-- ── Lab Shop — Cliente ─────────────────────────────────────────────────────────
-- Gestiona los NUI callbacks de la tienda de la laptop del lab y los points
-- interactivos de stashes dentro del lab.
-- También incluye el callback de registros (getLogs) del sistema OS de la laptop.
--
-- FLUJO DE COMPRA DE STORAGE:
--   1. UI abre confirmación de pago.
--   2. NUI callback 'gangLab:validateStoragePurchase' → valida en server.
--   3. Si válido → server retorna OK → UI cierra panel → placement vía raycast.
--   4. Jugador confirma posición → NUI callback 'gangLab:confirmStoragePurchase'.
--   5. Server cobra + crea en DB → devuelve stash nuevo.
--   6. Cliente crea point para el stash recién comprado.
--   7. NUI se reabre con datos frescos.
--
-- Si el jugador cancela el placement (paso 3→4): no se llama confirmStoragePurchase
-- → no se cobra nada.

local dbg = Debug:new({ enabled = Config.Debug })

-- ── Estado local de stashes ───────────────────────────────────────────────────

local stashPoints    = {}   -- [stash_id] = lib.points
local currentStashUI = nil  -- qué stash tiene abierto el HelpText

local function removeStashPoint(stashId)
    if stashPoints[stashId] then
        stashPoints[stashId]:remove()
        stashPoints[stashId] = nil
    end
end

local function clearAllStashPoints()
    for id, _ in pairs(stashPoints) do
        removeStashPoint(id)
    end
end

-- ── Marker de stash ───────────────────────────────────────────────────────────

local function getStashMarkerCfg()
    return (Config.LabShop and Config.LabShop.StashMarker) or {
        type = 22, offset = { x = 0.0, y = 0.0, z = 0.0 },
        scale = { x = 0.25, y = 0.25, z = 0.25 },
        color = { r = 0, g = 0, b = 0, a = 170 },
        bobUpAndDown = true, faceCamera = true, rotationOrder = 2, rotate = false,
    }
end

local function drawStashMarker(coords)
    local m = getStashMarkerCfg()
    DrawMarker(
        m.type,
        coords.x + (m.offset.x or 0.0),
        coords.y + (m.offset.y or 0.0),
        coords.z + (m.offset.z or 0.0),
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        m.scale.x, m.scale.y, m.scale.z,
        m.color.r, m.color.g, m.color.b, m.color.a,
        m.bobUpAndDown, m.faceCamera, m.rotationOrder, m.rotate,
        nil, nil, false
    )
end

-- ── Crear point interactivo de un stash ───────────────────────────────────────

local function createStashPoint(stash)
    if not stash or not stash.pos_x or not stash.pos_y or not stash.pos_z then
        return
    end
    if stash.pos_x == 0.0 and stash.pos_y == 0.0 then return end  -- sin posición

    local interactions = (Config.LabShop and Config.LabShop.StashInteractions) or {}
    local pointDist    = interactions.PointDistance    or 30.0
    local drawDist     = interactions.DrawDistance     or 10.0
    local interactDist = interactions.InteractDistance or 1.8

    local coords   = vector3(stash.pos_x, stash.pos_y, stash.pos_z)
    local stashId  = stash.id
    local stashLbl = stash.label or 'Almacén'

    local p = lib.points.new({
        coords   = coords,
        distance = pointDist,
        stashId  = stashId,
    })

    function p:nearby()
        local ped  = PlayerPedId()
        local dist = #(GetEntityCoords(ped) - coords)

        if dist < drawDist then
            drawStashMarker(coords)
        end

        if dist < interactDist then
            if currentStashUI ~= stashId then
                HelpText.ShowHelpText(locale:t('notify.lab_stash_help', stashLbl))
                currentStashUI = stashId
            end

            if IsControlJustReleased(0, 38) then  -- [E]
                HelpText.HideHelpText()
                currentStashUI = nil

                lib.callback.await('origen_gang:labs:openLabStash', false, { stash_id = stashId })
            end
        elseif currentStashUI == stashId then
            HelpText.HideHelpText()
            currentStashUI = nil
        end
    end

    removeStashPoint(stashId)
    stashPoints[stashId] = p
end

-- ── API exportada para labs.lua ────────────────────────────────────────────────

-- Inicializar points de stashes al entrar al lab (llamado desde labs.lua)
exports('InitLabStashPoints', function(stashes)
    clearAllStashPoints()
    for _, s in ipairs(stashes or {}) do
        createStashPoint(s)
    end
end)

