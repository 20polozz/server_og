-- origen_vehicleseats | client/main.lua
-- Standalone implementation without ox_lib or qb-target dependencies

local currentVehicle = nil
local previewPed = nil
local isSitting = false
local sittingSeat = nil
local sittingVehNetId = nil
local sittingThreadActive = false

-- ── Custom Standalone Callback System ──
local callbacks = {}
local callbackId = 0

function TriggerServerCallback(name, cb, ...)
    callbackId = callbackId + 1
    callbacks[callbackId] = cb
    TriggerServerEvent('origen_vehicleseats:server:triggerCallback', name, callbackId, ...)
end

RegisterNetEvent('origen_vehicleseats:client:triggerCallback', function(id, ...)
    if callbacks[id] then
        callbacks[id](...)
        callbacks[id] = nil
    end
end)

-- ── Standalone Notification System ──
function ShowNotification(text, type)
    if GetResourceState('origen_notify') == 'started' then
        exports['origen_notify']:Notify({
            description = text,
            type = type or 'info',
            duration = 5000
        })
        return
    end

    -- Fallback: standard GTA V notification
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

-- Helper to find the closest vehicle (bypassing any native GTA V flags/occupied exclusions)
local function GetClosestVehicleNearPlayer(coords, radius)
    local vehicles = GetGamePool('CVehicle')
    local closestVeh = 0
    local minDist = radius

    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)
            local dist = #(coords - vehCoords)
            if dist < minDist then
                minDist = dist
                closestVeh = veh
            end
        end
    end
    return closestVeh
end

-- ── Abrir el creador sobre un vehiculo (lo usan el comando y el panel) ──
-- desdeGestion: abierto desde el panel de gestion; el pie dice «Volver».
local function AbrirCreador(veh, desdeGestion)
    currentVehicle = veh
    local modelName = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
    local allSeats = GlobalState.VehicleSeats or {}
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openCreator", modelName = modelName, seats = allSeats[modelName] or {}, desdeGestion = desdeGestion == true })
end

-- ── Admin seatcreator command ──
RegisterCommand('seatcreator', function()
    -- Check permissions using our standalone callback
    TriggerServerCallback('origen_vehicleseats:server:checkPermission', function(hasPerm)
        if not hasPerm then
            ShowNotification('No tienes permisos para usar este comando.', 'error')
            return
        end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then
            -- Find closest vehicle near player bypassing native occupied exclusions
            local coords = GetEntityCoords(ped)
            veh = GetClosestVehicleNearPlayer(coords, 5.0)
        end

        if veh == 0 or not DoesEntityExist(veh) then
            ShowNotification('Súbete o colócate cerca de un vehículo para usar el creador.', 'error')
            return
        end

        AbrirCreador(veh)
    end)
end, false)

RegisterKeyMapping('seatcreator', 'Creador de asientos: abrir', 'keyboard', '')

--[[ ── El panel de gestion (pestaña Scripts del admin) ──────────────────────
     A pantalla completa, como Gestion de Vivienda: una ficha por modelo con
     asientos. Vive en ui/gestion (source-ui), en un iframe de ui/index.html.
     Colocar o mover un asiento sigue siendo cosa del creador del mundo (el
     gizmo): el panel lo abre sobre el vehiculo de al lado o sobre uno que
     saca delante (local, solo lo ve el admin) y, al cerrar el creador,
     vuelve. ]]
local POSTURAS = {
    sit_normal = 'Sentado', trunk_sit = 'En el maletero', sunbathe_back = 'Tumbado boca arriba',
    sunbathe_front = 'Tumbado boca abajo', kneeling = 'De rodillas',
}
local gestionAbierta = false
local volverAGestion = false
local traido = nil   -- el vehiculo que saca el panel para editarlo

local function Cerca(radio)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then veh = GetClosestVehicleNearPlayer(c, radio or 6.0) end
    if veh == 0 or not DoesEntityExist(veh) then return nil end
    return veh, string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(veh))), #(GetEntityCoords(veh) - c)
end

