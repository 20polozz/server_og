--[[ ── Las presas ─────────────────────────────────────────────────────────────

     Dos papeles:

       · las PROPIAS las crea este cliente (con el vale del servidor) y les
         lleva la cabeza: pasear, huir, atacar, ir al cebo;
       · las de TODOS (propias y ajenas) se conocen por el state bag
         `cazaPresa`, y de ellas salen las huellas, la sangre y el
         despellejado.

     Cada animal recibe una orden SOLO cuando cambia lo que quiere hacer. La
     versión anterior repetía la orden cada medio segundo y el animal nunca
     llegaba al cebo: cada repetición le borraba la anterior. ]]

local PR = Config.Presas
local RA = Config.Rastreo

local ESCENA_COMER = {
    ciervo = 'WORLD_DEER_GRAZING',
    ciervo_albino = 'WORLD_DEER_GRAZING',
    jabali = 'WORLD_PIG_GRAZING',
    conejo = 'WORLD_RABBIT_EATING',
    liebre = 'WORLD_RABBIT_EATING',
}

local function NetDeBolsa(bolsa)
    return tonumber((bolsa or ''):gsub('entity:', ''), 10)
end

local function Presa(netId)
    local p = C.presas[netId]
    if not p then
        p = { netId = netId, huellas = {} }
        C.presas[netId] = p
    end
    return p
end

local function Olvidar(netId)
    local p = C.presas[netId]
    if not p then return end
    C.presas[netId] = nil
    OrigenMapa.Quitar('rastro_' .. netId)
end
C.OlvidarPresa = Olvidar

AddStateBagChangeHandler('cazaPresa', nil, function(bolsa, _, valor)
    local netId = NetDeBolsa(bolsa)
    if not netId then return end
    if not valor then Olvidar(netId) return end
    local p = Presa(netId)
    p.info = valor
    p.propia = valor.cazador == cache.serverId
end)

AddStateBagChangeHandler('cazaMuerta', nil, function(bolsa, _, valor)
    local netId = NetDeBolsa(bolsa)
    if not netId or not valor then return end
    local p = Presa(netId)
    p.muerte = valor
end)

RegisterNetEvent('origen_hunting:presaFuera', function(netId)
    Olvidar(tonumber(netId))
end)

RegisterNetEvent('origen_hunting:abatida', function(netId)
    local p = C.presas[tonumber(netId)]
    if p then p.miPieza = true end
end)

--- El handle local de una presa, si está cargada aquí.
function C.EntidadDe(netId)
    if not NetworkDoesNetworkIdExist(netId) then return nil end
    local ent = NetToPed(netId)
    if ent == 0 or not DoesEntityExist(ent) then return nil end
    return ent
end

-- ── Dónde poner un animal ─────────────────────────────────────────────────

local function Suelo(x, y)
    local ok, z = GetGroundZFor_3dCoord(x, y, 1000.0, false)
    if not ok or z <= 0.0 then return nil end

    local okN, _, normal = GetGroundZAndNormalFor_3dCoord(x, y, z + 1.5)
    if okN and normal and normal.z < 0.72 then return nil end        -- demasiado empinado

    local hayAgua, agua = GetWaterHeight(x, y, z + 5.0)
    if hayAgua and agua > z - 0.3 then return nil end

    if IsPointOnRoad(x, y, z, 0) then return nil end
    return z
end

--- Detrás de la cámara: el animal no aparece de la nada delante de tus ojos.
local function BuscarSitio(base, dMin, dMax)
    local rumbo = GetGameplayCamRot(2).z
    for _ = 1, 16 do
        local ang = math.rad(rumbo + 180.0 + math.random(-80, 80))
        local d = math.random(math.floor(dMin), math.floor(dMax))
        local x = base.x - math.sin(ang) * d
        local y = base.y + math.cos(ang) * d
        if Caza.ZonaEn(x, y) then
            local z = Suelo(x, y)
            if z then return vec3(x, y, z + 0.4) end
        end
        Wait(0)
    end
    return nil
end

