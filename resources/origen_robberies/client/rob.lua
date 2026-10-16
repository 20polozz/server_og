Robberies = {}
Robberies.__index = Robberies
Robberies.table = {}

local _pendingMinigameCallback = nil

-- Todas las notificaciones del script llevan el título "Atracos"
local _libNotify = lib.notify
lib.notify = function(opts)
    if type(opts) == 'table' then
        opts.title = 'Atracos'
    end
    return _libNotify(opts)
end

local function maybeConsumeItem(item, shouldConsume, chance)
    if item and item ~= '' and shouldConsume then
        if math.random(100) <= (tonumber(chance) or 100) then
            TriggerServerEvent('origen_robberies:consumeMinigameItem', item)
        end
    end
end

AddEventHandler('origen_minijuegos:gameResult', function(success)
    if _pendingMinigameCallback then
        local cb = _pendingMinigameCallback
        _pendingMinigameCallback = nil
        cb(success)
    end
end)

function Robberies:trackAndGiveItems(items)
    if not self.robbedItems then self.robbedItems = {} end
    for _, item in ipairs(items) do
        table.insert(self.robbedItems, item)
    end
    -- Pasamos self.id para que el servidor añada metadata robberyId a cada item
    TriggerServerEvent('origen_robberies:giveItems', items, self.id)
end

function Robberies:handleZoneExit()
    SendNUIMessage({
        action = 'showHudTimer',
        data = {
            visible = false
        }
    })

    -- Doble guardia: flag propio + estado oficial del servidor
    if not self.robberyActive then return end
    if LocalPlayer.state.activeRobbery ~= self.id then
        self.robberyActive = false
        return
    end

    self.robberyActive = false

    -- Limpieza con protección ante errores (puntos ya removidos, etc.)
    pcall(function()
        if self.start and self.start.point then
            self.start.point.busy = false
        end
    end)

    for _, point in pairs(self.interactions or {}) do
        pcall(function() point:remove() end)
    end

    pcall(function()
        if self.bag and DoesEntityExist(self.bag) then
            DeleteEntity(self.bag)
        end
    end)

    LocalPlayer.state:set('activeRobbery', nil, true)

    if self.robberyTimerDone then
        TriggerServerEvent('origen_robberies:updateStats', self.id, 'completed')
    else
        if self.robbedItems and #self.robbedItems > 0 then
            -- Enviamos robberyId + coords + radio; el server busca por metadata
            -- en el ladrón Y en jugadores cercanos dentro de la zona
            local robCoords = { x = self.start.coords.x, y = self.start.coords.y, z = self.start.coords.z }
            local robRadius = self.safeZoneRadius or ((self.radius or 30.0) + 15.0)
            TriggerServerEvent('origen_robberies:stripRobbedItems', self.id, robCoords, robRadius)
        end
        lib.notify({
            description = 'Has abandonado el robo antes de tiempo. Has perdido todo lo que habías robado.',
            type = 'error',
            duration = 8000
        })
        TriggerServerEvent('origen_robberies:updateStats', self.id, 'failed')
    end

    pcall(function()
        TriggerServerEvent('origen_robberies:server:SyncPedAnim', vector3(self.start.coords.x, self.start.coords.y, self.start.coords.z), false)
    end)
end

function Robberies:startRobberyTimer()
    self.robberyTimerDone = false
    self.robberyActive = true
    self.robbedItems = {}

    local robId       = self.id
    local startCoords = vector3(self.start.coords.x, self.start.coords.y, self.start.coords.z)
    local zoneRadius  = self.safeZoneRadius or ((self.radius or 30.0) + 15.0)

    -- Hilo de monitoreo principal: usa el estado oficial activeRobbery
    -- y PlayerPedId() directo para evitar problemas con caché
    Citizen.CreateThread(function()
        local timeout = 0
        while LocalPlayer.state.activeRobbery ~= robId and timeout < 20 do
            Citizen.Wait(100)
            timeout = timeout + 1
        end

        while self.robberyActive do
            Citizen.Wait(500)
            if not self.robberyActive then break end
            if LocalPlayer.state.activeRobbery ~= robId then break end
            local ped  = PlayerPedId()
            local dist = #(GetEntityCoords(ped) - startCoords)
            if dist > zoneRadius then
                self:handleZoneExit()
                break
            end
        end
    end)

    -- Cuenta regresiva de espera con actualización de HUD
    Citizen.CreateThread(function()
        local timeout = 0
        while LocalPlayer.state.activeRobbery ~= robId and timeout < 20 do
            Citizen.Wait(100)
            timeout = timeout + 1
        end

        local waitMinutes = self.start.signalWaitTime or 0
        -- Retrocompatibilidad: Si es tienda y signalWaitTime no está definido, poner 5
        if self.start.isShop and self.start.signalWaitTime == nil then
            waitMinutes = 5
        end
        local totalSeconds = math.floor(waitMinutes * 60)
        
        -- Mostrar HUD si hay escape habilitado y hay tiempo de espera
        local showHud = (totalSeconds > 0) and self.escape and self.escape.enabled
        if showHud then
            SendNUIMessage({
                action = 'showHudTimer',
                data = {
                    visible = true,
                    timeLeft = totalSeconds,
                    statusText = 'ESPERANDO SEÑAL'
                }
            })
        end

        while totalSeconds > 0 and self.robberyActive do
            Citizen.Wait(1000)
            if not self.robberyActive or LocalPlayer.state.activeRobbery ~= robId then break end
            totalSeconds = totalSeconds - 1
            if showHud then
                SendNUIMessage({
                    action = 'updateHudTimer',
                    data = {
                        timeLeft = totalSeconds
                    }
                })
            end
        end

        if showHud then
            SendNUIMessage({
                action = 'showHudTimer',
                data = {
                    visible = false
                }
            })
        end

        if LocalPlayer.state.activeRobbery == robId and self.robberyActive then
            self.robberyTimerDone = true

            local isEscape = self.escape and self.escape.enabled

            if isEscape then
                if self.escapeReady then
                    self.robberyActive = false
                    local message = self.escape.message or '¡El escape ha comenzado! Dirígete a la zona segura. Tienes {time} minutos.'
                    message = message:gsub('{time}', tostring(self.escape.timeLimit or 30))
                    lib.notify({ description = message, type = 'success' })
                    self:escapePoint()
                else
                    if totalSeconds > 0 then
                        lib.notify({
                            title = '¡Tiempo de robo completado!',
                            description = '¡Ya puedes salir de la zona con tu botín!',
                            type = 'success',
                            duration = 8000
                        })
                    end
                end
            elseif totalSeconds > 0 then
                lib.notify({
                    title = '¡Tiempo de robo completado!',
                    description = '¡Ya puedes salir de la zona con tu botín!',
                    type = 'success',
                    duration = 8000
                })
            end
        end
    end)
