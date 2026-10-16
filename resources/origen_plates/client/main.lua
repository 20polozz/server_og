-- ============================================================
-- ORIGEN PLATES - Client
-- ============================================================

local isNuiOpen     = false
local currentVehicle = 0
local currentPlate   = ''
local nitrousCooldownUntil = 0
local startAntilagLoop

local _antilagVeh         = 0      -- handle del vehículo con antilag en esta sesión
local _antilagPlate       = ''     -- matrícula correspondiente
local _antilagLoopRunning = false
local _antilagLastFire    = 0      -- GetGameTimer() del último disparo
local _antilagLastThrottle = false -- ¿acelerador pulsado el tick anterior?
local _antilagLastHighRpm  = false
local _antilagBoneCache    = {}    -- [model] = { boneIndex, ... }

-- Vehículos a los que ya se les comprobó y aplicó el override en esta sesión
-- (evita N queries por cada entrada al mismo vehículo)
-- local checkedVehicles = {}  -- [networkId] = true

-- ── Helpers internos ─────────────────────────────────────────────────────────

local function openCustomUI()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        lib.notify({ title = 'Matrícula', description = 'Debes estar dentro de un vehículo', type = 'error', duration = 4000 })
        return
    end
    currentVehicle = veh
    currentPlate   = GetVehicleNumberPlateText(veh):gsub('%s+', ''):upper()
    SetNuiFocus(true, true)
    isNuiOpen = true
    SendNUIMessage({ action = 'openCustom' })
end

local function openFakeUI()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        lib.notify({ title = 'Matrícula', description = 'Debes estar dentro de un vehículo', type = 'error', duration = 4000 })
        return
    end
    currentVehicle = veh
    currentPlate   = GetVehicleNumberPlateText(veh):gsub('%s+', ''):upper()
    local fakePlate = exports.origen_dealership:GeneratePlate() or 'AAA0000'
    SetNuiFocus(true, true)
    isNuiOpen = true
    SendNUIMessage({ action = 'openFake', plate = fakePlate })
end

local function getNearestVehicle(maxDistance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, maxDistance or 3.0, false)
    if not vehicle or vehicle == 0 then return nil end
    return vehicle
end

-- ── Exports para origen_inventory (client.export en items.lua) ────────────────
exports('UseCustomPlate', openCustomUI)
exports('UseFakePlate',   openFakeUI)

-- ── Eventos de red (fallback / uso desde otros recursos) ─────────────────────
RegisterNetEvent('origen_plates:openCustomPlate', openCustomUI)
RegisterNetEvent('origen_plates:openFakePlate',   openFakeUI)

-- ── NUI: Cerrar UI ────────────────────────────────────────────────────────────
RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    isNuiOpen = false
    cb({})
end)

-- ── NUI: Aplicar matrícula personalizada ──────────────────────────────────────
RegisterNUICallback('applyCustom', function(data, cb)
    if not data or not data.plate or data.plate == '' then
        cb({})
        return
    end

    -- Vehiculo aún existe?
    if not DoesEntityExist(currentVehicle) then
        SendNUIMessage({ action = 'showError', message = 'Ya no estás en el vehículo' })
        cb({})
        return
    end
    
    local result = lib.callback.await('origen_plates:applyCustomPlate', false, {
        originalPlate = currentPlate,
        desiredPlate = data.plate
    })

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    isNuiOpen = false

    if result and result.success then
        SetVehicleNumberPlateText(currentVehicle, result.plate)
        lib.notify({
            title       = 'Matrícula Personalizada',
            description = 'Matrícula actualizada: ' .. result.plate,
            type        = 'success',
            duration    = 5000,
        })
    else
        lib.notify({
            title       = 'Matrícula Personalizada',
            description = (result and result.message) or 'Error al aplicar',
            type        = 'error',
            duration    = 4000,
        })
    end

    cb({})
end)

-- ── NUI: Aplicar matrícula falsa ──────────────────────────────────────────────
RegisterNUICallback('applyFake', function(data, cb)
    if not data or not data.plate or data.plate == '' then
        cb({})
        return
    end

    if not DoesEntityExist(currentVehicle) then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        isNuiOpen = false
        cb({})
        return
    end

    local result = lib.callback.await('origen_plates:applyFakePlate', false, {
        originalPlate = currentPlate,
        fakePlate = data.plate
    })

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    isNuiOpen = false

    if result and result.success then
        local applied, message = exports.qbx_smallresources:setFakePlate(currentVehicle, result.plate)
        if not applied then
            lib.notify({
                title       = 'Matrícula Falsa',
                description = message or 'No se pudo aplicar visualmente',
                type        = 'error',
                duration    = 4000,
            })
            cb({})
            return
        end

        lib.notify({
            title       = 'Matrícula Falsa',
            description = 'Matrícula falsa aplicada: ' .. result.plate,
            type        = 'warning',
            duration    = 5000,
        })
    else
        lib.notify({
            title       = 'Matrícula Falsa',
            description = (result and result.message) or 'Error al aplicar',
            type        = 'error',
            duration    = 4000,
        })
    end

    cb({})
end)

-- ── NUI: Generar nueva matrícula falsa ────────────────────────────────────────
RegisterNUICallback('generateNew', function(_, cb)
    SendNUIMessage({ action = 'newFakePlate', plate = exports.origen_dealership:GeneratePlate() })
    cb({})
end)

-- ── Re-aplicar matrículas falsas al entrar a un vehículo ─────────────────────
-- Cuando el vehículo se spawna desde el garage, tiene la matrícula real.
-- Este thread detecta la entrada al vehículo y consulta si hay una falsa activa.
-- local lastVehicle = 0

-- CreateThread(function()
--     while true do
--         Wait(1000)
--         local ped = PlayerPedId()
--         local veh = GetVehiclePedIsIn(ped, false)

--         if veh ~= 0 and veh ~= lastVehicle then
--             lastVehicle = veh
--             local netId = NetworkGetNetworkIdFromEntity(veh)

--             -- Solo consultar si no se ha procesado ya en esta sesión
--             if not checkedVehicles[netId] then
--                 checkedVehicles[netId] = true  -- marcamos antes para evitar doble query
--                 local plate  = GetVehicleNumberPlateText(veh):gsub('%s+', ''):upper()
--                 local result = lib.callback.await('origen_plates:getPlateOverride', false, { plate = plate })
--                 if result and result.plate then
--                     SetVehicleNumberPlateText(veh, result.plate)
--                 end
--             end
--         elseif veh == 0 then
--             lastVehicle = 0
--         end
--     end
-- end)

