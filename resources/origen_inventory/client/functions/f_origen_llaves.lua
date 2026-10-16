--[[
    La pestaña de Llaves.

    Era el panel de la K de qbx_vehiclekeys: una ventana propia, negra, que
    solo se dejaba abrir estando pegado a un coche tuyo. Compartir llaves lo
    hace TODO el mundo y varias veces por sesion, asi que estaba escondida
    detras de una tecla que casi nadie sabia que existia.

    Ahora es una pestaña mas del riel, como Ciudad o Misiones: se abre donde
    estes, enseña tus llaves, a quien se las has prestado y quien te ha
    prestado las suyas, y compartir es elegir llave, elegir persona y pulsar.

    Aqui no hay logica de llaves. Quien tiene cada llave lo saben
    qbx_vehiclekeys (las de la sesion, por sessionId) y origen_garages (las
    prestadas, que son las que quedan escritas en la base). Este fichero es
    solo el cable entre esas dos puertas y la interfaz; si una de las dos no
    esta en marcha, la pestaña lo dice en vez de reventar.
]]

local LLAVES = 'qbx_vehiclekeys'
local GARAJES = 'origen_garages'

local function Vivo(recurso)
    return GetResourceState(recurso) == 'started'
end

--[[ El nombre del coche.

     GetLabelText devuelve 'NULL' con los modelos que no traen traduccion, y
     ahi es mejor el nombre interno (BF400) que la palabra NULL en pantalla. ]]
local function NombreDeModelo(hash)
    if not hash then return 'Vehículo' end
    local interno = GetDisplayNameFromVehicleModel(hash)
    if not interno or interno == '' or interno == 'CARNOTFOUND' then return 'Vehículo' end
    local label = GetLabelText(interno)
    if not label or label == '' or label == 'NULL' then return interno end
    return label
end

--- car / bike / van / boat: es lo unico que distingue el icono de la ficha.
local function TipoDeVehiculo(vehicle)
    if not vehicle or vehicle == 0 then return 'car' end
    local clase = GetVehicleClass(vehicle)
    if clase == 8 or clase == 13 then return 'bike' end
    if clase == 14 then return 'boat' end
    if clase == 11 or clase == 12 then return 'van' end
    return 'car'
end

--- La entidad de un netId, o 0 si ese coche no esta cargado aqui.
local function EntidadDe(netId)
    netId = tonumber(netId)
    if not netId then return 0 end
    if not NetworkDoesNetworkIdExist(netId) then return 0 end
    local veh = NetToVeh(netId)
    if veh == 0 or not DoesEntityExist(veh) then return 0 end
    return veh
end

--[[ Donde esta, en palabras.

     La interfaz enseña esta linea tal cual y no hace cuentas: aqui es donde
     se sabe si el coche esta cargado --si no lo esta, no hay distancia que
     dar, y decir "a 0 m" seria mentir--. ]]
local function DondeEsta(vehicle, dist)
    if vehicle == 0 then return 'no está cerca' end
    if not dist then return 'por aquí cerca' end
    if dist < 1 then return 'justo al lado' end
    if dist < 1000 then return ('a %d m'):format(math.floor(dist + 0.5)) end
    return ('a %.1f km'):format(dist / 1000)
end

--- El candado, para pintarlo cerrado o abierto. Sale del statebag del coche,
--- que es de donde lo lee tambien la L.
local function EstaCerrado(vehicle)
    if vehicle == 0 then return nil end
    local estado = Entity(vehicle).state.doorslockstate
    if estado == nil then
        estado = GetVehicleDoorLockStatus(vehicle)
    end
    return estado == 2
end

--- Llamar a un callback de otro recurso sin que un fallo suyo tumbe la pestaña.
local function Pedir(recurso, nombre, ...)
    if not Vivo(recurso) then return nil end
    local args = table.pack(...)
    local ok, valor = pcall(function()
        return lib.callback.await(nombre, false, table.unpack(args, 1, args.n))
    end)
    if not ok then
        print(('^1[llaves]^0 %s fallo: %s'):format(nombre, tostring(valor)))
        return nil
    end
    return valor
end

