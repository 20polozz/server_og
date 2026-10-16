--[[ ── Origen Games · la partida en este cliente ────────────────────────────

     El núcleo de lo que pasa en el juego: entrar y salir, cada ronda, la zona,
     el HUD, mirar la partida al quedar fuera y las votaciones. Lo propio de
     cada juego vive en client/juegos/<juego>.lua, que se registra con
     RegistrarJuego y rellena los ganchos que necesite (docs/JUEGOS.md).

     Aquí NO se decide nada: el servidor dice qué rol toca, cuándo acaba cada
     fase y quién está fuera; este cliente lo aplica y le pide cosas.

     Todo lo que se toca del personaje al entrar se deshace al salir por
     CUALQUIER camino: fin de partida, abandonar, recurso parado o volver a
     entrar tras una caída. ]]

Juego = { activo = false }

--- Los módulos de cliente de cada juego, por id.
JuegosCliente = {}

function RegistrarJuego(id, modulo)
    JuegosCliente[id] = modulo
end

--- Lo que los juegos usan del núcleo.
Core = {}

local function Ahora() return GetGameTimer() end
Core.Ahora = Ahora

--[[ El minimapa de origen_map fuera mientras dura la partida: el HUD de cada
     juego va abajo a la izquierda y se pisaban (16/09). Apartar es por
     recurso, y origen_map lo suelta solo si este recurso se para. ]]
local function Minimapa(fuera)
    if GetResourceState('origen_map') ~= 'started' then return end
    pcall(function() exports.origen_map:Apartar(fuera == true) end)
end

function Core.Yo() return GetPlayerServerId(PlayerId()) end

local function Gancho(nombre, ...)
    local m = Juego.juego and JuegosCliente[Juego.juego]
    local f = m and m[nombre]
    if not f then return nil end
    local ok, a, b = pcall(f, ...)
    if not ok then
        print(('[origen_games] Error en el cliente de %s.%s: %s'):format(Juego.juego, nombre, a))
        return nil
    end
    return a, b
end

--[[ ── Ayudantes para los juegos ──────────────────────────────────────────── ]]
function Core.Inventario(bloquear)
    if GetResourceState('origen_inventory') ~= 'started' then return end
    pcall(function()
        if bloquear then exports.origen_inventory:lock() else exports.origen_inventory:unlock() end
    end)
end

--- Sin daño de ningún tipo: la vida de la partida la lleva el servidor. No se
--- usa la invencibilidad del jugador porque el anticheat la vigila.
function Core.Blindar()
    local ped = PlayerPedId()
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)
    SetPedCanRagdoll(ped, false)
end

function Core.Teletransportar(x, y, z, rumbo)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then TaskLeaveVehicle(ped, veh, 16) end

    RequestCollisionAtCoord(x, y, z)
    SetEntityCoords(ped, x, y, z, false, false, false, false)

    local hasta = Ahora() + 2500
    while not HasCollisionLoadedAroundEntity(ped) and Ahora() < hasta do Wait(0) end

    local hay, suelo = GetGroundZFor_3dCoord(x, y, z + 3.0, false)
    if hay and math.abs(suelo - z) < 6.0 then
        SetEntityCoords(ped, x, y, suelo, false, false, false, false)
    end
    if rumbo then SetEntityHeading(ped, rumbo + 0.0) end
end

function Core.Suelo(x, y, z)
    local hay, suelo = GetGroundZFor_3dCoord(x, y, z + 3.0, false)
    if hay and math.abs(suelo - z) < 8.0 then return suelo end
    return z - 1.0
end

function Core.DarArma(nombre)
    local ped = PlayerPedId()
    local hash = GetHashKey(nombre)
    GiveWeaponToPed(ped, hash, 250, false, true)
    SetCurrentPedWeapon(ped, hash, true)
    SetPedInfiniteAmmoClip(ped, true)
end

function Core.Oscuro(si)
    if si then
        if not IsScreenFadedOut() and not IsScreenFadingOut() then DoScreenFadeOut(400) end
    else
        if IsScreenFadedOut() or IsScreenFadingOut() then DoScreenFadeIn(500) end
    end
end

--- Segundos que faltan hasta un GetGameTimer dado (redondeando hacia arriba).
function Core.Resta(hasta)
    return math.max(0, math.ceil(((hasta or 0) - Ahora()) / 1000))
end

function Core.Aviso(texto, tipo)
    Nui.Enviar('aviso', { texto = texto, tipo = tipo or 'info' })
