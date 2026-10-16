--[[ ═══════════════════════════════════════════════════════════════════════
     LOS EXÁMENES PRÁCTICOS

     Cada examen es una lista de ETAPAS que el examinador va pidiendo una
     detrás de otra. El cliente las vigila (client/practico.lua) y avisa al
     servidor al cumplir cada una; el servidor comprueba con SU posición del
     aparato que de verdad se ha hecho (server/practico.lua).

     Tipos de etapa:

       motor         arrancar (o apagar, con `apagar = true`) desde los mandos
       rodar         llegar rodando a un punto de tierra (`pos`, `radio`)
       parar         detenerse en un punto, alineado con `rumbo`, `seg` segundos
       despegue      por la pista, en el aire antes de `antesDe` (metros de
                     pista); se da por hecho al pasar de `agl` metros del suelo
       tren          subir (`arriba = true`) o bajar el tren; se salta sola en
                     los aparatos con tren fijo
       altitud       ponerse entre `min` y `max` (metros sobre el mar) y
                     aguantar `seg` segundos
       aro           pasar por dentro de un aro (`pos`, `radio`). Si se lo
                     salta, resta `puntos` y sigue
       estable       `seg` segundos sin salirse de ±`alto` metros ni pasar de
                     `alabeo` grados de inclinación
       viraje        una vuelta completa (330°+) en menos de `seg` segundos sin
                     salirse de ±`alto` metros
       pasada        pasada baja a lo largo de la pista, entre `min` y `max`
                     metros sobre ella, sin tocarla
       toque         tocar la pista entre `desde` y `hasta` y volver a subir
                     sin parar (toma y despegue)
       aterrizar     tocar entre `desde` y `hasta`, no más fuerte de `vzBlanda`
                     m/s (y nunca más de `vzDura`), y parar dentro de la pista
       estacionario  helicóptero: quieto entre `min` y `max` metros sobre el
                     suelo, a menos de `radio` de `pos`, `seg` segundos
       tomar         helicóptero: posarse dentro de `radio` de `pos`, suave
       aparcar       llegar a `pos` y parar del todo

     Alturas de los aros: `z` es absoluta (sobre el mar), pero nunca queda
     por debajo del terreno + `sobre` (se mira el mapa de alturas del juego
     en el cliente, GetHeightmapTopZForPosition). `agl` en vez de `z`: a esa
     altura sobre lo que haya debajo (lo usan los helicópteros).

     `texto` es lo que dice el examinador al pedirla y `bien` al cumplirla.
     En los textos, {nombre} es el nombre del alumno.
   ═══════════════════════════════════════════════════════════════════════ ]]

local P = Vuelo.P
local L = P.L
local E = Vuelo.EnPista
local S = Config.Escuela
local zPista = P.z

Config.Examenes = {}

-- ── BÁSICA · avioneta ─────────────────────────────────────────────────────

