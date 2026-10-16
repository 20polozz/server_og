Inventory = {}
Inventory.wheelEnabled = false
Inventory.locked = false

---Open a inventory
---@param invType string
---@param data table | string | number
---@param extraData? table
Inventory.open = function(invType, data, extraData)
    local invData = {}
    if type(data) ~= 'table' then
        invData.id = data
        invData.extra = extraData
    else
        invData = data
    end

    if invType == 'player' then
        invType = 'otherplayer'
    end

    TriggerServerEvent("inventory:server:OpenInventory", invType, invData.id, invData)
end
exports('openInventory', Inventory.open)
exports('OpenInventory', Inventory.open)
exportsOX('OpenInventory', Inventory.open)

Inventory.openCartera = function(slot, item)
    if not item or not item.metadata or not item.metadata.bagId then return end
    local itemData = Items(item.name)
    local bagProps = itemData.bagProps or {
        maxweight = 200,
        slots = 5,
        label = itemData.label or "Mi Cartera"
    }
    Inventory.open('stash', string.format('cartera-%s', item.metadata.bagId), bagProps)
end
exports('openCartera', Inventory.openCartera)

Inventory.openBolsa = function(slot, item)
    if not item or not item.metadata or not item.metadata.bagId then return end
    local itemData = Items(item.name)
    local bagProps = itemData.bagProps or {
        maxweight = 20000,
        slots = 10,
        label = itemData.label or "Mi Bolsa Simple"
    }
    Inventory.open('stash', string.format('paperbag-%s', item.metadata.bagId), bagProps)
end
exports('openBolsa', Inventory.openBolsa)

Inventory.get = function()
    return Player?.inventory or {}
end
exports('getInventory', Inventory.get)
exports('GetInventory', Inventory.get)
exports('getPlayerInventory', Inventory.get)
exports('GetPlayerInventory', Inventory.get)

Inventory.isOpen = function()
    if not Player then return false end
    return Player.isOpen
end
exports('IsInventoryOpen', Inventory.isOpen)
exportsQB('IsInventoryOpen', Inventory.isOpen)

Inventory.lock = function()
    Inventory.locked = true
end
exports('lock', Inventory.lock)
exports('LockInventory', Inventory.lock)

Inventory.unlock = function()
    Inventory.locked = false
end
exports('unlock', Inventory.unlock)
exports('UnlockInventory', Inventory.unlock)

Inventory.isLocked = function()
    return Inventory.locked
end
exports('isLocked', Inventory.isLocked)
exports('IsInventoryLocked', Inventory.isLocked)

Inventory.toggleLock = function(toggle)
    Inventory.locked = toggle
end
exports('toggleLock', Inventory.toggleLock)
exports('ToggleInventoryAccess', Inventory.toggleLock)

---Use Inventory Slot
---@param slot number
---@return boolean
Inventory.useSlot = function(slot)
    if type(slot) ~= 'number' then return false end

    debugger("[INV] Using slot:", slot)
    TriggerServerEvent("inventory:server:UseItemSlot", slot)
    return true
end
exports('useSlot', Inventory.useSlot)

---Search inventory item
---@param search 'slots'|'count'
---@param item string | table<string>
---@param metadata (table | string) | nil
Inventory.search = function(search, item, metadata)
    if not Player then return false end

    local invItems = Player.inventory
    local isSingleItem = type(item) == 'string'
    if isSingleItem then item = { item } end

    --[[ El inventario puede no haber llegado todavia. Recorrerlo entonces era un
         `pairs(nil)` que no moria aqui, sino en quien preguntara: el hilo de la
         radio de origen_police lo consulta cada cuatro segundos desde que arranca
         el recurso, y el error salia con su nombre. Se contesta "no tienes nada",
         que es lo unico que se puede decir con verdad mientras no haya inventario. ]]
    if type(invItems) ~= 'table' then
        if search == 'count' then return isSingleItem and 0 or {} end
        return {}
    end

    local function matchesMetadata(itemData, metadata)
        if not metadata then return true end

        if type(metadata) == 'string' then
            return itemData.metadata and itemData.metadata.type == metadata
        elseif type(metadata) == 'table' then
            for key, value in pairs(metadata) do
                if not (itemData.metadata and itemData.metadata[key] == value) then
                    return false
                end
            end
            return true
        end

        return false
    end

    if search == 'count' then
        local result = {}

        for _, itemName in ipairs(item) do
            for i, invItem in pairs(invItems) do
                if invItem.name == itemName then
                    local itemData = invItem
                    if matchesMetadata(itemData, metadata) then
                        result[itemName] = (result[itemName] or 0) + itemData.count
                    end
                    break
                end
            end
        end

        return isSingleItem and (result[item[1]] or 0) or result
    elseif search == 'slots' then
        local result = {}

        for _, itemName in ipairs(item) do
            for i, invItem in pairs(invItems) do
                if invItem.name == itemName then
                    if matchesMetadata(invItem, metadata) then
                        result[itemName] = result[itemName] or {}
                        table.insert(result[itemName], {
                            slot = invItem.slot,
                            count = invItem.count or invItem.amount,
                            metadata = invItem.metadata
                        })
                    end
                end
            end
        end

        return result
    end

    return false
