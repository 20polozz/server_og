-- ========================================
-- CLIENTE: SESIONES DE VARIAS CARRERAS CON VOTACIÓN
-- ========================================
--[[ La parte de cada corredor de una sesión (server/sesiones.lua):

       votar      la pantalla de votación sale sin foco: se elige con ← → y
                  se vota con ENTER (los números son del inventario). Se puede
                  cambiar el voto mientras dure.
       siguiente  la salida de la siguiente carrera, marcada en el GPS; al
                  llegar al volante te apunta y te pone listo solo.
       final      la clasificación de la sesión al acabar. ]]

local votacion = nil    -- { sesion, n, hasta, sel, mio }
local pendiente = nil   -- la siguiente carrera, mientras se va hacia ella

local function avisar(titulo, texto, tipo, ms)
    lib.notify({ title = titulo, description = texto, type = tipo or 'inform', duration = ms or 5000 })
end

-- ── Votar ────────────────────────────────────────────────────────────────────

local IZQ, DER, ENTER = 174, 175, 201

RegisterNetEvent('racing:sesion:votar', function(d)
    if type(d) ~= 'table' or type(d.opciones) ~= 'table' or #d.opciones == 0 then return end
    local mi = { sesion = d.sesion, n = #d.opciones, hasta = GetGameTimer() + (tonumber(d.segundos) or 25) * 1000, sel = 1 }
    votacion = mi
    d.seleccion = 1
    SendNUIMessage({ action = 'sesion:votar', data = d })
    PlaySoundFrontend(-1, 'CHALLENGE_UNLOCKED', 'HUD_AWARDS', true)

    CreateThread(function()
        while votacion == mi and GetGameTimer() < mi.hasta do
            local antes = mi.sel
            if IsControlJustPressed(0, IZQ) then mi.sel = mi.sel > 1 and mi.sel - 1 or mi.n end
            if IsControlJustPressed(0, DER) then mi.sel = mi.sel < mi.n and mi.sel + 1 or 1 end
            if mi.sel ~= antes then
                SendNUIMessage({ action = 'sesion:seleccion', data = { opcion = mi.sel } })
                PlaySoundFrontend(-1, 'NAV_LEFT_RIGHT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end
            if IsControlJustPressed(0, ENTER) and mi.mio ~= mi.sel then
                mi.mio = mi.sel
                TriggerServerEvent('racing:sesion:voto', mi.sesion, mi.sel)
                SendNUIMessage({ action = 'sesion:miVoto', data = { opcion = mi.sel } })
                PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end
            Wait(0)
        end
    end)
end)

RegisterNetEvent('racing:sesion:recuento', function(d)
    if votacion and type(d) == 'table' and d.sesion == votacion.sesion then
        SendNUIMessage({ action = 'sesion:recuento', data = d })
    end
end)

-- ── Ir a la siguiente ────────────────────────────────────────────────────────

local function alVolante()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    return veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and veh or nil
end

RegisterNetEvent('racing:sesion:siguiente', function(d)
    if type(d) ~= 'table' or type(d.salida) ~= 'table' then return end
    votacion = nil
    pendiente = d
    local mi = d

    SendNUIMessage({ action = 'sesion:siguiente', data = d })
    SetNewWaypoint(d.salida.x + 0.0, d.salida.y + 0.0)
    avisar(('Sesión · carrera %d de %d'):format(d.carrera, d.total),
        ('Gana %s. La salida está marcada en el GPS: al llegar te apuntas solo.'):format(d.elegida), 'inform', 9000)

    CreateThread(function()
        local salida = vector3(d.salida.x + 0.0, d.salida.y + 0.0, d.salida.z + 0.0)
        local hasta = GetGameTimer() + ((tonumber(d.segundos) or 240) + 5) * 1000
        local apuntado, siguienteIntento = false, 0
        local fallos, ultimoMotivo = 0, nil

        while pendiente == mi and GetGameTimer() < hasta and not EnCarrera() do
            local veh = alVolante()
            if veh and GetGameTimer() >= siguienteIntento
                and #(GetEntityCoords(veh) - salida) < (tonumber(d.radio) or 45.0) then

                if not apuntado then
                    local nombre = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                    -- La contraseña no se mira: los de la sesión van invitados.
                    local ok, r = pcall(lib.callback.await, 'racing:hub:joinRace', false, {
                        raceId = d.raceId, password = 'sesion',
                        vehicleName = (nombre and nombre ~= 'CARNOTFOUND') and nombre or nil,
                    })
                    if ok and r and r.success then
                        apuntado = true
                    else
                        --[[ Lo que diga el servidor (clase del coche,
                             entrada...), UNA vez —o cuando cambie el motivo—, y
                             se vuelve a probar cada vez mas espaciado (8, 16,
                             32 s, y luego cada minuto) por si lo arregla. Antes
                             era cada 8 s con el mismo aviso de error durante
                             los cuatro minutos de espera. ]]
                        local motivo = (ok and r and r.message) or 'No te has podido apuntar'
                        if motivo ~= ultimoMotivo then
                            ultimoMotivo = motivo
                            avisar('Sesión', motivo, 'error', 6000)
                        end
                        fallos = fallos + 1
                        siguienteIntento = GetGameTimer() + math.min(60000, 8000 * 2 ^ (fallos - 1))
                    end
                end

                if apuntado and not LocalPlayer.state.isReady then
                    local ok, r = pcall(lib.callback.await, 'racing:hub:toggleReady', false, {})
                    if ok and r and r.success and r.isReady then
                        avisar('Sesión', 'Listo. Se sale en cuanto estéis todos.', 'success', 5000)
                    end
                    -- El estado tarda un poco en volver: no se pulsa dos veces.
                    siguienteIntento = GetGameTimer() + 3000
                end
            end
            Wait(500)
        end
        if pendiente == mi then pendiente = nil end
    end)
end)

-- ── Fin ──────────────────────────────────────────────────────────────────────

RegisterNetEvent('racing:sesion:final', function(d)
    votacion, pendiente = nil, nil
    if type(d) ~= 'table' then return end
    SendNUIMessage({ action = 'sesion:final', data = d })
    if d.motivo then avisar('Sesión', d.motivo, 'error', 7000) end

    -- Se cierra con Retroceso, como los resultados (o sola, desde la interfaz).
    CreateThread(function()
        local hasta = GetGameTimer() + 30000
        while GetGameTimer() < hasta do
            if IsControlJustPressed(0, 194) then break end
            Wait(0)
        end
        SendNUIMessage({ action = 'sesion:cerrar' })
    end)
end)
