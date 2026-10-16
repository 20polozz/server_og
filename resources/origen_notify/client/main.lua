local notifyQueue = {}
local notificationsDisabled = false

--- Los avisos, ademas de donde salgan, entran en el chat como centro de
--- avisos. A false se apaga el eco y el chat vuelve a ser solo chat.
local ECO_AL_CHAT = false

--[[ A DONDE VA CADA AVISO

     Por aqui pasan TODOS: los dos exports, el evento de red y la llamada que se
     intercepta abajo. Por eso el reparto va en este sitio y no en cada uno.

     Y ANTES DE REPARTIRLO, SE FIRMA

     Todo lo que llega lo manda alguien. `remitentes.lua` mira el texto y quien
     lo manda y decide de quien es: la pulsera, el banco, la central de tu
     trabajo. Un aviso sin remitente se lee como un fallo del movil, y de esos
     hay ochocientos.

     Firmado, va a los dos sitios: al CHAT, que es el centro de avisos y lo
     guarda en su pestaña hasta que lo leas, y al TELEFONO, que decide que hace
     con el —si sale, si suena, si se repite—. Los dos con pcall y mirando si
     estan arrancados: ni un chat ni un movil caido pueden llevarse por delante
     los avisos del servidor, que es lo que de verdad no puede fallar.

     Si la firma dice que no —una tecla, el editor de zonas— no es un mensaje
     de nadie: no va ni al chat ni al movil, y sale arriba en el medio, que es
     donde ese hace falta.

     Los de ayuda ni pasan por aqui: el "pulsa E para interactuar" es DrawText y
     vive en su propio fichero. Eso es una tecla que se puede pulsar ahora
     mismo, no algo que contarte. ]]
--[[ De quien es el aviso.

     Se saca UNA vez y la usan los dos destinos: el chat y el telefono. Antes
     se firmaba dentro de la llamada al movil, y con el chat en medio habria
     que recorrer el catalogo dos veces por aviso.

     Con pcall: un fallo de la firma no puede dejar sin avisos al jugador. Y
     mirando antes que `Remitentes` exista, porque a nil reventaria al montar
     los argumentos, que es FUERA del pcall: si `remitentes.lua` no cargara, se
     quedaria el servidor entero sin un solo aviso.

     Devuelve nil para lo que no es un mensaje —una tecla, el editor de
     zonas—: eso no lo manda nadie y sale arriba en el medio, como siempre. ]]
---@param data table
---@param recurso string|nil
---@return table|nil firma
local function firmaDe(data, recurso)
    if type(Remitentes) ~= 'table' then return nil end

    local ok, firma = pcall(Remitentes.De, data, recurso)
    if not ok then return nil end

    return firma or nil
end

--- El color del canto del mensaje en el chat, por lo que el aviso significa.
local COLOR_AVISO = {
    success = '#3ce6a4',
    error   = '#ff4d5e',
    warning = '#f0b429',
    info    = '#56a8ff',
}

--[[ Y ademas, en el chat.

     El chat de ORIGEN es tambien el centro de avisos: lo que te pasa AHORA
     —un cobro, una multa, el hambre— entra en la lista con su remitente y se
     queda ahi, en su pestaña, hasta que lo leas. El telefono sigue guardando
     el historial, que es lo que sabe hacer.

     Va antes que el telefono y no dentro de el a proposito: el aviso tiene que
     quedar registrado tambien cuando el movil no se hace cargo. Y con pcall y
     mirando si el recurso esta arrancado, por lo mismo que el movil: un chat
     caido no puede llevarse por delante los avisos. ]]
---@param firma table
---@param data table
local function alChat(firma, data)
    if not ECO_AL_CHAT then return end
    if GetResourceState('origen_chat') ~= 'started' then return end

    pcall(function()
        exports.origen_chat:addMessage({
            title    = firma.titulo,
            args     = { firma.cuerpo },
            type     = data.type,
            channel  = 'aviso',
            barColor = COLOR_AVISO[data.type] or '#949494',
        })
    end)
