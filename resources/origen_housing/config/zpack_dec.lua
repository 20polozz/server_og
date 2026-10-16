-- Pack de decoración, textil y ventanas (modelos: fuente/pack_dec.py, que es quien ESCRIBE este fichero:
-- nombres, precios y medidas de las partes salen de allí; si se cambia un modelo, se vuelve a generar).
-- Tres packs: ventanas (ventanas falsas con vista y luz, cortinas, estor, veneciana), decoracion
-- (alfombras, chimenea, biombo, jarrones, velas, libros, fotos) y arte_plantas (cuadros, espejos,
-- reloj, esculturas y plantas). Las partes las mueve custom/client/almacenajes.lua (uso = 'E').
-- Los paños de una cortina, los pliegues del estor y los tramos de la veneciana son UN modelo
-- puesto varias veces, cada vez con su sitio y su recorrido.

Config.Packs.Registrar({
    id = 'ventanas', nombre = 'Ventanas y cortinas',
    descripcion = 'Ventanas falsas con vistas que alumbran (ciudad, mar, colinas, jardín, cielo), claraboyas, cortinas, estor y veneciana que se abren de verdad',
    xp = 0,
    categorias = {
        ['Ventanas y cortinas'] = {
            { model = 'origen_casa_dec_ventana_jardin', price = 4500, nombre = 'Ventana de dos hojas con vistas al jardín', label = 'Ventana de dos hojas con vistas al jardín' },
            { model = 'origen_casa_dec_ventana_ciudad', price = 5500, nombre = 'Ventana de dos hojas con vistas a la ciudad', label = 'Ventana de dos hojas con vistas a la ciudad' },
            { model = 'origen_casa_dec_ventana_mar', price = 6000, nombre = 'Ventana de dos hojas con vistas al mar', label = 'Ventana de dos hojas con vistas al mar' },
            { model = 'origen_casa_dec_ventana_colinas', price = 5500, nombre = 'Ventana de dos hojas con vistas a las colinas', label = 'Ventana de dos hojas con vistas a las colinas' },
            { model = 'origen_casa_dec_ventanal_ciudad', price = 14000, nombre = 'Ventanal con vistas a la ciudad al anochecer', label = 'Ventanal con vistas a la ciudad al anochecer' },
            { model = 'origen_casa_dec_ventanal_mar', price = 16000, nombre = 'Ventanal con vistas a la playa', label = 'Ventanal con vistas a la playa' },
            { model = 'origen_casa_dec_ventanal_palmeras', price = 14000, nombre = 'Ventanal con atardecer de palmeras', label = 'Ventanal con atardecer de palmeras' },
            { model = 'origen_casa_dec_ventanal_colinas', price = 14000, nombre = 'Ventanal con vistas a las colinas', label = 'Ventanal con vistas a las colinas' },
            { model = 'origen_casa_dec_ojo_mar', price = 5000, nombre = 'Ojo de buey con vistas al mar', label = 'Ojo de buey con vistas al mar' },
            { model = 'origen_casa_dec_ojo_cielo', price = 4500, nombre = 'Ojo de buey con cielo despejado', label = 'Ojo de buey con cielo despejado' },
            { model = 'origen_casa_dec_claraboya_cielo', price = 7500, nombre = 'Claraboya de techo con cielo de día', label = 'Claraboya de techo con cielo de día' },
            { model = 'origen_casa_dec_claraboya_noche', price = 8500, nombre = 'Claraboya de techo con cielo estrellado', label = 'Claraboya de techo con cielo estrellado' },
            { model = 'origen_casa_dec_rejas_ciudad', price = 4000, nombre = 'Ventana con rejas, vistas a la ciudad', label = 'Ventana con rejas, vistas a la ciudad' },
            { model = 'origen_casa_dec_rejas_desierto', price = 4000, nombre = 'Ventana con rejas, vistas al desierto', label = 'Ventana con rejas, vistas al desierto' },
            { model = 'origen_casa_dec_cortina_lino', price = 4500, nombre = 'Cortinas de lino', label = 'Cortinas de lino' },
            { model = 'origen_casa_dec_cortina_gris', price = 4800, nombre = 'Cortinas opacas grises', label = 'Cortinas opacas grises' },
            { model = 'origen_casa_dec_cortina_visillo', price = 4000, nombre = 'Visillos blancos translúcidos', label = 'Visillos blancos translúcidos' },
            { model = 'origen_casa_dec_cortina_azul', price = 5500, nombre = 'Cortinas estampadas azules', label = 'Cortinas estampadas azules' },
            { model = 'origen_casa_dec_cortina_terciopelo', price = 12000, nombre = 'Cortinas de terciopelo con galería', label = 'Cortinas de terciopelo con galería' },
            { model = 'origen_casa_dec_estor', price = 3500, nombre = 'Estor plegable de lino', label = 'Estor plegable de lino' },
            { model = 'origen_casa_dec_veneciana', price = 4200, nombre = 'Persiana veneciana de madera', label = 'Persiana veneciana de madera' },
        },
    },
    iconos = { ['Ventanas y cortinas'] = 'fas fa-border-all' },
    animados = {
        ['origen_casa_dec_cortina_lino'] = {
            uso = 'E', texto = { 'Abrir las cortinas', 'Cerrar las cortinas' },
            partes = {
                { modelo = 'origen_casa_dec_cortina_lino_pano', pos = { -0.733, -0.012, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.292, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_lino_pano', pos = { -0.367, -0.024, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.583, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_lino_pano', pos = { 0.000, -0.024, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.583, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_lino_pano', pos = { 0.367, -0.012, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.292, ms = 1100 },
            },
        },
        ['origen_casa_dec_cortina_gris'] = {
            uso = 'E', texto = { 'Abrir las cortinas', 'Cerrar las cortinas' },
            partes = {
                { modelo = 'origen_casa_dec_cortina_gris_pano', pos = { -0.733, -0.012, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.292, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_gris_pano', pos = { -0.367, -0.024, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.583, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_gris_pano', pos = { 0.000, -0.024, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.583, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_gris_pano', pos = { 0.367, -0.012, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.292, ms = 1100 },
            },
        },
        ['origen_casa_dec_cortina_visillo'] = {
            uso = 'E', texto = { 'Abrir las cortinas', 'Cerrar las cortinas' },
            partes = {
                { modelo = 'origen_casa_dec_cortina_visillo_pano', pos = { -0.733, -0.012, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.292, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_visillo_pano', pos = { -0.367, -0.024, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.583, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_visillo_pano', pos = { 0.000, -0.024, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.583, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_visillo_pano', pos = { 0.367, -0.012, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.292, ms = 1100 },
            },
        },
        ['origen_casa_dec_cortina_azul'] = {
            uso = 'E', texto = { 'Abrir las cortinas', 'Cerrar las cortinas' },
            partes = {
                { modelo = 'origen_casa_dec_cortina_azul_pano', pos = { -0.733, -0.012, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.292, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_azul_pano', pos = { -0.367, -0.024, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.583, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_azul_pano', pos = { 0.000, -0.024, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.583, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_azul_pano', pos = { 0.367, -0.012, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.292, ms = 1100 },
            },
        },
        ['origen_casa_dec_cortina_terciopelo'] = {
            uso = 'E', texto = { 'Abrir las cortinas', 'Cerrar las cortinas' },
            partes = {
                { modelo = 'origen_casa_dec_cortina_terciopelo_pano', pos = { -0.733, -0.012, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.292, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_terciopelo_pano', pos = { -0.367, -0.024, 0.000 }, modo = 'corre', eje = 'x', recorrido = -0.583, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_terciopelo_pano', pos = { 0.000, -0.024, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.583, ms = 1100 },
                { modelo = 'origen_casa_dec_cortina_terciopelo_pano', pos = { 0.367, -0.012, 0.000 }, modo = 'corre', eje = 'x', recorrido = 0.292, ms = 1100 },
            },
        },
        ['origen_casa_dec_estor'] = {
            uso = 'E', texto = { 'Subir el estor', 'Bajar el estor' },
            partes = {
                { modelo = 'origen_casa_dec_estor_pliegue', pos = { 0.000, -0.004, -0.258 }, modo = 'corre', eje = 'z', recorrido = 0.244, ms = 1200 },
                { modelo = 'origen_casa_dec_estor_pliegue', pos = { 0.000, -0.008, -0.517 }, modo = 'corre', eje = 'z', recorrido = 0.489, ms = 1200 },
                { modelo = 'origen_casa_dec_estor_pliegue', pos = { 0.000, -0.012, -0.775 }, modo = 'corre', eje = 'z', recorrido = 0.733, ms = 1200 },
                { modelo = 'origen_casa_dec_estor_pliegue', pos = { 0.000, -0.016, -1.033 }, modo = 'corre', eje = 'z', recorrido = 0.977, ms = 1200 },
                { modelo = 'origen_casa_dec_estor_pliegue', pos = { 0.000, -0.020, -1.292 }, modo = 'corre', eje = 'z', recorrido = 1.222, ms = 1200 },
            },
        },
        ['origen_casa_dec_veneciana'] = {
            uso = 'E', texto = { 'Subir la persiana', 'Bajar la persiana' },
            partes = {
                { modelo = 'origen_casa_dec_veneciana_lamas', pos = { 0.000, 0.000, -0.250 }, modo = 'corre', eje = 'z', recorrido = 0.242, ms = 1400 },
                { modelo = 'origen_casa_dec_veneciana_lamas', pos = { 0.000, 0.000, -0.500 }, modo = 'corre', eje = 'z', recorrido = 0.484, ms = 1400 },
                { modelo = 'origen_casa_dec_veneciana_lamas', pos = { 0.000, 0.000, -0.750 }, modo = 'corre', eje = 'z', recorrido = 0.726, ms = 1400 },
                { modelo = 'origen_casa_dec_veneciana_lamas', pos = { 0.000, 0.000, -1.000 }, modo = 'corre', eje = 'z', recorrido = 0.968, ms = 1400 },
                { modelo = 'origen_casa_dec_veneciana_lamas', pos = { 0.000, 0.000, -1.250 }, modo = 'corre', eje = 'z', recorrido = 1.210, ms = 1400 },
                { modelo = 'origen_casa_dec_veneciana_base', pos = { 0.000, 0.000, 0.000 }, modo = 'corre', eje = 'z', recorrido = 1.200, ms = 1400 },
            },
        },
    },
})

Config.Packs.Registrar({
    id = 'decoracion', nombre = 'Decoración y alfombras',
    descripcion = 'Alfombras persas y modernas, chimenea de leña con brasas, biombo plegable, jarrones, velas encendidas, libros y marcos de fotos',
    xp = 0,
    categorias = {
        ['Decoración'] = {
            { model = 'origen_casa_dec_biombo', price = 6500, nombre = 'Biombo de tres hojas pintado a tinta', label = 'Biombo de tres hojas pintado a tinta' },
            { model = 'origen_casa_dec_jarron_azul', price = 4500, nombre = 'Jarrón de suelo de cerámica azul', label = 'Jarrón de suelo de cerámica azul' },
            { model = 'origen_casa_dec_jarron_tinta', price = 3500, nombre = 'Jarrón panzudo pintado a tinta', label = 'Jarrón panzudo pintado a tinta' },
            { model = 'origen_casa_dec_anfora_bronce', price = 5500, nombre = 'Ánfora de bronce con verdín', label = 'Ánfora de bronce con verdín' },
            { model = 'origen_casa_dec_marcos_fotos', price = 1500, nombre = 'Tres marcos de fotos de sobremesa', label = 'Tres marcos de fotos de sobremesa' },
            { model = 'origen_casa_dec_chimenea', price = 22000, nombre = 'Chimenea de leña con brasas', label = 'Chimenea de leña con brasas' },
        },
        ['Alfombras'] = {
            { model = 'origen_casa_dec_alfombra_persa', price = 9000, nombre = 'Alfombra persa', label = 'Alfombra persa' },
            { model = 'origen_casa_dec_alfombra_pasillera', price = 5000, nombre = 'Alfombra pasillera oriental', label = 'Alfombra pasillera oriental' },
            { model = 'origen_casa_dec_alfombra_moderna', price = 5500, nombre = 'Alfombra moderna geométrica', label = 'Alfombra moderna geométrica' },
            { model = 'origen_casa_dec_alfombra_retro', price = 4500, nombre = 'Alfombra retro de círculos', label = 'Alfombra retro de círculos' },
            { model = 'origen_casa_dec_alfombra_pelo', price = 6500, nombre = 'Alfombra de pelo largo', label = 'Alfombra de pelo largo' },
            { model = 'origen_casa_dec_alfombra_vaca', price = 8000, nombre = 'Alfombra de piel de vaca en retales', label = 'Alfombra de piel de vaca en retales' },
            { model = 'origen_casa_dec_alfombra_redonda', price = 6000, nombre = 'Alfombra redonda granate', label = 'Alfombra redonda granate' },
            { model = 'origen_casa_dec_felpudo', price = 1500, nombre = 'Felpudo de coco', label = 'Felpudo de coco' },
        },
        ['Libros y velas'] = {
            { model = 'origen_casa_dec_velas', price = 1800, nombre = 'Bandeja con velas encendidas', label = 'Bandeja con velas encendidas' },
            { model = 'origen_casa_dec_candelabro', price = 3200, nombre = 'Candelabro de hierro de tres brazos', label = 'Candelabro de hierro de tres brazos' },
            { model = 'origen_casa_dec_libros_pila', price = 1200, nombre = 'Pila de libros de arte', label = 'Pila de libros de arte' },
            { model = 'origen_casa_dec_libros_fila', price = 1600, nombre = 'Fila de libros con sujetalibros de mármol', label = 'Fila de libros con sujetalibros de mármol' },
        },
    },
    animados = {
        ['origen_casa_dec_biombo'] = {
            uso = 'E', texto = { 'Plegar el biombo', 'Desplegar el biombo' },
            partes = {
                { modelo = 'origen_casa_dec_biombo_hoja_i', pos = { -0.284, -0.016, 0.000 }, modo = 'gira', eje = 'z', angulo = 148.0, ms = 1200 },
                { modelo = 'origen_casa_dec_biombo_hoja_d', pos = { 0.284, 0.016, 0.000 }, modo = 'gira', eje = 'z', angulo = 148.0, ms = 1200 },
            },
        },
    },
})

Config.Packs.Registrar({
    id = 'arte_plantas', nombre = 'Arte y plantas',
    descripcion = 'Óleos enmarcados, tríptico, espejos, reloj de pared, esculturas de bronce y mármol y plantas de interior en maceta',
    xp = 0,
    categorias = {
        ['Arte'] = {
            { model = 'origen_casa_dec_cuadro_retrato', price = 9500, nombre = 'Retrato clásico con marco dorado', label = 'Retrato clásico con marco dorado' },
            { model = 'origen_casa_dec_cuadro_caballero', price = 8500, nombre = 'Retrato de caballero', label = 'Retrato de caballero' },
            { model = 'origen_casa_dec_cuadro_fabrica', price = 7000, nombre = 'Óleo «La fábrica»', label = 'Óleo «La fábrica»' },
            { model = 'origen_casa_dec_cuadro_iglesia', price = 6000, nombre = 'Paisaje «La iglesia»', label = 'Paisaje «La iglesia»' },
            { model = 'origen_casa_dec_cuadro_noche', price = 7500, nombre = 'Óleo «Noctámbulos»', label = 'Óleo «Noctámbulos»' },
            { model = 'origen_casa_dec_cuadro_ojo', price = 5500, nombre = 'Cuadro surrealista «El ojo»', label = 'Cuadro surrealista «El ojo»' },
            { model = 'origen_casa_dec_cuadro_plaza', price = 9000, nombre = 'Óleo «La plaza»', label = 'Óleo «La plaza»' },
            { model = 'origen_casa_dec_cuadro_mujer', price = 5000, nombre = 'Retrato «La mujer de negro»', label = 'Retrato «La mujer de negro»' },
            { model = 'origen_casa_dec_lienzo_azul', price = 6500, nombre = 'Lienzo abstracto azul', label = 'Lienzo abstracto azul' },
            { model = 'origen_casa_dec_triptico', price = 9500, nombre = 'Tríptico abstracto', label = 'Tríptico abstracto' },
            { model = 'origen_casa_dec_espejo_dorado', price = 7500, nombre = 'Espejo de pared con marco dorado', label = 'Espejo de pared con marco dorado' },
            { model = 'origen_casa_dec_espejo_redondo', price = 5000, nombre = 'Espejo redondo de latón', label = 'Espejo redondo de latón' },
            { model = 'origen_casa_dec_reloj', price = 3500, nombre = 'Reloj de pared de números romanos', label = 'Reloj de pared de números romanos' },
        },
        ['Esculturas y premios'] = {
            { model = 'origen_casa_dec_escultura_cinta', price = 14000, nombre = 'Escultura moderna «Cinta» en bronce', label = 'Escultura moderna «Cinta» en bronce' },
            { model = 'origen_casa_dec_esfera_marmol', price = 8000, nombre = 'Esfera de mármol sobre peana', label = 'Esfera de mármol sobre peana' },
        },
        ['Plantas'] = {
            { model = 'origen_casa_dec_planta_monstera', price = 3800, nombre = 'Monstera en maceta blanca', label = 'Monstera en maceta blanca' },
            { model = 'origen_casa_dec_planta_ficus', price = 4500, nombre = 'Ficus de interior', label = 'Ficus de interior' },
            { model = 'origen_casa_dec_planta_palmera', price = 5200, nombre = 'Palmera areca de interior', label = 'Palmera areca de interior' },
            { model = 'origen_casa_dec_planta_cactus', price = 3200, nombre = 'Cactus saguaro en maceta', label = 'Cactus saguaro en maceta' },
            { model = 'origen_casa_dec_planta_aloe', price = 2400, nombre = 'Aloe vera en maceta de barro', label = 'Aloe vera en maceta de barro' },
            { model = 'origen_casa_dec_planta_sansevieria', price = 2600, nombre = 'Lengua de suegra', label = 'Lengua de suegra' },
            { model = 'origen_casa_dec_planta_colgante', price = 3000, nombre = 'Planta colgante de techo', label = 'Planta colgante de techo' },
            { model = 'origen_casa_dec_planta_jardinera', price = 3400, nombre = 'Jardinera con pensamientos', label = 'Jardinera con pensamientos' },
            { model = 'origen_casa_dec_planta_flores', price = 2200, nombre = 'Jarrón con flores frescas', label = 'Jarrón con flores frescas' },
        },
    },
})
