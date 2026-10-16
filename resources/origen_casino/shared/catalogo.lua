--[[ ══════════════════════════════════════════════════════════════════════════
     EL CATÁLOGO: lo que se puede colocar

     Cada entrada de aquí es una fila de la lista «Añadir» del panel de admin.
     Colocar una crea un PUNTO —una mesa, una máquina, un empleado— con sus
     coordenadas propias en `origen_casino_puntos`.

     Esto no se edita desde el panel: es lo que el recurso sabe dibujar. Lo que
     sí se edita punto a punto son las coordenadas, el nombre, la apuesta
     mínima y máxima de esa mesa en concreto y cuántas plazas tiene.

     ── Los asientos ───────────────────────────────────────────────────────

     `asientos` son desplazamientos RELATIVOS al punto, en metros, mirando el
     punto hacia su rumbo:

         dx   a la derecha del punto (+) o a la izquierda (-)
         dy   por delante del punto (+) o por detrás (-)
         dz   arriba o abajo
         dh   cuántos grados gira el jugador respecto al rumbo del punto;
              0 es mirar hacia donde mira el punto

     Salen de los HUESOS de cada mueble: las mesas y las tragaperras del
     casino traen uno por silla (`Chair_Base_01`…`04`) con la posición y el
     giro exactos del taburete. Es lo que usa el propio GTA, y de ahí salen
     también `dh`: la silla del hueso mira 90° a su derecha de hacia donde
     mira el que se sienta.

     El modo de colocar del panel pinta un muñeco en cada asiento MIENTRAS
     mueves la mesa, así que se ven antes de guardar.
   ══════════════════════════════════════════════════════════════════════════ ]]

Catalogo = {}

--[[ Las sillas, leídas de los huesos en el juego (24/09) con el mueble en un
     rumbo cualquiera y pasadas a desplazamientos respecto al punto.

     Antes había aquí una elipse sacada de un mapa de alturas y de fotos
     cenitales, y fallaba en las esquinas por casi medio metro: el jugador se
     sentaba ENTRE dos taburetes. Los taburetes no tienen colisión, así que
     nada lo corregía. Con los huesos no hay nada que medir.

     Las tres mesas de cartas son el mismo mueble por fuera y dan los mismos
     cuatro huesos. La ruleta tiene CUATRO sillas, no tres: dos delante del
     tapete, una en la cabecera y una enfrente. ]]
local SILLAS_CARTAS = {
    { dx = -1.109, dy =  0.048, dz = 0.0, dh = -70.0 },
    { dx = -0.449, dy = -0.625, dz = 0.0, dh = -20.0 },
    { dx =  0.450, dy = -0.626, dz = 0.0, dh =  20.0 },
    { dx =  1.109, dy =  0.033, dz = 0.0, dh =  70.0 },
}

local SILLAS_RULETA = {
    { dx = -0.204, dy = -0.870, dz = 0.0, dh =   0.0 },
    { dx =  0.768, dy = -0.870, dz = 0.0, dh =   0.0 },
    { dx =  1.379, dy = -0.127, dz = 0.0, dh =  90.0 },
    { dx =  0.766, dy =  0.629, dz = 0.0, dh = 180.0 },
}

--[[ La cámara de la tragaperras mira a la VENTANA de los rodillos (1,1 m del
     suelo), por encima del hombro derecho: los rodillos giran en la propia
     máquina (client/maquinas.lua) y es lo que hay que ver. ]]
local CAMARA_TRAGAPERRAS = { atras = -0.05, alto = 1.56, mira = 1.22, lado = 0.0, campo = 60.0 }

-- Las cinco tragaperras dan el mismo hueso, al milímetro.
local SILLA_TRAGAPERRAS = { { dx = 0.0, dy = -0.752, dz = 0.0, dh = 0.0 } }