end
exports('search', Inventory.search)
exports('Search', Inventory.search)

---------- WEAPONS

Inventory.getCurrentWeapon = function()
    local cWeapon, cSlot, cData = Internal__GetCurrentWeapon()
    if not cWeapon then return false end
    local wHash = GetHashKey(cWeapon)
    local weaponData = GetWeapons(wHash)
    local weaponItemData = Items(weaponData.name)

    if not weaponItemData then return false end

    return {
        ammo = weaponData.ammotype,
        hash = wHash,
        label = weaponItemData.label,
        melee = weaponData.weapontype == 'Melee',
        metadata = cData.metadata,
        name = cWeapon,
        slot = cSlot,
        weight = weaponItemData.weight
    }
end
exports('getCurrentWeapon', Inventory.getCurrentWeapon)
exports('GetCurrentWeapon', Inventory.getCurrentWeapon)

Inventory.weaponWheel = function(state)
    Inventory.wheelEnabled = state
end
exports('weaponWheel', Inventory.weaponWheel)

-- Inventory.useSlot = function(slot)
--     TriggerServerEvent("inventory:server:UseItemSlot", slot)
-- end
-- exports('useSlot', Inventory.useSlot)

Inventory.useItem = function(item)
    local itemData = Items(item.name)
    if not itemData or not itemData.client then return false end

    local client = itemData.client or {}

    local canUseItem = Inventory.__Internal_CanUseItem(item.name)
    if not canUseItem then return false end

    if client.export then
        local resource, func = string.match(client.export, "([^%.]+)%.([^%.]+)")
        if resource and func then
            local resourceTable = exports[resource]

            local exportFound = pcall(function()
                local test = resourceTable[func]
            end)

            if not exportFound then
                debugger("[INV] Export function not found for " ..
                    itemData.name .. ". Please make sure you read the documentation.")
                return
            end

            if resourceTable and type(resourceTable[func]) == "function" then
                local success, result = pcall(resourceTable[func], resourceTable, item.slot, item)
                if not success then
                    debugger("[INV] Error while exporting function for " .. itemData.name .. ": " .. result)
                else
                    if Player then Player:CloseInventory() end
                end
            else
                debugger("[INV] Not found export function for " .. itemData.name .. ".")
            end
        else
            debugger("[INV] Misspelled export function for " .. itemData.name .. ", make sure you put resource.function.")
        end
    end
end

Inventory.hasItem = function(item, amount)
    if not Player then return false end
    amount = amount or 1

    local invItems = Player.inventory
    --- Mismo caso que en `Inventory.search`: sin inventario, no se tiene nada.
    if type(invItems) ~= 'table' then return false end

    local total = 0

    for i, invItem in pairs(invItems) do
        if invItem.name == item then
            total = total + (invItem.count or invItem.amount)
            if total >= amount then
                return true
            end
        end
    end

    return false
end
exports('hasItem', Inventory.hasItem)
exports('HasItem', Inventory.hasItem)

Inventory.getPlayerItems = function()
    --- `Player` es nil hasta que el personaje entra, y esto lo llaman de fuera.
    if not Player then return {} end
    return Player.inventory or {}
end
exports('getPlayerItems', Inventory.getPlayerItems)
exports('GetPlayerItems', Inventory.getPlayerItems)

--- Display item metadata
--- @param metadata table | string
--- @param value any
--- @return boolean
Inventory.displayMetadata = function(metadata, value)
    if not metadata then return false end
    local newMetadata = {}
    if type(metadata) ~= 'table' then
        table.insert(newMetadata, { metadata = metadata, value = value })
    elseif #metadata > 0 then
        for i, meta in pairs(metadata) do
            table.insert(newMetadata, { metadata = meta.metadata, value = meta.value })
        end
    else
        for key, val in pairs(metadata) do
            table.insert(newMetadata, { metadata = key, value = val })
        end
    end

    InventoryUI.Emit({
        action = 'displayMetadata',
        data = newMetadata
    })

    return true
end
exports('displayMetadata', Inventory.displayMetadata)

Inventory.getHotbar = function()
    local hotbar = {}
    if not Player then return hotbar end

    for i = 1, 6 do
        for _, item in pairs(Player:getInventory()) do
            if item.slot == i then
                hotbar[i] = item
                break
            end
        end
    end

    return hotbar
end

--- Abre el panel de administracion del inventario.
---
--- Lo llama el panel de admin desde su pestana "Scripts". Se marca de donde
--- se viene para que el boton de volver reabra el admin ahi mismo: la
--- bandera existia y se leia al cerrar, pero no la ponia nadie, asi que
--- volver no hacia nada.
Inventory.openManagement = function(desdeAdmin)
    Inventory.openedFromHub = desdeAdmin ~= false
    InventoryUI.OpenManagement()
