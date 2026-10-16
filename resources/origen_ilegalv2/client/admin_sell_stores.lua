-- ── Admin Sell Stores Client — NUI Callbacks ─────────────────────────────────
-- Placement usa Placement.Start() (f_placement.lua) — mismo motor que locations.
-- Preview del NPC se mantiene via opts.ped_model.

local dbg = Debug:new({ enabled = Config.Debug })

local placingNpc     = false
local placingStoreId = nil

-- ── GET INVENTORY ITEMS ───────────────────────────────────────────────────────

RegisterNUICallback('admin:sellStores:getInventoryItems', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:getInventoryItemsForSell', false)
    cb(result or {})
end)

-- ── GET SELL STORES ───────────────────────────────────────────────────────────

RegisterNUICallback('admin:sellStores:getStores', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:getSellStores', false)
    cb(result or { success = false, stores = {} })
end)

-- ── GET TERRITORIES ───────────────────────────────────────────────────────────

RegisterNUICallback('admin:sellStores:getTerritories', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:getTerritoriesForSellStores', false)
    cb(result or {})
end)

-- ── CREATE SELL STORE ─────────────────────────────────────────────────────────

RegisterNUICallback('admin:sellStores:createStore', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:createSellStore', false, data)
    cb(result or { success = false })
end)

-- ── UPDATE SELL STORE ─────────────────────────────────────────────────────────

RegisterNUICallback('admin:sellStores:updateStore', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:updateSellStore', false, data)
    cb(result or { success = false })
end)

-- ── TOGGLE SELL STORE ─────────────────────────────────────────────────────────

RegisterNUICallback('admin:sellStores:toggleStore', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:toggleSellStore', false, data)
    cb(result or { success = false })
end)

-- ── DELETE SELL STORE ─────────────────────────────────────────────────────────

RegisterNUICallback('admin:sellStores:deleteStore', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:deleteSellStore', false, data)
    cb(result or { success = false })
end)

-- ── ITEMS ─────────────────────────────────────────────────────────────────────

RegisterNUICallback('admin:sellStores:createItem', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:createSellStoreItem', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:sellStores:updateItem', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:updateSellStoreItem', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:sellStores:toggleItem', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:toggleSellStoreItem', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:sellStores:deleteItem', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:deleteSellStoreItem', false, data)
    cb(result or { success = false })
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- PLACEMENT: via Placement.Start() — con preview ped
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNUICallback('admin:sellStores:startPlacement', function(data, cb)
    if placingNpc then
        cb({ success = false, message = 'already_placing' })
        return
    end

    local storeId  = tonumber(data and data.store_id)
    local pedModel = (data and data.ped_model and data.ped_model ~= '') and data.ped_model or 's_m_y_dealer_01'

    if not storeId then
        cb({ success = false, message = 'invalid_store_id' })
        return
    end

    placingNpc     = true
    placingStoreId = storeId

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeAdminPanel' })

    cb({ success = true })

    Placement.Start({
        ped_model    = pedModel,
        label_rotate = locale:t('ui.rotate_npc'),
    }, function(result)
        placingNpc     = false
        placingStoreId = nil
        -- Sin foco aqui: el panel sigue cerrado y el servidor puede no
        -- reabrirlo; openAdminPanel ya lo coge cuando llega.

        if result then
            local saved = lib.callback.await('origen_gang:admin:setSellStoreNpc', false, {
                id        = storeId,
                ped_model = pedModel,
                x         = result.x,
                y         = result.y,
                z         = result.z,
                h         = result.h,
            })

            if saved and saved.success then
                Notify.SendNotify(locale:t('notify.admin_sell_npc_position_saved'), 'success')
            else
                Notify.SendNotify(locale:t('notify.admin_position_save_error'), 'error')
            end
        else
            Notify.SendNotify(locale:t('notify.admin_placement_cancelled'), 'error')
        end

        TriggerServerEvent('origen_gang:server:requestAdminPanel')
    end)
end)
