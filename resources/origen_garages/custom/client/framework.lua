Framework.GetPlayerIdentifier = function()
    local identifier = nil
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx_core' then 
        identifier = Framework.Functions.GetPlayerData().citizenid
    elseif Config.Framework == 'esx' then 
        identifier = Framework.GetPlayerData().identifier
    end

    return identifier
end

Framework.GetPlayerJob = function()
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx_core' then 
        local playerData = Framework.Functions.GetPlayerData()
        return {
            name = playerData.job.name,
            grade = playerData.job.grade.level,
        }
    elseif Config.Framework == 'esx' then 
        local playerData = Framework.GetPlayerData()
        return {
            name = playerData.job.name,
            grade = playerData.job.grade,
        }
    else 
        return {
            name = 'unknown',
            grade = 0,
        }
    end
end

Framework.GetPlayerGang = function()
    return {
        name = 'unknown',
        grade = 0,
    }
end

Framework.isPlayerLoaded = function()
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx_core' then 
        return Framework.Functions.GetPlayerData().citizenid ~= nil
    elseif Config.Framework == 'esx' then 
        return Framework.GetPlayerData().identifier ~= nil
    end
    return false
end