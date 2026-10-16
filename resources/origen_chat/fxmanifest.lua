fx_version 'cerulean'

game 'gta5'

author 'OrigenNetwork'

version '1.0.0'

lua54 'yes'

ui_page 'ui/index.html'

shared_scripts {
  '@ox_lib/init.lua',
  'init.lua',
  'config/*.lua',
}

client_scripts {
  '@origen_map/shared/foco.lua',
  '@origen_map/shared/tema.lua',
  'custom/client/*.lua',
  'client/*.lua',
}

server_scripts {
  'custom/server/*.lua',
  'server/*.lua',
}

files {
  'ui/index.html',
  'ui/assets/*.*',
  'locales/*.json'
}

provide 'chat'

dependencies {
  'ox_lib',
}

escrow_ignore {
  'config/*.lua',
  'custom/**/*.lua',
}