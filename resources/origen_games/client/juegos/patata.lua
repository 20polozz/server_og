--[[ ── Patata caliente · el cliente ─────────────────────────────────────────

     Aquí no se decide nada: el servidor dice quién lleva cada patata y cuánto
     aprieta su mecha. Este cliente pide pasarla (al tocar a alguien) o
     lanzarla (tecla), y pinta lo que se ve y se oye: el marcador rosa sobre la
     cabeza del portador, la patata en su mano, el pitido de la mecha y la
     explosión de mentira.

     Lo que se ve y se oye va en un hilo propio y no en `Frame`: el núcleo no
     llama a `Frame` mientras se mira la partida, y quien ha explotado también
     tiene que oír la mecha de los que quedan. Todo lo que se crea es local
     (nada de entidades de red) y se quita por cualquier camino de salida. ]]

local P = Config.Juegos.patata
local J = P.Juego
local T = P.Teclas
local ID = 'patata'

local M = {}
local st = {}

--- Modelos para la patata en la mano, por orden de preferencia. Se usa el
--- primero que exista en el juego; si ninguno, solo el marcador.
local MODELOS = { 'prop_bomb_01', 'v_res_fa_potato', 'prop_food_bs_chips', 'prop_cs_burger_01' }
local modeloMano -- nil: sin mirar todavía · false: ninguno sirve · hash

local MANO_DERECHA = 57005

--[[ ── Estado y limpieza ──────────────────────────────────────────────────── ]]

--- Borra lo que este juego ha puesto en el mundo y en el personaje. Sin Wait:
--- se llama también al parar el recurso.
local function Quitar()
    for _, obj in pairs(st.objetos or {}) do
        if obj and DoesEntityExist(obj) then
            DetachEntity(obj, false, false)
            DeleteEntity(obj)
        end
    end
    st.objetos = {}
    if modeloMano then SetModelAsNoLongerNeeded(modeloMano) end
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    st.multiplicador = 1.0
    StopGameplayCamShaking(true)
end

local function Reset()
    if st.objetos then Quitar() end
    st = {
        token = (st.token or 0) + 1,   -- el hilo del mundo de la partida anterior se va solo
        patatas = {},                  -- lo último que ha dicho el servidor
        portadores = {},               -- [serverId] = patata
        saltando = 0,
        objetos = {},                  -- [serverId] = objeto local en su mano
        pitidos = {},                  -- [id de patata] = próximo pitido (ms)
        vuelos = {},                   -- lanzamientos en el aire, solo para verse
        bloqueo = {},                  -- [serverId] = hasta cuándo no se la puedo devolver
        lanzarHasta = 0,
        lanzarTotal = J.enfriamientoLanzar,
        proximoContacto = 0,
        proximoBlanco = 0,
        blanco = nil,
        multiplicador = 1.0,
    }
end
Reset()

local function EsMio() return Juego.activo and Juego.juego == ID end
local function EnJuego() return EsMio() and Juego.fase == 'juego' end

local function EsPortador()
    return EnJuego() and not Juego.eliminado and st.portadores[Core.Yo()] ~= nil
end

--- Si a este jugador (fila del marcador) se le puede dar la patata.
local function PuedeRecibir(fila)
    if st.portadores[fila.id] then return false end
    local hasta = st.bloqueo[fila.id]
    if hasta and Core.Ahora() < hasta then return false end
    return true
end

local function BorrarObjeto(id)
    local obj = st.objetos[id]
    if obj and DoesEntityExist(obj) then
        DetachEntity(obj, false, false)
        DeleteEntity(obj)
    end
    st.objetos[id] = nil
end

--[[ ── El mundo: marcador, patata en la mano, mecha y vuelos ─────────────── ]]

local function ModeloMano()
    if modeloMano == nil then
        modeloMano = false
        for _, nombre in ipairs(MODELOS) do
            local h = GetHashKey(nombre)
            if IsModelInCdimage(h) and IsModelValid(h) then
                modeloMano = h
                break
            end
        end
    end
    if not modeloMano then return nil end
    if not HasModelLoaded(modeloMano) then
        RequestModel(modeloMano)
        return nil
    end
    return modeloMano
