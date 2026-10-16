--[[ ── El impostor · el cliente ─────────────────────────────────────────────

     Las teclas (E: tarea o eliminar · G: reportar o emergencia), las tareas y
     el botón pintados en el mundo, los cuerpos, el mono, la votación y la
     ficha del HUD. Aquí no se decide nada: el servidor valida cada petición.

     Este cliente solo sabe su propio rol. Si es tripulante, nada de lo que le
     llega dice quién es el impostor: ni el marcador (va sin roles) ni los
     cuerpos (llevan a quién, no quién). ]]

local C = Config.Juegos.impostor
local T = C.Teclas
local ID = 'impostor'

local M = {}
local st = { tareas = {}, cuerpos = {}, cerca = {}, recargaHasta = 0 }

local MODELO_HOMBRE = GetHashKey('mp_m_freemode_01')
local MODELO_MUJER = GetHashKey('mp_f_freemode_01')
local PROPS = { 0, 1, 2, 6, 7 }

local function Mio() return Juego.activo and Juego.juego == ID end
local function EsImpostor() return Juego.rol == 'impostor' end
local function Reunidos() return Juego.fase == 'reunion' or Juego.fase == 'voto' end

local function Plano(pos, x, y)
    local dx, dy = pos.x - x, pos.y - y
    return math.sqrt(dx * dx + dy * dy)
end

--- Un hash que puede llegar del servidor sin signo, con el signo que usan
--- las natives del cliente.
local function ConSigno(h)
    h = HashSinSigno(h)
    if h >= 2147483648 then h = h - 4294967296 end
    return h
end

--[[ ── El mono ─────────────────────────────────────────────────────────────

     Se cambia la ropa del ped por script, igual que los uniformes de
     origen_newjobs. Nada en origen_clothing ni en origen_inventory vigila el
     ped: la ropa solo se guarda en la base cuando el jugador la guarda desde
     una tienda o el armario, y el inventario (bloqueado en partida) solo apunta
     lo que le cuenta ese guardado. Así que no hace falta ningún export: se
     apunta lo que llevaba al ponérselo y se le devuelve tal cual. ]]
local function TrajeDe(modelo)
    modelo = ConSigno(modelo)
    if modelo == MODELO_HOMBRE then return C.Disfraz.hombre end
    if modelo == MODELO_MUJER then return C.Disfraz.mujer end
    return nil
end

local function PonerTraje(ped, traje)
    for componente, v in pairs(traje.componentes or {}) do
        if IsPedComponentVariationValid(ped, componente, v[1], v[2]) then
            SetPedComponentVariation(ped, componente, v[1], v[2], 0)
        end
    end
    for _, p in ipairs(traje.quitarProps or PROPS) do ClearPedProp(ped, p) end
end

local function GuardarRopa(ped)
    local r = { modelo = GetEntityModel(ped), comp = {}, props = {} }
    for c = 0, 11 do
        r.comp[c] = { GetPedDrawableVariation(ped, c), GetPedTextureVariation(ped, c), GetPedPaletteVariation(ped, c) }
    end
    for _, p in ipairs(PROPS) do
        r.props[p] = { GetPedPropIndex(ped, p), GetPedPropTextureIndex(ped, p) }
    end
    return r
end

local function Disfrazar()
    if not (Juego.ajustes and Juego.ajustes.disfraz) then return end
    local ped = PlayerPedId()
    local traje = TrajeDe(GetEntityModel(ped))
    if not traje then return end
    -- Solo la primera vez: nunca se apunta el mono como «lo que llevaba».
    if not st.ropa then st.ropa = GuardarRopa(ped) end
    PonerTraje(ped, traje)
end

local function QuitarDisfraz()
    local r = st.ropa
    if not r then return end
    st.ropa = nil
    local ped = PlayerPedId()
    -- Si le han cambiado el modelo entretanto, esos números ya no son su ropa.
    if not DoesEntityExist(ped) or GetEntityModel(ped) ~= r.modelo then return end
    for c = 0, 11 do
        local v = r.comp[c]
        if GetPedDrawableVariation(ped, c) ~= v[1] or GetPedTextureVariation(ped, c) ~= v[2]
            or GetPedPaletteVariation(ped, c) ~= v[3] then
            SetPedComponentVariation(ped, c, v[1], v[2], v[3])
        end
    end
    for p, v in pairs(r.props) do
        if v[1] == -1 then ClearPedProp(ped, p) else SetPedPropIndex(ped, p, v[1], v[2], true) end
    end
