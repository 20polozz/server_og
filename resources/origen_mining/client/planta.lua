--[[ ── El capataz y la planta ─────────────────────────────────────────────────

     El capataz y su panel (con él se empieza y se acaba todo: jornada,
     herramienta, carretilla, vehículo y cargas), la tolva y los puntos del
     mapa.

     La planta es la de origen_planta (tolva, cintas, trituradora,
     contenedor y fundición), puesta en Config.Planta. Cuando alguien
     descarga, las piedras suben por la cinta, se trituran y el contenedor
     se llena; de ahí se lleva el material al horno. ]]

local M = Config.Mina
local abierto = false

Planta = {}

-- ── Mapa ──────────────────────────────────────────────────────────────────

CreateThread(function()
    OrigenMapa.Poner('cantera', {
        x = M.centro.x, y = M.centro.y, z = M.centro.z,
        cat = 'trabajos', icono = 'pico', nombre = M.nombre,
    })
end)

--- De jornada se ven los frentes (zonas con su radio), la tolva y el capataz.
local puestos = false
local function PuntosDeJornada(jornada)
    local puntos = {}
    if jornada then
        for _, f in ipairs(Config.Frentes) do
            puntos[#puntos + 1] = {
                id = f.id, x = f.centro.x, y = f.centro.y, z = f.centro.z,
                cat = 'trabajos', icono = 'pico', radio = f.radio + 0.0, nombre = f.nombre,
            }
        end
    end
    OrigenMapa.PonerVarios('frente', puntos)
    local sitios = {}
    if jornada then
        local d, e = Mina.Descarga(), M.Peds.Capataz.coords
        sitios = {
            { id = 'tolva', x = d.x, y = d.y, z = d.z, cat = 'trabajos', icono = 'paquete', nombre = 'Tolva de la planta (descarga)' },
            { id = 'capataz', x = e.x, y = e.y, z = e.z, cat = 'trabajos', icono = 'persona', nombre = 'Capataz de la cantera' },
        }
    end
    OrigenMapa.PonerVarios('sitio', sitios)
end

CreateThread(function()
    while true do
        local jornada = L.Jornada()
        if jornada ~= puestos then
            puestos = jornada
            PuntosDeJornada(jornada)
        end
        -- El vehículo, detrás de él.
        local mio = Vehiculos.mio
        local veh = mio and Vehiculos.Entidad(mio.vehiculo)
        if veh and not Vehiculos.marcado then
            Vehiculos.marcado = veh
            OrigenMapa.Poner('alquiler', {
                entidad = veh, cat = 'trabajos', icono = 'camion', color = '#fc0259', propio = true,
                nombre = (Config.Vehiculos.tipos[mio.tipo] or Config.Vehiculos.tipos.camioneta).nombre,
            })
        elseif not veh and Vehiculos.marcado then
            Vehiculos.marcado = nil
            OrigenMapa.Quitar('alquiler')
        elseif veh and Vehiculos.marcado ~= veh then
            Vehiculos.marcado = nil
        end
        Wait(3000)
    end
end)

-- ── La planta ─────────────────────────────────────────────────────────────
--[[ Los props y su movimiento son de origen_planta (exports). Cada cliente
     monta la suya a menos de 250 m y la mueve con lo que le avisa el
     servidor en cada descarga: todos ven lo mismo, cada uno en local. ]]

local PL = exports.origen_planta
local ids = nil          -- tipo de máquina → id de origen_planta
local escondidos = {}    -- modelos del mapa escondidos: { pos, modelo }
local montada = false

-- Veta → material de los props (la piedra corriente es grava).
local MAT = { piedra = 'grava', carbon = 'carbon', hierro = 'hierro', cobre = 'cobre', cuarzo = 'cuarzo', oro = 'oro' }
local METALES = { hierro = true, cobre = true, oro = true }

local function PlantaLista()
    return GetResourceState('origen_planta') == 'started'
end

