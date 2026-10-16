--[[ ── El editor de la cantera ───────────────────────────────────────────────

     Para colocar la cantera a ojo, dentro del juego: se elige un sitio de
     la lista (el capataz, la planta entera, las salidas del vehículo y los
     bloques de voladura), se mueve con las flechas mirando por donde mira
     la cámara, y se guarda.

     Lo que se ve se rehace en cuanto algo cambia, así que se coloca mirando
     el resultado, no números.

     Teclas: TAB siguiente sitio · MAYÚS+TAB anterior · flechas mover
             AV/RE PÁG subir y bajar · Q/E girar
             CTRL fino (2 cm/s) · MAYÚS rápido (2 m/s) · sin nada, 0,4 m/s
             ESPACIO traer el sitio a donde estás tú
             INTRO guardar · SUPR deshacer lo tocado · RETROCESO salir ]]

Editor = { abierto = false }

local TECLAS = {
    tab = 9, shift = 16, ctrl = 17, enter = 13, retroceso = 8, supr = 46, espacio = 32,
    izq = 37, arriba = 38, der = 39, abajo = 40, repag = 33, avpag = 34, q = 81, e = 69,
}

--[[ Metros y grados POR SEGUNDO, no por fotograma: con 60 fps, un paso fijo
     por fotograma movía seis metros en un segundo y no había quien ajustara
     nada. Fino con CTRL, rápido con MAYÚS. ]]
local RITMOS = {
    fino = { metros = 0.05, grados = 3.0 },
    normal = { metros = 0.4, grados = 12.0 },
    rapido = { metros = 2.0, grados = 60.0 },
}

local elegido = 1
local cambiado = false
local original

local function Punto()
    return Mina.Sitios[elegido]
end

--- Qué ritmo toca según las teclas: fino, normal o rápido.
function Ritmo()
    if IsRawKeyDown(TECLAS.ctrl) then return 'FINO', RITMOS.fino end
    if IsRawKeyDown(TECLAS.shift) then return 'RÁPIDO', RITMOS.rapido end
    return 'NORMAL', RITMOS.normal
end

--- Vuelve a montar lo que se ve de la cantera con los puntos de ahora.
local function Rehacer()
    if Cantera and Cantera.Rehacer then Cantera.Rehacer() end
end

local function Guardar()
    local r = lib.callback.await('origen_mining:editor:guardar', false, Mina.SitiosAhora())
    if r and r.ok then
        cambiado = false
        L.Aviso('Cantera guardada. Queda así para todos.', 'success')
    else
        L.Aviso((r and r.mensaje) or 'No se pudo guardar.', 'error')
    end
end

--[[ Lo que se ve mientras se edita, sin dibujar nada a mano:

     - Las TECLAS, en la barra de teclas del HUD (exports.origen_hud:
       setupControls), que ya va en pegatina. Se pone al abrir y se quita al
       cerrar: no cambia mientras se edita.
     - Los DATOS (el sitio elegido, dónde está, el ritmo y si hay cambios sin
       guardar), en el aviso de tecla de origen_notify con L.Ayuda, que solo
       lo manda a la NUI cuando cambia. Mientras algo se mueve cambia en cada
       fotograma: se refresca como mucho cada 120 ms. ]]
local BARRA = {
    { key = 'TAB', text = 'Cambiar de sitio' },
    { key = 'Flechas', text = 'Mover' },
    { key = 'Q / E', text = 'Girar' },
    { key = 'Re / Av Pág', text = 'Altura' },
    { key = 'Ctrl / Mayús', text = 'Fino / rápido' },
    { key = 'Espacio', text = 'Traer aquí' },
    { key = 'Intro', text = 'Guardar' },
    { key = 'Supr', text = 'Deshacer' },
    { key = 'Retroceso', text = 'Salir' },
}

local function PonerBarra()
    pcall(function() exports.origen_hud:setupControls(BARRA) end)
end

local function QuitarBarra()
    pcall(function() exports.origen_hud:hideControls() end)
end

local datosVistos = 0

--- El sitio elegido y dónde está, en el aviso de tecla; el ritmo en la
--- segunda tecla (Ctrl / Mayús, que son las que lo cambian).
local function Datos()
    local ahora = GetGameTimer()
    if ahora - datosVistos < 120 then return end
    datosVistos = ahora
    local n = #Mina.Sitios
    local p = Punto()
    if not p then return end
    local v = p.leer()
    local donde = ''
    if v then
        donde = p.rumbo and (' · %.2f %.2f %.2f · %.0f°'):format(v.x, v.y, v.z, v.w or 0)
            or (' · %.2f %.2f %.2f'):format(v.x, v.y, v.z)
    end
    local texto = ('%s (%d/%d)%s%s'):format(p.nombre, elegido, n, donde, cambiado and ' · SIN GUARDAR' or '')
    local modo, ritmo = Ritmo()
    L.Ayuda('editor', 'TAB', texto, { 'Ctrl / Mayús', ('%s · %.2f m/s · %.0f°/s'):format(modo, ritmo.metros, ritmo.grados) })
end

