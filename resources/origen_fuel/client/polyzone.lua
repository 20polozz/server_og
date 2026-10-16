local creatingZone = false
local zonePoints = {}
local tempMarkers = {}
local callback = nil

local function DrawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local camCoords = GetGameplayCamCoords()
    local dist = #(coords - camCoords)
    
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    
    if onScreen then
        SetTextScale(0.35 * scale, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(x, y)
    end
end

local function DrawLine3D(from, to, r, g, b, a)
    DrawLine(from.x, from.y, from.z, to.x, to.y, to.z, r, g, b, a or 255)
end

local function DrawZonePreview()
    if #zonePoints < 1 then return end
    
    -- Dibujar marcadores en cada punto
    for i, point in ipairs(zonePoints) do
        DrawMarker(
            28, -- Marker tipo cilindro
            point.x, point.y, point.z,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            0.5, 0.5, 1.5,
            216, 27, 85, 150, -- El rosa de la casa (Nación lo repinta con tema.lua)
            false, true, 2, false, nil, nil, false
        )
        
        -- Texto con número del punto
        DrawText3D(vector3(point.x, point.y, point.z + 1.5), "Punto " .. i)
    end
    
    -- Dibujar líneas entre puntos
    for i = 1, #zonePoints do
        local nextIndex = (i % #zonePoints) + 1
        DrawLine3D(
            vector3(zonePoints[i].x, zonePoints[i].y, zonePoints[i].z),
            vector3(zonePoints[nextIndex].x, zonePoints[nextIndex].y, zonePoints[nextIndex].z),
            216, 27, 85, 200
        )
    end
end

local function ShowHelpText(text)
    -- La barra de teclas del servidor (origen_hud); la de GTA solo si no esta.
    if GetResourceState('origen_hud') == 'started' then
        return exports.origen_hud:Ayuda(text)
    end
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function StartZoneCreation(cb)
    if creatingZone then
        -- Se contesta igual (sin puntos): quien llama solto el raton para
        -- marcar y tiene que recuperarlo, o el panel se queda sin raton.
        if cb then cb(nil) end
        return
    end
    
    creatingZone = true
    zonePoints = {}
    callback = cb
    
    lib.notify({
        title = 'Zona de gasolinera',
        -- Las teclas ya las dice la barra de ayuda de abajo (ShowHelpText).
        description = 'Pon los puntos andando por el borde de la gasolinera.',
        type = 'inform',
        duration = 5000
    })
    
    CreateThread(function()
        while creatingZone do
            Wait(0)
            
            -- Dibujar preview de la zona
            DrawZonePreview()
            
            -- Mostrar ayuda
            if #zonePoints < 3 then
                ShowHelpText("~INPUT_PICKUP~ Añadir punto (" .. #zonePoints .. " de 3 como mínimo)")
            else
                ShowHelpText("~INPUT_PICKUP~ Añadir punto~n~~INPUT_FRONTEND_ACCEPT~ Terminar")
            end
            
            -- Tecla E para agregar punto
            if IsControlJustPressed(0, 38) then -- E
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                
                table.insert(zonePoints, {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z
                })
                
                lib.notify({
                    title = 'Punto añadido',
                    description = 'Punto ' .. #zonePoints .. ' añadido a la zona',
                    type = 'success'
                })
            end
            
            -- Tecla ENTER para finalizar
            if IsControlJustPressed(0, 18) then -- ENTER
                if #zonePoints < 3 then
                    lib.notify({
                        title = 'Gasolinera',
                        description = 'Hacen falta al menos 3 puntos para crear la zona',
                        type = 'error'
                    })
                else
                    lib.notify({
                        title = 'Zona creada',
                        description = 'Zona creada con ' .. #zonePoints .. ' puntos',
                        type = 'success'
                    })
                    
                    if callback then
                        callback(zonePoints)
                    end
                    
                    creatingZone = false
                    zonePoints = {}
                    callback = nil
                end
            end
            
            -- Tecla BACKSPACE para cancelar
            if IsControlJustPressed(0, 177) then -- BACKSPACE
                lib.notify({
                    title = 'Cancelado',
                    description = 'Se ha cancelado la creación de la zona',
                    type = 'error'
                })

                -- Se avisa sin puntos: el panel de admin seguia pintado y sin
                -- raton, porque solo se le devolvia al terminar la zona.
                local alCancelar = callback
                creatingZone = false
                zonePoints = {}
                callback = nil
                if alCancelar then alCancelar(nil) end
            end
            
            -- Deshabilitar controles
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 47, true) -- Weapon wheel
            DisableControlAction(0, 58, true) -- Next weapon
            DisableControlAction(0, 263, true) -- Melee attack
            DisableControlAction(0, 264, true) -- Melee attack
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 140, true) -- Melee attack light
            DisableControlAction(0, 141, true) -- Melee attack heavy
            DisableControlAction(0, 142, true) -- Melee attack alternate
            DisableControlAction(0, 143, true) -- Melee block
        end
    end)
end

-- Export para iniciar la creación de zona
exports('StartZoneCreation', StartZoneCreation)

-- Función para verificar si un punto está dentro de un polyzone
local function IsPointInZone(point, zone)
    if not zone or #zone < 3 then return false end
    
    local x, y = point.x, point.y
    local inside = false
    local j = #zone
    
    for i = 1, #zone do
        local xi, yi = zone[i].x, zone[i].y
        local xj, yj = zone[j].x, zone[j].y
        
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    
    return inside
end

exports('IsPointInZone', IsPointInZone)

-- Función para obtener la gasolinera más cercana basada en polyzone
local function GetClosestStationByZone(coords)
    local stations = GlobalState.Stations or {}
    
    for id, station in pairs(stations) do
        if station.polyzone and IsPointInZone(coords, station.polyzone) then
            return id, station
        end
    end
    
    return nil, nil
end

exports('GetClosestStationByZone', GetClosestStationByZone)

