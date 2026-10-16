Custom = {}
Config = Config or {}
Framework = {}
Internal = {}
Inventory = Inventory or {}

---@description Strips the .png extension from an item name if present.
---@param item string
---@return string
Inventory.StripPNG = function(item)
    if type(item) ~= "string" then return item end
    return item:gsub("%.png$", "")
end

BridgeConfig = BridgeConfig or {
    Notify = 'auto',
    HelpText = 'auto',
    VehicleKey = 'auto',
}
BridgeClientConfig = BridgeClientConfig or {
    ProgressBarSystem = 'auto',
}

local isServer = IsDuplicityVersion()
local resourceName = GetCurrentResourceName()
local version = GetResourceMetadata(resourceName, "version", 0) or "1.0.0"
resourceLoaded = false

while not Debug do
    Citizen.Wait(100)
end
local dbg = Debug:new({ enabled = Config.Debug })

---------------------------------------------------------------------
--  CLASS: ResourceDetector
---------------------------------------------------------------------
local ResourceDetector = {}
ResourceDetector.__index = ResourceDetector

function ResourceDetector:new(categories)
    return setmetatable({
        categories = categories,
        active = {}
    }, self)
end

function ResourceDetector:checkState(resource)
    local state = GetResourceState(resource)
    return state == "started" or state == "starting"
end

function ResourceDetector:findActive(list)
    for _, res in ipairs(list) do
        if self:checkState(res) then
            return res
        end
    end
    return nil
end

function ResourceDetector:detectAll()
    for category, list in pairs(self.categories) do
        self.active[category] = self:findActive(list)
    end
    return self.active
end

---------------------------------------------------------------------
--  CLASS: FrameworkLoader
---------------------------------------------------------------------
local FrameworkLoader = {}
FrameworkLoader.__index = FrameworkLoader

function FrameworkLoader:new(framework)
    return setmetatable({ framework = framework }, self)
end

function FrameworkLoader:getObject()
    local fw = self.framework
    if fw == "esx" then
        return exports["es_extended"]:getSharedObject()
    elseif fw == "qb-core" or fw == "qbx_core" then
        return exports["qb-core"]:GetCoreObject()
    end
    return nil
end

---------------------------------------------------------------------
--  CLASS: VersionChecker (solo server)
---------------------------------------------------------------------
local VersionChecker = {}
VersionChecker.__index = VersionChecker

function VersionChecker:new(resource)
    return setmetatable({
        resource = resource,
        version = version
    }, self)
end

local function normalizeVersion(v)
    return tonumber(v:gsub("%.", ""), 10)
end

function VersionChecker:check()
    local url = ("https://raw.githubusercontent.com/ElOrigenCompanyES/ScriptsVersions/master/%s.txt"):format(self.resource)

    PerformHttpRequest(url, function(err, data)
        if not data then
            self:printInfo(nil)
            return
        end

        local decoded = json.decode(data)
        local remoteV = normalizeVersion(decoded.version)
        local localV = normalizeVersion(self.version)
        local update = false

        self:printInfo(decoded, update)
    end, "GET", "", {["Content-Type"] = "application/json"})
end

function VersionChecker:printInfo(remote, update)
    resourceLoaded = true
end

---------------------------------------------------------------------
--  Start: resource detection
---------------------------------------------------------------------
local detector = ResourceDetector:new({
    framework = { "qbx_core", "qb-core", "es_extended" },
    inventory = {
        "origen_inventory", "ox_inventory", "qs-inventory", 
        "codem-inventory", "qb-inventory", "core_inventory"
    },
    fuel = { "origen_fuel", "LegacyFuel", "esx_fuel", "qb-fuel" },
    clothing = { "origen_clothing", "qb-clothing", 'illenium-appearance' }
})

local active = detector:detectAll()

-- Normalize framework names
local fw = active.framework
if fw == "es_extended" then fw = "esx" end
Config.Framework = fw

-- Config.Inventory eliminado: el bridge activo (Inventory.GetResourceName) es la fuente de verdad
Config.Fuel = active.fuel
Config.Clothing = active.clothing

---------------------------------------------------------------------
-- Framework Object
---------------------------------------------------------------------
local fwLoader = FrameworkLoader:new(Config.Framework)
Framework = fwLoader:getObject()

---------------------------------------------------------------------
-- Version Checker
---------------------------------------------------------------------
if isServer then
    local versionCheck = VersionChecker:new(resourceName)
    versionCheck:check()
end

---------------------------------------------------------------------
--- Database Initialization
---------------------------------------------------------------------
if isServer then
    while not MySQL or not resourceLoaded do
        Wait(100)
    end
    MySQL.ready(function()
        local tables = DetectSQLTables()

        for _, tableName in ipairs(tables) do
            local db = Database.new(tableName)
            db:verifyDatabaseStructure()
        end
    end)
end
