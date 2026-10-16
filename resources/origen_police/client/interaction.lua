local minmapmode = 1
local dragged = false
local draggin = false
local translationsRecived = false
local handCuffObject = nil

--[[ ── Borrar el prop de las esposas (16/09/2026) ─────────────────────────
     Antes se hacia un DeleteEntity a secas sobre la referencia guardada, y el
     prop se quedaba en la muñeca si el objeto (que es de red) habia pasado a
     ser de otro jugador, o si te esposaban dos veces y la referencia vieja se
     perdia. Ahora: se pide el control antes de borrar, se barren TODAS las
     esposas enganchadas al ped, y si aun asi no se puede, lo borra el
     servidor (que solo acepta esposas enganchadas a quien lo pide). ]]
local MODELO_ESPOSAS = GetHashKey("p_cs_cuffs_02_s")

local function BorrarPropEsposas(obj)
    if not obj or obj == 0 or not DoesEntityExist(obj) then return end
    if NetworkGetEntityIsNetworked(obj) and not NetworkHasControlOfEntity(obj) then
        local fin = GetGameTimer() + 1000
        NetworkRequestControlOfEntity(obj)
        while not NetworkHasControlOfEntity(obj) and GetGameTimer() < fin do
            Wait(0)
            NetworkRequestControlOfEntity(obj)
        end
    end
    DetachEntity(obj, true, true)
    SetEntityAsMissionEntity(obj, true, true)
    DeleteEntity(obj)
    if DoesEntityExist(obj) and NetworkGetEntityIsNetworked(obj) then
        TriggerServerEvent("origen_police:server:borrarPropEsposas", ObjToNet(obj))
    end
end

-- En el momento: hay que llamarla desde un hilo (espera al control del objeto).
function QuitarPropEsposasYa(obj)
    local ped = PlayerPedId()
    BorrarPropEsposas(obj)
    for _, o in ipairs(GetGamePool("CObject")) do
        if GetEntityModel(o) == MODELO_ESPOSAS and IsEntityAttachedToEntity(o, ped) then
            BorrarPropEsposas(o)
        end
    end
end

-- En segundo plano: se puede llamar desde un export o un evento sin hilo propio.
function QuitarPropEsposas(obj)
    CreateThread(function() QuitarPropEsposasYa(obj) end)
end
local isDragging = false
local isAttached = false
local isEscorting = false

CreateThread(function()
    Wait(5000)
    SendNUIMessage({
        action = "translations",
        translations = Config.Translations,
    })
end)

RegisterCommand(Config.Commands.Minimap.cmd, function()
    if not Config.ChangeMinimapSize then return end
    if IsNuiFocused() then return end
    local PlayerData = FW_GetPlayerData(false)

    if CanOpenTablet(PlayerData.job.name)[1] and PlayerData.job.onduty then
        if minmapmode == 3 then
            minmapmode = 1
        else
            minmapmode = minmapmode + 1
        end
        if minmapmode == 1 then
            SetBigmapActive(false, false)
        elseif minmapmode == 2 then
            SetBigmapActive(true, false)
        elseif minmapmode == 3 then
            SetBigmapActive(true, true)
        end
    end
end)
local customQuickmenuActions = nil
QuickmenuHiddenTabsConfig = {}
local lastFilteredJob = {}

local function FilterQuickAccessTabs(typeName, job)
    local jobCat = GetJobCategory(job)
    local PlayerData = FW_GetPlayerData(false)
    local playerDivisions = PlayerData.metadata.divisions or {}
    local playerGrade = PlayerData.job.grade.level

    if lastFilteredJob[typeName] and lastFilteredJob[typeName] == jobCat then
        -- We don't return here because divisions might have changed, 
        -- but usually we can trust the cache for jobs. 
        -- For simplicity and because division changes are rare during a session menu open,
        -- let's just filter every time for now or improve later.
    end

    lastFilteredJob[typeName] = jobCat
    local result = {}
    local sourceList = Config.QuickMenu[typeName]

    if not sourceList then return result end

    for _, data in pairs(sourceList) do
        local hasJob = false
        if typeName == 'Interactions' and customQuickmenuActions then
            if data.header then
                local headerType = data.translation
                local jobActions = customQuickmenuActions[job] or customQuickmenuActions[jobCat] or {}
                local hasAny = false
                if headerType == 'CitizenInteraction' then
                    local citizenActions = { Search = true, Wifes = true, Escort = true, PutInVehicle = true, JumpTo = true, revive = true, HealWounds = true, CheckStatus = true, Corneta = true }
                    for _, act in ipairs(jobActions) do
                        if citizenActions[act] then
                            hasAny = true
                            break
                        end
                    end
                elseif headerType == 'VehicleInteraction' then
                    local vehicleActions = { VehicleInformation = true, ImpoundVehicle = true, ConfiscateVehicle = true, ForceLock = true, StopTraffic = true, ReduceTraffic = true, ResumeTraffic = true, RadarLimit = true, TrafficCitation = true }
                    for _, act in ipairs(jobActions) do
                        if vehicleActions[act] then
                            hasAny = true
                            break
                        end
                    end
                else
                    hasAny = true
                end
                hasJob = hasAny
            else
                -- Dynamic permission checks for actions
                local allowedJobsForAction = {}
                local actionTranslation = data.translation
                if actionTranslation then
                    for configJob, allowedActions in pairs(customQuickmenuActions) do
                        for _, act in ipairs(allowedActions) do
                            if act == actionTranslation then
                                table.insert(allowedJobsForAction, configJob)
                                break
                            end
                        end
                    end
                end

                if #allowedJobsForAction == 0 then
                    hasJob = false
                else
                    for _, allowed in ipairs(allowedJobsForAction) do
                        if allowed == "all" or allowed == jobCat or allowed == job then
                            -- Respect any original rank restrictions for the matching job if they were defined in Config.QuickMenu
                            local rankRestriction = nil
                            if data.allowedJobs then
                                for _, originalAllowed in pairs(data.allowedJobs) do
                                    if type(originalAllowed) == "table" and originalAllowed.job == allowed then
                                        rankRestriction = originalAllowed.ranks
                                        break
                                    end
                                end
                            end

                            if not rankRestriction then
                                hasJob = true
                                break
                            else
                                if type(rankRestriction) == "table" then
                                    if TableContains(rankRestriction, playerGrade) then
                                        hasJob = true
                                        break
                                    end
                                elseif rankRestriction == playerGrade then
                                    hasJob = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
        else
            -- Default static checks
            if not data.allowedJobs then
                hasJob = true
            else
                for _, allowed in pairs(data.allowedJobs) do
                    if allowed == "all" then
                        hasJob = true
                        break
                    elseif type(allowed) == "string" then
                        if allowed == jobCat then
                            hasJob = true
                            break
                        end
                    elseif type(allowed) == "table" then
                        if allowed.job == jobCat then
                            if not allowed.ranks or (type(allowed.ranks) == "table" and GetTableLength(allowed.ranks) == 0) then
                                hasJob = true
                                break
                            else
                                if type(allowed.ranks) == "table" then
                                    if TableContains(allowed.ranks, playerGrade) then
                                        hasJob = true
                                        break
                                    end
                                elseif allowed.ranks == playerGrade then
                                    hasJob = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        
        local hasDivision = not data.division or (playerDivisions[data.division])

        local hasPermission = true
        if data.permission then
            local perms = Config.Permissions[job]
            if perms and perms[data.permission] then
                hasPermission = playerGrade >= perms[data.permission]
            else
                hasPermission = false
            end
        end

        if hasJob and hasDivision and hasPermission then
            local isHidden = false
            if typeName == 'Tabs' and QuickmenuHiddenTabsConfig and QuickmenuHiddenTabsConfig[data.index] then
                isHidden = true
            end
            if not isHidden then
                local copy = Shallowcopy(data)
                copy.allowedJobs = nil
                result[#result + 1] = copy
            end
        end
    end

    return result
end

RegisterKeyMapping(Config.Commands.Minimap.cmd, Config.Commands.Minimap.description, "keyboard", Config.Commands.Minimap.key)

--[[ Abrir el menu rapido.

     `conRiel` lo pone el acceso del inventario (custom/client/acceso_inventario.lua):
     cuando se viene del riel el menu es la columna entera pegada a el, con el
     riel al canto para poder volver a Inventario, Personaje, Admin o Banda sin
     cerrar y reabrir. `/quickaccess` abre lo mismo: la caja compacta de
     abajo a la derecha se quito el 07/10/2026 y no hay otra forma.

     Y cambia tambien QUIEN puede abrirlo. Por comando hace falta estar de
     servicio, como siempre. Desde el riel basta con tener el trabajo: fuera
     de servicio el panel se abre igual y enseña la pagina de entrar en
     servicio, que es lo unico que se puede hacer sin estar fichado. Un boton
     que desaparece justo cuando hace falta es el error que ya se cometio con
     el acceso de Negocio.

     `sinFoco` es para repintar un panel que YA esta abierto —al entrar en
     servicio—: manda los datos otra vez sin volver a pedir el foco ni arrancar
     un segundo hilo de controles sobre el que ya esta corriendo. ]]
local quickAccessThreadRunning = false

function StartQuickAccessControls()
    if quickAccessThreadRunning or InPause then return end
    quickAccessThreadRunning = true
    CreateThread(function()
        SetNuiFocusKeepInput(Config.Actions.QuickAccessKeepInput)
        while IsNuiFocused() and not InPause do
            Wait(0)
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true)
            EnableControlAction(1, 249, true)
            EnableControlAction(2, 249, true)

            for _, v in pairs(Config.Actions.QuickAccessAllowedInputs) do
                EnableControlAction(0, v, true)
            end
        end
        quickAccessThreadRunning = false
        SetNuiFocusKeepInput(false)
        while IsControlPressed(0, 200) or IsDisabledControlPressed(0, 200) do
            Wait(0)
            DisableControlAction(0, 200, true)
        end
        DisableControlAction(0, 200, true)
    end)
