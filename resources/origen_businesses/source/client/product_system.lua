RegisterNUICallback('getProductSystem', function(data, cb)
    cb(lib.callback.await('origen_businesses:server:getProductSystem', false, data.businessId))
end)

RegisterNUICallback('setProductSystem', function(data, cb)
    cb(lib.callback.await('origen_businesses:server:setProductSystem', false, data))
end)
