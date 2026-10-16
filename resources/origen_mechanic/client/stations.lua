-- Los precios de los paquetes que haya cambiado un admin (server/precios_admin.lua).
local function PreciosVivos(t)
    if type(t) ~= 'table' then return end
    for _, tier in ipairs(Config.Stations.Tiers) do
        if tonumber(t[tier.id]) then tier.price = tonumber(t[tier.id]) end
    end
end
PreciosVivos(GlobalState['origen_mechanic:tiers'])
AddStateBagChangeHandler('origen_mechanic:tiers', 'global', function(_, _, v) PreciosVivos(v) end)

--[[
    AUTO-SERVICIO — LADO DEL JUGADOR

    Marcador, tecla, menu y progressbar. Ni un precio se calcula aqui: la lista
    del menu llega hecha del servidor y el cobro lo decide el ticket del
    servidor, no esta pantalla.
]]

local busy = false
local opening = false
local blipJob = nil

local function Notify(description, notifyType)
    Custom.Notify({
        title = 'Auto-servicio',
        description = description,
        type = notifyType or 'error'
    })
end

-- ── Blips ────────────────────────────────────────────────────────────────

local function CurrentJob()
    if GetResourceState('qbx_core') ~= 'started' then return nil end

    local ok, data = pcall(function()
        return exports.qbx_core:GetPlayerData()
    end)

    if not ok or type(data) ~= 'table' or type(data.job) ~= 'table' then return nil end

    return type(data.job.name) == 'string' and data.job.name or nil
end

--[[ Las estaciones de emergencias solo salen en el mapa de quien puede usarlas:
     un taller de comisaria en el mapa de un civil es una chincheta que no lleva
     a ninguna parte. ]]
local function RefreshBlips()
    if not OrigenMapa then return end

    local job = CurrentJob()
    blipJob = job

    local config = Config.Stations.Blip

    for i = 1, #Config.Stations.Locations do
        local station = Config.Stations.Locations[i]
        local key = ('estacion_%s'):format(station.id)
        local restricted = type(station.jobs) == 'table'

        if restricted and not Mechanic.StationAllowsJob(station, job) then
            OrigenMapa.Quitar(key)
        else
            OrigenMapa.Poner(key, {
                x = station.coords.x,
                y = station.coords.y,
                z = station.coords.z,
                cat = restricted and config.emergencyCategory or config.publicCategory,
                icono = OrigenMapa.Icono(config.sprite),
                nombre = station.label
            })
        end
    end
end

AddEventHandler('QBCore:Client:OnJobUpdate', function()
    if CurrentJob() == blipJob then return end

    RefreshBlips()
end)

-- ── Aplicar el resultado ─────────────────────────────────────────────────

local function RequestControl(vehicle)
    if NetworkHasControlOfEntity(vehicle) then return end

    NetworkRequestControlOfEntity(vehicle)

    local deadline = GetGameTimer() + 1000
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < deadline do
        Wait(0)
    end
end

--[[ `vehiclehandler` (client.lua:32-56) pone SetVehicleUndriveable(true) en
     cuanto ve el motor a 0 y no lo deshace nunca. Sin quitarlo, la estacion
     cobraria por un motor nuevo y el coche seguiria sin arrancar. Es el mismo
     remedio que `RestoreDriveability` de client/repair.lua, repetido aqui porque
     alli es local al fichero. ]]
local function ApplyResult(vehicle, apply)
    if type(apply) ~= 'table' or not vehicle or not DoesEntityExist(vehicle) then return end

    RequestControl(vehicle)

    if apply.body then
        --[[ `SetVehicleFixed` tambien pone el motor y el deposito a tope, y eso
             seria un motor nuevo de regalo con el paquete de chapa. Se guardan
             antes y se devuelven despues. ]]
        local engine = GetVehicleEngineHealth(vehicle)
        local petrol = GetVehiclePetrolTankHealth(vehicle)

        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleBodyHealth(vehicle, 1000.0)

        SetVehicleEngineHealth(vehicle, engine)
        SetVehiclePetrolTankHealth(vehicle, petrol)
    end

    if apply.engineHealth then
        if GetVehicleEngineHealth(vehicle) < apply.engineHealth then
            SetVehicleEngineHealth(vehicle, apply.engineHealth)
        end

        SetVehicleUndriveable(vehicle, false)
    end
