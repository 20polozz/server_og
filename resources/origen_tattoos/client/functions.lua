local isCameraInterpolating
local currentCamera
local savedClothes = {}

cameraHandle = nil
openedMenu = false

local lastCoords = nil
local lastCam = nil
currentStore = nil
createdNpcs = {}
propsCreated = {}

function GetTattoosList()
    local p = promise:new()
    lib.callback('origen_tattoos:server:GetTattoosList', false, function(TattooLists)
        local data = {}
        local sinNombre = 0
        for k, v in pairs(TattooLists) do
            -- El nombre sale del idioma del juego. Si la etiqueta no existe se
            -- enseñaba la clave cruda (TAT_AR_000): ahora «Tatuaje N», con el
            -- número de la clave si lo tiene.
            local labelName = v.name and GetLabelText(v.name) or 'NULL'
            if labelName == 'NULL' or labelName == '' then
                local num = v.name and tonumber(tostring(v.name):match('(%d+)$'))
                if num then
                    labelName = ('Tatuaje %d'):format(num + 1)
                else
                    sinNombre = sinNombre + 1
                    labelName = ('Tatuaje %d'):format(sinNombre)
                end
            end
            data[#data+1] = {
                zone = v.zone,
                name = labelName,
                price = (v.price and v.price > 0) and v.price or 0,
                collection = v.collection,
                hashFemale = v.hashFemale,
                hashMale = v.hashMale,
                custom = v.custom or false,
                blocked = checkBlockedTattoos(v.name, v.hashFemale, v.hashMale)
            }
        end
        p:resolve(data)
    end)
    return Citizen.Await(p)
end

function checkBlockedTattoos(tattoo, hash1, hash2)
    for hash, cids in pairs(Config.BlockedTattoos) do
        if hash == hash1 or hash == hash2 then
            return cids
        end
    end
    return false
end

function GetPlayerTattoos()
    local tattoos = lib.callback.await('origen_tattoos:server:GetPlayerTattoos', false)
    return tattoos
end

--[[ Tatuajes que pone OTRO recurso (13/10): los de la tienda de cosméticos
     (origen_vipsystem). No son del tatuador —ni se guardan aquí ni se venden ni
     se borran aquí—, pero este recurso repinta al personaje cada segundo y al
     hacerlo borraría lo que pintase nadie más: por eso se le pasan y los pinta él,
     junto a los suyos.

       exports.origen_tattoos:PonerTatuajesExtra(quien, lista)
         quien  nombre del recurso que los pone (cada uno, su lista)
         lista  { { collection = '…', base = 'nombre sin _m/_f' | id = 'nombre entero', opacity = pasadas }, … }
                (nil o vacía: quita los de ese recurso)

     Con `base`, el sufijo de hombre o mujer se pone al pintar, según el modelo que
     lleve en ese momento. ]]
local TatuajesExtra = {}
local MODELO_MUJER = GetHashKey('mp_f_freemode_01')

--[[ «Mis tatuajes» del menú: mientras se prueba uno de la tienda, en vez de lo que lleva
     de ese recurso se pinta `PreviaExtra.lista` (lo que quedaría si se lo pusiera). ]]
PreviaExtra = nil          -- { quien = 'recurso', lista = { … } }
enApartadoTienda = false   -- el menú está en «Mis tatuajes»: los cambios de la tienda se repintan al llegar

local function PintarTatuajesExtra(ped)
    if next(TatuajesExtra) == nil and not PreviaExtra then return end
    local sufijo = GetEntityModel(ped) == MODELO_MUJER and '_f' or '_m'
    local listas = {}
    for quien, lista in pairs(TatuajesExtra) do listas[quien] = lista end
    if PreviaExtra then listas[PreviaExtra.quien] = PreviaExtra.lista end
    for _, lista in pairs(listas) do
        for _, t in ipairs(lista) do
            local coleccion, nombre = GetHashKey(t.collection), GetHashKey(t.base and (t.base .. sufijo) or t.id)
            for _ = 1, t.opacity do
                SetPedDecoration(ped, coleccion, nombre)
            end
        end
    end
end

