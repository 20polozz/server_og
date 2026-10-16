local holdingHook = false
local hookedBoat = nil
local activeRopesData = {} -- Guardará { rope = id, length = len, car = carEntity }
local activeRopes = {}
local isPilot = false
local ropeLength = 10.0
local attachedToProp = nil
local isInTowVeh = false

-- Donde queda el jugador colgado del cable: posicion y giro respecto al
-- gancho. Se midieron con un comando de depuracion (/ropeoffset) que ya no
-- esta: estaba abierto a todo el mundo y pintaba texto de GTA en pantalla.
local cuelgaX, cuelgaY, cuelgaZ = -0.04, -0.15, 0.04
local cuelgaRX, cuelgaRY, cuelgaRZ = 16.0, 6.0, 25.0



local tempRope = nil
local lastRopeUpdate = 0
local boatFrozen = false
local nuiVisible = false
local isNuiFocused = false
local currentBoatNet = nil -- boatNet activo mientras se conduce
local currentNotifyText = nil

local keysPressed = {
    interact = false,
    cancel = false,
    up = false,
    down = false,
    panel = false
}

local keysJustPressed = {
    interact = false,
    cancel = false,
    up = false,
    down = false,
    panel = false
}

local function setupKey(name, defaultKey, description)
    RegisterCommand('+' .. name, function()
        keysPressed[name] = true
        keysJustPressed[name] = true
    end, false)
    RegisterCommand('-' .. name, function()
        keysPressed[name] = false
    end, false)
    RegisterKeyMapping('+' .. name, description, 'keyboard', defaultKey)
end

local function GetKeyLabel(commandName)
    if type(GetBindingForCommand) == "function" then
        local ok, binding = pcall(GetBindingForCommand, commandName)
        if ok and binding and binding ~= "" then
            local label = binding:gsub("keyboard%s+", ""):gsub("mouse_button%s+", "")
            return label:upper()
        end
    end
    -- Fallbacks
    if commandName == "+interact" then return Config.Keys.Interact or "E" end
    if commandName == "+cancel" then return Config.Keys.Cancel or "G" end
    if commandName == "+up" then return Config.Keys.Up or "PAGEUP" end
    if commandName == "+down" then return Config.Keys.Down or "PAGEDOWN" end
    if commandName == "+panel" then return Config.Keys.Panel or "H" end
    return "E"
end

CreateThread(function()
    setupKey('interact', Config.Keys.Interact, 'Remolque de barcos: interactuar')
    setupKey('cancel', Config.Keys.Cancel, 'Remolque de barcos: cancelar o soltar')
    setupKey('up', Config.Keys.Up, 'Remolque de barcos: subir')
    setupKey('down', Config.Keys.Down, 'Remolque de barcos: bajar')
    setupKey('panel', Config.Keys.Panel or 'H', 'Remolque de barcos: panel de control')
end)

local frameJustPressed = {}
CreateThread(function()
    while true do
        Wait(0)
        for k, v in pairs(keysJustPressed) do
            frameJustPressed[k] = v
            keysJustPressed[k] = false
        end
    end
end)



-- ──────────────────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────────────────

local function DrawOrigenText(key, text)
    if currentNotifyText ~= text then
        exports['origen_notify']:DrawText(key, text)
        currentNotifyText = text
    end
end

local function HideOrigenText()
    if currentNotifyText then
        exports['origen_notify']:HideText()
        currentNotifyText = nil
    end
end

local function Notify(msg, ntype)
    lib.notify({ description = msg, type = ntype or 'inform' })
end

local function GetClosestVehicleToPed(ped, ignoreVeh)
    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local closestDist = 999.0
    local closestVeh = nil
    for i = 1, #vehicles do
        local v = vehicles[i]
        if v ~= ignoreVeh then
            local d = #(coords - GetEntityCoords(v))
            if d < closestDist then
                closestDist = d
                closestVeh = v
            end
        end
    end
    return closestVeh, closestDist
end

local function ShowWinchUI(length)
    if not nuiVisible then
        SendNUIMessage({ type = 'showWinch', length = length })
        nuiVisible = true
    else
        SendNUIMessage({ type = 'updateLength', length = length })
    end
end

local function HideWinchUI()
    if nuiVisible then
        SendNUIMessage({ type = 'hideWinch' })
        nuiVisible = false
    end
