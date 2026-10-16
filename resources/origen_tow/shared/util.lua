--[[ Lo poco que necesitan igual el cliente y el servidor. ]]

Tow = {}

--- La ficha de la grua segun su modelo, o nil si ese modelo no es una grua.
---@param modelo number hash del modelo
function Tow.Ficha(modelo)
    return Config.Gruas[modelo]
end

--- Interpola entre dos numeros.
function Tow.Entre(a, b, t)
    return a + (b - a) * t
end

--- Interpola entre dos vector3.
function Tow.EntreVec(a, b, t)
    return vec3(Tow.Entre(a.x, b.x, t), Tow.Entre(a.y, b.y, t), Tow.Entre(a.z, b.z, t))
end

--- Grados al rango [-180, 180], para que girar de 350 a 10 sea un salto corto
--- y no una vuelta entera.
function Tow.Corto(g)
    g = (g + 180.0) % 360.0
    if g < 0 then g = g + 360.0 end
    return g - 180.0
end

--- Suaviza el 0→1 para que arranque y frene sin tirones.
function Tow.Suave(t)
    if t <= 0.0 then return 0.0 end
    if t >= 1.0 then return 1.0 end
    return t * t * (3.0 - 2.0 * t)
end