end

--- Un cartel grande en el centro unos segundos. k: antetítulo, t: título, m: frase.
function Core.Banner(k, t, m, segundos)
    Nui.Enviar('banner', { k = k, t = t, m = m, segundos = segundos or 3 })
end

--- 'golpe' | 'fallo' | 'acierto' (sonido y destello), con aviso opcional.
function Core.Destello(tipo, texto)
    Nui.Enviar('destello', { tipo = tipo, texto = texto })
end

function Core.Sonido(tipo, x, y, z, propio, alcance)
    Nui.Sonido(tipo, x, y, z, propio, alcance)
end

--- Dirección de una rotación de cámara.
function Core.Direccion(rot)
    local rz, rx = math.rad(rot.z), math.rad(rot.x)
    local n = math.abs(math.cos(rx))
    return vector3(-math.sin(rz) * n, math.cos(rz) * n, math.sin(rx))
end

--- Traza desde la cámara hacia donde mira. Devuelve: toca, punto, entidad.
function Core.Rayo(distancia, flags, ignorar)
    local cam = GetFinalRenderedCamCoord()
    local dir = Core.Direccion(GetFinalRenderedCamRot(2))
    local hasta = cam + dir * distancia
    local prueba = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z,
        hasta.x, hasta.y, hasta.z, flags or -1, ignorar or PlayerPedId(), 7)
    local _, toca, punto, _, ent = GetShapeTestResult(prueba)
    return toca == 1, (toca == 1 and punto or hasta), ent
end

--- El ped de otro jugador de la partida por su server id, si está a la vista.
function Core.PedDe(id)
    local jugador = GetPlayerFromServerId(id)
    if jugador == -1 then return nil end
    local ped = GetPlayerPed(jugador)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return nil end
    return ped
end

--- El jugador vivo de la partida más cercano a una posición (sin contarse a
--- uno mismo). Devuelve: fila del marcador, ped, distancia.
function Core.MasCercano(desde, filtro)
    local yo = Core.Yo()
    local mejor, mejorPed, mejorD
    for _, fila in ipairs(Juego.marcador or {}) do
        if fila.vivo and fila.id ~= yo and (not filtro or filtro(fila)) then
            local ped = Core.PedDe(fila.id)
            if ped then
                local d = #(GetEntityCoords(ped) - desde)
                if not mejorD or d < mejorD then mejor, mejorPed, mejorD = fila, ped, d end
            end
        end
    end
    return mejor, mejorPed, mejorD
end

--[[ ── Votaciones ─────────────────────────────────────────────────────────────

     Una pantalla con foco para elegir entre opciones (el impostor la usa para
     votar a quién echar). La respuesta llega a `alVotar(id)`; `nil` es saltar. ]]
local votacion

function Core.Votacion(datos, alVotar)
    -- Una reunión corta cualquier minijuego a medias.
    if Core.CerrarMinijuego then Core.CerrarMinijuego() end
    votacion = { alVotar = alVotar }
    SetNuiFocus(true, true)
    Nui.Enviar('votacion', datos)
end

function Core.CerrarVotacion()
    if not votacion then return end
    votacion = nil
    SetNuiFocus(false, false)
    Nui.Enviar('votacionCerrar')
end

RegisterNUICallback('votar', function(d, cb)
    local v = votacion
    cb({ ok = true })
    if not v then return end
    Core.CerrarVotacion()
    if v.alVotar then v.alVotar(type(d) == 'table' and d.id or nil) end
end)

--[[ ── Minijuegos ──────────────────────────────────────────────────────────────

     Pantallas cortas con foco para las tareas (el impostor las usa). Se
     juegan enteras en la NUI; aquí solo se abre, se cierra y se avisa del
     resultado. Que el minijuego lo complete el cliente no prueba nada: quien
     lo usa sigue validando en el servidor presencia y tiempo mínimo. ]]
Core.MINIJUEGOS = {
    cables = 'Reparar cables',
    tarjeta = 'Pasar la tarjeta',
    secuencia = 'Arrancar el reactor',
    calibrar = 'Calibrar el motor',
    numeros = 'Reiniciar el panel',
    palanca = 'Vaciar la basura',
}

local minijuego

--- datos = { tipo, titulo, texto }. alTerminar(exito) se llama una sola vez.
function Core.Minijuego(datos, alTerminar)
    if minijuego or votacion then return false end
    if type(datos) ~= 'table' or not Core.MINIJUEGOS[datos.tipo] then return false end
    minijuego = { alTerminar = alTerminar }
    SetNuiFocus(true, true)
    Nui.Enviar('minijuego', {
        tipo = datos.tipo,
        titulo = datos.titulo or Core.MINIJUEGOS[datos.tipo],
        texto = datos.texto,
    })
    return true
