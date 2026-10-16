-- CRAFTING CONFIGURATION

Config.Crafting = {}

Config.Crafting.enable = true -- Enable or disable crafting system

Config.Crafting.items = {
    -- Example item
    -- ["item_name"] = { -- Must be exists on items.lua or server item list. | Item result (item key)
    --     ingredients = {
    --         ["ingredient1"] = 2, -- 2 of ingredient1 required
    --         ["ingredient2"] = 1  -- 1 of ingredient2 required
    --     },
    --     resultItem = "item_name", -- Result item name, must be defined in items.lua or server item list
    --     resultCount = 1,        -- Number of result items produced
    --     time = 5000,            -- Time in milliseconds to craft
    -- }
    ["tosti"] = {
        ingredients = {
            ["sandwich"] = 2,
            ["water_bottle"] = 1,
            ["weapon_pistol"] = 1
        },
        resultCount = 1,
        time = 5000,
    },
    ["tosti2"] = { -- This is a item key
        ingredients = {
            ["sandwich"] = 2,
        },
        -- Use 'resultItem' to specify the item produced (if not set, the 'key' will be used)
        resultItem = "tosti", -- Result item name, must be defined in items.lua or server item list
        resultCount = 1,
        time = 5000,
    },
    ["tosti3"] = { -- This is a item key
        ingredients = {
            ["sandwich"] = 2,
        },
        -- Use 'resultItem' to specify the item produced (if not set, the 'key' will be used)
        resultItem = "tosti", -- Result item name, must be defined in items.lua or server item list
        resultCount = 1,
        time = 5000,
    },
    ["tosti4"] = { -- This is a item key
        ingredients = {
            ["sandwich"] = 2,
        },
        -- Use 'resultItem' to specify the item produced (if not set, the 'key' will be used)
        resultItem = "tosti", -- Result item name, must be defined in items.lua or server item list
        resultCount = 1,
        time = 5000,
    },
    ["tosti5"] = { -- This is a item key
        ingredients = {
            ["sandwich"] = 2,
        },
        -- Use 'resultItem' to specify the item produced (if not set, the 'key' will be used)
        resultItem = "tosti", -- Result item name, must be defined in items.lua or server item list
        resultCount = 1,
        time = 5000,
    },
    ["tosti6"] = { -- This is a item key
        ingredients = {
            ["sandwich"] = 2,
        },
        -- Use 'resultItem' to specify the item produced (if not set, the 'key' will be used)
        resultItem = "tosti", -- Result item name, must be defined in items.lua or server item list
        resultCount = 1,
        time = 5000,
    }
}

Config.Crafting.zones = {
    ["crafting_zone"] = {
        enable = true, -- Enable or disable this crafting zone
        locations = vector3(-1302.4483, -2462.72, 13.92), -- Example coordinates
        radius = 2.0, -- Radius of the crafting zone
        label = "Banco de fabricación", -- Label for the crafting zone
        items = { -- Items that can be crafted in this zone
            "tosti", -- Example item that can be crafted
            "tosti2",
            "tosti3",
            "tosti4",
            "tosti5",
            "tosti6",
        },
    }
}