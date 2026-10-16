local debug = Debug.new(Config.Debug)
local locationBlips = {}
local locationPoints = {}
local currentTextUI = nil

local dbg = Debug:new({ enabled = Config.Debug })

local function GetLocationConfig(locationType)
    return Config.Locations.Types[locationType]
end

local function ResolveLocationType(locationId, locationData)
    local t = locationData and locationData.type or nil
    if t and Config.Locations.Types[t] then
        return t
    end

    local id = tostring(locationId or ''):lower()
    if id:find('personal_stash') then
        return 'personal_stash'
    elseif id:find('garage') then
        return 'garage'
    elseif id:find('clothing') then
        return 'clothing'
    elseif id:find('bank') then
        return 'bank'
    end

    return 'stash'
end

local function ResolveCoords(locationData)
    if locationData.x and locationData.y and locationData.z then
        return locationData
    end
    local src = locationData.coords or locationData.position or locationData.pos
    if type(src) == 'table' then
        locationData.x = src.x or src[1]
        locationData.y = src.y or src[2]
        locationData.z = src.z or src[3]
        locationData.h = locationData.h or locationData.heading or src.h or src.w or src[4]
    end
    return locationData
end

--[[ El local, en el mapa.

     Ya no es un blip del juego: se registra el punto en origen_map y de ahi lo
     leen los tres mapas del servidor. El interruptor de `config.blip.enabled`
     sigue mandando, y el color y el sprite tambien —pasan por OrigenMapa.Color
     y OrigenMapa.Icono, que traducen el numero de GTA—; la escala si deja de
     pintar nada. El 473 de los almacenes no tiene dibujo propio en esa tabla,
     asi que esos siguen con el de la categoria.

     Devuelve la CLAVE del punto, no un handle: es lo que hay que guardar para
     poder quitarlo despues. ]]
local function CreateLocationBlip(locationId, locationData)
    local locationType = ResolveLocationType(locationId, locationData)
    local config = GetLocationConfig(locationType)
    if not config or not config.blip or not config.blip.enabled then return nil end

    local clave = 'local_' .. tostring(locationId)

    OrigenMapa.Poner(clave, {
        x = locationData.x, y = locationData.y, z = locationData.z,
        cat = 'illegal',
        --- El sprite, igual que el color: traducido, y si no esta en la tabla de
        --- OrigenMapa.Icono, manda el de la categoria.
        icono = OrigenMapa.Icono(config.blip.sprite),
        nombre = locationData.name or locale:t(config.label) or locationId,
        --- Del numero de GTA al color de la chincheta. Un numero que no este en
        --- la tabla de OrigenMapa.Color deja mandar al de la categoria.
        color = OrigenMapa.Color(config.blip.color),
    })

    return clave
end

local function RemoveLocationBlip(clave)
    if clave then OrigenMapa.Quitar(clave) end
end

local function CreateLocationPoint(locationId, locationData)
    local locationType = ResolveLocationType(locationId, locationData)
    local config = GetLocationConfig(locationType)
    if not config then
        debug:log('location', 'No config for type:', locationType, 'id:', locationId)
        return nil
    end

    -- Resolver offset: 'offset' tiene precedencia sobre el legacy 'offsetZ'.
    -- Así configs viejas con solo offsetZ siguen funcionando sin cambios.
    local function resolveMarkerOffset(m)
        if m.offset then
            return {
                x = m.offset.x or 0.0,
                y = m.offset.y or 0.0,
                z = m.offset.z or 0.0,
            }
        end
        return { x = 0.0, y = 0.0, z = m.offsetZ or 0.0 }
    end

    local configCopy = {
        label = locale:t(config.label or locationId),
        marker = config.marker and {
            type          = config.marker.type,
            offset        = resolveMarkerOffset(config.marker),
            scale         = { x = config.marker.scale.x, y = config.marker.scale.y, z = config.marker.scale.z },
            color         = { r = config.marker.color.r,  g = config.marker.color.g,  b = config.marker.color.b, a = config.marker.color.a },
            bobUpAndDown  = config.marker.bobUpAndDown == true,
            faceCamera    = config.marker.faceCamera ~= false,
            rotationOrder = config.marker.rotationOrder or 2,
            rotate        = config.marker.rotate == true,
        } or nil,
        default     = config.default,
        onInteract  = config.onInteract,
        requiredPermission = config.requiredPermission
    }

    local coords = vector3(locationData.x, locationData.y, locationData.z)
    local point  = lib.points.new({
        coords       = coords,
        distance     = Config.Locations.DrawDistance,
        locationId   = locationId,
        locationData = locationData,
        locationType = locationType,
        config       = configCopy
    })

    function point:onEnter() end

    function point:onExit()
        if currentTextUI == self.locationId then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    function point:nearby()
        local dist = #(GetEntityCoords(PlayerPedId()) - self.coords)

        -- Marker
        if dist < Config.Locations.MarkerDrawDistance and self.config.marker then
            local m  = self.config.marker
            local mo = m.offset
            DrawMarker(
                m.type,
                self.coords.x + mo.x, self.coords.y + mo.y, self.coords.z + mo.z,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                m.scale.x, m.scale.y, m.scale.z,
                m.color.r, m.color.g, m.color.b, m.color.a,
                m.bobUpAndDown, m.faceCamera, m.rotationOrder, m.rotate,
                nil, nil, false
            )
        end

        -- Interact prompt
        if dist < Config.Locations.InteractDistance then
            if currentTextUI ~= self.locationId then
                HelpText.ShowHelpText('[E] ' .. self.config.label)
                currentTextUI = self.locationId
            end
            if IsControlJustReleased(0, 38) then
                HelpText.HideHelpText()
                currentTextUI = nil
                HandleLocationInteraction(self.locationId, self.locationData, self.locationType)
            end
        elseif currentTextUI == self.locationId then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    return point
