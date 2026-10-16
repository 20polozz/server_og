local busy = false
local nuiOpen = false

local function Notify(description, notifyType)
    Custom.Notify({
        title = 'Mecánica',
        description = description,
        type = notifyType or 'error'
    })
end

--[[ El foco se suelta ANTES de animar y el desmontaje se retrasa 280 ms (los
     260 de la transicion del panel mas margen). Al reves, el raton se queda
     preso los 260 ms en los que la pantalla ya parece cerrada. Es el mismo
     reparto que `client/riel.lua`. ]]
local function CloseNui()
    if not nuiOpen then return end

    nuiOpen = false
    SetNuiFocus(false, false)

    -- Si en esos 280 ms se ha vuelto a abrir, el cierre tardio se comeria
    -- la pantalla nueva y dejaria el raton cogido sin nada delante.
    SetTimeout(280, function()
        if not nuiOpen then SendNUIMessage({ action = 'close' }) end
    end)
end

local function OpenNui(action, data)
    --[[ El riel (client/riel.lua) comparte la pagina y el foco: la lectura
         tarda (barra + servidor) y en ese rato se puede haber abierto. Encima
         de el, el primer cierre soltaria el raton de las dos. ]]
    if MecRiel and MecRiel.EstaAbierto() then
        Notify('Cierra el menú antes de ver el resultado')
        return false
    end
    if nuiOpen then return false end

    nuiOpen = true
    SendNUIMessage({ action = action, data = data })
    SetNuiFocus(true, true)
end

--- Lo consulta `client/riel.lua` antes de abrir: las dos pantallas comparten
--- el foco de la NUI y no pueden estar encima la una de la otra.
local function PanelTallerAbierto()
    return nuiOpen
end
exports('PanelTallerAbierto', PanelTallerAbierto)

if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        nuiOpen = false
        SendNUIMessage({ action = 'close' })
    end)
end

local function ResolveVehicle()
    if cache.vehicle then
        Notify('Bájate del vehículo')
        return nil
    end

    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.Diagnostic.MaxDistance, false)
    if not vehicle or not DoesEntityExist(vehicle) then
        Notify('No hay ningún vehículo cerca')
        return nil
    end

    if not NetworkGetEntityIsNetworked(vehicle) then
        Notify('Ese vehículo no es válido')
        return nil
    end

    return vehicle
end

--[[ El punto del vano y la puerta salen de `Mechanic.GetEngineBay`, que ya lee
     la lista de motores traseros de `vehiclehandler` una sola vez. ]]
local function FaceEngineBay(vehicle)
    if type(Mechanic.GetEngineBay) ~= 'function' then return nil, nil end

    local bay, doorIndex = Mechanic.GetEngineBay(vehicle)

    if #(GetEntityCoords(cache.ped) - bay) > Config.Diagnostic.HoodDistance then
        return nil, nil
    end

    return bay, doorIndex
end

--[[ `lib.requestAnimDict` lanza si el diccionario no carga, y eso dejaria el
     trabajo a medias con el estado puesto. Sin animacion se puede seguir. ]]
local function PlayWorkAnim(anim, flag)
    if not pcall(lib.requestAnimDict, anim.dict, 3000) then return end

    ClearPedTasks(cache.ped)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 2.0, 2.0, -1, flag or 1, 0, false, false, false)
end

local function RunDiagnostic(vehicle)
    if busy or nuiOpen then return end

    local bay, doorIndex = FaceEngineBay(vehicle)
    if not bay then return Notify('Ponte junto al vano del motor') end

    local netId = VehToNet(vehicle)
    local class = GetVehicleClass(vehicle)

    local response = lib.callback.await('origen_mechanic:cb:startDiagnostic', false, {
        netId = netId,
        class = class
    })

    if type(response) ~= 'table' or not response.success then
        return Notify(type(response) == 'table' and response.message or 'No se puede diagnosticar este vehículo')
    end

    busy = true

    TaskTurnPedToFaceCoord(cache.ped, bay.x, bay.y, bay.z, 1000)
    Wait(700)
    SetVehicleDoorOpen(vehicle, doorIndex, false, false)
    PlayWorkAnim(Config.Diagnostic.Anim)

    local done = lib.progressBar({
        duration = response.duration or Config.Diagnostic.duration,
        label = 'Leyendo la centralita',
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = Config.Diagnostic.Anim.dict, clip = Config.Diagnostic.Anim.clip }
    })

    ClearPedTasks(cache.ped)
    SetVehicleDoorShut(vehicle, doorIndex, false)
    busy = false

    if not done then return end
    if not DoesEntityExist(vehicle) then return end

    local result = lib.callback.await('origen_mechanic:cb:finishDiagnostic', false, {
        netId = netId,
        class = class,
        temperature = GetVehicleEngineTemperature(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle)
    })

    if type(result) ~= 'table' or not result.success then
        return Notify(type(result) == 'table' and result.message or 'No se pudo leer el vehículo')
    end

    OpenNui('diagnostic', result.diagnostic)
