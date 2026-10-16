--[[ ── Derbi · el último coche en marcha gana ─────────────────────────────── ]]

local D = {}

D.id = 'derbi'
D.nombre = 'Derbi'
D.lema = 'El último coche en marcha gana'
D.icono = 'coche'
--- El dibujo de su chincheta en los dos mapas (origen_map e inventario).
D.iconoMapa = 'coche'

D.jugadoresMin = 2
D.jugadoresMax = 12
D.rondas = { 1, 3, 5 }
D.rondasDefecto = 3

D.modos = nil

D.punto = { x = -276.0, y = -2025.0, z = 30.15 }
--- Un derbi necesita sitio despejado: el aparcamiento junto al Maze Bank
--- Arena. El staff debería revisarla y moverla a su gusto.
D.zonaSemilla = { nombre = 'Aparcamiento del Maze Bank Arena', x = -280.7, y = -2030.83, z = 30.15, radio = 60.0 }

--- Los coches que se pueden elegir en una zona. Nada deportivo: tienen que
--- aguantar golpes y no salir volando.
D.Coches = {
    { id = 'issi2', nombre = 'Issi' },
    { id = 'blista', nombre = 'Blista' },
    { id = 'panto', nombre = 'Panto' },
    { id = 'rhapsody', nombre = 'Rhapsody' },
    { id = 'emperor', nombre = 'Emperor' },
    { id = 'tornado', nombre = 'Tornado' },
}

D.campos = {
    { id = 'vehiculo', nombre = 'Coche', tipo = 'opciones', opciones = D.Coches, defecto = 'issi2' },
    { id = 'duracion', nombre = 'Tiempo máximo de ronda', tipo = 'rango', min = 60, max = 480, paso = 15, defecto = 240, formato = 'reloj' },
}

D.destacado = 'eliminaciones'

D.Vida = {
    motorMuerto = 150.0,        -- por debajo de esta salud de motor el coche queda fuera
    carroceriaMuerta = 150.0,
    fueraDeZonaPorSegundo = 60.0, -- daño al motor por segundo fuera de la zona
    volcadoSegundos = 6,        -- volcado tanto tiempo = fuera
    deLadoSegundos = 10,        -- tumbado de lado y parado tanto tiempo = fuera
    creditoGolpe = 3,           -- segundos que cuenta un golpe para dar la eliminación
    fueraDelCoche = 3,          -- segundos fuera de tu coche antes de volver a meterte
    fueraDelCocheMax = 9,       -- y a estos, si sigues fuera, eliminado
    sinCocheMax = 15,           -- segundos de derbi sin que tu coche llegue a aparecer
}

--- Los choques. El cliente de quien embiste avisa; el servidor lo comprueba
--- con sus propias posiciones y velocidades.
D.Golpe = {
    distancia = 5.0,            -- metros máximos entre los centros de los dos coches (servidor)
    velocidadMin = 4.0,         -- m/s mínimos del coche que embiste (servidor)
    cadaVictima = 2,            -- segundos entre golpes que cuentan del mismo al mismo
    -- Un aviso de golpe queda pendiente y solo cuenta si en este margen la
    -- víctima también avisa del choque o su motor/carrocería (leídos en el
    -- servidor) bajan al menos `bajadaMin`.
    confirmarMs = 600,
    bajadaMin = 5.0,
    -- La vida lógica del servidor (empieza en 1000) baja por golpe validado
    -- el daño extra más esto, y fuera de la zona lo mismo que el motor.
    vidaLogicaBase = 30.0,
    -- Daño de motor extra que se quita la víctima en su propio coche, para que
    -- las rondas no se eternicen: minimo + (velocidad - velocidadMin) * porMs.
    danoMin = 20.0,
    danoPorMs = 5.0,
    danoMax = 110.0,
}

--- El coche de cada ronda: cuánto espera el cliente a que aparezca antes de
--- pedir otro, y cuántas veces se puede volver a crear.
D.Coche = { espera = 8, reintentos = 3, borrarTras = 4 }

D.Puntos = {
    eliminar = 10,
    sobrevivir = 15,
    golpe = 1,
}

D.Teclas = {
    turbo = { control = 21, texto = 'Shift' },
}

--- fuerza: aceleración que empuja hacia delante (m/s² aprox.). tope: cuánto
--- puede subir la velocidad sobre la que llevabas y el máximo absoluto (m/s),
--- para que nadie salga volando ni pase por lo que el anticheat mira.
D.Turbo = { segundos = 2, enfriamiento = 15, fuerza = 18.0, subida = 14.0, maxima = 42.0 }

D.ayuda = {
    {
        titulo = 'Cómo va',
        texto = 'Todos salen con el mismo coche mirando al centro. Choca contra los demás hasta dejarles el motor muerto. Si tu coche se rompe, vuelcas demasiado rato o te sales de la zona, estás fuera. Gana el último coche en marcha.',
    },
    {
        titulo = 'Teclas',
        teclas = {
            { tecla = 'Shift', texto = 'Turbo: un empujón hacia delante. Tiene recarga.' },
            { tecla = 'E', texto = 'Claxon, para que te oigan venir.' },
        },
        nota = 'No se puede salir del coche. Fuera de la zona el motor se va rompiendo solo, y un golpe fuerte también te lo toca.',
    },
    {
        titulo = 'Puntos',
        datos = { { k = 'Eliminar', v = '+10' }, { k = 'Sobrevivir', v = '+15' }, { k = 'Golpe', v = '+1' } },
    },
}

Config.Juegos.derbi = D