end

--[[ ── Tareas: minijuegos ─────────────────────────────────────────────────

     Cada tarea es un minijuego de la NUI (Core.Minijuego). Pulsar E junto a
     ella lo abre y avisa al servidor (empezarTarea); completarlo manda
     completarTarea, y el servidor mira que se abriera esa tarea, que siga al
     lado y que haya pasado el tiempo mínimo. Cerrarlo o fallarlo no cuesta
     nada: se vuelve a abrir. El impostor abre el mismo minijuego en sus tareas
     falsas para fingir, sin mandar nada. ]]
local function NombreTipo(tipo)
    return (Core.MINIJUEGOS and Core.MINIJUEGOS[tipo]) or (C.Tarea.nombres and C.Tarea.nombres[tipo]) or 'Tarea'
end

--- Cierra el minijuego de una tarea si hay uno abierto. Sin Wait.
local function CerrarMinijuego()
    local abierto = st.minijuego ~= nil
    st.minijuego = nil
    if (abierto or (Core.MinijuegoAbierto and Core.MinijuegoAbierto())) and Core.CerrarMinijuego then
        Core.CerrarMinijuego()
    end
end

local function QuitarTareas()
    CerrarMinijuego()
    for id in pairs(st.tareas) do OrigenMapa.Quitar('tarea_' .. id) end
    st.tareas = {}
end

local function CargarTareas(lista)
    QuitarTareas()
    for _, t in ipairs(lista or {}) do
        local id, x, y, z = tonumber(t.id), tonumber(t.x), tonumber(t.y), tonumber(t.z)
        if id and x and y and z then
            local tipo = type(t.tipo) == 'string' and t.tipo or 'cables'
            st.tareas[id] = { id = id, x = x + 0.0, y = y + 0.0, z = z + 0.0, base = z + 0.0, apoyada = false, intentos = 0, tipo = tipo }
            OrigenMapa.Poner('tarea_' .. id, {
                x = x, y = y, z = z, cat = 'activities', icono = 'juego', color = '#f0b429',
                nombre = 'Tarea: ' .. NombreTipo(tipo),
            })
        end
    end
end

--- Abre el minijuego de una tarea propia (de verdad o, si es impostor, falsa).
local function AbrirTarea(t)
    if not Core.Minijuego or st.minijuego then return end
    local falsa = EsImpostor()
    local tipo = (Core.MINIJUEGOS and Core.MINIJUEGOS[t.tipo]) and t.tipo or 'cables'
    local m = { id = t.id }
    st.minijuego = m

    local abierto = Core.Minijuego({ tipo = tipo, titulo = NombreTipo(tipo) }, function(exito)
        -- Si lo hemos cerrado nosotros (reunión, fin de fase...), ya no es este.
        if st.minijuego ~= m then return end
        st.minijuego = nil
        if not exito or not Mio() or Juego.eliminado or Juego.fase ~= 'juego' then return end
        local tarea = st.tareas[m.id]
        if not tarea or tarea.hecha then return end
        if falsa then
            -- Fingida: solo aquí, para no repetirla. Al servidor no le llega nada.
            tarea.hecha = true
            OrigenMapa.Quitar('tarea_' .. tarea.id)
            Core.Sonido('tarea')
        else
            -- Esperando la respuesta; si no llega en unos segundos, se puede repetir.
            tarea.enviada = Core.Ahora() + 3000
            TriggerServerEvent('origen_games:impostor:s:completarTarea', tarea.id)
        end
    end)

    if abierto == false then
        st.minijuego = nil
        return
    end
    if not falsa then TriggerServerEvent('origen_games:impostor:s:empezarTarea', t.id) end
end

--[[ El servidor manda las tareas a la altura del centro de la zona; aquí se
     apoyan en el suelo. Core.Suelo mira desde 3 m por encima y, si no
     encuentra suelo, devuelve z − 1: se prueba también más arriba y más abajo
     por si la plaza tiene cuesta, y se reintenta al acercarse (lejos, la
     colisión puede no estar cargada). ]]
