Placement = {
    active = false,
    model = nil,
    object = nil,

    vehicle = nil,
    markers = {},
}

function Placement:new(data, model)
    data = data or {}
    setmetatable(data, self)
    self.__index = self
    self.model = model
    return data
end

function Placement:createPlacement()
    self.model = GetHashKey(self.model)
    
    lib.requestModel(self.model)

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)

    self.object = CreateObject(self.model, coords.x + forward.x, coords.y + forward.y, coords.z + forward.z)

    SetEntityCollision(self.object, false, false)
    SetEntityAlpha(self.object, 200, false)
    SetModelAsNoLongerNeeded(self.model)

    Nui.ControlsNotify({
        keys = {
            { key= 'enter', text = Config.Translations.controls.confirm },
            { key= 'wheel', text = Config.Translations.controls.rotate },
            { key= 'farriba', text = Config.Translations.controls.up },
            { key= 'fabajo', text = Config.Translations.controls.down },
            { key= 'shift', text = Config.Translations.controls.slowmode },
            { key= 'borrar', text = Config.Translations.controls.cancel },
        }
    })

    self.active = true

    LocalPlayer.state:set('IsBusy', true, true)

    local initialHeight = 0
    local timer = 0
    
    while self.active do 
        local hit, coords = Utils.GetScreenCoords()

        SetEntityCoords(self.object, coords.x, coords.y, coords.z + initialHeight, false, false, false, true)

        local coords = GetEntityCoords(self.object)
        local rotation = GetEntityRotation(self.object)
        local rotationMultiplier = IsControlPressed(0, 21) and 1.0 or 5.0
        local heightMultiplier = IsControlPressed(0, 21) and 0.1 or 0.5

        if IsControlPressed(0, 14) then
            SetEntityRotation(self.object, rotation.x, rotation.y, rotation.z + rotationMultiplier, 1, true)
        elseif IsControlPressed(0, 15) then
            SetEntityRotation(self.object, rotation.x, rotation.y, rotation.z - rotationMultiplier, 1, true)
        end

        if IsControlPressed(0, 188) and (GetGameTimer() - timer) > 15 then 
            initialHeight = initialHeight + heightMultiplier
            SetEntityCoords(obj, coords.x, coords.y, coords.z + initialHeight)
            timer = GetGameTimer()
        elseif IsControlPressed(0, 187) and (GetGameTimer() - timer) > 15 then 
            initialHeight = initialHeight - heightMultiplier
            SetEntityCoords(obj, coords.x, coords.y, coords.z + initialHeight)
            timer = GetGameTimer()
        end

        if IsControlJustPressed(0, 177) then
            self:stopPlacement()
        end

        if IsControlJustPressed(0, 191) then
            local coords = GetEntityCoords(self.object)
            local heading = GetEntityHeading(self.object)
            return vector4(coords.x, coords.y, coords.z, heading)
        end

        Utils.DisableControls({24, 25})

        Wait(0)
    end
end

function Placement:stopPlacement()
    Nui.ControlsNotify()
    DeleteEntity(self.object)
    self.active = false
    self.object = nil

    LocalPlayer.state:set('IsBusy', false, true)
end


function Placement:CreateVehicle()
    lib.requestModel('kamacho')
    self.vehicle = CreateVehicle('kamacho', 0, 0, 0, 0, false, false)
    SetEntityCollision(self.vehicle, false, true)
    SetEntityAlpha(self.vehicle, 200)
    SetModelAsNoLongerNeeded(self.model)
end