end

local function ClearAllLocations()
    for _, blip in pairs(locationBlips) do RemoveLocationBlip(blip) end
    locationBlips = {}
    for _, point in pairs(locationPoints) do point:remove() end
    locationPoints = {}
    if currentTextUI then
        HelpText.HideHelpText()
        currentTextUI = nil
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then ClearAllLocations() end
end)

local function UpdateLocations(locations)
    ClearAllLocations()
    if not locations or type(locations) ~= 'table' then return end

    local count = 0
    for locationId, locationData in pairs(locations) do
        if type(locationData) == 'table' then
            locationData = ResolveCoords(locationData)
            if locationData.x and locationData.y and locationData.z then
                locationData.type = ResolveLocationType(locationId, locationData)
                locationBlips[locationId]  = CreateLocationBlip(locationId, locationData)
                locationPoints[locationId] = CreateLocationPoint(locationId, locationData)
                count = count + 1
            else
                print('[origen_ilegal][location] missing coords for:', locationId)
            end
        end
    end

    debug:log('location', 'Loaded', count, 'locations')
end

local function HasLocationPermission(requiredPermission)
    if not playerGang or not playerGang.member then return false end
    if not requiredPermission then return true end
    if playerGang.is_leader then return true end
    -- Primero los permisos que el servidor ya manda calculados para este
    -- jugador; buscar su rango en la tabla es el camino de reserva (las
    -- claves pueden llegar como texto y entonces no se encontraba).
    local mios = playerGang.player_permissions
    if type(mios) == 'table' and mios[requiredPermission] == true then return true end
    local id = playerGang.member.rank_id
    local rank = playerGang.ranks and (playerGang.ranks[id] or playerGang.ranks[tostring(id)] or playerGang.ranks[tonumber(id) or -1])
    return rank and rank.permissions and rank.permissions[requiredPermission] or false
end

function HandleLocationInteraction(locationId, locationData, locationType)
    local config = GetLocationConfig(locationType)
    if not config then return end

    if config.requiredPermission and not HasLocationPermission(config.requiredPermission) then
        Notify.SendNotify(locale:t('notify.no_permission'), 'error')
        return
    end

    local uniqueId = 'gang_' .. playerGang.id .. '_' .. locationId

    if config.default then
        if locationType == 'stash' then
            OpenStash(uniqueId, locationData)
        elseif locationType == 'personal_stash' then
            OpenPersonalStash(uniqueId, locationData)
        elseif locationType == 'garage' then
            OpenGarage(uniqueId, locationData)
        elseif locationType == 'clothing' then
            Internal.OpenClothingMenu(uniqueId, locationData)
        elseif locationType == 'bank' then
            OpenGangBank(uniqueId, locationData)
        elseif locationType == 'management' then
            OpenQuickMenu()
        end
    elseif config.onInteract and type(config.onInteract) == 'function' then
        config.onInteract(playerGang, locationId, locationData)
    end
end

--[[ El punto de banco de la banda NO pregunta nada por su cuenta.

     Antes abria el cuadro de ox_lib (lib.inputDialog) en mitad de la pantalla,
     con otra tipografia y otros botones: parecia otro programa. Ahora abre el
     panel de la banda —el menu de la derecha— y le pide que saque su propio
     cuadro de ingresar. La cantidad la escribe el panel, y el dinero se mueve
     por el mismo camino que sus botones (gang:cajaMover), asi que el
     servidor comprueba lo mismo venga de donde venga. ]]
function OpenGangBank(uniqueId, locationData)
    AbrirCajaDeBanda('in')
end

function OpenStash(uniqueId, locationData)
    -- El server abre el stash a través del bridge (Inventory.OpenStash)
    TriggerServerEvent('origen_gang:server:openStash')
end

