--------------------------------
--------------------------------
--- INVENTORY ITEMS MODULE ---
--- ----------------------------
---
InventoryItems = {}
InventoryButtons = {}
InventoryClientMethods = {}
InventoryWeapons = {}

-------------------------------
----------------------------------

local alternativeItems = {}
local isServer = IsDuplicityVersion()

local loadFile = function(filename)
    local fileContent = LoadResourceFile(GetCurrentResourceName(), filename)

    if not fileContent then
        debugger('^1ERROR: [org_inventory]^3 Could not find ' .. filename .. '^0')
        return false
    end

    local func, err = load(fileContent, filename, 't', _ENV)
    if not func then
        debugger('^1ERROR: [org_inventory]^3 Could not load ' .. filename .. '^0', err)
        return false
    end

    return func()
end

local setupItemButtons = function(item, buttons)
    local newButtons = {}
    for i, btn in pairs(buttons) do
        if btn.label and btn.action and type(btn.action) == 'function' then
            table.insert(newButtons, {
                label = btn.label,
                index = i,
            })

            if not IsDuplicityVersion() then
                InventoryButtons[item] = InventoryButtons[item] or {}
                InventoryButtons[item][btn.label] = btn.action
            end
        end
    end

    return newButtons
end

local setupItemAddRemoveMethods = function(item, client)
    if not client then return end

    if isServer then
        client.add = nil
        client.remove = nil
        return client
    end

    InventoryClientMethods[item] = InventoryClientMethods[item] or {}

    if client.add and type(client.add) == 'function' then
        InventoryClientMethods[item].add = client.add
        client.add = nil
    end

    if client.remove and type(client.remove) == 'function' then
        InventoryClientMethods[item].remove = client.remove
        client.remove = nil
    end

    return client
end

local formatItemsToNew = function(items)
    local formattedItems = {}
    for itemKey, item in pairs(items) do
        if item.name and item.label then
            local isAttachmentItem = function()
                -- check if name has _attachment
                return item.name:find('_attachment') ~= nil
            end

            local removeAttachmentPrefix = function(name)
                return name:gsub('_attachment', '')
            end

            local isAttachmentItem = isAttachmentItem()
            if isAttachmentItem then
                item.type = 'attachment'
                item.attachment = removeAttachmentPrefix(item.name)
                -- item.name = removeAttachmentPrefix(item.name)
            end

            local isWeaponTint = function()
                return Config.WeaponTints[item.name] ~= nil
            end

            local isWeaponTint = isWeaponTint()
            if isWeaponTint then
                item.type = 'attachment'
                item.attachment = 'finish'
            end


            if item.client then
                item.client = setupItemAddRemoveMethods(item.name, item.client)
            end

            local buttons = setupItemButtons(item.name, item.buttons or item.client?.buttons or {})
            if item.client?.buttons then
                item.client.buttons = nil
            end

            local stack = item.stack
            if type(stack) == 'nil' then
                stack = true
            end

            if Config.Experimentals.giveItemAlgorithm == 'no_stack' then
                if item.name:match('weapon_') then
                    stack = false
                end
            end

            local metadata = item.metadata or {}
            if item.image then
                metadata.image = item.image
            end

            if not metadata.maxUses and item.uses then
                metadata.maxUses = item.uses or item.consume
            end

            item.metadata = metadata

            local keyToUse = item.name
            formattedItems[keyToUse] = {
                name = keyToUse,
                label = item.label,
                weight = item.weight or 0,
                type = item.type or 'item',
                description = item.description or '',
                attachment = item.attachment,
                stack = stack,
                close = item.shouldClose or item.close or true,
                client = item.client or nil,
                server = item.server or nil,
                buttons = buttons,
                decay = item.decay or item.degrade or false,
                perishable = item.perishable,
                uses = item.uses or item.consume or 0,
                ammotype = item.ammotype,
                weapontype = item.weapontype,
                damagereason = item.damagereason
            }
        end
    end
    return formattedItems
end

local setupQBItems = function()
    local QBCore = exports['qb-core']:GetCoreObject()
    local QbItems = QBCore.Shared.Items
    if not QbItems then
        return false
    end

    alternativeItems = formatItemsToNew(QbItems)
    return true
end

