activeMission = {}
local BoostingData = -1
local Clasifications = {}
local propEntity
local lastVehicle = 0
local hacksHUD = false
InTablet = false
local openedFromHub = false
local tabletOpenTarget = 'mainBoosting'

RegisterNetEvent('origen_boosting:cl:generateVehZone', function(data)
    Internal.Notify(locale('in_game.notifications.vehicle_location'), 'info', 5000)
    activeMission.uniqueID = data.uniqueID
    activeMission.id = data.id
    --[[ La zona donde esta el coche: un circulo, no un sitio exacto. El
         desplazamiento al azar es lo que hace que haya que buscarlo.

         Ya no es un blip de radio del juego: es un punto de origen_map con
         `radio`, que la interfaz pinta como circulo. ]]
    activeMission.vehZoneBlip = 'zona_vehiculo'

    OrigenMapa.Poner(activeMission.vehZoneBlip, {
        x = data.coords.x + math.random(-100, 100),
        y = data.coords.y + math.random(-100, 100),
        z = data.coords.z,
        cat = 'illegal',
        icono = 'coche',
        nombre = 'Zona del vehiculo',
        radio = 250.0,
        color = '#d81b55',
        prioridad = 10,
    })

    activeMission.vehZone = lib.points.new({
        coords = data.coords,
        distance = 80,
        onEnter = function()
            activeMission.vehZone:remove()
            activeMission.vehZone = nil
            RequestModel(GetHashKey(data.vehicle))
            while not HasModelLoaded(GetHashKey(data.vehicle)) do
                Wait(1)
            end
            local randomColour = getRandomVehicleColor()
            local plate = lib.callback.await('origen_boosting:sv:plateGenerator')
            activeMission.vehId = CreateVehicle(GetHashKey(data.vehicle), data.coords.x, data.coords.y, data.coords.z, data.coords.w, true, true)
            SetVehicleNumberPlateText(activeMission.vehId, plate)
            SetEntityAsMissionEntity(activeMission.vehId)
            SetVehicleColours(activeMission.vehId, randomColour, randomColour)
            SetVehicleDirtLevel(activeMission.vehId, 0.0)
            SetVehicleExtraColours(activeMission.vehId, 0, 0)
            SetVehicleDoorsLocked(activeMission.vehId, 2)
            SetVehicleFuelLevel(activeMission.vehId, 100.0)
            SetVehicleEngineOn(activeMission.vehId, false, true, true)
            TriggerServerEvent('origen_boosting:sv:onEnterVehZone', {
                veh = NetworkGetNetworkIdFromEntity(activeMission.vehId),
                id = data.id
            })
        end
    })
end)

RegisterNetEvent('origen_boosting:cl:generateDeliveryZone', function(data)
    --[[ El punto de entrega. Lleva `ruta`, que es lo unico para lo que se
         sigue creando un blip por debajo —invisible—: GTA solo sabe trazar el
         camino por carretera hasta un blip, y ese trazado es justo lo que el
         mapa dibuja. ]]
    activeMission.deliveryZoneBlip = 'entrega'

    OrigenMapa.Poner(activeMission.deliveryZoneBlip, {
        x = data.coords.x, y = data.coords.y, z = data.coords.z,
        cat = 'illegal',
        icono = 'paquete',
        nombre = locale('in_game.blip.delivery_point'),
        color = '#2ee6a8',
        ruta = true,
        prioridad = 10,
    })

    local deliveryTriggered = false

    local function tryDeliver()
        if deliveryTriggered then return end
        local nearbyVehicles = lib.getNearbyVehicles(data.coords.xyz, 15.0, false)
        for k, v in pairs(nearbyVehicles) do
            if v.vehicle == activeMission.vehId then
                deliveryTriggered = true
                TriggerServerEvent('origen_boosting:sv:deliverVehicle', activeMission)
                if activeMission.deliveryZoneBlip then
                    OrigenMapa.Quitar(activeMission.deliveryZoneBlip)
                    activeMission.deliveryZoneBlip = nil
                end
                if activeMission.deliveryZone then
                    activeMission.deliveryZone:remove()
                    activeMission.deliveryZone = nil
                end
                return
            end
        end
    end

    activeMission.deliveryZone = lib.points.new({
        coords = data.coords,
        distance = 50,
        onEnter = function()
            if not activeMission.leaveNotification then
                activeMission.leaveNotification = true
                Internal.Notify(locale('in_game.notifications.vehicle_deliver'), 'info', 10000)
            end
            -- Intentar entrega al entrar en el radio
            Citizen.SetTimeout(500, tryDeliver)
        end,
        onExit = function()
            -- Intentar entrega al salir (comportamiento original como fallback)
            tryDeliver()
        end,
        nearby = function(self)
            -- Comprobar periódicamente si el vehículo está en la zona
            if self.currentDistance < 30 and not deliveryTriggered then
                local nearbyVehicles = lib.getNearbyVehicles(data.coords.xyz, 15.0, false)
                for k, v in pairs(nearbyVehicles) do
                    if v.vehicle == activeMission.vehId then
                        tryDeliver()
                        return
                    end
                end
            end
        end
    })
end)

