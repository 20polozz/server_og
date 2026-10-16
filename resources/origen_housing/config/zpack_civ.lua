-- Muebles propios CIVILES: lo cotidiano de una casa vivida (modelos:
-- fuente/pack_civ.py, origen_casa_civ_*; quién mueve las partes:
-- custom/client/almacenajes.lua con Config.Animados; quién sienta y acuesta:
-- custom/client/especiales.lua con Config.Especiales.modelos). Tres lotes:
--   civiles         la entrada, la colada y la limpieza, las mascotas, las aficiones y el piso de estudiante
--   familia         el cuarto de los niños
--   celebraciones   Navidad y cumpleaños
-- Las medidas de las partes, de los asientos y de las camas las escribe
-- fuente/pack_civ.py al acabar (líneas «LUA», «ASIENTO» y «CAMA»): si se cambia
-- un modelo, aquí también.
-- Los de pared (pizarra, corcho, calendario, pósters, guirnalda, pancarta) tienen
-- el origen en su canto de abajo: se colocan y se suben. Los que alumbran
-- (pecera, flexo, árbol, guirnalda) llevan la luz dentro del modelo: no se apagan.

local P = 'origen_casa_civ_'

local function M(id, precio, nombre)
    return { model = P .. id, price = precio, nombre = nombre, label = nombre }
end

Config.Packs.Registrar({
    id = 'civiles', nombre = 'Pack Civiles',
    descripcion = 'La casa de alguien que vive en ella: perchero con abrigos, zapatero y recibidor, felpudos con mensaje, tendedero, tabla de planchar, nevera con imanes, las cosas del perro y del gato, pecera con luz, guitarra, vinilos, caballete, tabla de surf y el piso de estudiante al completo',
    xp = 0,
    categorias = {
        ['Muebles'] = {
            M('perchero', 2800, 'Perchero de pared con abrigos'),
            M('zapatero', 3200, 'Zapatero abatible'),
            M('recibidor', 3800, 'Mueble recibidor con cuenco de llaves'),
            M('estanteria_cubos', 3200, 'Estantería de cubos'),
            M('vinilos', 6500, 'Mueble de vinilos con tocadiscos'),
        },
        ['Decoración'] = {
            M('paraguero', 1800, 'Paragüero con paraguas'),
            M('pizarra_tareas', 1800, 'Pizarra de tareas de la semana'),
            M('corcho_fotos', 1800, 'Corcho con fotos'),
            M('calendario', 1500, 'Calendario de pared'),
            M('poster_ovni', 1500, 'Póster del platillo'),
            M('poster_tebeo', 1500, 'Póster de tebeo'),
            M('poster_fauna', 1500, 'Póster de turismo'),
            M('tabla_surf', 3500, 'Tabla de surf apoyada'),
            M('bolsas_compra', 1500, 'Bolsas de la compra'),
        },
        ['Alfombras'] = {
            M('felpudo_bienvenidos', 1500, 'Felpudo «Bienvenidos»'),
            M('felpudo_hogar', 1500, 'Felpudo «Hogar dulce hogar»'),
            M('felpudo_pies', 1500, 'Felpudo «Límpiate los pies»'),
            M('felpudo_otravez', 1500, 'Felpudo «¿Otra vez tú?»'),
        },
        ['Lavandería y limpieza'] = {
            M('tendedero', 2200, 'Tendedero con ropa'),
            M('tabla_planchar', 2400, 'Tabla de planchar con plancha'),
            M('cesto_colada', 1600, 'Cesto de la colada'),
            M('limpieza', 1800, 'Cubo, fregona y escoba'),
            M('cubo_pedal', 1600, 'Cubo de basura de pedal'),
        },
        ['Neveras'] = {
            M('nevera', 4800, 'Nevera con imanes y dibujos'),
        },
        ['Mascotas'] = {
            M('cama_perro', 2200, 'Cama de perro'),
            M('comedero', 1600, 'Comedero y bebedero'),
            M('rascador', 3200, 'Rascador de gato'),
            M('pecera', 4500, 'Pecera con luz'),
            M('transportin', 2000, 'Transportín'),
        },
        ['Arte'] = {
            M('caballete', 3500, 'Caballete con lienzo'),
        },
        ['Instrumentos'] = {
            M('guitarra', 4200, 'Guitarra en su soporte'),
        },
        ['Plantas'] = {
            M('hierbas', 1600, 'Maceteros de hierbas de cocina'),
        },
        ['Escritorios'] = {
            M('escritorio_flexo', 3800, 'Escritorio de estudiante con flexo'),
        },
        ['Sillas'] = {
            M('silla_plegable', 1500, 'Silla plegable'),
        },
        ['Camas'] = {
            M('colchon_pales', 3500, 'Colchón sobre palés'),
        },
    },
    animados = {
        [P .. 'zapatero'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'zapatero_frente_a', pos = { 0.000, -0.130, 0.092 }, modo = 'gira', eje = 'x', angulo = 36.0, ms = 600 }, { modelo = P .. 'zapatero_frente_b', pos = { 0.000, -0.130, 0.572 }, modo = 'gira', eje = 'x', angulo = 36.0, ms = 600 } } },
        [P .. 'recibidor'] = { uso = 'E', texto = { 'Abrir el cajón', 'Cerrar el cajón' }, partes = { { modelo = P .. 'recibidor_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.20, ms = 600 } } },
        [P .. 'cubo_pedal'] = { uso = 'E', texto = { 'Pisar el pedal', 'Soltar el pedal' }, partes = { { modelo = P .. 'cubo_pedal_tapa', pos = { 0.000, 0.155, 0.590 }, modo = 'gira', eje = 'x', angulo = -72.0, ms = 450 } } },
        [P .. 'nevera'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'nevera_puerta', pos = { 0.280, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = 115.0, ms = 700 } } },
        [P .. 'transportin'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'transportin_puerta', pos = { 0.165, -0.315, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 600 } } },
    },
})

