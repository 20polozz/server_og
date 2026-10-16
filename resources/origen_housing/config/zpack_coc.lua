-- Cocina y electrodomésticos propios, con partes que se abren (modelos: fuente/pack_coc.py,
-- que ESCRIBE este fichero: no tocarlo a mano; quién las mueve: custom/client/almacenajes.lua).
--   base                la cocina básica (módulo, fregadero y placa) y una nevera blanca
--   cocina_moderna      módulos blancos y antracita, isla, península y comedor de nogal
--   cocina_rustica      módulos verde salvia con madera y latón, y comedor de roble
--   electrodomesticos   frigoríficos, congelador, vinoteca, horno, lavadora…
-- Los módulos miden 0,60 x 0,60 (los altos, 0,35 de fondo) y casan en fila.
-- Neveras, congelador, columnas despensa y aparador son almacenes (type = 'stash').

Config.Packs.Registrar({
    id = 'base',
    categorias = {
        ['Cocina'] = {
            { model = 'origen_casa_coc_b_bajo', price = 1500, nombre = 'Módulo bajo con puerta', label = 'Módulo bajo con puerta' },
            { model = 'origen_casa_coc_b_fregadero', price = 2200, nombre = 'Módulo con fregadero', label = 'Módulo con fregadero' },
            { model = 'origen_casa_coc_b_placa', price = 2500, nombre = 'Módulo con placa de gas', label = 'Módulo con placa de gas' },
        },
        ['Neveras'] = {
            { model = 'origen_casa_coc_e_nevera_basica', price = 2500, nombre = 'Nevera blanca de dos puertas', label = 'Nevera blanca de dos puertas', type = 'stash', stash = 'normal' },
        },
    },
    iconos = { ['Cocina'] = 'fas fa-blender', ['Neveras'] = 'fas fa-utensils' },
    animados = {
        ['origen_casa_coc_b_bajo'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_b_bajo_puerta', pos = { 0.300, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_coc_b_fregadero'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_b_fregadero_puerta', pos = { 0.300, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_coc_b_placa'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_b_placa_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.22, ms = 600 }, { modelo = 'origen_casa_coc_b_placa_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.36, ms = 700 } } },
        ['origen_casa_coc_e_nevera_basica'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_coc_e_nevera_basica_puerta_a', pos = { 0.275, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 600 }, { modelo = 'origen_casa_coc_e_nevera_basica_puerta_b', pos = { 0.275, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 700 } } },
    },
})

Config.Packs.Registrar({
    id = 'cocina_moderna', nombre = 'Cocina moderna',
    descripcion = 'Cocina modular blanca y antracita con encimera de piedra: módulos que casan en fila, isla, península, columna despensa y comedor de nogal. Todo se abre',
    xp = 0,
    categorias = {
        ['Cocina'] = {
            { model = 'origen_casa_coc_m_bajo', price = 2200, nombre = 'Módulo bajo con puerta (moderna)', label = 'Módulo bajo con puerta (moderna)' },
            { model = 'origen_casa_coc_m_cajonera', price = 2800, nombre = 'Cajonera de cocina (moderna)', label = 'Cajonera de cocina (moderna)' },
            { model = 'origen_casa_coc_m_esquina', price = 1800, nombre = 'Módulo de esquina (moderna)', label = 'Módulo de esquina (moderna)' },
            { model = 'origen_casa_coc_m_fregadero', price = 3500, nombre = 'Módulo con fregadero (moderna)', label = 'Módulo con fregadero (moderna)' },
            { model = 'origen_casa_coc_m_placa', price = 4200, nombre = 'Módulo con placa de inducción (moderna)', label = 'Módulo con placa de inducción (moderna)' },
            { model = 'origen_casa_coc_m_horno', price = 5200, nombre = 'Módulo con horno (moderna)', label = 'Módulo con horno (moderna)' },
            { model = 'origen_casa_coc_m_alto', price = 1900, nombre = 'Módulo alto de pared (moderna)', label = 'Módulo alto de pared (moderna)' },
            { model = 'origen_casa_coc_m_columna', price = 4800, nombre = 'Columna despensa (moderna)', label = 'Columna despensa (moderna)', type = 'stash', stash = 'big' },
            { model = 'origen_casa_coc_m_remate', price = 1600, nombre = 'Remate de estantes (moderna)', label = 'Remate de estantes (moderna)' },
            { model = 'origen_casa_coc_m_isla', price = 14000, nombre = 'Isla de cocina (moderna)', label = 'Isla de cocina (moderna)' },
            { model = 'origen_casa_coc_m_peninsula', price = 9500, nombre = 'Península con barra (moderna)', label = 'Península con barra (moderna)' },
        },
        ['Mesas'] = {
            { model = 'origen_casa_coc_c_mesa', price = 5500, nombre = 'Mesa de comedor de nogal (4 plazas)', label = 'Mesa de comedor de nogal (4 plazas)' },
            { model = 'origen_casa_coc_c_mesa_grande', price = 9000, nombre = 'Mesa de comedor de nogal (8 plazas)', label = 'Mesa de comedor de nogal (8 plazas)' },
        },
        ['Sillas'] = {
            { model = 'origen_casa_coc_m_taburete', price = 1500, nombre = 'Taburete de barra (moderna)', label = 'Taburete de barra (moderna)' },
            { model = 'origen_casa_coc_c_silla', price = 1600, nombre = 'Silla de comedor de cuero', label = 'Silla de comedor de cuero' },
        },
        ['Muebles'] = {
            { model = 'origen_casa_coc_c_aparador', price = 6500, nombre = 'Aparador de comedor de nogal', label = 'Aparador de comedor de nogal', type = 'stash', stash = 'big' },
        },
    },
    iconos = { ['Cocina'] = 'fas fa-blender', ['Mesas'] = 'fas fa-table', ['Sillas'] = 'fas fa-chair', ['Muebles'] = 'fas fa-couch' },
    animados = {
        ['origen_casa_coc_m_bajo'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_m_bajo_puerta', pos = { 0.300, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_coc_m_cajonera'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_m_cajonera_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.16, ms = 500 }, { modelo = 'origen_casa_coc_m_cajonera_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.27, ms = 600 }, { modelo = 'origen_casa_coc_m_cajonera_cajon_c', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.38, ms = 700 } } },
        ['origen_casa_coc_m_fregadero'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_m_fregadero_puerta', pos = { 0.300, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_coc_m_placa'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_m_placa_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.22, ms = 600 }, { modelo = 'origen_casa_coc_m_placa_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.36, ms = 700 } } },
        ['origen_casa_coc_m_horno'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_m_horno_puerta', pos = { 0.000, -0.280, 0.222 }, modo = 'gira', eje = 'x', angulo = 88.0, ms = 700 } } },
        ['origen_casa_coc_m_alto'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_m_alto_puerta', pos = { 0.300, -0.175, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_coc_m_columna'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_coc_m_columna_puerta_a', pos = { 0.300, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 }, { modelo = 'origen_casa_coc_m_columna_puerta_b', pos = { 0.300, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 700 } } },
        ['origen_casa_coc_m_isla'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_m_isla_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.36, ms = 600 }, { modelo = 'origen_casa_coc_m_isla_puerta_i', pos = { -0.900, -0.430, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_coc_m_isla_puerta_d', pos = { 0.900, -0.430, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_coc_m_peninsula'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_m_peninsula_puerta_i', pos = { -0.600, -0.430, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_coc_m_peninsula_puerta_d', pos = { 0.560, -0.430, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_coc_c_aparador'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_coc_c_aparador_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.28, ms = 600 }, { modelo = 'origen_casa_coc_c_aparador_puerta_i', pos = { -0.800, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = -100.0, ms = 600 }, { modelo = 'origen_casa_coc_c_aparador_puerta_d', pos = { 0.800, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = 100.0, ms = 600 } } },
    },
})

Config.Packs.Registrar({
    id = 'cocina_rustica', nombre = 'Cocina rústica',
    descripcion = 'Cocina modular de puertas enmarcadas verde salvia, encimera de madera, pila de loza y latón, con su mesa y sus sillas de roble macizo. Todo se abre',
    xp = 0,
    categorias = {
        ['Cocina'] = {
            { model = 'origen_casa_coc_r_bajo', price = 2400, nombre = 'Módulo bajo con puerta (rústica)', label = 'Módulo bajo con puerta (rústica)' },
            { model = 'origen_casa_coc_r_cajonera', price = 3000, nombre = 'Cajonera de cocina (rústica)', label = 'Cajonera de cocina (rústica)' },
            { model = 'origen_casa_coc_r_esquina', price = 1900, nombre = 'Módulo de esquina (rústica)', label = 'Módulo de esquina (rústica)' },
            { model = 'origen_casa_coc_r_fregadero', price = 3900, nombre = 'Módulo con fregadero (rústica)', label = 'Módulo con fregadero (rústica)' },
            { model = 'origen_casa_coc_r_placa', price = 3800, nombre = 'Módulo con placa de gas (rústica)', label = 'Módulo con placa de gas (rústica)' },
            { model = 'origen_casa_coc_r_horno', price = 5000, nombre = 'Módulo con horno (rústica)', label = 'Módulo con horno (rústica)' },
            { model = 'origen_casa_coc_r_alto', price = 2000, nombre = 'Módulo alto de pared (rústica)', label = 'Módulo alto de pared (rústica)' },
            { model = 'origen_casa_coc_r_columna', price = 5000, nombre = 'Columna despensa (rústica)', label = 'Columna despensa (rústica)', type = 'stash', stash = 'big' },
            { model = 'origen_casa_coc_r_remate', price = 1700, nombre = 'Remate de estantes (rústica)', label = 'Remate de estantes (rústica)' },
            { model = 'origen_casa_coc_r_isla', price = 15000, nombre = 'Isla de cocina (rústica)', label = 'Isla de cocina (rústica)' },
            { model = 'origen_casa_coc_r_peninsula', price = 10000, nombre = 'Península con barra (rústica)', label = 'Península con barra (rústica)' },
        },
        ['Mesas'] = {
            { model = 'origen_casa_coc_c_mesa_roble', price = 6500, nombre = 'Mesa de comedor de roble macizo', label = 'Mesa de comedor de roble macizo' },
        },
        ['Sillas'] = {
            { model = 'origen_casa_coc_r_taburete', price = 1500, nombre = 'Taburete de barra (rústica)', label = 'Taburete de barra (rústica)' },
            { model = 'origen_casa_coc_c_silla_roble', price = 1500, nombre = 'Silla de comedor de roble', label = 'Silla de comedor de roble' },
        },
    },
    iconos = { ['Cocina'] = 'fas fa-blender', ['Mesas'] = 'fas fa-table', ['Sillas'] = 'fas fa-chair' },
    animados = {
        ['origen_casa_coc_r_bajo'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_r_bajo_puerta', pos = { 0.300, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_coc_r_cajonera'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_r_cajonera_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.16, ms = 500 }, { modelo = 'origen_casa_coc_r_cajonera_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.27, ms = 600 }, { modelo = 'origen_casa_coc_r_cajonera_cajon_c', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.38, ms = 700 } } },
        ['origen_casa_coc_r_fregadero'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_r_fregadero_puerta', pos = { 0.300, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_coc_r_placa'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_r_placa_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.22, ms = 600 }, { modelo = 'origen_casa_coc_r_placa_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.36, ms = 700 } } },
        ['origen_casa_coc_r_horno'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_r_horno_puerta', pos = { 0.000, -0.280, 0.222 }, modo = 'gira', eje = 'x', angulo = 88.0, ms = 700 } } },
        ['origen_casa_coc_r_alto'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_r_alto_puerta', pos = { 0.300, -0.175, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_coc_r_columna'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_coc_r_columna_puerta_a', pos = { 0.300, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 }, { modelo = 'origen_casa_coc_r_columna_puerta_b', pos = { 0.300, -0.280, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 700 } } },
        ['origen_casa_coc_r_isla'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_r_isla_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.36, ms = 600 }, { modelo = 'origen_casa_coc_r_isla_puerta_i', pos = { -0.900, -0.430, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_coc_r_isla_puerta_d', pos = { 0.900, -0.430, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        ['origen_casa_coc_r_peninsula'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_r_peninsula_puerta_i', pos = { -0.600, -0.430, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = 'origen_casa_coc_r_peninsula_puerta_d', pos = { 0.560, -0.430, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
    },
})

Config.Packs.Registrar({
    id = 'electrodomesticos', nombre = 'Electrodomésticos',
    descripcion = 'Frigorífico americano con la comida dentro y luz, combi, neveras retro, congelador, vinoteca, cocina de gas, microondas, lavavajillas, campana, cafetera, lavadora y secadora: todos se abren',
    xp = 0,
    categorias = {
        ['Electrodomésticos'] = {
            { model = 'origen_casa_coc_e_cocina_gas', price = 5500, nombre = 'Cocina de gas con horno', label = 'Cocina de gas con horno' },
            { model = 'origen_casa_coc_e_microondas', price = 1800, nombre = 'Microondas', label = 'Microondas' },
            { model = 'origen_casa_coc_e_lavavajillas', price = 5200, nombre = 'Lavavajillas', label = 'Lavavajillas' },
            { model = 'origen_casa_coc_e_campana', price = 3200, nombre = 'Campana extractora de pared', label = 'Campana extractora de pared' },
            { model = 'origen_casa_coc_e_cafetera', price = 3500, nombre = 'Cafetera espresso', label = 'Cafetera espresso' },
        },
        ['Neveras'] = {
            { model = 'origen_casa_coc_e_frigo_americano', price = 18000, nombre = 'Frigorífico americano de dos puertas', label = 'Frigorífico americano de dos puertas', type = 'stash', stash = 'extrabig' },
            { model = 'origen_casa_coc_e_frigo_combi', price = 9000, nombre = 'Frigorífico combi de acero', label = 'Frigorífico combi de acero', type = 'stash', stash = 'big' },
            { model = 'origen_casa_coc_e_nevera_retro', price = 7500, nombre = 'Nevera retro verde menta', label = 'Nevera retro verde menta', type = 'stash', stash = 'big' },
            { model = 'origen_casa_coc_e_nevera_retro_roja', price = 7500, nombre = 'Nevera retro roja', label = 'Nevera retro roja', type = 'stash', stash = 'big' },
            { model = 'origen_casa_coc_e_congelador', price = 6000, nombre = 'Congelador vertical', label = 'Congelador vertical', type = 'stash', stash = 'big' },
            { model = 'origen_casa_coc_e_vinoteca', price = 12000, nombre = 'Vinoteca con puerta de cristal', label = 'Vinoteca con puerta de cristal' },
        },
        ['Lavandería y limpieza'] = {
            { model = 'origen_casa_coc_e_lavadora', price = 4800, nombre = 'Lavadora de carga frontal', label = 'Lavadora de carga frontal' },
            { model = 'origen_casa_coc_e_secadora', price = 4500, nombre = 'Secadora de carga frontal', label = 'Secadora de carga frontal' },
        },
    },
    iconos = { ['Electrodomésticos'] = 'fas fa-tv', ['Neveras'] = 'fas fa-utensils', ['Lavandería y limpieza'] = 'fas fa-soap' },
    animados = {
        ['origen_casa_coc_e_frigo_americano'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_coc_e_frigo_americano_puerta_i', pos = { -0.455, -0.360, 0.000 }, modo = 'gira', eje = 'z', angulo = -115.0, ms = 800 }, { modelo = 'origen_casa_coc_e_frigo_americano_puerta_d', pos = { 0.455, -0.360, 0.000 }, modo = 'gira', eje = 'z', angulo = 115.0, ms = 800 } } },
        ['origen_casa_coc_e_frigo_combi'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_coc_e_frigo_combi_puerta_a', pos = { 0.300, -0.330, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 800 }, { modelo = 'origen_casa_coc_e_frigo_combi_puerta_b', pos = { 0.300, -0.330, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 900 } } },
        ['origen_casa_coc_e_nevera_retro'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_coc_e_nevera_retro_puerta', pos = { 0.300, -0.340, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 800 } } },
        ['origen_casa_coc_e_nevera_retro_roja'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_coc_e_nevera_retro_roja_puerta', pos = { 0.300, -0.340, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 800 } } },
        ['origen_casa_coc_e_congelador'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_coc_e_congelador_puerta', pos = { -0.300, -0.330, 0.000 }, modo = 'gira', eje = 'z', angulo = -112.0, ms = 800 } } },
        ['origen_casa_coc_e_vinoteca'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_e_vinoteca_puerta', pos = { 0.300, -0.290, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 800 } } },
        ['origen_casa_coc_e_cocina_gas'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_e_cocina_gas_puerta', pos = { 0.000, -0.280, 0.174 }, modo = 'gira', eje = 'x', angulo = 88.0, ms = 700 } } },
        ['origen_casa_coc_e_microondas'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_e_microondas_puerta', pos = { -0.250, -0.190, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 } } },
        ['origen_casa_coc_e_lavavajillas'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_e_lavavajillas_bandeja', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.52, ms = 900 }, { modelo = 'origen_casa_coc_e_lavavajillas_puerta', pos = { 0.000, -0.280, 0.105 }, modo = 'gira', eje = 'x', angulo = 90.0, ms = 800 } } },
        ['origen_casa_coc_e_lavadora'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_e_lavadora_puerta', pos = { -0.215, -0.302, 0.000 }, modo = 'gira', eje = 'z', angulo = -115.0, ms = 700 } } },
        ['origen_casa_coc_e_secadora'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_coc_e_secadora_puerta', pos = { 0.215, -0.302, 0.000 }, modo = 'gira', eje = 'z', angulo = 115.0, ms = 700 } } },
    },
})
