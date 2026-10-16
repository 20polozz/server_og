--[[ origen_notify, sin que un reinicio suyo rompa los puntos. Los onEnter,
     onExit y nearby de lib.points corren en el hilo de ox_lib sin pcall: un
     export que falla mientras notify esta reiniciando mataba ese hilo y los
     NPC del mercado dejaban de responder hasta reiniciar este recurso. ]]
function NotifySeguro(fn, ...)
    if GetResourceState('origen_notify') ~= 'started' then return end
    local args = { ... }
    pcall(function() exports['origen_notify'][fn](exports['origen_notify'], table.unpack(args)) end)
end

-- ========================================
-- SISTEMA DE ZONAS, BLIPS Y NPCs — multi-mercado
-- Cada mercado en Config.Markets genera sus propios NPCs y zona.
-- ========================================

-- [marketId] = { npcEntity, doorNpcEntity, zone, blip }
local MarketInstances = {}

-- Rastrea si el jugador está físicamente dentro de cada zona (para re-registrar al activar)
InZoneMap = {}

-- Compartido con main.lua
MarketState = MarketState or {}
for marketId in pairs(Config.Markets) do
    MarketState[marketId] = MarketState[marketId] or {
        active     = false,
        owner      = nil,
        ownerLabel = nil,
        isOwner    = false,
        protected  = false,
    }
end

local normalizeDynamicCfg

-- ========================================
-- NPC HELPERS
-- ========================================

local function spawnNPC(cfg)
    local model = cfg.Model
    if type(model) == 'string' then
        model = joaat(model)
    end

    if not model or model == 0 or not IsModelInCdimage(model) or not IsModelValid(model) then
        Config.DebugPrint('[BlackMarket] Invalid NPC model, skipping ped spawn:', tostring(cfg.Model))
        return nil
    end

    RequestModel(model)
    local tries = 0
    while not HasModelLoaded(model) and tries < 200 do
        Wait(10)
        tries = tries + 1
    end

    if not HasModelLoaded(model) then
        Config.DebugPrint('[BlackMarket] Model load timeout, skipping ped spawn:', tostring(cfg.Model))
        return nil
    end

    local ent = CreatePed(4, model, cfg.Coords.x, cfg.Coords.y, cfg.Coords.z - 1.0, cfg.Coords.w, false, true)
    if not ent or ent == 0 then
        Config.DebugPrint('[BlackMarket] CreatePed failed for model:', tostring(cfg.Model))
        SetModelAsNoLongerNeeded(model)
        return nil
    end

    FreezeEntityPosition(ent, cfg.Freeze)
    SetEntityInvincible(ent, cfg.Invincible)
    SetBlockingOfNonTemporaryEvents(ent, cfg.BlockEvents)
    TaskStartScenarioInPlace(ent, cfg.Scenario, 0, true)
    SetModelAsNoLongerNeeded(model)
    return ent
end

-- ========================================
-- INICIALIZACIÓN POR MERCADO
-- ========================================

