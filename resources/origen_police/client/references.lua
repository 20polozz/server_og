local references = {}
local localRefOverride = { sprite = nil, color = nil }
local localRefDisabled = false
local lastSelectedSprite = nil
local lastSelectedColor = (Config.References and Config.References.DefaultColor) or 0
local lastRadioActiveState = false
local lastRadioFrequency = nil

local function IsEmsCategory(cat)
    if not cat and GetPlayerJobCategory then
        cat = GetPlayerJobCategory()
    end
    if not cat then
        local PlayerData = FW_GetPlayerData and FW_GetPlayerData()
        if PlayerData and PlayerData.job and PlayerData.job.name then
            local check = CanOpenTablet and CanOpenTablet(PlayerData.job.name)
            if check and check[2] then
                cat = check[2]
            elseif PlayerData.job.name == "ambulance" then
                cat = "ambulance"
            end
        end
    end
    if not cat then return false end
    cat = tostring(cat):lower()
    local emsCat = tostring(Config.EmsJobCategory or "ambulance"):lower()
    return cat == emsCat or cat == "ambulance" or cat == "ems"
end

local function GetDefaultSprite(cat)
    if IsEmsCategory(cat) then
        return (Config.References and Config.References.DefaultEmsSprite) or 61
    end
    return (Config.References and Config.References.DefaultSprite) or 1
end

local function ResolveSprite(cat, sprite)
    local isEms = IsEmsCategory(cat)
    local s = tonumber(sprite)
    if isEms then
        local defEms = (Config.References and Config.References.DefaultEmsSprite) or 61
        if not s or s == 1 then
            return defEms
        end
        return s
    else
        local def = (Config.References and Config.References.DefaultSprite) or 1
        if not s then
            return def
        end
        return s
    end
end

local function HasActiveRadioFrequency()
    -- 1. origen_police GetMultiFrec export
    local myfrec = exports["origen_police"]:GetMultiFrec()
    if myfrec and myfrec ~= "none" and myfrec ~= "" and myfrec ~= "entrada" and myfrec ~= "0" and myfrec ~= 0 and myfrec ~= false then
        return true, tostring(myfrec)
    end
    -- 2. Radio struct from radio/client
    if Radio and Radio.MultiFrec and Radio.MultiFrec ~= "none" and Radio.MultiFrec ~= "" and Radio.MultiFrec ~= "entrada" and Radio.MultiFrec ~= "0" and Radio.MultiFrec ~= 0 and Radio.MultiFrec ~= false then
        return true, tostring(Radio.MultiFrec)
    end
    -- 3. CurrentFrec global
    if CurrentFrec and CurrentFrec ~= "none" and CurrentFrec ~= "" and CurrentFrec ~= "entrada" and CurrentFrec ~= "0" and CurrentFrec ~= 0 and CurrentFrec ~= false then
        return true, tostring(CurrentFrec)
    end
    -- 4. LocalPlayer state bag radioChannel (pma-voice)
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.radioChannel then
        local ch = tonumber(LocalPlayer.state.radioChannel)
        if ch and ch > 0 then
            return true, tostring(ch)
        end
    end
    -- 5. pma-voice export fallback
    if GetResourceState("pma-voice") == "started" then
        local ok, ch = pcall(function()
            return exports['pma-voice']:getRadioChannel()
        end)
        if ok and tonumber(ch) and tonumber(ch) > 0 then
            return true, tostring(ch)
        end
    end
    return false, nil
end
exports("HasActiveRadioFrequency", HasActiveRadioFrequency)

