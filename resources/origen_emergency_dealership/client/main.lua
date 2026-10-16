local Config = Config or {}

local insideGarage = false
local entrando = false -- entrada en curso (pantalla en negro): no se puede entrar ni salir otra vez
local displayVehicles = {}
local spawnedExtraProps = {}
local testDriveNetId = nil
local garagePropObject = nil
local isPlayerAdmin = false
local isLoadingScreenActive = false

local function ShowLoadingScreen(loadType, customData)
    isLoadingScreenActive = true
    pcall(function()
        if GetResourceState('origen_hud') == 'started' then
            exports.origen_hud:toggleHud(false)
        end
    end)
    CreateThread(function()
        while isLoadingScreenActive do
            DisplayRadar(false)
            Wait(0)
        end
    end)
    local payload = {
        action = 'showLoading',
        type = loadType or 'enter'
    }
    if customData and type(customData) == 'table' then
        for k, v in pairs(customData) do
            payload[k] = v
        end
    end
    SendNUIMessage(payload)
end

local function HideLoadingScreen()
    if not isLoadingScreenActive then return end
    isLoadingScreenActive = false
    SendNUIMessage({
        action = 'hideLoading'
    })
    pcall(function()
        if GetResourceState('origen_hud') == 'started' then
            exports.origen_hud:toggleHud(true)
        end
    end)
    DisplayRadar(true)
    DoScreenFadeIn(300)
end

-- Cargar IPLs / YMAPs del juego al iniciar
local ymaps = {
    "hei_sm_13",
    "hei_sm_13_garage",
    "hei_sm_13_in_garage",
    "hei_sm_13_milo_",
    "sm_13_in_garage",
    "sm_13_garage",
    "imp_sm_13_cargarage_a",
    "imp_sm_13_cargarage_b",
    "imp_sm_13_cargarage_c",
    "imp_sm_13_modgarage",
    "hei_dlc_garage_high_new"
}

CreateThread(function()
    for _, ipl in ipairs(ymaps) do
        RequestIpl(ipl)
    end
end)

-- =========================================================
-- Helpers de Deserialización y Sincronización
-- =========================================================

local function NormalizeJob(job)
    if not job then return 'police' end
    job = string.lower(job)
    if job == 'police' or job == 'sapd' or job == 'sheriff' or job == 'bcso' or job == 'fib' then
        return 'police'
    elseif job == 'ambulance' or job == 'ems' or job == 'doctor' or job == 'safd' then
        return 'ambulance'
    end
    return job
end

local function isJobAllowed(requiredJob, playerJob)
    if not requiredJob or requiredJob == "" then return true end
    if not playerJob or playerJob == "" then return false end
    if string.lower(requiredJob) == string.lower(playerJob) then return true end
    if NormalizeJob(requiredJob) == NormalizeJob(playerJob) then return true end
    return false
end

local function deserializeVehicles(vehs)
    local out = {}
    for i, v in ipairs(vehs or {}) do
        local coords = nil
        if v.coords and v.coords.x and v.coords.y and v.coords.z then
            coords = vec4(tonumber(v.coords.x) + 0.0, tonumber(v.coords.y) + 0.0, tonumber(v.coords.z) + 0.0, (tonumber(v.coords.w) or 0.0) + 0.0)
        end
        local perf = nil
        if v.performance and type(v.performance) == 'table' then
            perf = {
                engine = tonumber(v.performance.engine) or -1,
                brakes = tonumber(v.performance.brakes) or -1,
                transmission = tonumber(v.performance.transmission) or -1,
                suspension = tonumber(v.performance.suspension) or -1,
                armor = tonumber(v.performance.armor) or -1,
                turbo = (v.performance.turbo == true or v.performance.turbo == 1 or v.performance.turbo == 'true')
            }
        end
        out[i] = {
            model = tostring(v.model or ''):gsub('%s+', ''),
            label = v.label or v.model,
            price = tonumber(v.price) or 0,
            desc = v.desc or '',
            paymentSource = v.paymentSource or 'agent',
            minRank = type(v.minRank) == 'table' and v.minRank or (tonumber(v.minRank) or 0),
            divisions = type(v.divisions) == 'table' and v.divisions or {},
            licenses = type(v.licenses) == 'table' and v.licenses or {},
            jobs = type(v.jobs) == 'table' and v.jobs or {},
            restrictionType = v.restrictionType or 'none',
            maxPerOfficer = tonumber(v.maxPerOfficer) or 0,
            category = v.category or 'police',
            coords = coords,
            hidden = (v.hidden == true or v.hidden == 1 or v.hidden == 'true'),
            performance = perf
        }
    end
    return out
end

-- =========================================================
-- Gestión de Mapa / Prop Shell / Mobiliario
-- =========================================================

--- Carga y fija el MLO / IPL / YMAP en las coordenadas especificadas
local function loadGarageMap()
    local coords = Config.InsideGarageCenter

    for _, ipl in ipairs(ymaps) do
        RequestIpl(ipl)
    end

    local intId = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if intId and intId ~= 0 then
        PinInteriorInMemory(intId)
        LoadInterior(intId)
        RefreshInterior(intId)

        local timeout = 0
        while not IsInteriorReady(intId) and timeout < 100 do
            Wait(20)
            timeout = timeout + 1
        end
    end
end

--- Spawnea el prop/interior principal del garaje (Config.GarageProp)
local function spawnGarageProp()
    if garagePropObject and DoesEntityExist(garagePropObject) then
        DeleteEntity(garagePropObject)
        garagePropObject = nil
    end

    if not Config.GarageProp then return end

    local model = Config.GarageProp.model or 'origen_policegarage'
    local coords = Config.GarageProp.coords or Config.InsideGarageCenter
    local hash = type(model) == 'number' and model or joaat(model)

    -- Si el modelo no está en el juego no hay nada que esperar: antes se
    -- esperaban 3 s con la pantalla en negro en cada entrada.
    if not IsModelInCdimage(hash) then return end

    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 150 do
        Wait(20)
        timeout = timeout + 1
    end

    if HasModelLoaded(hash) then
        garagePropObject = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
        if not DoesEntityExist(garagePropObject) then
            garagePropObject = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
        end

        if DoesEntityExist(garagePropObject) then
            SetEntityHeading(garagePropObject, coords.w or 0.0)
            FreezeEntityPosition(garagePropObject, true)
            SetEntityCollision(garagePropObject, true, true)
            SetModelAsNoLongerNeeded(hash)
        end
    else
        print(('[qbx_emergency_dealership] ERROR: No se pudo cargar el modelo del garaje "%s" (Hash: %s)'):format(model, hash))
    end
