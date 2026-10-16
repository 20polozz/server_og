function SelfRevive()
    local playerID = GetPlayerServerId(PlayerId()) -- The id of the admin that is going to revive
    if GetResourceState('qbx_medical') == 'started' then
        TriggerEvent('qbx_medical:client:playerRevived')
    elseif Config.AmbulanceSystem == "qb-ambulancejob" then 
        TriggerEvent("hospital:client:Revive")
    elseif Config.AmbulanceSystem == "default" then 
        ExecuteCommand("revive "..(Config.Framework=="esx" and 'me' or ''))
    elseif Config.AmbulanceSystem == "wasabi_ambulance" then 
        TriggerEvent('wasabi_ambulance:revive', false)
    end
end

function ModifySkin()
    SendNUIMessage({ action = "close" })
    SendNUIMessage({ action = "closeQuickMenuLua" })
    SendNUIMessage({ action = "closeAdminPanel" })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    if Config.ClothingSystem == "qb-clothing" then 
        TriggerEvent("qb-clothing:client:openMenu")
    elseif Config.ClothingSystem == "illenium-appearance" then
        TriggerEvent("illenium-appearance:client:openClothingShop", true)
    elseif Config.ClothingSystem == "vms_clothestore" then
        exports["vms_clothestore"]:OpenWardrobe()
    elseif Config.ClothingSystem == "origen_clothing" then
        TriggerEvent("origen_clothing:client:openCreationManually")
    end
end

function ReviveAll()
    TriggerServerEvent("origen_admin:server:reviveAll")
end

--[[ La fuente de verdad del sistema de tuneo es origen_businesses (Config.Tuning.System): es quien abre el taller en el juego. ]]
local function GetTunningSystem()
    if GetResourceState('origen_businesses') == 'started' then
        local ok, system = pcall(function()
            return exports['origen_businesses']:GetTuningSystem()
        end)
        if ok and type(system) == 'string' and system ~= '' then return system end
    end

    return Config.TunningSystem
end

function ModifyVehicle()
    local tunningSystem = GetTunningSystem()

    if tunningSystem == "qb-mechanicjob" then
        exports['qb-mechanicjob']:PaintCategories()
    elseif tunningSystem == "vms_tunning" then
        exports["vms_tuning"]:openTuning(nil, true)
    elseif tunningSystem == "esx_tunning" then -- https://docs.origennetwork.store/origen-admin/installation#tunning-modifications
        exports["esx_tuning"]:OpenMenu()
    elseif tunningSystem == "okokTunning" then
        TriggerServerEvent('okokTuning:openFreeMenu')
    elseif tunningSystem == "origen_customs" then
        SendNUIMessage({ action = "closeQuickMenuLua" })
        SendNUIMessage({ action = "closeAdminPanel" })
        -- Modo administración: se monta sin cobrar (el servidor vuelve a mirar el permiso).
        exports['origen_customs']:Abrir({ admin = true })
    end
end

function SetMaxVehicleFuel(vehicle)
    if GetResourceState("origen_fuel") == "started" then
        exports["origen_fuel"]:CompleteFuel(vehicle)
    elseif GetResourceState("LegacyFuel") == "started" then 
        exports["LegacyFuel"]:SetFuel(vehicle, 100)
    elseif GetResourceState("legacyfuel") == "started" then 
        exports["legacyfuel"]:SetFuel(vehicle, 100)
    elseif GetResourceState("ox_fuel") == "started" then
        SetVehicleFuelLevel(vehicle, 100.0)
        Entity(vehicle).state.fuel = 100
    elseif GetResourceState("cdn-fuel") == "started" then
        exports["cdn-fuel"]:SetFuel(vehicle, 100)
    elseif GetResourceState("ps-fuel") == "started" then
        exports["ps-fuel"]:SetFuel(vehicle, 100)
    elseif GetResourceState("qs-fuel") == "started" then
        exports["qs-fuel"]:SetFuel(vehicle, 100) 
    elseif Config.FuelSystem == "default" then 
        SetVehicleFuelLevel(vehicle, 100.0)
    end
end

function FixVehicle(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleUndriveable(vehicle, false)
    WashDecalsFromVehicle(vehicle, 1.0)
    SetVehicleFixed(vehicle)
    SetVehicleEngineOn(vehicle, true, false, false)
    SincronizarMecanica('fixvehicle', vehicle)
end

function UnlockVehicle(vehicle)
    SetVehicleDoorsLocked(vehicle, 1)
end

function BoostVehicle(vehicle)
    -- Part of the code adapted/taken from:
    -- https://github.com/tabarra/txAdmin/resource/menu/client/cl_vehicle.lua
    -- Original Author: Tabarra (https://github.com/tabarra)
    -- License: MIT
    SetVehicleCanBreak(vehicle, false)
    SetVehicleEngineCanDegrade(vehicle, false)
    SetVehicleMod(vehicle, 15, 3, false)
    SetVehicleMod(vehicle, 11, 3, false)
    SetVehicleMod(vehicle, 16, 4, false)
    SetVehicleMod(vehicle, 12, 2, false)
    SetVehicleMod(vehicle, 13, 2, false)
    ToggleVehicleMod(vehicle, 18, true)
    SetVehicleMod(vehicle, 18, 0, false)
    SetVehicleNitroEnabled(vehicle, true)
    SetVehicleTurboPressure(vehicle, 100.0)
    EnableVehicleExhaustPops(vehicle, true)
    SetVehicleCheatPowerIncrease(vehicle, 1.8)

    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel', 300.40120)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fHandBrakeForce', 10.0)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce', 20.0)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin', 2.1)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax', 2.5)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce', 2.0)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveInertia', 1.25)    
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDragCoeff', 10.0)
    SetVehicleHandlingVector(vehicle, 'CHandlingData', 'vecInertiaMultiplier', vector3(0.1, 0.1, 0.1))
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fAntiRollBarForce', 0.0001)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionLossMult', 0.00001)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fRollCentreHeightFront', 0.5)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fRollCentreHeightRear', 0.5)
end

RegisterNetEvent('origen_admin:client:TunningMenu', function()
    if not HasPermission("AdminMenu:TunningMenu") then return end
    ModifyVehicle()
end)