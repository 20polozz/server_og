spawned = {}
local selected = nil
local currentSelectedPed = nil

HUESO_CABEZA = 0x796E          -- SKEL_Head

--[[ Los encuadres del selector de personaje. El jugador elige entre ellos con
     los iconos de la derecha; tu los ajustas en vivo con F2 y se guardan en
     config/camaras.json.

       anclaje    'cabeza' cuelga del hueso de la cabeza (encuadra igual a
                  cualquier estatura); 'suelo' mide la altura desde los pies
       altura     sube o baja respecto al anclaje
       distancia  cuanto se separa la camara
       lateral    desplazamiento a los lados
       angulo     giro alrededor del personaje, en grados (0 de frente)
       fov        cuanto abarca el objetivo (menos = mas cerrado)
       seguir     si la cabeza sigue al raton                                 ]]
VISTAS = { 'cara', 'cuerpo' }

CAMARAS = {
    cara = {
        anclaje = 'cabeza', altura = 0.04, distancia = 0.70,
        lateral = 0.0, angulo = 0.0, fov = 27.0, seguir = true,
    },
    cuerpo = {
        anclaje = 'suelo', altura = 1.0, distancia = 2.60,
        lateral = 0.0, angulo = 0.0, fov = 40.0, seguir = false,
    },
}

--- Vista elegida ahora mismo.
VistaActual = 'cara'

--[[ APARTAR AL PERSONAJE DEL PANEL DE LA FICHA

     Desde el 14/09 la ficha es una columna a la derecha (source-ui,
     components/FichaPanel.vue) y tapaba el tercio derecho de la pantalla: el
     personaje, centrado en la pantalla entera, quedaba descentrado en el hueco
     que se ve. Se corre la camara hacia su derecha —camara y mira a la vez, sin
     girar— lo justo para que caiga en el centro de ese hueco.

     Cuanto: el panel ocupa `ocupa` px por la derecha, asi que el centro del
     hueco esta `ocupa / 2` px a la izquierda del centro. Pasado a metros a la
     distancia del ped, y como el FOV de la camara es VERTICAL, el ancho de la
     pantalla se cancela y solo queda el alto:

         metros = ocupa / alto * distancia * tan(fov / 2)

     Por eso sirve igual en 16:9 que en 21:9. Las medidas del panel son las de
     FichaPanel.vue: si cambian alli, cambian aqui. ]]
local PANEL_FICHA_PX = 548 + 58 + 10     -- columna + barra + hueco entre ellas
local PANEL_FICHA_VH = 0.012             -- el margen de 1.2vh contra el canto

--- Lo pone SelectCharacter: solo con un personaje ya creado hay panel.
ApartarParaPanel = false

local function DesplazamientoPanel(c)
    if not ApartarParaPanel then return 0.0 end
    local _, alto = GetActiveScreenResolution()
    if not alto or alto <= 0 then return 0.0 end
    local ocupa = PANEL_FICHA_PX + PANEL_FICHA_VH * alto
    -- Negativo: `lado` (abajo) apunta a la IZQUIERDA de la camara, y para que el
    -- personaje se vea a la izquierda la camara tiene que irse a su derecha.
    return -(ocupa / alto) * c.distancia * math.tan(math.rad(c.fov) / 2.0)
end

do
    local guardado = LoadResourceFile(GetCurrentResourceName(), 'config/camaras.json')
    if guardado then
        local ok, datos = pcall(json.decode, guardado)
        if not ok or type(datos) ~= 'table' then
            print('^1[origen_titlemenu] config/camaras.json ilegible; se usan los de fabrica.^0')
        else
            for vista, valores in pairs(datos) do
                if CAMARAS[vista] and type(valores) == 'table' then
                    for k, v in pairs(valores) do
                        if type(CAMARAS[vista][k]) == 'number' and type(v) == 'number' then
                            CAMARAS[vista][k] = v + 0.0
                        end
                    end
                end
            end
        end
    end
end

local camaraCara = nil
local siguiendoRaton = false

