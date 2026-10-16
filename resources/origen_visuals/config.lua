--[[ ══ Origen Visuals: los valores ═══════════════════════════════════════════

     Todo lo que cambia el aspecto del juego esta en este fichero. No se
     sustituye ningun fichero del juego: se le cambian valores en marcha, y al
     parar el recurso (o con /visuals) vuelve todo a como estaba.

     Al lado de cada valor va el ORIGINAL del juego (build 3095), para saber
     cuanto se ha movido. Tras tocar algo: restart origen_visuals. ]]

Config = {}

--[[ visualsettings.dat: luces de coches, farolas lejanas, semaforos, reflejos
     y la curva de tono (el "revelado" de la imagen). Clave = valor. ]]
Config.Ajustes = {
    -- Curva de tono. D/E/F son la parte oscura (mas D = sombras mas hondas),
    -- A la parte clara. Es lo que quita el aspecto lavado del juego.
    ['Tonemapping.bright.filmic.A'] = 0.27,     -- 0.22
    ['Tonemapping.bright.filmic.D'] = 0.26,     -- 0.20
    ['Tonemapping.bright.filmic.E'] = 0.014,    -- 0.01
    ['Tonemapping.dark.filmic.A'] = 0.26,       -- 0.22
    ['Tonemapping.dark.filmic.D'] = 0.25,       -- 0.20

    -- Faros: alumbran mas lejos y se ve el haz en la niebla y la lluvia.
    ['car.headlights.global.HeadlightIntensityMult'] = 6.5,     -- 5.0
    ['car.headlights.global.HeadlightDistMult'] = 1.3,          -- 1.0
    ['car.headlights.fullbeam.IntensityMult'] = 1.35,           -- 1.1
    ['car.headlights.fullbeam.DistMult'] = 1.7,                 -- 1.3
    ['car.headlights.player.distmult'] = 1.8,                   -- 1.5
    ['car.headlights.volume.intensityscale'] = 0.01,            -- 0.005

    -- Pilotos de noche: el cristal del faro y la luz de freno brillan mas.
    ['car.headlight.night.emissive.on'] = 22.0,     -- 15
    ['car.brakelight.night.emissive.on'] = 42.0,    -- 30
    ['car.reversinglight.night.emissive.on'] = 6.0, -- 3

    -- Los destellos (coronas) de los coches se ven desde mas lejos.
    ['car.coronas.BeginEnd'] = 450.0,       -- 300
    ['car.coronas.CutoffStart'] = 440.0,    -- 290
    ['car.coronas.CutoffEnd'] = 450.0,      -- 300
    ['misc.coronas.intensityScaleGlobal'] = 0.7, -- 0.5
    ['misc.coronas.sizeScaleGlobal'] = 0.85,     -- 0.75

    -- Sirenas: el reflejo en el asfalto y las sombras llegan mas lejos.
    ['car.sirens.SpecularFade'] = 35.0,     -- 15
    ['car.sirens.ShadowFade'] = 25.0,       -- 15

    -- La ciudad de lejos: coches y farolas como puntos de luz.
    ['distantlights.carlight.HDRIntensity'] = 3.5,      -- 2
    ['distantlights.streetlight.HDRIntensity'] = 3.5,   -- 2
    -- Las farolas del servidor son blancas (origen_visuals_stream); las que se
    -- pintan como puntos a lo lejos, tambien. El juego las trae naranja sodio.
    ['distantlights.streetlight.color.green'] = 0.9,    -- 0.47
    ['distantlights.streetlight.color.blue'] = 0.78,    -- 0.03

    -- Semaforos: se distinguen desde antes.
    ['trafficLight.near.intensity'] = 2.5,      -- 1.75
    ['trafficLight.farFadeStart'] = 160.0,      -- 100
    ['trafficLight.farFadeEnd'] = 200.0,        -- 120

    -- Reflejos: apenas por encima del juego. Con 4.5 / 6.5, lloviendo, los postes y
    -- las superficies mojadas se llenaban de puntitos de colores (11/10).
    ['reflection.tweaks.exterior.artificial.boost'] = 3.3,  -- 3.0
    ['reflection.tweaks.emissive.boost'] = 5.3,             -- 5.0

    -- Resplandor: empieza con luces menos fuertes y el halo es mas ancho.
    ['bloom.threshold.min'] = 0.3,          -- 0.4
    ['bloom.blurblendmult.large'] = 0.9,    -- 0.5
    ['bloom.blurblendmult.med'] = 2.3,      -- 2.0

    -- Charcos con lluvia: apenas por encima del juego. Con range 0.2 y strength 0.75 las
    -- aceras se cubrian de una lamina blanca con ondas, como plastico (11/10, con captura).
    ['puddles.range'] = 0.16,       -- 0.15
    ['puddles.strength'] = 0.55,    -- 0.5
}

