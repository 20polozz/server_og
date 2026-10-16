--[[ ── Origen Games · los puntos del mapa ───────────────────────────────────

     Cada juego tiene su punto: donde se abre su menú. Sale en los dos mapas
     del servidor (por origen_map) con el dibujo de su juego, y en el mundo es
     una de tres cosas, según lo haya puesto el staff (Config.Punto):

       marcador    el aro rosa en el suelo y la flecha que flota encima
       npc         un personaje quieto con su modelo y su animación
       recreativa  una máquina recreativa delante de donde se puso el staff

     El NPC y la máquina son de este cliente (no se crean en red): aparecen al
     acercarse y se borran al alejarse. El staff los cambia desde el menú y el
     servidor avisa para montarlos de nuevo.

     Con la recreativa, al empezar la partida quien estaba jugando en ella «se
     mete dentro» (Puntos.Entrar) y al acabar sale de ella (Puntos.Salir). ]]

Puntos = {}

local lista = {}
local zonas = {}
local creados = {}
local textoDe

--- A cuánto se puede pulsar E, según el tipo de punto.
local ALCANCE = { marcador = 2.0, npc = 2.2, recreativa = 1.6 }

--- El gesto de echar monedas y jugar en una máquina de la sala de juegos del casino.
local ANIM_DIC = 'anim_casino_a@amb@casino@games@arcadecabinet@maleright'

local function QuitarTexto(juego)
    if textoDe and (juego == nil or textoDe == juego) then
        lib.hideTextUI()
        textoDe = nil
    end
end

--[[ ── Lo que hay en el mundo ─────────────────────────────────────────────── ]]
local function Cargar(modelo)
    local hash = type(modelo) == 'string' and GetHashKey(modelo) or 0
    if hash == 0 or not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local hasta = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < hasta do Wait(0) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function Delante(p, metros)
    local r = math.rad(p.h or 0.0)
    return p.x - math.sin(r) * metros, p.y + math.cos(r) * metros
end

local function Suelo(x, y, z)
    local hay, suelo = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 1.5, false)
    if hay and math.abs(suelo - z) < 4.0 then return suelo end
    return z - 0.98
end

local function Borrar(juego)
    local c = creados[juego]
    if not c then return end
    if c.entidad and DoesEntityExist(c.entidad) then DeleteEntity(c.entidad) end
    creados[juego] = nil
end

local function Crear(p)
    if creados[p.juego] then return end
    creados[p.juego] = { cargando = true }

    if p.tipo == 'npc' then
        local hash = Cargar(p.modelo) or Cargar(Config.Punto.npc.modeloDefecto)
        if not creados[p.juego] then return end
        if not hash or not IsModelAPed(hash) then creados[p.juego] = nil return end
        local z = Suelo(p.x, p.y, p.z)
        local ped = CreatePed(4, hash, p.x + 0.0, p.y + 0.0, z, (p.h or 0.0) + 0.0, false, false)
        SetModelAsNoLongerNeeded(hash)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanRagdoll(ped, false)
        SetPedDiesWhenInjured(ped, false)
        SetPedCanBeTargetted(ped, false)
        if p.escenario and p.escenario ~= 'quieto' then
            TaskStartScenarioInPlace(ped, p.escenario, 0, true)
        end
        creados[p.juego] = { entidad = ped }

    elseif p.tipo == 'recreativa' then
        local hash = Cargar(p.modelo) or Cargar(Config.Punto.recreativa.modeloDefecto)
        if not creados[p.juego] then return end
        if not hash then creados[p.juego] = nil return end
        local x, y = Delante(p, Config.Punto.recreativa.distancia)
        local z = Suelo(x, y, p.z)
        local obj = CreateObjectNoOffset(hash, x, y, z, false, false, false)
        SetModelAsNoLongerNeeded(hash)
        -- Mirando hacia quien juega: la pantalla de estas máquinas da a su -Y.
        SetEntityHeading(obj, (p.h or 0.0) + 0.0)
        FreezeEntityPosition(obj, true)
        SetEntityInvincible(obj, true)
        creados[p.juego] = { entidad = obj }
    else
        creados[p.juego] = nil
    end
end

local function Limpiar()
    for _, z in pairs(zonas) do z:remove() end
    zonas = {}
    for juego in pairs(creados) do Borrar(juego) end
    QuitarTexto()
end

