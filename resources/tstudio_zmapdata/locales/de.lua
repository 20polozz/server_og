-- ============================================================================
--  Deutsche Texte für alle TStudio-Map-Systeme (Aufzüge, Autoaufzüge,
--  Aufzugsbedienfelder, Smart-Schalter, Sichtschutzglas, Tastenbelegung).
--  Aktivieren mit Config.Locale = "de" in config.lua.
--
--  ~INPUT_CONTEXT~ wird durch die Interaktionstaste des Spielers ersetzt und
--  darf überall im Satz stehen (am Anfang liest es sich am besten), z. B.
--  "Drücke ~INPUT_CONTEXT~, um den Aufzug zu benutzen". GTA-Farbcodes wie ~g~
--  werden im Hinweis unten am Bildschirm entfernt. %s füllt das Script aus
--  (z. B. den Etagennamen) - bitte stehen lassen. Fehlende Texte werden auf
--  Englisch angezeigt. Siehe locales/en.lua für die Anleitung zu weiteren Sprachen.
-- ============================================================================
TStudioLocales = TStudioLocales or {}

TStudioLocales["de"] = {
    -- Aufzüge
    ["elevator-help-notify"] = "~INPUT_CONTEXT~ Aufzug benutzen",
    ["floor-description"]    = "Ziel: %s",
    ["floor-number"]         = "Etage %s",
    ["menu-close"]           = "schließen",

    -- Autoaufzüge
    ["car-menu-title"]        = "Autoaufzug",
    ["car-menu-description"]  = "Fahrzeugtransport",
    ["car-floor-description"] = "Ziel: %s",
    ["car-help-notify"]       = "~INPUT_CONTEXT~ Autoaufzug benutzen",
    ["car-help-return"]       = "~INPUT_CONTEXT~ Zurückfahren",
    ["car-no-vehicle"]        = "Du brauchst ein Fahrzeug für diesen Aufzug",

    -- Smart-Schalter (Jalousien / Vorhänge)
    ["smart-switch-help-notify"]      = "~INPUT_CONTEXT~ Smart-Home-Steuerung",
    ["smart-switch-menu-title"]       = "Smart Home",
    ["smart-switch-menu-description"] = "Jalousiesteuerung",
    ["smart-switch-open-blinds"]      = "Jalousien öffnen",
    ["smart-switch-close-blinds"]     = "Jalousien schließen",

    -- Sichtschutzglas
    ["privacy-glass-help-notify"] = "~INPUT_CONTEXT~ Sichtschutzglas umschalten",

    -- Tastenbelegung (GTA-Einstellungen > Tastenbelegung > FiveM)
    ["keybind-elevators"]     = "TStudio Maps: Aufzüge",
    ["keybind-carElevators"]  = "TStudio Maps: Autoaufzüge",
    ["keybind-smartSwitches"] = "TStudio Maps: Smart-Schalter",
    ["keybind-privacyGlass"]  = "TStudio Maps: Sichtschutzglas",

    -- Aufzugsbedienfelder in der Spielwelt
    ["display-help-notify"]        = "~INPUT_CONTEXT~ Aufzugsbedienfeld benutzen",
    ["display-current-floor"]      = "Aktuelle Etage",
    ["display-select-floor"]       = "Etage wählen",
    ["display-select-destination"] = "Ziel wählen",
    ["display-cancel"]             = "Abbrechen",
    ["display-door-open"]          = "Öffnen",
    ["display-door-close"]         = "Schließen",
    ["display-travelling-to"]      = "Ziel: %s",
    ["display-doors-opening"]      = "Türen öffnen sich",
    ["display-ready"]              = "Bereit",
    ["display-in-transit"]         = "In Fahrt",
    ["display-arrived"]            = "Angekommen",
    ["display-welcome"]            = "Willkommen",
    ["display-floor-prefix"]       = "Etage",
    ["display-elevator"]           = "Aufzug",
    ["display-out-of-service"]     = "Außer Betrieb",
    ["display-online"]             = "Online",
    ["display-max-capacity"]       = "Max. Traglast",
    ["display-load"]               = "Last",
    ["display-elevator-status"]    = "Aufzugsstatus",
    ["display-stop"]               = "Halt",
    ["display-call-help"]          = "Hilfe",
    ["display-am"]                 = "AM",
    ["display-pm"]                 = "PM",
    ["display-days"]   = { "SO", "MO", "DI", "MI", "DO", "FR", "SA" },
    ["display-months"] = { "JAN", "FEB", "MÄR", "APR", "MAI", "JUN", "JUL", "AUG", "SEP", "OKT", "NOV", "DEZ" },
    ["display-clock-24h"]        = true,
    ["display-temperature-unit"] = "C",

    -- Übersetzungen von Etagen-/Zielnamen, die auf allen Maps gleich heißen.
    -- Map-spezifische Namen stehen im de-Block der jeweiligen elevators/<map>.lua.
    floors = {},
}
