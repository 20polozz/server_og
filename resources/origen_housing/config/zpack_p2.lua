-- Puertas propias (modelos: fuente/pack_p2.py, origen_casa_p2_*).
--   · pack «Puertas con estilo» (`puertas`): 17 puertas de interior y de entrada
--   · pack «Puertas de autor» (`puertas_autor`): las 10 exclusivas (origen_casa_p2_x_*),
--     pensadas para venderse además SUELTAS, una a una (pieza suelta
--     'modelo:origen_casa_p2_x_…', como los portones de garaje)
--
-- Todas son `type = 'door'`: una puerta de las de siempre del housing, con su
-- cerrojo para quien tiene llave. Las abre el juego (puerta normal, batiente a
-- los dos lados y que vuelve sola a cerrarse); no llevan partes de Config.Animados.
-- Miden 1,30 x 2,30 m, con el origen en la bisagra, como las del juego del
-- catálogo: Encajar (custom/client/obra.lua) las centra solas en el hueco de
-- puerta de la obra. Para el hueco de PUERTA DOBLE se ponen dos: tienen las dos
-- caras hechas y la segunda hoja queda del revés, con las bisagras hacia fuera.
--
-- Precios: los de aquí son provisionales. config/zz_economia.lua multiplica por 2,5
-- lo que se da de alta en «Puertas», así que cada uno va escrito a su precio final
-- partido por 2,5 (al lado, lo que acaba costando): de 3.000 $ a 7.500 $ las del
-- pack y de 12.000 $ a 25.000 $ las de autor.
-- `movimiento` y `funcion` son informativos, para la tienda y el catálogo.

local P = 'origen_casa_p2_'

local function M(id, precio, nombre)
    return { model = P .. id, price = precio, nombre = nombre, label = nombre, type = 'door', movimiento = true, funcion = 'puerta' }
end

Config.Packs.Registrar({
    id = 'puertas', nombre = 'Puertas con estilo',
    descripcion = 'Diecisiete puertas hechas a medida del hueco de tu casa, con sus manillas, sus bisagras y sus dos caras: lacadas lisa, de cuarterones y de baño con rejilla; roble, nogal y wengué; con cristal esmerilado, con ojo de buey y cristalera francesa; de granero, vaivén de cocina y de saloon; de oficina con veneciana, metálica de trastero, shoji japonesa, de seguridad y de entrada clásica con aldaba. Se abren, se cierran y se echa la llave como en cualquier puerta de la casa; pon dos en el hueco doble y hacen pareja',
    xp = 400, grupo = 'construccion',
    categorias = {
        ['Puertas'] = {
            M('lacada_lisa', 1200, 'Puerta lacada blanca lisa'),                          -- 3.000 $
            M('lacada_cuarterones', 1400, 'Puerta blanca de seis cuarterones'),           -- 3.500 $
            M('bano', 1500, 'Puerta de baño con rejilla'),                                -- 3.750 $
            M('roble', 1600, 'Puerta de roble de tres tableros'),                         -- 4.000 $
            M('trastero', 1600, 'Puerta metálica de trastero'),                           -- 4.000 $
            M('nogal', 1700, 'Puerta de nogal con tirador de barra'),                     -- 4.250 $
            M('wengue', 1800, 'Puerta de wengué con filetes de aluminio'),                -- 4.500 $
            M('cristal_esmerilado', 1800, 'Puerta lacada con cristal esmerilado'),        -- 4.500 $
            M('ojo_buey', 1900, 'Puerta gris con ojo de buey'),                           -- 4.750 $
            M('granero', 2000, 'Puerta de granero'),                                      -- 5.000 $
            M('vaiven', 2000, 'Puerta de vaivén de cocina'),                              -- 5.000 $
            M('saloon', 2200, 'Puerta de saloon'),                                        -- 5.500 $
            M('oficina', 2200, 'Puerta de oficina con cristal y veneciana'),              -- 5.500 $
            M('francesa', 2400, 'Cristalera francesa'),                                   -- 6.000 $
            M('shoji', 2400, 'Puerta shoji japonesa'),                                    -- 6.000 $
            M('entrada', 2600, 'Puerta de entrada clásica con aldaba'),                   -- 6.500 $
            M('seguridad', 3000, 'Puerta de seguridad de vivienda'),                      -- 7.500 $
        },
    },
})

Config.Packs.Registrar({
    id = 'puertas_autor', nombre = 'Puertas de autor',
    descripcion = 'Las diez puertas que se quedan mirando las visitas: acorazada de cámara de banco con su volante, escotilla de submarino, portón medieval de castillo, art déco de laca negra y oro, de club con capitoné, mirilla y neón, futurista con juntas de luz, japonesa del dragón dorado, blindada de búnker, de cristal ahumado con perfil negro y de celda con barrotes. Son puertas normales de la casa, con su llave: lo que cambia es la entrada',
    xp = 1500, grupo = 'construccion',
    categorias = {
        ['Puertas'] = {
            M('x_cristal', 4800, 'Puerta de cristal ahumado con marco negro'),            -- 12.000 $
            M('x_celda', 5200, 'Puerta de celda con barrotes'),                           -- 13.000 $
            M('x_castillo', 6400, 'Portón medieval de castillo'),                         -- 16.000 $
            M('x_bunker', 6800, 'Puerta blindada de búnker'),                             -- 17.000 $
            M('x_submarino', 7200, 'Puerta de submarino'),                                -- 18.000 $
            M('x_club', 8000, 'Puerta de club con mirilla y neón'),                       -- 20.000 $
            M('x_futurista', 8400, 'Puerta futurista con paneles de luz'),                -- 21.000 $
            M('x_dragon', 8800, 'Puerta japonesa del dragón'),                            -- 22.000 $
            M('x_deco', 9200, 'Puerta art déco dorada'),                                  -- 23.000 $
            M('x_camara', 10000, 'Puerta acorazada de cámara de banco'),                  -- 25.000 $
        },
    },
})
