Config = {}

-- ========================================
-- CONFIGURACIÓN GENERAL
-- ========================================

Config.Debug = false

-- Sistema de notificaciones
Config.Notify = function(source, message, type)
    if GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Racing',
            description = message,
            type = type or 'info',
            duration = 5000
        })
    end
end

-- ========================================
-- PERMISOS ADMIN
-- ========================================

Config.IsAdmin = function(source)
    -- Verificar ACE permissions (consola del servidor)
    if IsPlayerAceAllowed(source, 'racing.admin') then
        return true
    end

    -- Usar sistema de origen_admin (PREFERIDO)
    if GetResourceState('origen_admin') == 'started' then
        local hasOrigenAdmin = pcall(function()
            return exports['origen_admin']:CheckAdmin(source)
        end)

        if hasOrigenAdmin then
            local isAdmin = exports['origen_admin']:CheckAdmin(source)
            if isAdmin then
                return true
            end
        end
    end

    -- Fallback: verificar framework directamente
    --[[ Con qbx se pregunta a qbx_core directamente.

         Antes se pedia exports['qb-core']:GetCoreObject(), que con qbx (que
         hace `provide 'qb-core'`) devuelve el objeto de compatibilidad ENTERO
         —Shared con todos los items, vehiculos, trabajos y bandas, y cientos
         de funciones— serializado de un recurso a otro. Para cualquier
         jugador que no fuera admin por ACE ni por origen_admin se llegaba
         aqui: en el perfil del 16/09 (~300 jugadores) fueron 59 ms en una sola
         llamada a racing:territories:getAll.

         Las comprobaciones son las mismas: en el puente de qbx,
         QBCore.Functions.GetPlayer es qbx_core:GetPlayer y
         QBCore.Functions.HasPermission es qbx_core:HasPermission. Con un
         qb-core de verdad se sigue por el camino de antes. ]]
    if GetResourceState('qbx_core') == 'started' then
        local ok, esAdmin = pcall(function()
            local Player = exports.qbx_core:GetPlayer(source)
            if not Player then return false end
            -- Verificar job admin
            if Player.PlayerData and Player.PlayerData.job and Player.PlayerData.job.name == 'admin' then
                return true
            end
            -- Verificar permisos de framework
            return exports.qbx_core:HasPermission(source, 'admin') == true
                or exports.qbx_core:HasPermission(source, 'god') == true
        end)
        if ok and esAdmin then
            return true
        end
    elseif GetResourceState('qb-core') == 'started' then
        local success, QBCore = pcall(function()
            return exports['qb-core']:GetCoreObject() or exports['qbx_core']:GetCoreObject()
        end)

        if success and QBCore then
            local Player = QBCore.Functions.GetPlayer(source)
            if Player then
                -- Verificar job admin
                if Player.PlayerData.job and Player.PlayerData.job.name == 'admin' then
                    return true
                end
                -- Verificar permisos de framework
                local hasPerms = QBCore.Functions.HasPermission(source, 'admin') or
                                QBCore.Functions.HasPermission(source, 'god')
                if hasPerms then
                    return true
                end
            end
        end
    elseif GetResourceState('es_extended') == 'started' then
        local success, ESX = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)

        if success and ESX then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                local group = xPlayer.getGroup()
                return group == 'admin' or group == 'superadmin'
            end
        end
    end

    return false
end

-- Obtener playerId desde identifier
Config.GetPlayerFromIdentifier = function(identifier)
    -- Con qbx el identificador es el citizenid (Config.GetPlayerIdentifier):
    -- se pregunta directamente en vez de pedir GetPlayer a cada conectado.
    if GetResourceState('qbx_core') == 'started' then
        if type(identifier) ~= 'string' then return nil end
        local player = exports.qbx_core:GetPlayerByCitizenId(identifier)
        return player and player.PlayerData and tonumber(player.PlayerData.source) or nil
    end

    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerIdentifier = Config.GetPlayerIdentifier(tonumber(playerId))
        if playerIdentifier == identifier then
            return tonumber(playerId)
        end
    end
    return nil
end

-- ========================================
-- CONFIGURACIÓN DE CIRCUITOS
-- ========================================

Config.Circuits = {
    MinCheckpoints = 3, -- Mínimo de checkpoints
    MaxCheckpoints = 9999, -- Sin límite práctico (ilimitado)
    CheckpointRadius = 15.0, -- Radio del checkpoint (metros)
    MaxLaps = 10, -- Máximo de vueltas
}

--[[ El HUD de carrera (ui-vue/src/components/RacingHUDMinimal.vue).
     07/10: el 1, 2, 7 y 9 se ven igual, en pegatina: los datos en la barra
     de abajo y la clasificacion en una tarjeta a la derecha con su riel.
       0  paneles    el de cajas de siempre
       1  esquinas   sin cajas: posicion arriba a la izquierda, clasificacion a la derecha
       2  barra      sin cajas: una fila abajo en el centro
       3  torre      sin cajas: una columna a la izquierda, como la torre de la tele
       4  chapa      como el 1, con la posicion en una chapa rosa sesgada
       5  linea      todo en un renglon arriba a la izquierda; lo minimo
       6  rincon     abajo a la derecha, con el crono en grande
     Con fondo, discreto:
       7  cristal    el 1 sobre dos placas oscuras translucidas
       8  pildoras   el 5 con cada dato en su pastilla oscura
       9  papel      el 1 sobre el papel crema ]]
Config.HudCarrera = 1

--[[ La cuenta atras de la salida, en el centro de la pantalla
     (ui-vue/src/components/racing/CountdownOverlay.vue). Sin cajas, como el
     HUD: letra blanca con su cerco y una raya rosa.
       1  fino    la cifra, tres trazos que se llenan, la raya y el rotulo
       2  marco   la cifra entre cuatro esquinas finas, como un visor
       3  linea   una raya rosa de lado a lado con la cifra apoyada encima ]]
Config.SalidaEstilo = 1

--[[ La parrilla de salida (client/racing.lua, ColocarEnParrilla).

     Al empezar la cuenta atras cada coche va a su cajon, en dos columnas
     escalonadas detras del primer checkpoint y mirando como el. El orden es
     el de inscripcion. Medidas en metros.

     APAGADA: cada piloto sale desde donde este al empezar la cuenta atras
     (solo se congela hasta el «¡YA!»). Poner true para volver a la parrilla. ]]
Config.Parrilla = {
    Enabled     = false,
    PrimeraFila = 6.0,   -- del primer checkpoint a la primera fila
    EntreFilas  = 9.0,   -- de una fila a la siguiente
    Separacion  = 2.4,   -- del centro de la calzada a cada columna
}

--[[ El drift (client/racing.lua, DriftLoop). En una carrera de tipo «drift»
     gana quien mas puntos hace, no quien llega antes. ]]
Config.Drift = {
    AnguloMinimo     = 12.0,   -- grados de lado a partir de los que cuenta
    VelocidadMinima  = 30.0,   -- km/h; mas despacio no puntua
    PuntosPorSegundo = 60.0,   -- a 45 grados y 54 km/h, con multiplicador x1
    Gracia           = 1500,   -- ms sin derrapar antes de cerrar el derrape
}

--[[ El tope de 60 FPS en carrera: con mas, sale el aviso y a los segundos el
     jugador queda fuera (StartFpsMonitorThread, en client/racing.lua). A mas
     FPS los coches corren mas, y sin tope no compiten en igualdad.

     Se apago el 01/10/2026 para probar las carreras con tranquilidad; vuelve
     a estar ENCENDIDO desde el 07/10/2026. ]]
Config.LimiteFps = {
    Enabled = true,
    -- A partir de cuantos FPS salta el aviso. Al jugador se le dice 60 (es a
    -- lo que tiene que limitar), pero el contador baila un par de fotogramas
    -- arriba y abajo aunque el limite este bien puesto: con 65 hay margen y
    -- no se echa a nadie por un pico. Antes era 63, fijo en el cliente.
    Umbral = 65,
}

