local isQuickMenuOpen = false

--- Que la interfaz ha confirmado que su panel esta pintado de verdad. Ver el
--- comentario largo en OpenEmbeddedQuickMenu.
local nuiPintada = false
local currentQuickMenuOptions = {}
local currentQuickMenuMap = {}

--- Las opciones del selector que se pinta DENTRO del panel de banda (asiento
--- al meter en el coche, pasajero al sacar). Van aparte de
--- currentQuickMenuMap porque ahi siguen los botones del propio panel.
--- Ver ElegirEnPanel.
local eleccionMap = {}

--- El panel de banda abierto deja andar (KeepInput). Los menus incrustados no.
local panelAndando = false

--- Hay un campo de texto del panel con el foco: mientras, KeepInput apagado
--- para que escribir "wasd" en un nombre no eche a andar al personaje.
local escribiendo = false

--- El cuadro de la caja que hay que abrir en cuanto el panel tenga sus datos
--- ('in' o 'out'), o nil. Lo apunta AbrirCajaDeBanda; ver alli el porque.
local cajaPendiente = nil

local dbg = Debug:new({ enabled = Config.Debug })

local FaToIconifyMap = {
    ['fa-solid fa-bolt'] = 'mdi:flash',
    ['fa-solid fa-circle-stop'] = 'mdi:stop-circle-outline',
    ['fa-solid fa-circle-play'] = 'mdi:play-circle-outline',
    ['fa-solid fa-location-dot'] = 'mdi:map-marker',
    ['fa-solid fa-magnifying-glass'] = 'mdi:magnify',
    ['fa-solid fa-handcuffs'] = 'mdi:handcuffs',
    ['fa-solid fa-shoe-prints'] = 'mdi:shoe-print',
    ['fa-solid fa-car-side'] = 'mdi:car-side',
    ['fa-solid fa-person-walking-arrow-right'] = 'mdi:walk',
    ['fa-solid fa-car'] = 'mdi:car',
    ['fa-solid fa-chair'] = 'mdi:seat',
    ['fa-solid fa-user-minus'] = 'mdi:account-remove',
    ['fa-solid fa-user'] = 'mdi:account',
    ['fa-solid fa-syringe'] = 'mdi:needle',
    ['fa-solid fa-hand-holding-dollar'] = 'mdi:cash',
    ['fa-solid fa-xmark'] = 'mdi:close'
}

local function NormalizeMenuIcon(icon)
    if type(icon) ~= 'string' or icon == '' then
        return 'mdi:chevron-right'
    end

    if FaToIconifyMap[icon] then
        return FaToIconifyMap[icon]
    end

    if string.find(icon, ' ') then
        return 'mdi:chevron-right'
    end

    return icon
end

local function TriggerMenuOption(option)
    if not option or option.isMenuHeader then return end

    local params = option.params or {}
    local eventName = params.event
    if not eventName or eventName == '' then return end

    local args = params.args
    if params.isServer then
        if args ~= nil then
            TriggerServerEvent(eventName, args)
        else
            TriggerServerEvent(eventName)
        end
        return
    end

    if args ~= nil then
        TriggerEvent(eventName, args)
    else
        TriggerEvent(eventName)
    end
end

local function BuildNuiQuickMenuPayload(menuOptions)
    local title = 'Menú'
    local subtitle = nil
    local titleIcon = 'mdi:menu'
    local actions = {}

    for idx, option in ipairs(menuOptions or {}) do
        if option.isMenuHeader then
            title = option.header or title
            subtitle = option.txt or subtitle
            titleIcon = NormalizeMenuIcon(option.icon)
        else
            local actionId = ('menu_opt_%s'):format(idx)
            currentQuickMenuMap[actionId] = option
            actions[#actions + 1] = {
                id = actionId,
                label = option.header or ('Opción %s'):format(idx),
                description = option.txt or '',
                icon = NormalizeMenuIcon(option.icon),
                disabled = option.disabled == true,
                -- Las que no tienen vuelta atras nacen ya marcadas en rojo,
                -- no solo al pasar el raton por encima.
                peligro = option.peligro == true,
            }
        end
    end

    return {
        title = title,
        subtitle = subtitle,
        icon = titleIcon,
        actions = actions
    }
end

local function HasPermission(permission)
    if not playerGang then
        dbg:warning('[QuickMenu] No playerGang')
        return false
    end

    if playerGang.is_leader then
        dbg:info('[QuickMenu] Player is leader, granting permission:', permission)
        return true
    end

    if not playerGang.ranks then
        dbg:warning('[QuickMenu] No ranks in playerGang')
        return false
    end

    if not playerGang.member then
        dbg:warning('[QuickMenu] No member data in playerGang')
        return false
    end

    local playerRankId = playerGang.member.rank_id or playerGang.member.rank
    dbg:info('[QuickMenu] Player rank ID:', playerRankId)
    dbg:info('[QuickMenu] Member data:', json.encode(playerGang.member))

    if not playerRankId then
        dbg:warning('[QuickMenu] No rank_id found in member')
        return false
    end

    local playerRank = playerGang.ranks[tostring(playerRankId)] or playerGang.ranks[playerRankId]

    if not playerRank then
        dbg:warning('[QuickMenu] Player rank not found for ID:', playerRankId)
        return false
    end

    if not playerRank.permissions then
        dbg:warning('[QuickMenu] No permissions in rank')
        return false
    end

    dbg:info('[QuickMenu] Checking permission:', permission, '=', playerRank.permissions[permission])
    return playerRank.permissions[permission] == true
end

if QuickMenuRadio and QuickMenuRadio.Init then
    QuickMenuRadio.Init({
        isQuickMenuOpen = function()
            return isQuickMenuOpen
        end,
        hasPermission = HasPermission,
        getPlayerGang = function()
            return playerGang
        end,
        sendNuiMessage = function(payload)
            SendNUIMessage(payload)
        end,
    })
end

--[[ ¿Este menu lleva el riel del inventario?

     Solo el menu de banda entero, el que se abre desde el riel del inventario.
     Esta misma NUI la usan los menus incrustados de la venta de droga, y ahi
     un riel para saltar al inventario no pinta nada: estas a mitad de una
     interaccion, no navegando. ]]
local conRiel = false

--[[ Que la proxima apertura viene de OTRO panel del riel.

     Los siete paneles del riel pintan la misma barra del canto, identica y en
     el mismo sitio. En un relevo esa barra no tiene por que moverse: la de
     aqui aparece ya puesta encima de la que se esta yendo, y lo unico que se
     desliza es la columna. Si las dos se deslizaran, durante el cruce se
     verian dos barras moviendose una sobre otra.

     Se apunta y no se pasa por argumento porque este menu se abre por comando
     --`quickmenu`--, y un comando no admite argumentos. Vale para UNA
     apertura: se apaga al usarla, que si se quedara puesto la siguiente
     entrada normal saldria sin animacion sin que nadie sepa por que. ]]
local relevoEntrante = false

exports('MarcarRelevo', function() relevoEntrante = true end)

--[[ Para que el inventario pueda comprobar, tras pasarle el relevo, que este
     panel llego a abrirse de verdad. Si no, se quedaria con el foco de la NUI
     puesto y ninguna pantalla delante: el raton en medio y la camara sin
     responder. Ver VigilarRelevo en origen_inventory. ]]
exports('EstaAbierto', function()
    return isQuickMenuOpen == true
end)

