-- origen_vehicleseats | client/gizmo/main.lua
-- Gizmo nativo adaptado para posicionamiento de asientos

Gizmo = {
    enabled     = false,
    entity      = nil,
    currentMode = 'Translate',
    isRelative  = false,
}

-- ─────────────────────────────────────────────
-- Helpers de matriz
-- ─────────────────────────────────────────────
local function normalize(x, y, z)
    local len = math.sqrt(x * x + y * y + z * z)
    if len == 0 then return 0, 0, 0 end
    return x / len, y / len, z / len
end

local function makeEntityMatrix(entity)
    local f, r, u, a = GetEntityMatrix(entity)
    local view = DataView.ArrayBuffer(64)
    view:SetFloat32(0,  r[1]):SetFloat32(4,  r[2]):SetFloat32(8,  r[3]):SetFloat32(12, 0)
    view:SetFloat32(16, f[1]):SetFloat32(20, f[2]):SetFloat32(24, f[3]):SetFloat32(28, 0)
    view:SetFloat32(32, u[1]):SetFloat32(36, u[2]):SetFloat32(40, u[3]):SetFloat32(44, 0)
    view:SetFloat32(48, a[1]):SetFloat32(52, a[2]):SetFloat32(56, a[3]):SetFloat32(60, 1)
    return view
end

local function applyEntityMatrix(entity, view)
    local x1, y1, z1 = view:GetFloat32(16), view:GetFloat32(20), view:GetFloat32(24)
    local x2, y2, z2 = view:GetFloat32(0),  view:GetFloat32(4),  view:GetFloat32(8)
    local x3, y3, z3 = view:GetFloat32(32), view:GetFloat32(36), view:GetFloat32(40)
    local tx, ty, tz = view:GetFloat32(48), view:GetFloat32(52), view:GetFloat32(56)
    x1, y1, z1 = normalize(x1, y1, z1)
    x2, y2, z2 = normalize(x2, y2, z2)
    x3, y3, z3 = normalize(x3, y3, z3)
    SetEntityMatrix(entity, x1, y1, z1, x2, y2, z2, x3, y3, z3, tx, ty, tz)
end

-- ─────────────────────────────────────────────
-- StartGizmo — bloquea hasta confirmar/cancelar
-- Retorna tabla con posición/rotación o false si cancelado
-- ─────────────────────────────────────────────
function Gizmo:StartGizmo(entity)
    if self.enabled then return false end

    self.enabled     = true
    self.entity      = entity
    self.currentMode = 'Translate'
    self.cursorActive = true

    local initialCoords   = GetEntityCoords(entity)
    local initialRotation = GetEntityRotation(entity)
    local confirmed = false
    local cancelled = false

    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, false, false)
    SetEntityDrawOutline(entity, true)
    EnterCursorMode()

    while self.enabled and DoesEntityExist(entity) do
        Wait(0)

        DisableControlAction(0, 24, true)   -- Attack (Left click)
        DisableControlAction(0, 25, true)   -- Aim (Right click)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 14, true)
        DisableControlAction(0, 15, true)
        DisablePlayerFiring(PlayerId(), true)

        -- Handle Right-Click Camera Look Around
        local isRightClickPressed = IsDisabledControlPressed(0, 25) or IsControlPressed(0, 25)
        if isRightClickPressed then
            if self.cursorActive then
                LeaveCursorMode()
                self.cursorActive = false
            end
        else
            if not self.cursorActive then
                EnterCursorMode()
                self.cursorActive = true
            end
        end

        -- Control camera looking depending on mouse mode
        if self.cursorActive then
            DisableControlAction(0, 1, true) -- Look Left/Right
            DisableControlAction(0, 2, true) -- Look Up/Down
        else
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
        end

        -- ENTER → confirmar
        if IsDisabledControlJustPressed(0, 191) then
            confirmed    = true
            self.enabled = false
            break
        end

        -- BACKSPACE → cancelar
        if IsDisabledControlJustPressed(0, 177) then
            -- Prevent Right Click from triggering cellular cancel (177)
            local isRightClick = IsDisabledControlPressed(0, 25) or IsControlPressed(0, 25) or IsDisabledControlJustPressed(0, 25)
            if not isRightClick then
                cancelled    = true
                self.enabled = false
                break
            end
        end

        -- ALT → ajustar al suelo
        if IsDisabledControlJustPressed(0, 19) then
            PlaceObjectOnGroundProperly(entity)
        end

        local matrixBuffer = makeEntityMatrix(entity)
        local changed = Citizen.InvokeNative(
            0xEB2EDCA2,
            matrixBuffer:Buffer(),
            'Editor1',
            Citizen.ReturnResultAnyway()
        )
        if changed then
            applyEntityMatrix(entity, matrixBuffer)
        end
    end

    if self.cursorActive then
        LeaveCursorMode()
        self.cursorActive = false
    end

    if DoesEntityExist(entity) then
        SetEntityDrawOutline(entity, false)
        FreezeEntityPosition(entity, true)
        SetEntityCollision(entity, false, false)
    end

    if cancelled then
        if DoesEntityExist(entity) then
            SetEntityCoords(entity, initialCoords.x, initialCoords.y, initialCoords.z)
            SetEntityRotation(entity, initialRotation.x, initialRotation.y, initialRotation.z, 2, true)
        end
        return false
    end

    return {
        entity    = entity,
        position  = GetEntityCoords(entity),
        rotation  = GetEntityRotation(entity),
        confirmed = confirmed,
    }
end

function Gizmo:StopGizmo()
    self.enabled = false
end

function Gizmo:DeleteGizmo()
    self.enabled = false
end

-- ─────────────────────────────────────────────
-- Keybinds nativos
-- ─────────────────────────────────────────────
RegisterCommand('+vs_gizmoSelect', function()
    if not Gizmo.enabled then return end
    ExecuteCommand('+gizmoSelect')
end, false)
RegisterCommand('-vs_gizmoSelect', function()
    ExecuteCommand('-gizmoSelect')
end, false)
RegisterKeyMapping('+vs_gizmoSelect', 'Creador de asientos: seleccionar', 'MOUSE_BUTTON', 'MOUSE_LEFT')

RegisterCommand('+vs_gizmoTranslation', function()
    if not Gizmo.enabled then return end
    Gizmo.currentMode = 'Translate'
    ExecuteCommand('+gizmoTranslation')
end, false)
RegisterCommand('-vs_gizmoTranslation', function()
    ExecuteCommand('-gizmoTranslation')
end, false)
RegisterKeyMapping('+vs_gizmoTranslation', 'Creador de asientos: mover', 'keyboard', 'W')

RegisterCommand('+vs_gizmoRotation', function()
    if not Gizmo.enabled then return end
    Gizmo.currentMode = 'Rotate'
    ExecuteCommand('+gizmoRotation')
end, false)
RegisterCommand('-vs_gizmoRotation', function()
    ExecuteCommand('-gizmoRotation')
end, false)
RegisterKeyMapping('+vs_gizmoRotation', 'Creador de asientos: rotar', 'keyboard', 'R')

RegisterCommand('+vs_gizmoLocal', function()
    if not Gizmo.enabled then return end
    Gizmo.isRelative = not Gizmo.isRelative
    ExecuteCommand('+gizmoLocal')
end, false)
RegisterCommand('-vs_gizmoLocal', function()
    ExecuteCommand('-gizmoLocal')
end, false)
RegisterKeyMapping('+vs_gizmoLocal', 'Creador de asientos: espacio local/mundo', 'keyboard', 'Q')