-- ============================================================
-- ITEMS RACING
-- ============================================================

-- ── Helpers compartidos ───────────────────────────────────────────────────────

local function getDriverVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return nil end
    -- Solo si es el conductor (asiento -1)
    if GetPedInVehicleSeat(veh, -1) ~= ped then return nil end
    return veh
end

local function setFuelLevel(veh, level)
    if GetResourceState('ps-fuel')        == 'started' then exports['ps-fuel']:SetFuel(veh, level)         return end
    if GetResourceState('LegacyFuel')     == 'started' then exports['LegacyFuel']:SetFuel(veh, level)      return end
    if GetResourceState('LambdentFuelV')  == 'started' then exports['LambdentFuelV']:SetFuel(veh, level)   return end
    if GetResourceState('ox_fuel')        == 'started' then exports['ox_fuel']:SetFuel(veh, level)         return end
    SetVehicleFuelLevel(veh, level)
end

-- ── 1. ÓXIDO NITROSO — hold-to-use, purga manual, efectos nativos ─────────────

-- ─── Estado ───────────────────────────────────────────────────────────────────
local nosMode          = false   -- botella instalada
local nosCharge        = 0.0     -- carga  0–100
local nosTemp          = 0.0     -- purga/calor  0–100
local nosBoostOn       = false   -- boost activo este tick
local nosLocked        = false   -- bloqueado por sobrecalentamiento
local nosKeyHeld       = false   -- tecla boost mantenida
local nosPurgeKeyHeld  = false   -- tecla purga mantenida
local nosScreenFx      = false   -- efectos de pantalla activos
local _nosVehModel     = 0
local _nosVehMaxSpd    = 0.0
-- Handles partículas vapor purga
local _nosSteam        = { left = -1, right = -1 }
-- Persistencia
local _nosVehiclePlate = ''      -- matrícula del vehículo con botella activa
local _nosSaveTick     = 0       -- acumulador para guardado periódico (ms)

-- Normaliza la matrícula (sin espacios, mayúsculas) para usar como clave DB
local function trimPlate(plate)
    return (plate or ''):upper():gsub('%s', '')
end

-- Modelos de vehículos policiales (para detector de radar)
local POLICE_MODELS = {
    'police','police2','police3','police4','policeb','polmav',
    'sheriff','sheriff2','fbi','fbi2','pranger','lguard','riot','riot2',
    'policet','policeold1','policeold2','predator',
}
local POLICE_MODEL_HASHES = {}
for _, m in ipairs(POLICE_MODELS) do
    POLICE_MODEL_HASHES[GetHashKey(m)] = true
end

-- ─── Keybinds ─────────────────────────────────────────────────────────────────
-- Usamos +nos_boost (no +nos) para que el default LSHIFT se aplique limpio.
RegisterCommand('+nos_boost',  function() nosKeyHeld      = true  end, false)
RegisterCommand('-nos_boost',  function() nosKeyHeld      = false end, false)
RegisterCommand('+nos_purge',  function() nosPurgeKeyHeld = true  end, false)
RegisterCommand('-nos_purge',  function() nosPurgeKeyHeld = false end, false)
RegisterKeyMapping('+nos_boost',  'NOS: mantener para activar', 'keyboard', Config.NOS.DefaultKey)
RegisterKeyMapping('+nos_purge',  'NOS: mantener para purgar',  'keyboard', Config.NOS.DefaultPurgeKey)

-- ─── Efectos: llamas del escape ───────────────────────────────────────────────
-- SetVehicleNitroEnabled necesita el asset 'veh_xs_vehicle_mods' cargado para
-- mostrar las llamas reales del tubo de escape (igual que hace ND_Nitro).

local _nosVehXsLoaded = false

local function nosLoadVehXsAsset()
    if _nosVehXsLoaded then return end
    RequestNamedPtfxAsset('veh_xs_vehicle_mods')
    local t = 0
    while not HasNamedPtfxAssetLoaded('veh_xs_vehicle_mods') and t < 2000 do
        Wait(50); t = t + 50
    end
    _nosVehXsLoaded = HasNamedPtfxAssetLoaded('veh_xs_vehicle_mods')
end

local function nosApplyFlames(veh, on)
    if on then
        nosLoadVehXsAsset()
    end
    SetVehicleNitroEnabled(veh, on)
    EnableVehicleExhaustPops(veh, not on)
    SetVehicleBoostActive(veh, on)
    if not on then
        SetVehicleCheatPowerIncrease(veh, 1.0)
        if _nosVehXsLoaded then
            RemoveNamedPtfxAsset('veh_xs_vehicle_mods')
            _nosVehXsLoaded = false
        end
    end
    -- Sincronizar llamas con jugadores cercanos
    if NetworkGetEntityIsNetworked(veh) then
        TriggerServerEvent('origen_plates:broadcastNosVisuals',
            NetworkGetNetworkIdFromEntity(veh), on, false)
    end
end

-- ─── Efectos: vapor de purga en capó/motor ────────────────────────────────────
-- SetVehicleBoostActive(true) durante la purga activa el mismo audio del boost
-- (sonido de presión/soplado) sin aplicar ninguna fuerza extra al vehículo.

local _nosSteamVeh = 0   -- vehículo con vapor activo (para poder pararlo)

local function nosStartSteam(veh)
    SetVehicleBoostActive(veh, true)

    if not DoesParticleFxLoopedExist(_nosSteam.left) then
        _nosSteamVeh = veh

        local bone = GetEntityBoneIndexByName(veh, 'bonnet')
        if bone == -1 then bone = GetEntityBoneIndexByName(veh, 'engine') end
        if bone ~= -1 then
            local wPos   = GetWorldPositionOfEntityBone(veh, bone)
            local offset = GetOffsetFromEntityGivenWorldCoords(veh, wPos.x, wPos.y, wPos.z)

            UseParticleFxAssetNextCall('core')
            _nosSteam.left  = StartParticleFxLoopedOnEntity(
                'ent_sht_steam', veh,
                offset.x - 0.5, offset.y + 0.05, offset.z,
                40.0, -20.0, 0.0,
                0.3, false, false, false
            )
            UseParticleFxAssetNextCall('core')
            _nosSteam.right = StartParticleFxLoopedOnEntity(
                'ent_sht_steam', veh,
                offset.x + 0.5, offset.y + 0.05, offset.z,
                40.0,  20.0, 0.0,
                0.3, false, false, false
            )
        end

        -- Sincronizar vapor con jugadores cercanos
        if NetworkGetEntityIsNetworked(veh) then
            TriggerServerEvent('origen_plates:broadcastNosVisuals',
                NetworkGetNetworkIdFromEntity(veh), false, true)
        end
    end