end

local function IsVehicleAllowed(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return false, nil end
    local model = GetEntityModel(veh)
    if Config.AllowedBoats[model] then
        return true, Config.AllowedBoats[model]
    end
    for k, v in pairs(Config.AllowedBoats) do
        if type(k) == "string" then
            if GetHashKey(k) == model or joaat(k:lower()) == model then
                return true, v
            end
        elseif type(k) == "number" then
            if k == model then
                return true, v
            end
        end
    end
    return false, nil
end

local function GetHookAttachmentCoords(veh)
    local model = GetEntityModel(veh)
    local minDim, maxDim = GetModelDimensions(model)
    local isAllowed, cfg = IsVehicleAllowed(veh)

    -- Si se ha definido un offset específico válido en la config que no sea (0,0,0)
    if type(cfg) == "table" and cfg.offset then
        local ox = cfg.offset.x or 0.0
        local oy = cfg.offset.y or 0.0
        local oz = cfg.offset.z or 0.0
        if ox ~= 0.0 or oy ~= 0.0 or oz ~= 0.0 then
            return GetOffsetFromEntityInWorldCoords(veh, ox, oy, oz)
        end
    end

    local vClass = GetVehicleClass(veh)

    -- Si el vehículo es un helicóptero (Clase 15), usar la barriga
    if vClass == 15 then
        return GetOffsetFromEntityInWorldCoords(veh, 0.0, 0.0, minDim.z + 0.5)
    end

    -- Si el vehículo es un barco (Clase 14), usar la parte trasera del barco
    if vClass == 14 then
        return GetOffsetFromEntityInWorldCoords(veh, 0.0, minDim.y + 0.5, -0.2)
    end

    -- Por defecto para coches, camiones y demás vehículos terrestres:
    -- Parte trasera centrada a la altura del enganche / paragolpes
    return GetOffsetFromEntityInWorldCoords(veh, 0.0, minDim.y - 0.1, minDim.z + 0.45)
end

local function GetClosestTowVehicle(ped, maxRadius)
    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local closestDist = maxRadius or 15.0
    local closestVeh = nil
    local closestBackOffset = nil

    for i = 1, #vehicles do
        local v = vehicles[i]
        local isAllowed = IsVehicleAllowed(v)
        if isAllowed then
            local backOffset = GetHookAttachmentCoords(v)
            local delta = coords - backOffset
            local horizDist = #(vector2(delta.x, delta.y))
            local vertDist = math.abs(delta.z)
            local d = math.sqrt(horizDist^2 + (vertDist * 0.7)^2)
            if d < closestDist then
                closestDist = d
                closestVeh = v
                closestBackOffset = backOffset
            end
        end
    end

    return closestVeh, closestDist, closestBackOffset
end

-- ──────────────────────────────────────────────────────────
-- NUI Callbacks — botones del panel
-- ──────────────────────────────────────────────────────────

RegisterNUICallback('recoger', function(_, cb)
    if currentBoatNet and activeRopesData[currentBoatNet] then
        local rData = activeRopesData[currentBoatNet]
        if not boatFrozen then
            FreezeEntityPosition(NetToVeh(currentBoatNet), true)
            boatFrozen = true
        end
        TriggerServerEvent('origen_boattow:server:updateRopeLength', currentBoatNet, -0.5)
    end
    cb('ok')
end)

RegisterNUICallback('soltar', function(_, cb)
    if currentBoatNet and activeRopesData[currentBoatNet] then
        if not boatFrozen then
            FreezeEntityPosition(NetToVeh(currentBoatNet), true)
            boatFrozen = true
        end
        TriggerServerEvent('origen_boattow:server:updateRopeLength', currentBoatNet, 0.5)
    end
    cb('ok')
end)

RegisterNUICallback('stopWinch', function(_, cb)
    if currentBoatNet then
        local boat = NetToVeh(currentBoatNet)
        if DoesEntityExist(boat) and boatFrozen then
            FreezeEntityPosition(boat, false)
            boatFrozen = false
        end
    end
    cb('ok')
end)

RegisterNUICallback('closeUI', function(_, cb)
    isNuiFocused = false
    SetNuiFocus(false, false)
    HideWinchUI()
    cb('ok')
end)

RegisterNUICallback('cortar', function(_, cb)
    if currentBoatNet then
        TriggerServerEvent('origen_boattow:server:removeRope', currentBoatNet)
        Notify('Cuerda de remolque cortada.', 'inform')
    end
    cb('ok')
end)

-- ──────────────────────────────────────────────────────────
-- Sincronización inicial
-- ──────────────────────────────────────────────────────────

CreateThread(function()
    TriggerServerEvent('origen_boattow:server:requestSync')
end)

-- ──────────────────────────────────────────────────────────
-- Main Loop
-- ──────────────────────────────────────────────────────────

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local inVeh = GetVehiclePedIsIn(ped, false)
        local isTowVeh, _ = IsVehicleAllowed(inVeh)
        local isInTowVeh = (inVeh ~= 0 and isTowVeh)
        local showTextThisFrame = false
        local textKey = nil
        local textStr = nil

        -- ── Piloto de barco o vehículo de remolque ──
        if isInTowVeh then
            local bNet = 0
            if NetworkGetEntityIsNetworked(inVeh) then bNet = VehToNet(inVeh) end

            if bNet ~= 0 then
                if activeRopesData[bNet] then
                    sleep = 0
                    currentBoatNet = bNet

                    if not isNuiFocused then
                        showTextThisFrame = true
                        textKey = GetKeyLabel('+panel')
                        textStr = 'Panel Grúa'
                    end

                    if frameJustPressed.panel then -- H
                        isNuiFocused = not isNuiFocused
                        SetNuiFocus(isNuiFocused, isNuiFocused)
                        if isNuiFocused then
                            ShowWinchUI(activeRopesData[bNet].length)
                        else
                            HideWinchUI()
                        end
                    end
                else
                    sleep = 0
                    if not isNuiFocused then
                        showTextThisFrame = true
                        textKey = GetKeyLabel('+cancel')
                        textStr = 'Desplegar Gancho'
                    end
                    
                    if frameJustPressed.cancel then -- G
                        local propModel = `xm3_prop_xm3_hook_01a`
                        RequestModel(propModel)
                        while not HasModelLoaded(propModel) do Wait(0) end
                        
                        local backOffset = GetHookAttachmentCoords(inVeh)
                        local spawnCoords = vector3(backOffset.x, backOffset.y, backOffset.z - 2.0)
                        
                        local prop = CreateObject(propModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, true, true, false)
                        SetEntityCollision(prop, true, true)
                        SetEntityDynamic(prop, true)
                        local propNet = ObjToNet(prop)
                        SetNetworkIdExistsOnAllMachines(propNet, true)
                        
                        TriggerServerEvent('origen_boattow:server:syncRope', bNet, propNet, 2.0)
                        Notify('Gancho desplegado. Abre el panel (H) para bajarlo.', 'success')
                    end

                    -- Sin cuerda: ocultar si estaba visible
                    if nuiVisible then
                        HideWinchUI()
                        isNuiFocused = false
                        SetNuiFocus(false, false)
                        currentBoatNet = nil
                        if boatFrozen then
                            FreezeEntityPosition(inVeh, false)
                            boatFrozen = false
                        end
                    end
                end
            end
        else
            -- No está de piloto: ocultar NUI y descongelar si hace falta
            if nuiVisible then
                HideWinchUI()
                isNuiFocused = false
                SetNuiFocus(false, false)
                currentBoatNet = nil
            end
            if boatFrozen and inVeh == 0 then
                boatFrozen = false
            end
        end

        -- ── A pie: buscar vehículos autorizados y enganchar ──
        if not holdingHook and not isInTowVeh and not attachedToProp then
            local closestVeh, distToBack, backOffset = GetClosestTowVehicle(ped, 15.0)
            if closestVeh then
                sleep = 0
                local maxDist = Config.InteractDistance or 3.0

                if not NetworkGetEntityIsNetworked(closestVeh) then
                    NetworkRegisterEntityAsNetworked(closestVeh)
                end
                local boatNet = VehToNet(closestVeh)

                if boatNet ~= 0 and activeRopesData[boatNet] then
                    if distToBack <= maxDist then
                        showTextThisFrame = true
                        textKey = GetKeyLabel('+cancel')
                        textStr = 'Soltar Cuerda'
                        if frameJustPressed.cancel then
                            TriggerServerEvent('origen_boattow:server:removeRope', boatNet)
                            Notify('Cuerda de remolque desconectada.', 'inform')
                        end
                    end
                else
                    if distToBack <= maxDist then
                        showTextThisFrame = true
                        textKey = GetKeyLabel('+interact')
                        textStr = 'Coger Gancho'
                        if frameJustPressed.interact then
                            holdingHook = true
                            hookedBoat = closestVeh
                            Notify('Gancho cogido. Ve hasta el vehículo a rescatar o tíralo al suelo (G).', 'inform')
                            RopeLoadTextures()
                            while not RopeAreTexturesLoaded() do Wait(0) end
                            tempRope = AddRope(backOffset.x, backOffset.y, backOffset.z, 0.0, 0.0, 0.0, Config.RopeLength, 4, Config.RopeLength, 1.0, 1.0, false, false, false, 1.0, true)
                            AttachEntitiesToRope(tempRope, closestVeh, ped, backOffset.x, backOffset.y, backOffset.z, coords.x, coords.y, coords.z, Config.RopeLength, false, false, nil, nil)
                        end
                    end
                end
            end
            
            -- Lógica para engancharse a un cable suelto (prop)
            if not holdingHook and not attachedToProp then
                local closestProp = nil
                local propDist = 3.0
                local pBoatNet = nil
                for bNet, data in pairs(activeRopesData) do
                    if DoesEntityExist(data.car) and GetEntityType(data.car) == 3 then
                        local d = #(coords - GetEntityCoords(data.car))
                        if d < propDist then
                            propDist = d
                            closestProp = data.car
                            pBoatNet = bNet
                        end
                    end
                end
                
                if closestProp then
                    sleep = 0
                    showTextThisFrame = true
                    textKey = GetKeyLabel('+interact')
                    textStr = 'Engancharse al cable'
                    if frameJustPressed.interact then
                        attachedToProp = closestProp
                        
                        -- Cargar animación
                        RequestAnimDict("missrappel")
                        while not HasAnimDictLoaded("missrappel") do Wait(0) end
                        TaskPlayAnim(ped, "missrappel", "rappel_idle", 8.0, -8.0, -1, 1, 0, false, false, false)
                        -- Attach inicial (fixedRot = true para que herede el balanceo de la cuerda)
                        AttachEntityToEntity(ped, attachedToProp, 0, cuelgaX, cuelgaY, cuelgaZ, cuelgaRX, cuelgaRY, cuelgaRZ, false, false, false, true, 2, true)
                        Notify('Te has enganchado al cable. Usa G para soltarte.', 'success')
                    end
                end
            elseif attachedToProp then
                sleep = 0
                showTextThisFrame = true
                textKey = GetKeyLabel('+cancel')
                textStr = 'Soltarse'
                
                -- Mantener animación
                if not IsEntityPlayingAnim(ped, "missrappel", "rappel_idle", 3) then
                    TaskPlayAnim(ped, "missrappel", "rappel_idle", 8.0, -8.0, -1, 1, 0, false, false, false)
                end
                
                
                if frameJustPressed.cancel or not DoesEntityExist(attachedToProp) then
                    DetachEntity(ped, true, false)
                    ClearPedTasks(ped)
                    attachedToProp = nil
                    Notify('Te has soltado del cable.', 'inform')
                end
            end
        elseif holdingHook and not isInTowVeh then
            sleep = 0
            
            local boatCoords = GetEntityCoords(hookedBoat)
            if #(coords - boatCoords) > Config.RopeLength + 10.0 or frameJustPressed.cancel then
                holdingHook = false
                if tempRope then DeleteRope(tempRope); tempRope = nil end
                hookedBoat = nil
                Notify('Has soltado el gancho.', 'inform')
            else
                local targetVeh, targetDist = GetClosestVehicleToPed(ped, hookedBoat)
                if targetVeh and targetDist < 3.0 then
                    showTextThisFrame = true
                    textKey = GetKeyLabel('+interact') .. ' / ' .. GetKeyLabel('+cancel')
                    textStr = 'Enganchar / Soltar'
                    
                    if frameJustPressed.interact then
                        if not NetworkGetEntityIsNetworked(hookedBoat) then NetworkRegisterEntityAsNetworked(hookedBoat) end
                        if not NetworkGetEntityIsNetworked(targetVeh) then NetworkRegisterEntityAsNetworked(targetVeh) end

                        local boatNet = VehToNet(hookedBoat)
                        local carNet  = VehToNet(targetVeh)

                        if boatNet > 0 and carNet > 0 then
                            holdingHook = false
                            if tempRope then DeleteRope(tempRope); tempRope = nil end
                            hookedBoat = nil
                            TriggerServerEvent('origen_boattow:server:syncRope', boatNet, carNet, Config.RopeLength)
                            Notify('Vehículo enganchado. Sube al barco y usa el panel para recoger la cuerda.', 'success')
                        end
                    end
                else
                    showTextThisFrame = true
                    textKey = GetKeyLabel('+interact') .. ' / ' .. GetKeyLabel('+cancel')
                    textStr = 'Soltar al suelo / Soltar'
                    
                    if frameJustPressed.interact then
                        -- Soltar al suelo (spawn prop)
                        if not NetworkGetEntityIsNetworked(hookedBoat) then NetworkRegisterEntityAsNetworked(hookedBoat) end
                        local boatNet = VehToNet(hookedBoat)
                        
                        if boatNet > 0 then
                            local propModel = `xm3_prop_xm3_hook_01a`
                            RequestModel(propModel)
                            while not HasModelLoaded(propModel) do Wait(0) end
                            
                            local spawnCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.5, 0.0)
                            local _, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 1.0, false)
                            local zPos = groundZ ~= 0.0 and groundZ or spawnCoords.z
                            
                            local prop = CreateObject(propModel, spawnCoords.x, spawnCoords.y, zPos, true, true, false)
                            SetEntityCollision(prop, true, true)
                            SetEntityDynamic(prop, true)
                            local propNet = ObjToNet(prop)
                            SetNetworkIdExistsOnAllMachines(propNet, true)
                            
                            holdingHook = false
                            if tempRope then DeleteRope(tempRope); tempRope = nil end
                            
                            local actualDist = #(coords - GetEntityCoords(hookedBoat))
                            if actualDist < 5.0 then actualDist = 5.0 end
                            
                            local savedBoat = hookedBoat
                            hookedBoat = nil
                            TriggerServerEvent('origen_boattow:server:syncRope', boatNet, propNet, actualDist)
                            Notify('Cable bajado al suelo. Puedes engancharte a él.', 'success')
                        end
                    end
                end
            end
        end

        if showTextThisFrame then
            DrawOrigenText(textKey, textStr)
        else
            HideOrigenText()
        end

        Wait(sleep)
    end
