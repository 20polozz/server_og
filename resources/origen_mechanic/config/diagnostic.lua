Config.Diagnostic = {
    item = 'herramienta_diagnostico',
    book = 'libro_servicio',

    --[[ Distancia que valida el SERVIDOR entre el jugador y el vehiculo del
         netId, igual que en Config.Repair. ]]
    MaxDistance = 6.0,

    HoodDistance = 2.4,

    duration = 4000,
    bookDuration = 2500,

    --[[ Mismo margen que la sustitucion de piezas: el servidor exige que haya
         pasado este porcentaje de la progressbar antes de abrir la NUI. ]]
    DurationTolerance = 0.85,
    TicketMaxMs = 60000,

    HistoryLimit = 25,

    --[[ Tope de lineas de un presupuesto. Con la chapa dentro ya no bastan 25:
         a las 23 piezas mecanicas se les suman hasta 18 lineas de carroceria
         (4 puertas, 6 lunas, 6 ruedas, capo y porton) y "Marcar lo urgente"
         puede llegar a marcarlas todas. El tope solo corta una peticion
         inflada a mano. ]]
    MaxBudgetLines = 45,

    Anim = { dict = 'mini@repair', clip = 'fixing_a_player' },
    BookAnim = { dict = 'amb@world_human_clipboard@male@idle_a', clip = 'idle_c' },

    --[[ El nivel de suciedad de GTA va de 0 a 15; se muestra en porcentaje. ]]
    MaxDirtLevel = 15.0,

    --[[ `GetVehicleEngineTemperature` es la UNICA lectura del resumen que no
         existe en el servidor, asi que llega del cliente. Se clampea aqui y no
         entra en ningun calculo: es un indicador, no un precio. ]]
    MaxTemperature = 150.0
}

--[[ Precio de referencia de cada pieza. Es el COSTE de la pieza, no lo que
     acaba pagando el cliente: la mano de obra la pone el taller y en Fase 5
     sustituye a la tarifa base de abajo. ]]
Config.Budget = {
    Labor = {
        component = 450,
        service = 140,
        body = 350
    },

    --[[ Multiplicador de precio por clase de vehiculo. NO es el inverso de
         Config.IntervalMultipliers: alli decide cada cuanto toca el servicio y
         aqui cuanto cuesta la pieza. Mantenerlos separados evita que tocar el
         ritmo de mantenimiento mueva la economia sin querer. ]]
    ClassMultipliers = {
        [0] = 0.8,
        [1] = 0.9,
        [2] = 1.0,
        [3] = 1.0,
        [4] = 1.2,
        [5] = 1.6,
        [6] = 1.5,
        [7] = 2.4,
        [8] = 0.9,
        [9] = 1.3,
        [10] = 1.8,
        [11] = 1.4,
        [12] = 1.5,
        [17] = 1.4,
        [18] = 1.2,
        [19] = 2.0,
        [20] = 2.2,
        [22] = 1.6
    },

    MultiplierClamp = { min = 0.5, max = 4.0 },

    --[[ LA ECONOMIA DEL TALLER.

         El taller COMPRA la pieza al proveedor (`origen_businesses`,
         Config.Taller.Supplier, editable con /adminproveedor) y se la VENDE al
         cliente dentro del presupuesto. Si el precio de venta baja del coste,
         el taller pierde dinero en cada reparacion: paso de verdad el 18/09,
         con el motor a 300 y el aceite a 50 puestos desde el panel.

         Por eso los precios de `Parts` ya no van solos: son la lista de
         partida, pero por debajo hay un SUELO que sale del coste real. Se
         aplica en el servidor, que es quien puede preguntarle el coste al
         proveedor, y tambien al guardar desde el panel.

           margen.minimo   el suelo: coste x esto. Por debajo no se vende.
           margen.<tipo>   lo que se recomienda cobrar (lo que trae `Parts`).

         Con 1.35 de suelo, un neumatico que le cuesta 1.440 al taller no se
         puede presupuestar por menos de 1.944, y la mano de obra va encima. ]]
    Margen = {
        minimo = 1.35,
        component = 1.6,
        service = 1.7,
        body = 1.6
    },

    --[[ Lo minimo que se cobra de mano de obra, aunque el panel lo baje. La
         mano de obra es lo que hace que salga a cuenta atender a un cliente:
         a 60 el servicio, el mecanico trabaja gratis. ]]
    LaborMin = {
        component = 250,
        service = 80,
        body = 200
    },

    Parts = {
        component = {
            motor = 2400,
            transmision = 1900,
            frenos = 610,
            refrigeracion = 690,
            inyeccion = 640,
            direccion = 550,
            alternador = 480,
            suspension = 860,
            motor_electrico = 2900,
            bateria_ev = 3500
        },
        service = {
            aceite = 110,
            filtro_aire = 85,
            pastillas = 220,
            filtro_combustible = 95,
            bujias = 135,
            liquido_frenos = 95,
            anticongelante = 95,
            correa = 250,
            liquido_direccion = 95,
            refrigerante_bateria = 190,
            liquido_transmision = 130,
            cableado_at = 270,
            neumaticos = 390
        },

        --[[ La chapa se tarifa por GRUPO y no por (grupo, indice): una puerta
             delantera y una trasera son la misma pieza de recambio. Lo que
             distingue las lineas de una orden es la clave compuesta, no el
             precio.

             Estos numeros NO son los pesos de `origen_inventory` (18000, 14000,
             12000, 9000): eso es lo que pesa la pieza en la mochila. Se mantiene
             su proporcion, escalada a la tabla de arriba, porque una puerta que
             costara el doble que un motor rompe la economia del taller. ]]
        body = {
            puerta = 960,
            capo = 740,
            porton = 740,
            rueda = 610,
            luna = 480
        }
    }
}

