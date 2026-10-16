-- All the components listed here are ignored in case you are using ox_inventory
Config.Armory = {
    label = "Equipamiento",
    items = {
        {
            name = "weapon_combatpistol",
            price = 0,
            amount = 1,
            info = {
                serie = "SAPD",
                attachments = {
                    {component = "COMPONENT_AT_PI_FLSH", label = "Flashlight"},
                }
            },
            type = "weapon",
            slot = 1,
        },
        {
            name = "weapon_stungun",
            price = 0,
            amount = 1,
            info = {
                serie = "SAPD",
            },
            type = "weapon",
            slot = 2,
        },
        {
            name = "weapon_nightstick",
            price = 0,
            amount = 1,
            info =  {
                serie = "SAPD",
            },
            type = "weapon",
            slot = 3,
        },
        {
            name = "weapon_flashlight",
            price = 0,
            amount = 1,
            info =  {
                serie = "SAPD",
            },
            type = "weapon",
            slot = 4,
        },
        {
            name = "radio",
            price = 0,
            amount = 1,
            info =  {
                serie = "SAPD",
            },
            type = "item",
            slot = 5,
        },
        {
            name = "weapon_pumpshotgun",
            price = 0,
            amount = 1,
            info = {
                serie = "SAPD",
                attachments = {
                    {component = "COMPONENT_AT_AR_FLSH", label = "Flashlight"},
                }
            },
            type = "weapon",
            slot = 6,
        },
        {
            name = "weapon_smg",
            price = 0,
            amount = 1,
            info = {
                serie = "SAPD",
                attachments = {
                    {component = "COMPONENT_AT_SCOPE_MACRO_02", label = "1x Scope"},
                    {component = "COMPONENT_AT_AR_FLSH", label = "Flashlight"},
                }
            },
            type = "weapon",
            slot = 7,
        },
        {
            name = "weapon_carbinerifle",
            price = 0,
            amount = 1,
            info = {
                serie = "SAPD",
                attachments = {
                    {component = "COMPONENT_AT_AR_FLSH", label = "Flashlight"},
                    {component = "COMPONENT_AT_SCOPE_MEDIUM", label = "3x Scope"},
                }
            },
            type = "weapon",
            slot = 8,
        },
        {
            name = "pistol_ammo",
            price = 0,
            amount = 10,
            info =  {
                serie = "SAPD",
            },
            type = "item",
            slot = 9,
        },
        {
            name = "smg_ammo",
            price = 0,
            amount = 10,
            info =  {
                serie = "SAPD",
            },
            type = "item",
            slot = 10,
        },
        {
            name = "shotgun_ammo",
            price = 0,
            amount = 10,
            info =  {
                serie = "SAPD",
            },
            type = "item",
            slot = 11,
        },
        {
            name = "rifle_ammo",
            price = 0,
            amount = 10,
            info =  {
                serie = "SAPD",
            },
            type = "item",
            slot = 12,
        },
        {
            name = "armor",
            price = 0,
            amount = 1,
            info =  {
                serie = "SAPD",
            },
            type = "item",
            slot = 13,
        },
        {
            name = "heavyarmor",
            price = 0,
            amount = 1,
            info =  {
                serie = "SAPD",
            },
            type = "item",
            slot = 14,
        },
        {
            name = "instant_camera",
            price = 0,
            amount = 1,
            info =  {
                serie = "SAPD",
            },
            type = "item",
            slot = 15,
        },
        {
            name = "police_cad",
            price = 0,
            amount = 1,
            info =  {
                serie = "SAPD",
            },
            type = "item",
            slot = 16,
        },
        {
            name = "parachute",
            price = 0,
            amount = 1,
            info =  {
                serie = "SAPD",
            },
            type = "item",
            slot = 17,
        },
        {
            name = "megafono",
            price = 0,
            amount = 1,
            info = {
                serie = "SAPD",
            },
            type = "item",
            slot = 18,
        },
        {
            name = "weapon_beanbag",
            price = 0,
            amount = 1,
            info = {
                serie = "SAPD",
            },
            type = "weapon",
            slot = 19,
        },
        {
            name = "ammo-beanbag",
            price = 0,
            amount = 10,
            type = "item",
            slot = 20,
        },
        {
            name = "lectorhuellas",
            price = 0,
            amount = 1,
            type = "item",
            slot = 21,
        },
        {
            name = "weapon_combatpdw",
            price = 0,
            amount = 1,
            info = {
                serie = "SAPD",
            },
            type = "weapon",
            slot = 22,
        },
        {
            name = "cone",
            price = 0,
            amount = 5,
            type = "item",
            slot = 23,
        },
        {
            name = "barrier",
            price = 0,
            amount = 2,
            type = "item",
            slot = 24,
        },
        {
            name = "signal",
            price = 0,
            amount = 2,
            type = "item",
            slot = 25,
        },
        {
            name = "spikes",
            price = 0,
            amount = 1,
            type = "item",
            slot = 26,
        },
        {
            name = "radar",
            price = 0,
            amount = 1,
            type = "item",
            slot = 27,
        
        },
        {
            name = "binoculars",
            price = 0,
            amount = 1,
            type = "item",
            slot = 28,
        
        },
        {
            name = "flashlight_attachment",
            price = 0,
            amount = 1,
            type = "item",
            slot = 29,
        },
        {
            name = "destornillador",
            price = 0,
            amount = 1,
            type = "item",
            slot = 30,
        },
        {
            name = "gsr",
            price = 0,
            amount = 1,
            type = "item",
            slot = 31,
        },
        {
            name = "diving_gear",
            price = 0,
            amount = 1,
            type = "item",
            slot = 32,
        },

    }
}