end)

-- ──────────────────────────────────────────────────────────
-- Eventos de Red
-- ──────────────────────────────────────────────────────────

RegisterNetEvent('origen_boattow:client:addRope', function(boatNet, carNet, length)
    CreateThread(function()
        local timeout = 0
        while (not DoesEntityExist(NetToVeh(boatNet)) or not DoesEntityExist(NetworkGetEntityFromNetworkId(carNet))) and timeout < 50 do
            Wait(100); timeout = timeout + 1
        end
        if timeout >= 50 then return end

        local boat = NetToVeh(boatNet)
        local car  = NetworkGetEntityFromNetworkId(carNet)

        RopeLoadTextures()
        while not RopeAreTexturesLoaded() do Wait(0) end

        local cCoords = GetEntityCoords(car)
        local backOffset = GetHookAttachmentCoords(boat)

        local rope = AddRope(backOffset.x, backOffset.y, backOffset.z, 0.0, 0.0, 0.0, length, 4, length, 1.0, 1.0, false, false, false, 1.0, true)
        AttachEntitiesToRope(rope, boat, car, backOffset.x, backOffset.y, backOffset.z, cCoords.x, cCoords.y, cCoords.z, length, false, false, nil, nil)
        SetBoatAnchor(boat, false)

        activeRopesData[boatNet] = { rope = rope, length = length, car = car }
    end)
end)

