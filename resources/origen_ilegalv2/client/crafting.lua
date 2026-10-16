-- ── Gang Crafting — Cliente Gameplay ──────────────────────────────────────────
-- Cada punto de fabricación es un banco de trabajo de verdad (con torno,
-- taladro y esmeril al lado en los del mundo). Se elige la receta en el menú
-- y el personaje la monta en el banco; luego la orden pasa a la cola del punto.

local dbg = Debug:new({ enabled = Config.Debug })

-- ── Estado local ──────────────────────────────────────────────────────────────

local activePoints   = {}   -- [pointId] = pointData
local craftingPoints = {}   -- [pointId] = lib.points handle
local currentTextUI  = nil

local BANCO   = (Config.Crafting and Config.Crafting.Banco) or {}
local MONTAJE = (Config.Crafting and Config.Crafting.Montaje) or {}

local INTERACT_DIST = BANCO.Distancia or 2.0
local POINT_DIST    = BANCO.Dibujar or 80.0
local DELANTE       = BANCO.Delante or 0.95
local MODELOS_BANCO = BANCO.Modelos or { 'origen_armero_banco', 'gr_prop_gr_bench_04b', 'prop_tool_bench02' }

--[[ Las máquinas del taller (origen_modelos, stream/armero), en fila con el
     banco. `en` es a lo largo del banco; las piezas sueltas (plato, broca,
     muelas) van en su sitio de cada máquina: { x a lo largo, y al fondo, z }. ]]
local MAQUINAS = {
    { modelo = 'origen_armero_torno',   en = -2.05, piezas = { { 'origen_armero_torno_plato', -0.50, 0.0, 1.10 } } },
    { modelo = 'origen_armero_taladro', en = 1.60,  piezas = { { 'origen_armero_taladro_broca', 0.0, -0.05, 1.32 } } },
    { modelo = 'origen_armero_esmeril', en = 2.45,  piezas = {
        { 'origen_armero_esmeril_disco', -0.15, -0.05, 1.05 },
        { 'origen_armero_esmeril_disco',  0.15, -0.05, 1.05 },
    } },
}

local ALTO_TABLERO = 0.92   -- donde se apoya lo que se está montando

-- ── El banco en el mundo ──────────────────────────────────────────────────────

local bancos = {}   -- [pointId] = { objs = {}, base = vector3, h = number }

local function CargarModelo(nombre)
    local m = type(nombre) == 'number' and nombre or joaat(nombre)
    if not IsModelInCdimage(m) then return nil end
    RequestModel(m)
    local tope = GetGameTimer() + 5000
    while not HasModelLoaded(m) and GetGameTimer() < tope do Wait(10) end
    return HasModelLoaded(m) and m or nil
end

--- Un punto en las medidas del banco: x a lo largo, y hacia el fondo (el jugador está en -y), z arriba.
local function EnBanco(b, x, y, z)
    local r = math.rad(b.h)
    local cs, sn = math.cos(r), math.sin(r)
    return vector3(b.base.x + x * cs - y * sn, b.base.y + x * sn + y * cs, b.base.z + z)
end

local function Poner(modelo, p, h)
    local m = CargarModelo(modelo)
    if not m then return nil end
    local o = CreateObject(m, p.x, p.y, p.z, false, false, false)
    -- CreateObject lo deja unos centímetros por encima: el origen donde toca.
    SetEntityCoordsNoOffset(o, p.x, p.y, p.z, false, false, false)
    SetEntityHeading(o, h)
    FreezeEntityPosition(o, true)
    SetModelAsNoLongerNeeded(m)
    return o
end

local function QuitarBanco(pointId)
    local b = bancos[pointId]
    if not b then return end
    for _, o in ipairs(b.objs) do
        if DoesEntityExist(o) then DeleteEntity(o) end
    end
    bancos[pointId] = nil
end