Config.Packs.Registrar({
    id = 'familia', nombre = 'Pack Familia',
    descripcion = 'El cuarto de los niños: cama coche de carreras, baúl de juguetes que se abre, estantería casita con sus cuentos, alfombra de carreteras, caballito balancín y trona',
    xp = 0,
    categorias = {
        ['Camas'] = {
            M('cama_coche', 7500, 'Cama coche de carreras'),
        },
        ['Juegos y juguetes'] = {
            M('baul_juguetes', 2800, 'Baúl de juguetes'),
            M('caballito', 2500, 'Caballito balancín'),
        },
        ['Muebles'] = {
            M('estanteria_cuentos', 3500, 'Estantería casita de cuentos'),
        },
        ['Alfombras'] = {
            M('alfombra_carreteras', 2200, 'Alfombra de carreteras'),
        },
        ['Sillas'] = {
            M('trona', 2400, 'Trona'),
        },
    },
    animados = {
        [P .. 'baul_juguetes'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'baul_juguetes_tapa', pos = { 0.000, 0.220, 0.420 }, modo = 'gira', eje = 'x', angulo = -92.0, ms = 700 } } },
    },
})

Config.Packs.Registrar({
    id = 'celebraciones', nombre = 'Pack Celebraciones',
    descripcion = 'Para Navidad y para los cumpleaños: árbol con luces que alumbran, regalos, guirnalda de bombillas, mesa de cumpleaños con tarta, globos y la pancarta de «Feliz cumpleaños»',
    xp = 0,
    categorias = {
        ['Decoración'] = {
            M('arbol_navidad', 6500, 'Árbol de Navidad con luces'),
            M('regalos', 2500, 'Montón de regalos'),
            M('guirnalda_luces', 2800, 'Guirnalda de luces de pared'),
            M('globos', 1800, 'Globos de cumpleaños'),
            M('pancarta', 1800, 'Pancarta «Feliz cumpleaños»'),
        },
        ['Mesas'] = {
            M('mesa_cumple', 4500, 'Mesa de cumpleaños con tarta'),
        },
    },
})

-- Dónde se sienta y dónde se acuesta uno (custom/client/especiales.lua).
-- asiento = { x, y, z }: x/y desde el centro del modelo, z sobre su base; el
-- respaldo queda del lado +Y (giro de siempre). cama = { x, y, z, giro }: z
-- desde lo más alto del modelo (negativa: el colchón queda por debajo del
-- alerón de la cama coche); la cabeza, hacia +Y, como en las camas de zpack_dor.
local ESPECIALES = {
    [P .. 'silla_plegable'] = { asiento = { x = 0.00, y = -0.02, z = 0.46 } },
    [P .. 'cama_coche'] = { cama = { x = 0.00, y = -0.12, z = -0.33, giro = 0.0 } },
    [P .. 'colchon_pales'] = { cama = { x = 0.00, y = -0.12, z = -0.04, giro = 0.0 } },
}
if Config.Especiales and type(Config.Especiales.modelos) == 'table' then
    for modelo, datos in pairs(ESPECIALES) do
        if Config.Especiales.modelos[modelo] == nil then Config.Especiales.modelos[modelo] = datos end
    end
end
