--[[ ── Escondite · props contra cazadores ─────────────────────────────────── ]]

local E = {}

E.id = 'escondite'
E.nombre = 'Escondite'
E.lema = 'Props contra cazadores'
E.icono = 'prop'
--- El dibujo de su chincheta en los dos mapas (origen_map e inventario).
E.iconoMapa = 'cono'

E.jugadoresMin = 2
E.jugadoresMax = 16
E.rondas = { 3, 5, 8 }
E.rondasDefecto = 5

E.modos = {
    { id = 'clasico', nombre = 'Clásico', texto = 'El prop que cazan pasa a mirar. Gana la ronda quien aguante hasta el final.' },
    { id = 'infeccion', nombre = 'Infección', texto = 'El prop que cazan se une a los cazadores. Cada vez hay más buscando.' },
}

--- Dónde está su punto del mapa hasta que el staff lo mueva.
E.punto = { x = 195.17, y = -933.77, z = 30.69 }

--- La zona con la que se siembra la base de datos la primera vez.
E.zonaSemilla = { nombre = 'Plaza de la Legión', x = 195.17, y = -933.77, z = 29.7, radio = 55.0 }

--- Lo que el staff ajusta en cada zona de este juego.
E.campos = {
    { id = 'colocacion', nombre = 'Tiempo para esconderse', tipo = 'rango', min = 20, max = 180, paso = 5, defecto = 60, formato = 'reloj' },
    { id = 'busqueda', nombre = 'Tiempo de caza', tipo = 'rango', min = 60, max = 600, paso = 15, defecto = 240, formato = 'reloj' },
    { id = 'props', nombre = 'Props del sorteo', tipo = 'props', nota = 'Sin ninguno marcado se sortea entre todos. Copiar con el láser funciona con cualquiera del catálogo.' },
}

--- Cómo se llama en el ranking la cifra propia de este juego.
E.destacado = 'capturas'

E.Cazador = {
    arma = 'WEAPON_PISTOL',
    vida = 100,
    fallo = 5,          -- vida que quita un disparo que no da a nadie
    dano = 20,          -- lo que quita un disparo que acierta
    alcance = 70.0,
    cadencia = 320,     -- ms mínimos entre dos disparos que cuentan
    porCada = 5,        -- un cazador por cada tantos jugadores
}

E.Props = {
    cambios = 3,
    vida = { pequeno = 20, mediano = 40, grande = 60 },
    alcanceCopia = 25.0,
    tolerancia = 2.5,
}

E.Herramientas = {
    sonar = { enfriamiento = 35, radio = 20.0 },
    ruido = { enfriamiento = 50, radio = 25.0 },
    pista = { radio = 18.0, duracion = 25 },
}

E.Burlas = {
    enfriamiento = 8,
    alcance = 45.0,
    forzadaCada = 45,
    finalDesde = 30,
    finalCada = 12,
    tipos = { 'silbido', 'bocina', 'pedo', 'pato', 'muelle', 'risa', 'grillo', 'pitido' },
}

E.Huida = { veces = 1, segundos = 5 }

E.Puntos = {
    captura = 10,
    sobrevivir = 15,
    cadaMedioMinuto = 1,
    burla = 2,
    rondaCazador = 5,
}

E.Teclas = {
    cambiar = { control = 47, texto = 'G' },    -- prop: otro prop · cazador: sonar
    copiar = { control = 38, texto = 'E' },     -- prop: copiar con el láser
    burla = { control = 29, texto = 'B' },
    huir = { control = 74, texto = 'H' },       -- prop: huida · cazador: ruido
    girarIzq = { control = 174, texto = '←' },
    girarDer = { control = 175, texto = '→' },
}

E.ayuda = {
    {
        titulo = 'La ronda',
        texto = 'Cada ronda sale un cazador al azar (uno de cada cinco) y los demás se convierten en props. Primero hay un rato para esconderse mientras el cazador espera a oscuras. Después los props se quedan quietos y el cazador sale a buscarlos. No se puede salir de la zona.',
    },
    {
        titulo = 'Si eres prop',
        teclas = {
            { tecla = 'G', texto = 'Otro prop al azar. 3 cambios por ronda, solo mientras te escondes.' },
            { tecla = 'E', texto = 'Apunta con el láser a un objeto del mapa y conviértete en él: rosa si se puede, blanco si no.' },
            { tecla = '← →', texto = 'Girarte para encajar con lo que hay alrededor.' },
            { tecla = 'B', texto = 'Burla: un ruido que da 2 puntos en la búsqueda, pero te delata.' },
            { tecla = 'H', texto = 'Una vez por ronda: te descongelas unos segundos para huir.' },
        },
        nota = 'La voz sale de donde estás y cada cierto tiempo todos los props suenan solos: nadie gana callado.',
    },
    {
        titulo = 'Si eres cazador',
        teclas = {
            { tecla = 'Clic', texto = 'Disparar. Cada fallo te quita 5 de vida; a cero, estás fuera.' },
            { tecla = 'G', texto = 'Sonar: cuántos props hay cerca.' },
            { tecla = 'H', texto = 'Ruido: obliga a sonar a los props de alrededor.' },
        },
        nota = 'A mitad de la búsqueda aparece una pista: una zona donde se esconde el prop más cercano.',
    },
    {
        titulo = 'Puntos',
        datos = { { k = 'Captura', v = '+10' }, { k = 'Aguantar', v = '+15' }, { k = 'Cada 30 s', v = '+1' } },
    },
}

Config.Juegos.escondite = E
