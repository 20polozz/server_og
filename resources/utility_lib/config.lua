Config = {}

Config.UpdateCooldown = 500 -- (default: 500ms) This is the time when every loop will update (dialogues, markers, utilityNet rendering)

-- Used for utility net dynamic update based on workload/number of entities, this is the timeout of a single loop in performance-saving mode
Config.UtilityNetDynamicUpdate = 3000

Config.Draw3DText = true -- If true it will draw 3D text at the markers/interaction coords
Config.Draw3DTextDistance = 4.0 -- Distance from player to show the 3D text