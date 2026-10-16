-- Apagado hasta leer el ajuste: el interruptor de la NUI sale apagado si no hay nada guardado.
local radioWidgetEnabled = false
local currentFrequency = nil
local connectedUsers = 0
local talkingPlayers = {}

-- El ajuste guardado (Ajustes → «Aviso en pantalla»). Se leía solo con
-- Config.MetadataSystem == 'qb', que aquí es false: nunca se cargaba. Ahora
-- se mira en los metadatos del framework y se le dice a la NUI, que es quien
-- pinta el aviso (components/RadioAviso.vue).
local function LeerAjusteAviso()
    local metadata
    if Config.Framework == "qbcore" and QBCore then
        local pd = QBCore.Functions.GetPlayerData()
        metadata = pd and pd.metadata
    elseif Config.Framework == "esx" then
        local ok, pd = pcall(function() return exports['es_extended']:getSharedObject().GetPlayerData() end)
        metadata = ok and pd and pd.metadata
    end
    if metadata and metadata.radioWidget ~= nil then
        local v = metadata.radioWidget
        radioWidgetEnabled = (v == true or v == 1 or v == "1" or v == "true")
    end
end

-- Update widget visibility
local function UpdateWidgetVisibility()
    SendNUIMessage({
        action = 'updateRadioWidget',
        show = radioWidgetEnabled
    })
end

CreateThread(function()
    Wait(1000)
    LeerAjusteAviso()
    UpdateWidgetVisibility()
end)

RegisterNetEvent(Config.Framework == "qbcore" and "QBCore:Client:OnPlayerLoaded" or "esx:playerLoaded", function()
    Wait(1500)
    LeerAjusteAviso()
    UpdateWidgetVisibility()
end)

-- Update widget connection status
local function UpdateWidgetConnection(connected, frequency)
    currentFrequency = frequency
    SendNUIMessage({
        action = 'updateRadioWidget',
        connected = connected,
        frequency = frequency or ''
    })
end

-- Update connected users count
local function UpdateConnectedUsers(count)
    connectedUsers = count
    SendNUIMessage({
        action = 'updateRadioWidget',
        users = count
    })
end

-- Update talking player
local function UpdateTalkingPlayer(playerId, isTalking, playerName)
    if isTalking then
        talkingPlayers[playerId] = playerName
    else
        talkingPlayers[playerId] = nil
    end
    
    -- Find first talking player
    local talking = false
    local name = nil
    for id, pName in pairs(talkingPlayers) do
        talking = true
        name = pName
        break
    end
    
    SendNUIMessage({
        action = 'updateRadioWidget',
        talking = talking,
        playerName = name
    })
end

-- Listen for radio connection events
RegisterNetEvent('origen_radio:client:radioConnected', function(frequency)
    if not radioWidgetEnabled then return end
    UpdateWidgetConnection(true, frequency)
end)

RegisterNetEvent('origen_radio:client:radioDisconnected', function()
    UpdateWidgetConnection(false)
    SendNUIMessage({
        action = 'resetRadioWidget'
    })
    talkingPlayers = {}
end)

-- Listen for user count updates
RegisterNetEvent('origen_radio:client:updateUserCount', function(count)
    if not radioWidgetEnabled then return end
    UpdateConnectedUsers(count)
end)

-- Listen for local player talking (when YOU talk)
RegisterNetEvent('origen_radio:client:localPlayerTalking', function(isTalking)
    if not radioWidgetEnabled then return end
    if not currentFrequency then return end
    
    local playerName = GetPlayerName(PlayerId())
    
    -- Get player's character name if using framework
    if Config.Framework == "qbcore" then
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.charinfo then
            playerName = PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname
        end
    elseif Config.Framework == "esx" then
        local PlayerData = ESX.GetPlayerData()
        if PlayerData and PlayerData.firstName then
            playerName = PlayerData.firstName .. " " .. PlayerData.lastName
        end
    end
    
    UpdateTalkingPlayer(PlayerId(), isTalking, playerName)
end)

-- Listen for other players talking (you'll need to trigger this from pma-voice integration)
RegisterNetEvent('origen_radio:client:playerTalking', function(playerId, isTalking, playerName)
    if not radioWidgetEnabled then return end
    UpdateTalkingPlayer(playerId, isTalking, playerName)
end)

-- Toggle widget visibility
RegisterNetEvent('origen_radio:client:toggleWidget', function(enabled)
    radioWidgetEnabled = enabled
    UpdateWidgetVisibility()
    
    if not enabled then
        SendNUIMessage({
            action = 'resetRadioWidget'
        })
    elseif currentFrequency then
        UpdateWidgetConnection(true, currentFrequency)
        UpdateConnectedUsers(connectedUsers)
    end
end)

-- Export for other scripts
exports('IsWidgetEnabled', function()
    return radioWidgetEnabled
end)

exports('UpdateWidgetFrequency', function(frequency)
    currentFrequency = frequency
    UpdateWidgetConnection(true, frequency)
end)

exports('UpdateWidgetUsers', function(count)
    UpdateConnectedUsers(count)
end)

