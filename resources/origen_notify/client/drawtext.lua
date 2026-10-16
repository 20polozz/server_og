local currentDrawText = nil
local wasNuiFocused = false

--[[ El aviso de accion: la tecla y lo que se hace al pulsarla.

     `alt` es la SEGUNDA tecla, opcional, y llega como { tecla, accion }:

         exports.origen_notify:DrawText('E', 'Coger manguera', { 'G', 'Repostar bidon' })

     Sale detras de un filete, en parda en vez de rosa. Los cientos de
     llamadas de siempre --con dos argumentos-- siguen igual. ]]
---@param key string
---@param text string
---@param alt table|nil { tecla, accion }
local function DrawText(key, text, alt)
    --- Solo si vienen las dos cosas: media pastilla no dice nada.
    local segunda = nil
    if type(alt) == 'table' and alt[1] and alt[2] then
        segunda = { tostring(alt[1]), tostring(alt[2]) }
    end

    currentDrawText = {
        key = key,
        text = text,
        alt = segunda
    }
    -- Con un menu abierto (cualquier NUI con foco) se guarda y no se pinta:
    -- lo saca el hilo de abajo al cerrarse. Antes el hilo solo lo escondia al
    -- COGER el foco, y si alguien lo volvia a pedir con el menu ya abierto (el
    -- «Acceder a…» del garaje, cada fotograma) salia a traves del panel.
    if IsNuiFocused() then return end
    SendNUIMessage({
        action = 'showDrawText',
        data = {
            key = key,
            text = text,
            alt = segunda
        }
    })
end

local function HideText()
    currentDrawText = nil
    SendNUIMessage({
        action = 'hideDrawtext'
    })
end

exports('DrawText', DrawText)
exports('HideText', HideText)

CreateThread(function()
    while true do
        Wait(500)
        local isNuiFocused = IsNuiFocused()
        
        if isNuiFocused and not wasNuiFocused and currentDrawText then
            SendNUIMessage({
                action = 'hideDrawtext'
            })
        elseif not isNuiFocused and wasNuiFocused and currentDrawText then
            SendNUIMessage({
                action = 'showDrawText',
                data = {
                    key = currentDrawText.key,
                    text = currentDrawText.text,
                    alt = currentDrawText.alt
                }
            })
        end
        
        wasNuiFocused = isNuiFocused
    end
end)