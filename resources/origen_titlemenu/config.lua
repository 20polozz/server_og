Config =  Config or {}

Config.DefaultSlots = 1
Config.radar  = false
Config.Locales = 'es' -- en, es, it | More languages can be added in the locales.lua file
Config.Version = "V4.2"

-- ========================================
-- SERVER THEME PROFILE (branding + colors)
-- Set in server.cfg:
-- setr origen_titlemenu_theme pink
-- setr origen_titlemenu_theme blue
-- ========================================
Config.Themes = {
    pink = {
        colors = {
            primary = "#850e49f2",
            border = "rgba(184, 25, 92, 0.35)",
            borderHover = "rgba(184, 25, 92, 0.7)",
            glow = "rgba(184, 25, 92, 0.5)"
        },
        branding = {
            serverName = "ORIGEN NETWORK",
            heroDescription = "Vive la mejor experiencia de roleplay en FiveM. Servidor activo desde 2020 con mas de 50,000 jugadores registrados.",
            discordUrl = "https://discord.gg/elorigenrp",
            youtubeUrl = "https://www.youtube.com/@origennetwork3412/",
            backgroundImage = "https://r2.fivemanage.com/YfpnafpGo82v27FMeaBOR/FONDOPARAMENU.png",
            logo = "./assets/logo.png"
        }
    },
    blue = {
        colors = {
            primary = "#003c88f2",
            border = "rgba(0, 90, 200, 0.35)",
            borderHover = "rgba(0, 90, 200, 0.75)",
            glow = "rgba(0, 90, 200, 0.5)"
        },
        branding = {
            serverName = "EVOLUCION NETWORK",
            heroDescription = "Vive una experiencia roleplay estable, competitiva y en evolucion constante.",
            discordUrl = "https://discord.gg/rphDrK47Ag",
            youtubeUrl = "https://www.youtube.com/@origennetwork3412/",
            backgroundImage = "https://r2.fivemanage.com/zBD8N3qNxX8Vkuij5D6Mp/EVOLUCIONFONDO.png",
            logo = "./assets/logo.png"
        }
    }
}

Config.Theme = string.lower(GetConvar("origen_titlemenu_theme", "pink"))
if not Config.Themes[Config.Theme] then
    Config.Theme = "pink"
end
Config.ActiveTheme = Config.Themes[Config.Theme]

-- ========================================
-- YOUTUBE VIDEO PLAYER
-- ========================================
-- Añade aquí los IDs de tus videos de YouTube
-- Para obtener el ID: https://www.youtube.com/watch?v=ID_DEL_VIDEO
-- Solo copia la parte después de "v=" 
Config.YoutubeVideos = {
    'oQkAtmZgH_Y',  -- Video 1
    '9KSDyjVfFf0',  -- Video 2
    '8L7gRjnTOJQ',  -- Video 3
    'JYOyrx543i4',  -- Video 4
    'EVU3qKt9wRI',  -- Video 5
    'tParrxnzHH4',  -- Video 6
    'fhjO4_Bef1g',  -- Video 7
    'HR-BnS05L9Y',  -- Video 8
    'KJjhj6wHFqc',  -- Video 9
    '_Ow7PCvkDFs',  -- Video 10
    'jUPSK1o_KcE',  -- Video 11
    -- Puedes añadir más videos aquí si quieres
}


--Enable this option if you have any kind of bug as this option applies experimental patches. 
--If you want to know how it works you can open ticket in the official origin store discord.
Config.ExperimentalVersion = true

Config.DefaultSpawn = vector4(-1383.53, 282.19, 21.01, 218.42) -- Only used for esx framework (x, y, z, heading)

Config.SkySpawnCinematicDisable = false --if you set true the spawn cinematic will be disabled and you will have a default cinematic.

Config.CommandLogOut = {
    --If you do not want to use a more advanced permissions system and want something more "simple and practical",
    --you can disable this option and just leave the discord id perms option active.
    permissions = true, 
    --If you want to use esx or qb admin permissions you can color them here. 
    --For esx you can use as example "admin" and for qbcore you can use as example: "god" or the ranges you have configured.
    group_permissions = {
        "admin",
    }, 
    --This is a more practical permission system using the discord id of the person you want to authorize, 
    --note that the user must have the discord account linked in fivem but do not worry this is something that happens almost automatically.
    discord_allowed = false, 
    discord_id = {
        1167345857843183636, --example discord id // you can add as many as you want
    },
    --FINALLY IMPORTANT: If you want to completely disable the permissions system so that any user can use this command; 
    --you must set the permissions option to false and also the discord_allowed option.
}



----------------------------
---- APARTMENT SETTINGS ----
----------------------------
-- qbcore Apartments
Config.DisableQBApartment = false -- Disable the default QB Apartment
Config.QBApartmentSpawns = false -- Enable the Spawn Player own Apartment

-- 0resmon Motels
Config._Or_Motels = false -- Active the 0r_motels script

-- 0r_apartments
Config.Enable0RApartments = false -- Active the 0r_apartments script

-- Origen Housing 
Config.EnableOrigenHousing = false -- Active the list of houses in the titlemenu and spawn them

