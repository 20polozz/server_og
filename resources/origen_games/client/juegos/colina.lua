--[[ ── Rey de la colina · el cliente ─────────────────────────────────────────

     Dibuja la colina (y la marca de adónde irá), elige a quién empujar, se
     deja tirar al suelo cuando le empujan y rellena la ficha del HUD. Quién
     reina y quién suma lo dice el servidor: aquí no se decide nada. ]]

local C = Config.Juegos.colina
local E = C.Empujon
local T = C.Teclas
local ID = 'colina'

local M = {}
local st = {}

--- La animación del que empuja. Si el diccionario no existe en esta build, se
--- empuja igual, sin gesto.
local ANIM_DIC, ANIM_NOMBRE = 'reaction@shove', 'shove_var_a'

--- Ángulo delante del personaje en el que se busca a quién empujar. Algo más
--- estrecho que el que acepta el servidor (60°), para no pedir empujones que
--- vaya a rechazar por el retraso de la red.
local COS_FRENTE = math.cos(math.rad(55.0))

local COLOR = {
    libre = { 240, 180, 41 },
    mio = { 216, 27, 85 },
    otro = { 255, 128, 40 },
    disputada = { 150, 150, 158 },
    fantasma = { 245, 245, 245 },
}

local function Reset()
    st = { enfriamiento = 0, avisoDisputa = 0 }
end
Reset()

local function Activo() return Juego.activo and Juego.juego == ID end
local function Yo() return Juego.yo or {} end
local function SoyRey() return st.rey ~= nil and st.rey ~= false and st.rey == Core.Yo() end

--[[ ── El mapa ────────────────────────────────────────────────────────────── ]]
local function PonerMapa()
    local c = st.colina
    if not c then return OrigenMapa.Quitar('colina') end
    OrigenMapa.Poner('colina', {
        x = c.x, y = c.y, z = c.z, radio = c.radio,
        cat = 'activities', icono = 'juego', nombre = 'La colina', pulso = true,
    })
end

local function PonerProxima()
    local p = st.proxima
    if not p then return OrigenMapa.Quitar('colina_proxima') end
    OrigenMapa.Poner('colina_proxima', {
        x = p.x, y = p.y, z = p.z, radio = p.radio,
        cat = 'activities', icono = 'juego', nombre = 'La colina irá aquí',
    })
end

--- Todo lo de la colina fuera: dibujo, mapa y la marca de la próxima.
local function QuitarColina()
    st.colina, st.proxima, st.mueveHasta = nil, nil, nil
    st.rey, st.reyNombre, st.disputada, st.n = nil, nil, false, 0
    st.objetivo = nil
    OrigenMapa.Quitar('colina')
    OrigenMapa.Quitar('colina_proxima')
end

--- Tras un empujón el personaje vuelve a no poder caerse, como lo deja el
--- blindaje del núcleo. Solo dentro de la partida: al salir, el núcleo
--- restaura el ragdoll normal y no hay que pisarlo.
local function FinRagdoll()
    st.ragdollHasta = nil
    if Juego.activo then SetPedCanRagdoll(PlayerPedId(), false) end
end

--[[ ── El suelo de la colina ──────────────────────────────────────────────────

     El servidor sortea la colina con la z del centro de la zona, que en una
     cuesta puede quedar muchos metros por encima o por debajo. Aquí se busca
     el suelo de verdad, bajando desde 15 m por encima (lo que el servidor
     acepta de margen), primero sin contar objetos para no quedarse en una
     marquesina o un árbol. `nil` si todavía no hay colisión cargada. ]]
local MARGEN = 15.0

local function SueloReal(x, y, zRef)
    RequestCollisionAtCoord(x + 0.0, y + 0.0, zRef + 0.0)
    local desde = zRef + MARGEN
    local hay, suelo = GetGroundZExcludingObjectsFor_3dCoord(x + 0.0, y + 0.0, desde, false)
    if not hay then hay, suelo = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, desde, false) end
    if hay and math.abs(suelo - zRef) <= MARGEN then return suelo end
    return nil
