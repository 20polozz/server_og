-- 5400 -> «5.400», con el punto de miles del panel (utils/formato.ts).
local function Miles(n)
    local s = tostring(math.floor(n + 0.5))
    return (s:reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', ''))
end

local CONDITION_LABELS = {
    [Mechanic.ComponentCondition.OPTIMAL] = 'Óptimo',
    [Mechanic.ComponentCondition.WORN] = 'Desgastado',
    [Mechanic.ComponentCondition.CRITICAL] = 'Crítico',
    [Mechanic.ComponentCondition.FAILED] = 'Averiado',
    [Mechanic.ServiceCondition.OK] = 'Al día',
    [Mechanic.ServiceCondition.DUE] = 'Toca pronto',
    [Mechanic.ServiceCondition.OVERDUE] = 'Vencido'
}

local CONDITION_TONES = {
    [Mechanic.ComponentCondition.OPTIMAL] = 'ok',
    [Mechanic.ComponentCondition.WORN] = 'warn',
    [Mechanic.ComponentCondition.CRITICAL] = 'bad',
    [Mechanic.ComponentCondition.FAILED] = 'bad',
    [Mechanic.ServiceCondition.OK] = 'ok',
    [Mechanic.ServiceCondition.DUE] = 'warn',
    [Mechanic.ServiceCondition.OVERDUE] = 'bad'
}

--- Estado replicado por el servidor en el statebag de la entidad.
local function GetLocalVehicleHealth(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end

    local health = Entity(vehicle).state[Mechanic.StateKey]
    return type(health) == 'table' and health or nil
end
exports('GetLocalVehicleHealth', GetLocalVehicleHealth)

local function GetLocalComponentHealth(vehicle, component)
    local health = GetLocalVehicleHealth(vehicle)
    if not health or type(health.components) ~= 'table' then return nil end

    return health.components[component]
end
exports('GetLocalComponentHealth', GetLocalComponentHealth)

local function GetLocalServiceRemaining(vehicle, service)
    local health = GetLocalVehicleHealth(vehicle)
    if not health or type(health.services) ~= 'table' then return nil end

    local since = health.services[service]
    if since == nil then return nil end

    local interval = Mechanic.GetEffectiveInterval(service, health.class)
    if not interval then return nil end

    return interval - since
end
exports('GetLocalServiceRemaining', GetLocalServiceRemaining)

local function GetLocalMileage(vehicle)
    local health = GetLocalVehicleHealth(vehicle)
    return health and health.mileage or nil
end
exports('GetLocalMileage', GetLocalMileage)

lib.callback.register('origen_mechanic:cb:resolveTargetVehicle', function()
    local vehicle = cache.vehicle

    if not vehicle or not DoesEntityExist(vehicle) then
        vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 8.0, true)
    end

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    if not NetworkGetEntityIsNetworked(vehicle) then return nil end

    return {
        netId = VehToNet(vehicle),
        class = GetVehicleClass(vehicle),
        model = GetEntityModel(vehicle)
    }
end)

RegisterNetEvent('origen_mechanic:client:showDiagnostic', function(detail)
    if type(detail) ~= 'table' then return end

    local componentes = {}

    for i = 1, #detail.components do
        local component = detail.components[i]

        componentes[#componentes + 1] = {
            titulo = component.label,
            detalle = CONDITION_LABELS[component.condition] or component.condition,
            valor = ('%.1f%%'):format(component.health),
            tono = CONDITION_TONES[component.condition] or 'neutro'
        }
    end

    local servicios = {}

    for i = 1, #detail.services do
        local service = detail.services[i]

        servicios[#servicios + 1] = {
            titulo = service.label,
            detalle = CONDITION_LABELS[service.condition] or service.condition,
            -- Vencido: «pasado 400 km», como en el panel del taller (FilaMarcable);
            -- antes salia «-400 / 5000 km».
            valor = service.remaining < 0
                and ('pasado %s km'):format(Miles(math.abs(service.remaining)))
                or ('%s / %s km'):format(Miles(service.remaining), Miles(service.interval)),
            tono = CONDITION_TONES[service.condition] or 'neutro'
        }
    end

    MecRiel.Abrir({
        marca = 'lucide:wrench',
        kicker = MecMarcaTaller,
        titulo = 'Estado mecánico',
        renglon = ('Matrícula %s · %s km · clase %d'):format(detail.plate or '-', Miles(detail.mileage or 0), detail.class or 0),
        rotulo = MecMarcaTaller,
        grupos = {
            {
                id = 'componentes',
                titulo = 'Componentes',
                icono = 'lucide:cog',
                vacio = 'Sin componentes',
                filas = componentes
            },
            {
                id = 'servicios',
                titulo = 'Servicios',
                icono = 'lucide:calendar-clock',
                vacio = 'Sin servicios',
                filas = servicios
            }
        }
    })
end)

--[[ /estadocoche: el conductor ve el desgaste de su coche sin ir al taller.
     Solo lee el statebag que el servidor ya replica a este cliente, asi que no
     hay nada que validar ni ningun evento nuevo: enseña lo que el coche ya sabe. ]]
RegisterCommand('estadocoche', function()
    local vehicle = cache.vehicle
    if not vehicle or cache.seat ~= -1 then
        return lib.notify({ type = 'error', description = 'Tienes que ir al volante del coche' })
    end

    local health = GetLocalVehicleHealth(vehicle)
    if not health or type(health.components) ~= 'table' then
        return lib.notify({ type = 'error', description = 'Este vehículo no tiene registro mecánico' })
    end

    local componentes = {}
    for name, value in pairs(health.components) do
        local def = Config.Components[name]
        if def then
            local condition = Mechanic.GetComponentCondition(value)
            componentes[#componentes + 1] = {
                orden = def.order,
                titulo = def.label,
                detalle = CONDITION_LABELS[condition] or condition,
                valor = ('%d%%'):format(math.floor(value + 0.5)),
                tono = CONDITION_TONES[condition] or 'neutro'
            }
        end
    end
    table.sort(componentes, function(a, b) return a.orden < b.orden end)

    local servicios = {}
    for name, since in pairs(health.services or {}) do
        local def = Config.Services[name]
        local interval = def and Mechanic.GetEffectiveInterval(name, health.class)
        if interval and interval > 0 then
            local remaining = interval - since
            local condition = Mechanic.GetServiceCondition(remaining, interval)
            servicios[#servicios + 1] = {
                orden = def.order,
                titulo = def.label,
                detalle = CONDITION_LABELS[condition] or condition,
                valor = remaining > 0 and ('quedan %d km'):format(math.floor(remaining)) or 'vencido',
                tono = CONDITION_TONES[condition] or 'neutro'
            }
        end
    end
    table.sort(servicios, function(a, b) return a.orden < b.orden end)

    MecRiel.Abrir({
        marca = 'lucide:gauge',
        kicker = 'Mi coche',
        titulo = 'Desgaste del vehículo',
        renglon = ('Matrícula %s · %s km'):format(health.plate or '-', Miles(health.mileage or 0)),
        rotulo = MecMarcaTaller,
        grupos = {
            { id = 'componentes', titulo = 'Piezas', icono = 'lucide:cog', vacio = 'Sin piezas', filas = componentes },
            { id = 'servicios', titulo = 'Mantenimiento', icono = 'lucide:calendar-clock', vacio = 'Sin mantenimiento', filas = servicios }
        }
    })
end, false)
TriggerEvent('chat:addSuggestion', '/estadocoche', 'Ver el desgaste de las piezas de tu coche')

--[[ `invBusy` es la marca que ya usa el resto del servidor —ox_lib la pone sola
     en cada progressBar—. Solo se limpia la que puso este recurso: pisar la de
     otro dejaria sus avisos sueltos en mitad de su propia accion. ]]
CreateThread(function()
    local propia = false

    while true do
        Wait(200)

        local ocupado = Mechanic.EstaOcupado()

        if ocupado and not propia then
            LocalPlayer.state:set('invBusy', true, false)
            propia = true
        elseif not ocupado and propia then
            LocalPlayer.state:set('invBusy', false, false)
            propia = false
        end
    end
end)
