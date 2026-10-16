-- ============================================================
-- ORIGEN POLICE — RELACIONES PÚBLICAS Y CONVENIOS (CLIENTE)
-- ============================================================

RegisterNUICallback("GetAgreements", function(data, cb)
    FW_TriggerCallback("origen_police:server:getAgreements", function(results)
        cb(results or {})
    end)
end)

RegisterNUICallback("CreateAgreement", function(data, cb)
    FW_TriggerCallback("origen_police:server:createAgreement", function(result)
        cb(result or { success = false })
    end, data or {})
end)

RegisterNUICallback("UpdateAgreement", function(data, cb)
    FW_TriggerCallback("origen_police:server:updateAgreement", function(result)
        cb(result or { success = false })
    end, data or {})
end)

RegisterNUICallback("DeleteAgreement", function(data, cb)
    FW_TriggerCallback("origen_police:server:deleteAgreement", function(result)
        cb(result or { success = false })
    end, data or {})
end)

RegisterNetEvent("origen_police:client:agreementsUpdated", function()
    SendNUIMessage({
        action = "updateAgreements"
    })
end)
