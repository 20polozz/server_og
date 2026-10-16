-- ═══════════════════════════════════════════════════════════════════════════
--  ORG Parking — Admin Panel Client  (store edition)
-- ═══════════════════════════════════════════════════════════════════════════

local _open     = false
local _fetching = false

-- ── Build locale table to pass to NUI ─────────────────────────────────────

local function buildLocale()
    return {
        title                = T('admin_title'),
        subtitle             = T('admin_subtitle'),
        search_placeholder   = T('admin_search_placeholder'),
        vehicles_label       = T('admin_vehicles_count'):gsub('%%d', '{n}'),
        col_plate            = T('admin_col_plate'),
        col_model            = T('admin_col_model'),
        col_owner            = T('admin_col_owner'),
        col_date             = T('admin_col_date'),
        col_actions          = T('admin_col_actions'),
        stat_title           = T('admin_stat_title'),
        stat_total           = T('admin_stat_total'),
        stat_spawned         = T('admin_stat_spawned'),
        stat_unspawned       = T('admin_stat_unspawned'),
        stat_owners          = T('admin_stat_owners'),
        legend_spawned       = T('admin_legend_spawned'),
        legend_spawning      = T('admin_legend_spawning'),
        legend_despawning    = T('admin_legend_despawning'),
        legend_unspawned     = T('admin_legend_unspawned'),
        state_spawned        = T('admin_state_spawned'),
        state_spawning       = T('admin_state_spawning'),
        state_despawning     = T('admin_state_despawning'),
        state_unspawned      = T('admin_state_unspawned'),
        btn_spawn            = T('admin_btn_spawn_title'),
        btn_garage           = T('admin_btn_garage_title'),
        btn_delete           = T('admin_btn_delete_title'),
        btn_settings         = T('admin_btn_settings'),
        btn_back             = T('admin_btn_back'),
        settings_title       = T('admin_settings_title'),
        settings_saved       = T('admin_settings_saved'),
        settings_error       = T('admin_settings_error'),
        confirm_title        = T('admin_confirm_title'),
        confirm_body         = T('admin_confirm_body'):gsub('%%s', '{plate}'),
        confirm_hint         = T('admin_confirm_hint'),
        confirm_cancel       = T('admin_confirm_cancel'),
        confirm_delete       = T('admin_confirm_delete'),
        garage_title         = T('admin_garage_title'),
        garage_for           = T('admin_garage_for'):gsub('%%s', '{plate}'),
        garage_filter        = T('admin_garage_filter'),
        garage_cancel        = T('admin_garage_cancel'),
        garage_internal      = T('admin_garage_internal'):gsub('%%s', '{label}'),
        no_garages           = T('admin_no_garages'),
        empty                = T('admin_empty'),
        no_results           = T('admin_no_results'):gsub('%%s', '{q}'),
        loading              = T('admin_loading'),
        cfg_sec_behavior     = T('admin_cfg_sec_behavior'),
        cfg_sec_cost         = T('admin_cfg_sec_cost'),
        cfg_sec_proximity    = T('admin_cfg_sec_proximity'),
        cfg_sec_spawn        = T('admin_cfg_sec_spawn'),
        cfg_sec_limits       = T('admin_cfg_sec_limits'),
        cfg_sec_blip         = T('admin_cfg_sec_blip'),
        cfg_sec_marker       = T('admin_cfg_sec_marker'),
        cfg_sec_fuel         = T('admin_cfg_sec_fuel'),
        cfg_sec_cleanup      = T('admin_cfg_sec_cleanup'),
        cfg_sec_system       = T('admin_cfg_sec_system'),
        cfg_enabled          = T('admin_cfg_enabled'),
        cfg_auto_parking     = T('admin_cfg_auto_parking'),
        cfg_lock_timeout     = T('admin_cfg_lock_timeout'),
        cfg_rate_hour        = T('admin_cfg_rate_hour'),
        cfg_min_fee          = T('admin_cfg_min_fee'),
        cfg_free_min         = T('admin_cfg_free_min'),
        cfg_block_broke      = T('admin_cfg_block_broke'),
        cfg_spawn_radius     = T('admin_cfg_spawn_radius'),
        cfg_despawn_radius   = T('admin_cfg_despawn_radius'),
        cfg_despawn_delay    = T('admin_cfg_despawn_delay'),
        cfg_concurrency      = T('admin_cfg_concurrency'),
        cfg_max_cell         = T('admin_cfg_max_cell'),
        cfg_max_player       = T('admin_cfg_max_player'),
        cfg_sprite           = T('admin_cfg_sprite'),
        cfg_color            = T('admin_cfg_color'),
        cfg_draw_dist        = T('admin_cfg_draw_dist'),
        cfg_marker_visible   = T('admin_cfg_marker_visible'),
        cfg_marker_hidden    = T('admin_cfg_marker_hidden'),
        cfg_save_fuel        = T('admin_cfg_save_fuel'),
        cfg_inactive_days    = T('admin_cfg_inactive_days'),
        cfg_debug_mode       = T('admin_cfg_debug_mode'),
        cfg_save_btn         = T('admin_cfg_save_btn'),
    }
