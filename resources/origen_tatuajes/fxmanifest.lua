-- Tatuajes propios del servidor (texturas dibujadas por nosotros). Común a
-- Origen y Nación. Solo transmite: quien los pone es origen_tattoos (o quien
-- toque) con SetPedDecoration(ped, `origen_tatuajes_overlays`, `<nombre>_m|_f`).
--
--   origen_tatuajes_overlays.xml   dónde cae cada tatuaje en el cuerpo (uvPos, scale, giro)
--   stream/<nombre>.ytd            un diccionario por tatuaje, con una textura del mismo nombre
--   fuente/                        de dónde sale todo: `python fuente/montar.py`
--
-- Un tatuaje nuevo: dibujarlo en fuente/dibujos.py, darlo de alta en
-- fuente/tatuajes.py y volver a montar. El cliente carga el XML al conectar:
-- lo nuevo se ve tras reiniciar el recurso y, si no, al reconectar.
fx_version 'cerulean'
game 'gta5'

files {
    'origen_tatuajes_overlays.xml',
}

data_file 'PED_OVERLAY_FILE' 'origen_tatuajes_overlays.xml'
