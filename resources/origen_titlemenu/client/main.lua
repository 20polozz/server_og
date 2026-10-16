local IsNUIReady = false
local CachedCharacters = {}
local creationnpc
local isSwitchingCreationModel = false
local creationAnchor = nil
local hasSpawned = false
local playerID = nil
local spawnEnCurso = false

local function PlayCreationHello(ped)
    if not ped or not DoesEntityExist(ped) then return end

    CreateThread(function()
        local dict = "gestures@m@standing@casual"
        local anim = "gesture_hello"

        if not HasAnimDictLoaded(dict) then RequestAnimDict(dict) end
        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end

        FreezeEntityPosition(ped, false)
        ClearPedTasksImmediately(ped)
        TaskPlayAnim(ped, dict, anim, 8.0, 1.0, 1400, 48, 0.0, false, false, false)
        Wait(1450)
        if creationAnchor then
            SetEntityCoordsNoOffset(ped, creationAnchor.x, creationAnchor.y, creationAnchor.z, false, false, false)
            SetEntityHeading(ped, creationAnchor.w)
        end
        FreezeEntityPosition(ped, true)
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_GUARD_STAND", 0, true)
    end)
end

--- ¿Hay ya un personaje dentro? Pasa cuando se REINICIA este recurso con la
--- partida empezada. Entonces no se hace nada de la entrada: ni la instancia
--- propia, ni el fundido a negro, ni pedir la lista de personajes. Antes, un
--- `restart origen_titlemenu` dejaba al jugador solo en su instancia, con la
--- pantalla en negro y la portada tapandolo todo.
local function YaEnPartida()
    if LocalPlayer.state.isLoggedIn then return true end
    local ok, datos = pcall(FW_GetPlayerData)
    return ok and datos ~= nil and datos.citizenid ~= nil
end

Citizen.CreateThread(function()
    --[[ El state bag y la cache del core tardan un momento en estar puestos
         tras un restart: sin esta espera, YaEnPartida() decia que no y la
         entrada se llevaba al jugador bajo el mapa. Si aun asi duda, se le
         pregunta al servidor, que si lo sabe seguro. ]]
    Wait(800)

    local dentro = YaEnPartida()

    if not dentro then
        local ok, resp = pcall(function()
            return lib.callback.await('origen_titlemenu:sv:enPartida', false)
        end)
        dentro = ok and resp == true
    end

    if dentro then
        hasSpawned = true
        return
    end
    TriggerServerEvent("origen_titlemenu:server:InstancePrevent")
    while not IsNUIReady do
        Citizen.Wait(100)
    end
    DoScreenFadeOut(0)
    TriggerEvent("origen_titlemenu:client:OnPlayerJoined")
    TriggerServerEvent("origen_titlemenu:server:OnPlayerJoined")

    NewLoadSceneStartSphere(Config.CreationCoords.x, Config.CreationCoords.y, Config.CreationCoords.z, 1000, 0)
    while not hasSpawned do 
        Wait(500)
        DisplayRadar(false)
    end
end)

RegisterNUICallback('Nuitranslate', function(d, cb)
    cb(Lang.nui)
end)

RegisterNUICallback('GetYoutubeVideos', function(d, cb)
    cb(Config.YoutubeVideos)
end)

AddStateBagChangeHandler('PlayerCount', 'global', function(_, _, value)
    if value then
        local maxPlayers = GetConvarInt('sv_maxclients', 128)
        SendNUIMessage({
            action = "updatePlayerCount",
            playerCount = value,
            maxPlayers = maxPlayers
        })
    end
end)

AddStateBagChangeHandler('Uptime', 'global', function(_, _, value)
    if value then
        SendNUIMessage({
            action = "updateUptime",
            uptimeMinutes = value
        })
    end
end)

AddStateBagChangeHandler('StaffCount', 'global', function(_, _, value)
    if value then
        SendNUIMessage({
            action = "updateStaffCount",
            staffCount = value
        })
    end
end)

RegisterNUICallback("Ready", function(data, cb)
    cb(not IsNUIReady)
    IsNUIReady = true
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    TriggerEvent('esx:loadingScreenOff')
    
    local playerCount = GlobalState.PlayerCount or 0
    local maxPlayers = GetConvarInt('sv_maxclients', 128)
    SendNUIMessage({
        action = "updatePlayerCount",
        playerCount = playerCount,
        maxPlayers = maxPlayers
    })
    
    local uptimeMinutes = GlobalState.Uptime or 0
    SendNUIMessage({
        action = "updateUptime",
        uptimeMinutes = uptimeMinutes
    })
    
    local staffCount = GlobalState.StaffCount or 0
    SendNUIMessage({
        action = "updateStaffCount",
        staffCount = staffCount
    })

    FW_TriggerCallback('origen_titlemenu:GetPing', function(ping)
        SendNUIMessage({
            action = "updateServerInfo",
            ping = ping,
            version = Config.Version
        })
    end)
end)

local SetupInfo = nil

RegisterNUICallback("WaitingCMenuExceded", function(data, cb)
    cb(SetupInfo)
end)

