TryCatch = {}
TryCatch.__index = TryCatch

function TryCatch.new()
    local self = setmetatable({}, TryCatch)
    self.tryFunc = nil
    self.catchFunc = nil
    self.finallyFunc = nil
    return self
end

function TryCatch:try(func)
    self.tryFunc = func
    return self
end

function TryCatch:catch(func)
    self.catchFunc = func
    return self
end

function TryCatch:finally(func)
    self.finallyFunc = func
    
    local success, err = pcall(self.tryFunc)
    
    if not success and self.catchFunc then
        self.catchFunc(err)
    end
    
    if self.finallyFunc then
        self.finallyFunc()
    end
    
    return self
end

