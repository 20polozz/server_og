Config = {}

-- ========================================
-- CONFIGURACIÓN GENERAL
-- ========================================

Config.Debug = false

Config.TestMode = false

-- ========================================
-- MERCADOS NEGROS (multi-mercado)
-- ========================================

--[[ Aqui ya no se pone ningun mercado.

     Antes venian tres escritos a mano (Mercado Negro, Mercado de Armas y
     Mercado Racing), cada uno con sus dos NPC clavados en unas coordenadas.
     Ahora todos se montan desde el panel de admin («Nuevo mercado»): la zona, el que vende y el de la puerta se colocan
     andando hasta el sitio y pulsando [E], y se guardan en la tabla
     `blackmarket_markets`. Desde «Cómo funciona» se mueven o se borran.

     La tabla se rellena sola al arrancar con lo que haya en la base de datos
     (server/main.lua → LoadDynamicMarkets). ]]
Config.Markets = {}

-- ========================================
-- SISTEMA DE CAPTURA
-- ========================================

Config.Capture = {
    -- Duración de la ventana de captura (segundos)
    CaptureTime = 1800,  -- 30 minutos

    -- Tiempo de gracia en caso de empate (segundos)
    GracePeriod = 120,   -- 2 minutos

    -- Distancia para contar como "en la zona" (metros)
    CheckDistance = 100.0,

    -- Intervalo de broadcast de standings al cliente (ms)
    BroadcastInterval = 5000,

    -- Recompensa para cada miembro de la banda ganadora
    CaptureReward = {
        money = 0,
        black_money = 10000,
    },

    -- ── Sistema de presencia por tiempo ────────────────────────────────
    -- Si true, gana la banda con más puntos de presencia acumulados
    -- (tiempo × miembros vivos). Si false, usa el sistema original
    -- (más miembros en zona al final).
    WinByPresenceScore = true,

    -- Puntos acumulados por segundo por cada miembro vivo en la zona.
    -- Con 3 miembros vivos → +3 pts/s. Muerto/abatido → +0 pts/s.
    PresenceScorePerSecond = 1,
}

-- ========================================
-- SISTEMA DE ACTIVACIÓN AUTOMÁTICA
-- ========================================

Config.Activation = {
    -- Cada cuánto se inicia un ciclo de captura (minutos)
    Interval = 480,  -- 8 horas

    -- Avisos previos (minutos antes del inicio)
    NotifyBefore = { 60, 30, 15, 5, 1 },

    -- Auto-start al iniciar el servidor
    AutoStart = true,
}

-- ========================================
-- PRODUCTOS Y ECONOMÍA
-- ========================================

Config.Products = {
    -- Descuento para la banda propietaria
    OwnerDiscount = 20, -- 20% de descuento
    
    -- Máximo de productos que puede vender una banda
    MaxProducts = 10,
    
    -- Límites de precio
    MinPrice = 1,
    MaxPrice = 1000000,
    
    -- Límites de stock (MaxStock = 0 → sin límite)
    MinStock = 1,
    MaxStock = 0,
    
    -- Tipo de moneda aceptada
    AcceptedCurrency = {
        'money',
        'black_money',
        'ogn',
    },
    
    -- Items prohibidos (no se pueden vender en el mercado negro)
    BlacklistedItems = {
        'id_card',
        'driver_license',
        'weaponlicense',
        'lawyerpass',
        'policerecord',
        -- Añadir más items que no quieras en el mercado
    }
}

-- ========================================
-- QUÉ SE VENDE EN CADA MERCADO
-- ========================================
--[[ Cada mercado vende una sola cosa (02/10: uno de droga, uno de armas y uno
     de crews, cada uno en un sótano del mapeado de MXC). La categoría se elige
     en el panel («Cómo funciona» → «Qué se vende») y se guarda con el resto de
     ajustes del mercado; aquí solo se dice qué objetos entran en cada una.

     El inventario no tiene un campo de categoría, así que se reconoce por el
     NOMBRE del objeto (patrones de Lua, en minúsculas) o por su `type`. Si un
     objeto nuevo no entra donde debería, se añade su nombre a `nombres`.

     La regla la aplica el servidor cuando el producto lo pone la banda dueña.
     Un administrador puede poner cualquier objeto en cualquier mercado, y su
     buscador los enseña todos (09/10). ]]
