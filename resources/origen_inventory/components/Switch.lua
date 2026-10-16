Switch = {}
Switch.__index = Switch

function Switch.new(value)
    local self = setmetatable({}, Switch)
    self.value = value
    self.cases = {}
    self.defaultCase = nil
    return self
end

function Switch:case(caseValue, action)
    if caseValue ~= nil and action ~= nil then
        self.cases[caseValue] = action
    end
    return self
end

function Switch:default(action)
    self.defaultCase = action
    return self
end

function Switch:execute()
    if self.cases[self.value] then
        self.cases[self.value]()
    elseif self.defaultCase then
        self.defaultCase()
    end
end