end

function Robberies.new(data)
    if not data.active then return end

    local existing = Robberies.table[data.id]
    if existing then
        existing:update(data)
        return existing
    end
    
    local self = setmetatable({}, Robberies)

    self.id = data.id
    self.name = data.name
    self.radius = data.radius
    self.start = data.start

    if not data.start then
        return
    end

    self.weaponRestrictions = data.weaponRestrictions or {}
    self.lootPoints = data.lootPoints or {}
    self.interactions = {}
    self.safe = data.safe or {
        enabled = false
    }
    self.guards = data.guards or {
        enabled = false
    }
    self.escape = data.escape or {
        enabled = false
    }
    self.steps = self.start.isShop and 1 or (#self.lootPoints + (self.safe.enabled and 1 or 0))
    
    Robberies.table[self.id] = self

    if self.start.type == 'npc' then
        self:createNpc()
    else
        self:createProp()
    end

    if self.safe.enabled then
        self:spawnSafe()
    end

    self:createSafeZone()

    return self
end

function Robberies.get(id)
    return Robberies.table[id]
end

function Robberies:shopAnimation()
    Citizen.CreateThread(function()
        Citizen.Wait(10800)

        lib.requestModel('prop_poly_bag_01')
        self.bag = CreateObjectNoOffset('prop_poly_bag_01', GetEntityCoords(self.start.entity), true, true)
        AttachEntityToEntity(self.bag, self.start.entity, GetPedBoneIndex(self.start.entity, 60309), 0.1, -0.11, 0.08, 0.0, -75.0, -75.0, 1, 1, 0, 0, 2, 1)

        Citizen.Wait(10000)

        DetachEntity(self.bag, 1, 1)
        ApplyForceToEntity(self.bag, 3, vector3(0.0, 50.0, 0.0), 0.0, 0.0, 0.0, 0, true, true, false, false, true)
        SetModelAsNoLongerNeeded('prop_poly_bag_01')

        self:addMoneyBag()
    end)
end

function Robberies:addMoneyBag()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5)
            if DoesEntityExist(self.bag) then
                if #(GetEntityCoords(cache.ped) - GetEntityCoords(self.bag)) <= 1.5 then
                    PlaySoundFrontend(-1, 'ROBBERY_MONEY_TOTAL', 'HUD_FRONTEND_CUSTOM_SOUNDSET', true)
                    NetworkRequestControlOfEntity(self.bag)
                    local timeout = 0
                    while not NetworkHasControlOfEntity(self.bag) and timeout < 10 do
                        Citizen.Wait(1000)
                        NetworkRequestControlOfEntity(self.bag)
                        timeout = timeout + 1
                    end
                    DeleteEntity(self.bag)
                    self:removeStep()
                    self:trackAndGiveItems(self.getRandomLoot(self.start.items))
                    break
                end
            else
                break
            end
        end
    end)
end

function Robberies:createSafeZone()
    local maxDistance = 30.0
    local startCoords = vector3(self.start.coords.x, self.start.coords.y, self.start.coords.z)

    for _, lootPoint in pairs(self.lootPoints) do
        local lootCoords = vector3(lootPoint.coords.x, lootPoint.coords.y, lootPoint.coords.z)
        local distance = #(startCoords - lootCoords)
        if distance > maxDistance then
            maxDistance = distance
        end
    end

    if self.safe.enabled and self.safe.coords then
        local safeCoords = vector3(self.safe.coords.x, self.safe.coords.y, self.safe.coords.z)
        local distance = #(startCoords - safeCoords)
        if distance > maxDistance then
            maxDistance = distance
        end
    end

    local safeRadius = maxDistance + 15.0

    if self.radius and self.radius > safeRadius then
        safeRadius = self.radius
    end

    self.safeZoneRadius = safeRadius

    self.safeZone = lib.zones.sphere({
        coords = startCoords,
        radius = safeRadius,
        debug = false,
        onExit = function()
            if self.start.isShop then
                -- Tiendas: limpieza original sin timer
                if self.start.point.busy then
                    self.start.point.busy = false
                    for _, point in pairs(self.interactions) do
                        point:remove()
                    end
                    if self.bag and DoesEntityExist(self.bag) then
                        DeleteEntity(self.bag)
                    end
                    TriggerServerEvent('origen_robberies:server:SyncPedAnim', vector3(self.start.coords.x, self.start.coords.y, self.start.coords.z), false)
                end
            else
                -- Robos normales: tanto onExit como el hilo de monitoreo
                -- llaman handleZoneExit; el guard interno evita doble ejecución
                if self.robberyActive and LocalPlayer.state.activeRobbery == self.id then
                    self:handleZoneExit()
                end
            end
        end
    })
end

--[[ El dependiente, solo cuando hay alguien cerca.

     Antes se creaban los de TODAS las tiendas nada mas entrar, estuvieras
     donde estuvieras: 48 peds fijos de los 256 que tiene GTA para todo
     (trafico, peatones y los NPC de cada recurso). Ahora aparece a 80 m y se
     va al alejarte, como los NPC de misiones. A esa distancia ya esta ahi
     mucho antes de que puedas verlo o apuntarle. ]]
local DISTANCIA_DEPENDIENTE = 80.0

--- Un robo sin modelo configurado no se monta: sin esto lib.requestModel
--- reventaba con "got nil" al entrar, y el robo se quedaba a medias.
--- Tiene que ir ANTES de spawnStartPed: un local solo lo ven las funciones
--- escritas debajo; las de arriba buscan un global que no existe.
local function sinModelo(self, que, modelo)
    if modelo and modelo ~= '' then return false end
    print(('^3[origen_robberies]^7 el robo %s (%s) no tiene modelo de %s: revisalo en el panel'):format(
        tostring(self.id), tostring(self.name), que))
    return true
end

