--[[
    LAS CÁMARAS DE SEGURIDAD DEL NEGOCIO

    Una cámara es un PUNTO más del negocio (tipo `camera`): se coloca desde
    Ajustes → Puntos apuntando a una pared o al techo, como la cocina, y se
    guarda con los demás puntos. Hereda de ellos el límite por negocio, estar
    a menos de 25 m para colocarla y el permiso `manage_settings`.

    Verlas es otro permiso, `view_cameras` («Ver cámaras»), que el jefe da al
    rango que quiera. Se miran desde la pestaña Cámaras del panel, estés donde
    estés. Ver source/server/camaras.lua y source/client/camaras.lua.
]]

Config = Config or {}

Config.Camaras = {
    --[[ Cuántas puede poner un negocio al que la administración no le ha
         dado un límite propio. Con `available_points.camera` puesto en el
         panel de admin manda ese. ]]
    PorDefecto = 4,

    --[[ Los modelos que se pueden colgar. Son los mismos que usa la policía,
         y en todos el objetivo mira hacia su -Y: por eso la vista gira 180°
         respecto al rumbo con el que se colocó. `desfase` es dónde queda el
         objetivo respecto al punto de anclaje (hacia delante y hacia abajo). ]]
    Modelos = {
        { model = 'prop_cctv_cam_06a', label = 'Domo de techo' },
        { model = 'prop_cctv_cam_01a', label = 'De pared' },
        { model = 'prop_cctv_cam_01b', label = 'De pared (blanca)' },
        { model = 'prop_cctv_cam_04b', label = 'Compacta' },
        { model = 'prop_cctv_cam_04c', label = 'Compacta (esquina)' },
    },
    Desfase = { adelante = 0.2, abajo = 0.4 },

    -- Hasta dónde gira la vista a cada lado del rumbo en que se colocó.
    Giro = 70.0,
    -- Inclinación: la de arranque y los topes (negativo es mirar hacia abajo).
    Inclinacion = { inicial = -25.0, min = -70.0, max = 10.0 },
    -- Campo de visión: más pequeño es más zoom.
    Fov = { inicial = 55.0, min = 12.0, max = 70.0 },
    -- Sensibilidad del ratón al mirar.
    Sensibilidad = 6.0,

    -- A qué distancia aparece el objeto de la cámara en el mundo.
    DistanciaObjeto = 80.0,

    -- El largo máximo del nombre de una cámara.
    NombreMax = 32,
}

--- El modelo de la lista, o nil si no está permitido.
function Config.Camaras.Modelo(modelo)
    if type(modelo) ~= 'string' then return nil end
    for _, m in ipairs(Config.Camaras.Modelos) do
        if m.model == modelo then return m end
    end
    return nil
end
