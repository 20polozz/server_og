-- Muebles propios de los packs «Retro años 80» y «Fiestas del año» (modelos:
-- fuente/pack_t5.py, origen_casa_t5_*). Dos packs temáticos: cada mueble va a la
-- categoría del catálogo que le toca.
--
-- PRECIOS: config/zz_economia.lua multiplica el precio de aquí por el `mult` de la
-- categoría (Música / DJ ×8, Tecnología, Luces, Neveras, Juegos y Carteles de neón ×3,
-- el resto ×2,5; Almacenaje ×1,3). Lo de aquí es, pues, el precio final partido por
-- ese número: al lado de cada uno va lo que acaba costando.
--
-- Los que HACEN algo, con lo que ya había en el housing:
--   · tv        la tele de tubo: su pantalla lleva la textura «script_rt_tvscreen» y el
--               modelo está dado de alta en origen_screens/shared/config.lua
--   · stash     nevera redondeada, nevera portátil y ataúd: la puerta o la tapa se
--               abren al abrir el almacén (uso = 'almacen')
--   · luz con interruptor   lámpara de lava, póster de neón, calabazas, árbol, reno y
--               cartel «FIESTA»: llevan la luz dentro del modelo y tienen su modelo
--               «_off». Se apuntan abajo como lámparas de config/luces.lua: se
--               encienden y se apagan con la E y con el interruptor de la sala.
--   · sentarse  el sofá de skay (config/especiales.lua)
-- Los demás que se mueven lo hacen con la E (Config.Animados). El ventilador de
-- techo, el tren, el móvil de murciélagos y la piñata «giran»: el sistema de partes
-- solo sabe ir de cerrado a abierto, así que dan vueltas un rato y se paran (y al
-- pararlos las desandan). No es un giro continuo.
-- De techo (ventilador, murciélagos, piñata) y de pared (póster de neón, corona):
-- se colocan y se suben. La telaraña va en un rincón, bajo el techo.
-- Las medidas de las partes las escribe fuente/pack_t5.py al acabar y las copia
-- aquí fuente/pack_t5_lua.py (entre las marcas «animados»): no tocarlas a mano.

local P = 'origen_casa_t5_'

local function M(id, precio, nombre, extra)
    local it = { model = P .. id, price = precio, nombre = nombre, label = nombre }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end

