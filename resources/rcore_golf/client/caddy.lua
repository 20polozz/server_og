--[[ NOTA DE ORIGEN: este recurso ya no crea blips del juego.

     Los puntos se registran en origen_map, que es de donde los leen los tres
     mapas del servidor (el minimapa, el del menu de pausa y la pestaña de
     Ciudad del inventario). El ayudante que lo hace se carga desde el
     fxmanifest: '@origen_map/shared/marcar.lua'.

     Es un recurso de terceros: si llega una version nueva, este cambio hay que
     volver a hacerlo. ]]

AddTextEntry("RGOLF_CADDY_SPAWNED", Texts.caddySpawned)

function GetSuitableCaddySpawnLocation(locations)
    for _, caddyCoords in pairs(locations) do
        if IsPositionOccupied(caddyCoords.x, caddyCoords.y, caddyCoords.z, 3.0, false, true, false, false, false, 0, false) then
            return caddyCoords
        end
    end
    return locations[math.random(1, #locations)]
end

function SetCaddyBlipData(caddy, playerNum)
    caddyBlip = 'caddy_' .. tostring(playerNum or 1)
    OrigenMapa.Poner(caddyBlip, {
        entidad = caddy,
        cat = 'activities',
        icono = 'golf',
    })
end

RegisterNetEvent("rcore_golf:spawnCaddy", function(playerNum, splitLocations, locationName)
    local vehicleHash = GetHashKey(Config.CaddyVehicleName)
    RequestModelAsync(vehicleHash)
    local vehicleCoords = GetSuitableCaddySpawnLocation(splitLocations)
    vehicleCaddy = CreateVehicle(vehicleHash, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleCoords.w, true, true)
    SetVehicleFuelLevel(vehicleCaddy, 100.0)
    CaddyCreated = true
    ShowTimedHelpText("RGOLF_CADDY_SPAWNED", 7500)
    Citizen.SetTimeout(7500, function()
        CaddyCreated = false
    end)
    SetCaddyBlipData(vehicleCaddy, playerNum)
    vehicleCaddyNetId = NetworkGetNetworkIdFromEntity(vehicleCaddy)
    TriggerServerEvent("rcore_golf:setCaddyLocks", vehicleCaddyNetId, locationName)
end)