RegisterNetEvent('origen_boattow:client:removeRope', function(boatNet)
    if activeRopesData[boatNet] then
        local car = activeRopesData[boatNet].car
        if DoesEntityExist(car) and GetEntityType(car) == 3 then
            NetworkRequestControlOfEntity(car)
            DeleteEntity(car)
        end
        DeleteRope(activeRopesData[boatNet].rope)
        activeRopesData[boatNet] = nil
    end
    if currentBoatNet == boatNet then
        HideWinchUI()
        currentBoatNet = nil
    end
end)

RegisterNetEvent('origen_boattow:client:updateRopeLength', function(boatNet, carNet, newLength)
    if activeRopesData[boatNet] then
        local oldLength = activeRopesData[boatNet].length
        DeleteRope(activeRopesData[boatNet].rope)

        local boat = NetToVeh(boatNet)
        local car  = NetworkGetEntityFromNetworkId(carNet)

        local backOffset = GetHookAttachmentCoords(boat)
        local cCoords = GetEntityCoords(car)

        local rope = AddRope(backOffset.x, backOffset.y, backOffset.z, 0.0, 0.0, 0.0, newLength, 4, newLength, 0.0, 0.0, false, false, false, 1.0, true)
        ActivatePhysics(rope)
        AttachEntitiesToRope(rope, boat, car, backOffset.x, backOffset.y, backOffset.z, cCoords.x, cCoords.y, cCoords.z, newLength, false, false, nil, nil)

        activeRopesData[boatNet].rope   = rope
        activeRopesData[boatNet].length = newLength

        -- Actualizar la NUI si estamos mirando este barco
        if nuiVisible and currentBoatNet == boatNet then
            SendNUIMessage({ type = 'updateLength', length = newLength })
        end
    end
end)

