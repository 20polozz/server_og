--========================================================--
--=                 Event Hook System (Client)            =--
--========================================================--

local eventHooks = {}
local microtime = GetGameTimer
local hookId = 0

--========================================================--
--=                       Utils                          =--
--========================================================--

local function matchItem(filter, item, secondItem)
    local itemName = type(item) == 'table' and item.name or item
    if itemName and filter[itemName] then return true end
    if type(secondItem) == 'table' and filter[secondItem.name] then return true end
    return false
end

local function matchInventory(filter, fromInv, toInv)
    for _, pattern in ipairs(filter) do
        if fromInv and fromInv:match(pattern) then return true end
        if toInv and toInv:match(pattern) then return true end
    end
    return false
end

local function matchType(filter, t)
    return filter[t] or false
end

local function debugMessage(fmt, ...)
    print(('[HOOK DEBUG] ' .. fmt):format(...))
end

--========================================================--
--=                 Hook Execution Core                  =--
--========================================================--

function TriggerEventHooks(event, payload)
    local hooks = eventHooks[event]
    if not hooks then return true end

    local fromInv = tostring(payload.fromInventory or payload.inventoryId or payload.shopType or '')
    local toInv = tostring(payload.toInventory or '')
    local invType = payload.inventoryType or payload.shopType or payload.fromType

    for i, hook in ipairs(hooks) do
        if hook.itemFilter and not matchItem(hook.itemFilter, payload.fromSlot or payload.item or payload.itemName or payload.recipe, payload.toSlot) then
            goto continue
        end
        if hook.inventoryFilter and not matchInventory(hook.inventoryFilter, fromInv, toInv) then
            goto continue
        end
        if hook.typeFilter and not matchType(hook.typeFilter, invType) then
            goto continue
        end

        if hook.debugger then
            debugMessage('%s:%s:%s', hook.resource or 'client', event, i)
        end

        local start = microtime()
        local ok, result = pcall(hook, payload)
        local elapsed = microtime() - start

        if elapsed >= 100 then
            debugMessage('Hook "%s:%s:%s" tardó %.2fms.', hook.resource or 'client', event, i, elapsed)
        end

        if result == false then
            return false
        end

        ::continue::
    end

    return (event == 'createItem') and payload.metadata or true
end

--========================================================--
--=              Hook Registration / Removal             =--
--========================================================--

exports('registerHook', function(event, callback, options)
    if not eventHooks[event] then eventHooks[event] = {} end

    hookId += 1

    local mt = getmetatable(callback)
    mt.__index = nil
    mt.__newindex = nil

    callback.hookId = hookId
    callback.resource = GetCurrentResourceName()

    if options then
        for k, v in pairs(options) do
            callback[k] = v
        end
    end

    table.insert(eventHooks[event], callback)
    return hookId
end)

exports('removeHooks', function(id)
    local currentResource = GetCurrentResourceName()

    for _, hooks in pairs(eventHooks) do
        for i = #hooks, 1, -1 do
            local hook = hooks[i]
            if hook.resource == currentResource and (not id or hook.hookId == id) then
                table.remove(hooks, i)
            end
        end
    end
end)

--========================================================--
--=                Resource Cleanup Handler              =--
--========================================================--

AddEventHandler('onClientResourceStop', function(resource)
    for _, hooks in pairs(eventHooks) do
        for i = #hooks, 1, -1 do
            if hooks[i].resource == resource then
                table.remove(hooks, i)
            end
        end
    end
end)
