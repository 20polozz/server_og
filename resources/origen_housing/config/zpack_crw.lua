-- Pack Crews: el local de un crew de coches / club de carreras callejeras.
-- Modelos propios (fuente/pack_crw.py; texturas del juego: fuente/texturas_pack_crw.py),
-- en origen_modelos/stream/casa_obra (origen_casa_pk_crw.ytyp, origen_casa_txp_crw.ytd).
-- Todo es de adorno: nada da ventaja ni guarda cosas.
--   · Se abren con la E (custom/client/almacenajes.lua): dos cajones del carro de
--     herramientas, la puerta de la nevera y la de la vitrina.
--   · Llevan luz real dentro del modelo (siempre encendida) la lámpara de tubo, los
--     cuatro neones, el semáforo de salida, la nevera, la vitrina, la barra, la valla
--     y el simulador.
--   · Uno se puede sentar (custom/client/especiales.lua) en el sillón baquet, en el
--     sofá de baquets (en el asiento de la izquierda), en el taburete de bidón y en
--     el simulador.
--   · Lo de pared lleva el origen en la pared (y = 0) y en su borde de abajo.
-- Las medidas de las partes las escribe fuente/pack_crw.py al acabar (líneas
-- «LUA»): si se cambia un modelo, aquí también.

local function M(id, precio, nombre)
    return { model = 'origen_casa_crw_' .. id, price = precio, nombre = nombre, label = nombre }
end

Config.Packs.Registrar({
    id = 'crews', nombre = 'Pack Crews',
    descripcion = 'Monta el local de tu crew: garaje con grúa de motor, compresor y carro de herramientas que se abre, club con sofá de baquets, barra con frontal de coche y nevera de energéticas, vitrina de trofeos, neones con luz, lonas para el nombre del crew, semáforo de salida y simulador de conducción',
    xp = 0,
    categorias = {
        ['Taller y exposición'] = {
            M('cono', 1500, 'Cono de carreras'),
            M('caballetes', 1800, 'Caballetes de taller (par)'),
            M('extintor', 1800, 'Extintor en su soporte'),
            M('gato', 2500, 'Gato hidráulico de carretilla'),
            M('torre_neumaticos', 2500, 'Torre de neumáticos'),
            M('valla', 2500, 'Valla de obra con baliza'),
            M('enrollador', 2800, 'Enrollador de manguera de pared'),
            M('lampara_tubo', 3000, 'Lámpara de taller de tubo'),
            M('bidones', 3500, 'Bidones de aceite y de combustible de competición'),
            M('panel_herramientas', 4500, 'Panel de herramientas con siluetas'),
            M('compresor', 5000, 'Compresor de aire'),
            M('banco', 5500, 'Banco de trabajo con tornillo'),
            M('carro', 6500, 'Carro de herramientas con cofre'),
            M('motor_soporte', 8000, 'Motor en soporte'),
            M('estanteria_llantas', 9000, 'Estantería de llantas y neumáticos'),
            M('semaforo', 9500, 'Semáforo de salida de carreras'),
            M('grua_motor', 12000, 'Grúa de taller con motor colgando'),
        },
        ['Alfombras'] = {
            M('alfombrilla', 2200, 'Alfombrilla de taller'),
        },
        ['Sillones'] = {
            M('sillon_baquet', 6000, 'Sillón baquet de competición'),
            M('sofa_baquets', 11000, 'Sofá de dos baquets'),
        },
        ['Sillas'] = {
            M('taburete_bidon', 1800, 'Taburete de bidón'),
        },
        ['Mesas'] = {
            M('mesa_llanta', 5500, 'Mesa de centro de rueda y cristal'),
        },
        ['Neveras'] = {
            M('nevera', 7500, 'Nevera de bebidas energéticas'),
        },
        ['Muebles'] = {
            M('barra_coche', 22000, 'Barra con frontal de coche'),
        },
        ['Trofeos'] = {
            M('vitrina', 16000, 'Vitrina de trofeos de carreras'),
        },
        ['Juegos y juguetes'] = {
            M('diana', 3500, 'Diana en su armario'),
            M('simulador', 28000, 'Simulador de conducción de tres pantallas'),
        },
        ['Decoración'] = {
            M('senal_stop', 1500, 'Señal de stop'),
            M('senal_limite', 1500, 'Señal de límite de velocidad'),
            M('senal_curva', 1500, 'Señal de curva'),
            M('senal_derrape', 1500, 'Señal de derrape'),
            M('lona_rojo', 2000, 'Lona de crew roja'),
            M('lona_azul', 2000, 'Lona de crew azul'),
            M('lona_negro', 2000, 'Lona de crew negra'),
            M('lona_amarillo', 2000, 'Lona de crew amarilla'),
            M('lona_verde', 2000, 'Lona de crew verde'),
            M('bandera', 2500, 'Banderas de cuadros cruzadas'),
            M('matriculas', 3500, 'Pared de matrículas'),
            M('tablero_tiempos', 3500, 'Pizarra de tiempos de vuelta'),
            M('casco_mono', 5000, 'Casco y mono de piloto colgados'),
        },
        ['Carteles de neón'] = {
            M('neon_rayo', 4500, 'Neón de rayo'),
            M('neon_llama', 4500, 'Neón de llama'),
            M('neon_flecha', 4500, 'Neón de flecha'),
            M('neon_garage', 6500, 'Neón «GARAGE»'),
        },
    },
    animados = {
        ['origen_casa_crw_carro'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_crw_carro_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.32, ms = 600 }, { modelo = 'origen_casa_crw_carro_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.26, ms = 600 } } },
        ['origen_casa_crw_nevera'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_crw_nevera_puerta', pos = { 0.320, -0.320, 0.000 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 700 } } },
        ['origen_casa_crw_vitrina'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = 'origen_casa_crw_vitrina_puerta', pos = { 0.520, -0.230, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 800 } } },
    },
})

-- Asientos (config/especiales.lua): x/y desde el centro del modelo, z sobre su base.
-- El frente de estos muebles mira a -Y, como el de las sillas del juego (giro 180).
if Config.Especiales and Config.Especiales.modelos then
    local E = Config.Especiales.modelos
    E['origen_casa_crw_sillon_baquet'] = { asiento = { y = -0.13, z = 0.36 } }
    E['origen_casa_crw_sofa_baquets'] = { asiento = { x = -0.38, y = -0.13, z = 0.36 } }
    E['origen_casa_crw_taburete_bidon'] = { asiento = { z = 0.74 } }
    E['origen_casa_crw_simulador'] = { asiento = { y = 0.38, z = 0.33 } }
end
