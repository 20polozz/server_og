_T = {}
_T.__index = _T

while not Debug do
    Wait(100)
end

local dbg = Debug:new({ enabled = Config.Debug })

---@param lang string
function _T:new(lang)
    local self = setmetatable({
        lang = lang,
    }, _T)
    -- Load English as base fallback first, then overlay active language.
    if Lang["en"] then
        self:extend(Lang["en"])
    end
    if Lang[lang] then
        self:extend(Lang[lang])
        --[[ Las claves que trae el idioma activo, aparte. Hacen falta para
             saber si una frase es de verdad de este idioma o viene del
             respaldo en ingles: ver el alias de _T:t. ]]
        self._propias = {}
        self:extend(Lang[lang], nil, self._propias)
    end
    return self
end

---@param phrases table
---@param prefix string
---@param destino? table  donde se apuntan; por defecto, el propio locale
function _T:extend(phrases, prefix, destino)
    destino = destino or self
    for key, phrase in pairs(phrases) do
        local prefixKey = prefix and ('%s.%s'):format(prefix, key) or key
        if type(phrase) == 'table' then
            self:extend(phrase, prefixKey, destino)
        else
            destino[prefixKey] = phrase
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
        local resolvedKey = key

        --[[ Muchas frases estan como ui.* en un idioma y como notify.* en otro.

             Antes el alias solo se probaba si la clave no existia en NINGUN
             idioma. Pero el ingles se carga debajo como respaldo, asi que casi
             siempre existia: se pedia notify.x, el español la tenia como ui.x,
             y salia la inglesa. Ahora la frase del idioma activo gana al
             respaldo, este en el espacio que este. ]]
        local propias = self._propias or {}
        if not propias[resolvedKey] then
            local aliasKey
            if key:sub(1, 7) == 'notify.' then
                aliasKey = 'ui.' .. key:sub(8)
            elseif key:sub(1, 3) == 'ui.' then
                aliasKey = 'notify.' .. key:sub(4)
            end

            if aliasKey and self[aliasKey] and (propias[aliasKey] or not self[resolvedKey]) then
                resolvedKey = aliasKey
            end
        end

        if not self[resolvedKey] then
            -- Avoid exposing raw locale keys (notify.foo_bar) to players.
            local fallback = key
            local lastSegment = key:match('([^%.]+)$')
            if lastSegment and lastSegment ~= '' then
                fallback = lastSegment
            end
            fallback = fallback:gsub('_', ' ')
            fallback = fallback:gsub('^%l', string.upper)
            p:resolve(fallback)
            return
        end
        if type(self[resolvedKey]) == 'string' then
            local normalizedOpts = opts
            if type(opts) == 'table' then
                normalizedOpts = {}
                for i, value in ipairs(opts) do
                    if type(value) == 'string' and value:find('_') and not value:find('%s') then
                        normalizedOpts[i] = value:gsub('_', ' ')
                    else
                        normalizedOpts[i] = value
                    end
                end
            end
            if type(opts) == 'string' and opts:find('_') and not opts:find('%s') then
                normalizedOpts = opts:gsub('_', ' ')
            end
            if type(normalizedOpts) == 'table' and self[resolvedKey]:match('%s') then 
                p:resolve(self[resolvedKey]:format(table.unpack(normalizedOpts)))
            elseif type(normalizedOpts) ~= 'table' and self[resolvedKey]:match('%s') then 
                p:resolve(self[resolvedKey]:format(normalizedOpts))
            else
                p:resolve(self[resolvedKey])
            end
        else
            p:resolve(self[resolvedKey])
        end
    end)
    --[[ El catch TIENE que resolver la promesa.

         Antes solo la registraba, y eso deja `Citizen.Await(p)` esperando una
         respuesta que no llega nunca: el hilo que llamo a locale:t se queda
         colgado para siempre, sin error ni aviso. Basta con que una frase
         lleve dos %s y se le pase un solo dato —string.format lanza— para
         matar en silencio lo que sea que estuviera haciendo el hilo. Asi se
         colgaba entero el cuadro de mando de banda.

         Se responde con la frase en crudo, sin rellenar. Sale un %s a la
         vista, que es feo, pero se ve y se arregla; colgarse no se ve. ]]
    :catch(function(err)
        dbg:error('^1locale error^0: ' .. tostring(err))
        -- En pcall porque si ya estaba resuelta, resolver otra vez lanza; y
        -- aqui lo unico que no puede pasar es volver a quedarse callado.
        pcall(function()
            p:resolve(type(self[key]) == 'string' and self[key] or key)
        end)
    end)
    :finally(function() end)
    return Citizen.Await(p)
end

locale = _T:new(Config.Language)

