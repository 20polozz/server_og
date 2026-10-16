-- ═══════════════════════════════════════════════════════════════════════════
--  ORG Parking — Configuration
--  Version: 1.0.0  |  by OrigenNetwork
--
--  ► This file is NOT encrypted. Edit freely.
--  ► Restart the resource after any change.
-- ═══════════════════════════════════════════════════════════════════════════

Config = {}

-- ─────────────────────────────────────────────────────────────────────────────
--  LANGUAGE
--  Available: 'en'  'es'  'fr'  'de'  'pt'
--  Add your own in locales/<code>.lua
-- ─────────────────────────────────────────────────────────────────────────────
Config.Locale = 'es'

-- ─────────────────────────────────────────────────────────────────────────────
--  FRAMEWORK
--  Controls how the resource identifies players and checks vehicle ownership.
--
--  'qbx'     → QBCore-X  (qbx_core)
--  'qb'      → QBCore    (qb-core)
--  'esx'     → ESX       (es_extended)
--  'custom'  → Edit custom/sv_framework.lua yourself
-- ─────────────────────────────────────────────────────────────────────────────
Config.Framework = 'qbx'

-- ─────────────────────────────────────────────────────────────────────────────
--  KEY SYSTEM
--  Controls how vehicle keys are given and lock state is set.
--
--  'qbx_vehiclekeys' → qbx_vehiclekeys
--  'qs-vehiclekeys'  → qs-vehiclekeys
--  'rk-keys'         → rk-keys
--  'none'            → Vehicles spawn unlocked, no keys given
--  'custom'          → Edit custom/sv_keys.lua and custom/cl_keys.lua
-- ─────────────────────────────────────────────────────────────────────────────
Config.KeySystem = 'qbx_vehiclekeys'

-- ─────────────────────────────────────────────────────────────────────────────
--  ADMIN PERMISSION SYSTEM
--  Controls who can access /orgadmin
--
--  'origen_admin' → origen_admin resource (recommended for OrigenNetwork servers)
--  'ace'          → FiveM built-in ACE permissions (works in any server)
--  'qbx'          → QBX/QB player group (god/superadmin/admin)
--  'esx'          → ESX player group (superadmin/admin)
--  'custom'       → Edit custom/sv_framework.lua → Framework.HasAdminPermission()
-- ─────────────────────────────────────────────────────────────────────────────
Config.AdminSystem = 'origen_admin'

-- Permission key to check (used with 'origen_admin' and 'custom')
Config.AdminPermission = 'org_parking'

-- ACE node to check (only used when AdminSystem = 'ace')
-- Add to server.cfg:  add_ace group.admin  org_parking.admin  allow
Config.AdminAceNode = 'org_parking.admin'

-- ─────────────────────────────────────────────────────────────────────────────
--  NOTIFICATION SYSTEM
--  How server-side messages are shown to players.
--
--  'ox_lib'   → ox_lib notifications (requires ox_lib)
--  'qbx'      → QBX/QB notifications
--  'esx'      → ESX notifications
--  'chat'     → Plain chat message
--  'custom'   → Edit custom/sv_framework.lua → Framework.Notify()
-- ─────────────────────────────────────────────────────────────────────────────
Config.NotifySystem = 'ox_lib'

-- ─────────────────────────────────────────────────────────────────────────────
--  DATABASE
--  Table name used by this resource. Run sql/install.sql once to create it.
--  Do NOT rename after data already exists.
-- ─────────────────────────────────────────────────────────────────────────────
Config.TableName = 'org_parking'

-- ─────────────────────────────────────────────────────────────────────────────
--  GARAGE INTEGRATION
--  Automatically syncs with garage resources when vehicles are stored/retrieved.
--  Set to 'none' to disable.
--
--  'origen_garages' → origen_garages (OrigenNetwork)
--  'qb-garages'     → qb-garages
--  'none'           → No integration
--  'custom'         → Edit custom/sv_framework.lua → Framework.SetVehicleStorageState()
-- ─────────────────────────────────────────────────────────────────────────────
Config.GarageIntegration = 'origen_garages'

-- ─────────────────────────────────────────────────────────────────────────────
--  AUTOMATIC PARKING
-- ─────────────────────────────────────────────────────────────────────────────

-- Auto-park when a player exits their vehicle?
Config.AutomaticParking = true

-- Seconds to wait after exit for the player to LOCK the vehicle.
-- The vehicle is only saved when locked within this window.
-- If not locked → the vehicle is NOT parked (player will come back).
Config.AutomaticParkingTimeout = 30

-- ─────────────────────────────────────────────────────────────────────────────
--  LOCK BEHAVIOUR
-- ─────────────────────────────────────────────────────────────────────────────

-- Lock vehicles when they are spawned by this system?
Config.LockVehiclesOnSpawn = true

