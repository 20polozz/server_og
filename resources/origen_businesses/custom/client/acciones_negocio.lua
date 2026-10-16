--[[
    LAS ACCIONES DEL NEGOCIO

    Lo que se puede hacer estando en un negocio, en una sola lista. Antes esto
    era el menu F7: una lista de org-menu que se armaba en el momento de
    abrirla y en la que el texto, el icono y lo que hacia cada linea iban
    juntos en el mismo sitio.

    Ahora quien las pinta es el panel de negocio —la columna del riel del
    inventario—, asi que aqui solo se DICE cuales hay y que hace cada una. La
    forma es siempre la misma:

        { id, label, desc, icon, peligro, cierra, run(businessId) }

      · label  va corto: cabe en una ficha de la rejilla, cuatro por fila.
      · desc   es la frase larga, la que sale al dejar el raton encima.
      · cierra dice si el panel se quita de en medio al pulsarla. Las que
        abren un cuadro de dialogo lo necesitan; las que solo cambian un
        estado del propio negocio no, y ahi se queda abierto y se refresca.

    El fichar y el abrir el local no estan aqui: los pone el panel, porque
    dependen de permisos y de si estas de servicio, que es cosa suya.
]]

local function Notify(msg, ntype)
    if GetResourceState('origen_notify') == 'started' then
        exports['origen_notify']:Notify({ description = msg, type = ntype or 'inform', duration = 4000 })
    end
end

--[[ Los avisos de dispatch de Weazel. Es un interruptor que vive en el
     servidor y del que el cliente lleva copia para saber como pintar el
     boton: si dice "activar" o "desactivar". ]]
local weazelDispatchAlertsEnabled = false

RegisterNetEvent('origen_police:client:setReporterDispatchSubscription', function(enabled)
    weazelDispatchAlertsEnabled = enabled == true
end)

-- ─────────────────────────────────────────────────────────────────────────
-- EMITIR FACTURA · comun a cualquier negocio
-- ─────────────────────────────────────────────────────────────────────────
local function OpenInvoiceDialog(businessId)
    local input = exports['org-input']:ShowInput({
        header     = 'Emitir Factura',
        submitText = 'Enviar Factura',
        icon       = 'fa-solid fa-file-invoice-dollar',
        inputs     = {
            {
                type        = 'number',
                name        = 'accountId',
                text        = 'ID del jugador (servidor)',
                icon        = 'fa-solid fa-user',
                isRequired  = true,
                placeholder = '1',
            },
            {
                type        = 'number',
                name        = 'amount',
                text        = 'Importe',
                icon        = 'fa-solid fa-dollar-sign',
                isRequired  = true,
                placeholder = '100',
            },
            {
                type        = 'text',
                name        = 'concept',
                text        = 'Concepto',
                icon        = 'fa-solid fa-tag',
                isRequired  = true,
                placeholder = 'Ej: Servicio realizado',
            },
        },
    })

    if not input then return end

    local accountId = tonumber(input.accountId)
    local amount    = tonumber(input.amount)
    local concept   = tostring(input.concept or ''):gsub('^%s*(.-)%s*$', '%1')

    if not accountId or accountId <= 0 then
        Notify('ID de jugador inválida.', 'error') ; return
    end
    if not amount or amount <= 0 then
        Notify('El importe debe ser mayor que 0.', 'error') ; return
    end
    if concept == '' then
        Notify('Debes indicar un concepto.', 'error') ; return
    end

    local result = lib.callback.await('origen_businesses:cb:createInvoice', false, {
        businessId = businessId,
        accountId  = accountId,
        amount     = amount,
        concept    = concept,
    })

    if result and result.success then
        Notify('Factura enviada correctamente.', 'success')
    else
        Notify(result and result.message or 'Error al enviar la factura.', 'error')
    end
end

-- ─────────────────────────────────────────────────────────────────────────
-- HELPERS DE MECANICO
-- ─────────────────────────────────────────────────────────────────────────
local function ConfigMecanico()
    return (Config and Config.Mechanic) or {}
end

local function GetNearestVehicle(maxDist)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local pool   = GetGamePool('CVehicle')
    local nearest, nearestDist = 0, maxDist or 5.0

    for i = 1, #pool do
        local veh  = pool[i]
        local dist = #(coords - GetEntityCoords(veh))
        if dist < nearestDist then
            nearestDist = dist
            nearest     = veh
        end
    end

    return nearest ~= 0 and nearest or nil
end

local function NombreDelModelo(veh)
    local nombre = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    return nombre ~= 'CARNOTFOUND' and nombre or 'desconocido'
end

--[[ El esqueleto de "Reparar" y "Limpiar", que solo se diferencian en la barra
     y en lo que le hacen al coche.

     El vehículo se elige aquí y se manda al servidor POR netId. El servidor se
     conformaba con que hubiera algún coche a 12 m y el cliente aplicaba el
     arreglo al que le daba la gana: el de al lado servía de coartada para
     reparar cualquier otro.

     El cobro va DESPUÉS de la barra de progreso: si se cancela a medias, la
     caja no ha pagado nada. ]]
