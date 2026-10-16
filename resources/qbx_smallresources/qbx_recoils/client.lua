local recoils = require 'qbx_recoils.config'

-- Depuración: Verificar si los recoils se cargaron
if recoils then
  --  print('^2[qbx_recoils] ^7Configuración de retroceso cargada con éxito.')
end

-- Función para obtener el multiplicador basado en puntería (0.0 a 1.0)
local function getRecoilMultiplier()
    local gymData = exports.qbx_core:GetPlayerData().metadata.gym_data or {}
    local shootingLevel = gymData.shooting or 0
    -- Si shootingLevel es 100, multiplier es 0. Si es 0, multiplier es 1
    local multiplier = 1.0 - (math.min(100, shootingLevel) / 100.0)
    return multiplier, shootingLevel
end

local function recoilLoop()
    CreateThread(function()
        local multiplier, shootingLevel = getRecoilMultiplier()
   --     print(('^3[qbx_recoils] ^7Estadística Shooting: ^2%s%% ^7| Multiplicador de Recoil: ^5%s%%'):format(math.floor(shootingLevel), math.floor(multiplier * 100)))

        while cache.weapon do
            if IsPedShooting(cache.ped) and not IsPedDoingDriveby(cache.ped) then
                local _, wep = GetCurrentPedWeapon(cache.ped, true)
                local recoilVal = recoils[wep]
                
                if recoilVal and recoilVal ~= 0 then
                    local finalRecoil = recoilVal * multiplier

                    if finalRecoil > 0.01 then
                        local tv = 0
                        if GetFollowPedCamViewMode() ~= 4 then
                            repeat
                                Wait(0)
                                local p = GetGameplayCamRelativePitch()
                                SetGameplayCamRelativePitch(p + 0.1, 0.2)
                                tv += 0.1
                            until tv >= finalRecoil
                        else
                            repeat
                                Wait(0)
                                local p = GetGameplayCamRelativePitch()
                                if finalRecoil > 0.1 then
                                    SetGameplayCamRelativePitch(p + 0.6, 1.2)
                                    tv += 0.6
                                else
                                    SetGameplayCamRelativePitch(p + 0.016, 0.333)
                                    tv += 0.1
                                end
                            until tv >= finalRecoil
                        end
                    end
                end
            end
            Wait(0)
        end
    end)
end

lib.onCache('weapon', function(weapon)
    Wait(5)
    if not weapon then return end
    print('^3[qbx_recoils] ^7Arma detectada: ' .. weapon)
    recoilLoop()
end)