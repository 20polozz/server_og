-- Muebles propios de los packs «Terraza de lujo» y «Guarida y taller» (tanda 2; modelos:
-- fuente/pack_x2.py, origen_casa_x2_*). Este fichero lo escribe fuente/pack_x2_lua.py con las
-- medidas de las partes que da pack_x2.py al acabar: si se cambia un modelo, se vuelve a generar.
--
-- Los que tienen función la tienen por su `type`, el de siempre del housing:
--   · stash     almacén; el mueble se abre al abrir el alijo (uso = 'almacen')
--   · wardrobe  ropero; las taquillas se abren al abrir el menú de ropa (uso = 'ropero')
--   · camera    la lente mira a -Y, que es hacia donde mira la vista; inclinación y giro, abajo
--   · light     el origen del modelo es la lente y el haz sale hacia +Y (House:DrawLight)
-- Los demás con partes se abren con la E (uso = 'E'). Quién las mueve: custom/client/almacenajes.lua.
-- La pérgola repite el MISMO modelo de lama nueve veces (una parte por lama): es a propósito.
-- El jacuzzi se coloca destapado: la cubierta, plegada y de pie detrás; la E la tiende sobre el vaso.
-- De pared (armero de rejas) y de techo (cámaras): origen en su canto de abajo, se colocan y se suben.

local P = 'origen_casa_x2_'

local function M(id, precio, nombre, extra)
    local it = { model = P .. id, price = precio, nombre = nombre, label = nombre }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end

