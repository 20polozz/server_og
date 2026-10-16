-- Tanda 2 de muebles propios: packs «Dormitorio a medida» y «Baño y lavadero»
-- (modelos origen_casa_d2_*, fuente/pack_d2.py). GENERADO por fuente/pack_d2_lua.py:
-- no editar a mano; el catálogo está en ese guion y las medidas de las partes salen
-- del modelado (fuente/pack_d2_partes.json).
--
-- Función, por el `type` de siempre del housing:
--   · stash     almacén (uso = 'almacen': el mueble se abre al abrir su inventario)
--   · wardrobe  ropero (uso = 'ropero': se abre al abrir el menú de ropa)
--   · camas     tumbarse (Config.Especiales, abajo): litera, forja y plataforma. Las que
--               guardan cosas o se mueven no: su E ya es de abrirlas.
-- Los demás que se mueven lo hacen con la E (uso = 'E'). Quién mueve las partes:
-- custom/client/almacenajes.lua con Config.Animados.
-- Cada mueble lleva además, para la tienda: `descripcion`, `movimiento` (qué se mueve;
-- sin él, no se mueve nada) y `funcion` ('Almacén', 'Ropero', 'Tumbarse'; sin él, adorno).
-- Lo de pared (mesilla suspendida, camerino, tabla de planchar) tiene el origen en el
-- suelo y su altura ya puesta: se deja contra la pared.

local P = 'origen_casa_d2_'

local function M(id, precio, nombre, extra)
    local it = { model = P .. id, price = precio, nombre = nombre, label = nombre }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end

