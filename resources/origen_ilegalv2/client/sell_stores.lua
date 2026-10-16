-- ── Gang Sell Stores — Cliente Gameplay ──────────────────────────────────────
-- Gestiona spawn/despawn de NPCs de venta, interacción y apertura de NUI.
-- Misma arquitectura que client/stores.lua, adaptada a ventas.

local dbg = Debug:new({ enabled = Config.Debug })

-- ── Estado local ──────────────────────────────────────────────────────────────

local activeStores   = {}
local spawnedNpcs    = {}
local spawningNpcs   = {}
local storePoints    = {}
local currentTextUI  = nil

local sellStoresMarkerCfg = (Config.Markers and Config.Markers.SellStores) or {}
local sellStoresFallback  = sellStoresMarkerCfg.fallback or {}

local INTERACT_DIST  = sellStoresMarkerCfg.interactDistance or 1.8
local MARKER_DIST    = sellStoresMarkerCfg.drawDistance or 15.0
local POINT_DIST     = sellStoresMarkerCfg.pointDistance or 50.0

local MARKER_TYPE    = sellStoresFallback.type or 1
local MARKER_OFFSET  = sellStoresFallback.offset or { x = 0.0, y = 0.0, z = 0.0 }
local MARKER_SCALE   = sellStoresFallback.scale or { x = 0.6, y = 0.6, z = 0.6 }
local MARKER_COLOR   = sellStoresFallback.color or { r = 255, g = 200, b = 100, a = 150 }
local MARKER_BOB     = sellStoresFallback.bobUpAndDown == true
local MARKER_FACE    = sellStoresFallback.faceCamera ~= false
local MARKER_ROT_ORD = sellStoresFallback.rotationOrder or 2
local MARKER_ROTATE  = sellStoresFallback.rotate == true

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function SpawnSellStoreNpc(store)
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
        dbg:warning('[SellStores] No se pudo cargar modelo:', store.ped_model)
        spawningNpcs[store.id] = nil
        return
    end

    local ped = CreatePed(4, modelHash, store.pos_x, store.pos_y, store.pos_z, store.pos_h, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(modelHash)

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
    spawningNpcs[store.id] = nil
    dbg:info('[SellStores] NPC spawneado para punto de venta', store.id, '| ped:', ped)
end

local function DespawnSellStoreNpc(storeId)
    if spawnedNpcs[storeId] and DoesEntityExist(spawnedNpcs[storeId]) then
        DeleteEntity(spawnedNpcs[storeId])
    end
    spawnedNpcs[storeId]  = nil
    spawningNpcs[storeId] = nil
end

local function RemoveStorePoint(storeId)
    if storePoints[storeId] then
        storePoints[storeId]:remove()
        storePoints[storeId] = nil
    end
end

local function ClearAllSellStores()
    for storeId, _ in pairs(activeStores) do
        DespawnSellStoreNpc(storeId)
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

-- ── Apertura de UI de venta ───────────────────────────────────────────────────

local sellMenuOpen   = false
local currentStoreId = nil

local function OpenSellMenu(store)
    if sellMenuOpen then return end

    local result = lib.callback.await('origen_gang:sellStore:getCatalog', false, store.id)
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

    sellMenuOpen   = true
    currentStoreId = store.id

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openGangSellStore',
        data   = {
            store_id   = store.id,
            store_name = result.store_name,
            items      = result.items,
        },
    })
end

-- ── NUI Callbacks de venta ────────────────────────────────────────────────────

RegisterNUICallback('gangSellStore:sellItem', function(data, cb)
    if not currentStoreId then cb({ success = false }) ; return end

    data.store_id = currentStoreId
    local result = lib.callback.await('origen_gang:sellStore:sellItem', false, data)

    if result and result.success then
        Notify.SendNotify(locale:t('notify.sell_store_sale_success', {
            result.quantity,
            result.item_name,
            result.price_paid,
            CustomStoreMoneyClient.GetPayTypeLabel(result.pay_type)
        }), 'success')
    else
        local reason = result and result.message or 'error'
        Notify.SendNotify(CustomStoreMoneyClient.GetSellError(reason), 'error')
    end

    cb(result or { success = false })
end)

