-- Pack de BAÑO: sanitarios y muebles de baño propios (modelos: fuente/pack_ban.py;
-- las partes que se mueven las lleva custom/client/almacenajes.lua por Config.Animados). Tres packs:
--   base        un inodoro, un lavabo y una ducha sencillos, que tiene cualquier casa
--   bano        el baño completo (y lo viejo para pisos francos)
--   bano_lujo   mármol, latón, bañeras exentas, jacuzzi y sauna
-- Lo de pared (espejos, toallero, radiador, urinario, columna) lleva el origen en el
-- suelo y su altura de montaje ya puesta: se deja en el suelo contra la pared.
-- Las medidas de las partes las escribe fuente/pack_ban.py al acabar (líneas
-- «LUA»): si se cambia un modelo, aquí también. Precios provisionales.

Config.Packs.Registrar({
    id = 'base',
    categorias = {
        ['Baño'] = {
            { model = 'origen_casa_ban_inodoro', price = 1500, nombre = 'Inodoro con cisterna', label = 'Inodoro con cisterna' },
            { model = 'origen_casa_ban_lavabo_pedestal', price = 1500, nombre = 'Lavabo de pedestal', label = 'Lavabo de pedestal' },
            { model = 'origen_casa_ban_ducha_plato', price = 3500, nombre = 'Plato de ducha con mampara', label = 'Plato de ducha con mampara' },
        },
    },
    animados = {
        ['origen_casa_ban_inodoro'] = { uso = 'E', texto = { 'Levantar la tapa', 'Bajar la tapa' }, partes = { { modelo = 'origen_casa_ban_inodoro_tapa', pos = { 0.000, 0.102, 0.422 }, modo = 'gira', eje = 'x', angulo = -92.0, ms = 500 } } },
        ['origen_casa_ban_ducha_plato'] = { uso = 'E', texto = { 'Abrir la mampara', 'Cerrar la mampara' }, partes = { { modelo = 'origen_casa_ban_ducha_plato_hoja', pos = { 0.428, -0.430, 0.000 }, modo = 'gira', eje = 'z', angulo = 95.0, ms = 700 } } },
    },
})

