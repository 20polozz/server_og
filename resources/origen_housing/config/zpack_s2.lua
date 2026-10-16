-- Muebles propios de la tanda 2: «Salón de diseño» y «Comedor y recibidor»
-- (modelos: fuente/pack_s2.py y sus cinco ficheros pack_s2_*.py, origen_casa_s2_*).
-- ESTE FICHERO LO ESCRIBE fuente/pack_s2_lua.py a partir de fuente/pack_s2_datos.json
-- (las medidas de las partes y de los asientos salen de los modelos): si se cambia
-- un modelo, se vuelve a generar; no se retoca a mano.
--
-- Movimiento: Config.Animados (lo mueve custom/client/almacenajes.lua). `uso`:
--   'E'        se abre y se cierra con la E
--   'almacen'  el mueble es `type = 'stash'`: se abre al abrir su alijo y se cierra con él
-- Función, por su `type` de siempre del housing:
--   stash      almacén (tamaños de config/stashes.lua)
--   wardrobe   ropero (menú de ropa)
--   tv         tele: la pantalla lleva «script_rt_tvscreen» (render target «tvscreen»);
--              hay que darlos de alta en origen_screens/shared/config.lua (Config.Modelos)
-- Sentarse y tumbarse: Config.Especiales.modelos (custom/client/especiales.lua), abajo.
-- En cada mueble van además dos campos informativos para la tienda y el catálogo, que
-- el housing no usa para nada más: `movimiento = true` (tiene partes que se mueven) y
-- `funcion` ('almacen', 'ropero', 'tele', 'sentarse' o 'tumbarse').

local P = 'origen_casa_s2_'

local function M(id, precio, nombre, extra)
    local it = { model = P .. id, price = precio, nombre = nombre, label = nombre }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end

