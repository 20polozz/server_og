local gameBuild, currentWalk, currentExpression = GetGameBuildNumber(), GetResourceKvpString('animations_walkstyle') or 'default', GetResourceKvpString('animations_expression') or 'default'
local isActionsLimited, isPlayingAnimation = false, false
local isRagdoll, isPointing, returnStance = false, false, false
local emoteCooldown, lastEmote, lastVariant, ptfxCanHold, otherPlayer, clone = 0, nil, nil, false, nil, nil
local playerParticles, keybinds, registeredEmotes, cloneProps = {}, {}, {}, {}
local lang = require('locales.' .. Config.Language)
local pedTypes = require('data.ped_types')
local plyState = LocalPlayer.state

local custom = require('custom_emotes')

AnimationList = {
    Walks = require('data.animations.walks'),
    Scenarios = require('data.animations.scenarios'),
    Expressions = require('data.animations.expressions'),
    Emotes = require('data.animations.emotes'),
    PropEmotes = require('data.animations.prop_emotes'),
    ConsumableEmotes = require('data.animations.consumable_emotes'),
    DanceEmotes = require('data.animations.dance_emotes'),
    SynchronizedEmotes = require('data.animations.synchronized_emotes'),
    AnimalEmotes = require('data.animations.animal_emotes')
}

