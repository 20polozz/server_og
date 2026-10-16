Custom = {}
Framework = {}
Config = {}
Internal = {}

local isServer = IsDuplicityVersion()
local resource_name = GetCurrentResourceName()
local version = GetResourceMetadata(resource_name, 'version', 0) or '1.0.0'

local core = require 'config.custom_core'

local resourceCategories = {
    framework = {
        'qb-core',
        'es_extended'
    },
    clothing = {
        'origen_clothing',
        'qb-clothing',
        'illenium-appearance',
        'fivem-appearance',
        'crm-appearance',
        'tgiann-clothing',
        'nf-skin',
        'ak47_clothing',
        'ak47_qb_clothing',
        'vms_clothestore',
        'rcore_clothing',
    },
    inventory = {
        'origen_inventory',
        'jpr-inventory',
        'ak47_inventory',
        'ox_inventory',
        'qs-inventory',
        'codem-inventory',
        'ps-inventory',
        'tgiann-inventory',
        'qb-inventory',
        'core_inventory',
    },
    weather = {
        'Renewed-Weathersync',
        'qb-weathersync',
        'cd_easytime',
    },
    lockpickSystem = {
        'qb-lockpick',
        'lockpick'
    },
    parking = {
        'origen_parking',
        'AdvancedParking',
        'cd_garage',
    },
    garage = {
        'cd_garage',
        -- 'qs-advancedgarages',
        'jg-advancedgarages',
        'okokGarage',
        'vms_garagesv2',
        'rcore_garage',
        'qb-garages',
        'origen_garages',
        'op-garages'
    },
    keysystem = {
        'qb-vehiclekeys',
        'qs-vehiclekeys',
        'wasabi_carlock',
        'esx_vehiclelock',
    },
}

local function checkResourceState(resource)
    return GetResourceState(resource) == 'starting' or GetResourceState(resource) == 'started'
end

local function findActiveResource(resourceList)
    for _, resource in ipairs(resourceList) do
        if checkResourceState(resource) then
            return resource
        end
    end
    return nil
end

local activeResources = {}
for category, resources in pairs(resourceCategories) do
    activeResources[category] = findActiveResource(resources)
end

activeResources.framework = activeResources.framework == 'es_extended' and 'esx' or (core.useCustomCore and 'custom' or activeResources.framework) 
activeResources.framework = activeResources.framework or '^1No framework resource found'
activeResources.clothing = activeResources.clothing or '^1No clothing resource found'
activeResources.inventory = activeResources.inventory or '^1No inventory resource found'
activeResources.weather = activeResources.weather or '^3No weather resource found'
activeResources.lockpickSystem = activeResources.lockpickSystem or '^3No lockpick resource found^0'
activeResources.keysystem = activeResources.keysystem or '^3No keysystem resource found^0'
activeResources.parking = activeResources.parking or '^3No parking resource found^0'
activeResources.garage = activeResources.garage or '^3No garage resource found^0'

Config.Framework = activeResources.framework
Config.Inventory = activeResources.inventory
Config.Clothing = activeResources.clothing
Config.Weather = activeResources.weather
Config.LockpickSystem = activeResources.lockpickSystem
Config.KeySystem = activeResources.keysystem
Config.Parking = activeResources.parking
Config.Garage = activeResources.garage

if Config.Inventory == 'qb-inventory' then
    local inventory = GetResourceMetadata('qb-inventory', 'version', 0)
    if inventory then 
        inventory = tonumber(string.match(inventory, "%d+%.?%d*"))
        if tonumber(inventory) >= 2.0 then
            Config.Inventory = 'new-qb-inventory'
        end
    end
elseif Config.Inventory == 'ps-inventory' then
    local inventory = GetResourceMetadata('ps-inventory', 'version', 0)
    if inventory then 
        inventory = tonumber(string.match(inventory, "%d+%.?%d*"))
        if tonumber(inventory) >= 1.5 then
            Config.Inventory = 'new-ps-inventory'
        end
    end
end

