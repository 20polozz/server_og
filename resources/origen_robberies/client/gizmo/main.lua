Gizmo = {
    enabled = false,
    entity = nil,
    currentMode = 'Translate',
    isRelative = false,
}

local function normalize(x, y, z)
    local length = math.sqrt(x * x + y * y + z * z)
    if length == 0 then return 0, 0, 0 end
    return x / length, y / length, z / length
end

local function makeEntityMatrix(entity)
    local f, r, u, a = GetEntityMatrix(entity)
    local view = DataView.ArrayBuffer(60)

    view:SetFloat32(0, r[1]):SetFloat32(4, r[2]):SetFloat32(8, r[3]):SetFloat32(12, 0)
    view:SetFloat32(16, f[1]):SetFloat32(20, f[2]):SetFloat32(24, f[3]):SetFloat32(28, 0)
    view:SetFloat32(32, u[1]):SetFloat32(36, u[2]):SetFloat32(40, u[3]):SetFloat32(44, 0)
    view:SetFloat32(48, a[1]):SetFloat32(52, a[2]):SetFloat32(56, a[3]):SetFloat32(60, 1)

    return view
end

local function applyEntityMatrix(entity, view)
    local x1, y1, z1 = view:GetFloat32(16), view:GetFloat32(20), view:GetFloat32(24)
    local x2, y2, z2 = view:GetFloat32(0), view:GetFloat32(4), view:GetFloat32(8)
    local x3, y3, z3 = view:GetFloat32(32), view:GetFloat32(36), view:GetFloat32(40)
    local tx, ty, tz = view:GetFloat32(48), view:GetFloat32(52), view:GetFloat32(56)

    x1, y1, z1 = normalize(x1, y1, z1)
    x2, y2, z2 = normalize(x2, y2, z2)
    x3, y3, z3 = normalize(x3, y3, z3)

    SetEntityMatrix(entity,
        x1, y1, z1,
        x2, y2, z2,
        x3, y3, z3,
        tx, ty, tz
    )
end

function Gizmo:StartGizmo(entity)
    if self.enabled then return end

    self.enabled = true
    self.entity = entity
    self.currentMode = 'Translate'

    local initialCoords = GetEntityCoords(entity)
    local initialRotation = GetEntityRotation(entity)
    local cancelled = false
    local confirmed = false

    if GetResourceState('origen_hud') == 'started' then
        exports.origen_hud:setupControls()
        exports.origen_hud:setupControls({
            { key = 'W', text = 'Mover' },
            { key = 'R', text = 'Rotar' },
            { key = 'Q', text = 'Local/Mundo' },
            { key = 'ALT', text = 'Ajustar al suelo' },
            { key = 'G', text = 'Mover apuntando' },
            { key = 'Intro', text = 'Confirmar posición' },
        })
    end

    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, false, false)

    if IsEntityAPed(entity) then
        SetEntityAlpha(entity, 200, false)
    else
        SetEntityDrawOutline(entity, true)
    end

    EnterCursorMode()

    while self.enabled and DoesEntityExist(entity) do
        Wait(0)

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 14, true)
        DisableControlAction(0, 15, true)
        DisableControlAction(0, 19, true)
        DisablePlayerFiring(cache.playerId, true)

        if IsDisabledControlJustPressed(0, 47) then
            self.enabled = false
            break
        end

        if IsDisabledControlJustPressed(0, 191) then
            confirmed = true
            self.enabled = false
            break
        end

        if IsDisabledControlJustPressed(0, 177) then
            cancelled = true
            self.enabled = false
            break
        end

        if IsDisabledControlJustPressed(0, 19) then
            PlaceObjectOnGroundProperly_2(entity)
        end

        local matrixBuffer = makeEntityMatrix(entity)
        local changed = Citizen.InvokeNative(0xEB2EDCA2, matrixBuffer:Buffer(), 'Editor1', Citizen.ReturnResultAnyway())

        if changed then
            applyEntityMatrix(entity, matrixBuffer)
        end
    end

    LeaveCursorMode()

    if DoesEntityExist(entity) then
        if IsEntityAPed(entity) then SetEntityAlpha(entity, 255, false) end
        SetEntityDrawOutline(entity, false)
        FreezeEntityPosition(entity, true)
        SetEntityCollision(entity, false, false)
    end

    if cancelled then
        SetEntityCoords(entity, initialCoords.x, initialCoords.y, initialCoords.z)
        SetEntityRotation(entity, initialRotation.x, initialRotation.y, initialRotation.z, 2, true)
        return false
    end

    return {
        entity = entity,
        position = GetEntityCoords(entity),
        rotation = GetEntityRotation(entity),
        confirmed = confirmed,
    }
end

function Gizmo:StopGizmo()
    self.enabled = false
end

function Gizmo:DeleteGizmo()
    self.enabled = false
end

lib.addKeybind({
    name = '_gizmoSelect',
    description = 'Robos (editor): seleccionar',
    defaultMapper = 'MOUSE_BUTTON',
    defaultKey = 'MOUSE_LEFT',
    onPressed = function(self)
        if not Gizmo.enabled then return end
        ExecuteCommand('+gizmoSelect')
    end,
    onReleased = function(self)
        ExecuteCommand('-gizmoSelect')
    end
})

lib.addKeybind({
    name = '_gizmoTranslation',
    description = 'Robos (editor): mover',
    defaultKey = 'W',
    onPressed = function(self)
        if not Gizmo.enabled then return end
        Gizmo.currentMode = 'Translate'
        ExecuteCommand('+gizmoTranslation')
    end,
    onReleased = function(self)
        ExecuteCommand('-gizmoTranslation')
    end
})

lib.addKeybind({
    name = '_gizmoRotation',
    description = 'Robos (editor): rotar',
    defaultKey = 'R',
    onPressed = function(self)
        if not Gizmo.enabled then return end
        Gizmo.currentMode = 'Rotate'
        ExecuteCommand('+gizmoRotation')
    end,
    onReleased = function(self)
        ExecuteCommand('-gizmoRotation')
    end
})

lib.addKeybind({
    name = '_gizmoLocal',
    description = 'Robos (editor): espacio local/mundo',
    defaultKey = 'Q',
    onPressed = function(self)
        if not Gizmo.enabled then return end
        Gizmo.isRelative = not Gizmo.isRelative
        ExecuteCommand('+gizmoLocal')
    end,
    onReleased = function(self)
        ExecuteCommand('-gizmoLocal')
    end
})