if true then -- replace with true if you want this command
    local enabled = false
    RegisterCommand("getcarpos", function()
        local obj = GetClosestObjectOfType(GetEntityCoords(PlayerPedId()), 5.0, `tstudio_tuner_asset_carlifta`, false, false, false)
        if obj ~= 0 then
            local pos = GetEntityCoords(obj)
            print("Car pos: " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)
        else
            print("No car lift found")
        end
    end)
end

local zOffsets = { 0.65, 16.05 - 13.35} -- , 18.18 - 13.35 

function getText(key)
    return Config.Texts[key]
end

CreateThread(function()
    while true do
        local canSleep = true
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        for _, lift in pairs(Config.Carlifts) do
            -- Handle GetPos marker
            local getDist = #(pos.xy - lift.GetPos.xy)
            if getDist < 50.0 then
                canSleep = false
                DrawMarker(36, lift.GetPos.x, lift.GetPos.y, lift.GetPos.z + 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, Config.Color[1], Config.Color[2], Config.Color[3], 150, 0, 1, 0, 0)
                if getDist < 0.5 then
                    ShowHelpNotification(getText("GET_CAR"))
                    if IsControlJustPressed(0, 38) then
                        OpenGetView(lift)
                    end
                end
            end

            -- Handle PutPos marker
            local putDist = #(pos.xy - lift.PutPos.xy)
            if putDist < 50.0 then
                canSleep = false
                DrawMarker(20, lift.PutPos.x, lift.PutPos.y, lift.PutPos.z + 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, Config.Color[1], Config.Color[2], Config.Color[3], 150, 0, 1, 0, 0)
                if putDist < 0.5 then
                    ShowHelpNotification(getText("PUT_CAR"))
                    if IsControlJustPressed(0, 38) then
                        PutLastVehicle(lift)
                    end
                end
            end
        end

        Wait(canSleep and 1000 or 1)
    end
end)

local curLift
local curVehicle = nil
local oldPos = nil
local oldHeading = nil
local oldDoorState = nil
local curIndex

local getCam
local getIndex
local getVehicle
function OpenGetView(lift)
    getIndex = nil
    getVehicle = nil
    for k, v in pairs(zOffsets) do
        local state, veh = IsPositionOccupied(lift.Pos, k)
        if state then
            getIndex = k
            getVehicle = veh
        end
    end

    if not getIndex then
        ShowHelpNotifyDuration(getText("NO_CAR_ON_LIFT"), 2000)
        return
    end

    SendNUIMessage({
        action = "setShow",
        data = true,
        mode = "get",
        level = getIndex,
        levels = #zOffsets,
        color = Config.Color
    })
    SetNuiFocus(true, true)
    curLift = lift
    getCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamActive(getCam, true)
    AttachCamToEntity(getCam, getVehicle, 0.0, 5.0, 1.0, true)
    PointCamAtEntity(getCam, getVehicle, 0.0, 0.0, 0.0)
    RenderScriptCams(true, false, 0, true, true)
end

function PutVehicleOnPos(lift, zOffsetIndex, vehicle)
    local obj = GetClosestObjectOfType(lift.Pos, 5.0, `tstudio_tuner_asset_carlifta`, false, false, false)
    local pos = lift.Pos
    local heading = GetEntityHeading(obj) - 90.0
    local zOffset = zOffsets[zOffsetIndex]
    SetVehicleFixed(vehicle)
    SetVehicleDoorsLocked(vehicle, 2)
    SetEntityCoordsNoOffset(vehicle, pos.x, pos.y, pos.z + zOffset, false, false, false)
    SetEntityHeading(vehicle, heading)
    FreezeEntityPosition(vehicle, true)
end

local helpNotify
function ShowHelpNotification(msg)
    if msg ~= helpNotify then
        AddTextEntry('tstudio_carelevator_help', msg)
        helpNotify = msg
    end
    BeginTextCommandDisplayHelp('tstudio_carelevator_help')
    EndTextCommandDisplayHelp(0, false, true, -1)
end