end
exports('openManagement', Inventory.openManagement)

local function ListenClose()
    if Player.inloop then return end
    CreateThread(function()
        Player.inloop = true
        while Player.inloop do
            Wait(1000)
            player, distance = Player:GetClosestPlayer()
            if not player or distance > 3 then
                Player.inloop = false
                Player:CloseInventory()
                return
            end
        end
    end)
end
Inventory.__Internal_SearchClosestPlayer = function()
    local player, distance = Player:GetClosestPlayer()
    if Player.inloop then return false end

    ListenClose()

    if not player or distance > 3 then
        Bridge.Notify(locale:t('notify.search.notclose'), 'error')
        return false
    end

    if not Bridge.CanSearch(GetPlayerPed(player)) then
        Bridge.Notify(locale:t('notify.search.nothandsup'), 'error')
        return false
    end

    local plyId = GetPlayerServerId(player)
    RequestAnimDict("anim@gangops@facility@servers@bodysearch@")
    while not HasAnimDictLoaded("anim@gangops@facility@servers@bodysearch@") do
        Citizen.Wait(100)
    end
    Player:CloseInventory(true)
    local controls = exports.origen_inventory:controls(false, false, false, false)
    Bridge.ProgressBar('search_player_inv', locale:t('notify.search.searching'), 5000,
        controls,
        exports.origen_inventory:progress_animation_fix({
            dict = "anim@gangops@facility@servers@bodysearch@",
            clip =
            "player_search"
        }),
        false, function(result)
            if result then
                StopAnimTask(PlayerPedId(), "anim@gangops@facility@servers@bodysearch@", "player_search", 1.0)
                Inventory.open('otherplayer', plyId)
            end
        end)

    return true
end

local tasks = {}

Inventory.__Internal_AddTask = function(task, func)
    if not tasks[task] then
        tasks[task] = {}
    end
    tasks[task][#tasks[task] + 1] = func
end

Inventory.__Internal_RunTask = function(task, ...)
    if not tasks[task] then return end

    for _, func in pairs(tasks[task]) do
        if type(func) == 'function' then
            local success, err = pcall(func, ...)
            if not success then
                debugger("[INV] Error running task '" .. task .. "': " .. err)
            end
        end
    end
end

Inventory.__Internal_CanUseItem = function(itemName)
    local itemData = Items(itemName)
    if not itemData or not itemData.client then return true end
    local client = itemData.client or {}
    local playerPed = PlayerPedId()

    local disableOptions = client.disable or {}
    if type(disableOptions.car) ~= "nil" then
        if disableOptions.car then
            local inVehicle = GetVehiclePedIsIn(playerPed, false)
            if inVehicle ~= 0 then
                debugger(string.format('[Inventory.useSlot] Tried to use item %s while in vehicle', itemName))
                return false, 'cannot_use_item_in_vehicle'
            end
        end
    end

    if type(disableOptions.combat) ~= "nil" then
        if disableOptions.combat then
            if IsPedInMeleeCombat(playerPed) or IsPedShooting(playerPed) then
                debugger(string.format('[Inventory.useSlot] Tried to use item %s while in combat', itemName))
                return false, 'cannot_use_item_in_combat'
            end
        end
    end

    if type(disableOptions.sprint) ~= "nil" then
        if disableOptions.sprint then
            if IsPedSprinting(playerPed) then
                debugger(string.format('[Inventory.useSlot] Tried to use item %s while sprinting', itemName))
                return false, 'cannot_use_item_while_sprinting'
            end
        end
    end

    if type(disableOptions.move) ~= "nil" then
        if disableOptions.move then
            if IsPedWalking(playerPed) or IsPedRunning(playerPed) or IsPedSprinting(playerPed) then
                debugger(string.format('[Inventory.useSlot] Tried to use item %s while moving', itemName))
                return false, 'cannot_use_item_while_moving'
            end
        end
    end

    -- Mouse aiming check or mouse movement
    if type(disableOptions.mouse) ~= "nil" then
        if disableOptions.mouse then
            if IsControlPressed(0, 25) then -- INPUT_AIM
                debugger(string.format('[Inventory.useSlot] Tried to use item %s in slot %s while aiming', itemName))
                return false, 'cannot_use_item_while_aiming'
            end
        end
    end

    return true
end

-- ==============================
-- Sistema unificado de eventos
-- ==============================
local unifiedEvents = {
    ["QBCore:Client:OnJobUpdate"] = "onJobUpdate",
    ["QBCore:Client:OnGangUpdate"] = "onJobUpdate",
    ["esx:setJob"] = "onJobUpdate",
    ["onResourceStop"] = "onResourceStop"
}

for event, taskName in pairs(unifiedEvents) do
    RegisterNetEvent(event, function(...)
        Inventory.__Internal_RunTask(taskName, ...)
    end)
end
