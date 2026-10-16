Config.Cascade = {
    Enabled = true,

    --[[ CALIBRACION. t1ger degrada un 0,5 % de la salud actual por cada segundo
         conduciendo con el servicio vencido, lo que funde un motor en pocos
         minutos de conduccion lenta y en muchos mas de conduccion rapida: el
         castigo depende del tiempo al volante, no del uso real del coche.

         Aqui el ratio es por KILOMETRO recorrido y no por segundo. El resultado
         no depende de la velocidad ni de cada cuanto sincroniza el cliente, y el
         coste es cero threads nuevos porque se engancha al kilometraje que ya
         suma el servidor.

         0.15 %/km con un servicio vencido: 100 -> 86 a los 100 km, -> 47 a los
         500 km, -> 22 (Critico) a los 1.000 km, -> 5 a los 2.000 km. Con varios
         servicios vencidos que protegen la misma pieza el efecto se acumula.
         Subir este numero endurece el sistema de forma exponencial. ]]
    RatePerKm = 0.15,

    --[[ La curva exponencial tiende a cero pero nunca lo alcanza, asi que sin
         este suelo ninguna pieza llegaria jamas al estado Averiado. ]]
    FloorHealth = 1.0,

    --[[ Un sync con un salto de kilometraje anormalmente grande (lag, reconexion)
         no debe fundir la pieza de golpe. ]]
    MaxKmPerStep = 2.0
}

Config.Collision = {
    Enabled = true,

    --[[ Velocidad PERDIDA en el impacto, en km/h (antes: la que se llevaba).
         `vehiclehandler` trabaja en las unidades de su propia config, la
         conversion se hace en el hook.

         25/09: con la velocidad previa, 40 km/h y cualquier rasguño de chapa, un
         viaje Paleto-ciudad rozando algo cada 5 s se comia 2 piezas un 5-15 %
         por roce y los jugadores pagaban 5-20k al dia de taller. Ahora un roce
         no cuenta; un choque de verdad toca una pieza, y mas cuanto mas fuerte. ]]
    MinImpactSpeedKmh = 25.0,
    --- A partir de aqui el golpe ya quita el MaxPercent entero.
    SevereImpactKmh = 90.0,
    MaxImpactSpeedKmh = 400.0,

    CooldownMs = 10000,
    ComponentCount = 1,

    --- Porcentaje de la salud ACTUAL que pierde la pieza tocada, segun lo fuerte del golpe.
    MinPercent = 3,
    MaxPercent = 12
}
