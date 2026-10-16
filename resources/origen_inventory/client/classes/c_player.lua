Player_Class = {}
Player_Class.__index = Player_Class
Player = nil

local playerInventoryLabel = Config.UI.PlayerInventoryLabel or 'Inventario'
local debug = Debug.new(Config.DebugMode)

CurrentVehicle = nil

---@return Player_Class
function Player_Class:new()
    local self = setmetatable({
        source = GetPlayerServerId(PlayerId()),
        isOpen = false,
        inventory = {},
        items = {},
        currentWeapon = nil,
        otherInv = nil,
        ammo = {},
        weight = 0,
        slots = Config.Player.MaxInventorySlots,
        maxWeight = Config.Player.MaxWeight,
        maxSlots = Config.Player.MaxInventorySlots,
        nextUpdate = 0,
        activeDrop = nil,
        equipedClothes = nil,
    }, Player_Class)
    self:GetInfo()
    self:LoadInventory()
    return self
end

---@return table
function Player_Class:GetInfo()
    local job, gang, charinfo = Bridge.GetPlayerInfo()
    self.job = job
    self.gang = gang
    self.charinfo = charinfo
    self.health = Bridge.GetPlayerHealth
    self.armor = Bridge.GetPlayerArmor
    self.hunger = Bridge.GetPlayerHunger
    self.thirst = Bridge.GetPlayerThirst
    return self
end

function Player_Class:ReturnWeapons()
    local weapons = {}

    --- El `:finally` de LoadInventory llama aqui incluso cuando la carga fallo.
    if type(self.inventory) ~= 'table' then return weapons end

    for _, item in pairs(self.inventory) do
        if item.type == "weapon" then
            table.insert(weapons, item)
        end
    end
    return weapons
end

--[[ origen_clothing revienta al pedirle la ropa si todavia no tiene los datos
     de apariencia del ped --durante la creacion del personaje, sin ir mas lejos,
     que es justo cuando pasa esto--. Como iba dentro de la tabla del mensaje, el
     error se llevaba por delante la apertura entera del inventario en vez de
     dejar el hueco de la ropa vacio.

     Si una prenda esta puesta o no lo decide EstadoRopa (client/clothes.lua),
     con la misma regla que los botones de poner y quitar. Antes se fiaba de
     origen_clothing, que tiene su propio "sin prenda" y no coincide con el del
     inventario: una prenda quitada seguia en rosa. De origen_clothing solo se
     toma la huella de la prenda (la usa la ropa como objeto). `__recuperables`
     son las que se quitaron y se pueden volver a poner (Vestir todo). ]]
local function RopaEquipada()
    local ok, ropa = pcall(function()
        return exports.origen_clothing:GetEquippedClothes(cache.ped, true)
    end)
    if not ok or type(ropa) ~= 'table' then ropa = {} end

    local puesta, recuperable
    if EstadoRopa then
        local okEstado, p, r = pcall(EstadoRopa)
        if okEstado then puesta, recuperable = p, r end
    end
    if not puesta then return ropa end

    for clave, esta in pairs(puesta) do
        if esta then
            ropa[clave] = ropa[clave] or 'puesta'
        else
            ropa[clave] = nil
        end
    end
    ropa.__recuperables = recuperable
    return ropa
end

--[[ La ropa de ahora mismo, para la pestaña Personaje. Solo llegaba al abrir
     el inventario: quitarse una prenda desde el panel (o con /pelo, o al pasar
     una prenda al inventario) no la volvia a mandar, y la etiqueta seguia
     encendida hasta cerrar y abrir. La pestaña la pide tras cada accion y cada
     poco mientras esta a la vista.

     Con RegisterNuiCallback y no con InventoryUI.On: este fichero se carga
     antes que f_nui.lua, que es donde nace InventoryUI. ]]
RegisterNuiCallback('GetRopaPuesta', function(_, cb)
    cb(RopaEquipada())
end)

--[[ Reintentos de la carga inicial. Diez intentos de segundo en segundo:
     de sobra para el hueco que deja el framework al entrar, y corto como para
     no dejar un hilo dando vueltas si el jugador se ha ido. ]]
local REINTENTOS_CARGA = 10
local ESPERA_REINTENTO = 1000

