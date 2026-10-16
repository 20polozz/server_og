--[[ ══ La camara ════════════════════════════════════════════════════════════

     Todos los numeros del plano, aparte, para poder recargarlos en caliente
     con un `ensure origen_intro` mientras se ajusta el encuadre.

     La camara empieza alta y detras del coche y va cayendo hasta quedar donde
     estaria la camara normal del juego. Altura y retirada no se interpolan en
     linea recta sino en proporcion (a * (b/a)^t): el ojo percibe las alturas
     como razones, y una bajada lineal de 150 m a 2 m parece desplomarse al
     principio y arrastrarse al final. ]]

Config.Camara = {
    alturaInicial   = 150.0,
    retiradaInicial = 60.0,

    --[[ Solo se usan como respaldo. El tramo final no calcula donde acabar:
         lee donde esta de verdad la camara del juego y converge a ella. ]]
    alturaFinal   = 2.1,
    retiradaFinal = 6.0,

    --- Se mira algo por encima del centro del coche, no a sus ruedas.
    alturaMira = 0.9,

    fovInicial = 60.0,
    fovFinal   = 50.0,

    --[[ Cuanto persigue la camara al rumbo del coche. Arriba va suelta -- a
         150 m el rumbo casi da igual y seguirlo al instante daria un latigazo
         en cada curva -- y abajo va pegada detras, para que la entrega cuadre. ]]
    kMin = 0.45,
    kMax = 3.5,

    --- Cuanto tarda la camara en fundirse con la del juego, y el relevo final.
    aterrizaje = 2200,
    entrega    = 700,

    --[[ El suelo temporal del progreso -- lo que completa el plano si el coche
         se atasca -- ya no vive aqui: depende de lo larga que sea cada ruta.
         Ver Config.Ritmo y shared/ritmo.lua. ]]

    --- Fundidos de entrada y salida.
    telon    = 400,
    apertura = 700,
}
