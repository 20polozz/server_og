Handlers = {}
Handlers.__index = Handlers

function Handlers.new(interval)
    local self = setmetatable({}, Handlers)
    self.interval = interval or 1000
    self.registered = {}
    return self
end

function Handlers:Register(handlerData)
    if self.registered[handlerData.name] then return end
    self.registered[handlerData.name] = handlerData
    handlerData.callbacks = {}
    handlerData.lastResult = nil
    handlerData.lastExtra = nil
end

function Handlers:AddCallback(name, cb)
    if self.registered[name] then
        table.insert(self.registered[name].callbacks, cb)
    end
end

function Handlers:Start()
    CreateThread(function()
        while true do
            Wait(self.interval)

            if not next(self.registered) then
                Wait(1000)
                goto continue
            end

            for name, handler in pairs(self.registered) do
                local result, extra = handler.check(handler)

                if result ~= handler.lastResult then
                    handler.lastResult = result
                    handler.lastExtra = extra
                    for _, cb in ipairs(handler.callbacks) do
                        cb(result, extra)
                    end
                end
            end
            ::continue::
        end
    end)
end

HandlerManager = Handlers.new(1000)

HandlerManager:Register(VehicleSitHandler)

HandlerManager:Start()