-- Un punto del mundo, en el marco de un ancla (x, y, z, rumbo).
local function EnMarco(ancla, p)
    local w = math.rad(-ancla.w)
    local dx, dy = p.x - ancla.x, p.y - ancla.y
    return dx * math.cos(w) - dy * math.sin(w), dx * math.sin(w) + dy * math.cos(w)
end

--[[ Esconde lo que el mapa tiene dentro de los rectángulos. Se repasa cada
     poco: los props del mapa aparecen al acercarse (streaming). ]]
local function Despejar()
    local P = Config.Planta
    local nuestros = {}
    for _, id in pairs(ids or {}) do
        local e = PL:Entidad(id)
        if e then nuestros[e] = true end
    end
    for _, o in ipairs(GetGamePool('CObject')) do
        if not nuestros[o] and not IsEntityAMissionEntity(o) and IsEntityVisible(o) then
            local c = GetEntityCoords(o)
            for _, zona in ipairs({ { P.ancla, P.despejar }, { P.fundicion, P.despejar_fundicion } }) do
                local x, y = EnMarco(zona[1], c)
                for _, r in ipairs(zona[2]) do
                    if x >= r[1] and x <= r[2] and y >= r[3] and y <= r[4] and math.abs(c.z - zona[1].z) < 6.0 then
                        local m = GetEntityModel(o)
                        CreateModelHide(c.x, c.y, c.z, 0.5, m, true)
                        escondidos[#escondidos + 1] = { pos = c, modelo = m }
                    end
                end
            end
        end
    end
end

local Fundicion = { ocupada = false }
local monton = { nivel = 0.0, mat = 'grava' }
Planta.Fundicion = Fundicion
function Planta.Ids() return ids end

local function Desmontar()
    for _, id in pairs(ids or {}) do PL:Borrar(id) end
    ids = nil
    for _, h in ipairs(escondidos) do RemoveModelHide(h.pos.x, h.pos.y, h.pos.z, 0.5, h.modelo, false) end
    escondidos = {}
    montada = false
    Fundicion.ocupada = false
end

local function Montar()
    Desmontar()
    if not PlantaLista() then return end
    local a, f = Config.Planta.ancla, Config.Planta.fundicion
    ids = PL:CrearPlanta(a.xyz, a.w, true, { fundicion = true })
    local z = PL:Suelo('fundicion', vec3(f.x, f.y, f.z), f.w) or f.z
    ids.fundicion = PL:Crear('fundicion', vec3(f.x, f.y, z), f.w)
    -- La balsa de temple y el carro de lingotes, al lado (origen_planta los coloca).
    for k, id in pairs(PL:CrearJunto(ids.fundicion) or {}) do ids[k] = id end
    -- La fundición siempre está encendida: quemador y chimenea.
    PL:Efecto(ids.fundicion, 'fuego', true)
    PL:Efecto(ids.fundicion, 'humo', true)
    montada = true
    Despejar()
    Planta.PedirVista()
end

-- Si origen_planta se para o se reinicia, sus props desaparecen con él: se
-- da la planta por desmontada y el bucle del capataz la vuelve a montar.
AddEventHandler('onClientResourceStop', function(r)
    if r ~= 'origen_planta' then return end
    ids, montada = nil, false
    Fundicion.ocupada = false
end)

-- ── La planta en marcha ──────────────────────────────────────────────────
-- Anda mientras le llegue material; se para sola unos segundos después.
local marchaHasta, enMarcha = 0, false
local CADENA = { 'generador', 'caseta', 'trituradora', 'cinta_subida', 'cinta_salida' }

local function Arrancar(segundos)
    if not ids then return end
    marchaHasta = math.max(marchaHasta, GetGameTimer() + segundos * 1000)
    if enMarcha then return end
    enMarcha = true
    -- El generador arranca primero; la baliza avisa y luego la cadena.
    PL:Marcha(ids.generador, true)
    PL:Marcha(ids.caseta, true)
    SetTimeout(900, function()
        if ids and enMarcha then
            for _, k in ipairs(CADENA) do PL:Marcha(ids[k], true) end
        end
    end)
    CreateThread(function()
        while enMarcha and GetGameTimer() < marchaHasta do Wait(500) end
        enMarcha = false
        if ids then for _, k in ipairs(CADENA) do PL:Marcha(ids[k], false) end end
    end)
end

--[[ Una descarga: cada pedrusco entra a la cinta bajo la tolva con el color
     de su veta y sube a la trituradora (lo sigue el evento `llega`). ]]
function Planta.Triturar(vetas, ms)
    if not ids or type(vetas) ~= 'table' then return end
    local n = math.min(#vetas, 12)
    Arrancar(40)
    PL:Efecto(ids.tolva, 'polvo_descarga', true)
    SetTimeout(math.max(2500, n * 900), function() if ids then PL:Efecto(ids.tolva, 'polvo_descarga', false) end end)
    for i = 1, n do
        local mat = MAT[vetas[i]] or 'grava'
        SetTimeout((i - 1) * 900, function()
            if ids then PL:Echar(ids.cinta_subida, 'origen_planta_piedra_' .. mat, 1.9) end
        end)
    end
end

-- ── Lo que ven todos: el montón y la fundición ────────────────────────
--[[ El servidor dice cuánto hay ENTRE TODOS en el contenedor y en el horno
     (server/planta.lua, evento `origen_mining:planta`). El montón sube y baja
     con eso y toma el color de lo que más hay; mientras haya algo en el
     horno, la fundición hace coladas del metal que más se esté fundiendo. ]]
local vista = { cont = {}, horno = {}, lingotes = {} }

-- El carro junto a la fundición enseña los lingotes que esperan dueño
-- (de todos), hasta doce, del metal que haya en cada hueco.
local ORDEN_METAL = { 'oro', 'cobre', 'hierro' }
local function PintarCarro()
    if not ids or not ids.carro then return end
    local huecos = {}
    for _, m in ipairs(ORDEN_METAL) do
        for _ = 1, math.floor(tonumber(vista.lingotes[m]) or 0) do
            if #huecos < 12 then huecos[#huecos + 1] = m end
        end
    end
    -- Abajo lo que más hay: se llena de abajo arriba.
    for k = 1, 12 do
        local m = huecos[#huecos - k + 1]
        if m then PL:Cambiar(ids.carro, 'l' .. k, m) end
        PL:Mostrar(ids.carro, 'l' .. k, m ~= nil)
    end
end

local function Mayor(t)
    local mejor, n = nil, 0
    for m, x in pairs(t or {}) do
        if (tonumber(x) or 0) > n then mejor, n = m, tonumber(x) end
    end
    return mejor, n
end

local function PintarMonton()
    if not ids then return end
    local total = 0
    for _, n in pairs(vista.cont) do total = total + (tonumber(n) or 0) end
    local mat = MAT[Mayor(vista.cont) or ''] or monton.mat
    if mat ~= monton.mat then
        monton.mat = mat
        PL:Cambiar(ids.contenedor, 'monton', mat)
    end
    monton.nivel = math.min(1.0, total / Config.Planta.lleno_visual)
    PL:Mover(ids.contenedor, 'monton', -1.1 + 1.1 * monton.nivel, 2.0)
end

RegisterNetEvent('origen_mining:planta', function(v)
    if type(v) ~= 'table' then return end
    vista = { cont = type(v.cont) == 'table' and v.cont or {}, horno = type(v.horno) == 'table' and v.horno or {},
              lingotes = type(v.lingotes) == 'table' and v.lingotes or {} }
    PintarMonton()
    PintarCarro()
end)

--- Al montar la planta: cómo está ahora.
function Planta.PedirVista()
    CreateThread(function()
        local v = lib.callback.await('origen_mining:plantaVista', false)
        if type(v) == 'table' then
            vista = { cont = v.cont or {}, horno = v.horno or {}, lingotes = v.lingotes or {} }
            PintarMonton()
            PintarCarro()
        end
    end)
end

AddEventHandler('origen_planta:llega', function(id, modelo)
    if not ids then return end
    local mat = modelo:match('_(%a+)$')
    if id == ids.cinta_subida then
        -- Cae a la trituradora: sale partida en dos trozos por la cinta de salida.
        Arrancar(30)
        SetTimeout(1500, function()
            if not ids then return end
            PL:Echar(ids.cinta_salida, 'origen_planta_trozo_' .. mat, 0.4)
            SetTimeout(500, function() if ids then PL:Echar(ids.cinta_salida, 'origen_planta_trozo_' .. mat, 0.4) end end)
        end)
    end
end)

-- Alguien echa al horno: la tapa se abre un momento.
RegisterNetEvent('origen_mining:hornoEcha', function(_, _, ms)
    if not ids or Fundicion.ocupada then return end
    PL:Mover(ids.fundicion, 'tapa', 60.0, 0.5)
    SetTimeout(math.max(900, tonumber(ms) or 0), function()
        if ids and not Fundicion.ocupada then PL:Mover(ids.fundicion, 'tapa', 0.0, 0.8) end
    end)
end)

-- Mientras haya algo fundiéndose (de quien sea), coladas: tantos moldes
-- como pedruscos haya en el horno de ese metal (hasta seis).
CreateThread(function()
    while true do
        Wait(3000)
        if ids and not Fundicion.ocupada then
            local m, n = Mayor(vista.horno)
            if m and METALES[m] then Fundicion.Colada(m, n) end
        end
    end
end)

-- ── La fundición ─────────────────────────────────────────────────────────
--[[ Una colada: abre la tapa, el horno se llena, vuelca sobre el carrusel
     molde a molde (uno por pedrusco, hasta seis) y los lingotes se enfrían
     al metal que era. Se quedan en los moldes hasta que alguien recoge sus
     lingotes (Fundicion.Vaciar), o unos minutos. ]]
local vaciarEn = 0

function Fundicion.Vaciar(segundos)
    local f = ids and ids.fundicion
    if not f then return end
    vaciarEn = 0
    for k = 1, 6 do PL:Mover(f, 'metal' .. k, -0.08, segundos or 1.0) end
    SetTimeout(math.floor((segundos or 1.0) * 1000) + 200, function()
        if ids and ids.fundicion == f and not Fundicion.ocupada then
            for k = 1, 6 do PL:Cambiar(f, 'metal' .. k, 'caliente') end
        end
    end)
end

-- Lo que nadie recoge se retira solo a los tres minutos.
CreateThread(function()
    while true do
        Wait(5000)
        if vaciarEn > 0 and GetGameTimer() > vaciarEn and not Fundicion.ocupada then Fundicion.Vaciar(1.5) end
    end
end)

-- La cesta del polipasto: baja al rojo, hierve el agua y sube templada.
local function Templar(mat)
    local t = ids and ids.temple
    if not t then return end
    CreateThread(function()
        local dentro = (PL:Notas('temple') or {}).dentro or -0.75
        PL:Cambiar(t, 'cesta', 'caliente')
        PL:Luz(t, 'cesta', true)
        Wait(600)
        PL:Mover(t, 'cesta', dentro, 3.0)
        Wait(2200)
        -- El metal al rojo toca el agua: estallido de vapor.
        PL:Efecto(t, 'hervor', true)
        SetTimeout(2500, function() if ids and ids.temple == t then PL:Efecto(t, 'hervor', false) end end)
        Wait(400)
        PL:Efecto(t, 'vapor', true)
        PL:Luz(t, 'cesta', false)
        Wait(900)
        if not ids or ids.temple ~= t then return end
        PL:Cambiar(t, 'cesta', mat)
        Wait(3500)
        PL:Mover(t, 'cesta', 0.0, 3.0)
        Wait(3500)
        PL:Efecto(t, 'vapor', false)
        Wait(4000)
        if ids and ids.temple == t then PL:Cambiar(t, 'cesta', 'vacia') end
    end)
end

function Fundicion.Colada(mat, n)
    local f = ids and ids.fundicion
    if not f or Fundicion.ocupada then return end
    Fundicion.ocupada = true
    n = math.max(1, math.min(6, math.floor(tonumber(n) or 6)))
    CreateThread(function()
        local function vivo() return ids and ids.fundicion == f end
        -- Moldes limpios antes de empezar.
        for k = 1, 6 do PL:Mover(f, 'metal' .. k, -0.08, 0.6) end
        Wait(700)
        for k = 1, 6 do PL:Cambiar(f, 'metal' .. k, 'caliente') end
        PL:Luz(f, 'horno', true)
        PL:Efecto(f, 'brasas', true)
        PL:Mover(f, 'tapa', 75.0, 1.5)
        Wait(1800)
        PL:Cambiar(f, 'horno', 'lleno')
        Wait(2500)
        PL:Mover(f, 'tapa', 0.0, 1.5)
        Wait(1800)
        PL:Mover(f, 'horno', -55.0, 2.5)
        Wait(2700)
        for k = 1, n do
            if not vivo() then return end
            PL:Mover(f, 'carrusel', -60.0 * (k - 1), 1.2)
            Wait(1400)
            PL:Mostrar(f, 'chorro', true)
            PL:Efecto(f, 'vertido', true)
            PL:Efecto(f, 'chispas', true)
            PL:Luz(f, 'chorro', true)
            PL:Luz(f, 'moldes', true)
            PL:Mover(f, 'metal' .. k, 0.0, 2.2)
            Wait(2400)
            PL:Mostrar(f, 'chorro', false)
            PL:Efecto(f, 'vertido', false)
            PL:Efecto(f, 'chispas', false)
            PL:Luz(f, 'chorro', false)
        end
        if not vivo() then return end
        PL:Mover(f, 'horno', 0.0, 2.5)
        PL:Mover(f, 'carrusel', 0.0, 2.0)
        Wait(2600)
        PL:Cambiar(f, 'horno', 'vacio')
        PL:Efecto(f, 'brasas', false)
        PL:Luz(f, 'horno', false)
        -- Enfriarse: del rojo al metal, entre vapor. A la vez, en la balsa se
        -- templa una cesta de la hornada anterior.
        PL:Efecto(f, 'vapor', true)
        Templar(mat)
        for k = 1, n do
            Wait(2500)
            if not vivo() then return end
            PL:Cambiar(f, 'metal' .. k, mat)
        end
        PL:Luz(f, 'moldes', false)
        SetTimeout(3000, function() if ids and ids.fundicion == f then PL:Efecto(f, 'vapor', false) end end)
        vaciarEn = GetGameTimer() + 180000
        Fundicion.ocupada = false
    end)
end

--[[ La compuerta del contenedor y el horno: E abre el panel en «Planta»
     (lo tuyo: recoger del contenedor, recoger lingotes). Echar al horno lo
     que llevas triturado es otra cosa: lo lleva client/trabajo.lua. ]]
CreateThread(function()
    local texto = nil
    while true do
        local espera = 700
        local quiero = nil
        if ids and montada and not cache.vehicle and not L.panelAbierto and not L.ocupado then
            local pos = GetEntityCoords(cache.ped)
            local r, rr = Mina.Recoger()
            local h, hr = Mina.Horno()
            local dr, dh = #(pos.xy - r.xy), #(pos.xy - h.xy)
            if dr < 20.0 or dh < 20.0 then espera = 0 end
            if dr <= rr and not L.Mano() then
                quiero = { 'Contenedor: lo tuyo', r }
            elseif dh <= hr and not L.Mano() and not L.Empuja() then
                quiero = { 'Fundición: tus lingotes', h }
            end
            if quiero and IsControlJustReleased(0, 38) then
                L.QuitarAyuda('planta')
                texto = nil
                local punto = quiero[2]
                CreateThread(function() AbrirPanel('planta', punto) end)
                quiero = nil
            end
        end
        local t = quiero and quiero[1] or nil
        if t ~= texto then
            texto = t
            if t then L.Ayuda('planta', 'E', t) else L.QuitarAyuda('planta') end
        end
        Wait(espera)
    end
end)

-- ── El capataz ────────────────────────────────────────────────────────────

local capataz = nil

local function CrearNPC(cfg)
    local hash = GetHashKey(cfg.modelo)
    if not Cantera.Cargar(hash) then return nil end
    local c = cfg.coords
    local z = Cantera.Suelo(c.x, c.y, c.z) or c.z
    local ped = Rastro.Marcar(CreatePed(4, hash, c.x, c.y, z, c.w, false, false))
    SetModelAsNoLongerNeeded(hash)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    return ped
end

--[[ Rehacer lo que se ve: lo llama el editor cuando se mueve un sitio. ]]
local rehacer = false
function Cantera.Rehacer()
    rehacer = true
    Cantera.RehacerBloques()
end

CreateThread(function()
    local cfg = M.Peds.Capataz
    local conTexto = false
    while true do
        local espera = 1000
        local pos = GetEntityCoords(cache.ped)
        local c = cfg.coords
        local d = #(pos - c.xyz)
        if rehacer then
            rehacer = false
            if capataz then Cantera.Borrar(capataz) capataz = nil end
            if montada then Montar() end
            PuntosDeJornada(L.Jornada())
        end
        if d < 70.0 and not capataz then
            capataz = CrearNPC(cfg)
        elseif d >= 70.0 and capataz then
            Cantera.Borrar(capataz)
            capataz = nil
        end
        -- La planta: montada mientras estés a menos de 250 m. Lo del mapa que
        -- estorba se repasa cada 5 s de cerca (va apareciendo al acercarse).
        local dp = #(pos.xy - Config.Planta.ancla.xy)
        if dp < 250.0 and not montada then Montar()
        elseif dp >= 280.0 and montada then Desmontar() end
        if montada and dp < 160.0 and GetGameTimer() > (Planta.despejado or 0) then
            Planta.despejado = GetGameTimer() + 5000
            Despejar()
        end

        if d < 12.0 then espera = 0 end
        local cerca = d <= 2.3 and not abierto and not cache.vehicle and not L.ocupado
        if cerca and not conTexto then
            conTexto = true
            L.Ayuda('npc', 'E', L.Jornada() and 'Hablar con el capataz' or 'Empezar la jornada con el capataz')
        elseif not cerca and conTexto then
            conTexto = false
            L.QuitarAyuda('npc')
        end
        if cerca and IsControlJustReleased(0, 38) then
            conTexto = false
            L.QuitarAyuda('npc')
            AbrirPanel('jornada')
        end
        Wait(espera)
    end
end)

-- ── El panel ──────────────────────────────────────────────────────────────

local abiertoEn = nil     -- dónde se abrió: el capataz, el contenedor o el horno

--[[ Los jugadores que tengo al lado, para que el servidor no recorra a los
     300 conectados al montar el panel (equipo: a quien se puede invitar). El
     juego solo da por aqui a los de mi zona (GetActivePlayers); el servidor
     comprueba la distancia de verdad de cada uno. ]]
local function ConCercanos(d)
    d = type(d) == 'table' and d or {}
    local yo, mio, t = GetEntityCoords(PlayerPedId()), PlayerId(), {}
    for _, id in ipairs(GetActivePlayers()) do
        if id ~= mio then
            local ped = GetPlayerPed(id)
            if ped ~= 0 and #(GetEntityCoords(ped) - yo) < 60.0 then t[#t + 1] = GetPlayerServerId(id) end
        end
    end
    d.cercanos = t
    return d
end

function AbrirPanel(seccion, punto)
    if abierto then return end
    abierto = true
    abiertoEn = punto or M.Peds.Capataz.coords.xyz
    local r = lib.callback.await('origen_mining:panel:abrir', false, ConCercanos({}))
    if not r or not r.datos then
        abierto = false
        L.Nui('cerrar')
        L.Aviso((r and r.mensaje) or 'La cantera no puede atenderte ahora.', 'error')
        return
    end
    r.datos.seccion = seccion or 'jornada'
    L.panelAbierto = true
    L.EsconderTarjetas()
    SetNuiFocus(true, true)
    L.Nui('abrir', r.datos)
end

function CerrarPanel()
    if not abierto then return end
    abierto = false
    L.panelAbierto = false
    SetNuiFocus(false, false)
    -- Si en estos 280 ms se ha vuelto a abrir, el 'cerrar' tardío no puede
    -- esconder el panel nuevo.
    SetTimeout(280, function() if not abierto then L.Nui('cerrar') end end)
    CreateThread(L.PedirYo)
end

-- Ratón soltado a la fuerza (soltarraton, pantalla colgada): el panel se da
-- por cerrado y se esconde, o no volvería a abrirse.
OrigenFoco.AlSoltar(function() CerrarPanel() end)

CreateThread(function()
    while true do
        Wait(1000)
        if abierto and abiertoEn and #(GetEntityCoords(cache.ped) - abiertoEn) > 12.0 then CerrarPanel() end
    end
end)

RegisterNUICallback('cerrar', function(_, cb)
    CerrarPanel()
    cb({ ok = true })
end)

for _, nombre in ipairs({ 'refrescar', 'empezar', 'terminar', 'herramienta', 'comprarCargas', 'marcarFrente', 'marcarPlanta',
    'equipoInvitar', 'equipoSalir', 'equipoExpulsar', 'recoger', 'lingotes', 'vender' }) do
    RegisterNUICallback(nombre, function(d, cb)
        local r = lib.callback.await('origen_mining:panel:' .. nombre, false, ConCercanos(d))
        cb(r or { ok = false, mensaje = 'La cantera no contesta.' })
        -- Al recoger se abre la compuerta; con metal en brazos, el panel se cierra.
        if r and r.ok and nombre == 'recoger' and ids then
            PL:Mover(ids.contenedor, 'compuerta', 95.0, 0.6)
            SetTimeout(1800, function() if ids then PL:Mover(ids.contenedor, 'compuerta', 0.0, 0.8) end end)
        end
        -- Al recoger los lingotes, los moldes se vacían.
        if r and r.ok and nombre == 'lingotes' and not Fundicion.ocupada then Fundicion.Vaciar(0.8) end
        if r and r.cerrar then CerrarPanel() end
        if r and r.ok and r.punto then SetNewWaypoint(r.punto.x + 0.0, r.punto.y + 0.0) end
        if r and r.ok and nombre == 'empezar' then
            CreateThread(function()
                Wait(600)
                Vehiculos.mio = lib.callback.await('origen_mining:miVehiculo', false)
            end)
        end
        if r and r.ok and nombre == 'terminar' then Vehiculos.mio = nil end
    end)
end

RegisterNUICallback('marcarVehiculo', function(_, cb)
    local mio = Vehiculos.mio
    local ent = mio and Vehiculos.Entidad(mio.vehiculo)
    if ent then
        local c = GetEntityCoords(ent)
        SetNewWaypoint(c.x, c.y)
        L.Aviso('Ruta marcada a tu vehículo.', 'success')
        return cb({ ok = true })
    end
    cb({ ok = false, mensaje = 'No veo tu vehículo desde aquí.' })
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    if abierto then SetNuiFocus(false, false) end
    if capataz then Cantera.Borrar(capataz) end
    Desmontar()
end)