end

--- Dónde se dibuja: el suelo que calcula este cliente; si aún no puede, el
--- que ya confirmó el servidor, y si no, la z sorteada.
local function SueloDibujo(c)
    return SueloReal(c.x, c.y, c.z) or c.sueloServ or (c.z - 1.0)
end

--- Una colina (o la próxima) tal como llega del servidor.
local function Punto(d)
    local c = {
        id = d.id, x = d.x, y = d.y, z = d.z, radio = d.radio, mov = d.mov,
        zOk = d.zOk == true, sueloServ = tonumber(d.suelo) or nil,
    }
    c.suelo = SueloDibujo(c)
    return c
end

--- Lo que el servidor sabe del suelo, sobre una colina que ya teníamos.
local function Confirmar(c, d)
    c.zOk = d.zOk == true
    c.sueloServ = tonumber(d.suelo) or nil
end

--- Si el servidor todavía no sabe a qué altura está el suelo, se lo decimos.
--- Una petición por Lento como mucho (el servidor frena a 200 ms) y, tras
--- mandarla, se espera a que llegue la confirmación antes de repetir.
local function Responder(c, ahora)
    if not c or c.zOk or not c.id or ahora < (c.proximoIntento or 0) then return false end
    local z = SueloReal(c.x, c.y, c.z)
    if not z then
        c.proximoIntento = ahora + 1000
        return false
    end
    c.proximoIntento = ahora + 3000
    TriggerServerEvent('origen_games:colina:s:suelo', c.id, z)
    return true
end

--- Si una altura cuenta como estar arriba, con el mismo criterio que el
--- servidor: sin suelo confirmado, margen amplio.
local function AlturaOk(c, z)
    if c.zOk and c.sueloServ then return math.abs(z - (c.sueloServ + 1.0)) < 4.0 end
    return math.abs(z - c.z) < MARGEN
end

--[[ ── Lo que llega del servidor ──────────────────────────────────────────── ]]

--- Dentro de la colina según este cliente: solo para los avisos y la ficha.
local function DentroYo()
    local c = st.colina
    if not c then return false end
    local p = GetEntityCoords(PlayerPedId())
    local dx, dy = p.x - c.x, p.y - c.y
    return math.sqrt(dx * dx + dy * dy) <= c.radio and AlturaOk(c, p.z)
end

RegisterNetEvent('origen_games:colina:c:colina', function(d)
    if not Activo() or type(d) ~= 'table' then return end
    if d.quitar then return QuitarColina() end

    local yo = Core.Yo()
    local ahora = Core.Ahora()
    local eraRey = SoyRey()
    local movida = not st.colina or st.colina.id ~= d.id

    if movida then
        local habia = st.colina ~= nil
        st.colina = Punto(d)
        PonerMapa()
        if habia then Core.Sonido('pase') end
    else
        Confirmar(st.colina, d)
    end

    if d.proxima then
        if not st.proxima or st.proxima.id ~= d.proxima.id then
            st.proxima = Punto(d.proxima)
            PonerProxima()
        else
            Confirmar(st.proxima, d.proxima)
        end
        st.mueveHasta = ahora + (tonumber(d.mueveEn) or 0) * 1000
    elseif st.proxima then
        st.proxima, st.mueveHasta = nil, nil
        PonerProxima()
    end

    local disputadaAntes = st.disputada
    st.rey = d.rey
    st.reyNombre = d.reyNombre
    st.disputada = d.disputada == true
    st.n = tonumber(d.n) or 0

    if d.rey == yo and not eraRey then
        Core.Sonido('corona')
        Core.Aviso('¡Eres el rey! Aguanta arriba tú solo.', 'caza')
    elseif eraRey and d.rey ~= yo and not movida then
        Core.Aviso('Has perdido la colina.', 'mal')
    end

    if st.disputada and not disputadaAntes and DentroYo() and ahora - st.avisoDisputa > 4000 then
        st.avisoDisputa = ahora
        Core.Aviso('¡Disputada! Nadie suma: echa a los demás.', 'mal')
    end
end)

