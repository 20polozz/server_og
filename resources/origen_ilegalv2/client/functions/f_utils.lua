-- Client utility functions

function GetClosestPlayer()
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, playerId in ipairs(players) do
        local targetPed = GetPlayerPed(playerId)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if closestDistance == -1 or distance < closestDistance then
                closestDistance = distance
                closestPlayer = playerId
            end
        end
    end

    return closestPlayer, closestDistance
end

--[[ El pie de teclas de abajo a la derecha: el de origen_hud, el mismo de todo
     el servidor (antes este recurso tenia el suyo, HudControls.vue). Cada
     tecla es { key = 'ENTER', text = 'Confirmar' }; origen_hud la traduce
     («Intro», «Retroceso») o pone su dibujo ('WHEEL', 'LCLICK'...). Con la
     guarda, si origen_hud no esta arrancado no se rompe el hilo que llama. ]]
function MostrarTeclas(teclas)
    if GetResourceState('origen_hud') ~= 'started' then return end
    exports.origen_hud:setupControls(teclas)
end

function QuitarTeclas()
    if GetResourceState('origen_hud') ~= 'started' then return end
    exports.origen_hud:hideControls()
end

--[[ El bocadillo sobre la cabeza de un NPC (los clientes de la venta de
     droga): una pegatina de mundo, como las del resto del servidor. Pieza
     gris claro (220,221,224) con canto negro, sombra dura negra abajo a la
     derecha, filete rosa a la izquierda y la letra en tinta negra. En Nacion
     el rosa sale naranja: tema.lua envuelve DrawRect.

     Sigue siendo texto de mundo: se coloca con World3dToScreen2d sobre las
     coordenadas que le pasan y no se pinta si cae fuera de la pantalla. ]]
function BocadilloPegatina(x, y, z, texto)
    if not texto or texto == '' then return end
    local enPantalla, sx, sy = World3dToScreen2d(x, y, z)
    if not enPantalla then return end

    local escala = 0.35
    -- Lo que mide el texto de verdad, para que la pieza lo abrace.
    BeginTextCommandGetWidth('STRING')
    AddTextComponentSubstringPlayerName(texto)
    SetTextFont(4)
    SetTextScale(escala, escala)
    local anchoTexto = EndTextCommandGetWidth(true)

    -- Un pixel de pantalla, para que el canto y la sombra midan lo mismo en
    -- cualquier resolucion.
    local rx, ry = GetActiveScreenResolution()
    local px, py = 1.0 / rx, 1.0 / ry

    local w = anchoTexto + 0.012 + 3.0 * px
    local h = 0.03
    local cx = sx
    local cy = sy + 0.0125

    local cantoX, cantoY = 2.0 * px, 2.0 * py
    local sombraX, sombraY = 3.0 * px, 3.0 * py

    -- Sombra dura, canto negro y la pieza.
    DrawRect(cx + sombraX, cy + sombraY, w + 2.0 * cantoX, h + 2.0 * cantoY, 0, 0, 0, 255)
    DrawRect(cx, cy, w + 2.0 * cantoX, h + 2.0 * cantoY, 0, 0, 0, 255)
    DrawRect(cx, cy, w, h, 220, 221, 224, 255)
    -- El filete rosa, por dentro del canto izquierdo.
    local filete = 3.0 * px
    DrawRect(cx - w / 2.0 + filete / 2.0, cy, filete, h, 216, 27, 85, 255)

    SetTextScale(escala, escala)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(11, 11, 13, 255)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(texto)
    EndTextCommandDisplayText(sx + filete / 2.0, sy)
end
