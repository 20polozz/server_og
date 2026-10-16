-- ── f_placement.lua ──────────────────────────────────────────────────────────
-- Helper centralizado de placement. Motor idéntico a StartLocationPlacement
-- (main.lua): mismo raycast, mismo DrawMarker — sin líneas de heading ni
-- extras visuales. Solo marker sobre el suelo, igual que al colocar locations.
--
-- API pública:
--
--   Placement.Start(opts, callback)
--     opts = {
--       -- Marker de preview (opcional; si se omite no dibuja nada)
--       marker = {
--         type, offset={x,y,z}, scale={x,y,z}, color={r,g,b,a},
--         bobUpAndDown, faceCamera, rotationOrder, rotate
--       },
--       -- Ped de preview (opcional; para stores/sell stores)
--       ped_model = "s_m_y_dealer_01",
--       -- Vehículo de preview (opcional; para garages de banda)
--       vehicle_model = "sultan",   -- model name del vehículo
--       vehicle_alpha = 150,        -- transparencia 0-255 (def: 150)
--       -- Textos de controles HUD
--       label_confirm = string,  -- default locale ui.confirm_position
--       label_rotate  = string,  -- default locale ui.rotate_point
--       label_cancel  = string,  -- default locale ui.cancel
--     }
--     callback(result) donde result = { x, y, z, h } | nil (nil = cancelado)
--
-- ─────────────────────────────────────────────────────────────────────────────

Placement = Placement or {}

-- ── Raycast ───────────────────────────────────────────────────────────────────
-- Mismo patrón que RayCastGamePlayCamera de main.lua:
-- flags = 1 (geometría mundo) | 16 (mapa/agua sólida) | 32 (vehículos) — NO -1.
-- Excluir agua, vegetación y vidrios da un snap de Z mucho más limpio.

local function PlacementRaycast(distance)
    local camRot   = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()

    local rX = math.rad(camRot.x)
    local rZ = math.rad(camRot.z)
    local dir = vector3(
        -math.sin(rZ) * math.abs(math.cos(rX)),
         math.cos(rZ) * math.abs(math.cos(rX)),
         math.sin(rX)
    )

    local dest = camCoord + dir * distance

    -- flags: 1=world|16=water_solid|32=vehicles  (NO vidrio ni vegetación)
    local _, hit, coords, _, entity = GetShapeTestResult(
        StartShapeTestRay(
            camCoord.x, camCoord.y, camCoord.z,
            dest.x,     dest.y,     dest.z,
            1 | 16 | 32,
            PlayerPedId(),
            4   -- options: ignorar el ped local
        )
    )

    if hit == 1 then
        return true, coords, entity
    end
    return false, nil, nil
end

-- ── Cargar ped de preview ─────────────────────────────────────────────────────