end

local function nosStopSteam()
    if _nosSteamVeh ~= 0 then
        SetVehicleBoostActive(_nosSteamVeh, false)
        -- Sincronizar parada de vapor con jugadores cercanos
        if NetworkGetEntityIsNetworked(_nosSteamVeh) then
            TriggerServerEvent('origen_plates:broadcastNosVisuals',
                NetworkGetNetworkIdFromEntity(_nosSteamVeh), false, false)
        end
        _nosSteamVeh = 0
    end
    if DoesParticleFxLoopedExist(_nosSteam.left)  then StopParticleFxLooped(_nosSteam.left,  false) end
    if DoesParticleFxLoopedExist(_nosSteam.right) then StopParticleFxLooped(_nosSteam.right, false) end
    _nosSteam.left  = -1
    _nosSteam.right = -1
end

-- ─── Efectos: pantalla basados en velocidad ───────────────────────────────────

local function nosUpdateScreenFx(active, speed)
    local mph = speed * 2.237
    if active and mph > Config.NOS.ScreenFxSpeedMph then
        if not nosScreenFx then
            nosScreenFx = true
            SetTimecycleModifier('rply_motionblur')
            ShakeGameplayCam('SKY_DIVING_SHAKE', 0.25)
        end
    else
        if nosScreenFx then
            nosScreenFx = false
            StopGameplayCamShaking(true)
            SetTransitionTimecycleModifier('default', 0.35)
        end
    end
end

-- ─── Thread de boost por frame (solo mientras el boost está activo) ───────────
-- Usa SetVehicleCheatPowerIncrease con multiplicador dinámico (igual que ND_Nitro)

local function startBoostFrameThread(veh)
    -- Cachear velocidad máxima del modelo una vez
    local model = GetEntityModel(veh)
    if model ~= _nosVehModel then
        _nosVehModel  = model
        _nosVehMaxSpd = math.max(1.0, GetVehicleModelMaxSpeed(model))
    end

    CreateThread(function()
        while nosBoostOn and GetVehiclePedIsIn(PlayerPedId(), false) == veh do
            local speed = GetEntitySpeed(veh)
            local spd   = math.max(1.0, speed)
            local mult  = math.min(Config.NOS.BoostMultBase * _nosVehMaxSpd / spd, Config.NOS.BoostMultCap)
            SetVehicleCheatPowerIncrease(veh, mult)

            -- Asistencia de aceleración a baja velocidad
            if speed * 2.237 < 5.0 then
                SetControlNormal(0, 71, 0.5)
            end

            nosUpdateScreenFx(true, speed)
            Wait(0)
        end
        -- Restablecer potencia al soltar
        SetVehicleCheatPowerIncrease(veh, 1.0)
        nosUpdateScreenFx(false, 0.0)
    end)
end

-- ─── HUD helper ───────────────────────────────────────────────────────────────

--[[ El nitroso, para el minimapa de origen_map: desde el 11/09/2026 el HUD del
     coche va dentro del minimapa (diseño «HUD carplay») y el nitroso es una
     tira en su borde. Solo lectura. ]]
exports('EstadoNitroso', function()
    return {
        instalado = nosMode and true or false,
        carga = nosCharge,
        activo = nosBoostOn and true or false,
        bloqueado = nosLocked and true or false,
    }
end)

--- Si el minimapa ya enseña el nitroso, esta tarjeta no sale encima.
local function MinimapaLoEnsena()
    if GetResourceState('origen_map') ~= 'started' then return false end
    local ok, si = pcall(function() return exports.origen_map:HudDelCoche() end)
    return ok and si == true
end

local function sendNosHud(visible)
    if visible and MinimapaLoEnsena() then visible = false end
    local state
    if nosCharge <= 0 then                      state = 'empty'
    elseif nosBoostOn then                      state = 'active'
    elseif nosLocked then                       state = 'locked'
    elseif nosPurgeKeyHeld and nosTemp > 0 then state = 'venting'
    else                                        state = 'ready'
    end
    SendNUIMessage({
        action      = 'setNosHud',
        visible     = visible,
        charge      = nosCharge,
        temperature = nosTemp,
        state       = state,
    })
end

-- ─── Thread principal (100 ms) ────────────────────────────────────────────────

