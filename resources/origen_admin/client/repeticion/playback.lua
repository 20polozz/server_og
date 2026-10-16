RepPlayback = {
    active = false,
    clip = nil,
    time = 0.0,
    cursor = 1,
    paused = false,
    speedIndex = RepCfg.defaultSpeedIndex,
    actorIds = {},
    focusIndex = 0,
    showTracers = true,
}

local FLAGS = RepUtils.FLAGS
local COLOR = RepUtils.COLOR

--[[ Las teclas van en la barra de teclas del servidor (origen_hud), no
     pintadas con DrawText de GTA. Se manda solo cuando cambia algo de lo que
     dice (pausa, trazadoras), no cada fotograma. ]]
local barraPuesta = nil

local function hudArrancado()
    return GetResourceState('origen_hud') == 'started'
end

local function ponerBarra()
    if not hudArrancado() then return end
    local estado = (RepPlayback.paused and 'p' or 'r') .. (RepPlayback.showTracers and 't' or 'n')
    if estado == barraPuesta then return end
    barraPuesta = estado
    exports.origen_hud:setupControls({
        { key = 'SPACE', text = RepPlayback.paused and 'Seguir' or 'Pausa' },
        { key = 'UP', text = 'Avanzar' },
        { key = 'DOWN', text = 'Atrás' },
        { key = 'LEFT', text = 'Más lento' },
        { key = 'RIGHT', text = 'Más rápido' },
        { key = 'Z / X', text = 'Evento' },
        { key = 'G', text = 'Cámara' },
        { key = 'Y', text = 'Objetivo' },
        { key = 'L', text = RepPlayback.showTracers and 'Ocultar disparos' or 'Ver disparos' },
        { key = 'WASD', text = 'Cámara libre' },
        { key = 'ESCAPE', text = 'Salir' },
    })
end

local function quitarBarra()
    if barraPuesta and hudArrancado() then exports.origen_hud:hideControls() end
    barraPuesta = nil
end
local savedCoords = nil

