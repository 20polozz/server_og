--[[ ── El motor de las máquinas del aserradero ────────────────────────────────

     Crea la línea (parque de troncos, grúa, descortezadora, sierra, apiladora,
     secadero y carretilla; shared/maquina.lua, generado con los modelos de
     fuente/) y mueve sus piezas: el mismo motor que la planta de la mina y la
     prensa del basurero, copiado aquí para que el aserradero no dependa de
     ningún otro recurso. Se usa con `PL:Crear(tipo, coords, rumbo)`,
     `PL:Mover`, `PL:Mostrar`, `PL:Cambiar`, `PL:Efecto`, `PL:Luz`, `PL:Marcha`,
     `PL:Punto`, `PL:Entidad`, `PL:Notas` y `PL:Borrar`. ]]

local creadas = {}
local siguiente = 0
local CERCA = 150.0

-- Partículas de cada efecto (asset, nombre, escala). Elegidas con fotos en el
-- juego (27/09); los nombres salen de la lista real de core.ypt.
local PARTICULAS = {
    astillas = { 'core', 'ent_amb_stoner_dust_drop', 0.6 },
    corteza = { 'core', 'ent_amb_stoner_dust_drop', 0.8 },
    serrin = { 'core', 'ent_amb_foundry_dust', 0.5 },
    vapor1 = { 'core', 'ent_amb_steam_vent_open_hvy', 0.4 },
    vapor2 = { 'core', 'ent_amb_steam_vent_open_hvy', 0.4 },
}

-- De noche (20:00–7:00): focos, ventanas y mástiles.
local noche = false
local function EsDeNoche()
    local h = GetClockHours()
    return h >= 20 or h < 7
end

local function cargar(modelo)
    local h = type(modelo) == 'number' and modelo or joaat(modelo)
    if not IsModelInCdimage(h) then
        print(('^1[origen_lumber] el modelo %s no existe^7'):format(tostring(modelo)))
        return nil
    end
    RequestModel(h)
    local limite = GetGameTimer() + 10000
    while not HasModelLoaded(h) do
        if GetGameTimer() > limite then return nil end
        Wait(0)
    end
    return h
end

local function objeto(modelo, en)
    local h = cargar(modelo)
    if not h then return nil end
    local e = CreateObjectNoOffset(h, en.x, en.y, en.z, false, false, false)
    FreezeEntityPosition(e, true)
    SetModelAsNoLongerNeeded(h)
    return e
end

-- ── Marcos (r, f, u, o) en coordenadas del cuerpo ───────────────────────
local function rotar(v, a, grados)
    local t = math.rad(grados)
    local c, s = math.cos(t), math.sin(t)
    local cruz = vec3(a.y * v.z - a.z * v.y, a.z * v.x - a.x * v.z, a.x * v.y - a.y * v.x)
    local punto = a.x * v.x + a.y * v.y + a.z * v.z
    return v * c + cruz * s + a * (punto * (1 - c))
end

local function en_marco(M, v) return M.r * v.x + M.f * v.y + M.u * v.z end
local function punto_en(M, p) return M.o + en_marco(M, p) end

local function componer(P, C)
    return { r = en_marco(P, C.r), f = en_marco(P, C.f), u = en_marco(P, C.u), o = punto_en(P, C.o) }
end

local IDENTIDAD = { r = vec3(1, 0, 0), f = vec3(0, 1, 0), u = vec3(0, 0, 1), o = vec3(0, 0, 0) }

local function marco(m, nombre, cache)
    if cache[nombre] then return cache[nombre] end
    local p = m.piezas[nombre]
    local d = p.def
    local M
    if d.ancla then
        local A = marco(m, d.ancla.pieza, cache)
        M = { r = IDENTIDAD.r, f = IDENTIDAD.f, u = IDENTIDAD.u, o = punto_en(A, d.ancla.punto) }
    else
        local b = math.rad(d.rumbo or 0.0)
        local r0, f0, u0 = vec3(math.cos(b), math.sin(b), 0.0), vec3(-math.sin(b), math.cos(b), 0.0), IDENTIDAD.u
        local o = d.pos or vec3(0, 0, 0)
        if d.tipo == 'desliza' then
            o = o + d.eje * p.valor
        elseif (d.tipo == 'angulo' or d.tipo == 'giro') and p.valor ~= 0.0 then
            r0, f0, u0 = rotar(r0, d.eje, p.valor), rotar(f0, d.eje, p.valor), rotar(u0, d.eje, p.valor)
        end
        M = { r = r0, f = f0, u = u0, o = o }
        if d.padre then M = componer(marco(m, d.padre, cache), M) end
    end
    cache[nombre] = M
    return M
