local RegisterNuiCallback = RegisterNuiCallback
local SendNUIMessage = SendNUIMessage
local Thread = CreateThread
local UIOpen = false
local voiceModes = {
    ['Whisper'] = 33,
    ['Normal'] = 66,
    ['Shouting'] = 100,
}
local pState = LocalPlayer.state

InventoryUI = {}

InventoryUI.On = function(endpoint, fn)
    RegisterNuiCallback(endpoint, function(data, cb)
        local result = fn(data)
        return cb(result ~= nil and result or false)
    end)
end

InventoryUI.Emit = function(data, delay, cancelDebug)
    if not cancelDebug then debugger("Emitting Inventory UI event:", json.encode(data, { indent = true })) end
    if delay then Wait(delay) end
    SendNUIMessage(data)
end

InventoryUI.UpdateVehicleState = function(isInVehicle, isDriver)
    InventoryUI.Emit({
        action = 'updateVehicleState',
        isInVehicle = isInVehicle,
        isDriver = isDriver
    })
end

InventoryUI.Notify = function(action, name)
    InventoryUI.Emit({
        action = "notification",
        notification = {
            action = action,
            name = name,
        }
    })
end

InventoryUI.Close = function()
    --[[ Sin Player (despues de salir del personaje) esto reventaba y la
         pantalla que pedia cerrarse se quedaba con el raton. Se suelta a mano
         y se quita la pantalla. ]]
    if not Player then
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
        InventoryUI.Emit({ action = 'close' })
        return true
    end
    return Player:CloseInventory()
end

InventoryUI.Open = function(uiConfig)
    debugger("Opening Inventory UI with config:", json.encode(uiConfig, { indent = true }))
    local secondInventory = uiConfig.secondInventory or nil
    uiConfig.secondInventory = nil

    local playerData = {
        health = GetEntityHealth(cache.ped) - 100,
        armour = GetPedArmour(cache.ped),
        stamina = IsEntityInWater(cache.ped) and GetPlayerUnderwaterTimeRemaining(cache.playerId) * 10 or 100 - GetPlayerSprintStaminaRemaining(cache.playerId),
        talking = NetworkIsPlayerTalking(cache.playerId),
    }

    local stats = {
        health = playerData.health,
        armour = playerData.armour,
        stamina = playerData.stamina,
        hunger = pState.hunger or 100,
        thirst = pState.thirst or 100,
        voice = voiceModes[pState.proximity and pState.proximity.mode or 'Normal'] or 66,
    }
    
    InventoryUI.Emit({ 
        action = 'open', 
        inventory = uiConfig, 
        secondInventory = secondInventory,
        stats = stats,
        --[[ Que se llega desde otro panel del riel y su barra sigue en
             pantalla, asi que la de aqui tiene que aparecer YA PUESTA encima
             en vez de deslizarse. Lo enciende quien abre --AbrirEnPestana y
             AbrirAcceso-- y se apaga aqui mismo: vale para UNA apertura, que
             si se quedara puesto la siguiente entrada normal saldria sin
             animacion sin que nadie sepa por que. ]]
        relevo = InventoryUI.relevoEntrante == true,
        --[[ Y por que pestaña abrir. Viaja con la apertura para que lo primero
             que se pinte ya sea la buena; mandandola despues se veia entrar el
             inventario por Objetos y saltar. ]]
        pestana = InventoryUI.pestanaEntrante,
        -- Y, dentro de la pestaña, que pantalla. Ver AbrirEnPestana.
        vista = InventoryUI.vistaEntrante,
        --[[ Modo SOLO REPORTES: el panel se abre estando tirado en el suelo,
             y entonces no es el inventario, es la pantalla de reportes y nada
             mas. La interfaz deja solo la pestaña Ciudad, sin accesos y sin
             volver al indice, asi que no hay rejilla de objetos que tocar.
             Ver AbrirReportes en f_origen_accesos.lua. ]]
        soloReportes = InventoryUI.soloReportesEntrante == true,
    }, false, true)

    InventoryUI.relevoEntrante = false
    InventoryUI.pestanaEntrante = nil
    InventoryUI.vistaEntrante = nil
    InventoryUI.soloReportesEntrante = false
end

InventoryUI.UpdateInventory = function(inventory)
    InventoryUI.Emit({ action = 'update', inventory = inventory, secondInventory = inventory.secondInventory }, false, true)
end

InventoryUI.SetupTranslations = function()
    InventoryUI.Emit({
        action = 'setupTranslations',
        translations = Lang[Config.Language].ui
    }, false, true)
end

Thread(function()
    Wait(1000)
    InventoryUI.SetupTranslations()
end)

-----------
-- Callbacks from NUI
-----------
---

--[[ `fetchNui` (source-ui/src/utils/fetchNui.ts) dispara `inventory:keepFocus`
     detras de CADA llamada que no pase clearFocus. Eso esta bien mientras el
     panel esta abierto, pero cualquier peticion que se resuelva DESPUES de
     cerrarlo -un sondeo de pestaña que ya estaba en vuelo, una validacion de
     movimiento que tarda- volvia a poner el raton en pantalla, y el jugador se
     lo encontraba encima sin haber abierto nada.

     La interfaz no tiene por que saber si llega tarde. Aqui se decide: si no hay
     nada NUESTRO abierto, no se recupera el foco. Ni se recupera ni se suelta:
     puede que lo tenga otro panel al que acabamos de dar el relevo desde el
     riel, y quitarselo lo dejaria visible pero sin raton. ]]
