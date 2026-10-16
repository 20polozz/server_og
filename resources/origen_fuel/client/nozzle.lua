local Nozzle = 0
local Rope = 0
local nozzles = require 'config.nozzles'
local pumps = require 'config.pumps'
local utils = require 'client.utils'

local function rotateOffset(offset, rotation)
	local rad = math.rad(rotation)
	local cos = math.cos(rad)
	local sin = math.sin(rad)
	return vec3(offset.x * cos - offset.y * sin, offset.x * sin + offset.y * cos, offset.z)
end

function GrabNozzle(entity)
    if Nozzle ~= 0 then return end

    local ped = PlayerPedId()
    
    lib.requestAnimDict('anim@am_hold_up@male', 300)
    TaskPlayAnim(ped, 'anim@am_hold_up@male', 'shoplift_high', 2.0, 8.0, -1, 50, 0, false, false, false)
    Wait(300)
    StopAnimTask(ped, 'anim@am_hold_up@male', 'shoplift_high', 1.0)
    RemoveAnimDict('anim@am_hold_up@male')

    local cat = 'fv'
    local hash = nozzles[cat].nozzle
    local hand = nozzles[cat].offsets.hand
    local bone = GetPedBoneIndex(ped, 18905)

    lib.requestModel(hash)
    local nozzle = CreateObject(hash, 1.0, 1.0, 1.0, true, true, false)
    AttachEntityToEntity(nozzle, ped, bone, hand[1], hand[2], hand[3], hand[4], hand[5], hand[6], false, true, false, true, 0, true)
    
    Nozzle = nozzle

    RopeLoadTextures()
    while not RopeAreTexturesLoaded() do
        Wait(0)
        RopeLoadTextures()
    end

    local pumpCoords = GetEntityCoords(entity)
    local rope = AddRope(pumpCoords.x, pumpCoords.y, pumpCoords.z, 0.0, 0.0, 0.0, 3.0, 1, 8.0, 0.0, 1.0, false, false, false, 1.0, true)

    while not rope do
        Wait(0)
    end

    Rope = rope
    ActivatePhysics(rope)
    Wait(100)

    local nozzleOffset = nozzles[cat].offsets.rope
    local nozzlePos = GetOffsetFromEntityInWorldCoords(nozzle, nozzleOffset.x, nozzleOffset.y, nozzleOffset.z)
    local pumpHeading = GetEntityHeading(entity)
    local pumpModel = GetEntityModel(entity)
    local pumpOffset = pumps[pumpModel] and pumps[pumpModel].offset or vec3(0.0, 0.0, 1.5)
    local rotatedPumpOffset = rotateOffset(pumpOffset, pumpHeading)
    local coords = pumpCoords + rotatedPumpOffset

    AttachEntitiesToRope(rope, entity, nozzle, coords.x, coords.y, coords.z, nozzlePos.x, nozzlePos.y, nozzlePos.z, 5.0, false, false, nil, nil)

    CreateThread(function()
        local maxDistance = 10.0
        while Nozzle ~= 0 do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - pumpCoords)
            
            if dist > maxDistance then
                ReturnNozzle()
                if exports['origen_fuel']:GetPendingRefuel() then
                    exports['origen_fuel']:ClearPendingRefuel()
                    lib.notify({description = 'Manguera desconectada por distancia', type = 'error'})
                else
                    lib.notify({description = 'Manguera devuelta por distancia', type = 'inform'})
                end
                break
            end
            Wait(500)
        end
    end)

    return true
end

function ReturnNozzle()
    if Nozzle == 0 then return end

    local ped = PlayerPedId()
    
    
    Wait(250)

    DeleteEntity(Nozzle)
    Nozzle = 0
    DeleteRope(Rope)
    RopeUnloadTextures()
    Rope = 0

    return true
end

function HasNozzle()
    return Nozzle ~= 0
end

exports('HasNozzle', HasNozzle)
exports('GrabNozzle', GrabNozzle)
exports('ReturnNozzle', ReturnNozzle)