--- La marca en el suelo del sitio elegido, con su flecha si mira a algún lado.
--- En colores pegatina: la elegida en rosa (216,27,85), las demás en gris.
local function Marca()
    local p = Punto()
    local v = p and p.leer()
    if not v then return end
    local z = (Cantera.Suelo(v.x, v.y, v.z) or v.z)
    DrawMarker(1, v.x, v.y, z - 0.9, 0, 0, 0, 0, 0, 0, 1.2, 1.2, 1.6, 216, 27, 85, 120, false, false, 2, false)
    if p.rumbo then
        Cantera.Flecha(vec3(v.x, v.y, z), v.w or 0.0, 3.0, { 216, 27, 85, 190 })
    end
    for i, otro in ipairs(Mina.Sitios) do
        if i ~= elegido then
            local o = otro.leer()
            if o and #(vec2(o.x, o.y) - vec2(v.x, v.y)) < 60.0 then
                local oz = (Cantera.Suelo(o.x, o.y, o.z) or o.z)
                DrawMarker(1, o.x, o.y, oz - 0.9, 0, 0, 0, 0, 0, 0, 0.7, 0.7, 1.0, 220, 221, 224, 90, false, false, 2, false)
            end
        end
    end
end

local function Mover(dx, dy, dz, dw)
    local p = Punto()
    local v = p.leer()
    if not v then return end
    local nx, ny, nz = v.x + dx, v.y + dy, v.z + dz
    if p.rumbo then
        p.poner(vec4(nx, ny, nz, ((v.w or 0.0) + dw) % 360))
    else
        p.poner(vec3(nx, ny, nz))
    end
    cambiado = true
    Rehacer()
end

function Editor.Abrir()
    if Editor.abierto then return end
    Editor.abierto = true
    original = Mina.SitiosAhora()
    cambiado = false
    L.Aviso('Editor abierto. TAB cambia de sitio, INTRO guarda.', 'success')
    PonerBarra()
    datosVistos = 0
    CreateThread(function()
        while Editor.abierto do
            Datos()
            Marca()
            local _, ritmo = Ritmo()
            local dt = GetFrameTime()
            local paso = ritmo.metros * dt
            local giro = ritmo.grados * dt

            -- Mover mirando por donde mira la cámara.
            local rot = GetGameplayCamRot(2)
            local h = math.rad(rot.z)
            local fx, fy = -math.sin(h), math.cos(h)
            local rx, ry = math.cos(h), math.sin(h)
            if IsRawKeyDown(TECLAS.arriba) then Mover(fx * paso, fy * paso, 0, 0) end
            if IsRawKeyDown(TECLAS.abajo) then Mover(-fx * paso, -fy * paso, 0, 0) end
            if IsRawKeyDown(TECLAS.der) then Mover(rx * paso, ry * paso, 0, 0) end
            if IsRawKeyDown(TECLAS.izq) then Mover(-rx * paso, -ry * paso, 0, 0) end
            if IsRawKeyDown(TECLAS.repag) then Mover(0, 0, paso * 0.6, 0) end
            if IsRawKeyDown(TECLAS.avpag) then Mover(0, 0, -paso * 0.6, 0) end
            if IsRawKeyDown(TECLAS.q) then Mover(0, 0, 0, giro) end
            if IsRawKeyDown(TECLAS.e) then Mover(0, 0, 0, -giro) end

            if IsRawKeyReleased(TECLAS.tab) then
                local n = #Mina.Sitios
                elegido = IsRawKeyDown(TECLAS.shift) and ((elegido - 2) % n + 1) or (elegido % n + 1)
            end
            if IsRawKeyReleased(TECLAS.espacio) then
                local c = GetEntityCoords(cache.ped)
                local p = Punto()
                if p.rumbo then
                    p.poner(vec4(c.x, c.y, c.z - 1.0, GetEntityHeading(cache.ped)))
                else
                    p.poner(vec3(c.x, c.y, c.z - 1.0))
                end
                cambiado = true
                Rehacer()
            end
            if IsRawKeyReleased(TECLAS.supr) then
                Mina.AplicarSitios(original)
                cambiado = false
                Rehacer()
                L.Aviso('Deshecho: vuelve a estar como al abrir el editor.', 'success')
            end
            if IsRawKeyReleased(TECLAS.enter) then Guardar() end
            if IsRawKeyReleased(TECLAS.retroceso) then Editor.Cerrar() end
            Wait(0)
        end
    end)
end

function Editor.Cerrar()
    if not Editor.abierto then return end
    Editor.abierto = false
    QuitarBarra()
    L.QuitarAyuda('editor')
    if cambiado then
        Mina.AplicarSitios(original)
        Rehacer()
        L.Aviso('Editor cerrado sin guardar: se queda como estaba.', 'error')
    else
        L.Aviso('Editor cerrado.', 'success')
    end
end

-- Si el recurso se para con el editor abierto, la barra de teclas del HUD
-- se quedaría puesta (el aviso de tecla ya lo quita estado.lua).
AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() and Editor.abierto then QuitarBarra() end
end)

-- Al arrancar, los sitios que diga el servidor (manda el fichero guardado).
CreateThread(function()
    Wait(2500)
    local t = lib.callback.await('origen_mining:editor:pedirPuntos', false)
    if type(t) == 'table' then
        Mina.AplicarSitios(t)
        Rehacer()
    end
end)

RegisterNetEvent('origen_mining:editor:abrir', function()
    if GetInvokingResource() then return end
    Editor.Abrir()
end)

--- Cuando otro guarda (o guardas tú), todos se enteran y lo repintan.
RegisterNetEvent('origen_mining:editor:puntos', function(t)
    if GetInvokingResource() then return end
    Mina.AplicarSitios(t)
    Rehacer()
end)