local function HayInterfazAbierta()
    return (Player and Player.isOpen) or InventoryUI.managementOpen or false
end

InventoryUI.On('inventory:focusIn', function()
    if not HayInterfazAbierta() then return end
    SetNuiFocusKeepInput(false)
end)

InventoryUI.On('inventory:focusOut', function()
    if not HayInterfazAbierta() then return end
    SetNuiFocusKeepInput(true)
end)

InventoryUI.On('inventory:keepFocus', function()
    --[[ Si no hay nada nuestro abierto, no se toca NADA.

         Antes aqui se soltaba el foco —SetNuiFocus(false, false)— para dejar
         limpia la pantalla si la peticion llegaba tarde. El problema es que el
         foco de la NUI es del cliente entero, no de este recurso: desde el
         riel se salta a otros paneles —admin, banda, negocio, policia— y
         cualquiera de las 70 y pico llamadas de la interfaz que siguiera en
         vuelo aterrizaba con el inventario ya cerrado y le quitaba el foco al
         panel recien abierto.

         Se quedaba visible pero muerto: el raton volvia a mover la camara y al
         pulsar un boton el personaje daba un puñetazo, porque el clic lo
         recibia el juego y no la pantalla.

         Soltarlo aqui tampoco hacia falta: el cierre de verdad ya pasa por
         CloseInventory, que llama a NUIFocus(false, false). Lo unico que hacia
         falta para el caso tardio es NO recuperarlo, y de eso ya se encarga
         este mismo `if`. ]]
    if not HayInterfazAbierta() then return end
    SetNuiFocus(true, true)
end)

InventoryUI.On('saveSettings', function(settings)
    local forcedColor = Config.UI.Color or 'default'
    SetResourceKvp('origen_inventory:color', forcedColor)
    Sprite.emitEvent('onSettingsUpdate', { defaultColor = forcedColor })
    
    return true
end)

InventoryUI.On('getSettings', function()
    local isRadarEnabled = not IsRadarHidden()
    updateRadarState(isRadarEnabled)
    local forcedColor = Config.UI.Color or 'default'
    return {
        defaultColor = forcedColor,
        useClothingAsItem = ClothingController.isCAIEnabled(),
        enableTabs = Config.UI.EnableTabs,
    }
end)

InventoryUI.On('getUIColor', function()
    return Config.UI.Color or 'default'
end)

InventoryUI.On('getVehicleStats', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or vehicle == 0 then return false end

    local model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    if model == 'NULL' or model == 'CARNOTFOUND' then
        model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    end

    local classNames = {
        [0] = 'Compacts',
        [1] = 'Sedans',
        [2] = 'SUVs',
        [3] = 'Coupes',
        [4] = 'Muscle',
        [5] = 'Sports Classics',
        [6] = 'Sports',
        [7] = 'Super',
        [8] = 'Motorcycles',
        [9] = 'Off-road',
        [10] = 'Industrial',
        [11] = 'Utility',
        [12] = 'Vans',
        [13] = 'Cycles',
        [14] = 'Boats',
        [15] = 'Helicopters',
        [16] = 'Planes',
        [17] = 'Service',
        [18] = 'Emergency',
        [19] = 'Military',
        [20] = 'Commercial',
        [21] = 'Trains',
        [22] = 'Open Wheel'
    }

    local maxSeats = math.max((GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) or 1) - 1, 1)
    local playerSeat = 1
    for i = -1, maxSeats - 2 do
        if GetPedInVehicleSeat(vehicle, i) == ped then
            playerSeat = i + 2
            break
        end
    end

    return {
        name = model,
        plate = GetVehicleNumberPlateText(vehicle),
        className = classNames[GetVehicleClass(vehicle)] or 'Vehicle',
        speedKmh = math.floor((GetEntitySpeed(vehicle) * 3.6) + 0.5),
        fuel = math.floor(GetVehicleFuelLevel(vehicle) + 0.5),
        engineHealth = math.floor(math.max(math.min(GetVehicleEngineHealth(vehicle) / 10.0, 100.0), 0.0) + 0.5),
        bodyHealth = math.floor(math.max(math.min(GetVehicleBodyHealth(vehicle) / 10.0, 100.0), 0.0) + 0.5),
        rpm = math.floor(math.max(math.min(GetVehicleCurrentRpm(vehicle), 1.0), 0.0) * 100.0 + 0.5),
        seat = playerSeat,
        maxSeats = maxSeats,
        engineOn = GetIsVehicleEngineRunning(vehicle)
    }
end)

InventoryUI.On('copyCoords', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local isInAnyInterior = GetInteriorFromEntity(playerPed) ~= 0

    if Config.WorldPoints.ForceGroundZ and not isInAnyInterior then
        local exist, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 500.0, false)
        if exist then coords = vector3(coords.x, coords.y, groundZ) end
    end

    return { x = coords.x, y = coords.y, z = coords.z, w = heading }
end)

InventoryUI.On('close', function()
    return InventoryUI.Close()
end)

