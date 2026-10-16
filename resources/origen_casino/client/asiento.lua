--[[ ══════════════════════════════════════════════════════════════════════════
     SENTARSE

     El servidor dice «te has sentado en la plaza 2 de la mesa 14» y manda dónde
     está esa plaza. Aquí se lleva al personaje, se le pone la animación y se
     mueve la cámara. Nada de esto decide nada: si el servidor no lo hubiera
     aceptado, este evento no llegaría.

     ── La cámara ───────────────────────────────────────────────────────────

     Se pone detrás y por encima del hombro, mirando al centro de la mesa. Es
     lo justo para que la pantalla no tape la cara del de al lado y para que se
     vea que hay gente sentada. No se mueve sola: una cámara que se pasea
     mientras tú lees una carta marea.
   ══════════════════════════════════════════════════════════════════════════ ]]

local camara = nil
local sentado = false

-- ── La cámara ─────────────────────────────────────────────────────────────

--[[ La cámara se coloca DETRÁS del jugador, mirando a lo que tiene delante.

     Las tres medidas —cuánto se echa atrás, a qué altura va y a qué altura
     mira— salen del catálogo, y el que no las trae las saca del propio
     modelo: un mueble de dos metros y medio como una tragaperras no se mira
     desde donde se mira una mesa de un metro veinte.

     Con el valor fijo que había —1,15 m detrás y 1,25 de alto para todo— la
     tragaperras salía con el respaldo del taburete llenando media pantalla. ]]
local function PonerCamara(asiento, punto, tipo)
    if camara then return end

    local alturaModelo = 1.2
    if tipo and tipo.modelo then
        local hash = joaat(tipo.modelo)
        if HasModelLoaded(hash) then
            local _, arriba = GetModelDimensions(hash)
            if arriba and arriba.z > 0.2 then alturaModelo = arriba.z end
        end
    end

    local cfg = (tipo and tipo.camara) or {}
    --[[ Por defecto: un poco más atrás cuanto más alto sea el mueble, la
         cámara medio metro por encima de él y mirando a su parte alta, que es
         donde pasan las cosas —el tapete, los rodillos—. ]]
    local atras = cfg.atras or (1.35 + alturaModelo * 0.45)
    local alto = cfg.alto or (alturaModelo * 0.55 + 0.85)
    local mira = cfg.mira or (alturaModelo * 0.88)

    --[[ Detrás del asiento: en GTA un rumbo `h` mira hacia (-sin h, cos h),
         así que «detrás» es justo lo contrario. ]]
    local rad = math.rad(asiento.h)
    local x = asiento.x + math.sin(rad) * atras
    local y = asiento.y - math.cos(rad) * atras

    --[[ `lado` la corre a la derecha del jugador: por encima del hombro. En la
         tragaperras hace falta, porque desde justo detrás la cabeza tapa los
         rodillos. La derecha de un rumbo h es (cos h, sin h). ]]
    local lado = cfg.lado or 0.0
    x = x + math.cos(rad) * lado
    y = y + math.sin(rad) * lado

    camara = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', x, y, asiento.z + alto,
        0.0, 0.0, 0.0, (cfg.campo or 48.0) + 0.0, false, 0)  -- + 0.0: un entero llega al native como un campo de visión casi cero
    --[[ A dónde mira: al centro del mueble, o —con `adelante`— a un punto
         delante de la silla. En las mesas es lo que hace falta: tus cartas y
         el crupier, no el centro del tapete, que cae de lado en las plazas
         de las puntas. El frente de un rumbo h es (-sin h, cos h). ]]
    local mx, my = punto.x, punto.y
    if cfg.adelante then
        mx = asiento.x - math.sin(rad) * cfg.adelante
        my = asiento.y + math.cos(rad) * cfg.adelante
    end
    PointCamAtCoord(camara, mx, my, punto.z + mira)
    SetCamActive(camara, true)
    RenderScriptCams(true, true, 800, true, false)
end

local function QuitarCamara()
    if not camara then return end
    RenderScriptCams(false, true, 600, true, false)
    DestroyCam(camara, false)
    camara = nil
end

-- ── Sentarse ──────────────────────────────────────────────────────────────

local escena = nil

local function CargarDict(dict)
    if not DoesAnimDictExist(dict) then return false end
    RequestAnimDict(dict)
    local t = GetGameTimer()
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() - t > 3000 then return false end
        Wait(0)
    end
    return true
end

