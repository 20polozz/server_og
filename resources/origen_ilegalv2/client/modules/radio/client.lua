QuickMenuRadio = QuickMenuRadio or {}

local deps = {
    isQuickMenuOpen = function() return false end,
    hasPermission = function() return false end,
    getPlayerGang = function() return nil end,
    sendNuiMessage = function(payload) SendNUIMessage(payload) end,
}

local radioEnabled       = false
local currentRadioFreq   = 'none'
local radioCurrentGroup  = 'none'
local radioMuted         = false
local radioAnimIndex     = 1
local radioTalking       = false
local radioTargets       = {}
local radioMembersByFrec = {}
local radioAnimProp      = nil  -- entidad del prop adjunto durante la animación

function QuickMenuRadio.Init(opts)
    opts = opts or {}
    if type(opts.isQuickMenuOpen) == 'function' then deps.isQuickMenuOpen = opts.isQuickMenuOpen end
    if type(opts.hasPermission) == 'function' then deps.hasPermission = opts.hasPermission end
    if type(opts.getPlayerGang) == 'function' then deps.getPlayerGang = opts.getPlayerGang end
    if type(opts.sendNuiMessage) == 'function' then deps.sendNuiMessage = opts.sendNuiMessage end
end

local function GetRadioCfg()
    return (Config and Config.Radio) or {}
end

local function GetRadioVoiceCfg()
    local radioCfg = GetRadioCfg()
    return radioCfg.Voice or {}
end

local function IsVoiceEnabled()
    local voiceCfg = GetRadioVoiceCfg()
    if voiceCfg.Enabled == false then return false end
    local resource = voiceCfg.Resource or 'pma-voice'
    return GetResourceState(resource) == 'started'
end

local function IsRadioClicksEnabled()
    local voiceCfg = GetRadioVoiceCfg()
    return voiceCfg.Clicks == true
end

local function SendRadioTalkSound(state)
    if not IsRadioClicksEnabled() then return end
    deps.sendNuiMessage({
        action = 'radioTalkSound',
        state = state,
    })
end

local function GetMyServerId()
    return GetPlayerServerId(PlayerId())
end

local function EnsureRadioFrecTargets(frec)
    if not radioMembersByFrec[frec] then
        radioMembersByFrec[frec] = {}
    end
    return radioMembersByFrec[frec]
end

local function RemoveRadioMemberFromAllFreqs(id)
    for frec, members in pairs(radioMembersByFrec) do
        if members[id] then
            members[id] = nil
        end
    end
end

local function AddRadioMemberToFreq(id, frec, data)
    id = tonumber(id)
    if not id or not frec then return end

    RemoveRadioMemberFromAllFreqs(id)
    local members = EnsureRadioFrecTargets(frec)
    members[id] = {
        muted = data and data.muted == true or false,
        ready = data and data.ready ~= false or true,
        name  = data and data.name or nil,
        grade = data and data.grade or nil,
    }
end

local function RemoveRadioMemberFromFreq(id, frec)
    id = tonumber(id)
    if not id then return end

    if frec and radioMembersByFrec[frec] then
        radioMembersByFrec[frec][id] = nil
        return
    end

    RemoveRadioMemberFromAllFreqs(id)
end

local function BuildCurrentTalkTargets()
    local targets = {}
    if not radioEnabled or radioMuted then return targets end

    local frec = currentRadioFreq
    if not frec or frec == 'none' then return targets end

    local members = radioMembersByFrec[frec] or {}
    local myId = GetMyServerId()

    for id, data in pairs(members) do
        if tonumber(id) ~= myId and (not data or data.muted ~= true) then
            targets[tonumber(id)] = true
        end
    end

    return targets
end