local DEFAULT_REFERENCES_CONFIG = {
    sprites = {
        ["61"] = "https://docs.fivem.net/blips/radar_hospital.png",
        ["408"] = "https://docs.fivem.net/blips/radar_capture_the_flag.png",
        ["43"] = "https://docs.fivem.net/blips/radar_police_heli.png",
        ["1"] = "https://docs.fivem.net/blips/radar_level.png",
        ["67"] = "https://docs.fivem.net/blips/radar_security_van.png",
        ["623"] = "https://docs.fivem.net/blips/radar_pickup_dtb_blast_decrease.png",
        ["102"] = "https://docs.fivem.net/blips/radar_comedy_club.png",
        ["226"] = "https://docs.fivem.net/blips/radar_gang_vehicle_bikers.png",
        ["38"] = "https://docs.fivem.net/blips/radar_raceflag.png",
        ["496"] = "https://docs.fivem.net/blips/radar_production_weed.png",
        ["442"] = "https://docs.fivem.net/blips/radar_beast.png",
        ["669"] = "https://docs.fivem.net/blips/radar_arena_zr380.png",
        ["741"] = "https://docs.fivem.net/blips/radar_drone_controls.png",
        ["210"] = "https://docs.fivem.net/blips/radar_franklin_family_grey.png",
        ["780"] = "https://docs.fivem.net/blips/radar_docks_export.png",
        ["110"] = "https://docs.fivem.net/blips/radar_gun_shop.png"
    },
    labels = {
        ["61"] = "EMS",
        ["408"] = "RRPP",
        ["43"] = "ASD",
        ["1"] = "COLA",
        ["67"] = "METRO",
        ["623"] = "100s",
        ["102"] = "DB",
        ["226"] = "MARY",
        ["38"] = "SAHP",
        ["496"] = "KING",
        ["442"] = "K9",
        ["669"] = "CABEZA",
        ["741"] = "ASD DRON",
        ["210"] = "FIB",
        ["780"] = "ZEBRA",
        ["110"] = "SWAT"
    },
    colors = {
        ["11"] = "#8dcea7",
        ["12"] = "#70a8ae",
        ["30"] = "#29a5b8",
        ["40"] = "#4c4c4c",
        ["5"] = "#eec64e",
        ["41"] = "#f29d9d",
        ["1"] = "#e03232",
        ["29"] = "#4561ab",
        ["3"] = "#5db6e5",
        ["46"] = "#ecf029",
        ["25"] = "#0c7b56",
        ["15"] = "#6ac4bf",
        ["18"] = "#97cae9",
        ["28"] = "#cda80c",
        ["85"] = "#3d3d3d",
        ["82"] = "#a4ccaa",
        ["34"] = "#ed8ca1",
        ["2"] = "#71cb71",
        ["83"] = "#A854F2",
        ["50"] = "#896ce2",
        ["26"] = "#7ac3fe",
        ["76"] = "#782323",
        ["24"] = "#bbd65b",
        ["0"] = "#ffffff"
    }
}

local refConfigFile = LoadResourceFile(GetCurrentResourceName(), "config/quickmenu-references.json")
local ReferencesConfig = refConfigFile and json.decode(refConfigFile) or DEFAULT_REFERENCES_CONFIG

local function GetSpriteUrl(sprite)
    local s = tostring(sprite or "")
    if ReferencesConfig and ReferencesConfig.sprites and ReferencesConfig.sprites[s] then
        return ReferencesConfig.sprites[s]
    end
    if DEFAULT_REFERENCES_CONFIG.sprites[s] then
        return DEFAULT_REFERENCES_CONFIG.sprites[s]
    end
    if s == "61" then
        return "https://docs.fivem.net/blips/radar_hospital.png"
    end
    return "https://docs.fivem.net/blips/radar_level.png"
end

local function GetColorHex(color)
    local c = tostring(color or "")
    if ReferencesConfig and ReferencesConfig.colors and ReferencesConfig.colors[c] then
        return ReferencesConfig.colors[c]
    end
    if DEFAULT_REFERENCES_CONFIG.colors[c] then
        return DEFAULT_REFERENCES_CONFIG.colors[c]
    end
    return "#2f6bff"
end

local function GetSpriteLabel(sprite)
    local s = tostring(sprite or "")
    if ReferencesConfig and ReferencesConfig.labels and ReferencesConfig.labels[s] then
        return ReferencesConfig.labels[s]
    end
    if DEFAULT_REFERENCES_CONFIG.labels[s] then
        return DEFAULT_REFERENCES_CONFIG.labels[s]
    end
    if s == "61" then
        return "EMS"
    end
    return "Policía"