--[[ Una escena sincronizada: es como sienta el propio casino de GTA —y como
     lo hacen los scripts de casino que se ven bien—. La animación ya sabe
     dónde está el taburete respecto a su ORIGEN, así que el personaje cae
     encima sin calcular nada. Lo único es poner el origen donde lo espera:

     · Mesas: en el hueso `Chair_Base` de la silla, con el giro del hueso, que
       va 90° por delante de hacia donde mira el jugador.
     · Tragaperras: en el centro de la MÁQUINA y con su rumbo. Con el origen
       en la silla, como en las mesas, el personaje acababa de lado y un metro
       fuera del taburete (visto en el juego el 24/09). ]]
local function Origen(asiento, punto, tipo, sentar)
    if sentar.origen == 'mueble' then
        local z = punto.z
        local hash = tipo.modelo and joaat(tipo.modelo)
        if hash and HasModelLoaded(hash) then
            -- El mueble se levanta lo que baja su caja (client/puntos.lua).
            local abajo = GetModelDimensions(hash)
            z = punto.z - abajo.z
        end
        return punto.x, punto.y, z, punto.h
    end
    return asiento.x, asiento.y, asiento.z, (asiento.h + 90.0) % 360.0
end

local function Escena(ped, origen, dict, anim, bucle)
    local nueva = NetworkCreateSynchronisedScene(origen[1], origen[2], origen[3],
        0.0, 0.0, origen[4], 2, not bucle, bucle, 1.0, 0.0, 1.0)
    NetworkAddPedToSynchronisedScene(ped, nueva, dict, anim, 2.0, -2.0, 13, 16, 2.0, 0)
    NetworkStartSynchronisedScene(nueva)
    escena = nueva
    return nueva
end

local function DictDe(ped, sentar)
    if sentar.dictMujer and not IsPedMale(ped) then return sentar.dictMujer end
    return sentar.dict
end

--- Plan B, para lo que no trae animación propia (la butaca de los caballos):
--- un escenario de silla en el sitio, sin colisión para que el mueble que
--- haya debajo no lo empuje y congelado DESPUÉS de mandar la tarea —congelar
--- antes deja al personaje de pie como un poste—.
local function SentarGenerico(ped, asiento, tipo)
    SetEntityCollision(ped, false, false)
    SetEntityCoordsNoOffset(ped, asiento.x, asiento.y, asiento.z + 1.0, false, false, false)
    SetEntityHeading(ped, asiento.h)
    TaskStartScenarioInPlace(ped, (tipo and tipo.escenarioAsiento)
        or 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER', 0, true)
    CreateThread(function()
        Wait(600)
        if sentado then FreezeEntityPosition(ped, true) end
    end)
end

local actual = nil       -- con qué está sentado: origen, diccionario, animaciones

--- Espera a que acabe la escena `mia` y vuelve al bucle de estar sentado.
--- Si mientras tanto empieza otra escena, o se levanta, no toca nada.
function Esperar(mia, dict, anim)
    CreateThread(function()
        local dura = math.floor(GetAnimDuration(dict, anim) * 1000)
        local t = GetGameTimer()
        while sentado and escena == mia and GetGameTimer() - t < dura do
            local enLocal = NetworkGetLocalSceneFromNetworkId(mia)
            if enLocal ~= -1 and GetSynchronizedScenePhase(enLocal) >= 0.99 then break end
            Wait(50)
        end
        local a = actual
        if sentado and escena == mia and a then
            Escena(a.ped, a.origen, a.dict, a.sentar.quieto, true)
        end
    end)
end

local function Sentar(datos)
    local ped = cache.ped
    local asiento = datos.asiento
    local tipo = Catalogo.Tipo(datos.tipo)
    local punto = C.puntos[datos.punto]
    if not punto then return end

    sentado = true
    actual = nil
    C.sesion = datos
    -- Jugando no se ve el minimapa: tapa la mesa y no pinta nada aquí.
    pcall(function() exports.origen_map:Apartar(true) end)
    if not asiento then return end

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)

    local sentar = tipo and tipo.sentar
    local dict = sentar and DictDe(ped, sentar)
    if not (dict and CargarDict(dict)) then
        Casino.Traza('sin animación de casino: se sienta con un escenario')
        SentarGenerico(ped, asiento, tipo)
        PonerCamara(asiento, punto, tipo)
        return
    end

    --[[ De pie junto al taburete, que es donde empieza la animación de
         entrada; si se la pone desde donde estaba, se ve un salto. ]]
    local rad = math.rad(asiento.h)
    SetEntityCoordsNoOffset(ped, asiento.x - math.cos(rad) * 0.6, asiento.y - math.sin(rad) * 0.6,
        asiento.z + 1.0, false, false, false)
    SetEntityHeading(ped, asiento.h)

    local origen = { Origen(asiento, punto, tipo, sentar) }
    Escena(ped, origen, dict, sentar.entrada, false)
    PonerCamara(asiento, punto, tipo)

    actual = { ped = ped, origen = origen, dict = dict, sentar = sentar }
    Esperar(escena, dict, sentar.entrada)
