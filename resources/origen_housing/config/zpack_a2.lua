-- Packs «Galería de autor» y «Luz y neón» (tanda 2; modelos origen_casa_a2_*: fuente/pack_a2.py, que es quien
-- ESCRIBE este fichero: nombres, precios, tipos y medidas de las partes salen de allí; si se cambia un modelo,
-- se vuelve a generar). Las partes las mueve custom/client/almacenajes.lua con Config.Animados:
--   uso = 'E'        se abre y se cierra (o se pone en marcha) con la E
--   uso = 'almacen'  el mueble es un almacén (type = 'stash'): se abre al abrir el alijo y se cierra al cerrarlo
-- Los que giran sin parar (ventilador de techo, escultura cinética) dan sus vueltas en unos segundos y se paran:
-- el sistema de partes solo sabe ir de cerrado a abierto.
-- Al final, las lámparas y los neones: se dan de alta en Config.Luces para que se enciendan y se apaguen como
-- las del pack de iluminación (cada una tiene su modelo «_off» en origen_casa_pk_a2.ytyp).

local P = 'origen_casa_a2_'

Config.Packs.Registrar({
    id = 'galeria_autor', nombre = 'Galería de autor',
    descripcion = 'Para que la casa parezca la de un coleccionista: reloj de pie y de cuco, bola del mundo que esconde un bar, espejo basculante, ventilador de techo y biombo de ratán; óleos y láminas enmarcadas, jardín vertical, terrario, olivo y bonsái; alfombras de autor; librería con escalera corredera y estantería giratoria; esculturas (una, cinética), vitrina de trofeos, joyero y vitrina de joyería que guardan cosas de verdad',
    xp = 450, grupo = 'muebles',
    categorias = {
        ['Decoración'] = {
            { model = P .. 'reloj_pie', price = 9500, nombre = 'Reloj de pie de péndulo', label = 'Reloj de pie de péndulo' },
            { model = P .. 'reloj_cuco', price = 6500, nombre = 'Reloj de cuco', label = 'Reloj de cuco' },
            { model = P .. 'espejo_pie', price = 7000, nombre = 'Espejo de pie basculante', label = 'Espejo de pie basculante' },
            { model = P .. 'ventilador_techo', price = 6000, nombre = 'Ventilador de techo de madera', label = 'Ventilador de techo de madera' },
            { model = P .. 'biombo_ratan', price = 5500, nombre = 'Biombo de ratán de tres hojas', label = 'Biombo de ratán de tres hojas' },
            { model = P .. 'bola_mundo', price = 9000, nombre = 'Bola del mundo con bar', label = 'Bola del mundo con bar', type = 'stash', stash = 'normal' },
        },
        ['Arte'] = {
            { model = P .. 'cuadro_cuadrado', price = 8500, nombre = 'Lienzo abstracto «Cuadrado naranja»', label = 'Lienzo abstracto «Cuadrado naranja»' },
            { model = P .. 'galeria_trio', price = 6500, nombre = 'Trío de láminas enmarcadas', label = 'Trío de láminas enmarcadas' },
            { model = P .. 'cuadro_billar', price = 9500, nombre = 'Óleo «El partido» con luz de galería', label = 'Óleo «El partido» con luz de galería' },
            { model = P .. 'cuadro_cubista', price = 9000, nombre = 'Óleo cubista «El músico»', label = 'Óleo cubista «El músico»' },
            { model = P .. 'escultura_pared', price = 8000, nombre = 'Escultura de pared «Órbitas»', label = 'Escultura de pared «Órbitas»' },
        },
        ['Plantas'] = {
            { model = P .. 'jardin_vertical', price = 9500, nombre = 'Jardín vertical', label = 'Jardín vertical' },
            { model = P .. 'terrario', price = 4500, nombre = 'Terrario de cristal y latón', label = 'Terrario de cristal y latón' },
            { model = P .. 'olivo', price = 6500, nombre = 'Olivo en macetero de piedra', label = 'Olivo en macetero de piedra' },
            { model = P .. 'bonsai', price = 6000, nombre = 'Bonsái sobre mesita lacada', label = 'Bonsái sobre mesita lacada' },
            { model = P .. 'estante_plantas', price = 5500, nombre = 'Estantería de escalera con macetas', label = 'Estantería de escalera con macetas' },
        },
        ['Alfombras'] = {
            { model = P .. 'alfombra_trazo', price = 7500, nombre = 'Alfombra de lana «Trazo rojo»', label = 'Alfombra de lana «Trazo rojo»' },
            { model = P .. 'alfombra_tinta', price = 8500, nombre = 'Alfombra de lana «Tinta y jade»', label = 'Alfombra de lana «Tinta y jade»' },
            { model = P .. 'alfombra_bloques', price = 6500, nombre = 'Alfombra de lana «Bloques»', label = 'Alfombra de lana «Bloques»' },
            { model = P .. 'alfombra_niebla', price = 7000, nombre = 'Alfombra de lana «Niebla»', label = 'Alfombra de lana «Niebla»' },
            { model = P .. 'alfombra_yute', price = 4500, nombre = 'Alfombra redonda de yute trenzado', label = 'Alfombra redonda de yute trenzado' },
        },
        ['Libros y velas'] = {
            { model = P .. 'libreria_escalera', price = 16000, nombre = 'Librería de biblioteca con escalera corredera', label = 'Librería de biblioteca con escalera corredera' },
            { model = P .. 'estanteria_giratoria', price = 7500, nombre = 'Estantería giratoria de libros', label = 'Estantería giratoria de libros' },
            { model = P .. 'farol', price = 3500, nombre = 'Farol de suelo con vela', label = 'Farol de suelo con vela' },
            { model = P .. 'candelabro_pie', price = 5500, nombre = 'Candelabro de pie de cinco brazos', label = 'Candelabro de pie de cinco brazos' },
        },
        ['Esculturas y premios'] = {
            { model = P .. 'escultura_cinetica', price = 12000, nombre = 'Escultura cinética «Astrolabio»', label = 'Escultura cinética «Astrolabio»' },
            { model = P .. 'escultura_piedras', price = 7000, nombre = 'Escultura «Piedras en equilibrio»', label = 'Escultura «Piedras en equilibrio»' },
            { model = P .. 'escultura_espiral', price = 11000, nombre = 'Escultura «Torsión» en cobre', label = 'Escultura «Torsión» en cobre' },
        },
        ['Trofeos'] = {
            { model = P .. 'vitrina_trofeos', price = 14000, nombre = 'Vitrina de trofeos iluminada', label = 'Vitrina de trofeos iluminada', type = 'stash', stash = 'big' },
            { model = P .. 'copa_campeon', price = 8000, nombre = 'Gran copa de campeón', label = 'Gran copa de campeón' },
            { model = P .. 'camiseta_firmada', price = 7000, nombre = 'Camiseta firmada enmarcada', label = 'Camiseta firmada enmarcada' },
        },
        ['Joyas'] = {
            { model = P .. 'joyero', price = 4500, nombre = 'Joyero de nogal con espejo', label = 'Joyero de nogal con espejo', type = 'stash', stash = 'small' },
            { model = P .. 'busto_collar', price = 6000, nombre = 'Busto con collar de perlas y rubí', label = 'Busto con collar de perlas y rubí' },
            { model = P .. 'vitrina_joyas', price = 15000, nombre = 'Vitrina de joyería', label = 'Vitrina de joyería', type = 'stash', stash = 'big' },
            { model = P .. 'caja_relojes', price = 5000, nombre = 'Estuche de relojes de colección', label = 'Estuche de relojes de colección' },
        },
    },
    animados = {
        [P .. 'reloj_pie'] = { uso = 'E', texto = { 'Abrir la puerta', 'Cerrar la puerta' }, partes = { { modelo = P .. 'reloj_pie_puerta', pos = { -0.190, -0.110, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 800 } } },
        [P .. 'reloj_cuco'] = { uso = 'E', texto = { 'Dar la hora', 'Guardar el cuco' }, partes = { { modelo = P .. 'reloj_cuco_puerta', pos = { -0.035, -0.120, 0.000 }, modo = 'gira', eje = 'z', angulo = -115.0, ms = 350 }, { modelo = P .. 'reloj_cuco_pajaro', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.085, ms = 500 } } },
        [P .. 'espejo_pie'] = { uso = 'E', texto = { 'Inclinar el espejo', 'Enderezar el espejo' }, partes = { { modelo = P .. 'espejo_pie_luna', pos = { 0.000, 0.000, 1.000 }, modo = 'gira', eje = 'x', angulo = -14.0, ms = 900 } } },
        [P .. 'ventilador_techo'] = { uso = 'E', texto = { 'Encender', 'Apagar' }, partes = { { modelo = P .. 'ventilador_techo_palas', pos = { 0.000, 0.000, -0.330 }, modo = 'gira', eje = 'z', angulo = 7200.0, ms = 9000 } } },
        [P .. 'biombo_ratan'] = { uso = 'E', texto = { 'Plegar el biombo', 'Desplegar el biombo' }, partes = { { modelo = P .. 'biombo_ratan_hoja_i', pos = { -0.264, -0.016, 0.000 }, modo = 'gira', eje = 'z', angulo = 148.0, ms = 1200 }, { modelo = P .. 'biombo_ratan_hoja_d', pos = { 0.264, 0.016, 0.000 }, modo = 'gira', eje = 'z', angulo = 148.0, ms = 1200 } } },
        [P .. 'bola_mundo'] = { uso = 'almacen', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'bola_mundo_tapa', pos = { 0.000, 0.300, 0.660 }, modo = 'gira', eje = 'x', angulo = -72.0, ms = 900 } } },
        [P .. 'terrario'] = { uso = 'E', texto = { 'Abrir la tapa', 'Cerrar la tapa' }, partes = { { modelo = P .. 'terrario_tapa', pos = { 0.000, 0.140, 0.335 }, modo = 'gira', eje = 'x', angulo = -68.0, ms = 700 } } },
        [P .. 'libreria_escalera'] = { uso = 'E', texto = { 'Mover la escalera', 'Devolver la escalera' }, partes = { { modelo = P .. 'libreria_escalera_escalera', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.950, ms = 1800 } } },
        [P .. 'estanteria_giratoria'] = { uso = 'E', texto = { 'Girar la estantería', 'Girar la estantería' }, partes = { { modelo = P .. 'estanteria_giratoria_torre', pos = { 0.000, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = 180.0, ms = 1600 } } },
        [P .. 'farol'] = { uso = 'E', texto = { 'Abrir el farol', 'Cerrar el farol' }, partes = { { modelo = P .. 'farol_puerta', pos = { -0.110, -0.110, 0.000 }, modo = 'gira', eje = 'z', angulo = -110.0, ms = 600 } } },
        [P .. 'escultura_cinetica'] = { uso = 'E', texto = { 'Dar impulso', 'Parar' }, partes = { { modelo = P .. 'escultura_cinetica_aro_a', pos = { 0.000, 0.000, 0.620 }, modo = 'gira', eje = 'z', angulo = 1440.0, ms = 10000 }, { modelo = P .. 'escultura_cinetica_aro_b', pos = { 0.000, 0.000, 0.620 }, modo = 'gira', eje = 'x', angulo = 2160.0, ms = 10000 }, { modelo = P .. 'escultura_cinetica_esfera', pos = { 0.000, 0.000, 0.620 }, modo = 'gira', eje = 'z', angulo = -2880.0, ms = 10000 } } },
        [P .. 'vitrina_trofeos'] = { uso = 'almacen', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'vitrina_trofeos_puerta_i', pos = { -0.545, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = -108.0, ms = 800 }, { modelo = P .. 'vitrina_trofeos_puerta_d', pos = { 0.545, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = 108.0, ms = 800 } } },
        [P .. 'joyero'] = { uso = 'almacen', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'joyero_tapa', pos = { 0.000, 0.100, 0.130 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 700 }, { modelo = P .. 'joyero_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.110, ms = 600 } } },
        [P .. 'vitrina_joyas'] = { uso = 'almacen', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'vitrina_joyas_tapa', pos = { 0.000, 0.263, 1.005 }, modo = 'gira', eje = 'x', angulo = -62.0, ms = 900 } } },
        [P .. 'caja_relojes'] = { uso = 'E', texto = { 'Abrir el estuche', 'Cerrar el estuche' }, partes = { { modelo = P .. 'caja_relojes_tapa', pos = { 0.000, 0.110, 0.070 }, modo = 'gira', eje = 'x', angulo = -98.0, ms = 700 } } },
    },
})

