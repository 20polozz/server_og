-- ── Gang Labs — Cliente Gameplay ─────────────────────────────────────────────

local dbg = Debug:new({ enabled = Config.Debug })

local activeLabs      = {}
local labEntryPoints  = {}
local interiorPoints  = {}
local currentTextUI   = nil

local insideLab = nil -- { lab_id, lab_name, lab_type, gameplay_type, exit, laptop }
local labPanelOpen = false

local markerCfg = (Config.Markers and Config.Markers.Labs) or {}
local entryCfg  = markerCfg.entry or {}
local exitCfg   = markerCfg.exit or {}
local laptopCfg = markerCfg.laptop or {}

local function markerDefaults(cfg, fallbackColor)
    return {
        type = cfg.type or 1,
        offset = cfg.offset or { x = 0.0, y = 0.0, z = 0.0 },
        scale = cfg.scale or { x = 0.8, y = 0.8, z = 0.8 },
        color = cfg.color or fallbackColor,
        bob = cfg.bobUpAndDown == true,
        face = cfg.faceCamera ~= false,
        rotOrd = cfg.rotationOrder or 2,
        rotate = cfg.rotate == true,
    }
end

local ENTRY_DIST   = (Config.Labs and Config.Labs.Interactions and Config.Labs.Interactions.EntryDistance) or 2.0
local EXIT_DIST    = (Config.Labs and Config.Labs.Interactions and Config.Labs.Interactions.ExitDistance) or 2.0
local LAPTOP_DIST  = (Config.Labs and Config.Labs.Interactions and Config.Labs.Interactions.LaptopDistance) or 2.0

local ENTRY_DRAW_DIST  = markerCfg.entryDrawDistance or 20.0
local EXIT_DRAW_DIST   = markerCfg.exitDrawDistance or 20.0
local LAPTOP_DRAW_DIST = markerCfg.laptopDrawDistance or 15.0

local POINT_DIST = markerCfg.pointDistance or 60.0

local ENTRY_MARKER  = markerDefaults(entryCfg,  { r = 180, g = 180, b = 255, a = 160 })
local EXIT_MARKER   = markerDefaults(exitCfg,   { r = 255, g = 180, b = 120, a = 170 })
local LAPTOP_MARKER = markerDefaults(laptopCfg, { r = 120, g = 180, b = 255, a = 170 })

local function isArray(tbl)
    if type(tbl) ~= 'table' then return false end
    local n = 0
    for k, _ in pairs(tbl) do
        if type(k) ~= 'number' then return false end
        n = n + 1
    end
    return n > 0
end

local function deepCopy(value)
    if type(value) ~= 'table' then return value end
    local out = {}
    for k, v in pairs(value) do
        out[k] = deepCopy(v)
    end
    return out
end

local function mergeInPlace(dst, src)
    if type(dst) ~= 'table' or type(src) ~= 'table' then return end

    if isArray(dst) and isArray(src) then
        for i = #dst, 1, -1 do dst[i] = nil end
        for i = 1, #src do dst[i] = deepCopy(src[i]) end
        return
    end

    for k, v in pairs(src) do
        if type(v) == 'table' then
            if type(dst[k]) ~= 'table' then
                dst[k] = deepCopy(v)
            else
                mergeInPlace(dst[k], v)
            end
        else
            dst[k] = v
        end
    end
end

RegisterNetEvent('origen_gang:client:labs:settingsSync', function(settingsByType)
    if type(settingsByType) ~= 'table' then return end

    local configByType = {
        weed = Config.LabWeed,
        meth = Config.LabMeth,
        coke = Config.LabCoke,
        counterfeit = Config.LabCounterfeit,
    }

    for labType, settings in pairs(settingsByType) do
        local cfg = configByType[labType]
        if cfg and type(settings) == 'table' then
            mergeInPlace(cfg, settings)
        end
    end
end)

local function requestRuntimeLabSettings()
    local settings = lib.callback.await('origen_gang:labs:getRuntimeSettings', false)
    if type(settings) == 'table' then
        TriggerEvent('origen_gang:client:labs:settingsSync', settings)
    end
end