InventoryUI.On('inventory_options', function(data)
    if not data or not data.event then return false end

    if data.event == 'search' then
        return Inventory.__Internal_SearchClosestPlayer()
    end

    if data.event == 'hostage' then
        ExecuteCommand('th')
        return
    end

    if data.event == 'photoMode' then
        Thread(function()
            PhotoMode.Start()
        end)
        return true
    end

    if data.type and data.event then
        eventPublisher:publish(('origen_inventory:%s:%s'):format(data.type, data.event))
        return true
    end

    eventPublisher:publish(('origen_inventory:makeAction:%s'):format(data.event), data.action)
    return true
end)

InventoryUI.On('customItemButtonInteract', function(interactData)
    if not interactData or not interactData.item or not interactData.button then return false end
    local item = interactData.item
    local button = interactData.button

    local itemAction = InventoryButtons[item.name] and InventoryButtons[item.name][button]

    if itemAction and type(itemAction) == 'function' then
        Thread(function() 
            itemAction(item.slot, item.metadata)
        end)
        return true
    end

    return false
end)

--- Los que tienes al lado, para que la ficha deje elegir a quien le das algo.
InventoryUI.On('getNearbyPlayers', function()
    return GetNearbyPlayers()
end)

InventoryUI.On('giveItemToNearPlayer', function(data)
    --[[ El destinatario lo elige la ficha. Sin nadie elegido se cae al de
         siempre --el mas cercano-- para no romper a quien llame a esto desde
         otro sitio.

         Que venga de la NUI no lo hace de fiar, y no hace falta que lo sea:
         quien comprueba que ese id existe y que esta al alcance es el servidor,
         en giveInventoryItemToPlayer. ]]
    local target = tonumber(data.target)

    if not target then
        local nearPlayer = GetClosestNearbyPlayer()
        if not nearPlayer then return false end
        target = nearPlayer.playerId
    end

    local amount = tonumber(data.amount)
    if not amount or amount < 1 then return false end

    local item = data.item

    TriggerServerEvent('inventory:server:giveInventoryItemToPlayer', {
        target = target,
        slot = item.slot,
        NumberOfItem = amount,
    })

    RequestAnimDict('mp_common')
    while not HasAnimDictLoaded('mp_common') do
        Citizen.Wait(0)
    end
    TaskPlayAnim(PlayerPedId(), 'mp_common', 'givetake1_b', 8.0, 1.0, -1, 16, 0, false, false, false)
    return true
end)

-- Sistema simplificado para movimientos optimistas
local lastMovementTime = 0
local function canProcessMovement()
    local currentTime = GetGameTimer()
    return (currentTime - lastMovementTime) >= 30 -- Muy reducido para movimientos múltiples
end

InventoryUI.On('swapItems', function(swapData)
    if swapData.fromInventory:match('shop_') or swapData.toInventory:match('shop_') then return false end
    if not swapData.count or not tonumber(swapData.count) or tonumber(swapData.count) < 0 then swapData.count = 0 end

    -- Verificación básica anti-spam
    if not canProcessMovement() then
        -- Log comentado para movimientos múltiples menos intrusivos
        -- debugger("^3[ORG_INV]:^1 Movimiento demasiado rápido, ignorando...")
        return false
    end

    lastMovementTime = GetGameTimer()

    -- Usar callback para obtener resultado SINCRONIZADO del servidor
    local p = promise.new()

    Bridge.TriggerCallback('inventory:server:ValidateItemMove', function(success)
            p:resolve(success)
        end, swapData.fromInventory, swapData.toInventory, swapData.fromSlot, swapData.toSlot, swapData.count, swapData
        .count)

    local result = Citizen.Await(p)

    if result then
        debugger("^2[ORG_INV]:^0 Movimiento CONFIRMADO:", swapData.fromInventory, "->", swapData.toInventory)
    else
        debugger("^1[ORG_INV]:^0 Movimiento RECHAZADO:", swapData.fromInventory, "->", swapData.toInventory)
    end

    return result -- Retornar resultado real del servidor
end)

local ultimoAvisoTirarEnCoche = 0
InventoryUI.On('dropItem', function(dropData)
    --[[ Dentro de un vehiculo no se tira nada: la bolsa caeria bajo el coche y
         «Vaciar» soltaba la mochila entera en marcha. Esto es solo el aviso
         rapido; quien lo prohibe de verdad es el servidor (ValidateItemMove,
         TirarDesdeVehiculo en server/functions/f_player.lua). ]]
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        if GetGameTimer() - ultimoAvisoTirarEnCoche > 3000 then
            ultimoAvisoTirarEnCoche = GetGameTimer()
            Bridge.Notify(locale:t('notify.inventory_drop_in_vehicle'), 'error')
        end
        InventoryUI.UpdateVehicleState(true, GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId())
        return false
    end

    if not dropData.count or not tonumber(dropData.count) or tonumber(dropData.count) < 0 then dropData.count = 0 end

    -- Verificación básica anti-spam
    if not canProcessMovement() then
        -- Log comentado para movimientos múltiples menos intrusivos
        -- debugger("^3[ORG_INV]:^1 Drop demasiado rápido, ignorando...")
        return false
    end

    lastMovementTime = GetGameTimer()

    -- Usar callback para obtener resultado SINCRONIZADO del servidor
    local p = promise.new()
    local playerDrop = Player.activeDrop or 0
    dropData.toInventory = ((type(playerDrop) == 'table') and playerDrop.id or 0)

    Bridge.TriggerCallback('inventory:server:ValidateItemMove', function(success)
            p:resolve(success)
        end, dropData.fromInventory, dropData.toInventory, dropData.fromSlot, dropData.toSlot,
        dropData.fromCount or dropData.count, dropData.toCount or dropData.count)

    local result = Citizen.Await(p)

    if result then
        debugger("^2[ORG_INV]:^0 Drop CONFIRMADO:", dropData.fromInventory, "->", dropData.toInventory)
    else
        debugger("^1[ORG_INV]:^0 Drop RECHAZADO:", dropData.fromInventory, "->", dropData.toInventory)
    end

    return result -- Retornar resultado real del servidor
end)

