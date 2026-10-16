Observer = {}
Observer.__index = Observer

function Observer.new()
    local self = setmetatable({}, Observer)
    self.events = {}
    return self
end

function Observer:on(eventName, callback)
    if not self.events[eventName] then
        self.events[eventName] = {}
    end
    table.insert(self.events[eventName], callback)
end

function Observer:off(eventName, callback)
    if not self.events[eventName] then return end
    
    for i, cb in ipairs(self.events[eventName]) do
        if cb == callback then
            table.remove(self.events[eventName], i)
            break
        end
    end
end

function Observer:emit(eventName, ...)
    if not self.events[eventName] then return end
    
    for _, callback in ipairs(self.events[eventName]) do
        callback(...)
    end
end

function Observer:once(eventName, callback)
    local wrapper
    wrapper = function(...)
        callback(...)
        self:off(eventName, wrapper)
    end
    self:on(eventName, wrapper)
end