local function ValidateBudgetPrices()
    local function check(map, config, kind)
        for part in pairs(config) do
            if not map[part] then
                print(('[origen_mechanic] La pieza "%s" (%s) no tiene precio en Config.Budget.Parts'):format(part, kind))
            end
        end

        for part in pairs(map) do
            if not config[part] then
                print(('[origen_mechanic] Config.Budget.Parts declara la pieza inexistente "%s" (%s)'):format(part, kind))
            end
        end
    end

    check(Config.Budget.Parts.component, Config.Components, Mechanic.PartKind.COMPONENT)
    check(Config.Budget.Parts.service, Config.Services, Mechanic.PartKind.SERVICE)
end

ValidateBudgetPrices()

function Mechanic.GetPriceMultiplier(class)
    local multiplier = Config.Budget.ClassMultipliers[class] or 1.0
    local clamp = Config.Budget.MultiplierClamp

    return math.max(clamp.min, math.min(multiplier, clamp.max))
end

--- Precio de la pieza y de la mano de obra para una clase de vehículo.
function Mechanic.GetPartPrice(part, kind, class)
    local prices = Config.Budget.Parts[kind]
    local key = part

    if kind == Mechanic.PartKind.BODY then
        key = Mechanic.ParseBodyLineKey(part)
        if not key then return nil end
    end

    local base = prices and prices[key]
    if not base then return nil end

    local multiplier = Mechanic.GetPriceMultiplier(class)
    local labor = math.max(Config.Budget.Labor[kind] or 0, Config.Budget.LaborMin[kind] or 0)

    --[[ El suelo va DESPUES del multiplicador: la clase abarata el precio pero
         no lo que le cuesta la pieza al taller, y un compacto con multiplicador
         bajo volvia a quedar por debajo del coste. ]]
    return Mechanic.ConSuelo(part, kind, math.floor(base * multiplier)), math.floor(labor * multiplier)
end

--[[ El suelo de una pieza: nunca por debajo del coste del proveedor mas el
     margen minimo. Solo el SERVIDOR sabe ese coste (se lo pregunta a
     `origen_businesses`), asi que en el cliente esto no hace nada y el precio
     que se ensena es el de la lista; el que se cobra lo calcula el servidor.
     `Mechanic.CosteDePieza` la pone server/precios_admin.lua. ]]
function Mechanic.ConSuelo(part, kind, base)
    if not Mechanic.CosteDePieza then return base end

    local coste = Mechanic.CosteDePieza(part, kind)
    if not coste or coste <= 0 then return base end

    local minimo = math.floor(coste * (Config.Budget.Margen.minimo or 1.35) + 0.5)
    return math.max(base, minimo)
end

--- Lo que se recomienda cobrar por una pieza que cuesta `coste`.
function Mechanic.PrecioRecomendado(kind, coste)
    local margen = Config.Budget.Margen[kind] or Config.Budget.Margen.minimo or 1.5
    return math.floor((tonumber(coste) or 0) * margen + 0.5)
end

--[[ Qué piezas tiene sentido presupuestar: un componente que no esta perfecto
     o un servicio con kilometros encima. Lo decide el servidor porque el
     precio no se cobra por una pieza que no hacia falta. ]]
function Mechanic.NeedsIntervention(state, part, kind)
    if kind == Mechanic.PartKind.COMPONENT then
        return (state.components[part] or 0) < 100
    end

    --[[ La chapa no se mide por salud ni por kilometros: o esta en el parte que
         escribio una inspeccion con ticket, o no hay nada que cobrar. ]]
    if kind == Mechanic.PartKind.BODY then
        return Mechanic.GetBodyDamageStatus(state, part) ~= nil
    end

    return (state.services[part] or 0) > 0
end

--- Estado (`damaged` / `missing`) de una linea de chapa en un vehiculo, o `nil`.
function Mechanic.GetBodyDamageStatus(state, part)
    local group, index = Mechanic.ParseBodyLineKey(part)
    if not group then return nil end

    local damage = type(state) == 'table' and state.bodyDamage or nil
    if type(damage) ~= 'table' or type(damage.parts) ~= 'table' then return nil end

    local entries = damage.parts[group]
    if type(entries) ~= 'table' then return nil end

    return entries[tostring(index)]
end
