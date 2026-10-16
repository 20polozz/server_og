-- Ascensores y elevadores de coche de las viviendas (ver config/ascensores.lua
-- y custom/server/ascensores.lua). Son tres cosas:
--  · De mueble a mueble: cabinas y plataformas del catálogo, que el jugador
--    coloca como un mueble más. A pie junto a una cabina, o al volante sobre
--    una plataforma, la E lleva a otra de la casa (se aparece allí).
--  · Elevador de taller: esas mismas plataformas suben y bajan en el sitio el
--    coche que tengan encima.
--  · Ascensor y montacoches de las casas de modalidad libre: una cabina que
--    se mueve de verdad por su hueco (pieza de obra), de planta en planta.
-- Aquí no se decide nada: se pide al servidor y se hace lo que él diga.
local C = Config.Ascensores

local piezas = {}       -- los muebles de la casa en la que se está: { id, zona, clase, entidad, modelo, centro, base, radio }
local casaActual = nil  -- id de esa casa
local ocupado = false   -- a medio viaje o esperando al servidor
local eligiendo = nil   -- con el menú de plantas abierto: { pieza, orden } o { hueco, base }
local menuAjeno = false -- otro menú tiene la pantalla (la cinta de decorar, el radial…)
local conTexto = false
local opciones = nil    -- lo que ofrece el menú pequeño del elevador
local Brazos = {}       -- lo que sube de los elevadores de taller (más abajo)

local TEXTO = {
    persona = 'Usar el ascensor',
    coche = 'Usar el elevador',
    llevar = 'Llevar a otra plataforma',
    subir = 'Subir el coche',
    bajar = 'Bajar el coche',
    subirSolo = 'Subir el elevador',
    bajarSolo = 'Bajar el elevador',
    a = { usar = 'Ascensor', llamar = 'Llamar al ascensor' },
    c = { usar = 'Montacoches', llamar = 'Llamar al montacoches' },
}
local SIN_PAREJA = 'Este ascensor no va a ningún sitio: coloca otra cabina en la casa'

-- La cinta de decorar usa la E para cambiar de categoría y no se le puede
-- preguntar si está abierta; sí avisa, como todos los menús del servidor, de
-- que aparta el HUD. Con un menú en pantalla no se ofrece el ascensor.
-- (el árbitro lo suelta si se queda enganchado: custom/client/tecla_e.lua)
AddEventHandler('origen_housing:sinMenuAjeno', function() menuAjeno = false end)

AddEventHandler('qv2:suppressHud', function(fuera)
    menuAjeno = fuera == true
end)

local function Ajustes(modelo)
    return C.modelos[modelo] or {}
end

-- El cartel y la tecla los lleva el árbitro común (custom/client/tecla_e.lua):
-- aquí solo se ofrece la E, o se retira.
local function Texto(texto)
    if not texto then Tecla.Retirar('ascensores') end
end

local function Fundido(fuera)
    if fuera then
        DoScreenFadeOut(350)
        local t = GetGameTimer()
        while not IsScreenFadedOut() and GetGameTimer() - t < 1000 do Wait(0) end
    else
        DoScreenFadeIn(450)
    end
end

-- ── Los muebles de la casa ──────────────────────────────────────────────
-- La casa en la que está el jugador: dentro de una de módulo o de IPL, o en
-- la parcela de cualquiera (ahí cuentan también los muebles de interior de
-- las casas de interior propio, que están en la calle).
local function Casa()
    local id = currentInteriorHouseID or currentExteriorHouseID
    if not id then return nil end
    local house = House.get(id)
    return house or nil
end

local function Recoger()
    local house = Casa()
    local lista = {}
    casaActual = house and house.id or nil
    if house then
        for zona, muebles in pairs({ interior = house.interiorFurniture, exterior = house.exteriorFurniture }) do
            for id, m in pairs(muebles or {}) do
                local clase = type(m) == 'table' and C.Clase(m.model)
                if clase and m.entity and DoesEntityExist(m.entity) then
                    local min, max = GetModelDimensions(GetEntityModel(m.entity))
                    local a = Ajustes(m.model)
                    local cx, cy = (min.x + max.x) / 2, (min.y + max.y) / 2
                    if a.centro then cx, cy = a.centro[1], a.centro[2] end
                    local centro = GetOffsetFromEntityInWorldCoords(m.entity, cx, cy, 0.0)
                    lista[#lista + 1] = {
                        id = tostring(id), zona = zona, clase = clase, entidad = m.entity, modelo = m.model,
                        centro = centro, base = centro.z + min.z, radio = a.radio or C[clase].radio,
                    }
                end
            end
        end
    end
    piezas = lista
end

-- La pieza de esa clase que tiene `punto` encima (o al lado, con `holgura`).
local function PiezaEn(clase, punto, holgura)
    local mejor, cuanto = nil, nil
    for _, p in ipairs(piezas) do
        if p.clase == clase and DoesEntityExist(p.entidad) then
            local d = #(vector2(punto.x, punto.y) - vector2(p.centro.x, p.centro.y))
            local alto = punto.z - p.base
            -- la altura, para que no salte desde la planta de arriba o la de abajo
            if d <= p.radio + (holgura or 0.0) and alto > -1.0 and alto < 3.2 and (not cuanto or d < cuanto) then
                mejor, cuanto = p, d
            end
        end
    end
    return mejor
end

-- El coche que hay sobre una plataforma (parado encima o ya subido). Se mira
-- como mucho dos veces por segundo: es recorrer todos los vehículos cercanos.
local function CocheSobre(p)
    local ahora = GetGameTimer()
    if p.mirado and ahora - p.mirado < 500 then
        return p.coche and DoesEntityExist(p.coche) and p.coche or nil
    end
    p.mirado, p.coche = ahora, nil
    local cuanto = nil
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local c = GetEntityCoords(veh)
        local d = #(vector2(c.x, c.y) - vector2(p.centro.x, p.centro.y))
        local alto = c.z - p.base
        if d <= p.radio and alto > -1.0 and alto < 5.0 and (not cuanto or d < cuanto) then
            p.coche, cuanto = veh, d
        end
    end
    return p.coche
end

-- Las piezas enlazadas con una (ella incluida): las de su clase y su zona, de
-- abajo arriba. El puesto en esa lista es la planta que se ve en el menú.
local function Enlazadas(pieza)
    local orden = {}
    for _, p in ipairs(piezas) do
        if p.clase == pieza.clase and p.zona == pieza.zona and DoesEntityExist(p.entidad) then orden[#orden + 1] = p end
    end
    table.sort(orden, function(a, b)
        if math.abs(a.base - b.base) > 0.05 then return a.base < b.base end
        return a.id < b.id
    end)
    return orden
end

-- ── De mueble a mueble ──────────────────────────────────────────────────
-- Dónde deja el servidor al jugador, en el mapa. Los muebles de dentro de una
-- casa de módulo se guardan medidos desde el módulo (como en House:LoadFurniture).
local function EnElMapa(house, zona, pos)
    local datos = house.houseData
    if zona == 'interior' and datos and datos.data and datos.data.type == 'shell' and datos.shell and datos.shell.entity
        and DoesEntityExist(datos.shell.entity) and pos.z < 1000.0 then
        return GetOffsetFromEntityInWorldCoords(datos.shell.entity, pos.x + 0.0, pos.y + 0.0, pos.z + 0.0)
    end
    return vector3(pos.x + 0.0, pos.y + 0.0, pos.z + 0.0)
end

-- Punto de llegada: el centro de la pieza de destino y la altura de su piso.
-- El piso se busca con un rayo hacia abajo desde dentro de la pieza (contra el
-- mapa y los objetos), salvo que el modelo lo tenga medido en la configuración.
local function Llegada(origenPieza, rumbo, modelo, ignorar)
    local a = Ajustes(modelo)
    local hash = joaat(modelo)
    local min, max = vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, 0.0)
    if HasModelLoaded(hash) or IsModelInCdimage(hash) then min, max = GetModelDimensions(hash) end
    local cx, cy = (min.x + max.x) / 2, (min.y + max.y) / 2
    if a.centro then cx, cy = a.centro[1], a.centro[2] end
    local r = math.rad(rumbo)
    local x = origenPieza.x + cx * math.cos(r) - cy * math.sin(r)
    local y = origenPieza.y + cx * math.sin(r) + cy * math.cos(r)
    if a.suelo then return vector3(x, y, origenPieza.z + a.suelo) end
    local base = origenPieza.z + min.z
    local rayo = StartExpensiveSynchronousShapeTestLosProbe(x, y, base + 1.3, x, y, base - 1.0, 1 + 16, ignorar or 0, 4)
    local _, toca, punto = GetShapeTestResult(rayo)
    if toca == 1 and punto then return vector3(x, y, punto.z) end
    return vector3(x, y, base + 0.1)