--[[ Valores del timecycle que se ponen fijos, de dia y de noche, dentro y
     fuera. Los multiplicadores valen 1.0 en el juego.

     OJO, los de detalle y sombras son lo unico del recurso que cuesta FPS:
     dibujan mas cosas a mas distancia. Si hay quejas de rendimiento, bajar
     esos antes que nada. ]]
Config.Fijas = {
    -- Hasta donde llegan los modelos buenos antes de pasar al de lejos.
    -- Es lo que hace que arboles, arbustos y edificios no "salten" tan cerca.
    lod_mult_hd = 1.5,
    lod_mult_orphanhd = 1.5,
    lod_mult_lod = 1.4,
    lod_mult_slod1 = 1.25,

    -- Sombras del sol hasta mas lejos.
    dir_shadow_distance_multiplier = 1.5,
    shadow_distance_mult = 1.4,

    -- Esquinas de la imagen algo mas oscuras, como en una camara.
    postfx_vignetting_intensity = 0.22,
    postfx_vignetting_radius = 7.0,
}

--[[ La noche. De 0 (dia) a 1 (noche cerrada), con una rampa al anochecer y
     otra al amanecer. Horas del juego, con decimales. ]]
Config.Noche = {
    anochece = { 19.5, 21.5 },
    -- Climas en los que se aplica la noche de Origen entera (oscuridad, conos de farola, neones).
    despejado = { EXTRASUNNY = true, CLEAR = true, CLOUDS = true, NEUTRAL = true, SMOG = true },
    amanece = { 5.0, 6.5 },

    -- variable = { de dia, de noche cerrada }. El valor de dia es el del juego.
    vars = {
        -- Luz ambiente natural (la del cielo). Mas bajo = donde no hay
        -- farolas se ve menos. Con 0.5 ya cuesta jugar.
        natural_ambient_multiplier = { 1.0, 0.65 },
        -- Alcance de las luces lejanas de la ciudad.
        lodlight_range_mult = { 1.0, 1.4 },
        -- Alcance de farolas, escaparates y demas luces cercanas: el charco
        -- de luz en la acera es mas grande.
        light_falloff_mult = { 1.0, 1.4 },

        -- Luz volumetrica: el cono de luz de las farolas se ve en el aire.
        -- Con cuidado: en una avenida las farolas se SUMAN. Con intensidad
        -- 0.035 y densidad 1.6 una calle con dos farolas quedaba bien y una
        -- avenida entera se llenaba de neblina naranja.
        fog_volume_light_intensity = { 0.015, 0.026 },
        fog_volume_light_size = { 0.0, 0.8 },
        fog_volume_light_range = { 25.0, 30.0 },
        fogvolume_density_scalar = { 0.0, 0.6 },

        -- Destello de las luces (farolas, pilotos, semaforos).
        sprite_brightness = { 1.0, 1.25 },
        sprite_size = { 1.0, 1.12 },
    },

    -- Neones y luces de noche: resplandor (halo) alrededor de lo que emite luz, y la
    -- exposicion algo mas baja para que los rotulos y ventanas no se quemen en blanco.
    -- Probado en Vinewood de noche: con bloom 2.2 las ventanas se comian la fachada.
    hacia = {
        postfx_intensity_bloom = 1.4,
        postfx_exposure = -0.25,    -- con -0.4 el cielo de noche perdia el azul y quedaba negro
    },
}

--[[ La luz de las personas. El motor tiene una luz de relleno solo para los personajes; el
     juego la deja floja y fria, y de noche las caras quedan planas y azuladas. Aqui, de
     noche, va mas fuerte y calida: la cara se lee y la piel coge color. De dia no se toca.
     Con 0.8 y mas naranja la piel oscura se iba a rojo en primer plano: de ahi el 0.5 y el tono suave. ]]
