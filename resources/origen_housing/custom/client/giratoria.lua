-- Plataformas giratorias de exposición (ver config/giratoria.lua y
-- custom/server/giratoria.lua). A pie junto a una, la E la pone a girar o la
-- para. Gira el mueble y, con él, los coches sin conductor que tenga encima.
-- Cada cliente gira su mueble con el mismo reloj (lo que lleva girando lo dice
-- el servidor); el coche lo mueve quien lo tiene en red y los demás lo ven.
local C = Config.Giratoria

local piezas = {}       -- las de la casa en la que se está: { id, zona, clave, entidad, radio, rumbo0 }
local casaActual = nil
local estados = {}      -- ['zona:id'] = { girando, base, inicio (GetGameTimer de este cliente) }
local rumbos = {}       -- entidad → rumbo con el que se colocó (antes de girarla)
local menuAjeno = false
local conTexto = false
local ocupado = false

-- (el árbitro lo suelta si se queda enganchado: custom/client/tecla_e.lua)
AddEventHandler('origen_housing:sinMenuAjeno', function() menuAjeno = false end)

AddEventHandler('qv2:suppressHud', function(fuera)
    menuAjeno = fuera == true
end)

-- El cartel y la tecla los lleva el árbitro común (custom/client/tecla_e.lua):
-- aquí solo se ofrece la E, o se retira.
local function Texto(texto)
    if not texto then Tecla.Retirar('giratoria') end
end

local function Angulo(e)
    if not e then return 0.0 end
    if not e.girando then return e.base end
    return (e.base + (GetGameTimer() - e.inicio) * C.velocidad / 1000.0) % 360.0
end

-- Suelta los coches que llevaba una plataforma (y quita sus dobles)
local function Soltar(p)
    for veh, c in pairs(p.coches or {}) do
        if c.doble and DoesEntityExist(c.doble) then DeleteEntity(c.doble) end
        if c.mio and DoesEntityExist(veh) then FreezeEntityPosition(veh, false) end
    end
    p.coches, p.ultimo = nil, nil
end

-- Un doble local del coche, igual que él. Es lo que se ve girar: el de verdad
-- lo mueve quien lo tiene en red y a los demás les llega a saltitos, así que
-- mientras gira se esconde y se enseña este, que cada cliente lleva con su
-- plataforma fotograma a fotograma.
local function Doble(veh)
    local modelo = GetEntityModel(veh)
    if not HasModelLoaded(modelo) then
        RequestModel(modelo)
        return nil
    end
    local q = GetEntityCoords(veh)
    local doble = CreateVehicle(modelo, q.x, q.y, q.z, GetEntityHeading(veh), false, false)
    if not doble or doble == 0 then return nil end
    SetEntityCollision(doble, false, false)
    FreezeEntityPosition(doble, true)
    SetEntityInvincible(doble, true)
    SetVehicleDoorsLocked(doble, 2)
    SetVehicleEngineOn(doble, false, true, true)
    local ok, datos = pcall(lib.getVehicleProperties, veh)
    if ok and datos then
        datos.plate, datos.fuelLevel = nil, nil
        pcall(lib.setVehicleProperties, doble, datos)
    end
    return doble
end

