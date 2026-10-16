Config.EnableAnimations = true -- Enable/Disable all animated props
Config.EnablePlayerAnimations = true -- Enable/Disable player interaction animations
Config.Debug = false -- Enable/Disable debug messages in console
Config.UseOxTarget = true -- Use ox_target for interactions (if available)
Config.AutoOpen = true                  -- Enable auto-open for all garage rollup doors
Config.AutoOpenDefaultLocked = true     -- true = doors start locked on server start, false = doors start unlocked
Config.AutoOpenCloseDelay = 3000        -- ms delay before auto-close after last player exits zone

--[[
    PERMISSIONS SYSTEM
    Set Config.Permissions.enabled = true to enable job-based restrictions
    Then configure allowedJobs on each prop in config.lua
]]
Config.Permissions = {
    enabled = false, -- Set to true to enable job restrictions
    
    -- Framework detection: 'auto', 'qb', 'qbox', 'esx', 'standalone'
    -- 'auto' will try to detect your framework automatically
    framework = 'auto',
    
    -- If you want to use ACE permissions instead of jobs, set this to true
    -- Then set acePermission on each prop (e.g. acePermission = "compound.lift")
    useAce = false,
    
    -- Default message when player doesn't have access
    noAccessMessage = "You don't have access to this"
}

Config.Messages = {
    interactButton = "Interact",
    noAccess = "You don't have access to this object",
    alreadyInUse = "This object is already in use",
    menuTitle = "Animated Objects",
    testAllAnimations = "Test all animations",
    open = "Open",
    close = "Close",
    lock = "Lock",
    unlock = "Unlock",
    locked = "Locked",
    unlocked = "Unlocked",
}

--[[
    AUTO-OPEN SYSTEM
    When enabled, garage rollup doors auto-open when a player enters their
    interaction zone and auto-close when all players leave.
    The ox_target/E-key interaction changes from open/close to lock/unlock.
    Lifts are never affected by this setting.
]]