Config.Categories = {
    Order = { 'todo', 'drogas', 'armas', 'vehiculos' },

    todo = { label = 'De todo' },

    drogas = {
        label = 'Droga',
        patrones = {
            'weed', 'cannabis', '^coke', 'coke$', '^coca_', 'cokebaggy', 'loosecoke',
            '^meth', '^opium', '^opio', 'heroin', '^lsd', '^joint', '^porro', '^crack',
            'mdma', 'extasis', '^drug', '^droga', 'amapola',
        },
        -- bolsa_envasar: la que gasta la mesa de origen_weed al empaquetar (08/10)
        nombres = { plant_tub = true, bolsa_envasar = true },
        --- Lo que casa con un patrón sin serlo: las algas no son hierba.
        excluye = { seaweed = true },
    },

    armas = {
        label = 'Armas',
        patrones = {
            '^weapon_', '_ammo$', '^ammo', '_attachment$', '^weapontint_', '^armor', '^chaleco',
            '^c4', 'explos', 'granad', 'grenade', 'thermite', 'termita',
        },
        tipos = { 'weapon', 'ammo', 'attachment', 'pistol', 'shotgun', 'rifle', 'smg', 'sniper', 'mg' },
        nombres = { vest = true, lockpick = true, masks = true, bomba_ruedas = true },
    },

    vehiculos = {
        label = 'Coches y carreras',
        patrones = {
            '^pieza_', 'repairkit', '^kit_reparacion', '^tirekit', '^oxido_nitroso', '^nitro',
            '^matricula_', '^tablet_racing', '^sabotaje_', '^herramienta_diagnostico',
            '^localizador_gps', '^servicio_aceite', '^servicio_liquido', '^servicio_neumaticos',
        },
        nombres = { bidon_gasolina = true, bomba_ruedas = true, laptop_hack = true },
    },
}

--- ¿Entra ese objeto en la categoría? `todo` (o una categoría que no existe) deja pasar todo.
---@param categoria string|nil
---@param nombre string
---@param tipo string|nil
---@return boolean
function Config.ItemEnCategoria(categoria, nombre, tipo)
    local def = categoria and Config.Categories[categoria]
    if not def or categoria == 'todo' or categoria == 'Order' then return true end
    if type(nombre) ~= 'string' then return false end

    local n = nombre:lower()
    if def.excluye and def.excluye[n] then return false end
    if def.nombres and def.nombres[n] then return true end

    for _, patron in ipairs(def.patrones or {}) do
        if n:find(patron) then return true end
    end

    local t = type(tipo) == 'string' and tipo:lower() or ''
    for _, trozo in ipairs(def.tipos or {}) do
        if t ~= '' and t:find(trozo, 1, true) then return true end
    end

    return false
end

