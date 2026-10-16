playerIdentifier = nil

local function loadHouses()
    if playerIdentifier then return end
    
    playerIdentifier = Framework.GetPlayerIdentifier()

    while not playerIdentifier do
        playerIdentifier = Framework.GetPlayerIdentifier()
        Wait(500)
    end
    local housesCount = 0

    if Config.EnablePreloadMethod then
        lib.callback('origen_housing:server:getPreload', false, function(preload)
            if not preload or not next(preload) then return end

            for _, v in pairs(preload) do
                if not Preload.table[v.id] then
                    Preload.new(v)
                    housesCount = housesCount + 1
                end
            end
        end)
    else
        lib.callback('origen_housing:server:getAllHouses', false, function(houses)
            if not houses or not next(houses) then return end
            for _, v in pairs(houses) do
                if not House.table[v.id] then
                    local house = House.new(v)
                    house:CreateHouse()
                    housesCount = housesCount + 1
                end
            end
        end)
    end


    if housesCount > 0 then
        debugger('Player loaded with identifier', playerIdentifier)
        debugger('Houses loaded', housesCount)
    end

    LocalPlayer.state:set('IsBusy', false, true)
end

RegisterNetEvent('origen_housing:client:onPLayerLoad', function()
    loadHouses()
    
    if Config.EnterHouseOnSpawn then
        local inside = lib.callback.await('origen_housing:server:isInsideHousing', false)
        if inside then
            local house = House.get(tonumber(inside))
            if house then
                house:EnterHouse()
            end
        end
        
        local insideHotel = lib.callback.await('origen_housing:server:isInsideHotel', false)
        if insideHotel then
            local room = HotelRoom.get(tonumber(insideHotel))
            if room then
                room:EnterRoom()
            end
        end
    end
end)

RegisterNetEvent('origen_housing:client:onPLayerUnload', function()
    playerIdentifier = nil

    debugger('Player unloaded')

    if next(House.table) then
        debugger('Deleting houses', #House.table)

        for _, house in pairs(House.table) do
            house:DeleteHouse()
        end

        debugger('Houses deleted', #House.table)
    end

    LocalPlayer.state:set('IsBusy', false, true)
end)

CreateThread(function()
    loadHouses()
end)

RegisterNetEvent('origen_housing:client:CreateHouse', function(house)
    local house = House.new(house)
    house:CreateHouse()
end)

RegisterNetEvent('origen_housing:client:notify', function(text, type, length)
    Internal.Notify(text, type, length)
end)

exports('loadHouse', function(houseID, cb, options)
    if not houseID then return end
    local house = lib.callback.await('origen_housing:server:getHouse', false, houseID)
    if not house then return end

    local created_house = House.new(house)

    if created_house then 
        created_house:CreateHouse()

        if options.enter then 
            created_house:EnterHouse()
        end

        if cb then cb(created_house.houseData) end
    end
end)

-- AddEventHandler('onResourceStart', function(resource)
--    if resource == GetCurrentResourceName() then
--       playerIdentifier = Framework.GetPlayerIdentifier()
--    end
-- end)