RegisterNetEvent('origen_boosting:cl:notify', function(message, type, duration)
    Internal.Notify(message, type, duration)
end)

lib.onCache('vehicle', function(value)
    if value then
        local state = Entity(value).state
        if value == activeMission.vehId then
            if not state.localizerTriggered then
                if state.hacks > 0 then
                    TriggerServerEvent('origen_boosting:sv:onEnterVehicle', activeMission, GetEntityCoords(PlayerPedId()))
                    activeMission.localizer = true
                    ActiveLocalizer()
                else
                    TriggerServerEvent('origen_boosting:sv:removeLocalizer', activeMission.id)
                end
                OrigenMapa.Quitar(activeMission.vehZoneBlip)
                Custom.SendDispatch({
                    coords = activeMission.coords,
                    vehicle = activeMission.vehId
                })
            end
        end

        if state.hacks and state.hacks > 0 then
            SendNUIMessage({
                action = "updateHacks",
                show = true,
                data = state.hacks
            })
            hacksHUD = true
        end
    else
        if hacksHUD then
            SendNUIMessage({
                action = "updateHacks",
                show = false,
                data = 0
            })
            hacksHUD = false
        end
    end
end)

function ActiveLocalizer()
    Citizen.CreateThread(function()
        while activeMission.localizer do
            local veh = GetVehiclePedIsIn(PlayerPedId(), false)
            if activeMission.vehId == veh then
                local vehCoords = GetEntityCoords(GetVehiclePedIsIn(PlayerPedId(), false))
                activeMission.coords = {x = vehCoords.x, y = vehCoords.y, z = vehCoords.z}
                TriggerServerEvent('origen_boosting:sv:localizer', activeMission.id, vehCoords)
            end
            Wait(1000)
        end
    end)
end

local function GetRankIndex(rank)
    for i = 1, #GlobalState.Ranks do
        if GlobalState.Ranks[i].name == rank then
            return i
        end
    end
    return 1
end

local function ParseClasifications()
    for i = 1, #Clasifications do 
        if Clasifications[i].rankVehicle and Clasifications[i].rankProp then
            Clasifications[i].rank = Clasifications[i].rankVehicle
            goto continue
        end
        local ranksPool = (GlobalState.RanksByType and GlobalState.RanksByType.vehicle) or GlobalState.Ranks
        Clasifications[i].rank = GetRankByXP(Clasifications[i].experience, 'vehicle').actualRank.name
        for j = 1, #ranksPool do
            if ranksPool[j].name == Clasifications[i].rank then
                break
            else
                Clasifications[i].experience = Clasifications[i].experience - ranksPool[j].xp
            end
        end
        ::continue::
    end
end

local function GetBoostingData()
    local received = false
    lib.callback("origen_boosting:server:GetBoostingData", source, function(data)
        if not data then
            received = true
            print("^1Failed to get boosting data^0")
        end
        BoostingData = data.player
        Clasifications = data.clasifications
        Offers = data.offers
        PData = data.pData
        ParseClasifications()
        received = true
    end)
    while not received do
        Wait(0)
    end
