-- ── Admin Crafting Client — NUI Callbacks ────────────────────────────────────
-- Placement usa Placement.Start() (f_placement.lua) — mismo motor que locations.

local dbg = Debug:new({ enabled = Config.Debug })

local placingPoint   = false
local placingPointId = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- CALLBACKS NUI — PUNTOS
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNUICallback('admin:crafting:getPoints', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:getPoints', false)
    cb(result or { success = false, points = {} })
end)

RegisterNUICallback('admin:crafting:getTerritories', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:getTerritories', false)
    cb(result or {})
end)

RegisterNUICallback('admin:crafting:getLabTypes', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:getLabTypes', false)
    cb(result or {})
end)

RegisterNUICallback('admin:crafting:getInventoryItems', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:getInventoryItems', false)
    cb(result or {})
end)

RegisterNUICallback('admin:crafting:createPoint', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:createPoint', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:crafting:updatePoint', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:updatePoint', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:crafting:togglePoint', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:togglePoint', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:crafting:deletePoint', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:deletePoint', false, data)
    cb(result or { success = false })
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- PLACEMENT — via Placement.Start() (f_placement.lua)
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNUICallback('admin:crafting:startPlacement', function(data, cb)
    if placingPoint then
        cb({ success = false, message = 'already_placing' })
        return
    end

    local pointId = tonumber(data and data.point_id)
    if not pointId then
        cb({ success = false, message = 'invalid_point_id' })
        return
    end

    placingPoint   = true
    placingPointId = pointId

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeAdminPanel' })

    cb({ success = true })

    local previewCfg = (Config.Markers and Config.Markers.AdminCraftingPreview) or {}

    Placement.Start({
        marker = {
            type          = previewCfg.type or 1,
            offset        = previewCfg.offset or { x = 0.0, y = 0.0, z = 0.0 },
            scale         = previewCfg.scale or { x = 0.8, y = 0.8, z = 0.8 },
            color         = previewCfg.color or { r = 100, g = 200, b = 255, a = 180 },
            bobUpAndDown  = previewCfg.bobUpAndDown == true,
            faceCamera    = previewCfg.faceCamera ~= false,
            rotationOrder = previewCfg.rotationOrder or 2,
            rotate        = previewCfg.rotate == true,
        },
    }, function(result)
        placingPoint   = false
        placingPointId = nil
        -- Sin foco aqui: el panel sigue cerrado y el servidor puede no
        -- reabrirlo; openAdminPanel ya lo coge cuando llega.

        if result then
            local saved = lib.callback.await('origen_gang:admin:crafting:setPointLocation', false, {
                id = pointId,
                x  = result.x,
                y  = result.y,
                z  = result.z,
                h  = result.h,
            })

            if saved and saved.success then
                Notify.SendNotify(locale:t('notify.admin_position_saved'), 'success')
            else
                Notify.SendNotify(locale:t('notify.admin_position_save_error'), 'error')
            end
        else
            Notify.SendNotify(locale:t('notify.admin_placement_cancelled'), 'error')
        end

        TriggerServerEvent('origen_gang:server:requestAdminPanel')
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- CALLBACKS NUI — RECETAS
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNUICallback('admin:crafting:createRecipe', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:createRecipe', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:crafting:updateRecipe', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:updateRecipe', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:crafting:toggleRecipe', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:toggleRecipe', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:crafting:deleteRecipe', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:deleteRecipe', false, data)
    cb(result or { success = false })
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- CALLBACKS NUI — INPUTS
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNUICallback('admin:crafting:createInput', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:createInput', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:crafting:updateInput', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:updateInput', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:crafting:deleteInput', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:deleteInput', false, data)
    cb(result or { success = false })
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- CALLBACKS NUI — OUTPUTS
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterNUICallback('admin:crafting:createOutput', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:createOutput', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:crafting:updateOutput', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:updateOutput', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:crafting:deleteOutput', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:crafting:deleteOutput', false, data)
    cb(result or { success = false })
end)
