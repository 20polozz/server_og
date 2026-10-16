--[[ La cámara del taller.

     Una órbita alrededor del coche: ángulo (0 = de frente), altura en grados
     y distancia. Lo que manda la pantalla —arrastrar, rueda, pinchar una
     zona— cambia el OBJETIVO, y cada fotograma la cámara se acerca un poco a
     él. Por eso nunca salta: vuela.

     El arrastre llega de la pantalla y no del ratón del juego a propósito:
     así la NUI no necesita KeepInput y ninguna tecla se escapa al juego
     mientras se tunea. ]]

Camara = {}

local C = Config.Camara
local cam = nil
local veh = nil
local activa = false

-- Lo que hay ahora y a lo que se va.
local ahora = { angulo = 0.0, altura = C.altura, dist = 5.0, centro = vector3(0, 0, 0), fov = C.fov }
local meta = { angulo = 0.0, altura = C.altura, dist = 5.0, centro = nil, fov = C.fov }

local radio = 2.5
local interior = false
local girarSolo = false
local zonaFija = nil      -- punto de la zona en coordenadas del coche

local function Radio(v)
    local min, max = GetModelDimensions(GetEntityModel(v))
    return #(max - min) / 2.0
end

--- El centro de la caja del coche en el mundo (no su origen, que en muchos
--- modelos está en el suelo o desplazado).
local function Centro(v)
    local min, max = GetModelDimensions(GetEntityModel(v))
    local c = (min + max) / 2.0
    return GetOffsetFromEntityInWorldCoords(v, c.x, c.y, c.z)
end

local function Suave(a, b, t)
    return a + (b - a) * t
end

-- El ángulo por el camino corto: de 350 a 10 son 20 grados, no 340.
local function SuaveAngulo(a, b, t)
    local d = ((b - a + 180.0) % 360.0) - 180.0
    return a + d * t
end

local function Posicion(centro, angulo, altura, dist)
    local h = math.rad(GetEntityHeading(veh) + angulo)
    local p = math.rad(altura)
    local x = -math.sin(h) * math.cos(p)
    local y = math.cos(h) * math.cos(p)
    local z = math.sin(p)
    return vector3(centro.x + x * dist, centro.y + y * dist, centro.z + z * dist)
end

local function Bucle()
    CreateThread(function()
        local ultimo = GetGameTimer()
        while activa do
            local t = GetGameTimer()
            local dt = (t - ultimo) / 1000.0
            ultimo = t

            if not DoesEntityExist(veh) then
                Camara.Parar()
                break
            end

            if girarSolo and not interior then
                meta.angulo = meta.angulo + C.girarSolo * dt
            end

            local s = C.suavizado
            ahora.angulo = SuaveAngulo(ahora.angulo, meta.angulo, s)
            ahora.altura = Suave(ahora.altura, meta.altura, s)
            ahora.dist = Suave(ahora.dist, meta.dist, s)
            ahora.fov = Suave(ahora.fov, meta.fov, s)

            local objetivo
            if zonaFija then
                objetivo = GetOffsetFromEntityInWorldCoords(veh, zonaFija.x, zonaFija.y, zonaFija.z)
            else
                objetivo = Centro(veh)
            end
            ahora.centro = vector3(
                Suave(ahora.centro.x, objetivo.x, s),
                Suave(ahora.centro.y, objetivo.y, s),
                Suave(ahora.centro.z, objetivo.z, s)
            )

            if interior then
                -- Dentro: la cámara va en el asiento del copiloto y el ángulo
                -- mueve la MIRADA, no la posición.
                local asiento = GetEntityBoneIndexByName(veh, 'seat_pside_f')
                local base = asiento ~= -1 and GetWorldPositionOfEntityBone(veh, asiento)
                    or GetOffsetFromEntityInWorldCoords(veh, 0.4, 0.0, 0.5)
                local pos = base + vector3(0, 0, 0.62)
                SetCamCoord(cam, pos.x, pos.y, pos.z)
                -- Ángulo 0 = mirando al frente, igual que fuera es «cámara delante».
                local mira = Posicion(pos, ahora.angulo, ahora.altura, 1.0)
                PointCamAtCoord(cam, mira.x, mira.y, mira.z)
            else
                local pos = Posicion(ahora.centro, ahora.angulo, ahora.altura, ahora.dist)
                -- Se corren cámara y mirada juntas hacia la derecha de la
                -- imagen: el coche queda en el hueco que deja la columna.
                local mira = ahora.centro
                local frente = ahora.centro - pos
                local derecha = vector3(frente.y, -frente.x, 0.0)
                local largo = #derecha
                if largo > 0.001 then
                    local corrido = derecha / largo * (ahora.dist * (C.desplazar or 0.0))
                    pos = pos + corrido
                    mira = mira + corrido
                end
                -- Que no se meta bajo el suelo al bajar la cámara.
                local ok, suelo = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 2.0, false)
                if ok and pos.z < suelo + 0.25 then pos = vector3(pos.x, pos.y, suelo + 0.25) end
                SetCamCoord(cam, pos.x, pos.y, pos.z)
                PointCamAtCoord(cam, mira.x, mira.y, mira.z)
            end
            SetCamFov(cam, ahora.fov)

            -- Nada del jugador se mueve mientras tanto.
            DisableAllControlActions(0)
            EnableControlAction(0, 245, true) -- chat
            EnableControlAction(0, 249, true) -- hablar (pma-voice)
            Wait(0)
        end
    end)
