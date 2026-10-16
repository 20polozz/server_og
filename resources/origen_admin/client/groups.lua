RegisterNetEvent('origen_admin:client:syncGroups', function(groups)
    
    -- Update Config.Permissions
    for k, v in pairs(groups) do
        Config.Permissions[k] = v.permissions
    end

    -- Update HighPermissions logic
    local groupsWithPermissions = {}
    for group, permissions in pairs(Config.Permissions) do
        if type(permissions) == "table" then
            if table.concat(permissions, ","):find("all") then
                table.insert(groupsWithPermissions, { group = group, count = math.huge })
            else
                local count = #permissions
                table.insert(groupsWithPermissions, { group = group, count = count })
            end
        end
    end
    table.sort(groupsWithPermissions, function(a, b)
        return a.count > b.count
    end)
    
    Config.HighPermissions = {}
    for _, groupInfo in ipairs(groupsWithPermissions) do
        table.insert(Config.HighPermissions, groupInfo.group)
    end

    -- Refresh Admin Status if menu is open or just generally
    -- If we are an admin, this might change what we see
    if isAdmin and AdminGroup then
        -- Ideally we should refresh the UI if it's open, but for now we just update key values
        -- Use the existing event to refresh UI if needed
        -- TriggerEvent("origen_admin:client:openNewAdminPanel", OnlineUsers, AdminGroup) -- This might be too aggressive if menu is closed
    end
end)

-- NUI Callbacks
RegisterNUICallback('origen_admin:server:getGroups', function(data, cb)
    FW_TriggerCallback('origen_admin:server:getGroups', function(groups)
        cb(groups)
    end)
end)

RegisterNUICallback('origen_admin:server:getAvailablePermissions', function(data, cb)
    FW_TriggerCallback('origen_admin:server:getAvailablePermissions', function(perms)
        cb(perms)
    end)
end)

RegisterNUICallback('origen_admin:server:createGroup', function(data, cb)
    TriggerServerEvent('origen_admin:server:createGroup', data)
    cb('ok')
end)

RegisterNUICallback('origen_admin:server:updateGroup', function(data, cb)
    TriggerServerEvent('origen_admin:server:updateGroup', data)
    cb('ok')
end)

RegisterNUICallback('origen_admin:server:deleteGroup', function(data, cb)
    TriggerServerEvent('origen_admin:server:deleteGroup', data)
    cb('ok')
end)

RegisterNUICallback('origen_admin:server:getAllStaff', function(data, cb)
    FW_TriggerCallback('origen_admin:server:getAllStaff', function(staff)
        cb(staff)
    end)
end)

RegisterNUICallback('origen_admin:server:getStaffHours', function(data, cb)
    FW_TriggerCallback('origen_admin:server:getStaffHours', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('origen_admin:server:getStaffHoursHistory', function(data, cb)
    FW_TriggerCallback('origen_admin:server:getStaffHoursHistory', function(result)
        cb(result)
    end, data)
end)