Config.Packs.Registrar({
    id = 'terraza_lujo', nombre = 'Terraza de lujo',
    descripcion = 'La terraza que se enseña: jacuzzi con cubierta que se pliega, pérgola de lamas que se abren, invernadero con puerta, barbacoa de gas con tapa, tumbona regulable, sombrilla que se inclina, balancín, fuente, brasero y arcón de ratán que guarda; y para rematar la casa, buzón, cubo de pedal, tendedero y tabla de planchar, tres focos orientables y una cámara de exterior',
    xp = 400, grupo = 'tematico',
    categorias = {
        ['Jardín y patio'] = {
            M('brasero', 1500, 'Brasero de hierro con leña'),
            M('sombrilla', 1600, 'Sombrilla de jardín inclinable'),
            M('tumbona', 1800, 'Tumbona de teca con respaldo regulable'),
            M('arcon_jardin', 2400, 'Arcón de jardín de ratán', { type = 'stash', stash = 'normal' }),
            M('balancin', 3000, 'Balancín de jardín de teca'),
            M('barbacoa', 3200, 'Barbacoa de gas con tapa'),
            M('fuente', 6000, 'Fuente de piedra de tres platos'),
            M('pergola', 9000, 'Pérgola bioclimática de lamas orientables'),
            M('invernadero', 9500, 'Invernadero de cristal con puerta'),
            M('jacuzzi', 16000, 'Jacuzzi con escalones y cubierta plegable'),
        },
        ['Varios'] = {
            M('cubo_pedal', 700, 'Cubo de pedal de acero'),
            M('tendedero', 900, 'Tendedero con ropa'),
            M('tabla_planchar', 900, 'Tabla de planchar con plancha'),
            M('buzon', 1000, 'Buzón de poste'),
        },
        ['Cámaras de seguridad'] = {
            M('cam_brazo', 6500, 'Cámara de exterior en brazo', { type = 'camera' }),
        },
        ['Puntos de luz'] = {
            M('foco_jardin', 800, 'Foco de jardín de pica', { type = 'light' }),
            M('foco_led', 1100, 'Proyector LED de exterior', { type = 'light' }),
            M('foco_par', 1300, 'Foco de escenario', { type = 'light' }),
        },
    },
    animados = {
        [P .. 'sombrilla'] = { uso = 'E', texto = { 'Inclinar la sombrilla', 'Enderezar la sombrilla' }, partes = { { modelo = P .. 'sombrilla_copa', pos = { 0.000, 0.000, 1.750 }, modo = 'gira', eje = 'x', angulo = 26.0, ms = 1200 } } },
        [P .. 'tumbona'] = { uso = 'E', texto = { 'Levantar el respaldo', 'Bajar el respaldo' }, partes = { { modelo = P .. 'tumbona_respaldo', pos = { 0.000, 0.250, 0.320 }, modo = 'gira', eje = 'x', angulo = 42.0, ms = 800 } } },
        [P .. 'arcon_jardin'] = { uso = 'almacen', partes = { { modelo = P .. 'arcon_jardin_tapa', pos = { 0.000, 0.310, 0.560 }, modo = 'gira', eje = 'x', angulo = -85.0, ms = 800 } } },
        [P .. 'barbacoa'] = { uso = 'E', texto = { 'Abrir la tapa', 'Cerrar la tapa' }, partes = { { modelo = P .. 'barbacoa_tapa', pos = { 0.000, 0.270, 0.900 }, modo = 'gira', eje = 'x', angulo = -80.0, ms = 900 } } },
        [P .. 'pergola'] = { uso = 'E', texto = { 'Abrir las lamas', 'Cerrar las lamas' }, partes = { { modelo = P .. 'pergola_lama', pos = { 0.000, -1.330, 2.500 }, modo = 'gira', eje = 'x', angulo = 70.0, ms = 1400 }, { modelo = P .. 'pergola_lama', pos = { 0.000, -0.998, 2.500 }, modo = 'gira', eje = 'x', angulo = 70.0, ms = 1400 }, { modelo = P .. 'pergola_lama', pos = { 0.000, -0.665, 2.500 }, modo = 'gira', eje = 'x', angulo = 70.0, ms = 1400 }, { modelo = P .. 'pergola_lama', pos = { 0.000, -0.333, 2.500 }, modo = 'gira', eje = 'x', angulo = 70.0, ms = 1400 }, { modelo = P .. 'pergola_lama', pos = { 0.000, 0.000, 2.500 }, modo = 'gira', eje = 'x', angulo = 70.0, ms = 1400 }, { modelo = P .. 'pergola_lama', pos = { 0.000, 0.333, 2.500 }, modo = 'gira', eje = 'x', angulo = 70.0, ms = 1400 }, { modelo = P .. 'pergola_lama', pos = { 0.000, 0.665, 2.500 }, modo = 'gira', eje = 'x', angulo = 70.0, ms = 1400 }, { modelo = P .. 'pergola_lama', pos = { 0.000, 0.998, 2.500 }, modo = 'gira', eje = 'x', angulo = 70.0, ms = 1400 }, { modelo = P .. 'pergola_lama', pos = { 0.000, 1.330, 2.500 }, modo = 'gira', eje = 'x', angulo = 70.0, ms = 1400 } } },
        [P .. 'invernadero'] = { uso = 'E', texto = { 'Abrir la puerta', 'Cerrar la puerta' }, partes = { { modelo = P .. 'invernadero_puerta', pos = { 0.420, -1.500, 0.000 }, modo = 'gira', eje = 'z', angulo = 100.0, ms = 900 } } },
        [P .. 'jacuzzi'] = { uso = 'E', texto = { 'Tapar el jacuzzi', 'Destapar el jacuzzi' }, partes = { { modelo = P .. 'jacuzzi_cubierta_a', pos = { 0.000, 1.050, 0.900 }, modo = 'gira', eje = 'x', angulo = 90.0, ms = 1600 }, { modelo = P .. 'jacuzzi_cubierta_b', pos = { 0.000, -0.025, 1.925 }, modo = 'gira', eje = 'x', angulo = -90.0, ms = 1600 } } },
        [P .. 'cubo_pedal'] = { uso = 'E', texto = { 'Abrir el cubo', 'Cerrar el cubo' }, partes = { { modelo = P .. 'cubo_pedal_tapa', pos = { 0.000, 0.150, 0.610 }, modo = 'gira', eje = 'x', angulo = -75.0, ms = 500 } } },
        [P .. 'buzon'] = { uso = 'E', texto = { 'Abrir el buzón', 'Cerrar el buzón' }, partes = { { modelo = P .. 'buzon_puerta', pos = { 0.000, -0.250, 1.022 }, modo = 'gira', eje = 'x', angulo = 95.0, ms = 600 } } },
    },
})

