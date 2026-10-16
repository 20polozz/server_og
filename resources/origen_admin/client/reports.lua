RegisterNUICallback("SendReport", function(data, cb)
    TriggerServerEvent("origen_admin:server:sendReport", data.type, data.message)
    cb(true)
end)

RegisterNUICallback("SendReportMessage", function(data, cb)
    TriggerServerEvent("origen_admin:server:sendReportMessage", data.reportId, data.message)
    cb(true)
end)

RegisterNUICallback("UploadReportFile", function(data, cb)
    FW_TriggerCallback("origen_admin:server:getUploadConfig", function(result)
        cb(result)
    end)
end)

RegisterNUICallback("CloseReport", function(data, cb)
    TriggerServerEvent("origen_admin:server:deleteReport", data.reportId)
    cb(true)
end)

RegisterNUICallback("TakeReport", function(data, cb)
    TriggerServerEvent("origen_admin:server:acceptReport", data.reportId)
    cb(true)
end)

RegisterNUICallback("GoToPlayer", function(data, cb)
    TriggerServerEvent('origen_admin:server:goto', tonumber(data.playerId))
    cb(true)
end)

RegisterNUICallback("BringPlayer", function(data, cb)
    TriggerServerEvent('origen_admin:server:bring', tonumber(data.playerId))
    cb(true)
end)

RegisterNetEvent("origen_admin:client:newReport", function(report)
    ShowNotification("Se ha recibido un nuevo reporte.")
    SendNUIMessage({
        action = "newReport",
        report = report
    })
end)

RegisterNetEvent("origen_admin:client:reportUpdated", function(report)
    -- Only updates the NUI list; notifications are handled by dedicated events
    SendNUIMessage({
        action = "reportUpdated",
        report = report
    })
end)

RegisterNetEvent("origen_admin:client:playerReplied", function(playerName, reportId)
    ShowNotification("El jugador " .. tostring(playerName) .. " ha respondido al reporte #" .. tostring(reportId))
end)

RegisterNetEvent("origen_admin:client:setReports", function(reports)
    SendNUIMessage({
        action = "setReports",
        reports = reports
    })
end)

RegisterNUICallback("GetReports", function(data, cb)
    FW_TriggerCallback("origen_admin:server:getReports", function(retval)
        cb(retval) -- This is only in the first time the menu is opened, after that the client will receive reports from the server
    end)
end)

RegisterNetEvent("origen_admin:client:reportAccepted", function(id, assigned)
    SendNUIMessage({
        action = "reportAccepted",
        report = {
            id = id,
            assigned = assigned
        }
    })
end)

RegisterNetEvent("origen_admin:client:reportDeleted", function(id)
    SendNUIMessage({
        action = "reportDeleted",
        report = {
            id = id,
        }
    })
end)