-- Dormitorio: camas, mesillas, cómodas, tocadores y demás, propios y con partes
-- que se mueven (modelos: fuente/pack_dor.py; quién las mueve:
-- custom/client/almacenajes.lua). Tres packs:
--   base              una cama sencilla de pino y un colchón en el suelo
--   dormitorio        el dormitorio de diario: camas, mesillas, cómoda, cuna…
--   dormitorio_lujo   capitoné, dosel, marfil y latón
-- Las medidas de las partes y de dónde se tumba uno las escribe
-- fuente/pack_dor.py al acabar (líneas «LUA» y «CAMA»): si se cambia un modelo,
-- aquí también.
-- La cama con canapé y el banco de pie de cama son, además, almacenajes
-- (type = 'stash', con los tamaños de config/stashes.lua): se abren al usarlos.
-- Precios provisionales: los repasa config/zz_economia.lua.

Config.Packs.Registrar({
    id = 'base',
    categorias = {
        ['Camas'] = {
            { model = 'origen_casa_dor_colchon_suelo', price = 1500, nombre = 'Colchón en el suelo', label = 'Colchón en el suelo' },
            { model = 'origen_casa_dor_cama_sencilla', price = 2200, nombre = 'Cama sencilla de pino', label = 'Cama sencilla de pino' },
        },
    },
})

Config.Packs.Registrar({
    id = 'dormitorio', nombre = 'Dormitorio',
    descripcion = 'El dormitorio completo: cama de matrimonio, juvenil, litera, de palets, con canapé que se levanta y abatible de pared; cuna, mesillas y cómoda con cajones que salen, tocador de camerino con luces, galán y espejo de pie',
    xp = 0,
    categorias = {
        ['Camas'] = {
            { model = 'origen_casa_dor_cuna', price = 3000, nombre = 'Cuna con baranda', label = 'Cuna con baranda' },
            { model = 'origen_casa_dor_cama_palets', price = 3500, nombre = 'Cama de palets', label = 'Cama de palets' },
            { model = 'origen_casa_dor_cama_juvenil', price = 3800, nombre = 'Cama juvenil', label = 'Cama juvenil' },
            { model = 'origen_casa_dor_litera', price = 5500, nombre = 'Litera de pino', label = 'Litera de pino' },
            { model = 'origen_casa_dor_cama_moderna', price = 6500, nombre = 'Cama de matrimonio moderna', label = 'Cama de matrimonio moderna' },
            { model = 'origen_casa_dor_cama_canape', price = 9000, nombre = 'Cama con canapé abatible', label = 'Cama con canapé abatible', type = 'stash', stash = 'big' },
            { model = 'origen_casa_dor_cama_abatible', price = 12000, nombre = 'Cama abatible de pared', label = 'Cama abatible de pared' },
        },
        ['Muebles'] = {
            { model = 'origen_casa_dor_galan', price = 1600, nombre = 'Galán de noche', label = 'Galán de noche' },
            { model = 'origen_casa_dor_mesilla_moderna', price = 1800, nombre = 'Mesilla moderna de wengué', label = 'Mesilla moderna de wengué' },
            { model = 'origen_casa_dor_mesilla_clasica', price = 2000, nombre = 'Mesilla de cerezo', label = 'Mesilla de cerezo' },
            { model = 'origen_casa_dor_comoda', price = 4500, nombre = 'Cómoda de seis cajones', label = 'Cómoda de seis cajones' },
            { model = 'origen_casa_dor_tocador_camerino', price = 6000, nombre = 'Tocador de camerino con luces', label = 'Tocador de camerino con luces' },
        },
        ['Sillas'] = {
            { model = 'origen_casa_dor_taburete', price = 1500, nombre = 'Taburete de tocador', label = 'Taburete de tocador' },
        },
        ['Decoración'] = {
            { model = 'origen_casa_dor_espejo_pie', price = 2200, nombre = 'Espejo de pie basculante', label = 'Espejo de pie basculante' },
            { model = 'origen_casa_dor_cabecero_listones', price = 2800, nombre = 'Cabecero de listones con luz', label = 'Cabecero de listones con luz' },
        },
    },
    animados = {
        ['origen_casa_dor_cama_canape'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_dor_cama_canape_somier', pos = { 0.000, 0.950, 0.360 }, modo = 'gira', eje = 'x', angulo = -40.0, ms = 1400 } } },
        ['origen_casa_dor_cama_abatible'] = { uso = 'E', texto = { 'Bajar la cama', 'Recoger la cama' }, partes = { { modelo = 'origen_casa_dor_cama_abatible_cama', pos = { 0.000, -0.200, 0.300 }, modo = 'gira', eje = 'x', angulo = 90.0, ms = 1700 } } },
        ['origen_casa_dor_cuna'] = { uso = 'E', texto = { 'Bajar la baranda', 'Subir la baranda' }, partes = { { modelo = 'origen_casa_dor_cuna_baranda', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = -0.30, ms = 700 } } },
        ['origen_casa_dor_mesilla_moderna'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_dor_mesilla_moderna_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.24, ms = 600 } } },
        ['origen_casa_dor_mesilla_clasica'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_dor_mesilla_clasica_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.22, ms = 600 } } },
        ['origen_casa_dor_comoda'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_dor_comoda_cajon_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.32, ms = 600 }, { modelo = 'origen_casa_dor_comoda_cajon_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.20, ms = 600 } } },
        ['origen_casa_dor_tocador_camerino'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_dor_tocador_camerino_cajon_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.26, ms = 600 }, { modelo = 'origen_casa_dor_tocador_camerino_cajon_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.18, ms = 600 } } },
        ['origen_casa_dor_espejo_pie'] = { uso = 'E', texto = { 'Inclinar', 'Enderezar' }, partes = { { modelo = 'origen_casa_dor_espejo_pie_luna', pos = { 0.000, 0.000, 0.980 }, modo = 'gira', eje = 'x', angulo = -14.0, ms = 700 } } },
    },
})