end

local function ResetMainPlayerBlip()
    local mainBlip = GetMainPlayerBlipId()
    if DoesBlipExist(mainBlip) then
        SetBlipSprite(mainBlip, 6)
        SetBlipColour(mainBlip, 0)
        SetBlipScale(mainBlip, 1.0)
        ShowHeadingIndicatorOnBlip(mainBlip, false)
        SetBlipPriority(mainBlip, 1)
    end
end

local function ActivateDefaultReference(frec)
    if not onduty then return end
    localRefDisabled = false

    local cat = GetPlayerJobCategory()
    local sprite = ResolveSprite(cat, localRefOverride.sprite or lastSelectedSprite)
    local color = localRefOverride.color or lastSelectedColor or (Config.References and Config.References.DefaultColor) or 0

    localRefOverride.sprite = sprite
    localRefOverride.color = color
    lastSelectedSprite = sprite
    lastSelectedColor = color

    TriggerServerEvent("origen_police:server:setLocation", true)
    TriggerServerEvent("origen_police:server:updateref", {
        sprite = sprite,
        color = color,
        hideGPS = false
    })

    UpdateAllBlips()

    SendNUIMessage({
        action = "SyncQuick",
        sprite = sprite,
        color = color
    })
end

local function CheckRadioStateChange()
    if not onduty then return end
    local isActive, frec = HasActiveRadioFrequency()
    if isActive then
        if not lastRadioActiveState or (frec and frec ~= lastRadioFrequency) then
            lastRadioActiveState = true
            lastRadioFrequency = frec

            -- Si el jugador NO tiene referencia (la quitó expresamente o no ha elegido icono),
            -- NO volver a ponérsela bajo ninguna circunstancia al cambiar de frecuencia.
            if not localRefDisabled and localRefOverride.sprite ~= nil then
                UpdateAllBlips()
            end
        end
    else
        if lastRadioActiveState then
            lastRadioActiveState = false
            lastRadioFrequency = nil
            ResetMainPlayerBlip()
            UpdateAllBlips()
        end
    end
end

function UpdateAllBlips()
    if not onduty then
        ResetMainPlayerBlip()
        return
    end

    local inRadio = HasActiveRadioFrequency()
    local myServerId = GetPlayerServerId(PlayerId())
    local myRef = references[tostring(myServerId)] or references[myServerId]

    -- 1. Actualizar el blip del propio jugador local:
    -- Solo se coloca referencia si:
    --  a) Está conectado a una frecuencia de radio activa.
    --  b) NO se la ha quitado / deshabilitado manualmente.
    --  c) No está oculto por hideGPS.
    local mainBlip = GetMainPlayerBlipId()
    if DoesBlipExist(mainBlip) then
        if not inRadio or localRefDisabled or (myRef and myRef.hideGPS) then
            ResetMainPlayerBlip()
        else
            local cat = GetPlayerJobCategory()
            local rawSprite = localRefOverride.sprite or (myRef and myRef.sprite) or lastSelectedSprite
            local sprite = ResolveSprite(cat, rawSprite)
            local color = localRefOverride.color or (myRef and tonumber(myRef.color)) or lastSelectedColor or (Config.References and Config.References.DefaultColor) or 0

            if GetBlipSprite(mainBlip) ~= sprite then
                SetBlipSprite(mainBlip, sprite)
            end
            if GetBlipColour(mainBlip) ~= color then
                SetBlipColour(mainBlip, color)
            end
            SetBlipScale(mainBlip, 1.05)
            SetBlipPriority(mainBlip, 10)
            SetBlipCategory(mainBlip, 7)
            ShowHeadingIndicatorOnBlip(mainBlip, (sprite == 1 or sprite == 6))
        end
    end
end

function SetLocalReferenceOverride(sprite, color)
    if sprite then
        localRefOverride.sprite = tonumber(sprite)
        lastSelectedSprite = tonumber(sprite)
        localRefDisabled = false
    end
    if color then
        localRefOverride.color = tonumber(color)
        lastSelectedColor = tonumber(color)
        localRefDisabled = false
    end
    if not sprite and not color then
        localRefOverride.sprite = nil
        localRefOverride.color = nil
        localRefDisabled = true
        ResetMainPlayerBlip()
    end
    UpdateAllBlips()
