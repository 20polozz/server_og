RegisterNetEvent("origen_police:client:OnFederalJoin", function()
    -- Event that is triggered when the player joins the federal prison
end)

RegisterNetEvent("origen_police:client:OnFederalLeave", function()
    -- Event that is triggered when the player leaves the federal prison
end)

RegisterNetEvent("origen_police:client:sendCitizenToFederal", function(targetId, time, dangerous)
    -- Event that is triggered when the agent sends a player to the federal prison
    if Config.OwnPrisionSystem and GetResourceState('rcore_prison') == 'started' then
        exports['rcore_prison']:Jail(targetId, time)
    end
end)

-- THE ABOVE FUNCTIONS ONLY WORK IF Config.OwnPrisionSystem IS SET TO TRUE IN config/federal.lua

function SpawnInJail(PlayerData)
    -- Your code
end

function setPrision(minutes, danger)
    -- Your code
end