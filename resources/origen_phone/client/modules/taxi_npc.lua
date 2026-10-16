--[[ El pasajero de una carrera de NPC del taxi (Config.Rides.TaxiNpc).

     La carrera la saca el servidor y va por la app como cualquier otra; aqui
     solo vive la persona: aparece en la acera al acercarse el taxi, sube
     cuando el taxi para a su lado (o cuando se pulsa "he llegado"), va
     sentado detras y se baja al terminar.

     Lo que NO esta aqui es si el taxista ha llegado o ha terminado: eso lo
     mira el servidor con la posicion de verdad del jugador (NpcEnSuSitio en
     server/api/rides.lua). Si lo decidiera este fichero, bastaria con decir
     que si desde casa para cobrar una carrera que no paga nadie.
]]

--- La carrera en curso tal y como la manda el servidor, o nil.
local Carrera = nil
--- El pasajero, si ya esta en el mundo.
local Pasajero = nil
local hilo = false
local avisado = false

--- A partir de esta distancia a la recogida aparece el pasajero.
local APARECER = 120.0

local function Avisar(texto, tipo)
    lib.notify({ description = texto, type = tipo or 'inform' })
end

--[[ Donde se pone el pasajero: la acera mas cercana al punto.

     Los puntos de la configuracion son calles, no aceras medidas al metro, y
     un ped puesto a pelo en esas coordenadas sale en mitad de la calzada o
     dentro de un edificio. ]]
local function Acera(p)
    local ok, sitio = GetSafeCoordForPed(p.x, p.y, p.z, true, 16)
    if ok then return sitio end

    ok, sitio = GetSafeCoordForPed(p.x, p.y, p.z, false, 0)
    if ok then return sitio end

    for _, arriba in ipairs({ 2.0, 10.0, 25.0, 50.0 }) do
        local hay, z = GetGroundZFor_3dCoord(p.x, p.y, p.z + arriba, false)
        if hay then return vector3(p.x, p.y, z) end
    end

    return vector3(p.x, p.y, p.z)
end

local function Crear(c)
    local modelo = joaat(c.model or 'a_m_y_downtown_01')
    if not IsModelInCdimage(modelo) then modelo = joaat('a_m_y_downtown_01') end

    RequestModel(modelo)
    local limite = GetGameTimer() + 5000
    while not HasModelLoaded(modelo) and GetGameTimer() < limite do Wait(50) end
    if not HasModelLoaded(modelo) then return nil end

    local sitio = Acera(c.pickup)
    local ped = CreatePed(4, modelo, sitio.x, sitio.y, sitio.z, math.random(0, 359) + 0.0, true, true)
    SetModelAsNoLongerNeeded(modelo)
    if not ped or ped == 0 then return nil end

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCanBeDraggedOut(ped, false)
    SetPedKeepTask(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_MOBILE', 0, true)

    return ped
end

--- Se va andando y el juego se lo lleva cuando no se le vea.
local function Despedir(ped)
    if not ped or not DoesEntityExist(ped) then return end

    CreateThread(function()
        local coche = GetVehiclePedIsIn(ped, false)
        if coche ~= 0 then
            TaskLeaveVehicle(ped, coche, 0)
            local limite = GetGameTimer() + 8000
            while DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) and GetGameTimer() < limite do Wait(200) end
        end

        if not DoesEntityExist(ped) then return end
        ClearPedTasks(ped)
        TaskWanderStandard(ped, 10.0, 10)
        Wait(20000)

        if DoesEntityExist(ped) then
            SetEntityAsMissionEntity(ped, false, true)
            SetPedAsNoLongerNeeded(ped)
        end
    end)
end

--- El primer asiento libre, mejor detras como en un taxi.
local function Asiento(coche)
    for _, asiento in ipairs({ 1, 2, 0 }) do
        if asiento < GetVehicleMaxNumberOfPassengers(coche) and IsVehicleSeatFree(coche, asiento) then
            return asiento
        end
    end
    return nil
end

local subiendo = false

--- Sube al taxi: andando si puede, y si no llega, sentado directamente.
local function Subir(forzar)
    local ped, coche = Pasajero, GetVehiclePedIsIn(PlayerPedId(), false)
    if subiendo or not ped or coche == 0 or IsPedInVehicle(ped, coche, false) then return end

    local asiento = Asiento(coche)
    if not asiento then
        Avisar('No queda asiento libre para el cliente.', 'error')
        return
    end

    subiendo = true
    CreateThread(function()
        ClearPedTasks(ped)
        if not forzar then
            TaskEnterVehicle(ped, coche, 15000, asiento, 1.0, 1, 0)
            local limite = GetGameTimer() + 15000
            while DoesEntityExist(ped) and not IsPedInVehicle(ped, coche, false) and GetGameTimer() < limite do
                Wait(200)
            end
        end

        if DoesEntityExist(ped) and not IsPedInVehicle(ped, coche, false) then
            ClearPedTasksImmediately(ped)
            SetPedIntoVehicle(ped, coche, asiento)
        end

        subiendo = false
        if Carrera and Carrera.status ~= 'onboard' and not avisado then
            avisado = true
            Avisar('El cliente ya está dentro. Pulsa «Recogido» en el móvil.', 'success')
        end
    end)
end

local function Vigilar()
    if hilo then return end
    hilo = true

    CreateThread(function()
        while Carrera do
            local c = Carrera
            local yo = PlayerPedId()
            local pos = GetEntityCoords(yo)
            local recogida = vector3(c.pickup.x, c.pickup.y, c.pickup.z)

            if c.status == 'accepted' or c.status == 'arrived' then
                if (not Pasajero or not DoesEntityExist(Pasajero)) and #(pos - recogida) < APARECER then
                    Pasajero = Crear(c)
                end

                -- Sube cuando el taxi para a su lado, sin esperar al boton.
                local coche = GetVehiclePedIsIn(yo, false)
                if Pasajero and DoesEntityExist(Pasajero) and coche ~= 0
                    and #(GetEntityCoords(Pasajero) - GetEntityCoords(coche)) < 14.0
                    and GetEntitySpeed(coche) < 1.5 then
                    Subir(false)
                end
            elseif c.status == 'onboard' then
                -- Pulsado "recogido" sin que haya subido: se sienta ya.
                if Pasajero and DoesEntityExist(Pasajero) and not IsPedInAnyVehicle(Pasajero, false) then
                    Subir(true)
                end
            end

            Wait(500)
        end

        hilo = false
    end)
end

RegisterNetEvent('origen_phone:cl:taxiNpc', function(c)
    if type(c) ~= 'table' then return end

    if c.status == 'done' or c.status == 'cancelled' then
        if Carrera and Carrera.id == c.id then
            Despedir(Pasajero)
            Pasajero, Carrera, avisado = nil, nil, false
        end
        return
    end

    -- Otra carrera distinta: la anterior ya no tiene pasajero.
    if Carrera and Carrera.id ~= c.id then
        Despedir(Pasajero)
        Pasajero, avisado = nil, false
    end

    Carrera = c
    Vigilar()

    if c.status == 'arrived' then Subir(false) end
end)

AddEventHandler('onResourceStop', function(nombre)
    if nombre ~= GetCurrentResourceName() then return end
    if Pasajero and DoesEntityExist(Pasajero) then DeleteEntity(Pasajero) end
end)
