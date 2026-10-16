local WHEEL_BONES = { 'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr', 'wheel_lm1', 'wheel_rm1' }
local TARGET_NAME = 'origen_mechanic:installPart'

local carrying = nil
local installing = false
local backEngine = nil

local function Notify(description, notifyType)
    Custom.Notify({
        title = 'Mecánica',
        description = description,
        type = notifyType or 'error'
    })
end

--[[ La lista de motores traseros vive en `vehiclehandler` y no se duplica aqui:
     se lee su fichero de datos una sola vez. Si el recurso no esta o el fichero
     cambia de forma, se asume motor delantero. ]]
local function GetBackEngineList()
    if backEngine then return backEngine end

    backEngine = {}

    if GetResourceState('vehiclehandler') ~= 'started' then return backEngine end

    local ok, result = pcall(function()
        local file = LoadResourceFile('vehiclehandler', 'data/vehicle.lua')
        if not file then return nil end

        local chunk = load(file, '@@vehiclehandler/data/vehicle.lua', 't')
        return chunk and chunk() or nil
    end)

    if ok and type(result) == 'table' and type(result.backengine) == 'table' then
        backEngine = result.backengine
    end

    return backEngine
end

local function IsBackEngine(model)
    return GetBackEngineList()[model] == true
end

--- Punto físico del vano motor y puerta que hay que abrir.
local function GetEngineBay(vehicle)
    local model = GetEntityModel(vehicle)
    local min, max = GetModelDimensions(model)
    local back = IsBackEngine(model)

    return GetOffsetFromEntityInWorldCoords(vehicle, 0.0, back and min.y or max.y, 0.3), back and 5 or 4
end

--[[ El diagnostico necesita el mismo punto y la misma puerta. Se comparte la
     funcion en vez de volver a leer `vehiclehandler/data/vehicle.lua`. ]]
Mechanic.GetEngineBay = GetEngineBay

local function GetClosestWheelPoint(vehicle, maxDistance)
    local pedCoords = GetEntityCoords(cache.ped)
    local closest, closestDistance = nil, maxDistance

    for i = 1, #WHEEL_BONES do
        local bone = GetEntityBoneIndexByName(vehicle, WHEEL_BONES[i])
        if bone ~= -1 then
            local boneCoords = GetWorldPositionOfEntityBone(vehicle, bone)
            local distance = #(pedCoords - boneCoords)

            if distance < closestDistance then
                closest, closestDistance = boneCoords, distance
            end
        end
    end

    return closest
end

--- Punto correcto según la pieza: rueda para frenos y neumáticos, capó para el resto.
local function GetRepairPoint(vehicle, part)
    if Mechanic.IsWheelPart(part) then
        local wheel = GetClosestWheelPoint(vehicle, Config.Repair.WheelDistance)
        if not wheel then return nil, nil, 'Ponte junto a la rueda' end

        return wheel, nil
    end

    local bay, doorIndex = GetEngineBay(vehicle)
    if #(GetEntityCoords(cache.ped) - bay) > Config.Repair.HoodDistance then
        return nil, nil, 'Ponte junto al vano del motor'
    end

    return bay, doorIndex
end

local function PlayCarryAnim(prop)
    local anim = prop.bone == Config.Repair.Bone.BOX and Config.Repair.Anim.CarryBox or Config.Repair.Anim.CarryHand

    lib.requestAnimDict(anim.dict)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 4.0, 1.0, -1, 49, 0, false, false, false)

    return anim
end

--[[ El modelo se comprueba antes de pedirlo porque `lib.requestModel` lanza un
     error con un modelo inexistente, y quedarse sin prop no puede impedir montar
     la pieza. ]]
local function LoadPropModel(propConfig)
    local hash = joaat(propConfig.model)
    if not IsModelValid(hash) and not IsModelInCdimage(hash) then return nil end

    local ok = pcall(lib.requestModel, hash, 5000)
    if not ok or not HasModelLoaded(hash) then return nil end

    return hash
end

