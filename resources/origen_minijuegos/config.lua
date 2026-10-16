Config = {}

-- =====================================================
-- LOCKPICK (GANZUADO DE VEHÍCULOS)
-- =====================================================

Config.Lockpick = {
    -- Dificultad general
    Difficulty = {
        easy = {
            pins = 3,           -- Número de pines a desbloquear
            timePerPin = 8,     -- Tiempo por pin (segundos)
            sweetSpotSize = 40, -- Tamaño del área correcta (%)
            moveSpeed = 1.0     -- Velocidad de movimiento
        },
        medium = {
            pins = 4,
            timePerPin = 6,
            sweetSpotSize = 30,
            moveSpeed = 1.3
        },
        hard = {
            pins = 5,
            timePerPin = 5,
            sweetSpotSize = 20,
            moveSpeed = 1.6
        },
        extreme = {
            pins = 6,
            timePerPin = 4,
            sweetSpotSize = 15,
            moveSpeed = 2.0
        }
    },

    -- Animaciones
    Animation = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        anim = 'machinic_loop_mechandplayer',
        flag = 16
    },

    -- Sonidos
    Sounds = {
        success = true,     -- Sonido de éxito
        fail = true,        -- Sonido de fallo
        tick = true,        -- Sonido de movimiento
        ambient = false     -- Sonido ambiente durante el minijuego
    },

    -- Items (si usas sistema de items)
    RequireItem = false,    -- ¿Requiere item? (false para testear)
    ItemName = 'lockpick',  -- Nombre del item
    RemoveOnFail = false,   -- ¿Remover item al fallar?
    BreakChance = 20        -- % de probabilidad de romperse al fallar
}

-- =====================================================
-- HACKING (MEMORY SEQUENCE)
-- =====================================================

Config.Hacking = {
    -- Dificultad general
    Difficulty = {
        easy = {
            levels = 3,         -- Número de niveles
            timePerLevel = 12,  -- Tiempo por nivel (segundos)
            sequenceLength = 2  -- Longitud base de secuencia (aumenta +1 por nivel)
        },
        medium = {
            levels = 5,
            timePerLevel = 10,
            sequenceLength = 2
        },
        hard = {
            levels = 6,
            timePerLevel = 8,
            sequenceLength = 3
        },
        extreme = {
            levels = 7,
            timePerLevel = 6,
            sequenceLength = 3
        }
    },

    -- Animaciones
    Animation = {
        dict = 'anim@heists@prison_heiststation@cop_reactions',
        anim = 'cop_b_idle',
        flag = 49
    },

    -- Items (si usas sistema de items)
    RequireItem = false,        -- ¿Requiere item? (false para testear)
    ItemName = 'hacking_device', -- Nombre del item
    RemoveOnFail = false,       -- ¿Remover item al fallar?
    BreakChance = 15            -- % de probabilidad de romperse al fallar
}

-- =====================================================
-- CODE BREAKER (BREACH PROTOCOL STYLE)
-- =====================================================

Config.CodeBreaker = {
    -- Dificultad general
    Difficulty = {
        easy = {
            gridSize = 5,           -- Tamaño de la matriz (5x5)
            sequenceLength = 3,     -- Longitud de la secuencia objetivo
            sequences = 1,          -- Número de secuencias a completar
            timeLimit = 30          -- Tiempo total (segundos)
        },
        medium = {
            gridSize = 6,
            sequenceLength = 4,
            sequences = 2,
            timeLimit = 35
        },
        hard = {
            gridSize = 6,
            sequenceLength = 5,
            sequences = 2,
            timeLimit = 30
        },
        extreme = {
            gridSize = 7,
            sequenceLength = 6,
            sequences = 3,
            timeLimit = 40
        }
    },

    -- Animaciones
    Animation = {
        dict = 'anim@heists@prison_heiststation@cop_reactions',
        anim = 'cop_b_idle',
        flag = 49
    },

    -- Items (si usas sistema de items)
    RequireItem = false,            -- ¿Requiere item? (false para testear)
    ItemName = 'breach_device',     -- Nombre del item
    RemoveOnFail = false,           -- ¿Remover item al fallar?
    BreakChance = 10                -- % de probabilidad de romperse al fallar
}

-- =====================================================
-- WIRE PUZZLE (CABLE MATCHING)
-- =====================================================

