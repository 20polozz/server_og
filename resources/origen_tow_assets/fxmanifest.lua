--[[ Los modelos de la grua de plataforma.

     El `flatbed` de serie del GTA tiene la caja de una pieza: no hay nada
     que la incline, asi que nunca se va a ver como sube un coche. Este
     modelo SUSTITUYE al de serie por el del MTL Flatbed, que trae la caja
     de dos formas: como extra 1 del camion (que se oculta) y como prop
     suelto `inm_flatbed_base`, que es el que se desliza y se inclina.

     Aqui solo estan los modelos. Quien los mueve es origen_tow.

     El camion y sus texturas son de I'm Not MentaL y Yoha
     (gta5-mods.com/vehicles/mtl-flatbed-tow-truck); el empaquetado para
     FiveM, de Gamzky (gs_flatbed). La licencia de este ultimo esta al lado,
     en LICENCIA-gamzky.txt. ]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OrigenNetwork'
description 'Modelos de la grua de plataforma'
version '1.0.0'

files {
    'stream/flatbed.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/flatbed.ytyp'