local function AccionSobreVehiculo(businessId, accion)
    local veh = GetNearestVehicle(tonumber(ConfigMecanico().SearchDistance) or 5.0)

    if not veh or not DoesEntityExist(veh) then
        Notify(accion.sinVehiculo, 'error')
        return
    end

    if not businessId then
        Notify('No se ha podido identificar el negocio.', 'error')
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    if not netId or netId == 0 then
        Notify(accion.sinVehiculo, 'error')
        return
    end

    local ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, veh, 1000)

    if not lib.progressBar({
        duration = accion.duracion,
        label = accion.label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true
        },
        anim = accion.anim
    }) then
        return
    end

    if not DoesEntityExist(veh) then
        Notify(accion.sinVehiculo, 'error')
        return
    end

    local result = lib.callback.await(accion.callback, false, {
        businessId = businessId,
        netId = netId
    })

    if not result or not result.success then
        Notify(result and result.message or 'No se ha podido completar la acción.', 'error')
        return
    end

    accion.aplicar(veh)
    Notify(accion.hecho(NombreDelModelo(veh), result.price or 0), 'success')
end

local function LimpiarVehiculo(veh)
    WashDecalsFromVehicle(veh, 1.0)
    SetVehicleDirtLevel(veh, 0.0)
end

AddEventHandler('origen_businesses:client:mechanic:cleanVehicle', function(businessId)
    AccionSobreVehiculo(businessId, {
        callback    = 'origen_businesses:cb:chargeClean',
        duracion    = tonumber(ConfigMecanico().CleanDuration) or 8000,
        label       = 'Limpiando el vehículo...',
        anim        = { scenario = 'WORLD_HUMAN_MAID_CLEAN' },
        sinVehiculo = 'No hay ningún vehículo cerca para limpiar.',
        aplicar     = LimpiarVehiculo,
        hecho       = function(modelo, precio)
            return ('Vehículo %s limpiado correctamente. (-$%d de la sociedad)'):format(modelo, precio)
        end
    })
end)

-- ─────────────────────────────────────────────────────────────────────────
-- LO QUE SE PUEDE HACER EN CADA TIPO DE NEGOCIO
--
-- Cada funcion se llama JUSTO al abrir el panel, no al arrancar el recurso:
-- varias miran un estado de fuera —si la central esta abierta, si estas
-- emitiendo— y el rotulo del boton depende de eso.
-- ─────────────────────────────────────────────────────────────────────────
local porTipo = {}

--[[ ── MECANICO ────────────────────────────────────────────────────────────

     Aqui habia un boton "Reparar" que dejaba un coche como nuevo por 50 $ que
     ademas PAGABA la sociedad. Con el, el resto del sistema de mecanica —el
     desgaste, las piezas, el presupuesto, la orden de trabajo— no valia para
     nada: el taller perdia dinero por cada coche y el cliente no pagaba.

     Reparar es ahora el punto `taller` con su orden de trabajo (Fase 5).
     "Limpiar" se queda: es una accion de servicio de verdad, no una reparacion
     encubierta, y su cobro sigue siendo un gasto legitimo del negocio. ]]
porTipo['mechanic'] = function(businessId)
    local precios = (Config and Config.Mechanic) or {}
    local limpiar = tonumber(precios.CleanPrice) or 15

    return {
        {
            id    = 'mec_limpiar',
            label = 'Limpiar',
            desc  = ('Limpiar el vehículo más cercano ($%d de la sociedad)'):format(limpiar),
            icon  = 'lucide:droplets',
            cierra = true,
            run = function()
                TriggerEvent('origen_businesses:client:mechanic:cleanVehicle', businessId)
            end,
        },
    }
end