end

--[[ ── Los gestos ──────────────────────────────────────────────────────────

     Mientras juega, el personaje hace lo que se hace en el casino de GTA:
     pulsa el botón o tira de la palanca de la tragaperras, celebra si gana,
     se lamenta si pierde. Cada gesto es una escena suelta en el mismo origen
     que el bucle, y al acabar se vuelve al bucle. Si llega otro gesto a medias,
     el nuevo manda. ]]
function Gesto(nombre, fija)
    local a = actual
    if not sentado or not a then return end
    -- `fija`: una animación concreta del gesto (la palanca tiene que ser la
    -- misma que la que hace la máquina).
    local anim = fija or (a.sentar.gestos and a.sentar.gestos[nombre])
    if type(anim) == 'table' then anim = anim[math.random(#anim)] end
    if not anim or GetAnimDuration(a.dict, anim) <= 0.0 then return end
    Escena(a.ped, a.origen, a.dict, anim, false)
    Esperar(escena, a.dict, anim)
    return anim
end

local function Levantar()
    local ped = cache.ped
    local tipo = C.sesion and Catalogo.Tipo(C.sesion.tipo)
    local asiento = C.sesion and C.sesion.asiento
    local punto = C.sesion and C.puntos[C.sesion.punto]
    local sentar = tipo and tipo.sentar
    sentado = false
    actual = nil
    C.sesion = nil
    pcall(function() exports.origen_map:Apartar(false) end)
    QuitarCamara()
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)

    local dict = sentar and asiento and punto and DictDe(ped, sentar)
    if dict and HasAnimDictLoaded(dict) and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped, false) then
        --[[ Levantarse con su animación y soltar al terminar. `escena` cambia
             si se vuelve a sentar entretanto: entonces no se toca nada. ]]
        local mia = Escena(ped, { Origen(asiento, punto, tipo, sentar) }, dict, sentar.salida, false)
        CreateThread(function()
            Wait(math.floor(GetAnimDuration(dict, sentar.salida) * 1000))
            if escena == mia and not sentado then
                NetworkStopSynchronisedScene(mia)
                escena = nil
                ClearPedTasks(ped)
            end
        end)
        return
    end

    if escena then NetworkStopSynchronisedScene(escena) escena = nil end
    ClearPedTasks(ped)
end

RegisterNetEvent('origen_casino:sentado', function(datos)
    if type(datos) ~= 'table' then return end
    Sentar(datos)
    AbrirJuego(datos)
end)

RegisterNetEvent('origen_casino:levantado', function(motivo)
    if not sentado and not C.sesion then return end
    Levantar()
    CerrarJuego()
    if motivo and motivo ~= 'se levantó' and type(motivo) == 'string' then
        C.Aviso(Config.General.nombre, motivo, 'inform')
    end
end)

--- Levantarse por voluntad propia. Lo llama la pantalla al cerrarse.
function Levantarse()
    if not C.sesion then return end
    lib.callback.await('origen_casino:levantarse', false)
    Levantar()
end

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    --[[ De golpe: con el recurso parado no queda hilo que termine la
         animación de levantarse, y la escena en bucle seguiría para siempre. ]]
    if escena then NetworkStopSynchronisedScene(escena) escena = nil end
    if sentado or camara then
        QuitarCamara()
        FreezeEntityPosition(cache.ped, false)
        SetEntityCollision(cache.ped, true, true)
        ClearPedTasksImmediately(cache.ped)
    end
end)

--[[ Si el personaje muere, se esposa o lo meten en un coche mientras está
     sentado, la mesa se queda con él dentro y el juego con la pantalla puesta.
     Esto lo corta. ]]
CreateThread(function()
    while true do
        Wait(1000)
        if sentado then
            local ped = cache.ped
            if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) or IsPedCuffed(ped) then
                Levantarse()
                CerrarJuego()
            end
        end
    end
end)
