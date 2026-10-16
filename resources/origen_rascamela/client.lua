local playing = false

RegisterNUICallback('scratchCard', function(data, cb)
    -- Aviso de que se termino de rascar. Se manda SIEMPRE, haya premio o no:
    -- quien decide si hay premio y cuanto es el servidor, no la pagina.
    TriggerServerEvent('scratch:reward')
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    if cb then cb('ok') end
    SetNuiFocus(false, false)
    playing = false
    TriggerServerEvent('origen_rascamela:server:close')
end)

RegisterNetEvent('origen_rascamela', function(amount)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'playandrestart',
        amount = amount -- Ahora pasamos la cantidad exacta
    })
end)