function PonerTatuajesExtra(quien, lista)
    if type(quien) ~= 'string' or quien == '' then return false end
    local limpia = {}
    for _, t in ipairs(type(lista) == 'table' and lista or {}) do
        local nombre = type(t) == 'table' and (t.base or t.id) or nil
        if #limpia < 60 and type(nombre) == 'string' and #nombre <= 80 and type(t.collection) == 'string' and #t.collection <= 80 then
            limpia[#limpia + 1] = {
                collection = t.collection, base = type(t.base) == 'string' and t.base or nil, id = type(t.id) == 'string' and t.id or nil,
                opacity = math.max(1, math.min(5, math.floor(tonumber(t.opacity) or 1))),
            }
        end
    end
    TatuajesExtra[quien] = #limpia > 0 and limpia or nil
    -- se ve al momento (con el menú del tatuador abierto solo si está en «Mis tatuajes»: en una zona hay una vista previa puesta)
    if LocalPlayer.state.isLoggedIn and (not openedMenu or enApartadoTienda) then ApplyPlayerTattos() end
    return true
end

exports('PonerTatuajesExtra', PonerTatuajesExtra)

-- Si el recurso que los puso se para, sus tatuajes se van con él
AddEventHandler('onClientResourceStop', function(recurso)
    if TatuajesExtra[recurso] then
        TatuajesExtra[recurso] = nil
        if LocalPlayer.state.isLoggedIn and not openedMenu then ApplyPlayerTattos() end
    end
end)

function ApplyPlayerTattos()
    local ped = PlayerPedId()
    ClearPedDecorations(ped)
    -- primero los de otros recursos: los del tatuador van encima (y su bucle puede cortarse antes de acabar)
    PintarTatuajesExtra(ped)
    for _, tattoo in pairs(AppliedTattoos) do
        if not tattoo then return end
        if tattoo.opacity ~= nil then
            for i = 1, tattoo.opacity do
                SetPedDecoration(ped, tattoo.collection, tattoo.id)
            end
        else
            SetPedDecoration(ped, tattoo.collection, tattoo.id)
        end
    end
end

function SetPedTattos(ped, tattoos)
    ClearPedDecorations(ped)
    for _, tattoo in pairs(tattoos) do
        if not tattoo then return end
        if tattoo.opacity ~= nil then
            for i = 1, tattoo.opacity do
                SetPedDecoration(ped, tattoo.collection, tattoo.id)
            end
        else
            SetPedDecoration(ped, tattoo.collection, tattoo.id)
        end
    end
end

exports('SetPedTattos', SetPedTattos)

function PreviewTattoo(data)
    local ped = PlayerPedId()
    ClearPedDecorations(ped)

    ApplyPlayerTattos()

    if not data then return end

    if data.opacity ~= nil then
        for i = 1, data.opacity do
            SetPedDecoration(ped, data.collection, data.hash)
        end
    else
        SetPedDecoration(ped, data.collection, data.hash)
    end
end

function OpenMenu(store)
    if openedMenu then
        return
    end

    local myTattoos = {AppliedTattoos}
    
    SendNUIMessage({
        action = 'show',
        tattoos = TattooLists,
        cid = QBX.PlayerData.citizenid,
        storeIndex = store,
        myTattoos = myTattoos
    })
    
    LocalPlayer.state.hide_props = true
    SetNuiFocus(true, true)
    SetCamera('head')
    RenderScriptCams(true, false, 0, true, true)
    openedMenu = true
    currentStore = store
    HideClothes()

    exports.origen_hud:setupControls({
        {
            key = 'wheel',
            text = 'Rotar',
        },
        {
            key = 'C',
            text = 'Acercar',
        },
        {
            key = 'Z',
            text = 'Alejar',
        },
    })
end

function CloseMenu()
    SetNuiFocus(false, false)
    openedMenu = false
    SalirDeTienda()
    SendNUIMessage({action = 'hide'})
    -- En pcall: con origen_hud parado el export revienta y se quedaban la
    -- camara y la ropa de la tienda.
    pcall(function() exports.origen_hud:hideControls() end)
    FinishCam()
    ResetSkin()
    currentStore = nil
end

function ToggleMenu(state)
    if not openedMenu then return end
    SendNUIMessage({
        action = 'toggle',
        state = state
    })
    SetNuiFocus(state, state)
    if state then
        exports.origen_hud:setupControls({
            {
                key = 'wheel',
                text = 'Rotar',
            },
            {
                key = 'C',
                text = 'Acercar',
            },
            {
                key = 'Z',
                text = 'Alejar',
            },
        })
    else
        exports.origen_hud:hideControls()
    end
end

function GetGender()
    local body = 'male'
    local model = GetEntityModel(PlayerPedId())
    if model == GetHashKey("mp_f_freemode_01") then
        body = 'female'
    end
    return body
end

