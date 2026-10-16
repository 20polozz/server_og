Config.Actions = {}
Config.Actions.RagdollInTackleFail = true -- If true, the player will ragdoll if the tackle fails when the target person is far away
Config.Actions.QuickAccessKeepInput = true -- If true, the input will be kept when the quick access is opened
Config.Actions.QuickAccessShowCursor = true -- If true, the cursor will be shown when the quick access is opened
Config.Actions.QuickAccessAllowedInputs = {
    22, 30, 31, 32, 33, 34, 35, 59, 71, 72, 76, 21, 14, 15, 16, 17, 239, 240
}

Config.Actions.AllowAllJobsTackle = false -- If true, all jobs can tackle players, otherwise only police and EMS can tackle players
Config.Actions.AllowAllJobsDrag = false -- If true, all jobs can drag players, otherwise only police and EMS can drag players
Config.Actions.AllowAllJobsPutInVehicle = true -- If true, all jobs can put players in vehicles, otherwise only police and EMS can put players in vehicles
Config.Actions.AllowAllJobsAttachPlayer = false -- If true, all jobs can attach players, otherwise only police and EMS can attach players

Config.Actions.MaxObjectsPerPlayer = 15 -- Maximum number of placed objects per player source

Config.ActionTimes = {
    ["handcuff"] = 300,
    ["drag"] = 300,
    ["putinvehicle"] = 500,
    ["attachplayer"] = 500,
    ["ankle_cuff"] = 300,
    ["ankle_shock"] = 300,
    ["placaje"] = 200,
    ["placeobj"] = 400,
    ["removeobj"] = 1000,
    ["placeradar"] = 1000,
}