Config.Packs.Registrar({
    id = 'salon_diseno', nombre = 'Salón de diseño',
    descripcion = 'Un salón de revista: sofá acanalado de terciopelo, chaise longue con arcón, sofá cama clic-clac, sillón relax que se reclina, butaca de pletina y cuero capitoné, mecedora, diván y puf arcón; mesas de centro con tapas correderas, mesas nido que se sacan y auxiliares con cajón; librería giratoria, secreter que se abre, baúl bar de cuero con luz y cinco muebles de tele (cuatro con tele que funciona y uno con almacén)',
    xp = 450, grupo = 'estancia',
    categorias = {
        ['Sillones'] = {
            M('puf_arcon', 3600, 'Puf arcón de cuero coñac', { type = 'stash', stash = 'normal', movimiento = true, funcion = 'almacen' }),
            M('mecedora', 5200, 'Mecedora de nogal', { funcion = 'sentarse' }),
            M('sofa_clic', 7800, 'Sofá cama clic-clac', { movimiento = true }),
            M('butaca_pletina', 8800, 'Butaca de pletina cromada y cuero capitoné', { funcion = 'sentarse' }),
            M('sofa2_nogal', 9200, 'Sofá de dos plazas de nogal y cuero', { funcion = 'sentarse' }),
            M('relax', 9500, 'Sillón relax de bucle', { movimiento = true, funcion = 'sentarse' }),
            M('divan', 9800, 'Diván de terciopelo rosa palo', { funcion = 'tumbarse' }),
            M('chaise_arcon', 12000, 'Chaise longue con arcón', { type = 'stash', stash = 'big', movimiento = true, funcion = 'almacen' }),
            M('sofa_canale', 13500, 'Sofá acanalado de terciopelo azul', { funcion = 'sentarse' }),
        },
        ['Mesas'] = {
            M('auxiliar_c', 2200, 'Mesa auxiliar en C de acero y roble'),
            M('auxiliar_cajon', 2900, 'Mesa auxiliar de nogal con cajón', { movimiento = true }),
            M('mesas_nido', 4600, 'Mesas nido de nogal y acero negro', { movimiento = true }),
            M('centro_oval', 4800, 'Mesa de centro ovalada con balda de rejilla'),
            M('centro_correderas', 5400, 'Mesa de centro con tapas correderas', { movimiento = true }),
        },
        ['Muebles'] = {
            M('estanteria_escalera', 3800, 'Estantería de escalera'),
            M('libreria_giratoria', 6200, 'Librería giratoria de nogal', { movimiento = true }),
            M('secreter', 8200, 'Secreter de caoba con tapa abatible', { movimiento = true }),
            M('baul_bar', 16500, 'Baúl bar de cuero', { movimiento = true }),
        },
        ['Televisores con mueble'] = {
            M('tv_caballete', 5600, 'Tele de 50" en caballete de roble', { type = 'tv', funcion = 'tele' }),
            M('tv_lamas', 6200, 'Mueble de roble con lamas y tele de 55"', { type = 'tv', funcion = 'tele' }),
            M('tv_retro', 7400, 'Mueble de los setenta con tele de tubo', { type = 'tv', funcion = 'tele' }),
            M('tv_almacen', 9800, 'Mueble de tele con correderas y almacén', { type = 'stash', stash = 'big', movimiento = true, funcion = 'almacen' }),
            M('tv_panel', 11500, 'Panel acanalado de nogal con tele de 65"', { type = 'tv', funcion = 'tele' }),
        },
    },
    animados = {
        [P .. 'chaise_arcon'] = { uso = 'almacen', partes = { { modelo = P .. 'chaise_arcon_tapa', pos = { -0.850, -0.150, 0.270 }, modo = 'gira', eje = 'x', angulo = -52.0, ms = 900 } } },
        [P .. 'sofa_clic'] = { uso = 'E', texto = { 'Abrir la cama', 'Recoger la cama' }, partes = { { modelo = P .. 'sofa_clic_respaldo', pos = { 0.000, 0.200, 0.430 }, modo = 'gira', eje = 'x', angulo = -76.0, ms = 1200 } } },
        [P .. 'relax'] = { uso = 'E', texto = { 'Reclinar', 'Incorporar' }, partes = { { modelo = P .. 'relax_respaldo', pos = { 0.000, 0.220, 0.400 }, modo = 'gira', eje = 'x', angulo = -32.0, ms = 1200 }, { modelo = P .. 'relax_reposapies', pos = { 0.000, -0.395, 0.420 }, modo = 'gira', eje = 'x', angulo = -86.0, ms = 1200 } } },
        [P .. 'puf_arcon'] = { uso = 'almacen', partes = { { modelo = P .. 'puf_arcon_tapa', pos = { 0.000, 0.260, 0.360 }, modo = 'gira', eje = 'x', angulo = -98.0, ms = 700 } } },
        [P .. 'centro_correderas'] = { uso = 'E', texto = { 'Abrir las tapas', 'Cerrar las tapas' }, partes = { { modelo = P .. 'centro_correderas_tapa_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.300, ms = 800 }, { modelo = P .. 'centro_correderas_tapa_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.300, ms = 800 } } },
        [P .. 'mesas_nido'] = { uso = 'E', texto = { 'Sacar las mesas', 'Recoger las mesas' }, partes = { { modelo = P .. 'mesas_nido_mediana', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.360, ms = 800 }, { modelo = P .. 'mesas_nido_pequena', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.680, ms = 800 } } },
        [P .. 'auxiliar_cajon'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'auxiliar_cajon_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.220, ms = 600 } } },
        [P .. 'libreria_giratoria'] = { uso = 'E', texto = { 'Girar', 'Girar' }, partes = { { modelo = P .. 'libreria_giratoria_torre', pos = { 0.000, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = 180.0, ms = 1800 } } },
        [P .. 'baul_bar'] = { uso = 'E', texto = { 'Abrir el bar', 'Cerrar el bar' }, partes = { { modelo = P .. 'baul_bar_puerta_i', pos = { -0.420, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = -112.0, ms = 1000 }, { modelo = P .. 'baul_bar_puerta_d', pos = { 0.420, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 1000 } } },
        [P .. 'secreter'] = { uso = 'E', texto = { 'Abrir el escritorio', 'Cerrar el escritorio' }, partes = { { modelo = P .. 'secreter_tapa', pos = { 0.000, -0.190, 0.760 }, modo = 'gira', eje = 'x', angulo = 90.0, ms = 900 } } },
        [P .. 'tv_almacen'] = { uso = 'almacen', partes = { { modelo = P .. 'tv_almacen_puerta_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.650, ms = 900 }, { modelo = P .. 'tv_almacen_puerta_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.650, ms = 900 } } },
    },
})

Config.Packs.Registrar({
    id = 'comedor_recibidor', nombre = 'Comedor y recibidor',
    descripcion = 'El comedor y la entrada de casa: mesa extensible que se abre de verdad, mesa de alas abatibles, redonda de mármol e industrial de tablones; ocho sillas y bancos (terciopelo, roble y cuerda, chapa, mimbre, cuero); aparador de puertas correderas, vitrina de hierro y cristal con luz, sinfonier, zapatero abatible, consolas con cajones y espejo, banco con arcón y un recibidor con perchero que hace de ropero',
    xp = 400, grupo = 'estancia',
    categorias = {
        ['Sillas'] = {
            M('taburete_roble', 1500, 'Taburete bajo de roble', { funcion = 'sentarse' }),
            M('silla_chapa', 1900, 'Silla industrial de acero galvanizado', { funcion = 'sentarse' }),
            M('silla_nordica', 2400, 'Silla nórdica de roble y cuerda', { funcion = 'sentarse' }),
            M('silla_terciopelo', 2600, 'Silla de comedor de terciopelo', { funcion = 'sentarse' }),
            M('silla_mimbre', 3200, 'Sillón de mimbre con cojín', { funcion = 'sentarse' }),
            M('banco_comedor', 3400, 'Banco de comedor de roble y hierro', { funcion = 'sentarse' }),
            M('silla_patin', 3600, 'Sillón de comedor de cuero con patín', { funcion = 'sentarse' }),
            M('banco_recibidor', 4200, 'Banco de recibidor con arcón', { type = 'stash', stash = 'normal', movimiento = true, funcion = 'almacen' }),
        },
        ['Mesas'] = {
            M('mesa_alas', 5800, 'Mesa de alas abatibles', { movimiento = true }),
            M('mesa_industrial', 8800, 'Mesa de comedor industrial de tablones'),
            M('mesa_extensible', 9500, 'Mesa de comedor extensible de roble', { movimiento = true }),
            M('mesa_tulipan', 11500, 'Mesa redonda de mármol con pie de tulipán'),
        },
        ['Muebles'] = {
            M('consola_cajones', 4200, 'Consola de recibidor con cajones', { movimiento = true }),
            M('zapatero', 4600, 'Zapatero abatible de tres frentes', { type = 'stash', stash = 'normal', movimiento = true, funcion = 'almacen' }),
            M('sinfonier', 6800, 'Sinfonier de nogal de seis cajones', { type = 'stash', stash = 'big', movimiento = true, funcion = 'almacen' }),
            M('recibidor_perchero', 7200, 'Recibidor con perchero y banco', { type = 'wardrobe', funcion = 'ropero' }),
            M('consola_espejo', 7800, 'Consola de mármol verde con espejo'),
            M('aparador_corredero', 8500, 'Aparador de puertas correderas de rejilla', { type = 'stash', stash = 'big', movimiento = true, funcion = 'almacen' }),
            M('vitrina_hierro', 9800, 'Vitrina industrial de hierro y cristal', { movimiento = true }),
        },
    },
    animados = {
        [P .. 'banco_recibidor'] = { uso = 'almacen', partes = { { modelo = P .. 'banco_recibidor_tapa', pos = { 0.000, 0.200, 0.445 }, modo = 'gira', eje = 'x', angulo = -84.0, ms = 700 } } },
        [P .. 'mesa_extensible'] = { uso = 'E', texto = { 'Extender la mesa', 'Recoger la mesa' }, partes = { { modelo = P .. 'mesa_extensible_tablero_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.250, ms = 1000 }, { modelo = P .. 'mesa_extensible_tablero_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.250, ms = 1000 }, { modelo = P .. 'mesa_extensible_ala', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = 0.044, ms = 1000 } } },
        [P .. 'mesa_alas'] = { uso = 'E', texto = { 'Levantar las alas', 'Bajar las alas' }, partes = { { modelo = P .. 'mesa_alas_ala_i', pos = { -0.150, 0.000, 0.735 }, modo = 'gira', eje = 'y', angulo = 90.0, ms = 900 }, { modelo = P .. 'mesa_alas_ala_d', pos = { 0.150, 0.000, 0.735 }, modo = 'gira', eje = 'y', angulo = -90.0, ms = 900 } } },
        [P .. 'consola_cajones'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'consola_cajones_cajon_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.170, ms = 600 }, { modelo = P .. 'consola_cajones_cajon_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.170, ms = 600 } } },
        [P .. 'aparador_corredero'] = { uso = 'almacen', partes = { { modelo = P .. 'aparador_corredero_puerta_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.585, ms = 900 }, { modelo = P .. 'aparador_corredero_puerta_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.585, ms = 900 } } },
        [P .. 'vitrina_hierro'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'vitrina_hierro_puerta_i', pos = { -0.430, -0.200, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 700 }, { modelo = P .. 'vitrina_hierro_puerta_d', pos = { 0.430, -0.200, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 700 } } },
        [P .. 'sinfonier'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'sinfonier_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.140, ms = 600 }, { modelo = P .. 'sinfonier_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.260, ms = 600 } } },
        [P .. 'zapatero'] = { uso = 'almacen', partes = { { modelo = P .. 'zapatero_frente_a', pos = { 0.000, -0.100, 0.078 }, modo = 'gira', eje = 'x', angulo = 40.0, ms = 700 }, { modelo = P .. 'zapatero_frente_b', pos = { 0.000, -0.100, 0.468 }, modo = 'gira', eje = 'x', angulo = 40.0, ms = 700 }, { modelo = P .. 'zapatero_frente_c', pos = { 0.000, -0.100, 0.858 }, modo = 'gira', eje = 'x', angulo = 40.0, ms = 700 } } },
    },
})

