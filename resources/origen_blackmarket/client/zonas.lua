--[[ ZONAS DE CAPTURA en el cliente (09/10). Ver server/zonas.lua.

     Aquí se hacen tres cosas:

       · saber si el jugador está dentro de la zona que toca, y decírselo al
         servidor (que lo vuelve a comprobar con sus propias coordenadas);
       · poner en el mapa dónde es la captura cuando el mercado tiene varias
         zonas y la de hoy no es donde está el mercado;
       · dejar al admin colocar una zona viéndola dibujada.

     Antes la zona era un lib.zones.sphere por mercado, creado al montarlo.
     Una esfera no sabe de alturas ni se puede cambiar de sitio sin rehacer
     el mercado entero, así que ahora es una cuenta a mano cada medio
     segundo: una distancia por mercado, que es lo mismo que hacía ox_lib. ]]

local EnMarcha  = {}   -- [marketId] = la zona de la captura en curso (la manda el servidor)
local Anunciada = {}   -- [marketId] = la que tocará en la próxima, si ya se ha dicho

local function dentroDe(c, z)
    local dx, dy, dz = c.x - z.x, c.y - z.y, c.z - z.z
    -- Puesta en el mapa del panel: un círculo visto desde arriba, sin altura.
    if z.plana then return dx * dx + dy * dy <= z.radio * z.radio end
    if dx * dx + dy * dy + dz * dz > z.radio * z.radio then return false end
    if z.altura and z.altura > 0 and math.abs(dz) > z.altura then return false end
    return true
end

--- La zona que cuenta ahora: la de la captura en marcha o, sin captura, la
--- de siempre (el centro y el radio del mercado).
local function vigente(marketId)
    local z = EnMarcha[marketId]
    if z then return z end
    local mCfg = Config.Markets[marketId]
    if not mCfg or not mCfg.Center then return nil end
    return {
        x = mCfg.Center.x, y = mCfg.Center.y, z = mCfg.Center.z,
        radio = mCfg.Radius or Config.Capture.CheckDistance or 100.0, altura = 0,
    }
end

--- Mira si se ha entrado o salido y avisa al servidor. Con `repetir`, si se
--- sigue dentro se vuelve a avisar: la zona es otra y allí aún no nos tienen.
local function revisar(marketId, yo, repetir)
    local z      = vigente(marketId)
    local dentro = z and dentroDe(yo, z) or false
    if dentro ~= (InZoneMap[marketId] == true) then
        InZoneMap[marketId] = dentro
        TriggerServerEvent(dentro and 'blackmarket:server:enterZone' or 'blackmarket:server:leaveZone', marketId)
    elseif dentro and repetir then
        TriggerServerEvent('blackmarket:server:enterZone', marketId)
    end
end

CreateThread(function()
    while true do
        Wait(500)
        local yo = GetEntityCoords(PlayerPedId())
        for marketId in pairs(Config.Markets) do
            revisar(marketId, yo, false)
        end
    end
end)

-- ========================================
-- EL PUNTO DEL MAPA
-- ========================================

local function clavePunto(marketId) return 'mercado_captura_' .. tostring(marketId) end

--- Rojo si se está peleando ya, ámbar si solo está anunciada. Con una sola
--- zona no se pone nada: la captura es donde el mercado, que ya tiene punto.
local function ponerPunto(marketId)
    local z = EnMarcha[marketId] or Anunciada[marketId]
    if not z or not z.varias then
        OrigenMapa.Quitar(clavePunto(marketId))
        return
    end
    local mCfg = Config.Markets[marketId]
    OrigenMapa.Poner(clavePunto(marketId), {
        x = z.x, y = z.y, z = z.z,
        cat = 'illegal',
        nombre = ('Captura · %s: %s'):format(mCfg and mCfg.label or 'Mercado negro', z.nombre or 'zona'),
        color = EnMarcha[marketId] and '#ff3355' or '#ffb020',
    })
end

RegisterNetEvent('blackmarket:client:zona', function(marketId, zona)
    marketId = tonumber(marketId)
    if not marketId then return end
    EnMarcha[marketId] = zona
    if zona then Anunciada[marketId] = nil end
    ponerPunto(marketId)
    revisar(marketId, GetEntityCoords(PlayerPedId()), zona ~= nil)
end)