Config.Personaje = {
    ped_light_mult = 0.5,   -- el juego: 0.2-0.3
    ped_light_col_r = 1.0,
    ped_light_col_g = 0.93,
    ped_light_col_b = 0.84,
}

--[[ Nubes. Por clima, las capas de nubes del juego entre las que se va
     rotando. El clima que no salga se queda con la que ponga el juego. ]]
Config.Nubes = {
    horasPorCapa = 6,   -- horas de juego que dura cada una
    fundido = 30.0,     -- segundos que tarda en entrar o salir

    -- Con buen tiempo, solo las de cumulos grandes: las finas (Cirrus, Wispy,
    -- Contrails) apenas se ven y el cielo parece el del juego.
    EXTRASUNNY = { 'Cloudy 01', 'Puffs', 'Nimbus' },
    CLEAR = { 'Cloudy 01', 'Nimbus', 'Puffs' },
    NEUTRAL = { 'Cloudy 01', 'Puffs' },
    CLOUDS = { 'Cloudy 01', 'Nimbus', 'stratoscumulus' },
    CLEARING = { 'Cloudy 01', 'shower' },
    OVERCAST = { 'altostratus', 'Stripey', 'Stormy 01' },
    RAIN = { 'Stormy 01', 'shower' },
    THUNDER = { 'Stormy 01' },
}

--[[ Lo que se cambia en proporcion a lo que pone el juego a cada hora y con
     cada clima (data/base.lua). 1.0 = igual que el juego. El clima que no
     salga aqui se queda como esta. Dentro de un interior no se aplica. ]]
Config.Proporcion = {
    -- Aire mas limpio con buen tiempo: se ve mas lejos y el cielo queda menos
    -- blanquecino. La niebla, la lluvia y la nieve no se tocan.
    fog_density = { EXTRASUNNY = 0.45, CLEAR = 0.5, CLOUDS = 0.65, NEUTRAL = 0.5, CLEARING = 0.75, OVERCAST = 0.85, FOGGY = 2.1 },
    fog_haze_density = { EXTRASUNNY = 0.55, CLEAR = 0.6, CLOUDS = 0.75, NEUTRAL = 0.6, CLEARING = 0.85, FOGGY = 2.0 },

    -- La niebla de verdad (clima FOGGY): el doble de espesa, mas pegada al suelo (los
    -- edificios se pierden hacia arriba por capas) y fria en vez de blanca lechosa.
    -- Elegida entre ocho variantes probadas en partida a las 9:00.
    fog_falloff = { FOGGY = 1.9 },
    fog_col_r = { FOGGY = 0.72 }, fog_col_g = { FOGGY = 0.79 }, fog_col_b = { FOGGY = 0.88 },
    fog_near_col_r = { FOGGY = 1.3 }, fog_near_col_g = { FOGGY = 1.3 }, fog_near_col_b = { FOGGY = 1.32 },
    -- Color algo menos chillon (1.0 = el del juego; por debajo, mas apagado).
    postfx_desaturation = { todos = 0.95, FOGGY = 0.8 },
    -- Oclusion ambiental: la sombra de contacto entre hojas, bajo los coches
    -- y en las esquinas. Da volumen a la vegetacion.
    ssao_inten = { todos = 1.35 },
    -- Luz de cine: menos sol directo. El juego compensa la exposicion y lo que queda es una
    -- imagen con las sombras hondas y azuladas, el cielo mas saturado y el asfalto mas
    -- oscuro. Es, con diferencia, lo que mas cambia el aspecto de dia (probado al mediodia
    -- con 8 valores: por debajo de la mitad ya no cambia mas; por encima de x1.3 se quema).
    light_dir_mult = { EXTRASUNNY = 0.55, CLEAR = 0.55, CLOUDS = 0.6, NEUTRAL = 0.55, SMOG = 0.6 },
    -- Rayos de sol entre nubes, edificios y arboles. Donde mas se nota es al amanecer y
    -- al atardecer; con x2.3 el sol se comia media pantalla.
    light_ray_mult = { todos = 1.6 },
}

--[[ Ambientes por lugar y hora. Cada uno entra solo en sus zonas (nombres de zona del
     juego, GetNameOfZone), dentro de su franja de horas { empieza, lleno, lleno, acaba } y
     con sus climas. En `vars`: por = multiplica lo que haya; vale = lo lleva a ese valor. ]]
