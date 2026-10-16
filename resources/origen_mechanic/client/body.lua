local TARGET_NAME = 'origen_mechanic:installBodyPart'

local carrying = nil
local working = false
local inspecting = false
local offsetsCache = {}
local appliedRevision = {}

local function Notify(description, notifyType)
    Custom.Notify({
        title = 'Chapa',
        description = description,
        type = notifyType or 'error'
    })
end

local function HasAnim(anim)
    if type(anim) ~= 'table' or type(anim.dict) ~= 'string' then return false end

    return DoesAnimDictExist(anim.dict)
end

--[[ `lib.requestAnimDict` lanza si el diccionario no carga y eso dejaria el
     trabajo a medias con el estado puesto. Sin animacion se puede seguir. ]]
local function PlayWorkAnim(anim, flag)
    if not HasAnim(anim) then return false end
    if not pcall(lib.requestAnimDict, anim.dict, 3000) then return false end

    ClearPedTasks(cache.ped)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 2.0, 2.0, -1, flag or 1, 0, false, false, false)
    return true
end

local function ProgressAnim(anim)
    if not HasAnim(anim) then return nil end

    return { dict = anim.dict, clip = anim.clip }
end

local function RequestControl(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    if NetworkHasControlOfEntity(vehicle) then return true end

    NetworkRequestControlOfEntity(vehicle)

    local deadline = GetGameTimer() + 1000
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < deadline do
        Wait(0)
    end

    return NetworkHasControlOfEntity(vehicle)
end

local function GetBoneName(group, index)
    local part = Config.Body.Parts[group]
    if not part then return nil end

    local value = tonumber(index)
    if not value then return nil end

    if part.kind == Mechanic.BodyGroupKind.DOOR then
        local door = Config.Body.Doors[value]
        return door and door.bone or nil, door and door.bone2 or nil
    end

    if part.kind == Mechanic.BodyGroupKind.WINDOW then
        local window = Config.Body.Windows[value]
        return window and window.bone or nil
    end

    return nil
end

local function GetWheelData(vehicle, index)
    local wheels = Config.Body.Wheels[GetVehicleNumberOfWheels(vehicle)]
    if not wheels then return nil end

    return wheels[tonumber(index)]
end

local function BoneWorldPosition(vehicle, boneName)
    if not boneName then return nil end

    local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
    if boneIndex == -1 then return nil end

    return GetWorldPositionOfEntityBone(vehicle, boneIndex)
end

--- ¿El hueso se ha colapsado sobre el centro del vehículo? Entonces falta la pieza.
local function IsBoneCollapsed(vehicle, boneName)
    local position = BoneWorldPosition(vehicle, boneName)
    if not position then return nil end

    return #(position - GetEntityCoords(vehicle)) <= 0.1
end

local function CollectBoneNames()
    local names = {}

    for _, door in pairs(Config.Body.Doors) do
        names[#names + 1] = door.bone
        if door.bone2 then names[#names + 1] = door.bone2 end
    end

    for _, window in pairs(Config.Body.Windows) do
        names[#names + 1] = window.bone
    end

    local seen = {}
    for _, wheels in pairs(Config.Body.Wheels) do
        for _, wheel in pairs(wheels) do
            if not seen[wheel.bone] then
                seen[wheel.bone] = true
                names[#names + 1] = wheel.bone
            end
        end
    end

    return names
end

local BONE_NAMES = CollectBoneNames()

--[[ Cuando una pieza se arranca, su hueso se colapsa sobre el centro del coche y
     deja de servir para situar el punto de trabajo. La unica forma de recuperar
     donde ESTABA es medirlo sobre un vehiculo intacto del mismo modelo, asi que
     se spawnea un duplicado invisible bajo el mapa, se leen los desplazamientos
     y se borra en el acto. Se cachea por modelo: los huesos de un modelo son
     siempre los mismos y repetir el spawn por cada coche no compensa. ]]
local function GetModelBoneOffsets(vehicle)
    local model = GetEntityModel(vehicle)
    local cached = offsetsCache[model]
    if cached then return cached end

    local offsets = {}

    if not IsModelValid(model) or not IsModelAVehicle(model) or not pcall(lib.requestModel, model, 10000) or not HasModelLoaded(model) then
        offsetsCache[model] = offsets
        return offsets
    end

    local coords = GetEntityCoords(vehicle)

    --[[ Entre el CreateVehicle y el DeleteEntity no hay ni un solo yield: si el
         hilo pudiera cortarse en medio, el duplicado se quedaria en el mundo. ]]
    local duplicate = CreateVehicle(model, coords.x, coords.y, coords.z - 250.0, 0.0, false, false)
    SetModelAsNoLongerNeeded(model)

    if duplicate and duplicate ~= 0 and DoesEntityExist(duplicate) then
        SetEntityVisible(duplicate, false, false)
        SetEntityCollision(duplicate, false, false)
        FreezeEntityPosition(duplicate, true)

        for i = 1, #BONE_NAMES do
            local boneName = BONE_NAMES[i]
            local boneIndex = GetEntityBoneIndexByName(duplicate, boneName)

            if boneIndex ~= -1 then
                local world = GetWorldPositionOfEntityBone(duplicate, boneIndex)
                local offset = GetOffsetFromEntityGivenWorldCoords(duplicate, world.x, world.y, world.z)

                if #offset > 0.05 then offsets[boneName] = offset end
            end
        end

        DeleteEntity(duplicate)
    end

    offsetsCache[model] = offsets
    return offsets
end

--- Punto de trabajo de una pieza, exista todavía o esté arrancada.
local function GetBodyPartPoint(vehicle, group, index)
    local part = Config.Body.Parts[group]
    if not part then return nil end

    local boneName, fallbackBone

    if part.kind == Mechanic.BodyGroupKind.WHEEL then
        local wheel = GetWheelData(vehicle, index)
        boneName = wheel and wheel.bone or nil
    else
        boneName, fallbackBone = GetBoneName(group, index)
    end

    if not boneName then return nil end

    local offsets = GetModelBoneOffsets(vehicle)
    local offset = offsets[boneName] or (fallbackBone and offsets[fallbackBone])

    if offset then
        return GetOffsetFromEntityInWorldCoords(vehicle, offset.x, offset.y, offset.z)
    end

    return BoneWorldPosition(vehicle, boneName) or BoneWorldPosition(vehicle, fallbackBone)
end

--- Lectura local del daño visual. Las nativas de daño solo existen en cliente.
local function ScanBodyDamage(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end

    local parts = {}

    local function mark(group, index, status)
        parts[group] = parts[group] or {}
        parts[group][tostring(index)] = status
    end

    for _, group in ipairs(Mechanic.BodyGroupOrder) do
        local part = Config.Body.Parts[group]

        if part.kind == Mechanic.BodyGroupKind.DOOR then
            for i = 1, #part.indices do
                local index = part.indices[i]

                if GetIsDoorValid(vehicle, index) then
                    local door = Config.Body.Doors[index]

                    if IsBoneCollapsed(vehicle, door.bone) then
                        mark(group, index, Mechanic.BodyStatus.MISSING)
                    elseif IsVehicleDoorDamaged(vehicle, index) then
                        mark(group, index, Mechanic.BodyStatus.DAMAGED)
                    end
                end
            end
        elseif part.kind == Mechanic.BodyGroupKind.WINDOW then
            for i = 1, #part.indices do
                local index = part.indices[i]
                local window = Config.Body.Windows[index]

                --[[ Un coupe no tiene lunas traseras y la nativa de integridad
                     responde igual: sin comprobar el hueso saldrian rotas dos
                     ventanillas que ese modelo nunca tuvo. ]]
                if window and GetEntityBoneIndexByName(vehicle, window.bone) ~= -1 then
                    if not IsVehicleWindowIntact(vehicle, index) then
                        mark(group, index, Mechanic.BodyStatus.MISSING)
                    end
                end
            end
        elseif part.kind == Mechanic.BodyGroupKind.WHEEL then
            local wheels = Config.Body.Wheels[GetVehicleNumberOfWheels(vehicle)]

            if wheels then
                for index, wheel in pairs(wheels) do
                    if part.allowed[index] then
                        if IsBoneCollapsed(vehicle, wheel.bone) then
                            mark(group, index, Mechanic.BodyStatus.MISSING)
                        elseif IsVehicleTyreBurst(vehicle, index, false) or GetVehicleWheelHealth(vehicle, wheel.wheelId) <= 100.0 then
                            mark(group, index, Mechanic.BodyStatus.DAMAGED)
                        end
                    end
                end
            end
        end
    end

    return {
        parts = parts,
        bodyHealth = GetVehicleBodyHealth(vehicle)
    }
end
exports('ScanBodyDamage', ScanBodyDamage)

--[[ Una abolladura no se puede volver a marcar: no hay nativa que deforme una
     pieza concreta. Solo se reproduce lo que falta; lo abollado se queda anotado
     como trabajo pendiente aunque el coche se vea liso. ]]
local function BreakBodyPart(vehicle, group, index, status)
    local part = Config.Body.Parts[group]
    if not part then return end

    local value = tonumber(index)
    if not value then return end

    if part.kind == Mechanic.BodyGroupKind.DOOR then
        if status == Mechanic.BodyStatus.MISSING then
            SetVehicleDoorBroken(vehicle, value, true)
        end
        return
    end

    if part.kind == Mechanic.BodyGroupKind.WINDOW then
        RemoveVehicleWindow(vehicle, value)
        return
    end

    local wheel = GetWheelData(vehicle, value)
    if not wheel then return end

    if status == Mechanic.BodyStatus.MISSING then
        BreakOffVehicleWheel(vehicle, wheel.wheelId, false, true, true, false)
    else
        SetVehicleTyreBurst(vehicle, value, false, 1000.0)
    end
end

local function ApplyBodyDamage(vehicle, payload)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    if type(payload) ~= 'table' or type(payload.parts) ~= 'table' then return end

    for group, entries in pairs(payload.parts) do
        if type(entries) == 'table' then
            for index, status in pairs(entries) do
                BreakBodyPart(vehicle, group, index, status)
            end
        end
    end

    local stored = tonumber(payload.bodyHealth)
    if stored and stored < GetVehicleBodyHealth(vehicle) then
        SetVehicleBodyHealth(vehicle, stored + 0.0)
    end
end

--[[ Dos cosas que se pagan caras si se olvidan: el motor de fisica de GTA pisa el
     daño mientras sincroniza una entidad recien creada, de ahi la segunda pasada
     a los 500 ms (misma disciplina que `origen_garages` y `org_parking`); y el
     statebag llega a TODOS los clientes que tienen el coche en pantalla, asi que
     aqui NO se pide el control y solo escribe quien ya lo tiene. ]]
local function RestoreBodyDamage(vehicle, payload)
    local deadline = GetGameTimer() + 2000
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < deadline do
        Wait(250)
        if not DoesEntityExist(vehicle) then return end
    end

    if not NetworkHasControlOfEntity(vehicle) then return end

    ApplyBodyDamage(vehicle, payload)

    CreateThread(function()
        Wait(500)
        if DoesEntityExist(vehicle) then ApplyBodyDamage(vehicle, payload) end
    end)
end

--[[ No hay forma de reparar UNA pieza: las nativas solo saben arreglar el coche
     entero. Se arregla entero y se vuelve a romper todo lo que sigue roto. La
     salud de motor, deposito y suciedad se guardan antes porque `SetVehicleFixed`
     tambien las deja a estreno y eso seria una reparacion mecanica gratis. ]]
local function RefreshVehicleBody(vehicle, payload)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    if not RequestControl(vehicle) then return end

    local engineHealth = GetVehicleEngineHealth(vehicle)
    local tankHealth = GetVehiclePetrolTankHealth(vehicle)
    local dirtLevel = GetVehicleDirtLevel(vehicle)

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)

    SetVehicleEngineHealth(vehicle, engineHealth)
    SetVehiclePetrolTankHealth(vehicle, tankHealth)
    SetVehicleDirtLevel(vehicle, dirtLevel)

    if type(payload) == 'table' and type(payload.parts) == 'table' then
        for group, entries in pairs(payload.parts) do
            if type(entries) == 'table' then
                for index, status in pairs(entries) do
                    BreakBodyPart(vehicle, group, index, status)
                end
            end
        end
    end

    local stored = type(payload) == 'table' and tonumber(payload.bodyHealth) or nil
    SetVehicleBodyHealth(vehicle, stored or Config.Body.MaxBodyHealth)
end

local function StartWeldPtfx(point)
    local ptfx = Config.Body.Ptfx.weld

    if not pcall(lib.requestNamedPtfxAsset, ptfx.dict, 5000) then return nil end
    if not HasNamedPtfxAssetLoaded(ptfx.dict) then return nil end

    UseParticleFxAsset(ptfx.dict)

    local ok, handle = pcall(StartNetworkedParticleFxLoopedAtCoord, ptfx.name,
        point.x, point.y, point.z, 0.0, 0.0, 0.0, ptfx.scale,
        false, false, false, 1.0)

    return ok and handle or nil
end

local function StopWeldPtfx(handle)
    if not handle then return end

    pcall(StopParticleFxLooped, handle, false)
end

local function PlaySparksPtfx(point)
    local ptfx = Config.Body.Ptfx.sparks

    if not pcall(lib.requestNamedPtfxAsset, ptfx.dict, 5000) then return end
    if not HasNamedPtfxAssetLoaded(ptfx.dict) then return end

    UseParticleFxAsset(ptfx.dict)
    pcall(StartNetworkedParticleFxNonLoopedAtCoord, ptfx.name,
        point.x, point.y, point.z, 0.0, 0.0, 0.0, ptfx.scale, false, false, false)
end

local function BuildInspectPoints(vehicle)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    local points = {}

    for i = 1, #Config.Body.InspectPoints do
        local definition = Config.Body.InspectPoints[i]
        local offsetX, offsetY = 0.0, 0.0

        if definition.axis == 'y' then
            offsetY = definition.side > 0 and (max.y + definition.margin) or (min.y - definition.margin)
        else
            offsetX = definition.side > 0 and (max.x + definition.margin) or (min.x - definition.margin)
        end

        points[i] = {
            id = definition.id,
            label = definition.label,
            anim = definition.anim,
            offset = vector3(offsetX, offsetY, 0.0),
            done = false
        }
    end

    return points
end

--[[ El aro se planta en el suelo, no a la altura del chasis. Si el raycast no
     encuentra piso (el coche esta sobre un puente, en un elevador) se cae a la
     altura de rueda, que es lo unico que no deja el aro flotando en el aire. ]]
local function GroundZ(x, y, z)
    local found, ground = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 1.5, false)
    if found and math.abs(ground - z) < 4.0 then return ground end

    return z - 0.98
end

local function RunInspection(vehicle, duration)
    local points = BuildInspectPoints(vehicle)
    local marker = Config.Body.Inspect.Marker
    local ring, chevron, color = marker.ring, marker.chevron, marker.color
    local pending = #points

    local function PointCoords(point)
        return GetOffsetFromEntityInWorldCoords(vehicle, point.offset.x, point.offset.y, point.offset.z)
    end

    --[[ Se corta antes que el ticket del servidor: llegar al final justo cuando
         el ticket acaba de caducar seria tirar toda la inspeccion a la basura. ]]
    local deadline = GetGameTimer() + Config.Body.TicketMaxMs - 20000
    local textShown = false

    Notify('Rodea el vehículo y revisa los cuatro costados', 'inform')

    --[[ El raycast de suelo solo se rehace si el coche se movio de verdad: con
         el coche quieto, que es lo normal, se paga una vez por punto. ]]
    local lastVehicleCoords = GetEntityCoords(vehicle)

    while pending > 0 do
        Wait(0)

        if not DoesEntityExist(vehicle) then break end
        if cache.vehicle then break end
        if IsPedDeadOrDying(cache.ped, true) then break end
        if GetGameTimer() > deadline then break end

        local pedCoords = GetEntityCoords(cache.ped)
        local vehicleCoords = GetEntityCoords(vehicle)
        if #(pedCoords - vehicleCoords) > Config.Body.Inspect.abortDistance then break end

        if #(vehicleCoords - lastVehicleCoords) > 0.3 then
            lastVehicleCoords = vehicleCoords

            for i = 1, #points do
                points[i].groundZ = nil
            end
        end

        local nearest, nearestDistance = nil, Config.Body.Inspect.pointDistance

        for i = 1, #points do
            local point = points[i]

            if not point.done then
                local coords = PointCoords(point)
                local distance = #(pedCoords - coords)

                if distance <= Config.Body.Inspect.markerDistance then
                    if not point.groundZ then
                        point.groundZ = GroundZ(coords.x, coords.y, coords.z)
                    end

                    DrawMarker(ring.type, coords.x, coords.y, point.groundZ + ring.zOffset,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        ring.scale, ring.scale, ring.height,
                        color.r, color.g, color.b, ring.alpha,
                        false, false, 2, true, nil, nil, false)

                    DrawMarker(chevron.type, coords.x, coords.y, point.groundZ + chevron.zOffset,
                        0.0, 0.0, 0.0, 0.0, 180.0, 0.0,
                        chevron.scale, chevron.scale, chevron.scale,
                        color.r, color.g, color.b, chevron.alpha,
                        true, true, 2, false, nil, nil, false)
                end

                if distance < nearestDistance then
                    nearest, nearestDistance = point, distance
                end
            end
        end

        if nearest then
            if not textShown then
                lib.showTextUI(('[%s] Revisar %s'):format(Config.Body.Inspect.keyLabel, nearest.label))
                textShown = true
            end

            if IsControlJustReleased(0, Config.Body.Inspect.key) then
                lib.hideTextUI()
                textShown = false

                local coords = PointCoords(nearest)
                TaskTurnPedToFaceCoord(cache.ped, coords.x, coords.y, coords.z, 800)
                Wait(400)

                local done = lib.progressBar({
                    duration = duration,
                    label = ('Revisando %s'):format(nearest.label:lower()),
                    canCancel = true,
                    disable = { car = true, move = true, combat = true },
                    anim = ProgressAnim(nearest.anim)
                })

                ClearPedTasks(cache.ped)

                if done then
                    nearest.done = true
                    pending = pending - 1

                    if pending > 0 then
                        Notify(('%s revisado · quedan %d'):format(nearest.label, pending), 'inform')
                    end
                end
            end
        elseif textShown then
            lib.hideTextUI()
            textShown = false
        end
    end

    if textShown then lib.hideTextUI() end

    return pending == 0
end

local function InspectBody(vehicle)
    if working or inspecting then return end
    if carrying then return Notify('Suelta la pieza que llevas encima') end
    if cache.vehicle then return Notify('Bájate del vehículo') end
    if not NetworkGetEntityIsNetworked(vehicle) then return Notify('Ese vehículo no es válido') end

    local netId = VehToNet(vehicle)
    local class = GetVehicleClass(vehicle)

    local response = lib.callback.await('origen_mechanic:cb:startBodyInspection', false, {
        netId = netId,
        class = class
    })

    if type(response) ~= 'table' or not response.success then
        return Notify(type(response) == 'table' and response.message or 'No se puede inspeccionar este vehículo')
    end

    inspecting = true
    local completed = RunInspection(vehicle, response.duration or Config.Body.Inspect.duration)
    inspecting = false

    if not completed then return Notify('Inspección incompleta') end
    if not DoesEntityExist(vehicle) then return end

    local scan = ScanBodyDamage(vehicle)
    if not scan then return Notify('No se pudo leer la carrocería') end

    local result = lib.callback.await('origen_mechanic:cb:finishBodyInspection', false, {
        netId = netId,
        class = class,
        scan = scan
    })

    if type(result) ~= 'table' or not result.success then
        return Notify(type(result) == 'table' and result.message or 'No se pudo registrar la inspección')
    end

    local rows = result.rows or {}
    local filas = {}

    for i = 1, #rows do
        local row = rows[i]
        local arrancada = row.status == Mechanic.BodyStatus.MISSING

        filas[#filas + 1] = {
            titulo = row.detail,
            -- La clave del item («puerta_coche») escrita para leer: «Pieza: puerta coche».
            detalle = ('Pieza: %s'):format((tostring(row.item or ''):gsub('_', ' '))),
            valor = arrancada and 'Arrancada' or 'Dañada',
            tono = arrancada and 'bad' or 'warn'
        }
    end

    MecRiel.Abrir({
        marca = 'lucide:car',
        kicker = MecMarcaTaller,
        titulo = 'Inspección de carrocería',
        renglon = ('Matrícula %s · carrocería %.0f%% · %d pieza(s) pendientes'):format(
            result.plate or '-',
            (result.bodyHealth or Config.Body.MaxBodyHealth) / 10,
            #rows
        ),
        rotulo = MecMarcaTaller,
        grupos = {
            {
                id = 'chapa',
                titulo = 'Chapa',
                icono = 'lucide:hammer',
                vacio = 'Sin daños de chapa',
                filas = filas
            }
        }
    })
end

local function UseBodyInspector()
    if working or inspecting then return end

    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.Body.MaxDistance, false)
    if not vehicle or not DoesEntityExist(vehicle) then return Notify('No hay ningún vehículo cerca') end

    InspectBody(vehicle)
end
exports('UseBodyInspector', UseBodyInspector)

local function RemoveTarget(vehicle)
    if GetResourceState('ox_target') ~= 'started' then return end
    if not vehicle or not DoesEntityExist(vehicle) then return end

    pcall(function()
        exports.ox_target:removeLocalEntity(vehicle, TARGET_NAME)
    end)
end

local function PlayCarryAnim(prop)
    local anim = prop and prop.bone == Config.Repair.Bone.BOX and Config.Repair.Anim.CarryBox or Config.Repair.Anim.CarryHand

    if not pcall(lib.requestAnimDict, anim.dict, 3000) then return anim end

    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 4.0, 1.0, -1, 49, 0, false, false, false)
    return anim
end

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

--- Pieza dañada de este tipo más cercana al mecánico, dentro del alcance.
local function GetClosestEntry(session)
    local part = Config.Body.Parts[session.group]
    local pedCoords = GetEntityCoords(cache.ped)
    local closest, closestIndex, closestDistance = nil, nil, part.reach

    for index in pairs(session.entries) do
        local point = GetBodyPartPoint(session.vehicle, session.group, index)

        if point then
            local distance = #(pedCoords - point)

            if distance < closestDistance then
                closest, closestIndex, closestDistance = point, index, distance
            end
        end
    end

    return closest, closestIndex
end

local function InstallBodyPart(session)
    if working or not carrying then return end

    local vehicle = session.vehicle
    if not DoesEntityExist(vehicle) then return StopCarrying() end

    local point, index = GetClosestEntry(session)
    if not point or not index then
        return Notify(('Ponte junto a la pieza: %s'):format(session.label:lower()))
    end

    working = true
    lib.hideTextUI()

    TaskTurnPedToFaceCoord(cache.ped, point.x, point.y, point.z, 1000)
    Wait(700)

    PlayWorkAnim(session.anim)

    local ptfx = StartWeldPtfx(point)

    if not Mechanic.Minijuego(Config.Body.Repair.minijuego, nil, Config.Body.Repair) then
        StopWeldPtfx(ptfx)
        ClearPedTasks(cache.ped)
        working = false
        Notify('Se te ha ido la soldadura')

        if carrying then PlayCarryAnim(carrying.propConfig) end
        return
    end

    local done = lib.progressBar({
        duration = session.duration,
        label = ('Montando %s'):format(session.label:lower()),
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = ProgressAnim(session.anim)
    })

    StopWeldPtfx(ptfx)
    ClearPedTasks(cache.ped)
    working = false

    if not done then
        if carrying then PlayCarryAnim(carrying.propConfig) end
        return
    end

    if not carrying or not DoesEntityExist(vehicle) then return StopCarrying() end

    local response = lib.callback.await('origen_mechanic:cb:finishBodyRepair', false, {
        netId = session.netId,
        group = session.group,
        index = index,
        class = GetVehicleClass(vehicle)
    })

    StopCarrying()

    if type(response) ~= 'table' or not response.success then
        return Notify(type(response) == 'table' and response.message or 'No se pudo montar la pieza')
    end

    RefreshVehicleBody(vehicle, response.body)
    PlaySparksPtfx(point)

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
                icon = 'fa-solid fa-hammer',
                label = ('Montar %s'):format(session.label),
                distance = Config.Body.TargetDistance,
                canInteract = function()
                    return carrying ~= nil and not working
                end,
                onSelect = function()
                    CreateThread(function() InstallBodyPart(session) end)
                end
            }
        })
    end)

    return ok
