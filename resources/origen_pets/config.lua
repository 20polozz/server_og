Config = {}

--[[ ── Las razas ────────────────────────────────────────────────────────────

     Solo perros. GTA trae mas bichos —gatos monteses, coyotes, pumas—, pero un
     puma paseando por Vinewood no es una mascota, es un aviso al 911.

     `pelea` dice si la raza sabe defenderte. Un chihuahua no muerde a nadie: se
     le puede pedir que se siente y que te siga, pero el modo guardia no le sale
     y el panel lo dice en vez de dejar que lo intente y se lo lleven por
     delante.

     `salud` es con cuanta vida aparece. GTA da 200 a un ped normal; un rottweiler
     aguanta lo que un tio, un chihuahua no.

     `alijo` es lo que puede llevarte encima: ranuras y kilos. Va por tamaño y
     no por raza: un rottweiler carga una mochila de verdad y un carlino lleva
     lo que le quepa en un arnes. Es la razon practica para tener un perro
     grande aunque no pelees con el. ]]
Config.Razas = {
    rottweiler  = { modelo = 'a_c_rottweiler',  nombre = 'Rottweiler',       pelea = true,  salud = 200, alijo = { slots = 12, peso = 25000 } },
    shepherd    = { modelo = 'a_c_shepherd',    nombre = 'Pastor alemán',    pelea = true,  salud = 190, alijo = { slots = 12, peso = 24000 } },
    husky       = { modelo = 'a_c_husky',       nombre = 'Husky',            pelea = true,  salud = 170, alijo = { slots = 10, peso = 22000 } },
    retriever   = { modelo = 'a_c_retriever',   nombre = 'Labrador',         pelea = false, salud = 150, alijo = { slots = 10, peso = 20000 } },
    poodle      = { modelo = 'a_c_poodle',      nombre = 'Caniche',          pelea = false, salud = 110, alijo = { slots = 5,  peso = 8000 } },
    pug         = { modelo = 'a_c_pug',         nombre = 'Carlino',          pelea = false, salud = 100, alijo = { slots = 4,  peso = 6000 } },
    westy       = { modelo = 'a_c_westy',       nombre = 'West Highland',    pelea = false, salud = 110, alijo = { slots = 5,  peso = 8000 } },
    chop        = { modelo = 'a_c_chop',        nombre = 'Chop',             pelea = true,  salud = 200, alijo = { slots = 12, peso = 25000 } },

    -- Los caballos. Se montan con la E (config_caballos.lua); llevan alforjas.
    caballo_policia = { modelo = 'a_c_horse_police', nombre = 'Caballo de policía', pelea = false, salud = 300, alijo = { slots = 20, peso = 60000 } },
    caballo_sheriff = { modelo = 'ft_ahorse',        nombre = 'Cuarto de milla',    pelea = false, salud = 300, alijo = { slots = 20, peso = 60000 } },
    --[[ Las que traia murderface-pets (Nacion) y aqui no estaban. Van en el
         config y no en el catalogo de la base: asi las mascotas que ya tenia
         la gente tienen donde caer. Para VENDERLAS, darlas de alta desde el
         panel de admin con la misma clave. ]]
    cat             = { modelo = 'a_c_cat_01', nombre = 'Gato', pelea = false, salud = 112, alijo = { slots = 4, peso = 6000 } },
    panther         = { modelo = 'a_c_panther', nombre = 'Pantera negra', pelea = true, salud = 200, alijo = { slots = 12, peso = 25000 } },
    mtlion          = { modelo = 'a_c_mtlion', nombre = 'Puma', pelea = true, salud = 200, alijo = { slots = 12, peso = 25000 } },
    coyote          = { modelo = 'a_c_coyote', nombre = 'Coyote', pelea = true, salud = 200, alijo = { slots = 8, peso = 15000 } },
    boar            = { modelo = 'a_c_boar', nombre = 'Jabalí', pelea = true, salud = 187, alijo = { slots = 8, peso = 15000 } },
    deer            = { modelo = 'a_c_deer', nombre = 'Ciervo', pelea = false, salud = 175, alijo = { slots = 12, peso = 25000 } },
    pig             = { modelo = 'a_c_pig', nombre = 'Cerdo', pelea = false, salud = 150, alijo = { slots = 8, peso = 15000 } },
    cow             = { modelo = 'a_c_cow', nombre = 'Vaca', pelea = false, salud = 200, alijo = { slots = 12, peso = 25000 } },
    chimp           = { modelo = 'a_c_chimp_02', nombre = 'Chimpancé', pelea = false, salud = 150, alijo = { slots = 8, peso = 15000 } },
    rhesus          = { modelo = 'a_c_rhesus', nombre = 'Mono rhesus', pelea = false, salud = 112, alijo = { slots = 4, peso = 6000 } },
    rabbit          = { modelo = 'a_c_rabbit_01', nombre = 'Conejo', pelea = false, salud = 125, alijo = { slots = 4, peso = 6000 } },
    rat             = { modelo = 'a_c_rat', nombre = 'Rata', pelea = false, salud = 105, alijo = { slots = 2, peso = 2000 } },
    hen             = { modelo = 'a_c_hen', nombre = 'Gallina', pelea = false, salud = 125, alijo = { slots = 2, peso = 2000 } },
    seagull         = { modelo = 'a_c_seagull', nombre = 'Gaviota', pelea = false, salud = 112, alijo = { slots = 2, peso = 2000 } },
    pigeon          = { modelo = 'a_c_pigeon', nombre = 'Paloma', pelea = false, salud = 112, alijo = { slots = 2, peso = 2000 } },
    crow            = { modelo = 'a_c_crow', nombre = 'Cuervo', pelea = false, salud = 112, alijo = { slots = 2, peso = 2000 } },
    cormorant       = { modelo = 'a_c_cormorant', nombre = 'Cormorán', pelea = false, salud = 112, alijo = { slots = 2, peso = 2000 } },
    chickenhawk     = { modelo = 'a_c_chickenhawk', nombre = 'Gavilán', pelea = false, salud = 125, alijo = { slots = 2, peso = 2000 } },
    doberman        = { modelo = 'dusa_doberman', nombre = 'Dóberman', pelea = true, salud = 187, alijo = { slots = 12, peso = 25000 } },
    canecorso       = { modelo = 'dusa_cane', nombre = 'Cane Corso', pelea = true, salud = 200, alijo = { slots = 12, peso = 25000 } },
    englishbulldog  = { modelo = 'dusa_englishbulldog', nombre = 'Bulldog inglés', pelea = false, salud = 150, alijo = { slots = 8, peso = 15000 } },
    sphynx          = { modelo = 'dusa_sphynx', nombre = 'Gato sphynx', pelea = false, salud = 112, alijo = { slots = 4, peso = 6000 } },
    poodle2         = { modelo = 'a_c_poodle_2', nombre = 'Caniche toy', pelea = false, salud = 112, alijo = { slots = 4, peso = 6000 } },
    husky2          = { modelo = 'a_c_husky_2', nombre = 'Husky siberiano', pelea = true, salud = 200, alijo = { slots = 12, peso = 25000 } },
    retriever2      = { modelo = 'a_c_retriever_2', nombre = 'Labrador retriever', pelea = false, salud = 175, alijo = { slots = 12, peso = 25000 } },
    shepherd2       = { modelo = 'a_c_shepherd_2', nombre = 'Pastor belga malinois', pelea = true, salud = 162, alijo = { slots = 12, peso = 25000 } },
    westy2          = { modelo = 'a_c_westy_2', nombre = 'West Highland terrier', pelea = false, salud = 112, alijo = { slots = 4, peso = 6000 } },

    poni            = { modelo = 'ft_horse',         nombre = 'Poni pinto',         pelea = false, salud = 250, alijo = { slots = 14, peso = 40000 } },
}

