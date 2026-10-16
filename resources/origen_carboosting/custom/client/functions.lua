Custom.GiveKeys = function(veh)
    TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(veh))
end

local lastMinigame = nil
local validDifficulties = {
    easy = true,
    medium = true,
    hard = true,
    extreme = true
}

local function trim(value)
    if type(value) ~= 'string' then return '' end
    return value:match('^%s*(.-)%s*$') or value
end

local function normalizeOptionName(name, options)
    local candidate = trim(name)
    if candidate == '' then return nil end
    for i = 1, #options do
        if string.lower(options[i]) == string.lower(candidate) then
            return options[i]
        end
    end
    return nil
end

local function isMinigameSuccess(value)
    if value == true or value == 1 then return true end
    if type(value) == 'string' then
        local normalized = string.lower(trim(value))
        return normalized == 'true' or normalized == '1' or normalized == 'success' or normalized == 'ok'
    end
    return false
end

local function runOrigenMinigame(exportName, difficulty)
    local p = promise.new()

    local ok, err = pcall(function()
        exports.origen_minijuegos[exportName](exports.origen_minijuegos, difficulty, function(success)
            p:resolve(success)
        end)
    end)

    if not ok then
        -- Fallback a StartHacking si el export no existe
        local ok2 = pcall(function()
            exports.origen_minijuegos:StartHacking(difficulty, function(success)
                p:resolve(success)
            end)
        end)
        -- Sin minijuegos (reiniciando) es un fallo, no una espera eterna.
        if not ok2 then p:resolve(false) end
    end

    return Citizen.Await(p)
end

Custom.Minigame = function(context)
    if not Config.Minigame.Enabled then
        return true
    end

    local category = context and context.category or 'D'
    local difficulty = Config.Minigame.DifficultyByRank[category] or Config.Minigame.DefaultDifficulty
    if context and context.minigameDifficulty and context.minigameDifficulty ~= 'auto' then
        difficulty = context.minigameDifficulty
    end
    difficulty = string.lower(trim(difficulty))
    if not validDifficulties[difficulty] then
        difficulty = Config.Minigame.DefaultDifficulty or 'medium'
    end

    local options = Config.Minigame.Options or {}
    if #options == 0 then
        options = { 'StartHacking' }
    end

    if context and context.minigame and context.minigame ~= '' then
        local normalizedOption = normalizeOptionName(context.minigame, options)
        if normalizedOption then
            options = { normalizedOption }
        end
    end

    if #options == 0 then
        return Config.Minigame.FallbackSuccess and true or nil
    end

    local orderedOptions = {}
    if Config.Minigame.Randomize and #options > 1 then
        local pool = {}
        for i = 1, #options do
            pool[#pool + 1] = options[i]
        end

        if lastMinigame then
            for i = #pool, 1, -1 do
                if pool[i] == lastMinigame then
                    table.remove(pool, i)
                    break
                end
            end
        end

        local selected = pool[math.random(1, #pool)]
        orderedOptions[#orderedOptions + 1] = selected
        lastMinigame = selected

        for i = 1, #options do
            if options[i] ~= selected then
                orderedOptions[#orderedOptions + 1] = options[i]
            end
        end
    else
        orderedOptions = options
    end

    for i = 1, #orderedOptions do
        local result = runOrigenMinigame(orderedOptions[i], difficulty)
        if result ~= nil then
            return result
        end
    end

    return Config.Minigame.FallbackSuccess and true or nil
end

Custom.SendDispatch = function(data)
    -- Data contains data.coords and data.vehicle
    -- Example usage: local plate = GetVehicleNumberPlateText(data.vehicle), local color = GetVehicleColor(data.vehicle)
    local vehicle = data.vehicle
    local model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    local plate = GetVehicleNumberPlateText(vehicle)
    local color1, color2 = GetVehicleColours(vehicle)
    
    TriggerServerEvent("SendAlert:police", {
        coords = data.coords,
        title = "Robo de Vehículo Boosting",
        type = "FORZAR",
        message = "Se ha reportado un robo de un " .. model .. " con matrícula " .. plate,
        metadata = {
            model = model,
            plate = plate,
            color = {color1, color2}
        },
        job = {"police", "sheriff", "fib"},
        ignoreCooldown = true
    })
end

Custom.VehicleDestroy = function(veh)
    Internal.Notify(locale('in_game.notifications.vehicle_explosion', 20))
    SetTimeout(20000, function()
        if DoesEntityExist(veh) then
            AddExplosion(GetEntityCoords(veh), 0, 100.0, true, false, true)
        end
    end)
end

Custom.IsOnDuty = function()
    return exports['origen_police']:IsOnDuty()
end