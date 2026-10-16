--[[
    ============================================================
    COMMANDS SETTINGS
    ============================================================
    Defines the chat commands available in the resource.
    'restricted = true' requires the permission defined in
    'permission' to execute (checked via ACE/framework perms).
    ============================================================
--]]

Config.Commands = {
    Gang = {
        name       = 'gangorg',
        help       = 'commands.gang.help',
        restricted = false,
    },
    CreateGang = {
        name       = 'creategang',
        help       = 'commands.creategang.help',
        restricted = false,
    },
    DeleteGang = {
        name       = 'deletegang',
        help       = 'commands.deletegang.help',
        restricted = true,
        permission = 'admin',
    },
    GangInfo = {
        name       = 'ganginfo',
        help       = 'commands.ganginfo.help',
        restricted = false,
    },
}
