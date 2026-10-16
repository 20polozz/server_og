--[[ ══ Las fotos automaticas de los coches ══════════════════════════════════

     Traido de la version de la tienda (client/photos.lua) con tres cambios:

     - La captura sale de screencapture, que en este servidor hace de
       screenshot-basic (`provide 'screenshot-basic'`). Se llama por el nombre
       de screenshot-basic, que es el export que imita.
     - La foto no se guarda en el disco del recurso: va a fivemanage por
       origen_uploader (ver server/fotos.lua, el porque).
     - Renewed-Weathersync pisa el clima y la hora cada pocos segundos; se le
       quita la sincronizacion mientras dura la sesion y se le devuelve al
       terminar.

     El recorte del fondo verde lo hace la interfaz en un canvas: aqui se saca
     la captura cruda, se le pasa a la NUI y se espera a que diga si la subio. ]]

local CAPTURA = 'screenshot-basic'
local CAPTURA_REAL = 'screencapture'

local capturing = false
local cancelRequested = false
local pendingPhoto = nil

local function arrancado(recurso)
    local estado = GetResourceState(recurso)
    return estado == 'started' or estado == 'starting'
end

local function isScreenshotAvailable()
    return arrancado(CAPTURA) or arrancado(CAPTURA_REAL)
end

local function requestScreenshot()
    local result, done = nil, false

    exports[CAPTURA]:requestScreenshot({ encoding = 'png', quality = 1.0 }, function(data)
        result = data
        done = true
    end)

    local timeout = GetGameTimer() + 10000
    while not done and GetGameTimer() < timeout do
        Wait(0)
    end

    return result
end

-- Espera a que la NUI recorte la foto y la suba. La subida va por un envio
-- latente y luego a fivemanage, asi que se le da bastante mas que en la tienda.
local function processInNui(model, dataUri)
    pendingPhoto = { model = model, done = false, success = false, url = nil }

    SendNUIMessage({
        action = 'processVehiclePhoto',
        model = model,
        image = dataUri
    })

    local timeout = GetGameTimer() + 60000
    while pendingPhoto and not pendingPhoto.done and GetGameTimer() < timeout do
        Wait(10)
    end

    local url = pendingPhoto and pendingPhoto.done and pendingPhoto.success and pendingPhoto.url or nil
    pendingPhoto = nil

    return url
end

local function buildCamera(vehicle, modelHash)
    local min, max = GetModelDimensions(modelHash)
    local size = max - min
    local largest = math.max(size.x, size.y, size.z)

    local coords = GetEntityCoords(vehicle, false)
    local center = vector3(
        coords.x + (min.x + max.x) / 2,
        coords.y + (min.y + max.y) / 2,
        coords.z + (min.z + max.z) / 2
    )

    local orbit = math.rad(Config.VehiclePhotos.camera.orbit)
    local distance = largest + Config.VehiclePhotos.camera.distance

    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        center.x + distance * math.cos(orbit),
        center.y + distance * math.sin(orbit),
        center.z + size.z / 2,
        0.0, 0.0, 0.0,
        Config.VehiclePhotos.camera.fov + 0.0, true, 0)

    PointCamAtCoord(cam, center.x, center.y, center.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false, 0)

    return cam
end

-- El equilibrio de color de la caja verde, el mismo contra el que recorta la
-- NUI. Sirve para rechazar colores de la paleta que el recorte se comeria.
local KEY_CHROMA_R, KEY_CHROMA_G = 0.058, 0.797
local PALETTE_SAFETY_MARGIN = 0.05

local function chromaDistanceFromBackdrop(colour)
    local sum = colour.r + colour.g + colour.b
    if sum <= 0 then return 1.0 end

    return math.max(
        math.abs(colour.r / sum - KEY_CHROMA_R),
        math.abs(colour.g / sum - KEY_CHROMA_G)
    )
end

local safePalette

