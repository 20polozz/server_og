Config.Lockpick = { -- Lockpick settings
    enabled = true, -- Enable or disable the lockpicking option
    customLockpickMinigame = false, -- If true, you will need to configure your minigame in the function Custom.LockpickMinigame in custom\client\robbery.lua
    policeNeed = 2, -- Number of police needed
    maxTry = 3, -- Number of attempts to pick the lock before the item breaks
    item = false, -- Item needed to pick the lock
    advancedItem = false, -- Item needed if the lockpicking upgrade is acquired
    alertOwner = true, -- Notify the house owner if someone tries to pick the lock
}

Config.AlarmDuration = 5 -- Alarm duration in minutes

Config.Dispatch = 'origen_police' -- origen_police, custom

Config.PoliceJob = 'police'