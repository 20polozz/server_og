--[[ ═══════════════════════════════════════════════════════════════════════
     EL PRÁCTICO (lado cliente)

     Una sesión = un examen de shared/examenes.lua. Cada fotograma se vigila
     la etapa que toca y, además, todo lo que no es una etapa pero cuenta:
     velocidad, intermitentes, cinturón, golpes, atropellos, salirse de la
     calzada y los stops.

     Los fallos que restan se juntan en `pend` y viajan con el siguiente
     aviso al servidor; los que suspenden de golpe (atropello, destrozar el
     coche, dejar el volante, tiempo) se mandan en el momento.
   ═══════════════════════════════════════════════════════════════════════ ]]

local S = nil            -- la sesión en curso
local P = Config.Practico

local NOMBRES = {
    preparar = 'Comprobaciones', punto = 'En ruta', emergencia = 'Frenazo',
    aparcar = 'Aparcar', fin = 'Fin',
}

--[[ Las marcas en la carretera son de origen_markers (el cartel con la
     distancia, el mismo de las carreras): se ve de lejos y por encima del
     tráfico, que un círculo pintado en el suelo no. Como mucho dos a la vez:
     el punto que toca y, más pequeño, el siguiente. ]]
local marcas = {}

local function HayMarkers() return GetResourceState('origen_markers') == 'started' end

local function QuitarMarcas()
    for _, id in ipairs(marcas) do
        pcall(function() exports.origen_markers:Remove(id) end)
    end
    marcas = {}
end