RegisterNetEvent("origen_titlemenu:client:Setup", function(characters, slots)
    SetNuiFocus(true, true)
    --- Fuera el rastreador de misiones y el logo de origen_notify mientras el
    --- menu esta puesto: caian encima de la barra de la ficha, en la esquina de
    --- arriba a la derecha. Es la misma señal que usa el radial de origen_hud.
    TriggerEvent('qv2:suppressHud', true)
    --- Y el minimapa, que con el ajuste «siempre» salia en la portada, en la
    --- seleccion y en la creacion del personaje.
    if GetResourceState('origen_map') == 'started' then exports.origen_map:Apartar(true) end
    StartAudioScene("DLC_MPHEIST_TRANSITION_TO_APT_FADE_IN_RADIO_SCENE")
    playerID = PlayerPedId()
    SetEntityCoords(PlayerPedId(), Config.HiddenCoords.xyz)
    SetEntityVisible(PlayerPedId(), false)
    CachedCharacters = characters
    debuger('load',#CachedCharacters)
    
    local function decodeSkin(rawSkin)
        if type(rawSkin) == 'string' then
            local ok, decoded = pcall(json.decode, rawSkin)
            if ok then return decoded end
            return nil
        end
        return rawSkin
    end

    local function ensureCharacterPedLoaded(character)
        if not character or character.npc and DoesEntityExist(character.npc) then
            return character and character.npc or nil
        end

        character.npc = SetupPeds(character.model, decodeSkin(character.skin))
        if character.npc and DoesEntityExist(character.npc) then
            character.mugshot = UpdateMugShot(character.npc, true)
            character.skin = nil

            if Config.ClothSystem == "rcore_clothing" then
                local rcoreSkin = exports["rcore_clothing"]:getSkinByIdentifier(character.citizenid)
                exports.rcore_clothing:setPedSkin(character.npc, rcoreSkin)
            end
        end

        return character.npc
    end

    --[[ Ultima ubicacion: el servidor manda las coordenadas y aqui se traducen
         a algo legible. El nombre de la zona solo se puede sacar en el cliente,
         que es quien tiene los natives del mapa. Tambien se calcula la posicion
         en tanto por ciento para el minimapa de la ficha. ]]
    for i = 1, #CachedCharacters do
        local pos = CachedCharacters[i].position
        if pos and pos.x and pos.y then
            local x, y, z = pos.x + 0.0, pos.y + 0.0, (pos.z or 0.0) + 0.0

            --[[ Primero la calle, que dice mucho mas que el barrio: "Vinewood
                 Blvd" frente a "Rockford Hills". Si el juego no sabe nombrarla
                 —descampados, interiores, sitios sin via— se cae a la zona, y
                 si la zona tampoco tiene nombre propio el juego devuelve el
                 comodin "San Andreas", que es lo que salia siempre antes. ]]
            local legible = function(txt)
                return txt and txt ~= 'NULL' and txt ~= '' and txt ~= 'NIL' and txt
            end

            local nombre
            local ok, calleHash = pcall(GetStreetNameAtCoord, x, y, z)
            if ok and calleHash and calleHash ~= 0 then
                nombre = legible(GetStreetNameFromHashKey(calleHash))
            end

            if not nombre then
                local zona = GetNameOfZone(x, y, z)
                nombre = zona and legible(GetLabelText(zona)) or nil
            end

            if nombre then
                CachedCharacters[i].ubicacion = nombre
            end

            -- El mapa de Los Santos va de -4000 a 4500 en X y de -4000 a 8000
            -- en Y; el eje vertical se invierte para que 0 % sea arriba.
            local px = (pos.x + 4000.0) / 8500.0 * 100.0
            local py = (8000.0 - pos.y) / 12000.0 * 100.0
            CachedCharacters[i].mapa = {
                math.max(0.0, math.min(100.0, px)),
                math.max(0.0, math.min(100.0, py)),
            }
        end
    end

    -- Abrir NUI al instante y precargar peds en segundo plano.
    SendNUIMessage({
        action = "setup",
        characters = CachedCharacters,
        slots = slots,
        youtubeVideos = Config.YoutubeVideos,
        theme = Config.Theme,
        themeProfile = Config.ActiveTheme,
    })

    local totalCharacters = #CachedCharacters
    for i = 1, totalCharacters do
        Citizen.CreateThread(function()
            ensureCharacterPedLoaded(CachedCharacters[i])
        end)
    end
    
    --[[ Las caras que falten: se sacan en segundo plano, con la portada del
         menu tapando la pantalla, asi que no se ve nada (client/retrato.lua). ]]
    if SacarRetratosPendientes then SacarRetratosPendientes(CachedCharacters) end

    SetupInfo = { characters = characters, slots = slots }
    
end)

RegisterNUICallback("SelectCharacter", function(data, cb)
    for i = 1, #CachedCharacters do
        local character = CachedCharacters[i]
        if character.citizenid == data.citizenid then
            if not character.npc or not DoesEntityExist(character.npc) then
                local skin = character.skin
                if type(skin) == 'string' then
                    local ok, decoded = pcall(json.decode, skin)
                    skin = ok and decoded or nil
                end
                character.npc = SetupPeds(character.model, skin)
                if character.npc and DoesEntityExist(character.npc) then
                    character.mugshot = UpdateMugShot(character.npc, true)
                    character.skin = nil
                end
            end

            if character.npc and DoesEntityExist(character.npc) then
                SelectCharacter(character.npc)
                creationnpc = nil
                cb(true)
                return
            end

            break
        end
    end

    cb(false)
end)

RegisterNUICallback("UnselectCharacter", function(data, cb)
    UnselectCharacter()
    creationnpc = nil
    
    StartCinematicCam()
    cb(true)
end)


RegisterNUICallback('GetSpawns', function(data, cb)
    debuger ('spawn','^1[origen_titlemenu]^0 GetSpawns', '^3Framework:^0 ', Config.Framework, '^3Active 0r_motels:^0 ', Config._Or_Motels, '^3Config Apartaments:^0' ,Config.Apartment)
    local spawns = {}

    FW_TriggerCallback('origen_titlemenu:GetLastPlace', function(_lastplace)
        debuger ('spawn', 'lastplace' ,json.encode(_lastplace))
        
        -- Check if this is first-time character creation (no lastplace)
        local isFirstTimeCreation = not _lastplace
        
        if not Config.DisableQBApartment and Config.Apartment == 'qb-apartments' then
            local apartment, apartmentlist, lastplace = GetMyApartments(data.citizenid)
            if apartment and Config.QBApartmentSpawns then
                table.insert(spawns, { id = apartment.name, apartmentType = apartment.type, coordX = apartmentlist[apartment.type].coords.enter.x, coordY = apartmentlist[apartment.type].coords.enter.y, label = apartment.label, type = "apartment" })
                isFirstTimeCreation = false  -- Has apartment, not first time
            elseif not _lastplace then
                for k, v in pairs(apartmentlist) do
                    table.insert(spawns, { id = v.name, coordX = v.coords.enter.x, coordY = v.coords.enter.y, label = v.label, type = "first_apartment" })
                end
            end
        end
        if _lastplace then
            table.insert(spawns, { id = "lastplace", coordX = _lastplace.x, coordY = _lastplace.y, label = Lang.general.lastLocation, type = "lastplace" })
            if Config.Locations then 
                for k,v in pairs(Config.Locations) do
                    table.insert(spawns, { id = k:lower(), coordX = v.coords.x, coordY = v.coords.y, label = v.label, type = "custom_place" })
                end
            end

            if Config.EnableOrigenHousing and GetResourceState('origen_housing'):match('start') then 

                local loadingHouses = true

                FW_TriggerCallback('origen_titlemenu:server:GetPlayerHouses', function(properties)
                    if properties then 
                        for _, house in pairs(properties) do
                            table.insert(spawns, { 
                                id = house.id, 
                                coordX = house.coordX, 
                                coordY = house.coordY, 
                                label = house.label, 
                                type = house.type 
                            })
                        end
                        loadingHouses = false
                    else
                        loadingHouses = false
                    end
                end, data.citizenid)

                while loadingHouses do 
                    Wait(100)
                end
            end
        else
            if Config._Or_Motels and Config.Apartment == '0r_motels' and GetResourceState('0r_motels'):match('start') then 
                if exports['0r_motels']:GetApartment() then 
                    table.insert(spawns, { id = "Or_motels", coordX = Config.DefaultSpawn.x, coordY = Config.DefaultSpawn.y, label = Lang.general.createCharacter_Motel, type = "first_apartment" })
                    isFirstTimeCreation = false  -- Has motel, not pure first time
                else
                    table.insert(spawns, { id = "spawn", coordX = Config.DefaultSpawn.x, coordY = Config.DefaultSpawn.y, label = Lang.general.createCharacter, type = "spawn" })
                end
            elseif Config.Apartment == 'default' then 
                table.insert(spawns, { id = "spawn", coordX = Config.DefaultSpawn.x, coordY = Config.DefaultSpawn.y, label = Lang.general.createCharacter, type = "spawn" })
            end
        end  
        if Custom.SpawnMenu then 
            Custom.SpawnMenu(function(_spawns)
                for k,v in pairs(_spawns) do
                    table.insert(spawns, v)
                end
            end, _lastplace)
        end
        Wait(1000)
        if not spawns or #spawns == 0 then 
            table.insert(spawns, { id = "spawn", coordX = Config.DefaultSpawn.x, coordY = Config.DefaultSpawn.y, label = Lang.general.createCharacter, type = "spawn" })
        end

        local weatherState = GlobalState.weather
        local currentWeather = nil
        if type(weatherState) == 'table' then
            currentWeather = weatherState.weather
        elseif type(weatherState) == 'string' then
            currentWeather = weatherState
        end

        local currentTime = GlobalState.currentTime
        local serverTime = nil
        if type(currentTime) == 'table' and currentTime.hour ~= nil and currentTime.minute ~= nil then
            serverTime = {
                hour = tonumber(currentTime.hour) or 0,
                minute = tonumber(currentTime.minute) or 0
            }
        end
        
        -- If first time creation and using origen_clothing, skip spawn selection
        if isFirstTimeCreation and Config.ClothSystem == 'origen_clothing' and Config.Apartment == 'default' then
            cb({
                skipSpawnSelection = true,
                spawns = spawns,
                hasApartment = false,
                weather = currentWeather,
                currentWeather = currentWeather,
                serverWeather = currentWeather,
                serverTime = serverTime
            })
        else
            cb({
                spawns = spawns,
                hasApartment = _lastplace and true or false,
                weather = currentWeather,
                currentWeather = currentWeather,
                serverWeather = currentWeather,
                serverTime = serverTime
            })
        end
    end, data.citizenid)
end)

RegisterNUICallback("TriggerCallback", function(data, cb)
    --[[ Traza del puente entero: NUI -> cliente -> servidor -> cliente -> NUI.
         Al aparecer con un personaje existente la respuesta no llegaba y la
         interfaz se comia los 15 s de espera; asi se ve en que eslabon se
         pierde en vez de suponerlo. ]]
    local nombre = tostring(data and data.name)
    local contestado = false

    FW_TriggerCallback(data.name, function(retval)
        contestado = true
        cb(retval)
    end, data)

    Citizen.CreateThread(function()
        Citizen.Wait(12000)
        if not contestado then
            print(('^1[origen_titlemenu] %s sigue sin respuesta a los 12 s^0'):format(nombre))
        end
    end)
end)

RegisterNUICallback("StartCharacterCreation", function(data, cb)
    creationAnchor = vector4(
        Config.CreationCoords.x,
        Config.CreationCoords.y,
        Config.CreationCoords.z,
        Config.CreationCoords.w
    )

    -- Crear el nuevo personaje de creación
    creationnpc = SpawnCreationPed("mp_m_freemode_01")
    
    -- Seleccionar el personaje de creación (esto lo hace entrar caminando y salir al anterior)
    SelectCharacter(creationnpc)
    
    cb(true)
end)

RegisterNUICallback("SetModel", function(data, cb)
    if isSwitchingCreationModel then
        cb(true)
        return
    end
    isSwitchingCreationModel = true

    local newModel = tonumber(data.model) or GetHashKey(data.model)
    
    -- Si no existe el ped, crear uno nuevo
    if not creationnpc or not DoesEntityExist(creationnpc) then
        creationnpc = SpawnCreationPed(data.model)
        SelectCharacter(creationnpc)
        SetTimeout(2100, function()
            PlayCreationHello(creationnpc)
        end)
        isSwitchingCreationModel = false
        cb(true)
        return
    end
    
    -- Mantener una posición fija de referencia para evitar drift acumulado.
    local oldPed = creationnpc
    if not creationAnchor then
        creationAnchor = vector4(
            Config.CreationCoords.x,
            Config.CreationCoords.y,
            Config.CreationCoords.z,
            Config.CreationCoords.w
        )
    end
    
    -- Cargar el nuevo modelo
    if not HasModelLoaded(newModel) then RequestModel(newModel) end
    while not HasModelLoaded(newModel) do
        Citizen.Wait(0)
    end
    
    -- Eliminar el ped viejo
    DeleteEntity(oldPed)
    
    -- Crear nuevo ped SIEMPRE anclado en el punto central del menú.
    creationnpc = CreatePed(4, newModel, creationAnchor.x, creationAnchor.y, creationAnchor.z, creationAnchor.w, false, true)
    SetEntityInvincible(creationnpc, true)
    SetBlockingOfNonTemporaryEvents(creationnpc, true)
    SetEntityVisible(creationnpc, true)
    SetEntityAlpha(creationnpc, 255, false)
    SetPedConfigFlag(creationnpc, 79, true)
    SetEntityCollision(creationnpc, true, true)
    SetEntityCoordsNoOffset(creationnpc, creationAnchor.x, creationAnchor.y, creationAnchor.z, false, false, false)
    SetEntityHeading(creationnpc, creationAnchor.w)
    
    FreezeEntityPosition(creationnpc, true)
    
    -- Aplicar la animación
    TaskStartScenarioInPlace(creationnpc, "WORLD_HUMAN_GUARD_STAND", 0, true)

    -- IMPORTANT: keep peds.lua internal selected reference synced.
    SyncSelectedPedReference(oldPed, creationnpc)
    PlayCreationHello(creationnpc)
    
    SetModelAsNoLongerNeeded(newModel)
    isSwitchingCreationModel = false
    cb(true)
end)

RegisterNUICallback("StartSpawnCamera", function(data, cb)
    SpawnCamera()
    cb(true)
end)

RegisterNUICallback("StopSpawnCamera", function(data, cb)
    StopSpawnCamera()
    cb(true)
end)

--[[ ¿Ha tomado ya el relevo el juego?

     Se pone en cuanto el jugador esta dentro (AbrirTelon, al final del spawn o
     al avisar la creacion de personaje). A partir de ahi este menu ya no manda:
     detras hay una camara y otra NUI —la creacion de origen_clothing— y
     cualquier cosa que haga este recurso con el foco o con su capa se la quita
     a ellas.

     Hacia falta porque el camino de error de la NUI llamaba a HudFadeIn cuando
     algo tardaba de mas: si el servidor contestaba tarde a CreateCharacter, a
     los 15 s la pagina daba la peticion por perdida y "recogia el telon". Para
     entonces el jugador ya estaba en la creacion de personaje, y ese HudFadeIn
     le devolvia el raton a un menu invisible: la columna se veia entera y no
     respondia a un solo clic. ]]
local juegoEnMarcha = false

RegisterNUICallback("HudFadeOut", function(data, cb)
    local time = (data and tonumber(data.time)) or 400
    if GetResourceState('origen_hud') == 'started' then
        -- Ensure origen_hud fade is always above this NUI.
        SetNuiFocus(false, false)
        SetNuiZindex(1)
        exports['origen_hud']:DoScreenFadeOut(time)
        Wait(time + 20)
    end
    cb(true)
end)

RegisterNUICallback("HudFadeIn", function(data, cb)
    local time = (data and tonumber(data.time)) or 400
    if GetResourceState('origen_hud') == 'started' then
        --[[ El telon se quita siempre —dejar la pantalla en negro no arregla
             nada—, pero el foco y la capa solo se recuperan si este menu sigue
             siendo el que manda. Ya dentro del juego se hace justo lo
             contrario: apartarse. ]]
        if juegoEnMarcha then
            SetNuiZindex(0)
        else
            -- Restore titlemenu layer/focus while fade-in completes.
            SetNuiZindex(99999)
            SetNuiFocus(true, true)
        end
        exports['origen_hud']:DoScreenFadeIn(time)
    end
    cb(true)
end)

RegisterNUICallback("BackToCharacterSelection", function(data, cb)
    StopSpawnCamera(false, true)
    UnselectCharacter(true)

    local citizenid = data and data.citizenid or nil
    if citizenid then
        for i = 1, #CachedCharacters do
            if CachedCharacters[i].citizenid == citizenid then
                SelectCharacter(CachedCharacters[i].npc)
                creationnpc = nil
                break
            end
        end
    end

    cb(true)
end)

RegisterNUICallback("SelectSpawn", function(data, cb)
    SelectCoords(data.x, data.y)
    cb(true)
end)

function DeleteCachedCharacters()
    for i = 1, #CachedCharacters do
        if CachedCharacters[i].npc then
            DeleteEntity(CachedCharacters[i].npc)
        end
    end
    spawned = {}
end

--[[ Modelos del modo historia. El juego arranca al jugador con Michael, y ese
     es el ped que se ve mientras origen_clothing no ha aplicado el aspecto
     guardado. Ninguno de estos es nunca un personaje de rol. ]]
local MODELOS_HISTORIA = {
    [GetHashKey('player_zero')] = true,   -- Michael
    [GetHashKey('player_one')]  = true,   -- Franklin
    [GetHashKey('player_two')]  = true,   -- Trevor
}

--- Espera, con tope, a que el jugador tenga ya su propio aspecto.
--- Sin esto se abre el telon con Michael en pantalla y el cambiazo se ve.
local function EsperarAspectoPropio(msTope)
    local tope = msTope or 6000
    local pasado = 0

    while MODELOS_HISTORIA[GetEntityModel(PlayerPedId())] and pasado < tope do
        Citizen.Wait(50)
        pasado = pasado + 50
    end

    if pasado >= tope then
        print('^3[origen_titlemenu] El aspecto no ha llegado en ' .. tope .. ' ms; se abre igual.^0')
    end

    -- Un respiro para que se apliquen ropa y accesorios antes de verse.
    Citizen.Wait(200)
end

local function playerSpawned()
    LocalPlayer.state:set('isLoggedIn', true, true)
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
end


--[[ El telon de la pantalla de carga.

     Levantarlo es abrirle los ojos al jugador, y hasta ahora se abrian
     demasiado pronto: al crear un personaje, detras de este momento todavia
     quedan el teletransporte al estudio de creacion, el cambio de modelo y el
     viaje de camara hasta la cara. Todo eso se veia.

     Asi que cuando detras viene la creacion no se levanta aqui: se espera al
     aviso de origen_clothing, que sale cuando el plano de cara ya ha encajado y
     su panel esta pintado. El jugador pasa de la pantalla de carga a su cara,
     sin nada en medio. ]]
local telonAbierto = false
local esperandoCreacion = false

local function AbrirTelon()
    if telonAbierto then return end
    telonAbierto = true

    --[[ Abrir el telon es el ultimo acto de este menu: a partir de aqui el
         jugador esta en el mundo y quien manda es el juego. ]]
    juegoEnMarcha = true

    DoScreenFadeIn(500)

    --[[ El telon de origen_hud ("Cargando el servidor") lo pone HudFadeOut y
         SOLO lo quita su propio DoScreenFadeIn: el fundido nativo de aqui
         arriba no lo toca. ]]
    if GetResourceState('origen_hud') == 'started' then
        local ok, err = pcall(function()
            exports['origen_hud']:DoScreenFadeIn(500)
        end)
        if not ok then
            print('^1[origen_titlemenu] No se ha podido quitar el telon: ' .. tostring(err) .. '^0')
        end
    end

    --[[ Y este menu se aparta. Aqui habia un SetNuiZindex(99999) copiado de
         HudFadeIn, donde sirve para que el menu vuelva a quedar por encima
         mientras se abre el fundido; en este momento no sirve para nada —el
         telon que se esta quitando es de origen_hud, que tiene su propia capa—
         y ademas deja este recurso por encima de todos los demas para el resto
         de la partida. Se manda al fondo, que es donde le toca. ]]
    SetNuiZindex(0)
end

--[[ origen_clothing avisa cuando la creacion esta lista de verdad. Solo se hace
     caso si este spawn lo estaba esperando: el mismo aviso sale al usar /skin,
     y alli no hay ningun telon que abrir. ]]
RegisterNetEvent('origen_clothing:client:creationReady', function()
    if not esperandoCreacion then return end
    esperandoCreacion = false
    AbrirTelon()
end)

--[[ ══ Aparecer con suelo debajo ═══════════════════════════════════════════

     SetEntityCoords te lleva al sitio en el acto, pero el mapa de alrededor
     tarda en llegar. Si al ped se le quita el congelado antes de que exista el
     suelo, se queda flotando: no cae porque no hay contra que caer, y para
     cuando el terreno aparece ya se ha quedado ahi arriba. Es lo que pasaba al
     entrar en la ultima ubicacion -- las coordenadas eran las correctas, lo
     que fallaba era el momento.

     Aqui se pide la colision de ese punto, se espera a tenerla y solo entonces
     se suelta al ped.

     La espera lleva tope de 10 segundos a proposito: en un sitio raro -- el
     mar, un interior sin descargar -- la colision puede no llegar nunca, y sin
     tope el jugador se quedaria en la pantalla de carga para siempre. Mas vale
     aparecer flotando un momento que no aparecer. ]]
local function ColocarConSuelo(ped, x, y, z, heading)
    RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, x, y, z, false, false, false, false)
    if heading then SetEntityHeading(ped, heading) end

    local hasta = GetGameTimer() + 10000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < hasta do
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
        Citizen.Wait(0)
    end

    --[[ Y aun con el suelo cargado puede haber quedado por encima, porque la
         Z guardada es la de donde estabas y el terreno no siempre coincide al
         centimetro. Se comprueba de verdad si esta en el aire en vez de
         corregir siempre: si te desconectaste dentro de una casa, bajarlo al
         suelo del terreno te dejaria debajo del mapa. ]]
    if GetEntityHeightAboveGround(ped) > 1.5 then
        local hay, sueloZ = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 1.0, false)
        if hay then
            SetEntityCoords(ped, x, y, sueloZ, false, false, false, false)
        end
    end

    FreezeEntityPosition(ped, false)
