Preview = {
    cam = nil,
    object = nil,
    _type = nil,
    items = {},
    current = nil,
    selected = nil,
}

local tempObject = nil

function Preview:new(data, ctype, current, items)
    data = data or {}
    setmetatable(data, self)
    self.__index = self
    self._type = ctype
    self.items = items
    self.current = current
    return data
end

RegisterNuiCallback('previewShell', function(data, cb)
    local model = data.model --todo verificar que este en el config
    if model then
        Preview:createShellPreview(model, true, false)
        cb('ok')
    end
end)

function Preview:createExteriorPreview(model)
    Nui.togglePreviewOpacity(false)
    
    DoScreenFadeOut(500)
    Wait(500)
    Internal.DisableWeatherSync()
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    FreezeEntityPosition(ped, true)
    local box = Utils.CreateMainBox()
    local model = GetHashKey(model)

    if not HasModelLoaded(model) then
        lib.requestModel(model)
        while not HasModelLoaded(model) do
            debugger('Loading model ' .. model)
            Wait(500)
        end
    end

    local boxCoords = GetEntityCoords(box)

    local entity = CreateObjectNoOffset(model, boxCoords.x, boxCoords.y, boxCoords.z - 19.0, false)
    SetEntityHeading(entity, 0.0)
    local entityCoords = GetEntityCoords(entity)
    local entityHeading = GetEntityHeading(entity)

    FreezeEntityPosition(entity, true)
    SetModelAsNoLongerNeeded(model)

    CreateThread(function()
        while entity do
            local rotation = GetEntityRotation(entity)
            SetEntityRotation(entity, rotation.x, rotation.y, rotation.z + 0.3, 2, true)
            Wait(0)
        end
    end)

    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', entityCoords.x + 30.0, entityCoords.y, entityCoords.z + 10.0, 0.0 ,0.0, entityHeading, GetGameplayCamFov(), 1, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 5, true, true)
    SetCamCoord(cam, entityCoords.x + 30.0, entityCoords.y, entityCoords.z + 10.0)
    SetCamRot(cam, -10.0, 0.0, 90.0, 2)
    SetFocusPosAndVel(vec3(entityCoords.x, entityCoords.y, entityCoords.z + 10.0),  0.0, 0.0, 0.0)
    DoScreenFadeIn(300)

    Nui.ControlsNotify({
        keys = {
            { key= 'E', text= Config.Translations.controls.exit, }
        }
    })

    LocalPlayer.state:set('IsBusy', true, true)

    while true do
        if IsControlJustPressed(0, 38) then
            break
        end
        Wait(0)
    end

    Nui.ControlsNotify()
    DoScreenFadeOut(250)
    Wait(300)
    DestroyCam(cam)
    RenderScriptCams(false, false, 0, true, true)
    Utils.CreateMainBox()
    DeleteEntity(entity)
    SetEntityCoords(PlayerPedId(), pedCoords)
    FreezeEntityPosition(ped, false)
    Internal.EnableWeatherSync()
    Wait(1000)
    DoScreenFadeIn(1000)
    Nui.togglePreviewOpacity(true)

    LocalPlayer.state:set('IsBusy', false, true)
end

RegisterNuiCallback('previewExterior', function(data, cb)
    local model = data.model --todo verificar que este en el config
    if model then
        Preview:createExteriorPreview(model)
        cb('ok')
    end
end)

if Config.Debug then
    RegisterCommand('previewShell', function(source, args, raw)
        local model = args[1]
        if model then
            Preview:createShellPreview(model, false, true)
        end
    end)
end

