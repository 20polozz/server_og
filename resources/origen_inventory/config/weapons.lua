--[[
   ___       _                    ___                      _                   
  / _ \ _ __(_) __ _  ___ _ __   |_ _|_ ____   _____ _ __ | |_ ___  _ __ _   _ 
 | | | | '__| |/ _` |/ _ \ '_ \   | || '_ \ \ / / _ \ '_ \| __/ _ \| '__| | | |
 | |_| | |  | | (_| |  __/ | | |  | || | | \ V /  __/ | | | || (_) | |  | |_| |
  \___/|_|  |_|\__, |\___|_| |_| |___|_| |_|\_/ \___|_| |_|\__\___/|_|   \__, |
               |___/                                                     |___/ 
    Origen Inventory by Origen Network

    Note:
    . Add the weapons to this file and forget about adding them to other files.
    . This file is only for defining weapons and their properties.
    . You can also add custom weapons here.
    . If you want to add more items, please use config/items.lua

    Note 2:
    . When adding a weapon, this file has higher priority 
      than any other weapon lists (qb or Weapons.old) there is no need to add them anywhere else
      and will be automatically added as a usable item.
]]
return {
    Weapons = {
        WEAPON_PISTOL = {
            label = 'Pistola (9 mm)',
            description = "Pistola semiautomática de 9 mm.",
            type = 'Pistol',
            ammoname = 'pistol_ammo',
            damagereason = 'Disparo',
            weight = 500,
        },
        WEAPON_COMBATPISTOL = {
            label = 'Pistola de Combate',
            description = "Pistola de combate, ligera y fiable.",
            type = 'Pistol',
            ammoname = 'pistol_ammo',
            damagereason = 'Disparo',
            weight = 150,
        },
        WEAPON_BEANBAG = {
            label = 'Escopeta de Goma',
            description = "Escopeta de Goma",
            type = 'Shotgun',
            ammoname = 'ammo-beanbag',
            damagereason = 'Disparo',
            weight = 150,
        },
        WEAPON_DBSHOTGUN = {
            label = 'Escopeta de Caza',
            description = "Arma especializada para caza mayor.",
            type = 'Shotgun',
            ammoname = 'hunting_ammo',
            damagereason = 'Disparo',
            weight = 1000,
        },
        WEAPON_MUSKET = {
            label = 'Rifle de Caza',
            description = "Un disparo limpio deja la piel perfecta. Solo para zonas de caza.",
            type = 'Shotgun',
            ammoname = 'hunting_ammo',
            damagereason = 'Disparo',
            weight = 1200,
        },
        WEAPON_KATANA_2 = {
            label = 'Katana',
            description = "Arma blanca afilada.",
            type = 'weapon',
            ammoname = nil,
            damagereason = 'Cortado / Apuñalado',
            weight = 1000,
            image = 'weapon_katana_2.png',
            unique = true,
            useable = true
        }
    },

    --- WIP
    Components = {},
    Ammo = {
        ['pistol_ammo'] = {
			label = '9mm',
			weight = 7,
		},
        ['ammo-beanbag'] = {
            label = 'Balas de goma',
            weight = 7,
        },
        ['hunting_ammo'] = {
            label = 'Munición de Caza',
            weight = 5,
        },
    }
}