function PararCamaraCara(sinTransicion)
    siguiendoRaton = false
    if camaraCara and DoesCamExist(camaraCara) then
        if not sinTransicion then
            RenderScriptCams(false, true, 500, true, false)
        end
        DestroyCam(camaraCara, false)
    end
    camaraCara = nil
end

--[[ Coordenadas de camara y de mira de una vista.

     Todo se calcula en coordenadas del MUNDO, partiendo del anclaje y
     separandose en la direccion en que mira el ped, girada por `angulo`. Se usa
     el vector de avance del ped y no los ejes locales del hueso porque el eje
     local de la cabeza apunta hacia atras: haciendolo asi la camara acababa
     detras y se veia la nuca.                                                ]]
function PuntosCamara(ped, vista)
    local c = CAMARAS[vista] or CAMARAS.cara

    local base
    if c.anclaje == 'cabeza' then
        base = GetWorldPositionOfEntityBone(ped, GetPedBoneIndex(ped, HUESO_CABEZA))
    else
        base = GetEntityCoords(ped)
    end

    -- Direccion de la camara: el frente del ped girado `angulo` grados.
    local rad = math.rad(GetEntityHeading(ped) + c.angulo)
    local frente = vector3(-math.sin(rad), math.cos(rad), 0.0)
    local lado = vector3(frente.y, -frente.x, 0.0)

    -- El lateral del encuadre (F2) mas lo que haga falta para librar el panel.
    local lateral = c.lateral + DesplazamientoPanel(c)

    local mira = vector3(
        base.x + lado.x * lateral,
        base.y + lado.y * lateral,
        base.z + c.altura)

    local pos = vector3(
        mira.x + frente.x * c.distancia,
        mira.y + frente.y * c.distancia,
        mira.z)

    return pos, mira, c
end

--- El ped que se esta retratando ahora mismo, o nil.
function PedRetratado()
    return currentSelectedPed
end

--- Recoloca la camara ya existente sin recrearla. Para el modo de ajuste.
function RefrescarCamaraCara(ped)
    if not camaraCara or not DoesCamExist(camaraCara) or not ped or not DoesEntityExist(ped) then return end
    local pos, mira, c = PuntosCamara(ped, VistaActual)
    SetCamCoord(camaraCara, pos.x, pos.y, pos.z)
    SetCamFov(camaraCara, c.fov)
    PointCamAtCoord(camaraCara, mira.x, mira.y, mira.z)
end

--- Cambia de vista sobre el ped que ya esta en camara.
function CambiarVista(vista)
    if not CAMARAS[vista] then return false end
    VistaActual = vista
    local ped = currentSelectedPed
    if ped and DoesEntityExist(ped) then IniciarCamaraCara(ped) end
    return true
end