--- Vuelve a pedir el inventario cuando el servidor ha contestado en blanco.
--- @param other any
function Player_Class:ReintentarCarga(other)
    --- Nunca en nil: hay medio recurso que da por hecho que esto es una tabla.
    self.inventory = self.inventory or {}

    local intento = (self.reintentosCarga or 0) + 1
    self.reintentosCarga = intento

    if intento > REINTENTOS_CARGA then
        print(('^1[ORG_INV]^0 El servidor no ha devuelto el inventario tras %s intentos; se deja de pedir.')
            :format(REINTENTOS_CARGA))
        return
    end

    CreateThread(function()
        Wait(ESPERA_REINTENTO)
        --- Si por el camino se cambio de personaje, este Player ya no pinta nada.
        if Player ~= self then return end

        --[[ Y si mientras esperabamos llego una respuesta buena --el servidor
             manda `UpdateInventory` por su cuenta al terminar de cargar-- no hay
             nada que reintentar. ]]
        if next(self.inventory) then return end

        self:LoadInventory(other)
    end)
end

---@return table inventory
function Player_Class:LoadInventory(other)
    TryCatch
        :try(function()
            Bridge.TriggerCallback('origen_inventory:getPlayerInventory', function(data)
                --[[ El servidor contesta una tabla vacia cuando todavia no tiene
                     la instancia del jugador (el framework aun no ha terminado de
                     meter al personaje). Asignar eso tal cual dejaba
                     `self.inventory` en nil PARA SIEMPRE:

                       - `OnPlayerLoad` no vuelve a crear el Player porque ya
                         existe, asi que nadie lo pedia otra vez;
                       - todo lo que recorre el inventario reventaba
                         --`Search`, que el hilo de la radio de origen_police
                         consulta cada cuatro segundos, era el que lo cantaba--;
                       - y el mensaje a la NUI viajaba con `items` sin definir,
                         que es un `Object.values(undefined)` en la interfaz y
                         se lleva por delante el panel entero.

                     De ahi el "no me carga el inventario hasta que me reconecto".
                     Una respuesta sin inventario ya no borra lo que hubiera: se
                     vuelve a pedir. ]]
                if type(data) ~= 'table' or type(data.inventory) ~= 'table' then
                    self:ReintentarCarga(other)
                    return
                end

                self.inventory = data.inventory
                self.slots = data.slots or self.slots
                self.maxWeight = data.maxweight or self.maxWeight
                self.equipedClothes = data.equipedClothes
                self.weight = data.weight or 0
                self.reintentosCarga = nil

                self:UpdateNuiInventory(other)
            end, Config.Framework == 'esx')

            debug:log('info', '^2[ORG_INV]:^0LoadInventory', self.source, self.inventory, self.weight)
        end)
        :catch(function(err)
            debugger('^1', err, '^0')
        end)
        :finally(function()
            if not Inventory.wheelEnabled then
                local setUnarmed = false

                --- Check for weapons
                if self.currentWeapon ~= `WEAPON_UNARMED` then
                    local weapons = self:ReturnWeapons()
                    if #weapons == 0 then
                        setUnarmed = true
                    end

                    for i = 1, #weapons do
                        if GetHashKey(weapons[i].name) == self.currentWeapon then
                            setUnarmed = false
                            break
                        end
                    end
                end

                if setUnarmed then
                    TriggerEvent('origen_inventory:Unarmed')
                end
            end

            debug:log('info', 'Player Inventory Loaded', self.source, self.inventory)
        end)
    return self.inventory
end

function Player_Class:getInventory()
    return self.inventory
end

function Player_Class:hasWeaponOnSlot()
    local weaponItems = self:ReturnWeapons()
    local currentWeapon, currentWeaponSerial, currentWeaponData = Internal__GetCurrentWeapon()
    if not currentWeapon or not currentWeaponSerial or not currentWeaponData then return false end

    for k, weapon in pairs(weaponItems) do
        if not weapon.metadata and not weapon.metadata.serie then goto continue end
        if weapon and weapon.metadata.serie == currentWeaponSerial and weapon.slot == currentWeaponData.slot then
            return true
        end
        ::continue::
    end

    TriggerEvent('origen_inventory:Unarmed')
    return false
end

--- Update Player inventory
--- @param other any
--- @param clearInventory? boolean
function Player_Class:UpdateInventory(other, clearInventory)
    self:LoadInventory(other)

    self:hasWeaponOnSlot()

    if clearInventory then
        TriggerEvent('origen_inventory:Unarmed')
    end
end

function Player_Class:CloseSecondInventory()
    InventoryUI.Emit({
        action = 'closeSecondInventory',
    })

    TriggerServerEvent('origen_inventory:server:onCloseSecondInventory')
end

