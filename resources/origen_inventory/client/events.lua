RegisterNetEvent('orgInv:setEntityToRouting', function(netId, bucket)
    local source = source
    local ent = NetworkGetEntityFromNetworkId(netId)
    local playerBucket = GetPlayerRoutingBucket(source)
    SetEntityRoutingBucket(ent, bucket or playerBucket)
end)

RegisterNetEvent('origen_inventory:client:OnItemAdded', function(itemName, amount, slot)
    if InventoryClientMethods[itemName] and InventoryClientMethods[itemName].add then
        InventoryClientMethods[itemName].add(amount, slot)
    end
end)

RegisterNetEvent('origen_inventory:client:OnItemRemoved', function(itemName, amount, slot)
    if InventoryClientMethods[itemName] and InventoryClientMethods[itemName].remove then
        InventoryClientMethods[itemName].remove(amount, slot)
    end
    
    if Internal__GetCurrentWeapon then
        local currentWeapon, currentSerial, currentData = Internal__GetCurrentWeapon()
        if currentWeapon and currentWeapon:lower() == itemName:lower() then
            if currentData and currentData.slot == slot then
                exports['origen_inventory']:unarmedPed()
            end
        end
    end
end)

RegisterNetEvent('inventory:client:openAdmin', function(...)
    InventoryUI.OpenManagement()
end)

RegisterNetEvent('origen_inventory:client:UpdateInventory', function(other, clearInventory)
    UpdateInventory(other, clearInventory)
end)


RegisterNetEvent('origen_inventory:client:CloseInventory', function(isServer, isNui, remote)
    Player:CloseInventory(isServer, isNui, remote)
end)

RegisterNetEvent('inventory:client:useItem', function(item)
    Inventory.useItem(item)
end)

RegisterNetEvent('origen_inventory:client:openHangerMenu', function(slot, item)
    if not slot then return end

    local itemData = item or {}
    local metadata = itemData.metadata or {}
    local perchaName = metadata.perchaName or 'Percha de conjunto'
    local actions = InventoryButtons['percha'] or {}

    local menuOptions = {
        { header = perchaName, isMenuHeader = true },
    }

    if actions['Abrir percha'] then
        menuOptions[#menuOptions + 1] = {
            header = 'Abrir percha',
            txt = 'Ver y gestionar prendas guardadas.',
            icon = 'fa-solid fa-shirt',
            params = {
                handler = function()
                    actions['Abrir percha'](slot, metadata)
                end
            }
        }
    end

    if actions['Equipar conjunto'] then
        menuOptions[#menuOptions + 1] = {
            header = 'Equipar conjunto',
            txt = 'Equipa lo que haya dentro de la percha.',
            icon = 'fa-solid fa-user-check',
            params = {
                handler = function()
                    actions['Equipar conjunto'](slot, metadata)
                end
            }
        }
    end

    if actions['Renombrar percha'] then
        menuOptions[#menuOptions + 1] = {
            header = 'Renombrar percha',
            txt = 'Cambia el nombre del conjunto.',
            icon = 'fa-solid fa-pen',
            params = {
                handler = function()
                    actions['Renombrar percha'](slot, metadata)
                end
            }
        }
    end

    exports['org-menu']:openMenu(menuOptions)
end)

RegisterNetEvent('inventory:client:ItemBox', function(itemData, type)
    InventoryUI.Notify(type, itemData.name)
end)

RegisterNetEvent('qb-inventory:client:ItemBox', function(itemData, type)
    InventoryUI.Notify(type, itemData.name)
end)


Callbacks.register('origen_inventory:canUseItem', function(itemName)
    return Inventory.__Internal_CanUseItem(itemName)
end)
-- RegisterNUICallback("PlayDropSound", function(data, cb)
--     PlaySound(-1, "CLICK_BACK", "WEB_NAVIGATION_SOUNDS_PHONE", 0, 0, 1)
--     cb(true)
-- end)

-- RegisterNUICallback("PlayDropFail", function(data, cb)
--     PlaySound(-1, "Place_Prop_Fail", "DLC_Dmod_Prop_Editor_Sounds", 0, 0, 1)
--     cb(true)
-- end)



--- on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        -- Con el inventario o la gestion abiertos, el raton se quedaria
        -- puesto sin nadie detras.
        SetNuiFocus(false, false)
        clearCache()
    end
end)

local function UnloadPlayer()
    -- Con el panel delante, Player = nil lo dejaba pintado y con el raton
    -- puesto: ya no habia a quien pedirle que se cerrase. Se cierra antes.
    if Player and Player.isOpen then
        Player:CloseInventory(false, false)
    end
    CharacterUnloaded = true
    Player = nil
    ResetClothesToDefault()
    TriggerServerEvent('origen_inventory::PlayerUnload')
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', UnloadPlayer)
RegisterNetEvent('esx:onPlayerLogout', UnloadPlayer)

RegisterNetEvent('esx:playerLoaded', function()
    CharacterUnloaded = false
    TriggerServerEvent('origen_inventory::PlayerLoaded')
end)

------------------------------------
--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--- Personal Menu (Recording & Editor)
--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
------------------------------------

eventPublisher:subscribe('origen_inventory:personal:toggleWeapon', function()
    TriggerEvent('origen_police:holster:unarm')
end)

eventPublisher:subscribe('origen_inventory:personal:editor', function(id)
	InventoryUI.Close()
    local elements = {
        {header = locale:t('notify.CivilMenu'), isMenuHeader = true},
        {header = locale:t('notify.Record'),        txt = locale:t('notify.RecordDesc'),    icon = "fas fa-video",action = 'origen_inventory:record', value = 'start'},
        {header = locale:t('notify.Save'),          txt = locale:t('notify.SaveDesc'), 	    icon = "fas fa-save", action = 'origen_inventory:record', value = 'save'},
        {header = locale:t('notify.Cancel'),        txt = locale:t('notify.CancelDesc'), 	icon = "fas fa-save", action = 'origen_inventory:record', value = 'cancel'},
        {header = locale:t('notify.EditorMode'),    txt = locale:t('notify.EditorModeDesc'),icon = "fas fa-edit", action = 'origen_inventory:record', value = 'editor'},
    }
    Bridge.OpenMenu(elements)
end)

RegisterNetEvent("origen_inventory:record", function(name)
	if(name == "start") then 
		StartRecording(1)
	elseif(name == "save") then
		StopRecordingAndSaveClip()
	elseif(name == "cancel") then
		StopRecordingAndDiscardClip()
	elseif(name == "editor") then
		ActivateRockstarEditor()
	end
end)