-- Give keys to the owner when their vehicle spawns nearby?
Config.GiveKeysOnSpawn = true

-- ─────────────────────────────────────────────────────────────────────────────
--  PROXIMITY (meters)
--  SpawnRadius  — vehicle spawns when a player enters this range
--  DespawnRadius — despawn timer starts when ALL players leave this range
--
--  IMPORTANT: DespawnRadius should be > SpawnRadius (hysteresis gap).
--  This prevents "flickering" when a player stands at the exact boundary.
--  Recommended: SpawnRadius = 200, DespawnRadius = 250
-- ─────────────────────────────────────────────────────────────────────────────
Config.SpawnRadius   = 200.0
Config.DespawnRadius = 250.0

-- Seconds to wait after all players leave before the entity is actually deleted.
-- Higher = safer transition, lower = less entity time in the world.
Config.DespawnDelay = 10

-- ─────────────────────────────────────────────────────────────────────────────
--  SPATIAL GRID
--  The world is divided into cells of this size (meters).
--  Smaller = more precise queries, but more cells to maintain.
--  With SpawnRadius 200 m, cell size 150 m → scans 3×3 = 9 cells per player.
-- ─────────────────────────────────────────────────────────────────────────────
Config.GridCellSize = 150

-- ─────────────────────────────────────────────────────────────────────────────
--  SPAWN QUEUE (parallel concurrent spawning)
--  Maximum number of vehicles that spawn simultaneously (server-side).
--  Higher = faster zone population, slightly more server CPU pressure.
--  3 is a safe default for 500-player servers.
--  Increase to 5 if your server handles entity creation well.
--
--  The client-side mods-apply queue automatically uses SpawnConcurrency + 1
--  workers so cosmetic passes keep pace with entity creation.
--  (SpawnConcurrency = 3 → 4 mod workers; = 5 → 6 mod workers, etc.)
-- ─────────────────────────────────────────────────────────────────────────────
Config.SpawnConcurrency = 8    -- simultaneous entity creations

-- ─────────────────────────────────────────────────────────────────────────────
--  CLEANUP
--  Automatically delete parking entries for vehicles inactive for N days.
-- ─────────────────────────────────────────────────────────────────────────────
Config.Clean = {
    enabled         = true,
    maxInactiveDays = 30,
}

-- ─────────────────────────────────────────────────────────────────────────────
--  ROUTING BUCKETS (DIMENSIONS)
--  Enable if your server uses routing buckets (e.g. instances, interiors).
--  When enabled, vehicles are only visible within the same bucket.
-- ─────────────────────────────────────────────────────────────────────────────
Config.UseDimensions = false

-- ─────────────────────────────────────────────────────────────────────────────
--  PARKING LIMITS
-- ─────────────────────────────────────────────────────────────────────────────

-- Maximum parked vehicles per grid cell (GridCellSize × GridCellSize area).
-- 0 = disabled (recommended default — use ZoneLimits for fine-grained control).
-- With GridCellSize = 150, each cell is ~150×150 m (≈2 city blocks).
-- A busy server downtown can easily accumulate 20-30 vehicles per cell;
-- set this only if you notice problematic hotspots. Suggested value: 25.
Config.MaxPerCell = 0

-- Maximum parked vehicles per player across the whole map.
-- 0 = disabled (recommended default).
-- Set to e.g. 5 if you want to limit how many cars one player can park at once.
Config.MaxPerPlayer = 0

-- Named zones with individual limits.
-- If a player tries to park inside a zone that has reached its limit, parking
-- is denied and a notification is shown.
--
-- Format:
--   { name = 'Label', coords = vector3(x, y, z), radius = N, max = N }
--
-- Example — limit the Legion Square area to 8 parked cars:
--   { name = 'Legion Square', coords = vector3(195.2, -937.0, 30.7), radius = 80.0, max = 8 },
Config.ZoneLimits = {
    -- { name = 'Downtown',    coords = vector3(195.2, -937.0, 30.7), radius = 120.0, max = 10 },
    -- { name = 'Sandy Paleto', coords = vector3(26.2, 6554.0, 31.8), radius = 150.0, max = 6  },
}

-- ─────────────────────────────────────────────────────────────────────────────
--  PARKING COST  (charged when the player retrieves their vehicle)
--  The charge is calculated based on how long the vehicle has been parked.
-- ─────────────────────────────────────────────────────────────────────────────
Config.ParkingCost = {
    enabled      = false,   -- Set true to charge players when retrieving a vehicle
    ratePerHour  = 50,      -- Money units charged per hour parked
    minimum      = 10,      -- Minimum charge even for very short stays
    freeMinutes  = 0,       -- Grace period in minutes — no charge within this window
    blockIfBroke = true,    -- If true, prevent unpark when the player cannot afford the fee
}