local function PonerBanco(point)
    QuitarBanco(point.id)

    local h = (point.pos_h or 0.0) + 0.0
    local r = math.rad(h)
    local x = point.pos_x - math.sin(r) * DELANTE
    local y = point.pos_y + math.cos(r) * DELANTE

    -- El suelo del banco, medido; el punto puede estar guardado a la altura del jugador.
    local z = point.pos_z - 1.0
    for _ = 1, 10 do
        local hay, suelo = GetGroundZFor_3dCoord(x, y, point.pos_z + 1.5, false)
        if hay then z = suelo break end
        Wait(100)
    end

    local b = { objs = {}, base = vector3(x, y, z), h = h }
    bancos[point.id] = b

    for _, modelo in ipairs(MODELOS_BANCO) do
        local o = Poner(modelo, b.base, h)
        if o then b.objs[#b.objs + 1] = o break end
    end

    if BANCO.Maquinas ~= false and not point.is_lab_instance then
        for _, m in ipairs(MAQUINAS) do
            local maquina = Poner(m.modelo, EnBanco(b, m.en, 0.0, 0.0), h)
            if maquina then
                b.objs[#b.objs + 1] = maquina
                for _, pz in ipairs(m.piezas) do
                    local o = Poner(pz[1], EnBanco(b, m.en + pz[2], pz[3], pz[4]), h)
                    if o then b.objs[#b.objs + 1] = o end
                end
            end
        end
    end
end

-- ── Montar en el banco ────────────────────────────────────────────────────────

local montando = false

local function Animar(ped)
    local dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@'
    RequestAnimDict(dict)
    local tope = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < tope do Wait(10) end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, 'machinic_loop_mechandplayer', 4.0, -4.0, -1, 1, 0, false, false, false)
        return dict
    end
    TaskStartScenarioInPlace(ped, 'PROP_HUMAN_BUM_BIN', 0, true)
end

--- Lo que se está montando, tumbado sobre el banco. Solo las armas tienen modelo.
local function PiezaEnElBanco(point, item)
    local b = bancos[point.id]
    if not b or not item then return nil end
    item = tostring(item):lower()
    if item:sub(1, 7) ~= 'weapon_' then return nil end

    local hash = joaat(item)
    if not IsWeaponValid(hash) then return nil end
    RequestWeaponAsset(hash, 31, 0)
    local tope = GetGameTimer() + 3000
    while not HasWeaponAssetLoaded(hash) and GetGameTimer() < tope do Wait(10) end
    if not HasWeaponAssetLoaded(hash) then return nil end

    local p = EnBanco(b, 0.0, 0.08, ALTO_TABLERO + 0.02)
    local o = CreateWeaponObject(hash, 0, p.x, p.y, p.z, true, 1.0, 0)
    if not o or o == 0 then return nil end
    -- De lado, con el cañón a lo largo del banco.
    SetEntityCoordsNoOffset(o, p.x, p.y, p.z, false, false, false)
    SetEntityRotation(o, 90.0, 0.0, b.h, 2, true)
    FreezeEntityPosition(o, true)
    SetEntityCollision(o, false, false)
    return o
end

local function TextoError(result)
    local reason = result and result.message or 'error'
    if reason == 'missing_blueprint' then
        return ('Necesitas llevar encima el %s'):format(result.item or 'plano')
    elseif reason == 'missing_item' then
        if result.item then
            return locale:t('notify.crafting_missing_item', { (result.needed or '?'), result.item, (result.has or 0) })
        end
        return locale:t('notify.crafting_missing_items')
    elseif reason == 'too_far' then
        return 'Tienes que estar delante del banco'
    elseif reason == 'user_level_too_low' then
        return locale:t('notify.crafting_user_level_low')
    elseif reason == 'gang_level_too_low' then
        return locale:t('notify.crafting_gang_level_low')
    elseif reason == 'inventory_full' then
        return 'No te cabe en el inventario. Haz sitio y vuelve a recogerlo.'
    end
    local claves = {
        point_disabled   = 'notify.crafting_point_disabled',
        point_not_found  = 'notify.crafting_point_not_found',
        invalid_params   = 'notify.crafting_invalid_params',
        no_identifier    = 'notify.crafting_no_identifier',
        not_started      = 'notify.crafting_not_started',
        not_ready        = 'notify.crafting_not_ready',
        too_fast         = 'notify.crafting_too_fast',
        no_gang          = 'notify.crafting_no_gang',
        not_cancellable  = 'notify.crafting_not_cancellable',
        not_starter      = 'notify.crafting_not_starter',
        recipe_not_found = 'notify.crafting_recipe_not_found',
        not_whitelisted     = 'notify.crafting_not_whitelisted',
        territory_neutral   = 'notify.crafting_territory_neutral',
        not_territory_owner = 'notify.crafting_not_territory_owner',
        no_territory        = 'notify.crafting_no_territory',
    }
    return locale:t(claves[reason] or 'notify.crafting_error_generic')
end

local function TiempoLegible(s)
    s = math.floor(tonumber(s) or 0)
    if s < 60 then return ('%d s'):format(s) end
    local m, r = math.floor(s / 60), s % 60
    return r > 0 and ('%d min %d s'):format(m, r) or ('%d min'):format(m)
end

--- El servidor ya ha dicho que sí (crafting:empezar): el personaje va al banco,
--- monta la pieza y, si acaba, la orden pasa a la cola.
local function Montar(point, info)
    if montando then return end
    montando = true

    local ped = PlayerPedId()
    local h = (point.pos_h or 0.0) + 0.0
    local puesto = vector3(point.pos_x, point.pos_y, point.pos_z)

    -- Al puesto, delante del banco.
    TaskGoStraightToCoord(ped, puesto.x, puesto.y, puesto.z, 1.0, 3000, h, 0.1)
    local tope = GetGameTimer() + 3000
    while GetGameTimer() < tope and #(GetEntityCoords(ped).xy - puesto.xy) > 0.35 do Wait(50) end
    ClearPedTasks(ped)
    SetEntityHeading(ped, h)

    local pieza = PiezaEnElBanco(point, info.salida)
    local dict = Animar(ped)

    local ok = ProgressBar.Open({
        duration     = (tonumber(info.segundos) or MONTAJE.Segundos or 10) * 1000,
        label        = ('Montando %s'):format(info.nombre or ''),
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
    })

    ClearPedTasks(ped)
    if dict then RemoveAnimDict(dict) end
    if pieza and DoesEntityExist(pieza) then DeleteEntity(pieza) end

    if ok == false then
        TriggerServerEvent('origen_gang:server:crafting:dejar')
        Notify.SendNotify('Has dejado el montaje. No se ha gastado nada.', 'error')
        montando = false
        return
    end

    local result = lib.callback.await('origen_gang:crafting:terminar', false)
    if result and result.success then
        local t = tonumber(result.craft_time) or 0
        Notify.SendNotify(t > 0
            and ('Montado. Queda en la cola del banco: listo en %s.'):format(TiempoLegible(t))
            or 'Montado. Recógelo en el banco.', 'success', 6000)
    else
        Notify.SendNotify(TextoError(result), 'error')
    end
    montando = false
end

-- ── UI de crafteo ─────────────────────────────────────────────────────────────

local craftingMenuOpen = false
local currentPointId   = nil
local _refreshingOpenPoint = false
local _pendingRefreshPoint = nil
local _lastRefreshMs       = 0
local REFRESH_DEBOUNCE_MS  = 350

local function RefreshOpenPointQueue(force)
    if not craftingMenuOpen or not currentPointId then return end

    local now = GetGameTimer()
    if not force and (now - _lastRefreshMs) < REFRESH_DEBOUNCE_MS then
        _pendingRefreshPoint = currentPointId
        return
    end

    if _refreshingOpenPoint then
        _pendingRefreshPoint = currentPointId
        return
    end

    _refreshingOpenPoint = true
    _lastRefreshMs = now

    local ok, refresh = pcall(function()
        return lib.callback.await('origen_gang:crafting:openPoint', false, currentPointId)
    end)

    _refreshingOpenPoint = false

    if ok and refresh and refresh.success then
        SendNUIMessage({
            action = 'gangCrafting:refreshQueue',
            data   = {
                queue         = refresh.queue,
                recipes       = refresh.recipes,
                user_progress = refresh.user_progress,
                gang_progress = refresh.gang_progress,
            },
        })
    end

    if _pendingRefreshPoint and craftingMenuOpen and currentPointId and _pendingRefreshPoint == currentPointId then
        _pendingRefreshPoint = nil
        local waitMs = REFRESH_DEBOUNCE_MS - (GetGameTimer() - _lastRefreshMs)
        if waitMs < 0 then waitMs = 0 end
        CreateThread(function()
            Wait(waitMs)
            RefreshOpenPointQueue(true)
        end)
    end
end

local function OpenCraftingMenu(point)
    if craftingMenuOpen or montando then return end

    local result = lib.callback.await('origen_gang:crafting:openPoint', false, point.id)
    if not result or not result.success then
        local reason = result and result.message or 'error'
        local msgs = {
            point_disabled      = locale:t('notify.crafting_point_disabled'),
            no_gang             = locale:t('notify.crafting_no_gang'),
            not_whitelisted     = locale:t('notify.crafting_not_whitelisted'),
            territory_neutral   = locale:t('notify.crafting_territory_neutral'),
            not_territory_owner = locale:t('notify.crafting_not_territory_owner'),
            no_territory        = locale:t('notify.crafting_no_territory'),
            point_not_found     = locale:t('notify.crafting_point_not_found'),
        }
        Notify.SendNotify(msgs[reason] or locale:t('notify.no_access_with_reason', reason), 'error')
        return
    end

    craftingMenuOpen = true
    currentPointId   = point.id

    -- Registrar observador para push server->client del estado de la cola
    TriggerServerEvent('origen_gang:server:crafting:watchPoint', point.id)

    SendTranslationsToNUI()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openGangCrafting',
        data   = {
            point_id      = point.id,
            point_name    = result.point_name,
            recipes       = result.recipes,
            queue         = result.queue,
            user_progress = result.user_progress,
            gang_progress = result.gang_progress,
        },
    })