end

-- ── Trabajo ──────────────────────────────────────────────────────────────

local function ResolveVehicle()
    if cache.vehicle then
        Notify('Bájate del vehículo')
        return nil
    end

    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.Stations.VehicleDistance, false)
    if not vehicle or not DoesEntityExist(vehicle) then
        Notify('Mete el vehículo en la estación')
        return nil
    end

    if not NetworkGetEntityIsNetworked(vehicle) then
        Notify('Ese vehículo no es válido')
        return nil
    end

    return vehicle
end

local function PlayWorkAnim()
    local anim = Config.Stations.Anim
    if not pcall(lib.requestAnimDict, anim.dict, 3000) then return end

    ClearPedTasks(cache.ped)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 2.0, 2.0, -1, 1, 0, false, false, false)
end

local function RunTier(station, vehicle, tier)
    local netId = VehToNet(vehicle)
    local class = GetVehicleClass(vehicle)

    local payload = {
        station = station.id,
        tier = tier.id,
        netId = netId,
        class = class
    }

    local start = lib.callback.await('origen_mechanic:cb:startStationRepair', false, payload)
    if type(start) ~= 'table' or not start.success then
        return Notify(type(start) == 'table' and start.message or 'La estación no puede con esto')
    end

    busy = true
    PlayWorkAnim()

    local done = lib.progressBar({
        duration = start.duration,
        label = start.label,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = Config.Stations.Anim.dict, clip = Config.Stations.Anim.clip }
    })

    ClearPedTasks(cache.ped)
    busy = false

    if not done then return end

    local result = lib.callback.await('origen_mechanic:cb:finishStationRepair', false, payload)
    if type(result) ~= 'table' or not result.success then
        return Notify(type(result) == 'table' and result.message or 'No se pudo completar el trabajo')
    end

    ApplyResult(vehicle, result.apply)

    --[[ La fisica de GTA pisa lo que se escribe justo despues de tocar el
         vehiculo (hallazgo de la Fase 7): se vuelve a escribir medio segundo
         mas tarde. ]]
    CreateThread(function()
        Wait(500)
        ApplyResult(vehicle, result.apply)
    end)

    Notify(result.message, 'success')
end

local function BuildStationMenu(station)
    local vehicle = ResolveVehicle()
    if not vehicle then return end

    local menu = lib.callback.await('origen_mechanic:cb:getStationMenu', false, {
        station = station.id,
        netId = VehToNet(vehicle),
        class = GetVehicleClass(vehicle)
    })

    if type(menu) ~= 'table' or not menu.success then
        return Notify(type(menu) == 'table' and menu.message or 'La estación no responde')
    end

    if menu.closed then
        return Notify('Hay mecánicos de servicio. Llama a un taller.', 'inform')
    end

    local filas = {}
    local porId = {}

    for i = 1, #menu.tiers do
        local tier = menu.tiers[i]
        porId[tier.id] = tier

        filas[#filas + 1] = {
            id = tier.id,
            titulo = tier.label,
            detalle = tier.description or '',
            valor = tier.price > 0 and ('$%d'):format(tier.price) or 'Gratis',
            tono = tier.price > 0 and 'neutro' or 'ok'
        }
    end

    local nota

    if menu.multiplier and menu.multiplier > 1.0 then
        nota = ('Hay %d mecánicos de servicio: la máquina cobra el %d%% del precio normal. Un taller te sale mucho más barato.')
            :format(menu.mechanics or 0, math.floor(menu.multiplier * 100 + 0.5))
    end

    --[[ La pantalla solo manda el `id` del nivel. El precio sigue saliendo del
         ticket que arma el servidor en `startStationRepair`: si viajara desde
         la NUI, cualquiera se repararía el motor por un dólar. ]]
    MecRiel.Abrir({
        marca = 'lucide:wrench',
        kicker = 'Auto-servicio',
        titulo = menu.label,
        renglon = 'Elige el paquete y confirma',
        rotulo = MecMarcaTaller,
        nota = nota,
        seleccion = true,
        grupos = {
            {
                id = 'niveles',
                titulo = 'Niveles',
                icono = 'lucide:layers',
                vacio = 'La estación no ofrece nada',
                filas = filas
            }
        },
        acciones = {
            { id = 'confirmar', texto = 'Reparar', tipo = 'principal' }
        }
    }, function(elegido)
        if type(elegido) ~= 'table' or elegido.accion ~= 'confirmar' then return end

        local tier = porId[elegido.seleccion]
        if not tier then return end

        if not DoesEntityExist(vehicle) then return Notify('El vehículo ya no está') end

        RunTier(station, vehicle, tier)
    end)
