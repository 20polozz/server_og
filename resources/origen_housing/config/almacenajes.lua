-- Muebles con partes que se mueven (custom/client/almacenajes.lua y
-- custom/server/almacenajes.lua). Aquí, los almacenajes de la primera tanda; los
-- de los packs (roperos, armeros, cocinas…) se declaran en Config.Animados
-- (config/packs.lua y config/zpack_*.lua), con el mismo formato de partes y un
-- `uso`: 'almacen' (se abre al abrir el alijo y se cierra al cerrar el
-- inventario), 'ropero' (al abrir y cerrar el menú de ropa) o 'E' (mueble
-- normal: se abre y se cierra con la E). El módulo mueve las dos tablas: se
-- consultan con Config.Almacenajes.Def(modelo), SIEMPRE en tiempo de ejecución
-- (este fichero se carga antes que packs.lua y que los zpack).
--
-- Muebles de almacenaje propios, que se abren de verdad. Son muebles del catálogo (config/furniture.lua,
-- categoría «Almacenaje», type = 'stash'): el modelo del catálogo es el CUERPO, lo
-- fijo, y sus puertas, tapas, cajones o solapas son otros modelos que cada cliente
-- pone sobre él y mueve al abrir y al cerrar el almacenamiento.
--
-- Este fichero se carga antes que config/furniture.lua (orden alfabético): aquí
-- solo va cómo se mueve cada uno; precio y capacidad, en el catálogo.
Config.Almacenajes = {
    ritmo = 600,        -- ms mínimos entre dos avisos de abrir del mismo jugador (lo mira el servidor)
    tope = 8.0,         -- lo más lejos del mueble que el servidor da por bueno para abrirlo
    alcance = 60.0,     -- en la calle (muebles de parcela), a quién avisa el servidor: a los que estén a menos de esto
    topeE = 4.0,        -- lo mismo para los que se abren con la E
    radioE = 1.1,       -- a qué distancia de la caja del mueble sale la E (más su medio ancho)
    sinAbrir = 5000,    -- ms que se espera a que el inventario salga; si no sale (el servidor no dejó), se cierra el mueble

    -- Alijos de neveras y congeladores. El servidor los abre como frío para
    -- que origen_inventory detenga la caducidad de su contenido.
    frigorificos = {
        ['origen_casa_alm_congelador'] = true,
        ['origen_casa_coc_e_nevera_basica'] = true,
        ['origen_casa_coc_e_nevera_retro'] = true,
        ['origen_casa_coc_e_nevera_retro_roja'] = true,
        ['origen_casa_coc_e_congelador'] = true,
        ['origen_casa_k2_nevera_francesa'] = true,
        ['origen_casa_k2_nevera_retro_crema'] = true,
        ['origen_casa_k2_nevera_retro_azul'] = true,
        ['origen_casa_k2_arcon_bebidas'] = true,
        ['origen_casa_k2_expositor'] = true,
        ['origen_casa_k2_minibar'] = true,
        ['origen_casa_k2_vinoteca_doble'] = true,
        ['origen_casa_t1_nevera_botellas'] = true,
        ['origen_casa_t2_nevera_muestras'] = true,
        ['origen_casa_t5_nevera_redonda'] = true,
        ['origen_casa_t5_nevera_portatil'] = true,
        ['origen_casa_t6_nevera_refrescos'] = true,
        ['origen_casa_t6_nevera_caja'] = true,
        ['origen_casa_x2_nevera_portatil'] = true,
    },

    -- Por modelo, sus partes. Las medidas son las de fuente/almacenajes.py (las
    -- escribe él al acabar, líneas «LUA»): si se cambia el modelo, aquí también.
    --   modelo    el de la parte (sin colisión)
    --   pos       dónde va su origen, en el cuerpo: la bisagra de las que giran,
    --             el origen del cuerpo en las que corren
    --   modo      'gira': gira `angulo` grados alrededor de `eje` (puertas: 'z';
    --             tapas y solapas: 'x'). 'corre': se desplaza `recorrido` metros
    --             a lo largo de `eje` (cajones: 'y', hacia el frente, que es -Y)
    --   ms        lo que tarda en abrirse, y en cerrarse
    modelos = {
        ['origen_casa_alm_caja_fuerte'] = { partes = { { modelo = 'origen_casa_alm_caja_fuerte_puerta', pos = { 0.350, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 800 } } },
        ['origen_casa_alm_armero'] = { partes = { { modelo = 'origen_casa_alm_armero_puerta_i', pos = { -0.500, -0.225, 0.000 }, modo = 'gira', eje = 'z', angulo = -110.0, ms = 600 }, { modelo = 'origen_casa_alm_armero_puerta_d', pos = { 0.500, -0.225, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 600 } } },
        ['origen_casa_alm_taquilla'] = { partes = { { modelo = 'origen_casa_alm_taquilla_puerta', pos = { 0.200, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = 115.0, ms = 600 } } },
        ['origen_casa_alm_baul'] = { partes = { { modelo = 'origen_casa_alm_baul_tapa', pos = { 0.000, 0.275, 0.430 }, modo = 'gira', eje = 'x', angulo = -80.0, ms = 700 } } },
        ['origen_casa_alm_arcon'] = { partes = { { modelo = 'origen_casa_alm_arcon_tapa', pos = { 0.000, 0.300, 0.420 }, modo = 'gira', eje = 'x', angulo = -85.0, ms = 700 } } },
        ['origen_casa_alm_comoda'] = { partes = { { modelo = 'origen_casa_alm_comoda_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.32, ms = 600 } } },
        ['origen_casa_alm_aparador'] = { partes = { { modelo = 'origen_casa_alm_aparador_puerta_i', pos = { -0.778, -0.225, 0.000 }, modo = 'gira', eje = 'z', angulo = -100.0, ms = 600 }, { modelo = 'origen_casa_alm_aparador_puerta_d', pos = { 0.778, -0.225, 0.000 }, modo = 'gira', eje = 'z', angulo = 100.0, ms = 600 } } },
        ['origen_casa_alm_cajonera_taller'] = { partes = { { modelo = 'origen_casa_alm_cajonera_taller_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.30, ms = 600 } } },
        ['origen_casa_alm_congelador'] = { partes = { { modelo = 'origen_casa_alm_congelador_tapa', pos = { 0.000, 0.310, 0.800 }, modo = 'gira', eje = 'x', angulo = -75.0, ms = 700 } } },
        ['origen_casa_alm_cajas'] = { partes = { { modelo = 'origen_casa_alm_cajas_solapa_f', pos = { 0.000, -0.210, 0.380 }, modo = 'gira', eje = 'x', angulo = 130.0, ms = 600 }, { modelo = 'origen_casa_alm_cajas_solapa_t', pos = { 0.000, 0.210, 0.380 }, modo = 'gira', eje = 'x', angulo = -130.0, ms = 600 } } },
        ['origen_casa_alm_maleta'] = { partes = { { modelo = 'origen_casa_alm_maleta_tapa', pos = { 0.000, 0.240, 0.130 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 600 } } },
    },

    -- Los diez almacenajes del juego que se vendían antes. Ya no están en el
    -- catálogo (no se pueden comprar: el servidor rechaza los `retirado`), pero
    -- los que hay colocados en las casas siguen siendo almacenaje, con su E, su
    -- contenido y su capacidad de siempre: que un mueble es un baúl y cuánto
    -- cabe lo saca el housing de __indexFurniture, así que se apuntan ahí.
    -- No borrar: sin su línea, el mueble colocado deja de abrirse.
    antiguos = {
        { model = 'v_res_tre_storageunit', price = 3000, type = 'stash', stash = 'normal' },
        { model = 'v_res_jewelbox', price = 400, type = 'stash', stash = 'small' },
        { model = 'v_res_tre_storagebox', price = 2500, type = 'stash', stash = 'big' },
        { model = 'hei_prop_heist_deposit_box', price = 250, type = 'stash', stash = 'small' },
        { model = 'hei_prop_heist_wooden_box', price = 2000, type = 'stash', stash = 'big' },
        { model = 'prop_box_ammo03a', price = 2500, type = 'stash', stash = 'big' },
        { model = 'p_v_43_safe_s', price = 4000, type = 'stash', stash = 'extrabig' },
        { model = 'ch_prop_mil_crate_02b', price = 250, type = 'stash', stash = 'big' },
        { model = 'v_res_fh_crateclosed', price = 2500, type = 'stash', stash = 'big' },
        { model = 'prop_mil_crate_01', price = 5000, type = 'stash', stash = 'extrabig' },
        -- y los siete roperos del juego de «Armarios» (lo mismo: siguen abriendo el menú de ropa)
        { model = 'ch_prop_ch_service_locker_01a', price = 100, type = 'wardrobe' },
        { model = 'ch_prop_ch_service_locker_02a', price = 100, type = 'wardrobe' },
        { model = 'apa_mp_h_str_shelffloorm_02', price = 100, type = 'wardrobe' },
        { model = 'apa_mp_h_str_shelffreel_01', price = 100, type = 'wardrobe' },
        { model = 'bkr_prop_gunlocker_01a', price = 100, type = 'wardrobe' },
        { model = 'apa_mp_h_str_shelfwallm_01', price = 100, type = 'wardrobe' },
        { model = 'v_serv_cupboard_01', price = 100, type = 'wardrobe' },
    },
}

-- init.lua ya ha creado __indexFurniture (vacío) y lo llena después, en un hilo,
-- con el catálogo; lo que esté en el catálogo manda.
for _, item in ipairs(Config.Almacenajes.antiguos) do
    item.retirado = true
    if __indexFurniture and not __indexFurniture[item.model] then __indexFurniture[item.model] = item end
end

--- Clave de un mueble dentro de su casa, la misma en el cliente y en el servidor.
function Config.Almacenajes.Clave(zona, id)
    return tostring(zona) .. ':' .. tostring(id)
end

--- Cómo se mueve un modelo: { uso, texto, partes } o nil si no tiene partes.
--- Mira primero los packs (Config.Animados) y luego los de aquí, que son
--- almacenajes. Llamar en tiempo de ejecución, nunca al cargar el fichero.
function Config.Almacenajes.Def(modelo)
    if type(modelo) ~= 'string' then return nil end
    local d = (Config.Animados and Config.Animados[modelo]) or Config.Almacenajes.modelos[modelo]
    if type(d) ~= 'table' or type(d.partes) ~= 'table' or #d.partes == 0 then return nil end
    return d
end

--- 'almacen', 'ropero' o 'E'
function Config.Almacenajes.Uso(def)
    local u = def and def.uso
    if u == 'ropero' or u == 'E' then return u end
    return 'almacen'
end