end

local function TerminarMinijuego(exito)
    local m = minijuego
    if not m then return end
    minijuego = nil
    SetNuiFocus(false, false)
    Nui.Enviar('minijuegoCerrar')
    if m.alTerminar then
        local ok, err = pcall(m.alTerminar, exito == true)
        if not ok then print(('[origen_games] Error al terminar un minijuego: %s'):format(err)) end
    end
end

function Core.CerrarMinijuego() TerminarMinijuego(false) end
function Core.MinijuegoAbierto() return minijuego ~= nil end

RegisterNUICallback('minijuego', function(d, cb)
    cb({ ok = true })
    TerminarMinijuego(type(d) == 'table' and d.exito == true)
end)

--[[ ── Poner y quitar ─────────────────────────────────────────────────────── ]]

--- Deja el personaje como estaba antes de la partida.
local function Restaurar()
    local ped = PlayerPedId()
    Gancho('Restaurar')
    Espectador.Parar()
    Core.CerrarVotacion()
    Core.CerrarMinijuego()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    ResetEntityAlpha(ped)
    SetEntityCollision(ped, true, true)
    SetEntityProofs(ped, false, false, false, false, false, false, false, false)
    SetPedCanRagdoll(ped, true)
    SetPedInfiniteAmmoClip(ped, false)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    RemoveAllPedWeapons(ped, true)
    if IsScreenFadedOut() or IsScreenFadingOut() then DoScreenFadeIn(400) end
end

local function EstadoHud()
    return {
        activo = Juego.activo,
        juego = Juego.juego,
        juegoNombre = Juego.juegoNombre,
        icono = Juego.icono,
        nombre = Juego.nombre,
        modoNombre = Juego.modoNombre,
        zona = Juego.zona and Juego.zona.nombre,
        ronda = Juego.ronda,
        rondas = Juego.rondas,
        fase = Juego.fase,
        faseNombre = Juego.faseNombre,
        eliminado = Juego.eliminado,
        miId = Core.Yo(),
        bote = Juego.bote,
        destacado = Juego.juego and Config.Juegos[Juego.juego] and Config.Juegos[Juego.juego].destacado,
        abandonar = Config.Teclas.abandonar.texto,
    }
end

function Core.EnviarHud()
    Nui.Enviar('hud', EstadoHud())
end

local BucleFrame, BucleLento

RegisterNetEvent('origen_games:c:empezar', function(d)
    if Juego.activo then return end
    Menu.CerrarYa()

    Juego = {
        activo = true,
        juego = d.juego,
        juegoNombre = d.juegoNombre,
        icono = d.icono,
        nombre = d.nombre,
        modo = d.modo,
        modoNombre = d.modoNombre,
        rondas = d.rondas,
        bote = d.bote,
        zona = d.zona,
        ajustes = d.ajustes or {},
        opciones = d.opciones or {},
        jugadores = d.jugadores or {},
        marcador = {},
        contadores = {},
        yo = {},
        ronda = 0,
        fase = 'preparacion',
        faseNombre = 'Preparando',
        finFase = Ahora(),
        eliminado = false,
    }

    Core.Inventario(true)
    RemoveAllPedWeapons(PlayerPedId(), true)
    Core.Blindar()
    TriggerEvent('qv2:suppressHud', true)
    Minimapa(true)

    LocalPlayer.state:set("inGames", true, true)
    LocalPlayer.state:set("inMinigame", true, true)
    if d.juego == 'paintball' then
        LocalPlayer.state:set("inPaintball", true, true)
    end
    TriggerEvent('hospital:client:Revive')

    OrigenMapa.Poner('zona', {
        x = d.zona.x, y = d.zona.y, z = d.zona.z,
        radio = d.zona.radio,
        cat = 'activities',
        icono = 'juego',
        nombre = d.juegoNombre .. ' · ' .. (d.zona.nombre or ''),
    })

    Core.EnviarHud()
    Gancho('Empezar', d)
    CreateThread(BucleFrame)
    CreateThread(BucleLento)
end)

