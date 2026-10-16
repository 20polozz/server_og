Config = {}
Custom = {}
BanksRegistered = false

function debugger(...)
    if Config.Debug then print ('[^6DEBUG^0]', ...) end
end

local resourceCategories = {
    Framework = {'qbx_core', 'qb-core', 'es_extended'},
    Inventory = {'origen_inventory', 'qb-inventory', 'ox_inventory'}
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

Config.Framework = activeResources.Framework
Config.Inventory = activeResources.Inventory

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

Framework = GetFrameworkObject()
Internal = {}