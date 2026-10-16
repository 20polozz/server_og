--[[ ── Rey de la colina · solo uno puede quedarse arriba ───────────────────── ]]

local C = {}

C.id = 'colina'
C.nombre = 'Rey de la colina'
C.lema = 'Solo uno puede quedarse arriba'
C.icono = 'corona'
--- El dibujo de su chincheta en los dos mapas (origen_map e inventario).
C.iconoMapa = 'corona'

C.jugadoresMin = 2
C.jugadoresMax = 16
C.rondas = { 1, 3, 5 }
C.rondasDefecto = 3

C.modos = nil

C.punto = { x = 208.0, y = -920.0, z = 30.69 }
C.zonaSemilla = { nombre = 'Plaza de la Legión', x = 195.17, y = -933.77, z = 29.7, radio = 45.0 }

C.campos = {
    { id = 'duracion', nombre = 'Duración de la ronda', tipo = 'rango', min = 60, max = 420, paso = 15, defecto = 180, formato = 'reloj' },
    { id = 'radioColina', nombre = 'Tamaño de la colina', tipo = 'rango', min = 1.5, max = 6, paso = 0.5, defecto = 2.5, formato = 'metros' },
    { id = 'moverCada', nombre = 'La colina se mueve cada', tipo = 'rango', min = 20, max = 120, paso = 5, defecto = 45, formato = 'segundos' },
}

C.destacado = 'segundos de rey'

C.Empujon = {
    alcance = 2.2,
    enfriamiento = 4,
    ragdoll = 1800,     -- ms en el suelo
    fuerza = 11.0,
}

--- Aviso antes de que la colina cambie de sitio.
C.AvisoMover = 5

C.Puntos = {
    porSegundo = 1,     -- solo si estás SOLO dentro
    ganarRonda = 10,    -- quien más segundos sume en la ronda
}

C.Teclas = {
    empujar = { control = 38, texto = 'E' },
}

C.ayuda = {
    {
        titulo = 'Cómo va',
        texto = 'Dentro de la zona hay un círculo: la colina. Cada segundo que estés tú solo dentro suma un punto. Si hay dos o más, no suma nadie. Cada poco la colina cambia de sitio: te avisa antes para que corras.',
    },
    {
        titulo = 'Teclas',
        teclas = {
            { tecla = 'E', texto = 'Empujón: tira al suelo a quien tengas delante. Tiene recarga.' },
        },
        nota = 'Nadie se hace daño: los empujones solo sirven para sacar al rey de la colina.',
    },
    {
        titulo = 'Puntos',
        datos = { { k = 'Por segundo', v = '+1' }, { k = 'Ganar ronda', v = '+10' } },
    },
}

Config.Juegos.colina = C
