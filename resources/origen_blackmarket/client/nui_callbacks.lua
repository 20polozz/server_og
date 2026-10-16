-- ========================================
-- CALLBACKS DEL NUI
-- ========================================

-- Ya están registrados en client/main.lua
-- Este archivo se puede usar para callbacks adicionales en el futuro

-- Ejemplo de callback adicional:
RegisterNUICallback('playSound', function(data, cb)
    if data.soundName and data.soundSet then
        PlaySoundFrontend(-1, data.soundName, data.soundSet, true)
    end
    cb('ok')
end)

RegisterNUICallback('vibrate', function(data, cb)
    -- Vibración del mando (si está conectado)
    if data.duration then
        local duration = data.duration or 200
        N_0x48b3886c1e7e8770(0, duration) -- Vibración ligera
    end
    cb('ok')
end)

--[[ Los avisos de la NUI (la tienda, sobre todo) van a origen_notify, como el
     resto del servidor: la pantalla ya no pinta toasts propios. Solo texto y
     un tipo de la lista; lo demas se ignora. Sin dependencia dura: si
     origen_notify no esta arrancado, no se avisa (ver la nota del fxmanifest). ]]
local TIPOS_AVISO = { success = true, error = true, info = true, warning = true }

RegisterNUICallback('notificar', function(data, cb)
    cb('ok')
    if type(data) ~= 'table' or type(data.description) ~= 'string' or data.description == '' then return end
    if GetResourceState('origen_notify') ~= 'started' then return end
    pcall(function()
        exports['origen_notify']:Notify({
            title = 'Mercado negro',
            description = data.description:sub(1, 200),
            type = TIPOS_AVISO[data.type] and data.type or 'info',
            duration = math.min(tonumber(data.duration) or 5000, 10000),
        })
    end)
end)
