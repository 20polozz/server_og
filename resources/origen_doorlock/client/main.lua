local function loadDoors()
    local count = 0
    local doors = lib.callback.await('origen_doorlock:server:GetAllDoors', false)
    LocalPlayer.state.orgPlayerIdentifier = Framework.GetPlayerIdentifier()

    if not doors or not next(doors) then
        return debugger('No doors found')
    end

    --[[ Se carga dos veces (al arrancar y al entrar el personaje). Los puntos
         de la primera se quedaban vivos y con los datos de antes de tener
         personaje (sin acceso por lista de jugadores): se quitan. ]]
    for _, viejo in pairs(Doors) do
        if viejo.point then viejo.point:remove() end
    end
    if currentDoorID then
        Custom.HideText()
        currentDoorID = false
    end
    Doors = {}

    for k,v in pairs(doors) do
        local success, err = pcall(function()
            local door = Door:new(v)
            door:RegisterDoor()
            count = count + 1
        end)
        if not success then
            debugger('^1Failed to register door ID ' .. tostring(v.id) .. ': ' .. tostring(err) .. '^0')
        end
    end

    if count > 0 then
        debugger('Player loaded with identifier', LocalPlayer.state.orgPlayerIdentifier)
        debugger('Doors loaded', count)
    end
end

RegisterNetEvent('origen_doorlock:client:onPLayerLoad', function()
    loadDoors()
end)

RegisterNetEvent('origen_doorlock:client:onPlayerUnload', function()
    Doors = {}
    LocalPlayer.state.orgPlayerIdentifier = nil
end)

RegisterNetEvent('origen_doorlock:client:CreateDoor', function(data)
    local door = Door:new(data)
    door:RegisterDoor()
    debugger('Created door with id', door.id)
end)

CreateThread(function()
    Wait(1000)
    loadDoors()
end)   