--[[ La mesa de blackjack en el mundo (client/mesas.lua): el crupier y dónde
     caen las cartas. Medido en el juego el 24/09: el tapete a 0,95 m, las
     cartas del jugador a 0,44 m de su silla —encima del recuadro pintado— y
     las del crupier delante de la bandeja de fichas. Las animaciones del
     crupier van al origen de la mesa y lo colocan solas. ]]
--[[ La cámara de las mesas: por encima de la cabeza del jugador y mirando al
     tapete, que es donde pasa todo —las cartas, las fichas, el crupier—. Con
     la de antes, baja y detrás del respaldo, no se veía la mesa. ]]
local CAMARA_MESA = { atras = 0.35, alto = 2.05, lado = 0.30, mira = 0.95, adelante = 0.75, campo = 52.0 }

local CARTAS_BLACKJACK = {
    modelos = { 'S_F_Y_Casino_01', 'S_M_Y_Casino_01' },
    dict = 'anim_casino_b@amb@casino@games@blackjack@dealer', quieto = 'idle',
    altura = 0.95, jugador = 0.44, paso = 0.035,
    crupier = { dx = -0.07, dy = 0.17 }, pasoCrupier = 0.075,
    zapato = { dx = 0.55, dy = 0.45 },
    retardo = 450, entreCartas = 200,       -- ms: hasta que sale la carta, y entre una y otra
    anims = {
        dar = 'deal_card_player_%s', pedir = 'hit_card_player_%s',
        propia = 'deal_card_self', propiaSegunda = 'deal_card_self_second_card',
        propiaMas = 'deal_card_self_card_10',
        girar = 'check_and_turn_card', recoger = 'retrieve_own_cards_and_remove',
    },
}

--[[ La mesa de póker de tres cartas. Su paño trae los TRES huecos de las
     cartas del crupier pintados, en abanico, y en cada plaza los recuadros de
     PAIR PLUS, ANTE y PLAY, donde van las fichas: las cartas del jugador van
     delante de ellos, en fila. Medido en el juego el 24/09.

     El crupier del póker no tiene animación de reposo propia: la saca de la
     común de los crupieres. ]]
local CARTAS_POKER = {
    modelos = { 'S_M_Y_Casino_01', 'S_F_Y_Casino_01' },
    dict = 'anim_casino_b@amb@casino@games@threecardpoker@dealer',
    quieto = { 'anim_casino_b@amb@casino@games@shared@dealer@', 'idle' },
    altura = 0.95, jugador = 0.46, paso = 0.07, fila = 3,
    crupier = { huecos = {
        { dx = -0.14, dy = 0.13, giro = 12.0 },
        { dx = 0.0, dy = 0.14, giro = 0.0 },
        { dx = 0.14, dy = 0.13, giro = -12.0 },
    } },
    zapato = { dx = 0.0, dy = 0.40 },
    retardo = 450, entreCartas = 200,
    anims = {
        dar = 'deck_deal_p%s', pedir = 'deck_deal_p%s',
        propia = 'deck_deal_self', propiaSegunda = 'deck_deal_self', propiaMas = 'deck_deal_self',
        girar = 'reveal_self', recoger = nil,
    },
}

--[[ El Hold em no existe en el casino de GTA: se juega en la misma mesa que
     el póker de tres cartas. Las cinco comunes, en fila en el centro, justo
     debajo de los huecos del crupier; las dos de cada jugador, donde el póker
     pone sus tres. ]]
local CARTAS_HOLDEM = {
    modelos = { 'S_F_Y_Casino_01', 'S_M_Y_Casino_01' },
    dict = 'anim_casino_b@amb@casino@games@threecardpoker@dealer',
    quieto = { 'anim_casino_b@amb@casino@games@shared@dealer@', 'idle' },
    altura = 0.95, jugador = 0.46, paso = 0.07, fila = 2,
    crupier = { huecos = {
        { dx = -0.16, dy = 0.10 }, { dx = -0.08, dy = 0.10 }, { dx = 0.0, dy = 0.10 },
        { dx = 0.08, dy = 0.10 }, { dx = 0.16, dy = 0.10 },
    } },
    zapato = { dx = 0.0, dy = 0.40 },
    retardo = 450, entreCartas = 200,
    anims = {
        dar = 'deck_deal_p%s', pedir = 'deck_deal_p%s',
        propia = 'deck_deal_self', propiaSegunda = 'deck_deal_self', propiaMas = 'deck_deal_self',
        girar = nil, recoger = nil,
    },
}