function IniciarCamaraCara(ped)
    if not ped or not DoesEntityExist(ped) then return end

    local anterior = camaraCara
    siguiendoRaton = false

    local pos, mira, c = PuntosCamara(ped, VistaActual)

    camaraCara = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', pos, 0.0, 0.0, 0.0, c.fov, false, 0)
    PointCamAtCoord(camaraCara, mira)

    --[[ Desenfoque de fondo: es lo que hace que el retrato se vea cuidado.
         Solo en el plano corto: en cuerpo entero, con el ped a mas de dos
         metros, desenfocaria al propio personaje. ]]
    if c.anclaje == 'cabeza' then
        SetCamUseShallowDofMode(camaraCara, true)
        SetCamNearDof(camaraCara, 0.2)
        SetCamFarDof(camaraCara, 1.0)
        SetCamDofStrength(camaraCara, 1.0)
    end

    --[[ Solo se interpola al pasar de un retrato a otro, que ahi el viaje de
         camara queda bien. Al entrar por primera vez se corta directamente al
         encuadre configurado: si se interpolaba desde el plano general, la
         camara bajaba desde arriba durante casi un segundo antes de colocarse,
         y eso no lo queremos. ]]
    if anterior and DoesCamExist(anterior) then
        SetCamActiveWithInterp(camaraCara, anterior, 900, 1, 1)
        Citizen.CreateThread(function()
            Citizen.Wait(900)
            if DoesCamExist(anterior) then
                SetCamActive(anterior, false)
                DestroyCam(anterior, false)
            end
        end)
    else
        SetCamActive(camaraCara, true)
        RenderScriptCams(true, false, 0, true, false)   -- sin viaje: corte seco
    end

    siguiendoRaton = true
    local esta = camaraCara

    --[[ El escenario que se le pone al llegar (TaskStartScenarioInPlace) hace
         que el cuerpo se balancee. En el retrato estorba: en origen_clothing el
         ped esta completamente quieto y solo se mueve la cabeza. Se le quitan
         las tareas y se le fuerza el estado de movimiento a ninguno. ]]
    ClearPedTasksImmediately(ped)

    local conDof = c.anclaje == 'cabeza'
    local sigueCabeza = c.seguir

    Citizen.CreateThread(function()
        while siguiendoRaton and esta == camaraCara and DoesEntityExist(ped) do
            -- El desenfoque hay que renovarlo cada frame o no se aplica.
            if conDof then SetUseHiDof() end

            -- Quieto del todo: congelado, sin velocidad y sin estado de
            -- movimiento. Las tres cosas, como hace el creador de ropa.
            FreezeEntityPosition(ped, true)
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
            ForcePedMotionState(ped, `MotionState_None`, false, 1, true)

            if sigueCabeza then
                -- Posicion del raton en pantalla -> punto del mundo al que mirar.
                local x = GetDisabledControlNormal(0, 239)
                local y = GetDisabledControlNormal(0, 240)
                local mundo = GetWorldCoordFromScreenCoord(x, y)
                TaskLookAtCoord(ped, mundo.x, mundo.y, mundo.z, 1000, 16384, 2)
            end

            Citizen.Wait(0)
        end
    end)
end

