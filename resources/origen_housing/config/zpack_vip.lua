-- LUJO y GUARIDA: muebles propios pensados para vender (modelos: fuente/pack_vip.py,
-- origen_casa_vip_*; quién mueve las partes: custom/client/almacenajes.lua con
-- Config.Animados; quién sienta: custom/client/especiales.lua). Cuatro packs temáticos:
--   mansion         piano de cola, despacho, trono, araña, fuente, comedor de diez, cama redonda, cajas fuertes
--   coleccionista   vitrinas con cristal y luz, acuarios, cava, botellero, barril
--   banda           «Pack Banda»: la guarida (estandartes en seis colores, reuniones, dinero, fuego…)
--   laboratorio     laboratorio y cultivo clandestino, decorativo
-- Las medidas de las partes las escribe fuente/pack_vip.py al acabar (líneas «LUA»):
-- si se cambia un modelo, aquí también (este fichero se generó con ellas).
-- Con luz de verdad dentro del .ydr (siempre encendida): araña, fuente, cámara acorazada,
-- las tres vitrinas, los dos acuarios, la cava, el barril de fuego, la tienda y la lámpara de cultivo.
-- Las partes que se abren no llevan colisión: la valla y la cámara se cruzan por el hueco
-- esté la hoja abierta o cerrada.

local P = 'origen_casa_vip_'

local function M(id, precio, nombre, alijo)
    local it = { model = P .. id, price = precio, nombre = nombre, label = nombre }
    if alijo then it.type, it.stash = 'stash', alijo end     -- tamaños de config/stashes.lua
    return it
end

