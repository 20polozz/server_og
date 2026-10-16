-- Ocio, bar, gimnasio, terraza y cine: muebles propios (modelos: fuente/pack_oci.py,
-- texturas del juego: fuente/texturas_pack_oci.py; quién mueve las partes:
-- custom/client/almacenajes.lua con Config.Animados). Cuatro packs:
--   sala_de_juegos   billar, futbolín, ping-pong, diana, póquer, recreativa, pinball, jukebox, air hockey y el cine
--   bar_en_casa      barra por tramos, botellero con luz, nevera, grifo, barriles, taburete y neón
--   gimnasio_casa    banco con barra, mancuernas, cinta, saco, espaldera, esterilla, pesas rusas y espejo
--   terraza          tumbona, sombrilla, sofá y sillón de ratán, mesa baja, barbacoa, brasero, macetero y farol
-- Las medidas de las partes las escribe fuente/pack_oci.py al acabar (líneas
-- «LUA»): si se cambia un modelo, aquí también. Son muebles de adorno: los del
-- gimnasio no son las máquinas usables de origen_gym.
-- Precios provisionales (los repasa config/zz_economia.lua si existe).

Config.Packs.Registrar({
    id = 'sala_de_juegos', nombre = 'Sala de juegos y cine',
    descripcion = 'Billar con su taquera, futbolín, ping-pong plegable, diana con armario, mesa de póquer, recreativa, pinball y jukebox con luz, air hockey y un cine en casa con butacas, pantalla y carrito de palomitas',
    xp = 0,
    categorias = {
        ['Juegos y juguetes'] = {
            { model = 'origen_casa_oci_billar', price = 18000, nombre = 'Mesa de billar de caoba', label = 'Mesa de billar de caoba' },
            { model = 'origen_casa_oci_taquera', price = 2800, nombre = 'Taquera de pared', label = 'Taquera de pared' },
            { model = 'origen_casa_oci_futbolin', price = 7500, nombre = 'Futbolín', label = 'Futbolín' },
            { model = 'origen_casa_oci_pingpong', price = 6500, nombre = 'Mesa de ping-pong plegable', label = 'Mesa de ping-pong plegable' },
            { model = 'origen_casa_oci_diana', price = 2500, nombre = 'Diana con armario', label = 'Diana con armario' },
            { model = 'origen_casa_oci_poquer', price = 14000, nombre = 'Mesa de póquer', label = 'Mesa de póquer' },
            { model = 'origen_casa_oci_recreativa', price = 16000, nombre = 'Máquina recreativa', label = 'Máquina recreativa' },
            { model = 'origen_casa_oci_pinball', price = 19000, nombre = 'Pinball', label = 'Pinball' },
            { model = 'origen_casa_oci_jukebox', price = 22000, nombre = 'Jukebox clásica', label = 'Jukebox clásica' },
            { model = 'origen_casa_oci_airhockey', price = 9500, nombre = 'Mesa de air hockey', label = 'Mesa de air hockey' },
            { model = 'origen_casa_oci_palomitas', price = 8500, nombre = 'Carrito de palomitas', label = 'Carrito de palomitas' },
        },
        ['Sillones'] = {
            { model = 'origen_casa_oci_butaca', price = 4500, nombre = 'Butaca de cine', label = 'Butaca de cine' },
            { model = 'origen_casa_oci_butacas3', price = 12000, nombre = 'Fila de tres butacas de cine', label = 'Fila de tres butacas de cine' },
        },
        ['Tecnología'] = {
            { model = 'origen_casa_oci_pantalla', price = 9000, nombre = 'Pantalla de proyección', label = 'Pantalla de proyección' },
        },
    },
    animados = {
        ['origen_casa_oci_pingpong'] = { uso = 'E', texto = { 'Plegar', 'Desplegar' }, partes = {
            { modelo = 'origen_casa_oci_pingpong_mitad_i', pos = { -0.030, 0.000, 0.760 }, modo = 'gira', eje = 'y', angulo = 86.0, ms = 1100 },
            { modelo = 'origen_casa_oci_pingpong_pata_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.78, ms = 1100 },
            { modelo = 'origen_casa_oci_pingpong_mitad_d', pos = { 0.030, 0.000, 0.760 }, modo = 'gira', eje = 'y', angulo = -86.0, ms = 1100 },
            { modelo = 'origen_casa_oci_pingpong_pata_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.78, ms = 1100 },
        } },
        ['origen_casa_oci_diana'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = {
            { modelo = 'origen_casa_oci_diana_puerta_i', pos = { -0.310, -0.030, 0.000 }, modo = 'gira', eje = 'z', angulo = -165.0, ms = 700 },
            { modelo = 'origen_casa_oci_diana_puerta_d', pos = { 0.310, -0.030, 0.000 }, modo = 'gira', eje = 'z', angulo = 165.0, ms = 700 },
        } },
    },
})

Config.Packs.Registrar({
    id = 'bar_en_casa', nombre = 'Bar en casa',
    descripcion = 'Una barra de caoba y mármol por tramos (recto, esquina y con fregadero), botellero retroiluminado, nevera de puerta de cristal que se abre, grifo de cerveza, barriles, taburetes y un neón de «BAR» que alumbra',
    xp = 0,
    categorias = {
        ['Bebidas'] = {
            { model = 'origen_casa_oci_barra_recta', price = 9000, nombre = 'Barra de bar: tramo recto', label = 'Barra de bar: tramo recto' },
            { model = 'origen_casa_oci_barra_esquina', price = 6500, nombre = 'Barra de bar: esquina', label = 'Barra de bar: esquina' },
            { model = 'origen_casa_oci_barra_fregadero', price = 11500, nombre = 'Barra de bar: tramo con fregadero', label = 'Barra de bar: tramo con fregadero' },
            { model = 'origen_casa_oci_botellero', price = 15000, nombre = 'Botellero retroiluminado', label = 'Botellero retroiluminado' },
            { model = 'origen_casa_oci_nevera', price = 5500, nombre = 'Nevera de bar con puerta de cristal', label = 'Nevera de bar con puerta de cristal' },
            { model = 'origen_casa_oci_grifo', price = 3500, nombre = 'Grifo de cerveza de tres caños', label = 'Grifo de cerveza de tres caños' },
            { model = 'origen_casa_oci_barril_cerveza', price = 1500, nombre = 'Barril de cerveza', label = 'Barril de cerveza' },
            { model = 'origen_casa_oci_barril_mesa', price = 3200, nombre = 'Mesa alta de barril', label = 'Mesa alta de barril' },
        },
        ['Sillas'] = {
            { model = 'origen_casa_oci_taburete', price = 1800, nombre = 'Taburete alto de bar', label = 'Taburete alto de bar' },
        },
        ['Carteles de neón'] = {
            { model = 'origen_casa_oci_neon_bar', price = 4500, nombre = 'Neón «BAR»', label = 'Neón «BAR»' },
        },
    },
    animados = {
        ['origen_casa_oci_nevera'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = {
            { modelo = 'origen_casa_oci_nevera_puerta', pos = { 0.310, -0.240, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 700 },
        } },
    },
})

Config.Packs.Registrar({
    id = 'gimnasio_casa', nombre = 'Gimnasio en casa',
    descripcion = 'Banco de pesas con barra y respaldo inclinable, rack de mancuernas, cinta de correr, saco de boxeo con soporte, espaldera, esterilla, pesas rusas y espejo de pared',
    xp = 0,
    categorias = {
        ['Gimnasio'] = {
            { model = 'origen_casa_oci_banco_pesas', price = 7500, nombre = 'Banco de pesas con barra', label = 'Banco de pesas con barra' },
            { model = 'origen_casa_oci_mancuernas', price = 5500, nombre = 'Rack de mancuernas', label = 'Rack de mancuernas' },
            { model = 'origen_casa_oci_cinta', price = 9500, nombre = 'Cinta de correr', label = 'Cinta de correr' },
            { model = 'origen_casa_oci_saco', price = 4800, nombre = 'Saco de boxeo con soporte', label = 'Saco de boxeo con soporte' },
            { model = 'origen_casa_oci_espaldera', price = 2600, nombre = 'Espaldera', label = 'Espaldera' },
            { model = 'origen_casa_oci_esterilla', price = 1500, nombre = 'Esterilla y rodillo', label = 'Esterilla y rodillo' },
            { model = 'origen_casa_oci_kettlebells', price = 1800, nombre = 'Juego de pesas rusas', label = 'Juego de pesas rusas' },
            { model = 'origen_casa_oci_espejo_gym', price = 3000, nombre = 'Espejo de gimnasio', label = 'Espejo de gimnasio' },
        },
    },
    animados = {
        ['origen_casa_oci_banco_pesas'] = { uso = 'E', texto = { 'Inclinar el respaldo', 'Tumbar el respaldo' }, partes = {
            { modelo = 'origen_casa_oci_banco_pesas_respaldo', pos = { 0.000, -0.200, 0.420 }, modo = 'gira', eje = 'x', angulo = 32.0, ms = 900 },
        } },
    },
})

Config.Packs.Registrar({
    id = 'terraza', nombre = 'Terraza y jardín',
    descripcion = 'Tumbona de teca con respaldo reclinable, sombrilla que se inclina, sofá y sillón de ratán con sus cojines, mesa baja de cristal, barbacoa de gas con tapa, brasero y farol que alumbran, y un macetero grande',
    xp = 0,
    categorias = {
        ['Jardín y patio'] = {
            { model = 'origen_casa_oci_tumbona', price = 4200, nombre = 'Tumbona de teca', label = 'Tumbona de teca' },
            { model = 'origen_casa_oci_sombrilla', price = 3800, nombre = 'Sombrilla de rayas', label = 'Sombrilla de rayas' },
            { model = 'origen_casa_oci_sofa_ratan', price = 11000, nombre = 'Sofá de ratán de tres plazas', label = 'Sofá de ratán de tres plazas' },
            { model = 'origen_casa_oci_sillon_ratan', price = 5200, nombre = 'Sillón de ratán', label = 'Sillón de ratán' },
            { model = 'origen_casa_oci_mesa_terraza', price = 3600, nombre = 'Mesa baja de ratán y cristal', label = 'Mesa baja de ratán y cristal' },
            { model = 'origen_casa_oci_barbacoa', price = 12500, nombre = 'Barbacoa de gas', label = 'Barbacoa de gas' },
            { model = 'origen_casa_oci_brasero', price = 8000, nombre = 'Brasero de piedra', label = 'Brasero de piedra' },
            { model = 'origen_casa_oci_macetero', price = 2800, nombre = 'Macetero grande con ave del paraíso', label = 'Macetero grande con ave del paraíso' },
            { model = 'origen_casa_oci_farol', price = 1600, nombre = 'Farol de vela', label = 'Farol de vela' },
        },
    },
    animados = {
        ['origen_casa_oci_tumbona'] = { uso = 'E', texto = { 'Reclinar el respaldo', 'Bajar el respaldo' }, partes = {
            { modelo = 'origen_casa_oci_tumbona_respaldo', pos = { 0.000, 0.240, 0.305 }, modo = 'gira', eje = 'x', angulo = 48.0, ms = 900 },
        } },
        ['origen_casa_oci_sombrilla'] = { uso = 'E', texto = { 'Inclinar la sombrilla', 'Enderezar la sombrilla' }, partes = {
            { modelo = 'origen_casa_oci_sombrilla_copa', pos = { 0.000, 0.000, 2.030 }, modo = 'gira', eje = 'x', angulo = -28.0, ms = 1200 },
        } },
        ['origen_casa_oci_barbacoa'] = { uso = 'E', texto = { 'Abrir la tapa', 'Cerrar la tapa' }, partes = {
            { modelo = 'origen_casa_oci_barbacoa_tapa', pos = { 0.000, 0.290, 0.940 }, modo = 'gira', eje = 'x', angulo = -80.0, ms = 800 },
        } },
    },
})

-- Sentarse y tumbarse (custom/client/especiales.lua): taburete, butacas, ratán y tumbona.
-- Un asiento por modelo: en la fila de butacas y en el sofá es el del centro.
if Config.Especiales and type(Config.Especiales.modelos) == 'table' then
    local m = Config.Especiales.modelos
    m['origen_casa_oci_taburete'] = { asiento = { z = 0.80 } }
    m['origen_casa_oci_butaca'] = { asiento = { y = -0.08, z = 0.46 } }
    m['origen_casa_oci_butacas3'] = { asiento = { y = -0.08, z = 0.46 } }
    m['origen_casa_oci_sofa_ratan'] = { asiento = { y = -0.10, z = 0.42 } }
    m['origen_casa_oci_sillon_ratan'] = { asiento = { y = -0.10, z = 0.42 } }
    m['origen_casa_oci_tumbona'] = { cama = { z = -0.02 } }
end