local setupOrigenItems = function()
    local inventoryItemsFile = loadFile('config/items.lua')
    if not inventoryItemsFile then
        debugger('^1ERROR: [org_inventory]^3 Could not find config/items.lua^0')
        return false
    end

    local newInventoryItems = {}

    for itemName, item in pairs(inventoryItemsFile) do
        local buttons = setupItemButtons(itemName, item.buttons or item.client?.buttons or {})
        local clientMethods = setupItemAddRemoveMethods(itemName, item.client)

        item.name = itemName:lower()

        if clientMethods then
            item.client = clientMethods
        end

        if item.client?.buttons then
            item.client.buttons = nil
        end

        if item.type == 'attachment' then
            local isWeaponTint = function()
                return Config.WeaponTints[item.name]
            end

            local isWeaponTint = isWeaponTint()
            if isWeaponTint then
                item.attachment = 'finish'
            end
        end

        item.buttons = buttons

        if item.degrade then
            item.decay = item.degrade
            item.degrade = nil
        end

        if not item.weight then
            item.weight = 0
        end

        local metadata = item.metadata or {}
        if item.image then
            metadata.image = item.image
        end

        if not metadata.maxUses and item.uses then
            metadata.maxUses = item.uses or item.consume
        end

        item.metadata = metadata

        if type(item.stack) == 'nil' then
            item.stack = true
        end

        InventoryItems[itemName:lower()] = item
    end

    return newInventoryItems
end

local setupOldItems = function()
    alternativeItems = formatItemsToNew(OrgItems)
    return true
end

local setupItems = function()
    local count = 0
    for itemName, itemData in pairs(alternativeItems) do
        if not InventoryItems[itemName] then
            InventoryItems[itemName] = itemData
            count = count + 1
        end
    end

end

setupOrigenItems()

if Config.Framework == 'qbcore' and not GlobalState.orgInventoryProvided and setupQBItems() or setupOldItems() then
    setupItems()
end


local setupWeapons = function()
    local weaponsFile = loadFile('config/weapons.lua')
    if not weaponsFile then return false end
    local weapons = weaponsFile.Weapons or weaponsFile.weapons
    if not weapons then return false end

    for weaponName, weaponData in pairs(weapons) do
        -- Normalize weapon name
        weaponName = weaponName:lower()

        local metadata = weaponData.metadata or {}
        if weaponData.image then
            metadata.image = weaponData.image
        end
        weaponData.metadata = metadata
        weaponData.model = weaponData.model or weaponName

        local wData = {
            name = weaponName,
            label = weaponData.label,
            description = weaponData.description,

            model = weaponData.model or weaponName,
            hash = GetHashKey(weaponData.model),

            weight = weaponData.weight or 0,
            stack = false,
            close = true,
            weapontype = weaponData.type,
            type = 'weapon',
            ammotype = weaponData.ammoname,
            decay = weaponData.durability,
            damagereason = weaponData.damagereason,

            weapon = true
        }

        local weaponHash = GetHashKey(weaponName)

        InventoryItems[wData.name] = wData
        InventoryWeapons[weaponHash] = wData

        -- Compatibility
        OrgWeapons[weaponHash] = wData

    end

    return true
end

local setupComponents = function()
    -- local weaponsFile = loadFile('config/weapons.lua')
    -- if not weaponsFile then return false end
    -- local components = weaponsFile.Components or weaponsFile.components
    -- if not components then return false end

    -- for componentName, componentData in pairs(components) do
    --     -- Normalize component name
    --     componentName = componentName:lower()

    --     local metadata = componentData.metadata or {}
    --     if componentData.image then
    --         metadata.image = componentData.image
    --     end
    --     componentData.metadata = metadata

    --     local cData = {
    --         name = componentName,
    --         label = componentData.label,
    --         description = componentData.description,
    --         weight = componentData.weight,
    --         stack = true,
    --         close = true,
    --         type = 'attachment',
    --     }

    --     InventoryItems[cData.name] = cData

    --     print(('[OrgItems] Loaded weapon component item: %s'):format(componentName))
    -- end

    -- return true
end

local setupAmmo = function()
    local weaponsFile = loadFile('config/weapons.lua')
    if not weaponsFile then return false end
    local ammos = weaponsFile.Ammo or weaponsFile.ammo
    if not ammos then return false end

    for ammoName, ammoData in pairs(ammos) do
        -- Normalize ammo name
        ammoName = ammoName:lower()

        local metadata = ammoData.metadata or {}
        if ammoData.image then
            metadata.image = ammoData.image
        end
        ammoData.metadata = metadata

        local aData = {
            name = ammoName,
            label = ammoData.label,
            description = ammoData.description or "",
            weight = ammoData.weight,
            stack = true,
            close = true,
            type = 'ammo',
        }

        InventoryItems[aData.name] = aData

    end

    return true
