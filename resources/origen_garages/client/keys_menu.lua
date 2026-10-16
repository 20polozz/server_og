-- Dynamic Keys Management System using org-menu and org-input

local function OpenSharedKeysMenu()
    local menu = {
        {
            header = "Gestión de Llaves",
            isMenuHeader = true,
            icon = "fa-solid fa-key"
        },
        {
            header = "Compartir Llaves a Distancia",
            txt = "Comparte llaves con un jugador por su ID de servidor",
            icon = "fa-solid fa-share-nodes",
            params = {
                isAction = true,
                event = function()
                    local vehicles = lib.callback.await('origen_garages:cb:getMyVehiclesList', false)
                    if not vehicles or #vehicles == 0 then
                        Custom.Notify('No posees ningún vehículo registrado a tu nombre', 'error')
                        OpenSharedKeysMenu()
                        return
                    end
                    
                    local subMenu = {
                        {
                            header = "Selecciona tu Vehículo",
                            isMenuHeader = true,
                            icon = "fa-solid fa-car"
                        }
                    }
                    
                    for _, veh in ipairs(vehicles) do
                        table.insert(subMenu, {
                            header = veh.label,
                            txt = "Matrícula: " .. veh.plate,
                            icon = "fa-solid fa-car-side",
                            params = {
                                isAction = true,
                                event = function()
                                    local input = exports['org-input']:ShowInput({
                                        header = 'Compartir Llaves',
                                        submitText = 'Confirmar',
                                        icon = 'fa-solid fa-key',
                                        inputs = {
                                            {
                                                type = "number",
                                                name = "targetId",
                                                text = "ID del Jugador Destino",
                                                isRequired = true
                                            }
                                        }
                                    })
                                    
                                    if not input or not input.targetId then
                                        OpenSharedKeysMenu()
                                        return
                                    end
                                    
                                    local targetId = tonumber(input.targetId)
                                    local success, msg = lib.callback.await('origen_garages:cb:shareKeyRemotely', false, veh.plate, targetId)
                                    if success then
                                        Custom.Notify(msg, 'success')
                                    else
                                        Custom.Notify(msg or 'No se pudo compartir las llaves', 'error')
                                    end
                                    OpenSharedKeysMenu()
                                end
                            }
                        })
                    end
                    
                    exports['org-menu']:openMenu(subMenu)
                end
            }
        },
        {
            header = "Compartir con Alguien Cercano",
            txt = "Comparte llaves con un jugador que esté cerca de ti",
            icon = "fa-solid fa-users",
            params = {
                isAction = true,
                event = function()
                    local nearbyPlayers = lib.callback.await('origen_garages:cb:getNearbyPlayersInfo', false)
                    if not nearbyPlayers or #nearbyPlayers == 0 then
                        Custom.Notify('No hay ningún jugador cerca de ti', 'error')
                        OpenSharedKeysMenu()
                        return
                    end
                    
                    local vehicles = lib.callback.await('origen_garages:cb:getMyVehiclesList', false)
                    if not vehicles or #vehicles == 0 then
                        Custom.Notify('No posees ningún vehículo registrado a tu nombre', 'error')
                        OpenSharedKeysMenu()
                        return
                    end
                    
                    local subMenu = {
                        {
                            header = "Selecciona tu Vehículo",
                            isMenuHeader = true,
                            icon = "fa-solid fa-car"
                        }
                    }
                    
                    for _, veh in ipairs(vehicles) do
                        table.insert(subMenu, {
                            header = veh.label,
                            txt = "Matrícula: " .. veh.plate,
                            icon = "fa-solid fa-car-side",
                            params = {
                                isAction = true,
                                event = function()
                                    local playerSelectMenu = {
                                        {
                                            header = "Selecciona Jugador",
                                            isMenuHeader = true,
                                            icon = "fa-solid fa-user"
                                        }
                                    }
                                    
                                    for _, ply in ipairs(nearbyPlayers) do
                                        table.insert(playerSelectMenu, {
                                            header = ply.name,
                                            txt = "Pulsa para entregarle las llaves",
                                            icon = "fa-solid fa-user-plus",
                                            params = {
                                                isAction = true,
                                                event = function()
                                                    local success, msg = lib.callback.await('origen_garages:cb:shareKeyRemotely', false, veh.plate, ply.id)
                                                    if success then
                                                        Custom.Notify(msg, 'success')
                                                    else
                                                        Custom.Notify(msg or 'No se pudo compartir las llaves', 'error')
                                                    end
                                                    OpenSharedKeysMenu()
                                                end
                                            }
                                        })
                                    end
                                    
                                    exports['org-menu']:openMenu(playerSelectMenu)
                                end
                            }
                        })
                    end
                    
                    exports['org-menu']:openMenu(subMenu)
                end
            }
        },
        {
            header = "Llaves que he Prestado",
            txt = "Administra y revoca llaves dadas a otros jugadores",
            icon = "fa-solid fa-user-check",
            params = {
                isAction = true,
                event = function()
                    local lentKeys = lib.callback.await('origen_garages:cb:getLentKeys', false)
                    if not lentKeys or #lentKeys == 0 then
                        Custom.Notify('No has prestado las llaves de ningún vehículo', 'info')
                        OpenSharedKeysMenu()
                        return
                    end
                    
                    local subMenu = {
                        {
                            header = "Llaves Prestadas",
                            isMenuHeader = true,
                            icon = "fa-solid fa-user-minus"
                        }
                    }
                    
                    for _, key in ipairs(lentKeys) do
                        table.insert(subMenu, {
                            header = string.format("%s (%s)", key.vehicleLabel, key.plate),
                            txt = "Prestadas a: " .. key.targetName,
                            icon = "fa-solid fa-user-xmark",
                            params = {
                                isAction = true,
                                event = function()
                                    -- Show org-input to confirm
                                    local confirm = exports['org-input']:ShowInput({
                                        header = '¿Revocar Llaves?',
                                        submitText = 'Confirmar Revocación',
                                        icon = 'fa-solid fa-trash-can',
                                        inputs = {
                                            {
                                                type = "select",
                                                name = "sure",
                                                text = "¿Estás seguro?",
                                                options = {
                                                    { value = "yes", text = "Sí, revocar acceso" },
                                                    { value = "no", text = "No, mantener acceso" }
                                                },
                                                isRequired = true
                                            }
                                        }
                                    })
                                    
                                    if confirm and confirm.sure == "yes" then
                                        local success, msg = lib.callback.await('origen_garages:cb:revokeKeyRemotely', false, key.plate, key.targetCitizen)
                                        if success then
                                            Custom.Notify('Has revocado las llaves correctamente', 'success')
                                        else
                                            Custom.Notify(msg or 'No se pudo revocar las llaves', 'error')
                                        end
                                    end
                                    OpenSharedKeysMenu()
                                end
                            }
                        })
                    end
                    
                    exports['org-menu']:openMenu(subMenu)
                end
            }
        },
        {
            header = "Llaves que me han Prestado",
            txt = "Devuelve llaves de coches compartidos contigo",
            icon = "fa-solid fa-handshake",
            params = {
                isAction = true,
                event = function()
                    local borrowedKeys = lib.callback.await('origen_garages:cb:getBorrowedKeys', false)
                    if not borrowedKeys or #borrowedKeys == 0 then
                        Custom.Notify('Nadie te ha compartido llaves de su vehículo', 'info')
                        OpenSharedKeysMenu()
                        return
                    end
                    
                    local subMenu = {
                        {
                            header = "Llaves Recibidas",
                            isMenuHeader = true,
                            icon = "fa-solid fa-undo"
                        }
                    }
                    
                    for _, key in ipairs(borrowedKeys) do
                        table.insert(subMenu, {
                            header = string.format("%s (%s)", key.vehicleLabel, key.plate),
                            txt = "Dueño: " .. key.ownerName,
                            icon = "fa-solid fa-arrow-rotate-left",
                            params = {
                                isAction = true,
                                event = function()
                                    local confirm = exports['org-input']:ShowInput({
                                        header = '¿Devolver Llaves?',
                                        submitText = 'Confirmar Devolución',
                                        icon = 'fa-solid fa-right-from-bracket',
                                        inputs = {
                                            {
                                                type = "select",
                                                name = "sure",
                                                text = "¿Estás seguro?",
                                                options = {
                                                    { value = "yes", text = "Sí, devolver llaves" },
                                                    { value = "no", text = "No, quedármelas" }
                                                },
                                                isRequired = true
                                            }
                                        }
                                    })
                                    
                                    if confirm and confirm.sure == "yes" then
                                        local success, msg = lib.callback.await('origen_garages:cb:returnKeyRemotely', false, key.plate)
                                        if success then
                                            Custom.Notify('Has devuelto las llaves exitosamente', 'success')
                                        else
                                            Custom.Notify(msg or 'No se pudo devolver las llaves', 'error')
                                        end
                                    end
                                    OpenSharedKeysMenu()
                                end
                            }
                        })
                    end
                    
                    exports['org-menu']:openMenu(subMenu)
                end
            }
        }
    }
    
    exports['org-menu']:openMenu(menu)
end

-- Command for players to easily manage keys anywhere
RegisterCommand('llaves', function()
    OpenSharedKeysMenu()
end, false)

RegisterCommand('misllaves', function()
    OpenSharedKeysMenu()
end, false)

-- Trigger integration event if needed or client exports
exports('OpenKeysManagementMenu', OpenSharedKeysMenu)
