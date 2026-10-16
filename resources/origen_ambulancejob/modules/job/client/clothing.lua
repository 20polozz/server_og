local useInternalClothing = lib.load("config").clothingScript
local useOrigenPolicePoints = lib.load("config").useOrigenPolicePoints
if not useInternalClothing or useOrigenPolicePoints then
    function initClothes() end
    function unloadClothes() end
    return
end

local FreezeEntityPosition            = FreezeEntityPosition
local SetEntityInvincible             = SetEntityInvincible
local SetBlockingOfNonTemporaryEvents = SetBlockingOfNonTemporaryEvents

local function openClothingMenu(clothes)
    local menu = {
        {
            header = locale("clothesmenu_label") or "Vestuario SAMS",
            isMenuHeader = true,
            icon = "fas fa-shirt",
        },
        {
            header = locale('clothesmenu_civilian_label') or "Ropa Civil",
            txt = locale('clothesmenu_civilian_description') or "Ponerse la ropa de civil",
            icon = "fas fa-shirt",
            params = {
                isAction = true,
                event = function()
                    if lib.progressBar({
                            duration = 3000,
                            label = locale("clothesmenu_civilian_use") or "Cambiándose de ropa...",
                            useWhileDead = false,
                            allowCuffed = false,
                            canCancel = false,
                            disable = {
                                car = true,
                                move = true,
                                combat = true,
                            },
                            anim = {
                                dict = 'clothingshirt',
                                clip = 'try_shirt_positive_d'
                            },
                        }) then
                        Framework.toggleClothes(false, clothes)
                    end
                end
            }
        },
        {
            header = locale('clothesmenu_job_label') or "Uniforme Médico",
            txt = locale('clothesmenu_job_description') or "Ponerse el uniforme de servicio",
            icon = "fas fa-user-doctor",
            params = {
                isAction = true,
                event = function()
                    Framework.toggleClothes(true, clothes)
                end
            }
        },
        {
            header = "Cerrar",
            txt = "Cerrar vestuario",
            icon = "fas fa-xmark",
            params = {
                isAction = true,
                event = function()
                    utils.closeMenu()
                end
            }
        }
    }

    utils.openMenu(menu)
end

local clothingPoints = {}

function initClothes(data, jobs)
    local ped = utils.createPed(data.model, data.pos)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    local point = lib.points.new({
        coords = data.pos.xyz,
        distance = 2.5,
        onEnter = function(self)
            if not cache.vehicle and Framework.hasJob(jobs) then
                lib.showTextUI('[E] - ' .. locale('clothing_interact_label'))
            end
        end,
        onExit = function(self)
            lib.hideTextUI()
        end,
        nearby = function(self)
            if not cache.vehicle and Framework.hasJob(jobs) then
                if self.currentDistance < 2.0 and IsControlJustReleased(0, 38) then
                    openClothingMenu(data)
                end
            end
        end
    })

    table.insert(clothingPoints, point)
end

function unloadClothes()
    for _, point in pairs(clothingPoints) do
        point:remove()
    end
    clothingPoints = {}
end
