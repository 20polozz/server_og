local function bvsDebug(message) if Config.Debug then print(message) end end
local currentAlcohol = 0
local currentStage = nil
local originalWalkstyle = nil
local isEffectActive = false
local isLoopRunning = false
local lastStumbleTime = 0
local lastDecayTime = 0
local lastDrinkTimer = 0

local function getAlcoholConfig()
    return Config and Config.Alcohol or nil
end

local function getStageForLevel(level)
    local cfg = getAlcoholConfig()
    if not cfg or not cfg.Enabled or not cfg.Stages then return nil end

    if cfg.Stages.Heavy and level >= cfg.Stages.Heavy.Threshold then
        return 'Heavy', cfg.Stages.Heavy
    elseif cfg.Stages.Medium and level >= cfg.Stages.Medium.Threshold then
        return 'Medium', cfg.Stages.Medium
    elseif cfg.Stages.Light and level >= cfg.Stages.Light.Threshold then
        return 'Light', cfg.Stages.Light
    end

    return nil, nil
end

local function setDrunkWalk(animSet)
    if not animSet or animSet == '' then return end
    local ped = PlayerPedId()

    RequestAnimSet(animSet)
    local attempts = 0
    while not HasAnimSetLoaded(animSet) and attempts < 30 do
        Wait(50)
        attempts = attempts + 1
    end

    if HasAnimSetLoaded(animSet) then
        SetPedMovementClipset(ped, animSet, 1.0)
    end
end

local function saveOriginalWalkstyle()
    if originalWalkstyle then return end

    if GetResourceState('ianemotes'):match('start') then
        local ok, walk = pcall(function()
            return exports.ianemotes:getWalkstyle()
        end)
        if ok and walk and walk ~= '' then
            originalWalkstyle = walk
            return
        end
    end

    local kvp = GetResourceKvpString('walkstyle')
    if kvp and kvp ~= '' then
        originalWalkstyle = kvp
    end
end

local function restoreOriginalWalkstyle()
    local ped = PlayerPedId()
    ResetPedMovementClipset(ped, 0.0)

    if originalWalkstyle then
        if GetResourceState('ianemotes'):match('start') then
            pcall(function()
                exports.ianemotes:setWalkstyle(originalWalkstyle)
            end)
        end
        originalWalkstyle = nil
    end
end

local function clearDrunkEffects()
    local ped = PlayerPedId()

    ClearTimecycleModifier()
    StopGameplayCamShaking(true)
    SetPedIsDrunk(ped, false)
    SetPedMotionBlur(ped, false)

    restoreOriginalWalkstyle()

    currentStage = nil
    isEffectActive = false
end

local function applyStageEffects(stageName, stageData)
    local ped = PlayerPedId()
    if not stageData then return end

    if not isEffectActive then
        saveOriginalWalkstyle()
        isEffectActive = true
    end

    -- Efectos de pantalla
    if stageData.Timecycle then
        SetTimecycleModifier(stageData.Timecycle)
        if stageData.TimecycleStrength then
            SetTimecycleModifierStrength(stageData.TimecycleStrength)
        end
    end

    -- Temblor de cámara
    if stageData.CamShake then
        if not IsGameplayCamShaking() then
            ShakeGameplayCam(stageData.CamShake, stageData.ShakeIntensity or 1.0)
        else
            SetGameplayCamShakeAmplitude(stageData.ShakeIntensity or 1.0)
        end
    end

    -- Físicas y blur
    SetPedIsDrunk(ped, true)
    if stageData.MotionBlur then
        SetPedMotionBlur(ped, true)
    end

    -- Clipset de caminata
    if stageData.WalkStyle then
        setDrunkWalk(stageData.WalkStyle)
    end
end

local function updateDrunkState()
    local cfg = getAlcoholConfig()
    if not cfg or not cfg.Enabled then
        if isEffectActive then
            clearDrunkEffects()
        end
        return
    end

    local stageName, stageData = getStageForLevel(currentAlcohol)

    if stageName ~= currentStage then
        currentStage = stageName
        if stageData then
            applyStageEffects(stageName, stageData)
        else
            clearDrunkEffects()
        end
    end
end