function SetupPeds(model, clothing)
    debuger('peds','^3recibed',model, type(model))

    --[[ Un personaje que nunca acabo el creador de ropa no tiene modelo
         guardado, asi que aqui llegaba nil. GetHashKey(nil) no da un modelo
         valido y el bucle de mas abajo esperaba para siempre: el callback
         SelectCharacter no volvia nunca, no se creaba el ped, la camara no se
         movia y la pantalla se quedaba en negro. Sin modelo se usa uno por
         defecto en vez de colgarse. ]]
    if model == nil or model == '' or model == 0 then
        model = 'mp_m_freemode_01'
        debuger('peds','^1sin modelo, se usa el de por defecto^0', model)
    end

    model = type(model) == 'number' and model or tonumber(model) ~= nil and tonumber(model) or GetHashKey(model)
    debuger('peds','^2out',model, type(model))

    if not IsModelInCdimage(model) or not IsModelValid(model) then
        debuger('peds','^1modelo desconocido, se usa el de por defecto^0', model)
        model = GetHashKey('mp_m_freemode_01')
    end

    if not HasModelLoaded(model) then
        RequestModel(model)
    end
    debuger('peds','^3waiting for model^0', model)

    -- Con tope: si un modelo no llega a cargar, mejor no crear el ped que
    -- dejar colgado a quien nos haya llamado.
    local esperas = 0
    while not HasModelLoaded(model) do
        Citizen.Wait(10)
        esperas = esperas + 1
        if esperas > 500 then          -- 5 s
            debuger('peds','^1el modelo no ha cargado, se abandona^0', model)
            return nil
        end
    end
    debuger('peds','^2charged',model)
    local spawn = #spawned + 1 -- Assign unique index
    local cfg = (Config.CinematicSpawns and Config.CinematicSpawns[1]) and Config.CinematicSpawns[1] or { coords = vector4(0,0,0,0) }
    if Config.CinematicSpawns and Config.CinematicSpawns[spawn] then
        cfg = Config.CinematicSpawns[spawn]
    end

    debuger ('peds','^3Spawning ped with model:^0',model,spawn)
    
    -- Calculate left entry position (same as SelectCharacter)
    local targetCoords = cfg.coords
    local sideOffset = 2.5
    local headingRad = math.rad(targetCoords.w)
    local forwardX = -math.sin(headingRad)
    local forwardY = math.cos(headingRad)
    local rightX = forwardY
    local rightY = -forwardX
    local leftPos = vector3(targetCoords.x + (rightX * sideOffset), targetCoords.y + (rightY * sideOffset), targetCoords.z)
    local walkHeading = targetCoords.w + 90.0
    if walkHeading >= 360.0 then walkHeading = walkHeading - 360.0 end
    
    -- Spawn at left entry position, facing walk direction
    local ped = CreatePed(4, model, leftPos.x, leftPos.y, leftPos.z, walkHeading, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityVisible(ped, false) -- Start invisible
    
    debuger('peds','^3| ped number:^0', ped)
    spawned[spawn] = ped
    SetPedConfigFlag(ped, 79, true)

    -- Removed animation playback from here to prevent premature execution

    if clothing then
        debuger('peds','^3Set skin...:^0',ped, clothing )
        if Config.ClothSystem == 'illenium-appearance' or Config.ClothSystem == 'codem-appearance' then clothing.model = model end
        SetSkin(ped, clothing)
        debuger('peds','^2skin set:^0',ped )
    end
    debuger('peds','^2 return Ped:^0',ped )
    return ped
end

local function PlayPedAnimation(ped, cfg)
    if cfg.anim then
        if not HasAnimDictLoaded(cfg.anim.dict) then RequestAnimDict(cfg.anim.dict) end 
        while not HasAnimDictLoaded(cfg.anim.dict) do
            Citizen.Wait(0)
        end
        TaskPlayAnim(ped, cfg.anim.dict, cfg.anim.anim, 1.5, 1.5, -1, cfg.anim.legs and 49 or 1, 0, false, false, false)
    elseif cfg.scenario then
        TaskStartScenarioInPlace(ped, cfg.scenario, 0, true)
    end
end

function SelectCharacter(ped, zoff)
    if not ped or not DoesEntityExist(ped) then return end

    debuger("[TITLEMENU] Selection Change - Incoming:", ped)
    
    -- Determinar si es un ped de creación o un personaje existente
    local isCreationPed = false
    local cfg = (Config.CinematicSpawns and Config.CinematicSpawns[1]) and Config.CinematicSpawns[1] or { coords = vector4(0,0,0,0) }
    
    -- Buscar en spawned (personajes existentes)
    local foundInSpawned = false
    for i, p in pairs(spawned) do
        if p == ped and Config.CinematicSpawns[i] then
            cfg = Config.CinematicSpawns[i]
            foundInSpawned = true
            break
        end
    end
    
    -- Si no está en spawned, es un ped de creación
    if not foundInSpawned then
        isCreationPed = true
        cfg = { coords = Config.CreationCoords, scenario = "WORLD_HUMAN_GUARD_STAND" }
    end

    -- El apartado de camara era para la ficha en columna del 14/09. Con la
    -- ficha del 11/09 (dos columnas que enmarcan al personaje, recuperada el
    -- 14/09) el personaje va centrado: se deja apagado.
    ApartarParaPanel = false

    -- If clicking the same character, just ensure camera is set up and return
    if currentSelectedPed == ped then
        -- Ya esta colocado: directo al plano de la cara.
        IniciarCamaraCara(ped)
        DoScreenFadeIn(1000)
        return
    end

    local targetCoords = cfg.coords
    local sideOffset = 2.5
    
    local headingRad = math.rad(targetCoords.w)
    local forwardX = -math.sin(headingRad)
    local forwardY = math.cos(headingRad)
    local rightX = forwardY
    local rightY = -forwardX
    
    -- leftPos (Spawn - Camera Left) 
    -- rightPos (Exit - Camera Right)
    local leftPos = vector3(targetCoords.x + (rightX * sideOffset), targetCoords.y + (rightY * sideOffset), targetCoords.z)
    local rightPos = vector3(targetCoords.x - (rightX * sideOffset), targetCoords.y - (rightY * sideOffset), targetCoords.z)

    -- Walking direction: 90 degrees to the right of camera
    -- Character walks from left to right, facing right
    local walkHeading = targetCoords.w + 90.0
    if walkHeading >= 360.0 then walkHeading = walkHeading - 360.0 end

    --[[ 1. EL QUE SALE
         Antes se iba andando hacia un lado y se desvanecia, unos 4 segundos.
         Ahora desaparece en el sitio: el personaje elegido tiene que estar
         delante de la camara al instante, no despues de una caminata. ]]
    local outgoingPed = currentSelectedPed
    if outgoingPed and DoesEntityExist(outgoingPed) then
        ClearPedTasksImmediately(outgoingPed)
        SetEntityVisible(outgoingPed, false)
        SetEntityAlpha(outgoingPed, 255, false)
        ResetEntityAlpha(outgoingPed)
        FreezeEntityPosition(outgoingPed, true)
        SetEntityCollision(outgoingPed, false, false)
        SetEntityCoords(outgoingPed, targetCoords.x, targetCoords.y, targetCoords.z)

        -- Los peds de creacion no se reutilizan.
        if not foundInSpawned then
            DeleteEntity(outgoingPed)
        end
    end

    -- 2. INCOMING
    currentSelectedPed = ped
    
    --[[ Colocado en el sitio, sin caminata. Antes entraba andando desde un lado
         y tardaba unos 4 segundos en ponerse delante de la camara; ahora
         aparece ya en su posicion, mirando al objetivo. ]]
    ClearPedTasksImmediately(ped)

    for _, otherPed in pairs(spawned) do
        if DoesEntityExist(otherPed) and otherPed ~= ped then
            SetEntityNoCollisionEntity(ped, otherPed, false)
        end
    end

    SetEntityCoords(ped, targetCoords.x, targetCoords.y, targetCoords.z)
    SetEntityHeading(ped, targetCoords.w)
    SetEntityVisible(ped, true)
    SetEntityAlpha(ped, 255, false)
    ResetEntityAlpha(ped)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, true)
    SetPedConfigFlag(ped, 79, true)
    PlayPedAnimation(ped, cfg)

    --[[ La camara NO se puede montar en la misma linea que el teleport: los
         huesos del ped tardan un fotograma en recolocarse, asi que
         GetPedBoneCoords devolveria todavia la cabeza en su sitio anterior y el
         encuadre saldria desplazado —se veian las piernas—. Se espera a que el
         hueso este de verdad donde toca. ]]
    Citizen.CreateThread(function()
        local objetivo = vector3(targetCoords.x, targetCoords.y, targetCoords.z)

        for _ = 1, 30 do                       -- medio segundo como mucho
            Citizen.Wait(0)
            if currentSelectedPed ~= ped or not DoesEntityExist(ped) then return end
            local cabeza = GetWorldPositionOfEntityBone(ped, GetPedBoneIndex(ped, 0x796E))
            -- La cabeza queda por encima de los pies y sobre la misma vertical.
            if cabeza.z - objetivo.z > 1.2 and #(vector3(cabeza.x, cabeza.y, objetivo.z) - objetivo) < 0.6 then
                break
            end
        end

        if currentSelectedPed == ped and DoesEntityExist(ped) then
            IniciarCamaraCara(ped)
        end
    end)

    -- Static Cam
    local camPos = Config.FixedCamera.xyz
    local camRot = vector3(-5.0, 0.0, Config.FixedCamera.w)

    if not selected then
        selected = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, 40.0, false, 2)
    end
    SetCamActive(selected, true)
    RenderScriptCams(true, true, 800, true, false)
    
    DoScreenFadeIn(1000)