local function Crear(ficha)
    local base = C.cebo and C.cebo.coords or GetEntityCoords(cache.ped)
    local sitio = BuscarSitio(base, PR.distanciaMin, PR.distanciaMax)
        or BuscarSitio(base, 35.0, 60.0)
    if not sitio then
        Caza.Traza('sin sitio para', ficha.id)
        return false
    end

    local hash = GetHashKey(ficha.modelo)
    -- ox_lib LANZA un error si el modelo no carga a tiempo: sin el pcall se
    -- llevaría por delante el hilo que pide presas.
    if not pcall(lib.requestModel, hash, 8000) then return false end

    local ped = CreatePed(28, hash, sitio.x, sitio.y, sitio.z, math.random(0, 359) + 0.0, true, true)
    SetModelAsNoLongerNeeded(hash)
    if not ped or ped == 0 then return false end

    local espera = GetGameTimer() + 2000
    while not NetworkGetEntityIsNetworked(ped) and GetGameTimer() < espera do Wait(0) end
    if not NetworkGetEntityIsNetworked(ped) then DeleteEntity(ped) return false end

    local netId = PedToNet(ped)
    -- Mientras vive, su cabeza está aquí: si migra a otro cliente, pierde las órdenes.
    SetNetworkIdCanMigrate(netId, false)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    PlaceObjectOnGroundProperly(ped)

    local max = math.floor(GetEntityMaxHealth(ped) * (ficha.vida or 1.0))
    SetEntityMaxHealth(ped, max)
    SetEntityHealth(ped, max)

    if not lib.callback.await('origen_hunting:presaCreada', false, netId) then
        DeleteEntity(ped)
        return false
    end

    local p = Presa(netId)
    p.propia = true
    p.ped = ped
    p.ficha = ficha
    p.max = max
    p.tarea = nil
    p.creada = GetGameTimer()

    if C.cebo and C.cebo.hasta > GetGameTimer() then
        p.objetivo = { coords = C.cebo.coords, hasta = C.cebo.hasta, cebo = true }
    end

    Caza.Miga('creada', ficha.id, netId)
    return true
end

-- Pedir presas mientras toque.
CreateThread(function()
    local proximo = 0
    while true do
        Wait(1500)
        if C.activa and C.zona and not C.panelAbierto and GetGameTimer() >= proximo
            and not IsPedInAnyVehicle(cache.ped, false) and not IsEntityDead(cache.ped) then
            local vivas = 0
            for _, p in pairs(C.presas) do
                if p.propia and p.ped and not IsEntityDead(p.ped) then vivas = vivas + 1 end
            end
            if vivas < (C.estado.presasMax or 1) then
                local r = lib.callback.await('origen_hunting:pedirPresa', false, GetClockHours())
                if r and r.ok then
                    if not Crear(r.especie) then proximo = GetGameTimer() + 5000 end
                else
                    proximo = GetGameTimer() + math.max(2, (r and r.espera) or 10) * 1000
                end
            else
                proximo = GetGameTimer() + 4000
            end
        end
    end
end)

-- ── Cómo te nota un animal ────────────────────────────────────────────────

--- Multiplica la distancia de detección según cómo se mueve `ped` y el viento.
local function Olfato(ped, desde, hasta)
    local m = 1.0
    if GetPedStealthMovement(ped) then m = m * RA.agachado end
    if IsPedSprinting(ped) or IsPedRunning(ped) then m = m * RA.corriendo end
    if IsPedInAnyVehicle(ped, false) then m = m * 1.3 end

    local viento = GetWindDirection()
    local dir = hasta - desde
    local largo = #dir
    if largo > 0.1 then
        -- El viento sopla HACIA `viento`: si va de ti al animal, te huele.
        local dot = (viento.x * dir.x + viento.y * dir.y) / largo
        if dot > 0.5 then m = m * RA.vientoEnContra end
    end
    return m
end
C.Olfato = Olfato

