fx_version 'cerulean'
game 'gta5'

author 'Origen Network'
description 'Paginas que se abren dentro de las pantallas del mundo'
version '1.0.0'

-- ¿Por qué un recurso aparte y SIN guion bajo en el nombre?
--
-- Una página de recurso se sirve desde https://cfx-nui-<recurso>/. El
-- reproductor de Twitch contesta con «frame-ancestors https://<ese host>», y en
-- CSP un host solo admite letras, cifras y guiones: con «origen_screens» la
-- regla se descarta entera y el directo no se deja enmarcar. Este recurso solo
-- existe para que el host sea «cfx-nui-origenweb». No le cambies el nombre.
--
-- Lo usa origen_screens (Config.Pagina). No lleva scripts.

files {
    'tele.html',
}
