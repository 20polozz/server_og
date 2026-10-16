-- ════════════════════════════════════════════════════════════════════
--  origen_screens · qué enlaces entran en una tele
--
--  SOLO YouTube y Twitch. Esto corre en el SERVIDOR con lo que manda el
--  cliente, así que se trata como hostil:
--
--   * Se trocea la URL a mano (esquema, autoridad, ruta, consulta). Nada de
--     string.find sobre la cadena entera: «youtube.com.malo.com»,
--     «malo.com/?youtube.com» o «youtube.com@malo.com» pasarían.
--   * El host tiene que ser EXACTAMENTE uno de la lista. Sin usuario (@), sin
--     puerto, sin barra invertida (el navegador la lee como /), sin punto
--     final, sin %-codificar, sin espacios ni caracteres de control.
--   * De la URL solo se saca un identificador que cumple un patrón cerrado
--     (el id de 11 caracteres de YouTube, el nombre de canal o el número de
--     vídeo de Twitch). La URL que se pinta la reconstruye la página de la
--     tele a partir de ese id: la URL cruda del jugador no llega nunca a la
--     DUI.
--
--  Es Lua puro a propósito (sin natives): se prueba fuera del juego.
--  Devuelve nil, motivo  ó  { tipo, ref, clase, inicio, url }.
-- ════════════════════════════════════════════════════════════════════

Enlaces = {}

local HOSTS_YOUTUBE = {
    ['youtube.com'] = true,
    ['www.youtube.com'] = true,
    ['m.youtube.com'] = true,
    ['youtu.be'] = true,
}

local HOSTS_TWITCH = {
    ['twitch.tv'] = true,
    ['www.twitch.tv'] = true,
    ['player.twitch.tv'] = true,
}

-- Primeros tramos de twitch.tv que NO son un canal.
local RUTAS_TWITCH_RESERVADAS = {
    directory = true, videos = true, settings = true, p = true, search = true,
    downloads = true, jobs = true, turbo = true, subscriptions = true,
    inventory = true, wallet = true, friends = true, messages = true,
    login = true, signup = true, prime = true, store = true, drops = true,
    broadcast = true, following = true, clip = true, clips = true, moderator = true,
    popout = true, embed = true, legal = true, privacy = true, team = true,
}

local LARGO_MAXIMO = 300
local SEGUNDOS_MAXIMOS = 12 * 3600

local function esIdYoutube(s)
    return type(s) == 'string' and #s == 11 and s:match('^[%w_%-]+$') ~= nil
end

local function esCanalTwitch(s)
    return type(s) == 'string' and #s >= 3 and #s <= 25 and s:match('^[%w_]+$') ~= nil
end

local function esVodTwitch(s)
    return type(s) == 'string' and #s >= 1 and #s <= 12 and s:match('^%d+$') ~= nil
end

-- «90», «90s», «1h2m3s», «2m» → segundos (0 si no se entiende).
local function leerTiempo(s)
    if type(s) ~= 'string' or s == '' or #s > 12 then return 0 end
    if s:match('^%d+$') then
        return math.min(tonumber(s) or 0, SEGUNDOS_MAXIMOS)
    end
    if not s:match('^[%dhms]+$') then return 0 end
    local total, visto = 0, false
    for cifra, unidad in s:gmatch('(%d+)([hms])') do
        visto = true
        local n = tonumber(cifra) or 0
        if unidad == 'h' then total = total + n * 3600
        elseif unidad == 'm' then total = total + n * 60
        else total = total + n end
    end
    -- «1h2x» o restos sueltos no cuentan: la cadena entera tiene que casar.
    local rehecho = s:gsub('%d+[hms]', '')
    if not visto or rehecho ~= '' then return 0 end
    return math.min(total, SEGUNDOS_MAXIMOS)
end

-- Consulta «a=1&b=2» → tabla. Un parámetro repetido se queda con el PRIMERO.
-- No se decodifica %xx: ninguno de los valores que se aceptan lo necesita, y
-- así «v=%41…» no casa con el patrón y se rechaza.
local function leerConsulta(q)
    local t = {}
    if not q or q == '' then return t end
    for trozo in (q .. '&'):gmatch('([^&]*)&') do
        local k, v = trozo:match('^([^=]+)=(.*)$')
        if k and t[k] == nil then t[k] = v end
    end
    return t
end

