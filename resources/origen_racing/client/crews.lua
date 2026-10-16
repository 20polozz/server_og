-- ========================================
-- ORIGEN RACING - CREWS CLIENTE
-- ========================================


myCrew         = nil
local garageBlip     = nil

-- ── Blip de la base de la crew ────────────────────────────────────────────────
-- La base es la casa de crew de origen_housing (server/base.lua): el blip va en
-- su entrada. Sin casa, no hay blip.
local function RemoveGarageBlip()
    if garageBlip then
        OrigenMapa.Quitar(garageBlip)
    end
    garageBlip = nil
end

local function CreateGarageBlip(crew)
    RemoveGarageBlip()
    if not crew then return end

    CreateThread(function()
        local r = PedirBaseDeCrew and PedirBaseDeCrew() or nil
        local e = r and r.success and r.base and r.base.entrada
        -- La crew puede haber cambiado mientras se preguntaba.
        if not e or not myCrew or myCrew.id ~= crew.id then return end
        RemoveGarageBlip()
        garageBlip = 'base_' .. tostring(crew.id or crew.tag or 'mia')
        OrigenMapa.Poner(garageBlip, {
            x = e.x, y = e.y, z = e.z,
            cat = 'racing',
            icono = 'escudo',
            nombre = ('[' .. (crew.tag or '?') .. '] Base Crew'),
        })
    end)
end

-- ========================================
-- FUNCIONES
-- ========================================

function LoadMyCrew()
    lib.callback('racing:crews:getMyCrew', false, function(response)
        if response.success then
            myCrew = response.crew
            if myCrew then
                LocalPlayer.state.crew_id = myCrew.id
                CreateGarageBlip(myCrew)
            else
                LocalPlayer.state.crew_id = nil
                RemoveGarageBlip()
            end
            SendNUIMessage({
                action = 'updateCrew',
                data = myCrew
            })
        else
            myCrew = nil
            LocalPlayer.state.crew_id = nil
            RemoveGarageBlip()
        end
    end)
end

--[[ ── EL PANEL DE CREW ─────────────────────────────────────────────────

     La columna que se abre al pulsar Crew en el riel del inventario. Es el
     tercer hermano del panel de banda y del de negocio: mismo sitio, mismo
     ancho, mismo riel al canto, y dentro lo que hace falta saber para llevar
     la crew —quien esta conectado, que territorios son tuyos, como va la
     caja— en vez de una lista de opciones sueltas.

     Dos reglas que vienen de haberlo hecho ya dos veces:

       1. El panel se abre SIEMPRE que tengas crew, aunque el resto de los
          datos tarden. Primero se enseña la columna y despues se rellena; si
          se esperase aqui a que conteste el servidor, el boton del riel
          podria quedarse sin hacer nada.

       2. El riel se pide a origen_inventory, que es quien sabe si eres admin,
          si tienes banda o si estas en un coche. Aqui solo se pinta. ]]

local panelAbierto = false

--- La lista de botones del canto la da origen_inventory. Aqui solo se pide.
local function RielDelInventario()
    if GetResourceState('origen_inventory') ~= 'started' then return nil end
    local ok, riel = pcall(function()
        return exports['origen_inventory']:GetRiel('crew')
    end)
    if not ok then return nil end
    return riel
end

--- ¿Pertenece de verdad a una crew? Es lo estricto; para el riel se usa
--- SaleAccesoCrew, que además cuenta el permiso de creación.
local function TieneCrew()
    return myCrew ~= nil
end

exports('TieneCrew', TieneCrew)

--[[ ¿Le han dado permiso para crear una crew?

     Lo sabe el servidor, pero el riel del inventario se pinta en seco —GetRiel
     se llama desde otros paneles y ahi no se puede esperar una respuesta—, asi
     que se pregunta una vez y se guarda. Se vuelve a preguntar cuando un admin
     concede el permiso y cada vez que se abre el panel, que son los dos
     momentos en que el dato cambia o se va a usar. ]]
local puedeCrearCrew = false

local function RefrescarPermisoDeCreacion(despues)
    lib.callback('racing:crews:checkMyPermission', false, function(resp)
        puedeCrearCrew = resp and resp.hasPermission == true
        if despues then despues(puedeCrearCrew) end
    end)
