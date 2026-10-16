Debug = Debug or {}
Debug.__index = Debug

local DEFAULT_COLORS = {
    info = "^4[INFO]^7",
    success = "^2[SUCCESS]^7",
    warning = "^3[WARNING]^7",
    error = "^1[ERROR]^7",
    debug = "^5[DEBUG]^7",
    trace = "^6[TRACE]^7",
}

local LOG_TYPES = { "info", "success", "warning", "error", "debug", "trace" }

local function trim(value)
    return tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function safeEncode(value)
    if type(value) ~= "table" then
        return tostring(value)
    end

    if json and json.encode then
        local ok, encoded = pcall(json.encode, value)
        if ok and encoded then
            return encoded
        end
    end

    return tostring(value)
end

local function mergeColors(baseColors, from)
    if type(from) ~= "table" then
        return baseColors
    end

    for key, value in pairs(from) do
        if type(key) == "string" and type(value) == "string" then
            baseColors[key] = value
        end
    end

    return baseColors
end

function Debug:new(config)
    config = type(config) == "table" and config or {}

    BridgeConfig = BridgeConfig or {}
    local bridgeDebug = BridgeConfig.Debug
    if type(bridgeDebug) == "boolean" then
        bridgeDebug = { enabled = bridgeDebug }
    end
    bridgeDebug = type(bridgeDebug) == "table" and bridgeDebug or {}

    local enabled = false
    if config.enabled ~= nil then
        enabled = config.enabled and true or false
    elseif bridgeDebug.enabled ~= nil then
        enabled = bridgeDebug.enabled and true or false
    end

    local colors = {}
    for key, value in pairs(DEFAULT_COLORS) do
        colors[key] = value
    end

    mergeColors(colors, bridgeDebug.colors)
    mergeColors(colors, config.colors)

    return setmetatable({
        enabled = enabled,
        colors = colors,
    }, Debug)
end

function Debug:log(typeName, force, ...)
    if type(force) ~= "boolean" then
        return self:log(typeName, false, force, ...)
    end

    if not self.enabled and not force then
        return
    end

    local args = { ... }
    local chunks = {}

    for i = 1, #args do
        chunks[#chunks + 1] = safeEncode(args[i])
    end

    local tag = self.colors[typeName] or self.colors.debug
    local forced = force and " ^9[FORCED]^7" or ""
    local message = table.concat(chunks, " ")

    print(("%s%s%s %s"):format(tag, forced, ' ' .. message, "^0"))
end

for i = 1, #LOG_TYPES do
    local levelName = LOG_TYPES[i]
    Debug[levelName] = function(self, force, ...)
        if type(force) == "boolean" then
            return self:log(levelName, force, ...)
        end
        return self:log(levelName, false, force, ...)
    end
end
