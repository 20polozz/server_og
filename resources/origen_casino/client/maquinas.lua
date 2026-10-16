--[[ ══════════════════════════════════════════════════════════════════════════
     LOS RODILLOS DE VERDAD

     Las tragaperras del casino de GTA no traen los rodillos pintados: son tres
     props aparte (`<máquina>_reels`) que se meten en la ventana y se giran.
     Aquí se ponen al crear la máquina y se hacen girar cuando el servidor tira,
     para el que juega y para todos los que estén cerca mirando.

     El resultado lo manda el servidor; esto solo decide en qué casilla del
     rodillo se para cada uno para enseñar ese símbolo.

     ── Lo que se midió en el juego (24/09) ─────────────────────────────────

     · Dónde van: a (-0,115 | 0,005 | 0,125 ; 0,047 ; 0,906) del origen de la
       máquina. Las cinco máquinas tienen la ventana en el mismo sitio.
     · La tira: 16 casillas de 22,5° y LA MISMA en todas las máquinas; solo
       cambia el dibujo de dos de ellas (la figura y el emblema de cada tema).
       Ver `TIRA` más abajo.
     · El giro va con CUATERNIÓN alrededor del eje del rodillo. Con ángulos de
       Euler, pasados los 90° de cabeceo el motor lo reinterpreta y el rodillo
       salta a otra casilla: el 7 salía en la casilla 0 y otra vez en la 12.
     · Los props creados por un recurso NO se borran solos al reiniciarlo si
       se ha perdido su referencia: se quedaron seis rodillos colgados, unos
       encima de otros, y salían dos símbolos a la vez. Por eso se borran en
       `onResourceStop` y al quitar cada máquina, siempre.
   ══════════════════════════════════════════════════════════════════════════ ]]

Maquinas = {}

local rodillos = {}      -- [puntoId] = { ents = {e,e,e}, angulo = {a,a,a}, modelo, giro }

local POS_X = { -0.115, 0.005, 0.125 }
local POS_Y, POS_Z = 0.047, 0.906
local PASO = 22.5

--[[ Qué símbolo del juego enseña cada casilla. Los nombres de la izquierda
     son los ids de `Config.Tragaperras.simbolos`; el dibujo real es:

         siete     el 7                     naranja   la sandía
         diamante  el emblema de la máquina limon     la ciruela
         campana   la campana               cereza    las cerezas
         herradura la figura del tema (estrella ninja, rayo, botella…) ]]
local TIRA = {
    [0] = 'siete', 'limon', 'cereza', 'naranja', 'herradura', 'diamante', 'cereza', 'campana',
    'siete', 'limon', 'naranja', 'herradura', 'limon', 'campana', 'cereza', 'herradura',
}

local CASILLAS = {}      -- [simbolo] = { casilla, casilla… }
for k = 0, 15 do
    local s = TIRA[k]
    CASILLAS[s] = CASILLAS[s] or {}
    table.insert(CASILLAS[s], k)
end

-- ── Colocar y girar un rodillo ────────────────────────────────────────────

--- Gira el rodillo `grados` alrededor de su eje, con el rumbo de la máquina.
local function Orientar(ent, rumbo, grados)
    local th, hh = math.rad(grados) / 2, math.rad(rumbo) / 2
    local cz, sz, cx, sx = math.cos(hh), math.sin(hh), math.cos(th), math.sin(th)
    SetEntityQuaternion(ent, cz * sx, sz * sx, cx * sz, cz * cx)
end

local function Borrar(id)
    local r = rodillos[id]
    if not r then return end
    for _, e in ipairs(r.ents) do
        if DoesEntityExist(e) then DeleteEntity(e) end
    end
    rodillos[id] = nil
end

--- Pone los tres rodillos en la máquina `maquina` (la entidad).
function Maquinas.Poner(punto, tipo, maquina)
    Borrar(punto.id)
    if not tipo or tipo.juego ~= 'tragaperras' or not tipo.modelo then return end
    if not maquina or not DoesEntityExist(maquina) then return end

    local hash = joaat(tipo.modelo .. '_reels')
    if not IsModelInCdimage(hash) or not pcall(lib.requestModel, hash, 8000) then return end

    local rumbo = GetEntityHeading(maquina)
    local r = { ents = {}, angulo = {}, rumbo = rumbo, maquina = maquina }
    for i = 1, 3 do
        local pos = GetOffsetFromEntityInWorldCoords(maquina, POS_X[i], POS_Y, POS_Z)
        local e = CreateObject(hash, pos.x, pos.y, pos.z, false, false, false)
        SetEntityCollision(e, false, false)
        FreezeEntityPosition(e, true)
        -- De salida, una casilla cualquiera: tres sietes en todas las máquinas
        -- de la sala a la vez se ve de mentira.
        local a = math.random(0, 15) * PASO
        Orientar(e, rumbo, a)
        r.ents[i], r.angulo[i] = e, a
    end
    SetModelAsNoLongerNeeded(hash)
    rodillos[punto.id] = r
