RegisterNUICallback("GetBans", function(data, cb)
    FW_TriggerCallback("origen_admin:server:getBans", function(retval)
        cb(retval) -- This is only in the first time the menu is opened, after that the client will receive reports from the server
    end)
end)

RegisterNetEvent("origen_admin:client:newBan", function(ban)
    -- Code for send the ban data to the NUI
end)