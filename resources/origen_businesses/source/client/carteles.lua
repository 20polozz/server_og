--[[
    CARTELES DEL LOCAL Y VALLAS PUBLICITARIAS — cliente

    · PINTAR: el servidor reparte una lista ligera de rectángulos (esquinas y
      versión). Los más cercanos de cada clase se pintan con un navegador
      (DUI) que abre ui/build/lienzo.html, y su textura se pega en la pared
      con DrawTexturedPoly, como las pantallas de pared de origen_screens.
      Solo por delante: por detrás de una valla no se ve el anuncio al revés.

    · MARCAR: la interfaz pide `lienzos:marcar` y se aparta; aquí se marcan
      dos esquinas en la pared con [E] y se le devuelven. Lo que valga o no lo
      decide el servidor al guardar.

    Ver config/carteles.lua y source/server/carteles.lua.
]]

local C, V = Config.Carteles, Config.Vallas
local RECURSO = GetCurrentResourceName()
local PAGINA = ('https://cfx-nui-%s/ui/build/lienzo.html'):format(RECURSO)

local lienzos = {}    -- clave 'c:1' / 'v:3' -> { k, id, v, c1..c4 (vector3), centro, normal }
local datos = {}      -- versión -> lo que devuelve el servidor para pintar
local pidiendo = {}   -- versión -> true mientras se pide

--[[ Dos juegos de navegadores: los carteles son de interior y casi
     cuadrados; las vallas, alargadas y de lejos. ]]
local juegos = {
    c = { ancho = 1024, alto = 1024, max = C.MaxPintando, distancia = C.DistanciaVer, slots = {} },
    v = { ancho = 2048, alto = 1024, max = V.MaxPintando, distancia = V.DistanciaVer, slots = {} },
}
local serie = 0

--[[ La vista previa en curso (ver `Previa` más abajo): un rectángulo cuyo
     sitio y contenido son los de la copia que se está mirando o ajustando,
     no los que ha repartido el servidor. ]]
local previa = nil   -- { clave, l, v, datos }

local function LienzoDe(clave)
    if previa and previa.clave == clave then return previa.l end
    return lienzos[clave]
end

local function Vec(t) return vector3(t.x + 0.0, t.y + 0.0, t.z + 0.0) end

local function Cruz(a, b)
    return vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

-- ── La lista ─────────────────────────────────────────────────────────────

local function Cargar(lista)
    local nuevos = {}
    for _, l in ipairs(type(lista) == 'table' and lista or {}) do
        if type(l) == 'table' and type(l.c) == 'table' and l.c.c1 and l.c.c4 then
            local c1, c2, c3, c4 = Vec(l.c.c1), Vec(l.c.c2), Vec(l.c.c3), Vec(l.c.c4)
            local n = Cruz(c2 - c1, c3 - c1)
            local ln = #n
            nuevos[l.k .. ':' .. l.id] = {
                k = l.k, id = l.id, v = l.v,
                c1 = c1, c2 = c2, c3 = c3, c4 = c4,
                centro = (c1 + c4) * 0.5,
                normal = ln > 0 and n / ln or vector3(0, 0, 1),
            }
        end
    end
    lienzos = nuevos
end

RegisterNetEvent('origen_businesses:client:lienzos', function(lista)
    Cargar(lista)
end)

CreateThread(function()
    Wait(2000)
    local ok, lista = pcall(function()
        return lib.callback.await('origen_businesses:cb:lienzos:lista', false)
    end)
    if ok and lista then Cargar(lista) end
end)

-- ── Navegadores ──────────────────────────────────────────────────────────

local function Mandar(slot, d)
    if not slot.dui or not d then return end
    SendDuiMessage(slot.dui, json.encode({
        lienzo = 1, accion = 'pintar',
        contenido = d.contenido, negocio = d.negocio, logo = d.logo,
        ancho = d.ancho, alto = d.alto,
    }))
end

