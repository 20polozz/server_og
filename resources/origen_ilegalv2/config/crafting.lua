--[[
    ============================================================
    CRAFTING SETTINGS
    ============================================================
    Level and XP system for the crafting module.

    PLAYER LEVEL — own table: origen_gang_crafting_progress
    GANG LEVEL   — connected to the main gang system:
                   uses gang.level and gang.exp from origen_gangs.
                   The level-up formula is configured below.
    ============================================================
--]]

Config.Crafting = {

    -- ── Player Level ──────────────────────────────────────────────────────────
    PlayerLevel = {
        -- XP formula required to move from level N to N+1.
        -- Options: 'flat' (always same amount) | 'linear' | 'exponential'
        Formula = 'linear',

        -- 'flat'        → fixed cost = BaseXP always.
        -- 'linear'      → XP = BaseXP + (current_level × IncrementPerLevel)
        --   Example (base=500, inc=250): Lv1→2=750 | Lv5→6=1750 | Lv9→10=2750
        -- 'exponential' → XP = BaseXP × (Multiplier ^ current_level)
        --   Example (base=500, mult=1.5): Lv1→2=750 | Lv5→6≈3796 | Lv9→10≈28680
        BaseXP            = 500,
        IncrementPerLevel = 250,   -- only for 'linear'
        Multiplier        = 1.5,   -- only for 'exponential'
    },

    -- ── Gang Level ─────────────────────────────────────────────────────────────
    -- Writes directly to gang.level and gang.exp (origen_gangs).
    --
    -- Formula 'custom': usa la tabla CustomXP para definir exactamente cuánto XP
    -- se necesita para pasar de nivel N al N+1.
    -- Si el nivel actual supera la tabla, se usa el último valor definido.
    GangLevel = {
        Formula  = 'custom',

        -- XP necesarios para subir DE ese nivel AL siguiente
        --   Nivel 1 → 2 : 1000 XP
        --   Nivel 2 → 3 : 3000 XP
        --   Nivel 3 → 4 : 5000 XP
        --   Nivel 4 → 5 : 7000 XP
        --   Nivel 5 → 6+: 12000 XP (y se mantiene para niveles superiores)
        CustomXP = {
            [1] = 1000,
            [2] = 3000,
            [3] = 5000,
            [4] = 7000,
            [5] = 12000,
        },

        -- Fallback para fórmulas estándar (no se usan con 'custom')
        BaseXP            = 1000,
        IncrementPerLevel = 500,
        Multiplier        = 1.6,
    },

    -- ── Banco de trabajo ───────────────────────────────────────────────────────
    -- Cada punto de fabricación pone un banco de verdad en el mundo. El punto
    -- guardado en el panel de admin es donde se pone el jugador; el banco va
    -- `Delante` metros por delante, mirando hacia el mismo lado.
    -- Los modelos viven en origen_modelos (stream/armero).
    Banco = {
        Modelos   = { 'origen_armero_banco', 'gr_prop_gr_bench_04b', 'prop_tool_bench02' },
        Delante   = 0.95,
        -- Torno, taladro de columna y esmeril en fila con el banco (solo en
        -- los puntos del mundo: en un laboratorio no hay sitio).
        Maquinas  = true,
        Distancia = 2.0,     -- a cuánto se puede usar
        Dibujar   = 80.0,    -- a cuánto aparece el banco
    },

    -- ── Montaje ────────────────────────────────────────────────────────────────
    -- Al fabricar, el personaje monta la pieza en el banco con animación y
    -- barra. Al acabar, la orden entra en la cola del punto.
    Montaje = {
        Segundos  = 10,
        Distancia = 4.0,     -- el servidor rechaza montar o recoger más lejos
    },

    -- ── Planos ─────────────────────────────────────────────────────────────────
    -- Toda arma (weapon_*) pide llevar encima su plano, el item `plano_<arma>`
    -- (p. ej. plano_weapon_pistol). No se gasta. Los planos los da la
    -- administración; los items se crean solos, uno por cada arma.
    Planos = {
        Armas    = true,
        Prefijo  = 'plano_',
        Imagen   = 'plano.png',   -- en origen_inventory/ui/images
        Peso     = 50,
        SinPlano = {},             -- armas que NO piden plano, p. ej. { 'weapon_bat' }
    },
}
