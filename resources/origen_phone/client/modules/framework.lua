--[[ Puente del cliente con el resto del servidor: avisos e inventario.

     El cliente necesita mucho menos que el servidor. Solo dos cosas:

       - poder sacar un aviso corto en pantalla, fuera del telefono
       - saber que telefonos lleva encima el jugador, para pintar la interfaz

     Lo segundo es solo para la interfaz. La comprobacion que manda —la que
     decide si se puede llamar, escribir o abrir algo— la hace siempre el
     servidor contra su propio inventario, nunca lo que diga esto de aqui.
]]

Framework = {}

-- ---------------------------------------------------------------------------
--  Avisos
-- ---------------------------------------------------------------------------

--- Aviso corto en pantalla (el del servidor, no el del telefono).
---@param message string
---@param kind string|nil  'info' | 'success' | 'error'
function Framework.Notify(message, kind)
    if not message then return end

    -- El recurso de avisos propio del servidor, si lo hay.
    local propio = Config.Notify
    if propio and propio ~= 'framework' and GetResourceState(propio) == 'started' then
        local ok = pcall(function()
            exports[propio]:Notify({
                title = Locale.Say('phone_title'),
                description = message,
                type = kind or 'info',
            })
        end)
        if ok then return end
    end

    -- ox_lib lo tiene todo el mundo: es dependencia del recurso.
    lib.notify({
        description = message,
        type = kind == 'error' and 'error' or (kind == 'success' and 'success' or 'inform'),
    })
end

-- ---------------------------------------------------------------------------
--  Inventario
-- ---------------------------------------------------------------------------

--[[ Igual que en el servidor, cada inventario tiene su forma de contar lo que
     lleva el jugador. Aqui solo hace falta leer, asi que cada adaptador es una
     sola funcion que devuelve una lista de { metadata }. ]]

local CANDIDATOS = { 'origen_inventory', 'ox_inventory', 'qb-inventory', 'qs-inventory' }

local detected = nil

--- Nombre del inventario en uso, o nil.
---@return string|nil
local function InventoryName()
    local forced = Config.Item.Inventory
    if forced and forced ~= 'auto' then
        return GetResourceState(forced) == 'started' and forced or nil
    end

    if detected and GetResourceState(detected) == 'started' then return detected end
    detected = nil

    for i = 1, #CANDIDATOS do
        if GetResourceState(CANDIDATOS[i]) == 'started' then
            detected = CANDIDATOS[i]
            return detected
        end
    end

    return nil
end

local LECTORES = {}

LECTORES.origen_inventory = function()
    return exports.origen_inventory:getInventory()
end

--[[ ox_inventory da el inventario del cliente por su state bag, que es lo
     unico que hay disponible sin preguntar al servidor. ]]
LECTORES.ox_inventory = function()
    return exports.ox_inventory:GetPlayerItems()
end

LECTORES['qb-inventory'] = function()
    -- En QBCore el inventario del cliente vive en los datos del jugador.
    local core = GetResourceState('qb-core') == 'started' and exports['qb-core']:GetCoreObject() or nil
    if not core then return nil end

    local data = core.Functions.GetPlayerData()
    return data and data.items or nil
end

LECTORES['qs-inventory'] = function()
    return exports['qs-inventory']:getUserInventory()
end

--- Todos los items de telefono que lleva encima el jugador.
---@return table[]  { metadata }
function Framework.GetPhoneItems()
    local name = InventoryName()
    if not name then return {} end

    local ok, items = pcall(LECTORES[name])
    if not ok or not items then return {} end

    local found = {}
    for _, item in pairs(items) do
        if item and item.name == Config.Item.Name then
            -- Cada inventario llama de una forma a lo mismo.
            found[#found + 1] = { metadata = item.metadata or item.info or {} }
        end
    end
    return found
end

--- true si el jugador lleva encima el telefono de ese numero.
--- Es solo para la interfaz: la comprobacion que manda la hace el servidor.
---@param number string
---@return boolean
function Framework.HasPhoneItem(number)
    if not Config.Item.Require then return true end

    local items = Framework.GetPhoneItems()
    for i = 1, #items do
        local meta = items[i].metadata
        if meta and meta[Config.Item.MetaNumber] == number then
            return true
        end
    end
    return false
end

--[[ Si lleva ALGUN telefono encima, tenga numero o no.

     No es lo mismo que HasPhoneItem: aquel pregunta por una linea concreta, y
     este solo por el aparato. La diferencia importa con un movil recien
     comprado, que todavia no tiene numero en su metadata —se lo pone el
     servidor al encenderlo la primera vez— y aun asi hay que dejar abrirlo.

     DEVUELVE nil CUANDO NO SE SABE, y eso no es un descuido: si no hay ningun
     inventario detectado, aqui no se puede mirar nada, y contestar "no llevas"
     dejaria el telefono cerrado para todo el mundo. En la duda contesta nil y
     que decida el servidor, que es quien lo sabe de verdad.
---@return boolean|nil ]]
function Framework.CarryingPhone()
    if not Config.Item.Require then return true end
    if not InventoryName() then return nil end

    return #Framework.GetPhoneItems() > 0
end

--- Numero del primer telefono que lleve encima, si tiene alguno con numero.
---@return string|nil
function Framework.GetFirstNumber()
    local items = Framework.GetPhoneItems()
    for i = 1, #items do
        local meta = items[i].metadata
        if meta and meta[Config.Item.MetaNumber] then
            return meta[Config.Item.MetaNumber]
        end
    end
    return nil
end

RegisterNetEvent('origen_phone:cl:notify', function(message, kind)
    Framework.Notify(message, kind)
end)

--[[ El inventario muestra la metadata con etiquetas legibles en vez de las
     claves crudas. Se hace con un poco de retraso para que el inventario ya
     este en marcha cuando se le pide, y solo lo tiene origen_inventory: los
     demas no ofrecen nada parecido, asi que ahi se ven las claves tal cual. ]]
CreateThread(function()
    Wait(2000)
    if InventoryName() ~= 'origen_inventory' then return end

    pcall(function()
        exports.origen_inventory:displayMetadata({
            [Config.Item.MetaNumber] = '',   -- el crudo se oculta: ya sale el formateado
            [Config.Item.MetaFormatted] = Locale.Say('item_meta_number'),
            [Config.Item.MetaName] = Locale.Say('item_meta_owner'),
        })
    end)
end)
