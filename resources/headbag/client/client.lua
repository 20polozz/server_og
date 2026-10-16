local hasBag = false
local bags = {}

RegisterNetEvent('wx_headbag:notify', function(title, desc)
    Notification(title, desc)
end)

function GetClosestPlayer()
    local closestPlayer = lib.getClosestPlayer(GetEntityCoords(PlayerPedId()), 2.0, false)
    if closestPlayer == nil or not closestPlayer then
        Notification(wx.Locale.NotifyTitle, wx.Locale.NotifyNoOneNearby)
    else
        if not hasBag then
            local targetId = GetPlayerServerId(closestPlayer)
            TriggerServerEvent('wx_headbag:putOnTarget', targetId)
            Notification(wx.Locale.NotifyTitle, wx.Locale.NotifyPutOn)
            hasBag = true
        else
            hasBag = false
            Notification(wx.Locale.NotifyTitle, wx.Locale.NotifyAlreadyOn)
        end
    end
end

RegisterNetEvent('wx_headbag:putOn')
AddEventHandler('wx_headbag:putOn', function()
    Headbag = CreateObject(GetHashKey("prop_money_bag_01"), 0, 0, 0, true, true, true)
    AttachEntityToEntity(Headbag, GetPlayerPed(-1), GetPedBoneIndex(GetPlayerPed(-1), 12844), 0.22, 0.04, 0, 0, 270.0, 60.0, true, true, false, true, 1, true)
    table.insert(bags, Headbag)
    SendNUIMessage({ type = 'bagOn' })
    SetNuiFocus(false, false)
    hasBag = true
end)

RegisterNetEvent('wx_headbag:takeOff')
AddEventHandler('wx_headbag:takeOff', function()
    Notification(wx.Locale.NotifyTitle, wx.Locale.NotifyTookOff)
    DeleteEntity(Headbag)
    SetEntityAsNoLongerNeeded(Headbag)
    SendNUIMessage({ type = 'bagOff' })
    hasBag = false
end)

local function bagmenu()
    local opciones = {
        {
            header = wx.Locale.ContextTitle,
            icon = "fa-solid fa-masks-theater",
            isMenuHeader = true,
        },
        {
            header = wx.Locale.ContextPutOn,
            txt = wx.Locale.ContextDescPutOn,
            icon = "fa-solid fa-mask",
            params = {
                isAction = true,
                event = function()
                    GetClosestPlayer()
                end
            }
        },
        {
            header = wx.Locale.ContextTakeOff,
            txt = wx.Locale.ContextDescTakeOff,
            icon = "fa-solid fa-masks-theater",
            params = {
                isAction = true,
                event = function()
                    local closestPlayer = lib.getClosestPlayer(GetEntityCoords(PlayerPedId()), 2.0, false)
                    if closestPlayer == nil or not closestPlayer then
                        Notification(wx.Locale.NotifyTitle, wx.Locale.NotifyNoOneNearby)
                    else
                        TriggerServerEvent('wx_headbag:takeOffTarget', GetPlayerServerId(closestPlayer))
                    end
                end
            }
        }
    }
    exports["org-menu"]:openMenu(opciones)
end

RegisterNetEvent('wx_headbag:openAdminMenu')
AddEventHandler('wx_headbag:openAdminMenu', function()
    bagmenu()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, bag in pairs(bags) do
            DeleteEntity(bag)
        end
    end
end)

if wx.removeHeadbagOnRespawn then
    AddEventHandler('playerSpawned', function()
        -- Que el servidor sepa que ya no la llevas (ver server.lua, conBolsa).
        if hasBag then TriggerServerEvent('wx_headbag:quitadaAlReaparecer') end
        DeleteEntity(Headbag)
        SetEntityAsNoLongerNeeded(Headbag)
        SendNUIMessage({ type = 'bagOff' })
        hasBag = false
    end)
end