--[[ La ruleta en el mundo (client/ruleta.lua): el crupier y sus animaciones.
     `lanzar` dura lo mismo que el arranque del bombo y de la bola. ]]
local RULETA_MUNDO = {
    modelos = { 'S_F_Y_Casino_01', 'S_M_Y_Casino_01' },
    dict = 'anim_casino_b@amb@casino@games@roulette@dealer',
    dictMujer = 'anim_casino_b@amb@casino@games@roulette@dealer_female',
    quieto = 'idle', lanzar = 'spin_wheel',
}

--[[ Cómo se sienta: con las animaciones del casino de GTA, colocadas en la
     silla con una escena sincronizada (client/asiento.lua). `entrada` lleva al
     personaje de pie junto al taburete hasta sentado; `quieto` es el bucle
     mientras juega; `salida`, levantarse. ]]
local SENTAR_MESA = {
    dict = 'anim_casino_b@amb@casino@games@shared@player@',
    entrada = 'sit_enter_left', quieto = 'idle_cardgames', salida = 'sit_exit_left',
}
local SENTAR_TRAGAPERRAS = {
    dict = 'anim_casino_a@amb@casino@games@slots@male',
    dictMujer = 'anim_casino_a@amb@casino@games@slots@female',
    entrada = 'enter_left', quieto = 'base_idle_a', salida = 'exit_left',
    origen = 'mueble',   -- la animación se coloca en la máquina, no en la silla
    -- Lo que hace mientras juega (client/asiento.lua, Gesto). Si hay varias,
    -- una al azar: pulsar el botón o tirar de la palanca.
    gestos = {
        boton = { 'press_spin_a', 'press_spin_b' },
        palanca = { 'pull_spin_a', 'pull_spin_b' },     -- la máquina hace `<esta>_slotmachine`
        apuestaUno = { 'press_betone_a' },
        apuestaMax = { 'press_betmax_a' },
        gana = { 'win_a', 'win_b' },
        pierde = { 'lose_a', 'lose_b' },
    },
}

--[[ Las máquinas de vídeo. `pantalla` es el cristal donde se pinta el juego,
     en metros desde el origen del mueble (x a la derecha de quien juega, y
     hacia el jugador en negativo, z hacia arriba); `taburete`, dónde va el
     suyo (el mismo hueso que las tragaperras de GTA).

     La cámara se acerca más que en la de rodillos: la pantalla tiene que
     llenar la vista para que se lea el juego. ]]
--[[ El cristal de las tragaperras de GTA (vw_prop_casino_slot_0Xa, todas
     iguales), medido en el juego el 07/10 AL MILÍMETRO con marcas cada 2 mm
     y fotos perpendiculares de cerca (las que tapa el marco dicen dónde
     empieza): el hueco va de x −0,2761 a +0,2771 y de z 1,0208 (ahí empieza
     la barra plateada, a ras del cristal) a 1,2599. El cristal está
     INCLINADO hacia atrás: y = −0,1325 + 0,196 × (z − 1,265).

     Lo que hace falta saber para que quede pegada:
       · El dibujo de la máquina no es del todo plano: a 0,6 mm asomaba por
         encima de la pantalla en algunos sitios. Va a 2 mm.
       · Por arriba y por los lados el marco tiene un labio y el dibujo
         sigue debajo: de lado se veía la selva por el hueco. Ensanchar la
         pantalla bajo el labio se veía de frente. Lo que lo arregla es un
         marco negro de 2 cm hacia dentro por los cuatro lados (`fondo`,
         client/video.lua): de frente no se ve y de lado es el canto de la
         pantalla.
     Es el hueco exacto, 0,553 × 0,244: la página es de 1280×564. ]]