local function Salir(punto, rescate)
    local estaba = Juego.activo
    Juego.activo = false
    -- Sin rol ni fase: ningún hilo que siga despierto puede actuar como si
    -- continuara la partida.
    Juego.rol, Juego.fase = nil, nil

    LocalPlayer.state:set("inGames", false, true)
    LocalPlayer.state:set("inMinigame", false, true)
    LocalPlayer.state:set("inPaintball", false, true)

    Gancho('Salir')
    Restaurar()
    Core.Inventario(false)
    TriggerEvent('qv2:suppressHud', false)
    Minimapa(false)
    OrigenMapa.Quitar('zona')
    Nui.Enviar('hud', { activo = false })

    if punto and tonumber(punto.x) then
        DoScreenFadeOut(300)
        Wait(350)
        Core.Teletransportar(punto.x + 0.0, punto.y + 0.0, punto.z + 0.0)
        -- Si su punto es una recreativa, sale de la máquina.
        if Puntos and Puntos.Salir and punto.juego then Puntos.Salir(punto.juego) end
        DoScreenFadeIn(500)
    end

    --[[ Red de seguridad: pase lo que pase con los hilos de la partida, fuera
         de ella la pantalla no puede quedarse en negro. Se vigila un rato. ]]
    CreateThread(function()
        local hasta = GetGameTimer() + 5000
        while GetGameTimer() < hasta do
            if not Juego.activo and (IsScreenFadedOut() or IsScreenFadingOut()) then
                DoScreenFadeIn(400)
            end
            Wait(250)
        end
    end)

    if rescate and not estaba then
        TriggerEvent('QBCore:Notify', 'Te hemos sacado de una partida de Origen Games que no terminó.', 'primary')
    end
end

RegisterNetEvent('origen_games:c:salir', function(punto)
    if not Juego.activo then return end
    Salir(punto)
end)

RegisterNetEvent('origen_games:c:rescate', function(punto)
    if Juego.activo then return end
    -- Sin juego activo los ganchos no hacen nada: solo se restaura.
    Salir(punto, true)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(5000)
    TriggerServerEvent('origen_games:s:revisar')
end)

--[[ Y al arrancar el recurso: si se paró con salas o partidas a medias, las
     entradas siguen apuntadas y así se devuelven sin esperar a reconectar. ]]
CreateThread(function()
    Wait(9000)
    if LocalPlayer.state.isLoggedIn == true then
        TriggerServerEvent('origen_games:s:revisar')
    end
end)

--[[ ── Las rondas y las fases ─────────────────────────────────────────────── ]]
RegisterNetEvent('origen_games:c:ronda', function(d)
    if not Juego.activo then return end

    Juego.ronda = d.ronda
    Juego.rondas = d.rondas
    Juego.rol = d.rol
    Juego.eliminado = false
    Juego.datosRonda = d.datos or {}
    Juego.fase = 'preparacion'
    Juego.faseNombre = 'Preparando'
    Juego.finFase = Ahora() + d.segundos * 1000

    Nui.Enviar('ronda', { ronda = d.ronda, rondas = d.rondas, rol = d.rol, datos = d.datos })
    Core.EnviarHud()
    Gancho('AntesDeRonda', d)

    --[[ La primera ronda, si el punto del juego es una recreativa y estaba en
         ella: se mete dentro (acaba ya a oscuras). ]]
    if d.ronda == 1 and Puntos and Puntos.Entrar and Puntos.PuedeEntrar(Juego.juego) then
        --[[ Mientras se mete, el HUD no se ve: el cartel de la ronda y la
             imagen de «eres prop / cazador» tapaban la animación entera. ]]
        Juego.entrando = true
        Nui.Enviar('hudOculto', true)
        Puntos.Entrar(Juego.juego, function() return Juego.activo and Juego.ronda == d.ronda end)
        Juego.entrando = false
        Nui.Enviar('hudOculto', false)
        if not (Juego.activo and Juego.ronda == d.ronda) then return end
    end

    DoScreenFadeOut(300)
    Wait(350)

    --[[ Tras cada espera se mira si la partida sigue y si esta es todavía la
         ronda en curso: si el jugador abandonó entretanto, continuar lo dejaría
         congelado o a oscuras fuera de la partida. ]]
    local function Sigue() return Juego.activo and Juego.ronda == d.ronda end
    if not Sigue() then return end

    local ped = PlayerPedId()
    Espectador.Parar()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    RemoveAllPedWeapons(ped, true)
    Core.Blindar()

    local s = d.spawn
    Core.Teletransportar(s.x + 0.0, s.y + 0.0, s.z + 0.0, s.h)
    if not Sigue() then return end

    -- El juego prepara lo suyo. Si devuelve true, la pantalla la gestiona él.
    local propia = Gancho('Ronda', d)
    if not Sigue() then return end
    if not propia then DoScreenFadeIn(400) end
end)

