Config.QuickMenu = {}
Config.QuickMenu.Tabs = {
    {
        index = 'ref',
        icon = 'fa-solid fa-hashtag',
        defaultSelected = true
    },
    {
        index = 'com-rad',
        icon = 'fa-solid fa-circle-nodes',
    },
    {
        index = 'radio',
        icon = 'fa-solid fa-microphone-lines',
    },
    {
        index = 'interaccion',
        icon = 'fa-solid fa-user',
    },
    {
        index = 'guns',
        icon = 'fa-solid fa-gun',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
        hidden = not Config.Holster -- This tab will be hidden if the holster system is disabled, this option ignore allowed jobs
    },
    {
        index = 'items',
        icon = 'fa-solid fa-road-barrier',
    },
    {
        index = 'settings',
        icon = 'fa-solid fa-wrench',
    },
    {
        index = 'binds',
        icon = 'fa-solid fa-keyboard',
    },
    {
        index = 'k9',
        icon = 'fa-solid fa-dog',
        division = 'K9' -- This will be used for filtering
    },
}

Config.QuickMenu.K9 = {
    {
        header = true,
        translation = 'K9Commands'
    },
    {
        translation = 'Follow',
        icon = 'fas fa-walking',
        event = 'origen_police:client:k9:CommandFollow',
        dontClose = true
    },
    {
        translation = 'Sit',
        icon = 'fas fa-chair',
        event = 'origen_police:client:k9:CommandSit',
        dontClose = true
    },
    {
        translation = 'LieDown',
        icon = 'fas fa-bed',
        event = 'origen_police:client:k9:CommandLie',
        dontClose = true
    },
    {
        translation = 'EnterExitVehicle',
        icon = 'fas fa-car-side',
        event = 'origen_police:client:k9:CommandVehicleToggle',
        dontClose = true
    },
    {
        translation = 'Pet',
        icon = 'fas fa-heart',
        event = 'origen_police:client:k9:CommandPet',
        dontClose = true
    },
    {
        translation = 'Bark',
        icon = 'fas fa-volume-up',
        event = 'origen_police:client:k9:CommandBark',
        dontClose = true
    },
    {
        header = true,
        translation = 'K9Operational'
    },
    {
        translation = 'SearchPerson',
        icon = 'fas fa-user-search',
        event = 'origen_police:client:k9:CommandSearchPerson',
        dontClose = true
    },
    {
        translation = 'SearchVehicle',
        icon = 'fas fa-car-search',
        event = 'origen_police:client:k9:CommandSearchVehicle',
        dontClose = true
    },
    {
        translation = 'Guard',
        icon = 'fas fa-shield-dog',
        event = 'origen_police:client:k9:CommandGuard',
        dontClose = true
    },
    {
        header = true,
        translation = 'K9Appearance'
    },
    {
        translation = 'SkinTexture',
        icon = 'fas fa-palette',
        event = 'origen_police:client:k9:CommandTexture',
        dontClose = true
    },
    {
        translation = 'Ears',
        icon = 'fas fa-scissors',
        event = 'origen_police:client:k9:CommandComponent',
        id = 2,
        contextEvent = 'origen_police:client:k9:CommandComponentTexture',
        dontClose = true
    },
    {
        translation = 'Tail',
        icon = 'fas fa-paw',
        event = 'origen_police:client:k9:CommandComponent',
        id = 4,
        contextEvent = 'origen_police:client:k9:CommandComponentTexture',
        dontClose = true
    },
    {
        translation = 'Eyes',
        icon = 'fas fa-eye',
        event = 'origen_police:client:k9:CommandComponent',
        id = 5,
        contextEvent = 'origen_police:client:k9:CommandComponentTexture',
        dontClose = true
    },
    {
        translation = 'Collar',
        icon = 'fas fa-ring',
        event = 'origen_police:client:k9:CommandComponent',
        id = 6,
        contextEvent = 'origen_police:client:k9:CommandComponentTexture',
        dontClose = true
    },
    {
        translation = 'Vest',
        icon = 'fas fa-shield-halved',
        event = 'origen_police:client:k9:CommandComponent',
        id = 7,
        contextEvent = 'origen_police:client:k9:CommandComponentTexture',
        dontClose = true
    },
    {
        translation = 'PatchesUpper',
        icon = 'fas fa-shirt',
        event = 'origen_police:client:k9:CommandComponent',
        id = 8,
        contextEvent = 'origen_police:client:k9:CommandComponentTexture',
        dontClose = true
    },
    {
        translation = 'PatchesLower',
        icon = 'fas fa-vest',
        event = 'origen_police:client:k9:CommandComponent',
        id = 9,
        contextEvent = 'origen_police:client:k9:CommandComponentTexture',
        dontClose = true
    },
    {
        translation = 'SpecialEquip',
        icon = 'fas fa-suitcase',
        event = 'origen_police:client:k9:CommandComponent',
        id = 11,
        contextEvent = 'origen_police:client:k9:CommandComponentTexture',
        dontClose = true
    },
    {
        header = true,
        translation = 'K9TrainingSection'
    },
    {
        translation = 'Drugs',
        skill = 'drugs',
        icon = 'fas fa-cannabis',
        customClass = 'k9-specialty-item',
        dontClose = true
    },
    {
        translation = 'Weapons',
        skill = 'weapons',
        icon = 'fas fa-gun',
        customClass = 'k9-specialty-item',
        dontClose = true
    },
    {
        translation = 'Money',
        skill = 'money',
        icon = 'fas fa-money-bill',
        customClass = 'k9-specialty-item',
        dontClose = true
    },
    {
        translation = 'Explosives',
        skill = 'explosives',
        icon = 'fas fa-bomb',
        customClass = 'k9-specialty-item',
        dontClose = true
    },
    {
        header = true,
        translation = 'K9AdminManagement',
        permission = 'K9Admin'
    },
    {
        translation = 'GiveXP',
        icon = 'fas fa-plus',
        event = 'origen_police:client:k9:GiveXP',
        permission = 'K9Admin',
        dontClose = false
    },
    {
        translation = 'ResetK9',
        icon = 'fas fa-trash-can',
        event = 'origen_police:client:k9:ResetK9',
        permission = 'K9Admin',
        dontClose = false
    },
    {
        translation = 'ResetSkills',
        icon = 'fas fa-rotate-left',
        event = 'origen_police:client:k9:ResetSkills',
        permission = 'K9Admin',
        dontClose = false
    },
    {
        translation = 'ManageItems',
        icon = 'fas fa-box-open',
        event = 'origen_police:client:k9:ManageItems',
        permission = 'K9Admin',
        dontClose = false
    },
    {
        translation = 'ManageVehicles',
        icon = 'fas fa-car-rear',
        event = 'origen_police:client:k9:ManageVehicles',
        permission = 'K9Admin',
        dontClose = false
    }
}