function Player_Class:UpdateNuiInventory(other)
    local function prepareOtherInventory()
        if not other then return false end
        return {
            type = other.type or 'stash',
            id = other.id or 'player',
            label = other.label or 'Otro inventario',
            slots = other.slots or 12,
            items = other.inventory or other.items or {},
            weight = other.weight or 0,
            maxWeight = other.maxWeight or other.maxweight or self.maxWeight,
            coldStorage = other.coldStorage,
            queue = other.queue or {}
        }
    end

    InventoryUI.Emit({
        action = 'update',
        -- Todo
        inventory = {
            type = 'player',
            inventoryId = 'player',
            label = playerInventoryLabel,
            slots = self.slots,
            items = self.inventory,
            weight = self.weight,
            maxWeight = self.maxWeight,
            equipedClothes = self.equipedClothes,
            clothes = RopaEquipada(),
        },
        secondInventory = prepareOtherInventory()
    }, false, true)
end

function Player_Class:OpenInventory(other)
    --debugger ('^1[ORG_INV]:^3OpenInventory (CHECK) ^0', self.source, json.encode(other, {indent = true}))
    if self.isOpen and (not self.other and other) then return self:UpdateNuiInventory(other) end
    self.other = (other and other.id) or other and true or false
    --[[ Tirado en el suelo o esposado el inventario no se abre. La excepcion
         es el modo SOLO REPORTES, que no abre el inventario: abre la pantalla
         de reportes y nada mas --sin rejilla de objetos, sin accesos y sin
         poder cambiar de pestaña--. Justo cuando estas muerto es cuando mas
         falta hace poder avisar al staff. Ver AbrirReportes. ]]
    if not InventoryUI.soloReportesEntrante and not Bridge.CanOpen() then
        Bridge.Notify(locale:t('notify.inventory_busy'), 'error')
        return
    end

    --[[ Se recuerda mientras el panel este delante: lo miran las acciones de
         objetos para negarse, por si la interfaz llegara a pintar algo. ]]
    self.soloReportes = InventoryUI.soloReportesEntrante == true

    CreateThread(function()
        exports.origen_inventory:checkModules()
    end)

    self.isOpen = true

    --[[ Que el panel esta delante.

         Lo escuchan los HUD que dibujan en la misma zona de la pantalla —el
         rastreador de misiones, sin ir mas lejos, que pinta justo encima de
         la columna— para quitarse de en medio mientras dure. ]]
    TriggerEvent('origen_inventory:abierto', true)

    --[[ Aqui se probo un TriggerScreenblurFadeIn(500) y se quito.

         Desenfoca la PANTALLA ENTERA, no solo lo que hay detras del panel, y
         asi no se puede ver lo que pasa en la partida mientras miras el
         inventario. El fondo se queda nitido a proposito: lo unico que lo
         separa del panel es el velo negro de la NUI. Ver .overlay en
         views/Menu.vue, donde esta contado lo que se probo y por que no. ]]
    DisableEscKey()

    local function prepareOtherInventory()
        if not other then return false end
        return {
            type = other.type or 'stash',
            id = other.id or 'player',
            label = other.label or 'Otro inventario',
            slots = other.slots or 12,
            items = other.inventory or other.items or {},
            weight = other.weight or 0,
            maxWeight = other.maxWeight or other.maxweight or self.maxWeight,
            coldStorage = other.coldStorage,
            queue = other.queue or {}
        }
    end

    -- debugger('^1[ORG_INV]:^3OpenInventory (V2) ^0', json.encode(other, { indent = true }))
    InventoryUI.Open({
        -- Todo
        type = 'player',
        id = 'player',
        label = playerInventoryLabel,
        slots = self.slots,
        items = self.inventory,
        weight = self.weight,
        maxWeight = self.maxWeight,
        equipedClothes = self.equipedClothes,
        clothes = RopaEquipada(),
        secondInventory = prepareOtherInventory(),
    })

    local playerPed = PlayerPedId()
    local isOnVehicle = IsPedInAnyVehicle(playerPed, false)
    local isDriver = isOnVehicle and GetPedInVehicleSeat(GetVehiclePedIsIn(playerPed, false), -1) == playerPed
    InventoryUI.UpdateVehicleState(isOnVehicle, isDriver)

    NUIFocus(true, true)
end

--[[ `mantenerFoco` es para el relevo con otro panel (admin, banda, negocio).
     Ahi el panel nuevo ya ha pedido el foco para si antes de que este se
     retire, asi que soltarlo aqui se lo quitaria a el y el raton se quedaria
     en una NUI que ya no se ve. Para el cierre normal no se pasa y el foco se
     suelta como siempre. ]]
