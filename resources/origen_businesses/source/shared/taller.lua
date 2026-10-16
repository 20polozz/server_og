--[[
    EL TALLER COMO NEGOCIO

    El punto `taller` es distinto del `tuning` que ya existía. El de tuneo abre
    el taller de `origen_customs` (al volante o a pie); este abre el
    cuadro del taller —órdenes de trabajo, stock de piezas y tarifas— y se usa
    de pie, con el coche del cliente delante.

    Aquí vive lo único que necesitan saber los dos lados: cómo se llama el
    stash de piezas de un taller y qué tarifa tiene. La tarifa se sanea en un
    solo sitio porque llega de tres: del formulario de la NUI, de la base de
    datos y del valor por defecto de la config.
]]

BusinessWorkshop = BusinessWorkshop or {}

BusinessWorkshop.PointType = 'taller'

--- El stash donde vive el stock de piezas de un taller.
function BusinessWorkshop.StockId(businessId)
    local id = tostring(businessId or '')
    if id == '' then return nil end
    return 'business_parts_' .. id
end

--[[ La tarifa que acaba usándose. Un valor que no vale cae al defecto en vez de
     a cero: una mano de obra de 0 convierte el taller en lo que veníamos a
     arreglar, un sitio que trabaja gratis. ]]
function BusinessWorkshop.NormalizarTarifa(valor, clave)
    local defecto = (Config.Taller and Config.Taller.DefaultLabor or {})[clave] or 0
    local rango = (Config.Taller and Config.Taller.LaborRange) or { min = 0, max = 50000 }

    local numero = tonumber(valor)
    if not numero or numero ~= numero then return defecto end

    numero = math.floor(numero)
    if numero < rango.min or numero > rango.max then return defecto end

    return numero
end

--- Las tres tarifas de un taller, saneadas.
function BusinessWorkshop.Tarifas(fila)
    local origen = type(fila) == 'table' and fila or {}

    return {
        component = BusinessWorkshop.NormalizarTarifa(origen.labor_component or origen.component, 'component'),
        service = BusinessWorkshop.NormalizarTarifa(origen.labor_service or origen.service, 'service'),
        body = BusinessWorkshop.NormalizarTarifa(origen.labor_body or origen.body, 'body')
    }
end

--- El punto `taller` de un negocio, o nil si no tiene ninguno colocado.
function BusinessWorkshop.Punto(business)
    if type(business) ~= 'table' or type(business.points) ~= 'table' then return nil end

    for _, punto in pairs(business.points) do
        if type(punto) == 'table' and punto.type == BusinessWorkshop.PointType then
            return punto
        end
    end

    return nil
end

function BusinessWorkshop.EsTaller(business)
    return BusinessWorkshop.Punto(business) ~= nil
end

--[[ Los estados de una orden de trabajo. Viven aquí y no en `origen_mechanic`
     —que es su dueño— porque la NUI de este recurso también los pinta, y dos
     listas escritas a mano se desincronizan en el primer estado nuevo. ]]
BusinessWorkshop.Estados = {
    presupuesto = 'Presupuesto',
    aceptada = 'Aceptada',
    en_curso = 'En curso',
    terminada = 'Terminada',
    pagada = 'Pagada',
    cancelada = 'Cancelada'
}
