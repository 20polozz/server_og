-- ============================================================
-- ORIGEN POLICE — ANUNCIOS Y BOLETINES (CLIENTE)
-- ============================================================

RegisterNUICallback("GetAnnouncements", function(data, cb)
    FW_TriggerCallback("origen_police:server:getAnnouncements", function(results)
        cb(results or {})
    end)
end)

RegisterNUICallback("CreateAnnouncement", function(data, cb)
    FW_TriggerCallback("origen_police:server:createAnnouncement", function(result)
        cb(result or { success = false })
    end, data or {})
end)

RegisterNUICallback("UpdateAnnouncement", function(data, cb)
    FW_TriggerCallback("origen_police:server:updateAnnouncement", function(result)
        cb(result or { success = false })
    end, data or {})
end)

RegisterNUICallback("TogglePinAnnouncement", function(data, cb)
    local id = (type(data) == "table" and data.id) or data
    FW_TriggerCallback("origen_police:server:togglePinAnnouncement", function(result)
        cb(result or { success = false })
    end, id)
end)

RegisterNUICallback("DeleteAnnouncement", function(data, cb)
    local id = (type(data) == "table" and data.id) or data
    FW_TriggerCallback("origen_police:server:deleteAnnouncement", function(result)
        cb(result or { success = false })
    end, id)
end)

RegisterNetEvent("origen_police:client:announcementsUpdated", function()
    SendNUIMessage({
        action = "updateAnnouncements"
    })
end)
