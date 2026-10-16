-- ── Lab Counterfeit — Puente NUI ↔ Server (cliente) ─────────────────────────
-- Registra los NUI callbacks del sistema de lavado de dinero.
-- Toda la lógica autoritativa vive en server/lab_counterfeit.lua.
-- Este archivo puentea las llamadas de la UI al servidor y aplica
-- el estado visual IPL de las secadoras según los jobs activos/listos.

if not Config.LabCounterfeit or not Config.LabCounterfeit.Enabled then return end

-- ── Props IPL por dryer → los 3 estados posibles ─────────────────────────────
-- Los props se leen del interior counterfeit (interiorId 247809, mismo que bob74_ipl).
-- Los estados on/open son puramente visuales: no se persisten en DB.
-- El único prop comprable (y que persiste) es el 'off' (dryer adquirida).
local DRYER_PROPS = {
    dryer_1 = { off = 'dryera_off', on = 'dryera_on', open = 'dryera_open' },
    dryer_2 = { off = 'dryerb_off', on = 'dryerb_on', open = 'dryerb_open' },
    dryer_3 = { off = 'dryerc_off', on = 'dryerc_on', open = 'dryerc_open' },
    dryer_4 = { off = 'dryerd_off', on = 'dryerd_on', open = 'dryerd_open' },
}

-- Aplica el estado visual IPL de las dryers directamente con natives.
-- No persiste nada en DB — es solo cosmético. El reset de ApplyLabIplState
-- al reabrir la laptop sobreescribirá esto (correcto: el estado real viene del servidor).
-- jobs    = array de jobs activos del lab (del payload del servidor)
-- modules = ipl_modules del lab (del payload del servidor, para saber qué dryers compró)
local function applyDryerVisualState(jobs, modules)
    -- Obtener interiorId del catálogo
    local catalog = Config.LabUpgrades and Config.LabUpgrades['counterfeit']
    local interiorId = catalog and catalog.interior_id
    if not interiorId then return end

    -- Construir lista ordenada de dryers compradas (tienen active ~= nil en ipl_modules)
    local unlockedDryers = {}
    if modules then
        for _, mod in ipairs(modules) do
            if DRYER_PROPS[mod.module_key] then
                -- Dryer comprada = tiene variante activa registrada en DB
                if mod.active and mod.active ~= '' then
                    table.insert(unlockedDryers, mod.module_key)
                end
            end
        end
    end

    if #unlockedDryers == 0 then return end

    -- Ordenar jobs por started_at ASC para asignación determinista
    local sortedJobs = {}
    for _, j in ipairs(jobs or {}) do
        table.insert(sortedJobs, j)
    end
    table.sort(sortedJobs, function(a, b)
        return (a.started_at or 0) < (b.started_at or 0)
    end)

    -- Aplicar estado a cada dryer comprada con natives directos
    for i, moduleKey in ipairs(unlockedDryers) do
        local props = DRYER_PROPS[moduleKey]
        local job   = sortedJobs[i]

        -- Determinar qué prop activar
        local propOn
        if not job then
            propOn = props.off
        elseif job.status == 'ready' then
            propOn = props.open
        else
            propOn = props.on
        end

        -- Desactivar los otros dos y activar el correcto
        local allProps = { props.off, props.on, props.open }
        for _, p in ipairs(allProps) do
            if p ~= propOn then
                if IsInteriorEntitySetActive(interiorId, p) then
                    DeactivateInteriorEntitySet(interiorId, p)
                end
            end
        end
        if not IsInteriorEntitySetActive(interiorId, propOn) then
            ActivateInteriorEntitySet(interiorId, propOn)
        end
    end

    -- Un solo flush al final
    RefreshInterior(interiorId)
end

-- ── Obtener estado actual del lavado en el lab ─────────────────────────────────
RegisterNUICallback('gangLab:counterfeit:getLaunderState', function(_, cb)
    local result = lib.callback.await('origen_gang:labs:counterfeit:getLaunderState', false)
    if result and result.success then
        -- Aplicar estado visual de dryers sin bloquear la respuesta a la UI
        CreateThread(function()
            applyDryerVisualState(result.jobs, result.ipl_modules)
        end)
    end
    cb(result or { success = false, message = 'error' })
end)

-- ── Iniciar un proceso de lavado ───────────────────────────────────────────────
-- data = { amount: number }
RegisterNUICallback('gangLab:counterfeit:startLaunder', function(data, cb)
    local result = lib.callback.await('origen_gang:labs:counterfeit:startLaunder', false, {
        amount = tonumber(data and data.amount) or 0,
    })
    if result and result.success then
        CreateThread(function()
            applyDryerVisualState(result.jobs, result.ipl_modules)
        end)
    end
    cb(result or { success = false, message = 'error' })
end)

-- ── Reclamar dinero limpio de un proceso terminado ─────────────────────────────
-- data = { job_id: number }
RegisterNUICallback('gangLab:counterfeit:claimLaunder', function(data, cb)
    local result = lib.callback.await('origen_gang:labs:counterfeit:claimLaunder', false, {
        job_id = tonumber(data and data.job_id) or 0,
    })
    if result and result.success then
        CreateThread(function()
            applyDryerVisualState(result.jobs, result.ipl_modules)
        end)
    end
    cb(result or { success = false, message = 'error' })
end)

-- ── Sync push desde el servidor ────────────────────────────────────────────────
-- Recibe el estado actualizado de dryers cuando alguien en el mismo lab
-- inicia o reclama un lavado, o cuando un job termina por tiempo.
-- El servidor solo envía esto a jugadores que estén dentro del lab counterfeit.
RegisterNetEvent('origen_gang:labs:counterfeit:syncDryers', function(payload)
    -- Validar que seguimos dentro de un lab counterfeit (defensivo)
    local labState = exports[GetCurrentResourceName()]:GetInsideLab()
    if not labState or (labState.gameplay_type or labState.lab_type) ~= 'counterfeit' then return end

    CreateThread(function()
        applyDryerVisualState(payload.jobs, payload.ipl_modules)
    end)
end)

-- ── Aplicar estado al entrar al lab ────────────────────────────────────────────
-- Garantiza que el estado real de las dryers se vea desde el momento de entrada,
-- sin necesidad de abrir el tab de lavado en la laptop.
AddEventHandler('origen:Lab:OnEnter', function(labType)
    if labType ~= 'counterfeit' then return end

    CreateThread(function()
        -- Pequeño delay para que el servidor registre la presencia del jugador
        -- antes de hacer el callback (GetPlayerLabState debe devolver el state)
        Wait(500)
        local result = lib.callback.await('origen_gang:labs:counterfeit:getLaunderState', false)
        if result and result.success then
            applyDryerVisualState(result.jobs, result.ipl_modules)
        end
    end)
end)