local function CrearDui(juego, slot)
    slot.creando = true
    local dui = CreateDui(PAGINA, juego.ancho, juego.alto)
    local limite = GetGameTimer() + 5000
    while not IsDuiAvailable(dui) and GetGameTimer() < limite do Wait(20) end
    -- Un runtime txd no se puede borrar: cada navegador nuevo, nombre nuevo.
    serie = serie + 1
    local nombre = ('origen_lienzo_%d'):format(serie)
    local txd = CreateRuntimeTxd(nombre)
    CreateRuntimeTextureFromDuiHandle(txd, 'lienzo', GetDuiHandle(dui))
    slot.dui, slot.txd, slot.nace = dui, nombre, GetGameTimer()
    slot.enviada, slot.visible = nil, false
    slot.creando = false
end

local function Destruir(slot)
    if slot.dui then DestroyDui(slot.dui) end
    slot.dui, slot.txd, slot.clave, slot.enviada = nil, nil, nil, nil
end

--- Lo que hay que pintar en un rectángulo: de la memoria o del servidor.
local function Datos(l)
    if previa and previa.l == l then return previa.datos end
    local d = datos[l.v]
    if d then return d end
    if pidiendo[l.v] then return nil end
    pidiendo[l.v] = true
    CreateThread(function()
        local ok, res = pcall(function()
            return lib.callback.await('origen_businesses:cb:lienzos:contenido', false, l.k, l.id)
        end)
        if ok and type(res) == 'table' then datos[l.v] = res end
        -- Si falla, se vuelve a intentar a los 5 s.
        if not datos[l.v] then Wait(5000) end
        pidiendo[l.v] = nil
    end)
    return nil
end

--[[ Reparto: a cada juego, sus N rectángulos más cercanos que se vean de
     frente. El navegador que se queda sin rectángulo se guarda un rato por si
     vuelve a hacer falta y luego se cierra. ]]
