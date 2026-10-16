-- ── Gang Stores — Cliente Gameplay ────────────────────────────────────────────
-- Gestiona el spawn/despawn de NPCs de tienda, la interacción con el jugador
-- y la apertura de la NUI de compra.

local dbg = Debug:new({ enabled = Config.Debug })

-- ── Estado local ──────────────────────────────────────────────────────────────

local activeStores   = {}   -- [storeId] = storeData
local spawnedNpcs    = {}   -- [storeId] = pedHandle
local spawningNpcs   = {}   -- [storeId] = true (lock anti-race para spawn concurrente)
local storePoints    = {}   -- [storeId] = lib.points handle
local currentTextUI  = nil

local storesMarkerCfg = (Config.Markers and Config.Markers.Stores) or {}
local storesFallback  = storesMarkerCfg.fallback or {}

local INTERACT_DIST  = storesMarkerCfg.interactDistance or 1.8 -- distancia para mostrar texto de ayuda y abrir tienda
local MARKER_DIST    = storesMarkerCfg.drawDistance or 15.0    -- distancia para dibujar marker de fallback
local POINT_DIST     = storesMarkerCfg.pointDistance or 50.0   -- radio del lib.points

-- Marker de fallback (si no hay NPC visible)
local MARKER_TYPE    = storesFallback.type or 1
local MARKER_OFFSET  = storesFallback.offset or { x = 0.0, y = 0.0, z = 0.0 }
local MARKER_SCALE   = storesFallback.scale or { x = 0.6, y = 0.6, z = 0.6 }
local MARKER_COLOR   = storesFallback.color or { r = 180, g = 180, b = 255, a = 150 }
local MARKER_BOB     = storesFallback.bobUpAndDown == true
local MARKER_FACE    = storesFallback.faceCamera ~= false
local MARKER_ROT_ORD = storesFallback.rotationOrder or 2
local MARKER_ROTATE  = storesFallback.rotate == true

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function SpawnStoreNpc(store)
    -- Guard doble: ya existe el ped O ya hay un spawn en curso para esta tienda
    if spawnedNpcs[store.id] and DoesEntityExist(spawnedNpcs[store.id]) then return end
    if spawningNpcs[store.id] then return end
    spawningNpcs[store.id] = true

    local modelHash = GetHashKey(store.ped_model or 's_m_y_dealer_01')
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(modelHash) then
        dbg:warning('[Stores] No se pudo cargar modelo:', store.ped_model)
        spawningNpcs[store.id] = nil
        return
    end

    local ped = CreatePed(
        4,
        modelHash,
        store.pos_x, store.pos_y, store.pos_z,
        store.pos_h,
        false, true
    )

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(modelHash)

    -- Animación idle
    local animDict = 'anim@amb@business@bgen@bgen_no_work@'
    local animName = 'base'
    RequestAnimDict(animDict)
    timeout = 0
    while not HasAnimDictLoaded(animDict) and timeout < 30 do
        Wait(100)
        timeout = timeout + 1
    end
    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(ped, animDict, animName, 2.0, -1.0, -1, 1, 0.0, false, false, false)
    end

    spawnedNpcs[store.id]  = ped
    spawningNpcs[store.id] = nil  -- liberar lock
    dbg:info('[Stores] NPC spawneado para tienda', store.id, '| ped:', ped)
end

local function DespawnStoreNpc(storeId)
    if spawnedNpcs[storeId] and DoesEntityExist(spawnedNpcs[storeId]) then
        DeleteEntity(spawnedNpcs[storeId])
    end
    spawnedNpcs[storeId]  = nil
    spawningNpcs[storeId] = nil  -- limpiar lock también al despawnear
end

local function RemoveStorePoint(storeId)
    if storePoints[storeId] then
        storePoints[storeId]:remove()
        storePoints[storeId] = nil
    end
end

local function ClearAllStores()
    for storeId, _ in pairs(activeStores) do
        DespawnStoreNpc(storeId)
        RemoveStorePoint(storeId)
    end
    activeStores  = {}
    spawnedNpcs   = {}
    spawningNpcs  = {}
    storePoints   = {}
    if currentTextUI then
        HelpText.HideHelpText()
        currentTextUI = nil
    end