end

RegisterNetEvent("origen_boosting:client:OpenBoostingCad", function()
    tabletOpenTarget = 'mainBoosting'
    openedFromHub = false
    ToggleTablet(true)
end)

AddEventHandler('gameEventTriggered', function(event, data)
    if event == 'CEventNetworkEntityDamage' then
        local victim, attacker, victimDied, weapon = data[1], data[2], data[4], data[7]
        
        if not IsEntityAPed(victim) then return end
        local PlayerPed = PlayerPedId()
        if victimDied and NetworkGetPlayerIndexFromPed(victim) == PlayerId() and IsEntityDead(PlayerPed) then
            if activeMission and activeMission.id then
                TriggerServerEvent('origen_boosting:sv:onMissionFailed', activeMission.id)
            end
        end
    end
end)

RegisterNetEvent('origen_boosting:cl:missionFailed', function()
    if activeMission.vehZone then
        activeMission.vehZone:remove()
    end

    if activeMission.deliveryZone then
        activeMission.deliveryZone:remove()
    end

    if activeMission.vsZone then
        activeMission.vsZone:remove()
    end

    if activeMission.vsBlip then
        OrigenMapa.Quitar(activeMission.vsBlip)
    end

    if activeMission.vsPed then
        DeleteEntity(activeMission.vsPed)
    end

    if activeMission.vehZoneBlip then
        OrigenMapa.Quitar(activeMission.vehZoneBlip)
    end

    if activeMission.deliveryZoneBlip then
        OrigenMapa.Quitar(activeMission.deliveryZoneBlip)
    end

    if activeMission.localizer then
        activeMission.localizer = false
        SendNUIMessage({
            action = "updateHacks",
            show = false,
            data = 0
        })
    end

    -- Limpiar estado de misión completamente
    activeMission = {}
end)

RegisterNetEvent('origen_missions:client:OnMissionFailed', function(data)
    TriggerEvent('origen_boosting:cl:missionFailed', data and data.reason or nil)
end)

RegisterNetEvent('origen_missions:client:OnMissionCompleted', function(data)
    TriggerEvent('origen_boosting:cl:missionFailed')
end)

function ToggleTablet(value, delayFocus)
    if value == InTablet then return end
    SetNuiFocusKeepInput(false)
    DisableAllControlActions(0)
    Citizen.Wait(1)
    if value ~= nil then
        InTablet = value
    else
        InTablet = not InTablet
    end
    if InTablet then
        GetBoostingData() -- We're going to get the data every time the tablet is opened, so we can keep it updated until we make a differnt approach
        if type(BoostingData) == "table" then
            BoostingData.rankVehicle = GetRankByXP(BoostingData.experience_vehicle or BoostingData.experience or 0, 'vehicle')
            BoostingData.rankProp = GetRankByXP(BoostingData.experience_prop or 0, 'prop')
            BoostingData.rank = BoostingData.rankVehicle

            for k, v in pairs(BoostingData.saved) do
                v.started = k == activeMission.uniqueID and true or nil 
            end
        end

        RequestAnimDict('amb@code_human_in_bus_passenger_idles@female@tablet@idle_a')
        while not HasAnimDictLoaded('amb@code_human_in_bus_passenger_idles@female@tablet@idle_a') do
            Wait(500)
        end

        local prop = "prop_cs_tablet"
        if not IsPedInAnyVehicle(PlayerPedId(), false) then
            TaskPlayAnim(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 2.0, 3.0, -1, 51, 0, false, false, false)
            propEntity = CreateObject(GetHashKey(prop), 0, 0, 0, true, true, true)
            AttachEntityToEntity(propEntity, PlayerPedId() ,GetPedBoneIndex(PlayerPedId(), 28422), -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, 0, true, true, true)
        end

        SendNUIMessage({
            action = "openCad",
            data = type(BoostingData) == "table" and BoostingData or nil,
            clasifications = Clasifications,
            offers = Offers,
            pData = PData,
            openTarget = tabletOpenTarget,
            citizen = Framework.GetIdentifier(),
            riel = RielCompartido(),
            source = GetPlayerServerId(PlayerId())
        })
        
        -- Solo activar focus si no se especifica delayFocus
        if not delayFocus then
            SetNuiFocus(true, true)
        end
    else
        if propEntity ~= nil then
            ClearPedSecondaryTask(PlayerPedId())
            DetachEntity(propEntity, false, false)
            DeleteEntity(propEntity)
        end
        SetNuiFocus(false, false)
    end