local function startNosThread()
    _nosSaveTick = 0
    CreateThread(function()
        while nosMode do
            Wait(100)

            local veh      = GetVehiclePedIsIn(PlayerPedId(), false)
            local canBoost = nosKeyHeld and not nosLocked and nosCharge > 0 and veh ~= 0

            -- ── JUGADOR SALIÓ DEL VEHÍCULO → guardar carga y pausar ───────────
            if veh == 0 then
                if nosBoostOn then
                    nosBoostOn = false
                end
                nosStopSteam()
                if _nosVehiclePlate ~= '' then
                    TriggerServerEvent('origen_plates:saveNOSChargeEvent', _nosVehiclePlate, nosCharge)
                end
                nosMode = false
                sendNosHud(false)
                return
            end

            -- ── GUARDADO PERIÓDICO cada 5 seg ─────────────────────────────────
            _nosSaveTick = _nosSaveTick + 100
            if _nosSaveTick >= 5000 then
                _nosSaveTick = 0
                if _nosVehiclePlate ~= '' and nosCharge > 0 then
                    TriggerServerEvent('origen_plates:saveNOSChargeEvent', _nosVehiclePlate, nosCharge)
                end
            end

            -- ── BOOST activo ──────────────────────────────────────────────────
            if canBoost then
                nosCharge = math.max(0.0, nosCharge - Config.NOS.DrainPerTick)
                nosTemp   = math.min(Config.NOS.MaxTemp, nosTemp + Config.NOS.HeatPerTick)

                if not nosBoostOn then
                    nosBoostOn = true
                    nosStopSteam()           -- apagar vapor si estaba
                    nosApplyFlames(veh, true)
                    startBoostFrameThread(veh)
                end

            -- ── BOOST inactivo ────────────────────────────────────────────────
            else
                if nosBoostOn then
                    nosBoostOn = false
                    if veh ~= 0 then nosApplyFlames(veh, false) end
                end

                -- ── PURGA MANUAL (LMENU mantenido) ────────────────────────────
                if nosPurgeKeyHeld and nosTemp > 0 and veh ~= 0 then
                    nosStartSteam(veh)
                    if nosTemp > 0 then
                        nosTemp = math.max(0.0, nosTemp - Config.NOS.PurgeDrainPerTick)
                        -- Desbloquear NOS cuando el medidor baje de la zona peligrosa
                        if nosLocked and nosTemp < Config.NOS.MaxTemp then
                            nosLocked = false
                        end
                    else
                        -- Medidor ya en 0: quemar NOS directamente al purgar
                        nosCharge = math.max(0.0, nosCharge - Config.NOS.PurgeNosdrainPerTick)
                    end
                else
                    -- Sin enfriamiento pasivo: la purga solo baja al purgar manualmente
                    nosStopSteam()
                end
            end

            -- ── SOBRECALENTAMIENTO → bloqueo ──────────────────────────────────
            if nosTemp >= Config.NOS.MaxTemp and not nosLocked then
                nosLocked  = true
                nosBoostOn = false
                if veh ~= 0 then nosApplyFlames(veh, false) end
                lib.notify({
                    title       = 'NOS — Sobrecalentamiento',
                    description = ('Mantén [%s] para purgar el sistema'):format(Config.NOS.DefaultPurgeKey),
                    type        = 'error',
                    duration    = 5000,
                })
            end

            -- ── BOTELLA VACÍA → eliminar de DB ────────────────────────────────
            if nosCharge <= 0 then
                nosMode    = false
                nosBoostOn = false
                nosLocked  = false
                if veh ~= 0 then nosApplyFlames(veh, false) end
                nosStopSteam()
                if _nosVehiclePlate ~= '' then
                    TriggerServerEvent('origen_plates:saveNOSChargeEvent', _nosVehiclePlate, 0)
                    _nosVehiclePlate = ''
                end
                lib.notify({ title = 'NOS', description = 'Botella vacía', type = 'inform', duration = 3000 })
                sendNosHud(false)
                return
            end

            sendNosHud(true)
        end

        -- Limpieza si nosMode fue forzado a false
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then nosApplyFlames(veh, false) end
        nosStopSteam()
        sendNosHud(false)
    end)
end

-- ─── Activar botella ──────────────────────────────────────────────────────────

local function useNitrous()
    local now = GetGameTimer()
    if now < nitrousCooldownUntil then
        local left = math.max(1, math.ceil((nitrousCooldownUntil - now) / 1000))
        lib.notify({
            title = 'NOS',
            description = ('Espera %ss para volver a usarlo'):format(left),
            type = 'warning',
            duration = 2500
        })
        return
    end

    if nosMode then
        lib.notify({ title = 'NOS', description = 'Ya hay una botella activa', type = 'warning', duration = 2000 })
        return
    end

    local ped = PlayerPedId()

    -- Exigir estar fuera del vehículo
    if IsPedInAnyVehicle(ped, false) then
        lib.notify({
            title = 'NOS',
            description = 'Debes estar fuera del vehículo para instalar el nitro',
            type = 'error',
            duration = 3000
        })
        return
    end

    local veh = getNearestVehicle(3.0)
    if not veh then
        lib.notify({
            title = 'NOS',
            description = 'Debes estar cerca de un vehículo',
            type = 'error',
            duration = 3000
        })
        return
    end

    -- Comprobar si está en la zona del capó (bonnet)
    local bonnetBone = GetEntityBoneIndexByName(veh, 'bonnet')
    local bonnetPos
    if bonnetBone ~= -1 then
        bonnetPos = GetWorldPositionOfEntityBone(veh, bonnetBone)
    else
        local engineBone = GetEntityBoneIndexByName(veh, 'engine')
        if engineBone ~= -1 then
            bonnetPos = GetWorldPositionOfEntityBone(veh, engineBone)
        else
            -- Fallback si no tiene huesos específicos (2.0 metros al frente del vehículo)
            bonnetPos = GetOffsetFromEntityInWorldCoords(veh, 0.0, 2.0, 0.0)
        end
    end

    local playerCoords = GetEntityCoords(ped)
    local dist = #(playerCoords - bonnetPos)
    if dist > 2.0 then
        lib.notify({
            title = 'NOS',
            description = 'Debes estar en la zona del capó del vehículo',
            type = 'error',
            duration = 3000
        })
        return
    end

    -- Levantar el capó (puerta index 4)
    SetVehicleDoorOpen(veh, 4, false, false)

    -- Barra de progreso de 10 segundos
    local finished = lib.progressBar({
        duration = 10000,
        label = 'Colocando nitro en el motor...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
    })

    -- Bajar el capó
    SetVehicleDoorShut(veh, 4, false)

    if not finished then
        lib.notify({
            title = 'NOS',
            description = 'Instalación cancelada',
            type = 'error',
            duration = 3000
        })
        return
    end

    -- Consumir el item racing
    local ok = lib.callback.await('origen_plates:consumeRacingItem', false, 'oxido_nitroso')
    if not ok then
        lib.notify({
            title = 'NOS',
            description = 'No tienes óxido nitroso',
            type = 'error',
            duration = 3000
        })
        return
    end

    nitrousCooldownUntil = GetGameTimer() + 10000

    -- Guardar carga (owned / temporary)
    local plate = trimPlate(GetVehicleNumberPlateText(veh))
    local okSave, isOwned = lib.callback.await('origen_plates:saveNOSCharge', false, plate, Config.NOS.MaxCharge)

    _nosVehiclePlate = plate

    if isOwned then
        lib.notify({
            title = 'Nitrous Oxide',
            description = 'Botella instalada en el motor',
            type = 'success',
            duration = 4500
        })
    else
        lib.notify({
            title = 'Nitrous Oxide',
            description = 'Botella instalada en el motor (vehículo ajeno)',
            type = 'warning',
            duration = 4500
        })
    end
