animLoaded = false
local propRadio

function AddPropToPlayer(prop1, bone, off1, off2, off3, rot1, rot2, rot3, textureVariation)
    local Player = PlayerPedId()
    local x, y, z = table.unpack(GetEntityCoords(Player))

    if not IsModelValid(prop1) then
        DebugPrint(tostring(prop1).." is not a valid model!")
        return false
    end

    -- Safety cleanup: if a prop exists, delete it before creating a new one
    if propRadio and DoesEntityExist(propRadio) then
        DeleteEntity(propRadio)
        propRadio = nil
    end

    if not HasModelLoaded(prop1) then
        RequestModel(prop1)
        while not HasModelLoaded(prop1) do
            -- If player stops talking while loading, cancel creation
            if not Radio.Talking then return false end 
            Wait(10)
        end
    end

    -- Final check before creating the object
    if not Radio.Talking then return false end

    propRadio = CreateObject(joaat(prop1), x, y, z + 0.2, true, true, true)
    if textureVariation ~= nil then
        SetObjectTextureVariation(propRadio, textureVariation)
    end
    AttachEntityToEntity(propRadio, Player, GetPedBoneIndex(Player, bone), off1, off2, off3, rot1, rot2, rot3, true, true, false, true, 1, true)
    PlayerHasProp = true
    SetModelAsNoLongerNeeded(prop1)
    return true
end



local lastAnimUsed = 1
function StartTalkRadio(mfrec)
    if Radio.Talking or not Radio.Enabled or (Radio.MultiFrec == "none" and Radio.Frec <= 0) then return end
    if mfrec and Radio.MultiFrec ~= "none" and not Radio.Muted then
        Radio.Talking = {}
        for _, id in pairs(mfrec) do
            Radio.Talking[id] = true
        end
    elseif Radio.Frec > 0 and Radio.Enabled and not Radio.Muted then
        Radio.Talking = Radio.Targets
    elseif Radio.MultiFrec ~= "none" and not Radio.Muted then
        local targets = {}
        local rawTargets = Radio.MultiFrecTargets[Radio.MultiFrec] or {}
        for id, _ in pairs(rawTargets) do
            local sId = tonumber(id)
            if sId then
                targets[sId] = true
            end
        end
        Radio.Talking = targets
    end
    if IsPlayerDead() then return end
    if not CanTalk() then return end
    if Radio.Talking then
        local selectedWeapon = GetSelectedPedWeapon(PlayerPedId())
        Citizen.CreateThread(function()
            PlayerTargets(Radio.Talking)
            TriggerEvent("origen_hud:mostrarRadio")
            TriggerServerEvent("origen_radio:server:talking", Radio.Talking, true)
            
            -- Speaker Mode: People nearby hear you
            if PlayerMetadata.speakerMode then
                exports["pma-voice"]:overrideProximityRange(RadioConfig.Speaker.Distance or 5.0, true)
            end
            local ped = PlayerPedId()
            lastAnimUsed = tonumber(Radio.Anim) or 1
            local animData = RadioConfig.Anims[lastAnimUsed]
            
            if animData.Prop then
                PropName = animData.Prop
                PropBone = animData.PropBone
                PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6 = table.unpack(animData.PropPlacement)
                if not AddPropToPlayer(PropName, PropBone, PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6, textureVariation) then return end
            end
            
            if not HasAnimDictLoaded(animData.Dict) then
                RequestAnimDict(animData.Dict)
                while not HasAnimDictLoaded(animData.Dict) do
                    Citizen.Wait(10)
                end
            end
            
            TaskPlayAnim(ped, animData.Dict, animData.Anim, 4.0, 8.0, -1, 49, 0, 0, 0, 0)
            SendNUIMessage({
                startTalkSound = true
            })
            while Radio.Talking do
                if not CanTalk() then 
                    StopTalkRadio()
                    break
                end
                Wait(0)
                SetControlNormal(0, 249, 1.0)
                SetControlNormal(1, 249, 1.0)
                SetControlNormal(2, 249, 1.0)
                if Config.HideWeaponOnTalk then 
                    SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true)
                    DisablePlayerFiring(PlayerPedId(), true)
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
                end
            end
            if Config.HideWeaponOnTalk then
                SetCurrentPedWeapon(PlayerPedId(), selectedWeapon, false)
            end
        end)
    end
end

