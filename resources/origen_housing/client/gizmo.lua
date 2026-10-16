Gizmo = {
    enabled = false,
    entity = nil,
    mode = 'translate',
    restrictedZone = nil,
}

function Gizmo:new(data)
    data = data or {}
    setmetatable(data, self)
    self.__index = self
    return data
end

function Gizmo:ToggleState(state)
    SendNUIMessage({
        action = 'toggleState',
        data = {
            state = state
        }
    })
end

function Gizmo:StartGizmo(entity, restrictedZone)
    if self.enabled then 
        self:StopGizmo()
        Wait(200)
    end

    self:ToggleState(true)

    SetNuiFocus(true, true)

    self.enabled = true
    self.entity = entity

    Nui.ControlsNotify({
        title = Config.Translations.general.furniture,
        keys = {
            { key= 'R', text= Config.Translations.controls.toggleMode, },
            { key= 'ALT', text= Config.Translations.controls.placeOnGround },
            { key= 'H', text= Config.Translations.controls.toggleModetoMouse },
            { key= 'enter', text= Config.Translations.controls.finish },
        }
    })

    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = entity,
            position = GetEntityCoords(entity),
            rotation = GetEntityRotation(entity),
        }
    })

    if restrictedZone then
        self.restrictedZone = restrictedZone
    end


    while self.enabled do
        self:UpdateCameraPosition()

        Wait(0)
    end

    Nui.ControlsNotify()

    self:ToggleState(false)

    if not self.entity then return false end

    return {
        entity = entity,
        position = GetEntityCoords(self.entity),
        rotation = GetEntityRotation(self.entity),
    }
end

function Gizmo:UpdateCameraPosition()
    SendNUIMessage({
        action = 'setCameraPosition',
        data = {
            position = GetFinalRenderedCamCoord(),
            rotation = GetFinalRenderedCamRot()
        }
    })
end

function Gizmo:StopGizmo()
    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = nil,
        }
    })
    self:ToggleState(false)
    self.enabled = false
    Nui.ControlsNotify()
    SetNuiFocus(false, false)

    Wait(200)
    self.entity = nil
end

function Gizmo:DeleteGizmo()
    -- Como StopGizmo: sin quitarle la entidad a la pagina, el gizmo seguia
    -- pintado y agarrable sin nada detras en Lua.
    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = nil,
        }
    })
    self.entity = nil
    self:ToggleState(false)
    self.enabled = false
    Nui.ControlsNotify()
    SetNuiFocus(false, false)
end

RegisterNUICallback('moveEntity', function(data, cb)
    local entity = data.handle
    local position = data.position
    local rotation = data.rotation

    if Gizmo.restrictedZone then
        local isInside = Utils.isInsidePolyzone(position, Gizmo.restrictedZone)

        if isInside then
            SetEntityCoords(entity, position.x, position.y, position.z)
            SetEntityRotation(entity, rotation.x, rotation.y, rotation.z)
        end
    else
        SetEntityCoords(entity, position.x, position.y, position.z)
        SetEntityRotation(entity, rotation.x, rotation.y, rotation.z)
    end
    cb('ok')
end)

RegisterNUICallback('placeOnGround', function(data, cb)
    local entity = data.handle
    PlaceObjectOnGroundProperly(entity)

    local data = {
        position = GetEntityCoords(entity),
        rotation = GetEntityRotation(entity),
    }
    cb(json.encode(data))
end)

RegisterNUICallback('finishEdit', function(data, cb)
    -- Un Enter de mas con el gizmo ya cerrado soltaba el foco del menu.
    if not Gizmo.enabled then return cb('ok') end
    Gizmo:StopGizmo()
    cb('ok')
end)

RegisterNUICallback('cancelEdit', function(data, cb)
    Gizmo:DeleteGizmo()
    Furniture:CancelEdit()
    cb('ok')
end)

RegisterNUICallback('swapMode', function(data, cb)
    local mode = data.mode:lower()
    Gizmo.mode = mode
    -- La cinta de decorar (custom/client/obra.lua) da la vuelta a los modos con la R
    if Gizmo.alCambiarModo then Gizmo.alCambiarModo(mode) end
    cb('ok')
end)