--[[ Volver al ultimo checkpoint en carrera (client/racing.lua,
     VolverAlCheckpoint): el coche de la carrera vuelve al ultimo punto que
     has pasado, en el suelo, mirando hacia el siguiente y arreglado si
     estaba destrozado. Con un fundido corto.

     La tecla se MANTIENE pulsada (Mantener, en ms) y cada jugador la puede
     cambiar en Ajustes > Teclas > FiveM. No una numerica: esas son del
     inventario. Muerto no se vuelve: eso es del sistema medico. ]]
Config.VolverCheckpoint = {
    Enabled      = true,
    Tecla        = 'R',
    Mantener     = 1000,         -- ms con la tecla pulsada
    Comando      = 'volvercp',   -- lo mismo escribiendolo, sin mantener
    Enfriamiento = 10,           -- segundos entre una vuelta y la siguiente
    Fundido      = 400,          -- ms del fundido a negro
    -- Si mueres o el coche revienta, abandonar la carrera solo (DNF). Apagado:
    -- se avisa y la carrera espera a que vuelvas al volante.
    DnfAlMorir   = false,
}

-- Delimitadores en checkpoints (Props a los lados para marcar el camino y evitar recortes)

Config.CheckpointDelimiters = {
    Enabled = true,
    OffsetDistance = 0.5,      -- Distancia adicional al radio del checkpoint para colocar el prop (radio + offset)

    --[[ Lo que se puede poner a los lados de un checkpoint. Se elige punto por
         punto al grabar el circuito (flechas izquierda / derecha) y se guarda
         con el. EL PRIMERO es el de serie: el que llevan los puntos grabados
         sin elegir nada.

           pack     props propios (Config.PropsCarrera), uno a cada lado: del
                    color de la marca y en verde cuando el corredor ya ha
                    pasado el checkpoint.
           ptfx     ademas, una particula a cada lado (dict, name, scale,
                    alto: metros sobre el suelo, color: { r, g, b } de 0 a 1 o
                    'marca' = rosa en Origen y naranja en Nacion).
           salidas  (en ptfx) de donde sale, respecto al prop y girando con el:
                    una columna por salida (los tres bidones, tres columnas).
                    Sin salidas, una en el sitio del prop a `alto` del suelo.
           separar  metros de mas (o de menos) desde el borde: la carpa se
                    aparta para no meterse en la carretera, el piano se arrima.
           14/10: ya no hay «Sin nada»: todo punto lleva props.

         14/10: fuera los props del juego (focos, conos, vallas de obra...),
         solo los nuestros. El `id` es lo que se guarda en la base: los de antes
         siguen valiendo por Alias, que los pasa a su equivalente. ]]
    --[[ Forzar = { normal = 'ogn_luminoso', salida = 'ogn_cuadros' } pinta en
         carrera todos los puntos así sin mirar lo grabado. false = cada punto
         con el estilo que se le eligió al grabar (lo normal). El 15/10 los
         circuitos que había se pasaron en la base a pancarta luminosa con
         cuadros en la salida (copia de antes: docs/racing-checkpoints-deco-antes.sql). ]]
    Forzar = false,

    Estilos = {
        { id = 'ogn_bandera',    label = 'Bandera',              pack = 'bandera' },
        { id = 'ogn_vela',       label = 'Bandera vela',         pack = 'vela' },
        { id = 'ogn_cuadros',    label = 'Bandera a cuadros',    pack = 'cuadros' },
        { id = 'ogn_torre',      label = 'Torre LED',            pack = 'torre' },
        { id = 'ogn_luminoso',   label = 'Pancarta luminosa',    pack = 'luminoso' },
        { id = 'ogn_hinchable',  label = 'Columna hinchable',    pack = 'hinchable' },
        { id = 'ogn_carpa',      label = 'Carpa',                pack = 'carpa', separar = 1.8 },
        { id = 'ogn_valla',      label = 'Valla con lona',       pack = 'valla' },
        { id = 'ogn_barrera',    label = 'Barrera de hormigón',  pack = 'barrera' },
        { id = 'ogn_tecpro',     label = 'Barrera Tecpro',       pack = 'tecpro' },
        -- Los redondos echan humo por arriba, del color de la marca: una columna
        -- de nubes que nace dentro y se abre poco al subir, una por cada `salida` (respecto al prop).
        -- Ajustado con fotos en el juego el 14/10: la bola de scr_as_trans tapaba el prop entero.
        { id = 'ogn_neumaticos', label = 'Neumáticos con funda', pack = 'neumaticos',
          ptfx = { dict = 'scr_ar_planes', name = 'scr_ar_trail_smoke', scale = 0.07, color = 'marca',
                   columna = { pisos = 8, paso = 0.36, crece = 0.18 },
                   salidas = { vec3(0.0, 0.0, 0.75) } } },              -- del hueco de la pila
        { id = 'ogn_paja',       label = 'Balas de paja',        pack = 'paja' },
        { id = 'ogn_bidones',    label = 'Bidones',              pack = 'bidones',
          ptfx = { dict = 'scr_ar_planes', name = 'scr_ar_trail_smoke', scale = 0.05, color = 'marca',
                   columna = { pisos = 7, paso = 0.38, crece = 0.18 },
                   salidas = { vec3(-0.31, -0.18, 0.82), vec3(0.31, -0.18, 0.82), vec3(0.0, 0.36, 0.82) } } },  -- una por bidón
        { id = 'ogn_ledflecha',  label = 'Panel LED de flecha',  pack = 'ledflecha' },
        { id = 'ogn_flecha',     label = 'Chevrons',             pack = 'flecha' },
        { id = 'ogn_bolardo',    label = 'Bolardo luminoso',     pack = 'bolardo' },
        { id = 'ogn_cono',       label = 'Conos',                pack = 'cono' },
        { id = 'ogn_piano',      label = 'Piano',                pack = 'piano', separar = -0.3 },
    },

    -- Los estilos de antes, grabados en circuitos que ya existen → el suyo nuevo
    Alias = {
        focos = 'ogn_torre', conos = 'ogn_cono', barreras = 'ogn_valla', neumaticos = 'ogn_neumaticos',
        bengalas = 'ogn_bolardo', focos_humo = 'ogn_torre',
        humo_rosa_a = 'ogn_neumaticos', humo_rosa_b = 'ogn_neumaticos', humo_rosa_c = 'ogn_neumaticos',
        columna_rosa = 'ogn_neumaticos', humo = 'ogn_neumaticos', nada = 'ogn_bandera',
    },
}

--[[ Los props propios de carreras (origen_modelos/stream/carreras; se hacen
     con fuente/props/construir.py). Cada uno son una o varias PARTES: la
     primera se planta en el suelo y las demas van pegadas a ella con su
     desplazamiento (la tela de la bandera, a lo alto del mastil).

     En el nombre del modelo, %s es la variante, que pone client/decoracion.lua:
       marca = true    o_rosa / o_verde (Origen)  ·  n_naranja / n_verde (Nacion)
       sin marca       rosa o naranja segun la marca / verde
     El verde es el checkpoint ya pasado. `fijo` = no cambia al pasar (la
     bandera a cuadros). `der` = otras partes para el lado derecho (los
     chevrons apuntan hacia la carretera por los dos lados). ]]
