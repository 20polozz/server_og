-- Packs «Rancho y saloon» y «Mansión gótica» (tanda 2; modelos origen_casa_t4_*: fuente/pack_t4.py, que es quien
-- ESCRIBE este fichero: nombres, precios, tipos y medidas de las partes salen de allí; si se cambia un modelo,
-- se vuelve a generar). Las partes las mueve custom/client/almacenajes.lua con Config.Animados:
--   uso = 'E'        se abre y se cierra con la E
--   uso = 'almacen'  el mueble es un almacén (type = 'stash'): se abre al abrir el alijo y se cierra al cerrarlo
-- Al final, los que alumbran (velas, quinqué, araña, chimenea…): se dan de alta en Config.Luces para que se
-- enciendan y se apaguen como las lámparas del housing (cada uno tiene su modelo «_off» en origen_casa_pk_t4.ytyp).

local P = 'origen_casa_t4_'

Config.Packs.Registrar({
    id = 'rancho_saloon', nombre = 'Rancho y saloon',
    descripcion = 'Monta tu propio saloon o la casa del rancho: barra con trampilla de paso y reposapiés de latón, botellero con espejo, piano de pared, mesa de póker con su partida a medias, puertas batientes, barril, baúl de diligencia y armero de rifles que guardan cosas de verdad, estufa de leña que se abre, cama de forja, mecedora, sillas de enea, abrevadero con bomba, montura en su caballete, cartel de «Se busca», y una lámpara de rueda de carro y un farol de queroseno que se encienden y se apagan',
    xp = 450, grupo = 'tematico',
    categorias = {
        ['Muebles'] = {
            { model = P .. 'barra', price = 4500, nombre = 'Barra de saloon con trampilla de paso', label = 'Barra de saloon con trampilla de paso' },
            { model = P .. 'botellero', price = 4200, nombre = 'Botellero de saloon con espejo', label = 'Botellero de saloon con espejo' },
        },
        ['Instrumentos'] = {
            { model = P .. 'piano', price = 6000, nombre = 'Piano de pared de saloon', label = 'Piano de pared de saloon' },
        },
        ['Mesas'] = {
            { model = P .. 'mesa_poker', price = 3200, nombre = 'Mesa de póker de saloon', label = 'Mesa de póker de saloon' },
        },
        ['Sillas'] = {
            { model = P .. 'silla_enea', price = 900, nombre = 'Silla de enea', label = 'Silla de enea' },
        },
        ['Sillones'] = {
            { model = P .. 'mecedora', price = 1600, nombre = 'Mecedora de porche', label = 'Mecedora de porche' },
        },
        ['Almacenaje'] = {
            { model = P .. 'barril', price = 3200, nombre = 'Barril de whisky', label = 'Barril de whisky', type = 'stash', stash = 'normal' },
            { model = P .. 'baul_diligencia', price = 6500, nombre = 'Baúl de diligencia', label = 'Baúl de diligencia', type = 'stash', stash = 'big' },
        },
        ['Jardín y patio'] = {
            { model = P .. 'abrevadero', price = 2400, nombre = 'Abrevadero con bomba de mano', label = 'Abrevadero con bomba de mano' },
        },
        ['Varios'] = {
            { model = P .. 'perchero_cuernos', price = 1200, nombre = 'Perchero de cuernos de buey', label = 'Perchero de cuernos de buey' },
        },
        ['Luces'] = {
            { model = P .. 'rueda_carro', price = 2200, nombre = 'Lámpara de rueda de carro', label = 'Lámpara de rueda de carro' },
            { model = P .. 'farol', price = 700, nombre = 'Farol de queroseno', label = 'Farol de queroseno' },
        },
        ['Armeros'] = {
            { model = P .. 'armero_rifles', price = 9500, nombre = 'Armero de rifles de vitrina', label = 'Armero de rifles de vitrina', type = 'stash', stash = 'big' },
        },
        ['Camas'] = {
            { model = P .. 'cama_forja', price = 4200, nombre = 'Cama de forja con manta', label = 'Cama de forja con manta' },
        },
        ['Decoración'] = {
            { model = P .. 'estufa', price = 2600, nombre = 'Estufa de leña de hierro fundido', label = 'Estufa de leña de hierro fundido' },
            { model = P .. 'escupidera', price = 500, nombre = 'Escupidera de latón', label = 'Escupidera de latón' },
            { model = P .. 'montura', price = 3000, nombre = 'Montura vaquera en su caballete', label = 'Montura vaquera en su caballete' },
        },
        ['Arte'] = {
            { model = P .. 'cartel_busca', price = 700, nombre = 'Cartel de «Se busca»', label = 'Cartel de «Se busca»' },
        },
        ['Paredes'] = {
            { model = P .. 'puertas_saloon', price = 2200, nombre = 'Puertas batientes de saloon', label = 'Puertas batientes de saloon' },
        },
    },
    animados = {
        [P .. 'barra'] = { uso = 'E', texto = { 'Levantar la trampilla', 'Bajar la trampilla' }, partes = { { modelo = P .. 'barra_trampilla', pos = { 0.640, 0.000, 1.100 }, modo = 'gira', eje = 'y', angulo = -100.0, ms = 800 } } },
        [P .. 'piano'] = { uso = 'E', texto = { 'Cerrar la tapa del teclado', 'Abrir la tapa del teclado' }, partes = { { modelo = P .. 'piano_tapa', pos = { 0.000, -0.050, 0.728 }, modo = 'gira', eje = 'x', angulo = 90.0, ms = 700 } } },
        [P .. 'barril'] = { uso = 'almacen', texto = { 'Destapar', 'Tapar' }, partes = { { modelo = P .. 'barril_tapa', pos = { 0.000, 0.228, 0.874 }, modo = 'gira', eje = 'x', angulo = -105.0, ms = 700 } } },
        [P .. 'baul_diligencia'] = { uso = 'almacen', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'baul_diligencia_tapa', pos = { 0.000, 0.260, 0.440 }, modo = 'gira', eje = 'x', angulo = -98.0, ms = 800 } } },
        [P .. 'armero_rifles'] = { uso = 'almacen', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'armero_rifles_puerta_i', pos = { -0.530, -0.160, 0.600 }, modo = 'gira', eje = 'z', angulo = -112.0, ms = 700 }, { modelo = P .. 'armero_rifles_puerta_d', pos = { 0.530, -0.160, 0.600 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 700 } } },
        [P .. 'estufa'] = { uso = 'E', texto = { 'Abrir la portezuela', 'Cerrar la portezuela' }, partes = { { modelo = P .. 'estufa_puerta', pos = { 0.140, -0.360, 0.390 }, modo = 'gira', eje = 'z', angulo = 118.0, ms = 700 } } },
        [P .. 'puertas_saloon'] = { uso = 'E', texto = { 'Abrir las puertas', 'Cerrar las puertas' }, partes = { { modelo = P .. 'puertas_saloon_hoja_i', pos = { -0.580, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = -78.0, ms = 500 }, { modelo = P .. 'puertas_saloon_hoja_d', pos = { 0.580, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = 78.0, ms = 500 } } },
    },
})

