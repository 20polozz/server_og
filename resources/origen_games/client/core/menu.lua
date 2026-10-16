--[[ ── Origen Games · el menú de cada juego ─────────────────────────────────

     Un menú lateral con su riel: salas, crear, mi sala, ranking, cómo se juega
     y, para el staff, las zonas y el punto del juego.

     El reparto del cierre es el de siempre: EL FOCO SE SUELTA YA y el
     desmontaje espera a que acabe el deslizamiento.

     La pantalla elige; quien decide es el servidor. Aquí solo se hace de
     puente: cada botón es un callback que va y vuelve con {ok, mensaje}. ]]

Menu = { abierto = false, juego = nil }

--- La zona que un admin está editando, para pintarla en el mundo.
local vistaPrevia

--- Lo que la pantalla necesita saber de un juego para pintar su menú.
local function DefParaPantalla(id)
    local d = Config.Juegos[id]
    return {
        id = d.id,
        nombre = d.nombre,
        lema = d.lema,
        icono = d.icono,
        jugadoresMin = d.jugadoresMin,
        jugadoresMax = d.jugadoresMax,
        rondas = d.rondas,
        rondasDefecto = d.rondasDefecto,
        modos = d.modos,
        campos = d.campos,
        camposSala = d.camposSala,
        ayuda = d.ayuda,
        destacado = d.destacado,
        notaBote = d.notaBote,
    }
end

local function ConfigParaPantalla()
    return {
        sala = { nombreMin = Config.Sala.nombreMin, nombreMax = Config.Sala.nombreMax },
        apuesta = {
            maxima = Config.Apuesta.maxima,
            rapidas = Config.Apuesta.rapidas,
            comision = Config.Apuesta.comision,
        },
        zona = Config.ZonaLimites,
        abandonar = Config.Teclas.abandonar.texto,
        punto = {
            npc = { modelos = Config.Punto.npc.modelos, escenarios = Config.Punto.npc.escenarios },
            recreativa = { modelos = Config.Punto.recreativa.modelos },
        },
    }
end

function Menu.Abrir(juego, seccion)
    if Menu.abierto or (Juego and Juego.activo) then return end
    if not Config.Juegos[juego] then return end

    local inicio = lib.callback.await('origen_games:inicio', false, juego)
    if not inicio then return end

    if seccion == 'zonas' and not inicio.admin then
        return TriggerEvent('QBCore:Notify', 'No tienes permiso para esto.', 'error')
    end

    local mirar = lib.callback.await('origen_games:mirar', false, juego) or {}

    -- Entre las dos preguntas pudo empezar una partida.
    if Menu.abierto or (Juego and Juego.activo) then return end
    Menu.abierto = true
    Menu.juego = juego

    SetNuiFocus(true, true)
    TriggerEvent('qv2:suppressHud', true)

    Nui.Enviar('abrir', {
        juego = DefParaPantalla(juego),
        seccion = seccion or (mirar.sala and 'sala' or 'salas'),
        admin = inicio.admin == true,
        punto = inicio.punto,
        zonas = inicio.zonas or {},
        salas = mirar.salas or {},
        sala = mirar.sala,
        -- El catálogo de props solo lo usa el campo `props` del escondite.
        catalogo = Catalogo,
        config = ConfigParaPantalla(),
        miId = GetPlayerServerId(PlayerId()),
    })
end

--[[ ── La gestión desde el panel de admin ───────────────────────────────────

     La tarjeta «Origen Games» de la pestaña Scripts de origen_admin llama a
     `openManagement`. Abre el mismo menú en modo gestión: en el riel salen
     los cinco juegos y, de cada uno, sus zonas, sus ajustes y su punto del
     mapa. El permiso se vuelve a comprobar en el servidor en cada llamada. ]]
