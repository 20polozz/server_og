Config.Debug = false -- Enables or disables debug mode
Config.Language = "es" -- Sets the language of the script
Config.ContractOfferExpiration = 5 -- Sets the expiration time for contract offers in minutes
Config.MaxQueuedContracts = 12 -- Maximum simultaneous contracts shown in "bolsa de contratos"
Config.MissionDuration = false -- Sets the time in which the mission will be considered failed in minutes, if false, the mission will not fail
Config.CustomNotify = true -- Enables or disables custom notifications
Config.PoliceJobName = {
    'police',
    'fib',
    'sheriff',
    'sapd'
} -- Sets the name of the police job

Config.Weapons = {
    -- Pistolas
    'weapon_pistol',
    'weapon_combatpistol',
    'weapon_appistol',
    'weapon_stungun',
    'weapon_pistol50',
    'weapon_snspistol',
    'weapon_heavypistol',
    'weapon_vintagepistol',
    'weapon_flaregun',
    'weapon_marksmanpistol',
    'weapon_revolver',
    'weapon_doubleaction',
    'weapon_raypistol',
    'weapon_ceramicpistol',
    'weapon_navyrevolver',

    -- Subfusiles
    'weapon_microsmg',
    'weapon_smg',
    'weapon_assaultsmg',
    'weapon_combatpdw',
    'weapon_machinepistol',
    'weapon_minismg',
    'weapon_railgun',

    -- Fusiles de asalto
    'weapon_assaultrifle',
    'weapon_carbinerifle',
    'weapon_advancedrifle',
    'weapon_specialcarbine',
    'weapon_bullpuprifle',
    'weapon_compactrifle',
    'weapon_militaryrifle',
    'weapon_heavyrifle',
    'weapon_tacticalrifle',

    -- Fusiles de tirador
    'weapon_sniperrifle',
    'weapon_heavysniper',
    'weapon_marksmanrifle',
    'weapon_precisionrifle',

    -- Escopetas
    'weapon_pumpshotgun',
    'weapon_sawnoffshotgun',
    'weapon_assaultshotgun',
    'weapon_bullpupshotgun',
    'weapon_musket',
    'weapon_heavyshotgun',
    'weapon_dbshotgun',
    'weapon_autoshotgun',
    'weapon_combatshotgun',

    -- Armas cuerpo a cuerpo
    'weapon_bat',
    'weapon_golfclub',
    'weapon_crowbar',
    'weapon_wrench',
    'weapon_hammer',
    'weapon_bottle',
    'weapon_dagger',
    'weapon_hatchet',
    'weapon_knuckle',
    'weapon_machete',
    'weapon_switchblade',
    'weapon_battleaxe',
    'weapon_poolcue',
    'weapon_knife',
    'weapon_stone_hatchet',

    -- Lanzacohetes y granadas
    'weapon_rpg',
    'weapon_grenadelauncher',
    'weapon_minigun',
    'weapon_grenade',
    'weapon_bzgas',
    'weapon_molotov',
    'weapon_stickybomb',
    'weapon_proxmine',
    'weapon_snowball',
    'weapon_pipebomb',
    'weapon_ball',
    'weapon_smokegrenade',
    'weapon_flare',
    'weapon_hominglauncher',
    'weapon_rayminigun',
    'weapon_compactlauncher',
    'weapon_emplauncher',
    'weapon_raycarbine',
    'weapon_railgun',

    -- Otras
    'weapon_unarmed',
    'weapon_petrolcan',
    'gadget_parachute'
}

Config.Currency = { -- Currency which will be used to purchase contracts
    AllowTransference = true, -- Enables OGN transfer from the NUI top coins container.
    Account = 'ogn',
    RegisterBonus = 15 -- OGN granted automatically when creating boosting profile for first time
}

Config.Reward = { -- Sets the reward options
    type = 'account', -- Sets the type of reward, 'account' or 'item'
    name = 'ogn', -- Sets the name of the account or item
}

Config.AdminGroups = { -- Sets the groups that can create/edit contracts
    'admin',
    'god'
}

Config.Items = {
    OpenBoostingCad = 'boosting_cad', -- Sets the item needed to open the boosting CAD
    HackLocator = 'locator_remover' -- Sets the item needed to hack the locator system
}

Config.Hack = { -- Sets the hacking options
    Restriction = true, -- Enables or disables the restriction of hacking the locator while driving
    MinimumSpeed = 70, -- Sets the minimum speed at which the vehicle must go in order to hack the locator
    MaximumSpeed = 100, -- Sets the maximum speed allowed to hack the locator (set false to disable)
    SpeedMultiplier =  3.6 --  3.6 for km/h or 2.236936 for mph
}

Config.PlatePattern = 'XXXXXXXX' -- Sets the pattern of the license plates (Max 8 characters) (X = Random letter or number, L = Random letter, N = Random number, - = Blank space)

Config.Blips = { -- Sets the different types of blips
    Tracker = {
        Sprite = 161,
        Color = 1,
        Scale = 1.0,
    },
    Delivery = {
        Sprite = 225,
        Color = 2,
        Scale = 0.8,
    },
    Vin = {
        Sprite = 402,
        Color = 5,
        Scale = 0.8,
    },
    VehZone = {
        Alpha = 80,
        Color = 1,
        Scale = 0.8,
    },
}

Config.origenParking = false -- Enables or disable if using origen_parking

-- Minigame integration for hacking localizers
Config.Minigame = {
    Enabled = true,
    Resource = 'origen_minijuegos',
    Randomize = true,
    FallbackSuccess = false,
    DefaultDifficulty = 'medium',
    Options = {
        'StartLockpick',
        'StartHacking',
        'StartCodeBreaker',
        'StartWirePuzzle',
        'StartMinesweeper',
        'StartTimingCircles',
        'StartVarHack',
        'StartPowerGrid'
    },
    DifficultyByRank = {
        ['D'] = 'easy',
        ['C'] = 'easy',
        ['B'] = 'medium',
        ['A'] = 'medium',
        ['A+'] = 'hard',
        ['S'] = 'hard',
        ['S+'] = 'extreme'
    }
}

-- Safe weapon pool for NPC guards (no explosives/heavy weird weapons)
Config.Weapons = {
    'weapon_pistol',
    'weapon_combatpistol',
    'weapon_heavypistol',
    'weapon_snspistol',
    'weapon_microsmg',
    'weapon_smg',
    'weapon_assaultsmg',
    'weapon_carbinerifle',
    'weapon_specialcarbine'
}

-- Vehicle models available in admin contract editor
Config.VehicleModels = {
    'blista',
    'asea',
    'premier',
    'primo',
    'issi7',
    'schafter2',
    'tailgater',
    'fugitive',
    'baller',
    'granger',
    'zion',
    'windsor',
    'dominator',
    'gauntlet',
    'sabregt',
    'cognoscenti',
    'stafford',
    'superd',
    'sentinel3',
    'f620',
    'jackal',
    'jester',
    'ninef',
    'comet2',
    'turismo2',
    'infernus2',
    'zentorno',
    't20',
    'osiris',
    'entityxf'
}

-- Difficulties exposed in admin editor for selected minigame
Config.Minigame.AdminDifficultyOptions = {
    'auto',
    'easy',
    'medium',
    'hard',
    'extreme'
}