local function AttachCarryProp(propConfig)
    local hash = LoadPropModel(propConfig)

    if not hash and propConfig ~= Config.Repair.FallbackProp then
        propConfig = Config.Repair.FallbackProp
        hash = LoadPropModel(propConfig)
    end

    if not hash then return nil, propConfig end

    local coords = GetEntityCoords(cache.ped)
    local object = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
    local bone = GetPedBoneIndex(cache.ped, propConfig.bone)

    AttachEntityToEntity(object, cache.ped, bone,
        propConfig.pos.x, propConfig.pos.y, propConfig.pos.z,
        propConfig.rot.x, propConfig.rot.y, propConfig.rot.z,
        true, true, false, true, 1, true)

    SetModelAsNoLongerNeeded(hash)

    return object, propConfig
end

local function RemoveTarget(vehicle)
    if GetResourceState('ox_target') ~= 'started' then return end
    if not vehicle or not DoesEntityExist(vehicle) then return end

    pcall(function()
        exports.ox_target:removeLocalEntity(vehicle, TARGET_NAME)
    end)
end

local function StopCarrying()
    if not carrying then return end

    local session = carrying
    carrying = nil

    RemoveTarget(session.vehicle)
    lib.hideTextUI()

    if session.prop and DoesEntityExist(session.prop) then
        DeleteEntity(session.prop)
    end

    ClearPedTasks(cache.ped)
end

--[[ `vehiclehandler` marca el vehiculo como inconducible cuando la salud de
     motor nativa toca 0 y jamas quita ese flag. Subir solo nuestra salud de
     componente dejaria al jugador con una notificacion de exito y un coche que
     no arranca. Se limpia aqui y no en `vehiclehandler` para no pelearse con el
     por el flag, que es la misma disciplina que siguio la Fase 2. ]]
local function RestoreDriveability(vehicle, engineHealth)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    if not NetworkHasControlOfEntity(vehicle) then
        NetworkRequestControlOfEntity(vehicle)

        local deadline = GetGameTimer() + 1000
        while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < deadline do
            Wait(0)
        end
    end

    if GetVehicleEngineHealth(vehicle) < engineHealth then
        SetVehicleEngineHealth(vehicle, engineHealth)
    end

    --[[ Si el flag venia de quedarse sin combustible, `vehiclehandler` lo vuelve
         a poner en cuanto alguien se sienta. Es lo correcto: sin gasolina no se
         anda, y eso no lo arregla una pieza. ]]
    SetVehicleUndriveable(vehicle, false)
end

local function CloseHood(vehicle, doorIndex)
    if not doorIndex or not vehicle or not DoesEntityExist(vehicle) then return end

    SetVehicleDoorShut(vehicle, doorIndex, false)
end

local function InstallPart(session)
    if installing or not carrying then return end

    local vehicle = session.vehicle
    if not DoesEntityExist(vehicle) then return StopCarrying() end

    local point, doorIndex, err = GetRepairPoint(vehicle, session.part)
    if not point then return Notify(err) end

    installing = true
    lib.hideTextUI()

    TaskTurnPedToFaceCoord(cache.ped, point.x, point.y, point.z, 1000)
    Wait(700)

    if doorIndex then
        SetVehicleDoorOpen(vehicle, doorIndex, false, false)
    end

    local anim = doorIndex and Config.Repair.Anim.Hood or Config.Repair.Anim.Wheel
    lib.requestAnimDict(anim.dict)
    ClearPedTasks(cache.ped)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 2.0, 2.0, -1, 1, 0, false, false, false)

    local settings = session.kind == Mechanic.PartKind.SERVICE and Config.Repair.Service or Config.Repair.Component

    --[[ El skillcheck fallido no consume la pieza: el servidor solo la descuenta
         en `finishPartReplace`, que ni siquiera se llega a llamar. ]]
    local cual = session.kind == Mechanic.PartKind.SERVICE and Config.Repair.Minijuegos.service or Config.Repair.Minijuegos.component
    if not Mechanic.Minijuego(cual, session.part, settings) then
        ClearPedTasks(cache.ped)
        CloseHood(vehicle, doorIndex)
        installing = false
        Notify('Se te ha escapado la pieza de las manos')

        if carrying then PlayCarryAnim(carrying.propConfig) end
        return
    end

    local done = lib.progressBar({
        duration = session.duration,
        label = ('Instalando %s'):format(session.label),
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = anim.dict, clip = anim.clip }
    })

    ClearPedTasks(cache.ped)
    CloseHood(vehicle, doorIndex)
    installing = false

    if not done then
        if carrying then PlayCarryAnim(carrying.propConfig) end
        return
    end

    if not carrying or not DoesEntityExist(vehicle) then return StopCarrying() end

    local response = lib.callback.await('origen_mechanic:cb:finishPartReplace', false, {
        netId = session.netId,
        part = session.part,
        kind = session.kind,
        class = GetVehicleClass(vehicle)
    })

    StopCarrying()

    if type(response) ~= 'table' or not response.success then
        return Notify(type(response) == 'table' and response.message or 'No se pudo completar la sustitución')
    end

    if Config.Repair.EngineParts[session.part] then
        RestoreDriveability(vehicle, Config.Repair.EngineHealth.replacement)
    end

    Notify(response.message, 'success')

    if type(response.materials) == 'string' and response.materials ~= '' then
        Notify(('Has recuperado %s'):format(response.materials), 'inform')
    end
