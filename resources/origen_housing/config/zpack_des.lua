-- Muebles propios del pack «Detalles de casa» (modelos: fuente/pack_des.py,
-- origen_casa_des_*). Llena las categorías del catálogo que no tenían ningún
-- mueble propio: «Comida», «Varios», «Televisores con mueble», «Cámaras de
-- seguridad», «Puntos de luz», «Paredes» y «Cuadros personalizados».
--
-- Los que tienen función la tienen por su `type`, el de siempre del housing:
--   · tv      la pantalla lleva la textura «script_rt_tvscreen» (el render target
--             «tvscreen» del juego) y los cuatro modelos están dados de alta en
--             origen_screens/shared/config.lua (Config.Modelos). Por llevar `type`,
--             la E es la del mando de la tele: sus puertas no se abren.
--   · camera  la lente mira a -Y, que es hacia donde mira la vista de la cámara;
--             la inclinación y el giro, abajo, en Config.Cameras.
--   · light   el origen del modelo es la lente y el haz sale hacia +Y, que es por
--             donde House:DrawLight dibuja la luz: se orienta girando el mueble.
--   · board   el lienzo lleva una textura con nombre propio (des_lienzo_a/b/c, en
--             el diccionario origen_casa_txp_des) que se cambia por la imagen del
--             jugador; abajo, en Config.Boards. Como con los cuadros de antes,
--             todos los cuadros del MISMO modelo enseñan la misma imagen.
-- Los de pared (botiquín, cuadro eléctrico, cámaras, marcos) tienen el origen en
-- su canto de abajo: se colocan y se suben.
-- Quién mueve las partes: custom/client/almacenajes.lua con Config.Animados. Las
-- medidas de las partes las escribe fuente/pack_des.py al acabar (líneas «LUA»):
-- si se cambia un modelo, aquí también.
-- El ventilador «gira»: el sistema de partes solo sabe ir de cerrado a abierto, así
-- que al encenderlo las aspas dan veinte vueltas en nueve segundos y se paran (y
-- al «apagarlo» las desandan). No es un giro continuo.

local P = 'origen_casa_des_'

local function M(id, precio, nombre, extra)
    local it = { model = P .. id, price = precio, nombre = nombre, label = nombre }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end