end

local function CerrarMenu()
    TriggerServerEvent('origen_gang:server:crafting:clearWatch')
    _pendingRefreshPoint = nil
    craftingMenuOpen = false
    currentPointId   = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeGangCrafting' })
end

-- ── NUI Callbacks ─────────────────────────────────────────────────────────────

RegisterNUICallback('gangCrafting:close', function(data, cb)
    CerrarMenu()
    cb('ok')
end)

-- Si el raton se suelta a la fuerza (`soltarraton`, pagina vacia o colgada;
-- ver origen_map/shared/foco.lua), el crafteo se cierra de verdad: con la
-- marca en true no volveria a abrirse, el servidor seguiria mandando la cola
-- y la pagina se quedaria pintada.
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not craftingMenuOpen then return end
        TriggerServerEvent('origen_gang:server:crafting:clearWatch')
        _pendingRefreshPoint = nil
        craftingMenuOpen = false
        currentPointId   = nil
        SendNUIMessage({ action = 'closeGangCrafting' })
    end)
end

RegisterNetEvent('origen_gang:client:crafting:refreshPoint', function(pointId)
    pointId = tonumber(pointId)
    if not pointId then return end
    if not craftingMenuOpen or not currentPointId or currentPointId ~= pointId then return end
    RefreshOpenPointQueue(false)
end)

