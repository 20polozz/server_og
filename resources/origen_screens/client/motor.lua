-- ════════════════════════════════════════════════════════════════════
--  origen_screens · el motor de las teles
--
--  Cualquier recurso registra aquí una tele (exports.origen_screens:
--  RegistrarTele) y el motor se encarga del resto:
--
--   * QUÉ se ve: el servidor publica el estado de cada tele en
--     GlobalState['tele:<id>'] = { tipo, ref, clase, inicio, pausa, volumen }.
--     `inicio` es el GetGameTimer() DEL SERVIDOR en el que el vídeo estaba en
--     el segundo 0, así que quien llega tarde calcula por dónde va.
--   * DÓNDE se pinta: en la pantalla del propio modelo, con su render target
--     (Config.Modelos). Todos los props de un mismo render target enseñan lo
--     mismo, así que nunca se reparte uno a dos teles distintas: gana la más
--     cercana. Las pantallas de pared de los admins van con DrawTexturedPoly.
--   * CUÁNTAS: cada tele que se ve es un navegador (DUI). Solo las
--     Config.MaxReproduciendo más cercanas; el resto no pinta nada.
--   * SONIDO: por distancia, y silencio en otro interior.
-- ════════════════════════════════════════════════════════════════════

Motor = {}

local teles = {}          -- id -> registro
local slots = {}          -- navegadores: { dui, txd, tele, clave, vol, latido, nace, libreDesde }
local rts = {}            -- render target -> { id, propio }
local desfase = 0         -- reloj del servidor - GetGameTimer() local
local pendientesDespertar = {}

-- Modo streamer (/streamermode, de origen_businesses): las teles siguen
-- pintando, pero mudas.
local silencioStreamer = false

AddEventHandler('origen:modoStreamer', function(activo)
    silencioStreamer = activo == true
end)

CreateThread(function()
    if GetResourceState('origen_businesses') ~= 'started' then return end
    local ok, activo = pcall(function() return exports.origen_businesses:EnModoStreamer() end)
    if ok and activo then silencioStreamer = true end
end)

local W, H = Config.PaginaAncho or 1280, Config.PaginaAlto or 720

-- ── Utilidades ──────────────────────────────────────────────────────
local function vec(t)
    if type(t) == 'vector3' then return t end
    if type(t) ~= 'table' then return nil end
    local x, y, z = tonumber(t.x), tonumber(t.y), tonumber(t.z)
    if not x or not y or not z then return nil end
    return vector3(x, y, z)
end

local function DentroZona(p, zona)
    local dentro, j = false, #zona
    for i = 1, #zona do
        local xi, yi, xj, yj = zona[i].x, zona[i].y, zona[j].x, zona[j].y
        if ((yi > p.y) ~= (yj > p.y)) and (p.x < (xj - xi) * (p.y - yi) / (yj - yi) + xi) then
            dentro = not dentro
        end
        j = i
    end
    return dentro
end

function Motor.Estado(id)
    return GlobalState['tele:' .. id]
end

-- ── Reloj del servidor ──────────────────────────────────────────────
local function SincronizarReloj()
    local t0 = GetGameTimer()
    local srv = lib.callback.await('origen_screens:server:reloj', false)
    local t1 = GetGameTimer()
    if type(srv) == 'number' then
        desfase = srv - math.floor((t0 + t1) / 2)
    end
end

function Motor.Posicion(st)
    if st.pausa then return math.max(0, tonumber(st.pausa) or 0) end
    return math.max(0, ((GetGameTimer() + desfase) - (tonumber(st.inicio) or 0)) / 1000)
end