--- La raza que se usa cuando la guardada ya no existe en esta tabla, para que
--- una mascota no desaparezca por haber tocado la configuracion.
Config.RazaPorDefecto = 'retriever'

--[[ ── Distancias ───────────────────────────────────────────────────────── */

     `seguir` es a cuanto se pone detras de ti. Menos de dos metros y se te mete
     entre las piernas cada vez que te paras.

     `lejos` es a partir de cuanto se teletransporta a tu lado. Un perro que se
     queda atascado en una valla y no vuelve nunca es peor que uno que aparece
     de golpe. ]]
Config.Distancias = {
    seguir = 2.5,
    lejos = 45.0,
    sacar = 2.0,   -- a que distancia de ti aparece al sacarla
    laser = 60.0,  -- hasta donde llega el puntero para elegir a quien atacar
}

--[[ ── Comida y bebida ──────────────────────────────────────────────────────

     Solo bajan mientras la mascota esta en la calle: un perro guardado en casa
     no se muere de hambre porque su dueño lleve tres dias sin conectarse.

     `cada` son los segundos que tarda en bajar un punto. Con 90 segundos, de
     lleno a vacio son dos horas y media de juego seguidas con el perro fuera:
     lo suficiente para que haya que acordarse de el, y no tanto como para estar
     dandole de comer cada rato.

     Cuando uno de los dos llega a cero, empieza a perder vida. No se muere de
     hambre —eso seria perderla por desconectarte a mala hora— pero se queda
     debil y hay que atenderla. ]]
Config.Necesidades = {
    cada = 90,        -- segundos por punto
    castigo = 240,    -- cada cuanto pierde vida con hambre o sed
    danoPorFalta = 2, -- cuanta vida pierde cada vez

    -- Los items con los que se le da de comer y de beber. Si el item no existe
    -- en el inventario, la accion lo dice en vez de fallar en silencio.
    comida = { item = 'petfood', da = 45, nombre = 'Pienso' },
    bebida = { item = 'water_bottle', da = 60, nombre = 'Agua' },
}

--[[ ── El veterinario ──────────────────────────────────────────────────────

     Lo que cuesta curarla del todo. Se cobra entero aunque le falte poca vida:
     es una visita, no una gasolinera. ]]
Config.Veterinario = {
    precio = 750,
    cuenta = 'bank',
}

--[[ Con cuanta vida sale del suelo despues de que la maten. No sale al 100 %
     porque entonces morirse no cuesta nada, ni al 5 % porque entonces no la
     sacas hasta pagar y la mascota deja de existir mientras tanto. ]]
Config.SaludTrasMorir = 30

--- Cuantas mascotas puede tener un personaje a la vez.
Config.MaximoPorPersona = 3

--[[ ── Los grupos de admin que pueden regalar mascotas ─────────────────────
     Es el enganche de mientras: cuando haya tienda, la tienda llamara al mismo
     evento del servidor y esto se queda solo para pruebas. ]]
Config.GruposAdmin = { 'god', 'admin' }
