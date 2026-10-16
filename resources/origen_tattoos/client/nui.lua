--[[ ══ «MIS TATUAJES» · los comprados en la tienda de cosméticos (13/10) ══════
     La verdad está en origen_vipsystem. Aquí: pedir la lista (TiendaLista), probar uno
     sobre el personaje con la cámara en su sitio (TiendaVer) y mandar la orden de
     ponérselo, quitárselo o cambiar el acabado (TiendaPoner). Todo gratis: ya son suyos. ]]
local TIENDA = 'origen_vipsystem'
local misTienda = {}      -- la última lista del servidor: { { id, ocupa, decoraciones, camara, giro, … } }
local giroTienda = 0.0    -- lo que se ha girado al personaje para enseñar un sitio (se deshace al salir)

local function QuitarGiroTienda()
    if giroTienda ~= 0.0 then
        local ped = PlayerPedId()
        SetEntityHeading(ped, (GetEntityHeading(ped) - giroTienda) % 360.0)
        giroTienda = 0.0
    end
end

--- Fuera del apartado: ni vista previa de la tienda ni personaje girado
function SalirDeTienda()
    enApartadoTienda = false
    PreviaExtra = nil
    QuitarGiroTienda()
end

local function DeTienda(id)
    for _, t in ipairs(misTienda) do
        if t.id == id then return t end
    end
end

local function Chocan(a, b)
    for _, x in ipairs(a.ocupa or {}) do
        for _, y in ipairs(b.ocupa or {}) do
            if x == y then return true end
        end
    end
    return false
end

