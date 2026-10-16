local isServer = IsDuplicityVersion()
local CItems = {}

local formatItemsClient = function(client)
    if not client then return nil end

    if client.status then
        for k, v in pairs(client.status) do
            if v == 0 then
                client.status[k] = 0
            end
        end
    end

    if client.anim and (client.anim.dict == "" or client.anim.clip == "") then
        client.anim = nil
    end

    if client.prop and (client.prop.model == "" or not client.prop.model) then
        client.prop = nil
    end

    if client.usetime and client.usetime <= 0 then
        client.usetime = nil
    end

    return client
end

-- nil must survive as nil: it means the item does not take part in decay.
local toPerishableColumn = function(value)
    if value == nil or value == '' or value == 'none' then return nil end
    if value == 'true' or value == 'perishable' then return 1 end
    if value == 'false' or value == 'nonperishable' then return 0 end
    if type(value) == 'boolean' then return value and 1 or 0 end
    return nil
end

-- MySQL returns TINYINT as a number, and 0 is truthy in Lua.
local fromPerishableColumn = function(value)
    if value == nil then return nil end
    return value == 1 or value == true
end

CItems.AddCustomItem = function(data)
    local nameIsEmpty = not data.name or data.name == ''
    data.name = nameIsEmpty and Helper.getItemName(data.label) or data.name

    -- Checking if item exist
    local existingItem = Items(data.name)
    if existingItem then
        debugger(("[OrgItems] Item '%s' already exists. (ignored)"):format(existingItem.name))
        return false
    end

    data.client = formatItemsClient(data.client)

    if type(data.stack) ~= 'nil' then
        data.stack = data.stack
    else
        data.stack = true
    end

    local newItem = {
        name = data.name,
        label = data.label or data.name,
        weight = data.weight or 0,
        rarity = data.rarity,
        image = data.image or nil,
        type = data.type,
        description = data.description or '',
        stack = data.stack,
        close = data.close or true,
        server = data.server or nil,
        client = data.client or nil,
        buttons = data.buttons or {},
        decay = data.decay or nil,
        perishable = fromPerishableColumn(toPerishableColumn(data.perishable)),
        uses = data.consume or data.uses,
        custom = true
    }

    MySQL.awaitQuery(
    'INSERT INTO origen_customitems (name, label, weight, rarity, `type`, image, description, stack, close, server, client, buttons, decay, perishable) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            newItem.name, newItem.label, newItem.weight, newItem.rarity, newItem.type, newItem.image, newItem
            .description, newItem.stack, newItem.close, json.encode(newItem.server), json.encode(newItem
        .client), json.encode(newItem.buttons), newItem.decay, toPerishableColumn(data.perishable)
        })

    AddItemToDictionary(newItem.name, newItem, true) -- syncToClient = true
    debugger(string.format("[OrgItems] Item '%s' added to the database and inventory.", newItem.name))
    return true
end

CItems.EditCustomItem = function(data)
    if isServer then
        if not data or not data.name then
            debugger("[OrgItems] Invalid data for EditItem.")
            return false, 'invalid_item_data'
        end

        if not InventoryItems[data.name] then
            debugger(string.format("[OrgItems] Item '%s' does not exist in the inventory.", data.name))
            return false, 'item_not_found'
        end

        local item = InventoryItems[data.name]
        -- Merge new data with existing data
        for k, v in pairs(data) do
            item[k] = v
        end

        item.client = formatItemsClient(item.client)

        local perishableColumn = toPerishableColumn(data.perishable)
        item.perishable = fromPerishableColumn(perishableColumn)

        MySQL.awaitQuery(
            --- `decay` no estaba en el UPDATE: la caducidad puesta desde el panel valia
            --- hasta el siguiente reinicio y luego volvia la de antes.
            'UPDATE origen_customitems SET label = ?, weight = ?, rarity = ?, type = ?, image = ?, description = ?, stack = ?, close = ?, server = ?, client = ?, buttons = ?, decay = ?, perishable = ? WHERE name = ?',
            {
                item.label, item.weight, item.rarity, item.type, item.image, item.description, item.stack,
                item.close,
                json.encode(item.server or {}), json.encode(item.client or {}), json.encode(item.buttons or {}),
                tonumber(item.decay) or nil, perishableColumn, item.name
            })

        AddItemToDictionary(item.name, item, true) -- syncToClient = true

        --[[ La foto va ademas a su propia tabla.

             Es la unica que sobrevive a un reinicio para los items que vienen
             de `config/items.lua`, que no tienen fila en `origen_customitems`
             y por tanto el UPDATE de arriba no les toca nada. Escribiendo aqui,
             cambiar la imagen a mano y subirla con el boton acaban en el mismo
             sitio y no hay dos verdades. Ver server/functions/f_fotos_items.lua. ]]
        if data.image ~= nil then
            pcall(function()
                exports.origen_inventory:GuardarFotoItem(item.name, item.image or '')
            end)
        end

        debugger(string.format("[OrgItems] Item '%s' updated in the database and inventory.", item.name))
        return true
    else
        if Items[data.name] then
            local item = Items[data.name]

            for k, v in pairs(data) do
                item[k] = v
            end

            InventoryItems[item.name] = item
        else
            debugger(string.format("[OrgItems] Item '%s' does not exist in the client inventory, adding.", data.name))
        end
    end
