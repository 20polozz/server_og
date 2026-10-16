-- Los scripts que aparecen en la pestaña "Scripts" del panel.
--
-- Cada tarjeta abre el panel de administracion de su recurso llamando a
-- exports[resourceName]:openManagement(). El panel de admin se cierra antes
-- de abrirlo: son dos interfaces distintas y no pueden tener el foco a la vez.
--
--   id           permiso que hace falta para ver la tarjeta
--   resourceName recurso al que se le pide openManagement()
--   category     Core | Criminal | Economy | Jobs | Vehicles
--   panel        (opcional) para un recurso con MÁS de una tarjeta: se le pasa a openManagement(panel)
--   permiso      (opcional) el permiso que hace falta, si no es el propio id (la segunda tarjeta de un recurso)
--   requiere     (opcional) otros recursos que también tienen que estar arrancados para salir como «Activo»

Config.Scripts = {
    {
        id = "origen_inventory",
        name = "Origen Inventario",
        description = "Inventario: objetos, fabricación, tiendas y alijos",
        icon = "inventory",
        category = "Core",
        adminRoute = "export", -- Usar export en lugar de iframe
        resourceName = "origen_inventory", -- Nombre del recurso en el servidor
        color = "#850e49" -- Color personalizado (opcional)
    },
    {
        id = "origen_housing",
        name = "Origen Viviendas",
        description = "Casas y hoteles: construcción, muebles, puertas e interiores",
        icon = "home",
        category = "Core",
        adminRoute = "export", -- Usar export en lugar de iframe
        resourceName = "origen_housing", -- Nombre del recurso en el servidor
        color = "#850e49" -- Color personalizado (opcional)
    },
    {
        id = "origen_clothing",
        name = "Origen Ropa",
        description = "Ropa: tiendas, conjuntos y prendas a medida",
        icon = "shirt",
        category = "Core",
        adminRoute = "export", -- Usar export en lugar de iframe
        resourceName = "origen_clothing", -- Nombre del recurso en el servidor
        color = "#850e49" -- Color personalizado (opcional)
    },
    {
        id = "origen_doorlock",
        name = "Origen Puertas",
        description = "Sistema de puertas con control de acceso y gestión de permisos",
        icon = "door",
        category = "Core",
        adminRoute = "export", -- Usar export en lugar de iframe
        resourceName = "origen_doorlock", -- Nombre del recurso en el servidor
        color = "#850e49" -- Color personalizado (opcional)
    },
    {
        id = "origen_quests",
        name = "Origen Misiones",
        description = "Sistema avanzado de misiones con NPCs hostiles, minijuegos y eventos",
        icon = "quest",
        category = "Core",
        adminRoute = "export", -- Usar export en lugar de iframe
        resourceName = "origen_quests", -- Nombre del recurso en el servidor
        color = "#850e49" -- Color personalizado (opcional)
    },
    -- {
    --     id = "Renewed-Weathersync",
    --     name = "Origen Clima",
    --     description = "Control avanzado del clima y eventos meteorológicos del servidor",
    --     icon = "cloud",
    --     category = "Core",
    --     adminRoute = "export",
    --     resourceName = "Renewed-Weathersync",
    --     color = "#0ea5e9"
    -- },
    -- Queue System temporarily disabled - minimal mode active
    -- {
    --     id = "origen_queue",
    --     name = "Cola de entrada",
    --     description = "Sistema de cola con prioridades, grace period y anti-spam",
    --     icon = "users",
    --     category = "Core",
    --     adminRoute = "export",
    --     resourceName = "origen_queue",
    --     color = "#8b5cf6"
    -- },
    {
        id = "origen_robberies",
        name = "Origen Robos",
        description = "Robos: NPC, cajas fuertes, guardias y botín variable",
        icon = "robbery",
        category = "Criminal",
        adminRoute = "export", -- Usar export en lugar de iframe
        resourceName = "origen_robberies",
        color = "#850e49"
    },
    {
        id = "origen_police",
        name = "Origen Policía",
        description = "Panel administrativo de policía: gestión de rangos, etiquetas y sueldos en tiempo real",
        icon = "police",
        category = "Jobs",
        adminRoute = "export",
        resourceName = "origen_police",
        color = "#1e3a8a"
    },
    -- {
    --     id = "origen_ambulance",
    --     name = "Origen Ambulancia",
    --     description = "Sistema médico profesional con gestión de emergencias",
    --     icon = "ambulance",
    --     category = "Jobs",
    --     adminRoute = "/admin",
    --     resourceName = "origen_ambulance",
    --     color = "#dc2626"
    -- },
    -- {
    --     id = "origen_mechanic",
    --     name = "Origen Mecánico",
    --     description = "Taller mecánico con sistema de reparación y tuning",
    --     icon = "mechanic",
    --     category = "Jobs",
    --     adminRoute = "/admin",
    --     resourceName = "origen_mechanic",
    --     color = "#ea580c"
    -- },
    {
        id = "origen_banking",
        name = "Origen Banco",
        description = "Banco: cuentas y saldos, libro de movimientos, entidades y préstamos",
        icon = "bank",
        category = "Economy",
        adminRoute = "export",
        resourceName = "origen_banking",
        color = "#850e49"
    },
    {
        id = "origen_pets",
        name = "Origen Mascotas",
        description = "Catálogo de razas, precios y puntos de compra de mascotas",
        icon = "paw",
        category = "Jobs",
        adminRoute = "export",
        resourceName = "origen_pets",
        color = "#c2153f"
    },
    {
        id = "origen_hunting",
        name = "Origen Caza",
        description = "Especies, zonas, precios y torneos de caza; registro de ventas y piezas para detectar abusos",
        icon = "crosshair",
        category = "Jobs",
        adminRoute = "export",
        resourceName = "origen_hunting",
        color = "#d81b55"
    },
    {
        id = "origen_customs",
        name = "Origen Taller",
        description = "Taller de tuneo: precios, clases, acceso, cámara y piezas bloqueadas; precios del mantenimiento y registro de tuneos",
        icon = "mechanic",
        category = "Vehicles",
        adminRoute = "export",
        resourceName = "origen_customs",
        color = "#d81b55"
    },
    {
        id = "origen_vehicleseats",
        name = "Origen Asientos",
        description = "Asientos de más en los vehículos: ir detrás, en el maletero o tumbado en el techo",
        icon = "car",
        category = "Vehicles",
        adminRoute = "export",
        resourceName = "origen_vehicleseats",
        color = "#d81b55"
    },
    {
        id = "origen_autoescuela",
        name = "Origen Autoescuela",
        description = "Gestión y creación de circuitos de examen de conducir (coche, moto, camión)",
        icon = "car",
        category = "Vehicles",
        adminRoute = "export",
        resourceName = "origen_autoescuela",
        color = "#d81b55"
    },
    {
        id = "origen_casino",
        name = "Origen Casino",
        description = "El casino: colocar mesas, máquinas y mostradores; reglas de los siete juegos, fichas, socios, topes y vigilancia",
        icon = "coin",
        category = "Economy",
        adminRoute = "export",
        resourceName = "origen_casino",
        color = "#d81b55"
    },
    {
        id = "origen_games",
        name = "Origen Juegos",
        description = "Minijuegos: escondite, patata caliente, rey de la colina, derbi e impostor. Zonas, ajustes y puntos del mapa",
        icon = "gamepad",
        category = "Core",
        adminRoute = "export",
        resourceName = "origen_games",
        color = "#d81b55"
    },
    {
        id = "origen_garages",
        name = "Origen Garajes",
        description = "Sistema de garajes y gestión de vehículos",
        icon = "garage",
        category = "Vehicles",
        adminRoute = "export",
        resourceName = "origen_garages",
        color = "#0891b2"
    },
    {
        id = "origen_admin",
        name = "Origen Admin",
        description = "Panel de administración principal del servidor",
        icon = "police",
        category = "Core",
        adminRoute = "export",
        resourceName = "origen_admin",
        color = "#850e49"
    },
    {
        id = "org_parking",
        name = "Origen Aparcamiento",
        description = "Aparcamiento automático y gestión de los vehículos aparcados",
        icon = "car-parking",
        category = "Vehicles",
        adminRoute = "export",
        -- El recurso se llama org_parking, no origen_parking: el panel lo
        -- buscaba con el nombre largo, no lo encontraba, y lo pintaba como
        -- parado y sin panel aunque llevara horas funcionando.
        resourceName = "org_parking",
        color = "#850e49"
    },
    -- {
    --     id = "origen_shops",
    --     name = "Origen Tiendas",
    --     description = "Sistema de tiendas con múltiples categorías y productos",
    --     icon = "shop",
    --     category = "Economy",
    --     adminRoute = "/admin",
    --     resourceName = "origen_shops",
    --     color = "#d97706"
    -- },
    {
        id = "origen_businesses",
        name = "Origen Negocios",
        description = "Sistema de negocios con gestión de empleados, finanzas e inventario",
        icon = "building-2",
        category = "Economy",
        adminRoute = "export",
        resourceName = "origen_businesses",
        color = "#850e49"
    },
    -- {
    --     id = "origen_drugs",
    --     name = "Origen Drogas",
    --     description = "Sistema de drogas con procesamiento y venta",
    --     icon = "drugs",
    --     category = "Criminal",
    --     adminRoute = "/admin",
    --     resourceName = "origen_drugs",
    --     color = "#16a34a"
    -- },
    -- {
    --     id = "origen_gangs",
    --     name = "Origen Pandillas",
    --     description = "Sistema de bandas con territorios y gestión de miembros",
    --     icon = "gang",
    --     category = "Criminal",
    --     adminRoute = "/admin",
    --     resourceName = "origen_gangs",
    --     color = "#dc2626"
    -- },
    {
        id = "origen_dealership",
        name = "Origen Concesionario",
        description = "Concesionario de vehículos: compra y venta",
        icon = "car",
        category = "Vehicles",
        adminRoute = "export",  -- Usar export en lugar de iframe
        resourceName = "origen_dealership",
        color = "#9333ea"
    },
    {
        id = "origen_gym",
        name = "Origen Gimnasio",
        description = "Gimnasios: crearlos, colocar los aparatos y ajustar cómo se pone el personaje en cada uno",
        icon = "dumbbell",
        category = "Core",
        adminRoute = "export",
        resourceName = "origen_gym",
        color = "#d81b55"
    },
    {
        id = "origen_tattoos",
        name = "Origen Tatuajes",
        description = "Tiendas de tatuajes: crearlas, mover la entrada, la camilla y el tatuador, y ver cómo queda la sesión",
        icon = "image-plus",
        category = "Core",
        adminRoute = "export",
        resourceName = "origen_tattoos",
        color = "#d81b55"
    },
    {
        id = "origen_bingo",
        name = "Origen Bingo",
        description = "Bingo: salas con su bombo, panel y taquilla, y cada cuánto se juega y cuánto se gana",
        icon = "coin",
        category = "Economy",
        adminRoute = "export",
        resourceName = "origen_bingo",
        color = "#d81b55"
    },
    {
        -- Vive en [exclusivonacion], pero marca_origen.cfg tambien lo arranca.
        id = "origen_vipsystem",
        name = "Origen VIP",
        description = "VIP y monedas: rangos, códigos, tienda, sorteos y saldos de los jugadores",
        icon = "coin",
        category = "Economy",
        adminRoute = "export",
        resourceName = "origen_vipsystem",
        color = "#d81b55"
    },
    {
        -- Segunda tarjeta de origen_vipsystem: su panel abierto en la pestaña «Tatuajes» (asignar los
        -- trajes exclusivos y regalar tatuajes de la tienda). Mismo permiso que «Origen VIP».
        id = "origen_vipsystem_tatuajes",
        name = "Origen Tatuajes · Asignar",
        description = "Tatuajes exclusivos: asignar un traje hecho por encargo a un jugador, retirarlo y regalar tatuajes de la tienda",
        icon = "image-plus",
        category = "Core",
        adminRoute = "export",
        resourceName = "origen_vipsystem",
        panel = "tatuajes",
        permiso = "origen_vipsystem",
        requiere = { "origen_tattoos", "origen_tatuajes" },
        color = "#d81b55"
    },
    {
        id = "origen_mision",
        name = "Origen Encargos",
        description = "Los encargos del Notario: dar uno a un jugador, quitárselo, reiniciar su libreta y mover al contacto",
        icon = "crosshair",
        category = "Criminal",
        adminRoute = "export",
        resourceName = "origen_mision",
        color = "#d81b55"
    },
    {
        id = "origen_zones",
        name = "Origen Zonas",
        description = "Trozos del mapa con reglas dentro: sin tráfico, límite de velocidad, sin armas, zona segura",
        icon = "map-pin",
        category = "Core",
        adminRoute = "export",
        resourceName = "origen_zones",
        color = "#d81b55"
    },
    {
        id = "origen_blackmarket",
        name = "Origen Mercado negro",
        description = "Mercado negro con armas, vehículos y objetos exclusivos",
        icon = "shop-lock",
        category = "Criminal",
        adminRoute = "export",
        resourceName = "origen_blackmarket",
        color = "#1f2937"
    },
    {
        id = "origen_fuel",
        name = "Origen Gasolina",
        description = "Combustible: gasolineras y existencias",
        icon = "gas-pump",
        category = "Economy",
        adminRoute = "export",
        resourceName = "origen_fuel",
        color = "#ff6b35"
    },
    {
        id = "origen_ilegal",
        name = "Origen Bandas",
        description = "Bandas: territorios, miembros y todo lo de cada banda",
        icon = "users-slash",
        category = "Criminal",
        adminRoute = "export",
        resourceName = "origen_ilegalv2",
        color = "#dc2626"
    },
    {
        id = "origen_carboosting",
        name = "Origen Robo de coches",
        description = "Robo de vehículos: contratos, entregas y clasificaciones",
        icon = "car-burst",
        category = "Criminal",
        adminRoute = "export",
        resourceName = "origen_carboosting",
        color = "#7c3aed"
    },
    {
        id = "origen_racing",
        name = "Origen Carreras",
        description = "Circuitos, carreras, equipos y estadísticas",
        icon = "flag-checkered",
        category = "Criminal",
        adminRoute = "export",
        resourceName = "origen_racing",
        color = "#f59e0b"
    },
    {
        id = "origen_gangwars",
        name = "Origen Guerra de bandas",
        description = "Guerra de bandas: salas de espera, batallas y clasificación",
        icon = "swords",
        category = "Criminal",
        adminRoute = "export",
        resourceName = "origen_gangwars",
        color = "#dc2626"
    },
    {
        id = "qbx_smallresources",
        name = "Origen Teletransportes",
        description = "Administración de teletransportes y ascensores en tiempo real",
        icon = "location-dot",
        category = "Core",
        adminRoute = "export",
        resourceName = "qbx_smallresources",
        color = "#0ea5e9"
    },
    {
        id = "origen_vehiclehandling",
        name = "Origen Conducción",
        description = "Velocidad y manejo de los vehículos por categorías",
        icon = "car-burst",
        category = "Vehicles",
        adminRoute = "export",
        resourceName = "origen_vehiclehandling",
        color = "#850e49"
    },
    {
        id = "origen_vehiclesounds",
        name = "Origen Sonidos",
        description = "Personalización del sonido de motor por modelo de vehículo para todo el servidor",
        icon = "volume-2",
        category = "Vehicles",
        adminRoute = "export",
        resourceName = "origen_vehiclesounds",
        color = "#374151"
    },
    {
        id = "origen_uploader",
        name = "Origen Subidas",
        description = "Herramienta de subida de imágenes",
        icon = "image-plus",
        category = "Core",
        adminRoute = "export",
        resourceName = "origen_uploader",
        color = "#850e49"
    },
    {
        id = "origen_propplacer",
        name = "Origen Objetos",
        description = "Colocar y editar los objetos del mapa en tiempo real",
        icon = "grid",
        category = "Core",
        adminRoute = "export",
        resourceName = "origen_propplacer",
        color = "#850e49"
    },
    {
        id = "origen_phone",
        name = "Origen Móvil",
        description = "Ajustes del teléfono: cobertura, tarifas, aplicaciones y quién puede usarlas",
        icon = "phone",
        category = "Core",
        adminRoute = "export",
        resourceName = "origen_phone",
        color = "#850e49"
    },
}

if GetConvar('origen:marca', 'origen') == 'nacion' then
    for i = #Config.Scripts, 1, -1 do
        local id = Config.Scripts[i].id
        -- origen_mision no se usa en Nacion. origen_pets SI: desde el 13/10 es el
        -- sistema de mascotas de los dos servidores (murderface-pets se retiro).
        if id == 'origen_mision' then table.remove(Config.Scripts, i) end
    end
end