local function RefreshRadioSnapshotFromServer()
    local playerGang = deps.getPlayerGang()
    if not playerGang or not playerGang.id then return end

    local group = radioCurrentGroup
    if not group or group == 'none' then
        group = 'gang_' .. tostring(playerGang.id)
        radioCurrentGroup = group
    end

    local multiFrecs = lib.callback.await('origen_gang:server:radio:GetMultiFrecs', false, {
        group = group
    }) or {}

    local myId = GetMyServerId()
    local myFrec = 'none'

    radioMembersByFrec = {}
    for frec, members in pairs(multiFrecs) do
        radioMembersByFrec[frec] = {}
        for memberId, memberData in pairs(members) do
            local id = tonumber(memberId)
            if id then
                radioMembersByFrec[frec][id] = memberData
                if id == myId then
                    myFrec = frec
                    radioMuted = memberData and memberData.muted == true or false
                end
            end
        end
    end

    currentRadioFreq = myFrec
end

local function DestroyRadioAnimProp()
    if radioAnimProp and DoesEntityExist(radioAnimProp) then
        DeleteEntity(radioAnimProp)
    end
    radioAnimProp = nil
end

local function AttachRadioAnimProp(anim)
    DestroyRadioAnimProp()
    if not anim or not anim.Prop then return end

    local propModel = anim.Prop
    local propHash  = joaat(propModel)

    if not IsModelValid(propHash) then return end

    RequestModel(propHash)
    local timeout = 0
    while not HasModelLoaded(propHash) do
        Wait(50)
        timeout = timeout + 50
        if timeout >= 3000 then return end  -- evita loop infinito si el model no carga
    end

    local ped       = PlayerPedId()
    local px, py, pz = table.unpack(GetEntityCoords(ped))
    local prop       = CreateObject(propHash, px, py, pz + 0.2, true, true, true)

    local pl = anim.PropPlacement or { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 }
    AttachEntityToEntity(
        prop, ped,
        GetPedBoneIndex(ped, anim.PropBone),
        pl[1], pl[2], pl[3],
        pl[4], pl[5], pl[6],
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(propModel)
    radioAnimProp = prop
end

local function EnsureAnimLoaded()
    local voiceCfg = GetRadioVoiceCfg()
    if not voiceCfg.UseAnimation then return true end

    local anims = voiceCfg.Anims or {}
    if #anims == 0 then return true end

    if not anims[radioAnimIndex] then
        radioAnimIndex = tonumber(voiceCfg.DefaultAnim) or 1
    end

    local anim = anims[radioAnimIndex]
    if not anim or not anim.Dict then return true end

    if HasAnimDictLoaded(anim.Dict) then return true end

    -- Verificar que el dict existe antes de intentar cargarlo
    if not DoesAnimDictExist(anim.Dict) then
        print(('[origen_ilegalv2] RadioAnim: dict "%s" no existe, fallback a anim 1'):format(anim.Dict))
        radioAnimIndex = 1
        return false
    end

    RequestAnimDict(anim.Dict)
    local timeout = 0
    while not HasAnimDictLoaded(anim.Dict) do
        Wait(50)
        timeout = timeout + 50
        if timeout >= 3000 then
            print(('[origen_ilegalv2] RadioAnim: timeout cargando dict "%s", fallback a anim 1'):format(anim.Dict))
            radioAnimIndex = 1
            return false
        end
    end
    return true
end

--- Se declara aqui y se define abajo: StartTalkRadio la llama al morir
--- hablando, y como local declarada despues era nil y el hilo reventaba.
local StopTalkRadio

local function StartTalkRadio()
    if radioTalking then return end
    -- No se puede hablar por radio si el jugador está muerto o incapacitado (RP state)
    if Framework and Framework.GetIsPlayerDead and Framework.GetIsPlayerDead() then return end
    if not IsVoiceEnabled() then
        Notify.SendNotify(locale:t('notify.radio_voice_not_started'), 'error')
        return
    end
    if radioMuted then
        Notify.SendNotify(locale:t('notify.radio_muted_key'), 'error')
        return
    end
    if currentRadioFreq == 'none' then return end

    local voiceCfg = GetRadioVoiceCfg()
    local resource = voiceCfg.Resource or 'pma-voice'
    local targets = BuildCurrentTalkTargets()

    local hasTargets = false
    for _ in pairs(targets) do hasTargets = true break end

    if not hasTargets then
        RefreshRadioSnapshotFromServer()
        targets = BuildCurrentTalkTargets()
        for _ in pairs(targets) do hasTargets = true break end
    end

    radioTalking = true
    radioTargets = targets

    if hasTargets then
        exports[resource]:playerTargets(radioTargets)
    else
        exports[resource]:playerTargets()
    end

    TriggerServerEvent('origen_gang:server:radio:Talking', {
        group = radioCurrentGroup,
        value = true,
    })

    if voiceCfg.UseAnimation then
        local animOk = EnsureAnimLoaded()
        local anim = (voiceCfg.Anims or {})[radioAnimIndex]
        if animOk and anim and anim.Dict and anim.Anim then
            AttachRadioAnimProp(anim)
            TaskPlayAnim(PlayerPedId(), anim.Dict, anim.Anim, 4.0, 8.0, -1, anim.Flag or 49, 0, false, false, false)
        end
    end

    SendRadioTalkSound('on')

    CreateThread(function()
        local ped = PlayerPedId()
        local selectedWeapon = GetSelectedPedWeapon(ped)
        
        while radioTalking do
            Wait(0)

            -- Cortar la radio automáticamente si el jugador muere durante la transmisión
            if Framework and Framework.GetIsPlayerDead and Framework.GetIsPlayerDead() then
                StopTalkRadio()
                break
            end

            if voiceCfg.KeepControlPressed then
                local ptt = tonumber(voiceCfg.PttControl) or 249
                SetControlNormal(0, ptt, 1.0)
                SetControlNormal(1, ptt, 1.0)
                SetControlNormal(2, ptt, 1.0)
            end
            
            SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
            DisablePlayerFiring(ped, true)
            
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 263, true) -- Melee Attack 1

            DisableControlAction(0, 45, true) -- Reload
            DisableControlAction(0, 47, true)  -- Disable weapon
            DisableControlAction(0, 264, true) -- Disable melee
            DisableControlAction(0, 140, true) -- Disable melee
            DisableControlAction(0, 141, true) -- Disable melee
            DisableControlAction(0, 142, true) -- Disable melee
            DisableControlAction(0, 143, true) -- Disable melee
            DisableControlAction(0, 80, true) -- Disable key R
            DisableControlAction(0, 250, true) -- Disable key R
            DisableControlAction(0, 310, true) -- Disable key R
        end
        
        SetCurrentPedWeapon(ped, selectedWeapon, false)
    end)