local function getSafePalette()
    if safePalette ~= nil then
        return safePalette ~= false and safePalette or nil
    end

    local palette = Config.VehiclePhotos.vehicleColours
    if type(palette) ~= 'table' or #palette == 0 then
        safePalette = false
        return nil
    end

    local limit = Config.VehiclePhotos.output.chromaToleranceEdge + PALETTE_SAFETY_MARGIN
    local accepted = {}

    for i = 1, #palette do
        local colour = palette[i]
        if chromaDistanceFromBackdrop(colour) <= limit then
            Debug.warning(true, ('[DEALERSHIPS] El color %d de la paleta de fotos, rgb(%d,%d,%d), se parece demasiado al verde: el recorte se comeria el coche. No se usa.')
                :format(i, colour.r, colour.g, colour.b))
        else
            accepted[#accepted + 1] = colour
        end
    end

    if #accepted == 0 then
        Debug.warning(true, '[DEALERSHIPS] No queda ningun color valido en la paleta de fotos; los coches salen con su pintura de serie.')
        safePalette = false
        return nil
    end

    safePalette = accepted
    return accepted
end

-- El mismo modelo cae siempre en el mismo color: rehacer una foto no lo repinta
local function paletteColourFor(palette, model)
    local hash = 7
    for i = 1, #model do
        hash = (hash * 31 + model:byte(i)) % 2147483647
    end

    return palette[(hash % #palette) + 1]
end

--- @return string|nil la direccion de la foto subida
local function captureModel(model)
    local hash = joaat(model)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end

    if not HasModelLoaded(hash) then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end

    local spot = Config.VehiclePhotos.captureCoords
    local vehicle = CreateVehicle(hash, spot.x, spot.y, spot.z, Config.VehiclePhotos.captureHeading + 0.0, false, false)

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end

    SetEntityRotation(vehicle, 0.0, 0.0, Config.VehiclePhotos.captureHeading + 0.0, 0, false)
    SetVehicleDirtLevel(vehicle, 0.0)
    -- Sin kit de mods algunos modelos ignoran el tintado y la pintura de abajo
    SetVehicleModKit(vehicle, 0)
    -- Lunas oscuras: se ve menos verde a traves del cristal
    SetVehicleWindowTint(vehicle, 1)

    local palette = getSafePalette()
    if palette then
        local paint = paletteColourFor(palette, model)
        SetVehicleCustomPrimaryColour(vehicle, paint.r, paint.g, paint.b)
        SetVehicleCustomSecondaryColour(vehicle, paint.r, paint.g, paint.b)
        SetVehicleExtraColours(vehicle, 0, 0)
    end

    FreezeEntityPosition(vehicle, true)

    Wait(Config.VehiclePhotos.delays.spawn)

    local cam = buildCamera(vehicle, hash)

    Wait(Config.VehiclePhotos.delays.settle)

    local shot = requestScreenshot()
    local url = nil

    if shot then
        url = processInNui(model, shot)
    end

    RenderScriptCams(false, false, 0, true, false, 0)
    DestroyCam(cam, true)
    DeleteEntity(vehicle)
    SetModelAsNoLongerNeeded(hash)

    return url
end

-- ESC y retroceso. La NUI no tiene el foco mientras se sacan las fotos (el
-- juego tiene que seguir pintando), asi que las teclas se leen aqui. Se
-- desactivan antes para que el ESC no abra ademas el menu de pausa.
local CANCEL_CONTROLS = { 200, 202, 177 }

local function applyStudioWeather()
    SetRainLevel(0.0)
    SetWeatherTypePersist('EXTRASUNNY')
    SetWeatherTypeNow('EXTRASUNNY')
    SetWeatherTypeNowPersist('EXTRASUNNY')
    NetworkOverrideClockTime(12, 0, 0)
end

-- El radar y el HUD del juego se pintan en la misma imagen que se captura.
-- La hora se fija en cada vuelta: el sincronizador, al soltarlo, la pone a las
-- nueve de la noche una vez.
local function startHudHider()
    CreateThread(function()
        while capturing do
            HideHudAndRadarThisFrame()
            HideHelpTextThisFrame()
            NetworkOverrideClockTime(12, 0, 0)

            for i = 1, #CANCEL_CONTROLS do
                DisableControlAction(0, CANCEL_CONTROLS[i], true)
            end

            if not cancelRequested then
                for i = 1, #CANCEL_CONTROLS do
                    if IsDisabledControlJustPressed(0, CANCEL_CONTROLS[i]) then
                        cancelRequested = true
                        SendNUIMessage({ action = 'vehiclePhotoCancelling' })
                        break
                    end
                end
            end

            Wait(0)
        end
    end)
end

--- Renewed-Weathersync: con syncWeather a false deja de pisar clima y hora, y
--- repite `playerWeather` cada 2,5 s. Se devuelve como estaba.
local function pausarClima()
    local estado = LocalPlayer.state
    local antes = { sync = estado.syncWeather, clima = estado.playerWeather }

    estado.playerWeather = 'EXTRASUNNY'
    estado.syncWeather = false

    return antes
end

local function devolverClima(antes)
    local estado = LocalPlayer.state

    estado.playerWeather = antes.clima
    estado.syncWeather = antes.sync

    if antes.sync == nil then
        -- Sin sincronizador que lo lleve: se suelta a mano
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        NetworkClearClockTimeOverride()
    end
end

local function spawnBackdrop()
    local backdrop = Config.VehiclePhotos.backdrop
    if not backdrop or not backdrop.model then return nil end

    local hash = joaat(backdrop.model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        Debug.warning(true, '[DEALERSHIPS] No se encuentra la caja verde: ' .. tostring(backdrop.model))
        return nil
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end

    if not HasModelLoaded(hash) then
        Debug.warning(true, '[DEALERSHIPS] La caja verde no ha cargado: ' .. tostring(backdrop.model))
        return nil
    end

    -- Centrada en el punto de captura y con el suelo en el, este donde este el
    -- pivote del modelo
    local min, max = GetModelDimensions(hash)
    local localX = (min.x + max.x) / 2
    local localY = (min.y + max.y) / 2

    local heading = backdrop.heading + 0.0
    local rad = math.rad(heading)
    local rotatedX = localX * math.cos(rad) - localY * math.sin(rad)
    local rotatedY = localX * math.sin(rad) + localY * math.cos(rad)

    local spot = Config.VehiclePhotos.captureCoords
    local offset = backdrop.offset or vec3(0.0, 0.0, 0.0)

    local object = CreateObjectNoOffset(hash,
        spot.x - rotatedX + offset.x,
        spot.y - rotatedY + offset.y,
        spot.z - min.z + offset.z,
        false, false, false)

    SetEntityRotation(object, 0.0, 0.0, heading, 0, false)
    FreezeEntityPosition(object, true)
    SetModelAsNoLongerNeeded(hash)

    return object
end

local function IsVehiclePhotoCaptureAvailable()
    return Config.VehiclePhotos.enabled and isScreenshotAvailable() and arrancado('origen_uploader')
end

local function ReportProcessedPhoto(model, success, url)
    if pendingPhoto and pendingPhoto.model == model then
        pendingPhoto.success = success and true or false
        pendingPhoto.url = url
        pendingPhoto.done = true
    end
end

local function GenerateVehiclePhotos(models)
    if capturing then
        return { success = false, error = 'busy' }
    end

    if not Config.VehiclePhotos.enabled then
        return { success = false, error = 'disabled' }
    end

    if not isScreenshotAvailable() then
        return { success = false, error = 'screenshot_basic_missing' }
    end

    if not arrancado('origen_uploader') then
        return { success = false, error = 'uploader_missing' }
    end

    if type(models) ~= 'table' or #models == 0 then
        return { success = false, error = 'no_models' }
    end

    capturing = true
    cancelRequested = false
    startHudHider()

    local ped = PlayerPedId()
    local originalCoords = GetEntityCoords(ped, false)
    local originalHeading = GetEntityHeading(ped)
    local playerId = PlayerId()

    -- Su propio routing bucket: nadie mas ve la caja ni los coches
    lib.callback.await('origen_dealership:routingBucketHandler', false, true)

    SetNuiFocus(false, false)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    local spot = Config.VehiclePhotos.captureCoords
    local hiddenOffset = Config.VehiclePhotos.hiddenOffset
    SetEntityCoordsNoOffset(ped,
        spot.x + hiddenOffset.x,
        spot.y + hiddenOffset.y,
        spot.z + hiddenOffset.z,
        false, false, false)
    SetEntityVisible(ped, false, false)
    SetPlayerControl(playerId, false, 0)
    FreezeEntityPosition(ped, true)
    DisableIdleCamera(true)

    local clima = pausarClima()
    Wait(100)
    applyStudioWeather()

    local backdrop = spawnBackdrop()

    ClearAreaOfVehicles(spot.x, spot.y, spot.z, 25.0, false, false, false, false, false)

    Wait(500)
    DoScreenFadeIn(500)

    local generated, failed = {}, {}

    -- Pase lo que pase dentro, hay que llegar a la restauracion de abajo: si no,
    -- el admin se queda congelado, invisible y sin control en su bucket
    local ok, err = pcall(function()
        for index = 1, #models do
            if cancelRequested then break end

            local model = models[index]

            SendNUIMessage({
                action = 'vehiclePhotoProgress',
                model = model,
                current = index,
                total = #models
            })

            applyStudioWeather()

            local url = captureModel(model)
            if url then
                generated[#generated + 1] = { model = model, url = url }
            else
                failed[#failed + 1] = model
            end
        end
    end)

    if not ok then
        Debug.error(true, '[DEALERSHIPS] Fallo sacando las fotos: ' .. tostring(err))
    end

    if backdrop and DoesEntityExist(backdrop) then
        DeleteEntity(backdrop)
    end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    RenderScriptCams(false, false, 0, true, false, 0)
    ClearFocus()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCoordsNoOffset(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false)
    SetEntityHeading(ped, originalHeading)
    SetPlayerControl(playerId, true, 0)
    DisableIdleCamera(false)

    capturing = false
    devolverClima(clima)

    lib.callback.await('origen_dealership:routingBucketHandler', false)

    Wait(250)
    DoScreenFadeIn(500)
    SetNuiFocus(true, true)

    if not ok then
        return { success = false, error = 'capture_error', generated = generated, failed = failed }
    end

    return {
        success = true,
        generated = generated,
        failed = failed,
        cancelled = cancelRequested
    }
end

-- ══ Lo que pide la interfaz ══════════════════════════════════════════════

RegisterNUICallback('origen_dealerships:ui:getPhotoCapabilities', function(data, cb)
    local fotos = {}

    if data and type(data.models) == 'table' and #data.models > 0 then
        fotos = lib.callback.await('origen_dealerships:sv:fotos:lista', false, data.models) or {}
    end

    cb({
        available = IsVehiclePhotoCaptureAvailable(),
        fotos = fotos,
        output = Config.VehiclePhotos.output
    })
end)

RegisterNUICallback('origen_dealerships:ui:getExtraPhotoModels', function(_, cb)
    local models = lib.callback.await('origen_dealerships:sv:fotos:modelosExtra', false) or {}
    local fotos = #models > 0 and lib.callback.await('origen_dealerships:sv:fotos:lista', false, models) or {}

    cb({ models = models, fotos = fotos })
end)

RegisterNUICallback('origen_dealerships:ui:generateVehicleImages', function(data, cb)
    cb(GenerateVehiclePhotos(data and data.models))
end)

-- La NUI ya ha quitado el fondo. De la NUI aqui no hay red y el tamaño da
-- igual; el salto al servidor va por el envio latente de origen_uploader.
RegisterNUICallback('origen_dealerships:ui:saveVehicleImage', function(data, cb)
    local model = data and data.model
    local base64 = data and type(data.image) == 'string' and data.image:match('^data:image/png;base64,(.+)$')

    if not model or not base64 then
        ReportProcessedPhoto(model, false)
        return cb({ success = false })
    end

    local resguardo, motivo = exports['origen_uploader']:PrepararSubida(('concesionario_%s.png'):format(model), base64)
    if not resguardo then
        Debug.warning(true, '[DEALERSHIPS] No se pudo enviar la foto de ' .. tostring(model) .. ': ' .. tostring(motivo))
        ReportProcessedPhoto(model, false)
        return cb({ success = false })
    end

    local result = lib.callback.await('origen_dealerships:sv:fotos:subir', false, {
        model = model,
        ticket = resguardo
    })

    local success = type(result) == 'table' and result.success or false
    if not success then
        Debug.warning(true, '[DEALERSHIPS] El servidor no guardo la foto de ' .. tostring(model) .. ': ' .. tostring(type(result) == 'table' and result.error or result))
    end

    ReportProcessedPhoto(model, success, success and result.url or nil)

    cb({ success = success })
end)
