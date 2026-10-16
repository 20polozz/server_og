-- Packs de rol «Mi negocio en casa» y «Garaje de coleccionista» (tanda 2).
-- Modelos propios (fuente/pack_t6.py + pack_t6_a.py + pack_t6_b.py; texturas del juego:
-- fuente/texturas_pack_t6.py), en origen_modelos/stream/casa_obra
-- (origen_casa_pk_t6.ytyp, origen_casa_txp_t6.ytd). Cada mueble va en la categoría del
-- catálogo que le toca. Todo es cosmético: los almacenes guardan lo mismo que cualquier otro.
--
-- Qué hace cada uno, sin lógica nueva (lo de siempre del housing):
--   · type = 'stash'     almacén (config/stashes.lua); con uso = 'almacen' se abren sus
--                        puertas al abrir el alijo: vitrina, nevera de refrescos, caja fuerte,
--                        armario de taller y nevera caja de herramientas.
--   · type = 'wardrobe'  ropero: el perchero con ruedas (sin partes) y la taquilla de pilotos
--                        (uso = 'ropero': se abre la puerta al abrir el menú de ropa).
--   · type = 'light'     punto de luz del housing: el cartel de «Abierto». El haz sale del
--                        origen hacia +Y (House:DrawLight), así que ese modelo mira a +Y.
--   · uso = 'E'          se mueven con la E (custom/client/almacenajes.lua): el cajón de la
--                        caja registradora, el expositor giratorio (dos vueltas), la cortina
--                        del probador, el cajón de la mesa de embalaje, las puertas de la
--                        vitrina de cascos, los cajones del banco de trabajo y el semáforo.
--   · asiento            el sofá de trasera de coche (config/especiales.lua).
--   · luz real dentro del modelo (siempre encendida): vitrinas, neveras, probador, peanas,
--     expositor de llantas, surtidor, sofá (pilotos) y neón.
-- El semáforo de salida «se enciende» con el mismo sistema de partes: cada pareja de luces
-- rojas es una parte escondida dentro de la caja, detrás de su lente apagada y a distinta
-- profundidad; al accionarlo avanzan todas y cada una asoma en un momento distinto (de
-- izquierda a derecha). Al apagarlo se van en orden inverso.
-- Lo de pared (carteles de chapa, neón, pared de herramientas, semáforo, cartel de abierto)
-- lleva el origen en la pared y en su borde de abajo (el de abierto, en su centro): se
-- colocan y se suben.
-- Las medidas de las partes las escribe fuente/pack_t6.py al acabar (líneas «LUA»): si se
-- cambia un modelo, aquí también.

local P = 'origen_casa_t6_'

local function M(id, precio, nombre, extra)
    local it = { model = P .. id, price = precio, nombre = nombre, label = nombre }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end

