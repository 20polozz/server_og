--[[
    La parte del cliente: mide lo que solo se puede medir aqui.

    Conducir y volar no son eventos, son algo que pasa poco a poco, asi que hay
    que ir sumando distancia. Lo demas —reparar, hackear, forzar, robar— si son
    eventos, y se escuchan donde ya ocurren.

    Nada de esto decide nada: solo avisa al servidor de lo que ha pasado. Lo
    que se guarda y el porcentaje que sale de ello es cosa suya.
]]

--- Lo acumulado desde el ultimo aviso, para no mandar uno por metro.
local pendiente = {}

local function Sumar(habilidad, cuanto)
    if not cuanto or cuanto <= 0 then return end
    pendiente[habilidad] = (pendiente[habilidad] or 0) + cuanto
end

--[[ Cada tanto se manda lo acumulado y se vacia. Si el jugador se va antes,
     se pierde lo del ultimo tramo; es un precio pequeño al lado de mandar un
     evento al servidor por cada metro recorrido. ]]
CreateThread(function()
    while true do
        Wait(Config.GuardarCada)

        local hay = false
        for _ in pairs(pendiente) do hay = true break end
        if hay then
            TriggerServerEvent('origen_habilidades:sumar', pendiente)
            pendiente = {}
        end
    end
end)

--[[ ── Conduccion y pilotaje ────────────────────────────────────────────

     Se mide DISTANCIA, no tiempo: estar parado con el motor encendido no
     enseña a conducir, y contar tiempo premiaria justo eso.

     Solo cuenta si vas al volante. De copiloto no conduces tu. ]]
CreateThread(function()
    local anterior = nil

    while true do
        Wait(2000)

        local ped = PlayerPedId()
        local vehiculo = GetVehiclePedIsIn(ped, false)

        if vehiculo ~= 0 and GetPedInVehicleSeat(vehiculo, -1) == ped then
            local coords = GetEntityCoords(ped)

            if anterior then
                local metros = #(coords - anterior)

                --[[ Un salto de mas de 500 m en dos segundos no es conducir:
                     es un teleport, una carga de mapa o el servidor tirando.
                     Sin este tope, un solo teletransporte da el 100 % de la
                     habilidad de golpe. ]]
                if metros > 1 and metros < 500 then
                    local clase = GetVehicleClass(vehiculo)
                    -- 15 helicoptero, 16 avion. Lo demas rueda por el suelo.
                    local habilidad = (clase == 15 or clase == 16) and 'pilotaje' or 'conduccion'
                    Sumar(habilidad, metros / 1000.0)
                end
            end

            anterior = coords
        else
            -- Al bajarse se olvida la posicion: si no, el trayecto a pie hasta
            -- el siguiente coche contaria como conducido.
            anterior = nil
        end
    end
end)

--[[ ── Minijuegos ───────────────────────────────────────────────────────

     origen_minijuegos avisa del resultado de CUALQUIER minijuego con su
     nombre. Un solo enganche cubre todos los recursos que los usen. ]]
AddEventHandler('origen_minijuegos:result', function(juego, exito)
    if not exito then return end   -- fallar no enseña
    local habilidad = Config.Minijuegos[juego]
    if habilidad then Sumar(habilidad, 1) end
end)

--- ── Mecanica ─────────────────────────────────────────────────────────
AddEventHandler('origen_businesses:client:mechanic:repairVehicle', function()
    Sumar('mecanica', 1)
end)
