--[[ Las texturas del servidor (calles, aceras, terreno), en caliente.

     No sustituyen a las del juego por nombre de fichero: van en diccionarios propios
     (ov_X y ov_X_hi, en origen_visuals_stream) y aqui se cambian una a una con
     AddReplaceTexture. Asi cada jugador decide en el panel si las quiere, y con el
     apartado apagado el juego queda como viene.

     No se cargan todas: el juego dice que diccionarios suyos tiene cargados
     (HasStreamedTextureDictLoaded vale tambien para los del mapa), y solo de esos se
     trae la version propia. Cuando el juego suelta uno, se suelta la nuestra.
     Las de los coches (vehshare) van igual, con su propio apartado.
     La version de cerca (ov_X_hi) solo entra mientras el juego tiene cargada la suya
     (X+hi), y solo en calidad «Alta». ]]

if not Config.TexturasEnCaliente then return end

local POR_REPASO = 40     -- diccionarios que se miran en cada repaso
local CADA = 200          -- ms entre repasos: la vuelta entera, unos tres segundos

local bases = {}
for base in pairs(OVTexturas) do bases[#bases + 1] = base end
table.sort(bases)

local puesto = {}         -- base -> { textura -> diccionario propio que la sirve }
local pedidos = {}        -- diccionario propio -> true mientras lo tengamos pedido

local function Pedir(dic)
    if not pedidos[dic] then RequestStreamedTextureDict(dic, false) pedidos[dic] = true end
    return HasStreamedTextureDictLoaded(dic)
end

local function Soltar(dic)
    if pedidos[dic] then SetStreamedTextureDictAsNoLongerNeeded(dic) pedidos[dic] = nil end
end

--- Deja un diccionario del juego en el nivel pedido: 0 = el del juego, 1 = el propio,
--- 2 = el propio con la version de cerca. Devuelve false si aun esta cargando.
local function Dejar(base, e, nivel)
    local lo = 'ov_' .. (base:gsub('%+', '_'))     -- x+hidr se sirve como ov_x_hidr
    local hi = lo .. '_hi'
    local quiere = {}
    if nivel >= 1 and e.lo then
        if not Pedir(lo) then return false end
        for _, n in ipairs(e.lo) do quiere[n] = lo end
    end
    if nivel >= 2 and e.hi then
        if not Pedir(hi) then return false end
        for _, n in ipairs(e.hi) do quiere[n] = hi end
    end

    local hay = puesto[base] or {}
    for n, dic in pairs(hay) do
        if quiere[n] ~= dic then RemoveReplaceTexture(base, n) end
    end
    for n, dic in pairs(quiere) do
        if hay[n] ~= dic then AddReplaceTexture(base, n, dic, n) end
    end
    puesto[base] = next(quiere) and quiere or nil

    if nivel < 2 or not e.hi then Soltar(hi) end
    if nivel < 1 or not e.lo then Soltar(lo) end
    return true
end

local function Quitar()
    for base in pairs(puesto) do Dejar(base, OVTexturas[base], 0) end
    for dic in pairs(pedidos) do Soltar(dic) end
end

CreateThread(function()
    local i = 0
    while true do
        if OVCalidadTexturas() == 0 and OVCalidadTexturas('coches') == 0 and not next(puesto) and not next(pedidos) then
            Wait(1000)
        else
            for _ = 1, math.min(POR_REPASO, #bases) do
                i = i % #bases + 1
                local base = bases[i]
                local e = OVTexturas[base]
                local calidad = OVCalidadTexturas(e.grupo)      -- 0, 1 o 2
                local nivel = 0
                if calidad > 0 and HasStreamedTextureDictLoaded(base) then
                    nivel = (calidad >= 2 and e.hi and HasStreamedTextureDictLoaded(base .. '+hi')) and 2 or 1
                    if nivel == 1 and not e.lo then nivel = 0 end
                end
                Dejar(base, e, nivel)
            end
            Wait(CADA)
        end
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then Quitar() end
end)

exports('TexturasPuestas', function()
    local d, t = 0, 0
    for _, q in pairs(puesto) do d = d + 1 for _ in pairs(q) do t = t + 1 end end
    local p = 0 for _ in pairs(pedidos) do p = p + 1 end
    return d, t, p
end)