Config.Packs.Registrar({
    id = 'detalles', nombre = 'Detalles de casa',
    descripcion = 'Lo que faltaba para que la casa parezca vivida: bandeja de desayuno, tabla de quesos, tarta con campana de cristal, pizza, olla de guiso y cesta de picnic que se abren; perchero, escalera, ventilador que se enciende, caja de herramientas, cubos de reciclaje y botiquín; cuatro muebles con tele que funciona, tres cámaras de seguridad, tres focos orientables, tabique de ladrillo, pared de pavés, panel de lamas, biombo y tres cuadros para poner tu propia imagen',
    xp = 300, grupo = 'muebles',
    categorias = {
        ['Comida'] = {
            M('desayuno', 900, 'Bandeja de desayuno'),
            M('tabla_quesos', 900, 'Tabla de quesos'),
            M('frutero', 800, 'Frutero'),
            M('tarta', 1200, 'Tarta con campana de cristal'),
            M('pizza', 700, 'Pizza en su caja'),
            M('olla', 1000, 'Olla de guiso'),
            M('cesta_pan', 800, 'Cesta de pan'),
            M('caja_donuts', 700, 'Caja de dónuts'),
            M('picnic', 1500, 'Cesta de picnic'),
            M('galletas', 600, 'Galletas con leche'),
        },
        ['Varios'] = {
            M('perchero_pie', 1600, 'Perchero de pie'),
            M('escalera', 1400, 'Escalera de tijera'),
            M('caja_herramientas', 1500, 'Caja de herramientas'),
            M('cubos_reciclaje', 1800, 'Cubos de reciclaje'),
            M('ventilador', 1800, 'Ventilador de pie'),
            M('aspiradora', 1800, 'Aspiradora'),
            M('maletas', 2200, 'Juego de maletas'),
            M('botiquin', 1400, 'Botiquín de pared'),
            M('cuadro_electrico', 1400, 'Cuadro eléctrico'),
        },
        ['Televisores con mueble'] = {
            M('tv_nogal', 3500, 'Mueble de nogal con tele de 55"', { type = 'tv' }),
            M('tv_industrial', 3800, 'Mueble industrial con tele de 50"', { type = 'tv' }),
            M('tv_lacado', 5500, 'Mueble suspendido con panel y tele de 60"', { type = 'tv' }),
            M('tv_lujo', 9000, 'Mueble de mármol negro con tele de 75"', { type = 'tv' }),
        },
        ['Cámaras de seguridad'] = {
            M('cam_mini', 5500, 'Cámara interior de pared', { type = 'camera' }),
            M('cam_bala', 6000, 'Cámara de tubo', { type = 'camera' }),
            M('cam_domo', 7000, 'Cámara de domo de techo', { type = 'camera' }),
        },
        ['Puntos de luz'] = {
            M('foco_empotrado', 700, 'Foco empotrable', { type = 'light' }),
            M('foco_carril', 900, 'Foco de carril', { type = 'light' }),
            M('foco_estudio', 1200, 'Foco de estudio con viseras', { type = 'light' }),
        },
        ['Paredes'] = {
            M('pared_ladrillo', 1400, 'Tabique de ladrillo visto'),
            M('biombo', 1600, 'Biombo de tres hojas'),
            M('panel_lamas', 1800, 'Panel separador de lamas'),
            M('pared_paves', 2000, 'Pared de pavés'),
        },
        ['Cuadros personalizados'] = {
            M('cuadro_madera', 1500, 'Marco de roble con paspartú (tu imagen)', { type = 'board' }),
            M('cuadro_caballete', 1800, 'Lienzo en caballete (tu imagen)', { type = 'board' }),
            M('cuadro_dorado', 2200, 'Marco dorado clásico (tu imagen)', { type = 'board' }),
        },
    },
    animados = {
        [P .. 'tarta'] = { uso = 'E', texto = { 'Levantar la campana', 'Bajar la campana' }, partes = { { modelo = P .. 'tarta_campana', pos = { 0.000, 0.158, 0.106 }, modo = 'gira', eje = 'x', angulo = -78.0, ms = 800 } } },
        [P .. 'pizza'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'pizza_tapa', pos = { 0.000, 0.180, 0.042 }, modo = 'gira', eje = 'x', angulo = -112.0, ms = 700 } } },
        [P .. 'olla'] = { uso = 'E', texto = { 'Destapar', 'Tapar' }, partes = { { modelo = P .. 'olla_tapa', pos = { 0.137, 0.000, 0.168 }, modo = 'gira', eje = 'y', angulo = 62.0, ms = 600 } } },
        [P .. 'caja_donuts'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'caja_donuts_tapa', pos = { 0.000, 0.110, 0.055 }, modo = 'gira', eje = 'x', angulo = -115.0, ms = 600 } } },
        [P .. 'picnic'] = { uso = 'E', texto = { 'Abrir la cesta', 'Cerrar la cesta' }, partes = { { modelo = P .. 'picnic_tapa_izq', pos = { 0.000, 0.000, 0.246 }, modo = 'gira', eje = 'y', angulo = 82.0, ms = 700 }, { modelo = P .. 'picnic_tapa_der', pos = { 0.000, 0.000, 0.246 }, modo = 'gira', eje = 'y', angulo = -82.0, ms = 700 } } },
        [P .. 'caja_herramientas'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'caja_herramientas_tapa', pos = { 0.000, 0.120, 0.170 }, modo = 'gira', eje = 'x', angulo = -105.0, ms = 700 } } },
        [P .. 'cubos_reciclaje'] = { uso = 'E', texto = { 'Abrir las tapas', 'Cerrar las tapas' }, partes = { { modelo = P .. 'cubos_reciclaje_tapa_a', pos = { -0.330, 0.195, 0.625 }, modo = 'gira', eje = 'x', angulo = -75.0, ms = 500 }, { modelo = P .. 'cubos_reciclaje_tapa_b', pos = { 0.000, 0.195, 0.625 }, modo = 'gira', eje = 'x', angulo = -75.0, ms = 500 }, { modelo = P .. 'cubos_reciclaje_tapa_c', pos = { 0.330, 0.195, 0.625 }, modo = 'gira', eje = 'x', angulo = -75.0, ms = 500 } } },
        [P .. 'ventilador'] = { uso = 'E', texto = { 'Encender', 'Apagar' }, partes = { { modelo = P .. 'ventilador_aspas', pos = { 0.000, -0.075, 1.240 }, modo = 'gira', eje = 'y', angulo = 7200.0, ms = 9000 } } },
        [P .. 'botiquin'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'botiquin_puerta', pos = { 0.180, -0.055, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 600 } } },
        [P .. 'cuadro_electrico'] = { uso = 'E', texto = { 'Abrir la tapa', 'Cerrar la tapa' }, partes = { { modelo = P .. 'cuadro_electrico_tapa', pos = { 0.000, -0.035, 0.455 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 600 } } },
    },
})

-- Cámaras (config/cameras.lua, client/cameras.lua): `offset` se suma al giro con
-- el que se colocó el mueble (x: inclinación; la vista mira hacia -Y del modelo);
-- `rotation`: cuánto se puede girar la vista a cada lado.
if type(Config.Cameras) == 'table' then
    local CAMARAS = {
        [P .. 'cam_bala'] = { offset = vector3(-14.0, 0.0, 0.0), rotation = 70.0 },
        [P .. 'cam_domo'] = { offset = vector3(-30.0, 0.0, 0.0), rotation = 360.0 },
        [P .. 'cam_mini'] = { offset = vector3(-10.0, 0.0, 0.0), rotation = 60.0 },
    }
    for modelo, datos in pairs(CAMARAS) do
        if Config.Cameras[modelo] == nil then Config.Cameras[modelo] = datos end
    end
end

-- Cuadros personalizados (config/boards.lua, House:CreateBoardDui): el
-- diccionario y la textura del lienzo que se cambia por la imagen del jugador.
if type(Config.Boards) == 'table' then
    local CUADROS = {
        [P .. 'cuadro_dorado'] = { dict = 'origen_casa_txp_des', texture = 'des_lienzo_a' },
        [P .. 'cuadro_madera'] = { dict = 'origen_casa_txp_des', texture = 'des_lienzo_b' },
        [P .. 'cuadro_caballete'] = { dict = 'origen_casa_txp_des', texture = 'des_lienzo_c' },
    }
    for modelo, datos in pairs(CUADROS) do
        if Config.Boards[modelo] == nil then Config.Boards[modelo] = datos end
    end
end