--- Lo que llevaría de la tienda si se pusiera `este` con ese acabado: lo suyo puesto, menos lo que
--- va en el mismo sitio, más él. (Solo para enseñarlo: ponérselo de verdad lo decide el servidor.)
local function ListaDePrueba(este, acabado)
    local lista = {}
    local function Meter(t, a)
        for _, d in ipairs((t.decoraciones or {})[a] or {}) do
            lista[#lista + 1] = { collection = d.c, base = d.b, opacity = math.max(1, math.min(4, math.floor(tonumber(d.n) or 1))) }
        end
    end
    for _, t in ipairs(misTienda) do
        if t.puesto and t.id ~= este.id and not Chocan(t, este) then Meter(t, t.acabado) end
    end
    Meter(este, acabado == 'negro' and 'negro' or 'color')
    return lista
end

local function PedirTienda()
    if GetResourceState(TIENDA) ~= 'started' then misTienda = {} return misTienda end
    local lista = lib.callback.await('origen_tattoos:server:TiendaLista', 6000)
    misTienda = type(lista) == 'table' and lista or {}
    return misTienda
end

-- La lista (vacía = el apartado no se enseña) y de dónde se sirven las fotos de la tienda
RegisterNUICallback('TiendaLista', function(_, cb)
    cb({ lista = PedirTienda(), fotos = 'https://cfx-nui-' .. TIENDA .. '/web/dist/' })
end)

-- Entrar o salir del apartado
RegisterNUICallback('TiendaApartado', function(data, cb)
    if data and data.dentro then
        enApartadoTienda = true
        SetCamera('torso')
    else
        SalirDeTienda()
    end
    ApplyPlayerTattos()
    cb('ok')
end)

-- Probarse uno: cámara a su zona, el personaje girado hacia ella y el tatuaje pintado. Sin id: se suelta.
RegisterNUICallback('TiendaVer', function(data, cb)
    local t = type(data) == 'table' and DeTienda(data.id) or nil
    if not t then
        PreviaExtra = nil
        ApplyPlayerTattos()
        return cb('ok')
    end
    PreviaExtra = { quien = TIENDA, lista = ListaDePrueba(t, data.acabado) }
    ApplyPlayerTattos()
    -- la cámara se coloca delante del personaje: primero se le pone de frente, luego se le gira al sitio
    if data.mover ~= false then
        QuitarGiroTienda()
        SetCamera(Config.Cameras[t.camara] and t.camara or 'torso')
        giroTienda = (tonumber(t.giro) or 0.0) % 360.0
        if giroTienda ~= 0.0 then
            local ped = PlayerPedId()
            SetEntityHeading(ped, (GetEntityHeading(ped) + giroTienda) % 360.0)
        end
    end
    cb('ok')
end)

-- Ponérselo, quitárselo o cambiar el acabado: lo decide el servidor de la tienda
RegisterNUICallback('TiendaPoner', function(data, cb)
    local res = lib.callback.await('origen_tattoos:server:TiendaPoner', 8000, {
        id = data and data.id, puesto = data and data.puesto == true, acabado = data and data.acabado, pieza = data and data.pieza,
    })
    if type(res) ~= 'table' then res = { ok = false, msg = 'El servidor no ha contestado a tiempo.' } end
    if res.msg then
        lib.notify({ title = 'Mis tatuajes', description = res.msg, type = res.ok and 'success' or 'error' })
    end
    if res.ok then
        misTienda = type(res.lista) == 'table' and res.lista or {}
        -- ya es de verdad: fuera la prueba (lo que lleva llega por la tienda y se repinta solo)
        PreviaExtra = nil
        ApplyPlayerTattos()
    end
    cb({ ok = res.ok == true, lista = misTienda })
end)

RegisterNUICallback("SetupCam", function(data, cb)
    SalirDeTienda()
    local part = data.part
    local title = Config.ZoneLabels[part]
    SetCamera(part)
    cb({
        title = title,
        tattoos = {AppliedTattoos},
        gender = GetGender()
    })
end)

RegisterNUICallback("PreviewTattoo", function(data, cb)
    PreviewTattoo(data)

    cb('ok')
end)

RegisterNUICallback("BackMenu",function(data, cb)
    SetCamera('default')
    ApplyPlayerTattos()

    cb('ok')
end)

RegisterNUICallback("BuyTattoo",function(data, cb)
    if AppliedTattoos[data.hash] then
        lib.notify({
            title = 'Tatuajes',
            description = 'Ya tienes este tatuaje',
            type = 'error'
        })
        cb(false)
        return
    end

    local paymentMethod = data.paymentMethod
    if paymentMethod ~= 'cash' and paymentMethod ~= 'bank' then
        lib.notify({
            title = 'Tatuajes',
            description = 'Elige efectivo o tarjeta para pagar',
            type = 'error'
        })
        cb(false)
        return
    end

    local store = currentStore or data.storeIndex
    store = tonumber(store) or store
    if not store then
        lib.notify({
            title = 'Tatuajes',
            description = 'Error: tienda no disponible',
            type = 'error'
        })
        cb(false)
        return
    end

    if not currentStore then
        currentStore = store
    end

    -- El servidor comprueba, cobra y apunta la compra; del tatuaje solo se le dicen
    -- las pasadas y el nombre. Al tatuador también lo mueve él.
    local result = lib.callback.await('origen_tattoos:server:BuyTattoo', false, data.hash, store, paymentMethod, {
        opacity = data.opacity,
        name = data.name,
    })

    if not result then
        cb(false)
        return
    end

    StartTattooSequence(store, function(endTattoo)
        -- Acabe como acabe la escena, ya está cobrado: el servidor gasta la compra
        -- apuntada y pone el tatuaje.
        TriggerServerEvent('origen_tattoos:server:BuyTattoo')
        if endTattoo then
            lib.notify({
                title = 'Tatuajes',
                -- Cifra con punto de miles y el $ detrás, como en el resto del servidor.
                description = ('Has comprado «%s» por %s $'):format(tostring(data.name or 'el tatuaje'),
                    tostring(math.floor(tonumber(data.price) or 0)):reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')),
                type = 'success'
            })
        else
            lib.notify({
                title = 'Tatuajes',
                description = 'La sesión se ha cortado, pero el tatuaje ya estaba pagado: lo llevas puesto',
                type = 'inform'
            })
        end
        cb(true)
    end)
end)

RegisterNUICallback("RemoveTattoo",function(data, cb)
    if not AppliedTattoos[data.hash] then
        cb(false)
        return
    end
    TriggerServerEvent('origen_tattoos:server:RemoveTattoo', data.hash)
    lib.notify({
        title = 'Tatuajes',
        description = 'Te has eliminado el tatuaje',
        type = 'success'
    })
    cb(true)
end)

RegisterNUICallback("handsUp",function(data, cb)
    local dict = "missminuteman_1ig_2"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
    if not handsup then
        TaskPlayAnim(PlayerPedId(), dict, "handsup_enter", 8.0, 8.0, -1, 50, 0, false, false, false)
        handsup = true
    else
        handsup = false
        ClearPedTasks(PlayerPedId())
    end
    
    cb('ok')
end)

RegisterNUICallback('Rotate', function(data, cb)
    local direction = data.direction
    local ped = PlayerPedId()
    local heading = GetEntityHeading(ped)
    if direction == 'left' then
        SetEntityHeading(ped, heading - 30)
    else
        SetEntityHeading(ped, heading + 30)
    end
    
    cb('ok')
end)

RegisterNUICallback("Zoom",function(data, cb)
    -- Sin camara se contesta igual: una peticion sin respuesta deja la NUI
    -- esperando.
    if cameraHandle == nil then return cb('ok') end
    local camFov = GetCamFov(cameraHandle)
    if data.action == 'zoom' then 
        SetCamFov(cameraHandle, camFov + 5)
    else
        if camFov > 50 then
            SetCamFov(cameraHandle, camFov - 5)
        end
    end
    
    cb('ok')
end)

RegisterNUICallback('CloseNui', function(data, cb)
    CloseMenu()
    cb("ok")
end)

RegisterNUICallback('GetMyTattoos', function(data, cb)
    local formattedTattoos = {}
    
    for hash, tattooData in pairs(AppliedTattoos) do
        local tattooInfo = nil
        for _, tattoo in pairs(TattooLists) do
            if tattoo.hashMale == hash or tattoo.hashFemale == hash then
                tattooInfo = tattoo
                break
            end
        end
        
        table.insert(formattedTattoos, {
            id = hash,
            name = tattooInfo and tattooInfo.name or tattooData.name or 'Tatuaje',
            zone = tattooData.zone or 'ZONE_TORSO',
            collection = tattooData.collection
        })
    end
    
    cb({
        tattoos = {formattedTattoos}
    })
end)

RegisterNUICallback('GetPurchaseHistory', function(data, cb)
    local history = lib.callback.await('origen_tattoos:server:GetPurchaseHistory', false)

    cb({
        history = history or {}
    })
end)

RegisterNUICallback('getAppliedTattoos', function(data, cb)
    cb({
        tattoos = {AppliedTattoos}
    })
end)