local function startAlcoholLoop()
    if isLoopRunning then return end
    isLoopRunning = true
    lastDecayTime = GetGameTimer()

    CreateThread(function()
        while currentAlcohol > 0 do
            local cfg = getAlcoholConfig()
            if not cfg or not cfg.Enabled then break end

            local now = GetGameTimer()
            local ped = PlayerPedId()

            -- Comprobación de muerte
            if cfg.ResetOnDeath and (IsEntityDead(ped) or GetEntityHealth(ped) <= 0) then
                currentAlcohol = 0
                LocalPlayer.state:set('alcohol', 0, true)
                clearDrunkEffects()
                break
            end

            -- Disminución periódica del alcohol en el tiempo
            local interval = cfg.DecreaseInterval or 12000
            if now - lastDecayTime >= interval then
                lastDecayTime = now
                local decay = cfg.DecreaseAmount or 2
                currentAlcohol = math.max(0, currentAlcohol - decay)
                LocalPlayer.state:set('alcohol', currentAlcohol, true)
                updateDrunkState()
            end

            -- Efectos activos según el estado actual
            local _, stageData = getStageForLevel(currentAlcohol)

            -- Mantener clipset si corresponde y el jugador está a pie
            if stageData and stageData.WalkStyle and not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) then
                setDrunkWalk(stageData.WalkStyle)
            end

            -- Efecto de tropezón al correr/esprintar
            if stageData and stageData.StumbleChance and stageData.StumbleChance > 0 then
                if now - lastStumbleTime > 4000 then
                    if IsPedSprinting(ped) or (IsPedRunning(ped) and currentStage == 'Heavy') then
                        if math.random(1, 100) <= stageData.StumbleChance then
                            lastStumbleTime = now
                            SetPedToRagdoll(ped, 1200, 1500, 0, false, false, false)
                        end
                    end
                end
            end

            -- Efecto de ligero desvío al conducir en estado Heavy
            if stageData and stageData.DriveWobble and IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                    local speed = GetEntitySpeed(veh)
                    if speed > 8.0 and math.random(1, 100) <= 8 then
                        TaskVehicleTempAction(ped, veh, 7, 300)
                    end
                end
            end

            Wait(1000)
        end

        isLoopRunning = false
        if currentAlcohol <= 0 and isEffectActive then
            clearDrunkEffects()
        end
    end)
end

---Añadir nivel de alcohol al personaje
---@param amount number Cantidad de alcohol a sumar
local function addAlcohol(amount)
    local cfg = getAlcoholConfig()
    if not cfg or not cfg.Enabled then return end

    local val = tonumber(amount) or cfg.DefaultAmountPerDrink or 10
    local maxLevel = cfg.MaxLevel or 100
    currentAlcohol = math.min(maxLevel, currentAlcohol + val)

    LocalPlayer.state:set('alcohol', currentAlcohol, true)
    updateDrunkState()

    if Config.Debug then
        print(('[origen_businesses:alcohol] Consumo: +%s. Alcohol actual: %s/%s (Fase: %s)'):format(val, currentAlcohol, maxLevel, currentStage or 'Sobrio'))
    end

    if currentAlcohol > 0 and not isLoopRunning then
        startAlcoholLoop()
    end
end

---Añadir alcohol con protección anti-duplicados (debounce de 4s para evitar dobles tomas por evento y animación)
---@param amount number
local function addAlcoholDebounced(amount)
    local now = GetGameTimer()
    if now - lastDrinkTimer < 4000 then
        return
    end
    lastDrinkTimer = now
    addAlcohol(amount)
end

---Establecer directamente el nivel de alcohol
---@param level number
local function setAlcohol(level)
    local cfg = getAlcoholConfig()
    if not cfg or not cfg.Enabled then return end

    local maxLevel = cfg.MaxLevel or 100
    currentAlcohol = math.max(0, math.min(maxLevel, tonumber(level) or 0))

    LocalPlayer.state:set('alcohol', currentAlcohol, true)
    updateDrunkState()

    if currentAlcohol > 0 and not isLoopRunning then
        startAlcoholLoop()
    elseif currentAlcohol <= 0 and isEffectActive then
        clearDrunkEffects()
    end
end

-- ===============================================
-- EVENTOS
-- ===============================================

-- Evento directo desde el servidor (hook de origen_inventory o export)
RegisterNetEvent('origen_businesses:client:addAlcohol', function(amount)
    addAlcoholDebounced(amount)
end)

RegisterNetEvent('origen_businesses:client:setAlcohol', function(level)
    setAlcohol(level)
end)

RegisterNetEvent('origen_businesses:client:clearAlcohol', function()
    setAlcohol(0)
end)

-- Listener para cuando origen_inventory notifica uso de item en cliente
RegisterNetEvent('inventory:client:ItemBox', function(itemData, actionType)
    if actionType ~= 'used' or not itemData then return end
    local cfg = getAlcoholConfig()
    if not cfg or not cfg.Enabled then return end

    local itemName = tostring(itemData.name or '')
    if itemName == 'bvs_alcohol' or (cfg.Items and cfg.Items[itemName]) then
        local amount = (cfg.Items and cfg.Items[itemName]) or cfg.DefaultAmountPerDrink or 10
        addAlcoholDebounced(amount)
    end
end)

