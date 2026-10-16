local sendedData = nil

RegisterNuiCallback('save_profile', function(data, cb)
    local response = lib.callback.await('origen_gangwars:server:saveProfileData', false, {
        image = data.image,
        banner = data.banner,
    })
    cb(response)
end)

RegisterNuiCallback('get_profile_data', function(data, cb)
    if not sendedData then
        local response = lib.callback.await('origen_gangwars:server:getProfileData', false)

        if response.rewards and next(response.rewards) then
            for level, value in pairs(response.rewards) do
                level = tonumber(level)
                if Config.Rewards[level] then
                    Config.Rewards[level].free.claimed = value.free or false
                    Config.Rewards[level].premium.claimed = value.premium or false  
                end
            end
        end
        
        local missions = {}

        if response.missions then
            for i = 1, #response.missions do
                local mission = response.missions[i]
                if Config.Missions[mission.id] then
                    missions[i] = {
                        title = Config.Missions[mission.id].title,
                        description = Config.Missions[mission.id].description,
                        progress = tonumber(mission.progress),
                        type = mission.type,
                    }
                end
            end
        end

        response.missions = missions

        sendedData = response
    end

    cb({
        data = sendedData,
        rewards = Config.Rewards
    })

end)

