ElevatorConfig = {
    -- ============================================================
    -- ELEVATOR FLOORS
    -- Add/remove floors as needed. Each floor needs:
    --   label       : Display name in the menu
    --   description : Short description shown under the label
    --   coords      : { x, y, z } – where the player will be teleported
    --   heading     : Direction the player faces after teleport
    -- ============================================================
    Floors = {
        {
            label       = 'First Floor',
            description = 'Ground level',
            icon        = 'door-open',
            coords      = vector3(1759.181, 3657.415, 34.606),
            heading     = 210.0,
        },
        {
            label       = 'Rooftop',
            description = 'Hospital rooftop',
            icon        = 'cloud',
            coords      = vector3(1759.912, 3656.929, 40.459),
            heading     = 210.0,
        },
    },

    -- ============================================================
    -- INTERACTION ZONES
    -- One zone per floor where the player can interact with the elevator.
    -- size     : box dimensions (x, y, z)
    -- rotation : yaw rotation of the box (degrees)
    -- ============================================================
    Zones = {
        [1] = { -- First Floor zone
            coords   = vector3(1759.181, 3657.415, 34.606),
            size     = vector3(1.0, 1.0, 2.0),
            rotation = 210.0,
        },
        [2] = { -- Rooftop zone
            coords   = vector3(1759.912, 3656.929, 40.459),
            size     = vector3(1.0, 1.0, 2.0),
            rotation = 210.0,
        },
    },

    -- ============================================================
    -- INTERACTION METHOD
    -- 'auto'      – uses ox_target if available, falls back to textUI
    -- 'ox_target'  – forces ox_target (requires ox_target resource)
    -- 'textui'     – forces [E] key + lib.showTextUI
    -- ============================================================
    interaction = 'auto',

    -- ============================================================
    -- MESSAGES  (change text / translate as you wish)
    -- ============================================================
    Messages = {
        prompt        = '[E] Use Elevator',
        menuTitle     = 'Hospital Elevator',
        tpInProgress  = 'Teleporting…',
    },

    -- ============================================================
    -- CUSTOM MENU OVERRIDE
    -- If you want to use a different menu system instead of ox_lib,
    -- set UseCustomMenu = true and fill in the function below.
    --
    -- The function receives two arguments:
    --   floors       – the ElevatorConfig.Floors table
    --   currentFloor – index of the floor the player is currently on
    --
    -- Your function should display a menu and, when the player picks
    -- a floor, call the global  HospitalElevator_TeleportToFloor(floorIndex)
    -- function to perform the teleport.
    -- ============================================================
    UseCustomMenu = false,

    CustomMenuFunction = function(floors, currentFloor)
        -- Example with esx_menu_default or any other menu:
        --
        -- local elements = {}
        -- for i, floor in ipairs(floors) do
        --     if i ~= currentFloor then
        --         elements[#elements + 1] = { label = floor.label, value = i }
        --     end
        -- end
        -- ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'hospital_elevator', {
        --     title   = ElevatorConfig.Messages.menuTitle,
        --     align   = 'top-left',
        --     elements = elements,
        -- }, function(data, menu)
        --     menu.close()
        --     HospitalElevator_TeleportToFloor(data.current.value)
        -- end, function(data, menu)
        --     menu.close()
        -- end)
    end,
}