-- Lo que recupera cada consumible, para el dato «Recupera» de la ficha.
-- Se manda la tabla del CLIENTE y no la del servidor a proposito: al comer,
-- f_consumeables.lua suma configTable[item] de este lado e ignora el numero
-- que llega del servidor. Como config/consumables.lua sortea las cifras con
-- math.random al cargar, cada lado tiene las suyas, y la que se aplica es esta.
InventoryUI.On('getRecuperaciones', function()
    return {
        comida = Config.ConsumablesEat or {},
        bebida = Config.ConsumablesDrink or {},
        alcohol = Config.ConsumablesAlcohol or {},
    }
end)

InventoryUI.On('getItemData', function(item)
    if not item then return false end
    local itemData = Items(item)
    if not itemData then return false end
    return itemData
end)

local lastEntity = nil
local function isCursorOverOwnPed(screenX, screenY, ped)
    local pedCoords = GetEntityCoords(ped)
    local success, pedScreenX, pedScreenY = GetScreenCoordFromWorldCoord(pedCoords.x, pedCoords.y, pedCoords.z + 0.6)
    if not success then return false end

    local dx = math.abs(screenX - pedScreenX)
    local dy = math.abs(screenY - pedScreenY)
    return dx <= 0.055 and dy <= 0.11
end

InventoryUI.On('onHover', function()
    local screenX = GetDisabledControlNormal(0, 239)
    local screenY = GetDisabledControlNormal(0, 240)
    local playerPed = PlayerPedId()

    local hit, entity = RaycastFromScreen(
        vec2(screenX, screenY),
        GetGameplayCamCoord(),
        GetGameplayCamRot(0)
    )

    local ownPedHovered = isCursorOverOwnPed(screenX, screenY, playerPed)

    if ownPedHovered and #(GetEntityCoords(playerPed) - GetEntityCoords(playerPed)) <= Config.Player.GiveDistance then
        if lastEntity and lastEntity ~= playerPed then
            ResetEntityAlpha(lastEntity)
            lastEntity = nil
        end

        SetMouseCursorSprite(3)
        SetEntityAlpha(playerPed, 175, false)
        lastEntity = playerPed
        return playerPed
    end

    if hit and GetEntityType(entity) == 1 and IsPedAPlayer(entity) then
        if lastEntity and lastEntity ~= entity then
            ResetEntityAlpha(lastEntity)
            lastEntity = nil
        end

        if #(GetEntityCoords(playerPed) - GetEntityCoords(entity)) > Config.Player.GiveDistance then
            return nil
        end

        SetMouseCursorSprite(3)
        SetEntityAlpha(entity, 175, false)

        lastEntity = entity

        return entity
    else
        if lastEntity then
            ResetEntityAlpha(lastEntity)
            lastEntity = nil
        end
    end

    return nil
end)

