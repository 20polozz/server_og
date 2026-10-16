-- NUI Callbacks for Weather Admin Panel
local openedFromHub = false
-- Si el panel sigue abierto; el foco se da 2,8 s después y solo si no se cerró entretanto
local abierto = false

RegisterNUICallback('closeWeatherAdmin', function(_, cb)
    abierto = false
    SetNuiFocus(false, false)
    -- La NUI solo esconde el panel al recibir este mensaje; sin él quedaba pintado
    SendNUIMessage({ action = 'closeWeatherAdmin' })
    cb('ok')
    
    -- Si fue abierto desde el hub, volver al hub con pantalla de carga
    if openedFromHub then
        openedFromHub = false  -- Reset
        exports['origen_admin']:ReturnToScripts()
    end
end)

RegisterNUICallback('getWeatherEvents', function(_, cb)
    lib.callback('Renewed-Weathersync:server:getWeatherEvents', false, function(events)
        cb(events or {})
    end)
end)

RegisterNUICallback('setWeatherType', function(data, cb)
    local result = lib.callback.await('Renewed-Weathersync:server:setWeatherType', false, data.index, data.weatherType)
    cb({ success = result ~= false })
end)

RegisterNUICallback('setEventTime', function(data, cb)
    local result = lib.callback.await('Renewed-Weathersync:server:setEventTime', false, data.index, data.time)
    cb({ success = result ~= false })
end)

RegisterNUICallback('removeWeatherEvent', function(data, cb)
    TriggerServerEvent('Renewed-Weather:server:removeWeatherEvent', data.index)
    cb({ success = true })
end)

-- El apagón y la hora para el panel: solo se LEEN los GlobalState que el
-- servidor ya reparte (blackOut, currentTime...). No cambia nada.
RegisterNUICallback('estadoClima', function(_, cb)
    local gs = GlobalState
    cb({
        apagon = gs.blackOut == true,
        hora = gs.currentTime,
        horaCongelada = gs.freezeTime == true,
        climaCongelado = gs.weatherFrozen == true,
        noche = gs.isNight == true,
    })
end)

RegisterNUICallback('toggleBlackout', function(_, cb)
    TriggerServerEvent('Renewed-Weather:server:toggleBlackout')
    cb({ success = true })
end)

--- El panel de gestion del clima (pantalla completa). Desde el hub de admin se
--- espera a que termine su transicion antes de coger el foco; por /weather no.
function AbrirPanelClima(desdeHub)
    openedFromHub = desdeHub == true
    abierto = true

    CreateThread(function()
        SendNUIMessage({
            action = 'openWeatherAdmin'
        })

        if desdeHub then Wait(2800) end

        -- Si lo cerraron durante la espera, no se coge el foco (ratón preso sin panel)
        if not abierto then return end
        SetNuiFocus(true, true)
    end)
end

-- Export for origen_hub integration
exports('openManagement', function()
    AbrirPanelClima(true)
end)