local function setupMarket(marketId, mCfg)
    local instance = { npcEntity = nil, doorNpcEntity = nil, zone = nil, blip = nil }

    -- ── El punto del mapa (si configurado) ─────────────────────────
    --[[ Ya no es un blip del juego: se registra en origen_map y de ahi lo leen
         los tres mapas del servidor. El sprite y la escala del panel dejan de
         pintar nada —la chincheta es dibujo nuestro— pero el rotulo y, sobre
         todo, EL COLOR siguen mandando: aqui el color no es decoracion, dice
         si el mercado esta activo o quien lo tiene tomado. Eso lo aplica
         UpdateMarketBlip, mas abajo. ]]
    if mCfg.Blip then
        instance.blip = 'mercado_' .. tostring(marketId)
        OrigenMapa.Poner(instance.blip, {
            x = mCfg.Center.x, y = mCfg.Center.y, z = mCfg.Center.z,
            cat = 'illegal',
            nombre = mCfg.label or 'Mercado Negro',
        })
    end

    -- ── NPC vendedor ───────────────────────────────────────────────
    -- Los dos NPC los pone y los quita el vigilante de abajo, por cercania.

    -- ── NPC puerta ────────────────────────────────────────────────

    -- ── Zona de captura ────────────────────────────────────────────
    -- Ya no se crea aquí: la lleva client/zonas.lua, que sabe de varias
    -- zonas por mercado, de alturas y de cuál toca en cada captura.

    MarketInstances[marketId] = instance

    -- ── Punto interacción NPC vendedor ────────────────────────────
    CreateThread(function()
        local coords   = mCfg.NPC.Coords
        local inZone   = false
        local point    = lib.points.new({
            coords   = vec3(coords.x, coords.y, coords.z),
            distance = mCfg.InteractionDistance or 2.5,
        })

        function point:onEnter()
            inZone = true
            NotifySeguro('DrawText', 'E', mCfg.label or 'Mercado Negro')
        end

        function point:onExit()
            inZone = false
            NotifySeguro('HideText')
        end

        function point:nearby()
            if inZone and IsControlJustReleased(0, 38) then
                NotifySeguro('HideText')
                TriggerServerEvent('blackmarket:server:openMarket', marketId)
            end
        end
    end)

    -- ── Punto interacción NPC puerta ──────────────────────────────
    CreateThread(function()
        local coords     = mCfg.DoorNPC.Coords
        local inDoorZone = false
        local point      = lib.points.new({
            coords   = vec3(coords.x, coords.y, coords.z),
            distance = mCfg.InteractionDistance or 2.5,
        })

        function point:onEnter()
            inDoorZone = true
            NotifySeguro('DrawText', 'E', 'Información / Torneo')
        end

        function point:onExit()
            inDoorZone = false
            NotifySeguro('HideText')
        end

        function point:nearby()
            if inDoorZone and IsControlJustReleased(0, 38) then
                NotifySeguro('HideText')

                -- Siempre consultar al servidor para obtener el estado fresco del torneo.
                -- Así funciona también para jugadores que se conectaron DESPUÉS de que
                -- empezara la inscripción y nunca recibieron tournamentRegistrationOpen.
                local status = lib.callback.await('blackmarket:getTournamentStatus', false, marketId)

                if status and status.active then
                    if not status.isRegistered then
                        local directJoin = lib.callback.await('blackmarket:registerForConquest', false, marketId)
                        if directJoin and (directJoin.success or directJoin.alreadyRegistered) then
                            status.isRegistered = true
                        end
                    end

                    -- Reconstruir (o actualizar) el estado local con datos del servidor
                    local tournament = TournamentOpen and TournamentOpen[marketId]
                    local secsLeft   = status.secsLeft or 0

                    if not tournament then
                        -- Jugador llegó tarde — crear entrada local desde datos del servidor
                        TournamentOpen = TournamentOpen or {}
                        TournamentOpen[marketId] = {
                            conquestId        = status.conquestId,
                            secsLeft          = secsLeft,
                            receivedTimer     = GetGameTimer(),
                            circuitName       = status.circuitName,
                            mLabel            = status.mLabel,
                            registeredCrews   = status.registeredCrews or {},
                            isRegistered      = status.isRegistered or false,
                            vehicleClassName  = status.vehicleClassName,
                            collisionsEnabled = status.collisionsEnabled or false,
                        }
                        tournament = TournamentOpen[marketId]
                    else
                        -- Actualizar con datos frescos del servidor
                        tournament.registeredCrews = status.registeredCrews or tournament.registeredCrews or {}
                        tournament.isRegistered    = status.isRegistered == true
                        tournament.secsLeft        = secsLeft
                        tournament.receivedTimer   = GetGameTimer()
                    end

                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = 'openTournamentPanel',
                        data   = {
                            marketId          = marketId,
                            marketLabel       = mCfg.label or 'Mercado',
                            conquestId        = tournament.conquestId,
                            secsLeft          = secsLeft,
                            totalSecs         = tournament.secsLeft or secsLeft,
                            circuitName       = tournament.circuitName,
                            registeredCrews   = tournament.registeredCrews,
                            isRegistered      = tournament.isRegistered,
                            vehicleClassName  = tournament.vehicleClassName,
                            collisionsEnabled = tournament.collisionsEnabled,
                        }
                    })
                else
                    TriggerEvent('blackmarket:client:openMarketInfo', marketId)
                end
            end
        end
    end)
end

-- ========================================
-- FUNCIONES DE BLIP (por mercado)
-- ========================================

--[[ El color del mercado segun su estado.

     Antes esto era SetBlipColour con un numero de color de GTA. Ahora el punto
     vive en origen_map y el color viaja en hexadecimal, que es lo que entiende
     una interfaz web. Los tres estados son los mismos de siempre: en marcha,
     tomado por alguien, y en reposo.

     El parpadeo se pierde por el camino: en un mapa de Leaflet un punto que
     parpadea es ruido, y el rojo ya dice lo mismo sin moverse. ]]
