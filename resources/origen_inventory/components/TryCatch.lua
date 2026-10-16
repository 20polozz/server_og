TryCatch = {}
TryCatch.__index = TryCatch

function TryCatch.new()
    local self = setmetatable({}, TryCatch)
    self.tryBlock = nil
    self.catchBlock = nil
    return self
end

function TryCatch:try(block)
    self.tryBlock = block
    return self
end

function TryCatch:catch(block)
    self.catchBlock = block
    return self
end

function TryCatch:finally(block)
    if self.tryBlock then
        local status, result = pcall(self.tryBlock)
        if not status then
            if self.catchBlock then
                self.catchBlock(result)
            end
        end
    end
    if block then
        block()
    end
end

function TryCatch:throw(message)
    error(message)
end

function TryCatch:execute()
    if self.tryBlock then
        local status, result = pcall(self.tryBlock)
        if not status then
            if self.catchBlock then
                self.catchBlock(result)
            end
        end
    end
end