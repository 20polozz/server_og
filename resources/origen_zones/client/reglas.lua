--[[ ── Qué hace cada regla ────────────────────────────────────────────────────

     client/zonas.lua decide CUÁNDO manda una regla; aquí está QUÉ hace. Cada
     una tiene tres momentos y usa los que necesite:

         poner(ajustes, zona, estado)   al empezar a mandar
         cada(ajustes, zona, estado)    cada fotograma, mientras manda
         quitar(ajustes, zona, estado)  al dejar de mandar

     `estado` es una tabla vacía por regla y por vez: ahí se guarda lo que haya
     que deshacer al salir —los coches a los que se les ha tocado la velocidad,
     las sirenas que se han callado— para no dejar el mundo a medias.

     Un solo hilo las recorre todas. Con varias reglas encendidas eso sigue
     siendo un hilo, no seis, y cuando no hay ninguna duerme medio segundo. ]]

Reglas = {}

local puestas = {}   -- [clave] = { ajustes, zona, estado }
local YO = PlayerId()

local NADA = `WEAPON_UNARMED`

-- Los controles con los que se pega y se dispara.
local GOLPEAR = { 24, 25, 140, 141, 142, 143, 257, 263, 264 }

-- ═══════════════════════════════════════════════════════════════════════════
-- QUIÉN SOY
-- ═══════════════════════════════════════════════════════════════════════════

-- El trabajo y la banda los da el servidor, no el cliente: aquí solo se usan
-- para no molestar a quien se libra de la regla. Quien decide de verdad —quién
-- puede disparar, quién puede pasar— es server/vigilante.lua.
local ficha = { trabajo = nil, banda = nil }
local fichaHasta = 0

local function Ficha()
    if GetGameTimer() < fichaHasta then return ficha end
    fichaHasta = GetGameTimer() + 20000

    local nueva = lib.callback.await('origen_zones:quienSoy', false)
    if nueva then ficha = nueva end
    return ficha
end

local function EstaEnLaLista(lista, valor)
    if not valor then return false end
    for _, v in ipairs(lista or {}) do
        if v == valor then return true end
    end
    return false
end

local function SeLibra(ajustes)
    local quien = Ficha()
    return EstaEnLaLista(ajustes.trabajos, quien.trabajo)
        or EstaEnLaLista(ajustes.bandas, quien.banda)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- AYUDAS
-- ═══════════════════════════════════════════════════════════════════════════

local function CocheDelJugador(ped)
    if not IsPedInAnyVehicle(ped, false) then return nil end
    return GetVehiclePedIsIn(ped, false)
end

local function EsDeEmergencia(coche)
    return GetVehicleClass(coche) == 18
end

local function Cada(estado, clave, ms)
    local ahora = GetGameTimer()
    if (estado[clave] or 0) > ahora then return false end
    estado[clave] = ahora + ms
    return true
end

local function Aviso(texto, tipo)
    if Zonas and Zonas.Aviso then Zonas.Aviso(texto, tipo) end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EL CATÁLOGO
-- ═══════════════════════════════════════════════════════════════════════════

local COMO = {}

-- ── Sin coches de NPC ───────────────────────────────────────────────────────
COMO.sin_trafico = {
    poner = function(ajustes, zona)
        SetGarbageTrucks(false)
        SetRandomBoats(false)

        if ajustes.limpiar and zona._cx then
            local suelo, z = GetGroundZFor_3dCoord(zona._cx + 0.0, zona._cy + 0.0, 1000.0, false)
            ClearAreaOfVehicles(zona._cx + 0.0, zona._cy + 0.0, suelo and z or 0.0,
                (zona._alcance or 50.0) + 20.0, false, false, false, false, false)
        end
    end,
    cada = function(ajustes)
        SetVehicleDensityMultiplierThisFrame(0.0)
        SetRandomVehicleDensityMultiplierThisFrame(0.0)
        SetSomeVehicleDensityMultiplierThisFrame(0.0)
        if ajustes.aparcados ~= false then
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
        end
    end,
    quitar = function()
        SetGarbageTrucks(true)
        SetRandomBoats(true)
    end,
}

-- ── Sin peatones de NPC ─────────────────────────────────────────────────────
COMO.sin_peatones = {
    poner = function(ajustes, zona)
        if ajustes.limpiar and zona._cx then
            local suelo, z = GetGroundZFor_3dCoord(zona._cx + 0.0, zona._cy + 0.0, 1000.0, false)
            ClearAreaOfPeds(zona._cx + 0.0, zona._cy + 0.0, suelo and z or 0.0,
                (zona._alcance or 50.0) + 20.0, 1)
        end
    end,
    cada = function()
        SetPedDensityMultiplierThisFrame(0.0)
        SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
    end,
}

