-- Muebles propios de los packs «Casino en casa» y «Club privado» (modelos:
-- fuente/pack_t1.py, origen_casa_t1_*). Dos packs temáticos; cada mueble va en la
-- categoría del catálogo que le toca.
--
-- ESTE FICHERO LO ESCRIBE fuente/pack_t1_lua.py con las medidas de las partes
-- que deja pack_t1.py: si se cambia un modelo, se vuelve a generar.
--
-- Qué hace cada uno:
--   · con `type` (los de siempre del housing): la jaula de caja y el carrito de
--     fichas son almacén ('stash'), la nevera de botellas también, y el guardarropa
--     es ropero ('wardrobe'). Sus partes (reja, cajón, puertas) se abren al usarlos.
--   · con partes y uso 'E': se mueven con la E (custom/client/almacenajes.lua).
--     La rueda de la ruleta, la ruleta de la fortuna y la bola de espejos «giran»:
--     el sistema de partes solo sabe ir de cerrado a abierto, así que al
--     encenderlas dan sus vueltas en unos segundos y se paran (la bola, diez
--     vueltas en setenta segundos); con otra E las desandan. No es giro continuo.
--   · los que alumbran (tragaperras, vitrina, rótulo, lámpara de juego, barra,
--     botellero, cabina, podio, bola, focos) llevan la luz dentro del modelo:
--     siempre encendida, no van con interruptor.
-- De techo (z = 0 es el techo, cuelgan hacia abajo): lampara_juego y bola_espejos.
-- De pared (origen en su canto de abajo, se coloca y se sube): rotulo_casino.

local P = 'origen_casa_t1_'

local function M(id, precio, nombre, extra)
    local it = { model = P .. id, price = precio, nombre = nombre, label = nombre }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end

