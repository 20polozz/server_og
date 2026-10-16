-- ========================================
-- ORIGEN RACING - CONCESIONARIO DE CREW (cliente)
-- ========================================

local ActiveCrewVehicle = nil -- { entity, garageId, plate }

-- NUI Callbacks registrados en client/nui_callbacks.lua

-- ========================================
-- SACAR VEHÍCULO (spawn tras confirmar en UI)
-- ========================================
RegisterNetEvent('racing:dealership:client:spawnVehicle', function(vehicleData)
    local coords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())

    -- Cargar modelo
    local hash = GetHashKey(vehicleData.vehicleModel)
    if not IsModelInCdimage(hash) then
        lib.notify({ title = 'Concesionario', description = 'Modelo de vehículo no encontrado: ' .. vehicleData.vehicleModel, type = 'error' })
        return
    end

    lib.requestModel(hash)

    -- Spawnear un poco adelante del jugador
    local spawnCoords = vector3(
        coords.x + math.sin(-math.rad(heading)) * 6.0,
        coords.y + math.cos(-math.rad(heading)) * 6.0,
        coords.z
    )

    local vehicle = CreateVehicle(hash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)

    SetEntityAsNoLongerNeeded(vehicle)
    SetVehicleNumberPlateText(vehicle, vehicleData.plate)
    SetVehicleColours(vehicle, 0, 0)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleDoorsLocked(vehicle, 1)

    -- Aplicar mods guardados
    if vehicleData.mods then
        for modType, modValue in pairs(vehicleData.mods) do
            SetVehicleMod(vehicle, tonumber(modType), tonumber(modValue), false)
        end
    end

    SetModelAsNoLongerNeeded(hash)

    ActiveCrewVehicle = {
        entity  = vehicle,
        garageId = vehicleData.garageId,
        plate   = vehicleData.plate,
    }

    lib.notify({
        title       = 'Garaje Crew',
        description = vehicleData.vehicleLabel .. ' (' .. vehicleData.plate .. ') spawneado',
        type        = 'success',
        duration    = 4000,
    })
end)

-- ========================================
-- GUARDAR VEHÍCULO (eliminar entidad tras confirmar en servidor)
-- ========================================
RegisterNetEvent('racing:dealership:client:vehicleStored', function(garageId)
    if ActiveCrewVehicle and ActiveCrewVehicle.garageId == garageId then
        if DoesEntityExist(ActiveCrewVehicle.entity) then
            DeleteEntity(ActiveCrewVehicle.entity)
        end
        ActiveCrewVehicle = nil
        lib.notify({
            title       = 'Garaje Crew',
            description = 'Vehículo guardado correctamente',
            type        = 'success',
        })
    end
end)

-- ========================================
-- HELPER: devuelve el garageId del vehículo activo de crew
-- (usado desde NUI callbacks de client/nui_callbacks.lua si hace falta)
-- ========================================
function GetActiveCrewVehicleGarageId()
    if not ActiveCrewVehicle then return nil end

    local ped = PlayerPedId()
    local currentVeh = GetVehiclePedIsIn(ped, false)

    if currentVeh and currentVeh ~= 0 then
        local plate = GetVehicleNumberPlateText(currentVeh):gsub('%s+', '')
        if plate == ActiveCrewVehicle.plate then
            return ActiveCrewVehicle.garageId
        end
    end

    return nil
end