end

local function AddTarget(session)
    if GetResourceState('ox_target') ~= 'started' then return false end

    local ok = pcall(function()
        exports.ox_target:addLocalEntity(session.vehicle, {
            {
                name = TARGET_NAME,
                icon = 'fa-solid fa-screwdriver-wrench',
                label = ('Instalar %s'):format(session.label),
                distance = Config.Repair.TargetDistance,
                canInteract = function()
                    return carrying ~= nil and not installing
                end,
                onSelect = function()
                    CreateThread(function() InstallPart(session) end)
                end
            }
        })
    end)

    return ok
end

--[[ `ox_target` es la via normal, pero si no esta arrancado el item quedaria
     inservible, asi que se cae a una indicacion con tecla. ]]
local function RunFallbackPrompt(session)
    local shown = false

    while carrying == session do
        Wait(0)

        if not installing and DoesEntityExist(session.vehicle) then
            local point = GetRepairPoint(session.vehicle, session.part)

            if point then
                if not shown then
                    lib.showTextUI(('[E] Instalar %s'):format(session.label))
                    shown = true
                end

                if IsControlJustReleased(0, 38) then
                    InstallPart(session)
                    shown = false
                end
            elseif shown then
                lib.hideTextUI()
                shown = false
            end
        elseif shown then
            lib.hideTextUI()
            shown = false
        end
    end

    lib.hideTextUI()
end

local function WatchSession(session)
    local startedAt = GetGameTimer()

    while carrying == session do
        Wait(500)

        if installing then goto continue end

        if not DoesEntityExist(session.vehicle) then break end
        if cache.vehicle then break end
        if IsPedDeadOrDying(cache.ped, true) then break end
        if #(GetEntityCoords(cache.ped) - GetEntityCoords(session.vehicle)) > 12.0 then break end
        if (GetGameTimer() - startedAt) > Config.Repair.TicketMaxMs then break end

        if session.propConfig and not IsEntityPlayingAnim(cache.ped, session.carryAnim.dict, session.carryAnim.clip, 3) then
            PlayCarryAnim(session.propConfig)

            --[[ PlayCarryAnim cede al pedir el diccionario. Si la sesion termina
                 durante esa cesion, la animacion se repone sobre un mecanico que
                 ya no lleva nada y se queda con las manos ahuecadas para siempre. ]]
            if carrying ~= session then ClearPedTasks(cache.ped) end
        end

        ::continue::
    end

    if carrying == session then
        StopCarrying()
    end
end