local function drawMarkerAt(coords, marker)
    DrawMarker(
        marker.type,
        coords.x + marker.offset.x,
        coords.y + marker.offset.y,
        coords.z + marker.offset.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        marker.scale.x, marker.scale.y, marker.scale.z,
        marker.color.r, marker.color.g, marker.color.b, marker.color.a,
        marker.bob, marker.face, marker.rotOrd, marker.rotate, nil, nil, false
    )
end

local function removePoint(tbl, key)
    if tbl[key] then
        tbl[key]:remove()
        tbl[key] = nil
    end
end

local function normalizeCoord4(coord)
    if not coord then return nil end

    local x = coord.x or coord[1]
    local y = coord.y or coord[2]
    local z = coord.z or coord[3]
    local h = coord.h
    if h == nil then h = coord.w end
    if h == nil then h = coord[4] end

    if x == nil or y == nil or z == nil then
        return nil
    end

    return {
        x = x + 0.0,
        y = y + 0.0,
        z = z + 0.0,
        h = (h or 0.0) + 0.0,
    }
end

local function closeLabPanel()
    if not labPanelOpen then return end
    labPanelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeGangLab' })
end

local function openLabPanel()
    if not insideLab or labPanelOpen then return end

    labPanelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openGangLab',
        data = {
            lab_id = insideLab.lab_id,
            lab_name = insideLab.lab_name,
            lab_type = insideLab.gameplay_type or insideLab.lab_type,
            lab_type_raw = insideLab.lab_type,
        }
    })
end

local function clearInteriorPoints()
    for k, _ in pairs(interiorPoints) do
        removePoint(interiorPoints, k)
    end
end

local function clearEntryPoints()
    for labId, _ in pairs(activeLabs) do
        removePoint(labEntryPoints, labId)
    end
    activeLabs = {}
    if currentTextUI then
        HelpText.HideHelpText()
        currentTextUI = nil
    end
end

-- fadeIn = false → no hace DoScreenFadeIn al final (el caller lo maneja)
local function teleportPlayerTo(coords, skipFadeIn)
    coords = normalizeCoord4(coords)
    if not coords then return end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, false, false, false, false)
    if coords.h then SetEntityHeading(ped, coords.h + 0.0) end

    Wait(200)

    if not skipFadeIn then
        DoScreenFadeIn(500)
    end
end

local function leaveLab()
    if not insideLab then return end

    local result = lib.callback.await('origen_gang:labs:exit', false)
    if not result or not result.success then
        Notify.SendNotify(locale:t('notify.labs_exit_error'), 'error')
        return
    end

    -- Notificar al módulo del lab que estamos saliendo.
    -- El evento genérico 'origen:Lab:OnExit' recibe el lab_type como argumento.
    -- Cada lab_*.lua (runner o custom) escucha este evento y filtra por su tipo.
    if insideLab then
        TriggerEvent('origen:Lab:OnExit', insideLab.gameplay_type or insideLab.lab_type)
    end

    closeLabPanel()
    clearInteriorPoints()

    -- Limpiar points de stashes del lab
    exports[GetCurrentResourceName()]:ClearLabStashPoints()

    if result.coords then
        teleportPlayerTo(result.coords)
    end

    insideLab = nil
end

local function createInteriorPoints()
    clearInteriorPoints()
    if not insideLab then return end

    local exitData = normalizeCoord4(insideLab.exit) or normalizeCoord4(insideLab.spawn)
    local laptopData = normalizeCoord4(insideLab.laptop)
    if not exitData or not laptopData then
        dbg:error('[Labs] Invalid interior coords. exit/laptop missing for lab', insideLab.lab_id)
        return
    end

    local exitCoords = vector3(exitData.x, exitData.y, exitData.z)
    local laptopCoords = vector3(laptopData.x, laptopData.y, laptopData.z)

    local pExit = lib.points.new({
        coords = exitCoords,
        distance = 30.0,
        pointType = 'exit',
    })

    function pExit:nearby()
        local ped = PlayerPedId()
        local dist = #(GetEntityCoords(ped) - exitCoords)

        if dist < EXIT_DRAW_DIST then
            drawMarkerAt(exitCoords, EXIT_MARKER)
        end

        if dist < EXIT_DIST then
            if currentTextUI ~= 'lab_exit' then
                HelpText.ShowHelpText(locale:t('ui.labs_help_exit'))
                currentTextUI = 'lab_exit'
            end

            if IsControlJustReleased(0, 38) then
                HelpText.HideHelpText()
                currentTextUI = nil
                leaveLab()
            end
        elseif currentTextUI == 'lab_exit' then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    interiorPoints.exit = pExit

    local pLaptop = lib.points.new({
        coords = laptopCoords,
        distance = 25.0,
        pointType = 'laptop',
    })

    function pLaptop:nearby()
        local ped = PlayerPedId()
        local dist = #(GetEntityCoords(ped) - laptopCoords)

        if dist < LAPTOP_DRAW_DIST then
            drawMarkerAt(laptopCoords, LAPTOP_MARKER)
        end

        if dist < LAPTOP_DIST then
            if currentTextUI ~= 'lab_laptop' then
                HelpText.ShowHelpText(locale:t('ui.labs_help_laptop'))
                currentTextUI = 'lab_laptop'
            end

            if IsControlJustReleased(0, 38) then
                HelpText.HideHelpText()
                currentTextUI = nil
                openLabPanel()
            end
        elseif currentTextUI == 'lab_laptop' then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    interiorPoints.laptop = pLaptop