function SetCamera(key)
    if not isCameraInterpolating then
        local ped = PlayerPedId()
        if key ~= "current" then
            currentCamera = key
        end

        local coords, point = table.unpack(Config.Cameras[currentCamera])
        local reverseFactor = reverseCamera and -1 or 1

        if cameraHandle then
            local camCoords = GetOffsetFromEntityInWorldCoords(ped, coords.x * reverseFactor, coords.y * reverseFactor, coords.z * reverseFactor)
            local camPoint = GetOffsetFromEntityInWorldCoords(ped, point.x, point.y, point.z)
            local tmpCamera = CreateCameraWithParams("DEFAULT_SCRIPTED_CAMERA", camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0, 49.0, false, 0)

            PointCamAtCoord(tmpCamera, camPoint.x, camPoint.y, camPoint.z)
            SetCamActiveWithInterp(tmpCamera, cameraHandle, 1000, 1, 1)

            isCameraInterpolating = true

            CreateThread(function()
                repeat Wait(100)
                until not IsCamInterpolating(cameraHandle) and IsCamActive(tmpCamera)
                DestroyCam(cameraHandle, false)
                cameraHandle = tmpCamera
                isCameraInterpolating = false
            end)
        else
            local camCoords = GetOffsetFromEntityInWorldCoords(ped, coords.x, coords.y, coords.z)
            local camPoint = GetOffsetFromEntityInWorldCoords(ped, point.x, point.y, point.z)
            cameraHandle = CreateCameraWithParams("DEFAULT_SCRIPTED_CAMERA", camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0, 49.0, false, 0)

            PointCamAtCoord(cameraHandle, camPoint.x, camPoint.y, camPoint.z)
            SetCamActive(cameraHandle, true)
        end
    end

    while isCameraInterpolating do
        Wait(100)
    end
end

function ResetSkin()
	-- TriggerServerEvent('qb-clothes:loadPlayerSkin')
    exports['origen_clothing']:ReloadAppearanceData()
    LocalPlayer.state.hide_props = false
	Wait(1000)
	ApplyPlayerTattos()
end

--[[ Las tiendas de tatuajes, en el mapa.

     Ya no se crean blips del juego: se registran los puntos en origen_map y de
     ahi los leen los tres mapas del servidor. El nombre del barrio lo pone el
     propio registro, asi que en la lista salen «Tatuajes Vespucci» y
     «Tatuajes Sandy Shores» en vez de cinco filas que ponen lo mismo. ]]
function CreateBlips()
	local puntos = {}

	for k, v in pairs(Config.Stores) do
		-- Sin blip no sale en el mapa (se apaga desde el panel de admin).
		if v.blip ~= false then puntos[#puntos + 1] = {
			id = tostring(k),
			x = v.coords.x, y = v.coords.y, z = v.coords.z,
			cat = 'activities',
			icono = 'tatuaje',
			nombre = v.label or 'Tatuajes',
		} end
	end

	OrigenMapa.PonerVarios('tatuajes', puntos)
end

--[[ Los tatuadores, solo con alguien cerca: aparecen a 80 m y se borran al
     irte. Antes estaban los de todas las tiendas desde que entrabas, ocupando
     sitio en el pool de peds de GTA (256 para todo el servidor). ]]
local DISTANCIA_NPC = 80.0
local puntosNpc = {}