end

RegisterNetEvent("origen_titlemenu:client:SpawnPlayer", function(data)
    -- Un segundo spawn a la vez dejaria dos esperas compitiendo por la misma
    -- respuesta de 'SetDimension', que el puente qb indexa por nombre.
    if spawnEnCurso then
        print('^1[origen_titlemenu] client:SpawnPlayer ignorado: ya habia uno en curso^0')
        return
    end
    spawnEnCurso = true
    telonAbierto = false

    --[[ Todo el spawn va dentro de un pcall. El raton solo se suelta casi al
         final (SetNuiFocus(false, false) tras colocar al jugador), asi que un
         error en medio —un export parado, un dato que no llega— dejaba el
         raton preso sobre el menu, el telon puesto y spawnEnCurso en true, y
         el siguiente spawn se ignoraba. Si falla, se deja al jugador dentro:
         raton suelto, telon fuera y el spawn libre para reintentarlo. ]]
    local ok, err = pcall(function()

    --[[ Un personaje nuevo no aparece en la ciudad: aparece en el estudio de
         creacion. Es el unico caso en que el telon aguanta hasta el final. ]]
    local vaACreacion = Config.Framework == 'qbcore'
        and (data.type == 'qb_spawn' or data.type == 'spawn')

    debuger ('spawn','recibido', json.encode(data))
    Wait(1000)
    if data.type ~= "lastplace" and (data.type ~= "esx_spawn" or data.type ~= "qb_spawn" or data.type ~= 'spawn' or data.tpye ~= 'custom_place') then
        StopSpawnCamera()
    end
    if Config.Apartment == 'qb-apartments' then 
        local apartment, _, __ = GetMyApartments(data.citizenid)
        TriggerEvent("apartments:client:SetHomeBlip", type(apartment) == "table" and apartment.type or nil)
    end

    UnselectCharacter()
    StopCinematicCam()
    if creationnpc then
        DeleteEntity(creationnpc)
    end
    DeleteCachedCharacters()
    --[[ Los datos del personaje, antes de seguir.

         El servidor manda este evento nada mas hacer el Login, y la ficha llega
         al cliente un momento despues. Con un personaje nuevo no se esperaba:
         se avisaba de que ya estaba cargado y se abria la creacion con la ficha
         vacia, y todo lo que la lee en ese instante —kq_link, la ropa, los
         garajes— reventaba sin trabajo ni datos. Hasta diez segundos; si no
         llega, se sigue igual para no dejar a nadie en la pantalla de carga. ]]
    local PlayerData = FW_GetPlayerData() or {}
    local hastaFicha = GetGameTimer() + 10000

    while not (PlayerData.citizenid and (Config.Framework ~= 'qbcore' or PlayerData.charinfo))
        and GetGameTimer() < hastaFicha do
        Citizen.Wait(50)
        PlayerData = FW_GetPlayerData() or {}
    end

    if not PlayerData.citizenid then
        print('^1[origen_titlemenu] La ficha del personaje no ha llegado en 10 s; se sigue igual.^0')
    end

    if PlayerData.metadata == nil then
        PlayerData.metadata = {}
    end

    local spawnCoords = nil


    if not GetResourceState("origen_police"):match('start') or (not PlayerData.metadata["federal"] or tonumber(PlayerData.metadata["federal"]) == 0) then
        if data.type == "lastplace" then
            local newPos = nil
            if Config.Framework == "esx" then
                FW_TriggerCallback("origen_titlemenu:GetLastPlace", function(lastplace)
                    if lastplace then
                        newPos = lastplace
                    else
                        newPos = PlayerData.position
                    end
                end, PlayerData.citizenid)
            else
                newPos = PlayerData.position
            end
            --[[ Aqui habia un "while newPos == nil do Wait(1) end" sin salida.
                 El servidor manda este evento nada mas hacer el Login, y los
                 datos del jugador tardan un poco en llegar al cliente: si
                 PlayerData.position aun no esta, el bucle no terminaba nunca y
                 el jugador se quedaba en la pantalla de carga para siempre. ]]
            local intentos = 0
            while newPos == nil and intentos < 100 do        -- hasta 5 s
                Citizen.Wait(50)
                intentos = intentos + 1
                PlayerData = FW_GetPlayerData() or PlayerData
                newPos = PlayerData and PlayerData.position
            end

            if newPos == nil then
                newPos = Config.DefaultSpawn
                print('^1[origen_titlemenu] Sin position tras 5 s; se usa DefaultSpawn.^0')
            end
            ColocarConSuelo(PlayerPedId(), newPos.x, newPos.y, newPos.z,
                PlayerData.position?.w or 0)
            SetEntityVisible(PlayerPedId(), true)

            --[[ La camara de llegada: arranca alta sobre el punto donde
                 apareces y empieza a bajar. La cierra CamaraLlegadaTerminar()
                 al final de este mismo evento, cuando el aspecto ya es el tuyo.
                 Vuelve en el acto: la bajada corre sola mientras aqui sigue el
                 spawn. Si esta apagada en el config, no hace nada. ]]
            CamaraLlegadaEmpezar(newPos, PlayerData.position?.w or 0)

            local insideMeta = PlayerData and PlayerData.metadata and PlayerData.metadata["inside"] or {}

            if (insideMeta.apartment and insideMeta.apartment.apartmentType) ~= nil or (insideMeta.apartment and insideMeta.apartment.apartmentId ~= nil) then
                TriggerEvent('qb-apartments:client:LastLocationHouse', insideMeta.apartment.apartmentType, insideMeta.apartment.apartmentId)
            else
                local wait = true
                FW_TriggerCallback('SetDimension', function()
                    wait = false
                end, 0)
                -- Con tope: si SetDimension no contesta, seguir en vez de colgarse.
                local esperaDim = 0
                while wait and esperaDim < 3000 do
                    Citizen.Wait(1)
                    esperaDim = esperaDim + 1
                end
            end
            --[[ Aqui NO se abre el telon todavia. El ped sigue siendo el de
                 serie del juego y su aspecto no llega hasta que responde
                 origen_clothing, unos instantes despues. Antes esto no se
                 notaba porque la camara bajaba dos segundos desde el cielo y
                 para cuando aterrizaba ya estaba cambiado; sin esa bajada
                 aparecias de Michael y te cambiaba delante. Se deja en negro y
                 se abre al final, cuando el aspecto ya es el tuyo. ]]
            DoScreenFadeOut(0)
        elseif data.type == "apartment" then
            TriggerEvent('qb-apartments:client:LastLocationHouse', data.apartmentType, data.id)
            Wait(2500)
            SetEntityVisible(PlayerPedId(), true)
            DoScreenFadeIn(500)
        elseif data.type == "first_apartment" then
            if Config.Apartment == 'qb-apartments' and not Custom.Spawn then
                TriggerServerEvent("apartments:server:CreateApartment", data.id, Apartments.Locations[data.id].label, true)
                debug("CREATE FIRST APARTAMENT (qb-apartments)")
            elseif Config.Apartment == '0r_motels' and not Custom.Spawn then
                if exports['0r_motels']:GetApartment() then 
                    TriggerServerEvent("0R:Motels:Server:SetPlayerRandomRoom", 'avatar.png')
                end
            elseif Custom.Spawn then 
                Custom.Spawn(data.id)
            end
            Wait(3500)
            SetEntityVisible(PlayerPedId(), true)
            CreatePlayer()
            DoScreenFadeIn(500)
        elseif data.type == "esx_spawn" or ((data.type == "spawn" or data.type == 'custom_place' ) and Config.Framework == 'esx') then
            local coords = (Config.Locations and data.type == "custom_place") and Config.Locations[data.id].coords or Config.DefaultSpawn
            ColocarConSuelo(PlayerPedId(), coords.x, coords.y, coords.z, Config.DefaultSpawn.w)
            SetEntityVisible(PlayerPedId(), true)

            local insideMeta = PlayerData and PlayerData.metadata and PlayerData.metadata["inside"] or {}

            if (insideMeta.apartment and insideMeta.apartment.apartmentType) ~= nil or (insideMeta.apartment and insideMeta.apartment.apartmentId ~= nil) then
                TriggerEvent('qb-apartments:client:LastLocationHouse', insideMeta.apartment.apartmentType, insideMeta.apartment.apartmentId)
            else
                local wait = true
                FW_TriggerCallback('SetDimension', function()
                    wait = false
                end, 0)
                -- Con tope: si SetDimension no contesta, seguir en vez de colgarse.
                local esperaDim = 0
                while wait and esperaDim < 3000 do
                    Citizen.Wait(1)
                    esperaDim = esperaDim + 1
                end
            end
            DoScreenFadeIn(500)
        elseif data.type == "qb_spawn" or ((data.type == "spawn" or data.type == 'custom_place') and Config.Framework == 'qbcore') then
            local coords = (Config.Locations and data.type == "custom_place") and Config.Locations[data.id].coords or Config.DefaultSpawn
            ColocarConSuelo(PlayerPedId(), coords.x, coords.y, coords.z,
                coords.w or Config.DefaultSpawn.w)
            SetEntityVisible(PlayerPedId(), true)
            local wait = true
            FW_TriggerCallback('SetDimension', function()
                wait = false
            end, 0)
            -- Con tope: si SetDimension no contesta, seguir en vez de colgarse.
            local esperaDim = 0
            while wait and esperaDim < 3000 do
                Citizen.Wait(1)
                esperaDim = esperaDim + 1
            end
            --[[ Con la creacion detras, aqui se cierra en vez de abrirse.

                 En negro de verdad, con el fundido nativo, y no solo con el
                 telon de origen_hud: ese es una capa NUI y otra NUI puede
                 acabar por encima. Asi el mundo no se dibuja pase lo que pase,
                 y lo abre AbrirTelon cuando la creacion avisa. ]]
            if vaACreacion then
                DoScreenFadeOut(0)
            else
                DoScreenFadeIn(500)
            end
        elseif data.type == "house" and GetResourceState('origen_housing'):match('start') then 
            exports.origen_housing:loadHouse(data.id, function(house)
                if not house then return end
                FreezeEntityPosition(PlayerPedId(), false)
                SetEntityVisible(PlayerPedId(), true)
                debug("SPAWN IN HOUSE (origen_housing)")
            end, {enter = true})
        end
    else
        DoScreenFadeIn(500)
        Wait(500)
        exports["origen_police"]:SpawnInFederal(PlayerData)
    end
    
    if data.type == "lastplace" or (data.type == "esx_spawn" or data.type == "qb_spawn" or data.type == 'custom_place' or  data.type == "spawn") then
        StopSpawnCamera(true)
    end
    
    SetNuiFocus(false, false)
    hasSpawned = true

    --[[ Desde aqui el jugador ya esta en el mundo. Se marca ANTES de abrir el
         telon porque cuando detras viene la creacion el telon tarda todavia un
         par de segundos, y en ese hueco una respuesta que llega tarde podia
         hacer que la NUI reclamara el raton. ]]
    juegoEnMarcha = true

    --[[ Fin del spawn. Si detras viene la creacion, el telon sigue puesto y lo
         abre el aviso de origen_clothing; si no, se abre ya. ]]
    if vaACreacion then
        esperandoCreacion = true

        --[[ Red de seguridad: si el aviso no llega —origen_clothing parado, un
             fallo por el camino— el jugador no se puede quedar mirando el telon
             para siempre. ]]
        CreateThread(function()
            local desde = GetGameTimer()
            while esperandoCreacion and GetGameTimer() - desde < 20000 do
                Wait(200)
            end
            if esperandoCreacion then
                print('^1[origen_titlemenu] origen_clothing no ha avisado de que la creacion estuviera lista; se abre el telon igual.^0')
                esperandoCreacion = false
                AbrirTelon()
            end
        end)
    else
        AbrirTelon()
    end

    --[[ Avisar a la interfaz de que ya se esta dentro.

         Antes solo se enteraba por la respuesta del callback del servidor, y si
         esa respuesta se perdia por el camino el menu se quedaba puesto encima
         del juego para siempre aunque el jugador ya hubiera aparecido. Este
         aviso sale del propio cliente, en el momento exacto en que el spawn ha
         terminado, asi que no depende de ningun viaje de ida y vuelta. ]]
    SendNUIMessage({ action = "entrado" })
    TriggerEvent('qv2:suppressHud', false)
    if GetResourceState('origen_map') == 'started' then exports.origen_map:Apartar(false) end

    
    -- La escena de audio del menu se arranca en el Setup; si no se para aqui,
    -- se queda sonando dentro del juego.
    StopAudioScene("DLC_MPHEIST_TRANSITION_TO_APT_FADE_IN_RADIO_SCENE")
    playerSpawned()
    if Config.Framework == "qbcore" then
        if data.type == "qb_spawn" or data.type == 'spawn' then
			local model = GetHashKey("mp_m_freemode_01")

			if not HasModelLoaded(model) then RequestModel(model) end

			while not HasModelLoaded(model) do
				RequestModel(model)
				Wait(0)
			end

			SetPlayerModel(PlayerId(), model)
			SetModelAsNoLongerNeeded(model)
            SetPedComponentVariation(PlayerPedId(), 8, 0, 0, 0)
            if Config.ClothSystem == 'codem-appearance' or Config.ClothSystem == 'illenium-appearance' then
                TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
                TriggerEvent('QBCore:Client:OnPlayerLoaded')
            end
            CreatePlayer()
            --TriggerEvent("qb-clothing:client:openMenu")
        else
            --[[ Personaje que ya existia: hay que devolverle su aspecto.
                 playerSpawned() dispara QBCore:Client:OnPlayerLoaded y
                 origen_clothing lo recoge, pero ese aviso llega antes de que el
                 servidor tenga lista la ficha: la consulta vuelve vacia y te
                 quedas con el ped de por defecto (Michael de serie). Se
                 reintenta aqui, ya con el jugador cargado del todo. ]]
            if Config.ClothSystem == 'origen_clothing'
                and GetResourceState('origen_clothing'):match('start') then
                --[[ En linea y no en un hilo aparte: hay que poder esperar a
                     que termine antes de abrir el telon. Antes iba suelto con
                     un Wait(1000) a ciegas, y ese segundo era exactamente el
                     rato que el jugador se veia de Michael. ]]
                Citizen.Wait(250)
                local ok, err = pcall(function()
                    exports.origen_clothing:ReloadAppearanceData()
                end)
                if not ok then
                    print('^1[origen_titlemenu] No se ha podido aplicar el aspecto: '
                        .. tostring(err) .. '^0')
                end
            end

            if data.type == "lastplace" then
                EsperarAspectoPropio()
                DoScreenFadeIn(500)

                --[[ Ya eres tu: la camara puede aterrizar detras de ti y
                     devolver el control. Esta llamada tarda lo que dura el
                     aterrizaje; si la camara no llego a arrancar, vuelve en el
                     acto y solo se asegura de que no te quedas congelado. ]]
                CamaraLlegadaTerminar()
            end
        end
    elseif Config.Framework == "esx" then
        if (data.type ~= "esx_spawn" or data.type == 'spawn') and data.skin then
            TriggerEvent('skinchanger:loadSkin', json.decode(data.skin), function()
                TriggerServerEvent('esx:onPlayerSpawn')
                TriggerEvent('esx:onPlayerSpawn')
                TriggerEvent('playerSpawned')
                TriggerEvent('esx:restoreLoadout')
            end)
        elseif data.type == "esx_spawn" or (data.type == "spawn" and Config.Framework == 'esx') then
			local model = GetHashKey("mp_m_freemode_01")

			if not HasModelLoaded(model) then RequestModel(model) end

			while not HasModelLoaded(model) do
				RequestModel(model)
				Wait(0)
			end

			SetPlayerModel(PlayerId(), model)
			SetModelAsNoLongerNeeded(model)
            CreatePlayer()
			--TriggerEvent('esx_skin:openSaveableMenu')
        end
    end

    PostSpawnPlayer()
    end)

    if not ok then
        print('^1[origen_titlemenu] client:SpawnPlayer ha fallado: ' .. tostring(err) .. '^0')
        SetNuiFocus(false, false)
        juegoEnMarcha = true
        DoScreenFadeIn(500)
        if GetResourceState('origen_hud') == 'started' then
            pcall(function()
                exports['origen_hud']:DoScreenFadeIn(500)
            end)
        end
        -- Y el menu fuera de la pantalla, que no quede pintado sobre el juego.
        SendNUIMessage({ action = "entrado" })
        spawnEnCurso = false
    end
end)

