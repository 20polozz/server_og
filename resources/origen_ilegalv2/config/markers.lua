--[[
    ============================================================
    MARKERS SETTINGS
    ============================================================
    Centralizes marker styles/variables used by the client
    so they can be customized from a single place.
    ============================================================
--]]

Config.Markers = {
    -- Fallback marker for buy stores (when no NPC is visible)
    Stores = {
        interactDistance = 1.8,
        drawDistance     = 15.0,
        pointDistance    = 50.0,
        fallback = {
            type  = 1,
            offset = { x = 0.0, y = 0.0, z = 0.0 },
            scale = { x = 0.6, y = 0.6, z = 0.6 },
            color = { r = 216, g = 27, b = 85, a = 150 },
            bobUpAndDown = false,
            faceCamera   = true,
            rotationOrder = 2,
            rotate       = false,
        },
    },

    -- Fallback marker for sell points (when no NPC is visible)
    SellStores = {
        interactDistance = 1.8,
        drawDistance     = 15.0,
        pointDistance    = 50.0,
        fallback = {
            type  = 1,
            offset = { x = 0.0, y = 0.0, z = 0.0 },
            scale = { x = 0.6, y = 0.6, z = 0.6 },
            color = { r = 220, g = 221, b = 224, a = 150 },
            bobUpAndDown = false,
            faceCamera   = true,
            rotationOrder = 2,
            rotate       = false,
        },
    },

    -- Main marker for crafting points
    Crafting = {
        interactDistance = 2.0,
        drawDistance     = 20.0,
        pointDistance    = 60.0,
        marker = {
            type  = 22,
            offset = { x = 0.0, y = 0.0, z = 1.0 },
            scale = { x = 0.25, y = 0.25, z = 0.25 },
            color = { r = 0, g = 0, b = 0, a = 160 },
            bobUpAndDown = true,
            faceCamera   = true,
            rotationOrder = 2,
            rotate       = false,
        },
    },

    -- Preview marker when placing crafting points from admin panel
    AdminCraftingPreview = {
        type  = 22,
        offset = { x = 0.0, y = 0.0, z = 1.0 },
        scale = { x = 0.25, y = 0.25, z = 0.25 },
        color = { r = 0, g = 0, b = 0, a = 180 },
        bobUpAndDown = false,
        faceCamera   = true,
        rotationOrder = 2,
        rotate       = false,
    },

    -- Preview marker when placing lab entries from admin panel
    AdminLabsPreview = {
        type  = 22,
        offset = { x = 0.0, y = 0.0, z = 1.0 },
        scale = { x = 0.25, y = 0.25, z = 0.25 },
        color = { r = 0, g = 0, b = 0, a = 180 },
        bobUpAndDown = false,
        faceCamera   = true,
        rotationOrder = 2,
        rotate       = false,
    },

    -- Lab markers (world entry + interior exit/laptop)
    Labs = {
        pointDistance = 60.0,
        entryDrawDistance = 20.0,
        exitDrawDistance = 20.0,
        laptopDrawDistance = 15.0,

        entry = {
            type = 22,
            offset = { x = 0.0, y = 0.0, z = 1.0 },
            scale = { x = 0.25, y = 0.25, z = 0.25 },
            color = { r = 0, g = 0, b = 0, a = 160 },
            bobUpAndDown = true,
            faceCamera = true,
            rotationOrder = 2,
            rotate = false,
        },

        exit = {
            type = 22,
            offset = { x = 0.0, y = 0.0, z = 1.0 },
            scale = { x = 0.25, y = 0.25, z = 0.25 },
            color = { r = 0, g = 0, b = 0, a = 170 },
            bobUpAndDown = true,
            faceCamera = true,
            rotationOrder = 2,
            rotate = false,
        },

        laptop = {
            type = 22,
            offset = { x = 0.0, y = 0.0, z = 0.0 },
            scale = { x = 0.25, y = 0.25, z = 0.25 },
            color = { r = 0, g = 0, b = 0, a = 170 },
            bobUpAndDown = true,
            faceCamera = true,
            rotationOrder = 2,
            rotate = false,
        },
    },

    -- Fallback marker for location placement when marker type does not exist
    LocationPlacementFallback = {
        type  = 22,
        offset = { x = 0.0, y = 0.0, z = 1.0 },
        scale = { x = 0.25, y = 0.25, z = 0.25 },
        color = { r = 0, g = 0, b = 0, a = 200 },
        bobUpAndDown = false,
        faceCamera   = true,
        rotationOrder = 2,
        rotate       = false,
    },
}
