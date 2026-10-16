-- ========================================
-- CIRCUITOS FAVORITOS (15/10/2026)
-- ========================================
-- La estrella de cada circuito en el Racing Hub (Carreras › Circuitos y el
-- selector de Crear carrera). Es cosa de cada jugador y no la necesita nadie
-- más, así que se guarda en el propio juego (KVP del recurso) y no en la
-- base de datos: no hay nada que validar en el servidor.

local CLAVE = 'racing_favoritos'
local TOPE = 200

local function leer()
    local ok, lista = pcall(json.decode, GetResourceKvpString(CLAVE) or '[]')
    if not ok or type(lista) ~= 'table' then return {} end
    local ids = {}
    for _, v in ipairs(lista) do
        local id = tonumber(v)
        if id then ids[#ids + 1] = id end
    end
    return ids
end

RegisterNUICallback('racing:favoritos:leer', function(_, cb)
    cb({ success = true, ids = leer() })
end)

-- `favorito`: true lo pone, false lo quita; sin él, lo alterna.
RegisterNUICallback('racing:favoritos:poner', function(data, cb)
    local id = tonumber(data and data.circuitId)
    if not id then cb({ success = false }) return end

    local nuevos, estaba = {}, false
    for _, v in ipairs(leer()) do
        if v == id then estaba = true else nuevos[#nuevos + 1] = v end
    end

    local quiere = data.favorito
    if quiere == nil then quiere = not estaba end
    if quiere then nuevos[#nuevos + 1] = id end
    while #nuevos > TOPE do table.remove(nuevos, 1) end

    SetResourceKvp(CLAVE, json.encode(nuevos))
    cb({ success = true, ids = nuevos })
end)
