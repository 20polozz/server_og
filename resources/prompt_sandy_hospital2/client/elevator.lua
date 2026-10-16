-- ============================================================
-- Hospital Elevator – Teleport-based
-- Supports ox_lib context menu (default) or any custom menu.
-- Optionally uses ox_target for interaction instead of [E] key.
-- ============================================================

local hasOxLib    = GetResourceState('ox_lib')    == 'started'
local hasOxTarget = GetResourceState('ox_target') == 'started'

if not hasOxLib and not ElevatorConfig.UseCustomMenu then
    print('[prompt_sandy_hospital2] ^1Elevator disabled – ox_lib not found and no custom menu configured.^7')
    return
end

-- ============================================================
-- Helpers
-- ============================================================
local currentTextUI = nil

local function updateTextUI(newText)
    if currentTextUI == newText then return end
    if hasOxLib then
        if newText then
            lib.showTextUI(newText)
        else
            lib.hideTextUI()
        end
    end
    currentTextUI = newText
end

--- Determine whether ox_target should be used for elevator interaction.
local function shouldElevatorUseOxTarget()
    local setting = ElevatorConfig.interaction or 'auto'
    if setting == 'ox_target' then return true end
    if setting == 'textui'    then return false end
    return hasOxTarget -- 'auto'
end

-- Determine which floor the player is closest to (by Z height).
local function getNearestFloor()
    local z = GetEntityCoords(cache.ped or PlayerPedId()).z
    local best, bestDist = 1, math.huge
    for i, floor in ipairs(ElevatorConfig.Floors) do
        local d = math.abs(floor.coords.z - z)
        if d < bestDist then
            best, bestDist = i, d
        end
    end
    return best
end

-- ============================================================
-- Teleport function (globally accessible for custom menus)
-- ============================================================
function HospitalElevator_TeleportToFloor(floorIndex)
    local floor = ElevatorConfig.Floors[floorIndex]
    if not floor then return end

    local ped = cache.ped or PlayerPedId()

    -- Quick fade for a smooth transition
    DoScreenFadeOut(250)
    Wait(300)

    SetEntityCoords(ped, floor.coords.x, floor.coords.y, floor.coords.z, false, false, false, false)
    SetEntityHeading(ped, floor.heading)

    Wait(200)
    DoScreenFadeIn(250)
end

-- ============================================================
-- Menu display
-- ============================================================
local function openElevatorMenu(currentFloor)
    -- Custom menu path
    if ElevatorConfig.UseCustomMenu and ElevatorConfig.CustomMenuFunction then
        ElevatorConfig.CustomMenuFunction(ElevatorConfig.Floors, currentFloor)
        return
    end

    -- ox_lib context menu (default)
    local options = {}
    for i, floor in ipairs(ElevatorConfig.Floors) do
        if i ~= currentFloor then
            options[#options + 1] = {
                title       = floor.label,
                description = floor.description,
                icon        = floor.icon or 'building',
                onSelect    = function()
                    HospitalElevator_TeleportToFloor(i)
                end,
            }
        end
    end

    lib.registerContext({
        id      = 'hospital_elevator_menu',
        title   = ElevatorConfig.Messages.menuTitle,
        options = options,
    })
    lib.showContext('hospital_elevator_menu')
end

-- ============================================================
-- Interaction zones – one per floor
-- Supports ox_target (if available/configured) or textUI + [E]
-- ============================================================

--- Helper: register ox_target zones for all elevator floors.
local function setupElevatorOxTarget()
    local label = ElevatorConfig.Messages.prompt:gsub('%[E%]%s*', '')
    for floorIndex, zone in pairs(ElevatorConfig.Zones) do
        exports.ox_target:addBoxZone({
            coords   = zone.coords,
            size     = zone.size,
            rotation = zone.rotation,
            debug    = false,
            options  = {
                {
                    name     = 'elevator_floor_' .. floorIndex,
                    icon     = 'fas fa-elevator',
                    label    = label,
                    onSelect = function()
                        local currentFloor = getNearestFloor()
                        openElevatorMenu(currentFloor)
                    end,
                },
            },
        })
    end
end

--- Helper: register textUI + [E] zones for all elevator floors (original behaviour).
local function setupElevatorTextUI()
    for floorIndex, zone in pairs(ElevatorConfig.Zones) do
        lib.zones.box({
            coords   = zone.coords,
            size     = zone.size,
            rotation = zone.rotation,

            onEnter = function()
                updateTextUI(ElevatorConfig.Messages.prompt)
            end,

            onExit = function()
                updateTextUI(nil)
            end,

            inside = function()
                if IsControlJustPressed(0, 38) then -- E key
                    local currentFloor = getNearestFloor()
                    openElevatorMenu(currentFloor)
                end
            end,
        })
    end
end

if shouldElevatorUseOxTarget() then
    setupElevatorOxTarget()
else
    setupElevatorTextUI()
end

-- ============================================================
-- Cleanup on resource stop
-- ============================================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    updateTextUI(nil)
end)