RegisterNUICallback('gangSellStore:close', function(data, cb)
    sellMenuOpen   = false
    currentStoreId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeGangSellStore' })
    cb('ok')
end)

-- Si el raton se suelta a la fuerza (`soltarraton`, pagina vacia o colgada;
-- ver origen_map/shared/foco.lua), el punto de venta se cierra de verdad: con
-- la marca en true no volveria a abrirse, y la pagina se quedaria pintada.
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not sellMenuOpen then return end
        sellMenuOpen   = false
        currentStoreId = nil
        SendNUIMessage({ action = 'closeGangSellStore' })
    end)
end

-- ── Crear punto de lib.points para un punto de venta ─────────────────────────

local function CreateSellStorePoint(store)
    RemoveStorePoint(store.id)

    local coords = vector3(store.pos_x, store.pos_y, store.pos_z)

    local point = lib.points.new({
        coords   = coords,
        distance = POINT_DIST,
        storeId  = store.id,
    })

    function point:onEnter()
        CreateThread(function()
            SpawnSellStoreNpc(activeStores[self.storeId] or store)
        end)
    end

    function point:onExit()
        DespawnSellStoreNpc(self.storeId)
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

        -- Marker de fallback si no hay NPC
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

        if dist < INTERACT_DIST then
            if currentTextUI ~= self.storeId then
                HelpText.ShowHelpText(locale:t('notify.sell_store_help_interact', (s.name or '')))
                currentTextUI = self.storeId
            end
            if IsControlJustReleased(0, 38) and not sellMenuOpen then
                HelpText.HideHelpText()
                currentTextUI = nil
                OpenSellMenu(s)
            end
        elseif currentTextUI == self.storeId then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    storePoints[store.id] = point
end

-- ── Cargar puntos de venta ────────────────────────────────────────────────────

local _loadingSellStores = false
local _lastLoadTime      = 0
local LOAD_COOLDOWN      = 4000

local function LoadSellStores()
    local now = GetGameTimer()

    if _loadingSellStores then
        dbg:info('[SellStores] LoadSellStores ignorado: ya hay una carga en vuelo')
        return
    end

    if (now - _lastLoadTime) < LOAD_COOLDOWN then
        dbg:info('[SellStores] LoadSellStores ignorado: cooldown activo')
        return
    end

    _loadingSellStores = true
    _lastLoadTime      = now

    ClearAllSellStores()

    local result = lib.callback.await('origen_gang:sellStore:getAvailable', false)

    _loadingSellStores = false

    if not result or not result.success then return end

    for _, store in ipairs(result.stores or {}) do
        if store.pos_x ~= 0 or store.pos_y ~= 0 then
            activeStores[store.id] = store
            CreateSellStorePoint(store)
        end
    end

    dbg:info('[SellStores] Cargados', #(result.stores or {}), 'puntos de venta')
end

-- ── Recarga desde servidor ────────────────────────────────────────────────────

RegisterNetEvent('origen_gang:client:sellStores:reload', function()
    TriggerServerEvent('origen_gang:client:sellStores:requestReload')
end)

RegisterNetEvent('origen_gang:client:sellStores:loaded', function(stores)
    ClearAllSellStores()
    for _, store in ipairs(stores or {}) do
        if store.pos_x ~= 0 or store.pos_y ~= 0 then
            activeStores[store.id] = store
            CreateSellStorePoint(store)
        end
    end
end)

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if not Framework.GetIsPlayerLoaded() then return end
    Wait(3500)
    LoadSellStores()
end)

AddEventHandler('origen:Client:OnPlayerLoaded', function()
    Wait(3000)
    LoadSellStores()
end)

AddEventHandler('origen:Client:OnPlayerUnload', function()
    ClearAllSellStores()
    _lastLoadTime  = 0
    -- Abierto al descargar: se cierra la pantalla y se suelta el raton, no
    -- solo la marca.
    if sellMenuOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeGangSellStore' })
    end
    sellMenuOpen   = false
    currentStoreId = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    ClearAllSellStores()
end)

-- ── ESC cierra el menú de venta si está abierto ───────────────────────────────
exports('IsSellMenuOpen', function() return sellMenuOpen end)
exports('CloseSellMenu', function()
    if not sellMenuOpen then return end
    sellMenuOpen   = false
    currentStoreId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeGangSellStore' })
end)
