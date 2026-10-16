FollowMouse = false
local previousData = {
    zone = nil,
    components = {},
}
local CurrentAppearance = {}
InSelection = false
CreationPed = nil
local creationTeleport = true
local creationCallbacks = {}

function SetPreviousData(newZone, components)
    if previousData.zone then
        debugger("Skip setting previous data")
        return
    end
    previousData.zone = CurrentCameraZone
    for k, component in pairs(components or {}) do 
        previousData.components[k] = {
            index = component.index,
            value = GetPedDrawableVariation(GetPedCamera(), component.index),
            texture = GetPedTextureVariation(GetPedCamera(), component.index),
        }
        SetPedComponentVariation(GetPedCamera(), component.index, component.value, component.texture, 0)
    end
    MoveCamera(newZone)
end

function RestorePreviousData()
    if previousData.zone then
        MoveCamera(previousData.zone)
        previousData.zone = nil
    end
    for k, component in pairs(previousData.components) do
        SetPedComponentVariation(GetPedCamera(), component.index, component.value, component.texture, 0)
    end
    previousData.components = {}
end

function StartCreationThread()
    Custom.HideVisuals(true)
    InSelection = true
    while InSelection do
        -- Move this inside the loop, because may be other script is unfreezing the entity
        FreezeEntityPosition(CreationPed, true) -- Fishii truco
        if CurrentCameraZone == "ZONE_ACCESORIES" then
            -- Esto fue un intento para que el personaje mirara hacia arriba cuando se visualizara los collares
            -- pero parece que la cabeza tiene un limite de rotación y no puede mirar hacia arriba con IK

            local ikCoords = GetOffsetFromEntityInWorldCoords(CreationPed, 0.0, 20.0, 50.0)
            SetIkTarget(CreationPed, 1, 0, 0, ikCoords.x, ikCoords.y, ikCoords.z, 0, -1, 1000)
        elseif FollowMouse then
            local screenX = GetDisabledControlNormal(0, 239)
            local screenY = GetDisabledControlNormal(0, 240)
            local world, normal = GetWorldCoordFromScreenCoord(screenX, screenY)
            TaskLookAtCoord(CreationPed, world.x, world.y, world.z, 1000, 16384, 2)
        end

        ForcePedMotionState(CreationPed, `MotionState_None`, false, 1, true)
        -- Female multiplayer ped by a strange bug is moving backward so we need to reset its velocity to zero vector
        SetEntityVelocity(CreationPed, 0.0, 0.0, 0.0) -- Dani truco

        DisableAllControlActions(0)
        EnableControlAction(0, 249, true) -- Push to Talk
        EnableControlAction(0, 252, true) -- Push to Talk (alternate)

        Citizen.Wait(0)
    end
    ClearTimecycleModifier()
    FreezeEntityPosition(CreationPed, false)
    StopCamera()
    ForceCleanupCameraSystem()
    Custom.HideVisuals(false)
end

-- RegisterCommand("creationdata", function()
--     debugger("Velocity: ", GetEntityVelocity(PlayerPedId()))
--     debugger("Freezed: ", IsEntityPositionFrozen(PlayerPedId()))
--     debugger("KeepingInput: ", IsNuiFocusKeepingInput())
--     debugger("NUI Focused: ", IsNuiFocused())
-- end)

function IsMpPedModel(model)
    model = type(model) == 'number' and model or GetHashKey(model)
    return model == `mp_m_freemode_01` or model == `mp_f_freemode_01`
end

-- Set the default ped head blend data
function SetDefaultPedValues(ped, model)
    model = GetHashKey(model)
    if IsMpPedModel(model) then
        SetPedDefaultComponentVariation(ped)
        -- Check if the model is male or female, then change the face mix based on this.
        if model == `mp_m_freemode_01` then
            SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0, 0, 0, false)
        elseif model == `mp_f_freemode_01` then
            SetPedHeadBlendData(ped, 45, 21, 0, 20, 15, 0, 0.3, 0.1, 0, false)
        end
    end