end
exports("SetLocalReferenceOverride", SetLocalReferenceOverride)

function GetLocalReference()
    if not onduty or not HasActiveRadioFrequency() or localRefDisabled then
        return {
            sprite = nil,
            color = nil
        }
    end
    local mySource = tostring(GetPlayerServerId(PlayerId()))
    local myRef = references and references[mySource]
    if myRef and myRef.hideGPS then
        return {
            sprite = nil,
            color = nil
        }
    end
    local cat = GetPlayerJobCategory()
    local rawSprite = localRefOverride.sprite or (myRef and myRef.sprite) or lastSelectedSprite
    local sprite = ResolveSprite(cat, rawSprite)
    local color = localRefOverride.color or (myRef and tonumber(myRef.color)) or lastSelectedColor or (Config.References and Config.References.DefaultColor) or 0
    return {
        sprite = sprite,
        color = color
    }
end
exports("GetLocalReference", GetLocalReference)

RegisterNUICallback("SetLocation", function(state, cb)
    if not onduty then
        cb(false)
        return
    end
    state = state.value
    if state == false then
        localRefDisabled = true
        localRefOverride.sprite = nil
        localRefOverride.color = nil
        ResetMainPlayerBlip()
        TriggerServerEvent("origen_police:server:setLocation", false)
        TriggerServerEvent("origen_police:server:removeref")
        SendNUIMessage({
            action = "SyncQuick",
            clearRef = true
        })
    else
        localRefDisabled = false
        local cat = GetPlayerJobCategory()
        local sprite = ResolveSprite(cat, lastSelectedSprite)
        local color = lastSelectedColor or (Config.References and Config.References.DefaultColor) or 0
        localRefOverride.sprite = sprite
        localRefOverride.color = color
        lastSelectedSprite = sprite
        lastSelectedColor = color
        TriggerServerEvent("origen_police:server:setLocation", true)
        if HasActiveRadioFrequency() then
            TriggerServerEvent("origen_police:server:updateref", {
                sprite = sprite,
                color = color,
                hideGPS = false
            })
        end
        UpdateAllBlips()
        SendNUIMessage({
            action = "SyncQuick",
            sprite = sprite,
            color = color
        })
    end
    cb(true)
end)

--[[ Tamaño de las referencias en el minimapa (Ajustes, 12/10). Las dibuja
     origen_map, asi que solo se le pasa el recado; el lo guarda. ]]
RegisterNUICallback("TamanoReferencias", function(data, cb)
    TriggerEvent('origen_map:referencias:tamano', type(data) == "table" and data.tamano or 'normal')
    cb(true)
end)

RegisterNUICallback("RemoveReference", function(data, cb)
    localRefDisabled = true
    localRefOverride.sprite = nil
    localRefOverride.color = nil
    ResetMainPlayerBlip()
    TriggerServerEvent("origen_police:server:removeref")
    TriggerServerEvent("origen_police:server:setLocation", false)
    UpdateAllBlips()
    SendNUIMessage({
        action = "SyncQuick",
        clearRef = true
    })
    cb(true)
end)

