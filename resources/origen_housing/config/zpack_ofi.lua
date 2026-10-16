-- Pack de OFICINA, TECNOLOGÍA Y MÚSICA: muebles y aparatos propios (modelos:
-- fuente/pack_ofi.py, origen_casa_ofi_*; quién mueve las partes:
-- custom/client/almacenajes.lua con Config.Animados; quién sienta:
-- custom/client/especiales.lua con Config.Especiales.modelos). Tres lotes:
--   oficina          escritorios, mesas de reuniones, sillas, archivador, armario, caja registradora, pizarra, estantería
--   tecnologia       escritorio y silla gamer, monitores, torre de PC, portátil, rack de servidores, impresora, router,
--                    consola, proyector y pantalla enrollable
--   estudio_musica   altavoz de estudio, mesa de DJ, tocadiscos, piano, banqueta, amplificador, micrófono y teclado
-- La silla de visita y la papelera son del pack `base` (las tiene cualquier casa).
-- Las medidas de las partes las escribe fuente/pack_ofi.py al acabar (líneas
-- «LUA»): si se cambia un modelo, aquí también.
-- El archivador, el armario y la caja registradora son almacenes (type = 'stash',
-- con los tamaños de config/stashes.lua): se abren al usarlos. Lo demás que se
-- mueve va con la E. Las pantallas brillan solas con una imagen fija: no son
-- teles (type = 'tv' pide un render target del juego que estos modelos no llevan).
-- En mesas y escritorios el frente (-Y) es el lado del que se sienta uno; en la
-- mesa de DJ, el de quien pincha (la fachada con luz mira al público).

local P = 'origen_casa_ofi_'

local function M(id, precio, nombre, extra)
    local it = { model = P .. id, price = precio, nombre = nombre, label = nombre }
    for k, v in pairs(extra or {}) do it[k] = v end
    return it
end

Config.Packs.Registrar({
    id = 'base',
    categorias = {
        ['Sillas'] = {
            M('silla_visita', 1500, 'Silla de visita de tubo cromado'),
        },
        ['Muebles'] = {
            M('papelera', 600, 'Papelera de rejilla'),
        },
    },
})