Config.QuickMenu.Interactions = {
    {
        header = true,
        translation = 'CitizenInteraction'
    },
    {
        translation = 'Search',
        icon = 'fa-solid fa-user',
        command = 'cachearPolice',
        allowedJobs = {
            Config.PoliceJobCategory,
            "fib"
        },
    },
    {
        translation = 'Wifes',
        icon = 'fa-solid fa-user',
        event = 'origen_police:client:cuffuncuff',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
    {
        translation = 'Escort',
        icon = 'fa-solid fa-user',
        event = 'origen_police:client:drag'
    },
    {
        translation = 'PutInVehicle',
        icon = 'fa-solid fa-user',
        event = 'origen_police:client:vehicleinof'
    },
    {
        translation = 'JumpTo',
        icon = 'fa-solid fa-user',
        command = 'placaje',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
    {
        translation = 'revive',
        icon = 'fa-solid fa-user-doctor',
        command = 'revivep',
        allowedJobs = {
            Config.EmsJobCategory,
            { job = "saspa", ranks = {3,7} }
        },
    },
    {
        translation = 'HealWounds',
        icon = 'fa-solid fa-briefcase-medical',
        command = Config.Framework == 'qbcore' and 'heal' or 'healp',
        allowedJobs = {
            Config.EmsJobCategory,
            { job = "saspa", ranks = {3,7} }
        },
    },
    {
        translation = 'CheckStatus',
        icon = 'fa-solid fa-notes-medical',
        command = 'revisar',
        allowedJobs = {
            Config.EmsJobCategory,
            { job = "saspa", ranks = {3,7} }
        },
    },
    {
        translation = 'Corneta',
        icon = 'fa-solid fa-user',
        event = 'origen_police:client:corneta',
        allowedJobs = {
            "saspa"
        },
    },

    {
        header = true,
        translation = 'VehicleInteraction',
        allowedJobs = {
            Config.PoliceJobCategory,
            "fib"
        },
    },
    {
        translation = 'TrafficCitation',
        icon = 'fa-solid fa-file-invoice-dollar',
        event = 'origen_police:client:openCitationPad',
        keepFocus = true,
        allowedJobs = {
            Config.PoliceJobCategory,
            "fib",
            "saspa"
        },
    },
    {
        translation = 'VehicleInformation',
        icon = 'fa-solid fa-car',
        event = 'origen_police:client:vehicledata',
        allowedJobs = {
            Config.PoliceJobCategory,
            "fib"
        },
    },
    {
        translation = 'ImpoundVehicle',
        icon = 'fa-solid fa-car',
        event = 'origen_police:client:incautar',
        allowedJobs = {
            Config.PoliceJobCategory,
            "fib"
        },
    },
    {
        translation = 'ConfiscateVehicle',
        icon = 'fa-solid fa-car',
        event = 'origen_police:client:confiscar',
        allowedJobs = {
            Config.PoliceJobCategory,
            "fib"
        },
    },
    {
        translation = 'ForceLock',
        icon = 'fa-solid fa-car',
        event = 'origen_police:client:openveh',
        allowedJobs = {
            Config.PoliceJobCategory,
            "fib"
        },
    },
    {
        translation = 'StopTraffic',
        icon = 'fa-solid fa-car',
        serverEvent = 'origen_police:server:stoptraffic',
        allowedJobs = {
            Config.PoliceJobCategory,
            "fib"
        },
    },
    {
        translation = 'ReduceTraffic',
        icon = 'fa-solid fa-car',
        serverEvent = 'origen_police:server:slowtraffic',
        allowedJobs = {
            Config.PoliceJobCategory,
            "fib"
        },
    },
    {
        translation = 'ResumeTraffic',
        icon = 'fa-solid fa-car',
        serverEvent = 'origen_police:server:resumetraffic',
        allowedJobs = {
            Config.PoliceJobCategory,
            "fib"
        },
    },
    {
        translation = 'RadarLimit',
        icon = 'fa-solid fa-gauge-high',
        command = 'radar-limit',
        allowedJobs = {
            Config.PoliceJobCategory,
            "fib"
        },
    },
}

Config.QuickMenu.Holster = {
    {
        translation = 'ShowHideWeapons',
        icon = 'fa-solid fa-user',
        event = 'origen_police:holster:unarm',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
    {
        header = true,
        translation = 'PistolPos'
    },
    {
        translation = 'Front',
        icon = 'fa-solid fa-user',
        command = 'holster boxers',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
    {
        translation = 'Behind',
        icon = 'fa-solid fa-user',
        command = 'holster backhandgun',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
    {
        translation = 'WaistCart',
        icon = 'fa-solid fa-user',
        command = 'holster waisthandgun',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
    {
        translation = 'NormalCart',
        icon = 'fa-solid fa-user',
        command = 'holster handguns',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
    {
        translation = 'ChestCart',
        icon = 'fa-solid fa-user',
        command = 'holster chesthandgun',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
    {
        translation = 'ThighCart',
        icon = 'fa-solid fa-user',
        command = 'holster hiphandgun',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
    {
        translation = 'LegCart',
        icon = 'fa-solid fa-user',
        command = 'holster leghandgun',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
    {
        translation = 'SeparateLegCart',
        icon = 'fa-solid fa-user',
        command = 'holster handguns2',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
    {
        header = true,
        translation = 'RiflePos'
    },
    {
        translation = 'Chest',
        icon = 'fa-solid fa-user',
        command = 'holster tacticalrifle',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
    {
        translation = 'BackRifle',
        icon = 'fa-solid fa-user',
        command = 'holster assault',
        allowedJobs = {
            Config.PoliceJobCategory,
            "saspa",
            "fib"
        },
    },
}

Config.QuickMenu.Objects = {
    {
        name = 'none', -- The remove button is not a Config.Props object
        icon = 'bin.png',
        translation = 'Delete',
        allowedJobs = {
            'all'
        },
        customEvent = 'rmveobj', -- Custom event to remove the object
        customClass = 'bg-qrr', -- Custom class for the red background
        dontClose = true, -- This button will not close the quick menu
    },
    -- {
    --     name = 'none', -- The remove button is not a Config.Props object
    --     icon = 'bin.png',
    --     translation = 'RemoveTape',
    --     allowedJobs = {
    --         'police',
    --         'sheriff',
    --         'sapd'
    --     },
    --     event = 'origen_police:removetape', -- Custom event to remove the tape
    --     customClass = 'bg-qrr', -- Custom class for the red background
    --     dontClose = true, -- This button will not close the quick menu
    -- },
}