end

local function Viajar(desde, hasta)
    if ocupado then return end
    ocupado = true
    Texto(nil)
    local casa = casaActual
    local house = casa and House.get(casa)
    local res = house and lib.callback.await('origen_housing:ascensores:usar', false, casa, desde.zona, desde.id, hasta.id)
    if type(res) ~= 'table' or not res.ok then
        Custom.Notify(type(res) == 'table' and res.aviso or 'El ascensor no responde', 'error', 4000)
        ocupado = false
        return
    end

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local movido = res.clase == 'coche' and veh or ped
    if res.clase == 'coche' and (veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped) then
        ocupado = false
        return
    end
    -- se llega mirando hacia donde se miraba, contado desde la pieza: si las
    -- dos están puestas igual, se sale como se entró
    local rumbo = (res.rumbo + 0.0) + (GetEntityHeading(movido) - GetEntityHeading(desde.entidad))

    PlaySoundFrontend(-1, 'CLOSING', 'MP_PROPERTIES_ELEVATOR_DOORS', true)
    Fundido(true)
    -- ¿sigue todo en su sitio después del fundido? (se ha podido salir de la casa)
    if casaActual ~= casa or not DoesEntityExist(movido) then
        Fundido(false)
        ocupado = false
        return
    end

    local destino = Llegada(EnElMapa(house, desde.zona, res.pos), res.rumbo + 0.0, res.modelo, movido)
    if res.clase == 'coche' then
        local t = GetGameTimer()
        while not NetworkHasControlOfEntity(veh) and GetGameTimer() - t < 1000 do
            NetworkRequestControlOfEntity(veh)
            Wait(0)
        end
        SetEntityVelocity(veh, 0.0, 0.0, 0.0)
        SetEntityCoordsNoOffset(veh, destino.x, destino.y, destino.z + 1.0, false, false, false)
        SetEntityHeading(veh, rumbo)
        SetVehicleOnGroundProperly(veh)
    else
        SetEntityCoords(ped, destino.x, destino.y, destino.z, false, false, false, false)
        SetEntityHeading(ped, rumbo)
        SetGameplayCamRelativeHeading(0.0)
    end

    local t = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(movido) and GetGameTimer() - t < 3000 do Wait(50) end
    Wait(350)
    if res.clase == 'coche' and DoesEntityExist(veh) then SetVehicleOnGroundProperly(veh) end
    PlaySoundFrontend(-1, 'OPENED', 'MP_PROPERTIES_ELEVATOR_DOORS', true)
    Fundido(false)
    -- que la E no vuelva a salir hasta que el servidor deje viajar otra vez
    SetTimeout(C.ritmo, function() ocupado = false end)
end

local function Usar(pieza)
    local orden = Enlazadas(pieza)
    if #orden < 2 then
        Custom.Notify(SIN_PAREJA, 'info', 4500)
        return
    end
    if #orden == 2 then
        return Viajar(pieza, orden[1] == pieza and orden[2] or orden[1])
    end
    -- tres o más: el menú de plantas del housing
    if IsNuiFocused() then return end
    local plantas, aqui = {}, 0
    for n, p in ipairs(orden) do
        plantas[n] = { planta = n }
        if p == pieza then aqui = n - 1 end
    end
    eligiendo = { pieza = pieza, orden = orden, desde = GetGameTimer() }
    Texto(nil)
    Nui.ToggleElevatorMenu(true, { floors = plantas, floor = aqui })
end

-- Quien va de acompañante en un coche que cambia de plataforma
RegisterNetEvent('origen_housing:ascensores:fundido', function()
    if ocupado or not casaActual or GetVehiclePedIsIn(PlayerPedId(), false) == 0 then return end
    ocupado = true
    Fundido(true)
    Wait(1200)
    Fundido(false)
    ocupado = false
end)

-- ── Elevador de taller ──────────────────────────────────────────────────
-- Pide al servidor subir o bajar el coche que hay sobre la plataforma. Él
-- decide cuál de las dos cosas toca y manda moverlo a quien lo tiene en red.
local function Taller(pieza, coche)
    if ocupado then return end
    local net = coche and DoesEntityExist(coche) and NetworkGetEntityIsNetworked(coche) and NetworkGetNetworkIdFromEntity(coche) or 0
    -- sin coche solo se mueven los que tienen brazos (suben y bajan vacíos)
    if net == 0 and not Brazos.De(pieza) then
        Custom.Notify('Ese vehículo no se puede subir al elevador', 'error', 4000)
        return
    end
    ocupado = true
    Texto(nil)
    local res = lib.callback.await('origen_housing:ascensores:taller', false, casaActual, pieza.zona, pieza.id, net)
    if type(res) ~= 'table' or not res.ok then
        Custom.Notify(type(res) == 'table' and res.aviso or 'El elevador no responde', 'error', 4000)
    end
    SetTimeout(C.taller.ritmo, function() ocupado = false end)
end

-- Lo recibe el cliente que tiene el coche en red: lo congela y lo sube (o lo
-- baja y lo suelta) despacio. Los demás lo ven moverse por la red.
-- `espera`: ms que el coche aguarda quieto antes de subir, mientras los brazos
-- del elevador llegan hasta sus bajos.
RegisterNetEvent('origen_housing:ascensores:taller:mover', function(net, subir, alto, dura, espera)
    alto, dura = tonumber(alto), tonumber(dura)
    espera = math.max(0, math.min(3000, tonumber(espera) or 0))
    if type(net) ~= 'number' or not alto or not dura or alto <= 0.0 or alto > 4.0 or dura < 100 or dura > 20000 then return end
    if not NetworkDoesNetworkIdExist(net) then return end
    local veh = NetworkGetEntityFromNetworkId(net)
    if not veh or veh == 0 or not DoesEntityExist(veh) or GetEntityType(veh) ~= 2 then return end
    SetEntityVelocity(veh, 0.0, 0.0, 0.0)
    FreezeEntityPosition(veh, true)
    local p = GetEntityCoords(veh)
    local hasta = p.z + (subir and alto or -alto)
    local t0 = GetGameTimer() + espera
    PlaySoundFrontend(-1, 'CLOSING', 'MP_PROPERTIES_ELEVATOR_DOORS', true)
    while DoesEntityExist(veh) do
        local u = math.max(0.0, math.min(1.0, (GetGameTimer() - t0) / dura))
        local s = u * u * (3.0 - 2.0 * u)       -- arranca y frena suave
        SetEntityCoordsNoOffset(veh, p.x, p.y, p.z + (hasta - p.z) * s, false, false, false)
        if u >= 1.0 then break end
        Wait(0)
    end
    if not subir and DoesEntityExist(veh) then
        FreezeEntityPosition(veh, false)
        SetVehicleOnGroundProperly(veh)
    end
end)

-- ── Lo que sube de los elevadores de taller ─────────────────────────────
-- Los elevadores propios (Config.Ascensores.modelos, los que llevan `brazos`)
-- son dos modelos: el mueble, que es lo fijo, y lo que sube (los brazos, la
-- bandeja o las pistas), que es un objeto LOCAL que pone cada cliente sobre
-- el mueble y mueve cada fotograma con el aviso del servidor. Algunos llevan
-- además piezas sueltas (las barras de la tijera), que se colocan según la
-- altura. Aquí no se decide nada: quién sube, cuánto y cuándo lo dice el servidor.
local elevadores = {}   -- 'zona:id' → { clave, casa, pieza, ajustes, modelo, ent, piezas, est, mueve, sinEstado, choca, ultima, pegado }

local function Suave(u)
    if u <= 0.0 then return 0.0 end
    if u >= 1.0 then return 1.0 end
    return u * u * (3.0 - 2.0 * u)      -- la misma curva con la que sube el coche
end

-- A qué altura sobre el suelo del mueble está ahora la cara de apoyo; si ha
-- terminado de moverse; y si en este momento el coche va con ella.
-- Con coche y levantando por los bajos hay dos tiempos: los brazos van solos
-- del reposo a los bajos (`espera` ms) y luego suben los dos a la par; al
-- bajar, al revés. `c` es la altura de los bajos con el coche en el suelo.
local function AlturaBrazos(b)
    local reposo, e = b.ajustes.reposo + 0.0, b.est
    if not e then return reposo, true, false end
    local c = e.c or reposo
    local t = GetGameTimer() - e.inicio
    if e.arriba then
        if t >= e.espera + e.dura then return c + e.alto, true, false end
        if t < e.espera then return reposo + (c - reposo) * Suave(t / e.espera), false, false end
        return c + e.alto * Suave((t - e.espera) / e.dura), false, true
    end
    if t >= e.dura + e.espera then return reposo, true, false end
    if t < e.dura then return c + e.alto * (1.0 - Suave(t / e.dura)), false, true end
    return c + (reposo - c) * Suave((t - e.dura) / e.espera), false, false
