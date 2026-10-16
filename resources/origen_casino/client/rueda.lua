--[[ ══════════════════════════════════════════════════════════════════════════
     LA RUEDA DE LA SUERTE EN EL MUNDO

     Como en GTA Online: la rueda de premios encima de su base, el personaje
     se acerca, levanta el brazo y tira de ella hacia abajo; la rueda da sus
     vueltas, frena y se para en la casilla que ha sacado el servidor, y el
     personaje lo celebra. Lo ve todo el que esté cerca.

     ── Lo medido en el juego (24/09) ───────────────────────────────────────

     · La base (`vw_prop_vw_luckywheel_01a`) es solo el soporte con la aguja.
       La rueda de premios es otro prop, `vw_prop_vw_luckywheel_02a`, que va
       1,5 m por encima del origen de la base, con su mismo rumbo: ahí el aro
       blanco de la base se ve igual arriba que abajo (a 1,6 quedaba alta).
     · La cara buena mira hacia DETRÁS del rumbo del punto: el jugador se pone
       por ese lado.
     · La rueda gira sobre su eje con CUATERNIÓN: con SetEntityRotation el
       motor se come el giro en ese eje y no se mueve.
     · 20 casillas de 18°. Girando la rueda +R grados, se mueve en el sentido
       de las agujas del reloj visto de frente; la casilla `i` (contando desde
       la de arriba en reposo, en ese mismo sentido) queda bajo la aguja con
       R = −18·i.
     · Las animaciones (`anim_casino_a@amb@casino@games@lucky7wheel@male` y
       `@female`) van en una escena con el origen y el giro de la BASE: así
       el personaje se coloca solo a la izquierda de la rueda, con la mano en
       el borde.
   ══════════════════════════════════════════════════════════════════════════ ]]

RuedaMundo = {}

local ruedas = {}       -- [puntoId] = { punto, base, rueda, angulo, giro }

local MODELO = 'vw_prop_vw_luckywheel_02a'
local ALTO = 1.5
local SECTOR = 18.0

-- ── La rueda de premios ───────────────────────────────────────────────────

local function Orientar(e, rumbo, angulo)
    local hr, rr = math.rad(rumbo) / 2, math.rad(angulo) / 2
    local cz, sz, cr, sr = math.cos(hr), math.sin(hr), math.cos(rr), math.sin(rr)
    SetEntityQuaternion(e, -sz * sr, cz * sr, cr * sz, cz * cr)
end

function RuedaMundo.Poner(punto, tipo, base)
    RuedaMundo.Quitar(punto.id)
    if not base or not DoesEntityExist(base) then return end
    local hash = joaat(MODELO)
    if not pcall(lib.requestModel, hash, 5000) then return end
    local o = GetEntityCoords(base)
    local e = CreateObjectNoOffset(hash, o.x, o.y, o.z + ALTO, false, false, false)
    SetEntityCollision(e, false, false)
    FreezeEntityPosition(e, true)
    -- El rumbo, el del punto: el de un mueble recién creado dentro de un
    -- interior se leía a 0 (visto en Jurassic Jackpot, 24/09). Solo un mueble
    -- del mapa («sin poner el mueble») manda con el suyo.
    local rumbo = punto.sinProp and GetEntityHeading(base) or (punto.h + 0.0)
    local r = { punto = punto, base = base, rueda = e, rumbo = rumbo, angulo = 0.0 }
    Orientar(e, r.rumbo, 0.0)
    SetModelAsNoLongerNeeded(hash)
    ruedas[punto.id] = r
end

function RuedaMundo.Quitar(id)
    local r = ruedas[id]
    if not r then return end
    ruedas[id] = nil
    r.giro = nil
    if DoesEntityExist(r.rueda) then DeleteEntity(r.rueda) end
end

--[[ Da unas vueltas y frena hasta dejar `casilla` bajo la aguja. Gira hacia
     atrás (a izquierdas), que es hacia donde la lleva el tirón de la mano. ]]
local function Girar(r, casilla, duracion)
    local giro = {}
    r.giro = giro
    local desde = r.angulo
    local destino = -casilla * SECTOR
    local falta = (desde - destino) % 360.0
    local hasta = desde - falta - 360.0 * 4
    local t0 = GetGameTimer()
    CreateThread(function()
        while r.giro == giro and DoesEntityExist(r.rueda) do
            local t = math.min(1.0, (GetGameTimer() - t0) / duracion)
            -- Arranca de golpe y frena poco a poco, hasta pararse en seco.
            local s = 1.0 - (1.0 - t) ^ 3
            r.angulo = desde + (hasta - desde) * s
            Orientar(r.rueda, r.rumbo, r.angulo)
            if t >= 1.0 then break end
            Wait(0)
        end
        r.angulo = r.angulo % 360.0
    end)
end

-- ── El personaje ──────────────────────────────────────────────────────────

local actual = nil      -- { r, dict, escena, cam }

local function Dict()
    return IsPedMale(cache.ped) and 'anim_casino_a@amb@casino@games@lucky7wheel@male'
        or 'anim_casino_a@amb@casino@games@lucky7wheel@female'
end

local function Escena(anim, bucle)
    local a = actual
    if not a then return end
    local o = GetEntityCoords(a.r.base)
    local esc = NetworkCreateSynchronisedScene(o.x, o.y, o.z, 0.0, 0.0, a.r.rumbo, 2, not bucle, bucle, 1.0, 0.0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, esc, a.dict, anim, 4.0, -4.0, 13, 16, 1000.0, 0)
    NetworkStartSynchronisedScene(esc)
    a.escena = esc
    return esc, math.floor(GetAnimDuration(a.dict, anim) * 1000)