InventoryUI.On('onGiveItems', function(data)
    -- Make sure to reset lastEntity alpha
    if lastEntity then
        ResetEntityAlpha(lastEntity)
        lastEntity = nil
    end

    if not data or not data.target or not data.items then return end
    local target = data.target
    local items = data.items
    local playerPed = PlayerPedId()

    if lastEntity then
        ResetEntityAlpha(lastEntity)
        lastEntity = nil
    end

    for _, item in pairs(items) do
        if type(item) ~= 'table' or item.inventoryType ~= 'player' then
            return false
        end
    end

    if target == playerPed then
        local equipped = 0
        local equippedClothes = 0
        local returnedClothes = 0
        local equippedSets = 0
        local ignored = 0
        local failed = 0
        local ped = playerPed

        for _, item in pairs(items) do
            local isValidBase = type(item) == 'table' and item.name and item.slot and item.inventoryType == 'player'
            if not isValidBase then
                ignored = ignored + 1
                goto continue
            end

            if item.name == 'percha' then
                if GetResourceState('origen_clothing') ~= 'started' then
                    failed = failed + 1
                    Bridge.Notify('origen_clothing no esta iniciado.', 'error')
                    goto continue
                end

                local canEquipPromise = promise.new()
                Bridge.TriggerCallback('origen_inventory:hanger:canEquipSet', function(canEquip, reason)
                    canEquipPromise:resolve({ canEquip = canEquip, reason = reason })
                end, item.slot)
                local canEquipResult = Citizen.Await(canEquipPromise)

                if not canEquipResult or not canEquipResult.canEquip then
                    failed = failed + 1
                    goto continue
                end

                local equippedHashes = exports.origen_clothing:GetEquippedClothes(ped, true) or {}
                local equipSetPromise = promise.new()
                Bridge.TriggerCallback('origen_inventory:hanger:equipSet', function(success, payload)
                    equipSetPromise:resolve({ success = success, payload = payload })
                end, item.slot, equippedHashes)

                local equipSetResult = Citizen.Await(equipSetPromise)
                if not equipSetResult or not equipSetResult.success then
                    failed = failed + 1
                    goto continue
                end

                local applyItems = equipSetResult.payload and equipSetResult.payload.applyItems or {}
                if #applyItems == 0 then
                    failed = failed + 1
                    goto continue
                end

                for _, clothingData in ipairs(applyItems) do
                    local previousHash = equippedHashes[clothingData.name]
                    if previousHash and previousHash ~= clothingData.hash then
                        returnedClothes = returnedClothes + 1
                    end

                    if clothingData.type == 'props' then
                        exports.origen_clothing:SetPedPropByHash(ped, clothingData.hash, true)
                    else
                        exports.origen_clothing:SetPedDrawableByHash(ped, clothingData.hash, true)
                    end
                end

                equippedSets = equippedSets + 1
                equippedClothes = equippedClothes + #applyItems
                goto continue
            end

            local isValidItem = item.metadata and item.metadata.hash
            if not isValidItem then
                ignored = ignored + 1
                goto continue
            end

            local itemData = Items(item.name)
            if not itemData or itemData.type ~= 'clothing' then
                ignored = ignored + 1
                goto continue
            end

            local previousHash = exports.origen_clothing:GetEquippedClothes(cache.ped, true)[item.name]
            local p = promise.new()

            Bridge.TriggerCallback('origen_inventory:equipClothing', function(success, clothingType)
                if success then
                    if previousHash and previousHash ~= item.metadata.hash then
                        returnedClothes = returnedClothes + 1
                    end

                    if clothingType == 'props' then
                        exports.origen_clothing:SetPedPropByHash(ped, item.metadata.hash, true)
                    elseif clothingType == 'drawables' then
                        exports.origen_clothing:SetPedDrawableByHash(ped, item.metadata.hash, true)
                    end
                    equipped = equipped + 1
                    equippedClothes = equippedClothes + 1
                else
                    failed = failed + 1
                end
                p:resolve(success)
            end, item.slot, item.name, item.metadata.hash, previousHash)

            Citizen.Await(p)
            :: continue ::
        end

        if equipped > 0 or equippedSets > 0 then
            Player:LoadInventory()
        end

        if equipped > 0 or equippedSets > 0 then
            Bridge.Notify(('Prendas puestas: %s | Devueltas: %s'):format(equippedClothes, returnedClothes), 'success')
        elseif ignored > 0 and failed == 0 then
            Bridge.Notify('Solo se pueden equipar prendas de ropa o perchas de conjunto', 'error')
        end

        if failed > 0 then
            Bridge.Notify(('No se pudieron equipar %s elemento(s)'):format(failed), 'error')
        end

        return equipped > 0 or equippedSets > 0
    end

    local targetPed = NetworkGetPlayerIndexFromPed(target)
    if not targetPed then return false end

    local targetID = GetPlayerServerId(targetPed)
    if not targetID then return false end

    if #(GetEntityCoords(playerPed) - GetEntityCoords(target)) > Config.Player.GiveDistance then
        return false
    end

    RequestAnimDict('mp_common')
    while not HasAnimDictLoaded('mp_common') do
        Citizen.Wait(0)
    end

    local p = promise.new()

    Bridge.TriggerCallback('inventory:server:GiveItemsToPlayer', function(success)
        if success then
            TaskPlayAnim(PlayerPedId(), 'mp_common', 'givetake1_b', 8.0, 1.0, -1, 16, 0, false, false, false)
        end
        p:resolve(success)
    end, targetID, items)


    return Citizen.Await(p)
end)

InventoryUI.On('resetHover', function()
    if not lastEntity then return end
    ResetEntityAlpha(lastEntity)
    lastEntity = nil
end)

InventoryUI.On('useItem', function(slot)
    if not slot then return false end
    local slot = tonumber(slot)
    if not slot or slot < 0 then return false end
    TriggerServerEvent('inventory:server:UseItemSlot', slot)
    return true
end)

InventoryUI.On('requestInventoryUpdate', function()
    if Player and Player.UpdateClient then
        Player:UpdateClient()
        return true
    end
    return false
end)

------------------------------
-----------------
---
--          CRAFTING
---
-----------------
------------------------------

InventoryUI.On('crafting:addQueueItem', function(data)
    local inventoryId = data.inventoryId
    local internalName = data.internalName
    local itemName = data.name
    local itemAmount = data.count or 1

    if not inventoryId or not itemName then return false end

    local itemToCraft = {
        internalName = internalName,
        name = itemName,
        count = itemAmount
    }

    local p = promise.new()

    Bridge.TriggerCallback('org:Inv:AddCraftingQueueItem', function(success)
        if success then
            debugger("Added item to crafting queue:", itemName, "x" .. itemAmount)
            Sprite.updateCraftingSprite(inventoryId)
            p:resolve(true)
        else
            debugger("Failed to add item to crafting queue:", itemName)
            p:resolve(false)
        end
    end, inventoryId, itemToCraft)
    return Citizen.Await(p)
end)

InventoryUI.On('crafting:takeAllItems', function(data)
    local inventoryId = data.inventoryId
    if not inventoryId then return false end

    local p = promise.new()

    Bridge.TriggerCallback('org:Inv:TakeAllCraftingItems', function(success)
        if success then
            debugger("Took all items from crafting inventory:", inventoryId)
            Sprite.updateCraftingSprite(inventoryId)
            p:resolve(true)
        else
            debugger("Failed to take all items from crafting inventory:", inventoryId)
            p:resolve(false)
        end
    end, inventoryId)

    return Citizen.Await(p)
end)

