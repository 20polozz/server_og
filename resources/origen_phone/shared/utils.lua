--[[ Utilidades compartidas entre cliente y servidor. ]]

Utils = {}

--- Deja un numero de telefono en solo digitos.
---@param number string|number|nil
---@return string|nil
function Utils.CleanNumber(number)
    if not number then return nil end
    local clean = tostring(number):gsub('%D', '')
    return clean ~= '' and clean or nil
end

--- Aplica Config.PhoneNumber.Format a un numero crudo.
--- El formato lleva los grupos entre llaves: "{2}-{4}" parte 551234 en "55-1234".
--- Si el numero no mide lo que dice el formato, se devuelve tal cual: es mejor
--- ver un numero raro que uno cortado.
---@param number string|number|nil
---@return string
function Utils.FormatNumber(number)
    local clean = Utils.CleanNumber(number)
    if not clean then return '' end

    local format = Config.PhoneNumber.Format
    if not format or format == '' then return clean end

    local total = 0
    for size in format:gmatch('{(%d+)}') do
        total = total + tonumber(size)
    end
    if total ~= #clean then return clean end

    local cursor = 1
    local result = format:gsub('{(%d+)}', function(size)
        size = tonumber(size)
        local chunk = clean:sub(cursor, cursor + size - 1)
        cursor = cursor + size
        return chunk
    end)

    return result
end

--- Recorta una cadena a un maximo de caracteres, sin romper si viene nil.
---@param text any
---@param max number
---@return string
--[[ Tapa las palabras que el servidor no quiere leer.

     Se busca sin acentos y sin mayusculas, y dentro de la palabra: poner
     "tonto" tapa tambien "tontaco". Es tosco a proposito —un filtro fino se
     esquiva igual y ademas tapa cosas que no queria— y lo que hace falta aqui
     es que lo evidente no pase.

     Lo que se tapa se tapa; el mensaje sale igual. Rechazarlo le diria a quien
     lo escribio que palabra ha saltado, y a partir de ahi es cuestion de probar
     hasta encontrar la que cuela. ]]
---@param texto string|nil
---@return string|nil
function Utils.Filtrar(texto)
    if type(texto) ~= 'string' or texto == '' then return texto end
    if not Config.Filter or Config.Filter.Enabled ~= true then return texto end

    local palabras = Config.Filter.Words or {}
    if #palabras == 0 then return texto end

    local mascara = Config.Filter.Mask or '***'
    local llano = Utils.SinAcentos(texto:lower())
    local salida = texto

    for i = 1, #palabras do
        local mala = Utils.SinAcentos(tostring(palabras[i]):lower())

        if mala ~= '' then
            --[[ Se busca en el texto llano y se corta en el original, para no
                 devolver el mensaje sin acentos y en minusculas. ]]
            local desde = 1

            while true do
                local ini, fin = llano:find(mala, desde, true)
                if not ini then break end

                salida = salida:sub(1, ini - 1) .. mascara .. salida:sub(fin + 1)

                --[[ El texto llano y el original dejan de medir lo mismo en
                     cuanto se sustituye una vez, asi que se recalculan los dos
                     y se sigue desde donde acaba la mascara. ]]
                llano = Utils.SinAcentos(salida:lower())
                desde = ini + #mascara
            end
        end
    end

    return salida
end

--- El mismo texto sin acentos, para poder comparar sin sorpresas.
---@param texto string
---@return string
function Utils.SinAcentos(texto)
    local mapa = {
        ['á'] = 'a', ['é'] = 'e', ['í'] = 'i', ['ó'] = 'o', ['ú'] = 'u', ['ü'] = 'u',
        ['à'] = 'a', ['è'] = 'e', ['ì'] = 'i', ['ò'] = 'o', ['ù'] = 'u',
        ['â'] = 'a', ['ê'] = 'e', ['î'] = 'i', ['ô'] = 'o', ['û'] = 'u',
        ['ä'] = 'a', ['ë'] = 'e', ['ï'] = 'i', ['ö'] = 'o', ['ñ'] = 'n', ['ç'] = 'c',
    }

    return (texto:gsub('[\194-\244][\128-\191]*', function(c) return mapa[c] or c end))
