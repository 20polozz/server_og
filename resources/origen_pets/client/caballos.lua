--[[ ── Mascotas · montar a caballo ──────────────────────────────────────────

     El jinete va ENGANCHADO al caballo con la postura del quad; el caballo es
     un ped del servidor al que se le va diciendo hacia donde ir segun las
     teclas de andar y la camara, igual que se mueve uno a pie. ]]

local montado = nil      -- la entidad del caballo que se monta
local preparados = {}    -- [entidad] = true: ya se le quito el miedo en este cliente

local function Aviso(texto, tipo)
    if GetResourceState('origen_notify') == 'started' then
        exports.origen_notify:Notify(texto, tipo or 'info')
    end
end
RegisterNetEvent('origen_pets:caballos:cl:aviso', Aviso)

local function Texto(tecla, accion)
    if GetResourceState('origen_notify') ~= 'started' then return end
    if tecla then exports.origen_notify:DrawText(tecla, accion) else exports.origen_notify:HideText() end
end

--[[ Un caballo se reconoce por su MODELO, venga de donde venga: los que trae
     el comando de pruebas (`/caballo`) y los que alguien saca como mascota. ]]
local porHash = {}
for nombre in pairs(Config.Caballos.Modelos) do porHash[joaat(nombre)] = nombre end

local function EsCaballo(ped)
    return porHash[GetEntityModel(ped)] ~= nil and not IsPedAPlayer(ped) and NetworkGetEntityIsNetworked(ped)
end

local function DatosDe(ent)
    return Config.Caballos.Modelos[porHash[GetEntityModel(ent)]]
end

--- Los de `/caballo` los monta cualquiera; una mascota, solo quien la saco.
local function PuedoMontar(ped)
    return Entity(ped).state.caballo ~= nil or NetworkGetEntityOwner(ped) == cache.playerId
end

--- Un caballo es un ciervo: sin esto sale huyendo de la gente y de los coches.
local function Amansar(ent)
    SetBlockingOfNonTemporaryEvents(ent, true)
    SetPedFleeAttributes(ent, 0, false)
    SetPedCombatAttributes(ent, 17, true)
    SetPedCanRagdoll(ent, false)
    SetPedCanBeTargetted(ent, false)
    SetPedKeepTask(ent, true)
    -- Sin esto toma al jinete por un peaton que tiene delante: frena y da
    -- vueltas para rodearlo (2 m/s en vez de 15).
    SetPedSteersAroundPeds(ent, false)
end

local function Control(ent)
    if NetworkHasControlOfEntity(ent) then return true end
    NetworkRequestControlOfEntity(ent)
    local hasta = GetGameTimer() + 1500
    while not NetworkHasControlOfEntity(ent) and GetGameTimer() < hasta do Wait(0) end
    return NetworkHasControlOfEntity(ent)
end

local function CaballoCerca()
    local yo = GetEntityCoords(cache.ped)
    local mejor, dist = nil, Config.Caballos.DistanciaMontar
    for _, ped in ipairs(GetGamePool('CPed')) do
        if EsCaballo(ped) and PuedoMontar(ped) then
            local d = #(GetEntityCoords(ped) - yo)
            if d < dist and not IsEntityDead(ped) then mejor, dist = ped, d end
        end
    end
    return mejor
end

--[[ La postura va en dos capas. Las PIERNAS son las del quad, que caen en
     los estribos, pero esa animacion encorva el tronco 22 grados; encima va,
     de cintura para arriba, el TRONCO de la moto chopper, que lo deja
     vertical. Al galope se quita la capa de arriba y el jinete se inclina. ]]
