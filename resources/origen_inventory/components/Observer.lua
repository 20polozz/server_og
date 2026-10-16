EventPublisher = {}
EventPublisher.__index = EventPublisher

function EventPublisher.new()
    local self = setmetatable({}, EventPublisher)
    self.observers = {}
    return self
end

function EventPublisher:subscribe(event, func)
    self.observers[event] = self.observers[event] or {}
    table.insert(self.observers[event], func)
end

function EventPublisher:unsubscribe(event, func)
    if not self.observers[event] then return end
    for i, observer in ipairs(self.observers[event]) do
        if observer == func then
            table.remove(self.observers[event], i)
            break
        end
    end
end

function EventPublisher:publish(event, ...)
    local observers = self.observers[event]
    if not observers then return nil end

    -- Realizar una copia para evitar conflictos si los observadores modifican la tabla
    local observersSnapshot = {table.unpack(observers)}
    
    local results = {}
    
    for i, observer in ipairs(observersSnapshot) do
        local ok, result = pcall(observer, ...)
        if not ok then
            debugger(("Error en observador del evento '%s': %s"):format(event, result))
            results[i] = false
        else
            results[i] = result ~= nil and result or true  -- Si no retorna nada, asume éxito
        end
    end
    
    -- Si solo hay un observador, retornar su resultado directamente
    if #results == 1 then
        return results[1]
    end
    
    -- Si hay múltiples observadores, retornar true solo si todos tuvieron éxito
    for _, result in ipairs(results) do
        if result == false then
            return false
        end
    end
    
    return true
end