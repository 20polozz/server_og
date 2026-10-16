local cruisecontrol = false
local speedlimiter = false

RegisterNUICallback('GetMenuData', function(data, cb)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if vehicle > 0 and GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
        local vehclass = GetVehicleClass(vehicle)

        if vehclass ~= 13 and  vehclass ~= 21 then
            local doors = {}

            for i = 0, 6 do
                if DoesVehicleHaveDoor(vehicle, 0) then
                    table.insert(doors, {
                        id = i,
                        closed = GetVehicleDoorAngleRatio(vehicle, i) == 0
                    })
                end
            end

            cb({
                doors = doors,
                speedlimiter = speedlimiter,
                cruisecontrol = cruisecontrol,
                motor = GetIsVehicleEngineRunning(vehicle) == 1,
                ismoto = vehclass == 8,
                isboat = vehclass == 14,
                drift = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDragCoeff") > 90,
                vehname = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
            })
        else
            cb(false)
        end
    else
        cb(false)
    end
end)


RegisterCommand('trucos', function(source, args, raw)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local vehclass = GetVehicleClass(vehicle)

    if vehclass ~= 8 then
        return Bridge.Notify(locale:t('notify.notricks'))
    end
    
    if vehicle > 0 and GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
        local menu = {
            {
                header = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))),
                isMenuHeader = true, 
            },
            { 
                header = locale:t('nui.LayDown'),
                txt= locale:t('nui.LayDown_desc'), 
                icon="fa-solid fa-motorcycle",
                action = "origen_inventory:client:acrobatic",
                value = "idle_a",
            },
            { 
                header = locale:t('nui.PeekLeft'),
                txt= locale:t('nui.PeekLeft_desc'), 
                icon="fa-solid fa-motorcycle",
                action = "origen_inventory:client:acrobatic",
                value = "idle_b",
            },
            { 
                header = locale:t('nui.PeekRight'),
                txt= locale:t('nui.PeekRight_desc'), 
                icon="fa-solid fa-motorcycle",
                action = "origen_inventory:client:acrobatic",
                value = "idle_c",
            },
            { 
                header = locale:t('nui.SideToSide'),
                txt= locale:t('nui.SideToSide_desc'), 
                icon="fa-solid fa-motorcycle",
                action = "origen_inventory:client:acrobatic",
                value = "idle_d",
            },
            { 
                header = locale:t('nui.Surf'),
                txt= locale:t('nui.Surf_desc'), 
                icon="fa-solid fa-motorcycle",
                action = "origen_inventory:client:acrobatic",
                value = "idle_e",
            }
        }
        Bridge.OpenMenu(menu)
    else
        Bridge.Notify(locale:t('notify.NoInVehicle'))
    end
end, false)

RegisterNetEvent("origen_inventory:client:acrobatic", function(animName)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, true) then
        RequestAnimDict("rcmextreme2atv")
        while not HasAnimDictLoaded("rcmextreme2atv") do
            Wait(10)
        end
        TaskPlayAnim(ped, "rcmextreme2atv", animName, 8.0, 1.0, -1, 32, 32, false, false, false)
    end
end)


local GetVehiclePedIsIn = GetVehiclePedIsIn
local lastVehicle = nil
local lastRadarState = nil

local function updateVehicleState(vehicle)
    local state = vehicle and true or false 
    
    InventoryUI.Emit({
        action = 'updateVehicleState',
        state = state
    })
end

function updateRadarState(state)
    InventoryUI.Emit({
        action = 'updateRadarState',
        state = state
    })
end

CreateThread(function()

	while true do
		local ped = PlayerPedId()

        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle > 0 then
            if vehicle ~= lastVehicle then
                updateVehicleState(vehicle)
            end

            lastVehicle = vehicle
        else
            if lastVehicle then
                updateVehicleState(false)
                lastVehicle = nil
            end
        end

        local isRadarEnabled = not IsRadarHidden()

        if isRadarEnabled ~= lastRadarState then
            updateRadarState(isRadarEnabled)
            lastRadarState = isRadarEnabled
        end

        Wait(100)
	end
end)