function Preview:createIPLPreview()
    local label = self.items[self.current].label
    local coords = self.items[self.current].cam
    
    DoScreenFadeOut(250)

    if self.cam then
        Wait(300)
        DestroyCam(self.cam)
        RenderScriptCams(false, false, 0, true, true)
        ClearFocus()
        self.cam = nil
    end
    
    Nui.SetLoading(true)
    Nui.SetTitleInfo(true, label)

    local interior = GetInteriorAtCoords(coords)
    if interior and interior ~= 0 then 
        local tries = 0
        LoadInterior(interior)
        while not IsInteriorReady(interior) do
            Wait(1000)
            LoadInterior(interior)
            tries = tries + 1
            if tries > 4 then
                self.current = self.current + 1
                if self.current > #self.items then
                    self.current = 1
                end
                self:createIPLPreview()
                break
            end
        end
    end
    self.cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', coords.x, coords.y, coords.z + 0.3, 0.0 ,0.0, coords.w, GetGameplayCamFov(), 1, 2)
    SetCamActive(self.cam, true)
    RenderScriptCams(true, false, 0, true, true)
    SetFocusPosAndVel(coords,  0.0, 0.0, 0.0)
    Wait(1000)
    Nui.SetLoading(false)
    Internal.DisableWeatherSync()

    Nui.ControlsNotify({
        title = self._type == 'garages' and 'Garage' or 'Interior',
        keys = {
            { key= 'enter', text = Config.Translations.controls.select },
            { key= 'fizquierda', text = Config.Translations.controls.previous },
            { key= 'fderecha', text = Config.Translations.controls.next },
            { key= 'borrar', text = Config.Translations.controls.exit },
        }
    })

    LocalPlayer.state:set('IsBusy', true, true)

    DoScreenFadeIn(300)

    while self.cam do
        SetFocusPosAndVel(coords, 0.0, 0.0, 0.0)

        if IsControlJustPressed(0, 174) or IsDisabledControlJustPressed(0, 174) then
            self.current = self.current - 1
            if self.current < 1 then
                self.current = #self.items
            end
            self:createIPLPreview()
            break
        end
        
        if IsControlJustPressed(0, 175) or IsDisabledControlJustPressed(0, 175) then
            self.current = self.current + 1
            if self.current > #self.items then
                self.current = 1
            end
            self:createIPLPreview()
            break
        end

        if IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) then
            self:destroyIPLPreview()
            self.selected = false
        end

        if IsControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 191) then
            self:destroyIPLPreview()
            self.selected = self.current
        end

        Wait(5)
    end

    return self.selected
end

function Preview:destroyIPLPreview()
    DoScreenFadeOut(250)
    Wait(300)
    if self.cam then
        DestroyCam(self.cam)
        RenderScriptCams(false, false, 0, true, true)
        ClearFocus()
        self.cam = nil
    end
    Nui.SetTitleInfo(false)
    Nui.ControlsNotify()
    Internal.EnableWeatherSync()
    Wait(700)
    DoScreenFadeIn(250)

    LocalPlayer.state:set('IsBusy', false, true)
end

function Preview:createShellPreview(model, panel, command)
    local modelData = __indexShells[model]
    if not modelData then return debugger('Model not found', model) end

    Nui.togglePreviewOpacity(false)
    
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    model = GetHashKey(model)

    lib.requestModel(model)

    local entity = CreateObject(model, coords.x, coords.y, 2000, false, false, false)
    if command then
        tempObject = entity
    end
    SetEntityHeading(entity, 300.0)
    FreezeEntityPosition(entity, true)
    SetModelAsNoLongerNeeded(model)
    DoScreenFadeOut(500)
    Internal.DisableWeatherSync()
    Wait(300)
    Nui.ControlsNotify({
        keys = {
            { key= 'E', text= Config.Translations.controls.exit },
        }
    })

    LocalPlayer.state:set('IsBusy', true, true)

    local offset = GetOffsetFromEntityInWorldCoords(entity, modelData.offset.x, modelData.offset.y, modelData.offset.z)
    SetEntityCoords(ped, offset.x, offset.y, offset.z)

    Wait(300)
    DoScreenFadeIn(300)

    while true do 
        if IsControlJustPressed(0, 38) then 
            break
        end
        Wait(0)
    end
    Wait(300)
    Internal.EnableWeatherSync()
    DoScreenFadeOut(300)
    SetEntityCoords(ped, coords)
    DeleteEntity(entity)
    Nui.ControlsNotify()
    Wait(300)
    DoScreenFadeIn(300)
    tempObject = nil
    if not command then
        Nui.togglePreviewOpacity(true)
    end

    LocalPlayer.state:set('IsBusy', false, true)
end

if Config.Debug then
    RegisterCommand('getoffset', function()
        local player_coords = GetEntityCoords(PlayerPedId())
        local offset = GetOffsetFromEntityGivenWorldCoords(tempObject, player_coords.x, player_coords.y, player_coords.z)
        lib.setClipboard('vector3('..offset.x .. ', ' .. offset.y .. ', ' .. offset.z .. ')')
    end)
end