end

---@param firma table
---@param firma table
---@param data table
---@return boolean seHaceCargoElTelefono
local function alTelefono(firma, data)
    if GetResourceState('origen_phone') ~= 'started' then return false end

    local ok, cargo = pcall(function()
        return exports.origen_phone:ShowServerNotification({
            title       = firma.titulo,
            description = firma.cuerpo,
            app         = firma.app,
            type        = data.type,
            duration    = data.duration,
        })
    end)

    --- Si la llamada revienta, el aviso se queda aqui: mejor arriba que en ningun sitio.
    return ok and cargo == true
end

---@param data table
---@param recurso string|nil quien ha llamado, cuando se sabe
local function sendNotification(data, recurso)
    if notificationsDisabled then
        --- Con quien lo mandaba: al vaciar la cola ya no hay forma de saberlo.
        notifyQueue[#notifyQueue + 1] = { data = data, recurso = recurso }
        return
    end

    --[[ Firmado una vez, repartido a los dos.

         Si no hay firma esto no es un mensaje de nadie —una tecla, una
         herramienta del editor—: ni al chat ni al movil, sale arriba.

         Y si el telefono se hace cargo, aqui no se pinta nada: el aviso se
         MUEVE al movil, no se copia, que verlo arriba y abajo a la vez es
         leer dos veces lo mismo. El chat es otra cosa: alli no interrumpe,
         se queda en la lista.

         Cuando el movil dice que no —no lo lleva encima, lo tiene apagado—
         sale arriba como toda la vida. Nadie se queda sin avisos por no
         llevar movil. ]]
    local firma = firmaDe(data, recurso)

    if firma then
        alChat(firma, data)

        if alTelefono(firma, data) then return end
    end

    --[[ Y arriba, con la misma firma.

         La tarjeta lleva SIEMPRE un titulo encima. Antes se le pasaba el aviso
         tal cual, y como ocho de cada diez llegan sin titulo, el hambre salia
         pelada mientras en el movil ponia "Smartband". Ahora lleva lo mismo
         que el telefono: el remitente de titulo y el cuerpo ya limpio (con el
         titulo propio delante cuando decia algo, ver Remitentes.De).

         Copia y no el aviso original: la cola de `disableNotifications` y
         quien lo mando siguen teniendo el suyo sin tocar. Y `message` a nil
         porque la interfaz lo lee antes que `description`. ]]
    local aviso = data

    if firma then
        aviso = {}
        for k, v in pairs(data) do aviso[k] = v end
        aviso.title       = firma.titulo
        aviso.description = firma.cuerpo
        aviso.message     = nil
        aviso.text        = nil
    end

    SendNUIMessage({
        action = 'sendNotification',
        data = aviso
    })
end

--[[ Quien llama, para saber de quien es el aviso.

     `GetInvokingResource` solo dice la verdad DENTRO de la llamada del export,
     asi que se lee aqui y se arrastra hacia dentro. Ocho de cada diez avisos
     del servidor llegan sin titulo, y el recurso que los manda es lo unico que
     queda para saber quien los firma.

     Y llega vacio cuando el aviso viene del evento de red o de dentro de este
     mismo recurso. No pasa nada: entonces manda lo que diga el texto. ]]
--[[ Y aguantando que le pasen el texto suelto.

     Hay tres sitios en el servidor que llaman asi:

         exports.origen_notify:Notify('No hay ningun vehiculo cerca', 'error')

     Eso nunca ha salido en pantalla. `data.description` sobre un texto da nil
     —en Lua indexar una cadena no revienta, devuelve nada— asi que el aviso se
     mandaba a la interfaz sin nada que enseñar y se perdia por el camino, sin
     error en consola ni nada que mirar.

     Se recoge aqui y no en los tres sitios porque manteniendo la puerta
     estrecha vuelve a pasar: el siguiente que llame con un texto tampoco vera
     su aviso. ]]
local function desdeFuera(data, tipo, duracion)
    if type(data) == 'string' then
        data = {
            description = data,
            type = type(tipo) == 'string' and tipo or 'info',
            duration = type(duracion) == 'number' and duracion or 5000,
        }
    end

    --[[ `recurso` puesto a mano gana.

         Lo pone quien hace de intermediario y sabe algo que aqui no se puede
         saber: `qbx_core` recibe el aviso de otro recurso y lo reenvia, asi
         que desde aqui el que ha llamado es el, y el bueno se habria perdido.
         Son ciento catorce avisos. ]]
    local recurso = type(data) == 'table' and type(data.recurso) == 'string' and data.recurso or nil

    sendNotification(data, recurso or GetInvokingResource())
end

exports('showNotification', desdeFuera)
exports('Notify', desdeFuera)

--[[ Bajar la pila para un cartel de arriba.

     Los avisos salen arriba en el medio, justo donde otros recursos ponen su
     cartel grande (el del torneo de caza), y se pisaban. Quien pinta el cartel
     dice cuántos píxeles ocupa desde el borde de arriba y la pila baja por
     debajo; con 0 vuelve a su sitio.

         exports.origen_notify:ApartarArriba(150)   -- cartel a la vista
         exports.origen_notify:ApartarArriba(0)     -- cartel ido

     Se apunta quién lo pidió: si ese recurso se para con el cartel puesto,
     nadie devolvería la pila y se quedaría abajo para siempre. ]]
local apartadoPor = nil

exports('ApartarArriba', function(px)
    px = tonumber(px) or 0
    apartadoPor = px > 0 and GetInvokingResource() or nil
    SendNUIMessage({ action = 'apartarArriba', px = px })
end)

AddEventHandler('onClientResourceStop', function(res)
    if apartadoPor and res == apartadoPor then
        apartadoPor = nil
        SendNUIMessage({ action = 'apartarArriba', px = 0 })
    end
end)

RegisterNetEvent('origen_notify:SendNotification', function(data)
    sendNotification(data)
end)

--[[ Dos nombres que usan otros recursos y que antes no escuchaba nadie (los
     avisos no salian: unos 137, casi todos del panel de admin):
       origen_notify:client:Notify  (tipo, titulo, texto)   origen_admin, carboosting, anticheat, policia
       origen_notify:Notify         (texto, tipo)           origen_clothing
     Tambien admiten una tabla { title, description, type, duration }. ]]
local TIPOS = { error = true, success = true, info = true, warning = true, primary = true, inform = true }

RegisterNetEvent('origen_notify:client:Notify', function(a, b, c, d)
    if type(a) == 'table' then return sendNotification(a) end
    if TIPOS[a] then
        if c == nil then return sendNotification({ type = a, description = b, duration = 5000 }) end
        return sendNotification({ type = a, title = b, description = c, duration = tonumber(d) or 5000 })
    end
    sendNotification({ description = a, type = TIPOS[b] and b or 'primary', title = c, duration = 5000 })
end)

RegisterNetEvent('origen_notify:Notify', function(a, b, c)
    if type(a) == 'table' then return sendNotification(a) end
    sendNotification({ description = a, type = TIPOS[b] and b or 'primary', duration = tonumber(c) or 5000 })
end)

exports("disableNotifications", function(disable, ignoreQueue)
    notificationsDisabled = disable
    if disable then
        return
    end
    if not ignoreQueue then
        for _, guardado in ipairs(notifyQueue) do
            sendNotification(guardado.data, guardado.recurso)
        end
    end
    notifyQueue = {}
end)

--[[ El logo OGN de arriba a la derecha cae en el mismo canto que los menus
     laterales (inventario, animaciones, radial...) y se veia por encima o a
     traves de ellos. Se aparta con las mismas dos señales que el rastreador
     de misiones de origen_quests (quests2.lua):

     - porAviso: 'qv2:suppressHud' (radial de origen_hud, animaciones...) y
       'origen_inventory:abierto'. Una sola bandera, como alli: el radial pide
       ocultar y, si se va al inventario, quien lo devuelve es el inventario.
     - porFoco: cualquier interfaz con el foco del raton. Las que dejan pasar
       el teclado al juego no siempre cuentan, por eso existe la primera. ]]
local porAviso, porFoco, logoOculto = false, false, nil

--[[ - porCarrera: mientras se corre una carrera de origen_racing. Su HUD pone
       la clasificacion justo en ese canto y el logo se le montaba encima. Lo
       avisa origen_racing con 'origen_racing:enCarrera' (client/racing.lua).
       NO vale 'origen_hud:setRacingMode': racing solo lo lanza para APAGAR,
       nunca para encender. ]]
local porCarrera = false

--[[ - porAjustes (07/10): con el menu de Ajustes abierto (origen_ajustes lanza
       TriggerEvent('origen:ajustes', bool)) solo se ve el menu. ]]
local porAjustes = false

local function enviarLogo()
    local ocultar = porAviso or porFoco or porCarrera or porAjustes
    if ocultar == logoOculto then return end
    logoOculto = ocultar
    SendNUIMessage({ action = 'ocultarLogo', ocultar = ocultar })
end

AddEventHandler('qv2:suppressHud', function(suppress)
    porAviso = suppress == true
    enviarLogo()
end)

AddEventHandler('origen:ajustes', function(abierto)
    porAjustes = abierto == true
    enviarLogo()
end)

AddEventHandler('origen_racing:enCarrera', function(corriendo)
    porCarrera = corriendo == true
    enviarLogo()
end)

AddEventHandler('origen_inventory:abierto', function(abierto)
    porAviso = abierto == true
    enviarLogo()
end)

--[[ IsNuiFocused() solo ve el foco de ESTE recurso: los menus del riel que no
     avisan con evento (mascotas, banda, crew, radio...) dejaban el logo
     asomando entre el panel y el riel. Cada recurso con interfaz carga
     @origen_map/shared/foco.lua, que anuncia 'origen:foco:estado' al coger y
     soltar el raton: con eso se sabe si CUALQUIERA lo tiene. ]]
local focoDeOtros = {}

AddEventHandler('origen:foco:estado', function(recurso, tiene)
    focoDeOtros[recurso] = tiene and true or nil
end)

AddEventHandler('onClientResourceStop', function(res)
    focoDeOtros[res] = nil
end)

CreateThread(function()
    while true do
        porFoco = IsNuiFocused() == true or next(focoDeOtros) ~= nil
        --[[ Se LEE el estado en cada vuelta en vez de fiarse solo del evento:
             un evento que llega mientras este recurso esta reiniciandose se
             pierde, y el logo se quedaba puesto toda la carrera. ]]
        porCarrera = LocalPlayer.state.enCarrera == true
        enviarLogo()
        Wait(150)
    end
end)

-- Si quien lo escondio se para con su menu abierto, nadie lo devolveria.
AddEventHandler('onClientResourceStop', function(res)
    if res == 'origen_inventory' or res == 'origen_hud' or res == 'origen_anims'
        or res == 'origen_zombies' or res == 'origen_clothing' or res == 'origen_fuel' then
        porAviso = false
        enviarLogo()
    end
    if res == 'origen_racing' then
        porCarrera = false
        enviarLogo()
    end
end)

-- Intercepting call lol
RegisterNetEvent("origen_notify:ShowNotification")
AddEventHandler("origen_notify:ShowNotification", function(text, title, business, bimg)
    sendNotification({
        title = title,
        description = text,
        type = 'primary',
        duration = 5000
    })
    
end)