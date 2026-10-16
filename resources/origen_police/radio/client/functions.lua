local propRadio

function AddPropToPlayer(prop1, bone, off1, off2, off3, rot1, rot2, rot3, textureVariation)
    local Player = PlayerPedId()
    local x, y, z = table.unpack(GetEntityCoords(Player))

    if not IsModelValid(prop1) then
        Debuger(tostring(prop1).." is not a valid model!")
        return false
    end

    if not HasModelLoaded(prop1) then
        while not HasModelLoaded(prop1) do
            RequestModel(prop1)
            Wait(100)
        end
    end
    propRadio = CreateObject(joaat(prop1), x, y, z + 0.2, true, true, true)
    if textureVariation ~= nil then
        SetObjectTextureVariation(propRadio, textureVariation)
    end
    AttachEntityToEntity(propRadio, Player, GetPedBoneIndex(Player, bone), off1, off2, off3, rot1, rot2, rot3, true, true, false, true, 1, true)
    PlayerHasProp = true
    SetModelAsNoLongerNeeded(prop1)
    return true
end

function StartTalkRadio(mfrec)
    if Radio.Talking or not Radio.Enabled or Radio.MultiFrec == "none" or exports["origen_police"]:IsHandcuffed() then return end
    if type(mfrec) == "string" then mfrec = {mfrec} end
    if mfrec and type(mfrec) == "table" and Radio.MultiFrec ~= "none" and not Radio.Muted then
        Radio.Talking = {}
        for i = 1, #mfrec do
            if type(mfrec[i]) == "string" then
                local rawFreq = mfrec[i]
                local frecId = ParseFrecID(rawFreq)
                local foundTargets = Radio.MultiFrecTargets[frecId] or Radio.MultiFrecTargets[rawFreq]
                if not foundTargets then
                    for targetFrec, targets in pairs(Radio.MultiFrecTargets) do
                        if ParseFrecID(targetFrec) == frecId or tostring(targetFrec):lower() == rawFreq:lower() then
                            foundTargets = targets
                            break
                        end
                    end
                end
                if foundTargets then
                    for id, _ in pairs(foundTargets) do
                        local numId = tonumber(id)
                        if numId and numId ~= GetPlayerServerId(PlayerId()) then
                            Radio.Talking[numId] = true
                        end
                    end
                end
            end
        end
    elseif Radio.Frec > 0 and Radio.Enabled and not Radio.Muted then
        Radio.Talking = Radio.Targets
    elseif Radio.MultiFrec ~= "none" and not Radio.Muted then
        Radio.Talking = {}
        if Radio.MultiFrecTargets and Radio.MultiFrecTargets[Radio.MultiFrec] then
            for k, _ in pairs(Radio.MultiFrecTargets[Radio.MultiFrec]) do
                local numId = tonumber(k)
                if numId and numId ~= GetPlayerServerId(PlayerId()) then
                    Radio.Talking[numId] = true
                end
            end
        end
    end

    Radio.Talking = CanTalk() and Radio.Talking or false
    
    if Radio.Talking then
        local ped = PlayerPedId()
        local selectedWeapon = GetSelectedPedWeapon(ped)
        local unarmedHash = GetHashKey("WEAPON_UNARMED")
        local hasWeapon = (selectedWeapon ~= unarmedHash and selectedWeapon ~= 0)
        local hideWeapon = (RadioConfig.HideWeaponOnTalk == true)

        CreateThread(function()
            PlayerTargets(Radio.Talking, CurrentFrec)
            TriggerEvent("origen_hud:mostrarRadio")
            TriggerServerEvent("origen_police:server:talking", Radio.Talking, true)
            SendNUIMessage({
                radio = "Talking",
                target = GetPlayerServerId(PlayerId()),
                value = true
            })
            SendNUIMessage({
                radioMenu = "Talking",
                target = GetPlayerServerId(PlayerId()),
                value = true
            })

            local animData = (RadioConfig.Anims and RadioConfig.Anims[Radio.Anim]) or { Dict = "random@arrests", Anim = "generic_radio_chatter" }
            local animDict = animData.Dict
            local animName = animData.Anim

            -- If holding a weapon and anim uses a handheld radio prop, use shoulder mic anim to avoid prop clipping and allow natural weapon holding
            if hasWeapon and animData.Prop then
                animDict = "random@arrests"
                animName = "generic_radio_chatter"
            end

            Radio.ActiveAnimDict = animDict
            Radio.ActiveAnimName = animName

            -- Only attach handheld radio prop if unarmed
            if not hasWeapon and animData.Prop then
                local PropName = animData.Prop
                local PropBone = animData.PropBone
                local PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6 = table.unpack(animData.PropPlacement)
                if not AddPropToPlayer(PropName, PropBone, PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6) then return end
            end

            if not HasAnimDictLoaded(animDict) then
                RequestAnimDict(animDict)
                while not HasAnimDictLoaded(animDict) do
                    Wait(10)
                end
            end

            TaskPlayAnim(ped, animDict, animName, 4.0, 8.0, -1, 49, 0, 0, 0, 0)
            SendNUIMessage({
                startTalkSound = true
            })
            while Radio.Talking do
                Wait(0)
                if not CanTalk() then
                    StopTalkRadio()
                    break
                end
                SetControlNormal(0, 249, 1.0)
                SetControlNormal(1, 249, 1.0)
                SetControlNormal(2, 249, 1.0)
                
                if hideWeapon then
                    SetCurrentPedWeapon(ped, unarmedHash, true)
                    DisablePlayerFiring(ped, true)
                    DisableControlAction(0, 24, true) -- Attack
                    DisableControlAction(0, 257, true) -- Attack 2
                    DisableControlAction(0, 25, true) -- Aim
                    DisableControlAction(0, 263, true) -- Melee Attack 1

                    DisableControlAction(0, 45, true) -- Reload
                    DisableControlAction(0, 47, true)  -- Disable weapon
                    DisableControlAction(0, 264, true) -- Disable melee
                    DisableControlAction(0, 257, true) -- Disable melee
                    DisableControlAction(0, 140, true) -- Disable melee
                    DisableControlAction(0, 141, true) -- Disable melee
                    DisableControlAction(0, 142, true) -- Disable melee
                    DisableControlAction(0, 143, true) -- Disable melee
                    DisableControlAction(0, 45, true) -- Disable key R
                    DisableControlAction(0, 80, true) -- Disable key R
                    DisableControlAction(0, 140, true) -- Disable key R
                    DisableControlAction(0, 250, true) -- Disable key R
                    DisableControlAction(0, 263, true) -- Disable key R
                    DisableControlAction(0, 310, true) -- Disable key R
                else
                    -- When not hiding weapon, only disable melee punching if unarmed
                    if not hasWeapon then
                        DisableControlAction(0, 24, true) -- Attack
                        DisableControlAction(0, 257, true) -- Attack 2
                        DisableControlAction(0, 140, true) -- Disable melee
                        DisableControlAction(0, 141, true) -- Disable melee
                        DisableControlAction(0, 142, true) -- Disable melee
                    end
                end
            end
            
            if hideWeapon then
                SetCurrentPedWeapon(ped, selectedWeapon, false)
            end
        end)
    end