RegisterNetEvent('origen_games:colina:c:empujado', function(d)
    if not Activo() or Juego.eliminado or type(d) ~= 'table' then return end
    local dx, dy = tonumber(d.dx) or 0.0, tonumber(d.dy) or 0.0
    local ped = PlayerPedId()

    --[[ El núcleo deja el personaje sin ragdoll al blindarlo; para caer hay
         que devolvérselo un momento. Lo vuelve a quitar FinRagdoll. ]]
    SetPedCanRagdoll(ped, true)
    SetPedToRagdoll(ped, E.ragdoll, E.ragdoll, 0, false, false, false)
    st.ragdollHasta = Core.Ahora() + E.ragdoll + 400
    Core.Aviso(('¡Te ha empujado %s!'):format(d.por or 'alguien'), 'mal')

    --[[ La fuerza, al fotograma siguiente: el ragdoll se activa en el próximo
         paso de física y un empujón aplicado antes se lo come la cápsula. ]]
    CreateThread(function()
        Wait(0)
        if not Activo() then return end
        local p = PlayerPedId()
        ApplyForceToEntity(p, 1, dx * E.fuerza, dy * E.fuerza, E.fuerza * 0.25,
            0.0, 0.0, 0.0, 0, false, true, true, false, true)
    end)
end)

RegisterNetEvent('origen_games:colina:c:empujon', function(d)
    if not Activo() or type(d) ~= 'table' then return end
    local ahora = Core.Ahora()
    if d.ok then
        st.enfriamiento = ahora + (tonumber(d.enfriamiento) or E.enfriamiento) * 1000
    else
        -- Rechazado (se había movido, la red...): se puede probar enseguida.
        st.enfriamiento = ahora + 500
    end
end)

--[[ ── A quién empujar ──────────────────────────────────────────────────────── ]]
local function BuscarObjetivo(ped)
    local desde = GetEntityCoords(ped)
    local frente = GetEntityForwardVector(ped)
    local fl = math.sqrt(frente.x * frente.x + frente.y * frente.y)
    local yo = Core.Yo()
    local mejor, mejorD

    for _, fila in ipairs(Juego.marcador or {}) do
        if fila.vivo and fila.id ~= yo then
            local otro = Core.PedDe(fila.id)
            if otro and not IsPedRagdoll(otro) then
                local p = GetEntityCoords(otro)
                local d = #(p - desde)
                if d <= E.alcance and (not mejorD or d < mejorD) then
                    local dx, dy = p.x - desde.x, p.y - desde.y
                    local plano = math.sqrt(dx * dx + dy * dy)
                    local delante = plano < 0.5
                        or (fl > 0.01 and (frente.x * dx + frente.y * dy) / (plano * fl) >= COS_FRENTE)
                    if delante then
                        mejor = { id = fila.id, nombre = fila.nombre, dist = d }
                        mejorD = d
                    end
                end
            end
        end
    end
    return mejor
end

local function PuedeEmpujar(ahora, ped)
    return Juego.fase == 'juego' and not Juego.eliminado and ahora >= st.enfriamiento
        and not st.ragdollHasta and not IsPedRagdoll(ped)
end

--[[ ── Ganchos del núcleo ─────────────────────────────────────────────────── ]]
function M.Empezar()
    Reset()
    if DoesAnimDictExist(ANIM_DIC) then RequestAnimDict(ANIM_DIC) end
end

function M.AntesDeRonda()
    QuitarColina()
    if st.ragdollHasta then FinRagdoll() end
    st.enfriamiento = 0
end

function M.Ronda(d)
    local c = d.datos and d.datos.colina
    if c then
        st.colina = Punto(c)
        PonerMapa()
    end
    return false
end

