--[[
    LA CENTRAL, EN EL LADO DEL JUGADOR

    Aquí no se decide nada: todo lo que importa —quién puede coger un aviso,
    dónde está el cliente, cuánto cuesta— lo resuelve source/server/central.lua.
    Esto es lo que se ve y lo que se oye.

    Tres cosas:

      · el aviso que entra, para el que está trabajando;
      · la RUTA al cliente cuando coges uno, que es lo que de verdad hace
        falta para atenderlo;
      · el empujón a la interfaz del panel para que la pestaña Central se
        refresque sola mientras la estás mirando.
]]

--- El aviso que llevo entre manos. Solo uno: coger dos a la vez sería tener
--- dos rutas puestas y ninguna que seguir.
local llevo = nil

local CLAVE_MAPA = 'central_aviso'

local function Notify(texto, tipo, titulo)
    if GetResourceState('origen_notify') ~= 'started' then return end

    exports['origen_notify']:Notify({
        title = titulo,
        description = texto,
        type = tipo or 'inform',
        duration = 6000,
    })
end

--- Mandar a la interfaz del panel. Si no está abierta, el mensaje se cae al
--- vacío y no pasa nada.
local function ALaNui(accion, datos)
    SendNUIMessage({ action = accion, data = datos })
end

-- ─────────────────────────────────────────────────────────────────────────
-- EL PUNTO Y LA RUTA
-- ─────────────────────────────────────────────────────────────────────────

local function QuitarRuta()
    if OrigenMapa then OrigenMapa.Quitar(CLAVE_MAPA) end
end

--[[ Poner el sitio del cliente en el mapa, con el camino marcado.

     Va por origen_map y no con un blip a pelo para que se comporte como el
     resto de puntos del servidor: mismo estilo, misma lista del mapa grande, y
     se va solo si se para el recurso. ]]
local function PonerRuta(aviso)
    if not OrigenMapa or not aviso or not aviso.coords then return end

    OrigenMapa.Poner(CLAVE_MAPA, {
        x = aviso.coords.x + 0.0,
        y = aviso.coords.y + 0.0,
        z = (aviso.coords.z or 0.0) + 0.0,
        cat = 'trabajos',
        nombre = aviso.titular or 'Aviso de la central',
        ruta = true,
    })
end

-- ─────────────────────────────────────────────────────────────────────────
-- LO QUE LLEGA DEL SERVIDOR
-- ─────────────────────────────────────────────────────────────────────────

--- Entra un aviso nuevo en el local donde estás fichado.
RegisterNetEvent('origen_businesses:client:central:aviso', function(aviso)
    if type(aviso) ~= 'table' then return end

    Notify(aviso.titular or 'Alguien pide un servicio', 'inform', 'Central')
    ALaNui('negocio:central:refrescar', {})
end)

--- Lo has cogido tú: se te pone la ruta.
RegisterNetEvent('origen_businesses:client:central:llevas', function(aviso)
    if type(aviso) ~= 'table' then return end

    llevo = aviso
    PonerRuta(aviso)

    Notify('Ruta puesta hasta el cliente', 'success', 'Central')
    ALaNui('negocio:central:refrescar', {})
end)

--- Lo has soltado, cerrado o rechazado: fuera la ruta.
RegisterNetEvent('origen_businesses:client:central:sueltas', function(id)
    if llevo and llevo.id ~= id then return end

    llevo = nil
    QuitarRuta()
    ALaNui('negocio:central:refrescar', {})
end)

--- Algo ha cambiado en la central del local: que la pestaña se entere.
RegisterNetEvent('origen_businesses:client:central:refrescar', function()
    ALaNui('negocio:central:refrescar', {})
end)

--[[ Cómo va lo que TÚ pediste.

     Esto le llega al cliente, no al empleado. El aviso de verdad —el que se
     queda y se puede volver a leer— es el del móvil; este es el de pantalla,
     para el que está jugando y no va a sacar el teléfono. ]]
RegisterNetEvent('origen_businesses:client:central:estado', function(datos)
    if type(datos) ~= 'table' then return end

    local textos = {
        taken = 'Van de camino',
        done = 'Servicio atendido',
        refused = 'No pueden atenderte',
        expired = 'Nadie ha cogido tu aviso',
        cancelled = 'Aviso cancelado',
    }

    local texto = textos[datos.estado]
    if texto then Notify(texto, datos.estado == 'done' and 'success' or 'inform', 'Servicios') end
end)