end

function Camara.Empezar(vehiculo)
    veh = vehiculo
    radio = Radio(veh)
    interior, girarSolo, zonaFija = false, false, nil

    local d = radio * C.distancia
    meta = { angulo = 35.0, altura = C.altura, dist = d, centro = nil, fov = C.fov }
    -- Se arranca un poco más lejos y más de lado: la cámara «llega» al coche.
    ahora = { angulo = 70.0, altura = C.altura + 10.0, dist = d * 1.7, centro = Centro(veh), fov = C.fov + 8.0 }

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, ahora.fov)
    local pos = Posicion(ahora.centro, ahora.angulo, ahora.altura, ahora.dist)
    SetCamCoord(cam, pos.x, pos.y, pos.z)
    PointCamAtCoord(cam, ahora.centro.x, ahora.centro.y, ahora.centro.z)
    RenderScriptCams(true, true, 900, true, false)

    activa = true
    Bucle()
end

function Camara.Parar()
    if not activa then return end
    activa = false
    RenderScriptCams(false, true, 700, true, false)
    if cam then
        DestroyCam(cam, false)
        cam = nil
    end
end

function Camara.Activa() return activa end

--- Arrastre de la pantalla, en píxeles.
function Camara.Arrastrar(dx, dy)
    if not activa then return end
    girarSolo = false
    meta.angulo = meta.angulo - (tonumber(dx) or 0) * C.sensibilidad
    local lim = interior and 60.0 or 80.0
    meta.altura = math.max(interior and -60.0 or -4.0, math.min(lim, meta.altura + (tonumber(dy) or 0) * C.sensibilidad))
end

--- Rueda del ratón: >0 aleja, <0 acerca.
function Camara.Zoom(pasos)
    if not activa then return end
    if interior then
        meta.fov = math.max(30.0, math.min(75.0, meta.fov + (tonumber(pasos) or 0) * 3.0))
        return
    end
    local min, max = radio * C.distanciaMin, radio * C.distanciaMax
    meta.dist = math.max(min, math.min(max, meta.dist * (1.0 + (tonumber(pasos) or 0) * 0.08)))
end

--- Vuela a una zona del catálogo (o al coche entero con `nil`). `punto` es la
--- posición de la zona en coordenadas del coche.
function Camara.Zona(zona, punto)
    if not activa then return end
    girarSolo = false

    if not zona then
        interior, zonaFija = false, nil
        meta.dist, meta.altura, meta.fov = radio * C.distancia, C.altura, C.fov
        return
    end

    local cfg = zona.camara or {}
    if cfg.interior then
        interior, zonaFija = true, nil
        meta.angulo, meta.altura, meta.fov = 0.0, -14.0, 58.0
        return
    end

    interior = false
    zonaFija = punto
    meta.angulo = cfg.angulo or meta.angulo
    meta.altura = cfg.altura or meta.altura
    meta.dist = radio * (cfg.distancia or 1.0)
    meta.fov = C.fov
end

--- Vistas fijas de la barra de abajo.
local VISTAS = {
    frente = { angulo = 0, altura = 6 },
    tresCuartos = { angulo = 35, altura = 12 },
    lateral = { angulo = 90, altura = 4 },
    trasera = { angulo = 180, altura = 8 },
    cenital = { angulo = 20, altura = 72 },
}

function Camara.Vista(nombre)
    local v = VISTAS[nombre]
    if not activa or not v then return end
    interior, zonaFija, girarSolo = false, nil, false
    meta.angulo, meta.altura = v.angulo, v.altura
    meta.dist, meta.fov = radio * C.distancia, C.fov
end

function Camara.Exposicion(encender)
    girarSolo = encender == true
    if girarSolo then
        interior, zonaFija = false, nil
        meta.dist = radio * C.distancia * 1.1
    end
end

function Camara.Handle() return cam end