local function Repartir(pos)
    local ahora = GetGameTimer()
    for k, juego in pairs(juegos) do
        local cerca = {}
        for clave, l in pairs(lienzos) do
            if l.k == k then
                local d = #(pos - l.centro)
                if d <= juego.distancia and #(pos - l.centro) > 0 then
                    local delante = (pos - l.c1).x * l.normal.x + (pos - l.c1).y * l.normal.y + (pos - l.c1).z * l.normal.z
                    if delante > -0.5 then cerca[#cerca + 1] = { clave = clave, d = d } end
                end
            end
        end
        table.sort(cerca, function(a, b) return a.d < b.d end)

        -- Lo que se está previsualizando va siempre, esté donde esté.
        local elegidos, n = {}, 0
        if previa and previa.l.k == k then elegidos[previa.clave], n = true, 1 end
        for i = 1, #cerca do
            if n >= juego.max then break end
            if not elegidos[cerca[i].clave] then elegidos[cerca[i].clave], n = true, n + 1 end
        end

        -- Fuera los que ya no tocan.
        for _, slot in ipairs(juego.slots) do
            if slot.clave and not elegidos[slot.clave] then
                slot.clave, slot.enviada, slot.visible = nil, nil, false
                slot.libreDesde = ahora
            end
        end

        -- Los que faltan, a un navegador libre.
        local puestos = {}
        for _, slot in ipairs(juego.slots) do if slot.clave then puestos[slot.clave] = true end end
        for clave in pairs(elegidos) do
            if not puestos[clave] then
                local libre
                for i = 1, juego.max do
                    juego.slots[i] = juego.slots[i] or {}
                    if not juego.slots[i].clave then libre = juego.slots[i] break end
                end
                if libre then
                    libre.clave, libre.enviada, libre.visible = clave, nil, false
                    if not libre.dui and not libre.creando then
                        CreateThread(function() CrearDui(juego, libre) end)
                    end
                end
            end
        end

        -- Cada navegador con lo suyo. Se manda dos veces (al nacer la página
        -- puede no estar escuchando todavía) y se pinta cuando ya ha tenido
        -- tiempo de dibujar, para no enseñar un fotograma en blanco.
        for _, slot in ipairs(juego.slots) do
            local l = slot.clave and LienzoDe(slot.clave)
            if l and slot.dui and ahora - (slot.nace or 0) > 600 then
                local d = Datos(l)
                if d then
                    if slot.enviada ~= l.v then
                        Mandar(slot, d)
                        slot.enviada, slot.enviadaEn, slot.repetida = l.v, ahora, false
                    elseif not slot.repetida and ahora - slot.enviadaEn > 2500 then
                        Mandar(slot, d)
                        slot.repetida = true
                    end
                    if ahora - slot.enviadaEn > 350 then slot.visible = true end
                end
            elseif not slot.clave and slot.dui and slot.libreDesde and ahora - slot.libreDesde > 60000 then
                Destruir(slot)
            end
        end
    end
end

CreateThread(function()
    while true do
        -- Durante la vista previa se reparte desde la cámara, no desde el ped.
        local pos = previa and GetFinalRenderedCamCoord() or GetEntityCoords(PlayerPedId())
        if next(lienzos) then pcall(Repartir, pos) end
        Wait(previa and 150 or 500)
    end
end)

--- Las dos caras del rectángulo, solo si la cámara está delante.
local function Pintar(l, txd)
    local cam = GetFinalRenderedCamCoord()
    local r = cam - l.c1
    if r.x * l.normal.x + r.y * l.normal.y + r.z * l.normal.z <= 0.0 then return end
    local a, b, c, d = l.c1, l.c2, l.c3, l.c4
    -- c1 abajo izq. (0,1) · c2 abajo der. (1,1) · c3 arriba izq. (0,0) · c4 arriba der. (1,0)
    DrawTexturedPoly(a.x, a.y, a.z, b.x, b.y, b.z, d.x, d.y, d.z, 255, 255, 255, 255, txd, 'lienzo', 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0)
    DrawTexturedPoly(a.x, a.y, a.z, d.x, d.y, d.z, c.x, c.y, c.z, 255, 255, 255, 255, txd, 'lienzo', 0.0, 1.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    DrawTexturedPoly(a.x, a.y, a.z, d.x, d.y, d.z, b.x, b.y, b.z, 255, 255, 255, 255, txd, 'lienzo', 0.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 0.0)
    DrawTexturedPoly(a.x, a.y, a.z, c.x, c.y, c.z, d.x, d.y, d.z, 255, 255, 255, 255, txd, 'lienzo', 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0)
end

CreateThread(function()
    while true do
        local algo = false
        for _, juego in pairs(juegos) do
            for _, slot in ipairs(juego.slots) do
                local l = slot.visible and slot.clave and LienzoDe(slot.clave)
                if l and slot.txd then
                    algo = true
                    Pintar(l, slot.txd)
                end
            end
        end
        Wait(algo and 0 or 300)
    end
end)

-- ── Marcar las esquinas ──────────────────────────────────────────────────

local marcando = false

--[[ El texto de ayuda de arriba a la izquierda. Cada trozo que se le pasa
     al juego se corta a los 99 bytes, así que va línea a línea (y una línea
     larga, por sus « · »). ]]
local function Ayuda(texto)
    -- La barra de teclas del servidor (origen_hud); la de GTA solo si no esta.
    if GetResourceState('origen_hud') == 'started' then
        return exports.origen_hud:Ayuda(texto)
    end
    BeginTextCommandDisplayHelp('STRING')
    local lineas = {}
    for linea in (texto .. '~n~'):gmatch('(.-)~n~') do lineas[#lineas + 1] = linea end
    for i, linea in ipairs(lineas) do
        local fin = i < #lineas and '~n~' or ''
        if #linea + #fin <= 95 then
            AddTextComponentSubstringPlayerName(linea .. fin)
        else
            local partes = {}
            for parte in (linea .. ' · '):gmatch('(.-) · ') do partes[#partes + 1] = parte end
            for j, parte in ipairs(partes) do
                AddTextComponentSubstringPlayerName(parte .. (j < #partes and ' · ' or fin))
            end
        end
    end
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function Rayo(distancia)
    local cam = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(0)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local cx = math.abs(math.cos(rx))
    local dir = vector3(-math.sin(rz) * cx, math.cos(rz) * cx, math.sin(rx))
    local fin = cam + dir * distancia
    local rayo = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z, fin.x, fin.y, fin.z, 1 + 16, PlayerPedId(), 0)
    local _, golpe, punto, normal = GetShapeTestResult(rayo)
    return golpe == 1 or golpe == true, punto, normal
end

local function Linea(a, b, r, g, bl)
    DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, r, g, bl, 255)
end

--[[ Dos esquinas en una pared. Devuelve { p1, p2, normal } o nil si se
     cancela. `tam` son los topes para pintar en verde o en rojo; el que
     manda es el servidor. ]]
local function Marcar(tam, alcance, que)
    local paso, p1, n1 = 1, nil, nil
    while true do
        Wait(0)
        DisableControlAction(0, 24, true)  -- disparar
        DisableControlAction(0, 25, true)  -- apuntar
        DisableControlAction(0, 140, true) -- golpe

        local golpe, punto, normal = Rayo(alcance)

        if golpe then
            DrawMarker(28, punto.x, punto.y, punto.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.06, 0.06, 0.06, 255, 255, 255, 180, false, false, 2, false, nil, nil, false)
        end

        if paso == 1 then
            Ayuda(('Marca %s~n~~INPUT_PICKUP~ Esquina de ABAJO a la izquierda~n~~INPUT_CELLPHONE_CANCEL~ Cancelar'):format(que))
            if golpe and IsControlJustPressed(0, 38) then
                if math.abs(normal.z) > 0.7 then
                    PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDS', true)
                else
                    p1, n1, paso = punto, normal, 2
                    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDS', true)
                end
            end
        else
            local destino = golpe and punto or p1
            local c1, c2, c3, c4, w, h = C.Esquinas(p1, destino, n1)
            local vale = false
            if c1 then
                vale = w >= tam.minAncho and h >= tam.minAlto and w <= tam.maxAncho and h <= tam.maxAlto
                local r, g, b = 216, 27, 85
                if vale then r, g, b = 220, 221, 224 end
                c1, c2, c3, c4 = Vec(c1), Vec(c2), Vec(c3), Vec(c4)
                Linea(c1, c2, r, g, b) Linea(c2, c4, r, g, b) Linea(c4, c3, r, g, b) Linea(c3, c1, r, g, b)
                Linea(c1, c4, r, g, b)
                Ayuda(('%.2f x %.2f m%s~n~~INPUT_PICKUP~ Esquina de ARRIBA a la derecha~n~~INPUT_CELLPHONE_CANCEL~ Quitar la primera esquina'):format(
                    w, h, vale and '' or ('  (%.1f–%.0f x %.1f–%.0f m)'):format(tam.minAncho, tam.maxAncho, tam.minAlto, tam.maxAlto)))
            end
            if IsControlJustPressed(0, 38) then
                if vale then
                    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDS', true)
                    local function T(p) return { x = p.x, y = p.y, z = p.z } end
                    return { p1 = T(p1), p2 = T(destino), normal = T(n1) }
                end
                PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDS', true)
            end
        end

        -- Retroceso: con una esquina puesta, la quita; sin ninguna, cancela.
        if IsControlJustPressed(0, 177) then
            if paso == 2 then paso, p1, n1 = 1, nil, nil else return nil end
        end
    end
end

--- El nombre de la calle y la zona, para que la lista diga dónde está.
local function Sitio(p)
    local calle = GetStreetNameFromHashKey(GetStreetNameAtCoord(p.x, p.y, p.z))
    local zona = GetLabelText(GetNameOfZone(p.x, p.y, p.z))
    if zona == 'NULL' then zona = '' end
    if calle ~= '' and zona ~= '' then return calle .. ', ' .. zona end
    return calle ~= '' and calle or zona
end

RegisterNUICallback('lienzos:marcar', function(data, cb)
    if marcando then cb(nil) return end
    marcando = true
    SetNuiFocus(false, false)

    --[[ Marcando se cancela con ESC, y sin foco ese ESC le llegaba tambien al
         radial del HUD: se abria, y al volver aqui se cogia el foco otra vez,
         con dos recursos a la vez con el raton. El radial respeta este aviso
         (como en las camaras y la previa); se quita un poco despues para que
         el mismo toque no lo abra al soltar. ]]
    LocalPlayer.state:set('mirandoCamara', true, false)

    local valla = data and data.clase == 'valla'
    local ok, res = pcall(Marcar, valla and V.Tam or C.Tam, valla and 250.0 or 25.0, valla and 'la valla' or 'el cartel')
    if not ok then print(('^1[origen_businesses] marcar: %s^0'):format(tostring(res))) res = nil end
    if res then res.sitio = Sitio(res.p1) end

    SetTimeout(400, function() LocalPlayer.state:set('mirandoCamara', false, false) end)
    marcando = false
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    cb(res)
end)

RegisterNUICallback('lienzos:ruta', function(data, cb)
    local x, y = tonumber(data and data.x), tonumber(data and data.y)
    if x and y then
        SetNewWaypoint(x + 0.0, y + 0.0)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

-- ── Vista previa y ajuste ────────────────────────────────────────────────

--[[ Una cámara delante del cartel o de la valla, pintando lo que manda la
     interfaz (lo que se está escribiendo, aunque no esté guardado).

     Con `ajustar` además se mueve y se cambia de tamaño con el teclado. Al
     confirmar se devuelven las esquinas nuevas y la interfaz se las pasa al
     servidor, que las valida como si se hubieran marcado a mano.

     Teclas:
       ratón           girar alrededor
       rueda           acercar / alejar (ajustando: tamaño)
       Re Pág / Av Pág acercar / alejar
       C               vista aérea / de frente
       flechas         mover (ajustando) · Mayús: más rápido
       Ctrl + flechas  ancho y alto (ajustando)
       Z / X           separar / pegar a la pared (ajustando)
       R               volver a como estaba (ajustando)
       Intro           guardar el sitio nuevo (ajustando)
       Retroceso / ESC salir ]]

local Z = vector3(0.0, 0.0, 1.0)
local SEP = 0.03   -- lo que Config.Carteles.Esquinas separa de la pared

local function Largo(v) return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z) end
local function Unidad(v) local l = Largo(v) return l > 0 and v / l or v end

local function Rehacer(e, k, id)
    local c1 = e.o
    local c2 = e.o + e.U * e.w
    local c3 = e.o + Z * e.h
    local c4 = c2 + Z * e.h
    return {
        k = k, id = id, v = previa and previa.v or 'previa:0',
        c1 = c1, c2 = c2, c3 = c3, c4 = c4,
        centro = (c1 + c4) * 0.5, normal = e.N,
    }
end

--- La distancia a la que el rectángulo entero cabe en pantalla.
local function Encaje(w, h, fov)
    local t = math.tan(math.rad(fov / 2))
    local ratio = GetAspectRatio(false)
    return math.max(h * 1.35 / (2 * t), w * 1.35 / (2 * t * ratio), 1.0)
end

local function AyudaPrevia(ajustar, aerea, e)
    local t
    if ajustar then
        t = ('~b~%.2f x %.2f m~s~~n~Flechas: mover · ~INPUT_SPRINT~ rápido~n~~INPUT_DUCK~ + flechas: ancho y alto · Rueda: tamaño~n~~INPUT_MULTIPLAYER_INFO~ / ~INPUT_VEH_DUCK~ separar / pegar · ~INPUT_RELOAD~ deshacer~n~~INPUT_LOOK_BEHIND~ %s · ~INPUT_FRONTEND_ACCEPT~ Guardar · ~INPUT_CELLPHONE_CANCEL~ Salir')
            :format(e.w, e.h, aerea and 'De frente' or 'Vista aérea')
    else
        t = ('Ratón: girar · Rueda: acercar~n~~INPUT_LOOK_BEHIND~ %s~n~~INPUT_CELLPHONE_CANCEL~ Volver al panel')
            :format(aerea and 'De frente' or 'Vista aérea')
    end
    Ayuda(t)
end

local function Previa(data)
    local k = data.clase == 'valla' and 'v' or 'c'
    local id = tonumber(data.id)
    local base = id and lienzos[k .. ':' .. id]
    if not base then return nil, 'No está en el mapa todavía. Prueba en unos segundos.' end

    local ped = PlayerPedId()
    if IsEntityDead(ped) then return nil, 'Ahora no puedes.' end

    local tam = k == 'v' and V.Tam or C.Tam
    local ajustar = data.ajustar == true

    -- El estado ajustable: origen (abajo izq.), ejes y tamaño.
    local e = {
        o = base.c1,
        U = Unidad(base.c2 - base.c1),
        N = base.normal,
        w = Largo(base.c2 - base.c1),
        h = Largo(base.c3 - base.c1),
    }
    local original = { o = e.o, w = e.w, h = e.h }

    -- Lo que se pinta: lo de la interfaz, o lo de verdad si no manda nada.
    local d
    if type(data.contenido) == 'table' then
        d = { contenido = data.contenido, negocio = data.negocio, logo = data.logo }
    else
        local ok, res = pcall(function()
            return lib.callback.await('origen_businesses:cb:lienzos:contenido', false, k, id)
        end)
        d = ok and type(res) == 'table' and res or { contenido = {} }
    end
    d.ancho, d.alto = e.w, e.h

    previa = { clave = k .. ':' .. id, v = 'previa:1', n = 1, datos = d }
    previa.l = Rehacer(e, k, id)
    datos[previa.v] = d

    LocalPlayer.state:set('mirandoCamara', true, false)
    local vida = GetEntityHealth(ped)

    local fov = 50.0
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, fov)
    local giro, alto = 0.0, 8.0
    local dist = Encaje(e.w, e.h, fov)
    local aerea = false
    local tamCambiado, ultimoEnvio = false, 0
    local resultado = nil

    local function Colocar()
        local centro = previa.l.centro
        local pos
        if aerea then
            local lejos = math.max(dist, 12.0)
            pos = centro + e.N * (lejos * 0.9) + Z * (lejos * 1.4 + 10.0)
        else
            -- Girar la normal alrededor de Z (giro) y levantarla (alto).
            local g, a = math.rad(giro), math.rad(alto)
            local nx = e.N.x * math.cos(g) - e.N.y * math.sin(g)
            local ny = e.N.x * math.sin(g) + e.N.y * math.cos(g)
            local dir = vector3(nx * math.cos(a), ny * math.cos(a), math.sin(a))
            pos = centro + dir * dist
        end
        SetCamCoord(cam, pos.x, pos.y, pos.z)
        PointCamAtCoord(cam, centro.x, centro.y, centro.z)
        SetFocusPosAndVel(centro.x, centro.y, centro.z, 0.0, 0.0, 0.0)
    end

    Colocar()
    RenderScriptCams(true, true, 600, true, false)

    while true do
        Wait(0)
        DisableAllControlActions(0)
        EnableControlAction(0, 249, true) -- la voz
        HideHudAndRadarThisFrame()
        local dt = GetFrameTime()

        -- Girar con el ratón.
        local mx, my = GetDisabledControlNormal(0, 1), GetDisabledControlNormal(0, 2)
        if not aerea and (mx ~= 0.0 or my ~= 0.0) then
            giro = math.max(-70.0, math.min(70.0, giro - mx * 8.0))
            alto = math.max(-15.0, math.min(65.0, alto - my * 8.0))
        end

        -- Acercar / alejar.
        local acercar = IsDisabledControlPressed(0, 10) and -1 or (IsDisabledControlPressed(0, 11) and 1 or 0)
        if acercar ~= 0 then dist = math.max(0.6, math.min(400.0, dist * (1 + acercar * dt * 1.5))) end
        if not ajustar then
            if IsDisabledControlJustPressed(0, 241) then dist = math.max(0.6, dist * 0.88) end
            if IsDisabledControlJustPressed(0, 242) then dist = math.min(400.0, dist * 1.12) end
        end

        if IsDisabledControlJustPressed(0, 26) then aerea = not aerea end

        if ajustar then
            local rapido = IsDisabledControlPressed(0, 21)
            local ctrl = IsDisabledControlPressed(0, 36)
            local paso = (rapido and 2.0 or 0.35) * dt
            if k == 'v' then paso = paso * 4 end

            local dx = (IsDisabledControlPressed(0, 175) and 1 or 0) - (IsDisabledControlPressed(0, 174) and 1 or 0)
            local dy = (IsDisabledControlPressed(0, 172) and 1 or 0) - (IsDisabledControlPressed(0, 173) and 1 or 0)

            if ctrl then
                -- Cambiar el tamaño desde el centro.
                if dx ~= 0 then
                    local nw = math.max(tam.minAncho, math.min(tam.maxAncho, e.w + dx * paso * 2))
                    e.o = e.o - e.U * ((nw - e.w) / 2)
                    e.w, tamCambiado = nw, true
                end
                if dy ~= 0 then
                    local nh = math.max(tam.minAlto, math.min(tam.maxAlto, e.h + dy * paso * 2))
                    e.o = e.o - Z * ((nh - e.h) / 2)
                    e.h, tamCambiado = nh, true
                end
            else
                if dx ~= 0 then e.o = e.o + e.U * (dx * paso) end
                if dy ~= 0 then e.o = e.o + Z * (dy * paso) end
            end

            -- La rueda escala las dos cosas a la vez, sin deformar.
            local rueda = IsDisabledControlJustPressed(0, 241) and 1 or (IsDisabledControlJustPressed(0, 242) and -1 or 0)
            if rueda ~= 0 then
                local f = rueda > 0 and 1.05 or (1 / 1.05)
                local nw, nh = e.w * f, e.h * f
                if nw >= tam.minAncho and nw <= tam.maxAncho and nh >= tam.minAlto and nh <= tam.maxAlto then
                    e.o = e.o - e.U * ((nw - e.w) / 2) - Z * ((nh - e.h) / 2)
                    e.w, e.h, tamCambiado = nw, nh, true
                end
            end

            -- Separar o pegar a la pared (una valla puede tener la cara hundida).
            local fondo = (IsDisabledControlPressed(0, 20) and 1 or 0) - (IsDisabledControlPressed(0, 73) and 1 or 0)
            if fondo ~= 0 then e.o = e.o + e.N * (fondo * 0.15 * dt * (k == 'v' and 4 or 1)) end

            if IsDisabledControlJustPressed(0, 45) then
                e.o, e.w, e.h, tamCambiado = original.o, original.w, original.h, true
            end

            -- Con otro tamaño la página se vuelve a maquetar (si no, el texto
            -- saldría estirado). Como mucho cinco veces por segundo.
            if tamCambiado and GetGameTimer() - ultimoEnvio > 200 then
                tamCambiado, ultimoEnvio = false, GetGameTimer()
                datos[previa.v] = nil
                previa.n = previa.n + 1
                previa.v = 'previa:' .. previa.n
                local nuevo = {}
                for kk, vv in pairs(d) do nuevo[kk] = vv end
                nuevo.ancho, nuevo.alto = e.w, e.h
                d = nuevo
                previa.datos = d
                datos[previa.v] = d
            end

            previa.l = Rehacer(e, k, id)

            -- El borde, para ver el hueco aunque la página aún no se haya
            -- repintado con el tamaño nuevo.
            local l = previa.l
            DrawLine(l.c1.x, l.c1.y, l.c1.z, l.c2.x, l.c2.y, l.c2.z, 216, 27, 85, 255)
            DrawLine(l.c2.x, l.c2.y, l.c2.z, l.c4.x, l.c4.y, l.c4.z, 216, 27, 85, 255)
            DrawLine(l.c4.x, l.c4.y, l.c4.z, l.c3.x, l.c3.y, l.c3.z, 216, 27, 85, 255)
            DrawLine(l.c3.x, l.c3.y, l.c3.z, l.c1.x, l.c1.y, l.c1.z, 216, 27, 85, 255)

            if IsDisabledControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 201) then
                local function T(p) return { x = p.x, y = p.y, z = p.z } end
                resultado = {
                    p1 = T(e.o - e.N * SEP),
                    p2 = T(l.c4 - e.N * SEP),
                    normal = T(e.N),
                }
                break
            end
        end

        Colocar()
        AyudaPrevia(ajustar, aerea, e)

        if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 322) then
            break
        end
        if IsEntityDead(ped) or GetEntityHealth(ped) < vida then break end
    end

    RenderScriptCams(false, true, 500, true, false)
    DestroyCam(cam, false)
    ClearFocus()
    datos[previa.v] = nil
    previa = nil
    -- El ESC de salir no puede abrir el radial al soltarse.
    SetTimeout(400, function() LocalPlayer.state:set('mirandoCamara', false, false) end)
    return resultado
end

RegisterNUICallback('lienzos:previa', function(data, cb)
    if marcando or previa then cb(nil) return end
    marcando = true
    SetNuiFocus(false, false)

    local ok, res, motivo = pcall(Previa, data or {})
    if not ok then
        print(('^1[origen_businesses] previa: %s^0'):format(tostring(res)))
        res = nil
        previa = nil
        RenderScriptCams(false, false, 0, true, false)
        ClearFocus()
        LocalPlayer.state:set('mirandoCamara', false, false)
    elseif motivo then
        Custom.Notify({ title = 'Carteles', description = motivo, type = 'error' })
    end

    marcando = false
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    cb(res)
end)

-- ── Lo que pide la interfaz ──────────────────────────────────────────────

local function Pasar(nombre)
    RegisterNUICallback(nombre, function(data, cb)
        local ok, res = pcall(function()
            return lib.callback.await('origen_businesses:cb:' .. nombre, false, data)
        end)
        cb((ok and type(res) == 'table') and res or { success = false, message = 'No hubo respuesta del servidor.' })
    end)
end

for _, nombre in ipairs({
    'carteles:lista', 'carteles:colgar', 'carteles:guardar', 'carteles:quitar', 'carteles:mover',
    'vallas:lista', 'vallas:alquilar', 'vallas:guardar',
    'vallas:admin:lista', 'vallas:admin:crear', 'vallas:admin:editar', 'vallas:admin:mover',
    'vallas:admin:terminar', 'vallas:admin:borrar', 'carteles:admin:quitar',
}) do Pasar(nombre) end

--[[ La imagen: como el logo, por origen_uploader para que el tamaño no
     tope con el de un evento. ]]
RegisterNUICallback('carteles:imagen', function(data, cb)
    if not data or type(data.base64) ~= 'string' then cb({ success = false, message = 'No llegó la imagen.' }) return end
    if GetResourceState('origen_uploader') ~= 'started' then
        cb({ success = false, message = 'El servicio de imágenes no está disponible.' })
        return
    end
    local resguardo, motivo = exports['origen_uploader']:PrepararSubida(data.nombre, data.base64)
    if not resguardo then cb({ success = false, message = motivo or 'No se pudo enviar la imagen.' }) return end

    local ok, res = pcall(function()
        return lib.callback.await('origen_businesses:cb:carteles:imagen', false, {
            businessId = data.businessId, ticket = resguardo, nombre = data.nombre,
        })
    end)
    cb((ok and res) or { success = false, message = 'No se pudo subir la imagen.' })
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= RECURSO then return end
    for _, juego in pairs(juegos) do
        for _, slot in ipairs(juego.slots) do Destruir(slot) end
    end
end)