Config.Packs.Registrar({
    id = 'oficina', nombre = 'Oficina',
    descripcion = 'Despacho completo: escritorio ejecutivo de nogal, escritorio en L, mesa de dibujo, mesas de reuniones, sillas de oficina, archivador, armario, caja registradora, pizarra y estantería. Los cajones y las puertas se abren',
    xp = 0,
    categorias = {
        ['Escritorios'] = {
            M('mesa_dibujo', 4500, 'Mesa de dibujo abatible'),
            M('escritorio_l', 6500, 'Escritorio en L con cajonera'),
            M('mesa_reuniones', 8000, 'Mesa de reuniones'),
            M('escritorio_ejecutivo', 9500, 'Escritorio ejecutivo de nogal'),
            M('mesa_reuniones_grande', 16000, 'Mesa de juntas grande'),
        },
        ['Sillas'] = {
            M('silla_ergonomica', 2500, 'Silla de oficina ergonómica'),
            M('silla_director', 5500, 'Sillón de director de cuero'),
        },
        ['Muebles'] = {
            M('pizarra', 1800, 'Pizarra blanca con ruedas'),
            M('archivador', 3000, 'Archivador metálico', { type = 'stash', stash = 'normal' }),
            M('estanteria', 3500, 'Estantería de carpetas'),
            M('caja_registradora', 3500, 'Caja registradora', { type = 'stash', stash = 'small' }),
            M('armario', 5500, 'Armario de oficina', { type = 'stash', stash = 'big' }),
        },
    },
    animados = {
        [P .. 'escritorio_ejecutivo'] = { uso = 'E', texto = { 'Abrir los cajones', 'Cerrar los cajones' }, partes = {
            { modelo = 'origen_casa_ofi_escritorio_ejecutivo_cajon_i', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.420, ms = 500 },
            { modelo = 'origen_casa_ofi_escritorio_ejecutivo_cajon_d', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.420, ms = 500 }
        } },
        [P .. 'escritorio_l'] = { uso = 'E', texto = { 'Abrir el cajón', 'Cerrar el cajón' }, partes = {
            { modelo = 'origen_casa_ofi_escritorio_l_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.340, ms = 500 }
        } },
        [P .. 'mesa_dibujo'] = { uso = 'E', texto = { 'Inclinar el tablero', 'Tumbar el tablero' }, partes = {
            { modelo = 'origen_casa_ofi_mesa_dibujo_tablero', pos = { 0.000, -0.400, 0.860 }, modo = 'gira', eje = 'x', angulo = 35.0, ms = 900 }
        } },
        [P .. 'mesa_reuniones_grande'] = { uso = 'E', texto = { 'Abrir las conexiones', 'Cerrar las conexiones' }, partes = {
            { modelo = 'origen_casa_ofi_mesa_reuniones_grande_tapa', pos = { -0.924, 0.062, 0.746 }, modo = 'gira', eje = 'x', angulo = -100.0, ms = 500 }
        } },
        [P .. 'archivador'] = { uso = 'almacen', partes = {
            { modelo = 'origen_casa_ofi_archivador_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.440, ms = 600 }
        } },
        [P .. 'armario'] = { uso = 'almacen', partes = {
            { modelo = 'origen_casa_ofi_armario_puerta_i', pos = { -0.475, -0.225, 0.000 }, modo = 'gira', eje = 'z', angulo = -112.0, ms = 650 },
            { modelo = 'origen_casa_ofi_armario_puerta_d', pos = { 0.475, -0.225, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 650 }
        } },
        [P .. 'caja_registradora'] = { uso = 'almacen', partes = {
            { modelo = 'origen_casa_ofi_caja_registradora_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.200, ms = 400 }
        } },
    },
})

Config.Packs.Registrar({
    id = 'tecnologia', nombre = 'Tecnología y gaming',
    descripcion = 'Puesto gamer con LED, monitores encendidos (uno, doble y ultrapanorámico), torre con cristal, portátil que se abre, rack de servidores, impresora, router, consola, proyector y pantalla enrollable que baja',
    xp = 0,
    categorias = {
        ['Escritorios'] = {
            M('escritorio_gamer', 7500, 'Escritorio gamer con LED'),
        },
        ['Sillas'] = {
            M('silla_gamer', 4500, 'Silla gamer'),
        },
        ['Tecnología'] = {
            M('router', 1500, 'Router wifi'),
            M('impresora', 1800, 'Impresora láser'),
            M('monitor', 2000, 'Monitor de 27 pulgadas'),
            M('consola', 2200, 'Consola con mando'),
            M('portatil', 3000, 'Portátil'),
            M('proyector', 3500, 'Proyector'),
            M('monitor_doble', 4200, 'Monitor doble con brazo'),
            M('pantalla_proyeccion', 4500, 'Pantalla de proyección enrollable'),
            M('monitor_ultra', 5500, 'Monitor ultrapanorámico curvo'),
            M('torre_pc', 6500, 'Torre de PC con cristal y LED'),
            M('rack', 18000, 'Rack de servidores'),
        },
    },
    animados = {
        [P .. 'escritorio_gamer'] = { uso = 'E', texto = { 'Sacar el teclado', 'Guardar el teclado' }, partes = {
            { modelo = 'origen_casa_ofi_escritorio_gamer_bandeja', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.260, ms = 450 }
        } },
        [P .. 'portatil'] = { uso = 'E', texto = { 'Abrir el portátil', 'Cerrar el portátil' }, partes = {
            { modelo = 'origen_casa_ofi_portatil_tapa', pos = { 0.000, 0.118, 0.014 }, modo = 'gira', eje = 'x', angulo = -112.0, ms = 700 }
        } },
        [P .. 'rack'] = { uso = 'E', texto = { 'Abrir el rack', 'Cerrar el rack' }, partes = {
            { modelo = 'origen_casa_ofi_rack_puerta', pos = { 0.310, -0.475, 0.000 }, modo = 'gira', eje = 'z', angulo = 115.0, ms = 800 }
        } },
        [P .. 'impresora'] = { uso = 'E', texto = { 'Sacar la bandeja', 'Meter la bandeja' }, partes = {
            { modelo = 'origen_casa_ofi_impresora_bandeja', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.200, ms = 450 }
        } },
        [P .. 'pantalla_proyeccion'] = { uso = 'E', texto = { 'Bajar la pantalla', 'Subir la pantalla' }, partes = {
            { modelo = 'origen_casa_ofi_pantalla_proyeccion_lama1', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = -0.168, ms = 1800 },
            { modelo = 'origen_casa_ofi_pantalla_proyeccion_lama2', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = -0.336, ms = 1800 },
            { modelo = 'origen_casa_ofi_pantalla_proyeccion_lama3', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = -0.504, ms = 1800 },
            { modelo = 'origen_casa_ofi_pantalla_proyeccion_lama4', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = -0.672, ms = 1800 },
            { modelo = 'origen_casa_ofi_pantalla_proyeccion_lama5', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = -0.840, ms = 1800 },
            { modelo = 'origen_casa_ofi_pantalla_proyeccion_lama6', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = -1.008, ms = 1800 },
            { modelo = 'origen_casa_ofi_pantalla_proyeccion_lama7', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = -1.176, ms = 1800 },
            { modelo = 'origen_casa_ofi_pantalla_proyeccion_lama8', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = -1.344, ms = 1800 }
        } },
    },
})

Config.Packs.Registrar({
    id = 'estudio_musica', nombre = 'Estudio de música',
    descripcion = 'Para montar un estudio o una cabina: mesa de DJ con luz, tocadiscos con tapa, piano de pared que se abre, teclado, amplificador, altavoces de estudio y micrófono de pie',
    xp = 0,
    categorias = {
        ['Música / DJ'] = {
            M('micro_pie', 1500, 'Micrófono de pie'),
            M('banqueta_piano', 1800, 'Banqueta de piano'),
            M('altavoz_estudio', 2400, 'Altavoz de estudio con pie'),
            M('ampli', 2600, 'Amplificador de guitarra'),
            M('tocadiscos', 2800, 'Tocadiscos'),
            M('teclado_sinte', 4200, 'Teclado sintetizador'),
            M('piano', 9000, 'Piano de pared'),
            M('mesa_dj', 12000, 'Mesa de DJ'),
        },
    },
    animados = {
        [P .. 'tocadiscos'] = { uso = 'E', texto = { 'Levantar la tapa', 'Bajar la tapa' }, partes = {
            { modelo = 'origen_casa_ofi_tocadiscos_tapa', pos = { 0.000, 0.181, 0.077 }, modo = 'gira', eje = 'x', angulo = -62.0, ms = 700 }
        } },
        [P .. 'piano'] = { uso = 'E', texto = { 'Abrir el teclado', 'Cerrar el teclado' }, partes = {
            { modelo = 'origen_casa_ofi_piano_tapa', pos = { 0.000, -0.065, 0.690 }, modo = 'gira', eje = 'x', angulo = -96.0, ms = 800 }
        } },
    },
})

-- Sentarse (un asiento por mueble; x, y: desde el centro del modelo; z: altura
-- del asiento sobre su base). Va aquí y no en config/especiales.lua para no
-- tocar un fichero compartido: este se carga después.
for modelo, datos in pairs({
    [P .. 'silla_ergonomica'] = { asiento = { x = 0.00, y = -0.04, z = 0.50 } },
    [P .. 'silla_director'] = { asiento = { x = 0.00, y = -0.07, z = 0.55 } },
    [P .. 'silla_visita'] = { asiento = { x = 0.00, y = -0.04, z = 0.49 } },
    [P .. 'silla_gamer'] = { asiento = { x = 0.00, y = -0.07, z = 0.53 } },
    [P .. 'banqueta_piano'] = { asiento = { x = 0.00, y = 0.01, z = 0.50 } },
}) do
    if Config.Especiales and Config.Especiales.modelos then Config.Especiales.modelos[modelo] = datos end
end
