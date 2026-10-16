Custom = {}
Framework = {}
Config = {}
Internal = {}


local isServer = IsDuplicityVersion()
local resource_name = GetCurrentResourceName()

local resourceCategories = {
    framework = {
        'qbx_core',
        'qb-core',
        'es_extended'
    },
}

local function checkResourceState(resource)
    return GetResourceState(resource) == 'starting' or GetResourceState(resource) == 'started'
end

local function findActiveResource(resourceList)
    for _, resource in ipairs(resourceList) do
        if checkResourceState(resource) then
            return resource
        end
    end
    return nil
end

local activeResources = {}
for category, resources in pairs(resourceCategories) do
    activeResources[category] = findActiveResource(resources)
end

activeResources.framework = activeResources.framework == 'es_extended' and 'esx' or activeResources.framework == 'qb-core' and 'qb-core' or activeResources.framework == 'qbx_core' and 'qbx' or activeResources.framework
Config.Framework = activeResources.framework

local function GetFrameworkObject()
    if Config.Framework == 'esx' then
        return exports['es_extended']:getSharedObject()
    elseif Config.Framework == 'qb-core' then
        return exports["qb-core"]:GetCoreObject()
    elseif Config.Framework == 'qbx' then
        return exports["qb-core"]:GetCoreObject()
    end
    return nil
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

if isServer then
    Framework = GetFrameworkObject()

    local function GetScriptVersion()
        PerformHttpRequest('https://raw.githubusercontent.com/ElOrigenCompanyES/ScriptsVersions/master/'..resource_name..'.txt', function(error, result, headers)
            if not result then 
                loadScript = true
                return
            end
            loadScript = true
        end, 'GET', '', {["Content-Type"]="application/json"})
    end

    GetScriptVersion()
else
    Framework = GetFrameworkObject()
end

--# DEBBUGER #--
Debug = {
    -- Colores para diferentes tipos de mensajes
    colors = {
        info = '^4[INFO]^7',      -- Azul
        success = '^2[SUCCESS]^7', -- Verde
        warning = '^3[WARNING]^7', -- Amarillo
        error = '^1[ERROR]^7',     -- Rojo
        debug = '^5[DEBUG]^7',     -- Magenta
        trace = '^6[TRACE]^7'      -- Cian
    },
    
    -- Función principal de logging
    log = function(debugType, force, ...)
        -- Si force no es booleano, significa que es parte del mensaje
        if type(force) ~= 'boolean' then
            -- Reordenar argumentos: force es en realidad el primer argumento del mensaje
            local args = {force, ...}
            force = false
            return Debug.log(debugType, force, table.unpack(args))
        end
        
        if not Config.Debug and not force then return end

        local color = Debug.colors[debugType] or Debug.colors.debug
        local args = {...}
        local message = ''
        
        for i, arg in ipairs(args) do
            if type(arg) == 'table' then
                message = message .. json.encode(arg)
            else
                message = message .. tostring(arg)
            end
            
            if i < #args then
                message = message .. ' '
            end
        end
        
        -- Agregar indicador [FORCED] si es un mensaje forzado
        local forceIndicator = force and ' ^9[FORCED]^7' or ''
        print(color .. forceIndicator .. ' ' .. message)
    end,
    
    -- Funciones específicas para cada tipo
    info = function(force, ...)
        if type(force) == 'boolean' then
            Debug.log('info', force, ...)
        else
            Debug.log('info', false, force, ...)
        end
    end,
    
    success = function(force, ...)
        if type(force) == 'boolean' then
            Debug.log('success', force, ...)
        else
            Debug.log('success', false, force, ...)
        end
    end,
    
    warning = function(force, ...)
        if type(force) == 'boolean' then
            Debug.log('warning', force, ...)
        else
            Debug.log('warning', false, force, ...)
        end
    end,
    
    error = function(force, ...)
        if type(force) == 'boolean' then
            Debug.log('error', force, ...)
        else
            Debug.log('error', false, force, ...)
        end
    end,
    
    debug = function(force, ...)
        if type(force) == 'boolean' then
            Debug.log('debug', force, ...)
        else
            Debug.log('debug', false, force, ...)
        end
    end,
    
    trace = function(force, ...)
        if type(force) == 'boolean' then
            Debug.log('trace', force, ...)
        else
            Debug.log('trace', false, force, ...)
        end
    end
}