end

--[[ La tablet es un panel del riel, como el Racing Hub: lleva en el canto la
     barra de todos los menus, que se la pide al inventario, y desde ella se
     salta a los demas (08/10). Sin inventario devuelve nil y la interfaz
     pone sus propias secciones en la barra, como antes. ]]
function RielCompartido()
    if GetResourceState('origen_inventory') ~= 'started' then return nil end
    local ok, riel = pcall(function()
        return exports['origen_inventory']:GetRiel('boosting')
    end)
    if not ok or type(riel) ~= 'table' then return nil end
    return riel
end

--[[ Saltar a otro panel desde el riel. Se cierra la tablet (animacion, prop
     y foco) y el destino se abre a los 200 ms; el `true` es el aviso de
     relevo, para que la barra no se mueva. Igual que hub:irDelRiel en
     origen_racing/client/main.lua. ]]
--[[ Los avisos de la tablet, por los de Origen (origen_notify), como en el
     resto del servidor: antes la interfaz pintaba los suyos encima de la
     cabecera. Si origen_notify no esta, se contesta false y la tablet pinta
     el de casa. ]]
RegisterNUICallback("notificar", function(data, cb)
    if GetResourceState('origen_notify') ~= 'started' or type(data) ~= 'table' then
        cb(false)
        return
    end
    local tipos = { success = true, error = true, info = true, warning = true }
    TriggerEvent('origen_notify:client:Notify',
        tipos[data.type] and data.type or 'info',
        tostring(data.title or ''),
        tostring(data.message or ''))
    cb(true)
end)

RegisterNUICallback("irDelRiel", function(data, cb)
    cb(true)

    if InTablet then
        ToggleTablet(false)
        InTablet = false
    end
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    openedFromHub = false

    if GetResourceState('origen_inventory') ~= 'started' then return end
    local destino = data and data.id
    if not destino then return end

    CreateThread(function()
        Wait(200)
        if data.tipo == 'acceso' then
            exports['origen_inventory']:AbrirAcceso(destino, true)
        else
            exports['origen_inventory']:AbrirEnPestana(destino, true)
        end
    end)
end)

RegisterNUICallback("close", function(data, cb)
    if InTablet then
        ToggleTablet(false)
        Citizen.Wait(100)
        InTablet = false
    end
    -- Siempre, no solo con la tablet: el aviso de contrato entrante tambien
    -- coge el foco (SetIncomingPopupFocus) y se cierra por aqui.
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    cb(true)
    
    if openedFromHub then
        openedFromHub = false
        exports['origen_admin']:ReturnToScripts()
    end
end)

RegisterNUICallback("get_lang", function(data, cb)
    cb(Config.Language)
end)

