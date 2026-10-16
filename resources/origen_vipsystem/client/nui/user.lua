--* NUI CALLBACKS - PANEL USER

RegisterNUICallback('user:init', function(_, cb)
    local data = lib.callback.await('origen_vipsystem:server:userInit', 5000)

    -- A timeout used to be answered with a well-formed "no vip, no store" payload,
    -- which the NUI could not tell apart from a real one.
    cb(data or { failed = true })
end)

RegisterNUICallback('user:redeemCode', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:userRedeemCode', 2000, data)
    cb(res or { success = false })
end)

-- A subscription purchase also writes the subscription and its first invoice, so
-- the old 1000 ms budget could time out on a charge the server had already made.
RegisterNUICallback('user:buyStoreItem', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:userBuyStoreItem', 5000, data)
    cb(res or { success = false })
end)

RegisterNUICallback('user:getBusinesses', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:userGetBusinesses', 3000)
    cb(res or { success = false, businesses = {} })
end)

RegisterNUICallback('user:getCosmetics', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:userGetCosmetics', 3000)
    cb(res or { success = false, prendas = {} })
end)

RegisterNUICallback('user:buyCosmetic', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:userBuyCosmetic', 5000, data)
    cb(res or { success = false })
end)

RegisterNUICallback('user:getVipVehicles', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:userGetVipVehicles', 3000)
    cb(res or { success = false, vehiculos = {} })
end)

RegisterNUICallback('user:buyVipVehicle', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:userBuyVipVehicle', 8000, data)
    cb(res or { success = false })
end)

RegisterNUICallback('user:requestBusinessPurchase', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:userRequestBusinessPurchase', 5000, data)
    cb(res or { success = false })
end)

RegisterNUICallback('user:getSubscriptions', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:userGetSubscriptions', 3000)
    cb(res or { success = false, subscriptions = {} })
end)

RegisterNUICallback('user:cancelSubscription', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:userCancelSubscription', 3000, data)
    cb(res or { success = false })
end)

RegisterNUICallback('user:resumeSubscription', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:userResumeSubscription', 3000, data)
    cb(res or { success = false })
end)

RegisterNUICallback('user:paySubscriptionNow', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:userPaySubscriptionNow', 5000, data)
    cb(res or { success = false })
end)

RegisterNUICallback('user:convertCurrency', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:userConvertCurrency', 2000, data)
    cb(res or { success = false })
end)

-- The model comes back from the server, never from the NUI payload, so a faked
-- request can only ever start a drive the player was already allowed to start.
RegisterNUICallback('user:testDriveVehicle', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:userTestDrive', 2000, data)

    if not res or not res.success then
        return cb(res or { success = false })
    end

    if not TestDrive.Start(res.model, res.label, res.duration) then
        return cb({ success = false })
    end

    cb({ success = true })
end)

-- ─── Sorteos ──────────────────────────────────────────────────────────────────

RegisterNUICallback('user:getRaffles', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:userGetRaffles', 1000)
    cb(res or { success = false, raffles = {} })
end)

RegisterNUICallback('user:joinRaffle', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:userJoinRaffle', 1000, data)
    cb(res or { success = false })
end)

RegisterNUICallback('user:claimRafflePrize', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:userClaimRafflePrize', 1000, data)
    cb(res or { success = false })
end)