end

-- Pone los brazos y sus piezas donde toca, sobre el mueble (si este se mueve
-- con el gizmo, le siguen). Solo toca lo que ha cambiado de sitio: recolocar
-- cada vez una bandeja con un coche encima lo haría botar.
local function ColocarBrazos(b)
    local m = b.pieza and b.pieza.entidad
    if not m or not DoesEntityExist(m) then return nil end
    local h, quieto, juntos = AlturaBrazos(b)
    local p, r = GetOffsetFromEntityInWorldCoords(m, 0.0, 0.0, h), GetEntityRotation(m, 2)
    local u = b.ultima
    if u and #(u.p - p) < 0.0005 and #(u.r - r) < 0.01 then return h, quieto, juntos end
    b.ultima = { p = p, r = r }
    if b.ent and DoesEntityExist(b.ent) then
        SetEntityCoordsNoOffset(b.ent, p.x, p.y, p.z, false, false, false)
        SetEntityRotation(b.ent, r.x, r.y, r.z, 2, false)
        -- los que levantan por los bajos no chocan abajo: el coche tiene que pasarles por encima
        local choca = b.ajustes.apoyo ~= 'bajos' or h > b.ajustes.reposo + 0.5
        if b.choca ~= choca then
            b.choca = choca
            SetEntityCollision(b.ent, choca, choca)
        end
    end
    for _, q in ipairs(b.piezas or {}) do
        if DoesEntityExist(q.ent) then
            -- tijera: el centro de la barra a media altura, y tanto más inclinada cuanto más arriba
            local d = q.def
            local c = GetOffsetFromEntityInWorldCoords(m, d.x + 0.0, d.y + 0.0, h / 2)
            local abre = math.deg(math.asin(math.max(0.0, math.min(1.0, (h - 2 * d.eje) / d.largo))))
            SetEntityCoordsNoOffset(q.ent, c.x, c.y, c.z, false, false, false)
            SetEntityRotation(q.ent, abre * (d.giro or 1), 0.0, r.z, 2, false)
        end
    end
    return h, quieto, juntos
end

-- El coche, mientras sube o baja: lo que se ve es un doble local pegado a los
-- brazos, que va con ellos fotograma a fotograma. El de verdad lo mueve quien
-- lo tiene en red (a los demás les llega a saltitos) y entretanto se esconde.
-- Al parar, el doble se quita cuando el de verdad ha llegado a su altura.
local function DobleDeCoche(veh)
    local modelo = GetEntityModel(veh)
    if not HasModelLoaded(modelo) then return nil end
    local q = GetEntityCoords(veh)
    local doble = CreateVehicle(modelo, q.x, q.y, q.z, GetEntityHeading(veh), false, false)
    if not doble or doble == 0 then return nil end
    SetEntityCollision(doble, false, false)
    FreezeEntityPosition(doble, true)
    SetEntityInvincible(doble, true)
    SetVehicleDoorsLocked(doble, 2)
    SetVehicleEngineOn(doble, false, true, true)
    Entity(doble).state:set('origenDoble', true, false)
    local ok, datos = pcall(lib.getVehicleProperties, veh)
    if ok and datos then
        datos.plate, datos.fuelLevel = nil, nil
        pcall(lib.setVehicleProperties, doble, datos)
    end
    return doble
end

local function SoltarCoche(b)
    local c = b.pegado
    b.pegado, b.soltando = nil, nil
    if c and c.doble and DoesEntityExist(c.doble) then DeleteEntity(c.doble) end
end

local function LlevarCoche(b, juntos)
    local e = b.est
    if not C.taller.cochesAjenos or not e or not e.net or e.tarde then return end
    if juntos and not e.mirado then
        e.mirado = true
        local veh = NetworkDoesNetworkIdExist(e.net) and NetworkGetEntityFromNetworkId(e.net) or 0
        if veh ~= 0 and DoesEntityExist(veh) and GetEntityType(veh) == 2 and b.ent and DoesEntityExist(b.ent) then
            SoltarCoche(b)
            local doble = DobleDeCoche(veh)
            if doble then
                local p, r = GetEntityCoords(veh), GetEntityRotation(veh, 2)
                local d = GetOffsetFromEntityGivenWorldCoords(b.ent, p.x, p.y, p.z)
                AttachEntityToEntity(doble, b.ent, 0, d.x, d.y, d.z, r.x, r.y, GetEntityHeading(veh) - GetEntityHeading(b.ent),
                    false, false, false, false, 2, true)
                b.pegado = { real = veh, doble = doble }
            end
        end
    end
    local c = b.pegado
    if not c then return end
    if DoesEntityExist(c.real) then SetEntityLocallyInvisible(c.real) end
    if not juntos and not b.soltando then
        b.soltando = true
        local desde = GetGameTimer()
        CreateThread(function()
            while b.pegado == c do
                local lleva = GetGameTimer() - desde
                local hay = DoesEntityExist(c.real) and DoesEntityExist(c.doble)
                if not hay or lleva > 3000
                    or (lleva >= C.taller.soltar and math.abs(GetEntityCoords(c.real).z - GetEntityCoords(c.doble).z) < 0.04) then
                    SoltarCoche(b)
                    return
                end
                SetEntityLocallyInvisible(c.real)
                Wait(0)
            end
        end)
    end
end

local function QuitarBrazos(clave)
    local b = elevadores[clave]
    if not b then return end
    SoltarCoche(b)
    if b.ent and DoesEntityExist(b.ent) then DeleteEntity(b.ent) end
    for _, q in ipairs(b.piezas or {}) do
        if DoesEntityExist(q.ent) then DeleteEntity(q.ent) end
    end
    elevadores[clave] = nil
end

