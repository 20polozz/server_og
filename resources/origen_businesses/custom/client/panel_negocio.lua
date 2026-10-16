--[[
    EL PANEL DE NEGOCIO

    La columna que se abre al pulsar Negocio en el riel del inventario. Es el
    gemelo del panel de banda: mismo sitio, mismo ancho, mismo riel al canto,
    y dentro lo que hace falta saber para trabajar —quien esta fichado, como
    va la caja, que puedes hacer— en vez de una lista de opciones sueltas.

    Tres reglas que vienen de haberlo hecho ya una vez en la banda:

      1. El panel se abre SIEMPRE, aunque el servidor no conteste. Primero se
         enseña la columna y despues se rellena. Un `lib.callback.await` que
         no encuentra su callback registrado —lo normal si el recurso se
         reinicio sin refresh— se planta cinco minutos, y si se esperase aqui
         el boton del riel sencillamente no haria nada.

      2. Si perteneces a varios negocios, primero se elige. La eleccion es
         una pagina mas del mismo panel, no otro menu: el riel no se mueve y
         no parece que hayas salido a otro sitio.

      3. Lo que solo cambia el estado del negocio —fichar, abrir el local— no
         cierra el panel: se hace y se vuelve a pedir el dato. Lo que abre un
         cuadro de dialogo si, que si no sale detras.
]]

local abierto      = false      --- ¿esta la columna en pantalla?

--[[ Que la proxima apertura viene de OTRO panel del riel.

     Los siete paneles del riel pintan la misma barra del canto, identica y en
     el mismo sitio. En un relevo esa barra no tiene por que moverse: la de
     aqui aparece ya puesta encima de la que se esta yendo, y lo unico que se
     desliza es la columna. Si las dos se deslizaran, durante el cruce se
     verian dos barras moviendose una sobre otra.

     Se apunta aqui y no se pasa por argumento porque este panel se abre por
     comando --`negocios_f7`--, y un comando no admite argumentos. Vale para
     UNA apertura: se apaga al usarla, que si se quedara puesto la siguiente
     entrada normal saldria sin animacion sin que nadie sepa por que. ]]
local relevoEntrante = false

--- Que la interfaz ha confirmado que su columna esta pintada de verdad. Ver el
--- comentario largo en AbrirPanel.
local nuiPintada = false

--- Sube en cada apertura: el temporizador de pintado de una apertura vieja lo
--- ve cambiado y no toca la nueva.
local aperturas = 0

exports('MarcarRelevo', function() relevoEntrante = true end)

--[[ Para que el inventario pueda comprobar, tras pasarle el relevo, que este
     panel llego a abrirse de verdad. Si no, se quedaria con el foco de la NUI
     puesto y ninguna pantalla delante: el raton en medio y la camara sin
     responder. Ver VigilarRelevo en origen_inventory. ]]
exports('EstaAbierto', function()
    return abierto == true
end)
local negocioActual = nil       --- el id del negocio que se esta mirando
local accionesMapa  = {}        --- id de accion → la accion entera, con su run
local variosNegocios = false    --- ¿hay a donde volver? decide si sale "Cambiar"

local function Notify(msg, ntype)
    if GetResourceState('origen_notify') == 'started' then
        exports['origen_notify']:Notify({ description = msg, type = ntype or 'inform', duration = 4000 })
    end
end

--- La lista de botones del canto la da origen_inventory, que es quien sabe si
--- estas en un coche, si tienes banda o si eres admin. Aqui solo se pide.
local function RielDelInventario()
    if GetResourceState('origen_inventory') ~= 'started' then return nil end
    local ok, riel = pcall(function()
        return exports['origen_inventory']:GetRiel('negocio')
    end)
    if not ok then return nil end
    return riel
end

