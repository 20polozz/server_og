InPause = false
local propEntity = nil
local isAdmin = nil
local cachedInsuranceTypes = {}
local cachedLicenseTypes = {}

function FetchInitialData()
    if not isAdmin and not Config.IgnoreSettings then
        FW_TriggerCallback("origen_police:server:getAdminState", function(result)
            isAdmin = result
        end)
    end
    FW_TriggerCallback("origen_police:police:GetInsuranceTypes", function(result)
        cachedInsuranceTypes = result or {}
    end)
    FW_TriggerCallback("origen_police:police:GetLicenseTypes", function(result)
        cachedLicenseTypes = result or {}
    end)
    TriggerServerEvent("origen_police:server:requestLicensesSync")
end

RegisterNetEvent("origen_police:client:syncInsuranceTypes", function(types)
    cachedInsuranceTypes = types or {}
    if InPause then
        SendNUIMessage({
            action = "UpdateInsurances",
            insurances = cachedInsuranceTypes
        })
    end
end)

RegisterNetEvent("origen_police:client:syncLicenseTypes", function(types)
    cachedLicenseTypes = types or {}
    if InPause then
        SendNUIMessage({
            action = "UpdateLicensesTypes",
            licenses = cachedLicenseTypes
        })
    end
end)

RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
    FetchInitialData()
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if FW_GetPlayerData(false) then
            FetchInitialData()
        end
    end
end)

RegisterNetEvent("origen_police:client:OpenPoliceCad", function()
    local PlayerData = FW_GetPlayerData(false)
    if PlayerData == nil or PlayerData.job == nil or PlayerData.job.name == nil then return end
    if not CanOpenTablet(PlayerData.job.name)[1] then return FW_Notify(Config.Translations.CantUseItem)  end
    if not InPause then
        --[[ El riel de la derecha va SIEMPRE con la tablet.

             Es la misma barra que comparten los once menus del servidor, y la
             pinta el menu rapido, no la tablet. Llegando desde el panel ya
             estaba puesta; abriendo por el comando, por la tecla o por el item
             la pantalla salia descolgada, sin manera de saltar a otro menu.

             Asi que si el panel no esta delante se abre AQUI de marco y la
             tablet entra dentro, que es exactamente el mismo camino que hace
             el boton del panel. `TabletDesdeElMenu` se queda a false: el
             marco lo hemos puesto nosotros y hay que quitarlo al cerrar.

             Si el jugador no puede abrir el panel --no esta fichado, no le
             toca-- OpenQuickAccessMenu devuelve false y la tablet se abre como
             siempre, sin riel: mas vale sin barra que sin tablet. ]]
        MarcoDeLaTablet = false
        if not MenuRapidoAbierto and OpenQuickAccessMenu then
            MarcoDeLaTablet = OpenQuickAccessMenu(true, true) ~= false
        end
        TogglePause(true)
    end
end)

RegisterNUICallback("close", function(data, cb)
    if InPause then
        TogglePause(false)
    elseif not MenuRapidoAbierto then
        --[[ El Escape de la MDT escucha en window aunque la tablet este cerrada
             (MdtView va con v-show), asi que llega aqui desde cualquier pantalla
             de policia. Con la tablet cerrada, un foco de este recurso sin nada
             delante no lo suelta nadie mas: el Escape es la salida. La placa, la
             foto y el radar ya sueltan el suyo con su propio Escape; el menu
             rapido cierra con animacion y avisa por `focus`, no se le pisa. ]]
        SetNuiFocus(false, false)
    end
    cb(true)
end)

--[[ Quitar de delante el panel de policia (y la tablet, si iba dentro) desde
     Lua: cuando algo que tapa la pantalla —la camara de fotos, una
     repeticion, el alijo de un informe— se lo lleva, o cuando la red del raton
     suelta el foco a la fuerza.

     El ORDEN importa: las banderas del panel se apagan ANTES de cerrar la
     tablet. Si no, TogglePause(false) cree que el panel sigue detras y le
     devuelve el foco (SetNuiFocus(true, ...) + StartQuickAccessControls): el
     raton vuelve a quedar preso justo al rescatarlo.

     Seguro de llamar sin nada abierto: no hace nada. ]]
