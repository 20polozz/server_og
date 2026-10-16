--[[ ── Escondite · convertirse en prop ──────────────────────────────────────

     El truco: el personaje se vuelve invisible y lleva pegado el objeto. El
     objeto es de red, así que los demás lo ven moverse con él, y la voz de
     proximidad sigue saliendo del personaje: el prop «habla».

     El objeto lo crea este cliente y el servidor lo comprueba antes de darlo
     por bueno (que sea un objeto, que sea suyo y que sea EL modelo que le tocó).
     Si lo que se crea no coincide, el servidor lo borra. ]]

Prop = {}

local objeto
local fichaActual
local congelado = false

--- Cada transformación lleva su número. Si llegan dos seguidas y la primera
--- tarda en cargar su modelo, al terminar ve que ya no es la última y no toca
--- nada: sin esto borraba el objeto bueno y dejaba el prop invisible.
local generacion = 0

local function Ped() return PlayerPedId() end

function Prop.Ficha() return fichaActual end
function Prop.Objeto() return objeto end

--- Lo que sobresale la base del modelo por debajo de su origen (negativo).
local base = 0.0

--[[ Moviéndose, el objeto va PEGADO al personaje invisible y le sigue.

     Se pega a la raíz, que va a un metro del suelo más o menos: se mide cuánto
     exactamente y se baja el objeto eso más lo que sobresale su base, para que
     apoye en el suelo en vez de flotar o hundirse. Va sin colisión, o se
     chocaría con su propio personaje. ]]
local function Enganchar(obj)
    local ped = Ped()
    FreezeEntityPosition(obj, false)
    SetEntityCollision(obj, false, false)

    local altura = GetEntityHeightAboveGround(ped)
    if altura < 0.6 or altura > 1.4 then altura = 1.0 end

    AttachEntityToEntity(obj, ped, 0, 0.0, 0.0, -altura - base, 0.0, 0.0, 0.0,
        false, false, false, false, 2, true)
end

--[[ Quieto, el objeto se SUELTA y se clava en el mundo.

     Pegado al personaje heredaba su animación de estar de pie (la respiración,
     el peso de un pie a otro) y el prop se balanceaba aunque el personaje
     estuviera congelado: se notaba a simple vista que era alguien. Suelto,
     recto, apoyado en el suelo y congelado, no se mueve nada. Y con colisión:
     el cazador choca con él como con cualquier objeto del mapa. ]]
local function Fijar(obj)
    local ped = Ped()
    local c = GetEntityCoords(ped)
    local rumbo = GetEntityHeading(ped)

    local altura = GetEntityHeightAboveGround(ped)
    if altura < 0.6 or altura > 1.4 then altura = 1.0 end
    local z = c.z - altura - base

    -- Mejor el suelo de verdad, si se encuentra cerca: en una cuesta, la
    -- altura sobre el suelo del personaje no es la de su punto de apoyo.
    local hay, suelo = GetGroundZFor_3dCoord(c.x, c.y, c.z + 0.5, false)
    if hay and math.abs(suelo - (c.z - altura)) < 1.0 then z = suelo - base end

    DetachEntity(obj, false, false)
    SetEntityCoordsNoOffset(obj, c.x, c.y, z, false, false, false)
    SetEntityRotation(obj, 0.0, 0.0, rumbo, 2, true)
    SetEntityVelocity(obj, 0.0, 0.0, 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, true, true)
end

function Prop.Quitar()
    -- Quitar también cancela una transformación que siga cargando.
    generacion = generacion + 1
    if objeto and DoesEntityExist(objeto) then
        DetachEntity(objeto, false, false)
        SetEntityAsMissionEntity(objeto, true, true)
        DeleteEntity(objeto)
    end
    objeto = nil
    fichaActual = nil
end

--- Carga un modelo con tope de espera. Devuelve false si no existe en esta
--- versión del juego o no llega a cargar.
local function Cargar(hash)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return false end
    RequestModel(hash)
    local hasta = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > hasta then return false end
        Wait(20)
    end
    return true
end

function Prop.Transformar(ficha)
    if not ficha or not ficha.modelo then return end
    generacion = generacion + 1
    local mia = generacion
    local hash = GetHashKey(ficha.modelo)

    local cargado = Cargar(hash)
    if mia ~= generacion then return end

    if not cargado then
        -- El servidor sortea otro y no lo vuelve a dar.
        TriggerServerEvent('origen_games:escondite:s:modeloRoto', ficha.modelo)
        return
    end

    Prop.Quitar()

    local ped = Ped()
    local c = GetEntityCoords(ped)

    local obj = CreateObject(hash, c.x, c.y, c.z - 1.0, true, true, false)
    SetModelAsNoLongerNeeded(hash)
    if not obj or obj == 0 then return end

    objeto = obj
    fichaActual = ficha

    SetEntityInvincible(obj, true)
    SetEntityCanBeDamaged(obj, false)
    SetEntityCollision(obj, false, false)
    SetEntityVisible(ped, false, false)

    base = GetModelDimensions(hash).z

    if congelado then Fijar(obj) else Enganchar(obj) end

    --[[ Que no cambie de dueño: si migrara a otro cliente, dejaría de ser
         «suyo» para el servidor y no se podría comprobar. ]]
    local hastaRed = GetGameTimer() + 1500
    while not NetworkGetEntityIsNetworked(obj) and GetGameTimer() < hastaRed do Wait(0) end
    local netId = NetworkGetNetworkIdFromEntity(obj)
    SetNetworkIdCanMigrate(netId, false)

    -- Un respiro para que el servidor ya conozca la entidad al comprobarla.
    SetTimeout(350, function()
        if objeto == obj then TriggerServerEvent('origen_games:escondite:s:modelo', netId) end
    end)
