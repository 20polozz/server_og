CharacterUnloaded = false

function OnPlayerLoad()
    if Player then
        --[[ Existir no es estar cargado. El Player se puede haber creado antes de
             que el framework tuviera el personaje --una tecla pulsada en el menu
             de inicio, el hilo del bridge adelantandose a la sesion-- y entonces
             se quedo sin inventario. Con el `return` seco de antes nadie volvia a
             pedirlo en toda la sesion: de ahi el reconectar para arreglarlo. ]]
        if type(Player.inventory) ~= 'table' or not next(Player.inventory) then
            Player:LoadInventory()
        end
        return
    end
    CharacterUnloaded = false
    Player = Player_Class:new()
    debugger("[Player] Player Load & Created")
end

exportsQB('OnPlayerLoad', OnPlayerLoad)
exports('OnPlayerLoad', OnPlayerLoad)

function clearCache()
    Citizen.Wait(1000)
    collectgarbage("collect")
    collectgarbage("restart")
end

function OpenInventory(other, invType)
    if not Player then
        if CharacterUnloaded then return end
        OnPlayerLoad()
        return
    end
    -- if Player.isOpen then
    --     Player:CloseInventory()
    --     return
    -- end
    
    if cache.vehicle then
        local vehClass = GetVehicleClass(cache.vehicle)
        local isVehicleWithHud = cache.seat == -1
        if isVehicleWithHud then
            TriggerEvent('origen_hud:client:hideVehicleHud', true)
        end
    end
    
    Player:OpenInventory(other, invType)
end
RegisterNetEvent('inventory:client:OpenInventory', OpenInventory)



function DisableEscKey()
    CreateThread(function()
        if not Config.DisableMovementOnInventoryOpen then
            return
        end

        while Player.isOpen do
            Wait(3)
            DisableAllControlActions(0)
        end
    end)

    CreateThread(function()
        while Player.isOpen do
            Wait(3)
            DisableControlAction(0, 36, true)
        end
    end)

    CreateThread(function()
        if not Config.DisableEscOnInventoryOpen then
            return
        end

        local timeMs = 300
        local timerToClose = GetGameTimer() + timeMs
        local currentTimer = 0

        while Player.isOpen or IsControlReleased(0, 200) do
            DisableControlAction(0, 177, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 202, true)

            if IsDisabledControlJustReleased(0, 200) then
                break
            end

            if not Player.isOpen then
                currentTimer = GetGameTimer()
                if currentTimer - timerToClose > timeMs then
                    break
                end
            else
                timerToClose = GetGameTimer() + timeMs
            end

            Wait(3)
        end

        Wait(100)
    end)
end

function UpdateInventory(other, clearInventory)
    if not Player then
        if CharacterUnloaded then return end
        OnPlayerLoad()
        return
    end

    Player:UpdateInventory(other, clearInventory)
end

exportsQB('UpdateInventory', UpdateInventory)
exports('UpdateInventory', UpdateInventory)

function CloseInventory(isServer, isNui)
    Player.isOpen = false
    if Player.other then
        TriggerServerEvent('origen_inventory:server:CloseInventory', Player.other)
    end
    Player:CloseInventory(isServer, isNui)
end

exportsQB('CloseInventory', CloseInventory)
exports('CloseInventory', CloseInventory)

local function ListenClose(targetPed)
    if Player.inloop then return end
    CreateThread(function()
        Citizen.Wait(500)
        local timeout = 0
        -- Esperar a que el inventario se abra y coja el foco NUI
        while not IsNuiFocused() and timeout < 20 do
            Citizen.Wait(100)
            timeout = timeout + 1
        end

        Player.inloop = true
        while Player.inloop do
            Wait(500)
            if not targetPed or not DoesEntityExist(targetPed) then
                Player.inloop = false
                Player:CloseInventory()
                ExecuteCommand("closeinv")
                return
            end

            local playerPed = PlayerPedId()
            local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed))
            
            if distance > 4.0 then
                Player.inloop = false
                Player:CloseInventory()
                ExecuteCommand("closeinv")
                Bridge.Notify(locale:t('notify.search.notclose'), 'error')
                return
            end

            -- Si el jugador ya ha cerrado el inventario manualmente, paramos el bucle
            if not IsNuiFocused() then
                Player.inloop = false
                return
            end
        end
    end)