function CerrarPanelPolicia()
    local habiaPanel = MenuRapidoAbierto
    MarcoDeLaTablet = false
    TabletDesdeElMenu = false
    MenuRapidoAbierto = false
    if InPause then
        TogglePause(false)
    elseif habiaPanel then
        SetNuiFocus(false, false)
        TriggerEvent('qv2:suppressHud', false)
    end
    if habiaPanel then
        SendNUIMessage({ action = 'CloseQuickAccess' })
    end
end

--[[ Quitar la tablet de delante para algo que necesita la pantalla y el
     raton entero —la camara de fotos, una repeticion, un alijo—. Con la
     tablet DENTRO del panel, TogglePause(false) a secas le devolvia el foco
     al panel en mitad de la camara (que ya no recibia teclas: ni foto ni
     salida). Asi que el panel se va con ella, por el mismo camino que al
     saltar por el riel. Devuelve si habia panel, para VolverALaTablet. ]]
function ApartarTablet()
    local conPanel = MenuRapidoAbierto == true
    if conPanel then
        CerrarPanelPolicia()
    elseif InPause then
        TogglePause(false)
    end
    return conPanel
end

--- Volver a la tablet despues de ApartarTablet: con panel, por el camino de
--- siempre (la tablet dentro del panel, con el riel); sin el, como estaba.
function VolverALaTablet(conPanel)
    if conPanel then
        TriggerEvent('origen_police:client:OpenPoliceCad')
    else
        TogglePause(true)
    end
end

--[[ Una capa suelta (la placa, la foto, mover el radar) se cierra y devuelve
     el raton a quien lo tuviera debajo: a la tablet no se le toca (lo tiene
     ella), al panel F7 se le devuelve —soltarlo dejaba el panel a la vista
     sin cursor— y si no hay nada debajo, se suelta. ]]
function DevolverFocoTrasCapa()
    if InPause then return end
    if MenuRapidoAbierto then
        SetNuiFocus(true, Config.Actions.QuickAccessShowCursor)
        if StartQuickAccessControls then StartQuickAccessControls() end
    else
        SetNuiFocus(false, false)
    end
end

if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        CerrarPanelPolicia()
    end)
end


--- Cada apertura de la tablet sube este numero: la respuesta de
--- SyncPermissions o el plazo de una apertura anterior lo ven cambiado y no
--- hacen nada.
local vueltaTablet = 0
--- La tablet de esta vuelta llego a mandarse y a coger el foco.
local tabletLista = false
local PLAZO_TABLET = 5000