--[[ ── Los datos del cuadro de mando ───────────────────────────────────────

     Lo que se pinta encima de las acciones: quien eres, como va la banda, los
     conectados, el territorio, la caja y el registro.

     Casi nada de esto lo sabe el cliente. `playerGang` trae el nombre, el
     nivel y el dinero, pero no el porcentaje de cada territorio ni lo que hay
     en el alijo ni los ultimos movimientos, y menos aun donde esta cada
     compañero. Asi que se pide al servidor de una sola vez, al abrir.

     Lo que SI se resuelve aqui es lo que solo sabe el cliente: la zona en la
     que esta cada miembro y si el vehiculo en el que va es coche o moto. El
     servidor manda coordenadas y el modelo, y aqui se traducen. ]]

--- Coche o moto. La clase del vehiculo solo se puede preguntar en el cliente.
local function EsMoto(modelo)
    if not modelo or modelo == 0 then return false end
    local clase = GetVehicleClassFromName(modelo)
    -- 8 son las motos y 13 las bicis. Para lo que aqui importa —que se mueve
    -- rapido y a la intemperie— son lo mismo.
    return clase == 8 or clase == 13
end

--- En que anda cada uno, en una palabra.
local function EstadoDe(m)
    if m.muerto then return 'muerta' end
    if m.herido then return 'herida' end
    if m.modelo and m.modelo ~= 0 then
        return EsMoto(m.modelo) and 'moto' or 'coche'
    end
    return 'pie'
end

--[[ Los conectados, ordenados por cercania.

     El orden importa: el primero de la lista es el que tienes al lado, y es
     justo a quien alcanzan las acciones de este menu. Verlo arriba y marcado
     es lo que ata las dos mitades del panel. ]]