Config.PropsCarrera = {
    bandera    = { marca = true, partes = { { 'ocar_mastil' }, { 'ocar_tela_%s', vec3(0.0, -0.05, 4.055) } } },
    cuadros    = { fijo = true, partes = { { 'ocar_mastil' }, { 'ocar_tela_cuadros', vec3(0.0, -0.05, 4.055) } } },
    neumaticos = { marca = true, partes = { { 'ocar_neumaticos_%s' } } },
    tecpro     = { marca = true, partes = { { 'ocar_tecpro_%s' } } },
    barrera    = { marca = true, partes = { { 'ocar_barrera_%s' } } },
    torre      = { marca = true, partes = { { 'ocar_torre_%s' } } },
    bolardo    = { partes = { { 'ocar_bolardo_%s' } } },
    cono       = { partes = { { 'ocar_cono_%s' } } },
    flecha     = { partes = { { 'ocar_flecha_%s_izq' } }, der = { { 'ocar_flecha_%s_der' } } },
    vela       = { marca = true, partes = { { 'ocar_vela_%s' } } },
    valla      = { marca = true, partes = { { 'ocar_valla_%s' } } },
    bidones    = { marca = true, partes = { { 'ocar_bidones_%s' } } },
    paja       = { marca = true, partes = { { 'ocar_paja_%s' } } },
    carpa      = { marca = true, partes = { { 'ocar_carpa_%s' } } },
    hinchable  = { marca = true, partes = { { 'ocar_hinchable_%s' } } },
    -- Flota, gira para mirar a la camara de cada uno y da luz (`encara`, `luz`:
    -- client/decoracion.lua). luz = metros sobre el origen, alcance e intensidad;
    -- `altura` = metros de mas o de menos sobre el suelo. Ajustado con fotos el
    -- 14/10: 1,4 m mas bajo (la punta, justo por encima de los coches) y la luz
    -- suave (con 12 m y 6 la carretera era un foco rosa, y con 8 y 2,5 aun mucho).
    luminoso   = { marca = true, partes = { { 'ocar_luzcaja_%s' } }, encara = true, altura = -1.4,
                   luz = { alto = 4.8, alcance = 6.0, intensidad = 1.2 } },
    piano      = { partes = { { 'ocar_piano_%s' } } },
    ledflecha  = { partes = { { 'ocar_ledflecha_%s_izq' } }, der = { { 'ocar_ledflecha_%s_der' } } },
}

-- ========================================
-- TIPOS DE CARRERA
-- ========================================

Config.RaceTypes = {
    {
        id = 'circuit',
        label = 'Circuito',
        description = 'Carrera por vueltas, vuelve al inicio',
        icon = 'repeat',
        allowLaps = true
    },
    {
        id = 'sprint',
        label = 'Sprint',
        description = 'Carrera punto A a punto B',
        icon = 'trending-up',
        allowLaps = false
    },
    {
        id = 'drift',
        label = 'Drift',
        description = 'Competencia de puntos por drift',
        icon = 'wind',
        allowLaps = true
    }
}

-- ========================================
-- CLASES DE VEHÍCULOS
-- ========================================

Config.VehicleClasses = {
    {
        id = 'S',
        label = 'Clase S',
        description = 'Súper deportivos y exóticos',
        color = '#ff0000',
        vehicles = {} -- Lista de modelos permitidos (vacío = todos de la clase)
    },
    {
        id = 'A',
        label = 'Clase A',
        description = 'Deportivos de alto rendimiento',
        color = '#ff6b00',
        vehicles = {}
    },
    {
        id = 'B',
        label = 'Clase B',
        description = 'Deportivos intermedios',
        color = '#ffd700',
        vehicles = {}
    },
    {
        id = 'C',
        label = 'Clase C',
        description = 'Compactos y sedanes deportivos',
        color = '#00ff00',
        vehicles = {}
    },
    {
        id = 'D',
        label = 'Clase D',
        description = 'Vehículos urbanos',
        color = '#0080ff',
        vehicles = {}
    },
    {
        id = 'custom',
        label = 'Personalizada',
        description = 'Define los vehículos permitidos',
        color = '#ffffff',
        vehicles = {}
    },
    {
        id = 'any',
        label = 'Cualquiera',
        description = 'Sin restricciones de clase',
        color = '#808080',
        vehicles = {}
    }
}

-- Vehículos prohibidos globalmente (blacklist)
Config.BlacklistedVehicles = {
    'khanjali', -- Tanque
    'rhino', -- Tanque
    'insurgent',
    'insurgent2',
    'insurgent3',
    'menacer',
    'nightshark',
    'vigilante',
    'oppressor',
    'oppressor2',
    'scramjet',
    'deluxo'
}

-- ========================================
-- CONFIGURACIÓN DE CARRERAS
-- ========================================

Config.Racing = {
    MinPlayers = 2, -- Mínimo de jugadores para iniciar
    MaxPlayers = 100, -- Máximo de jugadores por carrera

    -- Countdown
    CountdownSeconds = 5, -- Cuenta regresiva antes de empezar

    -- Ghosting (sin colisiones al inicio)
    GhostingEnabled = true,
    GhostingDuration = 10000, -- ms (10 segundos)

    -- Tiempos
    MaxTimePerCheckpoint = 120, -- segundos máximo por checkpoint
    LapTimeoutMultiplier = 1.5, -- Multiplicador para timeout de vuelta

    -- Anti-trampa
    AntiCheat = {
        enabled = true,
        checkGodmode = true,
        checkTeleport = true,
        maxSpeedDeviation = 1.5 -- Multiplicador sobre velocidad máxima del vehículo
    },

    -- Economía
    MinBuyIn = 100,
    MaxBuyIn = 1000000,
    DefaultCommission = 7, -- % de comisión del sistema (se destruye; 15/10, antes 5)

    -- Distribución de premios (%)
    PrizeDistribution = {
        [1] = 60, -- 60% para el 1º
        [2] = 25, -- 25% para el 2º
        [3] = 15  -- 15% para el 3º
    },

    -- Monedas aceptadas
    Currencies = {
        { id = 'ogn', label = 'OGN' }
    },

    -- Cooldown
    RaceCooldown = 300, -- segundos entre carreras en el mismo circuito
    CreateCooldown = 60, -- segundos entre crear carreras
}

-- ========================================
-- VISUALIZACIÓN
-- ========================================

Config.Visual = {
    -- Checkpoints
    Checkpoint = {
        color = { r = 255, g = 165, b = 0, a = 150 }, -- Naranja
        finishColor = { r = 0, g = 255, b = 0, a = 150 }, -- Verde
        markerType = 1, -- Cilindro vertical
        scale = { x = 10.0, y = 10.0, z = 2.0 }
    },

    -- Blips en mapa
    Blips = {
        circuit = {
            sprite = 315, -- Bandera de carrera
            color = 46, -- Naranja
            scale = 0.8
        },
        activeRace = {
            sprite = 227, -- Bandera animada
            color = 2, -- Verde
            scale = 1.0
        }
    },

    -- Partículas/Efectos
    Effects = {
        countdown = true,
        finishLine = true,
        checkpointPass = true
    }
}

-- ========================================
-- HUD DE CARRERA
-- ========================================

Config.HUD = {
    enabled = true,
    position = 'top-right', -- top-right, top-left, bottom-right, bottom-left
    showMinimap = true,
    showLeaderboard = true,
    maxLeaderboardEntries = 8
}

-- ========================================
-- RANKINGS Y ESTADÍSTICAS
-- ========================================

Config.Rankings = {
    enabled = true,
    saveHistory = true, -- Guardar historial de todas las carreras
    leaderboardTypes = {
        'wins', -- Total de victorias
        'money', -- Total ganado
        'races', -- Total de carreras
        'winrate' -- % de victorias
    }
}

-- ========================================
-- INTEGRACIÓN CON GANGS
-- ========================================

Config.Gangs = {
    enabled = true,
    allowPrivateRaces = true, -- Carreras privadas solo para gang
    gangStats = true -- Estadísticas por gang
}

-- ========================================
-- FUNCIONES DE FRAMEWORK
-- ========================================