function TogglePause(value)
    local PlayerData = FW_GetPlayerData(false)
    --[[ Sin datos del jugador no se ABRE, pero cerrar se cierra siempre: antes
         este return tambien se comia el TogglePause(false) y dejaba InPause
         en true con su hilo bloqueando todos los controles. ]]
    local cerrando = value == false or (value == nil and InPause)
    if not cerrando and (PlayerData == nil or PlayerData.job == nil or PlayerData.job.name == nil) then return end
    if isAdmin == nil and not Config.IgnoreSettings then
        FW_TriggerCallback("origen_police:server:getAdminState", function(result)
            isAdmin = result
        end)
    end
    if value ~= nil then
        InPause = value
    else
        InPause = not InPause
    end
    SetNuiFocusKeepInput(false)
    DisableAllControlActions(0)
    Wait(1)
    if InPause then
        vueltaTablet = vueltaTablet + 1
        local mia = vueltaTablet
        tabletLista = false

        --[[ La tablet se pinta cuando contesta SyncPermissions. Si no contesta
             —el servidor tarda, el callback se pierde— InPause se quedaba en
             true sin tablet delante: todos los controles bloqueados y ni
             siquiera foco que soltar. A los 5 s sin tablet, se cierra. ]]
        SetTimeout(PLAZO_TABLET, function()
            if InPause and vueltaTablet == mia and not tabletLista then
                print('^1[origen_police]^0 La tablet no llego a abrirse en 5 s. Se cierra para no dejar los controles bloqueados.')
                TogglePause(false)
            end
        end)

        --[[ Antes aqui se apagaba el HUD de avisos (ToggleAlerts(false)) y al
             cerrar la tablet se quedaba apagado aunque estuviera abierto antes.
             No hace falta: con la tablet delante la interfaz no lo pinta, y
             al cerrarla se le repite como tiene que quedar
             (ReenviarVistaDispatch, mas abajo). ]]

        CreateThread(function()
            while InPause do
                DisableAllControlActions(0)
                EnableControlAction(0, 249, true)
                EnableControlAction(1, 249, true)
                EnableControlAction(2, 249, true)
                Wait(0)
            end
            while IsControlPressed(0, 200) or IsDisabledControlPressed(0, 200) do
                Wait(0)
                DisableControlAction(0, 200, true)
            end
            DisableControlAction(0, 200, true)
        end)

        RequestAnimDict('amb@code_human_in_bus_passenger_idles@female@tablet@idle_a')
        while not HasAnimDictLoaded('amb@code_human_in_bus_passenger_idles@female@tablet@idle_a') do
            Wait(500)
        end
        -- Cerrada mientras cargaba la animacion: ni prop ni tablet.
        if not InPause or vueltaTablet ~= mia then return end

        local prop = "prop_cs_tablet"
        if not IsPedInAnyVehicle(PlayerPedId()) then
            TaskPlayAnim(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 2.0, 3.0, -1, 51, 0, false, false, false)
            propEntity = CreateObject(GetHashKey(prop), 0, 0, 0, true, true, true)
            AttachEntityToEntity(propEntity, PlayerPedId() ,GetPedBoneIndex(PlayerPedId(), 28422), -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, 0, true, true, true)
        end

        local player = exports["origen_police"]:FW_GetPlayerData(false)
        local playerMetadata = exports["origen_police"]:FW_GetPlayerData(true).metadata or {}
        if not Config.Translations then Config.Translations = Translations end
        if not Config.Translations.PoliceLicenses and Translations and Translations.PoliceLicenses then
            Config.Translations.PoliceLicenses = Translations.PoliceLicenses
        end
        
        -- Fetch insurance types if empty, but don't block
        if #cachedInsuranceTypes == 0 then
            FW_TriggerCallback("origen_police:police:GetInsuranceTypes", function(result)
                cachedInsuranceTypes = result or {}
                -- Send an update to NUI if the tablet is still open
                if InPause then
                    SendNUIMessage({
                        action = "UpdateInsurances",
                        insurances = cachedInsuranceTypes
                    })
                end
            end)
        end

        -- Fetch license types if empty, but don't block
        if #cachedLicenseTypes == 0 then
            FW_TriggerCallback("origen_police:police:GetLicenseTypes", function(result)
                cachedLicenseTypes = result or {}
                -- Send an update to NUI if the tablet is still open
                if InPause then
                    SendNUIMessage({
                        action = "UpdateLicensesTypes",
                        licenses = cachedLicenseTypes
                    })
                end
            end)
        end

        FW_TriggerCallback("origen_police:server:SyncPermissions", function(serverPerms, serverDivs, serverLics)
            --[[ Cerrada (Escape, plazo, red del raton) o vuelta a abrir antes
                 de que contestara el servidor: esta respuesta ya no manda. Sin
                 esto cogia el foco para una tablet que nadie veia. ]]
            if not InPause or vueltaTablet ~= mia then return end
            tabletLista = true
            if serverPerms then Config.Permissions = serverPerms end
            if serverDivs and type(serverDivs) == "table" and next(serverDivs) ~= nil then
                if not Config.Translations then Config.Translations = {} end
                Config.Translations.DivisionsData = serverDivs
                if Translations then Translations.DivisionsData = serverDivs end
            end
            if serverLics and type(serverLics) == "table" and next(serverLics) ~= nil then
                if not Config.Translations then Config.Translations = {} end
                Config.Translations.PoliceLicenses = serverLics
                if Translations then Translations.PoliceLicenses = serverLics end
            end
            
            local openData = {
                open = true,
                --[[ La tablet va DENTRO del panel: `dentro` le dice a la
                     interfaz que se pinte en la columna del menu rapido en vez
                     de a pantalla completa, y `marco` que ese panel lo hemos
                     abierto nosotros solo para tener el riel --asi, al cerrar
                     la tablet, se cierra tambien y se vuelve al juego en vez
                     de quedarse el panel de policia delante--. ]]
                dentro = MenuRapidoAbierto == true,
                marco = MarcoDeLaTablet == true,
                translations = Config.Translations,
                policeConfig = Config.PoliceConfig,
                permissions = serverPerms or exports["origen_police"]:GetPermissions(),
                isAdmin = isAdmin,
                jobData = {
                duty = player.job.onduty,
                name = player.job.name,
                level = (type(player.job.grade) == "table" and player.job.grade.level) or player.job.grade or 0,
                isboss = player.job.isboss or false,
                category = exports["origen_police"]:GetPlayerJobCategory(),
                divisions = (playerMetadata and playerMetadata.divisions) or (player and player.metadata and player.metadata.divisions) or {},
                citizenid = player.citizenid,
                gradeLabel = (type(player.job.grade) == "table" and (player.job.grade.label or player.job.grade.name)) or player.job.grade_label or "",
                badge = playerMetadata.police_badge or "",
                firstname = player.charinfo and player.charinfo.firstname or "",
                lastname = player.charinfo and player.charinfo.lastname or ""
            },
            jobCategories = Config.JobCategory,
            insurances = cachedInsuranceTypes,
            licensesTypes = cachedLicenseTypes,
            options = {
                GuideBtn = Config.ShowGuideButton
            }
        }
        SendNUIMessage(openData)
        openData.permissions = nil -- Remove after the nui message to not print all the permissions
        openData.translations = nil -- Remove after the nui message to not print all the translations
        Debuger("Open cad data: ", json.encode(openData, {indent = true}))

        TriggerServerEvent('origen_police:server:tabletOpened')
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(Config.KeepInputOnTablet)
        --[[ El seguimiento de misiones ocupa el mismo canto que la tablet y se
             le veia por debajo. Se esconde mientras esta delante, con el mismo
             evento local que usa el radial de origen_hud. ]]
        TriggerEvent('qv2:suppressHud', true)
    end)
    else
        TriggerServerEvent('origen_police:server:tabletClosed')
        TriggerEvent('origen_police:client:tabletClosed')
        if StopCurrentCam then StopCurrentCam() end
        if propEntity ~= nil then
            ClearPedSecondaryTask(PlayerPedId())
            DetachEntity(propEntity, false, false)
            DeleteEntity(propEntity)
        end
        SendNUIMessage({
            open = false,
            action = "close"
        })
        -- La interfaz esconde el HUD al cerrar: se le dice como debe quedar.
        if ReenviarVistaDispatch then ReenviarVistaDispatch() end
        --[[ ── Quien se queda con la pantalla ───────────────────────────────

             Si el panel de policia sigue delante, la tablet iba DENTRO de el:
             el panel no se ha ido a ninguna parte y el foco es suyo. Soltarlo
             aqui dejaria el panel a la vista y el raton fuera, y devolver el
             seguimiento de misiones lo haria asomar por encima.

             Sin panel —la tablet abierta por el item o por el comando— se
             cierra como siempre: fuera el foco y vuelven las misiones. ]]
        TabletDesdeElMenu = false

        --[[ Y si el panel lo habiamos puesto NOSOTROS, solo para tener el
             riel, se va con la tablet: quedarse el panel de policia delante
             despues de cerrar la tablet con el Escape no es lo que pide nadie.
             La interfaz ya lo esconde al recibir `open: false`; aqui se apaga
             la bandera para que el foco se suelte como en el caso de siempre. ]]
        if MarcoDeLaTablet then
            MarcoDeLaTablet = false
            MenuRapidoAbierto = false
        end

        if not MenuRapidoAbierto then
            SetNuiFocus(false, false)
            TriggerEvent('qv2:suppressHud', false)
        else
            SetNuiFocus(true, Config.Actions.QuickAccessShowCursor)
            if StartQuickAccessControls then
                StartQuickAccessControls()
            end
        end
    end
