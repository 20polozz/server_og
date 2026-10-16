--[[ ══════════════════════════════════════════════════════════════════════════
     LA CONFIGURACIÓN DE PARTIDA DEL CASINO

     Esto es la lista de salida, no la verdad. Lo que un administrador cambia
     en el panel se guarda en `origen_casino_ajustes` y PISA lo que hay aquí al
     arrancar (ver server/ajustes.lua). Por eso las tablas de aquí se rellenan,
     nunca se sustituyen: hay ficheros que guardan la referencia al cargar.

     Las mesas, las máquinas, la caja y los empleados NO están aquí: se colocan
     desde el panel de admin, uno a uno, y viven en `origen_casino_puntos`. Lo
     que hay aquí es el CATÁLOGO de lo que se puede colocar (shared/catalogo.lua)
     y las reglas de cada juego.
   ══════════════════════════════════════════════════════════════════════════ ]]

Config = {}

--- Líneas extra en la consola. Se queda en false en producción.
Config.Depurar = false

-- ═══ Lo general ═══════════════════════════════════════════════════════════

Config.General = {
    nombre = 'Casino Diamond',

    --[[ El recinto. Sirve para tres cosas: saber si alguien está dentro sin
         recorrer todas las mesas, apagar el casino entero de una vez y pintar
         el blip principal. `radio` es en planta (x, y): un casino de dos
         plantas sigue siendo el mismo sitio. ]]
    zona = { x = 935.0, y = 46.0, z = 71.0, radio = 90.0 },

    --- El blip del recinto en el mapa de la casa (origen_map).
    blip = { activo = true, nombre = 'Casino', icono = 'casino' },

    --[[ Cerrado por reforma: nadie puede apostar, ni siquiera un admin. El
         panel lo enciende y lo apaga sin reiniciar nada. ]]
    abierto = true,
    mensajeCerrado = 'El casino está cerrado ahora mismo.',

    --[[ Horario. Fuera de él no se puede apostar (las mesas siguen puestas y
         se puede entrar). `abre` y `cierra` son horas del juego, 0-23. Con los
         dos iguales, abierto las 24 h. ]]
    horario = { activo = false, abre = 10, cierra = 4 },

    --- El negocio de origen_businesses al que va lo que gana la casa. false = a
    --- ninguno. Es el mismo identificador que usa el casino de rcore.
    sociedad = '142',
}

-- ═══ Las fichas ═══════════════════════════════════════════════════════════

--[[ Las fichas NO son un objeto del inventario. Son un saldo en la base,
     atado al ciudadano, y esto es a propósito: un objeto se puede duplicar con
     un fallo de otro recurso, se puede tirar al suelo y se puede pasar de mano
     en mano para lavar dinero. Un saldo no. Lo único que se puede hacer con
     fichas es jugar, y volver a convertirlas en dinero en la caja. ]]
Config.Fichas = {
    --- Lo que cuesta UNA ficha al comprarla, en dólares.
    precioCompra = 1,

    --[[ Lo que te dan por UNA ficha al venderla. Con 0.95 la casa se queda el
         5 % de todo lo que entra y sale, que es el suelo de lo que gana el
         casino aunque nadie juegue. A 1 no hay comisión. ]]
    precioVenta = 1.0,

    --- Lo máximo que se puede tener en fichas a la vez.
    topeSaldo = 5000000,

    --- Topes por día natural (se reinician a las 00:00 del servidor).
    compraDiaria = 500000,
    ventaDiaria = 2000000,

    --- Lo mínimo y lo máximo de una sola operación en la caja.
    minimoOperacion = 100,
    maximoOperacion = 250000,

    --[[ De dónde sale el dinero al comprar. 'banco' pregunta con qué cuenta
         (origen_banking), 'efectivo' lo coge del bolsillo, 'ambos' deja
         elegir en la pantalla. Lo que se cobra al vender va siempre al banco:
         nadie sale del casino con dos millones en el bolsillo. ]]
    pagoCompra = 'ambos',
    pagoVenta = 'banco',
}

-- ═══ La membresía ═════════════════════════════════════════════════════════

--[[ La tarjeta de socio. Es lo que pide el empleado de la caja antes de darte
     fichas, y lo que piden las máquinas antes de dejarte jugar.

     Regla de la casa, aprendida por las malas: **entrar es libre, jugar no**.
     El día que la membresía se pidió en la puerta, el casino se quedó cerrado
     para todo el servidor —la tarjeta acababa de nacer y no la tenía nadie— y
     se vivió como si estuviera todo el mundo baneado. ]]
