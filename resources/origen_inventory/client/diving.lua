local isDiving = false
local maskProp = nil
local tankProp = nil
local MAX_OXYGEN = 900.0 -- 15 minutos en segundos
local currentOxygen = 0.0
local currentSlot = nil -- slot del ítem equipado actualmente

--[[ El oxigeno bajo el agua, en el aviso de origen_notify (antes un texto de
     GTA abajo al centro). Solo se manda cuando cambia el porcentaje, y se
     quita al salir a la superficie o al quitarse el equipo. ]]
CreateThread(function()
    local visto = nil
    while true do
        Wait(500)
        local ped = PlayerPedId()
        if isDiving and IsPedSwimmingUnderWater(ped) then
            local percentage = math.max(0, math.floor((currentOxygen / MAX_OXYGEN) * 100))
            if percentage ~= visto then
                visto = percentage
                local aviso = percentage < 25 and ' · ¡sube ya!' or ''
                exports['origen_notify']:DrawText('O₂', ('Oxígeno %d %%%s'):format(percentage, aviso))
            end
        elseif visto then
            visto = nil
            exports['origen_notify']:HideText()
        end
    end
end)

-- Hilo para la lógica del oxígeno (se resta cada segundo)
-- Solo cuenta cuando isDiving = true (equipo puesto). Al quitarlo se pausa automáticamente.
CreateThread(function()
    while true do
        Wait(1000)
        if isDiving then
            local ped = PlayerPedId()
            if IsPedSwimmingUnderWater(ped) then
                if currentOxygen > 0 then
                    currentOxygen = currentOxygen - 1.0
                end
                
                if currentOxygen <= 0 then
                    -- Oxígeno agotado: el ítem se ha consumido completamente
                    SetEnableScuba(ped, false)
                    SetPedMaxTimeUnderwater(ped, 0.0)
                    
                    -- Limpiar props
                    if maskProp then DeleteEntity(maskProp); maskProp = nil end
                    if tankProp then DeleteEntity(tankProp); tankProp = nil end
                    
                    -- Resetear estado
                    isDiving = false
                    currentOxygen = 0.0
                    
                    -- Notificar al jugador
                    if Bridge and Bridge.Notify then
                        Bridge.Notify('¡Se ha agotado el oxígeno! El equipo de buceo se ha gastado.', 'error')
                    end
                    
                    -- Enviar evento al servidor para eliminar el ítem del inventario
                    TriggerServerEvent('diving:server:consumeGear', currentSlot)
                    currentSlot = nil
                else
                    -- Asegurarse de que mientras quede oxígeno, Scuba esté activo
                    SetEnableScuba(ped, true)
                end
            end
        end
    end
end)

