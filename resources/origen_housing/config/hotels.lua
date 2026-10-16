Config.Hotels = {
    enabled = true,
    
    checkExpiredInterval = 60000,
    
    notifications = {
        beforeExpire = {
            ['24h'] = 86400,
            ['1h'] = 3600,
        }
    },

    defaultRentalOptions = {
        { type = Translations.daily, price = 500, duration = 86400 },
        { type = Translations.weekly, price = 3000, duration = 604800 },
        { type = Translations.monthly, price = 10000, duration = 2592000 },
    },

    defaultStashData = {
        slots = 50,
        weight = 100000,
    },

    blipSettings = {
        sprite = 475,
        color = 0,
        scale = 0.7,
    },

    roomBlipSettings = {
        sprite = 40,
        color = 0,
        scale = 0.5,
        showAvailableRooms = false,
    },

    --[[ ══ Los interiores de las habitaciones ═════════════════════════════

         OJO con lo que se pone aquí, porque no es lo que parece: esto NO
         spawnea nada. Son coordenadas de sitios que ya tienen que existir en
         el mundo, y el recurso se limita a teletransportarte allí. Apuntar a
         un hueco vacío no da error: te deja en el aire y te caes.

         Hay dos formas de que exista algo en esas coordenadas:

         · Un interior del juego base, de los que enciende bob74_ipl. Como
           bob74_ipl es dependencia de este recurso, están disponibles
           siempre y no hay que instalar ningún mapeado. Son los dos
           primeros de aquí abajo.

         · Un MLO propio, metido como recurso aparte. Entonces se ponen aquí
           las coordenadas de dentro.

         Las habitaciones NO se pisan entre ellas aunque compartan interior:
         cada una tiene su propio routing bucket (9000 + id), así que dos
         inquilinos del mismo hotel no se ven aunque estén en el mismo sitio
         del mapa.

         De dónde salen las coordenadas: `spawn` es el punto de entrada de
         Config.IPL (config/ipl_interiors.lua), la misma lista que usan las
         casas de tipo `ipl`; `stash`, el punto con el que bob74_ipl
         identifica cada interior. Están sacadas del código, no probadas en
         partida: si el almacén cae en una pared, se mueve aquí. ]]
    interiorIPLs = {
        --  El clásico para un hotel: el estudio de gama baja de GTA Online.
        --  Existe siempre, sin instalar nada.
        --  Mantiene la clave de antes —apuntaba a un hueco bajo el mapa— para
        --  no romper las habitaciones que ya se hubieran creado con ella.
        ['v_motel_mp_small_default'] = {
            label = 'Estudio (gama baja)',
            spawn = vector4(266.0410, -1007.3227, -101.0085, 358.5691),
            --  El almacén y el ropero, medidos dentro del apartamento.
            stash = vector4(265.96, -999.45, -99.01, 269.11),
            wardrobe = vector4(259.87, -1004.06, -99.01, 172.35),
        },

        --  Un escalón por encima, para habitaciones de más precio.
        ['gtao_house_mid_1'] = {
            label = 'Apartamento (gama media)',
            spawn = vector4(346.5080, -1012.6182, -99.1962, 1.1224),
            stash = vector4(347.2686, -999.2955, -99.1962, 0.0),
            --  Sin `wardrobe` medido: el armario sale en el almacén con la G
            --  (HotelRoom:CreateInsidePoints). Poner aquí uno propio lo quita.
        },

        --[[ Estas dos venían de serie apuntando a coordenadas del mapa a
             secas, sin nada que las respalde: no hay ningún MLO en el
             servidor para ellas. Se dejan porque puede haber habitaciones
             creadas con estas claves, pero antes de usarlas hay que meter el
             mapeado y comprobar que las coordenadas caen dentro. ]]
        ['v_motel_mp'] = {
            label = 'Motel (necesita MLO)',
            spawn = vector4(-1407.62, 270.53, 24.91, 180.53),
            stash = vector4(-1403.18, 266.79, 24.91, 257.86),
        },

        ['interiorsandy'] = {
            label = 'Motel Sandy (necesita MLO)',
            spawn = vector4(1622.34, 3782.19, 24.95, 37.07),
            stash = vector4(1621.35, 3788.7, 24.95, 34.58),
        },
    },
}