Config.GetPlayerMoney = function(source, currency)
    currency = currency or 'ogn'

    -- Qbox (qbx_core)
    if GetResourceState('qbx_core') == 'started' then
        local QBX = exports.qbx_core
        local Player = QBX:GetPlayer(source)
        if Player then
            if currency == 'crypto' then
                return Player.PlayerData.money['crypto'] or 0
            end
            return Player.PlayerData.money[currency] or 0
        end
    -- QBCore
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            if currency == 'crypto' then
                return Player.PlayerData.money['crypto'] or 0
            end
            return Player.PlayerData.money[currency] or 0
        end
    -- ESX
    elseif GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.getAccount(currency).money
        end
    end

    return 0
end

Config.RemoveMoney = function(source, currency, amount)
    currency = currency or 'ogn'

    -- Qbox (qbx_core)
    if GetResourceState('qbx_core') == 'started' then
        local QBX = exports.qbx_core
        local Player = QBX:GetPlayer(source)
        if Player then
            local success = Player.Functions.RemoveMoney(currency, amount)
            return success
        end
    -- QBCore
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local success = Player.Functions.RemoveMoney(currency, amount)
            return success
        end
    -- ESX
    elseif GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.removeAccountMoney(currency, amount)
            return true
        end
    end

    return false
end

Config.AddMoney = function(source, currency, amount)
    currency = currency or 'ogn'

    -- Qbox (qbx_core)
    if GetResourceState('qbx_core') == 'started' then
        local QBX = exports.qbx_core
        local Player = QBX:GetPlayer(source)
        if Player then
            local success = Player.Functions.AddMoney(currency, amount)
            return success
        end
    -- QBCore
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local success = Player.Functions.AddMoney(currency, amount)
            return success
        end
    -- ESX
    elseif GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.addAccountMoney(currency, amount)
            return true
        end
    end

    return false
end

Config.GetPlayerGang = function(source)
    -- Qbox (qbx_core)
    if GetResourceState('qbx_core') == 'started' then
        local QBX = exports.qbx_core
        local Player = QBX:GetPlayer(source)
        if Player and Player.PlayerData.gang then
            return Player.PlayerData.gang.name
        end
    -- QBCore
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and Player.PlayerData.gang then
            return Player.PlayerData.gang.name
        end
    end
    return nil
end

Config.GetPlayerIdentifier = function(source)
    -- Qbox (qbx_core)
    if GetResourceState('qbx_core') == 'started' then
        local QBX = exports.qbx_core
        local Player = QBX:GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    -- QBCore
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    -- ESX
    elseif GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    end
    -- Fallback genérico
    return GetPlayerIdentifier(source, 0)
end

Config.HasItem = function(source, itemName)
    -- Qbox (qbx_core)
    if GetResourceState('qbx_core') == 'started' then
        local QBX = exports.qbx_core
        local Player = QBX:GetPlayer(source)
        if Player then
            local item = Player.Functions.GetItemByName(itemName)
            return item ~= nil and item.amount > 0
        end
    -- QBCore
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local item = Player.Functions.GetItemByName(itemName)
            return item ~= nil and item.amount > 0
        end
    -- ESX
    elseif GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            local item = xPlayer.getInventoryItem(itemName)
            return item ~= nil and item.count > 0
        end
    -- OX Inventory (standalone)
    elseif GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:GetItemCount(source, itemName)
        return count > 0
    end

    return false
end

Config.GetPlayerName = function(source)
    return GetPlayerName(source)
end

-- ========================================
-- CONFIGURACIÓN DE CREWS Y TERRITORIOS
-- ========================================

Config.Crews = {
    Enabled = true,

    -- Creación de Crews
    Creation = {
        MinNameLength = 3,
        MaxNameLength = 50,
        MinTagLength = 2,
        MaxTagLength = 6,
        Cost = 50000, -- Costo para crear una crew
        Currency = 'ogn',
    },

    -- Miembros (sin límite: 0 = ilimitado)
    Members = {
        MaxMembers = 0,
        MinMembersToStartContest = 2,
        DefaultRank = 'member',
    },

    -- Invitaciones
    Invites = {
        ExpireTime = 24 * 60, -- 24 horas en minutos
        MaxPendingInvites = 5,
    },

    -- Niveles y Experiencia
    Levels = {
        Enabled = true,
        MaxLevel = 50,
        XPPerWin = 100,
        XPPerLoss = 25,
        XPPerTerritoryWin = 500,
        XPPerTerritoryDefense = 300,
    },

    -- Territorios
    Territories = {
        Enabled = true,

        -- Protección tras conquista (en minutos, por tamaño de territorio)
        -- small  = 48h  → carreras frecuentes, disputa rápida
        -- medium = 72h  → disputa más espaciada
        -- large  = 96h  → territorios grandes, muy difíciles de quitar
        ProtectionTime = 24 * 60, -- fallback legacy (no se usa si ProtectionTimeBySize está definido)
        ProtectionTimeBySize = {   -- 15/10: más cortas, el mapa se mueve en 6 semanas
            small  = 24 * 60,  -- 24 horas en minutos
            medium = 36 * 60,  -- 36 horas en minutos
            large  = 48 * 60,  -- 48 horas en minutos
        },

        -- Disputas automáticas
        AutoContest = {
            Enabled = true,
            DefaultInterval = 3,     -- MINUTOS entre disputas
            CheckInterval = 1,       -- Revisar cada 1 minuto
            NotifyBefore = 5,        -- Notificar 5 min antes
            MinParticipants = 2,     -- Mínimo de participantes para iniciar
            MinCrews = 2,            -- Mínimo de crews distintas listas para iniciar disputa
            RegistrationTime = 2,    -- Minutos para inscribirse (fallback si el territorio no tiene uno)
            ForceStartTime = 30,     -- Minutos máximos de lobby antes de forzar inicio/cancelar
        },

        -- Recompensas
        Rewards = {
            ConquestWin = 15000,
            DefenseWin = 10000,
            ParticipationReward = 2000,
            ReputationPerWin = 100,
            ReputationPerDefense = 75,
        },
        -- El reward_money de territorios se acredita siempre en la caja de la crew (OGN).

        -- Buy-in obligatorio para carreras de territorio
        RequiredBuyIn = {
            Min = 5000,
            Max = 50000,
            Default = 10000,
        },

        -- Ingreso pasivo para crews con territorios controlados
        PassiveIncome = {
            Enabled = true,
            -- OGN por territorio por intervalo. Es el valor de los territorios
            -- que no tienen uno propio (campo «Ingreso pasivo» del admin vacío).
            AmountPerTerritory = 500,
            IntervalMinutes = 60,       -- Cada 60 minutos
            Currency = 'ogn',
            -- Solo cobra la crew que ha tenido algún miembro conectado durante
            -- el intervalo: una crew que deja de jugar no llena la caja sola.
            SoloConMiembrosConectados = true,
            -- Lo máximo que una crew cobra al día sumando todos sus territorios
            -- (0 = sin tope). El día va por la fecha de la base de datos.
            TopeDiarioPorCrew = 2500,
        },

        -- Bonus de premio en carreras cuyo circuito está en un territorio propio
        RaceBonus = {
            Enabled = true,
            Percent = 20,               -- +20% del premio base
        },

        -- Descuento en buy-in para la crew dueña del territorio
        BuyInDiscount = {
            Enabled = true,
            Percent = 50,               -- 50% de descuento
        },
    },

    -- Permisos por rango
    DefaultPermissions = {
        leader = {
            invite_members = true,
            kick_members = true,
            promote_members = true,
            manage_ranks = true,
            manage_crew = true,
            start_contest = true,
            manage_money = true,
            manage_disputes = true,
            disband_crew = true,
        },
        coleader = {
            invite_members = true,
            kick_members = true,
            promote_members = false,
            manage_ranks = false,
            manage_crew = true,
            start_contest = true,
            manage_money = true,
            manage_disputes = true,
            disband_crew = false,
        },
        member = {
            invite_members = false,
            kick_members = false,
            promote_members = false,
            manage_ranks = false,
            manage_crew = false,
            start_contest = false,
            manage_money = false,
            manage_disputes = false,
            disband_crew = false,
        },
    },

    -- Colores predefinidos para crews
    DefaultColors = {
        '#850e49', -- Rosa Origen
        '#ef4444', -- Rojo
        '#f97316', -- Naranja
        '#eab308', -- Amarillo
        '#22c55e', -- Verde
        '#06b6d4', -- Cyan
        '#3b82f6', -- Azul
        '#8b5cf6', -- Morado
        '#ec4899', -- Rosa
        '#f43f5e', -- Rosa rojizo
    },

    -- Blips en el mapa
    Blips = {
        Territory = {
            Free = {
                sprite = 315,
                color = 0,
                scale = 0.8,
            },
            Occupied = {
                sprite = 315,
                color = 1, -- Se usa el color de la crew
                scale = 1.0,
            },
            Contested = {
                sprite = 315,
                color = 1,
                scale = 1.2,
                flash = true,
            },
        },
    },
}

