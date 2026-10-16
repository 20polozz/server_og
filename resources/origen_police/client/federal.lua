local inside = false
local prisonMinutes = 0
local dynamicPerimeter = nil

if not Config.Federal.Exits then
    print("You have a syntax error in config/federal.lua or you're missing the Exits table, we don't give support for this, just revert your changed or redownload the file from keymaster.")
end

-- ─── Sincronizar Perímetro de Prisión Federal ─────────────────
CreateThread(function()
    Wait(2000)
    FW_TriggerCallback("origen_police:server:getFederalPerimeter", function(pts)
        if pts and #pts >= 3 then
            dynamicPerimeter = pts
        end
    end)
end)

RegisterNetEvent("origen_police:client:syncFederalPerimeter", function(pts)
    if pts and #pts >= 3 then
        dynamicPerimeter = pts
    end
end)

function IsPointInPolygon(point, polygon)
    if not polygon or #polygon < 3 then return false end
    local x, y = point.x, point.y
    local isInside = false
    local j = #polygon
    for i = 1, #polygon do
        local p1 = polygon[i]
        local p2 = polygon[j]
        local xi, yi = p1.x or p1[1], p1.y or p1[2]
        local xj, yj = p2.x or p2[1], p2.y or p2[2]
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            isInside = not isInside
        end
        j = i
    end
    return isInside
end

function IsInsidePrisonPerimeter(pcoords)
    local poly = dynamicPerimeter or Config.Federal.Perimeter
    if poly and #poly >= 3 then
        return IsPointInPolygon(pcoords, poly)
    else
        return #(pcoords - Config.Federal.Center) <= (Config.Federal.Radius or 190.0)
    end
end

function isInPrision()
    return inside
end

exports("IsInPrision", isInPrision)

RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
    if GetResourceState("origen_titlemenu") == "started" then return end
    Wait(2000)
    local PlayerData = FW_GetPlayerData(true)
    if PlayerData.metadata and PlayerData.metadata["federal"] == 1 then
        Wait(2000)
        SpawnInFederal(PlayerData)
    end
end)

function SpawnInFederal(PlayerData)
    SetEntityVisible(PlayerPedId(), true)
    if Config.OwnPrisionSystem then
        SpawnInJail(PlayerData)
    else
        FreezeEntityPosition(PlayerPedId(), false)
        FW_TriggerCallback("origen_police:callback:GetFederal", function(result)
            if result and result.time and tonumber(result.time) > 0 then
                SetFederal(tonumber(result.time), result.danger)
            else
                SetFederal(false)
            end
        end, PlayerData.citizenid)
    end
end