RegisterNetEvent('origen_games:c:fase', function(d)
    if not Juego.activo then return end
    Juego.fase = d.fase
    Juego.faseNombre = d.nombre
    Juego.finFase = Ahora() + (d.segundos or 0) * 1000
    Nui.Enviar('fase', d)
    Core.EnviarHud()
    Gancho('Fase', d)
end)

RegisterNetEvent('origen_games:c:estado', function(d)
    if not Juego.activo then return end
    Juego.marcador = d.marcador or {}
    Juego.contadores = d.contadores or {}
    Juego.yo = d.yo or {}
    Nui.Enviar('estado', { marcador = Juego.marcador, contadores = Juego.contadores })
    Gancho('Estado', d)
end)

RegisterNetEvent('origen_games:c:finRonda', function(d)
    if not Juego.activo then return end
    Juego.fase = 'finRonda'
    Juego.finFase = Ahora() + d.segundos * 1000

    Nui.Enviar('finRonda', d)
    Gancho('FinRonda', d)

    local estabaMirando = Espectador.activo
    Espectador.Parar()
    Core.CerrarVotacion()
    Core.CerrarMinijuego()

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    RemoveAllPedWeapons(ped, true)
    SetPedInfiniteAmmoClip(ped, false)
    Core.Oscuro(false)

    -- Quien miraba desde arriba baja al centro con los demás.
    if estabaMirando and Juego.zona then
        Core.Teletransportar(Juego.zona.x, Juego.zona.y, Juego.zona.z)
    end
end)

RegisterNetEvent('origen_games:c:final', function(d)
    if not Juego.activo then return end
    Juego.fase = 'final'
    Juego.finFase = Ahora() + d.segundos * 1000
    Nui.Enviar('final', d)
    Gancho('Final', d)
end)

--[[ ── Lo que le pasa a uno ───────────────────────────────────────────────── ]]
RegisterNetEvent('origen_games:c:eliminado', function(d)
    if not Juego.activo then return end
    Juego.eliminado = true
    Core.CerrarMinijuego()
    Gancho('Eliminado', d)
    RemoveAllPedWeapons(PlayerPedId(), true)
    Core.Oscuro(false)
    Espectador.Empezar(Juego.zona)
    Nui.Enviar('eliminado', d)
    Core.EnviarHud()
end)

RegisterNetEvent('origen_games:c:devolver', function(d)
    if not Juego.activo then return end
    if Gancho('Devuelto', d) then return end
    local ped = PlayerPedId()
    SetEntityCoords(ped, d.x + 0.0, d.y + 0.0, d.z + 0.0, false, false, false, false)
    if d.quieto then FreezeEntityPosition(ped, true) end
end)

RegisterNetEvent('origen_games:c:aviso', function(d)
    if Juego.activo then Nui.Enviar('aviso', d) end
end)

RegisterNetEvent('origen_games:c:banner', function(d)
    if Juego.activo then Nui.Enviar('banner', d) end
end)

RegisterNetEvent('origen_games:c:destello', function(d)
    if Juego.activo then Nui.Enviar('destello', d) end
end)

RegisterNetEvent('origen_games:c:sonido', function(d)
    if not Juego.activo then return end
    Nui.Sonido(d.tipo, d.x and d.x + 0.0, d.y and d.y + 0.0, d.z and d.z + 0.0, d.id == Core.Yo(), d.alcance)
end)

--[[ ── Los bucles ──────────────────────────────────────────────────────────── ]]
local FASES_QUIETAS = { preparacion = true, finRonda = true, final = true }

