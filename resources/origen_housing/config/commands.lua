Config.Commands = {
    OpenAdminMenu = {
        enabled = true,
        cmd = 'housing',
    },

    --[[ Sin tecla. Traia la O de serie y el menu de propiedades se abria
         solo, en mitad de cualquier cosa. El comando /management sigue ahi, y
         quien la quiera puede ponersela a mano en los ajustes de FiveM
         --Teclado > FiveM--, que es donde ox_lib deja el atajo registrado
         aunque no traiga tecla por defecto. ]]
    OpenManagementMenu = {
        enabled = true,
        cmd = 'management',
    },

    OpenFurnitureMenu = {
        enabled = true,
        cmd = 'furniture',
        key = 'K',
    },
}