end

--- La patata en la mano de cada portador que este cliente ve.
local function ObjetosEnMano()
    -- Fuera las de quien ya no la lleva.
    for id in pairs(st.objetos) do
        if not st.portadores[id] then BorrarObjeto(id) end
    end

    for id in pairs(st.portadores) do
        local ped = Core.PedDe(id)
        local obj = st.objetos[id]
        if not ped then
            if obj then BorrarObjeto(id) end
        elseif not obj or not DoesEntityExist(obj) or GetEntityAttachedTo(obj) ~= ped then
            if obj then BorrarObjeto(id) end
            local hash = ModeloMano()
            if hash then
                local c = GetEntityCoords(ped)
                obj = CreateObject(hash, c.x, c.y, c.z, false, false, false)
                if obj and obj ~= 0 then
                    SetEntityCollision(obj, false, false)
                    SetEntityCanBeDamaged(obj, false)
                    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, MANO_DERECHA),
                        0.13, 0.03, -0.02, -60.0, 0.0, 0.0, false, false, false, false, 2, true)
                    st.objetos[id] = obj
                end
            end
        end
    end
end

local function DibujarPortador(p, ped, ahora, yo)
    local c = GetEntityCoords(ped)
    local u = p.urgencia or 0.0

    -- El marcador: de rosa a rojo según aprieta; en los últimos segundos, parpadea.
    local encendido = not p.final or math.floor(ahora / 120) % 2 == 0
    if encendido then
        local g = math.floor(90 - 70 * u)
        local b = math.floor(150 - 120 * u)
        DrawMarker(0, c.x, c.y, c.z + 1.35, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.38, 0.38, 0.38, 255, g, b, 215, true, false, 2, true, nil, nil, false)
    end
    -- Un resplandor caliente alrededor, más fuerte cuanto más aprieta.
    DrawLightWithRange(c.x, c.y, c.z + 0.2, 255, 90, 40, 2.5, 0.6 + 2.4 * u)

    -- La mecha: de ~1,2 s entre pitidos a ~0,15 s; al final, casi continuo.
    local cuando = st.pitidos[p.id] or 0
    if ahora >= cuando then
        local intervalo = p.final and 110 or math.floor(1200 - 1050 * u)
        st.pitidos[p.id] = ahora + intervalo
        Core.Sonido('mecha', c.x, c.y, c.z + 0.5, p.portador == yo, J.alcanceMecha or 45.0)
    end
end

local function DibujarVuelos(ahora)
    for i = #st.vuelos, 1, -1 do
        local v = st.vuelos[i]
        local t = (ahora - v.inicio) / v.dura
        local de, a = Core.PedDe(v.de), Core.PedDe(v.a)
        if t >= 1.0 or not de or not a then
            table.remove(st.vuelos, i)
        else
            local o = GetEntityCoords(de)
            local d = GetEntityCoords(a)
            local x = o.x + (d.x - o.x) * t
            local y = o.y + (d.y - o.y) * t
            local z = o.z + 0.4 + (d.z - o.z) * t + math.sin(math.pi * t) * 1.4
            DrawMarker(28, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.16, 0.16, 0.16, 255, 130, 40, 235, false, false, 2, false, nil, nil, false)
        end
    end
end

local function HiloMundo()
    local mio = st.token
    CreateThread(function()
        while EsMio() and st.token == mio do
            local ahora = Core.Ahora()
            local yo = Core.Yo()

            if Juego.fase == 'juego' then
                ObjetosEnMano()
                for _, p in ipairs(st.patatas) do
                    local ped = Core.PedDe(p.portador)
                    if ped then DibujarPortador(p, ped, ahora, yo) end
                end
                DibujarVuelos(ahora)
            end

            Wait(0)
        end
        -- Se ha acabado la partida o la ronda cambió de hilo: nada colgando.
        if st.token == mio then Quitar() end
    end)
end