--[[ Un objetivo que se puede atacar o del que se puede huir: un jugador de
     verdad, vivo y a pie. Se vuelve a mirar en CADA vuelta, no solo al dar la
     orden: si el jugador se desconecta o cambia de personaje, su ped deja de
     ser de jugador, y dejar a un animal en combate contra él es de lo que más
     huele a crash del motor (16/09, volcado helium-king-table cazando). ]]
local function ObjetivoValido(ped)
    return ped and ped ~= 0 and DoesEntityExist(ped)
        and IsPedAPlayer(ped)
        and NetworkGetPlayerIndexFromPed(ped) ~= -1
        and not IsEntityDead(ped)
        and not IsPedInAnyVehicle(ped, false)
end

local function Amenaza(pos)
    local mejor, dist = nil, 90.0
    for _, id in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(id)
        if ObjetivoValido(ped) then
            local d = #(GetEntityCoords(ped) - pos)
            if d < dist then mejor, dist = ped, d end
        end
    end
    return mejor, dist
end

local function Ordenar(p, quiere, amenaza)
    local ped = p.ped
    Caza.Miga('orden', p.ficha and p.ficha.id, p.netId, (p.tarea or '-') .. '>' .. quiere,
        amenaza and ('objetivo=' .. tostring(NetworkGetPlayerIndexFromPed(amenaza))) or '')
    p.tarea = quiere
    p.amenaza = amenaza
    ClearPedTasks(ped)

    if quiere == 'atacar' then
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 46, true)
        SetPedCombatAttributes(ped, 5, true)
        TaskCombatPed(ped, amenaza, 0, 16)
    elseif quiere == 'huir' then
        TaskSmartFleePed(ped, amenaza, 250.0, -1, false, false)
    elseif quiere == 'ir' then
        --[[ Por la malla de navegación y NO con TaskGoToCoordAnyMeans: esa
             orden es de humanos (puede intentar subirse a un vehículo) y en un
             animal no tiene sentido. ]]
        local c = p.objetivo.coords
        TaskFollowNavMeshToCoord(ped, c.x, c.y, c.z, 1.0, -1, 2.0, 0, 0.0)
    elseif quiere == 'comer' then
        local escena = ESCENA_COMER[p.ficha.id]
        if escena then
            TaskStartScenarioInPlace(ped, escena, 0, true)
        else
            TaskStandStill(ped, 15000)
        end
    else
        local pos = GetEntityCoords(ped)
        TaskWanderInArea(ped, pos.x, pos.y, pos.z, 30.0, 2.0, 5.0)
    end
end

local function Conducta(p, ahora)
    local ped = p.ped

    -- Solo manda quien tiene el control; el resto de clientes no toca nada.
    if not NetworkHasControlOfEntity(ped) then return end

    -- El objetivo de la orden en curso ya no vale: se suelta YA, sin esperar a
    -- que haya otro jugador cerca.
    if (p.tarea == 'atacar' or p.tarea == 'huir') and not ObjetivoValido(p.amenaza) then
        Ordenar(p, 'pasear', nil)
    end

    local pos = GetEntityCoords(ped)
    local ficha = p.ficha
    local amenaza, dist = Amenaza(pos)

    local det = ficha.deteccion
    if amenaza then det = det * Olfato(amenaza, GetEntityCoords(amenaza), pos) end

    local herida = GetEntityHealth(ped) < p.max
    if amenaza and IsPedShooting(amenaza) and dist < 120.0 then p.susto = ahora + 10000 end
    local asustada = (p.susto or 0) > ahora

    if p.objetivo and ahora > p.objetivo.hasta then p.objetivo = nil end

    local quiere
    local c = ficha.conducta
    if amenaza and c == 'ataca' and (dist < det or (herida and dist < det * 2.0)) then
        quiere = 'atacar'
    elseif amenaza and c == 'embiste' and (dist < det * 0.55 or (herida and dist < det * 1.5)) then
        quiere = 'atacar'
    elseif amenaza and c ~= 'ataca' and (dist < det or (herida and dist < det * 2.5) or (asustada and dist < 120.0)) then
        quiere = 'huir'
    elseif p.tarea == 'huir' and amenaza and dist < det * 3.0 then
        quiere = 'huir'
    elseif p.tarea == 'atacar' and amenaza and dist < det * 2.2 then
        quiere = 'atacar'
    elseif p.objetivo then
        quiere = #(pos - p.objetivo.coords) < 3.0 and 'comer' or 'ir'
    else
        quiere = 'pasear'
    end

    if quiere ~= p.tarea or ((quiere == 'atacar' or quiere == 'huir') and p.amenaza ~= amenaza) then
        Ordenar(p, quiere, amenaza)
    end