end

exports('UseNitrous', useNitrous)
RegisterNetEvent('origen_plates:useNitrous', useNitrous)

-- ─── Restaurar NOS al entrar a un vehículo ────────────────────────────────────
-- Si el coche tiene una botella guardada en DB, la retoma automáticamente.
-- Solo actúa cuando el jugador es el conductor y no tiene NOS activo.

local _lastNosCheckVeh = 0
local _hasCheckedCurrentVeh = false
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 then
            if veh ~= _lastNosCheckVeh then
                _lastNosCheckVeh = veh
                _hasCheckedCurrentVeh = false
            end

            -- Solo actúa si el jugador es el conductor y no hemos comprobado este vehículo aún
            if not _hasCheckedCurrentVeh and GetPedInVehicleSeat(veh, -1) == ped then
                _hasCheckedCurrentVeh = true
                Wait(600)   -- dejar que el vehículo se inicialice del todo
                local plate = trimPlate(GetVehicleNumberPlateText(veh))

                -- ── Restaurar NOS ──────────────────────────────────────────
                if not nosMode then
                    local charge = lib.callback.await('origen_plates:getNOSCharge', false, plate)
                    if charge and charge > 0 then
                        _nosVehiclePlate = plate
                        nosMode    = true
                        nosCharge  = charge
                        nosTemp    = 0.0
                        nosLocked  = false
                        nosBoostOn = false
                        lib.notify({
                            title       = 'Nitrous Oxide',
                            description = ('Botella activa — %d%% carga restante · [%s] boost'):format(math.floor(charge + 0.5), Config.NOS.DefaultKey),
                            type        = 'inform',
                            duration    = 4000,
                        })
                        sendNosHud(true)
                        startNosThread()
                    end
                end

                -- ── Restaurar Antilag ──────────────────────────────────────
                if _antilagVeh == 0 or _antilagPlate ~= plate then
                    local hasAntilag = lib.callback.await('origen_plates:getAntilagState', false, plate)
                    if hasAntilag then
                        _antilagVeh   = veh
                        _antilagPlate = plate
                        lib.notify({
                            title       = 'Antilag',
                            description = 'Antilag activo en este vehículo',
                            type        = 'inform',
                            duration    = 4000,
                        })
                        startAntilagLoop()
                    end
                end
            end

        elseif veh == 0 then
            _lastNosCheckVeh = 0
            _hasCheckedCurrentVeh = false
        end
    end
end)

-- ── 2. KIT DE REPARACIÓN RÁPIDA ──────────────────────────────────────────────

local function useRepairKit()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        lib.notify({ title = 'Reparación', description = 'Debes estar dentro de un vehículo', type = 'error', duration = 3000 })
        return
    end

    -- Comprobar item antes de iniciar la animación
    local ok = lib.callback.await('origen_plates:consumeRacingItem', false, 'kit_reparacion')
    if not ok then
        lib.notify({ title = 'Reparación', description = 'No tienes un kit de reparación', type = 'error', duration = 3000 })
        return
    end

    -- Salir del vehículo y reparar con barra de progreso
    local repaired = lib.progressBar({
        duration    = 4000,
        label       = 'Reparando vehículo...',
        useWhileDead = false,
        canCancel   = false,
        disable     = { car = true, move = true },
        anim        = { dict = 'mini@repair', clip = 'fixing_a_ped' },
    })

    if repaired then
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehiclePetrolTankHealth(veh, 1000.0)
        SetVehicleDeformationFixed(veh)
        SetVehicleFixed(veh)

        lib.notify({ title = 'Reparación', description = 'Vehículo reparado al 100%', type = 'success', duration = 4000 })
    end
end

exports('UseRepairKit', useRepairKit)
RegisterNetEvent('origen_plates:useRepairKit', useRepairKit)

-- ── 3. BIDÓN DE COMBUSTIBLE ───────────────────────────────────────────────────

local function useFuelCan()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        lib.notify({ title = 'Combustible', description = 'Debes estar dentro de un vehículo', type = 'error', duration = 3000 })
        return
    end

    local ok = lib.callback.await('origen_plates:consumeRacingItem', false, 'bidon_combustible')
    if not ok then
        lib.notify({ title = 'Combustible', description = 'No tienes un bidón de combustible', type = 'error', duration = 3000 })
        return
    end

    local refueled = lib.progressBar({
        duration     = 5000,
        label        = 'Rellenando depósito...',
        useWhileDead = false,
        canCancel    = false,
        disable      = { car = true, move = true },
        anim         = { dict = 'weapon@w_sp_jerrycan', clip = 'fire' },
    })

    if refueled then
        setFuelLevel(veh, 100.0)
        lib.notify({ title = 'Combustible', description = 'Depósito lleno', type = 'success', duration = 4000 })
    end
end

exports('UseFuelCan', useFuelCan)
RegisterNetEvent('origen_plates:useFuelCan', useFuelCan)

-- ── 4. DETECTOR DE RADAR ──────────────────────────────────────────────────────

local radarDetectorActive = false

