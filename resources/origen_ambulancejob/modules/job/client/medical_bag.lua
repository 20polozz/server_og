local TaskStartScenarioInPlace         = TaskStartScenarioInPlace
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local TaskPlayAnim                     = TaskPlayAnim
local Wait                             = Wait
local CreateObjectNoOffset             = CreateObjectNoOffset
local PlaceObjectOnGroundProperly      = PlaceObjectOnGroundProperly
local DeleteEntity                     = DeleteEntity
local ClearPedTasks                    = ClearPedTasks
local RegisterNetEvent                 = RegisterNetEvent

local medicBagProp                     = lib.load("config").medicBagProp
local useOxInventory                   = lib.load("config").useOxInventory

local function openMedicalBag()
    local playerPed = cache.ped or PlayerPedId()

    TaskStartScenarioInPlace(playerPed, "CODE_HUMAN_MEDIC_TEND_TO_DEAD")

    lib.callback('origen_ambulancejob:openMedicalBag', false, function(stash)
        if GetResourceState('origen_inventory') == 'started' then
            exports['origen_inventory']:openInventory("stash", stash)
        elseif GetResourceState('ox_inventory') == 'started' then
            exports.ox_inventory:openInventory("stash", stash)
        end
    end)
end

local function placeMedicalBag()
    lib.requestAnimDict("pickup_object")
    lib.requestModel(medicBagProp)

    local playerPed = cache.ped or PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.5, 0.0)

    TaskPlayAnim(playerPed, "pickup_object", "pickup_low", 8.0, 8.0, 1000, 50, 0, false, false, false)

    Wait(900)

    medicBag = CreateObjectNoOffset(medicBagProp, coords.x, coords.y, coords.z, true, false)
    PlaceObjectOnGroundProperly(medicBag)

    utils.addRemoveItem("remove", "medicalbag", 1)

    local thisBag = medicBag
    local bagPoint = lib.points.new({
        coords = coords,
        distance = 2.0,
        onEnter = function(self)
            if not cache.vehicle and DoesEntityExist(thisBag) then
                lib.showTextUI('[E] - ' .. locale('open_medical_bag') .. '  |  [G] - ' .. locale('pickup_medical_bag'))
            end
        end,
        onExit = function(self)
            lib.hideTextUI()
        end,
        nearby = function(self)
            if not cache.vehicle and DoesEntityExist(thisBag) then
                if self.currentDistance < 1.8 then
                    if IsControlJustReleased(0, 38) then -- [E]
                        openMedicalBag()
                    elseif IsControlJustReleased(0, 47) then -- [G]
                        local pPed = cache.ped or PlayerPedId()
                        TaskPlayAnim(pPed, "pickup_object", "pickup_low", 8.0, 8.0, 1000, 50, 0, false, false, false)
                        Wait(900)
                        if DoesEntityExist(thisBag) then
                            DeleteEntity(thisBag)
                        end
                        ClearPedTasks(pPed)
                        lib.hideTextUI()
                        self:remove()
                        utils.addRemoveItem("add", "medicalbag", 1)
                    end
                end
            else
                lib.hideTextUI()
                self:remove()
            end
        end
    })
end

local emsJobs = lib.load("config").emsJobs

RegisterNetEvent("origen_ambulancejob:placeMedicalBag", function()
    if not Framework.hasJob(emsJobs) then return end

    placeMedicalBag()
end)
RegisterNetEvent("ars_ambulancejob:placeMedicalBag", function()
    TriggerEvent("origen_ambulancejob:placeMedicalBag")
end)
