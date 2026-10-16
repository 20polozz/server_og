--[[ PESCABICHOS · lo que hace falta del juego.

     1. LA CAMARA (realidad aumentada). Con la camara del telefono abierta
        (client/modules/camera.lua), la interfaz pide que le digamos donde caen
        en SU pantalla los bichos que tiene cerca. Cada pocos fotogramas se
        proyecta cada uno con GetScreenCoordFromWorldCoord —la camara que se
        esta dibujando es la del telefono— y se manda a la interfaz:
          { u = uid, x, y (0..1 de la pantalla entera), d = metros,
            v = si cae delante, r = hacia donde queda (grados, + izquierda),
            t = si hay algo en medio (pared, coche) }
        La interfaz lo pasa a su lienzo (el visor recorta el centro de la
        pantalla, ver utils/vistaJuego.ts) y dibuja el bicho encima.

        El suelo de cada bicho lo pone el juego, no el servidor: el servidor
        solo sabe la altura a la que estaba el jugador al salir el bicho.

     2. SEGUIR un sitio. Un bicho fuera de la carretera no tiene ruta de GPS
        (el juego solo traza por carretera), asi que ademas del punto en el
        mapa se planta un haz de luz en el sitio, que se ve de lejos, y se
        quita al llegar. ]]

local AR = { activo = false, lista = {}, suelos = {}, tapados = {}, tanda = 0 }

--- Cada cuanto se manda la proyeccion a la interfaz (ms). Mas a menudo no se nota y cuesta.
local CADA = 66
--- Hasta donde se proyecta: mas lejos no se ve nada en el visor.
local LEJOS = 160.0
--- Cada cuanto se mira si hay algo en medio de cada bicho (ms).
local CADA_RAYO = 300

--[[ El suelo de cada bicho. Se busca desde un poco por encima de quien mira
     (o del sitio, lo que este mas alto), no desde 60 m: desde tan arriba la
     sonda choca con copas de arboles y tejados y el bicho acababa en el aire. ]]
local function Suelo(b)
    local s = AR.suelos[b.u]
    if s then return s end
    local yo = GetEntityCoords(PlayerPedId())
    local z = math.max((tonumber(b.z) or 0.0) + 0.0, yo.z) + 4.0
    local hay, zs = GetGroundZFor_3dCoord(b.x + 0.0, b.y + 0.0, z, false)
    local agua, za = GetWaterHeightNoWaves(b.x + 0.0, b.y + 0.0, z)
    if agua and (not hay or za > zs) then
        AR.suelos[b.u] = za
        return za
    end
    if hay then
        AR.suelos[b.u] = zs
        return zs
    end
    return z
end

--- Rumbo del juego (grados) desde a hasta b, en el plano.
local function Rumbo(ax, ay, bx, by)
    return math.deg(math.atan(-(bx - ax), by - ay))
end

local function Normal(a)
    return (a + 180.0) % 360.0 - 180.0
end

