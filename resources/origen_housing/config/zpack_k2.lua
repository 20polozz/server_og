-- Muebles propios de los packs «Cocina de chef» y «Despensa y bodega» (tanda 2).
-- Lo ESCRIBE fuente/pack_k2.py (lua=…): no tocarlo a mano; si se cambia un modelo, se vuelve a generar.
-- Modelos origen_casa_k2_*; quién mueve las partes: custom/client/almacenajes.lua con Config.Animados.
--   · `mueve = true`   el mueble tiene partes que se abren o se mueven
--   · `funcion = '…'`  lo que hace además de adornar (para enseñarlo en la tienda)
-- Neveras, despensa y estantería son almacenes (type = 'stash'): se abren al usarlos (uso = 'almacen').
-- Los de pared o techo (módulo alto, barra de utensilios, campana de isla) tienen el origen en su
-- canto de abajo: se colocan y se suben.

local P = 'origen_casa_k2_'

local function M(id, precio, nombre, extra)
    local it = { model = P .. id, price = precio, nombre = nombre, label = nombre }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end

Config.Packs.Registrar({
    id = 'cocina_chef', nombre = 'Cocina de chef',
    descripcion = 'La cocina de un restaurante en tu casa: módulos y cajoneras de acero, isla con tabla de carnicero, fogones de seis fuegos, horno doble, lavavajillas, cafetera de barista, amasadora, barbacoa de interior, máquina de hielo y siete neveras (puertas francesas, retro de dos puertas, expositor, arcón de bebidas, vinoteca, minibar). Casi todo se abre, y las neveras y la despensa guardan cosas de verdad',
    xp = 450, grupo = 'muebles',
    categorias = {
        ['Cocina'] = {
            M('ch_bajo', 3200, 'Módulo bajo de acero de dos puertas', { mueve = true }),
            M('ch_cajonera', 3600, 'Cajonera de acero de tres cajones', { mueve = true }),
            M('ch_fregadero', 5200, 'Fregadero doble de acero con grifo de ducha', { mueve = true }),
            M('ch_alto', 2900, 'Módulo alto de acero con puerta de cristal elevable', { mueve = true }),
            M('ch_isla', 16000, 'Isla de chef con tabla de carnicero y cajones', { mueve = true }),
            M('ch_despensa', 7500, 'Despensa de columna de acero (almacén)', { type = 'stash', stash = 'big', mueve = true, funcion = 'Almacén' }),
            M('ch_mesa', 4200, 'Mesa de trabajo de acero con balda'),
            M('ch_barra', 1900, 'Barra de pared con sartenes y utensilios'),
            M('ch_carro', 3400, 'Carro auxiliar de cocina con cajón', { mueve = true }),
            M('ch_estanteria', 4500, 'Estantería de despensa con conservas (almacén)', { type = 'stash', stash = 'normal', funcion = 'Almacén' }),
            M('olla_expres', 900, 'Olla exprés'),
        },
        ['Electrodomésticos'] = {
            M('fogones', 9500, 'Cocina profesional de seis fuegos con horno', { mueve = true }),
            M('horno_doble', 11000, 'Columna de horno doble', { mueve = true }),
            M('micro', 2400, 'Microondas de acero con grill', { mueve = true }),
            M('lavavajillas', 6200, 'Lavavajillas de acero de dos cestas', { mueve = true }),
            M('campana_isla', 5800, 'Campana de isla de techo'),
            M('cafetera_barista', 6800, 'Cafetera de barista de dos grupos con molinillo'),
            M('amasadora', 2600, 'Amasadora de varillas color crema', { mueve = true }),
            M('freidora', 2200, 'Freidora de aire', { mueve = true }),
            M('dispensador_agua', 2800, 'Dispensador de agua con garrafa'),
            M('barbacoa', 5200, 'Barbacoa de interior con tapa', { mueve = true }),
            M('maquina_hielo', 4800, 'Máquina de hielo', { mueve = true }),
        },
        ['Neveras'] = {
            M('nevera_francesa', 19000, 'Nevera de acero de puertas francesas (almacén)', { type = 'stash', stash = 'extrabig', mueve = true, funcion = 'Almacén' }),
            M('nevera_retro_crema', 9500, 'Nevera retro de dos puertas, crema (almacén)', { type = 'stash', stash = 'big', mueve = true, funcion = 'Almacén' }),
            M('nevera_retro_azul', 9500, 'Nevera retro de dos puertas, azul cielo (almacén)', { type = 'stash', stash = 'big', mueve = true, funcion = 'Almacén' }),
            M('arcon_bebidas', 8500, 'Arcón de bebidas con tapas de cristal (almacén)', { type = 'stash', stash = 'big', mueve = true, funcion = 'Almacén' }),
            M('expositor', 11000, 'Nevera expositora de bebidas (almacén)', { type = 'stash', stash = 'big', mueve = true, funcion = 'Almacén' }),
            M('minibar', 4200, 'Minibar de cristal negro (almacén)', { type = 'stash', stash = 'normal', mueve = true, funcion = 'Almacén' }),
            M('vinoteca_doble', 14000, 'Vinoteca de columna de dos zonas (almacén)', { type = 'stash', stash = 'big', mueve = true, funcion = 'Almacén' }),
        },
    },
    animados = {
        [P .. 'ch_bajo'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'ch_bajo_puerta_i', pos = { -0.400, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = -108.0, ms = 600 }, { modelo = P .. 'ch_bajo_puerta_d', pos = { 0.400, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 108.0, ms = 600 } } },
        [P .. 'ch_cajonera'] = { uso = 'E', texto = { 'Abrir los cajones', 'Cerrar los cajones' }, partes = { { modelo = P .. 'ch_cajonera_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.38, ms = 600 }, { modelo = P .. 'ch_cajonera_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.38, ms = 600 }, { modelo = P .. 'ch_cajonera_cajon_c', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.38, ms = 600 } } },
        [P .. 'ch_fregadero'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'ch_fregadero_puerta_i', pos = { -0.600, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = -108.0, ms = 600 }, { modelo = P .. 'ch_fregadero_puerta_d', pos = { 0.600, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 108.0, ms = 600 } } },
        [P .. 'ch_alto'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'ch_alto_puerta', pos = { 0.000, -0.160, 0.598 }, modo = 'gira', eje = 'x', angulo = -98.0, ms = 700 } } },
        [P .. 'ch_isla'] = { uso = 'E', texto = { 'Abrir los cajones', 'Cerrar los cajones' }, partes = { { modelo = P .. 'ch_isla_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.44, ms = 600 }, { modelo = P .. 'ch_isla_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.44, ms = 600 }, { modelo = P .. 'ch_isla_cajon_c', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.44, ms = 600 }, { modelo = P .. 'ch_isla_cajon_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.44, ms = 600 } } },
        [P .. 'ch_despensa'] = { uso = 'almacen', partes = { { modelo = P .. 'ch_despensa_puerta_i', pos = { -0.450, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = -112.0, ms = 700 }, { modelo = P .. 'ch_despensa_puerta_d', pos = { 0.450, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 700 } } },
        [P .. 'ch_carro'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'ch_carro_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.30, ms = 600 } } },
        [P .. 'fogones'] = { uso = 'E', texto = { 'Abrir el horno', 'Cerrar el horno' }, partes = { { modelo = P .. 'fogones_puerta', pos = { 0.000, -0.330, 0.200 }, modo = 'gira', eje = 'x', angulo = 88.0, ms = 800 } } },
        [P .. 'horno_doble'] = { uso = 'E', texto = { 'Abrir los hornos', 'Cerrar los hornos' }, partes = { { modelo = P .. 'horno_doble_puerta_a', pos = { 0.000, -0.280, 1.334 }, modo = 'gira', eje = 'x', angulo = 88.0, ms = 800 }, { modelo = P .. 'horno_doble_puerta_b', pos = { 0.000, -0.280, 0.714 }, modo = 'gira', eje = 'x', angulo = 88.0, ms = 800 } } },
        [P .. 'micro'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'micro_puerta', pos = { -0.268, -0.180, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 } } },
        [P .. 'lavavajillas'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'lavavajillas_cesta_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.42, ms = 1100 }, { modelo = P .. 'lavavajillas_cesta_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.50, ms = 1100 }, { modelo = P .. 'lavavajillas_puerta', pos = { 0.000, -0.280, 0.100 }, modo = 'gira', eje = 'x', angulo = 90.0, ms = 800 } } },
        [P .. 'amasadora'] = { uso = 'E', texto = { 'Levantar el cabezal', 'Bajar el cabezal' }, partes = { { modelo = P .. 'amasadora_cabezal', pos = { 0.000, 0.130, 0.270 }, modo = 'gira', eje = 'x', angulo = -42.0, ms = 700 } } },
        [P .. 'freidora'] = { uso = 'E', texto = { 'Sacar la cubeta', 'Meter la cubeta' }, partes = { { modelo = P .. 'freidora_cubeta', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.24, ms = 600 } } },
        [P .. 'barbacoa'] = { uso = 'E', texto = { 'Levantar la tapa', 'Bajar la tapa' }, partes = { { modelo = P .. 'barbacoa_tapa', pos = { 0.000, 0.260, 0.800 }, modo = 'gira', eje = 'x', angulo = -78.0, ms = 800 } } },
        [P .. 'maquina_hielo'] = { uso = 'E', texto = { 'Abrir la tapa', 'Cerrar la tapa' }, partes = { { modelo = P .. 'maquina_hielo_tapa', pos = { 0.000, 0.020, 0.920 }, modo = 'gira', eje = 'x', angulo = -80.0, ms = 700 } } },
        [P .. 'nevera_francesa'] = { uso = 'almacen', partes = { { modelo = P .. 'nevera_francesa_puerta_i', pos = { -0.460, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = -118.0, ms = 800 }, { modelo = P .. 'nevera_francesa_puerta_d', pos = { 0.460, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = 118.0, ms = 800 }, { modelo = P .. 'nevera_francesa_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.46, ms = 900 } } },
        [P .. 'nevera_retro_crema'] = { uso = 'almacen', partes = { { modelo = P .. 'nevera_retro_crema_puerta_a', pos = { 0.310, -0.270, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 800 }, { modelo = P .. 'nevera_retro_crema_puerta_b', pos = { 0.310, -0.270, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 800 } } },
        [P .. 'nevera_retro_azul'] = { uso = 'almacen', partes = { { modelo = P .. 'nevera_retro_azul_puerta_a', pos = { 0.310, -0.270, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 800 }, { modelo = P .. 'nevera_retro_azul_puerta_b', pos = { 0.310, -0.270, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 800 } } },
        [P .. 'arcon_bebidas'] = { uso = 'almacen', partes = { { modelo = P .. 'arcon_bebidas_tapa', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.48, ms = 800 } } },
        [P .. 'expositor'] = { uso = 'almacen', partes = { { modelo = P .. 'expositor_puerta', pos = { 0.320, -0.290, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 800 } } },
        [P .. 'minibar'] = { uso = 'almacen', partes = { { modelo = P .. 'minibar_puerta', pos = { 0.240, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 700 } } },
        [P .. 'vinoteca_doble'] = { uso = 'almacen', partes = { { modelo = P .. 'vinoteca_doble_puerta', pos = { 0.300, -0.290, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 800 } } },
    },
})

Config.Packs.Registrar({
    id = 'despensa_bodega', nombre = 'Despensa y bodega',
    descripcion = 'Para recibir como se debe: barril de roble con su grifo, mueble bar de nogal, botellero, carrito de bebidas, torre de cerveza, cubitera con champán, licorera y caja de vino; y para picar, jamón en su jamonero, tabla de embutidos, cesta de fruta, panera, tarros de despensa, caja de verduras y bombones',
    xp = 350, grupo = 'muebles',
    categorias = {
        ['Bebidas'] = {
            M('barril', 4200, 'Barril de roble con grifo', { mueve = true }),
            M('mueble_bar', 7800, 'Mueble bar de nogal con espejo', { mueve = true }),
            M('botellero', 4800, 'Botellero de roble con veinte botellas'),
            M('carrito_bebidas', 5200, 'Carrito de bebidas de latón y cristal'),
            M('cubitera', 1600, 'Cubitera con champán y dos copas'),
            M('grifo_cerveza', 3800, 'Torre de tres grifos de cerveza', { mueve = true }),
            M('caja_vino', 1800, 'Caja de vino de madera con tres botellas', { mueve = true }),
            M('licorera', 1900, 'Licorera de cristal con vasos'),
            M('caja_cervezas', 900, 'Caja de cervezas con botellines'),
        },
        ['Comida'] = {
            M('tabla_embutidos', 1200, 'Tabla de embutidos'),
            M('jamonero', 2400, 'Jamón en su jamonero'),
            M('cesta_fruta', 1100, 'Cesta de mimbre con fruta'),
            M('panera', 1300, 'Panera de roble con tapa', { mueve = true }),
            M('tarros', 900, 'Tarros de despensa'),
            M('caja_verduras', 1000, 'Caja de verduras del mercado'),
            M('bombones', 700, 'Caja de bombones', { mueve = true }),
        },
    },
    animados = {
        [P .. 'barril'] = { uso = 'E', texto = { 'Abrir el grifo', 'Cerrar el grifo' }, partes = { { modelo = P .. 'barril_grifo', pos = { 0.000, -0.414, 0.414 }, modo = 'gira', eje = 'z', angulo = 90.0, ms = 400 } } },
        [P .. 'mueble_bar'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'mueble_bar_puerta_i', pos = { -0.470, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = P .. 'mueble_bar_puerta_d', pos = { 0.470, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        [P .. 'grifo_cerveza'] = { uso = 'E', texto = { 'Tirar una caña', 'Cerrar los grifos' }, partes = { { modelo = P .. 'grifo_cerveza_tiradores', pos = { 0.000, -0.050, 0.415 }, modo = 'gira', eje = 'x', angulo = 32.0, ms = 400 } } },
        [P .. 'caja_vino'] = { uso = 'E', texto = { 'Abrir la caja', 'Cerrar la caja' }, partes = { { modelo = P .. 'caja_vino_tapa', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.26, ms = 600 } } },
        [P .. 'panera'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'panera_tapa', pos = { 0.000, 0.030, 0.030 }, modo = 'gira', eje = 'x', angulo = -80.0, ms = 700 } } },
        [P .. 'bombones'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'bombones_tapa', pos = { 0.000, 0.100, 0.035 }, modo = 'gira', eje = 'x', angulo = -110.0, ms = 600 } } },
    },
})
