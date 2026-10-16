-- ── Lab Upgrades — Cliente ─────────────────────────────────────────────────────
-- Motor de aplicación de variantes IPL en el interior del laboratorio.
-- Usa natives directos (ActivateInteriorEntitySet / Deactivate / RefreshInterior)
-- sin depender de bob74_ipl en runtime para mantener el acoplamiento mínimo.

local dbg = Debug:new({ enabled = Config.Debug })

-- ── Interior IDs (derivados del catálogo de config) ───────────────────────────
-- Se construyen dinámicamente desde Config.LabUpgrades para que agregar
-- un nuevo lab type en config sea suficiente — sin tocar este archivo.
local INTERIOR_IDS = (function()
    local ids = {}
    for labType, catalog in pairs(Config.LabUpgrades or {}) do
        if catalog.interior_id then
            ids[labType] = catalog.interior_id
        end
    end
    return ids
end)()

-- ── Motor de aplicación de estado IPL ─────────────────────────────────────────

-- Props mínimas que deben estar activas para que la laptop/notebook
-- no quede flotando en el aire cuando un lab todavía no tiene compras.
-- Solo se usan como fallback en módulo 'style' exclusivo sin variante activa.
-- Verificadas contra bob74_ipl/dlc_bikers/cocaine.lua y meth.lua:
--   coke: table_equipment_upgrade es la mesa en cualquier tier; set_up es
--         el soporte base que siempre está en basic y upgrade.
--   meth: meth_lab_basic incluye la mesa/soporte de la notebook;
--         meth_lab_setup es el entorno compartido entre basic y upgrade.
local STYLE_FALLBACK_PROPS = {
    coke = { 'set_up', 'equipment_basic', 'coke_press_basic', 'production_basic', 'table_equipment' },
    meth = { 'meth_lab_basic', 'meth_lab_setup' },
}

-- Aplica una lista de props_on y props_off sobre un interiorId dado.
-- No hace RefreshInterior, eso se delega al caller para hacer un solo flush.
local function applyProps(interiorId, propsOn, propsOff)
    -- Desactivar primero las alternativas
    for _, prop in ipairs(propsOff or {}) do
        if prop and prop ~= '' then
            if IsInteriorEntitySetActive(interiorId, prop) then
                DeactivateInteriorEntitySet(interiorId, prop)
            end
        end
    end
    -- Activar las deseadas
    for _, prop in ipairs(propsOn or {}) do
        if prop and prop ~= '' then
            if not IsInteriorEntitySetActive(interiorId, prop) then
                ActivateInteriorEntitySet(interiorId, prop)
            end
        end
    end
end

