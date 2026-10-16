fx_version 'cerulean'
game 'gta5'

author 'OrigenNetwork'
description 'Mapa: depósito de Davis'
version '1.0.0'

-- Solo mapa: los ymaps y los choques del juego de esa zona, con lo suelto del
-- patio del depósito enterrado 200 m (no borrado, para no romper los índices
-- de LOD) y sin coches aparcados. Una sola versión de cada fichero (la lr_, la
-- que carga el juego): con base/hei_/lr_ a la vez el mapa sale duplicado.
-- Separado de origen_garbage el 30/09 para que cargue como mapeado, antes que
-- el mapa del juego. Se regeneran con origen_garbage/fuente/deposito_ymaps.ps1
-- y deposito_ybn.ps1, que escriben aquí.
this_is_a_map 'yes'