end

local function initializeClothes(model)
    lib.requestModel(model, 10000)
    SetPlayerModel(cache.playerId, model)
    -- Wait(500)
    SetDefaultPedValues(PlayerPedId(), model)
    Wait(150)
    SetModelAsNoLongerNeeded(model)
end

local promiseId = nil

function StartPedCreation(currentLocation, gender, existingPed, notEndTeleport, callback)
    -- initializeClothes(QBX.PlayerData.charinfo.gender == 1 and 'mp_f_freemode_01' or 'mp_m_freemode_01')
    creationTeleport = not notEndTeleport
    if not existingPed then
        TriggerEvent("qb-weathersync:client:DisableSync")
        NetworkOverrideClockTime(10, 0, 0)
        -- SpawnEnvironment()
        -- Wait(2000)
        lib.callback.await('origen_clothing:setRoutingBucket', false, true)
        initializeClothes(gender == 0 and 'mp_m_freemode_01' or 'mp_f_freemode_01')
    end
    CreationPed = existingPed or PlayerPedId()
    if not currentLocation then
        local interior = GetInteriorAtCoords(Config.CreationCoords.x, Config.CreationCoords.y, Config.CreationCoords.z)
        LoadInterior(interior)
        local startTime = GetGameTimer()
        debugger(interior)
        while not IsInteriorReady(interior) and interior ~= 0 do
            if GetGameTimer() - startTime > 5000 then
                debugger("Could not load interior in time, exiting...")
                break
            end
            Wait(1000)
        end
        -- SetInteriorRoomTimecycle(interior, 1, GetHashKey("creation"))
        -- RefreshInterior(interior)
        -- SetTimecycleModifier("creation") -- Desactivado porque causa fondo verde
        SetEntityCoords(CreationPed, Config.CreationCoords.x, Config.CreationCoords.y, Config.CreationCoords.z)
        SetEntityHeading(CreationPed, Config.CreationCoords.w)
    end
    SetEntityVisible(CreationPed, true, false)
    -- Wait(2000)
    CreateThread(function()
        StartCreationThread()
    end)
    StartCamera(true, existingPed)

    Citizen.SetTimeout(1000, function()
        MoveCamera('ZONE_HEAD')
        local isMp = IsMpPedModel(GetEntityModel(CreationPed))
        OpenClothing('creation', {
            headBlend = isMp and GetHeadBlendData(CreationPed) or nil,
            faceFeatures = isMp and GetPedFaceFeatures(CreationPed) or nil,
            headOverlays = isMp and GetPedHeadOverlays(CreationPed) or nil,
            drawables = GetPedDrawables(CreationPed),
            props = GetPedProps(CreationPed),
        })

        --[[ Aviso de que la creacion ya se puede ver.

             Quien llega desde el selector de personaje lo hace con la pantalla
             en negro a proposito: origen_titlemenu deja puesto su telon para
             que no se vea el teletransporte ni el viaje de camara. Este es el
             momento de abrirlo, y no antes: MoveCamera interpola 700 ms hasta
             la cara y el panel tarda otro poco en pintarse. ]]
        Citizen.SetTimeout(900, function()
            TriggerEvent('origen_clothing:client:creationReady')
        end)

    end)

    promiseId = promise.new()
    return Citizen.Await(promiseId)
end