function PutLastVehicle(lift)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    if DoesEntityExist(vehicle) then
        local pos = GetEntityCoords(vehicle)
        local playerPos = GetEntityCoords(PlayerPedId())
        local dist = #(pos.xy - playerPos.xy)

        if dist < 5.0 then
            if not IsEntityPositionFrozen(vehicle) then
                for i = 0, GetVehicleMaxNumberOfPassengers(vehicle) do
                    local ped = GetPedInVehicleSeat(vehicle, i - 2)
                    if DoesEntityExist(ped) then
                        ShowHelpNotifyDuration(getText("CAR_NOT_EMPTY"), 2000)
                        return
                    end
                end
                local freeIndex
                for k, v in pairs(zOffsets) do
                    if not IsPositionOccupied(lift.Pos, k) then
                        freeIndex = k
                        break
                    end
                end

                if not freeIndex then
                    ShowHelpNotifyDuration(getText("LIFT_FULL") or "The lift is full", 2000)
                    return
                end

                curVehicle = vehicle
                oldPos = pos
                oldHeading = GetEntityHeading(vehicle)
                oldDoorState = GetVehicleDoorLockStatus(vehicle)
                curLift = lift
                curIndex = freeIndex

                CreateThread(function()
                    PutVehicleOnPos(lift, curIndex, vehicle)
                end)
                SendNUIMessage({
                    action = "setShow",
                    data = true,
                    mode = "put",
                    level = curIndex,
                    levels = #zOffsets,
                    color = Config.Color
                })
                SetNuiFocus(true, true)

                local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                SetCamActive(cam, true)
                AttachCamToEntity(cam, vehicle, 0.0, 5.0, 1.0, true)
                PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0)
                RenderScriptCams(true, false, 0, true, true)
            else
                ShowHelpNotifyDuration(getText("CAR_ON_LIFT"), 2000)
            end
        else
            ShowHelpNotifyDuration(getText("CAR_TOO_FAR"), 2000)
        end
    else
        ShowHelpNotifyDuration(getText("NO_CAR"), 2000)
    end
end

RegisterNUICallback("exit", function(data, cb)
    if curVehicle then
        FreezeEntityPosition(curVehicle, false)
        SetEntityCoords(curVehicle, oldPos.x, oldPos.y, oldPos.z, false, false, false)
        SetEntityHeading(curVehicle, oldHeading)
        SetVehicleDoorsLocked(curVehicle, oldDoorState)
        curVehicle = nil
        oldPos = nil
        oldHeading = nil
        oldDoorState = nil
        curIndex = nil
        SendNUIMessage({
            action = "setShow",
            data = false
        })
        SetNuiFocus(false, false)
        DestroyCam(GetRenderingCam())
        RenderScriptCams(false, false, 0, true, true)
    else
        Exit()
    end
    cb(true)
end)

local function WrapLevel(index)
    if index < 1 then
        return #zOffsets
    elseif index > #zOffsets then
        return 1
    end
    return index
end

RegisterNUICallback("buttonClick", function(data, cb)
    if data == 2 or data == 3 then
        local indexMod = data == 2 and 1 or -1
        if curIndex ~= nil then
            local newIndex = curIndex
            for _ = 1, #zOffsets - 1 do
                newIndex = WrapLevel(newIndex + indexMod)
                if not IsPositionOccupied(curLift.Pos, newIndex) then
                    curIndex = newIndex
                    PutVehicleOnPos(curLift, curIndex, curVehicle)
                    break
                end
            end
        elseif getIndex ~= nil then
            local newIndex = getIndex
            for _ = 1, #zOffsets - 1 do
                newIndex = WrapLevel(newIndex + indexMod)
                local state, veh = IsPositionOccupied(curLift.Pos, newIndex)
                if state and veh then
                    getIndex = newIndex
                    getVehicle = veh
                    AttachCamToEntity(getCam, getVehicle, 0.0, 5.0, 1.0, true)
                    PointCamAtEntity(getCam, getVehicle, 0.0, 0.0, 0.0)
                    break
                end
            end
        end
    elseif data == 1 and curIndex ~= nil then
        Exit()
    elseif data == 4 and getIndex ~= nil then
        Exit()

        SetEntityCoords(getVehicle, curLift.GetOutPos.xyz, false, false, false)
        SetEntityHeading(getVehicle, curLift.GetOutPos.w)
        SetVehicleDoorsLocked(getVehicle, 0)
        FreezeEntityPosition(getVehicle, false)
        getVehicle = nil
        getIndex = nil
        SendNUIMessage({
            action = "setShow",
            data = false
        })
        SetNuiFocus(false, false)
        DestroyCam(GetRenderingCam())
        RenderScriptCams(false, false, 0, true, true)
    end
    cb({ level = curIndex or getIndex, levels = #zOffsets })
end)

function Exit()
    curVehicle = nil
    oldPos = nil
    oldHeading = nil
    oldDoorState = nil
    curIndex = nil
    SendNUIMessage({
        action = "setShow",
        data = false
    })
    SetNuiFocus(false, false)
    DestroyCam(GetRenderingCam())
    RenderScriptCams(false, false, 0, true, true)
end

function ShowHelpNotifyDuration(msg, duration)
    AddTextEntry('tstudio_carelevator_help_duration', msg)
    BeginTextCommandDisplayHelp('tstudio_carelevator_help_duration')
    EndTextCommandDisplayHelp(0, false, true, duration)
    Wait(duration)
end

function IsPositionOccupied(pos, index)
    if pos == nil or index == nil or zOffsets[index] == nil then
        return true
    end
    local pos = vector3(pos.x, pos.y, pos.z + zOffsets[index])
    for k, v in pairs(GetGamePool("CVehicle")) do
        local vehPos = GetEntityCoords(v)
        local dist = #(vehPos - pos)
        if dist < 0.2 then
            return true, v
        end
    end
end
