-- Muebles propios de los packs «Estudio y directo» y «Ocio, deporte y mascotas»
-- (tanda 2; modelos: fuente/pack_o2.py, origen_casa_o2_*). Categorías: «Escritorios»,
-- «Tecnología», «Música / DJ», «Instrumentos», «Juegos y juguetes», «Gimnasio» y «Mascotas».
--
-- ESTE FICHERO LO ESCRIBE fuente/pack_o2_lua.py (catálogo, precios y nombres están
-- allí; las medidas de las partes, en fuente/pack_o2_partes.json, que deja pack_o2.py).
--
-- Con función, por su `type` de siempre del housing:
--   · tv        escritorio_streamer, tele_pared y tele_retro: la pantalla lleva la
--               textura «script_rt_tvscreen» y hay que darlos de alta en
--               origen_screens/shared/config.lua (Config.Modelos, 'tvscreen').
--   · stash     secreter (small) y flightcase (medium): se abren al abrir el alijo.
--   · wardrobe  taquilla_gym: se abre al abrir el menú de ropa.
-- Los demás con partes se abren y se cierran con la E (Config.Animados, uso = 'E').
-- La bici de spinning y la rueda del hámster «giran»: el sistema de partes solo va
-- de cerrado a abierto, así que dan sus vueltas en unos segundos y se paran.
-- El precio es el provisional: config/zz_economia.lua lo multiplica por categoría.

local P = 'origen_casa_o2_'

local function M(id, precio, nombre, extra)
    local it = { model = P .. id, price = precio, nombre = nombre, label = nombre }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end

