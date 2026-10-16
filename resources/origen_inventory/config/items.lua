--[[
   ___       _                    ___                      _
  / _ \ _ __(_) __ _  ___ _ __   |_ _|_ ____   _____ _ __ | |_ ___  _ __ _   _
 | | | | '__| |/ _` |/ _ \ '_ \   | || '_ \ \ / / _ \ '_ \| __/ _ \| '__| | | |
 | |_| | |  | | (_| |  __/ | | |  | || | | \ V /  __/ | | | || (_) | |  | |_| |
  \___/|_|  |_|\__, |\___|_| |_| |___|_| |_|\_/ \___|_| |_|\__\___/|_|   \__, |
               |___/                                                     |___/
    Origen Inventory by Origen Network

    Note:
    . Add the items to this file and forget about adding them to other files.
    . This file is only for defining items and their properties.
    . If you want to add custom weapons, please use config/weapons.lua

    Note 2:
    . When adding a item, this file has higher priority
      than any other item lists (qb or Items.old) there is no need to add them anywhere else.

    Note 3 - Perishable items:
    . `decay` is the shelf life in HOURS. An item without it never expires.
    . `perishable = false` opts an item out even if it has a `decay` value.
    . Shelf life is spent at the rate of whatever container holds the item, so a
      stash with `coldStorage = { rate = 0.25 }` makes food last 4x longer.
      See Config.Decay and Config.Stashes in config/stashes.lua.
]]
local items = {
    -- Herramienta del aserradero de Paleto (origen_lumber): la presta la
    -- caseta y se devuelve al acabar la jornada.
    hacha_lenador = {
        label = 'Hacha de leñador',
        weight = 2500,
        stack = false,
        close = true,
        image = 'weapon_hatchet.png',
        description = 'Herramienta del aserradero de Paleto. Solo sirve para talar: se devuelve al acabar la jornada.',
    },

    motosierra = {
        label = 'Motosierra',
        weight = 7000,
        stack = false,
        close = true,
        image = 'drill.png',
        description = 'Motosierra de tala. Corta en poco más de la mitad de tiempo que el hacha, pero gasta gasolina.',
    },

    medicalbag = {
        label = 'Bolsa Médica',
        weight = 500,
        stack = false,
        close = true,
        image = 'police_medkit.png',
        description = 'Kit médico completo para tratar heridas y transportar material sanitario.',
    },

    bandage = {
        label = 'Vendaje',
        weight = 100,
        stack = true,
        close = true,
        image = 'bandage.png',
        description = 'Vendaje médico utilizado para curar y proteger heridas.',
    },

    defibrillator = {
        label = 'Desfibrilador',
        weight = 1000,
        -- Se apila: origen_ambulancejob ya no lo gasta al reanimar (es equipo).
        stack = true,
        close = true,
        description = 'Dispositivo médico para reanimación cardiopulmonar.',
    },

    tweezers = {
        label = 'Pinzas Médicas',
        weight = 100,
        stack = true,
        close = true,
        description = 'Pinzas de precisión para extracción de proyectiles y cuerpos extraños.',
    },

    burncream = {
        label = 'Crema para Quemaduras',
        weight = 100,
        stack = true,
        close = true,
        image = 'burn_gel.png',
        description = 'Pomada especializada para calmar y tratar quemaduras.',
    },

    suturekit = {
        label = 'Kit de Sutura',
        weight = 150,
        stack = true,
        close = true,
        image = 'suture_kit.png',
        description = 'Material quirúrgico estéril para suturar y cerrar heridas abiertas.',
    },

    icepack = {
        label = 'Bolsa de Hielo',
        weight = 200,
        stack = true,
        close = true,
        description = 'Bolsa de frío para reducir inflamaciones y contusiones.',
    },

    stretcher = {
        label = 'Camilla Médica',
        weight = 2000,
        stack = false,
        close = true,
        client = {
            event = 'origen_ambulancejob:toggleStretcherItem'
        },
        description = 'Camilla de emergencias para el traslado de pacientes.',
    },

    pepperspray = {
        label = 'Spray Pimienta',
        weight = 500,
        stack = false,
        close = true,
        description = 'Gas pimienta de dotación policial. Incapacita temporalmente al objetivo.'
    },

    splint = {
        label = 'Férula',
        weight = 500,
        stack = true,
        close = true,
        description = 'Se utiliza para inmovilizar huesos fracturados o dislocados.',
    },

    tosti        = {
        label = 'Sándwich de Queso',
        description = 'Rico para comer...',
        weight = 220,
        uses = 3,
        stack = true,
        close = true,
        client = {
            status = { hunger = 200000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            prop = {
                model = 'prop_cs_burger_01',
                pos = { x = 0.02, y = 0.02, z = -0.02 },
                rot = { x = 0.0, y = 0.0, z = 0.0 },
                bone = 18905
            },
            usetime = 2500,
            -- Aqui venian dos botones de ejemplo del recurso, 'Hola' y 'Adiós',
            -- que solo escribian en la consola y salian en la ficha del objeto.
        }
    },

    vehicle_keys = {
        label = 'Llaves del Vehículo',
        weight = 50,
        stack = false,
        description = 'Llaves de un vehículo.',
    },

    boosting_cad = {
        label = 'Tablet de Boosting',
        weight = 100,
        stack = false,
        description = 'Probablemente puedes usar esta tablet para acciones ilegales.',
    },

    tablet_racing = {
        label = 'Tablet Racing (Lite)',
        weight = 100,
        stack = false,
        description = 'Dispositivo con acceso limitado al sistema de carreras.',
        client = {
            export = 'origen_racing.UseTabletRacing'
        }
    },

    tablet_racingfull = {
        label = 'Tablet Racing (Full)',
        weight = 100,
        stack = false,
        description = 'Dispositivo con acceso completo al sistema de carreras.',
        client = {
            export = 'origen_racing.UseTabletRacingFull'
        }
    },

    locator_remover = {
        label = 'Eliminador de Localizador',
        weight = 100,
        stack = false,
        description = 'Parece un eliminador para un tipo específico de señal.',
    },

    cartera = {
        label = 'Cartera',
        weight = 50,
        stack = false,
        close = true,
        bagProps = {
            maxweight = 1000000,
            slots = 30,
            label = "Mi Cartera"
        },
        description = 'Una cartera para guardar documentación.',
        client = {
            export = 'origen_inventory.openCartera',
            buttons = {
                {
                    label = 'Abrir Cartera',
                    action = function(slot, metadata)
                        local bagProps = exports.origen_inventory:Items('cartera').bagProps or {
                            maxweight = 1000000,
                            slots = 30,
                            label = "Mi Cartera"
                        }
                        exports.origen_inventory:openInventory('stash', string.format('cartera-%s', metadata.bagId), bagProps)
                    end
                }
            }
        }
    },


    -- An example of an item that opens another inventory when used
    paperbag     = {
        label = 'Bolsa de Papel',
        weight = 100,
        stack = true,
        -- 20 kg y 10 huecos: con 5 kg no cabia ni la compra de un negocio.
        bagProps = {
            maxweight = 20000,
            slots = 10,
            label = "Mi Bolsa Simple"
        },
        description = 'Una simple bolsa de papel para llevar objetos.',
        client = {
            export = 'origen_inventory.openBolsa',
            buttons = {
                {
                    label = 'Abrir Bolsa',
                    action = function(slot, metadata)
                        local bagProps = exports.origen_inventory:Items('paperbag').bagProps or {
                            maxweight = 20000,
                            slots = 10,
                            label = "Mi Bolsa Simple"
                        }
                        exports.origen_inventory:openInventory('stash', string.format('paperbag-%s', metadata.bagId), bagProps)
                    end
                }
            }
        }
    },
    percha = {
        label = 'Percha de conjunto',
        weight = 350,
        stack = false,
        close = false,
        description = 'Guarda y equipa un conjunto completo de ropa en un solo item.',
        -- Nota: en el frontend actual, cuando se define `image` sin slash inicial
        -- puede resolverse mal la ruta. Lo forzamos con `/` para evitarlo.
        image = '/percha.png',
        client = {
            buttons = {
                {
                    label = 'Abrir percha',
                    action = function(slot, metadata)
                        Bridge.TriggerCallback('origen_inventory:hanger:prepareOpen', function(success, data)
                            if not success or not data then
                                Bridge.Notify('No se pudo abrir la percha.', 'error')
                                return
                            end

                            exports.origen_inventory:openInventory('stash', data.stashId, {
                                label = data.label or 'Percha de conjunto',
                                slots = data.slots or 20,
                                maxweight = data.maxweight or 25000
                            })
                        end, slot)
                    end
                },
                {
                    label = 'Renombrar percha',
                    action = function(slot, metadata)
                        local dialog = exports['org-input']:ShowInput({
                            header = 'Renombrar Percha',
                            submitText = 'Guardar',
                            inputs = {
                                {
                                    name = 'name',
                                    type = 'text',
                                    text = 'Nombre del conjunto',
                                    default = metadata and metadata.perchaName or 'Percha de conjunto',
                                    isRequired = true,
                                }
                            }
                        })

                        if not dialog or not dialog.name then return end

                        Bridge.TriggerCallback('origen_inventory:hanger:rename', function(success, newName)
                            if not success then
                                Bridge.Notify('No se pudo renombrar la percha.', 'error')
                                return
                            end

                            Bridge.Notify(('Percha renombrada a: %s'):format(newName or dialog.name), 'success')
                        end, slot, dialog.name)
                    end
                },
                {
                    label = 'Equipar conjunto',
                    action = function(slot, metadata)
                        if GetResourceState('origen_clothing') ~= 'started' then
                            Bridge.Notify('origen_clothing no esta iniciado.', 'error')
                            return
                        end

                        Bridge.TriggerCallback('origen_inventory:hanger:canEquipSet', function(canEquip, reason)
                            if not canEquip then
                                local preCheckMessage = reason == 'empty_hanger' and 'La percha no tiene prendas guardadas.' or
                                    reason == 'hanger_busy' and 'La percha esta siendo usada, espera un momento.' or
                                    'No se puede equipar este conjunto ahora.'
                                Bridge.Notify(preCheckMessage, 'error')
                                return
                            end

                            local ped = PlayerPedId()
                            exports['origen_inventory']:progressBar({
                                name = 'hanger_equip_set',
                                duration = 20000,
                                label = 'Cambiandote de ropa...',
                                useWhileDead = false,
                                canCancel = true,
                                controlDisables = {
                                    disableMovement = true,
                                    disableCarMovement = true,
                                    disableMouse = false,
                                    disableCombat = true,
                                },
                                animation = {
                                    animDict = 'clothingtie',
                                    anim = 'try_tie_positive_a',
                                    flags = 49,
                                },
                            }, function(cancelled)
                                if cancelled then
                                    Bridge.Notify('Cambio de ropa cancelado.', 'error')
                                    return
                                end

                                local equippedHashes = exports.origen_clothing:GetEquippedClothes(ped, true) or {}
                                Bridge.TriggerCallback('origen_inventory:hanger:equipSet', function(success, payload)
                                    if not success then
                                        local errorMessage = payload == 'inventory_full' and 'No tienes espacio para devolver la ropa equipada.' or
                                            payload == 'empty_hanger' and 'La percha no tiene prendas guardadas.' or
                                            payload == 'hanger_busy' and 'La percha esta siendo usada, espera un momento.' or
                                            'No se pudo equipar el conjunto.'
                                        Bridge.Notify(errorMessage, 'error')
                                        return
                                    end

                                    local applyItems = payload and payload.applyItems or {}
                                    if #applyItems == 0 then
                                        Bridge.Notify('No hay prendas validas para equipar.', 'error')
                                        return
                                    end

                                    for _, clothingData in ipairs(applyItems) do
                                        if clothingData.type == 'props' then
                                            exports.origen_clothing:SetPedPropByHash(ped, clothingData.hash, true)
                                        else
                                            exports.origen_clothing:SetPedDrawableByHash(ped, clothingData.hash, true)
                                        end
                                    end

                                    Bridge.Notify('Conjunto equipado correctamente.', 'success')
                                end, slot, equippedHashes)
                            end)
                        end, slot)
                    end
                }
            }
        }
    },

    perchas = {
        label = 'Percha',
        weight = 350,
        stack = false,
        close = false,
        description = 'Guarda y equipa un conjunto completo de ropa en un solo item.',
        image = '/percha.png',
    },
    tool_screwdriver = {
        label = 'Destornillador',
        weight = 1,
        stack = true,
        close = true,
        description = 'Sirve para destornillar cosas.'
    },

    rpg_ammo = {
        label = 'Cohete de RPG',
        weight = 300,
        stack = true,
        close = true,
        description = 'Munición para el lanzacohetes.'
    },

    ['ammo-beanbag'] = {
        label = 'Balas de goma',
        weight = 7,
        stack = true,
        close = true,
        description = 'Munición no letal para escopeta de goma.',
    },

    -- El telefono del servidor. Ya no hay un segundo item para lb-phone: el
    -- aparato es este, y su imagen es ui/images/ognphone.png.
    ognphone     = {
        label = "Teléfono OGN",
        weight = 190,
        stack = false,
        description = "Un movil con OGN de serie.",
        client = {
            export = "origen_phone.UsePhoneItem",
            remove = function()
                TriggerEvent("origen_phone:cl:itemRemoved")
            end,
            add = function()
                TriggerEvent("origen_phone:cl:itemAdded")
            end
        }
    },

    -- Tints
    -- Weapon Tints
    suppressor_attachment = {
        label = 'Silenciador',
        weight = 100,
        type = 'attachment',
        attachment = 'suppressor',
        description = 'Reduce el ruido del disparo.'
    },
    clip_attachment = {
        label = 'Cargador Ampliado',
        weight = 100,
        type = 'attachment',
        attachment = 'clip',
        description = 'Aumenta la capacidad de munición.'
    },
    drum_attachment = {
        label = 'Cargador de Tambor',
        weight = 150,
        type = 'attachment',
        attachment = 'clip',
        description = 'Gran capacidad de munición.'
    },
    flashlight_attachment = {
        label = 'Linterna',
        weight = 100,
        type = 'attachment',
        attachment = 'flashlight',
        description = 'Añade una linterna táctica al arma.',
    },
    smallscope_attachment = {
        label = 'Mira Pequeña',
        weight = 100,
        type = 'attachment',
        attachment = 'scope',
        description = 'Mejora la precisión a corta distancia.'
    },
    medscope_attachment = {
        label = 'Mira Mediana',
        weight = 100,
        type = 'attachment',
        attachment = 'scope',
        description = 'Mejora la precisión a media distancia.'
    },
    largescope_attachment = {
        label = 'Mira Larga',
        weight = 100,
        type = 'attachment',
        attachment = 'scope',
        description = 'Mejora la precisión a larga distancia.'
    },
    holoscope_attachment = {
        label = 'Mira Holográfica',
        weight = 100,
        type = 'attachment',
        attachment = 'scope',
        description = 'Mira holográfica para corta-media distancia.'
    },
    advscope_attachment = {
        label = 'Mira Avanzada',
        weight = 100,
        type = 'attachment',
        attachment = 'scope',
        description = 'Mira telescópica avanzada.'
    },
    nvscope_attachment = {
        label = 'Mira Nocturna',
        weight = 150,
        type = 'attachment',
        attachment = 'scope',
        description = 'Visión nocturna acoplable.'
    },
    thermalscope_attachment = {
        label = 'Mira Térmica',
        weight = 150,
        type = 'attachment',
        attachment = 'scope',
        description = 'Mira con visión térmica.'
    },
    grip_attachment = {
        label = 'Empuñadura',
        weight = 100,
        type = 'attachment',
        attachment = 'grip',
        description = 'Mejora el control del retroceso.'
    },
    comp_attachment = {
        label = 'Compensador',
        weight = 100,
        type = 'attachment',
        attachment = 'barrel',
        description = 'Reduce el retroceso del arma.'
    },
    barrel_attachment = {
        label = 'Cañón Pesado',
        weight = 100,
        type = 'attachment',
        attachment = 'barrel',
        description = 'Aumenta el alcance efectivo.'
    },

    weapontint_0 = {
        label = 'Tinte por defecto',
        weight = 100,
        type = 'attachment',
        attachment = 'finish',
        description = 'Tinte de arma por defecto/negro'
    },
    weapontint_1 = {
        label = 'Tinte verde',
        weight = 100,
        type = 'attachment',
        attachment = 'finish',
        description = 'Tinte de arma verde'
    },
    weapontint_2 = {
        label = 'Tinte de oro',
        weight = 100,
        type = 'attachment',
        attachment = 'finish',
        description = 'Tinte de arma de oro'
    },
    weapontint_3 = {
        label = 'Tinte rosa',
        weight = 100,
        type = 'attachment',
        attachment = 'finish',
        description = 'Tinte de arma rosa',
    },
    weapontint_4 = {
        label = 'Tinte militar',
        weight = 100,
        type = 'attachment',
        attachment = 'finish',
        description = 'Tinte de arma militar'
    },
    weapontint_5 = {
        label = 'Tinte LSPD',
        weight = 100,
        type = 'attachment',
        attachment = 'finish',
        description = 'Tinte de arma LSPD'
    },
    weapontint_6 = {
        label = 'Tinte naranja',
        weight = 100,
        type = 'attachment',
        attachment = 'finish',
        description = 'Tinte de arma naranja'
    },
    weapontint_7 = {
        label = 'Tinte platino',
        weight = 100,
        type = 'attachment',
        attachment = 'finish',
        description = 'Tinte de arma de platino'
    },

    --Armors
    armor        = {
        label = 'Chaleco',
        weight = 500,
        stack = false,
        close = true,
        description = 'Un poco de protección no vendría mal... ¿verdad?'
    },
    heavyarmor   = {
        label = 'Chaleco Pesado',
        weight = 500,
        stack = false,
        close = true,
        description = 'Un poco de protección no vendría mal... ¿verdad?'
    },

    --Clothing
    masks = {
        label = 'Máscara',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    neck = {
        label = 'Accesorio de Cuello',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    jackets = {
        label = 'Chaqueta',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    vest = {
        label = 'Chaleco (Ropa)',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    shirts = {
        label = 'Camisa',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    bags = {
        label = 'Mochila',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    torsos = {
        label = 'Torso',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    legs = {
        label = 'Pantalones',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    shoes = {
        label = 'Zapatos',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    decals = {
        label = 'Accesorio',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    hats = {
        label = 'Sombrero/Gorra',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    glasses = {
        label = 'Gafas',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    watches = {
        label = 'Reloj',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    earrings = {
        label = 'Pendientes',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    bracelets = {
        label = 'Pulsera',
        weight = 1,
        stack = false,
        type = 'clothing'
    },

    ['instant_camera'] = {
        label = "Cámara Instantánea",
        weight = 200,
        server = {
            export = "origen_police.instant_camera"
        },
        consume = 0
    },
    ['photo']           = {
        label = "Foto",
        weight = 200,
        server = {
            export = "origen_police.photo"
        },
        consume = 0
    },
    ['report_evidence'] = {
        label = "Evidencia de Informe",
        weight = 200,
        server = {
            export = "origen_police.report_evidence"
        },
        consume = 0
    },
    ['k9']              = {
        label = "Silbato K9",
        weight = 200,
        server = {
            export = "origen_police.k9"
        },
        consume = 0
    },
    ['lspd_badge']      = {
        label = "Placa LSPD",
        weight = 200,
        server = {
            export = "origen_police.lspd_badge"
        },
        consume = 0
    },
    ['ems_badge']       = {
        label = "Placa EMS",
        weight = 200,
        server = {
            export = "origen_police.ems_badge"
        },
        consume = 0
    },
    ['bcsd_badge']      = {
        label = "Placa BCSD",
        weight = 200,
        server = {
            export = "origen_police.bcsd_badge"
        },
        consume = 0
    },
    ['fib_badge']       = {
        label = "Placa FIB",
        weight = 200,
        server = {
            export = "origen_police.fib_badge"
        },
        consume = 0
    },
    ['sapd_badge']      = {
        label = "Placa SAPD",
        weight = 200,
        server = {
            export = "origen_police.sapd_badge"
        },
        consume = 0
    },
    ['saspa_badge']     = {
        label = "Placa SASPA",
        weight = 200,
        server = {
            export = "origen_police.saspa_badge"
        },
        consume = 0
    },
    ['destornillador']  = {
        label = "Destornillador",
        weight = 500,
        description = "Herramienta para retirar matrículas falsas y cubiertas personalizadas.",
        client = {
            export = "origen_plates.UseScrewdriver"
        },
        consume = 0
    },
    ['fib_badge']       = {
        label = "Placa FIB",
        weight = 200,
        server = {
            export = "origen_police.fib_badge"
        },
        consume = 0
    },
    ['seguro_medico']   = {
        label = "Seguro Médico",
        weight = 50,
        stack = false,
        close = true,
        consume = 0,
        description = 'Tarjeta de seguro médico con información del paciente.'
    },
    ['licencia_card']   = {
        label = "Licencia",
        weight = 50,
        stack = false,
        close = true,
        consume = 0,
        description = 'Tarjeta de licencia con información del titular.'
    },
    ['certificado']   = {
        label = "Certificado Vehicular",
        weight = 50,
        stack = false,
        close = true,
        consume = 0,
        server = {
            export = "origen_police.certificado"
        },
        description = 'Certificado oficial asociado a un vehículo.'
    },
    ['police_cad']      = {
        label = "Tablet Policial",
        weight = 200,
        server = {
            export = "origen_police.police_cad"
        },
        consume = 0
    },
    ['ticket_radar']      = {
        label = "Multa de Radar",
        weight = 50,
        stack = false,
        close = true,
        consume = 0,
        description = 'Boletín de infracción por exceso de velocidad detectado por radar.'
    },
    ['business_tablet']      = {
        label = "Tablet de Negocio",
        weight = 200,
        server = {
            export = "origen_businesses.business_tablet"
        },
        consume = 0
    },
    ['evidence_a']      = {
        label = "Bala peritada",
        weight = 200,
        consume = 0
    },
    ['evidence_az']     = {
        label = "Evidencia",
        weight = 200,
        consume = 0
    },
    ['evidence_b']      = {
        label = "Vehículo peritado",
        weight = 200,
        consume = 0
    },
    ['evidence_n']      = {
        label = "Impacto peritado",
        weight = 200,
        consume = 0
    },
    ['evidence_ne']     = {
        label = "Huella peritada",
        weight = 200,
        consume = 0
    },
    ['evidence_r']      = {
        label = "Mancha hemática peritada",
        weight = 200,
        consume = 0
    },
    ['evidence_ro']     = {
        label = "Objeto peritado",
        weight = 200,
        consume = 0
    },
    ['evidence_v']      = {
        label = "Sustancia peritada",
        weight = 200,
        consume = 0
    },

    ['evidence_ne']      = {
        label = "Huella Dactilar",
        weight = 200,
        consume = 0
    },

    ['bidon_gasolina'] = {
        label = 'Bidón de Gasolina',
        weight = 2000,
        stack = false,
        close = true,
        description = 'Un bidón de gasolina lleno, listo para repostar un vehículo.',
        client = {
            export = 'origen_fuel.UsarBidon'
        }
    },

    -- PESCA · catalogo ampliado
    sardina = {
        label = 'Sardina',
        weight = 1,
        stack = false,
        close = true,
        description = 'Un cardumen entero cabe en la mano'
    },

    rutilo = {
        label = 'Rutilo',
        weight = 1,
        stack = false,
        close = true,
        description = 'Pez de agua dulce, plateado y nervioso'
    },

    pejerrey = {
        label = 'Pejerrey',
        weight = 1,
        stack = false,
        close = true,
        description = 'Fino, largo y con una raya plateada'
    },

    perca = {
        label = 'Perca Amarilla',
        weight = 1,
        stack = false,
        close = true,
        description = 'Rayada de amarillo y verde oliva'
    },

    caballa = {
        label = 'Caballa',
        weight = 1,
        stack = false,
        close = true,
        description = 'Lomo tornasolado, carne oscura'
    },

    mojarra = {
        label = 'Mojarra',
        weight = 1,
        stack = false,
        close = true,
        description = 'De las que muerden en la rompiente'
    },

    anguila = {
        label = 'Anguila',
        weight = 1,
        stack = false,
        close = true,
        description = 'Se retuerce hasta después de sacarla'
    },

    lucio = {
        label = 'Lucio',
        weight = 1,
        stack = false,
        close = true,
        description = 'Todo dientes y mala intención'
    },

    rocote = {
        label = 'Rocote',
        weight = 1,
        stack = false,
        close = true,
        description = 'Espinas venenosas en la aleta dorsal'
    },

    calico_bass = {
        label = 'Cabrilla Calicó',
        weight = 1,
        stack = false,
        close = true,
        description = 'Moteada como un mantel viejo'
    },

    sargo = {
        label = 'Sargo Californiano',
        weight = 1,
        stack = false,
        close = true,
        description = 'Dientes de oveja y frente abultada'
    },

    siluro = {
        label = 'Siluro',
        weight = 1,
        stack = false,
        close = true,
        description = 'Bigotudo y del fondo, pesa más de lo que parece'
    },

    lingcod = {
        label = 'Lingcod',
        weight = 1,
        stack = false,
        close = true,
        description = 'Boca enorme, carne azulada'
    },

    corvina = {
        label = 'Corvina de California',
        weight = 1,
        stack = false,
        close = true,
        description = 'Gruñe al sacarla del agua'
    },

    corvina_blanca = {
        label = 'Corvina Blanca',
        weight = 1,
        stack = false,
        close = true,
        description = 'Plateada, grande y esquiva'
    },

    pez_globo = {
        label = 'Pez Globo',
        weight = 1,
        stack = false,
        close = true,
        description = 'Se infla. Y es venenoso. Mucho cuidado'
    },

    pez_gota = {
        label = 'Pez Gota',
        weight = 1,
        stack = false,
        close = true,
        description = 'La cara más triste del océano'
    },

    raya = {
        label = 'Raya',
        weight = 1,
        stack = false,
        close = true,
        description = 'Plana, con cola de látigo'
    },

    halibut_california = {
        label = 'Halibut de California',
        weight = 1,
        stack = false,
        close = true,
        description = 'Los dos ojos del mismo lado'
    },

    halibut_pacifico = {
        label = 'Halibut del Pacífico',
        weight = 1,
        stack = false,
        close = true,
        description = 'Como una puerta con aletas'
    },

    medregal = {
        label = 'Medregal',
        weight = 1,
        stack = false,
        close = true,
        description = 'Pelea hasta el último metro de sedal'
    },

    barracuda = {
        label = 'Barracuda',
        weight = 1,
        stack = false,
        close = true,
        description = 'Una flecha con dientes'
    },

    pez_espada = {
        label = 'Pez Espada',
        weight = 1,
        stack = false,
        close = true,
        description = 'La pieza que todo pescador cuenta dos veces'
    },

    tiburon_cornudo = {
        label = 'Tiburón Cornudo',
        weight = 1,
        stack = false,
        close = true,
        description = 'Pequeño, con espinas sobre las aletas'
    },

    tiburon_gris = {
        label = 'Tiburón Gris',
        weight = 1,
        stack = false,
        close = true,
        description = 'Nunca viene solo'
    },

    tiburon_blanco = {
        label = 'Tiburón Blanco',
        weight = 1,
        stack = false,
        close = true,
        description = 'Si esto muerde el anzuelo, reza'
    },

    cangrejo = {
        label = 'Cangrejo',
        weight = 1,
        stack = false,
        close = true,
        description = 'Pinza primero, preguntas después'
    },

    langosta = {
        label = 'Langosta',
        weight = 1,
        stack = false,
        close = true,
        description = 'Cara y con antenas'
    },

    pulpo = {
        label = 'Pulpo',
        weight = 1,
        stack = false,
        close = true,
        description = 'Ocho brazos y más mala leche que ocho'
    },

    mejillon = {
        label = 'Mejillón',
        weight = 1,
        stack = false,
        close = true,
        description = 'Se agarra a la roca como si le fuera la vida'
    },

    ostras = {
        label = 'Ostras',
        weight = 1,
        stack = false,
        close = true,
        description = 'A veces traen sorpresa dentro'
    },

    tortuga_verde = {
        label = 'Tortuga Verde',
        weight = 1,
        stack = false,
        close = true,
        description = 'Protegida. Deberias devolverla al agua'
    },

    tortuga_olivacea = {
        label = 'Tortuga Olivácea',
        weight = 1,
        stack = false,
        close = true,
        description = 'La más pequeña de las marinas. Y protegida'
    },

    tortuga_laud = {
        label = 'Tortuga Laúd',
        weight = 1,
        stack = false,
        close = true,
        description = 'Sin caparazón duro. Enorme y protegida'
    },

    ballena_gris = {
        label = 'Ballena Gris',
        weight = 1,
        stack = false,
        close = true,
        description = 'Esto no deberia caber en un anzuelo'
    },

    ballena_jorobada = {
        label = 'Ballena Jorobada',
        weight = 1,
        stack = false,
        close = true,
        description = 'Canta. Y pesa como un edificio'
    },

    ballena_azul = {
        label = 'Ballena Azul',
        weight = 1,
        stack = false,
        close = true,
        description = 'El animal más grande que existe. En tu caña'
    },

    bota_vieja = {
        label = 'Bota Vieja',
        weight = 1,
        stack = false,
        close = true,
        description = 'Enganchada del talón. Clásico'
    },

    coral_negro = {
        label = 'Coral Negro',
        weight = 1,
        stack = false,
        close = true,
        description = 'Arrancado del fondo. Frágil'
    },

    coral_pilar = {
        label = 'Coral Pilar',
        weight = 1,
        stack = false,
        close = true,
        description = 'Como un órgano de piedra'
    },

    llave_oxidada = {
        label = 'Llave Oxidada',
        weight = 1,
        stack = false,
        close = true,
        description = 'Abre algo. Falta saber que'
    },

    cofre_oxidado = {
        label = 'Cofre Oxidado',
        weight = 1,
        stack = false,
        close = true,
        description = 'Cerrado. Hace falta una llave oxidada'
    },

    graphite_rod = {
        label = 'Caña de Grafito',
        weight = 1,
        stack = false,
        close = true,
        useable = true,
        description = 'Caña de grafito. Mayor durabilidad'
    },

    carbon_rod = {
        label = 'Caña de Carbono',
        weight = 1,
        stack = false,
        close = true,
        useable = true,
        description = 'Ligera y rígida. Aguanta piezas medianas'
    },

    titanium_rod = {
        label = 'Caña de Titanio',
        weight = 1,
        stack = false,
        close = true,
        useable = true,
        description = 'Caña de titanio. Para expertos'
    },

    master_rod = {
        label = 'Caña Maestra',
        weight = 1,
        stack = false,
        close = true,
        useable = true,
        description = 'La última caña que vas a necesitar'
    },

    worms = {
        label = 'Gusanos',
        weight = 1,
        stack = true,
        close = true,
        description = 'Gusanos básicos'
    },

    crickets = {
        label = 'Grillos',
        weight = 1,
        stack = true,
        close = true,
        description = 'Saltan. Y atraen a los que saltan'
    },

    grasshopper = {
        label = 'Saltamontes',
        weight = 1,
        stack = true,
        close = true,
        description = 'Grande y ruidoso en la superficie'
    },

    leech = {
        label = 'Sanguijuelas',
        weight = 1,
        stack = true,
        close = true,
        description = 'Repugnantes. Y muy eficaces'
    },

    minnows = {
        label = 'Alevines',
        weight = 1,
        stack = true,
        close = true,
        description = 'Pez pequeño para pescar pez grande'
    },

    squid = {
        label = 'Calamar',
        weight = 1,
        stack = true,
        close = true,
        description = 'Trozo de calamar. Para piezas marinas'
    },

    seaweed = {
        label = 'Alga',
        weight = 1,
        stack = true,
        close = true,
        description = 'Para los que pastan en el fondo'
    },

    pig_bait = {
        label = 'Cebo de Cerdo',
        weight = 1,
        stack = true,
        close = true,
        description = 'Casquería. Huele a kilómetros'
    },

    cow_bait = {
        label = 'Cebo de Vaca',
        weight = 1,
        stack = true,
        close = true,
        description = 'Una pieza entera. Para lo más grande'
    },

    shrimp = {
        label = 'Camarones',
        weight = 1,
        stack = true,
        close = true,
        description = 'Camarones. Atrae peces grandes'
    },

    basic_rod = {
        label = 'Caña de Pescar Básica',
        weight = 1,
        stack = false,
        close = true,
        description = 'Una caña de pescar básica para principiantes'
    },

    artificial_bait = {
        label = 'Cebo Artificial',
        weight = 1,
        stack = true,
        close = true,
        description = 'Cebo artificial para atraer peces'
    },

    anchovy = {
        label = 'Anchoa',
        weight = 1,
        stack = false,
        close = true,
        description = 'Una pequeña anchoa fresca'
    },

    trout = {
        label = 'Trucha',
        weight = 1,
        stack = false,
        close = true,
        description = 'Una trucha de agua dulce'
    },

    haddock = {
        label = 'Eglefino',
        weight = 1,
        stack = false,
        close = true,
        description = 'Un eglefino del atlántico'
    },

    salmon = {
        label = 'Salmón',
        weight = 1,
        stack = false,
        close = true,
        description = 'Un delicioso salmón'
    },

    grouper = {
        label = 'Mero',
        weight = 1,
        stack = false,
        close = true,
        description = 'Un gran mero'
    },

    piranha = {
        label = 'Piraña',
        weight = 1,
        stack = false,
        close = true,
        description = 'Una peligrosa piraña'
    },

    red_snapper = {
        label = 'Pargo Rojo',
        weight = 1,
        stack = false,
        close = true,
        description = 'Un hermoso pargo rojo'
    },

    mahi_mahi = {
        label = 'Dorado',
        weight = 1,
        stack = false,
        close = true,
        description = 'Un espectacular dorado'
    },

    tuna = {
        label = 'Atún',
        weight = 1,
        stack = false,
        close = true,
        description = 'Un gran atún'
    },

    shark = {
        label = 'Tiburón',
        weight = 1,
        stack = false,
        close = true,
        description = '¡Un tiburón! Muy raro y valioso'
    },

    speaker_small = {
        label = 'Altavoz Pequeño',
        weight = 1,
        stack = true,
        close = true,
        description = 'Un pequeño radio para escuchar música.',
        client = {
            export = "origen_speaker.PlaceSpeakerSmall"
        }
    },

    speaker_medium = {
        label = 'Altavoz Mediano 1',
        weight = 1,
        stack = true,
        close = true,
        description = 'Un altavoz mediano con buen sonido.',
        client = {
            export = "origen_speaker.PlaceSpeakerMedium"
        }
    },

    speaker_medium_1 = {
        label = 'Altavoz Mediano 2',
        weight = 1,
        stack = true,
        close = true,
        description = 'Un altavoz mediano de alta fidelidad.',
        client = {
            export = "origen_speaker.PlaceSpeakerMedium1"
        }
    },

    speaker_big = {
        label = 'Altavoz Grande',
        weight = 1,
        stack = false,
        close = true,
        description = 'Un altavoz de gran potencia.',
        client = {
            export = "origen_speaker.PlaceSpeakerBig"
        }
    },

    vehicle_papers = {
        label = 'Papeles del Vehículo',
        weight = 1,
        stack = false,
        -- Usable: los enseña origen_police (server/items.lua), por el mismo
        -- camino que el certificado vehicular. Sin esto el objeto no hacia nada.
        usable = true,
        close = true,
        consume = 0,
        description = 'Documentación oficial del vehículo con datos del propietario.',
    },

    -- ========================================
    -- ITEMS PARA MINIJUEGOS DE ROBBERIES
    -- ========================================

    lockpick = {
        label = 'Ganzúa',
        weight = 1,
        stack = true,
        close = true,
        description = 'Herramienta para forzar cerraduras. Útil para lockpicking.',
    },

    laptop_hack = {
        label = 'Laptop de Hackeo',
        weight = 1,
        stack = false,
        close = true,
        description = 'Laptop especializada con software de hackeo para sistemas de seguridad avanzados.',
    },

    wire_kit = {
        label = 'Kit de Cables',
        weight = 1,
        stack = true,
        close = true,
        description = 'Kit profesional de cables y conectores para reparaciones eléctricas.',
    },

    scanner = {
        label = 'Escáner',
        weight = 1,
        stack = false,
        close = true,
        description = 'Dispositivo escáner avanzado para análisis de frecuencias y señales.',
    },

    multimeter = {
        label = 'Multímetro',
        weight = 1,
        stack = true,
        close = true,
        description = 'Multímetro digital profesional para medición de voltaje, corriente y resistencia.',
    },

    cups = {
        label = 'Cups',
        weight = 1,
        close = true,
        consume = 0,
        client = {},
        server = {
            export = 'rcore_beerpong.cups',
        },
    },
    mixer = {
        label = 'mixer',
        weight = 1,
        close = true,
        consume = 0,
        client = {},
        server = {
            export = 'xdiskjockey.mixer',
        },
    },

    wheelchair = {
        label = 'Silla de Ruedas',
        weight = 0,
        stack = false,
        close = true,
        description = 'Una silla de ruedas para personas con movilidad reducida.',
        client = {
            export = 'origen_wheelchair.UseWheelchair'
        }
    },

    megafono = {
        label = 'Megáfono',
        weight = 1,
        stack = false,
        close = true,
        description = 'Útil para ser escuchado a larga distancia.',
    },

    microfono = {
        label = 'Micrófono',
        weight = 1,
        stack = false,
        close = true,
        description = 'Micrófono profesional para retransmisiones.',
    },

    camara_cctv = {
        label = 'Cámara CCTV',
        weight = 500,
        stack = true,
        close = true,
        description = 'Cámara de seguridad CCTV que puede ser instalada por la policía para vigilar zonas.',
        server = {
            export = 'origen_police.camara_cctv'
        },
        consume = 0,
    },
    
    lectorhuellas = {
        label = 'Lector de Huellas',
        weight = 200,
        stack = false,
        close = true,
        description = 'Escáner de huellas portátil de uso policial.',
        server = {
            export = 'origen_police.lectorhuellas'
        },
        consume = 0,
    },

    gsr = {
        label = 'Kit de GSR (Pólvora)',
        weight = 200,
        stack = false,
        close = true,
        description = 'Kit reactivo portátil para la detección de residuos de disparo (GSR).',
        server = {
            export = 'origen_police.gsr'
        },
        consume = 0,
    },

    evidence_gsr = {
        label = 'Muestra de GSR',
        weight = 200,
        stack = false,
        close = true,
        description = 'Evidencia de test de pólvora (GSR) de un sospechoso.',
        server = {
            export = 'origen_police.evidence_gsr'
        },
        consume = 0,
    },

    hisopo = {
        label = 'Hisopo Bucal (ADN)',
        weight = 100,
        stack = true,
        close = true,
        description = 'Kit esterilizado para la toma de frotis bucal y registro de perfil genético.',
        server = {
            export = 'origen_police.hisopo'
        },
        consume = 1,
    },

    evidence_dna = {
        label = 'Certificado de ADN',
        weight = 100,
        stack = false,
        close = true,
        description = 'Justificante pericial oficial de perfil genético registrado en CODIS.',
        server = {
            export = 'origen_police.evidence_dna'
        },
        consume = 0,
    },
    -- Caza
    -- De origen_hunting: la piel de un animal legendario (sin foto propia, usa
    -- la de la piel perfecta) y el reclamo, que hace venir a la presa.
    animal_pelt_legendary = {
        label = 'Piel Legendaria',
        weight = 400,
        stack = true,
        close = true,
        image = 'animal_pelt_perfect.png',
        description = 'La piel de un animal que pocos han visto. Un trofeo.',
    },
    hunting_call = {
        label = 'Reclamo de Caza',
        weight = 80,
        stack = false,
        close = true,
        image = 'binoculars.png',
        description = 'Imita la llamada de los animales. Úsalo en una zona de caza.',
    },
    hunting_bait = {
        label = 'Cebo de Caza',
        weight = 100,
        stack = true,
        close = true,
        description = 'Cebo especial para atraer animales salvajes.',
    },
    hunting_knife = {
        label = 'Cuchillo de Caza',
        weight = 250,
        stack = false,
        close = true,
        description = 'Útil para desollar animales en tareas de caza.',
    },
    deer_meat = {
        label = 'Carne de Ciervo',
        weight = 200,
        stack = true,
        close = true,
        description = 'Carne cruda de ciervo cazado.',
    },
    rabbit_meat = {
        label = 'Carne de Conejo',
        weight = 100,
        stack = true,
        close = true,
        description = 'Carne cruda de conejo cazado.',
    },
    coyote_meat = {
        label = 'Carne de Coyote',
        weight = 200,
        stack = true,
        close = true,
        description = 'Carne dura y nudosa de coyote.',
    },
    boar_meat = {
        label = 'Carne de Jabalí',
        weight = 200,
        stack = true,
        close = true,
        description = 'Carne gruesa de jabalí salvaje.',
    },
    mtlion_meat = {
        label = 'Carne de Puma',
        weight = 200,
        stack = true,
        close = true,
        description = 'Carne exótica de puma.',
    },
    animal_pelt_poor = {
        label = 'Piel de Pobre Calidad',
        weight = 300,
        stack = true,
        close = true,
        description = 'Una piel en mal estado, no vale mucho.',
    },
    animal_pelt_good = {
        label = 'Piel de Buena Calidad',
        weight = 300,
        stack = true,
        close = true,
        description = 'Una piel bastante decente.',
    },
    animal_pelt_perfect = {
        label = 'Piel Perfecta',
        weight = 300,
        stack = true,
        close = true,
        description = 'Una piel en condiciones impecables. Muy valiosa.',
    },

    -- ORIGEN WEED
    weedplant_seedf = {
        label = 'Semilla de Marihuana (Hembra)',
        weight = 1,
        stack = true,
        close = true,
        description = 'Semilla hembra para iniciar un cultivo.'
    },
    weedplant_seedm = {
        label = 'Semilla de Marihuana (Macho)',
        weight = 1,
        stack = true,
        close = true,
        description = 'Semilla macho para polinizar una planta hembra.'
    },
    plant_tub = {
        label = 'Maceta',
        weight = 250,
        stack = true,
        close = true,
        description = 'Contenedor necesario para plantar.'
    },
    empty_watering_can = {
        label = 'Regadera Vacia',
        weight = 400,
        stack = true,
        close = true,
        description = 'Regadera sin agua.'
    },
    full_watering_can = {
        label = 'Regadera Llena',
        weight = 600,
        stack = true,
        close = true,
        description = 'Regadera lista para regar plantas.'
    },
    weed_nutrition = {
        label = 'Fertilizante',
        weight = 150,
        stack = true,
        close = true,
        description = 'Nutrientes para mejorar la salud de la planta.'
    },
    water_bottle = {
        label = 'Botella de Agua',
        weight = 100,
        stack = true,
        close = true,
        description = 'Agua para llenar la regadera.'
    },
    weedplant_branch = {
        label = 'Rama de Marihuana',
        weight = 200,
        stack = true,
        close = true,
        description = 'Rama cosechada de una planta de marihuana.'
    },
    weedplant_branch_common = {
        label = 'Rama (Común)',
        weight = 200,
        stack = true,
        close = true,
        rarity = 'common',
        description = 'Rama de marihuana de calidad común.'
    },
    weedplant_branch_uncommon = {
        label = 'Rama (Poco Común)',
        weight = 200,
        stack = true,
        close = true,
        rarity = 'uncommon',
        description = 'Rama de marihuana de calidad poco común.'
    },
    weedplant_branch_rare = {
        label = 'Rama (Rara)',
        weight = 200,
        stack = true,
        close = true,
        rarity = 'rare',
        description = 'Rama de marihuana de calidad rara.'
    },
    weedplant_branch_epic = {
        label = 'Rama (Épica)',
        weight = 200,
        stack = true,
        close = true,
        rarity = 'epic',
        description = 'Rama de marihuana de calidad épica.'
    },
    weedplant_branch_legendary = {
        label = 'Rama (Legendaria)',
        weight = 200,
        stack = true,
        close = true,
        rarity = 'legendary',
        description = 'Rama de marihuana de calidad legendaria.'
    },
    weed_clone = {
        label = 'Esqueje de Marihuana',
        weight = 100,
        stack = false,
        close = true,
        rarity = 'uncommon',
        description = 'Esqueje de una planta de marihuana. Contiene la genética de la madre.'
    },

    pesticida_organico = {
        label = 'Pesticida Orgánico',
        weight = 200,
        stack = true,
        close = true,
        rarity = 'common',
        description = 'Tratamiento natural contra los ácaros. Cura la infestación sin dañar la planta.'
    },

    fungicida = {
        label = 'Fungicida',
        weight = 250,
        stack = true,
        close = true,
        rarity = 'uncommon',
        description = 'Tratamiento antifúngico de alta potencia. Combate hongos y podredumbre.'
    },

    -- ── Mesa de Procesado ────────────────────────────────────────────────────
    mesa_procesado = {
        label = 'Mesa de Procesado',
        weight = 8000,
        stack = false,
        close = true,
        rarity = 'uncommon',
        description = 'Mesa de madera para deshojar y empaquetar cosechas de marihuana.'
    },

    -- ── Brotes desojados (paso intermedio) ───────────────────────────────────
    weed_trimmed_common = {
        label = 'Brote Desojado (Común)', weight = 100, stack = true, close = true,
        rarity = 'common', description = 'Brote fresco desojado a mano. Calidad Común.'
    },
    weed_trimmed_uncommon = {
        label = 'Brote Desojado (Poco Común)', weight = 100, stack = true, close = true,
        rarity = 'uncommon', description = 'Brote fresco desojado a mano. Calidad Poco Común.'
    },
    weed_trimmed_rare = {
        label = 'Brote Desojado (Raro)', weight = 100, stack = true, close = true,
        rarity = 'rare', description = 'Brote fresco desojado a mano. Calidad Rara.'
    },
    weed_trimmed_epic = {
        label = 'Brote Desojado (Épico)', weight = 100, stack = true, close = true,
        rarity = 'epic', description = 'Brote fresco desojado a mano. Calidad Épica.'
    },
    weed_trimmed_legendary = {
        label = 'Brote Desojado (Legendario)', weight = 100, stack = true, close = true,
        rarity = 'legendary', description = 'Brote fresco desojado a mano. Calidad Legendaria.'
    },

    -- ── Paquetes empaquetados (producto final) ────────────────────────────────
    weed_packed_common = {
        label = 'Paquete de María (Común)', weight = 120, stack = true, close = true,
        rarity = 'common', description = 'María lista para la calle. Calidad Común.'
    },
    weed_packed_uncommon = {
        label = 'Paquete de María (Poco Común)', weight = 120, stack = true, close = true,
        rarity = 'uncommon', description = 'María lista para la calle. Calidad Poco Común.'
    },
    weed_packed_rare = {
        label = 'Paquete de María (Raro)', weight = 120, stack = true, close = true,
        rarity = 'rare', description = 'María lista para la calle. Calidad Rara.'
    },
    weed_packed_epic = {
        label = 'Paquete de María (Épico)', weight = 120, stack = true, close = true,
        rarity = 'epic', description = 'María lista para la calle. Calidad Épica.'
    },
    weed_packed_legendary = {
        label = 'Paquete de María (Legendario)', weight = 120, stack = true, close = true,
        rarity = 'legendary', description = 'Mercancía top. La mejor calidad del mercado.'
    },

    -- ── Tendal ───────────────────────────────────────────────────────────────
    bolsa_envasar = {
        label = 'Bolsa de Envasar',
        weight = 5,
        stack = true,
        close = true,
        description = 'Bolsa para la envasadora al vacío. Cada paquete de maría gasta una.'
    },
    bidon_agua = {
        label = 'Bidón de Agua',
        weight = 3000,
        stack = false,
        close = true,
        rarity = 'uncommon',
        description = 'Bidón azul de 60 L con grifo y embudo. Ponlo junto al cultivo: llena la regadera y se recarga cuando llueve.'
    },
    tendal = {
        label = 'Tendal de Secado',
        weight = 1500,
        stack = false,
        close = true,
        rarity = 'uncommon',
        description = 'Estructura de madera con cuerda para colgar y secar ramas de marihuana al aire libre. Cabe hasta 6 ramas.'
    },

    -- ── Ramas secas (mismo tier de rareza que las frescas, mayor valor) ──────
    weedplant_branch_dried_common = {
        label = 'Rama Seca (Común)',
        weight = 150,
        stack = true,
        close = true,
        rarity = 'common',
        description = 'Rama de maría curada al sol. Calidad Común. Lista para procesar o vender.'
    },

    weedplant_branch_dried_uncommon = {
        label = 'Rama Seca (Poco Común)',
        weight = 150,
        stack = true,
        close = true,
        rarity = 'uncommon',
        description = 'Rama de maría curada al sol. Calidad Poco Común. Lista para procesar o vender.'
    },

    weedplant_branch_dried_rare = {
        label = 'Rama Seca (Rara)',
        weight = 150,
        stack = true,
        close = true,
        rarity = 'rare',
        description = 'Rama de maría curada al sol. Calidad Rara. Lista para procesar o vender.'
    },

    weedplant_branch_dried_epic = {
        label = 'Rama Seca (Épica)',
        weight = 150,
        stack = true,
        close = true,
        rarity = 'epic',
        description = 'Rama de maría curada al sol. Calidad Épica. Lista para procesar o vender.'
    },

    weedplant_branch_dried_legendary = {
        label = 'Rama Seca (Legendaria)',
        weight = 150,
        stack = true,
        close = true,
        rarity = 'legendary',
        description = 'Rama de maría curada al sol. Calidad Legendaria. La mejor del mercado.'
    },

    black_money = {
        label = 'Dinero Negro',
        weight = 0,
        stack = true,
        close = false,
        usable = false,
        description = 'Dinero de procedencia ilegal.',
    },

    repairkit = {
        label = 'Kit de Reparación',
        weight = 2500,
        stack = true,
        close = true,
        description = 'Caja de herramientas para reparar tu vehículo (Recupera un 40% de daño).',
    },

    advancedrepairkit = {
        label = 'Kit de Reparación Avanzado',
        weight = 400,
        stack = true,
        close = true,
        description = 'Caja de herramientas avanzada para reparar tu vehículo al 100%.',
    },

    cleaningkit = {
        label = 'Kit de Limpieza',
        weight = 250,
        stack = true,
        close = true,
        description = 'Un paño y jabón para que tu coche vuelva a brillar.',
    },

    pieza_motor = {
        label = 'Motor',
        weight = 30000,
        stack = true,
        close = true,
        description = 'Bloque motor completo de recambio. Se monta en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    pieza_transmision = {
        label = 'Transmisión',
        weight = 25000,
        stack = true,
        close = true,
        description = 'Caja de cambios de recambio. Se monta en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    pieza_frenos = {
        label = 'Juego de Frenos',
        weight = 8000,
        stack = true,
        close = true,
        description = 'Discos y pinzas de freno. Se montan en la rueda.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    pieza_refrigeracion = {
        label = 'Radiador',
        weight = 12000,
        stack = true,
        close = true,
        description = 'Radiador y circuito de refrigeración. Se monta en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    pieza_inyeccion = {
        label = 'Inyectores',
        weight = 4000,
        stack = true,
        close = true,
        description = 'Rampa de inyección de recambio. Se monta en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    pieza_direccion = {
        label = 'Bomba de Dirección',
        weight = 6000,
        stack = true,
        close = true,
        description = 'Bomba de dirección asistida. Se monta en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    pieza_alternador = {
        label = 'Alternador',
        weight = 7000,
        stack = true,
        close = true,
        description = 'Alternador de recambio. Se monta en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    pieza_suspension = {
        label = 'Suspensión',
        weight = 15000,
        stack = true,
        close = true,
        description = 'Amortiguadores y muelles de recambio. Se montan en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    pieza_motor_electrico = {
        label = 'Motor Eléctrico',
        weight = 26000,
        stack = true,
        close = true,
        description = 'Motor eléctrico de recambio. Solo para vehículos eléctricos.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    pieza_bateria_ev = {
        label = 'Batería EV',
        weight = 28000,
        stack = true,
        close = true,
        description = 'Pack de baterías de tracción. Solo para vehículos eléctricos.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_aceite = {
        label = 'Aceite de Motor',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Garrafa de aceite para el cambio. Se hace en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_filtro_aire = {
        label = 'Filtro de Aire',
        weight = 800,
        stack = true,
        close = true,
        description = 'Filtro de aire de recambio. Se cambia en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_pastillas = {
        label = 'Pastillas de Freno',
        weight = 2500,
        stack = true,
        close = true,
        description = 'Juego de pastillas de freno. Se cambian en la rueda.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_filtro_combustible = {
        label = 'Filtro de Combustible',
        weight = 800,
        stack = true,
        close = true,
        description = 'Filtro de combustible de recambio. Se cambia en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_bujias = {
        label = 'Bujías',
        weight = 500,
        stack = true,
        close = true,
        description = 'Juego de bujías. Se cambian en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_liquido_frenos = {
        label = 'Líquido de Frenos',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Botella de líquido de frenos. Se cambia en la rueda.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_anticongelante = {
        label = 'Anticongelante',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Garrafa de anticongelante. Se cambia en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_correa = {
        label = 'Correa de Distribución',
        weight = 600,
        stack = true,
        close = true,
        description = 'Correa de distribución de recambio. Se cambia en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_liquido_direccion = {
        label = 'Líquido de Dirección',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Botella de líquido de dirección asistida. Se cambia en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_refrigerante_bateria = {
        label = 'Refrigerante de Batería',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Refrigerante del pack de baterías. Solo para vehículos eléctricos.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_liquido_transmision = {
        label = 'Líquido de Transmisión',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Botella de líquido de transmisión. Se cambia en el vano del motor.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_cableado_at = {
        label = 'Cableado de Alta Tensión',
        weight = 1200,
        stack = true,
        close = true,
        description = 'Mazo de cables de alta tensión. Solo para vehículos eléctricos.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    servicio_neumaticos = {
        label = 'Neumáticos',
        weight = 12000,
        stack = true,
        close = true,
        description = 'Juego de neumáticos nuevos. Se montan en la rueda.',
        client = {
            export = 'origen_mechanic.UsePartItem'
        },
    },

    kit_parche = {
        label = 'Kit de Parche',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Apaño de emergencia. No repara: deja el coche a medio gas lo justo para llegar al taller.',
        client = {
            export = 'origen_mechanic.UsePatchKit'
        },
    },

    chatarra_metal = {
        label = 'Chatarra de Metal',
        weight = 400,
        stack = true,
        close = false,
        usable = false,
        description = 'Restos metálicos recuperados de una pieza sustituida.',
    },

    chatarra_plastico = {
        label = 'Chatarra de Plástico',
        weight = 200,
        stack = true,
        close = false,
        usable = false,
        description = 'Restos de plástico recuperados de una pieza sustituida.',
    },

    chatarra_goma = {
        label = 'Chatarra de Goma',
        weight = 300,
        stack = true,
        close = false,
        usable = false,
        description = 'Restos de goma recuperados de una pieza sustituida.',
    },

    chatarra_cobre = {
        label = 'Chatarra de Cobre',
        weight = 350,
        stack = true,
        close = false,
        usable = false,
        description = 'Restos de cobre recuperados de una pieza sustituida.',
    },

    herramienta_diagnostico = {
        label = 'Herramienta de Diagnóstico',
        weight = 1800,
        stack = false,
        close = true,
        description = 'Escáner de centralita. Junto al vano del motor lee el estado real del vehículo y permite presupuestar el trabajo.',
        client = {
            export = 'origen_mechanic.UseDiagnosticTool'
        },
    },

    libro_servicio = {
        label = 'Libro de Servicio',
        weight = 400,
        stack = false,
        close = true,
        description = 'Registro de mantenimiento de un vehículo. Muestra todo lo que se le ha cambiado y con cuántos kilómetros.',
        client = {
            export = 'origen_mechanic.UseServiceBook'
        },
    },

    herramienta_chapa = {
        label = 'Útil de Chapista',
        weight = 2500,
        stack = false,
        close = true,
        description = 'Peine, calibre y linterna. Hay que rodear el vehículo y revisar los cuatro costados para levantar el parte de carrocería.',
        client = {
            export = 'origen_mechanic.UseBodyInspector'
        },
    },

    pieza_puerta = {
        label = 'Puerta de Vehículo',
        weight = 18000,
        stack = true,
        close = true,
        description = 'Puerta de recambio sin pintar. Se monta en el hueco correspondiente.',
        client = {
            export = 'origen_mechanic.UseBodyPartItem'
        },
    },

    pieza_capo = {
        label = 'Capó de Vehículo',
        weight = 14000,
        stack = true,
        close = true,
        description = 'Capó de recambio sin pintar. Se monta en el frontal.',
        client = {
            export = 'origen_mechanic.UseBodyPartItem'
        },
    },

    pieza_porton = {
        label = 'Portón de Vehículo',
        weight = 14000,
        stack = true,
        close = true,
        description = 'Portón trasero de recambio sin pintar. Se monta en la zaga.',
        client = {
            export = 'origen_mechanic.UseBodyPartItem'
        },
    },

    pieza_rueda = {
        label = 'Rueda Completa',
        weight = 12000,
        stack = true,
        close = true,
        description = 'Llanta con neumático montado. Sustituye una rueda reventada o arrancada.',
        client = {
            export = 'origen_mechanic.UseBodyPartItem'
        },
    },

    pieza_luna = {
        label = 'Luna de Vehículo',
        weight = 9000,
        stack = true,
        close = true,
        description = 'Cristal de recambio. Sustituye una ventanilla, el parabrisas o la luneta.',
        client = {
            export = 'origen_mechanic.UseBodyPartItem'
        },
    },

    black_money = {
        label = 'Dinero Negro',
        weight = 0,
        stack = true,
        close = false,
        usable = false,
        description = 'Dinero de procedencia ilegal.',
    },

    tirekit = {
        label = 'Kit de Neumáticos',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Kit para reparar neumáticos pinchados.',
    },
    cone = {
        label = 'Cono',
        weight = 500,
        max = 5,
        stack = true,
        close = true,
        description = 'Cono de tráfico para señalización.'
    },
    barrier = {
        label = 'Barrera',
        weight = 2000,
        max = 2,
        stack = true,
        close = true,
        description = 'Barrera para bloquear el paso.'
    },
    signal = {
        label = 'Señal',
        weight = 1000,
        max = 2,
        stack = true,
        close = true,
        description = 'Señalización policial.'
    },
    spikes = {
        label = 'Banda de Pinchos',
        weight = 3000,
        max = 1,
        stack = true,
        close = true,
        description = 'Pinchos para detener vehículos policiales.'
    },
    radar = {
        label = 'Radar de Velocidad',
        weight = 1500,
        max = 1,
        stack = true,
        close = true,
        description = 'Dispositivo para medir la velocidad.'
    },

    -- Documentación y Licencias
    --[[ Los documentos que hacen los negocios (origen_businesses, pestaña
         Documentos del panel). El texto no va en el objeto: el objeto lleva
         `docId` y el documento vive en la tabla origen_businesses_documentos,
         así que no se puede falsificar cambiando la metadata. Al usarlo se
         abre para leerlo, firmarlo si le falta tu firma, o enseñarlo.
         La hoja no se apila (cada una es una); las tarjetas iguales sí. ]]
    documento_negocio = {
        label = 'Documento',
        weight = 10,
        stack = false,
        unique = true,
        usable = true,
        close = true,
        description = 'Un documento en papel de un negocio: contrato, recibo o escrito.'
    },
    tarjeta_negocio = {
        label = 'Tarjeta',
        weight = 2,
        stack = true,
        unique = false,
        usable = true,
        close = true,
        description = 'Una tarjeta de un negocio: de visita o carné de empleado.'
    },
    --[[ La membresia del casino (recurso origen_casino_membresia). La tarjeta lleva
         en sus metadatos de quien es y cuando caduca; no se apila porque cada
         una es de su titular. ]]
    --[[ La membresia de un gimnasio que es un negocio (origen_gym, Config.Negocio).
         Lleva en sus metadatos de que negocio es y cuando caduca; se compra en
         la propia maquina. No se apila: cada una es de un gimnasio y una fecha. ]]
    membresia_gimnasio = {
        label = 'Membresía de gimnasio',
        weight = 0,
        stack = false,
        unique = true,
        usable = false,
        close = true,
        image = 'licencia_card.png',
        description = 'Tarjeta de socio de un gimnasio. Sirve en el que la vendió, hasta la fecha que pone.'
    },
    casino_membresia = {
        label = 'Membresía del Casino',
        weight = 0,
        stack = false,
        unique = true,
        usable = true,
        close = true,
        image = 'casino_membresia.png',
        description = 'Tarjeta personal de socio del casino. Se renueva cada semana en el mostrador de la entrada.'
    },
    id_card = {
        label = 'Documento de Identidad',
        weight = 0,
        stack = false,
        unique = true,
        usable = true,
        close = true,
        description = 'Documento que acredita la identidad del ciudadano.'
    },
    licencia_card = {
        label = 'Licencia Personal',
        weight = 0,
        stack = false,
        unique = true,
        usable = true,
        close = true,
        description = 'Licencia genérica para diversas acreditaciones.'
    },
    licenciapesca_card = {
        label = 'Licencia de Pesca',
        weight = 0,
        stack = false,
        unique = true,
        usable = true,
        close = true,
        description = 'Acreditación oficial para realizar actividades de pesca.'
    },
    licenciacaza_card = {
        label = 'Licencia de Caza',
        weight = 0,
        stack = false,
        unique = true,
        usable = true,
        close = true,
        description = 'Acreditación oficial para realizar actividades de caza.'
    },
    licenciaarma_card = {
        label = 'Licencia de Armas',
        weight = 0,
        stack = false,
        unique = true,
        usable = true,
        close = true,
        description = 'Acreditación oficial para el porte y uso de armas.'
    },
    -- origen_autoescuela: el carné de conducir. Lo da la autoescuela; usarlo
    -- lo enseña a quien tengas delante y la clase va en los metadatos.
    licencia_conducir = {
        label = 'Carné de Conducir',
        weight = 0,
        stack = false,
        unique = true,
        usable = true,
        close = true,
        description = 'Carné de conducir expedido por la Autoescuela de Los Santos.'
    },
    -- origen_aviacion: la da la escuela de vuelo de Sandy. Usarla la enseña a
    -- quien tengas delante; el nivel y el número van en los metadatos.
    licencia_piloto = {
        label = 'Licencia de Piloto',
        weight = 0,
        stack = false,
        unique = true,
        usable = true,
        close = true,
        description = 'Licencia de piloto expedida por la Escuela de Vuelo de Sandy Shores.'
    },

    -- ── origen_plates: items de conducción / racing ────────────────────────────

    oxido_nitroso = {
        label       = 'Óxido Nitroso',
        weight      = 300,
        stack       = true,
        close       = true,
        description = 'Botella de NOS. Activa un impulso de velocidad durante 8 segundos mientras conduces.',
        client = {
            export = 'origen_plates.UseNitrous'
        }
    },

    kit_reparacion = {
        label       = 'Kit de Reparación Rápida',
        weight      = 800,
        stack       = true,
        close       = true,
        description = 'Repara chapa, motor y depósito al instante. Tarda unos segundos en aplicarse.',
        client = {
            export = 'origen_plates.UseRepairKit'
        }
    },

    bidon_combustible = {
        label       = 'Bidón de Combustible',
        weight      = 600,
        stack       = true,
        close       = true,
        description = 'Llena el depósito del vehículo al 100%. Compatible con sistemas de combustible del servidor.',
        client = {
            export = 'origen_plates.UseFuelCan'
        }
    },

    detector_radar = {
        label       = 'Detector de Radar',
        weight      = 150,
        stack       = true,
        close       = true,
        description = 'Dispositivo que detecta vehículos policiales en un radio de 200m y emite una alerta. Activo 10 minutos.',
        client = {
            export = 'origen_plates.UseRadarDetector'
        }
    },

    -- ── origen_plates: matrículas ──────────────────────────────────────────────
    matricula_personalizada = {
        label       = 'Matrícula Personalizada',
        weight      = 50,
        stack       = true,
        close       = true,
        description = 'Permite cambiar la matrícula de tu vehículo de forma permanente y legal.',
        client = {
            export = 'origen_plates.UseCustomPlate'
        }
    },

    matricula_falsa = {
        label       = 'Matrícula Falsa',
        weight      = 50,
        stack       = true,
        close       = true,
        description = 'Matrícula aleatoria no registrada. La policía puede detectarla en el MDT.',
        client = {
            export = 'origen_plates.UseFakePlate'
        }
    },

    -- ── origen_plates: items de durabilidad y sabotaje ─────────────────────────

    jaula_seguridad = {
        label       = 'Jaula de Seguridad',
        weight      = 500,
        stack       = true,
        close       = true,
        description = 'Refuerza la estructura del vehículo durante 10 minutos.',
        client = {
            export = 'origen_plates.UseJaulaSeguidad'
        }
    },

    localizador_gps = {
        label       = 'Localizador GPS',
        weight      = 50,
        stack       = true,
        close       = true,
        description = 'Instala un rastreador oculto en el vehículo más cercano. Muestra su posición en el mapa durante 10 minutos.',
        client = {
            export = 'origen_plates.UseLocalizadorGPS'
        }
    },

    inhibidor_velocidad = {
        label       = 'Inhibidor de Velocidad',
        weight      = 200,
        stack       = true,
        close       = true,
        description = 'Sabotea el sistema de gestión del motor del vehículo objetivo. Limita su velocidad máxima a unos 43 km/h.',
        client = {
            export = 'origen_plates.UseInhibidorVelocidad'
        }
    },

    bomba_ruedas = {
        label       = 'Bomba de Ruedas',
        weight      = 300,
        stack       = true,
        close       = true,
        description = 'Dispositivo explosivo de pequeño calibre que se adhiere a las ruedas. Detona en 45 segundos y revienta todos los neumáticos.',
        client = {
            export = 'origen_plates.UseBombaRuedas'
        }
    },

    sabotaje_motor = {
        label       = 'Kit de Sabotaje de Motor',
        weight      = 400,
        stack       = true,
        close       = true,
        description = 'Manipula componentes críticos del motor. El fallo se produce varios segundos después de arrancar el vehículo.',
        client = {
            export = 'origen_plates.UseSabotajeMotor'
        }
    },

    pinchos_carretera = {
        label       = 'Pinchos de Carretera',
        weight      = 600,
        stack       = true,
        close       = true,
        description = 'Franja de pinchos desplegable. Pincha las ruedas delanteras de cualquier vehículo que pase por encima. 2 usos / 45 segundos.',
        client = {
            export = 'origen_plates.UsePinchosCarretera'
        }
    },
    antilag = {
        label       = 'Kit Antilag',
        weight      = 400,
        stack       = true,
        close       = true,
        description = 'Instala un sistema de antilag en tu vehículo. Genera explosiones de escape automáticas al soltar el acelerador a RPM alta. Úsalo de nuevo para desinstalarlo.',
        client = {
            export = 'origen_plates.UseAntilag'
        }
    },

    desinstalador_antilag = {
        label       = 'Kit Desinstalador de Antilag',
        weight      = 400,
        stack       = true,
        close       = true,
        description = 'Permite desmontar y desinstalar el sistema de antilag de un vehículo.',
        client = {
            export = 'origen_plates.UseRemoveAntilag'
        }
    },

    print_image = {
        label = 'Lámina de Dibujo',
        weight = 100,
        stack = true,
        description = 'Una lámina en blanco lista para imprimir.',
        close = true
    },

    image_printed = {
        label = 'Documento impreso',
        weight = 100,
        stack = true,
        description = 'Un documento con una imagen impresa.',
        close = true
    },

    spray_can = {
        label       = 'Spray',
        weight      = 300,
        stack       = true,
        close       = true,
        description = 'Bote de spray para grafitear. Solo los miembros de una banda pueden usarlo.',
    },

    cleaning_rag = {
        label       = 'Trapo de limpieza',
        weight      = 150,
        stack       = true,
        close       = true,
        description = 'Trapo empapado en disolvente para borrar grafitis. Acércate a uno y úsalo.',
    },

    graffiti_spray = {
        label       = 'Spray de Graffiti',
        weight      = 300,
        stack       = false,
        close       = true,
        description = 'Bote de spray para graffiti. El color y la durabilidad están guardados en el bote.',
    },

    graffiti_eraser = {
        label       = 'Borrador de Graffiti',
        weight      = 200,
        stack       = false,
        close       = true,
        description = 'Borra trazos del lienzo de graffiti. Tiene durabilidad limitada.',
    },
    ['emergency_lights_kit'] = {
        label = "Kit de luces de emergencia",
        weight = 2000,
        stack = true,
        consume = 0,
        server = {
            export = 'kq_emergency.UseItem',
        },
    },

    radio = {
        label = 'Radio',
        weight = 500,
        stack = false,
        close = false,
        description = 'Radio de comunicaciones para el gang.',
    },

    -- ══════════════════════════════════════════════════════════════════════════
    -- ORIGEN_ILEGALV2 — Labs
    -- ══════════════════════════════════════════════════════════════════════════

    -- ── METH LAB ──────────────────────────────────────────────────────────────

    ephedrine = {
        label       = 'Efedrina',
        weight      = 100,
        stack       = true,
        close       = true,
        description = 'Precursor químico para la producción de metanfetamina.',
    },

    acetone = {
        label       = 'Acetona',
        weight      = 200,
        stack       = true,
        close       = true,
        description = 'Solvente químico. Necesario para el proceso de cocción.',
    },

    empty_weed_bag = {
        label       = 'Bolsa Vacía',
        weight      = 10,
        stack       = true,
        close       = true,
        description = 'Bolsa de plástico vacía. Usada para empaquetar productos.',
    },

    methbags = {
        label       = 'Bolsas de Meta',
        weight      = 150,
        stack       = true,
        close       = true,
        description = 'Metanfetamina cristalizada lista para distribución.',
    },

    -- ── COKE LAB ──────────────────────────────────────────────────────────────

    coca_leaf = {
        label       = 'Hoja de Coca',
        weight      = 50,
        stack       = true,
        close       = true,
        description = 'Hoja de coca cruda. Materia prima para el procesado.',
    },

    coke = {
        label       = 'Polvo Base',
        weight      = 80,
        stack       = true,
        close       = true,
        description = 'Polvo de cocaína sin procesar. Producto intermedio.',
    },

    bakingsoda = {
        label       = 'Bicarbonato',
        weight      = 50,
        stack       = true,
        close       = true,
        description = 'Bicarbonato de sodio. Agente de corte para cocaína.',
    },

    loosecoke = {
        label       = 'Cocaína Cortada',
        weight      = 80,
        stack       = true,
        close       = true,
        description = 'Cocaína cortada lista para embolsar.',
    },

    cokebaggy = {
        label       = 'Bolsa de Cocaína',
        weight      = 100,
        stack       = true,
        close       = true,
        description = 'Cocaína embolsada lista para distribución.',
    },

    -- ── WEED LAB ──────────────────────────────────────────────────────────────

    wetcannabis = {
        label       = 'Cannabis Húmedo',
        weight      = 100,
        stack       = true,
        close       = true,
        description = 'Flor de cannabis recién cosechada. Debe secarse.',
    },

    drycannabis = {
        label       = 'Cannabis Seco',
        weight      = 60,
        stack       = true,
        close       = true,
        description = 'Cannabis seco listo para moler.',
    },

    weedgrinder = {
        label       = 'Grinder',
        weight      = 200,
        stack       = false,
        close       = true,
        description = 'Molino de hierba. No se consume al usarse.',
    },

    grindedweed = {
        label       = 'Cannabis Molido',
        weight      = 40,
        stack       = true,
        close       = true,
        description = 'Cannabis molido listo para embolsar.',
    },

    bluntwrap = {
        label       = 'Papel de Liar',
        weight      = 10,
        stack       = true,
        close       = true,
        description = 'Papel para liar blunts.',
    },

    blunt = {
        label       = 'Blunt',
        weight      = 30,
        stack       = true,
        close       = true,
        description = 'Blunt liado listo para la venta.',
    },
    album = {
        label = 'Álbum de Cartas',
        weight = 500,
        stack = false,
        description = 'Un álbum para guardar tu colección de cartas.',
        close = true,
        client = { export = 'origen_AlbumCards.album' }
    },
    albumpack = {
        label = 'Sobre de Cartas',
        weight = 100,
        stack = true,
        description = 'Contiene cartas coleccionables. Ábrelo para ver qué te toca.',
        close = true,
        client = { export = 'origen_AlbumCards.albumpack' }
    },
    albumcardcommon = {
        label = 'Carta Coleccionable',
        weight = 0,
        stack = false,
        description = 'Una carta rara de colección.',
        close = true,
        client = { export = 'origen_AlbumCards.albumcard' }
    },
    albumcardunrare = {
        label = 'Carta Coleccionable',
        weight = 0,
        stack = false,
        description = 'Una carta rara de colección.',
        close = true,
        client = { export = 'origen_AlbumCards.albumcard' }
    },
    albumcardrare = {
        label = 'Carta Coleccionable',
        weight = 0,
        stack = false,
        description = 'Una carta rara de colección.',
        close = true,
        client = { export = 'origen_AlbumCards.albumcard' }
    },
    albumcardepic = {
        label = 'Carta Coleccionable',
        weight = 0,
        stack = false,
        description = 'Una carta rara de colección.',
        close = true,
        client = { export = 'origen_AlbumCards.albumcard' }
    },
    albumcardlegendary = {
        label = 'Carta Coleccionable',
        weight = 0,
        stack = false,
        description = 'Una carta rara de colección.',
        close = true,
        client = { export = 'origen_AlbumCards.albumcard' }
    },
    scratch_card = {
        label = 'Boleto de Rasca y Gana',
        weight = 0,
        stack = true,
        description = '¡Rasca los paneles y descubre si has ganado un premio!',
        close = true
    },
    micro_oculto = {
        label = 'Micrófono Oculto',
        weight = 100,
        stack = false,
        description = 'Un pequeño dispositivo de escucha.',
        close = true
    },
    receptor_micro = {
        label = 'Receptor de Frecuencia',
        weight = 200,
        stack = false,
        description = 'Dispositivo para escuchar micrófonos sincronizados.',
        close = true
    },
    detector_micro = {
        label = 'Detector de Micrófonos',
        weight = 250,
        stack = false,
        description = 'Escanea en 15m para detectar micrófonos ocultos activos.',
        close = true
    },
    inhibidor_micro = {
        label = 'Inhibidor de Frecuencia',
        weight = 300,
        stack = false,
        description = 'Anula todos los micrófonos ocultos en un radio de 15m.',
        close = true
    },
    quitamicro = {
        label = 'Desinstalador de Micros',
        weight = 150,
        stack = false,
        description = 'Permite extraer físicamente un micrófono oculto instalado en un vehículo.',
        close = true
    },
    manitol = {
        label = 'Manitol',
        weight = 80,
        stack = true,
        description = 'Producto quimico alimenticio.',
        close = true
    },
    jewels = {
        label = 'Joyas',
        weight = 1,
        stack = true,
    },

    ruby = {
        label = 'Rubí Rojo',
        weight = 1,
    },

    panther = {
        label = 'Estatua de Pantera',
        weight = 1,
    },

    ruby_necklace = {
        label = 'Collar de Rubí',
        weight = 1,
    },

    emerald = {
        label = 'Esmeralda',
        weight = 1,
    },

    golden_banana = {
        label = 'Plátano de Oro',
        weight = 1,
    },

    cable_cutter = {
        label = 'Cortacables',
        weight = 1,
        stack = true,
    },

    glass_cutter = {
        label = 'Cortacristales',
        weight = 1,
        stack = true,
    },

    screwdriver = {
        label = 'Destornillador',
        weight = 1,
        stack = true,
    },

    diving_gear = {
        label = 'Equipo de Buceo',
        weight = 5000,
        stack = false,
        close = true,
        description = 'Permite respirar bajo el agua y moverte mejor.',
        client = {
            export = 'origen_inventory.UseDivingGear'
        }
    },

    emergency_backpack = {
        label = 'Mochila de Emergencias',
        weight = 2000,
        stack = false,
        close = true,
        description = 'Una mochila portátil con suministros médicos y policiales de emergencia.',
        client = {
            export = 'origen_police.UseEmergencyBackpack'
        }
    },

    tourniquet = {
        label = 'Torniquete',
        weight = 100,
        stack = true,
        close = true,
        description = 'Frena hemorragias en extremidades.',
    },

    surgical_forceps = {
        label = 'Pinzas Quirúrgicas',
        weight = 200,
        stack = true,
        close = true,
        description = 'Permite extraer proyectiles de las heridas.',
    },

    suture_kit = {
        label = 'Kit de Sutura',
        weight = 150,
        stack = true,
        close = true,
        description = 'Cierra incisiones y heridas abiertas.',
    },

    burn_gel = {
        label = 'Gel para Quemaduras',
        weight = 100,
        stack = true,
        close = true,
        description = 'Alivia e hidrata quemaduras graves.',
    },

    epinephrine = {
        label = 'Epinefrina',
        weight = 50,
        stack = true,
        close = true,
        description = 'Estabiliza el ritmo cardíaco en paradas cardíacas.',
    },

    saline_bag = {
        label = 'Suero Salino',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Recupera el volumen sanguíneo del paciente.',
    },

    police_medkit = {
        label = 'Botiquín Policial',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Kit médico de dotación policial. Permite a los agentes reanimar a un compañero inconsciente.',
        server = {
            export = 'origen_police.police_medkit'
        },
        consume = 0,
    },

    -- ── Granja (origen_farming) ───────────────────────────────────────────
    lechuga = {
        label = 'Lechuga',
        weight = 250,
        stack = true,
        close = true,
        image = 'lechuga.png',
        description = 'Lechuga fresca de la cooperativa de Grapeseed.',
    },

    zanahoria = {
        label = 'Zanahoria',
        weight = 120,
        stack = true,
        close = true,
        image = 'zanahoria.png',
        description = 'Zanahoria recién sacada de la tierra.',
    },

    patata = {
        label = 'Patata',
        weight = 200,
        stack = true,
        close = true,
        image = 'patata.png',
        description = 'Patata de la huerta de Grapeseed.',
    },

    tomate = {
        label = 'Tomate',
        weight = 150,
        stack = true,
        close = true,
        image = 'tomate.png',
        description = 'Tomate maduro de la cooperativa.',
    },

    fresa = {
        label = 'Fresa',
        weight = 30,
        stack = true,
        close = true,
        image = 'fresa.png',
        description = 'Fresa dulce de temporada.',
    },

    maiz = {
        label = 'Mazorca de Maíz',
        weight = 300,
        stack = true,
        close = true,
        image = 'maiz.png',
        description = 'Mazorca de maíz dorada.',
    },

    calabaza = {
        label = 'Calabaza',
        weight = 2500,
        stack = true,
        close = true,
        image = 'calabaza.png',
        description = 'Calabaza grande y pesada.',
    },

    semilla_lechuga = {
        label = 'Semillas de Lechuga',
        weight = 10,
        stack = true,
        close = true,
        image = 'semilla_lechuga.png',
        description = 'Semillas para sembrar una celda de lechuga en tu parcela.',
    },

    semilla_zanahoria = {
        label = 'Semillas de Zanahoria',
        weight = 10,
        stack = true,
        close = true,
        image = 'semilla_zanahoria.png',
        description = 'Semillas para sembrar una celda de zanahoria en tu parcela.',
    },

    semilla_patata = {
        label = 'Semillas de Patata',
        weight = 10,
        stack = true,
        close = true,
        image = 'semilla_patata.png',
        description = 'Semillas para sembrar una celda de patata en tu parcela.',
    },

    semilla_tomate = {
        label = 'Semillas de Tomate',
        weight = 10,
        stack = true,
        close = true,
        image = 'semilla_tomate.png',
        description = 'Semillas para sembrar una celda de tomate en tu parcela.',
    },

    semilla_trigo = {
        label = 'Semillas de Trigo',
        weight = 10,
        stack = true,
        close = true,
        image = 'semilla_trigo.png',
        description = 'Semillas para sembrar una celda de trigo en tu parcela.',
    },

    semilla_fresa = {
        label = 'Semillas de Fresa',
        weight = 10,
        stack = true,
        close = true,
        image = 'semilla_fresa.png',
        description = 'Semillas para sembrar una celda de fresa en tu parcela.',
    },

    semilla_maiz = {
        label = 'Semillas de Maíz',
        weight = 10,
        stack = true,
        close = true,
        image = 'semilla_maiz.png',
        description = 'Semillas para sembrar una celda de maíz en tu parcela.',
    },

    semilla_calabaza = {
        label = 'Semillas de Calabaza',
        weight = 10,
        stack = true,
        close = true,
        image = 'semilla_calabaza.png',
        description = 'Semillas para sembrar una celda de calabaza en tu parcela.',
    },

    semilla_cafe = {
        label = 'Semillas de Café',
        weight = 10,
        stack = true,
        close = true,
        image = 'semilla_cafe.png',
        description = 'Semillas para sembrar una celda de café en tu parcela.',
    },

    granja_azada = {
        label = 'Azada',
        weight = 1500,
        stack = false,
        close = true,
        image = 'granja_azada.png',
        description = 'Para arar la tierra de tu parcela.',
    },

    granja_regadera = {
        label = 'Regadera',
        weight = 1200,
        stack = false,
        close = true,
        image = 'granja_regadera.png',
        description = 'Riega las plantas. Se llena en el depósito del palé o en la cooperativa.',
    },

    granja_abono = {
        label = 'Abono',
        weight = 500,
        stack = true,
        close = true,
        image = 'granja_abono.png',
        description = 'Acelera el crecimiento y mejora la calidad de la cosecha.',
    },

    granja_insecticida = {
        label = 'Insecticida',
        weight = 400,
        stack = true,
        close = true,
        image = 'granja_insecticida.png',
        description = 'Acaba con la plaga de una planta.',
    },

    -- Mascotas (origen_pets): el pienso de serie de Config.Necesidades.comida.
    -- Se da desde el panel de la mascota, no con "usar".
    petfood = {
        label = 'Pienso',
        weight = 250,
        stack = true,
        close = true,
        description = 'Comida para tu mascota. Dásela desde su panel.',
    },

    -- Cantera (origen_mining): lo que sale de la planta. Se vende al capataz
    -- (Config.Productos de origen_mining manda en los precios).
    lingote_hierro = {
        label = 'Lingote de hierro',
        weight = 1200,
        stack = true,
        close = false,
        description = 'Hierro fundido en la planta de la cantera. Lo compra el capataz.',
    },
    lingote_cobre = {
        label = 'Lingote de cobre',
        weight = 1300,
        stack = true,
        close = false,
        description = 'Cobre fundido en la planta de la cantera. Lo compra el capataz.',
    },
    lingote_oro = {
        label = 'Lingote de oro',
        weight = 1500,
        stack = true,
        close = false,
        description = 'Oro fundido en la planta de la cantera. Lo compra el capataz.',
    },
    grava = {
        label = 'Grava',
        weight = 800,
        stack = true,
        close = false,
        description = 'Piedra triturada en la planta de la cantera. La compra el capataz.',
    },
    carbon_mineral = {
        label = 'Carbón',
        weight = 600,
        stack = true,
        close = false,
        description = 'Carbón triturado en la planta de la cantera. Lo compra el capataz.',
    },
    cuarzo = {
        label = 'Cuarzo triturado',
        weight = 700,
        stack = true,
        close = false,
        description = 'Cuarzo triturado en la planta de la cantera. Lo compra el capataz.',
    },
}

if GetConvar('origen:marca', 'origen') == 'nacion' then
    items.murderface_food = {
        label = 'Comida para Mascotas',
        description = 'Comida para alimentar mascotas.',
        weight = 250,
        stack = true,
        close = true,
    }
    items.murderface_collar = {
        label = 'Collar para Mascota',
        description = 'Collar usado para transferir la propiedad de una mascota.',
        weight = 100,
        stack = true,
        close = true,
    }
    items.murderface_nametag = {
        label = 'Placa de Nombre',
        description = 'Placa para cambiar el nombre de una mascota.',
        weight = 50,
        stack = true,
        close = true,
    }
    items.murderface_firstaid = {
        label = 'Botiquin para Mascotas',
        description = 'Kit de primeros auxilios para curar mascotas.',
        weight = 300,
        stack = true,
        close = true,
    }
    items.murderface_groomingkit = {
        label = 'Kit de Aseo',
        description = 'Kit para asear y personalizar mascotas.',
        weight = 500,
        stack = true,
        close = true,
    }
    items.murderface_waterbottle = {
        label = 'Botella de Agua Portatil',
        description = 'Botella portatil para dar agua a las mascotas.',
        weight = 350,
        stack = false,
        close = true,
    }
    items.murderface_doghouse = {
        label = 'Casa para Perro',
        description = 'Casa para perro colocable.',
        weight = 2500,
        stack = false,
        close = true,
    }
    items.murderface_leash = {
        label = 'Correa Negra',
        description = 'Correa negra para llevar una mascota.',
        weight = 150,
        stack = false,
        close = true,
    }
    items.murderface_leash_2 = {
        label = 'Correa Amarilla',
        description = 'Correa amarilla para llevar una mascota.',
        weight = 150,
        stack = false,
        close = true,
    }
    items.murderface_leash_3 = {
        label = 'Correa Verde',
        description = 'Correa verde para llevar una mascota.',
        weight = 150,
        stack = false,
        close = true,
    }
    items.murderface_husky = {
        label = 'Husky',
        description = 'Mascota Husky.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_shepherd = {
        label = 'Pastor Aleman',
        description = 'Mascota Pastor Aleman.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_rottweiler = {
        label = 'Rottweiler',
        description = 'Mascota Rottweiler.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_retriever = {
        label = 'Golden Retriever',
        description = 'Mascota Golden Retriever.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_chop = {
        label = 'Chop',
        description = 'Mascota Chop.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_westy = {
        label = 'Westie',
        description = 'Mascota Westie.',
        weight = 800,
        stack = false,
        close = true,
    }
    items.murderface_pug = {
        label = 'Pug',
        description = 'Mascota Pug.',
        weight = 800,
        stack = false,
        close = true,
    }
    items.murderface_poodle = {
        label = 'Poodle',
        description = 'Mascota Poodle.',
        weight = 800,
        stack = false,
        close = true,
    }
    items.murderface_cat = {
        label = 'Gato',
        description = 'Mascota gato.',
        weight = 800,
        stack = false,
        close = true,
    }
    items.murderface_panther = {
        label = 'Pantera Negra',
        description = 'Mascota Pantera Negra.',
        weight = 1200,
        stack = false,
        close = true,
    }
    items.murderface_mtlion = {
        label = 'Leon de Montana',
        description = 'Mascota Leon de Montana.',
        weight = 1200,
        stack = false,
        close = true,
    }
    items.murderface_coyote = {
        label = 'Coyote',
        description = 'Mascota Coyote.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_hen = {
        label = 'Gallina',
        description = 'Mascota gallina.',
        weight = 500,
        stack = false,
        close = true,
    }
    items.murderface_rabbit = {
        label = 'Conejo',
        description = 'Mascota conejo.',
        weight = 500,
        stack = false,
        close = true,
    }
    items.murderface_chimp = {
        label = 'Chimpance',
        description = 'Mascota chimpance.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_rhesus = {
        label = 'Mono Rhesus',
        description = 'Mascota mono Rhesus.',
        weight = 800,
        stack = false,
        close = true,
    }
    items.murderface_doberman = {
        label = 'Doberman',
        description = 'Mascota Doberman.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_canecorso = {
        label = 'Cane Corso',
        description = 'Mascota Cane Corso.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_englishbulldog = {
        label = 'Bulldog Ingles',
        description = 'Mascota Bulldog Ingles.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_poodle2 = {
        label = 'Toy Poodle',
        description = 'Mascota Toy Poodle.',
        weight = 800,
        stack = false,
        close = true,
    }
    items.murderface_sphynx = {
        label = 'Gato Sphynx',
        description = 'Mascota gato Sphynx.',
        weight = 800,
        stack = false,
        close = true,
    }
    items.murderface_husky2 = {
        label = 'Siberian Husky',
        description = 'Mascota Siberian Husky.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_retriever2 = {
        label = 'Labrador Retriever',
        description = 'Mascota Labrador Retriever.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_shepherd2 = {
        label = 'Belgian Malinois',
        description = 'Mascota Belgian Malinois.',
        weight = 1000,
        stack = false,
        close = true,
    }
    items.murderface_westy2 = {
        label = 'West Highland Terrier',
        description = 'Mascota West Highland Terrier.',
        weight = 800,
        stack = false,
        close = true,
    }
    items.murderface_pdk9 = {
        label = 'Police K9',
        description = 'Mascota K9 policial.',
        weight = 1000,
        stack = false,
        close = true,
    }
end

items.citation_pad = {
    label = 'Talonario de Citaciones',
    weight = 300,
    stack = false,
    close = true,
    image = 'police_cad.png',
    description = 'Talonario policial para redactar boletas de citación y multas de tráfico.',
}

items.citation_ticket = {
    label = 'Boleta de Citación',
    weight = 50,
    stack = false,
    close = true,
    image = 'certificate.png',
    description = 'Copia oficial de infracción de tráfico emitida por un agente.',
}

-- origen_mision (solo Origen): la Lista Negra. Quien la tiene, la usa y ve los
-- trabajos sucios del comisario Bastida. Se la da un admin a quien quiera que
-- pueda hacerlos; sin ella no se puede coger ninguno.
if GetConvar('origen:marca', 'origen') ~= 'nacion' then
    items.lista_negra = {
        label = 'Lista Negra',
        weight = 100,
        stack = false,
        unique = true,
        usable = true,
        close = true,
        image = 'lista_negra.png',
        description = 'Una libreta con nombres que alguien quiere borrar del mapa. No la enseñes.',
    }
    -- Las pistas de los trabajos de la Lista Negra: cada una lleva en los
    -- metadatos su nombre, descripcion e imagen (las pone origen_mision) y se
    -- lee usandola. Se retiran solas al acabar el trabajo.
    items.pista_lista_negra = {
        label = 'Pista',
        weight = 50,
        stack = false,
        unique = true,
        usable = true,
        close = true,
        image = 'printerdocument.png',
        description = 'Una pista de un trabajo de la Lista Negra.',
    }
end

-- Tableros de juego (solo Nación).
if GetConvar('origen:marca', 'origen') == 'nacion' then
    items.lscitytycoon = {
        label = 'LS City Tycoon',
        description = 'Tablero de juego Los Santos City Tycoon. Colócalo en el suelo para jugar con amigos.',
        weight = 1500,
        stack = false,
        close = true,
        client = {
            disable = {
                car = true,
            },
        },
    }

    items.ludo = {
        label = 'Ludo',
        description = 'Tablero de juego de Ludo / Parchís. Colócalo en el suelo para jugar con amigos.',
        weight = 1200,
        stack = false,
        close = true,
        client = {
            disable = {
                car = true,
            },
        },
    }
end

-- Ingredientes y comidas exclusivos de Nación.
if GetConvar('origen:marca', 'origen') == 'nacion' then
    items.nac_onion = {
        type = 'ingredient',
        label = 'Cebolla',
        weight = 150,
        stack = true,
        close = true,
        image = 'nac_onion.png',
        decay = 120,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_garlic = {
        type = 'ingredient',
        label = 'Ajo',
        weight = 30,
        stack = true,
        close = true,
        image = 'nac_garlic.png',
        decay = 120,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_bellpepper = {
        type = 'ingredient',
        label = 'Pimiento rojo',
        weight = 180,
        stack = true,
        close = true,
        image = 'nac_bellpepper.png',
        decay = 96,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_cucumber = {
        type = 'ingredient',
        label = 'Pepino',
        weight = 200,
        stack = true,
        close = true,
        image = 'nac_cucumber.png',
        decay = 96,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_mushroom = {
        type = 'ingredient',
        label = 'Champiñón',
        weight = 100,
        stack = true,
        close = true,
        image = 'nac_mushroom.png',
        decay = 72,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_avocado = {
        type = 'ingredient',
        label = 'Aguacate',
        weight = 180,
        stack = true,
        close = true,
        image = 'nac_avocado.png',
        decay = 96,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_chili = {
        type = 'ingredient',
        label = 'Chile',
        weight = 40,
        stack = true,
        close = true,
        image = 'nac_chili.png',
        decay = 120,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_broccoli = {
        type = 'ingredient',
        label = 'Brócoli',
        weight = 300,
        stack = true,
        close = true,
        image = 'nac_broccoli.png',
        decay = 72,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_spinach = {
        type = 'ingredient',
        label = 'Espinaca',
        weight = 120,
        stack = true,
        close = true,
        image = 'nac_spinach.png',
        decay = 48,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_apple = {
        type = 'ingredient',
        label = 'Manzana',
        weight = 180,
        stack = true,
        close = true,
        image = 'nac_apple.png',
        decay = 168,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_banana = {
        type = 'ingredient',
        label = 'Plátano',
        weight = 120,
        stack = true,
        close = true,
        image = 'nac_banana.png',
        decay = 96,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_orange = {
        type = 'ingredient',
        label = 'Naranja',
        weight = 180,
        stack = true,
        close = true,
        image = 'nac_orange.png',
        decay = 168,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_lemon = {
        type = 'ingredient',
        label = 'Limón',
        weight = 120,
        stack = true,
        close = true,
        image = 'nac_lemon.png',
        decay = 168,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_grapes = {
        type = 'ingredient',
        label = 'Uvas',
        weight = 200,
        stack = true,
        close = true,
        image = 'nac_grapes.png',
        decay = 96,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_peach = {
        type = 'ingredient',
        label = 'Melocotón',
        weight = 150,
        stack = true,
        close = true,
        image = 'nac_peach.png',
        decay = 96,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_mango = {
        type = 'ingredient',
        label = 'Mango',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_mango.png',
        decay = 96,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_pineapple = {
        type = 'ingredient',
        label = 'Piña',
        weight = 900,
        stack = true,
        close = true,
        image = 'nac_pineapple.png',
        decay = 120,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_blueberry = {
        type = 'ingredient',
        label = 'Arándanos',
        weight = 80,
        stack = true,
        close = true,
        image = 'nac_blueberry.png',
        decay = 72,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_watermelon = {
        type = 'ingredient',
        label = 'Sandía',
        weight = 3000,
        stack = true,
        close = true,
        image = 'nac_watermelon.png',
        decay = 120,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_pear = {
        type = 'ingredient',
        label = 'Pera',
        weight = 180,
        stack = true,
        close = true,
        image = 'nac_pear.png',
        decay = 168,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_egg = {
        type = 'ingredient',
        label = 'Huevo',
        weight = 60,
        stack = true,
        close = true,
        image = 'nac_egg.png',
        decay = 168,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_milk = {
        type = 'ingredient',
        label = 'Leche',
        weight = 1000,
        stack = true,
        close = true,
        image = 'nac_milk.png',
        decay = 72,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_cheese = {
        type = 'ingredient',
        label = 'Queso',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_cheese.png',
        decay = 168,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_flour = {
        type = 'ingredient',
        label = 'Harina',
        weight = 1000,
        stack = true,
        close = true,
        image = 'nac_flour.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_rice = {
        type = 'ingredient',
        label = 'Arroz',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_rice.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_beans = {
        type = 'ingredient',
        label = 'Frijoles',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_beans.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_sugar = {
        type = 'ingredient',
        label = 'Azúcar',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_sugar.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_salt = {
        type = 'ingredient',
        label = 'Sal',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_salt.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_butter = {
        type = 'ingredient',
        label = 'Mantequilla',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_butter.png',
        decay = 168,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_oil = {
        type = 'ingredient',
        label = 'Aceite de cocina',
        weight = 1000,
        stack = true,
        close = true,
        image = 'nac_oil.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_yeast = {
        type = 'ingredient',
        label = 'Levadura',
        weight = 20,
        stack = true,
        close = true,
        image = 'nac_yeast.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_pasta = {
        type = 'ingredient',
        label = 'Pasta seca',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_pasta.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_dough = {
        type = 'ingredient',
        label = 'Masa fresca',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_dough.png',
        decay = 48,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_honey = {
        type = 'ingredient',
        label = 'Miel',
        weight = 350,
        stack = true,
        close = true,
        image = 'nac_honey.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_cocoa = {
        type = 'ingredient',
        label = 'Cacao',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_cocoa.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_beef = {
        type = 'ingredient',
        label = 'Carne de res',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_beef.png',
        decay = 24,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_chicken = {
        type = 'ingredient',
        label = 'Carne de pollo',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_chicken.png',
        decay = 24,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_pork = {
        type = 'ingredient',
        label = 'Carne de cerdo',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_pork.png',
        decay = 24,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_shrimp = {
        type = 'ingredient',
        label = 'Camarón',
        weight = 150,
        stack = true,
        close = true,
        image = 'nac_shrimp.png',
        decay = 24,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_bacon = {
        type = 'ingredient',
        label = 'Tocino',
        weight = 100,
        stack = true,
        close = true,
        image = 'nac_bacon.png',
        decay = 48,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_bread = {
        type = 'ingredient',
        label = 'Pan',
        weight = 300,
        stack = true,
        close = true,
        image = 'nac_bread.png',
        decay = 72,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_cream = {
        type = 'ingredient',
        label = 'Nata',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_cream.png',
        decay = 72,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_spices = {
        type = 'ingredient',
        label = 'Especias',
        weight = 50,
        stack = true,
        close = true,
        image = 'nac_spices.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_olives = {
        type = 'ingredient',
        label = 'Aceitunas',
        weight = 150,
        stack = true,
        close = true,
        image = 'nac_olives.png',
        decay = 168,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_syrup = {
        type = 'ingredient',
        label = 'Sirope',
        weight = 300,
        stack = true,
        close = true,
        image = 'nac_syrup.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_vanilla = {
        type = 'ingredient',
        label = 'Vainilla',
        weight = 10,
        stack = true,
        close = true,
        image = 'nac_vanilla.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_lentils = {
        type = 'ingredient',
        label = 'Lentejas',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_lentils.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_tomato_sauce = {
        type = 'ingredient',
        label = 'Salsa de tomate',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_tomato_sauce.png',
        decay = 120,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_cabbage = {
        type = 'ingredient',
        label = 'Repollo',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_cabbage.png',
        decay = 120,
        perishable = true,
        description = 'Ingrediente fresco para preparar platos.',
    }
    items.nac_mustard = {
        type = 'ingredient',
        label = 'Mostaza',
        weight = 200,
        stack = true,
        close = true,
        image = 'nac_mustard.png',
        description = 'Ingrediente de despensa para cocinar.',
    }
    items.nac_green_salad = {
        label = 'Ensalada verde',
        weight = 350,
        stack = true,
        close = true,
        image = 'nac_green_salad.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 150000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_caesar_salad = {
        label = 'Ensalada César',
        weight = 400,
        stack = true,
        close = true,
        image = 'nac_caesar_salad.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 180000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_vegetable_soup = {
        label = 'Sopa de verduras',
        weight = 450,
        stack = true,
        close = true,
        image = 'nac_vegetable_soup.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 180000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_french_fries = {
        label = 'Patatas fritas',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_french_fries.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 120000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_grilled_corn = {
        label = 'Mazorca a la brasa',
        weight = 300,
        stack = true,
        close = true,
        image = 'nac_grilled_corn.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 130000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_hamburger = {
        label = 'Hamburguesa casera',
        weight = 400,
        stack = true,
        close = true,
        image = 'nac_hamburger.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 220000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_cheeseburger = {
        label = 'Hamburguesa con queso',
        weight = 430,
        stack = true,
        close = true,
        image = 'nac_cheeseburger.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 240000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_chicken_burger = {
        label = 'Hamburguesa de pollo',
        weight = 400,
        stack = true,
        close = true,
        image = 'nac_chicken_burger.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 220000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_veggie_sandwich = {
        label = 'Sándwich vegetal',
        weight = 320,
        stack = true,
        close = true,
        image = 'nac_veggie_sandwich.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 170000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_chicken_sandwich = {
        label = 'Sándwich de pollo',
        weight = 370,
        stack = true,
        close = true,
        image = 'nac_chicken_sandwich.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 210000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_beef_tacos = {
        label = 'Tacos de carne',
        weight = 350,
        stack = true,
        close = true,
        image = 'nac_beef_tacos.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 200000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_chicken_tacos = {
        label = 'Tacos de pollo',
        weight = 350,
        stack = true,
        close = true,
        image = 'nac_chicken_tacos.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 200000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_fish_tacos = {
        label = 'Tacos de pescado',
        weight = 350,
        stack = true,
        close = true,
        image = 'nac_fish_tacos.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 190000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_burrito = {
        label = 'Burrito de carne',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_burrito.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 260000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_veggie_pizza = {
        label = 'Pizza vegetal',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_veggie_pizza.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 250000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_meat_pizza = {
        label = 'Pizza de carne',
        weight = 550,
        stack = true,
        close = true,
        image = 'nac_meat_pizza.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 280000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_grilled_fish = {
        label = 'Pescado a la brasa',
        weight = 400,
        stack = true,
        close = true,
        image = 'nac_grilled_fish.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 210000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_grilled_salmon = {
        label = 'Salmón a la plancha',
        weight = 420,
        stack = true,
        close = true,
        image = 'nac_grilled_salmon.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 230000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_salmon_sushi = {
        label = 'Sushi de salmón',
        weight = 300,
        stack = true,
        close = true,
        image = 'nac_salmon_sushi.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 180000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_tuna_sushi = {
        label = 'Sushi de atún',
        weight = 300,
        stack = true,
        close = true,
        image = 'nac_tuna_sushi.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 180000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_seafood_paella = {
        label = 'Paella de marisco',
        weight = 550,
        stack = true,
        close = true,
        image = 'nac_seafood_paella.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 280000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_spaghetti_bolognese = {
        label = 'Espaguetis boloñesa',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_spaghetti_bolognese.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 260000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_mushroom_pasta = {
        label = 'Pasta con champiñones',
        weight = 450,
        stack = true,
        close = true,
        image = 'nac_mushroom_pasta.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 240000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_potato_omelette = {
        label = 'Tortilla de patata',
        weight = 400,
        stack = true,
        close = true,
        image = 'nac_potato_omelette.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 230000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_pancakes = {
        label = 'Tortitas',
        weight = 300,
        stack = true,
        close = true,
        image = 'nac_pancakes.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 170000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_pumpkin_soup = {
        label = 'Crema de calabaza',
        weight = 400,
        stack = true,
        close = true,
        image = 'nac_pumpkin_soup.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 180000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_fruit_salad = {
        label = 'Ensalada de frutas',
        weight = 300,
        stack = true,
        close = true,
        image = 'nac_fruit_salad.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 140000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_strawberry_smoothie = {
        label = 'Batido de fresa',
        weight = 350,
        stack = true,
        close = true,
        image = 'nac_strawberry_smoothie.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 80000, thirst = 170000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_lemonade = {
        label = 'Limonada',
        weight = 300,
        stack = true,
        close = true,
        image = 'nac_lemonade.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 0, thirst = 180000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_orange_juice = {
        label = 'Zumo de naranja',
        weight = 300,
        stack = true,
        close = true,
        image = 'nac_orange_juice.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 0, thirst = 180000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_apple_pie = {
        label = 'Tarta de manzana',
        weight = 350,
        stack = true,
        close = true,
        image = 'nac_apple_pie.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 180000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_chocolate_cake = {
        label = 'Tarta de chocolate',
        weight = 400,
        stack = true,
        close = true,
        image = 'nac_chocolate_cake.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 220000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_chocolate_cookies = {
        label = 'Galletas de chocolate',
        weight = 180,
        stack = true,
        close = true,
        image = 'nac_chocolate_cookies.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 100000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_steak = {
        label = 'Bistec a la parrilla',
        weight = 450,
        stack = true,
        close = true,
        image = 'nac_steak.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 250000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_roast_rabbit = {
        label = 'Conejo asado',
        weight = 400,
        stack = true,
        close = true,
        image = 'nac_roast_rabbit.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 230000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_crab_cakes = {
        label = 'Croquetas de cangrejo',
        weight = 320,
        stack = true,
        close = true,
        image = 'nac_crab_cakes.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 190000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_grilled_octopus = {
        label = 'Pulpo a la brasa',
        weight = 400,
        stack = true,
        close = true,
        image = 'nac_grilled_octopus.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 220000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_boar_stew = {
        label = 'Estofado de jabalí',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_boar_stew.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 270000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_croissant = {
        label = 'Cruasán',
        weight = 180,
        stack = true,
        close = true,
        image = 'nac_croissant.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 120000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_hot_dog = {
        label = 'Perrito caliente',
        weight = 350,
        stack = true,
        close = true,
        image = 'nac_hot_dog.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 190000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_avocado_toast = {
        label = 'Tostada de aguacate',
        weight = 280,
        stack = true,
        close = true,
        image = 'nac_avocado_toast.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 150000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_lasagna = {
        label = 'Lasaña',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_lasagna.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 270000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_chicken_rice = {
        label = 'Arroz con pollo',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_chicken_rice.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 260000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_fish_soup = {
        label = 'Caldo de pescado',
        weight = 450,
        stack = true,
        close = true,
        image = 'nac_fish_soup.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 200000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_bean_stew = {
        label = 'Guiso de frijoles',
        weight = 450,
        stack = true,
        close = true,
        image = 'nac_bean_stew.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 240000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_flan = {
        label = 'Flan casero',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_flan.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 140000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_mango_ice_cream = {
        label = 'Helado de mango',
        weight = 220,
        stack = true,
        close = true,
        image = 'nac_mango_ice_cream.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 120000, thirst = 40000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_strawberry_tart = {
        label = 'Tarta de fresa',
        weight = 350,
        stack = true,
        close = true,
        image = 'nac_strawberry_tart.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 190000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_spring_rolls = {
        label = 'Rollitos de primavera',
        weight = 280,
        stack = true,
        close = true,
        image = 'nac_spring_rolls.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 160000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_brownie = {
        label = 'Brownie de chocolate',
        weight = 250,
        stack = true,
        close = true,
        image = 'nac_brownie.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 160000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_roast_chicken = {
        label = 'Pollo asado',
        weight = 500,
        stack = true,
        close = true,
        image = 'nac_roast_chicken.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 280000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_stuffed_potato = {
        label = 'Patata rellena',
        weight = 400,
        stack = true,
        close = true,
        image = 'nac_stuffed_potato.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 220000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_breaded_fish = {
        label = 'Pescado empanado',
        weight = 380,
        stack = true,
        close = true,
        image = 'nac_breaded_fish.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 210000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
    items.nac_apple_pancakes = {
        label = 'Tortitas de manzana',
        weight = 350,
        stack = true,
        close = true,
        image = 'nac_apple_pancakes.png',
        decay = 24,
        perishable = true,
        description = 'Comida preparada.',
        client = {
            status = { hunger = 190000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 3500,
        },
    }
end

return items