local function useRadarDetector()
    if radarDetectorActive then
        lib.notify({ title = 'Detector', description = 'El detector ya está activo', type = 'warning', duration = 2000 })
        return
    end

    local ok = lib.callback.await('origen_plates:consumeRacingItem', false, 'detector_radar')
    if not ok then
        lib.notify({ title = 'Detector de Radar', description = 'No tienes un detector de radar', type = 'error', duration = 3000 })
        return
    end

    radarDetectorActive = true
    lib.notify({
        title       = 'Detector de Radar',
        description = 'Activado — te alertará cuando haya policía cerca (10 min)',
        type        = 'success',
        duration    = 6000,
    })

    CreateThread(function()
        local expiryTime  = GetGameTimer() + 600000   -- 10 minutos
        local lastAlert   = 0
        local alertCooldown = 12000   -- ms entre alertas para no spamear

        while GetGameTimer() < expiryTime and radarDetectorActive do
            Wait(3000)

            local playerCoords = GetEntityCoords(PlayerPedId())
            local copNearby    = false
            local copDist      = 9999.0

            -- Escanear jugadores cercanos con vehículo policial
            for _, pId in ipairs(GetActivePlayers()) do
                if pId ~= PlayerId() then
                    local copPed  = GetPlayerPed(pId)
                    local copVeh  = GetVehiclePedIsIn(copPed, false)
                    if DoesEntityExist(copPed) and copVeh ~= 0 then
                        local d = #(playerCoords - GetEntityCoords(copPed))
                        if d < 200.0 and POLICE_MODEL_HASHES[GetEntityModel(copVeh)] then
                            copNearby = true
                            if d < copDist then copDist = d end
                        end
                    end
                end
            end

            -- Escanear NPCs policiales cercanos
            if not copNearby then
                local peds = GetGamePool('CPed')
                for _, npcPed in ipairs(peds) do
                    if DoesEntityExist(npcPed) and not IsPedAPlayer(npcPed) then
                        local npcVeh = GetVehiclePedIsIn(npcPed, false)
                        if npcVeh ~= 0 then
                            local d = #(playerCoords - GetEntityCoords(npcPed))
                            if d < 150.0 and POLICE_MODEL_HASHES[GetEntityModel(npcVeh)] then
                                copNearby = true
                                if d < copDist then copDist = d end
                            end
                        end
                    end
                end
            end

            -- Alertar si hay policía y ha pasado suficiente tiempo desde la última alerta
            if copNearby and GetGameTimer() - lastAlert > alertCooldown then
                lastAlert = GetGameTimer()
                local distLabel = math.floor(copDist) .. 'm'
                PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
                lib.notify({
                    title       = 'Detector',
                    description = 'Vehículo policial a ' .. distLabel,
                    type        = 'error',
                    duration    = 5000,
                })
            end
        end

        radarDetectorActive = false
        lib.notify({ title = 'Detector', description = 'Batería agotada', type = 'inform', duration = 4000 })
    end)
end

exports('UseRadarDetector', useRadarDetector)
RegisterNetEvent('origen_plates:useRadarDetector', useRadarDetector)

-- ── 5. ANTILAG ────────────────────────────────────────────────────────────────
-- Instala un sistema de backfire (explosiones de escape) automático en el coche.
-- Se activa en modo "liftoff": al soltar el acelerador a RPM y velocidad altas.
-- Persiste en DB para vehículos propios (igual que el NOS).
-- Sincronizado: otros jugadores ven y escuchan las explosiones.



-- Configuración (extraída de la auditoría del script de referencia)
local ANTILAG_PTFX        = 'core'
local ANTILAG_FX_NAMES    = { 'veh_backfire', 'veh_exhaust_flame' }
local ANTILAG_FX_SCALE    = 2.0
local ANTILAG_BONES       = {
    'exhaust','exhaust_2','exhaust_3','exhaust_4',
    'exhaust_5','exhaust_6','exhaust_7','exhaust_8',
}
local ANTILAG_COOLDOWN    = 700   -- ms mínimos entre ráfagas
local ANTILAG_BURST       = 4     -- disparos por ráfaga
local ANTILAG_BURST_DELAY = 55    -- ms entre disparos
local ANTILAG_MIN_RPM     = 0.72  -- RPM mínima para disparar (0–1)
local ANTILAG_MIN_SPEED   = 1.0   -- velocidad mínima m/s

-- Sonido: AddExplosion para reproducir el petardeo del escape
local function antilagPlaySound(veh)
    if Config.Antilag and not Config.Antilag.PlaySound then return end
    local pos = GetEntityCoords(veh or GetVehiclePedIsIn(PlayerPedId(), false))
    local expType = (Config.Antilag and Config.Antilag.ExplosionType) or 61

    -- Truco de atenuación: la explosión es invisible, por lo que desplazarla verticalmente
    -- hacia abajo aumenta la distancia de la fuente del sonido, reduciendo su volumen de forma natural.
    local volume = (Config.Antilag and Config.Antilag.Volume) or 1.0
    local offsetZ = 0.0
    if volume < 1.0 then
        -- Mapear volumen de 0.0 a 1.0 a un desfase de -25.0 a 0.0 metros
        offsetZ = -25.0 * (1.0 - volume)
    end

    AddExplosion(pos.x, pos.y, pos.z + offsetZ, expType, 0.0, true, true, 0.0, true)
end

