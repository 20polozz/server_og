-- ─────────────────────────────────────────────────────────────────────────────
--  origen_weed · La policía y las plantaciones — Cliente (08/10)
--  · Olor: el agente de servicio que pasa cerca de una planta lo nota.
--  · Cámara térmica del helicóptero: las plantas grandes brillan.
--  · Testigos: excursionistas que pasean por las zonas y, si te ven plantar o
--    cosechar, sacan el móvil; si no los espantas, llaman a la policía.
-- ─────────────────────────────────────────────────────────────────────────────
local function cfg() return Config.Weed.Police or {} end

local function aviso(texto, tipo, ms)
    exports['origen_notify']:Notify({ description = texto, type = tipo or 'info', duration = ms or 5000 })
end

local RUMBOS = { 'el norte', 'el noreste', 'el este', 'el sureste', 'el sur', 'el suroeste', 'el oeste', 'el noroeste' }
--- Hacia dónde queda `hasta` desde `desde` (0 = norte, en el sentido del reloj)
local function rumbo(desde, hasta)
    local a = math.deg(math.atan(hasta.x - desde.x, hasta.y - desde.y)) % 360
    return RUMBOS[math.floor((a + 22.5) / 45) % 8 + 1]
end

-- ── Olor ──────────────────────────────────────────────────────────────────────
-- Las plantas se conocen todas en el cliente (las manda el servidor para
-- dibujarlas), así que el olor se mira aquí. Un aviso por sitio cada `cadaSeg`.
local olidas = {}
CreateThread(function()
    while true do
        Wait(4000)
        local o = cfg().olor
        if o and WeedEsPoli and WeedEsPoli() and not IsPedInAnyHeli(PlayerPedId()) then
            local p = GetEntityCoords(PlayerPedId())
            local mejor, dMejor
            for _, pl in pairs(WeedPlantasConocidas() or {}) do
                local d = #(p - pl.coords)
                if d <= (o.base or 12) + (pl.stage or 1) * (o.porFase or 7) and (not dMejor or d < dMejor) then
                    mejor, dMejor = pl, d
                end
            end
            if mejor then
                local clave = ('%d:%d'):format(math.floor(mejor.coords.x / 25), math.floor(mejor.coords.y / 25))
                if not olidas[clave] or GetGameTimer() - olidas[clave] > (o.cadaSeg or 180) * 1000 then
                    olidas[clave] = GetGameTimer()
                    local fuerte = dMejor < 15 and 'muy fuerte ' or ''
                    aviso(('Huele %sa maría por aquí, hacia %s'):format(fuerte, rumbo(p, mejor.coords)), 'warning', 7000)
                end
            end
        end
    end
end)

-- ── Cámara térmica del helicóptero ────────────────────────────────────────────
-- Con la visión térmica puesta (la de origen_police, o cualquiera) y dentro de
-- un helicóptero, las plantas desde la fase `desdeFase` brillan como un foco de
-- calor. Las pequeñas no: plantar y cosechar a tiempo es más seguro.
CreateThread(function()
    while true do
        local espera = 600
        local t = cfg().termica
        local ped = PlayerPedId()
        if t and WeedEsPoli and WeedEsPoli() and IsPedInAnyHeli(ped) and IsSeethroughActive() then
            espera = 0
            local p = GetEntityCoords(ped)
            for _, pl in pairs(WeedPlantasConocidas() or {}) do
                if (pl.stage or 1) >= (t.desdeFase or 4) and #(p - pl.coords) <= (t.distancia or 450.0) then
                    local c = pl.coords
                    DrawMarker(28, c.x, c.y, c.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        1.6, 1.6, 1.6, 255, 255, 255, 170, false, false, 2, false, nil, nil, false)
                end
            end
        end
        Wait(espera)
    end
end)

-- ── Excursionistas ────────────────────────────────────────────────────────────
-- Solo los ve el jugador que está en la zona (son suyos, sin red): pasean un
-- rato cerca y se van. Bastan para que plantar no sea siempre a solas.
local function enZona()
    local r = Config.Weed.Planting
    local p = GetEntityCoords(PlayerPedId())
    for _, z in ipairs((r and r.validZones) or {}) do
        if #(p - z.coords) <= z.radius then return z end
    end
end

local paseantes = {}   -- [ped] = hasta (GetGameTimer)

local function quitarPaseante(ped)
    paseantes[ped] = nil
    if DoesEntityExist(ped) then
        SetEntityAsMissionEntity(ped, true, true)
        DeletePed(ped)
    end
end

--- La configuración de los testigos, o nil si están apagados.
local function testigosCfg()
    local t = cfg().testigos
    if not t or t.activo == false then return nil end
    return t