end


StopTalkRadio = function()
    if not radioTalking then return end

    local voiceCfg = GetRadioVoiceCfg()
    local resource = voiceCfg.Resource or 'pma-voice'

    TriggerServerEvent('origen_gang:server:radio:Talking', {
        group = radioCurrentGroup,
        value = false,
    })

    radioTalking = false
    radioTargets = {}

    SendRadioTalkSound('off')

    MumbleClearVoiceTargetPlayers(1)
    if GetResourceState(resource) == 'started' then
        exports[resource]:playerTargets()
    end

    if voiceCfg.UseAnimation then
        local anim = (voiceCfg.Anims or {})[radioAnimIndex]
        if anim and anim.Dict and anim.Anim then
            StopAnimTask(PlayerPedId(), anim.Dict, anim.Anim, 3.0)
        end
    end
    DestroyRadioAnimProp()
end

local function ToggleRadioMute(value)
    local voiceCfg = GetRadioVoiceCfg()
    if not voiceCfg.EnableMute then return end

    if value ~= nil then
        radioMuted = value == true
    else
        radioMuted = not radioMuted
    end

    TriggerServerEvent('origen_gang:server:radio:Mute', {
        group = radioCurrentGroup,
        value = radioMuted,
    })

    Notify.SendNotify(radioMuted and 'Radio silenciada' or 'Radio activada', radioMuted and 'error' or 'success')
end

