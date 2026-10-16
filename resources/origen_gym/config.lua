--[[ Origen Gym.

     Aqui no hay gimnasios escritos: se crean desde dentro del juego con el
     configurador (/gymconfig) y viven en la base de datos. Lo que si esta aqui
     es el catalogo de aparatos y las reglas.

     Todo es del propio GTA: los props y los ejercicios (escenarios del juego).
     Por eso lo ve todo el mundo sin sincronizar nada a mano: el ejercicio es
     una tarea del personaje, y el juego ya la reparte. ]]

Config = {}

--- Quien puede abrir el configurador: el permiso «Gestionar Gimnasios» de
--- origen_admin, que es tambien el que ensena su tarjeta en la pestana Scripts.
Config.Permiso = 'origen_gym'
Config.Comando = 'gymconfig'

--- Desde cuanto se ponen los aparatos de un gimnasio, y cuanto puede alejarse
--- un aparato del centro del suyo.
Config.Distancia = 90.0
Config.Radio = 60.0

--- A cuanto del aparato hay que estar para usarlo.
Config.Alcance = 1.7

Config.Topes = { gimnasios = 40, aparatos = 80 }

--[[ Los gimnasios que son un NEGOCIO (origen_businesses, tipo «gym»).

     Sus maquinas las coloca el jefe desde el panel del negocio, en Ajustes, y
     son aparatos como los demas: mismo catalogo, mismas posturas, mismo
     entrenamiento. Lo que cambia es quien entra:

       · los empleados del negocio, siempre;
       · los demas, con la membresia: un objeto (`item`) que se compra en la
         propia maquina, lleva apuntado de que gimnasio es y cuando caduca, y
         cuyo precio va a la caja del negocio. Con el precio a 0 es libre.

     `tope`  cuantas maquinas puede poner un negocio si el no dice otra cosa
             (lo normal es que lo diga: la administracion lo pone en «Cuantos
             puntos caben» de origen_businesses; nunca pasa de Topes.aparatos)
     `radio` cuanto pueden alejarse de la primera que puso (el centro) ]]
Config.Negocio = {
    item = 'membresia_gimnasio',
    tope = 25,
    radio = 40.0,
    precioMax = 50000,
    diasMax = 30,
    precio = 500,      -- con lo que nace un gimnasio de negocio
    dias = 7,
}

--[[ Entrenar sube las habilidades de siempre (el gym_data del personaje: fuerza
     y resistencia, de 0 a 100). Se cuenta por tandas: cada `Tanda` segundos
     seguidos en el aparato, el servidor suma lo que da ese aparato.

     El cansancio es el tope: `tandas` como mucho dentro de `ventana` segundos.
     Con 18 tandas de 0,25 cada media hora, lo mas que se sube son 9 puntos por
     hora. ]]
Config.Tanda = 20
Config.Cansancio = { tandas = 18, ventana = 30 * 60 }

--[[ Cada serie es un minijuego (juego.lua), y lo bien que salga decide cuanto
     sube: lo que da el aparato se multiplica por un valor entre `minimo` (la
     serie hecha sin acertar nada) y `maximo` (la serie perfecta). Entre serie y
     serie hay `Config.Descanso` segundos. ]]
Config.Descanso = 4
Config.Minijuego = { minimo = 0.4, maximo = 1.5 }

Config.Habilidades = { strength = 'Fuerza', condition = 'Resistencia' }

--[[ El catalogo.

     modelo     el prop del juego
     escenario  el ejercicio, si el juego lo trae como escenario. Los de aparato
                (PROP_HUMAN_*) se quedan donde se les dice; los de suelo
                (WORLD_HUMAN_*) se posan solos en el suelo.
     anim       en su lugar, una animacion en bucle con el personaje clavado en
                el sitio: para lo que tiene que quedar a una altura exacta, como
                la cinta. { m = { dict, clip }, f = { dict, clip } } (hombre / mujer).
     ped        donde va el personaje respecto del ORIGEN del prop (que no
                siempre esta en su base): metros a la derecha (x), hacia delante
                (y), arriba (z) y grados de giro (h). Medidas en el juego el
                03/10/2026, una a una y con fotos. Se pueden retocar desde el
                configurador («Ajustar postura»): lo que se guarde alli manda
                sobre esto.
     gana       lo que suma cada serie, antes de aplicarle la nota del minijuego
     juego      el minijuego de ese ejercicio y lo dificil que es (ver juego.lua)

     Cualquier aparato se puede poner tambien SIN prop --«solo el punto»--, para
     los gimnasios cuyo mapeado ya trae las maquinas: se marca donde va el
     personaje y listo. ]]
