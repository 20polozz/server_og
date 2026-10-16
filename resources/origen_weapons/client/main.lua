--[[ Estos modificadores son ajustes que se quedan puestos: no hay que repetirlos
     cada fotograma. Antes se hacia —y con los punos tambien, porque
     WEAPON_UNARMED esta en la config—, asi que el hilo corria siempre (16/09).

     Ahora se aplican en cuanto cambia el arma (se mira cada fotograma, que es
     una sola native) y se reafirman cada cuarto de segundo por si otro recurso
     los ha tocado, igual que hacia antes a su manera. ]]
local REAFIRMAR_MS = 250

CreateThread(function()
    local armaAnterior, pedAnterior, proxima = nil, nil, 0

    while true do
        Wait(0)

        local playerPed = PlayerPedId()
        local currentWeapon = GetSelectedPedWeapon(playerPed)
        local ahora = GetGameTimer()

        if currentWeapon == armaAnterior and playerPed == pedAnterior and ahora < proxima then
            goto siguiente
        end
        armaAnterior, pedAnterior, proxima = currentWeapon, playerPed, ahora + REAFIRMAR_MS

        do
        local weaponsConfig = Config.Weapons[currentWeapon]

        if weaponsConfig then
            if weaponsConfig.disableCritical then
                SetPedSuffersCriticalHits(playerPed, false)
            else
                SetPedSuffersCriticalHits(playerPed, true)
            end
            local modifier = weaponsConfig.modifier
            if modifier == 0 then modifier = 0.000001 end
            
            SetPlayerWeaponDamageModifier(PlayerId(), modifier)
            SetPlayerMeleeWeaponDamageModifier(PlayerId(), modifier)
            SetWeaponDamageModifier(currentWeapon, modifier)
        else
            SetPedSuffersCriticalHits(playerPed, true)
            SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
            SetPlayerMeleeWeaponDamageModifier(PlayerId(), 1.0)
            SetWeaponDamageModifier(`WEAPON_UNARMED`, 1.0)
        end
        end

        ::siguiente::
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    local playerPed = PlayerPedId()
    SetPedSuffersCriticalHits(playerPed, true)
    SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
    SetPlayerMeleeWeaponDamageModifier(PlayerId(), 1.0)
    SetWeaponDamageModifier(`WEAPON_UNARMED`, 1.0)
end)
