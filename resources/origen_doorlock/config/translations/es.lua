if Config.Language ~= 'es' then return end

Translations = {
    nui = {
        ['doorsManage'] = 'Gestión de puertas',
        ['createDoor'] = 'Crear Puerta',
        ['search'] = 'Buscar...',
        ['name'] = 'Nombre',
        ['type'] = 'Tipo',
        ['state'] = 'Estado',
        ['actions'] = 'Acciones',
        ['open'] = 'Abierto',
        ['closed'] = 'Cerrado',
        ['save'] = 'Guardar',
        ['accept'] = 'Aceptar',
        ['close'] = 'Cerrar',
        ['distance'] = 'Distancia',
        ['distancePlaceholder'] = 'Distancia (0 - 100)',
        ['autolock'] = 'Autocierre',
        ['autolockPlaceholder'] = 'Tiempo para bloquear la puerta (segundos)',
        ['groups'] = 'Grupos',
        ['grade'] = 'Grado',
        ['add'] = 'Añadir',
        ['passcode'] = 'Código de acceso',
        ['passcodePlaceholder'] = 'Código de acceso',
        ['automatic'] = 'Automático',
        ['automaticDesc'] = 'Es una puerta automática',
        ['double'] = 'Doble',
        ['doubleDesc'] = 'Es una puerta doble',
        ['lockpick'] = 'Ganzuado',
        ['lockpickDesc'] = 'Habilitar la opción de ganzuado',
        ['namePlaceholder'] = 'Nombre de la puerta',
        ['locked'] = 'Bloqueado',
        ['lockedDesc'] = 'La puerta está bloqueada por defecto tras un reinicio',
        ['groupNamePlaceholder'] = 'Nombre del grupo',
        ['players'] = 'Jugadores',
        ['id'] = 'ID',
        ['idPlaceholder'] = 'ID del jugador',
    },

    drawtext = {
        ['unlock'] = 'Desbloquear',
        ['lock'] = 'Bloquear',
    },

    general = {
        ['commandHelp'] = 'Abre el menú de administración (Sólo administradores)',
        ['enterPasscode'] = 'Introduce el código de acceso',
        ['passcode'] = 'Código de acceso',
    },

    logs = {
        ['doorsUsage'] = 'USO DE PUERTAS',
        ['doorsUsageDesc'] = 'El jugador **%s** ha **%s** la puerta **%s**',
        ['createDoor'] = 'Crear Puerta',
        ['createDoorDesc'] = 'El jugador **%s** ha creado la puerta **%s**',
        ['deleteDoor'] = 'Borrar Puerta',
        ['doorsDeletedDesc'] = 'El jugador **%s** ha borrado la puerta **%s**',
        ['loked'] = 'Bloqueado',
        ['unlocked'] = 'Desbloqueado',
        ['lockpicked'] = 'Ganzuado',
    },

    puerta = {
        ['codigoIncorrecto'] = 'Código incorrecto',
        ['sinPermiso'] = 'No tienes acceso a esta puerta',
        ['demasiadosIntentos'] = 'Demasiados intentos. Espera un minuto',
    },

    ganzua = {
        ['exito'] = 'Has forzado la cerradura',
        ['fallo'] = 'No has conseguido forzar la cerradura',
        ['rota'] = 'La ganzúa se ha roto',
        ['espera'] = 'Espera un momento antes de volver a intentarlo',
        ['bloqueada'] = 'Has fallado demasiadas veces con esta cerradura. Prueba más tarde',
        ['sinMinijuego'] = 'No hay minijuego de ganzúa disponible',
        ['lejos'] = 'Te has alejado de la puerta',
    },
}