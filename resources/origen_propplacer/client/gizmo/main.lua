-- origen_propplacer | client/gizmo/main.lua
-- Gizmo nativo basado en origen_robberies (sin ox_lib)

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

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 14, true)
        DisableControlAction(0, 15, true)
        DisablePlayerFiring(PlayerId(), true)

        -- G → salir al modo raycast
        if IsDisabledControlJustPressed(0, 47) then
            self.enabled = false
            break
        end

        -- ENTER → confirmar
        if IsDisabledControlJustPressed(0, 191) then
            confirmed    = true
            self.enabled = false
            break
        end

        -- BACKSPACE → cancelar
        if IsDisabledControlJustPressed(0, 177) then
            cancelled    = true
            self.enabled = false
            break
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

    LeaveCursorMode()

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
-- Keybinds nativos (sin ox_lib)
-- ─────────────────────────────────────────────
RegisterCommand('+pp_gizmoSelect', function()
    if not Gizmo.enabled then return end
    ExecuteCommand('+gizmoSelect')
end, false)
RegisterCommand('-pp_gizmoSelect', function()
    ExecuteCommand('-gizmoSelect')
end, false)
RegisterKeyMapping('+pp_gizmoSelect', 'Colocar objetos: seleccionar', 'MOUSE_BUTTON', 'MOUSE_LEFT')

RegisterCommand('+pp_gizmoTranslation', function()
    if not Gizmo.enabled then return end
    Gizmo.currentMode = 'Translate'
    ExecuteCommand('+gizmoTranslation')
end, false)
RegisterCommand('-pp_gizmoTranslation', function()
    ExecuteCommand('-gizmoTranslation')
end, false)
RegisterKeyMapping('+pp_gizmoTranslation', 'Colocar objetos: mover', 'keyboard', 'W')

RegisterCommand('+pp_gizmoRotation', function()
    if not Gizmo.enabled then return end
    Gizmo.currentMode = 'Rotate'
    ExecuteCommand('+gizmoRotation')
end, false)
RegisterCommand('-pp_gizmoRotation', function()
    ExecuteCommand('-gizmoRotation')
end, false)
RegisterKeyMapping('+pp_gizmoRotation', 'Colocar objetos: rotar', 'keyboard', 'R')

RegisterCommand('+pp_gizmoLocal', function()
    if not Gizmo.enabled then return end
    Gizmo.isRelative = not Gizmo.isRelative
    ExecuteCommand('+gizmoLocal')
end, false)
RegisterCommand('-pp_gizmoLocal', function()
    ExecuteCommand('-gizmoLocal')
end, false)
RegisterKeyMapping('+pp_gizmoLocal', 'Colocar objetos: espacio local/mundo', 'keyboard', 'Q')
