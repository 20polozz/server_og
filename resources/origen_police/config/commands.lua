Config.Commands = {

    -- Police Cad
    OpenPoliceCad = {
        cmd = 'pcad', -- command for open the police cad
        description = Config.Translations.OpenPoliceCad, -- description for the command
        key = '', -- key for open the police cad
        item = 'police_cad', -- item for open the police cad
    },

    -- Panel de Administración Policial
    OpenPoliceAdmin = {
        cmd = 'policeadmin', -- Comando principal (/policeadmin)
        aliases = { 'adminpolice' }, -- Comandos alternativos (/adminpolice)
        description = 'Abrir panel de administración policial',
        permission = 'origen_police', -- Permiso asignable en origen_admin
        ace = 'command.policeadmin', -- Permiso ACE asignable en server.cfg (ej: add_ace group.admin command.policeadmin allow)
        allowBoss = true, -- Permitir a jefes policiales (sapd / isboss)
        allowAdminGroup = true, -- Permitir a administradores staff (god, admin, mod)
    },

    -- Radar
    VehicleRadar = { -- key for open the vehicle radar
        cmd = 'alpr',
        description = Config.Translations.VehicleRadar,
        key = 'NUMPAD5'
    },
    LockRadar = { -- key for lock the radar
        cmd = 'balpr',
        description = Config.Translations.LockRadar,
        key = 'NUMPAD8',
    },
    MoveRadar = { -- key for move the radar
        cmd = 'moveralpr',
        description = Config.Translations.MoveRadar,
        key = 'NUMPAD4',
    },
    RadarLimit = { -- key for setting the radar limit
        cmd = 'radarlimit',
        description = 'Establecer Límite de Radar',
        key = '',
    },

    -- Dispatch
    NextAlert = { -- key for go to the next alert in the mini dispatch
        cmd = 'nxtalert',
        description = Config.Translations.NextAlert,
        key = 'RIGHT',
    },
    PreviousAlert = { -- key for go to the previous alert in the mini dispatch
        cmd = 'prvalert',
        description = Config.Translations.PreviousAlert,
        key = 'LEFT',
    },
    AcceptAlert = { -- key for accept the alert in the mini dispatch and marke into the map
        key = 'O',
    },
    DeleteAlert = { -- key for decline the alert in the mini dispatch
        key = 'I',
    },
    OpenMiniDispatch = { -- key for open the mini dispatch
        cmd = 'minidispatch',
        description = Config.Translations.OpenMiniDispatch,
        key = 'U',
    },

    -- K9
    K9Menu = { -- key for open the K9 menu
        cmd = 'k9',
        description = Config.Translations.K9Menu,
        key = 'K',
    },

    -- Sirens
    SirensKey = { -- key for activate sirens
        cmd = 'sirens',
        description = Config.Translations.SirensKey,
        key = 'COMMA',
    },
    LightsSirens = { -- key for activate lights
        cmd = 'lights',
        description = Config.Translations.LightsSirens,
        key = 'Q',
    },
    HornKey = {
        key = 86, -- Key code for the horn: https://docs.fivem.net/docs/game-references/controls/
        disabledKey = 86, -- If nil no key will be disabled, this is to avoid other game actions when the horn is performed: https://docs.fivem.net/docs/game-references/controls/
    },

    -- Interactions
    HandCuff = { -- key for handcuff
        description = Config.Translations.HandCuff,
        key = '',
    },
    Search = { -- key for search
        cmd = 'cachearcerca',
        description = Config.Translations.SearchPlayer or 'Policía: Cachear',
        key = '',
    },
    Escort = { -- key for escort
        cmd = 'escoltarcerca',
        description = Config.Translations.EscortPlayer or 'Policía: Escoltar',
        key = '',
    },
    QRR = { -- key for QRR
        description = Config.Translations.QRR,
        key = '',
    },
    Ten20 = { -- key for 10-20
        description = Config.Translations.Ten20,
        key = '',
    },
    Ten13B = { -- key for QRR-B
        description = Config.Translations.Ten13B,
        key = '',
    },
    Ten13C = { -- key for QRR-C
        description = Config.Translations.Ten13C,
        key = '',
    },
    Tackle = { -- key for tackle
        description = Config.Translations.Tackle,
        key = '',
    },
    VehicleInto = { -- key for set ped into the vehicle
        description = Config.Translations.VehicleInto,
        key = '',
    },
    VehiclePursuit = { -- key for set ped into the vehicle
        description = Config.Translations.VehiclePursuit,
        key = '',
    },
    CambioJurisdiccion = { -- key for Cambio Jurisdiccion
        description = Config.Translations.CambioJurisdiccionKey,
        key = '',
    },

    -- Force
    ForceVehicle = {  -- The name of the command to force vehicles, this is going to force the vehicle and send alert to on duty
        cmd = 'forzar',
    },

    -- Quick access menu
    -- Sin tecla: el menu rapido se abre desde el riel del inventario, en el
    -- boton de Policia, igual que el de banda y el de negocio. Para devolver
    -- el F7 basta con volver a poner key = 'F7'; el comando sigue existiendo
    -- y por ahi el menu se abre sin riel.
    QuickAccess = { -- key for open the right menu
        cmd = 'quickaccess',
        description = Config.Translations.QuickAccess or 'Menú Rápido Policía / Servicios',
        key = '',
    },

    -- Duty Toggle
    ToggleDuty = {
        cmd = 'toggleduty',
        description = Config.Translations.ToggleDutyCommand,
        key = '',
    },

    -- Minimap
    Minimap = { -- key for set the minmap to police mode
        cmd = 'policeminmap',
        description = Config.Translations.Minimap,
        key = '',
    },

    -- Radio
    TalkRadio = { -- key for talk on your radio
        description = Config.Translations.TalkRadio,
        key = 'LMENU',
    },

    ChangeRadioAnim = { -- commands for change the radio animation
        cmd = 'animradio',
    },

    TalkMegaphone = { -- key for talk in the megaphone
        key = 246, -- DEFUALT KEY: Y - https://docs.fivem.net/docs/game-references/controls/
    },

    -- Helicopter
    CamOrRappel = {
        key = 38, -- DEFAULT KEY: E - https://docs.fivem.net/docs/game-references/controls/
    },
    Heli254V = {
        cmd = '254v',
        description = Config.Translations.Heli254V,
        key = '', -- Changed from E to B as default to avoid conflict, user can rebind
    },

    -- Alerts
    CustomCommandAlert = {
        ["entorno"] = {
            jobCategory = {"police", "fib"},
            triggerEvent = "origen_police:client:onPlayerCall911",
            sound = "https://r2.fivemanage.com/hKHnIwIXgeaTI05Xdks2b/sonidoalertas.mp3",
        },
        ["auxilio"] = {
            jobCategory = "ambulance",
            title = "Aviso de Auxilio",
            triggerEvent = "origen_police:client:onPlayerCall911ems",
            ignoreCooldown = true,
            sound = "https://r2.fivemanage.com/hKHnIwIXgeaTI05Xdks2b/sonidoalertas.mp3",
        },
    }
}