-- ── Sentarse y tumbarse ─────────────────────────────────────────────────
-- Un sitio por mueble (el sistema de config/especiales.lua no lleva más). x/y, desde
-- el centro de la caja del modelo; z del asiento, sobre su base; el respaldo queda del
-- lado +Y, así que vale el giro de siempre (180). Los que son almacén (chaise con arcón,
-- puf arcón, banco de recibidor) y el sofá cama no llevan asiento: su E es otra.
-- El diván es para tumbarse: z, respecto a lo más alto del modelo; el cuerpo, a lo largo de X.
local SITIOS = {
    [P .. 'sofa_canale'] = { asiento = { x = 0.00, y = -0.08, z = 0.47 } },
    [P .. 'relax'] = { asiento = { x = -0.02, y = -0.04, z = 0.50 } },
    [P .. 'butaca_pletina'] = { asiento = { x = 0.00, y = -0.07, z = 0.44 } },
    [P .. 'mecedora'] = { asiento = { x = 0.00, y = -0.05, z = 0.47 } },
    [P .. 'divan'] = { cama = { x = 0.13, y = -0.03, z = -0.33, giro = 90.0 } },
    [P .. 'sofa2_nogal'] = { asiento = { x = 0.35, y = -0.07, z = 0.47 } },
    [P .. 'silla_terciopelo'] = { asiento = { x = 0.00, y = -0.05, z = 0.49 } },
    [P .. 'silla_nordica'] = { asiento = { x = 0.00, y = -0.04, z = 0.46 } },
    [P .. 'silla_chapa'] = { asiento = { x = 0.00, y = -0.03, z = 0.46 } },
    [P .. 'silla_mimbre'] = { asiento = { x = -0.00, y = -0.04, z = 0.47 } },
    [P .. 'taburete_roble'] = { asiento = { x = 0.00, y = -0.01, z = 0.45 } },
    [P .. 'banco_comedor'] = { asiento = { x = 0.00, y = 0.00, z = 0.50 } },
    [P .. 'silla_patin'] = { asiento = { x = 0.00, y = -0.05, z = 0.48 } },
}
if Config.Especiales and type(Config.Especiales.modelos) == 'table' then
    for modelo, datos in pairs(SITIOS) do
        if Config.Especiales.modelos[modelo] == nil then Config.Especiales.modelos[modelo] = datos end
    end
end