end

--- Cada apertura con foco sube este numero: la respuesta del K9 o el plazo de
--- pintado de una apertura anterior lo ven cambiado y no hacen nada.
local vueltaMenu = 0

--- `relevo`: se llega desde otro panel del riel y su barra sigue en pantalla,
--- asi que la de aqui aparece ya puesta encima en vez de deslizarse.
function OpenQuickAccessMenu(conRiel, sinFoco, relevo)
    local PlayerData = FW_GetPlayerData()
    if not PlayerData or not PlayerData.job or not PlayerData.job.name then return false end
    if not (PlayerData.job.onduty or onduty) then return false end

    if conRiel then
        if not (PuedePanelPolicia and PuedePanelPolicia()) then return false end
    elseif not CanOpenQuickAccessMenu() then
        return false
    end

    -- Se pide ANTES de abrir: la lista depende de si estas en un coche y de
    -- que recursos contesten, y preguntarla dentro del callback del K9 la
    -- dejaria a merced de lo que tarde.
    local riel = conRiel and RielDelInventario and RielDelInventario() or nil

    --[[ Que el menu rapido esta delante. Lo consulta origen_inventory por el
         export EstaAbierto, para comprobar --tras pasarle el relevo-- que este
         panel llego a abrirse de verdad; si no llego, el foco de la NUI se
         quedaria puesto con ninguna pantalla delante. ]]
    MenuRapidoAbierto = true

    --[[ Fuera el seguimiento de misiones mientras el menu esta delante: ocupa
         el mismo canto derecho y se veia por debajo de la columna. Es el mismo
         evento local que usan el radial y las animaciones. ]]
    TriggerEvent('qv2:suppressHud', true)

    --[[ ── Y SE COMPRUEBA QUE EL PANEL LLEGO A PINTARSE ──────────────────────

         Mandar el mensaje no prueba nada. Si la interfaz revienta al montarse
         --un dato que llega mal, una lista que no era lista-- Vue desmonta el
         trozo roto sin decir nada: queda la pantalla en blanco con el foco de
         la NUI cogido, el raton en medio y nada que pulsar. Y desde aqui todo
         parece correcto, porque MenuRapidoAbierto sigue en true.

         Asi que la interfaz contesta cuando se ha pintado de verdad --mirando
         que su div este en el DOM, no solo que la hayan montado-- y si en un
         segundo y medio no ha contestado, se suelta el foco. ]]
    MenuRapidoPintado = false

    --[[ Una repintada (sinFoco) no cuenta como apertura: no debe dejar sin
         foco a una apertura de verdad que aun espera al K9. ]]
    if not sinFoco then vueltaMenu = vueltaMenu + 1 end
    local mia = vueltaMenu

    --[[ El plazo de 1,5 s arranca cuando se MANDA el panel, no antes: si
         arrancaba antes de pedir los datos del K9, un servidor lento se comia
         el plazo entero y soltaba el foco con el panel ya llegando. ]]
    local function vigilarPintado()
        SetTimeout(1500, function()
            if vueltaMenu ~= mia or not MenuRapidoAbierto or MenuRapidoPintado then return end

            print('^1[origen_police]^0 El menu rapido no llego a pintarse. Se suelta el foco para no dejar el raton preso.')
            --[[ No llego a pintarse, asi que no hay nada que quitar. Lo
                 unico que importa es devolver el raton (y el seguimiento de
                 misiones, que se escondio al abrir). ]]
            MenuRapidoAbierto = false
            SetNuiFocusKeepInput(false)
            SetNuiFocus(false, false)
            TriggerEvent('qv2:suppressHud', false)
        end)
    end

    local enviado = false
    local function openMenu(dogData)
        --[[ Una sola vez por apertura (la respuesta del K9 y su plazo compiten)
             y solo si sigue en pie: cerrado mientras se esperaba al K9, o
             vuelto a abrir por otro camino, el panel no se pinta ni coge el
             foco —se quedaria a la vista sin nadie que lo cerrase—. ]]
        if enviado then return end
        enviado = true
        if not MenuRapidoAbierto then return end
        if not sinFoco and vueltaMenu ~= mia then return end

        local currentRef = GetLocalReference and GetLocalReference()
        SendNUIMessage({
            action = 'OpenQuickAccess',
            riel = riel,
            relevo = relevo == true,
            sprite = currentRef and currentRef.sprite or nil,
            unitColor = currentRef and currentRef.color or nil,
            translations = not translationsRecived and Config.Translations or nil,
            permissions = exports["origen_police"]:GetPermissions(),
            jobData = {
                duty = PlayerData.job.onduty,
                name = PlayerData.job.name,
                -- El nombre bonito del departamento y del rango. La caja de
                -- abajo a la derecha no los usaba, pero la columna del riel
                -- lleva cabecera y ahi hace falta poner algo que se lea:
                -- 'police' y '3' no son eso.
                label = PlayerData.job.label,
                gradeLabel = (type(PlayerData.job.grade) == "table" and PlayerData.job.grade.name) or nil,
                -- Tu id de servidor. La central manda la lista de agentes de
                -- servicio con el id de cada uno, y sin este no hay forma de
                -- encontrarte a ti mismo en ella —y por tanto de saber en que
                -- unidad vas ni quien la comparte contigo—.
                serverId = GetPlayerServerId(PlayerId()),
                level = (type(PlayerData.job.grade) == "table" and PlayerData.job.grade.level) or PlayerData.job.grade or 0,
            },
            options = {
                confiscate = Config.Confiscate,
                holster = Config.Holster,
            },
            tabs = FilterQuickAccessTabs('Tabs', PlayerData.job.name),
            objects = FilterQuickAccessTabs('Objects', PlayerData.job.name),
            interactions = FilterQuickAccessTabs('Interactions', PlayerData.job.name),
            holster = FilterQuickAccessTabs('Holster', PlayerData.job.name),
            k9 = FilterQuickAccessTabs('K9', PlayerData.job.name),
            k9Data = dogData or {},
            jobCategories = Config.JobCategory,
            usedColors = exports["origen_police"]:GetUsedColors(),
            codes = GetDynamicRadioCodes and GetDynamicRadioCodes() or nil,
            -- A que apartado va cada codigo. La tabla de la base de datos no
            -- guarda eso, asi que lo dice config/radio_codes.lua.
            codeGroups = Config.RadioCodeGroups,
            -- Como se llama y de que color va la pantalla para esta categoria:
            -- el recurso lo abren cinco, no solo la policia.
            ui = UIDeCategoria and UIDeCategoria() or nil
        })

        -- Repintado de un panel ya abierto o usado como marco para la tablet:
        -- no se toca el foco ni se arranca hilo de controles.
        if sinFoco then return end

        SetNuiFocus(true, Config.Actions.QuickAccessShowCursor)
        StartQuickAccessControls()
        vigilarPintado()
    end

    if lib then
        lib.callback('origen_police:server:k9:GetDogData', false, function(dogData)
            openMenu(dogData)
        end)
        --[[ Sin plazo, un servidor que no contesta dejaba el panel sin abrir
             —y la tablet de marco, que se pinta DENTRO de el, invisible con
             el foco puesto—. Al segundo se abre sin datos del perro. ]]
        SetTimeout(1000, function()
            openMenu({})
        end)
    else
        openMenu({})
    end

    return true
