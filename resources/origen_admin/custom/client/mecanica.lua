--[[ Los arreglos de vehiculo del panel son nativas de cliente: dejan la salud de
     GTA a tope y no tocan el estado de `origen_mechanic`, asi que el coche sigue
     averiado por dentro y su motor sigue sin arrancar. Esto avisa al dueño del
     estado.

     El cliente NO manda que vehiculo es: lo resuelve el servidor desde el ped.
     Aqui solo se comprueba que la accion es sobre el coche en el que se esta,
     porque si no el aviso pediria sincronizar otra cosa distinta. ]]
function SincronizarMecanica(accion, vehicle)
    if type(accion) ~= 'string' then return end
    if GetResourceState('origen_mechanic') ~= 'started' then return end

    local actual = GetVehiclePedIsIn(PlayerPedId(), false)
    if not actual or actual == 0 then return end
    if vehicle and vehicle ~= 0 and vehicle ~= actual then return end

    TriggerServerEvent('origen_admin:server:sincronizarMecanica', accion)
end