-- ── Registro ────────────────────────────────────────────────────────
-- datos (una de tres formas):
--   { entidad = handle }                     un prop que ya existe (muebles)
--   { modelo = hash|nombre, coords = vec3 }  un prop del mapa (se busca solo)
--   { esquinas = {c1,c2,c3,c4}, zona = {…} } una pantalla de pared
-- y además: nombre, oculta, mirarInterior (false para las casas), despertar.
function Motor.Registrar(id, datos)
    if type(id) ~= 'string' or #id == 0 or #id > 120 or type(datos) ~= 'table' then return false end

    local r = {
        id = id,
        nombre = datos.nombre,
        oculta = datos.oculta == true,
        mirarInterior = datos.mirarInterior ~= false,
    }

    if datos.entidad then
        if not DoesEntityExist(datos.entidad) then return false end
        local info = Config.ModelosPorHash[GetEntityModel(datos.entidad)]
        if not info then return false end
        r.entidad, r.modelo, r.rt = datos.entidad, GetEntityModel(datos.entidad), info.rt
    elseif datos.modelo and datos.coords then
        local modelo = type(datos.modelo) == 'number' and datos.modelo or GetHashKey(datos.modelo)
        local info = Config.ModelosPorHash[modelo]
        local ancla = vec(datos.coords)
        if not info or not ancla then return false end
        r.modelo, r.rt, r.ancla = modelo, info.rt, ancla
    elseif datos.esquinas then
        local e = datos.esquinas
        local c1, c2, c3, c4 = vec(e.c1), vec(e.c2), vec(e.c3), vec(e.c4)
        if not c1 or not c2 or not c3 or not c4 then return false end
        r.esquinas = { c1 = c1, c2 = c2, c3 = c3, c4 = c4 }
        r.centro = (c1 + c4) * 0.5
        if type(datos.zona) == 'table' and #datos.zona >= 3 then r.zona = datos.zona end
    else
        return false
    end

    teles[id] = r
    if datos.despertar and not Motor.Estado(id) then pendientesDespertar[id] = true end
    return true
end

function Motor.Quitar(id)
    teles[id] = nil
    pendientesDespertar[id] = nil
end

function Motor.Ocultar(id, oculta)
    if teles[id] then teles[id].oculta = oculta == true end
end

function Motor.Registro(id)
    return teles[id]
end

local function Centro(r)
    if r.esquinas then return r.centro end
    if r.entidad and DoesEntityExist(r.entidad) then return GetEntityCoords(r.entidad) end
    return r.ancla
end
Motor.Centro = Centro

-- Los props del mapa no tienen handle fijo: se buscan cuando estás cerca.
local function ResolverEntidad(r, pos)
    if not r.ancla then return end
    if r.entidad and DoesEntityExist(r.entidad) then return end
    r.entidad = nil
    if #(pos - r.ancla) > Config.DistanciaVer + 10.0 then return end
    local e = GetClosestObjectOfType(r.ancla.x, r.ancla.y, r.ancla.z, 1.5, r.modelo, false, false, false)
    if e and e ~= 0 then r.entidad = e end
end

-- ── Render targets ──────────────────────────────────────────────────
local function EngancharRT(r)
    local u = rts[r.rt]
    if not u then
        u = { propio = not IsNamedRendertargetRegistered(r.rt) }
        if u.propio then RegisterNamedRendertarget(r.rt, false) end
        rts[r.rt] = u
    end
    if not IsNamedRendertargetLinked(r.modelo) then LinkNamedRendertarget(r.modelo) end
    u.id = GetNamedRendertargetRenderId(r.rt)
end

-- Se mira `slot.rt` y no el registro: la tele puede haberse quitado ya del
-- registro (el mueble se borró) cuando se suelta su navegador.
local function SoltarRT(rt)
    for _, s in ipairs(slots) do
        if s.tele and s.rt == rt then return end
    end
    local u = rts[rt]
    if u and u.propio and IsNamedRendertargetRegistered(rt) then ReleaseNamedRendertarget(rt) end
    rts[rt] = nil
end

-- ── Navegadores ─────────────────────────────────────────────────────
local function Enviar(slot, datos)
    if not slot.dui or GetGameTimer() - slot.nace < 1500 then return false end
    datos.tele = 1
    SendDuiMessage(slot.dui, json.encode(datos))
    return true
end

local function CrearDui(i, slot)
    slot.creando = true
    slot.n = (slot.n or 0) + 1
    local dui = CreateDui(Config.Pagina, W, H)
    local limite = GetGameTimer() + 5000
    while not IsDuiAvailable(dui) and GetGameTimer() < limite do Wait(20) end
    -- Un runtime txd no se puede borrar: si el navegador se recrea, nombre nuevo.
    local nombre = ('origen_tele_%d_%d'):format(i, slot.n)
    local txd = CreateRuntimeTxd(nombre)
    CreateRuntimeTextureFromDuiHandle(txd, 'video', GetDuiHandle(dui))
    slot.dui, slot.txd, slot.nace = dui, nombre, GetGameTimer()
    slot.latido, slot.vol, slot.clave = 0, -1, nil
    slot.creando = false