end

RegisterCommand(Config.Commands.QuickAccess.cmd, function(source, args, raw)
    if IsNuiFocused() then return end
    local PlayerData = FW_GetPlayerData(false)
    if not PlayerData or not PlayerData.job or not PlayerData.job.name then return end
    if not CanOpenTablet(PlayerData.job.name)[1] then return end
    if not (PlayerData.job.onduty or onduty) then
        ShowNotification(Config.Translations.NotInDuty or "NO ESTÁS EN SERVICIO", "error")
        return
    end
    if not (PuedePanelPolicia and PuedePanelPolicia()) then return end
    OpenQuickAccessMenu(true)
end)

--- La interfaz avisa de que el menu rapido esta en el DOM. Ver el comentario
--- largo en OpenQuickAccessMenu.
RegisterNUICallback("police:menuPintado", function(_, cb)
    cb('ok')
    MenuRapidoPintado = true
end)

RegisterNUICallback("translationsRecived", function(data, cb)
    translationsRecived = true
    if GetDynamicRadioCodes then
        SendNUIMessage({
            action = "UpdateRadioCodes",
            codes = GetDynamicRadioCodes()
        })
    end
    cb(true)
end)

RegisterKeyMapping(Config.Commands.QuickAccess.cmd, Config.Commands.QuickAccess.description, "keyboard", Config.Commands.QuickAccess.key)

RegisterNUICallback("notification", function(data, cb)
    -- The legacy page posted the text on its own; the Vue MDT posts
    -- { message, type }. Passing the table straight through reached
    -- qbx_core.Notify, which reads `.text` and renders "Placeholder".
    if type(data) == "table" then
        ShowNotification(data.message or data.text or "", data.type)
    else
        ShowNotification(data)
    end
    cb(true)
end)

local LastQuickActionTime = 0

