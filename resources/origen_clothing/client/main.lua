playerIdentifier = nil
IsAdmin = {
    fetched = false,
    value = false
}

function isAdmin()
    return lib.callback.await("origen_clothing:isAdmin", false)
end

local function loadStores()
    if playerIdentifier then return end
    
    playerIdentifier = Custom.GetPlayerIdentifier()

    while not playerIdentifier do
        playerIdentifier = Custom.GetPlayerIdentifier()
        Wait(500)
    end

    lib.callback('origen_clothing:server:getStores', false, function(stores)
        if not stores or not next(stores) then return end
        for _, data in pairs(stores) do
            if not Store.table[data.id] then
                Store.new(data)
            end
        end
    end)
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Custom.HideVisuals(false)
        if outfitPed then
            DeleteEntity(outfitPed)
        end
    end
end)

RegisterNetEvent("origen_clothing:openClothingMenu", function(type)
    SalirDeTiendaEspecial()
    if type == "clothing" then
        StartCamera(true)
        OpenClothing('clothes', {
            stock = {},
            storeId = -1,
            outfits = Outfit.GetCivilOutfits(),
            drawables = GetPedDrawables(PlayerPedId()),
            props = GetPedProps(PlayerPedId())
        })
    elseif type == "gestion" then
        --[[ La tienda tal cual la ve un jugador, pero para retirar prendas
             (server/gestion.lua). Solo llega aqui si el servidor ha
             comprobado que eres admin; sin eso, el servidor no deja retirar
             nada aunque esta pantalla se abriera. No se compra: al cerrar
             vuelve la ropa que llevabas. ]]
        StartCamera(true)
        OpenClothing('clothes', {
            stock = {},
            storeId = -1,
            gestion = true,
            outfits = Outfit.GetCivilOutfits(),
            drawables = GetPedDrawables(PlayerPedId()),
            props = GetPedProps(PlayerPedId())
        })
    elseif type == "admin" then
        OpenClothing("admin", {
            stores = Store.GetAllData()
        })
    elseif type == "barber" then
        StartCamera(true)
        OpenClothing("barber", {
            headBlend = GetHeadBlendData(cache.ped),
            faceFeatures = GetPedFaceFeatures(cache.ped),
            headOverlays = GetPedHeadOverlays(cache.ped),
            drawables = GetPedDrawables(cache.ped),
        })
    elseif type == "ped" then
        StartCamera(true)
        MoveCamera('ZONE_OUTFITS')
        local peds = lib.callback.await('origen_clothing:getPeds', false)
        OpenClothing('ped', { peds = peds })
    end
    debugger("OPEN: ", type)
end)

if Config.FixWetClothPhysics then
    SetWetClothPinRadiusScale(1.0)
end

function LoadModelDicts()
    for hash, ped_name in pairs(GlobalState.ModelsDict) do
        Config.Peds[hash] = ped_name
    end
end

AddStateBagChangeHandler("ModelsDict", "global", function(name, key, value)
    LoadModelDicts()
end)

CreateThread(function()
    LoadModelDicts()
end)

RegisterNetEvent('origen_clothing:client:onPlayerLoad', function()
    Wait(1000)
    loadStores()
    -- TriggerEvent('origen_clothing:loadClothes')
end)

RegisterNetEvent('origen_clothing:client:openCreationManually', function()
    -- Called from /skin creation command - don't reset model, don't teleport
    local gender = GetEntityModel(PlayerPedId()) == GetHashKey('mp_f_freemode_01') and 1 or 0
    StartPedCreation(true, gender, PlayerPedId(), true)
end)

RegisterNetEvent('origen_clothing:client:createStore', function(data)
    Store.new(data)
end)

RegisterNetEvent('origen_clothing:client:updateStore', function(data)
    local store = Store.get(data.id)
    if not store then
        return
    end
    store:edit(data)
end)

RegisterNetEvent('origen_clothing:client:deleteStore', function(id)
    local store = Store.get(id)
    if not store then
        return
    end
    store:delete()
end)

function openCreation(sex, isFirstTimeCreation)
    local gender = Framework.GetGender()
    local model = gender == 1 and "mp_f_freemode_01" or "mp_m_freemode_01"

    local modelHash = GetHashKey(model)
    lib.requestModel(modelHash, 10000)

    SetPlayerModel(PlayerId(), modelHash)
    SetPedComponentVariation(PlayerPedId(), 0, 0, 0, 2)
    TriggerServerEvent('origen_clothing:setRoutingBucket', true)
    
    -- Pass isFirstTimeCreation to determine if teleportation should happen
    if isFirstTimeCreation then
        -- First time creation, allow teleport
        StartPedCreation(false, gender == 1 and 1 or 0, PlayerPedId(), false)
    else
        -- Manual /skin command, don't teleport
        StartPedCreation(true, gender == 1 and 1 or 0, PlayerPedId(), true)
    end
end

exports('openCreation', openCreation)

-- Variable para rastrear si fue abierto desde el hub
local openedFromHub = false
-- Cada openManagement sube: el foco retrasado de una apertura vieja se retira.
local aperturasAdmin = 0

-- Exports auxiliares para el flag
exports('IsOpenedFromHub', function() return openedFromHub end)
exports('ResetHubFlag', function() openedFromHub = false end)

-- Export para abrir el panel de administración desde el hub
exports('openManagement', function()
    -- Marcar que fue abierto desde el hub
    openedFromHub = true
    aperturasAdmin = aperturasAdmin + 1
    local mia = aperturasAdmin
    
    CreateThread(function()
        -- Abrir el panel pero SIN activar el focus todavía
        OpenClothing("admin", {
            stores = Store.GetAllData(),
            delayFocus = true  -- No activar focus todavía
        })
        
        -- Esperar 2.8 segundos
        Wait(2800)

        --[[ Si en esos 2,8 s se cerro (closeAdminMenu baja openedFromHub) o
             se volvio a abrir, no se coge el raton: seria para un panel que
             ya no esta y el raton se quedaria preso. ]]
        if not openedFromHub or aperturasAdmin ~= mia then return end
        
        -- AHORA activar el focus
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end)
end)

