Custom = {}
Config = {}
Framework = {}
Internal = {}
Utils = {}

local isServer = IsDuplicityVersion()
local resource_name = GetCurrentResourceName()

function debugger(...)
    if Config.Debug then print ('[^6DEBUG^0]', ...) end
end

local resourceCategories = {
    framework = {
        'qbx_core',
        'qb-core',
        'es_extended'
    },
    keysystem = {
        'esx_vehiclelock',
        'qbx_vehiclekeys',
        'qb-vehiclekeys',
        'qs-vehiclekeys',
        'wasabi_carlock',
    },
    weather = {
        'Renewed-Weathersync',
        'qb-weathersync',
        'cd_easytime',
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

activeResources.framework = activeResources.framework == 'es_extended' and 'esx' or activeResources.framework == 'qb-core' and 'qb-core' or activeResources.framework
activeResources.weather = activeResources.weather or '^3No weather resource found'
activeResources.keysystem = activeResources.keysystem or '^3No keysystem resource found^0'
Config.Framework = activeResources.framework
Config.KeySystem = activeResources.keysystem
Config.Weather = activeResources.weather

local function GetFrameworkObject()
    if Config.Framework == 'esx' then
        return exports['es_extended']:getSharedObject()
    elseif Config.Framework == 'qb-core' then
        return exports["qb-core"]:GetCoreObject()
    elseif Config.Framework == 'qbx_core' then
        return exports["qb-core"]:GetCoreObject()
    end
    return nil
end

local frameworkEvents = {
    ['qb-core'] = {
        ['load'] = 'QBCore:Client:OnPlayerLoaded',
        ['unload'] = 'QBCore:Client:OnPlayerUnload',
       ['jobUpdate'] = 'QBCore:Client:OnJobUpdate',
    },
    ['qbx_core'] = {
        ['load'] = 'QBCore:Client:OnPlayerLoaded',
        ['unload'] = 'QBCore:Client:OnPlayerUnload',
        ['jobUpdate'] = 'QBCore:Client:OnJobUpdate',
    },
    ['esx'] = {
        ['load'] = 'esx:playerLoaded',
        ['unload'] = 'esx:playerLogout',
        ['jobUpdate'] = 'esx:setJob',
    },
}

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

    local function onPlayerLoaded()
        TriggerEvent('origen_garages:client:onPlayerLoad')
    end

    local function onPlayerUnload()
        TriggerEvent('origen_garages:client:onPlayerUnload')
    end

    local function onJobUpdate(job)
        TriggerEvent('origen_garages:client:onJobUpdate', job)
    end
    
    local eventName = frameworkEvents[Config.Framework]['load']
    local unloadEventName = frameworkEvents[Config.Framework]['unload']
    local jobUpdateEventName = frameworkEvents[Config.Framework]['jobUpdate']
    
    if eventName then RegisterNetEvent(eventName, onPlayerLoaded) end
    if unloadEventName then RegisterNetEvent(unloadEventName, onPlayerUnload) end
    if jobUpdateEventName then RegisterNetEvent(jobUpdateEventName, onJobUpdate) end

    RegisterNetEvent('origen_garages:client:notify', function(message, type, duration)
        Custom.Notify(message, type, duration)
    end)
end

local Translations = {}

local function loadLocaleFile(key)
    local file = LoadResourceFile(cache.resource, ('locales/%s.json'):format(key)) or LoadResourceFile(cache.resource, 'locales/en.json')

    if not file then
        debugger('Locale file not found for language: ' .. key)
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
    local lstr = Translations['game'][str]

    if lstr then
        if ... then
            return lstr and lstr:format(...)
        end

        return lstr
    end

    return str
end

function getLocale(type)
    return Translations[type]
end

__indexFurniture = {}

CreateThread(function()
    while not Config.Language do
        Wait(1000)
    end
    local table = lib.table
    local locales = loadLocaleFile(Config.Language)
    for category, translations in pairs(locales) do
        Translations[category] = {}
        for id, translation in pairs(translations) do
            Translations[category][id] = translation
        end
    end
end)

CreateThread(function()
    for _, category in ipairs(Config.Furniture) do
        for _, item in ipairs(category.items) do
            __indexFurniture[item.model] = item
        end
    end
end)