end

function StopTalkRadio()
    if not Radio.Talking then return end
    TriggerServerEvent("origen_police:server:talking", Radio.Talking, false)
    Radio.Talking = false
    MumbleClearVoiceTargetPlayers(1)
    PlayerTargets()
    if DoesEntityExist(propRadio) then
        DeleteEntity(propRadio)
    end
    if Radio.ActiveAnimDict and Radio.ActiveAnimName then
        StopAnimTask(PlayerPedId(), Radio.ActiveAnimDict, Radio.ActiveAnimName, 3.0)
        Radio.ActiveAnimDict = nil
        Radio.ActiveAnimName = nil
    elseif RadioConfig.Anims and RadioConfig.Anims[Radio.Anim] then
        StopAnimTask(PlayerPedId(), RadioConfig.Anims[Radio.Anim].Dict, RadioConfig.Anims[Radio.Anim].Anim, 3.0)
    end
    TriggerEvent("origen_hud:ocultarRadio")
    SendNUIMessage({
        stopTalkSound = true
    })
    SendNUIMessage({
        radio = "Talking",
        target = GetPlayerServerId(PlayerId()),
        value = false
    })
    SendNUIMessage({
        radioMenu = "Talking",
        target = GetPlayerServerId(PlayerId()),
        value = false
    })