--TODO: Verificar si esto se ejecuta solo para crear un personaje o siempre
function EndPedCreation()
    if creationTeleport then
        TriggerServerEvent("qbx_afk:server:SetAFKPaused", false)
        Wait(600)
    end
    InSelection = false
    StopCamera()
    ForceCleanupCameraSystem()
    TriggerEvent("qb-weathersync:client:EnableSync")
    TriggerServerEvent('origen_clothing:setRoutingBucket', false)
    SaveAppearance()

    -- Notify titlemenu that character creation is complete
    TriggerEvent('origen_clothing:client:creationComplete')

    -- Ejecutar callback del multicharacter si existe
    if GetMulticharacterCallbacks then
        local multicharacterCallbacks = GetMulticharacterCallbacks()
        if multicharacterCallbacks and multicharacterCallbacks.submit then
            debugger("Executing multicharacter submit callback")
            multicharacterCallbacks.submit()
            ClearMulticharacterCallbacks()
        end
    end

    if promiseId then
        promiseId:resolve(GetAppearanceData(CreationPed))
        promiseId = nil
    end
    if not creationTeleport then
        debugger("Ignore creation teleport")
        return
    end
    
    -- Teleport player to spawn coordinates after first-time character creation
    if Config.SpawnCoords then
        debugger("Teleporting player to spawn coordinates: ", Config.SpawnCoords)
        
        -- Fade to black
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do
            Wait(0)
        end
        
        -- Teleport while screen is black
        SetEntityCoords(PlayerPedId(), Config.SpawnCoords.x, Config.SpawnCoords.y, Config.SpawnCoords.z, false, false, false, true)
        SetEntityHeading(PlayerPedId(), Config.SpawnCoords.w)
        
        -- Wait a moment to ensure teleport is complete
        Wait(500)
        
        -- Fade back in
        DoScreenFadeIn(500)
    end
end

exports("startPedCreation", StartPedCreation)

function GetAppearanceData(ped, onlyApplied)
    ped = ped or PlayerPedId()
    return {
        model = GetPedModel(ped),
        headBlendData = GetHeadBlendData(ped),
        faceFeatures = GetPedFaceFeatures(ped),
        headOverlays = GetPedHeadOverlays(ped),
        hairTint = GetPedHairTint(ped),
        eyeColor = GetPedEyeColor(ped),
        drawables = GetPedDrawablesHash(ped, nil, onlyApplied),
        props = GetPedPropsHash(ped, nil, onlyApplied),
    }
end

function SetAppearance(ped, skin)
    if not skin then return end

    if skin.model then
        skin.modelHash = GetHashKey(skin.model)
        if GetEntityModel(ped) ~= skin.modelHash then
            debugger("Changing model to ", skin.model)
            initializeClothes(skin.model)
            ped = PlayerPedId()
        end
    end

    if IsMpPedModel(GetEntityModel(ped)) then
        SetHeadBlendData(ped, skin.headBlendData)
        SetPedFaceFeatures(ped, skin.faceFeatures)
        SetHeadOverlays(ped, skin.headOverlays)
        SetHairTint(ped, skin.hairTint)
        if skin.eyeColor then
            SetPedEyeColor(ped, skin.eyeColor)
        end
    end

    if skin.drawables then
        SetPedDrawablesByHash(ped, skin.drawables)
    end
    if skin.props then
        SetPedPropsByHash(ped, skin.props)
    end
end

function SaveAppearance()
    local outfit = Outfit.GetEquipped()
    if outfit and outfit.isJob then
        debugger("Not saving appearance because it's a job outfit.")
        return
    end
    local appearance = GetAppearanceData(cache.ped)

    local guardada = lib.callback.await("origen_clothing:saveAppearance", false, appearance)
    --[[ El servidor quita al guardar lo VIP o exclusivo que no has comprado
         (server/especiales.lua) y lo que no puedes llevar por permiso, como el
         uniforme de otro trabajo (server/main.lua). Si ha quitado algo, te
         viste con lo que ha guardado: si no, lo seguirias llevando puesto
         hasta reconectar. ]]
    if type(guardada) == 'table' and (guardada.drawables or guardada.props) then
        SetPedDrawablesByHash(cache.ped, guardada.drawables)
        SetPedPropsByHash(cache.ped, guardada.props)
        appearance.drawables = guardada.drawables or appearance.drawables
        appearance.props = guardada.props or appearance.props
        Custom.Notify('Te has quitado la ropa que no puedes llevar (VIP, exclusiva o de un trabajo)', 'error', 6000)
    end

    TriggerEvent('origen_clothing:saveAppearance', {
        drawables = appearance.drawables,
        props = appearance.props,
    })
