--[[
    LO QUE PIDE UN PUNTO PARA USARSE

    El cliente y el servidor miraban `punto.permission` y `punto.dutyRequired`
    directamente, pero `Business:AddPoint` nunca los guardaba: en base de datos
    llegan siempre a `nil` y cualquier empleado abría cualquier punto sin
    fichar.

    Ya se guardan, pero los puntos que ya existen siguen sin traerlos. De ahí
    estas dos funciones: son el único sitio donde se decide qué pide un punto,
    y resuelven el `nil` con un valor por defecto.

    Los valores por defecto elegidos:

      · PERMISO: ninguno. Adivinar un permiso por tipo de punto le quitaría el
        acceso a gente que hoy lo tiene, y el panel que hay detrás de cada
        punto ya filtra por rango por su cuenta. El permiso es algo que se
        pone a mano.

      · SERVICIO: obligatorio, salvo en los puntos que no son trabajo. Fichar
        no le quita ninguna función a nadie —solo obliga a pulsar el botón de
        servicio antes—, así que es el defecto seguro. Se quedan fuera los
        puntos que también usa quien no es de la casa o que son de uso
        personal: la tienda, la barra, los asientos, el ropero y el almacén
        personal.
]]

BusinessPoints = BusinessPoints or {}

local SIN_SERVICIO = {
    store = true,
    barra_de_baile = true,
    asiento = true,
    storage = true,
    clothing = true,
    carga = true,        -- punto de carga del móvil: para clientes (30/09)
}

--- El permiso que pide el punto, o nil si no pide ninguno.
function BusinessPoints.RequierePermiso(punto)
    if type(punto) ~= 'table' then return nil end
    local permiso = punto.permission
    if type(permiso) ~= 'string' or permiso == '' then return nil end
    return permiso
end

--- Si hay que estar de servicio en el negocio para usar el punto.
function BusinessPoints.RequiereServicio(punto)
    if type(punto) ~= 'table' then return false end
    --[[ El punto de carga del móvil es para todo el mundo, también para los
         empleados sin fichar (30/09): no lo cambia lo guardado en el punto,
         que el panel pone a «hace falta fichar» al crearlo. ]]
    if punto.type == 'carga' then return false end
    if punto.dutyRequired ~= nil then return punto.dutyRequired == true end
    return not SIN_SERVICIO[punto.type]
end