local function crearTatuador(k, v)
    local coords = vector4(v.employee.idle.coords.x, v.employee.idle.coords.y, v.employee.idle.coords.z - 1, v.employee.idle.coords.w)
    local model = GetHashKey(v.employee.model)

    RequestModel(model)
    local intentos = 0
    while not HasModelLoaded(model) and intentos < 100 do
        Wait(50)
        intentos = intentos + 1
    end
    if not HasModelLoaded(model) then return end

    local npc = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, true)

    SetEntityAsMissionEntity(npc, true, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetModelAsNoLongerNeeded(model)
    FreezeEntityPosition(npc, true)
    LoadDict(v.employee.idle.dict)
    TaskPlayAnim(npc, v.employee.idle.dict, v.employee.idle.anim, 8.0, 8.0, -1, 1, 0, false, false, false)
    createdNpcs[k] = npc
end

function CreateNpcs()
    -- Lo de antes fuera: una tienda puede haberse movido o borrado.
    for k, p in pairs(puntosNpc) do
        p:remove()
        if createdNpcs[k] and DoesEntityExist(createdNpcs[k]) then DeleteEntity(createdNpcs[k]) end
        createdNpcs[k] = nil
    end
    puntosNpc = {}

    for k, v in pairs(Config.Stores) do
        local c = v.employee.idle.coords
        local p = lib.points.new({ coords = vec3(c.x, c.y, c.z), distance = DISTANCIA_NPC })
        function p:onEnter()
            if not (createdNpcs[k] and DoesEntityExist(createdNpcs[k])) then crearTatuador(k, v) end
        end
        function p:onExit()
            if createdNpcs[k] and DoesEntityExist(createdNpcs[k]) then DeleteEntity(createdNpcs[k]) end
            createdNpcs[k] = nil
        end
        puntosNpc[k] = p
    end
end

--[[ Desviste para tatuar: hombre en calzoncillos, mujer en bikini
     (Config.Clothes). Antes se hacia UNA vez al abrir y cualquier cosa que
     volviera a vestir al personaje (la funda del arma, un recargo de la ropa)
     lo dejaba vestido tapando los tatuajes; ademas "quitaba" gorra y gafas
     poniendo un numero concreto en vez de quitarlas, y a la mujer la dejaba
     sin ropa interior. Ahora quita todos los props y, mientras el menu esta abierto, vuelve a
     desvestir si algo cambia. Al cerrar, ResetSkin devuelve la ropa. ]]
local function Desvestir(ped)
    local ropa = Config.Clothes[GetGender()]
    if not ropa then return end
    for componente, v in pairs(ropa) do
        if GetPedDrawableVariation(ped, componente) ~= v[1] or GetPedTextureVariation(ped, componente) ~= v[2] then
            SetPedComponentVariation(ped, componente, v[1], v[2], 0)
        end
    end
    for _, prop in ipairs({0, 1, 2, 6, 7}) do
        if GetPedPropIndex(ped, prop) ~= -1 then
            ClearPedProp(ped, prop)
        end
    end
end

local vigilandoRopa = false

function HideClothes()
    Desvestir(PlayerPedId())
    if vigilandoRopa then return end
    vigilandoRopa = true
    CreateThread(function()
        while openedMenu do
            Desvestir(PlayerPedId())
            Wait(250)
        end
        vigilandoRopa = false
    end)
end

function FinishCam()
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(cameraHandle, false)
    cameraHandle = nil
    currentCamera = nil
    isCameraInterpolating = nil
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    FreezeEntityPosition(PlayerPedId(), false)
    for _, v in pairs(createdNpcs) do
        DeleteEntity(v)
    end

    if not openedMenu then return end
    -- La camara de la tienda tambien: sin esto se quedaba la vista clavada.
    FinishCam()
    ResetSkin()
end)
  

function LoadDict(dict)
    local timeout = false
    SetTimeout(5000, function() timeout = true end)

    repeat
        RequestAnimDict(dict)
        Wait(50)
    until HasAnimDictLoaded(dict) or timeout
end

function CheckDistance(coords, entity, distance)
    local isNear = false
    local attemps = 0
    while not isNear do
        local EntityCoords = GetEntityCoords(entity)
        local dist = #(coords - EntityCoords)
        if dist < distance then
            isNear = true
        end
        attemps = attemps + 1
        if attemps >= 100 then
            break
        end
        Wait(100)
    end

    return isNear
end

function SetupTattooShop(store, cb)
    local shop = Config.Stores[store]
    
    if not shop then
        cb(false, store)
        return
    end

    local ped = PlayerPedId()
    local heading = GetEntityHeading(ped)
    local shopCustomer = shop.customer
    lastCoords = vector4(GetEntityCoords(ped), heading)
    lastCam = currentCamera

    local sequenceTaskId = OpenSequenceTask()

    if sequenceTaskId then 
        ApplyPlayerTattos()
        ToggleMenu(false)
        FinishCam()
        TaskGoStraightToCoord(ped, shopCustomer.chair.x, shopCustomer.chair.y, shopCustomer.chair.z, 1.0, -1, shopCustomer.chair.w, 0.1)
        TaskStandStill(0, -1)

        local near = CheckDistance(vector3(shopCustomer.chair.x, shopCustomer.chair.y, shopCustomer.chair.z), ped, 1.0)

        if near then 
            DoScreenFadeOut(500)
            Wait(1500)
            FreezeEntityPosition(ped, true)
            SetEntityCoords(ped, shop.customer.coords)
            SetEntityHeading(ped, shop.customer.coords.w)
            LoadDict(shop.customer.dict)
            TaskPlayAnim(ped, shop.customer.dict, shop.customer.anim, 8.0, 8.0, -1, 1, 0, false, false, false)
            RenderScriptCams(true, false, 0, true, true)
            SetCamera('tattoo')
            Wait(1500)
            DoScreenFadeIn(500)
            CloseSequenceTask(sequenceTaskId)
            if lib.progressBar({
                duration = math.random(5000, 10000),
                label = 'Tatuando...',
                useWhileDead = false,
                canCancel = false,
            }) then
                cb(true, store)
                return
            end
        end
    end
    cb(false, store)