Config.Packs.Registrar({
    id = 'estudio_directo', nombre = 'Estudio y directo',
    descripcion = 'Para montar el despacho, el canal y el local de ensayo: escritorio de roble con cajones que se abren, mesa elevable que sube de verdad, secreter con tapa abatible que guarda cosas, escritorio de pared que se pliega y un puesto de streamer con pantalla que funciona; rack de servidores con puerta de cristal, impresora 3D, portátil que se abre, mueble con tele escamoteable, tele de pared y tele retro que se ven; cabina de DJ con luces, tocadiscos con tapa, torre de amplificador, flight case con almacenaje y mueble de vinilos; piano que se destapa, batería completa, soporte con tres guitarras y estuches de guitarra y de violín que se abren',
    xp = 450, grupo = 'muebles',
    categorias = {
        ['Escritorios'] = {
            M('escritorio_abatible', 2600, 'Escritorio abatible de pared'),
            M('escritorio_cajones', 3600, 'Escritorio de roble con tres cajones'),
            M('secreter', 4400, 'Secreter de nogal con tapa abatible', { type = 'stash', stash = 'small' }),
            M('escritorio_elevable', 5600, 'Escritorio elevable eléctrico'),
            M('escritorio_streamer', 12800, 'Puesto de streamer con pantalla y aro de luz', { type = 'tv' }),
        },
        ['Tecnología'] = {
            M('tele_retro', 2000, 'Tele retro de tubo con mesita', { type = 'tv' }),
            M('portatil_tapa', 2500, 'Portátil que se abre'),
            M('tele_pared', 3000, 'Tele de pared de 43"', { type = 'tv' }),
            M('impresora3d', 4000, 'Impresora 3D con puerta'),
            M('tele_escamoteable', 10000, 'Mueble con tele escamoteable'),
            M('rack_puerta', 16000, 'Armario rack de servidores con puerta de cristal'),
        },
        ['Música / DJ'] = {
            M('tocadiscos_tapa', 1500, 'Tocadiscos con tapa'),
            M('mueble_vinilos', 1750, 'Mueble de vinilos con cajones'),
            M('flightcase', 2000, 'Flight case de DJ con ruedas', { type = 'stash', stash = 'medium' }),
            M('ampli_torre', 2500, 'Torre de amplificador de guitarra'),
            M('cabina_dj', 7500, 'Cabina de DJ con frontal de luz'),
        },
        ['Instrumentos'] = {
            M('estuche_guitarra', 3000, 'Estuche con guitarra eléctrica'),
            M('violin_estuche', 3500, 'Violín en su estuche'),
            M('guitarras_soporte', 6000, 'Soporte con tres guitarras'),
            M('bateria', 8000, 'Batería acústica'),
            M('piano_tapa', 10000, 'Piano vertical lacado con tapa'),
        },
    },
    animados = {
        [P .. 'escritorio_abatible'] = { uso = 'E', texto = { 'Abrir la mesa', 'Recoger la mesa' }, partes = { { modelo = P .. 'escritorio_abatible_tablero', pos = { 0.000, -0.080, 0.020 }, modo = 'gira', eje = 'x', angulo = 90.0, ms = 900 } } },
        [P .. 'escritorio_cajones'] = { uso = 'E', texto = { 'Abrir los cajones', 'Cerrar los cajones' }, partes = { { modelo = P .. 'escritorio_cajones_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.16, ms = 600 }, { modelo = P .. 'escritorio_cajones_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.24, ms = 600 }, { modelo = P .. 'escritorio_cajones_cajon_c', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.32, ms = 600 } } },
        [P .. 'secreter'] = { uso = 'almacen', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'secreter_tapa', pos = { 0.000, -0.100, 0.765 }, modo = 'gira', eje = 'x', angulo = 88.0, ms = 900 } } },
        [P .. 'escritorio_elevable'] = { uso = 'E', texto = { 'Subir la mesa', 'Bajar la mesa' }, partes = { { modelo = P .. 'escritorio_elevable_tablero', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = 0.42, ms = 2600 } } },
        [P .. 'portatil_tapa'] = { uso = 'E', texto = { 'Abrir el portátil', 'Cerrar el portátil' }, partes = { { modelo = P .. 'portatil_tapa_tapa', pos = { 0.000, 0.118, 0.014 }, modo = 'gira', eje = 'x', angulo = -108.0, ms = 700 } } },
        [P .. 'impresora3d'] = { uso = 'E', texto = { 'Abrir la puerta', 'Cerrar la puerta' }, partes = { { modelo = P .. 'impresora3d_puerta', pos = { -0.200, -0.214, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 } } },
        [P .. 'tele_escamoteable'] = { uso = 'E', texto = { 'Subir la tele', 'Guardar la tele' }, partes = { { modelo = P .. 'tele_escamoteable_tele', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = 0.70, ms = 2400 } } },
        [P .. 'rack_puerta'] = { uso = 'E', texto = { 'Abrir la puerta', 'Cerrar la puerta' }, partes = { { modelo = P .. 'rack_puerta_puerta', pos = { 0.320, -0.380, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 600 } } },
        [P .. 'tocadiscos_tapa'] = { uso = 'E', texto = { 'Levantar la tapa', 'Bajar la tapa' }, partes = { { modelo = P .. 'tocadiscos_tapa_tapa', pos = { 0.000, 0.186, 0.088 }, modo = 'gira', eje = 'x', angulo = -72.0, ms = 800 } } },
        [P .. 'mueble_vinilos'] = { uso = 'E', texto = { 'Abrir los cajones', 'Cerrar los cajones' }, partes = { { modelo = P .. 'mueble_vinilos_cajon_izq', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.30, ms = 600 }, { modelo = P .. 'mueble_vinilos_cajon_der', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.22, ms = 600 } } },
        [P .. 'flightcase'] = { uso = 'almacen', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'flightcase_tapa', pos = { 0.000, 0.270, 0.470 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 800 } } },
        [P .. 'estuche_guitarra'] = { uso = 'E', texto = { 'Abrir el estuche', 'Cerrar el estuche' }, partes = { { modelo = P .. 'estuche_guitarra_tapa', pos = { 0.000, 0.220, 0.090 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 800 } } },
        [P .. 'violin_estuche'] = { uso = 'E', texto = { 'Abrir el estuche', 'Cerrar el estuche' }, partes = { { modelo = P .. 'violin_estuche_tapa', pos = { 0.000, 0.140, 0.070 }, modo = 'gira', eje = 'x', angulo = -98.0, ms = 800 } } },
        [P .. 'piano_tapa'] = { uso = 'E', texto = { 'Abrir el piano', 'Cerrar el piano' }, partes = { { modelo = P .. 'piano_tapa_tapa_teclado', pos = { 0.000, -0.130, 0.800 }, modo = 'gira', eje = 'x', angulo = -96.0, ms = 900 }, { modelo = P .. 'piano_tapa_tapa_arriba', pos = { 0.000, 0.300, 1.220 }, modo = 'gira', eje = 'x', angulo = -38.0, ms = 900 } } },
    },
})

