return {
    dui = {
        width = 512,
        height = 1024
    },

    --[[ El diseño del cartel de checkpoint (source-ui/src/views/Checkpoint.vue):
           0  clasico    el de papel crema de siempre
           1  portico    arco de salida: bandera a cuadros, marcador negro, dos patas
           2  dorsal     placa de numero de coche de carreras
           3  chevrones  panel de curva con galones hacia donde sigue el trazado
           4  neon       telemetria: panel oscuro, filo rosa encendido, barra de aproximacion
           5  limpio     sin fondo: cifra, raya rosa, rotulo y un hilo hasta el suelo
         Cambiarlo pide reiniciar el recurso. ]]
    checkpointEstilo = 5,

    defaults = {
        drawDistance = 500.0,
        fadeDistance = 400.0,
        size = 1.0,

        minHeight = 5.0,
        maxHeight = 50.0,
        groundZOffset = -2.0,
    },

    rendering = {
        updateInterval = 100,

        distanceUpdateInterval = 1,

        --[[ Cuanto ocupa el cartel en pantalla: ancho = size x 4 / este numero,
             en radianes, y el alto el doble. Con 90, el cartel grande (size
             2.5) mide unos 6 grados de ancho y su rotulo queda a unos 12 del
             suelo. Mas pequeño el numero, mas grande y MAS ALTO el cartel. ]]
        perspectiveDivisor = 90.0,

        checkpointBaseMultiplier = 4.0,
        -- El ancho minimo, en metros, cuando ya estas al lado (alto, el doble).
        checkpointMinSize = 2.4,
        checkpointAspectRatio = 2.0,
    }
}