end

--[[ ¿Sale el boton de Crew en el riel?

     Sale teniendo crew y tambien teniendo permiso para crearla: si solo saliera
     con crew, quien acaba de recibir el permiso no tendria por donde usarlo
     —tendria que saberse el comando—, que es justo el momento en que el boton
     hace falta. ]]
exports('SaleAccesoCrew', function()
    return TieneCrew() or puedeCrearCrew
end)

--[[ Cerrar.

     Global a proposito: el panel tambien se cierra desde fuera —al recoger
     el almacen antiguo (client/base.lua), cuando la propia interfaz manda cerrarse con
     ESC—, y si esos caminos no pasasen por aqui, `panelAbierto` se quedaria en
     true y el boton del riel dejaria de abrirlo. ]]
function CerrarPanelCrew(avisarNui)
    --[[ EL FOCO SE SUELTA ANTES QUE NADA, y por fuera del guardia de abajo.

         Ese `if not panelAbierto` descartaba la llamada entera, y con ella el
         SetNuiFocus: con la marca ya en false, la pantalla se iba y el raton
         se quedaba en medio. Quedarse sin panel se arregla volviendo a abrir;
         quedarse sin camara, no. ]]
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if not panelAbierto then return end
    panelAbierto = false

    if avisarNui ~= false then
        SendNUIMessage({ action = 'closeCrewPanel' })
    end
end

--[[ Que la proxima apertura viene de OTRO panel del riel.

     Los siete paneles del riel pintan la misma barra del canto, identica y en
     el mismo sitio. En un relevo esa barra no tiene por que moverse: la de
     aqui aparece ya puesta encima de la que se esta yendo, y lo unico que se
     desliza es la columna.

     Se apunta y no se pasa por argumento porque este panel se abre por comando
     --`crew`--, y un comando no admite argumentos. Vale para UNA apertura. ]]
local relevoEntrante = false

--- Que la interfaz ha confirmado que su columna esta pintada de verdad. Ver el
--- comentario largo en OpenCrewPanel.
local nuiPintada = false

exports('MarcarRelevo', function() relevoEntrante = true end)

--[[ Para que el inventario pueda comprobar, tras pasarle el relevo, que este
     panel llego a abrirse de verdad. Si no, se quedaria con el foco de la NUI
     puesto y ninguna pantalla delante: el raton en medio y la camara sin
     responder. Ver VigilarRelevo en origen_inventory. ]]
exports('EstaAbierto', function()
    return panelAbierto == true
end)

--- Lo mismo para el resto del recurso: los cierres del hub y de las carreras
--- sueltan el foco, que es de todo el recurso, y tienen que saber si este
--- panel sigue delante (SoltarFocoCarreras, en main.lua).
function PanelCrewAbierto()
    return panelAbierto == true
end

--- Sube en cada apertura: el temporizador de pintado de una apertura vieja lo
--- ve cambiado y no cierra la nueva.
local aperturas = 0