function Placement:placeMarkers(stage, reposition)
    self.active = true
    local stage = stage or 0
    local rotation = 0.0
    self.markers = {}

    local controls = {
        title = Config.Translations.controls.entry,
        keys = {
            { key= 'enter', text = Config.Translations.controls.confirm },
            { key= 'borrar', text = Config.Translations.controls.cancel },
        }
    }

    LocalPlayer.state:set('IsBusy', true, true)

    Nui.ControlsNotify(controls)

    while self.active do 
        
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        local hit, coords = Utils.GetScreenCoords()

        DrawLine(pedCoords.x, pedCoords.y, pedCoords.z, coords.x, coords.y, coords.z, 255, 255, 255, 255)

        -- Casa de banda o de crew: la entrada y el garaje van dentro del
        -- territorio de la banda o crew (custom/client/propietario.lua). Se pinta su contorno y el
        -- punto sale en rojo, y no se puede confirmar, mientras caiga fuera.
        local fuera = false
        if PropietarioCliente and PropietarioCliente.Limite() then
            PropietarioCliente.DibujarLimite(pedCoords.z)
            fuera = PropietarioCliente.Fuera(coords)
        end
        local mr, mg, mb = 216, 27, 85
        if fuera then mr, mg, mb = 235, 20, 20 end

        if stage == 0 then
            --[[ if self.vehicle then
                DeleteEntity(self.vehicle)
                self.vehicle = nil
            end ]]

            DrawMarker(20, coords.x, coords.y, coords.z + 1, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.3, 0.3, 0.3, mr, mg, mb, 200, true, true, 2, nil, nil, false)

            if IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) then
                stage = 0
                self.markers = {}
            end
        elseif stage == 1 then
            --[[ if not self.vehicle then
                self:CreateVehicle()
            end

            if self.vehicle then 
                SetEntityCoords(self.vehicle, coords.x, coords.y, coords.z)
                SetEntityRotation(self.vehicle, 0, 0, rotation, 2)

                if IsControlPressed(0, 241) or IsDisabledControlPressed(0, 241) then
                    rotation = rotation + 10.0
                    if rotation > 360.0 then
                        rotation = 0.0
                    end
                end
        
                if IsControlPressed(0, 242) or IsDisabledControlPressed(0, 242) then
                    rotation = rotation - 10.0
                    if rotation < 0.0 then
                        rotation = 360.0
                    end
                end
            end ]]

            DrawMarker(20, coords.x, coords.y, coords.z + 1, 0.0, 0.0, 0.0, 90.0, rotation - 180, 0.0, 0.3, 0.3, 0.3, mr, mg, mb, 255, false, false, 0, false)

            if IsControlPressed(0,241) then
                rotation = rotation + 10.0
                if rotation > 360.0 then
                    rotation = 0.0
                end
            end
    
            if IsControlPressed(0,242) then
                rotation = rotation - 10.0
                if rotation < 0.0 then
                    rotation = 360.0
                end
            end
        end

        if IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) then
            if stage == 0 then 
                self.active = false
            else
                if not reposition then 
                    stage = 0
                    Nui.ControlsNotify(controls)
                    self.markers = {}
                else
                    self.active = false
                end
            end
        end

        DisableControlAction(0, 24, true)
        if (IsControlJustPressed(0, 176) or IsDisabledControlJustPressed(0, 176)) or (IsControlJustPressed(0, 215) or IsDisabledControlJustPressed(0, 215)) or (IsControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 191)) or (IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201)) then
            if fuera then
                PropietarioCliente.AvisarFuera()
            elseif stage == 0 then
                self.markers['entry'] = {
                    type = 'entry',
                    coords = vector4(coords.x, coords.y, coords.z, 0.0),
                }
                if not reposition then 
                    stage = 1
                    Nui.ControlsNotify({
                        title = Config.Translations.controls.garage,
                        keys = {
                            { key= 'enter', text = Config.Translations.controls.confirm },
                            { key= 'wheel', text = Config.Translations.controls.rotate },
                            { key= 'borrar', text = Config.Translations.controls.back },
                        }
                    })
                else
                    self.active = false
                end
            elseif stage == 1 then
                if not reposition then 
                    local entryCoords = self.markers['entry']
                    if not entryCoords then return end
                    local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(entryCoords.coords.x, entryCoords.coords.y, entryCoords.coords.z))
                    if distance >= 5.0 then
                        self.markers['garage'] = {
                            type = 'garage',
                            coords = vector4(coords.x, coords.y, coords.z, rotation),
                        }
                        self.active = false
                    else
                        Internal.Notify(Config.Translations.notify.error.tooCloseMarker, 'error', 5000)
                    end
                else
                    self.markers['garage'] = {
                        type = 'garage',
                        coords = vector4(coords.x, coords.y, coords.z, rotation),
                    }
                    self.active = false
                end
            end
        end
        
        Wait(0)
    end

    --[[ if self.vehicle then
        DeleteEntity(self.vehicle)
        self.vehicle = nil
    end ]]

    Nui.ControlsNotify()

    LocalPlayer.state:set('IsBusy', false, true)

    return self.markers
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if Placement.vehicle then DeleteEntity(Placement.vehicle) end
end)