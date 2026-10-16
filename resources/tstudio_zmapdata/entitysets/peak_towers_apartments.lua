-- #########################################
-- Peak Towers Apartments Entity Set Configuration
-- #########################################
-- 14 floors (1-4, 6-15), each with hallway + 4 apartments (L1, L2, R1, R2)
-- All entries are floorManaged = true (handled by activate_ipl.lua)

return {
    -- Floor 1
    {
        name = "Peak Towers Apt Floor 1 Hallway",
        coords = vector3(57.393196, -930.921143, 194.374359),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor1_hallway_milo",
        entitySets = {
            {name = "floor01", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 1 L1",
        coords = vector3(80.463562, -934.085083, 194.379868),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor1_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 1 L2",
        coords = vector3(34.322750, -927.757080, 194.379929),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor1_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 1 R1",
        coords = vector3(50.271099, -908.750610, 194.379868),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor1_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 1 R2",
        coords = vector3(64.515244, -953.091553, 194.379929),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor1_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 2
    {
        name = "Peak Towers Apt Floor 2 Hallway",
        coords = vector3(57.393196, -930.921143, 199.143738),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor2_hallway_milo",
        entitySets = {
            {name = "floor02", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 2 L1",
        coords = vector3(80.463562, -934.085083, 199.149246),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor2_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 2 L2",
        coords = vector3(34.322750, -927.757080, 199.149307),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor2_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 2 R1",
        coords = vector3(64.515244, -953.091553, 199.149307),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor2_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 2 R2",
        coords = vector3(50.271099, -908.750610, 199.149246),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor2_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 3
    {
        name = "Peak Towers Apt Floor 3 Hallway",
        coords = vector3(57.393196, -930.921143, 203.543030),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor3_hallway_milo",
        entitySets = {
            {name = "floor03", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 3 L1",
        coords = vector3(34.322750, -927.757080, 203.548615),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor3_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 3 L2",
        coords = vector3(80.463562, -934.085083, 203.548553),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor3_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 3 R1",
        coords = vector3(50.271099, -908.750610, 203.548553),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor3_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 3 R2",
        coords = vector3(64.515244, -953.091553, 203.548615),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor3_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 4
    {
        name = "Peak Towers Apt Floor 4 Hallway",
        coords = vector3(57.393196, -930.921143, 207.942368),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor4_hallway_milo",
        entitySets = {
            {name = "floor04", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 4 L1",
        coords = vector3(80.463562, -934.085083, 207.947891),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor4_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 4 L2",
        coords = vector3(34.322750, -927.757080, 207.947952),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor4_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 4 R1",
        coords = vector3(64.515244, -953.091553, 207.947952),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor4_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 4 R2",
        coords = vector3(50.271099, -908.750610, 207.947891),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor4_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 6
    {
        name = "Peak Towers Apt Floor 6 Hallway",
        coords = vector3(57.393196, -930.921143, 238.738556),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor6_hallway_milo",
        entitySets = {
            {name = "floor06", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 6 L1",
        coords = vector3(80.463562, -934.085083, 238.744080),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor6_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 6 L2",
        coords = vector3(34.322750, -927.757080, 238.744141),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor6_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 6 R1",
        coords = vector3(64.515244, -953.091553, 238.744141),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor6_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 6 R2",
        coords = vector3(50.271099, -908.750610, 238.744080),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor6_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 7
    {
        name = "Peak Towers Apt Floor 7 Hallway",
        coords = vector3(57.393196, -930.921143, 243.137894),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor7_hallway_milo",
        entitySets = {
            {name = "floor07", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 7 L1",
        coords = vector3(34.322750, -927.757080, 243.143478),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor7_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 7 L2",
        coords = vector3(80.463562, -934.085083, 243.143417),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor7_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 7 R1",
        coords = vector3(50.271099, -908.750610, 243.143417),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor7_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 7 R2",
        coords = vector3(64.515244, -953.091553, 243.143478),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor7_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 8
    {
        name = "Peak Towers Apt Floor 8 Hallway",
        coords = vector3(57.393196, -930.921143, 247.537231),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor8_hallway_milo",
        entitySets = {
            {name = "floor08", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 8 L1",
        coords = vector3(80.463562, -934.085083, 247.542755),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor8_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 8 L2",
        coords = vector3(34.322750, -927.757080, 247.542816),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor8_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 8 R1",
        coords = vector3(64.515244, -953.091553, 247.542816),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor8_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 8 R2",
        coords = vector3(50.271099, -908.750610, 247.542755),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor8_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 9
    {
        name = "Peak Towers Apt Floor 9 Hallway",
        coords = vector3(57.393196, -930.921143, 251.936569),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor9_hallway_milo",
        entitySets = {
            {name = "floor09", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 9 L1",
        coords = vector3(34.322750, -927.757080, 251.942154),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor9_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 9 L2",
        coords = vector3(80.463562, -934.085083, 251.942093),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor9_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 9 R1",
        coords = vector3(50.271099, -908.750610, 251.942093),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor9_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 9 R2",
        coords = vector3(64.515244, -953.091553, 251.942154),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor9_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 10
    {
        name = "Peak Towers Apt Floor 10 Hallway",
        coords = vector3(57.393196, -930.921143, 256.335907),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor10_hallway_milo",
        entitySets = {
            {name = "floor10", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 10 L1",
        coords = vector3(80.463562, -934.085083, 256.341431),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor10_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 10 L2",
        coords = vector3(34.322750, -927.757080, 256.341492),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor10_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 10 R1",
        coords = vector3(64.515244, -953.091553, 256.341492),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor10_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 10 R2",
        coords = vector3(50.271099, -908.750610, 256.341431),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor10_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 11
    {
        name = "Peak Towers Apt Floor 11 Hallway",
        coords = vector3(57.393196, -930.921143, 282.731873),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor11_hallway_milo",
        entitySets = {
            {name = "floor11", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 11 L1",
        coords = vector3(34.322750, -927.757080, 282.737457),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor11_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 11 L2",
        coords = vector3(80.463562, -934.085083, 282.737396),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor11_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 11 R1",
        coords = vector3(50.271099, -908.750610, 282.737396),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor11_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 11 R2",
        coords = vector3(64.515244, -953.091553, 282.737457),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor11_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 12
    {
        name = "Peak Towers Apt Floor 12 Hallway",
        coords = vector3(57.393196, -930.921143, 287.131256),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor12_hallway_milo",
        entitySets = {
            {name = "floor12", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 12 L1",
        coords = vector3(80.463562, -934.085083, 287.136780),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor12_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 12 L2",
        coords = vector3(34.322750, -927.757080, 287.136841),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor12_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 12 R1",
        coords = vector3(64.515244, -953.091553, 287.136841),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor12_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 12 R2",
        coords = vector3(50.271099, -908.750610, 287.136780),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor12_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 13
    {
        name = "Peak Towers Apt Floor 13 Hallway",
        coords = vector3(57.393196, -930.921143, 291.530670),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor13_hallway_milo",
        entitySets = {
            {name = "floor13", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 13 L1",
        coords = vector3(34.322750, -927.757080, 291.536255),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor13_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 13 L2",
        coords = vector3(80.463562, -934.085083, 291.536194),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor13_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 13 R1",
        coords = vector3(50.271099, -908.750610, 291.536194),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor13_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 13 R2",
        coords = vector3(64.515244, -953.091553, 291.536255),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor13_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 14
    {
        name = "Peak Towers Apt Floor 14 Hallway",
        coords = vector3(57.393196, -930.921143, 295.930054),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor14_hallway_milo",
        entitySets = {
            {name = "floor14", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 14 L1",
        coords = vector3(80.463562, -934.085083, 295.935577),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor14_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 14 L2",
        coords = vector3(34.322750, -927.757080, 295.935638),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor14_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 14 R1",
        coords = vector3(64.515244, -953.091553, 295.935638),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor14_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 14 R2",
        coords = vector3(50.271099, -908.750610, 295.935577),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor14_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },

    -- Floor 15
    {
        name = "Peak Towers Apt Floor 15 Hallway",
        coords = vector3(57.393196, -930.921143, 300.329437),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor15_hallway_milo",
        entitySets = {
            {name = "floor15", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 15 L1",
        coords = vector3(34.322750, -927.757080, 300.335022),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor15_l1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 15 L2",
        coords = vector3(80.463562, -934.085083, 300.334961),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor15_l2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 15 R1",
        coords = vector3(50.271099, -908.750610, 300.334961),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor15_r1_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
    {
        name = "Peak Towers Apt Floor 15 R2",
        coords = vector3(64.515244, -953.091553, 300.335022),
        floorManaged = true,
        ipl = "tstudio_hg_peaktowers_apa_floor15_r2_milo",
        entitySets = {
            {name = "apa_furnished", enable = true},
            {name = "apa_main_blinds_open", enable = true},
            {name = "apa_bedroom_blinds_open", enable = true},
            {name = "apa_closet_blinds_open", enable = true},
        }
    },
}
