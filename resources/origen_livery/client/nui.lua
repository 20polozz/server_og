--[[ ── El menú de liveries ─────────────────────────────────────────────────

     La pantalla es un menú del riel (columna + barra del canto, como el
     inventario y la radio) con el editor que se estira hacia la izquierda.
     Aquí vive todo lo que la NUI le pide al cliente; el editor en sí —cámara
     y vista previa en el coche— está en client/editor.lua.

     Los nombres de las llamadas van sin tildes: el navegador codifica en la
     URL todo lo que no es ASCII y RegisterNUICallback no las encontraría. ]]

local abierto = false
local abriendo = false
local pintado = false

local PESTANAS = { inventory = true, personal = true, vehicle = true, keys = true, city = true, quests = true, settings = true }

--- El nombre bonito del modelo, el de la tienda: «Karin Sultan RS» y no «sultanrs».
local function etiquetaDe(entity)
    if not entity or entity == 0 then return nil end
    local modelo = GetEntityModel(entity)
    local marca = GetLabelText(GetMakeNameFromVehicleModel(modelo))
    local nombre = GetLabelText(GetDisplayNameFromVehicleModel(modelo))
    if nombre == 'NULL' then return nil end
    if marca ~= 'NULL' and marca ~= '' then return ('%s %s'):format(marca, nombre) end
    return nombre
end

--- El coche para la NUI: lo de Livery.target() sin el handle de la entidad,
--- que no le sirve de nada y en JSON solo es un número raro.
local function vehiculoParaNui(target)
    if not target then return nil end
    return {
        model = target.model,
        label = etiquetaDe(target.entity),
        plate = target.plate,
        modLiveries = target.modLiveries,
        modLivery = target.modLivery,
        slots = target.slots,
        assignment = target.assignment,
    }
end

local function huecosDe(target)
    if not target then return {} end
    local info = lib.callback.await('origen_livery:layout', false, target.model)
    return type(info) == 'table' and type(info.layout) == 'table' and info.layout or {}
end

--- Solo el conductor: la livery va por matrícula y la pone quien lleva el coche.
local function alVolante()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return 0 end
    return veh
end

local function HudFuera(fuera)
    TriggerEvent('qv2:suppressHud', fuera == true)
end

local function ajustesParaNui()
    local e = Config.Editor or {}
    return {
        exportar = e.ExportSize or 2048,
        maxImagen = e.MaxImageChars or 9000000,
        maxDoc = e.MaxDocChars or 8000000,
        maxDisenos = Config.MaxDesignsPerPlayer,
    }
end

local function Cerrar()
    if not abierto then return end
    abierto = false

    -- Primero el foco, siempre: si lo de abajo falla, lo peor es quedarse sin
    -- menú, no quedarse sin cámara.
    SetNuiFocus(false, false)
    Editor.parar()
    HudFuera(false)

    SetTimeout(280, function()
        if not abierto then SendNUIMessage({ accion = 'cerrar' }) end
    end)
end

