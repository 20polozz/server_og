Config.Repair = {
    --[[ Distancia que valida el SERVIDOR entre el jugador y el vehiculo del
         netId. Es la que impide reparar un coche que no se tiene delante. ]]
    MaxDistance = 6.0,

    TargetDistance = 4.0,
    WheelDistance = 1.8,
    HoodDistance = 2.4,

    --[[ Margen de tolerancia sobre la duracion declarada: el servidor exige que
         haya pasado al menos este porcentaje del tiempo antes de aceptar el
         final. Sin esto un cliente modificado repara instantaneamente. ]]
    DurationTolerance = 0.85,
    TicketMaxMs = 180000,

    --[[ EL MINIJUEGO de cada trabajo. Son los de `origen_minijuegos`, los
         mismos que usan los robos: `juego` es su clave, `dificultad` una de
         easy|medium|hard|extreme y `titulo` el rotulo del panel.

         `skillCheck` e `inputs` se quedan de respaldo: si `origen_minijuegos`
         no esta arrancado se vuelve al circulo de ox_lib y el taller sigue
         funcionando. ]]
    Minijuegos = {
        component = { juego = 'taladro', dificultad = 'medium', titulo = 'Desmontar y montar la pieza' },
        service = { juego = 'taladro', dificultad = 'easy', titulo = 'Aflojar y apretar' },
        patch = { juego = 'corte', dificultad = 'easy', titulo = 'Colocar el parche' }
    },

    --[[ Piezas que piden otro juego: lo electrico no se taladra, se puentea.
         Vale una clave suelta ('circuito') o la tabla entera. ]]
    MinijuegoPorPieza = {
        alternador = { juego = 'circuito', dificultad = 'easy', titulo = 'Alternador: puentear el circuito' },
        inyeccion = { juego = 'senal', dificultad = 'medium', titulo = 'Inyeccion: calibrar la señal' },
        motor_electrico = { juego = 'circuito', dificultad = 'medium', titulo = 'Motor electrico: puentear el circuito' },
        bateria_ev = { juego = 'circuito', dificultad = 'medium', titulo = 'Bateria: puentear el circuito' },
        refrigerante_bateria = { juego = 'circuito', dificultad = 'easy', titulo = 'Refrigeracion de la bateria' },
        cableado_at = { juego = 'circuito', dificultad = 'easy', titulo = 'Cableado: puentear el circuito' }
    },

    Component = {
        duration = 9000,
        skillCheck = { 'easy', 'easy', 'medium' },
        inputs = { 'w', 'a', 's', 'd' }
    },

    Service = {
        duration = 5000,
        skillCheck = { 'easy', 'easy' },
        inputs = { 'w', 'a', 's', 'd' }
    },

    Patch = {
        item = 'kit_parche',
        duration = 7000,
        skillCheck = { 'medium' },
        inputs = { 'w', 'a', 's', 'd' },
        --[[ No es una reparacion: deja el componente en Critico, lo justo para
             llegar al taller por su propio pie. ]]
        componentHealth = 5.0,
        serviceRemainingKm = 10.0
    },

    --[[ `vehiclehandler` (client.lua:32-56) pone SetVehicleUndriveable(true) en
         cuanto la salud de motor NATIVA llega a 0 y nunca lo deshace. Nuestra
         salud de componente es otra cosa, asi que sin tocar tambien la nativa el
         parche "funcionaria" y el coche seguiria sin arrancar. Se deja por
         debajo de 500 a proposito: vehiclehandler recorta el par por debajo de
         ese valor y ese es justo el tacto de "llega al taller como puedas". ]]
    EngineHealth = {
        patch = 200.0,
        replacement = 1000.0
    },

    --- Componentes que, al sustituirse, devuelven la salud de motor nativa.
    EngineParts = {
        motor = true,
        motor_electrico = true
    },

    --[[ Estas se cambian en la rueda; el resto, en el capo. ]]
    WheelParts = {
        frenos = true,
        pastillas = true,
        neumaticos = true
    },

    Anim = {
        Hood = { dict = 'mini@repair', clip = 'fixing_a_player' },
        Wheel = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
        CarryHand = { dict = 'anim@heists@humane_labs@finale@keycards', clip = 'ped_a_enter_loop' },
        CarryBox = { dict = 'anim@heists@box_carry@', clip = 'idle' }
    },

    --[[ 60309 es la mano derecha y 28422 la caja a dos manos. El hueso decide la
         animacion de acarreo, no al reves. ]]
    Bone = {
        HAND = 60309,
        BOX = 28422
    },

    FallbackProp = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },

    Props = {
        component = {
            motor = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            transmision = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            refrigeracion = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            suspension = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            motor_electrico = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            bateria_ev = { model = 'prop_car_battery_01', pos = vector3(-0.02, 0.15, -0.22), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            frenos = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            inyeccion = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            direccion = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            alternador = { model = 'prop_car_battery_01', pos = vector3(-0.02, 0.15, -0.22), rot = vector3(0.0, 5.0, 0.0), bone = 28422 }
        },
        service = {
            aceite = { model = 'prop_oilcan_02a', pos = vector3(-0.02, 0.18, -0.28), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            liquido_frenos = { model = 'prop_oilcan_02a', pos = vector3(-0.02, 0.18, -0.28), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            anticongelante = { model = 'prop_oilcan_02a', pos = vector3(-0.02, 0.18, -0.28), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            liquido_direccion = { model = 'prop_oilcan_02a', pos = vector3(-0.02, 0.18, -0.28), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            liquido_transmision = { model = 'prop_oilcan_02a', pos = vector3(-0.02, 0.18, -0.28), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            refrigerante_bateria = { model = 'prop_oilcan_02a', pos = vector3(-0.02, 0.18, -0.28), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            filtro_aire = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            filtro_combustible = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            bujias = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            pastillas = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            correa = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            cableado_at = { model = 'prop_cs_cardbox_01', pos = vector3(-0.02, 0.15, -0.24), rot = vector3(0.0, 5.0, 0.0), bone = 28422 },
            neumaticos = { model = 'prop_wheel_tyre', pos = vector3(0.0, 0.24, -0.13), rot = vector3(0.0, 0.0, 0.0), bone = 28422 }
        }
    },

    --[[ Receta de materiales de cada pieza. Lo que vuelve al sustituir se escala
         por la condicion con la que salio: `floor(cantidad * condicion / 100)`.
         Cambiar la pieza antes de que reviente es lo que compensa. ]]
    Recipes = {
        component = {
            motor = { chatarra_metal = 8, chatarra_cobre = 3, chatarra_plastico = 2 },
            transmision = { chatarra_metal = 6, chatarra_cobre = 2 },
            frenos = { chatarra_metal = 4, chatarra_goma = 2 },
            refrigeracion = { chatarra_metal = 4, chatarra_plastico = 2, chatarra_goma = 1 },
            inyeccion = { chatarra_metal = 3, chatarra_plastico = 2, chatarra_cobre = 1 },
            direccion = { chatarra_metal = 4, chatarra_goma = 1 },
            alternador = { chatarra_cobre = 5, chatarra_metal = 3 },
            suspension = { chatarra_metal = 6, chatarra_goma = 2 },
            motor_electrico = { chatarra_cobre = 8, chatarra_metal = 4 },
            bateria_ev = { chatarra_cobre = 6, chatarra_plastico = 4, chatarra_metal = 3 }
        },
        service = {
            aceite = { chatarra_plastico = 1 },
            filtro_aire = { chatarra_plastico = 1 },
            pastillas = { chatarra_metal = 2 },
            filtro_combustible = { chatarra_plastico = 1 },
            bujias = { chatarra_metal = 1, chatarra_cobre = 1 },
            liquido_frenos = { chatarra_plastico = 1 },
            anticongelante = { chatarra_plastico = 1 },
            correa = { chatarra_goma = 2 },
            liquido_direccion = { chatarra_plastico = 1 },
            refrigerante_bateria = { chatarra_plastico = 1 },
            liquido_transmision = { chatarra_plastico = 1 },
            cableado_at = { chatarra_cobre = 3 },
            neumaticos = { chatarra_goma = 4 }
        }
    },

    --[[ Lo que cada kit de `vehiclehandler` hace con el estado de este recurso.
         `vehiclehandler` solo conoce la salud nativa de GTA, asi que sin esta
         tabla el kit deja el coche impecable y el componente averiado sigue
         bloqueando el motor. ]]
    Kits = {
        --[[ El kit basico NO resucita un componente averiado: para eso ya existe
             el `kit_parche`, que lo deja al 5% para llegar al taller cojo. Si el
             basico lo arreglara del todo, el mecanico se queda sin trabajo. ]]
        basic = {
            components = false,
            services = false,
            body = false,
            history = false,
            label = 'Kit de reparación'
        },

        advanced = {
            components = true,
            --[[ Un servicio es mantenimiento por kilometros, no daño. Si un kit
                 los resetea, el jugador tiene aceite gratis para siempre y el
                 taller pierde su linea de ingreso recurrente. ]]
            services = false,
            --[[ La chapa tambien es linea de ingreso del taller (Fase 6), asi
                 que el kit no la borra del estado persistido. ]]
            body = false,
            history = true,
            label = 'Kit de reparación avanzado'
        },

        --[[ El `/fixcar` de admin no es economia, es herramienta: arregla todo,
             servicios y chapa incluidos. ]]
        admin = {
            components = true,
            services = true,
            body = true,
            history = true,
            label = 'Reparación de administración'
        }
    },

    --[[ `IsThisModelAnElectricVehicle` solo existe en cliente y el tipo de
         combustible decide que piezas encajan, asi que la lista la resuelve el
         servidor por hash de modelo y no se le pregunta al jugador. ]]
    ElectricModels = {
        'voltic', 'voltic2', 'khamelion', 'surge', 'dilettante', 'dilettante2',
        'neon', 'raiden', 'cyclone', 'tezeract', 'imorgon', 'omnisegt',
        'powersurge', 'virtue', 'iwagen', 'rcbandito', 'caddy', 'caddy2',
        'caddy3', 'airtug'
    }
}

local electricHashes = {}

for i = 1, #Config.Repair.ElectricModels do
    electricHashes[joaat(Config.Repair.ElectricModels[i])] = true
end

function Mechanic.IsWheelPart(part)
    return Config.Repair.WheelParts[part] == true
end

function Mechanic.GetFuelType(modelHash)
    local hash = tonumber(modelHash)
    if hash and hash < 0 then hash = hash + 0x100000000 end

    if hash and electricHashes[hash] then return Mechanic.FuelType.ELECTRIC end

    return Mechanic.FuelType.COMBUSTION
end

--- ¿Encaja esta pieza en un vehículo de este tipo de combustible?
function Mechanic.IsPartCompatible(partConfig, fuelType)
    if type(partConfig) ~= 'table' then return false end
    if partConfig.type == Mechanic.FuelType.BOTH then return true end

    return partConfig.type == fuelType
end

function Mechanic.GetPartProp(part, kind)
    local props = Config.Repair.Props[kind]
    return (props and props[part]) or Config.Repair.FallbackProp
end

function Mechanic.GetPartRecipe(part, kind)
    local recipes = Config.Repair.Recipes[kind]
    return recipes and recipes[part] or nil
end

function Mechanic.GetPartDuration(kind)
    if kind == Mechanic.PartKind.SERVICE then return Config.Repair.Service.duration end

    return Config.Repair.Component.duration
end

--- Condición de un componente en porcentaje (es su propia salud).
function Mechanic.GetComponentConditionPercent(health)
    return Mechanic.ClampHealth(health)
end

--- Condición de un servicio en porcentaje de vida útil restante.
function Mechanic.GetServiceConditionPercent(since, interval)
    local used = tonumber(since) or 0
    local total = tonumber(interval) or 0
    if total <= 0 then return 0.0 end

    return Mechanic.ClampHealth(100.0 - ((used / total) * 100.0))
end
