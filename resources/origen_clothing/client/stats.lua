local stats = nil

local function ResetRechargeMultipliers()
    SetPlayerHealthRechargeMultiplier(cache.playerId, 0.0)
    SetPlayerHealthRechargeLimit(cache.playerId, 0.0)
end

--[[ Cambiar el modelo crea un ped nuevo con la vida llena. Si ya hay una copia
     sin devolver no se pisa: la que vale es la del ped de antes del cambio, no
     la del recien creado (asi se curaba uno lanzando /fixpj varias veces). ]]
function BackupPlayerStats()
    if stats then return end
    local ped = PlayerPedId()
    stats = {
        health = GetEntityHealth(ped),
        armour = GetPedArmour(ped)
    }
end

function RestorePlayerStats()
    if not (stats and stats.health and stats.armour) then return end
    SetEntityMaxHealth(PlayerPedId(), 200)
    Wait(1000)
    local ped = PlayerPedId()
    SetEntityHealth(ped, stats.health)
    SetPedArmour(ped, stats.armour)
    ResetRechargeMultipliers()
    -- Se gasta al devolverla: una copia vieja no debe volver a aplicarse.
    stats = nil
end
