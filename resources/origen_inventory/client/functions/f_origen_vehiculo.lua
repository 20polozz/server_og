--[[
    Estado del vehiculo para la pestaña de vehiculo (diseño 8a).

    La pestaña ya sabia abrir puertas, ventanas, capo y maletero, pero no tenia
    de donde sacar lo demas: matricula, combustible, salud del motor y la
    carroceria, estado de cada rueda y quien va sentado. Todo eso lo da el
    juego con nativas, solo hacia falta un sitio donde pedirlo.

    Se pide bajo demanda, no en bucle: la interfaz lo llama al abrir la pestaña
    y luego cada par de segundos mientras esta a la vista. Un thread permanente
    para algo que solo se mira con el inventario abierto es tiempo regalado.
]]

--- Salud de 0 a 100 a partir de un valor de 0 a 1000, que es como lo dan las
--- nativas de motor y carroceria.
local function Porcentaje(valor, maximo)
    if not valor or not maximo or maximo == 0 then return 0 end
    local n = math.floor((valor / maximo) * 100)
    if n < 0 then n = 0 end
    if n > 100 then n = 100 end
    return n
end

--- Las cuatro puertas de un turismo, con su ventana emparejada.
--- Los indices son los del juego: 0 delantera izquierda, 1 delantera derecha,
--- 2 trasera izquierda, 3 trasera derecha.
local PUERTAS = {
    { id = 'dfl', puerta = 0, ventana = 0, nombre = 'Delantera izq.', accion = 'toggle-front-left-door',  accionVentana = 'toggle-front-left-window' },
    { id = 'dfr', puerta = 1, ventana = 1, nombre = 'Delantera der.', accion = 'toggle-front-right-door', accionVentana = 'toggle-front-right-window' },
    { id = 'dbl', puerta = 2, ventana = 2, nombre = 'Trasera izq.',   accion = 'toggle-back-left-door',   accionVentana = 'toggle-back-left-window' },
    { id = 'dbr', puerta = 3, ventana = 3, nombre = 'Trasera der.',   accion = 'toggle-back-right-door',  accionVentana = 'toggle-back-right-window' },
}

--- Las cuatro ruedas. El indice 4 y 5 son los ejes traseros de camiones, que
--- aqui no se enseñan: con cuatro esquinas ya se entiende el dibujo.
local RUEDAS = {
    { id = 'wfl', rueda = 0, nombre = 'Del. izq.' },
    { id = 'wfr', rueda = 1, nombre = 'Del. der.' },
    { id = 'wbl', rueda = 4, nombre = 'Tras. izq.' },
    { id = 'wbr', rueda = 5, nombre = 'Tras. der.' },
}

--- Los asientos, del -1 (conductor) en adelante.
local ASIENTOS = {
    { indice = -1, nombre = 'Conductor' },
    { indice = 0,  nombre = 'Copiloto' },
    { indice = 1,  nombre = 'Trasero izq.' },
    { indice = 2,  nombre = 'Trasero der.' },
}

--[[ Los nombres de personaje de los que van en el coche. Los da el servidor
     (origen_inventory:vehiculo:nombres), que solo contesta por quien va en tu
     mismo vehículo. Se guardan un minuto: la pestaña pregunta el estado cada
     dos segundos y el nombre de alguien no cambia mientras va sentado. ]]
local cacheNombres = {}