-- Ambulance Armoury
Config.AmbulanceArmory = {
    label = "Equipamiento EMS",
    job = "ambulance", -- Job name required to access
    coords = vector4(309.26, -603.06, 43.2, 160.26),
    items = {
        {
            name = "medicalbag",
            price = 0,
            amount = 1,
            info = {},
            type = "item",
            slot = 1,
        },
        {
            name = "defibrillator",
            price = 0,
            amount = 1,
            info = {},
            type = "item",
            slot = 2,
        },
        {
            name = "firstaid",
            price = 0,
            amount = 5,
            info = {},
            type = "item",
            slot = 3,
        },
        {
            name = "bandage",
            price = 0,
            amount = 10,
            info = {},
            type = "item",
            slot = 4,
        },
        {
            name = "burncream",
            price = 0,
            amount = 5,
            info = {},
            type = "item",
            slot = 5,
        },
        {
            name = "suturekit",
            price = 0,
            amount = 5,
            info = {},
            type = "item",
            slot = 6,
        },
        {
            name = "tweezers",
            price = 0,
            amount = 2,
            info = {},
            type = "item",
            slot = 7,
        },
        {
            name = "icepack",
            price = 0,
            amount = 5,
            info = {},
            type = "item",
            slot = 8,
        },
        {
            name = "splint",
            price = 0,
            amount = 5,
            info = {},
            type = "item",
            slot = 9,
        },
        {
            name = "stretcher",
            price = 0,
            amount = 1,
            info = {},
            type = "item",
            slot = 10,
        },
        {
            name = "weapon_flashlight",
            price = 0,
            amount = 1,
            info = {},
            type = "weapon",
            slot = 11,
        },
        {
            name = "radio",
            price = 0,
            amount = 1,
            info = {},
            type = "item",
            slot = 12,
        },
        {
            name = "parachute",
            price = 0,
            amount = 1,
            info = {},
            type = "item",
            slot = 13,
        },
        {
            name = "diving_gear",
            price = 0,
            amount = 1,
            type = "item",
            slot = 14,
        },
    }
}