end

local function mundo(m)
    local f, r, u, o = GetEntityMatrix(m.cuerpo)
    return { r = r, f = f, u = u, o = o }
end

local function colocar_todo(m)
    local W = mundo(m)
    local cache = {}
    for nombre, p in pairs(m.piezas) do
        if p.ent then
            local L = componer(W, marco(m, nombre, cache))
            SetEntityMatrix(p.ent, L.f.x, L.f.y, L.f.z, L.r.x, L.r.y, L.r.z, L.u.x, L.u.y, L.u.z, L.o.x, L.o.y, L.o.z)
            -- SetEntityMatrix mueve el dibujo pero deja la colisión atrás:
            -- volver a fijar las coordenadas la lleva con él (probado en el juego).
            SetEntityCoordsNoOffset(p.ent, L.o.x, L.o.y, L.o.z, false, false, false)
        end
    end
end

local function poner_modelo(m, p, modelo)
    if p.modelo == modelo and p.ent then return end
    local e = objeto(modelo, GetEntityCoords(m.cuerpo))
    if not e then return end
    if p.ent and DoesEntityExist(p.ent) then DeleteEntity(p.ent) end
    p.ent, p.modelo = e, modelo
    SetEntityVisible(e, p.visible, false)
    SetEntityCollision(e, p.visible, p.visible)
    m.sucio = true
end

-- ── API ─────────────────────────────────────────────────────────────────
local function Crear(tipo, coords, rumbo)
    local def = Maquinas[tipo]
    if not def then
        print(('^1[origen_lumber] no hay máquina «%s»^7'):format(tostring(tipo)))
        return nil
    end
    local cuerpo = objeto(def.cuerpo, coords)
    if not cuerpo then return nil end
    SetEntityHeading(cuerpo, rumbo or 0.0)
    siguiente = siguiente + 1
    local m = { id = siguiente, tipo = tipo, def = def, cuerpo = cuerpo, piezas = {}, marcha = false,
                efectos = {}, luces = {}, echados = {}, sucio = true }
    for nombre, d in pairs(def.piezas or {}) do
        local p = { def = d, valor = d.inicio or 0.0, visible = not d.oculta }
        m.piezas[nombre] = p
        poner_modelo(m, p, d.modelo)
    end
    creadas[siguiente] = m
    for _, p in pairs(m.piezas) do
        local n = p.def.noche
        if n and noche then
            if n.variante then poner_modelo(m, p, p.def.variantes[n.variante]) end
            if n.valor then p.valor = n.valor end
        end
    end
    for nombre, l in pairs(def.luces or {}) do
        if l.noche and noche then m.luces[nombre] = true end
    end
    colocar_todo(m)
    return siguiente
end

-- Día ↔ noche: lo que cambia solo.
local function PonerNoche(m, si)
    for nombre, p in pairs(m.piezas) do
        local n = p.def.noche
        if n then
            if n.variante then
                poner_modelo(m, p, si and p.def.variantes[n.variante] or p.def.modelo)
            end
            if n.valor then
                p.desde, p.hasta = p.valor, si and n.valor or (p.def.inicio or 0.0)
                p.t0, p.dura = GetGameTimer(), (n.segundos or 0) * 1000
            end
        end
    end
    for nombre, l in pairs(m.def.luces or {}) do
        if l.noche then m.luces[nombre] = si or nil end
    end
    m.sucio = true
end