-- Aplica el estado completo de upgrades de un lab.
-- modules = array de módulos con variant activa y sus props (viene del servidor).
-- Se hace un único RefreshInterior al final.
--
-- IMPORTANTE: primero se desactivan TODAS las props del catálogo (reset total)
-- para neutralizar el LoadDefault que bob74_ipl aplica al iniciar el recurso.
-- Después se activa solo lo que corresponde al estado real del lab.
local function ApplyLabIplState(labType, modules)
    local interiorId = INTERIOR_IDS[labType]
    if not interiorId then
        dbg:warning('[LabUpgrades] Interior ID desconocido para tipo:', labType)
        return
    end

    local catalog = Config.LabUpgrades and Config.LabUpgrades[labType]
    if not catalog then
        dbg:warning('[LabUpgrades] Catálogo no encontrado para tipo:', labType)
        return
    end

    -- ── PASO 1: Reset total ───────────────────────────────────────────────────
    -- Desactivar TODAS las props que el catálogo conoce para este interior.
    -- Esto neutraliza el LoadDefault de bob74_ipl y deja el interior pelado.
    -- Usamos un set para no desactivar la misma prop dos veces.
    local allCatalogProps = {}
    for _, mod in ipairs(catalog.modules or {}) do
        for _, v in ipairs(mod.variants or {}) do
            for _, prop in ipairs(v.props_on or {}) do
                if prop and prop ~= '' and not allCatalogProps[prop] then
                    allCatalogProps[prop] = true
                    if IsInteriorEntitySetActive(interiorId, prop) then
                        DeactivateInteriorEntitySet(interiorId, prop)
                    end
                end
            end
        end
    end

    -- ── PASO 2: Aplicar solo el estado real ───────────────────────────────────
    -- Construir lookup rápido de módulos del catálogo por module_key
    local catalogByKey = {}
    for _, mod in ipairs(catalog.modules or {}) do
        catalogByKey[mod.module_key] = mod
    end

    for _, mod in ipairs(modules or {}) do
        local catMod = catalogByKey[mod.module_key]
        if not catMod then goto continue end

        if mod.exclusive then
            -- Módulo exclusivo: activar solo la variante activa (si existe)
            if mod.active and mod.active ~= '' then
                for _, catV in ipairs(catMod.variants or {}) do
                    if catV.variant_key == mod.active then
                        for _, prop in ipairs(catV.props_on or {}) do
                            if prop and prop ~= '' then
                                if not IsInteriorEntitySetActive(interiorId, prop) then
                                    ActivateInteriorEntitySet(interiorId, prop)
                                end
                            end
                        end
                        break
                    end
                end
            elseif mod.module_key == 'style' then
                -- Sin variante activa en el módulo 'style': aplicar props mínimas
                -- de fallback para que la mesa/soporte de la notebook no quede flotando.
                -- No representa ninguna compra real, es solo un piso visual seguro.
                local fallback = STYLE_FALLBACK_PROPS[labType]
                if fallback then
                    for _, prop in ipairs(fallback) do
                        if not IsInteriorEntitySetActive(interiorId, prop) then
                            ActivateInteriorEntitySet(interiorId, prop)
                        end
                    end
                    dbg:info('[LabUpgrades] Fallback style aplicado para', labType, '— sin variante activa')
                end
            end
            -- Resto de módulos exclusivos sin active = pelados → no activamos nada (correcto)

        else
            -- Módulo no exclusivo: activar todas las variantes desbloqueadas
            for _, v in ipairs(mod.variants or {}) do
                if v.unlocked then
                    for _, catV in ipairs(catMod.variants or {}) do
                        if catV.variant_key == v.variant_key then
                            for _, prop in ipairs(catV.props_on or {}) do
                                if prop and prop ~= '' then
                                    if not IsInteriorEntitySetActive(interiorId, prop) then
                                        ActivateInteriorEntitySet(interiorId, prop)
                                    end
                                end
                            end
                            break
                        end
                    end
                end
            end
        end

        ::continue::
    end

    -- ── PASO 3: Flush ─────────────────────────────────────────────────────────
    RefreshInterior(interiorId)
    dbg:info('[LabUpgrades] Estado IPL aplicado (con reset previo) para tipo:', labType)
end

-- Export para que labs.lua pueda llamarlo al entrar al lab
exports('ApplyLabIplState', ApplyLabIplState)

-- ── NUI Callbacks ─────────────────────────────────────────────────────────────

-- Obtener catálogo + estado actual (abre la laptop de mejoras)
RegisterNUICallback('gangLab:getUpgrades', function(data, cb)
    local result = lib.callback.await('origen_gang:labs:getUpgrades', false)
    cb(result or { success = false, message = 'error' })
end)

-- Comprar variante
RegisterNUICallback('gangLab:buyUpgrade', function(data, cb)
    local result = lib.callback.await('origen_gang:labs:buyUpgrade', false, {
        module_key  = data.module_key,
        variant_key = data.variant_key,
        pay_type    = data.pay_type,
    })

    if result and result.success and result.modules then
        -- Aplicar el nuevo estado IPL inmediatamente en el cliente
        local labState = exports[GetCurrentResourceName()]:GetInsideLab()
        if labState then
            ApplyLabIplState(labState.gameplay_type or labState.lab_type, result.modules)
        end
    end

    cb(result or { success = false, message = 'error' })
end)

-- Cambiar variante activa (gratis, ya desbloqueada)
RegisterNUICallback('gangLab:setActiveUpgrade', function(data, cb)
    local result = lib.callback.await('origen_gang:labs:setActiveUpgrade', false, {
        module_key  = data.module_key,
        variant_key = data.variant_key,
    })

    if result and result.success and result.modules then
        local labState = exports[GetCurrentResourceName()]:GetInsideLab()
        if labState then
            ApplyLabIplState(labState.gameplay_type or labState.lab_type, result.modules)
        end
    end

    cb(result or { success = false, message = 'error' })
end)