-- La zona de siempre se ha movido desde el mapa del panel: solo cambia eso,
-- sin rehacer el mercado (sus NPC y sus puntos se quedan como están).
RegisterNetEvent('blackmarket:client:zonaPrincipal', function(marketId, centro, radio)
    marketId = tonumber(marketId)
    local mCfg = marketId and Config.Markets[marketId]
    if not mCfg or type(centro) ~= 'table' then return end
    mCfg.Center = vector3(centro.x + 0.0, centro.y + 0.0, (centro.z or 0) + 0.0)
    mCfg.Radius = tonumber(radio) or mCfg.Radius
    if UpdateMarketBlip then UpdateMarketBlip(marketId) end
end)

RegisterNetEvent('blackmarket:client:zonaAnunciada', function(marketId, zona)
    marketId = tonumber(marketId)
    if not marketId then return end
    Anunciada[marketId] = zona
    ponerPunto(marketId)
end)

-- Quien entra tarde lo recibe con el estado del mercado (main.lua lo registra).
AddEventHandler('blackmarket:client:updateState', function(state)
    local marketId = tonumber(state and state.marketId)
    if not marketId then return end
    EnMarcha[marketId]  = state.zona
    Anunciada[marketId] = state.zonaAnunciada
    ponerPunto(marketId)
end)

AddEventHandler('blackmarket:client:removeMarket', function(marketId)
    marketId = tonumber(marketId)
    if not marketId then return end
    EnMarcha[marketId], Anunciada[marketId] = nil, nil
    OrigenMapa.Quitar(clavePunto(marketId))
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for marketId in pairs(Config.Markets) do
        OrigenMapa.Quitar(clavePunto(marketId))
    end
end)

-- ========================================
-- COLOCAR DESDE EL AIRE (panel de admin)
-- ========================================

local RADIO_MIN, RADIO_MAX = 5.0, 300.0

local function acotar(v, min, max) return math.max(min, math.min(max, v)) end

--- Soltada este cuadro, esté el control apagado o no (con la cámara al
--- vuelo se apagan todos para que el personaje no se mueva).
local function soltada(control)
    return IsControlJustReleased(0, control) or IsDisabledControlJustReleased(0, control)
end

--- La rueda, como +1 / -1 / 0.
local function rueda()
    if IsControlJustPressed(0, 241) or IsDisabledControlJustPressed(0, 241) or IsDisabledControlJustPressed(0, 15) then return 1 end
    if IsControlJustPressed(0, 242) or IsDisabledControlJustPressed(0, 242) or IsDisabledControlJustPressed(0, 14) then return -1 end
    return 0
end

--[[ La cámara al vuelo con la que se coloca una zona.

     Una zona de sesenta metros no se ve desde el suelo: se está dentro de
     ella. Así que al colocarla la vista sube y se mueve suelta —WASD, ratón,
     ESPACIO y CTRL para la altura—, y la zona va donde se mira: un rayo desde
     la cámara hasta el suelo.

     Es una cámara de guion, no un noclip: el personaje se queda quieto donde
     estaba, sin teletransportes ni invencibilidad, que es lo que mira el
     anticheat. El foco del mapa sigue a la cámara para que cargue lo que
     tiene debajo. ]]
local Vuelo = {}

function Vuelo.abrir()
    local yo = PlayerPedId()
    local p  = GetEntityCoords(yo)
    -- Bajo techo se sube poco: desde 45 m el rayo daría en la calle de encima.
    local subida = GetInteriorFromEntity(yo) ~= 0 and 5.0 or 45.0
    local cam = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA',
        p.x, p.y, p.z + subida, -70.0, 0.0, GetEntityHeading(yo), 60.0, false, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 400, true, false)
    FreezeEntityPosition(yo, true)
    return { cam = cam, yo = yo, punto = vector3(p.x, p.y, p.z) }
end