function OpenCrewPanel()
    if panelAbierto then return end

    -- Grabando un circuito el recurso no puede tener el raton (admin.lua).
    if GrabandoCircuito and GrabandoCircuito() then
        lib.notify({ title = 'Crew', description = 'Termina o cancela la grabación del circuito primero', type = 'error' })
        return
    end

    --[[ El foco es solo del panel: nada de teclas al juego.

         `SetNuiFocusKeepInput` es un interruptor GLOBAL del cliente y se queda
         como lo dejo el ultimo que lo toco. El inventario lo pone en true a
         proposito —para poder andar mientras lo miras—, asi que al saltar de
         su riel a este panel se heredaba encendido y el personaje daba
         puñetazos al pulsar los botones. Por eso se dice aqui que NO en vez de
         dar por hecho que esta apagado.

         `modo` dice con que pagina abre la columna: la crew que ya tienes o el
         formulario para crearla. Las dos son la misma columna y el mismo riel;
         lo unico que cambia es lo que hay dentro. ]]
    local function Mostrar(modo)
        panelAbierto = true
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({
            action = 'openCrewPanel',
            data   = {
                riel = RielDelInventario(),
                modo = modo or 'panel',
                --[[ Que se llega desde otro panel del riel y su barra sigue en
                     pantalla: la de aqui aparece ya puesta encima en vez de
                     deslizarse, o durante el cruce se verian dos barras
                     moviendose una sobre otra. ]]
                relevo = relevoEntrante,
            },
        })
        relevoEntrante = false

        --[[ ── Y SE COMPRUEBA QUE LA COLUMNA LLEGO A PINTARSE ───────────────

             Mandar el mensaje no prueba nada. Si la interfaz revienta al
             montarse --un dato que llega mal, una lista que no era lista--
             Vue desmonta el trozo roto sin decir nada: queda la pantalla en
             blanco con el foco de la NUI cogido, el raton en medio y nada que
             pulsar. Y desde aqui todo parece correcto, porque `panelAbierto`
             sigue en true.

             Asi que la interfaz contesta cuando se ha pintado de verdad
             --mirando que su columna este en el DOM, no solo que le hayan
             llamado-- y si en un segundo y medio no ha contestado, se cierra
             y se suelta el foco. ]]
        nuiPintada = false
        aperturas = aperturas + 1
        local mia = aperturas

        SetTimeout(1500, function()
            if mia ~= aperturas or not panelAbierto or nuiPintada then return end

            print('^1[origen_racing]^0 El panel de crew no llego a pintarse. Se cierra y se suelta el foco para no dejar el raton preso.')
            CerrarPanelCrew(true)
        end)
    end

    if myCrew then
        Mostrar('panel')
        return
    end

    -- Sin crew en cache se pregunta una vez: puede que el jugador acabe de
    -- entrar y LoadMyCrew todavia no haya contestado.
    lib.callback('racing:crews:getMyCrew', false, function(response)
        if response and response.success and response.crew then
            myCrew = response.crew
            LocalPlayer.state.crew_id = response.crew.id
            Mostrar('panel')
            return
        end

        LocalPlayer.state.crew_id = nil

        -- Sin crew, el panel solo tiene sentido si puedes crear una. Se vuelve
        -- a preguntar en vez de fiarse de lo guardado: entre que se pinto el
        -- riel y se pulso el boton, el permiso puede haberse usado ya.
        RefrescarPermisoDeCreacion(function(puede)
            if puede then
                Mostrar('creacion')
            else
                lib.notify({
                    title = 'Crew',
                    description = 'No perteneces a ninguna crew.',
                    type = 'error',
                    duration = 5000,
                })
            end
        end)
    end)
end

exports('AbrirPanelCrew', OpenCrewPanel)

--[[ El comando que ejecuta el riel del inventario.

     SIN RegisterKeyMapping a proposito, igual que el de negocio: el panel se
     abre desde el riel y de ningun otro sitio. Tenerlo tambien en una tecla
     suelta serian dos caminos que mantener y dos sitios donde se puede quedar
     desincronizado el foco de la NUI. ]]
RegisterCommand('crew', function()
    OpenCrewPanel()
end, false)

--[[ Saltar a otro panel desde el riel. Se suelta el foco antes: los dos
     paneles lo piden para si, y si no se suelta, el que se abre no responde al
     raton.

     El destino se decide por `tipo` y no por una lista de nombres escritos a
     mano: los accesos —admin, banda, negocio, policia, crew— van por
     AbrirAcceso y las pestañas del inventario por AbrirEnPestana. Con la lista
     escrita, cada acceso nuevo obligaba a tocar los cinco paneles y el que se
     olvidaba dejaba un boton que no hacia nada. ]]
--- La interfaz avisa de que su columna esta en el DOM. Sin esto, el cliente no
--- tiene forma de saber si lo que mando llego a pintarse.
RegisterNUICallback('crew:pintado', function(_, cb)
    cb('ok')
    nuiPintada = true
end)

