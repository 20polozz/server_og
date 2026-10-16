Custom = {}
Framework = {}
Config = {}
Internal = {}

local isServer = IsDuplicityVersion()
local resource_name = GetCurrentResourceName()
local version = GetResourceMetadata(resource_name, 'version', 0) or '1.0.0'

local resourceCategories = {
    framework = {
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

activeResources.framework = activeResources.framework == 'es_extended' and 'esx' or activeResources.framework
activeResources.framework = activeResources.framework or '^1No framework resource found'

Config.Framework = activeResources.framework

local frameworkEvents = {
    ['qb-core'] = {
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

local function GetFrameworkObject()
    if Config.Framework == 'esx' then
        return exports['es_extended']:getSharedObject()
    elseif Config.Framework == 'qb-core' then
        return exports["qb-core"]:GetCoreObject()
    elseif Config.Framework == 'custom' then
        return core.GetCustomCoreObject()
    end

    return nil
end

function debugger(...)
    if Config.Debug then print('[^6DEBUG^0]', ...) end
end

Framework = GetFrameworkObject()
if isServer then

else
    local function onPlayerLoaded()
        TriggerEvent('origen_clothing:client:onPlayerLoad')
    end

    local function onJobUpdate(job)
        TriggerEvent('origen_clothing:client:onJobUpdate', job)
    end
    
    local eventName = frameworkEvents[Config.Framework]['load']
    local jobUpdateEventName = frameworkEvents[Config.Framework]['jobUpdate']
    
    if eventName then RegisterNetEvent(eventName, onPlayerLoaded) end
    if jobUpdateEventName then RegisterNetEvent(jobUpdateEventName, onJobUpdate) end

    RegisterNetEvent('origen_clothing:client:notify', function(text, type, length)
        Custom.Notify(text, type, length)
    end)
end


-- Translations
local Translations = {}

local function loadLocaleFile(key)
    local file = LoadResourceFile(cache.resource, ('locales/%s.json'):format(key)) or LoadResourceFile(cache.resource, 'locales/en.json')

    if not file then
        debugger('Locale file not found for language: ' .. key)
    end

    return file and json.decode(file) or {}
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

function getTranslations()
    return Translations
end

CreateThread(function()
    while not Config.Language do
        Wait(1000)
    end
    local table = lib.table
    local locales = loadLocaleFile(Config.Language)
    for id, translation in pairs(locales) do
        Translations[id] = translation
    end
end)