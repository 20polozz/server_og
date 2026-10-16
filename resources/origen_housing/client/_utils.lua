Utils = {}

local function RotationToDirection(rotation)
    local x = rotation.x * math.pi / 180.0
    local z = rotation.z * math.pi / 180.0
    local num = math.abs(math.cos(x))
    return vector3((-math.sin(z) * num), (math.cos(z) * num), math.sin(x))
end

local function RayCastGamePlayCamera(distance, camCoords, camRot)
    local cameraRotation = camRot or GetGameplayCamRot()
    local cameraCoord = camCoords or GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

Utils.GetScreenCoords = function(distance, camCoords, camRot)
	local hit, coords, entity = RayCastGamePlayCamera(distance or 1000.0, camCoords, camRot)
    return hit, coords, entity
end

Utils.DisableControls = function(controls, cursor)
    if not controls then return end

    for i = 1, #controls do
        DisableControlAction(2, controls[i], true)
    end
    DisablePlayerFiring(PlayerId(), true)

    if cursor then
        SetMouseCursorActiveThisFrame()
    end
end

Utils.isInsidePolyzone = function(coords, polyzone)
    local x, y = coords.x, coords.y
    local inside = false
    local j = #polyzone

    for i = 1, #polyzone do
        local xi, yi = polyzone[i].x, polyzone[i].y
        local xj, yj = polyzone[j].x, polyzone[j].y

        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        
        j = i
    end

    return inside
end

Utils.CheckModelExist = function(model)
    model = GetHashKey(model)

    if not IsModelInCdimage(model) then
        return false
    end

    return true
end

Utils.FormatTime = function(minutes)
    if minutes >= 60 then
        local hours = math.floor(minutes / 60)
        local remainingMinutes = minutes % 60
        return string.format("%d hour(s) %d minute(s)", hours, remainingMinutes)
    else
        return string.format("%d minute(s)", minutes)
    end
end
 
local function World3DToScreen2D(pos)
    local _, sX, sY = GetScreenCoordFromWorldCoord(pos.x, pos.y, pos.z)
    return vector2(sX, sY)
end

local function ScreenRelToWorld(camPos, camRot, cursor)
    local camForward = RotationToDirection(camRot)
    local rotUp = vector3(camRot.x + 1.0, camRot.y, camRot.z)
    local rotDown = vector3(camRot.x - 1.0, camRot.y, camRot.z)
    local rotLeft = vector3(camRot.x, camRot.y, camRot.z - 1.0)
    local rotRight = vector3(camRot.x, camRot.y, camRot.z + 1.0)
    local camRight = RotationToDirection(rotRight) - RotationToDirection(rotLeft)
    local camUp = RotationToDirection(rotUp) - RotationToDirection(rotDown)
    local rollRad = -(camRot.y * math.pi / 180.0)
    local camRightRoll = camRight * math.cos(rollRad) - camUp * math.sin(rollRad)
    local camUpRoll = camRight * math.sin(rollRad) + camUp * math.cos(rollRad)
    local point3DZero = camPos + camForward * 1.0
    local point3D = point3DZero + camRightRoll + camUpRoll
    local point2D = World3DToScreen2D(point3D)
    local point2DZero = World3DToScreen2D(point3DZero)
    local scaleX = (cursor.x - point2DZero.x) / (point2D.x - point2DZero.x)
    local scaleY = (cursor.y - point2DZero.y) / (point2D.y - point2DZero.y)
    local point3Dret = point3DZero + camRightRoll * scaleX + camUpRoll * scaleY
    local forwardDir = camForward + camRightRoll * scaleX + camUpRoll * scaleY
    return point3Dret, forwardDir
end

Utils.GetEntityOnScreen = function(camPos, camRot)

    local camRot = camRot or GetGameplayCamRot(0)
    local camPos = camPos or GetGameplayCamCoord()
    local posX = GetControlNormal(0, 239)
    local posY = GetControlNormal(0, 240)
    local cursor = vector2(posX, posY)
    local cam3DPos, forwardDir = ScreenRelToWorld(camPos, camRot, cursor)
    local direction = camPos + forwardDir * 500.0
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(cam3DPos, direction, 1, 0, 0)
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)

    local rayHandle2 = StartExpensiveSynchronousShapeTestLosProbe(cam3DPos, direction, 16, 0, 0)
    local _, hit2, _, _, entityHit2 = GetShapeTestResult(rayHandle2)

    if hit2 == 1 then
        return true, entityHit2 
    elseif hit == 1 then
        return true, entityHit 
    else
        return false, -1 
    end