local frameworkEvents = {
    ['qb-core'] = {
        ['load'] = 'QBCore:Client:OnPlayerLoaded',
        ['unload'] = 'QBCore:Server:OnPlayerUnload',
    },
    ['esx'] = {
        ['load'] = 'esx:playerLoaded',
        ['unload'] = 'esx:playerLogout',
    },
    ['custom'] = {
        ['load'] = core.events.load,
        ['unload'] = core.events.unload,
    },
}


local function GetFrameworkObject()
    if Config.Framework == 'esx' then
        return exports['es_extended']:getSharedObject()
    elseif Config.Framework == 'qb-core' then
        return exports["qb-core"]:GetCoreObject()
    elseif Config.Framework == 'custom' then
        return core.GetCustomCoreObject()
    end

    return nil
end

function debugger(...)
    if Config.Debug then print ('[^6DEBUG HOUSING^0]', ...) end
end

if isServer then
    Framework = GetFrameworkObject()

    SetConvar('game_enableDynamicDoorCreation', 'true')
    SetConvarReplicated('game_enableDynamicDoorCreation', 'true')

    local eventName = frameworkEvents[Config.Framework]['unload']
    
    local function onPlayerUnload(src)
        TriggerEvent('origen_housing:server:onPLayerUnload', src)
    end

    if eventName then
        AddEventHandler(eventName, onPlayerUnload)
    end

    --[[ Abrir y registrar baúles desde el cliente. Antes abrían cualquier
         inventario (y registraban el baúl con las casillas y el peso que
         mandara el cliente). Ahora BaulDeCasaParaJugador (server/main.lua)
         dice si ese jugador puede abrir ese id, y los datos (label, slots,
         weight: la misma forma que mandaba el cliente) son los del servidor. ]]
    RegisterNetEvent('origen_housing:server:QBOpenStash', function(id, data)
        local src = source
        if Config.Inventory ~= 'new-qb-inventory' then return end
        local baul = BaulDeCasaParaJugador(src, id)
        if not baul then return end

        pcall(function()
            exports['qb-inventory']:OpenInventory(src, id, baul)
        end)
    end)

    RegisterNetEvent('origen_housing:server:JPROpenStash', function(id, data)
        local src = source
        if Config.Inventory ~= 'jpr-inventory' then return end
        local baul = BaulDeCasaParaJugador(src, id)
        if not baul then return end

        pcall(function()
            exports['jpr-inventory']:OpenInventory(src, id, baul)
        end)
    end)

    Internal.RegisterStash = function(id, data)
        if Config.Inventory == 'ox_inventory' then 
            exports.ox_inventory:RegisterStash(id, data.label, data.slots, data.weight * 1000, nil)
        else
            Custom.RegisterStash(id, data)
        end
    end

    RegisterNetEvent('origen_housing:server:RegisterStash', function(id, data)
        local src = source
        local baul = BaulDeCasaParaJugador(src, id)
        if not baul then return end
        Internal.RegisterStash(id, baul)
    end)

    --[[ origen_inventory: el baul lo abre el servidor, despues de mirar llave,
         dueño y que estes dentro o al lado (BaulDeCasaParaJugador). Antes el
         cliente lo abria con inventory:server:OpenInventory y cualquier id de
         baul de casa u hotel valia. Los dos prefijos se apuntan en
         SoloDesdeServidor para que ese camino ya no los abra. ]]
    RegisterNetEvent('origen_housing:server:AbrirBaul', function(id)
        local src = source
        if Config.Inventory ~= 'origen_inventory' then return end
        local baul = BaulDeCasaParaJugador(src, id)
        if not baul then
            print(('^3[origen_housing]^0 %s (%s) no puede abrir el baul %s (sin llave, fuera de la casa o lejos del mueble)')
                :format(GetPlayerName(src) or '?', tostring(src), tostring(id)))
            return
        end
        if baul.coldStorage then
            -- Las propiedades no se guardan en la base; rehidratarlas antes
            -- de abrir evita cobrar el reinicio a la velocidad normal.
            exports.origen_inventory:RegisterStash(id, {
                label = baul.label,
                slots = baul.slots,
                coldStorage = baul.coldStorage,
            })
        end
        -- Solo nombre y casillas, como mandaba antes el cliente: el peso de
        -- Config.StashesTypes va en kg y el alijo se queda con el suyo.
        exports.origen_inventory:openInventory(src, 'stash', id, {
            label = baul.label,
            slots = baul.slots,
            coldStorage = baul.coldStorage,
        })
    end)

    local function BaulesSoloDesdeServidor()
        if Config.Inventory ~= 'origen_inventory' or GetResourceState('origen_inventory') ~= 'started' then return end
        pcall(function()
            exports.origen_inventory:SoloDesdeServidor('^stashHousing_')
            exports.origen_inventory:SoloDesdeServidor('^hotelroom_')
        end)
    end
    CreateThread(BaulesSoloDesdeServidor)
    AddEventHandler('onResourceStart', function(recurso)
        if recurso == 'origen_inventory' then BaulesSoloDesdeServidor() end
    end)
