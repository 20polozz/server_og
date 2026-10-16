Internal.isPlayerLoaded = function()
    local ActiveFramework = Config.Framework
    if ActiveFramework == 'qb-core' or ActiveFramework == 'qbx_core' then 
        local PlayerData = Framework.Functions.GetPlayerData()
        if PlayerData and PlayerData.citizenid then
            return true
        end
    elseif ActiveFramework == 'esx' then
        local PlayerData = Framework.GetPlayerData()
        if PlayerData and PlayerData.identifier then
            return true
        end
    end
    return false
end

Internal.GetPlayerIdentifier = function()
    local identifier = nil
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx_core' then 
        identifier = Framework.Functions.GetPlayerData().citizenid
    elseif Config.Framework == 'esx' then 
        identifier = Framework.GetPlayerData().identifier
    end

    return identifier
end