Config.Packs.Registrar({
    id = 'luz_neon', nombre = 'Luz y neón',
    descripcion = 'Cuatro carteles de neón (corazón, rayo, cóctel y luna) y seis lámparas de diseño —de arco, trípode, colgante triple, aplique de globo, de mesa y guirnalda de bombillas— que se encienden y se apagan de verdad, a mano o con el interruptor de la sala',
    xp = 350, grupo = 'muebles',
    categorias = {
        ['Carteles de neón'] = {
            { model = P .. 'neon_corazon', price = 3200, nombre = 'Neón «Corazón»', label = 'Neón «Corazón»' },
            { model = P .. 'neon_rayo', price = 3000, nombre = 'Neón «Rayo»', label = 'Neón «Rayo»' },
            { model = P .. 'neon_copa', price = 3600, nombre = 'Neón «Cóctel»', label = 'Neón «Cóctel»' },
            { model = P .. 'neon_luna', price = 3600, nombre = 'Neón «Luna y estrellas»', label = 'Neón «Luna y estrellas»' },
        },
        ['Luces'] = {
            { model = P .. 'lampara_arco', price = 3200, nombre = 'Lámpara de arco con base de mármol', label = 'Lámpara de arco con base de mármol' },
            { model = P .. 'lampara_tripode', price = 2600, nombre = 'Lámpara trípode de roble', label = 'Lámpara trípode de roble' },
            { model = P .. 'colgante_trio', price = 3000, nombre = 'Colgante triple de vidrio ámbar', label = 'Colgante triple de vidrio ámbar' },
            { model = P .. 'aplique_globo', price = 1400, nombre = 'Aplique de globo opal', label = 'Aplique de globo opal' },
            { model = P .. 'lampara_seta', price = 1500, nombre = 'Lámpara de mesa «Seta»', label = 'Lámpara de mesa «Seta»' },
            { model = P .. 'guirnalda', price = 1800, nombre = 'Guirnalda de bombillas', label = 'Guirnalda de bombillas' },
        },
    },
})

