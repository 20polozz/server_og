Framework.GetPlayerIdentifier = function()
    local identifier = nil
    if Config.Framework == 'qb-core' then 
        identifier = Framework.Functions.GetPlayerData().citizenid
    elseif Config.Framework == 'esx' then 
        identifier = Framework.GetPlayerData().identifier
    end

    return identifier
end