end

-- ── Apertura de la UI de compra ───────────────────────────────────────────────

local storeMenuOpen = false
local currentStoreId = nil

local function OpenStoreMenu(store)
    if storeMenuOpen then return end

    -- Pedir catálogo al servidor
    local result = lib.callback.await('origen_gang:store:getCatalog', false, store.id)
    if not result or not result.success then
        local reason = result and result.message or 'error'
        local msg = ({
            store_disabled      = locale:t('notify.sell_store_disabled'),
            no_gang             = locale:t('notify.crafting_no_gang'),
            not_whitelisted     = locale:t('notify.sell_store_not_whitelisted'),
            territory_neutral   = locale:t('notify.sell_store_territory_neutral'),
            not_territory_owner = locale:t('notify.sell_store_not_territory_owner'),
            no_territory        = locale:t('notify.sell_store_no_territory'),
        })[reason] or locale:t('notify.no_access_with_reason', reason)
        Notify.SendNotify(msg, 'error')
        return
    end

    storeMenuOpen  = true
    currentStoreId = store.id

    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'openGangStore',
        data     = {
            store_id   = store.id,
            store_name = result.store_name,
            items      = result.items,
        },
    })
end

-- ── NUI Callbacks de compra ───────────────────────────────────────────────────

RegisterNUICallback('gangStore:buyItem', function(data, cb)
    if not currentStoreId then cb({ success = false }) ; return end

    data.store_id = currentStoreId
    local result = lib.callback.await('origen_gang:store:buyItem', false, data)

    if result and result.success then
        Notify.SendNotify(('Compraste x%d %s por $%s (%s).'):format(
            result.quantity,
            result.item_name,
            result.price_paid,
            CustomStoreMoneyClient.GetPayTypeLabel(result.pay_type)
        ), 'success')
    else
        local reason = result and result.message or 'error'
        Notify.SendNotify(CustomStoreMoneyClient.GetBuyError(reason), 'error')
    end

    cb(result or { success = false })
end)

RegisterNUICallback('gangStore:close', function(data, cb)
    storeMenuOpen  = false
    currentStoreId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeGangStore' })
    cb('ok')
end)

-- Si el raton se suelta a la fuerza (`soltarraton`, pagina vacia o colgada;
-- ver origen_map/shared/foco.lua), la tienda se cierra de verdad: con la
-- marca en true no volveria a abrirse, y la pagina se quedaria pintada.
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not storeMenuOpen then return end
        storeMenuOpen  = false
        currentStoreId = nil
        SendNUIMessage({ action = 'closeGangStore' })
    end)
end

-- ── Crear punto de lib.points para una tienda ─────────────────────────────────

local function CreateStorePoint(store)
    RemoveStorePoint(store.id)

    local coords = vector3(store.pos_x, store.pos_y, store.pos_z)

    local point = lib.points.new({
        coords   = coords,
        distance = POINT_DIST,
        storeId  = store.id,
    })

    function point:onEnter()
        -- Spawn NPC al entrar en el radio
        CreateThread(function()
            SpawnStoreNpc(activeStores[self.storeId] or store)
        end)
    end

    function point:onExit()
        -- Despawnear NPC al salir del radio
        DespawnStoreNpc(self.storeId)
        if currentTextUI == self.storeId then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    function point:nearby()
        local s = activeStores[self.storeId]
        if not s then return end

        local ped      = PlayerPedId()
        local myCoords = GetEntityCoords(ped)
        local dist     = #(myCoords - coords)

        -- Marker de fallback si el NPC no existe
        local npcHandle = spawnedNpcs[self.storeId]
        if not npcHandle or not DoesEntityExist(npcHandle) then
            if dist < MARKER_DIST then
                DrawMarker(
                    MARKER_TYPE,
                    coords.x + MARKER_OFFSET.x, coords.y + MARKER_OFFSET.y, coords.z + MARKER_OFFSET.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    MARKER_SCALE.x, MARKER_SCALE.y, MARKER_SCALE.z,
                    MARKER_COLOR.r, MARKER_COLOR.g, MARKER_COLOR.b, MARKER_COLOR.a,
                    MARKER_BOB, MARKER_FACE, MARKER_ROT_ORD, MARKER_ROTATE, nil, nil, false
                )
            end
        end

        -- Texto de interacción
        if dist < INTERACT_DIST then
            if currentTextUI ~= self.storeId then
                HelpText.ShowHelpText('[E] Abrir tienda · ' .. (s.name or ''))
                currentTextUI = self.storeId
            end
            if IsControlJustReleased(0, 38) and not storeMenuOpen then
                HelpText.HideHelpText()
                currentTextUI = nil
                OpenStoreMenu(s)
            end
        elseif currentTextUI == self.storeId then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    storePoints[store.id] = point
    -- lib.points llama a onEnter automáticamente si el jugador está dentro del radio.
    -- NO spawneamos manualmente aquí para evitar doble ped.