end

Utils.ScreenToWorld = function(camPos, camRot)
    local camRot = camRot or GetGameplayCamRot(0)
    local camPos = camPos or GetGameplayCamCoord()
    local posX = GetControlNormal(0, 239)
    local posY = GetControlNormal(0, 240)
    local cursor = vector2(posX, posY)
    local cam3DPos, forwardDir = ScreenRelToWorld(camPos, camRot, cursor)
    local direction = camPos + forwardDir * 500.0
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(cam3DPos, direction, 1, 0, 0)
    local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
    
    return hit, endCoords
end

-- Test box

local box = nil

Utils.CreateMainBox = function()
    if box then
        DeleteEntity(box)
        box = nil
        return
    end

    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local coords = vector4(pcoords.x, pcoords.y, pcoords.z, heading)

    local model = GetHashKey('origen_house_showcase')

    lib.requestModel(model)

    box = CreateObject(model, coords.x, coords.y, coords.z, 0.0, false, false, false)
    SetEntityHeading(box, 0.0)
    FreezeEntityPosition(box, true)

    local objCoords = GetEntityCoords(box)
    SetEntityCoords(ped, objCoords.x, objCoords.y, objCoords.z + 1.0)
    SetModelAsNoLongerNeeded(model)
    return box
end

Utils.IsClearAhead = function(distance)
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local forwardVector = GetEntityForwardVector(ped)

    local endCoords = vector3(
        pedCoords.x + forwardVector.x * distance,
        pedCoords.y + forwardVector.y * distance,
        pedCoords.z + forwardVector.z * distance
    )

    local rayHandle = StartShapeTestRay(pedCoords.x, pedCoords.y, pedCoords.z, endCoords.x, endCoords.y, endCoords.z, 1, ped, 0)
    local _, hit, _, _, _ = GetShapeTestResult(rayHandle)
    
    return hit == 1
end

Utils.PlayAnim = function(ped, dict, anim, time)
    lib.requestAnimDict(dict)

    TaskPlayAnim(ped, dict, anim, 8.0, 8.0, -1, 48, 0, 0, 0, 0)
    RemoveAnimDict(dict)
    if time then
        Wait(time)
        ClearPedTasks(ped)
    end
end

--[[ Marcar una vivienda en el mapa.

     Antes esto creaba un blip del juego. Ya no: el punto se registra en
     origen_map y de ahi lo leen los tres mapas del servidor —el minimapa, el
     del menu de pausa y la pestaña de Ciudad del inventario—.

     Lo que se gana es el nombre. Un blip solo sabe decir su numero de sprite,
     y los mapas de Leaflet tenian que adivinar de ahi que era cada cosa, asi
     que todas las casas salian llamadas «Vivienda». Ahora sale «Casa 24» o
     «Casa 24 en venta», que es lo que ya se escribia en el rotulo del blip y
     no llegaba a ninguna parte.

     El sprite y el color que se elegian en la configuracion dejan de hacer
     falta: aqui la chincheta es dibujo nuestro. Lo que sigue mandando es el
     interruptor de si la vivienda se marca o no. ]]
--[[ `como` (opcional) dice QUE vivienda es, para que no salgan todas iguales:
       icono   'casa', 'casa_venta' u 'hotel' (dibujos de los dos mapas)
       mia     true si es tuya: tu casa o el hotel donde tienes habitacion.
               Va en el rosa de «lo tuyo» y con la chincheta de lo propio. ]]
local COLOR_MIO = '#fc0259'

Utils.MarcarEnMapa = function(clave, coords, nombre, cat, como)
    como = como or {}
    OrigenMapa.Poner(clave, {
        x = coords.x, y = coords.y, z = coords.z,
        cat = cat or 'housing',
        nombre = nombre,
        icono = como.icono,
        color = como.mia and COLOR_MIO or nil,
        propio = como.mia and true or nil,
    })
    return clave
end

Utils.QuitarDelMapa = function(clave)
    OrigenMapa.Quitar(clave)
end