--? TRANSLATIONS
Config.Translations = {}

local function loadLocaleFile(key)
    local file = LoadResourceFile(cache.resource, ('locales/%s.json'):format(key)) or LoadResourceFile(cache.resource, 'locales/en.json')

    if not file then
        Debug.error('Locale file not found for language: ' .. key)
    end

    return file and json.decode(file) or {}
end

local function flattenDict(source, target, prefix)
    for key, value in pairs(source) do
        local fullKey = prefix and (prefix .. '.' .. key) or key

        if type(value) == 'table' then
            flattenDict(value, target, fullKey)
        else
            target[fullKey] = value
        end
    end

    return target
end

function locale(str, ...)
    local lstr = Config.Translations[str]

    if lstr then
        if ... then
            local args = {...}
            if type(args[1]) == 'table' then
                for key, value in pairs(args[1]) do
                    lstr = lstr:gsub('{' .. key .. '}', tostring(value))
                end
                return lstr
            else
                return lstr:format(...)
            end
        end

        return lstr
    end

    return str
end

-- Función auxiliar para contar elementos en una tabla
local function tableCount(t)
    if not t or type(t) ~= 'table' then return 0 end
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

CreateThread(function()
    while not Config.Language do
        Wait(1000)
    end
    local table = lib.table
    local locales = loadLocaleFile(Config.Language)
    for k, v in pairs(flattenDict(locales, {})) do
        if type(v) == 'string' then
            for var in v:gmatch('${[%w%s%p]-}') do
                local locale = locales[var:sub(3, -2)]

                if locale then
                    locale = locale:gsub('%%', '%%%%')
                    v = v:gsub(var, locale)
                end
            end
        end

        
        Config.Translations[k] = v
    end

    if GetConvar('origen:marca', 'origen') == 'nacion' then
        Config.Translations['logs.payment_methods.xp'] = 'Farm XP'
        local sinPrecio = Config.Translations['errors.xp_price_not_configured']
        if sinPrecio then
            Config.Translations['errors.xp_price_not_configured'] = (sinPrecio:gsub('XP', 'Farm XP'))
        end
    end
end)

-- Agregar callback para obtener traducciones (solo en cliente)
if not isServer then
    -- Cache de traducciones para evitar múltiples cargas
    local translationsCache = {}
    
    lib.callback.register('origen_dealerships:getTranslations', function()
        local language = Config.Language or 'en'
        
        -- Si ya están en cache, devolverlas directamente
        if translationsCache[language] then
            return translationsCache[language]
        end
        
        -- Cargar y procesar traducciones
        local translations = loadLocaleFile(language)
        
        if not translations or not next(translations) then
            Debug.error('No translations found for language: ' .. language)
            return {}
        end
        
        -- Función auxiliar para aplanar las traducciones anidadas
        local function flattenTranslations(source, target, prefix)
            for key, value in pairs(source) do
                local fullKey = prefix and (prefix .. '.' .. key) or key
                
                if type(value) == 'table' then
                    flattenTranslations(value, target, fullKey)
                else
                    target[fullKey] = value
                end
            end
            return target
        end
        
        local flattenedTranslations = flattenTranslations(translations, {})
        
        -- Guardar en cache
        translationsCache[language] = flattenedTranslations
        
        Debug.debug('Translations loaded and cached for language:', language, 'Keys:', tableCount(flattenedTranslations))
        return flattenedTranslations
    end)
end