-- ============================================================================
--  MODOS DE CARRERA, LOBBY AMUEBLADO, ARCADE Y PAPELES
-- ============================================================================

--[[ Los modos que se pueden elegir al crear una carrera. El servidor solo
     acepta los de esta lista (server/modos.lua).
       circuit      vueltas al circuito, gana el primero
       sprint       de la salida a la meta, una sola pasada
       drift        gana quien mas puntos de derrape hace; el coche sale ya
                    con las ruedas de drift puestas
       eliminacion  al acabar cada vuelta, el ultimo en cruzar queda fuera;
                    las vueltas las pone el servidor (corredores - 1)
       arcade       como circuit, con potenciadores por el recorrido ]]
Config.Modos = {
    circuit     = { label = 'Circuito' },
    sprint      = { label = 'Sprint' },
    drift       = { label = 'Drift' },
    eliminacion = { label = 'Eliminación' },
    arcade      = { label = 'Arcade' },
}

--[[ El lobby: lo que el que crea el circuito coloca alrededor de la salida
     (boton «Amueblar» de la ficha del circuito, client/amueblar.lua). Solo se
     ve mientras hay una carrera abierta en ese circuito. ]]
Config.Lobby = {
    Distancia  = 220.0,  -- a que distancia de la salida aparecen los muebles
    RadioMax   = 400.0,  -- lo mas lejos de la salida que se puede colocar algo
    MaxMuebles = 80,
    MaxPlazas  = 40,
    MaxItems   = 60,

    -- Las secciones del catalogo, en el orden en que salen en el menu.
    Categorias = {
        { id = 'salida',   label = 'Salida y meta' },
        { id = 'barreras', label = 'Barreras' },
        { id = 'luces',    label = 'Luces' },
        { id = 'paddock',  label = 'Paddock' },
        { id = 'publico',  label = 'Público' },
    },

    --[[ Lo que se puede colocar. Un modelo que el juego no tenga se salta solo.
         Los nuestros (ocar_*, origen_modelos/stream/carreras) salen con el
         color de la marca: propio() pone la variante. Cada servidor tiene su
         base, asi que lo que se guarda es el modelo ya resuelto. 14/10: fuera
         los del juego que tienen equivalente nuestro. ]]
    Catalogo = (function()
        local nacion = GetConvar('origen:marca', 'origen') == 'nacion'
        local function propio(modelo, conMarca)
            return modelo:format(conMarca and (nacion and 'n_naranja' or 'o_rosa') or (nacion and 'naranja' or 'rosa'))
        end
        return {
        { cat = 'salida',   label = 'Arco hinchable',        model = propio('ocar_arco_%s', true) },
        { cat = 'salida',   label = 'Bandera vela',          model = propio('ocar_vela_%s', true) },
        { cat = 'salida',   label = 'Columna hinchable',     model = propio('ocar_hinchable_%s', true) },
        { cat = 'salida',   label = 'Arco de salida',        model = 'stt_prop_startline_gantry' },
        { cat = 'salida',   label = 'Pórtico de carrera',    model = 'stt_prop_race_gantry_01' },
        { cat = 'salida',   label = 'Línea de salida',       model = 'stt_prop_race_start_line_01' },
        { cat = 'salida',   label = 'Pancarta de salida',    model = 'prop_tri_start_banner' },
        { cat = 'salida',   label = 'Pancarta de meta',      model = 'prop_tri_finish_banner' },
        { cat = 'salida',   label = 'Mástil con bandera',    model = 'stt_prop_flagpole_1a' },
        { cat = 'barreras', label = 'Valla con lona',        model = propio('ocar_valla_%s', true) },
        { cat = 'barreras', label = 'Barrera de hormigón',   model = propio('ocar_barrera_%s', true) },
        { cat = 'barreras', label = 'Barrera Tecpro',        model = propio('ocar_tecpro_%s', true) },
        { cat = 'barreras', label = 'Pila de neumáticos',    model = propio('ocar_neumaticos_%s', true) },
        { cat = 'barreras', label = 'Balas de paja',         model = propio('ocar_paja_%s', true) },
        { cat = 'barreras', label = 'Piano',                 model = propio('ocar_piano_%s') },
        { cat = 'barreras', label = 'Chevrons',              model = propio('ocar_flecha_%s_izq') },
        { cat = 'barreras', label = 'Panel LED de flecha',   model = propio('ocar_ledflecha_%s_izq') },
        { cat = 'barreras', label = 'Cono',                  model = propio('ocar_cono_%s') },
        { cat = 'barreras', label = 'Muro de neumáticos',    model = 'stt_prop_tyre_wall_01' },
        { cat = 'barreras', label = 'Muro de neumáticos 2',  model = 'prop_tyre_wall_01' },
        { cat = 'barreras', label = 'Valla metálica',        model = 'prop_fncsec_03b' },
        { cat = 'luces',    label = 'Torre LED',             model = propio('ocar_torre_%s', true) },
        { cat = 'luces',    label = 'Pancarta luminosa',     model = propio('ocar_luzcaja_%s', true) },
        { cat = 'luces',    label = 'Bolardo luminoso',      model = propio('ocar_bolardo_%s') },
        { cat = 'luces',    label = 'Foco de obra',          model = 'prop_worklight_03b' },
        { cat = 'luces',    label = 'Foco doble',            model = 'prop_worklight_04d' },
        { cat = 'paddock',  label = 'Carpa',                 model = propio('ocar_carpa_%s', true) },
        { cat = 'paddock',  label = 'Bidones',               model = propio('ocar_bidones_%s', true) },
        { cat = 'paddock',  label = 'Generador',             model = 'prop_generator_03b' },
        { cat = 'paddock',  label = 'Carro de herramientas', model = 'prop_toolchest_05' },
        { cat = 'paddock',  label = 'Caja de herramientas',  model = 'prop_tool_box_04' },
        { cat = 'paddock',  label = 'Gato de taller',        model = 'prop_carjack' },
        { cat = 'publico',  label = 'Grada',                 model = 'prop_bleachers_01' },
        { cat = 'publico',  label = 'Mesa',                  model = 'prop_table_03' },
        { cat = 'publico',  label = 'Silla',                 model = 'prop_chair_08' },
        { cat = 'publico',  label = 'Altavoz',               model = 'prop_speaker_06' },
        { cat = 'publico',  label = 'Mesa de DJ',            model = 'prop_dj_deck_01' },
        { cat = 'publico',  label = 'Nevera',                model = 'prop_coolbox_01' },
        }
    end)(),

    -- Los que se quitaron del catalogo el 14/10: ya no salen en el menu, pero
    -- los lobbies que ya los tienen colocados los conservan al volver a guardar
    -- (server/modos.lua, SanearExtras, tiraba lo que no estuviera en el catalogo).
    Antiguos = {
        'prop_inflatearch_01', 'prop_inflategate_01', 'prop_beachflag_le', 'prop_offroad_tyres02',
        'prop_barrier_wat_03b', 'prop_barrier_work05', 'prop_barrier_work06a', 'prop_roadcone02a',
        'stt_prop_corner_sign_01', 'xm_prop_base_tripod_lampa', 'prop_gazebo_02', 'prop_gazebo_03', 'prop_barrel_02a',
    },
}