end

function UnselectCharacter(instant)
    -- Se suelta el plano de la cara y el seguimiento del raton.
    PararCamaraCara(instant)

    if instant and currentSelectedPed then
        local ped = currentSelectedPed
        if DoesEntityExist(ped) then
            ClearPedTasksImmediately(ped)
            SetEntityAlpha(ped, 255, false)
            ResetEntityAlpha(ped)
            SetEntityVisible(ped, false)
            FreezeEntityPosition(ped, true)
            SetEntityCollision(ped, false, false)
        end
        currentSelectedPed = nil
        return
    end

    if currentSelectedPed then
        local outgoingPed = currentSelectedPed
        Citizen.CreateThread(function()
            if DoesEntityExist(outgoingPed) then
                -- Determinar si es un ped de creación o un personaje existente
                local cfg = (Config.CinematicSpawns and Config.CinematicSpawns[1]) and Config.CinematicSpawns[1] or { coords = vector4(0,0,0,0) }
                local foundInSpawned = false
                
                for i, p in pairs(spawned) do
                    if p == outgoingPed and Config.CinematicSpawns[i] then
                        cfg = Config.CinematicSpawns[i]
                        foundInSpawned = true
                        break
                    end
                end
                
                -- Si no está en spawned, es un ped de creación
                if not foundInSpawned then
                    cfg = { coords = Config.CreationCoords, scenario = "WORLD_HUMAN_GUARD_STAND" }
                end
                
                local targetCoords = cfg.coords
                local sideOffset = 2.5
                
                local headingRad = math.rad(targetCoords.w)
                local forwardX = -math.sin(headingRad)
                local forwardY = math.cos(headingRad)
                local rightX = forwardY
                local rightY = -forwardX
                
                -- Sin caminata de salida: al volver a la lista el ped se retira
                -- en el sitio, igual que al seleccionar aparece ya colocado.
                ClearPedTasksImmediately(outgoingPed)
                SetEntityAlpha(outgoingPed, 255, false)
                ResetEntityAlpha(outgoingPed)
                SetEntityVisible(outgoingPed, false)
                ClearPedTasks(outgoingPed)
                FreezeEntityPosition(outgoingPed, true)
                SetEntityCollision(outgoingPed, false, false)
                SetEntityCoords(outgoingPed, targetCoords.x, targetCoords.y, targetCoords.z)

                if not foundInSpawned then
                    DeleteEntity(outgoingPed)
                end
            end
        end)
        currentSelectedPed = nil
    end
    
    -- Keep camera active - don't destroy it
    -- This prevents camera jumping when reselecting
