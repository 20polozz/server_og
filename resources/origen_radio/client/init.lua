RadioConfig.Multifrec = {}

Config.BindFreqs = {}

if Config.Framework == "qbcore" then
    QBCore = GetCoreObject()
elseif Config.Framework == "esx" then
    ESX = GetCoreObject()
end

function FW_TriggerCallback(...)
    if Config.Framework == "qbcore" then
        QBCore.Functions.TriggerCallback(...)
    elseif Config.Framework == "esx" then
        ESX.TriggerServerCallback(...)
    end
end

function FW_GetPlayerMetadata()
    if Config.MetadataSystem then
        local metadata = nil
        FW_TriggerCallback("origen_radio:server:GetPlayerMetadata", function(data)
            metadata = data
        end)
        while metadata == nil do
            Citizen.Wait(0)
        end
        return metadata
    end
    return nil
end

function FW_GetPlayerData(ignoreMetadata)
    if Config.Framework == "qbcore" then
        local player = QBCore.Functions.GetPlayerData()
        return player
    elseif Config.Framework == "esx" then
        local PlayerData = ESX.GetPlayerData()
        local metadata = nil
        if not ignoreMetadata then 
            metadata = FW_GetPlayerMetadata() or PlayerData.metadata
        end
        return {
            citizenid = PlayerData.identifier,
            items = GetPlayerItems(PlayerData),
            job = PlayerData.job and {
                name = PlayerData.job.name,
                label = PlayerData.job.label,
                grade = {
                    level = PlayerData.job.grade,
                    name = PlayerData.job.grade_label
                },
                -- isboss = IsBoss(PlayerData.job.grade),
                -- onduty = GetResourceState("origen_radio") == "started" and exports["origen_radio"]:GetPoliceDuty() or false
            } or false,
            charinfo = {
                firstname = PlayerData.firstName,
                lastname = PlayerData.lastName or "",
                account = "XXXXXXXXX",
                birthdate = PlayerData.dateofbirth,
                nationality = "XXXXXXXXX",
                gender = PlayerData.sex == "m" and 0 or 1,
            },
            metadata = metadata,
            position = PlayerData.coords
        }
    end
end

function FW_GetPlayersFromCoords(coords, radius)
    if Config.Framework == "qbcore" then
        return QBCore.Functions.GetPlayersFromCoords(coords, radius)
    elseif Config.Framework == "esx" then
        return ESX.Game.GetPlayersInArea(coords, radius)
    end
end

function FW_GetClosestVehicle(coords)
    if Config.Framework == "qbcore" then
        return QBCore.Functions.GetClosestVehicle(coords)
    elseif Config.Framework == "esx" then
        return ESX.Game.GetClosestVehicle(coords)
    end
end

function FW_GetObjects()
    if Config.Framework == "qbcore" then
        return QBCore.Functions.GetObjects()
    elseif Config.Framework == "esx" then
        return ESX.Game.GetObjects()
    end
end

function Fw_GetPeds()
    if Config.Framework == "qbcore" then
        return QBCore.Functions.GetPeds()
    elseif Config.Framework == "esx" then
        return ESX.Game.GetPeds()
    end
end

function FW_GetVehicles()
    if Config.Framework == "qbcore" then
        return QBCore.Functions.GetVehicles()
    elseif Config.Framework == "esx" then
        return ESX.Game.GetVehicles()
    end
end

function FW_SpawnVehicle(model, cb, coords, isNetwork)
    if Config.Framework == "qbcore" then
        QBCore.Functions.SpawnVehicle(model, cb, coords, isNetwork)
    elseif Config.Framework == "esx" then
        ESX.Game.SpawnVehicle(model, coords, 0.0, cb, isNetwork)
    end
end

function FW_DeleteVehicle(vehicle)
    if Config.Framework == "qbcore" then
        QBCore.Functions.DeleteVehicle(vehicle)
    elseif Config.Framework == "esx" then
        ESX.Game.DeleteVehicle(vehicle)
    end
end

function FW_GetClosestPlayer(coords)
    if Config.Framework == "qbcore" then
        return QBCore.Functions.GetClosestPlayer(coords)
    elseif Config.Framework == "esx" then
        return ESX.Game.GetClosestPlayer(coords)
    end
end

function FW_Round(num, numDecimalPlaces)
	if numDecimalPlaces then
		local power = 10 ^ numDecimalPlaces
		return math.floor((num * power) + 0.5) / (power)
	else
		return math.floor(num + 0.5)
	end
end

local function exploreMetatable(mt, indent)
    indent = indent or ""

    for key, value in pairs(mt) do
        if type(value) == "table" then
            exploreMetatable(value, indent .. "  ")
        else
            if key == "__index" and type(value) == "function" then
                return value
            end
        end
    end
end

Citizen.CreateThread(function()
    local pma_metatable = getmetatable(exports["pma-voice"])
    if type(pma_metatable) == "table" then
        local funcReference = exploreMetatable(pma_metatable)
        local successPT, error = pcall(function()
            funcReference("pma-voice", "playerTargets")
        end)
        local successTV, error2 = pcall(function()
            funcReference("pma-voice", "toggleVoice")
        end)
        
        if not successPT and not successTV then 
            print("^4origen_radio: Can't find pma-voice playerTargets and toggleVoice exports, please make sure to read the installation.txt file")
            return
        end

        if not successPT then
            print("^4origen_radio: Can't find pma-voice playerTargets export, please make sure to have the latest version of pma-voice or ask for support in the discord server")
            return
        end
    end
end)