Config.Packs.Registrar({
    id = 'ocio_mascotas', nombre = 'Ocio, deporte y mascotas',
    descripcion = 'El cuarto de juegos, el gimnasio y el rincón de los animales: casa de muñecas que se abre en dos hojas, mesa de ajedrez con cajón, tragaperras con palanca, cocinita con horno que se abre, canasta de baloncesto y tipi con cojines; taquilla de gimnasio que hace de ropero, jaula de sentadillas con barra olímpica, bicicleta de spinning con el volante que gira, máquina de remo con asiento que corre y dispensador de agua; caseta de perro, jaula de pájaros con puerta, terrario con cristal corredero, acuario con mueble, árbol rascador grande, jaula de hámster con rueda que gira, sofá de mascota y arenero con puerta batiente',
    xp = 400, grupo = 'muebles',
    categorias = {
        ['Juegos y juguetes'] = {
            M('tipi', 2000, 'Tipi infantil con cojines'),
            M('cocinita', 2500, 'Cocinita de juguete'),
            M('casa_munecas', 3000, 'Casa de muñecas'),
            M('canasta', 3000, 'Canasta de baloncesto con pie'),
            M('mesa_ajedrez', 4000, 'Mesa de ajedrez con cajón'),
            M('tragaperras', 15000, 'Tragaperras de palanca'),
        },
        ['Gimnasio'] = {
            M('fuente_agua', 1500, 'Dispensador de agua con botellón'),
            M('taquilla_gym', 2500, 'Taquilla doble de gimnasio', { type = 'wardrobe' }),
            M('bici_spinning', 5500, 'Bicicleta de spinning'),
            M('remo', 6500, 'Máquina de remo'),
            M('jaula_sentadillas', 9000, 'Jaula de sentadillas con barra olímpica'),
        },
        ['Mascotas'] = {
            M('arenero', 1600, 'Arenero cerrado con puerta'),
            M('jaula_hamster', 1800, 'Jaula de hámster con rueda'),
            M('sofa_mascota', 2400, 'Sofá de mascota capitoné'),
            M('caseta_perro', 2600, 'Caseta de perro de madera'),
            M('jaula_pajaro', 2800, 'Jaula de pájaros con pie'),
            M('arbol_gatos', 3200, 'Árbol rascador grande'),
            M('terrario', 6000, 'Terrario de reptil con mueble'),
            M('acuario_mueble', 10000, 'Acuario con mueble de nogal'),
        },
    },
    animados = {
        [P .. 'cocinita'] = { uso = 'E', texto = { 'Abrir el horno y el armario', 'Cerrar el horno y el armario' }, partes = { { modelo = P .. 'cocinita_puerta_armario', pos = { 0.394, -0.160, 0.000 }, modo = 'gira', eje = 'z', angulo = 100.0, ms = 600 }, { modelo = P .. 'cocinita_puerta_horno', pos = { 0.000, -0.160, 0.050 }, modo = 'gira', eje = 'x', angulo = 86.0, ms = 700 } } },
        [P .. 'casa_munecas'] = { uso = 'E', texto = { 'Abrir la casa', 'Cerrar la casa' }, partes = { { modelo = P .. 'casa_munecas_hoja_izq', pos = { -0.450, -0.200, 0.000 }, modo = 'gira', eje = 'z', angulo = -112.0, ms = 900 }, { modelo = P .. 'casa_munecas_hoja_der', pos = { 0.450, -0.200, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 900 } } },
        [P .. 'mesa_ajedrez'] = { uso = 'E', texto = { 'Abrir el cajón', 'Cerrar el cajón' }, partes = { { modelo = P .. 'mesa_ajedrez_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.26, ms = 600 } } },
        [P .. 'tragaperras'] = { uso = 'E', texto = { 'Tirar de la palanca', 'Soltar la palanca' }, partes = { { modelo = P .. 'tragaperras_palanca', pos = { 0.340, -0.040, 1.070 }, modo = 'gira', eje = 'x', angulo = 62.0, ms = 450 } } },
        [P .. 'taquilla_gym'] = { uso = 'ropero', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'taquilla_gym_puerta_izq', pos = { -0.320, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = -112.0, ms = 600 }, { modelo = P .. 'taquilla_gym_puerta_der', pos = { 0.320, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 600 } } },
        [P .. 'bici_spinning'] = { uso = 'E', texto = { 'Dar pedales', 'Parar' }, partes = { { modelo = P .. 'bici_spinning_volante', pos = { 0.000, -0.360, 0.300 }, modo = 'gira', eje = 'x', angulo = 3600.0, ms = 7000 } } },
        [P .. 'remo'] = { uso = 'E', texto = { 'Remar hacia atrás', 'Volver adelante' }, partes = { { modelo = P .. 'remo_asiento', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = 0.62, ms = 1400 } } },
        [P .. 'arenero'] = { uso = 'E', texto = { 'Abrir la puerta', 'Cerrar la puerta' }, partes = { { modelo = P .. 'arenero_puerta', pos = { 0.000, -0.203, 0.335 }, modo = 'gira', eje = 'x', angulo = -58.0, ms = 500 } } },
        [P .. 'jaula_hamster'] = { uso = 'E', texto = { 'Hacer girar la rueda', 'Parar la rueda' }, partes = { { modelo = P .. 'jaula_hamster_rueda', pos = { -0.140, -0.060, 0.200 }, modo = 'gira', eje = 'y', angulo = 2880.0, ms = 6000 } } },
        [P .. 'jaula_pajaro'] = { uso = 'E', texto = { 'Abrir la jaula', 'Cerrar la jaula' }, partes = { { modelo = P .. 'jaula_pajaro_puerta', pos = { 0.056, -0.182, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        [P .. 'terrario'] = { uso = 'E', texto = { 'Abrir el terrario', 'Cerrar el terrario' }, partes = { { modelo = P .. 'terrario_cristal', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.46, ms = 900 } } },
        [P .. 'acuario_mueble'] = { uso = 'E', texto = { 'Abrir el mueble', 'Cerrar el mueble' }, partes = { { modelo = P .. 'acuario_mueble_puerta_izq', pos = { -0.620, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = -100.0, ms = 600 }, { modelo = P .. 'acuario_mueble_puerta_der', pos = { 0.620, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = 100.0, ms = 600 } } },
    },
})
