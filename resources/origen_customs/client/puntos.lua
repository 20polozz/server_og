--[[ Los puntos que flotan sobre el coche: frontal, ruedas, escape…

     Cada zona del catálogo se ancla a un hueso del modelo (el primero de su
     lista que exista) o, si no hay ninguno, a una posición de su caja. Aquí
     se proyectan a la pantalla ~30 veces por segundo y se mandan a la NUI,
     que es la que los pinta y la que sabe si el ratón está encima.

     Solo se manda cuando algo se ha movido: con la cámara quieta no sale
     ningún mensaje. ]]

Puntos = {}

local veh = nil
local activo = false
local locales = {}     -- zona.id → vector3 en coordenadas del coche
local ultimoEnvio = ''

--- La posición de una zona en coordenadas del coche.
local function Anclar(v, zona)
    for _, hueso in ipairs(zona.huesos or {}) do
        local b = GetEntityBoneIndexByName(v, hueso)
        if b ~= -1 then
            local w = GetWorldPositionOfEntityBone(v, b)
            local l = GetOffsetFromEntityGivenWorldCoords(v, w.x, w.y, w.z)
            -- Los huesos de las ruedas están en el eje: se saca el punto un
            -- poco hacia fuera para que no quede dentro de la llanta.
            if hueso:find('^wheel') then l = vector3(l.x * 1.12, l.y, l.z) end
            return l
        end
    end
    local min, max = GetModelDimensions(GetEntityModel(v))
    local c, m = (min + max) / 2.0, (max - min) / 2.0
    local h = zona.hueco or { 0, 0, 0 }
    return vector3(c.x + m.x * h[1], c.y + m.y * h[2], c.z + m.z * h[3])
end

function Puntos.Local(id)
    return locales[id]
end

local function Bucle()
    CreateThread(function()
        while activo do
            if not DoesEntityExist(veh) then break end
            local cam = Camara.Handle()
            local camPos = cam and GetCamCoord(cam) or GetGameplayCamCoord()
            local centro = GetEntityCoords(veh)

            local lista = {}
            for _, zona in ipairs(Catalogo.Zonas) do
                local l = locales[zona.id]
                if l then
                    local w = GetOffsetFromEntityInWorldCoords(veh, l.x, l.y, l.z)
                    local ok, sx, sy = GetScreenCoordFromWorldCoord(w.x, w.y, w.z)
                    -- ¿La zona mira hacia la cámara? Un punto del otro lado del
                    -- coche se enseña apagado, no se esconde: así el mecánico
                    -- sabe que existe y que tiene que girar.
                    local haciaCam = camPos - centro
                    local haciaPunto = w - centro
                    local delante = (haciaCam.x * haciaPunto.x + haciaCam.y * haciaPunto.y + haciaCam.z * haciaPunto.z) > -0.35
                    lista[#lista + 1] = {
                        id = zona.id,
                        x = ok and math.floor(sx * 10000) / 10000 or -1,
                        y = ok and math.floor(sy * 10000) / 10000 or -1,
                        v = ok and delante,
                    }
                end
            end

            local texto = json.encode(lista)
            if texto ~= ultimoEnvio then
                ultimoEnvio = texto
                SendNUIMessage({ accion = 'puntos', datos = lista })
            end
            Wait(33)
        end
    end)
end

function Puntos.Empezar(v)
    veh = v
    locales = {}
    for _, zona in ipairs(Catalogo.Zonas) do
        locales[zona.id] = Anclar(v, zona)
    end
    ultimoEnvio = ''
    activo = true
    Bucle()
end

function Puntos.Parar()
    activo = false
end
