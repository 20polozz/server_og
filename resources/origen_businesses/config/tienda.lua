--[[ Tiendas como trabajo de un negocio (30/09): caja registradora y clientes NPC.

     No hay que coger coordenadas: las CAJAS son los props de caja registradora
     que haya dentro del radio de un negocio de tienda (el usuario, 30/09: «que
     coja el prop si está dentro del radio del negocio»). El dependiente se pone
     detrás y el cliente delante, según hacia dónde mira la caja.

     Para los NPC, en los 24/7 del juego se usa además la planta del interior
     (v_shop_247, medida con CodeWalker): por qué puerta entran y dónde se paran
     a mirar. Cae sola si el negocio está en uno de ellos. En cualquier otra
     tienda entran desde la calle y van derechos a la caja. ]]
Config.Tienda = {
    -- Tipos de negocio que funcionan como tienda
    Tipos = { shop = true, store = true },

    -- Radio (m) alrededor de los puntos del negocio que cuenta como la tienda
    Radio = 20.0,

    --[[ Props de caja registradora. `delante`: hacia dónde mira el prop, a
         cuántos metros se pone el cliente; `detras`, el dependiente (al otro
         lado). prop_till_01 medido en el 24/7 de Strawberry: el dependiente
         de siempre queda a 0,5 m detrás. ]]
    Cajas = {
        [`prop_till_01`] = { delante = 1.00, detras = 0.50 },
        [`prop_till_02`] = { delante = 1.00, detras = 0.50 },
        [`prop_till_03`] = { delante = 1.00, detras = 0.50 },
        [0] = { delante = 1.10, detras = 0.50 },         -- caja puesta como punto (PuntoCaja)
    },
    CajasMax = 4,          -- por negocio

    --[[ Donde la caja no es un prop suelto sino parte del edificio (las LTD de
         gasolinera, 30/09: el juego no ve ningún objeto), el jefe pone un punto
         «caja» en el panel del negocio: el muñeco donde se pone el dependiente,
         mirando al cliente. Una caja de punto lleva este «modelo». ]]
    PuntoCaja = 0,

    -- La planta de los interiores del juego (local: el suelo en z = 0; rumbo 0 = +Y)
    Modelos = {
        v_shop_247 = {
            puerta = { fuera = vec3(1.87, -8.5, 0.0), umbral = vec3(1.87, -6.3, 0.0), dentro = vec3(1.87, -4.3, 0.0) },
            mirar = {
                vec4(2.40, -2.60, 0.0, 0.0),     -- góndola, lado de la puerta
                vec4(2.40, -0.45, 0.0, 180.0),   -- góndola, lado de atrás
                vec4(1.80, 0.60, 0.0, 0.0),      -- estantería del fondo
                vec4(6.20, -1.50, 0.0, 270.0),   -- neveras
                vec4(6.20, -3.00, 0.0, 270.0),
                vec4(5.15, 0.40, 0.0, 0.0),      -- nevera del fondo
                vec4(-0.67, -4.30, 0.0, 180.0),  -- fruta, junto a la puerta
            },
            centro = vec3(2.0, -1.8, 0.0),
        },
    },

    -- Dónde está cada interior del juego (de sus ymaps; rumbo en grados)
    Tiendas = {
        ['247_chumash'] = { label = '24/7 Chumash (Barbareno Rd)', modelo = 'v_shop_247', pos = vec3(-3245.646, 1003.062, 11.831), rumbo = 85.07 },
        ['247_ineseno'] = { label = '24/7 Banham Canyon (Ineseno Rd)', modelo = 'v_shop_247', pos = vec3(-3043.274, 586.071, 6.909), rumbo = 107.76 },
        ['247_strawberry'] = { label = '24/7 Strawberry (Innocence Blvd)', modelo = 'v_shop_247', pos = vec3(27.249, -1343.679, 28.497), rumbo = 0.00 },
        ['247_vinewood'] = { label = '24/7 Downtown Vinewood (Clinton Ave)', modelo = 'v_shop_247', pos = vec3(376.140, 329.265, 102.566), rumbo = -14.12 },
        ['247_harmony'] = { label = '24/7 Harmony (Route 68)', modelo = 'v_shop_247', pos = vec3(546.785, 2667.376, 41.156), rumbo = -172.50 },
        ['247_paleto'] = { label = '24/7 Paleto Bay (Great Ocean Hwy)', modelo = 'v_shop_247', pos = vec3(1731.959, 6417.244, 34.037), rumbo = -26.36 },
        ['247_sandy'] = { label = '24/7 Sandy Shores (Alhambra Dr)', modelo = 'v_shop_247', pos = vec3(1960.680, 3744.545, 31.344), rumbo = 30.00 },
        ['247_tataviam'] = { label = '24/7 Tataviam (Palomino Fwy)', modelo = 'v_shop_247', pos = vec3(2553.692, 383.738, 107.623), rumbo = 87.72 },
        ['247_senora'] = { label = '24/7 Grand Senora (Senora Fwy)', modelo = 'v_shop_247', pos = vec3(2676.219, 3283.602, 54.241), rumbo = 60.87 },
    },

    -- Clientes NPC: solo con alguien de servicio dentro de la tienda
    Npc = {
        Modelos = {
            'a_m_m_business_01', 'a_f_y_business_01', 'a_m_y_hipster_01', 'a_f_y_hipster_02',
            'a_m_m_eastsa_01', 'a_f_m_downtown_01', 'a_m_y_genstreet_01', 'a_f_y_tourist_01',
            'a_m_m_skater_01', 'a_f_y_vinewood_02', 'a_m_y_stbla_01', 'a_f_m_bevhills_01',
        },
        -- PRUEBAS (30/09, el usuario: «que vengan más NPC»): lo normal es { min = 40, max = 90 }
        Espera = { min = 2, max = 5 },          -- segundos entre un cliente y el siguiente
        Productos = { min = 1, max = 3 },       -- productos distintos por compra
        Unidades = { min = 1, max = 2 },        -- de cada uno
        --[[ Un NPC no compra lo que esté a más de MargenMax veces lo que le
             cuesta al negocio en el catálogo del proveedor: con precios de
             broma no entra dinero. Lo que no está en el catálogo tampoco. ]]
        MargenMax = 3.0,
        TopeHora = 4000,                        -- $ por negocio y hora que pueden dejar los NPC
        EsperaEnCaja = 90,                      -- segundos que espera en la caja antes de irse
        MirarSeg = { min = 4, max = 8 },
        Bolsa = 'prop_shopping_bags02',
    },

    -- Escanear en la caja: una prueba de habilidad por unidad
    Escaneo = { dificultad = 'easy', teclas = { 'e' }, segPorUnidad = 0.8 },

    -- Tickets a jugadores
    Ticket = { lineasMax = 10, unidadesMax = 50, caduca = 45 },

    Distancias = { caja = 1.6, cliente = 2.0 },

    --[[ TAREAS DEL TURNO (30/09, el usuario: «que tengan más tareas como
         reponer las estanterías y limpiar las neveras; que cobren como el
         granjero o el basurero, para incitar a trabajar en los locales»).

         Los sitios los pone el jefe como puntos del negocio (Ajustes). Mientras
         hay empleados de servicio dentro, el servidor va sacando tareas en esos
         puntos; las paga el servidor (no la caja del negocio), al banco, con
         el mismo tope que granja, aserradero, mina y basura.

         Cuentas: con un empleado sale una tarea nueva cada `Intervalo` s (con
         dos, el doble de seguido, etc.). A ~27 $ de media, trabajando sin
         parar son ~115 tareas/h ≈ 3.100 $/h; con los paseos y los huecos,
         ~2.500 $/h, como la granja. El tope corta en 3.000 $ cada 30 min. ]]
    Tareas = {
        Intervalo = 30,          -- s entre tarea y tarea, por empleado dentro
        PorEmpleado = 3,         -- tareas abiertas a la vez por empleado dentro
        Max = 8,                 -- y como mucho, por tienda
        Enfriar = 150,           -- s hasta que el mismo sitio vuelve a pedir tarea
        Distancia = 1.6,         -- m al punto para hacerla

        --[[ Los tipos de punto. `max`: cuántos puede poner una tienda sin que
             lo abra la administración. `paga` en $, `seg` lo que dura. ]]
        Tipos = {
            estanteria = { label = 'Reponer estantería', punto = 'Estantería', paga = 28, seg = 8, max = 8, icono = 'lucide:package-open' },
            nevera = { label = 'Limpiar nevera', punto = 'Nevera', paga = 24, seg = 9, max = 4, icono = 'lucide:refrigerator' },
            suelo = { label = 'Fregar el suelo', punto = 'Suelo', paga = 20, seg = 10, max = 4, icono = 'lucide:droplets' },
            papelera = { label = 'Sacar la basura', punto = 'Papelera', paga = 40, seg = 2.5, max = 2, icono = 'lucide:trash-2' },
        },
        -- De dónde salen las cajas para reponer (opcional: sin trastienda se repone sin ir a por ella)
        Trastienda = { max = 1, seg = 2.0 },

        --[[ Sacar la basura: a cualquier cubo o contenedor de la calle (la
             lista del basurero, origen_garbage). Antes solo valían los 8
             contenedores grandes y junto a muchas tiendas no hay ninguno: te
             quedabas con la bolsa en la mano sin saber dónde tirarla (30/09). ]]
        Contenedores = {
            [`prop_bin_01a`] = true, [`prop_bin_02a`] = true, [`prop_bin_03a`] = true,
            [`prop_bin_04a`] = true, [`prop_bin_05a`] = true, [`prop_bin_06a`] = true,
            [`prop_bin_07a`] = true, [`prop_bin_07b`] = true, [`prop_bin_07c`] = true,
            [`prop_bin_07d`] = true, [`prop_bin_08a`] = true, [`prop_bin_08open`] = true,
            [`prop_bin_09a`] = true, [`prop_bin_10a`] = true, [`prop_bin_10b`] = true,
            [`prop_bin_11a`] = true, [`prop_bin_11b`] = true, [`prop_bin_12a`] = true,
            [`prop_bin_13a`] = true, [`prop_bin_14a`] = true, [`prop_bin_14b`] = true,
            [`prop_bin_beach_01a`] = true, [`prop_bin_beach_01d`] = true, [`prop_recyclebin_01a`] = true,
            [`prop_recyclebin_02a`] = true, [`prop_recyclebin_02b`] = true, [`prop_recyclebin_02_c`] = true,
            [`prop_recyclebin_02_d`] = true, [`prop_recyclebin_03_a`] = true, [`prop_recyclebin_04_a`] = true,
            [`prop_recyclebin_04_b`] = true, [`prop_recyclebin_05_a`] = true, [`zprop_bin_01a_old`] = true,
            [`prop_cs_bin_01`] = true, [`prop_cs_bin_02`] = true, [`prop_cs_bin_03`] = true,
            [`prop_dumpster_01a`] = true, [`prop_dumpster_02a`] = true, [`prop_dumpster_02b`] = true,
            [`prop_dumpster_3a`] = true, [`prop_dumpster_4a`] = true, [`prop_dumpster_4b`] = true,
            [`prop_cs_dumpster_01a`] = true, [`p_dumpster_t`] = true,
        },
        ContenedorMin = 6.0,     -- m del punto de la papelera (que no valga la de dentro)
        ContenedorMax = 90.0,

        Tope = { dinero = 3000, ventana = 30 * 60 },

        --[[ Lo que se ve y se lleva. Todas probadas en un clon del personaje
             el 30/09 (IsEntityPlayingAnim / IsPedUsingScenario): arrancan.
             Las mismas salen en el clon transparente al colocar el punto. ]]
        Anim = {
            caja = { dict = 'anim@heists@box_carry@', clip = 'idle', flag = 49,
                prop = 'hei_prop_heist_box', hueso = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0) },
            -- Alargar las manos a la balda, colocando
            estanteria = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab', flag = 1 },
            -- Trapo en vertical, como un cristal: la puerta de la nevera (el escenario trae el trapo)
            nevera = { escenario = 'WORLD_HUMAN_MAID_CLEAN' },
            -- La fregona (el escenario trae la fregona)
            suelo = { escenario = 'WORLD_HUMAN_JANITOR' },
            -- Agacharse a coger la caja en la trastienda
            cogerCaja = { dict = 'pickup_object', clip = 'pickup_low', flag = 1 },
            -- Teclear en la caja registradora
            registradora = { dict = 'anim@heists@prison_heiststation@cop_reactions', clip = 'cop_b_idle', flag = 49 },
            -- La bolsa pequeña de los golpes (la de la calle se veía enorme en la mano)
            bolsa = { dict = 'missfbi4prepp1', clip = '_idle_garbage_man', flag = 49,
                prop = 'hei_prop_heist_binbag', hueso = 57005, pos = vec3(0.12, 0.0, 0.0), rot = vec3(25.0, 270.0, 180.0) },
            coger = { dict = 'anim@heists@narcotics@trash', clip = 'pickup', flag = 48 },
            tirar = { dict = 'anim@heists@narcotics@trash', clip = 'throw_b', flag = 48, ms = 1200 },
        },
    },
}