local function PonerMarca(pos, z, rotulo, lejos)
    local ok, id = pcall(function()
        return exports.origen_markers:Create({
            coords = vec3(pos.x, pos.y, z), groundZ = z, type = 'checkpoint',
            label = rotulo, drawDistance = lejos, fadeDistance = lejos * 0.8,
        })
    end)
    if ok and id then marcas[#marcas + 1] = id end
end

--- Borra lo del examen: la chincheta del punto, el recorrido y las marcas.
local function MapaFuera()
    OrigenMapa.Quitar('objetivo')
    OrigenMapa.PonerVarios('recorrido', {})
    QuitarMarcas()
end

-- ── Utilidades ────────────────────────────────────────────────────────────

local function Veh()
    if not S then return nil end
    local veh = NetworkDoesNetworkIdExist(S.vehNet) and NetToVeh(S.vehNet) or 0
    if veh ~= 0 and DoesEntityExist(veh) then return veh end
    return nil
end

local function Examinador()
    if not S or not S.pedNet then return nil end
    local ped = NetworkDoesNetworkIdExist(S.pedNet) and NetToPed(S.pedNet) or 0
    if ped ~= 0 and DoesEntityExist(ped) then return ped end
    return nil
end

local function Texto(t)
    t = tostring(t or '')
    return (t:gsub('{nombre}', S and S.alumno or ''))
end

--- El examinador dice algo (el cuadro de arriba).
local function Dice(texto, tono)
    if not S or not texto then return end
    A.Nui('dice', { quien = S.examinador, texto = Texto(texto), tono = tono })
    PlaySoundFrontend(-1, 'Menu_Accept', 'Phone_SoundSet_Default', true)
end

--- Un fallo que resta puntos. `clave` evita contarlo dos veces en la etapa.
local function Penal(motivo, puntos, clave)
    if not S then return end
    clave = clave or motivo
    if S.e.penales[clave] then return end
    S.e.penales[clave] = true
    S.pend[#S.pend + 1] = { motivo = motivo, puntos = puntos }
    S.historial = S.historial or {}
    S.historial[#S.historial + 1] = { motivo = motivo, puntos = puntos, etapa = S.i }
    S.restado = S.restado + puntos
    A.Nui('penal', { motivo = motivo, puntos = puntos })
    PlaySoundFrontend(-1, 'CHECKPOINT_MISSED', 'HUD_MINI_GAME_SOUNDSET', true)
end

local function Suspender(motivo)
    if not S or S.fin then return end
    S.fin = true
    local pend = S.pend
    S.pend = {}
    TriggerServerEvent('origen_autoescuela:practico:fallo', motivo, pend)
    -- Si el servidor ya no tenía sesión, no contesta: no dejar el HUD colgado.
    local yo = S
    SetTimeout(8000, function()
        if S == yo then
            S, A.practico = nil, nil
            MapaFuera()
            A.Nui('finPractico')
        end
    end)
end

local function KmH(veh) return GetEntitySpeed(veh) * 3.6 end

--- El suelo del punto, para que la marca no quede enterrada ni flotando.
local function Suelo(pos)
    local z = A.Suelo(pos.x, pos.y, pos.z + 5.0)
    return z or pos.z
end

--[[ Sitios donde NO cuenta «te sales de la calzada».

     IsPointOnRoad dice que no hay calzada en el parking de la autoescuela ni
     en algunos callejones y carriles de servicio por los que pasa la ruta
     (medido el 20/09: las tres plazas de salida, la de aparcar y dos puntos
     del circuito B). Sin esto, el examen resta puntos por ir exactamente
     donde él mismo manda, que es lo que veia el alumno como «me quita puntos
     sin motivo».

     Tres perdones:
       · el recinto de la autoescuela, donde se sale y se aparca;
       · los alrededores del punto que toca ahora;
       · y cualquier sitio con un nodo de carretera a menos de 6 m, que es un
         camino del juego aunque no sea asfalto pintado. El nodo se pregunta
         como mucho dos veces por segundo: es lo caro de los tres. ]]
local nodoCerca, nodoCuando = false, 0

local function Permitido(pos)
    if Auto.Plano(pos, Config.Escuela.salidas[1]) < 45.0 then return true end
    local pl = S and S.plaza
    if pl and pl.x and Auto.Plano(pos, vec3(pl.x, pl.y, pl.z)) < 30.0 then return true end

    local e = S and S.etapas[S.i]
    local o = e and (e.pos or ((e.tipo == 'aparcar' or e.tipo == 'fin') and Config.Aparcamiento.centro))
    if o and Auto.Plano(pos, o) < ((e.radio or 12.0) + 15.0) then return true end

    local ahora = GetGameTimer()
    if ahora - nodoCuando > 500 then
        nodoCuando = ahora
        local hay, nodo = GetClosestVehicleNodeWithHeading(pos.x, pos.y, pos.z, 1, 3.0, 0)
        nodoCerca = (hay == 1 or hay == true) and Auto.Plano(pos, nodo) < 6.0
    end
    return nodoCerca
end

-- ── Marcas en el mundo ────────────────────────────────────────────────────

local ROSA = { 216, 27, 85 }
local VERDE = { 60, 220, 120 }

local function Columna(pos, radio, color, alto)
    local z = S.e.zSuelo or pos.z
    DrawMarker(1, pos.x, pos.y, z - 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        radio * 2.0, radio * 2.0, alto or 4.0, color[1], color[2], color[3], 70, false, false, 2, false, nil, nil, false)
    DrawMarker(25, pos.x, pos.y, z + 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        radio * 2.0, radio * 2.0, 1.0, 220, 221, 224, 150, false, false, 2, false, nil, nil, false)
    DrawMarker(2, pos.x, pos.y, z + 5.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0,
        3.0, 3.0, 3.0, color[1], color[2], color[3], 220, true, true, 2, false, nil, nil, false)
end

--- La plaza de aparcamiento: un rectángulo pintado en el suelo.
--[[ La plaza donde hay que aparcar: la MISMA de la que se salió, que manda
     el servidor al arrancar. Config.Aparcamiento queda de red de seguridad
     por si llega una sesión vieja sin plaza. ]]
local function LaPlaza()
    local p = S and S.plaza
    if p and p.x then
        return vec3(p.x + 0.0, p.y + 0.0, p.z + 0.0), (p.w or 0.0) + 0.0
    end
    local c = Config.Aparcamiento
    return c.centro, c.rumbo
end

--[[ La plaza, a la medida del vehículo.

     Las de config son las de un coche. El camión del examen mide 8,05 m y no
     cabía en una plaza de 6,5: el alumno no podía aprobar (medido el 20/09).
     Así que la plaza crece con el vehículo y el listón sigue siendo el mismo
     para todos: un palmo por lado.

     Van AQUÍ, antes de quien las usa: una función local declarada más abajo
     no existe para las de arriba —se resuelve como global y sale nil— y eso
     tumbaba el dibujo de la plaza entero (20/09). ]]
local function Medidas(veh)
    local c = Config.Aparcamiento
    if not veh or veh == 0 then return c.ancho, c.largo end
    if S and S.plazaAncho then return S.plazaAncho, S.plazaLargo end
    local mn, mx = GetModelDimensions(GetEntityModel(veh))
    local ancho = math.max(c.ancho, (mx.x - mn.x) + 1.0)
    local largo = math.max(c.largo, (mx.y - mn.y) + 1.2)
    if S then S.plazaAncho, S.plazaLargo = ancho, largo end
    return ancho, largo
end

local function EnPlaza(veh)
    local centro, rumbo = LaPlaza()
    local anchoP, largoP = Medidas(veh)
    local p = GetEntityCoords(veh)
    local h = math.rad(rumbo)
    local fx, fy = -math.sin(h), math.cos(h)
    local rx, ry = p.x - centro.x, p.y - centro.y
    local largo = rx * fx + ry * fy
    local ancho = rx * fy - ry * fx
    return math.abs(largo) <= largoP / 2 + 0.8 and math.abs(ancho) <= anchoP / 2 + 0.6
end

--[[ La plaza, pintada en el suelo como una plaza de verdad.

     Antes eran cuatro DrawLine: un hilo de un píxel que desde el asiento del
     coche no se ve (20/09, el usuario: «debería haber un cuadrado en el suelo
     para ver el punto bien»). Ahora se pinta el rectángulo ENTERO con
     triángulos —suelo translúcido, para que se siga viendo el asfalto— y un
     bordillo grueso alrededor. Va a ras de suelo, así que hay que dibujarlo
     por las dos caras: un triángulo solo se ve por delante, y desde el coche
     se mira desde arriba. ]]
local function Banda(a, b, ancho, dx, dy, r, g, bl, al)
    local hx, hy = dx * ancho / 2, dy * ancho / 2
    local p1 = vec3(a.x + hx, a.y + hy, a.z)
    local p2 = vec3(b.x + hx, b.y + hy, b.z)
    local p3 = vec3(b.x - hx, b.y - hy, b.z)
    local p4 = vec3(a.x - hx, a.y - hy, a.z)
    DrawPoly(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, p3.x, p3.y, p3.z, r, g, bl, al)
    DrawPoly(p1.x, p1.y, p1.z, p3.x, p3.y, p3.z, p2.x, p2.y, p2.z, r, g, bl, al)
    DrawPoly(p1.x, p1.y, p1.z, p3.x, p3.y, p3.z, p4.x, p4.y, p4.z, r, g, bl, al)
    DrawPoly(p1.x, p1.y, p1.z, p4.x, p4.y, p4.z, p3.x, p3.y, p3.z, r, g, bl, al)
end

local function Plaza(zForzada, dentroForzado, vehForzado)
    local centro, rumbo = LaPlaza()
    local anchoP, largoP = Medidas(vehForzado or Veh())
    local h = math.rad(rumbo)
    local fx, fy = -math.sin(h), math.cos(h)
    local dx, dy = fy, -fx
    local z = (zForzada or (S and S.e and S.e.zPlaza) or centro.z) + 0.03
    local dentro = dentroForzado
    if dentro == nil then dentro = S and S.e and S.e.dentro end
    local col = dentro and VERDE or ROSA

    local esquinas = {}
    for i, sg in ipairs({ { 1, 1 }, { 1, -1 }, { -1, -1 }, { -1, 1 } }) do
        esquinas[i] = vec3(
            centro.x + fx * (largoP / 2) * sg[1] + dx * (anchoP / 2) * sg[2],
            centro.y + fy * (largoP / 2) * sg[1] + dy * (anchoP / 2) * sg[2], z)
    end

    -- El suelo de la plaza, por las dos caras.
    local a, b, cc, d = esquinas[1], esquinas[2], esquinas[3], esquinas[4]
    local al = dentro and 90 or 70
    DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, cc.x, cc.y, cc.z, col[1], col[2], col[3], al)
    DrawPoly(a.x, a.y, a.z, cc.x, cc.y, cc.z, b.x, b.y, b.z, col[1], col[2], col[3], al)
    DrawPoly(a.x, a.y, a.z, cc.x, cc.y, cc.z, d.x, d.y, d.z, col[1], col[2], col[3], al)
    DrawPoly(a.x, a.y, a.z, d.x, d.y, d.z, cc.x, cc.y, cc.z, col[1], col[2], col[3], al)

    -- Y el bordillo: una banda de 25 cm por lado, bien visible.
    for i = 1, 4 do
        local p, q = esquinas[i], esquinas[i % 4 + 1]
        local ex, ey = q.x - p.x, q.y - p.y
        local largo = math.sqrt(ex * ex + ey * ey)
        if largo > 0.01 then
            Banda(p, q, 0.25, -ey / largo, ex / largo, col[1], col[2], col[3], 235)
        end
    end

    -- La flecha, un poco más alta que el techo de un camión.
    DrawMarker(2, centro.x, centro.y, z + 4.2, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0,
        2.0, 2.0, 2.0, col[1], col[2], col[3], 220, true, true, 2, false, nil, nil, false)
end

--[[ La línea del stop, pintada en el suelo (24/09).

     Los alumnos no sabían DÓNDE es «la línea»: solo había el cartel con los
     metros. Ahora hay una raya gruesa de lado a lado de la calzada, justo en
     el marcador: roja mientras falta pararse y verde en cuanto el coche se ha
     parado del todo. El rumbo de la calle sale del nodo de carretera (una
     vez por etapa); el suelo se vuelve a medir de cerca, que de lejos el
     mapa no está cargado y GetGroundZ no contesta. ]]
local function LineaStop(e, veh)
    local pos = veh and GetEntityCoords(veh)
    local d = pos and Auto.Plano(pos, e.pos) or 9999.0
    if d > 200.0 then return end
    if not S.e.rumboCalle then
        local hay, _, rumbo = GetClosestVehicleNodeWithHeading(e.pos.x, e.pos.y, e.pos.z, 1, 3.0, 0)
        S.e.rumboCalle = (hay == 1 or hay == true) and rumbo or (veh and GetEntityHeading(veh) or 0.0)
    end
    if not S.e.zLinea and d < 120.0 then S.e.zLinea = A.Suelo(e.pos.x, e.pos.y, e.pos.z + 3.0) or false end
    local z = (S.e.zLinea or S.e.zSuelo or e.pos.z) + 0.06
    local h = math.rad(S.e.rumboCalle)
    local fx, fy = -math.sin(h), math.cos(h)          -- a lo largo de la calle
    local sx, sy = fy, -fx                            -- de lado a lado
    local medio = 4.5
    local a = vec3(e.pos.x - sx * medio, e.pos.y - sy * medio, z)
    local b = vec3(e.pos.x + sx * medio, e.pos.y + sy * medio, z)
    local col = S.e.parado and VERDE or { 230, 30, 40 }
    Banda(a, b, 0.9, fx, fy, col[1], col[2], col[3], 235)
end

local function Marcar(e)
    if e.tipo == 'punto' then
        if e.stop then LineaStop(e, Veh()) end
        if S.e.conMarkers then return end      -- ya lo pinta origen_markers
        Columna(e.pos, e.radio * 0.5, e.stop and VERDE or ROSA)
        local sig = S.etapas[S.i + 1]
        if sig and sig.tipo == 'punto' then
            local z = S.e.zSig or Suelo(sig.pos)
            S.e.zSig = z
            DrawMarker(1, sig.pos.x, sig.pos.y, z - 0.5, 0, 0, 0, 0, 0, 0,
                sig.radio, sig.radio, 2.0, ROSA[1], ROSA[2], ROSA[3], 30, false, false, 2, false, nil, nil, false)
        end
    elseif e.tipo == 'aparcar' then
        Plaza()
    end
end

-- ── El mapa: el camino del examen ─────────────────────────────────────────

--[[ Una chincheta suelta no dice por donde se va, y el alumno no se conoce la
     ciudad. Asi que se marcan dos cosas:

     · el SIGUIENTE punto con `ruta = true`, que es la manivela del GPS: el
       mapa crea por debajo un blip invisible y el juego traza el camino por
       calles hasta el. Esa linea la pintan los dos mapas, el minimapa y el
       grande.
     · y el RESTO del recorrido, solo en el mapa GRANDE (`minimapa = false`),
       para ver la vuelta entera de un vistazo sin llenar el minimapa de
       conos. ]]
local function Objetivo(e)
    if e.pos then return e.pos end
    if e.tipo == 'aparcar' or e.tipo == 'fin' then return (LaPlaza()) end
    return nil
end

local function PuntoMapa(e)
    local o = Objetivo(e)
    if not o then OrigenMapa.Quitar('objetivo') return end
    -- Durante el examen el GPS es del examinador: un waypoint del alumno gana
    -- al punto del examen en los dos mapas, y la linea llevaria a su marca.
    SetWaypointOff()
    OrigenMapa.Poner('objetivo', {
        x = o.x, y = o.y, z = o.z, cat = 'eventos', icono = 'bandera',
        nombre = 'Examen de conducir · ' .. (NOMBRES[e.tipo] or 'Siguiente'),
        pulso = true, prioridad = 5, ruta = true, propio = true,
    })
end

--- Lo que queda por delante, en el mapa grande.
local function Recorrido()
    if not S then return end
    local lista = {}
    for i = S.i + 1, #S.etapas do
        local e = S.etapas[i]
        local o = Objetivo(e)
        if o then
            lista[#lista + 1] = {
                id = i, x = o.x, y = o.y, z = o.z, cat = 'eventos',
                icono = (e.tipo == 'aparcar' or e.tipo == 'fin') and 'bandera' or 'cono',
                nombre = ('Examen de conducir · %d de %d'):format(i, #S.etapas),
                minimapa = false, propio = true,
            }
        end
    end
    OrigenMapa.PonerVarios('recorrido', lista)
end

local ROTULO = { izq = '← GIRA A LA IZQUIERDA', der = '→ GIRA A LA DERECHA', recto = '↑ SIGUE RECTO' }

--- Las marcas de origen_markers de esta etapa (y fuera las de la anterior).
local function MarcasDeEtapa(e)
    QuitarMarcas()
    if not HayMarkers() then return end
    if e.tipo == 'punto' then
        S.e.conMarkers = true
        PonerMarca(e.pos, S.e.zSuelo or e.pos.z, e.stop and 'STOP · PÁRATE EN LA LÍNEA ROJA' or (ROTULO[e.giro] or ROTULO.recto), 450.0)
        local sig = S.etapas[S.i + 1]
        if sig and sig.tipo == 'punto' then
            PonerMarca(sig.pos, Suelo(sig.pos), 'DESPUÉS', 160.0)
        end
    elseif e.tipo == 'aparcar' then
        -- La plaza se sigue pintando en el suelo (hacen falta las líneas);
        -- el cartel es para encontrarla desde la otra punta de la calle.
        local c = (LaPlaza())
        PonerMarca(c, S.e.zPlaza or c.z, e.marchaAtras and 'APARCA MARCHA ATRÁS' or 'APARCA AQUÍ', 300.0)
    end
end

-- ── Empezar una etapa ─────────────────────────────────────────────────────

local function Etapa(i)
    S.i = i
    local e = S.etapas[i]
    S.e = { t0 = GetGameTimer(), penales = {}, cuenta = 0, fase = 1, vMin = 999.0 }
    if e.pos then S.e.zSuelo = Suelo(e.pos) end
    if e.tipo == 'aparcar' then S.e.zPlaza = Suelo((LaPlaza())) end
    if e.limite then S.limite = e.limite end
    Dice(e.texto)
    PuntoMapa(e)
    Recorrido()
    MarcasDeEtapa(e)
    A.Nui('etapa', { i = i, total = #S.etapas, nombre = NOMBRES[e.tipo] or e.tipo })
end

--- La etapa está hecha: avisar al servidor (en otro hilo, que espera).
local function Hecha()
    if not S or S.enviando or S.fin then return end
    S.enviando = true
    local i, e = S.i, S.etapas[S.i]
    local pend = S.pend
    S.pend = {}
    CreateThread(function()
        local r = lib.callback.await('origen_autoescuela:practico:etapa', false, i, { penal = pend })
        if not S then return end
        if r and r.ok then
            PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
            if r.fin then
                S.fin = true
                if e.bien then Dice(e.bien, 'bien') end
                return
            end
            if e.bien then Dice(e.bien, 'bien') Wait(1500) end
            if S and not S.fin then Etapa(i + 1) S.enviando = false end
        elseif r and r.fin then
            S.fin = true
        else
            S.enviando = false
            for _, p in ipairs(pend) do S.pend[#S.pend + 1] = p end
            if r and r.mensaje then Dice(r.mensaje, 'mal') end
        end
    end)
end

-- ── Cada tipo de etapa ────────────────────────────────────────────────────

local T = {}
local dt = 0.0

--- La E, aunque otro script la tenga desactivada dentro del vehículo.
local function PulsaE()
    return IsControlJustReleased(0, 38) or IsDisabledControlJustReleased(0, 38)
end

local function Cinturon()
    return LocalPlayer.state.seatbelt == true
end

function T.preparar(e, veh)
    if e.cinturon and not Cinturon() then
        S.e.aviso = 'Ponte el cinturón'
        return false
    end
    if not GetIsVehicleEngineRunning(veh) then
        S.e.aviso = nil
        A.Ayuda('motor', 'E', 'Comprobaciones y arrancar')
        if PulsaE() then
            A.QuitarAyuda('motor')
            S.e.arrancando = true
            CreateThread(function()
                local ok = lib.progressBar({
                    duration = 3500, label = 'Espejos, asiento y cinturón',
                    canCancel = false, disable = { move = true, car = true, combat = true },
                })
                local v = Veh()
                if ok and v then SetVehicleEngineOn(v, true, false, true) end
            end)
        end
        return false
    end
    A.QuitarAyuda('motor')
    return true
end

--[[ ¿Lleva puesto el intermitente de ese lado?

     Vale lo que diga la tecla de este mismo recurso (A.Intermitente, el
     estado de la palanca) o lo que devuelva el juego: 0 ninguno, 1 izquierda,
     2 derecha y 3 los dos. Los CUATRO a la vez son las de avería, no una
     señal de giro: con eso puesto no vale, que si no bastaría con dejarlas
     encendidas todo el examen. ]]
local function Senal(veh, giro)
    local quiero = giro == 'izq' and 1 or 2
    if A.Intermitente and A.Intermitente() == quiero then return true end
    return GetVehicleIndicatorLights(veh) == quiero
end

-- Parado «del todo»: un coche frenado casi nunca da 0,0 exacto.
local PARADO_KMH = 2.0
-- Parar en cualquier sitio de aquí a la línea cuenta (cola detrás de otro).
local ZONA_STOP = 25.0

--[[ Un punto del recorrido.

     ANTES (hasta el 24/09) la etapa se daba por hecha en cuanto el coche
     entraba en el radio del punto (14 m) y en ESE instante se juzgaban el
     stop y el intermitente. Pero la «línea» del stop es el propio marcador:
     el alumno llegaba rodando, se paraba en el marcador (a 0 m), ponía el
     intermitente y giraba… y el examen ya le había quitado 20 por «saltarse
     el stop» y 10 por «giro sin intermitente» 14 m antes, cuando aún iba
     rodando. Con 30 de golpe, suspenso.

     Ahora:
       · el stop vale si se para del todo en los 25 m antes de la línea (o
         encima de ella) y solo se penaliza si PASA sin haberse parado;
       · el intermitente vale si está puesto antes de EMPEZAR A GIRAR, y se
         juzga cuando el coche gira (30° desde que entró) o deja el punto
         atrás, no al entrar en el radio. ]]
function T.punto(e, veh)
    local pos = GetEntityCoords(veh)
    local d = Auto.Plano(pos, e.pos)
    local v = KmH(veh)
    S.e.dMin = math.min(S.e.dMin or 9999.0, d)

    -- El intermitente: se apunta en cuanto se ve puesto cerca del giro.
    local avisoInter
    if e.giro ~= 'recto' then
        local t = d / math.max(4.0, GetEntitySpeed(veh))   -- segundos a ojo
        if t <= P.intermitente or d <= e.radio then
            if not S.e.intermitente and Senal(veh, e.giro) then S.e.intermitente = true end
            if not S.e.intermitente then
                avisoInter = e.giro == 'izq' and 'Pon el intermitente izquierdo (tecla ←)' or 'Pon el intermitente derecho (tecla →)'
            end
        end
    end

    -- El stop: pararse del todo antes de la línea (el marcador) o en ella.
    local avisoStop
    if e.stop then
        if d <= ZONA_STOP and v <= PARADO_KMH then S.e.parado = true end
        if not S.e.parado and d <= ZONA_STOP + 15.0 then
            avisoStop = ('STOP · párate del todo en la línea roja · %d m'):format(math.floor(d))
        end
    end
    S.e.aviso = avisoStop or avisoInter

    -- Aún no ha llegado al punto.
    if d <= e.radio and not S.e.rumboEntrada then S.e.rumboEntrada = GetEntityHeading(veh) end
    if not S.e.rumboEntrada then return false end

    -- Recto y sin stop: como siempre, basta con llegar.
    if e.giro == 'recto' and not e.stop then return true end

    local girado = math.abs(Auto.DifRumbo(GetEntityHeading(veh), S.e.rumboEntrada)) > 30.0
    local pasado = d > e.radio or d > S.e.dMin + 6.0
    local hecho
    if e.giro == 'recto' then
        hecho = S.e.parado or pasado or girado     -- stop recto: parar y listo
    else
        hecho = pasado or girado                   -- giro: se juzga al girar
    end
    if not hecho then return false end

    if e.stop and not S.e.parado then
        Penal('Te has saltado el stop', 20, 'stop')
    end
    if e.giro ~= 'recto' and not S.e.intermitente then
        Penal('Giro sin intermitente', P.puntosIntermitente, 'inter')
    end
    return true
end

function T.emergencia(e, veh)
    if KmH(veh) < 1.0 then return true end
    local seg = (GetGameTimer() - S.e.t0) / 1000
    S.e.progreso = math.min(1.0, seg / e.seg)
    S.e.aviso = '¡FRENA!'
    if seg > e.seg then
        Penal('Frenazo de emergencia demasiado lento', e.puntos or 25, 'lento')
        return true
    end
    return false
end

function T.aparcar(e, veh)
    local dentro = EnPlaza(veh)
    S.e.dentro = dentro
    -- Marcha atrás: se mira que los últimos metros se hagan en retroceso.
    if e.marchaAtras and GetEntitySpeedVector(veh, true).y < -0.6 then S.e.atras = true end
    if not dentro then
        S.e.cuenta = 0
        S.e.aviso = 'Mete el vehículo dentro de la plaza'
        return false
    end
    if KmH(veh) > 1.0 then S.e.cuenta = 0 return false end
    S.e.aviso = nil
    S.e.cuenta = S.e.cuenta + dt
    S.e.progreso = math.min(1.0, S.e.cuenta / (e.seg or 2.0))
    if S.e.cuenta < (e.seg or 2.0) then return false end
    if e.marchaAtras and not S.e.atras then
        Penal('No has entrado marcha atrás', 10, 'atras')
    end
    return true
end

function T.fin(e, veh)
    if not GetIsVehicleEngineRunning(veh) then A.QuitarAyuda('motor') return true end
    if KmH(veh) < 1.0 then
        A.Ayuda('motor', 'E', 'Apagar el motor')
        if PulsaE() then
            A.QuitarAyuda('motor')
            SetVehicleEngineOn(veh, false, false, true)
            return true
        end
    end
    return false
end

-- ── El bucle ──────────────────────────────────────────────────────────────

local function Hud(veh, e)
    local pos = GetEntityCoords(veh)
    local o = e.pos or ((e.tipo == 'aparcar' or e.tipo == 'fin') and (LaPlaza())) or nil
    local obj
    if o then
        local dx, dy = o.x - pos.x, o.y - pos.y
        local rumboA = (math.deg(math.atan(-dx, dy)) + 360.0) % 360.0
        obj = {
            dist = math.floor(math.sqrt(dx * dx + dy * dy)),
            dif = math.floor(Auto.DifRumbo(rumboA, GetEntityHeading(veh))),
        }
    end
    local quedan = S.tiempo - (GetGameTimer() - S.inicio) / 1000
    A.Nui('hud', {
        vel = math.floor(KmH(veh)),
        limite = math.floor(S.limite or Config.Limite),
        cinturon = S.examen.cinturon and Cinturon() or nil,
        obj = obj,
        puntos = math.max(0, 100 - S.restado),
        quedan = math.max(0, math.floor(quedan)),
        aviso = S.e.aviso or S.avisoGlobal,
        progreso = S.e.progreso,
        giro = e.tipo == 'punto' and e.giro or nil,
    })
end

local function Bucle()
    local ultimoHud, anterior = 0, GetGameTimer()
    local sinVolante, fuera, chapa = 0.0, 0.0, nil
    local rapido, sinCinturon, fueraCalzada = 0.0, 0.0, 0.0
    while S do
        local ahora = GetGameTimer()
        dt = (ahora - anterior) / 1000
        anterior = ahora
        local veh = Veh()
        if not S.fin then
            if not veh then
                Suspender('El vehículo se ha perdido.')
            else
                local e = S.etapas[S.i]
                --[[ PlayerPedId() y no cache.ped: el de ox_lib se queda a 0 un
                     instante al recargar el recurso y al reaparecer, y con 0
                     `IsEntityDead` contesta que SÍ. El examen suspendía por
                     «Accidente» sin accidente, con la nota intacta y sin una
                     sola falta (visto el 20/09 en un recorrido de prueba). ]]
                local ped = PlayerPedId()
                local mando = GetPedInVehicleSeat(veh, -1) == ped
                S.avisoGlobal = nil

                --[[ Fuera del coche: diez segundos y el examen se CANCELA.

                     Antes era un suspenso, y no es justo: si te bajas es
                     porque algo ha pasado —un accidente, un aviso del
                     trabajo— y no por hacer trampas. Cancelar no apunta
                     suspenso ni deja espera; el dinero sí se pierde. ]]
                if not mando then
                    sinVolante = sinVolante + dt
                    local quedan = math.max(0, math.ceil(10.0 - sinVolante))
                    S.avisoGlobal = ('Vuelve al volante · el examen se cancela en %d s'):format(quedan)
                    if sinVolante > 10.0 then
                        A.CancelarPractico('Te has bajado del vehículo.')
                    end
                else
                    sinVolante = 0.0
                end

                -- Golpes y destrozos.
                local ch = GetVehicleBodyHealth(veh)
                if chapa and chapa - ch > P.golpe and HasEntityCollidedWithAnything(veh) then
                    Penal('Golpe con el vehículo', P.puntosGolpe, 'golpe' .. ahora)
                end
                chapa = ch
                if IsEntityDead(veh) or ch < P.chapaMinima then
                    Suspender('Has destrozado el vehículo.')
                elseif ped ~= 0 and DoesEntityExist(ped) and IsEntityDead(ped) then
                    -- Muerto no se examina a nadie, pero tampoco se le
                    -- suspende: se cancela y que vuelva cuando pueda.
                    A.CancelarPractico('Te has quedado inconsciente.')
                end

                -- Atropellos: suspenso directo.
                for _, otro in ipairs(GetGamePool('CPed')) do
                    if otro ~= ped and not IsPedInAnyVehicle(otro, false)
                        and #(GetEntityCoords(otro) - GetEntityCoords(veh)) < 12.0
                        and HasEntityBeenDamagedByEntity(otro, veh, true) then
                        ClearEntityLastDamageEntity(otro)
                        Suspender('Has atropellado a una persona.')
                        break
                    end
                end

                -- El cinturón.
                if S.examen.cinturon and not Cinturon() and KmH(veh) > 15.0 then
                    sinCinturon = sinCinturon + dt
                    S.avisoGlobal = 'Ponte el cinturón'
                    if sinCinturon > 4.0 then
                        Penal('Conduces sin cinturón', P.puntosCinturon, 'cinturon' .. math.floor(ahora / 20000))
                        sinCinturon = 0.0
                    end
                else
                    sinCinturon = 0.0
                end

                -- La velocidad del tramo.
                local limite = S.limite or Config.Limite
                local v = KmH(veh)
                if v > limite + P.margenFuera then
                    Suspender(('Exceso de velocidad grave: %d en un tramo de %d.'):format(math.floor(v), math.floor(limite)))
                elseif v > limite + P.margenResta then
                    rapido = rapido + dt
                    S.avisoGlobal = ('Máximo %d km/h'):format(math.floor(limite))
                    if rapido > 1.5 then
                        Penal(('Exceso de velocidad (%d en %d)'):format(math.floor(v), math.floor(limite)),
                            P.puntosVelocidad, 'vel' .. S.i)
                    end
                elseif v > limite + P.margenAviso then
                    S.avisoGlobal = ('Máximo %d km/h'):format(math.floor(limite))
                    rapido = 0.0
                else
                    rapido = 0.0
                end

                -- Salirse de la calzada.
                local pos = GetEntityCoords(veh)
                if not IsPointOnRoad(pos.x, pos.y, pos.z, veh) and v > 5.0 and not Permitido(pos) then
                    fueraCalzada = fueraCalzada + dt
                    if fueraCalzada > P.segundosFalta then
                        Penal('Te sales de la calzada', P.puntosFuera, 'calzada' .. S.i)
                    end
                else
                    fueraCalzada = 0.0
                end

                -- Fuera de la zona del examen.
                if Auto.Plano(pos, Config.Escuela.centro) > Config.Escuela.radioExamen then
                    fuera = fuera + dt
                    S.avisoGlobal = 'Fuera de la zona del examen: vuelve'
                    if fuera > P.fueraMax then Suspender('Te has ido fuera de la zona del examen.') end
                else
                    fuera = 0.0
                end

                if (ahora - S.inicio) / 1000 > S.tiempo then Suspender('Se ha acabado el tiempo.') end

                if e and not S.fin then
                    Marcar(e)
                    if mando and not S.enviando and T[e.tipo] and T[e.tipo](e, veh) then Hecha() end
                end

                if ahora - ultimoHud > 150 and e then
                    ultimoHud = ahora
                    Hud(veh, e)
                end
            end
        end
        Wait(0)
    end
end

-- ── Empezar ───────────────────────────────────────────────────────────────

function A.EmpezarPractico(r)
    local ex = Config.Examenes[r.examen]
    local etapas = r.etapas or (ex and Auto.Etapas(ex, r.variante))
    if not etapas or #etapas == 0 then return end

    for _, e in ipairs(etapas) do
        if e.pos and (type(e.pos) == 'table' and not getmetatable(e.pos)) then
            e.pos = vec3(tonumber(e.pos.x) + 0.0, tonumber(e.pos.y) + 0.0, tonumber(e.pos.z) + 0.0)
        end
    end

    S = {
        examen = ex, etapas = etapas, variante = r.variante, vehNet = r.veh, pedNet = r.ped,
        plaza = r.plaza,
        examinador = r.examinador, alumno = r.alumno,
        i = 1, e = { penales = {} }, pend = {}, restado = 0,
        inicio = GetGameTimer(), tiempo = r.tiempo or ex.tiempo,
        limite = Config.Limite,
    }
    A.practico = S

    local fin = GetGameTimer() + 10000
    while not Veh() and GetGameTimer() < fin do Wait(50) end
    local veh = Veh()
    if not veh then
        A.Aviso('No llega el vehículo. Habla otra vez con el instructor.', 'error')
        Suspender('El vehículo no llegó.')
        return
    end
    pcall(function() exports.origen_fuel:SetFuel(veh, 100.0) end)
    SetVehicleEngineOn(veh, false, true, true)
    DoScreenFadeOut(400)
    Wait(450)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    -- El examinador lo crea el servidor y puede tardar en llegar por red.
    CreateThread(function()
        local fin2 = GetGameTimer() + 8000
        local ped = Examinador()
        while not ped and GetGameTimer() < fin2 do Wait(100) ped = Examinador() end
        if not ped then return end
        NetworkRequestControlOfEntity(ped)
        local f2 = GetGameTimer() + 1500
        while not NetworkHasControlOfEntity(ped) and GetGameTimer() < f2 do Wait(20) end
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanBeDraggedOut(ped, false)
        SetPedConfigFlag(ped, 184, true)
        SetPedKeepTask(ped, true)
        SetEntityInvincible(ped, true)
        local v = Veh()
        if v and GetVehiclePedIsIn(ped, false) ~= v then TaskWarpPedIntoVehicle(ped, v, 0) end
    end)
    Wait(300)
    DoScreenFadeIn(600)

    A.Nui('practico', {
        nombre = ex.nombre, aparato = ex.aparato, examinador = S.examinador,
        total = #S.etapas, tiempo = S.tiempo, aprobado = P.aprobado,
    })
    Etapa(1)
    CreateThread(Bucle)
end

--[[ El examen que arranca desde la COLA: las plazas estaban ocupadas, el
     alumno esperó y ahora le toca. Si tiene el menú abierto se cierra solo. ]]
RegisterNetEvent('origen_autoescuela:practico:arrancar', function(r)
    if A.panel then
        A.panel = false
        SetNuiFocus(false, false)
        A.Nui('cerrar')
    end
    A.EmpezarPractico(r)
end)

RegisterNetEvent('origen_autoescuela:practico:resultado', function(r)
    if not S then return end
    S.fin = true
    A.QuitarAyuda('motor')
    MapaFuera()
    if r.aprobado then
        Dice(r.nivelNuevo
            and ('Aprobado, {nombre}. Ya tienes el carné %s: la tarjeta está en tu inventario.'):format(r.nivelNuevo:lower())
            or 'Aprobado.', 'bien')
    else
        Dice('Examen suspendido. Para el vehículo y bájate.', 'mal')
    end
    r.soloVer = false
    A.Nui('resultado', r)
    SetNuiFocus(true, true)
    S = nil
    A.practico = nil
end)

RegisterNetEvent('origen_autoescuela:practico:retirado', function()
    MapaFuera()
    A.Nui('finPractico')
end)

RegisterNUICallback('resultadoCerrar', function(_, cb)
    cb({})
    SetNuiFocus(false, false)
end)

--[[ Cancelar el examen. No es rendirse (eso es /abandonarpractico, que
     cuenta como suspenso): es dejarlo cuando ya no se puede seguir. No apunta
     suspenso ni deja espera, pero el dinero no vuelve. ]]
function A.CancelarPractico(motivo)
    if not S or S.fin then return end
    S.fin = true
    TriggerServerEvent('origen_autoescuela:practico:cancelar', motivo)
    -- Si el servidor no contesta, no dejar el HUD colgado.
    local yo = S
    SetTimeout(8000, function()
        if S == yo then
            S, A.practico = nil, nil
            MapaFuera()
            A.Nui('finPractico')
        end
    end)
end

RegisterCommand('cancelarexamen', function()
    if not S or S.fin then
        return A.Aviso('No tienes ningún examen en marcha.', 'error')
    end
    A.CancelarPractico('Lo has cancelado tú.')
end, false)
RegisterKeyMapping('cancelarexamen', 'Autoescuela: cancelar el examen', 'keyboard', 'F9')

RegisterNetEvent('origen_autoescuela:practico:cancelado', function(motivo)
    S, A.practico = nil, nil
    MapaFuera()
    A.QuitarAyuda('motor')
    A.Nui('finPractico')
    A.Aviso((motivo or 'Examen cancelado.') .. ' No cuenta como suspenso, pero el importe no se devuelve.', 'error', 9000)
end)

--- Abandonar a propósito (cuenta como suspenso).
RegisterCommand('abandonarpractico', function()
    if not S or S.fin then return end
    S.fin = true
    TriggerServerEvent('origen_autoescuela:practico:abandonar')
end, false)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    A.QuitarAyuda('motor')
    QuitarMarcas()
end)
