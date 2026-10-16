-- ============================================================
-- ORIGEN POLICE — RECRUITMENT & TRAINING DIVISION (CLIENTE)
-- ============================================================

RegisterNUICallback("GetRtdAcademies", function(data, cb)
    FW_TriggerCallback("origen_police:server:getRtdAcademies", function(results)
        cb(results or {})
    end)
end)

RegisterNUICallback("SaveRtdAcademy", function(data, cb)
    FW_TriggerCallback("origen_police:server:saveRtdAcademy", function(result)
        cb(result or { success = false })
    end, data or {})
end)

RegisterNUICallback("DeleteRtdAcademy", function(data, cb)
    FW_TriggerCallback("origen_police:server:deleteRtdAcademy", function(result)
        cb(result or { success = false })
    end, data or {})
end)

RegisterNUICallback("GetRtdExams", function(data, cb)
    FW_TriggerCallback("origen_police:server:getRtdExams", function(results)
        cb(results or {})
    end, data or {})
end)

RegisterNUICallback("GetRtdCadets", function(data, cb)
    FW_TriggerCallback("origen_police:server:getRtdCadets", function(results)
        cb(results or {})
    end)
end)

RegisterNUICallback("GetRtdInstructors", function(data, cb)
    FW_TriggerCallback("origen_police:server:getRtdInstructors", function(results)
        cb(results or {})
    end)
end)

RegisterNUICallback("SaveRtdExam", function(data, cb)
    FW_TriggerCallback("origen_police:server:saveRtdExam", function(result)
        cb(result or { success = false })
    end, data or {})
end)

RegisterNUICallback("DeleteRtdExam", function(data, cb)
    FW_TriggerCallback("origen_police:server:deleteRtdExam", function(result)
        cb(result or { success = false })
    end, data or {})
end)

RegisterNUICallback("ReopenRtdExam", function(data, cb)
    FW_TriggerCallback("origen_police:server:reopenRtdExam", function(result)
        cb(result or { success = false })
    end, data or {})
end)

RegisterNUICallback("GetRtdCriteria", function(data, cb)
    FW_TriggerCallback("origen_police:server:getRtdCriteria", function(results)
        cb(results or {})
    end)
end)

RegisterNUICallback("SaveRtdCriteria", function(data, cb)
    FW_TriggerCallback("origen_police:server:saveRtdCriteria", function(result)
        cb(result or { success = false })
    end, data or {})
end)

RegisterNetEvent("origen_police:client:rtdUpdated", function()
    SendNUIMessage({
        action = "updateRtdExams"
    })
end)

RegisterNetEvent("origen_police:client:rtdCriteriaUpdated", function(criteria)
    SendNUIMessage({
        action = "updateRtdCriteria",
        criteria = criteria
    })
end)