--[[ Al entrar, decirle al servidor que estás.

     Los avisos no se borran al desconectar —una grúa de camino sigue de
     camino—, pero el servidor olvida tu id de jugador, que al reconectar es
     otro. Esto los vuelve a atar. ]]
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('origen_businesses:server:centralVuelvo')
end)

AddEventHandler('esx:playerLoaded', function()
    TriggerServerEvent('origen_businesses:server:centralVuelvo')
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    TriggerServerEvent('origen_businesses:server:centralVuelvo')
end)

--- Si se para el recurso, la ruta se va con él.
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    QuitarRuta()
end)

-- ─────────────────────────────────────────────────────────────────────────
-- LO QUE PIDE LA PESTAÑA CENTRAL DEL PANEL
--
-- Mismo patrón que el resto del panel (custom/client/panel_negocio.lua): la
-- interfaz llama, aquí se pregunta al servidor y se contesta. Todo va por
-- pcall: un callback que no está registrado —lo normal si el recurso se
-- reinició sin refresh— planta la espera cinco minutos, y con ella la pestaña.
-- ─────────────────────────────────────────────────────────────────────────

--- Pregunta al servidor sin que un fallo suyo deje la pestaña colgada.
local function AlServidor(nombre, datos)
    local ok, res = pcall(function()
        return lib.callback.await('origen_businesses:cb:central:' .. nombre, false, datos)
    end)
    if not ok then return nil end
    return res
end

--[[ La distancia se resuelve aquí y no en el servidor.

     Por lo mismo que la plantilla del panel: quien pregunta se mueve, y el
     nombre del barrio solo existe en el cliente. El servidor manda las
     coordenadas en crudo.

     Esto es SOLO para pintar —para poder decir "a 300 m, Sandy Shores" y para
     apagar el botón de entregar cuando estás lejos—. Al entregar de verdad, el
     servidor vuelve a medir por su cuenta (EstaJunto): si se fiara de esto,
     bastaría con mentirle desde aquí para entregar la compra desde casa. ]]
local function Colocar(avisos)
    local yo = GetEntityCoords(PlayerPedId())

    for _, aviso in ipairs(avisos or {}) do
        if aviso.coords and aviso.coords.x then
            local donde = vector3(aviso.coords.x, aviso.coords.y, aviso.coords.z or 0.0)
            aviso.distancia = math.floor(#(yo - donde))
            aviso.zona = GetLabelText(GetNameOfZone(donde.x, donde.y, donde.z))
        end
    end

    return avisos
end

RegisterNUICallback('centralLista', function(data, cb)
    local res = AlServidor('lista', data and data.businessId)

    if type(res) == 'table' and res.success then
        res.avisos = Colocar(res.avisos)
        res.llevo = llevo and llevo.id or nil
    end

    cb(res or { success = false, message = 'La central no contestó.' })
end)

RegisterNUICallback('centralCoger', function(data, cb)
    cb(AlServidor('coger', { id = data and data.id }) or { ok = false, error = 'No se pudo coger el aviso.' })
end)

RegisterNUICallback('centralSoltar', function(data, cb)
    cb(AlServidor('soltar', { id = data and data.id }) or { ok = false, error = 'No se pudo soltar el aviso.' })
end)

RegisterNUICallback('centralCerrar', function(data, cb)
    cb(AlServidor('cerrar', {
        id = data and data.id,
        importe = data and data.importe,
        concepto = data and data.concepto,
    }) or { ok = false, error = 'No se pudo cerrar el aviso.' })
end)

RegisterNUICallback('centralRechazar', function(data, cb)
    cb(AlServidor('rechazar', { id = data and data.id }) or { ok = false, error = 'No se pudo rechazar el aviso.' })
end)

RegisterNUICallback('centralServicios', function(data, cb)
    cb(AlServidor('servicios', {
        businessId = data and data.businessId,
        servicios  = data and data.servicios,
    }) or { success = false, message = 'No se pudieron guardar los servicios.' })
end)