Config.Packs.Registrar({
    id = 'retro_80', nombre = 'Retro años 80',
    descripcion = 'El salón de 1985: tele de tubo que funciona, con su mueble y su vídeo; equipo de música de doble pletina, radiocasete, tocadiscos con tapa y estantería de vinilos; máquina de discos y recreativa con sus luces, consola de cartuchos, ordenador de 8 bits y vídeo VHS; sofá de skay, mesa de cristal ahumado, mueble bar que se abate, nevera redondeada que guarda cosas, ventilador de techo, póster de neón y lámpara de lava que se encienden, teléfono de góndola y un cubo de Rubik gigante',
    xp = 450, grupo = 'tematico',
    categorias = {
        ['Televisores con mueble'] = {
            M('tv_tubo', 4500, 'Tele de tubo con mueble y vídeo', { type = 'tv' }),               -- 13.500 $
        },
        ['Tecnología'] = {
            M('consola', 1800, 'Consola de cartuchos con dos mandos'),                            -- 5.400 $
            M('ordenador_8bits', 2500, 'Ordenador de 8 bits con monitor'),                        -- 7.500 $
            M('video_vhs', 1500, 'Vídeo VHS con sus cintas'),                                     -- 4.500 $
            M('telefono_gondola', 800, 'Teléfono de góndola'),                                    -- 2.400 $
        },
        ['Música / DJ'] = {
            M('equipo_musica', 2000, 'Equipo de música de doble pletina'),                        -- 16.000 $
            M('jukebox', 3000, 'Máquina de discos con luces'),                                    -- 24.000 $
            M('tocadiscos', 900, 'Tocadiscos con tapa'),                                          -- 7.200 $
            M('radiocasete', 700, 'Radiocasete'),                                                 -- 5.600 $
        },
        ['Juegos y juguetes'] = {
            M('recreativa', 7000, 'Recreativa de pie'),                                           -- 21.000 $
        },
        ['Luces'] = {
            M('lampara_lava', 1000, 'Lámpara de lava'),                                           -- 3.000 $
        },
        ['Carteles de neón'] = {
            M('poster_neon', 2200, 'Póster de neón «Atardecer»'),                                 -- 6.600 $
        },
        ['Sillones'] = {
            M('sofa_skay', 5500, 'Sofá de skay de tres plazas'),                                  -- 13.750 $
        },
        ['Mesas'] = {
            M('mesa_cristal', 2600, 'Mesa de centro de cristal ahumado'),                         -- 6.500 $
        },
        ['Muebles'] = {
            M('mueble_bar', 5000, 'Mueble bar de puerta abatible'),                               -- 12.500 $
            M('estanteria_vinilos', 3200, 'Estantería de vinilos'),                               -- 8.000 $
        },
        ['Neveras'] = {
            M('nevera_redonda', 3500, 'Nevera retro roja', { type = 'stash', stash = 'big' }),    -- 10.500 $
        },
        ['Varios'] = {
            M('ventilador_techo', 2200, 'Ventilador de techo con luz'),                           -- 5.500 $
        },
        ['Decoración'] = {
            M('cubo_rubik', 1500, 'Cubo de Rubik gigante'),                                       -- 3.750 $
        },
    },
    animados = {
        -- <animados:retro_80>
        [P .. 'consola'] = { uso = 'E', texto = { 'Abrir la tapa', 'Cerrar la tapa' }, partes = { { modelo = P .. 'consola_tapa', pos = { -0.045, 0.165, 0.086 }, modo = 'gira', eje = 'x', angulo = -68.0, ms = 500 } } },
        [P .. 'equipo_musica'] = { uso = 'E', texto = { 'Abrir tapa y pletinas', 'Cerrar' }, partes = { { modelo = P .. 'equipo_musica_pletina_a', pos = { -0.105, -0.182, 0.500 }, modo = 'gira', eje = 'x', angulo = 28.0, ms = 450 }, { modelo = P .. 'equipo_musica_pletina_b', pos = { 0.105, -0.182, 0.500 }, modo = 'gira', eje = 'x', angulo = 28.0, ms = 450 }, { modelo = P .. 'equipo_musica_tapa', pos = { 0.000, 0.195, 0.897 }, modo = 'gira', eje = 'x', angulo = -62.0, ms = 700 } } },
        [P .. 'radiocasete'] = { uso = 'E', texto = { 'Abrir la pletina', 'Cerrar la pletina' }, partes = { { modelo = P .. 'radiocasete_pletina', pos = { 0.000, -0.076, 0.152 }, modo = 'gira', eje = 'x', angulo = 30.0, ms = 450 } } },
        [P .. 'mueble_bar'] = { uso = 'E', texto = { 'Abrir el bar', 'Cerrar el bar' }, partes = { { modelo = P .. 'mueble_bar_puerta', pos = { 0.000, -0.200, 0.722 }, modo = 'gira', eje = 'x', angulo = 90.0, ms = 800 } } },
        [P .. 'tocadiscos'] = { uso = 'E', texto = { 'Levantar la tapa', 'Bajar la tapa' }, partes = { { modelo = P .. 'tocadiscos_tapa', pos = { 0.000, 0.178, 0.092 }, modo = 'gira', eje = 'x', angulo = -62.0, ms = 700 } } },
        [P .. 'ventilador_techo'] = { uso = 'E', texto = { 'Encender', 'Apagar' }, partes = { { modelo = P .. 'ventilador_techo_aspas', pos = { 0.000, 0.000, 0.260 }, modo = 'gira', eje = 'z', angulo = 7200.0, ms = 12000 } } },
        [P .. 'nevera_redonda'] = { uso = 'almacen', partes = { { modelo = P .. 'nevera_redonda_puerta', pos = { 0.310, -0.240, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 800 } } },
        [P .. 'cubo_rubik'] = { uso = 'E', texto = { 'Girar', 'Colocar' }, partes = { { modelo = P .. 'cubo_rubik_capa', pos = { 0.000, 0.000, 0.385 }, modo = 'gira', eje = 'z', angulo = 45.0, ms = 700 } } },
        -- </animados>
    },
})

Config.Packs.Registrar({
    id = 'fiestas', nombre = 'Fiestas del año',
    descripcion = 'La casa, de fiesta todo el año. Halloween: calabazas que se encienden, telaraña de rincón, esqueleto, caldero que alumbra, lápidas, murciélagos que dan vueltas y un ataúd que se abre y guarda cosas. Navidad: árbol nevado grande con luces, chimenea con calcetines, belén, reno iluminado, trineo con regalos, corona y un tren que corre alrededor del árbol. Cumpleaños: mesa dulce con tarta de tres pisos, arco de globos, piñata y cartel luminoso. Verano: piscina hinchable, flotadores y nevera portátil',
    xp = 500, grupo = 'tematico',
    categorias = {
        ['Luces'] = {
            M('calabazas', 1200, 'Calabazas de Halloween con luz'),                               -- 3.600 $
            M('arbol_grande', 4000, 'Árbol de Navidad grande, nevado'),                           -- 12.000 $
            M('reno', 2000, 'Reno iluminado'),                                                    -- 6.000 $
        },
        ['Carteles de neón'] = {
            M('cartel_fiesta', 2000, 'Cartel luminoso «FIESTA»'),                                 -- 6.000 $
        },
        ['Decoración'] = {
            M('telarana', 600, 'Telaraña de rincón con araña'),                                   -- 1.500 $
            M('esqueleto', 2200, 'Esqueleto de pie'),                                             -- 5.500 $
            M('caldero', 2000, 'Caldero de bruja'),                                               -- 5.000 $
            M('murcielagos', 1200, 'Móvil de murciélagos'),                                       -- 3.000 $
            M('chimenea_navidad', 6000, 'Chimenea de Navidad con calcetines'),                    -- 15.000 $
            M('belen', 2600, 'Belén de madera'),                                                  -- 6.500 $
            M('corona', 800, 'Corona de Navidad'),                                                -- 2.000 $
            M('arco_globos', 1800, 'Arco de globos'),                                             -- 4.500 $
            M('pinata', 1000, 'Piñata de estrella'),                                              -- 2.500 $
        },
        ['Almacenaje'] = {
            M('ataud', 7000, 'Ataúd de pie', { type = 'stash', stash = 'big' }),                  -- 9.000 $
        },
        ['Jardín y patio'] = {
            M('lapidas', 1800, 'Lápidas'),                                                        -- 4.500 $
            M('trineo', 3600, 'Trineo con regalos'),                                              -- 9.000 $
            M('piscina_hinchable', 3000, 'Piscina hinchable'),                                    -- 7.500 $
            M('flotadores', 1200, 'Flotadores de piscina'),                                       -- 3.000 $
        },
        ['Juegos y juguetes'] = {
            M('tren', 2500, 'Tren de juguete con su vía'),                                        -- 7.500 $
        },
        ['Mesas'] = {
            M('mesa_dulce', 3500, 'Mesa dulce con tarta de tres pisos'),                          -- 8.750 $
        },
        ['Neveras'] = {
            M('nevera_portatil', 900, 'Nevera portátil', { type = 'stash', stash = 'small' }),    -- 2.700 $
        },
    },
    animados = {
        -- <animados:fiestas>
        [P .. 'ataud'] = { uso = 'almacen', partes = { { modelo = P .. 'ataud_tapa', pos = { 0.350, -0.170, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 1100 } } },
        [P .. 'murcielagos'] = { uso = 'E', texto = { 'Dar cuerda', 'Parar' }, partes = { { modelo = P .. 'murcielagos_movil', pos = { 0.000, 0.000, 0.910 }, modo = 'gira', eje = 'z', angulo = 1080.0, ms = 16000 } } },
        [P .. 'tren'] = { uso = 'E', texto = { 'Poner en marcha', 'Parar' }, partes = { { modelo = P .. 'tren_convoy', pos = { 0.000, 0.000, 0.000 }, modo = 'gira', eje = 'z', angulo = 3600.0, ms = 60000 } } },
        [P .. 'pinata'] = { uso = 'E', texto = { 'Empujar', 'Parar' }, partes = { { modelo = P .. 'pinata_estrella', pos = { 0.000, 0.000, 1.350 }, modo = 'gira', eje = 'x', angulo = 26.0, ms = 900 } } },
        [P .. 'nevera_portatil'] = { uso = 'almacen', partes = { { modelo = P .. 'nevera_portatil_tapa', pos = { 0.000, 0.180, 0.320 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 700 } } },
        -- </animados>
    },
})

-- Los que se encienden y se apagan: lámparas de config/luces.lua con otro prefijo.
-- Config.Luces.Lampara(modelo) es por donde preguntan el cliente, el servidor y la
-- tienda («Luz con interruptor»): se le enseñan también estos seis. tipo: dónde va
-- (ninguno es de techo); mano: se enciende y se apaga con la E junto a ella.
if type(Config.Luces) == 'table' and type(Config.Luces.Lampara) == 'function' then
    local MIAS = {
        lampara_lava = { tipo = 'mesa', nombre = 'Lámpara de lava' },
        poster_neon = { tipo = 'color', nombre = 'Póster de neón' },
        calabazas = { tipo = 'pie', nombre = 'Calabazas con luz' },
        arbol_grande = { tipo = 'pie', nombre = 'Árbol de Navidad' },
        reno = { tipo = 'pie', nombre = 'Reno iluminado' },
        cartel_fiesta = { tipo = 'color', nombre = 'Cartel luminoso' },
    }
    local PORNOMBRE, PORHASH = {}, {}
    for id, l in pairs(MIAS) do
        l.id = 't5_' .. id
        l.mano = true
        l.modelo = P .. id
        l.apagada = l.modelo .. '_off'
        PORNOMBRE[l.modelo] = l
        PORHASH[joaat(l.modelo)] = l
    end
    local antes = Config.Luces.Lampara
    function Config.Luces.Lampara(modelo)
        local t = type(modelo)
        local mia = (t == 'string' and PORNOMBRE[modelo]) or (t == 'number' and PORHASH[modelo]) or nil
        if mia then return mia end
        return antes(modelo)
    end
end

-- Dónde se sienta uno (custom/client/especiales.lua): x/y desde el centro del
-- modelo, z sobre su base.
if Config.Especiales and type(Config.Especiales.modelos) == 'table' then
    if Config.Especiales.modelos[P .. 'sofa_skay'] == nil then
        Config.Especiales.modelos[P .. 'sofa_skay'] = { asiento = { x = 0.00, y = -0.10, z = 0.42 } }
    end
end