function M.FinRonda()
    QuitarColina()
    if st.ragdollHasta then FinRagdoll() end
end

function M.Final()
    QuitarColina()
    if st.ragdollHasta then FinRagdoll() end
end

function M.Salir()
    -- Sin Wait: se llama también al parar el recurso.
    OrigenMapa.Quitar('colina')
    OrigenMapa.Quitar('colina_proxima')
    if HasAnimDictLoaded(ANIM_DIC) then RemoveAnimDict(ANIM_DIC) end
    Reset()
end
M.Restaurar = M.Salir

--[[ ── Cada fotograma ─────────────────────────────────────────────────────── ]]
local function Cilindro(x, y, z, radio, rgb, alfa, alto)
    DrawMarker(1, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        radio * 2.0, radio * 2.0, alto, rgb[1], rgb[2], rgb[3], alfa, false, false, 2, false, nil, nil, false)
end

local function Aro(x, y, z, radio, rgb, alfa)
    DrawMarker(25, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        radio * 2.0, radio * 2.0, 1.0, rgb[1], rgb[2], rgb[3], alfa, false, false, 2, false, nil, nil, false)
end

local function ColorColina()
    if st.disputada then return COLOR.disputada end
    if SoyRey() then return COLOR.mio end
    if st.rey then return COLOR.otro end
    return COLOR.libre
end

function M.Frame(ahora)
    local ped = PlayerPedId()

    RestorePlayerStamina(PlayerId(), 1.0)

    -- Sin puñetazos ni patadas: aquí solo se empuja con la tecla.
    DisableControlAction(0, T.empujar.control, true)
    DisablePlayerFiring(PlayerId(), true)
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true)
    DisableControlAction(0, 140, true)
    DisableControlAction(0, 141, true)
    DisableControlAction(0, 142, true)
    DisableControlAction(0, 257, true)
    DisableControlAction(0, 263, true)
    DisableControlAction(0, 264, true)

    if IsDisabledControlJustPressed(0, T.empujar.control) and PuedeEmpujar(ahora, ped) then
        -- Se vuelve a buscar al pulsar: el de la ficha puede tener 250 ms.
        local obj = BuscarObjetivo(ped)
        if obj then
            st.enfriamiento = ahora + E.enfriamiento * 1000
            TriggerServerEvent('origen_games:colina:s:empujar', obj.id)
            if HasAnimDictLoaded(ANIM_DIC) then
                TaskPlayAnim(ped, ANIM_DIC, ANIM_NOMBRE, 8.0, -8.0, 700, 48, 0.0, false, false, false)
            end
        end
    end

    local c = st.colina
    if c and (Juego.fase == 'juego' or Juego.fase == 'preparacion') then
        local rgb = ColorColina()
        local z = c.suelo or c.z
        Cilindro(c.x, c.y, z - 0.05, c.radio, rgb, 70, 1.1)
        Aro(c.x, c.y, z + 0.04, c.radio, rgb, 210)
        -- Un haz fino que se ve desde toda la zona.
        Cilindro(c.x, c.y, z, 0.35, rgb, 60, 30.0)

        -- Un cono encima del rey, para ver de un vistazo a quién hay que echar.
        if st.rey and not st.disputada then
            local pedRey = st.rey == Core.Yo() and ped or Core.PedDe(st.rey)
            if pedRey then
                local p = GetEntityCoords(pedRey)
                DrawMarker(0, p.x, p.y, p.z + 1.35, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.35, 0.35, 0.35, COLOR.libre[1], COLOR.libre[2], COLOR.libre[3], 220, true, false, 2, false, nil, nil, false)
            end
        end
    end

    -- La marca fantasma de adónde irá, latiendo.
    local p = st.proxima
    if p and Juego.fase == 'juego' then
        local z = p.suelo or p.z
        local alfa = math.floor(40 + 35 * (0.5 + 0.5 * math.sin(ahora / 160.0)))
        Cilindro(p.x, p.y, z - 0.05, p.radio, COLOR.fantasma, alfa, 0.8)
        Aro(p.x, p.y, z + 0.04, p.radio, COLOR.fantasma, alfa + 90)
        Cilindro(p.x, p.y, z, 0.25, COLOR.fantasma, alfa, 30.0)
    end
