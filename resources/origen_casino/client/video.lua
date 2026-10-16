--[[ ══════════════════════════════════════════════════════════════════════════
     LAS MÁQUINAS DE VÍDEO EN EL MUNDO

     Cada máquina de vídeo lleva su taburete (como las tragaperras de GTA) y
     una pantalla de verdad: un navegador aparte (CreateDui) con la página
     ui/pantalla.html, pintado sobre el cristal del mueble con cuatro
     esquinas, igual que las pantallas del bingo. Lo ve el que juega y lo ven
     los que pasan.

     ── Cuántos navegadores ─────────────────────────────────────────────────

     Un navegador por máquina cuesta memoria y tiempo de CPU. Solo tienen el
     suyo las máquinas a menos de `DISTANCIA` metros, y como mucho
     `MAX_NAVEGADORES` (las más cercanas). Las demás enseñan la pantalla que
     trae el mueble. Al alejarse, el navegador se cierra.

     ── Jugar ───────────────────────────────────────────────────────────────

     Como la tragaperras de rodillos, con el teclado y sin ratón; las teclas
     las dice la interfaz (juegos/Video.vue):

         Espacio            girar (o acelerar lo que se está mostrando)
         Flecha arriba/abajo  subir o bajar la apuesta
         E (mantener)       comprar el bono, si la máquina lo vende
         H                  tabla de pagos en la pantalla
         Retroceso / Esc    levantarse
   ══════════════════════════════════════════════════════════════════════════ ]]

VideoMundo = {}

local DISTANCIA = 12.0
local MAX_NAVEGADORES = 6
local PAGINA = ('nui://%s/ui/pantalla.html'):format(GetCurrentResourceName())
local MARCA = GetConvar('origen:marca', 'origen')

local maquinas = {}      -- [puntoId] = { ent, tipo, punto, taburete }
local pantallas = {}     -- [puntoId] = { dui, txd, listo }
local numTxd = 0

function VideoEsJuego(juego)
    return juego == 'golpe' or juego == 'clasica' or juego == 'atrapa' or juego == 'cascadas'
end

-- ── El taburete ───────────────────────────────────────────────────────────

--[[ Se pone en la silla del catálogo (el hueso de las tragaperras de GTA) a
     ras del suelo del punto. Si ya hay uno ahí —una máquina puesta sobre una
     tragaperras del mapa, que trae el suyo—, no se pone otro. Sin colisión,
     como los del casino: con ella la animación de sentarse choca y el
     personaje sale despedido. ]]
local function PonerTaburete(punto, tipo, ent)
    local t = tipo.video and tipo.video.taburete
    if not t then return nil end
    local hash = joaat(t.modelo)
    if not IsModelInCdimage(hash) or not pcall(lib.requestModel, hash, 5000) then return nil end
    local pos = GetOffsetFromEntityInWorldCoords(ent, t.dx or 0.0, t.dy or 0.0, 0.0)
    if GetClosestObjectOfType(pos.x, pos.y, pos.z, 0.5, hash, false, false, false) ~= 0 then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end
    local bajo = GetModelDimensions(hash)
    local s = CreateObject(hash, pos.x, pos.y, punto.z - ((bajo and bajo.z) or 0.0), false, false, false)
    SetEntityHeading(s, (punto.h or 0.0) + (t.dh or 0.0))
    FreezeEntityPosition(s, true)
    SetEntityCollision(s, false, false)
    SetModelAsNoLongerNeeded(hash)
    return s
end

-- ── La pantalla ───────────────────────────────────────────────────────────

local function Mandar(id, datos)
    local p = pantallas[id]
    if p and p.listo then SendDuiMessage(p.dui, json.encode(datos)) end
end

local function CerrarPantalla(id)
    local p = pantallas[id]
    if not p then return end
    pantallas[id] = nil
    if p.dui then DestroyDui(p.dui) end
end