local PANTALLA_VIDEO = { x0 = -0.2761, x1 = 0.2771, z0 = 1.0208, z1 = 1.2599, y0 = -0.1824, y1 = -0.1355, fondo = 0.02 }
local TABURETE_VIDEO = { modelo = 'vw_prop_casino_stool_02a', dx = 0.0, dy = -0.752, dh = 90.0 }
local CAMARA_VIDEO = { atras = -0.12, alto = 1.32, mira = 1.14, lado = 0.0, campo = 46.0 }

local function MaquinaVideo(id, nombre, juego, modelo)
    return {
        id = id, nombre = 'Máquina de vídeo · ' .. nombre, familia = 'Máquinas de vídeo',
        juego = juego, modelo = modelo,
        icono = 'cherry', radio = 1.6, plazas = 1, mesa = false,
        asientos = SILLA_TRAGAPERRAS, sentar = SENTAR_TRAGAPERRAS,
        camara = CAMARA_VIDEO,
        video = { pantalla = PANTALLA_VIDEO, taburete = TABURETE_VIDEO },
    }
end

--[[ El catálogo. El orden es el que sale en el panel.

     familia   para agrupar en la lista del panel
     juego     qué se juega ahí (una clave de Config.Juegos), o el papel que
               hace el punto: 'caja', 'membresia'
     modelo    el prop o el ped que se crea
     ped       true si el modelo es una persona (se le pone un escenario)
     radio     a cuánto sale el aviso de la tecla
     plazas    cuántos pueden jugar a la vez; 0 = sin límite (la caja)
     asientos  ver arriba; vacío = se juega de pie
     mesa      true si es una mesa compartida (una ronda para todos los
               sentados) en vez de una máquina de un solo jugador ]]