end

setupWeapons()
setupComponents()
setupAmmo()


function Items(itemName)
    if itemName then
        -- Try to find the item as-is first
        local item = InventoryItems[itemName]
        if item then return item end

        -- If not found, try lowercase
        local itemLower = itemName:lower()
        item = InventoryItems[itemLower]
        if item then return item end

        -- If still not found, try uppercase
        local itemUpper = itemName:upper()
        item = InventoryItems[itemUpper]
        if item then return item end

        return nil
    end
    return InventoryItems
end

function Weapons(weaponHash)
    if weaponHash then
        return InventoryWeapons[weaponHash]
    end
    return InventoryWeapons
end

local itemsToSync = {}

function CreateItem(itemName, itemData, syncToClient)
    if not itemName or not itemData then
        return false
    end

    itemData.name = itemName
    InventoryItems[itemName] = itemData

    local lowerName = itemName:lower()
    if lowerName ~= itemName then
        InventoryItems[lowerName] = itemData
    end

    if syncToClient and isServer then
        itemsToSync[itemName] = itemData
        if lowerName ~= itemName then
            itemsToSync[lowerName] = itemData
        end
        TriggerClientEvent("inventory:client:AddItemToDictionary", -1, itemName, itemData)
    end

    return true
end

--- Lo contrario de CreateItem: saca el item del diccionario y, en el servidor,
--- tambien de la lista de sincronizacion.
---
--- Sin esto ultimo un item borrado volvia: `itemsToSync` guarda todo lo que se
--- ha creado en caliente y se le manda entero a cada jugador que conecta, asi
--- que quien entrase despues del borrado lo recibia otra vez. Se quitan las dos
--- claves —la del nombre tal cual y la de su version en minusculas— porque
--- CreateItem escribe las dos.
function RemoveItemFromDictionary(itemName)
    if not itemName then return false end

    local lowerName = itemName:lower()
    InventoryItems[itemName] = nil
    InventoryItems[lowerName] = nil
    itemsToSync[itemName] = nil
    itemsToSync[lowerName] = nil

    return true
end

AddItemToDictionary = CreateItem
GetItems = Items

function DebugItems(itemName)
    if itemName then
        local item = Items(itemName)
        print("Debug item '" .. itemName .. "':", item and json.encode(item) or "NOT_FOUND")
        return item
    else
        local count = 0
        for _ in pairs(InventoryItems) do count = count + 1 end
        print("Total items in inventory:", count)
        return InventoryItems
    end
end

exports('Items', Items)
exportsOX('Items', Items)
exports('CreateItem', CreateItem)
exports('AddItemToDictionary', CreateItem)
exports('RemoveItemFromDictionary', RemoveItemFromDictionary)
exports('DebugItems', DebugItems)
exports('GetInventoryItem', Items)
exports("GetItemList", Items)
exports("GetItems", Items)
exports("getItems", Items)
exports('Weapons', Weapons)

if isServer then
    RegisterNetEvent('inventory:server:requestSyncItems', function()
        TriggerClientEvent("inventory:client:AddItemsToDictionary", source, itemsToSync)
    end)
else
    CreateThread(function()
        Wait(1000)
        TriggerServerEvent('inventory:server:requestSyncItems')
    end)

    --- El panel de administracion se sembraba una sola vez, al abrirlo, y a
    --- partir de ahi solo se apañaba con lo que apuntaba por su cuenta al crear
    --- o borrar. Si el servidor rechazaba el alta, o si la respuesta del
    --- callback se perdia por el camino, la lista se quedaba con un item que ya
    --- no existia: salia en la rejilla pero no habia forma de darselo a nadie.
    --- Ahora el diccionario avisa, y la NUI sigue al servidor en vez de
    --- adivinar.
    RegisterNetEvent('inventory:client:AddItemToDictionary', function(itemName, itemData)
        AddItemToDictionary(itemName, itemData)
        if InventoryUI and InventoryUI.Emit then
            InventoryUI.Emit({ action = 'itemUpserted', name = itemName, item = itemData }, false, true)
        end
    end)

    RegisterNetEvent('inventory:client:AddItemsToDictionary', function(items)
        local count = 0
        for _ in pairs(items) do count = count + 1 end
        for itemName, itemData in pairs(items) do
            AddItemToDictionary(itemName, itemData)
        end
    end)

    RegisterNetEvent('inventory:client:ForceItemsSync', function()
        TriggerServerEvent('inventory:server:requestSyncItems')
    end)
end