local function Apoyar(t)
    for _, desde in ipairs({ t.base, t.base + 12.0, t.base - 12.0 }) do
        local z = Core.Suelo(t.x, t.y, desde)
        if z ~= desde - 1.0 then
            t.z, t.apoyada = z, true
            return
        end
    end
    t.intentos = t.intentos + 1
    if t.intentos >= 20 then t.apoyada = true end
end

local function TareaCercana(pos, ahora)
    local mejor, mejorD
    for _, t in pairs(st.tareas) do
        if t.enviada and ahora > t.enviada then t.enviada = nil end
        if not t.hecha and not t.enviada then
            local d = Plano(pos, t.x, t.y)
            if d <= C.Tarea.alcance and math.abs((pos.z - 1.0) - t.z) <= 3.0 and (not mejorD or d < mejorD) then
                mejor, mejorD = t, d
            end
        end
    end
    return mejor
end

--[[ ── Cuerpos ─────────────────────────────────────────────────────────────

     Un ped local (no de red) tumbado donde cayó la víctima. Si su personaje
     aún se ve por aquí se clona, con su ropa; si no, uno de su modelo (con el
     mono si la zona lo lleva). Cada cliente pinta el suyo y lo borra él. ]]
local function BorrarCuerpo(c)
    c.borrado = true
    if c.ped and DoesEntityExist(c.ped) then
        SetEntityAsMissionEntity(c.ped, true, true)
        DeleteEntity(c.ped)
    end
    c.ped = nil
end

local function QuitarCuerpos()
    for _, c in pairs(st.cuerpos) do BorrarCuerpo(c) end
    st.cuerpos = {}
end

local function CrearCuerpo(c)
    CreateThread(function()
        local ronda = Juego.ronda
        local function Sigue()
            return Mio() and Juego.ronda == ronda and st.cuerpos[c.id] == c and not c.borrado
        end

        c.suelo = Core.Suelo(c.x, c.y, c.z)
        local ped

        local suyo = c.victima and Core.PedDe(c.victima)
        if suyo and #(GetEntityCoords(suyo) - vector3(c.x, c.y, c.z)) < 6.0 then
            ped = ClonePed(suyo, false, false, true)
            if ped == 0 or not DoesEntityExist(ped) then ped = nil end
        end

        if not ped then
            local modelo = ConSigno(tonumber(c.modelo) or MODELO_HOMBRE)
            if not IsModelInCdimage(modelo) or not IsModelAPed(modelo) then modelo = MODELO_HOMBRE end
            RequestModel(modelo)
            local hasta = GetGameTimer() + 5000
            while not HasModelLoaded(modelo) and GetGameTimer() < hasta do Wait(50) end
            if not Sigue() or not HasModelLoaded(modelo) then
                SetModelAsNoLongerNeeded(modelo)
                return
            end
            ped = CreatePed(4, modelo, c.x, c.y, c.suelo, c.h, false, false)
            SetModelAsNoLongerNeeded(modelo)
            if not ped or ped == 0 then return end
            SetPedDefaultComponentVariation(ped)
            local traje = Juego.ajustes and Juego.ajustes.disfraz and TrajeDe(modelo)
            if traje then PonerTraje(ped, traje) end
        end

        -- Apuntado antes de la primera espera: si se limpia mientras, se borra.
        c.ped = ped

        SetEntityVisible(ped, true, false)
        ResetEntityAlpha(ped)
        SetEntityCoords(ped, c.x, c.y, c.suelo, false, false, false, false)
        SetEntityHeading(ped, c.h)
        SetEntityProofs(ped, true, true, true, true, true, true, true, true)
        SetEntityCanBeDamaged(ped, false)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanRagdoll(ped, false)
        RemoveAllPedWeapons(ped, true)

        RequestAnimDict('dead')
        local hasta = GetGameTimer() + 3000
        while not HasAnimDictLoaded('dead') and GetGameTimer() < hasta do Wait(50) end
        if not Sigue() then BorrarCuerpo(c) return end
        if HasAnimDictLoaded('dead') then
            TaskPlayAnim(ped, 'dead', 'dead_a', 8.0, 8.0, -1, 1, 0.0, false, false, false)
        end

        -- Que se asiente y quede clavado, sin estorbar a quien pase por encima.
        Wait(700)
        if not Sigue() then BorrarCuerpo(c) return end
        FreezeEntityPosition(ped, true)
        SetEntityCollision(ped, false, false)
        RemoveAnimDict('dead')
    end)