local BUEN_TIEMPO = { EXTRASUNNY = true, CLEAR = true, CLOUDS = true, NEUTRAL = true }

Config.Ambientes = {
    {   -- Bruma baja al amanecer en el campo, la costa norte y la montaña.
        id = 'bruma', horas = { 4.5, 5.8, 7.2, 9.0 }, climas = BUEN_TIEMPO,
        zonas = { 'PALETO', 'PALFOR', 'PALCOV', 'PROCOB', 'CMSW', 'MTCHIL', 'MTGORDO', 'MTJOSE', 'SANCHIA', 'CANNY',
                  'CCREAK', 'GRAPES', 'ALAMO', 'LAGO', 'NCHU', 'TONGVAH', 'TONGVAV', 'CHIL', 'BHAMCA', 'CHU', 'PALHIGH',
                  'TATAMO', 'WINDF', 'ELGORL', 'BRADP', 'BRADT', 'GALFISH', 'RGLEN', 'GREATC', 'ZANCUDO', 'SANAND' },
        vars = { fog_density = { por = 3.2 }, fog_haze_density = { por = 1.8 } },
    },
    {   -- Calima en el desierto en las horas de calor: el aire tiembla sobre el suelo.
        id = 'calima', horas = { 10.5, 12.5, 16.0, 18.0 }, climas = { EXTRASUNNY = true, CLEAR = true },
        zonas = { 'DESRT', 'SANDY', 'HARMO', 'RTRAK', 'ZQ_UAR', 'JAIL', 'SLAB', 'HUMLAB', 'GRAPES', 'ALAMO' },
        vars = { hh_minIntensity = { vale = 0.45 }, hh_maxIntensity = { por = 1.8 }, fog_haze_density = { por = 1.6 } },
    },
}

--[[ Viento segun el clima (0 = aire parado). Mueve arboles, hierba, banderas y toldos. ]]
Config.Viento = {
    EXTRASUNNY = 0.12, CLEAR = 0.18, NEUTRAL = 0.15, CLOUDS = 0.3, SMOG = 0.08, FOGGY = 0.04,
    OVERCAST = 0.45, CLEARING = 0.4, RAIN = 0.6, THUNDER = 1.0, otro = 0.2,
}

--[[ La lluvia: charcos, ropa mojada y coches lavados. ]]
Config.Lluvia = {
    charcos = 0.95,         -- nivel de lluvia forzado mientras llueve (por encima de 0.5 solo acelera los charcos)
    alturaRopa = 1.9,       -- hasta donde se moja la ropa, en metros desde los pies
    segundosEmpapar = 90,   -- lo que tarda en calarse entero a la intemperie
    segundosSecar = 240,    -- y en secarse a cubierto
    segundosLavar = 150,    -- lo que tarda la lluvia en dejar limpio un coche lleno de polvo
}

--[[ Efectos de lente, apagados de serie: cada jugador los enciende en el panel. ]]
Config.Lente = {
    grano = { postfx_noise = 0.1, postfx_noise_size = 0.55 },
    aberracion = { chrom_aberration_coeff = 0.004, chrom_aberration_coeff2 = 0.002 },
}

--[[ Estilos de un clic del panel: cada uno deja todos los apartados como en Origen salvo
     los que nombre aqui. ]]
Config.Estilos = {
    { id = 'origen', nombre = 'Origen', gustos = {} },
    { id = 'cine', nombre = 'Cine', gustos = { contraste = 'cine', color = 'cine', rayos = 'fuerte', neon = 'fuerte', noche = 'cerrada', grano = 'si' } },
    { id = 'vivo', nombre = 'Vivo', gustos = { color = 'juego', luz = 'suave', noche = 'juego', rayos = 'fuerte' } },
    { id = 'ligero', nombre = 'Ligero', gustos = { detalle = 'juego', sombras = 'juego', farolas = 'juego', destellos = 'juego' } },
}

--[[ El panel «Origen Gráficos» (radial → Gráficos, o /graficos): lo que cada jugador
     gradua a su gusto, en vivo, y se le guarda en su maquina.

     Cada apartado gobierna trozos de lo de arriba:
       tc = trozos de nombre de variables de timecycle (Fijas, Noche, Proporcion)
       vs = trozos de nombre de claves de Config.Ajustes
     y cada nivel lleva `v`: 0 = como el juego, 1 = como esta puesto arriba, mas de 1 =
     mas fuerte. Los de si/no llevan true/false. Lo que no gobierne ningun apartado va
     siempre como esta arriba.

     Las texturas (calles, edificios, arboles, pelo) no estan aqui: son ficheros y van
     siempre. ]]
