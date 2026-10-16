-- ========================================
-- CLIENTE: PROGRESIÓN DEL PILOTO (pestaña «Temporada» del hub)
-- ========================================
--[[ Solo hace de puente: la interfaz pide y el servidor (server/progresion.lua)
     calcula, valida y contesta. Todos los callbacks contestan siempre
     (ContestarDesdeServidor, client/main.lua): una NUI que espera una
     respuesta que no llega se queda colgada. ]]

RegisterNUICallback('racing:temporada:resumen', function(_, cb)
    ContestarDesdeServidor(cb, 'racing:temporada:resumen')
end)

RegisterNUICallback('racing:temporada:reclamar', function(data, cb)
    data = type(data) == 'table' and data or {}
    ContestarDesdeServidor(cb, 'racing:temporada:reclamar', { reto = data.reto, periodo = data.periodo })
end)

RegisterNUICallback('racing:temporada:elegirTitulo', function(data, cb)
    data = type(data) == 'table' and data or {}
    ContestarDesdeServidor(cb, 'racing:temporada:elegirTitulo', { titulo = data.titulo })
end)

-- Pase de temporada: un nivel o todos los desbloqueados.
RegisterNUICallback('racing:temporada:pase:reclamar', function(data, cb)
    data = type(data) == 'table' and data or {}
    ContestarDesdeServidor(cb, 'racing:temporada:pase:reclamar', { nivel = tonumber(data.nivel), todos = data.todos == true })
end)

-- Panel de admin: la temporada y el pase (solo lectura).
RegisterNUICallback('admin:temporada', function(_, cb)
    ContestarDesdeServidor(cb, 'racing:admin:temporada')
end)

RegisterNUICallback('racing:temporada:titulos', function(data, cb)
    data = type(data) == 'table' and data or {}
    ContestarDesdeServidor(cb, 'racing:temporada:titulos', { identifiers = data.identifiers })
end)

--[[ Lo que cambia al acabar una carrera (rating, división, retos) o al cerrar
     la temporada: un aviso, como los demás del servidor, y que la pestaña se
     refresque si está abierta. ]]
RegisterNetEvent('racing:progresion:aviso', function(d)
    if type(d) ~= 'table' then return end
    lib.notify({
        title = type(d.titulo) == 'string' and d.titulo or 'Temporada',
        description = type(d.texto) == 'string' and d.texto or '',
        type = d.tipo == 'success' and 'success' or 'info',
        duration = 9000,
    })
    SendNUIMessage({ action = 'temporada:refrescar' })
end)
