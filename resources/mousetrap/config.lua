Config = {}

--'ESX', 'QBCore', 'QBox'
Config.Framework = 'QBCore'

Config.NotificationSystem = 'qbcore' -- 'esx' 'qbcore' 'qbox'

Config.Commands = {
    mousetrapempty = {
        name = "mousetrapempty",
        description = "Alternar decoración vacía del Mousetrap",
        enabled = false, -- true = command enabled, false = command disabled
        restrictionType = false, -- false = everyone can use | ‘job’ = only specific jobs | ‘gang’ = only specific gangs
        allowedList = {} -- List of permitted jobs/gangs, e.g.: {‘police’, ‘mechanic’} or {‘ballas’, ‘vagos’}
    },
    mousetrapheist = {
        name = "mousetrapheist", 
        description = "Alternate Mousetrap Heist Decorations",
        enabled = true,
        restrictionType = false,
        allowedList = {}
    },
    mousetrapshowcase = {
        name = "mousetrapshowcase",
        description = "Alternate Mousetrap Showcase Decorations",
        enabled = true,
        restrictionType = false,
        allowedList = {}
    },
    mousetrapparty = {
        name = "mousetrapparty",
        description = "Alternate Mousetrap Party Decorations",
        enabled = true,
        restrictionType = false,
        allowedList = {}
    },
    mousetrapramp = {
        name = "mousetrapramp",
        description = "Alternate position of the Mousetrap ramp",
        enabled = true,
        restrictionType = false,
        allowedList = {}
    }
}

Config.Messages = {
    noPermission = "You do not have permission to use this command.",
    commandDisabled = "This command is disabled."
}