end

-- ── Open panel ─────────────────────────────────────────────────────────────

local function openAdminPanel()
    if _open or _fetching then return end
    _fetching = true

    lib.callback('org:admin:getVehicles', false, function(data)
        _fetching = false
        if not data then
            lib.notify({
                title       = 'Aparcamiento',
                description = T('admin_no_perms'),
                type        = 'error',
            })
            return
        end

        _open = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action   = 'openAdmin',
            vehicles = data.vehicles,
            stats    = data.stats,
            locale   = buildLocale(),
            settings = data.settings,
        })
    end)
end

-- ── Close panel ────────────────────────────────────────────────────────────

local function closeAdminPanel()
    if not _open then return end
    _open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeAdmin' })
end

-- Raton soltado a la fuerza (soltarraton, pantalla colgada): el panel se da
-- por cerrado y se esconde, o /orgadmin no volveria a abrirse.
OrigenFoco.AlSoltar(function()
    _open = false
    SendNUIMessage({ action = 'closeAdmin' })
end)

-- ── NUI callbacks ──────────────────────────────────────────────────────────
-- Names MUST match exactly what the Vue calls via fetchNui(name, data)

-- "closeAdmin" — called by Vue close button AND ESC keydown in AdminPanel
RegisterNUICallback('closeAdmin', function(_, cb)
    closeAdminPanel()
    cb('ok')

    -- ESC: si el panel se abrió desde la pestaña Scripts del admin, se vuelve
    -- a ella. origen_admin solo vuelve si este panel salió de su lista; con el
    -- comando, ESC cierra y nada más.
    if GetResourceState('origen_admin') == 'started' then
        SetTimeout(80, function()
            pcall(function() exports['origen_admin']:ReturnToScripts() end)
        end)
    end
end)

-- "getVehicles" — called by Vue ↻ Actualizar button
RegisterNUICallback('getVehicles', function(_, cb)
    lib.callback('org:admin:getVehicles', false, function(data)
        -- Return the data directly so fetchNui() resolves with it
        cb(data or { vehicles = {}, stats = { total=0, spawned=0, unspawned=0, owners=0 } })
    end)
end)

-- "forceSpawn" — Vue sends { id: string }
RegisterNUICallback('forceSpawn', function(body, cb)
    lib.callback('org:admin:forceSpawn', false, function(ok, reason)
        cb({ ok = ok == true, msg = reason })
    end, body.id)
end)

-- "removeVehicle" — Vue sends { id: string }
RegisterNUICallback('removeVehicle', function(body, cb)
    lib.callback('org:admin:removeVehicle', false, function(ok, reason)
        cb({ ok = ok == true, msg = reason })
    end, body.id)
end)

-- "getGarages" — Vue sends nothing, expects Garage[]
RegisterNUICallback('getGarages', function(_, cb)
    lib.callback('org:admin:getGarages', false, function(garages)
        cb(garages or {})
    end)
end)

-- "sendToGarage" — Vue sends { vehicleId, garageId, garageLabel }
RegisterNUICallback('sendToGarage', function(body, cb)
    lib.callback('org:admin:sendToGarage', false, function(ok, reason)
        cb({ ok = ok == true, msg = reason })
    end, body.vehicleId, body.garageId)
end)

-- "saveSettings" — Vue sends full settings object
RegisterNUICallback('saveSettings', function(body, cb)
    lib.callback('org:admin:saveSettings', false, function(ok)
        cb({ ok = ok == true })
    end, body)
end)

-- ── Export for external integrations ──────────────────────────────────────

exports('openManagement', openAdminPanel)

-- ── Command ────────────────────────────────────────────────────────────────

RegisterCommand(Config.AdminCommand or 'orgadmin', function()
    openAdminPanel()
end, false)
