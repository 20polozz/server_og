PlayerTags = false

--[[ Chapa «pegatina» dibujada con DrawRect: sombra dura abajo a la derecha,
     canto negro fino, relleno gris claro (o rosa) y tinta negra. Sin códigos
     de color de GTA (~g~, ~o~…): se quitan si vienen dentro. La usan /tags,
     /coords y el láser (client/laser.lua). ]]
local CHAPA_FUENTE = 4   -- la condensada de GTA, la del resto del servidor
PEGATINA_PIEZA = { 220, 221, 224 }
PEGATINA_ROSA  = { 216, 27, 85 }

function PegatinaChapa(sx, sy, text, escala, relleno)
    text = (tostring(text or ''):gsub('~[^~]*~', ''):gsub('~', ''))
    escala = escala or 0.32
    BeginTextCommandGetWidth('STRING')
    AddTextComponentSubstringPlayerName(text)
    SetTextFont(CHAPA_FUENTE)
    SetTextScale(escala, escala)
    local w = EndTextCommandGetWidth(true) + 0.012
    local alto = GetRenderedCharacterHeight(escala, CHAPA_FUENTE)
    local h = alto + 0.012
    local f = relleno or PEGATINA_PIEZA
    DrawRect(sx + 0.0022, sy + 0.0040, w + 0.0015, h + 0.0027, 0, 0, 0, 255)
    DrawRect(sx, sy, w + 0.0015, h + 0.0027, 0, 0, 0, 255)
    DrawRect(sx, sy, w, h, f[1], f[2], f[3], 255)
    SetTextFont(CHAPA_FUENTE)
    SetTextScale(escala, escala)
    SetTextColour(11, 11, 13, 255)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(sx, sy - alto * 0.62)
end

--- Chapa sobre un punto del mundo. acento = true la pinta en rosa.
function DDrawText3D(x, y, z, text, acento, scale)
    if not x or not y or not z or not text then
        return
    end

    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(x, y, z)
    if not onScreen then
        return
    end

    PegatinaChapa(sx, sy, text, scale or 0.30, acento and PEGATINA_ROSA or nil)
end

