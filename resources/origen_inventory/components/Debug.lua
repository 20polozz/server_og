Debug = {}
Debug.__index = Debug

function Debug.new(debugMode)
    local self = setmetatable({}, Debug)
    self.debugMode = debugMode or false
    return self
end

function Debug:isDebug()
    return self.debugMode
end

function Debug:buildMessage(...)
  local args = {...}
  local message = ''
  for i, v in ipairs(args) do
    message = message .. (v == nil and 'nil values' or tostring(v)) .. (i < #args and ", " or "")
  end
  return message
end

function Debug:log(type, ...)
  if self:isDebug() then
    local message = self:buildMessage(...)
    debugger('^5[ORG_INV]:^0 ' .. message, '^0')
  end
end