end

function Maquinas.Quitar(id)
    Borrar(id)
end

--[[ ── El giro ───────────────────────────────────────────────────────────

     Cada rodillo da unas vueltas enteras y se para en su casilla con un
     frenazo suave y un pequeño rebote, uno detrás de otro de izquierda a
     derecha: igual que la pantalla, con los mismos tiempos (`duracion`). ]]

local function Frenar(t)
    -- Sale disparado y frena al final; el 1,7 da un rebote de un par de grados.
    local s = 1.70158
    t = t - 1
    return t * t * ((s + 1) * t + s) + 1
end

function Maquinas.Girar(id, simbolos, duracion)
    local r = rodillos[id]
    if not r or type(simbolos) ~= 'table' then return end
    duracion = tonumber(duracion) or 2200

    local giro = {}
    r.giro = giro
    local inicio = GetGameTimer()
    local desde, hasta, fin = {}, {}, {}

    for i = 1, 3 do
        local lista = CASILLAS[simbolos[i]] or CASILLAS.cereza
        local casilla = lista[math.random(#lista)]
        desde[i] = r.angulo[i] % 360.0
        -- Hacia delante siempre, con 3 vueltas más una por rodillo: el de la
        -- derecha es el que más gira porque es el último en pararse.
        local destino = casilla * PASO
        local falta = (destino - desde[i]) % 360.0
        hasta[i] = desde[i] + falta + 360.0 * (2 + i)
        fin[i] = duracion * (0.55 + (i - 1) * 0.225)
    end

    CreateThread(function()
        while r.giro == giro do
            local t = GetGameTimer() - inicio
            local quedan = false
            for i = 1, 3 do
                local e = r.ents[i]
                if DoesEntityExist(e) then
                    local x = math.min(1.0, t / fin[i])
                    local a = desde[i] + (hasta[i] - desde[i]) * Frenar(x)
                    Orientar(e, r.rumbo, a)
                    r.angulo[i] = a
                    if x < 1.0 then quedan = true end
                end
            end
            if not quedan then break end
            Wait(0)
        end
        if r.giro == giro then r.giro = nil end
    end)
end

--[[ ── El giro que llega del servidor ────────────────────────────────────

     A todos los que están cerca: la palanca de la máquina (si se ha tirado
     de ella) y los rodillos. Al que juega, además, su gesto: pulsar el botón
     o tirar de la palanca, y al pararse celebrar o lamentarse.

     Los rodillos arrancan cuando la mano llega al botón o la palanca toca
     abajo, no al pulsar la tecla: si no, giraban antes de que se tocara nada. ]]
local DICT_SLOTS = 'anim_casino_a@amb@casino@games@slots@male'
local ARRANQUE = { boton = 650, palanca = 1100 }

RegisterNetEvent('origen_casino:giro', function(id, simbolos, duracion, gana, gesto)
    id = tonumber(id)
    duracion = tonumber(duracion) or 2200
    gesto = type(gesto) == 'string' and gesto or 'press_spin_a'
    local palanca = gesto:find('pull_spin') ~= nil

    local r = rodillos[id]
    if palanca and r and DoesEntityExist(r.maquina) then
        pcall(lib.requestAnimDict, DICT_SLOTS, 3000)
        PlayEntityAnim(r.maquina, gesto .. '_slotmachine', DICT_SLOTS, 1000.0, false, false, false, 0.0, 0)
    end

    local mia = C.sesion and C.sesion.punto == id
    if mia then Gesto(palanca and 'palanca' or 'boton', gesto) end

    SetTimeout(palanca and ARRANQUE.palanca or ARRANQUE.boton, function()
        Maquinas.Girar(id, simbolos, duracion)
        if mia then
            SetTimeout(duracion + 200, function()
                if C.sesion and C.sesion.punto == id then Gesto(gana and 'gana' or 'pierde') end
            end)
        end
    end)
end)

--[[ ══ JUGAR CON LAS TECLAS, COMO EN GTA ONLINE ══════════════════════════

     La tragaperras no lleva botonera en pantalla: se juega con el teclado y
     las teclas salen en la barra de abajo de la casa (las pone
     Tragaperras.vue en BarraMesa.vue: el `instructional_buttons` de GTA no
     pega con el resto del servidor). El ratón queda libre y los botones físicos de la
     máquina, a la vista.

         Espacio   pulsar SPIN            E   apostar uno más
         S         tirar de la palanca    R   apuesta máxima
         Retroceso / Esc   levantarse
   ══════════════════════════════════════════════════════════════════════════ ]]

local TECLA = {
    boton = 22,         -- INPUT_JUMP (Espacio)
    palanca = 33,       -- INPUT_MOVE_DOWN_ONLY (S)
    uno = 38,           -- INPUT_PICKUP (E)
    maximo = 45,        -- INPUT_RELOAD (R)
    salir = 194,        -- INPUT_FRONTEND_RRIGHT (Retroceso)
    esc = 200,          -- INPUT_FRONTEND_PAUSE_ALTERNATE (Esc)
}

local ocupadoHasta = 0

local function Accion(nombre, datos)
    return lib.callback.await('origen_casino:accion', false, nombre, datos) or { ok = false }
end

local function Tirar(palanca)
    if GetGameTimer() < ocupadoHasta then return end
    local est = C.estado or {}
    local apuesta = tonumber(est.apuesta) or 0
    if apuesta <= 0 then return end
    if (tonumber(est.fichas) or 0) < apuesta then
        C.Aviso(Config.General.nombre, 'No te quedan fichas para esa apuesta. Se compran en la caja.', 'error')
        return
    end
    local lista = palanca and { 'pull_spin_a', 'pull_spin_b' } or { 'press_spin_a', 'press_spin_b' }
    ocupadoHasta = GetGameTimer() + (tonumber(est.duracion) or 2200) + 1800
    local r = Accion('girar', { apuesta = apuesta, gesto = lista[math.random(#lista)] })
    if not r.ok then
        ocupadoHasta = 0
        if r.mensaje then C.Aviso(Config.General.nombre, r.mensaje, 'error') end
    end
end

local function Apostar(maximo)
    if GetGameTimer() < ocupadoHasta then return end
    local est = C.estado or {}
    local lista = est.fichasApuesta or {}
    if #lista == 0 then return end
    local actual = tonumber(est.apuesta) or lista[1]
    local nueva = lista[#lista]
    if not maximo then
        -- Uno más; pasado el máximo vuelve al mínimo, como el BET ONE de la máquina.
        nueva = lista[1]
        for i, v in ipairs(lista) do
            if v == actual then nueva = lista[i + 1] or lista[1] break end
        end
    end
    if nueva == actual then return end
    Gesto(maximo and 'apuestaMax' or 'apuestaUno')
    ocupadoHasta = GetGameTimer() + 700
    local r = Accion('apuesta', { apuesta = nueva })
    if not r.ok and r.mensaje then C.Aviso(Config.General.nombre, r.mensaje, 'error') end
end

CreateThread(function()
    while true do
        local espera = 400
        local ses = C.sesion
        if ses and ses.juego == 'tragaperras' and C.pantalla == 'juego' then
            espera = 0
            for _, t in pairs(TECLA) do DisableControlAction(0, t, true) end
            DisableControlAction(0, 199, true)       -- el menú de pausa
            DisableControlAction(0, 32, true) DisableControlAction(0, 34, true) DisableControlAction(0, 35, true)


            if IsDisabledControlJustPressed(0, TECLA.boton) then
                CreateThread(function() Tirar(false) end)
            elseif IsDisabledControlJustPressed(0, TECLA.palanca) then
                CreateThread(function() Tirar(true) end)
            elseif IsDisabledControlJustPressed(0, TECLA.uno) then
                CreateThread(function() Apostar(false) end)
            elseif IsDisabledControlJustPressed(0, TECLA.maximo) then
                CreateThread(function() Apostar(true) end)
            elseif IsDisabledControlJustPressed(0, TECLA.salir) or IsDisabledControlJustPressed(0, TECLA.esc) then
                CreateThread(function()
                    Levantarse()
                    CerrarJuego()
                end)
            end
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for id in pairs(rodillos) do Borrar(id) end
end)