RegisterNetEvent("origen_police:client:updateReferences", function(value)
    if not onduty then
        references = {}
        return
    end
    local jobCat = GetPlayerJobCategory()
    if not jobCat then return end
    
    local PlayerData = FW_GetPlayerData()
    local myJobName = PlayerData and PlayerData.job and PlayerData.job.name
    local isBoss = false
    local myLevel = 0
    if PlayerData and PlayerData.job then
        isBoss = PlayerData.job.isboss or (type(PlayerData.job.grade) == "table" and PlayerData.job.grade.isboss) or false
        local grade = PlayerData.job.grade
        if type(grade) == "table" then
            myLevel = grade.level or grade.grade or 0
        else
            myLevel = grade or 0
        end
    end
    myLevel = tonumber(myLevel) or 0
    local isStateAdmin = (myJobName == "sapd")
    local reqGrade = GetMinimunGrade(myJobName, "SeeOthersReferences")
    local canSeeOthers = false
    if isStateAdmin or isBoss then
        canSeeOthers = true
    elseif reqGrade ~= nil and reqGrade ~= 888 then
        canSeeOthers = (myLevel >= tonumber(reqGrade))
    else
        -- Fallback seguro: si no está configurado o devuelve 888, los policías en servicio ven las referencias
        canSeeOthers = true
    end

    local mySource = tostring(GetPlayerServerId(PlayerId()))
    local refs = {}
    for cat, catData in pairs(value) do
        local ignore = false
        if cat == "saspa" and jobCat ~= "saspa" then
            ignore = true
        elseif jobCat == "saspa" and cat ~= "saspa" then
            ignore = true
        end

        if not ignore then
            for k, v in pairs(catData) do
                local idStr = tostring(k)
                if canSeeOthers or idStr == mySource then
                    v.jobCategory = v.jobCategory or cat
                    refs[idStr] = v
                end
            end
        end
    end

    for k, v in pairs(refs) do
        if type(v.coords) == "table" and v.coords.x then
            v.coords = vector3(v.coords.x + 0.0, v.coords.y + 0.0, v.coords.z + 0.0)
        end
    end
    references = refs

    local mySource = tostring(GetPlayerServerId(PlayerId()))
    if references[mySource] then
        if references[mySource].sprite and localRefOverride.sprite == references[mySource].sprite then
            localRefOverride.sprite = nil
        end
        if references[mySource].color and localRefOverride.color == references[mySource].color then
            localRefOverride.color = nil
        end
    end

    UpdateAllBlips()

    SendNUIMessage({
        action = "UpdateUsedColors",
        colors = GetUsedColors()
    })
end)

RegisterNetEvent("origen_police:client:updateQuickmenuReferences", function(payload)
    local data = payload.data or payload
    if data then
        ReferencesConfig = data
    end
    SendNUIMessage({
        action = "updateQuickmenuReferences",
        data = data
    })
end)

function GetUsedColors()
    if not onduty then return {} end
    local usedColors = {}
    local mySource = tostring(GetPlayerServerId(PlayerId()))
    for k, v in pairs(references) do
        if tostring(k) ~= mySource and v.color then
            usedColors[tostring(v.color)] = true
        end
    end
    return usedColors
end

exports("GetUsedColors", GetUsedColors)

RegisterNetEvent("origen_police:client:removeref", function(source, removeAllRefs)
    local idStr = tostring(source)
    local mySource = tostring(GetPlayerServerId(PlayerId()))
    if removeAllRefs then
        references = {}
        if not HasActiveRadioFrequency() or localRefDisabled then
            ResetMainPlayerBlip()
        end
    elseif idStr == mySource then
        references[mySource] = nil
        if not HasActiveRadioFrequency() or localRefDisabled then
            ResetMainPlayerBlip()
        end
    else
        references[idStr] = nil
    end
    UpdateAllBlips()
end)

function ClearReferencesOffDuty()
    references = {}
    localRefDisabled = true
    localRefOverride.sprite = nil
    localRefOverride.color = nil
    lastSelectedSprite = nil
    lastRadioActiveState = false
    lastRadioFrequency = nil

    ResetMainPlayerBlip()
    DisplayPlayerNameTagsOnBlips(false)

    TriggerServerEvent("origen_police:server:removeref")
    TriggerServerEvent("origen_police:server:setLocation", false)
    TriggerServerEvent("origen_police:server:unsubscribeReferences")

    SendNUIMessage({
        action = "SyncQuick",
        clearRef = true
    })
    SendNUIMessage({
        action = "UpdateUsedColors",
        colors = {}
    })
    SendNUIMessage({
        action = "removeref"
    })
end
exports("ClearReferencesOffDuty", ClearReferencesOffDuty)