-- ================================================================
-- MRI SCANNER SYSTEM
-- ================================================================
MRIConfig = {
    -- ============================================================
    -- MRI BED MODEL
    -- Model name of the MRI bed prop (used for both static hiding
    -- and dynamic spawning – same model).
    -- ============================================================
    bedModel = 'i45pt_s_hsp_prop_mri_machine_bed',

    -- ============================================================
    -- BED POSITIONS
    -- outsideCoords : where the bed rests (matches the static prop)
    -- insideCoords  : where the bed slides to inside the MRI tube
    -- bedHeading    : yaw rotation of the bed
    --
    -- Adjust insideCoords to match your MRI tube placement.
    -- Typically an offset of ~1.5–2.0 m along the bed's heading.
    -- ============================================================
    bedOutsideCoords = vector3(1756.484, 3654.363, 34.56277),
    bedInsideCoords  = vector3(1755.542, 3653.819, 34.56277),
    bedHeading       = 120.0,

    -- ============================================================
    -- INTERACTION POINTS
    -- patientInteract  : zone/target near the bed where patient lies down
    -- operatorInteract : zone at the MRI desk for the operator (textUI mode)
    -- operatorDeskModel: when using ox_target, targets this prop directly
    -- ============================================================
    patientInteractCoords = vector3(1757.0, 3654.0, 34.56),
    patientInteractSize   = vector3(1.5, 1.5, 2.0),

    operatorInteractCoords = vector3(1756.817, 3650.458, 34.583),
    operatorInteractSize   = vector3(1.5, 1.5, 2.0),
    operatorInteractHeading = 39.369,

    -- ox_target will target this prop model directly instead of a box zone
    operatorDeskModel = 'i45pt_s_hsp_prop_deskmri',

    -- ============================================================
    -- TIMING
    -- slideDuration : how long the bed takes to move in/out (ms)
    -- scanDuration  : how long the MRI scan takes (ms)
    -- ============================================================
    slideDuration = 3000,
    scanDuration  = 10000,

    -- ============================================================
    -- SCAN LIGHT EFFECT
    -- Blue flashing light inside the MRI tube during a scan.
    -- coords    : center of the MRI machine bore
    -- color     : { r, g, b } (0–255)
    -- range     : how far the light reaches (metres)
    -- intensity : peak brightness (0–10)
    -- flashHz   : flashes per second (higher = faster strobe)
    -- ============================================================
    scanLight = {
        coords    = vector3(1754.25, 3653.06, 34.74),
        color     = { r = 50, g = 140, b = 255 },
        range     = 3.0,
        intensity = 5.0,
        flashHz   = 3.0,
    },

    -- ============================================================
    -- PATIENT ANIMATION
    -- dict : animation dictionary
    -- name : animation clip name
    -- ============================================================
    patientAnim = {
        dict = 'anim@gangops@morgue@table@',
        name = 'body_search',
    },

    -- ============================================================
    -- PATIENT ATTACHMENT OFFSETS
    -- Fine-tune these so the player lies correctly on the bed.
    -- offset   : x, y, z relative to the bed entity
    -- rotation : pitch, roll, yaw relative to the bed entity
    -- ============================================================
    patientOffset   = vector3(0.0, 0.8, 0.95),  -- Y shifts patient towards MRI tube; Z ≈ bed surface height
    patientRotation = vector3(0.0, 0.0, 180.0),

    -- ============================================================
    -- INTERACTION METHOD  (same options as elevator)
    -- 'auto' | 'ox_target' | 'textui'
    -- ============================================================
    interaction = 'auto',

    -- ============================================================
    -- MESSAGES  (change text / translate as you wish)
    -- ============================================================
    messages = {
        patientPrompt  = 'Lie on MRI Bed',
        operatorPrompt = 'MRI Controls',
        menuTitle      = 'MRI Scanner',
        moveInside     = 'Move Bed Inside',
        moveOutside    = 'Move Bed Outside',
        startScan      = 'Start MRI Scan',
        scanInProgress = 'Scanning...',
        scanComplete   = 'MRI Scan Complete',
        bedMoving      = 'Bed is moving...',
        alreadyInUse   = 'MRI is currently in use',
        noPatient      = 'No patient on the bed',
        getUpHint      = 'Press [BACKSPACE] to get up',
        releasePatient = 'Release Patient',
        accessDenied   = 'You do not have access to operate the MRI',
    },

    -- ============================================================
    -- JOB / PERMISSION CHECK  (server-side)
    -- Return true to allow the player to operate the MRI controls.
    -- Customise for your framework – examples below.
    -- ============================================================
    canOperate = function(source)
        -- ── ESX ──────────────────────────────────────
        -- local xPlayer = ESX.GetPlayerFromId(source)
        -- return xPlayer and xPlayer.getJob().name == 'ambulance'

        -- ── QBCore / QBox ────────────────────────────
        -- local Player = QBCore.Functions.GetPlayer(source)
        -- return Player and Player.PlayerData.job.name == 'ambulance'

        -- ── No restriction (default) ─────────────────
        return true
    end,

    -- ============================================================
    -- ON SCAN COMPLETE CALLBACK  (server-side)
    -- Called when the MRI scan finishes.  Hook your medical records,
    -- rewards, or any other server logic here.
    --   patient  = server id of the patient
    --   operator = server id of the operator
    -- ============================================================
    onScanComplete = function(patient, operator)
        -- Example: TriggerClientEvent('hospital:mriResult', patient)
    end,
}

-- ================================================================
-- HOSPITAL BED SIT / LIE SYSTEM
-- ================================================================
BedConfig = {
    -- ============================================================
    -- BED MODELS
    -- Each bed has its own offsets because prop origins differ.
    --   lieOffset / lieRotation  : player position when lying flat
    -- ============================================================
    beds = {
        {
            model        = 'i45pt_s_hsp_prop_operationbed_01',
            lieOffset    = vector3(0.0, 0.0, 1.85),
            lieRotation  = vector3(0.0, 0.0, -90.0),
            -- Model origin is underground — ox_target raycast can't hit it.
            -- Use fixed sphere zones at each bed surface instead of addModel.
            -- Add one vector3 per surgery bed instance in the map.
            interactCoords = {
                vector3(1779.751, 3640.697, 35.0),
                vector3(1769.717, 3634.843, 35.505),
            },
        },
        {
            model       = 'i45pt_s_hsp_bed_01',
            lieOffset   = vector3(0.0, 0.1, 1.25),
            lieRotation = vector3(0.0, 0.0, 180.0),
        },
        {
            model       = 'i45pt_s_hsp_bed_02',
            lieOffset   = vector3(0.0, 0.1, 1.25),
            lieRotation = vector3(0.0, 0.0, 0.0),
        },
    },

    -- ============================================================
    -- ANIMATION (shared across all beds)
    -- ============================================================
    lieAnim = {
        dict = 'anim@gangops@morgue@table@',
        name = 'body_search',
    },

    -- ============================================================
    -- INTERACTION METHOD
    -- 'auto'      – uses ox_target if available, falls back to textUI
    -- 'ox_target'  – forces ox_target
    -- 'textui'     – forces proximity thread + [E] key
    -- ============================================================
    interaction = 'auto',

    -- ============================================================
    -- MESSAGES  (change text / translate as you wish)
    -- ============================================================
    messages = {
        lieDown   = 'Lie Down',
        getUp     = 'Get Up',
        getUpHint = 'Press [BACKSPACE] to get up',
    },
}

