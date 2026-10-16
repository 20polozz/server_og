Config.Debug = false -- Set to true to enable debug messages in the console
Config.Language = 'es' -- Set the language of the resource
Config.PaymentMethod = 'bank' -- Set the account used for payments
Config.DepotPrice = 300 -- Sets the price that the user must pay when recovering a vehicle from the impound lot

Config.Permissions = { -- Permissions required to access the administration menu, leave the table empty to allow all players
    'god',
    'superadmin',
    'admin',
}

Config.GiveKeys = {
    interior = true,
    exterior = true
} -- Enable or disable the key system

Config.OpenAdministrationMenu = 'openadmin' -- Set the command to open the administration menu

Config.Keybinds = { -- Set the keybinds for various actions
    ['furniture'] = 'H',
    ['keysManagement'] = 'J'
}

Config.Columns = { -- Database mappings for different frameworks
    ['qb-core'] = {
        ['vehicles'] = 'player_vehicles',
        ['owner'] = 'citizenid',
        ['mods'] = 'mods',
        ['state'] = 'state',
        ['garage'] = 'garage',
    },
    ['qbx_core'] = {
        ['vehicles'] = 'player_vehicles',
        ['owner'] = 'citizenid',
        ['mods'] = 'mods',
        ['state'] = 'state',
        ['garage'] = 'garage',
    },
    ['esx'] = {
        ['vehicles'] = 'owned_vehicles',
        ['owner'] = 'owner',
        ['mods'] = 'vehicle',
        ['state'] = 'stored',
        ['garage'] = 'parking',
    },
    ['custom'] = {
        ['vehicles'] = '',
        ['owner'] = '',
        ['mods'] = '',
        ['state'] = '',
        ['garage'] = '',
    },
}

Config.VehicleStates = { -- States for vehicle storage
    OUT = 0,
    STORED = 1,
    IMPOUNDED = 2,
}

Config.Marker = { -- marcador de «dejar el vehículo»: rosa pegatina, quieto (ni bota ni gira)
    type = 36,
    color = {216, 27, 85, 210},
    size = vector3(0.3, 0.3, 0.3),
    coords = vector3(0.0, 0.0, 1.0),
    bobUpAndDown = false,
    faceCamera = true,
    rotate = false,
}