--[[ El modo arcade. Los potenciadores salen de dos sitios: los que el creador
     coloca a mano en el circuito, y una fila de cajas sorpresa que se pone
     sola cada `FilaCada` checkpoints (0 la quita). ]]
Config.Arcade = {
    FilaCada     = 3,
    RadioCoger   = 3.6,     -- metros
    Reaparece    = 8000,    -- ms hasta que vuelve a estar
    TurboMs      = 2600,    -- lo que dura un turbo
    TurboFuerza  = 2.6,     -- multiplicador de potencia mientras dura
    Tipos = {
        turbo    = { label = 'Turbo',      marker = 22, color = { 216, 27, 85 } },
        reparar  = { label = 'Reparación', marker = 36, color = { 220, 221, 224 } },   -- pieza pegatina (se distingue por el simbolo)
        sorpresa = { label = 'Sorpresa',   marker = 32, color = { 220, 221, 224 } },   -- pieza pegatina
    },
    Orden = { 'turbo', 'reparar', 'sorpresa' },
}

--[[ Apostar los papeles: cada uno se juega el coche con el que se apunta y el
     ganador se queda todos. Solo coches propios (player_vehicles). ]]
Config.Papeles = {
    Enabled = true,
    MinCorredores = 2,   -- con menos nadie pierde nada
}

--[[ Valoraciones y circuito de la semana (server/valoraciones.lua, 14/10).

     Valora (1-5 estrellas) solo quien ha corrido el circuito: tiene una vuelta
     suya en racing_tiempos. Cada lunes sale solo el circuito de la semana: el
     mejor valorado con un minimo de votos, con la media «bayesiana» (dos
     votos de 5 no ganan a cuarenta de 4,5) y sin repetir el de la semana
     anterior. Un admin puede fijar otro desde el panel.

     Correrlo da mas: los puntos de temporada por ExtraPuntos y, en carreras
     con bote, un ExtraDinero sobre el premio que pone la casa. Ese dinero
     solo con MinCorredoresDinero pilotos distintos y con un tope al dia por
     jugador: si no, dos cuentas apostando entre ellas sacarian dinero sin fin. ]]
--[[ GUERRA DE TERRITORIOS (server/guerras.lua, 15/10). Descubrir, reconocer,
     declarar, ventanas fijas (hora de Madrid) y carrera por equipos. ]]
Config.Guerras = {
    -- Ventanas por día de la semana (0 = domingo … 6 = sábado), en horas.
    Ventanas = {
        [0] = { 0, 19, 21 },          -- domingo (las 00:00 son la última del sábado)
        [1] = { 20, 22 }, [2] = { 20, 22 }, [3] = { 20, 22 }, [4] = { 20, 22 }, [5] = { 20, 22 },
        [6] = { 18, 20, 22 },         -- sábado: Noche de asaltos
    },
    AntelacionMin   = 180,            -- la guerra va a la primera ventana a más de esto
    RegistroMin     = 5,              -- minutos de sala antes de salir
    Tasa            = { small = 1500, medium = 3000, large = 6000 },   -- de la caja; la mitad si está descuidado
    DestruyeParte   = 0.5,            -- de la tasa, lo que se pierde; el resto, al dueño si defiende
    MinMiembros     = 4,
    MaxAtacantes    = 3,
    PilotosPorCrew  = 4,
    Puntos          = { 25, 18, 15, 12, 10, 8, 6, 4, 2, 1 },
    Reconocer       = { Veces = 3, Miembros = 2 },
    RespetoDescubrir = 50,
    PresenciaHoras  = 72,             -- sin carrera en su circuito en este tiempo, descuidado
    AbiertasPorVentana = 2,
    SoltadoDias     = 3,              -- un territorio soltado no sale en las abiertas en estos días
    Conquista       = { small = 2000, medium = 4000, large = 8000 },   -- OGN a la caja al conquistar
    Pasivo          = { small = 40, medium = 80, large = 150 },         -- OGN por hora, con presencia
    Casa = {
        NivelMin    = 3,
        CosteCambio = 5000,
        EsperaDias  = 7,
        BanderaDia  = 50,
        Recuperar   = 200,
        Invasor     = 1.5,            -- respeto de crew de quien gana en casa ajena a uno de casa
        PorInvasor  = 10,             -- respeto de la crew de casa por invasor que acaba detrás
    },
}

--[[ NIVEL DE CREW (server/crew_nivel.lua, 15/10). El respeto total de la
     crew sube su nivel (1-30); cada tabla es { nivel desde el que vale, valor }. ]]