Config.Packs.Registrar({
    id = 'dormitorio_lujo', nombre = 'Dormitorio de lujo',
    descripcion = 'Suite de lujo: cama king con cabecero capitoné, cama con dosel de caoba tallada, mesilla, cómoda y tocador en marfil y latón, banco de pie de cama que guarda cosas, biombo que se pliega y cabecero de terciopelo',
    xp = 0,
    categorias = {
        ['Camas'] = {
            { model = 'origen_casa_dor_cama_lujo', price = 22000, nombre = 'Cama king capitoné', label = 'Cama king capitoné' },
            { model = 'origen_casa_dor_cama_dosel', price = 30000, nombre = 'Cama con dosel de caoba', label = 'Cama con dosel de caoba' },
        },
        ['Muebles'] = {
            { model = 'origen_casa_dor_mesilla_lujo', price = 4500, nombre = 'Mesilla de marfil y latón', label = 'Mesilla de marfil y latón' },
            { model = 'origen_casa_dor_banco_pie', price = 6500, nombre = 'Banco capitoné de pie de cama', label = 'Banco capitoné de pie de cama', type = 'stash', stash = 'normal' },
            { model = 'origen_casa_dor_tocador', price = 8500, nombre = 'Tocador clásico con espejo', label = 'Tocador clásico con espejo' },
            { model = 'origen_casa_dor_comoda_lujo', price = 9500, nombre = 'Cómoda de marfil y latón', label = 'Cómoda de marfil y latón' },
        },
        ['Decoración'] = {
            { model = 'origen_casa_dor_biombo', price = 5500, nombre = 'Biombo de tres hojas', label = 'Biombo de tres hojas' },
            { model = 'origen_casa_dor_cabecero_capitone', price = 8000, nombre = 'Cabecero capitoné de terciopelo', label = 'Cabecero capitoné de terciopelo' },
        },
    },
    animados = {
        ['origen_casa_dor_mesilla_lujo'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_dor_mesilla_lujo_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.22, ms = 600 } } },
        ['origen_casa_dor_comoda_lujo'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_dor_comoda_lujo_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.32, ms = 600 } } },
        ['origen_casa_dor_tocador'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_dor_tocador_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.24, ms = 600 } } },
        ['origen_casa_dor_banco_pie'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_dor_banco_pie_tapa', pos = { 0.000, 0.210, 0.400 }, modo = 'gira', eje = 'x', angulo = -72.0, ms = 800 } } },
        ['origen_casa_dor_biombo'] = { uso = 'E', texto = { 'Plegar', 'Desplegar' }, partes = { { modelo = 'origen_casa_dor_biombo_hoja_i', pos = { -0.279, -0.018, 0.000 }, modo = 'gira', eje = 'z', angulo = 150.0, ms = 1100 }, { modelo = 'origen_casa_dor_biombo_hoja_d', pos = { 0.279, 0.018, 0.000 }, modo = 'gira', eje = 'z', angulo = 150.0, ms = 1100 } } },
    },
})

-- Tumbarse en las camas y sentarse en el taburete (custom/*/especiales.lua).
-- cama = { x, y, z, giro }: x/y desde el centro del modelo, z desde lo más alto
-- (por eso son negativas: el cabecero o el dosel quedan por encima del colchón);
-- giro 0: la cabeza hacia la cabecera (+Y del modelo). En la litera, la de abajo.
-- No se tumba uno en la del canapé (es un almacenaje: su E abre el arcón), ni
-- en la abatible (su E la baja y la recoge), ni en la cuna.
if Config.Especiales and Config.Especiales.modelos then
    local m = Config.Especiales.modelos
    m['origen_casa_dor_cama_moderna'] = { cama = { x = 0.00, y = -0.16, z = -0.55, giro = 0.0 } }
    m['origen_casa_dor_cama_lujo'] = { cama = { x = 0.00, y = -0.16, z = -0.79, giro = 0.0 } }
    m['origen_casa_dor_cama_dosel'] = { cama = { x = 0.00, y = -0.12, z = -1.54, giro = 0.0 } }
    m['origen_casa_dor_cama_juvenil'] = { cama = { x = 0.00, y = -0.12, z = -0.38, giro = 0.0 } }
    m['origen_casa_dor_litera'] = { cama = { x = 0.00, y = -0.12, z = -1.16, giro = 0.0 } }
    m['origen_casa_dor_cama_palets'] = { cama = { x = 0.00, y = -0.19, z = -0.49, giro = 0.0 } }
    m['origen_casa_dor_colchon_suelo'] = { cama = { x = 0.02, y = -0.06, z = -0.13, giro = 0.0 } }
    m['origen_casa_dor_cama_sencilla'] = { cama = { x = 0.00, y = -0.12, z = -0.38, giro = 0.0 } }
    m['origen_casa_dor_taburete'] = { asiento = { z = 0.47 } }
end