local COLOR_ESTADO = {
    activo   = '#ff3355',   -- en marcha: el unico rojo del mapa
    tomado   = '#ffb020',   -- alguien lo tiene
    reposo   = '#ff8a2b',   -- el naranja de lo ilegal
}

function UpdateMarketBlip(marketId)
    local inst = MarketInstances[marketId]
    if not inst or not inst.blip then return end
    local mCfg = Config.Markets[marketId]
    if not mCfg or not mCfg.Blip then return end

    local state = MarketState[marketId] or {}
    local color = COLOR_ESTADO.reposo
    if state.active then
        color = COLOR_ESTADO.activo
    elseif state.owner then
        color = COLOR_ESTADO.tomado
    end

    OrigenMapa.Poner(inst.blip, {
        x = mCfg.Center.x, y = mCfg.Center.y, z = mCfg.Center.z,
        cat = 'illegal',
        nombre = mCfg.label or 'Mercado Negro',
        color = color,
    })
end

-- Legacy alias (por si hay código que llama CreateMarketBlip / CreateMarketNPC)
function CreateMarketBlip()  UpdateMarketBlip(1) end
function CreateMarketNPC()   end
function CreateDoorNPC()     end
function CreateCaptureZone() end

-- ========================================
-- INICIALIZACIÓN
-- ========================================

CreateThread(function()
    Wait(1000)
    -- config.lua ya no trae mercados: todos llegan del servidor con requestDynamicMarkets.
    for marketId, mCfg in pairs(Config.Markets) do
        mCfg = normalizeDynamicCfg(mCfg)
        Config.Markets[marketId] = mCfg
        setupMarket(marketId, mCfg)
    end
    -- Re-sincroniza mercados dinámicos al iniciar/reiniciar el recurso en el cliente.
    TriggerServerEvent('blackmarket:server:requestDynamicMarkets')

    -- Solicitar estado de todos los mercados
    for marketId in pairs(Config.Markets) do
        TriggerServerEvent('blackmarket:server:getState', marketId)
    end
    Config.DebugPrint('^2Black Market zones initialized (multi-market)^7')
end)

--[[ Vigilante de los NPC, por cercania.

     Antes recreaba los NPC de TODOS los mercados cada 15 s si faltaban,
     estuvieras donde estuvieras: diez peds fijos ocupando sitio en el pool de
     peds de GTA (256 para todo el servidor). Ahora cada NPC existe solo si
     tienes su sitio a menos de 80 m, y se borra al alejarte. Sigue sirviendo
     para lo de antes: si el juego se lo lleva estando cerca, vuelve. ]]
local DISTANCIA_NPC = 80.0

local function npcPorCercania(inst, campo, cfg, yo)
    if not cfg or not cfg.Coords then return end
    local cerca = #(yo - vector3(cfg.Coords.x, cfg.Coords.y, cfg.Coords.z)) <= DISTANCIA_NPC
    local ent = inst[campo]
    local existe = ent and DoesEntityExist(ent)
    if cerca and not existe then
        inst[campo] = spawnNPC(cfg)
    elseif not cerca and existe then
        DeleteEntity(ent)
        inst[campo] = nil
    elseif not existe then
        inst[campo] = nil
    end
end

CreateThread(function()
    while true do
        Wait(2000)
        for marketId, mCfg in pairs(Config.Markets) do
            local inst = MarketInstances[marketId]
            if not inst then
                mCfg = normalizeDynamicCfg(mCfg)
                Config.Markets[marketId] = mCfg
                setupMarket(marketId, mCfg)
            else
                local yo = GetEntityCoords(PlayerPedId())
                npcPorCercania(inst, 'npcEntity', mCfg.NPC, yo)
                npcPorCercania(inst, 'doorNpcEntity', mCfg.DoorNPC, yo)
            end
        end
    end
end)

-- ========================================
-- MERCADOS DINÁMICOS — añadir en caliente
-- ========================================