local function Efecto(id, nombre, si)
    local m = creadas[id]
    local e = m and m.def.efectos and m.def.efectos[nombre]
    if not e then return false end
    local actual = m.efectos[nombre]
    if actual then StopParticleFxLooped(actual, false) m.efectos[nombre] = nil end
    if not si then return true end
    local pt = PARTICULAS[nombre]
    if not pt then return false end
    RequestNamedPtfxAsset(pt[1])
    local limite = GetGameTimer() + 5000
    while not HasNamedPtfxAssetLoaded(pt[1]) and GetGameTimer() < limite do Wait(0) end
    local ent = e.pieza and m.piezas[e.pieza] and m.piezas[e.pieza].ent or m.cuerpo
    UseParticleFxAssetNextCall(pt[1])
    m.efectos[nombre] = StartParticleFxLoopedOnEntity(pt[2], ent, e.punto.x, e.punto.y, e.punto.z,
        0.0, 0.0, 0.0, pt[3] or 1.0, false, false, false)
    return true
end

local function Borrar(id)
    local m = creadas[id]
    if not m then return end
    for nombre in pairs(m.efectos) do Efecto(id, nombre, false) end
    for _, o in pairs(m.echados) do
        if DoesEntityExist(o.ent) then DeleteEntity(o.ent) end
    end
    for _, p in pairs(m.piezas) do
        if p.ent and DoesEntityExist(p.ent) then DeleteEntity(p.ent) end
    end
    if DoesEntityExist(m.cuerpo) then DeleteEntity(m.cuerpo) end
    creadas[id] = nil
end

local function Marcha(id, si)
    local m = creadas[id]
    if not m then return false end
    m.marcha = si and true or false
    for _, p in pairs(m.piezas) do
        if p.def.marcha then poner_modelo(m, p, m.marcha and p.def.marcha or p.def.modelo) end
    end
    for nombre, e in pairs(m.def.efectos or {}) do
        if e.marcha then Efecto(id, nombre, m.marcha) end
    end
    for nombre, l in pairs(m.def.luces or {}) do
        if l.marcha then m.luces[nombre] = m.marcha or nil end
    end
    if not m.marcha then
        for _, p in pairs(m.piezas) do
            if p.def.vaiven then
                p.desde, p.hasta = p.valor, (p.def.vaiven.centro or 0.0) + 0.0
                p.t0, p.dura = GetGameTimer(), 400
            end
        end
    end
    m.sucio = true
    return true
end

local function Mover(id, pieza, valor, segundos)
    local m = creadas[id]
    local p = m and m.piezas[pieza]
    if not p then return false end
    p.desde, p.hasta = p.valor, valor + 0.0
    p.t0, p.dura = GetGameTimer(), math.max(0, (segundos or 0) * 1000)
    return true
end

local function Cambiar(id, pieza, variante)
    local m = creadas[id]
    local p = m and m.piezas[pieza]
    if not p then return false end
    local modelo = p.def.variantes and p.def.variantes[variante] or variante
    poner_modelo(m, p, modelo)
    return true
end

local function Mostrar(id, pieza, si)
    local m = creadas[id]
    local p = m and m.piezas[pieza]
    if not p then return false end
    p.visible = si and true or false
    SetEntityVisible(p.ent, p.visible, false)
    SetEntityCollision(p.ent, p.visible, p.visible)
    m.sucio = true
    return true
end

local function Luz(id, nombre, si)
    local m = creadas[id]
    if not m or not (m.def.luces and m.def.luces[nombre]) then return false end
    m.luces[nombre] = si and true or nil
    return true
end

local function Punto(id, nombre)
    local m = creadas[id]
    local p = m and m.def.puntos and m.def.puntos[nombre]
    if not p then return nil end
    return GetOffsetFromEntityInWorldCoords(m.cuerpo, p.x, p.y, p.z)
end

local function Entidad(id, pieza)
    local m = creadas[id]
    if not m then return nil end
    if pieza then return m.piezas[pieza] and m.piezas[pieza].ent end
    return m.cuerpo
end

-- Echa un objeto a la cinta. `desde` es la y de la cinta (en metros desde
-- la cola) por donde entra; sin él, entra por la cola.
local function Echar(id, modelo, desde)
    local m = creadas[id]
    if not m or not m.def.recorrido then return nil end
    local ruta = m.def.recorrido
    local i = 1
    if desde then
        while ruta[i + 1] and ruta[i + 1].y < desde do i = i + 1 end
    end
    local inicio = GetOffsetFromEntityInWorldCoords(m.cuerpo, ruta[i].x, ruta[i].y, ruta[i].z)
    local e = objeto(modelo, inicio)
    if not e then return nil end
    SetEntityCollision(e, false, false)
    SetEntityHeading(e, math.random(0, 359) + 0.0)
    m.echados[e] = { ent = e, modelo = modelo, tramo = i, t = 0.0, giro = math.random(-40, 40) + 0.0 }
    return e
