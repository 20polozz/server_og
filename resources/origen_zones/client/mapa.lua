--[[ ── Las zonas en el mapa y en el suelo ─────────────────────────────────────

     Dos cosas distintas:

     · El blip, que lo ve todo el mundo si la zona lo lleva puesto. GTA no sabe
       dibujar un polígono en el mapa, así que un polígono se marca con su
       chincheta en el centro y ya; el círculo sí puede llevar además su rueda
       de color.

     · El borde en el suelo, que solo se enciende desde el panel y solo lo ve
       quien lo enciende. Es para colocar la zona: sin verla pintada en el
       sitio nunca sabes si el polígono cae donde creías. ]]

Mapa = {}

local blips = {}
local bordes = false

-- Los blips van por número, no por color: hay 85 y ninguno es «#ff2d6a». Se
-- coge el más cercano al color de la zona, que para una chincheta de 8 px es
-- más que suficiente.
local PALETA = {
    { n = 1,  r = 224, g = 50,  b = 50 },   -- rojo
    { n = 2,  r = 114, g = 204, b = 114 },  -- verde
    { n = 3,  r = 93,  g = 182, b = 229 },  -- azul
    { n = 5,  r = 240, g = 200, b = 80 },   -- amarillo
    { n = 17, r = 255, g = 149, b = 64 },   -- naranja
    { n = 27, r = 255, g = 102, b = 178 },  -- rosa
    { n = 38, r = 0,   g = 102, b = 204 },  -- azul oscuro
    { n = 44, r = 160, g = 160, b = 160 },  -- gris
    { n = 48, r = 150, g = 100, b = 220 },  -- morado
    { n = 49, r = 140, g = 40,  b = 40 },   -- granate
    { n = 0,  r = 255, g = 255, b = 255 },  -- blanco
}

local function ColorDeBlip(hex)
    if type(hex) ~= 'string' or #hex < 7 then return 1 end

    local r = tonumber(hex:sub(2, 3), 16) or 255
    local g = tonumber(hex:sub(4, 5), 16) or 45
    local b = tonumber(hex:sub(6, 7), 16) or 106

    local mejor, cerca = 1, math.huge
    for _, c in ipairs(PALETA) do
        local d = (c.r - r) ^ 2 + (c.g - g) ^ 2 + (c.b - b) ^ 2
        if d < cerca then mejor, cerca = c.n, d end
    end
    return mejor
end

local function Borrar()
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    blips = {}
end

function Mapa.Repintar()
    Borrar()

    for _, zona in pairs(Zonas.todas) do
        if zona.activa and (zona.blip_sprite or 0) > 0 and zona._cx then
            local color = ColorDeBlip(zona.color)

            if zona.forma == 'circulo' then
                local rueda = AddBlipForRadius(zona._cx + 0.0, zona._cy + 0.0, 0.0, zona.radio + 0.0)
                SetBlipColour(rueda, color)
                SetBlipAlpha(rueda, 100)
                blips[#blips + 1] = rueda
            end

            local blip = AddBlipForCoord(zona._cx + 0.0, zona._cy + 0.0, 0.0)
            SetBlipSprite(blip, zona.blip_sprite)
            SetBlipColour(blip, color)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(zona.nombre)
            EndTextCommandSetBlipName(blip)
            blips[#blips + 1] = blip
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EL BORDE EN EL SUELO
-- ═══════════════════════════════════════════════════════════════════════════

local alturas = {}   -- [id] = { z por esquina }, que medir el suelo es caro

local function AlturaDe(zona, i, x, y)
    alturas[zona.id] = alturas[zona.id] or {}
    local guardada = alturas[zona.id][i]
    if guardada then return guardada end

    local hay, z = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, 1000.0, false)
    local altura = (hay and z or GetEntityCoords(PlayerPedId()).z) + 0.5
    alturas[zona.id][i] = altura
    return altura
end

function Mapa.Bordes(si)
    bordes = si and true or false
    if not bordes then alturas = {} end
    return bordes
end

function Mapa.VeBordes()
    return bordes
end

CreateThread(function()
    while true do
        if not bordes then
            Wait(500)
        else
            local yo = GetEntityCoords(PlayerPedId())

            for _, zona in pairs(Zonas.todas) do
                if zona._cx and #(vector2(yo.x, yo.y) - vector2(zona._cx, zona._cy)) < 350.0 then
                    local r = tonumber((zona.color or '#ff2d6a'):sub(2, 3), 16) or 255
                    local g = tonumber((zona.color or '#ff2d6a'):sub(4, 5), 16) or 45
                    local b = tonumber((zona.color or '#ff2d6a'):sub(6, 7), 16) or 106

                    if zona.forma == 'circulo' then
                        -- Un círculo se dibuja como un polígono de 24 lados: a
                        -- ojo, desde el suelo, no se distingue de una curva.
                        local previo
                        for paso = 0, 24 do
                            local a = (paso / 24) * math.pi * 2
                            local x = zona._cx + math.cos(a) * zona.radio
                            local y = zona._cy + math.sin(a) * zona.radio
                            local z = AlturaDe(zona, paso + 1, x, y)
                            if previo then
                                DrawLine(previo.x, previo.y, previo.z, x, y, z, r, g, b, 200)
                            end
                            previo = { x = x, y = y, z = z }
                        end
                    elseif zona.puntos and #zona.puntos > 2 then
                        local n = #zona.puntos
                        for i = 1, n do
                            local a = zona.puntos[i]
                            local b2 = zona.puntos[i % n + 1]
                            local za = AlturaDe(zona, i, a.x, a.y)
                            local zb = AlturaDe(zona, i % n + 1, b2.x, b2.y)
                            DrawLine(a.x + 0.0, a.y + 0.0, za, b2.x + 0.0, b2.y + 0.0, zb, r, g, b, 200)
                            -- Una columna en cada esquina, que es lo que deja
                            -- ver si el polígono está donde crees.
                            DrawLine(a.x + 0.0, a.y + 0.0, za, a.x + 0.0, a.y + 0.0, za + 3.0, r, g, b, 200)
                        end
                    end
                end
            end

            Wait(0)
        end
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then Borrar() end
end)
