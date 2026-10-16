Config = {}

-- Enabling this will add additional prints and debug visuals
Config.debug = false
--
Config.locale = 'es'

Config.sql = {
    driver = 'oxmysql', -- oxmysql or ghmattimysql or mysql
    -- If you're using an older version of oxmysql set this to false
    newOxMysql = true,
}

-- Whether to set all the statebag values from the server only
Config.useStrictMode = false

-- Whether the presets should be fetched using net events instead of state bags (not recommended)
Config.fetchUsingEvents = false

Config.commands = {
    list = {
        enabled = true,
        commands = {
            'emergency:list',
            'evc:list',
        }
    },
    apply = {
        enabled = true,
        commands = {
            'emergency:apply',
            'evc:apply',
            'evc',
        }
    },
    clear = {
        enabled = true,
        commands = {
            'emergency:clear',
            'evc:clear',
        }
    },
}

Config.options = {
    -- The render distance for the attached props
    -- min: 50, max: 350
    renderDistance = 250,

    -- The refresh rate of the nearby vehicles - How often the script should scan for new and deleted vehicles
    -- min: 1000, max: 7500
    vehicleRefreshRate = 2500, -- ms
}

-- Whether the NPCs should react to sirens and move out of the way/pull over
Config.npcReactions = true

-- Additional lights or siren sounds made by other creators.
-- Check out the `extras` folder to see how they're loaded/added to implement more
Config.extras = {
    -- Whether to enable the "WmSirens" siren options
    -- https://github.com/Walsheyy/WMServerSirens -- The sirens require this resource to be installed
    wmSirens = false,

    -- Whether to enable lightbars made by Munky
    -- https://forum.cfx.re/t/release-lightbar-menu-script-attatch-lightbars-to-any-vehicle-w-sirens/905786 -- The 'lightbars' resource must be installed
    munkysLightbars = false,

    -- Lights made by D3ltaDevelopments (https://d3ltadevelopmentstudios.tebex.io/category/2295189)
    --- How to add:
    -- Install the lights resource
    -- Open the "EVC_Addon_List.txt" file provided by D3lta (within the lights resource you want to use)
    -- Copy all the models located within the "Lights" table. For example:
    --    ["D3s_OneGuard_M"]               = {Extras = true, Offset = vector3(0.00, -2.25, 0.8)},
    --    ["D3s_DualGuard"]                = {Extras = true, Offset = vector3(0.00, -2.25, 0.8)},
    -- Open the extras/d3lta.lua file
    -- Paste your models into the `models` table
}

Config.saving = {
    -- Whether to save presets applied to the vehicles
    saveVehicles = true,
}

-- Administrators have all the permissions by default.
-- You can modify the permissions to fit your exact needs in the editable server file.
Config.permissions = {
    -- Whether the player can access the `emergency:list` command to view and manage their presets on the go
    list = {
        everyone = false,
        jobsOnly = {
            {
                name = 'police',
                minGrade = 0,
            },
            {
                name = 'sheriff',
                minGrade = 0,
            },
            {
                name = 'fib',
                minGrade = 0,
            },
            {
                name = 'sapd',
                minGrade = 0,
            },
            {
                name = 'marshalls',
                minGrade = 0,
            },
        },
    },

    -- Whether the player can view all presets, including private presets in the list menu
    view_all = {
        everyone = false,
        jobsOnly = {}, -- By default only administrators are permitted to see all presets
    },

    -- Whether the player apply already made presets onto vehicles
    apply = {
        everyone = false,
        jobsOnly = {
            {
                name = 'police',
                minGrade = 0,
            },
            {
                name = 'sheriff',
                minGrade = 0,
            },
            {
                name = 'fib',
                minGrade = 0,
            },
            {
                name = 'sapd',
                minGrade = 0,
            },
            {
                name = 'marshalls',
                minGrade = 0,
            },
        },
    },

    -- Whether the player remove presets from vehicles
    unapply = {
        everyone = false,
        jobsOnly = {
            {
                name = 'police',
                minGrade = 0,
            },
            {
                name = 'sheriff',
                minGrade = 0,
            },
            {
                name = 'fib',
                minGrade = 0,
            },
            {
                name = 'sapd',
                minGrade = 0,
            },
            {
                name = 'marshalls',
                minGrade = 0,
            },
        },
    },

    -- Whether the player is allowed to create new presets
    create = {
        everyone = false,
        jobsOnly = {
            {
                name = 'police',
                minGrade = 0,
            },
            {
                name = 'sheriff',
                minGrade = 0,
            },
            {
                name = 'fib',
                minGrade = 0,
            },
            {
                name = 'sapd',
                minGrade = 0,
            },
            {
                name = 'marshalls',
                minGrade = 0,
            },
        },
    },

    -- Whether the player is allowed to create public presets
    public = {
        everyone = false,
        jobsOnly = {}, -- By default only administrators are permitted to create public presets
    },

    -- Whether the player is allowed to have administrative powers over all presets. Viewing, Editing, Deleting
    manage = {
        everyone = false,
        jobsOnly = {}, -- By default only administrators are permitted to manage all presets
    },

    --- COMMANDS
    -- These will dictate whether the players can use the commands. They still need to have the permissions for
    -- each action separately. If player has permissions for the apply command, but no permissions to actually apply the presets
    -- they will still be disallowed from performing the action.
    -- This allows you to allow players to "Apply" presets via the zones or items, but not via the commands.

    -- Whether the player is allowed to use the "Apply" command
    command_apply = {
        everyone = false,
        jobsOnly = {},
    },
    -- Whether the player is allowed to use the "Clear" command
    command_clear = {
        everyone = false,
        jobsOnly = {},
    },
}

-- Zones allowing a quick access to the preset applicator menu
-- Presets applied through these zones will be temporary. Meaning that they will not be saved in the database
Config.applicationZones = {
    enabled = true,
    zones = {
        ['lspd_city'] = {
            coords = vec3(860.61, -1357.82, 26.1),
            radius = 1.5,
            marker = {
                variant = 22,
                color = { r = 0, g = 0, b = 0, a = 155 },
                scale = 0.5,
            }
        },
        ['lspd_city2'] = {
            coords = vec3(833.02, -1372.6, 26.13),
            radius = 1.5,
            marker = {
                variant = 22,
                color = { r = 0, g = 0, b = 0, a = 155 },
                scale = 0.5,
            }
        },
        ['lspd_city3'] = {
            coords = vec3(823.2, -1371.93, 26.14),
            radius = 1.5,
            marker = {
                variant = 22,
                color = { r = 0, g = 0, b = 0, a = 155 },
                scale = 0.5,
            }
        },
        ['lspd_city4'] = {
            coords = vec3(404.61, -998.29, 23.33),
            radius = 1.5,
            marker = {
                variant = 22,
                color = { r = 0, g = 0, b = 0, a = 155 },
                scale = 0.5,
            }
        }
    }
}

-- Whether to use the "Emergency lights kit" item for applying the presets
-- The item adds a new way of accessing the "Application" menu. The "application zones" or the commands are fully separate and will not require
-- an item regardless of these options by default
Config.item = {
    enabled = true,

    -- Name of the item
    itemName = 'emergency_lights_kit',

    -- Whether the item should be taken after applying a preset
    takeItemOnUse = false,
}

-- Whether to skip a population type when checking vehicles for their presets
-- We perform a population type check on the vehicles before checking their state to filter out, and ignore all NPC vehicles
Config.skipPopulationTypeCheck = false

-- Whether to disable all the native keybinds for the light/audio control of the script. Useful when using exports to toggle the modes instead
Config.disableNativeKeybinds = false

Config.defaultKeybinds = {
    allOff = 'NUMPAD0',
    simpleCycle = 'Q',

    lights = {
        mode1 = 'NUMPAD7',
        mode2 = 'NUMPAD8',
        mode3 = 'NUMPAD9',
    },
    sounds = {
        mode1 = 'NUMPAD2',
        mode2 = 'NUMPAD3',
        mode3 = 'NUMPAD4',
        mode4 = 'NUMPAD5',
        mode5 = 'NUMPAD6',
    },
}

-- Full UI customization via RGB color values
Config.uiStyling = {
    -- Pegatina (07/10): los mismos valores que la capa del final de
    -- nui/dist/app.css, para que sin ella no vuelva el oscuro. «white» es la
    -- TINTA: el recurso lo usa para letras y filos.
    ['color-background'] = '196, 198, 202',
    ['color-background-light'] = '196, 198, 202',

    ['color-primary-dark'] = '216, 27, 85',
    ['color-primary'] = '216, 27, 85',
    ['color-primary-light'] = '223, 47, 99',
    ['color-primary-lighter'] = '255, 214, 228',

    ['color-secondary'] = '220, 221, 224',
    ['color-secondary-light'] = '241, 241, 238',

    ['color-white'] = '11, 11, 13',
    ['color-black'] = '0, 0, 0',
}

-- Nacion: el acento en su naranja (la paleta de origen_map/shared/tema.lua).
-- Solo color. El estilo pegatina del final de nui/dist/app.css va en las dos
-- marcas (05/10) y pisa estas variables con !important.
if GetConvar('origen:marca', 'origen') == 'nacion' then
    Config.uiStyling['color-primary-dark'] = '106, 52, 2'
    Config.uiStyling['color-primary'] = '253, 138, 35'
    Config.uiStyling['color-primary-light'] = '255, 170, 92'
    Config.uiStyling['color-primary-lighter'] = '255, 217, 182'
end