-- ── WEAZEL ───────────────────────────────────────────────────────────────
porTipo['weazel'] = function(_businessId)
    local emitiendo = false
    local avisos    = weazelDispatchAlertsEnabled

    if GetResourceState('origen_broadcast') == 'started' then
        local ok, value = pcall(function()
            return exports['origen_broadcast']:IsBroadcasting()
        end)
        emitiendo = ok and value == true
    end

    return {
        {
            id    = 'weazel_emitir',
            label = emitiendo and 'Cortar' or 'Emitir',
            desc  = emitiendo and 'Finaliza la transmisión actual'
                              or 'Inicia una transmisión en vivo para Weazel',
            icon  = emitiendo and 'lucide:square' or 'lucide:video',
            peligro = emitiendo,
            cierra = true,
            run = function()
                if GetResourceState('origen_broadcast') ~= 'started' then
                    Notify('El sistema de emisiones no está disponible.', 'error')
                    return
                end
                if emitiendo then
                    TriggerEvent('origen_broadcast:client:stopStreaming')
                else
                    TriggerEvent('origen_broadcast:client:canStartBroadcast')
                end
            end,
        },
        {
            id    = 'weazel_avisos',
            label = 'Avisos',
            desc  = avisos and 'Dejar de recibir avisos de dispatch policial'
                           or 'Recibir avisos de dispatch policial para cubrir incidencias',
            icon  = avisos and 'lucide:bell-off' or 'lucide:bell',
            cierra = false,
            run = function()
                if GetResourceState('origen_police') ~= 'started' then
                    Notify('El sistema de dispatch no está disponible.', 'error')
                    return
                end

                local nuevo = not weazelDispatchAlertsEnabled
                weazelDispatchAlertsEnabled = nuevo
                TriggerServerEvent('origen_police:server:setReporterDispatchSubscription', nuevo)

                if nuevo then
                    Notify('Avisos policiales activados.', 'success')
                else
                    Notify('Avisos policiales desactivados.', 'inform')
                end
            end,
        },
        {
            id    = 'weazel_realizacion',
            label = 'Realizar',
            desc  = 'Controla cámaras y emite un programa',
            icon  = 'lucide:film',
            cierra = true,
            run = function()
                if GetResourceState('origen_broadcast') ~= 'started' then
                    Notify('El sistema de emisiones no está disponible.', 'error')
                    return
                end
                TriggerEvent('origen_broadcast_studio:client:openStudio')
            end,
        },
    }
end

-- Compatibilidad con negocios legacy de tipo "reporters"
porTipo['reporters'] = porTipo['weazel']

-- ── COMPRAVENTA ──────────────────────────────────────────────────────────
porTipo['compraventa'] = function(businessId)
    --[[ Las cuatro abren un menu de la compraventa. Van con un respiro: el
         panel acaba de soltar el foco de la NUI y el menu que viene detras lo
         pide para si, asi que sin la espera se pisan y el menu sale sin raton.

         La espera NO era por cruzar de recurso —eso ya no pasa, la compraventa
         vive aqui dentro—, es la carrera por el foco. Se queda. ]]
    local function abrir(fn)
        return function()
            CreateThread(function()
                Wait(150)
                fn({ businessId = businessId })
            end)
        end
    end

    return {
        {
            id = 'cv_comprar', label = 'Comprar',
            desc = 'El negocio compra el coche y pasa al stock',
            icon = 'lucide:handshake', cierra = true,
            run = abrir(Compraventa.AbrirCompra),
        },
        {
            id = 'cv_stock', label = 'Stock',
            desc = 'Ver vehículos en el garaje del negocio',
            icon = 'lucide:warehouse', cierra = true,
            run = abrir(Compraventa.AbrirGaraje),
        },
        {
            id = 'cv_actual', label = 'Exponer',
            desc = 'Poner o quitar de exposición el vehículo en el que estás',
            icon = 'lucide:tag', cierra = true,
            run = abrir(Compraventa.GestionarVehiculoActual),
        },
        {
            id = 'cv_traspaso', label = 'Traspaso',
            desc = 'Transferir un vehículo de un jugador a otro',
            icon = 'lucide:file-signature', cierra = true,
            run = abrir(Compraventa.AbrirTraspaso),
        },
    }
end

-- ─────────────────────────────────────────────────────────────────────────
-- LO QUE VE EL PANEL
-- ─────────────────────────────────────────────────────────────────────────
AccionesNegocio = {}

--- Como se llama y con que icono se pinta cada tipo de negocio. Sale en la
--- cabecera del panel, debajo del nombre del local.
local ETIQUETAS = {
    taxi        = { label = 'Taxi',        icon = 'lucide:car-taxi-front' },
    mechanic    = { label = 'Mecánico',    icon = 'lucide:wrench' },
    weazel      = { label = 'Weazel',      icon = 'lucide:video' },
    reporters   = { label = 'Weazel',      icon = 'lucide:video' },
    restaurant  = { label = 'Restaurante', icon = 'lucide:utensils' },
    bar         = { label = 'Bar',         icon = 'lucide:martini' },
    shop        = { label = 'Tienda',      icon = 'lucide:store' },
    gym         = { label = 'Gimnasio',    icon = 'lucide:dumbbell' },
    compraventa = { label = 'Compraventa', icon = 'lucide:car' },
    general     = { label = 'Negocio',     icon = 'lucide:briefcase' },
}

function AccionesNegocio.Etiqueta(tipo)
    return ETIQUETAS[tostring(tipo or ''):lower()] or ETIQUETAS.general
end

--- Las acciones propias del tipo de negocio, ya resueltas. Devuelve lista
--- vacia para los tipos que no tienen ninguna: un restaurante ficha, factura
--- y abre el local como todos, y ahi se acaba lo suyo.
function AccionesNegocio.DelTipo(businessId, tipo)
    local constructor = porTipo[tostring(tipo or ''):lower()]
    if not constructor then return {} end

    local ok, lista = pcall(constructor, businessId)
    if not ok or type(lista) ~= 'table' then return {} end
    return lista
end

--- El cuadro de emitir factura, que lo llama el panel.
AccionesNegocio.Factura = OpenInvoiceDialog