function StopTalkRadio()
    if not Radio.Talking then return end
    TriggerServerEvent("origen_radio:server:talking", Radio.Talking, false)
    Radio.Talking = false
    MumbleClearVoiceTargetPlayers(1)
    PlayerTargets()
    
    -- Clear speaker mode proximity override
    if PlayerMetadata.speakerMode then
        exports["pma-voice"]:clearProximityOverride()
    end
    
    local animData = RadioConfig.Anims[lastAnimUsed]
    if animData.Prop then
        if propRadio and DoesEntityExist(propRadio) then
            DeleteEntity(propRadio)
            propRadio = nil
        end
    end
    StopAnimTask(PlayerPedId(), animData.Dict, animData.Anim, 3.0)
    TriggerEvent("origen_hud:ocultarRadio")
    SendNUIMessage({
        stopTalkSound = true
    })
end

function LoadPlayer(PlayerData)
    PlayerData = PlayerData or FW_GetPlayerData()
    while not PlayerData.citizenid do
        Citizen.Wait(500)
        PlayerData = FW_GetPlayerData()
    end
    if PlayerData.metadata["radio_anim"] then
        Radio.Anim = tonumber(PlayerData.metadata["radio_anim"]) or 1
    end
    if PlayerData.metadata["radio_clicks"] then
        Radio.Clicks = PlayerData.metadata["radio_clicks"]
    end
    if PlayerData.metadata["radio_keybind"] then
        Radio.Binds = PlayerData.metadata["radio_keybind"]
    end
    local animData = RadioConfig.Anims[Radio.Anim]
    if animData then
        RequestAnimDict(animData.Dict)
    end
    LoadAnim()
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
    TriggerServerEvent("origen_radio:server:SetFreq", Radio.Frec)
    TriggerServerEvent("origen_radio:server:SetMultiFrec", Radio.MultiGroup, Radio.MultiFrec)
    animLoaded = false
end

function DoAction(action)
    if action == "mute" then
        ToggleMute()
        TriggerServerEvent("origen_radio:server:Mute", Radio.MultiGroup, Radio.Muted)
    end
end

RegisterNetEvent('key-4', function()
    DoAction("mute")
end)

RegisterNUICallback("SetAnonMode", function(data, cb)
    -- El servidor mira `freqAnon == 0 or nil` para enseñar el nombre: un
    -- `false` guardado lo dejaba anónimo para siempre. Siempre 0 o 1.
    if type(data) == "table" then data = data.value end
    data = (data == 1 or data == true or data == "1") and 1 or 0
    PlayerMetadata["freqAnon"] = data
    SetPlayerConfig("freqAnon", data)
    if cb then cb(true) end
end)

-- La NUI manda 1/0 (a veces { value = … }). Se guarda como booleano:
-- con un 0 guardado tal cual, `if PlayerMetadata.speakerMode` daba verdadero
-- y el altavoz se quedaba puesto aunque se apagara. Y se contesta siempre,
-- para que la llamada de la NUI no se quede colgada.
local function AjusteSiNo(data)
    if type(data) == "table" then data = data.value end
    return data == true or data == 1 or data == "1"
end

RegisterNUICallback("SetStreamerMode", function(data, cb)
    data = AjusteSiNo(data)
    PlayerMetadata["streamerMode"] = data
    SetPlayerConfig("streamerMode", data)
    if cb then cb(true) end
end)

RegisterNUICallback("SetSpeakerMode", function(data, cb)
    data = AjusteSiNo(data)
    PlayerMetadata["speakerMode"] = data
    SetPlayerConfig("speakerMode", data)
    if cb then cb(true) end
end)

RegisterNUICallback("SetRadioWidget", function(data, cb)
    data = AjusteSiNo(data)
    PlayerMetadata["radioWidget"] = data
    SetPlayerConfig("radioWidget", data)
    -- El aviso en pantalla lo pinta la NUI: se le dice al momento.
    TriggerEvent("origen_radio:client:toggleWidget", data)
    if cb then cb(true) end
end)

RegisterNUICallback("StartTalkRadio", function(data, cb)
    StartTalkRadio(data)
    cb(true)
end)

RegisterNUICallback("StartTalkSAPD", function(data, cb)
    StartTalkRadio(data)
    cb(true)
end)

RegisterNUICallback("StartTalkSAFD", function(data, cb)
    StartTalkRadio(data)
    cb(true)
end)

RegisterNUICallback("StopTalkRadio", function(data, cb)
    StopTalkRadio()
    cb(true)
end)