RegisterNetEvent("origen_titlemenu:client:Logout", function()
    --[[ Se vuelve al menu: todo lo que el spawn dejo marcado como "ya dentro"
         se deshace. spawnEnCurso no vuelve a false al acabar un spawn, asi que
         sin esto el siguiente SpawnPlayer se ignoraba; y con juegoEnMarcha en
         true, HudFadeIn ya no le devolvia al menu ni el raton ni la capa. ]]
    spawnEnCurso = false
    hasSpawned = false
    juegoEnMarcha = false
    telonAbierto = false
    esperandoCreacion = false

    DoScreenFadeOut(500)
    Citizen.Wait(200)
    SendNUIMessage({
        action = "logout"
    })
end)

function SetDimension(dimension)
    local wait = true
    FW_TriggerCallback('SetDimension', function()
        wait = false
    end, dimension)
    -- Con tope: si SetDimension no contesta, seguir en vez de colgarse.
    local esperaDim = 0
    while wait and esperaDim < 3000 do
        Citizen.Wait(1)
        esperaDim = esperaDim + 1
    end
end

exports("SetDimension", SetDimension)

RegisterNetEvent("origen_titlemenu:Notify", ShowNotification)

-- -- ONLY ESX

RegisterNetEvent('origen:setPlayerData', function(data)
    SetTimeout(1, function()
        ESX.SetPlayerData("name", ('%s %s'):format(data.firstname, data.lastname))
        ESX.SetPlayerData('firstName', data.firstname)
        ESX.SetPlayerData('lastName', data.lastname)
        ESX.SetPlayerData('dateofbirth', data.dateOfBirth)
        ESX.SetPlayerData('sex', data.sex)
        ESX.SetPlayerData('height', data.height)
        ESX.SetPlayerData('nationality', data.nationality)
    end)
end)