InventoryUI.On('crafting:takeItem', function(data)
    local inventoryId = data.inventoryId
    local itemData = {
        name = data.itemName,
        count = data.count or 1,
        internalName = data.internalName
    }

    if not inventoryId or not itemData or not itemData.name then return false end

    local p = promise.new()

    Bridge.TriggerCallback('org:Inv:TakeCraftingItem', function(success)
        if success then
            debugger("Took item from crafting inventory:", itemData.name)
            Sprite.updateCraftingSprite(inventoryId)
            p:resolve(true)
        else
            debugger("Failed to take item from crafting inventory:", itemData.name)
            p:resolve(false)
        end
    end, inventoryId, itemData)

    return Citizen.Await(p)
end)

InventoryUI.On('crafting:updateRecipe', function(craftingData)
    if not craftingData or not craftingData.craftingId or not craftingData.recipe or not craftingData.recipeIndex then return false end

    local p = promise.new()

    Bridge.TriggerCallback('origen_inventory:updateCraftingRecipe', function(success)
        if success then
            debugger("Updated crafting recipe:", craftingData.craftingId)
            p:resolve(true)
        else
            debugger("Failed to update crafting recipe:", craftingData.craftingId)
            p:resolve(false)
        end
    end, craftingData)

    return Citizen.Await(p)
end)

InventoryUI.On('crafting:deleteRecipe', function(recipeData)
    if not recipeData or not recipeData.craftingId or not recipeData.recipeIndex then return false end

    local p = promise.new()

    Bridge.TriggerCallback('origen_inventory:deleteCraftingRecipe', function(success)
        if success then
            debugger("Deleted crafting recipe:", recipeData.craftingId)
            p:resolve(true)
        else
            debugger("Failed to delete crafting recipe:", recipeData.craftingId)
            p:resolve(false)
        end
    end, recipeData)

    return Citizen.Await(p)
end)

------------------------------
-----------------
---
--          MANAGEMENT
---
-----------------
------------------------------
InventoryUI.On('addCustomItem', function(itemData)
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:addCustomItem', function(success)
        p:resolve(success)
    end, itemData)

    return Citizen.Await(p)
end)

InventoryUI.On('editCustomItem', function(itemData)
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:editCustomItem', function(success)
        p:resolve(success)
    end, itemData)

    return Citizen.Await(p)
end)

--[[ Subir la foto de un item.

     La imagen no puede ir en la llamada al servidor: Cfx recomienda no pasar
     de unos 50 KB por evento y un base64 mayor no da error, se PIERDE, y el
     panel se queda en "Subiendo" para siempre. Por eso los bytes van antes por
     `origen_uploader`, que los manda con un evento latente y los deja
     esperando un minuto con un resguardo; en la llamada de aqui solo viaja ese
     resguardo, asi que el permiso se sigue comprobando en el servidor.

     De la NUI al cliente no hay red y el tamaño da igual: la pared esta solo
     en el salto cliente -> servidor. ]]
InventoryUI.On('subirFotoItem', function(datos)
    if GetResourceState('origen_uploader') ~= 'started' then
        return { ok = false, mensaje = 'origen_uploader no esta arrancado.' }
    end

    local resguardo, motivo = exports['origen_uploader']:PrepararSubida(
        datos and datos.filename or 'item.png',
        datos and datos.base64)

    if not resguardo then
        return { ok = false, mensaje = motivo or 'No se pudo preparar la imagen.' }
    end

    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:subirFotoItem', function(r)
        p:resolve(r)
    end, { name = datos.name, filename = datos.filename, ticket = resguardo })

    return Citizen.Await(p)
end)

InventoryUI.On('removeCustomItem', function(itemName)
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:removeCustomItem', function(success)
        p:resolve(success)
    end, itemName)

    return Citizen.Await(p)
end)

InventoryUI.OpenManagement = function()
    --- El panel de gestion tambien tiene raton, y tambien usa fetchNui: sin esta
    --- marca el guardado de `inventory:keepFocus` le quitaria el foco a el.
    InventoryUI.managementOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    InventoryUI.Emit({ action = 'openManagement', items = GetItems() }, false, true)
end

InventoryUI.On('closeManagement', function(datos)
    InventoryUI.managementOpen = false

    --[[ El foco es del recurso, no de la pantalla: si el inventario esta
         abierto, soltarlo aqui se lo quitaria a el. Pasa con "Ver inventario",
         que abre el del otro jugador mientras la gestion se va, y con el
         Escape que cierra las dos a la vez. El que cierre el inventario ya
         lo soltara.

         KeepInput se deja APAGADO. Estaba en true, y como el Escape del
         inventario tambien mandaba este aviso, cada cierre dejaba el teclado
         pasando al juego para el panel que viniera despues. ]]
    if not (Player and Player.isOpen) then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    -- Y la pantalla fuera, por si el cierre no vino de ella.
    InventoryUI.Emit({ action = 'closeManagement' }, false, true)

    --[[ "Ver inventario" no es volver: se ha ido a mirar un inventario, y
         reabrir el admin ahora lo pondria encima. Tampoco se guarda la
         vuelta para luego. ]]
    if datos and datos.verInventario then
        Inventory.openedFromHub = false
        return
    end

    --[[ ESC en la gestion: si se abrio desde la pestaña Scripts del admin,
         se vuelve a ella. origen_admin lo comprueba otra vez por su lado
         (solo vuelve si este panel salio de su lista). ]]
    if Inventory.openedFromHub then
        Inventory.openedFromHub = false
        if GetResourceState('origen_admin') == 'started' then
            SetTimeout(80, function()
                pcall(function() exports['origen_admin']:ReturnToScripts() end)
            end)
        end
    end
end)