Config.Membresia = {
    activa = true,

    --- Lo que cuesta y lo que dura.
    precio = 15000,
    dias = 7,

    --[[ Renovar antes de que caduque SUMA días a lo que quede. Esto es el tope
         de días por delante que se pueden llevar pagados, para que nadie
         compre un año de golpe el día que va sobrado. ]]
    topeDias = 28,

    --- Dónde hace falta. `caja` = comprar fichas. `mesas` = sentarse a jugar.
    exigirEnCaja = true,
    exigirEnMesas = true,

    --- Quién pasa sin ella: los que trabajan allí (identificador de negocio).
    trabajosExentos = { ['142'] = true },

    --[[ Un nivel de socio por encima: paga más, y a cambio sube los topes de
         apuesta y se lleva un porcentaje de vuelta de lo perdido. `activo` en
         false para no tener socios VIP. ]]
    vip = {
        activo = true,
        precio = 75000,
        dias = 7,
        multiplicadorApuesta = 5.0,   -- el tope de apuesta se multiplica por esto
        devolucion = 0.05,            -- del 0 al 1: lo que se devuelve de lo perdido al día
        devolucionTope = 100000,
    },
}

-- ═══ Los topes ════════════════════════════════════════════════════════════

--[[ El freno de mano. Nada de esto es una sugerencia: el servidor lo aplica en
     cada apuesta, y cuando salta, salta. Un casino sin topes es una impresora
     de dinero en cuanto alguien encuentra la grieta de un juego. ]]
Config.Limites = {
    --- Lo que se puede ganar y perder en un día natural, en fichas.
    gananciaDiaria = 3000000,
    perdidaDiaria = 1500000,

    --[[ Lo que la casa puede pagar de una sola vez. Un pleno a la ruleta con
         la apuesta máxima puede ser mucho dinero: esto es el techo. ]]
    pagoMaximo = 2000000,

    --- Segundos que una mesa aguanta a un jugador sin que haga nada.
    inactividad = 180,

    --- Milisegundos mínimos entre dos jugadas del mismo jugador.
    ritmoJugada = 400,
}

-- ═══ Los juegos ═══════════════════════════════════════════════════════════

--[[ Lo común a todos. Cada juego trae además su tabla propia más abajo.

     `min` y `max` son la apuesta en FICHAS. `activo` en false apaga el juego
     entero sin tener que quitar las mesas del mundo: se quedan puestas y
     dicen que están fuera de servicio. ]]
Config.Juegos = {
    tragaperras = { activo = true, nombre = 'Tragaperras', min = 50, max = 5000 },
    ruleta      = { activo = true, nombre = 'Ruleta', min = 100, max = 50000 },
    blackjack   = { activo = true, nombre = 'Blackjack', min = 500, max = 100000 },
    pokertres   = { activo = true, nombre = 'Póker de tres cartas', min = 500, max = 50000 },
    holdem      = { activo = true, nombre = 'Texas Hold em', min = 100, max = 25000 },
    caballos    = { activo = true, nombre = 'Carreras de caballos', min = 100, max = 100000 },
    rueda       = { activo = true, nombre = 'Rueda de la suerte', min = 0, max = 0 },
    -- Las máquinas de vídeo (sus números, en shared/video.lua).
    golpe       = { activo = true, nombre = 'El Golpe', min = 50, max = 5000 },
    clasica     = { activo = true, nombre = 'Vinewood', min = 50, max = 5000 },
    atrapa      = { activo = true, nombre = 'Atrapa y gana', min = 50, max = 5000 },
    cascadas    = { activo = true, nombre = 'Fiebre', min = 50, max = 5000 },
}

-- ═══ Tragaperras ══════════════════════════════════════════════════════════

--[[ Tres rodillos y una línea. Los símbolos llevan un PESO: cuanto más pesa,
     más veces sale. El porcentaje de devolución (lo que la máquina devuelve a
     largo plazo por cada 100 fichas que se meten) sale solo de estos números,
     y el panel de admin lo calcula y lo enseña al editarlos: cambiar un pago
     sin ver qué le hace a la devolución es llevar el negocio a ciegas.

     Con los valores de salida la devolución es del 92 % largo. Por debajo del
     85 % la máquina se nota rácana y la gente deja de jugar; por encima del
     98 % el casino pierde dinero. ]]
