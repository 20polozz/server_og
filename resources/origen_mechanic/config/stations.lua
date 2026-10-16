Config.Stations = {
    --[[ Distancias que valida el SERVIDOR. `MaxDistance` es jugador contra la
         estacion; `VehicleDistance` es jugador contra el vehiculo del netId Y
         estacion contra ese mismo vehiculo: sin las tres, un cliente tocado
         repara un coche que no esta en la estacion. ]]
    MaxDistance = 6.0,
    VehicleDistance = 12.0,

    DurationTolerance = 0.85,
    TicketMaxMs = 120000,

    MarkerDistance = 18.0,
    PointDistance = 2.2,
    Key = 38,
    KeyLabel = 'E',

    Marker = {
        type = 25,
        scale = vector3(1.4, 1.4, 1.0),
        color = { r = 220, g = 221, b = 224, a = 120 },
        freeColor = { r = 216, g = 27, b = 85, a = 120 }
    },

    Anim = { dict = 'mini@repair', clip = 'fixing_a_player' },

    --[[ El sprite 402 es `radar_repair` y `OrigenMapa.Icono` lo traduce a la
         chincheta de taller. Se deja el numero y no la clave para que cambiar
         el dibujo en un sitio lo cambie en los cuarenta recursos. ]]
    Blip = {
        sprite = 402,
        publicCategory = 'public',
        emergencyCategory = 'emergencias'
    },

    --[[ CERRAR vs ENCARECER.

         El diseño (§9.2) lo dejo sin decidir y aqui se decide: por defecto se
         ENCARECE. Cerrar la estacion porque hay dos mecanicos conectados deja
         tirado al jugador que se quedo sin coche a las cinco de la mañana y no
         encuentra a ninguno de esos dos; encarecerla mantiene la salida abierta
         y hace que llamar al mecanico siga siendo lo sensato. `Mode = 'cerrar'`
         existe para poder probar la otra mitad sin tocar codigo.

         El umbral empieza en 2 y no en los 3 de t1ger porque Origen no tiene el
         aforo de mecanicos que asume ese script.

         El multiplicador es escalonado: mas mecanicos de servicio, mas cara la
         maquina, hasta el tope. Con 2 mecanicos de servicio el motor pasa de
         14.000 a 35.000, frente a los 10.200 del taller: a ese precio nadie usa
         la maquina teniendo a quien llamar, que es justo el efecto que se
         busca. ]]
    Gating = {
        Mode = 'encarecer',
        Threshold = 2,
        Multiplier = 2.5,
        PerMechanic = 0.5,
        MaxMultiplier = 4.0,
        --[[ La cuenta recorre a todos los conectados preguntando a
             `origen_businesses` uno por uno. No se puede hacer en cada pulsacion
             de tecla. ]]
        CacheMs = 15000,
        FallbackJob = 'mechanic'
    },

    --[[ Precios de arranque, referidos a la clase 2 (compactos). Encima se
         aplica el mismo `Mechanic.GetPriceMultiplier` que usa el taller, para
         que un super no salga barato aqui y caro alli.

         Los numeros de t1ger (§5.5 del analisis: 2.500 la revision completa,
         8.000 la puesta a punto) NO se copian: con los precios de pieza de
         `Config.Budget.Parts` un motor en el taller son 9.000 de pieza mas 1.200
         de mano de obra. A 2.500 la maquina hacia el trabajo del taller por una
         cuarta parte y el oficio se quedaba sin clientes.

         La referencia es el taller, clase 2:
           motor              9.000 + 1.200 =  10.200  →  maquina 14.000
           componentes (8)   30.200 + 9.600 =  39.800  →  maquina 48.000
           servicios (11)     6.550 + 3.850 =  10.400  →  maquina 13.000
           chapa (1 puerta)   3.600 +   900 =   4.500  →  maquina 12.000

         La maquina siempre sale mas cara, y ademas no trabaja a la carta: se
         paga el paquete entero aunque solo haya una pieza rota. Ese sobreprecio
         es lo que se cobra por no esperar a nadie a las cinco de la mañana.

         `body` esta puesto sobre el precio de recambio y queda pendiente de
         recalibrar cuando la Fase 5b cierre la facturacion de chapa.

         Orden = orden en el menu. ]]
    Tiers = {
        {
            id = 'engine',
            label = 'Reparación de motor',
            description = 'Deja el motor a punto y el coche otra vez en marcha.',
            icon = 'gauge-high',
            duration = 12000,
            price = 4200,
            effects = { engine = true }
        },
        {
            id = 'body',
            label = 'Chapa y ruedas',
            description = 'Endereza la carrocería, repone lunas y ruedas.',
            icon = 'car-side',
            duration = 15000,
            price = 3600,
            effects = { body = true }
        },
        {
            id = 'components',
            label = 'Revisión de componentes',
            description = 'Sustituye todas las piezas gastadas del vehículo.',
            icon = 'screwdriver-wrench',
            duration = 25000,
            price = 14000,
            --[[ Lleva `engine` pegado a proposito: poner el componente `motor` a
                 100 sin devolver la salud de motor NATIVA deja el coche
                 igualmente sin arrancar (ver client/stations.lua). ]]
            effects = { engine = true, components = true }
        },
        {
            id = 'services',
            label = 'Fluidos y filtros',
            description = 'Pone a cero todos los mantenimientos vencidos.',
            icon = 'oil-can',
            duration = 20000,
            price = 4000,
            effects = { services = true }
        },
        {
            id = 'full',
            label = 'Puesta a punto completa',
            description = 'Todo lo anterior de una sola pasada.',
            icon = 'wrench',
            duration = 40000,
            price = 21000,
            effects = { engine = true, body = true, components = true, services = true }
        }
    },

    --[[ `jobs = nil` es publica. Con `jobs` puesta solo entran esos oficios y
         `free = true` la deja gratis y fuera del gating: una ambulancia parada
         por un golpe no es un problema de economia. ]]
    Locations = {
        -- {
        --     id = 'centro',
        --     label = 'Estación de reparación · Centro',
        --     coords = vector3(548.18, -206.17, 54.15)
        -- },
        -- {
        --     id = 'sandy',
        --     label = 'Estación de reparación · Sandy Shores',
        --     coords = vector3(1174.76, 2640.87, 37.75)
        -- },
        -- {
        --     id = 'paleto',
        --     label = 'Estación de reparación · Paleto Bay',
        --     coords = vector3(-378.55, 6045.36, 31.50)
        -- },
        -- {
        --     id = 'comisaria',
        --     label = 'Taller de comisaría',
        --     coords = vector3(433.62, -1018.28, 28.84),
        --     jobs = { police = true },
        --     free = true
        -- },
        -- {
        --     id = 'hospital',
        --     label = 'Taller del hospital',
        --     coords = vector3(344.39, -553.79, 28.74),
        --     jobs = { ambulance = true },
        --     free = true
        -- }
    }
}

