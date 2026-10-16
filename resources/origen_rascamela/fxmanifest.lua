fx_version 'cerulean'

lua54 'yes'
game 'gta5'

files {
    'html/index.html',
    'html/*.css',
    'html/index.js'
}

ui_page 'html/index.html'

client_scripts {
    -- El vigilante del raton (suelta el foco si la pantalla se queda colgada)
    '@origen_map/shared/foco.lua',
    -- Contesta origen:marca:dame a la NUI (Origen o Nacion)
    '@origen_map/shared/tema.lua',
    'client.lua'
}

server_scripts {
    'server.lua'
}