Config.Packs.Registrar({
    id = 'mansion_gotica', nombre = 'Mansión gótica',
    descripcion = 'Para la casa encantada, la cripta o el salón del conde: trono, cama con dosel, mesa de banquete y sillas de respaldo alto; órgano de tubos, librería de biblioteca con escalera corredera, vitrina de curiosidades, reloj de pie y espejo basculante que se abren y se mueven; ataúd y armario de boticario que guardan cosas de verdad; gárgola, atril y cortinajes de terciopelo; y candelabros, araña de hierro, calavera con vela y chimenea de piedra que se encienden y se apagan',
    xp = 500, grupo = 'tematico',
    categorias = {
        ['Sillones'] = {
            { model = P .. 'trono', price = 7000, nombre = 'Trono gótico', label = 'Trono gótico' },
        },
        ['Camas'] = {
            { model = P .. 'cama_dosel', price = 9000, nombre = 'Cama con dosel', label = 'Cama con dosel' },
        },
        ['Luces'] = {
            { model = P .. 'hachero', price = 2000, nombre = 'Hachero de forja de siete velas', label = 'Hachero de forja de siete velas' },
            { model = P .. 'candelabro', price = 900, nombre = 'Candelabro de mesa de tres brazos', label = 'Candelabro de mesa de tres brazos' },
            { model = P .. 'arana_hierro', price = 3200, nombre = 'Araña de hierro forjado', label = 'Araña de hierro forjado' },
            { model = P .. 'calavera', price = 800, nombre = 'Calavera con vela', label = 'Calavera con vela' },
        },
        ['Almacenaje'] = {
            { model = P .. 'ataud', price = 11000, nombre = 'Ataúd de ébano', label = 'Ataúd de ébano', type = 'stash', stash = 'extrabig' },
            { model = P .. 'boticario', price = 8000, nombre = 'Armario de boticario', label = 'Armario de boticario', type = 'stash', stash = 'big' },
        },
        ['Instrumentos'] = {
            { model = P .. 'organo', price = 15000, nombre = 'Órgano de tubos', label = 'Órgano de tubos' },
        },
        ['Muebles'] = {
            { model = P .. 'libreria', price = 9500, nombre = 'Librería de biblioteca con escalera corredera', label = 'Librería de biblioteca con escalera corredera' },
            { model = P .. 'vitrina', price = 5500, nombre = 'Vitrina de curiosidades', label = 'Vitrina de curiosidades' },
        },
        ['Decoración'] = {
            { model = P .. 'espejo_oval', price = 2400, nombre = 'Espejo ovalado basculante', label = 'Espejo ovalado basculante' },
            { model = P .. 'reloj_pie', price = 3600, nombre = 'Reloj de pie de péndulo', label = 'Reloj de pie de péndulo' },
            { model = P .. 'chimenea', price = 7000, nombre = 'Chimenea de piedra', label = 'Chimenea de piedra' },
        },
        ['Esculturas y premios'] = {
            { model = P .. 'gargola', price = 3500, nombre = 'Gárgola de piedra', label = 'Gárgola de piedra' },
        },
        ['Mesas'] = {
            { model = P .. 'mesa_banquete', price = 6500, nombre = 'Mesa de banquete', label = 'Mesa de banquete' },
        },
        ['Sillas'] = {
            { model = P .. 'silla_alta', price = 1900, nombre = 'Silla de respaldo alto', label = 'Silla de respaldo alto' },
        },
        ['Ventanas y cortinas'] = {
            { model = P .. 'cortinaje', price = 2600, nombre = 'Cortinajes de terciopelo', label = 'Cortinajes de terciopelo' },
        },
        ['Libros y velas'] = {
            { model = P .. 'atril', price = 2000, nombre = 'Atril con libro de salmos', label = 'Atril con libro de salmos' },
        },
    },
    animados = {
        [P .. 'ataud'] = { uso = 'almacen', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'ataud_tapa', pos = { 0.000, 0.370, 0.650 }, modo = 'gira', eje = 'x', angulo = -102.0, ms = 1400 } } },
        [P .. 'libreria'] = { uso = 'E', texto = { 'Mover la escalera', 'Devolver la escalera' }, partes = { { modelo = P .. 'libreria_escalera', pos = { -0.840, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 1.680, ms = 2200 } } },
        [P .. 'boticario'] = { uso = 'almacen', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'boticario_cajon', pos = { -0.400, 0.000, 0.615 }, modo = 'corre', eje = 'y', recorrido = -0.190, ms = 500 }, { modelo = P .. 'boticario_cajon', pos = { 0.200, 0.000, 0.445 }, modo = 'corre', eje = 'y', recorrido = -0.140, ms = 500 }, { modelo = P .. 'boticario_cajon', pos = { -0.200, 0.000, 0.785 }, modo = 'corre', eje = 'y', recorrido = -0.090, ms = 500 }, { modelo = P .. 'boticario_cajon', pos = { 0.000, 0.000, 0.105 }, modo = 'corre', eje = 'y', recorrido = -0.190, ms = 500 }, { modelo = P .. 'boticario_cajon', pos = { -0.600, 0.000, 0.275 }, modo = 'corre', eje = 'y', recorrido = -0.140, ms = 500 }, { modelo = P .. 'boticario_cajon', pos = { 0.400, 0.000, 0.785 }, modo = 'corre', eje = 'y', recorrido = -0.090, ms = 500 } } },
        [P .. 'espejo_oval'] = { uso = 'E', texto = { 'Inclinar el espejo', 'Enderezar el espejo' }, partes = { { modelo = P .. 'espejo_oval_luna', pos = { 0.000, 0.000, 1.000 }, modo = 'gira', eje = 'x', angulo = -11.0, ms = 900 } } },
        [P .. 'reloj_pie'] = { uso = 'E', texto = { 'Abrir la caja del péndulo', 'Cerrar la caja del péndulo' }, partes = { { modelo = P .. 'reloj_pie_puerta', pos = { 0.180, -0.110, 0.570 }, modo = 'gira', eje = 'z', angulo = 108.0, ms = 700 } } },
        [P .. 'vitrina'] = { uso = 'E', texto = { 'Abrir la vitrina', 'Cerrar la vitrina' }, partes = { { modelo = P .. 'vitrina_puerta_i', pos = { -0.530, -0.160, 0.540 }, modo = 'gira', eje = 'z', angulo = -115.0, ms = 800 }, { modelo = P .. 'vitrina_puerta_d', pos = { 0.530, -0.160, 0.540 }, modo = 'gira', eje = 'z', angulo = 115.0, ms = 800 } } },
        [P .. 'cortinaje'] = { uso = 'E', texto = { 'Abrir las cortinas', 'Cerrar las cortinas' }, partes = { { modelo = P .. 'cortinaje_pano', pos = { -1.030, -0.085, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.050, ms = 1200 }, { modelo = P .. 'cortinaje_pano', pos = { 1.030, -0.085, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.050, ms = 1200 }, { modelo = P .. 'cortinaje_pano', pos = { -0.650, -0.115, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.330, ms = 1200 }, { modelo = P .. 'cortinaje_pano', pos = { 0.650, -0.115, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.330, ms = 1200 }, { modelo = P .. 'cortinaje_pano', pos = { -0.270, -0.085, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.610, ms = 1200 }, { modelo = P .. 'cortinaje_pano', pos = { 0.270, -0.085, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.610, ms = 1200 } } },
    },
})

-- Los que se encienden y se apagan (custom/*/luces.lua). Config.Luces.Lampara solo conoce las lámparas de su
-- tabla (prefijo «origen_casa_luz_»): aquí se le enseñan las de estos packs sin tocar config/luces.lua.
-- tipo: dónde va (techo, pie, mesa) · mano: también con la E junto a ella; las de techo, solo con el
-- interruptor de la sala.
if type(Config.Luces) == 'table' and type(Config.Luces.Lampara) == 'function' then
    local MIAS = {
        rueda_carro = { tipo = 'techo', nombre = 'Lámpara de rueda de carro' },
        farol = { tipo = 'mesa', nombre = 'Farol de queroseno', mano = true },
        hachero = { tipo = 'pie', nombre = 'Hachero de forja de siete velas', mano = true },
        candelabro = { tipo = 'mesa', nombre = 'Candelabro de mesa de tres brazos', mano = true },
        arana_hierro = { tipo = 'techo', nombre = 'Araña de hierro forjado' },
        chimenea = { tipo = 'pie', nombre = 'Chimenea de piedra', mano = true },
        calavera = { tipo = 'mesa', nombre = 'Calavera con vela', mano = true },
    }
    local PORNOMBRE, PORHASH = {}, {}
    for id, l in pairs(MIAS) do
        l.id = 't4_' .. id
        l.modelo = P .. id
        l.apagada = l.modelo .. '_off'
        PORNOMBRE[l.modelo] = l
        PORHASH[joaat(l.modelo)] = l
    end
    local antes = Config.Luces.Lampara
    function Config.Luces.Lampara(modelo)
        local l = antes(modelo)
        if l then return l end
        if type(modelo) == 'number' then return PORHASH[modelo] end
        return type(modelo) == 'string' and PORNOMBRE[modelo] or nil
    end
end
