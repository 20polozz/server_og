--[[ ── El editor del patio ─────────────────────────────────────────────────────

     Para colocar el aserradero a ojo, dentro del juego: se elige un sitio de
     la lista (el encargado, la bahía de entrega y las salidas del camión),
     se mueve con las flechas
     mirando por donde mira la cámara, y se guarda.

     Lo que se ve se rehace en cuanto algo cambia, así que se coloca mirando
     el resultado, no números.

     Teclas: TAB siguiente sitio · MAYÚS+TAB anterior · flechas mover
             AV/RE PÁG subir y bajar · Q/E girar
             CTRL fino (2 cm/s) · MAYÚS rápido (2 m/s) · sin nada, 0,4 m/s
             ESPACIO traer el sitio a donde estás tú
             INTRO guardar · SUPR deshacer lo tocado · RETROCESO salir ]]

Editor = { abierto = false }

local TECLAS = {
    tab = 9, shift = 16, ctrl = 17, enter = 13, retroceso = 8, supr = 46, espacio = 32, g = 71,
    mas = 187, menos = 189, masNum = 107, menosNum = 109,
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
    return Lista()[elegido]
end

--- Qué ritmo toca según las teclas: fino, normal o rápido.
--- Solo nuestras máquinas y carteles (el usuario, 28/09): el encargado, la
--- bahía y las salidas ya no se tocan desde aquí.
local lista
function Lista()
    if not lista then
        lista = {}
        for _, p in ipairs(Lumber.Sitios) do
            if p.id:find('^maq_') or p.id:find('^deco_') then lista[#lista + 1] = p end
        end
    end
    return lista
end

--- Velocidad a mano: + la dobla y - la divide por dos (de 1/16 a x16).
local multi = 1.0
function Ritmo()
    local base, modo = RITMOS.normal, 'NORMAL'
    if IsRawKeyDown(TECLAS.ctrl) then base, modo = RITMOS.fino, 'FINO' end
    if IsRawKeyDown(TECLAS.shift) then base, modo = RITMOS.rapido, 'RÁPIDO' end
    return ('%s x%s'):format(modo, multi >= 1 and ('%g'):format(multi) or ('1/%g'):format(1 / multi)),
        { metros = base.metros * multi, grados = base.grados * multi }
end

--- Vuelve a montar lo que se ve del patio con los puntos de ahora.
local function Rehacer()
    if Aserradero and Aserradero.Rehacer then Aserradero.Rehacer() end
    if Linea and Linea.Recolocar then Linea.Recolocar() end
end

--- Flechas: tecla física o control del juego (el vuelo libre se queda las teclas crudas).
local CONTROLES = { arriba = 172, abajo = 173, izq = 174, der = 175, repag = 10, avpag = 11 }
local function Pulsada(nombre)
    if IsRawKeyDown(TECLAS[nombre]) then return true end
    local c = CONTROLES[nombre]
    return c ~= nil and (IsDisabledControlPressed(0, c) or IsControlPressed(0, c))
end

--- El suelo en (x, y): rayo desde poco por encima que solo ve terreno y
--- edificios del mapa (no las máquinas, que son objetos).
local function SueloBajo(x, y, z)
    local h = StartExpensiveSynchronousShapeTestLosProbe(x + 0.0, y + 0.0, z + 2.0, x + 0.0, y + 0.0, z - 60.0, 1, cache.ped, 0)
    local _, hit, c = GetShapeTestResult(h)
    return hit == 1 and c.z or nil
end

local function Guardar()
    local r = lib.callback.await('origen_lumber:editor:guardar', false, Lumber.SitiosAhora())
    if r and r.ok then
        cambiado = false
        L.Aviso('Patio guardado. Queda así para todos.', 'success')
    else
        L.Aviso((r and r.mensaje) or 'No se pudo guardar.', 'error')
    end
end

--[[ Lo que se ve mientras se edita, sin dibujar nada a mano:

     - Las TECLAS, en la barra de teclas del HUD (exports.origen_hud:
       setupControls), que ya va en pegatina. Se pone al abrir y se quita al
       cerrar: no cambia mientras se edita.
     - Los DATOS (la máquina elegida, dónde está, el ritmo y si hay cambios
       sin guardar), en el aviso de tecla de origen_notify con L.Ayuda, que
       solo lo manda a la NUI cuando cambia. Mientras algo se mueve cambia en
       cada fotograma: se refresca como mucho cada 120 ms. ]]
local BARRA = {
    { key = 'TAB', text = 'Cambiar de máquina' },
    { key = 'Flechas', text = 'Mover' },
    { key = 'Q / E', text = 'Girar' },
    { key = 'Re / Av Pág', text = 'Altura' },
    { key = 'Ctrl / Mayús', text = 'Fino / rápido' },
    { key = 'Espacio', text = 'Traer aquí' },
    { key = 'G', text = 'Al suelo' },
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

--- La máquina elegida y su sitio, en el aviso de tecla; el ritmo en la
--- segunda tecla (+ / -, que es la que lo cambia).
local function Datos()
    local ahora = GetGameTimer()
    if ahora - datosVistos < 120 then return end
    datosVistos = ahora
    local n = #Lista()
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
    L.Ayuda('editor', 'TAB', texto, { '+ / -', ('%s · %.2f m/s · %.0f°/s'):format(modo, ritmo.metros, ritmo.grados) })
end

--- La marca en el suelo del sitio elegido, con su flecha si mira a algún lado.
--- En colores pegatina: la elegida en rosa (216,27,85), las demás en gris.
local function Marca()
    local p = Punto()
    local v = p and p.leer()
    if not v then return end
    local z = (Monte.Suelo(v.x, v.y, v.z) or v.z)
    DrawMarker(1, v.x, v.y, z - 0.9, 0, 0, 0, 0, 0, 0, 1.2, 1.2, 1.6, 216, 27, 85, 120, false, false, 2, false)
    if p.rumbo then
        Monte.Flecha(vec3(v.x, v.y, z), v.w or 0.0, 3.0, { 216, 27, 85, 190 })
    end
    for i, otro in ipairs(Lista()) do
        if i ~= elegido then
            local o = otro.leer()
            if o and #(vec2(o.x, o.y) - vec2(v.x, v.y)) < 60.0 then
                local oz = (Monte.Suelo(o.x, o.y, o.z) or o.z)
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
    original = Lumber.SitiosAhora()
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
            -- La cámara que se ve (también la del vuelo libre).
            local rot = GetFinalRenderedCamRot(2)
            local h = math.rad(rot.z)
            local fx, fy = -math.sin(h), math.cos(h)
            local rx, ry = math.cos(h), math.sin(h)
            for _, c in pairs(CONTROLES) do DisableControlAction(0, c, true) end
            if Pulsada('arriba') then Mover(fx * paso, fy * paso, 0, 0) end
            if Pulsada('abajo') then Mover(-fx * paso, -fy * paso, 0, 0) end
            if Pulsada('der') then Mover(rx * paso, ry * paso, 0, 0) end
            if Pulsada('izq') then Mover(-rx * paso, -ry * paso, 0, 0) end
            if Pulsada('repag') then Mover(0, 0, paso * 0.6, 0) end
            if Pulsada('avpag') then Mover(0, 0, -paso * 0.6, 0) end
            if IsRawKeyReleased(TECLAS.mas) or IsRawKeyReleased(TECLAS.masNum) then multi = math.min(16.0, multi * 2.0) end
            if IsRawKeyReleased(TECLAS.menos) or IsRawKeyReleased(TECLAS.menosNum) then multi = math.max(1.0 / 16.0, multi / 2.0) end
            if IsRawKeyReleased(TECLAS.g) then
                local v = Punto().leer()
                local z = v and SueloBajo(v.x, v.y, v.z)
                if z then Mover(0, 0, z - v.z, 0) end
            end
            if IsRawKeyDown(TECLAS.q) then Mover(0, 0, 0, giro) end
            if IsRawKeyDown(TECLAS.e) then Mover(0, 0, 0, -giro) end

            if IsRawKeyReleased(TECLAS.tab) then
                local n = #Lista()
                elegido = IsRawKeyDown(TECLAS.shift) and ((elegido - 2) % n + 1) or (elegido % n + 1)
            end
            if IsRawKeyReleased(TECLAS.espacio) then
                local c = GetEntityCoords(cache.ped)
                local p = Punto()
                local z = SueloBajo(c.x, c.y, c.z) or (c.z - 1.0)
                if p.rumbo then
                    p.poner(vec4(c.x, c.y, z, GetEntityHeading(cache.ped)))
                else
                    p.poner(vec3(c.x, c.y, z))
                end
                cambiado = true
                Rehacer()
            end
            if IsRawKeyReleased(TECLAS.supr) then
                Lumber.AplicarSitios(original)
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
        Lumber.AplicarSitios(original)
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
    local t = lib.callback.await('origen_lumber:editor:pedirPuntos', false)
    if type(t) == 'table' then
        Lumber.AplicarSitios(t)
        Rehacer()
    end
end)

RegisterNetEvent('origen_lumber:editor:abrir', function()
    if GetInvokingResource() then return end
    Editor.Abrir()
end)

--- Cuando otro guarda (o guardas tú), todos se enteran y lo repintan.
RegisterNetEvent('origen_lumber:editor:puntos', function(t)
    if GetInvokingResource() then return end
    Lumber.AplicarSitios(t)
    Rehacer()
end)
