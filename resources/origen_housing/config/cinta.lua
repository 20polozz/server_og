-- La cinta (custom/client/obra.lua, ui/js/obra.js): cómo se ordena el catálogo,
-- cómo se llama cada cosa, qué hace cada tecla y la ayuda de cada herramienta.
--
-- Aquí NO se da de alta contenido: los muebles siguen en config/furniture.lua y
-- en los config/zpack_*.lua, las herramientas en custom/client/obra.lua y los
-- materiales en config/obra.lua. Este fichero solo dice DÓNDE sale cada cosa:
--
--   grupo (Q y E)  →  subgrupo (flechas ← →)  →  la fila de cosas (rueda)
--
-- Miniaturas: los muebles, ui/img/furniture/<modelo>.png; los materiales,
-- ui/img/obra/<material>.jpg; las herramientas, su icono (HERRAMIENTAS, en
-- custom/client/obra.lua). Los estilos que pasa la R (barandillas, pasos
-- secretos, trampillas) salen en una tira encima de la cosa, con su nombre; si
-- existe ui/img/obra/estilos/<grupo>_<id>.png (grupo: barandillas, secretos,
-- trampillas; 64x64 basta), la tira enseña también esa imagen.
--
-- Una categoría nueva que llegue por un pack no hay que apuntarla en ningún
-- sitio: cae en su grupo por el nombre (Config.Cinta.reglas) y, si ninguna
-- regla la reconoce, en «Varios», con su propio nombre de subgrupo.
Config.Cinta = {}
local T = Config.Cinta

-- ── Las teclas ──────────────────────────────────────────────────────────
-- La chuleta entera. La fila de abajo de la cinta enseña de aquí solo lo que
-- vale para lo que se lleva en la mano, siempre en este orden; la H la enseña
-- completa. (Los números son los controles del juego que lee obra.lua.)
--
--   MOVERSE POR EL CATÁLOGO
--     Q / E ............ grupo anterior / siguiente
--     ← / → ............ subgrupo anterior / siguiente
--     Rueda ............ cosa anterior / siguiente
--     ↑ / ↓ ............ saltar diez cosas (también Re Pág / Av Pág)
--     Intro ............ buscar por nombre en todo el catálogo (Intro acepta, Esc cancela)
--   PONER Y QUITAR
--     Clic ............. poner lo que se lleva (mueble: ajustarlo antes; material: pintar, y arrastrando)
--     Mayús + Clic ..... mueble: colocarlo ya donde se ve · material: toda la sala
--     Clic derecho ..... quitar lo que se mira (con Excavar: rellenar)
--     Z ................ deshacer el último cambio de obra (hasta cinco)
--   VARIANTES DE LO QUE SE LLEVA
--     R ................ la variante siguiente: estilo, tamaño, mano o giro de la pieza
--                        (con un mueble: ajuste fino, mover → girar → otra vez con la mira)
--     Mayús + Rueda .... girar (mueble) · dar la vuelta, frente, sube o baja (pieza)
--     Alt .............. mantener: sin imán (el mueble va libre; la puerta no busca su hueco)
--   SOBRE LO QUE SE MIRA
--     G ................ mover un mueble ya puesto
--     Clic central / X . cuentagotas: llevarse en la mano lo que se mira
--   VARIOS
--     F ................ guardar o quitar de favoritos
--     H ................ esta ayuda
--     Retroceso ........ salir
--
-- Fuera de la cinta, la G delante de un paso secreto abre su menú (clave,
-- gatillo…): es de custom/client/secretos.lua y no choca, porque con la cinta
-- abierta ese menú no se ofrece.
T.teclas = {
    grupo = 'Q / E', subgrupo = '← →', pasar = 'Rueda', saltar = '↑ ↓', buscar = 'Intro',
    poner = 'Clic', rapido = 'Mayús + Clic', quitar = 'Clic dcho', deshacer = 'Z',
    variante = 'R', girar = 'Mayús + Rueda', libre = 'Alt',
    mover = 'G', cuentagotas = 'Clic central', favorito = 'F', ayuda = 'H', salir = 'Retroceso',
}
T.salto = 10        -- cosas que saltan ↑ y ↓
T.maxBusqueda = 80  -- resultados que enseña el buscador, como mucho

-- La chuleta que enseña la H debajo de la ayuda de la herramienta
T.chuleta = {
    { 'Q / E', 'Grupo' }, { '← →', 'Subgrupo' }, { 'Rueda', 'Pasar' }, { '↑ ↓', 'Saltar 10' }, { 'Intro', 'Buscar' },
    { 'Clic', 'Poner' }, { 'Clic dcho', 'Quitar lo que miras' }, { 'R', 'Variante' }, { 'Mayús + Rueda', 'Girar' },
    { 'G', 'Mover un mueble puesto' }, { 'Clic central', 'Cuentagotas' }, { 'F', 'Favorito' }, { 'Z', 'Deshacer obra' },
}

-- ── Los grupos ──────────────────────────────────────────────────────────
-- En el orden en que salen. `subs`: el orden de sus subgrupos (uno que no esté
-- en la lista va detrás, por orden alfabético).
T.grupos = {
    { id = 'construir', nombre = 'Construir', icono = 'fas fa-trowel-bricks', obra = true,
        subs = { 'Estructura', 'Entradas', 'Escaleras', 'Ascensores y coches', 'Barandillas', 'Secretos', 'Imágenes' } },
    { id = 'pintar', nombre = 'Pintar', icono = 'fas fa-fill-drip', obra = true,
        subs = { 'Paredes lisas', 'Ladrillo y piedra', 'Madera', 'Suelos', 'Urbano y sucio', 'Lujo', 'Cristales' } },
    { id = 'salon', nombre = 'Salón', icono = 'fas fa-couch',
        subs = { 'Sofás y sillones', 'Mesas de centro y auxiliares', 'Muebles de tele', 'Aparadores y consolas', 'Chimeneas' } },
    { id = 'cocina', nombre = 'Comedor y cocina', icono = 'fas fa-utensils',
        subs = { 'Mesas y sillas', 'Cocina y electrodomésticos', 'Neveras', 'Menaje', 'Comida', 'Bebidas' } },
    { id = 'dormitorio', nombre = 'Dormitorio', icono = 'fas fa-bed',
        subs = { 'Camas', 'Mesillas y cómodas', 'Armarios' } },
    { id = 'bano', nombre = 'Baño', icono = 'fas fa-bath',
        subs = { 'Sanitarios', 'Toallas y aseo', 'Lavandería y limpieza' } },
    { id = 'oficina', nombre = 'Oficina y tecnología', icono = 'fas fa-laptop',
        subs = { 'Escritorios y sillas', 'Ordenadores y oficina', 'Televisores', 'Seguridad' } },
    { id = 'luz', nombre = 'Iluminación', icono = 'fas fa-lightbulb',
        subs = { 'De techo', 'De pie', 'De mesa', 'De pared', 'Lámparas', 'Focos', 'Neones', 'Interruptores y puntos de luz' } },
    { id = 'almacen', nombre = 'Almacenaje', icono = 'fas fa-box-archive',
        subs = { 'Almacenajes', 'Armeros' } },
    { id = 'deco', nombre = 'Decoración', icono = 'fas fa-palette',
        subs = { 'Cuadros y arte', 'Esculturas y trofeos', 'Plantas', 'Alfombras', 'Ventanas, cortinas y persianas', 'Libros, velas y relojes', 'Jarrones y adornos', 'Joyas', 'Objetos' } },
    { id = 'puertas', nombre = 'Puertas', icono = 'fas fa-door-open',
        subs = { 'Puertas', 'Portones de garaje', 'Rejas y verjas' } },
    { id = 'jardin', nombre = 'Exterior y jardín', icono = 'fas fa-umbrella-beach',
        subs = { 'Barbacoas y fuego', 'Tumbonas, bancos y sillas', 'Sombrillas y cenadores', 'Arbustos y árboles', 'Jardinería' } },
    { id = 'ocio', nombre = 'Ocio y gimnasio', icono = 'fas fa-gamepad',
        subs = { 'Recreativas y juegos', 'Gimnasio', 'Música y DJ', 'Instrumentos', 'Mascotas' } },
    { id = 'taller', nombre = 'Garaje y taller', icono = 'fas fa-car',
        subs = { 'Elevadores y plataformas', 'Taller', 'Herramientas' } },
    { id = 'sotano', nombre = 'Sótano', icono = 'fas fa-dungeon',
        subs = { 'Mobiliario y trastos', 'Celda y herramientas', 'Guarida' } },
    { id = 'secretos', nombre = 'Secretos', icono = 'fas fa-user-secret',
        subs = { 'Gatillos y escondites' } },
    { id = 'varios', nombre = 'Varios', icono = 'fas fa-box-open', subs = { 'Varios', 'Muros y jardineras' } },
}

-- ── Construir y pintar ──────────────────────────────────────────────────
-- Subgrupo de cada herramienta de obra (ids de HERRAMIENTAS, custom/client/obra.lua).
-- Una herramienta nueva que no esté aquí sale en «Más».
T.herramientas = {
    cavar = 'Estructura', pared = 'Estructura', esquina = 'Estructura', suelo = 'Estructura', puerta = 'Estructura', puerta2 = 'Estructura', garaje = 'Estructura',
    sube = 'Escaleras', baja = 'Escaleras', subeL = 'Escaleras', bajaL = 'Escaleras', escala = 'Escaleras', caracol = 'Escaleras',
    ascensor = 'Ascensores y coches', ascensor2 = 'Ascensores y coches', montacoches = 'Ascensores y coches',
    barandilla = 'Barandillas', secreto = 'Secretos', trampilla = 'Secretos', imagen = 'Imágenes',
    entrada = 'Entradas', cochera = 'Entradas',      -- custom/client/entradas.lua
}

-- Cómo se llama cada herramienta fuera de la cinta (el panel de cosméticos y la
-- tienda, al dar una suelta: Config.Packs.NombrePieza). Los mismos nombres que
-- en HERRAMIENTAS (custom/client/obra.lua), que es solo del cliente.
T.nombresHerramienta = {
    cavar = 'Excavar', pared = 'Pared', barandilla = 'Barandilla', puerta = 'Hueco de puerta', puerta2 = 'Hueco de puerta doble',
    garaje = 'Hueco de garaje', secreto = 'Puerta secreta', trampilla = 'Trampilla', suelo = 'Suelo entre plantas',
    baja = 'Escalera que baja', sube = 'Escalera que sube', bajaL = 'Escalera en L que baja', subeL = 'Escalera en L que sube',
    escala = 'Escalera de mano', caracol = 'Escalera de caracol', ascensor = 'Ascensor', ascensor2 = 'Ascensor de cabina',
    montacoches = 'Montacoches', imagen = 'Imagen', entrada = 'Entrada', cochera = 'Entrada de garaje',
    esquina = 'Esquina redondeada',
}

-- Subgrupo de cada material de pintar (ids de Config.Obra.materiales). Uno
-- nuevo que no esté aquí va por su id: T.reglasMaterial, y si no, «Paredes lisas».
T.materiales = {
    blanco = 'Paredes lisas', crema = 'Paredes lisas', gris = 'Paredes lisas', azul = 'Paredes lisas', verde = 'Paredes lisas', papel = 'Paredes lisas',
    ladrillo = 'Ladrillo y piedra', ladrillo_cal = 'Ladrillo y piedra', bloque = 'Ladrillo y piedra', hormigon = 'Ladrillo y piedra', pizarra = 'Ladrillo y piedra',
    madera = 'Madera', tablones = 'Madera', parquet_oscuro = 'Madera',
    baldosa = 'Suelos', moqueta = 'Suelos', linoleo = 'Suelos', microcemento = 'Suelos',
    ladrillo_viejo = 'Urbano y sucio', humedad = 'Urbano y sucio', desconchado = 'Urbano y sucio', chapa_oxido = 'Urbano y sucio',
    cemento_aceite = 'Urbano y sucio', azulejo = 'Urbano y sucio', moqueta_sucia = 'Urbano y sucio', chapa_lagrimada = 'Urbano y sucio',
    marmol = 'Lujo', marmol_negro = 'Lujo',
}
T.reglasMaterial = {
    { 'cristal', 'Cristales' }, { 'vidrio', 'Cristales' }, { 'marmol', 'Lujo' }, { 'oro', 'Lujo' }, { 'terciopelo', 'Lujo' },
    { 'sucio', 'Urbano y sucio' }, { 'sucia', 'Urbano y sucio' }, { 'viejo', 'Urbano y sucio' }, { 'oxido', 'Urbano y sucio' }, { 'chapa', 'Urbano y sucio' }, { 'grafiti', 'Urbano y sucio' },
    { 'ladrillo', 'Ladrillo y piedra' }, { 'piedra', 'Ladrillo y piedra' }, { 'hormigon', 'Ladrillo y piedra' }, { 'cemento', 'Ladrillo y piedra' },
    { 'parquet', 'Madera' }, { 'madera', 'Madera' }, { 'tarima', 'Madera' }, { 'roble', 'Madera' }, { 'nogal', 'Madera' },
    { 'baldosa', 'Suelos' }, { 'moqueta', 'Suelos' }, { 'suelo', 'Suelos' }, { 'gres', 'Suelos' }, { 'terrazo', 'Suelos' },
}