--[[ ── Pasarla y lanzarla ───────────────────────────────────────────────── ]]

--[[ A quién se la lanzaría ahora: el jugador vivo más cerca de la línea de la
     mira, a tiro y sin pared en medio. El servidor vuelve a mirar distancia y
     rumbo con sus posiciones. ]]
local function BuscarBlanco(ped, yo)
    local cam = GetFinalRenderedCamCoord()
    local dir = Core.Direccion(GetFinalRenderedCamRot(2))
    local mio = GetEntityCoords(ped)
    local mejor, mejorPerp

    for _, fila in ipairs(Juego.marcador or {}) do
        if fila.vivo and fila.id ~= yo and PuedeRecibir(fila) then
            local otro = Core.PedDe(fila.id)
            if otro then
                local pos = GetEntityCoords(otro)
                local dist = #(pos - mio)
                if dist <= J.alcanceLanzar and dist > 0.3 then
                    local v = pos - cam
                    local t = v.x * dir.x + v.y * dir.y + v.z * dir.z
                    if t > 0.0 then
                        local perp = #(pos - (cam + dir * t))
                        if perp <= 1.1 + dist * 0.08 and (not mejorPerp or perp < mejorPerp)
                            and HasEntityClearLosToEntity(ped, otro, 17) then
                            mejor, mejorPerp = { id = fila.id, nombre = fila.nombre, dist = dist }, perp
                        end
                    end
                end
            end
        end
    end
    return mejor
end

local function Lanzar(ped, ahora)
    local b = st.blanco
    if not b or ahora < st.lanzarHasta then return end

    local otro = Core.PedDe(b.id)
    if not otro then return end

    --[[ El servidor mira el rumbo del personaje, no la cámara: se le gira hacia
         el objetivo y se deja un momento para que ese giro llegue antes que
         la petición. ]]
    local d = GetEntityCoords(otro) - GetEntityCoords(ped)
    SetEntityHeading(ped, GetHeadingFromVector_2d(d.x, d.y))

    -- Bloqueo provisional hasta que conteste el servidor.
    st.lanzarHasta = ahora + 1500
    st.lanzarTotal = 1.5

    local mio, objetivo = st.token, b.id
    CreateThread(function()
        Wait(400)
        if not EnJuego() or st.token ~= mio or not EsPortador() then return end
        TriggerServerEvent('origen_games:patata:s:lanzar', objetivo)
    end)
end

--[[ ── Ganchos del núcleo ─────────────────────────────────────────────────── ]]
function M.Empezar()
    Reset()
    HiloMundo()
end

function M.AntesDeRonda()
    Reset()
    HiloMundo()
end

function M.FinRonda()
    st.patatas, st.portadores, st.saltando = {}, {}, 0
    st.vuelos, st.blanco = {}, nil
    Quitar()
end

function M.Eliminado()
    st.blanco = nil
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    st.multiplicador = 1.0
end

function M.Salir()
    st.token = (st.token or 0) + 1
    st.patatas, st.portadores, st.vuelos, st.blanco = {}, {}, {}, nil
    Quitar()
end
M.Restaurar = M.Salir

function M.Frame(ahora)
    local ped = PlayerPedId()

    -- La E es de lanzar; y sin puñetazos, que aquí se juega a tocar.
    DisableControlAction(0, T.lanzar.control, true)
    DisableControlAction(0, 51, true)
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true)
    DisableControlAction(0, 140, true)
    DisableControlAction(0, 141, true)
    DisableControlAction(0, 142, true)
    DisableControlAction(0, 257, true)
    DisableControlAction(0, 263, true)
    DisablePlayerFiring(PlayerId(), true)

    if not EsPortador() then
        st.blanco = nil
        return
    end

    -- Pasarla tocando: basta con llegar hasta alguien.
    if ahora >= st.proximoContacto then
        st.proximoContacto = ahora + 100
        local fila, _, d = Core.MasCercano(GetEntityCoords(ped), PuedeRecibir)
        if fila and d and d <= J.alcancePase then
            st.proximoContacto = ahora + 400
            TriggerServerEvent('origen_games:patata:s:pasar', fila.id)
        end
    end

    if ahora >= st.proximoBlanco then
        st.proximoBlanco = ahora + 100
        st.blanco = BuscarBlanco(ped, Core.Yo())
    end

    if IsDisabledControlJustPressed(0, T.lanzar.control) then Lanzar(ped, ahora) end