end

--[[ Una recarga cambia el modelo y devuelve la vida al cabo de un segundo. Si
     otra empieza en medio, guarda la vida del ped recien creado (llena) y cura:
     por eso van de una en una. ]]
local recargando = false

local function EnTurno(fn, ...)
    while recargando do Wait(50) end
    recargando = true
    local ok, err = pcall(fn, ...)
    recargando = false
    if not ok then error(err, 0) end
end

function RecargaEnCurso()
    return recargando
end

local function recargarAspecto(overrideModel)
    BackupPlayerStats()
    CurrentAppearance = lib.callback.await("origen_clothing:getAppearance", false, overrideModel)

    local skin = CurrentAppearance.skin and json.decode(CurrentAppearance.skin) or nil

    if not skin?.drawables then
        local defaultModel = overrideModel or 'mp_m_freemode_01'
        initializeClothes(defaultModel)
        CurrentAppearance = {
            model = defaultModel,
            skin = json.encode(GetAppearanceData(cache.ped)),
            hairslots = json.encode({})
        }
        RestorePlayerStats()
        return
    end
    
    CurrentAppearance.model = tonumber(CurrentAppearance.model) or CurrentAppearance.model
    local hasJobOutfit = Outfit.GetEquipped(true)
    
    initializeClothes(CurrentAppearance.model)

    SetAppearance(cache.ped, json.decode(CurrentAppearance.skin))

    if hasJobOutfit then
        hasJobOutfit:Equip(cache.ped)
    end

    RestorePlayerStats()

    -- Initialize hair slots
    HairSlot.Fetch(json.decode(CurrentAppearance.hairslots))

    -- Restaurar estilo de caminar
    if GetResourceState('origen_anims') == 'started' then
        local currentWalk = exports['origen_anims']:getCurrentWalk()
        if currentWalk and currentWalk ~= 'default' then
            exports['origen_anims']:setWalk(currentWalk)
        end
    end
end

function ReloadAppearanceData(overrideModel)
    EnTurno(recargarAspecto, overrideModel)
end

local function reaplicarAspecto()
    -- SetAppearance puede cambiar el modelo: la vida se guarda antes igual que al recargar
    BackupPlayerStats()
    SetAppearance(PlayerPedId(), json.decode(CurrentAppearance.skin))

    RestorePlayerStats()

    -- Restaurar estilo de caminar
    if GetResourceState('origen_anims') == 'started' then
        local currentWalk = exports['origen_anims']:getCurrentWalk()
        if currentWalk and currentWalk ~= 'default' then
            exports['origen_anims']:setWalk(currentWalk)
        end
    end
end

function ReApplyAppearance()
    if not CurrentAppearance or not CurrentAppearance.skin then
        debugger("No current appearance to reapply. Reloading skin...")
        ReloadAppearanceData()
        return
    end
    EnTurno(reaplicarAspecto)
end

function getAppearance(citizenid)
    return lib.callback.await("origen_clothing:getAppearanceByCitizenid", false, citizenid)
end

exports("SetAppearance", SetAppearance)
exports("SetDefaultPedValues", SetDefaultPedValues)
exports("GetAppearanceData", GetAppearanceData)
exports("ReloadAppearanceData", ReloadAppearanceData)
exports("ReApplyAppearance", ReApplyAppearance)
exports("getAppearance", getAppearance)

local lastTotalPed = nil

function UpdateTotals(ped)
    if lastTotalPed == ped then
        return
    end
    lastTotalPed = ped
    SendNUIMessage({
        action = 'updateTotals',
        totals = Store:GetGlobalCloths(ped),
    })
end

function GetCreationTeleport()
    return creationTeleport
end