-- Fabricar: el servidor lo comprueba todo, el menú se cierra y se monta en el banco.
RegisterNUICallback('gangCrafting:fabricar', function(data, cb)
    if not currentPointId or montando then cb({ success = false }) ; return end

    local point = activePoints[currentPointId]
    local result = lib.callback.await('origen_gang:crafting:empezar', false, {
        point_id  = currentPointId,
        recipe_id = data and data.recipe_id,
    })

    if not result or not result.success or not point then
        Notify.SendNotify(TextoError(result), 'error')
        cb(result or { success = false })
        return
    end

    cb({ success = true })
    CerrarMenu()
    CreateThread(function()
        Montar(point, { segundos = result.segundos, nombre = result.nombre, salida = data and data.salida })
    end)
end)

RegisterNUICallback('gangCrafting:claim', function(data, cb)
    if not currentPointId then cb({ success = false }) ; return end

    data.point_id = currentPointId
    local result  = lib.callback.await('origen_gang:crafting:claim', false, data)

    if result and result.success then
        local count = result.items_received and #result.items_received or 0
        Notify.SendNotify(locale:t('notify.crafting_claim_received_types', count), 'success')
        RefreshOpenPointQueue(false)
    else
        Notify.SendNotify(TextoError(result), 'error')
    end

    cb(result or { success = false })
end)

RegisterNUICallback('gangCrafting:cancelQueue', function(data, cb)
    local result = lib.callback.await('origen_gang:crafting:cancelQueue', false, data)

    if result and result.success then
        Notify.SendNotify(locale:t('notify.crafting_cancelled_refunded'), 'success')
        RefreshOpenPointQueue(false)
    else
        Notify.SendNotify(TextoError(result), 'error')
    end

    cb(result or { success = false })
end)

-- ── Crear punto de lib.points ─────────────────────────────────────────────────

local function RemoveCraftingPoint(pointId)
    if craftingPoints[pointId] then
        craftingPoints[pointId]:remove()
        craftingPoints[pointId] = nil
    end
    QuitarBanco(pointId)
end

local function CreateCraftingPoint(point)
    RemoveCraftingPoint(point.id)

    local coords = vector3(point.pos_x, point.pos_y, point.pos_z)

    local pt = lib.points.new({
        coords  = coords,
        distance = POINT_DIST,
        pointId  = point.id,
    })

    function pt:onEnter()
        local p = activePoints[self.pointId]
        -- En su hilo: PonerBanco espera a los modelos y al suelo.
        if p then CreateThread(function() PonerBanco(p) end) end
    end

    function pt:onExit()
        QuitarBanco(self.pointId)
        if currentTextUI == self.pointId then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    function pt:nearby()
        local p = activePoints[self.pointId]
        if not p then return end

        if self.currentDistance < INTERACT_DIST and not montando then
            if currentTextUI ~= self.pointId then
                HelpText.ShowHelpText(locale:t('notify.crafting_help_interact', (p.name or '')))
                currentTextUI = self.pointId
            end
            if IsControlJustReleased(0, 38) and not craftingMenuOpen then
                HelpText.HideHelpText()
                currentTextUI = nil
                OpenCraftingMenu(p)
            end
        elseif currentTextUI == self.pointId then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    craftingPoints[point.id] = pt
