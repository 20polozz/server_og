--@param houseID House ID
Custom.Dispatch = function(coords)
    if Config.Dispatch == 'origen_police' then 
        TriggerServerEvent("SendAlert:police", {
            coords = coords,
            type = 'GENERAL',
            title = 'House robbery',
            job = Config.PoliceJob,
        })
    else
        -- Add your custom dispatch alert
    end
end

--? Custom lockpick minigame, you can add your own logic here
Custom.LockpickMinigame = function(advanced)
    local result = true
    LockpickResult(result)
end