-- Listener para cuando origen_inventory consume un consumible regular
RegisterNetEvent('origenInv:consumables:consumeItem', function(itemInfo)
    if not itemInfo then return end
    local cfg = getAlcoholConfig()
    if not cfg or not cfg.Enabled then return end

    local itemName = tostring(itemInfo.name or '')
    if itemName == 'bvs_alcohol' or (cfg.Items and cfg.Items[itemName]) then
        local amount = (cfg.Items and cfg.Items[itemName]) or cfg.DefaultAmountPerDrink or 10
        addAlcoholDebounced(amount)
    end
end)

-- Listener para eventos estándar de bebidas alcohólicas de frameworks
RegisterNetEvent('origen_inventory:consumables:client:DrinkAlcohol', function(item)
    local cfg = getAlcoholConfig()
    if not cfg or not cfg.Enabled then return end
    local itemName = type(item) == 'string' and item or (item and item.name) or ''
    local amount = (cfg.Items and cfg.Items[itemName]) or cfg.DefaultAmountPerDrink or 10
    addAlcoholDebounced(amount)
end)

RegisterNetEvent('consumables:client:DrinkAlcohol', function(item)
    local cfg = getAlcoholConfig()
    if not cfg or not cfg.Enabled then return end
    local itemName = type(item) == 'string' and item or (item and item.name) or ''
    local amount = (cfg.Items and cfg.Items[itemName]) or cfg.DefaultAmountPerDrink or 10
    addAlcoholDebounced(amount)
end)

-- Compatibilidad previa
RegisterNetEvent('origen_inventory:client:addStatus', function(statusType, value)
    if statusType == 'alcohol' then
        addAlcoholDebounced(value)
    end
end)

RegisterNetEvent('origen_inventory:client:alcoholConsumed', function(value)
    addAlcoholDebounced(value)
end)

-- Limpieza al descargar / detener recurso
AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        if isEffectActive then
            clearDrunkEffects()
        end
    end
end)

-- Sincronizar en reconexión / spawn si ya tenía estado de alcohol
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local saved = LocalPlayer.state.alcohol or 0
    if saved > 0 then
        setAlcohol(saved)
    end
end)

RegisterNetEvent('esx:playerLoaded', function()
    local saved = LocalPlayer.state.alcohol or 0
    if saved > 0 then
        setAlcohol(saved)
    end
end)

-- Función y comando para consultar nivel de alcohol
local function showAlcoholStatus()
    local cfg = getAlcoholConfig()
    local maxLvl = (cfg and cfg.MaxLevel) or 100
    local lightThresh = (cfg and cfg.Stages and cfg.Stages.Light and cfg.Stages.Light.Threshold) or 30
    local stageLabel = 'Sobrio'
    if currentStage == 'Light' then
        stageLabel = 'Levemente ebrio'
    elseif currentStage == 'Medium' then
        stageLabel = 'Ebrio (Moderado)'
    elseif currentStage == 'Heavy' then
        stageLabel = 'Muy ebrio (Fuerte)'
    end

    local text = ('Nivel de alcohol: %s/%s (%s)'):format(currentAlcohol, maxLvl, stageLabel)

    -- 1. Notificación ox_lib
    if lib and lib.notify then
        lib.notify({
            title = 'Alcohol en sangre',
            description = text,
            type = currentAlcohol >= lightThresh and 'warning' or (currentAlcohol > 0 and 'inform' or 'success'),
            position = 'top-right',
            duration = 5000,
        })
    elseif BVSBridge and BVSBridge.bvsNotify then
        BVSBridge.bvsNotify({
            title = 'Alcohol en sangre',
            message = text,
            type = currentAlcohol >= lightThresh and 'warning' or (currentAlcohol > 0 and 'inform' or 'success')
        })
    end

    -- (Antes salia ademas en el chat, repetido: el aviso ya basta.)

    -- 3. Print en consola F8
    bvsDebug(('^3[origen_businesses:alcohol] %s^7'):format(text))
end

RegisterNetEvent('origen_businesses:client:showAlcoholStatus', showAlcoholStatus)

-- ===============================================
-- EXPORTS
-- ===============================================
exports('AddAlcohol', addAlcohol)
exports('SetAlcohol', setAlcohol)
exports('GetAlcohol', function() return currentAlcohol end)
exports('IsDrunk', function()
    local cfg = getAlcoholConfig()
    local thresh = (cfg and cfg.Stages and cfg.Stages.Light and cfg.Stages.Light.Threshold) or 30
    return currentAlcohol >= thresh
end)
exports('ClearAlcohol', function() setAlcohol(0) end)