RegisterNUICallback('crew:irDelRiel', function(data, cb)
    cb('ok')

    CerrarPanelCrew(false)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if GetResourceState('origen_inventory') ~= 'started' then return end

    local destino = data and data.id
    if not destino or destino == 'crew' then return end   -- ya estas aqui

    --[[ A los 200 y no a los 150: la columna tarda 260 ms en recogerse, asi
         que abriendo a mitad del recorrido el panel que entra empieza a
         deslizarse mientras este acaba de salir y no queda ni un fotograma de
         pantalla vacia. La barra del canto no se mueve en ningun momento.

         El `true` es el aviso de RELEVO: el que entra pinta su riel ya puesto
         en vez de deslizarlo, porque el de aqui sigue ahi hasta desmontarse. ]]
    CreateThread(function()
        Wait(200)
        if data.tipo == 'acceso' then
            exports['origen_inventory']:AbrirAcceso(destino, true)
        else
            exports['origen_inventory']:AbrirEnPestana(destino, true)
        end
    end)
end)

--[[ Si el vigilante comun (@origen_map/shared/foco.lua) suelta el raton a la
     fuerza, el panel se va con el: si no, quedaba pintado sin raton y con
     `panelAbierto` en true, y el riel no lo volvia a abrir. ]]
OrigenFoco.AlSoltar(function()
    if panelAbierto then CerrarPanelCrew(true) end
end)

--- Si el recurso se para con el panel abierto, el foco se queda pegado y el
--- jugador se queda con el raton y nada delante.
AddEventHandler('onResourceStop', function(recurso)
    if GetCurrentResourceName() ~= recurso then return end
    if panelAbierto then CerrarPanelCrew(false) end
end)

-- ========================================
-- COMANDOS
-- ========================================

--[[ El atajo de siempre para crear la crew.

     Ya no abre una pantalla aparte: abre EL PANEL, que sin crew y con permiso
     entra directo en el formulario. Asi la creacion es una pagina mas de la
     misma columna —con su riel, para poder marcharte— y no otra ventana con
     otro aspecto. ]]
RegisterCommand('createcrew', function()
    if myCrew then
        lib.notify({
            title = 'Crew',
            description = 'Ya perteneces a una crew.',
            type = 'error',
            duration = 5000,
        })
        return
    end

    RefrescarPermisoDeCreacion(function(puede)
        if not puede then
            lib.notify({
                title = 'Sin permiso',
                description = 'No tienes permiso para crear una crew. Pídeselo a un admin.',
                type = 'error',
                duration = 8000
            })
            return
        end
        OpenCrewPanel()
    end)
end, false)

-- ========================================
-- EVENTOS DEL SERVIDOR
-- ========================================

RegisterNetEvent('racing:crews:inviteReceived', function(data)
    -- Notificación: avisar al jugador que hay una invitación esperando
    lib.notify({
        title = 'Invitación a Crew',
        description = string.format(
            '**%s** [%s] te invita.\nAbre el Racing Hub para aceptar o rechazar.',
            data.crewName, data.crewTag
        ),
        type = 'inform',
        duration = 8000,
        icon = 'lucide:users',
        position = 'top-right'
    })

    -- Enviar al panel de invitaciones del Hub (funciona con Hub abierto o cerrado)
    SendNUIMessage({ action = 'crewInviteReceived', data = data })
end)

RegisterNetEvent('racing:crews:memberJoined', function(data)
    lib.notify({
        title = 'Nuevo Miembro',
        description = data.playerName .. ' se ha unido a la crew',
        type = 'success',
        duration = 5000,
        icon = 'lucide:user-plus',
        position = 'top-right'
    })
    -- Recargar crew y actualizar NUI aunque el panel esté abierto
    LoadMyCrew()
end)

--[[ Acabas de crear tu crew.

     Lo manda el servidor al terminar de crearla, tanto la de pago como la del
     permiso. Aqui se recarga todo: sin esto el cliente seguia creyendo que no
     tenias crew hasta el siguiente relog —sin blip de la base— y el boton de Crew del riel volvia a abrir el formulario de crear. ]]
RegisterNetEvent('racing:crews:crewCreated', function(data)
    LoadMyCrew()
    RefrescarPermisoDeCreacion()

    lib.notify({
        title = 'Crew creada',
        description = (data and data.crewName or 'Tu crew') .. ' ya existe. La llevas desde el riel del inventario.',
        type = 'success',
        duration = 8000,
        icon = 'lucide:flag',
        position = 'top-right'
    })
end)

