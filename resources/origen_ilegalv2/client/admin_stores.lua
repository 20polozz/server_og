-- ── Admin Stores Client — NUI Callbacks ──────────────────────────────────────
-- Placement usa Placement.Start() (f_placement.lua) — mismo motor que locations.
-- Preview del NPC se mantiene via opts.ped_model.

local dbg = Debug:new({ enabled = Config.Debug })

local placingNpc     = false
local placingStoreId = nil

-- ── GET INVENTORY ITEMS ───────────────────────────────────────────────────────

RegisterNUICallback('admin:stores:getInventoryItems', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:getInventoryItems', false)
    cb(result or {})
end)

-- ── GET STORES ────────────────────────────────────────────────────────────────

RegisterNUICallback('admin:stores:getStores', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:getStores', false)
    cb(result or { success = false, stores = {} })
end)

-- ── GET TERRITORIES ───────────────────────────────────────────────────────────

RegisterNUICallback('admin:stores:getTerritories', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:getTerritoriesForStores', false)
    cb(result or {})
end)

-- ── CREATE STORE ──────────────────────────────────────────────────────────────

RegisterNUICallback('admin:stores:createStore', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:createStore', false, data)
    cb(result or { success = false })
end)

-- ── UPDATE STORE ──────────────────────────────────────────────────────────────

RegisterNUICallback('admin:stores:updateStore', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:updateStore', false, data)
    cb(result or { success = false })
end)

-- ── TOGGLE STORE ──────────────────────────────────────────────────────────────

RegisterNUICallback('admin:stores:toggleStore', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:toggleStore', false, data)
    cb(result or { success = false })
end)

-- ── DELETE STORE ──────────────────────────────────────────────────────────────

RegisterNUICallback('admin:stores:deleteStore', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:deleteStore', false, data)
    cb(result or { success = false })
end)

-- ── ITEMS ─────────────────────────────────────────────────────────────────────

RegisterNUICallback('admin:stores:createItem', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:createStoreItem', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:stores:updateItem', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:updateStoreItem', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:stores:toggleItem', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:toggleStoreItem', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:stores:deleteItem', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:deleteStoreItem', false, data)
    cb(result or { success = false })
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- PLACEMENT: via Placement.Start() — con preview ped
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNUICallback('admin:stores:startPlacement', function(data, cb)
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
            local saved = lib.callback.await('origen_gang:admin:setStoreNpc', false, {
                id        = storeId,
                ped_model = pedModel,
                x         = result.x,
                y         = result.y,
                z         = result.z,
                h         = result.h,
            })

            if saved and saved.success then
                Notify.SendNotify(locale:t('notify.admin_store_npc_position_saved'), 'success')
            else
                Notify.SendNotify(locale:t('notify.admin_position_save_error'), 'error')
            end
        else
            Notify.SendNotify(locale:t('notify.admin_placement_cancelled'), 'error')
        end

        TriggerServerEvent('origen_gang:server:requestAdminPanel')
    end)
end)
