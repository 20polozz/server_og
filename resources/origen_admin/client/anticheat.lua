-- =============================================
-- origen_admin — Client: NUI Callbacks Anticheat
-- Puente entre el panel React y el servidor
-- =============================================

-- Obtener violaciones (con paginado y filtros)
RegisterNUICallback('ac:getViolations', function(data, cb)
    FW_TriggerCallback('ac:getViolations', function(result)
        cb(result or {})
    end, data)
end)

-- Obtener estadísticas del panel anticheat
RegisterNUICallback('ac:getStats', function(data, cb)
    FW_TriggerCallback('ac:getStats', function(result)
        cb(result or {})
    end)
end)

-- Obtener estado actual del toggle de exención de admins
RegisterNUICallback('ac:getExemptState', function(data, cb)
    FW_TriggerCallback('ac:getExemptState', function(result)
        cb(result or { exemptAdmins = true })
    end)
end)

-- Cambiar el estado del toggle de exención de admins
RegisterNUICallback('ac:setExemptState', function(data, cb)
    FW_TriggerCallback('ac:setExemptState', function(result)
        cb(result or { exemptAdmins = true })
    end, data)
end)