end

-- Keep selection/camera state in sync when creation ped is recreated.
function SyncSelectedPedReference(oldPed, newPed)
    if not newPed or not DoesEntityExist(newPed) then return end

    if currentSelectedPed == oldPed or not currentSelectedPed or not DoesEntityExist(currentSelectedPed) then
        currentSelectedPed = newPed
    end

    if selected and DoesCamExist(selected) then
        SetCamActive(selected, true)
        RenderScriptCams(true, false, 0, true, false)
    end
end


function SpawnCreationPed(model)
    model = tonumber(model) or GetHashKey(model)
    if not HasModelLoaded(model) then RequestModel(model) end
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end
    
    local targetCoords = Config.CreationCoords
    local sideOffset = 2.5 -- Increased to start outside FOV
    local headingRad = math.rad(targetCoords.w)
    local forwardX = -math.sin(headingRad)
    local forwardY = math.cos(headingRad)
    local rightX = forwardY
    local rightY = -forwardX
    
    local leftPos = vector3(targetCoords.x + (rightX * sideOffset), targetCoords.y + (rightY * sideOffset), targetCoords.z)
    
    -- Walking direction: 90 degrees to the right of camera (same as SelectCharacter)
    local walkHeading = targetCoords.w + 90.0
    if walkHeading >= 360.0 then walkHeading = walkHeading - 360.0 end

    -- Crear ped en posición izquierda, invisible inicialmente
    local ped = CreatePed(4, model, leftPos.x, leftPos.y, leftPos.z, walkHeading, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityVisible(ped, false)  -- Invisible hasta que SelectCharacter lo active
    SetEntityAlpha(ped, 255, false)
    SetPedConfigFlag(ped, 79, true)
    FreezeEntityPosition(ped, true)  -- Congelado hasta que SelectCharacter lo mueva
    
    -- NO mover el ped aquí - SelectCharacter se encargará de la animación completa
    
    return ped
end

-- on resource stop 
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        UnselectCharacter()
        for k,v in pairs(spawned) do
            if DoesEntityExist(v) then
                debuger('peds','^1Deleting ped^0', v)
                DeletePed(v)
            end
        end
    end
end)