end

-- ── Limpiar todo ──────────────────────────────────────────────────────────────

local function ClearAllCraftingPoints()
    for pointId, _ in pairs(activePoints) do
        RemoveCraftingPoint(pointId)
    end
    for pointId, _ in pairs(bancos) do
        QuitarBanco(pointId)
    end
    activePoints   = {}
    craftingPoints = {}
    if currentTextUI then
        HelpText.HideHelpText()
        currentTextUI = nil
    end
end

-- ── Cargar puntos disponibles ─────────────────────────────────────────────────

local _loadingPoints = false
local _lastLoadTime  = 0
local LOAD_COOLDOWN  = 4000

local function LoadCraftingPoints()
    local now = GetGameTimer()
    if _loadingPoints then return end
    if (now - _lastLoadTime) < LOAD_COOLDOWN then return end

    _loadingPoints = true
    _lastLoadTime  = now

    ClearAllCraftingPoints()

    local result = lib.callback.await('origen_gang:crafting:getAvailable', false)

    _loadingPoints = false

    if not result or not result.success then return end

    for _, point in ipairs(result.points or {}) do
        if point.pos_x ~= 0 or point.pos_y ~= 0 then
            activePoints[point.id] = point
            CreateCraftingPoint(point)
        end
    end

    dbg:info('[Crafting] Cargados', #(result.points or {}), 'puntos')
end

-- ── Reload desde servidor (cuando admin modifica un punto) ────────────────────

RegisterNetEvent('origen_gang:client:crafting:reload', function()
    TriggerServerEvent('origen_gang:client:crafting:requestReload')
end)

RegisterNetEvent('origen_gang:client:crafting:loaded', function(points)
    ClearAllCraftingPoints()
    for _, point in ipairs(points or {}) do
        if point.pos_x ~= 0 or point.pos_y ~= 0 then
            activePoints[point.id] = point
            CreateCraftingPoint(point)
        end
    end
end)

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if not Framework.GetIsPlayerLoaded() then return end
    Wait(3500)
    LoadCraftingPoints()
end)

AddEventHandler('origen:Client:OnPlayerLoaded', function()
    Wait(3000)
    LoadCraftingPoints()
end)

AddEventHandler('origen:Client:OnPlayerUnload', function()
    TriggerServerEvent('origen_gang:server:crafting:clearWatch')
    _pendingRefreshPoint = nil
    ClearAllCraftingPoints()
    _lastLoadTime    = 0
    -- Abierto al descargar: se cierra la pantalla y se suelta el raton, no
    -- solo la marca.
    if craftingMenuOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeGangCrafting' })
    end
    craftingMenuOpen = false
    currentPointId   = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    TriggerServerEvent('origen_gang:server:crafting:clearWatch')
    _pendingRefreshPoint = nil
    ClearAllCraftingPoints()
end)

-- origen_modelos parado: sus modelos se descargan y un objeto en pie con el
-- modelo descargado tumba el juego. Fuera los bancos.
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= 'origen_modelos' then return end
    for pointId, _ in pairs(bancos) do QuitarBanco(pointId) end
end)

-- ── Level-up notification ────────────────────────────────────────────────────

RegisterNetEvent('origen_gang:client:crafting:levelUp', function(data)
    if not data then return end

    if data.target_type == 'user' then
        Notify.SendNotify(
            locale:t('notify.crafting_level_up_user', {
                data.new_level,
                data.xp_remaining,
                data.xp_needed
            }),
            'success',
            7000
        )
    elseif data.target_type == 'gang' then
        Notify.SendNotify(
            locale:t('notify.crafting_level_up_gang', {
                data.new_level,
                data.xp_remaining,
                data.xp_needed
            }),
            'success',
            7000
        )
    end
end)

-- ── Exports para cierre por ESC global ───────────────────────────────────────
exports('IsCraftingMenuOpen', function() return craftingMenuOpen end)
exports('CloseCraftingMenu', function()
    if not craftingMenuOpen then return end
    CerrarMenu()
end)