Config.Examenes.basica = {
    nombre = 'Práctico · Básica',
    aparato = 'Avioneta',
    modelo = 'cuban800',
    tipo = 'plane',
    salidas = S.salidasAvion,
    nivel = 1,
    precio = 25000,
    tiempo = 14 * 60,
    etapas = {
        { tipo = 'motor', texto = 'Buenas, {nombre}. Hoy vas a volar conmigo. Cuando estés a los mandos, haz las comprobaciones y arranca.' },
        { tipo = 'parar', pos = E(25.0, 0.0), radio = 12.0, rumbo = P.rumbo, seg = 3,
          texto = 'Rueda despacio hasta la marca de la cabecera (en tierra, nunca a más de 45 km/h), alinéate hacia el oeste y detente.',
          bien = 'Pista libre. Autorizada la salida: motor a tope y mantén el eje.' },
        { tipo = 'despegue', antesDe = L - 80.0, agl = 40.0, puntos = 10,
          texto = 'Acelera sin salirte del eje y tira suave de los mandos al pasar de 120 km/h.',
          bien = 'Bien. Sigue subiendo con la nariz suave.' },
        { tipo = 'aro', pos = E(L + 1800.0, 0.0, 200.0), radio = 32.0, sobre = 70.0, puntos = 10,
          texto = 'Sigue recto subiendo: primer aro en la prolongación de la pista. Pásalo por el centro.' },
        { tipo = 'altitud', min = 250.0, max = 420.0, seg = 8, tope = 90, puntos = 5,
          texto = 'Sube a entre 250 y 420 metros y mantente ahí.' },
        { tipo = 'aro', pos = vec3(760.0, 3720.0, 260.0), radio = 30.0, sobre = 80.0, puntos = 10,
          texto = 'Vira a la derecha, hacia el Alamo Sea. Siguiente aro sobre la orilla.' },
        { tipo = 'estable', seg = 12, alto = 35.0, alabeo = 25.0, puntos = 10,
          texto = 'Nivela el avión: doce segundos sin subir ni bajar y con las alas rectas.',
          bien = 'Muy bien, así se vuela recto.' },
        { tipo = 'aro', pos = vec3(1320.0, 4230.0, 240.0), radio = 30.0, sobre = 80.0, puntos = 10,
          texto = 'Siguiente aro sobre el agua.' },
        { tipo = 'aro', pos = vec3(2050.0, 4020.0, 300.0), radio = 30.0, sobre = 90.0, puntos = 10,
          texto = 'Ahora hacia la orilla este.' },
        { tipo = 'aro', pos = vec3(2150.0, 3380.0, 320.0), radio = 30.0, sobre = 100.0, puntos = 10,
          texto = 'Rumbo sur, por el este de Sandy.' },
        { tipo = 'aro', pos = E(L * 0.5, -900.0, 320.0), radio = 32.0, sobre = 100.0, puntos = 10,
          texto = 'Bordeamos el aeródromo por el sur. Vamos a aterrizar hacia el este: busca la cabecera oeste.' },
        { tipo = 'aro', pos = E(L + 1300.0, 0.0, 190.0), radio = 34.0, sobre = 45.0, puntos = 10,
          texto = 'Empezamos la aproximación. Baja por los aros hacia la pista, velocidad moderada.' },
        { tipo = 'aro', pos = E(L + 650.0, 0.0, 120.0), radio = 30.0, sobre = 35.0, puntos = 10,
          texto = 'Sigue bajando. Pista a la vista.' },
        { tipo = 'aro', pos = E(L + 220.0, 0.0, 70.0), radio = 26.0, sobre = 25.0, puntos = 10,
          texto = 'Último aro. Gases atrás poco a poco.' },
        { tipo = 'aterrizar', desde = L * 0.45, hasta = L + 25.0, vzBlanda = 4.5, vzDura = 8.0, puntos = 10,
          texto = 'Toma en la primera mitad de la pista y frena sin salirte.',
          bien = 'Buena toma. Sal de la pista despacio.' },
        { tipo = 'aparcar', pos = S.salidasAvion[1].xyz, radio = 10.0,
          texto = 'Rueda despacio de vuelta a la cabecera este y déjalo donde lo cogiste.' },
        { tipo = 'motor', apagar = true, texto = 'Apaga el motor y hemos terminado.' },
    },
}

-- ── MEDIA · avión ─────────────────────────────────────────────────────────