InventoryUI.On('viewInventory', function(targetPlayer)
    if not targetPlayer or not targetPlayer.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('inventory:seePlayerInventory', function(success)
        p:resolve(success)
    end, targetPlayer.id, true)
    return Citizen.Await(p)
end)

InventoryUI.On('copyToClipboard', function(data)
    lib.setClipboard(data.text)
    return true
end)

InventoryUI.On('fetchCraftingZones', function()
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:fetchCraftingBoxes', function(boxes)
        p:resolve(boxes)
    end, true)
    return Citizen.Await(p)
end)

InventoryUI.On('createCraftingBox', function(boxData)
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:createCraftingBox', function(success)
        p:resolve(success)
    end, boxData)
    return Citizen.Await(p)
end)

InventoryUI.On('removeCrafting', function(boxId)
    if not boxId then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:removeCraftingBox', function(success)
        p:resolve(success)
    end, boxId)
    return Citizen.Await(p)
end)

InventoryUI.On('saveCraftingZone', function(boxData)
    if not boxData or not boxData.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:editCraftingBox', function(success)
        p:resolve(success)
    end, boxData)
    return Citizen.Await(p)
end)

InventoryUI.On('crafting:addRecipe', function(recipeData)
    if not recipeData or not recipeData.craftingId then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:addCraftingRecipe', function(success)
        p:resolve(success)
    end, recipeData)
    return Citizen.Await(p)
    
end)

InventoryUI.On('updateCraftingStatus', function(boxData)
    if not boxData or not boxData.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:updateCraftingBoxStatus', function(success)
        p:resolve(success)
    end, boxData)
    return Citizen.Await(p)
end)


InventoryUI.On('getMenuPlayers', function()
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:getMenuPlayers', function(players)
        p:resolve(players)
    end)
    return Citizen.Await(p)
end)

InventoryUI.On('deleteInventory', function(targetData)
    local targetPlayer = targetData.id
    if not targetPlayer then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:deletePlayerInventory', function(success)
        p:resolve(success)
    end, targetPlayer)

    return Citizen.Await(p)
end)

InventoryUI.On('fromMenuGiveItems', function(data)
    if not data or not data.id or not data.items or not next(data.items) then return false end
    local target = data.id
    local items = data.items
    local p = promise.new()

    Bridge.TriggerCallback('inventory:server:MenuGiveItemsToPlayer', function(success)
        p:resolve(success)
    end, target, items)

    return Citizen.Await(p)
end)
------------------------------
-----------------
---
--          SHOP
---
-----------------
------------------------------
---
InventoryUI.On('createShop', function(data, cb)
    local p = promise.new()
    data.fromServer = true

    Bridge.TriggerCallback('origen_inventory:createShop', function(success)
        p:resolve(success)
    end, data)
    return Citizen.Await(p)
end)

InventoryUI.On('fetchShops', function()
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:fetchShops', function(shops)
        p:resolve(shops)
    end, true)
    return Citizen.Await(p)
end)

InventoryUI.On('editShop', function(shopData)
    if not shopData or not shopData.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:editShop', function(success)
        p:resolve(success)
    end, shopData)
    return Citizen.Await(p)
end)

InventoryUI.On('removeShop', function(shopId)
    if not shopId then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:removeShop', function(success)
        p:resolve(success)
    end, shopId)
    return Citizen.Await(p)
end)

InventoryUI.On('updateShopStatus', function(shopData)
    if not shopData or not shopData.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:updateShopStatus', function(success)
        p:resolve(success)
    end, shopData)
    return Citizen.Await(p)
end)

InventoryUI.On('buyItems', function(buyData)
    if not buyData or not buyData.itemsToPay then return false end
    if not buyData.shopId then return false end

    -- check if shop id contains shop_ and removes it
    if buyData.shopId:match('^shop_') then
        buyData.shopId = buyData.shopId:sub(6)
    end

    --- Require sync from server
    -- if not Config.Shops[buyData.shopId] then
    --     debugger("[InventoryUI] Shop not found:", buyData.shopId)
    --     return false
    -- end

    debugger("Buying items:", json.encode(buyData, { indent = true }))

    local p = promise.new()

    Bridge.TriggerCallback('inventory:server:BuyItems', function(success)
        p:resolve(success)
    end, buyData.shopId, buyData.itemsToPay)

    return Citizen.Await(p)
end)

------------------------------
-----------------
---
--          AIRDROPS
---
-----------------
------------------------------
---
InventoryUI.On('origen_inventory:createAirdrop', function(airdropData)
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:createAirdrop', function(success)
        p:resolve(success)
    end, airdropData)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:fetchAirdrops', function()
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:fetchAirdrops', function(airdrops)
        p:resolve(airdrops)
    end)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:fetchAvailableGroups', function()
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:getAvailableGroups', function(groups)
        p:resolve(groups)
    end)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:updateAirdropStatus', function(airdropData)
    if not airdropData or not airdropData.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:updateAirdropStatus', function(success)
        p:resolve(success)
    end, airdropData)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:updateAirdrop', function(airdropData)
    if not airdropData or not airdropData.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:updateAirdrop', function(success)
        p:resolve(success)
    end, airdropData)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:removeAirdrop', function(airdropId)
    if not airdropId then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:removeAirdrop', function(success)
        p:resolve(success)
    end, airdropId)
    return Citizen.Await(p)