BucleFrame = function()
    local mantenerDesde
    local ultimoProgreso = -1

    while Juego.activo do
        local ahora = Ahora()

        DisableControlAction(0, 37, true)   -- rueda de armas
        DisableControlAction(0, Config.Teclas.abandonar.control, true)
        DisableControlAction(0, 75, true)   -- salir del vehículo: F es abandonar

        -- Mantener F para abandonar.
        if IsDisabledControlPressed(0, Config.Teclas.abandonar.control) and Juego.fase ~= 'final' then
            mantenerDesde = mantenerDesde or ahora
            local progreso = math.min(1.0, (ahora - mantenerDesde) / Config.MantenerParaSalir)
            local redondo = math.floor(progreso * 20)
            if redondo ~= ultimoProgreso then
                ultimoProgreso = redondo
                Nui.Enviar('abandonando', { progreso = progreso })
            end
            if progreso >= 1.0 then
                mantenerDesde = nil
                TriggerServerEvent('origen_games:s:abandonar')
                Wait(1500)
                -- Durante esa espera el servidor ya nos ha sacado: seguir con
                -- esta vuelta sería usar los datos de la partida que acabó.
                if not Juego.activo then break end
            end
        elseif mantenerDesde then
            mantenerDesde = nil
            ultimoProgreso = -1
            Nui.Enviar('abandonando', { progreso = 0 })
        end

        if Juego.activo and not Espectador.activo then
            Gancho('Frame', ahora)
        end

        -- La zona, pintada: un cilindro rosa que marca el borde.
        local z = Juego.zona
        if Juego.activo and z then
            DrawMarker(1, z.x, z.y, z.z - 25.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                z.radio * 2.0, z.radio * 2.0, 80.0, 216, 27, 85, 34, false, false, 2, false, nil, nil, false)
        end

        Wait(0)
    end
end

BucleLento = function()
    local ultimoFuera = nil

    while Juego.activo do
        local ahora = Ahora()
        local ped = PlayerPedId()

        Gancho('Lento', ahora)

        -- La zona: aviso y cuenta atrás. Quien manda es el servidor; esto es
        -- para que se vea venir.
        local fuera
        local z = Juego.zona
        if z and not Juego.eliminado and not Espectador.activo and not FASES_QUIETAS[Juego.fase] then
            local c = GetEntityCoords(ped)
            local dx, dy = c.x - z.x, c.y - z.y
            if math.sqrt(dx * dx + dy * dy) > z.radio then
                ultimoFuera = ultimoFuera or ahora
                fuera = math.max(0, Config.Zona.aviso - math.floor((ahora - ultimoFuera) / 1000))
            else
                ultimoFuera = nil
            end
        else
            ultimoFuera = nil
        end

        local ficha = not Juego.entrando and Gancho('Ficha') or nil
        if not ficha and Juego.eliminado then
            ficha = {
                tono = 'fuera', icono = 'ojo', rol = 'Fuera de la ronda',
                nombre = Juego.mirandoA and 'Mirando' or 'Esperando',
                renglon = Juego.mirandoA and '← → para cambiar' or 'A la siguiente ronda',
                puntos = Juego.yo and Juego.yo.puntos or 0,
            }
        end

        Nui.Enviar('tick', {
            quedan = Core.Resta(Juego.finFase),
            fuera = fuera,
            ficha = ficha,
            cartel = not Juego.entrando and Gancho('Cartel') or nil,
            fondo = not Juego.entrando and Gancho('Fondo') or nil,
            mirandoA = Espectador.activo and Juego.mirandoA or nil,
            -- Lo que el marcador tenga que decir de cada uno (icono por fila).
        })

        Wait(250)
    end
end

--[[ ── Para otros recursos ─────────────────────────────────────────────────── ]]
exports('EstaJugando', function() return Juego.activo == true, Juego.juego end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end

    --[[ Un fundido a negro no puede sobrevivir a este recurso: reiniciarlo es
         también la forma de sacar a alguien que se quedó a oscuras. ]]
    if (Juego.activo or LocalPlayer.state.isLoggedIn) and (IsScreenFadedOut() or IsScreenFadingOut()) then
        DoScreenFadeIn(0)
    end
    if not Juego.activo then return end
    Juego.activo = false

    LocalPlayer.state:set("inGames", false, true)
    LocalPlayer.state:set("inMinigame", false, true)
    LocalPlayer.state:set("inPaintball", false, true)

    -- Sin Wait: el recurso se está parando y el hilo no volvería.
    local ped = PlayerPedId()
    Gancho('Salir')
    Espectador.Parar()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetEntityProofs(ped, false, false, false, false, false, false, false, false)
    SetPedCanRagdoll(ped, true)
    SetPedInfiniteAmmoClip(ped, false)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    RemoveAllPedWeapons(ped, true)
    Core.Inventario(false)
    TriggerEvent('qv2:suppressHud', false)
    if votacion or minijuego then SetNuiFocus(false, false) end

    local p = Juego.juego and Puntos.De(Juego.juego)
    if p then SetEntityCoords(ped, p.x + 0.0, p.y + 0.0, p.z + 0.0, false, false, false, false) end
end)
