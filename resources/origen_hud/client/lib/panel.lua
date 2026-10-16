--[[ Los paneles laterales del HUD (Tienda, Mis cosas): el mismo reparto del
     foco para todos. El foco se suelta YA y el desmontaje espera a que la
     NUI acabe de deslizarse (260 ms), para que el raton nunca se quede preso. ]]

PanelesLaterales = {}

local function Misiones(visible)
    TriggerEvent('qv2:suppressHud', not visible)
end

function PanelLateral(prefijo)
    local p = { abierto = false, vuelta = 0 }

    function p.Soltar()
        p.abierto = false
        SetNuiFocus(false, false)
        Misiones(true)

        local mia = p.vuelta
        SetTimeout(280, function()
            if p.vuelta == mia then SendNUIMessage({ action = prefijo .. ':desmontar' }) end
        end)
    end

    function p.Cerrar()
        if not p.abierto then return end
        p.Soltar()
    end

    --- Reserva la apertura antes de pedir datos: dos pulsaciones seguidas no abren dos veces.
    function p.Empezar()
        if p.abierto then return false end
        p.abierto = true
        p.vuelta = p.vuelta + 1
        Misiones(false)
        return true
    end

    function p.Fallar(texto)
        p.abierto = false
        Misiones(true)
        lib.notify({ description = texto, type = 'error' })
    end

    function p.Mostrar(datos)
        SetNuiFocus(true, true)
        SendNUIMessage({ action = prefijo .. ':abrir', data = datos })
    end

    RegisterNUICallback(prefijo .. ':cerrar', function(_, cb)
        p.Cerrar()
        cb({})
    end)

    PanelesLaterales[#PanelesLaterales + 1] = p
    return p
end

if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        for _, p in ipairs(PanelesLaterales) do
            if p.abierto then p.Soltar() end
        end
    end)
end

AddEventHandler('origen:foco:estado', function(recurso, tiene)
    if not tiene or recurso == GetCurrentResourceName() then return end
    for _, p in ipairs(PanelesLaterales) do p.Cerrar() end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, p in ipairs(PanelesLaterales) do
        if p.abierto then
            SetNuiFocus(false, false)
            Misiones(true)
        end
    end
end)

--- Para el `unfocus` de client/main.lua, que suelta el foco con ESC.
function PanelesCerrarDesdeFuera()
    for _, p in ipairs(PanelesLaterales) do p.Cerrar() end
end