-- ── Las categorías del catálogo ─────────────────────────────────────────
-- Etiqueta de la categoría (config/furniture.lua y packs) → { grupo, subgrupo }.
--   abierta = true   es un cajón de sastre: cada mueble puede irse a otro grupo
--                    si el diccionario de más abajo sabe lo que es
--   afinar = true    sin salir del grupo, el diccionario reparte sus muebles
--                    entre los subgrupos (las neveras de «Cocina», a «Neveras»)
--   finos = { { 'trozo del modelo', 'Subgrupo' }, … }   reparto dentro del grupo
T.categorias = {
    ['Sillones'] = { 'salon', 'Sofás y sillones', abierta = true },
    ['Televisores con mueble'] = { 'salon', 'Muebles de tele' },
    ['Muebles'] = { 'salon', 'Aparadores y consolas', abierta = true },
    ['Mesas'] = { 'cocina', 'Mesas y sillas', abierta = true },
    ['Sillas'] = { 'cocina', 'Mesas y sillas', abierta = true },
    ['Cocina'] = { 'cocina', 'Cocina y electrodomésticos', afinar = true },
    ['Electrodomésticos'] = { 'cocina', 'Cocina y electrodomésticos', abierta = true },
    ['Neveras'] = { 'cocina', 'Neveras' },
    ['Comida'] = { 'cocina', 'Comida', afinar = true },
    ['Bebidas'] = { 'cocina', 'Bebidas', afinar = true },
    ['Camas'] = { 'dormitorio', 'Camas' },
    ['Armarios'] = { 'dormitorio', 'Armarios' },
    ['Baño'] = { 'bano', 'Toallas y aseo', afinar = true },
    ['Lavandería y limpieza'] = { 'bano', 'Lavandería y limpieza' },
    ['Escritorios'] = { 'oficina', 'Escritorios y sillas' },
    ['Tecnología'] = { 'oficina', 'Ordenadores y oficina', abierta = true },
    ['Cámaras de seguridad'] = { 'oficina', 'Seguridad' },
    ['Luces'] = { 'luz', 'Lámparas', afinar = true },
    ['Puntos de luz'] = { 'luz', 'Interruptores y puntos de luz' },
    ['Carteles de neón'] = { 'luz', 'Neones', abierta = true },
    ['Almacenaje'] = { 'almacen', 'Almacenajes' },
    ['Armeros'] = { 'almacen', 'Armeros' },
    ['Arte'] = { 'deco', 'Cuadros y arte' },
    ['Cuadros personalizados'] = { 'deco', 'Cuadros y arte' },
    ['Esculturas y premios'] = { 'deco', 'Esculturas y trofeos' },
    ['Trofeos'] = { 'deco', 'Esculturas y trofeos' },
    ['Plantas'] = { 'deco', 'Plantas', abierta = true },
    ['Alfombras'] = { 'deco', 'Alfombras' },
    ['Libros y velas'] = { 'deco', 'Libros, velas y relojes', afinar = true },
    ['Joyas'] = { 'deco', 'Joyas' },
    ['Decoración'] = { 'deco', 'Objetos', abierta = true },
    ['Puertas'] = { 'puertas', 'Puertas', afinar = true },
    ['Jardín y patio'] = { 'jardin', 'Jardinería', finos = {
        { 'bbq', 'Barbacoas y fuego' }, { 'heater', 'Barbacoas y fuego' }, { 'firepit', 'Barbacoas y fuego' },
        { 'parasol', 'Sombrillas y cenadores' }, { 'para_comb', 'Sombrillas y cenadores' }, { 'gazebo', 'Sombrillas y cenadores' },
        { 'lounger', 'Tumbonas, bancos y sillas' }, { 'bench', 'Tumbonas, bancos y sillas' }, { 'chair', 'Tumbonas, bancos y sillas' },
        { 'picnic', 'Tumbonas, bancos y sillas' }, { 'towel', 'Tumbonas, bancos y sillas' },
    } },
    ['Gimnasio'] = { 'ocio', 'Gimnasio' },
    ['Juegos y juguetes'] = { 'ocio', 'Recreativas y juegos', afinar = true },
    ['Música / DJ'] = { 'ocio', 'Música y DJ' },
    ['Instrumentos'] = { 'ocio', 'Instrumentos' },
    ['Mascotas'] = { 'ocio', 'Mascotas' },
    -- (los muebles de taller del Pack Crews —cono, gato, compresor, banco…— comparten categoría con los
    -- elevadores y las plataformas giratorias: en la cinta van a su propio subgrupo)
    ['Taller y exposición'] = { 'taller', 'Elevadores y plataformas', finos = { { 'origen_casa_crw_', 'Taller' } } },
    ['Guarida'] = { 'sotano', 'Guarida' },
    ['Ventanas y cortinas'] = { 'deco', 'Ventanas, cortinas y persianas' },
    ['Sótano'] = { 'sotano', 'Mobiliario y trastos' },
    ['Sótano: celda y herramientas'] = { 'sotano', 'Celda y herramientas' },
    ['Secretos'] = { 'secretos', 'Gatillos y escondites' },
    ['Paredes'] = { 'varios', 'Muros y jardineras' },
    ['Varios'] = { 'varios', 'Varios' },
}

-- Para las categorías que no están en la lista de arriba (las que traigan los
-- packs): el primer trozo que aparezca en su etiqueta —en minúsculas y sin
-- acentos— dice el grupo. El subgrupo es la propia etiqueta, salvo que la regla
-- traiga uno. Si no acierta ninguna: «Varios», con la etiqueta de subgrupo.
T.reglas = {
    { 'secret', 'secretos' }, { 'ocult', 'secretos' }, { 'gatillo', 'secretos' },
    { 'sotano', 'sotano' }, { 'celda', 'sotano' }, { 'mazmorra', 'sotano' }, { 'laboratorio', 'sotano' }, { 'guarida', 'sotano' }, { 'bunker', 'sotano' },
    { 'taller', 'taller' }, { 'garaje', 'taller' }, { 'mecanic', 'taller' }, { 'herramienta', 'taller', 'Herramientas' }, { 'coche', 'taller' }, { 'exposicion', 'taller' },
    { 'porton', 'puertas', 'Portones de garaje' }, { 'puerta', 'puertas' }, { 'reja', 'puertas', 'Rejas y verjas' }, { 'verja', 'puertas', 'Rejas y verjas' },
    { 'neon', 'luz', 'Neones' }, { 'luz', 'luz' }, { 'luces', 'luz' }, { 'lampara', 'luz' }, { 'ilumina', 'luz' }, { 'foco', 'luz', 'Focos' },
    { 'lavand', 'bano', 'Lavandería y limpieza' }, { 'limpieza', 'bano', 'Lavandería y limpieza' }, { 'bano', 'bano' }, { 'aseo', 'bano' }, { 'ducha', 'bano' }, { 'spa', 'bano' },
    { 'nevera', 'cocina', 'Neveras' }, { 'frigor', 'cocina', 'Neveras' }, { 'electrodom', 'cocina', 'Cocina y electrodomésticos' }, { 'cocina', 'cocina' },
    { 'comedor', 'cocina' }, { 'comida', 'cocina', 'Comida' }, { 'bebida', 'cocina', 'Bebidas' }, { 'menaje', 'cocina', 'Menaje' }, { 'vajilla', 'cocina', 'Menaje' }, { 'bodega', 'cocina' },
    { 'cama', 'dormitorio', 'Camas' }, { 'dormitorio', 'dormitorio' }, { 'armario', 'dormitorio', 'Armarios' }, { 'ropero', 'dormitorio', 'Armarios' },
    { 'vestidor', 'dormitorio', 'Armarios' }, { 'mesilla', 'dormitorio', 'Mesillas y cómodas' }, { 'comoda', 'dormitorio', 'Mesillas y cómodas' }, { 'infantil', 'dormitorio' },
    { 'seguridad', 'oficina', 'Seguridad' }, { 'camara', 'oficina', 'Seguridad' }, { 'televis', 'oficina', 'Televisores' }, { 'pantalla', 'oficina', 'Televisores' },
    { 'oficina', 'oficina' }, { 'despacho', 'oficina' }, { 'escritorio', 'oficina', 'Escritorios y sillas' }, { 'tecnolog', 'oficina' }, { 'ordenador', 'oficina' }, { 'informatic', 'oficina' },
    { 'armero', 'almacen', 'Armeros' }, { 'armeria', 'almacen', 'Armeros' }, { 'almacen', 'almacen' }, { 'caja fuerte', 'almacen' }, { 'taquilla', 'almacen' }, { 'estanter', 'almacen' }, { 'baul', 'almacen' },
    { 'jardin', 'jardin' }, { 'patio', 'jardin' }, { 'exterior', 'jardin' }, { 'terraza', 'jardin' }, { 'piscina', 'jardin' }, { 'barbacoa', 'jardin', 'Barbacoas y fuego' }, { 'playa', 'jardin' },
    { 'gimnasio', 'ocio', 'Gimnasio' }, { 'deporte', 'ocio', 'Gimnasio' }, { 'recreativ', 'ocio', 'Recreativas y juegos' }, { 'arcade', 'ocio', 'Recreativas y juegos' },
    { 'juego', 'ocio' }, { 'juguete', 'ocio' }, { 'casino', 'ocio' }, { 'ocio', 'ocio' }, { 'instrument', 'ocio', 'Instrumentos' }, { 'musica', 'ocio', 'Música y DJ' }, { 'mascota', 'ocio', 'Mascotas' }, { 'fiesta', 'ocio' },
    { 'cuadro', 'deco', 'Cuadros y arte' }, { 'arte', 'deco', 'Cuadros y arte' }, { 'escultura', 'deco', 'Esculturas y trofeos' }, { 'trofeo', 'deco', 'Esculturas y trofeos' },
    { 'planta', 'deco', 'Plantas' }, { 'alfombra', 'deco', 'Alfombras' }, { 'cortina', 'deco', 'Ventanas, cortinas y persianas' }, { 'persiana', 'deco', 'Ventanas, cortinas y persianas' },
    { 'libro', 'deco', 'Libros, velas y relojes' }, { 'vela', 'deco', 'Libros, velas y relojes' }, { 'reloj', 'deco', 'Libros, velas y relojes' }, { 'espejo', 'deco' },
    { 'navidad', 'deco' }, { 'halloween', 'deco' }, { 'decora', 'deco' }, { 'adorno', 'deco' }, { 'joya', 'deco', 'Joyas' },
    { 'sofa', 'salon', 'Sofás y sillones' }, { 'sillon', 'salon', 'Sofás y sillones' }, { 'salon', 'salon' }, { 'chimenea', 'salon' }, { 'mesa', 'cocina', 'Mesas y sillas' }, { 'silla', 'cocina', 'Mesas y sillas' },
    { 'mueble', 'salon' },
}

-- ── Los nombres ─────────────────────────────────────────────────────────
-- Nombre de los muebles propios que el catálogo aún trae sin él (el modelo entero).
T.nombres = {
    origen_casa_luz_interruptor = 'Interruptor', origen_casa_luz_interruptor_ind = 'Interruptor industrial',
    origen_casa_luz_downlight = 'Foco empotrado', origen_casa_luz_plafon = 'Plafón', origen_casa_luz_fluorescente = 'Fluorescente',
    origen_casa_luz_colgante = 'Lámpara colgante', origen_casa_luz_arana = 'Lámpara de araña', origen_casa_luz_industrial = 'Campana industrial',
    origen_casa_luz_bombilla = 'Bombilla desnuda', origen_casa_luz_panel_led = 'Panel LED', origen_casa_luz_aplique = 'Aplique',
    origen_casa_luz_aplique_moderno = 'Aplique moderno', origen_casa_luz_foco_pared = 'Foco de pared', origen_casa_luz_pie = 'Lámpara de pie',
    origen_casa_luz_mesa = 'Lámpara de mesa', origen_casa_luz_foco_obra = 'Foco de obra', origen_casa_luz_neon_rosa = 'Neón rosa',
    origen_casa_luz_neon_azul = 'Neón azul', origen_casa_luz_neon_verde = 'Neón verde', origen_casa_luz_neon_rojo = 'Neón rojo',
    origen_casa_luz_neon_morado = 'Neón morado', origen_casa_luz_tira_calida = 'Tira de luz cálida',
    origen_casa_elevador = 'Elevador de taller', origen_casa_elevador_poste = 'Elevador de un poste', origen_casa_elevador_2postes = 'Elevador de dos postes',
    origen_casa_elevador_tijera = 'Elevador de tijera', origen_casa_elevador_4col = 'Elevador de cuatro columnas',
    origen_casa_giratoria_s = 'Plataforma giratoria pequeña', origen_casa_giratoria_m = 'Plataforma giratoria mediana', origen_casa_giratoria_l = 'Plataforma giratoria grande',
    origen_casa_gatillo_libro = 'Gatillo: libro', origen_casa_gatillo_interruptor = 'Gatillo: interruptor', origen_casa_gatillo_palanca = 'Gatillo: palanca',
    origen_casa_gatillo_candelabro = 'Gatillo: candelabro', origen_casa_gatillo_cuadro = 'Gatillo: cuadro', origen_casa_caja_cuadro = 'Caja fuerte tras un cuadro',
    origen_casa_porton_galva = 'Portón galvanizado', origen_casa_porton_blanca = 'Portón blanco', origen_casa_porton_antracita = 'Portón antracita',
    origen_casa_porton_ventanas = 'Portón con ventanas', origen_casa_porton_madera = 'Portón de madera', origen_casa_porton_roja = 'Portón rojo',
    origen_casa_porton_banda = 'Portón con banda', origen_casa_porton_verde = 'Portón verde',
    jge_light_01 = 'Punto de luz', jge_light_02 = 'Punto de luz de color',
}