end

--[[ Altura a la que asentar una máquina en `en` (x, y) con ese rumbo. Con
     `huella` (x0, x1, y0, y1 en su marco) mide el suelo en las cuatro esquinas
     y el centro y se queda con el más bajo: en cuesta se hunde un poco por el
     lado alto en vez de flotar por el bajo. Si entre esquinas hay más de 2 m
     (un talud), el centro. Sin contar objetos (casetas, bidones, las propias
     máquinas). ]]
local function Suelo(tipo, en, rumbo)
    local function z_en(x, y)
        local hay, z = GetGroundZExcludingObjectsFor_3dCoord(x, y, en.z + 5.0, false, false)
        return hay and z or nil
    end
    local centro = z_en(en.x, en.y)
    local h = Maquinas[tipo] and Maquinas[tipo].huella
    if not h then return centro or en.z end
    local c, s = math.cos(math.rad(rumbo or 0.0)), math.sin(math.rad(rumbo or 0.0))
    local bajo, alto = centro, centro
    for _, e in ipairs({ { h[1], h[3] }, { h[2], h[3] }, { h[2], h[4] }, { h[1], h[4] } }) do
        local z = z_en(en.x + e[1] * c - e[2] * s, en.y + e[1] * s + e[2] * c)
        if z then
            bajo = bajo and math.min(bajo, z) or z
            alto = alto and math.max(alto, z) or z
        end
    end
    if not bajo then return en.z end
    if alto - bajo > 2.0 then return centro or bajo end
    return bajo
end

local luzSi = nil
local FUNCIONES = {
    Crear = Crear, Borrar = Borrar, Marcha = Marcha, Mover = Mover, Cambiar = Cambiar, Mostrar = Mostrar,
    Efecto = Efecto, Luz = Luz, Punto = Punto, Entidad = Entidad,
    Notas = function(tipo) return Maquinas[tipo] and Maquinas[tipo].notas end,
    -- Mover la máquina entera (la carretilla): el cuerpo y, en el siguiente
    -- fotograma, sus piezas.
    Colocar = function(id, pos, rumbo)
        local m = creadas[id]
        if not m then return end
        SetEntityCoordsNoOffset(m.cuerpo, pos.x, pos.y, pos.z, false, false, false)
        SetEntityHeading(m.cuerpo, rumbo + 0.0)
        m.sucio = true
    end,
    -- Quién decide si se encienden las luces (se dibujan en cada fotograma).
    SoloLucesSi = function(f) luzSi = f end,
}
-- Se llama con dos puntos, como el export de antes: PL:Mover(id, ...).
PL = setmetatable({}, { __index = function(_, k)
    local f = FUNCIONES[k]
    return f and function(_, ...) return f(...) end or nil
end })

-- ── Bucle: piezas, material en las cintas y luces ───────────────────────
local function avanzar_echados(m, dt)
    local ruta = m.def.recorrido
    local v = m.marcha and (m.def.velocidad or 0.5) or 0.0
    for e, o in pairs(m.echados) do
        if not DoesEntityExist(e) then
            m.echados[e] = nil
        else
            local a, b = ruta[o.tramo], ruta[o.tramo + 1]
            if not b then
                DeleteEntity(e)
                m.echados[e] = nil
                TriggerEvent('origen_lumber:llega', m.id, o.modelo)
            else
                local largo = #(b - a)
                -- Al caer de la cabeza va más deprisa (la gravedad).
                local vel = (b.z < a.z - 0.1) and 2.5 or v
                o.t = o.t + (largo > 0 and vel * dt / largo or 1.0)
                if o.t >= 1.0 then
                    o.tramo, o.t = o.tramo + 1, 0.0
                else
                    local p = a + (b - a) * o.t
                    local w = GetOffsetFromEntityInWorldCoords(m.cuerpo, p.x, p.y, p.z)
                    SetEntityCoordsNoOffset(e, w.x, w.y, w.z, false, false, false)
                    if vel > v then
                        SetEntityHeading(e, GetEntityHeading(e) + o.giro * dt * 4)
                    end
                end
            end
        end
    end