function Player_Class:CloseInventory(isServer, isNui, remote, mantenerFoco)
    debugger("[PlayerInstance] Closing inventory:", isServer, isNui, self.other or self.activeDrop)

    local hasPrevOther = self.other

    --[[ EL FOCO SE SUELTA ANTES QUE NADA, y por fuera del antirrebote de mas
         abajo.

         Ese `nextUpdate` se come la llamada ENTERA si han pasado menos de un
         segundo desde el ultimo cierre, y hasta ahora eso incluia el
         SetNuiFocus. Dos cierres seguidos --saltar a otro panel del riel y
         volver, que son dos clics- dejaban el raton puesto en pantalla y
         ningun panel delante: el segundo cierre se descartaba entero y nadie
         soltaba nada.

         Quedarse sin panel se arregla volviendo a abrir. Quedarse sin camara,
         no: hay que reconectar. Asi que esto va primero y sin guardas. ]]
    if not mantenerFoco then
        NUIFocus(false, false)
        SetNuiFocusKeepInput(false)
    end

    --[[ El antirrebote de un segundo solo corta el aviso al servidor, y solo
         si el inventario ya estaba cerrado.

         Existe por el eco: un cierre que no viene de la NUI hace que el
         servidor conteste con origen_inventory:client:CloseInventory, que
         vuelve a entrar aqui sin argumentos y le avisaria otra vez, y asi sin
         fin.

         Antes era un `return` que se llevaba todo lo de abajo. El segundo de
         dos cierres seguidos no llegaba ni a decirle a la NUI que se fuera:
         la pantalla puesta, `isOpen` en true y el foco ya suelto. Lo de aqui
         es local y repetirlo no hace daño, asi que va siempre. Y el cierre de
         un inventario que SI estaba abierto se le cuenta al servidor siempre:
         cerrar un alijo, abrir otro y cerrarlo antes del segundo lo dejaria
         abierto alli. ]]
    local repetido = not self.isOpen and self.nextUpdate > GetGameTimer()
    if not repetido then self.nextUpdate = GetGameTimer() + 1000 end

    self.isOpen = false
    -- El modo solo reportes vale para UNA apertura, no se queda puesto.
    self.soloReportes = false

    TriggerEvent('origen_inventory:abierto', false)

    -- Aqui no hay desenfoque que quitar: no se pone ninguno al abrir. Ver el
    -- comentario de OpenInventory.

    ---@diagnostic disable-next-line: inject-field
    Player.inloop = false
    self.other = false

    if not mantenerFoco then
        NUIFocus(false, false)

        if Config.UI.DelayNuiFocusForTabKey then
            CreateThread(function()
                Wait(300)
                SetNuiFocusKeepInput(false)
                SetNuiFocus(true, false)
                NUIFocus(false, false)
            end)
        end
    else
        --[[ Con `mantenerFoco` no se toca SetNuiFocus, que es de quien coge el
             relevo. Pero KeepInput SI hay que apagarlo: ese lo encendimos
             nosotros al abrir —para poder andar y hablar mientras miras el
             inventario— y lo compensabamos con el bucle DisableKeys, que se
             para aqui mismo al poner isOpen = false.

             Dejarlo encendido era dejar el interruptor puesto y a nadie
             apagando controles: en el panel que entraba, el raton movia la
             camara y al pulsar un boton el personaje pegaba un puñetazo. El
             que entra ya ha declarado el foco que quiere antes de llegar
             aqui, y ninguno de los del riel quiere teclas para el juego. ]]
        SetNuiFocusKeepInput(false)
    end


    if not isNui then
        InventoryUI.Emit({
            action = 'close',
        })
    end

    if CurrentVehicle then
        CloseTrunkAnim()
        CurrentVehicle = nil
    end

    if not repetido and (not isServer or hasPrevOther and not remote) then
        local otherId = ""
        if type(hasPrevOther) == 'string' then
            ---@diagnostic disable-next-line: cast-local-type
            otherId = hasPrevOther
        else
            ---@diagnostic disable-next-line: undefined-field
            otherId = hasPrevOther?.id
        end
        TriggerServerEvent('origen_inventory:server:Close', nil, isNui, otherId or self.activeDrop)
    end

    TriggerEvent('origen_hud:client:hideVehicleHud', false)

    return true
end

function Player_Class:setInUse(state)
    self.inUse = state
end

function Player_Class:GetClosestPlayer()
    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed)
    local players = GetActivePlayers()
    local closestPlayer, closestDistance = nil, -1
    for _, player in ipairs(players) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(pos - targetCoords)
            if closestDistance == -1 or distance < closestDistance then
                closestPlayer, closestDistance = player, distance
            end
        end
    end
    return closestPlayer, closestDistance
end

function Player_Class:setActiveDrop(drop)
    self.activeDrop = drop
end
