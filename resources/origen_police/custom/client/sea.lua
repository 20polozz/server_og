-- ============================================================
-- ORIGEN POLICE — SISTEMA DE ALERTA ESTATAL DE EMERGENCIA (CLIENTE)
-- ============================================================

RegisterNUICallback("GetSeaAlert", function(data, cb)
    FW_TriggerCallback("origen_police:server:getSeaAlert", function(result)
        if result then
            cb(result)
        else
            cb({ success = false, message = "No se pudo conectar con el servidor para consultar el SEA." })
        end
    end)
end)

RegisterNUICallback("SetSeaLevel", function(data, cb)
    FW_TriggerCallback("origen_police:server:setSeaLevel", function(result)
        if result then
            cb(result)
        else
            cb({ success = false, message = "Sin respuesta del servidor al actualizar nivel SEA." })
        end
    end, data or {})
end)

RegisterNUICallback("BroadcastSeaMessage", function(data, cb)
    FW_TriggerCallback("origen_police:server:broadcastSeaMessage", function(result)
        if result then
            cb(result)
        else
            cb({ success = false, message = "Sin respuesta del servidor al emitir comunicado." })
        end
    end, data or {})
end)

RegisterNUICallback("DeleteSeaHistory", function(data, cb)
    FW_TriggerCallback("origen_police:server:deleteSeaHistory", function(result)
        if result then
            cb(result)
        else
            cb({ success = false, message = "Sin respuesta del servidor al eliminar registro del historial." })
        end
    end, data or {})
end)

RegisterNetEvent("origen_police:client:seaAlertUpdated", function(data)
    SendNUIMessage({
        action = "updateSeaAlert",
        data = data
    })
end)

