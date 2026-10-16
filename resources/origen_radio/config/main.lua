-- FRAMEWORK CONFIG
Config = {}
Config.Framework = GetResourceState("qb-core") == "started" and "qbcore" or GetResourceState("es_extended") == "started" and "esx" or "none"
Config.Inventory = "origen_inventory" -- origen_inventory | old_origen_inventory | qb-inventory | qs-inventory | ox_inventory | ls-inventory | codem-inventory
Config.PermissionsGroups = {
    "mod" -- list of groups that will have all permissions, like "mod", "admin", "superadmin", etc
}
Config.Debug = false -- If you want to enable the debug mode
Config.Language = "es" -- en | es or you cant add your own language in locales.lua
Config.MetadataSystem = false -- If you want to use a custom metadata system
Config.CustomReviveEvent = "" -- The client event that will be triggered when the player is revived, if you are using a custom EMS script
Config.BindSystem = false -- If you want to use the keybinds system
Config.KeepInputOnNUI = false -- If you want to make able to move while the NUI is open
Config.HideWeaponOnTalk = false -- If you want to hide the weapon when the player is talking on the radio
Config.NeedRadioItem = true -- If you want to make the radio item required to open the radio interface
Config.RadioItems = { -- The items that the use will open the radio
    "radio",
}

-- RADIO CONFIG

RadioConfig = {}

RadioConfig.DefaultKey = "LMENU"
RadioConfig.DefaultBroadcastKey = "COMMA"
RadioConfig.DefaultOpenRadioKey = "Z"

-- Custom Frequencies Limit
RadioConfig.MaxCustomFrequencies = 5 -- Maximum number of custom frequencies each player can create

-- Speaker System
RadioConfig.Speaker = {
    Enabled = true,              -- Enable/disable speaker system
    Distance = 5.0,              -- Distance in meters (people nearby will hear you)
    ShowInWidget = true          -- Show speaker icon in widget
}

RadioConfig.Anims = {
    { Dict = "random@arrests", Anim = "generic_radio_chatter" },
    {
        Dict = "cellphone@str",
        Anim = "cellphone_call_listen_a",
        Prop = "prop_cs_hand_radio",
        PropBone = 57005,
        PropPlacement = {
            0.12,
            0.02,
            -0.02,
            20.0,
            70.0,
            130.0
        },
    },
    {
        Dict = "anim@male@holding_radio",
        Anim = "holding_radio_clip",
        Prop = "prop_cs_hand_radio",
        PropBone = 28422,
        PropPlacement = {
            0.0750,
            0.0230,
            -0.0230,
            -90.0000,
            0.0,
            -59.9999
        },
    },
}

if Config.Debug then
    function Debuger(...)
        print ('[^5Origen Radio^0]', ...)
    end
else
    Debuger = function() end
end