--[[ El lado del cliente: le llega el presupuesto del mecánico, lo ve con sus
     líneas y su total, y acepta o rechaza. El cobro y lo que se monta lo
     decide el servidor; aquí solo se enseña y se contesta. ]]

local pendiente = nil

local function Soltar()
    -- Si el cliente es el propio mecánico (tunea su coche), el taller sigue
    -- abierto y el ratón es suyo: no se suelta.
    if not (TallerAbierto and TallerAbierto()) then SetNuiFocus(false, false) end
end

RegisterNetEvent('origen_customs:presupuesto', function(datos)
    if type(datos) ~= 'table' then return end
    pendiente = datos.id
    SendNUIMessage({ accion = 'factura', datos = datos })
    SetNuiFocus(true, true)
    PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', true)
end)

RegisterNetEvent('origen_customs:presupuestoAnulado', function(id)
    if pendiente ~= id then return end
    pendiente = nil
    SendNUIMessage({ accion = 'facturaFuera' })
    Soltar()
end)

RegisterNUICallback('responder', function(d, cb)
    cb({ ok = true })
    if not pendiente or type(d) ~= 'table' or d.id ~= pendiente then return end
    TriggerServerEvent('origen_customs:responder', pendiente, d.acepta == true)
    pendiente = nil
    Soltar()
end)