end

function Prop.Congelar(si)
    congelado = si == true
    local ped = Ped()
    FreezeEntityPosition(ped, congelado)
    if congelado then
        ClearPedTasksImmediately(ped)
        SetPedCanRagdoll(ped, false)
    end

    if objeto and DoesEntityExist(objeto) then
        if congelado then Fijar(objeto) else Enganchar(objeto) end
    end
end

function Prop.Congelado() return congelado end

function Prop.Girar(grados)
    local ped = Ped()
    local rumbo = (GetEntityHeading(ped) + grados) % 360.0
    SetEntityHeading(ped, rumbo)
    -- Quieto, el objeto ya no va pegado al personaje: se gira él.
    if congelado and objeto and DoesEntityExist(objeto) then
        SetEntityRotation(objeto, 0.0, 0.0, rumbo, 2, true)
    end
end

--[[ ── Mirar un objeto del mapa para copiarlo ─────────────────────────────── ]]
local function Direccion(rot)
    local z, x = math.rad(rot.z), math.rad(rot.x)
    local n = math.abs(math.cos(x))
    return vector3(-math.sin(z) * n, math.cos(z) * n, math.sin(x))
end
Prop.Direccion = Direccion

--[[ ── El láser de copiar ──────────────────────────────────────────────────

     Como el láser del panel de admin: una línea desde el prop hasta donde
     apunta la cámara y una caja alrededor del objeto al que da. Rosa si ese
     objeto se puede copiar, blanco apagado si no. Así se ve de un vistazo en
     qué te puedes convertir sin ir probando a ciegas. ]]

--- A qué apunta la cámara. Devuelve una tabla con:
---   punto    dónde da (o el final del alcance si no da a nada)
---   ent      la entidad a la que da, si es un objeto
---   ficha    su ficha del catálogo si se puede copiar
---   hash     el modelo sin signo, para mandarlo al servidor
function Prop.Apuntar()
    local ped = Ped()
    local cam = GetFinalRenderedCamCoord()
    local dir = Direccion(GetFinalRenderedCamRot(2))
    local desdePed = #(cam - GetEntityCoords(ped))
    local hasta = cam + dir * (Config.Juegos.escondite.Props.alcanceCopia + desdePed)

    -- Mundo + objetos: una pared corta el láser, no lo atraviesa.
    local prueba = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z,
        hasta.x, hasta.y, hasta.z, 17, ped, 4)
    local _, toca, punto, _, ent = GetShapeTestResult(prueba)

    local info = { punto = toca == 1 and punto or hasta }
    if toca ~= 1 or not ent or ent == 0 or ent == objeto then return info end
    if GetEntityType(ent) ~= 3 then return info end

    info.ent = ent

    -- Otro prop de la partida no se puede copiar: se sabría quién es.
    if Entity(ent).state.escondite then return info end
    if #(GetEntityCoords(ped) - punto) > Config.Juegos.escondite.Props.alcanceCopia + 1.5 then return info end

    local hash = HashSinSigno(GetEntityModel(ent))
    local ficha = CatalogoPorHash[hash]
    if ficha then
        info.ficha = ficha
        info.hash = hash
    end
    return info
end

--- Las doce aristas de la caja del modelo, en el mundo: se sacan las ocho
--- esquinas con el desplazamiento de la entidad, así la caja gira con ella.
local function Caja(ent, r, g, b, a)
    local minimo, maximo = GetModelDimensions(GetEntityModel(ent))
    local function E(x, y, z) return GetOffsetFromEntityInWorldCoords(ent, x, y, z) end
    local c = {
        E(minimo.x, minimo.y, minimo.z), E(maximo.x, minimo.y, minimo.z),
        E(maximo.x, maximo.y, minimo.z), E(minimo.x, maximo.y, minimo.z),
        E(minimo.x, minimo.y, maximo.z), E(maximo.x, minimo.y, maximo.z),
        E(maximo.x, maximo.y, maximo.z), E(minimo.x, maximo.y, maximo.z),
    }
    local aristas = { {1,2},{2,3},{3,4},{4,1}, {5,6},{6,7},{7,8},{8,5}, {1,5},{2,6},{3,7},{4,8} }
    for _, par in ipairs(aristas) do
        local p, q = c[par[1]], c[par[2]]
        DrawLine(p.x, p.y, p.z, q.x, q.y, q.z, r, g, b, a)
    end
end

function Prop.DibujarLaser(info)
    local origen = objeto and DoesEntityExist(objeto) and GetEntityCoords(objeto) or GetEntityCoords(Ped())
    local p = info.punto
    local r, g, b, a = 240, 236, 228, 150
    if info.ficha then r, g, b, a = 216, 27, 85, 235 end

    DrawLine(origen.x, origen.y, origen.z + 0.25, p.x, p.y, p.z, r, g, b, a)
    DrawMarker(28, p.x, p.y, p.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.06, 0.06, 0.06, r, g, b, a, false, false, 2, false, nil, nil, false)

    if info.ent then Caja(info.ent, r, g, b, info.ficha and 255 or 120) end
end