Config.Examenes.media_avion = {
    nombre = 'Práctico · Media (avión)',
    aparato = 'Reactor ligero',
    modelo = 'vestra',
    tipo = 'plane',
    salidas = S.salidasAvion,
    nivel = 2,
    precio = 45000,
    tiempo = 16 * 60,
    etapas = {
        { tipo = 'motor', texto = '{nombre}, este ya no es una avioneta: tren retráctil y mucha más velocidad. Arranca cuando estés.' },
        { tipo = 'parar', pos = E(25.0, 0.0), radio = 12.0, rumbo = P.rumbo, seg = 3,
          texto = 'Suave con los gases, que empuja mucho. A la marca de la cabecera, alineado hacia el oeste, y quieto.',
          bien = 'Autorizado. Salida hacia el oeste.' },
        { tipo = 'despegue', antesDe = L - 120.0, agl = 50.0, puntos = 10,
          texto = 'Despega. En este tienes menos pista de la que parece: rota a tiempo.' },
        { tipo = 'tren', arriba = true, seg = 25, puntos = 5,
          texto = 'Tren arriba.', bien = 'Tren arriba, correcto.' },
        { tipo = 'aro', pos = E(L + 2000.0, 0.0, 280.0), radio = 26.0, sobre = 80.0, puntos = 10,
          texto = 'Sigue recto subiendo: aro en la prolongación de la pista.' },
        { tipo = 'altitud', min = 380.0, max = 600.0, seg = 8, tope = 80, puntos = 5,
          texto = 'Sube a entre 380 y 600 metros.' },
        { tipo = 'aro', pos = vec3(2080.0, 4780.0, 380.0), radio = 24.0, sobre = 100.0, puntos = 10,
          texto = 'Navegación: rumbo norte, a la vertical de Grapeseed.' },
        { tipo = 'viraje', seg = 50, alto = 60.0, puntos = 10,
          texto = 'Viraje completo de 360 grados, sin perder ni ganar más de 60 metros.',
          bien = 'Buen viraje, bien coordinado.' },
        { tipo = 'aro', pos = vec3(1330.0, 4250.0, 300.0), radio = 24.0, sobre = 90.0, puntos = 10,
          texto = 'Ahora al suroeste, sobre el Alamo Sea.' },
        { tipo = 'estable', seg = 15, alto = 30.0, alabeo = 20.0, puntos = 10,
          texto = 'Quince segundos recto y nivelado.' },
        { tipo = 'aro', pos = E(L + 900.0, 0.0, 160.0), radio = 26.0, sobre = 45.0, puntos = 10,
          texto = 'Vamos a hacer una pasada baja sobre la pista, de oeste a este. Colócate en la prolongación.' },
        { tipo = 'pasada', pos = E(L * 0.5, 0.0, zPista + 30.0), radio = 30.0, min = 10.0, max = 60.0, puntos = 15,
          texto = 'Pasada baja: entre 10 y 60 metros sobre la pista, sin tocarla.',
          bien = 'Pasada limpia. Sube y prepárate para una toma y despegue.' },
        { tipo = 'aro', pos = E(-900.0, 0.0, 250.0), radio = 28.0, sobre = 70.0, puntos = 10,
          texto = 'Sube y sigue al este.' },
        { tipo = 'aro', pos = E(L * 0.5, -850.0, 300.0), radio = 28.0, sobre = 90.0, puntos = 10,
          texto = 'Vuelta por el sur, paralelo a la pista.' },
        { tipo = 'aro', pos = E(L + 1200.0, 0.0, 180.0), radio = 30.0, sobre = 45.0, puntos = 10,
          texto = 'Aproximación por el oeste.' },
        { tipo = 'tren', arriba = false, seg = 30, puntos = 10,
          texto = 'Tren abajo antes de seguir bajando.', bien = 'Tres verdes. Tren abajo.' },
        { tipo = 'toque', desde = L * 0.3, hasta = L + 20.0, vzMax = 5.0, puntos = 10,
          texto = 'Toma y despegue: toca la pista y vuelve a subir sin parar.',
          bien = 'Buen toque. Arriba otra vez.' },
        { tipo = 'aro', pos = E(-900.0, 0.0, 220.0), radio = 28.0, sobre = 70.0, puntos = 10,
          texto = 'Sube por el este.' },
        { tipo = 'aro', pos = E(L * 0.5, -850.0, 280.0), radio = 28.0, sobre = 90.0, puntos = 10,
          texto = 'Otra vez por el sur.' },
        { tipo = 'aro', pos = E(L + 1200.0, 0.0, 180.0), radio = 30.0, sobre = 45.0, puntos = 10,
          texto = 'Aproximación final.' },
        { tipo = 'aro', pos = E(L + 500.0, 0.0, 100.0), radio = 26.0, sobre = 30.0, puntos = 10,
          texto = 'Sigue bajando.' },
        { tipo = 'aterrizar', desde = L * 0.5, hasta = L + 25.0, vzBlanda = 4.0, vzDura = 7.5, puntos = 10,
          texto = 'Aterriza en la primera mitad y frena.',
          bien = 'Toma correcta.' },
        { tipo = 'aparcar', pos = S.salidasAvion[1].xyz, radio = 10.0,
          texto = 'Vuelve rodando a la cabecera este y aparca donde estaba.' },
        { tipo = 'motor', apagar = true, texto = 'Motor apagado y listo.' },
    },
}

