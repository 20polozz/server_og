--[[ Textos traducidos.

     Un mismo servidor puede tener a la vez a alguien con el telefono en
     español y a alguien con el telefono en ingles, asi que el idioma no es del
     servidor: es de cada telefono. Todo lo que se escribe aqui recibe a quien
     va dirigido, y responde en su idioma.

     Los ficheros estan en locales/<codigo>.json y son planos: clave, texto.
     Los huecos se marcan con %s y se rellenan por orden.

         Locale.Text('es', 'call_offline')
         Locale.Text('en', 'gave_phone_to', 'Marco')

     En el servidor casi siempre se usa el atajo Locale.Get(source, clave, ...),
     que ya mira que idioma tiene puesto ese jugador en su telefono.
]]

Locale = {}

--[[ Idioma al que se cae cuando falta algo.

     Se separa del idioma por defecto de la config a proposito: si un servidor
     pone Config.DefaultLanguage = 'pl' y a la traduccion polaca le faltan diez
     claves, lo que tiene que salir es el ingles, no la clave cruda. El ingles
     es el fichero que se mantiene siempre completo. ]]
local RESPALDO = 'en'

local cache = {}

--- Lee un fichero de idioma. Solo la primera vez; despues sale de memoria.
---@param language string
---@return table
--- Si ese idioma es uno de los del servidor (Config.Languages).
---@param language any
---@return boolean
function Locale.Existe(language)
    if type(language) ~= 'string' then return false end
    for _, l in ipairs(Config.Languages or {}) do
        if l == language then return true end
    end
    return false
end

function Locale.Table(language)
    --- Solo idiomas conocidos: el nombre acaba en una ruta de fichero.
    if not Locale.Existe(language) then language = RESPALDO end
    if cache[language] then return cache[language] end

    local raw = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.json'):format(language))
    if not raw then
        -- Se avisa una vez y se guarda la tabla vacia, para no volver a
        -- intentar leer un fichero que no existe en cada mensaje.
        print(('^3[origen_phone] Falta locales/%s.json^7'):format(language))
        cache[language] = {}
        return cache[language]
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        print(('^1[origen_phone] locales/%s.json no es un JSON valido^7'):format(language))
        cache[language] = {}
        return cache[language]
    end

    cache[language] = decoded
    return decoded
end

--- Vuelve a leer los ficheros. Para tocar traducciones sin reiniciar.
function Locale.Reload()
    cache = {}
end

--- Un texto en un idioma concreto, con los huecos rellenos.
---@param language string|nil
---@param key string
---@param ... any
---@return string
function Locale.Text(language, key, ...)
    if not key then return '' end

    local text = Locale.Table(language)[key]

    -- Sin traducir en ese idioma: se prueba el respaldo antes de rendirse.
    if not text and language ~= RESPALDO then
        text = Locale.Table(RESPALDO)[key]
    end

    -- Ni en el respaldo. Sale la clave, que es feo pero se ve y se arregla;
    -- una cadena vacia dejaria el hueco en blanco sin que nadie se entere.
    if not text then return key end

    local args = { ... }
    if #args == 0 then return text end

    local i = 0
    return (text:gsub('%%s', function()
        i = i + 1
        local v = args[i]
        return v ~= nil and tostring(v) or ''
    end))
end

--- Lista de idiomas que traen fichero, leyendo la carpeta.
--- No se puede listar un directorio desde Lua, asi que se comprueba uno a uno
--- contra la lista de idiomas conocidos.
---@return string[]
--[[ Como escribe las fechas un idioma.

     El telefono lo pasa tal cual a Intl, que es quien sabe si el mes va antes
     o despues del dia. Un idioma sin entrada en la tabla se cae al de la
     configuracion antes que al ingles: quien añade un idioma nuevo casi
     siempre quiere las fechas de su pais, no las de Londres. ]]
---@param language string
---@return string
function Locale.DateFor(language)
    local tabla = Config.DateLocales or {}
    return tabla[language] or Config.DateLocale or 'en-GB'
end

function Locale.Available()
    local found = {}
    for i = 1, #Config.Languages do
        local code = Config.Languages[i]
        if LoadResourceFile(GetCurrentResourceName(), ('locales/%s.json'):format(code)) then
            found[#found + 1] = code
        end
    end
    return found
end

if IsDuplicityVersion() then
    -- -----------------------------------------------------------------------
    --  Servidor: el idioma sale del telefono de cada uno
    -- -----------------------------------------------------------------------

    --- Idioma que tiene puesto el telefono abierto de ese jugador.
    ---@param source number|nil
    ---@return string
    function Locale.For(source)
        if not source then return Config.DefaultLanguage end

        local active = ActivePhones and ActivePhones[source]
        return (active and active.language) or Config.DefaultLanguage
    end

    --- Atajo: el texto en el idioma de quien lo va a leer.
    ---@param source number|nil
    ---@param key string
    ---@param ... any
    ---@return string
    function Locale.Get(source, key, ...)
        return Locale.Text(Locale.For(source), key, ...)
    end

    --[[ Y en el idioma del telefono de un numero.

         Hace falta para todo lo que se le escribe a alguien que no esta
         pidiendo nada: un aviso de llamada perdida, un mensaje de voz, una
         factura. Ahi no hay ningun jugador a mano, hay un numero.

         Sin esto, todos esos avisos salian en el idioma del servidor, asi que
         alguien que tuviera el telefono en ingles recibia las notificaciones en
         castellano. Si ese telefono no esta abierto se usa el del servidor: no
         hay a quien preguntarle, y cuando lo abra vera lo que se le guardo. ]]
    ---@param number string|nil
    ---@param key string
    ---@param ... any
    ---@return string
    function Locale.ByNumber(number, key, ...)
        if not number then return Locale.Text(Config.DefaultLanguage, key, ...) end

        for _, active in pairs(ActivePhones or {}) do
            if active.number == number then
                return Locale.Text(active.language or Config.DefaultLanguage, key, ...)
            end
        end

        return Locale.Text(Config.DefaultLanguage, key, ...)
    end
else
    -- -----------------------------------------------------------------------
    --  Cliente: hay un solo telefono, el de quien juega
    -- -----------------------------------------------------------------------

    local mine = nil

    --- Guarda el idioma del telefono propio. Lo llama el arranque.
    ---@param language string|nil
    function Locale.SetMine(language)
        mine = language
    end

    --- El texto en el idioma del telefono propio.
    ---@param key string
    ---@param ... any
    ---@return string
    function Locale.Say(key, ...)
        return Locale.Text(mine or Config.DefaultLanguage, key, ...)
    end

    --[[ La tabla entera, en el idioma del telefono propio.

         La necesita lo que se abre SIN telefono (la tienda de telefonos): la
         interfaz solo tiene los textos si alguna vez se encendio uno, y quien
         va a la tienda suele ser justo quien se ha quedado sin el. ]]
    ---@return table
    function Locale.MiTabla()
        return Locale.Table(mine or Config.DefaultLanguage)
    end
end
