local ModulesController = {}

ModulesController.get = function(id)
    return Module.instances[id] or nil
end
exports('getModule', ModulesController.get)

ModulesController.create = function(data)
    return Module.new(data)
end
exports('createModule', ModulesController.create)

---Send Module message
---@param id string
---@param data any
---@return boolean
ModulesController.sendMessage = function(id, data)
    local module = ModulesController.get(id)
    if not module then return false end
    local action = 'onModuleMessage'
    InventoryUI.Emit({
        action = action,
        data = {
            id = id,
            module = data
        }
    }, false, false)
end
exports('sendModuleMessage', ModulesController.sendMessage)

ModulesController.check = function(id)
    if not Module.instances or not next(Module.instances) then return end

    if id then
        local module = ModulesController.get(id)
        if not module then return end

        if module:canShow() then
            module:create()
        else
            module:remove()
        end
    else
        for _, module in pairs(Module.instances) do
            if module:canShow() then
                module:create()
            else
                module:remove()
            end
        end
    end
end
exports('checkModules', ModulesController.check)

ModulesController.getAll = function()
    return Module.instances
end
exports('getModules', ModulesController.getAll)

ModulesController.remove = function(id)
    local module = ModulesController.get(id)
    if not module then return false end

    module:remove()
    Module.instances[id].canShow = nil
    Module.instances[id].onOpen = nil
    Module.instances[id].onClose = nil
    Module.instances[id] = nil
    return true
end
exports('removeModule', ModulesController.remove)

CreateThread(function()
    InventoryUI.On('onOpenModule', function(data, cb)
        local module = ModulesController.get(data.id)
        if not module then return end

        module:onOpen()
        return true
    end)

    InventoryUI.On('onCloseModule', function(data, cb)
        local module = ModulesController.get(data.id)
        if not module then return end

        module:onClose()
        return true
    end)
end)