--- Si el recurso se para con el menu puesto, nadie devolveria el logo ni las
--- misiones.
AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    TriggerEvent('qv2:suppressHud', false)
end)

--[[ ══ Los puntos del mapa para la ficha ══════════════════════════════════

     La lamina de la ficha enseña la ciudad con los sitios que ve el personaje:
     son los mismos puntos que pintan el minimapa y el mapa grande, del registro
     de origen_map (su client/registro.lua).

     EL PROBLEMA: en el menu de titulo ese registro esta VACIO. Cada recurso
     apunta los suyos cuando el jugador ya esta dentro —origen_banking, por
     ejemplo, espera a `LocalPlayer.state.isLoggedIn`—, asi que aqui todavia no
     hay nada que enseñar.

     LA SOLUCION: se guarda UNA VEZ y se reparte hecha. Al entrar al juego, el
     cliente manda su lista una sola vez por sesion —y solo si tiene mas puntos
     que los guardados—; el servidor la deja en la base de datos y la sirve
     desde memoria a quien abra el menu (server/puntos_mapa.lua).

     Nada de consultas periodicas: un envio por sesion como mucho, y una
     peticion al abrir el menu. ]]

local TOPE_PUNTOS = 900

--- Los puntos del registro de origen_map, en lo minimo que necesita el dibujo.
---
--- Deja fuera lo que no pinta nada en una ficha: lo pegado a un jugador, lo que
--- late y los avisos de prioridad alta. Lo pegado a una ENTIDAD si entra —son
--- los NPC de tiendas y bancos, que estan siempre en el mismo sitio—.
local function PuntosDelRegistro()
    if GetResourceState('origen_map') ~= 'started' then return {} end

    local ok, puntos = pcall(function() return exports['origen_map']:Puntos() end)
    if not ok or type(puntos) ~= 'table' then return {} end

    local salida = {}
    for i = 1, #puntos do
        local p = puntos[i]
        local fijo = not p.jugador and not p.pulso and (tonumber(p.prioridad) or 0) <= 0

        if p and p.x and p.y and fijo and #salida < TOPE_PUNTOS then
            salida[#salida + 1] = {
                x = math.floor(p.x * 10) / 10,
                y = math.floor(p.y * 10) / 10,
                icono = p.icono,
                cat = p.cat or p.categoria,
                color = p.color,
            }
        end
    end

    return salida