end

RegisterNUICallback("ExecuteCommand", function(data, cb)
    ExecuteCommand(data.command)
    cb(true)
end)

RegisterNUICallback("SetWaypointinCoords", function(data, cb)
    SetNewWaypoint(data.x, data.y)
    if data and (data.code or data.id) then
        TriggerEvent("origen_police:client:SetAlertaMarcadaCode", data.code or data.id)
    end
    cb(true)
end)

RegisterNUICallback("GetClosestPlayers", function(data, cb)
    local myServerId = GetPlayerServerId(PlayerId())
    local players = exports["origen_police"]:FW_GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), 10)
    local list = {}
    for i = 1, #players do
        local sid = GetPlayerServerId(players[i])
        if sid and sid ~= myServerId then
            table.insert(list, sid)
        end
    end
    exports["origen_police"]:FW_TriggerCallback("origen_police:server:GetClosestPlayers", function(result)
        cb(result)
    end, list, data)
end)

RegisterNUICallback("GetCoords", function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    cb({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = GetEntityHeading(PlayerPedId())
    })
end)

exports("SendNUIMessage", SendNUIMessage)
exports("TogglePause", TogglePause)
exports("InTablet", function()
    return InPause
end)

RegisterNUICallback('showGameMenu', function(data, cb)
	ActivateFrontendMenu(GetHashKey(data.menu),0,-1)
    cb(true)
end)