end

CreateThread(function()
    while true do
        Wait(400)
        local ahora = GetGameTimer()
        for netId, p in pairs(C.presas) do
            if p.propia and p.ped then
                if not DoesEntityExist(p.ped) then
                    if not p.muertaAqui then TriggerServerEvent('origen_hunting:presaPerdida', netId) end
                    Olvidar(netId)
                elseif IsEntityDead(p.ped) then
                    if not p.muertaAqui then
                        p.muertaAqui = true
                        Caza.Miga('muerta', p.ficha and p.ficha.id, netId)
                        -- Muerta ya no necesita cabeza: que la pueda mover quien la cargue.
                        SetNetworkIdCanMigrate(netId, true)
                    end
                else
                    Conducta(p, ahora)
                end
            end
        end
    end
end)

-- ── Los aciertos ──────────────────────────────────────────────────────────

--[[ Cuántas veces le has dado. Solo resta calidad (tres disparos o más
     estropean la piel), así que se cuenta aquí y se avisa al servidor. ]]
CreateThread(function()
    while true do
        local espera = 500
        if C.activa and IsPedArmed(cache.ped, 4) then
            espera = 0
            if IsPedShooting(cache.ped) then
                Wait(60)
                for netId, p in pairs(C.presas) do
                    if not p.muerte then
                        local ent = C.EntidadDe(netId)
                        if ent and HasEntityBeenDamagedByEntity(ent, cache.ped, true) then
                            ClearEntityLastDamageEntity(ent)
                            TriggerServerEvent('origen_hunting:acierto', netId)
                        end
                    end
                end
            end
        end
        Wait(espera)
    end
end)

-- ── Huellas y sangre ──────────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(500)
        local yo = GetEntityCoords(cache.ped)
        for netId, p in pairs(C.presas) do
            local ent = C.EntidadDe(netId)
            if ent and not IsEntityDead(ent) and #(GetEntityCoords(ent) - yo) < 260.0 then
                local pos = GetEntityCoords(ent)
                local ultima = p.huellas[#p.huellas]
                if not ultima or #(ultima.pos.xy - pos.xy) >= RA.huellaCada then
                    local ok, z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.0, false)
                    local herida = GetEntityHealth(ent) < GetEntityMaxHealth(ent)
                    p.huellas[#p.huellas + 1] = {
                        pos = vec3(pos.x, pos.y, (ok and z or pos.z - 0.9) + 0.03),
                        rumbo = GetEntityHeading(ent),
                        sangre = herida,
                        t = GetGameTimer(),
                    }
                    if #p.huellas > RA.huellasMax then table.remove(p.huellas, 1) end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        local espera = 600
        if C.activa then
            local yo = GetEntityCoords(cache.ped)
            local ahora = GetGameTimer()
            for _, p in pairs(C.presas) do
                for _, h in ipairs(p.huellas) do
                    local d = #(h.pos - yo)
                    if d < RA.huellasSeVenA then
                        espera = 0
                        -- Se apagan con la distancia y con el tiempo (dos minutos).
                        local edad = math.min(1.0, (ahora - h.t) / 120000)
                        local a = math.floor(200 * (1.0 - d / RA.huellasSeVenA) * (1.0 - edad * 0.7))
                        if a > 8 then
                            if h.sangre then
                                DrawMarker(27, h.pos.x, h.pos.y, h.pos.z, 0, 0, 0, 0, 0, h.rumbo,
                                    0.32, 0.32, 0.32, 150, 12, 16, a, false, false, 2, false, nil, nil, false)
                            else
                                DrawMarker(27, h.pos.x, h.pos.y, h.pos.z, 0, 0, 0, 0, 0, h.rumbo,
                                    0.22, 0.3, 0.22, 92, 66, 40, a, false, false, 2, false, nil, nil, false)
                            end
                        end
                    end
                end
            end
        end
        Wait(espera)
    end