local function GetVehicleAllPlayers(ped, vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end
    if not IsPedInVehicle(ped, vehicle, false) then
        return nil
    end

    local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    local endSeat = math.max(0, maxSeats - 2, maxPassengers - 1)

    local players = {}
    local added = {}

    for seat = -1, endSeat do
        local p = GetPedInVehicleSeat(vehicle, seat)
        if p and p ~= 0 and DoesEntityExist(p) and IsPedAPlayer(p) then
            local playerIndex = NetworkGetPlayerIndexFromPed(p)
            if playerIndex and NetworkIsPlayerActive(playerIndex) then
                local serverId = GetPlayerServerId(playerIndex)
                if serverId and serverId > 0 and not added[serverId] then
                    added[serverId] = true
                    table.insert(players, serverId)
                end
            end
        end
    end

    return #players > 0 and players or nil
end

local GetVehicleFrontPlayers = GetVehicleAllPlayers

RegisterNUICallback("quickaction", function(data, cb)
    local eventName = data.event or data.serverevent
    if eventName then
        if not eventName:find("^origen_police") and not eventName:find("^police_k9") then
            Debuger("Trying to execute event with unknown name: ", eventName)
            return cb(false)
        end

        if (GetGameTimer() - LastQuickActionTime) <= 500 then
            Debuger("Trying too fast with action: ", eventName, ", remaining time: ", GetGameTimer() - LastQuickActionTime)
            return ShowNotification(Config.Translations.CantFast)
        end
        LastQuickActionTime = GetGameTimer()
    end
    if data.action == "ReferenceIcon" then
        local spriteId = tonumber(data.id)
        if spriteId and SetLocalReferenceOverride then
            SetLocalReferenceOverride(spriteId, nil)
        end
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local players = GetVehicleAllPlayers(ped, vehicle)
        
        if players then
            TriggerServerEvent("origen_police:server:updateref", {sprite = spriteId}, players)
        else
            TriggerServerEvent("origen_police:server:updateref", {sprite = spriteId})
        end
    elseif data.action == "ReferenceColor" then
        local colorId = tonumber(data.id)
        if colorId and SetLocalReferenceOverride then
            SetLocalReferenceOverride(nil, colorId)
        end
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local players = GetVehicleAllPlayers(ped, vehicle)
        
        if players then
            TriggerServerEvent("origen_police:server:updateref", {color = colorId}, players)
        else
            TriggerServerEvent("origen_police:server:updateref", {color = colorId})
        end
    elseif data.action == "ToggleReady" then
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local players = GetVehicleAllPlayers(ped, vehicle)
        
        if players then
            TriggerServerEvent("origen_police:server:Ready", Config.PoliceJobName, data.state, players)
        else
            TriggerServerEvent("origen_police:server:Ready", Config.PoliceJobName, data.state)
        end
    elseif data.action == "RadioCalls" then

        Calls(data.id)
    elseif data.command then
        if type(data.command) == "table" then
            for frm, command in pairs(data.command) do
                if frm == Config.Framework then
                    ExecuteCommand(command)
                end
            end
        else
            ExecuteCommand(data.command)
        end
    elseif data.event then
        TriggerEvent(data.event, data.id, data.dir, data.skills)
    elseif data.serverevent then
        TriggerServerEvent(data.serverevent, data.skills or data.id, data.dir)
    end
    cb(true)
end)

RegisterNetEvent('origen_police:client:UpdateK9Appearance', function(data)
    SendNUIMessage({
        action = 'updateStats',
        type = data.type,
        id = data.id,
        drawable = data.drawable,
        maxDrawable = data.maxDrawable,
        texture = data.texture,
        maxTexture = data.maxTexture
    })
end)

-- Variety commands
RegisterCommand("esposarcerca", function()
    local PlayerData = FW_GetPlayerData(false)

    if CanOpenTablet(PlayerData.job.name)[1] then
        if (GetGameTimer() - LastQuickActionTime) <= 500 then
            return ShowNotification(Config.Translations.CantFast)
        end
        LastQuickActionTime = GetGameTimer()
        TriggerEvent("origen_police:client:cuffuncuff")
    end
end, false)

RegisterCommand("escoltarcerca", function()
    local PlayerData = FW_GetPlayerData(false)

    if CanOpenTablet(PlayerData.job.name)[1] then
        if (GetGameTimer() - LastQuickActionTime) <= 500 then
            return ShowNotification(Config.Translations.CantFast)
        end
        LastQuickActionTime = GetGameTimer()
        TriggerEvent("origen_police:client:drag")
    end
end, false)

RegisterCommand("escoltarPolice", function()
    ExecuteCommand("escoltarcerca")
end, false)

--------------------------------------
----------------ESPOSAR---------------
--------------------------------------

local cuffed = false

RegisterNetEvent("origen_police:client:setcuffstate", function(otherid)
    cuffed = not cuffed

    CreateThread(function()
		TriggerServerEvent("origen_police:server:playcuffanim", otherid, cuffed)

		local tgtped = GetPlayerPed(GetPlayerFromServerId(otherid))
		SetEntityCoords(PlayerPedId(), GetEntityCoords(tgtped) + GetEntityForwardVector(tgtped))
		SetEntityHeading(PlayerPedId(), GetEntityHeading(tgtped))

		Wait(5000)

        local ped = PlayerPedId()
        LockInventory(cuffed)

        if cuffed then
            Config.HandCuff.Events.OnCuff()
        else
            Config.HandCuff.Events.OnUncuff()
        end

        while cuffed do
            Config.HandCuff.Events.WhileCuff()

            GiveWeaponToPed(ped, GetHashKey("WEAPON_UNARMED"), 0, false, true)
            
            for _, v in pairs(Config.HandCuff.BlockedInputs) do
                DisableControlAction(0, v, true)
            end

            if not IsEntityPlayingAnim(ped, Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 3) then
                TaskPlayAnim(ped, Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, 8.0, -1, 51, false, false, false)
            end

            Wait(0)
        end
    end)
end)

RegisterNetEvent("origen_police:client:playarrestanim", function(value)
	RequestAnimDict(Config.HandCuff.Anims.Cuffing.dict)
	while not HasAnimDictLoaded(Config.HandCuff.Anims.Cuffing.dict) do
		Wait(1)
	end
	RequestAnimDict(Config.HandCuff.Anims.Uncuffing.dict)
	while not HasAnimDictLoaded(Config.HandCuff.Anims.Uncuffing.dict) do
		Wait(1)
	end

	if value then -- Esposando a alguien
		TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Cuffing.dict, Config.HandCuff.Anims.Cuffing.anim, 8.0, -8.0, 3750 , 2, 0, 0, 0, 0)
	else -- Desesposando a alguien
		TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Uncuffing.dict, Config.HandCuff.Anims.Uncuffing.anim, 8.0, -8.0,-1, 2, 0, 0, 0, 0)
	end
	Wait(3500)
	ClearPedTasks(PlayerPedId())
end)



RegisterNetEvent("origen_police:client:playarrestedanim", function(value, cufferId)
	RequestAnimDict(Config.HandCuff.Anims.BeingCuffed.dict)
	while not HasAnimDictLoaded(Config.HandCuff.Anims.BeingCuffed.dict) do
		Wait(1)
	end
	RequestAnimDict(Config.HandCuff.Anims.BeingUncuffed.dict)
	while not HasAnimDictLoaded(Config.HandCuff.Anims.BeingUncuffed.dict) do
		Wait(1)
	end

    local ped = PlayerPedId()
	if value then -- Siendo esposado
		TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.BeingCuffed.dict, Config.HandCuff.Anims.BeingCuffed.anim, 8.0, -8.0, 3750 , 2, 0, 0, 0, 0)
        if not Config.HandCuff.SkillCheck.enabled then
            Wait(3500)
            local coords = GetEntityCoords(GetPlayerPed(PlayerId()), false)
            QuitarPropEsposasYa(handCuffObject)
            handCuffObject = CreateObject(GetHashKey("p_cs_cuffs_02_s"), coords.x, coords.y, coords.z, true, true, true)
            AttachEntityToEntity(handCuffObject, ped, GetPedBoneIndex(ped, 60309), -0.020, 0.060, 0.03, 290.0, 155.0, 80.0, true, false, false, false, 0, true)
            TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)
            return
        end
        local SkillSuccess = nil
        CreateThread(function()
            SkillSuccess = Config.HandCuff.SkillCheck.func(cufferId)
        end)
		Wait(Config.HandCuff.SkillCheck.WaitChance)
        if not SkillSuccess then
            local coords = GetEntityCoords(GetPlayerPed(PlayerId()), false)
            QuitarPropEsposasYa(handCuffObject)
            handCuffObject = CreateObject(GetHashKey("p_cs_cuffs_02_s"), coords.x, coords.y, coords.z, true, true, true)
            AttachEntityToEntity(handCuffObject, ped, GetPedBoneIndex(ped, 60309), -0.020, 0.060, 0.03, 290.0, 155.0, 80.0, true, false, false, false, 0, true)
            TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)
        else
            cuffed = false
            ClearPedTasks(PlayerPedId())
        end
	else -- Siendo DESesposado
        QuitarPropEsposas(handCuffObject)
        handCuffObject = nil
		TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.BeingUncuffed.dict, Config.HandCuff.Anims.BeingUncuffed.anim, 8.0, -8.0,-1, 2, 0, 0, 0, 0)
		Wait(3500)
		ClearPedTasks(PlayerPedId())
	end