Config.WirePuzzle = {
    -- Dificultad general
    Difficulty = {
        easy = {
            wireCount = 4,          -- Número de cables a conectar
            timeLimit = 20,         -- Tiempo total (segundos)
            mistakes = 3            -- Errores permitidos
        },
        medium = {
            wireCount = 6,
            timeLimit = 25,
            mistakes = 2
        },
        hard = {
            wireCount = 7,
            timeLimit = 20,
            mistakes = 1
        },
        extreme = {
            wireCount = 8,
            timeLimit = 18,
            mistakes = 0            -- No se permiten errores
        }
    },

    -- Animaciones
    Animation = {
        dict = 'anim@heists@prison_heiststation@cop_reactions',
        anim = 'cop_b_idle',
        flag = 49
    },

    -- Items (si usas sistema de items)
    RequireItem = false,            -- ¿Requiere item? (false para testear)
    ItemName = 'wire_cutter',       -- Nombre del item
    RemoveOnFail = false,           -- ¿Remover item al fallar?
    BreakChance = 5                 -- % de probabilidad de romperse al fallar
}

-- =====================================================
-- MINESWEEPER (BUSCAMINAS)
-- =====================================================

Config.Minesweeper = {
    -- Dificultad general
    Difficulty = {
        easy = {
            gridSize = 5,           -- Tamaño del grid (5x5 = 25 celdas)
            mines = 4,              -- Cantidad de minas
            timeLimit = 40          -- Tiempo total (segundos)
        },
        medium = {
            gridSize = 6,           -- 6x6 = 36 celdas
            mines = 7,
            timeLimit = 50
        },
        hard = {
            gridSize = 7,           -- 7x7 = 49 celdas
            mines = 12,
            timeLimit = 60
        },
        extreme = {
            gridSize = 8,           -- 8x8 = 64 celdas
            mines = 18,
            timeLimit = 70
        }
    },

    -- Animaciones
    Animation = {
        dict = 'anim@heists@prison_heiststation@cop_reactions',
        anim = 'cop_b_idle',
        flag = 49
    },

    -- Items (si usas sistema de items)
    RequireItem = false,            -- ¿Requiere item? (false para testear)
    ItemName = 'mine_detector',     -- Nombre del item
    RemoveOnFail = false,           -- ¿Remover item al fallar?
    BreakChance = 15                -- % de probabilidad de romperse al fallar
}

-- =====================================================
-- TIMING CIRCLES (QTE CIRCLES)
-- =====================================================

Config.TimingCircles = {
    -- Dificultad general
    Difficulty = {
        easy = {
            rounds = 4,             -- Número de círculos a completar
            speed = 1.0,            -- Velocidad de contracción
            perfectZone = 25        -- Tamaño de la zona perfecta (%)
        },
        medium = {
            rounds = 6,
            speed = 1.3,
            perfectZone = 20
        },
        hard = {
            rounds = 8,
            speed = 1.6,
            perfectZone = 15
        },
        extreme = {
            rounds = 10,
            speed = 2.0,
            perfectZone = 10
        }
    },

    -- Animaciones
    Animation = {
        dict = 'anim@heists@prison_heiststation@cop_reactions',
        anim = 'cop_b_idle',
        flag = 49
    },

    -- Items
    RequireItem = false,
    ItemName = 'timing_device',
    RemoveOnFail = false,
    BreakChance = 10
}

-- =====================================================
-- VAR HACK (SYMBOL ROTATION)
-- =====================================================

Config.VarHack = {
    -- Dificultad general
    Difficulty = {
        easy = {
            lines = 3,              -- Número de líneas
            symbols = 4,            -- Símbolos por línea
            timeLimit = 30          -- Tiempo total
        },
        medium = {
            lines = 4,
            symbols = 5,
            timeLimit = 35
        },
        hard = {
            lines = 5,
            symbols = 6,
            timeLimit = 40
        },
        extreme = {
            lines = 6,
            symbols = 7,
            timeLimit = 45
        }
    },

    -- Animaciones
    Animation = {
        dict = 'anim@heists@prison_heiststation@cop_reactions',
        anim = 'cop_b_idle',
        flag = 49
    },

    -- Items
    RequireItem = false,
    ItemName = 'var_interface',
    RemoveOnFail = false,
    BreakChance = 12
}

-- =====================================================
-- POWER GRID (PATH TRACING)
-- =====================================================

Config.PowerGrid = {
    -- Dificultad general
    Difficulty = {
        easy = {
            gridSize = 5,           -- Tamaño del grid (5x5)
            pathLength = 6,         -- Longitud mínima del camino
            timeLimit = 25          -- Tiempo total
        },
        medium = {
            gridSize = 6,
            pathLength = 10,
            timeLimit = 30
        },
        hard = {
            gridSize = 7,
            pathLength = 14,
            timeLimit = 35
        },
        extreme = {
            gridSize = 8,
            pathLength = 18,
            timeLimit = 40
        }
    },

    -- Animaciones
    Animation = {
        dict = 'anim@heists@prison_heiststation@cop_reactions',
        anim = 'cop_b_idle',
        flag = 49
    },

    -- Items
    RequireItem = false,
    ItemName = 'power_tracer',
    RemoveOnFail = false,
    BreakChance = 8
}
