--[[
    La caja fuerte de un negocio, del lado del jugador.

    Solo pide la clave. Se pide con el menu pequeño de ORIGEN, a media altura
    a la derecha (ui/source/src/components/CajaFuerte.vue, sobre MenuLateral.vue)
    y se manda tal cual al servidor, que es quien la compara, mira que estes
    delante de la caja, lleva la cuenta de los intentos y abre el alijo.

    Aqui no se sabe la clave ni se abre nada: si el servidor dice que no, se
    enseña su motivo en el mismo dialogo y se puede volver a probar.
]]

CajaFuerte = {}

local abierta = false
local negocioId = nil
local pintada = false

local function Cerrar(avisarNui)
    -- El foco primero y sin condiciones, como en el panel de negocio: quedarse
    -- sin dialogo se arregla; quedarse con el raton preso, no.
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if not abierta then return end
    abierta = false
    negocioId = nil

    if avisarNui then
        SendNUIMessage({ action = 'cajaFuerte:cerrar', data = {} })
    end
end

--- Abre el dialogo de la clave para la caja de ese negocio.
function CajaFuerte.Pedir(businessId, etiqueta)
    if abierta or not businessId then return end

    abierta = true
    negocioId = tostring(businessId)

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'cajaFuerte:abrir',
        data = { negocio = tostring(etiqueta or 'Negocio') },
    })

    --[[ Si la interfaz no llega a pintar el dialogo, no se deja el foco cogido
         con la pantalla vacia: a los 1,5 s se suelta. ]]
    pintada = false
    SetTimeout(1500, function()
        if abierta and not pintada then
            print('^1[origen_businesses]^0 El dialogo de la caja fuerte no llego a pintarse. Se suelta el foco.')
            Cerrar(true)
        end
    end)
end

RegisterNUICallback('cajaFuertePintada', function(_, cb)
    cb('ok')
    pintada = true
end)

RegisterNUICallback('cajaFuerteCerrar', function(_, cb)
    cb('ok')
    Cerrar(false)
end)

--[[ Probar una clave. La respuesta vuelve a la interfaz: si es que no, lleva el
     motivo (clave mala, intentos que quedan, demasiado lejos...). Si es que si,
     el inventario ya lo ha abierto el servidor y aqui solo se suelta el foco. ]]
RegisterNUICallback('cajaFuerteProbar', function(data, cb)
    if not abierta or not negocioId then
        cb({ success = false, message = 'La caja fuerte ya no está abierta.' })
        return
    end

    local clave = type(data) == 'table' and data.clave
    if type(clave) ~= 'string' or clave == '' then
        cb({ success = false, message = 'Escribe la clave.' })
        return
    end

    local ok, res = pcall(function()
        return lib.callback.await('origen_businesses:cb:cajaFuerte:abrir', false, negocioId, clave)
    end)

    if not ok or type(res) ~= 'table' then
        cb({ success = false, message = 'No se pudo comprobar la clave.' })
        return
    end

    if res.success then
        Cerrar(false)
        cb({ success = true })
        return
    end

    cb({ success = false, message = tostring(res.message or 'Clave incorrecta.') })
end)

-- Si alguien suelta el raton a la fuerza (comando `raton`), el dialogo se va
-- con el y se puede volver a abrir.
OrigenFoco.AlSoltar(function()
    if abierta then
        abierta = false
        negocioId = nil
        SendNUIMessage({ action = 'cajaFuerte:cerrar', data = {} })
    end
end)