end)

function RemoveHandCuff()
    cuffed = false
    QuitarPropEsposas(handCuffObject)
    handCuffObject = nil
    ClearPedTasks(PlayerPedId())
end

exports("RemoveHandCuff", RemoveHandCuff)

RegisterNetEvent("origen_police:client:AdminUncuff", function()
    cuffed = false
    QuitarPropEsposas(handCuffObject)
    handCuffObject = nil
    ClearPedTasks(PlayerPedId())
    LockInventory(false)
end)

RegisterNetEvent("origen_police:client:AdminCuff", function()
    if cuffed then return end
    cuffed = true
    CreateThread(function()
        local ped = PlayerPedId()
        LockInventory(cuffed)
        ClearPedTasks(ped)

        local coords = GetEntityCoords(ped, false)
        QuitarPropEsposasYa(handCuffObject)
        handCuffObject = CreateObject(GetHashKey("p_cs_cuffs_02_s"), coords.x, coords.y, coords.z, true, true, true)
        AttachEntityToEntity(handCuffObject, ped, GetPedBoneIndex(ped, 60309), -0.020, 0.060, 0.03, 290.0, 155.0, 80.0, true, false, false, false, 0, true)
        
        RequestAnimDict("mp_arresting")
        while not HasAnimDictLoaded("mp_arresting") do
            Wait(10)
        end

        TaskPlayAnim(ped, "mp_arresting", "idle", 8.0, -8.0, -1, 49, 0.0, false, false, false)

        while cuffed do
            GiveWeaponToPed(ped, GetHashKey("WEAPON_UNARMED"), 0, false, true)
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 263, true) -- Melee Attack 1
            DisableControlAction(0, 45, true) -- Reload
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 44, true) -- Cover
            DisableControlAction(0, 37, true) -- Select Weapon

            if not IsEntityPlayingAnim(ped, "mp_arresting", "idle", 3) then
                TaskPlayAnim(ped, "mp_arresting", "idle", 8.0, 8.0, -1, 51, false, false, false)
            end
            Wait(0)
        end
    end)
end)

RegisterNetEvent("origen_police:client:cuffuncuff", function()
    origen_police_cuffuncuff()
end)

function origen_police_cuffuncuff()
    if IsPedInAnyVehicle(PlayerPedId(), false) then return end

    local PlayerData = FW_GetPlayerData(false)
    if not PlayerData or not PlayerData.job or not (PlayerData.job.onduty or onduty) then
        ShowNotification(Config.Translations.NotInDuty or "NO ESTÁS EN SERVICIO", "error")
        return
    end
    
    local player, distance = FW_GetClosestPlayer()
    if player ~= -1 and distance <= 3.0 and distance > 0 then
        if CanHandCuff(player, distance) then
            if not draggin then
                TriggerServerEvent("origen_police:server:cuffuncuffplayer", GetPlayerServerId(player))
            else
                ShowNotification(Config.Translations.CantUncuff, "error")
            end
        else
            ShowNotification(Config.Translations.CantDoThis, 'error')
        end
    else
        ShowNotification(Config.Translations.NoPersonNear, "error")
    end
end


---------------------------------------
----------------ESCOLTAR---------------
---------------------------------------

function origen_police_drag()
    local PlayerData = FW_GetPlayerData(false)
    if not PlayerData or not PlayerData.job or not (PlayerData.job.onduty or onduty) then
        ShowNotification(Config.Translations.NotInDuty or "NO ESTÁS EN SERVICIO", "error")
        return
    end

    local player, distance = FW_GetClosestPlayer()
    if player ~= -1 and distance <= 3.0 and distance > 0 then
		local tgtped = GetPlayerPed(player)

		local state = not IsEntityAttachedToEntity(tgtped, PlayerPedId())

		if (state and IsEntityPlayingAnim(tgtped, Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 3)) or draggin then
			TriggerServerEvent("origen_police:server:dragplayer", GetPlayerServerId(player), state)

			draggin = state and GetPlayerServerId(player) or false

			CreateThread(function()
				RequestAnimDict("amb@world_human_drinking@coffee@male@base")
				while not HasAnimDictLoaded("amb@world_human_drinking@coffee@male@base") do
					Wait(10)
				end

				while draggin and DoesEntityExist(tgtped) and IsPedOnFoot(tgtped) and not IsPedDeadOrDying(tgtped, true) do
					Wait(100)

					if not IsEntityPlayingAnim(PlayerPedId(), "amb@world_human_drinking@coffee@male@base", "base", 3) then
						TaskPlayAnim(PlayerPedId(), "amb@world_human_drinking@coffee@male@base", "base", 8.0, 8.0, -1, 49, false, false, false)
					end
				end
				draggin = false
				ClearPedTasks(PlayerPedId())
			end)
		else
			ShowNotification(Config.Translations.HasToBeCuffed, "error")
		end
	else
		ShowNotification(Config.Translations.NoPersonNear, "error")
	end
end



