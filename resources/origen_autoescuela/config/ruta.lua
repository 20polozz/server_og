--[[ ═══════════════════════════════════════════════════════════════════════
     LOS RECORRIDOS DEL EXAMEN

     VARIOS a propósito: con un solo recorrido, a la semana se lo saben de
     memoria y el examen deja de medir nada. El servidor elige uno al azar
     cada vez que alguien empieza el práctico, y el alumno no sabe cuál le va
     a tocar hasta que arranca.

     Los puntos están pegados a la calzada de verdad: los saca el banco de
     pruebas saltando de nodo de carretera en nodo de carretera desde la
     autoescuela (`autoescuela_orden <nombre> ruta 16`, escribe
     prueba/ruta.txt) y se pegan aquí. No se escriben a mano: un punto a ojo
     cae en una acera.

     De cada punto: `pos` (obligatorio), `limite` de velocidad del tramo que
     TERMINA ahí (si no, Config.Limite) y `stop = true` si hay que detenerse
     del todo antes de llegar. El giro —izquierda, derecha o recto— NO se
     escribe: sale de la geometría de la propia ruta (Auto.Giro).
   ═══════════════════════════════════════════════════════════════════════ ]]

--[[ Siete puntos movidos el 20/09 (A10, B9, B11, C7, C9, C10 y C12).

     Todos estaban encima de un nodo de carretera y aun así la línea del GPS
     se quedaba entre 21 y 50 m antes: nodos a los que el juego no sabe llegar
     —medianas, carriles separados, enlaces—. No se ve midiendo distancias: hay
     que poner una ruta de verdad y mirar dónde acaba el camino
     (prueba/rutatodos.lua para encontrarlos, prueba/arreglatodos.lua para
     buscarles sitio). ]]

--- Velocidad por defecto en ciudad.
Config.Limite = 50.0

--[[ Los recorridos. Mientras estén vacíos, el práctico no se puede empezar y
     el panel lo dice: hay que generarlos en el juego. ]]
--[[ Rutas por las que NO se manda al camión.

     El del examen (mule) mide 3,75 m de alto, y medido en el juego el 20/09
     (prueba/techos.lua, pegándose a los nodos de la calzada) la ruta A pasa
     por un tramo con 2,93 m de hueco: el alumno se quedaba encajado debajo.
     Coche y moto siguen usándola. ]]
Config.RutasSinCamion = { A = true }

--[[ Un recorrido por carné, y solo uno (20/09, decisión del usuario: «pon un
     recorrido de cada solo, porque si no vamos a tener que comprobar
     muchos»).

     El coche se lleva el largo —C, quince puntos—, que es el que tiene que
     ser difícil; la moto va por A, que además recorta al 60 %; y el camión
     por B, porque por A no cabe (ver arriba).

     Lo que se pierde: con un solo recorrido, a la semana se lo saben. El
     teórico sigue cambiando de preguntas cada vez. Si algún día se quiere
     volver a sortear, basta con dejar esta tabla vacía: entonces cada examen
     usa todos los recorridos que le valgan. ]]
Config.RutaDe = { coche = 'C', moto = 'A', camion = 'B' }

