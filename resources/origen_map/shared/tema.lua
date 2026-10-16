--[[ ═══════════════════════════════════════════════════════════════════════
     El puente de la interfaz hacia la NUI de ESTE recurso: la MARCA (el
     color de la casa) y el SILENCIO de los menus.

     Igual que foco.lua: no se carga en origen_map, se carga EN CADA RECURSO
     QUE TIENE INTERFAZ, junto al vigilante del foco:

         client_scripts {
             '@origen_map/shared/foco.lua',
             '@origen_map/shared/tema.lua',
             'client/main.lua',
         }

     SendNUIMessage solo llega a la pantalla del recurso que lo llama: por eso
     hace falta una copia de este puente en cada uno. El fichero se sigue
     llamando tema.lua porque lo nombran todos los fxmanifest; el modo oscuro
     se quito del servidor el 06/10.
   ═══════════════════════════════════════════════════════════════════════ ]]

if IsDuplicityVersion() then return end

--[[ ═══════════════════════════════════════════════════════════════════════
     LA MARCA (02/10): el color de la casa segun el servidor que arranca.

     El mismo codigo sirve a dos servidores. En el cfg:

         setr origen:marca "origen"    -- rosa, el de siempre (y el de fabrica)
         setr origen:marca "nacion"    -- naranja

     Va en este fichero porque ya lo cargan todos los recursos con interfaz,
     que son tambien los que pintan cosas en el mundo. Tiene dos mitades:

     1. La pagina pregunta la marca al cargar (trozo «ORIGEN · marca» del
        <head>, que reparte kit/repartir-marca.py) y, si no es «origen», se
        repinta sola. Aqui solo se le contesta.
     2. Lo que se pinta desde Lua (marcadores, lineas, textos, contornos) se
        cambia en la SALIDA: con otra marca puesta se envuelven las natives de
        dibujo y todo rosa que les llegue sale del color nuevo. Nadie tiene que
        tocar su codigo, y un arreglo hecho en origen vale igual en nacion.

     En «origen» no se envuelve nada: ni una llamada de mas.

     La cuenta del color es LA MISMA que la de kit/marca.js. Si se toca una,
     se toca la otra.
   ═══════════════════════════════════════════════════════════════════════ ]]

local PALETAS = {
    nacion = {
        tono = 28.5,
        sat = 1.04,
        luz = { { 0, 0 }, { 0.267, 0.212 }, { 0.396, 0.36 }, { 0.453, 0.565 }, { 0.714, 0.68 }, { 0.8, 0.857 }, { 1, 1 } },
        fijos = {
            [0xe0074f] = { 253, 138, 35 }, [0xfc0259] = { 253, 138, 35 },
            -- rosa menos neon (06/10): el mismo naranja que el rosa de antes
            [0xd81b55] = { 255, 146, 48 }, [0xdf2f63] = { 255, 154, 64 }, [0xb3123f] = { 227, 108, 0 },
            [0xff6d97] = { 255, 170, 92 },
            [0xfd9bbd] = { 255, 217, 182 },
            [0x7d0b31] = { 106, 52, 2 }, [0x82173c] = { 106, 52, 2 },
        },
    },
}

local marca = GetConvar('origen:marca', 'origen')
local paleta = PALETAS[marca]

--- Para el codigo que quiera saberlo (un logo, un texto con el nombre).
OrigenMarca = marca

RegisterNUICallback('origen:marca:dame', function(_, cb)
    cb({ marca = marca })
end)