--[[ /tags · Estilo directo nativo en pantalla:
     Texto blanco [ID] Nombre con fuente 0, contorno negro y barra de vida
     horizontal en turquesa (#00ebb0) sobre fondo oscuro debajo del texto.
     Dibuja directamente en el fotograma sin intermediación de NUI. ]]
local TAGS_RADIO   = 180.0
local TAGS_MAXIMO  = 80
local TAGS_REPASO  = 250   -- ms entre repasos de quién está cerca
local HUESO_CABEZA = 31086 -- SKEL_Head
local tagsVuelta   = 0

local COLOR_VIDA   = { 0, 235, 175, 255 }  -- Turquesa / cian de la captura
local COLOR_ARMAD  = { 30, 144, 255, 255 } -- Azul para chaleco si lleva
local COLOR_FONDO  = { 10, 10, 10, 210 }   -- Fondo oscuro de la barra

local function ObtenerPosicionCabeza(ped)
    local cabeza = GetPedBoneCoords(ped, HUESO_CABEZA, 0.0, 0.0, 0.0)
    if not cabeza or cabeza.x == 0.0 or #(cabeza) < 2.0 then
        local coords = GetEntityCoords(ped)
        if coords and #(coords) >= 2.0 then
            cabeza = coords + vector3(0.0, 0.0, 0.85)
        else
            return nil
        end
    end
    return cabeza
end

local function DibujarTagJugador(sx, sy, dist, serverId, nombre, ped, isTalking)
    local scale = math.max(0.20, math.min(0.33, 0.33 - (dist / 160.0) * 0.13))
    local factor = scale / 0.32

    -- 1. Texto: [ID] Nombre
    local texto = string.format("[%s] %s", serverId, nombre)
    SetTextFont(0)
    SetTextScale(scale, scale)
    if isTalking then
        SetTextColour(255, 215, 0, 255)   -- Amarillo / dorado al hablar
    else
        SetTextColour(255, 255, 255, 255) -- Blanco puro
    end
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(texto)
    EndTextCommandDisplayText(sx, sy - 0.008 * factor)

    -- 2. Barra de vida debajo
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    if maxHealth <= 100 then maxHealth = 200 end
    local healthPct = math.max(0.0, math.min(1.0, (health - 100.0) / (maxHealth - 100.0)))
    if IsEntityDead(ped) or health <= 0 then
        healthPct = 0.0
    end

    local barW = 0.038 * factor
    local barH = 0.0042 * factor
    local barY = sy + 0.016 * factor

    -- Fondo oscuro
    DrawRect(sx, barY, barW + 0.001, barH + 0.002, COLOR_FONDO[1], COLOR_FONDO[2], COLOR_FONDO[3], COLOR_FONDO[4])

    -- Relleno de vida (alineado a la izquierda)
    if healthPct > 0.0 then
        local fillW = barW * healthPct
        local fillX = sx - (barW - fillW) / 2.0
        DrawRect(fillX, barY, fillW, barH, COLOR_VIDA[1], COLOR_VIDA[2], COLOR_VIDA[3], COLOR_VIDA[4])
    end

    -- Si lleva chaleco/armadura, mostrar barrita azul fina debajo
    local armour = GetPedArmour(ped)
    if armour and armour > 0 then
        local armPct = math.max(0.0, math.min(1.0, armour / 100.0))
        local armBarH = barH * 0.75
        local armBarY = barY + barH + 0.0015
        DrawRect(sx, armBarY, barW + 0.001, armBarH + 0.002, COLOR_FONDO[1], COLOR_FONDO[2], COLOR_FONDO[3], COLOR_FONDO[4])
        local armFillW = barW * armPct
        local armFillX = sx - (barW - armFillW) / 2.0
        DrawRect(armFillX, armBarY, armFillW, armBarH, COLOR_ARMAD[1], COLOR_ARMAD[2], COLOR_ARMAD[3], COLOR_ARMAD[4])
    end
end

function ToggleTags()
    PlayerTags = not PlayerTags
    tagsVuelta = tagsVuelta + 1
    SendNUIMessage({ action = 'adminTagsOff' }) -- Apaga NUI residual si lo hubiera

    if not PlayerTags then
        return
    end

    local vuelta = tagsVuelta
    CreateThread(function()
        local cerca = {}
        local proximoRepaso = 0

        while PlayerTags and vuelta == tagsVuelta do
            local yo = PlayerPedId()
            local cam = GetFinalRenderedCamCoord()
            local ahora = GetGameTimer()

            -- Repaso de jugadores cercanos cada 250 ms
            if ahora >= proximoRepaso then
                proximoRepaso = ahora + TAGS_REPASO

                local candidatos = {}
                local plist = GetActivePlayers()
                for i = 1, #plist do
                    local id = plist[i]
                    local ped = GetPlayerPed(id)
                    if ped ~= yo and ped ~= 0 and DoesEntityExist(ped) then
                        local pedCoords = GetEntityCoords(ped)
                        if #(pedCoords) >= 2.0 then
                            local d = #(cam - pedCoords)
                            if d <= TAGS_RADIO then
                                candidatos[#candidatos + 1] = { id = id, ped = ped, d = d }
                            end
                        end
                    end
                end
                table.sort(candidatos, function(a, b) return a.d < b.d end)

                cerca = {}
                for i = 1, #candidatos do
                    if #cerca >= TAGS_MAXIMO then break end
                    local p = candidatos[i]
                    local sid = GetPlayerServerId(p.id)
                    local nombre = GetPlayerName(p.id) or ''
                    if nombre == '' then
                        nombre = 'ID ' .. tostring(sid)
                    end
                    cerca[#cerca + 1] = {
                        id = p.id,
                        ped = p.ped,
                        sid = sid,
                        nombre = nombre
                    }
                end
            end

            -- Dibujo directo en pantalla (cada fotograma a 60/144 fps sin retardo)
            if not IsPauseMenuActive() and not IsScreenFadedOut() then
                for i = 1, #cerca do
                    local p = cerca[i]
                    local ped = GetPlayerPed(p.id)
                    if ped ~= 0 and DoesEntityExist(ped) then
                        local cabeza = ObtenerPosicionCabeza(ped)
                        if cabeza then
                            local dist = #(cam - cabeza)
                            if dist <= TAGS_RADIO then
                                local enPantalla, sx, sy = GetScreenCoordFromWorldCoord(cabeza.x, cabeza.y, cabeza.z + 0.35)
                                if enPantalla then
                                    local isTalking = NetworkIsPlayerTalking(p.id)
                                    DibujarTagJugador(sx, sy, dist, p.sid, p.nombre, ped, isTalking)
                                end
                            end
                        end
                    end
                end
            end

            Wait(0)
        end
    end)
end
