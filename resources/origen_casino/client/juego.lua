--[[ ══════════════════════════════════════════════════════════════════════════
     EL PUENTE CON LA PANTALLA DE JUEGO

     La pantalla no sabe jugar: enseña lo que le manda el servidor y devuelve
     lo que el jugador pulsa. Todo lo que sale de aquí hacia arriba es una
     petición, nunca un hecho.

     El estado llega EMPUJADO desde el servidor cada vez que cambia algo, no
     preguntando cada poco: una mesa de ruleta con siete sentados haciendo un
     sondeo por segundo son siete peticiones por segundo para enseñar lo mismo.
   ══════════════════════════════════════════════════════════════════════════ ]]

local abierto = false

function AbrirJuego(datos)
    if abierto then return end
    abierto = true
    C.pantalla = 'juego'
    -- La tragaperras y las máquinas de vídeo se juegan con el teclado, como en
    -- GTA Online (client/maquinas.lua, client/video.lua): sin ratón, la
    -- pantalla solo enseña.
    C.Foco(datos.juego ~= 'tragaperras' and datos.juego ~= 'rueda' and not VideoEsJuego(datos.juego))
    C.Enviar('abrirJuego', {
        juego = datos.juego,
        punto = datos.punto,
        plaza = datos.plaza,
        jackpot = C.jackpot,
    })
end

function CerrarJuego()
    if not abierto then return end
    abierto = false
    C.pantalla = nil
    C.Foco(false)
    C.Enviar('cerrarJuego')
end

--[[ Sin raton la mesa no se puede jugar ni dejar: se hace lo mismo que el
     boton de salir de la pantalla. Levantarse espera al servidor, de ahi el
     hilo. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not abierto then return end
        abierto = false
        C.Enviar('cerrarJuego')
        CreateThread(function() Levantarse() end)
    end)
end

RegisterNetEvent('origen_casino:estado', function(estado)
    -- Lo guarda también la mesa del mundo: con él pone tus cartas boca arriba.
    C.estado = estado
    if not abierto then return end
    C.Enviar('estado', estado)
end)

-- ── Lo que manda la pantalla ──────────────────────────────────────────────

RegisterNUICallback('accion', function(datos, cb)
    if not abierto then cb({ ok = false }) return end
    local res = lib.callback.await('origen_casino:accion', false,
        datos and datos.accion, datos and datos.datos)
    cb(res or { ok = false })
end)

RegisterNUICallback('salir', function(_, cb)
    cb({})
    Levantarse()
    CerrarJuego()
end)

RegisterNUICallback('refrescar', function(_, cb)
    cb({})
    lib.callback.await('origen_casino:refrescar', false)
end)

--[[ El sonido lo pone la pantalla, pero el aviso de ganar gordo se oye también
     fuera: es lo que hace que la sala se gire a mirar. ]]
RegisterNUICallback('sonar', function(datos, cb)
    cb({})
    local cual = datos and datos.cual
    if cual == 'premio' then
        PlaySoundFrontend(-1, 'RACE_PLACED', 'HUD_AWARDS', true)
    elseif cual == 'jackpot' then
        PlaySoundFrontend(-1, 'Mission_Pass_Notify', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', true)
    end
end)
