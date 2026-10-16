function IsBoss(grade)
    local PlayerData = FW_GetPlayerData()
    if PlayerData and PlayerData.job then
        if PlayerData.job.name == "sapd" then return true end
        if PlayerData.job.isboss or (PlayerData.job.grade and PlayerData.job.grade.isboss) then
            return true
        end
    end

    -- Fallback por nivel (Config.BossGrade)
    grade = tonumber(grade)
    if grade then
        for _, v in pairs(Config.BossGrade) do
            if grade >= v then
                return true
            end
        end
    end
    return false
end

function FW_Round(num, numDecimalPlaces)
	if numDecimalPlaces then
		local power = 10 ^ numDecimalPlaces
		return math.floor((num * power) + 0.5) / (power)
	else
		return math.floor(num + 0.5)
	end
end

CreateThread(function()
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
    
    local pma_metatable = getmetatable(exports["pma-voice"])
    if type(pma_metatable) == "table" then
        local funcReference = exploreMetatable(pma_metatable)
        local successPT, _ = pcall(function()
            funcReference("pma-voice", "playerTargets")
        end)
        local successTV, _ = pcall(function()
            funcReference("pma-voice", "toggleVoice")
        end)
        
        if not successPT and not successTV then
            print("^4origen_police: Can't find pma-voice playerTargets and toggleVoice exports, please make sure to read the installation.txt file")
            return
        end

        if not successPT then
            print("^4origen_police: Can't find pma-voice playerTargets export, please make sure to have the latest version of pma-voice or ask for support in the discord server")
            return
        end
    end
end)

-- OX LIB CHECK
if Config.OxLibMenu and not lib then
    Debuger("You have set the menu to ox_lib but you don't have uncommented the ox_lib line in the fxmanifest of origen_police")
end

function AddReplaceExport(resourceName, exportName, func)
    AddEventHandler("__cfx_export_"..resourceName.."_"..exportName, function(cb)
        return cb(func)
    end)
end

local function syncReportTags()
    FW_TriggerCallback("origen_police:server:GetReportTags", function(tags)
        if type(tags) == "table" and Config and Config.Translations then
            Config.Translations.ReportTags = tags
            SendNUIMessage({
                action = "UpdateReportTags",
                tags = tags
            })
        end
    end)
end

local function syncPermissions()
    FW_TriggerCallback("origen_police:server:SyncPermissions", function(serverPerms, serverDivs, serverLics)
        if serverPerms then
            Config.Permissions = serverPerms
            SendNUIMessage({
                action = "adminPermissionsUpdated",
                perms = Config.Permissions
            })
        end
        if serverDivs and type(serverDivs) == "table" and next(serverDivs) ~= nil then
            if not Config.Translations then Config.Translations = {} end
            Config.Translations.DivisionsData = serverDivs
            if Translations then Translations.DivisionsData = serverDivs end
            SendNUIMessage({
                action = "updateDivisionsData",
                divisions = serverDivs
            })
        end
        if serverLics and type(serverLics) == "table" and next(serverLics) ~= nil then
            if not Config.Translations then Config.Translations = {} end
            Config.Translations.PoliceLicenses = serverLics
            if Translations then Translations.PoliceLicenses = serverLics end
            SendNUIMessage({
                action = "updatePoliceLicenses",
                licenses = serverLics
            })
        end
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    syncReportTags()
    syncPermissions()
    TriggerServerEvent("origen_police:admin:requestQuickmenuSync")
    TriggerServerEvent("origen_police:server:requestDivisionsSync")
    TriggerServerEvent("origen_police:server:requestLicensesSync")
end)

RegisterNetEvent('esx:playerLoaded', function()
    syncReportTags()
    syncPermissions()
    TriggerServerEvent("origen_police:admin:requestQuickmenuSync")
    TriggerServerEvent("origen_police:server:requestDivisionsSync")
    TriggerServerEvent("origen_police:server:requestLicensesSync")
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(2000)
        syncReportTags()
        syncPermissions()
        TriggerServerEvent("origen_police:server:requestDivisionsSync")
        TriggerServerEvent("origen_police:server:requestLicensesSync")
    end
end)

RegisterNetEvent("origen_police:client:UpdateReportTags", function(tags)
    if type(tags) == "table" and Config and Config.Translations then
        Config.Translations.ReportTags = tags
    end
    SendNUIMessage({
        action = "UpdateReportTags",
        tags = tags
    })
end)

RegisterNetEvent("origen_police:client:updateDivisionsData", function(divisions)
    if type(divisions) == "string" then
        pcall(function() divisions = json.decode(divisions) end)
    end
    if type(divisions) == "table" then
        if not Config.Translations then Config.Translations = {} end
        Config.Translations.DivisionsData = divisions
        if Translations then Translations.DivisionsData = divisions end
        SendNUIMessage({
            action = "updateDivisionsData",
            divisions = divisions
        })
    end
end)

RegisterNetEvent("origen_police:client:updatePoliceLicenses", function(licenses)
    if type(licenses) == "string" then
        pcall(function() licenses = json.decode(licenses) end)
    end
    if type(licenses) == "table" then
        if not Config.Translations then Config.Translations = {} end
        Config.Translations.PoliceLicenses = licenses
        if Translations then Translations.PoliceLicenses = licenses end
        SendNUIMessage({
            action = "updatePoliceLicenses",
            licenses = licenses
        })
    end
end)