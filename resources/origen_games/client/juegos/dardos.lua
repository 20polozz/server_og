--[[ ── Origen Games · dardos, el cliente ─────────────────────────────────────

     Tres cosas: encontrar la diana que se tiene delante (del mapa o un mueble
     de una casa), apuntar y lanzar cuando es tu turno, y pintar los dardos
     clavados. El HUD es el de Origen Games: se le mandan la ficha, el
     marcador y los carteles como datos, igual que hace el núcleo.

     Quién tira, qué vale cada dardo y quién gana lo decide el servidor
     (server/juegos/dardos.lua). Aquí solo se dice dónde ha caído el dardo. ]]

local C = Config.Juegos.dardos
local T = C.teclas
local DICC = 'anim@amb@clubhouse@mini@darts@'
local DARDO = `prop_dart_1`

local MODELOS = {}
for nombre, datos in pairs(C.modelos) do
    MODELOS[#MODELOS + 1] = { nombre = nombre, hash = joaat(nombre), datos = datos }
end

local Dardos = {
    mesa = nil,          -- el último estado de la mesa en la que estoy
    diana = nil,         -- la diana que tengo delante (fuera de una mesa)
    resumen = nil,       -- la mesa que hay en esa diana, si la hay
    apuntando = false,
    clavados = {},       -- mesa → { objetos }
    cartel = nil, cartelHasta = 0,
    final = false,
}

local function Ahora() return GetGameTimer() end

--[[ ── La geometría de la diana ──────────────────────────────────────────────

     La diana se describe con su centro (el 50), la normal de la cara (hacia
     donde está quien tira) y su «arriba». La derecha de quien la mira se saca
     de ahí. Es lo que se manda al servidor y lo que les llega a todos para
     clavar los dardos en el mismo sitio. ]]
local function Cruz(a, b)
    return vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

local function Marco(d)
    local centro = vector3(d.x, d.y, d.z)
    local normal = vector3(d.nx, d.ny, d.nz)
    local arriba = vector3(d.ux, d.uy, d.uz)
    local derecha = Cruz(-normal, arriba)
    return centro, normal, arriba, derecha
end

--- La diana (objeto) que hay delante del jugador, o nil.
local function BuscarDiana(ped)
    local pos = GetEntityCoords(ped)
    local mejor, mejorDist
    for _, m in ipairs(MODELOS) do
        local obj = GetClosestObjectOfType(pos.x, pos.y, pos.z, C.alcance + 1.5, m.hash, false, false, false)
        if obj ~= 0 and DoesEntityExist(obj) then
            local c = m.datos.centro
            local centro = GetOffsetFromEntityInWorldCoords(obj, c.x, c.y, c.z)
            local adelante, _, arriba = GetEntityMatrix(obj)   -- devuelve delante, derecha, arriba, posición
            local normal = adelante * m.datos.cara
            local hacia = pos - centro
            local plano = vector3(hacia.x, hacia.y, 0.0)
            local dist = #plano
            -- Hay que estar delante de la cara, no detrás de la pared.
            if dist <= C.alcance and (hacia.x * normal.x + hacia.y * normal.y) > 0.3 and (not mejorDist or dist < mejorDist) then
                mejor = {
                    modelo = m.nombre,
                    x = centro.x, y = centro.y, z = centro.z,
                    nx = normal.x, ny = normal.y, nz = normal.z,
                    ux = arriba.x, uy = arriba.y, uz = arriba.z,
                }
                mejorDist = dist
            end
        end
    end
    return mejor
end

--[[ ── Los dardos clavados ─────────────────────────────────────────────────── ]]
local function Recoger(idMesa)
    for _, obj in ipairs(Dardos.clavados[idMesa] or {}) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    Dardos.clavados[idMesa] = nil
end

local function RecogerTodo()
    for id in pairs(Dardos.clavados) do Recoger(id) end
end

--[[ El dardo vuela desde la mano de quien tira hasta donde cae y se queda
     clavado, con la cola hacia fuera. prop_dart_1 va a lo largo de su Z con la
     punta hacia -Z y mide 19 cm: se gira para que su +Z mire como la normal de
     la cara y su centro queda fuera, con un centímetro de punta dentro. ]]
local MEDIO_DARDO = 0.094

local function Clavar(d)
    local centro, normal, arriba, derecha = Marco(d.diana)
    local destino = centro + derecha * d.u + arriba * d.v + normal * (MEDIO_DARDO - 0.012)

    lib.requestModel(DARDO, 3000)
    local desde = destino + normal * C.distanciaTiro
    local ped = GetPlayerFromServerId(d.tirador)
    if ped ~= -1 then
        local p = GetPlayerPed(ped)
        if p ~= 0 and DoesEntityExist(p) then desde = GetPedBoneCoords(p, 57005, 0.0, 0.0, 0.0) end
    end

    local obj = CreateObject(DARDO, desde.x, desde.y, desde.z, false, false, false)
    SetEntityCollision(obj, false, false)
    FreezeEntityPosition(obj, true)
    SetEntityRotation(obj, -90.0, 0.0, GetHeadingFromVector_2d(normal.x, normal.y), 2, true)
    SetModelAsNoLongerNeeded(DARDO)

    Dardos.clavados[d.mesa] = Dardos.clavados[d.mesa] or {}
    table.insert(Dardos.clavados[d.mesa], obj)

    CreateThread(function()
        local inicio, dura = Ahora(), 180
        while DoesEntityExist(obj) do
            local t = math.min(1.0, (Ahora() - inicio) / dura)
            -- Un arco suave: sube un poco a mitad de camino.
            local p = desde + (destino - desde) * t + vector3(0.0, 0.0, math.sin(t * math.pi) * 0.12)
            SetEntityCoordsNoOffset(obj, p.x, p.y, p.z, false, false, false)
            if t >= 1.0 then break end
            Wait(0)
        end
    end)
end

--[[ ── El HUD ──────────────────────────────────────────────────────────────── ]]
local function Modo(id)
    for _, m in ipairs(C.modos) do
        if m.id == id then return m end
    end
    return {}
end

local function Minimapa(fuera)
    if GetResourceState('origen_map') ~= 'started' then return end
    pcall(function() exports.origen_map:Apartar(fuera == true) end)
end

local hudEncendido = false
local function Hud(encender)
    if encender == hudEncendido then return end
    hudEncendido = encender
    if not encender then
        Nui.Enviar('hud', { activo = false })
        Minimapa(false)
        return
    end
    Minimapa(true)
end

local function EnviarHud(m)
    local modo = Modo(m.modo)
    Nui.Enviar('hud', {
        activo = true,
        juegoNombre = C.nombre,
        icono = C.icono,
        nombre = 'Mesa de dardos',
        modoNombre = modo.nombre,
        ronda = modo.turnos and math.min((m.yo and m.yo.turnos or 0) + 1, modo.turnos) or m.ronda,
        rondas = modo.turnos or m.ronda,
        fase = m.fase == 'espera' and 'preparacion' or m.fase,
        faseNombre = m.fase == 'espera' and 'Esperando'
            or m.fase == 'recoger' and 'Recogiendo'
            or (m.tirando == Core.Yo() and 'Tu turno' or ('Tira %s'):format(m.tirandoNombre or '')),
        miId = Core.Yo(),
        destacado = C.destacado,
        abandonar = T.salir.texto,
    })
    Nui.Enviar('estado', {
        marcador = m.marcador,
        contadores = m.fase == 'turno' and { { k = 'Dardo', v = ('%s/%s'):format(math.min(m.dardo + 1, C.dardosPorTurno), C.dardosPorTurno) } } or {},
    })
end

--- El aire que queda para aguantar la respiración (0-1).
local aire, cansado = 1.0, false

local function Ficha()
    local m = Dardos.mesa
    if not m then return nil end
    local modo = Modo(m.modo)
    local miTurno = m.tirando == Core.Yo() and m.fase == 'turno'
    local yo = m.yo or {}

    local renglon
    if modo.inicio then
        renglon = ('Te quedan %s'):format(yo.marca or modo.inicio)
    elseif m.modo == 'reloj' then
        renglon = (yo.objetivo or 1) > 20 and 'Te falta la diana' or ('Te toca el %s'):format(yo.objetivo or 1)
    else
        renglon = ('Turno %s de %s'):format(math.min((yo.turnos or 0) + 1, modo.turnos or 10), modo.turnos or 10)
    end

    local ficha = {
        tono = miTurno and 'caza' or 'neutro',
        icono = 'diana',
        rol = modo.nombre,
        nombre = m.estado == 'espera' and 'Esperando rivales' or (miTurno and 'Tu turno' or ('Tira %s'):format(m.tirandoNombre or '…')),
        renglon = renglon,
        puntos = yo.marca or 0,
    }

    if Dardos.apuntando then
        ficha.vida = { tipo = 'barra', etiqueta = 'Aire', pct = aire * 100, mal = cansado, cifra = cansado and 'Sin aire' or nil }
        ficha.acciones = {
            { id = 'lanzar', tecla = T.lanzar.texto, nombre = 'Lanzar' },
            { id = 'aguantar', tecla = T.aguantar.texto, nombre = 'Aguantar el pulso', apagada = cansado },
        }
    elseif m.estado == 'espera' then
        ficha.acciones = m.anfitrion == Core.Yo()
            and { { id = 'empezar', tecla = T.entrar.texto, nombre = ('Empezar (%s/%s)'):format(#m.marcador, m.max) } }
            or { { id = 'espera', tecla = '…', nombre = 'Espera a que empiece', apagada = true } }
    end
    return ficha
end

local function Cartel()
    local m = Dardos.mesa
    if not m then return nil end
    if Dardos.cartel and Ahora() < Dardos.cartelHasta then return Dardos.cartel end
    if m.estado == 'espera' then
        local modo = Modo(m.modo)
        return {
            k = 'Mesa de dardos · ' .. (modo.nombre or ''),
            t = m.anfitrion == Core.Yo() and 'Esperando rivales' or 'Esperando',
            m = m.anfitrion == Core.Yo() and ('Pulsa %s para empezar · %s/%s en la mesa'):format(T.entrar.texto, #m.marcador, m.max)
                or ('Somos %s/%s'):format(#m.marcador, m.max),
        }
    end
    return nil
end

--[[ ── Apuntar y lanzar ────────────────────────────────────────────────────── ]]
local camara, dardoMano
local apunte = { x = 0.0, y = 0.0 }
local fases = { math.random() * 6.28, math.random() * 6.28, math.random() * 6.28, math.random() * 6.28 }
local lanzado = 0

local function CargarAnim()
    RequestAnimDict(DICC)
    local t = Ahora()
    while not HasAnimDictLoaded(DICC) and Ahora() - t < 3000 do Wait(0) end
end

local function SoltarDardoMano()
    if dardoMano and DoesEntityExist(dardoMano) then DeleteEntity(dardoMano) end
    dardoMano = nil
end

local function DejarDeApuntar()
    if not Dardos.apuntando then return end
    Dardos.apuntando = false
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    StopAnimTask(ped, DICC, 'throw_idle_a', 2.0)
    SoltarDardoMano()
    if camara then
        RenderScriptCams(false, true, 400, true, true)
        DestroyCam(camara, false)
        camara = nil
    end
end

local function Apuntar()
    local m = Dardos.mesa
    if not m or Dardos.apuntando then return end
    Dardos.apuntando = true
    apunte = { x = 0.0, y = 0.0 }
    aire, cansado = 1.0, false

    local centro, normal, arriba, derecha = Marco(m.diana)
    local ped = PlayerPedId()

    -- A la raya de tiro, andando, y mirando a la diana.
    local raya = centro + vector3(normal.x, normal.y, 0.0) * C.distanciaTiro
    local suelo = GetEntityCoords(ped).z
    local rumbo = GetHeadingFromVector_2d(-normal.x, -normal.y)
    TaskGoStraightToCoord(ped, raya.x, raya.y, suelo, 1.0, 3000, rumbo, 0.15)
    local t = Ahora()
    while Ahora() - t < 3000 and #(vector2(GetEntityCoords(ped).x, GetEntityCoords(ped).y) - vector2(raya.x, raya.y)) > 0.25 do
        Wait(50)
        if not Dardos.apuntando then return end
    end
    ClearPedTasks(ped)
    SetEntityHeading(ped, rumbo)
    FreezeEntityPosition(ped, true)

    CargarAnim()
    TaskPlayAnim(ped, DICC, 'throw_idle_a', 4.0, -4.0, -1, 49, 0.0, false, false, false)

    lib.requestModel(DARDO, 3000)
    dardoMano = CreateObject(DARDO, 0.0, 0.0, 0.0, false, false, false)
    SetEntityCollision(dardoMano, false, false)
    AttachEntityToEntity(dardoMano, ped, GetPedBoneIndex(ped, 57005), 0.1, 0.02, -0.02, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    -- La cámara, por encima del hombro derecho, mirando al centro.
    local ojo = centro + normal * (C.distanciaTiro - 0.25) + derecha * 0.22 + arriba * 0.08
    camara = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', ojo.x, ojo.y, ojo.z, 0.0, 0.0, 0.0, 34.0, false, 2)
    PointCamAtCoord(camara, centro.x, centro.y, centro.z)
    SetCamActive(camara, true)
    RenderScriptCams(true, true, 500, true, true)
end

--- Un número al azar con forma de campana (Box-Muller).
local function Campana()
    local u1, u2 = math.max(1e-6, math.random()), math.random()
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
end

local function Lanzar(u, v)
    lanzado = Ahora()
    local ped = PlayerPedId()
    TaskPlayAnim(ped, DICC, 'throw_overlay', 8.0, -4.0, 900, 48, 0.0, false, false, false)
    CreateThread(function()
        -- Medido en el juego: a los 0,1 s de throw_overlay el brazo ya está
        -- estirado; soltarlo después parecía que el dardo salía tarde.
        Wait(90)
        SoltarDardoMano()
        TriggerServerEvent('origen_games:dardos:s:lanzar', u, v)
        Wait(600)
        if Dardos.apuntando then
            TaskPlayAnim(ped, DICC, 'throw_idle_a', 4.0, -4.0, -1, 49, 0.0, false, false, false)
            local m = Dardos.mesa
            if m and m.dardo < C.dardosPorTurno and DoesEntityExist(ped) then
                dardoMano = CreateObject(DARDO, 0.0, 0.0, 0.0, false, false, false)
                SetEntityCollision(dardoMano, false, false)
                AttachEntityToEntity(dardoMano, ped, GetPedBoneIndex(ped, 57005), 0.1, 0.02, -0.02, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            end
        end
    end)
end

local function DibujarMira(centro, arriba, derecha, normal, x, y)
    local p = centro + derecha * x + arriba * y + normal * 0.015
    local r, g, b = 216, 27, 85
    DrawLine(p.x - derecha.x * 0.035, p.y - derecha.y * 0.035, p.z - derecha.z * 0.035, p.x + derecha.x * 0.035, p.y + derecha.y * 0.035, p.z + derecha.z * 0.035, r, g, b, 255)
    DrawLine(p.x - arriba.x * 0.035, p.y - arriba.y * 0.035, p.z - arriba.z * 0.035, p.x + arriba.x * 0.035, p.y + arriba.y * 0.035, p.z + arriba.z * 0.035, r, g, b, 255)
    local seg, radio = 16, 0.018
    for i = 0, seg - 1 do
        local a1, a2 = i / seg * 6.2832, (i + 1) / seg * 6.2832
        local q1 = p + derecha * (math.cos(a1) * radio) + arriba * (math.sin(a1) * radio)
        local q2 = p + derecha * (math.cos(a2) * radio) + arriba * (math.sin(a2) * radio)
        DrawLine(q1.x, q1.y, q1.z, q2.x, q2.y, q2.z, 255, 255, 255, 230)
    end
end

local BLOQUEAR = { 1, 2, 24, 25, 30, 31, 32, 33, 34, 35, 21, 22, 36, 44, 37, 140, 141, 142, 257, 263, 264, 200 }

local function FrameApuntando(ahora)
    local m = Dardos.mesa
    for _, c in ipairs(BLOQUEAR) do DisableControlAction(0, c, true) end
    HideHudAndRadarThisFrame()

    local centro, normal, arriba, derecha = Marco(m.diana)
    local P = C.pulso

    -- El ratón mueve la mira dentro de la diana.
    apunte.x = math.max(-0.3, math.min(0.3, apunte.x + GetDisabledControlNormal(0, 1) * 0.045))
    apunte.y = math.max(-0.3, math.min(0.3, apunte.y - GetDisabledControlNormal(0, 2) * 0.045))

    -- El aire: se gasta aguantando y se recupera soltando.
    local dt = GetFrameTime()
    local aguanta = IsDisabledControlPressed(0, T.aguantar.control) and not cansado
    if aguanta then
        aire = math.max(0.0, aire - dt / P.aguante)
        if aire <= 0.0 then cansado = true end
    else
        aire = math.min(1.0, aire + dt / P.recuperar)
        if cansado and aire >= 0.6 then cansado = false end
    end
    local amp = cansado and P.cansado or (aguanta and P.aguantando or P.normal)

    local s = ahora / 1000
    local sx = amp * (0.65 * math.sin(s * 1.7 + fases[1]) + 0.35 * math.sin(s * 4.1 + fases[2]))
    local sy = amp * (0.65 * math.sin(s * 1.3 + fases[3]) + 0.35 * math.sin(s * 3.7 + fases[4]))
    local x, y = apunte.x + sx, apunte.y + sy

    DibujarMira(centro, arriba, derecha, normal, x, y)

    if IsDisabledControlJustPressed(0, T.lanzar.control) and ahora - lanzado > 900 and m.dardo < C.dardosPorTurno then
        Lanzar(x + Campana() * P.dispersion, y + Campana() * P.dispersion)
    end
end

--[[ ── Lo que llega del servidor ───────────────────────────────────────────── ]]
local function EnMesa(d) return Dardos.mesa and d and d.mesa == Dardos.mesa.id end

RegisterNetEvent('origen_games:dardos:c:estado', function(m)
    if Juego.activo then return end
    local nueva = not Dardos.mesa
    Dardos.mesa = m
    Dardos.final = false
    if nueva then
        lib.hideTextUI()
        Hud(true)
    end
    EnviarHud(m)

    if m.estado == 'jugando' and m.fase == 'turno' and m.tirando == Core.Yo() and m.dardo < C.dardosPorTurno then
        if not Dardos.apuntando then CreateThread(Apuntar) end
    elseif Dardos.apuntando and (m.fase ~= 'turno' or m.tirando ~= Core.Yo()) then
        -- Deja un momento para ver dónde cayó el último dardo.
        SetTimeout(700, function()
            local a = Dardos.mesa
            if not a or a.fase ~= 'turno' or a.tirando ~= Core.Yo() then DejarDeApuntar() end
        end)
    end
end)

RegisterNetEvent('origen_games:dardos:c:turno', function(d)
    if not EnMesa(d) then return end
    if d.tirando == Core.Yo() then
        Nui.Enviar('banner', { k = 'Dardos', t = 'Tu turno', m = ('%s dardos'):format(C.dardosPorTurno), segundos = 1.6 })
        Core.Sonido('pase')
    end
end)

RegisterNetEvent('origen_games:dardos:c:cartel', function(c)
    if not Dardos.mesa or type(c) ~= 'table' then return end
    Dardos.cartel = c
    Dardos.cartelHasta = Ahora() + 1800
end)

RegisterNetEvent('origen_games:dardos:c:aviso', function(d)
    if Dardos.mesa and d then Core.Aviso(d.texto, d.tipo) end
end)

RegisterNetEvent('origen_games:dardos:c:sonido', function(tipo)
    if Dardos.mesa and type(tipo) == 'string' then Core.Sonido(tipo) end
end)

RegisterNetEvent('origen_games:dardos:c:dardo', function(d)
    if type(d) ~= 'table' or type(d.diana) ~= 'table' then return end
    Clavar(d)
end)

RegisterNetEvent('origen_games:dardos:c:recoger', function(d)
    if type(d) == 'table' then Recoger(d.mesa) end
end)

RegisterNetEvent('origen_games:dardos:c:empieza', function(d)
    if not EnMesa(d) then return end
    Nui.Enviar('banner', { k = 'Dardos', t = '¡Empieza la partida!', m = 'El orden de tiro es al azar', segundos = 2.2 })
    Core.Sonido('cuenta')
end)

local function Salir()
    DejarDeApuntar()
    Dardos.mesa = nil
    Dardos.cartel = nil
    Hud(false)
end

RegisterNetEvent('origen_games:dardos:c:final', function(d)
    if not EnMesa(d) then return end
    DejarDeApuntar()
    Dardos.final = true
    Nui.Enviar('final', d)
    local id = d.mesa
    SetTimeout((d.segundos or 10) * 1000, function()
        if Dardos.mesa and Dardos.mesa.id == id and Dardos.final then Salir() end
    end)
end)

RegisterNetEvent('origen_games:dardos:c:fuera', function(d)
    if not EnMesa(d) or Dardos.final then return end
    if d.motivo then Core.Aviso(d.motivo, 'mal') end
    Salir()
end)

--[[ ── Los hilos ───────────────────────────────────────────────────────────── ]]

-- Buscar dianas y el [E], fuera de una mesa.
CreateThread(function()
    local texto
    local ultimaPregunta, ultimaBusqueda = 0, 0
    while true do
        local espera = 600
        local ped = PlayerPedId()
        local libre = not Juego.activo and not Dardos.mesa and not IsPedInAnyVehicle(ped, false) and not IsEntityDead(ped)

        -- Buscar objetos cuesta: cerca de una diana se mira la tecla en cada
        -- fotograma, pero la diana solo se vuelve a buscar cada 300 ms.
        if not libre then
            Dardos.diana = nil
        elseif Ahora() - ultimaBusqueda > 300 or not Dardos.diana then
            ultimaBusqueda = Ahora()
            Dardos.diana = BuscarDiana(ped)
        end

        if Dardos.diana then
            espera = 0
            local ahora = Ahora()
            if ahora - ultimaPregunta > 1200 then
                ultimaPregunta = ahora
                local d = Dardos.diana
                CreateThread(function() Dardos.resumen = lib.callback.await('origen_games:dardos:mesa', false, d) end)
            end

            local r = Dardos.resumen
            local nuevo
            if r and r.estado == 'espera' and r.jugadores < r.max then
                nuevo = ('[E] Unirse a la partida de %s (%s · %s/%s)'):format(r.anfitrion or '?', r.modoNombre, r.jugadores, r.max)
            elseif r then
                nuevo = 'Partida de dardos en juego'
            else
                nuevo = '[E] Jugar a los dardos'
            end
            if nuevo ~= texto then
                texto = nuevo
                lib.showTextUI(texto)
            end

            if IsControlJustPressed(0, T.entrar.control) then
                local d = Dardos.diana
                if r and r.estado == 'espera' then
                    local res = lib.callback.await('origen_games:dardos:unirse', false, r.id)
                    if res and not res.ok and res.mensaje then Core.Aviso(res.mensaje, 'mal') end
                elseif not r then
                    local opciones = {}
                    for _, m in ipairs(C.modos) do
                        opciones[#opciones + 1] = { id = m.id, nombre = m.nombre, detalle = m.texto }
                    end
                    lib.hideTextUI()
                    texto = nil
                    local votando = true
                    -- La votación no se cierra sola al acabarse el tiempo.
                    SetTimeout(30000, function() if votando then votando = false Core.CerrarVotacion() end end)
                    Core.Votacion({ titulo = 'Dardos', texto = '¿A qué jugamos?', opciones = opciones, segundos = 30, saltar = true }, function(id)
                        votando = false
                        if not id then return end
                        local res = lib.callback.await('origen_games:dardos:crear', false, { diana = d, modo = id })
                        if res and not res.ok and res.mensaje then Core.Aviso(res.mensaje, 'mal') end
                    end)
                end
            end
        elseif texto then
            texto = nil
            Dardos.resumen = nil
            lib.hideTextUI()
        end
        Wait(espera)
    end
end)

-- En una mesa: apuntar, empezar, salir y el HUD.
CreateThread(function()
    local sujetando, ultimoTick = nil, 0
    while true do
        local m = Dardos.mesa
        if not m then
            Wait(400)
        else
            local ahora = Ahora()
            if Dardos.apuntando and m.fase == 'turno' then FrameApuntando(ahora) end

            -- Empezar (quien abrió la mesa).
            if m.estado == 'espera' and m.anfitrion == Core.Yo() and IsControlJustPressed(0, T.entrar.control) then
                CreateThread(function()
                    local res = lib.callback.await('origen_games:dardos:empezar', false)
                    if res and not res.ok and res.mensaje then Core.Aviso(res.mensaje, 'mal') end
                end)
            end

            -- Mantener F para dejar la mesa.
            DisableControlAction(0, T.salir.control, true)
            if IsDisabledControlPressed(0, T.salir.control) and not Dardos.final then
                sujetando = sujetando or ahora
                local p = math.min(1.0, (ahora - sujetando) / 1500)
                Nui.Enviar('abandonando', { progreso = p })
                if p >= 1.0 then
                    sujetando = nil
                    Nui.Enviar('abandonando', { progreso = 0 })
                    TriggerServerEvent('origen_games:dardos:s:salir')
                end
            elseif sujetando then
                sujetando = nil
                Nui.Enviar('abandonando', { progreso = 0 })
            end

            if ahora - ultimoTick > 250 and not Dardos.final then
                ultimoTick = ahora
                Nui.Enviar('tick', {
                    quedan = m.fase == 'turno' and math.max(0, m.quedan - math.floor((ahora - (m.recibido or ahora)) / 1000)) or nil,
                    ficha = Ficha(),
                    cartel = Cartel(),
                })
            end
            Wait(0)
        end
    end
end)

-- Guardar cuándo llegó el estado, para contar el reloj del turno.
AddEventHandler('origen_games:dardos:c:estado', function(m)
    if type(m) == 'table' then m.recibido = Ahora() end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    RecogerTodo()
    if Dardos.apuntando then
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, false)
        ClearPedTasks(ped)
        SoltarDardoMano()
        if camara then RenderScriptCams(false, false, 0, true, true) DestroyCam(camara, false) end
    end
    if Dardos.diana then lib.hideTextUI() end
end)