-- Limpiar points al salir del lab (llamado desde labs.lua)
exports('ClearLabStashPoints', function()
    clearAllStashPoints()
    if currentStashUI then
        HelpText.HideHelpText()
        currentStashUI = nil
    end
end)

-- ── NUI Callbacks ─────────────────────────────────────────────────────────────

-- Obtener catálogo de tienda + stashes comprados
RegisterNUICallback('gangLab:getShop', function(data, cb)
    local result = lib.callback.await('origen_gang:labs:getShop', false)
    cb(result or { success = false, message = 'error' })
end)

-- Validar compra de storage (sin cobrar)
RegisterNUICallback('gangLab:validateStoragePurchase', function(data, cb)
    local result = lib.callback.await('origen_gang:labs:validateStoragePurchase', false, {
        category_key = data.category_key,
        item_key     = data.item_key,
        pay_type     = data.pay_type,
    })
    cb(result or { success = false, message = 'error' })
end)

-- Confirmar placement y cobrar
-- Llamado DESPUÉS de que el jugador posicionó el stash con el raycast.
-- data = { category_key, item_key, pay_type, x, y, z, h }
RegisterNUICallback('gangLab:confirmStoragePurchase', function(data, cb)
    local result = lib.callback.await('origen_gang:labs:confirmStoragePurchase', false, {
        category_key = data.category_key,
        item_key     = data.item_key,
        pay_type     = data.pay_type,
        x            = data.x,
        y            = data.y,
        z            = data.z,
        h            = data.h,
    })

    if result and result.success and result.stash then
        -- Crear point del stash recién comprado sin necesidad de re-entrar al lab
        createStashPoint(result.stash)
    end

    cb(result or { success = false, message = 'error' })
end)

-- Eliminar stash (ya confirmado por el jugador con el modal de advertencia)
-- data = { stash_id }
RegisterNUICallback('gangLab:deleteLabStash', function(data, cb)
    local result = lib.callback.await('origen_gang:labs:deleteLabStash', false, {
        stash_id = data.stash_id,
    })

    if result and result.success and result.stash_id then
        -- Quitar el point interactivo del stash eliminado
        removeStashPoint(result.stash_id)
        if currentStashUI == result.stash_id then
            HelpText.HideHelpText()
            currentStashUI = nil
        end
    end

    cb(result or { success = false, message = 'error' })
end)

-- Iniciar reubicación de un stash ya comprado vía raycast
-- data = { stash_id, label }
RegisterNUICallback('gangLab:startStashRelocation', function(data, cb)
    local stashId  = tonumber(data and data.stash_id)
    local stashLbl = tostring(data and data.label or 'Almacén')

    if not stashId then
        cb({ success = false, message = 'invalid_stash_id' })
        return
    end

    -- Cerrar la laptop
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeGangLab' })

    cb({ success = true })

    local previewCfg = (Config.LabShop and Config.LabShop.StashMarker) or {}

    Placement.Start({
        marker = {
            type          = previewCfg.type or 22,
            offset        = previewCfg.offset or { x = 0.0, y = 0.0, z = 0.0 },
            scale         = previewCfg.scale or { x = 0.25, y = 0.25, z = 0.25 },
            color         = previewCfg.color or { r = 0, g = 0, b = 0, a = 200 },
            bobUpAndDown  = previewCfg.bobUpAndDown == true,
            faceCamera    = previewCfg.faceCamera ~= false,
            rotationOrder = previewCfg.rotationOrder or 2,
            rotate        = previewCfg.rotate == true,
        },
        label_confirm = locale:t('ui.confirm_position'),
        label_cancel  = locale:t('notify.cancel'),
    }, function(result)
        if result then
            local relocResult = lib.callback.await('origen_gang:labs:relocateLabStash', false, {
                stash_id = stashId,
                x        = result.x,
                y        = result.y,
                z        = result.z,
                h        = result.h,
            })

            if relocResult and relocResult.success then
                -- Actualizar el point: quitar el viejo y crear uno nuevo en la posición nueva
                removeStashPoint(stashId)
                createStashPoint({
                    id    = stashId,
                    label = stashLbl,
                    pos_x = result.x,
                    pos_y = result.y,
                    pos_z = result.z,
                    pos_h = result.h,
                })
                Notify.SendNotify(locale:t('notify.lab_stash_relocated'), 'success')
            else
                Notify.SendNotify(locale:t('notify.error_generic'), 'error')
            end
        else
            Notify.SendNotify(locale:t('notify.admin_placement_cancelled'), 'error')
        end

        -- Re-abrir laptop con datos frescos
        local insideLab = exports[GetCurrentResourceName()]:GetInsideLab()
        if insideLab then
            -- El foco solo con el portatil delante: fuera del lab no se
            -- reabre y el raton se quedaria preso sin pantalla.
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openGangLab',
                data   = {
                    lab_id   = insideLab.lab_id,
                    lab_name = insideLab.lab_name,
                    lab_type = insideLab.gameplay_type or insideLab.lab_type,
                }
            })
        end
    end)
