Config = Config or {}

------------------------------------------
-------------- STASHES SYSTEM ------------
------------------------------------------

Config.Stashes = {}

------------------------------------------
--------------- DECAY SYSTEM -------------
------------------------------------------
-- Controls how fast items with a `decay` rate age inside each container.
-- rate 0 = frozen, 0.25 = ages 4x slower, 1 = normal, above 1 = accelerated.
Config.Decay = {
    -- Aging rate for items carried by a player.
    playerRate = 1.0,

    -- Whether items keep aging while the server is down.
    ageWhileOffline = true,

    -- Two stacks of the same item only merge when their durability is within
    -- this many percentage points. Set to 100 to always merge.
    mergeTolerance = 15,

    -- Aging rate per container type. Anything not listed here uses 1.0.
    rates = {
        drop = 1.5,
        trunk = 1.0,
        glovebox = 1.0,
        airdrop = 1.0,
    },
}

Config.Stashes = {

    default = {
        slots = 30,
        maxweight = 120000,
    },

    -- Fridge example: food inside ages 4x slower.
    -- ['fridge_burgershot'] = {
    --     label = 'Fridge',
    --     slots = 30,
    --     maxweight = 50000,
    --     coldStorage = { rate = 0.25 },
    --     locations = { vector3(-1319.3, -2493.41, 14.95) }
    -- },

    -- Freezer example: food inside does not age at all.
    -- ['freezer_burgershot'] = {
    --     label = 'Freezer',
    --     slots = 30,
    --     maxweight = 50000,
    --     coldStorage = { rate = 0.0 },
    --     locations = { vector3(-1319.3, -2495.41, 14.95) }
    -- },

    -- Alijo de pruebas del aeropuerto, apagado el 07/10 (salia como punto
    -- del mundo con la marca en el nombre, tambien en Nacion).
    -- -- example
    -- ['example'] = {
    --     -- job = 'police', -- or gang = 'origen',
    --     --  job_gradeup = 0, -- or gang_grade = 0,
    --     --job_gradedown = 2, -- or gang_grade = 0,
    --     -- gang = 'origen',
    --     -- gang_gradeup = 0,
    --     -- gang_gradedown = 3,
    --     label = 'ORIGEN TEST',
    --     slots = 8,
    --     marker ={
    --         type = 20,
    --         size = vector3(0.3, 0.3, 0.3),
    --         color = {r = 0, g = 0, b = 0, a = 255},
    --     },
    --     locations = { vector3(-1319.3, -2493.41, 14.95) }
    -- },

    -- ['example_2'] = {
    --     job = 'police', -- or gang = 'origen',
    --     job_gradeup = 0, -- or gang_grade = 0,
    --     job_gradedown = 4, -- or gang_grade = 0,
    --     -- gang = 'origen',
    --     -- gang_gradeup = 0,
    --     -- gang_gradedown = 3,
    --     label = 'TEST ORIGEN 2 ',
    --     slots = 50,
    --     marker ={
    --         type = 20,
    --         size = vector3(0.3, 0.3, 0.3),
    --         color = {r = 0, g = 0, b = 0, a = 255},
    --     },
    --     locations = vector3(-80.58, -815.22, 326.18)
    -- },
}