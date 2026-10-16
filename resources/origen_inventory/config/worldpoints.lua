--[[
    Origen Inventory - World Point Configuration
    Centralized configuration for all world interaction points
]]

Config = Config or {}

-----------------------------------------
----------- World Point System ----------
-----------------------------------------
Config.WorldPoints = {}

-- Enable/Disable the entire world point system
-- WARN: Disabling this will prevent all world points from being created or interacted with.
Config.WorldPoints.Enabled = true

-- Force Z coordinate to ground level when copy coords
Config.WorldPoints.ForceGroundZ = true

-- Sets whether or not the specified blip should only be displayed when nearby, or on the minimap.
Config.WorldPoints.BlipsShortRange = true

-- Sets the default model for dropped item inventories
Config.WorldPoints.UseDropModel = true
Config.WorldPoints.DefaultDropModel = `prop_med_bag_01b`

-----------------------------------------
------------- Marker Colors -------------
-----------------------------------------
Config.WorldPoints.MarkerColors = {
    stash = vector4(52, 152, 219, 150),
    shop = vector4(46, 204, 113, 150),
    crafting = vector4(230, 126, 34, 150),
}

-----------------------------------------
---------- Default Markers -------------
-----------------------------------------
Config.WorldPoints.DefaultMarkers = {
    stash = {
        show = true,
        type = 27, -- Checkpoint marker
        size = vector3(0.3, 0.3, 0.3),
        color = Config.WorldPoints.stash,
        distanceInteract = 1.5,
        bobUpAndDown = false,
        faceCamera = false,
        rotate = true
    },

    shop = {
        type = 27, -- Checkpoint marker
        size = vector3(0.3, 0.3, 0.3),
        color = Config.WorldPoints.shop,
        distanceInteract = 1.5,
        bobUpAndDown = false,
        faceCamera = false,
        rotate = true
    },

    crafting = {
        type = 30, -- Cylinder marker
        size = vector3(0.15, 0.15, 0.15),
        color = Config.WorldPoints.crafting,
        distanceInteract = 2.0,
        bobUpAndDown = false,
        faceCamera = false,
        rotate = true,
        drawOverEnts = false
    },
}

-----------------------------------------
----------- Point Types Config ----------
-----------------------------------------
--- Note: If you change the hook names,
--- be sure to update the event listeners accordingly.
--- Also, make sure that all external resources that use these hooks are updated.
--- Additionally, the sprites will stop working, and you will need to adjust to your own system.
---
--- Icons: https://icon-sets.iconify.design/
Config.WorldPoints.PointTypes = {
    stash = {
        refreshOnJobChange = true,
        loadFromConfig = true,

        -- Sprite configuration
        sprite = {
            enabled = true,
            icon = 'lucide:archive',
            offset = vector3(0, 0, 0.9),
            color = vector4(52, 152, 219, 255)
        },

        defaultMarker = Config.WorldPoints.DefaultMarkers.stash,
        hooks = {
            interactIn = 'worldpoint-interact-in',
            interactOut = 'worldpoint-interact-out',
            nearby = 'worldpoint-area-nearby'
        },
        zoneDistance = 15.0
    },

    shop = {
        refreshOnJobChange = true,
        loadFromConfig = true,

        -- Sprite configuration
        sprite = {
            enabled = true,
            icon = 'lucide:shopping-cart',
            offset = vector3(0, 0, 0.8),
            color = vector4(46, 204, 113, 255)
        },

        defaultMarker = Config.WorldPoints.DefaultMarkers.shop,
        hooks = {
            interactIn = 'worldpoint-interact-in',
            interactOut = 'worldpoint-interact-out',
            nearby = 'worldpoint-area-nearby'
        }
    },

    crafting = {
        refreshOnJobChange = true,
        loadFromConfig = true,

        -- Sprite configuration
        sprite = {
            enabled = true,
            icon = 'lucide:hammer',
            offset = vector3(0, 0, 0.5),
            color = vector4(230, 126, 34, 255),
            showCraftingPanel = true,
        },

        defaultMarker = Config.WorldPoints.DefaultMarkers.crafting,
        hooks = {
            interactIn = 'worldpoint-interact-in',
            interactOut = 'worldpoint-interact-out',
            nearby = 'worldpoint-area-nearby'
        }
    },

    drop = {
        refreshOnJobChange = false,
        loadFromConfig = false,
        sprite = {
            enabled = true,
            icon = 'lucide:box',
            offset = vector3(0, 0, 0.5),
            color = vector4(200, 200, 200, 255)
        },
        defaultMarker = nil,
        hooks = {
            interactIn = 'worldpoint-interact-in',
            interactOut = 'worldpoint-interact-out',
            nearby = 'worldpoint-area-nearby'
        }
    }
}

-----------------------------------------
---------- Initialization Config --------
-----------------------------------------
Config.WorldPoints.Initialization = {
    -- Startup delays (in milliseconds)
    taskRegistrationDelay = 200,
    jobUpdateDelay = 500,
    initialLoadDelay = 1000,
    -- Crafting panel sync interval
    craftingPanelSync = 5000
}

-----------------------------------------
--------- Interaction Settings ----------
-----------------------------------------
Config.WorldPoints.Interaction = {
    -- Key bindings
    keys = {
        interact = 38, -- E key
    },

    -- Interaction behavior
    behavior = {
        cooldownMs = 100, -- Prevent interaction spam
        allowInteractionInVehicle = false,
    },

    -- Feedback settings
    feedback = {
        -- Sound effects
        playSounds = true,
        interactSound = { name = 'SELECT', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET' }
    }
}

-----------------------------------------
---------- Visual Effects ---------------
-----------------------------------------
Config.WorldPoints.VisualEffects = {
    -- Sprite effects
    sprites = {
        enableFloatingLight = true,
        size = 2.0,
        color = vector4(255, 255, 200, 100),
        floatIntensity = 3.0
    }
}

-----------------------------------------
----------- Debug & Logging -------------
-----------------------------------------
Config.WorldPoints.Debug = {
    -- Debug options
    enabled = Config.Debug, -- Master debug toggle

    -- Visual debug
    showDebugMarkers = false, -- Show debug markers
    showPointLabels = false,  -- Show point IDs as text
}

-----------------------------------------
--------- Security & Protection ---------
-----------------------------------------
Config.WorldPoints.Security = {
    -- Anti-exploit measures
    maxInteractionsPerSecond = 1, -- Rate limiting
    checkPlayerState = true,      -- Ensure player is not dead (as game state)
}