-- Lámparas y neones que se encienden y se apagan (custom/*/luces.lua). Config.Luces.Lampara solo conoce las de
-- su tabla (prefijo «origen_casa_luz_»): aquí se le enseñan las de este pack sin tocar config/luces.lua.
-- tipo: dónde va (techo, pared, pie, mesa, color) · mano: también con la E junto a ella; las de techo, solo
-- con el interruptor de la sala.
if type(Config.Luces) == 'table' and type(Config.Luces.Lampara) == 'function' then
    local MIAS = {
        neon_corazon = { tipo = 'color', nombre = 'Neón «Corazón»', mano = true },
        neon_rayo = { tipo = 'color', nombre = 'Neón «Rayo»', mano = true },
        neon_copa = { tipo = 'color', nombre = 'Neón «Cóctel»', mano = true },
        neon_luna = { tipo = 'color', nombre = 'Neón «Luna y estrellas»', mano = true },
        lampara_arco = { tipo = 'pie', nombre = 'Lámpara de arco con base de mármol', mano = true },
        lampara_tripode = { tipo = 'pie', nombre = 'Lámpara trípode de roble', mano = true },
        colgante_trio = { tipo = 'techo', nombre = 'Colgante triple de vidrio ámbar' },
        aplique_globo = { tipo = 'pared', nombre = 'Aplique de globo opal', mano = true },
        lampara_seta = { tipo = 'mesa', nombre = 'Lámpara de mesa «Seta»', mano = true },
        guirnalda = { tipo = 'pared', nombre = 'Guirnalda de bombillas', mano = true },
    }
    local PORNOMBRE, PORHASH = {}, {}
    for id, l in pairs(MIAS) do
        l.id = 'a2_' .. id
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
