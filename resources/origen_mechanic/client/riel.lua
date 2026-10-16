-- El nombre del pie del riel segun el servidor: «Origen Taller» o «Nacion Taller».
MecMarcaTaller = (GetConvar('origen:marca', 'origen') == 'nacion' and 'Nación' or 'Origen') .. ' Taller'

--[[
    EL MENÚ LATERAL — LA PUERTA ÚNICA

    Las cinco pantallas que antes eran menús de ox_lib (`registerContext` y
    `alertDialog`) pasan por aquí. Todas tienen la misma forma: una columna con
    grupos de filas, con o sin selección, y de cero a dos acciones.

    El panel de diagnóstico (tema HUD Arcade, `client/diagnostic.lua`) NO pasa
    por aquí: es una pantalla completa y se queda como está.

    ── Lo que hay que entender antes de tocar esto ──────────────────────────

    Un `lib.alertDialog` BLOQUEA: se llama, se espera, se sigue. Una NUI no.
    Aquí el flujo se invierte: `Abrir` deja apuntado un `alResponder`, vuelve
    en el acto, y ese `alResponder` se ejecuta cuando la pantalla se cierra,
    con lo que el jugador eligió —o con nil si cerró sin elegir—.

    Traducirlo línea a línea desde el `alertDialog` no funciona: no hay dónde
    esperar.
]]

local abierto = false
local respuesta = nil
local alResponder = nil

MecRiel = {}

function MecRiel.EstaAbierto()
    return abierto
end

--[[ El foco se suelta ANTES de animar y el desmontaje se retrasa 280 ms (los
     260 de la transición más margen). Al revés, el ratón se queda preso los
     260 ms en los que la pantalla ya parece cerrada, y si el aviso no llega
     —una excepción en la NUI— se queda preso del todo. ]]
local function Cerrar()
    if not abierto then return end

    abierto = false
    SetNuiFocus(false, false)

    local manejador, elegido = alResponder, respuesta
    alResponder, respuesta = nil, nil

    -- Sin pisar un riel que se haya vuelto a abrir en esos 280 ms.
    SetTimeout(280, function()
        if not abierto then SendNUIMessage({ action = 'rielCerrar' }) end
    end)

    if not manejador then return end

    --[[ En su propio hilo y DESPUÉS de soltar el foco: lo que sigue a una
         elección suele ser una progressbar o una llamada al servidor, y ni una
         ni otra pueden correr con el ratón preso. ]]
    CreateThread(function() manejador(elegido) end)
end

MecRiel.Cerrar = Cerrar

--- `panel` es la pantalla entera, con todo lo que hace falta para decidir.
--- `alResponder` recibe la elección al cerrarse, o nil si se cerró sin elegir.
function MecRiel.Abrir(panel, responder)
    if abierto or type(panel) ~= 'table' then return false end

    --[[ El panel del taller usa el mismo foco de NUI: abrir el riel encima
         dejaría dos pantallas peleándose por él y el primer cierre soltaría el
         de las dos. ]]
    local ok, tallerAbierto = pcall(function()
        return exports.origen_mechanic:PanelTallerAbierto()
    end)

    if ok and tallerAbierto then return false end

    abierto = true
    respuesta = nil
    alResponder = responder

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'riel', data = panel })

    return true
end

RegisterNUICallback('rielAccion', function(data, cb)
    if abierto and type(data) == 'table' and type(data.accion) == 'string' then
        respuesta = { accion = data.accion, seleccion = data.seleccion }
    end

    cb({ success = true })
end)

RegisterNUICallback('rielCerrar', function(_, cb)
    Cerrar()
    cb({ success = true })
end)

--[[ Si le quitan el foco a la fuerza (el comando `raton` de origen_hud), la
     pantalla ya no está: se recoge el estado sin ejecutar lo que quedara
     apuntado, porque nadie llegó a elegir nada. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not abierto then return end

        abierto = false
        alResponder, respuesta = nil, nil
        SendNUIMessage({ action = 'rielCerrar' })
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if abierto then SetNuiFocus(false, false) end
end)

Mechanic.Ocupacion.riel = function()
    return abierto
end