Config.CrewNivel = {
    Enabled = true,
    NivelBase = 1200,          -- pasar del n al n+1: NivelBase + NivelPaso·(n−1)
    NivelPaso = 500,
    NivelMax  = 30,

    ParteDelMiembro = 0.25,    -- de lo que gana un miembro en una carrera válida
    TopeMiembroDia  = 400,     -- lo que un miembro puede aportar al día
    PorRival        = 10,      -- por cada piloto de OTRA crew al que gana
    RivalMax        = 60,      -- por carrera
    TopeExtraDia    = 200,     -- lo que un miembro aporta al día por ganar a otras crews

    -- Territorios (pequeño / mediano / grande)
    Conquista = { small = 400, medium = 800, large = 1500 },
    Defensa   = { small = 200, medium = 400, large = 750 },
    PerderParte = 0.5,         -- quien lo pierde: −esta parte de la conquista (solo de temporada)
    Soltar    = 100,           -- soltar un territorio (solo de temporada)
    RetoGanado = 100,          -- ganar un reto entre crews, más lo apostado
    Semana    = { 1000, 600, 300 },   -- top 3 de la semana

    -- Plazas de miembros: de 6 al empezar a 30 en el nivel máximo (15/10), casi una por nivel.
    Miembros    = { {1, 6}, {2, 7}, {3, 8}, {4, 9}, {5, 10}, {6, 11}, {8, 12}, {10, 13}, {11, 14}, {12, 15}, {14, 16}, {15, 17},
                    {16, 18}, {18, 19}, {19, 20}, {20, 21}, {22, 22}, {23, 23}, {24, 24}, {25, 25}, {26, 26}, {27, 27}, {28, 28}, {29, 29}, {30, 30} },
    Garaje      = { {1, 2}, {3, 3}, {5, 4}, {8, 6}, {12, 8}, {16, 10}, {20, 12}, {22, 14}, {25, 16}, {26, 18}, {30, 20} },
    Territorios = { {1, 0}, {2, 1}, {6, 2}, {10, 3}, {14, 4}, {20, 5}, {26, 6} },
    Clases      = { {1, { 'D', 'C' }}, {5, { 'D', 'C', 'B' }}, {10, { 'D', 'C', 'B', 'A' }},
                    {16, { 'D', 'C', 'B', 'A', 'S' }}, {22, { 'D', 'C', 'B', 'A', 'S', 'S+' }} },
    AtacarTamano = { small = 2, medium = 6, large = 12 },
    NivelRetos  = 4,

    --[[ LA BASE QUE CRECE (15/10). La casa de crew de origen_housing (si es
         de modalidad libre) sube de tamaño sola con el nivel: el tamaño de
         housing abre más celdas, plantas y sótanos, y lo construido se
         queda. Nunca se le baja. Cada tamaño paga un mantenimiento semanal
         de la caja (el lunes, hora de Madrid); si no llega, la crew deja de
         cobrar el ingreso pasivo de sus territorios hasta pagarlo. ]]
    --[[ CATÁLOGO DE LA CREW POR DEFECTO (15/10). Si la administración no ha
         metido coches propios en el catálogo general (Admin › Concesionario de
         crew), se vende esta lista. Coches del juego, por nivel de crew y
         clase; el dinero sale de la caja de la crew. Son metas de semanas:
         una crew activa junta unos 15.000-25.000 OGN por semana. ]]
    Catalogo = {
        { id = 'futo',      modelo = 'futo',      nombre = 'Futo',            clase = 'D', nivel = 1,  precio = 8000,   max = 2 },
        { id = 'blista2',   modelo = 'blista2',   nombre = 'Blista Compact',  clase = 'D', nivel = 1,  precio = 9000,   max = 2 },
        { id = 'sultan',    modelo = 'sultan',    nombre = 'Sultan',          clase = 'C', nivel = 2,  precio = 18000,  max = 2 },
        { id = 'penumbra',  modelo = 'penumbra',  nombre = 'Penumbra',        clase = 'C', nivel = 3,  precio = 20000,  max = 2 },
        { id = 'elegy2',    modelo = 'elegy2',    nombre = 'Elegy RH8',       clase = 'C', nivel = 4,  precio = 24000,  max = 2 },
        { id = 'kuruma',    modelo = 'kuruma',    nombre = 'Kuruma',          clase = 'B', nivel = 5,  precio = 38000,  max = 1 },
        { id = 'jester',    modelo = 'jester',    nombre = 'Jester',          clase = 'B', nivel = 6,  precio = 45000,  max = 1 },
        { id = 'comet2',    modelo = 'comet2',    nombre = 'Comet',           clase = 'B', nivel = 8,  precio = 52000,  max = 1 },
        { id = 'sultanrs',  modelo = 'sultanrs',  nombre = 'Sultan RS',       clase = 'A', nivel = 10, precio = 75000,  max = 1 },
        { id = 'zr350',     modelo = 'zr350',     nombre = 'ZR350',           clase = 'A', nivel = 12, precio = 85000,  max = 1 },
        { id = 'jester3',   modelo = 'jester3',   nombre = 'Jester Classic',  clase = 'A', nivel = 14, precio = 95000,  max = 1 },
        { id = 'italigtb',  modelo = 'italigtb',  nombre = 'Itali GTB',       clase = 'S', nivel = 16, precio = 140000, max = 1 },
        { id = 't20',       modelo = 't20',       nombre = 'T20',             clase = 'S', nivel = 19, precio = 170000, max = 1 },
        { id = 'krieger',   modelo = 'krieger',   nombre = 'Krieger',         clase = 'S+', nivel = 22, precio = 240000, max = 1 },
        { id = 'emerus',    modelo = 'emerus',    nombre = 'Emerus',          clase = 'S+', nivel = 26, precio = 280000, max = 1 },
    },

    Base = {
        { nivel = 1,  tamano = 'pequena', nombre = 'Garaje pequeño', mantenimiento = 0 },
        { nivel = 8,  tamano = 'media',   nombre = 'Nave',           mantenimiento = 3000 },
        { nivel = 16, tamano = 'grande',  nombre = 'Cuartel',        mantenimiento = 7000 },
        { nivel = 25, tamano = 'premium', nombre = 'Sede',           mantenimiento = 15000 },
    },

    -- Fin de temporada (por respeto de temporada): OGN a la caja por puesto.
    PremiosTemporada = { 60000, 35000, 20000, 5000, 5000, 5000, 5000, 5000, 5000, 5000 },
    CocheCampeona    = 'sultan2',   -- coche de temporada al garaje de la crew campeona

    --[[ PASE DE CREW (15/10). Sube con el respeto de temporada de la crew; lo
         reclama el líder o un colíder y es de la crew para siempre. Solo cosas
         que existen: piezas del pack de crews de origen_housing (se
         desbloquean para su casa; al colocarlas se pagan como siempre), OGN a
         la caja y el coche de crew de la temporada. ]]
    Pase = {
        Niveles = 30,
        Base    = 400,               -- respeto del nivel n: Base + Paso·(n−1)
        Paso    = 40,
        DineroPorNivel = 300,        -- a la caja, en los niveles sin pieza
        Recompensas = {
            [3]  = { piezas = { 'bandera' }, texto = 'Banderas de cuadros' },
            [5]  = { piezas = { 'torre_neumaticos', 'cono', 'caballetes' }, texto = 'Torre de neumáticos, conos y caballetes' },
            [8]  = { piezas = { 'sillon_baquet', 'sofa_baquets' }, texto = 'Sillón y sofá de baquets' },
            [10] = { piezas = { 'banco', 'panel_herramientas', 'carro' }, texto = 'Banco, panel y carro de herramientas' },
            [13] = { piezas = { 'matriculas', 'tablero_tiempos' }, texto = 'Pared de matrículas y pizarra de tiempos' },
            [15] = { piezas = { 'neon_rayo', 'neon_llama', 'neon_flecha', 'neon_garage' }, texto = 'Los cuatro neones' },
            [18] = { piezas = { 'simulador' }, texto = 'Simulador de tres pantallas' },
            [20] = { piezas = { 'vitrina' }, texto = 'Vitrina de trofeos' },
            [22] = { piezas = { 'semaforo', 'estanteria_llantas' }, texto = 'Semáforo de salida y estantería de llantas' },
            [25] = { piezas = { 'barra_coche', 'nevera' }, texto = 'Barra con frontal de coche y nevera' },
            [28] = { piezas = { 'grua_motor', 'motor_soporte' }, texto = 'Grúa de taller y motor en soporte' },
            [30] = { coche = true, texto = 'Coche de crew de la temporada' },
        },
        Coche = 'sultan2',
    },
}

--[[ Topes de los movimientos de dinero (15/10). Por persona y día de Madrid.
     Vender OGN por dinero de fuera del juego deja rastro y no sale a cuenta. ]]
Config.TopesDinero = {
    EnvioPersonalDia = 5000,   -- OGN que un jugador puede mandar a otros al día
    ComisionEnvio    = 0.05,   -- se destruye: llega la cantidad menos esto
    CajaLiderDia     = 10000,  -- lo que el líder puede sacar o mandar de la caja al día
    CajaColiderDia   = 2500,   -- lo mismo para un colíder
}

Config.Semana = {
    Enabled             = true,
    MinVotos            = 3,      -- votos para poder salir de la semana
    ExtraPuntos         = 1.25,   -- puntos de temporada x1,25
    -- 0 desde el 15/10: con 4 cuentas propias se sacaban 5.000 OGN al dia
    -- por cuenta. El circuito de la semana da puntos, no dinero.
    ExtraDinero         = 0,
    MinCorredoresDinero = 4,
    TopeDineroDia       = 5000,   -- OGN de extra por jugador y dia
}

--[[ Ranking semanal de crews y «crew de la semana» (server/ranking.lua, 14/10).

     Cada carrera que cuenta suma puntos a la crew de cada piloto que la acaba,
     según su puesto entre los que acabaron. Ganar o defender un territorio
     suma un extra (una vez por territorio, crew y semana). La semana va de
     lunes 00:00 a domingo 23:59 en la hora de ZonaHoraria; al cerrarse se
     paga a la CAJA de las tres primeras, se guarda en el histórico y la
     siguiente empieza en cero.

     Para que una crew no se haga carreras entre sus miembros: hacen falta
     MinCorredores pilotos distintos y, entre ellos, dos crews distintas o
     alguien sin crew. Y cada piloto aporta como mucho TopeJugadorDia puntos
     al dia (sin contar los de territorio). ]]
