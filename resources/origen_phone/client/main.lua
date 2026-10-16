--[[ Puntos de entrada: el item, el comando y la tecla. ]]

-- El inventario llama a esto al usar el item. `slot` trae la metadata, y de ahi
-- sale el numero del telefono concreto que se ha usado: si llevas dos, se abre
-- el que has pulsado.
exports('UsePhoneItem', function(_, slot)
    local number = slot and slot.metadata and slot.metadata[Config.Item.MetaNumber] or nil
    Phone.Toggle(number)
end)

-- Compatibilidad con inventarios que pasan el item entero en vez del slot.
exports('UsePhone', function(item)
    local number = item and item.metadata and item.metadata[Config.Item.MetaNumber] or nil
    Phone.Toggle(number)
end)

if Config.Command then
    RegisterCommand(Config.Command, function()
        -- Con otro panel delante con KeepInput (el menu de animaciones, por
        -- ejemplo) la tecla llega igual. Abrir encima le apagaba el KeepInput
        -- (foco.lua) y al cerrar el movil el de debajo se quedaba sin teclado y
        -- con la camara bloqueada. Cerrar si se deja siempre.
        if not Phone.open and OrigenFoco and OrigenFoco.OtroConFoco() then return end

        -- Sin numero: se coge el primer telefono que se lleve encima. Si no hay
        -- ninguno con numero, el servidor estrena uno.
        Phone.Toggle(Framework.GetFirstNumber())
    end, false)

    if Config.Keybind then
        RegisterKeyMapping(Config.Command, 'Abrir el teléfono', 'keyboard', Config.Keybind)
    end
end

-- Cerrar con Escape. La NUI tiene el foco con las teclas activas, asi que el
-- juego sigue viendo la pulsacion y hay que atenderla aqui.
CreateThread(function()
    while true do
        if Phone.open then
            -- El control esta desactivado (si no, abriria el menu de pausa),
            -- asi que hay que leerlo con la version "disabled".
            if IsDisabledControlJustReleased(0, 322) or IsDisabledControlJustReleased(0, 200) then
                if Camera.active then
                    Camera.Close()
                    Nui.Send('cameraClosed', true)
                else
                    Phone.Close()
                end
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

-- Al reiniciar el recurso con el telefono abierto, la NUI se queda con el foco
-- y el jugador no puede moverse. Esto lo suelta.
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Foco.Todo()
end)

RegisterNetEvent('origen_phone:cl:itemAdded', function()
    Wait(500)
    if Phone.number then return end

    local first = Framework.GetFirstNumber()
    if first then Phone.number = first end
end)

-- ---------------------------------------------------------------------------
--  Exports para otros recursos
-- ---------------------------------------------------------------------------

exports('IsOpen', function()
    return Phone.open
end)

exports('GetNumber', function()
    return Phone.number
end)

exports('Open', function()
    Phone.Open(Framework.GetFirstNumber())
end)

exports('Close', function()
    Phone.Close()
end)

exports('IsInCall', function()
    return Calls.IsActive()
end)
