Livery = {}

local resource = GetCurrentResourceName()
local DUI_TIMEOUT = 10000

local entries = {}
local assetBase = ''
local healthy = nil

local function resolveAssetBase()
    local base = GetConvar(Config.AssetBaseConvar, '')

    if base == '' then
        local endpoint = GetCurrentServerEndpoint()
        base = endpoint and endpoint ~= '' and ('http://' .. endpoint) or ''
    end

    return (base:gsub('/+$', ''))
end

local function currentAssetBase()
    if assetBase == '' then
        assetBase = resolveAssetBase()
    end
    return assetBase
end

local function urlEncode(str)
    if type(str) ~= 'string' then return '' end
    return (str:gsub('[^%w%-_%.~]', function(c)
        return string.format('%%%02X', string.byte(c))
    end))
end

function Livery.assetBase()
    return currentAssetBase()
end

function Livery.healthUrl()
    local base = currentAssetBase()
    if base == '' then return nil end
    return base .. Config.HttpPrefix .. '/health'
end

function Livery.setHealth(ok)
    healthy = ok and true or false
end

function Livery.isHealthy()
    return healthy
end

local function slotUrl(slot)
    if type(slot.url) == 'string' and slot.url ~= '' then
        return slot.url
    end

    local base = currentAssetBase()
    if type(slot.hash) == 'string' and slot.hash:match('^%x+$') and base ~= '' then
        return ('%s%s/img/%s.png'):format(base, Config.HttpPrefix, slot.hash)
    end

    return nil
end

local function key(model, slotId)
    return model .. ':' .. slotId
end

local function normalizePlate(plate)
    if type(plate) ~= 'string' then return '' end
    return plate:match('^%s*(.-)%s*$'):upper()
end

local function modelNameOf(vehicle)
    local name = GetEntityArchetypeName(vehicle)
    if type(name) ~= 'string' or name == '' then return nil end
    return name:lower()
end

