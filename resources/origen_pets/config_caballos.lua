--[[ ── Montar a caballo ─────────────────────────────────────────────────────
     Los caballos son mascotas como las demas (razas con modelo de caballo en
     config.lua o en el catalogo); esto es lo que hace falta para montarlos.
     El codigo va en client/caballos.lua y server/caballos.lua. ]]
Config.Caballos = {}

--[[ Los caballos que se pueden montar. Todos llevan el esqueleto y las
     animaciones del ciervo (peds.meta del pack de animales), asi que andan,
     trotan y galopan como el; lo que cambia de uno a otro es el cuerpo.

     `asiento` es donde va el jinete respecto al hueso del lomo: `atras` en
     negativo, `alto` hacia arriba, e `inclina` los grados que se le echa hacia
     atras para que vaya derecho (sin nada cae 5 grados hacia delante; medido: con 5 el tronco queda a 0). `boca` es donde acaban las riendas respecto
     al hueso de la cabeza: a lo largo del morro, a cada lado y hacia abajo;
     sin `boca` no se pintan (el de policia las trae en el modelo). Todo
     medido en partida con fotos. ]]
Config.Caballos.Modelos = {
    ft_ahorse = {
        nombre = 'Cuarto de milla',
        asiento = { atras = -0.22, alto = 0.27, inclina = 5.0 },
        boca = { morro = 0.50, ancho = 0.07, abajo = -0.10 },
    },
    a_c_horse_police = {
        nombre = 'Caballo de policia',
        asiento = { atras = -0.24, alto = 0.44, inclina = 5.0 },
    },
    ft_horse = {
        nombre = 'Poni pinto',
        asiento = { atras = -0.36, alto = 0.23, inclina = 5.0 },
        boca = { morro = 0.48, ancho = 0.06, abajo = -0.10 },
    },
}

--[[ Lo que se le puede poner a cada caballo, revisado en el juego una a una
     (15/10): { [pieza] = { [drawable] = { texturas } } }, como shared/texturas.lua.
     El .ymt de a_c_horse_police declara tres pelajes pero el pack solo traia el
     primero (los otros salian transparentes); el 15/10 se pintaron y se
     metieron en su .ytd: 0 = manta verde con estrella (sheriff), 1 = manta azul
     con placa (policia), 2 = manta marron lisa. La pieza 8 (la cola) no se toca.
       a_c_horse_police  pieza 0 = silla: 0 sheriff, 1 policia, 2 lisa
       ft_ahorse  pieza 2 = montura: 0/0 Sheriff K-9, 0/1 Police K-9, 0/2 civil marron
                  (pintada el 15/10, con su entrada en el .ymt), 1/0 sin montura
       ft_horse   pieza 0 = pelaje: seis ]]
Config.Caballos.Piezas = {
    a_c_horse_police = { [0] = { [0] = { 0, 1, 2 } } },
    ft_ahorse = { [2] = { [0] = { 0, 1, 2 }, [1] = { 0 } } },
    ft_horse = { [0] = { [0] = { 0, 1, 2, 3, 4, 5 } } },
}

-- SKEL_Spine1 del ciervo: cae bajo la silla y apenas cabecea.
Config.Caballos.HuesoLomo = 24816

-- La postura del jinete, en dos capas (ver client.lua): piernas del quad y,
-- de cintura para arriba, el tronco recto de la chopper.
Config.Caballos.Postura = {
    piernas = { dict = 'veh@bike@quad@front@base',    anim = 'sit' },
    tronco  = { dict = 'veh@bike@chopper@front@base', anim = 'sit' },
}

-- A partir de esta velocidad (m/s) el jinete suelta el tronco y se inclina. El trote
-- va a 4,5 y el galope a 15,6.
Config.Caballos.VelocidadGalope = 8.0

--[[ Disparar montado, como desde la moto: solo armas de una mano. El jinete
     sigue sentado y el tronco pone el disparo del quad (`sweep_*`), parado en
     la fase que toca segun hacia donde mira la camara: 0 es atras por la
     izquierda, 0,25 la izquierda, 0,5 delante, 0,75 la derecha y 1 atras por
     la derecha. Low/med/high segun se mire abajo, al frente o arriba.
     `cadencia`: segundos entre tiros; las pistolas, un tiro por clic. ]]
Config.Caballos.Disparo = {
    activo = true,
    grupos = { `GROUP_PISTOL` },
    armas = { `WEAPON_MICROSMG`, `WEAPON_MACHINEPISTOL`, `WEAPON_MINISMG` },
    dict = 'veh@drivebybike@quad@front@1h',
    bajo = -12.0, alto = 14.0,   -- grados de camara para pasar a low / high
    cadencia = { pistola = 0.25, rafaga = 0.09 },
}

-- El paso del caballo (lo que el juego llama «move blend ratio»).
Config.Caballos.Paso   = 1.0   -- Ctrl
Config.Caballos.Trote  = 2.0   -- sin nada
Config.Caballos.Galope = 3.0   -- Mayusculas

Config.Caballos.DistanciaMontar = 2.2

-- Lo que gira el caballo, en grados por segundo, a cada paso: al galope abre
-- mas la curva. Lo giramos nosotros: si se le deja al juego, frena en cada giro.
Config.Caballos.Giro = { paso = 220.0, trote = 170.0, galope = 120.0 }

--[[ Los brazos. `ancho`, `delante` y `alto` son donde descansan las manos
     respecto al jinete. `sigue` es cuanto se van detras del cuello del caballo
     en marcha: 0 las deja clavadas, 1 las lleva pegadas al cuello. Los huesos
     son SKEL_Neck_1 y SKEL_Spine3 del ciervo. ]]
Config.Caballos.Brazos = { ancho = 0.14, delante = 0.42, alto = 0.20, sigue = 0.40, cuello = 39317, pecho = 24818 }

-- Las riendas: `holgura` es cuanto mas larga que la distancia mano-boca es
-- la rienda con el caballo quieto.
Config.Caballos.Riendas = { grosor = 0.014, holgura = 1.02, tramos = 8, color = { 20, 13, 8 } }