local function DatosGestion()
    local modelos = {}
    for modelo, asientos in pairs(GlobalState.VehicleSeats or {}) do
        if type(asientos) == 'table' and #asientos > 0 then
            local t = {}
            for _, a in ipairs(asientos) do
                t[#t + 1] = { id = a.id, nombre = a.name or 'Asiento', postura = POSTURAS[a.preset] or 'A medida' }
            end
            modelos[#modelos + 1] = { modelo = modelo, asientos = t }
        end
    end
    table.sort(modelos, function(a, b) return a.modelo < b.modelo end)
    local ocupados = 0
    for _, s in pairs(GlobalState.OccupiedSeats or {}) do
        for _ in pairs(s) do ocupados = ocupados + 1 end
    end
    local _, modelo, dist = Cerca()
    return { modelos = modelos, ocupados = ocupados, cerca = modelo and { modelo = modelo, dist = dist } or nil }
end

local function AbrirGestion()
    gestionAbierta = true
    SetNuiFocus(true, true)
    SendNUIMessage({ a = 'gestion', datos = DatosGestion() })
    -- Lo de al lado cambia si se mueve uno: se refresca mientras esta abierto.
    CreateThread(function()
        while gestionAbierta do
            Wait(1500)
            if gestionAbierta then SendNUIMessage({ a = 'datos', datos = DatosGestion() }) end
        end
    end)
end

local function CerrarGestion()
    gestionAbierta = false
    SendNUIMessage({ a = 'cerrar' })
    SetNuiFocus(false, false)
end

local function QuitarTraido()
    if traido and DoesEntityExist(traido) then DeleteEntity(traido) end
    traido = nil
end

--- La tarjeta de la pestaña Scripts del admin llama a esto.
exports('openManagement', function()
    TriggerServerCallback('origen_vehicleseats:server:checkPermission', function(hasPerm)
        if not hasPerm then
            ShowNotification('No tienes permisos para gestionar los asientos.', 'error')
            return
        end
        AbrirGestion()
    end)
end)

RegisterNUICallback('gestion:cerrar', function(_, cb)
    cb('ok')
    CerrarGestion()
end)

RegisterNUICallback('gestion:editar', function(d, cb)
    local veh, modelo = Cerca()
    if not veh then return cb({ ok = false, motivo = 'No tienes ningún vehículo al lado.' }) end
    if d and d.modelo and d.modelo ~= modelo then
        return cb({ ok = false, motivo = ('El de al lado es un %s, no un %s.'):format(modelo:upper(), tostring(d.modelo):upper()) })
    end
    cb({ ok = true })
    CerrarGestion()
    volverAGestion = true
    AbrirCreador(veh, true)
end)

RegisterNUICallback('gestion:traer', function(d, cb)
    local nombre = (d and tostring(d.modelo or '') or ''):lower():gsub('%s', '')
    local hash = joaat(nombre)
    if nombre == '' or not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return cb({ ok = false, motivo = 'No hay ningún vehículo con ese nombre.' })
    end
    RequestModel(hash)
    local hasta = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < hasta do Wait(50) end
    if not HasModelLoaded(hash) then return cb({ ok = false, motivo = 'El modelo no carga. Prueba otra vez.' }) end
    QuitarTraido()
    local ped = PlayerPedId()
    local delante = GetOffsetFromEntityInWorldCoords(ped, 0.0, 5.0, 0.0)
    -- Local (no va por red): solo lo ve quien lo edita.
    traido = CreateVehicle(hash, delante.x, delante.y, delante.z, GetEntityHeading(ped) + 90.0, false, false)
    SetModelAsNoLongerNeeded(hash)
    SetVehicleOnGroundProperly(traido)
    FreezeEntityPosition(traido, true)
    SetVehicleDoorsLocked(traido, 2)
    cb({ ok = true })
    CerrarGestion()
    volverAGestion = true
    AbrirCreador(traido, true)
end)

RegisterNUICallback('gestion:borrar', function(d, cb)
    TriggerServerCallback('origen_vehicleseats:server:deleteSeat', function(r)
        if not r then return cb({ ok = false, motivo = 'No se pudo quitar.' }) end
        cb({ ok = true })
        Wait(250)
        if gestionAbierta then SendNUIMessage({ a = 'datos', datos = DatosGestion() }) end
    end, tostring(d.modelo or ''), tonumber(d.id))
end)

RegisterNUICallback('gestion:borrarModelo', function(d, cb)
    TriggerServerCallback('origen_vehicleseats:server:deleteModel', function(r)
        if not r then return cb({ ok = false, motivo = 'No se pudo quitar.' }) end
        cb({ ok = true })
        Wait(250)
        if gestionAbierta then SendNUIMessage({ a = 'datos', datos = DatosGestion() }) end
    end, tostring(d.modelo or ''))
end)

-- ── Spawning and Destroying Preview Peds ──
local function destroyPreviewPed()
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
        previewPed = nil
    end
end

local function spawnPreviewPed(data)
    destroyPreviewPed()

    local ped = PlayerPedId()
    local veh = currentVehicle
    if not veh or not DoesEntityExist(veh) then return end

    -- Clone player ped
    previewPed = ClonePed(ped, 0.0, false, true)
    
    -- Aesthetic enhancements
    SetEntityAlpha(previewPed, 180, false) -- Semi-transparent
    SetEntityCollision(previewPed, false, false)
    SetEntityInvincible(previewPed, true)
    FreezeEntityPosition(previewPed, true)

    -- Play selected animation
    local animDict = data.animDict
    local animName = data.animName

    if not DoesAnimDictExist(animDict) then
        return
    end

    RequestAnimDict(animDict)
    local timer = GetGameTimer()
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
        if GetGameTimer() - timer > 3000 then
            ShowNotification('No se pudo cargar la animación seleccionada.', 'error')
            return
        end
    end

    TaskPlayAnim(previewPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Attach to vehicle
    local offset = data.offset or { x = 0.0, y = -1.5, z = 0.5 }
    local rot = data.rotation or { x = 0.0, y = 0.0, z = 0.0 }
    
    AttachEntityToEntity(
        previewPed, veh, 0,
        offset.x, offset.y, offset.z,
        rot.x, rot.y, rot.z,
        false, false, false, true, 2, true
    )
end

-- ── UI Callbacks ──
RegisterNUICallback('closeCreator', function(data, cb)
    SetNuiFocus(false, false)
    destroyPreviewPed()
    currentVehicle = nil
    cb('ok')
    -- Abierto desde el panel de gestion: el vehiculo que saco, fuera, y se vuelve.
    QuitarTraido()
    if volverAGestion then
        volverAGestion = false
        AbrirGestion()
    end
end)

RegisterNUICallback('previewSeat', function(data, cb)
    spawnPreviewPed(data)
    cb('ok')
end)

RegisterNUICallback('stopPreview', function(data, cb)
    destroyPreviewPed()
    cb('ok')
end)

-- Teclas del gizmo: las pinta la propia pagina (ui/index.html, .va-barra) en
-- la barra de abajo, en una linea, con «Colocar · <asiento>» delante. Sale
-- sola con el setUIVisibility = false de abajo (la columna se aparta) y se va
-- con el true. Antes iban en la barra de origen_hud: no se manda nada alli,
-- o saldrian dos barras. Las teclas son las que mira el gizmo
-- (client/gizmo/main.lua): ENTER (191) confirma, BACKSPACE (177) cancela,
-- ALT (19) lo baja al suelo y el clic derecho mantenido mueve la camara;
-- W/R/Q son las del manipulador.
local function SendPlacingControlsHUD(show)
end

RegisterNUICallback('startGizmo', function(data, cb)
    if not previewPed or not DoesEntityExist(previewPed) then
        return cb({ success = false, error = "Preview ped no creado" })
    end

    -- Hide NUI temporarily
    SendNUIMessage({ action = "setUIVisibility", visible = false })
    SetNuiFocus(false, false)

    -- Detach and prepare ped
    DetachEntity(previewPed, true, true)
    FreezeEntityPosition(previewPed, false)

    -- Play animation again to make sure it plays during gizmo positioning
    local animDict = data.animDict
    local animName = data.animName
    TaskPlayAnim(previewPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Show instruction boxes
    SendPlacingControlsHUD(true)

    -- Trigger Gizmo
    -- Protegido: si el gizmo revienta a medias se quedaba el cursor del
    -- juego puesto y la pagina escondida, sin foco y sin nada que cerrar.
    local ok, result = pcall(Gizmo.StartGizmo, Gizmo, previewPed)
    if not ok then
        print(('^1[origen_vehicleseats]^7 gizmo: %s'):format(tostring(result)))
        LeaveCursorMode()
        Gizmo.enabled = false
        Gizmo.cursorActive = false
        if DoesEntityExist(previewPed) then SetEntityDrawOutline(previewPed, false) end
        result = nil
    end

    SendPlacingControlsHUD(false)

    -- Return focus and NUI visibility
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "setUIVisibility", visible = true })

    if result and result.confirmed then
        local pedCoords = GetEntityCoords(previewPed)
        local relPos = GetOffsetFromEntityGivenWorldCoords(currentVehicle, pedCoords.x, pedCoords.y, pedCoords.z)

        local pedRot = GetEntityRotation(previewPed, 2)
        local vehRot = GetEntityRotation(currentVehicle, 2)
        local relRot = vector3(pedRot.x - vehRot.x, pedRot.y - vehRot.y, pedRot.z - vehRot.z)

        -- Re-attach at new coordinates
        AttachEntityToEntity(
            previewPed, currentVehicle, 0,
            relPos.x, relPos.y, relPos.z,
            relRot.x, relRot.y, relRot.z,
            false, false, false, true, 2, true
        )
        FreezeEntityPosition(previewPed, true)

        cb({
            success = true,
            offset = { x = relPos.x, y = relPos.y, z = relPos.z },
            rotation = { x = relRot.x, y = relRot.y, z = relRot.z }
        })
    else
        -- Cancelled. Re-attach at old coords
        local offset = data.offset or { x = 0.0, y = -1.5, z = 0.5 }
        local rot = data.rotation or { x = 0.0, y = 0.0, z = 0.0 }
        
        AttachEntityToEntity(
            previewPed, currentVehicle, 0,
            offset.x, offset.y, offset.z,
            rot.x, rot.y, rot.z,
            false, false, false, true, 2, true
        )
        FreezeEntityPosition(previewPed, true)
        cb({ success = false })
    end
end)

RegisterNUICallback('saveSeat', function(data, cb)
    local veh = currentVehicle
    if not veh then return cb({ success = false }) end

    local model = GetEntityModel(veh)
    local modelName = string.lower(GetDisplayNameFromVehicleModel(model))

    TriggerServerCallback('origen_vehicleseats:server:saveSeat', function(result)
        if result then
            destroyPreviewPed()
            cb({ success = true, seats = result })
        else
            cb({ success = false })
        end
    end, modelName, data)
end)

RegisterNUICallback('deleteSeat', function(data, cb)
    local veh = currentVehicle
    if not veh then return cb({ success = false }) end

    local model = GetEntityModel(veh)
    local modelName = string.lower(GetDisplayNameFromVehicleModel(model))

    TriggerServerCallback('origen_vehicleseats:server:deleteSeat', function(result)
        if result then
            destroyPreviewPed()
            cb({ success = true, seats = result })
        else
            cb({ success = false })
        end
    end, modelName, data.seatId)
end)


-- ── Interactive Sitting System (For normal players) ──

-- Sit down functionality
local function sitDown(veh, seat)
    local ped = PlayerPedId()
    local netId = VehToNet(veh)
    
    -- Check seat occupancy with server using our callback
    TriggerServerCallback('origen_vehicleseats:server:trySit', function(allowed)
        if not allowed then
            ShowNotification('Alguien ya está sentado en este lugar.', 'error')
            return
        end

        isSitting = true
        sittingSeat = seat
        sittingVehNetId = netId

        -- Hide prompt text
        if GetResourceState('origen_notify') == 'started' then
            exports['origen_notify']:HideText()
        end

        -- Play animation on player
        RequestAnimDict(seat.animDict)
        while not HasAnimDictLoaded(seat.animDict) do Wait(0) end
        TaskPlayAnim(ped, seat.animDict, seat.animName, 8.0, -8.0, -1, 1, 0, false, false, false)

        -- Attach to vehicle
        AttachEntityToEntity(
            ped, veh, 0,
            seat.offset.x, seat.offset.y, seat.offset.z,
            seat.rotation.x, seat.rotation.y, seat.rotation.z,
            false, false, false, true, 2, true
        )

        -- Disable collision and ragdolling to prevent falling off during vehicle movement
        SetPedCanRagdoll(ped, false)
        SetEntityCollision(ped, false, false)

        -- Handle trunk if configured
        if seat.openTrunk then
            SetVehicleDoorOpen(veh, 5, false, false)
        end

        ShowNotification('Te has sentado. Pulsa X para levantarte.', 'info')

        -- Sitting Loop
        if not sittingThreadActive then
            sittingThreadActive = true
            -- Tecla para levantarse en la barra de origen_hud (antes, ayuda de GTA).
            local conBarra = GetResourceState('origen_hud') == 'started'
            if conBarra then
                exports.origen_hud:setupControls({ { key = 'X', text = 'Levantarte' } })
            end
            CreateThread(function()
                while isSitting do
                    Wait(0)
                    local currentPed = PlayerPedId()
                    local vehicle = NetToVeh(sittingVehNetId)

                    -- Keep playing animation to prevent interruptions
                    if isSitting and sittingSeat and not IsEntityPlayingAnim(currentPed, sittingSeat.animDict, sittingSeat.animName, 3) then
                        TaskPlayAnim(currentPed, sittingSeat.animDict, sittingSeat.animName, 8.0, -8.0, -1, 1, 0, false, false, false)
                    end

                    -- Disable offensive/movement inputs
                    DisableControlAction(0, 21, true) -- Sprint
                    DisableControlAction(0, 22, true) -- Jump
                    DisableControlAction(0, 24, true) -- Attack
                    DisableControlAction(0, 25, true) -- Aim
                    DisableControlAction(0, 31, true) -- Move Z
                    DisableControlAction(0, 30, true) -- Move X/Y
                    DisableControlAction(0, 75, true) -- Exit vehicle

                    -- Check stand up key: [X] (INPUT_VEH_DUCK is 73)
                    if IsDisabledControlJustPressed(0, 73) or IsControlJustPressed(0, 73) then
                        standUp()
                    end

                    -- Safety checks
                    if isSitting and (not DoesEntityExist(vehicle) or IsPedDeadOrDying(currentPed, true)) then
                        standUp()
                    end

                    -- Moving vehicle checks
                    if isSitting and sittingSeat and not sittingSeat.allowMoving then
                        local speed = GetEntitySpeed(vehicle) * 3.6 -- km/h
                        if speed > 15.0 then
                            standUp(true) -- Force fall/ragdoll off the vehicle
                        end
                    end
                end
                if conBarra then exports.origen_hud:hideControls() end
                sittingThreadActive = false
            end)
        end
    end, netId, seat.id)
end

-- Stand up functionality
function standUp(forceFall)
    if not isSitting then return end
    isSitting = false

    local ped = PlayerPedId()
    local vehicle = NetToVeh(sittingVehNetId)

    DetachEntity(ped, true, true)
    ClearPedTasks(ped)

    -- Restore collision and ragdolling
    SetPedCanRagdoll(ped, true)
    SetEntityCollision(ped, true, true)

    -- Close trunk if opened
    if vehicle and DoesEntityExist(vehicle) and sittingSeat.openTrunk then
        SetVehicleDoorShut(vehicle, 5, false)
    end

    -- Server sync release
    TriggerServerEvent('origen_vehicleseats:server:leaveSeat', sittingVehNetId, sittingSeat.id)

    if forceFall then
        SetPedToRagdoll(ped, 2000, 2000, 0, 0, 0, 0)
        ShowNotification('¡Te caíste del vehículo por estar en movimiento!', 'error')
    else
        -- Place player slightly behind their sitting spot on ground safely
        local coords = GetEntityCoords(ped)
        SetEntityCoords(ped, coords.x, coords.y, coords.z + 0.1, false, false, false, true)
    end

    sittingSeat = nil
    sittingVehNetId = nil
end

-- Try sitting in the closest seat of the vehicle
local function TrySittingInClosestSeat(veh)
    if isSitting then return end
    if not veh or not DoesEntityExist(veh) then return end

    local model = GetEntityModel(veh)
    local modelName = string.lower(GetDisplayNameFromVehicleModel(model))
    local allSeats = GlobalState.VehicleSeats or {}
    local seats = allSeats[modelName]

    if not seats or #seats == 0 then return end

    local pedCoords = GetEntityCoords(PlayerPedId())
    local closestSeat = nil
    local minDist = 999.0

    for _, seat in ipairs(seats) do
        local worldPos = GetOffsetFromEntityInWorldCoords(veh, seat.offset.x, seat.offset.y, seat.offset.z)
        local dist = #(pedCoords - worldPos)
        if dist < minDist then
            minDist = dist
            closestSeat = seat
        end
    end

    if closestSeat and minDist < 2.0 then
        -- Check server occupied status
        local occupiedData = GlobalState.OccupiedSeats or {}
        local netId = VehToNet(veh)
        if occupiedData[netId] and occupiedData[netId][closestSeat.id] then
            ShowNotification('Este asiento ya está siendo usado.', 'error')
            return
        end

        sitDown(veh, closestSeat)
    else
        ShowNotification('No estás lo suficientemente cerca de ningún asiento de este vehículo.', 'error')
    end
end

-- ── 3D Text Proximity Prompt (Redefined using origen_notify:DrawText widget) ──
local hasActiveText = false
local lastActiveSeatId = nil

-- Copia local de GlobalState.VehicleSeats: leer el statebag cada fotograma cuesta
local vehicleSeatsCache = GlobalState.VehicleSeats or {}
AddStateBagChangeHandler('VehicleSeats', 'global', function(_, _, value)
    vehicleSeatsCache = value or {}
end)

-- Coche con asientos recordado en modo cercano, para no recorrer el pool cada fotograma
local nearSeatsVeh = 0
local nearSeatsNextSearch = 0

CreateThread(function()
    while true do
        local sleep = 1000
        if not isSitting then
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)

            -- Find closest vehicle using memory entity pool search
            -- (solo cada 500 ms, o si el coche recordado desaparece o se aleja)
            local veh = nearSeatsVeh
            local now = GetGameTimer()
            if veh == 0 or now >= nearSeatsNextSearch or not DoesEntityExist(veh)
                or #(pedCoords - GetEntityCoords(veh)) >= 6.0 then
                veh = GetClosestVehicleNearPlayer(pedCoords, 6.0)
                nearSeatsNextSearch = now + 500
            end
            nearSeatsVeh = 0

            if veh ~= 0 and DoesEntityExist(veh) then
                local model = GetEntityModel(veh)
                local modelName = string.lower(GetDisplayNameFromVehicleModel(model))
                local allSeats = vehicleSeatsCache
                local seats = allSeats[modelName]

                -- De jornada en la cantera la caja es de la mina (la carretilla va con
                -- H y E): no se ofrece sentarse (27/09, el usuario).
                if seats and #seats > 0 and not LocalPlayer.state.minaJornada then
                    sleep = 0
                    nearSeatsVeh = veh
                    local closestSeat = nil
                    local minDist = 2.0

                    for _, seat in ipairs(seats) do
                        local worldPos = GetOffsetFromEntityInWorldCoords(veh, seat.offset.x, seat.offset.y, seat.offset.z)
                        local dist = #(pedCoords - worldPos)
                        if dist < minDist then
                            minDist = dist
                            closestSeat = seat
                        end
                    end

                    if closestSeat then
                        -- Check if occupied
                        local occupiedData = GlobalState.OccupiedSeats or {}
                        local netId = VehToNet(veh)
                        local occupied = occupiedData[netId] and occupiedData[netId][closestSeat.id]

                        if occupied then
                            if lastActiveSeatId ~= closestSeat.id or not hasActiveText then
                                if GetResourceState('origen_notify') == 'started' then
                                    exports['origen_notify']:DrawText('H', 'Ocupado: ' .. closestSeat.name)
                                end
                                lastActiveSeatId = closestSeat.id
                                hasActiveText = true
                            end
                        else
                            -- Draw the clean, premium origen key widget prompt!
                            if lastActiveSeatId ~= closestSeat.id or not hasActiveText then
                                if GetResourceState('origen_notify') == 'started' then
                                    exports['origen_notify']:DrawText('H', 'Sentarse en ' .. closestSeat.name)
                                end
                                lastActiveSeatId = closestSeat.id
                                hasActiveText = true
                            end

                            if IsControlJustPressed(0, 74) then -- [H] Key
                                sitDown(veh, closestSeat)
                            end
                        end
                    else
                        -- Not close to any specific seat of this vehicle anymore
                        if hasActiveText then
                            if GetResourceState('origen_notify') == 'started' then
                                    exports['origen_notify']:HideText()
                            end
                            hasActiveText = false
                            lastActiveSeatId = nil
                        end
                    end
                else
                    -- No custom seats configured for this model
                    if hasActiveText then
                        if GetResourceState('origen_notify') == 'started' then
                            exports['origen_notify']:HideText()
                        end
                        hasActiveText = false
                        lastActiveSeatId = nil
                    end
                end
            else
                -- No vehicle nearby
                if hasActiveText then
                    if GetResourceState('origen_notify') == 'started' then
                        exports['origen_notify']:HideText()
                    end
                    hasActiveText = false
                    lastActiveSeatId = nil
                end
            end
        else
            -- Player is sitting
            nearSeatsVeh = 0
            if hasActiveText then
                if GetResourceState('origen_notify') == 'started' then
                    exports['origen_notify']:HideText()
                end
                hasActiveText = false
                lastActiveSeatId = nil
            end
        end
        Wait(sleep)
    end
end)

-- ── Dynamic Target Registrations (Optional / Wrapped in resource state check) ──
CreateThread(function()
    Wait(2000) -- Wait for exports to load

    -- ox_target setup
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addGlobalVehicle({
            {
                name = 'sit_custom_seats',
                icon = 'fas fa-chair',
                label = 'Sentarse en Asiento Personalizado',
                canInteract = function(entity, distance, coords, name, bone)
                    local model = GetEntityModel(entity)
                    local modelName = string.lower(GetDisplayNameFromVehicleModel(model))
                    local allSeats = GlobalState.VehicleSeats or {}
                    local seats = allSeats[modelName]
                    return seats and #seats > 0
                end,
                onSelect = function(data)
                    TrySittingInClosestSeat(data.entity)
                end
            }
        })
    end

    -- qb-target setup
    if GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddGlobalVehicle({
            options = {
                {
                    type = "client",
                    event = "origen_vehicleseats:client:targetSit",
                    icon = "fas fa-chair",
                    label = "Sentarse en Asiento Personalizado",
                    canInteract = function(entity)
                        local model = GetEntityModel(entity)
                        local modelName = string.lower(GetDisplayNameFromVehicleModel(model))
                        local allSeats = GlobalState.VehicleSeats or {}
                        local seats = allSeats[modelName]
                        return seats and #seats > 0
                    end,
                }
            },
            distance = 2.5,
        })
    end
end)

RegisterNetEvent("origen_vehicleseats:client:targetSit", function(data)
    TrySittingInClosestSeat(data.entity)
end)