Config.Packs.Registrar({
    id = 'guarida_taller', nombre = 'Guarida y taller',
    descripcion = 'Todo para montar la guarida y el taller: contenedor marítimo que se abre y guarda, mesa de planes, pizarra de golpes que gira, caja de munición, puesto de radio, taquillas que sirven de ropero, generador y cama de campaña; banco de trabajo y carro de herramientas con cajones, armario de inflamables, lavadora de piezas y expositor de llantas; archivador, armario metálico, baúl y nevera que guardan, tres armeros y dos cámaras discretas',
    xp = 450, grupo = 'tematico',
    categorias = {
        ['Sótano'] = {
            M('cama_campana', 1200, 'Cama de campaña'),
            M('pales', 1200, 'Palé con cajas'),
            M('estanteria', 2000, 'Estantería de carga'),
            M('taquillas', 2200, 'Taquillas de vestuario', { type = 'wardrobe' }),
            M('generador', 2500, 'Generador de gasolina'),
        },
        ['Guarida'] = {
            M('pizarra_golpes', 2800, 'Pizarra de golpes giratoria'),
            M('mesa_planes', 3200, 'Mesa de planes'),
            M('radio', 3800, 'Puesto de radio'),
            M('caja_municion', 5500, 'Caja de munición', { type = 'stash', stash = 'big' }),
            M('contenedor', 14000, 'Contenedor marítimo', { type = 'stash', stash = 'extrabig' }),
        },
        ['Taller y exposición'] = {
            M('lavapiezas', 4000, 'Lavadora de piezas'),
            M('armario_pintura', 4500, 'Armario de inflamables'),
            M('banco_trabajo', 5500, 'Banco de trabajo con cajones'),
            M('carro_herramientas', 6500, 'Carro de herramientas de siete cajones', { type = 'stash', stash = 'medium' }),
            M('expositor_llantas', 7000, 'Expositor de llantas'),
        },
        ['Almacenaje'] = {
            M('nevera_portatil', 1200, 'Nevera portátil', { type = 'stash', stash = 'small' }),
            M('baul_mimbre', 3000, 'Baúl de mimbre', { type = 'stash', stash = 'normal' }),
            M('archivador', 3500, 'Archivador metálico', { type = 'stash', stash = 'medium' }),
            M('armario_metal', 6500, 'Armario metálico de taller', { type = 'stash', stash = 'big' }),
        },
        ['Armeros'] = {
            M('maletin_rifle', 5500, 'Maletín de rifle', { type = 'stash', stash = 'normal' }),
            M('armero_rejas', 7500, 'Armero de pared con rejas', { type = 'stash', stash = 'medium' }),
            M('armero_vitrina', 9500, 'Vitrina armero de nogal', { type = 'stash', stash = 'big' }),
        },
        ['Cámaras de seguridad'] = {
            M('cam_ptz', 8000, 'Cámara motorizada de techo', { type = 'camera' }),
            M('cam_humo', 9000, 'Cámara oculta en detector de humos', { type = 'camera' }),
        },
    },
    iconos = { ['Guarida'] = 'fas fa-skull', ['Armeros'] = 'fas fa-crosshairs' },
    animados = {
        [P .. 'taquillas'] = { uso = 'ropero', partes = { { modelo = P .. 'taquillas_puerta_a', pos = { -0.153, -0.240, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 }, { modelo = P .. 'taquillas_puerta_b', pos = { 0.152, -0.240, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 }, { modelo = P .. 'taquillas_puerta_c', pos = { 0.457, -0.240, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        [P .. 'pizarra_golpes'] = { uso = 'E', texto = { 'Dar la vuelta a la pizarra', 'Dar la vuelta a la pizarra' }, partes = { { modelo = P .. 'pizarra_golpes_tablero', pos = { 0.000, 0.000, 1.200 }, modo = 'gira', eje = 'z', angulo = 180.0, ms = 1500 } } },
        [P .. 'caja_municion'] = { uso = 'almacen', partes = { { modelo = P .. 'caja_municion_tapa', pos = { 0.000, 0.230, 0.360 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 800 } } },
        [P .. 'contenedor'] = { uso = 'almacen', partes = { { modelo = P .. 'contenedor_puerta_i', pos = { -1.170, -1.500, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 1600 }, { modelo = P .. 'contenedor_puerta_d', pos = { 1.170, -1.500, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 1600 } } },
        [P .. 'lavapiezas'] = { uso = 'E', texto = { 'Abrir la tapa', 'Cerrar la tapa' }, partes = { { modelo = P .. 'lavapiezas_tapa', pos = { 0.000, 0.300, 0.900 }, modo = 'gira', eje = 'x', angulo = -95.0, ms = 800 } } },
        [P .. 'armario_pintura'] = { uso = 'E', texto = { 'Abrir el armario', 'Cerrar el armario' }, partes = { { modelo = P .. 'armario_pintura_puerta_i', pos = { -0.450, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = -110.0, ms = 700 }, { modelo = P .. 'armario_pintura_puerta_d', pos = { 0.450, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 700 } } },
        [P .. 'banco_trabajo'] = { uso = 'E', texto = { 'Abrir los cajones', 'Cerrar los cajones' }, partes = { { modelo = P .. 'banco_trabajo_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.34, ms = 600 }, { modelo = P .. 'banco_trabajo_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.24, ms = 600 } } },
        [P .. 'carro_herramientas'] = { uso = 'almacen', partes = { { modelo = P .. 'carro_herramientas_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.30, ms = 600 }, { modelo = P .. 'carro_herramientas_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.22, ms = 600 } } },
        [P .. 'nevera_portatil'] = { uso = 'almacen', partes = { { modelo = P .. 'nevera_portatil_tapa', pos = { 0.000, 0.200, 0.340 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 600 } } },
        [P .. 'baul_mimbre'] = { uso = 'almacen', partes = { { modelo = P .. 'baul_mimbre_tapa', pos = { 0.000, 0.250, 0.440 }, modo = 'gira', eje = 'x', angulo = -95.0, ms = 800 } } },
        [P .. 'archivador'] = { uso = 'almacen', partes = { { modelo = P .. 'archivador_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.40, ms = 700 } } },
        [P .. 'armario_metal'] = { uso = 'almacen', partes = { { modelo = P .. 'armario_metal_puerta_i', pos = { -0.500, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = -110.0, ms = 700 }, { modelo = P .. 'armario_metal_puerta_d', pos = { 0.500, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 700 } } },
        [P .. 'maletin_rifle'] = { uso = 'almacen', partes = { { modelo = P .. 'maletin_rifle_tapa', pos = { 0.000, 0.200, 0.075 }, modo = 'gira', eje = 'x', angulo = -105.0, ms = 700 } } },
        [P .. 'armero_rejas'] = { uso = 'almacen', partes = { { modelo = P .. 'armero_rejas_reja_i', pos = { -0.700, -0.080, 0.000 }, modo = 'gira', eje = 'z', angulo = -115.0, ms = 700 }, { modelo = P .. 'armero_rejas_reja_d', pos = { 0.700, -0.080, 0.000 }, modo = 'gira', eje = 'z', angulo = 115.0, ms = 700 } } },
        [P .. 'armero_vitrina'] = { uso = 'almacen', partes = { { modelo = P .. 'armero_vitrina_puerta', pos = { 0.530, -0.190, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 800 } } },
    },
})

-- Cámaras (config/cameras.lua, client/cameras.lua): `offset` se suma al giro con el que se
-- colocó el mueble (x: inclinación; la vista mira hacia -Y del modelo); `rotation`: cuánto se
-- puede girar la vista a cada lado.
if type(Config.Cameras) == 'table' then
    local CAMARAS = {
        [P .. 'cam_brazo'] = { offset = vector3(-15.0, 0.0, 0.0), rotation = 80.0 },
        [P .. 'cam_ptz'] = { offset = vector3(-25.0, 0.0, 0.0), rotation = 360.0 },
        [P .. 'cam_humo'] = { offset = vector3(-65.0, 0.0, 0.0), rotation = 360.0 },
    }
    for modelo, datos in pairs(CAMARAS) do
        if Config.Cameras[modelo] == nil then Config.Cameras[modelo] = datos end
    end
end
