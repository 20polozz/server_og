Conduccion = Conduccion or {}

--[[ Conduce el ped del jugador, siempre. Va en el asiento -1 de principio a
     fin, y por eso la entrega del control al llegar es un no-op: no hay cambio
     de asiento, no hay salto de camara, las llaves ya valen y el coche es
     propiedad de su cliente durante todo el trayecto. ]]

--[[ Deja el coche y al jugador listos para el trayecto.

     Nada de SetEntityInvincible sobre el ped: origen_anticheat lee
     GetPlayerInvincible y reporta el flanco false->true (client/godmode.lua:19).
     Lo que de verdad hace falta -- que no se caiga, no entre en ragdoll y no
     aborte la tarea por un susto -- se consigue por las otras vias, y el
     invencible se le pone al coche, que si se puede. ]]
function Conduccion.Preparar(ped, veh)
    if veh == 0 then return end

    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleUndriveable(veh, false)
    SetVehicleOnGroundProperly(veh)
    SetVehicleDoorsLocked(veh, 0)

    SetEntityInvincible(veh, true)
    SetVehicleTyresCanBurst(veh, false)
    SetVehicleStrong(veh, true)

    SetPedCanRagdoll(ped, false)
    Nativa('SetPedCanBeKnockedOffVehicle', ped, 1)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPlayerCanDoDriveBy(PlayerId(), false)
    Nativa('SetPedCanBeDraggedOut', ped, false)

    SetVehRadioStation(veh, 'OFF')
    SetRadioToStationName('OFF')
    SetUserRadioControlEnabled(false)
end

--[[ La nativa de conducir hasta un punto, resuelta en caliente.

     La variante de largo alcance aparece con dos grafias segun el build
     (Longrange / LongRange) y en este servidor la segunda NO existe: llamarla
     a ciegas mata el hilo a mitad de la intro. Se prueban las dos y se cae a
     TaskVehicleDriveToCoord, que es la que usa el resto del repo -- incluido
     rcore_casino, que la lanza sobre el propio PlayerPedId. ]]
local conducir
local elegida

local function ResolverNativa()
    if conducir then return conducir end

    if type(TaskVehicleDriveToCoordLongrange) == 'function' then
        elegida = 'TaskVehicleDriveToCoordLongrange'
        conducir = function(ped, veh, d, C)
            TaskVehicleDriveToCoordLongrange(ped, veh, d.x, d.y, d.z,
                C.velocidad, C.estilo, C.radioParada)
        end
    elseif type(TaskVehicleDriveToCoordLongRange) == 'function' then
        elegida = 'TaskVehicleDriveToCoordLongRange'
        conducir = function(ped, veh, d, C)
            TaskVehicleDriveToCoordLongRange(ped, veh, d.x, d.y, d.z,
                C.velocidad, C.estilo, C.radioParada)
        end
    else
        elegida = 'TaskVehicleDriveToCoord'
        conducir = function(ped, veh, d, C)
            TaskVehicleDriveToCoord(ped, veh, d.x, d.y, d.z,
                C.velocidad, 0, GetEntityModel(veh), C.estilo, C.radioParada)
        end
    end

    if Config.Debug then
        print(('^5[origen_intro]^0 conduciendo con %s'):format(elegida))
    end

    return conducir
end

--[[ El punto al que se manda la IA: `metros` mas alla del destino, siguiendo su
     rumbo. En GTA el vector hacia delante de un rumbo h es (-sin, cos).

     Existe para que el coche cruce el punto de entrega a velocidad de crucero:
     si la IA apuntara al destino, empezaria a frenar bastante antes y el
     jugador recibiria un coche casi parado. ]]
local function MasAlla(ruta, metros)
    local destino = ruta.destino
    local rad = math.rad(destino.w or 0.0)
    local dx, dy = -math.sin(rad), math.cos(rad)

    --[[ Si la w del destino apunta en contra del sentido de la marcha -- una
         ruta mal configurada -- la prolongacion caeria DETRAS y el coche daria
         media vuelta justo al final. Ahi manda el sentido real del viaje. ]]
    local vx, vy = destino.x - ruta.spawn.x, destino.y - ruta.spawn.y
    if (dx * vx + dy * vy) <= 0.0 then
        local largo = math.sqrt(vx * vx + vy * vy)
        if largo > 0.01 then dx, dy = vx / largo, vy / largo end
    end

    return { x = destino.x + dx * metros, y = destino.y + dy * metros, z = destino.z }
end

--- Le dice al jugador que conduzca. Se puede llamar de nuevo para reemitir la
--- tarea si el vigilante ve que el coche se ha quedado clavado.
function Conduccion.Tarea(ped, veh, ruta)
    if veh == 0 or not ruta or not ruta.destino then return end

    local C = Config.Conduccion

    SetDriveTaskDrivingStyle(ped, C.estilo)
    ResolverNativa()(ped, veh, MasAlla(ruta, C.margenPasado), C)

    -- Sin esto el motor de tareas puede descartar la de script en cuanto
    -- considera que el ped ha vuelto a manos del jugador.
    SetPedKeepTask(ped, true)
    SetDriverAbility(ped, 1.0)
    SetDriverAggressiveness(ped, 0.0)
end

--[[ Bloqueo de controles mientras dura la intro.

     Se apaga el grupo entero en vez de una lista negra a mano: en teclado la
     direccion tambien entra por los controles genericos de movimiento (30-34),
     el salto (22) es freno de mano dentro del coche, y ademas estan todos los
     INPUT_VEH_*. Cualquier lista se queda corta, y basta un frame de input para
     que el motor le devuelva el volante al jugador y cancele la tarea -- que es
     la causa numero uno de que un autopilot se rompa.

     El grupo 2 (FRONTEND) se deja vivo para no romper NUI ni chat, y se
     reactiva el push to talk para que pueda hablar durante el viaje. ]]
function Conduccion.Suprimir()
    CreateThread(function()
        while Intro.activo do
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true)
            EnableControlAction(0, 252, true)

            -- Atajo Q (44) + R (45) para asegurar silencio de musica/radio
            if IsDisabledControlPressed(0, 44) and IsDisabledControlPressed(0, 45) then
                local veh = Intro.vehiculo and Intro.vehiculo()
                if veh and veh ~= 0 then
                    SetVehRadioStation(veh, 'OFF')
                    SetRadioToStationName('OFF')
                    SetUserRadioControlEnabled(false)
                end
            end
            Wait(0)
        end
    end)
end

--- Devuelve el ped y el coche a su estado normal. Aguanta que la llamen de mas.
function Conduccion.Soltar(ped, veh)
    SetUserRadioControlEnabled(true)
    if ped and ped ~= 0 then
        SetPedKeepTask(ped, false)
        ClearPedTasks(ped)
        SetBlockingOfNonTemporaryEvents(ped, false)
        SetPedCanRagdoll(ped, true)
        Nativa('SetPedCanBeKnockedOffVehicle', ped, 0)
        Nativa('SetPedCanBeDraggedOut', ped, true)
        SetPlayerCanDoDriveBy(PlayerId(), true)
    end

    if veh and veh ~= 0 and DoesEntityExist(veh) then
        SetEntityInvincible(veh, false)
        SetVehicleTyresCanBurst(veh, true)
        SetVehicleStrong(veh, false)
        SetEntityAsMissionEntity(veh, false, true)
    end
end
