local PlayerManager = {
    Framework = Config.Framework
}

function PlayerManager:Get()
    if self.Framework == 'qb-core' or self.Framework == 'qbx_core' then
        return Framework.Functions.GetPlayerData()
    elseif self.Framework == 'es_extended' then
        return Framework.GetPlayerData()
    end
end

function Internal.IsPlayerLoaded()
    local playerData = PlayerManager:Get()
    if not playerData then return false end

    if PlayerManager.Framework == 'es_extended' then
        return playerData.identifier ~= nil and playerData.identifier ~= ''
    else
        return playerData.citizenid ~= nil and playerData.citizenid ~= ''
    end
end