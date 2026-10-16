local localeLoaded = false
local loadedLanguage = nil

local function refreshLocaleLanguage()
    if not (lib and lib.locale) then
        return
    end

    local language = Config and Config.Language or nil

    if localeLoaded and loadedLanguage == language then
        return
    end

    lib.locale(language)
    localeLoaded = true
    loadedLanguage = language
end

refreshLocaleLanguage()

local function translate(key, ...)
    refreshLocaleLanguage()
    local ok, value = pcall(locale, key, ...)
    if ok and type(value) == 'string' then
        return value
    end
    return key
end

function T(key, ...)
    return translate(key, ...)
end

local function buildSectionProxy(prefix)
    return setmetatable({}, {
        __index = function(_, entry)
            local key = prefix and (prefix .. '.' .. entry) or entry
            local value = translate(key)
            if value == key then
                return buildSectionProxy(key)
            end
            return value
        end
    })
end

Lang = setmetatable({}, {
    __index = function()
        return buildSectionProxy(nil)
    end
})

local function loadLocaleFile(language)
    local fileName = ('locales/%s.json'):format(language or 'en')
    local raw = LoadResourceFile(GetCurrentResourceName(), fileName)
    if not raw then
        return nil
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        return nil
    end

    return decoded
end

local function flattenTable(source, out, prefix)
    for key, value in pairs(source) do
        local flatKey = prefix and (prefix .. '.' .. key) or key
        if type(value) == 'table' then
            flattenTable(value, out, flatKey)
        elseif type(value) == 'string' then
            out[flatKey] = value
        end
    end
end

function GetNuiTranslations()
    local language = (Config and Config.Language) or 'en'
    local localeData = loadLocaleFile(language) or loadLocaleFile('en') or {}
    local translations = {}

    if type(localeData.meta) == 'table' and type(localeData.meta.locale) == 'string' then
        translations['meta.locale'] = localeData.meta.locale
    end

    if type(localeData.nui) == 'table' then
        flattenTable(localeData.nui, translations, nil)
    end

    return translations
end