-- ── Límite de velocidad ─────────────────────────────────────────────────────
COMO.velocidad = {
    poner = function(ajustes)
        Aviso(('Aquí no se pasa de %d km/h.'):format(ajustes.kmh or 30), 'inform')
    end,
    cada = function(ajustes, _, estado)
        local ped = PlayerPedId()
        local coche = CocheDelJugador(ped)
        if not coche then return end
        if not ajustes.emergencias and EsDeEmergencia(coche) then return end

        local tope = (ajustes.kmh or 30) / 3.6

        if ajustes.modo == 'avisar' then
            if GetEntitySpeed(coche) > tope * 1.08 and Cada(estado, 'aviso', 5000) then
                Aviso(('Vas por encima de los %d km/h de esta zona.'):format(ajustes.kmh or 30), 'error')
            end
            return
        end

        -- Se frena limitando el coche, no empujándolo: si se le fuerza la
        -- velocidad hacia delante, el coche da tirones y se sale en las curvas.
        estado.tocados = estado.tocados or {}
        if not estado.tocados[coche] then
            estado.tocados[coche] = GetVehicleHandlingFloat(coche, 'CHandlingData', 'fInitialDriveMaxFlatVel') or 0.0
        end
        SetEntityMaxSpeed(coche, tope)
    end,
    quitar = function(_, _, estado)
        for coche, original in pairs(estado.tocados or {}) do
            if DoesEntityExist(coche) then
                SetEntityMaxSpeed(coche, original > 0.0 and original or 200.0)
            end
        end
    end,
}

-- ── Prohibido entrar en coche ───────────────────────────────────────────────
COMO.sin_conducir = {
    cada = function(ajustes, _, estado)
        if not Cada(estado, 'mira', 800) then return end

        local ped = PlayerPedId()
        local coche = CocheDelJugador(ped)
        if not coche then return end
        if not ajustes.emergencias and EsDeEmergencia(coche) then return end

        if Cada(estado, 'aviso', 6000) then
            Aviso('Aquí se entra andando: deja el coche fuera.', 'error')
        end

        if ajustes.sacar and not IsPedGettingIntoAVehicle(ped) then
            TaskLeaveVehicle(ped, coche, 0)
        end
    end,
}

-- ── Prohibido bajarse del coche ─────────────────────────────────────────────
COMO.sin_bajarse = {
    cada = function(_, _, estado)
        local ped = PlayerPedId()
        if not CocheDelJugador(ped) then return end

        DisableControlAction(0, 75, true)   -- bajarse
        DisableControlAction(27, 75, true)

        if IsDisabledControlJustPressed(0, 75) and Cada(estado, 'aviso', 5000) then
            Aviso('Aquí no puedes bajarte del coche.', 'error')
        end
    end,
}

-- ── Altura mínima de vuelo ──────────────────────────────────────────────────
COMO.altura_vuelo = {
    cada = function(ajustes, _, estado)
        if not Cada(estado, 'mira', 500) then return end

        local ped = PlayerPedId()
        local coche = CocheDelJugador(ped)
        if not coche then return end

        local clase = GetVehicleClass(coche)
        if clase ~= 15 and clase ~= 16 then return end
        if not ajustes.emergencias and EsDeEmergencia(coche) then return end
        if GetPedInVehicleSeat(coche, -1) ~= ped then return end

        local alto = GetEntityHeightAboveGround(coche)
        if alto >= (ajustes.metros or 150) then return end

        if Cada(estado, 'aviso', 8000) then
            Aviso(('Sobre esta zona no se vuela por debajo de %d m.'):format(ajustes.metros or 150), 'error')
        end

        if ajustes.empujar then
            local v = GetEntityVelocity(coche)
            SetEntityVelocity(coche, v.x, v.y, math.max(v.z, 7.0))
        end
    end,
}

-- ── Sin armas ───────────────────────────────────────────────────────────────
COMO.sin_armas = {
    poner = function(ajustes)
        if SeLibra(ajustes) then return end
        Aviso('Aquí no se sacan armas.', 'error')
    end,
    cada = function(ajustes, _, estado)
        if SeLibra(ajustes) then return end

        DisablePlayerFiring(YO, true)

        local ped = PlayerPedId()
        if GetSelectedPedWeapon(ped) == NADA then return end

        SetCurrentPedWeapon(ped, NADA, true)

        if ajustes.avisar ~= false and Cada(estado, 'aviso', 5000) then
            Aviso('Guarda eso: en esta zona no se saca.', 'error')
        end
    end,
}

-- ── Zona segura ─────────────────────────────────────────────────────────────
-- Lo de aquí es para que no se pueda ni intentar. Que el disparo no haga daño
-- lo decide server/vigilante.lua, que es el único que no se puede tocar desde
-- el cliente del que dispara.
COMO.zona_segura = {
    poner = function(ajustes)
        if ajustes.avisar == false then return end
        Aviso('Zona segura: aquí no se le hace daño a nadie.', 'inform')
    end,
    cada = function(ajustes)
        DisablePlayerFiring(YO, true)

        if ajustes.melee == false then return end
        for i = 1, #GOLPEAR do
            DisableControlAction(0, GOLPEAR[i], true)
        end
    end,
}