end

local function enterLab(lab)
    if insideLab then return end

    local result = lib.callback.await('origen_gang:labs:enter', false, { lab_id = lab.id })
    if not result or not result.success then
        local reason = result and result.message or 'error'
        local msgs = {
            lab_disabled = locale:t('notify.labs_disabled'),
            no_gang = locale:t('notify.labs_no_gang'),
            not_whitelisted = locale:t('notify.labs_not_whitelisted'),
            territory_neutral = locale:t('notify.labs_territory_neutral'),
            not_territory_owner = locale:t('notify.labs_not_territory_owner'),
            no_territory = locale:t('notify.labs_no_territory'),
            lab_not_found = locale:t('notify.labs_not_found'),
            invalid_lab_type = locale:t('notify.labs_invalid_type'),
        }
        Notify.SendNotify(msgs[reason] or locale:t('notify.error_with_reason', reason), 'error')
        return
    end

    -- Teleportar con fade out pero SIN fade in todavía.
    -- La pantalla queda negra hasta que el IPL esté aplicado.
    local catalogType = result.lab_type
    if not (Config.LabUpgrades and Config.LabUpgrades[catalogType]) then
        catalogType = result.gameplay_type
    end
    local hasIplCatalog = Config.LabUpgrades and Config.LabUpgrades[catalogType]
    teleportPlayerTo(result.spawn, hasIplCatalog)  -- skipFadeIn si vamos a resetear IPL

    insideLab = {
        lab_id = result.lab_id,
        lab_name = result.lab_name,
        lab_type = result.lab_type,
        gameplay_type = result.gameplay_type or result.lab_type,
        spawn = normalizeCoord4(result.spawn),
        exit = normalizeCoord4(result.exit),
        laptop = normalizeCoord4(result.laptop),
    }

    createInteriorPoints()

    -- Inicializar points de stashes comprados en este lab
    -- Se hace en background para no bloquear la entrada
    CreateThread(function()
        local shopData = lib.callback.await('origen_gang:labs:getShop', false)
        if shopData and shopData.success and shopData.stashes then
            exports[GetCurrentResourceName()]:InitLabStashPoints(shopData.stashes)
        end
    end)

    -- Notificar al módulo del lab que entramos.
    -- El evento genérico 'origen:Lab:OnEnter' recibe el lab_type + datos de entrada.
    -- Cada lab_*.lua (runner o custom) escucha este evento y filtra por su tipo.
    -- Para labs que necesiten datos adicionales del servidor antes de iniciar
    -- (ej: weed → plantas tomadas), el módulo custom puede hacer su propio callback
    -- dentro del handler de 'origen:Lab:OnEnter'.
    TriggerEvent('origen:Lab:OnEnter', result.gameplay_type or result.lab_type)

    -- Aplicar (o resetear) variantes IPL del lab.
    -- Se hace con pantalla negra para que el jugador no vea el LoadDefault de bob74.
    if hasIplCatalog then
        Wait(300)  -- tiempo para que el interior termine de cargar antes del refresh
        exports[GetCurrentResourceName()]:ApplyLabIplState(catalogType, result.ipl_modules or {})
        Wait(100)  -- pequeño buffer post-refresh antes de abrir la pantalla
        DoScreenFadeIn(600)
    end

