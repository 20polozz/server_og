local OnlineUsers = {}
local isAdmin = false
AdminGroup = nil
local menuOpen = false

--[[ Mientras el panel de admin esta delante, fuera el rastreador de misiones y
     el logo de origen_notify: los dos escuchan la misma señal y el panel les
     cae encima. Es lo que hacen el radial de origen_hud, las animaciones y el
     menu de ropa. Se llama en CADA camino de apertura y de cierre —hay varios,
     incluido el que suelta el foco al quedarse sin panel—, que si se queda
     puesto el rastreador no vuelve hasta reconectar. ]]
local function HudFuera(fuera)
    TriggerEvent('qv2:suppressHud', fuera == true)
end

-- Si el recurso se para con el panel delante, nadie manda el `false`.
AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    HudFuera(false)
end)

local openedFromBusinesses = false
local commandsRegistered = false
local cachedAdminData = nil
local lastCacheTime = 0
local CACHE_DURATION = 30000

local function GetAdminData(forceRefresh)
    local currentTime = GetGameTimer()
    
    if not forceRefresh and cachedAdminData and (currentTime - lastCacheTime) < CACHE_DURATION then
        return cachedAdminData
    end
    
    local data = lib.callback.await('origen_admin:server:getQuickMenuData', false)
    
    if data then
        cachedAdminData = data
        lastCacheTime = currentTime
        OnlineUsers = data.onlineUsers or {}
        isAdmin = true
        AdminGroup = data.adminGroup
    else
        cachedAdminData = nil
        lastCacheTime = 0
        OnlineUsers = {}
        isAdmin = false
        AdminGroup = nil
    end
    
    return data
end

--[[ ── El foco, vigilado ────────────────────────────────────────────────

     Igual que lo hace origen_inventory (client/function.lua, DisableKeys): no
     se confia en SetNuiFocusKeepInput, se apagan los controles a mano mientras
     el panel esta delante.

     KeepInput es un interruptor GLOBAL del cliente, no de este recurso, y se
     queda como lo dejo el ultimo que lo toco. Pedirlo y confiar en el no vale:
     del mismo riel cuelgan cuatro paneles mas y cualquiera puede volver a
     moverlo. Lo que si es nuestro son los controles, y esos se apagan a mano.

     Los dos paneles NO quieren lo mismo:

       - El menu rapido deja andar y hablar mientras lo usas, como el
         inventario: KeepInput encendido y los controles que estorban apagados
         uno a uno. Solo se corta mientras escribes en el buscador, o las
         teclas irian a la vez al texto y al personaje.

       - El panel grande no: es una pantalla completa con formularios por todas
         partes. Ahi KeepInput apagado y no se anda.

     Dos ritmos en un solo hilo:
       - Cada fotograma, los controles. Tiene que ser cada fotograma o se
         cuela el que caiga en el hueco.
       - Cada ~200 ms, el foco. Solo se recupera si NO lo hay, asi que no se
         pelea con nadie que lo tenga legitimamente. ]]
local vigilante = false
local menuRapido = false    -- el panel de delante es el de acciones rapidas
local escribiendo = false   -- el buscador tiene el cursor

--[[ Lo que de verdad para el puñetazo.

     DisableControlAction apaga la TECLA, y el ataque cuerpo a cuerpo entra por
     varios controles segun el arma que lleves, asi que taparlos uno a uno es
     ir adivinando. DisablePlayerFiring corta el disparo y el golpe en la raiz,
     sea cual sea la tecla. Los dos, porque el primero no tapa el raton.

     Lo que NO esta en esta lista es a proposito: andar (30-35), correr y
     hablar. Es lo que se puede seguir haciendo con el menu rapido delante. ]]
local CONTROLES_APAGADOS = {
    -- Camara: es lo que hacia que el raton girase al personaje por detras.
    1, 2,
    -- Cuerpo a cuerpo, los seis: 140 ligero, 141 fuerte, 142 alternativo,
    -- 143 bloqueo, 263 y 264 melee. Faltando uno, el puñetazo vuelve.
    140, 141, 142, 143, 263, 264,
    -- Disparo, apuntado y el raton del vehiculo.
    24, 25, 257, 106,
    -- Rueda y cambio de arma: con el raton encima de la lista, la rueda
    -- scrollea y no deberia cambiarte el arma a la vez.
    14, 15, 16, 17, 261, 262,
    -- Entrar/salir, cobertura, saltar y el resto de lo que estorba.
    18, 22, 23, 26, 44, 45, 68, 69, 70, 80, 91, 92, 286, 287,
    -- Radio de vehiculo y dial de emisoras (Q y controles de radio en vehiculo)
    81, 82, 83, 84, 85, 86,
    -- Escape y la pausa: la tecla la usa el panel para cerrarse, asi que el
    -- juego no debe abrir ademas su menu por detras.
    177, 200, 202,
}

--- El estado que le toca a KeepInput ahora mismo. En un solo sitio, que si no
--- cada uno lo calcula a su manera y se acaban contradiciendo.
local function InputAlJuego()
    return menuRapido and not escribiendo
end