-- El diccionario: { 'trozo del modelo', 'Nombre', grupo, 'Subgrupo' }. Vale el
-- PRIMERO que aparezca en el nombre del modelo, así que lo concreto va antes
-- que lo general ('sofabed' antes que 'sofa', 'sofa' antes que 'bed').
-- El grupo y el subgrupo son opcionales: mandan si la categoría del mueble es
-- «abierta», o (solo el subgrupo) si ya era de ese mismo grupo.
-- Si dos muebles acaban con el mismo nombre se numeran solos: «Sillón 1», «Sillón 2»…
T.diccionario = {
    -- los que otro trozo más corto se llevaría por delante
    { 'trophy', 'Trofeo', 'deco', 'Esculturas y trofeos' }, { 'headphones', 'Auriculares', 'ocio', 'Música y DJ' }, { 'microphone', 'Micrófono', 'ocio', 'Música y DJ' },
    { 'ashtray', 'Cenicero' }, { 'cctv_cam', 'Cámara de seguridad', 'oficina', 'Seguridad' }, { 'cctv', 'Equipo de vigilancia', 'oficina', 'Seguridad' },
    { 'basketball_net', 'Canasta', 'ocio', 'Recreativas y juegos' }, { 'basketball', 'Balón de baloncesto', 'ocio', 'Recreativas y juegos' },
    { 'chip_carrier', 'Bandeja de fichas', 'ocio', 'Recreativas y juegos' }, { 'binder', 'Archivador' }, { 'binoculars', 'Prismáticos' },
    -- sofás y asientos
    { 'sofacorn', 'Sofá rinconera', 'salon', 'Sofás y sillones' }, { 'sofa_daybed', 'Diván', 'salon', 'Sofás y sillones' },
    { 'sofa2seat', 'Sofá de dos plazas', 'salon', 'Sofás y sillones' }, { 'sofa3seat', 'Sofá de tres plazas', 'salon', 'Sofás y sillones' },
    { 'sofabed', 'Sofá cama', 'salon', 'Sofás y sillones' }, { 'sofa', 'Sofá', 'salon', 'Sofás y sillones' },
    { 'chairarm', 'Sillón', 'salon', 'Sofás y sillones' }, { 'armchair', 'Sillón', 'salon', 'Sofás y sillones' },
    { 'easychair', 'Butaca', 'salon', 'Sofás y sillones' }, { 'chairstrip', 'Butaca de rayas', 'salon', 'Sofás y sillones' },
    { 'strip_chair', 'Butaca de rayas', 'salon', 'Sofás y sillones' }, { 'barcchair', 'Sillón de diseño', 'salon', 'Sofás y sillones' },
    { 'singleseat', 'Sillón individual', 'salon', 'Sofás y sillones' }, { 'chairstool', 'Reposapiés', 'salon', 'Sofás y sillones' },
    { 'foot_stool', 'Reposapiés', 'salon', 'Sofás y sillones' }, { 'pouf', 'Puf', 'salon', 'Sofás y sillones' },
    { 'benchshort', 'Banco corto', 'salon', 'Sofás y sillones' },
    { 'weight_bench', 'Banco de pesas', 'ocio', 'Gimnasio' }, { 'muscle_bench', 'Banco de musculación', 'ocio', 'Gimnasio' },
    { 'tool_bench', 'Banco de trabajo', 'taller', 'Herramientas' }, { 'bench_piano', 'Banqueta de piano', 'ocio', 'Instrumentos' },
    { 'benchset', 'Mesa con bancos' }, { 'lounger', 'Tumbona', 'jardin', 'Tumbonas, bancos y sillas' },
    { 'deck_chair', 'Hamaca', 'jardin', 'Tumbonas, bancos y sillas' }, { 'rock_chair', 'Mecedora' }, { 'folding_chair', 'Silla plegable' },
    { 'direct_chair', 'Silla de director' }, { 'wheelchair', 'Silla de ruedas' }, { 'torture_ch', 'Silla de interrogatorio' },
    { 'off_chair', 'Silla de oficina', 'oficina', 'Escritorios y sillas' }, { 'offchair', 'Silla de oficina', 'oficina', 'Escritorios y sillas' },
    { 'office_chair', 'Silla de oficina', 'oficina', 'Escritorios y sillas' }, { 'deskchair', 'Silla de escritorio', 'oficina', 'Escritorios y sillas' },
    { 'din_chair', 'Silla de comedor', 'cocina', 'Mesas y sillas' }, { 'dinechair', 'Silla de comedor', 'cocina', 'Mesas y sillas' },
    { 'dineeames', 'Silla de diseño', 'cocina', 'Mesas y sillas' }, { 'barstool', 'Taburete de bar', 'cocina', 'Mesas y sillas' },
    { 'din_stool', 'Taburete de comedor', 'cocina', 'Mesas y sillas' }, { 'kitnstool', 'Taburete de cocina', 'cocina', 'Mesas y sillas' },
    { 'lngestool', 'Taburete bajo' },
    -- mesas
    { 'pooltable', 'Mesa de billar', 'ocio', 'Recreativas y juegos' }, { 'pool_rack', 'Taquera de billar', 'ocio', 'Recreativas y juegos' },
    { 'pool_cue', 'Taco de billar', 'ocio', 'Recreativas y juegos' }, { 'pool_tri', 'Triángulo de billar', 'ocio', 'Recreativas y juegos' },
    { 'table_tennis', 'Mesa de ping-pong', 'ocio', 'Recreativas y juegos' }, { 'blackjack', 'Mesa de blackjack', 'ocio', 'Recreativas y juegos' },
    { 'roulette', 'Mesa de ruleta', 'ocio', 'Recreativas y juegos' }, { 'table_casino', 'Mesa de casino', 'ocio', 'Recreativas y juegos' },
    { 'picnictable', 'Mesa de pícnic', 'jardin', 'Tumbonas, bancos y sillas' }, { 'table_para_comb', 'Mesa con sombrilla', 'jardin', 'Sombrillas y cenadores' },
    { 'lounger1_table', 'Mesita de tumbona' },
    { 'din_table', 'Mesa de comedor', 'cocina', 'Mesas y sillas' }, { 'diningtable', 'Mesa de comedor', 'cocina', 'Mesas y sillas' },
    { 'dinetble', 'Mesa de comedor', 'cocina', 'Mesas y sillas' },
    { 'tab_coffee', 'Mesa de centro', 'salon', 'Mesas de centro y auxiliares' }, { 'coffee_table', 'Mesa de centro', 'salon', 'Mesas de centro y auxiliares' },
    { 'coffe_table', 'Mesa de centro', 'salon', 'Mesas de centro y auxiliares' }, { 'coffeetable', 'Mesa de centro', 'salon', 'Mesas de centro y auxiliares' },
    { 'coftable', 'Mesa de centro', 'salon', 'Mesas de centro y auxiliares' }, { 'coftbl', 'Mesa de centro con vitrina', 'salon', 'Mesas de centro y auxiliares' },
    { 'lowtable', 'Mesa baja', 'salon', 'Mesas de centro y auxiliares' }, { 'tab_sidelrg', 'Mesa auxiliar', 'salon', 'Mesas de centro y auxiliares' },
    { 'side_table', 'Mesa auxiliar', 'salon', 'Mesas de centro y auxiliares' }, { 'sidetbl', 'Mesa auxiliar', 'salon', 'Mesas de centro y auxiliares' },
    { 'console_table', 'Consola', 'salon', 'Aparadores y consolas' }, { 'mconsole', 'Consola', 'salon', 'Aparadores y consolas' },
    { 'm_console', 'Consola', 'salon', 'Aparadores y consolas' }, { 'm_h_console', 'Consola', 'salon', 'Aparadores y consolas' },
    { 'hosptable', 'Mesa de hospital' }, { 'tablesaw', 'Sierra de mesa', 'taller', 'Herramientas' }, { 'table_mic', 'Micrófono de mesa', 'oficina', 'Ordenadores y oficina' },
    { 'bed_table', 'Mesilla de noche', 'dormitorio', 'Mesillas y cómodas' }, { 'bed_with_table', 'Cama con mesillas', 'dormitorio', 'Camas' },
    -- lámparas (antes que «table» y «lamp»)
    { 'floorlampnight', 'Lámpara de pie de noche', 'luz', 'De pie' }, { 'floorlamp', 'Lámpara de pie', 'luz', 'De pie' }, { 'floor_lamp', 'Lámpara de pie', 'luz', 'De pie' },
    { 'lampstand', 'Lámpara de pie', 'luz', 'De pie' }, { 'tripod_lamp', 'Lámpara de trípode', 'luz', 'De pie' },
    { 'lamptablenight', 'Lámpara de mesilla', 'luz', 'De mesa' }, { 'lamptable', 'Lámpara de mesa', 'luz', 'De mesa' }, { 'table_lamp', 'Lámpara de mesa', 'luz', 'De mesa' },
    { 'tablelamp', 'Lámpara de mesa', 'luz', 'De mesa' }, { 'lamptbl', 'Lámpara de mesa', 'luz', 'De mesa' },
    { 'lightpendant', 'Lámpara colgante', 'luz', 'De techo' }, { 'tube_lamp', 'Tubos de luz', 'luz', 'Focos' },
    { 'worklight', 'Foco de obra', 'luz', 'Focos' }, { 'studio_light', 'Foco de estudio', 'luz', 'Focos' }, { 'kino_light', 'Foco de cine', 'luz', 'Focos' },
    { 'luz_neon', 'Neón', 'luz', 'Neones' }, { 'luz_tira', 'Tira de luz', 'luz', 'Neones' }, { 'luz_interruptor', 'Interruptor', 'luz', 'Interruptores y puntos de luz' },
    { 'luz_aplique', 'Aplique', 'luz', 'De pared' }, { 'luz_foco_pared', 'Foco de pared', 'luz', 'De pared' }, { 'luz_foco_obra', 'Foco de obra', 'luz', 'Focos' },
    { 'luz_pie', 'Lámpara de pie', 'luz', 'De pie' }, { 'luz_mesa', 'Lámpara de mesa', 'luz', 'De mesa' }, { 'casa_luz_', 'Lámpara de techo', 'luz', 'De techo' },
    { 'beer_neon', 'Neón de cerveza', 'luz', 'Neones' }, { 'neon', 'Cartel de neón', 'luz', 'Neones' }, { 'prop_sign_', 'Cartel luminoso', 'luz', 'Neones' },
    { 'art_lamp', 'Lámpara de diseño', 'luz', 'Lámparas' }, { 'moden_lamp', 'Lámpara moderna', 'luz', 'Lámparas' },
    { 'fa_lamp', 'Lámpara', 'luz', 'Lámparas' }, { 'lampa_', 'Lámpara', 'luz', 'Lámparas' }, { 'vw_lamp', 'Lámpara', 'luz', 'Lámparas' },
    -- muebles de guardar y de tele
    { 'tv_cabinet', 'Mueble de tele', 'salon', 'Muebles de tele' }, { 'avunit', 'Mueble de tele', 'salon', 'Muebles de tele' },
    { 'tvstand', 'Mueble de tele', 'salon', 'Muebles de tele' }, { 'tv_stand', 'Mueble de tele', 'salon', 'Muebles de tele' },
    { 'sideboard', 'Aparador', 'salon', 'Aparadores y consolas' }, { 'sidebrd', 'Aparador', 'salon', 'Aparadores y consolas' },
    { 'chestdrawer', 'Cómoda', 'dormitorio', 'Mesillas y cómodas' }, { 'ddresser', 'Tocador', 'dormitorio', 'Mesillas y cómodas' },
    { 'armoire', 'Armario', 'dormitorio', 'Armarios' }, { 'cupboard', 'Alacena', 'salon', 'Aparadores y consolas' },
    { 'dart_bd_cab', 'Diana con armario', 'ocio', 'Recreativas y juegos' }, { 'cabinet', 'Vitrina', 'salon', 'Aparadores y consolas' },
    { 'laundry_shelving', 'Estantería de lavandería' }, { 'towel_shelf', 'Estante de toallas' }, { 'shelving', 'Estantería' },
    -- camas
    { 'campbed', 'Catre', 'dormitorio', 'Camas' }, { 'bed_dog', 'Cama de perro', 'ocio', 'Mascotas' }, { 'bedsideclock', 'Despertador', 'deco', 'Libros, velas y relojes' },
    { 'bedsidebook', 'Libro de mesilla', 'deco', 'Libros, velas y relojes' }, { 'bed_double', 'Cama de matrimonio', 'dormitorio', 'Camas' },
    { 'bed_wide', 'Cama ancha', 'dormitorio', 'Camas' }, { 'messy', 'Cama deshecha', 'dormitorio', 'Camas' }, { 'matress', 'Colchón' }, { 'sleepbag', 'Saco de dormir' },
    -- cocina
    { 'fridge_door', 'Puerta de cámara frigorífica' }, { 'beerfridge', 'Nevera de cervezas', 'cocina', 'Neveras' }, { 'bar_fridge', 'Nevera de bar', 'cocina', 'Neveras' },
    { 'minifridge', 'Mininevera', 'cocina', 'Neveras' }, { 'desk_fridge', 'Nevera de despacho', 'cocina', 'Neveras' }, { 'vend_fridge', 'Nevera expositora', 'cocina', 'Neveras' },
    { 'fridge', 'Frigorífico', 'cocina', 'Neveras' }, { 'cooker', 'Cocina de gas', 'cocina', 'Cocina y electrodomésticos' },
    { 'griddle', 'Plancha de cocina', 'cocina', 'Cocina y electrodomésticos' }, { 'microwave', 'Microondas', 'cocina', 'Cocina y electrodomésticos' },
    { 'prop_micro_', 'Microondas', 'cocina', 'Cocina y electrodomésticos' }, { 'toaster', 'Tostadora', 'cocina', 'Cocina y electrodomésticos' },
    { 'kettle', 'Hervidor', 'cocina', 'Cocina y electrodomésticos' }, { 'coffeemachine', 'Cafetera', 'cocina', 'Cocina y electrodomésticos' },
    { 'coffee_mac', 'Cafetera', 'cocina', 'Cocina y electrodomésticos' }, { 'coffpot', 'Cafetera italiana', 'cocina', 'Menaje' },
    { 'juicer', 'Exprimidor', 'cocina', 'Cocina y electrodomésticos' }, { 'juice_dispenser', 'Dispensador de zumo', 'cocina', 'Cocina y electrodomésticos' },
    { 'foodprocess', 'Robot de cocina', 'cocina', 'Cocina y electrodomésticos' }, { 'plate_warmer', 'Calientaplatos', 'cocina', 'Cocina y electrodomésticos' },
    { 'watercooler', 'Dispensador de agua', 'oficina', 'Ordenadores y oficina' }, { 'bs_soda', 'Máquina de refrescos', 'cocina', 'Cocina y electrodomésticos' },
    { 'sink', 'Fregadero', 'cocina', 'Cocina y electrodomésticos' }, { 'kniferack', 'Barra de cuchillos', 'cocina', 'Menaje' }, { 'knifeblock', 'Taco de cuchillos', 'cocina', 'Menaje' },
    { 'utensil', 'Utensilios de cocina', 'cocina', 'Menaje' }, { 'breadbin', 'Panera', 'cocina', 'Menaje' }, { 'bread_rack', 'Estante de pan', 'cocina', 'Menaje' },
    { 'plate_wall', 'Plato de pared', 'deco', 'Jarrones y adornos' }, { 'dec_plate', 'Plato decorativo', 'deco', 'Jarrones y adornos' },
    { 'plate_stand', 'Soporte de platos', 'cocina', 'Menaje' }, { 'plate_sweets', 'Plato de dulces', 'cocina', 'Comida' }, { 'tableplace', 'Servicio de mesa', 'cocina', 'Menaje' },
    { 'plate', 'Plato', 'cocina', 'Menaje' }, { 'saucer', 'Platillo', 'cocina', 'Menaje' }, { 'prop_mug', 'Taza', 'cocina', 'Menaje' },
    { 'bowlpile', 'Pila de cuencos', 'cocina', 'Menaje' }, { 'fruitbowl', 'Frutero', 'cocina', 'Comida' }, { 'bowl_fruit', 'Frutero', 'cocina', 'Comida' },
    { 'fruit_basket', 'Cesta de fruta', 'cocina', 'Comida' }, { 'peanut_bowl', 'Cuenco de cacahuetes', 'cocina', 'Comida' }, { 'bowl_crisps', 'Cuenco de patatas', 'cocina', 'Comida' },
    { 'sugarbowl', 'Azucarero', 'cocina', 'Menaje' }, { 'bowl', 'Cuenco', 'cocina', 'Menaje' },
    { 'kitch_pot_fry', 'Sartén', 'cocina', 'Menaje' }, { 'kitch_pot', 'Olla', 'cocina', 'Menaje' }, { 'copper_pan', 'Sartén de cobre', 'cocina', 'Menaje' },
    { 'pot_rack', 'Colgador de ollas', 'cocina', 'Menaje' }, { 'metalfoodjar', 'Bote de cocina', 'cocina', 'Menaje' }, { 'milkjug', 'Jarra de leche', 'cocina', 'Menaje' },
    { 'silvrtray', 'Bandeja de plata', 'cocina', 'Menaje' }, { 'drink_tray', 'Bandeja de bebidas', 'cocina', 'Bebidas' }, { 'champ_tray', 'Bandeja de champán', 'cocina', 'Bebidas' },
    { 'inout_tray', 'Bandeja de documentos', 'oficina', 'Ordenadores y oficina' }, { 'disptray', 'Bandeja de joyas' }, { 'tray', 'Bandeja', 'cocina', 'Comida' },
    { 'kscales', 'Báscula de cocina', 'cocina', 'Menaje' },
    -- comida y bebida
    { 'burg', 'Hamburguesa', 'cocina', 'Comida' }, { 'hotdog', 'Perrito caliente', 'cocina', 'Comida' }, { 'donut', 'Dónut', 'cocina', 'Comida' },
    { 'pizza', 'Caja de pizza', 'cocina', 'Comida' }, { 'noodle', 'Fideos', 'cocina', 'Comida' }, { 'taco', 'Taco', 'cocina', 'Comida' },
    { 'sandwich', 'Sándwich', 'cocina', 'Comida' }, { 'nugets', 'Nuggets', 'cocina', 'Comida' }, { 'chips', 'Patatas fritas', 'cocina', 'Comida' },
    { 'crisps', 'Bolsa de patatas', 'cocina', 'Comida' }, { 'snack', 'Aperitivo', 'cocina', 'Comida' }, { 'choc_', 'Chocolatina', 'cocina', 'Comida' },
    { 'candy', 'Caramelos', 'cocina', 'Comida' }, { 'sweet', 'Dulces', 'cocina', 'Comida' }, { 'ketchup', 'Kétchup', 'cocina', 'Comida' },
    { 'mustard', 'Mostaza', 'cocina', 'Comida' }, { 'sugarjar', 'Azucarero', 'cocina', 'Comida' }, { 'napkin', 'Servilletas', 'cocina', 'Comida' },
    { 'pineapple', 'Piña', 'cocina', 'Comida' }, { 'apple', 'Manzanas', 'cocina', 'Comida' }, { 'bar_fruit', 'Fruta cortada', 'cocina', 'Comida' },
    { 'fruit_plas', 'Caja de fruta', 'cocina', 'Comida' }, { 'bread', 'Pan', 'cocina', 'Comida' }, { 'choptom', 'Tomate en lata', 'cocina', 'Comida' },
    { 'tincorn', 'Lata de maíz', 'cocina', 'Comida' }, { 'tintomsoup', 'Lata de sopa', 'cocina', 'Comida' }, { 'potnoodle', 'Fideos instantáneos', 'cocina', 'Comida' },
    { 'food_bs_bag', 'Bolsa de comida', 'cocina', 'Comida' }, { 'food_bag', 'Bolsa de comida', 'cocina', 'Comida' }, { 'fork', 'Tenedor', 'cocina', 'Menaje' },
    { 'champ_flute', 'Copa de champán', 'cocina', 'Bebidas' }, { 'champset', 'Juego de champán', 'cocina', 'Bebidas' }, { 'champ_cool', 'Champán en cubitera', 'cocina', 'Bebidas' },
    { 'champ_box', 'Caja de champán', 'cocina', 'Bebidas' }, { 'champ', 'Botella de champán', 'cocina', 'Bebidas' }, { 'wine_glass', 'Copa de vino', 'cocina', 'Bebidas' },
    { 'redwine', 'Copa de tinto', 'cocina', 'Bebidas' }, { 'whtwine', 'Copa de blanco', 'cocina', 'Bebidas' }, { 'wine', 'Botella de vino', 'cocina', 'Bebidas' },
    { 'drink_whisky', 'Vaso de whisky', 'cocina', 'Bebidas' }, { 'whisk', 'Botella de whisky', 'cocina', 'Bebidas' }, { 'brandy', 'Botella de brandy', 'cocina', 'Bebidas' },
    { 'cognac', 'Botella de coñac', 'cocina', 'Bebidas' }, { 'tequila', 'Botella de tequila', 'cocina', 'Bebidas' }, { 'vodka', 'Botella de vodka', 'cocina', 'Bebidas' },
    { 'rum_bottle', 'Botella de ron', 'cocina', 'Bebidas' }, { 'tonic', 'Botella de tónica', 'cocina', 'Bebidas' }, { 'water_bottle', 'Botella de agua', 'cocina', 'Bebidas' },
    { 'bottle_opener', 'Abrebotellas', 'cocina', 'Menaje' }, { 'bottle_holder', 'Botellero', 'cocina', 'Bebidas' }, { 'weed_bottle', 'Bote de marihuana' },
    { 'crate_beer', 'Caja de cervezas', 'cocina', 'Bebidas' }, { 'beer_box', 'Caja de cervezas', 'cocina', 'Bebidas' }, { 'beer', 'Cerveza', 'cocina', 'Bebidas' },
    { 'ice_bucket', 'Cubitera', 'cocina', 'Bebidas' }, { 'energy_drink', 'Bebida energética', 'cocina', 'Bebidas' }, { '_can_', 'Lata de refresco', 'cocina', 'Bebidas' },
    { 'milk', 'Leche', 'cocina', 'Bebidas' }, { 'juice', 'Zumo', 'cocina', 'Bebidas' }, { 'coffee', 'Café', 'cocina', 'Bebidas' }, { 'paper_cup', 'Vaso de papel', 'cocina', 'Bebidas' },
    { 'drinkstraws', 'Pajitas', 'cocina', 'Bebidas' }, { 'glass_stack', 'Pila de vasos', 'cocina', 'Menaje' }, { 'bottle', 'Botella', 'cocina', 'Bebidas' },
    -- baño, lavandería y limpieza
    { 'bathpot', 'Bote de sales', 'bano', 'Toallas y aseo' }, { 'bublbath', 'Gel de baño', 'bano', 'Toallas y aseo' }, { 'bathtub', 'Bañera', 'bano', 'Sanitarios' },
    { 'mbath', 'Bañera', 'bano', 'Sanitarios' }, { 'hottub', 'Jacuzzi', 'jardin', 'Jardinería' }, { 'toilet_roll', 'Papel higiénico', 'bano', 'Toallas y aseo' },
    { 'looroll', 'Papel higiénico', 'bano', 'Toallas y aseo' }, { 'toilet_brush', 'Escobilla', 'bano', 'Toallas y aseo' }, { 'toilet_soap', 'Jabón', 'bano', 'Toallas y aseo' },
    { 'soap_disp', 'Dispensador de jabón', 'bano', 'Toallas y aseo' }, { 'soappowder', 'Detergente', 'bano', 'Lavandería y limpieza' }, { 'shamp', 'Champú', 'bano', 'Toallas y aseo' },
    { 'toiletbag', 'Neceser', 'bano', 'Toallas y aseo' }, { 'toiletry', 'Artículos de aseo', 'bano', 'Toallas y aseo' }, { 'toilet', 'Inodoro', 'bano', 'Sanitarios' },
    { 'showerdoor', 'Mampara de ducha', 'bano', 'Sanitarios' }, { 'shower_rack', 'Estante de ducha', 'bano', 'Sanitarios' }, { 'w_fountain', 'Fuente de agua', 'bano', 'Sanitarios' },
    { 'towel_rail', 'Toallero', 'bano', 'Toallas y aseo' }, { 'beach_towel', 'Toalla de playa', 'jardin', 'Tumbonas, bancos y sillas' }, { 'towel', 'Toalla', 'bano', 'Toallas y aseo' },
    { 'toothb', 'Cepillo de dientes', 'bano', 'Toallas y aseo' }, { 'toothpaste', 'Pasta de dientes', 'bano', 'Toallas y aseo' }, { 'hairdryer', 'Secador', 'bano', 'Toallas y aseo' },
    { 'aftershave', 'Loción de afeitar', 'bano', 'Toallas y aseo' }, { 'razor', 'Maquinilla', 'bano', 'Toallas y aseo' }, { 'shvbrush', 'Brocha de afeitar', 'bano', 'Toallas y aseo' },
    { 'bs_scissors', 'Tijeras', 'bano', 'Toallas y aseo' }, { 'bs_spray', 'Pulverizador', 'bano', 'Toallas y aseo' }, { 'lipstick', 'Pintalabios', 'bano', 'Toallas y aseo' },
    { 'mirror', 'Espejo', 'bano', 'Sanitarios' },
    { 'laundry_machine', 'Lavadora', 'bano', 'Lavandería y limpieza' }, { 'laundry_trolley', 'Carro de lavandería', 'bano', 'Lavandería y limpieza' },
    { 'dryer', 'Secadora', 'bano', 'Lavandería y limpieza' }, { 'mlaundry', 'Cesto de ropa', 'bano', 'Lavandería y limpieza' }, { 'basket', 'Cesto', 'bano', 'Lavandería y limpieza' },
    { 'ironbrd', 'Tabla de planchar', 'bano', 'Lavandería y limpieza' }, { 'ironing', 'Tabla de planchar', 'bano', 'Lavandería y limpieza' }, { 'prop_iron_', 'Plancha', 'bano', 'Lavandería y limpieza' },
    { 'vacuum', 'Aspiradora', 'bano', 'Lavandería y limpieza' }, { 'mopbucket', 'Cubo de fregar', 'bano', 'Lavandería y limpieza' }, { 'bktmop', 'Cubo y fregona', 'bano', 'Lavandería y limpieza' },
    { '_mop', 'Fregona', 'bano', 'Lavandería y limpieza' }, { 'duster', 'Mopa', 'bano', 'Lavandería y limpieza' }, { 'detergent', 'Detergente', 'bano', 'Lavandería y limpieza' },
    { 'rasberryclean', 'Limpiador', 'bano', 'Lavandería y limpieza' }, { 'recyclebin', 'Cubo de reciclaje', 'bano', 'Lavandería y limpieza' }, { 'binbag', 'Bolsa de basura' },
    { '_bin', 'Papelera', 'bano', 'Lavandería y limpieza' }, { 'ice_bucket', 'Cubitera' }, { 'bucket', 'Cubo', 'bano', 'Lavandería y limpieza' },
    -- tecnología
    { 'monitorstand', 'Soporte de monitor', 'oficina', 'Ordenadores y oficina' }, { 'monitor', 'Monitor', 'oficina', 'Ordenadores y oficina' },
    { 'laptop', 'Portátil', 'oficina', 'Ordenadores y oficina' }, { 'lap_top', 'Portátil', 'oficina', 'Ordenadores y oficina' }, { 'keyboard', 'Teclado', 'oficina', 'Ordenadores y oficina' },
    { 'dyn_pc', 'Ordenador', 'oficina', 'Ordenadores y oficina' }, { 'heist_pc', 'Ordenador', 'oficina', 'Ordenadores y oficina' }, { 'computer', 'Ordenador', 'oficina', 'Ordenadores y oficina' },
    { 'club_screen', 'Pantalla', 'oficina', 'Televisores' }, { 'server', 'Servidor', 'oficina', 'Ordenadores y oficina' }, { 'printer', 'Impresora', 'oficina', 'Ordenadores y oficina' },
    { 'fax', 'Fax', 'oficina', 'Ordenadores y oficina' }, { 'shredder', 'Trituradora de papel', 'oficina', 'Ordenadores y oficina' }, { 'phone', 'Teléfono', 'oficina', 'Ordenadores y oficina' },
    { 'tablet', 'Tableta', 'oficina', 'Ordenadores y oficina' }, { 'cctv_cam', 'Cámara de seguridad', 'oficina', 'Seguridad' }, { 'cctv', 'Equipo de vigilancia', 'oficina', 'Seguridad' },
    { 'settop_remote', 'Mando de la tele', 'oficina', 'Televisores' }, { 'tv_ceiling', 'Tele de techo', 'oficina', 'Televisores' }, { 'tv_flat', 'Tele plana', 'oficina', 'Televisores' },
    { 'flatscreentv', 'Tele plana', 'oficina', 'Televisores' }, { 'tv_cam', 'Cámara de televisión', 'oficina', 'Ordenadores y oficina' }, { '_tv', 'Televisor', 'oficina', 'Televisores' },
    { 'v_cam', 'Videocámara', 'oficina', 'Ordenadores y oficina' }, { 'camera', 'Cámara de fotos', 'oficina', 'Ordenadores y oficina' }, { 'telescope', 'Telescopio' },
    { 'hifi', 'Equipo de música', 'ocio', 'Música y DJ' }, { 'boombox', 'Radiocasete', 'ocio', 'Música y DJ' }, { 'ghettoblast', 'Radiocasete', 'ocio', 'Música y DJ' },
    { 'tapeplayer', 'Reproductor de cintas', 'ocio', 'Música y DJ' }, { 'radioalrm', 'Radiodespertador', 'deco', 'Libros, velas y relojes' }, { 'hand_radio', 'Walkie-talkie', 'oficina', 'Ordenadores y oficina' },
    { 'walkie', 'Walkie-talkie', 'oficina', 'Ordenadores y oficina' }, { 'radio', 'Radio', 'ocio', 'Música y DJ' }, { 'speakerdock', 'Base de altavoces', 'ocio', 'Música y DJ' },
    { 'mp3_dock', 'Base de altavoces', 'ocio', 'Música y DJ' }, { 'speakerstack', 'Torre de altavoces', 'ocio', 'Música y DJ' }, { 'speaker', 'Altavoz', 'ocio', 'Música y DJ' },
    { 'dj_deck', 'Mesa de DJ', 'ocio', 'Música y DJ' }, { 'dj_stand', 'Cabina de DJ', 'ocio', 'Música y DJ' }, { 'mixer', 'Mesa de mezclas', 'ocio', 'Música y DJ' },
    { 'djbag', 'Bolsa de DJ', 'ocio', 'Música y DJ' }, { 'headphones', 'Auriculares', 'ocio', 'Música y DJ' }, { 'smoke_machine', 'Máquina de humo', 'ocio', 'Música y DJ' },
    { 'vinyl', 'Caja de vinilos', 'ocio', 'Música y DJ' }, { 'jukebox', 'Gramola', 'ocio', 'Música y DJ' }, { 'microphone', 'Micrófono', 'ocio', 'Música y DJ' },
    { 'controller', 'Mando de consola', 'ocio', 'Recreativas y juegos' }, { 'prop_console_', 'Videoconsola', 'ocio', 'Recreativas y juegos' },
    { 'fan', 'Ventilador', 'oficina', 'Ordenadores y oficina' }, { 'ecg', 'Monitor cardíaco', 'oficina', 'Ordenadores y oficina' }, { 'sewing_machine', 'Máquina de coser' },
    { 'exercisebike', 'Bicicleta estática', 'ocio', 'Gimnasio' }, { 'exer_bike', 'Bicicleta estática', 'ocio', 'Gimnasio' },
    -- arte y decoración
    { 'artwall', 'Cuadro', 'deco', 'Cuadros y arte' }, { 'wallart', 'Cuadro personalizado', 'deco', 'Cuadros y arte' }, { 'painting', 'Pintura', 'deco', 'Cuadros y arte' },
    { 'pictureframe', 'Marco de fotos', 'deco', 'Cuadros y arte' }, { 'picture_frame', 'Marco de fotos', 'deco', 'Cuadros y arte' }, { 'photoframe', 'Marco de fotos', 'deco', 'Cuadros y arte' },
    { 'photo', 'Foto enmarcada', 'deco', 'Cuadros y arte' }, { 'advert', 'Cartel publicitario', 'deco', 'Cuadros y arte' },
    { 'art_statue', 'Estatua', 'deco', 'Esculturas y trofeos' }, { 'art_car', 'Coche de colección', 'deco', 'Esculturas y trofeos' }, { 'toy_sculpture', 'Figura de colección', 'deco', 'Esculturas y trofeos' },
    { 'art_dog', 'Figura de perro', 'ocio', 'Mascotas' }, { 'art_bird', 'Figura de pájaro', 'ocio', 'Mascotas' }, { 'art_guitar', 'Guitarra de exposición', 'ocio', 'Instrumentos' },
    { 'sculpt', 'Escultura', 'deco', 'Esculturas y trofeos' }, { 'statue', 'Estatua', 'deco', 'Esculturas y trofeos' }, { 'trophy', 'Trofeo', 'deco', 'Esculturas y trofeos' },
    { 'award', 'Premio', 'deco', 'Esculturas y trofeos' }, { 'pogo_gold', 'Figura de oro', 'deco', 'Esculturas y trofeos' }, { 'horsefig', 'Figura de caballo', 'deco', 'Esculturas y trofeos' },
    { 'fighorse', 'Figura de caballo', 'deco', 'Esculturas y trofeos' }, { 'figclown', 'Figura de payaso', 'deco', 'Esculturas y trofeos' }, { 'figoblisk', 'Obelisco', 'deco', 'Esculturas y trofeos' },
    { 'figpillar', 'Pilar decorativo', 'deco', 'Esculturas y trofeos' }, { 'plinth', 'Pedestal', 'deco', 'Esculturas y trofeos' }, { 'idol_case', 'Urna de ídolo', 'deco', 'Esculturas y trofeos' },
    { 'vase_flowers', 'Jarrón con flores', 'deco', 'Plantas' }, { 'acc_flowers', 'Ramo de flores', 'deco', 'Plantas' }, { 'mflowers', 'Ramo de flores', 'deco', 'Plantas' },
    { 'fh_flowers', 'Ramo de flores', 'deco', 'Plantas' }, { 'vase', 'Jarrón', 'deco', 'Jarrones y adornos' }, { 'ceramic_jug', 'Jarra de cerámica', 'deco', 'Jarrones y adornos' },
    { 'm_urn', 'Urna', 'deco', 'Jarrones y adornos' }, { 'acc_jar', 'Tarro decorativo', 'deco', 'Jarrones y adornos' }, { 'glasspot', 'Tarro de cristal', 'deco', 'Jarrones y adornos' },
    { 'pot_pouri', 'Popurrí', 'deco', 'Jarrones y adornos' }, { 'scent_sticks', 'Ambientador de varillas', 'deco', 'Jarrones y adornos' }, { 'box_trinket', 'Joyero', 'deco', 'Jarrones y adornos' },
    { 'floatcandle', 'Velas flotantes', 'deco', 'Libros, velas y relojes' }, { 'candle', 'Velas', 'deco', 'Libros, velas y relojes' }, { 'rugwool', 'Alfombra', 'deco', 'Alfombras' },
    { 'clock', 'Reloj', 'deco', 'Libros, velas y relojes' }, { 'notebook', 'Cuaderno', 'deco', 'Libros, velas y relojes' }, { 'investbook', 'Libro', 'deco', 'Libros, velas y relojes' },
    { 'book_stack', 'Pila de libros', 'deco', 'Libros, velas y relojes' }, { 'stock_book', 'Libro', 'deco', 'Libros, velas y relojes' }, { 'novel', 'Novela', 'deco', 'Libros, velas y relojes' },
    { 'book', 'Libro', 'deco', 'Libros, velas y relojes' }, { 'magrack', 'Revistero', 'deco', 'Libros, velas y relojes' }, { 'magtidy', 'Revistero', 'deco', 'Libros, velas y relojes' },
    { 'magazine', 'Revista', 'deco', 'Libros, velas y relojes' }, { 'fashmag', 'Revista de moda', 'deco', 'Libros, velas y relojes' }, { 'mag_motor', 'Revista de motor', 'deco', 'Libros, velas y relojes' },
    { 'newspaper', 'Periódico', 'deco', 'Libros, velas y relojes' }, { 'paper_news', 'Periódico', 'deco', 'Libros, velas y relojes' }, { 'blind', 'Persiana', 'deco', 'Ventanas, cortinas y persianas' },
    { 'dreamcatch', 'Atrapasueños', 'deco', 'Jarrones y adornos' }, { 'chimes', 'Carillón de viento', 'deco', 'Jarrones y adornos' },
    { 'jewel', 'Joyas', 'deco', 'Joyas' }, { 'neck_disp', 'Expositor de collares', 'deco', 'Joyas' }, { 'leg_chain', 'Cadena', 'deco', 'Joyas' },
    -- plantas
    { 'xmas_tree', 'Árbol de Navidad', 'deco', 'Plantas' }, { 'cactus', 'Cactus', 'deco', 'Plantas' }, { 'peyote', 'Peyote', 'deco', 'Plantas' },
    { 'bush_ivy', 'Hiedra', 'jardin', 'Arbustos y árboles' }, { 'bush', 'Arbusto', 'jardin', 'Arbustos y árboles' }, { 'prop_tree_', 'Árbol', 'jardin', 'Arbustos y árboles' },
    { 'ch_prop_tree', 'Árbol en maceta', 'deco', 'Plantas' }, { 'palmeto', 'Palmito', 'jardin', 'Arbustos y árboles' }, { 'palmstairs', 'Palmera de interior', 'deco', 'Plantas' },
    { 'plant_palm', 'Palmera en maceta', 'deco', 'Plantas' }, { 'palm_sm', 'Palmera pequeña', 'jardin', 'Arbustos y árboles' }, { 'fern', 'Helecho', 'deco', 'Plantas' },
    { 'bananaplant', 'Platanera', 'deco', 'Plantas' }, { 'windowbox', 'Jardinera de ventana', 'jardin', 'Jardinería' }, { 'dstplanter', 'Jardinera', 'jardin', 'Jardinería' },
    { 'planter', 'Jardinera', 'jardin', 'Jardinería' }, { 'plant_flower', 'Flores', 'deco', 'Plantas' }, { 'plant_cane', 'Cañas', 'jardin', 'Arbustos y árboles' },
    { 'plant_clover', 'Tréboles', 'jardin', 'Arbustos y árboles' }, { 'plant_group', 'Macizo de plantas', 'jardin', 'Arbustos y árboles' }, { 'h4_pot', 'Macetero', 'deco', 'Plantas' },
    { 'm_pot1', 'Macetero', 'deco', 'Plantas' }, { 'plant', 'Planta', 'deco', 'Plantas' },
    -- jardín
    { 'bbq', 'Barbacoa', 'jardin', 'Barbacoas y fuego' }, { 'patio_heater', 'Estufa de terraza', 'jardin', 'Barbacoas y fuego' }, { 'firepit', 'Hoguera', 'jardin', 'Barbacoas y fuego' },
    { 'parasol', 'Sombrilla', 'jardin', 'Sombrillas y cenadores' }, { 'gazebo', 'Cenador', 'jardin', 'Sombrillas y cenadores' }, { 'birdbath', 'Bebedero de pájaros', 'jardin', 'Jardinería' },
    { 'hose', 'Manguera', 'jardin', 'Jardinería' }, { 'lawnmower', 'Cortacésped', 'jardin', 'Jardinería' }, { 'wheelbarrow', 'Carretilla', 'jardin', 'Jardinería' },
    { 'garden_edging', 'Bordillo de jardín', 'jardin', 'Jardinería' }, { 'zapper', 'Matamosquitos', 'jardin', 'Jardinería' }, { 'fence_arches', 'Valla con arcos', 'jardin', 'Jardinería' },
    { 'fence', 'Valla', 'jardin', 'Jardinería' }, { 'gnome', 'Gnomo de jardín', 'jardin', 'Jardinería' }, { 'prop_fountain', 'Fuente', 'jardin', 'Jardinería' },
    { 'out_door_speaker', 'Altavoz de exterior', 'jardin', 'Jardinería' },
    -- gimnasio, juegos, música y mascotas
    { 'weight_rack', 'Estante de pesas', 'ocio', 'Gimnasio' }, { 'weight_squat', 'Jaula de sentadillas', 'ocio', 'Gimnasio' }, { 'punch', 'Saco de boxeo', 'ocio', 'Gimnasio' },
    { 'barbell', 'Barra con discos', 'ocio', 'Gimnasio' }, { 'freeweight', 'Mancuerna', 'ocio', 'Gimnasio' }, { 'prop_weight', 'Disco de pesas', 'ocio', 'Gimnasio' },
    { 'yoga', 'Esterilla de yoga', 'ocio', 'Gimnasio' }, { 'swiss_ball', 'Pelota de pilates', 'ocio', 'Gimnasio' }, { 'exball', 'Pelota de ejercicio', 'ocio', 'Gimnasio' },
    { 'mexball', 'Pelota de ejercicio', 'ocio', 'Gimnasio' }, { 'boxing_glove', 'Guantes de boxeo', 'ocio', 'Gimnasio' },
    { 'plush', 'Peluche', 'ocio', 'Recreativas y juegos' }, { 'arcade_claw', 'Máquina de gancho', 'ocio', 'Recreativas y juegos' }, { 'arcade_race_car', 'Recreativa de coches', 'ocio', 'Recreativas y juegos' },
    { 'arcade_race_truck', 'Recreativa de camiones', 'ocio', 'Recreativas y juegos' }, { 'arcade_race_bike', 'Recreativa de motos', 'ocio', 'Recreativas y juegos' },
    { 'arcade_fortune', 'Máquina de la fortuna', 'ocio', 'Recreativas y juegos' }, { 'arcade_love', 'Máquina del amor', 'ocio', 'Recreativas y juegos' },
    { 'arcade_strength', 'Máquina de fuerza', 'ocio', 'Recreativas y juegos' }, { 'arcade_gun', 'Recreativa de disparos', 'ocio', 'Recreativas y juegos' },
    { 'bball_arcade', 'Canasta recreativa', 'ocio', 'Recreativas y juegos' }, { 'arcade', 'Máquina recreativa', 'ocio', 'Recreativas y juegos' }, { 'dart', 'Diana', 'ocio', 'Recreativas y juegos' },
    { 'basketball_net', 'Canasta', 'ocio', 'Recreativas y juegos' }, { 'basketball', 'Balón de baloncesto', 'ocio', 'Recreativas y juegos' }, { 'chip_', 'Fichas de casino', 'ocio', 'Recreativas y juegos' },
    { 'casino_cards', 'Baraja', 'ocio', 'Recreativas y juegos' }, { 'soc_ball', 'Balón de fútbol', 'ocio', 'Recreativas y juegos' }, { 'am_ball', 'Balón de fútbol americano', 'ocio', 'Recreativas y juegos' },
    { 'bbbat', 'Bate de béisbol', 'ocio', 'Recreativas y juegos' }, { 'tennis_bag', 'Bolsa de tenis', 'ocio', 'Recreativas y juegos' },
    { 'piano', 'Piano', 'ocio', 'Instrumentos' }, { 'drum_kit', 'Batería', 'ocio', 'Instrumentos' }, { 'cga_drums', 'Congas', 'ocio', 'Instrumentos' },
    { 'drum_stick', 'Baquetas', 'ocio', 'Instrumentos' }, { 'guitars_rack', 'Soporte de guitarras', 'ocio', 'Instrumentos' }, { 'guitar_case', 'Funda de guitarra', 'ocio', 'Instrumentos' },
    { 'guitaramp', 'Amplificador de guitarra', 'ocio', 'Instrumentos' }, { 'acc_guitar', 'Guitarra acústica', 'ocio', 'Instrumentos' }, { 'el_guitar', 'Guitarra eléctrica', 'ocio', 'Instrumentos' },
    { 'guitar', 'Guitarra', 'ocio', 'Instrumentos' }, { 'ld_sax', 'Saxofón', 'ocio', 'Instrumentos' },
    { 'doghouse', 'Caseta de perro', 'ocio', 'Mascotas' }, { 'dog_cage', 'Transportín', 'ocio', 'Mascotas' }, { 'toy_dog', 'Perro de juguete', 'ocio', 'Mascotas' },
    { 'ball_lobber', 'Lanzapelotas', 'ocio', 'Mascotas' },
    -- sótano, taller y herramientas
    { 'jail_door', 'Puerta de celda', 'sotano', 'Celda y herramientas' }, { 'pris_door', 'Puerta de celda', 'sotano', 'Celda y herramientas' }, { 'pris_bars', 'Barrotes', 'sotano', 'Celda y herramientas' },
    { 'fnclink_03gate', 'Verja metálica', 'puertas', 'Rejas y verjas' }, { 'fnclink', 'Valla metálica', 'sotano', 'Celda y herramientas' }, { 'rub_cage', 'Jaula', 'sotano', 'Celda y herramientas' },
    { 'gold_cont', 'Contenedor blindado', 'sotano', 'Celda y herramientas' }, { 'chains', 'Cadenas', 'sotano', 'Celda y herramientas' }, { 'ld_hook', 'Gancho', 'sotano', 'Celda y herramientas' },
    { 'cuff_keys', 'Llaves de esposas', 'sotano', 'Celda y herramientas' }, { 'cuffs', 'Esposas' }, { 'gaffer_tape', 'Cinta americana', 'sotano', 'Celda y herramientas' },
    { 'rope', 'Cuerda', 'sotano', 'Celda y herramientas' }, { 'toolchest', 'Carro de herramientas', 'taller', 'Herramientas' }, { 'tool_box', 'Caja de herramientas', 'taller', 'Herramientas' },
    { 'vertdrill', 'Taladro de columna', 'taller', 'Herramientas' }, { 'engine_hoist', 'Grúa de motor', 'taller', 'Herramientas' }, { 'sacktruck', 'Carretilla de mano', 'taller', 'Herramientas' },
    { 'car_battery', 'Batería de coche', 'taller', 'Herramientas' }, { 'pliers', 'Alicates', 'taller', 'Herramientas' }, { 'hammer', 'Martillo', 'taller', 'Herramientas' },
    { 'tool_wrench', 'Llave inglesa', 'taller', 'Herramientas' }, { 'tool_drill', 'Taladro', 'taller', 'Herramientas' }, { 'blowtorch', 'Soplete', 'taller', 'Herramientas' },
    { 'consaw', 'Radial', 'taller', 'Herramientas' }, { 'crowbar', 'Palanca' }, { 'shovel', 'Pala' }, { 'fireaxe', 'Hacha de bombero' }, { 'hatchet', 'Hacha' },
    { 'barrel_pile', 'Pila de barriles' }, { 'barrel', 'Barril' }, { 'pallet', 'Palé' }, { 'cementbags', 'Sacos de cemento' }, { 'generator', 'Generador' },
    { 'coolbox', 'Nevera portátil' }, { 'ice_box', 'Arcón de hielo' }, { 'bar_ice', 'Cubeta de hielo' },
    -- puertas
    { 'gar_door', 'Puerta de garaje', 'puertas', 'Portones de garaje' }, { 'porton', 'Portón de garaje', 'puertas', 'Portones de garaje' }, { 'bk_gate', 'Verja', 'puertas', 'Rejas y verjas' },
    { 'safedoor', 'Puerta de caja fuerte', 'puertas', 'Puertas' }, { 'doorsafe', 'Caja fuerte de pared' }, { 'secdoor', 'Puerta de seguridad', 'puertas', 'Puertas' },
    { 'frontdoor', 'Puerta de entrada', 'puertas', 'Puertas' }, { 'backdoor', 'Puerta trasera', 'puertas', 'Puertas' }, { 'countdoor', 'Puerta de mostrador', 'puertas', 'Puertas' },
    { 'door', 'Puerta', 'puertas', 'Puertas' }, { 'dorr', 'Puerta', 'puertas', 'Puertas' }, { 'trevtraildr', 'Puerta de caravana', 'puertas', 'Puertas' },
    { 'artgallery_dl', 'Puerta de galería', 'puertas', 'Puertas' }, { '_mp_l', 'Puerta', 'puertas', 'Puertas' },
    -- objetos sueltos
    { 'shoebox', 'Caja de zapatos' }, { 'suitcase', 'Maleta' }, { 'attache', 'Maletín' }, { 'security_case', 'Maletín de seguridad' }, { 'cash_case', 'Maletín con dinero' },
    { 'cash_pile', 'Fajos de billetes' }, { 'gun_case', 'Maletín de armas' }, { 'guncase', 'Caja de armas' }, { 'gunrack', 'Armero de pared' }, { 'box_ammo', 'Caja de munición' },
    { 'thermite_case', 'Maletín' }, { 'trevor_case', 'Maletín' }, { 'ld_case', 'Maletín' }, { 'backpack', 'Mochila' }, { 'duffel', 'Bolsa de deporte' },
    { 'heist_bag', 'Bolsa de atraco' }, { 'carrier_bag', 'Bolsa de la compra' }, { 'pill_bag', 'Bolsa de pastillas' }, { 'meth_bag', 'Bolsa de cristal' },
    { 'bag_pickup', 'Bolso' }, { 'big_bag', 'Bolsa grande' }, { 'ashtray', 'Cenicero' }, { 'cigar_pack', 'Caja de puros' }, { 'cigar', 'Puro' }, { 'ciggy', 'Cigarrillo' },
    { 'busker_hat', 'Sombrero' }, { 'proxy_hat', 'Gorra' }, { 'ballistic_shield', 'Escudo balístico' }, { 'riot_shield', 'Escudo antidisturbios' },
    { 'armour', 'Chaleco antibalas' }, { 'katana', 'Katana' }, { 'bowie_knife', 'Cuchillo de caza' }, { 'dagger', 'Daga' }, { 'me_knife', 'Cuchillo' },
    { 'torch', 'Linterna' }, { 'fib_badge', 'Placa' }, { 'franklin_dl', 'Carné de conducir' }, { 'medstation', 'Botiquín de pared' }, { 'health_pack', 'Botiquín' },
    { 'stat_pack', 'Maletín médico' }, { 'passport', 'Pasaporte' }, { 'documents', 'Documentos' }, { 'papers', 'Papeles' }, { 'cliff_paper', 'Papeles' },
    { 'cd_folder', 'Pila de carpetas' }, { 'folder', 'Carpeta' }, { 'filebox', 'Caja de archivo' }, { 'paper_box', 'Caja de folios' },
    { 'desktidy', 'Organizador de escritorio' }, { 'cdstorage', 'Torre de discos' }, { 'res_cd', 'Disco' }, { 'bong', 'Pipa de agua' }, { 'syringe', 'Jeringuilla' },
    { 'cs_pills', 'Bote de pastillas' }, { 'coke', 'Cocaína' }, { 'weed_block', 'Fardo de marihuana' }, { 'weed_pallet', 'Palé de marihuana' }, { 'weed', 'Marihuana' },
    { 'gas_mask', 'Máscara de gas' }, { 'grenade', 'Granada de gas' }, { 'sgun_casing', 'Casquillos' }, { 'swipe_card', 'Tarjeta de acceso' }, { 'chip_carrier', 'Bandeja de fichas' },
    { 'tea_trolly', 'Carrito de té' }, { 'dildo', 'Juguete para adultos' }, { 'box_step', 'Cajón' }, { 'fragwall', 'Muro roto' },
    { 'ped_business', 'Maniquí' }, { 'towerfan', 'Ventilador de torre' },
    -- lo más general, al final
    { '_chr', 'Silla', 'cocina', 'Mesas y sillas' }, { 'stool', 'Taburete', 'cocina', 'Mesas y sillas' }, { 'bench', 'Banco' },
    { 'chair', 'Silla', 'cocina', 'Mesas y sillas' }, { 'seat', 'Asiento' },
    { 'counter', 'Mostrador' }, { 'desk', 'Escritorio', 'oficina', 'Escritorios y sillas' }, { 'table', 'Mesa', 'cocina', 'Mesas y sillas' }, { 'bed', 'Cama', 'dormitorio', 'Camas' },
    { 'lamp', 'Lámpara', 'luz', 'Lámparas' }, { 'prop_pot_0', 'Cacerola', 'cocina', 'Menaje' }, { 'cage', 'Jaula' }, { 'crate', 'Caja' }, { 'case', 'Maletín' },
    { 'box', 'Caja' }, { 'bag', 'Bolsa' }, { 'rack', 'Estante' }, { 'ball', 'Pelota' },
}