local function antilagGetBones(veh)
    local model = GetEntityModel(veh)
    if _antilagBoneCache[model] then return _antilagBoneCache[model] end
    local bones = {}
    for _, boneName in ipairs(ANTILAG_BONES) do
        local idx = GetEntityBoneIndexByName(veh, boneName)
        if idx ~= -1 then bones[#bones + 1] = idx end
    end
    _antilagBoneCache[model] = bones
    return bones
end

-- Dispara partículas de backfire en una entidad (local o remota).
-- Técnica yorick: StartParticleFxLooped + StopParticleFxLooped(handle, true)
-- El flash inicial del looped es mucho más grande que el NonLooped.
-- NO se llama a RequestNamedPtfxAsset para 'core' porque siempre está disponible.
local function antilagSpawnFx(entity, bones)
    local fxName = ANTILAG_FX_NAMES[1]
    if #bones > 0 then
        for _, boneIdx in ipairs(bones) do
            UseParticleFxAssetNextCall(ANTILAG_PTFX)
            local handle = StartParticleFxLoopedOnEntityBone(
                fxName, entity,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                boneIdx, ANTILAG_FX_SCALE,
                false, false, false
            )
            if handle and handle ~= -1 then
                StopParticleFxLooped(handle, true)
            end
        end
    else
        UseParticleFxAssetNextCall(ANTILAG_PTFX)
        local handle = StartParticleFxLoopedOnEntity(
            fxName, entity,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            ANTILAG_FX_SCALE,
            false, false, false
        )
        if handle and handle ~= -1 then
            StopParticleFxLooped(handle, true)
        end
    end
end

-- Dispara una ráfaga de backfires en el vehículo dado (local + broadcast)
local function antilagFireBurst(veh)
    local bones = antilagGetBones(veh)

    -- Pico de presión del turbo (efecto yorick)
    SetVehicleTurboPressure(veh, 25.0)

    CreateThread(function()
        for i = 1, ANTILAG_BURST do
            antilagSpawnFx(veh, bones)
            antilagPlaySound(veh)
            if i < ANTILAG_BURST then Wait(math.random(35, ANTILAG_BURST_DELAY)) end
        end
    end)

    -- Sincronizar con jugadores cercanos
    if NetworkGetEntityIsNetworked(veh) then
        TriggerServerEvent('origen_plates:broadcastAntilagPop',
            NetworkGetNetworkIdFromEntity(veh))
    end
end

function startAntilagLoop()
    if _antilagLoopRunning then return end
    _antilagLoopRunning  = true
    _antilagLastThrottle = false
    _antilagLastHighRpm  = false
    _antilagLastFire     = 0

    CreateThread(function()
        while _antilagVeh ~= 0 do
            Wait(0)
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)

            if veh == 0 or veh ~= _antilagVeh then
                _antilagVeh = 0
                _antilagPlate = ''
                break
            end

            if GetPedInVehicleSeat(veh, -1) ~= ped then
                Wait(500)
                goto continueAntilag
            end

            do
                local throttleVal  = GetControlNormal(0, 71)  -- INPUT_VEH_ACCELERATE
                local brakeVal     = GetControlNormal(0, 72)  -- INPUT_VEH_BRAKE
                local twoStepKey   = IsControlPressed(0, 21)  -- LEFT SHIFT (igual que qb-antilag)
                local throttleOn   = throttleVal > 0.15
                local brakeOn      = brakeVal    > 0.15
                local rpm          = GetVehicleCurrentRpm(veh)
                local speed        = GetEntitySpeed(veh)
                local inAir        = IsEntityInAir(veh)
                local now          = GetGameTimer()
                local cooldownOk   = (now - _antilagLastFire) > ANTILAG_COOLDOWN

                -- ── MODO 2-STEP (SHIFT + acelerador, RPM 0.3–0.5) ─────────────────
                -- Simula borboteo en ralentí alto / launch control.
                -- Dispara CONTINUAMENTE mientras se mantiene SHIFT con gas.
                if twoStepKey and throttleOn and not inAir
                    and rpm > 0.28 and rpm < 0.55 and cooldownOk
                then
                    _antilagLastFire = now
                    antilagFireBurst(veh)

                -- ── MODO ANTILAG NORMAL (decelerar a RPM alta sin freno) ───────────
                -- Dispara mientras no hay gas ni freno y el motor sigue alto.
                -- Cubre tanto el liftoff puntual como la deceleración prolongada.
                elseif not throttleOn and not brakeOn and not twoStepKey
                    and not inAir and speed > ANTILAG_MIN_SPEED
                    and rpm > ANTILAG_MIN_RPM and cooldownOk
                then
                    _antilagLastFire = now
                    antilagFireBurst(veh)
                end

                _antilagLastThrottle = throttleOn
                _antilagLastHighRpm  = rpm > ANTILAG_MIN_RPM
            end

            ::continueAntilag::
        end
        _antilagLoopRunning = false
    end)
end

local function useAntilag()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        lib.notify({ title = 'Antilag', description = 'Debes estar dentro de un vehículo', type = 'error', duration = 3000 })
        return
    end
    if GetPedInVehicleSeat(veh, -1) ~= ped then
        lib.notify({ title = 'Antilag', description = 'Debes ser el conductor', type = 'error', duration = 3000 })
        return
    end

    local plate = trimPlate(GetVehicleNumberPlateText(veh))

    -- Toggle OFF: antilag ya activo en este vehículo
    if _antilagVeh == veh then
        _antilagVeh   = 0
        _antilagPlate = ''
        TriggerServerEvent('origen_plates:removeAntilag', plate)
        lib.notify({ title = 'Antilag', description = 'Antilag desinstalado', type = 'inform', duration = 3000 })
        return
    end

    -- Toggle ON: instalar (consume item en servidor)
    local result = lib.callback.await('origen_plates:installAntilag', false, plate)
    if not result then return end
    if result.err == 'no_item' then
        lib.notify({ title = 'Antilag', description = 'No tienes un kit de antilag', type = 'error', duration = 3000 })
        return
    end
    if result.err then return end

    _antilagVeh   = veh
    _antilagPlate = plate

    if result.owned then
        lib.notify({ title = 'Antilag', description = 'Instalado — backfire al decelerar | SHIFT+gas para 2-Step', type = 'success', duration = 6000 })
    else
        lib.notify({ title = 'Antilag', description = 'Instalado (vehículo ajeno) — backfire al decelerar | SHIFT+gas para 2-Step', type = 'warning', duration = 6000 })
    end
    startAntilagLoop()
end

exports('UseAntilag', useAntilag)
RegisterNetEvent('origen_plates:useAntilag', useAntilag)

local function useRemoveAntilag()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        lib.notify({ title = 'Antilag', description = 'Debes estar dentro de un vehículo', type = 'error', duration = 3000 })
        return
    end
    if GetPedInVehicleSeat(veh, -1) ~= ped then
        lib.notify({ title = 'Antilag', description = 'Debes ser el conductor', type = 'error', duration = 3000 })
        return
    end

    local plate = trimPlate(GetVehicleNumberPlateText(veh))

    -- Comprobar si tiene antilag
    local hasAntilag = lib.callback.await('origen_plates:getAntilagState', false, plate)
    if not hasAntilag then
        lib.notify({ title = 'Antilag', description = 'Este vehículo no tiene antilag instalado', type = 'error', duration = 3000 })
        return
    end

    -- Barra de progreso
    local finished = lib.progressBar({
        duration = 5000,
        label = 'Desinstalando sistema de antilag...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
    })

    if not finished then
        lib.notify({ title = 'Antilag', description = 'Desinstalación cancelada', type = 'error', duration = 3000 })
        return
    end

    -- Llamar al servidor para quitar y consumir
    local result = lib.callback.await('origen_plates:removeAntilagWithItem', false, plate)
    if not result or result.err == 'no_item' then
        lib.notify({ title = 'Antilag', description = 'No tienes el kit desinstalador de antilag', type = 'error', duration = 3000 })
        return
    end

    if result.ok then
        -- Limpiar estado local
        if _antilagVeh == veh then
            _antilagVeh   = 0
            _antilagPlate = ''
        end
        lib.notify({ title = 'Antilag', description = 'Sistema de antilag retirado con éxito', type = 'success', duration = 4000 })
    end
end

exports('UseRemoveAntilag', useRemoveAntilag)
RegisterNetEvent('origen_plates:useRemoveAntilag', useRemoveAntilag)

