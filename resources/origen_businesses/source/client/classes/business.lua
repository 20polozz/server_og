Business = {}
Business.__index = Business
Business.Instances = {}
local isDancing = false
local isSitting = false

local function dbg(...)
    if Config and Config.Debug then
        print('[origen_businesses][garage][client]', ...)
    end
end

local GetPermissionCandidates = BusinessPermissions.Candidates

local function HasAnyPermission(permissions, candidates)
    if type(permissions) == "table" then
        if #permissions > 0 then
            for i = 1, #candidates do
                if lib.table.contains(permissions, candidates[i]) then
                    return true
                end
            end
            return false
        end

        for i = 1, #candidates do
            if permissions[candidates[i]] == true then
                return true
            end
        end
    end

    return false
end

local function MoneyWashInputDialog()
    if GetResourceState('org-input') == 'started' then
        local dialog = exports['org-input']:ShowInput({
            header = 'Lavado de dinero',
            submitText = 'Lavar',
            inputs = {
                {
                    type = 'number',
                    name = 'amount',
                    text = '¿Cuánto dinero quieres lavar?',
                    isRequired = true,
                    default = '1'
                }
            }
        })
        if dialog and dialog.amount ~= nil then
            return tonumber(dialog.amount)
        end
        return nil
    end

    local input = lib.inputDialog('Lavado de dinero', {
        { type = 'number', label = '¿Cuánto dinero quieres lavar?', required = true, min = 1, default = 1 }
    })
    if input and input[1] ~= nil then
        return tonumber(input[1])
    end
    return nil
end

local function OpenBusinessTuningMenu(businessId)
    local tuningConfig = Config and Config.Tuning or {}
    local system = tostring(tuningConfig.System or 'origen_customs')

    if system == 'origen_customs' then
        if GetResourceState('origen_customs') ~= 'started' then return false end
        exports['origen_customs']:Abrir({ negocio = businessId })
        return true
    elseif system == 'qb-mechanicjob' then
        if GetResourceState('qb-mechanicjob') ~= 'started' then return false end
        exports['qb-mechanicjob']:PaintCategories()
        return true
    elseif system == 'vms_tunning' then
        if GetResourceState('vms_tuning') ~= 'started' then return false end
        exports['vms_tuning']:openTuning(nil, true)
        return true
    elseif system == 'esx_tunning' then
        if GetResourceState('esx_tuning') ~= 'started' then return false end
        exports['esx_tuning']:OpenMenu()
        return true
    elseif system == 'okokTunning' then
        if GetResourceState('okokTuning') ~= 'started' then return false end
        TriggerServerEvent('okokTuning:openFreeMenu')
        return true
    end

    return false
end

