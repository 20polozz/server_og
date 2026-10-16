Mechanic.PartKind = {
    COMPONENT = 'component',
    SERVICE = 'service',
    --[[ La chapa no vive en Config.Items: sus piezas y su item los declara
         `Config.Body.Parts`, indexadas por (grupo, indice). ]]
    BODY = 'body',

    --[[ Un kit no sustituye una pieza concreta: deja constancia en el libro de
         servicio de que alguien intervino el coche fuera del taller. ]]
    KIT = 'kit'
}

--[[ El nombre de item NO es la clave de la pieza: `motor`, `frenos` o `correa`
     son palabras demasiado genericas para el espacio de nombres del inventario.
     El mapeo vive aqui y es la unica fuente de verdad. ]]
Config.Items = {
    PatchKit = 'kit_parche',

    --[[ Herramientas: no se gastan y no son piezas, asi que quedan fuera del
         indice inverso de Mechanic.PartItems. Config.Diagnostic manda. ]]
    DiagnosticTool = 'herramienta_diagnostico',
    ServiceBook = 'libro_servicio',

    Components = {
        motor = 'pieza_motor',
        transmision = 'pieza_transmision',
        frenos = 'pieza_frenos',
        refrigeracion = 'pieza_refrigeracion',
        inyeccion = 'pieza_inyeccion',
        direccion = 'pieza_direccion',
        alternador = 'pieza_alternador',
        suspension = 'pieza_suspension',
        motor_electrico = 'pieza_motor_electrico',
        bateria_ev = 'pieza_bateria_ev'
    },

    Services = {
        aceite = 'servicio_aceite',
        filtro_aire = 'servicio_filtro_aire',
        pastillas = 'servicio_pastillas',
        filtro_combustible = 'servicio_filtro_combustible',
        bujias = 'servicio_bujias',
        liquido_frenos = 'servicio_liquido_frenos',
        anticongelante = 'servicio_anticongelante',
        correa = 'servicio_correa',
        liquido_direccion = 'servicio_liquido_direccion',
        refrigerante_bateria = 'servicio_refrigerante_bateria',
        liquido_transmision = 'servicio_liquido_transmision',
        cableado_at = 'servicio_cableado_at',
        neumaticos = 'servicio_neumaticos'
    },

    Materials = {
        chatarra_metal = 'Chatarra de metal',
        chatarra_plastico = 'Chatarra de plástico',
        chatarra_goma = 'Chatarra de goma',
        chatarra_cobre = 'Chatarra de cobre'
    }
}

Mechanic.PartItems = {}

local function IndexPartItems()
    local seen = {}

    local function index(map, config, kind)
        for part in pairs(config) do
            local item = map[part]
            if not item then
                print(('[origen_mechanic] La pieza "%s" (%s) no tiene item declarado en Config.Items'):format(part, kind))
            elseif seen[item] then
                print(('[origen_mechanic] El item "%s" esta declarado dos veces en Config.Items'):format(item))
            else
                seen[item] = true
                Mechanic.PartItems[item] = { part = part, kind = kind }
            end
        end

        for part in pairs(map) do
            if not config[part] then
                print(('[origen_mechanic] Config.Items declara la pieza inexistente "%s" (%s)'):format(part, kind))
            end
        end
    end

    index(Config.Items.Components, Config.Components, Mechanic.PartKind.COMPONENT)
    index(Config.Items.Services, Config.Services, Mechanic.PartKind.SERVICE)
end

IndexPartItems()

--- Devuelve la pieza y su tipo a partir del nombre de item, o `nil`.
function Mechanic.ResolvePartItem(itemName)
    if type(itemName) ~= 'string' then return nil end

    local entry = Mechanic.PartItems[itemName]
    if not entry then return nil end

    return entry.part, entry.kind
end

function Mechanic.GetPartItem(part, kind)
    if kind == Mechanic.PartKind.COMPONENT then return Config.Items.Components[part] end
    if kind == Mechanic.PartKind.SERVICE then return Config.Items.Services[part] end

    if kind == Mechanic.PartKind.BODY then
        local group = Mechanic.ParseBodyLineKey(part)
        local bodyPart = group and Config.Body.Parts[group]
        return bodyPart and bodyPart.item or nil
    end

    return nil
end

function Mechanic.GetPartConfig(part, kind)
    if kind == Mechanic.PartKind.COMPONENT then return Config.Components[part] end
    if kind == Mechanic.PartKind.SERVICE then return Config.Services[part] end

    if kind == Mechanic.PartKind.BODY then
        local group = Mechanic.ParseBodyLineKey(part)
        return group and Config.Body.Parts[group] or nil
    end

    return nil
end

--[[ La chapa se rotula con la etiqueta LARGA ("Puerta trasera izquierda"): con
     la del grupo, cuatro puertas rotas serian cuatro lineas llamadas "Puerta" y
     el cliente no sabria que esta firmando. ]]
function Mechanic.GetPartLabel(part, kind)
    if kind == Mechanic.PartKind.KIT then
        local kit = Config.Repair.Kits and Config.Repair.Kits[part]
        return kit and kit.label or part
    end

    if kind == Mechanic.PartKind.BODY then
        local group, index = Mechanic.ParseBodyLineKey(part)
        if not group then return part end

        return Mechanic.GetBodyIndexLabel(group, index)
    end

    local config = Mechanic.GetPartConfig(part, kind)
    return config and config.label or part
end