-- ── Sin nivel de búsqueda ───────────────────────────────────────────────────
-- Ojo: este servidor ya arranca con la policía del juego apagada
-- (qbx_disableservices deja el máximo en 0), así que esta regla casi nunca
-- tiene nada que hacer. Se queda porque el día que se encienda, aquí está el
-- recorte. Y a propósito NO se toca SetMaxWantedLevel: es un ajuste de toda la
-- sesión, y devolverlo a 5 al salir encendería la policía en todo el mapa.
COMO.sin_busqueda = {
    poner = function()
        SetPoliceIgnorePlayer(YO, true)
        for servicio = 1, 12 do EnableDispatchService(servicio, false) end
    end,
    cada = function(ajustes, _, estado)
        if not Cada(estado, 'mira', 1000) then return end
        if ajustes.limpiar ~= false and GetPlayerWantedLevel(YO) > 0 then
            ClearPlayerWantedLevel(YO)
        end
    end,
    quitar = function()
        SetPoliceIgnorePlayer(YO, false)
        for servicio = 1, 12 do EnableDispatchService(servicio, true) end
    end,
}

-- ── Sin explosiones ─────────────────────────────────────────────────────────
-- Entera del servidor: cancela el proyectil, la explosión y el fuego. Aquí
-- solo se avisa, para que nadie se pregunte por qué la granada no ha hecho
-- nada.
COMO.sin_explosiones = {
    poner = function()
        Aviso('Aquí no vuela nada por los aires.', 'inform')
    end,
}

-- ── Quién entra ─────────────────────────────────────────────────────────────
COMO.acceso = {
    poner = function(ajustes)
        if SeLibra(ajustes) then return end
        Aviso(ajustes.mensaje or 'Este sitio no es para ti.', 'error')
    end,
}

-- ── Hora y clima propios ────────────────────────────────────────────────────
COMO.clima = {
    poner = function(ajustes, _, estado)
        if ajustes.tiempo and ajustes.tiempo ~= 'ninguno' then
            SetOverrideWeather(ajustes.tiempo)
            estado.tiempo = true
        end

        local hora = tonumber(ajustes.hora)
        if hora and hora >= 0 then
            NetworkOverrideClockTime(hora, 0, 0)
            estado.hora = true
        end
    end,
    quitar = function(_, _, estado)
        if estado.tiempo then ClearOverrideWeather() end
        if estado.hora then NetworkClearClockTimeOverride() end
    end,
}

-- ── Sin sirenas ─────────────────────────────────────────────────────────────
COMO.sin_sirenas = {
    cada = function(ajustes, _, estado)
        estado.calladas = estado.calladas or {}

        local ped = PlayerPedId()
        local mio = CocheDelJugador(ped)
        if mio and not estado.calladas[mio] then
            SetVehicleHasMutedSirens(mio, true)
            estado.calladas[mio] = true
        end

        if ajustes.alrededor == false then return end
        if not Cada(estado, 'barrido', 1500) then return end

        -- El barrido del pool es lo caro de esta regla, así que va cada segundo
        -- y medio y no cada fotograma.
        for _, coche in ipairs(GetGamePool('CVehicle')) do
            if not estado.calladas[coche] and GetVehicleClass(coche) == 18 then
                SetVehicleHasMutedSirens(coche, true)
                estado.calladas[coche] = true
            end
        end
    end,
    quitar = function(_, _, estado)
        for coche in pairs(estado.calladas or {}) do
            if DoesEntityExist(coche) then SetVehicleHasMutedSirens(coche, false) end
        end
    end,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- PONER, QUITAR Y EL HILO
-- ═══════════════════════════════════════════════════════════════════════════

function Reglas.Poner(clave, ajustes, zona)
    local como = COMO[clave]
    if not como or puestas[clave] then return end

    local puesta = { ajustes = ajustes, zona = zona, estado = {} }
    puestas[clave] = puesta

    if como.poner then
        local ok, err = pcall(como.poner, ajustes, zona, puesta.estado)
        if not ok then print(('^1[origen_zones]^7 regla %s al entrar: %s'):format(clave, err)) end
    end
end

function Reglas.Quitar(clave)
    local puesta = puestas[clave]
    if not puesta then return end

    puestas[clave] = nil

    local como = COMO[clave]
    if como and como.quitar then
        local ok, err = pcall(como.quitar, puesta.ajustes, puesta.zona, puesta.estado)
        if not ok then print(('^1[origen_zones]^7 regla %s al salir: %s'):format(clave, err)) end
    end
end

function Reglas.Puestas()
    return puestas
end

CreateThread(function()
    while true do
        local trabajo = false

        for clave, puesta in pairs(puestas) do
            local como = COMO[clave]
            if como and como.cada then
                trabajo = true
                como.cada(puesta.ajustes, puesta.zona, puesta.estado)
            end
        end

        -- Sin ninguna regla que pida fotograma, este hilo cuesta lo que cueste
        -- despertarse dos veces por segundo.
        Wait(trabajo and 0 or 500)
    end
end)

-- Al parar el recurso hay que devolver el mundo como estaba: si no, quien
-- estuviese dentro de una zona de clima se queda con la niebla puesta.
AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for clave in pairs(puestas) do Reglas.Quitar(clave) end
end)
