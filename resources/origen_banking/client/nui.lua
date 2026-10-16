RegisterNUICallback('withdrawAmount', function(data, cb)
    local result = lib.callback.await('origen_banking:server:WithdrawFromAccount', false, data)
    lib.notify({
        title = result.success and 'Éxito' or 'Error',
        description = result.message,
        type = result.success and 'success' or 'error',
        position = 'top-right',
        duration = 5000
    })
    cb(result.success)
end)

RegisterNUICallback('depositAmount', function(data, cb)
    local result = lib.callback.await('origen_banking:server:DepositToAccount', false, data)
    lib.notify({
        title = result.success and 'Éxito' or 'Error',
        description = result.message,
        type = result.success and 'success' or 'error',
        position = 'top-right',
        duration = 5000
    })
    cb(result.success)
end)

RegisterNUICallback('transferAmount', function(data, cb)
    local result = lib.callback.await('origen_banking:server:TransferFromAccount', false, data)
    lib.notify({
        title = result.success and 'Éxito' or 'Error',
        description = result.message,
        type = result.success and 'success' or 'error',
        position = 'top-right',
        duration = 5000
    })
    cb(result.success)
end)

RegisterNUICallback('renameAccount', function(data, cb)
    local result = lib.callback.await('origen_banking:server:RenameAccount', false, data)
    lib.notify({
        title = result.success and 'Éxito' or 'Error',
        description = result.message,
        type = result.success and 'success' or 'error',
        position = 'top-right',
        duration = 5000
    })
    cb(result.success)
end)

RegisterNUICallback('loaded', function(_, cb)
    cb('ok')
end)

RegisterNUICallback('logout', function(_, cb)
    CerrarBanco()
    cb('ok')
end)

RegisterNUICallback('createAccount', function(data, cb)
    local result = lib.callback.await('origen_banking:server:CreateAccount', false, data)
    Avisar(result)
    cb(result or { success = false })
end)

--- Los movimientos de una cuenta que se está mirando (la ficha de Cuentas).
RegisterNUICallback('accountTransactions', function(data, cb)
    local id = type(data) == 'table' and data.accountId or nil
    cb(lib.callback.await('origen_banking:cb:getAccountTransactions', false, id) or {})
end)

RegisterNUICallback('selectAccount', function(data, cb)
    local transactions = lib.callback.await('origen_banking:cb:setActiveAccount', false, data.accountId)
    cb(transactions)
end)

--@param data { permission: string, playerId: number }
RegisterNUICallback('addUserToAccount', function(data, cb)
    local result = lib.callback.await('origen_banking:server:addUserToAccount', false, data)
    lib.notify({
        title = result.success and 'Éxito' or 'Error',
        description = result.message,
        type = result.success and 'success' or 'error',
        position = 'top-right',
        duration = 5000
    })
    cb(result)
end)

RegisterNUICallback('convertAccountToShared', function(data, cb)
    local result = lib.callback.await('origen_banking:server:ConvertAccountToShared', false, data)
    lib.notify({
        title = result.success and 'Éxito' or 'Error',
        description = result.message,
        type = result.success and 'success' or 'error',
        position = 'top-right',
        duration = 5000
    })
    cb(result.success)
end)

RegisterNUICallback('updateUserRole', function(data, cb)
    local result = lib.callback.await('origen_banking:server:updateUserRole', false, data)
    lib.notify({
        title = result.success and 'Éxito' or 'Error',
        description = result.message,
        type = result.success and 'success' or 'error',
        position = 'top-right',
        duration = 5000
    })
    cb(result)
end)

RegisterNUICallback('removeUserFromAccount', function(data, cb)
    local result = lib.callback.await('origen_banking:server:removeUserFromAccount', false, data)
    lib.notify({
        title = result.success and 'Éxito' or 'Error',
        description = result.message,
        type = result.success and 'success' or 'error',
        position = 'top-right',
        duration = 5000
    })
    cb(result)
end)
--[[ El silencio del pie del riel (06/10): el boton de la barra avisa aqui y
     el dueño, origen_map, lo reparte a todas las interfaces. Igual que en
     origen_quests/client/client.lua. ]]
RegisterNUICallback('RielSilencio', function(data, cb)
    local si = data and data.silencio
    if type(si) ~= 'boolean' then return cb({ ok = false }) end
    TriggerEvent('origen:silencio:poner', si)
    cb({ ok = true })
end)
