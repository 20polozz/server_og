Config.Missions = {
    Enabled = true,
    DefaultFailOnPlayerDeath = true,
    AutoReloadOnEditorChanges = true,
    StageStartDelayMs = 500,
    MaxConcurrentPerPlayer = 1,
    DefaultObjectiveRadius = 4.0,
    StageTypes = {
        vehicle = true,
        prop = true,
        ped = true,
        zone = true,
    },
    Editor = {
        Command = "missionseditor",
        TestCommand = "missiontest",
    },
    Balance = {
        MaxPrice = 1000000,
        MaxReward = 1000000,
        MaxExperience = 1000000,
        MaxGuards = 30,
        MaxDifficulty = 4,
    },
    Replayability = {
        Enabled = true,
        RadiusJitter = 2.5,
        StageBonusRewardMax = 10,
    },
    UI = {
        MissionCategories = {
            "Aprendiz",
            "Operativo",
            "Veterano",
            "Jefe"
        },
        Props = {
            "prop_box_wood01a",
            "prop_ld_case_01",
            "prop_cs_package_01",
            "prop_money_bag_01",
            "hei_prop_heist_thermite",
            "prop_drug_package"
        }
    }
}