end

local temblando, revisarNoche = 0.0, 0
CreateThread(function()
    noche = EsDeNoche()
    local antes = GetGameTimer()
    while true do
        local ahora = GetGameTimer()
        local dt = math.min(0.1, (ahora - antes) / 1000.0)
        antes = ahora
        local yo = GetEntityCoords(PlayerPedId())
        local trabajo = false
        local tiembla = 0.0
        for _, m in pairs(creadas) do
            if #(GetEntityCoords(m.cuerpo) - yo) < CERCA then
                local cambia = m.sucio
                m.sucio = false
                for _, p in pairs(m.piezas) do
                    local d = p.def
                    if d.tipo == 'giro' and m.marcha then
                        p.valor = (p.valor + d.giro * dt) % 360.0
                        cambia = true
                    elseif d.vaiven and m.marcha and not p.hasta then
                        local v = d.vaiven
                        p.valor = (v.centro or 0.0) + v.amp * math.sin(ahora / 1000.0 * v.hz * 2 * math.pi)
                        cambia = true
                    elseif p.hasta then
                        local t = p.dura > 0 and math.min(1.0, (ahora - p.t0) / p.dura) or 1.0
                        t = t * t * (3 - 2 * t)   -- arranca y frena suave
                        p.valor = p.desde + (p.hasta - p.desde) * t
                        if t >= 1.0 then p.hasta = nil end
                        cambia = true
                    end
                end
                if cambia then colocar_todo(m) end
                if next(m.echados) then avanzar_echados(m, dt) end
                local conLuz = next(m.luces) ~= nil and (not luzSi or luzSi(m))
                if conLuz then
                    local W = mundo(m)
                    local cache = {}
                    for nombre in pairs(m.luces) do
                        local l = m.def.luces[nombre]
                        local M = l.pieza and componer(W, marco(m, l.pieza, cache)) or W
                        local q = punto_en(M, l.punto)
                        -- El color va en enteros: un 255.0 lo lee el juego como un
                        -- entero enorme y la luz ciega toda la pantalla (27/09).
                        local r, g, b = math.floor(l.color[1]), math.floor(l.color[2]), math.floor(l.color[3])
                        if l.dir then
                            local d = en_marco(M, l.dir)
                            DrawSpotLight(q.x, q.y, q.z, d.x, d.y, d.z, r, g, b, l.rango + 0.0, l.fuerza + 0.0,
                                0.0, (l.radio or 45.0) + 0.0, 1.0)
                        else
                            local parpadeo = (l.noche or l.marcha) and 1.0
                                or 0.85 + 0.15 * math.sin(ahora / 70.0) * math.sin(ahora / 113.0)
                            DrawLightWithRange(q.x, q.y, q.z, r, g, b, l.rango + 0.0, l.fuerza * parpadeo)
                        end
                    end
                end
                if m.def.temblor and m.marcha and #(GetEntityCoords(m.cuerpo) - yo) < m.def.temblor.radio then
                    tiembla = math.max(tiembla, m.def.temblor.fuerza)
                end
                trabajo = trabajo or cambia or next(m.echados) ~= nil or conLuz
            end
        end
        -- Vibración de cámara junto a lo que anda (la trituradora, el generador).
        if tiembla ~= temblando then
            if tiembla > 0 then
                ShakeGameplayCam('ROAD_VIBRATION_SHAKE', tiembla)
            else
                StopGameplayCamShaking(false)
            end
            temblando = tiembla
        end
        if ahora > revisarNoche then
            revisarNoche = ahora + 2000
            local ahoraNoche = EsDeNoche()
            if ahoraNoche ~= noche then
                noche = ahoraNoche
                for _, m in pairs(creadas) do PonerNoche(m, noche) end
            end
        end
        Wait(trabajo and 0 or 250)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(creadas) do Borrar(id) end
    if temblando > 0 then StopGameplayCamShaking(true) end
end)