-- Lo mismo, pero por el NOMBRE del mueble (en minúsculas y sin acentos), para
-- los que ya lo traen puesto: los muebles propios de los packs, cuyo modelo
-- (origen_casa_…) no dice nada en inglés. { 'palabras', grupo, 'Subgrupo' }: vale
-- la primera que aparezca como palabras enteras (se admite el plural); con un
-- asterisco al final, como principio de palabra ('estanter*'). Mandan igual que
-- el diccionario: del todo en una categoría «abierta», y solo el subgrupo si el
-- mueble ya era de ese grupo.
T.porNombre = {
    { 'camara de seguridad', 'oficina', 'Seguridad' }, { 'alarma', 'oficina', 'Seguridad' },
    { 'mesa de centro', 'salon', 'Mesas de centro y auxiliares' }, { 'mesa auxiliar', 'salon', 'Mesas de centro y auxiliares' },
    { 'mesa baja', 'salon', 'Mesas de centro y auxiliares' }, { 'mesita', 'salon', 'Mesas de centro y auxiliares' }, { 'mesa nido', 'salon', 'Mesas de centro y auxiliares' },
    { 'mueble de tele*', 'salon', 'Muebles de tele' }, { 'mueble de tv', 'salon', 'Muebles de tele' }, { 'mueble tv', 'salon', 'Muebles de tele' },
    { 'mueble bajo de tv', 'salon', 'Muebles de tele' }, { 'mueble bajo de tele*', 'salon', 'Muebles de tele' }, { 'mesa de tv', 'salon', 'Muebles de tele' }, { 'mesa de tele*', 'salon', 'Muebles de tele' },
    { 'chimenea', 'salon', 'Chimeneas' }, { 'estufa de lena', 'salon', 'Chimeneas' },
    { 'banco de pesas', 'ocio', 'Gimnasio' }, { 'banco de trabajo', 'taller', 'Herramientas' }, { 'saco de boxeo', 'ocio', 'Gimnasio' },
    { 'cinta de correr', 'ocio', 'Gimnasio' }, { 'pesa', 'ocio', 'Gimnasio' }, { 'mancuerna', 'ocio', 'Gimnasio' }, { 'eliptica', 'ocio', 'Gimnasio' }, { 'esterilla', 'ocio', 'Gimnasio' },
    { 'mesa de billar', 'ocio', 'Recreativas y juegos' }, { 'billar', 'ocio', 'Recreativas y juegos' }, { 'futbolin', 'ocio', 'Recreativas y juegos' },
    { 'recreativa', 'ocio', 'Recreativas y juegos' }, { 'pinball', 'ocio', 'Recreativas y juegos' }, { 'diana', 'ocio', 'Recreativas y juegos' }, { 'mesa de poker', 'ocio', 'Recreativas y juegos' },
    { 'mesa de dj', 'ocio', 'Música y DJ' }, { 'altavoz', 'ocio', 'Música y DJ' }, { 'altavoces', 'ocio', 'Música y DJ' }, { 'tocadiscos', 'ocio', 'Música y DJ' }, { 'gramola', 'ocio', 'Música y DJ' },
    { 'equipo de musica', 'ocio', 'Música y DJ' }, { 'guitarra', 'ocio', 'Instrumentos' }, { 'piano', 'ocio', 'Instrumentos' }, { 'bateria', 'ocio', 'Instrumentos' }, { 'violin', 'ocio', 'Instrumentos' },
    { 'acuario', 'ocio', 'Mascotas' }, { 'pecera', 'ocio', 'Mascotas' }, { 'rascador', 'ocio', 'Mascotas' }, { 'comedero', 'ocio', 'Mascotas' }, { 'caseta', 'ocio', 'Mascotas' },
    { 'silla de oficina', 'oficina', 'Escritorios y sillas' }, { 'silla gaming', 'oficina', 'Escritorios y sillas' }, { 'silla de escritorio', 'oficina', 'Escritorios y sillas' },
    { 'escritorio', 'oficina', 'Escritorios y sillas' }, { 'archivador', 'oficina', 'Escritorios y sillas' },
    { 'ordenador', 'oficina', 'Ordenadores y oficina' }, { 'monitor', 'oficina', 'Ordenadores y oficina' }, { 'portatil', 'oficina', 'Ordenadores y oficina' },
    { 'impresora', 'oficina', 'Ordenadores y oficina' }, { 'servidor', 'oficina', 'Ordenadores y oficina' }, { 'router', 'oficina', 'Ordenadores y oficina' },
    { 'televis*', 'oficina', 'Televisores' }, { 'tele', 'oficina', 'Televisores' }, { 'proyector', 'oficina', 'Televisores' }, { 'pantalla', 'oficina', 'Televisores' },
    { 'sofa', 'salon', 'Sofás y sillones' }, { 'sillon', 'salon', 'Sofás y sillones' }, { 'sillones', 'salon', 'Sofás y sillones' }, { 'butaca', 'salon', 'Sofás y sillones' },
    { 'puf', 'salon', 'Sofás y sillones' }, { 'chaise', 'salon', 'Sofás y sillones' }, { 'divan', 'salon', 'Sofás y sillones' }, { 'reposapies', 'salon', 'Sofás y sillones' },
    { 'aparador', 'salon', 'Aparadores y consolas' }, { 'consola', 'salon', 'Aparadores y consolas' }, { 'vitrina', 'salon', 'Aparadores y consolas' },
    { 'libreria', 'salon', 'Aparadores y consolas' }, { 'estanter*', 'salon', 'Aparadores y consolas' }, { 'mueble bar', 'salon', 'Aparadores y consolas' },
    { 'mesa de comedor', 'cocina', 'Mesas y sillas' }, { 'taburete', 'cocina', 'Mesas y sillas' },
    { 'frigorifico', 'cocina', 'Neveras' }, { 'nevera', 'cocina', 'Neveras' }, { 'congelador', 'cocina', 'Neveras' }, { 'vinoteca', 'cocina', 'Neveras' },
    { 'horno', 'cocina', 'Cocina y electrodomésticos' }, { 'lavavajillas', 'cocina', 'Cocina y electrodomésticos' }, { 'microondas', 'cocina', 'Cocina y electrodomésticos' },
    { 'campana', 'cocina', 'Cocina y electrodomésticos' }, { 'vitroceramica', 'cocina', 'Cocina y electrodomésticos' }, { 'fregadero', 'cocina', 'Cocina y electrodomésticos' },
    { 'encimera', 'cocina', 'Cocina y electrodomésticos' }, { 'isla de cocina', 'cocina', 'Cocina y electrodomésticos' }, { 'cafetera', 'cocina', 'Cocina y electrodomésticos' },
    { 'tostadora', 'cocina', 'Cocina y electrodomésticos' }, { 'batidora', 'cocina', 'Cocina y electrodomésticos' }, { 'hervidor', 'cocina', 'Cocina y electrodomésticos' },
    { 'vajilla', 'cocina', 'Menaje' }, { 'plato', 'cocina', 'Menaje' }, { 'olla', 'cocina', 'Menaje' }, { 'sarten', 'cocina', 'Menaje' }, { 'sartenes', 'cocina', 'Menaje' }, { 'cubiertos', 'cocina', 'Menaje' },
    { 'litera', 'dormitorio', 'Camas' }, { 'cuna', 'dormitorio', 'Camas' }, { 'colchon', 'dormitorio', 'Camas' }, { 'cama', 'dormitorio', 'Camas' },
    { 'mesilla', 'dormitorio', 'Mesillas y cómodas' }, { 'comoda', 'dormitorio', 'Mesillas y cómodas' }, { 'tocador', 'dormitorio', 'Mesillas y cómodas' }, { 'cabecero', 'dormitorio', 'Mesillas y cómodas' },
    { 'armario', 'dormitorio', 'Armarios' }, { 'ropero', 'dormitorio', 'Armarios' }, { 'perchero', 'dormitorio', 'Armarios' }, { 'zapatero', 'dormitorio', 'Armarios' },
    { 'inodoro', 'bano', 'Sanitarios' }, { 'lavabo', 'bano', 'Sanitarios' }, { 'banera', 'bano', 'Sanitarios' }, { 'ducha', 'bano', 'Sanitarios' }, { 'bide', 'bano', 'Sanitarios' },
    { 'mampara', 'bano', 'Sanitarios' }, { 'toallero', 'bano', 'Toallas y aseo' }, { 'toalla', 'bano', 'Toallas y aseo' },
    { 'lavadora', 'bano', 'Lavandería y limpieza' }, { 'secadora', 'bano', 'Lavandería y limpieza' }, { 'tendedero', 'bano', 'Lavandería y limpieza' }, { 'aspiradora', 'bano', 'Lavandería y limpieza' },
    { 'lampara de pie', 'luz', 'De pie' }, { 'lampara de mesa', 'luz', 'De mesa' }, { 'lampara de mesilla', 'luz', 'De mesa' }, { 'flexo', 'luz', 'De mesa' },
    { 'aplique', 'luz', 'De pared' }, { 'foco de pared', 'luz', 'De pared' }, { 'lampara de techo', 'luz', 'De techo' }, { 'lampara colgante', 'luz', 'De techo' },
    { 'plafon', 'luz', 'De techo' }, { 'arana', 'luz', 'De techo' }, { 'fluorescente', 'luz', 'De techo' }, { 'foco empotrado', 'luz', 'De techo' }, { 'panel led', 'luz', 'De techo' }, { 'bombilla', 'luz', 'De techo' }, { 'campana industrial', 'luz', 'De techo' }, { 'neon', 'luz', 'Neones' }, { 'tira led', 'luz', 'Neones' },
    { 'tira de luz', 'luz', 'Neones' }, { 'foco', 'luz', 'Focos' }, { 'interruptor', 'luz', 'Interruptores y puntos de luz' }, { 'lampara', 'luz', 'Lámparas' },
    { 'cuadro', 'deco', 'Cuadros y arte' }, { 'lienzo', 'deco', 'Cuadros y arte' }, { 'poster', 'deco', 'Cuadros y arte' }, { 'lamina', 'deco', 'Cuadros y arte' },
    { 'escultura', 'deco', 'Esculturas y trofeos' }, { 'estatua', 'deco', 'Esculturas y trofeos' }, { 'busto', 'deco', 'Esculturas y trofeos' }, { 'trofeo', 'deco', 'Esculturas y trofeos' },
    { 'planta', 'deco', 'Plantas' }, { 'maceta', 'deco', 'Plantas' }, { 'ficus', 'deco', 'Plantas' }, { 'cactus', 'deco', 'Plantas' }, { 'bonsai', 'deco', 'Plantas' }, { 'flores', 'deco', 'Plantas' },
    { 'alfombra', 'deco', 'Alfombras' }, { 'felpudo', 'deco', 'Alfombras' }, { 'cortina', 'deco', 'Ventanas, cortinas y persianas' }, { 'persiana', 'deco', 'Ventanas, cortinas y persianas' },
    { 'estor', 'deco', 'Ventanas, cortinas y persianas' }, { 'visillo', 'deco', 'Ventanas, cortinas y persianas' }, { 'biombo', 'deco', 'Ventanas, cortinas y persianas' },
    { 'libro', 'deco', 'Libros, velas y relojes' }, { 'vela', 'deco', 'Libros, velas y relojes' }, { 'reloj', 'deco', 'Libros, velas y relojes' }, { 'candelabro', 'deco', 'Libros, velas y relojes' },
    { 'jarron', 'deco', 'Jarrones y adornos' }, { 'jarrones', 'deco', 'Jarrones y adornos' }, { 'espejo', 'deco', 'Jarrones y adornos' },
    { 'barbacoa', 'jardin', 'Barbacoas y fuego' }, { 'brasero', 'jardin', 'Barbacoas y fuego' }, { 'hoguera', 'jardin', 'Barbacoas y fuego' },
    { 'tumbona', 'jardin', 'Tumbonas, bancos y sillas' }, { 'hamaca', 'jardin', 'Tumbonas, bancos y sillas' }, { 'sombrilla', 'jardin', 'Sombrillas y cenadores' },
    { 'cenador', 'jardin', 'Sombrillas y cenadores' }, { 'pergola', 'jardin', 'Sombrillas y cenadores' }, { 'toldo', 'jardin', 'Sombrillas y cenadores' },
    { 'arbusto', 'jardin', 'Arbustos y árboles' }, { 'arbol', 'jardin', 'Arbustos y árboles' }, { 'arboles', 'jardin', 'Arbustos y árboles' }, { 'seto', 'jardin', 'Arbustos y árboles' },
    { 'palmera', 'jardin', 'Arbustos y árboles' }, { 'jardinera', 'jardin', 'Jardinería' }, { 'manguera', 'jardin', 'Jardinería' }, { 'jacuzzi', 'jardin', 'Jardinería' },
    { 'caja fuerte', 'almacen', 'Almacenajes' }, { 'baul', 'almacen', 'Almacenajes' }, { 'arcon', 'almacen', 'Almacenajes' }, { 'taquilla', 'almacen', 'Almacenajes' }, { 'armero', 'almacen', 'Armeros' },
    { 'porton', 'puertas', 'Portones de garaje' }, { 'portones', 'puertas', 'Portones de garaje' }, { 'reja', 'puertas', 'Rejas y verjas' }, { 'verja', 'puertas', 'Rejas y verjas' }, { 'puerta', 'puertas', 'Puertas' },
    { 'elevador', 'taller', 'Elevadores y plataformas' }, { 'plataforma giratoria', 'taller', 'Elevadores y plataformas' }, { 'herramienta', 'taller', 'Herramientas' }, { 'compresor', 'taller', 'Herramientas' },
    { 'silla', 'cocina', 'Mesas y sillas' }, { 'mesa', 'cocina', 'Mesas y sillas' },
}

