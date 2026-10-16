Framework.GetPlayerIdentifier = function()
    local identifier = nil
    if Config.Framework == 'qb-core' then 
        identifier = Framework.Functions.GetPlayerData().citizenid
    elseif Config.Framework == 'esx' then 
        identifier = Framework.GetPlayerData().identifier
    end

    return identifier
end

Framework.GetPlayerJob = function()
    if Config.Framework == 'qb-core' then 
        return Framework.Functions.GetPlayerData().job.name
    elseif Config.Framework == 'esx' then 
        return Framework.GetPlayerData().job.name
    end
end

Framework.GetPlayerJobGroup = function()
    if Config.Framework == 'qb-core' then 
        return Framework.Functions.GetPlayerData().job.grade.level
    elseif Config.Framework == 'esx' then 
        return Framework.GetPlayerData().job.grade
    end
end

Framework.GetPlayerGang = function()
    return 'none'
end

Framework.GetPlayerGangGrade = function()
    return 0
end