ResourceName = GetCurrentResourceName()

nop = function() end

function ConvertVec4ToVec3(vec4)
    return vec3(vec4.x, vec4.y, vec4.z)
end

function NearlyEqual(a, b, tolerance)
    if not a or not b then return false end
    tolerance = tolerance or 0.01
    return math.abs(a - b) <= tolerance
end

function VectorNearlyEqual(a, b, tolerance)
    if not a or not b then return false end
    tolerance = tolerance or 0.01
    return math.abs(a.x - b.x) <= tolerance and math.abs(a.y - b.y) <= tolerance and math.abs(a.z - b.z) <= tolerance
end

function ConvertArrayToVec(array)
    if #array == 3 then
        return vec3(array[1], array[2], array[3])
    elseif #array == 4 then
        return vec4(array[1], array[2], array[3], array[4])
    else
        debugger("Invalid array length, expected 3 or 4, got: " .. #array)
        return nil
    end
end

function ConvertVecToArray(vec)
    if vec == nil then
        return nil
    end
    if vec.w then
        return {vec.x, vec.y, vec.z, vec.w}
    else
        return {vec.x, vec.y, vec.z}
    end
end

function Dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function TableContains(table, value, valueExtractor)
    for _, v in pairs(table) do
        if (valueExtractor and valueExtractor(v) == value) or v == value then
            return true
        end
    end
    return false
end

function CombineTables(target, source)
    local result = {}

    for k, v in pairs(target) do
        result[k] = v
    end

    for k, v in pairs(source) do
        result[k] = v
    end

    return result
end

function parseItemHash(hash)
    local collection, component_id, drawable_id, texture_id = string.match(hash, "^(.-)%-%-([%-]?%d+)%-%-([%-]?%d+)%-%-([%-]?%d+)$")

    component_id = tonumber(component_id)

    return {
        collection = collection,
        component_id = component_id,
        drawable_id = tonumber(drawable_id),
        texture_id = tonumber(texture_id),
        anchor = component_id >= 1000 and component_id - 1000 or false
    }
end

function FormatTable(table)
	if not table then return {} end
    if type(table) == 'string' then 
        table = json.decode(table)
    end
    return table
end

exports('GetRemoveHash', function(model, category)
    local removeData = Config.RemoveItem[model]
    if removeData then
        return removeData[category]
    end
    return nil
end)