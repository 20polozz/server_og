--[[ ── Karts · carreras con cajas sorpresa ─────────────────────────────────── ]]

local K = {}

K.id = 'karts'
K.nombre = 'Karts'
K.lema = 'Carreras con cajas sorpresa, turbos y plátanos'
K.icono = 'coche'
--- El dibujo de su chincheta en los dos mapas (origen_map e inventario).
K.iconoMapa = 'coche'

--[[ Dos como mínimo. Para probar el circuito a solas en un servidor de
     pruebas: `setr origen_karts_solo 1` en la consola y reiniciar el recurso.
     No se pone en el server.cfg de producción. ]]
K.jugadoresMin = GetConvarInt('origen_karts_solo', 0) == 1 and 1 or 2
K.jugadoresMax = 8
--- Cada ronda es una carrera: 1 = carrera suelta, 3 o 5 = gran premio.
K.rondas = { 1, 3, 5 }
K.rondasDefecto = 3

K.modos = nil

--- El aparcamiento del circuito de Benny's, junto a la rueda gigante.
K.punto = { x = -757.0, y = -2040.0, z = 7.89 }
--- La zona cubre el circuito entero (la vuelta mide 1,3 km).
K.zonaSemilla = { nombre = "Circuito de Benny's", x = -655.0, y = -2095.0, z = 7.9, radio = 165.0 }

--- Los circuitos se rellenan en config/karts_circuitos.lua.
K.Circuitos = {}

K.Karts = {
    { id = 'veto2', nombre = 'Veto Modern' },
    { id = 'veto', nombre = 'Veto Classic' },
}

--- Lo que pone el staff en cada zona.
K.campos = {
    { id = 'circuito', nombre = 'Circuito', tipo = 'opciones', opciones = { { id = 'bennys', nombre = "Circuito de Benny's" } }, defecto = 'bennys' },
    { id = 'vehiculo', nombre = 'Kart', tipo = 'opciones', opciones = K.Karts, defecto = 'veto2' },
    { id = 'duracion', nombre = 'Tiempo máximo de carrera', tipo = 'rango', min = 180, max = 900, paso = 30, defecto = 480, formato = 'reloj' },
}

--[[ Las cilindradas. `tope` es la velocidad punta en m/s (el kart de GTA corre
     más: se le recorta). 27 m/s son 97 km/h. ]]
K.Cilindradas = {
    { id = '50', nombre = '50 cc · tranquilo', tope = 17.0 },
    { id = '100', nombre = '100 cc · normal', tope = 22.0 },
    { id = '150', nombre = '150 cc · rápido', tope = 27.0 },
}

--- Lo que elige quien crea la sala.
K.camposSala = {
    { id = 'vueltas', nombre = 'Vueltas', tipo = 'rango', min = 1, max = 5, paso = 1, defecto = 3 },
    { id = 'cilindrada', nombre = 'Cilindrada', tipo = 'opciones', opciones = K.Cilindradas, defecto = '100' },
    { id = 'objetos', nombre = 'Cajas sorpresa', tipo = 'interruptor', defecto = true },
}

--- Lo que guarda el ranking además de puntos y victorias.
K.destacado = 'carreras ganadas'

--- Puntos por puesto en cada carrera, del primero hacia atrás.
K.Puntos = { 15, 12, 10, 8, 6, 4, 2, 1 }

--[[ Las puertas de la vuelta. El servidor lleva la cuenta con la posición que
     ÉL ve de cada kart: una puerta vale si se pasa a menos de `radio` metros
     y la anterior ya está pasada. ]]
K.Puertas = {
    radio = 11.0,
    -- A más de esto de su tramo durante `lejosSegundos`, se le devuelve.
    lejos = 32.0,
    lejosSegundos = 4,
}

--- Cuando el primero cruza la meta, lo que tienen los demás para acabar.
K.Meta = { espera = 40 }

K.Recolocar = {
    cada = 5,              -- segundos entre dos «volver a pista»
    quieto = 1200,         -- ms parado al volver
    volcadoSegundos = 3,   -- volcado tanto rato: se le devuelve solo
}

--- El kart de cada ronda (igual que el coche del derbi).
K.Coche = { espera = 8, reintentos = 3, sinCocheMax = 15, fueraDelCoche = 3 }

--[[ ── Los turbos ─────────────────────────────────────────────────────────────

     Todo turbo es lo mismo: unos segundos con el tope de velocidad subido y un
     empuje hacia delante. Cambia cuánto dura y cuánto sube.

       objeto     el champiñón de las cajas
       banda      las flechas del suelo
       derrape    mantener el freno de mano girando; al soltar, según cuánto
                  se haya aguantado (azul o naranja)
       salida     acelerar justo al final de la cuenta atrás
       rebufo     ir pegado detrás de otro kart

     `velocidadMaxima` es lo que el SERVIDOR admite: por encima de eso durante
     `segundosTrampa`, fuera. Tiene que cubrir el tope de 150 cc más el turbo
     más fuerte con margen, y quedar por debajo de lo que mira el anticheat. ]]
