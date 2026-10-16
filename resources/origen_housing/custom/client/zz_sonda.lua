-- TEMPORAL (pruebas): la sonda zz_puerta pide volver a meter al jugador en una
-- casa tras reiniciar el recurso. Evento local, no de red. Borrar con la sonda.
AddEventHandler('zz_puerta:entrar', function(id)
    local house = House and House.get and House.get(tonumber(id) or id)
    if not house then return end
    if currentInteriorHouseID then return end
    house:EnterHouse()
end)

-- Diagnóstico: cómo ve el cliente la obra (y el error, si montar revienta)
AddEventHandler('zz_puerta:diag', function(id)
    local d = { obra = Obra ~= nil, dentro = Obra and Obra.Dentro and Obra.Dentro() or false, interior = currentInteriorHouseID }
    local a = Obra and Obra.Actual and Obra.Actual()
    if a then
        local n = 0
        for _ in pairs(a.objetos or {}) do n = n + 1 end
        d.objetos, d.muerta = n, a.muerta
    end
    local ok, r = pcall(function() return lib.callback.await('origen_housing:obra:estado', 3000, tonumber(id) or id) end)
    d.estadoOk, d.estado = ok, ok and (type(r) == 'table' and 'tabla' or tostring(r)) or tostring(r)
    local house = House and House.get and House.get(tonumber(id) or id)
    d.casa = house ~= nil
    if house then d.libre = Obra and Obra.EsLibre and Obra.EsLibre(house) or false end
    TriggerServerEvent('zz_puerta:nada', 'diag', d)
end)

-- Monta a mano con el error a la vista
AddEventHandler('zz_puerta:montar', function(id)
    local house = House and House.get and House.get(tonumber(id) or id)
    local ok, err = xpcall(function() house:EnterHouse() end, debug.traceback)
    TriggerServerEvent('zz_puerta:nada', 'montar', { ok = ok, err = ok and nil or tostring(err):sub(1, 900) })
end)
