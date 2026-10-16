local cooldown = 0
local applyCooldown = function(ms)
    cooldown = GetGameTimer() + ms
end

local isCooldown = function()
    return GetGameTimer() < cooldown
end

--- Sin personaje (menu de inicio, seleccion de personaje) no hay inventario
--- que abrir: el servidor lo niega igual, pero la NUI se abria vacia encima
--- del menu. qbx_core pone isLoggedIn al cargar el personaje; en ESX no existe.
local function SinPersonaje()
    return Config.Framework == 'qbcore' and not LocalPlayer.state.isLoggedIn
end

RegisterCommand('origen_inventory', function()
    if SinPersonaje() then return end
    if Inventory.locked then return end
    if IsPauseMenuActive() then return end
    if not Player and not CharacterUnloaded then Player = Player_Class:new() end
    if not Player or (Player and Player.isOpen) then return CloseInventory() end
    if IsNuiFocused() then return end
    local hasVehicle, veh, model, plate, nearGlovebox = Bridge.CanOpenTrunk()
    local isVehicleLocked = false

    if hasVehicle then
        if isCooldown() then return end
        applyCooldown(800)
        isVehicleLocked = GetVehicleDoorLockStatus(veh) == 2
        if nearGlovebox and not isVehicleLocked then
            Inventory.open('glovebox', plate, { model = model })
            -- Se vigila el coche con el que se abrio: sin esto podias bajarte
            -- e irte andando con la guantera abierta.
            VigilarVehiculo(veh)
            return
        end

        if not isVehicleLocked then
            local ped = PlayerPedId()
            for i = -1, 6 do
                if GetPedInVehicleSeat(veh, i) == ped then
                    goto continue
                end
            end

            local modelHash = GetEntityModel(veh)
            local min, max = GetModelDimensions(modelHash)
            local playerpos = GetEntityCoords(PlayerPedId())
            
            -- Calculamos la posición relativa del jugador respecto al coche
            local relPos = GetOffsetFromEntityGivenWorldCoords(veh, playerpos.x, playerpos.y, playerpos.z)
            
            -- Determinamos si el maletero es delantero o trasero
            local isBackEngine = false
            for _, v in ipairs(Config.BackEngineVehicles) do
                if GetHashKey(v) == modelHash then isBackEngine = true break end
            end

            local isNearTrunk = false
            local distanceToPoint = 0.0

            if isBackEngine then
                -- Maletero ADELANTE: Comprobar si el jugador está en la parte frontal (Y > 0)
                -- y dentro de la anchura del coche (X entre min.x y max.x)
                local frontPoint = GetOffsetFromEntityInWorldCoords(veh, 0.0, max.y, 0.5)
                distanceToPoint = #(playerpos - frontPoint)
                if relPos.y > 0 and math.abs(relPos.x) < (max.x + 0.5) then
                    isNearTrunk = true
                end
            else
                -- Maletero ATRÁS: Comprobar si el jugador está en la parte trasera (Y < 0)
                -- y dentro de la anchura del coche (X entre min.x y max.x)
                local backPoint = GetOffsetFromEntityInWorldCoords(veh, 0.0, min.y, 0.5)
                distanceToPoint = #(playerpos - backPoint)
                if relPos.y < 0 and math.abs(relPos.x) < (max.x + 0.5) then
                    isNearTrunk = true
                end
            end

            -- Si estamos en la zona del maletero, permitimos un radio más amplio (1.8m)
            -- para que el alerón no sea un obstáculo
            if Config.OpenTrunkAnywhere or (isNearTrunk and distanceToPoint < 1.8) then 
                Inventory.open('trunk', plate, { model = modelHash })
                VigilarVehiculo(veh)
                OpenTrunkAnim()
                CreateThread(CheckVehicleDistance)
                CurrentVehicle = veh
                return
            end
        end
    end

    if Player and Player.activeDrop then
        if isCooldown() then return end
        applyCooldown(800)
        --- IsPlayerInFront? ---
        local distance = #(GetEntityCoords(PlayerPedId()) - Player.activeDrop.location)
        if distance < 3 then
            Inventory.open('drop', Player.activeDrop.id)
            return
        else
            Player:setActiveDrop(nil)
            Player:CloseSecondInventory()
        end
    end
    ::continue::
    Player:OpenInventory()
end, false)

RegisterKeyMapping('origen_inventory', 'Abrir el inventario', 'keyboard', Config.DefaultOpenKey)

for i = 1, 6 do
    RegisterCommand('slot' .. i, function()
        if SinPersonaje() then return end
        if Inventory.locked then return end
        if IsNuiFocused() then return end
        if not Player and not CharacterUnloaded then Player = Player_Class:new() end
        if not Player or (Player and Player.isOpen) then return CloseInventory() end
        if Bridge.CanOpen() and not IsPauseMenuActive() and not Player.inUse then
            if i == 7 then
                i = Config.Player.MaxInventorySlots --Config.MaxInventorySlots
            end
            Player:setInUse(true)
            Inventory.useSlot(i)

            Citizen.Wait(500)
            Player:setInUse(false)
        end
    end, false)
    RegisterKeyMapping('slot' .. i, 'Inventario: usar el hueco ' .. i, 'keyboard', tostring(i))
end