RegisterNUICallback("GetConfig", function(data, cb)
    local vehicles = Config.VehicleModels or {}
    local okVehicles, allVehicles = pcall(function()
        if type(GetAllVehicleModels) == 'function' then
            return GetAllVehicleModels()
        end
        return nil
    end)

    if okVehicles and type(allVehicles) == 'table' and #allVehicles > 0 then
        vehicles = allVehicles
        table.sort(vehicles, function(a, b)
            return tostring(a) < tostring(b)
        end)
    end

    local fullMinigameList = {
        'StartLockpick',
        'StartHacking',
        'StartCodeBreaker',
        'StartWirePuzzle',
        'StartMinesweeper',
        'StartTimingCircles',
        'StartVarHack',
        'StartPowerGrid'
    }

    local minigameMap = {}
    for i = 1, #fullMinigameList do
        minigameMap[fullMinigameList[i]] = true
    end

    if Config.Minigame and Config.Minigame.Options then
        for i = 1, #Config.Minigame.Options do
            minigameMap[Config.Minigame.Options[i]] = true
        end
    end

    local minigames = {}
    for name in pairs(minigameMap) do
        minigames[#minigames + 1] = name
    end
    table.sort(minigames, function(a, b)
        return tostring(a) < tostring(b)
    end)

    local missionPoints = GlobalState.OrigenMissionPoints or {}
    local spawnPoints = missionPoints.spawn
    local deliveryPoints = missionPoints.delivery
    if not spawnPoints or #spawnPoints == 0 then
        spawnPoints = Config.Zones.spawn
    end
    if not deliveryPoints or #deliveryPoints == 0 then
        deliveryPoints = Config.Zones.delivery
    end

    cb({
        categories = GlobalState.Ranks,
        rankSettings = GlobalState.Ranks or {},
        missionCategories = (Config.Missions and Config.Missions.UI and Config.Missions.UI.MissionCategories) or { 'Aprendiz', 'Operativo', 'Veterano', 'Jefe' },
        difficulties = Config.Guards.difficulties,
        weapons = Config.Weapons,
        vehicles = vehicles,
        props = (Config.Missions and Config.Missions.UI and Config.Missions.UI.Props) or {
            'prop_box_wood01a',
            'prop_ld_case_01',
            'prop_cs_package_01',
            'prop_money_bag_01',
            'hei_prop_heist_thermite',
            'prop_drug_package'
        },
        peds = {
            'g_m_y_mexgang_01',
            'g_m_y_ballasout_01',
            'g_m_y_famca_01',
            's_m_y_dealer_01',
            'u_m_y_party_01'
        },
        spawnPoints = spawnPoints,
        deliveryPoints = deliveryPoints,
        minigames = minigames,
        minigameDifficulties = Config.Minigame.AdminDifficultyOptions or {'auto', 'easy', 'medium', 'hard', 'extreme'},
        transference = Config.Currency.AllowTransference,
    })
end)

RegisterNUICallback("CapturePlayerPosition", function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    cb({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = heading
    })
end)

local function PointPlacement_RaycastCamera(distance)
    local camRot   = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local rad = math.pi / 180
    local dir = {
        x = -math.sin(camRot.z * rad) * math.abs(math.cos(camRot.x * rad)),
        y =  math.cos(camRot.z * rad) * math.abs(math.cos(camRot.x * rad)),
        z =  math.sin(camRot.x * rad)
    }
    local dest = vector3(camCoord.x + dir.x * distance, camCoord.y + dir.y * distance, camCoord.z + dir.z * distance)
    local _, hit, coords = GetShapeTestResult(
        StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
    )
    return hit, coords
end

-- Mientras se coloca un punto la tablet esta cerrada pero InTablet sigue en
-- true; openManagement lo mira para no dar el raton sin pantalla delante.
local colocando = false

RegisterNUICallback("StartPointPlacement", function(data, cb)
    local ped         = PlayerPedId()
    local origin      = GetEntityCoords(ped)
    local pointType   = data.pointType or 'spawn'
    local objectiveType  = data.objectiveType or 'vehicle'
    local objectiveModel = data.objectiveModel or (objectiveType == 'vehicle' and 'blista' or 'prop_box_wood01a')
    local radius      = tonumber(data.radius) or (pointType == 'delivery' and 12.0 or 6.0)

    -- Load ghost model
    local modelHash = GetHashKey(objectiveModel)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(0) end

    local ghostEntity
    if objectiveType == 'vehicle' then
        ghostEntity = CreateVehicle(modelHash, origin.x, origin.y, origin.z, GetEntityHeading(ped), false, false)
        SetVehicleEngineOn(ghostEntity, false, true, true)
    elseif objectiveType == 'ped' then
        ghostEntity = CreatePed(4, modelHash, origin.x, origin.y, origin.z, GetEntityHeading(ped), false, true)
    else
        ghostEntity = CreateObject(modelHash, origin.x, origin.y, origin.z, false, false, false)
    end
    SetEntityCollision(ghostEntity, false, false)
    SetEntityAlpha(ghostEntity, 170, false)
    FreezeEntityPosition(ghostEntity, true)
    SetEntityInvincible(ghostEntity, true)

    SendNUIMessage({ action = "closeCad" })
    SetNuiFocus(false, false)
    colocando = true

    -- Show hud controls
    if GetResourceState('origen_hud') == 'started' then
        exports.origen_hud:setupControls({
            { key = 'SCROLL',     text = 'Rotar' },
            { key = 'UP / DOWN',  text = 'Altura' },
            { key = 'ENTER',      text = 'Confirmar' },
        })
    end

    local function finishPlacement()
        if ghostEntity and DoesEntityExist(ghostEntity) then
            DeleteEntity(ghostEntity)
        end
        SetModelAsNoLongerNeeded(modelHash)
        if GetResourceState('origen_hud') == 'started' then
            exports.origen_hud:hideControls()
        end
        SendNUIMessage({
            action    = "openCad",
            data      = type(BoostingData) == "table" and BoostingData or nil,
            clasifications = Clasifications,
            offers    = Offers,
            pData     = PData,
            openTarget = 'createMenu',
            citizen   = Framework.GetIdentifier(),
            source    = GetPlayerServerId(PlayerId())
        })
        colocando = false
        InTablet = true
        SetNuiFocus(true, true)
    end

    local placing   = true
    local pos       = vector3(origin.x, origin.y, origin.z)
    local rot       = GetEntityHeading(ped)
    local heightOffset = 0.0

    CreateThread(function()
        while placing do
            Wait(0)

            -- Block shoot / attack / jump
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)

            -- Raycast position
            local hit, rayCoords = PointPlacement_RaycastCamera(50.0)
            if hit and rayCoords then
                pos = vector3(rayCoords.x, rayCoords.y, rayCoords.z + heightOffset)
            else
                local forward = GetEntityForwardVector(ped)
                local fallback = GetEntityCoords(ped) + forward * 3.0
                pos = vector3(fallback.x, fallback.y, fallback.z + heightOffset)
            end

            -- Scroll wheel → rotate
            local scrollUp   = GetControlNormal(0, 241) -- mouse wheel up
            local scrollDown = GetControlNormal(0, 242) -- mouse wheel down
            if scrollUp > 0.0 then
                rot = (rot + scrollUp * 180.0) % 360.0
            elseif scrollDown > 0.0 then
                rot = (rot - scrollDown * 180.0) % 360.0
            end

            -- Arrow UP/DOWN → height
            if IsControlPressed(0, 172) then heightOffset = heightOffset + 0.03 end
            if IsControlPressed(0, 173) then heightOffset = heightOffset - 0.03 end

            SetEntityCoordsNoOffset(ghostEntity, pos.x, pos.y, pos.z, false, false, false)
            SetEntityHeading(ghostEntity, rot)

            -- Draw radius marker
            DrawMarker(
                1,
                pos.x, pos.y, pos.z - 0.1,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                radius * 2.0, radius * 2.0, 0.5,
                216, 27, 85, 100,   -- rosa pegatina
                false, false, 2, false, nil, nil, false
            )

            -- Confirm
            if IsControlJustReleased(0, 191) then
                placing = false
                local finalPos = GetEntityCoords(ghostEntity)
                finishPlacement()
                cb({
                    ok     = true,
                    coords = { x = finalPos.x, y = finalPos.y, z = finalPos.z, w = rot },
                    radius = radius
                })
            -- Cancel
            elseif IsControlJustReleased(0, 177) then
                placing = false
                finishPlacement()
                cb({ ok = false })
            end
        end
    end)
end)

