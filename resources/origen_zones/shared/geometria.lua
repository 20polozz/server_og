--[[
    ORIGEN ZONES · la geometría

    Lo mismo en el cliente y en el servidor, a propósito: si cada lado midiera
    la zona a su manera, el aviso saldría en un sitio y el servidor cortaría el
    disparo en otro, y eso se vive como un fallo.

    Una zona puede ser un polígono (lista de esquinas) o un círculo (centro y
    radio). Las dos pueden llevar un suelo y un techo: sin eso, una zona segura
    dibujada sobre un edificio protege también el metro que pasa por debajo.
]]

Geo = {}

-- Redondea la zona una sola vez y se lo guarda encima: el rectángulo que la
-- envuelve. La comprobación cara —recorrer las esquinas— solo se hace cuando
-- el punto cae dentro de ese rectángulo, y eso descarta el 99 % de las veces.
function Geo.Preparar(zona)
    if zona.forma == 'circulo' then
        local r = zona.radio or 0.0
        zona._caja = {
            x1 = (zona.centro_x or 0.0) - r, x2 = (zona.centro_x or 0.0) + r,
            y1 = (zona.centro_y or 0.0) - r, y2 = (zona.centro_y or 0.0) + r,
        }
        zona._cx, zona._cy = zona.centro_x or 0.0, zona.centro_y or 0.0
        zona._alcance = r
        return zona
    end

    local puntos = zona.puntos
    if not puntos or #puntos < 3 then
        zona._caja = nil
        return zona
    end

    local x1, y1 = puntos[1].x, puntos[1].y
    local x2, y2 = x1, y1
    local sx, sy = 0.0, 0.0

    for i = 1, #puntos do
        local p = puntos[i]
        if p.x < x1 then x1 = p.x end
        if p.x > x2 then x2 = p.x end
        if p.y < y1 then y1 = p.y end
        if p.y > y2 then y2 = p.y end
        sx = sx + p.x
        sy = sy + p.y
    end

    zona._caja = { x1 = x1, x2 = x2, y1 = y1, y2 = y2 }
    zona._cx, zona._cy = sx / #puntos, sy / #puntos
    -- El alcance es media diagonal: sirve para barrer coches o para dejar a
    -- alguien fuera, no para decidir si está dentro.
    zona._alcance = math.max(x2 - x1, y2 - y1) * 0.5
    return zona
end

function Geo.EnPoligono(x, y, puntos)
    local dentro = false
    local j = #puntos

    for i = 1, #puntos do
        local xi, yi = puntos[i].x, puntos[i].y
        local xj, yj = puntos[j].x, puntos[j].y

        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            dentro = not dentro
        end
        j = i
    end

    return dentro
end

-- ¿Está este punto dentro de la zona? `z` puede venir a nil cuando solo se
-- mira el plano (el panel, por ejemplo): entonces el suelo y el techo no
-- cuentan.
function Geo.Dentro(zona, x, y, z)
    local caja = zona._caja
    if not caja then return false end
    if x < caja.x1 or x > caja.x2 or y < caja.y1 or y > caja.y2 then return false end

    if z then
        if zona.altura_min and z < zona.altura_min then return false end
        if zona.altura_max and z > zona.altura_max then return false end
    end

    if zona.forma == 'circulo' then
        local dx, dy = x - zona._cx, y - zona._cy
        return (dx * dx + dy * dy) <= (zona.radio * zona.radio)
    end

    return Geo.EnPoligono(x, y, zona.puntos)
end

-- La hora del juego, que es la que ve la gente. La reparte Renewed-Weathersync
-- por GlobalState y la leen igual los dos lados.
function Geo.HoraDelJuego()
    local t = GlobalState.currentTime
    if t and t.hour then return t.hour end
    return tonumber(os.date('%H')) or 12
end

-- Una zona puede mandar solo a ciertas horas: «peatonal de 22 a 6». Cuando el
-- tramo cruza la medianoche, `desde` es mayor que `hasta` y la cuenta se da la
-- vuelta.
function Geo.EnHorario(zona, hora)
    local desde, hasta = zona.horario_desde, zona.horario_hasta
    if desde == nil or hasta == nil then return true end
    if desde == hasta then return true end

    hora = hora or Geo.HoraDelJuego()

    if desde < hasta then
        return hora >= desde and hora < hasta
    end
    return hora >= desde or hora < hasta
end

function Geo.Activa(zona, hora)
    return zona.activa and Geo.EnHorario(zona, hora)
end

-- Un punto justo fuera de la zona, en la dirección en la que ya venía. Lo usa
-- `acceso` para sacar a quien no debería estar sin teletransportarle a la otra
-- punta del mapa.
function Geo.PuntoFuera(zona, x, y)
    local dx, dy = x - zona._cx, y - zona._cy
    local largo = math.sqrt(dx * dx + dy * dy)

    if largo < 0.1 then
        dx, dy, largo = 1.0, 0.0, 1.0
    end

    local fuera = (zona._alcance or 10.0) * 1.25 + 6.0
    return zona._cx + (dx / largo) * fuera, zona._cy + (dy / largo) * fuera
end