local function ClientHasRadioItem(itemName)
    local cfgItemName = GetRadioCfg().ItemName or 'radio'
    itemName = itemName or cfgItemName
    local ok, hasItem

    if Inventory and type(Inventory.HasItem) == 'function' then
        ok, hasItem = pcall(Inventory.HasItem, itemName, 1)
        if ok then return hasItem == true end
    end

    if Framework and type(Framework.HasItem) == 'function' then
        ok, hasItem = pcall(Framework.HasItem, itemName, 1)
        if ok then return hasItem == true end
    end

    if Internal and type(Internal.HasItem) == 'function' then
        ok, hasItem = pcall(Internal.HasItem, itemName, 1)
        if ok then return hasItem == true end
    end

    return false
end

local function ActivateRadio()
    local hasItem = ClientHasRadioItem(GetRadioCfg().ItemName or 'radio')
    if not hasItem then
        Notify.SendNotify(locale:t('notify.no_radio'), 'error')
        return false
    end

    radioEnabled = true
    EnsureAnimLoaded()
    local playerGang = deps.getPlayerGang()
    local gangId = playerGang and playerGang.id or 'unknown'
    radioCurrentGroup = 'gang_' .. tostring(gangId)
    return true
end

local function DeactivateRadio()
    if radioTalking then StopTalkRadio() end

    radioEnabled = (currentRadioFreq ~= 'none')
    local playerGang = deps.getPlayerGang()
    local gangId = playerGang and playerGang.id or nil
    radioCurrentGroup = gangId and ('gang_' .. tostring(gangId)) or 'none'
end

function QuickMenuRadio.GetPayloadMeta()
    local playerGang = deps.getPlayerGang()
    return {
        hasRadioTab = deps.hasPermission('quick_radio'),
        radioGroup = playerGang and ('gang_' .. tostring(playerGang.id)) or nil,
        radioFreqList = Config.Radio.Frequencies,
        radioConnectedFreq = currentRadioFreq,
        radioMuted = radioMuted,
    }
end

function QuickMenuRadio.OnMenuClosed()
    DeactivateRadio()
end

function QuickMenuRadio.OnResourceStop()
    if radioTalking then StopTalkRadio() end
    DestroyRadioAnimProp()
end

local function ForwardRadioEvent(payload)
    if not deps.isQuickMenuOpen() then return end
    deps.sendNuiMessage(payload)
end

RegisterNUICallback('quickMenuRadioLoad', function(_, cb)
    if not deps.isQuickMenuOpen() then cb('closed') return end
    if not deps.hasPermission('quick_radio') then cb('no_permission') return end

    if not ActivateRadio() then
        cb('no_radio')
        return
    end

    local group = radioCurrentGroup
    local multiFrecs = lib.callback.await('origen_gang:server:radio:GetMultiFrecs', false, { group = group }) or {}

    radioMembersByFrec = {}
    local myId = GetPlayerServerId(PlayerId())
    local myfrec = 'none'

    -- multiFrecsStr: keys string para que JSON serialice como objeto, no array
    local multiFrecsStr = {}

    for frec, members in pairs(multiFrecs) do
        radioMembersByFrec[frec] = {}
        multiFrecsStr[frec] = {}
        for memberId, memberData in pairs(members) do
            local id = tonumber(memberId)
            if id then
                radioMembersByFrec[frec][id] = memberData
                multiFrecsStr[frec][tostring(id)] = memberData
                if id == myId then
                    myfrec = frec
                    radioMuted = memberData and memberData.muted == true or false
                end
            end
        end
    end

    currentRadioFreq = myfrec
    radioEnabled = true

    local freclist = {}
    for _, frec in ipairs(Config.Radio.Frequencies) do
        table.insert(freclist, frec)
    end

    -- Cargar preferencia de animación persistida del servidor
    local savedAnimIndex = lib.callback.await('origen_gang:server:radio:GetAnimPreference', false)
    local voiceCfg = GetRadioVoiceCfg()
    local animCount = voiceCfg.Anims and #voiceCfg.Anims or 0
    if savedAnimIndex and type(savedAnimIndex) == 'number' and savedAnimIndex >= 1 and animCount > 0 and savedAnimIndex <= animCount then
        radioAnimIndex = savedAnimIndex
    else
        radioAnimIndex = tonumber(voiceCfg.DefaultAnim) or 1
    end

    -- Construir lista de animaciones para el NUI
    local animOptions = {}
    for i, anim in ipairs(voiceCfg.Anims or {}) do
        animOptions[#animOptions + 1] = {
            index = i,
            label = anim.Label or ('Animación ' .. i),
        }
    end

    cb({
        freclist    = freclist,
        myfrec      = myfrec,
        myid        = tostring(myId),
        group       = group,
        multiFrecs  = multiFrecsStr,
        animIndex   = radioAnimIndex,
        animOptions = animOptions,
    })
end)

