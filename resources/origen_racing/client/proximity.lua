-- Sistema de proximidad para Racing Hub
local activeBlip = nil
local activeRoute = false

-- Limpiar blip y ruta
local function ClearProximityMarkers()
    if activeBlip then
        -- Ya no es un blip del juego sino la clave de un punto de origen_map
        -- ('salida'): con RemoveBlip el punto se quedaba puesto para siempre.
        if type(activeBlip) == 'string' then
            OrigenMapa.Quitar(activeBlip)
        else
            RemoveBlip(activeBlip)
        end
        activeBlip = nil
    end
    
    if activeRoute then
        SetWaypointOff()
        ClearGpsMultiRoute()
        activeRoute = false
    end
end

-- Evento para limpiar marcadores. Locales (los lanzan main.lua y
-- nui_callbacks.lua): como eventos de red los podia lanzar cualquiera.
AddEventHandler('racing:clearProximityMarkers', function()
    ClearProximityMarkers()
end)

-- Evento para guardar el blip
AddEventHandler('racing:storeProximityBlip', function(blip)
    activeBlip = blip
    activeRoute = true
end)

-- Limpiar al desconectar
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ClearProximityMarkers()
    end
end)

