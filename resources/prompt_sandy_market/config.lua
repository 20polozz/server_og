Config = {}

-- IPL Configuration
Config.IPLs = {
    {
        name = "Sandy Market - Arcade Stalls",
        ipl = "box55_s_market_stalls_arcade",
        enabled = true,
        description = "Arcade game stalls in Sandy Shores Market"
    },
    {
        name = "Sandy Market - Boat Stalls",
        ipl = "box55_s_market_stalls_boats",
        enabled = true,
        description = "Boat equipment stalls in Sandy Shores Market"
    },
    {
        name = "Sandy Market - Clothing Stalls",
        ipl = "box55_s_market_stalls_clothing",
        enabled = true,
        description = "Clothing stalls in Sandy Shores Market"
    },
    {
        name = "Sandy Market - Crafting Stalls",
        ipl = "box55_s_market_stalls_crafting",
        enabled = true,
        description = "Crafting material stalls in Sandy Shores Market"
    },
    {
        name = "Sandy Market - Junk Stalls",
        ipl = "box55_s_market_stalls_junk",
        enabled = true,
        description = "Junk and scrap stalls in Sandy Shores Market"
    },
    {
        name = "Sandy Market - Plant Stalls",
        ipl = "box55_s_market_stalls_plants",
        enabled = true,
        description = "Plant and garden stalls in Sandy Shores Market"
    },
    {
        name = "Sandy Market - Tattoo Stalls",
        ipl = "box55_s_market_stalls_tattoo",
        enabled = true,
        description = "Tattoo equipment stalls in Sandy Shores Market"
    },
    {
        name = "Sandy Market - Vending Stalls",
        ipl = "box55_s_market_stalls_vending",
        enabled = true,
        description = "Vending machine stalls in Sandy Shores Market"
    },
    {
        name = "Sandy Market - Wholesale Stalls",
        ipl = "box55_s_market_stalls_wholesale",
        enabled = true,
        description = "Wholesale goods stalls in Sandy Shores Market"
    }
}

-- Menu Configuration
Config.Menu = {
    position = "top-right",
    title = "Sandy Market IPL Manager",
    subtitle = "Manage market stalls"
}

-- Command Configuration
Config.Command = {
    name = "marketipls",
    description = "Open IPL management menu",
    restricted = false -- Set to true if you want to restrict to admins
}

-- Fallback settings when ox_lib is not available
Config.Fallback = {
    autoLoad = true -- Automatically load enabled IPLs on resource start
} 