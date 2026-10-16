--[[ ── Paintball · rojos contra azules ─────────────────────────────────────── ]]

local P = {}

P.id = 'paintball'
P.nombre = 'Paintball'
P.lema = 'Rojos contra azules, sin sangre'
P.icono = 'paintball'
--- El dibujo de su chincheta en los dos mapas (origen_map e inventario).
P.iconoMapa = 'paintball'

P.jugadoresMin = 2
P.jugadoresMax = 20
P.rondas = { 1, 3 }
P.rondasDefecto = 1

P.modos = {
    { id = 'equipos', nombre = 'Por equipos', texto = 'Todos con la misma arma. Gana el equipo que más pinte antes de que acabe el tiempo.' },
    { id = 'armas', nombre = 'Juego de armas', texto = 'Cada equipo sube de arma al sumar pintadas. Gana el primero que termina la lista.' },
}

--- El vestíbulo de siempre del paintball, junto al Maze Bank Arena.
P.punto = { x = -280.7, y = -2030.83, z = 30.15 }

--[[ Las armas. `equipos`: las que puede elegir quien crea la sala. `armas`: la
     escalera del juego de armas, en orden, con las pintadas que el EQUIPO
     necesita para pasar a la siguiente. ]]
P.Armas = {
    { id = 'WEAPON_COMBATPISTOL', nombre = 'Pistola de combate' },
    { id = 'WEAPON_PISTOL_MK2', nombre = 'Pistola Mk II' },
    { id = 'WEAPON_HEAVYPISTOL', nombre = 'Pistola pesada' },
    { id = 'WEAPON_PISTOL50', nombre = 'Pistola .50' },
    { id = 'WEAPON_SNSPISTOL_MK2', nombre = 'Pistola SNS Mk II' },
    { id = 'WEAPON_VINTAGEPISTOL', nombre = 'Pistola vintage' },
    { id = 'WEAPON_PISTOLXM3', nombre = 'Pistola WM 29' },
    { id = 'WEAPON_APPISTOL', nombre = 'Pistola AP' },
    { id = 'WEAPON_NAVYREVOLVER', nombre = 'Revólver naval' },
    { id = 'WEAPON_MICROSMG', nombre = 'Micro SMG' },
    { id = 'WEAPON_SMG', nombre = 'Subfusil' },
    { id = 'WEAPON_ASSAULTSMG', nombre = 'Subfusil de asalto' },
    { id = 'WEAPON_PUMPSHOTGUN', nombre = 'Escopeta' },
    { id = 'WEAPON_BULLPUPSHOTGUN', nombre = 'Escopeta bullpup' },
    { id = 'WEAPON_ASSAULTRIFLE', nombre = 'Rifle de asalto' },
}

P.Escalera = {
    { arma = 'WEAPON_MUSKET', nombre = 'Mosquete', pintadas = 5 },
    { arma = 'WEAPON_AUTOSHOTGUN', nombre = 'Escopeta Sweeper', pintadas = 6 },
    { arma = 'WEAPON_TECPISTOL', nombre = 'SMG táctico', pintadas = 5 },
    { arma = 'WEAPON_STONE_HATCHET', nombre = 'Hacha de piedra', pintadas = 3, cuerpo = true },
    { arma = 'WEAPON_GUSENBERG', nombre = 'Gusenberg', pintadas = 4 },
    { arma = 'WEAPON_MARKSMANPISTOL', nombre = 'Pistola de tirador', pintadas = 4 },
    { arma = 'WEAPON_GADGETPISTOL', nombre = 'Pistola Perico', pintadas = 5 },
}

--- Lo que elige quien crea la sala. `modos`: solo sale en esos modos.
P.camposSala = {
    { id = 'arma', nombre = 'Arma', tipo = 'opciones', opciones = P.Armas, defecto = 'WEAPON_COMBATPISTOL', modos = { 'equipos' } },
    { id = 'duracion', nombre = 'Tiempo de partida', tipo = 'rango', min = 60, max = 900, paso = 60, defecto = 300, formato = 'reloj', modos = { 'equipos' } },
    { id = 'duracionArmas', nombre = 'Tiempo máximo', tipo = 'rango', min = 300, max = 1200, paso = 60, defecto = 600, formato = 'reloj', modos = { 'armas' },
      nota = 'Si nadie termina la lista, gana el equipo que vaya por un arma más alta.' },
}

--- Lo que pone el staff en cada arena.
P.campos = {
    { id = 'spawnRojo', nombre = 'Salida del equipo rojo', tipo = 'posicion', color = 'rojo' },
    { id = 'spawnAzul', nombre = 'Salida del equipo azul', tipo = 'posicion', color = 'azul' },
    { id = 'ymap', nombre = 'Ymap de la arena', tipo = 'texto', max = 60, opcional = true,
      nota = 'El nombre del ymap que hay que cargar para que exista la arena. Vacío si está en el mapa normal.' },
}

P.destacado = 'pintadas'

P.notaBote = 'Cada jugador paga la entrada del banco al unirse. El bote se lo reparte el equipo que gane la partida; si empatan, se reparte entre todos. Si la sala se deshace antes de empezar, se devuelve todo.'

--- La vida de la partida. El daño es el de GTA; la ambulancia no entra.
P.Vida = {
    maxima = 100,
    reaparecer = 3,            -- segundos pintado antes de volver a salir
    proteccion = 2.5,          -- segundos sin recibir al reaparecer
    alcance = 150.0,           -- metros a los que se acepta un disparo
    alcanceCuerpo = 4.0,
}

--- Si alguien cae por debajo de la arena (las de este servidor flotan en el
--- cielo), vuelve a su salida.
P.CaidaMaxima = 25.0

P.Puntos = {
    pintada = 1,
    cabeza = 1,                -- extra por pintar a la cabeza
    ganarRonda = 3,            -- a cada jugador del equipo que gana la ronda
}

P.ayuda = {
    {
        titulo = 'Cómo va',
        texto = 'Al empezar se reparten dos equipos, rojos y azules. Cada disparo que te llega te quita vida; sin vida quedas pintado y a los 3 segundos vuelves a salir desde tu base. Nadie se hace daño de verdad.',
    },
    {
        titulo = 'Los modos',
        texto = 'Por equipos: todos con la misma arma y gana el equipo que más pinte antes de que acabe el tiempo. Juego de armas: cada pintada de tu equipo suma para subir a la siguiente arma; gana el primero que termina la lista.',
    },
    {
        titulo = 'Teclas',
        teclas = {
            { tecla = 'F', texto = 'Mantener para abandonar la partida.' },
        },
        nota = 'Los compañeros llevan una bola verde encima de la cabeza.',
    },
    {
        titulo = 'Puntos',
        datos = { { k = 'Pintada', v = '+1' }, { k = 'A la cabeza', v = '+1' }, { k = 'Ganar ronda', v = '+3' } },
    },
}

Config.Juegos.paintball = P
