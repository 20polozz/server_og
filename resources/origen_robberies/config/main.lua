Config = {}

Config.TestMode = false

Config.WeaponTypes = {
    ["-728555052"] = "Melee",
    ["-1609580060"] = "Desarmado",
    ["416676503"] = "Pistol",
    ["860033945"] = "Escopeta",
    ["-957766203"] = "Subfusil",
    ["970310034"] = "Rifle de asalto",
}

Config.Minigames = {
    ['lockpick'] = {
        label = 'Lockpick',
        resource = 'origen_minijuegos',
        export = 'StartLockpick',
    },
    ['hacking'] = {
        label = 'Hacking (Memory Sequence)',
        resource = 'origen_minijuegos',
        export = 'StartHacking',
    },
    ['codebreaker'] = {
        label = 'Code Breaker (Breach Protocol)',
        resource = 'origen_minijuegos',
        export = 'StartCodeBreaker',
    },
    ['wirepuzzle'] = {
        label = 'Wire Puzzle',
        resource = 'origen_minijuegos',
        export = 'StartWirePuzzle',
    },
    ['minesweeper'] = {
        label = 'Minesweeper (Buscaminas)',
        resource = 'origen_minijuegos',
        export = 'StartMinesweeper',
    },
    ['timingcircles'] = {
        label = 'Timing Circles (QTE)',
        resource = 'origen_minijuegos',
        export = 'StartTimingCircles',
    },
    ['varhack'] = {
        label = 'VAR Hack (Symbol Rotation)',
        resource = 'origen_minijuegos',
        export = 'StartVarHack',
    },
    ['powergrid'] = {
        label = 'Power Grid (Path Tracing)',
        resource = 'origen_minijuegos',
        export = 'StartPowerGrid',
    },

    -- Los ocho nuevos (19/09/2026). Sus dificultades y todos sus numeros se
    -- tocan en origen_minijuegos/config_nuevos.lua; desde el editor de robos se
    -- puede ademas pisar cualquier ajuste suelto («ajustes finos»).
    ['ganzua'] = {
        label = 'Ganzúa de tensión',
        resource = 'origen_minijuegos',
        export = 'StartGanzua',
    },
    ['pines'] = {
        label = 'Pines del bombín',
        resource = 'origen_minijuegos',
        export = 'StartPines',
    },
    ['dial'] = {
        label = 'Dial de la caja fuerte',
        resource = 'origen_minijuegos',
        export = 'StartDial',
    },
    ['taladro'] = {
        label = 'Taladro',
        resource = 'origen_minijuegos',
        export = 'StartTaladro',
    },
    ['huella'] = {
        label = 'Clonar huella',
        resource = 'origen_minijuegos',
        export = 'StartHuella',
    },
    ['clave'] = {
        label = 'Descifrar la clave',
        resource = 'origen_minijuegos',
        export = 'StartClave',
    },
    ['senal'] = {
        label = 'Sintonizar la señal',
        resource = 'origen_minijuegos',
        export = 'StartSenal',
    },
    ['corte'] = {
        label = 'Corte de precisión',
        resource = 'origen_minijuegos',
        export = 'StartCorte',
    },

    -- La segunda tanda: los «grandes», a pantalla centrada.
    ['boveda'] = {
        label = 'Cámara acorazada (anillos)',
        resource = 'origen_minijuegos',
        export = 'StartBoveda',
    },
    ['termita'] = {
        label = 'Carga de termita (memoria)',
        resource = 'origen_minijuegos',
        export = 'StartTermita',
    },
    ['soplete'] = {
        label = 'Soplete (cortar la cerradura)',
        resource = 'origen_minijuegos',
        export = 'StartSoplete',
    },
    ['laser'] = {
        label = 'Rejilla láser (espejos)',
        resource = 'origen_minijuegos',
        export = 'StartLaser',
    },
    ['tunel'] = {
        label = 'Túnel de datos (esquivar)',
        resource = 'origen_minijuegos',
        export = 'StartTunel',
    },
    ['circuito'] = {
        label = 'Puentear el circuito',
        resource = 'origen_minijuegos',
        export = 'StartCircuito',
    },
    ['ritmo'] = {
        label = 'Sincronizar paquetes (ritmo)',
        resource = 'origen_minijuegos',
        export = 'StartRitmo',
    },
    ['inyeccion'] = {
        label = 'Inyección de código (teclear)',
        resource = 'origen_minijuegos',
        export = 'StartInyeccion',
    }
}

-- ── Comisarías — Polyzones de detección de captura ───────────────────────────
-- Si un jugador con un atraco activo entra en alguna de estas zonas,
-- el atraco se marca como FALLIDO automáticamente (sin XP).
-- Ajusta las coords y el radio según tu mapa.
Config.PolicePrecincts = {
    { coords = vector3(-432.0,  -974.0,  31.0), radius = 80.0,  label = "Mission Row PD" },
    { coords = vector3( 372.0, -1604.0,  29.0), radius = 60.0,  label = "Davis PD" },
    { coords = vector3(-1107.0, 2699.0,  18.0), radius = 60.0,  label = "Sandy Shores PD" },
    { coords = vector3(-448.0,  6008.0,  32.0), radius = 60.0,  label = "Paleto Bay PD" },
}