Config.EnableStarterItems = true -- Enable starter items
Config.StarterItems = { --  this is just for esx framework -- QBCore set in qb-core/config.lua
    {item = 'id_card', amount = 1},
    -- El carné de conducir ya NO se da al nacer: se saca en la autoescuela
    -- (origen_autoescuela). 19/09/2026.
    {item = 'tosti', amount = 10},
    {item = 'water_bottle', amount = 10},
    {item = 'ognphone', amount = 1},
    {item = 'cash', amount = 5000},
}
 

-- Add more locations here
--[[
Config.Locations = {
    ['gc'] = {
        label = 'Central Garage',
        coords = vector4(235.08, -757.28, 37.86, 139.58),
    }

}
]]

-- =========================================================
-- GUIA RAPIDA (MODO FACIL) PARA MOVER CAMARAS Y SPAWN
-- =========================================================
-- FORMATO DE COORDENADAS:
-- vector3(x, y, z)      -> posicion (sin direccion)
-- vector4(x, y, z, h)   -> posicion + direccion (heading)
-- h = hacia donde mira (0-360)
--
-- QUE TOCA CADA CONFIG:
-- 1) HiddenCoords:
--    Donde se "esconde" el ped real del jugador mientras esta en el titlemenu.
--    Si no sabes para que es, dejalo quieto.
--
-- 2) CreationCoords:
--    Punto central donde aparece/queda el personaje en la pantalla de seleccion.
--    Si quieres mover "el escenario" del personaje, este es el principal.
--
-- 3) FixedCamera:
--    Camara fija de la pantalla de personajes (la que ves al elegir slot).
--    x,y,z = donde esta la camara
--    h     = hacia donde mira la camara
--
-- 4) CinematicSpawns:
--    Puntos del ped para la animacion de entrada/salida al seleccionar personaje.
--    Lo normal: poner las 5 entradas con los mismos coords que CreationCoords.
--    zoff = ajuste fino de altura del ped (sube/baja un poco).
--
-- 5) SpawnCam:
--    Camara alta del mapa cuando estas en "Ubicacion / Despertarse".
--    coords = posicion de camara
--    rot    = rotacion de la camara (pitch, roll, yaw)
--
-- CONSEJO PRACTICO:
-- - Primero ajusta CreationCoords
-- - Luego ajusta FixedCamera para encuadrar bien
-- - Luego iguala CinematicSpawns a CreationCoords
-- - Por ultimo ajusta SpawnCam (vista del mapa)
--
-- COMO SACAR COORDS RAPIDO:
-- 1) Ponte en el sitio dentro del juego
-- 2) Usa tu comando de coords (o algun resource de admin)
-- 3) Copia x,y,z,h en el config
-- 4) restart origen_titlemenu
--
-- SI AL VOLVER EL PED SE VE RARO:
-- - toca solo zoff en pasos pequenos: 0.00 -> 0.10 -> 0.20 -> 0.35
-- =========================================================

--[[ ══ El retrato de cada personaje ═══════════════════════════════════════

     La foto de la cara que sale en el slot y en la ficha. La saca el propio
     menu con la camara de la cara (client/retrato.lua), o sea que todas salen
     con el mismo plano, y se sube a fivemanage por origen_uploader.

     Hace falta screencapture (o screenshot-basic) y origen_uploader
     arrancados; si falta alguno, no se saca ninguna y no pasa nada mas.     ]]
Config.Retrato = {
    activo = true,

    -- Cada cuantas horas se vuelve a sacar. El personaje cambia de pelo y de
    -- ropa, y el retrato tiene que seguirle. 0 = sacarla cada vez que abre el
    -- menu (gasta una subida por entrada).
    refrescoHoras = 24,

    --[[ El encuadre. Copiado del de MEJILLAS del creador de ropa
         (origen_clothing/config/cameras.lua, ZONE_CHEEKS: 0.8 de frente, 0.3
         de lado y fov 20), que es el que enseña la cara un poco de perfil en
         vez de un carnet de frente. Aqui va en angulo y distancia porque la
         camara gira alrededor de la cabeza: 0.8 de frente + 0.3 de lado son
         0.85 a 21 grados. La distancia y el fov van un pelin mas abiertos que
         alli para que quepan la coronilla y los hombros.

         altura    sube o baja el punto al que mira, desde la cabeza
         distancia metros desde la cabeza
         lateral   desplaza el encuadre a un lado sin girar
         angulo    grados alrededor de la cabeza (negativo, el otro perfil)
         fov       cuanto abre el objetivo                                  ]]
    camara = {
        altura = 0.035,
        distancia = 1.05,
        lateral = 0.0,
        -- Negativo: la camara se pone al otro lado y la cara mira a la
        -- DERECHA de quien la ve. En positivo mira a la izquierda.
        angulo = -21.0,
        fov = 28.0,
    },

    -- Lo que se le da a la camara antes de disparar, en milisegundos: el pelo,
    -- la ropa y el desenfoque tardan un poco en asentarse.
    esperaMs = 350,

    -- screencapture saca solo la capa del JUEGO, no la interfaz (por eso el
    -- concesionario saca sus fotos con su menu abierto y salen limpias). Si
    -- alguna vez cambiase y en los retratos saliese la portada del menu, con
    -- esto en true la interfaz se esconde el instante de la foto.
    esconderNui = false,

    -- La captura cruda. jpg pesa una decima parte que png y la foto final se
    -- reencodea a png igualmente.
    formato = 'jpg',
    calidad = 0.92,

    -- El recorte que hace la interfaz sobre la captura. El cuadro es cuadrado,
    -- centrado en la cara, y `alto` es la parte de la altura de la pantalla que
    -- se queda (1.0 = de arriba abajo).
    salida = {
        lado = 512,
        alto = 0.92,

        --[[ El cuadro no se centra a ojo: la interfaz busca la coronilla y el
             centro de la cabeza sobre el fondo negro y encuadra desde ahi, asi
             que todas las caras caen en el mismo sitio aunque una lleve gorro o
             sea mas alta. `aire` es el hueco que se deja por encima de la
             cabeza, en partes del cuadro.

             centroX y centroY solo se usan si la busqueda falla. ]]
        aire = 0.14,
        centroX = 0.5,
        centroY = 0.5,

        -- Brillo medio (0-255) por debajo del cual se da la foto por negra y
        -- se vuelve a intentar en vez de guardarla.
        umbralNegro = 20,
    },

    -- Cuantas veces se reintenta cuando la foto sale negra (el ped tarda un
    -- momento en pintarse la primera vez).
    intentos = 3,
}

