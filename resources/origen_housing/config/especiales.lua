-- Muebles especiales de guarida: sótano, sala de interrogatorio, celda
-- (custom/client/especiales.lua y custom/server/especiales.lua). Son muebles
-- del catálogo (config/furniture.lua, categorías «Sótano» y «Sótano: celda y
-- herramientas») a los que aquí se les da uso con la E:
--   · sentarse en las sillas y taburetes,
--   · tumbarse en los colchones,
--   · atar a la silla de interrogatorio a alguien que ya está esposado.
-- Es roleo entre jugadores: no hace daño ni quita vida a nadie.
--
-- Todos los modelos son props del propio juego que están en los ytyp de
-- `levels/gta5/props/…` (siempre cargados), nunca en los de un interior. Las
-- puertas de barrotes de la celda no van aquí: son muebles `type = 'door'` y
-- las lleva el sistema de puertas de la casa (cerrojo con llave).
Config.Especiales = {
    alcance = 1.4,          -- metros hasta el asiento o el colchón para que salga la E
    ocupado = 0.7,          -- con otro personaje a menos de esto del sitio, está ocupado
    altoAsiento = 0.48,     -- altura del asiento sobre la base del modelo, si el modelo no dice otra
    escenario = 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER',
    tumbado = { dict = 'timetable@tracy@sleep@', clip = 'base' },   -- la de las camillas del hospital

    atar = {
        minutos = 20,       -- tope: pasado este tiempo, el servidor suelta al atado
        ritmo = 2000,       -- ms mínimos entre dos órdenes de atar o soltar del mismo jugador
        distancia = 3.0,    -- lo más lejos que pueden estar el que ata y el esposado
        soltar = 3.5,       -- lo más lejos del atado desde donde se le puede soltar
        tope = 6.0,         -- lo más lejos de la silla que el servidor da por bueno (casas sin dimensión propia)
        casa = 60.0,        -- en esas casas, si el que ató se aleja más que esto de la silla, se suelta
        deriva = 3.0,       -- si el atado aparece a más de esto de donde quedó sentado, se suelta
        respuesta = 3000,   -- ms que se espera a que el cliente del esposado confirme que lo está
        esperaPieza = 10000,-- ms que el atado espera a tener la silla delante antes de avisar de que no puede
        vistazo = 2.5,      -- a qué distancia busca el cliente a un esposado para ofrecer «Atar»
    },

    -- Mientras se está atado: correr, saltar, agacharse, pegar, apuntar, cubrirse, entrar en coches…
    bloqueados = { 21, 22, 23, 24, 25, 30, 31, 32, 33, 34, 35, 36, 37, 44, 45, 47, 58, 73, 75,
        140, 141, 142, 143, 257, 263, 264, 266, 267, 268, 269 },

    textos = {
        sentarse = 'Sentarse',
        tumbarse = 'Tumbarse',
        levantarse = 'Levantarse',
        atar = 'Atar a la silla',
        soltar = 'Soltar de la silla',
    },

    -- Qué se puede hacer con cada modelo.
    --   asiento = { x, y, z, giro }   se puede uno sentar. x/y: metros desde el centro del modelo
    --                                 (y positivo, hacia su frente); z: altura del asiento sobre su
    --                                 base; giro: grados que se suman al rumbo del mueble (180 = el
    --                                 respaldo queda del lado +Y del modelo, como en las sillas del juego)
    --   cama = { x, y, z, giro }      se puede uno tumbar encima. z: metros sobre lo más alto del modelo
    --   atar = true                   además, se puede dejar atado en ella a un esposado
    modelos = {
        -- sillas de interrogatorio
        ['prop_torture_ch_01'] = { asiento = {}, atar = true },
        ['prop_old_wood_chair'] = { asiento = {}, atar = true },
        -- sillas y taburetes
        ['prop_table_03_chr'] = { asiento = {} },
        ['prop_table_03b_chr'] = { asiento = {} },
        ['prop_chair_10'] = { asiento = {} },
        ['prop_off_chair_04'] = { asiento = { z = 0.52 } },
        ['prop_cs_office_chair'] = { asiento = {} },
        ['prop_ld_farm_chair01'] = { asiento = { z = 0.42 } },
        ['prop_skid_chair_01'] = { asiento = { z = 0.42 } },
        ['prop_skid_chair_02'] = { asiento = { z = 0.42 } },
        ['prop_skid_chair_03'] = { asiento = { z = 0.42 } },
        ['prop_wheelchair_01'] = { asiento = { z = 0.50 } },
        ['prop_stool_01'] = { asiento = { z = 0.75 } },
        ['prop_rub_stool'] = { asiento = { z = 0.47 } },
        -- colchones y saco: el modelo es largo en X, así que el cuerpo va a lo largo de X
        ['prop_rub_matress_01'] = { cama = { giro = 90.0 } },
        ['prop_rub_matress_02'] = { cama = { giro = 90.0 } },
        ['prop_rub_matress_03'] = { cama = { giro = 90.0 } },
        ['prop_rub_matress_04'] = { cama = { giro = 90.0 } },
        ['prop_skid_sleepbag_1'] = { cama = { giro = 90.0 } },
    },
}

-- El nombre del modelo si es uno de estos (vale el nombre o su hash)
function Config.Especiales.Es(modelo)
    if type(modelo) == 'number' then
        for nombre in pairs(Config.Especiales.modelos) do
            if joaat(nombre) == modelo then return nombre end
        end
        return nil
    end
    return type(modelo) == 'string' and Config.Especiales.modelos[modelo] and modelo or nil
end