local function tramos(ruta)
    local lista = {}
    for s in ruta:gmatch('[^/]+') do lista[#lista + 1] = s end
    return lista
end

function Enlaces.Analizar(entrada)
    if type(entrada) ~= 'string' then return nil, 'Enlace no válido' end

    local url = entrada:match('^%s*(.-)%s*$')
    if url == '' then return nil, 'Pega un enlace de YouTube o Twitch' end
    if #url > LARGO_MAXIMO then return nil, 'Enlace demasiado largo' end

    -- Nada de espacios, controles, comillas, <> ni barra invertida en medio.
    if url:find('[%c%s\\<>"\'`]') then return nil, 'Enlace no válido' end

    -- Esquema: solo http(s). Sin esquema se entiende https.
    local esquema, resto = url:match('^([%a][%w+.%-]*):(.*)$')
    if esquema then
        esquema = esquema:lower()
        if esquema ~= 'https' and esquema ~= 'http' then
            -- javascript:, data:, file:, nui:… o «youtube.com:443/…»
            return nil, 'Solo se admiten enlaces de YouTube o Twitch'
        end
        if resto:sub(1, 2) ~= '//' then return nil, 'Enlace no válido' end
        resto = resto:sub(3)
    else
        if url:sub(1, 2) == '//' then return nil, 'Enlace no válido' end
        resto = url
    end

    -- Autoridad hasta la primera / ? #
    local autoridad, cola = resto:match('^([^/?#]*)(.*)$')
    if not autoridad or autoridad == '' then return nil, 'Enlace no válido' end
    if autoridad:find('@', 1, true) then return nil, 'Enlace no válido' end
    if autoridad:find(':', 1, true) then return nil, 'Enlace no válido' end
    if autoridad:find('%%') then return nil, 'Enlace no válido' end

    local host = autoridad:lower()
    local esYoutube, esTwitch = HOSTS_YOUTUBE[host], HOSTS_TWITCH[host]
    if not esYoutube and not esTwitch then
        return nil, 'Solo se admiten enlaces de YouTube o Twitch'
    end

    -- Ruta, consulta y fragmento.
    local ruta, consulta = cola:match('^([^?#]*)%??([^#]*)')
    ruta = ruta or ''
    local q = leerConsulta(consulta)
    local partes = tramos(ruta)

    if esYoutube then
        local id
        if host == 'youtu.be' then
            if #partes == 1 then id = partes[1] end
        elseif #partes == 1 and partes[1] == 'watch' then
            id = q.v
        elseif #partes == 2 and (partes[1] == 'embed' or partes[1] == 'shorts' or partes[1] == 'live' or partes[1] == 'v') then
            id = partes[2]
        end

        if not esIdYoutube(id) then return nil, 'No se reconoce el vídeo de YouTube' end

        return {
            tipo = 'youtube',
            ref = id,
            clase = 'video',
            inicio = leerTiempo(q.t or q.start),
            url = 'https://www.youtube.com/watch?v=' .. id,
        }
    end

    -- Twitch
    if host == 'player.twitch.tv' then
        if #partes ~= 0 then return nil, 'No se reconoce el enlace de Twitch' end
        if q.channel then
            local canal = q.channel:lower()
            if not esCanalTwitch(canal) then return nil, 'Canal de Twitch no válido' end
            return { tipo = 'twitch', ref = canal, clase = 'directo', inicio = 0, url = 'https://www.twitch.tv/' .. canal }
        end
        if q.video then
            local vod = q.video:gsub('^v', '')
            if not esVodTwitch(vod) then return nil, 'Vídeo de Twitch no válido' end
            return { tipo = 'twitch', ref = vod, clase = 'vod', inicio = leerTiempo(q.time or q.t), url = 'https://www.twitch.tv/videos/' .. vod }
        end
        return nil, 'No se reconoce el enlace de Twitch'
    end

    -- twitch.tv/videos/123  ·  twitch.tv/canal/video/123 (formato viejo)
    if #partes == 2 and partes[1] == 'videos' then
        if not esVodTwitch(partes[2]) then return nil, 'Vídeo de Twitch no válido' end
        return { tipo = 'twitch', ref = partes[2], clase = 'vod', inicio = leerTiempo(q.t), url = 'https://www.twitch.tv/videos/' .. partes[2] }
    end
    if #partes == 3 and partes[2] == 'video' and esCanalTwitch(partes[1]) then
        if not esVodTwitch(partes[3]) then return nil, 'Vídeo de Twitch no válido' end
        return { tipo = 'twitch', ref = partes[3], clase = 'vod', inicio = leerTiempo(q.t), url = 'https://www.twitch.tv/videos/' .. partes[3] }
    end

    -- twitch.tv/canal (se admite una barra final, nada más detrás)
    if #partes == 1 then
        local canal = partes[1]:lower()
        if RUTAS_TWITCH_RESERVADAS[canal] or not esCanalTwitch(canal) then
            return nil, 'Canal de Twitch no válido'
        end
        return { tipo = 'twitch', ref = canal, clase = 'directo', inicio = 0, url = 'https://www.twitch.tv/' .. canal }
    end

    return nil, 'No se reconoce el enlace de Twitch'
end

-- Para comprobar un estado que ya viene de la base de datos o del mueble de
-- una casa: mismos patrones cerrados que arriba.
function Enlaces.ContenidoValido(tipo, ref, clase)
    if tipo == 'youtube' then return clase == 'video' and esIdYoutube(ref) end
    if tipo == 'twitch' then
        if clase == 'directo' then return esCanalTwitch(ref) end
        if clase == 'vod' then return esVodTwitch(ref) end
    end
    return false
end
