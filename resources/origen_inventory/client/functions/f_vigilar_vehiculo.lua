--[[
    Cerrar el maletero y la guantera cuando dejas de estar delante.

    El inventario ya vigilaba la distancia al CACHEAR a otro jugador
    (client/function.lua), pero no al abrir un vehiculo. Se podia abrir la
    guantera sentado dentro, bajarse, irse andando y seguir moviendo objetos a
    veinte metros; o guardar el coche en el garaje con la guantera abierta y
    quedarte con un inventario que ya no existe.

    Aqui se vigila UNA cosa: que sigas al lado del vehiculo con el que abriste.
    Se guarda la entidad concreta, no "el coche mas cercano": si te bajas y
    pasa otro por al lado, el que importa es el tuyo.
]]

-- Cuanto puedes alejarte antes de que se cierre solo. Los seis metros dan
-- margen para rodear el coche —de la guantera al maletero hay su trecho en un
-- camion— sin dejarte cruzar la calle.
local DISTANCIA_MAXIMA = 6.0

local vigilando = false

--[[ Empieza a vigilar el vehiculo con el que se acaba de abrir un inventario.

     Se llama justo despues de Inventory.open, con la entidad del vehiculo. Si
     ya habia una vigilancia en marcha no se abre otra: el bucle anterior se
     entera solo de que el inventario se cerro y termina. ]]
function VigilarVehiculo(vehiculo)
    if vigilando then return end
    if not vehiculo or vehiculo == 0 then return end

    vigilando = true

    CreateThread(function()
        --[[ Un respiro antes de empezar: el inventario tarda un momento en
             marcarse como abierto, y sin esto el bucle veria isOpen en false
             en la primera vuelta y se cerraria a si mismo. ]]
        local espera = 0
        while (not Player or not Player.isOpen) and espera < 20 do
            Wait(100)
            espera = espera + 1
        end

        while Player and Player.isOpen do
            Wait(500)

            -- El coche ya no esta: lo han guardado, se ha destruido o has
            -- salido de su alcance de red. No hay inventario que mirar.
            if not DoesEntityExist(vehiculo) then
                Player:CloseInventory()
                break
            end

            local yo = GetEntityCoords(PlayerPedId())
            local suyo = GetEntityCoords(vehiculo)

            if #(yo - suyo) > DISTANCIA_MAXIMA then
                Player:CloseInventory()

                -- Se dice por que se ha cerrado: un inventario que desaparece
                -- solo parece un fallo del recurso.
                if Bridge and Bridge.Notify then
                    Bridge.Notify('Te has alejado del vehículo', 'error')
                end
                break
            end
        end

        vigilando = false
    end)
end