Config.Tragaperras = {
    --- El símbolo, su peso en el rodillo y lo que paga salir tres.
    simbolos = {
        { id = 'siete',     nombre = 'Siete',     peso = 1,  paga3 = 0,   jackpot = true },
        { id = 'diamante',  nombre = 'Diamante',  peso = 2,  paga3 = 500 },
        { id = 'campana',   nombre = 'Campana',   peso = 4,  paga3 = 150 },
        { id = 'herradura', nombre = 'Herradura', peso = 6,  paga3 = 60 },
        { id = 'naranja',   nombre = 'Naranja',   peso = 8,  paga3 = 22 },
        { id = 'limon',     nombre = 'Limón',     peso = 10, paga3 = 10 },
        { id = 'cereza',    nombre = 'Cereza',    peso = 12, paga3 = 6, paga2 = 1 },
    },

    --[[ El bote. Se lleva un porcentaje de cada apuesta y lo suelta entero
         cuando salen tres sietes. Es común a TODAS las máquinas del servidor:
         es lo que hace que merezca la pena mirarlo. ]]
    jackpot = {
        activo = true,
        semilla = 250000,     -- con lo que arranca, y a lo que vuelve tras caer
        porcentaje = 0.01,    -- de cada apuesta
        tope = 25000000,
    },

    --- Cuánto dura el giro en la pantalla, en milisegundos.
    duracionGiro = 2200,

    --- Las apuestas que ofrece la máquina (siempre dentro del min/max del juego).
    fichas = { 50, 100, 250, 500, 1000, 2500, 5000 },
}

-- ═══ Ruleta ═══════════════════════════════════════════════════════════════

--[[ Ruleta europea: un solo cero, del 0 al 36. La ventaja de la casa sale del
     cero y es del 2,7 %; no hace falta tocar ningún pago para que el casino
     gane. Si alguien pone un segundo cero (`doble`), sube al 5,26 %.

     La mesa va por RONDAS: se abren las apuestas, se cierran, gira y paga.
     Todo el que esté sentado juega la misma ronda, que es lo que hace que una
     mesa de ruleta sea un sitio y no un menú. ]]
Config.Ruleta = {
    doble = false,             -- true = ruleta americana (00)
    segundosApuestas = 30,
    segundosGiro = 14,
    segundosPago = 8,

    --- Lo que paga cada tipo de apuesta, a 1. Un pleno a 35 devuelve 36.
    pagos = {
        pleno = 35,            -- un número
        caballo = 17,          -- dos números pegados
        transversal = 11,      -- una fila de tres
        cuadro = 8,            -- cuatro en cuadro
        linea = 5,             -- dos filas, seis números
        docena = 2,
        columna = 2,
        color = 1,             -- rojo / negro
        paridad = 1,           -- par / impar
        mitad = 1,             -- falta / pasa
    },

    --- Lo máximo por tipo de apuesta, en fichas (además del tope del juego).
    topes = { pleno = 5000, caballo = 10000, transversal = 15000, cuadro = 20000,
              linea = 30000, docena = 50000, columna = 50000, color = 50000,
              paridad = 50000, mitad = 50000 },

    --- Cuántas apuestas distintas puede poner un jugador en una ronda.
    maximoApuestas = 24,
}

-- ═══ Blackjack ════════════════════════════════════════════════════════════

Config.Blackjack = {
    barajas = 6,
    --- Cuando queda menos de esta parte sin repartir, se vuelve a barajar.
    rebarajarEn = 0.35,

    --- Lo que paga un blackjack: 1.5 es 3 a 2, 1.2 es 6 a 5 (rácano).
    pagoBlackjack = 1.5,

    --- El crupier se planta en 17. Con `blandoSePlanta` en false pide con 17
    --- blando (as + 6), que es peor para el jugador.
    plantarEn = 17,
    blandoSePlanta = true,

    permitirDoblar = true,
    doblarSolo = { 9, 10, 11 },   -- vacío = doblar con cualquier mano
    permitirSepararse = true,
    separacionesMax = 1,
    permitirSeguro = true,
    permitirRendirse = false,

    --- Segundos que tiene un jugador para decidir antes de que se le plante solo.
    segundosTurno = 25,
    --- Segundos de la ventana de apuestas de cada mano.
    segundosApuestas = 20,
}

-- ═══ Póker de tres cartas ═════════════════════════════════════════════════

--[[ El de la mesa del casino de GTA: no se juega contra nadie, se juega contra
     el crupier. Se pone la entrada, se ven tres cartas y se decide si se sigue
     (poniendo otro tanto) o se tira. El crupier necesita reina o más para
     "entrar"; si no entra, la entrada paga 1 a 1 y lo apostado se devuelve. ]]
