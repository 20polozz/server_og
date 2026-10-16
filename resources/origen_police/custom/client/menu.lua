function ShowHelpNotification(key, msg)
    -- ORIGEN: con un solo texto al estilo de GTA (~INPUT_...~), la barra de
    -- teclas del servidor; antes se perdia por el DrawText de qb-core.
    if msg == nil and type(key) == 'string' and GetResourceState('origen_hud') == 'started' then
        return exports.origen_hud:Ayuda(key)
    end
    -- Put your code here if you want to use a custom notification
    if Config.Framework == "qbcore" then
        exports['qb-core']:DrawText(msg, nil, key)
    elseif Config.Framework == "esx" then
        Framework.ShowHelpNotification(msg, key)
    end
end

function ShowNotification(msg, type)
    if not Config.CustomNotify then
        if Config.Framework == "qbcore" then
            Framework.Functions.Notify(msg, type or "primary")
        elseif Config.Framework == "esx" then
            Framework.ShowNotification(msg, type)
        end
        return
    end
    -- Put your code here if you want to use a custom notification
end

function HideHelpNotification()
    if Config.Framework == "qbcore" then
        exports["qb-core"]:HideText()
        return
    end
    -- Write your code here if you want to use a custom notification and delete the code above
end

function OpenMenu(...)
    if GetResourceState('org-menu') == 'started' then
        local menuType = select(1, ...)
        if menuType == 'dialog' then
            local title = select(4, ...).title
            local onSubmit = select(5, ...)
            exports["org-menu"]:closeMenu()
            SetNuiFocus(false)
            SetNuiFocusKeepInput(false)
            CreateThread(function()
                Wait(100)
                SetNuiFocusKeepInput(false)
                local input = exports['org-input']:ShowInput({
                    header = title,
                    inputs = {
                        {
                            name = "value",
                            text = title or "Value",
                            type = "text",
                            isRequired = true
                        }
                    }
                })
                SetNuiFocusKeepInput(false)
                if input then
                    local data = {}
                    data.value = input.value or input[1] or input
                    onSubmit(data, {close = function() end})
                end
            end)
            return
        else
            exports["org-menu"]:openMenu(...)
            return
        end
    end

    if Config.OxLibMenu then
        if not lib then
            print("OxLib is not installed or not uncommented from the fxmanifest")
            return
        end
        local menuType = select(1, ...)
        if menuType == 'dialog' then
            local title = select(4, ...).title
            local onSubmit = select(5, ...)
            local input = lib.inputDialog(title, {'Value'})

            if not input then return end
            local close = function() end
            onSubmit({value = input[1]}, {close = close})
        else
            local menuID = math.random(1, 1000).."origen_police"
            local mainData = select(1, ...)
            local title = mainData[1].header
            local options = {}
            for _, v in pairs(mainData) do
                if v.isMenuHeader then goto continue end
                table.insert(options, {
                    title = v.header,
                    description = v.txt,
                    icon = v.icon,
                    onSelect = function()
                        if v.params.isAction then
                            v.params.event()
                        elseif v.params.event then
                            if v.params.isServer then
                                TriggerServerEvent(v.params.event, v.params.args)
                            else
                                TriggerEvent(v.params.event, v.params.args)
                            end
                        else
                            print("No event/action found for menu: ", v.header)
                        end
                    end
                })
                ::continue::
            end
            lib.registerContext({
                id = menuID,
                title = title,
                options = options
            })
            lib.showContext(menuID)
        end
        return
    end

    local menuType = select(1, ...)
    if Config.Framework == "qbcore" then
        if menuType == 'dialog' then
            local title = select(4, ...).title
            local onSubmit = select(5, ...)
            CreateThread(function()
                local input = exports['org-input']:ShowInput({
                    header = title,
                    inputs = {
                        {
                            name = "value",
                            text = title or "Value",
                            type = "text",
                            isRequired = true
                        }
                    }
                })
                if input then
                    local data = {}
                    data.value = input.value or input[1] or input
                    onSubmit(data, {close = function() end})
                else
                end
            end)
        else
            exports["org-menu"]:openMenu(...)
        end
    elseif Config.Framework == "esx" then
        if type(menuType) == "string" and menuType == 'dialog' then
            return Framework.UI.Menu.Open(...)
        end
        local menu = select(1, ...)
        local elements = {}
        local methods = {}
        for k, v in pairs(menu) do
            if k == 1 then goto continue end
            elements[#elements+1] = {
                label = v.header..(v.txt and ": " or "")..(v.txt or ""),
                value = v.header
            }
            if v.params.isAction then
                methods[v.header] = v.params.event
            else
                methods[v.header] = function()
                    if v.params.isServer then 
                        TriggerServerEvent(v.params.event, v.params.args)
                    else
                        TriggerEvent(v.params.event, v.params.args)
                    end
                end
            end
            ::continue::
        end
        Framework.UI.Menu.Open('default', GetCurrentResourceName(), string.gsub(string.lower(menu[1].header), "%s+", "").."_"..GetGameTimer(), {
            title    = menu[1].header or "Unknown Menu",
            align    = 'bottom-right',
            elements = elements
        }, function(data, menu)
            menu.close()
            Wait(100)
            methods[data.current.value]()
        end, function(_, menu)
            menu.close()
        end)
    else
        ShowNotification("The menu system isn't compatible with your framework")
    end
end

function ProgressBar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    if Config.Framework == "qbcore" then
        Framework.Functions.Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    elseif Config.Framework == "esx" then
        if GetResourceState("esx_progressbar") ~= "missing" then
            if animation then
                RequestAnimDict(animation.animDict)
                while not HasAnimDictLoaded(animation.animDict) do
                    Wait(0)
                end
                TaskPlayAnim(PlayerPedId(), animation.animDict, animation.anim, 8.0, 8.0, -1, animation.flags, 0, 0, 0, 0)
            end
            local a = GetGameTimer()
            Framework.Progressbar(label, duration, { -- This function is already async
                FreezePlayer = false
            })
            if animation then
                StopAnimTask(PlayerPedId(), animation.animDict, animation.anim, 1.0)
            end
            local time = GetGameTimer() - a
            if time < 2 then
                -- This means that the ProgressBar function is creating a thread
                Wait(duration)
            end
            if onFinish then
                onFinish()
            end
        else
            print("Your progressbar resource is missing, please install esx_progressbar or configure your own progressbarw, no support will be given for this")
            if onFinish then
                onFinish()
            end
        end
    end
end

function HideHUD()
    -- Code to hide the hud
end

function ShowHUD()
    -- Code to show the hud
end