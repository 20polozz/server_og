Config = {}

Config.Language = 'es' -- 'es' or 'en'
Config.UseIdentifier = 'license' -- 'license' or 'steam'

Config.DiscordRoles = {
    enable   = false,
    serverId = 'SERVER_ID',
}

-- Seed defaults — runtime config comes from DB after first run
Config.Vips = {
    ['bronce'] = { label = 'Bronce', priority = 100, points = 10, pointsSecondary = 0, roleID = '0' },
    ['plata']  = { label = 'Plata',  priority = 200, points = 20, pointsSecondary = 0, roleID = '0' },
    ['oro']    = { label = 'Oro',    priority = 300, points = 30, pointsSecondary = 0, roleID = '0' },
}

-- Internal resource currencies. The key is fixed (it maps to a column in origen_vip_wallets);
-- the label is what players see and can be renamed from the admin panel.
Config.Currencies = {
    coins = { label = 'XP' },
    xp    = { label = 'Farm XP' },
}

-- Default the VIP store charges with (independent from the paycheck). Products
-- can override it with their own per-currency prices from the admin panel.
Config.StorePayment = {
    target = 'currency', -- 'currency' (internal currency) or 'framework' (framework account)
    key    = 'coins',    -- a Config.Currencies key, or an account name ('bank' or 'cash')
}

-- Seed defaults for paycheck system (if no settings are found in the database)
Config.PaycheckSystem = {
    enable         = false,
    interval       = 1, -- minutes
    paidWithoutVip = false,
    payouts = {
        {
            enable       = true,
            target       = 'currency', -- 'currency' or 'framework'
            key          = 'xp',       -- a Config.Currencies key, or an account name
            source       = 'points',   -- 'points' or 'pointsSecondary' from the VIP type
            nonVipAmount = 5,
        },
        {
            enable       = false,
            target       = 'framework',
            key          = 'bank',
            source       = 'pointsSecondary',
            nonVipAmount = 500,
        },
    },
}

Config.StoreEnabled = false -- Enable/disable the VIP store (managed from admin panel)

-- Public Tebex storefront. Leave empty to hide the web store block in the NUI.
Config.TebexUrl = 'https://nacion.tebex.io/'

-- Featured row on the store home. It shows the products added within
-- `NewProductDays`; only when no new product is left does it fall back to the
-- most purchased ones. The "Novedades" sidebar entry follows the same window and
-- disappears with it, so that section never shows anything that is not new.
Config.NewProductDays = 7 -- days a product counts as new; 0 disables the section
Config.FeaturedCount  = 3 -- products shown in the featured row

-- Fallback ranking, used only while there is no new product. The limit is bench
-- depth, not what is displayed: the row drops sold out and otherwise unavailable
-- products, so asking for exactly `FeaturedCount` would leave holes in it.
Config.FeaturedDays      = 7  -- days of purchase history the ranking looks at
Config.FeaturedRankLimit = 10 -- products the ranking returns

-- Test drive for store vehicles. Each product decides from the admin panel whether
-- it can be tried; this block only says where and for how long.
Config.TestDrive = {
    enabled  = true,
    duration = 5,       -- minutes
    plate    = 'VIPTEST',
    fallback = 'land',  -- spawn group used when no group claims the vehicle class

    -- The group is picked from the native GTA vehicle class of the model:
    -- 8 motorcycles, 13 cycles, 14 boats, 15 helicopters, 16 planes, 21 trains.
    -- Add your own groups freely; a class listed nowhere falls back to the group
    -- named above.
    spawns = {
        land  = { classes = {},     coords = vec4(-32.176, -1682.479, 29.398, 124.72) },
        boat  = { classes = { 14 }, coords = vec4(-772.66, -1497.83, 0.94, 108.34) },
        heli  = { classes = { 15 }, coords = vec4(-741.34, -1467.15, 5.00, 138.02) },
        plane = { classes = { 16 }, coords = vec4(-1657.99, -3140.87, 13.99, 330.15) },
    },
}

-- Recurring store products. The charge is a debit of an internal currency, so it
-- also runs while the player is offline; the delivery waits until they connect.
Config.Subscriptions = {
    enable = true,

    tickSeconds = 60,   -- how often the scheduler looks for due subscriptions
    batchSize   = 50,   -- rows processed per tick, oldest due first

    -- A claimed row whose process died is picked up again after this long.
    leaseSeconds = 300,

    -- Queued deliveries wait this long after the player connects, so the
    -- inventory and the framework finish loading first.
    deliveryDelayMs      = 5000,
    deliveryMaxAttempts  = 5,

    -- A failed delivery does NOT refund the cycle: a renewal is a recurring
    -- benefit, and refunding every failure turns a broken delivery into free coins.
    refundOnDeliveryFailure = false,

    -- The VIP cleanup deletes expired VIPs every 12 h. Re-checking the purchase
    -- gates on renewal would silently kill the subscription of anyone whose VIP
    -- lapsed for a few hours, so a renewal only checks state and funds.
    cancelWhenVipLost = false,

    -- Set above 0 to bill in SECONDS instead of days. Testing only: a 30 day
    -- cycle is otherwise impossible to exercise.
    debugIntervalSeconds = 0,

    webhook = {
        maxRetries     = 3,
        retryDelaysMs  = { 2000, 10000, 60000 },
        minSpacingMs   = 250,  -- per URL, to stay under the Discord rate limit
        maxQueue       = 200,
        notifyEveryRetry = false,
    },
}

Config.GroupPermissions = { 'admin' }

-- Custom actions: the events and exports the panel is allowed to fire when it
-- delivers a `custom` store product or a `custom` raffle prize.
Config.CustomActions = {
    -- An empty list allows everything, since the panel is staff-only already.
    -- With at least one entry the list turns strict: nothing that fails to match
    -- runs. '*' is a wildcard and a missing key accepts any value.
    --   { resource = 'murderface-pets', name = 'GivePet' }
    --   { resource = 'murderface-pets', name = '*' }      -- the whole resource
    --   { kind = 'serverEvent', name = 'my_script:*' }
    allowlist = {},

    -- Recursos retirados → quien hace ahora su trabajo. murderface-pets se
    -- quitó el 13/10: los 24 productos de mascota de Nación llaman a su
    -- `GivePet`, que ahora contesta origen_pets (server/migrar.lua).
    alias = { ['murderface-pets'] = 'origen_pets' },

    -- Commands run with console (rcon) privileges. Turn this off if unused.
    allowCommands = true,

    -- false leaves an unknown placeholder as literal text; true cancels the
    -- delivery before anything runs.
    strictPlaceholders = false,

    -- Refund the payment, drop the purchase row and restore the stock when a
    -- delivery fails. Only an explicit `false` from the hook counts as failure.
    rollbackOnFailure = true,
}

Config.Commands = {
    ['open_user_menu'] = 'vip',
    ['open_vip_menu']  = 'vipmenu',
}

-- Turn this off if you open the user panel from your own menu with the
-- client export `openUserMenu`. The admin command is not affected.
Config.EnableUserCommand = false


BridgeConfig = BridgeConfig or {
    Notify = 'auto',
    Debug = {
        enabled = false,
    },
    Database = {
        SqlFile = 'origen_vipsystem.sql',
        -- Both flags are DESTRUCTIVE: they drop objects the .sql no longer declares
        -- and NULL out orphan foreign-key values. Leave them off unless you know why.
        DropExtra = false,
        CleanupOrphans = false,
    },
}
