-- Muebles propios de los packs «Clínica clandestina» y «Estudio de tatuaje y barbería»
-- (modelos: fuente/pack_t2.py, origen_casa_t2_*). ESTE FICHERO LO ESCRIBE fuente/pack_t2_lua.py:
-- nombres, precios y categorías se tocan allí; las medidas de las partes salen de los modelos.
--
-- Función (por su `type`, el de siempre del housing):
--   · stash     vitrina de medicinas, nevera de muestras y botiquín de pared: se abren al usarlos
--   · wardrobe  taquilla de batas: sus puertas se abren al abrir el menú de ropa
-- Luz: lámpara quirúrgica, lámpara de aro, tocador de bombillas, expositor, poste de barbero, cruz y
-- neones llevan su luz DENTRO del modelo (siempre encendida, sin interruptor) además del emisivo.
-- «Se enciende» con la E (monitor de constantes, negatoscopio, mesa de luz): la parte es la lámina
-- encendida, escondida dentro del mueble, que sale unos milímetros por delante de la apagada.
-- El poste de barbero «gira»: el sistema de partes solo sabe ir de cerrado a abierto, así que al
-- encenderlo da diez vueltas en catorce segundos y se para (y al apagarlo las desanda).
-- Lo de pared tiene el origen en su canto de abajo: se coloca y se sube.
-- Quién mueve las partes: custom/client/almacenajes.lua con Config.Animados.