function Robberies:spawnStartPed()
    if self.start.entity and DoesEntityExist(self.start.entity) then return end
    if sinModelo(self, 'dependiente', self.start.model) then return end
    -- Un nombre mal escrito en el panel hace que lib.requestModel lance un
    -- error; mejor avisar y seguir.
    if not IsModelInCdimage(joaat(self.start.model)) then
        print(('^3[origen_robberies]^7 el robo %s (%s): el modelo "%s" no existe en el juego'):format(
            tostring(self.id), tostring(self.name), tostring(self.start.model)))
        return
    end
    lib.requestModel(self.start.model)

    local ped = CreatePed(4, self.start.model, self.start.coords.x, self.start.coords.y, self.start.coords.z - 1, self.start.coords.w + 0.0, false, true)
    SetEntityHeading(ped, self.start.coords.w + 0.0)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    SetPedConfigFlag(ped, 79, true)
    SetPedConfigFlag(ped, 80, true)
    SetModelAsNoLongerNeeded(self.start.model)
    self.start.entity = ped
end

function Robberies:despawnStartPed()
    -- En pleno robo no se toca: la bolsa va pegada a el.
    if self.robberyActive then return end
    if self.start.entity and DoesEntityExist(self.start.entity) then
        DeleteEntity(self.start.entity)
    end
    self.start.entity = nil
end

function Robberies:createNpc()
    local robbery = self
    self.start.spawnPoint = lib.points.new({
        coords = self.start.coords,
        distance = DISTANCIA_DEPENDIENTE,
    })
    --[[ Con pcall, y no es adorno. onEnter y onExit corren DENTRO del bucle
         de lib.points, que es uno solo para todos los puntos del recurso: un
         error en un robo (un modelo que no carga, un nil) mata ese bucle y a
         partir de ahi no aparece ningun dependiente en todo el mapa. Asi paso
         con sinModelo declarado debajo de spawnStartPed. ]]
    function self.start.spawnPoint:onEnter()
        local ok, err = pcall(robbery.spawnStartPed, robbery)
        if not ok then print(('^1[origen_robberies]^7 no se pudo crear el dependiente del robo %s: %s'):format(tostring(robbery.id), tostring(err))) end
    end
    function self.start.spawnPoint:onExit()
        local ok, err = pcall(robbery.despawnStartPed, robbery)
        if not ok then print(('^1[origen_robberies]^7 no se pudo quitar el dependiente del robo %s: %s'):format(tostring(robbery.id), tostring(err))) end
    end

    self.start.point = lib.points.new({
        coords = self.start.coords,
        distance = 3,
        wait = 1000,
        busy = false
    })

    self.start.point.nearby = function()
        if self.start.point.busy then
            return
        end

        local isAiming, aimedEntity = GetEntityPlayerIsFreeAimingAt(cache.playerId)
        local isMelee, meleeEntity = GetPlayerTargetEntity(cache.playerId)
        
        if isAiming and aimedEntity == self.start.entity or isMelee and meleeEntity == self.start.entity then
            if #self.weaponRestrictions > 0 then
                cache.weapon = cache.weapon or GetSelectedPedWeapon(cache.ped)
                local weaponType = GetWeapontypeGroup(cache.weapon)
                if not lib.table.contains(self.weaponRestrictions, tostring(weaponType)) then
                    lib.notify({
                        description = '¿Crees que con eso me intimidarás?',
                        type = 'error'
                    })
                    self.start.point.wait = 5000
                    goto continue
                end
            end

            if self.start.requiredItem and self.start.requiredItem ~= '' then
                local hasItem = exports.origen_inventory:HasItem(self.start.requiredItem, 1)
                if not hasItem then
                    lib.notify({
                        description = 'Parece que te falta algo para iniciar el robo',
                        type = 'error'
                    })
                    self.start.point.wait = 5000
                    goto continue
                end
            end

            if LocalPlayer.state.activeRobbery then
                lib.notify({
                    description = 'Ya estás participando en un robo',
                    type = 'error'
                })
                self.start.point.wait = 5000    
                goto continue
            end

            local canRob, message = lib.callback.await('origen_robberies:tryRob', false, self.id)

            if not canRob then
                lib.notify({
                    description = message,
                    type = 'error'
                })
                self.start.point.wait = 5000    
                goto continue
            else
                self.start.point.wait = 1000
                self.start.point.busy = true

                local mg = self.start.startMinigame

                if mg and mg.enabled and mg.name and mg.name ~= 'none' then
                    local minigame = Config.Minigames[mg.name]

                    if minigame then
                        if mg.requiredItem and mg.requiredItem ~= '' then
                            if not exports.origen_inventory:HasItem(mg.requiredItem, 1) then
                                lib.notify({
                                    description = 'No tienes el objeto requerido para el minijuego de inicio',
                                    type = 'error'
                                })
                                self.start.point.busy = false
                                self.start.point.wait = 5000
                                goto continue
                            end
                        end
                        local difficulty = (mg.parameters and mg.parameters[1]) or 'medium'
                        _pendingMinigameCallback = function(success)
                            if not success then
                                lib.notify({
                                    description = 'No has logrado superar el minijuego para iniciar el robo',
                                    type = 'error'
                                })
                                maybeConsumeItem(mg.requiredItem, mg.consumeOnFail, mg.consumeOnFailChance)
                                self.start.point.busy = false
                                return
                            end
                            maybeConsumeItem(mg.requiredItem, mg.consumeOnSuccess, mg.consumeOnSuccessChance)
                            TriggerServerEvent('origen_robberies:confirmStart', self.id)
                            if self.start.isShop then self:shopAnimation() end
                            if self.guards.enabled then self:spawnGuards() end
                            self:setLootPoints()
                        end
                        TriggerEvent('origen_minijuegos:startGame', mg.name, difficulty, mg.parameters and mg.parameters[2])
                        goto continue
                    end
                end

                if self.start.isShop then self:shopAnimation() end
                if self.guards.enabled then self:spawnGuards() end
                self:setLootPoints()
            end
        end
        ::continue::
        Wait(self.start.point.wait)
        self.start.point.wait = 1000
    end
end

