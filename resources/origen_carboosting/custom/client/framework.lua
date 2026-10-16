Framework._GetPlayerData = function()
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx_core' then
        return Framework.Functions.GetPlayerData()
    elseif Config.Framework == 'esx' then 
        return Framework.GetPlayerData()
    end
end

Framework.GetIdentifier = function()
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx_core' then
        return Framework.Functions.GetPlayerData().citizenid
    elseif Config.Framework == 'esx' then 
        return Framework.GetPlayerData().identifier
    end
end