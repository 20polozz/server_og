Config.HandCuff = {
    BlockedInputs = {
        68, -- INPUT_VEH_AIM
        69, -- INPUT_VEH_ATTACK
        21, -- INPUT_SPRINT
        24, -- INPUT_ATTACK
        257,-- INPUT_ATTACK2
        25, -- INPUT_AIM
        263,-- INPUT_MELEE_ATTACK1
        45, -- INPUT_RELOAD
        22, -- INPUT_JUMP
        44, -- INPUT_COVER
        37, -- INPUT_SELECT_WEAPON
        23, -- INPUT_ENTER
        288,-- PHONE(F1)
        289,-- INVENTORY(F2)
        170,-- ANIMATIONS(F3)
        167,-- JOB(F6)
        0,  -- Disable changing view
        26, -- Disable looking behind
        73, -- Disable clearing animation
        59, -- Disable steering in vehicle
        71, -- Disable driving forward in vehicle
        72, -- Disable reversing in vehicle
        49, -- Disable Key F
        36, -- Disable going stealth
        47, -- Disable weapon
        264,-- Disable melee
        257,-- Disable melee
        140,-- Disable melee
        141,-- Disable melee
        142,-- Disable melee
        143,-- Disable melee
        75, -- Disable exit vehicle
        75, -- Disable exit vehicle (again)
        45, -- Disable key R
        80, -- Disable key R
        140,-- Disable key R
        250,-- Disable key R
        263,-- Disable key R
        310,-- Disable key R
    },
    Events = {
        OnCuff = function()
            -- When the player gets cuffed
        end,
        WhileCuff = function()
            -- Called while the player is cuffed
        end,
        OnUncuff = function()
            -- When the player gets uncuffed
        end
    },
    SkillCheck = {
        enabled = false, -- Enable a skillcheck to make target handcuffing to give the a chance to escape
        WaitChance = 3500, -- The time that have to escape
        func = function(playerCufferId)
            if not lib then
                return print("^1[ERROR] ^0Oxlib not found, please make sure that you have it and the fxmanifest oxlib line is uncommented.")
            end
            return lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 1}}, {'w', 'a', 's', 'd'})
        end
    },
    AllowAllJobs = false, -- Allow all jobs to use the handcuff system
    Anims = {
        Idle = {
            dict = "mp_arresting",
            anim = "idle"
        },
        Cuffing = {
            dict = "mp_arrest_paired",
            anim = "cop_p2_back_right"
        },
        Uncuffing = {
            dict = "mp_arresting",
            anim = "a_uncuff"
        },
        BeingCuffed = {
            dict = "mp_arrest_paired",
            anim = "crook_p2_back_right"
        },
        BeingUncuffed = {
            dict = "mp_arresting",
            anim = "b_uncuff"
        }
    }
}