function SetFederal(minutes, danger)
    if Config.OwnPrisionSystem then
        setPrision(minutes, danger)
    else
        if minutes and tonumber(minutes) and tonumber(minutes) > 0 then
            prisonMinutes = tonumber(minutes)
            local joinedfrom = "Mission Row"
            if danger then
                local pcoords = GetEntityCoords(PlayerPedId())
                local b
                for k, v in pairs(Config.Federal.Exits or {}) do
                    local d = #(pcoords - v.xyz)
                    if not b or b > d then
                        b = d
                        joinedfrom = k
                    end
                end
            end
            TriggerServerEvent("origen_police:server:setfederal", prisonMinutes, danger, joinedfrom)
            Wait(500)

            if not inside then
                inside = true
                CreateThread(function()
                    local seconds = Config.TimePerMonth or 60
                    SendNUIMessage({
                        action = "Federal",
                        mins = prisonMinutes
                    })
                    local escaped = false
                    while prisonMinutes > 0 and inside do
                        Wait(1000)
                        
                        local pcoords = GetEntityCoords(PlayerPedId())
                        local isInsidePerimeter = IsInsidePrisonPerimeter(pcoords)
                        if not isInsidePerimeter then
                            if not escaped then
                                escaped = true
                                ShowNotification("¡Has salido del perímetro de la prisión! La policía ha sido alertada.")
                                TriggerServerEvent("origen_police:server:prisonEscapeStart", pcoords)
                            else
                                TriggerServerEvent("origen_police:server:prisonEscapeUpdate", pcoords)
                            end
                        else
                            if escaped then
                                escaped = false
                                ShowNotification("Has vuelto dentro del perímetro de la Prisión Federal.")
                                TriggerServerEvent("origen_police:server:prisonEscapeEnd")
                            end
                        end
        
                        seconds = seconds - 1
                        if seconds <= 0 then
                            seconds = Config.TimePerMonth or 60
                            prisonMinutes = prisonMinutes - 1
                            if prisonMinutes > 0 then
                                TriggerServerEvent("origen_police:server:updatemins", prisonMinutes)
                                SendNUIMessage({
                                    action = "Federal",
                                    mins = prisonMinutes
                                })
                            else
                                -- Condena cumplida: teletransportar fuera a la salida
                                if escaped then
                                    escaped = false
                                    TriggerServerEvent("origen_police:server:prisonEscapeEnd")
                                end
                                inside = false
                                prisonMinutes = 0
                                DoScreenFadeOut(500)
                                Wait(600)
                                TriggerServerEvent("origen_police:server:setfederal", false)
                                SendNUIMessage({
                                    action = "Federal"
                                })
                                local exit = (Config.Federal.Exits and Config.Federal.Exits[joinedfrom]) 
                                    or (Config.Federal.Exits and Config.Federal.Exits[Config.DefaultExit]) 
                                    or (Config.Federal.Exits and Config.Federal.Exits["Mission Row"])
                                if Config.ForcedExit and Config.ForcedExit.enabled then
                                    exit = Config.ForcedExit.coords
                                end
                                if exit then
                                    SetEntityCoords(PlayerPedId(), exit.x, exit.y, exit.z, false, false, false, false)
                                    SetEntityHeading(PlayerPedId(), exit.w or 0.0)
                                end
                                Wait(500)
                                DoScreenFadeIn(500)
                                ShowNotification("Has cumplido tu condena y has salido de la Prisión Federal")
                            end
                        end
                    end
                    if escaped then
                        escaped = false
                        TriggerServerEvent("origen_police:server:prisonEscapeEnd")
                    end
                end)
            else
                SendNUIMessage({
                    action = "Federal",
                    mins = prisonMinutes
                })
            end
        else
            inside = false
            prisonMinutes = 0
            DoScreenFadeOut(500)
            Wait(600)
            TriggerServerEvent("origen_police:server:setfederal", false)
            TriggerServerEvent("origen_police:server:prisonEscapeEnd")
            SendNUIMessage({
                action = "Federal"
            })
            local exit = (Config.Federal.Exits and Config.Federal.Exits[Config.DefaultExit]) 
                or (Config.Federal.Exits and Config.Federal.Exits["Mission Row"])
            if Config.ForcedExit and Config.ForcedExit.enabled then
                exit = Config.ForcedExit.coords
            end
            if exit then
                SetEntityCoords(PlayerPedId(), exit.x, exit.y, exit.z, false, false, false, false)
                SetEntityHeading(PlayerPedId(), exit.w or 0.0)
            end
            Wait(500)
            DoScreenFadeIn(500)
        end
    end
end

exports("SpawnInFederal", SpawnInFederal)
exports("SetFederal", SetFederal)

RegisterNetEvent("SpawnInFederal", SpawnInFederal)
RegisterNetEvent("SetFederal", SetFederal)

-- ─── Evento para transportar al preso a prisión ──────────────────
RegisterNetEvent("origen_police:client:sendToFederalPrison", function(minutes, danger)
    local spawnCoords = Config.Federal.Spawn
    DoScreenFadeOut(500)
    Wait(600)
    SetEntityCoords(PlayerPedId(), spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), spawnCoords.w or 0.0)
    Wait(500)
    DoScreenFadeIn(500)
    SetFederal(minutes, danger)
end)

-- ─── Evento para liberar al preso de prisión ─────────────────────
RegisterNetEvent("origen_police:client:releaseFromFederalPrison", function()
    inside = false
    prisonMinutes = 0
    TriggerServerEvent("origen_police:server:prisonEscapeEnd")
    SetFederal(false)
    DoScreenFadeOut(500)
    Wait(600)
    local exit = Config.Federal.Exits[Config.DefaultExit] or Config.Federal.Exits["Mission Row"]
    if Config.ForcedExit and Config.ForcedExit.enabled then
        exit = Config.ForcedExit.coords
    end
    if exit then
        SetEntityCoords(PlayerPedId(), exit.x, exit.y, exit.z, false, false, false, false)
        SetEntityHeading(PlayerPedId(), exit.w or 0.0)
    end
    Wait(500)
    DoScreenFadeIn(500)
    ShowNotification("Has sido puesto en libertad de la Prisión Federal")
end)