Catalogo.Tipos = {
    -- ── Tragaperras ──────────────────────────────────────────────────────
    {
        id = 'slot_diamante', nombre = 'Tragaperras · Diamante', familia = 'Tragaperras',
        juego = 'tragaperras', modelo = 'vw_prop_casino_slot_01a',
        icono = 'cherry', radio = 1.6, plazas = 1, mesa = false,
        asientos = SILLA_TRAGAPERRAS, sentar = SENTAR_TRAGAPERRAS,
        camara = CAMARA_TRAGAPERRAS,
    },
    {
        id = 'slot_fortuna', nombre = 'Tragaperras · Fortuna', familia = 'Tragaperras',
        juego = 'tragaperras', modelo = 'vw_prop_casino_slot_02a',
        icono = 'cherry', radio = 1.6, plazas = 1, mesa = false,
        asientos = SILLA_TRAGAPERRAS, sentar = SENTAR_TRAGAPERRAS,
        camara = CAMARA_TRAGAPERRAS,
    },
    {
        id = 'slot_impulso', nombre = 'Tragaperras · Impulso', familia = 'Tragaperras',
        juego = 'tragaperras', modelo = 'vw_prop_casino_slot_03a',
        icono = 'cherry', radio = 1.6, plazas = 1, mesa = false,
        asientos = SILLA_TRAGAPERRAS, sentar = SENTAR_TRAGAPERRAS,
        camara = CAMARA_TRAGAPERRAS,
    },
    {
        id = 'slot_tesoro', nombre = 'Tragaperras · Tesoro', familia = 'Tragaperras',
        juego = 'tragaperras', modelo = 'vw_prop_casino_slot_04a',
        icono = 'cherry', radio = 1.6, plazas = 1, mesa = false,
        asientos = SILLA_TRAGAPERRAS, sentar = SENTAR_TRAGAPERRAS,
        camara = CAMARA_TRAGAPERRAS,
    },
    {
        id = 'slot_galaxia', nombre = 'Tragaperras · Galaxia', familia = 'Tragaperras',
        juego = 'tragaperras', modelo = 'vw_prop_casino_slot_05a',
        icono = 'cherry', radio = 1.6, plazas = 1, mesa = false,
        asientos = SILLA_TRAGAPERRAS, sentar = SENTAR_TRAGAPERRAS,
        camara = CAMARA_TRAGAPERRAS,
    },
    {
        id = 'slot_fuego', nombre = 'Tragaperras · Fuego', familia = 'Tragaperras',
        juego = 'tragaperras', modelo = 'vw_prop_casino_slot_08a',
        icono = 'cherry', radio = 1.6, plazas = 1, mesa = false,
        asientos = SILLA_TRAGAPERRAS, sentar = SENTAR_TRAGAPERRAS,
        camara = CAMARA_TRAGAPERRAS,
    },
    {
        id = 'slot_leon', nombre = 'Tragaperras · León', familia = 'Tragaperras',
        juego = 'tragaperras', modelo = 'vw_prop_casino_slot_06a',
        icono = 'cherry', radio = 1.6, plazas = 1, mesa = false,
        asientos = SILLA_TRAGAPERRAS, sentar = SENTAR_TRAGAPERRAS,
        camara = CAMARA_TRAGAPERRAS,
    },
    {
        id = 'slot_estrella', nombre = 'Tragaperras · Estrella', familia = 'Tragaperras',
        juego = 'tragaperras', modelo = 'vw_prop_casino_slot_07a',
        icono = 'cherry', radio = 1.6, plazas = 1, mesa = false,
        asientos = SILLA_TRAGAPERRAS, sentar = SENTAR_TRAGAPERRAS,
        camara = CAMARA_TRAGAPERRAS,
    },

    -- ── Máquinas de vídeo ────────────────────────────────────────────────
    --[[ El juego se pinta en la pantalla del mueble (client/video.lua) y
         cada una pone su taburete. Mientras no esté el mueble propio, van
         sobre la tragaperras de GTA con la pantalla encima de la ventana de
         los rodillos. ]]
    MaquinaVideo('video_golpe', 'El Golpe', 'golpe', 'vw_prop_casino_slot_08a'),
    MaquinaVideo('video_clasica', 'Vinewood', 'clasica', 'vw_prop_casino_slot_07a'),
    MaquinaVideo('video_atrapa', 'Atrapa y gana', 'atrapa', 'vw_prop_casino_slot_04a'),
    MaquinaVideo('video_cascadas', 'Fiebre', 'cascadas', 'vw_prop_casino_slot_05a'),

    -- ── Mesas ────────────────────────────────────────────────────────────
    {
        id = 'ruleta', nombre = 'Mesa de ruleta', familia = 'Mesas',
        juego = 'ruleta', modelo = 'vw_prop_casino_roulette_01b',
        camara = CAMARA_MESA,
        icono = 'circle-dot', radio = 2.4, plazas = 4, mesa = true,
        asientos = SILLAS_RULETA, sentar = SENTAR_MESA,
        ruletaMundo = RULETA_MUNDO,
    },
    {
        id = 'blackjack', nombre = 'Mesa de blackjack', familia = 'Mesas',
        juego = 'blackjack', modelo = 'vw_prop_casino_blckjack_01b',
        mesaCartas = CARTAS_BLACKJACK,
        camara = CAMARA_MESA,
        icono = 'spade', radio = 2.2, plazas = 4, mesa = true,
        asientos = SILLAS_CARTAS, sentar = SENTAR_MESA,
    },
    {
        id = 'pokertres', nombre = 'Mesa de póker de tres cartas', familia = 'Mesas',
        juego = 'pokertres', modelo = 'vw_prop_casino_3cardpoker_01b',
        mesaCartas = CARTAS_POKER,
        camara = CAMARA_MESA,
        icono = 'diamond', radio = 2.2, plazas = 4, mesa = false,
        asientos = SILLAS_CARTAS, sentar = SENTAR_MESA,
    },
    {
        id = 'holdem', nombre = 'Mesa de Texas Hold em', familia = 'Mesas',
        juego = 'holdem', modelo = 'vw_prop_casino_3cardpoker_01',
        mesaCartas = CARTAS_HOLDEM,
        camara = CAMARA_MESA,
        icono = 'club', radio = 2.6, plazas = 4, mesa = true,
        asientos = SILLAS_CARTAS, sentar = SENTAR_MESA,
    },

    -- ── Caballos ─────────────────────────────────────────────────────────
    {
        id = 'caballos_puesto', nombre = 'Ventanilla de apuestas (caballos)', familia = 'Caballos',
        juego = 'caballos', modelo = false,
        icono = 'trending-up', radio = 1.8, plazas = 0, mesa = true,
        asientos = {},
        marcador = { r = 216, g = 27, b = 85 },
    },
    {
        id = 'caballos_silla', nombre = 'Butaca frente a las pantallas', familia = 'Caballos',
        juego = 'caballos', modelo = false,
        icono = 'trending-up', radio = 1.2, plazas = 1, mesa = true,
        asientos = { { dx = 0.0, dy = 0.0, dz = 0.0, dh = 0.0 } },
        sinProp = true,
    },

    -- ── Rueda de la suerte ───────────────────────────────────────────────
    {
        id = 'rueda', nombre = 'Rueda de la suerte', familia = 'Rueda',
        juego = 'rueda', modelo = 'vw_prop_vw_luckywheel_01a',
        icono = 'gift', radio = 2.0, plazas = 1, mesa = false,
        asientos = {},
    },

    -- ── Mostradores ──────────────────────────────────────────────────────
    {
        id = 'caja', nombre = 'Caja de fichas (empleado)', familia = 'Mostradores',
        --[[ El cajero del casino de verdad, el mismo que usa rcore en este
             servidor. `ig_casey` no valía: es un ped de escena y no llegaba a
             crearse nunca, así que la caja se quedaba sin nadie detrás. ]]
        juego = 'caja', modelo = 'u_f_m_casinocash_01', ped = true,
        icono = 'coins', radio = 2.2, plazas = 0, mesa = false,
        asientos = {},
        escenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    },
    {
        id = 'membresia', nombre = 'Mostrador de socios (empleado)', familia = 'Mostradores',
        juego = 'membresia', modelo = 's_f_y_casino_01', ped = true,
        icono = 'id-card', radio = 2.2, plazas = 0, mesa = false,
        asientos = {},
        escenario = 'WORLD_HUMAN_CLIPBOARD',
    },
    {
        id = 'caja_marcador', nombre = 'Caja de fichas (sin empleado)', familia = 'Mostradores',
        juego = 'caja', modelo = false,
        icono = 'coins', radio = 2.2, plazas = 0, mesa = false,
        asientos = {},
        marcador = { r = 216, g = 27, b = 85 },
    },
}

--- El tipo por su id, o nil.
function Catalogo.Tipo(id)
    for _, t in ipairs(Catalogo.Tipos) do
        if t.id == id then return t end
    end
    return nil
end

--- Todas las familias, en el orden en que aparecen.
function Catalogo.Familias()
    local vistas, lista = {}, {}
    for _, t in ipairs(Catalogo.Tipos) do
        if not vistas[t.familia] then
            vistas[t.familia] = true
            lista[#lista + 1] = t.familia
        end
    end
    return lista
end

--[[ El catálogo tal y como lo pinta el panel: sin funciones y con los asientos
     ya resueltos, para poder mandarlo entero por JSON. ]]
function Catalogo.ParaPanel()
    local lista = {}
    for i, t in ipairs(Catalogo.Tipos) do
        lista[i] = {
            id = t.id, nombre = t.nombre, familia = t.familia, juego = t.juego,
            icono = t.icono, plazas = t.plazas, mesa = t.mesa == true,
            modelo = t.modelo or false, ped = t.ped == true,
            asientos = #t.asientos,
        }
    end
    return lista
end
