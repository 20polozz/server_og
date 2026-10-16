--[[ ── Origen Games · el puente con la pantalla ─────────────────────────────

     La NUI tiene dos caras que no se pisan: el menú de cada juego (con foco,
     se abre y se cierra) y el HUD de la partida (sin foco, encima del juego).
     Las dos hablan por aquí. ]]

Nui = {}

function Nui.Enviar(accion, datos)
    SendNUIMessage({ accion = accion, datos = datos })
end

--- Un sonido de la pantalla oído desde un punto del mundo: volumen según la
--- distancia a la cámara y lado según hacia dónde mira. `propio`: suena de
--- cerca (es de uno mismo). Los tipos están en source-ui/src/burlas.ts.
function Nui.Sonido(tipo, x, y, z, propio, alcance)
    alcance = tonumber(alcance) or 45.0

    if not x then
        return Nui.Enviar('sonido', { tipo = tipo, volumen = 0.8, pan = 0.0 })
    end

    local cam = GetFinalRenderedCamCoord()
    local dx, dy, dz = x - cam.x, y - cam.y, z - cam.z
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

    if dist > alcance and not propio then return end

    local volumen = propio and 0.55 or math.max(0.0, 1.0 - dist / alcance) ^ 1.4

    --[[ El lado: cuánto cae el sonido hacia la derecha de la cámara. En GTA,
         con rumbo z la cámara mira a (-sen z, cos z) y su derecha es
         (cos z, sen z); el producto escalar con la dirección del sonido da de
         -1 (izquierda) a 1 (derecha). ]]
    local pan = 0.0
    local plano = math.sqrt(dx * dx + dy * dy)
    if not propio and plano > 0.5 then
        local rumbo = math.rad(GetFinalRenderedCamRot(2).z)
        pan = (dx / plano) * math.cos(rumbo) + (dy / plano) * math.sin(rumbo)
        pan = math.max(-1.0, math.min(1.0, pan))
    end

    Nui.Enviar('sonido', { tipo = tipo, volumen = volumen, pan = pan })
end