end

local function CuerpoCercano(pos)
    local mejor, mejorD
    for _, c in pairs(st.cuerpos) do
        local d = Plano(pos, c.x, c.y)
        if d <= C.Reunion.alcanceCuerpo and math.abs(pos.z - c.z) <= 4.0 and (not mejorD or d < mejorD) then
            mejor, mejorD = c, d
        end
    end
    return mejor
end

--[[ ── Limpieza ─────────────────────────────────────────────────────────── ]]
local function Limpiar()
    QuitarTareas()
    QuitarCuerpos()
    st.cerca = {}
    st.objetivo = nil
    st.recargaHasta = 0
end

--[[ ── Ganchos del núcleo ─────────────────────────────────────────────────── ]]
function M.Empezar()
    Limpiar()
    st.companero = nil
end

function M.AntesDeRonda()
    Limpiar()
    st.companero = nil
    st.centroZ = nil
end

function M.Ronda(d)
    local datos = d.datos or {}
    st.dos = datos.dos == true
    if type(datos.companero) == 'table' and tonumber(datos.companero.id) then
        st.companero = { id = tonumber(datos.companero.id), nombre = tostring(datos.companero.nombre or '') }
    end
    CargarTareas(datos.tareas)
    -- Con la pantalla aún en negro: nadie ve a nadie cambiarse.
    Disfrazar()
    return false
end

function M.Fase(d)
    if d.fase ~= 'voto' then Core.CerrarVotacion() end
    -- Cualquier cambio de fase cierra el minijuego que hubiera abierto.
    CerrarMinijuego()
    if d.fase == 'juego' then
        -- Quien mira desde arriba sigue quieto: soltarlo lo dejaría caer.
        if not Juego.eliminado and not Espectador.activo then
            FreezeEntityPosition(PlayerPedId(), false)
        end
    end
end

--[[ En «Tareas» el marcador de todos da por vivos a los muertos que nadie ha
     descubierto. A quien ya lo sabe (impostores y eliminados) el servidor le
     manda aparte quiénes son, y aquí se corrige su copia del marcador: la cámara
     de mirar (client/core/espectador.lua) y Core.MasCercano la leen y no deben
     apuntar a un personaje aparcado invisible encima de la zona. A la pantalla
     ya le llegó sin corregir, y da igual: lo que enseña es lo mismo que ven
     los demás. ]]
function M.Estado()
    local ocultos = Juego.yo and Juego.yo.ocultos
    if type(ocultos) ~= 'table' then return end
    local muertos = {}
    for _, id in ipairs(ocultos) do
        if tonumber(id) then muertos[tonumber(id)] = true end
    end
    for _, fila in ipairs(Juego.marcador or {}) do
        if muertos[fila.id] then fila.vivo = false end
    end
end

function M.Eliminado()
    -- Sus tareas ya no se pueden hacer (y se cierra el minijuego si lo tenía
    -- abierto); los cuerpos se siguen viendo al mirar.
    QuitarTareas()
end

function M.FinRonda()
    Limpiar()
    Core.CerrarVotacion()
    QuitarDisfraz()
end

function M.Final()
    Limpiar()
    Core.CerrarVotacion()
    QuitarDisfraz()
end

function M.Salir()
    Limpiar()
    Core.CerrarVotacion()
    QuitarDisfraz()
    st.companero = nil
end
M.Restaurar = M.Salir

--- El servidor lo devuelve a la zona o a su sitio de la reunión, a la altura
--- del centro: aquí se apoya en el suelo.
function M.Devuelto(d)
    local x, y, z = d.x + 0.0, d.y + 0.0, d.z + 0.0
    local suelo = Core.Suelo(x, y, z)
    if suelo == z - 1.0 then suelo = z end
    local ped = PlayerPedId()
    SetEntityCoords(ped, x, y, suelo, false, false, false, false)
    if d.quieto then FreezeEntityPosition(ped, true) end
    return true
end

--[[ ── Lo que llega del servidor ──────────────────────────────────────────── ]]
RegisterNetEvent('origen_games:impostor:c:recarga', function(d)
    if not Mio() or type(d) ~= 'table' then return end
    st.recargaHasta = Core.Ahora() + (tonumber(d.segundos) or 0) * 1000
end)