function origen_police_setdragstate(state, otherid)
    dragged = state

	if dragged then
		local g = false
		local ped = PlayerPedId()
		local target = GetPlayerFromServerId(otherid)
		local tgtped = GetPlayerPed(target)

		AttachEntityToEntity(ped, tgtped, 11816, 0.28, 0.43, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

		CreateThread(function()
			while dragged and DoesEntityExist(tgtped) and IsPedOnFoot(tgtped) and not IsPedDeadOrDying(tgtped, true) do
				Wait(100)
				ped = PlayerPedId()
				tgtped = GetPlayerPed(target)
				if not IsEntityAttachedToEntity(ped, tgtped) then
					AttachEntityToEntity(ped, tgtped, 11816, 0.28, 0.43, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
				end
				if GetEntitySpeed(tgtped) > 0.1 then
					g = true
					TaskGoStraightToCoord(ped, GetEntityCoords(ped) + GetEntityForwardVector(ped) * 5.0, GetEntitySpeed(tgtped) > 2.0 and 2.0 or 1.0, -1, GetEntityHeading(ped), 0.0)
				elseif g then
					g = false
					ClearPedTasks(ped)
				end
			end
			dragged = false
			DetachEntity(PlayerPedId(), true, false)
			ClearPedTasks(ped)
		end)
	else
		DetachEntity(PlayerPedId(), true, false)
	end
end



RegisterNetEvent("origen_police:client:setdragstate", function(state, otherid)
	origen_police_setdragstate(state, otherid)
end)

RegisterNetEvent("origen_police:client:drag", function()
    origen_police_drag()
end)

-----------------------------------------
----------------PUTINOFVEH---------------
-----------------------------------------
function origen_police_vehicleinof()
    local PlayerData = FW_GetPlayerData(false)
    if not PlayerData or not PlayerData.job or not (PlayerData.job.onduty or onduty) then
        ShowNotification(Config.Translations.NotInDuty or "NO ESTÁS EN SERVICIO", "error")
        return
    end

    local player, distance = FW_GetClosestPlayer()
	local veh = FW_GetClosestVehicle()

    if player ~= -1 and distance <= 3.0 and distance > 0 and #(GetEntityCoords(veh) - GetEntityCoords(PlayerPedId())) < 5 then
		if draggin then
			draggin = false
			ClearPedTasks(PlayerPedId())
			TriggerServerEvent("origen_police:server:dragplayer", GetPlayerServerId(player), false)
		end
		if not IsPedInAnyVehicle(GetPlayerPed(player), false) then
			local nseats = GetVehicleModelNumberOfSeats(GetEntityModel(veh)) - 2
			for i = 0, nseats do
				if IsVehicleSeatFree(veh, nseats - i) then
                    UseCommand('me', Config.Translations['VehicleinofME'])
					TriggerServerEvent("origen_police:server:vehicleinof", GetPlayerServerId(player), NetworkGetNetworkIdFromEntity(veh), nseats - i)
					return
				end
			end
			ShowNotification(Config.Translations['noSeat'])
		else
			UseCommand('me', Config.Translations['VehicleofinME'])
			TriggerServerEvent("origen_police:server:vehicleinof", GetPlayerServerId(player))
		end
	else
		ShowNotification(Config.Translations.NoPersonNear)
	end
end




function origen_police_statevehicleinof(vehicle, seat)
	if vehicle then
		TaskWarpPedIntoVehicle(PlayerPedId(), NetworkGetEntityFromNetworkId(vehicle), seat)
	else
		TaskLeaveVehicle(PlayerPedId(), GetVehiclePedIsIn(PlayerPedId(), false), 16)
        if cuffed then
            Wait(100)
            TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, 8.0, -1, 51, false, false, false)
        end
	end
end

-- RegisterCommand("vehicleinof", function()
--     origen_police_vehicleinof()
-- end)

RegisterNetEvent("origen_police:client:vehicleinof", function()
	origen_police_vehicleinof()
end)

RegisterNetEvent("origen_police:client:statevehicleinof", function(vehicle, seat)
    origen_police_statevehicleinof(vehicle, seat)
end)

function SearchClosest()
    local PlayerData = FW_GetPlayerData(false)

    if not CanOpenTablet(PlayerData.job.name)[1] or not (PlayerData.job.onduty or onduty) then return end

    if (GetGameTimer() - LastQuickActionTime) <= 500 then
        return ShowNotification(Config.Translations.CantFast)
    end
    LastQuickActionTime = GetGameTimer()

    local player, distance = FW_GetClosestPlayer()
    if player ~= -1 and distance <= 2.5 and distance > 0 then
        if CanSearchPlayer(player) then
            local playerId = GetPlayerServerId(player)
            SearchClosestPlayer(playerId)
        else
            ShowNotification(Config.Translations.NotCuffed, "error")
        end
    else
        ShowNotification(Config.Translations.NoPersonNear, "error")
    end
end

RegisterCommand("cachearPolice", SearchClosest, false)
RegisterCommand("cachearcerca", SearchClosest, false)

StartSearchDistance = function(id)
    CreateThread(function()
        Wait(500)
        local timeout = 0
        -- Esperar a que el inventario se abra y coja el foco NUI
        while not IsNuiFocused() and timeout < 20 do
            Wait(100)
            timeout = timeout + 1
        end

        while true do
            Wait(500)
            local playerIdx = GetPlayerFromServerId(id)
            if playerIdx == -1 then break end
            
            local ped = GetPlayerPed(playerIdx)
            local coordsPed = GetEntityCoords(ped)
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            if #(coordsPed - playerCoords) > 4.0 then
                TriggerEvent('origen_inventory:client:CloseInventory')
                TriggerEvent('inventory:client:closeInventory')
                ExecuteCommand("closeinv")
                ShowNotification(Config.Translations.PersonFar, "error")
                break
            end
            
            -- Si el jugador ya ha cerrado el inventario manualmente, paramos el bucle
            if not IsNuiFocused() then
                break
            end
        end
    end)
end

exports("IsHandcuffed", function()
    return cuffed
end)

AddReplaceExport("qb-policejob", "IsHandcuffed", function()
    return cuffed
end)

local RequestAnimDict = function(animDict)
    while not HasAnimDictLoaded(animDict) do
        RequestAnimDict(animDict)
        Wait(5)
    end
end

-- Drag people
local function WalkBackwards()
    if isDragging then
        RequestAnimDict("move_strafe@first_person@generic")
        TaskPlayAnim(PlayerPedId(), "move_strafe@first_person@generic", 'walk_bwd_180_loop', 3.0, 1.0, -1, 1, 0, 0, 0, 0)
    end
end

local function StopWalkBackwards()
    if isDragging then
        RequestAnimDict("move_strafe@first_person@generic")
        TaskPlayAnim(PlayerPedId(), "move_strafe@first_person@generic", 'exit', 3.0, 1.0, -1, 1, 0, 0, 0, 0)
    end
end

RegisterNetEvent('origen_police:client:getDragged',function(entToAttach,anim)
    local curAttachedPed = GetPlayerPed(GetPlayerFromServerId(entToAttach))
    local ped = PlayerPedId()
    if anim == 'escort' then
        if not isAttached then
            ClearPedTasks(ped)
            isAttached = true
            RequestAnimDict(Config.HandCuff.Anims.Cuffing.dict)
            RequestAnimDict('move_m@generic_variations@walk')
            TaskPlayAnim(ped, Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, -8, -1, 49, 0.0, false, false, false)
            AttachEntityToEntity(ped,curAttachedPed, 1816,0.25, 0.49, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        else
            isAttached = false
            DetachEntity(ped)
            ClearPedTasks(ped)
        end
    elseif anim == "stopdrag" then
        isAttached = false
        DetachEntity(ped)
        ClearPedTasks(ped)
    else
        if not isAttached then
            isAttached = true
            ClearPedTasks(ped)
            RequestAnimDict('combat@drag_ped@')
            TaskPlayAnim(ped, 'combat@drag_ped@','injured_drag_ped' ,8.0, -8, -1, 5, 0, false, false, false)
            AttachEntityToEntity(ped,curAttachedPed, 1816, 4103, 0.48, 0.0, 0.0, 0.0, 0.0, 0.0)
        else
            isAttached = false
            DetachEntity(ped)
            ClearPedTasks(ped)
        end
    end
end)

RegisterNetEvent('origen_police:client:doAnimation',function(anim)
    local ped = PlayerPedId()
    if anim == 'escort' then
        if isEscorting then
            ClearPedTasks(ped)
            isEscorting = false
        else
            isEscorting = true
            RequestAnimDict('amb@world_human_drinking@coffee@male@base')
            if IsEntityPlayingAnim(ped, 'amb@world_human_drinking@coffee@male@base','base', 3) ~= 1 then
                TaskPlayAnim(ped, 'amb@world_human_drinking@coffee@male@base','base' ,8.0, -8, -1, 51, 0, false, false, false)
            end
        end
    elseif anim == "stopdrag" then
        ClearPedTasks(ped)
    else
        if isDragging then
            ClearPedTasks(ped)
            isDragging = false
        else
            isDragging = true
            RequestAnimDict('combat@drag_ped@')
            if IsEntityPlayingAnim(ped, 'combat@drag_ped@','injured_drag_plyr', 3) ~= 1 then
                TaskPlayAnim(ped, 'combat@drag_ped@','injured_drag_plyr' ,8.0, -8, -1, 51, 0, false, false, false)
            end
        end
    end
end)

RegisterCommand('drag', function()
    local PlayerData = FW_GetPlayerData(false)

    if not CanOpenTablet(PlayerData.job.name)[1] or not PlayerData.job.onduty then return end

    local closestPlayer, closestDistance = FW_GetClosestPlayer()
    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        TriggerServerEvent('origen_police:server:attachPlayer', GetPlayerServerId(closestPlayer), 'drag')
    else
        ShowNotification(Config.Translations.NoPersonNear, 'error')
    end
end, false)

RegisterCommand('+walkBackwards', WalkBackwards, false)
RegisterCommand('-walkBackwards', StopWalkBackwards, false)

RegisterCommand('StopWalkDrag', function()
    if isDragging then
        ClearPedTasks(PlayerPedId())
        isDragging = false
        local closestPlayer, closestDistance = FW_GetClosestPlayer()
        if closestPlayer ~= -1 and closestDistance <= 3.0 then
            TriggerServerEvent('origen_police:server:attachPlayer', GetPlayerServerId(closestPlayer), 'stopdrag')
        end
    end
end, false)

RegisterCommand('toggleduty', function()
    local PlayerData = FW_GetPlayerData(false)
    if not CanOpenTablet(PlayerData.job.name)[1] or not PlayerData.job.onduty then return end
    
    SendNUIMessage({
        action = "ToggleReadyKeybind"
    })
end, false)

-- Variety keymaps
if Config.Commands.HandCuff then
    RegisterKeyMapping("esposarcerca", Config.Commands.HandCuff.description, "keyboard", Config.Commands.HandCuff.key)
end
if Config.Commands.Search then
    RegisterKeyMapping(Config.Commands.Search.cmd or "cachearcerca", Config.Commands.Search.description or "Policía: Cachear", "keyboard", Config.Commands.Search.key or "")
end
if Config.Commands.Escort then
    RegisterKeyMapping(Config.Commands.Escort.cmd or "escoltarcerca", Config.Commands.Escort.description or "Policía: Escoltar", "keyboard", Config.Commands.Escort.key or "")
end
if Config.Commands.QRR then
    RegisterKeyMapping("qrr", Config.Commands.QRR.description, "keyboard", Config.Commands.QRR.key)
end
if Config.Commands.Ten20 then
    RegisterKeyMapping("10-20", Config.Commands.Ten20.description, "keyboard", Config.Commands.Ten20.key)
end
if Config.Commands.Ten13B then
    RegisterKeyMapping("QRR-B", Config.Commands.Ten13B.description, "keyboard", Config.Commands.Ten13B.key)
end
if Config.Commands.Ten13C then
    RegisterKeyMapping("QRR-C", Config.Commands.Ten13C.description, "keyboard", Config.Commands.Ten13C.key)
end
if Config.Commands.Tackle then
    RegisterKeyMapping("placaje", Config.Commands.Tackle.description, "keyboard", Config.Commands.Tackle.key)
end
if Config.Commands.VehicleInto then
    RegisterKeyMapping("vehicleinof", Config.Commands.VehicleInto.description, "keyboard", Config.Commands.VehicleInto.key)
end
if Config.Commands.VehiclePursuit then
    RegisterKeyMapping("254-V", Config.Commands.VehiclePursuit.description, "keyboard", Config.Commands.VehiclePursuit.key)
end
if Config.Commands.ToggleDuty then
    RegisterKeyMapping("toggleduty", Config.Commands.ToggleDuty.description, "keyboard", Config.Commands.ToggleDuty.key)
end
if Config.Commands.CambioJurisdiccion then
    RegisterKeyMapping("cambiojurisdiccion", Config.Commands.CambioJurisdiccion.description, "keyboard", Config.Commands.CambioJurisdiccion.key)
end
RegisterKeyMapping("+walkBackwards", "Policía: andar hacia atrás al escoltar", "keyboard", "S")
RegisterKeyMapping("StopWalkDrag", "Policía: soltar al escoltado", "keyboard", "X")

exports('origenPoliceCuff', origen_police_cuffuncuff)
exports('origenPoliceDrag', origen_police_drag)
exports('origenPoliceVehicleInof', origen_police_vehicleinof)

-- K9 Admin Events
RegisterNetEvent('origen_police:client:k9:GiveXP', function()
    local input = exports['org-input']:ShowInput({
        header = 'Dar XP a K9',
        icon = 'fas fa-star',
        inputs = {
            { name = 'id', text = 'ID del Jugador', type = 'number', isRequired = true, icon = 'fas fa-id-card' },
            { name = 'xp', text = 'Cantidad de XP', type = 'number', isRequired = true, icon = 'fas fa-chart-line' }
        }
    })
 
    if not input or not input.id or not input.xp then return end
    ExecuteCommand(('k9xp %s %s'):format(input.id, input.xp))
end)

RegisterNetEvent('origen_police:client:k9:ResetK9', function()
    local input = exports['org-input']:ShowInput({
        header = 'Reiniciar K9',
        icon = 'fas fa-undo',
        inputs = {
            { name = 'id', text = 'ID del Jugador', type = 'number', isRequired = true, icon = 'fas fa-id-card' }
        }
    })
 
    if not input or not input.id then return end
    
    local confirmMenu = {
        {
            header = '¿Reiniciar todos los datos?',
            icon = 'fas fa-exclamation-triangle',
            txt = 'Esta acción borrará NOMBRE, XP y SKILLS del jugador ' .. input.id,
            isMenuHeader = true
        },
        {
            header = 'Confirmar Reinicio',
            icon = 'fas fa-check-circle',
            params = {
                isAction = true,
                event = function()
                    ExecuteCommand(('k9reset %s'):format(input.id))
                end
            }
        },
        {
            header = 'Cancelar',
            icon = 'fas fa-times-circle',
            params = {
                isAction = true,
                event = function()
                    -- Cerrar
                end
            }
        }
    }
    OpenMenu(confirmMenu)
end)

RegisterNetEvent('origen_police:client:k9:ResetSkills', function()
    local input = exports['org-input']:ShowInput({
        header = 'Reiniciar Especialidades',
        icon = 'fas fa-graduation-cap',
        inputs = {
            { name = 'id', text = 'ID del Jugador', type = 'number', isRequired = true, icon = 'fas fa-id-card' }
        }
    })
 
    if not input or not input.id then return end
    ExecuteCommand(('k9resetskills %s'):format(input.id))
end)

RegisterNetEvent('origen_police:client:k9:ManageItems', function()
    lib.callback('origen_police:server:k9:GetAdminData', false, function(isAdmin, richItems, allowedVehicles)
        if not isAdmin then return end
        
        local menu = {
            {
                header = Config.Translations["ManageItems"],
                icon = 'fas fa-boxes',
                isMenuHeader = true
            },
            {
                header = Config.Translations["Add"],
                icon = 'fas fa-plus-circle',
                txt = "Añadir nuevo item detectable",
                params = {
                    isAction = true,
                    event = function()
                        local input = exports['org-input']:ShowInput({
                            header = Config.Translations["ManageItems"],
                            icon = 'fas fa-boxes',
                            inputs = {
                                {
                                    name = "name",
                                    text = Config.Translations["ItemName"] .. " (spawn code)",
                                    type = "text",
                                    isRequired = true,
                                    icon = 'fas fa-tag'
                                },
                                {
                                    name = "categories",
                                    text = Config.Translations["K9TrainingSection"],
                                    type = "select",
                                    icon = 'fas fa-folder-open',
                                    options = {
                                        { text = Config.Translations["Drugs"], value = "drugs", icon = 'fas fa-pills' },
                                        { text = Config.Translations["Weapons"], value = "weapons", icon = 'fas fa-gun' },
                                        { text = Config.Translations["Money"], value = "money", icon = 'fas fa-money-bill-wave' },
                                        { text = Config.Translations["Explosives"], value = "explosives", icon = 'fas fa-bomb' }
                                    }
                                }
                            }
                        })
                        if input and input.name then
                            TriggerServerEvent('origen_police:server:k9:AddItem', input.name, input.categories or {})
                            Wait(500)
                            TriggerEvent('origen_police:client:k9:ManageItems')
                        end
                    end
                }
            }
        }
        
        for _, item in ipairs(richItems) do
            table.insert(menu, {
            header = item.label,
            icon = 'fas fa-search',
            txt = "Click para eliminar",
                params = {
                    isAction = true,
                    event = function()
                        local confirmMenu = {
                            {
                                header = '¿Eliminar ' .. item.label .. '?',
                                icon = 'fas fa-trash-alt',
                                isMenuHeader = true
                            },
                            {
                                header = 'Confirmar Eliminación',
                                icon = 'fas fa-check-circle',
                                params = {
                                    isAction = true,
                                    event = function()
                                        TriggerServerEvent('origen_police:server:k9:RemoveItem', item.name)
                                        Wait(500)
                                        TriggerEvent('origen_police:client:k9:ManageItems')
                                    end
                                }
                            },
                            {
                                header = 'Cancelar',
                                icon = 'fas fa-times-circle',
                                params = {
                                    isAction = true,
                                    event = function()
                                        TriggerEvent('origen_police:client:k9:ManageItems')
                                    end
                                }
                            }
                        }
                        OpenMenu(confirmMenu)
                    end
                }
            })
        end
        
        OpenMenu(menu)
    end)
end)

RegisterNetEvent('origen_police:client:k9:ManageVehicles', function()
    lib.callback('origen_police:server:k9:GetAdminData', false, function(isAdmin, richItems, allowedVehicles)
        if not isAdmin then return end
        
        local menu = {
            {
                header = Config.Translations["ManageVehicles"],
                icon = 'fas fa-car',
                isMenuHeader = true
            },
            {
                header = Config.Translations["Add"],
                icon = 'fas fa-plus-circle',
                txt = "Añadir nuevo vehículo K9",
                params = {
                    isAction = true,
                    event = function()
                        local input = exports['org-input']:ShowInput({
                            header = Config.Translations["ManageVehicles"],
                            icon = 'fas fa-car',
                            inputs = {
                                {
                                    name = "model",
                                    text = Config.Translations["VehicleModel"] .. " (spawn code)",
                                    type = "text",
                                    isRequired = true,
                                    icon = 'fas fa-shuttle-van'
                                }
                            }
                        })
                        if input and input.model then
                            TriggerServerEvent('origen_police:server:k9:AddVehicle', input.model)
                            Wait(500)
                            TriggerEvent('origen_police:client:k9:ManageVehicles')
                        end
                    end
                }
            }
        }
        
        for _, model in ipairs(allowedVehicles) do
            table.insert(menu, {
                header = model:upper(),
                icon = 'fas fa-car-side',
                txt = "Click para eliminar",
                params = {
                    isAction = true,
                    event = function()
                        local confirmMenu = {
                            {
                                header = '¿Eliminar vehículo ' .. model:upper() .. '?',
                                icon = 'fas fa-trash-alt',
                                isMenuHeader = true
                            },
                            {
                                header = 'Confirmar Eliminación',
                                icon = 'fas fa-check-circle',
                                params = {
                                    isAction = true,
                                    event = function()
                                        TriggerServerEvent('origen_police:server:k9:RemoveVehicle', model)
                                        Wait(500)
                                        TriggerEvent('origen_police:client:k9:ManageVehicles')
                                    end
                                }
                            },
                            {
                                header = 'Cancelar',
                                icon = 'fas fa-times-circle',
                                params = {
                                    isAction = true,
                                    event = function()
                                        TriggerEvent('origen_police:client:k9:ManageVehicles')
                                    end
                                }
                            }
                        }
                        OpenMenu(confirmMenu)
                    end
                }
            })
        end
        
        OpenMenu(menu)
    end)
end)
RegisterNetEvent("origen_police:client:SyncSearchTarget", function(state)
    local ped = PlayerPedId()
    local dict = "handsonhood3@animation"
    local anim = "handsonhood3_clip"
    if state then
        local PlayerData = FW_GetPlayerData()
        local isDead = Entity(ped).state.isDead or Entity(ped).state.inLastStand or IsEntityDead(ped) or IsPedFatallyInjured(ped) or GetEntityHealth(ped) <= 100
        if not isDead and PlayerData and PlayerData.metadata then
            isDead = PlayerData.metadata["isdead"] or PlayerData.metadata["inlaststand"]
        end
        
        -- HANDCUFF CHECK: Don't do the "hands on hood" animation if already cuffed
        local isCuffed = Entity(ped).state.isHandcuffed or IsEntityPlayingAnim(ped, "mp_arresting", "idle", 3)
        if not isCuffed and PlayerData and PlayerData.metadata then
            isCuffed = PlayerData.metadata["ishandcuffed"]
        end

        if isDead or isCuffed then return end
        
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end
        ClearPedTasksImmediately(ped)
        Wait(100)
        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
    else
        if not IsEntityDead(ped) then
            StopAnimTask(ped, dict, anim, 1.0)
            ClearPedTasksImmediately(ped)
        end
    end
end)

-- ─── SAMS Quickmenu Actions Client Sync ────────────────────────
RegisterNetEvent("origen_police:client:syncQuickmenuActions", function(config)
    customQuickmenuActions = config
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    TriggerServerEvent("origen_police:server:requestQuickmenuActionsSync")
end)

RegisterNetEvent("esx:playerLoaded", function(xPlayer)
    TriggerServerEvent("origen_police:server:requestQuickmenuActionsSync")
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent("origen_police:server:requestQuickmenuActionsSync")
end)
