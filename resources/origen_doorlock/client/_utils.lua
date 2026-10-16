Utils = {}
tempData = {}

Utils.PlayAnim = function(ped, dict, anim, time)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(100)
    end

    TaskPlayAnim(ped, dict, anim, 8.0, 8.0, -1, 48, 0, 0, 0, 0)
    if time then
        Wait(time)
        ClearPedTasks(ped)
    end
end

Utils.PlaySound = function(soundID, volume)
    SendNUIMessage({
        action = 'playSound',
        sound = soundID,
        volume = volume
    })
end

Utils.Raycast = function(flags, ignore, distance)
    local ped = PlayerPedId()
	local coords, normal = GetWorldCoordFromScreenCoord(0.5, 0.5)
	local destination = coords + normal * (distance or 10)
	local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, flags or 511, ped, ignore or 4)

	while true do
		Wait(0)
		local retval, hit, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultIncludingMaterial(handle)

		if retval ~= 1 then
			return hit, entityHit, endCoords, surfaceNormal, materialHash
		end
	end
end

Utils.getDoorFromEntity = function(data)
    local entity = type(data) == 'table' and data.entity or data

    if not entity then return end

    local state = Entity(entity)?.state
    local id = state?.doorId

    if not id then return end

    local door = Doors[id]

    if not door then
        state.doorId = nil
    end

    return door
end

Utils.IsNotDoor = function(data)
    local entity = type(data) == 'number' and data or data.entity
    return not Utils.getDoorFromEntity(entity)
end

Utils.DrawEntity = function(entity, bool)
    SetEntityDrawOutline(entity, bool)
    SetEntityDrawOutlineColor(255, 255, 255, 100)
    SetEntityDrawOutlineShader(1)
end

Utils.addDoorlock = function(data)
    local entity = type(data) == 'number' and data or data.entity
    local model = GetEntityModel(entity)
    local coords = GetEntityCoords(entity)

    AddDoorToSystem(`temp`, model, coords.x, coords.y, coords.z, false, false, false)
    DoorSystemSetDoorState(`temp`, 4, false, false)

    coords = GetEntityCoords(entity)
    tempData[#tempData + 1] = {
        entity = entity,
        model = model,
        coords = coords,
        heading = math.floor(GetEntityHeading(entity) + 0.5)
    }

    RemoveDoorFromSystem(`temp`)
end

Utils.GetInput = function(title, options)
    if Config.Input == 'ox_lib' then
        return lib.inputDialog(title, options)
    elseif Config.Input == 'org-input' then
        local inputs = {}
        for i, option in pairs(options) do
            local inputType = 'text'
            if option.type == 'number' then
                inputType = 'number'
            elseif option.password or option.type == 'password' then
                inputType = 'password'
            end
            
            inputs[#inputs + 1] = {
                type = inputType,
                name = "input_" .. i,
                text = option.label,
                isRequired = option.required or false,
                default = option.default or ''
            }
        end
        
        local dialog = exports['org-input']:ShowInput({
            header = title,
            submitText = "Confirmar",
            icon = 'fa-solid fa-key',
            inputs = inputs
        })
        
        if dialog then
            local result = {}
            for i = 1, #options do
                result[i] = dialog["input_" .. i]
            end
            return result
        end
        return nil
    elseif Config.Input == 'qb-input' then
        local inputs = {}
        for i, option in pairs(options) do
            local inputType = 'text'
            if option.type == 'number' then
                inputType = 'number'
            elseif option.password then
                inputType = 'password'
            end
            
            inputs[#inputs + 1] = {
                text = option.label,
                name = "input_" .. i,
                type = inputType,
                isRequired = option.required or false,
                default = option.default or ''
            }
        end
        
        local dialog = exports['qb-input']:ShowInput({
            header = title,
            submitText = "Confirmar",
            inputs = inputs
        })
        
        if dialog then
            local result = {}
            for i = 1, #options do
                result[i] = dialog["input_" .. i]
            end
            return result
        end
        return nil
    else
        return lib.inputDialog(title, options)
    end
end