Config.Tipos = {
    {
        id = 'press', nombre = 'Banco de press', grupo = 'Fuerza',
        modelo = 'prop_muscle_bench_03', escenario = 'PROP_HUMAN_SEAT_MUSCLE_BENCH_PRESS',
        ped = { x = 0.0, y = -0.45, z = -0.26, h = 180.0 },
        gana = { strength = 0.25 },
        juego = { mecanica = 'tempo', periodo = 2.2, ancho = 0.2, objetivo = 7 },
    },
    {
        id = 'dominadas', nombre = 'Torre de dominadas', grupo = 'Fuerza',
        -- La barra de dominadas esta ATRAS de la torre (+y), al lado contrario
        -- del respaldo y de las paralelas, a y = 0,69 y z = 1,00 del origen.
        -- En este escenario las munecas quedan 0,18 por detras y 0,97 por
        -- encima del origen del personaje (medido con los huesos de las manos).
        modelo = 'prop_muscle_bench_05', escenario = 'PROP_HUMAN_MUSCLE_CHIN_UPS',
        ped = { x = 0.0, y = 0.52, z = -0.03, h = 180.0 },
        gana = { strength = 0.25 },
        juego = { mecanica = 'aguante', cae = 0.3, sube = 0.085, desde = 0.55, hasta = 0.8 },
    },
    {
        id = 'pesas', nombre = 'Pesas libres', grupo = 'Fuerza',
        modelo = 'prop_weight_rack_02', escenario = 'WORLD_HUMAN_MUSCLE_FREE_WEIGHTS',
        ped = { x = 0.0, y = -1.0, z = -0.5, h = 180.0 },
        gana = { strength = 0.22 },
        juego = { mecanica = 'alterno', desde = 2.0, hasta = 3.4, tope = 5.0 },
    },
    {
        id = 'flexiones', nombre = 'Flexiones', grupo = 'Fuerza',
        modelo = 'prop_yoga_mat_01', escenario = 'WORLD_HUMAN_PUSH_UPS',
        ped = { x = -0.3, y = 0.0, z = 0.0, h = 90.0 },
        gana = { strength = 0.2 },
        juego = { mecanica = 'secuencia', largo = 4, objetivo = 6 },
    },
    {
        id = 'abdominales', nombre = 'Abdominales', grupo = 'Resistencia',
        modelo = 'prop_yoga_mat_02', escenario = 'WORLD_HUMAN_SIT_UPS',
        ped = { x = 0.25, y = 0.0, z = 0.0, h = 90.0 },
        gana = { condition = 0.22 },
        juego = { mecanica = 'tempo', periodo = 1.6, ancho = 0.18, objetivo = 9 },
    },
    {
        id = 'yoga', nombre = 'Yoga', grupo = 'Resistencia',
        modelo = 'prop_yoga_mat_03', escenario = 'WORLD_HUMAN_YOGA',
        ped = { x = 0.0, y = 0.0, z = 0.0, h = 90.0 },
        gana = { condition = 0.2 },
        juego = { mecanica = 'respiracion', periodo = 6.0, margen = 0.12, velocidad = 0.42 },
    },
    {
        -- Con escenario el personaje se posa en el suelo y atraviesa la banda:
        -- va con animacion, clavado a la altura de la banda.
        id = 'cinta', nombre = 'Cinta de correr', grupo = 'Resistencia',
        modelo = 'apa_p_apdlc_treadmill_s',
        anim = {
            m = { 'amb@world_human_jog_standing@male@base', 'base' },
            f = { 'amb@world_human_jog_standing@female@base', 'base' },
        },
        ped = { x = 0.0, y = 0.0, z = 1.14, h = 180.0 },
        gana = { condition = 0.28 },
        juego = { mecanica = 'alterno', desde = 2.6, hasta = 4.0, tope = 5.5 },
    },
}

Config.Tipo = {}
for _, t in ipairs(Config.Tipos) do Config.Tipo[t.id] = t end