function Robberies:escapePoint(timeLeftMs)
    if not self.escape or not self.escape.enabled then return end
    if not self.escape.points or #self.escape.points == 0 then
        lib.notify({
            description = 'Este atraco no tiene una salida preparada. Avisa a un administrador.',
            type = 'error'
        })
        return
    end

    if not timeLeftMs then
        TriggerServerEvent('origen_robberies:startEscapeServer', self.id)
    end
    
    lib.requestModel(self.escape.npcModel)
    local randomIndex = math.random(1, #self.escape.points)
    local coords = self.escape.points[randomIndex]
    if not coords then return end

    self.escape.entity = CreatePed(4, self.escape.npcModel, coords.x, coords.y, coords.z - 1, coords.w + 0.0, false, true)
    SetEntityHeading(self.escape.entity, coords.w + 0.0)
    FreezeEntityPosition(self.escape.entity, true)
    SetBlockingOfNonTemporaryEvents(self.escape.entity, true)
    SetEntityInvincible(self.escape.entity, true)
    SetPedConfigFlag(self.escape.entity, 79, true)
    SetPedConfigFlag(self.escape.entity, 80, true)
    SetModelAsNoLongerNeeded(self.escape.npcModel)

    --[[ El punto de entrega, en el mapa.

         Ya no es un blip del juego: es un punto de origen_map. Lleva
         `ruta = true`, que es lo unico para lo que aun se crea un blip por
         debajo —invisible— porque GTA solo sabe trazar un camino por carretera
         hasta un blip, y ese trazado es justo lo que el mapa dibuja.

         Y prioridad alta: es el sitio al que hay que llegar ahora mismo, asi
         que el corte por distancia del minimapa no puede comerselo. ]]
    self.escapeBlip = 'entrega_' .. tostring(self.id or 'actual')

    OrigenMapa.Poner(self.escapeBlip, {
        x = coords.x, y = coords.y, z = coords.z,
        cat = 'illegal',
        icono = 'paquete',
        nombre = 'Punto de entrega',
        color = '#d81b55',
        ruta = true,
        prioridad = 10,
    })

    self.escape.startTime = GetGameTimer()
    self.escape.limitMs = timeLeftMs or ((self.escape.timeLimit or 30) * 60 * 1000)
    self:monitorEscape()

    self.escape.point = lib.points.new({
        coords = coords,
        distance = 4.0,
        wait = 0,
        busy = false
    })

    self.escape.point.onEnter = function()
        lib.showTextUI('[E] Hablar con el contacto')
    end

    self.escape.point.onExit = function()
        self.escape.avisoPolicia = false
        lib.hideTextUI()
    end

    self.escape.point.nearby = function()
        if self.escape.point.busy then return end

        local policeNear = HasPoliceNearby(150.0)

        --[[ Con policía cerca no hay tecla que pulsar: el aviso de acción
             (origen_notify:DrawText) siempre pinta una tecla, y los códigos
             ~r~/~n~ de GTA salían tal cual. Se quita el aviso y se dice una
             vez, con una notificación; vuelve la tecla cuando se van. ]]
        if policeNear then
            if not self.escape.avisoPolicia then
                self.escape.avisoPolicia = true
                lib.hideTextUI()
                lib.notify({
                    description = 'Hay policía cerca. Espera a que se alejen para entregar.',
                    type = 'error'
                })
            end
        else
            self.escape.avisoPolicia = false
            lib.showTextUI('[E] Hablar con el contacto')
        end

        if not policeNear and IsControlJustReleased(0, 38) then
            self.escape.point.busy = true
            local filteredReq, rewardItems = BuildPanelData(self.id)
            SendNUIMessage({
                action = 'showEscapePanel',
                data = {
                    requiredItems = filteredReq,
                    rewardItems   = rewardItems,
                    robId         = self.id
                }
            })
            SetNuiFocus(true, true)
            lib.hideTextUI()
        end

        self.escape.point.wait = 0
    end
end

function Robberies:monitorEscape()
    if self.escape.active then
        self.escape.active = false
        Citizen.Wait(100)
    end

    self.escape.active = true
    self.escape.notified50 = false
    self.escape.notified25 = false

    local totalSeconds = math.max(0, math.floor(self.escape.limitMs / 1000))
    SendNUIMessage({
        action = 'showHudTimer',
        data = {
            visible = true,
            timeLeft = totalSeconds,
            statusText = 'TIEMPO DE HUIDA'
        }
    })

    Citizen.CreateThread(function()
        while self.escape.active do
            Citizen.Wait(1000)
            if not self.escape.active then break end

            if not self.escape.startTime or not self.escape.limitMs then break end

            local elapsed = GetGameTimer() - self.escape.startTime
            local remaining = self.escape.limitMs - elapsed
            local percent = (remaining / self.escape.limitMs) * 100
            local remSeconds = math.max(0, math.floor(remaining / 1000))

            SendNUIMessage({
                action = 'updateHudTimer',
                data = {
                    timeLeft = remSeconds
                }
            })

            if remaining <= 0 then
                SendNUIMessage({
                    action = 'showHudTimer',
                    data = {
                        visible = false
                    }
                })

                lib.notify({
                    description = 'El punto de entrega ha expirado. El atraco ha fallado.',
                    type = 'error',
                    duration = 5000
                })

                LocalPlayer.state:set('activeRobbery', nil, true)
                self:removeEscape()
                TriggerServerEvent('origen_robberies:updateStats', self.id, 'failed')
                break
            end

            if percent <= 50 and not self.escape.notified50 then
                local mins = math.ceil(remaining / 60000)
                lib.notify({
                    description = 'Quedan ' .. mins .. ' minutos para llegar al punto de entrega',
                    type = 'warning',
                    duration = 4000
                })
                self.escape.notified50 = true
            elseif percent <= 25 and not self.escape.notified25 then
                local mins = math.ceil(remaining / 60000)
                lib.notify({
                    description = 'Quedan ' .. mins .. ' minutos para llegar al punto de entrega',
                    type = 'error',
                    duration = 5000
                })
                self.escape.notified25 = true
            end
        end

        SendNUIMessage({
            action = 'showHudTimer',
            data = {
                visible = false
            }
        })
    end)
end

LocalPlayer.state:set('activeRobbery', nil, true)

function Robberies:createProp()
    if sinModelo(self, 'inicio', self.start.model) then return end
    lib.requestModel(self.start.model)

    self.start.entity = CreateObjectNoOffset(self.start.model, self.start.coords.x, self.start.coords.y, self.start.coords.z + 0.0, false, true, false)
    SetEntityHeading(self.start.entity, self.start.coords.w )
    FreezeEntityPosition(self.start.entity, true)
    SetEntityInvincible(self.start.entity, true)
    SetModelAsNoLongerNeeded(self.start.model)

    self.start.point = lib.points.new({
        coords = self.start.coords,
        distance = 1.5,
        wait = 0,
        busy = false
    })

    self.start.point.onEnter = function()
        if self.start.point.busy then return end
        lib.showTextUI('[E] Empezar el atraco')
    end

    self.start.point.onExit = function()
        lib.hideTextUI()
    end

    self.start.point.nearby = function()
        if self.start.point.busy then return end

        if IsControlJustReleased(0, 38) then -- E
            if LocalPlayer.state.activeRobbery then
                lib.notify({
                    description = 'Ya estás participando en un robo',
                    type = 'error'
                })
                self.start.point.wait = 5000
                goto continue
            end

            local canRob, message = lib.callback.await('origen_robberies:tryRob', false, self.id)

            if not canRob then
                self.start.point.wait = 5000
                lib.notify({
                    description = message,
                    type = 'error'
                })
            else
                self.start.point.busy = true
                lib.hideTextUI()

                local mg = self.start.startMinigame

                if mg and mg.enabled and mg.name and mg.name ~= 'none' then
                    local minigame = Config.Minigames[mg.name]

                    if minigame then
                        if mg.requiredItem and mg.requiredItem ~= '' then
                            if not exports.origen_inventory:HasItem(mg.requiredItem, 1) then
                                lib.notify({
                                    description = 'No tienes el objeto requerido para el minijuego de inicio',
                                    type = 'error'
                                })
                                self.start.point.busy = false
                                goto continue
                            end
                        end
                        local difficulty = (mg.parameters and mg.parameters[1]) or 'medium'

                        _pendingMinigameCallback = function(success)
                            if not success then
                                lib.notify({
                                    description = 'No has logrado superar el minijuego para iniciar el robo',
                                    type = 'error'
                                })
                                maybeConsumeItem(mg.requiredItem, mg.consumeOnFail, mg.consumeOnFailChance)
                                self.start.point.busy = false
                                return
                            end
                            maybeConsumeItem(mg.requiredItem, mg.consumeOnSuccess, mg.consumeOnSuccessChance)
                            TriggerServerEvent('origen_robberies:confirmStart', self.id)
                            lib.notify({
                                description = 'Has iniciado el robo, ¡rápido, busca el botín!',
                                type = 'success'
                            })
                            if self.guards.enabled then self:spawnGuards() end
                            self:setLootPoints()
                            -- Entregar items de inicio del prop
                            if self.start.items and #self.start.items > 0 then
                                self:trackAndGiveItems(Robberies.getRandomLoot(self.start.items))
                            end
                        end
                        TriggerEvent('origen_minijuegos:startGame', mg.name, difficulty, mg.parameters and mg.parameters[2])
                        goto continue
                    end
                end

                TriggerServerEvent('origen_robberies:confirmStart', self.id)
                lib.notify({
                    description = 'Has iniciado el robo, ¡rápido, busca el botín!',
                    type = 'success'
                })
                if self.guards.enabled then self:spawnGuards() end
                self:setLootPoints()
                -- Entregar items de inicio del prop
                if self.start.items and #self.start.items > 0 then
                    self:trackAndGiveItems(Robberies.getRandomLoot(self.start.items))
                end
            end
            lib.hideTextUI()
        end
        ::continue::
        Wait(self.start.point.wait)
        if not self.start.point.busy and self.start.point.currentDistance and self.start.point.distance and self.start.point.currentDistance <= self.start.point.distance then
            lib.showTextUI('[E] Empezar el atraco')
        end

        self.start.point.wait = 0
    end
end

function Robberies.getRandomLoot(items)
    local loot = {}
    for _, item in ipairs(items) do
        if math.random(100) <= item.chance then
            local amount = math.random(item.amount.min, item.amount.max)
            table.insert(loot, { name = item.name, amount = amount })
        end
    end
    return loot
end

function Robberies:spawnSafe()
    if self.safe.enabled and not sinModelo(self, 'caja fuerte', self.safe.model) then
        lib.requestModel(self.safe.model)
        self.safe.entity = CreateObjectNoOffset(self.safe.model, self.safe.coords.x, self.safe.coords.y, self.safe.coords.z + 0.0, false, true, false)
        SetEntityHeading(self.safe.entity, self.safe.coords.w + 0.0)
        FreezeEntityPosition(self.safe.entity, true)
        SetEntityInvincible(self.safe.entity, true)
        SetModelAsNoLongerNeeded(self.safe.model)
    end
end

function Robberies:spawnGuards()
    lib.notify({
        description = self.guards.message or 'Los guardias han sido alertados y están en camino',
        type = 'success'
    })

    Citizen.CreateThread(function()
        Wait(self.guards.delay * 1000)
        self.guards.entities = {}
        self.guards.lootPoints = {}

        for i = 1, self.guards.amount do
            local guardModel = self.guards.model or 's_m_y_cop_01'
            lib.requestModel(guardModel)

            local coords = self.guards.coords[i] or {
                x = self.start.coords.x + math.random(-5, 5),
                y = self.start.coords.y + math.random(-5, 5),
                z = self.start.coords.z,
                w = self.start.coords.w
            }

            local guard = CreatePed(4, guardModel, coords.x, coords.y, coords.z, coords.w, true, true)
            SetEntityHeading(guard, coords.w)

            if self.guards.weapon and self.guards.weapon ~= '' then
                GiveWeaponToPed(guard, GetHashKey(self.guards.weapon), 0, false, false)
                SetCurrentPedWeapon(guard, GetHashKey(self.guards.weapon), true)
            end

            SetPedRelationshipGroupHash(guard, GetHashKey("EvilNPCs"))
            SetCanAttackFriendly(guard, false, false)

            TaskGoToEntity(guard, cache.ped, -1, 0.0, 500.0, 1073741824, 0)

            SetModelAsNoLongerNeeded(guardModel)

            table.insert(self.guards.entities, guard)
        end

        if self.guards.loot.enabled then
            self:setupGuardLoot()
        end
    end)
end

function Robberies:setupGuardLoot()
    Citizen.CreateThread(function()
        while self.start.point.busy and #self.guards.entities > 0 do
            Wait(500)
            
            for i, guard in ipairs(self.guards.entities) do
                local netId = NetworkGetNetworkIdFromEntity(guard)
                if DoesEntityExist(guard) then
                    local guardCoords = GetEntityCoords(guard)
                    
                    if not self.guards.lootPoints[netId] then
                        self.guards.lootPoints[netId] = lib.points.new({
                            coords = guardCoords,
                            distance = 2.0,
                            guardEntity = guard,
                            looted = false,
                            robbery = self
                        })

                        local point = self.guards.lootPoints[netId]

                        point.onEnter = function()
                            if IsEntityDead(point.guardEntity) and not point.looted then
                                lib.showTextUI('[E] Registrar cuerpo')
                            end
                        end

                        point.onExit = function()
                            lib.hideTextUI()
                        end

                        point.nearby = function()
                            if IsEntityDead(point.guardEntity) and not point.looted then
                                if IsControlJustReleased(0, 38) then -- E
                                    point.looted = true
                                    lib.hideTextUI()
                                    
                                    if not LocalPlayer.state.crouch then
                                        ExecuteCommand('+agacharseogn')
                                    end
                                    
                                    lib.progressBar({
                                        duration = 5000,
                                        label = "Registrando…",
                                        disable = {
                                            move = true,
                                            combat = true,
                                        },
                                        anim = {
                                            dict = "anim@gangops@facility@servers@bodysearch@",
                                            clip = "player_search",
                                            flag = 49
                                        },
                                    })

                                    local items = Robberies.getRandomLoot(point.robbery.guards.loot.items or {})
                                    if #items > 0 then
                                        point.robbery:trackAndGiveItems(items)
                                    else
                                        lib.notify({
                                            description = 'No has encontrado nada de valor',
                                            type = 'error'
                                        })
                                    end

                                    point:remove()
                                    if DoesEntityExist(point.guardEntity) then
                                        DeleteEntity(point.guardEntity)
                                    end
                                    self.guards.entities[i] = nil
                                end
                            end
                        end
                    else
                        self.guards.lootPoints[netId].coords = guardCoords
                    end
                else
                    if self.guards.lootPoints[netId] then
                        self.guards.lootPoints[netId]:remove()
                        self.guards.lootPoints[netId] = nil
                    end

                    self.guards.entities[i] = nil
                end
            end
        end
        
        for _, point in pairs(self.guards.lootPoints) do
            if point.remove then
                point:remove()
            end
        end
        self.guards.lootPoints = {}
    end)
end

function Robberies:setLootPoints()
    self:startRobberyTimer()

    for i, lootPoint in pairs(self.lootPoints) do
        if GetResourceState('origen_anims') == 'started' and lootPoint.anim and lootPoint.anim.id and lootPoint.anim.id ~= '' then
            local _, fetched = exports.origen_anims:getEmoteByCommand(lootPoint.anim.id)
            anim = fetched
        end
        
        local point = lib.points.new({
            coords = vector3(lootPoint.coords.x, lootPoint.coords.y, lootPoint.coords.z),
            distance = 2.0,
            wait = 0,
            busy = false,
            index = i,
            lootData = lootPoint
        })

        point.onEnter = function()
            lib.showTextUI('[E] Buscar')
        end

        point.onExit = function()
            lib.hideTextUI()
        end

        point.nearby = function()
            if point.busy then
                return
            end

            DrawMarker(22, point.coords.x, point.coords.y, point.coords.z + 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 200, false, true, 2, nil, nil, false)

            if IsControlJustReleased(0, 38) then -- E
                point.busy = true
                lib.hideTextUI()

                local function completeLoot()
                    lib.progressBar({
                        duration = (point.lootData.anim.duration * 1000) or 5000,
                        label = "Buscando…",
                        disable = {
                            move = true,
                            combat = true,
                        },
                        anim = anim and {
                            dict = anim.Dictionary,
                            clip = anim.Animation,
                            flag = tonumber(point.lootData.anim.flags) or 49,
                        } or nil,
                    })

                    local items = Robberies.getRandomLoot(point.lootData.items)

                    if #items > 0 then
                        self:trackAndGiveItems(items)
                    else
                        lib.notify({
                            description = 'No has encontrado nada de valor',
                            type = 'error'
                        })
                    end

                    if not self.start.isShop then
                        self:removeStep()
                    end
                    point:remove()
                end

                local mg = point.lootData.minigame
                if mg and mg.enabled and mg.name and mg.name ~= 'none' then
                    local minigame = Config.Minigames[mg.name]
                    if not minigame then
                        completeLoot()
                        return
                    end

                    if mg.requiredItem and mg.requiredItem ~= '' then
                        local hasItem = exports.origen_inventory:HasItem(mg.requiredItem, 1)
                        if not hasItem then
                            lib.notify({
                                description = 'No tienes el objeto necesario para acceder a este botín',
                                type = 'error'
                            })
                            point.busy = false
                            if point.currentDistance <= point.distance then
                                lib.showTextUI('[E] Buscar')
                            end
                            return
                        end
                    end

                    local difficulty = (mg.parameters and mg.parameters[1]) or 'medium'
                    _pendingMinigameCallback = function(success)
                        if not success then
                            lib.notify({
                                description = 'No has logrado encontrar el botín',
                                type = 'error'
                            })
                            maybeConsumeItem(mg.requiredItem, mg.consumeOnFail, mg.consumeOnFailChance)
                            -- Permitir reintentar en lugar de eliminar el punto
                            point.busy = false
                            if point.currentDistance <= point.distance then
                                lib.showTextUI('[E] Buscar')
                            end
                            return
                        end
                        maybeConsumeItem(mg.requiredItem, mg.consumeOnSuccess, mg.consumeOnSuccessChance)
                        completeLoot()
                    end
                    TriggerEvent('origen_minijuegos:startGame', mg.name, difficulty, mg.parameters and mg.parameters[2])
                else
                    completeLoot()
                end
            end

            point.wait = 0
        end

        self.interactions[i] = point
    end

    if self.safe.enabled then
        local safePoint = lib.points.new({
            coords = vector3(self.safe.coords.x, self.safe.coords.y, self.safe.coords.z),
            distance = 1.5,
            wait = 0,
            busy = false
        })

        safePoint.onEnter = function()
            lib.showTextUI('[E] Abrir caja fuerte')
        end

        safePoint.onExit = function()
            lib.hideTextUI()
        end

        safePoint.nearby = function()
            if safePoint.busy then
                return
            end

            if IsControlJustReleased(0, 38) then -- E
                safePoint.busy = true
                lib.hideTextUI()
                
                local function completeSafe()
                    lib.progressBar({
                        duration = 5000,
                        label = "Abriendo la caja fuerte…",
                        disable = {
                            move = true,
                            combat = true,
                        },
                        anim = {
                            dict = "anim@heists@ornate_bank@thermal_charge",
                            clip = "thermal_charge",
                            flag = 49,
                        },
                    })

                    local items = Robberies.getRandomLoot(self.safe.items)

                    if #items > 0 then
                        self:trackAndGiveItems(items)
                    else
                        lib.notify({
                            description = 'No hay nada de valor aquí',
                            type = 'error'
                        })
                    end

                    if not self.start.isShop then
                        self:removeStep()
                    end
                    safePoint:remove()
                end

                if self.safe.minigame.name ~= 'none' then
                    local minigame = Config.Minigames[self.safe.minigame.name]

                    if self.safe.minigame.requiredItem and self.safe.minigame.requiredItem ~= '' then
                        local hasItem = exports.origen_inventory:HasItem(self.safe.minigame.requiredItem, 1)
                        if not hasItem then
                            lib.notify({
                                description = 'No tienes el objeto requerido para abrir la caja fuerte',
                                type = 'error'
                            })
                            safePoint.busy = false
                            if safePoint.currentDistance <= safePoint.distance then
                                lib.showTextUI('[E] Abrir caja fuerte')
                            end
                            return
                        end
                    end

                    local difficulty = (self.safe.minigame.parameters and self.safe.minigame.parameters[1]) or 'medium'
                    _pendingMinigameCallback = function(success)
                        if not success then
                            lib.notify({
                                description = 'No has logrado abrir la caja fuerte',
                                type = 'error'
                            })
                            maybeConsumeItem(self.safe.minigame.requiredItem, self.safe.minigame.consumeOnFail, self.safe.minigame.consumeOnFailChance)
                            safePoint.busy = false
                            if safePoint.currentDistance <= safePoint.distance then
                                lib.showTextUI('[E] Abrir caja fuerte')
                            end
                            return
                        end
                        maybeConsumeItem(self.safe.minigame.requiredItem, self.safe.minigame.consumeOnSuccess, self.safe.minigame.consumeOnSuccessChance)
                        completeSafe()
                    end
                    TriggerEvent('origen_minijuegos:startGame', self.safe.minigame.name, difficulty, self.safe.minigame.parameters and self.safe.minigame.parameters[2])
                else
                    completeSafe()
                end
            end

            safePoint.wait = 0
        end

        self.interactions[#self.interactions + 1] = safePoint
    end

    if self.steps <= 0 and not self.start.isShop then
        self:finishRobbery()
    end
end

function Robberies:update(data)
    self:remove()
    Robberies.new(data)
end

function Robberies:removeStep()
    self.steps = self.steps - 1

    if self.steps <= 0 then
        self:finishRobbery()
    end
end

function Robberies:finishRobbery()
    self.steps = self.start.isShop and 1 or (#self.lootPoints + (self.safe.enabled and 1 or 0))

    local isEscape = self.escape and self.escape.enabled

    if isEscape then
        -- Tiene escape: siempre arrancar la fase NPC
        if self.robberyTimerDone then
            -- Timer listo: arrancar escape ahora
            self.robberyActive = false
            local message = self.escape.message or '¡El escape ha comenzado! Dirígete al punto de entrega. Tienes {time} minutos.'
            message = message:gsub('{time}', tostring(self.escape.timeLimit or 30))
            lib.notify({ description = message, type = 'success' })
            self:escapePoint()
        else
            -- Sin timer completado: botín recogido, marcar y esperar timer
            self.escapeReady = true
            lib.notify({
                description = '¡Has cogido el botín! Espera la señal para ir a entregar.',
                type = 'warning',
                duration = 8000
            })
        end
    else
        -- Sin escape: completar directo
        if self.robberyTimerDone then
            TriggerServerEvent('origen_robberies:updateStats', self.id, 'completed')
            self.robberyActive = false
            lib.notify({
                description = 'Has completado el robo, ¡rápido, escapa de la zona!',
                type = 'success'
            })
            LocalPlayer.state:set('activeRobbery', nil, true)
            if self.safeZone then
                self.safeZone:remove()
                self.safeZone = nil
            end
        else
            lib.notify({
                description = '¡Has saqueado todo! Espera la señal para poder salir de la zona.',
                type = 'warning',
                duration = 8000
            })
        end
    end
end

function Robberies:remove()
    if self.start and self.start.entity then
        if self.start.type == 'npc' then
            DeleteEntity(self.start.entity)
        else
            DeleteObject(self.start.entity)
        end
    end

    if self.start and self.start.point then
        self.start.point:remove()
    end

    if self.start and self.start.spawnPoint then
        self.start.spawnPoint:remove()
        self.start.spawnPoint = nil
    end

    for _, point in pairs(self.interactions) do
        point:remove()
    end

    if self.bag and DoesEntityExist(self.bag) then
        DeleteEntity(self.bag)
    end

    if self.safe.entity and DoesEntityExist(self.safe.entity) then
        DeleteEntity(self.safe.entity)
    end
    
    if self.guards.entities then
        for _, guard in ipairs(self.guards.entities) do
            if DoesEntityExist(guard) then
                DeleteEntity(guard)
            end
        end
    end

    if self.safeZone then
        self.safeZone:remove()
        self.safeZone = nil
    end

    if self.escape and self.escape.entity then
        DeleteEntity(self.escape.entity)
    end

    if self.escape and self.escape.point then
        self.escape.point:remove()
    end

    Robberies.table[self.id] = nil
end

function Robberies:deliverEscape()
    for _, item in pairs(self.escape.requiredItems or {}) do
        local hasItem = exports.origen_inventory:HasItem(item.name, item.amount)
        if not hasItem then
            lib.notify({
                description = '¿Crees que puedes engañarme? Parece que te falta algo para entregar el botín',
                type = 'error'
            })
            self.escape.point.busy = false
            return false
        end
    end

    lib.progressBar({
        duration = 3000,
        label = "Entregando el botín…",
        disable = {
            move = true,
            combat = true,
        },
        anim = { dict = 'mp_common', clip = 'givetake1_a', flag = 49 }
    })

    local success = lib.callback.await('origen_robberies:tryEscape', false, self.id)

    if success then
        TriggerServerEvent('origen_robberies:updateStats', self.id, 'completed')
        lib.notify({
            description = 'Has entregado el botín con éxito, ¡rápido, escapa de la zona!',
            type = 'success'
        })
        self:removeEscape(true)
        LocalPlayer.state:set('activeRobbery', nil, true)
        if self.safeZone then
            self.safeZone:remove()
            self.safeZone = nil
        end
        self.start.point.busy = false
    else
        self.escape.point.busy = false
    end
end

function Robberies:removeEscape(wait)
    if self.escape then
        self.escape.active = false
    end

    --[[ Con el panel del contacto abierto (el punto `busy`) cuando el tiempo
         se acaba, el panel se quedaba pintado con el raton cogido y ya sin
         robo al que entregar. Solo con el punto ocupado: si no, el foco puede
         ser de otra pantalla del recurso (el panel de administracion). ]]
    if self.escape and self.escape.point and self.escape.point.busy then
        SendNUIMessage({ action = 'hideEscapePanel' })
        SetNuiFocus(false, false)
    end

    SendNUIMessage({
        action = 'showHudTimer',
        data = {
            visible = false
        }
    })

    if self.escape and self.escape.point then
        self.escape.point:remove()
    end

    if self.escapeBlip then
        OrigenMapa.Quitar(self.escapeBlip)
        self.escapeBlip = nil
    end

    if self.escape and self.escape.entity and DoesEntityExist(self.escape.entity) then
        if wait then
            Citizen.Wait(10000)
        end
        DeleteEntity(self.escape.entity)
    end
end

function Robberies:reset()
    self.steps = self.start.isShop and 1 or (#self.lootPoints + (self.safe.enabled and 1 or 0))
    self.start.point.busy = false

    for _, point in pairs(self.interactions) do
        point:remove()
    end

    if self.bag and DoesEntityExist(self.bag) then
        DeleteEntity(self.bag)
    end

    if self.safe.entity and DoesEntityExist(self.safe.entity) then
        DeleteEntity(self.safe.entity)
    end
    
    if self.guards.entities then
        for _, guard in ipairs(self.guards.entities) do
            if DoesEntityExist(guard) then
                DeleteEntity(guard)
            end
        end
    end

    if self.escape and self.escape.entity and DoesEntityExist(self.escape.entity) then
        DeleteEntity(self.escape.entity)
    end

    if self.escapeBlip then
        OrigenMapa.Quitar(self.escapeBlip)
        self.escapeBlip = nil
    end

    self.interactions = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, robbery in pairs(Robberies.table) do
            robbery:remove()
        end
        SetNuiFocus(false, false)
    end
end)

RegisterNetEvent("origen_robberies:client:SyncPedAnim", function(coords, dict, anim, speedin, speedout, duration, flag, playbackrate, lockx, locky, lockz)
    local ped = lib.getClosestPed(coords)

    if not dict then
        ClearPedTasks(ped)
        return
    end

    lib.requestAnimDict(dict)
    TaskPlayAnim(ped, dict, anim, speedin, speedout, duration, flag, playbackrate, lockx, locky, lockz)
end)

RegisterNetEvent('origen_robberies:client:updateRobbery', function(id, data)
    local robbery = Robberies.get(id)

    if robbery then
        robbery:update(data)
    else
        Robberies.new(data)
    end
end)

RegisterNetEvent('origen_robberies:client:deleteRobbery', function(id)
    local robbery = Robberies.get(id)

    if robbery then
        robbery:remove()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerEvent('origen_robberies:playerLoaded')
end)

RegisterNetEvent('origen_robberies:playerLoaded', function()
    lib.callback('origen_robberies:getRobberies', false, function(robberies)
        for _, robbery in pairs(robberies) do
            Robberies.new(robbery)
        end

        -- Comprobar si hay un escape activo persistido en el servidor
        lib.callback('origen_robberies:checkActiveEscape', false, function(activeEscape)
            if activeEscape then
                local robInstance = Robberies.get(activeEscape.robberyId)
                if robInstance then
                    LocalPlayer.state:set('activeRobbery', activeEscape.robberyId, true)
                    robInstance.robberyActive = true
                    robInstance.escapeReady = true
                    robInstance:escapePoint(activeEscape.timeLeftMs)
                end
            end
        end)
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    for _, robbery in pairs(Robberies.table) do
        robbery:remove()
    end
end)

AddRelationshipGroup('EvilNPCs')
SetRelationshipBetweenGroups(0, GetHashKey("EvilNPCs"), GetHashKey("EvilNPCs"))
SetRelationshipBetweenGroups(5, GetHashKey("EvilNPCs"), GetHashKey("PLAYER"))
SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("EvilNPCs"))

Citizen.CreateThread(function()
    local playerData = exports.qbx_core:GetPlayerData()

    if playerData then
        Wait(2500)
        TriggerEvent('origen_robberies:playerLoaded')
    end
end)

function BuildPanelData(id)
    local robbery = Robberies.table[id]
    local reqItems = robbery.escape.requiredItems or {}
    local rewardItems = robbery.escape.rewardItems or {}
    local filteredReq = {}
    for _, r in pairs(reqItems) do
        if r.name and r.name ~= '' then
            table.insert(filteredReq, { name = r.name, amount = r.amount or 1 })
        end
    end
    return filteredReq, rewardItems
end

RegisterNetEvent('qbx_medical:client:onPlayerLaststand', function()
    if LocalPlayer.state.activeRobbery then
        TriggerServerEvent('origen_robberies:updateStats', LocalPlayer.state.activeRobbery, 'failed')

        local robbery = Robberies.get(LocalPlayer.state.activeRobbery)

        robbery.robberyActive = false

        for _, point in pairs(robbery.interactions) do
            point:remove()
        end

        if robbery.bag and DoesEntityExist(robbery.bag) then
            DeleteEntity(robbery.bag)
        end

        LocalPlayer.state:set('activeRobbery', nil, true)
        TriggerServerEvent('origen_robberies:server:SyncPedAnim', vector3(robbery.start.coords.x, robbery.start.coords.y, robbery.start.coords.z), false)
    end
end)

-- RegisterCommand('resetactive', function(source, args, rawCommand)
--     LocalPlayer.state:set('activeRobbery', nil, true)
-- end, false)