-- ── La ayuda (tecla H) ──────────────────────────────────────────────────
-- Tres renglones cortos por herramienta: qué hace, cómo se apunta y cómo se
-- quita. Las claves son las de las cosas de la cinta: 'h:<herramienta>', 'm'
-- (cualquier material), 'f' (un mueble), 'f:puerta' y 'nada'.
T.ayuda = {
    ['h:cavar'] = { 'Abre una celda nueva: la casa crece hacia donde excavas.', 'Mira la pared, el suelo o el techo que quieres abrir y haz clic.', 'Clic derecho rellena la celda en la que estás mirando.' },
    ['h:pared'] = { 'Levanta una pared entre dos espacios abiertos, para repartir salas.', 'Mira el suelo junto a la raya donde la quieres y haz clic.', 'Clic derecho sobre la pared la quita.' },
    ['h:esquina'] = { 'Redondea el rincón donde se juntan dos paredes lisas, de suelo a techo. En un saliente o al final de un tabique pone un canto redondo.', 'Mira el rincón y haz clic. La R cambia el radio: dos de 1 m en la misma pared hacen un medio punto. Sale del material de la pared y se pinta como ella.', 'Clic derecho sobre ella la quita. Si se queda sin una de sus paredes, se quita sola.' },
    ['h:suelo'] = { 'Tapa el hueco entre dos plantas con un suelo.', 'Mira el hueco desde arriba o desde abajo y haz clic.', 'Clic derecho sobre ese suelo lo quita y vuelve a abrir el hueco.' },
    ['h:puerta'] = { 'Pared con el hueco de una puerta. La puerta en sí se elige en el grupo Puertas.', 'Mira el suelo junto a la raya donde va y haz clic.', 'Clic derecho sobre la pared la quita.' },
    ['h:puerta2'] = { 'Hueco de puerta doble: ocupa dos celdas de ancho.', 'Mira el suelo junto a la raya; la R lo pasa a la celda del otro lado.', 'Clic derecho sobre la pared la quita.' },
    ['h:garaje'] = { 'Hueco de garaje, de dos celdas de ancho. El portón está en Puertas › Portones de garaje.', 'Mira el suelo junto a la raya; la R lo pasa a la celda del otro lado.', 'Clic derecho sobre la pared la quita.' },
    ['h:barandilla'] = { 'Barandilla en el borde entre dos espacios: no separa salas ni se pinta.', 'Se apunta como una pared. La R cambia de estilo: lo ves en la tira de arriba.', 'Clic derecho sobre ella la quita.' },
    ['h:secreto'] = { 'Paso secreto: una pared o un mueble que se abre. Fuera de la cinta, la G delante de él abre su menú.', 'Mira la pared que quieres cambiar. R: estilo. Mayús + rueda: le da la vuelta.', 'Clic derecho sobre él lo quita.' },
    ['h:trampilla'] = { 'Trampilla en el suelo entre dos plantas.', 'Mira ese suelo, o el hueco que quieres tapar. La R cambia de estilo.', 'Clic derecho sobre ella la quita.' },
    ['h:sube'] = { 'Escalera recta que sube a la planta de arriba: ocupa dos celdas y abre el hueco sola.', 'Mira el suelo donde arranca; sube hacia donde miras. La R la gira.', 'Clic derecho sobre la escalera la quita.' },
    ['h:baja'] = { 'Escalera recta que baja a la planta de abajo.', 'Mira el suelo por donde quieres bajar; baja hacia donde miras. La R la gira.', 'Clic derecho sobre la escalera la quita.' },
    ['h:subeL'] = { 'Escalera en L que sube: dos tramos con rellano.', 'Mira el suelo donde arranca. R: tuerce a la derecha, a la izquierda y luego gira.', 'Clic derecho sobre la escalera la quita.' },
    ['h:bajaL'] = { 'Escalera en L que baja a la planta de abajo.', 'Mira el suelo por donde bajas. R: tuerce a la derecha, a la izquierda y luego gira.', 'Clic derecho sobre la escalera la quita.' },
    ['h:escala'] = { 'Escalera de mano: una sola celda, pegada a una pared.', 'Mira la pared a la que va pegada. R: otra pared. Mayús + rueda: sube o baja.', 'Clic derecho sobre ella la quita.' },
    ['h:caracol'] = { 'Escalera de caracol: compacta (una celda) o amplia (dos por dos).', 'Mira el suelo. R: compacta, amplia y giro. Mayús + rueda: sube o baja.', 'Clic derecho sobre ella la quita.' },
    ['h:ascensor'] = { 'Ascensor de plataforma abierta, de dos a cinco plantas.', 'Mira la celda: tiene que estar abierta en todas las plantas. La R cambia tamaño y plantas.', 'Clic derecho sobre la cabina lo quita.' },
    ['h:ascensor2'] = { 'Ascensor de cabina cerrada, con puertas.', 'Como el otro. R: tamaño y plantas. Mayús + rueda: hacia dónde mira la puerta.', 'Clic derecho sobre la cabina lo quita.' },
    ['h:montacoches'] = { 'Plataforma para subir y bajar coches: dos por tres celdas.', 'Mira una celda del hueco, abierto en dos plantas o más. R: plantas y giro.', 'Clic derecho sobre la plataforma lo quita.' },
    ['h:imagen'] = { 'Pone una imagen tuya (enlace de Fivemanage) en una pared, un suelo o un techo.', 'Mira la cara, haz clic y pega el enlace. La R cambia el tamaño.', 'Clic derecho sobre la imagen la quita (la pared se queda).' },
    ['h:entrada'] = { 'La entrada a pie de la casa: dónde aparece quien entra, y ahí mismo queda el punto de salir.', 'Ponte donde la quieres, mirando hacia donde debe mirar quien entre, y haz clic.', 'No se quita: se cambia de sitio poniéndola otra vez.' },
    ['h:cochera'] = { 'La entrada de garaje: el sitio de dentro donde aparece el coche que entra.', 'Ponte en el sitio, mirando hacia donde debe quedar el morro, y haz clic.', 'Se cambia poniéndola otra vez; se gestiona en el menú de la casa, apartado Entradas.' },
    ['h'] = { 'Herramienta de obra.', 'Mira dónde la quieres y haz clic; la R pasa por sus variantes.', 'Clic derecho sobre lo puesto lo quita.' },
    ['m'] = { 'Pinta con este material paredes, suelos y techos.', 'Clic sobre una cara, o arrastra con el clic pulsado. Mayús + clic: toda la sala.', 'Para cambiarlo, pinta encima. El clic central coge el material que miras.' },
    ['f'] = { 'Mueble: lo ves donde miras, pegado a paredes y a otros muebles.', 'Clic: ajustarlo con flechas antes de comprar. Mayús + clic: comprarlo ya ahí. Mayús + rueda: girar. Alt: sin imán.', 'Clic derecho sobre un mueble puesto lo quita. La G lo mueve.' },
    ['f:puerta'] = { 'Puerta: se encaja sola en el hueco de puerta o de garaje que mires.', 'Mayús + rueda le da la vuelta (abre hacia el otro lado). Con Alt va libre, como un mueble.', 'Clic derecho sobre la puerta la quita.' },
    ['nada'] = { 'Aquí no hay nada todavía.', 'Q y E cambian de grupo, las flechas de subgrupo y la rueda pasa las cosas.', 'Intro busca por nombre en todo el catálogo.' },
}

