Custom.GetPlayerIdentifier = function()
    local identifier = nil
    if Config.Framework == 'qb-core' then 
        identifier = Framework.Functions.GetPlayerData().citizenid
    elseif Config.Framework == 'esx' then 
        identifier = Framework.GetPlayerData().identifier
    end

    return identifier
end

Custom.GetJob = function()
    if Config.Framework == 'qb-core' then
        local PlayerData = Framework.Functions.GetPlayerData()
        if not PlayerData or not PlayerData.job then 
            return { name = 'unemployed', grade = 0 } 
        end
        return {
            name = PlayerData.job.name,
            grade = PlayerData.job.grade.level,
        }
    elseif Config.Framework == 'esx' then
        local PlayerData = Framework.GetPlayerData()
        if not PlayerData or not PlayerData.job then 
            return { name = 'unemployed', grade = 0 } 
        end
        return {
            name = PlayerData.job.name,
            grade = PlayerData.job.grade,
        }
    else
        return {
            name = 'unemployed',
            grade = 0,
        }
    end
end

Framework.GetGender = function()
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx_core' then 
        local PlayerData = Framework.Functions.GetPlayerData()
        return PlayerData.charinfo.gender
    elseif Config.Framework == 'esx' then 
        local PlayerData = Framework.GetPlayerData()
        return PlayerData.sex == "m" and 0 or 1
    end
end

Framework.isPlayerLoaded = function()
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx_core' then 
        return Framework.Functions.GetPlayerData().citizenid ~= nil
    elseif Config.Framework == 'esx' then 
        return Framework.GetPlayerData().identifier ~= nil
    end
    return false
end