end)

-- Iniciar placement desde la NUI (cierra el panel, corre raycast, re-abre al terminar)
-- data = { category_key, item_key, pay_type, label }
RegisterNUICallback('gangLab:startStoragePlacement', function(data, cb)
    -- Cerrar el panel de la laptop
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeGangLab' })

    cb({ success = true })

    -- Marker de preview del stash (mismo estilo que los de admin placement)
    local previewCfg = (Config.LabShop and Config.LabShop.StashMarker) or {}

    Placement.Start({
        marker = {
            type          = previewCfg.type or 22,
            offset        = previewCfg.offset or { x = 0.0, y = 0.0, z = 0.0 },
            scale         = previewCfg.scale or { x = 0.25, y = 0.25, z = 0.25 },
            color         = previewCfg.color or { r = 0, g = 0, b = 0, a = 200 },
            bobUpAndDown  = previewCfg.bobUpAndDown == true,
            faceCamera    = previewCfg.faceCamera ~= false,
            rotationOrder = previewCfg.rotationOrder or 2,
            rotate        = previewCfg.rotate == true,
        },
        label_confirm = locale:t('ui.confirm_position'),
        label_cancel  = locale:t('notify.cancel'),
    }, function(result)
        if result then
            -- Confirmar compra enviando las coords al server
            local confirmResult = lib.callback.await('origen_gang:labs:confirmStoragePurchase', false, {
                category_key = data.category_key,
                item_key     = data.item_key,
                pay_type     = data.pay_type,
                x            = result.x,
                y            = result.y,
                z            = result.z,
                h            = result.h,
            })

            if confirmResult and confirmResult.success and confirmResult.stash then
                createStashPoint(confirmResult.stash)
                Notify.SendNotify(locale:t('notify.lab_stash_purchased'), 'success')
            else
                local msgs = {
                    insufficient_funds    = locale:t('notify.insufficient_funds'),
                    pay_type_not_allowed  = locale:t('notify.pay_type_not_allowed'),
                    not_available_in_lab  = locale:t('notify.lab_shop_not_available'),
                    not_inside_lab        = locale:t('notify.not_inside_lab'),
                    db_error              = locale:t('notify.error_generic'),
                }
                local msg = (confirmResult and msgs[confirmResult.message]) or locale:t('notify.error_generic')
                Notify.SendNotify(msg, 'error')
            end
        else
            -- Placement cancelado → no se cobra nada
            Notify.SendNotify(locale:t('notify.admin_placement_cancelled'), 'error')
        end

        -- Re-abrir laptop con datos frescos
        local insideLab = exports[GetCurrentResourceName()]:GetInsideLab()
        if insideLab then
            -- El foco solo con el portatil delante: fuera del lab no se
            -- reabre y el raton se quedaria preso sin pantalla.
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openGangLab',
                data   = {
                    lab_id   = insideLab.lab_id,
                    lab_name = insideLab.lab_name,
                    lab_type = insideLab.gameplay_type or insideLab.lab_type,
                }
            })
        end
    end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Callbacks de compra de mesas de crafteo desde laptop del lab
-- ─────────────────────────────────────────────────────────────────────────────

-- Validar compra de mesa (sin cobrar)
RegisterNUICallback('gangLab:validateCraftingTablePurchase', function(data, cb)
    local result = lib.callback.await('origen_gang:labs:validateCraftingTablePurchase', false, {
        point_id = data.point_id,
        pay_type = data.pay_type,
    })
    cb(result or { success = false, message = 'error' })
end)

