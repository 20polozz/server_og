--[[
    ============================================================
    QUICK MENU SETTINGS
    ============================================================
    Configures the radial interaction menu used between gang
    members. Actions are executed server-side via QuickActions.
    Each action requires the corresponding gang rank permission.
    ============================================================
--]]

Config.QuickMenu = {
    -- Enable the quick interaction menu
    Enable = true,

    -- Sin tecla: el menu rapido de banda se abre SOLO desde el riel del
    -- inventario, para no tener dos formas de llegar al mismo sitio y una
    -- tecla ocupada de por vida. Si se le vuelve a poner un valor aqui,
    -- volvera a registrarse el atajo.
    Key = nil,

    -- Use a chat command instead of (or in addition to) a key
    UseCommand  = true,
    CommandName = 'quickmenu',

    -- Custom gate function: return true to allow the menu to open,
    -- return false + reason string to block it silently.
    canInteract = function(playerPed, targetPed)
        return true, nil
    end,

    -- ── ACTIONS ──────────────────────────────────────────────────────────────
    -- Each action requires 'requiredPermission' to be granted on the player's rank.
    -- 'canExecute' is a client-side gate called before sending the action to the server.
    -- 'onExecute' runs server-side via QuickActions.

    Actions = {
        {
            id                 = 'search',
            order              = 1,
            label              = 'quickmenu.actions.search.label',
            icon               = 'fa-solid fa-magnifying-glass',
            requiredPermission = 'quick_search',
            canExecute = function(playerPed, targetPed)
                return true, nil
            end,
            onExecute = function(src, targetId)
                QuickActions.Search(src, targetId)
            end,
        },
        {
            id                 = 'handcuff',
            order              = 2,
            label              = 'quickmenu.actions.handcuff.label',
            icon               = 'fa-solid fa-handcuffs',
            requiredPermission = 'quick_handcuff',
            canExecute = function(playerPed, targetPed)
                return true, nil
            end,
            onExecute = function(src, targetId)
                QuickActions.Handcuff(src, targetId)
            end,
        },
        {
            id                 = 'escort',
            order              = 3,
            label              = 'quickmenu.actions.escort.label',
            icon               = 'fa-solid fa-shoe-prints',
            requiredPermission = 'quick_handcuff',
            canExecute = function(playerPed, targetPed)
                return true, nil
            end,
            onExecute = function(src, targetId)
                QuickActions.Escort(src, targetId)
            end,
        },
        {
            id                 = 'put_in_vehicle',
            order              = 4,
            label              = 'quickmenu.actions.put_in_vehicle.label',
            icon               = 'fa-solid fa-car-side',
            requiredPermission = 'quick_vehicle',
            canExecute = function(playerPed, targetPed)
                return true, nil
            end,
            onExecute = function(src, targetId)
                QuickActions.PutInVehicle(src, targetId)
            end,
        },
        {
            id                 = 'take_out_vehicle',
            order              = 5,
            label              = 'quickmenu.actions.take_out_vehicle.label',
            icon               = 'fa-solid fa-person-walking-arrow-right',
            requiredPermission = 'quick_vehicle',
            canExecute = function(playerPed, targetPed)
                return true, nil
            end,
            onExecute = function(src, targetId)
                QuickActions.TakeOutVehicle(src, targetId)
            end,
        },
    },
}
