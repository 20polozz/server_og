_T = {}
_T.__index = _T

---@param lang string
function _T:new(lang)
    local self = setmetatable({
        lang = lang,
    }, _T)
    self:extend(Lang[lang])
    return self
end

---@param phrases table
---@param prefix string
function _T:extend(phrases, prefix)
    for key, phrase in pairs(phrases) do
        local prefixKey = prefix and ('%s.%s'):format(prefix, key) or key
        if type(phrase) == 'table' then
            self:extend(phrase, prefixKey)
        else
            self[prefixKey] = phrase
        end
    end
end

---@param key string
---@param opts? table | string | number
---@return string
function _T:t(key, opts)
    local p = promise.new()
    TryCatch
    :try(function()
        if not key then error('key is required') return end
        if not self[key] then
            p:resolve(key)
            return
        end
        if type(opts) == 'table' and self[key]:match('%s') then 
             p:resolve( self[key]:format(table.unpack(opts)))
        elseif  type(opts) ~= 'table' and self[key]:match('%s') then 
            p:resolve(self[key]:format(opts))
        else
            p:resolve(self[key])
        end
    end)
    :catch(function(err)
        debugger('^1locale error^0: ' .. tostring(err))
    end)
    :finally(function() end)
    return Citizen.Await(p)
end


locale = _T:new(Config.Language)