local function ListaJuegos()
    local lista = {}
    for _, id in ipairs(Config.Orden) do
        local d = Config.Juegos[id]
        if d then lista[#lista + 1] = { id = d.id, nombre = d.nombre, icono = d.icono, lema = d.lema } end
    end
    return lista
end

function Menu.AbrirGestion(juego)
    if Menu.abierto or (Juego and Juego.activo) then return end
    juego = Config.Juegos[juego] and juego or Config.Orden[1]

    local inicio = lib.callback.await('origen_games:inicio', false, juego)
    if not inicio or not inicio.admin then
        return TriggerEvent('QBCore:Notify', 'No tienes permiso para gestionar Origen Games.', 'error')
    end
    if Menu.abierto or (Juego and Juego.activo) then return end

    Menu.abierto = true
    Menu.juego = juego
    Menu.gestion = true

    SetNuiFocus(true, true)
    TriggerEvent('qv2:suppressHud', true)

    Nui.Enviar('abrir', {
        juego = DefParaPantalla(juego),
        juegos = ListaJuegos(),
        gestion = true,
        seccion = 'zonas',
        admin = true,
        punto = inicio.punto,
        zonas = inicio.zonas or {},
        salas = {},
        catalogo = Catalogo,
        config = ConfigParaPantalla(),
        miId = GetPlayerServerId(PlayerId()),
    })
end

exports('openManagement', function() Menu.AbrirGestion() end)

--- Cambiar de juego dentro de la gestión.
RegisterNUICallback('gestionJuego', function(d, cb)
    local juego = type(d) == 'table' and d.juego
    if not Menu.abierto or not Menu.gestion or not Config.Juegos[juego] then return cb(false) end
    local inicio = lib.callback.await('origen_games:inicio', false, juego)
    if not inicio or not inicio.admin then return cb(false) end
    Menu.juego = juego
    cb({ juego = DefParaPantalla(juego), zonas = inicio.zonas or {}, punto = inicio.punto })
end)

--- Volver a la pestaña de Scripts del panel de admin.
RegisterNUICallback('volverAdmin', function(_, cb)
    cb({ ok = true })
    Menu.CerrarYa()
    TriggerEvent('qv2:suppressHud', false)
    if GetResourceState('origen_admin') == 'started' then
        pcall(function() exports.origen_admin:ReturnToScripts() end)
    end
end)

--- El cierre normal, el que pide la pantalla (Escape, pinchar fuera, botón).
function Menu.Cerrar()
    if not Menu.abierto then return end
    Menu.abierto = false
    Menu.juego = nil
    Menu.gestion = false
    vistaPrevia = nil

    SetNuiFocus(false, false)
    TriggerEvent('qv2:suppressHud', false)
    lib.callback('origen_games:mirar', false, function() end, nil)

    SetTimeout(280, function()
        if not Menu.abierto then Nui.Enviar('cerrar') end
    end)
end

--- Sin animación: empieza la partida y la pantalla tiene que irse ya.
function Menu.CerrarYa()
    if not Menu.abierto then return end
    Menu.abierto = false
    Menu.juego = nil
    Menu.gestion = false
    vistaPrevia = nil
    SetNuiFocus(false, false)
    Nui.Enviar('cerrar')
end

exports('EstaAbierto', function() return Menu.abierto end)

--[[ Raton soltado a la fuerza (vigilante de origen_map/shared/foco.lua o
     `soltarraton`): el cierre normal, con su HUD de vuelta. Sin esto
     Menu.abierto se quedaba en true y ningun punto volvia a abrir el menu. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if Menu.abierto then Menu.Cerrar() end
    end)
end

--[[ ── Lo que llega del servidor mientras el menú está abierto ────────────── ]]
RegisterNetEvent('origen_games:c:salas', function(juego, lista)
    if Menu.abierto and Menu.juego == juego then Nui.Enviar('salas', lista) end
end)

RegisterNetEvent('origen_games:c:sala', function(detalle)
    Nui.Enviar('sala', detalle)
end)

RegisterNetEvent('origen_games:c:salaCerrada', function(motivo)
    Nui.Enviar('sala', false)
    if motivo then TriggerEvent('QBCore:Notify', motivo, 'error') end
end)

RegisterNetEvent('origen_games:c:zonas', function(juego, lista)
    if Menu.abierto and Menu.juego == juego then Nui.Enviar('zonas', lista) end
end)

--[[ ── Los botones ─────────────────────────────────────────────────────────── ]]
local function Puente(nombre, callback, adaptar)
    RegisterNUICallback(nombre, function(datos, cb)
        local args = adaptar and adaptar(datos or {}) or datos
        local r = lib.callback.await('origen_games:' .. callback, false, args)
        cb(r or { ok = false, mensaje = 'Sin respuesta del servidor.' })
    end)
end

RegisterNUICallback('cerrar', function(_, cb)
    -- La gestión se abre desde la pestaña Scripts del admin: al salir con ESC
    -- se vuelve a ella (origen_admin solo vuelve si de verdad salió de allí).
    local eraGestion = Menu.gestion
    Menu.Cerrar()
    cb({ ok = true })
    if eraGestion and GetResourceState('origen_admin') == 'started' then
        SetTimeout(80, function()
            pcall(function() exports.origen_admin:ReturnToScripts() end)
        end)
    end
end)

Puente('crear', 'crear')
Puente('unirse', 'unirse', function(d) return d.id end)
Puente('salir', 'salir')
Puente('expulsar', 'expulsar', function(d) return d.id end)
Puente('empezar', 'empezar')
Puente('ranking', 'ranking')
Puente('guardarZona', 'guardarZona')
Puente('borrarZona', 'borrarZona', function(d) return d.id end)
Puente('moverPunto', 'moverPunto', function(d) return d.juego end)
Puente('guardarPunto', 'guardarPunto')

RegisterNUICallback('miPosicion', function(_, cb)
    cb(lib.callback.await('origen_games:miPosicion', false) or false)
end)

--- La zona que se está editando, para verla en el mundo.
RegisterNUICallback('verZona', function(d, cb)
    if type(d) == 'table' and tonumber(d.x) and tonumber(d.radio) then
        vistaPrevia = { x = d.x + 0.0, y = d.y + 0.0, z = d.z + 0.0, radio = d.radio + 0.0 }
    else
        vistaPrevia = nil
    end
    cb({ ok = true })
end)

RegisterNUICallback('marcarRuta', function(d, cb)
    if type(d) == 'table' and tonumber(d.x) and tonumber(d.y) then
        SetNewWaypoint(d.x + 0.0, d.y + 0.0)
    end
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if vistaPrevia and Menu.abierto then
            local v = vistaPrevia
            local pos = GetEntityCoords(PlayerPedId())
            if #(vec2(pos.x, pos.y) - vec2(v.x, v.y)) < v.radio + 250.0 then
                DrawMarker(1, v.x, v.y, v.z - 6.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    v.radio * 2.0, v.radio * 2.0, 30.0, 216, 27, 85, 55, false, false, 2, false, nil, nil, false)
                DrawMarker(28, v.x, v.y, v.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.6, 0.6, 0.6, 216, 27, 85, 200, false, false, 2, false, nil, nil, false)
            end
            Wait(0)
        else
            Wait(400)
        end
    end
end)

--- El staff gestiona todos los juegos desde donde esté: /juegos_admin abre la
--- gestión (la misma que la tarjeta del panel de admin); /juegos_admin derbi,
--- directamente en ese juego.
RegisterCommand('juegos_admin', function(_, args)
    Menu.AbrirGestion(args[1])
end, false)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    if Menu.abierto then
        SetNuiFocus(false, false)
        TriggerEvent('qv2:suppressHud', false)
    end
end)
