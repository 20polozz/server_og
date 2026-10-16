if not IsDuplicityVersion() then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if NetworkIsSessionStarted() then
                TriggerServerEvent("Queue:playerActivated")
                return
            end
        end
    end)
    return
end

local Queue = {}
-- EDITA ESTO EN SERVER.CFG + OTRAS OPCIONES EN CONFIG.LUA
Queue.MaxPlayers = GetConvarInt("sv_maxclients", 30)
Queue.Debug = GetConvar("sv_debugqueue", "true") == "true" and true or false
Queue.DisplayQueue = false
Queue.InitHostName = GetConvar("sv_hostname")

print(Queue.MaxPlayers, Queue.Debug, Queue.DisplayQueue, Queue.InitHostName)


-- Esto es necesario porque msgpack falla cuando las tablas son muy grandes
local _Queue = {}
_Queue.QueueList = {}
_Queue.PlayerList = {}
_Queue.PlayerCount = 0
_Queue.Priority = {}
_Queue.Connecting = {}
_Queue.JoinCbs = {}
_Queue.TempPriority = {}
_Queue.JoinDelay = GetGameTimer() + Config.JoinDelay and Config.JoinDelay or 0
_Queue.ReservedPlayers = {}
_Queue.PendingReserved = {}
_Queue.ReservedCount = 0

local tostring = tostring
local tonumber = tonumber
local ipairs = ipairs
local pairs = pairs
local print = print
local string_len = string.len
local string_sub = string.sub
local string_format = string.format
local string_lower = string.lower
local math_abs = math.abs
local math_floor = math.floor
local math_random = math.random
local os_time = os.time
local table_insert = table.insert
local table_remove = table.remove

Queue.InitHostName = Queue.InitHostName ~= "default FXServer" and Queue.InitHostName or false

for id, power in pairs(Config.Priority) do
    _Queue.Priority[string_lower(id)] = power
end

function Queue:DebugPrint(msg)
    if Queue.Debug then
        msg = "^3COLA: ^0" .. tostring(msg) .. "^7"
        print(msg)
    end
end