local function Bucle(tanda)
    local rayoSiguiente, indiceRayo = 0, 0
    while AR.activo and AR.tanda == tanda do
        --- Con el telefono cerrado no hay visor: se para solo.
        if not Phone.open then AR.activo = false break end
        local cam = GetFinalRenderedCamCoord()
        local rot = GetFinalRenderedCamRot(2)
        local ped = PlayerPedId()
        local yo = GetEntityCoords(ped)
        local ahora = GetGameTimer()

        --- Un rayo por vuelta, por turnos: ver si hay algo entre la lente y el bicho.
        if ahora >= rayoSiguiente and #AR.lista > 0 then
            rayoSiguiente = ahora + math.floor(CADA_RAYO / math.max(1, #AR.lista))
            indiceRayo = indiceRayo % #AR.lista + 1
            local b = AR.lista[indiceRayo]
            if b then
                local z = Suelo(b) + 0.6
                local rayo = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z, b.x + 0.0, b.y + 0.0, z, 1 + 16, ped, 4)
                local _, golpe = GetShapeTestResult(rayo)
                AR.tapados[b.u] = golpe == 1
            end
        end

        local salida = {}
        for _, b in ipairs(AR.lista) do
            local dx, dy = b.x - yo.x, b.y - yo.y
            local d = math.sqrt(dx * dx + dy * dy)
            if d <= LEJOS then
                local z = Suelo(b)
                --- Se apunta al centro del bicho, un poco por encima del suelo.
                local dentro, sx, sy = GetScreenCoordFromWorldCoord(b.x + 0.0, b.y + 0.0, z + 0.55)
                salida[#salida + 1] = {
                    u = b.u, x = sx, y = sy, d = math.floor(d * 10) / 10, v = dentro == true or dentro == 1,
                    r = math.floor(Normal(Rumbo(cam.x, cam.y, b.x, b.y) - rot.z)),
                    t = AR.tapados[b.u] == true,
                    --- Por debajo o por encima de la lente (para la flecha cuando no se ve).
                    b = (z + 0.55) < cam.z - 0.5,
                }
            end
        end

        Nui.Send('pb:ar', { l = salida, h = math.floor(rot.z) })
        Wait(CADA)
    end
end

--[[ Lo pide la interfaz: { activo = true|false, bichos = { {u, x, y, z} } }.
     Con la lista nueva se rehace sin cortar el bucle. ]]
Nui.On('pbAR', function(p)
    p = type(p) == 'table' and p or {}
    if p.activo == false then
        AR.activo = false
        AR.lista = {}
        return true
    end

    local lista = {}
    for _, b in ipairs(type(p.bichos) == 'table' and p.bichos or {}) do
        if tonumber(b.x) and tonumber(b.y) and b.u then
            lista[#lista + 1] = { u = tostring(b.u), x = tonumber(b.x), y = tonumber(b.y), z = tonumber(b.z) or GetEntityCoords(PlayerPedId()).z }
        end
        if #lista >= 20 then break end
    end
    AR.lista = lista

    if not AR.activo then
        AR.activo = true
        AR.tanda = AR.tanda + 1
        AR.tapados = {}
        local tanda = AR.tanda
        CreateThread(function() Bucle(tanda) end)
    end
    return true
end)

-- ---------------------------------------------------------------------------
--  Seguir un sitio: punto en el mapa y un haz de luz que se ve de lejos
-- ---------------------------------------------------------------------------

local Seguir = { tanda = 0 }

--- Al llegar a esta distancia (m) el haz se apaga solo.
local LLEGADO = 9.0
--- Y si no se llega, a los diez minutos.
local DURA = 10 * 60 * 1000

local function QuitarPunto(x, y)
    local wp = GetFirstBlipInfoId(8)
    if DoesBlipExist(wp) then
        local c = GetBlipInfoIdCoord(wp)
        if math.abs(c.x - x) < 2.0 and math.abs(c.y - y) < 2.0 then DeleteWaypoint() end
    end
end

Nui.On('pbSeguir', function(p)
    p = type(p) == 'table' and p or {}
    Seguir.tanda = Seguir.tanda + 1
    if not tonumber(p.x) or not tonumber(p.y) then
        if Seguir.x then QuitarPunto(Seguir.x, Seguir.y) end
        Seguir.x, Seguir.y = nil, nil
        return true
    end

    local x, y = tonumber(p.x) + 0.0, tonumber(p.y) + 0.0
    local z = tonumber(p.z) or GetEntityCoords(PlayerPedId()).z
    local color = type(p.color) == 'table' and p.color or { 216, 27, 85 }
    Seguir.x, Seguir.y = x, y

    -- El punto en el mapa, con el mismo camino que el resto del telefono (MarcarRuta).
    SetNewWaypoint(x, y)
    if GetResourceState('origen_inventory') == 'started' then
        pcall(function() exports['origen_inventory']:MarcarRuta(x, y, p.nombre or 'Pescabichos', nil) end)
    end

    local tanda = Seguir.tanda
    CreateThread(function()
        local hasta = GetGameTimer() + DURA
        local suelo = nil
        while Seguir.tanda == tanda and GetGameTimer() < hasta do
            local yo = GetEntityCoords(PlayerPedId())
            local dx, dy = x - yo.x, y - yo.y
            local d = math.sqrt(dx * dx + dy * dy)
            if d <= LLEGADO then
                Nui.Send('pb:llegado', { x = x, y = y })
                QuitarPunto(x, y)
                break
            end

            if not suelo then
                local hay, zs = GetGroundZFor_3dCoord(x, y, z + 60.0, false)
                local agua, za = GetWaterHeightNoWaves(x, y, z + 60.0)
                if agua and (not hay or za > zs) then suelo = za elseif hay then suelo = zs end
            end
            local zb = suelo or z

            -- El haz: un cilindro alto y fino, y un aro que late en el suelo.
            local late = 0.75 + 0.25 * math.sin(GetGameTimer() / 260.0)
            --[[ Medido en el juego (03/10): a 110 m un cilindro de 1 m era una raya
                 que casi no se veia. Ahora dos: uno ancho y suave y otro estrecho y
                 vivo dentro, y una luz en el suelo para que de noche se vea el sitio. ]]
            DrawMarker(1, x, y, zb - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 120.0, color[1], color[2], color[3], 55, false, false, 2, false, nil, nil, false)
            DrawMarker(1, x, y, zb - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 120.0, color[1], color[2], color[3], 150, false, false, 2, false, nil, nil, false)
            DrawMarker(25, x, y, zb + 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.6 * late, 3.6 * late, 1.0, color[1], color[2], color[3], 190, false, false, 2, false, nil, nil, false)
            if d < 250.0 then DrawLightWithRange(x, y, zb + 1.5, color[1], color[2], color[3], 8.0, 4.0) end
            Wait(0)
        end
        if Seguir.tanda == tanda then Seguir.x, Seguir.y = nil, nil end
    end)
    return true
end)
