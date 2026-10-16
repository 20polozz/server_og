--[[ NOTA DE ORIGEN: este recurso ya no crea blips del juego.

     Los puntos se registran en origen_map, que es de donde los leen los tres
     mapas del servidor (el minimapa, el del menu de pausa y la pestaña de
     Ciudad del inventario). El ayudante que lo hace se carga desde el
     fxmanifest: '@origen_map/shared/marcar.lua'.

     Es un recurso de terceros: si llega una version nueva, este cambio hay que
     volver a hacerlo. ]]

local CreatePed = CreatePed
local SetEntityInvincible = SetEntityInvincible
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local CreateVehicle = CreateVehicle
local SetVehicleNeedsToBeHotwired = SetVehicleNeedsToBeHotwired
local NetworkFadeInEntity = NetworkFadeInEntity
local AddBlipForCoord = AddBlipForCoord
local SetBlipSprite = SetBlipSprite
local SetBlipDisplay = SetBlipDisplay
local SetBlipScale = SetBlipScale
local SetBlipColour = SetBlipColour
local SetBlipAsShortRange = SetBlipAsShortRange
local BeginTextCommandSetBlipName = BeginTextCommandSetBlipName
local AddTextComponentString = AddTextComponentString
local EndTextCommandSetBlipName = EndTextCommandSetBlipName
local GetEntityCoords = GetEntityCoords
local PlayerPedId = PlayerPedId
local TriggerServerEvent = TriggerServerEvent
local DoScreenFadeOut = DoScreenFadeOut
local DoScreenFadeIn = DoScreenFadeIn
local IsScreenFadedOut = IsScreenFadedOut
local IsScreenFadedIn = IsScreenFadedIn

utils = {}
peds = {}

--[[ El remitente de estos avisos.

     Era 'SAMS', que son las siglas del recurso y no un sitio de la ciudad: al
     jugador no le dice nada y le recuerda que hay un script debajo. Lo que le
     habla es el servicio medico, asi que eso es lo que tiene que poner. ]]
local REMITENTE = 'Servicio Médico'

function utils.showNotification(msg, type)
    if GetResourceState('origen_notify') == 'started' then
        exports['origen_notify']:Notify({
            title = REMITENTE,
            description = msg,
            type = type and type or 'info'
        })
    else
        lib.notify({
            title = REMITENTE,
            description = msg,
            type = type and type or 'info'
        })
    end
end

local debug = lib.load("config").debug

function utils.debug(...)
    if debug then
        local args = { ... }

        for i = 1, #args do
            local arg = args[i]
            args[i] = type(arg) == 'table' and json.encode(arg, { sort_keys = true, indent = true }) or tostring(arg)
        end

        print('^6[DEBUG] ^7', table.concat(args, '\t'))
    end
end

function utils.createPed(name, ...)
    local model = lib.requestModel(name)

    if not model then return end

    local ped = CreatePed(0, model, ...)

    SetEntityInvincible(ped, true)
    SetModelAsNoLongerNeeded(model)

    table.insert(peds, ped)

    return ped
end

function utils.createVehicle(name, ...)
    local model = lib.requestModel(name)

    if not model then return end

    local vehicle = CreateVehicle(model, ...)

    SetVehicleNeedsToBeHotwired(vehicle, false)
    NetworkFadeInEntity(vehicle, true)
    SetModelAsNoLongerNeeded(model)

    return vehicle
end

--- NOTA DE ORIGEN: uno por sitio. Con una clave fija, el segundo hospital
--- borraba al primero.
local ultimoSitio = 0

function utils.createBlip(data)
    ultimoSitio = ultimoSitio + 1
    local blip = 'sanitario_' .. ultimoSitio
    OrigenMapa.Poner(blip, {
        x = data.pos.x, y = data.pos.y, z = data.pos.z,
        cat = 'emergencias',
        icono = OrigenMapa.Icono(data.type),
        nombre = data.name,
    })

    return blip
end

local clientCachedHospitalBeds = nil

RegisterNetEvent("origen_ambulancejob:client:syncHospitalBeds", function(beds)
    clientCachedHospitalBeds = beds
end)

