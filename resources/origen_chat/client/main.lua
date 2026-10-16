local chatInputActive = false
local chatInputActivating = false
local racingModeActive = false

-- Ocultar/mostrar el chat durante una carrera activa
local function PonerModoCarrera(isRacing)
    isRacing = isRacing == true
    racingModeActive = isRacing
    SendNUIMessage({ type = 'racingMode', active = isRacing })

    -- La NUI esconde la barra al empezar la carrera sin mandar chatResult, asi
    -- que el foco que cogio la T se quedaba puesto y chatInputActive en true:
    -- raton preso y un chat que ya no se volvia a abrir. Se recoge aqui.
    if isRacing and chatInputActive then
        chatInputActive = false
        chatInputActivating = false
        SetNuiFocus(false, false)
    end
end

AddEventHandler('origen_chat:setRacingMode', PonerModoCarrera)

--[[ El que de verdad dice si se esta corriendo: origen_racing lo avisa al
     empezar y al acabar la carrera por cualquier camino (meta, abandono,
     cancelacion...), y deja `enCarrera` en el estado del jugador. Antes nadie
     encendia el modo carrera del chat: los mensajes (los /me de alrededor)
     tapaban el HUD de la carrera. Con el chat reiniciado a mitad de carrera,
     se mira el estado al arrancar. ]]
AddEventHandler('origen_racing:enCarrera', PonerModoCarrera)
CreateThread(function()
    Wait(1000)
    if LocalPlayer.state.enCarrera == true then PonerModoCarrera(true) end
end)