local stationsById = {}
local tiersById = {}

for i = 1, #Config.Stations.Locations do
    local station = Config.Stations.Locations[i]
    stationsById[station.id] = station
end

for i = 1, #Config.Stations.Tiers do
    local tier = Config.Stations.Tiers[i]
    tiersById[tier.id] = tier
end

function Mechanic.GetStation(id)
    if type(id) ~= 'string' then return nil end

    return stationsById[id]
end

function Mechanic.GetStationTier(id)
    if type(id) ~= 'string' then return nil end

    return tiersById[id]
end

--- ¿Este oficio puede usar esta estación? Sin `jobs`, cualquiera.
function Mechanic.StationAllowsJob(station, job)
    if type(station) ~= 'table' or type(station.jobs) ~= 'table' then return true end

    return type(job) == 'string' and station.jobs[job] == true
end

--[[ El escalon de precio que toca con N mecanicos de servicio. Vive en shared
     para que el mismo numero se pueda enseñar en el menu y cobrar en el
     servidor, pero quien decide es siempre el servidor. ]]
function Mechanic.GetStationMultiplier(mechanics)
    local gating = Config.Stations.Gating
    local count = math.floor(tonumber(mechanics) or 0)

    if count < gating.Threshold then return 1.0 end

    local extra = (count - gating.Threshold) * gating.PerMechanic
    return math.min(gating.Multiplier + extra, gating.MaxMultiplier)
end

--[[ El multiplicador de clase es el MISMO que aplica el taller
     (`Mechanic.GetPriceMultiplier`). Sin el, la maquina cobraba lo mismo por un
     compacto que por un super mientras el taller cobraba 2,4 veces mas por el
     super: al dueño del super le salia a cuenta la maquina SIEMPRE, que es justo
     lo contrario de lo que busca el auto-servicio. ]]
function Mechanic.GetStationPrice(tier, multiplier, class)
    if type(tier) ~= 'table' then return 0 end

    local byClass = Mechanic.GetPriceMultiplier(class)
    return math.floor(tier.price * (tonumber(multiplier) or 1.0) * byClass + 0.5)
end
