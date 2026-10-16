fx_version "bodacious"

game "gta5"

author "OrigenNetwork"

version "2.9.1"

shared_scripts {
    "@ox_lib/init.lua",
    "config/_framework.lua",
    "config/police-stations/loader.lua",
    "config/translations/*.lua",
    "config/translations/overrides/*.lua",
    "config/*.lua",
    "radio/config.lua",
    "custom/shared/*.lua",
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    "utils/*.lua",
    "hooks/client.lua",
    "custom/framework/client/*.lua",
    "custom/client/admin.lua",
    "custom/client/robberies.lua",
    "custom/client/actions.lua",
    "custom/client/announcements.lua",
    "custom/client/rrpp.lua",
    "custom/client/rtd.lua",
    "custom/client/discord_sync.lua",
    "custom/client/clothing.lua",
    "custom/client/evidences.lua",
    "custom/client/commands.lua",
    "custom/client/federal.lua",
    "custom/client/inventory.lua",
    "custom/client/menu.lua",
    "custom/client/rpol.lua",
    "custom/client/vehicles.lua",
    "custom/client/voice.lua",
    "custom/client/client_pay_bills.lua",
    "custom/client/callouts.lua",
    "custom/client/acceso_inventario.lua",
    "custom/client/sea.lua",
    "custom/client/citations.lua",
    "client/handlers/*.lua",
    "client/init.lua",
    "client/menu/*.lua",
    "client/*.lua",
    "radio/client/**/*.lua",
}

server_scripts {
    "hooks/server.lua",
    "utils/FileManager.js",
    "custom/framework/server/*.lua",
    "custom/server/database.lua",
    "server/middlewares/*.lua",
    "config/logs/logs.lua",
    "custom/server/announcements.lua",
    "custom/server/rrpp.lua",
    "custom/server/rtd.lua",
    "custom/server/discord_sync.lua",
    "custom/server/ban.lua",
    "custom/server/bills.lua",
    "custom/server/inventory.lua",
    "custom/server/rpol.lua",
    "custom/server/society.lua",
    "custom/server/vehicles.lua",
    "custom/server/menu/structureManager.lua",
    "custom/server/menu/*.lua",
    "custom/server/federal.lua",
    "custom/server/callouts.lua",
    "custom/server/sea.lua",
    "custom/server/citations.lua",
    "custom/server/business_accounts.lua",
    "custom/server/duty.lua",
    "server/init.lua",
    "server/*.lua",
    "server/menu/*.lua",

    "radio/server/**/*.lua",
}

-- MDT en Vue: el codigo vive en ui/ y compila a html/mdt (`npx vite build` en ui/).
-- El panel de admin vive en admin-ui/ y compila a html/admin-dist.
ui_page 'html/mdt/index.html'

files {
    "config/quickmenu-references.json",
    "config/police-stations/*.json",
    'html/mdt/**/*.*',
    'html/admin-dist/*.*',
    'html/img/**/*.*',
    'html/sounds/*.*',
    'html/evidencias/*.*',
    "stream/*.ytyp",
    "stream/policetape/*.ytyp",
}

data_file 'DLC_ITYP_REQUEST' 'stream/*.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/policetape/*.ytyp'

provide {
    'qb-policejob'
}

-- Escrow
lua54 'yes'

dependencies {
    "pma-voice"
}

escrow_ignore {
    "utils/mugshot.lua",
    "config/*.lua",
    "config/translations/*.lua",
    "config/logs/logs.lua",
    "custom/client/*.lua",
    "custom/client/menu/*.lua",
    "custom/framework/**/*.lua",
    "custom/shared/*.lua",
    "custom/server/*.lua",
    "custom/server/menu/*.lua",
    "server/tables.lua",
    "radio/config.lua",
    'items.lua'
}

dependency '/assetpacks'