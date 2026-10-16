Custom = {}
Framework = {}
Config = {}

local isServer = IsDuplicityVersion()

local resourceCategories = {
    framework = {
        'qb-core',
        'es_extended'
    },
    lockpickSystem = {
        'qb-lockpick',
        'lockpick',
        't3_lockpick'
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

activeResources.framework = activeResources.framework == 'es_extended' and 'esx' or activeResources.framework
activeResources.framework = activeResources.framework or '^1No framework resource found'
activeResources.lockpickSystem = activeResources.lockpickSystem or '^3No lockpick resource found^0'

Config.Framework = activeResources.framework
Config.LockpickSysstem = activeResources.lockpickSystem


local frameworkEvents = {
    ['qb-core'] = 'QBCore:Client:OnPlayerLoaded',
    ['esx'] = 'esx:playerLoaded',
}


local function GetFrameworkObject()
    if Config.Framework == 'esx' then
        return exports['es_extended']:getSharedObject()
    elseif Config.Framework == 'qb-core' then
        return exports["qb-core"]:GetCoreObject()
    elseif Config.Framework == 'custom' then
        return Custom.GetCoreObject()
    end
    return nil
end

if isServer then
    Framework = GetFrameworkObject()
else
    Framework = GetFrameworkObject()

    local function onPlayerLoaded()
        TriggerEvent('origen_doorlock:client:onPLayerLoad')
    end
    
    local eventName = frameworkEvents[Config.Framework]
    if eventName then
        RegisterNetEvent(eventName, onPlayerLoaded)
    end

end

function debugger(...)
    if Config.Debug then print ('[^6DEBUG DOORLOCK^0]', ...) end
end