local function texturesOf(slot)
    local list = {}

    if type(slot.textures) == 'table' then
        for _, name in ipairs(slot.textures) do
            if type(name) == 'string' and name ~= '' then
                list[#list + 1] = name
            end
        end
    end

    if #list == 0 then
        list[1] = slot.texture
    end

    return list
end

--[[ Huecos que el editor está usando para la vista previa. Una livery de
     verdad que termine de cargar en ese hueco mientras tanto no se engancha:
     taparía lo que estás pintando. Al cerrar el editor se engancha la buena. ]]
local previewing = {}

function Livery.marcarPrevia(model, slotId, active)
    previewing[model .. ':' .. slotId] = active == true or nil
end

local function bindTextures(entry)
    if not entry.runtimeTex or previewing[entry.model .. ':' .. entry.slotId] then return end
    for _, texture in ipairs(entry.textures) do
        RemoveReplaceTexture(entry.txd, texture)
        AddReplaceTexture(entry.txd, texture, entry.runtimeTxd, entry.runtimeTex)
    end
end

local function unbindTextures(entry)
    if previewing[entry.model .. ':' .. entry.slotId] then return end
    for _, texture in ipairs(entry.textures) do
        RemoveReplaceTexture(entry.txd, texture)
    end
end

local function attach(entry)
    bindTextures(entry)
    entry.applied = true
end

local function detach(entry)
    unbindTextures(entry)
    entry.applied = false

    if entry.dui then
        DestroyDui(entry.dui)
        entry.dui = nil
    end
end

local function pushImage(entry)
    if not entry.dui or not entry.url then return end
    SendDuiMessage(entry.dui, json.encode({ image = entry.url }))
end

local REFRESH_DELAYS = { 250, 750, 1500, 3000 }

-- A replacement only binds to an embedded part txd that is resident when it is registered,
-- so it is registered again after the part gets installed or a vehicle wearing it streams in.
local function refreshSlot(model, slotId)
    local entry = entries[key(model, slotId)]

    if not entry then
        Livery.reconcile()
        entry = entries[key(model, slotId)]
    end

    if not entry or not entry.dui or entry.dropped then return end

    pushImage(entry)
    bindTextures(entry)
end

local function scheduleRefresh(model, slotId)
    CreateThread(function()
        local elapsed = 0

        for _, at in ipairs(REFRESH_DELAYS) do
            Wait(at - elapsed)
            elapsed = at
            refreshSlot(model, slotId)
        end
    end)
end

local function destroyEntry(entryKey)
    local entry = entries[entryKey]
    if not entry then return end

    entries[entryKey] = nil
    entry.dropped = true

    detach(entry)
end

--[[ Un txd de ejecución no se puede borrar y crear otro con el mismo nombre
     da problemas, así que se crea uno por hueco y se reutiliza. Lo que sí es
     nuevo cada vez es la textura: una DUI destruida no se vuelve a colgar del
     mismo nombre. ]]
local runtimeTxds = {}
local textureSerial = 0

local function createEntry(model, slot, url)
    local entryKey = key(model, slot.id)
    local name = ('origen_livery_%s_%s'):format(model, (slot.id:gsub(':', '_')))

    local entry = {
        model = model,
        slotId = slot.id,
        kind = slot.kind,
        modIndex = slot.modIndex,
        plate = slot.plate,
        txd = slot.txd,
        texture = slot.texture,
        textures = texturesOf(slot),
        runtimeTxd = name,
        runtimeTex = nil,
        url = url,
        dui = nil,
        applied = false,
        dropped = false,
        touched = GetGameTimer(),
    }

    entries[entryKey] = entry

    CreateThread(function()
        local base = currentAssetBase()
        local page = base ~= ''
            and (base .. Config.HttpPrefix .. '/dui')
            or ('https://cfx-nui-%s/html/dui.html'):format(resource)

        local fullPage = page
        if type(url) == 'string' and url ~= '' and #url < 1000 and url:match('^https?://') then
            fullPage = ('%s?img=%s'):format(page, urlEncode(url))
        end

        local dui = CreateDui(fullPage, Config.DuiSize, Config.DuiSize)
        local deadline = GetGameTimer() + DUI_TIMEOUT

        while not IsDuiAvailable(dui) and GetGameTimer() < deadline and not entry.dropped do
            Wait(50)
        end

        if entry.dropped then
            DestroyDui(dui)
            return
        end

        entry.dui = dui

        runtimeTxds[entry.runtimeTxd] = runtimeTxds[entry.runtimeTxd] or CreateRuntimeTxd(entry.runtimeTxd)
        textureSerial = textureSerial + 1
        entry.runtimeTex = ('%s_%d'):format(entry.runtimeTxd, textureSerial)
        CreateRuntimeTextureFromDuiHandle(runtimeTxds[entry.runtimeTxd], entry.runtimeTex, GetDuiHandle(dui))

        -- Enviar la imagen con reintentos para asegurar que CEF la reciba incluso si el DOM estaba inicializando
        for _, delay in ipairs({ 0, 150, 400, 800, 1500 }) do
            if delay > 0 then Wait(delay) end
            if entry.dropped or not entry.dui then break end
            pushImage(entry)
            if delay == 0 then
                attach(entry)
            end
        end
    end)

    return entry
end

local function updateEntry(entry, slot, url)
    entry.touched = GetGameTimer()

    local changed = entry.txd ~= slot.txd
        or entry.kind ~= slot.kind
        or table.concat(entry.textures, '|') ~= table.concat(texturesOf(slot), '|')

    if changed then
        destroyEntry(key(entry.model, entry.slotId))
        createEntry(entry.model, slot, url)
        return
    end

    entry.modIndex = slot.modIndex
    entry.plate = slot.plate

    if entry.url ~= url then
        entry.url = url
        pushImage(entry)
    end

    if not entry.applied and entry.dui then
        attach(entry)
    end
end

local function isSlot(slot)
    return type(slot) == 'table'
        and type(slot.txd) == 'string' and slot.txd ~= ''
        and type(slot.texture) == 'string' and slot.texture ~= ''
end

--[[ ── Qué liveries se cargan ──────────────────────────────────────────────

     Solo las de los coches que tienes cerca. Antes se cargaban TODAS las del
     servidor, con un tope de seis: a partir de la séptima, unas echaban a
     otras y había coches que salían con la livery de serie aunque la tuvieran
     puesta.

     Cada pasada mira los coches de los modelos con livery a menos de
     Config.LoadDistance, busca en la lista del servidor si su matrícula lleva
     una y se queda con las más cercanas hasta Config.MaxDuis. El coche en el
     que vas cuenta como distancia cero: el tuyo siempre entra.

     Lo que se aleja no se descarga en el acto sino a los Config.UnloadDelay,
     para no tirar y volver a cargar una DUI al dar la vuelta a la manzana; eso
     sí, si hace falta sitio para una más cercana, se descarga ya. ]]
local function nearbyLiveries()
    local found = {}
    local models = GlobalState['livery:models']
    if type(models) ~= 'table' or #models == 0 then return found end

    local byHash = {}
    for _, model in ipairs(models) do
        if type(model) == 'string' then byHash[joaat(model) & 0xFFFFFFFF] = model end
    end

    local ped = PlayerPedId()
    local origin = GetEntityCoords(ped)
    local mine = GetVehiclePedIsIn(ped, false)
    local slotsOf = {}

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        local model = byHash[GetEntityModel(vehicle) & 0xFFFFFFFF]

        if model then
            local distance = vehicle == mine and 0.0 or #(GetEntityCoords(vehicle) - origin)

            if distance <= Config.LoadDistance then
                local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))

                if plate ~= '' then
                    -- Leer el GlobalState deserializa la tabla entera: una vez por modelo.
                    if slotsOf[model] == nil then slotsOf[model] = GlobalState['livery:' .. model] or false end
                    local slots = slotsOf[model]

                    if slots then
                        for slotId, slot in pairs(slots) do
                            if type(slotId) == 'string' and isSlot(slot) and slot.plate == plate then
                                local url = slotUrl(slot)
                                local entryKey = key(model, slotId)

                                if url and (not found[entryKey] or found[entryKey].distance > distance) then
                                    found[entryKey] = { model = model, slot = slot, url = url, distance = distance }
                                end

                                break
                            end
                        end
                    end
                end
            end
        end
    end

    return found
