-- De quién es una casa: particular, de una banda o de un crew
-- (config/propietario.lua y custom/server/propietario.lua). Aquí solo va lo
-- que el cliente tiene que hacer: darle al formulario las listas, enseñar el
-- territorio de la banda o de la crew mientras se coloca su casa (y no dejar
-- confirmar un punto fuera) y rehacer la zona cuando el servidor dice que el
-- territorio ha cambiado. Quien decide es el servidor: lo de aquí es para no
-- llevarse el «no» al final.
PropietarioCliente = {}

local C = Config.Propietario
local limite = nil      -- el territorio de la banda o crew de la casa que se está colocando: { uso, puntos, centro, nombre, banda }

--- ¿Ese tipo de propietario va dentro de un territorio? (banda o crew)
function PropietarioCliente.ConTerritorio(uso)
    return uso == 'banda' or uso == 'crew'
end

-- Las bandas y los crews que hay, para el desplegable (ui/js/propietario.js).
RegisterNUICallback('propietarioListas', function(_, cb)
    local ok, listas = pcall(lib.callback.await, 'origen_housing:server:propietario:listas', false)
    cb(ok and type(listas) == 'table' and listas or { bandas = false, crews = false })
end)

local function Texto(grupo, clave, defecto, ...)
    local t = Config.Translations.notify[grupo] and Config.Translations.notify[grupo][clave] or defecto
    local ok, hecho = pcall(string.format, t, ...)
    return ok and hecho or t
end

--[[ Antes de colocar una casa (crear, o recolocar al editar). `datos` es el
     `data` de la casa que manda la NUI. En una casa de banda o de crew pide al
     servidor el territorio de esa banda (el principal) o crew y lo deja puesto
     como límite: la zona exterior ya no se dibuja (PropietarioCliente.Limite)
     y la entrada solo se puede poner dentro (client/placement.lua). Avisa de
     dónde es y, si quien la coloca está fuera, se lo marca en el GPS.
     Devuelve true, o false y el aviso (la banda o la crew no tiene territorio).
     `callado`: sin avisos (se edita la casa sin mover nada). ]]
function PropietarioCliente.Preparar(datos, callado)
    limite = nil
    if type(datos) ~= 'table' or not PropietarioCliente.ConTerritorio(datos.uso) or datos.grupo == nil then return true end
    local ok, t = pcall(lib.callback.await, 'origen_housing:server:propietario:territorio', false, datos.grupo, datos.uso)
    if not ok or type(t) ~= 'table' then return false, Config.Translations.notify.error.errorData end
    if not t.ok then return false, t.aviso or Config.Translations.notify.error.errorData end
    if t.libre or type(t.puntos) ~= 'table' or #t.puntos < 3 then return true end     -- (regla apagada en la config)

    limite = t
    limite.uso = datos.uso
    if not callado then
        Internal.Notify(Texto('info', 'gangPlaceInside', 'Coloca la entrada dentro del territorio de %s (%s)', t.banda or '', t.nombre or ''), 'info', 9000)
        if PropietarioCliente.Fuera(GetEntityCoords(PlayerPedId())) and type(t.centro) == 'table' then
            SetNewWaypoint(t.centro.x + 0.0, t.centro.y + 0.0)
            Internal.Notify(Texto('info', 'gangGoThere', 'Estás fuera del territorio de %s: te lo he marcado en el GPS', t.banda or ''), 'info', 9000)
        end
    end
    return true
end

--- Se acabó de colocar (o se dejó): ya no hay límite.
function PropietarioCliente.Soltar()
    limite = nil
end

--- El territorio que limita lo que se está colocando, o nil.
function PropietarioCliente.Limite()
    return limite
end

--- ¿Cae ese punto fuera del territorio? (false si no hay límite)
function PropietarioCliente.Fuera(coords)
    if not limite or not coords then return false end
    return not Utils.isInsidePolyzone(coords, limite.puntos)
end

function PropietarioCliente.AvisarFuera()
    if limite and limite.uso == 'crew' then
        Internal.Notify(Texto('error', 'crewPointOutside', 'Ahí no: queda fuera del territorio de la crew'), 'error', 5000)
    else
        Internal.Notify(Texto('error', 'gangPointOutside', 'Ahí no: queda fuera del territorio de la banda'), 'error', 5000)
    end
end

--[[ El contorno del territorio, cada fotograma mientras se coloca: un muro
     translúcido en cada lado (por las dos caras) con una raya arriba y otra
     abajo y un poste en cada vértice. Los territorios no tienen altura: el
     muro se pinta alrededor de la altura `z` (la de quien coloca). El rosa lo
     pasa a naranja en Nación el puente de origen_map (shared/tema.lua). ]]
function PropietarioCliente.DibujarLimite(z)
    if not limite then return end
    local p = limite.puntos
    local arriba, abajo = z + (C.territorio.muroArriba or 40.0), z - (C.territorio.muroAbajo or 80.0)
    local j = #p
    for i = 1, #p do
        local ax, ay, bx, by = p[j].x + 0.0, p[j].y + 0.0, p[i].x + 0.0, p[i].y + 0.0
        DrawPoly(ax, ay, abajo, bx, by, abajo, bx, by, arriba, 216, 27, 85, 45)
        DrawPoly(ax, ay, abajo, bx, by, arriba, ax, ay, arriba, 216, 27, 85, 45)
        DrawPoly(bx, by, abajo, ax, ay, abajo, bx, by, arriba, 216, 27, 85, 45)
        DrawPoly(bx, by, arriba, ax, ay, abajo, ax, ay, arriba, 216, 27, 85, 45)
        DrawLine(ax, ay, arriba, bx, by, arriba, 216, 27, 85, 255)
        DrawLine(ax, ay, z, bx, by, z, 216, 27, 85, 255)
        DrawLine(bx, by, abajo, bx, by, arriba, 216, 27, 85, 255)
        j = i
    end
end

-- El territorio que hace de zona exterior ha cambiado (o ya no hay).
RegisterNetEvent('origen_housing:client:zonaDeBanda', function(houseID, zona)
    local house = House.get(houseID)
    if not house then return end
    house.houseData.exteriorBanda = type(zona) == 'table' and zona or nil
    if HouseData[houseID] then HouseData[houseID].exteriorBanda = house.houseData.exteriorBanda end
    house:RehacerZonaExterior()
end)