--[[ ── ¿Hay de verdad un panel a la vista? ─────────────────────────────

     VigilarFoco devuelve el raton a este recurso cada 200 ms mientras
     `menuOpen` diga que hay menu. Eso es lo que lo protege de que otro
     recurso le robe el foco, pero tambien era una trampa: si la interfaz se
     escondia por un camino que no ponia `menuOpen` a false —volver del panel
     de un script, pasar del menu rapido al grande y que el servidor no
     conteste—, el foco volvia una y otra vez sin nada delante. Raton en
     pantalla, camara muerta, y sin panel no hay quien escuche el Escape.

     Ahora las dos pantallas dicen cuando se ven y cuando no, y si pasan dos
     segundos con menu "abierto" y ninguna a la vista se suelta todo. Es la
     tercera regla del riel: alguien lo comprueba despues.

     `sabeAvisar`: solo se vigila si la interfaz ha avisado alguna vez. Una
     interfaz compilada antes de esto no avisa nunca, y sin esta guarda se
     cerrarian todos los paneles a los dos segundos. ]]
local aLaVista = { completo = false, rapido = false }
local sabeAvisar = false
local GRACIA_SIN_PANEL = 2000

RegisterNUICallback("PanelALaVista", function(data, cb)
    cb("ok")
    if type(data) ~= 'table' then return end
    if data.panel ~= 'completo' and data.panel ~= 'rapido' then return end
    sabeAvisar = true
    aLaVista[data.panel] = data.visible == true
end)

local function HayPanel()
    return aLaVista.completo or aLaVista.rapido
end

--- `esRapido` dice cual de los dos paneles es el que abre.
local function VigilarFoco(esRapido)
    menuRapido = esRapido == true
    escribiendo = false
    SetNuiFocusKeepInput(InputAlJuego())

    if vigilante then return end
    vigilante = true

    CreateThread(function()
        local desdeElFoco = 0
        -- Desde cuando no hay ninguna pantalla a la vista; nil si la hay.
        local sinPanelDesde = nil

        while menuOpen do
            Wait(0)

            DisablePlayerFiring(PlayerId(), true)
            for i = 1, #CONTROLES_APAGADOS do
                DisableControlAction(0, CONTROLES_APAGADOS[i], true)
            end

            desdeElFoco = desdeElFoco + 1
            if desdeElFoco >= 12 then   -- ~200 ms a 60 fps
                desdeElFoco = 0

                if sabeAvisar and not HayPanel() then
                    sinPanelDesde = sinPanelDesde or GetGameTimer()
                else
                    sinPanelDesde = nil
                end

                -- Menu "abierto" y nada en pantalla: se suelta y se deja de vigilar.
                if sinPanelDesde and GetGameTimer() - sinPanelDesde > GRACIA_SIN_PANEL then
                    menuOpen = false
                    HudFuera(false)
                    -- Menos si el aviso de devolucion sigue delante: es suyo.
                    if not devolucionAbierta then
                        SetNuiFocus(false, false)
                    end
                    SetNuiFocusKeepInput(false)
                    break
                end

                if not IsNuiFocused() then
                    SetNuiFocus(true, true)
                end
                SetNuiFocusKeepInput(InputAlJuego())
            end
        end

        menuRapido = false
        escribiendo = false
        vigilante = false
    end)
end