local function Recoger()
    local id = currentInteriorHouseID or currentExteriorHouseID
    local house = id and House.get(id) or nil
    local casa = house and tostring(house.id) or nil
    if casa ~= casaActual then
        for _, p in ipairs(piezas) do Soltar(p) end
        casaActual, estados, rumbos = casa, {}, {}
        if casa then
            local pedida = casa
            local todas = lib.callback.await('origen_housing:giratoria:todas', false, casa)
            if casaActual ~= pedida then return end
            for clave, e in pairs(type(todas) == 'table' and todas or {}) do
                estados[clave] = { girando = e.girando == true, base = (tonumber(e.base) or 0.0) + 0.0, inicio = GetGameTimer() - (tonumber(e.lleva) or 0) }
            end
        end
    end
    local antes, lista = {}, {}
    for _, p in ipairs(piezas) do antes[p.entidad] = p end
    if house then
        for zona, muebles in pairs({ interior = house.interiorFurniture, exterior = house.exteriorFurniture }) do
            for mid, m in pairs(muebles or {}) do
                local nombre = type(m) == 'table' and C.Es(m.model)
                if nombre and m.entity and DoesEntityExist(m.entity) then
                    local p = antes[m.entity]
                    if p then
                        antes[m.entity] = nil
                    else
                        local min, max = GetModelDimensions(GetEntityModel(m.entity))
                        rumbos[m.entity] = rumbos[m.entity] or GetEntityHeading(m.entity)
                        p = {
                            id = tostring(mid), zona = zona, clave = zona .. ':' .. tostring(mid), entidad = m.entity,
                            radio = C.modelos[nombre].radio or math.max(max.x - min.x, max.y - min.y) / 2,
                            alto = max.z, rumbo0 = rumbos[m.entity],
                        }
                    end
                    lista[#lista + 1] = p
                end
            end
        end
    end
    for _, p in pairs(antes) do Soltar(p) end
    piezas = lista
end

RegisterNetEvent('origen_housing:giratoria:estado', function(casa, clave, girando, base, lleva)
    if tostring(casa) ~= casaActual or type(clave) ~= 'string' then return end
    estados[clave] = { girando = girando == true, base = (tonumber(base) or 0.0) + 0.0, inicio = GetGameTimer() - (tonumber(lleva) or 0) }
end)

-- Un fotograma de una plataforma que gira: el mueble a su ángulo y, con él,
-- los coches sin conductor que tenga encima y este jugador si está subido.
local function Girar(p, e)
    local angulo = Angulo(e)
    SetEntityHeading(p.entidad, (p.rumbo0 + angulo) % 360.0)
    local centro = GetEntityCoords(p.entidad)
    p.coches = p.coches or {}
    p.repaso = (p.repaso or 0) + 1
    if p.repaso % 30 == 1 then
        for _, veh in ipairs(GetGamePool('CVehicle')) do
            if not p.coches[veh] and not Entity(veh).state.origenDoble then
                local q = GetEntityCoords(veh)
                local d = vector3(q.x - centro.x, q.y - centro.y, 0.0)
                if #d <= p.radio and q.z > centro.z - 0.5 and q.z < centro.z + p.alto + 3.0
                    and GetPedInVehicleSeat(veh, -1) == 0 and NetworkGetEntityIsNetworked(veh) then
                    -- dónde está el coche respecto a la plataforma, con ella a cero
                    local a = math.rad(-angulo)
                    p.coches[veh] = {
                        x = d.x * math.cos(a) - d.y * math.sin(a), y = d.x * math.sin(a) + d.y * math.cos(a),
                        z = q.z - centro.z, rumbo = GetEntityHeading(veh) - angulo,
                    }
                end
            end
        end
    end
    local a = math.rad(angulo)
    local cos, sen = math.cos(a), math.sin(a)
    for veh, c in pairs(p.coches) do
        if not DoesEntityExist(veh) or GetPedInVehicleSeat(veh, -1) ~= 0 then
            -- se lo han llevado o alguien se ha puesto al volante: se suelta
            if c.doble and DoesEntityExist(c.doble) then DeleteEntity(c.doble) end
            if c.mio and DoesEntityExist(veh) then FreezeEntityPosition(veh, false) end
            p.coches[veh] = nil
        else
            local x, y, z = centro.x + c.x * cos - c.y * sen, centro.y + c.x * sen + c.y * cos, centro.z + c.z
            local rumbo = (c.rumbo + angulo) % 360.0
            -- el de verdad lo mueve quien lo tiene en red
            if NetworkHasControlOfEntity(veh) then
                if not c.mio then
                    c.mio = true
                    FreezeEntityPosition(veh, true)
                end
                SetEntityCoordsNoOffset(veh, x, y, z, false, false, false)
                SetEntityHeading(veh, rumbo)
            else
                c.mio = false
            end
            -- y lo que se ve es el doble
            if not c.doble or not DoesEntityExist(c.doble) then
                c.doble = Doble(veh)
                if c.doble then Entity(c.doble).state:set('origenDoble', true, false) end
            end
            if c.doble then
                SetEntityCoordsNoOffset(c.doble, x, y, z, false, false, false)
                SetEntityHeading(c.doble, rumbo)
                SetEntityLocallyInvisible(veh)
            end
        end
    end

    -- Quien está de pie encima gira con ella: se le lleva lo que ha girado la
    -- plataforma desde el fotograma anterior, y puede seguir andando.
    local paso = p.ultimo and ((angulo - p.ultimo + 540.0) % 360.0 - 180.0) or 0.0
    p.ultimo = angulo
    if paso ~= 0.0 then
        local ped = PlayerPedId()
        if GetVehiclePedIsIn(ped, false) == 0 and not IsPedRagdoll(ped) and not IsPedJumping(ped) and not IsPedFalling(ped) then
            local q = GetEntityCoords(ped)
            local dx, dy = q.x - centro.x, q.y - centro.y
            local pies = q.z - 1.0 - (centro.z + p.alto)
            if dx * dx + dy * dy <= p.radio * p.radio and pies > -0.35 and pies < 0.6 then
                local r = math.rad(paso)
                local c2, s2 = math.cos(r), math.sin(r)
                SetEntityCoordsNoOffset(ped, centro.x + dx * c2 - dy * s2, centro.y + dx * s2 + dy * c2, q.z, false, false, false)
                SetEntityHeading(ped, (GetEntityHeading(ped) + paso) % 360.0)
            end
        end
    end
end

local function Alternar(p)
    if ocupado then return end
    ocupado = true
    Texto(nil)
    local res = lib.callback.await('origen_housing:giratoria:alternar', false, casaActual, p.zona, p.id)
    if type(res) ~= 'table' or not res.ok then
        Custom.Notify(type(res) == 'table' and res.aviso or 'La plataforma no responde', 'error', 4000)
    end
    SetTimeout(C.ritmo, function() ocupado = false end)
end

CreateThread(function()
    while true do
        -- (si la consulta al servidor falla o tarda, el hilo sigue: sin esto se quedaba
        -- sin plataformas para siempre y no salía la E)
        local ok, err = pcall(Recoger)
        if not ok then
            casaActual = nil       -- que lo vuelva a pedir entero
            print(('^3[origen_housing]^0 giratoria: %s'):format(tostring(err)))
        end
        Wait(1000)
    end
end)

-- TEMPORAL (sonda): por qué sale o no la E
RegisterNetEvent('zz_puerta:diagGira', function()
    local ped = PlayerPedId()
    local yo, cerca = GetEntityCoords(ped), {}
    for _, p in ipairs(piezas) do
        local c = GetEntityCoords(p.entidad)
        cerca[#cerca + 1] = { p.clave, math.floor(#(vector3(yo.x - c.x, yo.y - c.y, 0.0)) * 10) / 10, p.radio, math.floor((yo.z - c.z) * 100) / 100 }
    end
    TriggerServerEvent('zz_puerta:nada', 'gira', { casa = casaActual, piezas = #piezas, ocupado = ocupado, menuAjeno = menuAjeno,
        decorando = Furniture and Furniture.active or false, nui = IsNuiFocused(), bloqueada = Tecla.Bloqueada(), cerca = cerca })
end)

-- Las que giran, cada fotograma; las paradas se dejan en el ángulo en que quedaron
CreateThread(function()
    while true do
        local espera = 300
        for _, p in ipairs(piezas) do
            local e = estados[p.clave]
            if DoesEntityExist(p.entidad) then
                if e and e.girando then
                    espera = 0
                    Girar(p, e)
                else
                    if p.coches then Soltar(p) end
                    if e and p.parada ~= e.base then
                        p.parada = e.base
                        SetEntityHeading(p.entidad, (p.rumbo0 + e.base) % 360.0)
                    end
                end
                if e and e.girando then p.parada = nil end
            end
        end
        Wait(espera)
    end
end)

-- La E, a pie junto a una plataforma
CreateThread(function()
    while true do
        local espera = 400
        local cerca = nil
        if #piezas > 0 and not ocupado and not menuAjeno and not (Furniture and Furniture.active)
            and not IsNuiFocused() and not IsPauseMenuActive() then
            local ped = PlayerPedId()
            if GetVehiclePedIsIn(ped, false) == 0 then
                local yo = GetEntityCoords(ped)
                for _, p in ipairs(piezas) do
                    local c = GetEntityCoords(p.entidad)
                    local d = #(vector3(yo.x - c.x, yo.y - c.y, 0.0))
                    if d <= p.radio + C.margen and yo.z > c.z - 1.0 and yo.z < c.z + p.alto + 3.0 and (not cerca or d < cerca.d) then
                        cerca = { p = p, d = d }
                    end
                end
            end
        end
        if cerca then
            -- (la tecla se mira en el árbitro. Es grande y se ofrece desde lejos: cede ante
            -- cualquier otra cosa que haya encima o al lado, una silla, una lámpara…)
            espera = 200
            local p = cerca.p
            local e = estados[p.clave]
            Tecla.Ofrecer('giratoria', {
                texto = e and e.girando and 'Parar la plataforma' or 'Girar la plataforma',
                prioridad = 30, dist = cerca.d,
                hacer = function() Alternar(p) end,
            })
        else
            Texto(nil)
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for _, p in ipairs(piezas) do Soltar(p) end
end)