--[[ Lo que se ve al entrar.

     Tres origenes que la interfaz recibe ya mezclados:
       · qbx_vehiclekeys   el coche de delante, tus llaves de sesion y la
                           gente que tienes al lado, con su nombre de personaje
       · origen_garages    lo prestado y lo recibido, que vive en la base
       · el propio cliente la distancia, el candado y el tipo de cada coche,
                           que solo se saben teniendo la entidad a mano ]]
InventoryUI.On('GetLlaves', function()
    if not Vivo(LLAVES) then return { hay = false } end

    -- El de delante se pide por netId para que sea el que ves: si vas dentro
    -- de uno, es ese; si no, el mas cercano.
    local yo = cache.ped or PlayerPedId()
    local dentro = GetVehiclePedIsIn(yo, false)
    if dentro == 0 then
        dentro = lib.getClosestVehicle(GetEntityCoords(yo), 6.0, true) or 0
    end
    local netDelante = dentro ~= 0 and NetworkGetNetworkIdFromEntity(dentro) or nil

    local datos = Pedir(LLAVES, 'qbx_vehiclekeys:server:getKeysPanel', netDelante)
    if type(datos) ~= 'table' then return { hay = false } end

    local misCoords = GetEntityCoords(yo)
    local frente = datos.vehicle and tonumber(datos.vehicle.netId) or nil

    local llaves = {}
    for _, k in ipairs(datos.ownedKeys or {}) do
        local veh = EntidadDe(k.netId)
        local dist = veh ~= 0 and #(misCoords - GetEntityCoords(veh)) or nil
        local esElDeDelante = frente ~= nil and tonumber(k.netId) == frente

        llaves[#llaves + 1] = {
            netId = k.netId,
            plate = (k.plate or ''):gsub('%s+$', ''),
            nombre = NombreDeModelo(k.model),
            tipo = TipoDeVehiculo(veh),
            dist = dist,
            --[[ El de delante lleva, ademas de donde esta, que esta delante:
                 es lo que lo separa de los otros tres que tienes a 200 m. ]]
            donde = esElDeDelante and (DondeEsta(veh, dist) .. ', delante de ti') or DondeEsta(veh, dist),
            cerrado = EstaCerrado(veh),
            delante = esElDeDelante,
        }
    end

    -- Los mas cerca primero: es el orden en el que se buscan con la vista.
    table.sort(llaves, function(a, b)
        if a.delante ~= b.delante then return a.delante end
        return (a.dist or 1e9) < (b.dist or 1e9)
    end)

    local gente = {}
    for _, p in ipairs(datos.nearbyPlayers or {}) do
        gente[#gente + 1] = {
            id = p.id,
            nombre = p.name,
            linea = p.dist and ('a %d m'):format(math.floor(p.dist + 0.5)) or 'cerca',
        }
    end

    --[[ Lo prestado y lo recibido son de origen_garages y no de la sesion:
         una llave dada se queda escrita, asi que sale aqui aunque el coche
         este guardado y no exista ninguna entidad suya. Por eso su nombre
         viene de la base y no del modelo que haya en la calle. ]]
    local prestadas, recibidas = {}, {}

    for _, k in ipairs(Pedir(GARAJES, 'origen_garages:cb:getLentKeys') or {}) do
        local nombre = k.vehicleLabel
        if (not nombre or nombre == '' or nombre == 'Vehículo') and k.modelHash then
            nombre = NombreDeModelo(k.modelHash)
        end
        prestadas[#prestadas + 1] = {
            plate = k.plate,
            vehiculo = nombre or 'Vehículo',
            quien = k.targetName or 'Alguien',
            citizen = k.targetCitizen,
        }
    end

    for _, k in ipairs(Pedir(GARAJES, 'origen_garages:cb:getBorrowedKeys') or {}) do
        local nombre = k.vehicleLabel
        if (not nombre or nombre == '' or nombre == 'Vehículo') and k.modelHash then
            nombre = NombreDeModelo(k.modelHash)
        end
        recibidas[#recibidas + 1] = {
            plate = k.plate,
            vehiculo = nombre or 'Vehículo',
            quien = k.ownerName or 'Alguien',
        }
    end

    return {
        hay = true,
        delante = frente,
        --[[ Por que NO hay coche delante: "no hay ninguno cerca" y "ese no es
             tuyo" son dos cosas distintas, y el jugador tiene que poder
             distinguirlas sin salir a mirar. ]]
        aviso = datos.message,
        llaves = llaves,
        gente = gente,
        prestadas = prestadas,
        recibidas = recibidas,
    }
end)