local function AbrirPantalla(id)
    local m = maquinas[id]
    if not m or pantallas[id] then return end
    local p = {}
    pantallas[id] = p
    CreateThread(function()
        local url = ('%s?juego=%s&marca=%s'):format(PAGINA, m.punto.juego, MARCA)
        local dui = CreateDui(url, 1280, 564)
        p.dui = dui
        local hasta = GetGameTimer() + 5000
        while not IsDuiAvailable(dui) and GetGameTimer() < hasta do Wait(20) end
        if pantallas[id] ~= p then DestroyDui(dui) return end
        -- Un runtime txd no se borra: cada navegador nuevo, un nombre nuevo.
        numTxd = numTxd + 1
        p.txd = 'origen_casino_video_' .. numTxd
        CreateRuntimeTextureFromDuiHandle(CreateRuntimeTxd(p.txd), 'pantalla', GetDuiHandle(dui))
        -- La página tarda un poco en estar escuchando.
        Wait(1200)
        if pantallas[id] ~= p then return end
        p.listo = true
        local est = C.sesion and C.sesion.punto == id and C.estado or nil
        Mandar(id, { a = 'maquina', juego = m.punto.juego, tabla = VideoTabla(m.punto.juego),
                     apuesta = est and est.apuesta or m.punto.min })
    end)
end

--[[ La pantalla en el mundo: el rectángulo exacto del hueco (x0..x1,
     z0..z1), inclinado como el cristal (`y0` abajo, `y1` arriba), y un
     MARCO NEGRO de `fondo` metros hacia dentro del mueble por los cuatro
     lados, como el canto de una pantalla empotrada. De frente el marco no
     se ve (está de canto); de lado tapa el hueco entre la pantalla y el
     cristal, por el que antes se veía el dibujo de la máquina. ]]
local function Cara(a, b, c, d, txd, u)
    -- a arriba-dcha, b arriba-izq, c abajo-dcha, d abajo-izq; por las dos caras
    if txd then
        local n = 'pantalla'
        DrawTexturedPoly(a.x, a.y, a.z, b.x, b.y, b.z, d.x, d.y, d.z, 255, 255, 255, 255, txd, n, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        DrawTexturedPoly(a.x, a.y, a.z, d.x, d.y, d.z, c.x, c.y, c.z, 255, 255, 255, 255, txd, n, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0)
        DrawTexturedPoly(d.x, d.y, d.z, b.x, b.y, b.z, a.x, a.y, a.z, 255, 255, 255, 255, txd, n, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0)
        DrawTexturedPoly(c.x, c.y, c.z, d.x, d.y, d.z, a.x, a.y, a.z, 255, 255, 255, 255, txd, n, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0)
    else
        DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, d.x, d.y, d.z, 6, 6, 8, 255)
        DrawPoly(a.x, a.y, a.z, d.x, d.y, d.z, c.x, c.y, c.z, 6, 6, 8, 255)
        DrawPoly(d.x, d.y, d.z, b.x, b.y, b.z, a.x, a.y, a.z, 6, 6, 8, 255)
        DrawPoly(c.x, c.y, c.z, d.x, d.y, d.z, a.x, a.y, a.z, 6, 6, 8, 255)
    end
end

local function Pintar(m, p)
    local s, e = m.tipo.video.pantalla, m.ent
    local o = GetOffsetFromEntityInWorldCoords
    local c1, c2 = o(e, s.x1, s.y1, s.z1), o(e, s.x0, s.y1, s.z1)
    local c3, c4 = o(e, s.x1, s.y0, s.z0), o(e, s.x0, s.y0, s.z0)
    Cara(c1, c2, c3, c4, p.txd)
    -- El marco: las mismas esquinas, `fondo` metros hacia dentro (normal del cristal).
    local f = s.fondo or 0.0
    if f > 0 then
        local dy, dz = 0.981 * f, -0.193 * f
        local d1, d2 = o(e, s.x1, s.y1 + dy, s.z1 + dz), o(e, s.x0, s.y1 + dy, s.z1 + dz)
        local d3, d4 = o(e, s.x1, s.y0 + dy, s.z0 + dz), o(e, s.x0, s.y0 + dy, s.z0 + dz)
        Cara(d1, d2, c1, c2)      -- arriba
        Cara(c3, c4, d3, d4)      -- abajo
        Cara(c2, d2, c4, d4)      -- izquierda
        Cara(d1, c1, d3, c3)      -- derecha
    end