end)

-- ── El rastro en el mapa ──────────────────────────────────────────────────

--[[ No se marca el animal: se marca una zona que lo contiene, movida al azar,
     y desaparece al acercarte. Lo último lo haces siguiendo las huellas. La
     pieza abatida sí se marca exacta para quien la abatió. ]]
CreateThread(function()
    while true do
        Wait(1000)
        local yo = GetEntityCoords(cache.ped)
        local ahora = GetGameTimer()
        for netId, p in pairs(C.presas) do
            local ent = C.EntidadDe(netId)
            local clave = 'rastro_' .. netId
            local info = p.info or {}
            if not ent then
                if p.marca then OrigenMapa.Quitar(clave) p.marca = nil end
            elseif p.muerte then
                if (p.propia or p.miPieza) and p.marca ~= 'muerta' then
                    p.marca = 'muerta'
                    OrigenMapa.Poner(clave, {
                        entidad = ent, cat = 'activities', icono = 'huella',
                        nombre = 'Pieza abatida: ' .. (info.nombre or 'animal'),
                        color = '#2e9e5b', prioridad = 10,
                    })
                end
            elseif p.propia then
                local d = #(GetEntityCoords(ent) - yo)
                if d <= RA.sinZonaA then
                    if p.marca then OrigenMapa.Quitar(clave) p.marca = nil end
                elseif not p.marca or ahora >= (p.marcaHasta or 0) then
                    local pos = GetEntityCoords(ent)
                    local desvio = RA.zonaRadio * 0.55
                    p.marca = 'zona'
                    p.marcaHasta = ahora + RA.zonaCada * 1000
                    OrigenMapa.Poner(clave, {
                        x = pos.x + (math.random() * 2 - 1) * desvio,
                        y = pos.y + (math.random() * 2 - 1) * desvio,
                        z = pos.z,
                        radio = RA.zonaRadio,
                        cat = 'activities', icono = 'huella',
                        nombre = 'Rastro de ' .. (info.nombre or 'presa'):lower(),
                        color = info.legendaria and '#e8b923' or '#ff3355',
                        prioridad = 10,
                    })
                end
            end
        end
    end
end)

-- ── Fin de jornada ────────────────────────────────────────────────────────

AddEventHandler('origen_hunting:finJornada', function()
    for netId, p in pairs(C.presas) do
        if not p.muerte then Olvidar(netId) end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    for netId, p in pairs(C.presas) do
        if p.propia and p.ped and DoesEntityExist(p.ped) then DeleteEntity(p.ped) end
        OrigenMapa.Quitar('rastro_' .. netId)
    end
end)

-- ── Cebo y reclamo: a qué presas afecta ───────────────────────────────────

--- Manda a las presas propias vivas a `coords` durante `segundos`.
function C.Atraer(coords, alcance, segundos, cebo)
    local n = 0
    for _, p in pairs(C.presas) do
        if p.propia and p.ped and DoesEntityExist(p.ped) and not IsEntityDead(p.ped)
            and #(GetEntityCoords(p.ped) - coords) <= alcance then
            p.objetivo = { coords = coords, hasta = GetGameTimer() + segundos * 1000, cebo = cebo }
            p.tarea = nil
            n = n + 1
        end
    end
    return n
end

--- La presa viva más cercana (propia primero), para el HUD.
function C.PresaCercana()
    local yo = GetEntityCoords(cache.ped)
    local mejor, dMejor
    for netId, p in pairs(C.presas) do
        local ent = C.EntidadDe(netId)
        if ent then
            local d = #(GetEntityCoords(ent) - yo)
            local peso = p.propia and d or d + 1000
            if not dMejor or peso < dMejor then mejor, dMejor = { p = p, ent = ent, d = d }, peso end
        end
    end
    return mejor
end