-- ================================================================
-- COUCH / CHAIR SEATING
-- ================================================================
-- Seats use scenario animations (TaskStartScenarioAtPosition)
-- which handle sit-down / stand-up transitions automatically.
-- Coordinates are absolute world positions.
--
-- conflicts = list of seat IDs that CANNOT be used at the same
--             time as this seat (checked server-side).
-- ================================================================
CouchConfig = {
    -- ============================================================
    -- SEAT DEFINITIONS
    -- Each seat: absolute world coords, heading, scenario, and
    -- optional conflicts list.
    --
    -- Scenarios you can use:
    --   PROP_HUMAN_SEAT_BENCH          – casual bench sit
    --   PROP_HUMAN_SEAT_ARMCHAIR       – relaxed armchair / couch
    --   PROP_HUMAN_SEAT_CHAIR          – generic chair
    --   PROP_HUMAN_SEAT_CHAIR_DRINK    – chair + drink in hand
    --   PROP_HUMAN_SEAT_CHAIR_UPRIGHT  – formal upright chair
    --   PROP_HUMAN_SEAT_CHAIR_UPRIGHT_SHOWROOM – showroom upright chair
    --   PROP_HUMAN_SEAT_CHAIR_MP_PLAYER – MP player chair
    --   WORLD_HUMAN_SUNBATHE_BACK      – lie on back (sunbathe)
    -- ============================================================
    seats = {
        { -- 1: couch left
            coords    = vector3(1738.8086, 3618.7, 34.088646),
            heading   = 301.829,
            scenario  = 'PROP_HUMAN_SEAT_BENCH',
        },
        { -- 2: couch middle
            coords    = vector3(1739.2198, 3618.03, 34.088646),
            heading   = 301.829,
            scenario  = 'PROP_HUMAN_SEAT_ARMCHAIR',
        },
        { -- 3: couch right
            coords    = vector3(1739.656, 3617.2134, 34.088646),
            heading   = 301.829,
            scenario  = 'PROP_HUMAN_SEAT_CHAIR',
        },
        { -- 4: side chair
            coords    = vector3(1742.9275, 3617.2156, 34.091736),
            heading   = 31.829,
            scenario  = 'PROP_HUMAN_SEAT_CHAIR',
        },
        { -- 5: side armchair
            coords    = vector3(1741.625, 3616.4578, 34.09514),
            heading   = 31.829,
            scenario  = 'PROP_HUMAN_SEAT_ARMCHAIR',
        },
        { -- 7: office chair
            coords    = vector3(1733.523, 3627.338, 34.097157),
            heading   = 301.829,
            scenario  = 'PROP_HUMAN_SEAT_CHAIR',
        },
        { -- 8: showroom chair A
            coords    = vector3(1733.0753, 3628.122, 34.129467),
            heading   = 301.829,
            scenario  = 'PROP_HUMAN_SEAT_CHAIR_UPRIGHT_SHOWROOM',
        },
        { -- 9: showroom chair B (opposite facing)
            coords    = vector3(1732.5541, 3627.848, 34.117462),
            heading   = 121.829,
            scenario  = 'PROP_HUMAN_SEAT_CHAIR_UPRIGHT_SHOWROOM',
        },
        { -- 10: chair A
            coords    = vector3(1751.9766, 3629.827, 34.083138),
            heading   = 211.829,
            scenario  = 'PROP_HUMAN_SEAT_CHAIR',
        },
        { -- 11: chair B
            coords    = vector3(1752.84, 3630.2756, 34.083138),
            heading   = 211.829,
            scenario  = 'PROP_HUMAN_SEAT_CHAIR',
        },
    },

    -- ============================================================
    -- INTERACTION
    -- ox_target sphere zone radius around each seat
    -- ============================================================
    interactRadius = 1.2,

    -- ============================================================
    -- MESSAGES
    -- ============================================================
    messages = {
        sit       = 'Sit Down',
        getUp     = 'Get Up',
        getUpHint = 'Press [BACKSPACE] to get up',
        occupied  = 'This seat is taken.',
        blocked   = 'Cannot use this right now.',
    },
}