end

--[[ UNA sola aportacion por sesion, y solo si aporta.

     Nada de mirar cada poco: se le da un rato a los recursos para que apunten
     sus puntos, se pregunta al servidor cuantos tiene (un numero) y, si los
     nuestros son mas, se mandan una vez. Despues no se vuelve a mirar.

     Se intenta a los 45 s de entrar, otra vez a los tres minutos si la primera
     vez todavia no habia nada, y AL SALIR al menu: quien juega diez minutos y
     hace /logout se iba sin aportar nada y el mapa se quedaba vacio. ]]
local aportado = false

--- Manda la lista al servidor si aporta algo. Devuelve true cuando ya no hay
--- que volver a intentarlo.
local function IntentarAportar(avisar)
    if aportado then return true end
    if not LocalPlayer.state.isLoggedIn then return false end

    local lista = PuntosDelRegistro()

    if #lista <= 5 then
        if avisar then print(('^3[origen_titlemenu]^0 Mapa: el registro solo tiene %d puntos, todavia no'):format(#lista)) end
        return false
    end

    local ok, cuenta = pcall(function()
        return lib.callback.await('origen_titlemenu:sv:puntosMapaCuenta', false)
    end)
    if not ok then return false end

    cuenta = tonumber(cuenta) or 0

    if #lista > cuenta then
        local ok2, nueva = pcall(function()
            return lib.callback.await('origen_titlemenu:sv:aportarPuntos', false, lista)
        end)
        if avisar then
            print(('^2[origen_titlemenu]^0 Mapa: mandados %d puntos (el servidor tenia %d, ahora %s)')
                :format(#lista, cuenta, ok2 and tostring(nueva) or '?'))
        end
    elseif avisar then
        print(('^2[origen_titlemenu]^0 Mapa: el servidor ya tiene %d puntos y yo %d, no hace falta mandar nada')
            :format(cuenta, #lista))
    end

    aportado = true
    return true
end

--[[ Se mira cada quince segundos hasta que salga, como mucho seis veces.

     Son seis llamadas a un export del propio cliente —gratis— y UNA sola
     peticion al servidor; en cuanto cuela, este hilo se acaba y no vuelve a
     hacer nada en toda la sesion. Antes se esperaba 45 segundos de golpe y
     quien entraba y salia rapido no llegaba a aportar nunca. ]]
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(3000) end

    for _ = 1, 6 do
        Wait(15000)
        if IntentarAportar(false) then return end
    end
end)

--- Al volver al menu con /logout, ultima oportunidad: el registro sigue puesto.
AddEventHandler('origen_titlemenu:client:Logout', function() IntentarAportar(false) end)

--- Para forzarlo a mano y ver que pasa: /puntosmapa
RegisterCommand('puntosmapa', function()
    aportado = false
    if not IntentarAportar(true) then
        print('^3[origen_titlemenu]^0 Mapa: no se ha podido aportar (mira si estas dentro del juego)')
    end
end, false)

RegisterNUICallback('PuntosMapa', function(_, cb)
    --[[ En el menu el registro esta vacio, asi que la lista viene del servidor,
         que la tiene en memoria desde que arranco (server/puntos_mapa.lua). Es
         UNA peticion al abrir el menu, sin base de datos por medio. ]]
    local lista = PuntosDelRegistro()

    if #lista == 0 then
        local ok, delServidor = pcall(function()
            return lib.callback.await('origen_titlemenu:sv:puntosMapa', false)
        end)
        if ok and type(delServidor) == 'table' then lista = delServidor end
    end

    cb(lista)
end)
