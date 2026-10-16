--[[
    OPEN SOURCE FUNCTIONS FOR CUSTOM INTEGRATIONS
    These functions allow you to add custom checks, permissions, and interactions
    NOTE: These functions run on CLIENT SIDE - use callbacks for server data
    
    To enable permissions:
    1. Set Config.Permissions.enabled = true in open_config.lua
    2. Set Config.Permissions.framework = 'auto' (or 'qb', 'qbox', 'esx')
    3. Add allowedJobs = {"mechanic", "police"} to each prop in config.lua
    
    For ACE permissions:
    1. Set Config.Permissions.useAce = true
    2. Add acePermission = "ilegal.lift" to each prop in config.lua
]]

-- Detect framework (cached)
local detectedFramework = nil
local function getFramework()
    if detectedFramework then return detectedFramework end
    
    local fw = Config.Permissions and Config.Permissions.framework or 'auto'
    
    if fw == 'auto' then
        if GetResourceState('qbx_core') == 'started' then
            detectedFramework = 'qbox'
        elseif GetResourceState('qb-core') == 'started' then
            detectedFramework = 'qb'
        elseif GetResourceState('es_extended') == 'started' then
            detectedFramework = 'esx'
        else
            detectedFramework = 'standalone'
        end
    else
        detectedFramework = fw
    end
    
    return detectedFramework
end

-- Get player job name from framework
local function getPlayerJobName()
    local fw = getFramework()
    local jobName = nil
    
    -- Try statebag first (works across frameworks)
    if LocalPlayer and LocalPlayer.state then
        local sb = LocalPlayer.state
        if type(sb.job) == 'table' and sb.job.name then
            jobName = sb.job.name
        elseif type(sb.job) == 'string' then
            jobName = sb.job
        elseif type(sb.jobName) == 'string' then
            jobName = sb.jobName
        end
    end
    
    if jobName then return jobName:lower() end
    
    -- Framework-specific fallbacks
    if fw == 'qb' then
        local ok, pd = pcall(function() return exports['qb-core']:GetPlayerData() end)
        if not ok or not pd or not pd.job then
            local ok2, QBCore = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok2 and QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
                pd = QBCore.Functions.GetPlayerData()
            end
        end
        if pd and pd.job and pd.job.name then
            jobName = pd.job.name
        end
    elseif fw == 'qbox' then
        local ok, pd = pcall(function() return exports['qbx_core']:GetPlayerData() end)
        if not ok or not pd or not pd.job then
            local ok2, QBX = pcall(function() return exports['qbx_core']:GetCoreObject() end)
            if ok2 and QBX then
                if QBX.PlayerData then pd = QBX.PlayerData end
                if not pd and QBX.Functions and QBX.Functions.GetPlayerData then
                    pd = QBX.Functions.GetPlayerData()
                end
            end
        end
        if pd and pd.job and pd.job.name then
            jobName = pd.job.name
        end
    elseif fw == 'esx' then
        local ESX = rawget(_G, 'ESX')
        if not ESX then
            local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
            if ok then ESX = obj end
        end
        local pd = ESX and ((ESX.GetPlayerData and ESX:GetPlayerData()) or ESX.PlayerData)
        if pd and pd.job and pd.job.name then
            jobName = pd.job.name
        end
    end
    
    return jobName and jobName:lower() or nil
end

-- Check if player has ACE permission
local function hasAcePermission(permission)
    return IsPlayerAceAllowed(PlayerId(), permission)
end

-- Get prop config by name
local function getPropConfig(propName)
    if not Config or not Config.Props then return nil end
    for _, prop in pairs(Config.Props) do
        if prop.name == propName then
            return prop
        end
    end
    return nil
end

--[[
    CanPlayerInteract - General interaction check
    Return false to prevent interaction entirely
]]
function CanPlayerInteract(propName, serverId)
    return true
end

--[[
    HasJobAccess - Job/permission based access
    Uses Config.Permissions settings
]]
function HasJobAccess(propName, serverId)
    -- If permissions system is disabled, allow all
    if not Config.Permissions or not Config.Permissions.enabled then
        return true
    end
    
    local propConfig = getPropConfig(propName)
    if not propConfig then return true end
    
    -- Check ACE permissions if enabled
    if Config.Permissions.useAce and propConfig.acePermission then
        return hasAcePermission(propConfig.acePermission)
    end
    
    -- Check job restrictions
    if not propConfig.allowedJobs or #propConfig.allowedJobs == 0 then
        return true -- No job restriction on this prop
    end
    
    local playerJob = getPlayerJobName()
    if not playerJob then return false end
    
    for _, allowedJob in ipairs(propConfig.allowedJobs) do
        if type(allowedJob) == 'string' and allowedJob:lower() == playerJob then
            return true
        end
    end
    
    return false
end

--[[
    GetCustomLabel - Modify the interaction label
    Return a custom string or defaultLabel
]]
function GetCustomLabel(propName, serverId, defaultLabel)
    return defaultLabel
end

--[[
    OnPropInteraction - Called when player interacts with a prop
    Use this for custom actions (notifications, events, etc)
]]
function OnPropInteraction(propName, serverId, propState)
    
end
