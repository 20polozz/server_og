Module = {}
Module.__index = Module
Module.instances = {}

---@class ModuleData
---@field id string
---@field icon? string
---@field ui string -- (https://cfx-nui-resource_name/html/index.html)
---@field useDefaultBackground? boolean
---@field canShow? function
---@field resource? string
---@field onOpen? function
---@field onClose? function
function Module.new(data)
    if Module.instances[data.id] then return Module.instances[data.id] end

    local self = setmetatable({}, Module)
    self.id = data.id
    self.icon = data.icon
    self.ui = data.ui
    self.useDefaultBackground = data.useDefaultBackground or false
    self.canShow = nil
    self.resource = data.resource or GetInvokingResource()
    self.onOpen = data.onOpen or nil
    self.onClose = data.onClose or nil

    if data.canShow and type(data.canShow) == 'table' then
        self.canShow = data.canShow
    end

    Module.instances[self.id] = self

    self:create()

    return self
end



function Module:canShow()
    if not self.canShow or self.canShow == nil then 
        return true
    end
    return self:canShow()
end

function Module:create()
    if self:canShow() then
        local data = {
            id = self.id,
            icon = self.icon,
            ui = self.ui,
            useDefaultBackground = self.useDefaultBackground,
            resourceName = self.resource,
        }

        SendNUIMessage({
            action = 'newModule',
            module = data
        })
    end
end

function Module:remove()
    local data = {
        id = self.id,
        icon = self.icon,
        ui = self.ui,
        useDefaultBackground = self.useDefaultBackground,
        resourceName = self.resource,
    }
    SendNUIMessage({
        action = 'removeModule',
        module = data
    })
end

function Module:onOpen()
    if not self.onOpen then return end
    self:onOpen()
end

function Module:onClose()
    if not self.onClose then return end
    self:onClose()
end