Config.Packs.Registrar({
    id = 'bano', nombre = 'Baño completo',
    descripcion = 'Sanitarios, lavabos con mueble, cabina de ducha, bañera y todos los accesorios: las tapas, las puertas, los cajones y las mamparas se abren de verdad',
    xp = 0,
    categorias = {
        ['Baño'] = {
            { model = 'origen_casa_ban_lavabo_viejo', price = 1500, nombre = 'Lavabo viejo de pared', label = 'Lavabo viejo de pared' },
            { model = 'origen_casa_ban_inodoro_viejo', price = 1800, nombre = 'Inodoro viejo de cisterna alta', label = 'Inodoro viejo de cisterna alta' },
            { model = 'origen_casa_ban_bide', price = 1800, nombre = 'Bidé', label = 'Bidé' },
            { model = 'origen_casa_ban_urinario', price = 2000, nombre = 'Urinario de pared', label = 'Urinario de pared' },
            { model = 'origen_casa_ban_lavabo_mueble', price = 3500, nombre = 'Mueble de lavabo de dos puertas', label = 'Mueble de lavabo de dos puertas' },
            { model = 'origen_casa_ban_lavabo_cajones', price = 4500, nombre = 'Lavabo suspendido de roble con cajones', label = 'Lavabo suspendido de roble con cajones' },
            { model = 'origen_casa_ban_espejo_marco', price = 1500, nombre = 'Espejo de baño con repisa', label = 'Espejo de baño con repisa' },
            { model = 'origen_casa_ban_armario_espejo', price = 2800, nombre = 'Armario de baño con espejo', label = 'Armario de baño con espejo' },
            { model = 'origen_casa_ban_columna', price = 4000, nombre = 'Columna de ducha de hidromasaje', label = 'Columna de ducha de hidromasaje' },
            { model = 'origen_casa_ban_ducha_esquina', price = 6000, nombre = 'Cabina de ducha de esquina', label = 'Cabina de ducha de esquina' },
            { model = 'origen_casa_ban_banera', price = 5500, nombre = 'Bañera con faldón', label = 'Bañera con faldón' },
            { model = 'origen_casa_ban_toallero', price = 1500, nombre = 'Toallero de barra con toallas', label = 'Toallero de barra con toallas' },
            { model = 'origen_casa_ban_radiador', price = 2500, nombre = 'Radiador toallero', label = 'Radiador toallero' },
            { model = 'origen_casa_ban_estanteria', price = 2500, nombre = 'Estantería de baño con toallas', label = 'Estantería de baño con toallas' },
            { model = 'origen_casa_ban_cesto', price = 1800, nombre = 'Cesto de la ropa de cuero', label = 'Cesto de la ropa de cuero' },
            { model = 'origen_casa_ban_alfombrilla', price = 1000, nombre = 'Alfombrilla de baño', label = 'Alfombrilla de baño' },
            { model = 'origen_casa_ban_portarrollos', price = 1500, nombre = 'Portarrollos de pie con escobilla', label = 'Portarrollos de pie con escobilla' },
            { model = 'origen_casa_ban_banqueta', price = 1500, nombre = 'Banqueta de listones', label = 'Banqueta de listones' },
        },
    },
    animados = {
        ['origen_casa_ban_inodoro_viejo'] = { uso = 'E', texto = { 'Levantar la tapa', 'Bajar la tapa' }, partes = { { modelo = 'origen_casa_ban_inodoro_viejo_tapa', pos = { 0.000, 0.112, 0.422 }, modo = 'gira', eje = 'x', angulo = -96.0, ms = 500 } } },
        ['origen_casa_ban_lavabo_mueble'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_ban_lavabo_mueble_puerta_i', pos = { -0.400, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_ban_lavabo_mueble_puerta_d', pos = { 0.400, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_ban_lavabo_cajones'] = { uso = 'E', texto = { 'Abrir los cajones', 'Cerrar los cajones' }, partes = { { modelo = 'origen_casa_ban_lavabo_cajones_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.30, ms = 550 }, { modelo = 'origen_casa_ban_lavabo_cajones_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.30, ms = 550 } } },
        ['origen_casa_ban_armario_espejo'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_ban_armario_espejo_puerta_i', pos = { -0.360, -0.062, 0.000 }, modo = 'gira', eje = 'z', angulo = -110.0, ms = 500 }, { modelo = 'origen_casa_ban_armario_espejo_puerta_d', pos = { 0.360, -0.062, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 500 } } },
        ['origen_casa_ban_ducha_esquina'] = { uso = 'E', texto = { 'Abrir la mampara', 'Cerrar la mampara' }, partes = { { modelo = 'origen_casa_ban_ducha_esquina_hoja_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = 0.40, ms = 800 }, { modelo = 'origen_casa_ban_ducha_esquina_hoja_f', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.40, ms = 800 } } },
        ['origen_casa_ban_cesto'] = { uso = 'E', texto = { 'Abrir el cesto', 'Cerrar el cesto' }, partes = { { modelo = 'origen_casa_ban_cesto_tapa', pos = { 0.000, 0.175, 0.547 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 600 } } },
    },
})

Config.Packs.Registrar({
    id = 'bano_lujo', nombre = 'Baño de lujo',
    descripcion = 'Mármol, latón y nogal: lavabo doble, ducha de obra, bañeras exentas, espejos con luz, jacuzzi y sauna',
    xp = 0,
    categorias = {
        ['Baño'] = {
            { model = 'origen_casa_ban_espejo_led', price = 8000, nombre = 'Espejo redondo con luz LED', label = 'Espejo redondo con luz LED' },
            { model = 'origen_casa_ban_espejo_camerino', price = 9000, nombre = 'Espejo de camerino con bombillas', label = 'Espejo de camerino con bombillas' },
            { model = 'origen_casa_ban_inodoro_susp', price = 9000, nombre = 'Inodoro suspendido con bastidor de mármol', label = 'Inodoro suspendido con bastidor de mármol' },
            { model = 'origen_casa_ban_lavabo_piedra', price = 9500, nombre = 'Lavabo de cuenco sobre mármol', label = 'Lavabo de cuenco sobre mármol' },
            { model = 'origen_casa_ban_banera_patas', price = 14000, nombre = 'Bañera de patas de fundición', label = 'Bañera de patas de fundición' },
            { model = 'origen_casa_ban_lavabo_doble', price = 16000, nombre = 'Lavabo doble de nogal y mármol negro', label = 'Lavabo doble de nogal y mármol negro' },
            { model = 'origen_casa_ban_banera_lujo', price = 18000, nombre = 'Bañera exenta de diseño', label = 'Bañera exenta de diseño' },
            { model = 'origen_casa_ban_ducha_obra', price = 22000, nombre = 'Ducha de obra de mármol', label = 'Ducha de obra de mármol' },
            { model = 'origen_casa_ban_jacuzzi', price = 38000, nombre = 'Jacuzzi de cuatro plazas', label = 'Jacuzzi de cuatro plazas' },
            { model = 'origen_casa_ban_sauna', price = 40000, nombre = 'Sauna de madera', label = 'Sauna de madera' },
        },
    },
    animados = {
        ['origen_casa_ban_inodoro_susp'] = { uso = 'E', texto = { 'Levantar la tapa', 'Bajar la tapa' }, partes = { { modelo = 'origen_casa_ban_inodoro_susp_tapa', pos = { 0.000, 0.172, 0.442 }, modo = 'gira', eje = 'x', angulo = -90.0, ms = 500 } } },
        ['origen_casa_ban_lavabo_doble'] = { uso = 'E', texto = { 'Abrir los cajones', 'Cerrar los cajones' }, partes = { { modelo = 'origen_casa_ban_lavabo_doble_cajon_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.34, ms = 600 }, { modelo = 'origen_casa_ban_lavabo_doble_cajon_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.34, ms = 600 } } },
        ['origen_casa_ban_sauna'] = { uso = 'E', texto = { 'Abrir la puerta', 'Cerrar la puerta' }, partes = { { modelo = 'origen_casa_ban_sauna_puerta', pos = { 0.800, -0.720, 0.000 }, modo = 'gira', eje = 'z', angulo = 100.0, ms = 800 } } },
    },
})
