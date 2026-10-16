-- #########################################################################
-- IPL Variants - TEMPLATE / DOCUMENTATION (not loaded; not in _manifest.lua)
-- #########################################################################
--
-- This is the EXTERIOR analog of the entity-set system (entitysets/*.lua).
--
--   Entity sets  -> toggle entity sets INSIDE a milo interior (needs an interior)
--   IPL variants -> toggle whole ymap IPLs ON/OFF on the exterior (no interior)
--
-- Use this when a map ships mutually-exclusive exterior variants authored as
-- separate ymaps/IPLs -- e.g. a 3D-text sign vs a 2D-text sign, or sign A vs
-- sign B. The server owner picks which variant is active simply by flipping
-- enable = true / false. enabled IPLs are RequestIpl'd, disabled IPLs are
-- RemoveIpl'd.
--
-- To use:
--   1. Copy this file to iplvariants/<your_map>.lua
--   2. Set `resource` to the map resource and fill in your variant ymap names
--   3. Add "<your_map>" to iplvariants/_manifest.lua
--
-- File shape:
--   resource  (string, REQUIRED)  The map resource that owns these ymaps. Variants
--                                 are ONLY applied while this resource is started
--                                 (RemoveIpl is global, so we never touch IPLs
--                                 unless their owning map is running).
--   variants  (table,  REQUIRED)  List of variant groups, each:
--     name  (string)   Debug/identification label
--     ipls  (table)    List of { name = "<ipl>", enable = true|false }
--                      The IPL name is the ymap filename WITHOUT the .ymap extension.

return {
    resource = "tstudio_my_map",
    variants = {
        {
            name = "Store Front Sign",
            ipls = {
                { name = "tstudio_mymap_sign_3d", enable = true  }, -- active variant
                { name = "tstudio_mymap_sign_2d", enable = false }, -- hidden variant
            },
        },
        {
            name = "Billboard",
            ipls = {
                { name = "tstudio_mymap_billboard_a",   enable = false },
                { name = "tstudio_mymap_billboard_b",   enable = true  },
                { name = "tstudio_mymap_billboard_off", enable = false },
            },
        },
    },
}