-- Nuevo evento: el jugador actual acaba de unirse a una crew (aceptó invitación)
RegisterNetEvent('racing:crews:crewJoined', function(data)
    lib.notify({
        title = 'Crew Unida',
        description = 'Te has unido a **' .. (data.crewName or 'la crew') .. '**',
        type = 'success',
        duration = 6000,
        icon = 'lucide:users',
        position = 'top-right'
    })
    -- Cargar datos de la crew (LoadMyCrew ya pone el blip de la base si tiene casa)
    LoadMyCrew()
    SendNUIMessage({ action = 'crewJoined', data = data })
end)

RegisterNetEvent('racing:crews:memberLeft', function(data)
    if myCrew then
        lib.notify({
            title = 'Miembro Abandonó',
            description = data.playerName .. ' ha abandonado la crew',
            type = 'info',
            duration = 5000
        })
        LoadMyCrew()
    end
end)

RegisterNetEvent('racing:crews:disbanded', function(crewName)
    lib.notify({
        title = 'Crew Disuelta',
        description = 'La crew "' .. crewName .. '" ha sido disuelta',
        type = 'error',
        duration = 10000
    })
    myCrew = nil
    RemoveGarageBlip()
    SendNUIMessage({
        action = 'crewDisbanded'
    })
end)

RegisterNetEvent('racing:crews:permissionGranted', function()
    -- Lo primero, apuntarlo: es lo que hace aparecer el boton de Crew en el
    -- riel del inventario, que es por donde se va a usar el permiso.
    RefrescarPermisoDeCreacion()

    lib.notify({
        title = 'Permiso concedido',
        description = 'Ya puedes crear tu crew. La tienes en el riel del inventario, en Crew.',
        type = 'success',
        duration = 15000,
        icon = 'lucide:flag',
        position = 'top'
    })
end)

-- (Aqui habia un hilo que cada 3 s apuntaba los jugadores cercanos en una
-- lista que no leia nadie: la de reclutar sale del servidor,
-- racing:crews:getNearbyPlayers.)

-- ========================================
-- EVENTOS DE DISPUTAS
-- ========================================

RegisterNetEvent('racing:disputes:notifyAccepted', function(data)
    
    -- Verificar si pertenezco a alguna de las crews involucradas
    local myCrewId = LocalPlayer.state.crew_id
    
    if myCrewId == data.challenger_crew_id or myCrewId == data.challenged_crew_id then
        local isChallenger = myCrewId == data.challenger_crew_id
        local rivalCrewName = isChallenger and data.challenged_crew_name or data.challenger_crew_name
        local registrationRaw = tonumber(data.registration_time) or 5
        -- Compatibilidad: algunos flujos guardan segundos en vez de minutos.
        local registrationMinutes = registrationRaw > 60 and math.max(1, math.floor(registrationRaw / 60)) or registrationRaw
        
        -- Notificación
        Config.Notify(PlayerId(), 
            string.format('¡Disputa contra %s aceptada! Ve al circuito %s. Tiempo: %d min', 
                rivalCrewName,
                data.circuit_name, 
                registrationMinutes
            ), 
            'success'
        )
        
        -- Crear blip temporal en el punto de salida
        local blip = 'disputa'
        OrigenMapa.Poner(blip, {
            x = data.start_coords.x, y = data.start_coords.y, z = data.start_coords.z,
            cat = 'racing',
            icono = 'bandera',
            nombre = string.format('Disputa vs %s', rivalCrewName),
            ruta = true,
        })
        
        -- Eliminar blip después del tiempo de registro + 1 minuto extra
        --- Quitar el punto se lleva tambien su ruta: el blip invisible que
        --- la sostiene lo crea y lo borra el propio registro.
        SetTimeout((registrationMinutes + 1) * 60 * 1000, function()
            OrigenMapa.Quitar(blip)
        end)
        
        
        -- Actualizar NUI si está abierto
        SendNUIMessage({
            action = 'disputeAccepted',
            data = data
        })
    end
end)

-- ========================================
-- INICIALIZACIÓN
-- ========================================

CreateThread(function()
    local PlayerData = exports.qbx_core:GetPlayerData()
    if PlayerData and PlayerData.citizenid then
        LoadMyCrew()
        RefrescarPermisoDeCreacion()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    LoadMyCrew()
    RefrescarPermisoDeCreacion()
end)

