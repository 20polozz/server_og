if not Config.SirensSystem then return end

local sirenstable = {}
-- Hay alguna entrada con sync = true por procesar (la ponen los eventos de abajo)
local pendiente = false

RegisterCommand(Config.Commands.LightsSirens.cmd, function()
    if IsNuiFocused() then return end
    if IsDisabledControlPressed(0, 86) then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        if (ValidVehicles[veh] == true) then
            SetVehicleSiren(veh, not IsVehicleSirenOn(veh))
            SetVehicleHasMutedSirens(veh, true)
            TriggerServerEvent("origen_police:server:PoliceSirenState", NetworkGetNetworkIdFromEntity(veh), 0)
        end
    end
end)

RegisterKeyMapping(Config.Commands.LightsSirens.cmd, Config.Commands.LightsSirens.description, 'keyboard', Config.Commands.LightsSirens.key)

RegisterCommand(Config.Commands.SirensKey.cmd, function()
    if IsNuiFocused() then return end
    if IsDisabledControlPressed(0, 86) then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if veh ~= 0 and IsVehicleSirenOn(veh) then
        if (ValidVehicles[veh] == true) then
            local netid = NetworkGetNetworkIdFromEntity(veh)
            TriggerServerEvent("origen_police:server:PoliceSirenState", netid, not sirenstable[netid] and 1 or sirenstable[netid].siren == 0 and 1 or 0)
        end
    end
end)

RegisterKeyMapping(Config.Commands.SirensKey.cmd, Config.Commands.SirensKey.description, 'keyboard', Config.Commands.SirensKey.key)

-- EVENTOS & BULCES
RegisterNetEvent("origen_police:client:PoliceHornState", function(netid, state)
    if not sirenstable[netid] then
        sirenstable[netid] = {
            horn = state
        }
    else
        sirenstable[netid].horn = state
    end
    sirenstable[netid].sync = true
    pendiente = true
end)

RegisterNetEvent("origen_police:client:PoliceSirenState", function(netid, state)
    if not NetworkDoesNetworkIdExist(netid) then
        return
    end
    local veh = NetworkGetEntityFromNetworkId(netid)
    SetVehicleHasMutedSirens(veh, true)
    if not sirenstable[netid] then
        sirenstable[netid] = {
            siren = state or 1
        }
    else
        sirenstable[netid].siren = state or (sirenstable[netid].siren or 0) + 1
        if sirenstable[netid].siren > #Config.Sirens then
            sirenstable[netid].siren = 1
        end
    end
    sirenstable[netid].sync = true
    pendiente = true
end)

RegisterNetEvent("origen_police:client:clearcache", function(netid)
    if sirenstable[netid] then
        if sirenstable[netid].hornid then
            StopSound(sirenstable[netid].hornid)
            ReleaseSoundId(sirenstable[netid].hornid)
        end
        if sirenstable[netid].sirenid then
            StopSound(sirenstable[netid].sirenid)
            ReleaseSoundId(sirenstable[netid].sirenid)
        end
        sirenstable[netid] = nil
    end
end)

CreateThread(function()
    while true do
        -- Solo hay trabajo cuando un evento marca sync; el sonido lo mantiene el
        -- juego solo, asi que sin nada pendiente basta mirar cada 100 ms
        Wait(pendiente and 0 or 100)
        -- Se baja antes de recorrer: el bucle no cede, asi que ningun evento
        -- puede colarse entre medias y perderse
        pendiente = false
        for k, v in pairs(sirenstable) do
            if v.sync then
                if NetworkDoesNetworkIdExist(k) then
                    local clid = NetworkGetEntityFromNetworkId(k)
                    if DoesEntityExist(clid) then
                        if v.hornid then
                            StopSound(v.hornid)
                            ReleaseSoundId(v.hornid)
                            v.hornid = nil
                        end
                        if v.horn then
                            v.hornid = GetSoundId()
                            PlaySoundFromEntity(v.hornid, "SIRENS_AIRHORN", clid, 0, 0, 0)
                        end

                        if v.sirenid then
                            StopSound(v.sirenid)
                            ReleaseSoundId(v.sirenid)
                            v.sirenid = nil
                        end
                        
                        if v.siren and Config.Sirens[v.siren] then
                            v.sirenid = GetSoundId()
                            PlaySoundFromEntity(v.sirenid, Config.Sirens[v.siren], clid, 0, 0, 0)
                        end
                    else
                        if v.sirenid then
                            StopSound(v.sirenid)
                            ReleaseSoundId(v.sirenid)
                            v.sirenid = false
                        end
                        if v.hornid then
                            StopSound(v.hornid)
                            ReleaseSoundId(v.hornid)
                            v.hornid = false
                        end
                    end
                end
                v.sync = false
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh > 0 and ValidVehicles[veh] == true then
            if IsControlJustPressed(0, 80) then
                DisableControlAction(0, 80, true)
                local netid = NetworkGetNetworkIdFromEntity(veh)
                if IsVehicleSirenOn(veh) and sirenstable[netid] and sirenstable[netid].siren ~= 0 and not IsDisabledControlPressed(0, 86) then
                    TriggerServerEvent("origen_police:server:PoliceSirenState", netid)
                    while IsDisabledControlPressed(0, 80) do
                        DisableControlAction(0, 80, true)
                        Wait(0)
                    end
                elseif not IsDisabledControlPressed(0, 86) then
                    TriggerServerEvent("origen_police:server:PoliceSirenState", netid, 1)
                    while IsDisabledControlPressed(0, 80) do
                        DisableControlAction(0, 80, true)
                        Wait(0)
                    end
                    TriggerServerEvent("origen_police:server:PoliceSirenState", netid, 0)
                end
            end
        else
            Wait(1000)
        end
    end
end)