RegisterNetEvent('origen_games:impostor:c:tareaHecha', function(d)
    if not Mio() or type(d) ~= 'table' then return end
    local t = st.tareas[tonumber(d.id) or -1]
    if not t then return end
    t.hecha, t.enviada = true, nil
    OrigenMapa.Quitar('tarea_' .. t.id)
    Core.Aviso('Tarea completada.', 'info')
end)

RegisterNetEvent('origen_games:impostor:c:tareaFallida', function(d)
    if not Mio() or type(d) ~= 'table' then return end
    local t = st.tareas[tonumber(d.id) or -1]
    if not t or t.hecha then return end
    t.enviada = nil
    Core.Aviso('No se ha podido completar la tarea. Vuelve a abrirla sin alejarte.', 'mal')
end)

RegisterNetEvent('origen_games:impostor:c:cuerpo', function(d)
    if not Mio() or type(d) ~= 'table' then return end
    local id, x, y, z = tonumber(d.id), tonumber(d.x), tonumber(d.y), tonumber(d.z)
    if not (id and x and y and z) or st.cuerpos[id] then return end
    local c = {
        id = id, x = x + 0.0, y = y + 0.0, z = z + 0.0,
        h = (tonumber(d.h) or 0.0) + 0.0,
        modelo = d.modelo,
        nombre = tostring(d.nombre or 'alguien'),
        victima = tonumber(d.victima),
    }
    c.suelo = c.z - 1.0
    st.cuerpos[id] = c
    CrearCuerpo(c)
end)

RegisterNetEvent('origen_games:impostor:c:reunion', function(d)
    if not Mio() or type(d) ~= 'table' then return end
    CerrarMinijuego()
    QuitarCuerpos()
    if Juego.eliminado or not tonumber(d.x) then return end

    Core.Teletransportar(d.x + 0.0, d.y + 0.0, d.z + 0.0, tonumber(d.h))

    -- Tras la espera del teletransporte: ¿sigue la reunión?
    if not Mio() then return end
    if Juego.eliminado then return end
    FreezeEntityPosition(PlayerPedId(), Reunidos())
end)