RegisterNUICallback('quickMenuRadioSetFrequency', function(data, cb)
    if not deps.isQuickMenuOpen() then cb('closed') return end
    if not radioEnabled then cb('inactive') return end

    local frec  = data and data.frec  or 'none'
    local group = data and data.group or radioCurrentGroup

    local result = lib.callback.await('origen_gang:server:radio:SetMultiFrecCb', false, {
        group = group,
        frec  = frec,
    })

    if result ~= 'ok' then cb(result or 'error') return end
    cb('ok')
end)

RegisterNUICallback('quickMenuRadioDisconnect', function(_, cb)
    if not deps.isQuickMenuOpen() then cb('closed') return end

    local myId    = GetPlayerServerId(PlayerId())
    local prevFrec = currentRadioFreq

    local result = lib.callback.await('origen_gang:server:radio:SetMultiFrecCb', false, {
        group = radioCurrentGroup,
        frec  = 'none',
    })

    if result ~= 'ok' then cb(result or 'error') return end

    -- Actualizar estado Lua local sin mandar eventos a NUI
    -- La NUI hace su propia limpieza usando myid/prevfrec del cb
    if prevFrec and prevFrec ~= 'none' then
        RemoveRadioMemberFromFreq(myId, prevFrec)
    end

    currentRadioFreq = 'none'
    if radioTalking then StopTalkRadio() end

    cb({ status = 'ok', myid = myId, prevfrec = prevFrec })
end)

RegisterNUICallback('quickMenuRadioMoveMember', function(data, cb)
    if not deps.isQuickMenuOpen() then cb('closed') return end
    if not radioEnabled then cb('inactive') return end

    local playerId = data and data.playerId
    local toFrec   = data and data.toFrec
    local group    = data and data.group or radioCurrentGroup

    if not playerId or not toFrec then cb('invalid') return end

    local result = lib.callback.await('origen_gang:server:radio:MovePlayerCb', false, {
        group    = group,
        playerId = tonumber(playerId),
        toFrec   = toFrec,
    })

    if result ~= 'ok' then cb(result or 'error') return end
    cb('ok')
end)

RegisterNetEvent('origen_gang:client:radio:AddPlayerMultiFrec', function(id, frec, data)
    AddRadioMemberToFreq(id, frec, data)

    local myId = GetPlayerServerId(PlayerId())
    if id == myId then
        currentRadioFreq = frec
        local playerGang = deps.getPlayerGang()
        radioCurrentGroup = radioCurrentGroup ~= 'none' and radioCurrentGroup or (playerGang and ('gang_' .. tostring(playerGang.id)) or 'none')
        radioEnabled = (frec ~= 'none')
        radioMuted = data and data.muted == true or radioMuted
    end

    ForwardRadioEvent({
        action = 'quickMenuRadioEvent',
        event  = 'AddPlayerMultiFrec',
        id     = id,
        frec   = frec,
        data   = data,
        isMe   = (id == myId),
    })
end)

RegisterNetEvent('origen_gang:client:radio:RemovePlayerMultiFrec', function(id, frec)
    RemoveRadioMemberFromFreq(id, frec)

    local myId = GetPlayerServerId(PlayerId())
    if id == myId then
        currentRadioFreq = 'none'
        radioEnabled = deps.isQuickMenuOpen()
        if radioTalking then StopTalkRadio() end
    end

    ForwardRadioEvent({
        action = 'quickMenuRadioEvent',
        event  = 'RemovePlayerMultiFrec',
        id     = id,
        frec   = frec,
        isMe   = (id == myId),
    })
end)

