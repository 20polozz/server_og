-- ============================================================================
--  English texts for all TStudio map systems (elevators, car elevators,
--  elevator panels, smart switches, privacy glass, key bindings).
--
--  ADD A LANGUAGE: copy this file to locales/<code>.lua (e.g. fr.lua), change
--  TStudioLocales["en"] below to TStudioLocales["fr"], translate the texts and
--  set Config.Locale = "fr" in config.lua. Anything you leave out shows in
--  English, so nothing ever disappears. Also add your language to map blocks
--  that override texts (e.g. the Vinewood Residence curtains in
--  Config.SmartSwitches), otherwise that map shows the texts of this file.
--
--  ~INPUT_CONTEXT~ is replaced with the player's interact key and may stand
--  anywhere in the text (at the start reads best). GTA colour codes like ~g~
--  are removed from the bottom-screen prompt.
--  %s is filled in by the script (a floor name, a destination...). Keep it.
--
--  A single map can override texts for itself in its own `locales` block:
--  elevator, car elevator and panel (display-*) texts in elevators/<map>.lua,
--  smart-switch texts in Config.SmartSwitches, the privacy glass prompt in
--  Config.PrivacySwitches. menu-close and keybind-* are server-wide.
-- ============================================================================
TStudioLocales = TStudioLocales or {}

TStudioLocales["en"] = {
    -- Elevators
    ["elevator-help-notify"] = "~INPUT_CONTEXT~ Open Elevator",
    ["floor-description"]    = "Teleport to %s",
    ["floor-number"]         = "Floor %s", -- other languages turn floors named "Floor 1", "Floor 2"... into this (English names stay as written)
    ["menu-close"]           = "close",    -- hint next to ESC at the bottom of every menu

    -- Car elevators
    ["car-menu-title"]        = "Car Elevator",
    ["car-menu-description"]  = "Vehicle Transport",
    ["car-floor-description"] = "Drive to %s",
    ["car-help-notify"]       = "~INPUT_CONTEXT~ Use Car Elevator",
    ["car-help-return"]       = "~INPUT_CONTEXT~ Drive Back",
    ["car-no-vehicle"]        = "You need a vehicle to use this elevator",

    -- Smart switches (blinds / curtains)
    ["smart-switch-help-notify"]      = "~INPUT_CONTEXT~ Smart Home Controls",
    ["smart-switch-menu-title"]       = "Smart Home",
    ["smart-switch-menu-description"] = "Blind Controls",
    ["smart-switch-open-blinds"]      = "Open Blinds",
    ["smart-switch-close-blinds"]     = "Close Blinds",

    -- Privacy glass
    ["privacy-glass-help-notify"] = "~INPUT_CONTEXT~ Toggle Privacy Glass",

    -- Key binding names (GTA Settings > Key Bindings > FiveM)
    ["keybind-elevators"]     = "TStudio Maps: Elevators",
    ["keybind-carElevators"]  = "TStudio Maps: Car Elevators",
    ["keybind-smartSwitches"] = "TStudio Maps: Smart Switches",
    ["keybind-privacyGlass"]  = "TStudio Maps: Privacy Glass",

    -- In-world elevator panels
    ["display-help-notify"]        = "~INPUT_CONTEXT~ Use Elevator Panel",
    ["display-current-floor"]      = "Current Floor",
    ["display-select-floor"]       = "Select your floor",
    ["display-select-destination"] = "Select Destination",
    ["display-cancel"]             = "Cancel",
    ["display-door-open"]          = "Open",
    ["display-door-close"]         = "Close",
    ["display-travelling-to"]      = "Traveling to %s",
    ["display-doors-opening"]      = "Doors opening",
    ["display-ready"]              = "Ready",
    ["display-in-transit"]         = "In Transit",
    ["display-arrived"]            = "Arrived",
    ["display-welcome"]            = "Welcome",
    ["display-floor-prefix"]       = "Floor",
    ["display-elevator"]           = "Elevator",
    ["display-out-of-service"]     = "Out of service",
    ["display-online"]             = "Online",
    ["display-max-capacity"]       = "Max Capacity",
    ["display-load"]               = "Load",
    ["display-elevator-status"]    = "Elevator Status",
    ["display-stop"]               = "Stop",
    ["display-call-help"]          = "Help",
    ["display-am"]                 = "AM",
    ["display-pm"]                 = "PM",
    ["display-days"]   = { "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT" },
    ["display-months"] = { "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" },
    ["display-clock-24h"]        = false, -- true = 21:30, false = 9:30 PM
    ["display-temperature-unit"] = "F",   -- "C" or "F" (a map's display.temperatureUnit wins)

    -- Optional translations of floor / destination names, e.g.
    -- floors = { ["Rooftop"] = "Toit" }  (left: the English name from
    -- elevators/*.lua, right: your translation). Maps can add their own too.
    floors = {},
}