--- Un cuadro: mueve la cámara y deja en `v.punto` dónde se está mirando.
function Vuelo.cuadro(v)
    DisableAllControlActions(0)
    EnableControlAction(0, 249, true)   -- pulsar para hablar
    EnableControlAction(0, 245, true)   -- chat

    local rot   = GetCamRot(v.cam, 2)
    local pitch = acotar(rot.x - GetDisabledControlNormal(0, 2) * 6.0, -89.0, 20.0)
    local yaw   = rot.z - GetDisabledControlNormal(0, 1) * 8.0
    SetCamRot(v.cam, pitch, 0.0, yaw, 2)

    local ry, rp = math.rad(yaw), math.rad(pitch)
    local paso   = (IsDisabledControlPressed(0, 21) and 2.4 or 0.7) * GetFrameTime() * 60.0
    local pos    = GetCamCoord(v.cam)
    local dx, dy, dz = 0.0, 0.0, 0.0
    if IsDisabledControlPressed(0, 32) then dx = dx - math.sin(ry); dy = dy + math.cos(ry) end   -- W
    if IsDisabledControlPressed(0, 33) then dx = dx + math.sin(ry); dy = dy - math.cos(ry) end   -- S
    if IsDisabledControlPressed(0, 34) then dx = dx - math.cos(ry); dy = dy - math.sin(ry) end   -- A
    if IsDisabledControlPressed(0, 35) then dx = dx + math.cos(ry); dy = dy + math.sin(ry) end   -- D
    if IsDisabledControlPressed(0, 22) then dz = dz + 1.0 end                                    -- ESPACIO
    if IsDisabledControlPressed(0, 36) then dz = dz - 1.0 end                                    -- CTRL
    pos = vector3(pos.x + dx * paso, pos.y + dy * paso, pos.z + dz * paso)
    SetCamCoord(v.cam, pos.x, pos.y, pos.z)
    SetFocusPosAndVel(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)

    -- A dónde se mira: el primer trozo de mapa que toca el rayo.
    local fx, fy, fz = -math.sin(ry) * math.cos(rp), math.cos(ry) * math.cos(rp), math.sin(rp)
    local rayo = StartShapeTestRay(pos.x, pos.y, pos.z, pos.x + fx * 1500.0, pos.y + fy * 1500.0, pos.z + fz * 1500.0, 1, v.yo, 0)
    local _, toca, donde = GetShapeTestResult(rayo)
    if toca == 1 or toca == true then v.punto = vector3(donde.x, donde.y, donde.z + 1.0) end   -- +1: a la altura de un ped, como los NPC
end

function Vuelo.cerrar(v)
    if not v then return end
    RenderScriptCams(false, true, 400, true, false)
    SetCamActive(v.cam, false)
    DestroyCam(v.cam, false)
    ClearFocus()
    FreezeEntityPosition(v.yo, false)
end

--- La zona dibujada: con altura, de -altura a +altura; sin ella, un murete
--- de tres metros que marca el borde. Y un punto en el centro.
local function dibujarZona(c, radio, altura)
    local base = altura > 0 and (c.z - altura) or (c.z - 1.0)
    local alto = altura > 0 and (altura * 2.0) or 3.0
    DrawMarker(1, c.x, c.y, base, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        radio * 2.0, radio * 2.0, alto, 216, 27, 85, 80, false, false, 2, false, nil, nil, false)
    DrawMarker(28, c.x, c.y, c.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.8, 0.8, 0.8, 216, 27, 85, 200, false, false, 2, false, nil, nil, false)
end