function Queue:IsDiscordRunning(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string_sub(id, 1, 7) == "discord" then
            return true
        end
    end
    
    return false
end

function Queue:HasSteamIdentifier(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string_sub(id, 1, 6) == "steam:" then
            return true
        end
    end

    return false
end

function Queue:GetPlayerCount()
    return _Queue.PlayerCount
end

function Queue:GetSize()
    return #_Queue.QueueList
end

function Queue:ConnectingSize()
    return #_Queue.Connecting
end

function Queue:GetQueueList()
    return _Queue.QueueList
end

function Queue:GetPriorityList()
    return _Queue.Priority
end

function Queue:GetPlayerList()
    return _Queue.PlayerList
end

function Queue:GetTempPriorityList()
    return _Queue.TempPriority
end

function Queue:GetConnectingList()
    return _Queue.Connecting
end

function Queue:IsInQueue(ids, rtnTbl, bySource, connecting)
    local connList = Queue:GetConnectingList()
    local queueList = Queue:GetQueueList()

    for genericKey1, genericValue1 in ipairs(connecting and connList or queueList) do
        local inQueue = false

        if not bySource then
            for genericKey2, genericValue2 in ipairs(genericValue1.ids) do
                if inQueue then break end

                for genericKey3, genericValue3 in ipairs(ids) do
                    if genericValue3 == genericValue2 then inQueue = true break end
                end
            end
        else
            inQueue = ids == genericValue1.source
        end

        if inQueue then
            if rtnTbl then
                return genericKey1, connecting and connList[genericKey1] or queueList[genericKey1]
            end

            return true
        end
    end

    return false
end

function Queue:IsPriority(ids)
    local prio = false
    local tempPower, tempEnd = Queue:HasTempPriority(ids)
    local prioList = Queue:GetPriorityList()

    for _, id in ipairs(ids) do
        id = string_lower(id)

        if prioList[id] then prio = prioList[id] break end
    end

    if tempPower or prio then
        if tempPower and prio then
            return tempPower > prio and tempPower or prio
        else
            return tempPower or prio
        end
    end

    return false
end

function Queue:HasTempPriority(ids)
    local tmpPrio = Queue:GetTempPriorityList()

    for _, id in pairs(ids) do
        id = string_lower(id)

        if tmpPrio[id] then return tmpPrio[id].power, tmpPrio[id].endTime, id end
    end

    return false
end

function Queue:AddToQueue(ids, connectTime, name, src, deferrals)
    if Queue:IsInQueue(ids) then return end

    local tmp = {
        source = src,
        ids = ids,
        name = name,
        priority = Queue:IsPriority(ids) or (src == "debug" and math_random(0, 15)),
        timeout = 0,
        deferrals = deferrals,
        firstconnect = connectTime,
        queuetime = function() return (os_time() - connectTime) end
    }

    local _pos = false
    local queueCount = Queue:GetSize() + 1
    local queueList = Queue:GetQueueList()

    for pos, data in ipairs(queueList) do
        if tmp.priority then
            if not data.priority then
                _pos = pos
            else
                if tmp.priority > data.priority then
                    _pos = pos
                end
            end

            if _pos then
                Queue:DebugPrint(string_format("%s[%s] fue priorizado y colocado %d/%d en la cola", tmp.name, ids[1], _pos, queueCount))
                break
            end
        end
    end

    if not _pos then
        _pos = Queue:GetSize() + 1
        Queue:DebugPrint(string_format("%s[%s] fue colocado %d/%d en la cola", tmp.name, ids[1], _pos, queueCount))
    end

    table_insert(queueList, _pos, tmp)
end

function Queue:RemoveFromQueue(ids, bySource, byIndex)
    local queueList = Queue:GetQueueList()

    if byIndex then
        if queueList[byIndex] then
            table_remove(queueList, byIndex)
        end

        return
    end

    if Queue:IsInQueue(ids, false, bySource) then
        local pos, data = Queue:IsInQueue(ids, true, bySource)
        table_remove(queueList, pos)
    end
end

function Queue:TempSize()
    local count = 0

    for _pos, data in pairs(Queue:GetQueueList()) do
        if Queue:HasTempPriority(data.ids) then count = count +1 end
    end

    return count > 0 and count or false
end

function Queue:IsInConnecting(ids, bySource, refresh)
    local inConnecting, tbl = Queue:IsInQueue(ids, refresh and true or false, bySource and true or false, true)

    if not inConnecting then return false end

    if refresh and inConnecting and tbl then
        Queue:GetConnectingList()[inConnecting].timeout = 0
    end

    return true
end

function Queue:RemoveFromConnecting(ids, bySource, byIndex)
    local connList = Queue:GetConnectingList()

    if byIndex then
        if connList[byIndex] then
            table_remove(connList, byIndex)
        end

        return
    end

    for genericKey1, genericValue1 in ipairs(connList) do
        local inConnecting = false

        if not bySource then
            for genericKey2, genericValue2 in ipairs(genericValue1.ids) do
                if inConnecting then break end

                for genericKey3, genericValue3 in ipairs(ids) do
                    if genericValue3 == genericValue2 then inConnecting = true break end
                end
            end
        else
            inConnecting = ids == genericValue1.source
        end

        if inConnecting then
            table_remove(connList, genericKey1)
            return true
        end
    end

    return false
end

function Queue:AddToConnecting(ids, ignorePos, autoRemove, done)
    local function remove()
        if not autoRemove then return end

        done(Config.Language.connectingerr)
        Queue:RemoveFromConnecting(ids)
        Queue:RemoveFromQueue(ids)
        Queue:DebugPrint("El jugador no pudo ser añadido a la lista de conexión")
    end

    local connList = Queue:GetConnectingList()

    if Queue:ConnectingSize() + Queue:GetPlayerCount() + 1 > Queue.MaxPlayers then remove() return false end
    
    if ids[1] == "debug" then
        table_insert(connList, {source = ids[1], ids = ids, name = ids[1], firstconnect = ids[1], priority = ids[1], timeout = 0})
        return true
    end

    if Queue:IsInConnecting(ids) then Queue:RemoveFromConnecting(ids) end

    local pos, data = Queue:IsInQueue(ids, true)
    if not ignorePos and (not pos or pos > 1) then remove() return false end

    table_insert(connList, data)
    Queue:RemoveFromQueue(ids)

    return true
end

function Queue:GetIds(src)
    local ids = GetPlayerIdentifiers(src)
    local ip = GetPlayerEndpoint(src)

    ids = (ids and ids[1]) and ids or (ip and {"ip:" .. ip} or false)
    ids = ids ~= nil and ids or false

    if ids then
        for k, id in ipairs(ids) do
            if string_sub(id, 1, 7) == "discord" then
                table_remove(ids, k)
                table_insert(ids, 1, id)
                break
            end
        end

        if #ids > 1 then
            for k, id in ipairs(ids) do
                if string_sub(id, 1, 3) == "ip:" and not Queue:IsPriority({id}) then table_remove(ids, k) end
            end
        end
    end

    return ids
end

function Queue:AddPriority(id, power, temp)
    if not id then return false end

    if type(id) == "table" then
        for _id, power in pairs(id) do
            if _id and type(_id) == "string" and power and type(power) == "number" then
                Queue:GetPriorityList()[_id] = power
            else
                Queue:DebugPrint("Error al añadir un ID de prioridad, datos inválidos")
                return false
            end
        end

        return true
    end

    power = (power and type(power) == "number") and power or 10

    if temp then
        local tempPower, tempEnd, tempId = Queue:HasTempPriority({id})
        id = tempId or id

        Queue:GetTempPriorityList()[string_lower(id)] = {power = power, endTime = os_time() + temp} 
    else
        Queue:GetPriorityList()[string_lower(id)] = power
    end
    
    return true
end

function Queue:RemovePriority(id)
    if not id then return false end
    id = string_lower(id)
    Queue:GetPriorityList()[id] = nil
    return true
end

function Queue:UpdatePosData(src, ids, deferrals)
    local pos, data = Queue:IsInQueue(ids, true)
    data.source = src
    data.ids = ids
    data.timeout = 0
    data.firstconnect = os_time()
    data.name = GetPlayerName(src)
    data.deferrals = deferrals
end

function Queue:NotFull(firstJoin)
    local canJoin = Queue:GetPlayerCount() + Queue:ConnectingSize() < Queue.MaxPlayers
    if firstJoin and canJoin then canJoin = Queue:GetSize() <= 1 end
    return canJoin
end

function Queue:SetPos(ids, newPos)
    if newPos <= 0 or newPos > Queue:GetSize() then return false end

    local pos, data = Queue:IsInQueue(ids, true)
    local queueList = Queue:GetQueueList()

    table_remove(queueList, pos)
    table_insert(queueList, newPos, data)
end

function Queue:CanJoin(src, cb)
    local allow = true

    for _, data in ipairs(_Queue.JoinCbs) do
        local await = true

        data.func(src, function(reason)
            if reason and type(reason) == "string" then allow = false cb(reason) end
            await = false
        end)

        while await do Citizen.Wait(0) end

        if not allow then return end
    end

    if allow then cb(false) end
end

function Queue:OnJoin(cb, resource)
    if not cb then return end

    local tmp = {resource = resource, func = cb}
    table_insert(_Queue.JoinCbs, tmp)
end

exports("GetQueueExports", function()
    return Queue
end)

local function playerConnect(name, setKickReason, deferrals, srcOverride)
    local src = srcOverride or source
    local ids = Queue:GetIds(src)
    local name = GetPlayerName(src)
    local connectTime = os_time()
    local connecting = true

    if not srcOverride then
        deferrals.defer()

        if Config.AntiSpam then
            for i=Config.AntiSpamTimer,0,-1 do
                deferrals.update(string.format(Config.PleaseWait, i))
                Citizen.Wait(1000)
            end
        end
    end

    Citizen.CreateThread(function()
        while connecting do
            Citizen.Wait(100)
            if not connecting then return end
            deferrals.update(Config.Language.connecting)
        end
    end)

    Citizen.Wait(500)

    local function done(msg, _deferrals)
        connecting = false

        local deferrals = _deferrals or deferrals

        if msg then deferrals.update(tostring(msg) or "") end

        Citizen.Wait(500)

        if not msg then
            deferrals.done()
            if Config.EnableGrace then
                for _, graceId in ipairs(ids) do
                    Queue:AddPriority(graceId, Config.GracePower, Config.GraceTime)
                end
            end
        else
            deferrals.done(tostring(msg) or "") CancelEvent()
        end

        return
    end

    local function update(msg, _deferrals)
        local deferrals = _deferrals or deferrals
        connecting = false
        deferrals.update(tostring(msg) or "")
    end

    if not ids then
        -- impedir unión
        done(Config.Language.idrr)
        CancelEvent()
        Queue:DebugPrint("Expulsado " .. name .. ", no se pudieron obtener sus identificadores")
        return
    end

    if Config.RequireSteam and not Queue:HasSteamIdentifier(src) then
        done(Config.Language.steam)
        return
    end

    if Config.RequireDiscord and not Queue:IsDiscordRunning(src) then
        -- impedir unión
        done(Config.Language.discord)
        CancelEvent()
        return
    end

    local allow

    Queue:CanJoin(src, function(reason)
        if reason == nil or allow ~= nil then return end
        if reason == false or #_Queue.JoinCbs <= 0 then allow = true return end

        if reason then
            -- impedir unión
            allow = false
            done(reason and tostring(reason) or "Fuiste bloqueado para unirte")
            Queue:RemoveFromQueue(ids)
            Queue:RemoveFromConnecting(ids)
            Queue:DebugPrint(string_format("%s[%s] fue bloqueado para unirse; Razón: %s", name, ids[1], reason))
            CancelEvent()
            return
        end

        allow = true
    end) 

    while allow == nil do Citizen.Wait(0) end
    if not allow then return end

    if Config.PriorityOnly and not Queue:IsPriority(ids) then done(Config.Language.wlonly) return end

    local discordId
    for _, id in ipairs(ids) do
        if string_sub(id, 1, 8) == "discord:" then
            discordId = string_sub(id, 9)
            break
        end
    end

    if discordId then
        local reserved = MySQL.scalar.await('SELECT 1 FROM discord_reserved_slots WHERE discord_id = ?', { discordId })
        if reserved then
            Queue:DebugPrint(string_format("%s[%s] tiene slot reservado, acceso directo concedido", name, ids[1]))
            _Queue.PendingReserved[discordId] = true
            Queue:RemoveFromQueue(ids)
            Queue:RemoveFromConnecting(ids)
            done()
            return
        end
    end

    if discordId then
        local result = MySQL.scalar.await('SELECT priority FROM discord_queue_priority WHERE discord_id = ?', { discordId })
        if result then
            local power = (6 - tonumber(result)) * 10
            Queue:AddPriority(ids[1], power)
            local _, existingData = Queue:IsInQueue(ids, true)
            if existingData then
                existingData.priority = power
            end
        end
    end

    -- Prioridad por license (grupos y prioridad individual gestionados desde el panel de admin)
    local licenseId
    for _, id in ipairs(ids) do
        if string_sub(id, 1, 8) == "license:" then
            licenseId = id
            break
        end
    end

    if licenseId then
        -- Verificar membresía en grupo de prioridad (protegido: las tablas pueden no existir aún)
        local okGroup, groupPower = pcall(function()
            return MySQL.scalar.await([[
                SELECT qpg.power
                FROM queue_priority_members qpm
                JOIN queue_priority_groups qpg ON qpm.group_id = qpg.id
                WHERE qpm.license = ? AND (qpm.expires_at IS NULL OR qpm.expires_at > ?)
            ]], { licenseId, os_time() })
        end)

        if okGroup and groupPower then
            local power = tonumber(groupPower)
            Queue:AddPriority(licenseId, power)
            local _, existingData = Queue:IsInQueue(ids, true)
            if existingData then
                existingData.priority = existingData.priority and existingData.priority > power and existingData.priority or power
            end
        else
            -- Solo si no tiene grupo, revisar prioridad individual
            local okInd, indPower = pcall(function()
                return MySQL.scalar.await(
                    'SELECT power FROM queue_individual_priority WHERE license = ? AND (expires_at IS NULL OR expires_at > ?)',
                    { licenseId, os_time() }
                )
            end)
            if okInd and indPower then
                local power = tonumber(indPower)
                Queue:AddPriority(licenseId, power)
                local _, existingData = Queue:IsInQueue(ids, true)
                if existingData then
                    existingData.priority = existingData.priority and existingData.priority > power and existingData.priority or power
                end
            end
        end
    end

    local rejoined = false

    if Queue:IsInConnecting(ids, false, true) then
        Queue:RemoveFromConnecting(ids)

        if Queue:NotFull() then
            -- dejar entrar al servidor

            if not Queue:IsInQueue(ids) then
                Queue:AddToQueue(ids, connectTime, name, src, deferrals)
            end

            local added = Queue:AddToConnecting(ids, true, true, done)
            if not added then CancelEvent() return end
            done()

            return
        else
            rejoined = true
        end
    end

    if Queue:IsInQueue(ids) then
        rejoined = true
        Queue:UpdatePosData(src, ids, deferrals)
    else
        Queue:AddToQueue(ids, connectTime, name, src, deferrals)

        if rejoined then
            Queue:SetPos(ids, 1)
            rejoined = false
        end
    end

    local pos, data = Queue:IsInQueue(ids, true)
    
    if not pos or not data then
        done(Config.Language.err .. " [1]")

        Queue:RemoveFromQueue(ids)
        Queue:RemoveFromConnecting(ids)

        CancelEvent()
        return
    end

    if Queue:NotFull(true) and _Queue.JoinDelay <= GetGameTimer() then
            -- dejar entrar al servidor
            local added = Queue:AddToConnecting(ids, true, true, done)
            if not added then CancelEvent() return end

            done()
            return
    end

    update(string_format(Config.Language.pos .. ((Queue:TempSize() and Config.ShowTemp) and " (" .. Queue:TempSize() .. " temp)" or "00:00:00"), pos, Queue:GetSize(), ""))

    if rejoined then return end

    while true do
        Citizen.Wait(500)

        local pos, data = Queue:IsInQueue(ids, true)

        local function remove(msg)
            if data then
                if msg then
                    update(msg, data.deferrals)
                end

                Queue:RemoveFromQueue(data.source, true)
                Queue:RemoveFromConnecting(data.source, true)
            else
                Queue:RemoveFromQueue(ids)
                Queue:RemoveFromConnecting(ids)
            end
        end

        if not data or not data.deferrals or not data.source or not pos then
            remove("[Cola] Eliminado de la cola, datos de cola inválidos :(")
            Queue:DebugPrint(tostring(name .. "[" .. ids[1] .. "] fue eliminado de la cola porque tenía datos inválidos"))
            return
        end

        local endPoint = GetPlayerEndpoint(data.source)
        if not endPoint then data.timeout = data.timeout + 0.5 else data.timeout = 0 end

        if data.timeout >= Config.QueueTimeOut and os_time() - connectTime > 5 then
            remove("[Cola] Eliminado por tiempo de espera agotado")
            return
        end

        if pos <= 1 and Queue:NotFull() and _Queue.JoinDelay <= GetGameTimer() then
            -- dejar entrar al servidor
            local added = Queue:AddToConnecting(ids)

            update(Config.Language.joining, data.deferrals)
            Citizen.Wait(500)

            if not added then
                done(Config.Language.connectingerr)
                CancelEvent()
                return
            end

            done(nil, data.deferrals)

            if Config.EnableGrace then
                for _, graceId in ipairs(ids) do
                    Queue:AddPriority(graceId, Config.GracePower, Config.GraceTime)
                end
            end

            Queue:RemoveFromQueue(ids)
            return
        end

        local seconds = data.queuetime()
        local qTime = string_format("%02d", math_floor((seconds % 86400) / 3600)) .. ":" .. string_format("%02d", math_floor((seconds % 3600) / 60)) .. ":" .. string_format("%02d", math_floor(seconds % 60))

        local msg = string_format(Config.Language.pos .. ((Queue:TempSize() and Config.ShowTemp) and " (" .. Queue:TempSize() .. " temp)" or ""), pos, Queue:GetSize(), qTime)
        update(msg, data.deferrals)
    end
end

exports("PlayerConnect", function(name, setKickReason, deferrals, src)
    playerConnect(name, setKickReason, deferrals, src)
end)

Citizen.CreateThread(function()
    local function remove(data, pos, msg)
        if data and data.source then
            Queue:RemoveFromQueue(data.source, true)
            Queue:RemoveFromConnecting(data.source, true)
        elseif pos then
            table_remove(Queue:GetQueueList(), pos)
        end
    end

    while true do
        Citizen.Wait(1000)
    
        local i = 1
    
        while i <= Queue:ConnectingSize() do
            local data = Queue:GetConnectingList()[i]
    
            local endPoint = GetPlayerEndpoint(data.source)
    
            data.timeout = data.timeout + 1
    
            if ((data.timeout >= 300 and not endPoint) or data.timeout >= Config.ConnectTimeOut) and data.source ~= "debug" and os_time() - data.firstconnect > 5 then
                remove(data)
                Queue:DebugPrint(data.name .. "[" .. data.ids[1] .. "] fue eliminado de la cola de conexión porque agotó el tiempo de espera")
            else
                i = i + 1
            end
        end

        for id, data in pairs(Queue:GetTempPriorityList()) do
            if os_time() >= data.endTime then
                Queue:GetTempPriorityList()[id] = nil
            end
        end

        Queue.MaxPlayers = GetConvarInt("sv_maxclients", 30)
        Queue.Debug = GetConvar("sv_debugqueue", "true") == "true" and true or false
        Queue.DisplayQueue = false

        local qCount = Queue:GetSize()

        if Queue.InitHostName then
            SetConvar('Cola', tostring(qCount))
        end
        if Queue.DisplayQueue then
            if Queue.InitHostName then
                SetConvar("sv_hostname", (qCount > 0 and "[" .. tostring(qCount) .. "] " or "") .. Queue.InitHostName)
            else
                Queue.InitHostName = GetConvar("sv_hostname")
                Queue.InitHostName = Queue.InitHostName ~= "default FXServer" and Queue.InitHostName or false
            end
        end
    end
end)

RegisterServerEvent("Queue:playerActivated")
AddEventHandler("Queue:playerActivated", function()
    local src = source
    local ids = Queue:GetIds(src)

    if not Queue:GetPlayerList()[src] then
        local discordId
        if ids then
            for _, id in ipairs(ids) do
                if string_sub(id, 1, 8) == "discord:" then
                    discordId = string_sub(id, 9)
                    break
                end
            end
        end

        if discordId and _Queue.PendingReserved[discordId] then
            _Queue.PendingReserved[discordId] = nil
            _Queue.ReservedPlayers[src] = discordId
            _Queue.ReservedCount = _Queue.ReservedCount + 1
            Queue:DebugPrint(string_format("[Reservado] %s entró al servidor (total reservados: %d)", GetPlayerName(src), _Queue.ReservedCount))
        else
            _Queue.PlayerCount = _Queue.PlayerCount + 1
        end

        Queue:GetPlayerList()[src] = true
        Queue:RemoveFromQueue(ids)
        Queue:RemoveFromConnecting(ids)
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    local ids = Queue:GetIds(src)

    if Queue:GetPlayerList()[src] then
        if _Queue.ReservedPlayers[src] then
            _Queue.ReservedPlayers[src] = nil
            _Queue.ReservedCount = math_abs(_Queue.ReservedCount - 1)
            Queue:DebugPrint(string_format("[Reservado] jugador desconectado (total reservados: %d)", _Queue.ReservedCount))
        else
            _Queue.PlayerCount = math_abs(_Queue.PlayerCount - 1)
        end
        Queue:GetPlayerList()[src] = nil
        Queue:RemoveFromQueue(ids)
        Queue:RemoveFromConnecting(ids)
        if Config.EnableGrace then
            for _, graceId in ipairs(ids) do
                Queue:AddPriority(graceId, Config.GracePower, Config.GraceTime)
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if Queue.DisplayQueue and Queue.InitHostName and resource == GetCurrentResourceName() then SetConvar("sv_hostname", Queue.InitHostName) end
    
    for k, data in ipairs(_Queue.JoinCbs) do
        if data.resource == resource then
            table_remove(_Queue.JoinCbs, k)
        end
    end
end)

if Config.DisableHardCap then
    Queue:DebugPrint("^1 [connectqueue] Desactivando hardcap ^7")

    AddEventHandler("onResourceStarting", function(resource)
        if resource == "hardcap" then CancelEvent() return end
    end)
    
    StopResource("hardcap")
end

local testAdds = 0
local commands = {}

commands.addq = function()
    Queue:DebugPrint("COLA DE DEBUG AÑADIDA")
    Queue:AddToQueue({"discord:10000000000000"..testAdds}, os_time(), "TestAdd: " .. testAdds, "debug")
    testAdds = testAdds + 1
end

commands.removeq = function(args)
    args[1] = tonumber(args[1])
    local name = Queue:GetQueueList()[args[1]] and Queue:GetQueueList()[args[1]].name or nil
    Queue:RemoveFromQueue(nil, nil, args[1])
    Queue:DebugPrint("ELIMINADO " .. tostring(name) .. " DE LA COLA")
end

commands.printq = function()
    Queue:DebugPrint("LISTA ACTUAL DE LA COLA")

    for pos, data in ipairs(Queue:GetQueueList()) do
        Queue:DebugPrint(pos .. ": [src: " .. data.source .. "] " .. data.name .. "[" .. data.ids[1] .. "] | Prioridad: " .. (tostring(data.priority and data.priority or false)) .. " | ÚLt. Msg: " .. (data.source ~= "debug" and GetPlayerLastMsg(data.source) or "debug") .. " | Tiempo agot.: " .. data.timeout .. " | Tiempo en cola: " .. data.queuetime() .. " segundos")
    end
end

commands.addc = function()
    Queue:AddToConnecting({"debug"})
    Queue:DebugPrint("COLA DE CONEXIÓN DE DEBUG AÑADIDA")
end

commands.removec = function(args)
    args[1] = tonumber(args[1])
    local name = Queue:GetConnectingList()[args[1]] and Queue:GetConnectingList()[args[1]].name or nil
    Queue:RemoveFromConnecting(nil, nil, args[1])
    Queue:DebugPrint("ELIMINADO " .. tostring(name) .. " DE LA LISTA DE CONEXIÓN")
end

commands.printc = function()
    Queue:DebugPrint("LISTA ACTUAL DE CONEXIÓN")

    for pos, data in ipairs(Queue:GetConnectingList()) do
        Queue:DebugPrint(pos .. ": [src: " .. data.source .. "] " .. data.name .. "[" .. data.ids[1] .. "] | Prioridad: " .. (tostring(data.priority and data.priority or false)) .. " | ÚLt. Msg: " .. (data.source ~= "debug" and GetPlayerLastMsg(data.source) or "debug") .. " | Tiempo agot.: " .. data.timeout)
    end
end

commands.printl = function()
    for k, joined in pairs(Queue:GetPlayerList()) do
        Queue:DebugPrint(k .. ": " .. tostring(joined))
    end
end

commands.printp = function()
    Queue:DebugPrint("LISTA ACTUAL DE PRIORIDADES")

    for id, power in pairs(Queue:GetPriorityList()) do
        Queue:DebugPrint(id .. ": " .. tostring(power))
    end
end

commands.printcount = function()
    Queue:DebugPrint("Conteo de jugadores: " .. Queue:GetPlayerCount())
end

commands.printtp = function()
    Queue:DebugPrint("LISTA ACTUAL DE PRIORIDADES TEMPORALES")

    for k, data in pairs(Queue:GetTempPriorityList()) do
        Queue:DebugPrint(k .. ": Poder: " .. tostring(data.power) .. " | Fin: " .. tostring(data.endTime) .. " | TiempoActual: " .. tostring(os_time()))
    end
end

commands.removetp = function(args)
    if not args[1] then return end

    Queue:GetTempPriorityList()[args[1]] = nil
    Queue:DebugPrint("ELIMINADO " .. args[1] .. " DE LA LISTA DE PRIORIDADES TEMPORALES")
end

commands.setpos = function(args)
    if not args[1] or not args[2] then return end

    args[1], args[2] = tonumber(args[1]), tonumber(args[2])

    local data = Queue:GetQueueList()[args[1]]

    Queue:SetPos(data.ids, args[2])

    Queue:DebugPrint("POSICIÓN EN COLA DE " .. data.name .. " ESTABLECIDA A: " .. args[2])
end

commands.setdata = function(args)
    if not args[1] or not args[2] or not args[3] then return end
    args[1] = tonumber(args[1])

    local num = tonumber(args[3])
    local data = Queue:GetQueueList()[args[1]]

    if args[2] == "queuetime" then
        local time = data.queuetime()
        local dif = time - num

        data.firstconnect = data.firstconnect + dif
        data.queuetime = function() return (os_time() - data.firstconnect) end
    else
        data[args[2]] = num and num or args[3]
    end

    Queue:DebugPrint("DATOS DE " .. data.name .. " '" .. args[2] .. "' ESTABLECIDOS A " .. args[3])
end

commands.commands = function()
    for cmd, func in pairs(commands) do
        Queue:DebugPrint(tostring(cmd))
    end
end

AddEventHandler("rconCommand", function(command, args)
    if command == "queue" and commands[args[1]] then
        command = args[1]
        table_remove(args, 1)
        commands[command](args)
        CancelEvent()
    end
end)

RegisterCommand("qstatus", function(src)
    if src ~= 0 then return end
    local queueList = Queue:GetQueueList()
    local connList = Queue:GetConnectingList()
    local normalPlayers = Queue:GetPlayerCount()
    local reservedPlayers = _Queue.ReservedCount
    local totalPlayers = normalPlayers + reservedPlayers
    local slotsLibres = Queue.MaxPlayers - normalPlayers - #connList
    print("^3========== ESTADO DE LA COLA ==========^7")
    print(("^5Jugadores en cola: ^7%d"):format(#queueList))
    print(("^5Jugadores conectando: ^7%d"):format(#connList))
    print(("^5Jugadores normales: ^7%d"):format(normalPlayers))
    print(("^5Jugadores con slot reservado: ^7%d"):format(reservedPlayers))
    print(("^5Total en servidor: ^7%d"):format(totalPlayers))
    print(("^5Capacidad máxima: ^7%d (+ %d reservados)"):format(Queue.MaxPlayers, reservedPlayers))
    print(("^5Slots libres para cola normal: ^7%d"):format(slotsLibres))
    print("^3========================================^7")
end, true)

RegisterCommand("qlist", function(src)
    if src ~= 0 then return end
    local queueList = Queue:GetQueueList()
    print("^3========== JUGADORES EN COLA ==========^7")
    if #queueList == 0 then
        print("^2La cola está vacía^7")
    else
        for pos, data in ipairs(queueList) do
            local seconds = data.queuetime()
            local qTime = string_format("%02d:%02d:%02d", math_floor((seconds % 86400) / 3600), math_floor((seconds % 3600) / 60), math_floor(seconds % 60))
            local prio = data.priority and tostring(data.priority) or "ninguna"
            print(string_format("^5[%d]^7 %s | ID: %s | Prioridad: %s | Tiempo: %s", pos, data.name, data.ids[1], prio, qTime))
        end
    end
    print("^3========================================^7")
end, true)

RegisterCommand("qmove", function(src, args)
    if src ~= 0 then return end
    if not args[1] or not args[2] then
        print("^1Uso: qmove <discord_id|identificador> <nueva_posicion>^7")
        return
    end
    local toPos = tonumber(args[2])
    if not toPos then
        print("^1La nueva posición debe ser un número^7")
        return
    end
    local searchId = args[1]
    if not string_sub(searchId, 1, 8):find(":") then
        searchId = "discord:" .. searchId
    end
    searchId = string_lower(searchId)
    local queueList = Queue:GetQueueList()
    local foundPos, foundData
    for pos, data in ipairs(queueList) do
        for _, id in ipairs(data.ids) do
            if string_lower(id) == searchId then
                foundPos = pos
                foundData = data
                break
            end
        end
        if foundPos then break end
    end
    if not foundPos then
        print(("^1No se encontró ningún jugador con el identificador: %s^7"):format(searchId))
        return
    end
    if toPos < 1 or toPos > #queueList then
        print(("^1La posición destino debe estar entre 1 y %d^7"):format(#queueList))
        return
    end
    Queue:SetPos(foundData.ids, toPos)
    print(("^2%s movido de la posición %d a la %d^7"):format(foundData.name, foundPos, toPos))
end, true)

local ostimetemp = os_time()
RegisterCommand("test", function(src)
    local currentTime = os_time()
    print(ostimetemp - currentTime)
end, true)