Config.PokerTres = {
    --- La carta mínima que necesita el crupier para entrar. 12 = reina.
    crupierEntraCon = 12,

    --- La bonificación de la entrada, que se paga entre o no entre el crupier.
    bonoEntrada = { escaleraColor = 5, trio = 4, escalera = 1 },

    --- La apuesta lateral "pareja o mejor", que se paga sola.
    parejaOMejor = {
        activa = true,
        pagos = { escaleraColor = 40, trio = 30, escalera = 6, color = 3, pareja = 1 },
        topeApuesta = 10000,
    },

    --- La ronda es común a toda la mesa, como en el casino: una ventana para
    --- apostar y otra para decidir. Al acabarse la de decidir, quien no ha
    --- dicho nada se retira.
    segundosApuestas = 20,
    segundosDecidir = 20,
}

-- ═══ Texas Hold em ════════════════════════════════════════════════════════

--[[ Este sí es entre jugadores: la casa no juega, solo se queda una comisión
     del bote. Es el único juego del casino donde un jugador puede quedarse el
     dinero de otro, así que la comisión es lo único que gana la casa y el
     resto se reparte entero. ]]
Config.Holdem = {
    jugadoresMax = 6,
    jugadoresMin = 2,

    --- Las ciegas. La grande es el doble de la pequeña.
    ciegaPequena = 100,

    --- Lo que hay que traer a la mesa: mínimo y máximo, en ciegas grandes.
    entradaMin = 20,
    entradaMax = 200,

    --- La comisión de la casa: porcentaje del bote y tope por mano.
    comision = 0.05,
    comisionTope = 5000,

    --- Segundos para decidir. Al pasarse, se retira (o pasa, si es gratis).
    segundosTurno = 30,
    --- Segundos entre manos.
    segundosEntreManos = 8,
}

-- ═══ Carreras de caballos ═════════════════════════════════════════════════

--[[ Inside Track. Seis caballos, una carrera cada pocos minutos, y las cuotas
     salen de la forma de cada caballo más el margen de la casa. El resultado
     lo decide el servidor ANTES de que empiece la carrera y lo guarda: lo que
     se ve correr en las pantallas es la representación de algo ya escrito.

     Las cuotas se recalculan en cada carrera con las formas de ese momento,
     así que no hay un caballo que siempre pague igual. ]]
Config.Caballos = {
    caballos = {
        { id = 1, nombre = 'Ruso Blanco',    color = '#8a8270' },
        { id = 2, nombre = 'Pulpo Feroz',    color = '#b4471f' },
        { id = 3, nombre = 'Doble Whisky',   color = '#c8a23a' },
        { id = 4, nombre = 'Rey Rojo',       color = '#c00a46' },
        { id = 5, nombre = 'Zumo de Sol',    color = '#3c8f5a' },
        { id = 6, nombre = 'Brisa Nocturna', color = '#3a5fa8' },
    },

    --- Cada cuántos segundos empieza una carrera, y lo que dura cada fase.
    cadaSegundos = 300,
    segundosApuestas = 120,
    segundosCarrera = 55,

    --[[ El margen de la casa: con 0.12 las cuotas suman el 112 %, o sea que a
         largo plazo la casa se queda el 11 % de lo apostado. ]]
    margen = 0.12,

    --- Qué se puede apostar.
    modos = { ganador = true, colocado = true },
    --- Con cuánto se divide la cuota al apostar a colocado (1º o 2º).
    divisorColocado = 3.0,

    --- El tope de cuota: nada paga más de esto, pase lo que pase.
    cuotaMaxima = 25.0,
}

-- ═══ La rueda de la suerte ════════════════════════════════════════════════

--[[ Un giro por persona cada tantas horas, gratis. No es un juego de apuesta:
     es el motivo para pasarse por el casino todos los días. Los premios llevan
     PESO, igual que los rodillos; el coche gordo casi nunca sale y eso es
     justo lo que lo hace valer. ]]