local SI_NO = { { id = 'no', nombre = 'No', v = false }, { id = 'si', nombre = 'Sí', v = true } }
local TRES = { { id = 'juego', nombre = 'Del juego', v = 0.0 }, { id = 'suave', nombre = 'Suave', v = 0.5 }, { id = 'origen', nombre = 'Origen', v = 1.0 } }

Config.Opciones = {
    -- ── Imagen ──
    { id = 'contraste', grupo = 'imagen', nombre = 'Contraste', ayuda = 'El revelado de la imagen: sombras más hondas y menos aspecto lavado.', defecto = 'origen',
      vs = { 'Tonemapping' },
      niveles = { { id = 'juego', nombre = 'Del juego', v = 0.0 }, { id = 'suave', nombre = 'Suave', v = 0.5 }, { id = 'origen', nombre = 'Origen', v = 1.0 }, { id = 'cine', nombre = 'Cine', v = 1.5 } } },
    { id = 'color', grupo = 'imagen', nombre = 'Color', ayuda = 'Cuánto se apagan los colores chillones del juego.', defecto = 'origen',
      tc = { 'postfx_desaturation' },
      niveles = { { id = 'juego', nombre = 'Vivo', v = 0.0 }, { id = 'origen', nombre = 'Natural', v = 1.0 }, { id = 'cine', nombre = 'Apagado', v = 2.5 } } },
    { id = 'resplandor', grupo = 'imagen', nombre = 'Resplandor', ayuda = 'El brillo que desborda de lo muy iluminado, de día y de noche.', defecto = 'origen',
      vs = { 'bloom.' }, niveles = TRES },
    { id = 'vineta', grupo = 'imagen', nombre = 'Viñeta', ayuda = 'Esquinas de la pantalla algo más oscuras, como en una cámara.', defecto = 'si',
      tc = { 'postfx_vignetting' }, niveles = SI_NO },
    { id = 'oclusion', grupo = 'imagen', nombre = 'Sombra de contacto', ayuda = 'La sombra fina entre hojas, bajo los coches y en las esquinas. Da volumen.', defecto = 'origen',
      tc = { 'ssao_inten' }, niveles = TRES },

    { id = 'luz', grupo = 'imagen', nombre = 'Luz de cine', ayuda = 'Menos sol directo: sombras hondas y azuladas, cielo más intenso. Es lo que más cambia la imagen de día.', defecto = 'origen',
      tc = { 'light_dir_mult' }, niveles = TRES },

    { id = 'grano', grupo = 'imagen', nombre = 'Grano de película', ayuda = 'Un grano fino sobre la imagen, como en cine.', defecto = 'no', niveles = SI_NO },
    { id = 'aberracion', grupo = 'imagen', nombre = 'Lente', ayuda = 'Bordes de color en las esquinas, como una lente real.', defecto = 'no', niveles = SI_NO },

    -- ── Cielo y clima ──
    { id = 'aire', grupo = 'cielo', nombre = 'Aire limpio', ayuda = 'Con buen tiempo se ve más lejos y el cielo queda menos blanquecino.', defecto = 'origen',
      tc = { 'fog_density', 'fog_haze_density' }, niveles = TRES },
    { id = 'niebla', grupo = 'cielo', nombre = 'Niebla', ayuda = 'Cuando hay niebla: más pegada al suelo, fría y por capas.', defecto = 'origen',
      tc = { 'fog_falloff', 'fog_col', 'fog_near_col' }, niveles = TRES },
    { id = 'nubes', grupo = 'cielo', nombre = 'Nubes con volumen', ayuda = 'Cúmulos grandes en vez de las nubes planas del juego.', defecto = 'si', niveles = SI_NO },
    { id = 'rayos', grupo = 'cielo', nombre = 'Rayos de sol', ayuda = 'La luz del sol derramándose entre nubes, edificios y árboles.', defecto = 'origen',
      tc = { 'light_ray_mult' },
      niveles = { { id = 'juego', nombre = 'Del juego', v = 0.0 }, { id = 'origen', nombre = 'Origen', v = 1.0 }, { id = 'fuerte', nombre = 'Fuerte', v = 2.0 } } },
    { id = 'charcos', grupo = 'cielo', nombre = 'Charcos y reflejos', ayuda = 'Con lluvia: charcos más grandes y el suelo mojado refleja más.', defecto = 'origen',
      vs = { 'puddles.', 'reflection.tweaks' }, niveles = TRES },

    { id = 'ambiente', grupo = 'cielo', nombre = 'Ambiente por zonas', ayuda = 'Bruma al amanecer en el campo y calima en el desierto a mediodía.', defecto = 'si', niveles = SI_NO },
    { id = 'viento', grupo = 'cielo', nombre = 'Viento', ayuda = 'Árboles, hierba y banderas se mueven según el tiempo que haga.', defecto = 'si', niveles = SI_NO },

    { id = 'lluvia', grupo = 'cielo', nombre = 'Lluvia viva', ayuda = 'Los charcos se forman antes, la ropa se empapa a la intemperie y la lluvia lava los coches.', defecto = 'si', niveles = SI_NO },

    -- ── Noche ──
    { id = 'noche', grupo = 'noche', nombre = 'Oscuridad', ayuda = 'Lo oscuro que queda donde no hay farolas.', defecto = 'origen',
      tc = { 'natural_ambient_multiplier' },
      niveles = { { id = 'juego', nombre = 'Clara', v = 0.0 }, { id = 'origen', nombre = 'Origen', v = 1.0 }, { id = 'cerrada', nombre = 'Cerrada', v = 1.5 } } },
    { id = 'neon', grupo = 'noche', nombre = 'Neones', ayuda = 'El halo de luz alrededor de rótulos, ventanas y pilotos.', defecto = 'origen',
      tc = { 'postfx_intensity_bloom', 'postfx_exposure' },
      niveles = { { id = 'juego', nombre = 'Sin halo', v = 0.0 }, { id = 'origen', nombre = 'Origen', v = 1.0 }, { id = 'fuerte', nombre = 'Fuerte', v = 1.6 } } },
    { id = 'farolas', grupo = 'noche', nombre = 'Cono de las farolas', ayuda = 'La luz de cada farola visible en el aire, y su charco de luz más grande.', defecto = 'origen',
      tc = { 'fog_volume_light', 'fogvolume_density', 'light_falloff_mult' }, niveles = TRES },
    { id = 'destellos', grupo = 'noche', nombre = 'Destellos', ayuda = 'El destello en estrella de farolas, semáforos y luces de coche.', defecto = 'origen',
      tc = { 'sprite_' }, vs = { 'coronas' }, niveles = TRES },
    { id = 'lejanas', grupo = 'noche', nombre = 'Luces de la ciudad', ayuda = 'La ciudad de lejos: más puntos de luz y desde más distancia.', defecto = 'origen',
      tc = { 'lodlight_range_mult' }, vs = { 'distantlights.' }, niveles = TRES },

    { id = 'personaje', grupo = 'noche', nombre = 'Luz de los personajes', ayuda = 'De noche, una luz cálida sobre las personas: se les ve la cara y la piel coge color.', defecto = 'origen',
      tc = { 'ped_light' }, niveles = TRES },

    -- ── Coches ──
    { id = 'faros', grupo = 'coches', nombre = 'Faros', ayuda = 'Los faros alumbran más lejos y se ve el haz con niebla o lluvia.', defecto = 'origen',
      vs = { 'car.headlights', 'car.headlight.' }, niveles = TRES },
    { id = 'pilotos', grupo = 'coches', nombre = 'Pilotos y freno', ayuda = 'Luces traseras, de freno y de marcha atrás más vivas de noche.', defecto = 'origen',
      vs = { 'car.brakelight', 'car.reversinglight' }, niveles = TRES },
    { id = 'sirenas', grupo = 'coches', nombre = 'Sirenas', ayuda = 'El reflejo y la sombra de las sirenas llegan más lejos.', defecto = 'origen',
      vs = { 'car.sirens' }, niveles = TRES },
    { id = 'semaforos', grupo = 'coches', nombre = 'Semáforos', ayuda = 'Se distinguen desde antes.', defecto = 'origen',
      vs = { 'trafficLight' }, niveles = TRES },

    { id = 'texcoches', grupo = 'coches', nombre = 'Texturas de los coches', ayuda = 'Neumáticos, cristales, matrículas y suciedad rehechos. Se cambian al momento.', defecto = 'si', niveles = SI_NO },

    -- ── Rendimiento ──
    { id = 'fps', grupo = 'rendimiento', nombre = 'Modo FPS', ayuda = 'Para PCs justos: menos sombras, menos detalle lejano y menos tráfico. Es el /fpson de siempre.', defecto = 'no', externo = 'fps',
      niveles = { { id = 'no', nombre = 'Apagado', v = false }, { id = 'medio', nombre = 'Medio', v = 'medio' }, { id = 'max', nombre = 'Máximo', v = 'max' } } },
    { id = 'texturas', grupo = 'rendimiento', nombre = 'Texturas del servidor', ayuda = 'Calles, aceras y terreno rehechos. Se cambian al momento. «Alta» añade las de cerca y usa más memoria de la gráfica; en «Del juego» no se carga ninguna.', defecto = 'alta', sinBarra = true,
      niveles = { { id = 'juego', nombre = 'Del juego', v = 0 }, { id = 'normal', nombre = 'Normal', v = 1 }, { id = 'alta', nombre = 'Alta', v = 2 } } },
    { id = 'detalle', grupo = 'rendimiento', nombre = 'Detalle a lo lejos', ayuda = 'Árboles y edificios con todo su detalle desde más lejos. Cuesta FPS.', defecto = 'origen',
      tc = { 'lod_mult' },
      niveles = { { id = 'juego', nombre = 'Del juego', v = 0.0 }, { id = 'origen', nombre = 'Origen', v = 1.0 }, { id = 'ultra', nombre = 'Ultra', v = 1.8 } } },
    { id = 'sombras', grupo = 'rendimiento', nombre = 'Alcance de las sombras', ayuda = 'Las sombras del sol llegan más lejos. Cuesta FPS.', defecto = 'origen',
      tc = { 'shadow_distance' },
      niveles = { { id = 'juego', nombre = 'Del juego', v = 0.0 }, { id = 'origen', nombre = 'Origen', v = 1.0 }, { id = 'ultra', nombre = 'Ultra', v = 1.8 } } },
}