function Business:StartPoleDance(coords)
    if isDancing then return end
    isDancing = true
    
    local ped = PlayerPedId()
    local anims = {
        { dict = "mini@strip_club@pole_dance@pole_dance1", anim = "pd_dance_01" },
        { dict = "mini@strip_club@pole_dance@pole_dance2", anim = "pd_dance_02" },
        { dict = "mini@strip_club@pole_dance@pole_dance3", anim = "pd_dance_03" }
    }
    
    local randomAnim = anims[math.random(1, #anims)]
    
    lib.requestAnimDict(randomAnim.dict)
    
    -- Teleport to coordinates
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(ped, coords.w)
    
    TaskPlayAnim(ped, randomAnim.dict, randomAnim.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    exports.origen_hud:setupControls({
        { key = 'X', text = 'Salir del punto' }
    })
    
    LocalPlayer.state:set('IsBusy', true, true)
    Custom.HideText()
    
    CreateThread(function()
        while isDancing do
            Wait(0)
            DisableControlAction(0, 73, true) -- X
            if IsDisabledControlJustPressed(0, 73) then
                isDancing = false
            end
            
            -- Disable movement and other controls
            DisableControlAction(0, 30, true) -- Move LR
            DisableControlAction(0, 31, true) -- Move UD
            DisableControlAction(0, 32, true) -- W
            DisableControlAction(0, 33, true) -- S
            DisableControlAction(0, 34, true) -- A
            DisableControlAction(0, 35, true) -- D
            DisableControlAction(0, 44, true) -- Q
            DisableControlAction(0, 46, true) -- E
            DisableControlAction(0, 38, true) -- E (Interaction)
        end
        
        ClearPedTasks(ped)
        exports.origen_hud:hideControls()
        LocalPlayer.state:set('IsBusy', false, true)
    end)
end

function Business:StartSitting(coords, seatKey)
    if isSitting then return end
    
    -- Check with server if seat is available
    local canSit = lib.callback.await('origen_businesses:cb:occupySeat', false, seatKey)
    if not canSit then
        Custom.Notify({
            title = 'Asiento',
            description = 'Este asiento ya está ocupado.',
            type = 'error'
        })
        return
    end
    
    isSitting = true
    
    local ped = PlayerPedId()
    
    local seatAnims = {
        { dict = "timetable@ron@ig_5_p3",            anim = "ig_5_p3_base" },
        { dict = "timetable@reunited@ig_10",          anim = "base_amanda" },
        { dict = "timetable@ron@ig_3_couch",          anim = "base" },
        { dict = "timetable@jimmy@mics3_ig_15@",      anim = "mics3_15_base_tracy" },
        { dict = "timetable@maid@couch@",             anim = "base" },
        { dict = "timetable@ron@ron_ig_2_alt1",       anim = "ig_2_alt1_base" },
        { dict = "sitcouch@joker",                    anim = "sitcouch_clip" },
    }
    
    local currentAnimIndex = 1
    
    local function playSeatAnim(index)
        local data = seatAnims[index]
        lib.requestAnimDict(data.dict)
        TaskPlayAnim(ped, data.dict, data.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    end
    
    -- Teleport to exact coordinates of the point
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(ped, coords.w)
    
    -- Freeze position so the ped stays exactly at the point without falling
    FreezeEntityPosition(ped, true)
    
    -- Play first animation
    playSeatAnim(currentAnimIndex)
    
    exports.origen_hud:setupControls({
        { key = '←', text = 'Anterior' },
        { key = '→', text = 'Siguiente' },
        { key = 'X', text = 'Levantarse' }
    })
    
    LocalPlayer.state:set('IsBusy', true, true)
    Custom.HideText()
    
    CreateThread(function()
        while isSitting do
            Wait(0)
            DisableControlAction(0, 73, true)  -- X
            DisableControlAction(0, 174, true) -- LEFT ARROW
            DisableControlAction(0, 175, true) -- RIGHT ARROW
            
            if IsDisabledControlJustPressed(0, 73) then
                isSitting = false
            end
            
            -- Left arrow - previous animation
            if IsDisabledControlJustPressed(0, 174) then
                currentAnimIndex = currentAnimIndex - 1
                if currentAnimIndex < 1 then
                    currentAnimIndex = #seatAnims
                end
                playSeatAnim(currentAnimIndex)
            end
            
            -- Right arrow - next animation
            if IsDisabledControlJustPressed(0, 175) then
                currentAnimIndex = currentAnimIndex + 1
                if currentAnimIndex > #seatAnims then
                    currentAnimIndex = 1
                end
                playSeatAnim(currentAnimIndex)
            end
            
            -- Disable movement and other controls
            DisableControlAction(0, 30, true) -- Move LR
            DisableControlAction(0, 31, true) -- Move UD
            DisableControlAction(0, 32, true) -- W
            DisableControlAction(0, 33, true) -- S
            DisableControlAction(0, 34, true) -- A
            DisableControlAction(0, 35, true) -- D
            DisableControlAction(0, 44, true) -- Q
            DisableControlAction(0, 46, true) -- E
            DisableControlAction(0, 38, true) -- E (Interaction)
        end
        
        -- Release seat on server
        TriggerServerEvent('origen_businesses:server:releaseSeat', seatKey)
        
        -- Unfreeze the player before clearing tasks
        FreezeEntityPosition(ped, false)
        
        ClearPedTasks(ped)
        exports.origen_hud:hideControls()
        LocalPlayer.state:set('IsBusy', false, true)
    end)
end

function Business.New(data)
    local self = setmetatable({}, Business)

    self.id = tostring(data.id)
    self.name = data.name
    self.label = data.label
    self.points = data.points or {}
    self.polyzone = data.polyzone or nil
    self.grades = data.grades or {}
    self.pointsGenerated = {}
    self.entities = {}
    self.blip = nil

    self.type = data.type or 'general'
    self.productSystem = data.productSystem == 'recipes' and 'recipes' or 'legacy'

    self:SetPoints()

    Business.Instances[self.id] = self
    return self
end

function Business:refuelVehicle(veh)
    if not veh or veh == 0 then return end
    FreezeEntityPosition(veh, true)
    local result = lib.progressBar({
        duration = 30000,
        label = 'Repostando vehículo...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true
        },
    })
    
    if result then
        local success, message = lib.callback.await('origen_businesses:cb:refuelVehicle', false, self.id)
        if success then
            -- Intentar usar exports de combustible con el formato adecuado
            if GetResourceState('origen_fuel') == 'started' then
                exports['origen_fuel']:CompleteFuel(veh)
            elseif GetResourceState('LegacyFuel') == 'started' then
                exports['LegacyFuel']:SetFuel(veh, 100.0)
            else
                SetVehicleFuelLevel(veh, 100.0)
                Entity(veh).state:set('fuel', 100.0, true)
            end
            Custom.Notify({title = 'Gasolinera', description = 'Vehículo repostado con éxito. El coste ($150) ha sido cargado al negocio.', type = 'success'})
        else
            Custom.Notify({title = 'Gasolinera', description = message, type = 'error'})
        end
    end
    FreezeEntityPosition(veh, false)
end

function Business.Get(id)
    if id == nil then
        return Business.Instances
    end
    return Business.Instances[tostring(id)]
end

function Business:SetPoints()
    self:ClearPoints()
    local business = self
    
    local managementPoint = nil
    
    -- local businessState = LocalPlayer.state.businesses
    -- local isEmployee = businessState and businessState[self.id]

    for i = 1, #self.points do
        local pData = self.points[i]

        -- En el sistema actual, los puntos TPV ni se crean en cliente: no hay
        -- caja, interacción ni pantalla hasta que administración active recetas.
        if pData.type ~= 'pos' or self.productSystem == 'recipes' then
        if pData.npc then
            lib.requestModel(pData.npc.model)
            local npc = CreatePed(4, pData.npc.model, pData.coords.x, pData.coords.y, pData.coords.z, pData.coords.w, false, true)
            
            SetEntityInvincible(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            FreezeEntityPosition(npc, true)
            SetModelAsNoLongerNeeded(pData.npc.model)
            
            pData.entity = npc
            self.entities[#self.entities + 1] = npc

            if Custom.SetNPCClohtes then
                Custom.SetNPCClohtes(npc, self.id)
            end
        end

        -- if isEmployee or pData.type == 'store' then
            local rawCoords = pData.coords
            local pointCoords
            if type(rawCoords) == 'vector4' or type(rawCoords) == 'vector3' then
                pointCoords = rawCoords
            elseif type(rawCoords) == 'table' then
                pointCoords = vector4(
                    tonumber(rawCoords.x) or 0.0,
                    tonumber(rawCoords.y) or 0.0,
                    tonumber(rawCoords.z) or 0.0,
                    tonumber(rawCoords.w) or 0.0
                )
            else
                pointCoords = vector4(0.0, 0.0, 0.0, 0.0)
            end

        --[[ La cámara de seguridad no es un sitio al que acercarse y pulsar E:
             no lleva marcador ni interacción, solo el objeto colgado en la
             pared. Se mira desde el panel (source/client/camaras.lua). ]]
        if pData.type == 'camera' then
            Camaras.RegistrarObjeto(self, i, pData, pointCoords)
        elseif pData.type == 'caja' or Config.Tienda.EsPuntoDeTarea(pData.type) then
            -- La caja y los sitios de las tareas los atienden tienda.lua y tareas.lua
        elseif pData.type ~= 'dj_zone' then
            -- Marker Point
            local markerPoint = lib.points.new({
                coords = pointCoords,
                distance = Config.Marker.Distance or 20.0,
            })

            function markerPoint:nearby()
                if not pData.npc then
                    -- No marker for asiento type
                    if pData.type == 'asiento' then return end
                    if pData.type == 'pos' then return end
                    -- El punto de carga no lleva marcador: es su poste (source/client/carga.lua)
                    if pData.type == 'carga' then return end

                    local isEmployee = LocalPlayer.state.businesses and LocalPlayer.state.businesses[business.id]
                    if pData.type ~= 'store' and pData.type ~= 'barra_de_baile' and pData.type ~= 'carga' and not isEmployee then return end
                    --[[ El marcador se pinta estando fichado o no: quien lo usa
                         tiene que poder VER dónde está el punto antes de fichar.
                         Quien corta por servicio es la interacción. ]]
                    if isEmployee and not business:HasPermission(BusinessPoints.RequierePermiso(pData)) then return end

                    local m = Config.Marker
                    DrawMarker(m.Type, pData.coords.x, pData.coords.y, pData.coords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, m.Size.x, m.Size.y, m.Size.z, m.Color.r, m.Color.g, m.Color.b, m.Color.a, m.BobUpAndDown, m.FaceCamera, 2, m.Rotate, nil, nil, false)
                end
            end
            self.pointsGenerated[#self.pointsGenerated + 1] = markerPoint

            -- El mueble de la cocina: aparece al acercarse y se va al alejarse.
            if pData.type == 'kitchen' then
                Cocina.RegistrarMueble(self, i, pData, pointCoords)
            elseif pData.type == 'pos' then
                BusinessPOS.Registrar(self, i, pData, pointCoords)
            end

            -- Interaction Point
            --[[ El punto de carga es un poste con colisión (04/10): ya no se
                 puede pisar el punto, y medido desde el suelo el metro y
                 medio se quedaba en poco más de uno alrededor. Se mide desde
                 la mitad del poste, a la altura del personaje. ]]
            local interactCoords = pointCoords
            if pData.type == 'carga' then
                interactCoords = vector3(pointCoords.x, pointCoords.y, pointCoords.z + 1.0)
            end

            --[[ Metro y medio desde el PERSONAJE es lo normal, y vale para
                 todo lo que se usa a pie. Pero el tuneo y el garaje se usan
                 sentado al volante: ahi el personaje va dentro del coche, y
                 desde el asiento del conductor hasta el punto —puesto donde
                 para el coche— hay mas de metro y medio en cuanto el coche es
                 un poco largo. De ahi el "solo tenemos un punto de tuneo
                 funcional": funcionaba el que estaba bien puesto por suerte y
                 los demas no llegaban nunca. Se mide mas ancho solo para esos
                 dos, que ademas son de empleado y avisan con su texto. ]]
            local CERCA_EN_COCHE = 4.0

            local interactPoint = lib.points.new({
                coords = interactCoords,
                -- La cocina se usa desde delante del mueble, no desde su centro.
                distance = pData.type == 'kitchen' and Config.Cocina.Distancia
                    or (pData.type == 'pos' and Config.POS.InteractionDistance)
                    or ((pData.type == 'tuning' or pData.type == 'garage') and CERCA_EN_COCHE)
                    or 1.5,
            })

            function interactPoint:onEnter()
                if pData.type == 'pos' and not BusinessPOS.DentroPolyzone(business, pointCoords) then
                    Custom.HideText()
                    return
                end
                local isEmployee = LocalPlayer.state.businesses and LocalPlayer.state.businesses[business.id]
                if pData.type ~= 'store' and pData.type ~= 'barra_de_baile' and pData.type ~= 'asiento' and pData.type ~= 'carga' and not isEmployee then return end
                if isEmployee and not business:HasPermission(BusinessPoints.RequierePermiso(pData)) then return end

                local labels = {
                    management = "Gestión del negocio",
                    stash = "Almacén",
                    safe = "Caja fuerte",
                    store = "Tienda",
                    garage = "Garaje de la empresa",
                    tuning = "Tuning de la empresa",
                    taller = "Taller",
                    crafting = "Mesa de fabricación",
                    storage = "Almacén personal",
                    conversion = "Lavado de dinero",
                    clothing = "Ropero",
                    compraventa = "Gestión de traspasos",
                    frigorifico = "Frigorífico",
                    dj = "Mesa de DJ",
                    barra_de_baile = "Barra de baile",
                    asiento = "Asiento",
                    carga = "Punto de carga",
                    kitchen = "Cocina",
                    pos = "Usar TPV",
                    drinks = "Bebidas",
                    assembly = "Mesa de montaje",
                    gas_station = "Gasolinera de la empresa",
                    album_card_create = "Crear carta (álbum)",
                    album_create = "Crear álbum",
                    album_pack_create = "Crear sobres"
                }

                Custom.DrawText(labels[pData.type] or "Interacción", 'E')
            end

            function interactPoint:onExit()
                Custom.HideText()
            end

            function interactPoint:nearby()
                if pData.type == 'pos' and not BusinessPOS.DentroPolyzone(business) then
                    Custom.HideText()
                    return
                end
                local isEmployee = LocalPlayer.state.businesses and LocalPlayer.state.businesses[business.id]
                if pData.type ~= 'store' and pData.type ~= 'barra_de_baile' and pData.type ~= 'asiento' and pData.type ~= 'carga' and not isEmployee then return end
                
                if isEmployee then
                    if not business:HasPermission(BusinessPoints.RequierePermiso(pData)) then return end
                    if BusinessPoints.RequiereServicio(pData) and LocalPlayer.state.isOnDuty ~= business.id then return end
                end

                local ped = PlayerPedId()
                local currentVehicle = GetVehiclePedIsIn(ped, false)
                local isDriver = currentVehicle ~= 0 and GetPedInVehicleSeat(currentVehicle, -1) == ped

                if pData.type == 'garage' then
                    Custom.DrawText(isDriver and 'Guardar vehículo' or 'Gestión de vehículos', 'E')
                elseif pData.type == 'tuning' then
                    Custom.DrawText('Abrir menú de tuneo', 'E')
                elseif pData.type == 'taller' then
                    Custom.DrawText('Taller', 'E')
                elseif pData.type == 'compraventa' then
                    Custom.DrawText('Gestionar Traspaso', 'E')
                end

                if IsControlJustReleased(0, 38) then
                    if pData.type == 'carga' then
                        Carga.Abrir(business.id, i)
                    elseif pData.type == 'stash' then
                        business:openStash(pData)
                    elseif pData.type == 'safe' then
                        business:openSafe(pData)
                    elseif pData.type == 'frigorifico' then
                        business:openFrigorifico(pData)
                    elseif pData.type == 'store' then
                        business:openStore()
                    elseif pData.type == 'management' then
                        business:OpenManagement()
                    elseif pData.type == 'clothing' then
                        business:openClothing()
                    elseif pData.type == 'conversion' then
                        business:openMoneyWash(pData)
                    elseif pData.type == 'garage' then
                        local ped = PlayerPedId()
                        local veh = GetVehiclePedIsIn(ped, false)
                        if veh ~= 0 then
                            local plate = GetVehicleNumberPlateText(veh)
                            local mods = lib.getVehicleProperties(veh)
                            mods.fuelLevel = GetVehicleFuelLevel(veh)
                            Custom.SaveVehicleHealth(veh)
                            lib.callback('origen_businesses:cb:storeBusinessVehicle', false, function(result)
                                if result.success then
                                    Custom.Notify({title = 'Garaje', description = result.message, type = 'success'})
                                    if DoesEntityExist(veh) then
                                        DeleteEntity(veh)
                                    end
                                else
                                    Custom.Notify({title = 'Garaje', description = result.message, type = 'error'})
                                end
                            end, { businessId = business.id, plate = plate, netId = NetworkGetNetworkIdFromEntity(veh), mods = mods })
                        else
                            --[[ Aqui habia un menu de en medio —"Gestion del
                                 Garaje"— con dos opciones: abrir el garaje o
                                 recuperar los perdidos. Eran dos clics para
                                 llegar a lo que casi siempre quieres, y ademas
                                 era un menu prestado (org-menu), que en este
                                 servidor no se usa.

                                 Ahora se abre el garaje directamente y los
                                 vehiculos perdidos van dentro, en su riel. ]]
                            business:abrirGarajeConPerdidos(pData.coords)
                        end
                    elseif pData.type == 'tuning' then
                        local ped = PlayerPedId()
                        local veh = GetVehiclePedIsIn(ped, false)
                        local isDriver = veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped
                        -- El taller propio también se abre a pie, con el coche al lado.
                        local aPie = tostring((Config.Tuning or {}).System or 'origen_customs') == 'origen_customs'

                        if not isDriver and not aPie then
                            Custom.Notify({
                                title = 'Tuneo',
                                description = 'Debes estar conduciendo un vehículo para abrir el menú de tuneo.',
                                type = 'error'
                            })
                            return
                        end

                        local opened = OpenBusinessTuningMenu(business.id)
                        if not opened then
                            Custom.Notify({
                                title = 'Tuneo',
                                description = 'El systema de tuneo no está disponible o no está configurado.',
                                type = 'error'
                            })
                        end
                    elseif pData.type == 'taller' then
                        business:OpenWorkshopMenu()
                    elseif pData.type == 'compraventa' then
                        --- Una tabla, no el tipo: es lo que espera, aunque no lo mire.
                        Compraventa.AbrirTraspaso({ businessId = business.id })
                    elseif pData.type == 'dj' then
                        if type(Business_OpenDJPanel) == 'function' then
                            Business_OpenDJPanel(business, pData)
                        end
                    elseif pData.type == 'storage' then
                        business:openPersonalStorage(pData)
                    elseif pData.type == 'barra_de_baile' then
                        if isDancing then return end
                        business:StartPoleDance(pointCoords)
                    elseif pData.type == 'asiento' then
                        if isSitting then return end
                        local seatKey = business.id .. ':' .. tostring(i)
                        business:StartSitting(pointCoords, seatKey)
                    elseif pData.type == 'kitchen' then
                        if business.productSystem == 'recipes' then
                            business:openRecipeCraftingMenu('kitchen')
                        else
                            Cocina.Abrir(business, pData)
                        end
                    elseif pData.type == 'drinks' then
                        if business.productSystem == 'recipes' then
                            business:openRecipeCraftingMenu('drinks')
                        else
                            business:openCraftingMenu(pData.type)
                        end
                    elseif pData.type == 'pos' then
                        BusinessPOS.Abrir(business, i)
                    elseif pData.type == 'assembly' or pData.type == 'crafting' then
                        business:openCraftingMenu(pData.type)
                    elseif pData.type == 'gas_station' then
                        local ped = PlayerPedId()
                        local veh = GetVehiclePedIsIn(ped, false)
                        local isDriver = veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped

                        -- Sin conductor no se pinta nada: antes salía el texto con
                        -- una tecla vacía («[] - Surtidor de Empresa»).
                        if isDriver then
                            Custom.DrawText('Repostar el vehículo (150 $)', 'E')
                            if IsControlJustReleased(0, 38) then
                                business:refuelVehicle(veh)
                            end
                        end
                    elseif pData.type == 'album_card_create' then
                        exports['origen_AlbumCards']:CreateCardMenu()
                    elseif pData.type == 'album_create' then
                        exports['origen_AlbumCards']:CreateAlbumMenu()
                    elseif pData.type == 'album_pack_create' then
                        exports['origen_AlbumCards']:CreatePackMenu()
                    end
                end
            end

            self.pointsGenerated[#self.pointsGenerated + 1] = interactPoint
        end

        -- DJ Zone: register as polyzone (independent of interaction points)
        if pData.type == 'dj_zone' then
            if type(Business_RegisterDJZone) == 'function' then
                Business_RegisterDJZone(business, pData)
            end
        end

        if pData.type == 'management' then
            managementPoint = pointCoords
        end
        -- end
        end
    end

    if managementPoint then
        local blipConfig = Config.BusinessBlips and Config.BusinessBlips[self.type] or (Config.BusinessBlips and Config.BusinessBlips['general'])
        if blipConfig then
            local label = tostring(self.label or "Negocio")
            if label == "" then label = "Negocio" end

            --[[ El local, en el mapa.

                 Ya no se crea un blip del juego: se registra el punto en
                 origen_map, que es de donde leen los mapas del servidor.

                 SOLO EN EL MINIMAPA, a proposito. El mapa grande —el del menu
                 de pausa y la pestaña de Ciudad del inventario— ya tiene su
                 capa de locales, que se la sirve el servidor con algo que
                 desde aqui no se sabe: si el local esta ABIERTO. Registrarlo
                 tambien alli seria enseñar cada negocio dos veces, una de
                 ellas sin estado.

                 El minimapa si lo necesita: es lo que antes le llegaba
                 rastreando este blip. ]]
            self.blip = 'negocio_' .. tostring(self.id)

            OrigenMapa.Poner(self.blip, {
                x = managementPoint.x, y = managementPoint.y, z = managementPoint.z,
                cat = 'locales',
                nombre = label,
                mapa = false,
            })
        end
    end

    if self.polyzone and type(Business_RegisterDJZone) == 'function' then
        if self.polyzone.points then
            Business_RegisterDJZone(self, self.polyzone)
        else
            for cid, zoneData in pairs(self.polyzone) do
                Business_RegisterDJZone(self, zoneData)
            end
        end
    end
end

function Business:ClearPoints()
    for i = 1, #self.pointsGenerated do
        self.pointsGenerated[i]:remove()
    end
    self.pointsGenerated = {}
    Cocina.QuitarMueblesDe(self.id)
    Camaras.QuitarObjetosDe(self.id)
    if BusinessPOS and BusinessPOS.QuitarDe then BusinessPOS.QuitarDe(self.id) end
    -- Los postes de carga se repasan ya: crear, mover o borrar un punto pasa
    -- siempre por aquí (SetPoints empieza limpiando)
    if Carga and Carga.Releer then Carga.Releer() end

    for i = 1, #self.entities do
        if DoesEntityExist(self.entities[i]) then
            DeleteEntity(self.entities[i])
        end
    end
    self.entities = {}
    
    if self.blip then
        OrigenMapa.Quitar(self.blip)
        self.blip = nil
    end

    return true
end

function Business:HasPermission(permission)
    local businessState = LocalPlayer.state.businesses
    if not businessState or not businessState[self.id] then return false end
    if not permission then return true end
    
    local gradeIndex = tostring(businessState[self.id])
    local grade = self.grades[gradeIndex]

    if not grade or not grade.permissions then return false end
    return HasAnyPermission(grade.permissions, GetPermissionCandidates(permission))
end

function Business:OpenManagement(isAdminMode)
    local data = lib.callback.await('origen_businesses:cb:getManagementData', false, self.id, isAdminMode == true)

    if not data.employee then
        Custom.Notify({
            title = 'Negocio',
            description = 'No se pudo obtener información del empleado',
            type = 'error'
        })
        return
    end
    
    SetNuiFocus(true, true)
    if type(StartBusinessPanelTabletAnim) == 'function' then
        StartBusinessPanelTabletAnim()
    end
    SendNUIMessage({
        action = 'openBusinessPanel',
        data = {
            business = data.business,
            employee = data.employee
        }
    })
end

--[[ El punto `taller` abre el mismo cuadro de mando del negocio, pero ya
     puesto en su pestaña. Es la pantalla de la oficina —órdenes, stock,
     tarifas—; la de diagnóstico se usa agachado junto al capó y es otra NUI, la
     de `origen_mechanic`. ]]
function Business:OpenWorkshop()
    self:OpenManagement()
    SendNUIMessage({ action = 'businessSwitchTab', data = { tab = 'taller' } })
end

--[[ El almacén de piezas del taller. No es un punto que se coloque: el
     servidor lo registra solo para cada negocio que tenga punto de taller, y
     hasta ahora no había manera de abrirlo —solo el panel lo listaba—, así que
     una pieza que sobraba no se podía devolver. ]]
function Business:openWorkshopStash()
    local stock = (Config.Taller and Config.Taller.Stock) or {}

    exports.origen_inventory:openInventory('stash', 'business_parts_' .. self.id, {
        label = 'Piezas del taller',
        slots = tonumber(stock.slots) or 80,
        maxweight = tonumber(stock.weight) or 600000,
    })
end

--[[ La revisión y el libro los pinta `origen_mechanic`, dueño del estado del
     coche. El permiso se mira aquí solo para avisar con claridad: quien decide
     es su servidor, que además comprueba que sigas junto al punto. ]]
function Business:RunMechanicAction(exportName)
    if GetResourceState('origen_mechanic') ~= 'started' then
        Custom.Notify({
            title = 'Taller',
            description = 'El sistema de mecánica no está disponible.',
            type = 'error'
        })
        return
    end

    if not self:HasPermission('repair_vehicles') then
        Custom.Notify({
            title = 'Taller',
            description = 'Tu rango no te deja revisar vehículos.',
            type = 'error'
        })
        return
    end

    CreateThread(function()
        exports.origen_mechanic[exportName]()
    end)
end

--[[ Las cosas que se hacen en el punto del taller. Con una sola tecla
     había que elegir una y dejar la otra sin sitio; el menú es el mismo
     `org-menu` que ya usan el garaje y la compraventa. Sin él, la tecla abre
     el cuadro de mando, que es lo que se busca casi siempre. ]]
function Business:OpenWorkshopMenu()
    if GetResourceState('org-menu') ~= 'started' then
        self:OpenWorkshop()
        return
    end

    --[[ `handler` y no `event`: es como enganchan todos los menús de este
         recurso, y un evento de red para esto lo dejaría disparable por
         cualquiera contra el almacén de cualquier negocio. ]]
    local menu = {
        {
            header = ('Taller | %s'):format(tostring(self.label or 'Negocio')),
            isMenuHeader = true
        },
        {
            header = 'Revisar vehículo',
            txt = 'Motor, piezas, mantenimientos y chapa del coche más cercano',
            icon = 'fa-solid fa-gauge-high',
            params = {
                handler = function()
                    self:RunMechanicAction('RevisarEnTaller')
                end
            }
        },
        {
            header = 'Libro de servicio',
            txt = 'Historial de reparaciones del coche más cercano',
            icon = 'fa-solid fa-book-open',
            params = {
                handler = function()
                    self:RunMechanicAction('UseServiceBook')
                end
            }
        },
        {
            header = 'Abrir el taller',
            txt = 'Órdenes de trabajo, stock y tarifas',
            icon = 'fa-solid fa-screwdriver-wrench',
            params = {
                handler = function()
                    self:OpenWorkshop()
                end
            }
        },
        {
            header = 'Almacén de piezas',
            txt = 'Guardar o sacar piezas a mano',
            icon = 'fa-solid fa-boxes-stacked',
            params = {
                handler = function()
                    --[[ El mismo permiso que pide el servidor para reponer:
                         quien no puede comprar tampoco anda suelto por el
                         almacén. ]]
                    if not self:HasPermission('manage_parts_stock') then
                        Custom.Notify({
                            title = 'Taller',
                            description = 'No tienes permiso para tocar el almacén de piezas.',
                            type = 'error'
                        })
                        return
                    end

                    self:openWorkshopStash()
                end
            }
        }
    }

    exports['org-menu']:openMenu(menu)
end

function Business:Delete()
    self:ClearPoints()
    Business.Instances[self.id] = nil
end

function Business.Reload(data)
    local found = false
    local dataId = tostring(data.id)
    for _, business in pairs(Business.Instances) do
        if tostring(business.id) == dataId then
            found = true
            business.name = data.name
            business.label = data.label
            business.points = data.points
            business.grades = data.grades
            business.polyzone = data.polyzone
            business.productSystem = data.productSystem == 'recipes' and 'recipes' or 'legacy'
            business:SetPoints()
        end
    end

    if not found then
        Business.New(data)
    end
end

function Business:openStash(data)
    exports.origen_inventory:openInventory('stash', 'business_stash_'..self.id, {
        label = 'Almacén',
        slots = tonumber(data and data.slots) or 50,
        maxweight = tonumber(data and data.weight) or 100000,
    })
end

--[[ La caja fuerte. Aqui ya no se compara nada: el cliente no tiene la clave
     (el servidor la quita de los puntos antes de mandarlos) y tampoco puede
     abrir el alijo por su cuenta. Se pide la clave con el dialogo del panel de
     negocio y la comprueba y abre el servidor. Ver source/client/caja_fuerte.lua
     y source/server/caja_fuerte.lua. ]]
function Business:openSafe(data)
    if data and data.hasPassword == false then
        Custom.Notify({ title = 'Caja Fuerte', description = 'Esta caja fuerte no tiene clave configurada.', type = 'error' })
        return
    end

    CajaFuerte.Pedir(self.id, self.label)
end

function Business:openPersonalStorage(data)
    local citizenid
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx_core' then
        citizenid = Framework.Functions.GetPlayerData().citizenid
    elseif Config.Framework == 'es_extended' then
        citizenid = Framework.GetPlayerData().identifier
    end
    
    if not citizenid then return end

    exports.origen_inventory:openInventory('stash', 'business_personal_' .. self.id .. '_' .. citizenid, {
        label = 'Almacén Personal',
        slots = tonumber(data and data.slots) or 20,
        maxweight = tonumber(data and data.weight) or 50000,
    })
end

function Business:openFrigorifico(data)
    exports.origen_inventory:openInventory('stash', 'business_frigorifico_' .. self.id)
end

function Business:openClothing()
    exports['origen_clothing']:openOutfitMenu(false)
end

function Business:openStore()
    local items = lib.callback.await('origen_businesses:cb:getStoreItems', false, self.id)
    if items == false then
        return Custom.Notify({ title = 'Tienda', description = 'Está cerrada: no hay nadie de servicio', type = 'error' })
    end
    local formattedItems = {}

    for k, item in pairs(items) do
        formattedItems[k] = {
            name = item.name,
            price = item.price,
            amount = item.amount,
            info = item.info or {},
            type = item.type,
            slot = k,
        }
    end

    -- exports.origen_inventory:RegisterShop('business_store_'..self.id, items)
    exports.origen_inventory:openInventory('shop', 'business_store_'..self.id, {
        label = 'Tienda',
        items = formattedItems,
        slots = #formattedItems,
        business = self.id,
    })
end

function Business:openMoneyWash(_data)
    local businessId = self.id
    local status = lib.callback.await('origen_businesses:cb:getMoneyWashStatus', false, { businessId = businessId })
    if not status or status.success ~= true then
        Custom.Notify({
            title = 'Lavado de dinero',
            description = (status and status.message) or 'No se pudo obtener el estado del lavado.',
            type = 'error'
        })
        return
    end

    if GetResourceState('org-menu') ~= 'started' then
        Custom.Notify({
            title = 'Lavado de dinero',
            description = 'No hay menú disponible (org-menu no iniciado).',
            type = 'error'
        })
        return
    end

    local menu = {
        {
            header = 'Lavado de dinero',
            isMenuHeader = true,
            icon = 'fa-solid fa-soap'
        }
    }

    if not status.active then
        menu[#menu + 1] = {
            header = 'Iniciar lavado',
            txt = 'Selecciona cuánto dinero negro quieres lavar.',
            icon = 'fa-solid fa-play',
            params = {
                handler = function()
                    local amount = MoneyWashInputDialog()
                    if not amount then return end
                    amount = math.floor(amount)
                    if amount <= 0 then return end

                    local started = lib.callback.await('origen_businesses:cb:startMoneyWash', false, {
                        businessId = businessId,
                        amount = amount
                    })

                    if not started or started.success ~= true then
                        Custom.Notify({
                            title = 'Lavado de dinero',
                            description = (started and started.message) or 'No se pudo iniciar el lavado.',
                            type = 'error'
                        })
                        return
                    end

                    Custom.Notify({
                        title = 'Lavado de dinero',
                        description = ('Lavado iniciado. Vuelve cuando termine para recoger tu dinero (%d%% comisión).'):format(tonumber(started.lossPercent or 0) or 0),
                        type = 'success'
                    })

                    self:openMoneyWash()
                end
            }
        }
    else
        local remainingMs = tonumber(status.remainingMs or 0) or 0
        local remainingSec = math.ceil(math.max(0, remainingMs) / 1000)

        menu[#menu + 1] = {
            header = 'Estado del lavado',
            txt = status.ready and 'Listo para recoger.' or ('En curso. Quedan ~%ds.'):format(remainingSec),
            icon = status.ready and 'fa-solid fa-check' or 'fa-solid fa-hourglass-half'
        }
        menu[#menu + 1] = {
            header = 'Detalles',
            txt = ('Sucia: $%d | Limpia: $%d | Comisión: %d%%'):format(
                tonumber(status.dirtyAmount or 0) or 0,
                tonumber(status.cleanAmount or 0) or 0,
                tonumber(status.lossPercent or 0) or 0
            ),
            icon = 'fa-solid fa-receipt'
        }

        if status.ready then
            menu[#menu + 1] = {
                header = 'Recoger dinero lavado',
                txt = ('Cobrar $%d en efectivo'):format(tonumber(status.cleanAmount or 0) or 0),
                icon = 'fa-solid fa-hand-holding-dollar',
                params = {
                    handler = function()
                        local collected = lib.callback.await('origen_businesses:cb:collectMoneyWash', false, { businessId = businessId })
                        if not collected or collected.success ~= true then
                            Custom.Notify({
                                title = 'Lavado de dinero',
                                description = (collected and collected.message) or 'No se pudo recoger el dinero.',
                                type = 'error'
                            })
                            return
                        end

                        Custom.Notify({
                            title = 'Lavado de dinero',
                            description = ('Has recogido $%d en efectivo.'):format(tonumber(collected.cleanedAmount or 0) or 0),
                            type = 'success'
                        })
                    end
                }
            }
        end
    end

    exports['org-menu']:openMenu(menu)
end

local function escribirDanioVehiculo(vehicle, props)
    if not DoesEntityExist(vehicle) then return end

    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end

    if type(props.tyreBurstCompletely) == 'table' then
        for tyre, burst in pairs(props.tyreBurstCompletely) do
            if burst then SetVehicleTyreBurst(vehicle, tonumber(tyre), true, 1000.0) end
        end
    end

    if type(props.tyresBurst) == 'table' then
        for tyre, burst in pairs(props.tyresBurst) do
            if burst then SetVehicleTyreBurst(vehicle, tonumber(tyre), false, 1000.0) end
        end
    end

    if type(props.windowsDamaged) == 'table' then
        for window, damaged in pairs(props.windowsDamaged) do
            if damaged then SmashVehicleWindow(vehicle, tonumber(window)) end
        end
    end

    if type(props.doorsBroken) == 'table' then
        for door, broken in pairs(props.doorsBroken) do
            if broken then SetVehicleDoorBroken(vehicle, tonumber(door), true) end
        end
    end
end

--[[ `lib.setVehicleProperties` ya escribe la salud y las roturas, pero el motor
     de fisica las pisa mientras sincroniza la entidad recien creada. Se repite
     la escritura medio segundo despues, cuando ya se ha asentado. ]]
local function aplicarEstadoVehiculo(vehicle, props)
    if not vehicle or vehicle == 0 or type(props) ~= 'table' or not next(props) then return end

    local ok = pcall(lib.setVehicleProperties, vehicle, props)
    if not ok then return end

    if props.fuelLevel then
        SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
    end

    escribirDanioVehiculo(vehicle, props)

    CreateThread(function()
        Wait(500)
        escribirDanioVehiculo(vehicle, props)
    end)
end

function Business:openGarage(garageCoords)
    local function normalizeCoords(coords)
        if not coords then return nil end
        local x, y, z, w = coords.x, coords.y, coords.z, coords.w
        if not x and type(coords) == 'vector4' then
            x, y, z, w = coords.x, coords.y, coords.z, coords.w
        end
        if not x and type(coords) == 'vector3' then
            x, y, z, w = coords.x, coords.y, coords.z, 0.0
        end
        if not x then return nil end
        return {
            x = tonumber(x),
            y = tonumber(y),
            z = tonumber(z),
            w = tonumber(w) or 0.0
        }
    end

    local function openNuiFallback()
        self:OpenManagement()
        CreateThread(function()
            Wait(120)
            SendNUIMessage({
                action = 'businessSwitchTab',
                data = 'vehicles'
            })
        end)
    end

    if GetResourceState('org-menu') ~= 'started' then
        openNuiFallback()
        return
    end

    local vehiclesResult = lib.callback.await('origen_businesses:cb:getBusinessVehicles', false, {
        businessId = self.id
    })

    if not vehiclesResult or vehiclesResult.success ~= true then
        Custom.Notify({
            title = 'Garaje',
            description = vehiclesResult and vehiclesResult.message or 'No se pudo cargar el garaje del negocio.',
            type = 'error'
        })
        return
    end

    local garageVehicles = vehiclesResult.garageVehicles or {}
    local menu = {
        {
            header = ('Garaje | %s'):format(tostring(self.label or 'Negocio')),
            isMenuHeader = true
        }
    }

    if #garageVehicles == 0 then
        menu[#menu + 1] = {
            header = 'No hay vehículos en el garaje',
            txt = 'Compra vehículos en la gestión del negocio.',
            icon = 'fa-solid fa-car'
        }
    else
        for i = 1, #garageVehicles do
            local row = garageVehicles[i]
            local vehicleId = tonumber(row.id)
            local isStored = tonumber(row.stored or 0) == 1
            local vehicleLabel = tostring(row.label or row.model or ('Vehículo #' .. tostring(vehicleId or i)))
            local plate = tostring(row.plate or 'SIN-MAT')
            local statusText = isStored and 'En garaje (listo para sacar)' or 'Fuera del garaje'

            local option = {
                header = vehicleLabel,
                txt = ('Matrícula: %s | %s'):format(plate, statusText),
                icon = isStored and 'fa-solid fa-car-side' or 'fa-solid fa-lock-open'
            }

            if isStored and vehicleId then
                option.params = {
                    handler = function()
                        dbg('request spawn', 'businessId=', self.id, 'vehicleId=', vehicleId)
                        local spawnResult = lib.callback.await('origen_businesses:cb:spawnBusinessVehicle', false, {
                            businessId = self.id,
                            vehicleId = vehicleId,
                            spawnCoords = normalizeCoords(garageCoords) or normalizeCoords(vehiclesResult.garagePoint)
                        })
                        dbg('spawn result ok=', spawnResult and spawnResult.success, 'payload=', spawnResult and json.encode(spawnResult) or 'nil')

                        if spawnResult and spawnResult.success then
                            local spawn = spawnResult.spawn or {}
                            local vehicleData = spawnResult.vehicle or {}
                            local modelName = tostring(vehicleData.model or row.model or '')
                            local plateValue = tostring(vehicleData.plate or plate or '')

                            local modelHash = joaat(modelName)
                            if modelName == '' or not IsModelValid(modelHash) then
                                dbg('invalid model', modelName, 'hash=', modelHash, 'isValid=', IsModelValid(modelHash))
                                Custom.Notify({
                                    title = 'Garaje',
                                    description = 'Modelo de vehículo inválido.',
                                    type = 'error'
                                })
                                return
                            end

                            DoScreenFadeOut(300)
                            while not IsScreenFadedOut() do Wait(0) end

                            lib.requestModel(modelHash)
                            local veh = CreateVehicle(modelHash, tonumber(spawn.x) or 0.0, tonumber(spawn.y) or 0.0, tonumber(spawn.z) or 0.0, tonumber(spawn.w) or 0.0, true, true)
                            dbg('create vehicle entity=', veh, 'model=', modelName, 'plate=', plateValue, 'spawn=', tonumber(spawn.x) or 0.0, tonumber(spawn.y) or 0.0, tonumber(spawn.z) or 0.0, tonumber(spawn.w) or 0.0)

                            if veh and veh ~= 0 and DoesEntityExist(veh) then
                                aplicarEstadoVehiculo(veh, vehicleData.mods)
                                --[[ La matricula se fuerza DESPUES de los mods:
                                     `lib.setVehicleProperties` escribe la que
                                     venga en el blob y la buena es la de la
                                     fila. ]]
                                SetVehicleNumberPlateText(veh, plateValue)
                                SetVehicleOnGroundProperly(veh)
                                SetVehicleDoorsLocked(veh, 1)
                                Entity(veh).state:set('businessVehicleId', vehicleId, true)
                                Entity(veh).state:set('businessId', tostring(self.id), true)
                                TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                                SetModelAsNoLongerNeeded(modelHash)

                                local createdNetId = NetworkGetNetworkIdFromEntity(veh)
                                dbg('confirm spawn', 'netId=', createdNetId, 'vehicleId=', vehicleId)
                                local confirm = lib.callback.await('origen_businesses:cb:confirmBusinessVehicleSpawn', false, {
                                    businessId = self.id,
                                    vehicleId = vehicleId,
                                    netId = createdNetId
                                })
                                dbg('confirm result', confirm and json.encode(confirm) or 'nil')

                                if not (confirm and confirm.success) then
                                    DeleteEntity(veh)
                                    DoScreenFadeIn(300)
                                    Custom.Notify({
                                        title = 'Garaje',
                                        description = confirm and confirm.message or 'No se pudo confirmar la salida del vehículo.',
                                        type = 'error'
                                    })
                                    return
                                end
                            else
                                DoScreenFadeIn(300)
                                Custom.Notify({
                                    title = 'Garaje',
                                    description = 'No se pudo crear el vehículo.',
                                    type = 'error'
                                })
                                return
                            end
                            DoScreenFadeIn(300)

                            Custom.Notify({
                                title = 'Garaje',
                                description = 'Vehículo sacado del garaje.',
                                type = 'success'
                            })
                        else
                            Custom.Notify({
                                title = 'Garaje',
                                description = spawnResult and spawnResult.message or 'No se pudo sacar el vehículo.',
                                type = 'error'
                            })
                        end
                    end
                }
            end

            menu[#menu + 1] = option
        end
    end

    menu[#menu + 1] = {
        header = 'Abrir gestión completa',
        txt = 'Abrir panel del negocio en pestaña Vehículos',
        icon = 'fa-solid fa-screwdriver-wrench',
        params = {
            handler = function()
                openNuiFallback()
            end
        }
    }

    exports['org-menu']:openMenu(menu)
end

--[[ Los vehiculos que estan fuera del garaje y se pueden recuperar pagando.
     Devuelve la lista tal cual la pinta la interfaz del garaje. ]]
function Business:listaDePerdidos()
    local resultado = lib.callback.await('origen_businesses:cb:getBusinessVehicles', false, {
        businessId = self.id
    })

    if not resultado or resultado.success ~= true then return nil, resultado and resultado.message end

    local perdidos = {}
    for _, fila in ipairs(resultado.garageVehicles or {}) do
        if tonumber(fila.stored or 0) == 0 then
            perdidos[#perdidos + 1] = {
                id = fila.id,
                label = fila.label or fila.model or 'Vehículo',
                model = fila.model,
                plate = fila.plate,
                brand = fila.brand,
            }
        end
    end

    return perdidos
end

--- Que negocio tiene el garaje abierto ahora mismo. Hace falta porque la
--- interfaz solo devuelve el id del vehiculo, sin decir de quien es el garaje.
local garajeAbierto = nil

--- Abre el garaje del negocio con la seccion de perdidos ya dentro.
function Business:abrirGarajeConPerdidos(coords)
    local perdidos, fallo = self:listaDePerdidos()

    garajeAbierto = self.id

    if fallo then
        Custom.Notify({ title = 'Garaje', description = fallo, type = 'error' })
        return
    end

    exports.origen_garages:openExternalGarage(self.id, coords, true, {
        label = 'Vehículos perdidos',
        price = Config.VehicleRecoveryPrice or 100,
        items = perdidos or {},
        evento = 'origen_businesses:client:recuperarVehiculo',
    })
end

--[[ Lo dispara la interfaz del garaje al elegir un vehiculo perdido. El garaje
     solo sabe devolver el id; el precio, el cobro y el mensaje son cosa
     nuestra. ]]
RegisterNetEvent('origen_businesses:client:recuperarVehiculo', function(vehicleId)
    local negocio = garajeAbierto and Business.Get(garajeAbierto)
    if not negocio then return end

    local respuesta = lib.callback.await('origen_businesses:cb:recoverBusinessVehicle', false, {
        businessId = negocio.id,
        vehicleId = vehicleId
    })

    Custom.Notify({
        title = 'Garaje',
        description = (respuesta and respuesta.message)
            or (respuesta and respuesta.success and 'Vehículo recuperado satisfactoriamente.')
            or 'No se pudo recuperar el vehículo.',
        type = (respuesta and respuesta.success) and 'success' or 'error'
    })

    if respuesta and respuesta.success then
        exports.origen_garages:actualizarPerdidos(negocio:listaDePerdidos() or {})
    end
end)

function Business:openRecoveryMenu(coords)
    local vehiclesResult = lib.callback.await('origen_businesses:cb:getBusinessVehicles', false, {
        businessId = self.id
    })

    if not vehiclesResult or vehiclesResult.success ~= true then
        Custom.Notify({
            title = 'Garaje',
            description = vehiclesResult and vehiclesResult.message or 'No se pudo cargar el garaje del negocio.',
            type = 'error'
        })
        return
    end

    local garageVehicles = vehiclesResult.garageVehicles or {}
    local menu = {
        {
            header = 'Vehículos Perdidos',
            isMenuHeader = true,
            icon = 'fa-solid fa-warehouse'
        }
    }

    local recoveryCount = 0
    for i = 1, #garageVehicles do
        local row = garageVehicles[i]
        if tonumber(row.stored or 0) == 0 then
            recoveryCount = recoveryCount + 1
            menu[#menu + 1] = {
                header = tostring(row.label or row.model or 'Vehículo'),
                txt = ('Matrícula: %s | Coste: $%d'):format(tostring(row.plate), Config.VehicleRecoveryPrice or 100),
                icon = 'fa-solid fa-rotate-left',
                params = {
                    handler = function()
                        local response = lib.callback.await('origen_businesses:cb:recoverBusinessVehicle', false, {
                            businessId = self.id,
                            vehicleId = row.id
                        })
                        if response.success then
                            Custom.Notify({
                                title = 'Garaje',
                                description = response.message or 'Vehículo recuperado satisfactoriamente.',
                                type = 'success'
                            })
                        else
                            Custom.Notify({
                                title = 'Garaje',
                                description = response.message or 'No se pudo recuperar el vehículo.',
                                type = 'error'
                            })
                        end
                    end
                }
            }
        end
    end

    if recoveryCount == 0 then
        return Custom.Notify({
            title = 'Garaje',
            description = 'No hay vehículos perdidos para recuperar.',
            type = 'info'
        })
    end

    exports['org-menu']:openMenu(menu)
end

function Business:openCraftingMenu(pointType)
    local crafts = lib.callback.await('origen_businesses:server:getBusinessCrafts', false, self.id, pointType)
    
    if not crafts or #crafts == 0 then
        Custom.Notify({
            title = 'Crafteos',
            description = 'No hay recetas disponibles en este punto.',
            type = 'error'
        })
        return
    end
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openCraftingPanel',
        data = {
            crafts = crafts,
            pointType = pointType,
            businessName = self.label,
            businessId = self.id
        }
    })
end

function Business:openRecipeCraftingMenu(pointType)
    local response = lib.callback.await('origen_businesses:server:getCraftRecipes', false, {
        businessId = self.id,
        pointType = pointType,
    })
    if type(response) ~= 'table' or not response.ok then
        Custom.Notify({
            title = pointType == 'kitchen' and 'Cocina' or 'Bebidas',
            description = response and response.error or 'No se pudieron cargar las recetas.',
            type = 'error',
        })
        return
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openCraftingPanel', data = {
        recipeMode = true,
        crafts = response.recipes or {},
        pointType = pointType,
        businessName = self.label,
        businessId = self.id,
        craftConfig = Config.Crafting,
        cookingMinigame = {
            minWaves = Config.Cocina.Minijuego.vueltas.min,
            maxWaves = Config.Cocina.Minijuego.vueltas.max,
            waveInterval = Config.Cocina.Minijuego.vueltas.cadaMs,
            waveDuration = Config.Cocina.Minijuego.msPorVuelta,
        },
    } })
end

function Business:startCrafting(craft)
    if lib.progressBar({
        duration = craft.time,
        label = 'Preparando ' .. craft.label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_ped'
        },
    }) then
        local success, message = lib.callback.await('origen_businesses:server:startCrafting', false, craft.id, 1)
        if success then
            Custom.Notify({
                title = 'Crafteos',
                description = 'Has terminado de preparar ' .. craft.label,
                type = 'success'
            })
        else
            Custom.Notify({
                title = 'Crafteos',
                description = message or 'No has podido terminar el crafteo.',
                type = 'error'
            })
        end
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if cache.resource ~= resourceName then return end
    for _, business in pairs(Business.Instances) do
        business:ClearPoints()
    end
end)

