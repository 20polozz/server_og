Mechanic.BodyStateKey = 'mechanicBody'

Mechanic.BodyStatus = {
    DAMAGED = 'damaged',
    MISSING = 'missing'
}

Mechanic.BodyGroupKind = {
    DOOR = 'door',
    WHEEL = 'wheel',
    WINDOW = 'window'
}

Config.Body = {
    --[[ Distancia que valida el SERVIDOR entre el jugador y el vehiculo del
         netId, igual que en Config.Repair y Config.Diagnostic. ]]
    MaxDistance = 8.0,

    TargetDistance = 4.0,

    DurationTolerance = 0.85,
    TicketMaxMs = 300000,

    --[[ Tope de entradas de un escaneo. Un turismo entero no pasa de 18; el tope
         solo corta una peticion inflada a mano. ]]
    MaxScanEntries = 32,

    MaxBodyHealth = 1000.0,

    Inspect = {
        item = 'herramienta_chapa',
        duration = 2000,
        --[[ Radio en el que se puede pulsar la tecla sobre el punto. ]]
        pointDistance = 1.3,
        markerDistance = 6.0,
        --[[ Si el mecanico se aleja mas de esto, la inspeccion se corta sola. ]]
        abortDistance = 20.0,
        key = 38,
        keyLabel = 'E',
        --[[ El punto es el mismo de todo el servidor (origen_games/core/punto):
             el aro rosa girando en el SUELO y el galon flotando encima. Van
             cuatro a la vez pegados al coche, asi que el aro es mas chico que
             el de un punto de actividad para que no se pisen entre si. ]]
        Marker = {
            color = { r = 216, g = 27, b = 85 },
            ring = { type = 27, scale = 1.2, height = 1.0, alpha = 170, zOffset = 0.03 },
            chevron = { type = 20, scale = 0.4, alpha = 190, zOffset = 1.1 }
        }
    },

    Repair = {
        duration = 12000,
        --- El minijuego de la casa; skillCheck/inputs son el respaldo de ox_lib.
        minijuego = { juego = 'corte', dificultad = 'medium', titulo = 'Cortar y soldar la chapa' },
        skillCheck = { 'easy', 'medium', 'medium' },
        inputs = { 'w', 'a', 's', 'd' },
        --[[ Cada panel recuperado devuelve algo de salud de carroceria; cuando no
             queda nada roto se sube al maximo. ]]
        bodyHealthPerPart = 90.0
    },

    Ptfx = {
        weld = { dict = 'core', name = 'ent_amb_foundry_arc_heat', scale = 0.6 },
        sparks = { dict = 'core', name = 'sp_foundry_sparks', scale = 0.7 }
    },

    --[[ Lo que devuelve una pieza vieja de chapa. Una que sale arrancada no
         devuelve nada: ya no queda nada que reaprovechar. ]]
    ReturnRatio = {
        damaged = 0.5,
        missing = 0.0
    },

    --[[ `type` es el campo de compatibilidad de combustible que mira
         `Mechanic.IsPartCompatible`: una puerta encaja en cualquier coche, asi
         que sin el la chapa no pasaria el filtro del presupuesto. ]]
    Parts = {
        puerta = {
            order = 1,
            label = 'Puerta',
            item = 'pieza_puerta',
            type = Mechanic.FuelType.BOTH,
            kind = Mechanic.BodyGroupKind.DOOR,
            indices = { 0, 1, 2, 3 },
            reach = 1.7,
            prop = { model = 'imp_prop_impexp_car_door_04a', pos = vector3(-0.55, 0.12, -0.32), rot = vector3(0.0, 0.0, 90.0), bone = 28422 },
            anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
            recipe = { chatarra_metal = 5, chatarra_plastico = 2 }
        },
        capo = {
            order = 2,
            label = 'Capó',
            item = 'pieza_capo',
            type = Mechanic.FuelType.BOTH,
            kind = Mechanic.BodyGroupKind.DOOR,
            indices = { 4 },
            reach = 1.6,
            prop = { model = 'imp_prop_impexp_bonnet_04a', pos = vector3(0.0, 0.20, 0.12), rot = vector3(-20.0, 0.0, 180.0), bone = 28422 },
            anim = { dict = 'mini@repair', clip = 'fixing_a_player' },
            recipe = { chatarra_metal = 4, chatarra_plastico = 1 }
        },
        porton = {
            order = 3,
            label = 'Portón',
            item = 'pieza_porton',
            type = Mechanic.FuelType.BOTH,
            kind = Mechanic.BodyGroupKind.DOOR,
            indices = { 5 },
            reach = 1.6,
            prop = { model = 'imp_prop_impexp_trunk_01a', pos = vector3(0.0, 0.15, 0.1), rot = vector3(30.0, 0.0, 0.0), bone = 28422 },
            anim = { dict = 'mini@repair', clip = 'fixing_a_player' },
            recipe = { chatarra_metal = 4, chatarra_plastico = 1 }
        },
        rueda = {
            order = 4,
            label = 'Rueda',
            item = 'pieza_rueda',
            type = Mechanic.FuelType.BOTH,
            kind = Mechanic.BodyGroupKind.WHEEL,
            indices = { 0, 1, 2, 3, 4, 5 },
            reach = 1.7,
            prop = { model = 'imp_prop_impexp_tyre_01c', pos = vector3(0.0, 0.26, -0.15), rot = vector3(0.0, 0.0, 0.0), bone = 28422 },
            anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
            recipe = { chatarra_goma = 4, chatarra_metal = 2 }
        },
        luna = {
            order = 5,
            label = 'Luna',
            item = 'pieza_luna',
            type = Mechanic.FuelType.BOTH,
            kind = Mechanic.BodyGroupKind.WINDOW,
            indices = { 0, 1, 2, 3, 6, 7 },
            reach = 1.9,
            prop = { model = 'h4_prop_yacht_glass_04', pos = vector3(0.0, -0.1, 0.3), rot = vector3(0.0, 0.0, 0.0), bone = 28422 },
            anim = { dict = 'mini@repair', clip = 'fixing_a_player' },
            recipe = { chatarra_plastico = 3 }
        }
    },

    --[[ `bone2` es el asiento: cuando la puerta ya no esta, su hueso desaparece
         del modelo y hace falta otro para situar el punto de trabajo. ]]
    Doors = {
        [0] = { label = 'Puerta delantera izquierda', bone = 'door_dside_f', bone2 = 'seat_dside_f' },
        [1] = { label = 'Puerta delantera derecha', bone = 'door_pside_f', bone2 = 'seat_pside_f' },
        [2] = { label = 'Puerta trasera izquierda', bone = 'door_dside_r', bone2 = 'seat_dside_r' },
        [3] = { label = 'Puerta trasera derecha', bone = 'door_pside_r', bone2 = 'seat_pside_r' },
        [4] = { label = 'Capó', bone = 'bonnet' },
        [5] = { label = 'Portón trasero', bone = 'boot' }
    },

    Windows = {
        [0] = { label = 'Ventanilla delantera izquierda', bone = 'window_lf' },
        [1] = { label = 'Ventanilla delantera derecha', bone = 'window_rf' },
        [2] = { label = 'Ventanilla trasera izquierda', bone = 'window_lr' },
        [3] = { label = 'Ventanilla trasera derecha', bone = 'window_rr' },
        [6] = { label = 'Parabrisas', bone = 'windscreen' },
        [7] = { label = 'Luneta trasera', bone = 'windscreen_r' }
    },

    --[[ El indice de neumatico y el id de rueda NO son el mismo numero: las
         nativas de reventon usan el indice y las de salud y arranque el id. En un
         coche de 4 ruedas los traseros son 4 y 5 de indice pero 2 y 3 de id. ]]
    Wheels = {
        [2] = {
            [0] = { label = 'Rueda delantera', bone = 'wheel_lf', wheelId = 0 },
            [4] = { label = 'Rueda trasera', bone = 'wheel_lr', wheelId = 1 }
        },
        [3] = {
            [0] = { label = 'Rueda delantera izquierda', bone = 'wheel_lf', wheelId = 0 },
            [1] = { label = 'Rueda delantera derecha', bone = 'wheel_rf', wheelId = 1 },
            [4] = { label = 'Rueda trasera izquierda', bone = 'wheel_lr', wheelId = 2 },
            [5] = { label = 'Rueda trasera derecha', bone = 'wheel_rr', wheelId = 3 }
        },
        [4] = {
            [0] = { label = 'Rueda delantera izquierda', bone = 'wheel_lf', wheelId = 0 },
            [1] = { label = 'Rueda delantera derecha', bone = 'wheel_rf', wheelId = 1 },
            [4] = { label = 'Rueda trasera izquierda', bone = 'wheel_lr', wheelId = 2 },
            [5] = { label = 'Rueda trasera derecha', bone = 'wheel_rr', wheelId = 3 }
        },
        [6] = {
            [0] = { label = 'Rueda delantera izquierda', bone = 'wheel_lf', wheelId = 0 },
            [1] = { label = 'Rueda delantera derecha', bone = 'wheel_rf', wheelId = 1 },
            [2] = { label = 'Rueda central izquierda', bone = 'wheel_lm1', wheelId = 4 },
            [3] = { label = 'Rueda central derecha', bone = 'wheel_rm1', wheelId = 5 },
            [4] = { label = 'Rueda trasera izquierda', bone = 'wheel_lr', wheelId = 2 },
            [5] = { label = 'Rueda trasera derecha', bone = 'wheel_rr', wheelId = 3 }
        },
        [8] = {
            [0] = { label = 'Rueda delantera izquierda', bone = 'wheel_lf', wheelId = 0 },
            [1] = { label = 'Rueda delantera derecha', bone = 'wheel_rf', wheelId = 1 },
            [2] = { label = 'Rueda central izquierda', bone = 'wheel_lm1', wheelId = 4 },
            [3] = { label = 'Rueda central derecha', bone = 'wheel_rm1', wheelId = 5 },
            [4] = { label = 'Rueda trasera izquierda', bone = 'wheel_lr', wheelId = 2 },
            [5] = { label = 'Rueda trasera derecha', bone = 'wheel_rr', wheelId = 3 }
        }
    },

    --- Los 4 puntos de la inspección, generados con `GetModelDimensions`.
    InspectPoints = {
        {
            id = 'frontal',
            label = 'Frontal',
            axis = 'y',
            side = 1,
            margin = 0.6,
            anim = { dict = 'mini@repair', clip = 'fixing_a_player' }
        },
        {
            id = 'trasera',
            label = 'Trasera',
            axis = 'y',
            side = -1,
            margin = 0.6,
            anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' }
        },
        {
            id = 'lateral_izquierdo',
            label = 'Lateral izquierdo',
            axis = 'x',
            side = -1,
            margin = 0.5,
            anim = { dict = 'mp_car_bomb', clip = 'car_bomb_mechanic' }
        },
        {
            id = 'lateral_derecho',
            label = 'Lateral derecho',
            axis = 'x',
            side = 1,
            margin = 0.5,
            anim = { dict = 'missmechanic', clip = 'work2_base' }
        }
    }
}

