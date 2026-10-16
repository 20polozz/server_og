Custom = {}
Framework = {}
Config = {}
Internal = {}
Translations = {}

-- Locales

local function loadLocaleFile(key)
    local file = LoadResourceFile(cache.resource, ('locales/%s.json'):format(key)) or LoadResourceFile(cache.resource, 'locales/en.json')

    if not file then
        debugger.warn('Locale file not found for language: ' .. key)
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
    local lstr = Translations[str]

    if lstr then
        if ... then
            return lstr and lstr:format(...)
        end

        return lstr
    end

    return str
end

CreateThread(function()
    Wait(1000)
    while not Config.Language do Wait(100) end

    local locales = loadLocaleFile(Config.Language)

    lib.table.wipe(Translations)

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

        Translations[k] = v
    end
end)

-- 

local isServer = IsDuplicityVersion()

local core = require 'config.custom_core'

local resourceCategories = {
    framework = {
        'qbx_core',
        'qb-core',
        'es_extended',
    }
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

activeResources.framework = activeResources.framework == 'es_extended' and 'esx' 
                            or (core.useCustomCore and 'custom' or activeResources.framework or 'standalone')

Config.Framework = activeResources.framework

local frameworkEvents = {
    ['qb-core'] = {
        ['load'] = 'QBCore:Client:OnPlayerLoaded',
        ['unload'] = 'QBCore:Server:OnPlayerUnload',
    },
    ['qbx_core'] = {
        ['load'] = 'QBCore:Client:OnPlayerLoaded',
        ['unload'] = 'QBCore:Server:OnPlayerUnload',
    },
    ['esx'] = {
        ['load'] = 'esx:playerLoaded',
        ['unload'] = 'esx:playerLogout',
    },
    ['custom'] = {
        ['load'] = core.events.load,
        ['unload'] = core.events.unload,
    },
}

local function GetFrameworkObject()
    if Config.Framework == 'esx' then
        return exports['es_extended']:getSharedObject()
    elseif Config.Framework == 'qbx_core' then
        return exports["qb-core"]:GetCoreObject()
    elseif Config.Framework == 'qb-core' then
        return exports["qb-core"]:GetCoreObject()
    elseif Config.Framework == 'custom' then
        return core.GetCustomCoreObject()
    end

    return nil
end

debugger = {}

function debugger.error(message, ...)
    if Config.Debug then print ('[^1DEBUG ERROR^0]', message, ...) end
end

function debugger.warn(message, ...)
    if Config.Debug then print ('[^3DEBUG WARNING^0]', message, ...) end
end

function debugger.info(message, ...)
    if Config.Debug then print ('[^5DEBUG INFO^0]', message, ...) end
end

if isServer then
    Framework = GetFrameworkObject()

    SetConvar('resources_useSystemChat', 'false')

    local eventName = frameworkEvents[Config.Framework]
    
    local function onPlayerUnload(src)
        TriggerEvent('origen_chat:server:onPLayerUnload', src)
    end

    if eventName then
        AddEventHandler(eventName['unload'], onPlayerUnload)
    end

    Internal.Notify = function(src, text, type, length)
        TriggerClientEvent('origen_chat:client:notify', src, text, type, length)
    end
else
    Framework = GetFrameworkObject()

    local function onPlayerLoaded()
        TriggerEvent('origen_chat:client:onPLayerLoad')
    end
    
    local eventName = frameworkEvents[Config.Framework]
    
    if eventName then RegisterNetEvent(eventName['load'], onPlayerLoaded) end

    Internal.Notify = function(text, type, length)
        if Config.CustomNotify or Config.Framework == 'custom' then
            Custom.Notify(text, type, length)
        else
            if Config.Framework == 'qb-core' then
                Framework.Functions.Notify(text, type, length)
            elseif Config.Framework == 'esx' then
                Framework.ShowNotification(text, type, length)
            end
        end
    end

    RegisterNetEvent('origen_chat:client:notify', function(text, type, length)
        Internal.Notify(text, type, length)
    end)
end