K.Turbo = {
    fuerza = 22.0,
    objeto = { segundos = 2.6, extra = 8.0 },
    banda = { segundos = 1.6, extra = 7.0, radio = 3.4, cada = 1500 },
    derrape = {
        velocidadMin = 9.0,
        giroMin = 0.35,
        niveles = {
            { tras = 0.9, segundos = 0.8, extra = 5.0, nombre = 'Miniturbo' },
            { tras = 2.0, segundos = 1.5, extra = 7.0, nombre = 'Superturbo' },
        },
    },
    salida = { desde = 1100, hasta = 250, segundos = 1.6, extra = 7.0, calado = 1300 },
    rebufo = { distancia = 14.0, angulo = 14.0, tras = 1.6, segundos = 1.2, extra = 4.0 },
    velocidadMaxima = 43.0,
    segundosTrampa = 4,
}

--- Fuera del asfalto el kart no pasa de esta parte de su tope (salvo en turbo
--- o con escudo). Es lo que quita las ganas de atajar por la hierba.
K.Hierba = { factor = 0.5, margen = 2.0 }

--[[ ── Las cajas y los objetos ────────────────────────────────────────────────

     `peso`: cuánto sale cada objeto según vayas { delante, en medio, detrás }.
     Al que va primero no le salen misiles ni rayos; al último, lo gordo. ]]
K.Cajas = {
    radio = 2.6,        -- metros para cogerla (lo mira el cliente)
    alcance = 14.0,     -- metros que admite el servidor entre el kart y la caja
    reaparece = 6,      -- segundos
    ruleta = 1500,      -- ms de ruleta antes de poder usar el objeto
}

K.Objetos = {
    turbo = { nombre = 'Turbo', usos = 1, peso = { 30, 25, 12 } },
    turbo3 = { nombre = 'Triple turbo', usos = 3, peso = { 4, 14, 24 } },
    platano = { nombre = 'Plátano', usos = 1, peso = { 40, 20, 6 } },
    misil = { nombre = 'Misil', usos = 1, peso = { 0, 24, 20 } },
    escudo = { nombre = 'Escudo', usos = 1, peso = { 6, 10, 14 } },
    onda = { nombre = 'Onda', usos = 1, peso = { 20, 10, 5 } },
    rayo = { nombre = 'Rayo', usos = 1, peso = { 0, 0, 8 } },
    azul = { nombre = 'Misil azul', usos = 1, peso = { 0, 3, 11 } },
}
K.ObjetosOrden = { 'turbo', 'turbo3', 'platano', 'misil', 'escudo', 'onda', 'rayo', 'azul' }

K.Platano = {
    modelo = 'ng_proc_food_nana2a',
    detras = 3.2,       -- metros por detrás del kart donde cae
    radio = 1.8,        -- metros para pisarlo
    alcance = 10.0,     -- lo que admite el servidor entre la víctima y el plátano
    armado = 700,       -- ms hasta que puede pisarse
    maximo = 30,        -- en pista a la vez; el más viejo desaparece
}

K.Misil = { velocidad = 40.0, minimo = 1.2, maximo = 5.0 }
K.Azul = { segundos = 3.5, radio = 8.0 }
K.Onda = { radio = 14.0 }
K.Rayo = { segundos = 4, factor = 0.55 }
K.Escudo = { segundos = 7 }

--- Un golpe (plátano, misil, onda): trompo y unos segundos sin gas. Después,
--- un rato a salvo para que no te encadenen.
K.Golpe = { segundos = 1.6, gracia = 2000, frenada = 0.25 }

K.Teclas = {
    objeto = { control = 86, texto = 'E' },         -- la bocina del vehículo
    derrape = { control = 76, texto = 'Espacio' },  -- el freno de mano
    volver = { control = 80, texto = 'R' },
}

--- Un color por puesto de parrilla (colores de coche de GTA).
K.Colores = { 27, 64, 88, 53, 38, 145, 135, 111 }

K.ayuda = {
    {
        titulo = 'Cómo va',
        texto = 'Cada ronda es una carrera en el circuito. Hay que pasar por toda la pista: atajar por la hierba te frena y las puertas no cuentan. Cada carrera da puntos según el puesto y gana el gran premio quien más sume.',
    },
    {
        titulo = 'Teclas',
        teclas = {
            { tecla = 'E', texto = 'Usar el objeto de la caja sorpresa.' },
            { tecla = 'Espacio', texto = 'Derrapar: manténlo girando y suéltalo para un miniturbo.' },
            { tecla = 'R', texto = 'Volver a la pista si te quedas atascado.' },
        },
        nota = 'Acelera justo al final de la cuenta atrás para salir con turbo; si te adelantas, calas. Pisar las flechas del suelo y pegarte detrás de otro kart también dan turbo.',
    },
    {
        titulo = 'Objetos',
        datos = {
            { k = 'Turbo', v = 'Acelerón' },
            { k = 'Plátano', v = 'Lo sueltas detrás' },
            { k = 'Misil', v = 'Al de delante' },
            { k = 'Misil azul', v = 'Al primero' },
            { k = 'Onda', v = 'A los de al lado' },
            { k = 'Rayo', v = 'Frena a los de delante' },
            { k = 'Escudo', v = 'Nada te da' },
        },
    },
    {
        titulo = 'Puntos por carrera',
        datos = { { k = '1º', v = '+15' }, { k = '2º', v = '+12' }, { k = '3º', v = '+10' }, { k = '4º', v = '+8' } },
    },
}

Config.Juegos.karts = K