end

--[[ `ox_target` es la via normal, pero no esta versionado en el repositorio: si
     no esta arrancado el item quedaria inservible, asi que se cae a una tecla. ]]
local function RunFallbackPrompt(session)
    local shown = false

    while carrying == session do
        Wait(0)

        if not working and DoesEntityExist(session.vehicle) then
            local point = GetClosestEntry(session)

            if point then
                if not shown then
                    lib.showTextUI(('[%s] Montar %s'):format(Config.Body.Inspect.keyLabel, session.label))
                    shown = true
                end

                if IsControlJustReleased(0, Config.Body.Inspect.key) then
                    shown = false
                    InstallBodyPart(session)
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

        if not working then
            if not DoesEntityExist(session.vehicle) then break end
            if cache.vehicle then break end
            if IsPedDeadOrDying(cache.ped, true) then break end
            if #(GetEntityCoords(cache.ped) - GetEntityCoords(session.vehicle)) > 15.0 then break end
            if (GetGameTimer() - startedAt) > Config.Body.TicketMaxMs then break end

            if session.carryAnim and not IsEntityPlayingAnim(cache.ped, session.carryAnim.dict, session.carryAnim.clip, 3) then
                PlayCarryAnim(session.propConfig)

                --[[ PlayCarryAnim cede al pedir el diccionario. Si la sesion termina
                     durante esa cesion, la animacion se repone sobre un mecanico que
                     ya no lleva nada y se queda con las manos ahuecadas para siempre. ]]
                if carrying ~= session then ClearPedTasks(cache.ped) end
            end
        end
    end

    if carrying == session then
        StopCarrying()
    end