-- Import customs animations
for _type, emoteList in pairs(custom) do
    for i = 1, #emoteList do
        AnimationList[_type][#AnimationList[_type] + 1] = emoteList[i]
    end
end

CreateThread(function()
    plyState.isAnimMenuOpen = false
end)

-- Lo que se ajusta desde el menu: el bucle, la velocidad y los bindeos. Se
-- guardan en KVP, en el PC del jugador, igual que el andar y la expresion.
local function leerKvpJson(clave)
    local texto = GetResourceKvpString(clave)
    if not texto then return nil end
    local ok, valor = pcall(json.decode, texto)
    return ok and valor or nil
end

local forzarBucle = GetResourceKvpInt('animations_loop') == 1
local velocidadAnim = tonumber(GetResourceKvpString('animations_speed')) or 1.0

-- Seis huecos. Por defecto en el teclado numerico: del 1 al 7 de arriba son
-- los huecos del inventario (origen_inventory, commands.lua) y se pisarian.
-- `vk` es el codigo de tecla virtual de Windows, el que leen los IsRawKey*.
local animBinds = leerKvpJson('animations_binds')
if type(animBinds) ~= 'table' or #animBinds ~= 6 then
    animBinds = {}
    for i = 1, 6 do
        animBinds[i] = { key = 'N' .. i, vk = 0x60 + i }
    end
else
    -- El JSON puede devolver 97.0 y el native quiere un entero.
    for i = 1, 6 do
        if type(animBinds[i]) ~= 'table' then animBinds[i] = { key = 'N' .. i, vk = 0x60 + i } end
        animBinds[i].vk = math.tointeger(tonumber(animBinds[i].vk))
    end
end

-- Que animacion hay en marcha, para el recuadro «En marcha» del menu. El id
-- cambia en cada animacion nueva y al parar: el hilo que vigila la anterior
-- lo ve y se retira sin tocar nada.
local enMarcha = { id = 0, cmd = nil }

local function avisarEnMarcha(data)
    SendNUIMessage({
        action = 'setPlaying',
        name = data and data.Label or false,
        cmd = data and data.Command or false,
    })
end

---Sigue la animacion recien puesta: le aplica la velocidad del menu y avisa
---a la NUI cuando se acaba sola.
---@param data table
---@param dict? string sin diccionario es un escenario
---@param anim? string
local function seguirAnimacion(data, dict, anim)
    enMarcha.id = enMarcha.id + 1
    enMarcha.cmd = data.Command
    local id = enMarcha.id

    avisarEnMarcha(data)

    CreateThread(function()
        local function sigue()
            if dict then return IsEntityPlayingAnim(cache.ped, dict, anim, 3) end
            return IsPedUsingAnyScenario(cache.ped)
        end

        -- TaskPlayAnim tarda unos fotogramas en arrancar con la mezcla.
        local limite = GetGameTimer() + 1500
        while enMarcha.id == id and not sigue() and GetGameTimer() < limite do Wait(50) end

        local aplicada = 1.0
        while enMarcha.id == id and sigue() do
            -- La velocidad es local: los demas la ven a 1x. En un emote de
            -- pareja se deja en 1x para no desacompasar a los dos.
            local quiere = (dict and not otherPlayer) and velocidadAnim or 1.0
            if dict and (quiere ~= 1.0 or aplicada ~= 1.0) then
                SetEntityAnimSpeed(cache.ped, dict, anim, quiere)
                aplicada = quiere
            end
            Wait(quiere ~= 1.0 and 0 or 250)
        end

        if enMarcha.id == id then
            enMarcha.cmd = nil
            avisarEnMarcha(nil)
        end
    end)
end

local function olvidarEnMarcha()
    enMarcha.id = enMarcha.id + 1
    enMarcha.cmd = nil
    avisarEnMarcha(nil)
end

-- Functions
---Closes the animation menu
function closeMenu()
    -- Solo si estaba abierto: closeMenu tambien se llama desde fuera y a
    -- ciegas, y devolver el rastreador con el inventario abierto lo pintaria
    -- encima de el.
    local estabaAbierto = plyState.isAnimMenuOpen

    SendNUIMessage({
        action = 'setVisible',
        state = false,
    })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    plyState.isAnimMenuOpen = false

    if estabaAbierto then TriggerEvent('qv2:suppressHud', false) end
end

exports('closeMenu', closeMenu)

--[[ El raton, a salvo (origen_map/shared/foco.lua).

     - Si el vigilante suelta el foco a la fuerza con el menu abierto,
       isAnimMenuOpen se quedaba en true: el bucle de abajo seguia bloqueando
       controles y el menu no se volvia a abrir. closeMenu() no coge foco.
     - Si otro recurso coge el foco con el menu abierto (KeepInput encima de
       KeepInput), foco.lua apaga el KeepInput y al cerrarse el de arriba este
       se quedaba sin teclado y con la camara bloqueada. Se cierra antes. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if plyState.isAnimMenuOpen then closeMenu() end
    end)
end

AddEventHandler('origen:foco:estado', function(recurso, tiene)
    if tiene and plyState.isAnimMenuOpen and recurso ~= GetCurrentResourceName() then
        closeMenu()
    end
end)

--[[ Alt con el menu abierto.

     Con el menu abierto el teclado va a la vez a la pagina y al juego
     (KeepInput). A algunos jugadores, al pulsar Alt, la pagina se quedaba sin
     foco: el cursor en pantalla, la lista sin responder y el Escape --que lo
     lee la pagina-- sin llegar, asi que no habia forma de salir. Dos redes:

     - Al soltar Alt se vuelve a dar el foco a la pagina, igual que al abrir.
     - Escape leido en crudo (no pasa por la pagina ni por los controles): si
       la pagina no dice en 300 ms que lo ha visto ('escVisto'), no le esta
       llegando el teclado y se cierra desde aqui. Cuando si llega, manda la
       pagina (que primero deshace lo que este a medias). ]]
local teclasAlJuego = true
local escVisto = 0

local ALT_TECLAS = { 18, 164 } -- VK_MENU y VK_LMENU

local function SoltoAlt()
    if not IsRawKeyReleased then return false end
    for i = 1, #ALT_TECLAS do
        if IsRawKeyReleased(ALT_TECLAS[i]) then return true end
    end
    return false
end

RegisterNUICallback('escVisto', function(_, cb)
    escVisto = GetGameTimer()
    cb('ok')
end)

---Toggles the animation menu
function toggleMenu()
    if not plyState.isLoggedIn then return end
    if plyState.isAnimMenuOpen then return end

    SendNUIMessage({
        action = 'setVisible',
        state = true,
    })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    teclasAlJuego = true

    plyState.isAnimMenuOpen = true

    -- El rastreador de misiones (origen_quests) cae en el mismo canto derecho
    -- y se veia a traves del panel. Se aparta como con el radial de origen_hud:
    -- con el teclado pasando al juego, su vigilante de IsNuiFocused no basta.
    TriggerEvent('qv2:suppressHud', true)

    lib.disableControls:Add(Config.disableControls)
    
    CreateThread(function()
        while plyState.isAnimMenuOpen do
            lib.disableControls()

            if SoltoAlt() then
                SetNuiFocus(true, true)
                SetNuiFocusKeepInput(teclasAlJuego)
            end

            if IsRawKeyReleased and IsRawKeyReleased(27) then
                local pulsado = GetGameTimer()
                SetTimeout(300, function()
                    if plyState.isAnimMenuOpen and escVisto < pulsado - 2000 then
                        closeMenu()
                    end
                end)
            end

            Wait(0)
        end
        lib.disableControls:Remove(Config.disableControls)
    end)
end

exports('toggleMenu', toggleMenu)

RegisterNUICallback('close', function(data, cb)
    closeMenu()
    cb(true)
end)

RegisterNUICallback('loadNui', function(data, cb)
    SendNUIMessage({
        action = 'setAnimations',
        data = AnimationList
    })
    SendNUIMessage({
        action = 'setAjustes',
        loop = forzarBucle,
        speed = velocidadAnim,
        binds = animBinds,
        -- Sin los IsRawKey* no hay forma de leer una tecla cualquiera: el
        -- menu esconde los bindeos en vez de dejar poner unos que no van.
        bindsOk = IsRawKeyPressed ~= nil,
        stopKey = Config.CancelEmoteKey,
        -- Las que ya usa este recurso: un bindeo encima haria las dos cosas.
        takenKeys = {
            Config.MenuKeybind, Config.CancelEmoteKey, Config.HandsUpKey,
            Config.CrossArmsKey, Config.PointKey, Config.PtfxKeybind or '',
        },
    })
    cb(true)
end)

RegisterNUICallback('stop', function(data, cb)
    cancelEmote(false)
    cb('ok')
end)

RegisterNUICallback('setLoop', function(data, cb)
    forzarBucle = data.state == true
    SetResourceKvpInt('animations_loop', forzarBucle and 1 or 0)
    cb('ok')
end)

RegisterNUICallback('setSpeed', function(data, cb)
    local v = tonumber(data.speed) or 1.0
    velocidadAnim = math.max(0.25, math.min(v, 2.0)) + 0.0
    SetResourceKvp('animations_speed', tostring(velocidadAnim))
    cb('ok')
end)

RegisterNUICallback('setBinds', function(data, cb)
    local nuevos = data.binds
    if type(nuevos) ~= 'table' or #nuevos ~= 6 then cb('ko') return end

    for i = 1, 6 do
        local b = nuevos[i]
        animBinds[i] = {
            key = tostring(b.key or '—'):sub(1, 5),
            vk = math.tointeger(tonumber(b.vk)),
            cmd = type(b.cmd) == 'string' and b.cmd or nil,
            label = type(b.label) == 'string' and b.label or nil,
        }
    end

    SetResourceKvp('animations_binds', json.encode(animBinds))
    cb('ok')
end)

RegisterNUICallback('playAnimation', function(data, cb)
    local anim = data.anim

    --[[ if anim.Walk then
        setWalk(anim.Walk)
    else
        playEmote(anim)
    end ]]
    if anim?.Walk then
        setWalk(anim?.Walk)
        cb('ok')
        return
    end
    
    playEmoteByCommand(anim.Command)
    cb('ok')
end)

RegisterNUICallback('previewAnimation', function(data, cb)
    startPlacementThread(data.anim)
    cb('ok')
end)

RegisterNUICallback('toggleSearch', function(data, cb)
    local state = data.state

    if not plyState.isAnimMenuOpen then
        cb('ok')
        return
    end

    teclasAlJuego = state == true
    SetNuiFocusKeepInput(state)
    cb('ok')
end)

---Toggle player limitations
---@param limited boolean
function setLimitation(limited)
    isActionsLimited = limited
end
exports('setLimitation', setLimitation)

---Check if the player is currently limited
---@return boolean
function isLimited()
    return isActionsLimited
end
exports('isLimited', isLimited)

---Remove multiple entries from a table
---@param _table table
---@param keep function
function removeFromTable(_table, keep)
    local _index = 1

    for i = 1, #_table do
        if keep(_table, i) then
            if i ~= _index then
                _table[_index] = _table[i]
                _table[i] = nil
            end
            _index += 1
        else
            _table[i] = nil
        end
    end

    return _table
end

---Display a notification
---@param _type string
---@param message string
function notify(_type, message)
    lib.notify({
        description = message,
        position = Config.NotificationPosition,
        duration = 5000,
    })
end
exports('customNotifyFn', function(fn) if fn then notify = fn end end)

---Register emotes to be used within external resources
---@param emote table
function registerEmote(emote)
    registeredEmotes[emote.Name] = emote
end
exports('registerEmote', registerEmote)

---Play a registered emote
---@param emote string
function playRegisteredEmote(emote)
    local registeredEmote = registeredEmotes[emote]

    if not registeredEmote then
        return
    end

    if registeredEmote.Type == 'Walks' then
        setWalk(registeredEmote.Walk)
    else
        playEmote(registeredEmote, registeredEmote.Variant)
    end
end
exports('playRegisteredEmote', playRegisteredEmote)

---Remove emotes from the menu
---@param _type string
function removeEmotes(_type)
    local checkMenus = {
        'Walks',
        'Scenarios',
        'Expressions',
        'Emotes',
        'PropEmotes',
        'ConsumableEmotes',
        'DanceEmotes',
        'SynchronizedEmotes',
        'AnimalEmotes'
    }

    for i = 1, #checkMenus do
        AnimationList[checkMenus[i]] = removeFromTable(AnimationList[checkMenus[i]], function(_table, _index)
            return not _table[_index][_type]
        end)
    end
end

---Get an emote based on the command
---@param name string
---@return string? _type Emote type
---@return table? _emote Emote table
function getEmoteByCommand(name)
    local _type, _emote, checkMenus = nil, nil, {
        'Walks',
        'Scenarios',
        'Expressions',
        'Emotes',
        'PropEmotes',
        'ConsumableEmotes',
        'DanceEmotes',
        'SynchronizedEmotes',
        'AnimalEmotes'
    }

    for i = 1, #checkMenus do
        local animType = checkMenus[i]
        local animList = AnimationList[animType]

        for emote = 1, #animList do
            if animList[emote] and (animList[emote].Command == name) then
                _type, _emote = animType, animList[emote]
                break
            end
        end
    end

    return _type, _emote
end

---Check if the player is in an animation
---@return boolean
function isInEmote()
    return isPlayingAnimation
end
exports('isInEmote', isInEmote)

---Get the last emote a player used
---@return table?, number?
function getLastEmote()
    return lastEmote, lastVariant
end
exports('getLastEmote', getLastEmote)

function requestSynchronizedEmote(senderData)
    if not senderData or not senderData.Options or not senderData.Options.Shared or not senderData.Options.Shared.OtherAnimation then
        notify('error', lang.not_valid_emote)
        return
    end

    local playerPos = GetEntityCoords(cache.ped)
    local targetId = lib.getClosestPlayer(playerPos, 3.0, false)

    if not targetId then
        notify('error', lang.no_player_nearby)
        return
    end

    local _type, emote = getEmoteByCommand(senderData.Options.Shared.OtherAnimation)

    if _type ~= 'SynchronizedEmotes' or not emote then
        notify('error', lang.not_valid_emote)
        return
    end

    TriggerServerEvent('emotemenu:requestSynchronizedEmote', GetPlayerServerId(targetId), senderData, emote)
end

---Play an emote by command
---@param command string
---@param variant? number
function playEmoteByCommand(command, variant)
    local _type, emote = getEmoteByCommand(command)

    if not _type or _type == 'Walks' then
        notify('error', lang.not_valid_emote)
        return
    end

    if _type == 'SynchronizedEmotes' then
        requestSynchronizedEmote(emote)
        return
    end

    playEmote(emote --[[@as table]], variant)
end
exports('playEmoteByCommand', playEmoteByCommand)

---Play an animation
---@param data table
---@param variation? number
function playEmote(data, variation)
    if data.PedTypes then
        if IsPedHuman(cache.ped) then
            notify('error', lang.not_valid_ped)
            return
        end

        local validPed = false
        local playerModel = GetEntityModel(cache.ped)

        for i = 1, #data.PedTypes do
            local allowedPeds = pedTypes[data.PedTypes[i]]
            local isContained = lib.table.contains(allowedPeds, playerModel)

            if isContained then
                validPed = true
                break
            end
        end

        if not validPed then
            notify('error', lang.not_valid_ped)
            return
        end
    end

    if not data.PedTypes and not IsPedHuman(cache.ped) then
        notify('error', lang.not_valid_ped)
        return
    end

    if data.Expression then
        if data.Expression == 'reset' then
            resetExpression()
        else
            setExpression(data.Expression)
        end
        return
    end

    if Config.EnableWeaponBlock and IsPedArmed(cache.ped, 7) then
        notify('error', lang.not_with_weapon)
        return
    end

    if Config.EnableAimShootBlock then
        CreateThread(function()
            while isPlayingAnimation and not IsPedRagdoll(cache.ped) do
                Wait(0)

                DisableControlAction(0, 25, true)
                DisablePlayerFiring(cache.playerId, true)
            end

            cancelEmote(false)
        end)
    end

    local duration, movementFlag = nil, cache.vehicle and 51 or 0

    if not Config.AllowedInVehicles and cache.vehicle then
        notify('error', lang.no_animations_in_vehicle)
        return
    end

    local gameTimer = GetGameTimer()

    if (gameTimer - emoteCooldown) < Config.EmoteCooldown then return end

    emoteCooldown = gameTimer

    TriggerServerEvent('emotemenu:deleteProps')

    if data.Scenario then
        if cache.vehicle then
            notify('error', lang.no_scenarios_in_vehicle)
            return
        end

        ClearPedTasks(cache.ped)
        TaskStartScenarioInPlace(cache.ped, data.Scenario, 0, true)

        isPlayingAnimation = true
        seguirAnimacion(data)
        return
    end

    if Config.EnableEmotePlacement and data.Placement and not data.Advanced then
        lib.hideMenu()

        startPlacementThread(data)

        return
    end

    local hasAutomatedPtfx, dictionaryName, animationName = false, data.Dictionary, data.Animation

    if type(dictionaryName) == 'table' and type(animationName) == 'table' then
        local randomIndex = math.random(1, #animationName)

        dictionaryName = dictionaryName[randomIndex]
        animationName = animationName[randomIndex]
    end

    local isValid = lib.requestAnimDict(dictionaryName, 1000)

    if not isValid then
        notify('error', lang.not_valid_emote)
        return
    end

    if data.NSFW and type(Config.EnableNSFWEmotes) == 'string' and Config.EnableNSFWEmotes == 'limited' and not LocalPlayer.state.allowNSFWEmotes then
        notify('error', lang.nsfw_limited)
        return
    end

    if data.Options then
        duration = data.Options.Duration

        if data.Options.Delay then Wait(data.Options.Delay) end

        if not cache.vehicle and data.Options.Flags then
            movementFlag = data.Options.Flags.Stuck and 50 or data.Options.Flags.Move and 51 or data.Options.Flags.Loop and 1 or movementFlag
            if data.Options.Flags.Loop then
                lastEmote, lastVariant = data, variation
            end
        end

        if data.Options.Ptfx then
            hasAutomatedPtfx = Config.EnableAutoPtfx and data.Options.Ptfx.Auto
            ptfxCanHold = data.Options.Ptfx.CanHold

            if Config.PtfxKeybind and not hasAutomatedPtfx then
                keybinds.PlayPtfx:disable(false)
                notify('success', (lang.press_for_effect):format(GetControlInstructionalButton(0, joaat('+playptfx') | 0x80000000, true):sub(3)))
            else
                keybinds.PlayPtfx:disable(true)
            end

            TriggerServerEvent('emotemenu:syncPtfx', data.Options.Ptfx.Asset, data.Options.Ptfx.Name, data.Options.Ptfx.Placement, data.Options.Ptfx.Bone, data.Options.Ptfx.Color)
        else
            if Config.PtfxKeybind then keybinds.PlayPtfx:disable(true) end
        end
    end

    -- El «Bucle» del menu: puesto, la animacion se repite hasta pararla
    -- aunque el emote no lo pida. Quitado, cada emote va como viene.
    if forzarBucle and not cache.vehicle then
        movementFlag = movementFlag | 1
        duration = nil
    end

    if data.Advanced then
        local coords = data.Advanced.Coords

        TaskPlayAnimAdvanced(cache.ped, dictionaryName, animationName, coords.x, coords.y, coords.z, 0, 0, data.Advanced.Heading, 2.0, 2.0, duration or -1, movementFlag, 1.0, false, false)
        SetEntityHeading(cache.ped, data.Advanced.Heading)
    else
        TaskPlayAnim(cache.ped, dictionaryName, animationName, 2.0, 2.0, duration or -1, movementFlag, 0, false, false, false)
    end

    RemoveAnimDict(dictionaryName)

    isPlayingAnimation = true
    seguirAnimacion(data, dictionaryName, animationName)

    if data.Options then
        local secondaryEmote = data.Options.SecondaryEmote

        if secondaryEmote then
            local isSecondaryValid = lib.requestAnimDict(secondaryEmote.Dictionary, 1000)

            if not isSecondaryValid then
                notify('error', lang.not_valid_emote)
                return
            end

            TaskPlayAnim(cache.ped, secondaryEmote.Dictionary, secondaryEmote.Animation, 2.0, 2.0, secondaryEmote.Duration or -1, 51, 0, false, false, false)
            RemoveAnimDict(secondaryEmote.Dictionary)
        end

        local propData = data.Options.Props

        if propData then
            local propCount = #propData

            if propCount > 0 then
                Wait(duration or 0)

                local propList = {}

                for i = 1, propCount do
                    local prop = propData[i]
                    local variant = prop.Variant

                    if variation then
                        if prop.Variations and prop.Variations[variation] then
                            variant = prop.Variations[variation]
                        end
                    end

                    propList[#propList + 1] = {
                        hash = joaat(prop.Name),
                        bone = prop.Bone,
                        placement = prop.Placement,
                        variant = variant,
                        hasPTFX = i == 1 and data.Options.Ptfx and data.Options.Ptfx.AttachToProp
                    }
                end

                local props = lib.callback.await('emotemenu:spawnProps', false, propList)

                if props then
                    for i = 1, #props do
                        local prop = props[i]
                        local object = NetworkGetEntityFromNetworkId(prop.object)

                        if DoesEntityExist(object) then
                            local hasControl = lib.waitFor(function()
                                local hasControl = NetworkGetEntityOwner(object) == cache.playerId

                                if hasControl then
                                    return true
                                end

                                NetworkRequestControlOfEntity(object)
                            end, ('Failed to gain entity control of entity'), 3000)


                            if hasControl then
                                addPropToPlayer(object, prop.bone, prop.placement, prop.variant)
                            end
                        end
                    end
                end
            end
        end
    end

    if hasAutomatedPtfx then
        Wait(400)

        LocalPlayer.state:set('ptfx', true, true)
    end
end
exports('playEmote', playEmote)

---Play an animation using a clone
---@param data table
function initCloneEmote(data)
    if DoesEntityExist(clone --[[@as number]]) then return end

    if cache.vehicle then
        notify('error', lang.no_animations_in_vehicle)
        return
    end

    local clonePos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 4.5, 0.0)
    local cloneHeading = GetEntityHeading(cache.ped) + 180

    clone = ClonePed(cache.ped, false, false, true)

    SetEntityCoords(clone, clonePos.x, clonePos.y, clonePos.z, false, false, false, false)
    SetEntityHeading(clone, cloneHeading)
    SetEntityAlpha(clone, 200, false)

    Wait(200)

    local hasAutomatedPtfx, dictionaryName, animationName = false, data.Dictionary, data.Animation

    if type(dictionaryName) == 'table' and type(animationName) == 'table' then
        local randomIndex = math.random(1, #animationName)

        dictionaryName = dictionaryName[randomIndex]
        animationName = animationName[randomIndex]
    end

    local isValid = lib.requestAnimDict(dictionaryName, 1000)

    if not isValid then
        notify('error', lang.not_valid_emote)
        return
    end

    if data.Options then
        duration = data.Options.Duration

        if data.Options.Delay then Wait(data.Options.Delay) end

        if not cache.vehicle and data.Options.Flags then
            if data.Options.Flags.Loop then movementFlag = 1 end
            if data.Options.Flags.Move then movementFlag = 51 end
            if data.Options.Flags.Stuck then movementFlag = 50 end
        end

        if data.Options.Ptfx then
            -- TO-DO
        end
    end

    local cloneDuration = GetAnimDuration(dictionaryName, animationName)

    if data.Advanced then
        local coords = data.Advanced.Coords

        TaskPlayAnimAdvanced(clone, dictionaryName, animationName, coords.x, coords.y, coords.z, 0, 0, data.Advanced.Heading, 2.0, 2.0, duration or -1, movementFlag, 1.0, false, false)
    else
        TaskPlayAnim(clone, dictionaryName, animationName, 2.0, 2.0, duration or -1, movementFlag, 0, false, false, false)
    end

    RemoveAnimDict(dictionaryName)

    if data.Options then
        local secondaryEmote = data.Options.SecondaryEmote

        if secondaryEmote then
            local isSecondaryValid = lib.requestAnimDict(secondaryEmote.Dictionary, 1000)

            if not isSecondaryValid then
                notify('error', lang.not_valid_emote)
                return
            end

            TaskPlayAnim(clone, secondaryEmote.Dictionary, secondaryEmote.Animation, 2.0, 2.0, secondaryEmote.Duration or -1, 51, 0, false, false, false)
            RemoveAnimDict(secondaryEmote.Dictionary)
        end

        local propData = data.Options.Props

        if propData then
            local propCount = #propData

            if propCount > 0 then
                Wait(duration or 0)

                local propList = {}

                for i = 1, propCount do
                    local prop = propData[i]
                    local variant = prop.Variant

                    if variation then
                        if prop.Variations and prop.Variations[variation] then
                            variant = prop.Variations[variation]
                        end
                    end

                    propList[#propList + 1] = {
                        hash = joaat(prop.Name),
                        bone = prop.Bone,
                        placement = prop.Placement,
                        variant = variant
                    }
                end

                if #propList > 0 then
                    for i = 1, #propList do
                        local prop = propList[i]

                        lib.requestModel(prop.hash, 1000)

                        local object = CreateObject(prop.hash, clonePos.x, clonePos.y, clonePos.z, false, false, false)
                        SetEntityCollision(object, false, false)
                        AttachEntityToEntity(object, clone, GetPedBoneIndex(clone, prop.bone), prop.placement[1].x, prop.placement[1].y, prop.placement[1].z, prop.placement[2].x, prop.placement[2].y, prop.placement[2].z, true, true, false, true, 1, true)

                        cloneProps[#cloneProps + 1] = object

                        SetModelAsNoLongerNeeded(prop.hash)
                    end
                end
            end
        end
    end

    local endTimer = ((cloneDuration or 0) + 1) * 1000

    if endTimer > 5000 then
        endTimer = 5000
    end

    Wait(endTimer)

    for i = 1, #cloneProps do
        DeleteEntity(cloneProps[i])
    end

    cloneProps = {}

    DeleteEntity(clone)
end

---Cancel the animation you're currently playing
---@param skipReset boolean
function cancelEmote(skipReset)
    if isPlayingAnimation and not isActionsLimited then
        if IsPedUsingAnyScenario(cache.ped) then ClearPedTasksImmediately(cache.ped) end
        if LocalPlayer.state.ptfx then LocalPlayer.state:set('ptfx', false, true) end
        if Config.PtfxKeybind then keybinds.PlayPtfx:disable(true) end

        ClearPedTasks(cache.ped)
        DetachEntity(cache.ped, true, false)
        TriggerServerEvent('emotemenu:deleteProps', otherPlayer)

        isPlayingAnimation = false
        olvidarEnMarcha()

        if not skipReset then
            lastEmote, lastVariant = nil, nil
        end

        if otherPlayer then
            TriggerServerEvent('emotemenu:cancelSynchronizedEmote', otherPlayer)

            otherPlayer = nil
        end
    end
end
exports('cancelEmote', cancelEmote)

---Get the players current expression
---@return string
function getCurrentExpression()
    return currentExpression
end
exports('getCurrentExpression', getCurrentExpression)

---Set the players current expression
---@param name string
function setExpression(name)
    ---@diagnostic disable-next-line: param-type-mismatch
    SetFacialIdleAnimOverride(cache.ped, name, 0)
    SetResourceKvp('animations_expression', name)

    currentExpression = name
end
exports('setExpression', setExpression)

---Reset the players expression
function resetExpression()
    ClearFacialIdleAnimOverride(cache.ped)
    SetResourceKvp('animations_expression', 'default')

    currentExpression = 'default'
end
exports('resetExpression', resetExpression)

---Get the players current walk style
---@return string
function getCurrentWalk()
    return currentWalk
end
exports('getCurrentWalk', getCurrentWalk)

---Set the players current walk style
---
---Nunca revienta. lib.requestAnimSet lanza un error si el clipset no carga a
---tiempo, y con un segundo de margen pasaba al entrar al servidor: con la ropa
---y el personaje cargando a la vez, 'move_m@gangster@var_c' no llegaba y el
---error subía hasta origen_clothing (y, desde el menú, dejaba la NUI sin
---respuesta). Ahora se espera más y, si aun así no carga, se avisa y se sigue
---andando normal.
---@param name string
---@return boolean
function setWalk(name)
    if type(name) ~= 'string' or name == '' or name == 'default' then
        resetWalk()
        return false
    end

    local ok, err = pcall(lib.requestAnimSet, name, 5000)
    if not ok then
        print(('^3[origen_anims]^7 No se pudo cargar el estilo de andar %s: %s'):format(name, tostring(err)))
        return false
    end

    SetPedMovementClipset(cache.ped, name, 0.2)
    RemoveAnimSet(name)
    SetResourceKvp('animations_walkstyle', name)

    currentWalk = name
    return true
end
exports('setWalk', setWalk)

---Reset the players walk style
function resetWalk()
    ResetPedMovementClipset(cache.ped, 0)
    SetResourceKvp('animations_walkstyle', 'default')

    currentWalk = 'default'
end
exports('resetWalk', resetWalk)

---Finish the animation placement
---@param location vector3
---@param heading number
---@param data table
function finishPlacementEmote(location, heading, data)
    if DoesEntityExist(clone --[[@as number]]) then
        DeleteEntity(clone --[[@as number]])
        for i = 1, #cloneProps do
            if DoesEntityExist(cloneProps[i]) then
                DeleteEntity(cloneProps[i])
            end
        end
    end
    clone = nil

    exports.origen_hud:hideControls()
    TaskGoToCoordAnyMeans(cache.ped, location.x, location.y, location.z, 1.0, 0, false, 786603, 0xbf800000)

    local coords = GetEntityCoords(cache.ped)

    exports.origen_hud:setupControls({
        {
            key = 'RCLICK',
            text = 'Cancelar',
        },
    })

    while #(coords - location) > 1.5 do
        Wait(0)

        coords = GetEntityCoords(cache.ped)

        if IsControlJustPressed(0, 177) then
            exports.origen_hud:hideControls()
            ClearPedTasks(cache.ped)
            location = vec3(0)

            break
        end
    end

    exports.origen_hud:hideControls()
    if location ~= vec3(0) then
        SetEntityCoords(cache.ped, location.x, location.y, location.z, false, false, false, false)

        data.Advanced = {
            Coords = location,
            Heading = heading,
        }

        playEmote(data)
    end
end

local function RotationToDirection(rotation)
    local x = rotation.x * math.pi / 180.0
    local z = rotation.z * math.pi / 180.0
    local num = math.abs(math.cos(x))
    return vector3((-math.sin(z) * num), (math.cos(z) * num), math.sin(x))
end

local function RayCastGamePlayCamera(distance, camCoords, camRot)
    local cameraRotation = camRot or GetGameplayCamRot()
    local cameraCoord = camCoords or GetGameplayCamCoord()
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

local function GetScreenCoords(distance, camCoords, camRot)
	local hit, coords, entity = RayCastGamePlayCamera(distance or 1000.0, camCoords, camRot)
    return hit, coords, entity
end

---Start the animation placement
---@param data table
function startPlacementThread(data)
    clone = ClonePed(cache.ped, false, false, true)
    local clonePos = GetOffsetFromEntityInWorldCoords(clone, 0.0, 4.5, 0.0)
    

    FreezeEntityPosition(clone, true)
    SetEntityAlpha(clone, 0, false)

    local dictionaryName, animationName = data.Dictionary, data.Animation
    local isValid = lib.requestAnimDict(dictionaryName, 1000)

    if not isValid then
        notify('error', lang.not_valid_emote)
        return
    end

    if data.Options then
        duration = data.Options.Duration

        if data.Options.Delay then Wait(data.Options.Delay) end

        if not cache.vehicle and data.Options.Flags then
            if data.Options.Flags.Loop then movementFlag = 1 end
            if data.Options.Flags.Move then movementFlag = 51 end
            if data.Options.Flags.Stuck then movementFlag = 50 end
        end
    end

    TaskPlayAnim(clone, dictionaryName, animationName, 2.0, 2.0, duration or -1, movementFlag, 0, false, false, false)
    RemoveAnimDict(dictionaryName)

    if data.Options then
        local secondaryEmote = data.Options.SecondaryEmote

        if secondaryEmote then
            local isSecondaryValid = lib.requestAnimDict(secondaryEmote.Dictionary, 1000)

            if not isSecondaryValid then
                notify('error', lang.not_valid_emote)
                return
            end

            TaskPlayAnim(clone, secondaryEmote.Dictionary, secondaryEmote.Animation, 2.0, 2.0, secondaryEmote.Duration or -1, 51, 0, false, false, false)
            RemoveAnimDict(secondaryEmote.Dictionary)
        end

        local propData = data.Options.Props

        if propData then
            local propCount = #propData

            if propCount > 0 then
                Wait(duration or 0)

                local propList = {}

                for i = 1, propCount do
                    local prop = propData[i]
                    local variant = prop.Variant

                    if variation then
                        if prop.Variations and prop.Variations[variation] then
                            variant = prop.Variations[variation]
                        end
                    end

                    propList[#propList + 1] = {
                        hash = joaat(prop.Name),
                        bone = prop.Bone,
                        placement = prop.Placement,
                        variant = variant
                    }
                end

                if #propList > 0 then
                    for i = 1, #propList do
                        local prop = propList[i]

                        lib.requestModel(prop.hash, 1000)

                        local object = CreateObject(prop.hash, clonePos.x, clonePos.y, clonePos.z, false, false, false)
                        SetEntityCollision(object, false, false)
                        AttachEntityToEntity(object, clone, GetPedBoneIndex(clone, prop.bone), prop.placement[1].x, prop.placement[1].y, prop.placement[1].z, prop.placement[2].x, prop.placement[2].y, prop.placement[2].z, true, true, false, true, 1, true)

                        cloneProps[#cloneProps + 1] = object

                        SetModelAsNoLongerNeeded(prop.hash)
                    end
                end
            end
        end
    end

    SetEntityCollision(clone, false, false)
    SetEntityAlpha(clone, 200, false)
    SetBlockingOfNonTemporaryEvents(clone, true)

    local currentCoords = nil
    local heading = GetEntityHeading(cache.ped) + 90.0
    
    exports.origen_hud:setupControls({
        {
            key = 'LCLICK',
            text = 'Colocar',
        },
        {
            key = 'WHEEL',
            text = 'Rotar',
        },
        {
            key = 'UP',
            text = 'Subir',
        },
        {
            key = 'DOWN',
            text = 'Bajar',
        },
        {
            key = 'RCLICK',
            text = 'Cancelar',
        }
    })

    SetPedConfigFlag(PlayerPedId(), 122, true)

    SetTimeout(0, function()
        local offsetZ = 0.0

        --[[ CreateThread(function()
            while clone do
                hit, endCoords = GetScreenCoords()
                Wait(5)
            end
        end) ]]

        while clone do
            local hit, endCoords = GetScreenCoords(20.0)

            DisableControlAction(0, 24, true)
            currentCoords = endCoords
            SetEntityCoords(clone, currentCoords.x, currentCoords.y, currentCoords.z + offsetZ, false, false, false, false)
            SetEntityHeading(clone, heading)

            if IsControlPressed(0, 14) then
                heading += 5

                if heading > 360 then heading = 0.0 end
            elseif IsControlPressed(0, 15) then
                heading -= 5

                if heading < 0 then heading = 360.0 end
            elseif IsDisabledControlPressed(0, 27) then
                offsetZ += 0.01

                if offsetZ > 1.0 then offsetZ = 1.0 end
            elseif IsDisabledControlPressed(0, 173) then
                offsetZ -= 0.01

                if offsetZ < -1.0 then offsetZ = -1.0 end
            end

            if IsDisabledControlPressed(0, 24) or IsControlJustPressed(0, 24) then
                local coords = GetEntityCoords(cache.ped)
                local distance = #(coords - currentCoords)

                if distance < 5.0 then
                    exports.origen_hud:hideControls()
                    SetPedConfigFlag(PlayerPedId(), 122, false)
                    finishPlacementEmote(GetEntityCoords(clone), heading, lib.table.deepclone(data))
                else
                    notify('error', lang.too_far)
                end
            elseif IsControlJustPressed(0, 177) then
                if DoesEntityExist(clone) then DeleteEntity(clone) end
                for i = 1, #cloneProps do
                    if DoesEntityExist(cloneProps[i]) then
                        DeleteEntity(cloneProps[i])
                    end
                end
                SetPedConfigFlag(PlayerPedId(), 122, false)
                clone = nil
                exports.origen_hud:hideControls()
            end

            Wait(0)
        end
    end)
end

---Attach a prop to the player
---@param object number
---@param bone number
---@param placement table
---@param variant number
function addPropToPlayer(object, bone, placement, variant)
    SetEntityCollision(object, false, false)

    if variant then SetObjectTextureVariation(object, variant) end

    AttachEntityToEntity(object, cache.ped, GetPedBoneIndex(cache.ped, bone), placement[1].x, placement[1].y, placement[1].z, placement[2].x, placement[2].y, placement[2].z, true, true, false, true, 1, true)
end

---Remove unsupported emotes
function removeUnsupportedEmotes()
    local checkMenus = {
        'Walks',
        'Scenarios',
        'Expressions',
        'Emotes',
        'PropEmotes',
        'ConsumableEmotes',
        'DanceEmotes',
        'SynchronizedEmotes',
        'AnimalEmotes'
    }

    local DoesAnimDictExist = DoesAnimDictExist
    local IsModelValid = IsModelValid

    for i = 1, #checkMenus do
        if AnimationList[checkMenus[i]] then
            AnimationList[checkMenus[i]] = removeFromTable(AnimationList[checkMenus[i]], function(_table, _index)
                local animation, doesExist = _table[_index], true

                if gameBuild < 2699 then
                    if animation.Dictionary and not DoesAnimDictExist(animation.Dictionary) then doesExist = false end
                    if animation.Options and animation.Options.Props then
                        local props = animation.Options.Props
                        local propCount = #props

                        if propCount > 0 then
                            for k = 1, propCount do
                                if not IsModelValid(joaat(props[k].Name)) then
                                    doesExist = false
                                    break
                                end
                            end
                        end
                    end
                end

                return doesExist
            end)
        end
    end
end

local IsPedFalling = IsPedFalling
local IsPedJumping = IsPedJumping
local IsAimCamActive = IsAimCamActive
local SetPedMaxMoveBlendRatio = SetPedMaxMoveBlendRatio
local IsPedUsingActionMode = IsPedUsingActionMode
local SetPedUsingActionMode = SetPedUsingActionMode
local SetPedCanPlayAmbientAnims = SetPedCanPlayAmbientAnims
local DisableFirstPersonCamThisFrame = DisableFirstPersonCamThisFrame

---Crouch loop
function crouchLoop()
    CreateThread(function()
        while LocalPlayer.state.stance == 1 do
            Wait(0)

            if cache.vehicle then
                LocalPlayer.state:set('stance', 0, false)
                break
            end

            if IsPedFalling(cache.ped) then
                LocalPlayer.state:set('stance', 0, false)
                break
            end

            if IsPedJumping(cache.ped) then
                LocalPlayer.state:set('stance', 0, false)
                break
            end

            if IsAimCamActive() then
                SetPedMaxMoveBlendRatio(cache.ped, 0.15)
            end

            if IsPedUsingActionMode(cache.ped) then
                SetPedUsingActionMode(cache.ped, false, -1, 'DEFAULT_ACTION')
            end

            SetPedCanPlayAmbientAnims(cache.ped, false)
            DisableFirstPersonCamThisFrame()
        end
    end)
end

-- Disable the stance controls
function disableStanceControls()
    lib.disableControls:Add({36, 26})

    CreateThread(function()
        while IsDisabledControlPressed(0, 36) or IsDisabledControlPressed(0, 26) do
            Wait(0)

            lib.disableControls()
        end

        lib.disableControls:Remove({36, 26})
    end)
end

-- Add / Remove options
removeUnsupportedEmotes()

--[[ if not Config.EnableNSFWEmotes then
    removeEmotes('NSFW')
end ]]

--[[ if not Config.EnableGangEmotes then
    removeEmotes('Gang')
end ]]

if not Config.EnableSocialMovementEmotes then
    removeEmotes('SocialMovement')
end

-- Commands
for i = 1, #Config.MenuOpenCommands do
    RegisterCommand(Config.MenuOpenCommands[i], function(source, args, rawCommand)
        if isActionsLimited then return end

        if plyState.isAnimMenuOpen then 
            closeMenu()
            return
        end

        if IsNuiFocused() then return end

        toggleMenu()
    end, false)
end

for i = 1, #Config.EmotePlayCommands do
    RegisterCommand(Config.EmotePlayCommands[i], function(source, args, rawCommand)
        if isActionsLimited then return end

        if not args[1] then
            notify('error', lang.not_valid_emote)

            return
        end

        local emoteName = args[1]:lower()

        if emoteName == 'c' then
            cancelEmote(false)

            return
        end

        local _type, emote = getEmoteByCommand(emoteName)

        if not _type or _type == 'Walks' then
            notify('error', lang.not_valid_emote)

            return
        end

        if _type == 'SynchronizedEmotes' then
            requestSynchronizedEmote(emote)

            return
        end

        local variant = nil
        local selectedVariant = args[2]

        if selectedVariant then
            local index = tonumber(selectedVariant)

            if index then variant = index end
        end

        playEmote(emote --[[@as table]], variant)
    end, false)
end

for i = 1, #Config.WalkSetCommands do
    RegisterCommand(Config.WalkSetCommands[i], function(_, args)
        if isActionsLimited then return end

        if not args[1] then
            notify('error', lang.not_valid_walk)

            return
        end

        local walkName = args[1]:lower()

        if walkName == 'c' then
            resetWalk()

            return
        end

        local _type, emote = getEmoteByCommand(walkName)

        if not _type or (_type ~= 'Walks') then
            notify('error', lang.not_valid_walk)

            return
        end

        setWalk(emote?.Walk)
    end, false)
end

-- Keybinds
if Config.MenuKeybind ~= '' then
    if #Config.MenuOpenCommands > 0 then
        RegisterKeyMapping(Config.MenuOpenCommands[1], lang.open_emote_menu, 'keyboard', Config.MenuKeybind)
    end
end

if Config.CancelEmoteKey ~= '' then
    keybinds.CancelKey = lib.addKeybind({
        name = 'ecancel',
        description = lang.cancel_your_emote,
        defaultKey = Config.CancelEmoteKey,
        onPressed = function()
            if lastEmote and lastEmote?.Command == 'handsup' then
                return
            end
            if plyState.inTrunk then return end
            cancelEmote(false)
        end
    })
end

-- Bindeos del menu. Se leen con IsRawKey* y no con RegisterKeyMapping porque
-- la tecla la elige el jugador desde la NUI y un mapping no se puede cambiar
-- desde codigo: se quedaria con la primera que viera.
---@param cmd string
local function usarAnimacion(cmd)
    local _type, emote = getEmoteByCommand(cmd)
    if not _type or not emote then return end

    if _type == 'Walks' then
        setWalk(emote.Walk)
    elseif _type == 'SynchronizedEmotes' then
        requestSynchronizedEmote(emote)
    else
        playEmote(emote)
    end
end

if IsRawKeyPressed then
    CreateThread(function()
        while true do
            local hayAlguno = false
            for i = 1, #animBinds do
                if animBinds[i].cmd and animBinds[i].vk then hayAlguno = true break end
            end

            -- Las teclas «en crudo» llegan aunque haya un chat o un menu con el
            -- foco: sin este filtro, escribir en el chat lanzaria animaciones.
            local libre = hayAlguno and not plyState.isAnimMenuOpen and not IsNuiFocused()
                and not IsPauseMenuActive() and not isActionsLimited and not IsEntityDead(cache.ped)

            if libre then
                for i = 1, #animBinds do
                    local b = animBinds[i]
                    if b.cmd and b.vk and IsRawKeyPressed(b.vk) then
                        -- La misma tecla otra vez la para.
                        if isPlayingAnimation and enMarcha.cmd == b.cmd then
                            cancelEmote(false)
                        else
                            -- En su hilo: playEmote espera (retardos, props) y
                            -- este tiene que seguir mirando teclas.
                            CreateThread(function() usarAnimacion(b.cmd) end)
                        end
                    end
                end
            end

            Wait(libre and 0 or 250)
        end
    end)
end

-- if Config.RagdollKeybind ~= '' then
--     local IsPedOnFoot = IsPedOnFoot
--     local SetPedToRagdoll = SetPedToRagdoll

--     keybinds.Ragdoll = lib.addKeybind({
--         name = 'suelo',
--         description = lang.ragdoll_character,
--         defaultKey = Config.RagdollKeybind,
--         onPressed = function()
--             if isActionsLimited or isPlayingAnimation or plyState.isAnimMenuOpen then return end

--             isRagdoll = not isRagdoll

--             while isRagdoll do
--                 Wait(0)
--                 if isActionsLimited then
--                     isRagdoll = false
--                     break
--                 end

--                 if IsPedOnFoot(cache.ped) then
--                     SetPedToRagdoll(cache.ped, 1000, 1000, 0, false, false, false)
--                 end
--             end
--         end
--     })
-- end

RegisterCommand('suelo', function(source, args, rawCommand)
    if isActionsLimited or isPlayingAnimation or plyState.isAnimMenuOpen then return end

    isRagdoll = not isRagdoll

    while isRagdoll do
        Wait(0)
        if isActionsLimited then
            isRagdoll = false
            break
        end

        if IsPedOnFoot(cache.ped) then
            SetPedToRagdoll(cache.ped, 1000, 1000, 0, false, false, false)
        end
    end
end, false)

if Config.HandsUpKey ~= '' then
    keybinds.HandsUp = lib.addKeybind({
        name = 'handsup',
        description = lang.hands_up,
        defaultKey = Config.HandsUpKey,
        onPressed = function()
            if isActionsLimited then return end
            if cache.vehicle then return end
            if plyState.inTrunk then return end

            if lastEmote and lastEmote?.Command == 'handsup' then
                cancelEmote(false)
                return
            end

            playEmoteByCommand('handsup')
        end,
    })
end

if Config.CrossArmsKey ~= '' then
    keybinds.CrossArms = lib.addKeybind({
        name = 'crossarms',
        description = lang.crossarms,
        defaultKey = Config.CrossArmsKey,
        onPressed = function()
            if isActionsLimited or cache.vehicle or plyState.isAnimMenuOpen or plyState.invOpen or plyState.inTrunk then return end

            if lastEmote and lastEmote?.Command == 'crossarms' then
                cancelEmote(false)
                return
            end

            playEmoteByCommand('crossarms')
        end,
    })
end

if Config.StanceKey ~= '' then
    LocalPlayer.state:set('stance', 0, false)

    keybinds.Stance = lib.addKeybind({
        name = 'crouch',
        description = lang.stance,
        defaultKey = Config.StanceKey,
        onPressed = function()
            if isActionsLimited or cache.vehicle or plyState.isAnimMenuOpen or plyState.invOpen then return end
            -- `invOpen` es de ox_inventory: origen_inventory no lo pone nunca. Con un menu
            -- delante (el inventario usa Control para elegir varios objetos) no se agacha.
            if IsNuiFocused() or IsPauseMenuActive() then return end

            DisableControlAction(0, 36, true)
            DisableControlAction(0, 26, true)
            disableStanceControls()

            local stanceLevel = LocalPlayer.state.stance

            if stanceLevel == 1 then 
                stanceLevel = 0

            else
                stanceLevel = 1
            end
            LocalPlayer.state:set('stance', stanceLevel, false)
        end
    })
end

if Config.PointKey ~= '' then
    local GetGameplayCamRelativePitch = GetGameplayCamRelativePitch
    local GetGameplayCamRelativeHeading = GetGameplayCamRelativeHeading
    local Cos = Cos
    local Sin = Sin
    local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
    local StartShapeTestCapsule = StartShapeTestCapsule
    local GetShapeTestResult = GetShapeTestResult
    local SetTaskMoveNetworkSignalFloat = SetTaskMoveNetworkSignalFloat
    local SetTaskMoveNetworkSignalBool = SetTaskMoveNetworkSignalBool
    local GetCamViewModeForContext = GetCamViewModeForContext
    local GetCamActiveViewModeContext = GetCamActiveViewModeContext

    keybinds.Point = lib.addKeybind({
        name = 'point',
        description = lang.point,
        defaultKey = Config.PointKey,
        onPressed = function()
            if isActionsLimited or plyState.isAnimMenuOpen then return end

            isPointing = not isPointing

            if isPointing then
                if cache.vehicle then return end

                lib.requestAnimDict('anim@mp_point', 1000)
                SetPedCurrentWeaponVisible(cache.ped, false, true, true, true)
                SetPedConfigFlag(cache.ped, 36, true)
                TaskMoveNetworkByName(cache.ped, 'task_mp_pointing', 0.5, false, 'anim@mp_point', 24)
                RemoveAnimDict('anim@mp_point')
                CreateThread(function()
                    while isPointing do
                        Wait(0)
                        local camPitch = GetGameplayCamRelativePitch()

                        if camPitch < -70.0 then
                            camPitch = -70.0
                        elseif camPitch > 42.0 then
                            camPitch = 42.0
                        end

                        camPitch = (camPitch + 70.0) / 112.0

                        local camHeading = GetGameplayCamRelativeHeading()
                        local cosCamHeading = Cos(camHeading)
                        local sinCamHeading = Sin(camHeading)

                        if camHeading < -180.0 then
                            camHeading = -180.0
                        elseif camHeading > 180.0 then
                            camHeading = 180.0
                        end

                        camHeading = (camHeading + 180.0) / 360.0

                        local coords = GetOffsetFromEntityInWorldCoords(cache.ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
                        local ray = StartShapeTestCapsule(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, cache.ped, 7)
                        local _, blocked = GetShapeTestResult(ray)

                        SetTaskMoveNetworkSignalFloat(cache.ped, 'Pitch', camPitch)
                        SetTaskMoveNetworkSignalFloat(cache.ped, 'Heading', camHeading * -1.0 + 1.0)
                        SetTaskMoveNetworkSignalBool(cache.ped, 'isBlocked', blocked)
                        SetTaskMoveNetworkSignalBool(cache.ped, 'isFirstPerson', GetCamViewModeForContext(GetCamActiveViewModeContext()) == 4)
                    end
                end)
            else
                RequestTaskMoveNetworkStateTransition(cache.ped, 'Stop')

                if not IsPedInjured(cache.ped) then ClearPedSecondaryTask(cache.ped) end
                if not cache.vehicle then SetPedCurrentWeaponVisible(cache.ped, true, true, true, true) end

                SetPedConfigFlag(cache.ped, 36, false)
                ClearPedSecondaryTask(cache.ped)
            end
        end
    })
end

if Config.PtfxKeybind then
    keybinds.PlayPtfx = lib.addKeybind({
        name = 'playptfx',
        disabled = true,
        description = lang.play_ptfx,
        defaultKey = Config.PtfxKeybind,
        onPressed = function()
            LocalPlayer.state:set('ptfx', true, true)

            if not ptfxCanHold then
                LocalPlayer.state:set('ptfx', false, true)
            end
        end,
        onReleased = function()
            if ptfxCanHold then
                LocalPlayer.state:set('ptfx', false, true)
            end
        end
    })
end

-- State Bag Handlers
---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler('ptfx', nil, function(bagName, _, value)
    local serverId = tonumber(bagName:gsub('player:', ''), 10)

    if (playerParticles[serverId] and value) or (not playerParticles[serverId] and not value) then return end

    local playerId = GetPlayerFromServerId(serverId)

    if not playerId then return end

    local playerPed = GetPlayerPed(playerId)
    local stateBag = Player(serverId).state

    if value then
        local asset, name, offset, rot, scale, color, propNet, entityTarget = stateBag.ptfxAsset, stateBag.ptfxName, stateBag.ptfxOffset, stateBag.ptfxRot, stateBag.ptfxScale or 1, stateBag.ptfxColor, stateBag.ptfxPropNet, playerPed
        local boneIndex = stateBag.ptfxBone and GetPedBoneIndex(playerPed, stateBag.ptfxBone) or GetEntityBoneIndexByName(name, "VFX")

        if propNet then
            local propObj = NetworkGetEntityFromNetworkId(propNet)
            if DoesEntityExist(propObj) then entityTarget = propObj end
        end

        lib.requestNamedPtfxAsset(asset, 1000)
        UseParticleFxAsset(asset)
        playerParticles[serverId] = StartParticleFxLoopedOnEntityBone(name, entityTarget, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneIndex, scale + 0.0, false, false, false)

        if color then
            if color[1] and type(color[1]) == 'table' then
                local randomIndex = math.random(1, #color)

                color = color[randomIndex]
            end

            SetParticleFxLoopedAlpha(playerParticles[serverId], color.A)
            SetParticleFxLoopedColour(playerParticles[serverId], color.R / 255, color.G / 255, color.B / 255, false)
        end
    else
        StopParticleFxLooped(playerParticles[serverId], false)
        RemoveNamedPtfxAsset(stateBag.ptfxAsset)
        playerParticles[serverId] = nil
    end
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler('stance', nil, function(_, _, value)
    if value == 0 then
        SetPedStealthMovement(cache.ped, false, 0)
        SetPedMaxMoveBlendRatio(cache.ped, 1.0)
        ResetPedMovementClipset(cache.ped, 0.55)
        ResetPedStrafeClipset(cache.ped)
        SetPedCanPlayAmbientAnims(cache.ped, true)
        SetPedCanPlayAmbientBaseAnims(cache.ped, true)
        ResetPedWeaponMovementClipset(cache.ped)
        if currentWalk and currentWalk ~= 'default' then
            lib.requestAnimSet(currentWalk, 1000)
            SetPedMovementClipset(cache.ped, currentWalk, 1.0)
        end

    elseif value == 1 then -- Crouched
        lib.requestAnimSet('move_ped_crouched', 1000)
        ---@diagnostic disable-next-line: param-type-mismatch
        SetPedStealthMovement(cache.ped, false, 0)
        SetPedMovementClipset(cache.ped, 'move_ped_crouched', 1.0)
        SetPedWeaponMovementClipset(cache.ped, 'move_ped_crouched')
        SetPedStrafeClipset(cache.ped, 'move_ped_crouched_strafing')
        crouchLoop()
    end
end)

-- Events
RegisterNetEvent('emotemenu:cancelEmote', cancelEmote)
RegisterNetEvent('emotemenu:closeMenu', closeMenu)
RegisterNetEvent('emotemenu:play', playEmote)
RegisterNetEvent('emotemenu:playByCommand', playEmoteByCommand)
RegisterNetEvent('emotemenu:playRegisteredEmote', playRegisteredEmote)
RegisterNetEvent('emotemenu:registerEmote', registerEmote)
RegisterNetEvent('emotemenu:resetExpression', resetExpression)
RegisterNetEvent('emotemenu:setExpression', setExpression)
RegisterNetEvent('emotemenu:resetWalk', resetWalk)
RegisterNetEvent('emotemenu:setWalk', setWalk)
RegisterNetEvent('emotemenu:toggleLimitation', setLimitation)
RegisterNetEvent('emotemenu:toggleMenu', toggleMenu)

local IsControlJustPressed = IsControlJustPressed

RegisterNetEvent('emotemenu:synchronizedEmoteRequest', function(sender, senderData, targetData)
    PlaySoundFrontend(-1, 'NAV', 'HUD_AMMO_SHOP_SOUNDSET', false)

    local isDead = false
    if GetResourceState('origen_ems') == 'started' then
        local ok, result = pcall(function()
            return exports.origen_ems:IsDead()
        end)
        isDead = ok and result or false
    end

    if not senderData or not targetData then
        notify('error', lang.not_valid_emote)
        return
    end

    if isDead and (senderData?.Command == 'carry2' or senderData?.Command == 'scarry' or senderData?.Command == 'scarry3') then
        if GetResourceState('origen_notify') == 'started' then
            exports.origen_notify:showNotification({
                description = 'Has recibido una solicitud de cargar, presiona Y para aceptar o N para rechazar',
                type = 'info',
                duration = 12000,
            })
        else
            notify('info', 'Has recibido una solicitud de cargar. Pulsa Y para aceptar o N para rechazar')
        end
    else
        local label = targetData.Label or 'animacion compartida'
        if GetResourceState('origen_notify') == 'started' then
            exports.origen_notify:showNotification({
                title = ('Solicitud de animación (%s)'):format(label),
                description = 'Pulsa Y para aceptar o N para rechazar',
                type = 'info',
                duration = 10000,
            })
        else
            notify('info', ('Solicitud de animación (%s). Pulsa Y para aceptar o N para rechazar'):format(label))
        end
    end

    if GetResourceState('origen_hud') == 'started' then
        exports.origen_hud:setupControls({
            {
                key = 'Y',
                text = 'Aceptar',
            },
            {
                key = 'N',
                text = 'Rechazar',
            },
        })
    end

    CreateThread(function()
        local timeoutAt = GetGameTimer() + 10000
        while true do
            Wait(0)
            if IsControlJustPressed(0, 246) then
                if GetResourceState('origen_hud') == 'started' then
                    exports.origen_hud:hideControls()
                end
                TriggerServerEvent('emotemenu:synchronizedEmoteResponse', sender, senderData, targetData)
                break
            elseif IsControlJustPressed(0, 306) then
                if GetResourceState('origen_hud') == 'started' then
                    exports.origen_hud:hideControls()
                end
                TriggerServerEvent('emotemenu:synchronizedEmoteRejected', sender)
                break
            elseif GetGameTimer() >= timeoutAt then
                if GetResourceState('origen_hud') == 'started' then
                    exports.origen_hud:hideControls()
                end
                TriggerServerEvent('emotemenu:synchronizedEmoteRejected', sender)
                break
            end
        end
    end)
end)

RegisterNetEvent('emotemenu:synchronizedEmoteRejected', function()
    if GetResourceState('origen_notify') == 'started' then
        exports.origen_notify:showNotification({
            description = 'El jugador ha rechazado o no ha respondido a la solicitud.',
            type = 'error',
            duration = 5000,
        })
    else
        notify('error', 'El jugador ha rechazado o no ha respondido a la solicitud.')
    end
end)

RegisterNetEvent('emotemenu:targetStartSynchronizedEmote', function(sender, senderData, targetData)
    local isValid = lib.requestAnimDict(targetData.Dictionary, 1000)

    if not isValid then
        notify('error', lang.not_valid_emote)
        return
    end

    if targetData.Options.Shared.Attach and not senderData.Options.Shared.Attach then
        local senderId = GetPlayerFromServerId(sender)
        local senderPed = GetPlayerPed(senderId)
        local bone = targetData.Options.Shared.Bone or -1
        local placement = targetData.Options.Shared.Placement
        local xP, yP, zP, xR, yR, zR = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0

        if placement then
            xP, yP, zP, xR, yR, zR = placement[1].x, placement[1].y, placement[1].z, placement[2].x, placement[2].y, placement[2].z
        end

        AttachEntityToEntity(cache.ped, senderPed, GetPedBoneIndex(senderPed, bone), xP, yP, zP, xR, yR, zR, false, false, false, true, 1, true)
    end

    playEmote(targetData)
    otherPlayer = sender
end)

RegisterNetEvent('emotemenu:senderStartSynchronizedEmote', function(target, senderData)
    local isValid = lib.requestAnimDict(senderData.Dictionary, 1000)

    if not isValid then
        notify('error', lang.not_valid_emote)
        return
    end

    local targetId = GetPlayerFromServerId(target)
    local targetPed = GetPlayerPed(targetId)
    local frontOffset, sideOffset, heightOffset, headingOffset = 1.0, 0.0, 0.0, 180.1

    if senderData.Options.Shared.FrontOffset then
        frontOffset = senderData.Options.Shared.FrontOffset + 0.0
    end

    if senderData.Options.Shared.SideOffset then
        sideOffset = senderData.Options.Shared.SideOffset + 0.0
    end

    if senderData.Options.Shared.HeightOffset then
        heightOffset = senderData.Options.Shared.HeightOffset + 0.0
    end

    if senderData.Options.Shared.HeadingOffset then
        headingOffset = senderData.Options.Shared.HeadingOffset + 0.0
    end

    if senderData.Options.Shared.Attach then
        local bone = senderData.Options.Shared.Bone or -1
        local placement = senderData.Options.Shared.Placement
        local xP, yP, zP, xR, yR, zR = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
        if placement then
            xP, yP, zP, xR, yR, zR = placement[1].x, placement[1].y, placement[1].z, placement[2].x, placement[2].y, placement[2].z
        end
        AttachEntityToEntity(cache.ped, targetPed, GetPedBoneIndex(targetPed, bone), xP, yP, zP, xR, yR, zR, false, false, false, true, 1, true)
    end

    local targetCoords = GetOffsetFromEntityInWorldCoords(targetPed, sideOffset, frontOffset, heightOffset)
    local targetHeading = GetEntityHeading(targetPed)

    SetEntityHeading(cache.ped, targetHeading - headingOffset)
    SetEntityCoordsNoOffset(cache.ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false)
    playEmote(senderData)

    otherPlayer = target
end)

RegisterNetEvent('emotemenu:cancelSynchronizedEmote', function()
    otherPlayer = nil

    notify('error', lang.emote_cancelled)
    cancelEmote(false)
end)

-- Cache
-- lib.onCache('ped', function(playerPed)
--     if cache.ped ~= playerPed then
--         if currentExpression ~= 'default' then
--             setExpression(currentExpression)
--         end

--         if currentWalk ~= 'default' then
--             setWalk(currentWalk)
--         end
--     end
-- end)

-- AddEventHandler('playerSpawned', function()
--     Wait(1000)
--     if currentExpression ~= 'default' then
--         setExpression(currentExpression)
--     end

--     if currentWalk ~= 'default' then
--         setWalk(currentWalk)
--     end
-- end)

AddEventHandler('entityDamaged', function(entity)
    if cache.ped == entity then
        if not IsPedFatallyInjured(cache.ped) then return end

        cancelEmote(false)
    end
end)

local openingDoor = false
local IsPedOpeningADoor = IsPedOpeningADoor

AddEventHandler('CEventOpenDoor', function()
    if not isPlayingAnimation then return end
    if openingDoor then return end

    openingDoor = true

    while IsPedOpeningADoor(cache.ped) do
        Wait(100)
    end

    openingDoor = false

    if lastEmote then
        cancelEmote(true)
        Wait(10)
        playEmote(lastEmote, lastVariant)
    end
end)

local hitTimeout, hittingPed = 500, false

AddEventHandler('CEventPlayerCollisionWithPed', function()
    if not isPlayingAnimation then return end

    if hittingPed then
        hitTimeout = 500
        return
    end

    hitTimeout, hittingPed = 500, true

    while hitTimeout > 0 do
        Wait(100)

        hitTimeout -= 100
    end

    if lastEmote then
        hitTimeout, hittingPed = 500, false

        cancelEmote(true)
        Wait(10)
        playEmote(lastEmote, lastVariant)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        cancelEmote(false)
        -- Parar el recurso con el menu abierto dejaba la pantalla y el raton
        -- puestos. closeMenu() la esconde y suelta el foco sin mirar si el
        -- menu constaba como abierto, asi que vale siempre.
        closeMenu()
    end
end)

-- RegisterCommand('cargar', function()
--     ExecuteCommand('e scarry')
-- end)

-- RegisterCommand('brazos', function()
--     ExecuteCommand('e carry2')
-- end)

-- RegisterCommand('cargarr', function()
--     ExecuteCommand('e scarry3')
-- end)

local SetPedCanPlayAmbientIdles = SetPedCanPlayAmbientIdles

CreateThread(function()
    while true do
        if cache.vehicle then
            Wait(1000)
        else
            SetPedCanPlayAmbientIdles(cache.ped, true, true)
            Wait(0)
        end
    end
end)

exports('getAllAnims', function()
    return AnimationList
end)

exports('getEmoteByCommand', getEmoteByCommand)
