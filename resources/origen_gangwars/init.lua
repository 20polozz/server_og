Config = {}
Custom = {}
Internal = {}
Framework = {}

local isServer = IsDuplicityVersion()
local resource_name = GetCurrentResourceName()
local core = require 'config.custom_core'

local resourceCategories = {
    framework = {
        'qbx_core',
        'qb-core',
        'es_extended',
    },
    weather = {
        'Renewed-Weathersync',
        'qb-weathersync',
        'cd_easytime',
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
    },

    ambulance = {
        'origen_ambulancejob',
        'ak47_ambulancejob',
        'ars_ambulancejob',
        'wasabi_ambulance',
        'esx_ambulancejob',
        'osp_ambulance',
        'qbx_medical',
        'qb-ambulancejob',
    },
    gangsystem = {
        'origen_ilegalv2',
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
activeResources.weather = activeResources.weather or 'standalone'
activeResources.ambulance = activeResources.ambulance or 'standalone'
activeResources.gangsystem = activeResources.gangsystem or 'standalone'

Config.Framework = activeResources.framework
Config.Inventory = activeResources.inventory
Config.Weather = activeResources.weather
Config.Ambulance = activeResources.ambulance
Config.GangSystem = activeResources.gangsystem

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
    },
    ['qbx_core'] = {
        ['load'] = 'QBCore:Client:OnPlayerLoaded',
        ['unload'] = 'QBCore:Client:OnPlayerUnload',
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
    
    local eventName = frameworkEvents[Config.Framework]['unload']
    
    local function onPlayerUnload(src)
        TriggerEvent('origen_gangwars:server:onPLayerUnload', src)
    end

    if eventName then
        RegisterNetEvent(eventName, onPlayerUnload)
    end

    Internal.RevivePlayer = function(source)
        local src = tonumber(source)
    
        if Config.Ambulance == 'qb-ambulancejob' then
            TriggerClientEvent('hospital:client:Revive', src)
        elseif Config.Ambulance == 'qbx_medical' then
            TriggerClientEvent('qbx_medical:client:playerRevived', src)
        elseif Config.Ambulance == 'ak47_ambulancejob' then
            TriggerClientEvent('ak47_ambulancejob:revive', src)
        elseif Config.Ambulance == 'origen_ambulancejob' or Config.Ambulance == 'ars_ambulancejob' then
            TriggerClientEvent('origen_ambulancejob:healPlayer', src, {revive = true})
            TriggerClientEvent('origen_ambulancejob:healPlayer', src, {heal = true})
        elseif Config.Ambulance == 'wasabi_ambulance' then
            exports.wasabi_ambulance:RevivePlayer(src)
        elseif Config.Ambulance == 'esx_ambulancejob' then
            TriggerClientEvent('esx_ambulancejob:revive', src)
        elseif Config.Ambulance == 'osp_ambulance' then
            TriggerClientEvent('hospital:client:Revive', src)
        else
            Custom.RevivePLayer(src)
        end
    end

    -- GetScriptVersion()
else
    Framework = GetFrameworkObject()

    PlayerPed = cache.ped

    lib.onCache('ped', function(value)
        PlayerPed = value
    end)

    local function onPlayerLoaded()
        TriggerEvent('origen_gangwars:client:onPLayerLoad')
    end
    
    local eventName = frameworkEvents[Config.Framework]['load']
    if eventName then
        RegisterNetEvent(eventName, onPlayerLoaded)
    end

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

    Internal.DisableWeatherSync = function()
        if Config.Weather == 'qb-weathersync' then
            TriggerEvent('qb-weathersync:client:DisableSync')
        elseif Config.Weather == 'cd_easytime' then
            TriggerEvent('cd_easytime:PauseSync', true)
        elseif Config.Weather == 'Renewed-Weathersync' then
            LocalPlayer.state.syncWeather = false
        else
            Custom.DisableWeatherSync()
        end
    end

    Internal.EnableWeatherSync = function()
        if Config.Weather == 'qb-weathersync' then
            TriggerEvent('qb-weathersync:client:EnableSync')
        elseif Config.Weather == 'cd_easytime' then
            TriggerEvent('cd_easytime:PauseSync', false)
        elseif Config.Weather == 'Renewed-Weathersync' then
            LocalPlayer.state.syncWeather = true
        else
            Custom.EnableWeatherSync()
        end
    end
end

-- Locales

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