local function LoadPreviewPed(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 100 do
        Wait(100)
        t = t + 1
    end
    if not HasModelLoaded(hash) then return nil, hash end

    local ped = CreatePed(4, hash, 0, 0, 0, 0, false, true)
    SetEntityInvincible(ped, true)
    SetEntityCollision(ped, false, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    return ped, hash
end

-- ── Cargar vehículo de preview (alpha, sin colisión, congelado) ───────────────

local function LoadPreviewVehicle(model, alpha)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 100 do
        Wait(100)
        t = t + 1
    end
    if not HasModelLoaded(hash) then return nil, hash end

    -- Calcular el offset Z del bounding box ANTES de crear el vehículo.
    -- GetModelDimensions devuelve (minVec, maxVec) del bounding box del modelo.
    -- El origen del vehículo está en su centro de masa, no en las ruedas.
    -- El minVec.z es la distancia desde el origen hasta el punto más bajo (negativa).
    -- Al mover el vehículo a la Z del suelo, necesitamos sumarle ese offset
    -- para que las ruedas queden exactamente apoyadas, no hundidas.
    local minVec, _ = GetModelDimensions(hash)
    -- minVec.z es negativo (ej: -0.75 para un sedan), tomamos su valor absoluto
    local zOffset = math.abs(minVec.z)

    -- Spawn fuera de cámara, invisible hasta que haya hit
    local veh = CreateVehicle(hash, 0.0, 0.0, -200.0, 0.0, false, false)
    SetEntityCollision(veh, false, false)
    FreezeEntityPosition(veh, true)
    SetEntityInvincible(veh, true)
    SetEntityAlpha(veh, alpha or 150, false)
    SetEntityVisible(veh, false, false)
    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleLights(veh, 0)

    return veh, hash, zOffset
end

-- ── Dibujar marker de preview ─────────────────────────────────────────────────
-- Fiel al DrawMarker de StartLocationPlacement: solo el marker, sin líneas extra.

local function DrawPlacementMarker(m, coords)
    local mo = m.offset or { x = 0.0, y = 0.0, z = 1.0 }
    DrawMarker(
        m.type or 22,
        coords.x + (mo.x or 0.0),
        coords.y + (mo.y or 0.0),
        coords.z + (mo.z or 1.0),
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        (m.scale and m.scale.x) or 0.25,
        (m.scale and m.scale.y) or 0.25,
        (m.scale and m.scale.z) or 0.25,
        (m.color and m.color.r) or 0,
        (m.color and m.color.g) or 0,
        (m.color and m.color.b) or 0,
        (m.color and m.color.a) or 200,
        m.bobUpAndDown == true,
        m.faceCamera ~= false,
        m.rotationOrder or 2,
        m.rotate == true,
        nil, nil, false
    )
end

-- ── API pública ───────────────────────────────────────────────────────────────

function Placement.Start(opts, callback)
    opts = opts or {}

    -- Controles HUD
    -- El pie de teclas de origen_hud (MostrarTeclas, functions/f_utils.lua).
    MostrarTeclas({
        { key = 'ENTER', text = opts.label_confirm or locale:t('ui.confirm_position') },
        { key = 'WHEEL', text = opts.label_rotate  or locale:t('ui.rotate_point')     },
        { key = 'X',     text = opts.label_cancel  or locale:t('ui.cancel')           },
    })

    -- Cargar ped de preview si se pidió
    local previewPed  = nil
    local previewHash = nil

    if opts.ped_model and opts.ped_model ~= '' then
        CreateThread(function()
            previewPed, previewHash = LoadPreviewPed(opts.ped_model)
        end)
    end

    -- Cargar vehículo de preview si se pidió
    -- Si existe vehicle_model, el preview de vehículo toma precedencia sobre el marker.
    local previewVeh     = nil
    local previewVehHash = nil
    local previewVehZOffset = 0.0  -- offset para apoyar ruedas en el suelo

    if opts.vehicle_model and opts.vehicle_model ~= '' then
        CreateThread(function()
            previewVeh, previewVehHash, previewVehZOffset = LoadPreviewVehicle(opts.vehicle_model, opts.vehicle_alpha)
            previewVehZOffset = previewVehZOffset or 0.0
        end)
    end

    local heading   = 0.0
    local done      = false

    local function cleanupPreview()
        if previewPed  and DoesEntityExist(previewPed)  then DeleteEntity(previewPed)  end
        if previewHash then SetModelAsNoLongerNeeded(previewHash) end
        if previewVeh  and DoesEntityExist(previewVeh)  then DeleteEntity(previewVeh)  end
        if previewVehHash then SetModelAsNoLongerNeeded(previewVehHash) end
    end

    CreateThread(function()
        while not done do
            -- Bloquear ataques
            DisableControlAction(0, 24,  true)  -- Attack
            DisableControlAction(0, 257, true)  -- Attack 2
            DisableControlAction(0, 25,  true)  -- Aim
            DisableControlAction(0, 263, true)  -- Melee 1
            DisableControlAction(0, 140, true)  -- Melee light
            DisableControlAction(0, 142, true)  -- Melee alt
            DisableControlAction(0, 143, true)  -- Melee block

            local hit, coords = PlacementRaycast(20.0)

            if hit and coords then
                -- Preview vehículo (tiene prioridad sobre marker y ped)
                if previewVeh and DoesEntityExist(previewVeh) then
                    -- El raycast da la Z de la superficie. El origen del vehículo
                    -- está en su centro de masa, NO en las ruedas. Sumamos el offset
                    -- del bounding box (minVec.z negativo → absolute value) para que
                    -- las ruedas queden exactamente apoyadas en el suelo sin hundirse.
                    local groundZ = coords.z + previewVehZOffset
                    SetEntityCoordsNoOffset(previewVeh, coords.x, coords.y, groundZ, false, false, false)
                    SetEntityHeading(previewVeh, heading)
                    SetEntityVisible(previewVeh, true, false)
                elseif previewPed and DoesEntityExist(previewPed) then
                    -- Preview ped (solo si no hay vehículo)
                    SetEntityCoords(previewPed, coords.x, coords.y, coords.z, false, false, false, false)
                    SetEntityHeading(previewPed, heading)
                    SetEntityVisible(previewPed, true, false)
                end

                -- Preview marker: solo si no hay vehículo
                if opts.marker and not previewVeh then
                    DrawPlacementMarker(opts.marker, coords)
                end

                -- Confirmar (ENTER)
                if IsControlJustPressed(0, 18) then
                    done = true
                    QuitarTeclas()
                    cleanupPreview()
                    if callback then
                        callback({ x = coords.x, y = coords.y, z = coords.z, h = heading })
                    end
                end
            else
                -- Sin hit: ocultar previews
                if previewPed and DoesEntityExist(previewPed) then
                    SetEntityVisible(previewPed, false, false)
                end
                if previewVeh and DoesEntityExist(previewVeh) then
                    SetEntityVisible(previewVeh, false, false)
                end
            end

            -- Rotación scroll (funciona siempre, con o sin hit)
            if IsControlPressed(0, 14) then        -- Scroll Down
                heading = (heading - 2.0) % 360.0
            elseif IsControlPressed(0, 15) then    -- Scroll Up
                heading = (heading + 2.0) % 360.0
            end

            -- Cancelar (X) — funciona siempre
            if IsControlJustPressed(0, 73) then
                done = true
                QuitarTeclas()
                cleanupPreview()
                if callback then callback(nil) end
            end

            Wait(0)
        end
    end)
end
