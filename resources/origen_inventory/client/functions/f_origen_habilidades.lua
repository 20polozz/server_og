--[[
    La subida natural de habilidades: punteria disparando, resistencia
    corriendo o nadando, fuerza peleando cuerpo a cuerpo. Y la bajada, si
    pasas horas sin hacerlo.

    Hasta el 11/09/2026 lo llevaba origen_pausemenu (client/stats.lua). Se
    queda igual, con el mismo balance: aqui se cuenta y cada 30 s se manda al
    servidor (server/functions/f_origen_habilidades.lua), que es quien lo
    guarda en gym_data y quien pone el tope a lo que se puede subir.
]]

local acumulado = { shooting = 0, condition = 0, strength = 0 }
local ultimo = { shooting = GetGameTimer(), condition = GetGameTimer(), strength = GetGameTimer() }

-- El balance de siempre, pensado para rol.
local AJUSTE = {
    -- 2 h sin disparar antes de bajar; ~0,5 % por hora; 2.500 disparos para el 100 %.
    shooting  = { umbral = 120 * 60 * 1000, baja = -0.004, sube = 0.04 },
    -- 3 h sin actividad fisica; ~0,6 % por hora.
    condition = { umbral = 180 * 60 * 1000, baja = -0.005, sube = 0.0014 },
    -- 4 h sin esfuerzo; ~0,4 % por hora.
    strength  = { umbral = 240 * 60 * 1000, baja = -0.003, sube = 0.0014 },
}

-- Diez veces por segundo: el original iba a cien y con cinco natives era caro.
CreateThread(function()
    while true do
        Wait(100)
        local ped = PlayerPedId()
        local ahora = GetGameTimer()

        if IsPedShooting(ped) then
            acumulado.shooting = acumulado.shooting + AJUSTE.shooting.sube
            ultimo.shooting = ahora
        end

        if IsPedRunning(ped) or IsPedSprinting(ped) or IsPedSwimming(ped) then
            acumulado.condition = acumulado.condition + AJUSTE.condition.sube
            ultimo.condition = ahora
        end

        if IsPedInMeleeCombat(ped) then
            acumulado.strength = acumulado.strength + AJUSTE.strength.sube
            ultimo.strength = ahora
        end
    end
end)

-- El gimnasio sube estas mismas cosas por su lado: cuenta como actividad.
RegisterNetEvent('gym:updateGymData', function(datos)
    if type(datos) ~= 'table' then return end
    if datos.condition then ultimo.condition = GetGameTimer() end
    if datos.strength then ultimo.strength = GetGameTimer() end
end)

-- Cada 30 s se manda lo acumulado, o la bajada si llevas mucho sin hacerlo.
CreateThread(function()
    while true do
        Wait(30000)
        local ahora = GetGameTimer()
        local envio, hay = {}, false

        for clave, a in pairs(AJUSTE) do
            if acumulado[clave] > 0 then
                envio[clave] = acumulado[clave]
                acumulado[clave] = 0
                hay = true
            elseif ahora - ultimo[clave] > a.umbral then
                envio[clave] = a.baja
                hay = true
            end
        end

        if hay then TriggerServerEvent('origen_inventory:habilidades:natural', envio) end
    end
end)