Config.Rutas = {
    -- A: la vuelta a la manzana grande por el oeste
    A = {
    { pos = vec3(-160.50, -368.75, 32.56) },   -- 1  a 191 m de la autoescuela
    { pos = vec3(-334.75, -295.25, 30.59) },   -- 2  a 380 m de la autoescuela
    { pos = vec3(-462.00, -221.50, 35.22) },   -- 3  a 526 m de la autoescuela
    { pos = vec3(-374.00, -72.25, 44.66), stop = true },   -- 4  a 534 m de la autoescuela
    --[[ Movido 28 m el 20/09: en el de antes (-277.00, 68.50) la línea del
         GPS se quedaba SIEMPRE a 37 m, y el alumno veía la ruta cortarse
         antes de llegar. Es un nodo al que el juego no sabe llegar —pasa en
         medianas y carriles separados—; la distancia al nodo no lo delata
         (estaba encima de uno), hay que probar la ruta de verdad con un blip
         puesto y midiendo dónde acaba (prueba/arreglapunto.lua). ]]
    { pos = vec3(-248.75, 68.25, 64.03) },   -- 5  a 584 m de la autoescuela
    { pos = vec3(-177.75, 249.75, 91.91) },   -- 6  a 714 m de la autoescuela
    { pos = vec3(-4.00, 154.50, 92.31) },   -- 7  a 592 m de la autoescuela
    { pos = vec3(162.50, 63.75, 79.34), stop = true },   -- 8  a 521 m de la autoescuela
    { pos = vec3(311.25, -13.75, 76.62) },   -- 9  a 515 m de la autoescuela
    { pos = vec3(249.00, -169.75, 57.81) },   -- 10  a 340 m de la autoescuela
    { pos = vec3(148.25, -331.25, 43.59) },   -- 11  a 166 m de la autoescuela
    { pos = vec3(61.00, -495.75, 33.06), stop = true },   -- 12  a 75 m de la autoescuela
    { pos = vec3(-23.00, -396.25, 38.59) },   -- vuelta a la autoescuela (la calle de delante del parking)
    },
    -- B: baja hacia el sur y vuelve por Vespucci
    B = {
    { pos = vec3(-168.50, -361.50, 32.06) },   -- 1  a 201 m de la autoescuela
    { pos = vec3(-361.75, -275.50, 32.53) },   -- 2  a 412 m de la autoescuela
    { pos = vec3(-557.50, -153.50, 37.19) },   -- 3  a 641 m de la autoescuela
    { pos = vec3(-669.25, -367.25, 33.62), stop = true },   -- 4  a 691 m de la autoescuela
    { pos = vec3(-768.75, -547.75, 25.97) },   -- 5  a 795 m de la autoescuela
    { pos = vec3(-859.50, -736.00, 23.72) },   -- 6  a 928 m de la autoescuela
    { pos = vec3(-661.25, -836.50, 23.50) },   -- 7  a 789 m de la autoescuela
    { pos = vec3(-484.50, -930.00, 22.94), stop = true },   -- 8  a 706 m de la autoescuela
    { pos = vec3(-247.50, -1058.75, 25.59) },   -- 9  a 667 m de la autoescuela
    { pos = vec3(-163.25, -827.25, 30.06) },   -- 10  a 432 m de la autoescuela
    { pos = vec3(-69.75, -683.25, 32.19) },   -- 11  a 259 m de la autoescuela
    { pos = vec3(97.00, -524.25, 33.06), stop = true },   -- 12  a 119 m de la autoescuela
    { pos = vec3(-23.00, -396.25, 38.59) },   -- vuelta a la autoescuela (la calle de delante del parking)
    },
    -- C: la larga: sube al norte y baja por el este
    C = {
    { pos = vec3(-149.75, -378.50, 32.72) },   -- 1  a 177 m de la autoescuela
    { pos = vec3(-299.50, -314.75, 29.50) },   -- 2  a 340 m de la autoescuela
    { pos = vec3(-447.25, -247.75, 35.03) },   -- 3  a 502 m de la autoescuela
    { pos = vec3(-590.50, -167.25, 37.06), stop = true },   -- 4  a 665 m de la autoescuela
    { pos = vec3(-518.00, -8.25, 43.44) },   -- 5  a 685 m de la autoescuela
    { pos = vec3(-458.75, 127.50, 63.38) },   -- 6  a 738 m de la autoescuela
    { pos = vec3(-390.50, 257.25, 82.47) },   -- 7  a 816 m de la autoescuela
    { pos = vec3(-321.00, 386.25, 109.31), stop = true },   -- 8  a 891 m de la autoescuela
    { pos = vec3(-184.00, 275.00, 91.59) },   -- 9  a 771 m de la autoescuela
    { pos = vec3(-52.00, 260.50, 103.56) },   -- 10  a 672 m de la autoescuela
    { pos = vec3(147.75, 162.75, 103.72) },   -- 11  a 615 m de la autoescuela
    { pos = vec3(270.00, 148.75, 103.47), stop = true  },   -- 12  a 601 m de la autoescuela
    { pos = vec3(210.25, -32.75, 68.62) },   -- 13  a 447 m de la autoescuela
    { pos = vec3(160.75, -187.25, 53.34) },   -- 14  a 286 m de la autoescuela
    { pos = vec3(-23.00, -396.25, 38.59) },   -- vuelta a la autoescuela (la calle de delante del parking)
    },
}

--- Dónde se aparca al final (se mide en el juego con /autopunto).
Config.Aparcamiento = {
    --[[ El cuarto hueco de la MISMA fila que las tres plazas de salida
         (Config.Escuela.salidas), un paso mas alla de la primera. Sondeado
         con rayos en el juego el 20/09: mismo asfalto y misma cota que ellas
         (37,98), cielo encima y nada ocupandolo.
         La de antes (9.83, -431.81) estaba mal: caia en una AZOTEA a 41,8 m
         sin nada debajo; se habia sacado con el suelo «desde arriba», que en
         ciudad es el tejado. Una plaza nueva se sondea desde la cota de la
         calle, no desde el cielo (prueba/plazas.lua), y se comprueba que el
         RECTANGULO entero de la plaza es plano y esta libre
         (prueba/buscaplaza.lua): este hueco da el mismo desnivel que las
         plazas de salida y deja una libre de por medio. ]]
    centro = vec3(-16.05, -396.29, 38.54),
    rumbo = 253.8,
    largo = 6.5,
    ancho = 3.2,
}
