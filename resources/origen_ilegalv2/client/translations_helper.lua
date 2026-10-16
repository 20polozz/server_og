-- Aplana la tabla de traducciones en dot-notation, igual que _T:extend en locales.lua.
-- Esto garantiza que el front recibe SIEMPRE el mismo conjunto de claves que usa Lua,
-- sin importar cuántas keys nuevas se agreguen en el futuro.
local function FlattenTranslations(phrases, prefix, out)
    out = out or {}
    for key, phrase in pairs(phrases) do
        local prefixKey = prefix and (prefix .. '.' .. key) or tostring(key)
        if type(phrase) == 'table' then
            FlattenTranslations(phrase, prefixKey, out)
        else
            out[prefixKey] = phrase
        end
    end
    return out
end

function SendTranslationsToNUI()
    if not Lang or not Config or not Config.Language then return end

    local raw = Lang[Config.Language]
    if not raw then return end

    SendNUIMessage({
        action = 'setTranslations',
        data   = FlattenTranslations(raw),
    })
end

exports('SendTranslationsToNUI', SendTranslationsToNUI)

-- NUI pull: la NUI puede pedir traducciones en caliente (fetchNui)
RegisterNUICallback('getTranslations', function(_, cb)
    if not Lang or not Config or not Config.Language then cb({}) ; return end
    local raw = Lang[Config.Language]
    cb(raw and FlattenTranslations(raw) or {})
end)

-- Envío inicial al arrancar el resource
CreateThread(function()
    Wait(1000)
    SendTranslationsToNUI()
end)

AddEventHandler('origen:Client:OnPlayerLoaded', function()
    Wait(500)
    SendTranslationsToNUI()
end)
