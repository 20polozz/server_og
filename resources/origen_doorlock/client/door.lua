Doors = {}
currentDoorID = false

DoorStates = {
    [0] = Translations?.drawtext?.lock or 'Lock',
    [1] = Translations?.drawtext?.unlock or 'Unlock',
}

Door = {
    id = nil,
    data = {},
    point = {},
    lastUsed = 0,
    previewsUsed = false,
}

function Door:new(data)
    data = data or {}
    self.__index = self
    local instance = setmetatable({}, self)

    instance.name = data.name
    instance.id = data.id
    instance.data = data.data
    instance.point = nil
    instance.lastUsed = 0

    return instance
end

function Door:Get(id)
    if not Doors[id] then 
        debugger('Door not found', id)
        return
    end

    return Doors[id]
end

function Door:RegisterDoor()
    local function addDoorToSystem(hash, model, x, y, z, state, rate)
        AddDoorToSystem(hash, model, x, y, z, false, false, false)
        DoorSystemSetDoorState(hash, 4, false, false)
        DoorSystemSetDoorState(hash, state, false, false)
        DoorSystemSetAutomaticRate(hash, rate, false, false)
    end

    self.name = self.name
    self.type = self.data.type
    self.state = self.data.state

    local function nearby(data)
        if data.currentDistance < data.distance and self.cantInteract then
            local currentText = DoorStates[self.data.locked]
            if not data.noty or data.lastText ~= currentText then
                currentDoorID = self.id
                debugger('[Nearby] Detecting door:', self.id, 'Text:', currentText)
                Custom.DrawText(currentText, 'E')
                data.noty = true
                data.lastText = currentText
            end
            if IsDisabledControlJustReleased(0, 38) then
                self:UseDoor()
            end
        end
    end

    local function onExit(data)
        debugger('Exit', data.doorID)
        if data.noty then
            Custom.HideText()
            data.noty = false
        end
        currentDoorID = false
        self.cantInteract = false
    end

    local function onEnter(data)
        local config = data.config

        for _, hash in pairs(data.hashes) do
            if not IsDoorRegisteredWithSystem(hash) then
                if self.data.doors then 
                    for _, door in pairs(self.data.doors) do
                        addDoorToSystem(door.hash, door.model, door.coords.x, door.coords.y, door.coords.z, self.data.locked, self.data.rate)
                    end
                else
                    addDoorToSystem(self.data.hash, self.data.model, self.data.coords.x, self.data.coords.y, self.data.coords.z, self.data.locked, self.data.rate)
                end
            end
        end

        --[[ El servidor ya no manda el codigo ni la lista de jugadores: solo
             si la puerta tiene codigo y si ESTE jugador esta en la lista. Esto
             es solo para ensenar el texto; quien decide es el servidor. ]]
        if config.hasPasscode then
            self.cantInteract = 'passcode'
        end

        if config.hasPlayers then
            if config.playerAllowed then
                if not self.cantInteract then
                    self.cantInteract = true
                end
                goto continue
            else
                return
            end
        end

        if config.groups and next(config.groups) then
            local playerJob = Framework.GetPlayerJob()
            local playerGroup = Framework.GetPlayerJobGroup()
            local playerGang = Framework.GetPlayerGang() --TODO: Implementar sistema de ilegal de origen internamente
            local playerGangGrade = Framework.GetPlayerGangGrade() --TODO: Implementar sistema de ilegal de origen internamente

            if config.groups[playerJob] then
                if tonumber(playerGroup) >= tonumber(config.groups[playerJob]) then
                    if not self.cantInteract then
                        self.cantInteract = true
                    end
                    goto continue
                end
            end

            if config.groups[playerGang] then
                if tonumber(playerGangGrade) >= tonumber(config.groups[playerGang]) then
                    if not self.cantInteract then
                        self.cantInteract = true
                    end
                    goto continue
                end
            end

            local businessState = LocalPlayer.state.businesses
            if businessState then
                for businessId, grade in pairs(businessState) do
                    if config.groups[businessId] then
                        local pGrade = tonumber(grade)
                        local rGrade = tonumber(config.groups[businessId])
                        
                        local hasAccess = false
                        if pGrade and rGrade then
                            hasAccess = (pGrade >= rGrade)
                        else
                            -- Business grade is likely a string (e.g., 'boss'). Validate against 0 or exact string match.
                            hasAccess = (not rGrade or rGrade == 0) or (tostring(grade) == tostring(config.groups[businessId]))
                        end

                        if hasAccess then
                            if not self.cantInteract then
                                self.cantInteract = true
                            end
                            goto continue
                        end
                    end
                end
            end

            return
        end

        ::continue::

        if not self.cantInteract then
            debugger('[onEnter] Permission set to TRUE (Default) for door:', self.id)
            self.cantInteract = true
        end
        
    end

    local hash = {}

    if self.data.doors then 
        for _, door in pairs(self.data.doors) do
            addDoorToSystem(door.hash, door.model, door.coords.x, door.coords.y, door.coords.z, self.data.locked, self.data.rate)
            hash[#hash + 1] = door.hash
        end
    else
        addDoorToSystem(self.data.hash, self.data.model, self.data.coords.x, self.data.coords.y, self.data.coords.z, self.data.locked, self.data.rate)
        hash[#hash + 1] = self.data.hash
    end

    self.point = lib.points.new({
        coords = vector3(self.data.coords.x, self.data.coords.y, self.data.coords.z),
        distance = tonumber(self.data.maxDistance),
        onExit = onExit,
        nearby = nearby,
        onEnter = onEnter,
        text = DoorStates[self.data.locked],
        cantInteract = false,
        noty = false,
        doorID = self.id,
        config = self.data,
        hashes = hash,
    })

    Doors[self.id] = self

    debugger('Registered door with id '..self.id)
end

function Door:DeleteDoor()
    local cacheID = self.id
    if self.data.doors then
        DoorSystemSetDoorState(self.data.doors[1].hash, 0, false, false)
        DoorSystemSetDoorState(self.data.doors[2].hash, 0, false, false)
    else
        DoorSystemSetDoorState(self.data.hash, 0, false, false)
    end

    if self.point then
        self.point:remove()
    end

    Doors[self.id] = nil
    for id, data in pairs(self) do
        self[id] = nil
    end

    debugger('Deleted door with id '..cacheID)
end

function Door:UseDoor()
    debugger('[UseDoor] cantInteract:', self.cantInteract, 'Door:', self.id)
    if not self.cantInteract or (self.cantInteract ~= true and self.cantInteract ~= 'passcode') then
        debugger('[UseDoor] Interaction REJECTED. Permission missing or incorrect:', self.cantInteract)
        return
    end
    
    if self.lastUsed + 1000 > GetGameTimer() then
        debugger('[UseDoor] Cooldown active')
        return
    end

    -- El codigo se pide aqui pero se comprueba en el servidor: el cliente ya
    -- no lo conoce.
    local codigo = nil
    if self.data.hasPasscode then
        debugger('Open via passcode')
        local input = Utils.GetInput(Translations.general['enterPasscode'], {
            {type = 'input', label = Translations.general['passcode'], password = true, required = true}
        })

        if not input or not input[1] or input[1] == '' then return end
        codigo = tostring(input[1])
    end

    if (GetGameTimer() - self.lastUsed) > 500 then
        self.lastUsed = GetGameTimer()
        Utils.PlayAnim(cache.ped, 'anim@heists@humane_labs@finale@keycards', 'ped_a_fail_d', 500)

        debugger('[UseDoor] Sending to server - ID:', self.id)
        TriggerServerEvent('origen_doorlock:server:UseDoor', self.id, codigo)
    end

end

RegisterNetEvent('origen_doorlock:client:DeleteDoor', function(id)
    debugger('[Client DeleteDoor Event] Received for ID:', id)
    local door = Door:Get(id)
    if not door then 
        debugger('[Client DeleteDoor Event] Door NOT FOUND locally:', id)
        return 
    end

    door:DeleteDoor()

    -- Si el menú está abierto, lo actualizamos para que desaparezca la puerta
    -- borrada. La lista del panel (con códigos) solo la da el servidor a un admin.
    if Nui and Nui.abierto then
        local adminDoors = lib.callback.await('origen_doorlock:server:GetAdminDoors', false)
        if adminDoors then
            SendNUIMessage({ action = 'updateDoors', doors = adminDoors })
        end
    end
end)

RegisterNetEvent('origen_doorlock:client:UpdateDoor', function(id, newData)
    debugger('[Client UpdateDoor Event] Received for ID:', id)
    local door = Door:Get(id)
    if not door then
        debugger('[Client UpdateDoor Event] Door NOT FOUND locally:', id)
        return
    end

    -- Actualizar campos editables preservando coords/hash/modelo/doors
    door.data.name        = newData.name        or door.data.name
    door.data.maxDistance = newData.maxDistance  or door.data.maxDistance
    door.data.rate        = newData.rate         or door.data.rate
    door.data.autolock    = newData.autolock     or 0
    door.data.lockpick    = newData.lockpick     or 0
    door.data.automatic   = newData.automatic    or false
    door.data.hasPasscode   = newData.hasPasscode == true
    door.data.hasPlayers    = newData.hasPlayers == true
    door.data.playerAllowed = newData.playerAllowed == true
    door.data.groups      = newData.groups
    door.name             = door.data.name

    -- Actualizar la distancia del point si cambió
    if door.point then
        door.point.distance = tonumber(door.data.maxDistance)
        door.point.config   = door.data
    end

    debugger('[Client UpdateDoor Event] Door updated locally:', id)
end)

-- Por qué el servidor no ha abierto la puerta (código, permiso, intentos).
RegisterNetEvent('origen_doorlock:client:avisoPuerta', function(clave)
    local texto = Translations.puerta and Translations.puerta[clave]
    if texto then Custom.Notify(texto, 'error') end
end)

RegisterNetEvent('origen_doorlock:client:UseDoor', function(id, locked)
    debugger('[Client UseDoor Event] Received update for door:', id, 'New state:', locked)
    local door = Doors[id]
    if not door then 
        debugger('[Client UseDoor Event] Door NOT FOUND in local table:', id)
        return 
    end

    Door.UpdateState(door, locked)
end)

function Door:UpdateState(locked)
    debugger('[UpdateState] Door ID:', self.id, 'New locked state:', locked, 'Old state:', self.data.locked)
    self.data.locked = locked
    self.state = locked

    if self.data.doors then 
        DoorSystemSetDoorState(self.data.doors[1].hash, self.data.locked, false, false)
        DoorSystemSetDoorState(self.data.doors[2].hash, self.data.locked, false, false)

        if self.data.hold then  
            DoorSystemSetHoldOpen(self.data.doors[1].hash, self.data.locked == 0)
            DoorSystemSetHoldOpen(self.data.doors[2].hash, self.data.locked == 0)
        end

        while self.data.locked == 1 and (not IsDoorClosed(self.data.doors[1].hash) or not IsDoorClosed(self.data.doors[2].hash)) do 
            Wait(0) 
        end
    else
        DoorSystemSetDoorState(self.data.hash, self.data.locked, false, false)

        if self.data.hold then 
            DoorSystemSetHoldOpen(self.data.hash, self.data.locked == 0) 
        end
        
        while self.data.locked == 1 and not IsDoorClosed(self.data.hash) do 
            Wait(0)
        end
    end

    if self.point then
        self.point.text = DoorStates[self.data.locked]

        if self.point.noty then
            Custom.DrawText(self.point.text, 'E')
        end
    end

    local distance = #(GetEntityCoords(cache.ped) - vector3(self.data.coords.x, self.data.coords.y, self.data.coords.z))

    if distance < 20 then
        local volume = (0.01) / (distance/ 5)
        volume = math.min(volume, 0.8)
        volume = math.max(volume, 0)
        Utils.PlaySound(self.data.locked == 0 and 'unlock' or 'lock', volume)
    end
end

function Door:EditDoor()    

end