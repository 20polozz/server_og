Nui = {}
local propEntity = nil
local nuiMenuOpen = false

Nui.ToggleMenu = function(state)

    if state then
        if LocalPlayer.state.orgInWar then
            debugger('NUI Menu: cant toggle while in war')
            return
        end
        if not Custom.CanOpenTablet() then
            debugger('NUI Menu: cant open table')
            return
        end
    end

    nuiMenuOpen = state

    SendNUIMessage({
        action = 'toggleMenu',
        data = {
            state = state,
            localTime = GetNetworkTime(),
            playerName = GetPlayerName(PlayerId()),
            lobbyList = GlobalState['orgStorms_lobbyList'],
            storms = GlobalState['orgStorms_storms'] or {},
            missionTime = GlobalState.Missions_Times,
            inStom = Storms.id,
        }
    })

    if state then
        lib.requestAnimDict('amb@code_human_in_bus_passenger_idles@female@tablet@idle_a')

        local prop = "prop_cs_tablet"
        if not IsPedInAnyVehicle(PlayerPed) then
            TaskPlayAnim(PlayerPed, "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 2.0, 3.0, -1, 51, 0, false, false, false)
            propEntity = CreateObject(GetHashKey(prop), 0, 0, 0, true, true, true)
            AttachEntityToEntity(propEntity, PlayerPed ,GetPedBoneIndex(PlayerPed, 28422), -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, 0, true, true, true)
        end

        RemoveAnimDict('amb@code_human_in_bus_passenger_idles@female@tablet@idle_a')
    else
        if propEntity ~= nil then
            ClearPedSecondaryTask(PlayerPed)
            DetachEntity(propEntity, false, false)
            DeleteEntity(propEntity)
            propEntity = nil
        end
    end

    SetNuiFocus(state, state)
end

--[[ El raton soltado a la fuerza (el vigilante de origen_map/shared/foco.lua
     o `soltarraton`): la tablet se cierra entera. Si no, nuiMenuOpen seguia en
     true y la tablet pintada, con el prop en la mano y sin raton. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not nuiMenuOpen then return end
        Nui.ToggleMenu(false)
    end)
end

AddEventHandler('onResourceStop', function(resource)
   if resource == GetCurrentResourceName() then
       if propEntity ~= nil then
            ClearPedSecondaryTask(PlayerPed)
            DetachEntity(propEntity, false, false)
            DeleteEntity(propEntity)
            propEntity = nil
        end
        SetNuiFocus(false, false)
   end
end)

Nui.UpdateProfile = function(data)
    SendNUIMessage({
        action = 'updateProfile',
        data = data
    })
end

Nui.UpdateStats = function(data)
    SendNUIMessage({
        action = 'updateStats',
        data = data
    })
end

Nui.UpdateMissions = function(data)
    if not data then return end

    local missions = {}

    for i = 1, #data do
        local mission = data[i]
        if Config.Missions[mission.id] then
            missions[i] = {
                title = Config.Missions[mission.id].title,
                description = Config.Missions[mission.id].description,
                progress = tonumber(mission.progress),
                type = mission.type,
            }
        end
    end

    data = missions

    SendNUIMessage({
        action = 'updateMissions',
        data = data
    })
end

Nui.UpdateFriends = function(data)
    SendNUIMessage({
        action = 'updateFriends',
        data = data
    })
end

Nui.UpdateTeamMembers = function(data)
    SendNUIMessage({
        action = 'UpdateTeamMembers',
        data = data
    })
end

Nui.ToggleHud = function(state)
    SendNUIMessage({
        action = 'toggleHud',
        data = {
            state = state
        }
    })
end

Nui.UpdateHud = function(key, value)
    SendNUIMessage({
        action = 'updateHud',
        data = {
            key = key,
            value = value
        }
    })
end

Nui.UpdateMissionTime = function(time)
    SendNUIMessage({
        action = 'updateMissionTime',
        time = time
    })
end

Nui.ControlsNotify = function(data)
    SendNUIMessage({
        action = 'controls',
        data = {
            visible      = data ~= nil,
            title        = data and data.title or nil,
            currentIndex = data and data.currentIndex or nil,
            totalPlayers = data and data.totalPlayers or nil,
            keys         = data and data.keys or nil,
        }
    })
end

if Config.Commands.OpenMenu.enable then
    RegisterCommand(Config.Commands.OpenMenu.command, function()
        Nui.ToggleMenu(true)
    end)
end

-- El menú de los jugadores y el panel de admin se cierran por el mismo
-- callback (`close`); con esto se sabe si lo abierto era el de admin.
local panelAdminAbierto = false

-- Evento para abrir el panel admin (llamado desde el servidor)
RegisterNetEvent('gangwars:openAdminPanel', function()
    if LocalPlayer.state.orgInWar then
        debugger('Admin Panel: cant toggle while in war')
        return
    end
    
    nuiMenuOpen = true
    panelAdminAbierto = true

    SendNUIMessage({
        action = 'toggleMenu',
        data = {
            state = true,
            localTime = GetNetworkTime(),
            playerName = GetPlayerName(PlayerId()),
            lobbyList = GlobalState['orgStorms_lobbyList'],
            storms = GlobalState['orgStorms_storms'] or {},
            missionTime = GlobalState.Missions_Times,
            inStom = Storms.id,
            adminPanel = true, -- Flag para indicar que es panel admin
        }
    })
    
    lib.requestAnimDict('amb@code_human_in_bus_passenger_idles@female@tablet@idle_a')

    local prop = "prop_cs_tablet"
    if not IsPedInAnyVehicle(PlayerPed) then
        TaskPlayAnim(PlayerPed, "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 2.0, 3.0, -1, 51, 0, false, false, false)
        propEntity = CreateObject(GetHashKey(prop), 0, 0, 0, true, true, true)
        AttachEntityToEntity(propEntity, PlayerPed ,GetPedBoneIndex(PlayerPed, 28422), -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, 0, true, true, true)
    end

    RemoveAnimDict('amb@code_human_in_bus_passenger_idles@female@tablet@idle_a')
    
    SetNuiFocus(true, true)
end)

-- Export para abrir panel admin desde Origen Hub
exports('openManagement', function()
    TriggerServerEvent('origen_gangwars:server:openAdminPanel')
end)

AddStateBagChangeHandler('orgStorms_storms', nil, function(bagName, key, value)
    debugger('[AddStateBagChangeHandler] orgStorms_storms changed. Value type: ' .. type(value))
    if not nuiMenuOpen then
        return
    end
    if value then
        debugger('[AddStateBagChangeHandler] Sending updateStorms with data')
        SendNUIMessage({
            action = 'updateStorms',
            data = {
                storms = value
            }
        })
        debugger('[AddStateBagChangeHandler] Message sent')
    else
        debugger('[AddStateBagChangeHandler] Value is nil, not sending')
    end
end)

AddStateBagChangeHandler('orgStorms_lobbyList', nil, function(bagName, key, value)
    if not nuiMenuOpen then
        return
    end
    SendNUIMessage({
        action = 'updateLobbyList',
        data = {
            storms = value
        }
    })
end)

RegisterNuiCallback('get_settings', function(data, cb)
    local settings = {
        translations = Config.Translations,
        invPath = Internal.GetInventoryPath(),
        allowedExtensions = Config.AllowedExtensions,
    }
    cb(settings)
end)

RegisterNuiCallback('close', function(data, cb)
    nuiMenuOpen = false
    SetNuiFocus(false, false)
    if propEntity ~= nil then
        ClearPedSecondaryTask(PlayerPed)
        DetachEntity(propEntity, false, false)
        DeleteEntity(propEntity)
        propEntity = nil
    end
    cb('ok')

    -- ESC en el panel de admin: si se abrió desde la pestaña Scripts del
    -- admin, se vuelve a ella. origen_admin solo vuelve si este panel salió
    -- de su lista; el menú de los jugadores cierra y nada más.
    if panelAdminAbierto then
        panelAdminAbierto = false
        if GetResourceState('origen_admin') == 'started' then
            SetTimeout(80, function()
                pcall(function() exports['origen_admin']:ReturnToScripts() end)
            end)
        end
    end
end)

RegisterNuiCallback('start_storm', function(data, cb)
    local response = lib.callback.await('origen_gangwars:server:startStorm', false, data.data)
    cb(response)
end)

RegisterNuiCallback('get_coords', function(data, cb)
    cb(json.encode(GetEntityCoords(PlayerPed)))
end)

RegisterNuiCallback('save_lobby', function(data, cb)
    local response = lib.callback.await('origen_gangwars:server:saveLobby', false, data.data)
    cb(response)
end)

RegisterNuiCallback('send_message', function(data, cb)
    local stormID = Storms.id
    if not stormID then return debugger('send_message: Storm not found') end
    TriggerServerEvent('origen_gangwars:server:sendMessage', stormID, data.message)
    cb('ok')
end)

RegisterNetEvent('origen_gangwars:client:addChat', function(data)
    SendNUIMessage({
        action = 'addChatMessage',
        data = data
    })
end)

local team = nil

RegisterNetEvent('origen_gangwars:client:inviteResquest', function(team)
    --todo Sistema de aceptacion de invitacion
    
    team = data.team
end)

RegisterNuiCallback('join_storm', function(data, cb)
    local id = tonumber(data.id)
    if not id then return debugger('joinStorm: Storm not found') end
    local response = lib.callback.await('origen_gangwars:server:joinStorm', false, id, data.password, team)
    if not response then 
        cb(nil)
        return
    end
    
    debugger('joinStorm response: ' .. json.encode(response))
    
    local _data = {
        id = id,
        stats = response.stats or {},
        weather = response.weather or 'N/A',
        time = response.time or 'N/A',
        weapon = response.weapon or 'N/A',
        gameMode = response.gameMode or 'N/A',
        mapName = response.mapName or 'N/A',
        image = response.image or 'N/A',
        playerKits = response.playerKits or {},
        reward = response.reward or {},
        radius = response.radius or 400,
        startedIn = response.startedIn or 300,
        playerList = response.playerList or {},
    }
    
    debugger('joinStorm _data: ' .. json.encode(_data))
    cb(_data)
end)

RegisterNuiCallback('toggleReady', function(data, cb)
    local ready = data.ready
    TriggerServerEvent('origen_gangwars:server:toggleReady', ready)
    cb('ok')
end)

RegisterNuiCallback('send_chat_message', function(data, cb)
    local stormId = tonumber(data.stormId)
    local message = data.message
    if not stormId or not message or message == '' then 
        cb({ success = false })
        return 
    end
    TriggerServerEvent('origen_gangwars:server:sendMessage', stormId, message)
    cb({ success = true })
end)

RegisterNuiCallback('leave_lobby', function(data, cb)
    local stormId = tonumber(data.stormId)
    if not stormId then 
        cb({ success = false })
        return 
    end
    
    debugger('[leave_lobby] Leaving storm: ' .. stormId)
    local success = lib.callback.await('origen_gangwars:server:leaveStorm', false, stormId)
    
    if success then
        debugger('[leave_lobby] Successfully left storm')
        cb({ success = true })
    else
        debugger('[leave_lobby] Failed to leave storm')
        cb({ success = false })
    end
end)

RegisterNuiCallback('delete_lobby', function(data, cb)
    local dbid = tonumber(data.dbid)
    if not dbid then 
        cb({ success = false })
        return 
    end
    
    debugger('[delete_lobby] Deleting lobby: ' .. dbid)
    local success = lib.callback.await('origen_gangwars:server:deleteLobby', false, dbid)
    
    if success then
        debugger('[delete_lobby] Successfully deleted lobby')
        cb({ success = true })
    else
        debugger('[delete_lobby] Failed to delete lobby')
        cb({ success = false })
    end
end)

RegisterNuiCallback('get_stats', function(data, cb)

    local response = lib.callback.await('origen_gangwars:server:getProfileData', false)
    cb(response)

end)

RegisterNuiCallback('save_profile_data', function(data, cb)
    local response = lib.callback.await('origen_gangwars:server:saveProfileData', false, data)
    cb(response)
end)

RegisterNuiCallback('save_alias', function(data, cb)
    local response = lib.callback.await('origen_gangwars:server:saveAlias', false, data.alias)
    cb(response)
end)

RegisterNuiCallback('claim_reward', function(data, cb)
    local response = lib.callback.await('origen_gangwars:server:claimReward', false, data)
    cb(response)
end)

RegisterNuiCallback('get_global_ranking', function(data, cb)
    local gangList = GlobalState.gangList or {}
    local topTreeGangs = GlobalState.topTreeGangs or {}

    local generateGangStats = false

    if not gangList or not next(gangList) then
        generateGangStats = true
    end

    local response = lib.callback.await('origen_gangwars:server:getAllStatsRanking', generateGangStats)
    cb({
        globalStats = response,
        gangList = GlobalState.gangList,
        topTreeGangs = GlobalState.topTreeGangs
    })
end)

RegisterNuiCallback('add_friend', function(data, cb)
    local response = lib.callback.await('origen_gangwars:server:addFriend', false, data.identifier)
    cb(response)
end)

RegisterNuiCallback('remove_friend', function(data, cb)
    local response = lib.callback.await('origen_gangwars:server:removeFriend', false, data.identifier)
    cb(response)
end)

RegisterNuiCallback('buy_battlepass', function(data, cb)
    local response = lib.callback.await('origen_gangwars:server:BuyBattlepass', false, data.code)
    cb(response)
end)

RegisterNuiCallback('invite_friend', function(data, cb)
    local response = lib.callback.await('origen_gangwars:server:inviteFriend', false, data.identifier)
    cb(response)
end)

RegisterNetEvent('origen_gangwars:client:notify', function(text, type, length)
    Internal.Notify(text, type, length)
end)

RegisterNetEvent('copyClipboard', function(value)
    lib.setClipboard(value)
end)

local joinTeamResponse = nil

local function requestJoinTeam(name)
    local response = nil
    local time = 100

    SendNUIMessage({
        action = 'RequestJoinTeam',
        name = name,
    })

    while response == nil and time > 0 do
        Wait(100)
        time = time - 1
        response = joinTeamResponse
    end

    return response
end

RegisterNuiCallback('requestJoinTeam', function(data, cb)
    joinTeamResponse = data.request
end)

lib.callback.register('origen_gangwars:client:invite_friend', function(team, name)

    -- if LocalPlayer.state.orgInWar then
    --     return {status = false, reason = 'already_in_war'}
    -- end

    -- if LocalPlayer.state.gangwars_team or next(LocalPlayer.state.gangwars_team) then
    --     return {status = false, reason = 'already_in_team'}
    -- end

    local response = requestJoinTeam(name)

    if response then
        SendNUIMessage({
            action = 'joinServerStorm',
        })
    end

    joinTeamResponse = nil

    debugger('Invite friend response', response)
    return {status = response}
end)