end

--[[ Si un nombre suplanta a alguien.

     Vale para nombres de usuario, alias y nombres de perfil. No es una
     palabrota: alguien que se llame "Admin" o "LSPD" esta engañando a los
     demas, y eso no se tapa con asteriscos, se rechaza.

     Se mira dentro del nombre, asi que "xX_Admin_Xx" tampoco cuela. ]]
---@param nombre string|nil
---@return boolean
function Utils.NombreLibre(nombre)
    if type(nombre) ~= 'string' or nombre == '' then return true end
    if not Config.Filter or Config.Filter.Enabled ~= true then return true end

    local llano = Utils.SinAcentos(nombre:lower()):gsub('[^%a]', '')

    for _, reservado in ipairs(Config.Filter.ReservedNames or {}) do
        if llano:find(reservado, 1, true) then return false end
    end

    return true
end

function Utils.Trim(text, max)
    if type(text) ~= 'string' then return '' end
    text = text:gsub('^%s+', ''):gsub('%s+$', '')
    if max and #text > max then
        text = text:sub(1, max)
    end

    --[[ Y de paso, las palabras que el servidor no quiere leer.

         Va aqui y no en cuarenta sitios porque por aqui pasa TODO lo que
         escribe un jugador: un mensaje, un anuncio, una nota, el nombre de una
         sala. Poniendolo en cada uno, el que se olvide es por donde entra.

         Con la lista vacia —que es como viene— esto no hace nada. ]]
    return Utils.Filtrar(text)
end

--- Genera un identificador unico razonable para telefonos, ficheros, etc.
---@param prefix string|nil
---@return string
function Utils.Uuid(prefix)
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    local uuid = template:gsub('[xy]', function(c)
        local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
        return string.format('%x', v)
    end)
    return (prefix and (prefix .. '_') or '') .. uuid
end

--- true si la tabla no tiene ni una clave.
---@param t table|nil
---@return boolean
function Utils.IsEmpty(t)
    if type(t) ~= 'table' then return true end
    return next(t) == nil
end

--- Convierte una lista en un conjunto {valor = true} para consultas rapidas.
---@param list table
---@return table
function Utils.ToSet(list)
    local set = {}
    for i = 1, #list do set[list[i]] = true end
    return set
end

--- Numero de elementos de una tabla asociativa.
---@param t table|nil
---@return number
function Utils.Count(t)
    if type(t) ~= 'table' then return 0 end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

--- Comprueba que una url apunte a algo que podamos pintar. No valida que
--- exista: solo que sea http(s) y no un javascript: disfrazado.
---@param url any
---@return boolean
function Utils.IsSafeUrl(url)
    if type(url) ~= 'string' then return false end
    if #url > 500 then return false end
    return url:match('^https?://[%w%-%._~:/%?#%[%]@!%$&\'%(%)%*%+,;=%%]+$') ~= nil
end

--[[ Lee una bandera que viene de la base de datos.

     oxmysql convierte los TINYINT(1) a booleano de JavaScript, asi que en Lua
     un `is_favorite` llega como `true`, no como `1`. Comparar con `== 1` da
     siempre falso, y ese fallo es silencioso: no revienta nada, simplemente
     ningun favorito es favorito y ningun grupo es grupo.

     Esta funcion acepta las tres formas (booleano, numero y texto) para que dé
     igual por donde venga el dato. ]]
---@param value any
---@return boolean
function Utils.Bool(value)
    if type(value) == 'boolean' then return value end
    if type(value) == 'number' then return value ~= 0 end
    if type(value) == 'string' then return value == '1' or value == 'true' end
    return false
end

--[[ Aviso por consola de algo que ha ido mal pero no ha tumbado nada.

     Se usa sobre todo con los recursos de fuera: si el inventario del servidor
     lleva una version distinta a la esperada, el telefono sigue funcionando
     pero quien lo instala tiene que enterarse de por que no se guarda el
     numero en el item. ]]
---@param message string
function Utils.Warn(message)
    print(('^3[origen_phone] %s^7'):format(message))
end
