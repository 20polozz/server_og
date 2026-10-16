if Config.Language ~= 'en' then return end

Translations = {
    nui = {
        ['doorsManage'] = 'Door Management',
        ['createDoor'] = 'Create Door',
        ['search'] = 'Search...',
        ['name'] = 'Name',
        ['type'] = 'Type',
        ['state'] = 'State',
        ['actions'] = 'Actions',
        ['open'] = 'Open',
        ['closed'] = 'Closed',
        ['save'] = 'Save',
        ['accept'] = 'Accept',
        ['close'] = 'Close',
        ['distance'] = 'Distance',
        ['distancePlaceholder'] = 'Distance (0 - 100)',
        ['autolock'] = 'Autolock',
        ['autolockPlaceholder'] = 'Time to lock the door (Seconds)',
        ['groups'] = 'Groups',
        ['grade'] = 'Grade',
        ['add'] = 'Add',
        ['passcode'] = 'Passcode',
        ['passcodePlaceholder'] = 'Access code',
        ['automatic'] = 'Automatic',
        ['automaticDesc'] = 'It is an automatic door',
        ['double'] = 'Double',
        ['doubleDesc'] = 'It is a double door',
        ['lockpick'] = 'Lockpick',
        ['lockpickDesc'] = 'Enable lockpicking option',
        ['namePlaceholder'] = 'Door name',
        ['locked'] = 'Locked',
        ['lockedDesc'] = 'The door is locked by default after a restart?',
        ['groupNamePlaceholder'] = 'Group name',
        ['players'] = 'Players',
        ['id'] = 'ID',
        ['idPlaceholder'] = 'Player ID',
    },

    drawtext = {
        ['unlock'] = 'Unlock',
        ['lock'] = 'Lock',
    },

    general = {
        ['commandHelp'] = 'Open the admin menu (Admins only)',
        ['enterPasscode'] = 'Enter the passcode',
        ['passcode'] = 'Passcode',
    },

    logs = {
        ['doorsUsage'] = 'DOOR USAGE',
        ['doorsUsageDesc'] = 'Player **%s** has **%s** the door **%s**',
        ['createDoor'] = 'Create Door',
        ['createDoorDesc'] = 'Player **%s** has created the door **%s**',
        ['deleteDoor'] = 'Delete Door',
        ['doorsDeletedDesc'] = 'Player **%s** has deleted the door **%s**',
        ['loked'] = 'Locked',
        ['unlocked'] = 'Unlocked',
        ['lockpicked'] = 'Lockpicked',
    },

    puerta = {
        ['codigoIncorrecto'] = 'Wrong passcode',
        ['sinPermiso'] = 'You do not have access to this door',
        ['demasiadosIntentos'] = 'Too many attempts. Wait a minute',
    },

    ganzua = {
        ['exito'] = 'You picked the lock',
        ['fallo'] = 'You failed to pick the lock',
        ['rota'] = 'Your lockpick broke',
        ['espera'] = 'Wait a moment before trying again',
        ['bloqueada'] = 'Too many failed attempts on this lock. Try again later',
        ['sinMinijuego'] = 'No lockpick minigame available',
        ['lejos'] = 'You moved away from the door',
    },
}