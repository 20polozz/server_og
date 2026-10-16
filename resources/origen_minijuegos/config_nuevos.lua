--[[ LOS MINIJUEGOS NUEVOS (19/09/2026)

     Ocho juegos pensados para los robos. Viven aparte de los ocho antiguos
     (config.lua) y todos funcionan igual:

       · cada uno tiene cuatro dificultades —easy, medium, hard, extreme—, y
         TODO lo que cambia entre una y otra esta aqui, a la vista;
       · quien lanza el juego puede ademas pisar cualquier ajuste suelto (el
         editor de origen_robberies lo hace: «ajustes finos»). Lo que llega de
         fuera se recorta contra `ajustes[clave].min/max`, asi que un valor
         absurdo no rompe el juego;
       · `ajustes` es tambien lo que el editor enseña: etiqueta, tope y paso.

     Dos ajustes son comunes a todos:
       tiempo   segundos para todo el juego (0 = sin reloj)
       fallos   errores que se perdonan; al siguiente, se pierde (0 = ni uno)

     Para añadir una dificultad propia basta otra entrada en `dificultad`; para
     cambiar lo dura que es una, se tocan sus numeros y se reinicia el recurso. ]]

Config.Nuevos = {}

--- Volumen de los pitidos del juego, de 0 (mudo) a 1.
Config.NuevosVolumen = 0.35

local HACKEO = { dict = 'anim@heists@prison_heiststation@cop_reactions', anim = 'cop_b_idle', flag = 49 }
local MANOS = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', anim = 'machinic_loop_mechandplayer', flag = 16 }
local AGACHADO = { dict = 'amb@medic@standing@kneel@base', anim = 'base', flag = 1 }

