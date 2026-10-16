-- client/testdrive.lua
-- Prueba de vehiculos de la tienda: spawn aislado, contador y regreso al origen.

TestDrive = {}

local session = {
    id      = 0,
    active  = false,
    vehicle = nil,
    origin  = nil,
    heading = 0.0,
}

local function config()
    return Config.TestDrive or {}
end

local function leaveBucket()
    lib.callback.await('origen_vipsystem:server:testDriveBucket', false, false)
end

--- Picks the spawn point from the native vehicle class of the model, so a boat
--- never lands on asphalt and a plane never spawns inside a parking lot.
local function resolveSpawn(model)
    local spawns = config().spawns
    if type(spawns) ~= 'table' then return nil end

    local class = GetVehicleClassFromName(joaat(model))

    for _, group in pairs(spawns) do
        for _, entry in ipairs(group.classes or {}) do
            if entry == class then return group.coords end
        end
    end

    local fallback = spawns[config().fallback or 'land']
    return fallback and fallback.coords or nil
end

--- Ends the session identified by `id`. Comparing the id is what stops a timer
--- from a previous drive from deleting the vehicle of the current one.
local function finish(id, reason)
    if not session.active or session.id ~= id then return end

    session.active = false

    local vehicle, origin, heading = session.vehicle, session.origin, session.heading
    session.vehicle, session.origin = nil, nil

    SendNUIMessage({ action = 'testDriveEnd' })
    DoScreenFadeOut(500)
    Wait(500)

    if vehicle and DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    end

    if origin then
        SetEntityCoords(cache.ped, origin.x, origin.y, origin.z, false, false, false, false)
        SetEntityHeading(cache.ped, heading)
    end

    leaveBucket()
    Wait(500)
    DoScreenFadeIn(1000)

    if reason == 'cancelled' then
        notify(T('notify.test_drive_cancelled'), 'error')
    else
        notify(T('notify.test_drive_finished'), 'success')
    end
end

local function abort(message)
    leaveBucket()
    DoScreenFadeIn(500)
    notify(T(message), 'error')
    return false
end

function TestDrive.Start(model, label, duration)
    if session.active then return false end
    if type(model) ~= 'string' or model == '' then return false end

    local coords = resolveSpawn(model)
    if not coords then
        notify(T('notify.test_drive_no_spawn'), 'error')
        return false
    end

    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        notify(T('notify.test_drive_invalid_model'), 'error')
        return false
    end

    local origin  = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)

    RequestModel(hash)

    local attempts = 0
    while not HasModelLoaded(hash) and attempts < 50 do
        Wait(100)
        attempts = attempts + 1
    end

    if not HasModelLoaded(hash) then
        notify(T('notify.test_drive_invalid_model'), 'error')
        return false
    end

    DoScreenFadeOut(500)
    Wait(500)

    if not lib.callback.await('origen_vipsystem:server:testDriveBucket', false, true) then
        SetModelAsNoLongerNeeded(hash)
        DoScreenFadeIn(500)
        notify(T('notify.test_drive_failed'), 'error')
        return false
    end

    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w, true, false)
    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(vehicle) then
        return abort('notify.test_drive_failed')
    end

    local plate = config().plate or 'VIPTEST'

    session.id      = session.id + 1
    session.active  = true
    session.vehicle = vehicle
    session.origin  = origin
    session.heading = heading

    local id = session.id

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNumberPlateText(vehicle, plate)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleDirtLevel(vehicle, 0.0)
    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)

    if Custom and Custom.GiveVehicleKeys then
        Custom.GiveVehicleKeys(vehicle, plate)
    end

    DoScreenFadeIn(500)

    local milliseconds = math.floor((tonumber(duration) or 5) * 60 * 1000)

    SendNUIMessage({
        action   = 'testDriveStart',
        label    = label or model,
        duration = milliseconds,
    })

    CreateThread(function()
        -- The warp needs a beat to settle under streaming load; polling right
        -- away would read the ped as "on foot" and cancel the drive instantly.
        Wait(1500)

        while session.active and session.id == id do
            if not IsPedInVehicle(cache.ped, vehicle, false) then
                return finish(id, 'cancelled')
            end

            Wait(500)
        end
    end)

    SetTimeout(milliseconds, function()
        finish(id, 'finished')
    end)

    return true
end

function TestDrive.IsActive()
    return session.active
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() or not session.active then return end

    if session.vehicle and DoesEntityExist(session.vehicle) then
        SetEntityAsMissionEntity(session.vehicle, true, true)
        DeleteVehicle(session.vehicle)
    end

    if session.origin then
        SetEntityCoords(cache.ped, session.origin.x, session.origin.y, session.origin.z, false, false, false, false)
        SetEntityHeading(cache.ped, session.heading)
    end
end)
