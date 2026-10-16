Custom.GetPlayerJob = function()
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx_core' then 
        local playerData = Framework.Functions.GetPlayerData()
        return playerData.job
    elseif Config.Framework == 'esx' then 
        local playerData = Framework.GetPlayerData()
        return {
            name = playerData.job.name,
            grade = {
                name = playerData.job.grade_name,
                level = playerData.job.grade,
            }
        }
    else 
        return {
            name = 'unknown',
            grade = {
                name = 'unknown',
                level = 0,
            }
        }
    end
end
    