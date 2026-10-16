
local interiorCoords = vector3(-316.6848, 219.4704, 68.7469)
local isPartyActive = false

RegisterNetEvent('origen_club:updateParty')
AddEventHandler('origen_club:updateParty', function(state)
    isPartyActive = state
    local interiorID = GetInteriorAtCoords(interiorCoords.x, interiorCoords.y, interiorCoords.z)
    
    if IsValidInterior(interiorID) then
        if isPartyActive then
            EnableInteriorProp(interiorID, "party")
        else
            DisableInteriorProp(interiorID, "party")
        end
        RefreshInterior(interiorID)
    end
end)


Citizen.CreateThread(function()
    TriggerServerEvent('origen_club:requestStatus')
    
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local dist = #(playerCoords - interiorCoords)

        if dist < 5.0 then
            sleep = 0
            DrawMarker(2, interiorCoords.x, interiorCoords.y, interiorCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 100, false, true, 2, true, nil, nil, false)
            
            if dist < 1.5 then

                if IsControlJustReleased(0, 38) then -- E key
                    TriggerServerEvent('origen_club:toggleParty')
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