-- =====================================================
-- GANZUA DE TENSION  (puertas, taquillas, vehiculos)
-- Se busca el angulo bueno con el raton y se gira el bombin. Si se fuerza
-- donde no es, la ganzua sufre y acaba partiendose.
-- =====================================================
Config.Nuevos.ganzua = {
    etiqueta = 'Ganzúa de tensión',
    animacion = MANOS,
    dificultad = {
        easy    = { cerraduras = 1, margen = 26, aguante = 2.4, fallos = 3, tiempo = 45 },
        medium  = { cerraduras = 2, margen = 18, aguante = 1.8, fallos = 2, tiempo = 50 },
        hard    = { cerraduras = 3, margen = 12, aguante = 1.3, fallos = 2, tiempo = 55 },
        extreme = { cerraduras = 3, margen = 8,  aguante = 0.9, fallos = 1, tiempo = 50 },
    },
    ajustes = {
        { clave = 'cerraduras', etiqueta = 'Cerraduras seguidas', min = 1, max = 6, paso = 1 },
        { clave = 'margen', etiqueta = 'Anchura del punto bueno (grados)', min = 4, max = 60, paso = 1 },
        { clave = 'aguante', etiqueta = 'Lo que aguanta la ganzúa forzando (s)', min = 0.3, max = 6, paso = 0.1 },
        { clave = 'fallos', etiqueta = 'Ganzúas de repuesto', min = 0, max = 9, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- =====================================================
-- PINES DEL BOMBIN  (cerraduras de seguridad)
-- Cada pin sube y baja a su ritmo. Hay que fijarlos uno a uno justo cuando
-- cruzan la linea de corte.
-- =====================================================
Config.Nuevos.pines = {
    etiqueta = 'Pines del bombín',
    animacion = MANOS,
    dificultad = {
        easy    = { pines = 3, velocidad = 0.8, margen = 22, seCaen = false, fallos = 4, tiempo = 40 },
        medium  = { pines = 4, velocidad = 1.0, margen = 17, seCaen = false, fallos = 3, tiempo = 45 },
        hard    = { pines = 5, velocidad = 1.3, margen = 13, seCaen = true,  fallos = 3, tiempo = 50 },
        extreme = { pines = 6, velocidad = 1.6, margen = 10, seCaen = true,  fallos = 2, tiempo = 50 },
    },
    ajustes = {
        { clave = 'pines', etiqueta = 'Pines', min = 2, max = 8, paso = 1 },
        { clave = 'velocidad', etiqueta = 'Velocidad de los pines', min = 0.3, max = 3, paso = 0.1 },
        { clave = 'margen', etiqueta = 'Anchura de la línea de corte (%)', min = 5, max = 40, paso = 1 },
        { clave = 'seCaen', etiqueta = 'Al fallar se cae un pin ya fijado', tipo = 'si_no' },
        { clave = 'fallos', etiqueta = 'Fallos perdonados', min = 0, max = 9, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- =====================================================
-- DIAL DE LA CAJA FUERTE
-- Se gira la rueda escuchando: el fonendo sube al acercarse al numero. Cada
-- numero se busca girando hacia el lado contrario que el anterior.
-- =====================================================
Config.Nuevos.dial = {
    etiqueta = 'Dial de la caja fuerte',
    animacion = AGACHADO,
    dificultad = {
        easy    = { numeros = 2, margen = 3, alcance = 22, ruido = 0.00, fallos = 3, tiempo = 60 },
        medium  = { numeros = 3, margen = 2, alcance = 16, ruido = 0.08, fallos = 2, tiempo = 70 },
        hard    = { numeros = 4, margen = 2, alcance = 12, ruido = 0.16, fallos = 2, tiempo = 80 },
        extreme = { numeros = 5, margen = 1, alcance = 9,  ruido = 0.24, fallos = 1, tiempo = 90 },
    },
    ajustes = {
        { clave = 'numeros', etiqueta = 'Números de la combinación', min = 1, max = 8, paso = 1 },
        { clave = 'margen', etiqueta = 'Cuánto se perdona al confirmar (números)', min = 0, max = 8, paso = 1 },
        { clave = 'alcance', etiqueta = 'Desde qué distancia se oye', min = 4, max = 45, paso = 1 },
        { clave = 'ruido', etiqueta = 'Ruido en el fonendo (0 a 0,5)', min = 0, max = 0.5, paso = 0.02 },
        { clave = 'fallos', etiqueta = 'Fallos perdonados', min = 0, max = 9, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- =====================================================
-- TALADRO  (cajas, camaras acorazadas, cajeros)
-- Se mantiene pulsado para subir de vueltas. Solo avanza dentro de la franja
-- buena; pasado de vueltas se calienta y la broca revienta.
-- =====================================================
Config.Nuevos.taladro = {
    etiqueta = 'Taladro',
    animacion = AGACHADO,
    dificultad = {
        easy    = { capas = 2, grosor = 3.0, banda = 30, calor = 0.8, fallos = 2, tiempo = 50 },
        medium  = { capas = 3, grosor = 3.0, banda = 24, calor = 1.0, fallos = 2, tiempo = 60 },
        hard    = { capas = 4, grosor = 3.2, banda = 18, calor = 1.3, fallos = 1, tiempo = 70 },
        extreme = { capas = 5, grosor = 3.2, banda = 13, calor = 1.6, fallos = 1, tiempo = 75 },
    },
    ajustes = {
        { clave = 'capas', etiqueta = 'Capas que atravesar', min = 1, max = 8, paso = 1 },
        { clave = 'grosor', etiqueta = 'Segundos de taladro por capa', min = 1, max = 10, paso = 0.2 },
        { clave = 'banda', etiqueta = 'Anchura de la franja buena (%)', min = 6, max = 50, paso = 1 },
        { clave = 'calor', etiqueta = 'Lo deprisa que se calienta', min = 0.3, max = 3, paso = 0.1 },
        { clave = 'fallos', etiqueta = 'Brocas de repuesto', min = 0, max = 9, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- =====================================================
-- CLONAR HUELLA  (lectores biometricos)
-- A la izquierda, la huella del dueño. A la derecha, trozos: unos son suyos y
-- otros de otra persona. Hay que marcar solo los suyos.
-- =====================================================
Config.Nuevos.huella = {
    etiqueta = 'Clonar huella',
    animacion = HACKEO,
    dificultad = {
        easy    = { rondas = 1, piezas = 3, opciones = 6, parecido = 0.0, fallos = 2, tiempo = 45 },
        medium  = { rondas = 2, piezas = 3, opciones = 8, parecido = 0.35, fallos = 2, tiempo = 70 },
        hard    = { rondas = 2, piezas = 4, opciones = 9, parecido = 0.6, fallos = 1, tiempo = 80 },
        extreme = { rondas = 3, piezas = 4, opciones = 12, parecido = 0.8, fallos = 1, tiempo = 100 },
    },
    ajustes = {
        { clave = 'rondas', etiqueta = 'Huellas seguidas', min = 1, max = 5, paso = 1 },
        { clave = 'piezas', etiqueta = 'Trozos buenos que encontrar', min = 1, max = 6, paso = 1 },
        { clave = 'opciones', etiqueta = 'Trozos a la vista', min = 4, max = 12, paso = 1 },
        { clave = 'parecido', etiqueta = 'Lo que se parecen los falsos (0 a 0,9)', min = 0, max = 0.9, paso = 0.05 },
        { clave = 'fallos', etiqueta = 'Fallos perdonados', min = 0, max = 9, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- =====================================================
-- DESCIFRAR LA CLAVE  (teclados, alarmas, cajas registradoras)
-- Se prueba una clave y el teclado chiva: verde = numero en su sitio,
-- ambar = esta pero en otro sitio, gris = no esta.
-- =====================================================
Config.Nuevos.clave = {
    etiqueta = 'Descifrar la clave',
    animacion = HACKEO,
    dificultad = {
        easy    = { digitos = 3, simbolos = 6,  intentos = 7, repetidos = false, porPosicion = true, tiempo = 60 },
        medium  = { digitos = 4, simbolos = 8,  intentos = 7, repetidos = false, porPosicion = true, tiempo = 75 },
        hard    = { digitos = 4, simbolos = 10, intentos = 6, repetidos = true,  porPosicion = true, tiempo = 80 },
        extreme = { digitos = 5, simbolos = 10, intentos = 6, repetidos = true,  porPosicion = true, tiempo = 90 },
    },
    ajustes = {
        { clave = 'digitos', etiqueta = 'Cifras de la clave', min = 2, max = 6, paso = 1 },
        { clave = 'simbolos', etiqueta = 'Teclas distintas (del 0 en adelante)', min = 3, max = 10, paso = 1 },
        { clave = 'intentos', etiqueta = 'Intentos', min = 2, max = 12, paso = 1 },
        { clave = 'repetidos', etiqueta = 'La clave puede repetir cifras', tipo = 'si_no' },
        { clave = 'porPosicion', etiqueta = 'La pista se da cifra a cifra (si no, solo el recuento)', tipo = 'si_no' },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- =====================================================
-- SINTONIZAR LA SEÑAL  (alarmas, camaras, inhibidores)
-- Hay que dejar la onda propia encima de la de referencia y aguantarla ahi.
-- =====================================================
Config.Nuevos.senal = {
    etiqueta = 'Sintonizar la señal',
    animacion = HACKEO,
    dificultad = {
        easy    = { rondas = 2, mandos = 2, margen = 0.14, mantener = 1.0, deriva = 0.0, tiempo = 45 },
        medium  = { rondas = 3, mandos = 2, margen = 0.10, mantener = 1.2, deriva = 0.0, tiempo = 55 },
        hard    = { rondas = 3, mandos = 3, margen = 0.08, mantener = 1.4, deriva = 0.3, tiempo = 70 },
        extreme = { rondas = 4, mandos = 3, margen = 0.06, mantener = 1.5, deriva = 0.6, tiempo = 80 },
    },
    ajustes = {
        { clave = 'rondas', etiqueta = 'Señales seguidas', min = 1, max = 8, paso = 1 },
        { clave = 'mandos', etiqueta = 'Mandos (2 = altura y frecuencia, 3 = también la fase)', min = 2, max = 3, paso = 1 },
        { clave = 'margen', etiqueta = 'Cuánto se perdona (0,03 a 0,3)', min = 0.03, max = 0.3, paso = 0.01 },
        { clave = 'mantener', etiqueta = 'Segundos que hay que aguantarla', min = 0.3, max = 5, paso = 0.1 },
        { clave = 'deriva', etiqueta = 'Lo que se mueve sola la referencia (0 a 1)', min = 0, max = 1, paso = 0.1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- =====================================================
-- CORTE DE PRECISION  (vitrinas, cristales, paneles)
-- Con el boton pulsado se sigue la linea de corte de punta a punta sin
-- salirse.
-- =====================================================
Config.Nuevos.corte = {
    etiqueta = 'Corte de precisión',
    animacion = MANOS,
    dificultad = {
        easy    = { rondas = 1, curvas = 3, ancho = 5.0, fallos = 3, tiempo = 40 },
        medium  = { rondas = 2, curvas = 4, ancho = 3.8, fallos = 3, tiempo = 55 },
        hard    = { rondas = 2, curvas = 6, ancho = 2.8, fallos = 2, tiempo = 60 },
        extreme = { rondas = 3, curvas = 7, ancho = 2.1, fallos = 2, tiempo = 75 },
    },
    ajustes = {
        { clave = 'rondas', etiqueta = 'Cortes seguidos', min = 1, max = 6, paso = 1 },
        { clave = 'curvas', etiqueta = 'Curvas de la línea', min = 2, max = 10, paso = 1 },
        { clave = 'ancho', etiqueta = 'Anchura de la línea (% del panel)', min = 1.2, max = 10, paso = 0.1 },
        { clave = 'fallos', etiqueta = 'Salidas perdonadas', min = 0, max = 9, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- ═════════════════════════════════════════════════════════════════════
-- SEGUNDA TANDA (19/09/2026): los «grandes». Pantalla al centro, pintados
-- en lienzo con neon, chispas y fuego. Se configuran igual que los demas.
-- ═════════════════════════════════════════════════════════════════════

-- CAMARA ACORAZADA: anillos que giran solos; se para cada uno cuando su
-- muesca pasa por el cerrojo de arriba.
Config.Nuevos.boveda = {
    etiqueta = 'Cámara acorazada (anillos)',
    animacion = AGACHADO,
    dificultad = {
        easy    = { anillos = 3, velocidad = 0.8,  margen = 18, acelera = 0.0,  fallos = 3, tiempo = 40 },
        medium  = { anillos = 4, velocidad = 1.0,  margen = 14, acelera = 0.1,  fallos = 3, tiempo = 45 },
        hard    = { anillos = 5, velocidad = 1.2,  margen = 11, acelera = 0.15, fallos = 2, tiempo = 50 },
        extreme = { anillos = 6, velocidad = 1.35, margen = 9,  acelera = 0.2,  fallos = 2, tiempo = 55 },
    },
    ajustes = {
        { clave = 'anillos', etiqueta = 'Anillos', min = 2, max = 7, paso = 1 },
        { clave = 'velocidad', etiqueta = 'Velocidad de giro', min = 0.3, max = 3, paso = 0.05 },
        { clave = 'margen', etiqueta = 'Anchura de la muesca (grados)', min = 4, max = 40, paso = 1 },
        { clave = 'acelera', etiqueta = 'Cuánto acelera el anillo al fallar (0 a 0,6)', min = 0, max = 0.6, paso = 0.05 },
        { clave = 'fallos', etiqueta = 'Fallos perdonados', min = 0, max = 9, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- CARGA DE TERMITA: se enseñan las cargas, se apagan y hay que marcarlas de
-- memoria. Al acertarlas todas, arde.
Config.Nuevos.termita = {
    etiqueta = 'Carga de termita (memoria)',
    animacion = AGACHADO,
    dificultad = {
        easy    = { tamano = 5, casillas = 6,  muestra = 3.0, rondas = 1, fallos = 2, tiempo = 30 },
        medium  = { tamano = 6, casillas = 9,  muestra = 3.0, rondas = 2, fallos = 2, tiempo = 55 },
        hard    = { tamano = 6, casillas = 12, muestra = 2.6, rondas = 2, fallos = 1, tiempo = 60 },
        extreme = { tamano = 7, casillas = 15, muestra = 2.6, rondas = 3, fallos = 1, tiempo = 90 },
    },
    ajustes = {
        { clave = 'tamano', etiqueta = 'Lado de la rejilla', min = 3, max = 9, paso = 1 },
        { clave = 'casillas', etiqueta = 'Cargas que memorizar', min = 1, max = 30, paso = 1 },
        { clave = 'muestra', etiqueta = 'Segundos que se enseñan', min = 0.5, max = 10, paso = 0.1 },
        { clave = 'rondas', etiqueta = 'Rondas', min = 1, max = 6, paso = 1 },
        { clave = 'fallos', etiqueta = 'Fallos perdonados', min = 0, max = 9, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- SOPLETE: se rodea la cerradura con el soplete encendido, al ritmo del
-- corte. Salirse es un fallo; pararse con la llama puesta, recalienta.
Config.Nuevos.soplete = {
    etiqueta = 'Soplete (cortar la cerradura)',
    animacion = AGACHADO,
    dificultad = {
        easy    = { ancho = 7.5, velocidad = 1.1,  forma = 0.0,  calor = 0.8, fallos = 3, tiempo = 45 },
        medium  = { ancho = 6.0, velocidad = 1.0,  forma = 0.35, calor = 1.0, fallos = 2, tiempo = 45 },
        hard    = { ancho = 4.6, velocidad = 0.9,  forma = 0.6,  calor = 1.2, fallos = 2, tiempo = 50 },
        extreme = { ancho = 3.6, velocidad = 0.85, forma = 0.9,  calor = 1.5, fallos = 1, tiempo = 55 },
    },
    ajustes = {
        { clave = 'ancho', etiqueta = 'Anchura de la franja (% del alto)', min = 1.5, max = 14, paso = 0.1 },
        { clave = 'velocidad', etiqueta = 'Velocidad del corte (1 = 14 s la vuelta)', min = 0.3, max = 3, paso = 0.05 },
        { clave = 'forma', etiqueta = 'Lo irregular que es el contorno (0 a 1)', min = 0, max = 1, paso = 0.05 },
        { clave = 'calor', etiqueta = 'Lo deprisa que se recalienta', min = 0.2, max = 3, paso = 0.1 },
        { clave = 'fallos', etiqueta = 'Fallos perdonados', min = 0, max = 9, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- REJILLA LASER: se giran espejos para llevar el rayo del emisor al receptor.
Config.Nuevos.laser = {
    etiqueta = 'Rejilla láser (espejos)',
    animacion = HACKEO,
    dificultad = {
        easy    = { tamano = 5, espejos = 3, senuelos = 2, muros = 1, giros = 0, tiempo = 45 },
        medium  = { tamano = 6, espejos = 4, senuelos = 3, muros = 2, giros = 0, tiempo = 60 },
        hard    = { tamano = 7, espejos = 5, senuelos = 5, muros = 3, giros = 0, tiempo = 70 },
        extreme = { tamano = 8, espejos = 6, senuelos = 7, muros = 4, giros = 0, tiempo = 80 },
    },
    ajustes = {
        { clave = 'tamano', etiqueta = 'Lado de la rejilla', min = 4, max = 9, paso = 1 },
        { clave = 'espejos', etiqueta = 'Espejos por los que pasa la solución (mínimo)', min = 1, max = 10, paso = 1 },
        { clave = 'senuelos', etiqueta = 'Espejos de más, que no hacen falta', min = 0, max = 12, paso = 1 },
        { clave = 'muros', etiqueta = 'Bloques que cortan el rayo', min = 0, max = 8, paso = 1 },
        { clave = 'giros', etiqueta = 'Giros permitidos (0 = sin límite)', min = 0, max = 60, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- TUNEL DE DATOS: se vuela por un tunel esquivando cortafuegos; cada uno
-- tiene un hueco por el que pasar. No lleva reloj: acaba al pasar todos.
Config.Nuevos.tunel = {
    etiqueta = 'Túnel de datos (esquivar)',
    animacion = HACKEO,
    dificultad = {
        easy    = { muros = 8,  velocidad = 0.8,  hueco = 110, fallos = 3, tiempo = 0 },
        medium  = { muros = 12, velocidad = 1.0,  hueco = 85,  fallos = 2, tiempo = 0 },
        hard    = { muros = 16, velocidad = 1.25, hueco = 68,  fallos = 2, tiempo = 0 },
        extreme = { muros = 20, velocidad = 1.5,  hueco = 55,  fallos = 1, tiempo = 0 },
    },
    ajustes = {
        { clave = 'muros', etiqueta = 'Cortafuegos que pasar', min = 3, max = 60, paso = 1 },
        { clave = 'velocidad', etiqueta = 'Velocidad', min = 0.3, max = 3, paso = 0.05 },
        { clave = 'hueco', etiqueta = 'Anchura del hueco (grados)', min = 25, max = 200, paso = 5 },
        { clave = 'fallos', etiqueta = 'Choques perdonados', min = 0, max = 9, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- PUENTEAR EL CIRCUITO: se giran piezas hasta que la corriente llega de la
-- bateria a todos los chips.
Config.Nuevos.circuito = {
    etiqueta = 'Puentear el circuito',
    animacion = HACKEO,
    dificultad = {
        easy    = { tamano = 4, chips = 1, senuelos = 3,  tiempo = 45 },
        medium  = { tamano = 5, chips = 2, senuelos = 5,  tiempo = 60 },
        hard    = { tamano = 6, chips = 2, senuelos = 8,  tiempo = 75 },
        extreme = { tamano = 7, chips = 3, senuelos = 10, tiempo = 90 },
    },
    ajustes = {
        { clave = 'tamano', etiqueta = 'Lado de la placa', min = 3, max = 8, paso = 1 },
        { clave = 'chips', etiqueta = 'Chips que alimentar', min = 1, max = 4, paso = 1 },
        { clave = 'senuelos', etiqueta = 'Piezas sueltas que despistan', min = 0, max = 14, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- SINCRONIZAR PAQUETES: notas que caen por cuatro carriles (A S D F). No
-- lleva reloj: acaba con la ultima nota.
Config.Nuevos.ritmo = {
    etiqueta = 'Sincronizar paquetes (ritmo)',
    animacion = HACKEO,
    dificultad = {
        easy    = { notas = 14, velocidad = 0.8, ritmo = 1.4, margen = 170, fallos = 4, tiempo = 0 },
        medium  = { notas = 20, velocidad = 1.0, ritmo = 1.9, margen = 140, fallos = 3, tiempo = 0 },
        hard    = { notas = 28, velocidad = 1.2, ritmo = 2.5, margen = 115, fallos = 3, tiempo = 0 },
        extreme = { notas = 36, velocidad = 1.4, ritmo = 3.1, margen = 95,  fallos = 2, tiempo = 0 },
    },
    ajustes = {
        { clave = 'notas', etiqueta = 'Paquetes', min = 4, max = 120, paso = 1 },
        { clave = 'velocidad', etiqueta = 'Velocidad de caída', min = 0.3, max = 3, paso = 0.05 },
        { clave = 'ritmo', etiqueta = 'Paquetes por segundo', min = 0.4, max = 6, paso = 0.1 },
        { clave = 'margen', etiqueta = 'Cuánto se perdona el pulso (ms)', min = 40, max = 400, paso = 5 },
        { clave = 'fallos', etiqueta = 'Paquetes perdidos que se perdonan', min = 0, max = 20, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

-- INYECCION DE CODIGO: caen codigos y hay que teclearlos antes de que toquen
-- el cortafuegos. No lleva reloj: acaba con el ultimo codigo.
Config.Nuevos.inyeccion = {
    etiqueta = 'Inyección de código (teclear)',
    animacion = HACKEO,
    dificultad = {
        easy    = { codigos = 6,  longitud = 3, velocidad = 0.8,  fallos = 2, tiempo = 0 },
        medium  = { codigos = 9,  longitud = 4, velocidad = 1.0,  fallos = 2, tiempo = 0 },
        hard    = { codigos = 12, longitud = 4, velocidad = 1.25, fallos = 1, tiempo = 0 },
        extreme = { codigos = 15, longitud = 5, velocidad = 1.45, fallos = 1, tiempo = 0 },
    },
    ajustes = {
        { clave = 'codigos', etiqueta = 'Códigos', min = 2, max = 60, paso = 1 },
        { clave = 'longitud', etiqueta = 'Letras por código', min = 2, max = 8, paso = 1 },
        { clave = 'velocidad', etiqueta = 'Velocidad de caída', min = 0.3, max = 3, paso = 0.05 },
        { clave = 'fallos', etiqueta = 'Códigos que pueden llegar abajo', min = 0, max = 9, paso = 1 },
        { clave = 'tiempo', etiqueta = 'Tiempo (s, 0 = sin reloj)', min = 0, max = 600, paso = 5 },
    },
}

--- El orden en que salen en las listas.
Config.NuevosOrden = {
    'boveda', 'termita', 'soplete', 'laser', 'tunel', 'circuito', 'ritmo', 'inyeccion',
    'ganzua', 'pines', 'dial', 'taladro', 'huella', 'clave', 'senal', 'corte',
}
