-- ========================================
-- CLIENT: MAIN - ORIGEN VEHICLE CLASSES
-- ========================================

---Calcula el Performance Index (PI) de un vehículo basándose en su handling real
---@param vehicle number Identificador de la entidad vehículo
---@return number PI redondeado
function GetVehiclePI(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return 0 end

    -- 1. MOTOR Y VELOCIDAD (Potencia bruta)
    local topSpeed = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel') -- m/s
    local acceleration = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce')
    local inertia = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveInertia')
    local shiftRate = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScale')

    -- 2. TRACCIÓN Y GIRO (Agilidad)
    local tractionMax = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax')
    local tractionMin = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin')
    local steerLock = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSteeringLock')
    local tractionBias = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionBiasFront')

    -- 3. FRENADA Y PESO (Control y masa)
    local braking = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce')
    local mass = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fMass')
    local drag = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDragCoeff')

    -- CÁLCULO DE SUB-SCORES NORMALIZADOS
    -- Velocidad: m/s a km/h normalizado (300 km/h como base alta)
    local scoreSpeed = (topSpeed * 3.6) / 0.6
    
    -- Aceleración: Fuerza inicial multiplicada por factores de respuesta
    local scoreAccel = (acceleration * 1200) + (inertia * 150) + (shiftRate * 20)
    
    -- Manejo: Tracción y giro compensado por el peso y aerodinámica
    local scoreHandling = ((tractionMax + tractionMin) * 200) + (steerLock * 5) - (drag * 20)
    
    -- Frenada: Potencia de frenado corregida por la masa
    local scoreBraking = (braking * 1000) - (mass / 200)

    -- AJUSTE POR MASA (Un coche muy pesado acelera peor, pero tiene inercia)
    local massPenalty = (mass / 1000) * 10 

    -- CÁLCULO FINAL (PI)
    local pi = (scoreSpeed * Config.PIFactors.topSpeed) + 
               (scoreAccel * Config.PIFactors.acceleration) + 
               (scoreHandling * Config.PIFactors.traction) + 
               (scoreBraking * Config.PIFactors.braking) - massPenalty

    -- Bonus por Tuneado de Rendimiento (Mantenemos el bonus por mods instalados)
    local tuningBonus = 0
    local engineMod = GetVehicleMod(vehicle, 11)
    if engineMod >= 0 then tuningBonus = tuningBonus + (engineMod + 1) * 20 end
    local brakesMod = GetVehicleMod(vehicle, 12)
    if brakesMod >= 0 then tuningBonus = tuningBonus + (brakesMod + 1) * 12 end
    local transMod = GetVehicleMod(vehicle, 13)
    if transMod >= 0 then tuningBonus = tuningBonus + (transMod + 1) * 15 end
    local suspMod = GetVehicleMod(vehicle, 15)
    if suspMod >= 0 then tuningBonus = tuningBonus + (suspMod + 1) * 10 end
    if IsToggleModOn(vehicle, 18) then tuningBonus = tuningBonus + 60 end

    return math.max(0, math.floor(pi + tuningBonus))
end

---Obtiene la clase de un vehículo basada en su PI o tipo
---@param vehicle number Identificador de la entidad vehículo
---@return string Clase del vehículo (D, C, B, A, A+, S, S+, M, H)
function CalculateVehicleClass(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return 'D' end
    
    local model = GetEntityModel(vehicle)
    local modelName = string.lower(GetDisplayNameFromVehicleModel(model))

    -- 1. Comprobar excepciones manuales
    if Config.ManualClass[modelName] then
        return Config.ManualClass[modelName]
    end

    -- 2. Comprobar si es aéreo (Clase H) o moto (Clase M) usando el nativo
    local vType = GetVehicleClass(vehicle) -- Nativo de GTA
    if vType == 15 or vType == 16 then -- Helicópteros (15) o Aviones (16)
        return 'H'
    end

    if vType == 8 then -- Motos (8)
        return 'M'
    end

    -- 4. Clasificar por PI
    local pi = GetVehiclePI(vehicle)
    
    for class, data in pairs(Config.Classes) do
        if not data.isMoto and not data.isAerial then
            if pi >= data.minPI and pi <= data.maxPI then
                return class
            end
        end
    end

    -- Fallback si el PI es muy alto
    if pi > 950 then return 'S+' end

    return 'D'
end

---Obtiene los stats detallados de un vehículo
---@param vehicle number Identificador de la entidad vehículo
---@return table Stats del vehículo
function GetVehicleStats(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return {} end
    
    local pi = GetVehiclePI(vehicle)
    local class = CalculateVehicleClass(vehicle)
    
    return {
        pi = pi,
        class = class,
        classData = Config.Classes[class],
        handling = {
            topSpeed = math.floor(GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel') * 3.6),
            acceleration = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce'),
            traction = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax'),
            braking = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce')
        }
    }
end

-- ========================================
-- EXPORTS
-- ========================================

exports('GetVehiclePI', GetVehiclePI)
exports('GetVehicleClass', CalculateVehicleClass)
exports('GetVehicleStats', GetVehicleStats)

-- ========================================
-- COMANDOS DE DEBUG (Solo si Config.Debug está activo o para admins)
-- ========================================
RegisterCommand('vclass', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePointer(playerPed)
    
    -- Aviso de origen_notify en vez del chat («Sistema») y del print suelto;
    -- el print se queda en F8 por si hay que copiar el dato.
    local function Avisar(texto, tipo)
        if GetResourceState('origen_notify') == 'started' then
            exports.origen_notify:Notify({ title = 'Clase del vehículo', description = texto, type = tipo, duration = 7000 })
        end
    end

    if vehicle == 0 then
        Avisar('Tienes que estar en un vehículo (o acabar de bajarte de uno).', 'error')
        return
    end

    local stats = GetVehicleStats(vehicle)
    local nombre = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    print(('[origen_vehicleclasses] %s | PI: %s | Clase: %s (%s)'):format(
        nombre, stats.pi, stats.class, stats.classData.label))
    Avisar(('%s · PI %s · clase %s (%s)'):format(nombre, stats.pi, stats.class, stats.classData.label), 'info')
end, false)

function GetVehiclePointer(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        vehicle = GetVehiclePedIsIn(ped, true)
    end
    return vehicle
end