--[[ Lo que va con el servidor y NO se puede quitar desde el panel: son ficheros que
     sustituyen a los del juego (origen_visuals_stream). Salen en el panel con un solo
     boton, para que se sepa que estan puestos y que no dependen del interruptor. ]]
local FIJO = { { id = 'si', nombre = 'Siempre puesto · no se apaga desde aquí', v = true } }
for _, o in ipairs({
    -- Las calles, aceras y terreno rehechos no se sirven de momento (5,6 GB, mucha memoria de
    -- la grafica): cuando vuelvan, aqui va su apartado «fijo_suelo».
    { id = 'fijo_caras', grupo = 'imagen', nombre = 'Piel de las caras', ayuda = 'Más detalle y poro en las caras de los personajes. Va siempre puesta.' },
    { id = 'fijo_farolas', grupo = 'noche', nombre = 'Farolas blancas', ayuda = 'Las farolas naranjas del juego pasan a luz blanca. Va siempre puesto.' },
    { id = 'fijo_coches', grupo = 'coches', nombre = 'Texturas de los coches', ayuda = 'Neumáticos, cristales y matrículas rehechos. Van siempre puestas.' },
    { id = 'fijo_humo', grupo = 'cielo', nombre = 'Humo y partículas', ayuda = 'Humo, polvo y salpicaduras más nítidos. Va siempre puesto.' },
}) do
    o.defecto, o.niveles = 'si', FIJO
    Config.Opciones[#Config.Opciones + 1] = o
end

--[[ Texturas en caliente (texturas.lua): APAGADO. Poner y quitar texturas del mapa con
     AddReplaceTexture funciona un rato, pero cuando el juego carga y suelta zonas acaba
     pintando texturas de otro sitio (carreteras con fachadas, 11/10). Hasta saber por
     que, las texturas se sirven sustituyendo por nombre, como siempre, y estos dos
     apartados no salen en el panel. ]]
Config.TexturasEnCaliente = false
if not Config.TexturasEnCaliente then
    for i = #Config.Opciones, 1, -1 do
        local id = Config.Opciones[i].id
        if id == 'texturas' or id == 'texcoches' then table.remove(Config.Opciones, i) end
    end
end
