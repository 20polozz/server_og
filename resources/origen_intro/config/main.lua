Config = {}

--[[ ══ Rutas ════════════════════════════════════════════════════════════════

     Cada ruta es un par: donde aparece el coche y a donde conduce solo.
     Se elige una al azar en cada intro. El heading (la w) del spawn es hacia
     donde mira el coche al aparecer, y el del destino no se usa para conducir
     -- el coche llega mirando hacia donde venga -- pero si se usa si hay que
     forzar la llegada.

     Los puntos pueden estar donde sea, incluso en plena calle concurrida: nada
     de esto ocurre en el mundo compartido. El jugador entra en su bucket
     privado antes de teletransportarse, y el coche aparece ya dentro. ]]
Config.Rutas = {
    {
        etiqueta = 'Mirror Park -> Vinewood Este',
        spawn    = vector4(1631.57, 1163.62, 83.61, 161.69),
        destino  = vector4(1499.38, 841.99, 76.64, 149.47),
    },
    {
        etiqueta = 'Puente Paleto -> Vinewood Este',
        spawn    = vector4(-2639.87, 2809.94, 16.28, 170.11),
        destino  = vector4(-2671.81, 2590.97, 16.27, 172.97),
    },
    {
        etiqueta = 'Puente Paleto -> Vinewood Este',
        spawn    = vector4(-2969.72, 2099.07, 40.77, 146.14),
        destino  = vector4(-3014.42, 1945.23, 28.60, 157.78),
    },
    {
        etiqueta = 'Puente Paleto -> Vinewood Este',
        spawn    = vector4(-583.23, -536.71, 24.81, 269.35),
        destino  = vector4(-392.97, -536.42, 24.83, 268.62),
    },
    {
        etiqueta = 'Puente Paleto -> Vinewood Este',
        spawn    = vector4(1223.28, -1154.12, 51.18, 110.13),
        destino  = vector4(976.52, -1176.49, 52.14, 92.22),
    },
}

--[[ ══ Reparto de rutas ═════════════════════════════════════════════════════

     Las rutas no se sortean: se reparte la carga. Siempre gana la de menor
     puntuacion, y la puntuacion sube con el uso.

     Durante el trayecto dos jugadores en la misma ruta no se molestan -- cada
     intro corre en su propio bucket privado y no se ven. Lo que si se nota es
     la SALIDA: al soltar el bucket todos reaparecen en el mismo destino y ahi
     si se apilan. De ahi que una ruta en curso pese tanto.

     pesoActiva      -- lo que suma cada intro que ahora mismo usa esa ruta.
     pesoReciente    -- penalizacion que se desvanece a lo largo de la ventana.
     ventanaReciente -- cuanto dura ese recuerdo, en ms.
     ruido           -- desempate, para que con las cuentas empatadas no salga
                        siempre la primera. ]]
Config.Reparto = {
    pesoActiva      = 10.0,
    pesoReciente    = 4.0,
    ventanaReciente = 120000,
    ruido           = 0.25,
}

--- Modelos posibles. Se elige uno al azar. Deben existir en qbx_vehicles.
Config.Modelos = {
    'blista',
    'issi2',
    'panto',
    'prairie',
    'asea',
}

--- Prefijo de matricula. Se completa con digitos al azar hasta 8 caracteres.
Config.Matricula = 'IN'

--[[ ══ Despeje del punto de spawn ══════════════════════════════════════════

     Red de seguridad, no el caso normal. El coche aparece dentro del bucket
     privado del jugador, que va sin poblacion y sin nadie mas dentro: ahi no
     puede haber nada que estorbe.

     Lo unico que esto puede llegar a encontrar son restos nuestros -- el coche
     de una intro anterior que se cayo a medias y no llego a limpiarse. Aun asi
     la comprobacion de dueno sigue puesta: si alguna vez algo con dueno acabara
     en ese bucket, no se toca. ]]
Config.Despeje = {
    radio = 6.0,
}

--[[ ══ Bucket ══════════════════════════════════════════════════════════════

     El bucket de cada jugador es base + su serverId. El rango 90000 esta libre:
     garages usa 5000+id, housing 7000+id, metro 5310, y clothing/titlemenu
     usan el propio serverId. ]]