end

local function createLabEntryPoint(lab)
    removePoint(labEntryPoints, lab.id)

    local coords = vector3(lab.entry_x, lab.entry_y, lab.entry_z)
    local p = lib.points.new({
        coords = coords,
        distance = POINT_DIST,
        labId = lab.id,
    })

    function p:nearby()
        if insideLab then return end

        local myCoords = GetEntityCoords(PlayerPedId())
        local dist = #(myCoords - coords)

        if dist < ENTRY_DRAW_DIST then
            drawMarkerAt(coords, ENTRY_MARKER)
        end

        if dist < ENTRY_DIST then
            if currentTextUI ~= self.labId then
                HelpText.ShowHelpText(locale:t('ui.labs_help_enter', lab.name or ''))
                currentTextUI = self.labId
            end

            if IsControlJustReleased(0, 38) then
                HelpText.HideHelpText()
                currentTextUI = nil
                enterLab(lab)
            end
        elseif currentTextUI == self.labId then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    labEntryPoints[lab.id] = p
end

local _loadingLabs = false
local _lastLoadTime = 0
local LOAD_COOLDOWN = 4000

local function loadLabs()
    if insideLab then return end

    local now = GetGameTimer()
    if _loadingLabs then return end
    if (now - _lastLoadTime) < LOAD_COOLDOWN then return end

    _loadingLabs = true
    _lastLoadTime = now

    clearEntryPoints()

    local result = lib.callback.await('origen_gang:labs:getAvailable', false)
    _loadingLabs = false

    if not result or not result.success then return end

    for _, lab in ipairs(result.labs or {}) do
        if lab.entry_x ~= 0 and lab.entry_y ~= 0 then
            activeLabs[lab.id] = lab
            createLabEntryPoint(lab)
        end
    end

    dbg:info('[Labs] Cargados', #(result.labs or {}), 'labs')
end

RegisterNUICallback('gangLab:closeLaptop', function(data, cb)
    closeLabPanel()
    cb('ok')
end)

-- Si el raton se suelta a la fuerza (`soltarraton`, pagina vacia o colgada;
-- ver origen_map/shared/foco.lua), el portatil se cierra de verdad: con la
-- marca en true no volveria a abrirse, y la pagina se quedaria pintada.
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if labPanelOpen then closeLabPanel() end
    end)
end

-- Nota: 'gangLab:exitLab' eliminado — el botón "Salir del lab" fue removido
-- de la laptop. El jugador sale exclusivamente por el marker [E] interior.

RegisterNetEvent('origen_gang:client:labs:reload', function()
    if insideLab then return end
    TriggerServerEvent('origen_gang:client:labs:requestReload')
end)

RegisterNetEvent('origen_gang:client:labs:loaded', function(labs)
    if insideLab then return end
    clearEntryPoints()
    for _, lab in ipairs(labs or {}) do
        if lab.entry_x ~= 0 and lab.entry_y ~= 0 then
            activeLabs[lab.id] = lab
            createLabEntryPoint(lab)
        end
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if not Framework.GetIsPlayerLoaded() then return end
    Wait(3500)
    requestRuntimeLabSettings()
    loadLabs()
end)

AddEventHandler('origen:Client:OnPlayerLoaded', function()
    Wait(3000)
    requestRuntimeLabSettings()
    loadLabs()
end)

AddEventHandler('origen:Client:OnPlayerUnload', function()
    closeLabPanel()
    clearInteriorPoints()
    clearEntryPoints()
    exports[GetCurrentResourceName()]:ClearLabStashPoints()
    insideLab = nil
    _lastLoadTime = 0
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    closeLabPanel()
    -- closeLabPanel solo suelta si el panel del lab estaba abierto; los demas
    -- (portatil, admin, tiendas) tambien pueden tener el foco.
    SetNuiFocus(false, false)
    clearInteriorPoints()
    clearEntryPoints()
    exports[GetCurrentResourceName()]:ClearLabStashPoints()
end)

exports('IsGangLabOpen', function() return labPanelOpen end)
exports('CloseGangLab', function() closeLabPanel() end)
exports('GetInsideLab', function() return insideLab end)
