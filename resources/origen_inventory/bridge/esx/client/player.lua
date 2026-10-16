if not GetResourceState('es_extended'):match('start') then return end
--- OnPlayerLoad ESX
RegisterNetEvent('esx:playerLoaded', OnPlayerLoad)

local hunger = 50
local thirst = 50

CreateThread(function() 
    local PlayerData = ESX.GetPlayerData()

    while not PlayerData or not PlayerData.job do
        Wait(1000)
        PlayerData = ESX.GetPlayerData()
    end
    
    OnPlayerLoad()
end)


function Bridge.TriggerCallback(name, cb, ...)
    ESX.TriggerServerCallback(name, cb, ...)
end

function Bridge.GetPlayerHealth()
    return GetEntityHealth(PlayerPedId()) - 100
end

function Bridge.GetPlayerArmor()
    return GetPedArmour(PlayerPedId())
end

function Bridge.GetPlayerHunger()
    local percent = nil
    local timing = 0
    TriggerEvent('esx_status:getStatus', 'hunger', function(status)
        percent = status.getPercent()
    end)
    while percent == nil do
        
        if timing > 2 then return 0 end

        TriggerEvent('esx_status:getStatus', 'hunger', function(status)
            percent = status.getPercent()
        end)
        timing += 1
        Wait(1000)
    end
    return percent
end

function Bridge.GetPlayerThirst()
    local percent = nil
    local timing = 0
    TriggerEvent('esx_status:getStatus', 'thirst', function(status)
        percent = status.getPercent()
    end)
    while percent == nil do
        if timing > 2 then return 0 end
        TriggerEvent('esx_status:getStatus', 'thirst', function(status)
            percent = status.getPercent()
        end)
        Wait(1000)
    end
    return percent
end

function Bridge.GetPlayerInfo()
    local PlayerData = ESX.GetPlayerData()
    local job = {
        name = PlayerData.job.name,
        grade = PlayerData.job.grade,
        label = PlayerData.job.label,
        isboss = PlayerData.job.grade_name,
        isduty = PlayerData.job.grade_label,
    }

    local charinfo = {
        firstname = PlayerData.firstName,
        lastname = PlayerData.lastName,
        birthdate = PlayerData.dateofbirth,
        gender = PlayerData.sex,
    }


    return job, nil, charinfo
end

function Bridge.Notify(message, type)
    ESX.ShowNotification( message, type)
end

function Bridge.CanSearch(targetPed)
    -- local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
    if IsEntityDead(targetPed) then return true end
    for k,v in pairs(Config.SearchAnims) do
        if IsEntityPlayingAnim(targetPed, v.dict, v.anim, 3) == 1 then
            return true
        end
    end
    return false
end

function  Bridge.CanOpen()
    local PlayerData = ESX.GetPlayerData()
    PlayerData.metadata = PlayerData.metadata or {}
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
        TriggerEvent('esx_status:add', "hunger", value * 1000)
        TriggerServerEvent('hud:server:RelieveStress', math.random(2, 4))
    elseif type == 'thirst' then
        TriggerEvent('esx_status:add', "thirst", value * 1000)
    elseif type == 'alcohol' then
        TriggerEvent('esx_status:add', "thirst", -value * 1000)
        TriggerServerEvent("consumables:server:addThirst", ESX.GetPlayerData().metadata["thirst"] + value)
        alcoholCount += 1
        AlcoholLoop()
        TriggerEvent("evidence:client:SetStatus", "alcohol", 200)
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