end


function SearchClosest()
    local player, distance = Player:GetClosestPlayer()
    if Player.inloop then return end

    if player and distance <= 1.0 and distance > 0 then
        if Bridge.CanSearch(GetPlayerPed(player)) then
            local plyId = GetPlayerServerId(player)
            local targetPed = GetPlayerPed(player)
            RequestAnimDict("anim@gangops@facility@servers@bodysearch@")
            while not HasAnimDictLoaded("anim@gangops@facility@servers@bodysearch@") do
                Citizen.Wait(100)
            end
            Bridge.ProgressBar('search_player_inv', locale:t('notify.search.searching'), 5000,
                exports.origen_inventory:controls(false, false, false, false),
                exports.origen_inventory:progress_animation_fix({ dict = "anim@gangops@facility@servers@bodysearch@", clip = "player_search" }),
                false, function(result)
                    if result then
                        StopAnimTask(PlayerPedId(), "anim@gangops@facility@servers@bodysearch@", "player_search", 1.0)
                        TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", plyId)
                        ListenClose(targetPed)
                    end
                end)
        else
            Bridge.Notify(locale:t('notify.search.nothandsup'), 'error')
        end
    else
        Bridge.Notify(locale:t('notify.search.notclose'), 'error')
    end
end

eventPublisher:subscribe('origen_inventory:searchPlayer', SearchClosest)
RegisterCommand('searchPlayer', SearchClosest, false)

function GetClosestPlayer(radius)
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, playerId in ipairs(players) do
        local targetPed = GetPlayerPed(playerId)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(targetCoords - playerCoords)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = playerId
                closestDistance = distance
            end
        end
    end
    if closestDistance ~= -1 and closestDistance <= radius then
        return closestPlayer
    else
        return nil
    end
end

function GetClosestVehicle(coords, dist)
    local ped = PlayerPedId()
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = dist or 3
    local closestVehicle = -1
    if not coords then
        coords = GetEntityCoords(ped)
    end

    --[[ El mas cercano de verdad.

         Aqui habia un `break` dentro del `if`: en cuanto encontraba UN coche
         dentro del radio dejaba de buscar, asi que lo que devolvia era el
         primero del pool que estuviera cerca, no el mas cercano. Con dos coches
         aparcados juntos te daba el de al lado, el jugador estaba en el
         maletero del suyo y la comprobacion de sitio fallaba contra el coche
         equivocado: se abria el inventario propio y parecia que el maletero
         "a veces no funciona". El pool no viene ordenado por distancia, asi que
         hay que recorrerlo entero. ]]
    for i = 1, #vehicles, 1 do
        local vehicle = vehicles[i]
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(vehicleCoords - coords)

        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicle
            closestDistance = distance
        end
    end
    return closestVehicle, closestDistance
end

function PlayerInFront()
    local playerPedId = PlayerPedId()
    local pos = GetEntityCoords(playerPedId)
    local entityWorld = GetOffsetFromEntityInWorldCoords(playerPedId, 0.0, 4.0, 0.0)
    local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 4,
        playerPedId, 0)
    local a, b, c, d, result = GetRaycastResult(rayHandle)
    return result
end