RegisterNetEvent('origen_gang:client:radio:Talking', function(target, value)
    if radioMuted then return end
    if not radioEnabled and currentRadioFreq == 'none' then return end

    if IsVoiceEnabled() then
        local resource = GetRadioVoiceCfg().Resource or 'pma-voice'
        exports[resource]:toggleVoice(target, value, 'radio')
    end

    ForwardRadioEvent({
        action = 'quickMenuRadioEvent',
        event  = 'Talking',
        target = target,
        value  = value,
    })
end)

RegisterNetEvent('origen_gang:client:radio:SetMuted', function(id, value)
    local numericId = tonumber(id)
    if numericId then
        for _, members in pairs(radioMembersByFrec) do
            if members[numericId] then
                members[numericId].muted = value == true
                break
            end
        end

        if numericId == GetMyServerId() then
            radioMuted = value == true
            if radioMuted and radioTalking then StopTalkRadio() end
        end
    end

    ForwardRadioEvent({
        action = 'quickMenuRadioEvent',
        event  = 'SetMuted',
        id     = id,
        value  = value,
    })
end)

RegisterNetEvent('origen_gang:client:radio:Disconnected', function()
    currentRadioFreq = 'none'
    radioEnabled = deps.isQuickMenuOpen()
    if radioTalking then StopTalkRadio() end
    ForwardRadioEvent({ action = 'quickMenuRadioEvent', event = 'Disconnected' })
end)

RegisterNetEvent('origen_gang:client:radio:ForceSetFrec', function(group, frec)
    currentRadioFreq  = frec
    radioCurrentGroup = group
    radioEnabled      = (frec ~= 'none')
    ForwardRadioEvent({
        action = 'quickMenuRadioEvent',
        event  = 'AddPlayerMultiFrec',
        id     = GetPlayerServerId(PlayerId()),
        frec   = frec,
        data   = nil,
        isMe   = true,
    })
end)

RegisterCommand('+radiotalk_org', function() StartTalkRadio() end, false)
RegisterCommand('-radiotalk_org', function() StopTalkRadio() end, false)

local voiceCfg = GetRadioVoiceCfg()
local talkKey = voiceCfg.TalkKey or 'LMENU'

RegisterKeyMapping('+radiotalk_org', 'Hablar por radio', 'keyboard', talkKey)

RegisterNUICallback('quickMenuRadioSetAnimation', function(data, cb)
    if not deps.isQuickMenuOpen() then cb({ status = 'closed' }) return end
    if not radioEnabled then cb({ status = 'inactive' }) return end

    local animIndex = data and tonumber(data.animIndex)
    if not animIndex then cb({ status = 'invalid' }) return end

    local voiceCfg = GetRadioVoiceCfg()
    local animCount = voiceCfg.Anims and #voiceCfg.Anims or 0

    if animCount == 0 or animIndex < 1 or animIndex > animCount then
        cb({ status = 'invalid_index' }) return
    end

    -- Actualizar índice local inmediatamente (UX responsivo)
    radioAnimIndex = animIndex

    -- Precargar el dict de la nueva anim en background
    local anim = voiceCfg.Anims[radioAnimIndex]
    if anim and anim.Dict and not HasAnimDictLoaded(anim.Dict) then
        CreateThread(function()
            RequestAnimDict(anim.Dict)
            while not HasAnimDictLoaded(anim.Dict) do Wait(0) end
        end)
    end

    -- Persistir en servidor (fire-and-forget con await para devolver resultado a NUI)
    local result = lib.callback.await('origen_gang:server:radio:SetAnimPreference', false, { animIndex = animIndex })

    cb({ status = result or 'ok', animIndex = radioAnimIndex })
end)

RegisterNUICallback('quickMenuRadioToggleMute', function(data, cb)
    if not deps.isQuickMenuOpen() then cb({ status = 'closed' }) return end
    if not radioEnabled then cb({ status = 'inactive' }) return end

    local value = data and data.value -- nil = toggle, true/false = forzar
    ToggleRadioMute(value)
    cb({ status = 'ok', muted = radioMuted })
end)