-- Las tareas de turno pertenecen a Origen. `setr origen:marca` se replica al
-- cliente; si falta, el valor predeterminado mantiene Origen.
Config.Tienda.Tareas.Habilitadas = GetConvar('origen:marca', 'origen') ~= 'nacion'

--- ¿Es un tipo de punto de tarea de tienda (o la trastienda)?
--- Qué animación hace el clon al colocar cada punto de tienda.
Config.Tienda.Previa = {
    caja = 'registradora', estanteria = 'estanteria', nevera = 'nevera',
    suelo = 'suelo', papelera = 'coger', trastienda = 'cogerCaja',
}

function Config.Tienda.EsPuntoDeTarea(tipo)
    return Config.Tienda.Tareas.Tipos[tipo] ~= nil or tipo == 'trastienda'
end

--[[ ¿En este local funciona la tienda (caja, clientes NPC y tareas del turno)?

     Antes se miraba SOLO el tipo de negocio, y la lista eran dos: `shop` y
     `store`. En el servidor la mayoría de los locales son `restaurant`, así que
     en un restaurante la caja registradora, la nevera, la estantería y la
     trastienda se podían colocar desde el panel y luego no hacían nada: el
     bucle que las busca no arrancaba nunca. Eso es lo que se contaba como "la
     caja no funciona".

     Ahora manda lo que el dueño HA PUESTO. Si ha colocado una caja o un punto
     de tarea es que quiere la tienda ahí, diga lo que diga la etiqueta del
     local; y donde no hay ninguno de esos puntos no se enciende nada, que es
     lo que hacía el tipo bien.

     @param business table|nil  el negocio ya cargado en cliente
     @param tipo string|nil     su tipo, si se tiene a mano
]]
function Config.Tienda.EsTienda(business, tipo)
    if Config.Tienda.Tipos[tipo or ''] then return true end
    if type(business) ~= 'table' or type(business.points) ~= 'table' then return false end

    for _, p in pairs(business.points) do
        if type(p) == 'table' then
            local puntoTarea = Config.Tienda.Tareas.Habilitadas and Config.Tienda.EsPuntoDeTarea(p.type)
            if p.type == 'caja' or puntoTarea then return true end
        end
    end

    return false