-- ─── Robos: polling, confirmación y denegación desde NUI ──────
RegisterNUICallback('pollActiveRobberies', function(data, cb)
    FW_TriggerCallback('origen_police:server:pollActiveRobberies', function(result)
        cb(result or { requests = {} })
    end)
end)

RegisterNUICallback('confirmRobbery', function(data, cb)
    TriggerServerEvent('origen_police:server:confirmRobbery', { id = tonumber(data.id) })
    cb('ok')
end)

RegisterNUICallback('denyRobbery', function(data, cb)
    TriggerServerEvent('origen_police:server:denyRobbery', { id = tonumber(data.id) })
    cb('ok')
end)

RegisterNUICallback('robberyTabletOpened', function(data, cb)
    TriggerServerEvent('origen_police:server:tabletOpened')
    cb('ok')
end)

RegisterNetEvent("origen_police:client:agentDataUpdated", function(data)
    SendNUIMessage({
        action = "agentDataUpdated",
        data = data
    })
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        if propEntity then
            DeleteEntity(propEntity)
        end
    end
end)

if Config.Commands.OpenPoliceCad.cmd then
    RegisterCommand(Config.Commands.OpenPoliceCad.cmd, function(source, args)
        TriggerEvent('origen_police:client:OpenPoliceCad')
    end)

    RegisterKeyMapping(Config.Commands.OpenPoliceCad.cmd, Config.Commands.OpenPoliceCad.description, 'keyboard', Config.Commands.OpenPoliceCad.key)
end

exports('openCad', function()
    TriggerEvent('origen_police:client:OpenPoliceCad')
end)

exports('OpenCad', function()
    TriggerEvent('origen_police:client:OpenPoliceCad')
end)

exports('TogglePause', TogglePause)