local callback
local active = false

--- Entrega el resultado UNA sola vez: el 'end' de la pagina, el raton
--- soltado a la fuerza y una segunda barra encima no pueden llamarlo dos
--- veces (la segunda reventaba con `callback` ya a nil).
local function Terminar(result)
    if not active then return end
    active = false
    SetNuiFocus(false, false)

    local fn = callback
    callback = nil
    if fn then fn(result == true) end
end

local function StartSkillbar(cb)

    -- Con una barra ya en marcha se contesta que no: sin respuesta, quien
    -- espera (la caña de c_main.lua) se quedaba colgado para siempre.
    if active then
        if cb then cb(false) end
        return
    end

    active = true
    callback = cb
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'skillbar',
    })
end

RegisterNUICallback('end', function(data, cb)
    cb({})
    Terminar(data and data.result)
end)

--[[ Raton soltado a la fuerza (vigilante de origen_map/shared/foco.lua o
     `soltarraton`): la barra se da por fallada y se quita de la pantalla. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not active then return end
        SendNUIMessage({ action = 'skillbarFin' })
        Terminar(false)
    end)
end

exports('Skillbar', StartSkillbar)
