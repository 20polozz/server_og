local TriggerServerEvent   = TriggerServerEvent
local GetPedLastDamageBone = GetPedLastDamageBone

local useOxInventory       = lib.load("config").useOxInventory

function checkInjuryCause(cause)
    local item = "bandage"
    local consumeItemPerUse = tonumber(GetEMSConfigVal("consumeItemPerUse", 10)) or 10

    if cause == "beaten" then
        item = "icepack"
    elseif cause == "stabbed" then
        item = "suturekit"
    elseif cause == "shot" then
        item = "tweezers"
    elseif cause == "burn" or cause == "fire" then -- llega como "burn" (data/weapons.lua)
        item = "burncream"
    end


    utils.debug(item, cause)

    local hasItem = Framework.hasItem(item)
    if not hasItem then return utils.showNotification(locale("not_enough_" .. item)) end

    if useOxInventory then
        local itemDurability = utils.getItem(item)?.metadata?.durability

        if itemDurability then
            if itemDurability < consumeItemPerUse then
                utils.showNotification(locale("no_durability"))
                return false
            end
        end
    end

    utils.useItem(item, consumeItemPerUse)

    return true
end


function checkInjuries(data)
    utils.debug(data.injuries)

    local menu = {
        {
            header = locale("injury_menu_title") or "Informe de Lesiones",
            isMenuHeader = true,
            icon = "fas fa-heart-pulse",
        }
    }

    if not data.injuries or not next(data.injuries) then
        menu[#menu + 1] = {
            header = locale('no_injuries') or "Sin lesiones detectadas",
            txt = "El paciente no presenta traumatismos ni heridas graves",
            icon = "fas fa-check-circle",
            isMenuHeader = true,
        }
    else
        for _, v in pairs(data.injuries) do
            menu[#menu + 1] = {
                header = v.label or "Lesión",
                txt = (v.desc or "Traumatismo") .. " | Gravedad: " .. (v.value or 0) .. "%",
                icon = "fas fa-user-injured",
                params = {
                    isAction = true,
                    event = function()
                        local detailMenu = {
                            {
                                header = (v.label or "Lesión") .. " (" .. (v.value or 0) .. "%)",
                                isMenuHeader = true,
                                icon = "fas fa-stethoscope",
                            },
                            {
                                header = "Gravedad: " .. (v.value or 0) .. "%",
                                txt = v.desc or "Estado de la zona afectada",
                                icon = "fas fa-gauge-high",
                                isMenuHeader = true,
                            },
                            {
                                header = "Causa: " .. (locale(v.cause) or v.cause or "Desconocida"),
                                txt = "Tipo de impacto o traumatismo detectado",
                                icon = "fas fa-triangle-exclamation",
                                isMenuHeader = true,
                            },
                            {
                                header = locale("injury_treat") or "Tratar Lesión",
                                txt = "Aplicar el material médico correspondiente a la herida",
                                icon = "fas fa-hand-holding-medical",
                                params = {
                                    isAction = true,
                                    event = function()
                                        if checkInjuryCause(v.cause) then
                                            if lib.progressBar({
                                                    duration = 2000 * ((v.value or 10) / 10),
                                                    label = locale("treating_injury") or "Tratando lesión...",
                                                    useWhileDead = false,
                                                    canCancel = true,
                                                    disable = {
                                                        car = true,
                                                        move = true
                                                    },
                                                    anim = {
                                                        scenario = "CODE_HUMAN_MEDIC_TEND_TO_DEAD"
                                                    }
                                                })
                                            then
                                                local dataToSend = {}
                                                dataToSend.targetServerId = data.target
                                                dataToSend.injury = true
                                                dataToSend.bone = v.bone
                                                -- El plus lo paga el servidor en healPlayer. Aquí se
                                                -- ingresaba otra vez desde el cliente, y ese camino ya no existe.
                                                TriggerServerEvent("origen_ambulancejob:healPlayer", dataToSend)

                                                utils.showNotification(locale("injury_treated") or "Lesión tratada correctamente", "success")
                                                utils.debug("Injury treated " .. dataToSend.bone)
                                            else
                                                utils.showNotification(locale("operation_canceled") or "Operación cancelada", "error")
                                            end
                                        end
                                    end
                                }
                            },
                            {
                                header = "Volver",
                                txt = "Regresar al listado de lesiones",
                                icon = "fas fa-arrow-left",
                                params = {
                                    isAction = true,
                                    event = function()
                                        checkInjuries(data)
                                    end
                                }
                            }
                        }

                        utils.openMenu(detailMenu)
                    end
                }
            }
        end
    end

    if data.targetPed and DoesEntityExist(data.targetPed) then
        menu[#menu + 1] = {
            header = "Volver al Diagnóstico",
            txt = "Regresar al menú principal del paciente",
            icon = "fas fa-arrow-left",
            params = {
                isAction = true,
                event = function()
                    checkPatient(data.targetPed)
                end
            }
        }
    end

    menu[#menu + 1] = {
        header = "Cerrar",
        txt = "Cerrar informe",
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

function treatInjury(bone)
    if not player.injuries[bone] then return end -- secure check

    player.injuries[bone] = nil
    LocalPlayer.state:set("injuries", player.injuries, true)

    local playerHealth = GetEntityHealth(cache.ped)
    local playerMaxHealth = GetEntityMaxHealth(cache.ped)
    local newHealth = math.min(playerHealth + 10, playerMaxHealth)

    utils.debug("current", playerHealth)
    utils.debug("max", playerMaxHealth)
    utils.debug("new", newHealth, type(newHealth))

    SetEntityHealth(cache.ped, newHealth)
end

local bodyParts = lib.load("data.body_parts")
local weapons = lib.load("data.weapons")
function updateInjuries(victim, weapon)
    local found, lastDamagedBone = GetPedLastDamageBone(victim)

    local damagedBone = bodyParts[tostring(lastDamagedBone)]

    utils.debug("Damaged bone ", lastDamagedBone, damagedBone and damagedBone.label or "unknown")

    if damagedBone then
        if not player.injuries[damagedBone.id] then
            player.injuries[damagedBone.id] = { bone = damagedBone.id, label = damagedBone.label, desc = damagedBone.levels["default"], value = player.isDead and 100 or 10, cause = weapons[weapon] and weapons[weapon][2] or "not found" }
        else
            local newVal = math.min(player.injuries[damagedBone.id].value + 10, 100)
            player.injuries[damagedBone.id].value = newVal
            player.injuries[damagedBone.id].desc = damagedBone.levels[tostring(newVal)] or damagedBone.levels["default"]
        end

        LocalPlayer.state:set("injuries", player.injuries, true)
    end
end
