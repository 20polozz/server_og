Debug = {}
Debug.__index = Debug

function Debug:new(config)
    local instance = setmetatable({}, Debug)

    instance.enabled = config?.enabled or false

    instance.colors = {
        info = '^4[INFO]^7',        -- Azul
        success = '^2[SUCCESS]^7',  -- Verde
        warning = '^3[WARNING]^7',  -- Amarillo
        error = '^1[ERROR]^7',      -- Rojo
        debug = '^5[DEBUG]^7',      -- Magenta
        trace = '^6[TRACE]^7'       -- Cian
    }

    return instance
end


function Debug:log(typeName, force, ...)
    if type(force) ~= "boolean" then
        -- Cuando no ponen true/false, reordenamos
        local args = { force, ... }
        return self:log(typeName, false, table.unpack(args))
    end

    if not self.enabled and not force then
        return
    end

    local color = self.colors[typeName] or self.colors.debug
    local args = {...}
    local message = ""

    for i, arg in ipairs(args) do
        if type(arg) == "table" then
            message = message .. json.encode(arg)
        else
            message = message .. tostring(arg)
        end
        if i < #args then
            message = message .. " "
        end
    end

    local forced = force and " ^9[FORCED]^7" or ""
    print(color .. forced .. " " .. message)
end

local types = { "info", "success", "warning", "error", "debug", "trace" }

for _, t in ipairs(types) do
    Debug[t] = function(self, force, ...)
        if type(force) == "boolean" then
            self:log(t, force, ...)
        else
            self:log(t, false, force, ...)
        end
    end
end