-- ─────────────────────────────────────────────────────────────────────────
-- LAS ACCIONES
--
-- Las tres primeras las pone el panel porque dependen de permisos y de si
-- estas fichado; el resto son las del tipo de negocio y las da
-- AccionesNegocio.
-- ─────────────────────────────────────────────────────────────────────────
local function ConstruirAcciones(negocio)
    local permisos = negocio.permisos or {}
    local fichado  = negocio.deServicio == true
    local acciones = {}

    local function meter(a) acciones[#acciones + 1] = a end

    -- Fichar es lo unico que se puede hacer sin estar fichado, asi que va
    -- primero y nunca esta apagado.
    meter({
        id     = 'duty',
        label  = fichado and 'Salir' or 'Fichar',
        desc   = fichado and 'Salir de servicio en este negocio'
                         or 'Entrar de servicio en este negocio',
        icon   = fichado and 'lucide:log-out' or 'lucide:log-in',
        peligro = fichado,
        cierra = false,
    })

    if permisos.abrirLocal then
        meter({
            id     = 'local',
            label  = negocio.abierto and 'Cerrar' or 'Abrir',
            desc   = negocio.abierto and 'Cerrar el local al público'
                                     or 'Abrir el local al público',
            icon   = negocio.abierto and 'lucide:door-closed' or 'lucide:door-open',
            -- El servidor exige estar de servicio para tocar el cartel; el
            -- boton lo dice antes de que te lo diga el error.
            disabled = not fichado,
            cierra = false,
        })
    end

    if permisos.facturas then
        meter({
            id       = 'factura',
            label    = 'Factura',
            desc     = 'Emitir una factura a un jugador',
            icon     = 'lucide:receipt-text',
            disabled = not fichado,
            cierra   = true,
        })
    end

    for _, a in ipairs(AccionesNegocio.DelTipo(negocio.id, negocio.tipo)) do
        -- Las del oficio piden estar trabajando: reparar un coche o abrir la
        -- central de taxis sin haber fichado no es media accion, es ninguna.
        a.disabled = a.disabled or not fichado
        meter(a)
    end

    -- El mapa es lo que permite que la interfaz mande solo un id de vuelta.
    accionesMapa = {}
    local paraNui = {}
    for i, a in ipairs(acciones) do
        accionesMapa[a.id] = a
        paraNui[i] = {
            id       = a.id,
            label    = a.label,
            desc     = a.desc,
            icon     = a.icon,
            peligro  = a.peligro == true,
            disabled = a.disabled == true,
        }
    end

    return paraNui
end

-- ─────────────────────────────────────────────────────────────────────────
-- LA PLANTILLA, VISTA DESDE AQUI
--
-- El servidor manda donde esta cada uno en coordenadas crudas. La distancia
-- y el nombre del barrio se resuelven aqui: la primera porque quien pregunta
-- se mueve, y el segundo porque GetNameOfZone solo existe en el cliente.
-- ─────────────────────────────────────────────────────────────────────────
local function ColocarPlantilla(plantilla)
    local yo = GetEntityCoords(PlayerPedId())
    local salida = {}

    for _, e in ipairs(plantilla or {}) do
        local fila = {
            cid        = e.cid,
            nombre     = e.nombre,
            rango      = e.rango,
            online     = e.online == true,
            deServicio = e.deServicio == true,
            soyYo      = e.soyYo == true,
            zona       = '',
            -- A nil y no a cero: cero seria "lo tienes encima", que es justo
            -- lo contrario de no saber donde esta.
            distancia  = nil,
        }

        if e.online and e.x then
            local donde = vector3(e.x, e.y or 0.0, e.z or 0.0)
            fila.distancia = #(yo - donde)
            fila.zona = GetLabelText(GetNameOfZone(donde.x, donde.y, donde.z))
        end

        salida[#salida + 1] = fila
    end

    --[[ Primero los que estan fichados, luego el resto de conectados por
         cercania, y al final los que no estan. Es el orden en que te hacen
         falta: con quien trabajas, quien anda por ahi y quien falta. ]]
    table.sort(salida, function(a, b)
        if a.deServicio ~= b.deServicio then return a.deServicio end
        if a.online ~= b.online then return a.online end
        if a.online then return (a.distancia or 0) < (b.distancia or 0) end
        return (a.nombre or '') < (b.nombre or '')
    end)

    return salida
end

-- ─────────────────────────────────────────────────────────────────────────
-- PEDIR Y PINTAR
-- ─────────────────────────────────────────────────────────────────────────
local function MandarNui(accion, datos)
    SendNUIMessage({ action = accion, data = datos })
end

--- Los datos de un negocio, ya listos para la interfaz. Va en su propio hilo
--- y despues de haber abierto: si el servidor tarda, lo unico que pasa es que
--- la columna se queda un momento en "cargando".
local function PedirNegocio(businessId)
    CreateThread(function()
        local ok, datos = pcall(function()
            return lib.callback.await('origen_businesses:cb:panelNegocio:datos', false, businessId)
        end)

        if not abierto then return end

        if not ok or type(datos) ~= 'table' then
            -- A pelo y no con el modo depuracion: si esto falla el panel se
            -- queda vacio y hay que enterarse igual.
            print(('^1[origen_businesses] El panel de negocio no contestó: %s^0'):format(tostring(datos)))
            MandarNui('negocio:error', { texto = 'No se pudieron cargar los datos del negocio.' })
            return
        end

        negocioActual = datos.id
        datos.plantilla = ColocarPlantilla(datos.plantilla)

        local etiqueta = AccionesNegocio.Etiqueta(datos.tipo)
        datos.tipoLabel = etiqueta.label
        datos.tipoIcon  = etiqueta.icon
        datos.puedeCambiar = variosNegocios

        MandarNui('negocio:datos', {
            negocio  = datos,
            acciones = ConstruirAcciones(datos),
        })
    end)
end

--- Volver a pedirlos sin parpadeo: la columna se queda como esta y se
--- reemplaza cuando llega lo nuevo. Es lo que se hace despues de fichar o de
--- abrir el local.
local function Refrescar()
    if not abierto or not negocioActual then return end
    PedirNegocio(negocioActual)
end

local function CerrarPanel(avisarNui)
    --[[ EL FOCO SE SUELTA ANTES QUE NADA, y por fuera del guardia de abajo.

         Ese `if not abierto` descartaba la llamada entera, y con ella el
         SetNuiFocus. Con `abierto` ya en false --dos cierres seguidos, un eco
         de la NUI, una accion que cerro por su cuenta-- la pantalla se iba y
         el raton se quedaba en medio, con la camara sin responder.

         Quedarse sin panel se arregla volviendo a abrir. Quedarse sin camara,
         no. Asi que esto va primero y sin condiciones. ]]
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if not abierto then return end

    abierto = false
    negocioActual = nil
    accionesMapa = {}

    if avisarNui then MandarNui('negocio:cerrar', {}) end
end

--[[ Abrir.

     `businessId` puede venir dado —desde el panel de pausa, por ejemplo— o
     no venir, que es lo normal desde el riel. Sin el, se mira a cuantos
     negocios perteneces: con uno se entra directo y con varios se elige. ]]
local function AbrirPanel(businessId, pestana)
    if abierto then return end

    local ok, lista = pcall(function()
        return lib.callback.await('origen_businesses:cb:panelNegocio:lista', false)
    end)

    if not ok or type(lista) ~= 'table' or #lista == 0 then
        -- No pertenece a ningún negocio: no abrir ni robar foco
        return
    end

    abierto = true

    --[[ El foco es solo del panel: nada de teclas al juego.

         `SetNuiFocusKeepInput` es un interruptor GLOBAL del cliente y se queda
         como lo dejo el ultimo que lo toco. El inventario lo pone en true a
         proposito —para poder andar y hablar mientras lo miras, y a cambio
         apaga a mano los controles de golpear—, asi que al saltar de su riel a
         este panel se heredaba encendido: se movia la camara por detras y el
         personaje daba puñetazos al pulsar los botones.

         Por eso se dice aqui que NO, en vez de dar por hecho que esta apagado.
         Cada panel declara el foco que quiere. ]]
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    --[[ `pestana` es por donde entrar en vez de por Acciones. La usa la vuelta
         de las cámaras: al dejar de mirar vuelves a la lista de cámaras, no a
         la portada. ]]
    MandarNui('negocio:abrir', { riel = RielDelInventario(), relevo = relevoEntrante, pestana = pestana })
    relevoEntrante = false

    --[[ ── Y SE COMPRUEBA QUE LA COLUMNA LLEGO A PINTARSE ───────────────────

         Mandar el mensaje no prueba nada. Si la interfaz revienta al montarse
         --un dato que llega mal, una lista que no era lista-- Vue desmonta el
         trozo roto sin decir nada: queda la pantalla en blanco con el foco de
         la NUI cogido, el raton en medio y nada que pulsar. Y desde aqui todo
         parece correcto, porque `abierto` sigue en true.

         Asi que la interfaz contesta cuando se ha pintado de verdad --mirando
         que su columna este en el DOM, no solo que le hayan llamado-- y si en
         un segundo y medio no ha contestado, se cierra y se suelta el foco. ]]
    nuiPintada = false

    -- Con su vuelta: cerrar y reabrir dentro del segundo y medio dejaba vivo
    -- el temporizador de la apertura anterior, que cerraba la nueva antes de
    -- que llegara a confirmar que se habia pintado.
    aperturas = aperturas + 1
    local mia = aperturas

    SetTimeout(1500, function()
        if mia ~= aperturas or not abierto or nuiPintada then return end

        print('^1[origen_businesses]^0 El panel de negocio no llego a pintarse. Se cierra y se suelta el foco para no dejar el raton preso.')
        CerrarPanel(true)
    end)

    variosNegocios = #lista > 1

    -- Con el negocio ya decidido —o con uno solo— no hay nada que elegir.
    local destino = nil
    if businessId then
        for _, n in ipairs(lista) do
            if n.id == tostring(businessId) then destino = n.id break end
        end
    end
    if not destino and #lista == 1 then destino = lista[1].id end

    if destino then
        PedirNegocio(destino)
        return
    end

    -- Al selector se le pone el icono de cada tipo aqui: el servidor
    -- manda el tipo y quien sabe con que se dibuja es el catalogo.
    for _, n in ipairs(lista) do
        n.tipoLabel = AccionesNegocio.Etiqueta(n.tipo).label
        n.tipoIcon  = AccionesNegocio.Etiqueta(n.tipo).icon
    end

    MandarNui('negocio:elegir', { lista = lista })
end

exports('AbrirPanelNegocio', AbrirPanel)

--[[ Para los otros módulos del cliente que salen del panel y vuelven a él (las
     cámaras de seguridad: source/client/camaras.lua). ]]
PanelNegocio = {
    Abrir = AbrirPanel,
    Cerrar = CerrarPanel,
}

--[[ El comando que ejecuta el riel del inventario.

     SIN RegisterKeyMapping a proposito: el panel de negocios se abre desde el
     riel del inventario y de ningun otro sitio. Tenerlo tambien en una tecla
     suelta significa dos caminos que hay que mantener y dos sitios donde se
     puede quedar desincronizado el foco de la NUI —que es justo lo que
     provocaba los puñetazos al pulsar—.

     El comando se queda registrado porque es lo que ejecuta el riel. ]]
RegisterCommand('negocios_f7', function()
    AbrirPanel(nil)
end, false)

-- ─────────────────────────────────────────────────────────────────────────
-- LO QUE MANDA LA INTERFAZ
-- ─────────────────────────────────────────────────────────────────────────
--- La interfaz avisa de que su columna esta en el DOM. Sin esto, el cliente no
--- tiene forma de saber si lo que mando llego a pintarse.
RegisterNUICallback('negocioPintado', function(_, cb)
    cb('ok')
    nuiPintada = true
end)

RegisterNUICallback('negocioCerrar', function(_, cb)
    cb('ok')
    CerrarPanel(false)
end)

RegisterNUICallback('negocioElegir', function(data, cb)
    cb('ok')
    local id = data and data.id
    if not id or not abierto then return end
    PedirNegocio(tostring(id))
end)

--- Volver al selector. Solo sale cuando de verdad hay entre que elegir.
RegisterNUICallback('negocioVolver', function(_, cb)
    cb('ok')
    if not abierto or not variosNegocios then return end

    negocioActual = nil
    CreateThread(function()
        local ok, lista = pcall(function()
            return lib.callback.await('origen_businesses:cb:panelNegocio:lista', false)
        end)
        if not abierto or not ok or type(lista) ~= 'table' then return end

        for _, n in ipairs(lista) do
            n.tipoLabel = AccionesNegocio.Etiqueta(n.tipo).label
            n.tipoIcon  = AccionesNegocio.Etiqueta(n.tipo).icon
        end
        MandarNui('negocio:elegir', { lista = lista })
    end)
end)

--[[ La ficha entera del negocio: el mismo objeto que come el cuadro de mando.

     El panel trae lo suyo —quien esta donde, los movimientos, el registro—,
     pero las pestañas de almacen, pedidos, vehiculos, anuncios y ajustes
     necesitan la plantilla de grados, los puntos, el catalogo y el mensaje de
     apertura. Eso ya lo devuelve `getManagementData` armado, y volver a
     montarlo aqui seria una segunda version del mismo objeto que se separaria
     de la primera al primer cambio.

     Va aparte del panel porque cuesta mas y no hace falta para pintar la
     portada: se pide en cuanto se abre, y las pestañas que lo necesitan
     esperan a que llegue. ]]
RegisterNUICallback('negocioFicha', function(data, cb)
    local id = (data and data.id) or negocioActual
    if not id then cb(nil) return end

    local ok, ficha = pcall(function()
        return lib.callback.await('origen_businesses:cb:getManagementData', false, id, false)
    end)

    --[[ La cocina: qué muebles hay y si este negocio la coloca desde aquí. Un
         restaurante sin límite de cocina puesto tiene hueco para una, igual
         que cuenta el servidor en Business:AddPoint. ]]
    if ok and type(ficha) == 'table' and type(ficha.business) == 'table' then
        local colocable = Config.Cocina.TiposQueLaColocan[ficha.business.type] == true
        ficha.cocina = { muebles = Config.Cocina.ParaInterfaz(), colocable = colocable }
        if colocable then
            ficha.business.available_points = ficha.business.available_points or {}
            if ficha.business.available_points.kitchen == nil then
                ficha.business.available_points.kitchen = 1
            end
        end

        --[[ Las cámaras de seguridad: los modelos que se pueden colgar y, sin
             límite de la administración, el hueco por defecto, igual que lo
             cuenta el servidor en Business:AddPoint. ]]
        ficha.camaras = { modelos = Config.Camaras.Modelos }
        -- Las plantillas de documentos (config/documentos.lua).
        ficha.documentos = { plantillas = Config.Documentos.Plantillas }
        ficha.business.available_points = ficha.business.available_points or {}
        if ficha.business.available_points.camera == nil then
            ficha.business.available_points.camera = Config.Camaras.PorDefecto
        end
    end

    cb((ok and ficha) or nil)
end)

--[[ Subir el logo desde el ordenador del jugador.

     La interfaz manda la imagen ya en base64 y sin la cabecera `data:`. De la
     NUI a aqui no hay red, asi que da igual lo que pese; la pared estaba en el
     salto siguiente, al servidor, donde un evento normal no aguanta una imagen
     entera: no fallaba, se perdia, y el dialogo se quedaba en "Subiendo" para
     siempre. Ese era el motivo del tope de 1 MB.

     Ahora los bytes van por origen_uploader, que los manda en un envio latente
     y los deja esperando en el servidor con un resguardo. Lo que viaja dentro
     de la llamada es solo ese resguardo. El permiso sigue donde estaba: lo
     pone el callback del servidor de este recurso, no el uploader. ]]
RegisterNUICallback('negocioSubirLogo', function(data, cb)
    local id = (data and data.businessId) or negocioActual
    if not id or not data or not data.base64 then
        cb({ success = false, message = 'No llegó la imagen.' })
        return
    end

    if GetResourceState('origen_uploader') ~= 'started' then
        cb({ success = false, message = 'El servicio de imágenes no está disponible.' })
        return
    end

    local resguardo, motivo = exports['origen_uploader']:PrepararSubida(data.nombre, data.base64)
    if not resguardo then
        cb({ success = false, message = motivo or 'No se pudo enviar la imagen.' })
        return
    end

    local ok, res = pcall(function()
        return lib.callback.await('origen_businesses:cb:panelNegocio:logo', false, {
            businessId = id,
            ticket     = resguardo,
            nombre     = data.nombre,
        })
    end)

    cb((ok and res) or { success = false, message = 'No se pudo subir la imagen.' })
end)

--[[ Ofrecer el puesto.

     No contrata: manda la oferta. Quien la recibe la ve en el móvil y la
     acepta o la rechaza, y hasta entonces no entra en plantilla. ]]
RegisterNUICallback('negocioOfertar', function(data, cb)
    local id = (data and data.businessId) or negocioActual
    if not id then cb({ success = false, message = 'No hay negocio.' }) return end

    local ok, res = pcall(function()
        return lib.callback.await('origen_businesses:cb:panelNegocio:ofertar', false, {
            businessId = id,
            targetId   = data and data.targetId,
            grade      = data and data.grade,
        })
    end)

    cb((ok and res) or { success = false, message = 'No se pudo enviar la oferta.' })
end)

RegisterNUICallback('negocioRefrescar', function(_, cb)
    cb('ok')
    Refrescar()
end)

--[[ Una accion.

     Las que cierran el panel lo cierran ANTES de hacer nada: casi todas
     acaban abriendo otra cosa que pide el foco de la NUI, y si el panel
     siguiera puesto se lo quitaria. Las que no cierran se hacen y se refresca
     la columna, que es lo que las hace legibles: pulsas Fichar y ves cambiar
     la cabecera. ]]
RegisterNUICallback('negocioAccion', function(data, cb)
    cb('ok')

    local accion = data and data.id and accionesMapa[data.id]
    if not accion or accion.disabled then return end

    local negocioId = negocioActual

    --[[ Se avisa a la interfaz al cerrar: la orden vino de ella, pero es Lua
         quien sabe si esta accion cierra o no. Sin el aviso, la columna se
         quedaba pintada encima del cuadro de dialogo que abre la accion. ]]
    if accion.cierra then
        CerrarPanel(true)
    end

    CreateThread(function()
        if accion.id == 'duty' then
            local res = lib.callback.await('origen_businesses:cb:toggleDuty', false, negocioId)
            if res and res.success == false and res.message then
                Notify(res.message, 'error')
            end
            Refrescar()
            return
        end

        if accion.id == 'local' then
            local res = lib.callback.await('origen_businesses:cb:toggleBusinessState', false, negocioId)
            if res and res.success == false and res.message then
                Notify(res.message, 'error')
            end
            Refrescar()
            return
        end

        if accion.id == 'factura' then
            AccionesNegocio.Factura(negocioId)
            return
        end

        if type(accion.run) == 'function' then
            local ok, err = pcall(accion.run)
            if not ok then
                print(('^1[origen_businesses] La acción %s falló: %s^0'):format(tostring(accion.id), tostring(err)))
            end
            if not accion.cierra then Refrescar() end
        end
    end)
end)

--[[ Los dos botones de la caja.

     La cantidad la pide el propio panel, con su cuadro (Dialogo.vue), y llega
     ya escrita. Aqui no se abre nada ni se toca el foco: el cuadro de ox_lib
     que habia antes salia encima con otro aspecto y obligaba a soltar y
     recuperar el foco, que es justo donde se quedaba el raton preso.

     Lo que se mira aqui es solo para no molestar al servidor con algo que no
     es un numero; quien decide es el servidor —permiso, cantidad, ritmo y que
     estes en el local—. La respuesta vuelve a la interfaz tal cual, para que
     el cuadro enseñe el error debajo del campo o se cierre si fue bien. ]]
local TOPE_CAJA = 1000000000

RegisterNUICallback('negocioCaja', function(data, cb)
    local tipo = data and data.tipo
    local negocioId = negocioActual

    if not abierto or not negocioId or (tipo ~= 'in' and tipo ~= 'out') then
        cb({ success = false, message = 'No hay negocio abierto.' })
        return
    end

    local cantidad = tonumber(data.cantidad)
    if not cantidad or cantidad ~= cantidad or cantidad ~= math.floor(cantidad)
        or cantidad <= 0 or cantidad > TOPE_CAJA then
        cb({ success = false, message = 'Escribe una cantidad entera mayor que cero.' })
        return
    end

    local ok, res = pcall(function()
        return lib.callback.await(
            tipo == 'in' and 'origen_businesses:cb:deposit' or 'origen_businesses:cb:withdraw',
            false, { business = negocioId, amount = math.floor(cantidad) })
    end)

    if not ok or type(res) ~= 'table' then
        cb({ success = false, message = 'No se pudo hacer el movimiento.' })
        return
    end

    cb({
        success    = res.success == true,
        message    = res.message,
        newBalance = res.newBalance,
    })

    -- Con exito cambia el saldo y los movimientos; sin el, puede haber
    -- cambiado si estas o no en el local. En los dos casos se vuelve a pedir.
    Refrescar()
end)

--[[ Saltar a otro panel desde el riel. Se suelta el foco antes: los dos
     paneles lo piden para si, y si no se suelta el que se abre no responde al
     raton. ]]
RegisterNUICallback('negocioRiel', function(data, cb)
    cb('ok')
    -- Cerrar antes de mirar el inventario: la NUI ya se ha ido, y sin el
    -- inventario arrancado el foco se quedaba puesto.
    CerrarPanel(false)
    if GetResourceState('origen_inventory') ~= 'started' then return end

    SetNuiFocus(false, false)

    local destino = data and data.id
    if not destino or destino == 'negocio' then return end

    --[[ A los 200 y no a los 150: la columna tarda 260 ms en recogerse, asi
         que abriendo a mitad del recorrido el panel que entra empieza a
         deslizarse mientras este acaba de salir y no queda ni un fotograma de
         pantalla vacia. La barra del canto no se mueve en ningun momento.

         El `true` es el aviso de RELEVO: el que entra pinta su riel ya puesto
         en vez de deslizarlo, porque el de aqui sigue ahi hasta desmontarse. ]]
    CreateThread(function()
        Wait(200)
        if destino == 'admin' or destino == 'banda' or destino == 'crew' or destino == 'policia'
            or destino == 'mascotas' or destino == 'radio' then
            exports['origen_inventory']:AbrirAcceso(destino, true)
        else
            exports['origen_inventory']:AbrirEnPestana(destino, true)
        end
    end)
end)

--[[ Si el vigilante comun (@origen_map/shared/foco.lua) suelta el raton a la
     fuerza --pantalla vacia, colgada o el comando `raton`--, el panel se va
     con el. Si no, quedaba pintado sin raton y con `abierto` en true, y el
     guardia de AbrirPanel no dejaba volver a abrirlo. ]]
OrigenFoco.AlSoltar(function()
    if not abierto then return end
    abierto = false
    negocioActual = nil
    accionesMapa = {}
    MandarNui('negocio:cerrar', {})
end)

--- Si el recurso se para con el panel abierto, el foco se queda pegado y el
--- jugador se queda con el raton y nada delante.
AddEventHandler('onResourceStop', function(recurso)
    if GetCurrentResourceName() ~= recurso then return end
    if abierto then CerrarPanel(false) end
end)
