Config = Config or {}
-----------------------------------------
------------  Vehicle  -------------------
-----------------------------------------
--- Open distance for Trunks
Config.OpenTrunkAnywhere = false
Config.TrunkOpenDistance = 3.0

Config.BackEngineVehicles = {
    'ninef',
    'adder',
    'vagner',
    't20',
    'infernus',
    'zentorno',
    'reaper',
    'comet2',
    'comet3',
    'jester',
    'jester2',
    'cheetah',
    'cheetah2',
    'prototipo',
    'turismor',
    'pfister811',
    'ardent',
    'nero',
    'nero2',
    'tempesta',
    'vacca',
    'bullet',
    'osiris',
    'entityxf',
    'turismo2',
    'fmj',
    're7b',
    'tyrus',
    'italigtb',
    'penetrator',
    'monroe',
    'ninef2',
    'stingergt',
    'surfer',
    'surfer2',
    'comet3',
}

----------------------------------------------
------------  Vehicle Trunk  -----------------
----------------------------------------------
Config.Trunks = {}

Config.Trunks.vehicles = {
    --- Don't change the 'default' name.
    default = {
        slots = 35,
        maxweight = 60000,
        label = 'Maletero',
    },

    [`speedo`] = {
        slots = 2,
        maxweight = 40000,
        label = 'Maletero Speedo',
        bone = 'door_dside_r',
    }

    ---- Attention: Use `` in the name, not "" or ''
    -- [`sultan`] = {
    --     slots = 50,
    --     maxweight = 120000,
    --     label = 'Maletero Sultan'
    -- },
    -- [`panto`] = {
    --     slots = 10,
    --     maxweight = 100000,
    --     label = 'Maletero Panto'
    -- },
    -- [`adder`] = {
    --     slots = 5,
    --     maxweight = 100000,
    --     label = 'Maletero Adder',
    --     bone  = 'bonnet',
    -- }
}


-------------------------------------------------
------------  Vehicle Glovebox  -----------------
-------------------------------------------------
Config.Gloveboxes = {}

Config.Gloveboxes.vehicles = {
    --- Don't change the 'default' name.
    default = {
        slots = 5,
        maxweight = 12500,
        label = 'Guantera',
    },

    ---- Attention: Use `` in the name, not "" or ''
    [`sultan`] = {
        slots = 5,
        maxweight = 12500,
        label = 'Guantera Sultan',
    },
    [`speedo`] = {
        slots = 8,
        maxweight = 20000,
        label = 'Guantera Speedo',
    }
}