-- ──────────────────────────────────────────────────────────
-- Herramienta In-Game para Setear Offsets (/ganchooffset)
-- ──────────────────────────────────────────────────────────

local editingOffset = false
local currentOffset = vector3(0.0, 0.0, 0.0)
local editingVeh = nil

local function RunOffsetEditor(cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        veh, _ = GetClosestVehicleToPed(ped, nil)
    end
    
    if not veh or veh == 0 then
        Notify('No hay vehículo cerca o no estás en uno', 'error')
        if cb then cb("0.0, 0.0, 0.0") end
        return
    end
    
    editingOffset = true
    editingVeh = veh
    local minDim, maxDim = GetModelDimensions(GetEntityModel(veh))
    local vClass = GetVehicleClass(veh)
    local defaultY = (vClass == 14 and (minDim.y + 0.5)) or (vClass == 15 and 0.0) or (minDim.y - 0.1)
    local defaultZ = (vClass == 14 and -0.2) or (vClass == 15 and (minDim.z + 0.5)) or (minDim.z + 0.45)
    currentOffset = vector3(0.0, defaultY, defaultZ)
    Notify('Modo edición: Flechas (X/Y), RePág/AvPág (Z). INTRO para confirmar.', 'success')
    
    CreateThread(function()
        while editingOffset do
            Wait(0)
            if not DoesEntityExist(editingVeh) then
                editingOffset = false
                if cb then cb("0.0, 0.0, 0.0") end
                break
            end
            
            local speed = 0.02
            if IsControlPressed(0, 21) then speed = 0.1 end -- Shift
            if IsControlPressed(0, 36) then speed = 0.005 end -- Ctrl
            
            if IsControlPressed(0, 172) then currentOffset = currentOffset + vector3(0.0, speed, 0.0) end
            if IsControlPressed(0, 173) then currentOffset = currentOffset - vector3(0.0, speed, 0.0) end
            if IsControlPressed(0, 174) then currentOffset = currentOffset - vector3(speed, 0.0, 0.0) end
            if IsControlPressed(0, 175) then currentOffset = currentOffset + vector3(speed, 0.0, 0.0) end
            if keysPressed.down then currentOffset = currentOffset + vector3(0.0, 0.0, speed) end
            if keysPressed.up then currentOffset = currentOffset - vector3(0.0, 0.0, speed) end
            
            local worldCoords = GetOffsetFromEntityInWorldCoords(editingVeh, currentOffset.x, currentOffset.y, currentOffset.z)
            DrawMarker(28, worldCoords.x, worldCoords.y, worldCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 216, 27, 85, 200, false, false, 2, false, nil, nil, false)
            
            local str = string.format("X: %.2f | Y: %.2f | Z: %.2f", currentOffset.x, currentOffset.y, currentOffset.z)
            DrawOrigenText('DESPLAZAMIENTO', str .. ' ~n~~w~[INTRO] Confirmar | [RETROCESO] Salir')
            
            if IsControlJustPressed(0, 191) then -- ENTER
                editingOffset = false
                HideOrigenText()
                local finalStr = string.format("%.2f, %.2f, %.2f", currentOffset.x, currentOffset.y, currentOffset.z)
                if cb then cb(finalStr) end
                Notify('Offset capturado.', 'success')
            end
            
            if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 200) then -- BACKSPACE/ESC
                editingOffset = false
                HideOrigenText()
                Notify('Edición cancelada.', 'error')
                if cb then cb("0.0, 0.0, 0.0") end
            end
        end
        HideOrigenText()
    end)