end

function StartTattooSequence(storeId, cb)
    local ped = PlayerPedId()
    SetupTattooShop(storeId, function(endTattoo, storeKey)
        local shop = Config.Stores[storeKey or storeId]
        if not shop then
            cb(false)
            return
        end
        -- Muerto en la silla (o de camino) no se vuelve a la tienda: se
        -- cierra del todo, o quedaba abierta sin pantalla ni raton.
        if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
            FreezeEntityPosition(ped, false)
            CloseMenu()
            cb(false)
            return
        end
        DoScreenFadeOut(500)
        Wait(2000)
        ClearPedTasks(ped)
        FreezeEntityPosition(ped, false)
        SetEntityCoords(ped, shop.customer.chair.x, shop.customer.chair.y, shop.customer.chair.z)
        FinishCam()
        Wait(500)
        DoScreenFadeIn(200)
        TaskGoStraightToCoord(ped, lastCoords.x, lastCoords.y, lastCoords.z, 1.0, -1, lastCoords.w, 0.1)

        local near = CheckDistance(vector3(lastCoords.x, lastCoords.y, lastCoords.z), ped, 0.5)

        --[[ Si no llega (una silla, otro jugador en medio) se le pone donde
             estaba. Antes no habia salida: la tienda seguia abierta sin
             pantalla ni raton, `openedMenu` en true y desvistiendo cada
             250 ms para siempre. ]]
        if not near then
            ClearPedTasks(ped)
            SetEntityCoords(ped, lastCoords.x, lastCoords.y, lastCoords.z)
            SetEntityHeading(ped, lastCoords.w)
        end

        ToggleMenu(true)
        CreateThread(function()
            Wait(1000)
            if openedMenu then
                RenderScriptCams(true, false, 0, true, true)
                SetCamera(lastCam)
            end
        end)
        cb(endTattoo and true or false)
    end)
end

function StartNPCSequence(store, travel)
    local shop = Config.Stores[store]
    local npc = createdNpcs[store]
    local taskId = OpenSequenceTask()
    local x, y, z = table.unpack(GetEntityCoords(npc))
    local propInfo = Config.Prop

    if not shop then return end
    local target

    if travel == 'goto' then 
        target = shop.employee.tattoo
    else
        target = shop.employee.idle
    end

    local dist = #(GetEntityCoords(PlayerPedId()) - vector3(target.coords.x, target.coords.y, target.coords.z))

    if taskId then
        FreezeEntityPosition(npc, false)
        ClearPedTasks(npc)
        if propsCreated[store] then
            DeleteEntity(propsCreated[store])
            propsCreated[store] = nil
        end
        Wait(500)
        TaskGoStraightToCoord(npc, target.coords.x, target.coords.y, target.coords.z, 1.0, -1, target.coords.w, 0.1)
        TaskStandStill(0, -1)

        CreateThread(function()
            local near = CheckDistance(vector3(target.coords.x, target.coords.y, target.coords.z), npc, 1.2)

            if near then
                FreezeEntityPosition(npc, true)
                SetEntityCoords(npc, target.coords.x, target.coords.y, target.coords.z - 1)
                SetEntityHeading(npc, target.coords.w)
                Wait(300)
                LoadDict(target.dict)
                TaskPlayAnim(npc, target.dict, target.anim, 8.0, 8.0, -1, 1, 0, false, false, false)
    
                if travel == 'goto' then 
                    prop = CreateObject(propInfo.model, x, y, z + 0.2, false, true, true)
                    AttachEntityToEntity(prop, npc, GetPedBoneIndex(npc, propInfo.bone), propInfo.xPos, propInfo.yPos, propInfo.zPos, propInfo.xRot, propInfo.yRot, propInfo.zRot, true, true, false, true, 1, true)
                    propsCreated[store] = prop

                    local volume = (0.01 * GetProfileSetting(300)) / (dist / 2)
                    volume = math.min(volume, 0.8)
                    volume = math.max(volume, 0)
                    -- exports['xsound']:PlayUrlPos('tattoogun', 'sounds/tattoogun.ogg', volume, vector3(x, y, z), false)
                end
                CloseSequenceTask(taskId)
            end
        end)
    end
end

--[[ Si el vigilante comun (@origen_map/shared/foco.lua) suelta el raton porque
     la pantalla no enseña nada, se cierra la tienda del todo: camara, ropa y
     controles de vuelta, y `openedMenu` a false para poder volver a abrirla. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if openedMenu then CloseMenu() end
    end)
end