end

function M.Lento(ahora)
    local ped = PlayerPedId()

    if st.ragdollHasta and ahora >= st.ragdollHasta then FinRagdoll() end

    -- El suelo, otra vez: con la colina lejos puede no estar cargado todavía.
    local c = st.colina
    if c then c.suelo = SueloDibujo(c) end
    local p = st.proxima
    if p then p.suelo = SueloDibujo(p) end

    if Juego.fase == 'preparacion' or Juego.fase == 'juego' then
        if not Responder(c, ahora) then Responder(p, ahora) end
    end

    st.objetivo = (Juego.fase == 'juego' and not Juego.eliminado) and BuscarObjetivo(ped) or nil
end

--[[ ── El HUD ─────────────────────────────────────────────────────────────── ]]
function M.Ficha()
    if Juego.eliminado then return nil end
    local yo = Yo()
    local ahora = Core.Ahora()
    local ped = PlayerPedId()
    local enJuego = Juego.fase == 'juego'

    local segundos = tonumber(yo.segundos) or 0
    local lider = tonumber(yo.lider) or 0
    local pct = lider > 0 and math.floor(segundos / lider * 100) or 0

    local quedan = Core.Resta(st.enfriamiento)
    local carga = quedan > 0 and (1 - quedan / E.enfriamiento) or nil
    local listo = PuedeEmpujar(ahora, ped)
    local obj = st.objetivo

    local ficha = {
        icono = 'corona',
        puntos = yo.puntos or 0,
        vida = { tipo = 'progreso', etiqueta = 'Tus segundos', pct = pct, cifra = segundos .. ' s' },
        acciones = {
            {
                id = 'empujar', tecla = T.empujar.texto, nombre = 'Empujar',
                extra = quedan > 0 and (quedan .. 's') or nil,
                apagada = not enJuego or quedan > 0 or not obj,
                carga = carga,
            },
        },
        pista = (listo and obj) and {
            tecla = T.empujar.texto, texto = 'Empujar a', destacado = obj.nombre,
            detalle = ('%.1f m'):format(obj.dist),
        } or nil,
    }

    if SoyRey() then
        ficha.tono = 'caza'
        ficha.rol = 'Rey'
        ficha.nombre = 'Aguanta arriba'
        ficha.renglon = ('Sumas %d por segundo'):format(C.Puntos.porSegundo)
    else
        ficha.tono = 'neutro'
        ficha.rol = 'Aspirante'
        ficha.nombre = 'Sube a la colina'
        local c = st.colina
        if c then
            local pos = GetEntityCoords(ped)
            local dx, dy = pos.x - c.x, pos.y - c.y
            local falta = math.sqrt(dx * dx + dy * dy) - c.radio
            if falta <= 0 and AlturaOk(c, pos.z) then
                ficha.renglon = st.disputada and '¡Disputada! Nadie suma' or 'Estás dentro'
            else
                ficha.renglon = ('La colina está a %d m'):format(math.max(1, math.floor(falta + 0.5)))
            end
        end
    end

    -- Con la colina a punto de moverse, eso manda sobre todo lo demás.
    if enJuego and st.mueveHasta then
        local s = Core.Resta(st.mueveHasta)
        if s > 0 then ficha.renglon = ('¡Se mueve en %d s!'):format(s) end
    end

    return ficha
end

function M.Cartel()
    if Juego.fase ~= 'preparacion' then return nil end
    return {
        k = 'Rey de la colina',
        t = ('Ronda %d de %d'):format(Juego.ronda or 0, Juego.rondas or 0),
        m = 'Quédate solo dentro del círculo',
        cifra = Core.Resta(Juego.finFase),
    }
end

RegistrarJuego(ID, M)