end

local function UseBodyPartItem(_, item)
    if type(item) ~= 'table' or type(item.name) ~= 'string' then return end

    local group = Mechanic.ResolveBodyItem(item.name)
    if not group then return end

    if carrying then return Notify('Ya llevas una pieza en las manos') end
    if working or inspecting then return end
    if cache.vehicle then return Notify('Bájate del vehículo') end

    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.Body.MaxDistance, false)
    if not vehicle or not DoesEntityExist(vehicle) then return Notify('No hay ningún vehículo cerca') end
    if not NetworkGetEntityIsNetworked(vehicle) then return Notify('Ese vehículo no es válido') end

    local netId = VehToNet(vehicle)

    local response = lib.callback.await('origen_mechanic:cb:startBodyRepair', false, {
        netId = netId,
        group = group,
        class = GetVehicleClass(vehicle)
    })

    if type(response) ~= 'table' or not response.success then
        return Notify(type(response) == 'table' and response.message or 'No se puede montar esa pieza')
    end

    local part = Config.Body.Parts[group]
    local prop, usedConfig = AttachCarryProp(part.prop)
    local carryAnim = PlayCarryAnim(usedConfig)

    local session = {
        group = group,
        label = response.label or part.label,
        duration = response.duration or Config.Body.Repair.duration,
        entries = response.entries or {},
        anim = part.anim,
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
exports('UseBodyPartItem', UseBodyPartItem)

local function PruneRevisions()
    local total = 0
    for _ in pairs(appliedRevision) do
        total = total + 1
    end

    if total < 256 then return end

    for bagName in pairs(appliedRevision) do
        local entity = GetEntityFromStateBagName(bagName)
        if not entity or entity == 0 or not DoesEntityExist(entity) then
            appliedRevision[bagName] = nil
        end
    end
end

--[[ El servidor es el unico que escribe este statebag. La restauracion solo
     AÑADE roturas y nunca repara: el registro puede ser mas viejo que el coche
     que tenemos delante, y un registro viejo no puede deshacer un golpe nuevo. ]]
AddStateBagChangeHandler(Mechanic.BodyStateKey, nil, function(bagName, _, value, _, _)
    if type(value) ~= 'table' then return end

    CreateThread(function()
        local vehicle = GetEntityFromStateBagName(bagName)

        local deadline = GetGameTimer() + 3000
        while (not vehicle or vehicle == 0 or not DoesEntityExist(vehicle)) and GetGameTimer() < deadline do
            Wait(100)
            vehicle = GetEntityFromStateBagName(bagName)
        end

        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

        local revision = tonumber(value.rev) or 0
        if appliedRevision[bagName] == revision then return end

        PruneRevisions()
        appliedRevision[bagName] = revision
        RestoreBodyDamage(vehicle, value)
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    StopCarrying()
    lib.hideTextUI()
end)

Mechanic.Ocupacion.body = function()
    return carrying ~= nil or working or inspecting
end