-- ── Funciones ───────────────────────────────────────────────────────────
local ACENTOS = { ['á'] = 'a', ['é'] = 'e', ['í'] = 'i', ['ó'] = 'o', ['ú'] = 'u', ['ü'] = 'u', ['ñ'] = 'n',
    ['Á'] = 'a', ['É'] = 'e', ['Í'] = 'i', ['Ó'] = 'o', ['Ú'] = 'u', ['Ü'] = 'u', ['Ñ'] = 'n' }

--- En minúsculas y sin acentos, para comparar y para buscar.
function Config.Cinta.Llano(texto)
    texto = tostring(texto or '')
    for con, sin in pairs(ACENTOS) do texto = texto:gsub(con, sin) end
    return texto:lower()
end

local GRUPO = {}
for n, g in ipairs(T.grupos) do GRUPO[g.id] = n end

--- La entrada del diccionario que reconoce ese modelo, o nil.
function Config.Cinta.Entrada(modelo)
    modelo = tostring(modelo or ''):lower()
    for _, d in ipairs(T.diccionario) do
        if modelo:find(d[1], 1, true) then return d end
    end
end

--- La regla de T.porNombre que reconoce ese nombre de mueble, o nil.
function Config.Cinta.PorNombre(nombre)
    local llano = ' ' .. Config.Cinta.Llano(nombre):gsub('[^%w]+', ' ') .. ' '
    for _, r in ipairs(T.porNombre) do
        local p = r[1]
        if p:sub(-1) == '*' then
            if llano:find(' ' .. p:sub(1, -2), 1, true) then return r end
        elseif llano:find(' ' .. p .. ' ', 1, true) or llano:find(' ' .. p .. 's ', 1, true) then
            return r
        end
    end