function Brazos.QuitarTodos()
    local claves = {}
    for clave in pairs(elevadores) do claves[#claves + 1] = clave end
    for _, clave in ipairs(claves) do QuitarBrazos(clave) end
end

local function CargarModelo(nombre)
    local modelo = joaat(nombre)
    if not IsModelInCdimage(modelo) then return nil end
    RequestModel(modelo)
    local t = GetGameTimer()
    while not HasModelLoaded(modelo) and GetGameTimer() - t < 4000 do Wait(20) end
    return HasModelLoaded(modelo) and modelo or nil
end

-- Crea lo que sube de un elevador, y sus piezas sueltas. Si algún modelo no
-- está todavía en el cliente no pasa nada: se vuelve a intentar en el
-- siguiente repaso.
local function CrearBrazos(b)
    local function vale()
        return elevadores[b.clave] == b and b.pieza and DoesEntityExist(b.pieza.entidad)
    end
    if not (b.ent and DoesEntityExist(b.ent)) then
        local modelo = CargarModelo(b.modelo)
        if not modelo then return end
        if not vale() or (b.ent and DoesEntityExist(b.ent)) then
            SetModelAsNoLongerNeeded(modelo)
            return
        end
        local p = GetEntityCoords(b.pieza.entidad)
        local e = CreateObjectNoOffset(modelo, p.x, p.y, p.z + b.ajustes.reposo, false, false, false)
        SetModelAsNoLongerNeeded(modelo)
        if not e or e == 0 then return end
        FreezeEntityPosition(e, true)
        b.ent, b.choca, b.ultima = e, nil, nil
    end
    if b.ajustes.piezas and not b.piezas then
        -- o todas o ninguna
        local modelos = {}
        for n, d in ipairs(b.ajustes.piezas) do
            modelos[n] = CargarModelo(d.modelo)
            if not modelos[n] then return end
        end
        if not vale() or b.piezas then return end
        local p = GetEntityCoords(b.pieza.entidad)
        local lista = {}
        for n, d in ipairs(b.ajustes.piezas) do
            local e = CreateObjectNoOffset(modelos[n], p.x, p.y, p.z, false, false, false)
            if e and e ~= 0 then
                SetEntityCollision(e, false, false)
                FreezeEntityPosition(e, true)
                lista[#lista + 1] = { ent = e, def = d }
            end
        end
        for n in ipairs(b.ajustes.piezas) do SetModelAsNoLongerNeeded(modelos[n]) end
        b.piezas, b.ultima = lista, nil
    end
end

-- A qué altura quedan los bajos del coche sobre el suelo del mueble: un rayo
-- hacia arriba desde cada taco, solo contra vehículos, y se toma el más bajo.
-- `subido`: lo que ya está levantado el coche (para quien llega con él arriba).
local function Contacto(b, subido)
    local a = b.ajustes
    local m = b.pieza and b.pieza.entidad
    local mejor = nil
    if m and DoesEntityExist(m) then
        for _, t in ipairs(a.tacos or {}) do
            local de = GetOffsetFromEntityInWorldCoords(m, t[1] + 0.0, t[2] + 0.0, 0.02)
            local hasta = GetOffsetFromEntityInWorldCoords(m, t[1] + 0.0, t[2] + 0.0, subido + 1.2)
            local rayo = StartExpensiveSynchronousShapeTestLosProbe(de.x, de.y, de.z, hasta.x, hasta.y, hasta.z, 2, b.ent or 0, 4)
            local _, toca, punto = GetShapeTestResult(rayo)
            if toca == 1 and punto then
                local c = #(punto - de) + 0.02 - subido
                -- por debajo de 7 cm es una rueda, no los bajos
                if c >= 0.07 and c <= 0.7 and (not mejor or c < mejor) then mejor = c end
            end
        end
    end
    return math.max(a.reposo + 0.0, mejor or a.contacto or 0.2)
end

-- Los números de una orden del servidor, en su sitio, o nada
local function Orden(alto, dura, espera, lleva, net)
    alto, dura, espera, lleva, net = tonumber(alto), tonumber(dura), tonumber(espera), tonumber(lleva), tonumber(net)
    if not alto or not dura or not espera or not lleva or not net then return nil end
    if alto <= 0.0 or alto > 4.0 or dura < 100 or dura > 20000 or espera < 0 or espera > 3000 or net < 0 then return nil end
    return alto + 0.0, math.floor(dura), math.floor(espera), math.max(0, math.floor(lleva)), math.floor(net)
end

-- Empieza a subir o a bajar (o, si `lleva` ya pasa de lo que dura, se queda
-- como dice el servidor: es lo que le toca a quien entra con él ya movido).
local function EmpezarBrazos(b, arriba, alto, dura, espera, lleva, net)
    SoltarCoche(b)
    local antes = b.est
    local total = dura + espera
    local e = { arriba = arriba, alto = alto, dura = dura, espera = espera, inicio = GetGameTimer() - lleva, net = net ~= 0 and net or nil,
        tarde = lleva > 300 }
    b.sinEstado = nil
    if e.net and b.ajustes.apoyo == 'bajos' then
        if not arriba and antes and antes.arriba and antes.c and not antes.aprox then
            e.c = antes.c                                   -- baja de donde lo subió
        elseif not e.tarde then
            e.c = Contacto(b, arriba and 0.0 or alto)
        elseif arriba and lleva >= total then
            e.c = Contacto(b, alto)
        else
            -- a medio camino no se puede medir: lo normal, y al llegar arriba se ajusta
            e.c = math.max(b.ajustes.reposo + 0.0, b.ajustes.contacto or 0.2)
            e.aprox = arriba
        end
    end
    b.est = (arriba or lleva < total) and e or nil
    b.mueve = lleva < total
    b.ultima = nil
    if not e.tarde and not e.net and b.pieza and #(GetEntityCoords(PlayerPedId()) - b.pieza.centro) < 15.0 then
        PlaySoundFrontend(-1, 'CLOSING', 'MP_PROPERTIES_ELEVATOR_DOORS', true)
    end
    ColocarBrazos(b)
end

-- El elevador con brazos de un mueble, si ya está puesto en este cliente
function Brazos.De(pieza)
    return pieza and elevadores[pieza.zona .. ':' .. pieza.id] or nil
end

function Brazos.Arriba(b)
    return b.est ~= nil and b.est.arriba == true
end

-- ¿Está ese personaje junto a los mandos del elevador?
function Brazos.EnMandos(b, ped)
    local m = b.pieza and b.pieza.entidad
    if not m or not DoesEntityExist(m) then return false end
    local donde = b.ajustes.mandos or { 0.0, 0.0 }
    local p, yo = GetOffsetFromEntityInWorldCoords(m, donde[1] + 0.0, donde[2] + 0.0, 0.0), GetEntityCoords(ped)
    return #(vector2(p.x, p.y) - vector2(yo.x, yo.y)) <= C.taller.radioMandos and yo.z - p.z > -0.5 and yo.z - p.z < 2.5
end

-- Pone los elevadores al día con los muebles de la casa (cada segundo, tras
-- Recoger): crea los que faltan, quita los de los muebles que ya no están y
-- pregunta al servidor cómo están los nuevos.
function Brazos.Repasar()
    local vistos = {}
    for _, p in ipairs(piezas) do
        local a = C.modelos[p.modelo]
        if a and a.brazos then
            local clave = p.zona .. ':' .. p.id
            vistos[clave] = true
            local b = elevadores[clave]
            if b and (b.casa ~= casaActual or b.modelo ~= a.brazos) then
                QuitarBrazos(clave)
                b = nil
            end
            if not b then
                b = { clave = clave, casa = casaActual, modelo = a.brazos, ajustes = a, sinEstado = true }
                elevadores[clave] = b
            end
            b.pieza = p
        end
    end
    local lista, sobran = {}, {}
    for clave, b in pairs(elevadores) do
        if vistos[clave] then lista[#lista + 1] = b else sobran[#sobran + 1] = clave end
    end
    for _, clave in ipairs(sobran) do QuitarBrazos(clave) end

    local falta = false
    for _, b in ipairs(lista) do
        if elevadores[b.clave] == b then
            CrearBrazos(b)
            if elevadores[b.clave] == b then
                if not b.mueve then ColocarBrazos(b) end
                if b.sinEstado then falta = true end
            end
        end
    end
    if not falta or not casaActual then return end

    local casa = casaActual
    local estado = lib.callback.await('origen_housing:ascensores:taller:estado', false, casa)
    if casaActual ~= casa or type(estado) ~= 'table' then return end     -- sin respuesta: se pregunta en el siguiente repaso
    for clave, b in pairs(elevadores) do
        if b.sinEstado and b.casa == casa then
            b.sinEstado = nil
            local e = estado[clave]
            if type(e) == 'table' then
                local alto, dura, espera, lleva, net = Orden(e.alto, e.dura, e.espera, e.lleva, e.net)
                if alto then EmpezarBrazos(b, e.arriba == true, alto, dura, espera, lleva, net) end
            end
        end
    end
end

-- El servidor avisa a todos los de la casa de que un elevador sube o baja
RegisterNetEvent('origen_housing:ascensores:taller:brazos', function(casa, clave, arriba, alto, dura, espera, lleva, net)
    if not casaActual or tostring(casa) ~= tostring(casaActual) or type(clave) ~= 'string' then return end
    local b = elevadores[clave]
    if not b then return end      -- todavía no está puesto aquí: se preguntará al crearlo
    alto, dura, espera, lleva, net = Orden(alto, dura, espera, lleva, net)
    if not alto then return end
    EmpezarBrazos(b, arriba == true, alto, dura, espera, lleva, net)
end)

-- Los que están en marcha, cada fotograma; y todos mientras se decora, para
-- que sigan al mueble que se está moviendo con el gizmo.
CreateThread(function()
    while true do
        local espera = 300
        local decorando = Furniture and Furniture.active
        for _, b in pairs(elevadores) do
            if b.mueve or decorando then
                espera = 0
                local _, quieto, juntos = ColocarBrazos(b)
                if b.mueve then
                    LlevarCoche(b, juntos == true)
                    if quieto then
                        b.mueve = false
                        local e = b.est
                        if e and e.aprox then
                            e.aprox = nil
                            e.c = Contacto(b, e.alto)
                            b.ultima = nil
                            ColocarBrazos(b)
                        end
                        if e and not e.arriba then b.est = nil end
                    end
                end
            end
        end
        Wait(espera)
    end
end)

-- Con más de una cosa que hacer en la misma plataforma, el menú pequeño del
-- servidor (org-menu) en vez de repartir teclas.
local function MenuElevador(lista)
    if GetResourceState('org-menu') ~= 'started' then return lista[1].hacer() end
    opciones = lista
    local menu = { { header = 'Elevador', txt = 'Qué quieres hacer con el coche', isMenuHeader = true } }
    for n, o in ipairs(lista) do
        menu[#menu + 1] = { header = o.texto, txt = o.detalle, params = { event = 'origen_housing:ascensores:opcion', args = n } }
    end
    exports['org-menu']:openMenu(menu)
end

AddEventHandler('origen_housing:ascensores:opcion', function(n)
    local o = opciones and opciones[tonumber(n)]
    opciones = nil
    if o and not ocupado then o.hacer() end
end)

-- ── Ascensor y montacoches con movimiento (casas de modalidad libre) ────
-- Cada hueco de la obra (pieza a:… o c:…) tiene una cabina: un objeto local
-- en cada cliente, que todos mueven igual a partir del aviso del servidor.
local O = Config.Obra
local huecos = {}       -- clave de la pieza → { clave, tipo, i0, i1, j0, j1, k, n, g, x, y, z0, planta, entidad, puesto, pistones, viaje, ocultos, pegados, carga, sinEstado }
local casaObra = nil    -- id (texto) de la obra a la que pertenecen
local montado = nil     -- el hueco a cuya cabina va pegado el jugador
local sincronizando = false

local function ObraActual()
    if not Obra or not Obra.Actual then return nil end
    local ok, o = pcall(Obra.Actual)
    return ok and type(o) == 'table' and o.o and o or nil
end

-- Centro del suelo de una celda (la cara de arriba de la losa)
local function Suelo(o, i, j, k)
    if Obra.Mundo then
        local ok, p = pcall(Obra.Mundo, i, j, k)
        if ok and p then return p end
    end
    return o.o + vector3(i * O.celda, j * O.celda + O.celda / 2, k * O.planta)
end

-- Celda y planta en las que está algo (la misma cuenta que hace el servidor)
local function CeldaDe(o, p)
    local d = p - o.o
    return math.floor(d.x / O.celda + 0.5), math.floor((d.y - O.celda / 2) / O.celda + 0.5), O.PlantaDe(d.z)
end

local function AlturaDe(h, planta)
    return h.z0 + (planta - h.k) * O.planta
end

-- A qué altura está ahora la cabina, y si el viaje ha terminado
local function Altura(h)
    local v = h.viaje
    if not v then return AlturaDe(h, h.planta), true end
    local plantas = math.abs(v.a - v.de)
    -- la cabina cerrada espera parada a que cierren las puertas (C.Espera, lo mismo que cuenta el servidor)
    local t = (GetGameTimer() - v.inicio - C.Espera(h)) / 1000
    if t >= C.Duracion(plantas) then return AlturaDe(h, v.a), true end
    local sentido = v.a > v.de and 1.0 or -1.0
    return AlturaDe(h, v.de) + sentido * C.Recorrido(plantas * O.planta, t), false
end

-- ¿Está ese punto sobre la cabina? `pies`: lo que hay del punto a su apoyo
-- (un personaje mide su posición a media altura; un coche, casi en el suelo).
-- `holgura`: metros de más, para los que se ven por la red con algo de retraso.
local function Sobre(h, p, z, pies, holgura)
    holgura = holgura or 0.0
    local mx, my = (h.i1 - h.i0 + 1) * O.celda / 2 + holgura, (h.j1 - h.j0 + 1) * O.celda / 2 + holgura
    if math.abs(p.x - h.x) > mx or math.abs(p.y - h.y) > my then return false end
    local alto = p.z - pies - z
    return alto > -0.6 - holgura and alto < 1.6 + holgura
end

-- Quita (o repone) el suelo de una planta en todas las celdas del hueco
local function Tapar(h, planta, quitar)
    if (h.ocultos[planta] or false) == quitar then return end
    h.ocultos[planta] = quitar or nil
    if not Obra or not Obra.Ocultar then return end
    for i = h.i0, h.i1 do
        for j = h.j0, h.j1 do
            pcall(Obra.Ocultar, ('l:%d:%d:%d'):format(i, j, planta), quitar)
        end
    end
end

-- Pega algo (un personaje o un coche) a la cabina, donde estaba y mirando a
-- donde miraba. Va pegado en ESTE cliente: cada uno lleva a todos los que
-- viajan en su propia cabina, y así nadie depende de la red para verlos subir.
local function Pegar(h, p)
    AttachEntityToEntity(p.ent, h.entidad, 0, p.d.x, p.d.y, p.d.z, p.rx, p.ry, p.rz, false, false, false, false, 2, true)
end

local function Apuntar(h, ent, mio)
    local p, r = GetEntityCoords(ent), GetEntityRotation(ent, 2)
    local esPed = IsEntityAPed(ent)
    -- El personaje de otro jugador no se deja pegar aquí: manda su posición de
    -- red, que llega a saltos y con retraso (se le veía colgando bajo la cabina).
    -- Mientras dura el viaje se esconde el de verdad y se enseña un doble local,
    -- que sí va pegado a la cabina y sube con ella sin un tirón.
    local real
    if esPed and not mio then
        local doble = ClonePed(ent, false, false, true)
        if doble and doble ~= 0 then
            SetEntityCoordsNoOffset(doble, p.x, p.y, p.z, false, false, false)
            SetEntityHeading(doble, GetEntityHeading(ent))
            SetEntityInvincible(doble, true)
            SetBlockingOfNonTemporaryEvents(doble, true)
            SetEntityCollision(doble, false, false)
            SetPedCanRagdoll(doble, false)
            real, ent = ent, doble
        end
    end
    local pegado = {
        ent = ent, mio = mio, real = real,
        d = GetOffsetFromEntityGivenWorldCoords(h.entidad, p.x, p.y, p.z),
        rx = esPed and 0.0 or r.x, ry = esPed and 0.0 or r.y,
        rz = GetEntityHeading(ent) - GetEntityHeading(h.entidad),
    }
    h.pegados[#h.pegados + 1] = pegado
    Pegar(h, pegado)
end

-- Suelta a los que iban pegados. El jugador de este cliente, en el momento.
-- Los demás, un poco después (salvo `ya`): al soltarlos vuelven a su posición
-- de red, y recién llegados todavía puede venir con retraso y dar un salto.
local function Soltar(h, ya)
    local lista = h.pegados
    h.pegados = nil
    if montado == h then montado = nil end
    if not lista then return end
    local function suelta(p)
        if p.real then
            if DoesEntityExist(p.ent) then DeleteEntity(p.ent) end
        elseif DoesEntityExist(p.ent) and IsEntityAttached(p.ent) then
            DetachEntity(p.ent, true, true)
        end
    end
    local luego = {}
    for _, p in ipairs(lista) do
        if p.mio or ya then suelta(p) else luego[#luego + 1] = p end
    end
    if #luego > 0 then
        -- Los de verdad siguen escondidos hasta que se quita su doble, y el doble
        -- no se quita hasta que el de verdad ha llegado por la red a la altura
        -- de la cabina (o pasan tres segundos): así no se le ve subir tarde.
        local desde = GetGameTimer()
        CreateThread(function()
            local quedan = #luego
            while quedan > 0 do
                local lleva = GetGameTimer() - desde
                quedan = 0
                for _, p in ipairs(luego) do
                    if not p.suelto then
                        local hay = p.real and DoesEntityExist(p.real) and DoesEntityExist(p.ent)
                        local llego = hay and math.abs(GetEntityCoords(p.real).z - GetEntityCoords(p.ent).z) < 0.25
                        if not p.real or not hay or lleva > 3000 or (lleva >= C.cabina.soltar and llego) then
                            p.suelto = true
                            suelta(p)
                        else
                            SetEntityLocallyInvisible(p.real)
                            quedan = quedan + 1
                        end
                    end
                end
                Wait(0)
            end
        end)
    end
end

-- Los cilindros del montacoches, a la altura que toca con la plataforma en z:
-- el extremo de arriba del tramo s, a s partes de las `de` que hay.
local function ColocarPistones(h, z)
    if not h.pistones then return end
    local sube = z - h.z0
    for _, p in ipairs(h.pistones) do
        if DoesEntityExist(p.ent) then
            SetEntityCoordsNoOffset(p.ent, h.x + p.dx, h.y + p.dy, h.z0 + sube * p.s / p.de - C.cabina.pistones.bajo, false, false, false)
        end
    end
end

-- Suelta los coches que llevaba la plataforma, bien apoyados
local function Descargar(h)
    for _, c in ipairs(h.carga or {}) do
        if DoesEntityExist(c.veh) then
            FreezeEntityPosition(c.veh, false)
            SetVehicleOnGroundProperly(c.veh)
        end
    end
    h.carga = nil
end

-- ── Las puertas de la cabina cerrada ────────────────────────────────────
-- Dos hojas correderas en el frente (objetos locales, sin colisión) y, detrás
-- de ellas, una barrera que no se ve y que solo choca mientras dura el viaje.
-- No van pegadas a la cabina: se recolocan con ella, en el mismo fotograma.
-- Cuánto están abiertas sale del reloj del viaje, así que van a la par en
-- todos los clientes: se cierran al arrancar (lo que el viaje espera), van
-- cerradas todo el camino y se abren al llegar. En reposo, abiertas.

-- De 0 (cerradas) a 1 (abiertas)
local function Abertura(h)
    local ms = math.max(1, C.Espera(h))
    if h.viaje then return 1.0 - Suave((GetGameTimer() - h.viaje.inicio) / ms) end
    if h.abre then
        local u = (GetGameTimer() - h.abre) / ms
        if u < 1.0 then return Suave(u) end
        h.abre = nil
    end
    return 1.0
end

-- Pone las hojas y la barrera donde toca, con la cabina a la altura z
local function ColocarPuertas(h, z)
    local p = h.puertas
    if not p then return end
    local D = p.def
    local r = math.rad(h.giro)
    local c, s = math.cos(r), math.sin(r)
    local x = D.cerrada + (D.abierta - D.cerrada) * Abertura(h)
    for n, ent in ipairs(p.hojas) do
        if DoesEntityExist(ent) then
            local lx = n == 1 and -x or x
            SetEntityCoordsNoOffset(ent, h.x + lx * c - D.y * s, h.y + lx * s + D.y * c, z, false, false, false)
        end
    end
    local choca = h.viaje ~= nil
    for _, b in ipairs(p.barrera) do
        if DoesEntityExist(b.ent) then
            SetEntityCoordsNoOffset(b.ent, h.x + b.x * c - b.y * s, h.y + b.x * s + b.y * c, z, false, false, false)
            if p.choca ~= choca then SetEntityCollision(b.ent, choca, choca) end
        end
    end
    p.choca = choca
end

local function QuitarPuertas(h)
    local p = h.puertas
    h.puertas, h.abre = nil, nil
    if not p then return end
    for _, ent in ipairs(p.hojas) do
        if DoesEntityExist(ent) then DeleteEntity(ent) end
    end
    for _, b in ipairs(p.barrera) do
        if DoesEntityExist(b.ent) then DeleteEntity(b.ent) end
    end
end

-- Deja la cabina quieta en su planta, con todos los suelos en su sitio
local function Aparcar(h, ya)
    local viajaba = h.viaje ~= nil
    h.viaje = nil
    for planta in pairs(h.ocultos) do Tapar(h, planta, false) end
    if h.entidad and DoesEntityExist(h.entidad) then
        SetEntityCoordsNoOffset(h.entidad, h.x, h.y, AlturaDe(h, h.planta), false, false, false)
    end
    if h.puertas then
        -- recién llegada, las puertas se abren (las mueve el bucle de las cabinas en marcha)
        h.abre = viajaba and not ya and GetGameTimer() or nil
        ColocarPuertas(h, AlturaDe(h, h.planta))
    end
    ColocarPistones(h, AlturaDe(h, h.planta))
    Soltar(h, ya)
    Descargar(h)
end

local function Quitar(clave)
    local h = huecos[clave]
    if not h then return end
    Aparcar(h, true)
    QuitarPuertas(h)
    if h.entidad and DoesEntityExist(h.entidad) then DeleteEntity(h.entidad) end
    for _, p in ipairs(h.pistones or {}) do
        if DoesEntityExist(p.ent) then DeleteEntity(p.ent) end
    end
    h.pistones = nil
    huecos[clave] = nil
end

local function QuitarTodos()
    local claves = {}
    for clave in pairs(huecos) do claves[#claves + 1] = clave end
    for _, clave in ipairs(claves) do Quitar(clave) end
    casaObra = nil
end

-- Crea la cabina de un hueco. Si el modelo todavía no está en el cliente no
-- pasa nada: se vuelve a intentar en el siguiente repaso.
local function ModeloDe(h)
    for _, nombre in ipairs(h.modelos) do
        if IsModelInCdimage(joaat(nombre)) then return nombre end
    end
    return nil
end

local function Crear(h)
    local nombre = ModeloDe(h)
    if not nombre then return end
    local modelo = joaat(nombre)
    RequestModel(modelo)
    local t = GetGameTimer()
    while not HasModelLoaded(modelo) and GetGameTimer() - t < 4000 do Wait(20) end
    if not HasModelLoaded(modelo) or huecos[h.clave] ~= h or (h.entidad and DoesEntityExist(h.entidad)) then return end
    local z = Altura(h)
    local e = CreateObjectNoOffset(modelo, h.x, h.y, z, false, false, false)
    SetModelAsNoLongerNeeded(modelo)
    if not e or e == 0 then return end
    SetEntityHeading(e, h.giro)
    FreezeEntityPosition(e, true)
    h.entidad, h.puesto = e, nombre
end

-- Las puertas de una cabina cerrada: las dos hojas y la barrera del frente.
-- Solo si la cabina puesta es la cerrada (con la de reserva no hay puertas).
-- Lo que falte por no tener aún el modelo se vuelve a intentar en cada repaso.
local function CrearPuertas(h)
    local D = h.cerrada
    if not D or h.puesto ~= D.modelo or not (h.entidad and DoesEntityExist(h.entidad)) then return end
    local p = h.puertas
    if not p then
        p = { def = D, hojas = {}, barrera = {} }
        h.puertas = p
    end
    local function vale()
        return huecos[h.clave] == h and h.puertas == p and h.entidad and DoesEntityExist(h.entidad)
    end
    local nuevo = false
    if #p.hojas == 0 and D.hoja then
        local modelo = CargarModelo(D.hoja)
        if modelo then
            if vale() and #p.hojas == 0 then
                for n = 1, 2 do
                    local e = CreateObjectNoOffset(modelo, h.x, h.y, h.z0, false, false, false)
                    if e and e ~= 0 then
                        SetEntityHeading(e, h.giro)
                        SetEntityCollision(e, false, false)
                        FreezeEntityPosition(e, true)
                        p.hojas[#p.hojas + 1] = e
                    end
                end
                nuevo = true
            end
            SetModelAsNoLongerNeeded(modelo)
        end
    end
    local B = C.cabina.cerrada.barrera
    if not p.conBarrera and type(B) == 'table' and B.modelo and vale() then
        local modelo = CargarModelo(B.modelo)
        if modelo then
            if vale() and not p.conBarrera then
                p.conBarrera = true
                local largo = math.max(0.5, B.largo or 2.0)
                local trozos = math.max(1, math.ceil(((B.ancho and B.ancho[h.g]) or largo) / largo - 0.01))
                for n = 1, trozos do
                    local e = CreateObjectNoOffset(modelo, h.x, h.y, h.z0, false, false, false)
                    if e and e ~= 0 then
                        SetEntityHeading(e, h.giro)
                        SetEntityVisible(e, false, false)
                        SetEntityCollision(e, false, false)
                        FreezeEntityPosition(e, true)
                        p.barrera[#p.barrera + 1] = { ent = e, x = (n - (trozos + 1) / 2) * largo, y = (B.y or D.y) + 0.0 }
                    end
                end
                p.choca = nil
                nuevo = true
            end
            SetModelAsNoLongerNeeded(modelo)
        end
    end
    if nuevo and vale() then ColocarPuertas(h, (Altura(h))) end
end

-- Los cuatro cilindros de un montacoches. O todos o ninguno: si falta algún
-- modelo de tramo se deja para el siguiente repaso.
local function CrearPistones(h)
    if h.tipo ~= 'c' or h.pistones then return end
    local P = C.cabina.pistones
    local tramos = math.min(h.n - 1, #P.modelos)
    local modelos = {}
    for s = 1, tramos do
        modelos[s] = joaat(P.modelos[s])
        if not IsModelInCdimage(modelos[s]) then return end
    end
    for s = 1, tramos do
        RequestModel(modelos[s])
        local t = GetGameTimer()
        while not HasModelLoaded(modelos[s]) and GetGameTimer() - t < 4000 do Wait(20) end
        if not HasModelLoaded(modelos[s]) then return end
    end
    if huecos[h.clave] ~= h or h.pistones then return end
    local lista = {}
    local r = math.rad(h.giro)
    for _, plato in ipairs(P.platos) do
        -- los platos giran con la plataforma
        local dx = plato[1] * math.cos(r) - plato[2] * math.sin(r)
        local dy = plato[1] * math.sin(r) + plato[2] * math.cos(r)
        for s = 1, tramos do
            local e = CreateObjectNoOffset(modelos[s], h.x + dx, h.y + dy, h.z0, false, false, false)
            if e and e ~= 0 then
                SetEntityCollision(e, false, false)
                FreezeEntityPosition(e, true)
                lista[#lista + 1] = { ent = e, s = s, de = tramos, dx = dx, dy = dy }
            end
        end
    end
    for s = 1, tramos do SetModelAsNoLongerNeeded(modelos[s]) end
    h.pistones = lista
    ColocarPistones(h, (Altura(h)))
end

-- Pone los huecos al día con la obra: cabinas para los que hay, fuera las de
-- los que ya no están, y el estado del servidor para los nuevos.
local function Repasar()
    local o = ObraActual()
    if not o then
        if next(huecos) then QuitarTodos() end
        return
    end
    local id = tostring(o.id)
    if casaObra ~= id then
        QuitarTodos()
        casaObra = id
    end

    local hay, falta = {}, false
    for clave, valor in pairs(o.piezas or {}) do
        local h = C.Hueco(clave, valor)
        if h then
            hay[clave] = true
            local viejo = huecos[clave]
            if viejo and (viejo.n ~= h.n or viejo.g ~= h.g or viejo.e ~= h.e) then
                Quitar(clave)
                viejo = nil
            end
            if not viejo then
                local a, b = Suelo(o, h.i0, h.j0, h.k), Suelo(o, h.i1, h.j1, h.k)
                h.x, h.y, h.z0 = (a.x + b.x) / 2, (a.y + b.y) / 2, a.z
                h.planta, h.ocultos, h.sinEstado = h.k, {}, true
                huecos[clave] = h
            end
        end
    end
    local sobran = {}
    for clave, h in pairs(huecos) do
        if not hay[clave] then sobran[#sobran + 1] = clave end
        if h.sinEstado then falta = true end
    end
    for _, clave in ipairs(sobran) do Quitar(clave) end

    if falta then
        local estado = lib.callback.await('origen_housing:ascensores:huecos', false, id)
        if casaObra == id and type(estado) == 'table' then
            for clave, e in pairs(estado) do
                local h = huecos[clave]
                if h and h.sinEstado and type(e) == 'table' and tonumber(e.planta) then
                    h.sinEstado = nil
                    h.planta = math.floor(tonumber(e.planta))
                    if e.a and e.de then
                        h.viaje = { de = e.de, a = e.a, inicio = GetGameTimer() - (tonumber(e.lleva) or 0) }
                    end
                end
            end
        end
    end

    if casaObra == id then
        local lista = {}
        for _, h in pairs(huecos) do lista[#lista + 1] = h end
        for _, h in ipairs(lista) do
            -- ha llegado un modelo mejor (o falta el que tenía): la cabina se rehace, parada y vacía
            if huecos[h.clave] == h and h.entidad and DoesEntityExist(h.entidad) and not h.viaje and not h.pegados
                and ModeloDe(h) ~= h.puesto then
                QuitarPuertas(h)
                DeleteEntity(h.entidad)
                h.entidad, h.puesto = nil, nil
            end
            if huecos[h.clave] == h and not (h.entidad and DoesEntityExist(h.entidad)) then Crear(h) end
            if huecos[h.clave] == h then CrearPuertas(h) end
            if huecos[h.clave] == h then CrearPistones(h) end
        end
    end
end

-- De uno en uno (el repaso espera al servidor y a los modelos), y sin que un
-- fallo a medias deje el paso cerrado para siempre.
local function Sincronizar()
    if sincronizando then return end
    sincronizando = true
    local ok, fallo = pcall(Repasar)
    sincronizando = false
    if not ok then print('[origen_housing] ascensores: ' .. tostring(fallo)) end
end

-- Empieza un viaje. `viajeros` (ids de servidor) y `coches` (ids de red) son
-- los que el servidor ha visto en la cabina al arrancar: se pegan a ella en
-- este cliente, sean de quien sean. Los coches que este cliente tiene en red
-- los mueve él, a la par que la plataforma, y eso es lo que ve el resto del mundo.
local function Arrancar(h, de, a, lleva, viajeros, coches)
    Soltar(h, true)
    Descargar(h)
    h.sinEstado = nil
    h.planta = de
    h.viaje = { de = de, a = a, inicio = GetGameTimer() - lleva }
    if lleva > 400 then return end
    PlaySoundFrontend(-1, 'CLOSING', 'MP_PROPERTIES_ELEVATOR_DOORS', true)

    local z = AlturaDe(h, de)
    local yo = PlayerPedId()
    local hayCabina = h.entidad and DoesEntityExist(h.entidad)
    if hayCabina then
        h.pegados = {}
        if type(viajeros) ~= 'table' then viajeros = { GetPlayerServerId(PlayerId()) } end
        for _, sid in ipairs(viajeros) do
            -- quien no esté cargado en este cliente, se ignora
            local jugador = GetPlayerFromServerId(tonumber(sid) or -1)
            local ped = jugador ~= -1 and GetPlayerPed(jugador) or 0
            -- (pegado a esta misma cabina puede seguir del viaje anterior: se le suelta con retraso)
            if ped ~= 0 and DoesEntityExist(ped) and GetVehiclePedIsIn(ped, false) == 0
                and (not IsEntityAttached(ped) or IsEntityAttachedToEntity(ped, h.entidad))
                and Sobre(h, GetEntityCoords(ped), z, 1.0, ped ~= yo and 1.0 or 0.0) then
                Apuntar(h, ped, ped == yo)
                if ped == yo then montado = h end
            end
        end
        -- TEMPORAL (sonda zz_puerta): qué ha visto este cliente al arrancar el viaje
        local dobles = 0
        for _, p in ipairs(h.pegados) do if p.real then dobles = dobles + 1 end end
        TriggerServerEvent('zz_puerta:nada', 'viaje ' .. tostring(h.clave), { viajeros = viajeros, pegados = #h.pegados, dobles = dobles })
    end
    if h.tipo == 'c' then
        -- Congelados y movidos a la par que la plataforma, cada fotograma: a los
        -- demás les llega por la red como cualquier coche que se mueve.
        h.carga = {}
        for _, veh in ipairs(GetGamePool('CVehicle')) do
            local p = GetEntityCoords(veh)
            if Sobre(h, p, z, 0.5) and (not NetworkGetEntityIsNetworked(veh) or NetworkHasControlOfEntity(veh)) then
                SetEntityVelocity(veh, 0.0, 0.0, 0.0)
                FreezeEntityPosition(veh, true)
                h.carga[#h.carga + 1] = { veh = veh, dx = p.x - h.x, dy = p.y - h.y, dz = p.z - z }
            end
        end
        -- Los coches que mueve otro cliente: aquí, pegados a la plataforma, para
        -- no verlos subir a saltos. Su dueño no los pega: los mueve de verdad.
        if hayCabina and C.cabina.cochesAjenos and type(coches) == 'table' then
            for _, net in ipairs(coches) do
                net = tonumber(net)
                local veh = net and NetworkDoesNetworkIdExist(net) and NetworkGetEntityFromNetworkId(net) or 0
                if veh ~= 0 and DoesEntityExist(veh) and GetEntityType(veh) == 2 and not NetworkHasControlOfEntity(veh)
                    and Sobre(h, GetEntityCoords(veh), z, 0.5, 1.0) then
                    Apuntar(h, veh, false)
                end
            end
        end
    end
end

-- Un fotograma del viaje
local function Mover(h)
    local z, fin = Altura(h)
    if fin then
        h.planta = h.viaje.a
        Aparcar(h)
        PlaySoundFrontend(-1, 'OPENED', 'MP_PROPERTIES_ELEVATOR_DOORS', true)
        return
    end
    if h.entidad and DoesEntityExist(h.entidad) then
        SetEntityCoordsNoOffset(h.entidad, h.x, h.y, z, false, false, false)
    end
    ColocarPuertas(h, z)
    ColocarPistones(h, z)
    for _, c in ipairs(h.carga or {}) do
        if DoesEntityExist(c.veh) then SetEntityCoordsNoOffset(c.veh, h.x + c.dx, h.y + c.dy, z + c.dz, false, false, false) end
    end
    -- La red puede soltar a los que van pegados (para ella no lo están): se
    -- vuelven a pegar en el mismo sitio.
    if h.pegados and h.entidad and DoesEntityExist(h.entidad) then
        for _, p in ipairs(h.pegados) do
            if DoesEntityExist(p.ent) and not IsEntityAttachedToEntity(p.ent, h.entidad) then Pegar(h, p) end
            if p.real and DoesEntityExist(p.real) then SetEntityLocallyInvisible(p.real) end
        end
    end
    -- El suelo de cada planta se quita solo mientras la cabina lo atraviesa
    -- (ella hace de suelo) y vuelve en cuanto pasa: el hueco nunca queda abierto.
    for planta = h.k + 1, h.k + h.n - 1 do
        local zs = AlturaDe(h, planta)
        Tapar(h, planta, zs > z - 0.35 and zs < z + 2.75)
    end
end

RegisterNetEvent('origen_housing:ascensores:viaje', function(casa, clave, de, a, lleva, viajeros, coches)
    local h = casaObra == tostring(casa) and huecos[clave]
    de, a = tonumber(de), tonumber(a)
    if not h or not de or not a or de == a then return end
    if de < h.k or de > h.k + h.n - 1 or a < h.k or a > h.k + h.n - 1 then return end
    Arrancar(h, math.floor(de), math.floor(a), tonumber(lleva) or 0, viajeros, coches)
end)

-- El servidor da el viaje por acabado: por si este cliente no lo vio entero
RegisterNetEvent('origen_housing:ascensores:llegada', function(casa, clave, planta)
    local h = casaObra == tostring(casa) and huecos[clave]
    planta = tonumber(planta)
    if not h or not planta or planta < h.k or planta > h.k + h.n - 1 then return end
    if h.viaje and h.viaje.a == planta and not h.sinEstado then return end   -- ya llega solo
    h.sinEstado = nil
    h.planta = math.floor(planta)
    Aparcar(h)
end)

AddEventHandler('origen_housing:obra:montada', function()
    Sincronizar()
end)

AddEventHandler('origen_housing:obra:desmontada', function()
    QuitarTodos()
end)

-- El hueco que se puede usar ahora: de pie (o al volante, en el montacoches)
-- sobre la cabina, o en una celda vecina de una planta en la que no está.
local function HuecoCerca(ped, veh)
    if not next(huecos) then return nil end
    local o = ObraActual()
    if not o or casaObra ~= tostring(o.id) then return nil end
    local pi, pj, pk = CeldaDe(o, GetEntityCoords(ped))
    for _, h in pairs(huecos) do
        if not h.viaje and not h.sinEstado and pk >= h.k and pk <= h.k + h.n - 1 and (veh == 0 or h.tipo == 'c') then
            if C.EnHuella(h, pi, pj) then
                if pk == h.planta then return h, 'usar' end
            elseif C.JuntoAHuella(h, pi, pj) and pk ~= h.planta then
                return h, 'llamar', pk
            end
        end
    end
    return nil
end

local function Pedir(h, planta, modo)
    if ocupado then return end
    ocupado = true
    Texto(nil)
    local res = lib.callback.await('origen_housing:ascensores:mover', false, casaObra, h.clave, planta, modo)
    if type(res) ~= 'table' or not res.ok then
        Custom.Notify(type(res) == 'table' and res.aviso or 'El ascensor no responde', 'error', 4500)
    end
    SetTimeout(600, function() ocupado = false end)
end

local function ElegirPlanta(h)
    if IsNuiFocused() then return end
    local plantas = {}
    for planta = h.k, h.k + h.n - 1 do
        plantas[#plantas + 1] = { nombre = C.NombrePlanta(planta), corto = planta == 0 and 'PB' or tostring(planta) }
    end
    eligiendo = { hueco = h.clave, base = h.k, desde = GetGameTimer() }
    Texto(nil)
    Nui.ToggleElevatorMenu(true, { floors = plantas, floor = h.planta - h.k })
end

-- ── El menú de plantas ──────────────────────────────────────────────────
-- El menú contesta por el callback de los garajes (client/nui.lua,
-- 'selectFloor'), que ya responde a la interfaz y no hace nada fuera de un
-- garaje. Aquí solo se escucha esa misma llamada mientras el menú es nuestro.
AddEventHandler('__cfx_nui:selectFloor', function(data)
    local e = eligiendo
    if not e or type(data) ~= 'table' then return end
    local n = tonumber(data.floor)
    if not n then return end

    if e.hueco then
        local h = huecos[e.hueco]
        local planta = e.base + math.floor(n)
        if h and planta == h.planta and not h.viaje then
            Custom.Notify('Ya estás en esa planta', 'info', 2500)
            return
        end
        eligiendo = nil
        Nui.ToggleElevatorMenu(false)
        if h then Pedir(h, planta, 'usar') end
        return
    end

    local destino = e.orden[math.floor(n) + 1]
    if not destino then return end
    if destino == e.pieza then
        Custom.Notify('Ya estás en esa planta', 'info', 2500)
        return
    end
    eligiendo = nil
    Nui.ToggleElevatorMenu(false)
    Viajar(e.pieza, destino)
end)

-- Escape o clic fuera: la interfaz cierra por 'close'
AddEventHandler('__cfx_nui:close', function()
    eligiendo = nil
end)

-- ── La E ────────────────────────────────────────────────────────────────
-- Lo que se puede hacer ahora mismo: { texto, hacer }, o nada.
local function Accion(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    local conduce = veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped

    if #piezas > 0 then
        if veh == 0 then
            local cabina = PiezaEn('persona', GetEntityCoords(ped))
            if cabina then return { texto = TEXTO.persona, hacer = function() Usar(cabina) end } end
        end
        -- la plataforma: al volante con el coche encima, o a pie junto a una que tiene coche
        local p, coche
        if conduce then
            p, coche = PiezaEn('coche', GetEntityCoords(veh)), veh
        elseif veh == 0 then
            p = PiezaEn('coche', GetEntityCoords(ped), 1.5)
            coche = p and CocheSobre(p)
        end
        -- Los elevadores con brazos: en marcha no se ofrece nada; vacíos se
        -- manejan a pie desde los mandos; y ya subidos bajan con lo que subió,
        -- sea cual sea el coche que haya ahora a mano (el de debajo de la bandeja).
        local b = p and Brazos.De(p)
        if b and (b.mueve or b.sinEstado) then p, b = nil, nil end
        if b and (not coche or Brazos.Arriba(b)) then
            local pieza = p
            p = nil
            if coche or Brazos.EnMandos(b, ped) then
                local arriba = Brazos.Arriba(b)
                return { texto = arriba and (b.est.net and TEXTO.bajar or TEXTO.bajarSolo) or TEXTO.subirSolo,
                    hacer = function() Taller(pieza, nil) end }
            end
        end
        if p and coche then
            local arriba = Entity(coche).state.origenTaller ~= nil
            local lista = { { texto = arriba and TEXTO.bajar or TEXTO.subir, detalle = 'En el sitio, como en un taller', hacer = function() Taller(p, coche) end } }
            if C.llevar and conduce and not arriba and #Enlazadas(p) >= 2 then
                lista[#lista + 1] = { texto = TEXTO.llevar, detalle = 'A otra plataforma de la casa', hacer = function() Usar(p) end }
            end
            if #lista == 1 then return lista[1] end
            return { texto = TEXTO.coche, hacer = function() MenuElevador(lista) end }
        end
    end

    if veh == 0 or conduce then
        local h, modo, planta = HuecoCerca(ped, veh)
        if h and modo == 'usar' then
            return { texto = TEXTO[h.tipo].usar, hacer = function() ElegirPlanta(h) end }
        elseif h then
            return { texto = TEXTO[h.tipo].llamar, hacer = function() Pedir(h, planta, 'llamar') end }
        end
    end
    return nil
end

-- ── Los bucles ──────────────────────────────────────────────────────────
-- Los muebles se repasan cada segundo (se ponen, se mueven y se quitan con el
-- jugador dentro) y los huecos de la obra, cada dos, por si se escapa un aviso.
CreateThread(function()
    local vuelta = 0
    while true do
        Recoger()
        Brazos.Repasar()
        vuelta = vuelta + 1
        if vuelta % 2 == 0 then Sincronizar() end
        Wait(1000)
    end
end)

-- La luz de dentro de las cabinas cercanas, cada fotograma
CreateThread(function()
    local L = C.cabina.luz
    local r, g, b = math.floor(L.color[1]), math.floor(L.color[2]), math.floor(L.color[3])
    while true do
        local espera = 500
        if casaObra and next(huecos) then
            local yo = GetEntityCoords(PlayerPedId())
            for _, h in pairs(huecos) do
                if h.tipo == 'a' and h.entidad and DoesEntityExist(h.entidad) then
                    local z = Altura(h)
                    if #(yo - vector3(h.x, h.y, z)) < L.distancia then
                        espera = 0
                        local ci, cj = (h.i0 + h.i1) / 2, (h.j0 + h.j1) / 2
                        for i = h.i0, h.i1 do
                            for j = h.j0, h.j1 do
                                DrawLightWithRange(h.x + (i - ci) * O.celda, h.y + (j - cj) * O.celda, z + L.alto, r, g, b,
                                    L.alcance + 0.0, L.intensidad + 0.0)
                            end
                        end
                    end
                end
            end
        end
        Wait(espera)
    end
end)

-- Las cabinas en marcha, cada fotograma
CreateThread(function()
    while true do
        local espera = 250
        for _, h in pairs(huecos) do
            if h.viaje then
                espera = 0
                Mover(h)
            elseif h.abre then
                -- recién llegada: las puertas de la cabina cerrada, abriéndose
                espera = 0
                ColocarPuertas(h, AlturaDe(h, h.planta))
            end
        end
        Wait(espera)
    end
end)

CreateThread(function()
    while true do
        local espera = 400
        local accion = nil
        if (#piezas > 0 or next(huecos)) and not ocupado and not eligiendo and not menuAjeno and not montado
            and not (Furniture and Furniture.active) and not IsNuiFocused() and not IsPauseMenuActive() then
            accion = Accion(PlayerPedId())
        end
        if accion then
            -- (la tecla se mira en el árbitro. En la cabina o en la plataforma, el ascensor
            -- va antes que lo demás que haya a mano)
            espera = 150
            Tecla.Ofrecer('ascensores', { texto = accion.texto, prioridad = 70, dist = 0.0, hacer = accion.hacer })
        else
            Texto(nil)
        end
        -- si el menú se quedó sin dueño (se salió de la casa con él abierto)
        if eligiendo and GetGameTimer() - eligiendo.desde > 500 and (not casaActual or not IsNuiFocused()) then
            if IsNuiFocused() then Nui.ToggleElevatorMenu(false) end
            eligiendo = nil
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    Brazos.QuitarTodos()
    QuitarTodos()
end)