end

CItems.RemoveCustomItem = function(name)
    local function removeFromInventory()
        if InventoryItems[name] then
            RemoveItemFromDictionary(name)
            debugger(string.format("[OrgItems] Item '%s' removed from the inventory.", name))
            return true
        else
            debugger(string.format("[OrgItems] Item '%s' does not exist in the inventory.", name))
            return false
        end
    end

    if isServer then
        if not InventoryItems[name] then
            debugger(string.format("[OrgItems] Item '%s' does not exist in the inventory.", name))
            return false
        end

        local success, err = Inventory.__Internal_RefreshDeletedItems(name)
        if success then
            debugger(string.format("[OrgItems] Removed instances of item '%s' from players inventories.", name))
        elseif err then
            debugger(string.format("[OrgItems] Error removing item '%s' from players' inventories: %s", name, err))
        end

        MySQL.awaitQuery('DELETE FROM origen_customitems WHERE name = ?', { name })
        TriggerClientEvent('origen_inventory:client:removeCustomItem', -1, name)
        debugger(string.format("[OrgItems] Item '%s' removed from the database and inventory.", name))
    end

    removeFromInventory()

    return true
end

-- ITEMS DESDE DB
CItems.SetDBItems = function()
    if isServer then -- is Server
        -- Verificar que MySQL esté disponible
        while not MySQL do
            Wait(100)
        end

        -- Verificar que el sistema principal esté listo
        while not InventoryItems or not AddItemToDictionary do
            Wait(50)
        end

        -- oxmysql casts a NULL TINYINT(1) to false, which would opt every item out of decay.
        local customItems = MySQL.awaitQuery('SELECT *, CAST(perishable AS SIGNED) AS perishable_value FROM origen_customitems')
        debugger(string.format("[OrgItems] Loaded %d custom items from database", #customItems))

        for _, item in pairs(customItems) do
            item.server = json.decode(item.server or '{}')
            item.client = json.decode(item.client or '{}')
            item.buttons = json.decode(item.buttons or '{}')
            item.perishable = fromPerishableColumn(item.perishable_value)
            item.perishable_value = nil
            item.custom = true
            AddItemToDictionary(item.name, item, true) -- syncToClient = true
            debugger(string.format("[OrgItems] Loaded custom item '%s' from database", item.name))
        end

        debugger(string.format("[OrgItems] ✅ Todos los custom items cargados correctamente"))
    else -- is Client
        -- Los custom items se sincronizan automáticamente via el sistema de inventario
        -- No se necesita código adicional en el cliente
    end
end

-- Ejecutar inmediatamente para que esté disponible antes de cargar inventarios
CItems.SetDBItems()

-- Eventos addCustomItem y editCustomItem removidos - se sincronizan automáticamente via AddItemToDictionary

RegisterNetEvent('origen_inventory:client:removeCustomItem', function(itemName)
    CItems.RemoveCustomItem(itemName)
    -- Igual que en el alta: el panel de administracion se entera del borrado por
    -- aqui y no por lo que apunte el mismo. Asi tambien se actualiza el panel de
    -- otro administrador que lo tenga abierto a la vez.
    if InventoryUI and InventoryUI.Emit then
        InventoryUI.Emit({ action = 'itemRemoved', name = itemName }, false, true)
    end
end)

exports('AddCustomItem', CItems.AddCustomItem)
exports('EditCustomItem', CItems.EditCustomItem)
exports('RemoveCustomItem', CItems.RemoveCustomItem)