end

function M.Lento()
    if not EsMio() then return end

    -- Nadie se cansa: la patata no espera a que recuperes el aliento.
    if not Juego.eliminado then RestorePlayerStamina(PlayerId(), 1.0) end

    local quiero = EsPortador() and (J.velocidadPortador or 1.0) or 1.0
    if st.multiplicador ~= quiero then
        SetRunSprintMultiplierForPlayer(PlayerId(), quiero)
        st.multiplicador = quiero
    end
end

--[[ ── Lo que llega del servidor ──────────────────────────────────────────── ]]
RegisterNetEvent('origen_games:patata:c:mecha', function(d)
    if not EsMio() or type(d) ~= 'table' then return end
    local ahora = Core.Ahora()
    local yo = Core.Yo()

    local portadores, bloqueo, lista = {}, {}, {}
    for _, p in ipairs(type(d.patatas) == 'table' and d.patatas or {}) do
        p.portador = tonumber(p.portador)
        if p.portador then
            lista[#lista + 1] = p
            portadores[p.portador] = p
            local libre = tonumber(p.libreEn) or 0
            if p.portador == yo and tonumber(p.ultimoDe) and libre > 0 then
                bloqueo[tonumber(p.ultimoDe)] = ahora + libre
            end
        end
    end

    local antes = st.portadores[yo] ~= nil
    st.patatas = lista
    st.portadores = portadores
    st.bloqueo = bloqueo
    st.saltando = tonumber(d.saltando) or 0

    -- Al soltarla o recibirla, la velocidad cambia ya, sin esperar al Lento.
    if antes ~= (portadores[yo] ~= nil) then
        st.blanco = nil
        M.Lento()
    end
end)

RegisterNetEvent('origen_games:patata:c:lanzado', function(d)
    if not EsMio() or type(d) ~= 'table' then return end
    local segundos = tonumber(d.enfriamiento) or 0
    st.lanzarHasta = Core.Ahora() + segundos * 1000
    st.lanzarTotal = d.ok and J.enfriamientoLanzar or math.max(segundos, 0.1)
    if not d.ok and d.texto then Core.Aviso(d.texto, 'mal') end
end)

RegisterNetEvent('origen_games:patata:c:vuelo', function(d)
    if not EnJuego() or type(d) ~= 'table' then return end
    st.vuelos[#st.vuelos + 1] = { de = tonumber(d.de), a = tonumber(d.a), inicio = Core.Ahora(), dura = 380 }
end)

--[[ La explosión de mentira: partículas, sonido (lo manda el servidor) y un
     temblor a quien esté cerca. Nada de AddExplosion: el anticheat la vigila. ]]
RegisterNetEvent('origen_games:patata:c:explosion', function(d)
    if not EsMio() or type(d) ~= 'table' then return end
    local x, y, z = tonumber(d.x), tonumber(d.y), tonumber(d.z)
    if not (x and y and z) then return end

    local id = tonumber(d.id)
    if id then
        st.portadores[id] = nil
        BorrarObjeto(id)
    end

    local mio = st.token
    RequestNamedPtfxAsset('core')
    local hasta = GetGameTimer() + 1000
    while not HasNamedPtfxAssetLoaded('core') and GetGameTimer() < hasta do Wait(0) end
    if not EsMio() or st.token ~= mio then return end

    if HasNamedPtfxAssetLoaded('core') then
        UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedAtCoord('exp_grd_grenade_lod', x, y, z - 0.4, 0.0, 0.0, 0.0, 1.2, false, false, false)
    end

    local cam = GetFinalRenderedCamCoord()
    local dist = #(cam - vector3(x, y, z))
    if dist < 30.0 and not Espectador.activo then
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', math.max(0.15, 1.0 - dist / 30.0))
    end
end)

--[[ ── El HUD ─────────────────────────────────────────────────────────────── ]]

--- El portador más cercano a mí (que no sea yo): nombre y distancia.
local function PortadorCercano()
    local yo = Core.Yo()
    local mio = GetEntityCoords(PlayerPedId())
    local mejor, mejorD
    for _, p in ipairs(st.patatas) do
        if p.portador ~= yo then
            local ped = Core.PedDe(p.portador)
            if ped then
                local d = #(GetEntityCoords(ped) - mio)
                if not mejorD or d < mejorD then mejor, mejorD = p, d end
            end
        end
    end
    return mejor, mejorD
end

function M.Ficha()
    if Juego.eliminado then return nil end
    local yo = Juego.yo or {}
    local puntos = yo.puntos or 0

    if EsPortador() then
        local p = st.portadores[Core.Yo()] or {}
        local quedan = Core.Resta(st.lanzarHasta)
        local total = st.lanzarTotal or J.enfriamientoLanzar
        local carga = (quedan > 0 and total > 0) and Util.Acotar(1 - quedan / total, 0.0, 1.0) or nil
        local b = st.blanco

        return {
            tono = 'caza', icono = 'patata',
            rol = '¡La llevas!',
            nombre = 'Pásala ya',
            renglon = p.final and '¡Va a explotar!' or 'La mecha arde...',
            puntos = puntos,
            vida = { tipo = 'progreso', etiqueta = 'Calor', pct = math.floor((p.urgencia or 0) * 100), cifra = p.final and '¡YA!' or nil },
            acciones = {
                {
                    id = 'lanzar', tecla = T.lanzar.texto,
                    nombre = b and ('Lanzar a ' .. b.nombre) or 'Lanzar',
                    extra = quedan > 0 and (quedan .. 's') or nil,
                    apagada = quedan > 0 or not b,
                    carga = carga,
                },
                { id = 'tocar', tecla = 'Toque', nombre = 'Tócale a alguien', extra = (tostring(J.alcancePase):gsub('%.', ',')) .. ' m' },
            },
            pista = (b and quedan <= 0) and {
                tecla = T.lanzar.texto, texto = 'Lanzar a', destacado = b.nombre,
                detalle = ('%d m'):format(math.floor(b.dist + 0.5)),
            } or nil,
        }
    end

    local ficha = {
        tono = 'neutro', icono = 'patata',
        rol = 'Superviviente',
        puntos = puntos,
    }

    if Juego.fase ~= 'juego' then
        ficha.nombre = 'Prepárate'
        ficha.renglon = 'La patata está a punto de salir'
        return ficha
    end

    local p, d = PortadorCercano()
    if p then
        ficha.nombre = 'Huye de ' .. (p.nombre or 'la patata')
        ficha.renglon = ('a %d m%s'):format(math.floor(d + 0.5), p.final and ' · ¡va a explotar!' or '')
    elseif st.saltando > 0 then
        ficha.nombre = 'Que no te toque'
        ficha.renglon = 'La patata está saltando...'
    else
        ficha.nombre = 'Que no te la pasen'
        ficha.renglon = 'Aléjate de quien la lleve'
    end
    return ficha
end

function M.Cartel()
    if not EsMio() or Juego.eliminado then return nil end

    if Juego.fase == 'preparacion' then
        return {
            k = ('Ronda %d de %d'):format(Juego.ronda or 0, Juego.rondas or 0),
            t = 'No te la quedes',
            m = 'Alguien va a empezar con la patata. Tócale a otro para pasársela antes de que explote.',
            cifra = Core.Resta(Juego.finFase),
        }
    end

    if EsPortador() then
        local p = st.portadores[Core.Yo()]
        if p and p.final then
            return { k = '¡Patata!', t = '¡Va a explotar!', m = '¡Pásala YA!', tipo = 'fuera' }
        end
    end
    return nil
end

RegistrarJuego(ID, M)