end

local function reconcile()
    local now = GetGameTimer()
    local found = nearbyLiveries()

    local ordered = {}
    for entryKey, item in pairs(found) do
        item.key = entryKey
        ordered[#ordered + 1] = item
    end
    table.sort(ordered, function(a, b) return a.distance < b.distance end)

    local chosen = {}
    for index, item in ipairs(ordered) do
        if index > Config.MaxDuis then break end
        chosen[item.key] = true

        local entry = entries[item.key]
        if entry then
            updateEntry(entry, item.slot, item.url)
        else
            entry = createEntry(item.model, item.slot, item.url)
        end

        -- updateEntry puede haberla rehecho: se vuelve a leer.
        entry = entries[item.key]
        if entry then entry.seen = now end
    end

    -- Las que no han entrado en esta pasada: fuera cuando lleven un rato sin
    -- hacer falta; mientras tanto, esperan por si vuelves.
    local lingering, count = {}, 0
    for entryKey, entry in pairs(entries) do
        count = count + 1
        if not chosen[entryKey] then
            if now - (entry.seen or 0) > Config.UnloadDelay then
                destroyEntry(entryKey)
                count = count - 1
            else
                lingering[#lingering + 1] = { key = entryKey, seen = entry.seen or 0 }
            end
        end
    end

    -- Sin sitio para las cercanas, las que se quedaron esperando se van ya.
    table.sort(lingering, function(a, b) return a.seen < b.seen end)
    for _, item in ipairs(lingering) do
        if count <= Config.MaxDuis then break end
        destroyEntry(item.key)
        count = count - 1
    end
end

function Livery.reconcile()
    reconcile()
end

local function modLiveryCount(vehicle)
    SetVehicleModKit(vehicle, 0)
    return GetNumVehicleMods(vehicle, Config.LiveryModType)
end

function Livery.target()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return nil end

    local model = modelNameOf(vehicle)
    if not model then return nil end

    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    local slots = GlobalState['livery:' .. model]
    local applied = {}
    local assignment

    if type(slots) == 'table' then
        for slotId, slot in pairs(slots) do
            local item = {
                id = slotId,
                texture = slot.texture,
                url = slotUrl(slot),
                designId = slot.designId,
                plate = slot.plate,
                modIndex = slot.modIndex,
            }

            applied[#applied + 1] = item

            if plate ~= '' and slot.plate == plate then
                assignment = { slotId = slotId, url = item.url, designId = slot.designId, modIndex = slot.modIndex }
            end
        end
    end

    table.sort(applied, function(a, b) return a.id < b.id end)

    return {
        model = model,
        entity = vehicle,
        plate = plate,
        modLiveries = modLiveryCount(vehicle),
        modLivery = GetVehicleMod(vehicle, Config.LiveryModType),
        slots = applied,
        assignment = assignment,
    }
end

local wearing = {}

--[[ Coches que el editor tiene en vista previa: mientras tanto el bucle que
     pone y quita la pieza de livery no los toca, o a los tres segundos le
     quitaría al coche la pieza que el editor acaba de ponerle para mirar. ]]
local pausados = {}

function Livery.pausar(vehicle, pausar)
    if not vehicle or vehicle == 0 then return end
    pausados[vehicle] = pausar == true or nil
end

--- Vuelve a enganchar la livery de verdad de un hueco, si la hay: la vista
--- previa del editor la tapó y al cerrar se devuelve.
function Livery.rebind(model, slotId)
    refreshSlot(model, slotId)
end

local function setLiveryMod(vehicle, modIndex)
    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, Config.LiveryModType, modIndex, false)
end

function Livery.enforce(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if pausados[vehicle] then return end

    local model = modelNameOf(vehicle)
    if not model then return end

    local slots = GlobalState['livery:' .. model]
    if type(slots) ~= 'table' then return end

    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    local current = GetVehicleMod(vehicle, Config.LiveryModType)
    local owned, ownedId

    if plate ~= '' then
        for slotId, slot in pairs(slots) do
            if slot.plate == plate and math.tointeger(slot.modIndex) then
                owned, ownedId = math.tointeger(slot.modIndex), slotId
                break
            end
        end
    end

    if owned then
        if current == owned then
            if not wearing[vehicle] or wearing[vehicle] == 'clearing' then
                wearing[vehicle] = true
                scheduleRefresh(model, ownedId)
            end
        elseif NetworkHasControlOfEntity(vehicle) then
            if wearing[vehicle] == 'clearing' then
                -- Wait for server to finish clearing
            elseif wearing[vehicle] then
                -- The modIndex changed natively AFTER we successfully enforced it.
                -- This implies the player is customizing the livery in a tuner menu.
                -- We clear the custom slot so it doesn't fight the tuner menu.
                TriggerServerEvent('origen_livery:clearSlot', model, ownedId)
                wearing[vehicle] = 'clearing'
            else
                setLiveryMod(vehicle, owned)
                wearing[vehicle] = true
                scheduleRefresh(model, ownedId)
            end
        end
        return
    end

    wearing[vehicle] = nil

    if current < 0 then return end

    for _, slot in pairs(slots) do
        if math.tointeger(slot.modIndex) == current then
            if NetworkHasControlOfEntity(vehicle) then
                setLiveryMod(vehicle, -1)
            end
            return
        end
    end
end

--- Explicit release of a vehicle this resource managed: the server dropped its state bag,
--- so the part it installed is stripped even though no registry slot claims the index anymore.
function Livery.release(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local model = modelNameOf(vehicle)
    if not model then return end

    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    local slots = GlobalState['livery:' .. model]

    if type(slots) == 'table' and plate ~= '' then
        for _, slot in pairs(slots) do
            if slot.plate == plate then return Livery.enforce(vehicle) end
        end
    end

    if GetVehicleMod(vehicle, Config.LiveryModType) >= 0 and NetworkHasControlOfEntity(vehicle) then
        setLiveryMod(vehicle, -1)
    end
end

-- Hashes de los modelos gestionados. Se calculan una vez y se tiran (nil) cuando
-- cambia 'livery:models', en vez de leer el GlobalState y hacer joaat cada 3 s.
local managedHashes = nil

local function buildManagedHashes()
    local models = GlobalState['livery:models']
    -- Sin modelos no se guarda nada: la próxima pasada lo vuelve a mirar, como antes.
    if type(models) ~= 'table' or #models == 0 then return nil end

    local managed = {}

    for _, model in ipairs(models) do
        if type(model) == 'string' then
            managed[joaat(model) & 0xFFFFFFFF] = true
        end
    end

    return managed
end

local function enforceAll()
    if not managedHashes then managedHashes = buildManagedHashes() end
    local managed = managedHashes
    if not managed then return end

    for vehicle in pairs(wearing) do
        if not DoesEntityExist(vehicle) then wearing[vehicle] = nil end
    end

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if managed[GetEntityModel(vehicle) & 0xFFFFFFFF] then
            Livery.enforce(vehicle)
        end
    end
end

-- Change handlers run before the new value is readable from the bag, so both wait a tick.
AddStateBagChangeHandler(nil, 'global', function(_, keyName)
    if type(keyName) ~= 'string' or keyName:sub(1, 7) ~= 'livery:' then return end
    Wait(0)
    -- Ya se puede leer el valor nuevo: que la próxima pasada rehaga los hashes.
    if keyName == 'livery:models' then managedHashes = nil end
    reconcile()
end)

AddStateBagChangeHandler('origen_livery', nil, function(bagName, _, value)
    Wait(0)

    local deadline = GetGameTimer() + 1000
    local entity = GetEntityFromStateBagName(bagName)

    while (entity == 0 or not DoesEntityExist(entity)) and GetGameTimer() < deadline do
        Wait(50)
        entity = GetEntityFromStateBagName(bagName)
    end

    if entity == 0 or not DoesEntityExist(entity) then return end

    if value == nil then
        Livery.release(entity)
    else
        Livery.enforce(entity)
    end
end)

CreateThread(function()
    while true do
        Wait(Config.EnforceInterval)
        enforceAll()
    end
end)

AddEventHandler('playerSpawned', function()
    for _, entry in pairs(entries) do
        if entry.dui and not entry.applied then attach(entry) end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= resource then return end

    for entryKey in pairs(entries) do
        destroyEntry(entryKey)
    end

    SetNuiFocus(false, false)
end)

CreateThread(function()
    assetBase = resolveAssetBase()
    reconcile()
end)