RegisterNUICallback("TriggerCallback", function(data, cb)
    local name = data.__name
    data.__name = nil
    lib.callback(name, source, function(retval)
        cb(retval)
    end, data)
end)

RegisterNUICallback("SetIncomingPopupFocus", function(data, cb)
    local state = data and data.state == true
    -- Con la tablet abierta el raton es suyo: apagar el cursor del aviso no
    -- puede quitarselo. Salvo colocando un objetivo: la tablet esta
    -- escondida y el raton es del juego (si no, el aviso lo cogia en medio).
    local f = state or (InTablet and not colocando)
    SetNuiFocus(f, f)
    SetNuiFocusKeepInput(false)
    cb(true)
end)

RegisterNetEvent("origen_boosting:client:GiveContract", function(contractData)
    Internal.Notify(locale('in_game.notifications.contract_received'), 'info', 5000)
    SendNUIMessage({
        action = "giveContract",
        data = contractData
    })
end)

RegisterCommand('togglecontractcursor', function()
    SendNUIMessage({
        action = "toggleIncomingPopupCursor"
    })
end, false)

RegisterKeyMapping('togglecontractcursor', 'Carboosting: ratón en el contrato', 'keyboard', 'I')

RegisterNetEvent('origen_boosting:cl:SendCoins', function(amount)
    if InTablet then
        SendNUIMessage({
            action = "receiveCoins",
            amount = amount
        })
    else
        Internal.Notify(locale('in_game.notifications.coins_received', amount), 'info', 5000)
    end
end)

