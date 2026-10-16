local playerBlips = {}

--- Mismo criterio que usa ToggleBlips para decidir si toca encender o apagar.
function BlipsActivos()
    return #playerBlips > 0
end

function ToggleBlips()
    if #playerBlips == 0 then
        EnableBlips()
    else
        DisableBlips()
    end
end

--[[ Los jugadores, en el mapa.

     Ya no son blips del juego: se registran como puntos en origen_map y de ahi
     los leen los tres mapas del servidor. Van con `entidad`, que es lo que
     hace que el punto siga al ped en vez de quedarse clavado donde estaba, y
     con prioridad alta para que el corte por distancia del minimapa no se los
     coma: un administrador mira este mapa justo para ver a los que estan
     lejos.

     Y se borran solos cuando el jugador deja de existir cerca —de eso se
     encarga el registro—, que es lo que antes hacia el propio blip de entidad. ]]
function EnableBlips()
    local players = GetActivePlayers()
    for i = 1, #players do
        local idx = players[i]
        local clave = 'jugador_' .. tostring(GetPlayerServerId(idx))

        playerBlips[idx] = clave

        OrigenMapa.Poner(clave, {
            entidad = GetPlayerPed(idx),
            cat = 'eventos',
            icono = 'persona',
            nombre = GetPlayerName(idx),
            prioridad = 10,
        })
    end
end

function DisableBlips()
    for _, clave in pairs(playerBlips) do
        OrigenMapa.Quitar(clave)
    end
    playerBlips = {}
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        DisableBlips()
    end
end)