--- La lista para el desplegable del panel: { { value, label }, ... }
function Config.ListaCategorias()
    local lista = {}
    for _, clave in ipairs(Config.Categories.Order) do
        lista[#lista + 1] = { value = clave, label = Config.Categories[clave].label }
    end
    return lista
end

-- ========================================
-- NOTIFICACIONES
-- ========================================

Config.Notifications = {
    -- Mensajes del sistema
    Messages = {
        -- Activación
        ActivationSoon = "El Mercado Negro estará disponible en %s minutos",
        ActivationNow = "El Mercado Negro está ACTIVO. Captura la zona para obtener beneficios exclusivos",
        MarketExpired = "El Mercado Negro ya no está disponible",

        -- Captura
        CaptureStarted = "Tu banda ha iniciado la captura del Mercado Negro (%s%%)",
        CaptureProgress = "Captura en progreso: %s%%",
        CaptureCompleted = "Tu banda ha capturado el Mercado Negro. Ahora tenéis acceso exclusivo",
        CaptureInterrupted = "La captura ha sido interrumpida por %s",
        LostControl = "Has perdido el control del Mercado Negro",
        NotEnoughMembers = "Se necesitan al menos %s miembros de tu banda en la zona",
        -- Con 1, en singular: quien lo use elige esta clave si el minimo es 1 (hoy no lo usa ningun script).
        NotEnoughMembers_one = "Se necesita al menos 1 miembro de tu banda en la zona",
        NotInGang = "Debes estar en una banda para capturar el Mercado Negro",
        AlreadyOwned = "Tu banda ya controla el Mercado Negro",
        ProtectionActive = "El Mercado Negro está protegido por %s minutos más",

        -- Productos
        ProductAdded = "Producto añadido al mercado: %s x%s por %s",
        ProductRemoved = "Producto eliminado del mercado",
        ProductUpdated = "Producto actualizado",
        ProductPurchased = "Has comprado %sx %s por %s",
        DiscountApplied = "Descuento del %s%% aplicado (Banda propietaria)",
        NotEnoughMoney = "No tienes suficiente dinero",
        NotEnoughStock = "No hay suficiente stock disponible",
        MaxProductsReached = "Has alcanzado el límite de productos (%s)",
        BlacklistedItem = "Este item no puede venderse en el Mercado Negro",
        InvalidPrice = "Precio inválido (Min: %s - Max: %s)",
        InvalidStock = "Stock inválido (Min: %s - Max: %s)",
        NotOwner = "Solo la banda propietaria puede gestionar productos",

        -- General
        MarketOpened = "Has abierto el Mercado Negro",
        MarketClosed = "Has cerrado el Mercado Negro",
    }
}

-- ========================================
-- PERMISOS
-- ========================================

Config.Permissions = {
    -- Quién puede añadir/eliminar productos (rangos de banda en QBX)
    CanManageProducts = function(gangGrade)
        -- En QBX, grade.level más alto = más poder
        -- 0 = Recluta, 1 = Miembro, 2 = Encargado, 3 = Jefe
        return gangGrade and gangGrade.level >= 3 -- Solo boss
    end,
    
    -- Quién puede comprar
    CanBuy = 'everyone', -- everyone, gang_members_only
}

-- ========================================
-- FUNCIONES DE INTEGRACIÓN
-- ========================================

-- Obtener el Core de QBX
local QBCore = nil
Config.GetQBCore = function()
    if not QBCore then
        QBCore = exports['qb-core']:GetCoreObject()
    end
    return QBCore
end

-- Obtener información de la banda del jugador
-- Usa origen_ilegalv2 como fuente principal (gang.name como identificador)
Config.GetPlayerGang = function(source)
    local src = tonumber(source)
    if not src or not DoesPlayerExist(src) then return nil end

    -- origen_ilegalv2 es la fuente oficial de bandas en este servidor
    if GetResourceState('origen_ilegalv2') == 'started' then
        -- Usamos GetPlayerGang que devuelve gang.name (el nombre string de la banda,
        -- el mismo que se almacena en owner_gang de blackmarket_control)
        local okName, gangName = pcall(function()
            return exports['origen_ilegalv2']:GetPlayerGang(src)
        end)
        if okName and gangName and gangName ~= '' and gangName ~= 'none' then
            -- Intentar obtener el label legible desde GetGangByName
            local label = tostring(gangName)
            local okGang, gangRow = pcall(function()
                return exports['origen_ilegalv2']:GetGangByName(tostring(gangName))
            end)
            if okGang and gangRow and gangRow.label then
                label = gangRow.label
            end
            return {
                name  = tostring(gangName),
                label = label,
            }
        end
        return nil
    end

    -- Fallback: qbx_core (por si origen_ilegalv2 no está disponible)
    local Player = exports.qbx_core:GetPlayer(src)
    if Player and Player.PlayerData.gang and Player.PlayerData.gang.name ~= 'none' then
        return {
            name  = Player.PlayerData.gang.name,
            label = Player.PlayerData.gang.label,
        }
    end

    return nil
end

-- Verificar si es admin
Config.IsAdmin = function(source)
    if GetResourceState('origen_admin') == 'started' then
        return exports['origen_admin']:HasPermission(source, 'origen_blackmarket') or exports['origen_admin']:HasPermission(source, 'AdminMenu')
    end
    local QBCore = Config.GetQBCore()
    return QBCore.Functions.HasPermission(source, 'admin') or QBCore.Functions.HasPermission(source, 'god')
end

-- Obtener identifier del jugador
Config.GetPlayerIdentifier = function(source)
    local QBCore = Config.GetQBCore()
    local Player = exports.qbx_core:GetPlayer(source)
    return Player and Player.PlayerData.citizenid or nil
end

-- Obtener nombre del jugador
Config.GetPlayerName = function(source)
    local QBCore = Config.GetQBCore()
    local Player = exports.qbx_core:GetPlayer(source)
    
    if Player and Player.PlayerData.charinfo then
        return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    end
    
    return GetPlayerName(source)
end

-- Mapeo de nombres de moneda a los tipos reales de qbx_core
-- (money → cash; black_money se trata como item de inventario, ver abajo)
local MoneyTypeMap = {
    ['money'] = 'cash',
}
local function NormalizeMoney(moneyType)
    return MoneyTypeMap[moneyType] or moneyType
end

-- Obtener dinero del jugador
-- black_money es un item del inventario en este servidor, no una moneda bancaria
Config.GetPlayerMoney = function(source, moneyType)
    if moneyType == 'black_money' then
        local item = Config.GetItem(source, 'black_money')
        return item and item.amount or 0
    end
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return 0 end
    local t = NormalizeMoney(moneyType)
    return (Player.PlayerData.money and Player.PlayerData.money[t]) or 0
end

-- Remover dinero del jugador
Config.RemoveMoney = function(source, moneyType, amount)
    if moneyType == 'black_money' then
        local item = Config.GetItem(source, 'black_money')
        if not item or item.amount < amount then return false end
        return Config.RemoveItem(source, 'black_money', amount)
    end
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return false end
    local t = NormalizeMoney(moneyType)
    local currentMoney = (Player.PlayerData.money and Player.PlayerData.money[t]) or 0
    if currentMoney < amount then return false end
    return Player.Functions.RemoveMoney(t, amount, 'blackmarket-purchase')
end

-- Añadir dinero al jugador
Config.AddMoney = function(source, moneyType, amount)
    if moneyType == 'black_money' then
        return Config.AddItem(source, 'black_money', amount)
    end
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return false end
    return Player.Functions.AddMoney(NormalizeMoney(moneyType), amount, 'blackmarket-sale')
end

-- Añadir item al jugador usando origen_inventory
Config.AddItem = function(source, itemName, amount, metadata)
    -- exports.origen_inventory:AddItem(source, itemName, amount, metadata, slot, ignoreWeight)
    return exports['origen_inventory']:AddItem(source, itemName, amount, metadata or {}, nil, false)
end

-- Remover item del jugador usando origen_inventory
Config.RemoveItem = function(source, itemName, amount)
    return exports['origen_inventory']:RemoveItem(source, itemName, amount, nil, nil)
end

-- Obtener item del jugador
Config.GetItem = function(source, itemName)
    return exports['origen_inventory']:getItem(source, itemName, false, false)
end

-- Notificar al jugador usando origen_notify
Config.Notify = function(source, message, type, duration)
    TriggerClientEvent('origen_notify:SendNotification', source, {
        description = message,
        type = type or 'info',
        duration = duration or 5000
    })
end

-- Notificar a toda la banda (todos los miembros online)
Config.NotifyGang = function(gangName, message, msgType, duration)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local pid = tonumber(playerId)
        local gang = Config.GetPlayerGang(pid)
        if gang and gang.name == gangName then
            Config.Notify(pid, message, msgType, duration)
        end
    end
end

-- Notificar a todos los jugadores que tienen banda
Config.NotifyAllGangs = function(message, msgType, duration)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local pid = tonumber(playerId)
        local gang = Config.GetPlayerGang(pid)
        if gang then
            Config.Notify(pid, message, msgType, duration)
        end
    end
end

-- ========================================
-- ACCESO EXTENDIDO (crews / locales)
-- ========================================

-- Obtener la crew del jugador usando el export de origen_racing
Config.GetPlayerCrew = function(source)
    if GetResourceState('origen_racing') ~= 'started' then return nil end
    local ok, crew = pcall(function()
        return exports['origen_racing']:GetPlayerCrew(source)
    end)
    if ok and crew and crew.id then
        return { name = crew.name or tostring(crew.id), label = crew.label or crew.name }
    end
    return nil
end

-- Obtener el negocio primario del jugador usando origen_businesses
Config.GetPlayerBusiness = function(source)
    if GetResourceState('origen_businesses') ~= 'started' then return nil end
    local ok, businesses = pcall(function()
        return exports['origen_businesses']:GetBusinessesOfSource(source)
    end)
    if ok and businesses then
        for id, biz in pairs(businesses) do
            return { name = tostring(id), label = biz.label or biz.name or tostring(id) }
        end
    end
    return nil
end

-- El cuerpo de policía del jugador (09/10). El «grupo» es su trabajo —LSPD,
-- sheriff…—, así que si el mercado se captura compiten los cuerpos entre sí;
-- si no se captura, entra cualquier agente.
Config.GetPlayerPolice = function(source)
    local src = tonumber(source)
    if not src or not DoesPlayerExist(src) then return nil end
    local ok, player = pcall(function() return Config.GetQBCore().Functions.GetPlayer(src) end)
    local job = ok and player and player.PlayerData and player.PlayerData.job
    if job and job.type == 'leo' then
        return { name = tostring(job.name), label = job.label or tostring(job.name) }
    end
    return nil
end

--[[ Para quién puede ser un mercado. La columna `access_type` de la base es un
     ENUM de antes ('bandas','crews','locales','publico') y no se toca: un tipo
     nuevo se guarda en el config_json y en la columna va `Config.AccessColumn`
     (ver LoadMarketState y saveMarketConfig en server/main.lua). ]]
Config.AccessTypes = { bandas = true, crews = true, locales = true, policia = true, publico = true }

local EN_LA_COLUMNA = { bandas = true, crews = true, locales = true, publico = true }

function Config.AccessColumn(accessType)
    return EN_LA_COLUMNA[accessType] and accessType or 'bandas'
end

-- Devuelve la identidad de grupo del jugador según el tipo de acceso del mercado.
-- Retorna { name, label } o nil si el jugador no pertenece al tipo requerido.
Config.GetAccessByType = function(source, accessType)
    if accessType == 'publico' then
        return { name = 'publico', label = 'Público' }
    elseif accessType == 'crews' then
        return Config.GetPlayerCrew(source)
    elseif accessType == 'locales' then
        return Config.GetPlayerBusiness(source)
    elseif accessType == 'policia' then
        return Config.GetPlayerPolice(source)
    else -- 'bandas' es el default
        return Config.GetPlayerGang(source)
    end
end

-- Notificar a todos según el tipo de acceso de un mercado
Config.NotifyByAccessType = function(accessType, message, msgType, duration)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local pid    = tonumber(playerId)
        local access = Config.GetAccessByType(pid, accessType)
        if access then
            Config.Notify(pid, message, msgType, duration)
        end
    end
end

-- Notificar solo al grupo propietario (por nombre de grupo)
Config.NotifyGroup = function(accessType, groupName, message, msgType, duration)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local pid    = tonumber(playerId)
        local access = Config.GetAccessByType(pid, accessType)
        if access and access.name == groupName then
            Config.Notify(pid, message, msgType, duration)
        end
    end
end

-- ========================================
-- FUNCIÓN DE DEBUG
-- ========================================

Config.DebugPrint = function(...)
    if Config.Debug then
        print('^3[BlackMarket]^7', ...)
    end
end