function utils.getClosestHospital()
    local closestHospitalKey = nil
    local closestHospital = nil
    local playerPed = cache.ped or PlayerPedId()
    local playerCoords = cache.coords or GetEntityCoords(playerPed)
    local minDist = 999999

    --[[ Las camillas las guarda origen_police en el SERVIDOR: su export
         GetHospitalBeds no existe en el cliente, y antes se preguntaba aqui y
         fallaba en silencio, asi que salvo justo despues de que un admin las
         guardara el hospital "mas cercano" salia siempre de data/hospitals.lua.
         Ahora se piden al servidor la primera vez y se guardan. ]]
    local customBeds = clientCachedHospitalBeds
    if not customBeds then
        local ok, beds = pcall(function()
            return lib.callback.await('origen_ambulancejob:server:getHospitalBeds', false)
        end)
        if ok and type(beds) == 'table' and next(beds) then
            customBeds = beds
            clientCachedHospitalBeds = beds
        end
    end

    if customBeds and next(customBeds) then
        for k, v in pairs(customBeds) do
            local firstBed = v.beds and v.beds[1]
            if firstBed and firstBed.bedPoint then
                local bx = firstBed.bedPoint.x or firstBed.bedPoint[1] or 0.0
                local by = firstBed.bedPoint.y or firstBed.bedPoint[2] or 0.0
                local bz = firstBed.bedPoint.z or firstBed.bedPoint[3] or 0.0
                local dist = #(playerCoords - vector3(bx, by, bz))
                if dist < minDist then
                    minDist = dist
                    closestHospitalKey = k
                    closestHospital = {
                        label = v.label or k,
                        respawn = v.beds
                    }
                end
            end
        end
    end

    if not closestHospitalKey then
        local hospitals = lib.load("data.hospitals") or {}
        for k, v in pairs(hospitals) do
            local hospitalCoords = v.zone and v.zone.pos or (v.respawn and v.respawn[1] and v.respawn[1].bedPoint.xyz) or vector3(0, 0, 0)
            local dist = #(playerCoords - hospitalCoords)

            if dist < minDist then
                minDist = dist
                closestHospitalKey = k
                closestHospital = v
            end
        end
    end

    return closestHospitalKey, closestHospital
end

function utils.addRemoveItem(type, item, quantity)
    local data = {}
    data.toggle = type == "remove"
    data.item = item
    data.quantity = quantity

    utils.debug(type, item, quantity)
    utils.debug(data)

    TriggerServerEvent("origen_ambulancejob:removAddItem", data)
end

function utils.useItem(item, value)
    local data = {}
    data.item = item
    data.value = value
    TriggerServerEvent("origen_ambulancejob:useItem", data)
end

function utils.getItem(name)
    local item = lib.callback.await('origen_ambulancejob:getItem', false, name)

    return item
end

function utils.isBedOccupied(coords)
    local targetPos = coords.xyz or (coords.x and vector3(coords.x, coords.y, coords.z)) or vector3(coords[1], coords[2], coords[3])
    local playerId, playerPed, playerCoords = lib.getClosestPlayer(targetPos, 1.5, true)
    if not playerPed then return false end
    if IsEntityPlayingAnim(playerPed, "timetable@tracy@sleep@", "base", 3) 
        or IsEntityPlayingAnim(playerPed, "anim@gangops@morgue@table@", "body_search", 3) 
        or IsEntityPlayingAnim(playerPed, "switch@franklin@bed", "sleep_getup_rubeyes", 3) then 
        return true 
    end

    return false
end

function utils.inHospitalZone(playerPos, boxPos, boxSize)
    local xInside = playerPos.x >= boxPos.x - boxSize.x / 2 and playerPos.x <= boxPos.x + boxSize.x / 2
    local yInside = playerPos.y >= boxPos.y - boxSize.y / 2 and playerPos.y <= boxPos.y + boxSize.y / 2
    local zInside = playerPos.z >= boxPos.z - boxSize.z / 2 and playerPos.z <= boxPos.z + boxSize.z / 2

    return xInside and yInside and zInside
end

--[[ La espera va con tope. Si otro recurso mete su propio fundido al mismo
     tiempo, el juego puede no dar nunca por hecho el nuestro, y quien esperaba
     se quedaba ahi dentro para siempre: en la reanimacion eso era dejar al
     herido a medio levantar. Pasado el doble de lo que iba a durar, se sigue. ]]
local function esperarFundido(comprobar, duration)
    local limite = GetGameTimer() + (duration or 800) * 2 + 500

    while not comprobar() do
        if GetGameTimer() > limite then return end
        Wait(50)
    end
end

function utils.doScreenFadeOut(duration, wait)
    DoScreenFadeOut(duration or 800)

    if not wait then return end
    esperarFundido(IsScreenFadedOut, duration)
end

function utils.doScreenFadeIn(duration, wait)
    DoScreenFadeIn(duration or 800)

    if not wait then return end
    esperarFundido(IsScreenFadedIn, duration)
end

function utils.openMenu(data)
    if not data or not next(data) then return end

    if GetResourceState('org-menu') == 'started' then
        exports['org-menu']:openMenu(data)
    elseif GetResourceState('qb-menu') == 'started' then
        exports['qb-menu']:openMenu(data)
    else
        local options = {}
        local title = "Menú"
        for i = 1, #data do
            local item = data[i]
            if item.isMenuHeader and i == 1 then
                title = item.header or title
            else
                table.insert(options, {
                    title = item.header or "",
                    description = item.txt or "",
                    icon = item.icon or "",
                    readOnly = item.isMenuHeader or item.disabled,
                    onSelect = item.params and item.params.isAction and item.params.event or nil
                })
            end
        end
        lib.registerContext({
            id = 'origen_ambulancejob:fallback_menu',
            title = title,
            options = options
        })
        lib.showContext('origen_ambulancejob:fallback_menu')
    end
end

function utils.closeMenu()
    if GetResourceState('org-menu') == 'started' then
        exports['org-menu']:closeMenu()
    elseif GetResourceState('qb-menu') == 'started' then
        exports['qb-menu']:closeMenu()
    end
end

RegisterNetEvent('origen_ambulancejob:showNotification', utils.showNotification)
RegisterNetEvent('ars_ambulancejob:showNotification', utils.showNotification)