RegisterNetEvent('origen_boosting:cl:RegisterBonus', function(amount)
    if InTablet then
        SendNUIMessage({
            action = "registerBonus",
            amount = amount
        })
    else
        Internal.Notify(locale('in_game.notifications.register_bonus', amount), 'success', 5000)
    end
end)

RegisterNetEvent('origen_boosting:cl:HackerXP', function(amount)
    Internal.Notify(locale('in_game.notifications.hacker_xp_received', amount), 'success', 5000)
    if InTablet then
        SendNUIMessage({
            action = "hackerXP",
            amount = amount
        })
    end
end)

RegisterNetEvent('origen_boosting:cl:UpdateXP', function(data)
    if InTablet then
        SendNUIMessage({
            action = 'updateXP',
            data   = data
        })
    end
end)

RegisterNetEvent('origen_boosting:cl:destroyVehicle', function()
    Custom.VehicleDestroy(activeMission.vehId)
end)

RegisterNUICallback("GetRanks", function(data, cb)
    cb(GlobalState.Ranks or {})
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if propEntity ~= nil then
            ClearPedSecondaryTask(PlayerPedId())
            DetachEntity(propEntity, false, false)
            DeleteEntity(propEntity)
        end
        SetNuiFocus(false, false)
    end
end)

exports('OpenCAD', function()
    tabletOpenTarget = 'mainBoosting'
    openedFromHub = false
    ToggleTablet(true)
end)

-- Hub Integration
exports('IsOpenedFromHub', function() return openedFromHub end)
exports('ResetHubFlag', function() openedFromHub = false end)

exports('openManagement', function()
    openedFromHub = true
    tabletOpenTarget = 'createMenu'
    
    CreateThread(function()
        -- Abrir el tablet pero sin activar focus todavía
        ToggleTablet(true, true)  -- true = delayFocus
        
        -- Esperar 2.8 segundos antes de activar el focus
        Wait(2800)
        
        -- AHORA activar el focus
        -- Si en esos 2,8 s se cerro la tablet o se empezo a colocar un punto,
        -- no hay pantalla que reciba el raton.
        if InTablet and not colocando then SetNuiFocus(true, true) end
    end)
end)

AddStateBagChangeHandler('hacks', nil, function(bagName, _, value, _, replicated)
    local entity = GetEntityFromStateBagName(bagName)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)

    if entity == activeMission.vehId and value == 0 then
        activeMission.localizer = false
    end

    if (entity ~= 0 and veh ~= 0) and entity == veh then
        SendNUIMessage({
            action = "updateHacks",
            show = value > 0,
            data = value
        })
    end
end)