local erguido = nil
local function Postura(ped, recto, yaMismo)
    local p = Config.Caballos.Postura
    lib.requestAnimDict(p.piernas.dict, 5000)
    lib.requestAnimDict(p.tronco.dict, 5000)
    if not IsEntityPlayingAnim(ped, p.piernas.dict, p.piernas.anim, 3) then
        TaskPlayAnim(ped, p.piernas.dict, p.piernas.anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    end
    if recto then
        -- 49 = en bucle, solo medio cuerpo y por encima de la otra.
        TaskPlayAnim(ped, p.tronco.dict, p.tronco.anim, yaMismo and 8.0 or 2.0, -2.0, -1, 49, 0.0, false, false, false)
    else
        StopAnimTask(ped, p.tronco.dict, p.tronco.anim, -2.0)
    end
    erguido = recto
end

--[[ Enganchado al LOMO (un hueso), no al cuerpo entero: asi sube, baja y se
     inclina con cada zancada. Los ejes del hueso van girados un cuarto de
     vuelta respecto al caballo: su X mira hacia delante. ]]
local function Sentar(ent)
    local d = DatosDe(ent)
    local ped = cache.ped
    local hueso = GetPedBoneIndex(ent, Config.Caballos.HuesoLomo)
    AttachEntityToEntity(ped, ent, hueso, d.asiento.atras, 0.0, d.asiento.alto, d.asiento.inclina or 0.0, 0.0, -90.0, false, false, false, true, 2, true)
    Postura(ped, true, true)
end

--- Si el arma que lleva en la mano se puede usar a caballo (las de una mano).
local function ArmaDeMontar(ped)
    local D = Config.Caballos.Disparo
    if not D or not D.activo then return false end
    local arma = GetSelectedPedWeapon(ped)
    if arma == `WEAPON_UNARMED` then return false end
    local grupo = GetWeapontypeGroup(arma)
    for _, g in ipairs(D.grupos) do if g == grupo then return true end end
    for _, a in ipairs(D.armas) do if a == arma then return true end end
    return false
end

--[[ Apuntar como desde la moto. El apuntado del juego NO se usa: con el no
     se puede ir sentado (pone de pie al jinete). El tronco lleva el disparo
     del quad parado en su fase, y el tiro sale con SetPedShootsAtCoord hacia
     donde mira la camara: bala, municion y ruido de verdad. ]]
local apuntando = nil   -- el clip puesto: 'sweep_low' | 'sweep_med' | 'sweep_high' | nil
local function Apuntar(ped, clip)
    local p, D = Config.Caballos.Postura, Config.Caballos.Disparo
    if apuntando and apuntando ~= clip then StopAnimTask(ped, D.dict, apuntando, -8.0) end
    if clip then
        lib.requestAnimDict(D.dict, 5000)
        StopAnimTask(ped, p.tronco.dict, p.tronco.anim, 8.0)
        if not IsEntityPlayingAnim(ped, D.dict, clip, 3) then
            TaskPlayAnim(ped, D.dict, clip, 8.0, -8.0, -1, 1 + 16 + 32, 0.5, false, false, false)
        end
    else
        erguido = nil   -- que vuelva el tronco de siempre
    end
    apuntando = clip
end

--- Hacia donde mira la camara respecto al caballo, como fase del disparo.
local function FaseDeCamara(ent)
    local giro = (GetGameplayCamRot(2).z - GetEntityHeading(ent) + 540.0) % 360.0 - 180.0   -- + a la izquierda
    return math.max(0.0, math.min(1.0, (180.0 - giro) / 360.0))
end

--- El punto al que se apunta: lo primero que toca el rayo de la camara.
local function Blanco(ent)
    local c = GetGameplayCamCoord()
    local r = GetGameplayCamRot(2)
    local x, z = math.rad(r.x), math.rad(r.z)
    local dir = vector3(-math.sin(z) * math.cos(x), math.cos(z) * math.cos(x), math.sin(x))
    local hasta = c + dir * 150.0
    local prueba = StartExpensiveSynchronousShapeTestLosProbe(c.x, c.y, c.z, hasta.x, hasta.y, hasta.z, 511, ent, 7)
    local _, toca, punto = GetShapeTestResult(prueba)
    return toca == 1 and punto or hasta
end

local ultimoTiro = 0
local function Disparar(ped, ent)
    local D = Config.Caballos.Disparo
    local arma = GetSelectedPedWeapon(ped)
    local pistola = GetWeapontypeGroup(arma) == `GROUP_PISTOL`
    local quiere = pistola and IsDisabledControlJustPressed(0, 24) or (not pistola and IsDisabledControlPressed(0, 24))
    if not quiere then return end
    local ahora = GetGameTimer()
    if ahora - ultimoTiro < (pistola and D.cadencia.pistola or D.cadencia.rafaga) * 1000 then return end
    local _, cargador = GetAmmoInClip(ped, arma)
    if cargador <= 0 then
        if GetAmmoInPedWeapon(ped, arma) > 0 then MakePedReload(ped) end
        return
    end
    ultimoTiro = ahora
    local b = Blanco(ent)
    SetPedShootsAtCoord(ped, b.x, b.y, b.z, true)
end

local function Desmontar()
    local ent = montado
    if not ent then return end
    montado = nil
    LocalPlayer.state:set('montado', false, true)
    if apuntando then Apuntar(cache.ped, nil) end
    local ped = cache.ped
    DetachEntity(ped, true, false)
    ClearPedTasks(ped)
    if DoesEntityExist(ent) then
        -- Al suelo, a la izquierda del caballo, que es por donde se baja uno.
        local l = GetOffsetFromEntityInWorldCoords(ent, -0.95, 0.0, 0.0)
        local hay, z = GetGroundZFor_3dCoord(l.x, l.y, l.z + 1.0, false)
        SetEntityCoordsNoOffset(ped, l.x, l.y, (hay and z or l.z) + 1.0, false, false, false)
        SetEntityHeading(ped, GetEntityHeading(ent))
        if NetworkHasControlOfEntity(ent) then
            ClearPedTasks(ent)
            TaskStandStill(ent, -1)
        end
        TriggerServerEvent('origen_pets:caballos:sv:desmontar', NetworkGetNetworkIdFromEntity(ent))
        -- Para mascota.lua: que vuelva a lo que estuviera haciendo.
        TriggerEvent('origen_pets:caballos:cl:desmontado', ent)
    end
    Texto()
end

--- Hacia donde quiere ir el jinete: las teclas de andar respecto a la camara.
local function Rumbo()
    local x = GetDisabledControlNormal(0, 30)
    local y = GetDisabledControlNormal(0, 31)
    if x * x + y * y < 0.04 then return nil end
    return (GetGameplayCamRot(2).z - math.deg(math.atan(x, -y))) % 360.0
end

--[[ Como se lleva el caballo. Antes se le mandaba «ve hacia alli» cada vez
     que cambiaba el rumbo, y el juego frena al caballo al cambiarle el
     destino: al galope bajaba de 16 a 2-5 m/s en cada giro. Ahora lleva UNA
     orden, ir hacia un punto guia que va siempre 25 m delante de su cabeza
     (corre recto), y el giro se lo damos nosotros rotandolo poco a poco. Asi
     mantiene el galope en las curvas. La guia es un objeto local e invisible. ]]
local TAREA_GUIA = `SCRIPT_TASK_GO_STRAIGHT_TO_COORD_RELATIVE_TO_ENTITY`
local guia = nil

local function PonerGuia(ent, rumbo)
    if not guia or not DoesEntityExist(guia) then
        local m = lib.requestModel(`prop_golf_ball`, 5000)
        local p = GetEntityCoords(ent)
        guia = CreateObject(m, p.x, p.y, p.z, false, false, false)
        SetModelAsNoLongerNeeded(m)
        SetEntityVisible(guia, false, false)
        SetEntityCollision(guia, false, false)
        FreezeEntityPosition(guia, true)
    end
    local p = GetEntityCoords(ent)
    local r = math.rad(rumbo)
    SetEntityCoordsNoOffset(guia, p.x - math.sin(r) * 25.0, p.y + math.cos(r) * 25.0, p.z, false, false, false)
    return guia
end

local function QuitarGuia()
    if guia and DoesEntityExist(guia) then DeleteEntity(guia) end
    guia = nil
end

local function Cabalgar(ent)
    local ultimoPaso = nil
    local antes = GetGameTimer()
    local parado = true
    local ayudaHasta = GetGameTimer() + 7000
    Texto('F', 'Desmontar')
    while montado == ent do
        local ped = cache.ped
        if not DoesEntityExist(ent) or IsEntityDead(ent) or IsEntityDead(ped) or LocalPlayer.state.dead
            or (IsEntityInWater(ent) and GetEntitySubmergedLevel(ent) > 0.7) then
            Desmontar()
            break
        end

        -- Subido no se pega, no se salta, no se cubre y no se entra en coches.
        -- Disparar, solo con un arma de una mano en la mano.
        local armado = ArmaDeMontar(ped)
        DisableControlAction(0, 21, true)  DisableControlAction(0, 22, true)
        DisableControlAction(0, 23, true)  DisableControlAction(0, 36, true)
        DisableControlAction(0, 37, true)  DisableControlAction(0, 44, true)
        DisableControlAction(0, 140, true) DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        -- El apuntado y el tiro del juego, nunca: lo hacemos nosotros sentados.
        DisableControlAction(0, 24, true) DisableControlAction(0, 25, true) DisableControlAction(0, 257, true)
        if not armado then
            -- Un arma de dos manos no se saca a caballo.
            if GetSelectedPedWeapon(ped) ~= `WEAPON_UNARMED` then
                SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                Aviso('A caballo solo se usan armas de una mano.', 'error')
            end
        end

        if IsDisabledControlJustPressed(0, 23) then
            Desmontar()
            break
        end

        if ayudaHasta and GetGameTimer() > ayudaHasta then
            ayudaHasta = nil
            Texto()
        end

        -- Clic derecho apunta; con el, el izquierdo dispara.
        local D = Config.Caballos.Disparo
        local clip = nil
        if armado and IsDisabledControlPressed(0, 25) then
            local mira = GetGameplayCamRot(2).x
            clip = mira < D.bajo and 'sweep_low' or mira > D.alto and 'sweep_high' or 'sweep_med'
        end
        if clip ~= apuntando or (clip and not IsEntityPlayingAnim(ped, D.dict, clip, 3)) then Apuntar(ped, clip) end

        local recto = GetEntitySpeed(ent) <= Config.Caballos.VelocidadGalope
        local p = Config.Caballos.Postura
        if clip then
            SetEntityAnimSpeed(ped, D.dict, clip, 0.0)
            SetEntityAnimCurrentTime(ped, D.dict, clip, FaseDeCamara(ent))
            ShowHudComponentThisFrame(14)
            Disparar(ped, ent)
            if not IsEntityPlayingAnim(ped, p.piernas.dict, p.piernas.anim, 3) then
                TaskPlayAnim(ped, p.piernas.dict, p.piernas.anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)
            end
        elseif recto ~= erguido or not IsEntityPlayingAnim(ped, p.piernas.dict, p.piernas.anim, 3)
            or (recto and not IsEntityPlayingAnim(ped, p.tronco.dict, p.tronco.anim, 3)) then
            Postura(ped, recto)
        end

        local ahora = GetGameTimer()
        local dt = math.min(0.1, (ahora - antes) / 1000.0)
        antes = ahora
        if Control(ent) then
            local rumbo = Rumbo()
            if rumbo then
                local C = Config.Caballos
                local paso = IsDisabledControlPressed(0, 21) and C.Galope
                    or IsDisabledControlPressed(0, 36) and C.Paso or C.Trote
                local vel = paso == C.Galope and C.Giro.galope or paso == C.Paso and C.Giro.paso or C.Giro.trote
                local h = GetEntityHeading(ent)
                local falta = (rumbo - h + 540.0) % 360.0 - 180.0
                local gira = math.max(-vel * dt, math.min(vel * dt, falta))
                if math.abs(gira) > 0.01 then
                    h = (h + gira) % 360.0
                    SetEntityHeading(ent, h)
                end
                local g = PonerGuia(ent, h)
                if parado or paso ~= ultimoPaso or GetScriptTaskStatus(ent, TAREA_GUIA) == 7 then
                    TaskGoStraightToCoordRelativeToEntity(ent, g, 0.0, 0.0, 0.0, paso, -1)
                    ultimoPaso, parado = paso, false
                end
            elseif not parado then
                ClearPedTasks(ent)
                TaskStandStill(ent, -1)
                parado, ultimoPaso = true, nil
            end
        end
        Wait(0)
    end
    QuitarGuia()
end

local function Montar(ent)
    if montado or not DatosDe(ent) then return end
    local ok, motivo = lib.callback.await('origen_pets:caballos:sv:montar', false, NetworkGetNetworkIdFromEntity(ent))
    if not ok then
        if motivo then Aviso(motivo, 'error') end
        return
    end
    if not Control(ent) then
        TriggerServerEvent('origen_pets:caballos:sv:desmontar', NetworkGetNetworkIdFromEntity(ent))
        return Aviso('El caballo no se deja. Prueba otra vez.', 'error')
    end
    Amansar(ent)
    SetEntityNoCollisionEntity(ent, cache.ped, false)
    SetEntityNoCollisionEntity(cache.ped, ent, false)
    ClearPedTasks(ent)
    TaskStandStill(ent, -1)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    montado = ent
    LocalPlayer.state:set('montado', true, true)
    Sentar(ent)
    TriggerEvent('origen_pets:caballos:cl:montado', ent)
    CreateThread(function() Cabalgar(ent) end)
end

exports('MontarCaballo', Montar)
exports('DesmontarCaballo', Desmontar)
exports('CaballoMontado', function() return montado end)

--- Para mascota.lua: el caballo que se lleva montado, o nil.
function CaballoMontado() return montado end

-- Los caballos sueltos: amansarlos (lo hace quien los controla) y ofrecer la tecla.
CreateThread(function()
    local pintado = false
    while true do
        local espera = 1000
        for _, ped in ipairs(GetGamePool('CPed')) do
            if not preparados[ped] and not IsPedAPlayer(ped) and NetworkGetEntityIsNetworked(ped)
                and Entity(ped).state.caballo and NetworkHasControlOfEntity(ped) then
                preparados[ped] = true
                Amansar(ped)
                if not Entity(ped).state.jinete then TaskStandStill(ped, -1) end
            end
        end
        local cerca = not montado and not IsPedInAnyVehicle(cache.ped, false)
            and not IsEntityDead(cache.ped) and CaballoCerca() or nil
        if cerca and not Entity(cerca).state.jinete then
            espera = 0
            if not pintado then
                pintado = true
                Texto('E', 'Montar')
            end
            if IsControlJustPressed(0, 38) then
                pintado = false
                Texto()
                Montar(cerca)
            end
        elseif pintado then
            pintado = false
            if not montado then Texto() end
        end
        Wait(espera)
    end
end)

--[[ Las manos y las riendas de los jinetes que hay cerca. Lo hace cada
     cliente por su cuenta, tambien para los demas: nada de esto viaja por red.

     LAS MANOS van atadas al caballo con IK. Su sitio de reposo es un punto
     delante del jinete; en marcha se van una parte (`Config.Caballos.Brazos.sigue`)
     detras del cuello del caballo, asi los brazos se doblan y se estiran con
     cada zancada en vez de ir tiesos.

     LAS RIENDAS son una tira fina de cada mano a la boca, DIBUJADA cada
     fotograma. Las cuerdas del juego llevan fisica: colgaban y al galope se
     quedaban atras. ]]
local riendas = {}   -- [caballo] = { jinete = ped, cuello = {izq, der}, largo = {izq, der} }

--- Los ejes de un hueso en el mundo, y un punto del mundo visto desde el.
local function Ejes(ent, hueso)
    local o = GetPedBoneCoords(ent, hueso, 0.0, 0.0, 0.0)
    return o, GetPedBoneCoords(ent, hueso, 1.0, 0.0, 0.0) - o,
        GetPedBoneCoords(ent, hueso, 0.0, 1.0, 0.0) - o, GetPedBoneCoords(ent, hueso, 0.0, 0.0, 1.0) - o
end

local function VistoDesde(p, o, x, y, z)
    local d = p - o
    return vector3(dot(d, x), dot(d, y), dot(d, z))
end

--- La boca. El eje X del hueso de la cabeza va a lo largo del morro y el Y
--- mira a la izquierda del caballo.
local function Boca(ent, b, lado)
    return GetPedBoneCoords(ent, 31086, b.morro, b.ancho * lado, b.abajo)
end

--- Una tira de `a` a `b`, de cara a la camara. `largo` es lo que mide la
--- rienda: si las puntas estan mas cerca, cuelga lo que le sobra.
local function Tira(a, b, cam, largo)
    local d = Config.Caballos.Riendas
    local c = d.color
    local dist = #(b - a)
    local caida = largo > dist and math.sqrt(0.375 * dist * (largo - dist)) or 0.0
    local antes, ladoAntes
    for i = 0, d.tramos do
        local t = i / d.tramos
        local p = a + (b - a) * t - vector3(0.0, 0.0, caida * 4.0 * t * (1.0 - t))
        if antes then
            local lado = norm(cross(p - antes, cam - p)) * (d.grosor * 0.5)
            ladoAntes = ladoAntes or lado
            local a1, a2, b1, b2 = antes - ladoAntes, antes + ladoAntes, p - lado, p + lado
            DrawPoly(a1.x, a1.y, a1.z, a2.x, a2.y, a2.z, b1.x, b1.y, b1.z, c[1], c[2], c[3], 255)
            DrawPoly(a2.x, a2.y, a2.z, b2.x, b2.y, b2.z, b1.x, b1.y, b1.z, c[1], c[2], c[3], 255)
            DrawPoly(a2.x, a2.y, a2.z, a1.x, a1.y, a1.z, b1.x, b1.y, b1.z, c[1], c[2], c[3], 255)
            DrawPoly(b2.x, b2.y, b2.z, a2.x, a2.y, a2.z, b1.x, b1.y, b1.z, c[1], c[2], c[3], 255)
            ladoAntes = lado
        end
        antes = p
    end
end

CreateThread(function()
    local repaso = 0
    while true do
        local ahora = GetGameTimer()
        if ahora > repaso then
            repaso = ahora + 1000
            local yo = GetEntityCoords(cache.ped)
            local vistos = {}
            for _, ped in ipairs(GetGamePool('CPed')) do
                if EsCaballo(ped) then
                    local quien = Entity(ped).state.jinete
                    local jug = quien and GetPlayerFromServerId(quien) or -1
                    local jinete = jug ~= -1 and GetPlayerPed(jug) or 0
                    if jinete ~= 0 and IsEntityAttachedToEntity(jinete, ped) and #(GetEntityCoords(ped) - yo) < 60.0 then
                        vistos[ped] = true
                        if not riendas[ped] or riendas[ped].jinete ~= jinete then riendas[ped] = { jinete = jinete, cuello = {}, largo = {} } end
                    end
                end
            end
            for ent in pairs(riendas) do
                if not vistos[ent] then riendas[ent] = nil end
            end
        end
        if next(riendas) then
            local cam = GetFinalRenderedCamCoord()
            local B = Config.Caballos.Brazos
            for ent, r in pairs(riendas) do
                local jinete = r.jinete
                if DoesEntityExist(ent) and DoesEntityExist(jinete) and IsEntityAttachedToEntity(jinete, ent) then
                    local quieto = GetEntitySpeed(ent) < 0.3
                    local armado = GetSelectedPedWeapon(jinete) ~= `WEAPON_UNARMED`
                    local co, cx, cy, cz = Ejes(ent, B.cuello)
                    local po, px, py, pz = Ejes(ent, B.pecho)
                    local b = (DatosDe(ent) or {}).boca
                    for i = 1, 2 do
                      -- i 1 es la mano izquierda: con un arma en la derecha,
                      -- esa no va a las riendas.
                      if not (armado and i == 2) then
                        local lado = i == 1 and -1.0 or 1.0
                        local reposo = GetOffsetFromEntityInWorldCoords(jinete, lado * B.ancho, B.delante, B.alto)
                        -- El reposo visto desde el cuello se apunta con el
                        -- caballo quieto; en marcha ese punto se va con el.
                        if not r.cuello[i] and quieto then r.cuello[i] = VistoDesde(reposo, co, cx, cy, cz) end
                        local mano = reposo
                        local c = r.cuello[i]
                        if c then
                            local conCuello = co + cx * c.x + cy * c.y + cz * c.z
                            mano = reposo + (conCuello - reposo) * B.sigue
                        end
                        local l = VistoDesde(mano, po, px, py, pz)
                        SetIkTarget(jinete, i == 1 and 3 or 4, ent, B.pecho, l.x, l.y, l.z, 0, 150, 150)
                        if b then
                            local boca = Boca(ent, b, -lado)
                            -- El largo se toma con el caballo quieto, que es
                            -- como se cogen: un pelo mas que de la mano a la boca.
                            if not r.largo[i] and quieto then r.largo[i] = #(boca - mano) * Config.Caballos.Riendas.holgura end
                            Tira(mano, boca, cam, r.largo[i] or #(boca - mano) * Config.Caballos.Riendas.holgura)
                        end
                      end
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    if montado then Desmontar() end
end)
