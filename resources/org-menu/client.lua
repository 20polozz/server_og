local headerShown = false
local sendData = nil
local thread = false
local ToDisable = { 14, 15, 16, 17, 18, 24, 25, 27, 50, 68, 69, 70, 91, 92, 96, 97, 99, 106, 114, 115, 122, 135, 142, 144, 176, 177, 180, 181, 198, 222, 223, 229, 237, 238, 241, 242, 257, 261, 262, 329, 330, 331, 334, 335, 336, 346, 348, 347 }

-- Functions
local function openMenu(data)
    if not data or not next(data) then return end
	-- for _,v in pairs(data) do
	-- 	if v["icon"] then
    --         local Items = exports['qb-core']:GetShared('Items')
	-- 		local img = "qb-inventory/html/"
	-- 		if Items[tostring(v["icon"])] then
	-- 			if not string.find(Items[tostring(v["icon"])].image, "images/") then
	-- 				img = img .. "images/"
	-- 			end
	-- 			v["icon"] = img .. Items[tostring(v["icon"])].image
	-- 		end
	-- 	end
	-- end
    SetNuiFocus(true, false)
    if not data[1] or not data[1].isMenuHeader or not data[1].nokeepinput then
        SetNuiFocusKeepInput(true)
    end
    headerShown = false
    sendData = data
    SendNUIMessage({
        action = 'openMenu',
        data = table.clone(data)
    })
    if not thread then
        thread = true
        Citizen.CreateThread(function()
            while thread do
                Citizen.Wait(0)
                for i = 1, #ToDisable do
                    DisableControlAction(0, ToDisable[i], true)
                end
            end
        end)
        Citizen.CreateThread(function()
            while sendData do
                Citizen.Wait(1200)
            end
            thread = false
        end)
    end
end

local function clearMenuData()
    sendData = nil
    headerShown = false
    SetNuiFocus(false)
    SetNuiFocusKeepInput(false)
end

local function closeMenu()
    clearMenuData()
    SendNUIMessage({
        action = 'closeMenu'
    })
end

local function showHeader(data)
    if not data or not next(data) then return end
    headerShown = true
    sendData = data
    SendNUIMessage({
        action = 'openMenu',
        data = table.clone(data)
    })
end

local function UpdateOption(option, key, value)
    if sendData then
        sendData[option][key] = value
    end
    SendNUIMessage({
        action = 'updateMenu',
        option = option,
        key = key,
        value = value
    })
end

local function HideMenu()
    SendNUIMessage({
        action = 'hideMenu'
    })
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false)
end

local function ShowMenu()
    SendNUIMessage({
        action = 'showMenu'
    })
    -- El foco primero: el vigilante (origen_map/shared/foco.lua) apaga el
    -- KeepInput al coger el foco y no deja encenderlo sin foco.
    SetNuiFocus(true, false)
    if not sendData[1] or not sendData[1].isMenuHeader or not sendData[1].nokeepinput then
        SetNuiFocusKeepInput(true)
    end
end

-- Events

RegisterNetEvent('org-menu:client:openMenu', function(data)
    openMenu(data)
end)

RegisterNetEvent('org-menu:client:closeMenu', function()
    closeMenu()
end)

RegisterNetEvent('qb-menu:client:openMenu', function(data)
    openMenu(data)
end)

RegisterNetEvent('qb-menu:client:closeMenu', function()
    closeMenu()
end)

-- NUI Callbacks

RegisterNUICallback('clickedButton', function(option, cb)
    if sendData then
        local data = sendData[tonumber(option)]
        if data and data.params then
            if not data.noclose and (not data.params or not data.params.submenu) then
                closeMenu()
            end

            if data.params.isServer then
                TriggerServerEvent(data.params.event, data.params.args)
            elseif data.params.isCommand then
                ExecuteCommand(data.params.event)
            elseif data.params.isQBCommand then
                TriggerServerEvent('QBCore:CallCommand', data.params.event, data.params.args)
            elseif data.params.handler then
                data.params.handler(data.params.args)  
            elseif data.params.submenu then
                openMenu(data.params.submenu)
            elseif data.params.isAction then
                data.params.event()
            else
                TriggerEvent(data.params.event, data.params.args)
            end
        else
            if not data or not data.noclose then
                closeMenu()
            end
        end
    else
        closeMenu()
    end
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(_, cb)
    clearMenuData()
    cb('ok')
    TriggerEvent("org-menu:client:menuClosed")
end)

-- Command and Keymapping

RegisterCommand('playerfocus', function()
    if headerShown then
        SetNuiFocus(true, false)
        SetNuiFocusKeepInput(true)
    end
end)

RegisterKeyMapping('playerFocus', 'Menú: pasar el ratón al menú', 'keyboard', 'LMENU')

-- Parado con el menu abierto: KeepInput es global del cliente y se quedaba
-- encendido. Las teclas antes que el foco (ORDEN_AL_SOLTAR en foco.lua).
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not OrigenFoco.Tiene() then return end
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
end)

-- Exports

exports('openMenu', openMenu)
exports('closeMenu', closeMenu)
exports('showHeader', showHeader)
exports('UpdateOption', UpdateOption)
exports('HideMenu', HideMenu)
exports('ShowMenu', ShowMenu)
