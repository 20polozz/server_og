-- #########################################
-- Pillbox MD Entity Set Configuration
-- #########################################
-- 3 floors, each with privacy glass entity sets
-- All entries are floorManaged = true (handled by activate_ipl.lua)
-- Default: privacy glass OFF (clear/transparent)

return {
    -- Floor 1 (Ground)
    {
        name = "Pillbox MD Floor 1",
        coords = vector3(306.003, -568.511, 64.159),
        floorManaged = true,
        ipl = "johanni_pillbox_e03_01_milo_",
        entitySets = {
            {name = "r7_privacy_off", enable = true},
        }
    },
    -- Floor 2
    {
        name = "Pillbox MD Floor 2",
        coords = vector3(306.003, -568.511, 68.162),
        floorManaged = true,
        ipl = "johanni_pillbox_e03_02_milo_",
        entitySets = {
            {name = "r7_privacy_off", enable = true},
        }
    },
    -- Floor 3
    {
        name = "Pillbox MD Floor 3",
        coords = vector3(306.003, -568.511, 60.025),
        floorManaged = true,
        ipl = "johanni_pillbox_e03_03_milo_",
        entitySets = {
            {name = "r7_privacy_off", enable = true},
        }
    },
}