end

CreateThread(function()
    while true do
        local t = testigosCfg()
        local paseo = t and t.paseo or {}
        Wait(math.random(paseo.cadaMin or 120, paseo.cadaMax or 240) * 1000)
        -- Los que ya han cumplido (y no están a la vista) se van
        for ped, hasta in pairs(paseantes) do
            if not DoesEntityExist(ped) then paseantes[ped] = nil
            elseif GetGameTimer() > hasta and not IsEntityOnScreen(ped) then quitarPaseante(ped) end
        end
        local z = t and enZona()
        local cuantos = 0
        for _ in pairs(paseantes) do cuantos = cuantos + 1 end
        if z and not (WeedEsPoli and WeedEsPoli()) and cuantos < (paseo.max or 2) and math.random(100) <= (paseo.prob or 60) then
            local modelo = joaat(t.modelos[math.random(#t.modelos)])
            RequestModel(modelo)
            local limite = GetGameTimer() + 5000
            while not HasModelLoaded(modelo) and GetGameTimer() < limite do Wait(50) end
            if HasModelLoaded(modelo) then
                local p = GetEntityCoords(PlayerPedId())
                local a = math.random() * 2 * math.pi
                local d = math.random(55, 85)
                local x, y = p.x + math.cos(a) * d, p.y + math.sin(a) * d
                local ok, gz = GetGroundZFor_3dCoord(x, y, p.z + 50.0, false)
                if ok then
                    local ped = CreatePed(4, modelo, x, y, gz, math.random(0, 359) + 0.0, false, false)
                    if ped and ped ~= 0 then
                        SetBlockingOfNonTemporaryEvents(ped, false)
                        SetPedFleeAttributes(ped, 0, true)
                        TaskWanderInArea(ped, p.x, p.y, p.z, 60.0, 4.0, 8.0)
                        paseantes[ped] = GetGameTimer() + (paseo.vida or 300) * 1000
                    end
                end
                SetModelAsNoLongerNeeded(modelo)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    for ped in pairs(paseantes) do
        if DoesEntityExist(ped) then SetEntityAsMissionEntity(ped, true, true) DeletePed(ped) end
    end
end)

-- ── Testigos: alguien te ha visto ─────────────────────────────────────────────
local llamando = false
RegisterNetEvent('origen_weed:client:Testigos', function(accion)
    local t = testigosCfg()
    if not t or llamando then return end
    local yo = PlayerPedId()
    local p  = GetEntityCoords(yo)

    -- El que más cerca esté y te vea: cualquier persona del juego, no jugadores
    local testigo, dMin
    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= yo and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) and IsPedHuman(ped)
            and not IsPedInAnyVehicle(ped, false) then
            local d = #(GetEntityCoords(ped) - p)
            if d <= (t.radio or 40.0) and (not dMin or d < dMin) and HasEntityClearLosToEntity(ped, yo, 17) then
                testigo, dMin = ped, d
            end
        end
    end
    if not testigo then return end

    llamando = true
    CreateThread(function()
        SetEntityAsMissionEntity(testigo, true, true)
        ClearPedTasks(testigo)
        TaskTurnPedToFaceEntity(testigo, yo, 1500)
        Wait(1200)
        TaskStartScenarioInPlace(testigo, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
        aviso('Alguien te ha visto y está sacando el móvil… espántalo antes de que llame', 'warning', 6000)

        local hasta = GetGameTimer() + (t.segundos or 8) * 1000
        local espantado = false
        while GetGameTimer() < hasta do
            Wait(100)
            if not DoesEntityExist(testigo) or IsPedDeadOrDying(testigo, true) then espantado = true break end
            -- Apuntarle o acercarse corriendo a por él le espanta
            if IsPlayerFreeAimingAtEntity(PlayerId(), testigo) or IsPlayerTargettingEntity(PlayerId(), testigo)
                or (#(GetEntityCoords(yo) - GetEntityCoords(testigo)) < 3.0 and IsPedSprinting(yo)) then
                espantado = true
                break
            end
        end

        if DoesEntityExist(testigo) and not IsPedDeadOrDying(testigo, true) then
            ClearPedTasks(testigo)
            TaskSmartFleePed(testigo, yo, 150.0, 20000, false, false)
        end
        if espantado then
            aviso('Se ha asustado y ha salido corriendo sin llamar', 'success', 4000)
        else
            TriggerServerEvent('origen_weed:server:Chivatazo', accion)
            aviso('Ha llamado a la policía', 'error', 5000)
        end
        if DoesEntityExist(testigo) then SetEntityAsNoLongerNeeded(testigo) end
        llamando = false
    end)
end)