end

-- QBox convert metadata key that containt "." into tables
local function LoadIndexedMetadata(playerMetadata, metadataKey)
    if not playerMetadata then return nil end
    if not metadataKey:match('%.') then
        return playerMetadata[metadataKey]
    end
    local metaTable, metaKey = metadataKey:match('([^%.]+)%.(.+)')
    return type(playerMetadata[metaTable]) == "table" and playerMetadata[metaTable][metaKey] or playerMetadata[metadataKey]
end

function LoadPlayer(PlayerData)
    PlayerData = PlayerData or FW_GetPlayerData(true)
    while not PlayerData.citizenid do
        Wait(500)
        PlayerData = FW_GetPlayerData(true)
    end

    local function finalizeLoad()
        local anim = LoadIndexedMetadata(PlayerData.metadata, "radio_police.anim")
        if anim ~= nil then Radio.Anim = tonumber(anim) end

        local clicks = LoadIndexedMetadata(PlayerData.metadata, "radio_police.clicks")
        if clicks ~= nil then Radio.Clicks = clicks end

        local binds = LoadIndexedMetadata(PlayerData.metadata, "radio_police.binds")
        if binds ~= nil and type(binds) == "table" then
            Radio.Binds = binds
            for k, action in pairs(Radio.Binds) do
                local keyUpper = tostring(k):upper()
                RegisterKeyMapping("+r_police_keybind " .. keyUpper, "Radio policial: " .. tostring(action), "keyboard", keyUpper)
            end
        end

        TriggerServerEvent("origen_police:admin:requestRadioBindsSync")

        if RadioConfig.Anims[Radio.Anim] then
            RequestAnimDict(RadioConfig.Anims[Radio.Anim].Dict)
        end

        SendNUIMessage({
            action = "UpdateRadioAnimUI",
            anim = Radio.Anim
        })

        local savedVolStr = GetResourceKvpString("origen_police_radio_vol")
        if savedVolStr then
            local savedVol = tonumber(savedVolStr)
            if savedVol and savedVol >= 0 and savedVol <= 100 then
                SetRadioVolume(math.floor(savedVol + 0.5))
            end
        end
    end

    if Config.Framework == "esx" then
        FW_TriggerCallback("origen_police:server:GetPlayerMetadata", function(metadata)
            if metadata then
                PlayerData.metadata = metadata
            end
            finalizeLoad()
        end)
    else
        finalizeLoad()
    end
end

function UnLoadPlayer()
    if ClearAllTalkingPlayers then ClearAllTalkingPlayers() end
    Radio = {
        Enabled = false,
        Frec = 0,
        Anim = 1,
        Targets = {},
        Talking = false,
        MultiGroup = "none",
        MultiFrec = "none",
        MultiFrecTargets = {},
        Clicks = true,
        Binds = {},
        Muted = false
    }
    SendNUIMessage({ action = "RadioSilenciada", muted = false })
    TriggerServerEvent("origen_police:server:SetFreq", Radio.Frec)
    TriggerServerEvent("origen_police:server:SetMultiFrec", Radio.MultiGroup, Radio.MultiFrec)
end

function SetPlayerConfig(key, value)
    TriggerServerEvent("origen_police:SetMetaData", key, value)
end

function DoAction(action)
    if action == "mute" then
        ToggleMute()
        -- Con la tecla no habia forma de saber como habia quedado (12/10).
        TriggerEvent('origen_notify:client:Notify', 'Radio', Radio.Muted and "Radio silenciada" or "Radio activada", Radio.Muted and "error" or "success")
        TriggerServerEvent("origen_police:server:Mute", Radio.MultiGroup, Radio.Muted)
    end
end

RegisterNUICallback("StartTalkRadio", function(data, cb)
    StartTalkRadio(data)
    cb(true)
end)

RegisterNUICallback("StopTalkRadio", function(data, cb)
    StopTalkRadio()
    cb(true)
end)