end

--- Grupo y subgrupo de un mueble: por su categoría del catálogo y, si hace
--- falta, por su modelo (o por su nombre, si lo trae). Siempre devuelve algo:
--- en el peor caso, 'varios' y la etiqueta de su categoría.
function Config.Cinta.Clasificar(etiqueta, modelo, entrada, nombre)
    etiqueta = tostring(etiqueta or 'Varios')
    modelo = tostring(modelo or ''):lower()
    local cat = T.categorias[etiqueta]
    local grupo, sub, abierta, finos, afinar
    if cat then
        grupo, sub, abierta, finos, afinar = cat[1], cat[2], cat.abierta, cat.finos, cat.afinar
    else
        local llano = Config.Cinta.Llano(etiqueta)
        for _, r in ipairs(T.reglas) do
            if llano:find(r[1], 1, true) then grupo, sub = r[2], r[3] or etiqueta break end
        end
        if not grupo then grupo, sub = 'varios', etiqueta end
    end
    for _, f in ipairs(finos or {}) do
        if modelo:find(f[1], 1, true) then return grupo, f[2] end
    end
    entrada = entrada or Config.Cinta.Entrada(modelo)
    -- Primero lo que diga el nombre del mueble, si lo trae; después, el diccionario
    -- (por el modelo). Un mueble con nombre propio solo cambia de grupo por su
    -- nombre: su modelo está en español y el diccionario lo leería mal.
    local conNombre = type(nombre) == 'string'
    local porNombre = conNombre and Config.Cinta.PorNombre(nombre) or nil
    for q, r in ipairs({ porNombre and { porNombre[2], porNombre[3] } or false, entrada and { entrada[3], entrada[4] } or false }) do
        local g2, s2 = r and r[1], r and r[2]
        if g2 and GRUPO[g2] then
            if abierta and (q == 1 or not conNombre) then return g2, s2 or sub end
            if g2 == grupo and s2 and (abierta or afinar) then return grupo, s2 end
        end
    end
    if not GRUPO[grupo] then grupo = 'varios' end
    return grupo, sub