function OpenPersonalStash(uniqueId, locationData)
    -- Usa identificador persistente (citizenid/license), NO el server ID (cambia cada sesión)
    local identifier = Framework.GetPlayerIdentifier()
    if not identifier then
        Notify.SendNotify(locale:t('notify.no_identifier'), 'error')
        return
    end
    local personalId = uniqueId .. '_' .. identifier
    -- El server abre el stash a través del bridge (Inventory.RegisterStash + Inventory.OpenStash)
    TriggerServerEvent('origen_gang:server:openPersonalStash', personalId)
end

function OpenGarage(uniqueId, locationData)
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle ~= 0 then
        local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')
        lib.callback('origen_gangs:server:storeVehicle', false, function(response)
            if response.success then
                local props = lib.getVehicleProperties(vehicle)
                lib.callback('origen_gangs:server:updateVehicleState', false, function()
                    DeleteVehicle(vehicle)
                    Notify.SendNotify(response.message, 'success')
                end, plate, props)
            else
                Notify.SendNotify(response.message, 'error')
            end
        end, plate)
    else
        if not playerGang then Notify.SendNotify(locale:t('notify.not_in_gang'), 'error'); return end
        lib.callback('origen_gangs:server:getGangVehicles', false, function(vehicles)
            lib.callback('origen_gangs:server:getVehicleCatalog', false, function(catalog)
                -- Pasar la locationData del garage para que el cliente use esas
                -- coords + heading al spawnear el vehículo.
                local garageLocation = nil
                if locationData and locationData.x and locationData.y and locationData.z then
                    -- Forzar float en h: json.encode puede serializar 0 como integer,
                    -- y CreateVehicle/SetEntityHeading requieren float obligatoriamente.
                    local rawH = tonumber(locationData.h or locationData.heading) or 0.0
                    garageLocation = {
                        x = locationData.x + 0.0,
                        y = locationData.y + 0.0,
                        z = locationData.z + 0.0,
                        h = rawH + 0.0,
                    }
                end
                --[[ Cada coche va resuelto: nombre, marca y clase del juego, y
                     el estado en cifras. La pantalla es la misma que la del
                     garaje de origen_garages y pinta lo que le llega, sin
                     conocer las propiedades del coche. ]]
                local coches = {}
                for _, v in ipairs(vehicles or {}) do
                    local hash = GetHashKey(v.vehicle or '')
                    local props = v.properties
                    if type(props) == 'string' then
                        local ok, leido = pcall(json.decode, props)
                        props = ok and leido or {}
                    end
                    props = type(props) == 'table' and props or {}

                    -- Sin salud guardada el coche esta nuevo: 1000, no 0.
                    local peor = math.min(tonumber(props.bodyHealth) or 1000, tonumber(props.engineHealth) or 1000)

                    coches[#coches + 1] = {
                        id = v.id,
                        plate = v.plate,
                        stored = (v.stored == true or tonumber(v.stored) == 1) and 1 or 0,
                        model = v.vehicle,
                        name = IsModelInCdimage(hash) and GetLabelText(GetDisplayNameFromVehicleModel(hash)) or v.vehicle,
                        brand = IsModelInCdimage(hash) and GetLabelText(GetMakeNameFromVehicleModel(hash)) or '',
                        class = IsModelInCdimage(hash) and GetLabelText('VEH_CLASS_' .. GetVehicleClassFromName(hash)) or '',
                        stats = {
                            fuel = tonumber(props.fuelLevel) or 100,
                            damage = math.max(0, math.min(100, 100 - math.floor(peor / 10 + 0.5))),
                        },
                    }
                end

                local multa = Config.Garage and Config.Garage.Impound or {}
                GarajeBandaVez = (GarajeBandaVez or 0) + 1

                SendNUIMessage({
                    action = 'openGarageMenu',
                    data   = {
                        gangData        = { label = playerGang.label, money = playerGang.money },
                        vehicles        = coches,
                        capacity        = Config.Vehicles and Config.Vehicles.MaxVehicles or 0,
                        -- Solo para enseñarlo: lo que se cobra lo decide el servidor.
                        recuperar       = { price = tonumber(multa.Fine) or 0, deCaja = multa.PayFromGangBank ~= false },
                        garageLocation  = garageLocation,
                    }
                })
                SetNuiFocus(true, true)
            end, playerGang.id)
        end, playerGang.id)
    end
end

RegisterNetEvent('origen_gang:client:updateGangData', function(gangData)
    if not gangData then
        ClearAllLocations()
        return
    end
    playerGang = gangData
    if gangData.locations and type(gangData.locations) == 'table' then
        UpdateLocations(gangData.locations)
    else
        ClearAllLocations()
    end
end)

local function InitializeLocations()
    if playerGang and playerGang.locations then
        UpdateLocations(playerGang.locations)
    end
end

AddEventHandler('origen:Client:OnPlayerLoaded', function()
    Wait(2000)
    InitializeLocations()
end)

RegisterNetEvent('origen_gang:client:playerGangLoaded', function()
    Wait(500)
    InitializeLocations()
end)

AddEventHandler('origen:Client:OnPlayerUnload', function()
    ClearAllLocations()
end)
