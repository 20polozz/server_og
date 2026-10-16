local function BuildComponentServices()
    for _, component in pairs(Config.Components) do
        component.services = {}
    end

    for serviceName, service in pairs(Config.Services) do
        for i = 1, #service.components do
            local componentName = service.components[i]
            local component = Config.Components[componentName]
            if component then
                component.services[#component.services + 1] = serviceName
            else
                print(('[origen_mechanic] El servicio "%s" apunta al componente inexistente "%s"'):format(serviceName, componentName))
            end
        end
    end

    for _, component in pairs(Config.Components) do
        table.sort(component.services)
    end
end

BuildComponentServices()

--[[ No se pasa a mayusculas a proposito: `origen_garages` y `qbx_vehicles`
     guardan la matricula tal cual la devuelve el juego, y normalizar de mas aqui
     dejaria filas huerfanas al cruzar con `player_vehicles`. ]]
function Mechanic.NormalizePlate(plate)
    if type(plate) ~= 'string' then return nil end

    local clean = plate:gsub('%s+', '')
    if clean == '' or #clean > 15 then return nil end

    return clean
end

function Mechanic.IsValidClass(class)
    return type(class) == 'number' and class >= 0 and class <= 22 and class % 1 == 0
end

function Mechanic.IsTrackableClass(class)
    if not Mechanic.IsValidClass(class) then return false end
    return not Config.UntrackableClasses[class]
end

--[[ `joaat` y `GetEntityModel` no coinciden en el signo: uno devuelve el hash sin
     signo y el otro puede devolverlo negativo. Sin normalizar, la lista negra no
     acierta nunca. ]]
local function NormalizeHash(value)
    local hash = tonumber(value)
    if not hash then return nil end

    return hash < 0 and (hash + 0x100000000) or hash
end

function Mechanic.IsBlacklistedModel(modelHash)
    local hash = NormalizeHash(modelHash)
    if not hash then return false end

    for i = 1, #Config.BlacklistedModels do
        if NormalizeHash(joaat(Config.BlacklistedModels[i])) == hash then return true end
    end

    return false
end

function Mechanic.GetIntervalMultiplier(class)
    local multiplier = Config.IntervalMultipliers[class] or 1.0
    return math.max(Config.MultiplierClamp.min, math.min(multiplier, Config.MultiplierClamp.max))
end

--- Intervalo efectivo en km de un servicio para una clase de vehículo.
function Mechanic.GetEffectiveInterval(serviceName, class)
    local service = Config.Services[serviceName]
    if not service then return nil end

    return math.floor(service.interval * Mechanic.GetIntervalMultiplier(class))
end

function Mechanic.GetComponentCondition(health)
    local value = tonumber(health) or 0
    local thresholds = Config.ComponentThresholds

    if value >= thresholds.optimal then return Mechanic.ComponentCondition.OPTIMAL end
    if value >= thresholds.worn then return Mechanic.ComponentCondition.WORN end
    if value >= thresholds.critical then return Mechanic.ComponentCondition.CRITICAL end

    return Mechanic.ComponentCondition.FAILED
end

function Mechanic.GetServiceCondition(remaining, interval)
    if remaining < 0 then return Mechanic.ServiceCondition.OVERDUE end
    if interval <= 0 then return Mechanic.ServiceCondition.OK end
    if (remaining / interval) < Config.ServiceThresholds.okRatio then return Mechanic.ServiceCondition.DUE end

    return Mechanic.ServiceCondition.OK
end

function Mechanic.ClampHealth(value)
    local health = tonumber(value)
    if not health or health ~= health then return 0.0 end

    return math.max(0.0, math.min(100.0, health + 0.0))
end

function Mechanic.ClampMileage(value)
    local mileage = tonumber(value)
    if not mileage or mileage ~= mileage then return 0.0 end

    return math.max(0.0, math.min(99999999.0, mileage + 0.0))
end

function Mechanic.Round(value, decimals)
    local factor = 10 ^ (decimals or 2)
    return math.floor((tonumber(value) or 0) * factor + 0.5) / factor
end

--- Componentes por defecto: todos a 100.
function Mechanic.DefaultComponents()
    local components = {}
    for name in pairs(Config.Components) do
        components[name] = 100.0
    end

    return components
end

--- Servicios por defecto: 0 km desde el último cambio.
function Mechanic.DefaultServices()
    local services = {}
    for name in pairs(Config.Services) do
        services[name] = 0.0
    end

    return services
end

--[[ Borra las claves que ya no existen en la config y añade las nuevas con su
     valor por defecto. Sin esto, renombrar una pieza deja basura en el JSON y
     los vehiculos viejos no ven la pieza nueva hasta que alguien toque la fila. ]]
function Mechanic.ValidateComponents(stored)
    local components = {}
    local source = type(stored) == 'table' and stored or {}

    for name in pairs(Config.Components) do
        local value = source[name]
        components[name] = value ~= nil and Mechanic.ClampHealth(value) or 100.0
    end

    return components
end

function Mechanic.ValidateServices(stored)
    local services = {}
    local source = type(stored) == 'table' and stored or {}

    for name in pairs(Config.Services) do
        local value = tonumber(source[name])
        services[name] = (value and value == value) and math.max(0.0, value + 0.0) or 0.0
    end

    return services
end

--- Estado aleatorio para un vehículo que nunca se registró.
function Mechanic.BuildRandomState(class)
    local vehicleClass = Mechanic.IsValidClass(class) and class or Config.DefaultVehicleClass
    local random = Config.RandomState

    local mileage = math.random(random.MileageRange[1], random.MileageRange[2]) + 0.0

    local services = {}
    for name in pairs(Config.Services) do
        local interval = Mechanic.GetEffectiveInterval(name, vehicleClass) or 0
        local used = math.random() * (random.ServiceUsedRange[2] - random.ServiceUsedRange[1]) + random.ServiceUsedRange[1]
        services[name] = math.floor(interval * used) + 0.0
    end

    local minHealth = math.max(0, math.min(100, random.ComponentHealthRange[1]))
    local maxHealth = math.max(minHealth, math.min(100, random.ComponentHealthRange[2]))

    local components = {}
    for name in pairs(Config.Components) do
        components[name] = math.random(minHealth, maxHealth) + 0.0
    end

    return {
        mileage = mileage,
        class = vehicleClass,
        components = components,
        services = services
    }
end