local function useScrewdriver()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        lib.notify({ title = 'Destornillador', description = 'Debes estar fuera del vehículo', type = 'error', duration = 3000 })
        return
    end

    local vehicle = getNearestVehicle(3.0)
    if not vehicle then
        lib.notify({ title = 'Destornillador', description = 'No hay ningún vehículo cerca', type = 'error', duration = 3000 })
        return
    end

    local success = lib.progressBar({
        duration = 5000,
        label = 'Retirando matrícula...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
    })

    if not success then
        lib.notify({ title = 'Destornillador', description = 'Acción cancelada', type = 'error', duration = 2500 })
        return
    end

    local current = trimPlate(GetVehicleNumberPlateText(vehicle))
    local result, message = exports.qbx_smallresources:setFakePlate(vehicle, nil)
    if not result then
        lib.notify({ title = 'Destornillador', description = message or 'No hay matrícula falsa aplicada', type = 'error', duration = 3500 })
        return
    end

    TriggerServerEvent('origen_plates:clearFakePlateByCurrent', current)
    lib.notify({ title = 'Destornillador', description = 'Matrícula falsa retirada', type = 'success', duration = 3500 })
end

exports('UseScrewdriver', useScrewdriver)

-- ── Cleanup al parar el recurso ───────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if isNuiOpen then SetNuiFocus(false, false) end
    radarDetectorActive = false

    -- Guardar carga NOS antes de parar (fire-and-forget)
    if nosMode and _nosVehiclePlate ~= '' and nosCharge > 0 then
        TriggerServerEvent('origen_plates:saveNOSChargeEvent', _nosVehiclePlate, nosCharge)
    end

    -- Limpiar estado NOS
    nosMode          = false
    nosBoostOn       = false
    nosLocked        = false
    nosKeyHeld       = false
    nosPurgeKeyHeld  = false
    _nosVehiclePlate = ''
    nosStopSteam()
    nosUpdateScreenFx(false, 0.0)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        SetVehicleNitroEnabled(veh, false)
        EnableVehicleExhaustPops(veh, true)
        SetVehicleBoostActive(veh, false)
        SetVehicleCheatPowerIncrease(veh, 1.0)
    end
    if _nosVehXsLoaded then
        RemoveNamedPtfxAsset('veh_xs_vehicle_mods')
        _nosVehXsLoaded = false
    end

    -- Limpiar estado Antilag
    _antilagVeh   = 0
    _antilagPlate = ''
end)

-- ── Backfires remotos (jugadores cercanos ven/escuchan el antilag ajeno) ──────
RegisterNetEvent('origen_plates:applyRemoteAntilagPop', function(senderSrc, netId)
    if GetPlayerServerId(PlayerId()) == senderSrc then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or not DoesEntityExist(entity) then return end

    local bones = antilagGetBones(entity)
    CreateThread(function()
        for i = 1, ANTILAG_BURST do
            antilagSpawnFx(entity, bones)
            antilagPlaySound(entity)
            if i < ANTILAG_BURST then Wait(math.random(35, ANTILAG_BURST_DELAY)) end
        end
    end)
end)

-- ── Efectos NOS remotos (jugadores cercanos ven/escuchan el NOS ajeno) ────────
-- Tabla de efectos remotos activos por entidad (para limpiarlos si se van)
local _remoteNos = {}   -- [entityHandle] = { flames=bool, steam={ left, right } }

RegisterNetEvent('origen_plates:applyRemoteNosVisuals', function(senderSrc, netId, flamesOn, purgeOn)
    -- El conductor ya aplicó sus efectos localmente
    if GetPlayerServerId(PlayerId()) == senderSrc then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or not DoesEntityExist(entity) then return end

    if not _remoteNos[entity] then
        _remoteNos[entity] = { flames = false, steam = nil }
    end
    local st = _remoteNos[entity]

    -- ── Llamas del escape ────────────────────────────────────────────────────
    if flamesOn ~= st.flames then
        st.flames = flamesOn
        SetVehicleNitroEnabled(entity, flamesOn)
        EnableVehicleExhaustPops(entity, not flamesOn)
        SetVehicleBoostActive(entity, flamesOn)
    end

    -- ── Vapor de purga ───────────────────────────────────────────────────────
    if purgeOn and not st.steam then
        -- Iniciar sonido de purga en el vehículo remoto
        SetVehicleBoostActive(entity, true)

        local bone = GetEntityBoneIndexByName(entity, 'bonnet')
        if bone == -1 then bone = GetEntityBoneIndexByName(entity, 'engine') end
        if bone ~= -1 then
            local wPos   = GetWorldPositionOfEntityBone(entity, bone)
            local offset = GetOffsetFromEntityGivenWorldCoords(entity, wPos.x, wPos.y, wPos.z)
            UseParticleFxAssetNextCall('core')
            local left  = StartParticleFxLoopedOnEntity(
                'ent_sht_steam', entity,
                offset.x - 0.5, offset.y + 0.05, offset.z,
                40.0, -20.0, 0.0, 0.3, false, false, false
            )
            UseParticleFxAssetNextCall('core')
            local right = StartParticleFxLoopedOnEntity(
                'ent_sht_steam', entity,
                offset.x + 0.5, offset.y + 0.05, offset.z,
                40.0,  20.0, 0.0, 0.3, false, false, false
            )
            st.steam = { left = left, right = right }
        end
    elseif not purgeOn and st.steam then
        -- Parar sonido y partículas de purga
        SetVehicleBoostActive(entity, false)
        local h = st.steam
        if DoesParticleFxLoopedExist(h.left)  then StopParticleFxLooped(h.left,  false) end
        if DoesParticleFxLoopedExist(h.right) then StopParticleFxLooped(h.right, false) end
        st.steam = nil
    end
end)

-- Limpiar efectos remotos al parar el recurso
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for entity, st in pairs(_remoteNos) do
        SetVehicleNitroEnabled(entity, false)
        EnableVehicleExhaustPops(entity, true)
        SetVehicleBoostActive(entity, false)
        if st.steam then
            if DoesParticleFxLoopedExist(st.steam.left)  then StopParticleFxLooped(st.steam.left,  false) end
            if DoesParticleFxLoopedExist(st.steam.right) then StopParticleFxLooped(st.steam.right, false) end
        end
    end
    _remoteNos = {}
end)
