-- Muebles propios de SALÓN (modelos: fuente/pack_sal.py, origen_casa_sal_*;
-- quién mueve las partes: custom/client/almacenajes.lua con Config.Animados;
-- quién sienta: custom/client/especiales.lua con Config.Especiales.modelos).
-- Tres lotes:
--   base            el sofá viejo y la mesa de madera que tiene cualquier casa
--   salon_moderno   sofás de tela, chaise longue, modular, sofá cama, reclinable, mesas, mueble de TV y chimenea eléctrica
--   salon_clasico   chester, orejero, aparador, librería, vitrina, mueble bar y carrito de bebidas
-- Las medidas de las partes y de los asientos las escribe fuente/pack_sal.py al
-- acabar (líneas «LUA» y «ASIENTO»): si se cambia un modelo, aquí también.

local function M(id, precio, nombre)
    return { model = 'origen_casa_sal_' .. id, price = precio, nombre = nombre, label = nombre }
end

local P = 'origen_casa_sal_'

Config.Packs.Registrar({
    id = 'base',
    categorias = {
        ['Sillones'] = {
            M('sofa_viejo', 1800, 'Sofá viejo de piso franco'),
        },
        ['Mesas'] = {
            M('mesa_maciza', 1500, 'Mesa de centro de madera maciza'),
        },
    },
})

Config.Packs.Registrar({
    id = 'salon_moderno', nombre = 'Salón moderno',
    descripcion = 'Sofás de tela, chaise longue, modular de esquina, sofá cama que se abre, sillón reclinable, mesas de centro, mueble de TV y chimenea eléctrica que alumbra',
    xp = 0,
    categorias = {
        ['Sillones'] = {
            M('puf', 1500, 'Puf redondo de punto'),
            M('butaca', 3200, 'Butaca nórdica'),
            M('sofa3', 4500, 'Sofá de tres plazas'),
            M('sofacama', 7500, 'Sofá cama'),
            M('reclinable', 8500, 'Sillón reclinable de cuero'),
            M('chaise', 9500, 'Sofá chaise longue'),
            M('modular', 14000, 'Sofá modular de esquina'),
        },
        ['Mesas'] = {
            M('auxiliar_ind', 2200, 'Mesa auxiliar industrial con cajón'),
            M('mesa_cristal', 3800, 'Mesa de centro de cristal y acero'),
            M('mesa_elevable', 4800, 'Mesa de centro elevable'),
        },
        ['Muebles'] = {
            M('estanteria', 4200, 'Estantería industrial'),
            M('mueble_tv', 5200, 'Mueble bajo de TV'),
        },
        ['Decoración'] = {
            M('chimenea', 18000, 'Chimenea eléctrica de pared'),
        },
    },
    animados = {
        [P .. 'sofacama'] = { uso = 'E', texto = { 'Abrir la cama', 'Recoger la cama' }, partes = { { modelo = P .. 'sofacama_cama', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.80, ms = 1100 } } },
        [P .. 'reclinable'] = { uso = 'E', texto = { 'Reclinar', 'Incorporar' }, partes = { { modelo = P .. 'reclinable_respaldo', pos = { 0.000, 0.220, 0.400 }, modo = 'gira', eje = 'x', angulo = -34.0, ms = 1200 }, { modelo = P .. 'reclinable_reposapies', pos = { 0.000, -0.405, 0.410 }, modo = 'gira', eje = 'x', angulo = -86.0, ms = 1200 } } },
        [P .. 'mesa_elevable'] = { uso = 'E', texto = { 'Subir la tapa', 'Bajar la tapa' }, partes = { { modelo = P .. 'mesa_elevable_tapa', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = 0.19, ms = 900 } } },
        [P .. 'auxiliar_ind'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'auxiliar_ind_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.26, ms = 600 } } },
        [P .. 'mueble_tv'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'mueble_tv_puerta_i', pos = { -0.605, -0.210, 0.104 }, modo = 'gira', eje = 'x', angulo = 88.0, ms = 700 }, { modelo = P .. 'mueble_tv_puerta_d', pos = { 0.605, -0.210, 0.104 }, modo = 'gira', eje = 'x', angulo = 88.0, ms = 700 } } },
    },
})