Config.Rueda = {
    horas = 24,

    --[[ Las 20 casillas de la rueda de GTA, EN SU ORDEN: la primera es la que
         está bajo la aguja con la rueda en reposo y las demás siguen en el
         sentido de las agujas del reloj (client/rueda.lua). Los valores son
         los que lleva pintados la rueda, para que lo que se ve sea lo que se
         cobra; el peso sí es nuestro. «Drinks» y el «?» dan un objeto; el «$»
         es fama; la bolsa, dinero al banco; las fichas, fichas. Si se cambia
         el orden o se quita una, la rueda para en otra casilla. ]]
    premios = {
        { id = 'bebida1',  tipo = 'sorpresa', nombre = 'Bebidas',          valor = 0,     peso = 8 },
        { id = 'fama1',    tipo = 'xp',       nombre = '500 de fama',      valor = 500,   peso = 9 },
        { id = 'dinero1',  tipo = 'dinero',   nombre = '5.500 $',          valor = 5500,  peso = 7 },
        { id = 'fichas1',  tipo = 'fichas',   nombre = '2.000 fichas',     valor = 2000,  peso = 8 },
        { id = 'nada',     tipo = 'nada',     nombre = 'Nada',             valor = 0,     peso = 12 },
        { id = 'fama2',    tipo = 'xp',       nombre = '1.000 de fama',    valor = 1000,  peso = 6 },
        { id = 'dinero2',  tipo = 'dinero',   nombre = '7.500 $',          valor = 7500,  peso = 5 },
        { id = 'fichas2',  tipo = 'fichas',   nombre = '3.500 fichas',     valor = 3500,  peso = 6 },
        { id = 'bebida2',  tipo = 'sorpresa', nombre = 'Bebidas',          valor = 0,     peso = 8 },
        { id = 'fama3',    tipo = 'xp',       nombre = '1.500 de fama',    valor = 1500,  peso = 7 },
        { id = 'fichas3',  tipo = 'fichas',   nombre = '5.500 fichas',     valor = 5500,  peso = 5 },
        { id = 'misterio', tipo = 'sorpresa', nombre = 'Sorpresa',         valor = 0,     peso = 5 },
        { id = 'bebida3',  tipo = 'sorpresa', nombre = 'Bebidas',          valor = 0,     peso = 8 },
        { id = 'fama4',    tipo = 'xp',       nombre = '2.000 de fama',    valor = 2000,  peso = 4 },
        { id = 'dinero3',  tipo = 'dinero',   nombre = '15.000 $',         valor = 15000, peso = 3 },
        { id = 'fichas4',  tipo = 'fichas',   nombre = '2.000 fichas',     valor = 2000,  peso = 8 },
        { id = 'bebida4',  tipo = 'sorpresa', nombre = 'Bebidas',          valor = 0,     peso = 8 },
        { id = 'fama5',    tipo = 'xp',       nombre = '3.500 de fama',    valor = 3500,  peso = 3 },
        { id = 'coche',    tipo = 'vehiculo', nombre = 'El coche del mes', valor = 0,     peso = 1,
          vehiculo = 'zion3', anuncio = true },
        { id = 'dinero4',  tipo = 'dinero',   nombre = '20.000 $',         valor = 20000, peso = 2 },
    },

    --- Lo que puede caer en «Sorpresa»: objetos del inventario.
    sorpresa = {
        { item = 'water_bottle', cantidad = 5, peso = 20 },
        { item = 'sandwich',     cantidad = 5, peso = 20 },
        { item = 'lockpick',     cantidad = 1, peso = 10 },
    },

    duracionGiro = 9000,
}

if GetConvar('origen:marca', 'origen') == 'nacion' then
    local fichasEnLugarDeFama = {
        fama1 = { id = 'fichas5', tipo = 'fichas', nombre = '500 fichas',   valor = 500,  peso = 9 },
        fama2 = { id = 'fichas6', tipo = 'fichas', nombre = '1.000 fichas', valor = 1000, peso = 6 },
        fama3 = { id = 'fichas7', tipo = 'fichas', nombre = '1.500 fichas', valor = 1500, peso = 7 },
        fama4 = { id = 'fichas8', tipo = 'fichas', nombre = '2.000 fichas', valor = 2000, peso = 4 },
        fama5 = { id = 'fichas9', tipo = 'fichas', nombre = '3.500 fichas', valor = 3500, peso = 3 },
    }
    for i, premio in ipairs(Config.Rueda.premios) do
        Config.Rueda.premios[i] = fichasEnLugarDeFama[premio.id] or premio
    end
end

-- ═══ Vigilancia ═══════════════════════════════════════════════════════════

--[[ Lo que mira el panel de admin para avisar de que alguien está ganando de
     una forma que no cuadra. No castiga a nadie: pinta la fila en ámbar y deja
     que un humano decida. Un casino es el sitio del servidor donde antes se
     nota que un juego tiene una grieta. ]]
Config.Vigilancia = {
    ganadoPorHora = 500000,    -- fichas ganadas en una hora que ya llaman la atención
    jugadasPorHora = 400,      -- jugadas en una hora (un bot pulsa más deprisa que una mano)
    rachaSospechosa = 12,      -- victorias seguidas en un juego de azar puro
    diasRegistro = 30,

    --- El permiso de origen_admin que abre el panel.
    permiso = 'origen_casino',
}