-- ─── Actualización en tiempo real del contador del preso ──────────
RegisterNetEvent("origen_police:client:updatePrisonTimer", function(newMins)
    prisonMinutes = tonumber(newMins) or 0
    SendNUIMessage({
        action = "Federal",
        mins = prisonMinutes
    })
end)

-- ─── Teletransporte del Agente a Federal ──────────────────────────
RegisterNetEvent("origen_police:client:teleportOfficer", function(x, y, z, h)
    DoScreenFadeOut(400)
    Wait(500)
    SetEntityCoords(PlayerPedId(), x, y, z, false, false, false, false)
    if h then SetEntityHeading(PlayerPedId(), h) end
    Wait(400)
    DoScreenFadeIn(400)
    ShowNotification("Has sido transportado a las instalaciones de Prisión Federal")
end)

-- ─── Blips de seguimiento de fugitivos en tiempo real para Policías ──
local FugitiveBlips = {}

--- Como se llama cada fugado. Se guarda aparte porque el evento que refresca
--- su posicion solo manda coordenadas, y volver a poner el punto sin el nombre
--- lo dejaria llamandose «Fugitivo» a secas a partir del primer movimiento.
local FugitiveNames = {}

RegisterNetEvent("origen_police:client:createFugitiveBlip", function(fugitiveSrc, coords, fugitiveName)
    local PlayerData = FW_GetPlayerData(false)
    if not PlayerData or not PlayerData.job or not CanOpenTablet(PlayerData.job.name)[1] then return end

    --[[ El fugitivo, en el mapa.

         Ya no es un blip del juego: es un punto de origen_map. Prioridad alta
         —lo que antes decia SetBlipAsShortRange(false)— porque un fugado
         importa este donde este, y el corte por distancia del minimapa se lo
         comeria.

         El parpadeo se queda por el camino: en un mapa de Leaflet un punto que
         parpadea es ruido, y el rojo ya dice lo mismo sin moverse. ]]
    local blip = 'fugitivo_' .. tostring(fugitiveSrc)

    OrigenMapa.Poner(blip, {
        x = coords.x, y = coords.y, z = coords.z,
        cat = 'emergencias',
        icono = 'persona',
        nombre = "Fugitivo: " .. (fugitiveName or "Recluso"),
        color = '#ff3355',
        prioridad = 10,
    })

    FugitiveBlips[fugitiveSrc] = blip
    FugitiveNames[fugitiveSrc] = "Fugitivo: " .. (fugitiveName or "Recluso")
    PlaySoundFrontend(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", false)
end)

RegisterNetEvent("origen_police:client:updateFugitiveBlip", function(fugitiveSrc, coords)
    --- Volver a ponerlo con la misma clave lo MUEVE: el registro actualiza el
    --- punto que ya hubiera en vez de crear otro.
    if FugitiveBlips[fugitiveSrc] then
        OrigenMapa.Poner(FugitiveBlips[fugitiveSrc], {
            x = coords.x, y = coords.y, z = coords.z,
            cat = 'emergencias',
            icono = 'persona',
            nombre = FugitiveNames[fugitiveSrc] or 'Fugitivo',
            color = '#ff3355',
            prioridad = 10,
        })
    end
end)

RegisterNetEvent("origen_police:client:removeFugitiveBlip", function(fugitiveSrc)
    if FugitiveBlips[fugitiveSrc] then
        OrigenMapa.Quitar(FugitiveBlips[fugitiveSrc])
    end
    FugitiveBlips[fugitiveSrc] = nil
    FugitiveNames[fugitiveSrc] = nil
end)

RegisterNUICallback("SpawnInFederal", function(data, cb)
    TriggerServerEvent("origen_police:server:tpToFederal")
    cb(true)
end)
RegisterNUICallback("SetFederal", function(data, cb)
    SetFederal(table.unpack(data))
    cb(true)
end)

-- ─── Creador Visual de Perímetro PolyZone de Prisión Federal ──
local creatingPerimeter = false
local perimeterPoints = {}

RegisterCommand("perimetrofederal", function()
    local PlayerData = FW_GetPlayerData(false)
    if not PlayerData or not PlayerData.job or not CanOpenTablet(PlayerData.job.name)[1] then
        return ShowNotification("No tienes permisos para definir el perímetro.", "error")
    end

    if creatingPerimeter then
        creatingPerimeter = false
        ShowNotification("Creación de perímetro cancelada.", "error")
        return
    end

    creatingPerimeter = true
    perimeterPoints = {}
    ShowNotification("Modo creador de perímetro de Prisión Federal activado.", "primary")

    CreateThread(function()
        while creatingPerimeter do
            Wait(0)
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)

            -- Mostrar ayuda en pantalla
            ShowHelpNotification("Puntos añadidos: ~g~" .. #perimeterPoints .. "~s~\n~INPUT_PICKUP~ Añadir punto en tu posición\n~INPUT_CELLPHONE_EXTRA_OPTION~ Deshacer último punto\n~INPUT_FRONTEND_ACCEPT~ Guardar perímetro\n~INPUT_CELLPHONE_CANCEL~ Cancelar")

            -- Dibujar marcador en los pies del jugador
            DrawMarker(28, pcoords.x, pcoords.y, pcoords.z - 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.8, 0, 255, 120, 180, false, false, 2, nil, nil, false)

            -- Dibujar líneas y marcas de los puntos ya colocados
            local t_half = 6.0
            for i = 1, #perimeterPoints do
                local pt = perimeterPoints[i]
                DrawMarker(28, pt.x, pt.y, pt.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 200, 0, 200, false, false, 2, nil, nil, false)
                DrawLine(pt.x, pt.y, pt.z - t_half, pt.x, pt.y, pt.z + t_half, 0, 255, 0, 255)

                if i > 1 then
                    local prevPt = perimeterPoints[i-1]
                    DrawLine(prevPt.x, prevPt.y, prevPt.z, pt.x, pt.y, pt.z, 0, 255, 0, 255)
                    DrawLine(prevPt.x, prevPt.y, prevPt.z + t_half, pt.x, pt.y, pt.z + t_half, 0, 255, 255, 255)
                    DrawLine(prevPt.x, prevPt.y, prevPt.z - t_half, pt.x, pt.y, pt.z - t_half, 0, 255, 255, 255)
                end
            end

            -- Si hay 3 o más puntos, cerrar el polígono visualmente
            if #perimeterPoints >= 3 then
                local firstPt = perimeterPoints[1]
                local lastPt = perimeterPoints[#perimeterPoints]
                DrawLine(lastPt.x, lastPt.y, lastPt.z, firstPt.x, firstPt.y, firstPt.z, 255, 100, 0, 255)
                DrawLine(lastPt.x, lastPt.y, lastPt.z + t_half, firstPt.x, firstPt.y, firstPt.z + t_half, 255, 100, 0, 255)
                DrawLine(lastPt.x, lastPt.y, lastPt.z - t_half, firstPt.x, firstPt.y, firstPt.z - t_half, 255, 100, 0, 255)
            end

            -- Tecla E (INPUT_PICKUP) para añadir punto
            if IsControlJustPressed(0, 38) then
                table.insert(perimeterPoints, { x = pcoords.x, y = pcoords.y, z = pcoords.z })
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDS", true)
                ShowNotification("Punto #" .. #perimeterPoints .. " añadido", "primary")
                Wait(300)
            end

            -- Tecla Backspace / Deshacer (INPUT_CELLPHONE_EXTRA_OPTION - 179 o 194)
            if IsControlJustPressed(0, 179) or IsControlJustPressed(0, 194) then
                if #perimeterPoints > 0 then
                    table.remove(perimeterPoints, #perimeterPoints)
                    ShowNotification("Último punto eliminado. Restantes: " .. #perimeterPoints, "primary")
                    Wait(300)
                end
            end

            -- Tecla Enter (INPUT_FRONTEND_ACCEPT - 18 / 201) para guardar
            if IsControlJustPressed(0, 18) or IsControlJustPressed(0, 201) then
                if #perimeterPoints < 3 then
                    ShowNotification("Debes colocar al menos 3 puntos para cerrar el perímetro.", "error")
                else
                    creatingPerimeter = false
                    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDS", true)
                    TriggerServerEvent("origen_police:server:saveFederalPerimeter", perimeterPoints)
                    ShowNotification("Perímetro enviado al servidor para guardarse.", "success")
                end
                Wait(300)
            end

            -- Tecla Cancelar (INPUT_CELLPHONE_CANCEL - 177 / ESC)
            if IsControlJustPressed(0, 177) then
                creatingPerimeter = false
                perimeterPoints = {}
                ShowNotification("Creación de perímetro cancelada.", "error")
                Wait(300)
            end
        end
    end)
end, false)

RegisterCommand("federalzone", function()
    ExecuteCommand("perimetrofederal")
end, false)