Config.Packs.Registrar({
    id = 'mansion', nombre = 'Pack Mansión',
    descripcion = 'Lujo de verdad: piano de cola que se abre, despacho presidencial, sillón trono, araña de cristal con luz, fuente de mármol, comedor de diez, cama redonda, caja fuerte dorada y cámara acorazada con puerta de banco',
    xp = 0, grupo = 'tematico',
    categorias = {
        ['Instrumentos'] = {
            M('piano', 38000, 'Piano de cola'),
        },
        ['Escritorios'] = {
            M('escritorio', 22000, 'Mesa de despacho presidencial'),
        },
        ['Sillones'] = {
            M('trono', 18000, 'Sillón trono'),
        },
        ['Luces'] = {
            M('arana', 16000, 'Lámpara de araña de cristal'),
        },
        ['Decoración'] = {
            M('fuente', 24000, 'Fuente interior de mármol'),
        },
        ['Mesas'] = {
            M('comedor', 32000, 'Mesa de comedor de diez con sillas'),
        },
        ['Camas'] = {
            M('cama_redonda', 20000, 'Cama redonda de lujo'),
        },
        ['Esculturas y premios'] = {
            M('escultura', 12000, 'Esfera armilar dorada sobre pedestal'),
        },
        ['Alfombras'] = {
            M('alfombra_piel', 8000, 'Alfombra de piel de vaca'),
        },
        ['Almacenaje'] = {
            M('caja_dorada', 28000, 'Caja fuerte de lujo dorada', 'extrabig'),
            M('camara', 40000, 'Cámara acorazada', 'extrabig'),
        },
    },
    animados = {
        [P .. 'piano'] = { uso = 'E', texto = { 'Abrir la tapa', 'Cerrar la tapa' }, partes = { { modelo = 'origen_casa_vip_piano_tapa', pos = { -0.750, 0.000, 0.955 }, modo = 'gira', eje = 'y', angulo = -38.0, ms = 1400 } } },
        [P .. 'escritorio'] = { uso = 'E', texto = { 'Abrir el cajón', 'Cerrar el cajón' }, partes = { { modelo = 'origen_casa_vip_escritorio_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = 0.32, ms = 600 } } },
        [P .. 'caja_dorada'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_vip_caja_dorada_puerta', pos = { 0.400, -0.290, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 900 } } },
        [P .. 'camara'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_vip_camara_puerta', pos = { 0.940, -0.660, 0.000 }, modo = 'gira', eje = 'z', angulo = 100.0, ms = 2400 } } },
    },
})

Config.Packs.Registrar({
    id = 'coleccionista', nombre = 'Pack Coleccionista',
    descripcion = 'Para enseñar lo que tienes: vitrinas con cristal y luz que se abren (joyas, trofeos y katanas), acuario de pared y acuario columna iluminados, cava climatizada, botellero a medida, barril y mesa de cata',
    xp = 0, grupo = 'tematico',
    categorias = {
        ['Joyas'] = {
            M('vitrina_joyas', 15000, 'Vitrina de joyería'),
        },
        ['Trofeos'] = {
            M('vitrina_trofeos', 12000, 'Vitrina de trofeos'),
        },
        ['Muebles'] = {
            M('vitrina_katanas', 16000, 'Vitrina de katanas'),
            M('botellero', 12000, 'Botellero de pared a medida'),
        },
        ['Decoración'] = {
            M('acuario_columna', 18000, 'Acuario columna'),
            M('acuario', 30000, 'Acuario grande de pared'),
        },
        ['Bebidas'] = {
            M('barril', 4500, 'Barril de roble en su cuna'),
            M('mesa_cata', 6000, 'Mesa de cata sobre barril'),
            M('cava', 14000, 'Cava climatizada'),
        },
    },
    animados = {
        [P .. 'vitrina_joyas'] = { uso = 'E', texto = { 'Abrir la vitrina', 'Cerrar la vitrina' }, partes = { { modelo = 'origen_casa_vip_vitrina_joyas_tapa', pos = { 0.000, 0.295, 0.985 }, modo = 'gira', eje = 'x', angulo = -55.0, ms = 900 } } },
        [P .. 'vitrina_trofeos'] = { uso = 'E', texto = { 'Abrir la vitrina', 'Cerrar la vitrina' }, partes = { { modelo = 'origen_casa_vip_vitrina_trofeos_puerta', pos = { 0.500, -0.225, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        [P .. 'vitrina_katanas'] = { uso = 'E', texto = { 'Abrir la vitrina', 'Cerrar la vitrina' }, partes = { { modelo = 'origen_casa_vip_vitrina_katanas_puerta', pos = { 0.745, -0.205, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        [P .. 'cava'] = { uso = 'E', texto = { 'Abrir la cava', 'Cerrar la cava' }, partes = { { modelo = 'origen_casa_vip_cava_puerta', pos = { 0.350, -0.340, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 600 } } },
    },
})

Config.Packs.Registrar({
    id = 'banda', nombre = 'Pack Banda',
    descripcion = 'La guarida de tu banda: estandartes en seis colores, mesa de reuniones, sofá de palés, barril de fuego que alumbra, tablón de territorio, pizarra de objetivos, caja de botín, mesa de contar dinero, palé de fajos, valla con candado, nevera con pegatinas y mucho más',
    xp = 0, grupo = 'tematico',
    categorias = {
        ['Guarida'] = {
            M('silla_vieja', 1500, 'Silla vieja de madera'),
            M('silla_plegable', 1500, 'Silla plegable'),
            M('estandarte_roja', 1800, 'Estandarte de banda rojo'),
            M('estandarte_morada', 1800, 'Estandarte de banda morado'),
            M('estandarte_verde', 1800, 'Estandarte de banda verde'),
            M('estandarte_negra', 1800, 'Estandarte de banda negro'),
            M('estandarte_azul', 1800, 'Estandarte de banda azul'),
            M('estandarte_amarilla', 1800, 'Estandarte de banda amarillo'),
            M('colchones', 1800, 'Colchones en el suelo'),
            M('bidones', 2000, 'Bidones'),
            M('bidon_mesa', 2200, 'Bidón-mesa'),
            M('mesa_reunion', 2500, 'Mesa de reuniones (puerta y caballetes)'),
            M('lona_grafiti', 2500, 'Lona con grafiti'),
            M('pizarra', 2800, 'Pizarra de objetivos'),
            M('tele_tubo', 2800, 'Tele de tubo sobre cajón'),
            M('bidon_fuego', 3000, 'Barril de fuego'),
            M('tablon', 3200, 'Tablón de territorio'),
            M('nevera', 3200, 'Nevera vieja con pegatinas'),
            M('sofa_pales', 3500, 'Sofá de palés'),
            M('pesas', 3500, 'Pesas caseras'),
            M('valla', 4000, 'Valla metálica con candado'),
            M('altavoz', 4500, 'Altavoz portátil'),
            M('caja_botin', 5500, 'Caja de botín', 'big'),
            M('mesa_dinero', 9000, 'Mesa de contar dinero'),
            M('pale_fajos', 15000, 'Palé de fajos envuelto'),
        },
    },
    iconos = { ['Guarida'] = 'fas fa-skull' },
    animados = {
        [P .. 'nevera'] = { uso = 'E', texto = { 'Abrir la nevera', 'Cerrar la nevera' }, partes = { { modelo = 'origen_casa_vip_nevera_puerta', pos = { 0.350, -0.330, 0.000 }, modo = 'gira', eje = 'z', angulo = 115.0, ms = 600 } } },
        [P .. 'valla'] = { uso = 'E', texto = { 'Abrir la valla', 'Cerrar la valla' }, partes = { { modelo = 'origen_casa_vip_valla_puerta', pos = { 1.250, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = 100.0, ms = 1200 } } },
        [P .. 'caja_botin'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_vip_caja_botin_tapa', pos = { 0.000, 0.300, 0.500 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 800 } } },
    },
})

Config.Packs.Registrar({
    id = 'laboratorio', nombre = 'Pack Laboratorio',
    descripcion = 'Ambientación de laboratorio y cultivo clandestino (decorativo): mesa de trabajo con matraces y hornillo, estantería de garrafas, tienda de cultivo que se abre y lámpara de cultivo con luz morada',
    xp = 0, grupo = 'tematico',
    categorias = {
        ['Sótano'] = {
            M('garrafas', 4000, 'Estantería de garrafas'),
            M('lampara_cultivo', 5000, 'Lámpara de cultivo'),
            M('mesa_lab', 8500, 'Mesa de laboratorio'),
            M('tienda_cultivo', 9500, 'Tienda de cultivo'),
        },
    },
    animados = {
        [P .. 'tienda_cultivo'] = { uso = 'E', texto = { 'Abrir la tienda', 'Cerrar la tienda' }, partes = { { modelo = 'origen_casa_vip_tienda_cultivo_solapa', pos = { 0.615, -0.620, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 1000 } } },
    },
})

-- ── Sentarse ────────────────────────────────────────────────────────────
-- Un asiento por mueble (config/especiales.lua): x/y desde el centro del modelo, z sobre su base.
local ASIENTOS = {
    [P .. 'trono'] = { asiento = { x = 0.00, y = -0.05, z = 0.51 } },
    [P .. 'silla_vieja'] = { asiento = { x = 0.00, y = -0.02, z = 0.50 } },
    [P .. 'silla_plegable'] = { asiento = { x = 0.00, y = -0.02, z = 0.46 } },
    [P .. 'sofa_pales'] = { asiento = { x = 0.00, y = -0.10, z = 0.45 } },
}
if Config.Especiales and type(Config.Especiales.modelos) == 'table' then
    for modelo, datos in pairs(ASIENTOS) do
        if Config.Especiales.modelos[modelo] == nil then Config.Especiales.modelos[modelo] = datos end
    end
end