-- Iniciar placement de mesa (cierra UI, raycast, confirma compra, re-abre)
RegisterNUICallback('gangLab:startCraftingTablePlacement', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeGangLab' })
    cb({ success = true })

    Placement.Start({
        marker = {
            type          = 1,
            offset        = { x = 0.0, y = 0.0, z = 0.0 },
            scale         = { x = 0.8, y = 0.8, z = 0.8 },
            color         = { r = 216, g = 27, b = 85, a = 180 },
            bobUpAndDown  = false,
            faceCamera    = false,
            rotationOrder = 2,
            rotate        = false,
        },
        label_confirm = locale:t('ui.confirm_position'),
        label_cancel  = locale:t('notify.cancel'),
    }, function(result)
        if result then
            local confirmResult = lib.callback.await('origen_gang:labs:confirmCraftingTablePurchase', false, {
                point_id = data.point_id,
                pay_type = data.pay_type,
                x        = result.x,
                y        = result.y,
                z        = result.z,
                h        = result.h,
            })

            if confirmResult and confirmResult.success then
                Notify.SendNotify(locale:t('notify.crafting_table_purchased'), 'success')
                TriggerServerEvent('origen_gang:client:crafting:requestReload')
            else
                local msgs = {
                    crafting_table_not_available     = locale:t('notify.lab_shop_not_available'),
                    crafting_table_already_purchased = locale:t('notify.crafting_table_already_purchased'),
                    insufficient_funds               = locale:t('notify.insufficient_funds'),
                    pay_type_not_allowed             = locale:t('notify.pay_type_not_allowed'),
                    not_inside_lab                   = locale:t('notify.not_inside_lab'),
                    db_error                         = locale:t('notify.error_generic'),
                }
                local msg = (confirmResult and msgs[confirmResult.message]) or locale:t('notify.error_generic')
                Notify.SendNotify(msg, 'error')
            end
        else
            Notify.SendNotify(locale:t('notify.admin_placement_cancelled'), 'error')
        end

        local insideLabCT = exports[GetCurrentResourceName()]:GetInsideLab()
        if insideLabCT then
            -- El foco solo con el portatil delante: fuera del lab no se
            -- reabre y el raton se quedaria preso sin pantalla.
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openGangLab',
                data   = {
                    lab_id   = insideLabCT.lab_id,
                    lab_name = insideLabCT.lab_name,
                    lab_type = insideLabCT.gameplay_type or insideLabCT.lab_type,
                }
            })
        end
    end)
end)

-- ── Gestión de mesas de crafteo instanciadas ─────────────────────────────────

-- Eliminar mesa de crafteo comprada
RegisterNUICallback('gangLab:deleteCraftingTable', function(data, cb)
    local result = lib.callback.await('origen_gang:labs:deleteCraftingTable', false, {
        instance_id = data.instance_id,
    })
    cb(result or { success = false, message = 'error' })
end)

-- Reubicación de mesa (cierra UI, raycast, confirma nueva pos, re-abre)
RegisterNUICallback('gangLab:startCraftingTableRelocation', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeGangLab' })
    cb({ success = true })

    Placement.Start({
        marker = {
            type          = 1,
            offset        = { x = 0.0, y = 0.0, z = 0.0 },
            scale         = { x = 0.8, y = 0.8, z = 0.8 },
            color         = { r = 216, g = 27, b = 85, a = 180 },
            bobUpAndDown  = false,
            faceCamera    = false,
            rotationOrder = 2,
            rotate        = false,
        },
        label_confirm = locale:t('ui.confirm_position'),
        label_cancel  = locale:t('notify.cancel'),
    }, function(result)
        if result then
            local confirmResult = lib.callback.await('origen_gang:labs:relocateCraftingTable', false, {
                instance_id = data.instance_id,
                x           = result.x,
                y           = result.y,
                z           = result.z,
                h           = result.h,
            })

            if confirmResult and confirmResult.success then
                Notify.SendNotify(locale:t('ui.confirm_position'), 'success')
                TriggerServerEvent('origen_gang:client:crafting:requestReload')
            else
                Notify.SendNotify(locale:t('notify.error_generic'), 'error')
            end
        else
            Notify.SendNotify(locale:t('notify.admin_placement_cancelled'), 'error')
        end

        local insideLabCT = exports[GetCurrentResourceName()]:GetInsideLab()
        if insideLabCT then
            -- El foco solo con el portatil delante: fuera del lab no se
            -- reabre y el raton se quedaria preso sin pantalla.
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openGangLab',
                data   = {
                    lab_id   = insideLabCT.lab_id,
                    lab_name = insideLabCT.lab_name,
                    lab_type = insideLabCT.gameplay_type or insideLabCT.lab_type,
                }
            })
        end
    end)
end)

-- ── Registros (logs) del lab ──────────────────────────────────────────────────
-- Delega al servidor que consulta DB y devuelve paginados.
RegisterNUICallback('gangLab:getLogs', function(data, cb)
    local result = lib.callback.await('origen_gang:labs:getLogs', false, {
        page  = tonumber(data.page)  or 0,
        limit = tonumber(data.limit) or 30,
    })
    if result then
        cb(result)
    else
        cb({ success = false, logs = {}, total = 0 })
    end
end)