--[[ Si el vigilante comun (@origen_map/shared/foco.lua) suelta el raton porque
     la pantalla no enseña nada, el menu deja de contar como abierto: si no,
     VigilarFoco lo volveria a coger en 200 ms y el siguiente HOME creeria que
     el menu rapido sigue delante. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        menuOpen = false
        HudFuera(false)
        --[[ Y la pantalla fuera. Con `soltarraton` (o una pagina colgada que
             vuelve) el panel seguia pintado: sin raton, sin ESC que le
             llegara y con Lua dandolo por cerrado (27/09, visto en el juego:
             el menu rapido delante de todo tras soltar el raton). ]]
        SendNUIMessage({ action = "closeQuickMenuLua" })
        SendNUIMessage({ action = "closeAdminPanel" })
    end)
end

--[[ El buscador del menu rapido avisa cuando coge y cuando suelta el cursor.
     Mientras escribes no puede irse tambien al juego: la W del texto seria un
     paso adelante. Al salir del campo se vuelve a poder andar. ]]
RegisterNUICallback("QuickMenuEscribiendo", function(data, cb)
    cb("ok")
    escribiendo = data and data.state == true
    SetNuiFocusKeepInput(InputAlJuego())
end)

RegisterNetEvent("origen_admin:client:removeAdminGroup", function()
    AdminGroup = nil
    cachedAdminData = nil
    lastCacheTime = 0
end)

RegisterNetEvent("origen_admin:client:refreshAdminCache", function()
    cachedAdminData = nil
    lastCacheTime = 0
end)

-- ========================================
-- QUICK MENU (HOME KEY) & FULL ADMIN PANEL
-- ========================================

local ultimoClickAdmin = 0
local timerAperturaAdmin = nil

--[[ Que panel de script se abrio el ultimo DESDE la pestaña Scripts, para
     saber de donde se vuelve. Lo pone OpenScriptPanel (mas abajo) y se borra
     al volver o en cuanto el admin se abre por cualquier otro camino: asi un
     panel abierto luego con su comando no «vuelve» a un admin del que no
     salio. ]]
local LastScriptPanel = nil

local function AbrirMenuLateral(data)
    SetNuiFocus(true, true)
    LastScriptPanel = nil
    menuOpen = true
    HudFuera(true)
    VigilarFoco(true)
    RegisterAdminCommands()
    
    SendNUIMessage({
        action = "openQuickMenu",
        lang = Config.Language,
        permissions = data.permissions,
        binds = GetKeyBinds(),
        isDuty = data.isDuty
    })
end

local function AbrirMenuCompleto(data)
    if not data or data.isDuty ~= true then return false end
    SetNuiFocus(true, true)
    LastScriptPanel = nil
    SetNuiFocusKeepInput(false)
    menuOpen = true
    HudFuera(true)
    VigilarFoco(false)
    RegisterAdminCommands()
    
    SendNUIMessage({
        action = "openAdminPanelNew",
        lang = Config.Language,
        permissions = data.permissions,
        isDuty = data.isDuty
    })
    return true
end

local function ProcesarAperturaAdmin()
    local ahora = GetGameTimer()
    local diferencia = ahora - ultimoClickAdmin

    -- Si se pulsa dos veces seguidas (en menos de 350 ms)
    if diferencia < 350 and timerAperturaAdmin then
        -- Cancelar la apertura del lateral para que no llegue a mostrarse
        timerAperturaAdmin = nil
        ultimoClickAdmin = 0
        
        local data = GetAdminData(true)
        if not data then return end
        if not data.isDuty then
            AbrirMenuLateral(data)
            return
        end
        
        AbrirMenuCompleto(data)
        return
    end

    -- Si el menú rápido ya está abierto en pantalla y se vuelve a pulsar el botón
    if menuOpen and menuRapido then
        local data = GetAdminData(true)
        if not data then return end
        if data.isDuty then AbrirMenuCompleto(data) end
        return
    end

    -- Si el menú completo ya está abierto, no hacer nada
    if menuOpen and not menuRapido then
        return
    end

    -- Primer clic: esperamos 280 ms antes de abrir el lateral por si el usuario pulsa dos veces
    ultimoClickAdmin = ahora
    local idTimer = ahora
    timerAperturaAdmin = idTimer

    SetTimeout(280, function()
        if timerAperturaAdmin == idTimer then
            timerAperturaAdmin = nil
            local data = GetAdminData(true)
            if not data then return end
            AbrirMenuLateral(data)
        end
    end)
end

if Config.Commands.AdminMenu and Config.Commands.AdminMenu.cmd and Config.Commands.AdminMenu.cmd ~= '' then
    RegisterCommand(Config.Commands.AdminMenu.cmd, function(source)
        ProcesarAperturaAdmin()
    end)

    if Config.Commands.AdminMenu.key and Config.Commands.AdminMenu.key ~= '' then
        RegisterKeyMapping(Config.Commands.AdminMenu.cmd, "Admin: abrir el menú rápido", 'keyboard', Config.Commands.AdminMenu.key)
    end
end

RegisterNetEvent("origen_admin:client:openQuickMenu", function(onlineUsers, admGroup, serverPerms, isDuty)
    SetNuiFocus(true, true)
    LastScriptPanel = nil
    local onDuty = isDuty == true
    OnlineUsers = onDuty and (onlineUsers or {}) or {}
    isAdmin = true
    AdminGroup = admGroup
    menuOpen = true
    HudFuera(true)
    VigilarFoco(true)
    RegisterAdminCommands()
    
    cachedAdminData = {
        onlineUsers = OnlineUsers,
        adminGroup = admGroup,
        permissions = onDuty and (serverPerms or {}) or {},
        isDuty = onDuty
    }
    lastCacheTime = GetGameTimer()
    
    local perms = onDuty and (serverPerms or Config.Permissions[AdminGroup] or {"all"}) or {}
    SendNUIMessage({
        action = "openQuickMenu",
        lang = Config.Language,
        permissions = perms,
        binds = GetKeyBinds(),
        isDuty = onDuty
    })
end)

RegisterNUICallback("closeAdminMenu", function(data, cb)
    -- Con el aviso de devolucion delante el raton es suyo: soltarlo aqui lo
    -- dejaba pintado sin poder pulsar Aceptar (devoluciones.lua).
    if devolucionAbierta then
        SetNuiFocus(true, true)
    else
        SetNuiFocus(false, false)
    end
    menuOpen = false
    HudFuera(false)
    timerAperturaAdmin = nil
    ultimoClickAdmin = 0
    cb("ok")
    -- Igual que closeAdminPanelNew: si no, la marca se quedaba puesta y el
    -- siguiente cierre le devolvia el foco a businesses sin venir de alli.
    if openedFromBusinesses then
        openedFromBusinesses = false
        TriggerEvent('origen_businesses:client:restoreFocus')
    end
end)

--[[ Los avisos del panel (algo que no se ha podido hacer: despedir de un
     negocio, abrir un script parado). Antes los pintaba la propia interfaz en
     su esquina; ahora van por origen_notify, como el resto del servidor. ]]
local TIPOS_AVISO = { success = true, error = true, warning = true, info = true }

RegisterNUICallback("Aviso", function(data, cb)
    cb("ok")
    if type(data) ~= "table" then return end
    local tipo = TIPOS_AVISO[data.type] and data.type or "info"
    local texto = tostring(data.message or "")
    if texto == "" then return end
    ShowNotification(texto:sub(1, 300), tipo, 4000)
end)

RegisterNUICallback("DisableMove", function(data, cb)
    cb("ok")

    --[[ Lo llama la interfaz al abrir un dialogo (state = true) y al cerrarlo
         (state = false). El `not data.state` a secas dejaba KeepInput ENCENDIDO
         al cerrar cualquier dialogo, aunque el panel siguiera abierto, y como
         KeepInput es global se quedaba asi.

         Con un dialogo delante no hay input para el juego, se abra donde se
         abra. Al cerrarlo se vuelve a lo que toque segun el panel: andar si es
         el menu rapido, quieto si es el grande. Sin panel, lo que pida. ]]
    if data.state then
        SetNuiFocusKeepInput(false)
    elseif menuOpen then
        SetNuiFocusKeepInput(InputAlJuego())
    else
        -- Sin panel no hay pantalla a la que dejar pasar el teclado.
        SetNuiFocusKeepInput(false)
    end
end)

-- ========================================
-- NUEVO PANEL DE ADMIN
-- ========================================

RegisterNetEvent("origen_admin:client:openNewAdminPanel", function(onlineUsers, admGroup, serverPerms, isDuty)
    if isDuty ~= true then return end
    -- El foco es solo del panel, como arriba: KeepInput es global y se
    -- hereda encendido del inventario si no se dice que no.
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    OnlineUsers = onlineUsers or {}
    LastScriptPanel = nil
    isAdmin = true
    AdminGroup = admGroup
    menuOpen = true
    HudFuera(true)
    VigilarFoco(false)
    
    cachedAdminData = {
        onlineUsers = onlineUsers,
        adminGroup = admGroup,
        permissions = serverPerms,
        isDuty = isDuty
    }
    lastCacheTime = GetGameTimer()
    
    local perms = serverPerms or Config.Permissions[AdminGroup] or {"AdminMenu"}
    SendNUIMessage({
        action = "openAdminPanelNew",
        lang = Config.Language,
        permissions = perms,
        isDuty = isDuty
    })
end)

RegisterNUICallback("closeAdminPanelNew", function(data, cb)
    menuOpen = false
    HudFuera(false)
    timerAperturaAdmin = nil
    ultimoClickAdmin = 0
    cb("ok")
    -- Con el aviso de devolucion delante el raton sigue siendo suyo.
    if devolucionAbierta then
        SetNuiFocus(true, true)
    else
        SetNuiFocus(false, false)
    end
    if openedFromBusinesses then
        openedFromBusinesses = false
        TriggerEvent('origen_businesses:client:restoreFocus')
    end
end)

RegisterNUICallback("openFullPanelFromQuickMenu", function(data, cb)
    cb("ok")

    local adminData = GetAdminData(true)
    if not adminData or not adminData.isDuty then
        -- El menu rapido ya se ha escondido y el grande no va a venir: con
        -- `menuOpen` puesto, VigilarFoco devolveria el raton sin nada delante.
        if adminData then
            AbrirMenuLateral(adminData)
        else
            menuOpen = false
            HudFuera(false)
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
        end
        return
    end
    
    -- El foco es solo del panel, como arriba: KeepInput es global y se
    -- hereda encendido del inventario si no se dice que no.
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    menuOpen = true
    HudFuera(true)
    VigilarFoco(false)
    
    SendNUIMessage({
        action = "openAdminPanelNew",
        lang = Config.Language,
        permissions = adminData.permissions,
        isDuty = adminData.isDuty
    })
end)

--[[ Reducir: del panel completo se vuelve a las acciones rápidas, que es de
     donde salió. Es el camino de vuelta de openFullPanelFromQuickMenu, y lo
     abre con AbrirMenuLateral para no repetir aquí el foco, el vigilante y los
     comandos: esa función ya deja `menuRapido` puesto, que es lo que decide si
     el teclado sigue llegando al juego. ]]
RegisterNUICallback("volverAAccionesRapidas", function(data, cb)
    cb("ok")

    local adminData = GetAdminData(true)
    if not adminData then
        -- El panel grande ya se ha escondido y el rápido no va a venir: con
        -- `menuOpen` puesto, VigilarFoco devolvería el ratón sin nada delante.
        menuOpen = false
        HudFuera(false)
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        return
    end

    AbrirMenuLateral(adminData)
end)

RegisterNUICallback("ToggleAdminDuty", function(data, cb)
    if type(data) ~= 'table' or type(data.state) ~= 'boolean' then
        cb({ success = false })
        return
    end

    local result = lib.callback.await('origen_admin:server:toggleAdminDuty', false, data.state)
    if type(result) ~= 'table' or result.success ~= true then
        cb(type(result) == 'table' and result or { success = false })
        return
    end

    cachedAdminData = {
        onlineUsers = result.onlineUsers or {},
        adminGroup = result.adminGroup,
        permissions = result.permissions or {},
        isDuty = result.isDuty == true
    }
    lastCacheTime = GetGameTimer()
    OnlineUsers = cachedAdminData.onlineUsers
    AdminGroup = cachedAdminData.adminGroup
    isAdmin = true
    cb(result)
end)

RegisterNetEvent('origen_admin:client:adminDutyRevoked', function()
    TriggerEvent('chat:removeSuggestion', '/sc')
    cachedAdminData = nil
    lastCacheTime = 0
    if not menuOpen then return end

    local data = GetAdminData(true)
    if not data then
        SendNUIMessage({ action = menuRapido and 'closeQuickMenuLua' or 'closeAdminPanel' })
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        menuOpen = false
        HudFuera(false)
        return
    end

    SendNUIMessage({
        action = 'adminDutyChanged',
        isDuty = data.isDuty,
        permissions = data.permissions
    })
end)

RegisterNetEvent('origen_admin:client:clearAdminEffects', function()
    if NoclipActivo and NoclipActivo() then ToggleNoClip() end
    if EstadoGodmode == true then
        EstadoGodmode = false
        SetPlayerInvincible(PlayerId(), false)
    end

    local ped = PlayerPedId()
    if isVanish == true then
        isVanish = false
        SetEntityVisible(ped, true)
    end
    if BlipsActivos and BlipsActivos() then ToggleBlips() end
    if PlayerTags == true then ToggleTags() end
    if LaserActivo and LaserActivo() then ToggleLaser() end
end)

-- Callback para obtener posiciones de jugadores para el mapa
RegisterNUICallback("GetPlayerPositions", function(data, cb)
    FW_TriggerCallback('origen_admin:server:getPlayerPositions', function(players)
        cb(players)
    end)
end)

-- Callback para obtener estadísticas del servidor
RegisterNUICallback("GetServerStats", function(data, cb)
    FW_TriggerCallback('origen_admin:server:GetServerStats', function(stats)
        cb(stats)
    end)
end)

-- Callback para cambiar el rango de admin de un jugador
RegisterNUICallback("SetPlayerGroupAdmin", function(data, cb)
    FW_TriggerCallback('origen_admin:server:SetPlayerGroupAdmin', function(result)
        cb(result)
    end, data)
end)

-- Callback para obtener detalles completos de un jugador
RegisterNUICallback("GetPlayerDetails", function(data, cb)
    FW_TriggerCallback('origen_admin:server:GetPlayerDetails', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback("GetPlayerVehiclesAdmin", function(data, cb)
    FW_TriggerCallback('origen_admin:server:GetPlayerVehiclesAdmin', function(result)
        cb(result or {})
    end, data)
end)

RegisterNUICallback("GiveVehicleToPlayer", function(data, cb)
    FW_TriggerCallback('origen_admin:server:GiveVehicleToPlayer', function(result)
        cb(result or { success = false, message = 'Error de servidor.' })
    end, data)
end)

RegisterNUICallback("GetAdminGarageOptions", function(_, cb)
    FW_TriggerCallback('origen_admin:server:GetAdminGarageOptions', function(result)
        cb(result or {})
    end)
end)

RegisterNUICallback("DeletePlayerVehicle", function(data, cb)
    FW_TriggerCallback('origen_admin:server:DeletePlayerVehicle', function(result)
        cb(result or { success = false, message = 'Error de servidor.' })
    end, data)
end)

RegisterNUICallback("UpdateVehicleState", function(data, cb)
    FW_TriggerCallback('origen_admin:server:UpdateVehicleState', function(result)
        cb(result or { success = false, message = 'Error de servidor.' })
    end, data)
end)

RegisterNUICallback("TransferPlayerVehicleGarage", function(data, cb)
    FW_TriggerCallback('origen_admin:server:TransferPlayerVehicleGarage', function(result)
        cb(result or { success = false, message = 'Error de servidor.' })
    end, data)
end)

RegisterNUICallback("GetPlayerCharacterSlots", function(data, cb)
    FW_TriggerCallback('origen_admin:server:GetPlayerCharacterSlots', function(result)
        cb(result or {})
    end, data)
end)

RegisterNUICallback("GetPlayerSlotsPanelData", function(data, cb)
    FW_TriggerCallback('origen_admin:server:GetPlayerSlotsPanelData', function(result)
        cb(result or { slots = 1, defaultSlots = 1, maxSlots = 5, characters = {} })
    end, data)
end)

RegisterNUICallback("AdjustPlayerSlots", function(data, cb)
    FW_TriggerCallback('origen_admin:server:AdjustPlayerSlots', function(result)
        cb(result or { success = false, message = 'Error de servidor.' })
    end, data)
end)

RegisterNUICallback("CKPlayerBySlot", function(data, cb)
    TriggerServerEvent('origen_admin:server:ckPlayerBySlot', data.license, data.slotCid, data.targetId)
    cb({ success = true })
end)

-- Callback para actualizar datos de un jugador
RegisterNUICallback("UpdatePlayerData", function(data, cb)
    FW_TriggerCallback('origen_admin:server:UpdatePlayerData', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback("GetOnlinePlayers", function(data, cb)
    local currentTime = GetGameTimer()
    
    if cachedAdminData and (currentTime - lastCacheTime) < CACHE_DURATION then
        cb(cachedAdminData.onlineUsers or {})
    else
        local adminData = GetAdminData(true)
        cb(adminData and adminData.onlineUsers or {})
    end
end)

RegisterNUICallback("GetOfflinePlayers", function(data, cb)
    FW_TriggerCallback('origen_admin:server:getOfflinePlayers', function(result)
        cb(result)
    end)
end)

--[[ Estado real de los interruptores.

     El menu de acciones rapidas los pinta encendidos o apagados, y esa marca
     tiene que salir del juego y no de lo que la interfaz recuerde haber
     pulsado: godmode se puede activar por comando, y al reiniciar el recurso
     la interfaz no sabe nada. ]]
RegisterNUICallback("EstadosRapidos", function(_, cb)
    local ped = PlayerPedId()
    local estados = {
        noclip    = NoclipActivo and NoclipActivo() or false,
        -- Se miran los dos: la variable propia por si el native miente, y el
        -- native por si la invencibilidad la puso otro script.
        godmode   = EstadoGodmode == true or GetPlayerInvincible(PlayerId()) == true,
        invisible = not (IsEntityVisible(ped) == 1 or IsEntityVisible(ped) == true),
        blips     = BlipsActivos and BlipsActivos() or false,
        tags      = PlayerTags == true,
        laser     = LaserActivo and LaserActivo() or false,
    }

    cb(estados)
end)

RegisterNUICallback("FastAction", function(data, cb)
    if FastActions[data.action] then
        if not HasPermission(FastActions[data.action][2]) then
            return
        end
        FastActions[data.action][1](data, cb)
        return
    end

    cb("ok")
end)

--[[ Las acciones globales del pie del panel (Revivir todos, Limpiar...). La
     interfaz las mandaba como GlobalAdminAction y nadie lo escuchaba: los
     botones no hacian nada (visto el 07/10). Cada una es la rapida de
     siempre, con su permiso; Limpiar area es nueva y va al servidor. ]]
local GLOBALES = {
    reviveAll = 'reviveall',
    clearVehicles = 'deleteVeh',
    clearPeds = 'deletePeds',
    announce = 'announce',
}

RegisterNUICallback("GlobalAdminAction", function(data, cb)
    cb("ok")
    local accion = type(data) == 'table' and data.action or nil
    if accion == 'clearArea' then
        if HasPermission('AdminMenu:DeleteObjects') then
            TriggerServerEvent('origen_admin:server:clearArea')
        end
        return
    end
    local rapida = FastActions[GLOBALES[accion] or '']
    if not rapida or not HasPermission(rapida[2]) then return end
    rapida[1]({ data = data.data }, function() end)
end)

RegisterNUICallback("UserAction", function(data, cb)
    if UserActions[data.action] then
        UserActions[data.action](data, cb)
        return
    end

    cb("ok")
end)

RegisterNUICallback("AdminAction", function(data, cb)
    local action = data.action
    local targetId = tonumber(data.targetId)
    
    if action == "kick" or action == "ban" then
        -- Logic handled in UI (opening tab or modal) or distinct callback
    end

    if UserActions[action] then
        UserActions[action]({
            source = targetId, 
            citizenid = data.citizenid,
            license = data.license,
            data = data.data
        }, cb)
        return
    end

    cb("ok")
end)

RegisterNUICallback("GetPlayerSanctions", function(data, cb)
    FW_TriggerCallback('origen_admin:server:GetPlayerSanctions', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback("BanPlayer", function(data, cb)
    TriggerServerEvent('origen_admin:server:BanPlayer', data.targetId, data.time, data.reason, data.license, data.playerName)
    cb("ok")
end)

RegisterNUICallback("KickPlayer", function(data, cb)
    TriggerServerEvent('origen_admin:server:KickPlayer', data.targetId, data.reason)
    cb("ok")
end)

RegisterNUICallback("AddWarn", function(data, cb)
    local target = data.targetId or data.citizenid
    TriggerServerEvent('origen_admin:server:addWarn', target, 'warn', data.reason)
    cb("ok")
end)

RegisterNUICallback("RemoveSanction", function(data, cb)
    local target = data.targetId or data.citizenid
    TriggerServerEvent('origen_admin:server:removeWarn', target, data.id)
    cb("ok")
end)

RegisterNUICallback("UnbanPlayer", function(data, cb)
    TriggerServerEvent('origen_admin:server:UnbanPlayer', data.license)
    cb("ok")
end)

RegisterNUICallback("GetAdminGroups", function(data, cb)
    local retval = {}
    if data.user then -- Include user permission
        retval[1] = Config.UserPermission
    end
    for k, v in pairs(Config.PermissionList) do
        retval[#retval+1] = v
    end
    cb(retval)
end)

local finalJobs = nil

RegisterNUICallback("GetJobs", function(data, cb)
    if not finalJobs then
        FW_TriggerCallback("origen_admin:server:GetBusiness", function(bus)
            local jobs = {}
            for k, v in pairs(Framework.Shared.Jobs) do 
                jobs[k] = {name = k, label = v.label}
            end
            for k, v in pairs(bus) do 
                jobs[k] = {name = k, label = k.."(Business)"}
            end
            finalJobs = jobs
        end)
    end
    while not finalJobs do
        Citizen.Wait(0)
    end
    cb(finalJobs)
end)

local Gangs = nil

RegisterNUICallback("GetGangs", function(data, cb)
    if not Gangs then
        if GetResourceState("origen_ilegalv2") ~= "started" then 
            Gangs = Framework.Shared.Gangs or {}
            return cb(Gangs)
        end
        FW_TriggerCallback("origen_admin:server:GetGangs", function(gangs)
            Gangs = gangs or {}
            cb(Gangs)
        end)
    else
        cb(Gangs)
    end
end)

RegisterNUICallback("GetItems", function(data, cb)
    local retval = {}
    for k,v in pairs(Framework.Shared.Items) do
        retval[v.name or k] = v.label
    end
    cb(retval)
end)

RegisterNUICallback("GetHouses", function(data, cb)
    cb(Config.Houses)
end)

function RegisterAdminCommands()
    if commandsRegistered then return end
    commandsRegistered = true
    for k, v in pairs(FastActions) do
        if v[3] then
            goto skip_command
        end
        local commandName = k
        if k == 'blips' then commandName = 'ablips' end
        RegisterCommand(commandName, function(source, args, raw)
            if not HasPermission(v[2]) then
                return
            end
            v[1]({}, function() end)
        end, false)
        ::skip_command::
    end
end

RegisterNetEvent("origen_admin:client:notification", function(msg)
    ShowNotification(msg)
end)

RegisterNUICallback("StartCall", function(data, cb)
    TriggerServerEvent("origen_admin:server:RequestCall", data.targetId)
    cb("ok")
end)

RegisterNUICallback("EndCall", function(data, cb)
    TriggerServerEvent("origen_admin:server:EndCall", data.targetId)
    cb("ok")
end)

RegisterNUICallback("HoldTalk", function(data, cb)
    if data.pressed then
        ExecuteCommand("+radiotalk")
    else
        ExecuteCommand("-radiotalk")
    end
    cb("ok")
end)

RegisterNetEvent("origen_admin:client:CallRequested", function(targetId)
    SendNUIMessage({
        action = "callRequested",
        targetId = targetId
    })
end)

RegisterNetEvent("origen_admin:client:CallStarted", function(targetId, participants)
    SendNUIMessage({
        action = "callStarted",
        targetId = targetId,
        participants = participants
    })
end)

RegisterNetEvent("origen_admin:client:CallEnded", function()
    SendNUIMessage({
        action = "callEnded"
    })
end)

-- ========================================
-- SCRIPTS (antes origen_hub)
-- ========================================

-- `LastScriptPanel` (que panel de script se abrio el ultimo) esta declarado
-- arriba, junto al menu rapido, porque lo borran las aperturas del admin.

RegisterNUICallback("GetScriptsList", function(data, cb)
    FW_TriggerCallback('origen_admin:server:GetScriptsList', function(result)
        cb(result or { scripts = {} })
    end, data)
end)

--- Abre el panel de administracion de otro recurso.
---
--- Los paneles de cada script son NUIs de su propio recurso y van a pantalla
--- completa, asi que hay que soltar el foco del admin ANTES de llamarlos: si
--- no, quedan dos interfaces peleandose por el raton y no responde ninguna.
RegisterNUICallback("OpenScriptPanel", function(data, cb)
    local recurso = data and data.resourceName
    -- «recurso#panel»: una tarjeta que abre un panel concreto de un recurso con más de una (config/scripts.lua: panel)
    local panel
    if type(recurso) == 'string' and recurso:find('#', 1, true) then
        recurso, panel = recurso:match('^([^#]+)#(.+)$')
    end

    if not recurso or GetResourceState(recurso) ~= 'started' then
        cb({ ok = false, motivo = 'no-arrancado' })
        return
    end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeAdminPanel" })
    menuOpen = false
    HudFuera(false)

    -- Un respiro antes de abrir el otro panel: sin el, la transicion parpadea
    -- porque el admin todavia no ha terminado de cerrarse.
    Wait(60)

    -- Apuntado ANTES de abrir: hay paneles que, si el servidor les niega el
    -- permiso, piden volver desde dentro de su openManagement.
    LastScriptPanel = recurso

    -- Con pcall: si el recurso no expone openManagement no se puede tumbar el
    -- panel entero por eso, se avisa y ya.
    local ok = pcall(function()
        exports[recurso]:openManagement(panel)
    end)

    if not ok then
        LastScriptPanel = nil
        cb({ ok = false, motivo = 'sin-export' })
        return
    end

    cb({ ok = true })
end)

--- Volver al panel de admin desde el panel de un script.
---
--- Lo llaman los recursos que antes volvian al hub (origen_fuel,
--- origen_housing, origen_garages...). Reabre el admin directamente en la
--- pestaña de scripts, que es de donde saliste.
---
--- Solo vuelve si el panel que lo pide se abrio desde la pestaña Scripts
--- (`LastScriptPanel`). Todos los paneles lo llaman al cerrarse con ESC; el
--- que se abrio con su comando, desde el riel o desde un punto del mapa no
--- viene del admin, y ahi ESC solo cierra. Devuelve true si ha vuelto.
local function ReturnToScripts()
    local quien = GetInvokingResource()
    if quien and quien ~= GetCurrentResourceName() and LastScriptPanel ~= quien then
        return false
    end

    LastScriptPanel = nil

    local adminData = GetAdminData(true)
    if not adminData then return false end

    -- El foco es solo del panel, como arriba: KeepInput es global y se
    -- hereda encendido del inventario si no se dice que no.
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    menuOpen = true
    HudFuera(true)
    VigilarFoco(false)

    SendNUIMessage({
        action = "openAdminPanelNew",
        lang = Config.Language,
        permissions = adminData.permissions,
        isDuty = adminData.isDuty,
        tab = 'scripts'
    })

    return true
end

exports('ReturnToScripts', ReturnToScripts)

--- ¿El panel de este recurso se abrio desde la pestaña Scripts? Para el que
--- necesite saberlo ANTES de cerrar (elegir entre cerrar a secas y volver).
--- Sin argumento, pregunta por el recurso que llama.
exports('VieneDeScripts', function(recurso)
    recurso = recurso or GetInvokingResource()
    return LastScriptPanel ~= nil and LastScriptPanel == recurso
end)

--- Reabrir el panel completo en una pestaña. Lo usa la repeticion de la
--- pestaña Espectar: al salir del clip se vuelve a donde estabas.
function AbrirPanelAdminEn(tab)
    local adminData = GetAdminData(true)
    if not adminData then return end

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    menuOpen = true
    HudFuera(true)
    VigilarFoco(false)

    SendNUIMessage({
        action = "openAdminPanelNew",
        lang = Config.Language,
        permissions = adminData.permissions,
        isDuty = adminData.isDuty,
        tab = tab
    })
end

RegisterNUICallback("GetPlayerDimension", function(data, cb)
    FW_TriggerCallback('origen_admin:server:GetPlayerDimension', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback("SetPlayerDimension", function(data, cb)
    FW_TriggerCallback('origen_admin:server:SetPlayerDimension', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback("GetPlayerBusinesses", function(data, cb)
    FW_TriggerCallback('origen_admin:server:GetPlayerBusinesses', function(result)
        cb(result or {})
    end, data)
end)

RegisterNUICallback("FirePlayerFromBusiness", function(data, cb)
    FW_TriggerCallback('origen_admin:server:FirePlayerFromBusiness', function(result)
        cb(result or { success = false, message = 'Error de servidor.' })
    end, data)
end)

RegisterNUICallback("GetPlayerTattoos", function(data, cb)
    FW_TriggerCallback('origen_admin:server:getPlayerTattoos', function(result)
        cb(result or {})
    end, data)
end)

RegisterNUICallback("RemovePlayerTattoo", function(data, cb)
    FW_TriggerCallback('origen_admin:server:removePlayerTattoo', function(result)
        cb(result or { success = false, message = 'Error de servidor.' })
    end, data)
end)

exports("openManagement", function(selectedPlayer, fromBusinesses)
    local adminData = GetAdminData(true)
    if not adminData then return end
    -- Detras de la comprobacion: si no se abre, el siguiente cierre no debe
    -- devolver el foco a businesses.
    openedFromBusinesses = fromBusinesses == true

    -- El foco es solo del panel, como arriba: KeepInput es global y se
    -- hereda encendido del inventario si no se dice que no.
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    menuOpen = true
    HudFuera(true)
    VigilarFoco(false)
    
    SendNUIMessage({
        action = "openAdminPanelNew",
        lang = Config.Language,
        permissions = adminData.permissions,
        isDuty = adminData.isDuty,
        selectedPlayer = selectedPlayer
    })
end)

--[[ ── El riel del inventario, tambien aqui ─────────────────────────────

     Al entrar en este menu desde el riel del inventario te quedabas encerrado:
     el riel desaparecia y no habia forma de volver a Personaje o a Vehiculo
     sin cerrar y reabrir el inventario a mano.

     La lista de botones NO se escribe aqui. La da origen_inventory, que es
     quien sabe si estas en un coche, si tienes banda o si estas de servicio.
     Tres copias de la misma lista se separarian a la primera. ]]
RegisterNUICallback("GetRielInventario", function(_, cb)
    if GetResourceState('origen_inventory') ~= 'started' then return cb({}) end
    local ok, riel = pcall(function()
        return exports['origen_inventory']:GetRiel('admin')
    end)
    cb(ok and riel or {})
end)

--[[ Para que el inventario pueda comprobar, tras pasarle el relevo, que este
     panel llego a abrirse de verdad. Si no, se quedaria con el foco puesto y
     ninguna pantalla delante. ]]
exports('EstaAbierto', function()
    return menuOpen
end)

--[[ El panel completo, directamente, sin pasar por el lateral.

     Lo usa el radial de origen_hud: un toque en Admin abre las acciones
     rapidas (el comando de siempre) y mantenerlo pulsado abre esto. Por el
     comando solo se llega con un doble toque en menos de 350 ms, y fingir ese
     doble toque desde fuera seria atarse a un tiempo que puede cambiar.

     El permiso se comprueba aqui y los datos los da el servidor, que vuelve a
     mirarlo: que el radial pinte el boton no prueba nada. En un hilo propio
     porque GetAdminData espera al servidor. ]]
exports('AbrirPanelCompleto', function()
    CreateThread(function()
        if not exports['origen_admin']:HasPermission('AdminMenu') then return end
        if menuOpen and not menuRapido then return end   -- ya esta delante

        local data = GetAdminData(false)
        if not data then return end
        AbrirMenuCompleto(data)
    end)
end)

RegisterNUICallback("IrDelRiel", function(data, cb)
    cb('ok')

    local destino = data and data.id
    if destino == 'admin' then return end   -- ya estas aqui

    --[[ La interfaz ya se ha escondido al pulsar: si no hay inventario al que
         saltar, se suelta todo aqui en vez de volver sin mas, o VigilarFoco
         seguiria cogiendo el raton sin nada delante (16/09). ]]
    if GetResourceState('origen_inventory') ~= 'started' then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        menuOpen = false
        HudFuera(false)
        return
    end

    --[[ El panel de destino se abre PRIMERO y este se retira despues. Los dos
         pintan el mismo riel en el mismo sitio, asi que solapandolos el canto
         derecho no llega a parpadear: solo cambia la columna de la izquierda.
         Antes se soltaba el foco y se esperaba 150 ms, y en ese hueco no habia
         nada en pantalla.

         El foco NO se suelta aqui: ya lo ha cogido el panel nuevo al abrirse. ]]
    if destino ~= 'inventory' and destino ~= 'personal' and destino ~= 'vehicle' and destino ~= 'keys'
        and destino ~= 'city' and destino ~= 'quests' and destino ~= 'settings' then
        --[[ Los accesos van por AbrirAcceso, que cierra antes de abrir porque
             no hay forma de confirmar que el suyo se abrio. Ahi si hace falta
             soltar el foco y quitar este panel primero.

             A los 200 y no a los 150: la columna tarda 260 ms en recogerse,
             asi que abriendo a mitad del recorrido el panel que entra empieza
             a deslizarse mientras este acaba de salir. El `true` es el aviso
             de RELEVO: el que entra pinta su riel ya puesto en vez de
             deslizarlo, porque el de aqui sigue ahi hasta desmontarse. ]]
        SetNuiFocus(false, false)
        menuOpen = false
        HudFuera(false)
        CreateThread(function()
            Wait(200)
            exports['origen_inventory']:AbrirAcceso(destino, true)
        end)
        return
    end

    --[[ EL FOCO SE SUELTA TAMBIEN AQUI.

         Antes no: se daba por hecho que lo cogeria el inventario al abrirse.
         Pero el inventario puede NEGARSE a abrir --Bridge.CanOpen() dice que
         no si estas ocupado, herido o esposado-- y entonces no lo coge nadie:
         este panel ya se ha ido, el otro no ha venido, y el foco se queda
         puesto con el raton en pantalla y nada que pulsar.

         Lo que cuesta soltarlo es que el cursor parpadee 200 ms. Lo que
         evita es quedarse sin camara. ]]
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    menuOpen = false
    HudFuera(false)

    exports['origen_inventory']:AbrirEnPestana(destino, true)
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('origen_admin:server:syncChatSuggestion')
end)
