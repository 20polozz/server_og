--[[ Tatuajes · asignar y exclusivos: el puente del panel con el servidor
     (server/asignar.lua), y la lista de exclusivos, que ya no es solo la del
     fichero: el servidor manda la suya entera al entrar y cada vez que cambia. ]]

RegisterNetEvent('origen_tattoos:client:exclusivos', function(lista)
    if type(lista) == 'table' then Config.BlockedTattoos = lista end
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('origen_tattoos:server:exclusivos')
end)

local SIN = { ok = false, motivo = 'El servidor no contesta.' }

RegisterNUICallback('admin:catalogo', function(_, cb)
    local r = lib.callback.await('origen_tattoos:admin:catalogo', false)
    if not r then return cb(false) end

    -- El nombre sale del idioma del juego, como en la tienda: la clave cruda
    -- (TAT_AR_003) se queda de apoyo en el hash, que tambien se busca.
    for _, t in ipairs(r.tatuajes or {}) do
        local nombre = t.n and GetLabelText(t.n) or 'NULL'
        if nombre == 'NULL' or nombre == '' then nombre = t.n or 'Tatuaje' end
        t.n = nombre
    end
    cb(r)
end)

RegisterNUICallback('admin:de', function(d, cb)
    cb(lib.callback.await('origen_tattoos:admin:de', false, d and d.jugador) or {})
end)

RegisterNUICallback('admin:poner', function(d, cb)
    cb(lib.callback.await('origen_tattoos:admin:poner', false, d) or SIN)
end)

RegisterNUICallback('admin:exclusivo', function(d, cb)
    cb(lib.callback.await('origen_tattoos:admin:exclusivo', false, d) or SIN)
end)