local function MiembrosCerca(lista, yo)
    local salida = {}

    for _, m in ipairs(lista or {}) do
        local fila = {
            id     = m.id,
            nombre = m.nombre,
            rango  = m.rango,
            desde  = m.desde,
            online = m.online == true,
            soyYo  = m.soyYo == true,
            estado = 'pie',
            zona   = '',
            -- Los desconectados no tienen donde estar. Va a nil y no a cero:
            -- cero seria "lo tienes encima", que es justo lo contrario.
            distancia = nil,
        }

        if m.online and m.x then
            local donde = vector3(m.x, m.y or 0.0, m.z or 0.0)
            fila.distancia = #(yo - donde)
            fila.estado = EstadoDe(m)
            -- El nombre del barrio, no el codigo interno de la zona.
            fila.zona = GetLabelText(GetNameOfZone(donde.x, donde.y, donde.z))
        end

        salida[#salida + 1] = fila
    end

    --[[ Primero los conectados y, entre ellos, de mas cerca a mas lejos. Los
         desconectados van al final por rango: ahi ya no importa donde estan
         sino quien manda. ]]
    table.sort(salida, function(a, b)
        if a.online ~= b.online then return a.online end
        if a.online then return (a.distancia or 0) < (b.distancia or 0) end
        return (a.nombre or '') < (b.nombre or '')
    end)

    return salida
end

--- La radio, que ya la lleva su propio modulo.
local function EstadoDeRadio()
    if not (QuickMenuRadio and QuickMenuRadio.GetPayloadMeta) then return nil end

    local meta = QuickMenuRadio.GetPayloadMeta()
    local frec = meta.radioConnectedFreq

    local volumen = 60
    if GetResourceState('pma-voice') == 'started' then
        local ok, v = pcall(function() return exports['pma-voice']:getRadioVolume() end)
        -- pma-voice lo guarda en fraccion (0-1) aunque setRadioVolume pida 0-100:
        -- sin pasarlo a cien, el panel abria siempre con el volumen a cero.
        if ok and type(v) == 'number' then
            volumen = math.floor((v <= 1 and v * 100 or v) + 0.5)
        end
    end

    --[[ Quien habla NO se manda desde aqui: cambia varias veces por segundo y
         lo que se mandara seria una foto vieja nada mas abrir. Eso lo pone la
         interfaz, que ya recibe el goteo de la radio en vivo. ]]
    return {
        conectado  = frec ~= nil and frec ~= 'none',
        frecuencia = frec ~= 'none' and frec or nil,
        volumen    = volumen,
    }
end

--[[ Lo que el cliente puede pintar SIN preguntar a nadie.

     Con esto se abre el menu, en el acto. Es la mitad de la cabecera y poco
     mas, pero es lo que hace que pulsar el boton haga algo siempre, pase lo
     que pase con el servidor. ]]
local function ResumenLocal()
    if not playerGang then return nil end

    local rango = ''
    if playerGang.is_leader then
        rango = locale:t('ui.quick_menu.rank_leader')
    elseif playerGang.member then
        local rankId = playerGang.member.rank_id or playerGang.member.rank
        local rank = rankId and playerGang.ranks
            and (playerGang.ranks[tostring(rankId)] or playerGang.ranks[rankId])
        if rank and rank.name then rango = rank.name end
    end

    return {
        -- Sin el id, la pestaña de Vehiculos abierta antes de que conteste el
        -- servidor pedia el garaje de la banda '' y salia vacia.
        id       = playerGang.id,
        label    = playerGang.label or playerGang.name,
        rango    = rango,
        miembros = playerGang.memberCount or 0,
        online   = playerGang.onlineCount or 0,
        respeto  = math.floor(playerGang.points or 0),
        nivel    = playerGang.level or 1,
        xp       = 0,
        xpNivel  = 1000,
        caja     = math.floor(playerGang.money or 0),

        -- Todo lo que solo sabe el servidor arranca a cero y se rellena
        -- cuando conteste. La interfaz esta preparada para verlo vacio.
        territorios = 0, territoriosTotal = 0,
        alijo = 0, alijoTotal = 0,
        guerra = false, enDisputa = 0,
        puedeDepositar = false, puedeRetirar = false,
        territorio = {}, movimientos = {}, registro = {},
        miembros_lista = {},
        radio = EstadoDeRadio(),
    }
end

--[[ Y el resto, cuando llegue.

     Va en su propio hilo y despues de haber abierto: si el servidor tarda o
     no contesta, lo unico que pasa es que el panel se queda con los datos de
     arriba. Nunca que el menu no salga. ]]
function PedirPanelAlServidor()
    CreateThread(function()
        local ok, datos = pcall(function()
            return lib.callback.await('origen_gang:panel', false)
        end)

        if not ok or type(datos) ~= 'table' then
            -- A pelo y no con el Debug: si esto falla, el panel se queda a
            -- medias y hay que enterarse aunque el modo depuracion este
            -- apagado.
            print(('^1[origen_ilegalv2] El panel de banda no contesto: %s^0'):format(tostring(datos)))
            return
        end

        -- Puede haberse cerrado mientras tanto.
        if not isQuickMenuOpen then return end

        local yo = GetEntityCoords(PlayerPedId())

        -- Los recuentos vienen del servidor y no se tocan: la lista no te
        -- incluye a ti, pero los conectados si.
        datos.miembros_lista = MiembrosCerca(datos.miembros_srv, yo)
        datos.miembros_srv = nil
        datos.radio = EstadoDeRadio()

        --[[ Las que piden llevar un arma en la mano se quitan si vas
             desarmado.

             Esto solo se puede saber en el cliente, y se hace ANTES de
             pintar: un boton que sale siempre y se niega la mitad de las
             veces enseña a no fiarse de los botones. ]]
        if type(datos.accionesObjetivo) == 'table' then
            local armado = GetSelectedPedWeapon(PlayerPedId()) ~= `WEAPON_UNARMED`
            local limpias = {}

            for _, a in ipairs(datos.accionesObjetivo) do
                if not a.requiereArma or armado then
                    limpias[#limpias + 1] = a
                end
            end

            datos.accionesObjetivo = limpias
        end

        SendNUIMessage({ action = 'panelBanda', data = datos })

        -- El cuadro de la caja que pidio el punto de banco, ahora que el panel
        -- ya sabe si tienes permiso y si estas en tu territorio.
        if cajaPendiente then
            SendNUIMessage({ action = 'panelBanda:abrirCaja', tipo = cajaPendiente })
            cajaPendiente = nil
        end
    end)
end

--- La lista de botones la da origen_inventory, que es quien sabe si estas en
--- un coche, si tienes negocio o si eres admin. Aqui solo se pide.
local function RielDelInventario()
    if GetResourceState('origen_inventory') ~= 'started' then return nil end
    local ok, riel = pcall(function()
        return exports['origen_inventory']:GetRiel('banda')
    end)
    if not ok then return nil end
    return riel
end

--[[ ── Andar con el panel abierto ─────────────────────────────────────────

     Lo mismo que el F7 de policia (origen_police/client/interaction.lua): se
     apaga TODO y se enciende solo lo de moverse. Al reves —apagar una lista
     de lo que molesta— siempre se escapa algo: una tecla de otro menu, el
     golpe que entra por otro control segun el arma.

       30-35         andar (A/D, W/S)
       21 22         correr y saltar
       59 60 63 64   girar e inclinar el vehiculo
       71 72 76      acelerar, frenar y freno de mano
       249           hablar (pulsar para hablar)

     Fuera, a proposito: la rueda del raton (14-17), que al bajar por una
     lista cambiaba de arma; mirar con el raton (1 2), que es del cursor; y
     disparar, apuntar y los seis golpes, que ademas se cortan de raiz con
     DisablePlayerFiring, sea cual sea la tecla que los dispare. ]]
local TECLAS_CON_PANEL = { 30, 31, 32, 33, 34, 35, 21, 22, 59, 60, 63, 64, 71, 72, 76, 249 }

--[[ Alt con el panel abierto (21/09/2026).

     La pestaña de Radio dice, con todas las letras, que se habla con Alt. Y
     con el panel abierto el teclado va a la vez a la pagina y al juego
     (KeepInput), que es justo cuando a FiveM le sienta mal el Alt: la pagina
     se queda sin foco, el cursor en medio, y el Escape --que lo lee la
     pagina-- ya no llega. Es el mismo fallo que en el movil y en origen_anims,
     y aqui van las mismas dos redes:

     - Al soltar Alt se vuelve a dar el foco a la pagina, igual que al abrir.
     - Escape leido en crudo (no pasa por la pagina ni por los controles): si
       la pagina no dice en 300 ms que lo ha visto ('gang:escVisto'), no le
       esta llegando el teclado y se cierra desde aqui. Cuando si llega manda
       la pagina, que sabe si ese Escape era de un cuadro y no del panel. ]]
local ALT_TECLAS = { 18, 164 } -- VK_MENU y VK_LMENU
local ESC_TECLA = 27
local escVisto = 0

local function SoltoAlt()
    if not IsRawKeyReleased then return false end
    for i = 1, #ALT_TECLAS do
        if IsRawKeyReleased(ALT_TECLAS[i]) then return true end
    end
    return false
end

RegisterNUICallback('gang:escVisto', function(_, cb)
    escVisto = GetGameTimer()
    cb('ok')
end)

--[[ Un cierre que no viene de la pagina (Escape que no llego, foco perdido,
     `raton`, la pantalla que no se pinto, morir con el panel abierto) no pasa
     por el callback 'closeQuickMenu', y una venta pendiente dejaba al jugador
     congelado. Se avisa igual que la pagina, y solo si habia menu. ]]
local function CierreForzado()
    local estaba = isQuickMenuOpen
    CloseEmbeddedQuickMenu(true)
    if estaba then TriggerEvent('origen_gang:quickMenu:closed') end
end

--- Cada apertura lleva su numero: si se cierra y se vuelve a abrir en el mismo
--- fotograma, el hilo viejo se retira y no quedan dos apagando controles.
local hiloTeclas = 0

local function ControlesConPanel()
    hiloTeclas = hiloTeclas + 1
    local mio = hiloTeclas

    CreateThread(function()
        local jugador = PlayerId()
        local desde = GetGameTimer()
        local muertoVisto = 0

        while isQuickMenuOpen and panelAndando and hiloTeclas == mio do
            --[[ Red por si nos quitan el foco sin pasar por el cierre (el
                 comando `raton`, otro recurso): sin foco no hay panel que
                 atender, y seguir apagando controles dejaria al jugador sin
                 poder mirar ni pegar. El margen es el fotograma que tarda en
                 constar el SetNuiFocus recien hecho. ]]
            if GetGameTimer() - desde > 500 and not IsNuiFocused() then
                CierreForzado()
                break
            end

            --[[ Muerto (o en el suelo) con el panel abierto: se seguian apagando
                 todos los controles cada fotograma, encima de la pantalla de
                 muerto. Se mira cada 250 ms, que el estado sale del framework. ]]
            if GetGameTimer() - muertoVisto > 250 then
                muertoVisto = GetGameTimer()
                if Framework and Framework.GetIsPlayerDead and Framework.GetIsPlayerDead() then
                    CierreForzado()
                    break
                end
            end

            -- Las dos redes del Alt (ver arriba).
            if SoltoAlt() then
                SetNuiFocus(true, true)
                SetNuiFocusKeepInput(not escribiendo)
            end

            if IsRawKeyReleased and IsRawKeyReleased(ESC_TECLA) then
                local pulsado = GetGameTimer()
                SetTimeout(300, function()
                    -- La pagina ve el Escape al bajarlo y aqui se lee al soltarlo:
                    -- el margen es lo que se tiene pulsado. Con 2 s, un Escape
                    -- visto (el de un cuadro) apagaba esta red para el siguiente.
                    if isQuickMenuOpen and hiloTeclas == mio and escVisto < pulsado - 500 then
                        print('^3[origen_ilegalv2]^7 El Escape no llego al panel de banda: se cierra desde aqui y se suelta el raton.')
                        CierreForzado()
                    end
                end)
            end

            DisableAllControlActions(0)
            for i = 1, #TECLAS_CON_PANEL do
                EnableControlAction(0, TECLAS_CON_PANEL[i], true)
            end
            DisablePlayerFiring(jugador, true)
            Wait(0)
        end

        if hiloTeclas ~= mio then return end

        -- El ESC que cerro el panel no debe llegar al juego al soltarse.
        while IsControlPressed(0, 200) or IsDisabledControlPressed(0, 200) do
            DisableControlAction(0, 200, true)
            Wait(0)
        end
    end)
end

--[[ Un campo de texto del panel coge o suelta el foco.

     Con KeepInput encendido, lo que escribes llega TAMBIEN al juego: poner
     "sadwa" de nombre a un rango hacia bailar al personaje. Mientras haya un
     campo de texto activo se apaga, y al salir vuelve. Es la misma idea que
     inventory:focusIn / focusOut en origen_inventory. ]]
RegisterNUICallback('gang:escribiendo', function(datos, cb)
    cb('ok')
    if not (isQuickMenuOpen and panelAndando) then return end

    escribiendo = datos and datos.si == true
    SetNuiFocusKeepInput(not escribiendo)
end)

--[[ Si el vigilante del foco nos lo quita a la fuerza (`raton` en F8), el
     panel se cierra de verdad: con `isQuickMenuOpen` a true no volveria a
     abrirse, y el hilo de arriba seguiria apagando controles. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if isQuickMenuOpen then CierreForzado() end
    end)
end

function OpenEmbeddedQuickMenu(menuOptions)
    if type(menuOptions) ~= 'table' then return end

    currentQuickMenuOptions = menuOptions
    currentQuickMenuMap = {}

    local payload = BuildNuiQuickMenuPayload(menuOptions)
    if not payload.actions or #payload.actions == 0 then
        return
    end

    if QuickMenuRadio and QuickMenuRadio.GetPayloadMeta then
        local meta = QuickMenuRadio.GetPayloadMeta()
        payload.hasRadioTab = meta.hasRadioTab
        payload.radioGroup = meta.radioGroup
        payload.radioFreqList = meta.radioFreqList
        payload.radioConnectedFreq = meta.radioConnectedFreq
        payload.radioMuted = meta.radioMuted
    else
        payload.hasRadioTab  = HasPermission('quick_radio')
        payload.radioGroup   = playerGang and ('gang_' .. tostring(playerGang.id)) or nil
        payload.radioFreqList = Config.Radio.Frequencies
        payload.radioConnectedFreq = 'none'
        payload.radioMuted = false
    end

    payload.conRiel = conRiel
    payload.relevo = relevoEntrante
    relevoEntrante = false


    payload.riel = conRiel and RielDelInventario() or nil

    --[[ El cuadro de mando abre con lo que el cliente YA sabe, y el resto
         llega despues.

         Antes se esperaba aqui la respuesta del servidor antes de mandar nada
         a la interfaz, y eso ataba el boton a que la respuesta llegase: si el
         callback tardaba —o no estaba registrado siquiera, que es lo que pasa
         cuando el recurso se reinicia sin refresh—, lib.callback.await se
         planta CINCO MINUTOS y el menu sencillamente no se abria. Pulsabas y
         no pasaba nada.

         Los datos no pueden decidir si el boton funciona. ]]
    local pedirPanel = conRiel
    payload.banda = conRiel and ResumenLocal() or nil

    conRiel = false   -- se consume: el siguiente menu no lo hereda

    isQuickMenuOpen = true
    escribiendo = false

    --[[ El foco lo declara cada panel, sin dar nada por heredado.

         `SetNuiFocusKeepInput` es un interruptor GLOBAL del cliente y se queda
         como lo dejo el ultimo que lo toco: al saltar del riel del inventario
         se heredaba encendido, sin nadie apagando la camara ni los golpes, y
         el personaje daba puñetazos al pulsar los botones.

         El panel de banda (con riel) deja ANDAR, como el F7 de policia: las
         teclas llegan al juego y el hilo de ControlesConPanel lo apaga todo
         menos moverse, conducir y hablar. Los menus incrustados de la venta
         de droga siguen sin teclas: ahi estas a mitad de un trato y alejarte
         con el menu abierto no pinta nada.

         KeepInput va DESPUES de SetNuiFocus: el vigilante del foco
         (origen_map/shared/foco.lua) lo apaga al coger el foco. ]]
    panelAndando = pedirPanel
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(pedirPanel)
    if pedirPanel then ControlesConPanel() end

    SendNUIMessage({
        action = 'openQuickMenu',
        data = payload
    })

    --[[ ── Y SE COMPRUEBA QUE LA PANTALLA LLEGO A PINTARSE ──────────────────

         Mandar el mensaje no prueba nada. Si la interfaz revienta al montarse
         --un dato que llega mal, una lista que no era lista-- Vue desmonta el
         trozo roto y no dice nada: queda la pantalla en blanco con el foco de
         la NUI cogido, el raton en medio y nada que pulsar. Y desde aqui todo
         parece correcto, porque `isQuickMenuOpen` sigue en true.

         Asi que la interfaz contesta cuando se ha pintado de verdad --mirando
         que su div este en el DOM, no solo que le hayan llamado-- y si en un
         segundo y medio no ha contestado, se cierra y se suelta el foco.

         Segundo y medio: la NUI contesta en el primer fotograma; el margen es
         para un arranque lento, no para esperar a nadie. ]]
    nuiPintada = false

    SetTimeout(1500, function()
        if not isQuickMenuOpen or nuiPintada then return end

        print('^1[origen_ilegalv2]^0 El menu rapido no llego a pintarse. Se cierra y se suelta el foco para no dejar el raton preso.')
        CierreForzado()
    end)

    if pedirPanel then PedirPanelAlServidor() end
end

function CloseEmbeddedQuickMenu(notifyNui)
    --[[ EL FOCO SE SUELTA ANTES QUE NADA, y por fuera del guardia de abajo.

         Ese `if not isQuickMenuOpen` descartaba la llamada entera, y con ella
         el SetNuiFocus: con la marca ya en false, la pantalla se iba y el
         raton se quedaba en medio. Quedarse sin panel se arregla volviendo a
         abrir; quedarse sin camara, no. ]]
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if not isQuickMenuOpen then return end

    isQuickMenuOpen = false
    panelAndando = false
    escribiendo = false
    -- Un cuadro pedido para un panel que ya se ha ido no lo hereda el siguiente.
    cajaPendiente = nil
    eleccionMap = {}
    currentQuickMenuOptions = {}
    currentQuickMenuMap = {}

    if QuickMenuRadio and QuickMenuRadio.OnMenuClosed then
        QuickMenuRadio.OnMenuClosed()
    end

    SetNuiFocus(false, false)

    if notifyNui then
        SendNUIMessage({ action = 'closeQuickMenu' })
    end
end

RegisterNUICallback('quickMenuAction', function(data, cb)
    local actionId = data and data.actionId or nil
    local selectedOption = actionId and currentQuickMenuMap[actionId] or nil

    CloseEmbeddedQuickMenu(false)

    local ok, err = pcall(TriggerMenuOption, selectedOption)
    if not ok then
        dbg:error('[QuickMenu] Error executing menu option:', err)
    end

    cb('ok')
end)

RegisterNUICallback('closeQuickMenu', function(_, cb)
    CloseEmbeddedQuickMenu(false)
    TriggerEvent('origen_gang:quickMenu:closed')
    cb('ok')
end)

function OpenQuickMenu()
    if not Config.QuickMenu.Enable then return end
    if isQuickMenuOpen then return end
    if not playerGang then return end

    local menuOptions = {
        {
            header = locale:t('ui.quick_menu.default_title'),
            isMenuHeader = true,
            icon = 'fa-solid fa-bolt'
        }
    }

    local level    = (_G.StreetSaleManager and _G.StreetSaleManager.cachedLevel) or 0
    local isActive = (_G.StreetSaleManager and _G.StreetSaleManager.zoneActive)  or false

    if level >= 90 then
        table.insert(menuOptions, {
            header = isActive and locale:t('ui.quick_menu.zone_sale_cancel') or locale:t('ui.quick_menu.zone_sale_activate'),
            txt    = isActive
                and locale:t('ui.quick_menu.zone_sale_active_desc', level)
                or  locale:t('ui.quick_menu.zone_sale_inactive_desc', level),
            icon   = isActive and 'fa-solid fa-circle-stop' or 'fa-solid fa-circle-play',
            params = {
                event = 'origen_gang:client:toggleZoneSale',
                args  = {}
            }
        })
    end

    --[[ Cachear, esposar, escoltar y meter/sacar NO se ponen aqui.

         Aqui habia un segundo juego de esos botones sacado de
         lib.getClosestPlayer, de cuando el cliente decidia quien era el de al
         lado. Desde que lo decide el servidor, esos botones llegan en
         `accionesObjetivo` (f_panel_banda.lua, ObjetivoDe) y PanelBanda los
         pinta en la misma rejilla. Con alguien al lado salian los dos juegos
         y cada icono se veia repetido. La unica lista es la del servidor. ]]

    --[[ Y las cuatro que no necesitan a nadie delante.

         Van SIEMPRE, tengas a alguien al lado o no. Es lo que hace que el
         boton de Banda del riel nunca este muerto: antes, estando solo, el
         menu no tenia una sola cosa que enseñar y saltaba un aviso de error
         en vez de abrirse. ]]
    --[[ La bolsa en la cabeza ocupa el hueco que era del Alijo (16/09/2026,
         pedido por el usuario). El alijo sigue en su sitio —la cifra de
         arriba y la pestaña de Ubicaciones—; solo se va el boton. Quien lleva
         la bolsa lo decide el servidor (origen_gang:server:bolsaCabeza), no
         este cliente. Mismo permiso que esposar: es la misma clase de cosa. ]]
    table.insert(menuOptions, {
        header   = locale:t('ui.quick_menu.act_headbag'),
        icon     = 'mdi:sack',
        disabled = not HasPermission('quick_handcuff'),
        params   = { event = 'origen_gang:client:accionBolsa' },
    })

    table.insert(menuOptions, {
        header = locale:t('ui.quick_menu.act_mark'),
        icon   = 'lucide:map-pin',
        params = { event = 'origen_gang:client:accionMarcar' },
    })

    table.insert(menuOptions, {
        header   = locale:t('ui.quick_menu.act_notice'),
        icon     = 'lucide:megaphone',
        disabled = not HasPermission('quick_radio'),
        params   = { event = 'origen_gang:client:accionAviso' },
    })

    table.insert(menuOptions, {
        header  = locale:t('ui.quick_menu.act_sos'),
        icon    = 'lucide:triangle-alert',
        peligro = true,
        params  = { event = 'origen_gang:client:accionSOS' },
    })

    conRiel = true

    OpenEmbeddedQuickMenu(menuOptions)
end

function CloseQuickMenu()
    if not isQuickMenuOpen then return end
    CloseEmbeddedQuickMenu(true)
end

--[[ ── Elegir algo SIN salir del panel ───────────────────────────────────

     Meter en el coche y sacar del coche preguntan despues de pulsar: que
     asiento, o a que pasajero. Eso lo pedian con OpenEmbeddedQuickMenu, y
     salia la tarjeta vieja oscura, suelta y sin riel. El motivo: el panel se
     cerraba al pulsar la accion, y cuando el servidor contestaba ya no habia
     panel; ademas `conRiel` se consume en cada apertura, asi que el menu
     incrustado nacia siempre sin riel y la interfaz pintaba la tarjeta.

     Ahora esas dos acciones no cierran el panel, y la pregunta se pinta con
     el cuadro del propio panel (DialogoPanel, opciones en chips). Elegir
     dispara la opcion y el panel se queda, con los datos refrescados;
     cancelar solo quita el cuadro.

     Solo lo usan los que vienen del panel (client/functions/f_vehicle_actions.lua).
     La venta de droga sigue con OpenEmbeddedQuickMenu y su tarjeta.

     `opciones.confirmar` es el texto del boton rosa. ]]
function ElegirEnPanel(menuOptions, opciones)
    if type(menuOptions) ~= 'table' then return end
    opciones = opciones or {}

    -- Se cerro mientras el servidor contestaba: se vuelve a abrir el panel,
    -- que es de donde venia la pregunta. Sin banda o con el menu apagado no
    -- se abre, y entonces queda la tarjeta de siempre.
    if not (isQuickMenuOpen and panelAndando) then
        if not isQuickMenuOpen then OpenQuickMenu() end
        if not (isQuickMenuOpen and panelAndando) then
            OpenEmbeddedQuickMenu(menuOptions)
            return
        end
    end

    eleccionMap = {}
    local datos = { titulo = 'Menú', icono = 'lucide:car', opciones = {}, confirmar = opciones.confirmar }

    for idx, option in ipairs(menuOptions) do
        if option.isMenuHeader then
            datos.titulo = option.header or datos.titulo
            datos.texto  = option.txt
        elseif not option.disabled then
            local id = ('elegir_%s'):format(idx)
            eleccionMap[id] = option
            datos.opciones[#datos.opciones + 1] = {
                value = id,
                label = option.header or ('Opción %s'):format(idx),
            }
        end
    end

    if #datos.opciones == 0 then return end

    SendNUIMessage({ action = 'panelBanda:elegir', data = datos })
end

RegisterNUICallback('gang:elegirOpcion', function(datos, cb)
    cb('ok')

    local id = datos and datos.id
    local opcion = type(id) == 'string' and eleccionMap[id] or nil
    eleccionMap = {}
    if not opcion then return end

    local ok, err = pcall(TriggerMenuOption, opcion)
    if not ok then
        dbg:error('[QuickMenu] Error en la opcion elegida:', err)
    end

    -- Tras meter o sacar, el de al lado cambia de estado: el boton de la
    -- rejilla tiene que pasar de «meter» a «sacar» o al reves.
    CreateThread(function()
        Wait(400)
        if isQuickMenuOpen then PedirPanelAlServidor() end
    end)
end)

RegisterNUICallback('gang:elegirCancelar', function(_, cb)
    cb('ok')
    eleccionMap = {}
end)

--[[ Abrir el panel de la banda directamente en el cuadro de ingresar o sacar.

     Lo usa el punto de banco del mundo (OpenGangBank, client/locations.lua),
     que antes abria un cuadro de ox_lib por su cuenta.

     El mensaje para la interfaz NO sale al abrir, sale cuando llegan los datos
     del servidor (PedirPanelAlServidor). Por dos motivos:
       · para entonces el panel esta montado de verdad —se monta al llegar
         'openQuickMenu', y 'panelBanda' solo se atiende con el ya puesto—, y
         un mensaje que llega antes que el componente se pierde sin decir nada;
       · y ya sabe si tienes permiso y si estas en tu territorio (`cajaAqui`).
         Si no puedes, se queda en la pestaña de caja con los botones apagados
         y la razon debajo, en vez de abrir un cuadro que luego se rechaza.

     Si el servidor no contesta, el panel se abre igual y el cuadro no sale:
     sin sus datos los botones tambien estarian apagados. ]]
function AbrirCajaDeBanda(tipo)
    tipo = tipo == 'out' and 'out' or 'in'

    -- El panel de banda ya delante (el de los botones, no un menu incrustado
    -- de la venta de droga): basta con pedirselo, que los datos ya los tiene.
    if isQuickMenuOpen then
        if panelAndando then
            SendNUIMessage({ action = 'panelBanda:abrirCaja', tipo = tipo })
        end
        return
    end

    cajaPendiente = tipo
    OpenQuickMenu()

    -- No se ha llegado a abrir (sin banda, o el menu apagado en la config):
    -- que no se quede apuntado para la proxima vez que se abra por otro lado.
    if not isQuickMenuOpen then cajaPendiente = nil end
end

function ExecuteQuickAction(actionId, targetId)
    local actionConfig = nil

    for _, action in ipairs(Config.QuickMenu.Actions) do
        if action.id == actionId then
            actionConfig = action
            break
        end
    end

    if not actionConfig then
        return
    end

    if actionConfig.requiredPermission and not HasPermission(actionConfig.requiredPermission) then
        Notify.SendNotify(locale:t('notify.no_permission_action'), 'error')
        return
    end

    local playerPed = PlayerPedId()
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))

    if actionConfig.canExecute then
        local canExecute, reason = actionConfig.canExecute(playerPed, targetPed)
        if not canExecute then
            local msg = reason and locale:t('notify.error_with_reason', reason) or locale:t('notify.cannot_execute_action')
            Notify.SendNotify(msg, 'error')
            return
        end
    end

    --[[ Aqui antes se ponia `isQuickMenuOpen = false` sin cerrar nada: el
         panel seguia delante con el foco y el cliente creia que no. Cerrar lo
         hace la interfaz (accionSobreObjetivo); y meter/sacar del coche
         necesitan el panel ABIERTO para pintar dentro el selector. ]]
    TriggerServerEvent('origen_gang:server:quickAction', actionId, targetId)
end

RegisterNetEvent('origen_gang:client:executeQuickAction', function(data)
    ExecuteQuickAction(data.actionId, data.targetId)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if QuickMenuRadio and QuickMenuRadio.OnResourceStop then
        QuickMenuRadio.OnResourceStop()
    end
    if isQuickMenuOpen then
        CloseQuickMenu()
    end
end)

if Config.QuickMenu.Key then
    RegisterKeyMapping('+quickmenu', 'Abrir menú rápido de banda', 'keyboard', Config.QuickMenu.Key)
end

RegisterCommand('+quickmenu', function()
    OpenQuickMenu()
end, false)

RegisterCommand('-quickmenu', function()
end, false)

if Config.QuickMenu.UseCommand and Config.QuickMenu.CommandName then
    RegisterCommand(Config.QuickMenu.CommandName, function()
        OpenQuickMenu()
    end, false)
end

--[[ Saltar a otro panel desde el riel. Se suelta el foco de esta NUI antes:
     los dos paneles lo piden para si, y si no se suelta el que se abre no
     responde al raton. ]]
--- La interfaz avisa de que su panel esta en el DOM. Sin esto, el cliente no
--- tiene forma de saber si lo que mando llego a pintarse.
RegisterNUICallback('quickMenuPintado', function(_, cb)
    cb('ok')
    nuiPintada = true
end)

RegisterNUICallback('gang:irDelRiel', function(data, cb)
    cb('ok')

    -- Se cierra SIEMPRE, antes de mirar nada: la interfaz ya se ha escondido
    -- al pulsar, y volver sin cerrar dejaba el raton puesto (16/09).
    CloseQuickMenu()
    SetNuiFocus(false, false)

    if GetResourceState('origen_inventory') ~= 'started' then return end

    local destino = data and data.id
    if not destino or destino == 'banda' then return end

    --[[ A los 200 y no a los 150: la columna tarda 260 ms en recogerse, asi
         que abriendo a mitad del recorrido el panel que entra empieza a
         deslizarse mientras este acaba de salir y no queda ni un fotograma de
         pantalla vacia. La barra del canto no se mueve en ningun momento.

         El `true` es el aviso de RELEVO: el que entra pinta su riel ya puesto
         en vez de deslizarlo, porque el de aqui sigue ahi hasta desmontarse. ]]
    CreateThread(function()
        Wait(200)
        if destino == 'admin' or destino == 'crew' or destino == 'negocio' or destino == 'policia'
            or destino == 'mascotas' or destino == 'radio' then
            exports['origen_inventory']:AbrirAcceso(destino, true)
        else
            exports['origen_inventory']:AbrirEnPestana(destino, true)
        end
    end)
end)

--[[ ══ Lo que el panel le pide a Lua ═══════════════════════════════════════

     Nada de aqui abajo pregunta nada. Antes casi todo abria un cuadro de
     ox_lib —"¿seguro?", "escribe la cantidad", "elige el rango"— y eso salia
     en mitad de la pantalla con otra tipografia, otros bordes y otros
     botones: para el jugador eran dos programas distintos pegados.

     Ahora pregunta el panel, con su cuadro y su estilo, y aqui llegan los
     datos ya completos. Lo unico que sigue pasando en Lua es lo que solo
     puede pasar en Lua: colocar una ubicacion con el marcador, y volver a
     comprobarlo todo antes de mandarlo al servidor. ]]

--- Volver a pedir los datos del panel sin cerrarlo, tras cambiar algo.
local function RefrescarPanel()
    CreateThread(function()
        -- Un respiro: el evento que cambio algo tiene que llegar al servidor
        -- y volver antes de que preguntemos, o se pide la foto vieja.
        Wait(400)
        if isQuickMenuOpen then PedirPanelAlServidor() end
    end)
end

RegisterNUICallback('gang:refrescarPanel', function(_, cb)
    cb('ok')
    RefrescarPanel()
end)

--- Alguien de la banda ha descubierto un territorio: si el panel esta abierto,
--- que el mapa y la lista lo enseñen ya (ver server/functions/f_territory_discovery.lua).
RegisterNetEvent('origen_gang:client:territorioDescubierto', function()
    RefrescarPanel()
end)

-- ── La caja ─────────────────────────────────────────────────────────────────

RegisterNUICallback('gang:cajaMover', function(datos, cb)
    cb('ok')

    local cantidad = math.floor(tonumber(datos and datos.cantidad) or 0)
    if cantidad <= 0 then return end

    local mete = (datos and datos.tipo) == 'in'

    lib.callback(mete and 'origen_gang:nui:depositMoney' or 'origen_gang:nui:withdrawMoney',
        false, function() RefrescarPanel() end, cantidad)
end)

-- ── Miembros ────────────────────────────────────────────────────────────────

RegisterNUICallback('gang:miembroAccion', function(datos, cb)
    cb('ok')

    local accion = datos and datos.accion
    local quien  = datos and datos.id
    if not accion then return end

    if accion == 'ascender' then
        TriggerServerEvent('origen_gang:server:promoteMember', quien)

    elseif accion == 'degradar' then
        TriggerServerEvent('origen_gang:server:demoteMember', quien)

    elseif accion == 'expulsar' then
        -- El panel ya ha preguntado. Aqui solo se hace.
        TriggerServerEvent('origen_gang:server:kickMember', quien)

    elseif accion == 'rango' then
        local rankId = tonumber(datos.rankId)
        if not rankId then return end
        TriggerServerEvent('origen_gang:server:setMemberRank', quien, rankId)

    elseif accion == 'invitar' then
        local sid = tonumber(datos.targetId)
        if not sid then return end
        TriggerServerEvent('origen_gang:server:inviteMember', sid)
    end

    RefrescarPanel()
end)

--[[ Los que tienes cerca, para el desplegable de invitar.

     Solo se puede invitar a quien tienes delante. No es una limitacion
     tecnica: invitar a alguien del otro lado del mapa al que no has visto es
     justo lo que no se quiere. ]]
RegisterNUICallback('gang:jugadoresCerca', function(_, cb)
    local salida = {}

    local cerca = lib.getNearbyPlayers(GetEntityCoords(PlayerPedId()), 5.0, false) or {}
    for _, p in ipairs(cerca) do
        local sid = GetPlayerServerId(p.id)
        salida[#salida + 1] = { value = tostring(sid), label = ('%s  ·  %s'):format(GetPlayerName(p.id), sid) }
    end

    cb(salida)
end)

-- ── Acciones sobre el de al lado ────────────────────────────────────────────

--[[ Cachear, esposar, escoltar y meter/sacar del coche.

     El objetivo NO viaja desde la interfaz: se le pregunta al servidor justo
     antes de disparar. Asi no depende de lo que el cliente tenga streameado
     —que era el fallo por el que los botones no salian— ni de que el id que
     suba de la NUI sea el bueno. ]]
RegisterNUICallback('gang:accionObjetivo', function(datos, cb)
    cb('ok')

    local actionId = datos and datos.actionId
    if not actionId then return end

    --[[ Someter no es una accion de banda: es el rehen de origen_hostage.

         Se llama a su comando en vez de copiar aqui lo que hace, porque ese
         recurso ya comprueba el arma, la distancia y que no estes sujetando a
         nadie —y avisa con su propio mensaje si algo falla—. Duplicar esas
         tres comprobaciones seria tener dos formas de tomar un rehen que se
         separarian a la primera. ]]
    if actionId == 'someter' then
        CloseQuickMenu()
        SetNuiFocus(false, false)
        CreateThread(function()
            Wait(150)
            ExecuteCommand('th')
        end)
        return
    end

    CreateThread(function()
        local objetivo = lib.callback.await('origen_gang:objetivoCerca', false)
        if not objetivo then
            Notify.SendNotify(locale:t('notify.no_players_nearby'), 'error')
            return
        end

        ExecuteQuickAction(actionId, objetivo)
    end)
end)

-- ── Rangos ──────────────────────────────────────────────────────────────────

--- El detalle de cada rango sale de playerGang, que ya lo tiene: no hace
--- falta ir al servidor a leer lo que el servidor ya nos mando.
RegisterNUICallback('gang:getRanksDetail', function(_, cb)
    local salida = {}

    for _, rank in pairs(playerGang and playerGang.ranks or {}) do
        salida[#salida + 1] = {
            id          = rank.id,
            name        = rank.name,
            grade       = rank.grade or 0,
            salary      = rank.salary or 0,
            permissions = rank.permissions or {},
        }
    end

    cb(salida)
end)

RegisterNUICallback('gang:crearRango', function(datos, cb)
    cb('ok')

    local nombre = datos and datos.nombre
    if type(nombre) ~= 'string' or nombre:gsub('%s', '') == '' then return end

    --[[ Nace sin ningun permiso, a proposito: un rango nuevo que heredase los
         del jefe seria una via de escalada silenciosa —creas uno, te lo pones
         y ya mandas—. Se abre su ficha y se marca lo que toque. ]]
    TriggerServerEvent('origen_gang:server:createRank', {
        name = nombre:sub(1, 40),
        salary = math.max(0, math.floor(tonumber(datos.salario) or 0)),
        permissions = {},
    })

    RefrescarPanel()
end)

RegisterNUICallback('gang:borrarRango', function(datos, cb)
    cb('ok')

    local rankId = tonumber(datos and datos.rankId)
    if not rankId then return end

    local destino = tonumber(datos.destino)

    -- Con gente dentro hay que decir a donde pasa; el panel ya lo ha
    -- preguntado y manda el rango destino.
    if destino then
        TriggerServerEvent('origen_gang:server:migrateAndDeleteRank', rankId, destino)
    else
        TriggerServerEvent('origen_gang:server:deleteRank', rankId)
    end

    RefrescarPanel()
end)

-- ── Vehiculos ───────────────────────────────────────────────────────────────

RegisterNUICallback('gang:borrarVehiculo', function(datos, cb)
    cb('ok')

    local vehicleId = datos and datos.vehicleId
    local gangId    = datos and datos.gangId
    if not vehicleId then return end

    CreateThread(function()
        local ok = lib.callback.await('origen_gangs:server:deleteGangVehicle', false, gangId, vehicleId)
        Notify.SendNotify(
            locale:t(ok and 'notify.vehicle_deleted' or 'notify.vehicle_delete_error'),
            ok and 'success' or 'error')
        RefrescarPanel()
    end)
end)

-- ── Ubicaciones ─────────────────────────────────────────────────────────────

--[[ Colocar una usa el modo de colocacion del recurso: sale un marcador que
     se mueve contigo y se confirma. Eso obliga a CERRAR el panel, que si no
     no se ve el mundo por debajo. Es lo unico que sigue preguntando fuera del
     panel, y no puede ser de otra forma: la pregunta es "¿dónde?" y la
     respuesta esta en el mundo, no en un formulario. ]]
RegisterNUICallback('gang:ponerSitio', function(datos, cb)
    cb('ok')

    local tipo = datos and datos.tipo
    if not tipo then return end

    CloseQuickMenu()
    SetNuiFocus(false, false)

    CreateThread(function()
        Wait(200)
        StartLocationPlacement(tipo, function(coords)
            if not coords then return end
            TriggerServerEvent('origen_gang:server:setLocation', tipo, {
                x = coords.x, y = coords.y, z = coords.z,
                h = coords.h or coords.heading or 0.0,
            })
        end)
    end)
end)

RegisterNUICallback('gang:quitarSitio', function(datos, cb)
    cb('ok')

    local tipo = datos and datos.tipo
    if not tipo then return end

    TriggerServerEvent('origen_gang:server:removeLocation', tipo)
    RefrescarPanel()
end)

--[[ Ir a una ubicacion pone la RUTA, no teletransporta.

     Teletransportar es cosa del panel de admin. El alijo es un sitio al que
     hay que llegar, y ese viaje —con lo que lleves encima— es justo la parte
     que hace que tenerlo lejos signifique algo. ]]
RegisterNUICallback('gang:irASitio', function(datos, cb)
    cb('ok')

    local tipo = datos and datos.tipo
    local sitio = tipo and playerGang and playerGang.locations and playerGang.locations[tipo]
    if not sitio then return end

    SetNewWaypoint(sitio.x + 0.0, sitio.y + 0.0)
    Notify.SendNotify(locale:t('notify.place_marked'), 'info')
end)

--[[ Marcar una zona desde la pestaña de Territorio: la ruta al centro de su
     poligono. Solo toca TU GPS, pero la interfaz es del jugador y se puede
     tocar: numeros de verdad y dentro del mapa, o nada. ]]
RegisterNUICallback('gang:marcarZona', function(datos, cb)
    cb('ok')

    local x = tonumber(datos and datos.x)
    local y = tonumber(datos and datos.y)
    if not x or not y or x ~= x or y ~= y then return end
    if x < -5000 or x > 5000 or y < -5000 or y > 9000 then return end

    SetNewWaypoint(x + 0.0, y + 0.0)
    Notify.SendNotify(locale:t('notify.place_marked'), 'info')
end)

--[[ El volumen de la radio desde la pestaña de Radio. El panel lo mandaba y
     nadie lo recogia: la barra se movia y el juego seguia igual. Solo toca
     TU pma-voice, nada va al servidor; aun asi, un numero de 0 a 100. ]]
RegisterNUICallback('gang:radioVolumen', function(datos, cb)
    cb('ok')

    local v = tonumber(datos and datos.valor)
    if not v or v ~= v then return end
    v = math.floor(math.max(0, math.min(100, v)) + 0.5)

    if GetResourceState('pma-voice') == 'started' then
        pcall(function() exports['pma-voice']:setRadioVolume(v) end)
    end
end)

-- ── Posicion de las armas ───────────────────────────────────────────────────

--[[ La misma funda que usa la policia en su menu F7, que es de origen_police y
     ya vale para todos los trabajos (Config.HolsterAllJobs). Aqui no se
     reinventa nada: se pulsa el mismo boton que alli.

     Y LA LISTA ES CERRADA. El menu de la policia ejecuta el comando que trae
     cada boton; si aqui se hiciera igual con lo que manda la interfaz, quien
     tocara la NUI podria ejecutar cualquier comando del cliente. La interfaz
     manda un nombre y solo vale si esta en esta tabla.

     Los nombres son las categorias de Config.WeaponCategoryOffsets de
     origen_police: cambiar uno alli obliga a cambiarlo aqui. ]]
local POSICIONES_ARMA = {
    pistola = {
        boxers = true,          -- frontal
        backhandgun = true,     -- detras
        waisthandgun = true,    -- cartuchera de cintura
        handguns = true,        -- cartuchera normal
        chesthandgun = true,    -- cartuchera de pecho
        hiphandgun = true,      -- cartuchera de muslo
        leghandgun = true,      -- cartuchera de pierna
        handguns2 = true,       -- cartuchera de pierna separada
    },
    rifle = {
        tacticalrifle = true,   -- pecho
        assault = true,         -- espalda
    },
}

--- La funda vive en origen_police: sin el arrancado, ni se ven las armas.
local function FundaDisponible()
    return GetResourceState('origen_police') == 'started'
end

--- Lo que tienes puesto ahora, para marcarlo en el panel. Lo guarda
--- origen_police en los metadatos del personaje al elegir.
RegisterNUICallback('gang:armasEstado', function(_, cb)
    local pistola, rifle = nil, nil
    pcall(function()
        pistola = Framework.GetPlayerMetaData('handgunflag')
        rifle = Framework.GetPlayerMetaData('rifleflag')
    end)

    cb({
        disponible = FundaDisponible(),
        pistola = POSICIONES_ARMA.pistola[pistola] and pistola or nil,
        rifle = POSICIONES_ARMA.rifle[rifle] and rifle or nil,
    })
end)

--- Un cambio cada medio segundo como mucho: cada uno quita y vuelve a poner
--- los objetos de las armas y guarda dos metadatos en el servidor.
local ultimoCambioArma = 0

RegisterNUICallback('gang:armasPosicion', function(datos, cb)
    local ahora = GetGameTimer()
    if ahora - ultimoCambioArma < 500 then return cb({ ok = false }) end

    if not FundaDisponible() then
        Notify.SendNotify(locale:t('ui.quick_menu.weapons_unavailable'), 'error')
        return cb({ ok = false })
    end

    local accion = datos and datos.accion

    if accion == 'mostrar' then
        ultimoCambioArma = ahora
        TriggerEvent('origen_police:holster:unarm')
        return cb({ ok = true })
    end

    local tipo = datos and datos.tipo
    local lista = type(tipo) == 'string' and POSICIONES_ARMA[tipo]
    if accion ~= 'posicion' or not lista or type(datos.flag) ~= 'string' or not lista[datos.flag] then
        return cb({ ok = false })
    end

    ultimoCambioArma = ahora
    ExecuteCommand('holster ' .. datos.flag)
    cb({ ok = true })
end)

-- ── Aviso a la banda ────────────────────────────────────────────────────────

--- El texto lo pide el panel; aqui solo se manda. Se recorta tambien en el
--- servidor: la interfaz es del jugador y se puede tocar.
RegisterNUICallback('gang:avisoBanda', function(datos, cb)
    cb('ok')

    local texto = datos and datos.texto
    if type(texto) ~= 'string' or texto:gsub('%s', '') == '' then return end

    TriggerServerEvent('origen_gang:server:aviso', texto)
end)

--[[ ── La aplicacion de banda del movil ────────────────────────────────────

     La pagina vive en ui/movil/index.html y la enseña el telefono dentro de
     si. Como la sirve este recurso, sus llamadas llegan aqui igual que las
     del panel: no hace falta puente ninguno. ]]

RegisterNUICallback('gang:misInvitaciones', function(_, cb)
    local ok, lista = pcall(function()
        return lib.callback.await('origen_gang:invitaciones', false)
    end)

    cb((ok and type(lista) == 'table') and lista or {})
end)

RegisterNUICallback('gang:responderInvitacion', function(datos, cb)
    local ok, resultado = pcall(function()
        return lib.callback.await('origen_gang:responderInvitacion', false, {
            gangId = datos and datos.gangId,
            acepta = datos and datos.acepta == true,
        })
    end)

    cb(ok and resultado or false)
end)

--[[ ── El escudo de la banda ────────────────────────────────────────────

     Subir una imagen y guardar su direccion. La NUI manda el fichero ya
     leido en base64: leerlo aqui no se puede —en Lua no hay acceso al disco
     del jugador— y ademas es la interfaz la que tiene el selector.

     Los dos van por callback y no por evento porque la interfaz necesita la
     respuesta: la direccion para enseñarla antes de guardar, y el si o el no
     para decir que ha pasado. ]]

RegisterNUICallback('gang:subirEscudo', function(datos, cb)
    --[[ Los bytes no viajan dentro de la llamada: una imagen entera no cabe en
         un evento de red y no fallaba, se perdia. Van antes por el envio
         latente de origen_uploader, que los deja esperando en el servidor con
         un resguardo; aqui solo se manda ese resguardo. El permiso lo sigue
         poniendo el callback de este recurso, que es quien sabe de rangos. ]]
    if GetResourceState('origen_uploader') ~= 'started' then
        cb({ success = false, message = 'El servicio de imágenes no está disponible.' })
        return
    end

    local resguardo, motivo = exports['origen_uploader']:PrepararSubida(
        datos and datos.nombre, datos and datos.base64)

    if not resguardo then
        cb({ success = false, message = motivo or 'No se pudo enviar la imagen.' })
        return
    end

    local ok, res = pcall(function()
        return lib.callback.await('origen_gang:logo:subir', false, {
            ticket = resguardo,
            nombre = datos and datos.nombre,
        })
    end)

    cb((ok and type(res) == 'table') and res or { success = false, message = 'No se pudo subir la imagen.' })
end)

RegisterNUICallback('gang:guardarEscudo', function(datos, cb)
    local ok, res = pcall(function()
        return lib.callback.await('origen_gang:logo:guardar', false, { url = datos and datos.url })
    end)

    cb((ok and type(res) == 'table') and res or { success = false, message = 'No se pudo guardar.' })
end)

--[[ Cuando otro lo cambia.

     El escudo esta en la cabecera del panel de todos los de la banda. Sin
     esto, el que lo sube lo ve al momento y los demas seguirian con el viejo
     hasta reconectar. ]]
RegisterNetEvent('origen_gang:client:logo', function(url)
    SendNUIMessage({ action = 'gangLogo', data = tostring(url or '') })
end)
