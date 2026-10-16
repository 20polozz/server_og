Locales = {}
Translations = {}

function _U(key, ...)
    if not Translations[key] then
        return 'Translation [' .. Config.Locale .. '][' .. key .. '] not found'
    end

    local text = Translations[key]
    local args = {...}

    if #args > 0 then
        return string.format(text, table.unpack(args))
    end

    return text
end

function InitLocale()
    if not Locales[Config.Locale] then
        print('^1[origen_AlbumCards] Locale [' .. Config.Locale .. '] not found, using [es] as fallback^0')
        Translations = Locales['es']
    else
        Translations = Locales[Config.Locale]
    end
end