end

--- Elimina el prop principal del garaje
local function deleteGarageProp()
    if garagePropObject and DoesEntityExist(garagePropObject) then
        DeleteEntity(garagePropObject)
        garagePropObject = nil
    end
end

--- Carga los props adicionales/mobiliario configurados en Config.Props
local function spawnExtraProps()
    for _, item in ipairs(spawnedExtraProps) do
        if item and DoesEntityExist(item) then
            DeleteEntity(item)
        end
    end
    spawnedExtraProps = {}

    if not Config.Props then return end

    for _, pData in ipairs(Config.Props) do
        local model = pData.model or pData[1]
        local coords = pData.coords or pData[2] or (type(pData[1]) == 'vector4' or type(pData[1]) == 'vector3' and pData[1])

        if model and coords then
            local hash = type(model) == 'number' and model or joaat(model)
            RequestModel(hash)
            local timeout = 0
            while not HasModelLoaded(hash) and timeout < 100 do
                Wait(10)
                timeout = timeout + 1
            end

            local obj = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
            if not DoesEntityExist(obj) then
                obj = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
            end

            if DoesEntityExist(obj) then
                SetEntityHeading(obj, coords.w or 0.0)
                FreezeEntityPosition(obj, true)
                SetEntityCollision(obj, true, true)
                SetModelAsNoLongerNeeded(hash)
                spawnedExtraProps[#spawnedExtraProps + 1] = obj
            end
        end
    end
end

--- Elimina los props adicionales/mobiliario
local function deleteExtraProps()
    for _, item in ipairs(spawnedExtraProps) do
        if item and DoesEntityExist(item) then
            DeleteEntity(item)
        end
    end
    spawnedExtraProps = {}
end

--- Limpia todos los vehículos de exposición y puntos de interacción
local function clearShowroomVehicles()
    for _, item in ipairs(displayVehicles) do
        if item.veh and DoesEntityExist(item.veh) then
            SetEntityAsMissionEntity(item.veh, true, true)
            DeleteVehicle(item.veh)
            DeleteEntity(item.veh)
        end
        if item.point then
            item.point:remove()
        end
    end
    displayVehicles = {}
end

-- =========================================================
-- Helper para Menú de Origen (org-menu / qb-menu)
-- =========================================================

local function OpenMenu(menuData)
    if GetResourceState('org-menu') == 'started' then
        exports['org-menu']:openMenu(menuData)
    elseif GetResourceState('qb-menu') == 'started' then
        exports['qb-menu']:openMenu(menuData)
    else
        local title = (menuData[1] and menuData[1].header) or 'Menú'
        local options = {}
        for _, item in ipairs(menuData) do
            if not item.isMenuHeader then
                options[#options + 1] = {
                    title = item.header,
                    description = item.txt,
                    icon = item.icon,
                    onSelect = function()
                        if item.params then
                            if item.params.isAction and item.params.event then
                                item.params.event()
                            elseif item.params.isServer and item.params.event then
                                TriggerServerEvent(item.params.event, item.params.args)
                            elseif item.params.event then
                                TriggerEvent(item.params.event, item.params.args)
                            end
                        end
                    end
                }
            end
        end
        lib.registerContext({
            id = 'emergency_dealership_inspect',
            title = title,
            options = options
        })
        lib.showContext('emergency_dealership_inspect')
    end
end

-- =========================================================
-- Menú de Inspección / Compra / Prueba de Vehículo
-- =========================================================

--- Abre el menú de inspección/compra de un vehículo de la lista
--- @param vehData table
local function openVehicleInspectMenu(vehData)
    local isSociety = (vehData.paymentSource == 'society')
    local payMethodText = isSociety and 'Financiado por Empresa (Comisaría)' or 'Pago Personal (Banco del Policía)'

    local rankText = ''
    local reqRank = type(vehData.minRank) == 'table' and (tonumber(vehData.minRank['police']) or 0) or (tonumber(vehData.minRank) or 0)
    if reqRank > 0 then
        rankText = (' | Rango mínimo %d'):format(reqRank)
    end

    local divText = ''
    if vehData.divisions and #vehData.divisions > 0 then
        divText = (' | Div: %s'):format(table.concat(vehData.divisions, ', '))
    end

    local licText = ''
    if vehData.licenses and #vehData.licenses > 0 then
        licText = (' | Lic: %s'):format(table.concat(vehData.licenses, ', '))
    end

    local maxText = ''
    if tonumber(vehData.maxPerOfficer) and vehData.maxPerOfficer > 0 then
        maxText = (' | Límite: %d/agente'):format(vehData.maxPerOfficer)
    end

    local perfText = ''
    if vehData.performance and type(vehData.performance) == 'table' then
        local parts = {}
        local p = vehData.performance
        if p.engine and p.engine >= 0 then parts[#parts + 1] = ('Motor N%d'):format(p.engine + 1) end
        if p.brakes and p.brakes >= 0 then parts[#parts + 1] = ('Frenos N%d'):format(p.brakes + 1) end
        if p.transmission and p.transmission >= 0 then parts[#parts + 1] = ('Trans N%d'):format(p.transmission + 1) end
        if p.suspension and p.suspension >= 0 then parts[#parts + 1] = ('Susp N%d'):format(p.suspension + 1) end
        if p.armor and p.armor >= 0 then parts[#parts + 1] = ('Blindaje %d%%'):format((p.armor + 1) * 20) end
        if p.turbo then parts[#parts + 1] = 'Turbo' end
        if #parts > 0 then
            perfText = (' | %s'):format(table.concat(parts, ', '))
        end
    end

    local buyTitle = isSociety
        and ('Adquirir por Cuenta de Empresa ($%s)'):format(vehData.price)
        or ('Comprar Vehículo ($%s)'):format(vehData.price)
    local buyDesc  = isSociety and 'Cargado a los fondos de la comisaría / sociedad' or 'Cargado a tu saldo bancario o efectivo'

    local menu = {
        {
            header = ('%s'):format(vehData.label),
            icon = 'fas fa-car',
            txt = ('Modelo: %s | Precio: $%s | %s%s%s%s%s%s'):format(
                vehData.model, vehData.price, payMethodText, rankText, divText, licText, maxText, perfText
            ) .. (vehData.desc and vehData.desc ~= '' and (' | %s'):format(vehData.desc) or ''),
            isMenuHeader = true
        },
        {
            header = buyTitle,
            icon = isSociety and 'fas fa-building-columns' or 'fas fa-money-bill-wave',
            txt = buyDesc,
            params = {
                isAction = true,
                event = function()
                    local confirmPrompt = isSociety
                        and ('¿Confirmas la adquisición del %s por $%s financiado con la cuenta de empresa?'):format(vehData.label, vehData.price)
                        or ('¿Confirmas la compra del %s por $%s cargado a tu cuenta bancaria?'):format(vehData.label, vehData.price)

                    local confirmMenu = {
                        {
                            header = 'Confirmar Adquisición',
                            icon = isSociety and 'fas fa-building-columns' or 'fas fa-money-bill-wave',
                            txt = confirmPrompt,
                            isMenuHeader = true
                        },
                        {
                            header = 'Confirmar Adquisición',
                            icon = 'fas fa-check',
                            txt = isSociety and 'Cargar a los fondos de la comisaría' or 'Cargar a tu cuenta personal',
                            params = {
                                isAction = true,
                                event = function()
                                    lib.notify({ title = 'Procesando Adquisición', description = 'Verificando requisitos y fondos...', type = 'inform' })
                                    
                                    ShowLoadingScreen('buy', {
                                        tag = 'TRAMITACIÓN DE VEHÍCULO EN CURSO',
                                        title = 'CONCESIONARIO POLICIAL',
                                        subtitle = 'TRAMITANDO ADQUISICIÓN POLICIAL',
                                        message = ('Tramitando matrícula de %s, verificando fondos y trasladando a plaza de entrega exterior...'):format(vehData.label or vehData.model),
                                        meta1Label = 'VEHÍCULO',
                                        meta1Val = (vehData.label or vehData.model):upper(),
                                        meta2Label = 'FINANCIACIÓN',
                                        meta2Val = isSociety and 'FONDOS COMISARÍA' or ('$%s (PERSONAL)'):format(vehData.price or 0),
                                        meta3Label = 'ENTREGA',
                                        meta3Val = 'PARKING EXTERIOR MRPD',
                                        tip = 'VEHÍCULO POLICIAL REGLAMENTARIO · ENTREGA EN EXTERIOR',
                                        statusText = 'Matriculando y asignando unidad...'
                                    })
                                    Wait(400)

                                    local res = lib.callback.await('qbx_emergency_dealership:server:buyVehicle', false, vehData.model, vehData.label, vehData.price)
                                    if res and res.success then
                                        clearShowroomVehicles()
                                        deleteExtraProps()
                                        deleteGarageProp()
                                        TriggerServerEvent('qbx_emergency_dealership:server:exitGarage')
                                        insideGarage = false

                                        local ped = cache.ped or PlayerPedId()

                                        if res.spawnCoords then
                                            RequestCollisionAtCoord(res.spawnCoords.x, res.spawnCoords.y, res.spawnCoords.z)
                                            SetEntityCoords(ped, res.spawnCoords.x, res.spawnCoords.y, res.spawnCoords.z, false, false, false, false)
                                            if res.spawnCoords.w then
                                                SetEntityHeading(ped, res.spawnCoords.w)
                                            end
                                        end

                                        if res.netId then
                                            -- lib.waitFor lanza un error si se agota: sin pcall
                                            -- la función moría aquí y la pantalla se quedaba negra.
                                            local okVeh, veh = pcall(lib.waitFor, function()
                                                if NetworkDoesNetworkIdExist(res.netId) then
                                                    local v = NetToVeh(res.netId)
                                                    if DoesEntityExist(v) then
                                                        return v
                                                    end
                                                end
                                            end, 'El vehículo no cargó a tiempo', 8000)

                                            if okVeh and veh and veh > 0 then
                                                SetVehicleNumberPlateText(veh, res.plate)
                                                if res.props then
                                                    pcall(function()
                                                        lib.setVehicleProperties(veh, res.props)
                                                    end)
                                                end
                                                if GetVehiclePedIsIn(ped, false) ~= veh then
                                                    TaskWarpPedIntoVehicle(ped, veh, -1)
                                                end
                                            end
                                        end

                                        Wait(800)
                                        HideLoadingScreen()
                                        lib.notify({ title = '¡Vehículo Entregado!', description = res.message, type = 'success' })
                                    else
                                        HideLoadingScreen()
                                        exports.qbx_core:Notify(res and res.message or 'No se pudo realizar la adquisición.', 'error')
                                    end
                                end
                            }
                        },
                        {
                            header = 'Cancelar',
                            icon = 'fas fa-times',
                            txt = 'Volver al vehículo',
                            params = {
                                isAction = true,
                                event = function()
                                    openVehicleInspectMenu(vehData)
                                end
                            }
                        }
                    }

                    OpenMenu(confirmMenu)
                end
            }
        },
        -- Prueba de Conducción (Desactivada a petición)
        {
            header = 'Cerrar',
            icon = 'fas fa-times',
            params = { isAction = true, event = function() end }
        }
    }

    OpenMenu(menu)
end

--- Spawnea simultáneamente todos los vehículos configurados en sus plazas
local function spawnShowroomVehicles()
    clearShowroomVehicles()

    for idx, vehData in ipairs(Config.Vehicles or {}) do
        if vehData.coords and not vehData.hidden and vehData.hidden ~= 1 and vehData.hidden ~= 'true' then
            local slotCoords = vehData.coords
            local hash = type(vehData.model) == 'number' and vehData.model or joaat(vehData.model)

            -- Un modelo del catálogo que no está en el juego costaba 3 s de
            -- pantalla negra por plaza al entrar.
            if not IsModelInCdimage(hash) then goto siguiente end

            RequestModel(hash)
            local timeout = 0
            while not HasModelLoaded(hash) and timeout < 150 do
                Wait(20)
                timeout = timeout + 1
            end

            if HasModelLoaded(hash) then
                RequestCollisionAtCoord(slotCoords.x, slotCoords.y, slotCoords.z)
                local veh = CreateVehicle(hash, slotCoords.x, slotCoords.y, slotCoords.z, slotCoords.w or 0.0, false, false)

                if DoesEntityExist(veh) then
                    SetEntityAsMissionEntity(veh, true, true)
                    SetEntityInvincible(veh, true)
                    SetVehicleDoorsLocked(veh, 2)
                    FreezeEntityPosition(veh, true)
                    SetEntityCoordsNoOffset(veh, slotCoords.x, slotCoords.y, slotCoords.z, false, false, false)
                    SetEntityHeading(veh, slotCoords.w or 0.0)
                    SetVehicleOnGroundProperly(veh)
                    FreezeEntityPosition(veh, true)
                    
                    -- Aplicar livery para que no salgan de serie
                    local livery = vehData.livery or 1
                    SetVehicleModKit(veh, 0)
                    SetVehicleLivery(veh, livery)
                    SetVehicleMod(veh, 48, livery, false)
                    
                    SetModelAsNoLongerNeeded(hash)

                    local point = lib.points.new({
                        coords = vec3(slotCoords.x, slotCoords.y, slotCoords.z),
                        distance = 2.5,
                        onEnter = function()
                            lib.showTextUI(('[E] - Inspeccionar / Comprar %s ($%s)'):format(vehData.label, vehData.price), { icon = 'car' })
                        end,
                        onExit = function()
                            lib.hideTextUI()
                        end,
                        nearby = function(self)
                            if IsControlJustPressed(0, 38) then
                                openVehicleInspectMenu(vehData)
                            end
                        end
                    })

                    displayVehicles[#displayVehicles + 1] = { veh = veh, point = point, data = vehData, index = idx }
                end
            else
                print(('[qbx_emergency_dealership] ERROR: No se pudo cargar el modelo del coche "%s" (Hash: %s)'):format(vehData.model, hash))
            end
        end
        ::siguiente::
    end
end

-- =========================================================
-- PANEL DE ADMINISTRACIÓN IN-GAME (BBDD PERMANENTE)
-- =========================================================

local openAdminMenu

--- Menú para listar vehículos disponibles que NO tienen plaza asignada todavía
local function openUnassignedVehiclesMenu(backMenu)
    local options = {}

    for idx, v in ipairs(Config.Vehicles or {}) do
        if not v.coords then
            options[#options + 1] = {
                title = ('%s ($%s)'):format(v.label, v.price),
                description = ('Modelo: %s\n%s'):format(v.model, v.desc or 'Sin plaza asignada.'),
                icon = 'car',
                onSelect = function()
                    local subOpts = {
                        {
                            title = 'Asignar Plaza (Mi Posición Actual)',
                            description = 'Colocar este vehículo exactamente donde estás parado y guardarlo en BBDD',
                            icon = 'map-pin',
                            onSelect = function()
                                local ped = cache.ped
                                local coords = GetEntityCoords(ped)
                                local heading = GetEntityHeading(ped)

                                local success, msg = lib.callback.await('qbx_emergency_dealership:server:saveVehicleSlot', false, idx, {
                                    x = coords.x,
                                    y = coords.y,
                                    z = coords.z,
                                    w = heading
                                })

                                if success then
                                    exports.qbx_core:Notify(msg, 'success')
                                else
                                    exports.qbx_core:Notify(msg or 'Error al asignar plaza.', 'error')
                                end
                                openAdminMenu()
                            end
                        },
                        {
                            title = 'Editar Precio y Datos',
                            description = 'Modificar el precio o nombre antes de asignar la plaza',
                            icon = 'pen-to-square',
                            onSelect = function()
                                local input = lib.inputDialog(('Editar %s'):format(v.label), {
                                    { type = 'input', label = 'Modelo de Spawn', default = v.model, required = true },
                                    { type = 'input', label = 'Nombre / Etiqueta', default = v.label, required = true },
                                    { type = 'number', label = 'Precio ($)', default = v.price, min = 0, required = true },
                                    { type = 'input', label = 'Descripción', default = v.desc or '' }
                                })

                                if input and input[1] and input[2] and input[3] then
                                    local success, msg = lib.callback.await('qbx_emergency_dealership:server:saveVehicle', false, idx, {
                                        model = input[1],
                                        label = input[2],
                                        price = input[3],
                                        desc = input[4] or ''
                                    })

                                    if success then
                                        exports.qbx_core:Notify(msg, 'success')
                                    else
                                        exports.qbx_core:Notify(msg or 'Error al guardar.', 'error')
                                    end
                                    openUnassignedVehiclesMenu(backMenu)
                                end
                            end
                        }
                    }

                    lib.registerContext({
                        id = 'ed_admin_unassigned_actions',
                        title = v.label,
                        menu = 'ed_admin_unassigned_vehs',
                        options = subOpts
                    })
                    lib.showContext('ed_admin_unassigned_actions')
                end
            }
        end
    end

    if #options == 0 then
        options[#options + 1] = {
            title = 'Todos los vehículos tienen plaza asignada',
            description = 'No quedan vehículos sin plaza. Puedes añadir nuevos modelos con el botón de creación.',
            icon = 'circle-check',
            disabled = true
        }
    end

    lib.registerContext({
        id = 'ed_admin_unassigned_vehs',
        title = ('Vehículos Disponibles (%d sin plaza)'):format(#options),
        menu = backMenu or 'ed_admin_main',
        options = options
    })
    lib.showContext('ed_admin_unassigned_vehs')
end

--- Menú de Gestión de Plazas de Entrega Exterior
local function openPurchaseSpawnsMenu()
    Config.Points = Config.Points or {}
    Config.Points.purchaseSpawns = Config.Points.purchaseSpawns or {}

    local options = {
        {
            title = 'Añadir Nueva Plaza de Entrega (Mi Posición Actual)',
            description = 'Crea una plaza exterior donde aparecerán los vehículos adquiridos',
            icon = 'plus-circle',
            onSelect = function()
                local ped = cache.ped or PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)

                local input = lib.inputDialog('Nueva Plaza de Entrega Exterior', {
                    { type = 'input', label = 'Etiqueta / Nombre', placeholder = 'Ej: Plaza Entrega Exterior #2', default = ('Plaza Entrega #%d'):format(#Config.Points.purchaseSpawns + 1), required = true },
                    { type = 'select', label = 'Departamento / Trabajo', default = 'police', options = {
                        { value = 'police', label = 'Policía (SAPD / Sheriff / BCSO)' },
                        { value = 'ambulance', label = 'Ambulancia (EMS / SAFD)' },
                        { value = '', label = 'Todos / Global' }
                    }, required = true }
                })

                if input and input[1] then
                    table.insert(Config.Points.purchaseSpawns, {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                        w = heading,
                        label = input[1],
                        job = input[2] or 'police'
                    })

                    local success, msg = lib.callback.await('qbx_emergency_dealership:server:savePoints', false, Config.Points)
                    if success then
                        exports.qbx_core:Notify('Plaza de entrega añadida con éxito.', 'success')
                    else
                        exports.qbx_core:Notify(msg or 'Error al guardar plazas.', 'error')
                    end
                    openPurchaseSpawnsMenu()
                else
                    openPurchaseSpawnsMenu()
                end
            end
        }
    }

    for idx, sp in ipairs(Config.Points.purchaseSpawns) do
        local coordStr = ('X: %.1f | Y: %.1f | Z: %.1f | H: %.1f°'):format(sp.x, sp.y, sp.z, sp.w or 0.0)
        local jobLabel = (sp.job and sp.job ~= '') and sp.job:upper() or 'GLOBAL'
        options[#options + 1] = {
            title = ('Plaza #%d: %s [%s]'):format(idx, sp.label or 'Sin nombre', jobLabel),
            description = coordStr,
            icon = 'warehouse',
            onSelect = function()
                lib.registerContext({
                    id = 'ed_admin_spawn_actions',
                    title = ('Plaza #%d - %s'):format(idx, sp.label or 'Plaza'),
                    menu = 'ed_admin_purchase_spawns',
                    options = {
                        {
                            title = 'Teletransportarme a este Punto',
                            description = 'Ir a las coordenadas de entrega exterior',
                            icon = 'person-walking-dashed-line-arrow-right',
                            onSelect = function()
                                local ped = cache.ped or PlayerPedId()
                                SetEntityCoords(ped, sp.x, sp.y, sp.z, false, false, false, false)
                                SetEntityHeading(ped, sp.w or 0.0)
                                exports.qbx_core:Notify(('Teletransportado a la Plaza #%d'):format(idx), 'inform')
                                openPurchaseSpawnsMenu()
                            end
                        },
                        {
                            title = 'Reubicar Plaza (Mi Posición Actual)',
                            description = 'Mueve esta plaza de entrega a tu posición y orientación actual',
                            icon = 'map-pin',
                            onSelect = function()
                                local ped = cache.ped or PlayerPedId()
                                local coords = GetEntityCoords(ped)
                                local heading = GetEntityHeading(ped)

                                Config.Points.purchaseSpawns[idx].x = coords.x
                                Config.Points.purchaseSpawns[idx].y = coords.y
                                Config.Points.purchaseSpawns[idx].z = coords.z
                                Config.Points.purchaseSpawns[idx].w = heading

                                local success, msg = lib.callback.await('qbx_emergency_dealership:server:savePoints', false, Config.Points)
                                if success then
                                    exports.qbx_core:Notify('Plaza de entrega reubicada con éxito.', 'success')
                                else
                                    exports.qbx_core:Notify(msg or 'Error al guardar.', 'error')
                                end
                                openPurchaseSpawnsMenu()
                            end
                        },
                        {
                            title = 'Eliminar Plaza de Entrega',
                            description = 'Elimina permanentemente esta plaza exterior',
                            icon = 'trash-can',
                            onSelect = function()
                                table.remove(Config.Points.purchaseSpawns, idx)
                                local success, msg = lib.callback.await('qbx_emergency_dealership:server:savePoints', false, Config.Points)
                                if success then
                                    exports.qbx_core:Notify('Plaza eliminada con éxito.', 'success')
                                else
                                    exports.qbx_core:Notify(msg or 'Error al eliminar.', 'error')
                                end
                                openPurchaseSpawnsMenu()
                            end
                        }
                    }
                })
                lib.showContext('ed_admin_spawn_actions')
            end
        }
    end

    lib.registerContext({
        id = 'ed_admin_purchase_spawns',
        title = 'Plazas de Entrega Exterior',
        menu = 'ed_admin_main',
        options = options
    })
    lib.showContext('ed_admin_purchase_spawns')
end

--- Menú Principal de Administración
openAdminMenu = function()
    local assignedCount = 0
    local unassignedCount = 0
    for _, v in ipairs(Config.Vehicles or {}) do
        if v.coords then
            assignedCount = assignedCount + 1
        else
            unassignedCount = unassignedCount + 1
        end
    end

    local options = {
        {
            title = ('Asignar Plaza a Vehículo ONX (%d Disponibles)'):format(unassignedCount),
            description = 'Selecciona cualquiera de los vehículos del pack ONX y colócalo en tu posición actual',
            icon = 'car-on',
            onSelect = function()
                openUnassignedVehiclesMenu('ed_admin_main')
            end
        },
        {
            title = 'Plazas de Entrega Exterior (Spawns)',
            description = 'Configurar o reubicar las plazas exteriores donde se entregan los vehículos comprados',
            icon = 'location-dot',
            onSelect = function()
                openPurchaseSpawnsMenu()
            end
        },
        {
            title = 'Crear Nuevo Vehículo Personalizado (Mi Posición Actual)',
            description = 'Añade cualquier otro modelo de spawn en tu ubicación exacta con guardado en BBDD',
            icon = 'plus-circle',
            onSelect = function()
                local ped = cache.ped
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)

                local input = lib.inputDialog('Añadir Plaza y Vehículo', {
                    { type = 'input', label = 'Modelo de Spawn', placeholder = 'Ej: onx_polbuff2', required = true },
                    { type = 'input', label = 'Nombre / Etiqueta', placeholder = 'Ej: Police Buffalo STX 2', required = true },
                    { type = 'number', label = 'Precio ($)', default = 30000, min = 0, required = true },
                    { type = 'input', label = 'Descripción', placeholder = 'Breve descripción del vehículo...' }
                })

                if input and input[1] and input[2] and input[3] then
                    local success, msg = lib.callback.await('qbx_emergency_dealership:server:addVehicle', false, {
                        model = input[1],
                        label = input[2],
                        price = input[3],
                        desc = input[4] or '',
                        coords = {
                            x = coords.x,
                            y = coords.y,
                            z = coords.z,
                            w = heading
                        }
                    })

                    if success then
                        exports.qbx_core:Notify(msg, 'success')
                    else
                        exports.qbx_core:Notify(msg or 'Error al añadir plaza.', 'error')
                    end
                    openAdminMenu()
                end
            end
        },
        {
            title = 'Recargar Exposición Actual',
            description = 'Refresca todos los vehículos en el garaje inmediatamente',
            icon = 'arrows-rotate',
            onSelect = function()
                if insideGarage then
                    spawnShowroomVehicles()
                    exports.qbx_core:Notify('Exposición recargada con éxito.', 'success')
                else
                    exports.qbx_core:Notify('No estás dentro del garaje exposición.', 'inform')
                end
                openAdminMenu()
            end
        }
    }

    -- Listar cada plaza asignada en el garaje
    local spotIndex = 0
    for idx, v in ipairs(Config.Vehicles or {}) do
        if v.coords then
            spotIndex = spotIndex + 1
            local coordStr = ('X: %.1f | Y: %.1f | Z: %.1f | H: %.1f°'):format(v.coords.x, v.coords.y, v.coords.z, v.coords.w or 0.0)
            options[#options + 1] = {
                title = ('Plaza #%d: %s ($%s)'):format(spotIndex, v.label, v.price),
                description = ('Modelo: %s | %s'):format(v.model, coordStr),
                icon = 'car-side',
                onSelect = function()
                    local subOpts = {
                        {
                            title = 'Editar Precio, Nombre o Modelo',
                            description = 'Modificar los datos de este vehículo en la Base de Datos',
                            icon = 'pen-to-square',
                            onSelect = function()
                                local input = lib.inputDialog(('Editar Plaza #%d - %s'):format(spotIndex, v.label), {
                                    { type = 'input', label = 'Modelo de Spawn', default = v.model, required = true },
                                    { type = 'input', label = 'Nombre / Etiqueta', default = v.label, required = true },
                                    { type = 'number', label = 'Precio ($)', default = v.price, min = 0, required = true },
                                    { type = 'input', label = 'Descripción', default = v.desc or '' }
                                })

                                if input and input[1] and input[2] and input[3] then
                                    local success, msg = lib.callback.await('qbx_emergency_dealership:server:saveVehicle', false, idx, {
                                        model = input[1],
                                        label = input[2],
                                        price = input[3],
                                        desc = input[4] or ''
                                    })

                                    if success then
                                        exports.qbx_core:Notify(msg, 'success')
                                    else
                                        exports.qbx_core:Notify(msg or 'Error al guardar.', 'error')
                                    end
                                    openAdminMenu()
                                end
                            end
                        },
                        {
                            title = 'Reubicar Plaza (Mi Posición Actual)',
                            description = 'Mover este vehículo a tu posición y orientación actual',
                            icon = 'map-pin',
                            onSelect = function()
                                local ped = cache.ped
                                local coords = GetEntityCoords(ped)
                                local heading = GetEntityHeading(ped)

                                local success, msg = lib.callback.await('qbx_emergency_dealership:server:saveVehicleSlot', false, idx, {
                                    x = coords.x,
                                    y = coords.y,
                                    z = coords.z,
                                    w = heading
                                })

                                if success then
                                    exports.qbx_core:Notify(msg, 'success')
                                else
                                    exports.qbx_core:Notify(msg or 'Error al actualizar posición.', 'error')
                                end
                                openAdminMenu()
                            end
                        },
                        {
                            title = 'Teletransportarme a esta Plaza',
                            description = 'Ir a la ubicación física de esta plaza',
                            icon = 'person-walking-dashed-line-arrow-right',
                            onSelect = function()
                                if v.coords then
                                    SetEntityCoords(cache.ped, v.coords.x, v.coords.y, v.coords.z, false, false, false, false)
                                    SetEntityHeading(cache.ped, v.coords.w or 0.0)
                                    exports.qbx_core:Notify(('Teletransportado a la Plaza #%d'):format(spotIndex), 'inform')
                                end
                                openAdminMenu()
                            end
                        },
                        {
                            title = 'Retirar de la Exposición (Quitar Plaza)',
                            description = 'Elimina la plaza del garaje pero mantiene el vehículo en la lista disponible',
                            icon = 'eye-slash',
                            onSelect = function()
                                local success, msg = lib.callback.await('qbx_emergency_dealership:server:saveVehicleSlot', false, idx, nil)
                                if success then
                                    exports.qbx_core:Notify(msg, 'success')
                                else
                                    exports.qbx_core:Notify(msg or 'Error al retirar plaza.', 'error')
                                end
                                openAdminMenu()
                            end
                        },
                        {
                            title = 'Eliminar Vehículo Permanentemente',
                            description = 'Borra este vehículo por completo de la base de datos',
                            icon = 'trash-can',
                            onSelect = function()
                                local confirm = lib.alertDialog({
                                    header = 'Eliminar Vehículo',
                                    content = ('¿Deseas eliminar permanentemente el vehículo %s (%s)?'):format(v.label, v.model),
                                    centered = true,
                                    cancel = true
                                })

                                if confirm == 'confirm' then
                                    local success, msg = lib.callback.await('qbx_emergency_dealership:server:deleteVehicle', false, idx)
                                    if success then
                                        exports.qbx_core:Notify(msg, 'success')
                                    else
                                        exports.qbx_core:Notify(msg or 'Error al eliminar.', 'error')
                                    end
                                    openAdminMenu()
                                end
                            end
                        }
                    }

                    lib.registerContext({
                        id = 'ed_admin_veh_slot_actions',
                        title = ('Plaza #%d - %s'):format(spotIndex, v.label),
                        menu = 'ed_admin_main',
                        options = subOpts
                    })
                    lib.showContext('ed_admin_veh_slot_actions')
                end
            }
        end
    end

    lib.registerContext({
        id = 'ed_admin_main',
        title = 'Panel de Plazas y Precios - Concesionario',
        options = options
    })
    lib.showContext('ed_admin_main')
end

-- =========================================================
-- Eventos de Sincronización en Tiempo Real y Carga
-- =========================================================


-- Forward declarations para que setupPoints pueda referenciarlas en sus closures
local enterGarage
local exitGarage

local entrancePoints = {}
local exitPoint = nil
local currentEntranceData = nil

local function setupPoints()
    if entrancePoints and #entrancePoints > 0 then
        for _, p in ipairs(entrancePoints) do p:remove() end
        entrancePoints = {}
    end
    if exitPoint then exitPoint:remove() exitPoint = nil end

    if Config.OutsideEntrances then
        for _, ent in ipairs(Config.OutsideEntrances) do
            local point = lib.points.new({
                coords = vec3(ent.x, ent.y, ent.z),
                distance = 2.0,
                entranceData = ent,
                onEnter = function(self)
                    local playerJob = ""
                    if GetResourceState('qbx_core') == 'started' then
                        local pData = exports.qbx_core:GetPlayerData()
                        if pData and pData.job then playerJob = pData.job.name end
                    elseif GetResourceState('qb-core') == 'started' then
                        local QBCore = exports['qb-core']:GetCoreObject()
                        local pData = QBCore.Functions.GetPlayerData()
                        if pData and pData.job then playerJob = pData.job.name end
                    end
                    
                    if isJobAllowed(self.entranceData.job, playerJob) then
                        lib.showTextUI('[E] - Entrar al Concesionario de Emergencias', { icon = 'warehouse' })
                    end
                end,
                onExit = function()
                    lib.hideTextUI()
                end,
                nearby = function(self)
                    local playerJob = ""
                    if GetResourceState('qbx_core') == 'started' then
                        local pData = exports.qbx_core:GetPlayerData()
                        if pData and pData.job then playerJob = pData.job.name end
                    elseif GetResourceState('qb-core') == 'started' then
                        local QBCore = exports['qb-core']:GetCoreObject()
                        local pData = QBCore.Functions.GetPlayerData()
                        if pData and pData.job then playerJob = pData.job.name end
                    end
                    
                    if isJobAllowed(self.entranceData.job, playerJob) then
                        DrawMarker(2, self.coords.x, self.coords.y, self.coords.z + 0.1, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 0, 0, 0, 200, false, true, 2, nil, nil, false)
                        if IsControlJustPressed(0, 38) then
                            enterGarage(self.entranceData)
                        end
                    end
                end
            })
            table.insert(entrancePoints, point)
        end
    end

    --[[ La puerta de salida funciona aunque el script no crea estar dentro.

         Quien se desconecta dentro vuelve a aparecer bajo tierra con
         insideGarage = false, y la puerta solo respondía con él a true: se
         quedaba encerrado. La puerta está en el interior, así que el que la
         tiene al lado está dentro. ]]
    if Config.InsideExitDoorCoords then
        exitPoint = lib.points.new({
            coords = Config.InsideExitDoorCoords.xyz,
            distance = 2.0,
            onEnter = function()
                if not entrando then
                    lib.showTextUI('[E] - Salir del Garaje', { icon = 'door-open' })
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            nearby = function(self)
                if entrando then return end
                DrawMarker(2, self.coords.x, self.coords.y, self.coords.z + 0.1, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 0, 0, 0, 200, false, true, 2, nil, nil, false)
                if IsControlJustPressed(0, 38) then
                    exitGarage()
                end
            end
        })
    end
end

local function applyPoints(pts)
    if not pts or type(pts) ~= 'table' then return end
    Config.Points = pts
    
    if pts.outsideEntrances and type(pts.outsideEntrances) == 'table' then
        Config.OutsideEntrances = {}
        for _, ent in ipairs(pts.outsideEntrances) do
            table.insert(Config.OutsideEntrances, {
                x = ent.x + 0.0, y = ent.y + 0.0, z = ent.z + 0.0, w = (ent.w or 0.0) + 0.0,
                label = ent.label, job = ent.job
            })
        end
    elseif pts.outsideEntrance then
        Config.OutsideEntrances = {
            { x = pts.outsideEntrance.x + 0.0, y = pts.outsideEntrance.y + 0.0, z = pts.outsideEntrance.z + 0.0, w = (pts.outsideEntrance.w or 0.0) + 0.0, label = "Entrada Principal", job = "" }
        }
    end
    if pts.insideExitDoor then
        Config.InsideExitDoorCoords = vec4(pts.insideExitDoor.x + 0.0, pts.insideExitDoor.y + 0.0, pts.insideExitDoor.z + 0.0, (pts.insideExitDoor.w or 0.0) + 0.0)
    end
    if pts.insideGarageCenter then
        Config.InsideGarageCenter = vec4(pts.insideGarageCenter.x + 0.0, pts.insideGarageCenter.y + 0.0, pts.insideGarageCenter.z + 0.0, (pts.insideGarageCenter.w or 0.0) + 0.0)
    end
    if pts.purchaseSpawns and #pts.purchaseSpawns > 0 then
        local sp = pts.purchaseSpawns[1]
        Config.PurchaseSpawnCoords = vec4(sp.x + 0.0, sp.y + 0.0, sp.z + 0.0, (sp.w or 0.0) + 0.0)
    end
    if pts.testDriveSpawns and #pts.testDriveSpawns > 0 then
        local sp = pts.testDriveSpawns[1]
        Config.TestDriveSpawnCoords = vec4(sp.x + 0.0, sp.y + 0.0, sp.z + 0.0, (sp.w or 0.0) + 0.0)
    end
    setupPoints()
end

RegisterNetEvent('qbx_emergency_dealership:client:syncPoints', function(pts)
    applyPoints(pts)
end)

local function fetchServerConfig()
    local res = lib.callback.await('qbx_emergency_dealership:server:getConfig', false)
    if res then
        if res.vehicles then
            Config.Vehicles = deserializeVehicles(res.vehicles)
        end
        if res.points then
            applyPoints(res.points)
        end
        if res.isAdmin ~= nil then
            isPlayerAdmin = res.isAdmin
        end
    end
end

CreateThread(function()
    setupPoints()
    Wait(1000)
    fetchServerConfig()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    fetchServerConfig()
end)

RegisterNetEvent('qbx_emergency_dealership:client:syncVehicles', function(serializedVehicles)
    if serializedVehicles then
        Config.Vehicles = deserializeVehicles(serializedVehicles)
    end

    if insideGarage then
        spawnShowroomVehicles()
    end
end)

-- =========================================================
-- Entrada / Salida del Garaje
-- =========================================================

--- Entra al garaje exposición
--[[ Entrar, a prueba de las veces que "no dejaba entrar".

     - Sin guarda, un segundo E durante el negro lanzaba otra entrada a la vez:
       dos tandas de coches de exposición, y la primera ya no se borraba nunca.
     - El jugador no se congelaba: caía por el suelo si el interior tardaba más
       de 0,6 s en tener colisión, y acababa en la calle o en el vacío.
     - Si algo fallaba a medio camino, la pantalla se quedaba en negro. ]]
enterGarage = function(entData)
    if insideGarage or entrando then return end
    if not Config.InsideGarageCenter then return end
    entrando = true
    currentEntranceData = entData
    lib.hideTextUI()

    local ped = cache.ped or PlayerPedId()
    ShowLoadingScreen('enter', {
        tag = 'SISTEMA DE GESTIÓN DE FLOTA',
        title = 'GARAJE DEPARTAMENTAL',
        subtitle = 'ACCEDIENDO A LA FLOTA POLICIAL',
        message = 'Sincronizando vehículos de dotación reglamentaria, equipamiento y plazas de exposición...',
        meta1Label = 'UBICACIÓN',
        meta1Val = 'MRPD · PLANTA INFERIOR',
        meta2Label = 'ESTADO',
        meta2Val = 'ACCESO AUTORIZADO',
        meta3Label = 'CUERPO',
        meta3Val = 'POLICÍA DE LOS SANTOS',
        tip = 'COMISARÍA MRPD · CUERPO POLICIAL DE LOS SANTOS',
        statusText = 'Cargando flota policial...'
    })
    Wait(400)

    local ok, err = pcall(function()
        TriggerServerEvent('qbx_emergency_dealership:server:enterGarage')

        local c = Config.InsideGarageCenter
        FreezeEntityPosition(ped, true)
        SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, false)
        SetEntityHeading(ped, c.w)

        loadGarageMap()
        spawnGarageProp()
        spawnExtraProps()

        local hasta = GetGameTimer() + 5000
        while GetGameTimer() < hasta do
            RequestCollisionAtCoord(c.x, c.y, c.z)
            if HasCollisionLoadedAroundEntity(ped) then break end
            Wait(50)
        end

        spawnShowroomVehicles()
        insideGarage = true
    end)

    FreezeEntityPosition(ped, false)
    entrando = false

    if not ok then
        print(('[origen_emergency_dealership] Error al entrar al garaje: %s'):format(tostring(err)))
    end

    Wait(600)
    HideLoadingScreen()

    if not ok then return end

    lib.notify({
        title = 'Garaje Concesionario de Emergencias',
        description = 'Acércate a cualquier vehículo expuesto para inspeccionarlo, probarlo o comprarlo.',
        type = 'inform'
    })
end

--- Sale del garaje exposición al exterior
--- Entrada exterior a la que devolver a quien sale sin haber entrado por una
--- (comando, o reconectado dentro): la de su cuerpo si la hay.
local function entradaPorDefecto()
    local lista = Config.OutsideEntrances or {}
    local pData = GetResourceState('qbx_core') == 'started' and exports.qbx_core:GetPlayerData() or nil
    local job = pData and pData.job and pData.job.name or ''
    for _, ent in ipairs(lista) do
        if ent.job and ent.job ~= '' and isJobAllowed(ent.job, job) then return ent end
    end
    return lista[1]
end

--- Quita todo lo local del garaje sin mover al jugador.
local function limpiarGaraje()
    clearShowroomVehicles()
    deleteExtraProps()
    deleteGarageProp()
    insideGarage = false
end

exitGarage = function()
    if entrando then return end

    ShowLoadingScreen('exit', {
        tag = 'DESPLIEGUE OPERATIVO',
        title = 'GARAJE DEPARTAMENTAL',
        subtitle = 'REGRESANDO A PATRULLAJE',
        message = 'Guardando estado de la flota, cerrando asignación y regresando al exterior de comisaría...',
        meta1Label = 'DESTINO',
        meta1Val = 'LOS SANTOS · EXTERIOR MRPD',
        meta2Label = 'ESTADO',
        meta2Val = 'EN SERVICIO ACTIVO',
        meta3Label = 'CANAL RADIO',
        meta3Val = 'FRECUENCIA 1 POLICÍA',
        tip = 'COMISARÍA MRPD · PATRULLAJE ACTIVO SAN ANDREAS',
        statusText = 'Saliendo al exterior...'
    })
    Wait(400)

    limpiarGaraje()
    TriggerServerEvent('qbx_emergency_dealership:server:exitGarage')

    local ped = cache.ped or PlayerPedId()
    local destino = currentEntranceData or entradaPorDefecto()
    if destino then
        RequestCollisionAtCoord(destino.x, destino.y, destino.z)
        SetEntityCoords(ped, destino.x, destino.y, destino.z, false, false, false, false)
        SetEntityHeading(ped, destino.w or 0.0)
    end
    currentEntranceData = nil

    Wait(600)
    HideLoadingScreen()
end

--[[ Vigilante: si "está dentro" pero ya no está en el garaje (murió y
     reapareció en el hospital, un admin lo teletransportó, /tpm...), se limpia.
     Antes insideGarage se quedaba a true para siempre y la entrada no volvía a
     responder hasta reconectar: el "a veces no deja entrar". ]]
CreateThread(function()
    while true do
        Wait(2000)
        if insideGarage and not entrando and Config.InsideGarageCenter then
            -- El garaje está justo debajo de MRPD (~100 m en vertical), así
            -- que la altura cuenta aparte: en la puerta de la comisaría la
            -- distancia en línea recta no llega a 120 m.
            local c = Config.InsideGarageCenter
            local p = GetEntityCoords(cache.ped or PlayerPedId())
            if #(p.xy - vec2(c.x, c.y)) > 80.0 or math.abs(p.z - c.z) > 20.0 then
                limpiarGaraje()
                currentEntranceData = nil
            end
        end
    end
end)

-- Registro de comandos de entrada al concesionario
for _, cmd in ipairs(Config.Commands or { 'garajepolicia' }) do
    RegisterCommand(cmd, function()
        enterGarage()
    end, false)
end

-- Registro de comandos de administración in-game
for _, cmd in ipairs(Config.AdminCommands or { 'edadmin', 'garajeadmin', 'emergencydealershipadmin' }) do
    RegisterCommand(cmd, function()
        if isPlayerAdmin then
            openAdminMenu()
        else
            exports.qbx_core:Notify('No tienes permisos de administrador.', 'error')
        end
    end, false)
end

-- Limpieza al reiniciar o detener el recurso
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    HideLoadingScreen()
    clearShowroomVehicles()
    deleteExtraProps()
    deleteGarageProp()
end)
