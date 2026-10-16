--[[ ── Lo que se ve dentro de una caja ────────────────────────────────────────

     Una caja de la granja nunca va vacía a la vista: lleva dentro las piezas
     de lo cosechado (lechugas, calabazas…), tantas como lo llena que vaya.
     Lo usan las cajas en las manos, las del palé y las de la camioneta, así
     que las tres se ven igual. Los sacos van cerrados: no enseñan nada.

     SOLO SE PINTA LA CAPA DE ARRIBA (21/09). De una caja no se ve el fondo:
     se ve la superficie de lo que lleva. Así que en vez de llenarla entera
     (30 lechugas, de las que 25 no se veían nunca) se pone UNA capa a la
     altura que le toque según lo llena que vaya: cuatro o cinco piezas y la
     caja se ve igual de llena.

     Importa porque GTA solo aguanta ~1.290 entidades PEGADAS a otra en toda
     la partida y al pasarse el juego se cae con «AttachmentExtension Pool
     Full, Size == 1290». Quitarles la colisión no sirve: ese cupo cuenta lo
     pegado, no lo que choca; y no hay forma de que ocho lechugas cuenten
     como una (cada entidad pegada ocupa su hueco). Un palé lleno pasa de
     ~370 objetos pegados a ~20: el que está tapado por otra caja encima ni
     siquiera los pone (plantas.lua). ]]

Relleno = {}

function Relleno.Cargar(hash)
    if not IsModelInCdimage(hash) then return false end
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local fin = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < fin do Wait(0) end
    return HasModelLoaded(hash)
end

--- Tope de piezas de la capa (por si entran muchas pequeñas).
local TOPE = 9

--- Rellena una caja ya creada: una capa de piezas a la altura que marque lo
--- llena que vaya, amontonadas y giradas al azar.
--- Devuelve las entidades creadas, para borrarlas con la caja.
function Relleno.Llenar(caja, cultivo, lleno)
    local cult = Granja.Cultivo(cultivo)
    local def = cult and cult.contenido
    lleno = math.max(0.0, math.min(1.0, tonumber(lleno) or 0))
    if not def or lleno <= 0 or not DoesEntityExist(caja) then return {} end
    local hash = GetHashKey(def.modelo)
    if not Relleno.Cargar(hash) then return {} end
    local cmin, cmax = GetModelDimensions(GetEntityModel(caja))
    local pmin, pmax = GetModelDimensions(hash)
    local pw, pd, ph = pmax.x - pmin.x, pmax.y - pmin.y, pmax.z - pmin.z
    local margen = 0.04
    -- Donde puede caer el CENTRO de una pieza sin salirse de las paredes.
    local x0, x1 = cmin.x + margen + pw * 0.45, cmax.x - margen - pw * 0.45
    local y0, y1 = cmin.y + margen + pd * 0.45, cmax.y - margen - pd * 0.45
    if x1 < x0 then x0, x1 = (cmin.x + cmax.x) / 2, (cmin.x + cmax.x) / 2 end
    if y1 < y0 then y0, y1 = (cmin.y + cmax.y) / 2, (cmin.y + cmax.y) / 2 end
    local cols = math.max(2, math.min(4, math.floor((cmax.x - cmin.x) / (pw * 0.6))))
    local filas = math.max(2, math.min(4, math.floor((cmax.y - cmin.y) / (pd * 0.6))))
    local paso = ph * 0.5
    local pisos = math.max(2, math.min(3, math.floor((cmax.z - cmin.z - 0.03) / paso) + 1))

    -- A qué altura queda la superficie: media caja llena, media altura.
    local piso = math.max(0, math.min(pisos - 1, math.ceil(lleno * pisos) - 1))
    local z = cmin.z - 0.02 + piso * paso - pmin.z
    local desplaza = (piso % 2 == 1) and 0.5 or 0.0

    local piezas = {}
    local i = 0
    for f = 0, filas - 1 - (piso % 2) do
        for c = 0, cols - 1 - (piso % 2) do
            i = i + 1
            if i > TOPE then break end
            local tx = cols > 1 and (c + desplaza) / (cols - 1) or 0.5
            local ty = filas > 1 and (f + desplaza) / (filas - 1) or 0.5
            local ox = x0 + (x1 - x0) * tx - (pmin.x + pmax.x) / 2 + ((i * 37) % 7 - 3) * 0.006
            local oy = y0 + (y1 - y0) * ty - (pmin.y + pmax.y) / 2 + ((i * 53) % 7 - 3) * 0.006
            local pos = GetEntityCoords(caja)
            local e = Rastro.Marcar(CreateObject(hash, pos.x, pos.y, pos.z + 1.0, false, false, false))
            SetEntityCollision(e, false, false)
            -- Un giro y un temblor distintos por pieza: amontonadas, no alineadas.
            AttachEntityToEntity(e, caja, 0, ox, oy, z,
                ((i * 29) % 15 - 7) + 0.0, ((i * 17) % 15 - 7) + 0.0, ((i * 71) % 360) + 0.0,
                false, false, false, false, 2, true)
            piezas[#piezas + 1] = e
        end
    end
    SetModelAsNoLongerNeeded(hash)
    return piezas
end

function Relleno.Borrar(piezas)
    for _, e in ipairs(piezas or {}) do
        if DoesEntityExist(e) then DeleteEntity(e) end
    end
end

--- La huella de una caja publicada ({ t, c, l }) para saber si hay que repintarla.
function Relleno.Clave(caja)
    if type(caja) ~= 'table' then return tostring(caja) end
    return ('%s:%s:%.2f'):format(tostring(caja.t), tostring(caja.c), tonumber(caja.l) or 0)
end