end

local function RunServiceBook(vehicle)
    if busy or nuiOpen then return end

    local netId = VehToNet(vehicle)
    local class = GetVehicleClass(vehicle)

    busy = true
    PlayWorkAnim(Config.Diagnostic.BookAnim, 49)

    local done = lib.progressBar({
        duration = Config.Diagnostic.bookDuration,
        label = 'Consultando el libro de servicio',
        canCancel = true,
        disable = { car = true, move = true, combat = true }
    })

    ClearPedTasks(cache.ped)
    busy = false

    if not done then return end
    if not DoesEntityExist(vehicle) then return end

    local result = lib.callback.await('origen_mechanic:cb:readServiceBook', false, {
        netId = netId,
        class = class
    })

    if type(result) ~= 'table' or not result.success then
        return Notify(type(result) == 'table' and result.message or 'No se pudo leer el libro')
    end

    OpenNui('serviceBook', result.book)
end

--[[ La revisión desde el punto `taller` de `origen_businesses`: sin
     herramienta y sin agacharse en el capó, porque el coche está en el taller.
     Hace de una pasada lo que en la calle son dos herramientas —centralita y
     chapa— y abre la misma pantalla, así que presupuesto y orden salen igual.
     El servidor comprueba que el jugador esté junto al punto; si no, pide la
     herramienta como siempre. ]]
local function RunWorkshopDiagnostic(vehicle)
    if busy or nuiOpen then return end

    local netId = VehToNet(vehicle)
    local class = GetVehicleClass(vehicle)

    local response = lib.callback.await('origen_mechanic:cb:startDiagnostic', false, {
        netId = netId,
        class = class
    })

    if type(response) ~= 'table' or not response.success then
        return Notify(type(response) == 'table' and response.message or 'No se puede revisar este vehículo')
    end

    busy = true

    TaskTurnPedToFaceEntity(cache.ped, vehicle, 1000)
    Wait(700)
    PlayWorkAnim(Config.Diagnostic.BookAnim, 49)

    local done = lib.progressBar({
        duration = response.duration or Config.Diagnostic.duration,
        label = 'Revisando el vehículo',
        canCancel = true,
        disable = { car = true, move = true, combat = true }
    })

    ClearPedTasks(cache.ped)
    busy = false

    if not done then return end
    if not DoesEntityExist(vehicle) then return end

    local scan = nil
    pcall(function()
        scan = exports[GetCurrentResourceName()]:ScanBodyDamage(vehicle)
    end)

    local result = lib.callback.await('origen_mechanic:cb:finishDiagnostic', false, {
        netId = netId,
        class = class,
        temperature = GetVehicleEngineTemperature(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        scan = scan
    })

    if type(result) ~= 'table' or not result.success then
        return Notify(type(result) == 'table' and result.message or 'No se pudo leer el vehículo')
    end

    OpenNui('diagnostic', result.diagnostic)
end

local function RevisarEnTaller()
    local vehicle = ResolveVehicle()
    if not vehicle then return end

    RunWorkshopDiagnostic(vehicle)
end
exports('RevisarEnTaller', RevisarEnTaller)

local function UseDiagnosticTool()
    local vehicle = ResolveVehicle()
    if not vehicle then return end

    RunDiagnostic(vehicle)
end
exports('UseDiagnosticTool', UseDiagnosticTool)

local function UseServiceBook()
    local vehicle = ResolveVehicle()
    if not vehicle then return end

    RunServiceBook(vehicle)
end
exports('UseServiceBook', UseServiceBook)

RegisterNUICallback('close', function(_, cb)
    CloseNui()
    cb({ success = true })
end)

--[[ El presupuesto lo calcula el servidor entero: de aqui solo salen las claves
     de pieza que ha marcado el mecanico. ]]
RegisterNUICallback('buildBudget', function(data, cb)
    if type(data) ~= 'table' or type(data.parts) ~= 'table' or type(data.netId) ~= 'number' then
        return cb({ success = false, message = 'Petición no válida' })
    end

    local vehicle = NetToVeh(data.netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return cb({ success = false, message = 'El vehículo ya no está' })
    end

    local result = lib.callback.await('origen_mechanic:cb:buildBudget', false, {
        netId = data.netId,
        class = GetVehicleClass(vehicle),
        parts = data.parts
    })

    cb(type(result) == 'table' and result or { success = false, message = 'Sin respuesta del servidor' })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if nuiOpen then SetNuiFocus(false, false) end
end)

Mechanic.Ocupacion.diagnostic = function()
    return busy or nuiOpen
end