--[[ ── Montar un punto ───────────────────────────────────────────────────────── ]]
local function Montar(p)
    if not p or not tonumber(p.x) then return end
    p.tipo = p.tipo or 'marcador'
    local sueloZ

    OrigenMapa.Poner('punto_' .. p.juego, {
        x = p.x, y = p.y, z = p.z,
        cat = 'activities',
        icono = p.iconoMapa or 'juego',
        color = Config.Punto.color,
        nombre = p.nombre,
    })

    local alcance = ALCANCE[p.tipo] or 2.0

    zonas[p.juego] = lib.points.new({
        coords = vec3(p.x + 0.0, p.y + 0.0, p.z + 0.0),
        distance = 40.0,
        onEnter = function() CreateThread(function() Crear(p) end) end,
        onExit = function()
            QuitarTexto(p.juego)
            Borrar(p.juego)
        end,
        nearby = function(self)
            if Juego and Juego.activo then return QuitarTexto(p.juego) end

            if p.tipo == 'marcador' then
                if not sueloZ then sueloZ = Suelo(p.x, p.y, p.z) end
                -- Un aro rosa en el suelo y la flecha que flota encima.
                DrawMarker(27, p.x, p.y, sueloZ + 0.03, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.6, 1.6, 1.0, 216, 27, 85, 170, false, false, 2, true, nil, nil, false)
                DrawMarker(20, p.x, p.y, sueloZ + 1.1, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0,
                    0.45, 0.45, 0.45, 216, 27, 85, 190, true, true, 2, false, nil, nil, false)
            elseif self.currentDistance < 6.0 then
                -- Una flecha pequeña encima del NPC o de la máquina, para saber que se habla con él.
                local c = creados[p.juego]
                if c and c.entidad and DoesEntityExist(c.entidad) then
                    local e = GetEntityCoords(c.entidad)
                    local alto = p.tipo == 'npc' and 1.25 or 2.15
                    DrawMarker(20, e.x, e.y, e.z + alto, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0,
                        0.3, 0.3, 0.3, 216, 27, 85, 190, true, true, 2, false, nil, nil, false)
                end
            end

            if self.currentDistance < alcance and not (Menu and Menu.abierto) then
                if textoDe ~= p.juego then
                    lib.showTextUI(('[E] %s%s'):format(p.tipo == 'recreativa' and 'Jugar a ' or '', p.nombre))
                    textoDe = p.juego
                end
                if IsControlJustReleased(0, 38) then
                    QuitarTexto()
                    Menu.Abrir(p.juego)
                end
            else
                QuitarTexto(p.juego)
            end
        end,
    })
end

function Puntos.De(juego)
    for _, p in ipairs(lista) do
        if p.juego == juego then return p end
    end
    return nil
end

local function MontarTodos(nuevos)
    if type(nuevos) ~= 'table' then return end
    Limpiar()
    lista = nuevos
    for _, p in ipairs(lista) do Montar(p) end
end

RegisterNetEvent('origen_games:c:puntos', MontarTodos)

CreateThread(function()
    Wait(2500)
    MontarTodos(lib.callback.await('origen_games:puntos', false))
end)

--[[ ── Meterse en la recreativa ─────────────────────────────────────────────

     Al empezar la partida, si el jugador está junto a la máquina de su
     juego: se pone delante, echa la moneda, la cámara se acerca a la pantalla
     mientras él se desvanece, destello y a negro. Lo llama el núcleo antes
     del primer fundido de la ronda. `sigue()` dice si la partida continúa:
     tras cada espera se mira, y si no, se deja todo como estaba. ]]
local cam

local function SoltarCamara()
    if cam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        cam = nil
    end
    local ped = PlayerPedId()
    ResetEntityAlpha(ped)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    AnimpostfxStop('MinigameTransitionIn')
end

--- Si este jugador está en la recreativa de su juego y hay animación que hacer.
function Puntos.PuedeEntrar(juego)
    local p = Puntos.De(juego)
    local c = creados[juego]
    if not p or p.tipo ~= 'recreativa' or not c or not c.entidad or not DoesEntityExist(c.entidad) then return false end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return false end
    return #(GetEntityCoords(ped) - vector3(p.x, p.y, p.z)) <= 8.0
end

--- Una nube de chispas donde está el personaje (el «plof» de desaparecer).
local function Chispas(x, y, z)
    local asset = 'scr_rcbarry2'
    RequestNamedPtfxAsset(asset)
    local hasta = GetGameTimer() + 1000
    while not HasNamedPtfxAssetLoaded(asset) and GetGameTimer() < hasta do Wait(0) end
    if not HasNamedPtfxAssetLoaded(asset) then return end
    UseParticleFxAsset(asset)
    StartParticleFxNonLoopedAtCoord('scr_clown_appears', x, y, z, 0.0, 0.0, 0.0, 0.8, false, false, false)
    RemoveNamedPtfxAsset(asset)