local function DisableKeys()
    while Player?.isOpen do
        Wait(0)

        --[[ Lo que de verdad para el puñetazo.

             DisableControlAction apaga la TECLA, y el ataque cuerpo a cuerpo
             entra por varios controles segun el arma que lleves, asi que
             taparlos uno a uno es ir adivinando —de hecho asi ya falle una
             vez—. DisablePlayerFiring corta el disparo y el golpe en la
             raiz, sea cual sea la tecla que lo dispare. ]]
        DisablePlayerFiring(PlayerId(), true)
        --[[ El inventario se abre con SetNuiFocusKeepInput(true) para que el
             juego siga recibiendo teclas —moverse, hablar— mientras lo miras.
             El precio es que hay que apagar a mano todo lo que no toca, y
             faltaban dos de los golpes: al pulsar cualquier cosa del panel el
             personaje pegaba un puñetazo.

             Los de cuerpo a cuerpo son seis y hay que apagarlos los seis:
               140 ligero   141 fuerte   142 alternativo   143 bloqueo
               263 melee 1  264 melee 2
             Estaban 140, 142 y 263; faltaban 141, 143 y 264. ]]
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 143, true)
        DisableControlAction(0, 264, true)

        DisableControlAction(0, 1, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 2, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 257, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 106, true)
        DisableControlAction(0, 287, true)
        DisableControlAction(0, 286, true)
        DisableControlAction(0, 18, true)
        DisableControlAction(0, 45, true)
        DisableControlAction(0, 80, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 263, true)
        DisableControlAction(0, 22, true)
        DisableControlAction(0, 26, true)
        DisableControlAction(0, 68, true)
        DisableControlAction(0, 69, true)
        DisableControlAction(0, 70, true)
        DisableControlAction(0, 91, true)
        DisableControlAction(0, 92, true)
    end
end

local function GiveMarker()
    local giveColor = Config.MarkerColors.give_player
    if not HasStreamedTextureDictLoaded(Sprite.dict) then
        RequestStreamedTextureDict(Sprite.dict)
        while not HasStreamedTextureDictLoaded(Sprite.dict) do
            Wait(10)
        end
    end

    SendDuiMessage(Sprite.dui, json.encode(
        {
            action = 'changeSpriteIcon',
            data = {
                icon = 'lucide:box'
            }
        }
    ))

    while Player?.isOpen do
        local sleep = 1000
        local player = PlayerInFront()
        if player ~= 0 and IsPedAPlayer(player) then
            local coords = GetEntityCoords(player)
            if #(GetEntityCoords(PlayerPedId()) - coords) < Config.Player.GiveDistance then
                sleep = 3
                -- DrawMarker(20, coords + vector3(0, 0, 1.1), 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.1, 0.1, 0.1, giveColor.x, giveColor.y, giveColor.z, giveColor.w, 1, 0, 0, 1)

                local camCoords = GetGameplayCamCoord()
                local distance = #(coords - camCoords)
                local scale = 1.3
                scale = math.floor(scale * 10000) / 10000
                scale = scale * math.exp(-0.15 * distance)
    
                local spriteScale = scale > 0.02 and scale or 0.02
                SetScriptGfxAlignParams(0.0, 0.0, 0.0, 0.0)

                local finalCoords = coords + vector3(0, 0, 1.0)
                SetDrawOrigin(finalCoords.x, finalCoords.y, finalCoords.z)
                DrawInteractiveSprite(Sprite.dict, Sprite.txt, 0.0, 0.0, spriteScale, spriteScale, 0.0, 255, 255, 255, 255)
            end
        end
        Wait(sleep)
    end

    SetStreamedTextureDictAsNoLongerNeeded(Sprite.dict)
end

function NUIFocus(nui, keep)
    SetNuiFocus(nui, nui)
    SetNuiFocusKeepInput(type(keep) == 'nil' and false or keep)
    if keep then
        CreateThread(DisableKeys)
        CreateThread(GiveMarker)
    end
end

local function IsBackEngine(vehModel)
    return Config.BackEngineVehicles[vehModel]
end

function CheckVehicleDistance()
    local vehicle = CurrentVehicle
    local distance = 0

    if not vehicle then return end

    while distance < Config.TrunkOpenDistance do
        local vehicleCoords = GetEntityCoords(vehicle)
        local playerCoords = GetEntityCoords(PlayerPedId())

        distance = #(vehicleCoords - playerCoords)
        Wait(500)
    end

    if Player then
        Player:CloseInventory()
    end
end

