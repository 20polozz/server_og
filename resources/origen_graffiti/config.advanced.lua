-- ─────────────────────────────────────────────────────────────────────────────
-- ADVANCED CONFIG (DO NOT TOUCH without technical criteria)
--
-- ⚠️ GOLDEN RULE:
-- If you are not measuring impact (TPS, latency, network load, client load), DO NOT change values.
--
-- Risks by category:
-- [PERFORMANCE] may increase server/client CPU usage.
-- [NETWORK]     may increase traffic/latency/desync.
-- [GAMEPLAY]    may change spray difficulty/feeling.
--
-- Checklist before changing values:
-- 1) Change one variable at a time.
-- 2) Test with 10+ players.
-- 3) If it gets worse, revert to defaults.
-- ─────────────────────────────────────────────────────────────────────────────

Config = Config or {}

-- [GAMEPLAY][NETWORK] Maximum distance (meters) to paint on a canvas.
Config.PaintMaxDistance   = 8.0

-- [GAMEPLAY] Brush size range (UV).
Config.BrushRadiusMin     = 0.002
Config.BrushRadiusMax     = 0.08
Config.BrushRadiusDefault = 0.012

-- [GAMEPLAY] Spray scaling based on camera-to-wall distance.
-- Near: tighter/more intense. Far: wider/softer.
Config.SprayDistMin           = 0.4
Config.SprayDistMax           = 7.0
Config.SprayRadiusMulClose    = 0.78
Config.SprayRadiusMulFar      = 1.45
Config.SprayIntensityMulClose = 1.15
Config.SprayIntensityMulFar   = 0.4
Config.SprayDistDefault       = 2.5

-- [NETWORK][PERFORMANCE] Stroke limits (payload and DB/network load).
Config.MaxStrokesPerTag  = 4000
Config.MinStrokesPerSave = 700   -- save rejected below this threshold

-- [NETWORK][PERFORMANCE][GAMEPLAY] Live collaboration.
-- Server-side rate limit per player (1s window).
Config.CollaborationMaxStrokesPerSecond = 90
Config.CollaborationSessionTimeout      = 1800
Config.CollaborationJoinDistance        = 8.0
-- Radius to see live strokes without joining.
Config.SpectatorDistance = 28.0

-- [PERFORMANCE][NETWORK] Graffiti streaming.
-- Server caches tags; client creates DUI by proximity.

-- [NETWORK][PERFORMANCE] Search radius (m) of tags per player.
Config.SyncLoadRadius = 200.0

-- [NETWORK][PERFORMANCE] Max tags sent per query.
Config.SyncMaxTagsPerQuery = 180

-- [PERFORMANCE] Distance (m) to create/destroy DUI for each graffiti.
Config.StreamDistance = 70.0

-- [PERFORMANCE] DUI canvas resolution (pixels). Lower = less VRAM and GPU load per graffiti.
-- Must be a power of 2. Recommended: 256, 512, 1024.
Config.DuiResolution = 256

-- [PERFORMANCE] Interval (ms) for zone-change detection thread.
Config.ServerCellCheckIntervalMs = 3000

-- [GAMEPLAY] Rendered canvas opacity (0–255).
Config.TagAlpha = 190

-- [GAMEPLAY][VISUAL] Dynamic brightness by in-game time.
-- Enabled: graffiti gets darker at night.
Config.TagTimeBrightnessEnabled = true

-- In-game night range [start, end). Supports ranges crossing midnight.
-- Example 21 -> 6 means 21:00..05:59 is considered night.
Config.TagNightStartHour = 21
Config.TagNightEndHour   = 6

-- Brightness multiplier (0.0–1.0).
-- 1.0 = original color; lower values look darker.
Config.TagDayBrightness   = 1.00
Config.TagNightBrightness = 0.40

-- [GAMEPLAY] Hold duration (ms) to erase a tag.
Config.EraseTagDuration = 120000

-- [GAMEPLAY] Canvas offset adjustment while painting (owner).
-- UP/DOWN moves along the wall normal.
Config.CanvasOffsetStep = 0.005   -- meters per keypress (~5 mm)
Config.CanvasOffsetMin  = -0.30   -- max inward offset (30 cm into wall)
Config.CanvasOffsetMax  =  0.50   -- max outward offset (50 cm from wall)