else
    Framework = GetFrameworkObject()

    local function onPlayerLoaded()
        TriggerEvent('origen_housing:client:onPLayerLoad')
    end
    
    local eventName = frameworkEvents[Config.Framework]['load']
    
    if eventName then RegisterNetEvent(eventName, onPlayerLoaded) end

    Internal.useCustomGarage = false

    local disabledRain = false
    local lastRainLevel = 0.0

    Internal.DrawText = function(text, key)
        if Config.CustomDrawText or Config.Framework == 'custom' then
            Custom.DrawText(text, key)
        else
            if Config.Framework == 'qb-core' then
                pcall(function()
                    exports['qb-core']:DrawText('['..key..'] - '..text)
                end)
            elseif Config.Framework == 'esx' then
                pcall(function()
                    Framework.TextUI('['..key..'] - '..text)
                end)
            end
        end
    end

    Internal.HideText = function()
        if Config.CustomDrawText or Config.Framework == 'custom' then
            Custom.HideText()
        else
            if Config.Framework == 'qb-core' then
                pcall(function()
                    exports['qb-core']:HideText()
                end)
            elseif Config.Framework == 'esx' then
                pcall(function()
                    Framework.HideUI()
                end)
            end
        end
    end

    Internal.Notify = function(text, type, length)
        if Config.CustomNotify or Config.Framework == 'custom' then
            Custom.Notify(text, type, length)
        else
            if Config.Framework == 'qb-core' then
                Framework.Functions.Notify(text, type, length)
            elseif Config.Framework == 'esx' then
                Framework.ShowNotification(text, type, length)
            end
        end
    end

    --[[ ══ El telon de los teletransportes ══════════════════════════════════

         La pantalla de carga de origen_hud —el lockup de Origen con sus
         tramos—, en vez de un negro a secas: el salto se tapa con algo del
         servidor y de paso se disimula el rato que tarda en cargar el suelo
         del destino.

         El fundido nativo se lanza IGUAL y por debajo. No es de adorno: si
         la NUI del HUD no llegara a pintar —recurso reiniciandose, la
         pantalla tarda un frame de mas—, sin el negro se veria el salto
         entero. Y si origen_hud no esta levantado, el nativo es lo unico que
         queda, que es lo que habia antes: una habitacion de hotel no puede
         dejar de funcionar porque falte otro recurso.

         Envuelto en pcall porque es una llamada a otro recurso: que alguien
         actualice origen_hud y se lleve el export por delante no puede
         dejar a nadie con la pantalla en negro. ]]
    local function TelonDelHud(entra, time)
        if not checkResourceState('origen_hud') then return end

        pcall(function()
            if entra then
                exports['origen_hud']:DoScreenFadeOut(time)
            else
                exports['origen_hud']:DoScreenFadeIn(time)
            end
        end)
    end

    Internal.FadeOut = function(time)
        time = time or 500

        DoScreenFadeOut(time)
        TelonDelHud(true, time)
    end

    Internal.FadeIn = function(time)
        time = time or 500

        TelonDelHud(false, time)
        DoScreenFadeIn(time)
    end

    Internal.Wardrobe = function(id)
        if Config.CustomClothing then
            Custom.Wardrobe(id)
            return
        end

        if Config.Clothing == 'qb-clothing' then 
            TriggerEvent('qb-clothing:client:openOutfitMenu')
        elseif Config.Clothing == 'illenium-appearance' then
            TriggerEvent('illenium-appearance:client:openOutfitMenu')
        elseif Config.Clothing == 'fivem-appearance' then
            TriggerEvent('fivem-appearance:client:openOutfitMenu')
        elseif Config.Clothing == 'crm-appearance' then
            TriggerEvent('crm-appearance:show-outfits')
        elseif Config.Clothing == 'tgiann-clothing' then
            TriggerEvent('tgiann-clothing:openOutfitMenu')
        elseif Config.Clothing == 'nf-skin' then
            TriggerEvent('nf-skin:client:openOutfitMenu') 
        elseif Config.Clothing == 'ak47_clothing' then
            TriggerEvent('ak47_clothing:openOutfit')
        elseif Config.Clothing == 'ak47_qb_clothing' then 
            TriggerEvent('ak47_qb_clothing:openOutfit')
        elseif Config.Clothing == 'vms_clothestore' then
            exports.vms_clothestore:OpenWardrobe()
        elseif Config.Clothing == 'rcore_clothing' then 
            TriggerEvent('rcore_clothing:openChangingRoom')
        elseif Config.Clothing == 'origen_clothing' then
            exports.origen_clothing:openOutfitMenu(false)
        else
            Custom.Wardrobe(id)
        end
    end

    --[[ Una sola apertura por pulsacion. En origen_inventory una segunda
         peticion con el baul ya abierto lo CIERRA, asi que dos llamadas
         seguidas (dos puntos en el mismo mueble, E y objetivo a la vez...) se
         veian como un baul que se cierra solo. ]]
    local ultimaApertura = 0
    Internal.OpenStash = function(id, data)
        local ahora = GetGameTimer()
        if ahora - ultimaApertura < 1000 then return end
        ultimaApertura = ahora

        if Config.CustomInventory then
            Custom.OpenStash(id, data)
            return
        end

        if Config.Inventory == 'origen_inventory' then
            -- Lo abre el servidor tras validar (origen_housing:server:AbrirBaul).
            TriggerServerEvent('origen_housing:server:AbrirBaul', id)
        elseif Config.Inventory == 'qb-inventory' then
            TriggerServerEvent('inventory:server:OpenInventory', 'stash', id, data)
            TriggerEvent('inventory:client:SetCurrentStash', id)
        elseif Config.Inventory == 'new-qb-inventory' then
            TriggerServerEvent('origen_housing:server:QBOpenStash', id, data)
        elseif Config.Inventory == 'qs-inventory' then
            data.maxweight = data.weight * 10
            TriggerServerEvent('inventory:server:OpenInventory', 'stash', id, data)
            TriggerEvent('inventory:client:SetCurrentStash', id)
        elseif Config.Inventory == 'codem-inventory' then
            TriggerServerEvent('inventory:server:OpenInventory', 'stash', id,  data) 
        elseif Config.Inventory == 'ox_inventory' then
            if exports.ox_inventory:openInventory('stash', id) == false then 
                TriggerServerEvent('origen_housing:server:RegisterStash', id, data)
                exports.ox_inventory:openInventory('stash', id)
            end
        elseif Config.Inventory == 'core_inventory' then
            TriggerServerEvent('core_inventory:server:openInventory', id, 'stash')
        elseif Config.Inventory == 'tgiann-inventory' then
            TriggerServerEvent('inventory:server:OpenInventory', 'stash', id, data)
        elseif Config.Inventory == 'ps-inventory' then
            data.weight = data.weight * 10
            TriggerServerEvent('inventory:server:OpenInventory', 'stash', id, data)
            TriggerEvent('inventory:client:SetCurrentStash', id)
        elseif Config.Inventory == 'new-ps-inventory' then
            data.weight = data.weight * 10
            TriggerServerEvent('ps-inventory:server:OpenInventory', 'stash', id, data)
        elseif Config.Inventory == 'ak47_inventory' then
            exports.ak47_inventory:OpenInventory({
                identifier = id,
                label = data.label,
                type = 'stash',
                maxWeight = data.weight * 1000,
                slots = data.slots,
            })
        elseif Config.Inventory == 'jpr-inventory' then
            TriggerServerEvent('origen_housing:server:JPROpenStash', id, data)
        else
            Custom.OpenStash(id, data)
        end
    end

    Internal.DisableWeatherSync = function()
        if Config.CustomWeatherSystem then
            Custom.DisableWeatherSync()
            return
        end
        
        if Config.Weather == 'qb-weathersync' then
            TriggerEvent('qb-weathersync:client:DisableSync')
        elseif Config.Weather == 'cd_easytime' then
            TriggerEvent('cd_easytime:PauseSync', true)
        elseif Config.Weather == 'Renewed-Weathersync' then
            LocalPlayer.state.syncWeather = false
        else
            Custom.DisableWeatherSync()
        end

        if Config.ForceDisableRain and not disabledRain then
            disabledRain = true
            lastRainLevel = GetRainLevel()

            CreateThread(function()
                while disabledRain do
                    SetRainLevel(0.0)
                    Wait(1000)
                end
            end)
        end
    end

    Internal.EnableWeatherSync = function()
        if Config.CustomWeatherSystem then
            Custom.EnableWeatherSync()
            return
        end
        
        if Config.Weather == 'qb-weathersync' then
            TriggerEvent('qb-weathersync:client:EnableSync')
        elseif Config.Weather == 'cd_easytime' then
            TriggerEvent('cd_easytime:PauseSync', false)
        elseif Config.Weather == 'Renewed-Weathersync' then
            LocalPlayer.state.syncWeather = true
        else
            Custom.EnableWeatherSync()
        end

        if Config.ForceDisableRain and disabledRain then
            disabledRain = false
            SetRainLevel(lastRainLevel)
        end
    end

    Internal.GiveVehicleKeys = function(vehicle, plate, action)
        if Config.CustomKeySystem then
            Custom.GiveVehicleKeys(vehicle, plate, action)
            return
        end

        if Config.KeySystem == 'qb-vehiclekeys' then
            TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
        elseif Config.KeySystem == 'qs-vehiclekeys' then
            local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            exports['qs-vehiclekeys']:GiveKeys(plate, model, true)
        elseif Config.KeySystem == 'esx_vehiclelock' then
            TriggerServerEvent('esx_vehiclelock:givekey', plate)
        elseif Config.KeySystem == 'wasabi_carlock' then
            exports.wasabi_carlock:GiveKey(plate)
        else
            Custom.GiveVehicleKeys(vehicle, plate)
        end
    end

    local function getCoordValue(coords, key, index)
        if not coords then return nil end

        if type(coords) == 'table' then
            if coords[key] ~= nil then
                return coords[key]
            end
            return coords[index]
        end

        local ok, value = pcall(function()
            return coords[key]
        end)

        if ok and value ~= nil then
            return value
        end

        ok, value = pcall(function()
            return coords[index]
        end)

        if ok and value ~= nil then
            return value
        end

        return nil
    end

    Internal.OpenGarage = function(houseID, garageType, coords)
        coords = vec4(
            tonumber(getCoordValue(coords, 'x', 1)) or 0.0,
            tonumber(getCoordValue(coords, 'y', 2)) or 0.0,
            tonumber(getCoordValue(coords, 'z', 3)) or 0.0,
            tonumber(getCoordValue(coords, 'w', 4)) or 0.0
        )

        local veh = cache.vehicle

        local function openDefaultGarage()
            local garage = Config.GarageInteriors[garageType]
            if not garage then return end
            Garage.CreateInteriorGarage({
                exit = coords,
                coords = garage.coords,
                slots = garage.slots,
                id = 'org_house_garage_'..houseID,
                floors = garage.floors,
                houseID = houseID
            })
        end

        if Config.UseHouseGarages then
            openDefaultGarage()
            return
        end

        if Config.CustomGarage then 
            Custom.OpenCustomGarage(houseID, garageType, coords)
            return
        end

        if Config.Garage == 'cd_garage' then
            if veh then 
                TriggerEvent('cd_garage:StoreVehicle_Main', 1, false, false)
            else
                TriggerEvent('cd_garage:PropertyGarage', 'quick', nil)
            end
        elseif Config.Garage == 'jg-advancedgarages' then
            local garageName = 'org_house_garage_' .. houseID
            if veh then 
                TriggerEvent('jg-advancedgarages:client:store-vehicle', garageName, 'car')
            else
                TriggerEvent('jg-advancedgarages:client:open-garage', garageName, 'car', vec4(coords.x, coords.y, coords.z, coords.w))
            end
        elseif Config.Garage == 'okokGarage' then
            if veh then 
                TriggerEvent('okokGarage:StoreVehiclePrivate')
            else
                TriggerEvent('okokGarage:OpenPrivateGarageMenu', vec3(coords.x, coords.y, coords.z), coords.w)
            end
        elseif Config.Garage == 'vms_garagesv2' then
            exports.vms_garagesv2:enterHouseGarage()
        elseif Config.Garage == 'rcore_garage' then
            if veh then
                TriggerEvent('rcore_garage:StoreMyVehicle', 'car')
            else
                TriggerEvent('rcore_garage:OpenGarageOnSpot', 'car', 'civ')
            end
        elseif Config.Garage == 'qb-garages' then
            TriggerEvent('qb-garages:client:setHouseGarage', 'house_garage_'..tostring(houseID), true)
        elseif Config.Garage == 'origen_garages' then
            exports.origen_garages:openExternalGarage(houseID, coords)
        else
            openDefaultGarage()
        end
    end

    local createdGarages = {}

    Internal.RegisterGarage = function(houseID, coords, name)
        if Config.UseHouseGarages or Config.CustomGarage then return end
        if Config.Garage == 'qb-garages' then 
            TriggerEvent('qb-garages:client:addHouseGarage', 'house_garage_'..tostring(houseID), {
                takeVehicle = {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    w = coords.w
                },
                type = 'house',
                label = name,
            })
            Internal.useCustomGarage = true
        elseif Config.Garage == 'op-garages' then 
            Internal.useCustomGarage = true
            if createdGarages[houseID] then return end
            local Coords = {
                CenterOfZone = coords,
                AccessPoint = vec4(0.0, 0.0, 0.0, 0.0)
            }
                
            local house = House.get(houseID)

            local identifier = Framework.GetPlayerIdentifier()

            local holder = house.houseData.holders[identifier]

            if not holder then return end

            local playerList = {
                {
                    id = identifier,
                    name = holder.name or 'Unknown'
                }
            }

            exports['op-garages']:ClientaddTempPrivateGarage(house.houseData.name .. ' | Garage', 'car', Coords, 15, playerList, function(garageId)
                createdGarages[houseID] = garageId

                debugger('Register house garage', garageId)
            end)
        end
    end

    Internal.RemoveGarage = function(houseID)
        if Config.UseHouseGarages or Config.CustomGarage then return end

        if Config.Garage == 'qb-garages' then
            TriggerEvent('qb-garages:client:removeHouseGarage', 'house_garage_'..tostring(houseID))
        elseif Config.Garage == 'op-garages' then
            if not createdGarages[houseID] then return end
            debugger('Remove garage', createdGarages[houseID])
            exports['op-garages']:ClientremoveTempPrivateGarage(createdGarages[houseID])
            createdGarages[houseID] = nil
        end
    end
end

__indexFurniture = {}
__indexIpls = {}
__indexIplsStyles = {}

CreateThread(function()
    for _, category in ipairs(Config.Furniture) do
        for _, item in ipairs(category.items) do
            __indexFurniture[item.model] = item
        end
    end

    for _, data in pairs(Config.IPL) do 
        __indexIpls[data.model] = data

        __indexIplsStyles[data.model] = data.styles
        if data and data.prefix then
            __indexIplsStyles[data.model].prefix = data.prefix
        end
    end

    if resource_name ~= 'origen_housing' then 
        while true do
            Citizen.Trace('[^6ORIGEN HOUSING^0] This resource must keep its original name: origen_housing\n')
            Wait(500)
        end
    end
end)
