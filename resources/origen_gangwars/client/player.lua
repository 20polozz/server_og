AddStateBagChangeHandler('gangwars_profile', ('player:%s'):format(cache.serverId), function(bagName, key, value)
    debugger('Received new profile', json.encode(value))
    Nui.UpdateProfile(value)
end)

AddStateBagChangeHandler('gangwars_stats', ('player:%s'):format(cache.serverId), function(bagName, key, value)
    debugger('Received new stats', json.encode(value))
    Nui.UpdateStats(value)
end)

AddStateBagChangeHandler('gangwars_friends', ('player:%s'):format(cache.serverId), function(bagName, key, value)
    debugger('Received new friends', json.encode(value))
    Nui.UpdateFriends(value)
end)

AddStateBagChangeHandler('gangwars_missions', ('player:%s'):format(cache.serverId), function(bagName, key, value)
    debugger('Received new missions', json.encode(value))
    Nui.UpdateMissions(value)
end) 

AddStateBagChangeHandler('gangwars_team', ('player:%s'):format(cache.serverId), function(bagName, key, value)
    debugger('Received new team members', json.encode(value, { indent = true }))
    Nui.UpdateTeamMembers(value)
end) 

AddStateBagChangeHandler('Missions_Times', 'global', function(bagName, key, value)
    debugger('Received new missions times', json.encode(value))
    Nui.UpdateMissionTime(value)
end)