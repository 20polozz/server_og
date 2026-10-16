--[[ Origen Bingo.

     Bingo español de 90 bolas. Hay UNA partida para todo el servidor: todas
     las salas enseñan la misma, y un cartón comprado en cualquier taquilla
     juega en ella.

     Aquí no hay salas escritas: se colocan desde dentro del juego con el
     configurador (/bingoconfig) y viven en la base de datos. Lo que está aquí
     son los valores de partida de los ajustes; desde el configurador se
     cambian sin reiniciar, y a partir de ese momento mandan los de la base
     de datos (botón «Volver a los del config» para deshacerlo).

     La regla que manda: **las bolas, los cartones y los premios los decide el
     servidor**. El cliente solo pinta. ]]

Config = {}

--- Quién puede abrir el configurador: el permiso «Gestionar Bingo» de
--- origen_admin, que es también el que enseña su tarjeta en la pestaña Scripts.
Config.Permiso = 'origen_bingo'
Config.Comando = 'bingoconfig'

--[[ ── Las partidas ──────────────────────────────────────────────────────────

     cada        minutos entre el principio de una partida y el de la siguiente.
                 La venta está abierta todo el rato que no se juega.
     bola        segundos entre bola y bola.
     minimo      cartones vendidos para que la partida se juegue. Si no se
                 llega, se aplaza otra vuelta y los cartones siguen valiendo.
     precio      lo que cuesta un cartón.
     porJugador  cartones que puede tener un jugador en una partida.
     total       cartones en una partida, entre todos.
     pago        con qué se pagan los cartones: 'efectivo', 'banco' o 'ambos'.
     cobro       dónde se cobran los premios: 'efectivo' o 'banco'.

     Los premios son una parte fija más un tanto por ciento de lo recaudado
     en esa partida. Si cantan dos a la vez, se reparte a partes iguales.
     Ojo con la parte fija: se paga aunque se vendan dos cartones, así que
     ese dinero sale de la nada. Con solo porcentaje, la casa se queda lo que
     no se reparte (aquí, el 20 %) y nunca se crea dinero. ]]
Config.Ajustes = {
    cada = 10,
    bola = 5,
    minimo = 1,
    precio = 250,
    porJugador = 6,
    total = 400,
    pago = 'ambos',
    cobro = 'banco',
    linea = { fijo = 0, porcentaje = 20 },
    bingo = { fijo = 0, porcentaje = 60 },
}

--- Los límites de lo que se puede poner desde el configurador.
Config.Limites = {
    cada = { 2, 120 },
    bola = { 2, 30 },
    minimo = { 1, 50 },
    precio = { 1, 100000 },
    porJugador = { 1, 24 },
    total = { 10, 2000 },
    fijo = { 0, 5000000 },
    porcentaje = { 0, 100 },
}

--- Lo que se queda la casa (lo recaudado menos los premios) va a este negocio
--- de origen_businesses, si hay uno. false = a ninguno.
Config.Sociedad = false

--- Segundos que se queda en las pantallas el resultado antes de abrir la venta.
Config.Resultado = 20

--[[ ── Las salas ─────────────────────────────────────────────────────────────

     Una sala es un sitio con un nombre. Dentro van sus piezas:
       · bombo      la máquina de las bolas (prop propio), con su cesta
       · panel      el tablero grande con la pantalla de lo que va saliendo
       · taquilla   donde se compran los cartones (con o sin empleado)

     Las piezas no pueden alejarse más de `Radio` del centro de su sala, y
     quien esté dentro de ese radio ve su cartón en pantalla mientras se
     juega. ]]
Config.Radio = 40.0
Config.Distancia = 120.0         -- desde cuánto se ponen las piezas de una sala
Config.Alcance = 2.2             -- a cuánto de la taquilla hay que estar para comprar
Config.Topes = { salas = 20, piezas = 30 }

Config.Piezas = {
    { id = 'bombo', nombre = 'Bombo', modelo = 'origen_bingo_bombo', icono = 'bombo' },
    { id = 'panel', nombre = 'Panel grande', modelo = 'origen_bingo_panel', icono = 'panel' },
    { id = 'pantalla', nombre = 'Pantalla de pared', modelo = 'origen_bingo_pantalla', icono = 'panel' },
    { id = 'taquilla', nombre = 'Taquilla', modelo = 'origen_bingo_taquilla', icono = 'taquilla' },
    { id = 'empleado', nombre = 'Taquilla con empleado', ped = 's_f_y_casino_01', icono = 'taquilla' },
}
Config.Pieza = {}
for _, p in ipairs(Config.Piezas) do Config.Pieza[p.id] = p end

--- Para el blip de cada sala en el mapa (origen_map).
Config.Mapa = { cat = 'activities', icono = 'casino' }
