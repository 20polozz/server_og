--[[ origen_ajustes · el menú de ajustes de GTA (Esc / radial «Ajustes») con el
     estilo pegatina claro. No es una NUI: son los .gfx del propio menú de
     pausa, editados, que FiveM carga en lugar de los del juego. Así gráficos,
     sonido, teclas... siguen funcionando de verdad.

     Los originales salen de update.rpf/x64/data/cdimages/scaleform_frontend.rpf
     y se editan con JPEXS (ActionScript 2). ]]

fx_version 'cerulean'
game 'gta5'

author 'Origen'
description 'Menú de ajustes de GTA con el estilo pegatina'

client_script 'client.lua'

ui_page 'ui/index.html'
files { 'ui/index.html' }
