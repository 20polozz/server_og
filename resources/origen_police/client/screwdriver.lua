-- ============================================================
-- ORIGEN POLICE - Screwdriver (Retire Fake Plates)
-- ============================================================

local function useScrewdriver()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, 3.0, false)

    if not vehicle or vehicle == 0 then
        ShowNotification("No hay ningún vehículo cerca", "error")
        return
    end

    -- Security: must be outside
    if IsPedInAnyVehicle(ped, false) then
        ShowNotification("Debes estar fuera del vehículo", "error")
        return
    end

    -- Determine if it's the front or back (optional, but let's just be near the car)
    local vehCoords = GetEntityCoords(vehicle)
    local dist = #(coords - vehCoords)
    
    if dist > 3.0 then
        ShowNotification("Estás demasiado lejos del vehículo", "error")
        return
    end

    -- Start interaction
    TaskTurnPedToFaceEntity(ped, vehicle, 1000)
    Wait(1000)

    local success = lib.progressBar({
        duration = 5000,
        label = "Retirando matrícula...",
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = "mini@repair",
            clip = "fixing_a_ped"
        },
    })

    if success then
        -- Call the fakeplate export with nil to restore real plate
        local result, message = exports.qbx_smallresources:setFakePlate(vehicle, nil)
        
        if result then
            ShowNotification("Matrícula retirada con éxito. Placa original restablecida.", "success")
        else
            ShowNotification(message or "Este vehículo no tiene una matrícula falsa", "error")
        end
    else
        ShowNotification("Acción cancelada", "error")
    end
end

RegisterNetEvent("origen_police:client:useScrewdriver", useScrewdriver)
