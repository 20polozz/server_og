--[[ ── Las gruas de coches ────────────────────────────────────────────────────

     Dos formas de llevarse un coche:

       · De GANCHO (towtruck): el brazo levanta el morro y el coche va
         rodando de atras. Es la de toda la vida del GTA, pero la del juego
         se suelta sola en cuanto hay mas gente cerca; aqui la llevamos
         nosotros de punta a punta.

       · De PLATAFORMA (flatbed): el coche sube ENTERO a la caja tirado por
         el cabrestante, y esa subida la ven todos los que esten delante,
         no solo quien tira de la palanca.

     Todas las medidas van en metros y referidas al centro del camion. Las
     de la caja movil se afinan en el juego con /gruaajuste, que al cerrarse
     escupe los numeros buenos por consola para pegarlos aqui. ]]

Config = {}

-- Hasta donde puede estar el coche del brazo de la grua de GANCHO, en metros.
Config.Distancia = 8.0

--[[ Lo cerca que hay que estar para que salgan los avisos. Antes saltaban a
     nueve metros del centro del camion y a ocho de cualquier coche, y el «pon
     la plataforma delante» perseguia a la gente por todo el aparcamiento.

       CercaGrua   margen alrededor del CONTORNO del camion (no de su centro,
                   que el flatbed mide diez metros de largo)
       CercaCoche  distancia al coche que se quiere cargar ]]
Config.CercaGrua = 2.5
Config.CercaCoche = 3.5

-- Lo que tarda el cabrestante en subir (o bajar) un coche, en milisegundos.
Config.Cabrestante = 7000

--[[ Lo que tarda el cable de la grua de gancho en acercarse el coche. Hace
     falta porque el enganche del juego solo muerde de muy cerca: medido, a
     2.5 m agarra siempre y a 7 m no agarra nunca. ]]
Config.Acercar = 3000

-- Cada cuanto repasa el cliente que el coche siga enganchado, en milisegundos.
-- Es el vigilante que arregla lo de que «se sueltan solos».
Config.Vigilante = 200

--[[ Le quita al camion el enganche automatico del juego, que es lo que
     engancha y suelta por su cuenta en baches y frenazos. Si por lo que sea
     con esto el gancho dejara de agarrar, ponlo en false: el vigilante y el
     dueño fijado siguen haciendo la mayor parte del trabajo. ]]
Config.QuitarAutomatico = false

--[[ Quien puede usarlas.

       SoloTaller  true = solo quien este DE SERVICIO en un negocio con taller
                   (origen_businesses). Es la misma pregunta que hace
                   origen_mechanic antes de dejar reparar: plantilla del
                   negocio + fichado + que el negocio tenga punto de taller.
       Trabajos    ademas de esos, trabajos del framework que tambien pueden
                   (por ejemplo { police = true }). Vacio = nadie mas.

     Con SoloTaller en false y Trabajos vacio, cualquiera. ]]
Config.SoloTaller = false
Config.Trabajos = {}

-- Tipos de vehiculo que se pueden remolcar. Los que da el servidor con
-- GetVehicleType. Fuera quedan barcos, helicopteros, aviones y trenes.
Config.Remolcables = {
    automobile = true,
    bike = true,
    quadbike = true,
    bicycle = true,
    amphibious_automobile = true,
    submarinecar = true,
}

--[[ ── Las gruas, por modelo ──────────────────────────────────────────────

     gancho     → { gancho }  donde muerde el gancho, referido al coche.

     plataforma → de dos clases:

       · Con CAJA MOVIL (`caja`): el camion trae la caja como extra del
         modelo. Se oculta ese extra y se pone en su sitio el prop, que si
         se puede deslizar e inclinar. Es la buena.

       · Por PERFIL (`alto`, `cajaDesde`, `rampaDesde`, `rampaHasta`): para
         los camiones de serie, que no tienen ninguna pieza movil. Los
         numeros salen de medir el camion en el juego con trazos verticales,
         y van referidos al centro del camion:

             alto        altura de la superficie de carga
             cajaDesde   donde empieza esa superficie por detras
             rampaDesde  donde la rampa toca el suelo (si la hay)
             rampaHasta  donde la rampa llega a la caja
             tope        hasta donde adelanta el morro del coche
             recoge      donde se encara y se deja el coche, por detras ]]