Config.BucketBase = 90000

--[[ 'relaxed' bloquea que el cliente cree entidades de poblacion pero deja
     pasar las de script. Con 'strict' se romperian los props y objetos de arma
     de cualquier otro resource durante la intro. El coche lo crea el servidor,
     asi que el lockdown no le afecta en ningun modo. ]]
Config.Lockdown = 'relaxed'

--[[ ══ Conduccion ══════════════════════════════════════════════════════════ ]]
Config.Conduccion = {
    velocidad = 16.0,   -- m/s (~58 km/h)

    --[[ El coche NO para al llegar: el jugador se queda conduciendo, en marcha.

         Para que la IA no empiece a frenar antes de tiempo no se la manda al
         destino sino a un punto `margenPasado` metros MAS ALLA, siguiendo el
         rumbo (la w) del destino. Asi cruza el punto de entrega a velocidad de
         crucero. El relevo se hace al entrar en `radioEntrega` del destino de
         verdad, y `radioParada` solo aplica a ese punto lejano que nunca se
         llega a pisar. ]]
    margenPasado = 90.0,
    radioEntrega = 10.0,
    radioParada  = 6.0,

    --[[ 786603 es el estilo "normal" de siempre, pero incluye el bit 128
         (StopAtTrafficLights). Los semaforos son objetos del mapa y siguen ahi
         aunque el bucket no tenga trafico: el coche pararia en rojo y el
         trayecto pasaria de ~22 s a algo impredecible. 786603 - 128 = 786475. ]]
    estilo = 786475,

    --[[ Respiro entre que el coche se materializa y se le da gas. Ya no es un
         plano estatico que se vea: para cuando el telon se levanta el coche
         lleva rodando lo que diga Config.Telon.marcha. Esto solo deja que la
         fisica se asiente antes de mandarle conducir. ]]
    retardoArranque = 700,
}

--[[ ══ Densidad de poblacion ═══════════════════════════════════════════════

     La poblacion del bucket va apagada (si no, el trayecto es impredecible),
     pero una ciudad completamente muerta durante 25 s se ve rara. El cliente
     devuelve algo de vida con los multiplicadores por frame. Al volver al
     bucket 0 se rampa de 'intro' a 1.0 para que el mundo se llene en vez de
     aparecer de golpe. ]]
Config.Densidad = {
    intro = 0.15,
    rampa = 4000,
}

--[[ ══ Colchon al volver al mundo compartido ═══════════════════════════════

     Al salir del bucket privado el coche aparece de golpe en una calle que
     lleva rato viva: puede haber otro jugador justo ahi, o trafico que en el
     bucket no existia. Durante unos segundos el coche atraviesa en vez de
     chocar.

     Son dos mecanismos distintos y hacen falta los dos. El modo fantasma de
     GTA solo existe entre JUGADORES en red -- contra los NPC no hace nada -- y
     para esos hay que ir quitando la colision uno a uno dentro de `radio`. ]]
Config.Fantasma = {
    duracion = 5000,
    radio    = 40.0,   -- hasta donde se buscan vecinos con los que no chocar
    refresco = 250,    -- cada cuanto se rehace esa lista de vecinos
}

--[[ ══ El telon ═════════════════════════════════════════════════════════

     Lo que tapa el paso de la creacion de personaje a la intro NO es el
     fundido nativo: es la pantalla de carga de Origen que ya vive en
     origen_hud -- logotipo, "Origen Network", los ocho tramos y "Cargando el
     servidor" -- puesta con sus exports. Ver client/telon.lua.

     minimo -- cuanto se queda como poco en pantalla, contado desde que baja. Si
       el montaje va rapido y no se pone este suelo, la pantalla de carga es un
       parpadeo y se lee como un fallo en vez de como una transicion.

     marcha -- cuanto sigue puesta DESPUES de que el coche arranque. Es lo que
       hace que la pantalla se descubra con el coche lanzado en vez de verlo
       salir desde parado.

       Ojo con subirlo mucho en rutas cortas: la camara baja por PROGRESO del
       trayecto, asi que este rato tambien gasta plano. A 16 m/s, cinco
       segundos son unos 80 m -- una quinta parte de una ruta de 350 m, pero
       casi la mitad de una de 200. Cuanto mas se tape, mas baja aparece la
       camara al descubrirse.

     Los dos se cumplen: se levanta cuando ha pasado `marcha` desde el arranque
     Y ademas lleva `minimo` en pantalla. ]]