Mechanic.BodyItems = {}
Mechanic.BodyGroupOrder = {}

local function IndexBodyParts()
    for group, part in pairs(Config.Body.Parts) do
        Mechanic.BodyGroupOrder[#Mechanic.BodyGroupOrder + 1] = group

        if type(part.item) ~= 'string' then
            print(('[origen_mechanic] La pieza de carrocería "%s" no tiene item declarado'):format(group))
        elseif Mechanic.PartItems[part.item] then
            print(('[origen_mechanic] El item "%s" ya está en uso por una pieza mecánica'):format(part.item))
        elseif Mechanic.BodyItems[part.item] then
            print(('[origen_mechanic] El item "%s" está declarado dos veces en Config.Body.Parts'):format(part.item))
        else
            Mechanic.BodyItems[part.item] = group
        end

        local allowed = {}
        for i = 1, #part.indices do
            allowed[part.indices[i]] = true
        end
        part.allowed = allowed
    end

    table.sort(Mechanic.BodyGroupOrder, function(a, b)
        return Config.Body.Parts[a].order < Config.Body.Parts[b].order
    end)

    for _, group in ipairs(Mechanic.BodyGroupOrder) do
        local part = Config.Body.Parts[group]
        local source = part.kind == Mechanic.BodyGroupKind.WINDOW and Config.Body.Windows
            or part.kind == Mechanic.BodyGroupKind.DOOR and Config.Body.Doors
            or nil

        if source then
            for i = 1, #part.indices do
                if not source[part.indices[i]] then
                    print(('[origen_mechanic] La pieza "%s" declara el índice %d, que no existe en la tabla de huesos'):format(group, part.indices[i]))
                end
            end
        end
    end
end

IndexBodyParts()

--[[ El cruce va aqui y no en `config/diagnostic.lua`, que es donde viven los
     precios: ese archivo se carga ANTES que este y `Config.Body` todavia no
     existe cuando corre su propio validador. ]]
local function ValidateBodyPrices()
    local prices = (Config.Budget and Config.Budget.Parts and Config.Budget.Parts.body) or {}

    for group in pairs(Config.Body.Parts) do
        if not prices[group] then
            print(('[origen_mechanic] La pieza de carrocería "%s" no tiene precio en Config.Budget.Parts.body'):format(group))
        end
    end

    for group in pairs(prices) do
        if not Config.Body.Parts[group] then
            print(('[origen_mechanic] Config.Budget.Parts.body declara la pieza de carrocería inexistente "%s"'):format(group))
        end
    end
end

ValidateBodyPrices()

function Mechanic.GetBodyPart(group)
    if type(group) ~= 'string' then return nil end

    return Config.Body.Parts[group]
end

--- Devuelve el grupo de carrocería a partir del nombre de item, o `nil`.
function Mechanic.ResolveBodyItem(itemName)
    if type(itemName) ~= 'string' then return nil end

    return Mechanic.BodyItems[itemName]
end

function Mechanic.IsValidBodyIndex(group, index)
    local part = Mechanic.GetBodyPart(group)
    if not part then return false end

    local value = tonumber(index)
    if not value or value % 1 ~= 0 then return false end

    return part.allowed[value] == true
end

function Mechanic.IsValidBodyStatus(status)
    return status == Mechanic.BodyStatus.DAMAGED or status == Mechanic.BodyStatus.MISSING
end

--[[ LA CLAVE COMPUESTA.

     Una linea mecanica se identifica por una clave unica (`motor`, `aceite`).
     Una de chapa NO: un coche puede tener las cuatro puertas arrancadas a la
     vez, asi que hace falta el par (grupo, indice). Todo el sistema de ordenes
     esta indexado por `part` —`BuildOrderLines` deduplica por ahi y
     `Internal.MarkOrderLine` empareja por `part` + `kind`—, de modo que la
     unica forma de que cuatro puertas sean cuatro lineas cobrables es que la
     clave las distinga.

     Quien la "simplifique" a `puerta` volvera a tener una sola linea de puerta
     por orden y tres puertas gratis. ]]
Mechanic.BodyLinePrefix = 'body'

function Mechanic.BodyLineKey(group, index)
    local value = tonumber(index)
    if type(group) ~= 'string' or not value then return nil end

    return ('%s:%s:%d'):format(Mechanic.BodyLinePrefix, group, math.floor(value))
end

--[[ Tolera la forma corta `grupo:indice` porque asi la escribio la Fase 6 en
     `origen_service_history`, y el libro de servicio sigue leyendo esas filas. ]]
function Mechanic.ParseBodyLineKey(key)
    if type(key) ~= 'string' then return nil end

    local group, index = key:match('^' .. Mechanic.BodyLinePrefix .. ':([%a_]+):(%-?%d+)$')
    if not group then group, index = key:match('^([%a_]+):(%-?%d+)$') end
    if not group then return nil end

    local value = tonumber(index)
    if not Mechanic.IsValidBodyIndex(group, value) then return nil end

    return group, math.floor(value)
end

function Mechanic.IsBodyLineKey(key)
    return Mechanic.ParseBodyLineKey(key) ~= nil
end

--- Etiqueta larga de una pieza concreta ("Puerta trasera izquierda").
function Mechanic.GetBodyIndexLabel(group, index)
    local part = Mechanic.GetBodyPart(group)
    if not part then return tostring(index) end

    local value = tonumber(index)
    local source = part.kind == Mechanic.BodyGroupKind.DOOR and Config.Body.Doors
        or part.kind == Mechanic.BodyGroupKind.WINDOW and Config.Body.Windows
        or nil

    if source and value and source[value] then return source[value].label end

    --[[ Se busca en el turismo primero y se cae al de 6 ruedas, que es el unico
         que nombra los indices centrales 2 y 3. Sin la caida, la linea de una
         orden de un camion se factura como "Rueda 2". ]]
    if part.kind == Mechanic.BodyGroupKind.WHEEL then
        for _, count in ipairs({ 4, 6, 8, 3, 2 }) do
            local wheels = Config.Body.Wheels[count]
            if value and wheels and wheels[value] then return wheels[value].label end
        end
    end

    return ('%s %s'):format(part.label, tostring(index))
end

function Mechanic.ClampBodyHealth(value)
    local health = tonumber(value)
    if not health or health ~= health then return Config.Body.MaxBodyHealth end

    return math.max(0.0, math.min(Config.Body.MaxBodyHealth, health + 0.0))
end

--[[ Las claves del mapa viajan SIEMPRE como cadena: `json.encode` convierte un
     mapa de claves numericas en array y al volver de la base de datos los
     indices dejarian de cuadrar con los de las nativas. ]]
function Mechanic.CountBodyDamage(bodyDamage)
    if type(bodyDamage) ~= 'table' or type(bodyDamage.parts) ~= 'table' then return 0 end

    local total = 0
    for _, entries in pairs(bodyDamage.parts) do
        if type(entries) == 'table' then
            for _ in pairs(entries) do
                total = total + 1
            end
        end
    end

    return total
end

--- Vista legible del daño de carrocería, ordenada y con etiquetas.
function Mechanic.DescribeBodyDamage(bodyDamage)
    local rows = {}

    if type(bodyDamage) ~= 'table' or type(bodyDamage.parts) ~= 'table' then return rows end

    for _, group in ipairs(Mechanic.BodyGroupOrder) do
        local entries = bodyDamage.parts[group]
        local part = Config.Body.Parts[group]

        if type(entries) == 'table' then
            local indices = {}
            for index in pairs(entries) do
                indices[#indices + 1] = index
            end
            table.sort(indices)

            for i = 1, #indices do
                local index = indices[i]
                rows[#rows + 1] = {
                    group = group,
                    index = index,
                    label = part.label,
                    detail = Mechanic.GetBodyIndexLabel(group, index),
                    status = entries[index],
                    item = part.item
                }
            end
        end
    end

    return rows
end
