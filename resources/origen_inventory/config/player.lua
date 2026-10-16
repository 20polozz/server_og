Config = Config or {}
-----------------------------------------
------------  Player  -------------------
-----------------------------------------
Config.Player = {}

-- The distance to give items to another player
Config.Player.GiveDistance = 3.5

--- The distance to view drop marker
Config.Player.DropMarkerDistance = 3.0

---- Set Max Weight of player inventory
Config.Player.MaxWeight = 120000

-- Set Max Slots of player inventory
Config.Player.MaxInventorySlots = 40

-- Set the save interval of player inventory
--- Los guardados no forzados se aplazan este rato. Con 40 minutos, todo lo que
--- pasara entre medias dependia del guardado forzado al desconectar o al parar
--- el recurso; si el servidor se caia o se cerraba sin txAdmin, se perdia entero.
Config.Player.SaveInterval = 5 -- minutes

-- Set the timeout of player when open a shop
Config.Player.ShopTimeout = 2 -- secconds


-------------------------------------------------
------------  Player Cheat Protections  ---------
-------------------------------------------------
-- [[ Note: This protection ignore admins for Bridge.IsAdmin ]]
Config.Player.CheatProtect = {}
Config.Player.CheatProtect.Enable = true
Config.Player.CheatProtect.MaxDistanceRemoteOpen = 10.0

--- Security Checks --------------------------------
--- Some third party resources deliver weapons directly to the player without going through the inventory,
--- this will cause the weapon to be deleted immediately, disable it if you do not want this.
Config.Player.CheatProtect.EnableNoItemWeapons = true

-------------------------------------------------
------------  Player Clothes As Item  -------------
-------------------------------------------------
Config.Player.ClothesAsItem = {}

--- Enable / Disable Clothes As Item system (CAI)
--- NOTE: Requiere origen_clothing resource to work properly
Config.Player.ClothesAsItem.Enable = false

-------------------------------------------------
------------  Player Money As Item  -------------
-------------------------------------------------
Config.Player.MoneyAsItem = {}

--- Enable / Disable Money As Item system (MAI)
Config.Player.MoneyAsItem.Enable = true


--- Note: This item is automatically created, you don't need to create it manually.
Config.Player.MoneyAsItem.Accounts = {
    --['itemName'] = itemData
    [DetectMoneyOrCash()] = {
        account = DetectMoneyOrCash(),
        label = 'Dinero',
        description = 'El mundo gira a su alrededor',
        weight = 0,
    },
    -- black_money = {
    --     account = 'black_money',
    --     label = 'Black Money',
    --     description = 'Black Money',
    --     weight = 0,
    -- }
}

-----------------------------------------
------------------- UI ------------------
-----------------------------------------
Config.UI = {
    Mini = true, -- Mini UI, only show second inventory if exist, else show main inventory
    ShowPlayerNameOnGiveItem = true,
    Hotbar = false, -- 07/10: no se usa (el usuario la quitó)
    ShowCraftingIndicator = true,
    PlayerInventoryLabel = 'Inventario',
    Color = 'default',
    DelayNuiFocusForTabKey = false, -- Delay NUI Focus when pressing TAB key (fix some input issues)

    -- Allow toggle tabs in inventory UI
    EnableTabs = {
        personal = {
            -- Enable / Disable personal inventory tabs
            enable = true,
            --------
            clothes = true,

            --- Enable / Disable Actions Modules
            enableActions = true,
            --------
            
            actions = {
                toggleWeapon = true,
                toggleHair = true,
                searchPlayer = true,
                carry = true,
                piggyback = true,
                putInVehicle = true,
                rockstarEditor = true
            }
        },
        settings = {
            -- Enable / Disable settings tab
            enable = true,
            --------
            
            keybinds = true,
            appearance = true
        },
        vehicle = {
            -- Enable / Disable vehicle inventory tab
            enable = true,
            --------
        },
        keys = {
            -- Enable / Disable vehicle keys tab
            enable = true,
            --------
        }
    }
}

--- Note: This control will only work the first time a player logs in, if changed later the player will need to change it manually from the game settings.
Config.DefaultOpenKey = "F2"
Config.HotbarOpenKey = "TAB" -- Only works if Config.UI.Hotbar is true

----------------------------------------
----- INVENTORY CUSTOMIZATION ----------
----------------------------------------

-- Disable Escape key when inventory is opens
Config.DisableEscOnInventoryOpen = true -- When inventory is open disable ESCAPE key.

--- Enable / Disable Player interaction (movements) when UI is open.
--- Note: This will prevent players from moving when the UI is open.
Config.DisableMovementOnInventoryOpen = false

--- Enable / Disable P (Map Key)
Config.DisablePKey = true

-- Notify players when exports (giveItem or removeItem) are used
Config.NotifyExports = {
    GiveItem = true,   -- Notify when giveItem is used
    RemoveItem = true, -- Notify when removeItem is used
}


---------------------------------------
---------- Carry & Piggyback ----------
---------------------------------------
--- Enable / Disable Carry & Piggyback system

Config.Animations = {}
Config.Animations.Carry = {
    anims = {
        me = { dict = 'missfinale_c2mcs_1', clip = 'fin_c2_mcs_1_camman', flag = 49 },
        target = { dict = 'nm', clip = 'firemans_carry', flag = 33, attach = { x = 0.27, y = 0.15, z = 0.63 } }
    },
}


Config.Animations.Piggyback = {
    anims = {
        me = { dict = 'anim@arena@celeb@flat@paired@no_props@', clip = 'piggyback_c_player_a', flag = 49 },
        target = { dict = 'anim@arena@celeb@flat@paired@no_props@', clip = 'piggyback_c_player_b', flag = 33, attach = { x = 0.0, y = -0.07, z = 0.45 } }
    },
}