if paleta then
    local memo = {}
    local floor, abs, max, min = math.floor, math.abs, math.max, math.min

    --- El color de la marca nueva, o nil si no es de la familia del rosa.
    local function cambiar(r, g, b)
        r, g, b = floor(r + 0.5), floor(g + 0.5), floor(b + 0.5)
        local k = r * 65536 + g * 256 + b
        local res = memo[k]
        if res ~= nil then return res or nil end
        res = false
        local mx, mn = max(r, g, b), min(r, g, b)
        local d = mx - mn
        if d > 0 then
            local l = (mx + mn) / 510
            local s = d / (255 - abs(mx + mn - 255))
            local h
            if mx == r then h = ((g - b) / d) % 6
            elseif mx == g then h = (b - r) / d + 2
            else h = (r - g) / d + 4 end
            h = (h * 60) % 360
            if s >= 0.3 and h >= 318 and h < 349 then
                res = paleta.fijos[k]
                if not res then
                    local c, L = paleta.luz, l
                    for i = 2, #c do
                        if l <= c[i][1] then
                            L = c[i - 1][2] + (c[i][2] - c[i - 1][2]) * (l - c[i - 1][1]) / (c[i][1] - c[i - 1][1])
                            break
                        end
                    end
                    local S = min(1, s * paleta.sat)
                    local C = (1 - abs(2 * L - 1)) * S
                    local H = paleta.tono / 60
                    local X = C * (1 - abs(H % 2 - 1))
                    local m = L - C / 2
                    local t
                    if H < 1 then t = { C, X, 0 } elseif H < 2 then t = { X, C, 0 }
                    elseif H < 3 then t = { 0, C, X } elseif H < 4 then t = { 0, X, C }
                    elseif H < 5 then t = { X, 0, C } else t = { C, 0, X } end
                    res = { floor((t[1] + m) * 255 + 0.5), floor((t[2] + m) * 255 + 0.5), floor((t[3] + m) * 255 + 0.5) }
                end
            end
        end
        memo[k] = res
        return res or nil
    end

    --- Para quien guarda el color en una tabla y lo pasa por otro camino.
    --- @return number, number, number
    function OrigenMarcaColor(r, g, b)
        local n = cambiar(r, g, b)
        if n then return n[1], n[2], n[3] end
        return r, g, b
    end

    --[[ Envuelve una native de dibujo: `pos` es donde va el rojo (el verde y
         el azul le siguen) y `escala` es 1 si los canales van de 0 a 1.
         Solo se rehace la llamada cuando el color ES rosa; lo demas pasa
         tal cual, sin crear nada. ]]
    local function envolver(nombre, pos, escala)
        local original = _G[nombre]
        if type(original) ~= 'function' then return end
        local f = escala and 255 or 1
        _G[nombre] = function(...)
            local r, g, b = select(pos, ...)
            if type(r) == 'number' and type(g) == 'number' and type(b) == 'number' then
                local n = cambiar(r * f, g * f, b * f)
                if n then
                    local a = table.pack(...)
                    -- Sin dividir cuando no hace falta: una division deja
                    -- un decimal, y la native espera un entero.
                    if escala then
                        a[pos], a[pos + 1], a[pos + 2] = n[1] / 255, n[2] / 255, n[3] / 255
                    else
                        a[pos], a[pos + 1], a[pos + 2] = n[1], n[2], n[3]
                    end
                    return original(table.unpack(a, 1, a.n))
                end
            end
            return original(...)
        end
    end

    envolver('DrawMarker', 14)
    envolver('DrawLine', 7)
    envolver('DrawPoly', 10)
    envolver('DrawRect', 5)
    envolver('DrawBox', 7)
    envolver('DrawSphere', 5)
    envolver('DrawSprite', 8)
    envolver('DrawLightWithRange', 4)
    envolver('DrawSpotLight', 7)
    envolver('SetTextColour', 1)
    envolver('SetEntityDrawOutlineColor', 1)
    envolver('SetBlipSecondaryColour', 2)
    envolver('SetParticleFxLoopedColour', 2, true)
    envolver('SetParticleFxNonLoopedColour', 1, true)
end

--[[ ── El silencio de la interfaz ─────────────────────────────────────────
     La pagina lo pregunta al cargar (callback de abajo) y luego se entera por
     el aviso global. Estos recursos no se callan nunca: su sonido es
     contenido (musica de la carga, la radio), no ruido de menu. ]]
local SIEMPRE_SUENA = {
    origen_loadingscreen = true,
    origen_loadingasset = true,
    origen_radio = true,
    origen_screens = true,
    origen_notify = true,
    origen_vehiclesounds = true,
    origen_speaker = true,
}
local silencio = false
local sinSilencio = SIEMPRE_SUENA[GetCurrentResourceName()] == true

local function avisarSilencio()
    SendNUIMessage({ accion = 'origen:silencio', silencio = silencio and not sinSilencio })
end

AddEventHandler('origen:silencio:aplicar', function(si)
    silencio = si == true
    avisarSilencio()
end)

--[[ Lo que pregunta la pagina al cargar (trozo «ORIGEN · interfaz» del
     <head>). Se llama asi por historia: antes tambien llevaba el tema. ]]
RegisterNUICallback('origen:tema:dame', function(_, cb)
    cb({ silencio = silencio and not sinSilencio })
end)

CreateThread(function()
    for _ = 1, 20 do
        local ok, valor = pcall(function()
            return exports.origen_map:SilencioActual()
        end)
        if ok and type(valor) == 'boolean' then
            silencio = valor
            if silencio then avisarSilencio() end
            return
        end
        Wait(250)
    end
end)