Config.RankingSemanal = {
    Enabled        = true,
    -- 'Europe/Madrid' (y Paris, Berlin, Rome…), 'Europe/Lisbon', 'Europe/London',
    -- 'Atlantic/Canary' y 'UTC' llevan su cambio de hora; 'local' = la de la máquina.
    ZonaHoraria    = 'Europe/Madrid',
    -- Puntos por puesto entre los que ACABAN; a partir del último de la lista, Resto.
    Puntos         = { 25, 18, 15, 12, 10, 8, 6, 4, 2 },
    Resto          = 1,
    MinCorredores  = 3,
    TopeJugadorDia = 150,
    -- Los modos que cuentan (la contrarreloj y las casuales no, nunca)
    -- Arcade y drift fuera (15/10): los objetos y los puntos de drift los decide el cliente.
    Tipos          = { circuit = true, sprint = true, eliminacion = true, territory = true },
    Territorio     = { Ganado = 50, Defendido = 25 },
    -- OGN a la caja de la crew por puesto al cerrar la semana
    Premios        = { 15000, 9000, 4500 },   -- 15/10: antes 50.000/25.000/10.000 (85.000 nuevos cada semana)
    -- Segundos tras el cierre antes de pagar: lo que tarda en guardarse una
    -- carrera que acabó a las 23:59.
    Gracia         = 120,
    Historico      = 8,      -- semanas pasadas que se ven en el panel
}

--[[ Lo que se elige al crear la carrera además del modo: tráfico, rebufo,
     hora y clima (server/ambiente.lua y client/ambiente.lua).

     Sin tráfico, el coche de cada corredor atraviesa todo lo que no es de su
     carrera —coches de NPC, coches y gente de otros jugadores— y se ve medio
     transparente. Lo hacen las dos partes: el corredor no choca con nada, y
     quien no corre tampoco choca con él. Hora y clima son solo para los
     corredores (y su copiloto); el resto de la ciudad sigue con lo suyo. ]]
Config.Ambiente = {
    -- Sin tráfico
    RadioTraspasa = 70.0,   -- metros alrededor del coche donde se atraviesa
    AlfaCorredor  = 150,    -- 0-255: cómo ve el resto a un corredor sin tráfico
    AlfaTrafico   = 110,    -- 0-255: cómo ve el corredor lo que atraviesa
    -- Hora: id -> hora del reloj. nil o '' = la del servidor.
    Horas = {
        amanecer  = { label = 'Amanecer',  hora = 6,  minuto = 30 },
        dia       = { label = 'Mediodía',  hora = 13, minuto = 0 },
        atardecer = { label = 'Atardecer', hora = 19, minuto = 30 },
        noche     = { label = 'Noche',     hora = 23, minuto = 30 },
    },
    -- Clima: id -> tipo de GTA. nil o '' = el del servidor.
    Climas = {
        despejado = { label = 'Despejado', tipo = 'EXTRASUNNY' },
        nublado   = { label = 'Nublado',   tipo = 'OVERCAST' },
        lluvia    = { label = 'Lluvia',    tipo = 'RAIN' },
        tormenta  = { label = 'Tormenta',  tipo = 'THUNDER' },
        niebla    = { label = 'Niebla',    tipo = 'FOGGY' },
    },
}

--[[ Sesiones: varias carreras seguidas con los mismos corredores, como las
     listas de GTA Online o Forza (server/sesiones.lua). Al acabar cada una, los
     que han corrido votan la siguiente entre unos circuitos sorteados y
     «Aleatorio»; los puntos de cada carrera se suman a una clasificación de
     la sesión. Para ir a la salida de la siguiente se les marca en el GPS y se
     les apunta solos al llegar. ]]
Config.Sesiones = {
    Enabled       = true,
    Carreras      = { 3, 5, 8 },  -- las que se pueden elegir al crear
    Opciones      = 3,            -- circuitos sorteados en la votación (+ «Aleatorio»)
    Votacion      = 25,           -- segundos para votar
    EsperaVotar   = 6,            -- segundos entre los resultados y la votación
    TiempoLlegar  = 240,          -- segundos para llegar a la siguiente salida
    RadioLlegada  = 45.0,         -- a cuántos metros de la salida te apunta solo
    -- Puntos por puesto (los que no acaban, 0)
    Puntos        = { 25, 18, 15, 12, 10, 8, 6, 4, 2, 1 },
    -- Si nadie la toca en este tiempo, la sesión se da por acabada (minutos)
    Caduca        = 40,
}

--[[ La policía detrás de las carreras ilegales (server/policia.lua y
     client/policia.lua). Común a los dos servidores.

     - Al salir una carrera, si toca, salta un aviso en el dispatch de
       origen_police. Cuánto tarda, si salta en carreras pequeñas y lo bien
       que sitúa al grupo depende del CALOR (nivel de búsqueda, 0-5) del más
       buscado de los que corren.
     - Desde ese aviso y hasta que acaba la carrera, la policía DE SERVICIO
       ve en su mapa un círculo donde anda el pelotón, que se mueve cada
       `Intervalo` segundos y se estrecha con el calor. La posición la saca el
       servidor de los peds de los corredores.
     - El calor sube al correr (más si ganas o hay dinero en juego) y baja
       solo con el tiempo. Se guarda en `racing_policia_calor`.
     - Si te esposan corriendo: fuera de la carrera (DNF; la entrada no se
       devuelve), calor por las nubes y, si se activa, multa. ]]
Config.Policia = {
    Enabled    = true,

    -- Qué carreras mira la policía. normal = las del hub; disputa = entre
    -- crews; territorio = por un territorio; torneo = conquistas del mercado
    -- negro; casual = las que no cuentan para estadísticas.
    -- contrarreloj y prueba nunca dan aviso (se corre solo).
    Tipos = {
        normal       = true,
        disputa      = true,
        territorio   = true,
        torneo       = false,
        casual       = true,
        contrarreloj = false,
        prueba       = false,
    },
    MinCorredores = 2,       -- con menos no es una carrera: ni aviso ni calor

    Intervalo  = 5,          -- segundos entre una posición y la siguiente
    Referencia = 'centro',   -- 'centro' del grupo o 'lider' (el primero)

    Aviso = {
        MinCorredores     = 3,     -- más pequeñas no dan aviso...
        CalorParaPequenas = 3.0,   -- ...salvo que alguien tenga este calor
        Retraso           = 60,    -- segundos hasta el aviso, sin calor
        RetrasoMin        = 5,     -- con el calor al máximo
        RadioMax          = 650.0, -- imprecisión del círculo sin calor (m)
        RadioMin          = 90.0,  -- con el calor al máximo
        MoverAviso        = true,  -- mover también el aviso del dispatch
        MoverCada         = 15,    -- segundos entre movimientos del aviso
    },

    Calor = {
        Max         = 5.0,
        Correr      = 0.5,   -- por cada carrera corrida
        Ganar       = 0.5,   -- además, si la ganas
        Dinero      = 0.5,   -- además, si había entrada, bote o papeles
        Detenido    = 2.0,   -- si te detienen en plena carrera
        BajaPorHora = 0.25,  -- lo que se enfría cada hora (también desconectado)
    },

    -- Esposado en plena carrera (las esposas de origen_police)
    Detencion = {
        Enabled        = true,
        RadioPoli      = 15.0, -- un agente de servicio a esta distancia...
        VentanaIntento = 90,   -- ...o un esposado visto hace menos de esto (s)
    },

    -- Multa automática al detenido: una factura en origen_police_bills (la
    -- tabla de facturas de origen_police; no tiene export para crearlas) y
    -- en el móvil si está origen_phone.
    Multa = {
        Enabled  = false,
        Importe  = 2500,
        Concepto = 'Participar en una carrera ilegal',
    },

    -- Si origen_police no está, quién cuenta como policía (trabajos de qbx)
    Trabajos = { 'police', 'sheriff' },
}
