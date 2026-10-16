Config = {}
Custom = {}
Internal = {}
Framework = {}
ContractOffers = {}

local isServer = IsDuplicityVersion()
local resource_name = GetCurrentResourceName()
local version = GetResourceMetadata(resource_name, 'version', 0) or '1.0.0'
local core = require 'config.custom_core'
local events = require 'config.custom_events'

local resourceCategories = {
    framework = {
        'qbx_core',
        'qb-core',
        'es_extended',
    },
    inventory = {
        'origen_inventory',
        'ak47_inventory',
        'ox_inventory',
        'qs-inventory',
        'codem-inventory',
        'ps-inventory',
        'tgiann-inventory',
        'qb-inventory',
        'core_inventory',
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

activeResources.framework = activeResources.framework == 'es_extended' and 'esx' or (core.useCustomCore and 'custom' or activeResources.framework)
activeResources.framework = activeResources.framework or 'standalone'
activeResources.inventory = activeResources.inventory or 'standalone'

Config.Framework = activeResources.framework
Config.Inventory = activeResources.inventory

if Config.Inventory == 'qb-inventory' then
    local inventory = GetResourceMetadata('qb-inventory', 'version', 0)
    if inventory ~= nil then
        inventory = tonumber(string.match(inventory, "%d+%.?%d*"))
        if tonumber(inventory) >= 2.0 then
            Config.Inventory = 'new-qb-inventory'
        end
    end
elseif Config.Inventory == 'ps-inventory' then
    local inventory = GetResourceMetadata('ps-inventory', 'version', 0)
    if inventory ~= nil then
        inventory = tonumber(string.match(inventory, "%d+%.?%d*"))
        if tonumber(inventory) >= 1.5 then
            Config.Inventory = 'new-ps-inventory'
        end
    end
end

local frameworkEvents = {
    ['qb-core'] = {
        ['load'] = 'QBCore:Client:OnPlayerLoaded',
        ['unload'] = 'QBCore:Client:OnPlayerUnload',
        ['jobUpdate'] = 'QBCore:Client:OnJobUpdate',
        ['dutyUpdate'] = 'QBCore:Client:SetDuty',
    },
    ['qbx_core'] = {
        ['load'] = 'QBCore:Client:OnPlayerLoaded',
        ['unload'] = 'QBCore:Client:OnPlayerUnload',
        ['jobUpdate'] = 'QBCore:Client:OnJobUpdate',
        ['dutyUpdate'] = 'QBCore:Client:SetDuty',
    },
    ['esx'] = {
        ['load'] = 'esx:playerLoaded',
        ['unload'] = 'esx:playerLogout',
        ['jobUpdate'] = 'esx:setJob',
        ['dutyUpdate'] = 'esx:setJob',
    },
    ['custom'] = {
        ['load'] = events.load,
        ['unload'] = events.unload,
        ['jobUpdate'] = events.jobUpdate,
        ['dutyUpdate'] = events.dutyUpdate,
    },
}

local function GetFrameworkObject()
    if Config.Framework == 'esx' then
        return exports['es_extended']:getSharedObject()
    elseif Config.Framework == 'qb-core' or Config.Framework == 'qbx_core' then
        return exports["qb-core"]:GetCoreObject()
    elseif Config.Framework == 'custom' then
        return core.GetCustomCoreObject()
    end

    return nil
end

function debugger(...)
    if Config.Debug then print ('[^6DEBUG^0]', ...) end
end

if isServer then
    Framework = GetFrameworkObject()
    
else
    Framework = GetFrameworkObject()

    local function registerNetEvent(eventName, callback)
        local event = events[eventName] or frameworkEvents[Config.Framework][eventName]
        if event then RegisterNetEvent(event, callback) end
    end
    
    local function onPlayerLoaded(...)
        TriggerEvent('origen_boosting:client:onPlayerLoaded', ...)
    end

    local function onPlayerUnload()
        TriggerEvent('origen_boosting:client:onPlayerUnload')
    end
    
    local function onJobUpdate(jobInfo)
        TriggerEvent('origen_boosting:client:onJobUpdate', jobInfo)
    end

    local function onDutyUpdate(onduty)
        TriggerEvent('origen_boosting:client:onDutyUpdate', onduty)
    end
    
    registerNetEvent('load', onPlayerLoaded)
    registerNetEvent('unload', onPlayerUnload)
    registerNetEvent('jobUpdate', onJobUpdate)
    registerNetEvent('dutyUpdate', onDutyUpdate)

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
end

-- Locales (By Trend)

Config.Translations = {}

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
    local lstr = Config.Translations[str]

    if lstr then
        if ... then
            return lstr and lstr:format(...)
        end

        return lstr
    end

    return str
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
end)