end

local function SoltarSlot(slot)
    Enviar(slot, { accion = 'vaciar' })
    local rt = slot.rt
    slot.tele, slot.rt, slot.clave, slot.vol = nil, nil, nil, -1
    slot.libreDesde = GetGameTimer()
    if rt then SoltarRT(rt) end
end

local function DestruirSlot(slot)
    if slot.dui then DestroyDui(slot.dui) end
    slot.dui, slot.txd = nil, nil
end

-- ── Volumen ─────────────────────────────────────────────────────────
local function Volumen(r, st, ped, pos)
    if st.pausa or silencioStreamer then return 0 end
    local base = math.max(0, math.min(100, tonumber(st.volumen) or 0))
    if base == 0 then return 0 end

    if r.zona then return DentroZona(pos, r.zona) and base or 0 end

    local centro = Centro(r)
    if not centro then return 0 end

    if r.mirarInterior then
        local intTele
        if r.entidad and DoesEntityExist(r.entidad) then
            intTele = GetInteriorFromEntity(r.entidad)
        else
            intTele = GetInteriorAtCoords(centro.x, centro.y, centro.z)
        end
        if GetInteriorFromEntity(ped) ~= intTele then return 0 end
    end

    local s = r.esquinas and Config.SonidoPared or Config.Sonido
    local d = #(pos - centro)
    if d <= s.pleno then return base end
    if d >= s.maximo then return 0 end
    local f = 1.0 - (d - s.pleno) / (s.maximo - s.pleno)
    return math.floor(base * f * f + 0.5)
end