--- El servidor envía tablas planas (sin metatipo vector), las convertimos aquí.
normalizeDynamicCfg = function(cfg)
    if not cfg then return cfg end
    if cfg.Center and type(cfg.Center) == 'table' then
        cfg.Center = vector3(cfg.Center.x or 0, cfg.Center.y or 0, cfg.Center.z or 0)
    end
    if cfg.NPC and cfg.NPC.Coords and type(cfg.NPC.Coords) == 'table' then
        cfg.NPC.Coords = vector4(cfg.NPC.Coords.x or 0, cfg.NPC.Coords.y or 0,
                                  cfg.NPC.Coords.z or 0, cfg.NPC.Coords.w or 0)
    end
    if cfg.DoorNPC and cfg.DoorNPC.Coords and type(cfg.DoorNPC.Coords) == 'table' then
        cfg.DoorNPC.Coords = vector4(cfg.DoorNPC.Coords.x or 0, cfg.DoorNPC.Coords.y or 0,
                                      cfg.DoorNPC.Coords.z or 0, cfg.DoorNPC.Coords.w or 0)
    end
    return cfg
end

RegisterNetEvent('blackmarket:client:addMarket', function(marketId, marketCfg)
    marketId = tonumber(marketId)
    if not marketId or not marketCfg then return end

    -- Evitar duplicados si el jugador ya tiene esta zona (p.ej. reconexión)
    if MarketInstances[marketId] then return end

    marketCfg = normalizeDynamicCfg(marketCfg)
    Config.Markets[marketId] = marketCfg

    -- Inicializar estado del mercado en el cliente
    MarketState[marketId] = MarketState[marketId] or {
        active     = false,
        owner      = nil,
        ownerLabel = nil,
        isOwner    = false,
        protected  = false,
    }

    -- Crear zona, NPCs e interacciones
    setupMarket(marketId, marketCfg)

    -- Solicitar estado actualizado al servidor
    TriggerServerEvent('blackmarket:server:getState', marketId)
    Config.DebugPrint('[BlackMarket] Mercado dinámico añadido en caliente:', marketId, marketCfg.label)
end)

-- Eliminar un mercado dinámico en caliente (admin borró desde el panel)
RegisterNetEvent('blackmarket:client:removeMarket', function(marketId)
    marketId = tonumber(marketId)
    if not marketId then return end

    local inst = MarketInstances[marketId]
    if inst then
        if inst.blip          then OrigenMapa.Quitar(inst.blip)        end
        if inst.npcEntity     then DeleteEntity(inst.npcEntity)        end
        if inst.doorNpcEntity then DeleteEntity(inst.doorNpcEntity)    end
        if inst.zone          then inst.zone:remove()                  end
        MarketInstances[marketId] = nil
    end

    Config.Markets[marketId] = nil
    MarketState[marketId]    = nil
    InZoneMap[marketId]      = nil
    Config.DebugPrint('[BlackMarket] Mercado dinámico eliminado en caliente:', marketId)
end)

-- Actualizar posición/NPCs de un mercado dinámico en caliente
RegisterNetEvent('blackmarket:client:updateMarketWorld', function(marketId, marketCfg)
    marketId = tonumber(marketId)
    if not marketId or not marketCfg then return end

    -- Destruir instancia actual
    local inst = MarketInstances[marketId]
    if inst then
        if inst.blip          then OrigenMapa.Quitar(inst.blip)        end
        if inst.npcEntity     then DeleteEntity(inst.npcEntity)        end
        if inst.doorNpcEntity then DeleteEntity(inst.doorNpcEntity)    end
        if inst.zone          then inst.zone:remove()                  end
        MarketInstances[marketId] = nil
    end

    -- Reconstruir con la nueva config
    marketCfg = normalizeDynamicCfg(marketCfg)
    Config.Markets[marketId] = marketCfg

    MarketState[marketId] = MarketState[marketId] or {
        active = false, owner = nil, ownerLabel = nil, isOwner = false, protected = false,
    }
    setupMarket(marketId, marketCfg)
    TriggerServerEvent('blackmarket:server:getState', marketId)
    Config.DebugPrint('[BlackMarket] Mercado dinámico actualizado en caliente:', marketId, marketCfg.label)
end)

-- Limpiar al descargar recurso
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, inst in pairs(MarketInstances) do
        if inst.blip        then OrigenMapa.Quitar(inst.blip)      end
        if inst.npcEntity   then DeleteEntity(inst.npcEntity)      end
        if inst.doorNpcEntity then DeleteEntity(inst.doorNpcEntity) end
        if inst.zone        then inst.zone:remove()                end
    end
    MarketInstances = {}
    SetNuiFocus(false, false)
end)
