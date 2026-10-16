--[[ ── El impostor · uno de vosotros no es quien dice ─────────────────────── ]]

local I = {}

I.id = 'impostor'
I.nombre = 'El impostor'
I.lema = 'Uno de vosotros no es quien dice'
I.icono = 'mascara'
--- El dibujo de su chincheta en los dos mapas (origen_map e inventario).
I.iconoMapa = 'mascara'

I.jugadoresMin = 4
I.jugadoresMax = 12
I.rondas = { 1, 3 }
I.rondasDefecto = 1

I.modos = {
    { id = 'uno', nombre = 'Un impostor', texto = 'Un solo impostor entre todos.' },
    { id = 'dos', nombre = 'Dos impostores', texto = 'Dos impostores que se conocen entre ellos. Con ocho o más jugadores.' },
}

I.punto = { x = 186.5, y = -940.5, z = 30.69 }
I.zonaSemilla = { nombre = 'Plaza de la Legión', x = 195.17, y = -933.77, z = 29.7, radio = 55.0 }

I.campos = {
    { id = 'tareas', nombre = 'Tareas por tripulante', tipo = 'rango', min = 2, max = 6, paso = 1, defecto = 3, formato = 'numero' },
    { id = 'duracion', nombre = 'Tiempo máximo de ronda', tipo = 'rango', min = 180, max = 900, paso = 30, defecto = 480, formato = 'reloj' },
    { id = 'disfraz', nombre = 'Todos con el mismo mono', tipo = 'interruptor', defecto = true },
}

I.destacado = 'aciertos'

I.Asesinato = {
    alcance = 2.0,
    enfriamiento = 25,
    alcanceSonido = 12.0,   -- a cuántos metros se oye una eliminación
}
--[[ Cada tarea es un minijuego de la NUI (Core.Minijuego). `minimo`: segundos
     que tienen que pasar como poco entre abrirlo y completarlo; lo mira el
     servidor, porque que la pantalla diga «hecho» no prueba nada. `tipos`: los
     minijuegos que se reparten; a un mismo jugador no se le repite ninguno
     mientras queden otros. `nombres` solo se usa si el núcleo no trae el suyo. ]]
I.Tarea = {
    alcance = 1.8,
    minimo = 2,
    --[[ La barra de «Equipo»: true sube en cuanto alguien termina una tarea;
         false solo se pone al día en las reuniones (más difícil, porque así
         no se sabe quién hace tareas de verdad). ]]
    barraEnVivo = true,
    tipos = { 'cables', 'tarjeta', 'secuencia', 'calibrar', 'numeros', 'palanca' },
    nombres = {
        cables = 'Reparar cables',
        tarjeta = 'Pasar la tarjeta',
        secuencia = 'Arrancar el reactor',
        calibrar = 'Calibrar el motor',
        numeros = 'Reiniciar el panel',
        palanca = 'Vaciar la basura',
    },
}
I.Reunion = {
    debate = 35,        -- segundos para hablar antes de votar
    voto = 25,          -- segundos para votar
    emergencias = 1,    -- botones de emergencia por jugador y ronda
    alcanceCuerpo = 3.0,
    alcanceBoton = 4.0, -- a cuánto del centro de la zona se pulsa la emergencia
    revelar = true,     -- decir si el expulsado era el impostor
}

--[[ El mono igual para todos (ajuste `disfraz` de la zona). Solo se pone a los
     personajes freemode; con cualquier otro modelo no se toca la ropa. Son
     las mismas piezas del uniforme de minero de origen_newjobs, que ya se usan
     en este servidor, sin el casco. Cada componente: { drawable, textura }. Si
     alguna no es válida para ese personaje, se deja la que llevaba.
     La ropa de antes se guarda en el cliente al ponerlo y se devuelve tal cual
     al acabar la ronda o salir: no se toca ni se guarda nada en la base. ]]
I.Disfraz = {
    hombre = {   -- mp_m_freemode_01
        componentes = {
            [1] = { 0, 0 },    -- máscara: ninguna
            [3] = { 64, 0 },   -- brazos
            [4] = { 39, 0 },   -- pantalón del mono
            [5] = { 0, 0 },    -- mochila: ninguna
            [6] = { 25, 0 },   -- botas
            [7] = { 0, 0 },    -- accesorios: ninguno
            [8] = { 15, 0 },   -- camiseta interior: ninguna
            [9] = { 0, 0 },    -- chaleco: ninguno
            [10] = { 0, 0 },   -- calcomanías: ninguna
            [11] = { 66, 0 },  -- mono
        },
        quitarProps = { 0, 1, 2, 6, 7 },   -- gorro, gafas, orejas, reloj, pulsera
    },
    mujer = {    -- mp_f_freemode_01
        componentes = {
            [1] = { 0, 0 },
            [3] = { 80, 0 },
            [4] = { 39, 0 },
            [5] = { 0, 0 },
            [6] = { 25, 0 },
            [7] = { 0, 0 },
            [8] = { 14, 0 },
            [9] = { 0, 0 },
            [10] = { 0, 0 },
            [11] = { 60, 0 },
        },
        quitarProps = { 0, 1, 2, 6, 7 },
    },
}

I.Puntos = {
    tarea = 3,
    votoCorrecto = 5,       -- votar al impostor que acaba expulsado
    eliminar = 8,           -- el impostor, por cada eliminación
    ganarTripulacion = 15,
    ganarImpostor = 25,
}

I.Teclas = {
    accion = { control = 38, texto = 'E' },       -- tarea · eliminar
    reportar = { control = 47, texto = 'G' },     -- reportar cuerpo · emergencia
}

I.ayuda = {
    {
        titulo = 'Cómo va',
        texto = 'Casi todos sois tripulantes; uno (o dos) es el impostor. Los tripulantes hacen tareas repartidas por la zona: cada una es un minijuego. El impostor elimina a escondidas. Si alguien encuentra un cuerpo, se convoca una reunión y se vota a quién echar.',
    },
    {
        titulo = 'Tripulante',
        teclas = {
            { tecla = 'E', texto = 'Pulsa junto a una tarea (la marca amarilla) y completa el minijuego.' },
            { tecla = 'G', texto = 'Reportar un cuerpo cercano o, en el centro, pulsar el botón de emergencia.' },
        },
        nota = 'La tripulación gana si termina todas las tareas o expulsa a los impostores.',
    },
    {
        titulo = 'Impostor',
        teclas = {
            { tecla = 'E', texto = 'Eliminar a quien tengas al lado. Tiene recarga. Sin nadie al lado, junto a una tarea falsa abre su minijuego para fingir.' },
            { tecla = 'G', texto = 'También puedes reportar para despistar.' },
        },
        nota = 'Gana el impostor si quedan tantos impostores como tripulantes.',
    },
    {
        titulo = 'Puntos',
        datos = { { k = 'Tarea', v = '+3' }, { k = 'Voto bueno', v = '+5' }, { k = 'Eliminar', v = '+8' } },
    },
}

Config.Juegos.impostor = I
