if Config.Framework ~= 'qb-core' and Config.Framework ~= 'qbx_core' then return end

RegisterNetEvent("qb-clothes:client:CreateFirstCharacter", function()
    openCreation()
end)

local previewPed = nil
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if previewPed then
        DeleteEntity(previewPed)
    end
    local skin = lib.callback.await("origen_clothing:getAppearance")
    if next(skin) then
        ReloadAppearanceData(false, true)
    end
end)

RegisterNetEvent('origen_clothing:client:qbPreview', function(data)
    if not data then
        if previewPed then
            DeleteEntity(previewPed)
        end
        return
    end
    local citizenid = data.citizenid
    local appearance = getAppearance(citizenid)
    local coords = data.coords

    if previewPed then
        DeleteEntity(previewPed)
    end

    lib.requestModel(appearance.model, 10000)

    previewPed = CreatePed(0, appearance.model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
    SetEntityHeading(previewPed, coords.w)
    FreezeEntityPosition(previewPed, true)

    SetAppearance(previewPed, json.decode(appearance.skin))
end)