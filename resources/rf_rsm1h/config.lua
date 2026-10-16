-- ============================================================================
--  rf_rsm1h  -  CONFIG
--  Door codes are in server/locks.lua (default public code - 5555/admin code - 0000)
-- ============================================================================

Config = Config or {}


-- ----------------------------------------------------------------------------
--  FEATURES        true = on, false = off
-- ----------------------------------------------------------------------------

Config.Features = {
    blinds     = true,   -- window blinds
    cameras    = true,   -- security cameras
    motion     = true,   -- camera motion alerts (needs cameras)
    doors      = true,   -- door locks
    doorKey    = true,   -- lock or unlock a door by walking up to it (needs doors)
    radio      = true,   -- music zones
    screens    = true,   -- video screens
    lifts      = true,   -- elevators
    phone      = true,   -- handheld panel
    panelSound = true,   -- panel clicks and chimes
    worldSound = true,   -- door and device sounds in the world
}


-- ----------------------------------------------------------------------------
--  MUSIC           audio files in html/audio, listed here by file name
--
--      'my song.mp3',
--      { file = 'trk_04.ogg', label = 'Night Run' },   -- with its own name
-- ----------------------------------------------------------------------------

Config.Tracks = {
	'2026.mp3',
}


-- ----------------------------------------------------------------------------
--  AUDIO
--
--  volume    0.0 to 1.0, except where marked 0-100
--  near      full volume within this many metres
--  far       silent at this many metres
--  distance  not heard past this many metres
-- ----------------------------------------------------------------------------

Config.Audio = {
    -- your own panel
    panel = {
        volume = 0.20,
    },

    -- someone else's panel nearby
    panelOthers = {
        volume   = 0.05,
        distance = 10.0,
    },

    -- doors, movers, blinds
    world = {
        volume   = 0.45,
        distance = 22.0,
    },

    -- camera motion alert
    alert = {
        volume   = 0.14,
        distance = 16.0,
    },

    -- music zones
    radio = {
        volume = 14,        -- 0-100, starting volume
        near   = 2.5,
        far    = 22.0,
    },

    -- video screens
    screen = {
        volume = 14,        -- 0-100, starting volume
        near   = 3.0,
        far    = 22.0,
    },

    -- elevators
    lift = {
        volume   = 0.65,    -- master volume
        distance = 25.0,
        clips = {           -- level of each sound
            doorOpen  = 0.45,
            doorClose = 0.45,
            start     = 0.50,   -- leaving
            move      = 0.42,   -- the ride
            ending    = 0.50,   -- arriving
            finish    = 0.38,   -- the chime
            uiopen    = 0.60,   -- call panel opening
        },
    },
}


-- ----------------------------------------------------------------------------
--  SOUNDS          files in html/audio/ui, without the .ogg
-- ----------------------------------------------------------------------------

Config.Sounds = {
    press   = 'origen_click',  -- any button (ORIGEN: sonido del riel)
    tap     = 'origen_click',  -- keypad digits
    on      = 'up',            -- something opening
    off     = 'down',          -- something closing
    open    = 'origen_slide',  -- panel opening (ORIGEN: deslizar del riel)
    close   = 'origen_slide',  -- panel closing
    codeBad = 'wrong_pass',    -- wrong code
    alert   = 'alert',         -- camera motion

    hiddenOpen  = 'hiddendoor_open',    -- hidden door opening
    hiddenClose = 'hiddendoor_close',   -- hidden door closing
}


-- ----------------------------------------------------------------------------
--  KEYS            38 = E   44 = Q   73 = X
--                  full list: docs.fivem.net/docs/game-references/controls
--
--  openPanel and doorKey share E. Near both, the wall pad wins.
-- ----------------------------------------------------------------------------

Config.Keys = {
    openPanel = 38,   -- open a wall pad
    doorKey   = 38,   -- lock or unlock a door
    camNext   = 38,   -- next camera
    camPrev   = 44,   -- previous camera
    camSweep  = 73,   -- camera auto pan
}


-- ----------------------------------------------------------------------------
--  PHONE
-- ----------------------------------------------------------------------------

Config.Phone = {
    command = 'controlperuano',   -- chat command that opens and closes it   ('' for none)
    key     = '',       -- key that does the same: 'F5', 'HOME'    ('' for none)

    -- Limit the command and key to certain players. Wall pads are not affected.
    whitelist = {
        enabled     = false,
        identifiers = {
            -- 'license:0000000000000000000000000000000000000000',
            -- 'discord:000000000000000000',
        },
        ace         = '',   -- ace permission, e.g. 'rf_rsm1h.phone'   ('' for none)
    },

    requireNear = false,    -- true = the phone only works near a wall pad
}


-- ----------------------------------------------------------------------------
--  GENERAL
-- ----------------------------------------------------------------------------

Config.ResetOnStart = true    -- everything back to default on restart
Config.Debug        = false   -- print what the script is doing to the console

-- Wireframe boxes showing the reach of wall pads, door locks and elevators
Config.DebugDraw = {
    enabled  = false,
    distance = 60.0,   -- metres
}