Config.Telon = {
    entrada = 400,
    minimo  = 2500,
    marcha  = 5000,
    salida  = 700,
}

--[[ ══ El telon ═══════════════════════════════════════════════════════

     Lo que tapa el paso de la creacion de personaje a la intro NO es el
     fundido nativo: es la pantalla de carga de Origen que ya vive en
     origen_hud -- logotipo, "Origen Network", los ocho tramos y "Cargando el
     servidor" -- puesta con sus exports. Ver client/telon.lua.

     minimo -- cuanto se queda como poco en pantalla. Si el montaje va rapido y
       no se pone este suelo, la pantalla de carga es un parpadeo y se lee como
       un fallo en vez de como una transicion. ]]
Config.Telon = {
    entrada = 400,
    minimo  = 2500,
    salida  = 700,
}

--[[ ══ Aviso de relevo ═══════════════════════════════════════════════════

     El cartel que sale en pantalla poco antes de que el jugador coja el
     volante. No pide foco de NUI: es un aviso, no un menu, y robarle el raton
     justo antes de conducir seria lo contrario de lo que se busca.

     anticipacion -- a cuantos metros del punto de relevo aparece. A la
       velocidad de crucero por defecto, 70 m son unos cuatro segundos y medio.
     refresco     -- cada cuanto se manda el progreso de la barra a la NUI. ]]
Config.Aviso = {
    activo       = true,
    anticipacion = 70.0,
    refresco     = 50,

    kicker = 'Toma de control',
    titulo = 'Prepárate',
    texto  = 'El vehículo pasa a tus manos',
}

--[[ ══ Tiempos ═════════════════════════════════════════════════════════════ ]]
Config.Tiempos = {
    --[[ Cuando se sale del bucket privado.
         'despues': 10 s tras entregar el control (el jugador ya va conduciendo).
         'antes':   con el coche parado en el destino y la camara aun puesta.
                    Mas seguro -- cualquier hipo queda tapado -- pero el jugador
                    ve el resto del servidor un momento antes de tomar el mando. ]]
    momentoSalida = 'despues',
    esperaBucket  = 10000,

    atascoMs        = 6000,    -- cuanto aguanta parado antes de intervenir
    atascoVelocidad = 1.0,     -- m/s por debajo de lo cual cuenta como parado
    reintentosTarea = 3,
}

--[[ ══ Ritmo ═══════════════════════════════════════════════════════════════

     Los topes de tiempo NO son constantes: se calculan a partir de la distancia
     de cada ruta. Toda la cuenta esta en shared/ritmo.lua.

     factorCamara -- cuanto mas que el tiempo teorico tarda el suelo de la caida
       en completarse. Tiene que quedar por encima de lo que dura el viaje de
       verdad, o la camara tocaria suelo con el coche todavia lejos.
     factorTope   -- la paciencia del vigilante antes de forzar la llegada.
     margen       -- suelo fijo para el arranque, los semaforos y algun rodeo. ]]
Config.Ritmo = {
    factorCamara    = 2.0,
    factorTope      = 3.0,
    margen          = 20000,
    colchonServidor = 60000,
    minimo          = 20000,
    maximo          = 900000,
}

--- A donde se lleva al jugador si la intro se cae por completo.
--- Es el viejo Config.SpawnCoords de origen_clothing.
Config.SpawnFallback = vector4(-1385.68, 271.74, 72.07, 17.3)

--[[ Permiso de origen_admin que exige /testintro.

     Ojo: origen_admin trae Config.Permissions vacio y saca los grupos de la
     base de datos (origen_admin_groups). Solo el grupo 'god' pasa siempre; a
     cualquier otro hay que darle 'all' o este permiso exacto desde el panel.

     Ponlo a false mientras estas probando para saltarte la comprobacion. ]]
Config.Permiso = 'Comando:testintro'

--- Deja esto en true mientras se prueba: sin logs, un fallo a mitad de la intro
--- solo se ve como una pantalla en negro.
Config.Debug = false
