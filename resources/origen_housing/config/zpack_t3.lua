-- Packs temáticos «Casa japonesa» y «Despacho del jefe» (modelos: fuente/pack_t3.py,
-- origen_casa_t3_*; diccionario origen_casa_txp_t3; ytyp origen_casa_pk_t3).
-- ESTE FICHERO LO ESCRIBE fuente/pack_t3_lua.py: el catálogo está allí y las medidas
-- de las partes salen de pack_t3.py. Si se cambia un modelo, se vuelve a generar.
--
-- Función de cada mueble (la de siempre del housing, por su `type`):
--   · stash     tansu, vitrina de katanas, archivador, caja fuerte tras panel y cuadro
--               con caja oculta: son almacenes y se abren al usarlos (uso = 'almacen')
--   · wardrobe  el oshiire: es ropero; su puerta corre al abrir el menú de ropa
--   · luz       andon, farol de piedra y lámpara de banquero llevan la luz dentro del
--               modelo (siempre encendida); el altar, la de sus velas
-- Los demás que se mueven se abren con la E (uso = 'E').
-- El cuadro con caja oculta es de pared: origen en su canto de abajo, se coloca y se sube.

local P = 'origen_casa_t3_'

local function M(id, precio, nombre, extra)
    local it = { model = P .. id, price = precio, nombre = nombre, label = nombre }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end

Config.Packs.Registrar({
    id = 'casa_japonesa', nombre = 'Casa japonesa',
    descripcion = 'Una casa japonesa entera: futón sobre tatami, kotatsu con su faldón, cojines zabuton y silla zaisu, tokonoma con rollo de caligrafía, altar lacado que se abre, cómoda tansu con herrajes de hierro, biombo de pan de oro, panel shoji que corre, lámpara andon y farol de piedra que alumbran, soporte y vitrina de katanas, bonsái, fuente de bambú que bascula, juego de té, armario oshiire y bañera ofuro de ciprés',
    xp = 450, grupo = 'tematico',
    categorias = {
        ['Camas'] = {
            M('futon', 4200, 'Futón japonés sobre tatami'),
        },
        ['Alfombras'] = {
            M('tatami', 1200, 'Estera de tatami'),
        },
        ['Armarios'] = {
            M('oshiire', 9500, 'Armario oshiire de puertas correderas', { type = 'wardrobe' }),
        },
        ['Mesas'] = {
            M('kotatsu', 4800, 'Mesa baja kotatsu con faldón'),
        },
        ['Sillas'] = {
            M('zabuton', 900, 'Cojín zabuton de seda'),
            M('zaisu', 1800, 'Silla zaisu sin patas'),
        },
        ['Decoración'] = {
            M('juego_te', 1600, 'Juego de té con tetera de hierro'),
            M('tokonoma', 6000, 'Tokonoma con rollo de caligrafía'),
            M('altar', 6000, 'Altar butsudan lacado'),
            M('katana_soporte', 4500, 'Soporte con katana y wakizashi'),
        },
        ['Almacenaje'] = {
            M('tansu', 9000, 'Cómoda tansu con herrajes de hierro', { type = 'stash', stash = 'big' }),
        },
        ['Armeros'] = {
            M('katana_armero', 16000, 'Vitrina armero de katanas', { type = 'stash', stash = 'big' }),
        },
        ['Paredes'] = {
            M('byobu', 4500, 'Biombo byobu de pan de oro'),
            M('shoji', 3800, 'Panel shoji corredero'),
        },
        ['Luces'] = {
            M('andon', 2600, 'Lámpara andon de papel'),
        },
        ['Plantas'] = {
            M('bonsai', 2800, 'Bonsái en bandeja de cerámica'),
        },
        ['Jardín y patio'] = {
            M('shishi_odoshi', 5200, 'Fuente de bambú shishi-odoshi'),
            M('toro', 4800, 'Farol de piedra'),
        },
        ['Baño'] = {
            M('ofuro', 7000, 'Bañera ofuro de ciprés'),
        },
    },
    animados = {
        [P .. 'oshiire'] = { uso = 'ropero', partes = { { modelo = P .. 'oshiire_puerta', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.84, ms = 900 } } },
        [P .. 'altar'] = { uso = 'E', texto = { 'Abrir el altar', 'Cerrar el altar' }, partes = { { modelo = P .. 'altar_puerta_i', pos = { -0.330, -0.240, 0.000 }, modo = 'gira', eje = 'z', angulo = -118.0, ms = 800 }, { modelo = P .. 'altar_puerta_d', pos = { 0.330, -0.240, 0.000 }, modo = 'gira', eje = 'z', angulo = 118.0, ms = 800 } } },
        [P .. 'tansu'] = { uso = 'almacen', partes = { { modelo = P .. 'tansu_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.16, ms = 700 }, { modelo = P .. 'tansu_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.30, ms = 700 } } },
        [P .. 'katana_armero'] = { uso = 'almacen', partes = { { modelo = P .. 'katana_armero_puerta_i', pos = { -0.520, -0.202, 0.000 }, modo = 'gira', eje = 'z', angulo = -108.0, ms = 800 }, { modelo = P .. 'katana_armero_puerta_d', pos = { 0.520, -0.202, 0.000 }, modo = 'gira', eje = 'z', angulo = 108.0, ms = 800 } } },
        [P .. 'shoji'] = { uso = 'E', texto = { 'Correr la hoja', 'Cerrar la hoja' }, partes = { { modelo = P .. 'shoji_hoja', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.84, ms = 1000 } } },
        [P .. 'shishi_odoshi'] = { uso = 'E', texto = { 'Volcar la caña', 'Levantar la caña' }, partes = { { modelo = P .. 'shishi_odoshi_cana', pos = { -0.220, 0.000, 0.520 }, modo = 'gira', eje = 'y', angulo = 48.0, ms = 1100 } } },
    },
})