Config.Packs.Registrar({
    id = 'casino_casa', nombre = 'Casino en casa',
    descripcion = 'Monta tu sala de juego: mesa de ruleta con la rueda que gira, mesas de blackjack y de póker, dos tragaperras con su palanca, ruleta de la fortuna, jaula de caja y carrito de fichas que guardan cosas, vitrina de premios, taburetes y sillones de jugador, postes con cordón, lámpara de mesa de juego, alfombra y rótulo luminoso',
    xp = 450, grupo = 'tematico',
    categorias = {
        ['Mesas'] = {
            M('mesa_ruleta', 38000, 'Mesa de ruleta con rueda que gira'),
            M('mesa_blackjack', 24000, 'Mesa de blackjack'),
            M('mesa_poker', 26000, 'Mesa de póker ovalada'),
        },
        ['Juegos y juguetes'] = {
            M('tragaperras_faraon', 22000, 'Tragaperras «Deity of the Sun»'),
            M('tragaperras_diamante', 22000, 'Tragaperras «Diamond Miner»'),
            M('ruleta_fortuna', 28000, 'Ruleta de la fortuna'),
            M('maletin_fichas', 3500, 'Maletín de fichas de póker'),
            M('carrusel_fichas', 2500, 'Carrusel de fichas de póker'),
        },
        ['Almacenaje'] = {
            M('jaula_caja', 36000, 'Jaula de caja del casino', { type = 'stash', stash = 'extrabig' }),
            M('carrito_fichas', 9500, 'Carrito de fichas del crupier', { type = 'stash', stash = 'medium' }),
        },
        ['Trofeos'] = {
            M('vitrina_premios', 18000, 'Vitrina de premios'),
        },
        ['Sillas'] = {
            M('taburete_casino', 2800, 'Taburete de casino'),
            M('sillon_jugador', 4800, 'Sillón de jugador en capitoné'),
        },
        ['Decoración'] = {
            M('cordon_tramo', 2400, 'Postes de latón con cordón'),
            M('set_crupier', 2200, 'Set de crupier: sabot, barajas y fichas'),
        },
        ['Alfombras'] = {
            M('alfombra_casino', 7500, 'Alfombra de casino'),
        },
        ['Luces'] = {
            M('lampara_juego', 6500, 'Lámpara de mesa de juego (de techo)'),
        },
        ['Carteles de neón'] = {
            M('rotulo_casino', 9000, 'Rótulo luminoso de casino'),
        },
    },
    animados = {
        [P .. 'mesa_ruleta'] = { uso = 'E', texto = { 'Girar la ruleta', 'Parar la ruleta' }, partes = { { modelo = P .. 'mesa_ruleta_rueda', pos = { -0.800, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = 2160.0, ms = 9000 } } },
        [P .. 'tragaperras_faraon'] = { uso = 'E', texto = { 'Tirar de la palanca', 'Soltar la palanca' }, partes = { { modelo = P .. 'tragaperras_faraon_palanca', pos = { 0.350, -0.040, 1.090 }, modo = 'gira', eje = 'x', angulo = 62.0, ms = 450 } } },
        [P .. 'tragaperras_diamante'] = { uso = 'E', texto = { 'Tirar de la palanca', 'Soltar la palanca' }, partes = { { modelo = P .. 'tragaperras_diamante_palanca', pos = { 0.350, -0.040, 1.090 }, modo = 'gira', eje = 'x', angulo = 62.0, ms = 450 } } },
        [P .. 'ruleta_fortuna'] = { uso = 'E', texto = { 'Girar la ruleta', 'Parar la ruleta' }, partes = { { modelo = P .. 'ruleta_fortuna_rueda', pos = { 0.000, 0.000, 1.360 }, modo = 'gira', eje = 'y', angulo = 1980.0, ms = 9000 } } },
        [P .. 'maletin_fichas'] = { uso = 'E', texto = { 'Abrir el maletín', 'Cerrar el maletín' }, partes = { { modelo = P .. 'maletin_fichas_tapa', pos = { 0.000, 0.125, 0.055 }, modo = 'gira', eje = 'x', angulo = -108.0, ms = 600 } } },
        [P .. 'jaula_caja'] = { uso = 'almacen', texto = { 'Abrir la caja', 'Cerrar la caja' }, partes = { { modelo = P .. 'jaula_caja_reja', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = 0.40, ms = 700 } } },
        [P .. 'carrito_fichas'] = { uso = 'almacen', texto = { 'Abrir el cajón', 'Cerrar el cajón' }, partes = { { modelo = P .. 'carrito_fichas_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.30, ms = 600 } } },
        [P .. 'vitrina_premios'] = { uso = 'E', texto = { 'Abrir la vitrina', 'Cerrar la vitrina' }, partes = { { modelo = P .. 'vitrina_premios_puerta_i', pos = { -0.520, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 700 }, { modelo = P .. 'vitrina_premios_puerta_d', pos = { 0.520, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 700 } } },
    },
})

Config.Packs.Registrar({
    id = 'club_privado', nombre = 'Club privado',
    descripcion = 'Tu propia sala VIP: barra por módulos con paso abatible, botellero iluminado, nevera de botellas, reservado con sofá en U y mesa con cubitera, cabina de DJ, torre de altavoces, podio de baile, bola de espejos que gira, focos de colores y cabeza móvil, telón de terciopelo, cuerda de acceso, guardarropa y alfombra roja',
    xp = 450, grupo = 'tematico',
    categorias = {
        ['Bebidas'] = {
            M('barra_recta', 12000, 'Barra de club: tramo recto'),
            M('barra_puerta', 8500, 'Barra de club: paso con tapa abatible'),
            M('botellero_led', 19000, 'Botellero iluminado de club'),
            M('cubitera_pie', 3800, 'Cubitera de pie con champán'),
        },
        ['Neveras'] = {
            M('nevera_botellas', 9500, 'Nevera de botellas de barra', { type = 'stash', stash = 'medium' }),
        },
        ['Sillas'] = {
            M('taburete_alto', 2600, 'Taburete alto de terciopelo'),
        },
        ['Sillones'] = {
            M('reservado_u', 32000, 'Reservado: sofá en U'),
        },
        ['Mesas'] = {
            M('mesa_reservado', 7500, 'Mesa de reservado con cubitera'),
            M('mesa_alta', 3200, 'Mesa alta de cóctel'),
        },
        ['Música / DJ'] = {
            M('cabina_dj', 34000, 'Cabina de DJ de club'),
            M('altavoz_torre', 12000, 'Torre de altavoces'),
            M('monitor_escenario', 4500, 'Monitor de escenario'),
            M('podio_baile', 14000, 'Podio de baile con barra'),
        },
        ['Luces'] = {
            M('bola_espejos', 6500, 'Bola de espejos giratoria (de techo)'),
            M('barra_focos', 9000, 'Barra de focos de colores en trípode'),
            M('cabeza_movil', 8500, 'Foco de cabeza móvil'),
        },
        ['Ventanas y cortinas'] = {
            M('telon', 14000, 'Telón de terciopelo rojo'),
        },
        ['Decoración'] = {
            M('cuerda_acceso', 3200, 'Cuerda de acceso de terciopelo'),
        },
        ['Armarios'] = {
            M('guardarropa', 16000, 'Guardarropa de club', { type = 'wardrobe' }),
        },
        ['Alfombras'] = {
            M('alfombra_roja', 6000, 'Alfombra roja'),
        },
    },
    animados = {
        [P .. 'barra_puerta'] = { uso = 'E', texto = { 'Abrir el paso', 'Cerrar el paso' }, partes = { { modelo = P .. 'barra_puerta_tapa', pos = { -0.370, 0.000, 1.085 }, modo = 'gira', eje = 'y', angulo = -88.0, ms = 700 }, { modelo = P .. 'barra_puerta_puerta', pos = { -0.375, -0.255, 0.000 }, modo = 'gira', eje = 'z', angulo = -100.0, ms = 700 } } },
        [P .. 'nevera_botellas'] = { uso = 'almacen', texto = { 'Abrir la nevera', 'Cerrar la nevera' }, partes = { { modelo = P .. 'nevera_botellas_puerta_i', pos = { -0.655, -0.275, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = P .. 'nevera_botellas_puerta_d', pos = { 0.655, -0.275, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        [P .. 'bola_espejos'] = { uso = 'E', texto = { 'Encender la bola', 'Parar la bola' }, partes = { { modelo = P .. 'bola_espejos_bola', pos = { 0.000, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = 3600.0, ms = 70000 } } },
        [P .. 'cabeza_movil'] = { uso = 'E', texto = { 'Mover el foco', 'Parar el foco' }, partes = { { modelo = P .. 'cabeza_movil_cabeza', pos = { 0.000, 0.000, 0.130 }, modo = 'gira', eje = 'z', angulo = 300.0, ms = 6000 } } },
        [P .. 'telon'] = { uso = 'E', texto = { 'Abrir el telón', 'Cerrar el telón' }, partes = { { modelo = P .. 'telon_pano_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.02, ms = 1400 }, { modelo = P .. 'telon_pano_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.50, ms = 1400 }, { modelo = P .. 'telon_pano_c', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.98, ms = 1400 }, { modelo = P .. 'telon_pano_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.98, ms = 1400 }, { modelo = P .. 'telon_pano_e', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.50, ms = 1400 }, { modelo = P .. 'telon_pano_f', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.02, ms = 1400 } } },
        [P .. 'cuerda_acceso'] = { uso = 'E', texto = { 'Abrir el paso', 'Cerrar el paso' }, partes = { { modelo = P .. 'cuerda_acceso_cuerda', pos = { -0.600, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = -82.0, ms = 800 } } },
        [P .. 'guardarropa'] = { uso = 'ropero', texto = { 'Abrir el guardarropa', 'Cerrar el guardarropa' }, partes = { { modelo = P .. 'guardarropa_puerta_i', pos = { -0.800, -0.290, 0.000 }, modo = 'gira', eje = 'z', angulo = -108.0, ms = 700 }, { modelo = P .. 'guardarropa_puerta_d', pos = { 0.800, -0.290, 0.000 }, modo = 'gira', eje = 'z', angulo = 108.0, ms = 700 } } },
    },
})