local function UsePartItem(_, item)
    if type(item) ~= 'table' or type(item.name) ~= 'string' then return end

    local part, kind = Mechanic.ResolvePartItem(item.name)
    if not part then return end

    if carrying then return Notify('Ya llevas una pieza en las manos') end
    if cache.vehicle then return Notify('Bájate del vehículo') end

    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.Repair.MaxDistance, false)
    if not vehicle or not DoesEntityExist(vehicle) then return Notify('No hay ningún vehículo cerca') end
    if not NetworkGetEntityIsNetworked(vehicle) then return Notify('Ese vehículo no es válido') end

    local netId = VehToNet(vehicle)

    local response = lib.callback.await('origen_mechanic:cb:startPartReplace', false, {
        netId = netId,
        part = part,
        kind = kind,
        class = GetVehicleClass(vehicle)
    })

    if type(response) ~= 'table' or not response.success then
        return Notify(type(response) == 'table' and response.message or 'No se puede sustituir esa pieza')
    end

    local propConfig = Mechanic.GetPartProp(part, kind)
    local prop, usedConfig = AttachCarryProp(propConfig)
    local carryAnim = PlayCarryAnim(usedConfig)

    local session = {
        part = part,
        kind = kind,
        label = response.label or part,
        duration = response.duration or Mechanic.GetPartDuration(kind),
        vehicle = vehicle,
        netId = netId,
        prop = prop,
        propConfig = usedConfig,
        carryAnim = carryAnim
    }

    carrying = session

    if not AddTarget(session) then
        CreateThread(function() RunFallbackPrompt(session) end)
    end

    CreateThread(function() WatchSession(session) end)
end
exports('UsePartItem', UsePartItem)

local function UsePatchKit()
    if carrying then return Notify('Ya llevas una pieza en las manos') end
    if installing then return end
    if cache.vehicle then return Notify('Bájate del vehículo') end

    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.Repair.MaxDistance, false)
    if not vehicle or not DoesEntityExist(vehicle) then return Notify('No hay ningún vehículo cerca') end
    if not NetworkGetEntityIsNetworked(vehicle) then return Notify('Ese vehículo no es válido') end

    local bay, doorIndex = GetEngineBay(vehicle)
    if #(GetEntityCoords(cache.ped) - bay) > Config.Repair.HoodDistance then
        return Notify('Ponte junto al vano del motor')
    end

    local netId = VehToNet(vehicle)

    local response = lib.callback.await('origen_mechanic:cb:startPatchKit', false, {
        netId = netId,
        class = GetVehicleClass(vehicle)
    })

    if type(response) ~= 'table' or not response.success then
        return Notify(type(response) == 'table' and response.message or 'No hay nada que parchear')
    end

    installing = true

    TaskTurnPedToFaceCoord(cache.ped, bay.x, bay.y, bay.z, 1000)
    Wait(700)
    SetVehicleDoorOpen(vehicle, doorIndex, false, false)

    local anim = Config.Repair.Anim.Hood
    lib.requestAnimDict(anim.dict)
    ClearPedTasks(cache.ped)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 2.0, 2.0, -1, 1, 0, false, false, false)

    local patch = Config.Repair.Patch

    if not Mechanic.Minijuego(Config.Repair.Minijuegos.patch, nil, patch) then
        ClearPedTasks(cache.ped)
        CloseHood(vehicle, doorIndex)
        installing = false
        return Notify('El parche no ha agarrado')
    end

    local done = lib.progressBar({
        duration = response.duration or patch.duration,
        label = 'Colocando parche de emergencia',
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = anim.dict, clip = anim.clip }
    })

    ClearPedTasks(cache.ped)
    CloseHood(vehicle, doorIndex)
    installing = false

    if not done then return end
    if not DoesEntityExist(vehicle) then return end

    local result = lib.callback.await('origen_mechanic:cb:finishPatchKit', false, {
        netId = netId,
        class = GetVehicleClass(vehicle)
    })

    if type(result) ~= 'table' or not result.success then
        return Notify(type(result) == 'table' and result.message or 'No se pudo aplicar el parche')
    end

    RestoreDriveability(vehicle, Config.Repair.EngineHealth.patch)

    Notify(result.message, 'success')
end
exports('UsePatchKit', UsePatchKit)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    StopCarrying()
end)

Mechanic.Ocupacion.repair = function()
    return carrying ~= nil or installing
end
