function validateEnumString(str, strType)
    if type(str) ~= "string" then
        error(strType .. " must be a string")
    end
    if str:match("[^%a]") then
        error(strType .. " must only contain letters")
    end
end

function LocalEnum(name, vals)
    validateEnumString(name, "Enum name")
    local enum = {}
    for k, v in pairs(vals) do
        if (not tonumber(k)) then
        validateEnumString(k, "Enum value")
        enum[k] = v
        else
        validateEnumString(v, "Enum value")
        enum[v] = v
        end
    end
    return enum
end
  
function Enum(name, vals)
    _G[name] = LocalEnum(name, vals)
end