Config.Packs.Registrar({
    id = 'dormitorio_medida', nombre = 'Dormitorio a medida',
    descripcion = 'El dormitorio que se usa de verdad: canapé que se levanta y cama con cajones para guardar, cama nido que sale de lado, abatible con altillo que baja de la pared, litera de hierro, cama de forja y plataforma baja para tumbarse, moisés de mimbre, cabecero de ratán, mesillas y baúl; y para la ropa, armario de correderas con espejo, ropero provenzal y vestidor abierto que abren el ropero, sinfonier, cómoda y espejo joyero con almacén, tocador y zapatero de trampones',
    xp = 450, grupo = 'estancia',
    categorias = {
        ['Camas'] = {
            M('canape', 9500, 'Cama con canapé tapizado', { type = 'stash', stash = 'big', descripcion = 'Cama de matrimonio tapizada en gris con cabecero capitoné; debajo, un arcón para guardar', movimiento = 'Se levanta el somier con el colchón', funcion = 'Almacén' }),
            M('cama_cajones', 10000, 'Cama de nogal con cajones', { type = 'stash', stash = 'big', descripcion = 'Cama de matrimonio de nogal con cabecero de cuero y dos cajones grandes a los pies', movimiento = 'Salen los dos cajones del pie', funcion = 'Almacén' }),
            M('nido', 5500, 'Cama nido juvenil', { descripcion = 'Cama individual lacada con una segunda cama que se saca rodando para las visitas', movimiento = 'La cama de abajo sale de lado' }),
            M('abatible', 13000, 'Cama abatible con altillo', { descripcion = 'Mueble de pared de roble con altillo: de día es un armario, de noche una cama', movimiento = 'La cama baja de la pared y su zócalo sale a hacer de pata' }),
            M('litera_metal', 5000, 'Litera de hierro', { descripcion = 'Litera de tubo negro con escalera y quitamiedos; te puedes tumbar en la de abajo', funcion = 'Tumbarse' }),
            M('cama_forja', 7000, 'Cama de forja', { descripcion = 'Cama clásica de hierro forjado con remates de latón y colcha de damasco; te puedes tumbar', funcion = 'Tumbarse' }),
            M('tatami', 8500, 'Cama baja de plataforma', { descripcion = 'Plataforma ancha de roble con cabecero de listones, lámpara y repisa a los lados; te puedes tumbar', funcion = 'Tumbarse' }),
            M('moises', 3200, 'Moisés de mimbre', { descripcion = 'Cuna de mimbre trenzado sobre patas de aspa, con su capota de tela', movimiento = 'La capota se echa atrás' }),
            M('cabecero_ratan', 2600, 'Cabecero de ratán en arco', { descripcion = 'Cabecero de ratán con rejilla y varillas en abanico, para poner detrás de cualquier cama' }),
            M('mesilla_flotante', 1900, 'Mesilla suspendida con lámpara', { descripcion = 'Mesilla lacada colgada de la pared con tapa de roble, lámpara, libros y despertador', movimiento = 'Se abre el cajón' }),
            M('mesilla_roble', 2000, 'Mesilla de roble', { descripcion = 'Mesilla de patas cónicas con cajón, hueco para libros y un jarrón con flores', movimiento = 'Se abre el cajón' }),
            M('baul_mimbre', 3800, 'Baúl de mimbre de pie de cama', { type = 'stash', stash = 'normal', descripcion = 'Baúl de mimbre con correas de cuero y asiento acolchado; guarda las mantas', movimiento = 'Se levanta la tapa', funcion = 'Almacén' }),
        },
        ['Armarios'] = {
            M('correderas', 12000, 'Armario de tres correderas', { type = 'wardrobe', descripcion = 'Armario de roble de 2,40 m con dos hojas de cristal ahumado, espejo central y luz interior', movimiento = 'Corren las dos hojas de cristal', funcion = 'Ropero' }),
            M('provenzal', 6500, 'Ropero provenzal', { type = 'wardrobe', descripcion = 'Ropero pintado en verde salvia con cuarterones, cornisa, patas torneadas y pomos de latón', movimiento = 'Se abren las dos hojas', funcion = 'Ropero' }),
            M('vestidor', 16000, 'Vestidor abierto con cajonera', { type = 'wardrobe', descripcion = 'Vestidor de wengué sin puertas: barras de colgar, baldas, zapatero, cajonera de roble y tira de luz', movimiento = 'Salen dos cajones', funcion = 'Ropero' }),
            M('sinfonier', 4800, 'Sinfonier de nogal', { type = 'stash', stash = 'normal', descripcion = 'Cajonera alta y estrecha de seis cajones con pomos de latón', movimiento = 'Salen dos cajones', funcion = 'Almacén' }),
            M('comoda', 5200, 'Cómoda nórdica de seis cajones', { type = 'stash', stash = 'big', descripcion = 'Cómoda blanca con frentes de roble, lámpara, bandeja de perfumes y libros', movimiento = 'Salen dos cajones', funcion = 'Almacén' }),
            M('tocador', 6000, 'Tocador con espejo redondo', { descripcion = 'Tocador lacado de patas de roble con espejo redondo de latón, frascos y brochas', movimiento = 'Se abren los dos cajones' }),
            M('zapatero', 3200, 'Zapatero de tres trampones', { descripcion = 'Zapatero estrecho de pared, lacado con frentes de roble, lleno de zapatos', movimiento = 'Se abaten los tres trampones' }),
            M('joyero', 4500, 'Espejo joyero de pie', { type = 'stash', stash = 'small', descripcion = 'Espejo de cuerpo entero que esconde un joyero forrado de terciopelo, con luz', movimiento = 'Se abre el espejo', funcion = 'Almacén' }),
        },
    },
    animados = {
        [P .. 'canape'] = { uso = 'almacen', partes = { { modelo = P .. 'canape_somier', pos = { 0.000, 1.000, 0.360 }, modo = 'gira', eje = 'x', angulo = -38.0, ms = 1400 } } },
        [P .. 'cama_cajones'] = { uso = 'almacen', partes = { { modelo = P .. 'cama_cajones_cajones', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.50, ms = 600 } } },
        [P .. 'nido'] = { uso = 'E', texto = { 'Sacar la cama nido', 'Guardar la cama nido' }, partes = { { modelo = P .. 'nido_nido', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.92, ms = 1100 } } },
        [P .. 'abatible'] = { uso = 'E', texto = { 'Bajar la cama', 'Recoger la cama' }, partes = { { modelo = P .. 'abatible_cama', pos = { 0.000, -0.190, 0.300 }, modo = 'gira', eje = 'x', angulo = 90.0, ms = 1700 }, { modelo = P .. 'abatible_patas', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.93, ms = 1700 } } },
        [P .. 'moises'] = { uso = 'E', texto = { 'Echar la capota atrás', 'Poner la capota' }, partes = { { modelo = P .. 'moises_capota', pos = { 0.000, 0.440, 0.775 }, modo = 'gira', eje = 'x', angulo = -84.0, ms = 900 } } },
        [P .. 'mesilla_flotante'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'mesilla_flotante_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.22, ms = 600 } } },
        [P .. 'mesilla_roble'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'mesilla_roble_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.22, ms = 600 } } },
        [P .. 'baul_mimbre'] = { uso = 'almacen', partes = { { modelo = P .. 'baul_mimbre_tapa', pos = { 0.000, 0.230, 0.420 }, modo = 'gira', eje = 'x', angulo = -80.0, ms = 800 } } },
        [P .. 'correderas'] = { uso = 'ropero', partes = { { modelo = P .. 'correderas_hoja_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.76, ms = 900 }, { modelo = P .. 'correderas_hoja_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.76, ms = 900 } } },
        [P .. 'provenzal'] = { uso = 'ropero', partes = { { modelo = P .. 'provenzal_puerta_i', pos = { -0.600, -0.290, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = P .. 'provenzal_puerta_d', pos = { 0.600, -0.290, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        [P .. 'vestidor'] = { uso = 'ropero', partes = { { modelo = P .. 'vestidor_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.18, ms = 600 }, { modelo = P .. 'vestidor_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.32, ms = 600 } } },
        [P .. 'sinfonier'] = { uso = 'almacen', partes = { { modelo = P .. 'sinfonier_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.18, ms = 600 }, { modelo = P .. 'sinfonier_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.30, ms = 600 } } },
        [P .. 'comoda'] = { uso = 'almacen', partes = { { modelo = P .. 'comoda_cajon_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.18, ms = 600 }, { modelo = P .. 'comoda_cajon_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.30, ms = 600 } } },
        [P .. 'tocador'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'tocador_cajon_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.24, ms = 600 }, { modelo = P .. 'tocador_cajon_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.16, ms = 600 } } },
        [P .. 'zapatero'] = { uso = 'E', texto = { 'Abrir los trampones', 'Cerrar los trampones' }, partes = { { modelo = P .. 'zapatero_trampon_a', pos = { 0.000, -0.168, 0.085 }, modo = 'gira', eje = 'x', angulo = 38.0, ms = 650 }, { modelo = P .. 'zapatero_trampon_b', pos = { 0.000, -0.168, 0.463 }, modo = 'gira', eje = 'x', angulo = 38.0, ms = 650 }, { modelo = P .. 'zapatero_trampon_c', pos = { 0.000, -0.168, 0.841 }, modo = 'gira', eje = 'x', angulo = 38.0, ms = 650 } } },
        [P .. 'joyero'] = { uso = 'almacen', partes = { { modelo = P .. 'joyero_puerta', pos = { -0.200, -0.060, 0.000 }, modo = 'gira', eje = 'z', angulo = -112.0, ms = 600 } } },
    },
})

Config.Packs.Registrar({
    id = 'bano_lavadero', nombre = 'Baño y lavadero',
    descripcion = 'Un baño con todo en su sitio y un cuarto de lavar completo: mueble de lavabo de mármol con puertas, camerino de tres espejos, ducha de pizarra con mampara corredera, bañera de obra con mampara, bañera exenta, inodoro y bidé con tapa, columna y carrito; torre de lavadora y secadora, lavadora de carga superior, tabla de planchar que baja de la pared, tendedero de alas, armario escobero, pila de lavar y mueble de cestas. Casi todo se abre',
    xp = 400, grupo = 'estancia',
    categorias = {
        ['Baño'] = {
            M('lavabo_salvia', 4200, 'Mueble de lavabo verde salvia', { descripcion = 'Mueble de lavabo con encimera de mármol, grifo de latón y las toallas dentro', movimiento = 'Se abren las dos puertas' }),
            M('camerino', 3200, 'Camerino de tres espejos', { descripcion = 'Armario de pared con tres espejos, aplique de luz y los botes en sus baldas', movimiento = 'Se abren los dos espejos laterales' }),
            M('mampara_corredera', 6500, 'Ducha de pizarra con mampara corredera', { descripcion = 'Plato de ducha de 1,40 m en pizarra, mampara de perfil negro y columna de ducha', movimiento = 'Corre la hoja de cristal' }),
            M('banera_mampara', 7500, 'Bañera de obra con mampara', { descripcion = 'Bañera con faldón de azulejo, columna de ducha y hoja de cristal abatible', movimiento = 'La mampara se abre hacia fuera' }),
            M('banera_exenta', 12000, 'Bañera exenta ovalada', { descripcion = 'Bañera negra por fuera y blanca por dentro, con grifería de pie y bandeja de roble' }),
            M('inodoro_roble', 2200, 'Inodoro con tapa de roble', { descripcion = 'Inodoro de tanque bajo con pulsador doble y asiento de madera', movimiento = 'Se levanta la tapa' }),
            M('bide_tapa', 2000, 'Bidé con tapa', { descripcion = 'Bidé de porcelana con grifo negro mate y tapa de roble, a juego con el inodoro', movimiento = 'Se levanta la tapa' }),
            M('columna_bano', 3600, 'Columna de baño', { type = 'stash', stash = 'normal', descripcion = 'Armario alto y estrecho de roble y lacado con toallas, papel y botes', movimiento = 'Se abre la puerta', funcion = 'Almacén' }),
            M('cesto_mimbre', 1600, 'Cesto de la ropa de mimbre', { descripcion = 'Cesto redondo de mimbre con forro de tela, asas de cuero y la ropa dentro', movimiento = 'Se levanta la tapa' }),
            M('toallero_escalera', 1600, 'Toallero de escalera', { descripcion = 'Escalera de roble apoyada en la pared con cuatro toallas echadas en sus peldaños' }),
            M('carrito_bano', 1800, 'Carrito auxiliar de baño', { descripcion = 'Carrito metálico de tres bandejas con ruedas, toallas enrolladas, papel y botes' }),
        },
        ['Lavandería y limpieza'] = {
            M('torre_lavado', 8500, 'Torre de lavadora y secadora', { descripcion = 'Lavadora y secadora en columna con su kit de unión y bandeja', movimiento = 'Se abren las dos puertas' }),
            M('lavadora_superior', 4200, 'Lavadora de carga superior', { descripcion = 'Lavadora americana de carga por arriba, con la colada dentro', movimiento = 'Se levanta la tapa' }),
            M('tabla_pared', 2600, 'Tabla de planchar abatible de pared', { descripcion = 'Armario estrecho de roble que guarda la tabla de planchar, la plancha y el pulverizador', movimiento = 'Se abre el armario y baja la tabla' }),
            M('tendedero_alas', 1800, 'Tendedero de alas', { descripcion = 'Tendedero de aluminio con la ropa tendida', movimiento = 'Se despliegan las dos alas' }),
            M('escobero', 3000, 'Armario escobero', { type = 'stash', stash = 'normal', descripcion = 'Armario alto con la escoba, la fregona, el cubo y los productos de limpieza', movimiento = 'Se abre la puerta', funcion = 'Almacén' }),
            M('pila_lavadero', 3200, 'Pila de lavar con mueble', { descripcion = 'Pila honda de porcelana con tabla de frotar, grifo alto y mueble bajo', movimiento = 'Se abren las dos puertas' }),
            M('mueble_cestas', 3400, 'Mueble de lavadero con cestas', { descripcion = 'Mueble de roble con tres cestas de mimbre para separar la colada', movimiento = 'Salen dos cestas' }),
            M('estanteria_lavadero', 2400, 'Estantería metálica de lavadero', { descripcion = 'Estantería cromada con detergentes, toallas, cestas y papel' }),
        },
    },
    animados = {
        [P .. 'lavabo_salvia'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'lavabo_salvia_puerta_i', pos = { -0.440, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = P .. 'lavabo_salvia_puerta_d', pos = { 0.440, -0.250, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        [P .. 'camerino'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'camerino_puerta_i', pos = { -0.600, -0.090, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = P .. 'camerino_puerta_d', pos = { 0.600, -0.090, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        [P .. 'mampara_corredera'] = { uso = 'E', texto = { 'Abrir la mampara', 'Cerrar la mampara' }, partes = { { modelo = P .. 'mampara_corredera_hoja', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.62, ms = 900 } } },
        [P .. 'banera_mampara'] = { uso = 'E', texto = { 'Abrir la mampara', 'Cerrar la mampara' }, partes = { { modelo = P .. 'banera_mampara_hoja', pos = { -0.842, -0.355, 0.000 }, modo = 'gira', eje = 'z', angulo = -88.0, ms = 800 } } },
        [P .. 'inodoro_roble'] = { uso = 'E', texto = { 'Levantar la tapa', 'Bajar la tapa' }, partes = { { modelo = P .. 'inodoro_roble_tapa', pos = { 0.000, 0.092, 0.422 }, modo = 'gira', eje = 'x', angulo = -92.0, ms = 500 } } },
        [P .. 'bide_tapa'] = { uso = 'E', texto = { 'Levantar la tapa', 'Bajar la tapa' }, partes = { { modelo = P .. 'bide_tapa_tapa', pos = { 0.000, 0.222, 0.412 }, modo = 'gira', eje = 'x', angulo = -92.0, ms = 500 } } },
        [P .. 'columna_bano'] = { uso = 'almacen', partes = { { modelo = P .. 'columna_bano_puerta', pos = { -0.200, -0.170, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 } } },
        [P .. 'cesto_mimbre'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'cesto_mimbre_tapa', pos = { 0.000, 0.250, 0.595 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 600 } } },
        [P .. 'torre_lavado'] = { uso = 'E', texto = { 'Abrir las puertas', 'Cerrar las puertas' }, partes = { { modelo = P .. 'torre_lavado_puerta_a', pos = { -0.215, -0.302, 0.000 }, modo = 'gira', eje = 'z', angulo = -115.0, ms = 700 }, { modelo = P .. 'torre_lavado_puerta_b', pos = { -0.215, -0.302, 0.000 }, modo = 'gira', eje = 'z', angulo = -115.0, ms = 700 } } },
        [P .. 'lavadora_superior'] = { uso = 'E', texto = { 'Abrir la tapa', 'Cerrar la tapa' }, partes = { { modelo = P .. 'lavadora_superior_tapa', pos = { 0.000, 0.265, 0.925 }, modo = 'gira', eje = 'x', angulo = -82.0, ms = 700 } } },
        [P .. 'tabla_pared'] = { uso = 'E', texto = { 'Abrir y bajar la tabla', 'Recoger la tabla' }, partes = { { modelo = P .. 'tabla_pared_tabla', pos = { 0.000, -0.045, 0.700 }, modo = 'gira', eje = 'x', angulo = 90.0, ms = 1100 }, { modelo = P .. 'tabla_pared_puerta', pos = { -0.230, -0.080, 0.000 }, modo = 'gira', eje = 'z', angulo = -115.0, ms = 500 } } },
        [P .. 'tendedero_alas'] = { uso = 'E', texto = { 'Abrir las alas', 'Plegar las alas' }, partes = { { modelo = P .. 'tendedero_alas_ala_f', pos = { 0.000, -0.275, 0.920 }, modo = 'gira', eje = 'x', angulo = -110.0, ms = 700 }, { modelo = P .. 'tendedero_alas_ala_t', pos = { 0.000, 0.275, 0.920 }, modo = 'gira', eje = 'x', angulo = 110.0, ms = 700 } } },
        [P .. 'escobero'] = { uso = 'almacen', partes = { { modelo = P .. 'escobero_puerta', pos = { -0.260, -0.235, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 } } },
        [P .. 'pila_lavadero'] = { uso = 'E', texto = { 'Abrir', 'Cerrar' }, partes = { { modelo = P .. 'pila_lavadero_puerta_i', pos = { -0.350, -0.270, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 600 }, { modelo = P .. 'pila_lavadero_puerta_d', pos = { 0.350, -0.270, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 600 } } },
        [P .. 'mueble_cestas'] = { uso = 'E', texto = { 'Sacar las cestas', 'Guardar las cestas' }, partes = { { modelo = P .. 'mueble_cestas_cesta_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.30, ms = 700 }, { modelo = P .. 'mueble_cestas_cesta_c', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.16, ms = 700 } } },
    },
})

-- Tumbarse en las camas (custom/*/especiales.lua). cama = { x, y, z, giro }: x/y desde el
-- centro del modelo, z desde lo más alto (por eso es negativa); giro 0: la cabeza hacia
-- la cabecera (+Y del modelo). En la litera, la de abajo.
if Config.Especiales and Config.Especiales.modelos then
    local m = Config.Especiales.modelos
    m[P .. 'litera_metal'] = { cama = { x = -0.02, y = -0.12, z = -1.16, giro = 0.0 } }
    m[P .. 'cama_forja'] = { cama = { x = -0.00, y = -0.12, z = -0.71, giro = 0.0 } }
    m[P .. 'tatami'] = { cama = { x = 0.00, y = -0.21, z = -0.38, giro = 0.0 } }
end