-- >>> PARTES (generado de las líneas «LUA» y «ANIM» de fuente/pack_t6.py)
local PARTES = {}
PARTES[P .. 'mostrador_caja'] = { uso = 'E', texto = { 'Abrir la caja', 'Cerrar la caja' }, partes = { { modelo = P .. 'mostrador_caja_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = 0.24, ms = 500 } } }
PARTES[P .. 'vitrina'] = { uso = 'almacen', partes = { { modelo = P .. 'vitrina_puerta_i', pos = { -0.500, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = -112.0, ms = 700 }, { modelo = P .. 'vitrina_puerta_d', pos = { 0.500, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 700 } } }
PARTES[P .. 'expositor_giratorio'] = { uso = 'E', texto = { 'Girar', 'Girar al revés' }, partes = { { modelo = P .. 'expositor_giratorio_torre', pos = { 0.000, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = 720.0, ms = 8000 } } }
PARTES[P .. 'probador'] = { uso = 'E', texto = { 'Abrir la cortina', 'Cerrar la cortina' }, partes = { { modelo = P .. 'probador_cortina', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.93, ms = 1100 } } }
PARTES[P .. 'nevera_refrescos'] = { uso = 'almacen', partes = { { modelo = P .. 'nevera_refrescos_puerta', pos = { 0.340, -0.300, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 700 } } }
PARTES[P .. 'mesa_embalaje'] = { uso = 'E', texto = { 'Abrir el cajón', 'Cerrar el cajón' }, partes = { { modelo = P .. 'mesa_embalaje_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.3, ms = 600 } } }
PARTES[P .. 'caja_fuerte'] = { uso = 'almacen', partes = { { modelo = P .. 'caja_fuerte_puerta', pos = { 0.280, -0.240, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 900 } } }
PARTES[P .. 'vitrina_cascos'] = { uso = 'E', texto = { 'Abrir la vitrina', 'Cerrar la vitrina' }, partes = { { modelo = P .. 'vitrina_cascos_puerta_i', pos = { -0.550, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = -112.0, ms = 700 }, { modelo = P .. 'vitrina_cascos_puerta_d', pos = { 0.550, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 700 } } }
PARTES[P .. 'armario_taller'] = { uso = 'almacen', partes = { { modelo = P .. 'armario_taller_puerta_i', pos = { -0.500, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = -115.0, ms = 700 }, { modelo = P .. 'armario_taller_puerta_d', pos = { 0.500, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = 115.0, ms = 700 } } }
PARTES[P .. 'banco_trabajo'] = { uso = 'E', texto = { 'Abrir los cajones', 'Cerrar los cajones' }, partes = { { modelo = P .. 'banco_trabajo_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.34, ms = 600 }, { modelo = P .. 'banco_trabajo_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.24, ms = 600 } } }
PARTES[P .. 'nevera_caja'] = { uso = 'almacen', partes = { { modelo = P .. 'nevera_caja_puerta', pos = { 0.330, -0.240, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 700 } } }
PARTES[P .. 'taquilla_pilotos'] = { uso = 'ropero', partes = { { modelo = P .. 'taquilla_pilotos_puerta', pos = { -0.340, -0.220, 0.000 }, modo = 'gira', eje = 'z', angulo = -115.0, ms = 700 } } }
PARTES[P .. 'semaforo_salida'] = { uso = 'E', texto = { 'Dar la salida', 'Apagar el semáforo' }, partes = { { modelo = P .. 'semaforo_salida_luz_1', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.0163, ms = 3600 }, { modelo = P .. 'semaforo_salida_luz_2', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.0203, ms = 3600 }, { modelo = P .. 'semaforo_salida_luz_3', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.0269, ms = 3600 }, { modelo = P .. 'semaforo_salida_luz_4', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.04, ms = 3600 }, { modelo = P .. 'semaforo_salida_luz_5', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.0778, ms = 3600 } } }
-- <<< PARTES

local function Animados(ids)
    local t = {}
    for _, id in ipairs(ids) do t[P .. id] = PARTES[P .. id] end
    return t
end

Config.Packs.Registrar({
    id = 'negocio_casa', nombre = 'Mi negocio en casa',
    descripcion = 'Monta tu tienda en casa: mostrador con caja registradora que se abre, vitrina de cristal, nevera de refrescos y caja fuerte que guardan de verdad, estanterías llenas, perchero con ruedas que hace de ropero, maniquíes, probador con cortina, expositor de postales que gira, máquina de café, báscula, mesa de embalaje, pizarra de menú y cartel luminoso de «Abierto»',
    xp = 400, grupo = 'tematico',
    categorias = {
        ['Muebles'] = {
            M('mostrador_caja', 9500, 'Mostrador con caja registradora'),
            M('estanteria_tienda', 6500, 'Estantería de tienda con género'),
            M('estanteria_ropa', 6000, 'Estantería de ropa doblada'),
            M('probador', 8500, 'Probador con cortina'),
        },
        ['Almacenaje'] = {
            M('vitrina', 9000, 'Vitrina de cristal de boutique', { type = 'stash', stash = 'big' }),
            M('caja_fuerte', 9500, 'Caja fuerte de suelo con buzón', { type = 'stash', stash = 'big' }),
        },
        ['Neveras'] = {
            M('nevera_refrescos', 8500, 'Nevera de refrescos con puerta de cristal', { type = 'stash', stash = 'normal' }),
        },
        ['Armarios'] = {
            M('perchero_ruedas', 4500, 'Perchero de ropa con ruedas', { type = 'wardrobe' }),
        },
        ['Decoración'] = {
            M('maniqui_a', 3500, 'Maniquí de escaparate con vaqueros'),
            M('maniqui_b', 3500, 'Maniquí de escaparate con vestido'),
            M('maniqui_sastre', 3000, 'Maniquí de sastre'),
            M('pizarra_menu', 1800, 'Pizarra de menú de caballete'),
        },
        ['Electrodomésticos'] = {
            M('maquina_cafe', 7500, 'Máquina de café de barra'),
        },
        ['Mesas'] = {
            M('mesa_embalaje', 5500, 'Mesa de embalaje'),
        },
        ['Varios'] = {
            M('expositor_giratorio', 3500, 'Expositor giratorio de postales'),
            M('bascula', 2500, 'Báscula de mostrador'),
            M('cestas', 1800, 'Cestas de la compra'),
            M('paquetes', 1800, 'Paquetes listos para enviar'),
        },
        ['Puntos de luz'] = {
            M('cartel_abierto', 3000, 'Cartel luminoso de «Abierto»', { type = 'light' }),
        },
    },
    animados = Animados({ 'mostrador_caja', 'vitrina', 'expositor_giratorio', 'probador', 'nevera_refrescos', 'mesa_embalaje', 'caja_fuerte' }),
})

Config.Packs.Registrar({
    id = 'garaje_coleccionista', nombre = 'Garaje de coleccionista',
    descripcion = 'Convierte el garaje en un museo: suelo de exposición por losetas, postes con cordón de terciopelo, peanas iluminadas, vitrina de cascos y expositor de llantas; pared de herramientas, armario de taller y banco con cajones que se abren; sofá hecho con la trasera de un clásico, mesa de motor V8, surtidor retro con luz, carteles de chapa, neón, nevera con forma de caja de herramientas, taquilla de piloto y semáforo de salida que se enciende',
    xp = 450, grupo = 'tematico',
    categorias = {
        ['Taller y exposición'] = {
            M('postes_cordon', 3500, 'Postes de museo con cordón de terciopelo'),
            M('atril_ficha', 2500, 'Atril con ficha de exposición'),
            M('peana', 4500, 'Peana de exposición iluminada'),
            M('peana_urna', 7500, 'Peana con urna y pistón cromado'),
            M('expositor_llantas', 9500, 'Expositor de llantas de tres alturas'),
            M('pared_herramientas', 7500, 'Pared de herramientas'),
            M('banco_trabajo', 9000, 'Banco de trabajo con tornillo y cajones'),
            M('surtidor', 12000, 'Surtidor de gasolina retro'),
            M('semaforo_salida', 9000, 'Semáforo de salida de cinco luces'),
        },
        ['Alfombras'] = {
            M('suelo_damero', 3500, 'Suelo de exposición ajedrezado (2 × 2 m)'),
            M('suelo_rojo', 3500, 'Suelo de exposición rojo (2 × 2 m)'),
        },
        ['Trofeos'] = {
            M('vitrina_cascos', 14000, 'Vitrina de cascos de piloto'),
        },
        ['Almacenaje'] = {
            M('armario_taller', 8500, 'Armario de taller de dos puertas', { type = 'stash', stash = 'big' }),
        },
        ['Neveras'] = {
            M('nevera_caja', 8500, 'Nevera con forma de caja de herramientas', { type = 'stash', stash = 'normal' }),
        },
        ['Armarios'] = {
            M('taquilla_pilotos', 6500, 'Taquilla de piloto', { type = 'wardrobe' }),
        },
        ['Sillones'] = {
            M('sofa_trasera', 16000, 'Sofá de trasera de coche clásico'),
        },
        ['Mesas'] = {
            M('mesa_v8', 12000, 'Mesa de centro de motor V8'),
            M('barril_mesa', 4000, 'Mesa alta de bidón'),
        },
        ['Decoración'] = {
            M('chapa_xero', 2200, 'Cartel de chapa de gasolina'),
            M('chapa_pis', 2000, 'Cartel de chapa de cerveza'),
            M('chapa_redwood', 2000, 'Cartel de chapa de tabaco'),
        },
        ['Carteles de neón'] = {
            M('neon_coche', 6500, 'Neón de coche clásico «Motor Club»'),
        },
    },
    animados = Animados({ 'vitrina_cascos', 'armario_taller', 'banco_trabajo', 'nevera_caja', 'taquilla_pilotos', 'semaforo_salida' }),
})

-- Asiento (config/especiales.lua): x/y desde el centro del modelo, z sobre su base.
if Config.Especiales and Config.Especiales.modelos then
    local E = Config.Especiales.modelos
    if E[P .. 'sofa_trasera'] == nil then E[P .. 'sofa_trasera'] = { asiento = { x = -0.40, y = -0.08, z = 0.56 } } end
end