end)

-- Custom Stashes Management
InventoryUI.On('origen_inventory:createCustomStash', function(stashData)
    if not stashData or not stashData.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:createCustomStash', function(success)
        p:resolve(success)
    end, stashData)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:fetchCustomStashes', function()
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:fetchCustomStashes', function(stashes)
        p:resolve(stashes)
    end, true)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:updateCustomStashStatus', function(stashData)
    if not stashData or not stashData.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:updateCustomStashStatus', function(success)
        p:resolve(success)
    end, stashData)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:updateCustomStash', function(stashData)
    if not stashData or not stashData.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:updateCustomStash', function(success)
        p:resolve(success)
    end, stashData)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:removeCustomStash', function(stashId)
    if not stashId then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:removeCustomStash', function(success)
        p:resolve(success)
    end, stashId)
    return Citizen.Await(p)
end)

-- Blacklist Management
InventoryUI.On('origen_inventory:createBlacklist', function(blacklistData)
    if not blacklistData or not blacklistData.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:createBlacklist', function(success)
        p:resolve(success)
    end, blacklistData)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:fetchBlacklists', function()
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:fetchBlacklists', function(blacklists)
        p:resolve(blacklists)
    end)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:updateBlacklistStatus', function(blacklistData)
    if not blacklistData or not blacklistData.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:updateBlacklistStatus', function(success)
        p:resolve(success)
    end, blacklistData)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:updateBlacklist', function(blacklistData)
    if not blacklistData or not blacklistData.id then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:updateBlacklist', function(success)
        p:resolve(success)
    end, blacklistData)
    return Citizen.Await(p)
end)

InventoryUI.On('origen_inventory:removeBlacklist', function(blacklistId)
    if not blacklistId then return false end
    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:removeBlacklist', function(success)
        p:resolve(success)
    end, blacklistId)
    return Citizen.Await(p)
end)

InventoryUI.On('equipClothing', function(data)
    if not data or not data.slot or not data.name or not data.hash then return false end

    local previousHash = exports.origen_clothing:GetEquippedClothes(cache.ped, true)[data.name]
    
    Bridge.TriggerCallback('origen_inventory:equipClothing', function(success, clothingType)
        if success then
            local ped = PlayerPedId()
            
            if clothingType == 'props' then
                exports.origen_clothing:SetPedPropByHash(ped, data.hash, true)
            elseif clothingType == 'drawables' then
                exports.origen_clothing:SetPedDrawableByHash(ped, data.hash, true)
            end
            
            Player:LoadInventory()
        end
    end, data.slot, data.name, data.hash, previousHash)
    
    return true
end)

InventoryUI.On('moveClothing', function(data)
    if not data or not data.fromSlot or not data.toSlot or not data.clothingType then 
        return false 
    end
    
    local p = promise.new()
    
    Bridge.TriggerCallback('origen_inventory:moveClothing', function(success, clothingKey)
        if success then
            local ped = PlayerPedId()
            exports.origen_clothing:RemoveClothing(ped, clothingKey, true)
            Player:LoadInventory()
            p:resolve(exports.origen_clothing:GetEquippedClothes(cache.ped, true))
        else
            p:resolve(false)
        end
    end, data)
    
    return Citizen.Await(p)
end)

InventoryUI.On('moveAllClothesToHanger', function(data)
    if not data or not data.hangerSlot then return false end
    local hangerSlot = tonumber(data.hangerSlot)
    if not hangerSlot then return false end

    if GetResourceState('origen_clothing') ~= 'started' then
        Bridge.Notify('origen_clothing no esta iniciado.', 'error')
        return false
    end

    local p = promise.new()
    Bridge.TriggerCallback('origen_inventory:hanger:storeEquippedSet', function(success, payload)
        if not success then
            local reason = payload
            local errorMessage = reason == 'invalid_hanger_item' and 'La percha seleccionada no es valida.' or
                reason == 'no_equipped_clothes' and 'No tienes ropa equipada para guardar.' or
                reason == 'hanger_busy' and 'La percha esta siendo usada, espera un momento.' or
                reason == 'hanger_full' and 'No hay espacio en la percha para guardar toda la ropa.' or
                'No se pudo guardar la ropa en la percha.'
            Bridge.Notify(errorMessage, 'error')
            p:resolve(false)
            return
        end

        local ped = PlayerPedId()
        local removeKeys = payload and payload.removeClothingKeys or {}
        for _, clothingKey in ipairs(removeKeys) do
            exports.origen_clothing:RemoveClothing(ped, clothingKey, true)
        end

        Player:LoadInventory()
        Bridge.Notify(('Ropa guardada en: %s'):format(payload and payload.hangerName or 'Percha de conjunto'), 'success')
        p:resolve(true)
    end, hangerSlot)

    return Citizen.Await(p)
end)

InventoryUI.On('getClothingImages', function()
    if not ClothingController or not ClothingController.getClothingImages then 
        return {} 
    end
    
    return ClothingController.getClothingImages()
end)