end

--- Una animación y, al acabar, la siguiente en bucle (si sigue siendo la misma).
local function Encadenar(anim, siguiente)
    local esc, dura = Escena(anim, false)
    if not esc then return 0 end
    SetTimeout(math.max(0, dura - 60), function()
        if actual and actual.escena == esc and siguiente then Escena(siguiente, true) end
    end)
    return dura
end

local function Camara(r)
    -- Detrás del jugador y un poco a la derecha, con la rueda entera en el cuadro.
    local rad = math.rad(r.rumbo)
    local o = GetEntityCoords(r.base)
    local fx, fy = -math.sin(rad), math.cos(rad)          -- hacia donde mira el punto
    local dx, dy = math.cos(rad), math.sin(rad)           -- su derecha
    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', o.x - fx * 3.6 + dx * 0.9, o.y - fy * 3.6 + dy * 0.9,
        o.z + 1.9, 0.0, 0.0, 0.0, 50.0, false, 0)
    PointCamAtCoord(cam, o.x, o.y, o.z + 1.55)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 800, true, false)
    return cam
end

local function Soltar()
    local a = actual
    actual = nil
    if not a then return end
    if a.cam then
        RenderScriptCams(false, true, 600, true, false)
        DestroyCam(a.cam, false)
    end
    if a.escena then NetworkStopSynchronisedScene(a.escena) end
    ClearPedTasks(cache.ped)
end

-- Al sentarse en una rueda (pulsar E delante): acercarse y levantar el brazo.
RegisterNetEvent('origen_casino:sentado', function(datos)
    if type(datos) ~= 'table' or datos.juego ~= 'rueda' then return end
    local r = ruedas[datos.punto]
    if not r then return end
    Soltar()
    actual = { r = r, dict = Dict() }
    pcall(lib.requestAnimDict, actual.dict, 5000)
    actual.cam = Camara(r)
    local dura = Encadenar('enter_right_to_baseidle', nil)
    SetTimeout(math.max(0, dura - 60), function()
        if actual and actual.r == r then Encadenar('enter_to_armraisedidle', 'armraisedidle') end
    end)
end)

RegisterNetEvent('origen_casino:levantado', function()
    if actual then Soltar() end
end)

--[[ El servidor ha tirado. La rueda gira para todos; el que ha tirado da el
     tirón, se queda mirando cómo gira y, al pararse, lo celebra y se va. ]]
RegisterNetEvent('origen_casino:ruedaGiro', function(id, casilla, duracion, tipo, quien)
    local r = ruedas[tonumber(id)]
    if not r then return end
    duracion = tonumber(duracion) or 9000
    local mio = quien == GetPlayerServerId(PlayerId()) and actual and actual.r == r

    if not mio then
        Girar(r, tonumber(casilla) or 0, duracion)
        return
    end

    -- El tirón: la rueda arranca cuando la mano ya la ha bajado.
    local dura = Encadenar('armraisedidle_to_spinningidle_high', 'spinningidle_high')
    SetTimeout(math.floor(dura * 0.45), function()
        Girar(r, tonumber(casilla) or 0, duracion)
    end)
    SetTimeout(math.floor(dura * 0.45) + duracion + 300, function()
        if not actual or actual.r ~= r then return end
        local celebrar = (tipo == 'vehiculo' and 'win_huge') or (tipo == 'nada' and nil)
            or ((tipo == 'dinero' or tipo == 'fichas') and 'win_big') or 'win'
        local espera = celebrar and Encadenar(celebrar, nil) or 0
        SetTimeout(espera, function()
            if not actual or actual.r ~= r then return end
            local salir = Encadenar('exit_to_standing', nil)
            SetTimeout(salir, function()
                if actual and actual.r == r then
                    Soltar()
                    Levantarse()
                    CerrarJuego()
                end
            end)
        end)
    end)
end)

-- ── Las teclas, como en GTA Online ────────────────────────────────────────

local TIRAR, TIRAR2, SALIR, ESC = 22, 33, 194, 200     -- Espacio, S, Retroceso, Esc
local tirado = 0

CreateThread(function()
    while true do
        local espera = 400
        if actual and C.pantalla == 'juego' then
            espera = 0
            DisableControlAction(0, TIRAR, true) DisableControlAction(0, TIRAR2, true)
            DisableControlAction(0, SALIR, true) DisableControlAction(0, ESC, true)
            DisableControlAction(0, 199, true)
            if (IsDisabledControlJustPressed(0, TIRAR) or IsDisabledControlJustPressed(0, TIRAR2))
                and GetGameTimer() > tirado then
                tirado = GetGameTimer() + 3000
                CreateThread(function()
                    local res = lib.callback.await('origen_casino:accion', false, 'girar', {})
                    if not res or not res.ok then
                        tirado = 0
                        if res and res.mensaje then C.Aviso(Config.General.nombre, res.mensaje, 'inform') end
                    else
                        tirado = GetGameTimer() + 60000
                    end
                end)
            elseif IsDisabledControlJustPressed(0, SALIR) or IsDisabledControlJustPressed(0, ESC) then
                if GetGameTimer() > tirado then
                    CreateThread(function()
                        Soltar()
                        Levantarse()
                        CerrarJuego()
                    end)
                end
            end
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    Soltar()
    for id in pairs(ruedas) do RuedaMundo.Quitar(id) end
end)