-- ─────────────────────────────────────────────────────────────────────────────
--  MAP BLIPS
--  Shows a blip on the player's map for each of their own parked vehicles.
-- ─────────────────────────────────────────────────────────────────────────────
Config.BlipEnabled = true
Config.BlipColor   = 3      -- GTA blip color id  (0=white 1=red 2=green 3=blue 5=yellow 40=purple)

--[[ El dibujo YA NO SALE DE AQUI. Los puntos los pinta el mapa de ORIGEN, que
     usa el icono de su categoria: este es de 'garages', o sea el del coche,
     que es justo lo que queria decir el 669. El numero se queda escrito porque
     es lo que enseña el panel de admin, pero cambiarlo no cambia nada. ]]
Config.BlipSprite  = 669    -- GTA blip sprite     (669=car parked  357=parking P  225=small car  56=vehicle)

-- ─────────────────────────────────────────────────────────────────────────────
--  PARKING MARKER
--  Draws a small floating "P" above every nearby parked vehicle so players
--  can identify system-parked cars at a glance.
--  Toggleable in real-time from the admin panel.
-- ─────────────────────────────────────────────────────────────────────────────
Config.ParkingMarker = {
    enabled  = true,   -- Show the "P" marker above parked vehicles
    drawDist = 20.0,   -- Maximum distance (meters) at which the marker is visible
}

-- ─────────────────────────────────────────────────────────────────────────────
--  FUEL
--  Persist and restore the vehicle's fuel level when parked / spawned.
--  Works with most popular fuel resources or falls back to the GTA native.
-- ─────────────────────────────────────────────────────────────────────────────
Config.SaveFuel   = true
Config.FuelSystem = 'auto'  -- 'auto' | 'ox_fuel' | 'LegacyFuel' | 'ps-fuel' | 'cdn-fuel' | 'native'
--  'auto' detects whichever compatible fuel resource is running on your server.

-- ─────────────────────────────────────────────────────────────────────────────
--  COLLISION NOTIFICATION
--  When a parked vehicle moves from its stored position (detected by the
--  proximity tracker), the registered owner receives a notification.
--  Fires at most once every CollisionPositionUpdateInterval seconds per vehicle
--  (shared rate-limit with the position update) — no spam possible.
-- ─────────────────────────────────────────────────────────────────────────────
Config.CollisionNotify = true

-- ─────────────────────────────────────────────────────────────────────────────
--  COLLISION POSITION UPDATE
--  When a parked vehicle is pushed by a collision while it is spawned,
--  the system automatically updates its stored position so it stays where
--  it ended up rather than snapping back to the original spot.
--
--  CollisionPositionUpdateInterval: minimum seconds between DB writes per
--  vehicle (prevents a single collider from flooding the database).
-- ─────────────────────────────────────────────────────────────────────────────
Config.CollisionPositionUpdateInterval = 3   -- seconds

-- ─────────────────────────────────────────────────────────────────────────────
--  ANTI-THEFT
--  When enabled, parked vehicles cannot be stolen by other players.
--
--  Mechanism 1 — Entity state flag:
--    Entity(entity).state.isParked = true  is set on every spawned vehicle.
--    Lockpick scripts that check this flag (qbx_vehiclekeys, qs-vehiclekeys,
--    most modern key resources) will automatically refuse to pick a parked car.
--
--  Mechanism 2 — Server-side eject:
--    If a non-owner manages to enter a parked vehicle (e.g. a lockpick resource
--    that does not check entity state), they are immediately ejected and notified.
-- ─────────────────────────────────────────────────────────────────────────────
Config.AntiTheft = true

-- ─────────────────────────────────────────────────────────────────────────────
--  BLACKLISTS
-- ─────────────────────────────────────────────────────────────────────────────

-- Vehicle models that cannot be parked (bicycles, restricted vehicles, etc.)
Config.BlacklistedModels = {
    'bmx', 'cruiser', 'fixter', 'scorcher', 'tribike', 'tribike2', 'tribike3',
}

-- Zones where parking is not allowed (e.g. interiors, mission areas)
-- Format: { coords = vector3(x,y,z), radius = N }
Config.BlacklistedZones = {
    -- { coords = vector3(-1077.0, -85.1, -90.2), radius = 50.0 },
}

-- ─────────────────────────────────────────────────────────────────────────────
--  ADMIN PANEL COMMAND
-- ─────────────────────────────────────────────────────────────────────────────
Config.AdminCommand = 'orgadmin'

-- ─────────────────────────────────────────────────────────────────────────────
--  DEBUG
--  Set to true to enable verbose console output.
--  ALWAYS set to false in production!
-- ─────────────────────────────────────────────────────────────────────────────
Config.Debug = false
