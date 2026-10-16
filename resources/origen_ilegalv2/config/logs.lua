--[[
    ============================================================
    LOGS SETTINGS
    ============================================================
    Configures in-game activity logging and optional Discord
    webhook notifications for gang events.
    ============================================================
--]]

Config.Logs = {
    -- Enable the activity log system
    Enable = true,

    -- Maximum number of log entries to store per gang
    MaxLogs = 100,

    -- Optional Discord webhook for external log delivery
    Discord = {
        Enable  = false,
        Webhook = '',
        Color   = 15158332, -- Embed color (red by default)
        Name    = 'Gang System',
        Logo    = '',
    },
}
