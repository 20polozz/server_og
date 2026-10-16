local HasEntityClearLosToEntity = HasEntityClearLosToEntity
local GetEntityCoords = GetEntityCoords

RegisterNetEvent('origen_chat:client:proximityChat', function(chatData, coords, range, id)
    local command = Config.Commands[id]


    local distance = #(coords - GetEntityCoords(cache.ped))
    if distance <= range then
        if chatData.src and command.preventCollisions then
            local sourcePed = GetPlayerPed(GetPlayerFromServerId(chatData.src))
            if sourcePed ~= PlayerPedId() and (not HasEntityClearLosToEntity(PlayerPedId(), sourcePed, 17) or not HasEntityClearLosToEntity(sourcePed, PlayerPedId(), 2)) then
                return
            end
        end
        
        exports.origen_chat:addMessage(chatData)
    end
end)

RegisterNetEvent('origen_chat:client:jobToJobChat', function(chatData, id)
    local command = Config.Commands[id]
    if not command then return end

    local job = Custom.GetPlayerJob()

    if job and command.groups[job.name] and job.grade.level >= command.groups[job.name] then 
        exports.origen_chat:addMessage(chatData)
    end
end)

local showIDs = false

local function DrawText3D(x, y, z, text, r, g, b)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.40, 0.40)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(r or 255, g or 255, b or 255, 255)
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

RegisterCommand('verids', function()
    showIDs = not showIDs
    if showIDs then
        Custom.Notify("Ver IDs activado", "success")
        CreateThread(function()
            while showIDs do
                local sleep = 500
                local myCoords = GetEntityCoords(cache.ped)
                for _, player in ipairs(GetActivePlayers()) do
                    local ped = GetPlayerPed(player)
                    -- 08/10: también la tuya, con el aspecto de siempre
                    do
                        local pedCoords = GetEntityCoords(ped)
                        local dist = #(myCoords - pedCoords)
                        if ped == cache.ped or (dist < 5.0 and HasEntityClearLosToEntity(cache.ped, ped, 17) and IsEntityVisible(ped) and GetEntityAlpha(ped) > 50) then
                            sleep = 0
                            local id = GetPlayerServerId(player)
                            
                            local r, g, b = 255, 255, 255
                            if NetworkIsPlayerTalking(player) then
                                r, g, b = 50, 255, 50
                            end
                            
                            DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z + 1.0, tostring(id), r, g, b)
                        end
                    end
                end
                Wait(sleep)
            end
        end)
    else
        Custom.Notify("Ver IDs desactivado", "success")
    end
end, false)

RegisterKeyMapping('verids', 'Ver IDs de jugadores cercanos', 'keyboard', 'F11')
