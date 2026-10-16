--[[ REGLA DE DISENO: ningun efecto puede matar al jugador ni tirarlo del mapa.
     Por eso ninguna rama toca la salud del motor ni el nivel de combustible
     (`vehiclehandler` deja el coche inconducible para siempre si los ve por
     debajo de su umbral), ninguna sube la escala de direccion, y los cortes de
     motor son cortos: el coche rueda y sigue frenando y girando. ]]
Config.Malfunctions = {
    Enabled = true,

    --- Cada cuántos segundos se intenta lanzar una avería mientras se conduce.
    IntervalSeconds = 25,

    --[[ Un coche parado no se averia: un corte de motor en el ralenti no se lee
         como averia, se lee como bug. ]]
    MinSpeedKmh = 20.0,

    --[[ En el aire el jugador no controla nada; quitarle potencia o frenos
         durante un salto es una muerte injusta, no una averia. ]]
    SkipWhileAirborne = true,

    Notify = true,

    --- Probabilidad de que el intento de avería se materialice, por condición.
    Chance = {
        [Mechanic.ComponentCondition.WORN] = 0.35,
        [Mechanic.ComponentCondition.CRITICAL] = 0.80
    },

    --[[ Aviso de servicio vencido mientras se conduce. Es la unica pista que
         tiene el jugador antes de que la cascada le rompa la pieza. ]]
    OverdueWarnMs = 180000
}

Config.EngineLock = {
    Enabled = true,

    --[[ GTA vuelve a arrancar el motor sola cada vez que el jugador lo intenta,
         asi que el bloqueo hay que reafirmarlo en bucle mientras dure. ]]
    EnforceMs = 250,
    NotifyMs = 30000
}

--[[ Valores de arranque. Los de t1ger van entre parentesis donde se han
     suavizado a proposito. ]]
Config.MalfunctionEffects = {
    motor = {
        [Mechanic.ComponentCondition.WORN] = { cycles = 4, power = -25.0, cutMs = 220, restMs = 700 },
        [Mechanic.ComponentCondition.CRITICAL] = { cycles = 8, power = -60.0, cutMs = 350, restMs = 600, temperature = 140.0 }
    },
    transmision = {
        [Mechanic.ComponentCondition.WORN] = { duration = 5000, clutchScale = 0.15, power = -15.0 },
        [Mechanic.ComponentCondition.CRITICAL] = { duration = 9000, clutchScale = 0.08, power = -35.0 }
    },
    frenos = {
        --[[ Multiplicador de la fuerza de frenada ORIGINAL, no un valor absoluto
             como hace t1ger (0.2 / 0.1 fijos): un camion y un deportivo no
             arrancan del mismo `fBrakeForce` y fijarlo deja a unos sin frenos y
             a otros sin enterarse. El suelo de 0.45 sigue frenando el coche. ]]
        [Mechanic.ComponentCondition.WORN] = { duration = 4000, brakeScale = 0.65 },
        [Mechanic.ComponentCondition.CRITICAL] = { duration = 8000, brakeScale = 0.45 }
    },
    refrigeracion = {
        [Mechanic.ComponentCondition.WORN] = { duration = 6000, temperature = 150.0 },
        [Mechanic.ComponentCondition.CRITICAL] = { duration = 12000, temperature = 200.0, engineOffMs = 4000 }
    },
    inyeccion = {
        [Mechanic.ComponentCondition.WORN] = { cycles = 5, power = -30.0, cutMs = 300, restMs = 400 },
        [Mechanic.ComponentCondition.CRITICAL] = { cycles = 12, power = -65.0, cutMs = 400, restMs = 300 }
    },
    direccion = {
        [Mechanic.ComponentCondition.WORN] = { duration = 4000, steeringScale = 0.70 },
        [Mechanic.ComponentCondition.CRITICAL] = { duration = 7000, steeringScale = 0.50 }
    },
    alternador = {
        [Mechanic.ComponentCondition.WORN] = { cycles = 4, engineOffMs = 600, engineOnMs = 500, lights = true },
        [Mechanic.ComponentCondition.CRITICAL] = { engineOffMs = 5000, lights = true }
    },
    suspension = {
        --[[ El agarre se toca poco a proposito: perder traccion a 150 km/h es un
             trompo, y un trompo es una muerte. Se busca que el coche flote y
             rebote, no que se vaya. ]]
        [Mechanic.ComponentCondition.WORN] = { duration = 6000, tractionScale = 0.90, reboundScale = 0.70 },
        [Mechanic.ComponentCondition.CRITICAL] = { duration = 10000, tractionScale = 0.80, reboundScale = 0.55 }
    },
    motor_electrico = {
        [Mechanic.ComponentCondition.WORN] = { cycles = 5, power = -45.0, cutMs = 300, restMs = 500 },
        [Mechanic.ComponentCondition.CRITICAL] = { engineOffMs = 4000, lights = true }
    },
    bateria_ev = {
        [Mechanic.ComponentCondition.WORN] = { duration = 6000, power = -50.0 },
        [Mechanic.ComponentCondition.CRITICAL] = { duration = 10000, power = -90.0 }
    }
}
