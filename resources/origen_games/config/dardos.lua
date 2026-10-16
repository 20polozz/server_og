--[[ ── Origen Games · dardos ───────────────────────────────────────────────

     No va como los demás juegos. No hay salas en un punto del mapa ni zonas
     del staff, ni teletransporte ni mundo aparte: se juega en CUALQUIER diana
     (las del mapa y las que alguien cuelgue de mueble en su casa), en el sitio
     y en el mundo en el que está cada uno. Del núcleo usa el ranking y el HUD.

     No entra en Config.Orden a propósito: así los menús de salas y zonas no
     lo listan, pero el ranking (Datos.Juego) sí lo reconoce. ]]

Config.Juegos.dardos = {
    id = 'dardos',
    nombre = 'Dardos',
    lema = 'Como en el Yellow Jack',
    icono = 'diana',
    destacado = 'dianas',

    jugadoresMax = 4,
    dardosPorTurno = 3,
    segundosTurno = 40,        -- quien no tira a tiempo pierde lo que le quede del turno
    pausaRecoger = 2.5,        -- entre turnos, mientras se recogen los dardos
    esperaMaxima = 300,        -- una mesa sin empezar se deshace a los 5 min
    alcance = 2.6,             -- a cuánto de la diana sale el [E]
    alcanceMesa = 12.0,        -- quien se aleja más se va de la mesa
    distanciaTiro = 2.37,      -- la raya de tiro reglamentaria

    modos = {
        { id = '301', nombre = '301', texto = 'Baja de 301 a cero. Hay que cerrar con un doble o la diana.', inicio = 301 },
        { id = '501', nombre = '501', texto = 'Igual, desde 501. Partida más larga.', inicio = 501 },
        { id = 'reloj', nombre = 'Vuelta al reloj', texto = 'Del 1 al 20 en orden y cierra en la diana.' },
        { id = 'entreno', nombre = 'Entrenamiento', texto = 'Tú solo: 10 turnos, suma todo lo que puedas.', solo = true, turnos = 10 },
    },

    --[[ Las dianas que se reconocen. `centro` es dónde cae la diana (el 50)
         respecto al origen del modelo, `cara` hacia qué lado del eje Y del
         modelo mira la cara (-1 o 1) y `escala` cuántos metros del modelo son
         un metro de una diana de verdad (la del juego es algo más grande).
         Medido en el juego con fotos de frente. ]]
    modelos = {
        -- Medido 25/09 con dos fotos de frente a 1,0 y 1,6 m: las dos llevan la
        -- misma diana, 1,31 veces la reglamentaria (dobles a 22,3 cm).
        prop_dart_bd_01 = { centro = vector3(-0.004, -0.061, -0.001), cara = -1, escala = 1.31 },
        prop_dart_bd_cab_01 = { centro = vector3(-0.004, -0.079, -0.001), cara = -1, escala = 1.31 },
    },

    --[[ El pulso. La mira se mueve sola (dos senos por eje, para que no se
         aprenda el ritmo); aguantar la respiración la calma, pero se agota y
         después tiembla más hasta recuperarse. En metros de la diana. ]]
    pulso = {
        normal = 0.030,
        aguantando = 0.007,
        cansado = 0.045,
        aguante = 3.5,         -- segundos de respiración aguantada
        recuperar = 2.0,       -- segundos para recuperar todo el aire
        dispersion = 0.005,    -- lo que se desvía el dardo al soltarlo
    },

    teclas = {
        lanzar = { control = 24, texto = 'Clic' },
        aguantar = { control = 25, texto = 'Clic dcho.' },
        entrar = { control = 38, texto = 'E' },
        salir = { control = 23, texto = 'F' },   -- mantener
    },

    -- El ranking: puntos por partida con rivales (el entrenamiento no cuenta).
    puntosVictoria = 10,
    puntosPartida = 2,
}