-- ── Elegir qué se pinta ─────────────────────────────────────────────
local function Elegir(ped, pos)
    local candidatas = {}
    for id, r in pairs(teles) do
        if not r.oculta then
            ResolverEntidad(r, pos)
            local centro = Centro(r)
            -- Un prop del mapa solo se pinta si de verdad está ahí.
            local existe = r.esquinas or (r.entidad and DoesEntityExist(r.entidad))
            if centro and existe then
                local d = #(pos - centro)
                local maximo = r.esquinas and Config.DistanciaVerPared or Config.DistanciaVer
                -- El estado se lee solo de las que están a tiro: cada lectura de
                -- GlobalState cuesta.
                if d <= maximo and Motor.Estado(id) then
                    candidatas[#candidatas + 1] = { r = r, d = d }
                end
            end
        end
    end
    table.sort(candidatas, function(a, b) return a.d < b.d end)

    local elegidas, orden, rtOcupado = {}, {}, {}
    for _, c in ipairs(candidatas) do
        if #orden >= Config.MaxReproduciendo then break end
        local rt = c.r.rt
        if not rt or not rtOcupado[rt] then
            if rt then rtOcupado[rt] = true end
            elegidas[c.r.id] = true
            orden[#orden + 1] = c.r.id
        end
    end
    return elegidas, orden
end

local function Repartir(ped, pos)
    local elegidas, orden = Elegir(ped, pos)

    for _, slot in ipairs(slots) do
        if slot.tele and not elegidas[slot.tele] then SoltarSlot(slot) end
    end

    local asignadas = {}
    for _, slot in ipairs(slots) do
        if slot.tele then asignadas[slot.tele] = true end
    end

    for _, id in ipairs(orden) do
        if not asignadas[id] then
            local libre
            for i = 1, Config.MaxReproduciendo do
                slots[i] = slots[i] or { vol = -1, latido = 0 }
                if not slots[i].tele then libre = i break end
            end
            if libre then
                local slot = slots[libre]
                local r = teles[id]
                slot.tele, slot.rt, slot.clave, slot.latido, slot.vol = id, r.rt, nil, 0, -1
                if r.rt then EngancharRT(r) end
                if not slot.dui and not slot.creando then
                    CreateThread(function() CrearDui(libre, slot) end)
                end
            end
        end
    end
end

-- Mantiene cada navegador al día: contenido, posición y volumen.
local function Latir(ped, pos)
    local ahora = GetGameTimer()
    for _, slot in ipairs(slots) do
        local r = slot.tele and teles[slot.tele]
        local st = r and Motor.Estado(r.id)
        if r and st and slot.dui then
            local vol = Volumen(r, st, ped, pos)
            local clave = ('%s|%s|%s|%s|%s'):format(st.tipo, st.ref, st.clase, tostring(st.inicio), tostring(st.pausa))
            if clave ~= slot.clave or ahora - (slot.latido or 0) > 5000 then
                if Enviar(slot, {
                    accion = 'cargar',
                    tipo = st.tipo, ref = st.ref, clase = st.clase,
                    segundo = Motor.Posicion(st),
                    pausado = st.pausa ~= nil,
                    volumen = vol,
                }) then
                    slot.clave, slot.latido, slot.vol = clave, ahora, vol
                end
            elseif math.abs(vol - (slot.vol or -1)) >= 1 then
                if Enviar(slot, { accion = 'volumen', v = vol }) then slot.vol = vol end
            end
        elseif not slot.tele and slot.dui and slot.libreDesde and ahora - slot.libreDesde > 30000 then
            DestruirSlot(slot)
        end
    end
end

-- Un cambio de estado se manda en el siguiente latido, sin esperar 5 s.
AddStateBagChangeHandler(nil, 'global', function(_, clave, valor)
    if type(clave) ~= 'string' or clave:sub(1, 5) ~= 'tele:' then return end
    local id = clave:sub(6)
    if valor then pendientesDespertar[id] = nil end
    for _, slot in ipairs(slots) do
        if slot.tele == id then slot.latido = 0 end
    end
    if Motor.AlCambiar then Motor.AlCambiar(id, valor) end
end)

-- ── Hilos ───────────────────────────────────────────────────────────
CreateThread(function()
    SincronizarReloj()
    local vuelta = 0
    while true do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        if vuelta % 2 == 0 then Repartir(ped, pos) end
        Latir(ped, pos)
        vuelta = vuelta + 1
        if vuelta % 240 == 0 then CreateThread(SincronizarReloj) end -- cada minuto
        Wait(250)
    end
end)

-- Las teles de las casas guardan su contenido en el mueble: al volver a
-- verlas tras un reinicio, se le pide al servidor que las encienda.
CreateThread(function()
    while true do
        Wait(Config.Ritmo.despertar + 100)
        local ids = {}
        for id in pairs(pendientesDespertar) do
            if teles[id] and not Motor.Estado(id) then ids[#ids + 1] = id end
            pendientesDespertar[id] = nil
            if #ids >= 10 then break end
        end
        if #ids > 0 then TriggerServerEvent('origen_screens:server:despertar', ids) end
    end
end)

CreateThread(function()
    while true do
        local pinta = false
        for _, slot in ipairs(slots) do
            local r = slot.tele and teles[slot.tele]
            if r and slot.txd then
                pinta = true
                if r.rt then
                    local u = rts[r.rt]
                    if u and (not u.id or u.id == 0) and GetGameTimer() > (u.reintento or 0) then
                        -- Recién enlazado puede devolver 0 hasta que el modelo carga.
                        u.reintento = GetGameTimer() + 1000
                        if not IsNamedRendertargetLinked(r.modelo) then LinkNamedRendertarget(r.modelo) end
                        u.id = GetNamedRendertargetRenderId(r.rt)
                    end
                    if u and u.id and u.id ~= 0 then
                        SetTextRenderId(u.id)
                        SetScriptGfxDrawOrder(4)
                        SetScriptGfxDrawBehindPausemenu(true)
                        DrawSprite(slot.txd, 'video', 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
                        SetTextRenderId(GetDefaultScriptRendertargetRenderId())
                    end
                elseif r.esquinas then
                    local e, t, n = r.esquinas, slot.txd, 'video'
                    -- Las dos caras, para que se vea por delante y por detrás.
                    DrawTexturedPoly(e.c1.x, e.c1.y, e.c1.z, e.c2.x, e.c2.y, e.c2.z, e.c4.x, e.c4.y, e.c4.z, 255, 255, 255, 255, t, n, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
                    DrawTexturedPoly(e.c1.x, e.c1.y, e.c1.z, e.c4.x, e.c4.y, e.c4.z, e.c3.x, e.c3.y, e.c3.z, 255, 255, 255, 255, t, n, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0)
                    DrawTexturedPoly(e.c4.x, e.c4.y, e.c4.z, e.c2.x, e.c2.y, e.c2.z, e.c1.x, e.c1.y, e.c1.z, 255, 255, 255, 255, t, n, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                    DrawTexturedPoly(e.c3.x, e.c3.y, e.c3.z, e.c4.x, e.c4.y, e.c4.z, e.c1.x, e.c1.y, e.c1.z, 255, 255, 255, 255, t, n, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0)
                end
            end
        end
        Wait(pinta and 0 or 400)
    end
end)

-- ── Diagnóstico: /tele_rt <nombre> ──────────────────────────────────
-- Pinta de rosa el render target <nombre> enlazado al modelo del prop al que
-- apuntas, 8 s. Si la pantalla se vuelve rosa, ese es el nombre bueno para
-- Config.Modelos. Solo en local: no toca a nadie más.
RegisterCommand('tele_rt', function(_, args)
    local nombre = args[1]
    if not nombre or not nombre:match('^[%w_]+$') then
        print('^3[origen_screens]^7 Uso: /tele_rt <render target>  (apuntando a la tele)')
        return
    end
    local cam = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(0)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local dir = vector3(-math.sin(rz) * math.abs(math.cos(rx)), math.cos(rz) * math.abs(math.cos(rx)), math.sin(rx))
    local destino = cam + dir * 20.0
    local rayo = StartShapeTestLosProbe(cam.x, cam.y, cam.z, destino.x, destino.y, destino.z, 16, PlayerPedId(), 0)
    local estado, _, _, _, entidad = GetShapeTestResult(rayo)
    local limite = GetGameTimer() + 1000
    while estado == 1 and GetGameTimer() < limite do
        Wait(0)
        estado, _, _, _, entidad = GetShapeTestResult(rayo)
    end
    if not entidad or entidad == 0 or GetEntityType(entidad) ~= 3 then
        print('^3[origen_screens]^7 No estás apuntando a ningún objeto')
        return
    end
    local modelo = GetEntityModel(entidad)
    local propio = not IsNamedRendertargetRegistered(nombre)
    if propio then RegisterNamedRendertarget(nombre, false) end
    if not IsNamedRendertargetLinked(modelo) then LinkNamedRendertarget(modelo) end
    local id = GetNamedRendertargetRenderId(nombre)
    print(('^2[origen_screens]^7 Modelo %d · render target %s · id %d · pintando 8 s'):format(modelo, nombre, id))
    CreateThread(function()
        local fin = GetGameTimer() + 8000
        while GetGameTimer() < fin do
            SetTextRenderId(id)
            SetScriptGfxDrawOrder(4)
            DrawRect(0.5, 0.5, 1.0, 1.0, 216, 27, 85, 255)
            SetTextRenderId(GetDefaultScriptRendertargetRenderId())
            Wait(0)
        end
        if propio then ReleaseNamedRendertarget(nombre) end
    end)
end, false)

-- ── Exports ─────────────────────────────────────────────────────────
exports('RegistrarTele', Motor.Registrar)
exports('QuitarTele', Motor.Quitar)
exports('EsModeloTele', function(modelo)
    if type(modelo) == 'string' then modelo = GetHashKey(modelo) end
    return Config.ModelosPorHash[modelo] ~= nil
end)
exports('EstadoTele', function(id)
    local st = Motor.Estado(id)
    if not st then return nil end
    return { tipo = st.tipo, ref = st.ref, clase = st.clase, pausado = st.pausa ~= nil, volumen = st.volumen }
end)

-- Quien registró teles antes de un reinicio de este recurso las pierde:
-- se avisa para que las vuelva a dar de alta (origen_housing lo escucha).
CreateThread(function()
    Wait(500)
    TriggerEvent('origen_screens:motorListo')
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for _, slot in ipairs(slots) do DestruirSlot(slot) end
    for rt, u in pairs(rts) do
        if u.propio and IsNamedRendertargetRegistered(rt) then ReleaseNamedRendertarget(rt) end
    end
end)