Config.HiddenCoords = vector4(1054.50, 4891.28, -31.80, 268.50)
Config.CreationCoords = vector4(1045.50, 4891.26, -31.80, 180.19)
Config.FixedCamera = vector4(1045.40, 4889.86, -31.15, -2.44)
Config.CinematicSpawns = {
    {
        coords = vector4(1045.50, 4891.26, -31.80, 180.19),
        scenario = "WORLD_HUMAN_GUARD_STAND",
        zoff = 0.35
    },
    {
        coords = vector4(1045.50, 4891.26, -31.80, 180.19),
        scenario = "WORLD_HUMAN_GUARD_STAND",
        zoff = 0.35
    },
    {
        coords = vector4(1045.50, 4891.26, -31.80, 180.19),
        scenario = "WORLD_HUMAN_GUARD_STAND",
        zoff = 0.35
    },
    {
        coords = vector4(1045.50, 4891.26, -31.80, 180.19),
        scenario = "WORLD_HUMAN_GUARD_STAND",
        zoff = 0.35
    },
    {
        coords = vector4(1045.50, 4891.26, -31.80, 180.19),
        scenario = "WORLD_HUMAN_GUARD_STAND",
        zoff = 0.35
    },
}

-- Camara del mapa de spawn (despertarse / ubicacion)
Config.SpawnCam = {
    coords = vector3(1045.40, 4889.86, -31.15),
    rot = vector3(-8.11, 0.05, -2.44),
}

-- =========================================================
-- CAMARA DE LLEGADA
-- La bajada desde el cielo al entrar en la ciudad, como en GTA Online.
-- Solo aplica al spawn en el ultimo sitio donde te desconectaste; los
-- spawns elegidos en el mapa ya bajan desde la camara del mapa.
--
-- activa      = ponlo en false y se entra en seco, como antes.
-- altura      = metros por encima de ti donde arranca la camara.
-- retirada    = metros por detras de ti donde acaba el plano.
-- alturaFinal = a que altura queda la camara al aterrizar.
-- bajada      = ms del tramo largo (el que tapa la carga del aspecto).
-- minimo      = ms que la camara aguanta en el aire como minimo, aunque tu
--               aspecto haya cargado antes. Sin esto, un dia rapido se ve
--               como un tiron en vez de como una llegada.
-- aterrizaje  = ms del ultimo tramo, ya pegada a ti.
-- entrega     = ms de la mezcla con la camara del juego.
-- tope        = ms tras los que se cierra sola si algo falla. No lo bajes.
-- =========================================================
Config.CamaraLlegada = {
    activa      = true,
    altura      = 260.0,
    retirada    = 9.0,
    alturaFinal = 3.2,
    bajada      = 5000,
    minimo      = 3500,
    aterrizaje  = 2600,
    entrega     = 1300,
    tope        = 20000,
}

Config.debug = {
    create = false,
    peds = false,
    spawn = false,
    general = true,
}

-- =========================================================
-- TITLEMENU CONFIGURATOR (in-game)
-- /confgtitlemenu -> open config menu (requires ox_lib)
-- Set enabled = false to disable the command completely.
-- =========================================================
Config.MenuConfigurator = {
    enabled = false,
    command = 'confgtitlemenu'
}

function debuger(typ,...)
    if Config.debug and Config.debug[typ] or typ == 'all' then
        -- print ('[^4Origen Titlemenu]^0', ...)
        -- print ('^0')
    end
end

function debug(msg)
    if Config.debug.general then
        -- print ('[^4Origen Titlemenu]^0', msg)
        -- print ('^0')
    end
end

Lang = Lang[Config.Locales]