--[[ Dar una llave.

     Se manda el netId y el id del jugador, y es el servidor de llaves quien
     comprueba las dos cosas que importan: que la llave es tuya y que esa
     persona esta de verdad al lado. Lo que la interfaz tenga pintado no
     prueba nada --pudo alejarse mientras elegias--. ]]
InventoryUI.On('LlaveDar', function(datos)
    local netId = tonumber(datos and datos.netId)
    local targetId = tonumber(datos and datos.targetId)
    if not netId or not targetId then
        return { ok = false, mensaje = 'Falta la llave o la persona' }
    end

    local r = Pedir(LLAVES, 'qbx_vehiclekeys:server:transferKeysToPlayer', netId, targetId)
    if type(r) ~= 'table' then
        return { ok = false, mensaje = 'No se ha podido dar la llave' }
    end
    return { ok = r.success == true, mensaje = r.message }
end)

--- Quitarle una llave a quien se la prestaste. Solo lo deja origen_garages al
--- que la dio o al dueño del coche; aqui no se decide nada.
InventoryUI.On('LlaveQuitar', function(datos)
    local plate = datos and datos.plate
    local citizen = datos and datos.citizen
    if not plate or not citizen or not Vivo(GARAJES) then
        return { ok = false, mensaje = 'Faltan datos de la llave' }
    end

    local ok, mensaje = lib.callback.await('origen_garages:cb:revokeKeyRemotely', false, plate, citizen)
    return { ok = ok == true, mensaje = mensaje }
end)

--- Devolver una que te prestaron.
InventoryUI.On('LlaveDevolver', function(datos)
    local plate = datos and datos.plate
    if not plate or not Vivo(GARAJES) then
        return { ok = false, mensaje = 'Faltan datos de la llave' }
    end

    local ok, mensaje = lib.callback.await('origen_garages:cb:returnKeyRemotely', false, plate)
    return { ok = ok == true, mensaje = mensaje }
end)

--[[ El candado de una llave: lo mismo que pulsar la L, pero sobre el coche
     que has elegido en la lista y no sobre el mas cercano.

     Quien decide si se puede es qbx_vehiclekeys --llaves y distancia--; si
     dice que no, aqui se devuelve el candado como estaba, para que la interfaz
     no se quede pintando lo contrario de lo que pasa. ]]
InventoryUI.On('LlaveCerradura', function(datos)
    local netId = tonumber(datos and datos.netId)
    if not netId or not Vivo(LLAVES) then return { ok = false } end

    local antes = EstaCerrado(EntidadDe(netId))

    local ok, hecho = pcall(function()
        return exports[LLAVES]:ToggleLockNet(netId)
    end)
    if not ok or hecho == false then return { ok = false } end

    --[[ El cierre da la vuelta por el servidor (animacion, evento y statebag).
         Antes se leia a los 250 ms fijos y casi siempre llegaba el candado de
         ANTES: la interfaz no cambiaba hasta cerrar y abrir. Ahora se espera a
         que cambie, hasta dos segundos; si no cambia —sin llaves, por
         ejemplo— se devuelve como esta. ]]
    local veh, cerrado = 0, antes
    for _ = 1, 20 do
        Wait(100)
        veh = EntidadDe(netId)
        cerrado = EstaCerrado(veh)
        if veh == 0 or cerrado ~= antes then break end
    end
    return { ok = veh ~= 0, cerrado = cerrado }
end)

--[[ Marcar un coche en el mapa. Sin netId se entiende que es desmarcar, igual
     que el "Marcar" de la lista de locales de Ciudad. ]]
InventoryUI.On('LlaveMarcar', function(datos)
    local netId = tonumber(datos and datos.netId)
    if not netId then
        SetWaypointOff()
        return { ok = true }
    end

    local veh = EntidadDe(netId)
    if veh == 0 then return { ok = false, mensaje = 'Ese vehículo no está cerca' } end

    local c = GetEntityCoords(veh)
    -- Con comprobacion, no a secas: ver MapaPonerWaypoint en f_origen_mapa.lua.
    CreateThread(function() MapaPonerWaypoint(c.x, c.y) end)
    return { ok = true }
end)
