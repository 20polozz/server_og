-- Roperos y armeros propios, con partes que se abren (modelos: fuente/roperos.py;
-- quién las mueve: custom/client/almacenajes.lua). Tres packs:
--   base       los tres roperos sencillos que tiene cualquier casa
--   vestidor   los roperos buenos
--   armeria    armeros (son almacenajes: type = 'stash', con los tamaños de config/stashes.lua)
-- Las medidas de las partes las escribe fuente/roperos.py al acabar (líneas
-- «LUA»): si se cambia un modelo, aquí también. El burro perchero no tiene
-- puertas: no lleva partes ni se anima.
-- Los siete roperos del juego que había en «Armarios» ya no se venden; los
-- colocados siguen valiendo (Config.Almacenajes.antiguos, config/almacenajes.lua).

Config.Packs.Registrar({
    id = 'base',
    categorias = {
        ['Armarios'] = {
            { model = 'origen_casa_rop_viejo', price = 1500, nombre = 'Armario viejo', label = 'Armario viejo', type = 'wardrobe' },
            { model = 'origen_casa_rop_burro', price = 1800, nombre = 'Burro perchero', label = 'Burro perchero', type = 'wardrobe' },
            { model = 'origen_casa_rop_rustico', price = 2800, nombre = 'Armario rústico de pino', label = 'Armario rústico de pino', type = 'wardrobe' },
        },
    },
    animados = {
        ['origen_casa_rop_viejo'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_viejo_puerta_i', pos = { -0.500, -0.260, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_rop_viejo_puerta_d', pos = { 0.500, -0.260, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_rop_rustico'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_rustico_puerta_i', pos = { -0.550, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_rop_rustico_puerta_d', pos = { 0.550, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
    },
})

Config.Packs.Registrar({
    id = 'vestidor', nombre = 'Vestidor',
    descripcion = 'Roperos de diseño que se abren de verdad: de caoba tallada, lacados, de correderas, empotrados y de lujo con luz',
    xp = 0,
    categorias = {
        ['Armarios'] = {
            { model = 'origen_casa_rop_gimnasio', price = 2500, nombre = 'Taquilla doble de gimnasio', label = 'Taquilla doble de gimnasio', type = 'wardrobe' },
            { model = 'origen_casa_rop_infantil', price = 2800, nombre = 'Armario infantil', label = 'Armario infantil', type = 'wardrobe' },
            { model = 'origen_casa_rop_militar', price = 3000, nombre = 'Armario metálico militar', label = 'Armario metálico militar', type = 'wardrobe' },
            { model = 'origen_casa_rop_chiffonier', price = 3500, nombre = 'Chiffonier de nogal', label = 'Chiffonier de nogal', type = 'wardrobe' },
            { model = 'origen_casa_rop_lacado', price = 4500, nombre = 'Armario blanco lacado', label = 'Armario blanco lacado', type = 'wardrobe' },
            { model = 'origen_casa_rop_clasico', price = 6000, nombre = 'Armario clásico de caoba', label = 'Armario clásico de caoba', type = 'wardrobe' },
            { model = 'origen_casa_rop_baul_viaje', price = 7500, nombre = 'Baúl ropero de viaje', label = 'Baúl ropero de viaje', type = 'wardrobe' },
            { model = 'origen_casa_rop_tres_puertas', price = 8000, nombre = 'Armario de tres puertas con espejo', label = 'Armario de tres puertas con espejo', type = 'wardrobe' },
            { model = 'origen_casa_rop_corredera', price = 9500, nombre = 'Armario de puertas correderas', label = 'Armario de puertas correderas', type = 'wardrobe' },
            { model = 'origen_casa_rop_empotrado', price = 14000, nombre = 'Armario empotrado de cuatro puertas', label = 'Armario empotrado de cuatro puertas', type = 'wardrobe' },
            { model = 'origen_casa_rop_lujo', price = 25000, nombre = 'Armario de lujo con luz interior', label = 'Armario de lujo con luz interior', type = 'wardrobe' },
        },
    },
    animados = {
        ['origen_casa_rop_gimnasio'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_gimnasio_puerta_i', pos = { 0.000, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 }, { modelo = 'origen_casa_rop_gimnasio_puerta_d', pos = { 0.320, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_rop_infantil'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_infantil_puerta_i', pos = { -0.450, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_rop_infantil_puerta_d', pos = { 0.450, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_rop_militar'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_militar_puerta_i', pos = { -0.475, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_rop_militar_puerta_d', pos = { 0.475, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_rop_chiffonier'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_chiffonier_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.20, ms = 600 }, { modelo = 'origen_casa_rop_chiffonier_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.30, ms = 600 } } },
        ['origen_casa_rop_lacado'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_lacado_puerta_i', pos = { -0.600, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_rop_lacado_puerta_d', pos = { 0.600, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_rop_clasico'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_clasico_puerta_i', pos = { -0.600, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_rop_clasico_puerta_d', pos = { 0.600, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_rop_baul_viaje'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_baul_viaje_mitad', pos = { 0.310, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = 120.0, ms = 900 } } },
        ['origen_casa_rop_tres_puertas'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_tres_puertas_puerta_i', pos = { -0.840, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_rop_tres_puertas_puerta_c', pos = { -0.280, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_rop_tres_puertas_puerta_d', pos = { 0.840, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_rop_corredera'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_corredera_hoja', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.84, ms = 900 } } },
        ['origen_casa_rop_empotrado'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_empotrado_puerta_a', pos = { -1.200, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_rop_empotrado_puerta_b', pos = { 0.000, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 }, { modelo = 'origen_casa_rop_empotrado_puerta_c', pos = { 0.000, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_rop_empotrado_puerta_d', pos = { 1.200, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_rop_lujo'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_rop_lujo_puerta_i', pos = { -0.800, -0.310, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_rop_lujo_puerta_d', pos = { 0.800, -0.310, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
    },
})

Config.Packs.Registrar({
    id = 'armeria', nombre = 'Armería',
    descripcion = 'Armeros con las armas a la vista: vitrina de caza, taquilla, cofre blindado, banco de armero, armario táctico y caja fuerte de armas',
    xp = 0,
    categorias = {
        ['Armeros'] = {
            { model = 'origen_casa_alm_armero_pared', price = 6000, nombre = 'Vitrina de armas de pared', label = 'Vitrina de armas de pared', type = 'stash', stash = 'normal' },
            { model = 'origen_casa_alm_armero_taquilla', price = 5500, nombre = 'Taquilla de armas', label = 'Taquilla de armas', type = 'stash', stash = 'medium' },
            { model = 'origen_casa_alm_armero_cofre', price = 7000, nombre = 'Cofre blindado de armas', label = 'Cofre blindado de armas', type = 'stash', stash = 'big' },
            { model = 'origen_casa_alm_armero_banco', price = 9000, nombre = 'Banco de armero', label = 'Banco de armero', type = 'stash', stash = 'big' },
            { model = 'origen_casa_alm_armero_tactico', price = 16000, nombre = 'Armario táctico', label = 'Armario táctico', type = 'stash', stash = 'extrabig' },
            { model = 'origen_casa_alm_armero_seguridad', price = 22000, nombre = 'Caja fuerte de armas', label = 'Caja fuerte de armas', type = 'stash', stash = 'extrabig' },
        },
    },
    iconos = { ['Armeros'] = 'fas fa-crosshairs' },
    animados = {
        ['origen_casa_alm_armero_pared'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_alm_armero_pared_puerta', pos = { -0.430, -0.130, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 } } },
        ['origen_casa_alm_armero_taquilla'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_alm_armero_taquilla_puerta', pos = { 0.230, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 600 } } },
        ['origen_casa_alm_armero_cofre'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_alm_armero_cofre_tapa', pos = { 0.000, 0.250, 0.240 }, modo = 'gira', eje = 'x', angulo = -95.0, ms = 700 } } },
        ['origen_casa_alm_armero_banco'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_alm_armero_banco_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.42, ms = 700 } } },
        ['origen_casa_alm_armero_tactico'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_alm_armero_tactico_puerta_i', pos = { -0.550, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = -110.0, ms = 600 }, { modelo = 'origen_casa_alm_armero_tactico_puerta_d', pos = { 0.550, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 600 } } },
        ['origen_casa_alm_armero_seguridad'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_alm_armero_seguridad_puerta', pos = { 0.400, -0.310, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 800 } } },
    },
})