--[[ Si el vigilante de foco.lua suelta el raton a la fuerza (pantalla vacia,
     colgada o el comando `raton`), chatInputActive se quedaba en true: el
     while de la T seguia dando vueltas y la T ya no reabria el chat. Se
     recoge el estado y se cierra la caja en la NUI, sin coger foco. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        chatInputActive = false
        chatInputActivating = false
        SendNUIMessage({ type = 'closeChat' })
    end)
end

local function exportHandler(exportName, func)
    AddEventHandler(('__cfx_export_chat_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end 

RegisterNetEvent('chatMessage')
RegisterNetEvent('chat:addMessage')
RegisterNetEvent('chat:addSuggestion')
RegisterNetEvent('chat:addSuggestions')
RegisterNetEvent('chat:removeSuggestion')
RegisterNetEvent('chat:clear')

-- internal events
RegisterNetEvent('__cfx_internal:serverPrint')

RegisterNetEvent('_chat:messageEntered')

--deprecated, use chat:addMessage
AddEventHandler('chatMessage', function(author, color, text)
    local args = { text }
    if author ~= "" then
        table.insert(args, 1, author)
    end

    SendNUIMessage({
        type = 'onMessage',
        message = {
            color = color,
            multiline = true,
            args = args
        }
    })
end)

if Config.Debug then
    AddEventHandler('__cfx_internal:serverPrint', function(msg)  
        SendNUIMessage({
            type = 'onMessage',
            message = {
                templateId = 'print',
                multiline = true,
                args = { msg },
            }
        })
    end)
end


-- addMessage
local addMessage = function(message)
    if type(message) == 'string' then
        message = {
            args = { message }
        }
    end

    SendNUIMessage({
        type = 'onMessage',
        message = message
    })
end

exports('addMessage', addMessage)
exportHandler('addMessage', addMessage)
AddEventHandler('chat:addMessage', addMessage)

-- addSuggestion
local addSuggestion = function(name, help, params)
    SendNUIMessage({
        type = 'onSuggestionAdd',
        suggestion = {
            name = name,
            help = help,
            params = params or nil
        }
    })
end

exports('addSuggestion', addSuggestion)
exportHandler('addSuggestion', addSuggestion)
AddEventHandler('chat:addSuggestion', addSuggestion)

local function hasBlacklistedPrefix(commandName)
    for prefix in pairs(Config.BlacklistedPrefixes) do
        if string.find(commandName, '/'..prefix, 1, true) then
            return true
        end
    end
    return false
end

AddEventHandler('chat:addSuggestions', function(suggestions)
    for _, suggestion in ipairs(suggestions) do
        if hasBlacklistedPrefix(suggestion.name) then
            goto continue
        end

        SendNUIMessage({
            type = 'onSuggestionAdd',
            suggestion = suggestion
        })

        ::continue::
    end
end)

local function removeSuggestion(name)
    if not name then return end
    SendNUIMessage({
        type = 'onSuggestionRemove',
        name = name
    })
    if not string.find(name, '^/') then
        SendNUIMessage({
            type = 'onSuggestionRemove',
            name = '/' .. name
        })
    end
end

exportHandler('removeSuggestion', removeSuggestion)
exports('removeSuggestion', removeSuggestion)
AddEventHandler('chat:removeSuggestion', removeSuggestion)

local function clearChat()
    SendNUIMessage({
        type = 'onClear'
    })
end

exportHandler('clearChat', clearChat)
exports('clearChat', clearChat)
AddEventHandler('chat:clear', clearChat)

local function isPlayerDead()
    if LocalPlayer and LocalPlayer.state and (LocalPlayer.state.dead or LocalPlayer.state.isDead) then
        return true
    end
    if GetResourceState('origen_ambulancejob') == 'started' then
        local ok, dead = pcall(function() return exports['origen_ambulancejob']:isDead() end)
        if ok and dead then return true end
    end
    if GetResourceState('qbx_medical') == 'started' then
        local ok, dead = pcall(function() return exports['qbx_medical']:isDead() end)
        if ok and dead then return true end
    end
    local ped = PlayerPedId()
    if IsPedDeadOrDying(ped, true) or IsEntityDead(ped) then
        return true
    end
    return false
end

RegisterNUICallback('chatResult', function(data, cb)
    chatInputActive = false

    --[[ Se suelta siempre, este muerto o no. Aqui habia una rama que, muerto,
         volvia a coger el foco con KeepInput: justo cuando la NUI ya habia
         escondido la barra, asi que el raton se quedaba en el chat sin nada que
         escuchar, y la T ya no lo reabria. La pantalla de muerto
         (origen_ambulancejob) lleva su propio foco y no necesita el nuestro.
         El KeepInput que encendiera este recurso lo apaga foco.lua al soltar;
         apagarlo aqui a mano tocaria el interruptor global, que puede ser de
         la pantalla de muerto. ]]
    SetNuiFocus(false, false)

    if not data.canceled then
        local id = PlayerId()

        --deprecated
        local r, g, b = 0, 0x99, 255

        if data.message:sub(1, 1) == '/' then
            -- Notificar al servidor el texto completo ANTES de ejecutar
            -- para que pueda loguearlo si quien escribe es staff
            TriggerServerEvent('origen_chat:server:staffRawInput', data.message)
            ExecuteCommand(data.message:sub(2))
        else
            -- Notificar también mensajes normales
            TriggerServerEvent('origen_chat:server:staffRawInput', data.message)
            Custom.OnSendNoCommandMessage(id, data.message)
        end
    end

    cb('ok')
end)

local function refreshCommands()
    if GetRegisteredCommands then
        local registeredCommands = GetRegisteredCommands()

        local suggestions = {}

        for _, command in ipairs(registeredCommands) do
            if IsAceAllowed(('command.%s'):format(command.name)) 
                and command.name ~= Config.CommandName 
                and not (Config.BlacklistedCommands and Config.BlacklistedCommands[command.name])
                and not hasBlacklistedPrefix(command.name) then
                table.insert(suggestions, {
                    name = '/' .. command.name,
                    help = ''
                })
            end
        end

        TriggerEvent('chat:addSuggestions', suggestions)
    end
end

AddEventHandler('onClientResourceStart', function(resName)
    Wait(500)

    refreshCommands()
end)

AddEventHandler('onClientResourceStop', function(resName)
    Wait(500)

    refreshCommands()
end)

local function registerKeybind()

    while not Translations or not next(Translations) do Wait(100) end

    RegisterCommand(Config.CommandName, function(source, args)
        if IsNuiFocused() and not isPlayerDead() then return end
        if IsPauseMenuActive() then return end

        if not Custom.CanOpenChat() then return end
        -- En carrera la ventana no sale sola (tapaba el HUD), pero la T si la
        -- abre: el que se estrella tiene que poder rolear con los EMS.

        if not chatInputActive then
            chatInputActive = true
            chatInputActivating = true

            SendNUIMessage({
                type = 'openChat'
            })

            while true do
                if chatInputActivating then
                    if not IsControlPressed(0, 245) then
                        SetNuiFocus(true, true)
                        SetNuiFocusKeepInput(false)
                        chatInputActivating = false
                    end
                end

                if not chatInputActive then break end
                
                Wait(0)
            end
        end
    end, false)

    RegisterKeyMapping(Config.CommandName, locale('commands.chat.description'), 'keyboard', 'T')

    SetTimeout(500, function()
        TriggerEvent('chat:removeSuggestion', '/'..Config.CommandName)
    end)
end

RegisterNUICallback('loaded', function(data, cb)
    refreshCommands()
    
    cb('ok')
end)

CreateThread(function()
    SetTextChatEnabled(false)
    SetNuiFocus(false, false)

    registerKeybind()
end)

RegisterNUICallback('getTranslations', function(data, cb)
    while not Translations or not next(Translations) do Wait(100) end

    cb(Translations)
end)

RegisterNUICallback('getConfig', function(data, cb)
    while not Config do Wait(1000) end
    cb({
        allowEdit = Config.AllowEdit,
        defaultColor = Config.DefaultColor,
        showEmojisOption = Config.ShowEmojisOption
    })
end)

if Config.ShowServerPrints then
    AddEventHandler('__cfx_internal:serverPrint', function(msg)
        print(msg)
    end)
end