local function collectActorIds(clip)
    local seen = {}
    local ids = {}

    for i = 1, #clip.frames do
        for id in pairs(clip.frames[i].actors) do
            if not seen[id] then
                seen[id] = true
                ids[#ids + 1] = id
            end
        end
    end

    table.sort(ids)
    return ids
end

local scratch = {}
local scratchVehicles = {}

local function scratchFor(id)
    local data = scratch[id]

    if not data then
        data = {}
        scratch[id] = data
        scratchVehicles[id] = {}
    end

    return data
end

local function interpolate(id, a, b, t)
    local lerp = RepUtils.lerp
    local data = scratchFor(id)

    data.model = a.model
    data.x = lerp(a.x, b.x, t)
    data.y = lerp(a.y, b.y, t)
    data.z = lerp(a.z, b.z, t)
    data.h = RepUtils.lerpAngle(a.h, b.h, t)
    data.speed = lerp(a.speed, b.speed, t)
    data.health = a.health
    data.armour = a.armour
    data.weapon = a.weapon
    data.seat = a.seat
    data.name = a.name
    data.f = a.f
    data.ix, data.iy, data.iz = a.ix, a.iy, a.iz
    data.mx, data.my, data.mz = a.mx, a.my, a.mz

    if a.ax and b.ax then
        data.ax = lerp(a.ax, b.ax, t)
        data.ay = lerp(a.ay, b.ay, t)
        data.az = lerp(a.az, b.az, t)
    else
        data.ax, data.ay, data.az = a.ax, a.ay, a.az
    end

    local source, target = a.vehicle, scratchVehicles[id]

    if source then
        target.model = source.model
        target.plate = source.plate

        if b.vehicle and b.vehicle.model == source.model then
            target.x = lerp(source.x, b.vehicle.x, t)
            target.y = lerp(source.y, b.vehicle.y, t)
            target.z = lerp(source.z, b.vehicle.z, t)
            target.rx = RepUtils.lerpAngle(source.rx, b.vehicle.rx, t)
            target.ry = RepUtils.lerpAngle(source.ry, b.vehicle.ry, t)
            target.rz = RepUtils.lerpAngle(source.rz, b.vehicle.rz, t)
            target.speed = lerp(source.speed, b.vehicle.speed, t)
        else
            target.x, target.y, target.z = source.x, source.y, source.z
            target.rx, target.ry, target.rz = source.rx, source.ry, source.rz
            target.speed = source.speed
        end

        data.vehicle = target
    else
        data.vehicle = nil
    end

    return data
end

local function findFrameIndex(clip, time)
    local frames = clip.frames
    local index = RepPlayback.cursor

    if index > #frames or frames[index].t > time then
        index = 1
    end

    while index < #frames - 1 and frames[index + 1].t <= time do
        index = index + 1
    end

    RepPlayback.cursor = index
    return index
end

local function renderFrame()
    local clip = RepPlayback.clip
    local index = findFrameIndex(clip, RepPlayback.time)
    local current = clip.frames[index]
    local nextFrame = clip.frames[index + 1] or current
    local span = nextFrame.t - current.t
    local alpha = span > 0 and math.min(1.0, (RepPlayback.time - current.t) / span) or 0.0

    for _, id in ipairs(RepPlayback.actorIds) do
        local a = current.actors[id]
        local b = nextFrame.actors[id]

        if a and b then
            local lookahead = clip.frames[index + 2] and clip.frames[index + 2].actors[id] or b
            RepActors.apply(id, interpolate(id, a, b, alpha), lookahead)
        elseif a then
            RepActors.apply(id, a, a)
        else
            RepActors.hide(id)
        end
    end
end

local function drawTracers()
    if not RepPlayback.showTracers then return end

    local clip = RepPlayback.clip
    local from = RepPlayback.time - RepCfg.tracerWindow
    local index = RepPlayback.cursor

    while index > 1 and clip.frames[index].t > from do
        index = index - 1
    end

    for i = index, RepPlayback.cursor do
        local frame = clip.frames[i]
        local age = (RepPlayback.time - frame.t) / RepCfg.tracerWindow
        local fade = math.floor(200 * math.max(0.0, 1.0 - age))

        if fade > 8 then
            for _, actor in pairs(frame.actors) do
                local shooting = (actor.f or 0) & FLAGS.shooting ~= 0

                if shooting and actor.mx and actor.ix then
                    DrawLine(actor.mx, actor.my, actor.mz, actor.ix, actor.iy, actor.iz, 255, 200, 60, fade)
                    DrawMarker(28, actor.ix, actor.iy, actor.iz, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.08, 0.08, 0.08, 216, 27, 85, fade, false, false, 2, false, nil, nil, false)
                elseif shooting and actor.mx and actor.ax then
                    DrawLine(actor.mx, actor.my, actor.mz, actor.ax, actor.ay, actor.az, 255, 200, 60, fade)
                end
            end
        end
    end
end

local function drawAimLines()
    local frame = RepPlayback.clip.frames[RepPlayback.cursor]

    if not frame then return end

    for id, actor in pairs(frame.actors) do
        local flags = actor.f or 0

        if flags & FLAGS.aiming ~= 0 and flags & FLAGS.shooting == 0 and actor.mx and actor.ax then
            local alpha = RepCamera.targetId == id and 120 or 60
            DrawLine(actor.mx, actor.my, actor.mz, actor.ax, actor.ay, actor.az, 120, 200, 255, alpha)
        end
    end
end

local function eventLabel(event)
    local attacker = RepUtils.limpio(event.attackerName or event.attacker or 'desconocido')
    local victim = RepUtils.limpio(event.victimName or event.victim)
    local verb = event.fatal and 'mató a' or 'hirió a'

    return ('%s   %s %s %s (%d hp)'):format(
        RepUtils.formatTime(event.t), attacker, verb, victim, event.health or 0
    )
end

local feedScratch = {}

local function drawEventFeed()
    local events = RepPlayback.clip.events

    if #events == 0 then return end

    local shown = feedScratch

    table.wipe(shown)

    for i = #events, 1, -1 do
        if events[i].t <= RepPlayback.time then
            shown[#shown + 1] = events[i]

            if #shown >= RepCfg.eventFeedSize then break end
        end
    end

    if #shown == 0 then return end

    -- La ficha: papel con la franja rosa arriba y el rotulo en rosa.
    local alto = 0.040 + #shown * 0.027
    RepUtils.card(0.145, 0.108 + alto / 2, 0.27, alto)
    RepUtils.drawRect(0.145, 0.110, 0.27, 0.004, COLOR.acento[1], COLOR.acento[2], COLOR.acento[3], 255)
    RepUtils.drawText('REGISTRO DE DAÑO', 0.018, 0.115, 0.32, false, COLOR.acento)

    for i = 1, #shown do
        local event = shown[i]
        local recent = RepPlayback.time - event.t <= RepCfg.eventHighlightWindow
        local y = 0.145 + (i - 1) * 0.027

        -- Lo reciente, con la marca rosa a la izquierda y en tinta; lo viejo, tenue.
        if recent then
            RepUtils.drawRect(0.0135, y + 0.0115, 0.0025, 0.018, COLOR.acento[1], COLOR.acento[2], COLOR.acento[3], 255)
        end
        RepUtils.drawText(eventLabel(event), 0.018, y, 0.28, false, recent and COLOR.tinta or COLOR.tenue)
    end
end

local function drawEventMarkers()
    local events = RepPlayback.clip.events

    for i = 1, #events do
        local event = events[i]
        local delta = RepPlayback.time - event.t

        if delta < 0 then break end

        if delta <= RepCfg.eventHighlightWindow then
            local scale = 0.4 + (delta / RepCfg.eventHighlightWindow) * 0.6
            local alpha = math.floor(200 * (1.0 - delta / RepCfg.eventHighlightWindow))
            local green = event.fatal and 40 or 160

            DrawMarker(28, event.x, event.y, event.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, scale * 0.5, scale * 0.5, scale * 0.5, 255, green, 40, alpha, false, false, 2, false, nil, nil, false)
        end
    end
end

-- Altura (centro) de la barra de progreso: la pieza de abajo se apoya en
-- ella y queda por encima de la barra de teclas de origen_hud.
local BARRA_Y = 0.900

local function drawTimeline()
    local duration = RepPlayback.clip.duration

    if duration <= 0 then return end

    for i = 1, #RepPlayback.clip.events do
        local event = RepPlayback.clip.events[i]
        local x = 0.30 + 0.40 * (event.t / duration)
        -- Muertes en tinta, daño en gris: encima del rosa de la barra se ven las dos.
        local c = event.fatal and COLOR.tinta or COLOR.tenue

        RepUtils.drawRect(x, BARRA_Y, 0.0018, 0.018, c[1], c[2], c[3], 255)
    end
end

--[[ La pieza de abajo: papel con canto y sombra, la chapa de PAUSA/PLAY en
     rosa con tinta negra, el tiempo y la camara en tinta, y la barra de
     progreso (pista gris, relleno rosa). Las teclas ya no van aqui: estan en
     la barra de origen_hud, en el pie de la pantalla. ]]
local function drawHud()
    local speed = RepCfg.playbackSpeeds[RepPlayback.speedIndex]
    local progress = RepPlayback.clip.duration > 0 and RepPlayback.time / RepPlayback.clip.duration or 0.0
    local conTitulo = RepPlayback.label ~= nil
    local alto = conTitulo and 0.098 or 0.072
    local arriba = BARRA_Y + 0.016 - alto

    RepUtils.card(0.5, arriba + alto / 2, 0.44, alto)
    RepUtils.drawRect(0.5, arriba + 0.002, 0.44, 0.004, COLOR.acento[1], COLOR.acento[2], COLOR.acento[3], 255)

    local y = arriba + 0.010
    if conTitulo then
        RepUtils.drawText(RepUtils.limpio(RepPlayback.label), 0.5, y, 0.34, true, COLOR.acento)
        y = y + 0.026
    end

    -- PAUSA / PLAY: chapa rosa con canto negro a la izquierda.
    local status = RepPlayback.paused and 'PAUSA' or 'PLAY'
    RepUtils.card(0.318, y + 0.016, 0.042, 0.026, COLOR.acento)
    RepUtils.drawText(status, 0.318, y + 0.003, 0.36, true, COLOR.tinta)

    local seguido = RepCamera.targetId and RepPlayback.nombres[RepCamera.targetId] or RepCamera.targetId
    local camLabel = RepCamera.mode == 'orbit' and ('siguiendo a %s'):format(RepUtils.limpio(seguido or '-')) or 'libre'
    local header = ('%s / %s   |   x%.2f   |   Cámara %s'):format(
        RepUtils.formatTime(RepPlayback.time),
        RepUtils.formatTime(RepPlayback.clip.duration),
        speed,
        camLabel
    )
    RepUtils.drawText(header, 0.345, y, 0.40, false, COLOR.tinta)

    -- Barra de progreso: pista en gris de panel con canto, relleno rosa.
    RepUtils.card(0.5, BARRA_Y, 0.40, 0.008, COLOR.panel)
    if progress > 0 then
        RepUtils.drawRect(0.30 + 0.40 * progress * 0.5, BARRA_Y, 0.40 * progress, 0.008, COLOR.acento[1], COLOR.acento[2], COLOR.acento[3], 255)
    end

    drawTimeline()
end

local function actorStatus(data)
    local flags = data.f or 0

    if flags & FLAGS.dead ~= 0 then return 'ABATIDO' end
    if flags & FLAGS.shooting ~= 0 then return 'DISPARANDO' end
    if flags & FLAGS.reloading ~= 0 then return 'RECARGANDO' end
    if flags & FLAGS.melee ~= 0 then return 'CUERPO A CUERPO' end
    if flags & FLAGS.aiming ~= 0 then return 'APUNTANDO' end
    if flags & FLAGS.ragdoll ~= 0 then return 'RAGDOLL' end
    if flags & FLAGS.cover ~= 0 then return 'EN COBERTURA' end

    return nil
end

local function drawTags()
    local frame = RepPlayback.clip.frames[RepPlayback.cursor]

    if not frame then return end

    for _, id in ipairs(RepPlayback.actorIds) do
        local data = frame.actors[id]
        local ped = RepActors.getPed(id)

        if data and ped then
            local coords = GetEntityCoords(ped) + vector3(0.0, 0.0, 1.05)
            local onScreen, sx, sy = World3dToScreen2d(coords.x, coords.y, coords.z)

            if onScreen then
                -- Chapa de pegatina ajustada al texto: papel (rosa si es el
                -- seguido) con el nombre en tinta, la vida debajo y, si hace
                -- algo, el estado en rosa (en blanco sobre la chapa rosa).
                local label = data.name and ('%s [%s]'):format(RepUtils.limpio(data.name), id) or tostring(id)
                local vida = ('%d hp   %d ap'):format(data.health or 0, data.armour or 0)
                local status = actorStatus(data)
                local seguido = RepCamera.targetId == id

                local ancho = math.max(RepUtils.textWidth(label, 0.28), RepUtils.textWidth(vida, 0.25),
                    status and RepUtils.textWidth(status, 0.25) or 0) + 0.012
                local alto = status and 0.064 or 0.045

                RepUtils.card(sx, sy + alto / 2 - 0.002, ancho, alto, seguido and COLOR.acento or COLOR.fondo)
                RepUtils.drawText(label, sx, sy, 0.28, true, COLOR.tinta)
                RepUtils.drawText(vida, sx, sy + 0.021, 0.25, true, seguido and COLOR.tinta or COLOR.tenue)

                if status then
                    RepUtils.drawText(status, sx, sy + 0.040, 0.25, true, seguido and COLOR.blanco or COLOR.acento)
                end
            end
        end
    end
end

local function suppressPopulation()
    SetPedDensityMultiplierThisFrame(0.0)
    SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
    SetVehicleDensityMultiplierThisFrame(0.0)
    SetRandomVehicleDensityMultiplierThisFrame(0.0)
    SetParkedVehicleDensityMultiplierThisFrame(0.0)
    SetGarbageTrucks(false)
    SetRandomBoats(false)
    SetCreateRandomCops(false)
end

local function disableControls()
    DisableAllControlActions(0)
    EnableControlAction(0, RepCfg.keys.togglePause, true)
    EnableControlAction(0, RepCfg.keys.exit, true)
end

local function jumpToEvent(direction)
    local events = RepPlayback.clip.events

    if #events == 0 then return end

    if direction > 0 then
        for i = 1, #events do
            if events[i].t > RepPlayback.time + 50 then
                RepPlayback.time = math.max(0.0, events[i].t - 1500)
                return
            end
        end

        RepPlayback.time = math.max(0.0, events[#events].t - 1500)
        return
    end

    for i = #events, 1, -1 do
        if events[i].t < RepPlayback.time - 1600 then
            RepPlayback.time = math.max(0.0, events[i].t - 1500)
            return
        end
    end

    RepPlayback.time = 0.0
end

local function handleInput()
    if IsDisabledControlJustPressed(0, RepCfg.keys.togglePause) then
        RepPlayback.paused = not RepPlayback.paused
    end

    if IsDisabledControlJustPressed(0, RepCfg.keys.speedUp) then
        RepPlayback.speedIndex = math.min(#RepCfg.playbackSpeeds, RepPlayback.speedIndex + 1)
    elseif IsDisabledControlJustPressed(0, RepCfg.keys.speedDown) then
        RepPlayback.speedIndex = math.max(1, RepPlayback.speedIndex - 1)
    end

    if IsDisabledControlPressed(0, RepCfg.keys.stepForward) then
        RepPlayback.time = math.min(RepPlayback.clip.duration, RepPlayback.time + 40.0)
    elseif IsDisabledControlPressed(0, RepCfg.keys.stepBack) then
        RepPlayback.time = math.max(0.0, RepPlayback.time - 40.0)
    end

    if IsDisabledControlJustPressed(0, RepCfg.keys.nextEvent) then
        jumpToEvent(1)
    elseif IsDisabledControlJustPressed(0, RepCfg.keys.prevEvent) then
        jumpToEvent(-1)
    end

    if IsDisabledControlJustPressed(0, RepCfg.keys.toggleTracers) then
        RepPlayback.showTracers = not RepPlayback.showTracers
    end

    if IsDisabledControlJustPressed(0, RepCfg.keys.cycleTarget) and #RepPlayback.actorIds > 0 then
        RepPlayback.focusIndex = RepPlayback.focusIndex % #RepPlayback.actorIds + 1
        RepCamera.targetId = RepPlayback.actorIds[RepPlayback.focusIndex]

        if RepCamera.mode == 'free' then
            RepCamera.toggleMode(RepCamera.targetId)
        end
    end

    if IsDisabledControlJustPressed(0, RepCfg.keys.toggleCamera) then
        RepCamera.toggleMode(RepCamera.targetId or RepPlayback.actorIds[1])
    end

    if IsDisabledControlJustPressed(0, RepCfg.keys.exit) or IsDisabledControlJustPressed(0, RepCfg.keys.exitAlt) then
        RepPlayback.stop()
    end
end

--- `seguirId` es el actor al que se pega la camara al empezar ('p' .. id de
--- servidor). Sin el, la camara salia libre mirando al norte desde donde
--- estuviera el primero de la lista, y no se veia a nadie.
function RepPlayback.start(clip, seguirId)
    if RepPlayback.active or not clip then return false end

    RepPlayback.clip = clip
    RepPlayback.time = 0.0
    RepPlayback.cursor = 1
    RepPlayback.paused = false
    RepPlayback.speedIndex = RepCfg.defaultSpeedIndex
    RepPlayback.actorIds = collectActorIds(clip)
    RepPlayback.focusIndex = 0
    RepPlayback.active = true

    RepPlayback.nombres = {}
    for i = 1, #clip.frames do
        for id, data in pairs(clip.frames[i].actors) do
            if data.name and not RepPlayback.nombres[id] then RepPlayback.nombres[id] = data.name end
        end
    end

    local myPed = cache.ped
    savedCoords = GetEntityCoords(myPed)

    -- Donde empieza la camara: el seguido en su primera aparicion o, si no
    -- sale, el primero que haya.
    local anchor, rumbo
    if seguirId then
        for i = 1, #clip.frames do
            local data = clip.frames[i].actors[seguirId]
            if data then
                anchor, rumbo = vector3(data.x, data.y, data.z), data.h
                break
            end
        end
    end
    if not anchor then
        for id, data in pairs(clip.frames[1].actors) do
            anchor, rumbo, seguirId = vector3(data.x, data.y, data.z), data.h, id
            break
        end
    end

    anchor = anchor or savedCoords

    -- Nada de NUI con el foco puesto: el panel ya se ha cerrado, pero si otra
    -- se lo quedo, los controles no llegarian a la camara.
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    TriggerEvent('origen:foco:soltar')
    -- El radial de origen_hud (ESC) mira esto para no abrirse encima.
    LocalPlayer.state:set('enRepeticion', true, false)

    SetEntityVisible(myPed, false, false)
    SetEntityCollision(myPed, false, false)
    FreezeEntityPosition(myPed, true)
    SetEntityInvincible(myPed, true)
    SetEntityCoordsNoOffset(myPed, anchor.x, anchor.y, anchor.z, false, false, false)

    RepCamera.start(anchor, rumbo or 0.0)
    if seguirId then
        RepCamera.mode = 'orbit'
        RepCamera.targetId = seguirId
        for i, id in ipairs(RepPlayback.actorIds) do
            if id == seguirId then RepPlayback.focusIndex = i end
        end
    end
    DisplayRadar(false)
    RepRecorder.paused = true

    if RepCfg.useBucket then
        TriggerServerEvent('origen_admin:server:repeticionEntrarBucket')
    end

    ClearAreaOfPeds(anchor.x, anchor.y, anchor.z, 400.0, 1)
    ClearAreaOfVehicles(anchor.x, anchor.y, anchor.z, 400.0, false, false, false, false, false)

    CreateThread(function()
        local last = GetGameTimer()

        while RepPlayback.active do
            local now = GetGameTimer()
            local delta = now - last
            last = now

            disableControls()
            suppressPopulation()
            handleInput()

            if RepPlayback.active and not RepPlayback.paused then
                RepPlayback.time = RepPlayback.time + delta * RepCfg.playbackSpeeds[RepPlayback.speedIndex]

                if RepPlayback.time >= RepPlayback.clip.duration then
                    RepPlayback.time = 0.0
                    RepPlayback.cursor = 1
                end
            end

            if RepPlayback.active then
                ponerBarra()
                renderFrame()
                RepCamera.update()
                drawTracers()
                drawAimLines()
                drawEventMarkers()
                drawHud()
                drawEventFeed()
                drawTags()
            end

            Wait(0)
        end
    end)

    return true
end

function RepPlayback.stop()
    if not RepPlayback.active then return false end

    RepPlayback.active = false
    LocalPlayer.state:set('enRepeticion', false, false)
    quitarBarra()

    RepCamera.stop()
    RepActors.clear()

    if RepCfg.useBucket then
        TriggerServerEvent('origen_admin:server:repeticionSalirBucket')
    end

    RepRecorder.paused = false
    RepPlayback.label = nil
    table.wipe(scratch)
    table.wipe(scratchVehicles)

    local myPed = cache.ped

    SetEntityVisible(myPed, true, false)
    SetEntityCollision(myPed, true, true)
    FreezeEntityPosition(myPed, false)
    SetEntityInvincible(myPed, false)

    if savedCoords then
        SetEntityCoordsNoOffset(myPed, savedCoords.x, savedCoords.y, savedCoords.z, false, false, false)
        savedCoords = nil
    end

    DisplayRadar(true)

    -- Quien la lanzo (la pestaña Espectar) vuelve a abrir el panel.
    local alTerminar = RepPlayback.alTerminar
    RepPlayback.alTerminar = nil
    if alTerminar then alTerminar() end

    return true
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if RepPlayback.active then
        RepPlayback.alTerminar = nil
        RepPlayback.stop()
    end

    RepActors.clear()
end)
