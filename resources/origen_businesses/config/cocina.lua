--[[
    LA COCINA DE LOS RESTAURANTES

    Un punto `kitchen` con un mueble de verdad encima (la cocina de gas, la
    plancha, la barbacoa…), su despensa, y el cocinar con animación y humo.
    La lógica vive en source/client/cocina.lua y source/server/cocina.lua.

    Las recetas no están aquí: son las de «Crafteos» del panel de admin con
    la mesa «Cocina».
]]

Config.Cocina = {
    --[[ Los muebles que se pueden poner. El modelo es la clave: el servidor no
         guarda uno que no esté en esta lista, así que añadir un mueble es
         añadir una fila. El primero es el que sale elegido.

         Mientras alguien cocina, encima del mueble aparecen sus `utensilios`
         (la sartén, la olla, los filetes) y el humo sale de `humo`. Las dos
         posiciones van en metros desde el centro del mueble, en sus ejes:
         x a lo ancho, y hacia atrás (el frente es -y), z hacia arriba.

         Probados y descartados (17/09): la plancha `prop_griddle_02` es de
         encimera (16 cm de alto) y la freidora `prop_chip_fryer` lleva la
         campana pegada (3,7 m). ]]
    Muebles = {
        {
            model = 'prop_cooker_03', label = 'Cocina de gas',
            utensilios = {
                { model = 'prop_kitch_pot_fry', pos = vec3(0.42, -0.20, 0.975), rot = vec3(0.0, 0.0, 25.0) },
                { model = 'prop_kitch_pot_med', pos = vec3(-0.43, 0.15, 0.975), rot = vec3(0.0, 0.0, 0.0) },
            },
            humo = vec3(0.42, -0.20, 1.02),
        },
        {
            model = 'prop_bbq_5', label = 'Barbacoa grande',
            utensilios = {
                { model = 'prop_cs_steak', pos = vec3(-0.20, 0.0, 0.95), rot = vec3(0.0, 0.0, 10.0) },
                { model = 'prop_cs_steak', pos = vec3(0.15, 0.05, 0.95), rot = vec3(0.0, 0.0, -20.0) },
            },
            humo = vec3(0.0, 0.0, 1.0),
        },
        {
            model = 'prop_bbq_1', label = 'Barbacoa',
            utensilios = {
                { model = 'prop_cs_steak', pos = vec3(-0.30, 0.05, 0.95), rot = vec3(0.0, 0.0, 15.0) },
                { model = 'prop_cs_steak', pos = vec3(0.02, 0.10, 0.95), rot = vec3(0.0, 0.0, -25.0) },
            },
            humo = vec3(-0.15, 0.05, 1.0),
        },
    },

    -- Una cocina sin mueble (la del propio local): sin utensilios y el humo
    -- a esta altura sobre el punto.
    SinMueble = {
        utensilios = {},
        humo = vec3(0.0, 0.0, 1.0),
    },

    --[[ Los tipos de negocio cuyo jefe coloca la cocina desde su panel. La
         administración la puede poner en cualquiera desde el suyo. Hace falta
         además hueco de cocina en los límites de puntos del negocio. ]]
    TiposQueLaColocan = {
        restaurant = true,
    },

    -- La despensa: una por negocio, la comparten sus cocinas. Es solo un
    -- almacén: se cocina con lo que lleva el cocinero en el inventario.
    Despensa = {
        slots = 40,
        peso = 200000,
    },

    -- A cuántos metros sale la tecla, y cuántos acepta el servidor (algo más:
    -- el jugador se mueve un poco entre que pulsa y llega la comprobación).
    Distancia = 2.0,
    DistanciaServidor = 4.0,

    -- A qué distancia aparece el mueble (y desaparece al alejarse).
    DistanciaMueble = 80.0,

    --[[ EL PUNTO DE COCCIÓN (ui/source/src/components/MinijuegoCocina.vue)

         Mientras se cocina hay que dar la vuelta unas cuantas veces: una
         aguja va y viene por una barra y se pulsa cuando pasa por la zona.
         Las vueltas las genera el servidor; la nota también la pone él.

         · vueltas: una cada `cadaMs` de cocción, entre `min` y `max`. La
           cocción dura al menos `msPorVuelta` por vuelta, para que quepan.
         · zona: medio ancho de la zona buena y de la perfecta (la barra mide 1).
         · velocidad: pasadas de la aguja por segundo; sube con el nivel de la
           receta hasta `tope`.
         · notas: según la parte de puntos conseguida (perfecto 2, bien 1,
           fallo 0 por vuelta). `multiplica` va sobre lo que da la receta;
           0 es quemado: se gastan los ingredientes y no sale nada. ]]
    Minijuego = {
        vueltas = { min = 3, max = 6, cadaMs = 6000 },
        msPorVuelta = 3000,
        zona = { bien = 0.13, perfecto = 0.045 },
        velocidad = { min = 0.6, max = 0.9, porNivel = 0.07, tope = 1.6 },
        notas = {
            { min = 0.85, nombre = 'perfecto', label = '¡Perfecto!',     multiplica = 1.5 },
            { min = 0.50, nombre = 'bien',     label = 'Bien hecho',     multiplica = 1.0 },
            { min = 0.20, nombre = 'regular',  label = 'Regular',        multiplica = 0.5 },
            { min = 0.00, nombre = 'quemado',  label = 'Se ha quemado',  multiplica = 0 },
        },
    },

    -- Lo que hace el personaje mientras cocina: la espátula de la barbacoa.
    Animacion = {
        dict = 'amb@prop_human_bbq@male@idle_a',
        clip = 'idle_b',
        prop = {
            model = 'prop_fish_slice_01',
            bone = 28422,
            pos = vec3(0.0, 0.0, 0.0),
            rot = vec3(0.0, 0.0, 0.0),
        },
    },

    --[[ El humo que sale del fuego mientras alguien cocina, en el punto
         `humo` del mueble. Lo ve (con los utensilios) todo el que esté a
         `radio` metros o menos cuando empieza. ]]
    --[[ Probados en el juego el 17/09 a pleno día: `ent_amb_smoke_foundry`
         no se ve a escala pequeña y `ent_amb_fbi_smoke_linger` y
         `ent_amb_steam_vent_rnd` no existen en `core`. Estos dos juntos: la
         columna de vapor se ve de lejos y la nube se queda sobre la sartén. ]]
    Humo = {
        asset = 'core',
        efectos = {
            { nombre = 'ent_sht_steam', escala = 2.5 },
            { nombre = 'ent_amb_steam_pipe_hvy', escala = 1.0 },
        },
        radio = 80.0,
    },
}

--- La lista para las interfaces: solo modelo y nombre (los vectores no
--- viajan bien a la NUI).
function Config.Cocina.ParaInterfaz()
    local lista = {}
    for i, m in ipairs(Config.Cocina.Muebles) do
        lista[i] = { model = m.model, label = m.label }
    end
    return lista
end

--- El mueble de esa lista con ese modelo, o nil.
function Config.Cocina.Mueble(modelo)
    if type(modelo) ~= 'string' then return nil end
    for i = 1, #Config.Cocina.Muebles do
        if Config.Cocina.Muebles[i].model == modelo then
            return Config.Cocina.Muebles[i]
        end
    end
    return nil
end
