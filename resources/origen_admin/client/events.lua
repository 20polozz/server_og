RegisterNUICallback("TriggerCallback", function(data, cb)
    FW_TriggerCallback(data.name, function(retval)
        if data.name == "origen_admin:server:getPlayerInfo" then 
            if not retval then
                return cb(nil)
            end
            local vehicleHash = false -- vehicle model should be excepted as a hash
            for i = 1, #retval.vehicles do
                if tonumber(retval.vehicles[i].label) ~= nil then 
                    vehicleHash = true
                end

                if vehicleHash then 
                    retval.vehicles[i].label = GetLabelText(GetDisplayNameFromVehicleModel(tonumber(retval.vehicles[i].label)))
                end
            end
        end
        cb(retval)
    end, data)
end)

RegisterNUICallback("sendEvent", function(data, cb)
    local args = {}
    if data.data then 
        for k, v in pairs(data.data) do
            table.insert(args, v)
        end
    end
    if data.side == "client" then 
        TriggerEvent(data.event, table.unpack(args))
        cb("ok")
        return
    end
    TriggerServerEvent(data.event, table.unpack(args))
    cb("ok")
end)