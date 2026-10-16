-- ── Admin Labs Client — NUI Callbacks ────────────────────────────────────────
-- Placement usa Placement.Start() (f_placement.lua) — mismo motor que locations.

local dbg = Debug:new({ enabled = Config.Debug })

local placingLab = false

RegisterNUICallback('admin:labs:getLabs', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:getLabs', false)
    cb(result or { success = false, labs = {} })
end)

RegisterNUICallback('admin:labs:getTerritories', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:getTerritories', false)
    cb(result or {})
end)

RegisterNUICallback('admin:labs:getTypes', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:getTypes', false)
    cb(result or {})
end)

RegisterNUICallback('admin:labs:getItemCatalog', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:getItemCatalog', false)
    cb(result or { success = false, items = {} })
end)

RegisterNUICallback('admin:labs:getLabConfig', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:getLabConfig', false, data)
    cb(result or { success = false, settings = {} })
end)

RegisterNUICallback('admin:labs:getDefaultConfig', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:getDefaultConfig', false, data)
    cb(result or { success = false, settings = {} })
end)

RegisterNUICallback('admin:labs:getSettings', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:getSettings', false)
    cb(result or { success = false, settings = {} })
end)

RegisterNUICallback('admin:labs:saveSettings', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:saveSettings', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:labs:getCustomTypes', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:getCustomTypes', false)
    cb(result or { success = false, types = {} })
end)

RegisterNUICallback('admin:labs:createCustomType', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:createCustomType', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:labs:deleteCustomType', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:deleteCustomType', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:labs:createLab', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:createLab', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:labs:updateLab', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:updateLab', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:labs:toggleLab', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:toggleLab', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:labs:deleteLab', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:labs:deleteLab', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:labs:startPlacement', function(data, cb)
    if placingLab then
        cb({ success = false, message = 'already_placing' })
        return
    end

    local labId = tonumber(data and data.lab_id)
    if not labId then
        cb({ success = false, message = 'invalid_lab_id' })
        return
    end

    placingLab = true

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeAdminPanel' })

    cb({ success = true })

    -- Marker de preview desde config (igual que antes, pero ahora via helper)
    local previewCfg = (Config.Markers and Config.Markers.AdminLabsPreview) or {}

    Placement.Start({
        marker = {
            type          = previewCfg.type or 1,
            offset        = previewCfg.offset or { x = 0.0, y = 0.0, z = 0.0 },
            scale         = previewCfg.scale or { x = 0.8, y = 0.8, z = 0.8 },
            color         = previewCfg.color or { r = 180, g = 180, b = 255, a = 180 },
            bobUpAndDown  = previewCfg.bobUpAndDown == true,
            faceCamera    = previewCfg.faceCamera ~= false,
            rotationOrder = previewCfg.rotationOrder or 2,
            rotate        = previewCfg.rotate == true,
        },
    }, function(result)
        placingLab = false
        -- Sin foco aqui: el panel sigue cerrado y el servidor puede no
        -- reabrirlo; openAdminPanel ya lo coge cuando llega.

        if result then
            local saved = lib.callback.await('origen_gang:admin:labs:setEntryLocation', false, {
                id = labId,
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
