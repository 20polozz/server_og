-- ========================================
-- CLIENTE: RANKING SEMANAL DE CREWS
-- ========================================
-- Solo el puente entre la NUI y el servidor (server/ranking.lua): la pestaña
-- Ranking del panel de crew y su apartado en el panel de admin.

RegisterNUICallback('racing:ranking:semana', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:ranking:semana', data)
end)

RegisterNUICallback('admin:ranking', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:ranking', data)
end)

RegisterNUICallback('admin:ranking:cerrar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:ranking:cerrar', data)
end)

RegisterNUICallback('admin:ranking:anular', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:ranking:anular', data)
end)

-- Al cerrarse una semana, la pestaña abierta se pone al dia sola.
RegisterNetEvent('racing:ranking:cerrada', function(data)
    SendNUIMessage({ action = 'racing:ranking:cerrada', data = data })
end)