end

local function OpenStation(station)
    if busy or opening or MecRiel.EstaAbierto() then return end

    --[[ `opening` ya no cubre el menu entero: la pantalla es una NUI y
         `BuildStationMenu` vuelve en cuanto la abre, asi que volver de aqui no
         significa que se haya cerrado. Cubre solo la ida y vuelta al servidor;
         a partir de ahi manda `MecRiel.EstaAbierto`.

         El `pcall` sigue haciendo falta por lo mismo de siempre: si revienta a
         mitad, `opening` tiene que volver a false o la estacion se queda muda
         para siempre. ]]
    opening = true
    local ok = pcall(BuildStationMenu, station)
    opening = false

    if not ok then Notify('La estación no responde') end
end

-- ── Punto físico ─────────────────────────────────────────────────────────

local function BuildPoint(station)
    local marker = Config.Stations.Marker
    local color = station.free and marker.freeColor or marker.color
    local shown = false

    lib.points.new({
        coords = station.coords,
        distance = Config.Stations.MarkerDistance,

        nearby = function(self)
            DrawMarker(marker.type, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                marker.scale.x, marker.scale.y, marker.scale.z,
                color.r, color.g, color.b, color.a,
                false, true, 2, false, nil, nil, false)

            --[[ `IsNuiFocused` es lo que tapa el menu de la propia estacion: el
                 panel del riel toma el foco y sin esto la indicacion se vuelve
                 a pintar por encima del menu abierto. ]]
            if self.currentDistance > Config.Stations.PointDistance or busy or IsNuiFocused() then
                if shown then
                    lib.hideTextUI()
                    shown = false
                end
                return
            end

            if not shown then
                lib.showTextUI(('[%s] %s'):format(Config.Stations.KeyLabel, station.label))
                shown = true
            end

            --[[ El menu se pide en su propio hilo: `lib.callback.await` cede, y
                 cediendo dentro del tick de `lib.points` se congelan los puntos
                 de todo el recurso hasta que conteste el servidor. ]]
            if IsControlJustReleased(0, Config.Stations.Key) then
                lib.hideTextUI()
                shown = false
                CreateThread(function() OpenStation(station) end)
            end
        end,

        onExit = function()
            if not shown then return end

            lib.hideTextUI()
            shown = false
        end
    })
end

CreateThread(function()
    for i = 1, #Config.Stations.Locations do
        BuildPoint(Config.Stations.Locations[i])
    end

    --[[ Los datos del jugador no estan listos en el primer frame del recurso:
         si se preguntan antes, las estaciones de emergencias no salen hasta el
         siguiente cambio de oficio. ]]
    Wait(2000)
    RefreshBlips()
end)
