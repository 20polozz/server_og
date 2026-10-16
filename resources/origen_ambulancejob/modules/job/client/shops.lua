local useOrigenPolicePoints = lib.load("config").useOrigenPolicePoints
if useOrigenPolicePoints then return end

local DrawMarker            = DrawMarker
local IsControlJustReleased = IsControlJustReleased
local CreateThread          = CreateThread
local ox_inventory          = (GetResourceState('ox_inventory') == 'started') and exports.ox_inventory
local hospitals             = lib.load("data.hospitals")
local emsJobs               = lib.load("config").emsJobs

local function createShops()
    for _, hospital in pairs(hospitals) do
        for name, pharmacy in pairs(hospital.pharmacy) do
            if pharmacy.blip.enable then
                utils.createBlip(pharmacy.blip)
            end

            lib.points.new({
                coords = pharmacy.pos,
                distance = 3,
                onEnter = function(self)
                    if pharmacy.job then
                        if Framework.hasJob(emsJobs) and Framework.getPlayerJobGrade() >= pharmacy.grade then
                            self.access = true
                            lib.showTextUI(locale('control_to_open_shop'))
                        else
                            self.access = false
                        end
                    else
                        self.access = true
                        lib.showTextUI(locale('control_to_open_shop'))
                    end
                end,
                onExit = function()
                    lib.hideTextUI()
                end,
                nearby = function(self)
                    if self.access then
                        DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0, 1.0, 216, 27, 85, 200, false, true, 2, false, nil, nil, false)

                        if self.currentDistance < 1 and IsControlJustReleased(0, 38) then
                            if GetResourceState('origen_inventory') == 'started' then
                                return exports['origen_inventory']:openInventory("shop", { type = name })
                            elseif GetResourceState('ox_inventory') == 'started' then
                                return exports.ox_inventory:openInventory("shop", { type = name })
                            end


                            local items = {}

                            local menu = {
                                {
                                    header = pharmacy.label or "Farmacia SAMS",
                                    isMenuHeader = true,
                                    icon = "fas fa-pills",
                                }
                            }

                            for i = 1, #pharmacy.items do
                                local item = pharmacy.items[i]
                                menu[#menu + 1] = {
                                    header = item.label,
                                    txt = "Precio: $" .. (item.price or 0),
                                    icon = item.icon or "fas fa-box-medical",
                                    params = {
                                        isAction = true,
                                        event = function()
                                            local amount = lib.inputDialog(locale("pharmacy_buying_quantity_title") or "Cantidad", {
                                                { type = 'number', label = locale("pharmacy_buying_quantity") or "Cantidad a comprar", icon = 'hashtag' },
                                            })
                                            if not amount then return end

                                            local quantity = tonumber(amount[1]) or 1
                                            if quantity <= 0 then return end
                                            -- Cobro y entrega en el servidor, de una vez y con los
                                            -- precios de data/hospitals: si no se cobra, no se entrega.
                                            local comprado = lib.callback.await('origen_ambulancejob:server:comprarFarmacia', false, name, item.name, quantity)
                                            if not comprado then return end
                                            utils.showNotification("Has comprado " .. quantity .. "x " .. item.label, "success")
                                        end
                                    }
                                }
                            end

                            menu[#menu + 1] = {
                                header = "Cerrar",
                                txt = "Cerrar farmacia",
                                icon = "fas fa-xmark",
                                params = {
                                    isAction = true,
                                    event = function()
                                        utils.closeMenu()
                                    end
                                }
                            }

                            utils.openMenu(menu)
                        end
                    end
                end
            })
        end
    end
end
CreateThread(createShops)
