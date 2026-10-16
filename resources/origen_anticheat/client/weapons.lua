-- =============================================
-- origen_anticheat — Client: Detección de Armas Ilegales
-- =============================================

-- Cooldown por arma detectada (para no reportar cada tick)
local reportedWeapons = {}
local WEAPON_COOLDOWN_MS = 30000  -- 30 segundos entre reportes de la misma arma

function CheckWeapons()
    if not Config.Modules.Weapons.enabled then return end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    local now = GetGameTimer()
    
    for _, weaponName in ipairs(Config.WeaponBlacklist) do
        local hash = GetHashKey(weaponName)
        
        if HasPedGotWeapon(ped, hash, false) then
            if not reportedWeapons[hash] or (now - reportedWeapons[hash]) > WEAPON_COOLDOWN_MS then
                reportedWeapons[hash] = now
                
                ReportViolation(
                    AC.Modules.Weapons,
                    string.format('Arma prohibida detectada en el jugador: %s', weaponName)
                )
                
                -- Quitar el arma de las manos físicamente (en caso de que sea un arma nativa)
                RemoveWeaponFromPed(ped, hash)
                
                -- Solicitar al servidor que quite el ítem del inventario
                TriggerServerEvent('ac:server:removeWeapon', weaponName)
            end
        end
    end
end