-- ── MEDIA · helicóptero ───────────────────────────────────────────────────

Config.Examenes.media_heli = {
    nombre = 'Práctico · Media (helicóptero)',
    aparato = 'Helicóptero',
    modelo = 'frogger',
    tipo = 'heli',
    salidas = S.salidasHeli,
    nivel = 2,
    precio = 45000,
    tiempo = 14 * 60,
    etapas = {
        { tipo = 'motor', texto = 'Helicóptero, {nombre}. Aquí todo es suavidad. Arranca y espera a que el rotor coja vueltas.' },
        { tipo = 'estacionario', pos = S.salidasHeli[1].xyz, radio = 10.0, min = 4.0, max = 12.0, seg = 8, puntos = 10,
          texto = 'Despega en vertical y quédate quieto entre 4 y 12 metros sobre la plataforma.',
          bien = 'Buen estacionario.' },
        { tipo = 'aro', pos = E(100.0, 350.0), agl = 50.0, radio = 18.0, puntos = 10,
          texto = 'Vuelo bajo. Primer aro al norte de la pista.' },
        { tipo = 'aro', pos = vec3(1880.0, 3620.0, 0.0), agl = 60.0, radio = 18.0, puntos = 10,
          texto = 'Sobre Sandy Shores. Cuidado con los postes y los tejados.' },
        { tipo = 'aro', pos = vec3(2000.0, 3900.0, 0.0), agl = 50.0, radio = 18.0, puntos = 10,
          texto = 'Siguiente, hacia la orilla.' },
        { tipo = 'aro', pos = E(L * 0.3, 450.0), agl = 45.0, radio = 18.0, puntos = 10,
          texto = 'Vuelve hacia el aeródromo por el norte.' },
        { tipo = 'tomar', pos = E(L * 0.6, 0.0), radio = 5.0, vzMax = 2.5, puntos = 15,
          texto = 'Toma de precisión: posa el helicóptero dentro de la marca de la pista, muy suave.',
          bien = 'Dentro de la marca. Bien.' },
        { tipo = 'estacionario', pos = E(L * 0.6, 0.0), radio = 8.0, min = 8.0, max = 20.0, seg = 10, puntos = 10,
          texto = 'Sube a entre 8 y 20 metros y aguanta quieto sobre la marca.' },
        { tipo = 'aro', pos = E(L + 400.0, -300.0), agl = 70.0, radio = 18.0, puntos = 10,
          texto = 'Al oeste, pasado el final de la pista.' },
        { tipo = 'aro', pos = E(L * 0.5, -500.0), agl = 60.0, radio = 18.0, puntos = 10,
          texto = 'Por el sur, en paralelo a la pista.' },
        { tipo = 'aro', pos = E(-100.0, 120.0), agl = 35.0, radio = 16.0, puntos = 10,
          texto = 'Aproximación a la plataforma, bajando.' },
        { tipo = 'tomar', pos = S.salidasHeli[1].xyz, radio = 5.0, vzMax = 2.5, puntos = 15,
          texto = 'Posa el helicóptero en la plataforma de salida.' },
        { tipo = 'motor', apagar = true, texto = 'Apaga el motor y terminamos.' },
    },
}

-- ── ALTA · reactor ────────────────────────────────────────────────────────

