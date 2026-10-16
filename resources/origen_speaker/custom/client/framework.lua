Custom.GetIdentifier = function()
    local identifier = nil
    if Config.Framework == 'qb-core' then 
        identifier = Framework.Functions.GetPlayerData()?.citizenid
    elseif Config.Framework == 'qbx_core' then 
        identifier = exports.qbx_core:GetPlayerData()?.citizenid
    elseif Config.Framework == 'esx' then 
        identifier = Framework.GetPlayerData()?.identifier
    end

    return identifier
end

Custom.GetJob = function()
    local job = nil
    if Config.Framework == 'qb-core' then 
        job = Framework.Functions.GetPlayerData()?.job
    elseif Config.Framework == 'qbx_core' then 
        job = exports.qbx_core:GetPlayerData()?.job
    elseif Config.Framework == 'esx' then 
        local playerData = Framework.GetPlayerData()
        job = {
            name = playerData.job.name,
            grade = {
                name = playerData.job.grade_name,
                level = playerData.job.grade,
            }
        }
    end

    return job
end