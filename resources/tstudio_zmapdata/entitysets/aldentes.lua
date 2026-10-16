-- #########################################
-- Al Dentes Entity Set Configuration
-- #########################################
-- Migrated from tstudio_aldentes/client/interior.lua.
-- Available sets on this interior: r8_casino_yes (table shown), r8_casino_no (table hidden).
-- Original behaviour activated r8_casino_no only (casino table hidden) -- preserved exactly here.

return {
    {
        name = "Al Dentes",
        coords = vector3(-1191.25867, -1402.93933, 7.4126153),
        ipl = "johanni_aldentes_milo_",
        entitySets = {
            {name = "r8_casino_no", enable = true},
        }
    },
}