end

function Puntos.Entrar(juego, sigue)
    if not Puntos.PuedeEntrar(juego) then return end
    local p = Puntos.De(juego)
    local c = creados[juego]
    local ped = PlayerPedId()

    local maquina = c.entidad
    local ok = pcall(function()
        -- Delante de la máquina y mirándola.
        TaskGoStraightToCoord(ped, p.x + 0.0, p.y + 0.0, p.z + 0.0, 1.0, 1500, (p.h or 0.0) + 0.0, 0.1)
        local hasta = GetGameTimer() + 1500
        while GetGameTimer() < hasta and #(GetEntityCoords(ped).xy - vector2(p.x, p.y)) > 0.35 do Wait(50) end
        if not sigue() then return end
        SetEntityHeading(ped, (p.h or 0.0) + 0.0)

        if DoesAnimDictExist(ANIM_DIC) then
            RequestAnimDict(ANIM_DIC)
            local espera = GetGameTimer() + 1500
            while not HasAnimDictLoaded(ANIM_DIC) and GetGameTimer() < espera do Wait(0) end
            if HasAnimDictLoaded(ANIM_DIC) then
                TaskPlayAnim(ped, ANIM_DIC, 'insert_coins', 8.0, -8.0, -1, 0, 0.0, false, false, false)
            end
        end
        PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        Wait(700)
        if not sigue() then return end

        -- La cámara, por encima del hombro y hacia la pantalla.
        local pantalla = GetOffsetFromEntityInWorldCoords(maquina, 0.0, -0.15, 1.35)
        local desde = GetOffsetFromEntityInWorldCoords(ped, 0.35, -0.9, 0.75)
        local cerca = GetOffsetFromEntityInWorldCoords(maquina, 0.0, -0.32, 1.35)

        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(cam, desde.x, desde.y, desde.z)
        PointCamAtCoord(cam, pantalla.x, pantalla.y, pantalla.z)
        SetCamFov(cam, 55.0)
        RenderScriptCams(true, true, 400, true, true)

        local destino = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(destino, cerca.x, cerca.y, cerca.z)
        PointCamAtCoord(destino, pantalla.x, pantalla.y, pantalla.z)
        SetCamFov(destino, 30.0)
        SetCamActiveWithInterp(destino, cam, 1500, 1, 1)
        DestroyCam(cam, false)
        cam = destino

        AnimpostfxPlay('MinigameTransitionIn', 0, false)
        Nui.Enviar('sonido', { tipo = 'turbo', volumen = 0.7, pan = 0.0 })

        --[[ La máquina lo absorbe: el personaje se congela, se desliza hacia la
             pantalla subiendo un poco y se desvanece, cada vez más deprisa. ]]
        local origen = GetEntityCoords(ped)
        FreezeEntityPosition(ped, true)
        SetEntityCollision(ped, false, false)
        local inicio = GetGameTimer()
        local DURA = 1600
        while GetGameTimer() - inicio < DURA do
            local t = (GetGameTimer() - inicio) / DURA
            local e = t * t
            local x = origen.x + (pantalla.x - origen.x) * e * 0.85
            local y = origen.y + (pantalla.y - origen.y) * e * 0.85
            local z = origen.z + (pantalla.z - 0.6 - origen.z) * e
            SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
            SetEntityAlpha(ped, math.max(0, math.floor(255 * (1.0 - e))), false)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.02)
            Wait(0)
            if not sigue() then break end
        end
        Chispas(pantalla.x, pantalla.y, pantalla.z)
        PlaySoundFrontend(-1, 'Hack_Success', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS', true)
        SetEntityCoordsNoOffset(ped, origen.x, origen.y, origen.z, false, false, false)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        if not sigue() then return end

        Wait(250)
        DoScreenFadeOut(300)
        Wait(330)
    end)

    SoltarCamara()
    if not ok and not sigue() then DoScreenFadeIn(300) end
end

--- Al volver de la partida junto a la recreativa: sale de la máquina.
function Puntos.Salir(juego)
    local p = Puntos.De(juego)
    if not p or p.tipo ~= 'recreativa' then return end
    AnimpostfxPlay('MinigameTransitionOut', 0, false)
    PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)
    SetEntityHeading(PlayerPedId(), ((p.h or 0.0) + 180.0) % 360.0)
end

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    QuitarTexto()
    if cam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cam, false)
        cam = nil
        ResetEntityAlpha(PlayerPedId())
    end
    for juego in pairs(creados) do Borrar(juego) end
end)
