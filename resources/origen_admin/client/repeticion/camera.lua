RepCamera = {
    handle = nil,
    mode = 'free',
    position = vector3(0.0, 0.0, 0.0),
    rotation = vector3(0.0, 0.0, 0.0),
    targetId = nil,
    orbitDistance = RepCfg.camera.orbitDistance,
}

function RepCamera.start(position, heading)
    if RepCamera.handle then return end

    RepCamera.position = position + vector3(0.0, 0.0, 2.0)
    RepCamera.rotation = vector3(-10.0, 0.0, heading or 0.0)
    RepCamera.mode = 'free'

    RepCamera.handle = CreateCamWithParams(
        'DEFAULT_SCRIPTED_CAMERA',
        RepCamera.position.x, RepCamera.position.y, RepCamera.position.z,
        RepCamera.rotation.x, RepCamera.rotation.y, RepCamera.rotation.z,
        60.0, false, 2
    )

    SetCamActive(RepCamera.handle, true)
    RenderScriptCams(true, true, 500, true, true)
end

function RepCamera.stop()
    if not RepCamera.handle then return end

    RenderScriptCams(false, true, 500, true, true)
    DestroyCam(RepCamera.handle, false)
    RepCamera.handle = nil
    RepCamera.targetId = nil
end

function RepCamera.toggleMode(targetId)
    if RepCamera.mode == 'free' then
        RepCamera.mode = 'orbit'
        RepCamera.targetId = targetId
    else
        RepCamera.mode = 'free'
    end

    return RepCamera.mode
end

local function updateRotation()
    local sensitivity = RepCfg.camera.sensitivity
    local dx = GetDisabledControlNormal(0, 1) * sensitivity
    local dy = GetDisabledControlNormal(0, 2) * sensitivity

    local pitch = math.max(-89.0, math.min(89.0, RepCamera.rotation.x - dy))
    local yaw = RepCamera.rotation.z - dx

    RepCamera.rotation = vector3(pitch, 0.0, yaw)
end

local function updateFreeMovement()
    local speed = RepCfg.camera.baseSpeed

    if IsDisabledControlPressed(0, RepCfg.keys.fast) then
        speed = speed * RepCfg.camera.fastMultiplier
    elseif IsDisabledControlPressed(0, RepCfg.keys.slow) then
        speed = speed * RepCfg.camera.slowMultiplier
    end

    local pitch = math.rad(RepCamera.rotation.x)
    local yaw = math.rad(RepCamera.rotation.z)

    local forward = vector3(
        -math.sin(yaw) * math.cos(pitch),
        math.cos(yaw) * math.cos(pitch),
        math.sin(pitch)
    )
    local right = vector3(math.cos(yaw), math.sin(yaw), 0.0)
    local move = vector3(0.0, 0.0, 0.0)

    if IsDisabledControlPressed(0, RepCfg.keys.forward) then move = move + forward end
    if IsDisabledControlPressed(0, RepCfg.keys.back) then move = move - forward end
    if IsDisabledControlPressed(0, RepCfg.keys.right) then move = move + right end
    if IsDisabledControlPressed(0, RepCfg.keys.left) then move = move - right end
    if IsDisabledControlPressed(0, RepCfg.keys.up) then move = move + vector3(0.0, 0.0, 1.0) end
    if IsDisabledControlPressed(0, RepCfg.keys.down) then move = move - vector3(0.0, 0.0, 1.0) end

    if #move > 0.01 then
        RepCamera.position = RepCamera.position + (move / #move) * speed
    end
end

local function updateOrbit()
    local ped = RepCamera.targetId and RepActors.getPed(RepCamera.targetId)

    -- Sin ped todavia (el modelo se esta cargando) se espera en orbita: pasar
    -- a libre aqui dejaba la camara clavada en el primer fotograma.
    if not ped then return end

    if IsDisabledControlPressed(0, RepCfg.keys.forward) then
        RepCamera.orbitDistance = math.max(1.5, RepCamera.orbitDistance - 0.15)
    elseif IsDisabledControlPressed(0, RepCfg.keys.back) then
        RepCamera.orbitDistance = math.min(40.0, RepCamera.orbitDistance + 0.15)
    end

    local center = GetEntityCoords(ped) + vector3(0.0, 0.0, 0.6)
    local pitch = math.rad(RepCamera.rotation.x)
    local yaw = math.rad(RepCamera.rotation.z)
    local distance = RepCamera.orbitDistance

    local offset = vector3(
        math.sin(yaw) * math.cos(pitch),
        -math.cos(yaw) * math.cos(pitch),
        -math.sin(pitch)
    ) * distance

    RepCamera.position = center + offset
end

function RepCamera.update()
    if not RepCamera.handle then return end

    updateRotation()

    if RepCamera.mode == 'orbit' then
        updateOrbit()
    else
        updateFreeMovement()
    end

    SetCamCoord(RepCamera.handle, RepCamera.position.x, RepCamera.position.y, RepCamera.position.z)
    SetCamRot(RepCamera.handle, RepCamera.rotation.x, RepCamera.rotation.y, RepCamera.rotation.z, 2)
end