end

--- Cuántos puntos de ese tipo puede poner una tienda sin límite de la administración.
function Config.Tienda.TopePunto(tipo)
    if tipo == 'caja' then return Config.Tienda.CajasMax end
    if not Config.Tienda.Tareas.Habilitadas then return nil end
    if tipo == 'trastienda' then return Config.Tienda.Tareas.Trastienda.max end
    local t = Config.Tienda.Tareas.Tipos[tipo]
    return t and t.max or nil
end

--- Un punto local de un interior del juego (vec3/vec4) en el mundo.
function Config.Tienda.Mundo(tienda, p)
    local t = Config.Tienda.Tiendas[tienda]
    if not t then return nil end
    local r = math.rad(t.rumbo)
    local c, s = math.cos(r), math.sin(r)
    local x = t.pos.x + p.x * c - p.y * s
    local y = t.pos.y + p.x * s + p.y * c
    local z = t.pos.z + p.z
    if p.w then
        return vec4(x, y, z, (p.w + t.rumbo) % 360.0)
    end
    return vec3(x, y, z)
end

function Config.Tienda.Modelo(tienda)
    local t = Config.Tienda.Tiendas[tienda]
    return t and Config.Tienda.Modelos[t.modelo]
end

--- Una caja puesta como punto (coords del dependiente, a ras de suelo, y su
--- rumbo mirando al cliente) → la posición y el rumbo que tendría el prop.
function Config.Tienda.CajaDePunto(c)
    local x, y, z, w = tonumber(c and c.x), tonumber(c and c.y), tonumber(c and c.z), tonumber(c and c.w) or 0.0
    if not x or not y or not z then return nil end
    local r = math.rad(w)
    local d = Config.Tienda.Cajas[Config.Tienda.PuntoCaja].detras
    return vec3(x - math.sin(r) * d, y + math.cos(r) * d, z + 1.1), w % 360.0
end

--- Dónde se ponen dependiente y cliente de una caja (pos del prop, rumbo en grados).
--- Devuelve dos vec4 a ras de suelo aproximado (z del prop - 1,1).
function Config.Tienda.PuestosCaja(modelo, pos, rumbo)
    local c = Config.Tienda.Cajas[modelo] or { delante = 1.0, detras = 0.5 }
    local r = math.rad(rumbo)
    local fx, fy = -math.sin(r), math.cos(r)
    local z = pos.z - 1.1
    local cliente = vec4(pos.x + fx * c.delante, pos.y + fy * c.delante, z, (rumbo + 180.0) % 360.0)
    local dependiente = vec4(pos.x - fx * c.detras, pos.y - fy * c.detras, z, rumbo % 360.0)
    return dependiente, cliente
end