--[[ Raton soltado a la fuerza (vigilante de origen_map/shared/foco.lua o
     `soltarraton`): el cierre de siempre, con el editor parado y el HUD de
     vuelta. Sin esto `abierto` se quedaba en true y /livery no hacia nada. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if abierto then Cerrar() end
    end)
end

--- `relevo`: se llega desde otro panel del riel y su barra sigue en pantalla.
local function Abrir(relevo)
    -- Dos /livery seguidos mientras se espera al servidor no abren dos veces.
    if abierto or abriendo then return end

    --[[ El permiso lo decide el servidor, que es donde se vuelve a mirar en
         cada evento. Aquí solo se pregunta para no abrir la pantalla a quien
         no la va a poder usar. ]]
    abriendo = true
    local puede = lib.callback.await('origen_livery:canUse', false)
    abriendo = false

    if not puede then
        TriggerEvent('QBCore:Notify', 'No tienes permiso para usar las liveries.', 'error')
        return
    end

    abierto = true
    pintado = false

    local target = alVolante() ~= 0 and Livery.target() or nil
    local huecos = huecosDe(target)
    local disenos = lib.callback.await('origen_livery:myDesigns', false) or {}

    -- Pudo cerrarse mientras esperábamos al servidor.
    if not abierto then return end

    SetNuiFocus(true, true)
    HudFuera(true)

    SendNUIMessage({
        accion = 'abrir',
        datos = {
            vehiculo = vehiculoParaNui(target),
            huecos = huecos,
            disenos = disenos,
            ajustes = ajustesParaNui(),
            relevo = relevo == true,
        },
    })

    --[[ Si la NUI no dice que se ha pintado en segundo y medio —una excepción,
         la interfaz sin compilar— el foco se suelta: un ratón preso sin nada
         delante no tiene salida. ]]
    SetTimeout(1500, function()
        if abierto and not pintado then
            print('^1[origen_livery]^0 La interfaz no respondió al abrir. Foco soltado.')
            Cerrar()
        end
    end)
end

RegisterCommand('livery', function()
    Abrir(false)
end, false)

exports('AbrirDelRiel', function(relevo)
    SetNuiFocus(false, false)
    SetTimeout(0, function() Abrir(relevo == true) end)
end)

exports('EstaAbierto', function()
    return abierto == true
end)

RegisterNUICallback('pintado', function(_, cb)
    pintado = true
    cb({ ok = true })
end)

RegisterNUICallback('cerrar', function(_, cb)
    cb({ ok = true })
    Cerrar()
end)

RegisterNUICallback('PedirRiel', function(_, cb)
    if GetResourceState('origen_inventory') ~= 'started' then return cb({}) end
    local ok, riel = pcall(function() return exports.origen_inventory:GetRiel('livery') end)
    cb(ok and type(riel) == 'table' and riel or {})
end)

RegisterNUICallback('IrDelRiel', function(datos, cb)
    cb({ ok = true })

    local destino = type(datos) == 'table' and datos.id or nil
    if type(destino) ~= 'string' then return end

    abierto = false
    SetNuiFocus(false, false)
    Editor.parar()
    HudFuera(false)

    if GetResourceState('origen_inventory') ~= 'started' then return end

    -- A los 200 y no a los 280: el que entra empieza a deslizarse mientras
    -- esta columna acaba de recogerse, y no queda hueco vacío.
    SetTimeout(200, function()
        if PESTANAS[destino] then
            exports.origen_inventory:AbrirEnPestana(destino, true)
        else
            exports.origen_inventory:AbrirAcceso(destino, true)
        end
    end)
end)

RegisterNUICallback('detectar', function(_, cb)
    local target = alVolante() ~= 0 and Livery.target() or nil
    cb({ ok = true })
    SendNUIMessage({ accion = 'vehiculo', vehiculo = vehiculoParaNui(target), huecos = huecosDe(target) })
end)

RegisterNUICallback('misDisenos', function(_, cb)
    cb(lib.callback.await('origen_livery:myDesigns', false) or {})
end)

local function huecoPedido(datos)
    local slot = type(datos) == 'table' and type(datos.slot) == 'string' and datos.slot or ''
    if slot ~= '' and not slot:match(Config.SlotIdPattern) then return nil end
    return slot
end

RegisterNUICallback('aplicarDiseno', function(datos, cb)
    local target = alVolante() ~= 0 and Livery.target() or nil
    if not target then return cb({ ok = false, error = 'get in a vehicle first' }) end

    local id = type(datos) == 'table' and math.tointeger(tonumber(datos.designId)) or nil
    if not id or id <= 0 then return cb({ ok = false, error = 'invalid design id' }) end

    local slot = huecoPedido(datos)
    if not slot then return cb({ ok = false, error = 'invalid slot id' }) end

    TriggerServerEvent('origen_livery:applyDesign', id, target.model, slot)
    cb({ ok = true, pending = true })
end)

RegisterNUICallback('aplicarUrl', function(datos, cb)
    local target = alVolante() ~= 0 and Livery.target() or nil
    if not target then return cb({ ok = false, error = 'get in a vehicle first' }) end

    local url = type(datos) == 'table' and datos.url or nil
    if type(url) ~= 'string' or #url > Config.MaxUrlLength or not url:match('^https?://%S+$') then
        return cb({ ok = false, error = 'invalid image url' })
    end

    local slot = huecoPedido(datos)
    if not slot then return cb({ ok = false, error = 'invalid slot id' }) end

    TriggerServerEvent('origen_livery:applyUrl', target.model, slot, url)
    cb({ ok = true, pending = true })
end)

RegisterNUICallback('quitar', function(_, cb)
    local target = alVolante() ~= 0 and Livery.target() or nil
    if not target then return cb({ ok = false, error = 'get in a vehicle first' }) end

    local slot = target.assignment and target.assignment.slotId or ''
    TriggerServerEvent('origen_livery:clearSlot', target.model, slot)
    cb({ ok = true, pending = true })
end)

RegisterNUICallback('borrarDiseno', function(datos, cb)
    local id = type(datos) == 'table' and math.tointeger(tonumber(datos.designId)) or nil
    if not id or id <= 0 then return cb({ ok = false, error = 'invalid design id' }) end
    cb(lib.callback.await('origen_livery:borrarDiseno', false, id) or { ok = false })
end)

--[[ ── Guardar y abrir diseños ─────────────────────────────────────────────

     Una livery exportada pesa megas y un diseño con imágenes importadas,
     más. Eso no cabe en un evento normal —pasado de unos 50 KB no da error,
     se pierde—, así que viaja por un evento latente, que el servidor recibe
     troceado, y la respuesta vuelve por otro evento con el número de pedido.
     La llamada de la NUI se queda esperando a esa respuesta. ]]

local pendientes = {}
local numeroPedido = 0

local function esperarRespuesta(pedido, tope)
    local p = promise.new()
    pendientes[pedido] = p

    SetTimeout(tope, function()
        if pendientes[pedido] then
            pendientes[pedido] = nil
            p:resolve({ ok = false, error = 'El servidor no ha contestado a tiempo.' })
        end
    end)

    return Citizen.Await(p)
end

local function responderPedido(pedido, resultado)
    local p = pendientes[pedido]
    if not p then return end
    pendientes[pedido] = nil
    p:resolve(resultado)
end

RegisterNetEvent('origen_livery:guardado', responderPedido)
RegisterNetEvent('origen_livery:doc', responderPedido)

local function nuevoPedido()
    numeroPedido = numeroPedido + 1
    return ('%d-%d'):format(GetGameTimer(), numeroPedido)
end

RegisterNUICallback('guardarDiseno', function(datos, cb)
    if type(datos) ~= 'table' then return cb({ ok = false, error = 'Datos vacíos.' }) end

    local e = Config.Editor or {}
    local imagen, doc = datos.imagen, datos.doc

    if type(imagen) ~= 'string' or #imagen > (e.MaxImageChars or 9000000) then
        return cb({ ok = false, error = 'La livery pesa demasiado para subirla.' })
    end

    if type(doc) ~= 'string' or #doc > (e.MaxDocChars or 8000000) then
        return cb({ ok = false, error = 'El diseño pesa demasiado para guardarlo.' })
    end

    local pedido = nuevoPedido()
    local bps = e.LatentBps or 4000000

    TriggerLatentServerEvent('origen_livery:guardar', bps, pedido, {
        designId = math.tointeger(tonumber(datos.designId)),
        nombre = datos.nombre,
        modelo = datos.modelo,
        imagen = imagen,
        doc = doc,
    })

    -- Lo que tarda en llegar al ritmo del evento, tres veces, más lo que tarde
    -- la subida de la imagen al almacén. Nunca menos de medio minuto.
    local segundos = ((#imagen + #doc) * 8) / bps
    cb(esperarRespuesta(pedido, math.floor(math.max(30000, segundos * 3000 + 20000))))
end)

RegisterNUICallback('abrirDiseno', function(datos, cb)
    local id = type(datos) == 'table' and math.tointeger(tonumber(datos.designId)) or nil
    if not id or id <= 0 then return cb({ ok = false, error = 'invalid design id' }) end

    local pedido = nuevoPedido()
    TriggerServerEvent('origen_livery:pedirDoc', pedido, id)
    cb(esperarRespuesta(pedido, 45000))
end)

--[[ ── El editor ─────────────────────────────────────────────────────── ]]

RegisterNUICallback('editor', function(datos, cb)
    cb({ ok = true })
    if not abierto then return end
    Editor.poner(type(datos) == 'table' and datos.abierto == true, type(datos) == 'table' and datos.modo or nil)
end)

RegisterNUICallback('vistaPrevia', function(datos, cb)
    cb({ ok = true })
    if not abierto or type(datos) ~= 'table' then return end
    Editor.vistaPrevia(datos.imagen)
end)

RegisterNUICallback('camara', function(datos, cb)
    cb({ ok = true })
    if not abierto or type(datos) ~= 'table' then return end
    Editor.camara(tonumber(datos.dx) or 0, tonumber(datos.dy) or 0, tonumber(datos.zoom) or 0)
end)

--- El editor se ha tenido que parar por su cuenta (bajaste del coche): la
--- pantalla se entera para no dejar «Guardar y aplicar» encendido.
function AvisarNuiSinCoche()
    if not abierto then return end
    SendNUIMessage({ accion = 'vehiculo', vehiculo = nil, huecos = {} })
end

RegisterNetEvent('origen_livery:applied', function(result)
    SendNUIMessage({ accion = 'aplicado', resultado = result })

    if type(result) ~= 'table' or not result.ok then return end

    -- Si el editor tenía una previa enganchada, liberarla para enganchar la livery real
    Editor.parar()

    local target = Livery.target()

    if target and target.entity then
        if result.cleared then
            Livery.release(target.entity)
        else
            Livery.enforce(target.entity)
        end
    end
end)

AddEventHandler('onResourceStop', function(nombre)
    if nombre ~= GetCurrentResourceName() then return end
    if abierto then
        SetNuiFocus(false, false)
        HudFuera(false)
    end
end)

exports('describeTarget', function()
    return Livery.target()
end)

exports('assetBase', function()
    return Livery.assetBase()
end)

