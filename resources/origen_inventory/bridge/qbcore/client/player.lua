if not GetResourceState('qb-core'):match('start') or GlobalState.orgInventoryProvided then return end
Bridge = Bridge or {}
local QB = exports['qb-core']:GetCoreObject()
local alcoholCount = 0
--- OnPlayerLoad QB
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CharacterUnloaded = false
    OnPlayerLoad()
end)

CreateThread(function() 
    local PlayerData = QB.Functions.GetPlayerData()

    while not PlayerData or not PlayerData.job do
        Wait(1000)
        PlayerData = QB.Functions.GetPlayerData()
    end
    
    OnPlayerLoad()
end)

function Bridge.TriggerCallback(name, cb, ...)
    QB.Functions.TriggerCallback(name, cb, ...)
end

function Bridge.GetPlayerHealth()
    return GetEntityHealth(PlayerPedId()) - 100
end

function Bridge.GetPlayerArmor()
    return GetPedArmour(PlayerPedId())
end

function Bridge.GetPlayerHunger()
    return QB.Functions.GetPlayerData().metadata.hunger
end

function Bridge.GetPlayerThirst()
    return QB.Functions.GetPlayerData().metadata.thirst
end

function Bridge.GetPlayerInfo()
    local PlayerData = QB.Functions.GetPlayerData()

    if not PlayerData then return nil, nil, nil end
    if not PlayerData.job then return nil, nil, nil end
    if not PlayerData.gang then return nil, nil, nil end
    if not PlayerData.charinfo then return nil, nil, nil end
    
    local job = {
        name = PlayerData.job.name,
        grade = PlayerData.job.grade,
        label = PlayerData.job.label,
        isboss = PlayerData.job.isboss,
        isduty = PlayerData.job.onduty,
    }
    local gang = {
        name = PlayerData.gang.name,
        grade = PlayerData.gang.grade,
        label = PlayerData.gang.label,
        isboss = PlayerData.gang.isboss or false,
    }

    local charinfo = {
        firstname = PlayerData.charinfo.firstname,
        lastname = PlayerData.charinfo.lastname,
        birthdate = PlayerData.charinfo.birthdate,
        gender = PlayerData.charinfo.gender,
    }


    return job, gang, charinfo
end

function Bridge.Notify(message, type)
    QB.Functions.Notify( message, type)
end

function Bridge.CanSearch(player)
    if IsEntityDead(player) then return true end
    for k,v in pairs(Config.SearchAnims) do
        if IsEntityPlayingAnim(player, v.dict, v.anim, 3) == 1 then
            return true
        end
    end
    return false
end

function  Bridge.CanOpen()
    local PlayerData = QB.Functions.GetPlayerData()
    local isDead  = PlayerData.metadata["isdead"] and PlayerData.metadata["inlaststand"] and PlayerData.metadata["ishandcuffed"]
    if isDead then return false end
    for k,v in pairs(Config.SearchAnims) do
        if IsEntityPlayingAnim(PlayerPedId(), v.dict, v.anim, 3) == 1 then
            return false
        end
    end
    return true
end

function  Bridge.CanOpenTrunk()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false) > 0 and GetVehiclePedIsIn(playerPed, false) or GetClosestVehicle(false, Config.TrunkOpenDistance) 
    
    local hasVehicle = false
    local model = 0
    local plate = "false"
    local nearGlovebox = false

    if vehicle and vehicle > 0 then
        local isSeatOnDriver = GetPedInVehicleSeat(vehicle, -1) == playerPed
        local isSeatNearDriver = GetPedInVehicleSeat(vehicle, 0) == playerPed
        
        hasVehicle = true
        nearGlovebox = isSeatOnDriver or isSeatNearDriver
        model = GetEntityModel(vehicle)
        plate = GetVehicleNumberPlateText(vehicle)
    end

    return hasVehicle, vehicle, model, plate, nearGlovebox
end

if not Config.UseInventoryComsumables then return end

function Bridge.AddStatus(type,value)
    if type == 'hunger' then 
        TriggerServerEvent("consumables:server:addHunger", QB.Functions.GetPlayerData().metadata["hunger"] + value)
        TriggerServerEvent('hud:server:RelieveStress', math.random(2, 4))
    elseif type == 'thirst' then
        TriggerServerEvent("consumables:server:addThirst", QB.Functions.GetPlayerData().metadata["thirst"] + value)
    elseif type == 'alcohol' then
        TriggerServerEvent("consumables:server:addThirst", QB.Functions.GetPlayerData().metadata["thirst"] + value)
        alcoholCount += 1
        AlcoholLoop()
        if alcoholCount > 1 and alcoholCount < 4 then
            TriggerEvent("evidence:client:SetStatus", "alcohol", 200)
        elseif alcoholCount >= 4 then
            TriggerEvent("evidence:client:SetStatus", "heavyalcohol", 200)
        end
    end
end

local looped = false
function AlcoholLoop()
    if not looped then
        looped = true
        CreateThread(function()
            while true do
                Wait(10)
                if alcoholCount > 0 then
                    Wait(1000 * 60 * 15)
                    alcoholCount -= 1
                else
                    looped = false
                    break
                end
            end
        end)
    end
end