end

exports('StartOffsetEditor', function(model, cb)
    RunOffsetEditor(cb)
end)

--[[ Herramienta de administracion: lo decide el servidor
     (Comando:ganchooffset de origen_admin). Antes la tenia cualquiera. ]]
RegisterCommand('ganchooffset', function()
    if not editingOffset and not lib.callback.await('origen_boattow:server:puedeAjustar', false) then
        Notify('No tienes acceso a este comando.', 'error')
        return
    end

    if editingOffset then
        editingOffset = false
        HideOrigenText()
        Notify('Modo edición desactivado.', 'error')
    else
        RunOffsetEditor(function(offset)
            local finalStr = "vector3(" .. offset .. ")"
            print('--- OFFSET GANCHO ---')
            print(finalStr)
            print('---------------------')
            pcall(function() lib.setClipboard(finalStr) end)
            Notify('Copiado al portapapeles y mostrado en F8 (consola)', 'success')
        end)
    end
end, false)

-- ──────────────────────────────────────────────────────────
-- Integración con origen_police (Vehículos Autorizados)
-- ──────────────────────────────────────────────────────────
RegisterNetEvent('origen_police:client:updateExtraVehicles')
AddEventHandler('origen_police:client:updateExtraVehicles', function(extraVehicles)
    if not extraVehicles then return end
    for model, data in pairs(extraVehicles) do
        local canTow = (data.can_tow == true or data.can_tow == 1 or data.can_tow == "1" or data.can_tow == "true")
        local mStr = tostring(model):lower():gsub("%s+", "")
        local hash = GetHashKey(mStr)
        local hashRaw = GetHashKey(model)
        
        if canTow then
            -- Intentar parsear el offset si es un string "X, Y, Z"
            local offsetVec = nil
            if data.tow_offset and type(data.tow_offset) == "string" and data.tow_offset ~= "" and data.tow_offset ~= "0.0, 0.0, 0.0" then
                local x, y, z = string.match(data.tow_offset, "([^,]+),([^,]+),([^,]+)")
                if x and y and z then
                    local ox, oy, oz = tonumber(x) or 0.0, tonumber(y) or 0.0, tonumber(z) or 0.0
                    if ox ~= 0.0 or oy ~= 0.0 or oz ~= 0.0 then
                        offsetVec = vector3(ox, oy, oz)
                    end
                end
            end
            
            local entry = { offset = offsetVec }
            Config.AllowedBoats[hash] = entry
            Config.AllowedBoats[hashRaw] = entry
            Config.AllowedBoats[mStr] = entry
            Config.AllowedBoats[model] = entry
        else
            -- Si no puede remolcar pero estaba en la lista, lo quitamos
            if Config.AllowedBoats[hash] then Config.AllowedBoats[hash] = nil end
            if Config.AllowedBoats[hashRaw] then Config.AllowedBoats[hashRaw] = nil end
            if Config.AllowedBoats[mStr] then Config.AllowedBoats[mStr] = nil end
            if Config.AllowedBoats[model] then Config.AllowedBoats[model] = nil end
        end
    end
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent("origen_police:admin:requestExtraVehiclesSync")
    Wait(4000)
    TriggerServerEvent("origen_police:admin:requestExtraVehiclesSync")
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    TriggerServerEvent("origen_police:admin:requestExtraVehiclesSync")
end)

RegisterNetEvent('esx:playerLoaded', function()
    Wait(2000)
    TriggerServerEvent("origen_police:admin:requestExtraVehiclesSync")
end)