RegisterNetEvent('origen_games:impostor:c:votar', function(d)
    if not Mio() or Juego.eliminado or Juego.fase ~= 'voto' or type(d) ~= 'table' then return end

    local opciones = {}
    for _, o in ipairs(d.opciones or {}) do
        local id = tonumber(o.id)
        if id then opciones[#opciones + 1] = { id = id, nombre = tostring(o.nombre or '') } end
    end

    Core.Votacion({
        titulo = '¿A quién echamos?',
        texto = st.dos and 'Vota a quien creas que es impostor. Si no lo tienes claro, salta.'
            or 'Vota a quien creas que es el impostor. Si no lo tienes claro, salta.',
        opciones = opciones,
        segundos = tonumber(d.segundos) or C.Reunion.voto,
        saltar = true,
    }, function(id)
        if not Mio() or Juego.eliminado or Juego.fase ~= 'voto' then return end
        id = tonumber(id)
        TriggerServerEvent('origen_games:impostor:s:votar', id or false)
        Core.Aviso(id and 'Voto enviado.' or 'Has saltado el voto.', 'info')
    end)
end)

RegisterNetEvent('origen_games:impostor:c:votacionFin', function()
    if not Mio() then return end
    Core.CerrarVotacion()
end)

RegisterNetEvent('origen_games:impostor:c:reanudar', function()
    if not Mio() or Juego.eliminado or Espectador.activo then return end
    FreezeEntityPosition(PlayerPedId(), false)
end)

--[[ ── Cada fotograma ─────────────────────────────────────────────────────── ]]
local function Pulsada(tecla) return IsDisabledControlJustPressed(0, tecla.control) end

local function Emergencias()
    local yo = Juego.yo or {}
    return tonumber(yo.emergencias) or C.Reunion.emergencias
end

--- El tripulante vivo más cercano a tiro de eliminar (sin contar al compañero
--- ni a los muertos sin descubrir, que M.Estado ya marca como no vivos).
local function Objetivo(pos)
    local comp = st.companero and st.companero.id
    local ocultos = {}
    for _, id in ipairs((Juego.yo and Juego.yo.ocultos) or {}) do
        if tonumber(id) then ocultos[tonumber(id)] = true end
    end
    local fila, _, d = Core.MasCercano(pos, function(f) return f.id ~= comp and not ocultos[f.id] end)
    if fila and d and d <= C.Asesinato.alcance then return { id = fila.id, nombre = fila.nombre, d = d } end
    return nil
end

--- El nombre del minijuego flotando sobre las tareas cercanas.
--[[ Rótulo «pegatina» en pantalla, centrado en (sx, sy): sombra dura,
     canto negro fino, pieza gris claro (rosa si acento) y tinta negra. ]]
local function Chapa(sx, sy, texto, escala, acento)
    texto = (tostring(texto or ''):gsub('~', ''))
    escala = escala or 0.35
    BeginTextCommandGetWidth('STRING')
    AddTextComponentSubstringPlayerName(texto)
    SetTextFont(4)
    SetTextScale(escala, escala)
    local w = EndTextCommandGetWidth(true) + 0.012
    local alto = GetRenderedCharacterHeight(escala, 4)
    local h = alto + 0.012
    DrawRect(sx + 0.0022, sy + 0.0040, w + 0.0015, h + 0.0027, 0, 0, 0, 255)
    DrawRect(sx, sy, w + 0.0015, h + 0.0027, 0, 0, 0, 255)
    if acento then
        DrawRect(sx, sy, w, h, 216, 27, 85, 255)
    else
        DrawRect(sx, sy, w, h, 220, 221, 224, 255)
    end
    SetTextFont(4)
    SetTextScale(escala, escala)
    SetTextColour(11, 11, 13, 255)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(texto)
    EndTextCommandDisplayText(sx, sy - alto * 0.62)
end

local function Texto3D(x, y, z, texto)
    local on, sx, sy = World3dToScreen2d(x, y, z)
    if on then Chapa(sx, sy, texto, 0.32) end
end

local function Dibujar(pos)
    for _, t in pairs(st.tareas) do
        if not t.hecha and Plano(pos, t.x, t.y) < 70.0 then
            DrawMarker(1, t.x, t.y, t.z - 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                1.3, 1.3, 0.5, 240, 180, 41, 110, false, false, 2, false, nil, nil, false)
            DrawMarker(0, t.x, t.y, t.z + 1.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.35, 0.35, 0.35, 240, 180, 41, 200, true, true, 2, false, nil, nil, false)
            if Plano(pos, t.x, t.y) < 12.0 then
                Texto3D(t.x, t.y, t.z + 1.8, 'Tarea: ' .. NombreTipo(t.tipo))
            end
        end
    end

    local z = Juego.zona
    if z then
        local cz = st.centroZ or z.z
        DrawMarker(1, z.x, z.y, cz - 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            1.4, 1.4, 0.7, 230, 40, 50, 170, false, false, 2, false, nil, nil, false)
        DrawMarker(27, z.x, z.y, cz + 0.03, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            C.Reunion.alcanceBoton * 2.0, C.Reunion.alcanceBoton * 2.0, 1.0, 230, 40, 50, 90, false, false, 2, false, nil, nil, false)
    end

    for _, c in pairs(st.cuerpos) do
        if Plano(pos, c.x, c.y) < 60.0 then
            DrawMarker(0, c.x, c.y, c.suelo + 1.4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.45, 0.45, 0.45, 230, 40, 50, 210, true, true, 2, false, nil, nil, false)
        end
    end
end

local function FrameTripulante(ahora, tarea)
    if tarea and Pulsada(T.accion) and ahora >= (st.proximoE or 0) then
        st.proximoE = ahora + 500
        AbrirTarea(tarea)
    end
end

local function FrameImpostor(pos, ahora, tarea)
    if Pulsada(T.accion) and ahora >= (st.proximoE or 0) then
        st.proximoE = ahora + 500
        local objetivo = Objetivo(pos)
        if objetivo and Core.Resta(st.recargaHasta) <= 0 then
            st.proximoE = ahora + 1200
            TriggerServerEvent('origen_games:impostor:s:eliminar', objetivo.id)
        elseif tarea then
            -- Fingir: el mismo minijuego en una tarea falsa.
            AbrirTarea(tarea)
        end
    end
end

function M.Frame(ahora)
    DisableControlAction(0, T.accion.control, true)
    DisableControlAction(0, T.reportar.control, true)
    -- Sin cuerpo a cuerpo ni disparos: aquí no se pega a nadie.
    DisablePlayerFiring(PlayerId(), true)
    for _, control in ipairs({ 24, 25, 140, 141, 142, 257, 263, 264 }) do
        DisableControlAction(0, control, true)
    end

    if Juego.eliminado then return end

    --[[ Con el minijuego abierto no se hace nada más: ni reportar ni eliminar.
         Solo se vigila que siga teniendo sentido (fase, tarea, cerca). ]]
    if st.minijuego then
        local t = st.tareas[st.minijuego.id]
        local pos = GetEntityCoords(PlayerPedId())
        if Juego.fase ~= 'juego' or not t or t.hecha or Plano(pos, t.x, t.y) > 3.0 then
            CerrarMinijuego()
        end
        return
    end

    if Reunidos() then
        DisableControlAction(0, 22, true)   -- saltar
        st.cerca = {}
        return
    end

    local fase = Juego.fase
    if fase ~= 'juego' and fase ~= 'preparacion' then return end

    local pos = GetEntityCoords(PlayerPedId())
    Dibujar(pos)

    if fase ~= 'juego' then
        st.cerca = {}
        return
    end

    local tarea = TareaCercana(pos, ahora)
    local cuerpo = CuerpoCercano(pos)
    local z = Juego.zona
    local centro = z and Plano(pos, z.x, z.y) <= C.Reunion.alcanceBoton - 0.3
    st.cerca = { tarea = tarea, cuerpo = cuerpo, centro = centro }

    if EsImpostor() then
        FrameImpostor(pos, ahora, tarea)
    elseif Juego.rol == 'tripulante' then
        FrameTripulante(ahora, tarea)
    end

    if Pulsada(T.reportar) and ahora >= (st.proximoG or 0) then
        st.proximoG = ahora + 1000
        if cuerpo then
            TriggerServerEvent('origen_games:impostor:s:reportar', cuerpo.id)
        elseif centro and Emergencias() > 0 then
            TriggerServerEvent('origen_games:impostor:s:emergencia')
        end
    end
end

function M.Lento()
    if Juego.eliminado then return end
    local pos = GetEntityCoords(PlayerPedId())

    for _, t in pairs(st.tareas) do
        if not t.apoyada and not t.hecha and Plano(pos, t.x, t.y) < 80.0 then Apoyar(t) end
    end

    local z = Juego.zona
    if z and not st.centroZ and Plano(pos, z.x, z.y) < 80.0 then
        local suelo = Core.Suelo(z.x, z.y, z.z)
        if suelo ~= z.z - 1.0 then st.centroZ = suelo end
    end

    st.objetivo = (EsImpostor() and Juego.fase == 'juego') and Objetivo(pos) or nil
end

--[[ ── El HUD ─────────────────────────────────────────────────────────────── ]]
local function AccionReportar(cerca)
    if cerca.cuerpo then
        return { id = 'reportar', tecla = T.reportar.texto, nombre = 'Reportar' }
    end
    local quedan = Emergencias()
    if cerca.centro then
        return { id = 'emergencia', tecla = T.reportar.texto, nombre = 'Emergencia', extra = tostring(quedan), apagada = quedan <= 0 }
    end
    return { id = 'reportar', tecla = T.reportar.texto, nombre = 'Reportar', extra = quedan > 0 and ('emergencia ' .. quedan) or nil, apagada = true }
end

local function PistaReportar(cerca)
    if cerca.cuerpo then
        return { tecla = T.reportar.texto, texto = 'Reportar el cuerpo de', destacado = cerca.cuerpo.nombre }
    end
    if cerca.centro and Emergencias() > 0 then
        return { tecla = T.reportar.texto, texto = 'Pulsar', destacado = 'Emergencia', detalle = 'Convoca una reunión' }
    end
    return nil
end

function M.Ficha()
    if Juego.eliminado or not Juego.rol then return nil end
    local yo = Juego.yo or {}
    local fase = Juego.fase
    local cerca = st.cerca or {}
    local enJuego = fase == 'juego'
    local equipo = tonumber(yo.equipo) or 0

    if EsImpostor() then
        local total = C.Asesinato.enfriamiento
        local quedan = Core.Resta(st.recargaHasta)
        local obj = enJuego and st.objetivo or nil

        local vida = {
            tipo = 'progreso', etiqueta = 'Eliminar',
            pct = quedan > 0 and math.floor((1 - quedan / total) * 100) or 100,
            cifra = quedan > 0 and (quedan .. ' s') or 'Lista',
        }

        --[[ E elimina si hay alguien a tiro con la recarga lista; si no, y hay
             una tarea falsa al lado, abre su minijuego para fingir. ]]
        local fingir = enJuego and cerca.tarea and not (obj and quedan <= 0)
        local acciones = {}
        if enJuego then
            local accionE
            if fingir then
                accionE = { id = 'tarea', tecla = T.accion.texto, nombre = NombreTipo(cerca.tarea.tipo) }
            else
                accionE = { id = 'eliminar', tecla = T.accion.texto, nombre = 'Eliminar', extra = quedan > 0 and (quedan .. 's') or nil,
                    apagada = quedan > 0 or not obj, carga = quedan > 0 and math.max(0, 1 - quedan / total) or nil }
            end
            acciones = { accionE, AccionReportar(cerca) }
        end

        local pista
        if enJuego then
            if obj then
                pista = {
                    tecla = T.accion.texto,
                    texto = quedan > 0 and 'Recargando' or 'Eliminar a',
                    destacado = obj.nombre,
                    detalle = quedan > 0 and (quedan .. ' s') or ('%.1f m'):format(obj.d),
                }
            else
                pista = PistaReportar(cerca)
                if not pista and cerca.tarea then
                    pista = { tecla = T.accion.texto, texto = 'Fingir', destacado = NombreTipo(cerca.tarea.tipo) }
                end
            end
        end

        return {
            tono = 'caza', icono = 'mascara',
            rol = 'Impostor',
            nombre = Reunidos() and 'Reunión' or 'Que no te pillen',
            renglon = st.companero and ('Con ' .. st.companero.nombre) or 'Elimina sin testigos',
            puntos = yo.puntos or 0,
            vida = vida,
            acciones = acciones,
            pista = pista,
        }
    end

    local total = tonumber(yo.tareasTotal) or 0
    local hechas = tonumber(yo.tareasHechas) or 0
    if total == 0 then
        for _, t in pairs(st.tareas) do
            total = total + 1
            if t.hecha then hechas = hechas + 1 end
        end
    end

    local vida = { tipo = 'progreso', etiqueta = 'Equipo', pct = equipo, cifra = equipo .. ' %' }

    local acciones = {}
    if enJuego then
        acciones = {
            { id = 'tarea', tecla = T.accion.texto, nombre = cerca.tarea and NombreTipo(cerca.tarea.tipo) or 'Tarea', apagada = not cerca.tarea },
            AccionReportar(cerca),
        }
    end

    local pista
    if enJuego then
        pista = PistaReportar(cerca)
        if not pista and cerca.tarea then
            pista = { tecla = T.accion.texto, texto = 'Tarea', destacado = NombreTipo(cerca.tarea.tipo) }
        end
    end

    return {
        tono = 'neutro', icono = 'mascara',
        rol = 'Tripulante',
        nombre = Reunidos() and 'Reunión' or 'Haz tus tareas',
        renglon = ('Tus tareas %d/%d · Equipo %d %%'):format(hechas, total, equipo),
        puntos = yo.puntos or 0,
        vida = vida,
        acciones = acciones,
        pista = pista,
    }
end

function M.Cartel()
    if Juego.eliminado or Juego.fase ~= 'preparacion' or not Juego.rol then return nil end
    local k = ('Ronda %d de %d'):format(Juego.ronda or 0, Juego.rondas or 0)
    if EsImpostor() then
        return {
            k = k,
            t = 'Eres el impostor',
            m = st.companero and ('Tu compañero es %s. Eliminad a la tripulación sin que os pillen.'):format(st.companero.nombre)
                or 'Elimina a la tripulación sin que te pillen.',
        }
    end
    local n = 0
    for _ in pairs(st.tareas) do n = n + 1 end
    return {
        k = k,
        t = 'Eres tripulante',
        m = ('Haz tus %d tareas y descubre %s.'):format(n, st.dos and 'a los impostores' or 'al impostor'),
    }
end

function M.Fondo()
    if Juego.eliminado or Juego.fase ~= 'preparacion' or not Juego.rol then return nil end
    return EsImpostor() and 'cazador' or 'prop'
end

RegistrarJuego(ID, M)