Config.Packs.Registrar({
    id = 'despacho_jefe', nombre = 'Despacho del jefe',
    descripcion = 'El despacho de quien manda: escritorio de caoba con tapete de piel y cajones que se abren, sillón capitoné que se reclina, sillas de confidente, mesa de reuniones, librería de abogado con vitrinas, archivador, mueble bar con licorera, globo terráqueo que esconde un bar, caja fuerte tras un panel de madera, cuadro con caja oculta, lámpara de banquero, humidor de puros, maletín con dinero, bandera, perchero, placa de director y cenicero con puro',
    xp = 450, grupo = 'tematico',
    categorias = {
        ['Escritorios'] = {
            M('escritorio', 14000, 'Escritorio de director de caoba'),
        },
        ['Sillones'] = {
            M('sillon', 7500, 'Sillón de director capitoné'),
        },
        ['Sillas'] = {
            M('silla_confidente', 3200, 'Silla de confidente de cuero'),
        },
        ['Mesas'] = {
            M('mesa_reuniones', 12000, 'Mesa de reuniones de nogal'),
        },
        ['Muebles'] = {
            M('libreria', 9500, 'Librería de abogado con vitrinas'),
            M('mueble_bar', 11000, 'Mueble bar con licorera'),
        },
        ['Almacenaje'] = {
            M('archivador', 5500, 'Archivador de caoba de cuatro cajones', { type = 'stash', stash = 'medium' }),
            M('cuadro_caja', 9000, 'Cuadro con caja oculta', { type = 'stash', stash = 'normal' }),
            M('caja_panel', 22000, 'Caja fuerte tras panel de madera', { type = 'stash', stash = 'extrabig' }),
        },
        ['Luces'] = {
            M('lampara_banquero', 2200, 'Lámpara de banquero'),
        },
        ['Decoración'] = {
            M('globo_bar', 6000, 'Globo terráqueo-bar'),
            M('humidor', 3000, 'Humidor de puros'),
            M('maletin', 4000, 'Maletín con dinero'),
            M('bandera', 2800, 'Bandera en mástil de latón'),
            M('placa', 1200, 'Placa de director con plumas'),
            M('cenicero', 900, 'Cenicero de cristal con puro'),
        },
        ['Varios'] = {
            M('perchero', 2400, 'Perchero de caoba con paragüero'),
        },
    },
    animados = {
        [P .. 'escritorio'] = { uso = 'E', texto = { 'Abrir los cajones', 'Cerrar los cajones' }, partes = { { modelo = P .. 'escritorio_cajon_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.32, ms = 700 }, { modelo = P .. 'escritorio_cajon_c', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.24, ms = 700 } } },
        [P .. 'sillon'] = { uso = 'E', texto = { 'Reclinar', 'Incorporar' }, partes = { { modelo = P .. 'sillon_respaldo', pos = { 0.000, 0.270, 0.500 }, modo = 'gira', eje = 'x', angulo = -13.0, ms = 900 } } },
        [P .. 'libreria'] = { uso = 'E', texto = { 'Abrir las vitrinas', 'Cerrar las vitrinas' }, partes = { { modelo = P .. 'libreria_puerta_i', pos = { -0.560, -0.182, 0.000 }, modo = 'gira', eje = 'z', angulo = -112.0, ms = 800 }, { modelo = P .. 'libreria_puerta_d', pos = { 0.560, -0.182, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 800 } } },
        [P .. 'mueble_bar'] = { uso = 'E', texto = { 'Abrir el bar', 'Cerrar el bar' }, partes = { { modelo = P .. 'mueble_bar_puerta_i', pos = { -0.750, -0.272, 0.000 }, modo = 'gira', eje = 'z', angulo = -110.0, ms = 800 }, { modelo = P .. 'mueble_bar_puerta_d', pos = { 0.750, -0.272, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 800 } } },
        [P .. 'archivador'] = { uso = 'almacen', partes = { { modelo = P .. 'archivador_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.44, ms = 800 } } },
        [P .. 'cuadro_caja'] = { uso = 'almacen', partes = { { modelo = P .. 'cuadro_caja_cuadro', pos = { -0.400, -0.004, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 900 } } },
        [P .. 'caja_panel'] = { uso = 'almacen', partes = { { modelo = P .. 'caja_panel_panel', pos = { 0.520, -0.288, 0.000 }, modo = 'gira', eje = 'z', angulo = 118.0, ms = 800 }, { modelo = P .. 'caja_panel_puerta', pos = { 0.420, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = 100.0, ms = 1300 } } },
        [P .. 'globo_bar'] = { uso = 'E', texto = { 'Abrir el globo', 'Cerrar el globo' }, partes = { { modelo = P .. 'globo_bar_tapa', pos = { 0.000, 0.270, 0.700 }, modo = 'gira', eje = 'x', angulo = -78.0, ms = 1100 } } },
        [P .. 'humidor'] = { uso = 'E', texto = { 'Abrir el humidor', 'Cerrar el humidor' }, partes = { { modelo = P .. 'humidor_tapa', pos = { 0.000, 0.130, 0.108 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 800 } } },
        [P .. 'maletin'] = { uso = 'E', texto = { 'Abrir el maletín', 'Cerrar el maletín' }, partes = { { modelo = P .. 'maletin_tapa', pos = { 0.000, 0.170, 0.062 }, modo = 'gira', eje = 'x', angulo = -105.0, ms = 800 } } },
    },
})