Config.Packs.Registrar({
    id = 'salon_clasico', nombre = 'Salón clásico',
    descripcion = 'Chester de cuero capitoné, orejero de terciopelo, aparador y librería de madera noble, vitrina de cristal, mueble bar con luz y carrito de bebidas',
    xp = 0,
    categorias = {
        ['Sillones'] = {
            M('orejero', 6500, 'Sillón orejero de terciopelo'),
            M('chester', 16000, 'Sofá chester de cuero'),
        },
        ['Mesas'] = {
            M('auxiliar', 2800, 'Mesa auxiliar de latón y mármol'),
        },
        ['Muebles'] = {
            M('carrito', 5500, 'Carrito de bebidas'),
            M('aparador', 7500, 'Aparador clásico de caoba'),
            M('libreria', 8500, 'Librería clásica de nogal'),
            M('vitrina', 11000, 'Vitrina con puertas de cristal'),
            M('mueble_bar', 22000, 'Mueble bar'),
        },
    },
    animados = {
        [P .. 'aparador'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'aparador_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.26, ms = 600 }, { modelo = P .. 'aparador_puerta_i', pos = { -0.818, -0.240, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 700 }, { modelo = P .. 'aparador_puerta_d', pos = { 0.818, -0.240, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 700 } } },
        [P .. 'libreria'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'libreria_puerta_i', pos = { -0.548, -0.200, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 700 }, { modelo = P .. 'libreria_puerta_d', pos = { 0.548, -0.200, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 700 } } },
        [P .. 'vitrina'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'vitrina_puerta_i', pos = { -0.498, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 700 }, { modelo = P .. 'vitrina_puerta_d', pos = { 0.498, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 700 } } },
        [P .. 'mueble_bar'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'mueble_bar_puerta_i', pos = { -0.468, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = -110.0, ms = 700 }, { modelo = P .. 'mueble_bar_puerta_d', pos = { 0.468, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 700 }, { modelo = P .. 'mueble_bar_tapa', pos = { 0.000, 0.250, 1.096 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 800 } } },
    },
})

-- ── Sentarse ────────────────────────────────────────────────────────────
-- Un asiento por mueble (el sistema de config/especiales.lua no lleva más):
-- en los sofás, la plaza del centro o la más cómoda. x/y, desde el centro de
-- la caja del modelo; z, sobre su base. El respaldo queda del lado +Y, así que
-- vale el giro de siempre (180).
-- El sofá cama no lleva asiento: su E es la de abrir la cama. El reclinable
-- lleva las dos cosas (sentarse y reclinar salen con la misma E).
local ASIENTOS = {
    [P .. 'sofa3'] = { asiento = { x = 0.00, y = -0.06, z = 0.49 } },
    [P .. 'chaise'] = { asiento = { x = -0.50, y = 0.28, z = 0.49 } },
    [P .. 'chester'] = { asiento = { x = 0.00, y = -0.03, z = 0.47 } },
    [P .. 'sofa_viejo'] = { asiento = { x = -0.39, y = -0.08, z = 0.46 } },
    [P .. 'modular'] = { asiento = { x = 0.60, y = 0.42, z = 0.48 } },
    [P .. 'orejero'] = { asiento = { x = 0.00, y = -0.04, z = 0.49 } },
    [P .. 'reclinable'] = { asiento = { x = -0.02, y = -0.05, z = 0.50 } },
    [P .. 'butaca'] = { asiento = { x = 0.00, y = -0.07, z = 0.45 } },
    [P .. 'puf'] = { asiento = { x = 0.00, y = 0.00, z = 0.43 } },
}
if Config.Especiales and type(Config.Especiales.modelos) == 'table' then
    for modelo, datos in pairs(ASIENTOS) do
        if Config.Especiales.modelos[modelo] == nil then Config.Especiales.modelos[modelo] = datos end
    end
end