function OpenTrunkAnim()
    local vehicle = GetClosestVehicle(false, 3)
    while (not HasAnimDictLoaded("amb@prop_human_bum_bin@idle_b")) do
        RequestAnimDict("amb@prop_human_bum_bin@idle_b")
        Citizen.Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), "amb@prop_human_bum_bin@idle_b", "idle_d", 4.0, 4.0, -1, 50, 0, false, false, false)
    if (IsBackEngine(GetEntityModel(vehicle))) then
        SetVehicleDoorOpen(vehicle, 4, false, false)
    else
        SetVehicleDoorOpen(vehicle, 5, false, false)
    end
end

function CloseTrunkAnim()
    local vehicle = CurrentVehicle
    while (not HasAnimDictLoaded("amb@prop_human_bum_bin@idle_b")) do
        RequestAnimDict("amb@prop_human_bum_bin@idle_b")
        Citizen.Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), "amb@prop_human_bum_bin@idle_b", "exit", 4.0, 4.0, -1, 50, 0, false, false, false)
    if (IsBackEngine(GetEntityModel(vehicle))) then
        SetVehicleDoorShut(vehicle, 4, false)
    else
        SetVehicleDoorShut(vehicle, 5, false)
    end
end

function IsMpPed(ped)
    local Male = GetHashKey("mp_m_freemode_01")
    local Female = GetHashKey("mp_f_freemode_01")
    local CurrentModel = GetEntityModel(ped)
    if CurrentModel == Male then
        return "Male"
    elseif CurrentModel == Female then
        return "Female"
    else
        if Bridge.CustomPeds then
            for k, v in pairs(Bridge.CustomPeds) do
                if CurrentModel == GetHashKey(k) then
                    return v
                end
            end
        end
    end
end

function IncurCooldown(ms)
    Citizen.CreateThread(function()
        Cooldown = true
        Wait(ms)
        Cooldown = false
    end)
end

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(5)
    end
end

function GetClosestNearbyPlayer()
    local closestPlayer = nil
    local closestDistance = Config.Player.GiveDistance or 3
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, playerId in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(playerId)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            if distance <= closestDistance then
                closestDistance = distance
                local pId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
                closestPlayer = {
                    playerId = pId,
                    name = Config.UI.ShowPlayerNameOnGiveItem and GetPlayerName(playerId) or pId,
                    indice = playerId,
                    distance = distance
                }
            end
        end
    end

    return closestPlayer
end

--- Todos los que estan lo bastante cerca para darles algo, del mas cercano al
--- mas lejano.
---
--- GetClosestNearbyPlayer devuelve solo el primero, y eso valia cuando dar era
--- un boton a ciegas: pulsabas y el objeto se iba a quien tuvieras mas cerca,
--- que con dos personas juntas es una moneda al aire. Para poder elegir hay que
--- enseñarlos todos.
---
--- Va el id DEL SERVIDOR y no el nombre. GetPlayerName devuelve el nombre de
--- la cuenta, no el del personaje, asi que enseñarlo aqui es enterarse fuera
--- de personaje de quien tienes delante --y Config.UI.ShowPlayerNameOnGiveItem
--- no manda en esta lista por eso mismo--. El id no dice nada de nadie y
--- senala igual de bien. Es ademas el unico numero que significa lo mismo aqui
--- y en el servidor: el indice local no le dice nada.
---
--- Quien comprueba la distancia de verdad es el servidor, en
--- giveInventoryItemToPlayer: esta lista es para poder elegir, no un permiso.
function GetNearbyPlayers()
    local maxDistance = Config.Player.GiveDistance or 3
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local lista = {}

    for _, playerId in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(playerId)
        if targetPed ~= playerPed then
            local distance = #(playerCoords - GetEntityCoords(targetPed))
            if distance <= maxDistance then
                local pId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
                lista[#lista + 1] = { playerId = pId, distance = distance }
            end
        end
    end

    table.sort(lista, function(a, b) return a.distance < b.distance end)
    return lista
end

-- Get the first near player from me



------------------------------
---
---     REFACTORING
--- 



CreateThread(function()
    while true do

        if not Inventory.wheelEnabled then
            BlockWeaponWheelThisFrame()
            DisableControlAction(0, 37, true)
        end

        if Config.DisablePKey then
            DisableControlAction(0, 199, true)
        end
        
        Wait(3)
    end
end)