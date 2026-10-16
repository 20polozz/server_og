Config.Airdrop = {}
-----------------------------------------
------------  AirDrops  -----------------
-----------------------------------------

-- Airdrop Settings 
-- WIP --- This feature is still in development and may not work as intended.
-- WIP --- This feature is still in development and may not work as intended.
-- WIP --- This feature is still in development and may not work as intended.
-- WIP --- This feature is still in development and may not work as intended.

-- Crate Model and Parachute Model
Config.Airdrop.CrateModel = 'prop_box_wood02a_pu'
Config.Airdrop.ParachuteModel = 'prop_v_parachute'

-- Drop Height from landing position
Config.Airdrop.DropHeight = 100.0

-- Time in ms to land (0 for auto place on ground)
Config.Airdrop.LandingTime = 10000

-- Stash max slots
Config.Airdrop.StashSlots = 20

-- Smoke settings for when the airdrop lands
Config.Airdrop.Smoke = {
    enable = true,
    particle = {
        dict = 'scr_ar_planes',
        name = 'scr_ar_trail_smoke',
    },
    scale = .8,
    -- Due to particle limitations, colors may not appear as expected
    color = { r = 170, g = 30, b = 80 },
}