Config.Packs.Registrar({
    id = 'clinica_clandestina', nombre = 'Clínica clandestina',
    descripcion = 'Todo para montar un quirófano donde nadie pregunta: camilla con respaldo que sube, mesa de quirófano articulada, lámpara quirúrgica que alumbra de verdad, monitor de constantes y negatoscopio que se encienden, carro de curas con cajones, gotero, bombona de oxígeno, silla de ruedas, báscula, lavamanos, biombo, cubo de residuos de pedal y cruz de neón; la vitrina de medicinas, la nevera de muestras y el botiquín guardan cosas, y la taquilla de batas es un ropero',
    xp = 400, grupo = 'tematico',
    categorias = {
        ['Camas'] = {
            { model = 'origen_casa_t2_camilla', price = 6500, nombre = 'Camilla de hospital con respaldo abatible', label = 'Camilla de hospital con respaldo abatible' },
        },
        ['Mesas'] = {
            { model = 'origen_casa_t2_mesa_quirofano', price = 14000, nombre = 'Mesa de quirófano articulada', label = 'Mesa de quirófano articulada' },
            { model = 'origen_casa_t2_mesa_instrumental', price = 2600, nombre = 'Mesa de instrumental quirúrgico', label = 'Mesa de instrumental quirúrgico' },
        },
        ['Luces'] = {
            { model = 'origen_casa_t2_lampara_quirurgica', price = 7500, nombre = 'Lámpara quirúrgica de pie', label = 'Lámpara quirúrgica de pie' },
        },
        ['Carteles de neón'] = {
            { model = 'origen_casa_t2_cruz_farmacia', price = 3800, nombre = 'Cruz de farmacia de neón verde', label = 'Cruz de farmacia de neón verde' },
        },
        ['Sillas'] = {
            { model = 'origen_casa_t2_silla_ruedas', price = 3200, nombre = 'Silla de ruedas', label = 'Silla de ruedas' },
            { model = 'origen_casa_t2_taburete_medico', price = 1600, nombre = 'Taburete clínico con ruedas', label = 'Taburete clínico con ruedas' },
        },
        ['Almacenaje'] = {
            { model = 'origen_casa_t2_vitrina_medicinas', price = 9000, nombre = 'Vitrina de medicinas', label = 'Vitrina de medicinas', type = 'stash', stash = 'big' },
            { model = 'origen_casa_t2_botiquin_pared', price = 3000, nombre = 'Botiquín de pared', label = 'Botiquín de pared', type = 'stash', stash = 'small' },
        },
        ['Neveras'] = {
            { model = 'origen_casa_t2_nevera_muestras', price = 8500, nombre = 'Nevera de muestras de laboratorio', label = 'Nevera de muestras de laboratorio', type = 'stash', stash = 'normal' },
        },
        ['Armarios'] = {
            { model = 'origen_casa_t2_taquilla_batas', price = 6000, nombre = 'Taquilla de batas y pijamas de quirófano', label = 'Taquilla de batas y pijamas de quirófano', type = 'wardrobe' },
        },
        ['Muebles'] = {
            { model = 'origen_casa_t2_carro_curas', price = 5200, nombre = 'Carro de curas con cajones', label = 'Carro de curas con cajones' },
        },
        ['Tecnología'] = {
            { model = 'origen_casa_t2_monitor_constantes', price = 6800, nombre = 'Monitor de constantes vitales', label = 'Monitor de constantes vitales' },
            { model = 'origen_casa_t2_negatoscopio', price = 3600, nombre = 'Negatoscopio con radiografías', label = 'Negatoscopio con radiografías' },
        },
        ['Baño'] = {
            { model = 'origen_casa_t2_lavamanos', price = 4200, nombre = 'Lavamanos clínico de acero', label = 'Lavamanos clínico de acero' },
        },
        ['Paredes'] = {
            { model = 'origen_casa_t2_biombo_medico', price = 2400, nombre = 'Biombo médico con ruedas', label = 'Biombo médico con ruedas' },
        },
        ['Varios'] = {
            { model = 'origen_casa_t2_gotero', price = 1500, nombre = 'Gotero con suero y sangre', label = 'Gotero con suero y sangre' },
            { model = 'origen_casa_t2_bascula', price = 2200, nombre = 'Báscula de columna con tallímetro', label = 'Báscula de columna con tallímetro' },
            { model = 'origen_casa_t2_cubo_pedal', price = 1200, nombre = 'Cubo de residuos biológicos de pedal', label = 'Cubo de residuos biológicos de pedal' },
            { model = 'origen_casa_t2_bombona_oxigeno', price = 2800, nombre = 'Bombona de oxígeno con carro', label = 'Bombona de oxígeno con carro' },
        },
    },
    animados = {
        ['origen_casa_t2_camilla'] = { uso = 'E', texto = { 'Subir el respaldo', 'Bajar el respaldo' }, partes = { { modelo = 'origen_casa_t2_camilla_respaldo', pos = { 0.000, 0.155, 0.496 }, modo = 'gira', eje = 'x', angulo = 52.0, ms = 1500 } } },
        ['origen_casa_t2_mesa_quirofano'] = { uso = 'E', texto = { 'Articular la mesa', 'Poner la mesa plana' }, partes = { { modelo = 'origen_casa_t2_mesa_quirofano_cabecero', pos = { 0.000, 0.560, 0.815 }, modo = 'gira', eje = 'x', angulo = 26.0, ms = 1300 }, { modelo = 'origen_casa_t2_mesa_quirofano_piernas', pos = { 0.000, -0.360, 0.815 }, modo = 'gira', eje = 'x', angulo = 30.0, ms = 1300 } } },
        ['origen_casa_t2_vitrina_medicinas'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_t2_vitrina_medicinas_puerta_i', pos = { -0.405, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = -105.0, ms = 700 }, { modelo = 'origen_casa_t2_vitrina_medicinas_puerta_d', pos = { 0.405, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = 105.0, ms = 700 } } },
        ['origen_casa_t2_botiquin_pared'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_t2_botiquin_pared_puerta', pos = { 0.220, -0.065, 0.000 }, modo = 'gira', eje = 'z', angulo = 115.0, ms = 600 } } },
        ['origen_casa_t2_nevera_muestras'] = { uso = 'almacen', partes = { { modelo = 'origen_casa_t2_nevera_muestras_puerta', pos = { 0.320, -0.270, 0.000 }, modo = 'gira', eje = 'z', angulo = 112.0, ms = 700 } } },
        ['origen_casa_t2_taquilla_batas'] = { uso = 'ropero', partes = { { modelo = 'origen_casa_t2_taquilla_batas_puerta_i', pos = { -0.420, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = -108.0, ms = 700 }, { modelo = 'origen_casa_t2_taquilla_batas_puerta_d', pos = { 0.420, -0.210, 0.000 }, modo = 'gira', eje = 'z', angulo = 108.0, ms = 700 } } },
        ['origen_casa_t2_carro_curas'] = { uso = 'E', texto = { 'Abrir los cajones', 'Cerrar los cajones' }, partes = { { modelo = 'origen_casa_t2_carro_curas_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.300, ms = 600 }, { modelo = 'origen_casa_t2_carro_curas_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.200, ms = 600 } } },
        ['origen_casa_t2_monitor_constantes'] = { uso = 'E', texto = { 'Encender', 'Apagar' }, partes = { { modelo = 'origen_casa_t2_monitor_constantes_pantalla', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.006, ms = 150 } } },
        ['origen_casa_t2_negatoscopio'] = { uso = 'E', texto = { 'Encender', 'Apagar' }, partes = { { modelo = 'origen_casa_t2_negatoscopio_luz', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.008, ms = 120 } } },
        ['origen_casa_t2_cubo_pedal'] = { uso = 'E', texto = { 'Abrir la tapa', 'Cerrar la tapa' }, partes = { { modelo = 'origen_casa_t2_cubo_pedal_tapa', pos = { 0.000, 0.172, 0.572 }, modo = 'gira', eje = 'x', angulo = -72.0, ms = 450 } } },
    },
})

Config.Packs.Registrar({
    id = 'tattoo_barberia', nombre = 'Estudio de tatuaje y barbería',
    descripcion = 'Abre tu propio estudio: sillón de tatuador y sillón de barbero que se reclinan, camilla con cabecero abatible, carro de tintas con cajones, mesa de luz que se enciende, esterilizador con puerta, secador de casco, lavacabezas, expositor de piercings con vitrina, tocador con espejo de bombillas y lámpara de aro que alumbran, poste de barbero que gira, flash de diseños, carteles y los neones «Tattoo» y «Barber»',
    xp = 400, grupo = 'tematico',
    categorias = {
        ['Sillones'] = {
            { model = 'origen_casa_t2_sillon_tatuador', price = 9500, nombre = 'Sillón de tatuador reclinable', label = 'Sillón de tatuador reclinable' },
            { model = 'origen_casa_t2_sillon_barbero', price = 12000, nombre = 'Sillón de barbero clásico reclinable', label = 'Sillón de barbero clásico reclinable' },
        },
        ['Camas'] = {
            { model = 'origen_casa_t2_camilla_tatuaje', price = 5200, nombre = 'Camilla de tatuaje con cabecero abatible', label = 'Camilla de tatuaje con cabecero abatible' },
        },
        ['Sillas'] = {
            { model = 'origen_casa_t2_taburete_ruedas', price = 1800, nombre = 'Taburete de tatuador con respaldo', label = 'Taburete de tatuador con respaldo' },
        },
        ['Luces'] = {
            { model = 'origen_casa_t2_aro_luz', price = 2800, nombre = 'Lámpara de aro con trípode', label = 'Lámpara de aro con trípode' },
        },
        ['Carteles de neón'] = {
            { model = 'origen_casa_t2_neon_tattoo', price = 4500, nombre = 'Neón «Tattoo»', label = 'Neón «Tattoo»' },
            { model = 'origen_casa_t2_neon_barber', price = 4500, nombre = 'Neón «Barber»', label = 'Neón «Barber»' },
        },
        ['Muebles'] = {
            { model = 'origen_casa_t2_tocador_bombillas', price = 11000, nombre = 'Tocador de barbero con espejo de bombillas', label = 'Tocador de barbero con espejo de bombillas' },
            { model = 'origen_casa_t2_carro_tintas', price = 4800, nombre = 'Carro de tintas con cajones', label = 'Carro de tintas con cajones' },
        },
        ['Escritorios'] = {
            { model = 'origen_casa_t2_mesa_luz', price = 4600, nombre = 'Mesa de luz de dibujo', label = 'Mesa de luz de dibujo' },
        },
        ['Baño'] = {
            { model = 'origen_casa_t2_lavacabezas', price = 7500, nombre = 'Lavacabezas de peluquería', label = 'Lavacabezas de peluquería' },
        },
        ['Electrodomésticos'] = {
            { model = 'origen_casa_t2_esterilizador', price = 5500, nombre = 'Esterilizador de autoclave', label = 'Esterilizador de autoclave' },
            { model = 'origen_casa_t2_secador_casco', price = 3400, nombre = 'Secador de casco de pie', label = 'Secador de casco de pie' },
        },
        ['Joyas'] = {
            { model = 'origen_casa_t2_expositor_piercings', price = 9000, nombre = 'Expositor de piercings con vitrina', label = 'Expositor de piercings con vitrina' },
        },
        ['Arte'] = {
            { model = 'origen_casa_t2_flash_pared', price = 3200, nombre = 'Flash de tatuajes enmarcado', label = 'Flash de tatuajes enmarcado' },
            { model = 'origen_casa_t2_cartel_hotshave', price = 1600, nombre = 'Cartel esmaltado «Hot Shave»', label = 'Cartel esmaltado «Hot Shave»' },
            { model = 'origen_casa_t2_cuadros_barberia', price = 2200, nombre = 'Cuadros de barbería: cortes y precios', label = 'Cuadros de barbería: cortes y precios' },
        },
        ['Decoración'] = {
            { model = 'origen_casa_t2_poste_barbero', price = 3800, nombre = 'Poste de barbero giratorio', label = 'Poste de barbero giratorio' },
            { model = 'origen_casa_t2_estante_tintas', price = 2400, nombre = 'Estante de tintas de pared', label = 'Estante de tintas de pared' },
        },
        ['Varios'] = {
            { model = 'origen_casa_t2_reposabrazos', price = 1400, nombre = 'Reposabrazos de tatuador', label = 'Reposabrazos de tatuador' },
        },
    },
    animados = {
        ['origen_casa_t2_sillon_tatuador'] = { uso = 'E', texto = { 'Reclinar', 'Incorporar' }, partes = { { modelo = 'origen_casa_t2_sillon_tatuador_respaldo', pos = { 0.000, 0.260, 0.495 }, modo = 'gira', eje = 'x', angulo = -42.0, ms = 1500 }, { modelo = 'origen_casa_t2_sillon_tatuador_reposapiernas', pos = { 0.000, -0.270, 0.485 }, modo = 'gira', eje = 'x', angulo = -68.0, ms = 1500 } } },
        ['origen_casa_t2_sillon_barbero'] = { uso = 'E', texto = { 'Reclinar', 'Incorporar' }, partes = { { modelo = 'origen_casa_t2_sillon_barbero_respaldo', pos = { 0.000, 0.270, 0.530 }, modo = 'gira', eje = 'x', angulo = -38.0, ms = 1500 } } },
        ['origen_casa_t2_camilla_tatuaje'] = { uso = 'E', texto = { 'Subir el cabecero', 'Bajar el cabecero' }, partes = { { modelo = 'origen_casa_t2_camilla_tatuaje_cabecero', pos = { 0.000, 0.510, 0.670 }, modo = 'gira', eje = 'x', angulo = 35.0, ms = 1100 } } },
        ['origen_casa_t2_tocador_bombillas'] = { uso = 'E', texto = { 'Abrir el cajón', 'Cerrar el cajón' }, partes = { { modelo = 'origen_casa_t2_tocador_bombillas_cajon', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.260, ms = 600 } } },
        ['origen_casa_t2_carro_tintas'] = { uso = 'E', texto = { 'Abrir los cajones', 'Cerrar los cajones' }, partes = { { modelo = 'origen_casa_t2_carro_tintas_cajon_a', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.280, ms = 600 }, { modelo = 'origen_casa_t2_carro_tintas_cajon_b', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'y', recorrido = -0.180, ms = 600 } } },
        ['origen_casa_t2_mesa_luz'] = { uso = 'E', texto = { 'Encender la mesa de luz', 'Apagar la mesa de luz' }, partes = { { modelo = 'origen_casa_t2_mesa_luz_luz', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = 0.006, ms = 120 } } },
        ['origen_casa_t2_esterilizador'] = { uso = 'E', texto = { 'Abrir la puerta', 'Cerrar la puerta' }, partes = { { modelo = 'origen_casa_t2_esterilizador_puerta', pos = { -0.238, -0.275, 0.000 }, modo = 'gira', eje = 'z', angulo = -112.0, ms = 800 } } },
        ['origen_casa_t2_secador_casco'] = { uso = 'E', texto = { 'Levantar el casco', 'Bajar el casco' }, partes = { { modelo = 'origen_casa_t2_secador_casco_casco', pos = { 0.000, -0.050, 1.380 }, modo = 'gira', eje = 'x', angulo = -52.0, ms = 900 } } },
        ['origen_casa_t2_expositor_piercings'] = { uso = 'E', texto = { 'Abrir la vitrina', 'Cerrar la vitrina' }, partes = { { modelo = 'origen_casa_t2_expositor_piercings_tapa', pos = { 0.000, 0.253, 1.063 }, modo = 'gira', eje = 'x', angulo = -58.0, ms = 800 } } },
        ['origen_casa_t2_poste_barbero'] = { uso = 'E', texto = { 'Encender', 'Apagar' }, partes = { { modelo = 'origen_casa_t2_poste_barbero_franjas', pos = { 0.000, -0.130, 0.200 }, modo = 'gira', eje = 'z', angulo = 3600.0, ms = 14000 } } },
    },
})