end

CreateThread(function()
    while true do
        local espera = 500
        if next(maquinas) then
            local yo = GetEntityCoords(cache.ped)
            local cerca = {}
            for id, m in pairs(maquinas) do
                if DoesEntityExist(m.ent) then
                    local d = #(yo - vector3(m.punto.x, m.punto.y, m.punto.z))
                    if d <= DISTANCIA then cerca[#cerca + 1] = { id = id, d = d } end
                end
            end
            table.sort(cerca, function(a, b) return a.d < b.d end)
            local quedan = {}
            for k = 1, math.min(#cerca, MAX_NAVEGADORES) do
                local id = cerca[k].id
                quedan[id] = true
                if not pantallas[id] then AbrirPantalla(id) end
            end
            -- La máquina en la que se juega no pierde su pantalla nunca.
            if C.sesion and maquinas[C.sesion.punto] then
                quedan[C.sesion.punto] = true
                if not pantallas[C.sesion.punto] then AbrirPantalla(C.sesion.punto) end
            end
            for id in pairs(pantallas) do
                if not quedan[id] then CerrarPantalla(id) end
            end
            for id, p in pairs(pantallas) do
                local m = maquinas[id]
                if m and p.txd and DoesEntityExist(m.ent) then Pintar(m, p) end
            end
            if next(pantallas) then espera = 0 end
        end
        Wait(espera)
    end
end)

-- ── Poner y quitar (desde client/puntos.lua) ──────────────────────────────

function VideoMundo.Poner(punto, tipo, ent)
    VideoMundo.Quitar(punto.id)
    if not ent or not DoesEntityExist(ent) or not tipo.video then return end
    maquinas[punto.id] = { ent = ent, tipo = tipo, punto = punto, taburete = PonerTaburete(punto, tipo, ent) }
end

function VideoMundo.Quitar(id)
    CerrarPantalla(id)
    local m = maquinas[id]
    if not m then return end
    maquinas[id] = nil
    if m.taburete and DoesEntityExist(m.taburete) then DeleteEntity(m.taburete) end
end

-- ── Lo que llega del servidor ─────────────────────────────────────────────

local ocupadoHasta = 0
local mostrando = 0          -- hasta cuándo se está mostrando una jugada mía

RegisterNetEvent('origen_casino:video', function(id, jugada)
    id = tonumber(id)
    if type(jugada) ~= 'table' then return end
    Mandar(id, { a = 'jugada', jugada = jugada })
    if C.sesion and C.sesion.punto == id then
        local dura = VideoDuracion(jugada)
        mostrando = GetGameTimer() + dura
        ocupadoHasta = mostrando
        C.Enviar('videoJugada', { pago = jugada.pago, coste = jugada.coste, duracion = dura, bono = jugada.bono ~= nil })
    end
end)

-- La apuesta de la sesión, también en la pantalla del mueble.
AddEventHandler('origen_casino:estado', function(estado)
    if type(estado) ~= 'table' or not VideoEsJuego(estado.juego) then return end
    Mandar(tonumber(estado.punto), { a = 'apuesta', apuesta = estado.apuesta })
end)

-- ── Las teclas ────────────────────────────────────────────────────────────

local TECLA = {
    girar = 22,          -- INPUT_JUMP (Espacio)
    subir = 172,         -- INPUT_CELLPHONE_UP (flecha arriba)
    bajar = 173,         -- INPUT_CELLPHONE_DOWN (flecha abajo)
    comprar = 38,        -- INPUT_PICKUP (E)
    ayuda = 74,          -- INPUT_VEH_HEADLIGHT (H)
    salir = 194,         -- INPUT_FRONTEND_RRIGHT (Retroceso)
    esc = 200,           -- INPUT_FRONTEND_PAUSE_ALTERNATE (Esc)
}

--- Lo que hay que mantener E para comprar el bono: cuesta cien apuestas.
local MANTENER = 1200

local function Accion(nombre, datos)
    return lib.callback.await('origen_casino:accion', false, nombre, datos) or { ok = false }
end

local function Girar(comprar)
    local est = C.estado or {}
    local apuesta = tonumber(est.apuesta) or 0
    if apuesta <= 0 then return end
    local coste = comprar and apuesta * (tonumber(est.compra) or 0) or apuesta
    if coste <= 0 then return end
    if (tonumber(est.fichas) or 0) < coste then
        C.Aviso(Config.General.nombre, 'No te quedan fichas para eso. Se compran en la caja.', 'error')
        return
    end
    -- Mientras llega la respuesta, nada más: dos «girar» seguidos se cobrarían los dos.
    ocupadoHasta = GetGameTimer() + 4000
    CreateThread(function() Gesto('boton') end)
    local r = Accion(comprar and 'comprar' or 'girar', { apuesta = apuesta })
    if not r.ok then
        ocupadoHasta = 0
        if r.mensaje then C.Aviso(Config.General.nombre, r.mensaje, 'error') end
    end
end

local function Apostar(paso)
    local est = C.estado or {}
    local lista = est.fichasApuesta or {}
    if #lista == 0 then return end
    local actual = tonumber(est.apuesta) or lista[1]
    local k = 1
    for i, v in ipairs(lista) do if v == actual then k = i break end end
    local nueva = lista[math.max(1, math.min(#lista, k + paso))]
    if nueva == actual then return end
    ocupadoHasta = GetGameTimer() + 350
    CreateThread(function() Gesto('apuestaUno') end)
    local r = Accion('apuesta', { apuesta = nueva })
    if not r.ok and r.mensaje then C.Aviso(Config.General.nombre, r.mensaje, 'error') end
end

CreateThread(function()
    local pulsadoE = nil
    local ayuda = false
    while true do
        local espera = 400
        local ses = C.sesion
        if ses and VideoEsJuego(ses.juego) and C.pantalla == 'juego' then
            espera = 0
            for _, t in pairs(TECLA) do DisableControlAction(0, t, true) end
            DisableControlAction(0, 199, true)       -- el menú de pausa
            DisableControlAction(0, 27, true)        -- el móvil (flecha arriba)
            local ahora = GetGameTimer()
            local libre = ahora >= ocupadoHasta

            if IsDisabledControlJustPressed(0, TECLA.girar) then
                if ahora < mostrando then
                    -- Acelerar lo que se está mostrando: todo a un tercio.
                    Mandar(ses.punto, { a = 'rapido' })
                    local resto = math.floor((mostrando - ahora) / 3)
                    mostrando = ahora + resto
                    ocupadoHasta = mostrando
                    C.Enviar('videoRapido', { duracion = resto })
                elseif libre then
                    CreateThread(function() Girar(false) end)
                end
            elseif libre and IsDisabledControlJustPressed(0, TECLA.subir) then
                CreateThread(function() Apostar(1) end)
            elseif libre and IsDisabledControlJustPressed(0, TECLA.bajar) then
                CreateThread(function() Apostar(-1) end)
            elseif IsDisabledControlJustPressed(0, TECLA.ayuda) then
                ayuda = not ayuda
                Mandar(ses.punto, { a = 'ayuda', on = ayuda })
            elseif IsDisabledControlJustPressed(0, TECLA.salir) or IsDisabledControlJustPressed(0, TECLA.esc) then
                ayuda = false
                CreateThread(function()
                    Levantarse()
                    CerrarJuego()
                end)
            end

            -- Comprar el bono: mantener E. La interfaz enseña cuánto falta.
            if (C.estado and C.estado.compra) and libre and IsDisabledControlPressed(0, TECLA.comprar) then
                pulsadoE = pulsadoE or ahora
                local parte = math.min(1.0, (ahora - pulsadoE) / MANTENER)
                C.Enviar('videoMantener', parte)
                if parte >= 1.0 then
                    pulsadoE = nil
                    C.Enviar('videoMantener', 0)
                    CreateThread(function() Girar(true) end)
                end
            elseif pulsadoE then
                pulsadoE = nil
                C.Enviar('videoMantener', 0)
            end
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for id in pairs(maquinas) do VideoMundo.Quitar(id) end
end)