exports('UseDivingGear', function(slot, item)
    -- Guardar el slot para poder eliminarlo cuando se agote el oxígeno
    local ped = PlayerPedId()
    if isDiving then
        -- Quitar equipo
        exports['origen_inventory']:progressBar({
            name = 'quitar_buceo',
            duration = 5000, -- 15 segundos
            label = 'Quitando equipo de buceo...',
            useWhileDead = false,
            canCancel = true,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            },
            animation = {
                animDict = 'clothingshirt',
                anim = 'try_shirt_positive_d',
                flags = 49,
            },
        }, nil, nil, function(cancelled)
            if cancelled then
                if Bridge and Bridge.Notify then Bridge.Notify('Acción cancelada.', 'error') end
                return
            end
            
            isDiving = false
            SetEnableScuba(ped, false)
            SetPedMaxTimeUnderwater(ped, 10.0)
            
            if maskProp then DeleteEntity(maskProp); maskProp = nil end
            if tankProp then DeleteEntity(tankProp); tankProp = nil end
            
            if currentSlot then
                TriggerServerEvent('diving:server:updateGearOxygen', currentSlot, currentOxygen)
                currentSlot = nil
            else
                print('[Buceo] ERROR: No hay currentSlot al desequipar!')
            end

            
            if Bridge and Bridge.Notify then
                Bridge.Notify('Te has quitado el equipo de buceo.', 'info')
            else
                TriggerEvent('chatMessage', 'Buceo', {255, 0, 0}, 'Te has quitado el equipo de buceo.')
            end
        end)
    else
        -- Poner equipo
        exports['origen_inventory']:progressBar({
            name = 'poner_buceo',
            duration = 10000, -- 30 segundos
            label = 'Poniendo equipo de buceo...',
            useWhileDead = false,
            canCancel = true,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            },
            animation = {
                animDict = 'clothingshirt',
                anim = 'try_shirt_positive_d',
                flags = 49,
            },
        }, nil, nil, function(cancelled)
            if cancelled then
                if Bridge and Bridge.Notify then Bridge.Notify('Acción cancelada.', 'error') end
                return
            end
            
            isDiving = true
            local meta = item and (item.metadata or item.info) or {}
            currentOxygen = tonumber(meta.oxygen) or MAX_OXYGEN
            currentSlot = slot -- guardar el slot del ítem para eliminarlo cuando se gaste
            SetEnableScuba(ped, true)
            SetPedMaxTimeUnderwater(ped, MAX_OXYGEN)
            
            -- Cargar modelos de GTA V para buceo
            local maskModel = `p_s_scuba_mask_s`
            local tankModel = `p_s_scuba_tank_s`
            
            RequestModel(maskModel)
            while not HasModelLoaded(maskModel) do Wait(10) end
            
            RequestModel(tankModel)
            while not HasModelLoaded(tankModel) do Wait(10) end
            
            local coords = GetEntityCoords(ped)
            maskProp = CreateObject(maskModel, coords.x, coords.y, coords.z, true, true, false)
            tankProp = CreateObject(tankModel, coords.x, coords.y, coords.z, true, true, false)
            
            -- Ajustar el tanque en la espalda (posición y rotación corregida)
            AttachEntityToEntity(tankProp, ped, GetPedBoneIndex(ped, 24818), -0.30, -0.22, 0.0, 0.0, 90.0, 180.0, true, true, false, true, 1, true)
            -- Ajustar las gafas en la cabeza
            AttachEntityToEntity(maskProp, ped, GetPedBoneIndex(ped, 12844), 0.0, 0.0, 0.0, 0.0, 90.0, 180.0, true, true, false, true, 1, true)
            
            if Bridge and Bridge.Notify then
                Bridge.Notify('Te has equipado el equipo de buceo. ¡Al agua!', 'success')
            else
                TriggerEvent('chatMessage', 'Buceo', {0, 255, 0}, 'Te has equipado el equipo de buceo. ¡Al agua!')
            end
        end)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if maskProp then DeleteEntity(maskProp) end
        if tankProp then DeleteEntity(tankProp) end
    end
end)

-- Comando de ayuda temporal para ajustar la posición de la bombona en vivo sin reiniciar script
RegisterCommand('ajustebombona', function(source, args)
    if not isDiving or not tankProp then 
        print("Ponte el traje de buceo primero para ajustar la bombona.")
        return 
    end
    
    local x = tonumber(args[1]) or -0.30
    local y = tonumber(args[2]) or -0.22
    local z = tonumber(args[3]) or 0.0
    local rx = tonumber(args[4]) or 0.0
    local ry = tonumber(args[5]) or 90.0
    local rz = tonumber(args[6]) or 180.0
    
    local ped = PlayerPedId()
    AttachEntityToEntity(tankProp, ped, GetPedBoneIndex(ped, 24818), x, y, z, rx, ry, rz, true, true, false, true, 1, true)
    
    print(("Offsets Bombona Ajustados -> X: %s Y: %s Z: %s | RX: %s RY: %s RZ: %s"):format(x, y, z, rx, ry, rz))
    if Bridge and Bridge.Notify then
        Bridge.Notify(('Offsets actualizados: X:%s Y:%s Z:%s'):format(x,y,z), 'success')
    end
end)