end

-- ── Cargar tiendas ────────────────────────────────────────────────────────────

local _loadingStores  = false
local _lastLoadTime   = 0
local LOAD_COOLDOWN   = 4000  -- ms mínimos entre cargas (evita doble carga en inicio)

local function LoadStores()
    local now = GetGameTimer()

    -- Si ya hay una carga en vuelo, ignorar
    if _loadingStores then
        dbg:info('[Stores] LoadStores ignorado: ya hay una carga en vuelo')
        return
    end

    -- Si acabamos de cargar hace menos de LOAD_COOLDOWN ms, ignorar
    if (now - _lastLoadTime) < LOAD_COOLDOWN then
        dbg:info('[Stores] LoadStores ignorado: cooldown activo')
        return
    end

    _loadingStores = true
    _lastLoadTime  = now

    ClearAllStores()

    local result = lib.callback.await('origen_gang:store:getAvailable', false)

    _loadingStores = false

    if not result or not result.success then return end

    for _, store in ipairs(result.stores or {}) do
        if store.pos_x ~= 0 or store.pos_y ~= 0 then
            activeStores[store.id] = store
            CreateStorePoint(store)
        end
    end

    dbg:info('[Stores] Cargadas', #(result.stores or {}), 'tiendas')
end

-- ── Recarga desde servidor (cuando admin modifica una tienda) ──────────────────

RegisterNetEvent('origen_gang:client:stores:reload', function()
    TriggerServerEvent('origen_gang:client:stores:requestReload')
end)

RegisterNetEvent('origen_gang:client:stores:loaded', function(stores)
    ClearAllStores()
    for _, store in ipairs(stores or {}) do
        if store.pos_x ~= 0 or store.pos_y ~= 0 then
            activeStores[store.id] = store
            CreateStorePoint(store)
        end
    end
end)

-- ── Lifecycle ─────────────────────────────────────────────────────────────────
-- REGLA: un solo entry point real → OnPlayerLoaded.
-- onResourceStart solo actúa en caso de `ensure` mientras el jugador ya estaba
-- cargado; el cooldown de LoadStores absorbe cualquier doble disparo.

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- Solo actuar si el jugador ya está cargado (caso ensure/restart del resource)
    if not Framework.GetIsPlayerLoaded() then return end
    Wait(3500)  -- delay mayor que el de OnPlayerLoaded para que el cooldown lo descarte si ya cargó
    LoadStores()
end)

AddEventHandler('origen:Client:OnPlayerLoaded', function()
    Wait(3000)
    LoadStores()
end)

AddEventHandler('origen:Client:OnPlayerUnload', function()
    ClearAllStores()
    _lastLoadTime  = 0  -- resetear cooldown para la próxima carga
    -- Abierta al descargar: se cierra la pantalla y se suelta el raton, no
    -- solo la marca.
    if storeMenuOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeGangStore' })
    end
    storeMenuOpen  = false
    currentStoreId = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    ClearAllStores()
end)

-- ── ESC cierra la tienda si está abierta ─────────────────────────────────────
-- (El handler de ESC global está en main.lua; aquí exponemos la función)
exports('IsStoreMenuOpen', function() return storeMenuOpen end)
exports('CloseStoreMenu', function()
    if not storeMenuOpen then return end
    storeMenuOpen  = false
    currentStoreId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeGangStore' })
end)