Config.Gruas = {
    [`towtruck`] = {
        tipo = 'gancho',
        ganchoY = -2.45,
        ganchoZ = 0.35,
        brazo = 0.65,
        cable = vec3(0.0, -3.30, 1.30),
    },
    [`towtruck2`] = {
        tipo = 'gancho',
        ganchoY = -2.15,
        ganchoZ = 0.30,
        brazo = 0.65,
        cable = vec3(0.0, -2.80, 1.15),
    },
    [`towtruck3`] = {
        tipo = 'gancho',
        ganchoY = -2.45,
        ganchoZ = 0.35,
        brazo = 0.65,
        cable = vec3(0.0, -3.30, 1.30),
    },
    [`towtruck4`] = {
        tipo = 'gancho',
        ganchoY = -2.15,
        ganchoZ = 0.30,
        brazo = 0.65,
        cable = vec3(0.0, -2.80, 1.15),
    },

    --[[ La plataforma buena. El `flatbed` que corre en el servidor NO es el
         del GTA: origen_tow_assets lo sustituye por el del MTL Flatbed, que
         trae la caja como extra 1 del camion y ademas como prop suelto. Se
         oculta el extra, se pone el prop en su sitio, y ya se puede sacar
         hacia atras e inclinar hasta tocar el suelo.

         Las tres poses son las del propio mod, no inventadas. ]]
    [`flatbed`] = {
        tipo = 'plataforma',
        caja = {
            prop = 'inm_flatbed_base',
            extra = 1,                 -- la caja del modelo, que se oculta
            hueso = 'chassis',
            -- Metida, sacada hacia atras y tumbada en el suelo.
            puesta = { pos = vec3(0.0, -3.60, 0.22), rot = vec3(0.0, 0.0, 0.0) },
            atras  = { pos = vec3(0.0, -7.60, 0.22), rot = vec3(0.0, 0.0, 0.0) },
            bajada = { pos = vec3(0.0, -7.80, -0.70), rot = vec3(14.0, 0.0, 0.0) },
            -- Donde queda el coche sobre la caja.
            coche = vec3(0.0, 1.15, 0.20),
            -- De donde sale el cable, referido a la caja.
            cable = vec3(0.0, 3.60, 0.55),
        },
        cable = vec3(0.0, 1.75, 1.45),
        entrada = 14.0,
    },

    --[[ El slamtruck si lleva rampa de verdad: medida, baja de la caja
         (0.42) al suelo en 2.5 m. El coche trepa por ella y se queda de
         morro arriba, medio subido en la rampa, como en el juego base. ]]
    [`slamtruck`] = {
        tipo = 'plataforma',
        alto = 0.42,
        cajaDesde = -1.70,
        rampaDesde = -4.30,
        rampaHasta = -1.70,
        tope = 0.55,
        recoge = -7.5,
        cable = vec3(0.0, 1.30, 1.25),
        entrada = 10.0,
    },
}

-- Lo que tarda cada paso de la caja movil, en milisegundos.
Config.Caja = {
    sacar = 2200,   -- deslizarla hacia atras (y volver a meterla)
    bajar = 1500,   -- inclinarla hasta el suelo (y volver a levantarla)
    tirar = 4000,   -- el cabrestante subiendo el coche por ella
}

--[[ La caja negra: cuando un camion pega un salto, cada cliente que lo tenga
     delante manda al servidor lo que habia alrededor. Sale por la consola del
     servidor y se guarda en cajanegra.log, dentro del recurso. En false no
     hace nada. ]]
Config.CajaNegra = true

-- Teclas. El jugador las puede cambiar en Esc → Ajustes → Asignacion de teclas.
Config.Teclas = {
    Usar = 'E',
    -- Bajar y subir la caja a mano, sin cargar nada.
    Plataforma = 'G',
    BrazoArriba = 'PAGEUP',
    BrazoAbajo = 'PAGEDOWN',
}