Config.Examenes.alta = {
    nombre = 'Práctico · Alta',
    aparato = 'Reactor ejecutivo',
    modelo = 'luxor',
    tipo = 'plane',
    salidas = S.salidasAvion,
    nivel = 3,
    precio = 90000,
    tiempo = 20 * 60,
    etapas = {
        { tipo = 'motor', texto = '{nombre}, examen de licencia alta. Voy a ser exigente con las alturas y las tomas. Arranca.' },
        { tipo = 'parar', pos = E(25.0, 0.0), radio = 12.0, rumbo = P.rumbo, seg = 3,
          texto = 'Es un avión grande: rueda despacio hasta la marca, alineado hacia el oeste, y quieto.',
          bien = 'Autorizado. Pista corta para este aparato: todo el empuje desde el principio.' },
        { tipo = 'despegue', antesDe = L - 150.0, agl = 60.0, puntos = 10,
          texto = 'Despega.' },
        { tipo = 'tren', arriba = true, seg = 20, puntos = 5, texto = 'Tren arriba.' },
        { tipo = 'aro', pos = E(L + 2200.0, 0.0, 350.0), radio = 22.0, sobre = 90.0, puntos = 10,
          texto = 'Aro de salida, en la prolongación de la pista. Sigue subiendo.' },
        { tipo = 'altitud', min = 600.0, max = 900.0, seg = 10, tope = 120, puntos = 5,
          texto = 'Sube a entre 600 y 900 metros.' },
        { tipo = 'aro', pos = vec3(2100.0, 4800.0, 600.0), radio = 20.0, sobre = 120.0, puntos = 10,
          texto = 'Navegación a Grapeseed.' },
        { tipo = 'aro', pos = vec3(480.0, 5580.0, 1000.0), radio = 22.0, sobre = 120.0, puntos = 10,
          texto = 'Ahora a la cima del Chiliad. Mantén margen con el monte.' },
        { tipo = 'estable', seg = 20, alto = 25.0, alabeo = 18.0, puntos = 10,
          texto = 'Veinte segundos nivelado y recto.' },
        { tipo = 'viraje', seg = 60, alto = 50.0, puntos = 10,
          texto = 'Viraje completo de 360 grados. Tolerancia: 50 metros.' },
        { tipo = 'aro', pos = vec3(1000.0, 4600.0, 450.0), radio = 20.0, sobre = 90.0, puntos = 10,
          texto = 'Descenso hacia el Alamo Sea.' },
        { tipo = 'aro', pos = vec3(700.0, 3700.0, 300.0), radio = 20.0, sobre = 80.0, puntos = 10,
          texto = 'Sigue al sur.' },
        { tipo = 'aro', pos = E(L + 1000.0, 0.0, 170.0), radio = 22.0, sobre = 45.0, puntos = 10,
          texto = 'Pasada baja sobre la pista, de oeste a este. Colócate.' },
        { tipo = 'pasada', pos = E(L * 0.5, 0.0, zPista + 25.0), radio = 25.0, min = 10.0, max = 45.0, puntos = 15,
          texto = 'Pasada: entre 10 y 45 metros sobre la pista, sin tocar.' },
        { tipo = 'aro', pos = E(-900.0, 0.0, 250.0), radio = 22.0, sobre = 70.0, puntos = 10,
          texto = 'Sube por el este.' },
        { tipo = 'aro', pos = E(L * 0.5, -900.0, 300.0), radio = 22.0, sobre = 90.0, puntos = 10,
          texto = 'Circuito por el sur.' },
        { tipo = 'tren', arriba = false, seg = 30, puntos = 10, texto = 'Tren abajo.' },
        { tipo = 'aro', pos = E(L + 1400.0, 0.0, 200.0), radio = 24.0, sobre = 45.0, puntos = 10,
          texto = 'Aproximación final. Estabiliza pronto.' },
        { tipo = 'aro', pos = E(L + 700.0, 0.0, 125.0), radio = 22.0, sobre = 35.0, puntos = 10,
          texto = 'Sigue la senda.' },
        { tipo = 'aro', pos = E(L + 250.0, 0.0, 70.0), radio = 20.0, sobre = 25.0, puntos = 10,
          texto = 'Cruzando el umbral.' },
        { tipo = 'aterrizar', desde = L * 0.6, hasta = L + 20.0, vzBlanda = 3.5, vzDura = 7.0, puntos = 15,
          texto = 'Toma en el primer tercio. Frena a fondo.',
          bien = 'Buena toma.' },
        { tipo = 'aparcar', pos = S.salidasAvion[1].xyz, radio = 12.0, texto = 'Rueda de vuelta a la cabecera este y aparca donde estaba.' },
        { tipo = 'motor', apagar = true, texto = 'Apaga y hemos terminado.' },
    },
}

--- En qué nivel se hace cada práctico y en qué orden salen en la pantalla.
Config.OrdenExamenes = { 'basica', 'media_avion', 'media_heli', 'alta' }

for id, ex in pairs(Config.Examenes) do ex.id = id end
