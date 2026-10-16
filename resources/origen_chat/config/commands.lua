Config.Commands = {
    ['me'] = {
        enabled = true,
        color = '#f9f1a5',
        icon = 'lucide:user',
        preventCollisions = true,
        distance = 15.0,
        command = 'me',
        channel = 'rol', -- Pestaña del centro de chat: rol, ooc, aviso o sistema.
        params = {},
        showNameInsteadOfId = false,
        type = 'proximity',
    },

    ['do'] = {
        enabled = true,
        color = '#d9173e',
        icon = 'lucide:cloudy',
        preventCollisions = true,
        distance = 10.0,
        command = 'do',
        channel = 'rol', -- Pestaña del centro de chat: rol, ooc, aviso o sistema.
        showNameInsteadOfId = false,
        type = 'proximity',
    },

    ['ooc'] = {
        enabled = true,
        color = '#949494',
        icon = 'lucide:radar',
        preventCollisions = false,
        distance = 10.0,
        command = 'ooc',
        channel = 'ooc', -- Pestaña del centro de chat: rol, ooc, aviso o sistema.
        showNameInsteadOfId = false,
        type = 'proximity',
    },

    ['msg'] = {
        enabled = true,
        color = '#8217d9',
        icon = 'lucide:users',
        preventCollisions = false,
        distance = false,
        command = 'msg',
        channel = 'ooc', -- Pestaña del centro de chat: rol, ooc, aviso o sistema.
        showNameInsteadOfId = false,
        type = 'player-to-player',
    },

    ['announcement'] = {
        enabled = true,
        color = '#ffffff',
        icon = 'lucide:megaphone',
        command = 'announcement',
        channel = 'sistema', -- Pestaña del centro de chat: rol, ooc, aviso o sistema.
        permissions = {
            'admin',
        },
        type = 'global-announcement',
    },

    ['lspd'] = {
        enabled = false,
        color = '#173ed9',
        icon = 'lucide:building',
        command = 'lspd',
        channel = 'sistema', -- Pestaña del centro de chat: rol, ooc, aviso o sistema.
        groups = {
            ['police'] = 5,
        },
        showGradeAndJob = true,
        type = 'job-to-job',
    },

    ['ems'] = {
        enabled = false,
        color = '#d91717',
        icon = 'lucide:ambulance',
        command = 'ems',
        channel = 'sistema', -- Pestaña del centro de chat: rol, ooc, aviso o sistema.
        groups = {
            ['ambulance'] = 0,
        },
        showGradeAndJob = true,
        type = 'job-to-job',
    },

    ['announce-lspd'] = {
        enabled = false,
        color = '#173ed9',
        icon = 'lucide:building',
        command = 'announce-lspd',
        channel = 'sistema', -- Pestaña del centro de chat: rol, ooc, aviso o sistema.
        groups = {
            ['police'] = 4,
        },
        type = 'job-to-global',
    },

    ['announce-ems'] = {
        enabled = false,
        color = '#d91717',
        icon = 'lucide:ambulance',
        command = 'announce-ems',
        channel = 'sistema', -- Pestaña del centro de chat: rol, ooc, aviso o sistema.
        groups = {
            ['ambulance'] = 0,
        },
        type = 'job-to-global',
    },

    ['custom_command'] = {
        enabled = false, -- If true, the command will be enabled.
        color = '#ffffff', -- Color to use for the command.
        icon = 'lucide:user', -- Icon to use for the command.
        preventCollisions = true, -- If true, players who are blocked by a collision will not receive the message, e.g. walls, doors, etc...
        distance = 15.0, -- Distance at which players will receive the message, if false, the message will be sent to all players.
        command = 'custom_command', -- Command to use to send the message.
        channel = 'rol', -- Pestaña del centro de chat: rol, ooc, aviso o sistema.
        params = {}, -- Parameters to use to send the message.
        showNameInsteadOfId = true, -- If true, the command will show the player's name instead of their ID.
        permissions = { -- Permissions to use to send the message.
            'group.mod',
            'group.admin',
        },
        groups = { -- Jobs to use to send the message (job_name = job_grade). 
            ['job_name'] = 0,
            ['job_name2'] = 0,
        },
        type = 'proximity', -- Type of command to use (proximity, global, player-to-player, global-announcement, job-to-job, job-to-global).
    },

    ['dados'] = {
        enabled = true,
        color = '#2af5f5ff',
        icon = 'lucide:dice-5', 
        preventCollisions = true,
        distance = 15.0,
        command = 'dados',
        channel = 'rol', -- Pestaña del centro de chat: rol, ooc, aviso o sistema.
        showNameInsteadOfId = false,
        type = 'dice',
    },

    ['suerte'] = {
        enabled = true,
        color = '#30ff1dff',
        icon = 'lucide:clover',
        preventCollisions = true,
        distance = 15.0,
        command = 'suerte',
        channel = 'rol', -- Pestaña del centro de chat: rol, ooc, aviso o sistema.
        showNameInsteadOfId = false,
        type = 'luck',
    }
}