function NombresDePersonaje(ocupantes)
    local ahora, faltan, out = GetGameTimer(), {}, {}
    for _, id in pairs(ocupantes) do
        local c = cacheNombres[id]
        if c and ahora - c.t < 60000 then out[id] = c.n else faltan[#faltan + 1] = id end
    end
    if #faltan > 0 then
        local ok, r = pcall(function() return lib.callback.await('origen_inventory:vehiculo:nombres', false, faltan) end)
        if ok and type(r) == 'table' then
            for k, n in pairs(r) do
                local id = tonumber(k)
                if id and type(n) == 'string' then
                    cacheNombres[id] = { n = n, t = ahora }
                    out[id] = n
                end
            end
        end
    end
    return out
end

InventoryUI.On('GetVehicleState', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if not veh or veh == 0 then
        return { dentro = false }
    end

    local puertas = {}
    for _, d in ipairs(PUERTAS) do
        -- Solo las que el coche tiene: un dos puertas no enseña las traseras.
        if GetIsDoorValid(veh, d.puerta) then
        --[[ GetVehicleDoorAngleRatio da lo abierta que esta, de 0 a 1. Se
             considera abierta por encima de 0.05 y no de 0 exacto: una puerta
             recien cerrada devuelve valores minusculos durante un instante y
             la interfaz parpadeaba. ]]
        puertas[#puertas + 1] = {
            id = d.id,
            nombre = d.nombre,
            accion = d.accion,
            accionVentana = d.accionVentana,
            abierta = GetVehicleDoorAngleRatio(veh, d.puerta) > 0.05,
            rota = IsVehicleDoorDamaged(veh, d.puerta),
            -- Rota o bajada desde la pestaña (ver VentanaBajada en f_vehicles.lua).
            ventanaAbierta = not IsVehicleWindowIntact(veh, d.ventana)
                or (VentanaBajada ~= nil and VentanaBajada(veh, d.ventana)),
        }
        end
    end

    local ruedas = {}
    for _, r in ipairs(RUEDAS) do
        --[[ GetVehicleWheelHealth da 1000 de fabrica y 0 con la rueda
             destrozada. Si la rueda ni siquiera existe (un coche de dos ejes
             preguntado por el tercero) devuelve un numero enorme, asi que se
             acota. ]]
        local salud = GetVehicleWheelHealth(veh, r.rueda) or 0
        if salud > 1000 then salud = 1000 end
        ruedas[#ruedas + 1] = {
            id = r.id,
            nombre = r.nombre,
            valor = Porcentaje(salud, 1000),
            pinchada = IsVehicleTyreBurst(veh, r.rueda, false),
        }
    end

    local asientos = {}
    local plazas = GetVehicleMaxNumberOfPassengers(veh)

    -- Quién va en cada asiento, por su id de servidor, para pedir los nombres.
    local ocupantes = {}
    for _, a in ipairs(ASIENTOS) do
        if a.indice == -1 or a.indice < plazas then
            local quien = GetPedInVehicleSeat(veh, a.indice)
            if quien and quien ~= 0 then
                local jugador = NetworkGetPlayerIndexFromPed(quien)
                if jugador and jugador ~= -1 then ocupantes[a.indice] = GetPlayerServerId(jugador) end
            end
        end
    end
    local nombres = NombresDePersonaje(ocupantes)

    for _, a in ipairs(ASIENTOS) do
        -- Solo los asientos que el vehiculo tiene de verdad.
        if a.indice == -1 or a.indice < plazas then
            local quien = GetPedInVehicleSeat(veh, a.indice)
            local ocupado = quien ~= 0 and quien ~= nil
            local nombre = nil
            if ocupado then
                -- El del personaje, no el de Steam (ver NombresDePersonaje).
                local id = ocupantes[a.indice]
                if id then
                    nombre = nombres[id] or (quien == ped and 'Tú' or 'Ocupado')
                elseif quien == ped then
                    nombre = 'Tú'
                else
                    nombre = 'Ocupado'
                end
            end
            asientos[#asientos + 1] = {
                indice = a.indice,
                nombre = a.nombre,
                ocupante = nombre,
                esTuyo = quien == ped,
            }
        end
    end

    return {
        dentro = true,
        conductor = GetPedInVehicleSeat(veh, -1) == ped,
        matricula = (GetVehicleNumberPlateText(veh) or ''):gsub('%s+$', ''),
        motor = GetIsVehicleEngineRunning(veh),
        cerrado = GetVehicleDoorLockStatus(veh) >= 2,
        capo = GetVehicleDoorAngleRatio(veh, 4) > 0.05,
        maletero = GetVehicleDoorAngleRatio(veh, 5) > 0.05,

        -- Telemetria. El combustible ya viene en 0-100.
        combustible = math.floor(GetVehicleFuelLevel(veh) or 0),
        motorSalud = Porcentaje(GetVehicleEngineHealth(veh), 1000),
        carroceria = Porcentaje(GetVehicleBodyHealth(veh), 1000),

        puertas = puertas,
        ruedas = ruedas,
        asientos = asientos,
    }
end)

--[[ Cerrar o abrir el coche desde la pestaña (boton «Cerrar coche» del pie).
     El cierre no es cosa del inventario: lo lleva qbx_vehiclekeys, con su
     comprobacion de llaves, su animacion y su sonido. Se le pulsa su propia
     tecla (la L, registrada con lib.addKeybind como +togglelocks) para no
     duplicar nada de eso aqui. ]]
--[[ ── La radio del coche ────────────────────────────────────────────────────
     La pestaña la lleva dentro (antes cerraba el inventario y abria la pantalla
     de origen_speaker). Aqui no se toca el sonido: cada orden se le pasa a
     origen_speaker, que es de quien es la radio, y quien decide de verdad sigue
     siendo su servidor —comprueba que vas sentado en ese coche: la maneja
     cualquiera que vaya dentro—.

     Sin el recurso arrancado la pestaña se entera por `sinRadio` y enseña el
     aviso en vez de una pantalla que no haria nada. ]]
local function HayRadio()
    return GetResourceState('origen_speaker') == 'started'
end

--- Lo que pide la interfaz: una llamada al servidor del altavoz, sin fiarse.
local function Preguntar(evento, ...)
    local ok, r = pcall(function(...)
        return lib.callback.await(evento, false, ...)
    end, ...)
    if not ok then return nil end
    return r
end

InventoryUI.On('RadioEstado', function()
    if not HayRadio() then return { dentro = false, sinRadio = true } end

    local r = Preguntar('origen_speaker:server:getCarRadio')
    if type(r) ~= 'table' then return { dentro = false } end
    return r
end)

InventoryUI.On('RadioPoner', function(data)
    if not HayRadio() or type(data) ~= 'table' or type(data.url) ~= 'string' then return { ok = false } end
    return exports['origen_speaker']:CarRadioPlay(data.url)
end)

InventoryUI.On('RadioParar', function()
    if not HayRadio() then return { ok = false } end
    return exports['origen_speaker']:CarRadioStop()
end)

InventoryUI.On('RadioVolumen', function(data)
    if not HayRadio() or type(data) ~= 'table' then return { ok = false } end
    return exports['origen_speaker']:CarRadioSetVolume(tonumber(data.volumen))
end)

--- `fuera` a true: que se oiga fuera del coche, como siempre.
InventoryUI.On('RadioFuera', function(data)
    if not HayRadio() or type(data) ~= 'table' then return { ok = false } end
    return exports['origen_speaker']:CarRadioInsideOnly(not data.fuera)
end)

InventoryUI.On('RadioListas', function()
    if not HayRadio() then return { mias = {}, compartidas = {}, publicas = {} } end

    local propias = Preguntar('origen_speaker:server:getPlaylists') or {}
    local publicas = Preguntar('origen_speaker:server:getPublicPlaylists') or {}

    return {
        mias = propias.myPlaylists or {},
        compartidas = propias.sharedPlaylists or {},
        publicas = publicas or {},
    }
end)

InventoryUI.On('RadioCrearLista', function(data)
    if not HayRadio() or type(data) ~= 'table' then return { ok = false } end

    local nombre = type(data.nombre) == 'string' and data.nombre:sub(1, 40) or ''
    if nombre == '' then return { ok = false } end

    -- El export avisa al jugador si el servidor lo rechaza (tope de listas...)
    return exports['origen_speaker']:CarRadioCreatePlaylist(nombre)
end)

InventoryUI.On('RadioAnadir', function(data)
    if not HayRadio() or type(data) ~= 'table' or not data.lista then return { ok = false } end
    return exports['origen_speaker']:CarRadioAddSong(data.lista, data.url)
end)

--[[ Poner una lista es poner su primera cancion: la radio del coche reproduce
     de una en una, no tiene cola. ]]
InventoryUI.On('RadioPonerLista', function(data)
    if not HayRadio() or type(data) ~= 'table' or not data.lista then return { ok = false } end
    -- La lista vacia y los rechazos del servidor los avisa el propio export
    return exports['origen_speaker']:CarRadioPlayPlaylist(data.lista)
end)

InventoryUI.On('VehiculoCerradura', function()
    if GetResourceState('qbx_vehiclekeys') ~= 'started' then return false end
    ExecuteCommand('+togglelocks')
    SetTimeout(100, function() ExecuteCommand('-togglelocks') end)
    return true
end)