RegisterNetEvent('origen_police:client:OnJobUpdate', function(jobData)
    localRefOverride.sprite = nil
    localRefOverride.color = nil
    lastSelectedSprite = nil
end)

local referencesThreadRunning = false

function StartReferences()
    if referencesThreadRunning then return end
    referencesThreadRunning = true

    CreateThread(function()
        DisplayPlayerNameTagsOnBlips(true)
        TriggerServerEvent('origen_police:server:subscribeReferences')

        while onduty do
            CheckRadioStateChange()
            UpdateAllBlips()
            Wait(1000)
        end

        referencesThreadRunning = false
        ClearReferencesOffDuty()
    end)
end

CreateThread(function()
    Wait(1500)
    if onduty then
        StartReferences()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    ResetMainPlayerBlip()
end)

-- Escuchar eventos de desconexión o cambio de radio para actualizar la referencia inmediatamente
RegisterNetEvent("origen_police:client:radioConnected", function(frec)
    CheckRadioStateChange()
end)

RegisterNetEvent("origen_police:client:TakeDropRadio", function(state)
    CheckRadioStateChange()
end)

RegisterNetEvent("origen_police:client:Disconnected", function()
    CheckRadioStateChange()
end)

RegisterNetEvent("origen_police:client:SetMultiFrec", function(group, frec)
    CheckRadioStateChange()
end)

AddStateBagChangeHandler('radioChannel', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(bagName, key, value)
    CheckRadioStateChange()
end)

function MiReferenciaParaMapa()
    if not onduty then return nil end
    local inRadio = HasActiveRadioFrequency()
    if not inRadio or localRefDisabled then return nil end

    local myServerId = tostring(GetPlayerServerId(PlayerId()))
    local myRef = references[myServerId] or {}
    if myRef.hideGPS then return nil end

    local cat = GetPlayerJobCategory()
    local rawSprite = localRefOverride.sprite or myRef.sprite or lastSelectedSprite
    local sprite = ResolveSprite(cat, rawSprite)
    local color = localRefOverride.color or tonumber(myRef.color) or lastSelectedColor or (Config.References and Config.References.DefaultColor) or 0
    local hex = GetColorHex(color)
    local url = GetSpriteUrl(sprite)
    local label = GetSpriteLabel(sprite)

    return {
        sprite = sprite,
        color = color,
        hex = hex,
        url = url,
        label = label or (myRef.unit or (IsEmsCategory(cat) and "EMS" or "Policía")),
        unit = myRef.unit or "Sin Asignar",
        lastname = myRef.lastname or ""
    }
end
exports('MiReferenciaParaMapa', MiReferenciaParaMapa)

exports('ReferenciasParaMapa', function()
    if not onduty then return {} end
    local t = {}
    local mySource = tostring(GetPlayerServerId(PlayerId()))

    for id, v in pairs(references) do
        local idStr = tostring(id)
        if not v.hideGPS and idStr ~= mySource then
            local x, y

            local jugador = GetPlayerFromServerId(tonumber(id) or -1)
            local ped = (jugador ~= -1 and NetworkIsPlayerActive(jugador)) and GetPlayerPed(jugador) or 0
            if ped ~= 0 and DoesEntityExist(ped) then
                local p = GetEntityCoords(ped)
                if p.x ~= 0.0 or p.y ~= 0.0 then
                    x, y = p.x, p.y
                end
            end
            if not x and v.coords and v.coords.x then
                x, y = v.coords.x, v.coords.y
            end

            if x then
                local sprite = ResolveSprite(v.jobCategory, v.sprite)
                local color = tonumber(v.color) or (Config.References and Config.References.DefaultColor) or 0
                local hex = GetColorHex(color)
                local url = GetSpriteUrl(sprite)
                local label = GetSpriteLabel(sprite)

                t[#t + 1] = {
                    x = x + 0.0,
                    y = y + 0.0,
                    etiqueta = ('%s %s'):format(v.unit or '', v.lastname or ''),
                    sprite = sprite,
                    color = color,
                    hex = hex,
                    url = url,
                    label = label,
                    source = tonumber(id)
                }
            end
        end
    end

    return t
end)