end

--- Nombre de un mueble para la etiqueta de la cinta: el suyo si lo trae; si
--- no, el de T.nombres o el del diccionario; y si no hay forma, la etiqueta de
--- su categoría. Devuelve también si el nombre es propio de ese mueble (true) o
--- genérico: los genéricos repetidos los numera la cinta («Sillón 1», «Sillón 2»…).
function Config.Cinta.Nombre(item, etiqueta, entrada)
    if type(item) == 'table' then
        local suyo = item.nombre or item.label
        if type(suyo) == 'string' and suyo ~= '' then return suyo, true end
    end
    local modelo = tostring(type(item) == 'table' and item.model or item or ''):lower()
    if T.nombres[modelo] then return T.nombres[modelo], true end
    entrada = entrada or Config.Cinta.Entrada(modelo)
    if entrada then return entrada[2], false end
    return tostring(etiqueta or 'Mueble'), false
end

--- Subgrupo de una herramienta de obra y de un material de pintar.
function Config.Cinta.SubHerramienta(id)
    return T.herramientas[id] or 'Más'
end

function Config.Cinta.SubMaterial(id)
    if T.materiales[id] then return T.materiales[id] end
    local llano = Config.Cinta.Llano(id)
    for _, r in ipairs(T.reglasMaterial) do
        if llano:find(r[1], 1, true) then return r[2] end
    end
    return 'Paredes lisas'
end

--- Ordena las cosas de un grupo por subgrupo (el orden de `subs` del grupo, y
--- los que no estén, detrás por orden alfabético) sin cambiar el orden que
--- traían dentro de cada uno. Devuelve la lista de cosas ya seguida y la de
--- subgrupos: { { nombre, desde, n } }. `subDe(cosa)` dice el subgrupo de cada una.
function Config.Cinta.Repartir(grupo, cosas, subDe)
    local orden, cajas = {}, {}
    for q, nombre in ipairs(grupo.subs or {}) do orden[nombre] = q end
    local nombres = {}
    for _, c in ipairs(cosas) do
        local s = subDe(c) or 'Varios'
        if not cajas[s] then
            cajas[s] = {}
            nombres[#nombres + 1] = s
        end
        cajas[s][#cajas[s] + 1] = c
    end
    table.sort(nombres, function(a, b)
        local oa, ob = orden[a], orden[b]
        if oa and ob then return oa < ob end
        if oa or ob then return oa ~= nil end
        return Config.Cinta.Llano(a) < Config.Cinta.Llano(b)
    end)
    local seguidas, subs = {}, {}
    for _, s in ipairs(nombres) do
        subs[#subs + 1] = { nombre = s, desde = #seguidas + 1, n = #cajas[s] }
        for _, c in ipairs(cajas[s]) do seguidas[#seguidas + 1] = c end
    end
    return seguidas, subs
end

--- ¿Casa ese texto de búsqueda (ya en llano) con una cosa? Todas las palabras
--- tienen que estar en su nombre, su subgrupo, su grupo o su modelo.
function Config.Cinta.Casa(palabras, pajar)
    for _, p in ipairs(palabras) do
        if not pajar:find(p, 1, true) then return false end
    end
    return true
end