local function teclasDeZona(lista, radio)
    lista[#lista + 1] = { key = 'RUEDA', text = ('Radio: %d m'):format(math.floor(radio + 0.5)) }
    lista[#lista + 1] = { key = 'WASD', text = 'Mover la vista' }
    lista[#lista + 1] = { key = 'ESPACIO / CTRL', text = 'Subir y bajar' }
    lista[#lista + 1] = { key = 'SHIFT', text = 'Rápido' }
    return lista
end

local function redondear(c, rumbo)
    return {
        x = math.floor(c.x * 100) / 100,
        y = math.floor(c.y * 100) / 100,
        z = math.floor(c.z * 100) / 100,
        heading = rumbo and math.floor(rumbo * 10) / 10 or nil,
    }
end

--[[ Una zona suelta (las de «Dónde se pelea» y la de «Dónde está puesto»).
     El panel se esconde, la vista sube y la zona va donde se mira. Con la
     rueda se abre o se cierra. [E] la deja ahí; [RETROCESO] lo deja. ]]
RegisterNUICallback('colocarZona', function(data, cb)
    local radio  = acotar(tonumber(data and data.radio) or 58.0, RADIO_MIN, RADIO_MAX) + 0.0
    local altura = math.max(0.0, tonumber(data and data.altura) or 0.0) + 0.0

    SetNuiFocus(false, false)

    local function teclas()
        local lista = teclasDeZona({ { key = 'E', text = 'Poner la zona aquí' } }, radio)
        lista[#lista + 1] = { key = 'RETROCESO', text = 'Dejarlo' }
        exports['origen_hud']:setupControls(lista)
    end
    teclas()

    local vuelo = Vuelo.abrir()

    local function acabar(res)
        Vuelo.cerrar(vuelo)
        exports['origen_hud']:hideControls()
        SetNuiFocus(true, true)
        cb(res)
    end

    CreateThread(function()
        local limite = GetGameTimer() + 300000
        while GetGameTimer() < limite do
            Wait(0)
            Vuelo.cuadro(vuelo)

            local giro = rueda()
            if giro ~= 0 then
                radio = acotar(radio + giro * 2.0, RADIO_MIN, RADIO_MAX)
                teclas()
            end
            dibujarZona(vuelo.punto, radio, altura)

            if soltada(38) then         -- E
                local c = redondear(vuelo.punto)
                return acabar({ success = true, x = c.x, y = c.y, z = c.z, radio = math.floor(radio + 0.5) })
            end
            if soltada(177) then        -- RETROCESO
                return acabar({ success = false })
            end
        end
        acabar({ success = false })
    end)
end)

-- ========================================
-- MONTAR UN MERCADO ANDANDO (panel de admin)
-- ========================================

--[[ Los tres sitios de un mercado seguidos, sin volver al panel entre uno y
     otro: el que vende, el de la puerta y la zona. Los dos NPC se ponen
     andando hasta el sitio y pulsando [E], y quedan mirando hacia donde mira
     el admin; la zona, desde el aire (ver Vuelo). Lo ya puesto se queda a la
     vista —el NPC, medio transparente— para colocar lo siguiente con
     referencia. [RETROCESO] vuelve un paso.

     Con `data.solo` se hace un único paso: es el «Recolocar» de cada fila. ]]
local PASOS = {
    { clave = 'npc',     tecla = 'Poner aquí al que vende',      modelo = 'npc_model' },
    { clave = 'doornpc', tecla = 'Poner aquí al de la puerta',   modelo = 'doornpc_model' },
    { clave = 'center',  tecla = 'Poner aquí la zona de captura' },
}

local function fantasma(modelo, p, rumbo)
    local hash = type(modelo) == 'string' and joaat(modelo) or 0
    if hash == 0 or not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local intentos = 0
    while not HasModelLoaded(hash) and intentos < 200 do Wait(10); intentos = intentos + 1 end
    if not HasModelLoaded(hash) then return nil end
    local ped = CreatePed(4, hash, p.x, p.y, p.z - 1.0, rumbo, false, true)
    SetModelAsNoLongerNeeded(hash)
    if not ped or ped == 0 then return nil end
    SetEntityAlpha(ped, 170, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    return ped
end

RegisterNUICallback('montarEnElMundo', function(data, cb)
    data = data or {}
    local radio = acotar(tonumber(data.radio) or 58.0, RADIO_MIN, RADIO_MAX) + 0.0

    local pasos = PASOS
    if data.solo then
        pasos = {}
        for _, paso in ipairs(PASOS) do if paso.clave == data.solo then pasos[1] = paso end end
        if not pasos[1] then return cb({ success = false }) end
    end

    SetNuiFocus(false, false)

    local i, puesto, fantasmas, vuelo = 1, {}, {}, nil

    local function teclas()
        local paso  = pasos[i]
        local lista = { { key = 'E', text = #pasos > 1 and ('%s (%d de %d)'):format(paso.tecla, i, #pasos) or paso.tecla } }
        if paso.clave == 'center' then teclasDeZona(lista, radio) end
        lista[#lista + 1] = { key = 'RETROCESO', text = i > 1 and 'Paso atrás' or 'Dejarlo' }
        exports['origen_hud']:setupControls(lista)
    end

    --- La vista sube solo en el paso de la zona, y baja al salir de él.
    local function vista()
        local hace = pasos[i].clave == 'center'
        if hace and not vuelo then
            vuelo = Vuelo.abrir()
        elseif not hace and vuelo then
            Vuelo.cerrar(vuelo); vuelo = nil
        end
    end

    local function acabar(res)
        Vuelo.cerrar(vuelo); vuelo = nil
        for _, ped in pairs(fantasmas) do
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
        exports['origen_hud']:hideControls()
        SetNuiFocus(true, true)
        cb(res)
    end

    teclas()
    vista()

    CreateThread(function()
        local limite = GetGameTimer() + 600000
        while GetGameTimer() < limite do
            Wait(0)
            local paso = pasos[i]
            local sitio

            if paso.clave == 'center' then
                Vuelo.cuadro(vuelo)
                local giro = rueda()
                if giro ~= 0 then
                    radio = acotar(radio + giro * 2.0, RADIO_MIN, RADIO_MAX)
                    teclas()
                end
                dibujarZona(vuelo.punto, radio, 0.0)
                sitio = redondear(vuelo.punto)
            else
                -- Un aro en los pies y una raya hacia donde mirará el NPC.
                local yo = PlayerPedId()
                local p  = GetEntityCoords(yo)
                local f  = GetEntityForwardVector(yo)
                DrawMarker(25, p.x, p.y, p.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.9, 0.9, 0.9, 216, 27, 85, 200, false, false, 2, false, nil, nil, false)
                DrawLine(p.x, p.y, p.z - 0.9, p.x + f.x * 1.4, p.y + f.y * 1.4, p.z - 0.9, 216, 27, 85, 255)
                sitio = redondear(p, GetEntityHeading(yo))
            end

            if soltada(38) then                 -- E
                puesto[paso.clave] = sitio
                if i == #pasos then
                    return acabar({
                        success = true, radio = math.floor(radio + 0.5),
                        npc = puesto.npc, doornpc = puesto.doornpc, center = puesto.center,
                    })
                end
                -- Queda a la vista para colocar lo siguiente con referencia.
                if paso.modelo then
                    fantasmas[paso.clave] = fantasma(data[paso.modelo], sitio, sitio.heading or 0.0)
                end
                i = i + 1
                teclas(); vista()
            elseif soltada(177) then            -- RETROCESO
                if i == 1 then return acabar({ success = false }) end
                i = i - 1
                local clave = pasos[i].clave
                puesto[clave] = nil
                if fantasmas[clave] then
                    if DoesEntityExist(fantasmas[clave]) then DeleteEntity(fantasmas[clave]) end
                    fantasmas[clave] = nil
                end
                teclas(); vista()
            end
        end
        acabar({ success = false })
    end)
end)

RegisterNUICallback('getZonas', function(data, cb)
    cb(lib.callback.await('blackmarket:getZonas', false, data and data.marketId) or { success = false })
end)

RegisterNUICallback('saveZonas', function(data, cb)
    cb(lib.callback.await('blackmarket:saveZonas', false, data) or { success = false })
end)

-- ========================================
-- EL MAPA DEL PANEL
-- ========================================

RegisterNUICallback('getMapa', function(_, cb)
    cb(lib.callback.await('blackmarket:getMapa', false) or {})
end)

RegisterNUICallback('moverZonaMapa', function(data, cb)
    cb(lib.callback.await('blackmarket:moverZonaMapa', false, data) or { success = false })
end)

RegisterNUICallback('nuevaZonaMapa', function(data, cb)
    cb(lib.callback.await('blackmarket:nuevaZonaMapa', false, data) or { success = false })
end)

--- «Llévame»: marca el sitio en el GPS. No teletransporta a nadie.
RegisterNUICallback('marcarGPS', function(data, cb)
    local x, y = tonumber(data and data.x), tonumber(data and data.y)
    if x and y then SetNewWaypoint(x + 0.0, y + 0.0) end
    cb({ success = x ~= nil and y ~= nil })
end)
