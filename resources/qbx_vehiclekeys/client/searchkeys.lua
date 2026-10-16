local config = require 'config.client'
local isSearchLocked = false
local isSearchAllowed = false

local function setSearchLabelState(isAllowed)
    if isSearchLocked and isAllowed then return end
    if isAllowed and cache.vehicle and GetVehicleConfig(cache.vehicle).findKeysChance == 0.0 then
        isSearchAllowed = false
        return
    end
    local isOpen, text = lib.isTextUIOpen()
    -- ox_lib (retocado) separa «[H] - texto» y lo manda a origen_notify con la tecla aparte.
    -- (es.json trae solo el texto; los demás idiomas aún lo traen con «[H] - » delante)
    local newText = '[H] - ' .. locale('info.search_keys_dispatch'):gsub('^%[H%]%s*%-%s*', '')
    local isValidMessage = text and text == newText
    if isAllowed and not isValidMessage and cache.seat == -1 then
        lib.showTextUI(newText)
    elseif (not isAllowed or cache.seat ~= -1) and isOpen and isValidMessage then
        lib.hideTextUI()
    end

    isSearchAllowed = isAllowed and cache.seat == -1
end

local function getDifficultyByClass(vehicleClass)
    if vehicleClass >= 0 and vehicleClass <= 3 then return 'medium' end  -- Compacts, Sedans, SUVs, Coupes
    if vehicleClass >= 4 and vehicleClass <= 7 then return 'hard' end    -- Muscle, Sports, Classics, Super
    if vehicleClass == 8 or vehicleClass == 9 then return 'extreme' end  -- Motorcycles, Off-road
    if vehicleClass == 18 then return 'hard' end                         -- Emergency
    return 'medium'
end

local function findKeys(vehicleClass, vehicle)
    local difficulty = getDifficultyByClass(vehicleClass)

    exports['origen_minijuegos']:StartWirePuzzle(difficulty, function(success)
        CreateThread(function()
            local found = false
            if success then
                found = lib.callback.await('qbx_vehiclekeys:server:findKeys', false, VehToNet(vehicle))
                if not found then
                    TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
                    exports.qbx_core:Notify(locale('notify.failed_keys'), 'error')
                end
            else
                TriggerServerEvent('hud:server:GainStress', math.random(1, 4))
                exports.qbx_core:Notify(locale('notify.failed_keys'), 'error')
            end

            SetTimeout(10000, function()
                SendPoliceAlertAttempt('steal', vehicle)
            end)

            Wait(config.timeBetweenHotwires)
            isSearchLocked = false
            setSearchLabelState(not found)
        end)
    end)
end

local searchKeysKeybind = lib.addKeybind({
    name = 'searchkeys',
    description = locale('info.search_keys'),
    defaultKey = 'H',
    secondaryMapper = 'PAD_DIGITALBUTTONANY',
    secondaryKey = 'LRIGHT_INDEX',
    disabled = true,
    onPressed = function()
        if isSearchAllowed and cache.vehicle then
            isSearchLocked = true
            setSearchLabelState(false)
            local vehicle = cache.vehicle
            if not GetIsVehicleAccessible(vehicle) then
                findKeys(GetVehicleClass(vehicle), vehicle)
            else
                isSearchLocked = false
                setSearchLabelState(true)
            end
        end
    end
})

function GetKeySearchEnabled()
    return isSearchAllowed
end

function EnableKeySearch()
    setSearchLabelState(true)
    searchKeysKeybind:disable(false)
end

function DisableKeySearch()
    setSearchLabelState(false)
    searchKeysKeybind:disable(true)
end