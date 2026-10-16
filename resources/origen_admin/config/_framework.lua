Config = {}
Config.Language = "es" -- en, es, fr, cn, it
Config.Debug = false -- true | false to enable or disable debug mode
Config.Framework = "auto" -- auto, esx, qbcore
Config.Inventory = "origen_inventory" -- origen_inventory | qb-inventory | qs-inventory | codem-inventory | ox_inventory
Config.AmbulanceSystem = "qb-ambulancejob" -- qb-ambulancejob | esx_ambulancejob | wasabi_ambulance | default
Config.ClothingSystem = "origen_clothing" -- origen_clothing | qb-clothing | illenium-appearance | vms_clothestore
Config.HousingSystem = "origen_housing" -- default | origen_housing | qs-housing
Config.GarageSystem = "default" -- default(can work with others system) | cd_garage | okokGarage
--[[ Respaldo: manda origen_businesses (Config.Tuning.System); esto solo se usa si ese recurso no está o no expone el valor. ]]
Config.TunningSystem = "origen_customs" -- origen_customs | qb-mechanicjob | vms_tunning | esx_tunning | okokTunning
Config.FuelSystem = "default" -- default | legacyfuel
Config.PermissionList = { -- Only the permissions that will be able to execute admin actions, don't add user groups, ONLY ADMIN GROUPS!
    'mod',
    'admin',
    'god'
}
Config.PermissionSystem = false -- true | false to enable or disable the custom permission system and use the framework's permission system
Config.CkStructure = { -- These are the data that will be deleted when a player is wiped
    ["qbcore"] = {
        {table = "players", column="citizenid"}
    },
    ["esx"] = {
        {table = "users", column="identifier"}
    }
}

Config.MoneyName = {
    ["esx"] = "money",
    ["qbcore"] = "cash"
}
Config.CustomBanSystem = false -- If this is set to true the function of custom/server/actions.lua will be used instead of the default ban system

-- DONT TOUCH ANYTHING BELOW THIS LINE
if Config.Framework ~= "auto" and Config.Framework ~= "esx" and Config.Framework ~= "qbcore" then
    print("Invalid framework, please use 'esx' or 'qbcore'")
    return
end
if Config.Framework == "auto" then 
    Config.Framework = GetResourceState("es_extended") == "started" and "esx" or "qbcore"
end
Config.CkStructure = Config.CkStructure[Config.Framework]
Config.MoneyName = Config.MoneyName[Config.Framework]
if Config.Debug then
    function Debuger(...)
        print ('[^5Origen Admin^0]', ...)
    end
else
    Debuger = function() end
end