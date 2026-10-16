local deleteLazer = false

local function RotationToDirection(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
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

local function DrawEntityBoundingBox(entity, color)
    local model = GetEntityModel(entity)
    local min, max = GetModelDimensions(model)
    local rightVector, forwardVector, upVector, position = GetEntityMatrix(entity)

    -- Calculate size
    local dim =
	{
		x = 0.5*(max.x - min.x),
		y = 0.5*(max.y - min.y),
		z = 0.5*(max.z - min.z)
	}

    local FUR =
    {
		x = position.x + dim.y*rightVector.x + dim.x*forwardVector.x + dim.z*upVector.x,
		y = position.y + dim.y*rightVector.y + dim.x*forwardVector.y + dim.z*upVector.y,
		z = 0
    }

    local FUR_bool, FUR_z = GetGroundZFor_3dCoord(FUR.x, FUR.y, 1000.0, 0)
    FUR.z = FUR_z
    FUR.z = FUR.z + 2 * dim.z

    local BLL =
    {
        x = position.x - dim.y*rightVector.x - dim.x*forwardVector.x - dim.z*upVector.x,
        y = position.y - dim.y*rightVector.y - dim.x*forwardVector.y - dim.z*upVector.y,
        z = 0
    }
    local BLL_bool, BLL_z = GetGroundZFor_3dCoord(FUR.x, FUR.y, 1000.0, 0)
    BLL.z = BLL_z

    -- DEBUG
    local edge1 = BLL
    local edge5 = FUR

    local edge2 =
    {
        x = edge1.x + 2 * dim.y*rightVector.x,
        y = edge1.y + 2 * dim.y*rightVector.y,
        z = edge1.z + 2 * dim.y*rightVector.z
    }

    local edge3 =
    {
        x = edge2.x + 2 * dim.z*upVector.x,
        y = edge2.y + 2 * dim.z*upVector.y,
        z = edge2.z + 2 * dim.z*upVector.z
    }

    local edge4 =
    {
        x = edge1.x + 2 * dim.z*upVector.x,
        y = edge1.y + 2 * dim.z*upVector.y,
        z = edge1.z + 2 * dim.z*upVector.z
    }

    local edge6 =
    {
        x = edge5.x - 2 * dim.y*rightVector.x,
        y = edge5.y - 2 * dim.y*rightVector.y,
        z = edge5.z - 2 * dim.y*rightVector.z
    }

    local edge7 =
    {
        x = edge6.x - 2 * dim.z*upVector.x,
        y = edge6.y - 2 * dim.z*upVector.y,
        z = edge6.z - 2 * dim.z*upVector.z
    }

    local edge8 =
    {
        x = edge5.x - 2 * dim.z*upVector.x,
        y = edge5.y - 2 * dim.z*upVector.y,
        z = edge5.z - 2 * dim.z*upVector.z
    }

    DrawLine(edge1.x, edge1.y, edge1.z, edge2.x, edge2.y, edge2.z, color.r, color.g, color.b, color.a)
    DrawLine(edge1.x, edge1.y, edge1.z, edge4.x, edge4.y, edge4.z, color.r, color.g, color.b, color.a)
    DrawLine(edge2.x, edge2.y, edge2.z, edge3.x, edge3.y, edge3.z, color.r, color.g, color.b, color.a)
    DrawLine(edge3.x, edge3.y, edge3.z, edge4.x, edge4.y, edge4.z, color.r, color.g, color.b, color.a)
    DrawLine(edge5.x, edge5.y, edge5.z, edge6.x, edge6.y, edge6.z, color.r, color.g, color.b, color.a)
    DrawLine(edge5.x, edge5.y, edge5.z, edge8.x, edge8.y, edge8.z, color.r, color.g, color.b, color.a)
    DrawLine(edge6.x, edge6.y, edge6.z, edge7.x, edge7.y, edge7.z, color.r, color.g, color.b, color.a)
    DrawLine(edge7.x, edge7.y, edge7.z, edge8.x, edge8.y, edge8.z, color.r, color.g, color.b, color.a)
    DrawLine(edge1.x, edge1.y, edge1.z, edge7.x, edge7.y, edge7.z, color.r, color.g, color.b, color.a)
    DrawLine(edge2.x, edge2.y, edge2.z, edge8.x, edge8.y, edge8.z, color.r, color.g, color.b, color.a)
    DrawLine(edge3.x, edge3.y, edge3.z, edge5.x, edge5.y, edge5.z, color.r, color.g, color.b, color.a)
    DrawLine(edge4.x, edge4.y, edge4.z, edge6.x, edge6.y, edge6.z, color.r, color.g, color.b, color.a)
end

--[[ Rótulo de abajo al centro: chapa pegatina (PegatinaChapa, en
     client/tags.lua), tinta negra, sin códigos de color de GTA. ]]
local function Draw2DText(content)
    PegatinaChapa(0.5, 0.9, content, 0.36)
end

local function MathRound(value, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(value * mult + 0.5) / mult
end

--[[ La ayuda de las teclas va por origen_notify (la pastilla de abajo, como
     en el resto del servidor) y no en texto de GTA. Se manda solo cuando
     cambia: DrawText habla con la NUI y cada fotograma seria un mensaje. ]]
local ayudaPuesta = false

local function PonerAyuda(poner)
    if poner == ayudaPuesta then return end
    ayudaPuesta = poner
    if poner then
        exports.origen_notify:DrawText('E', 'Borrar el objeto', { 'G', 'Copiar sus datos' })
    else
        exports.origen_notify:HideText()
    end
end

local function treadDeleteLazer()
    while deleteLazer do
        local color = {r = 216, g = 27, b = 85, a = 220}   -- rosa pegatina
        local position = GetEntityCoords(PlayerPedId())
        local hit, coords, entity = RayCastGamePlayCamera(1000.0)
        if hit and (IsEntityAVehicle(entity) or IsEntityAPed(entity) or IsEntityAnObject(entity)) then
            local entityCoord = GetEntityCoords(entity)
            local minimum, maximum = GetModelDimensions(GetEntityModel(entity))
            local netID = NetworkGetNetworkIdFromEntity(entity)
            DrawEntityBoundingBox(entity, color)
            DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
            Draw2DText('NetID: ' .. netID .. '   Entidad: ' .. entity .. '   Modelo: ' .. GetEntityModel(entity) .. "   Coordenadas: " .. MathRound(coords.x, 2) .. " " .. MathRound(coords.y, 2) .. " " .. MathRound(coords.z, 2) .. "   Distancia: " .. MathRound(#(coords - position), 2))
            PonerAyuda(true)
            if IsControlJustReleased(0, 38) then
                SetEntityAsMissionEntity(entity, true, true)
                TriggerServerEvent('origen_admin:server:DeleteEntity', netID)
            end

            if IsControlJustReleased(0, 58) then
                local heading = GetEntityHeading(entity)
                TriggerServerEvent('origen_admin:server:GetAndCopyObjectData', GetEntityModel(entity), entityCoord, heading)
            end
        else
            PonerAyuda(false)
            if coords.x ~= 0.0 and coords.y ~= 0.0 then
                Draw2DText("Coordenadas: " .. MathRound(coords.x, 2) .. " " .. MathRound(coords.y, 2) .. " " .. MathRound(coords.z, 2) .. "   Distancia: " .. MathRound(#(coords - position), 2))
                DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
                DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g, color.b, color.a, false, true, 2, nil, nil, false)
            end
        end
        Wait(3)
    end
    PonerAyuda(false)
end

RegisterNetEvent('origen_admin:client:CopyObjectData', function(data)
    SendNUIMessage({
        action = 'copyToClipboard',
        text = data
    })
    ShowNotification('Datos del objeto copiados al portapapeles')
end)

--- Igual que en noclip: `deleteLazer` es local y hace falta fuera.
function LaserActivo()
    return deleteLazer == true
end

function ToggleLaser()
    deleteLazer = not deleteLazer
    if deleteLazer then
        CreateThread(treadDeleteLazer)
    end
end