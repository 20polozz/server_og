--[[ Estado del telefono en el cliente: abrirlo, cerrarlo, animarlo.

     El telefono se abre "andando": el raton controla la pantalla pero las
     teclas de movimiento siguen llegando al juego. Eso se consigue con
     SetNuiFocus(true, true) mas SetNuiFocusKeepInput(true), y luego apagando a
     mano los controles que estorban (disparar, apuntar, entrar en vehiculos).
]]

Phone = {}

Phone.open = false
Phone.booted = false

--[[ Enganchado a la red.

     No es lo mismo que `booted`: eso quiere decir que la interfaz tiene sus
     datos y solo pasa al abrirlo. Esto quiere decir que el servidor sabe que
     numero llevas, que es lo unico que hace falta para que te entre algo. ]]
Phone.awake = false
Phone.number = nil

--- Copia de los ajustes del telefono. La guarda el cliente porque hay cosas
--- (el volumen del tono, si suena o no) que hacen falta sin que la interfaz
--- este abierta para preguntarlas.
Phone.settings = nil

local prop = nil
local animDict = 'cellphone@'
local propModel = Config.Animation.Prop

--[[ Controles que se apagan con el telefono en la mano.

     Moverse, correr, saltar y mirar siguen funcionando: la gracia es poder
     andar mientras lo usas. Se apaga tambien la tecla de pausa, porque si no
     Escape abre el menu del juego en vez de cerrar el telefono. ]]
local BLOCKED_CONTROLS = {
    199, -- pausa (P)
    200, -- pausa (Esc)
    322, -- Esc
    24,  -- atacar
    25,  -- apuntar
    47,  -- arma
    58,  -- arma
    263, -- cuerpo a cuerpo
    264,
    257,
    140, 141, 142,
    143,
    75,  -- salir del vehiculo
    23,  -- entrar en vehiculo
    37,  -- rueda de armas
    44,  -- cubrirse

    --[[ La vista.

         Con SetNuiFocusKeepInput(true) el juego sigue leyendo el raton, asi que
         mover el cursor por el telefono giraba tambien la camara. Andar si se
         deja (WASD sigue vivo, que en rol se agradece), pero mirar no: el raton
         es del telefono mientras esta abierto. ]]
    1,   -- mirar a los lados
    2,   -- mirar arriba y abajo
    3,   -- los mismos ejes, en la otra asignacion
    4,
    5,
    6,
    106, -- el raton dentro de un vehiculo

    --[[ La radio del coche.

         Dentro de un vehiculo, la rueda del raton es el mando de la emisora:
         al hacer scroll en una lista del telefono se cambiaba de emisora sin
         querer. No hace falta apagar la radio —quien estuviera escuchando algo
         se quedaria sin musica por abrir el movil—; basta con que el mando no
         escuche mientras el telefono esta en la mano. ]]
    81,  -- emisora siguiente
    82,  -- emisora anterior
    83,  -- pista siguiente
    84,  -- pista anterior
    85,  -- la rueda de la radio
}

-- ---------------------------------------------------------------------------
--  Animacion y prop
-- ---------------------------------------------------------------------------

local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 2000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    return HasAnimDictLoaded(dict)
end

local function CreatePhoneProp()
    if not Config.Animation.Enabled or prop then return end

    RequestModel(propModel)
    local timeout = GetGameTimer() + 2000
    while not HasModelLoaded(propModel) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(propModel) then return end

    --[[ Se vuelve a mirar despues de esperar al modelo.

         La espera cede el hilo hasta dos segundos (la primera vez de la
         sesion el modelo no esta cargado). En ese rato puede pasar de todo:
         que se cierre el telefono con Escape —y entonces este objeto se
         quedaba pegado a la mano con el telefono guardado, porque el cierre ya
         habia pasado por DestroyPhoneProp cuando aun no existia— o que otra
         apertura haya creado el suyo, y salian dos, uno de ellos huerfano. ]]
    if prop or not Phone.open then
        SetModelAsNoLongerNeeded(propModel)
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    prop = CreateObject(propModel, coords.x, coords.y, coords.z, true, true, false)

    local offset = Config.Animation.PropOffset
    local rotation = Config.Animation.PropRotation
    AttachEntityToEntity(
        prop, ped, GetPedBoneIndex(ped, Config.Animation.PropBone),
        offset.x, offset.y, offset.z,
        rotation.x, rotation.y, rotation.z,
        true, true, false, true, 1, true
    )
    SetModelAsNoLongerNeeded(propModel)
end

local function DestroyPhoneProp()
    if not prop then return end
    if DoesEntityExist(prop) then DeleteEntity(prop) end
    prop = nil
end

--[[ La postura con la que se sostiene el telefono.

     Son tres, y la diferencia se ve desde fuera: leyendo se sujeta a la altura
     del pecho, hablando se lleva a la oreja, y haciendo una foto se estira el
     brazo. Esa ultima importa mas de lo que parece: con la de leer, el aparato
     se queda plantado delante de la cara, o sea justo en medio del encuadre de
     la camara. Salia el telefono dentro del telefono.

     En coche no hay version de la de foto, asi que ahi se queda la de leer. ]]
--[[ Cada postura vive en su propio diccionario.

     Las de leer y hablar estan en 'cellphone@'. La de hacer una foto NO: esta
     en 'cellphone@self', que es el que trae selfie_in / selfie / selfie_out.
     Aqui se habia usado 'cellphone_photo_idle' del diccionario de siempre y la
     mano salia abierta, sin agarrar nada, porque esa animacion no es la de
     sostener el telefono para fotografiar. Es el mismo juego de animaciones que
     usan los demas telefonos del mercado. ]]
local POSES = {
    read  = { dict = 'cellphone@',      anim = 'cellphone_text_read_base' },
    call  = { dict = 'cellphone@',      anim = 'cellphone_call_listen_base' },

    --[[ 'selfie', no 'selfie_in'.

         En ese diccionario hay tres clips y hacen cosas distintas: selfie_in es
         *sacar* el telefono, selfie es *sostenerlo* con el brazo estirado, y
         selfie_out es guardarlo. Aqui estaba puesto selfie_in, que al repetirse
         en bucle sacaba el movil del bolsillo una y otra vez sin llegar nunca a
         quedarse quieto.

         La mezcla va mas rapida que en las otras (8 en vez de 3) porque el
         brazo tiene que estar arriba antes de que el jugador encuadre, no
         subiendo poco a poco mientras ya esta mirando por el visor. ]]
    photo = { dict = 'cellphone@self', anim = 'selfie', mezcla = 8.0 },
}

--- Sentado se sostiene igual: la de selfie vale para las dos, y las otras dos
--- tienen su version propia dentro del coche.
local POSES_COCHE = {
    read  = { dict = 'anim@cellphone@in_car@ps', anim = 'cellphone_text_read_base' },
    call  = { dict = 'anim@cellphone@in_car@ps', anim = 'cellphone_call_listen_base' },
    photo = { dict = 'cellphone@self',           anim = 'selfie', mezcla = 8.0 },
}

--- Cual esta puesta ahora mismo, para poder volver a ella.
local pose = 'read'
--- Y el clip de esa postura, para mirar si se sigue reproduciendo.
local poseActual = nil

---@param kind string  'read' | 'call' | 'photo'
function Phone.SetPose(kind)
    if not Config.Animation.Enabled then return end

    local ped = PlayerPedId()
    local elegida = IsPedInAnyVehicle(ped, false) and POSES_COCHE[kind] or POSES[kind]
    if not elegida then return end

    pose = kind
    poseActual = elegida

    if not LoadAnimDict(elegida.dict) then return end

    --[[ Sin gestos ni animaciones de ambiente mientras se sostiene el telefono.
         Las personajes femeninas hacen gestos sueltos de pie (tocarse el pelo,
         cambiar el peso de pierna) y el juego los pone ENCIMA de la parte de
         arriba del cuerpo: el brazo subia con el movil y al segundo bajaba.
         Se devuelven al soltarlo (Phone.StopAnimation). ]]
    SetPedCanPlayAmbientAnims(ped, false)
    SetPedCanPlayAmbientBaseAnims(ped, false)
    SetPedCanPlayGestureAnims(ped, false)

    --[[ La marca 49 es 1 + 16 + 32: en bucle, solo de cintura para arriba y sin
         quitarle el control al jugador. Es lo que deja que siga andando con las
         piernas mientras el torso sostiene el telefono. ]]
    local mezcla = elegida.mezcla or 3.0

    TaskPlayAnim(ped, elegida.dict, elegida.anim, mezcla, -mezcla, -1, 49, 0, false, false, false)
    SetPedConfigFlag(ped, 243, true)
end

--- La postura puesta ahora mismo.
---@return string
function Phone.GetPose()
    return pose
end

--- El objeto del telefono que lleva en la mano, si lo hay.
--- La camara lo necesita para poder esconderlo de su propia lente.
---@return number|nil
function Phone.GetProp()
    return prop
end

--- Pone la animacion que toca segun donde este el jugador y si esta llamando.
---@param calling boolean
function Phone.PlayAnimation(calling)
    Phone.SetPose(calling and 'call' or 'read')
end

function Phone.StopAnimation()
    local ped = PlayerPedId()

    -- Se sueltan todas, no solo la de leer: si se sale del telefono con la
    -- camara abierta, la de la foto se quedaba puesta y el personaje seguia
    -- con el brazo estirado por la calle.
    for _, tabla in ipairs({ POSES, POSES_COCHE }) do
        for _, p in pairs(tabla) do
            StopAnimTask(ped, p.dict, p.anim, 1.0)
        end
    end

    ClearPedSecondaryTask(ped)
    poseActual = nil

    SetPedCanPlayAmbientAnims(ped, true)
    SetPedCanPlayAmbientBaseAnims(ped, true)
    SetPedCanPlayGestureAnims(ped, true)
end

--[[ Guardar el aparato: fuera el objeto de la mano y fuera la postura.

     Lo necesita el fin de una llamada con el telefono cerrado. Al cerrar el
     telefono en mitad de una llamada el objeto se deja en la mano a proposito
     (ver Phone.Close), y cuando el otro colgaba solo se paraba la animacion:
     el movil se quedaba flotando en la mano hasta volver a abrir y cerrar. ]]
function Phone.SoltarDeLaMano()
    DestroyPhoneProp()
    Phone.StopAnimation()
end

--[[ Si algo corta la postura con el telefono en la mano, se vuelve a poner.
     Pasaba con las personajes femeninas: el brazo subia y al segundo bajaba,
     y ya no volvia hasta cerrar y abrir. Ademas de quitarles los gestos (ver
     SetPose), aqui se repasa cada medio segundo por si lo corta otra cosa
     —otro recurso, un golpe—. No se toca mientras cae, esta muerta o entra o
     se sube a un coche: ahi el juego manda y la postura se pone al acabar.
     Bajarse no hace falta mirarlo: con el telefono abierto la tecla de salir
     esta apagada (BLOCKED_CONTROLS). ]]
local function VigilarPostura(ped)
    if not poseActual or not Config.Animation.Enabled then return end
    if IsEntityDead(ped) or IsPedRagdoll(ped) or IsPedGettingIntoAVehicle(ped) then
        return
    end
    -- Dentro o fuera del coche la postura es otra: la pide de nuevo SetPose.
    local tocaCoche = IsPedInAnyVehicle(ped, false)
    local esperada = tocaCoche and POSES_COCHE[pose] or POSES[pose]
    if esperada ~= poseActual or not IsEntityPlayingAnim(ped, poseActual.dict, poseActual.anim, 3) then
        Phone.SetPose(pose)
    end
end

-- ---------------------------------------------------------------------------
--  Abrir y cerrar
-- ---------------------------------------------------------------------------

--[[ Esposado, por cualquiera de los dos sistemas del servidor.

     IsPedCuffed solo es verdad con SetEnableHandcuffs, que es lo que usan
     las bandas (origen_ilegalv2). Las esposas de origen_police no lo llaman:
     ponen su animacion y el statebag `isHandcuffed`. Con solo IsPedCuffed
     el telefono se abria esposado por la policia, y con el abierto las dos
     animaciones se pisaban cada medio segundo (la postura del telefono y la
     de las esposas, cada una devolviendo la suya). ]]
---@param ped number
---@return boolean
local function Esposado(ped)
    if IsPedCuffed(ped) then return true end
    if LocalPlayer.state.isHandcuffed or Entity(ped).state.isHandcuffed then return true end
    return IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3) == true
end

--[[ Muerto o ABATIDO (25/09).

     IsEntityDead solo es verdad el par de segundos que dura la caida:
     origen_ambulancejob resucita el ped en el suelo para la pantalla de
     muerte, y a partir de ahi el juego lo da por vivo. Con solo eso el
     telefono se abria tirado en el suelo y se podia llamar. Lo que dice que
     sigues abatido son los statebags de la ambulancia: `dead` (desde el
     golpe hasta que te levantan) y `samsCaido` (desde que quedas tumbado). ]]
---@param ped number|nil
---@return boolean
function Phone.Abatido(ped)
    ped = ped or PlayerPedId()
    if IsEntityDead(ped) then return true end
    local estado = LocalPlayer.state
    return estado.dead == true or estado.samsCaido ~= nil
end

--[[ El telefono no puede seguir en la mano si pasa algo de esto.

     CanOpen ya lo mira al ABRIR, pero nada lo miraba despues:

     - Muerto sin golpe. Al morir se suelta el telefono desde
       'gameEventTriggered', que solo salta con dano. Una muerte por vida a
       cero (un /kill, un script) dejaba el telefono abierto con el cursor
       encima de la pantalla de muerto.
     - Esposado con el telefono ya abierto.
     - Al agua con el telefono abierto: Config.CloseWhenSwimming solo
       impedia abrirlo, y la postura se reponia nadando. ]]
---@param ped number
---@return string|nil  'muerto' | 'guardar' | nil
local function MotivoParaGuardarlo(ped)
    if Config.CloseOnDeath and Phone.Abatido(ped) then
        return 'muerto'
    end
    if Esposado(ped) then return 'guardar' end
    if Config.CloseWhenSwimming and IsPedSwimming(ped) then return 'guardar' end
    return nil
end

--- Hilo que apaga los controles que estorban mientras el telefono esta abierto.
local function StartControlThread()
    CreateThread(function()
        local repaso = 0
        while Phone.open do
            if GetGameTimer() - repaso > 500 then
                repaso = GetGameTimer()
                local ped = PlayerPedId()

                local motivo = MotivoParaGuardarlo(ped)
                if motivo == 'muerto' then
                    Phone.Drop()
                    break
                elseif motivo then
                    Phone.Close()
                    break
                end

                VigilarPostura(ped)
            end

            --[[ Alt devuelve el foco a la pantalla.

                 Alt es la tecla de la camara (apuntar / cursor), y a algunos
                 jugadores, al pulsarla, la pantalla se quedaba sin foco: el
                 cursor en medio y nada respondia (fallo de FiveM con
                 KeepInput). Al soltarla se vuelve a poner TODO el foco tal
                 como diga el estado (ver client/modules/foco.lua). ]]
            if IsRawKeyReleased and (IsRawKeyReleased(18) or IsRawKeyReleased(164)) then
                Foco.Aplicar(true)
            end

            for i = 1, #BLOCKED_CONTROLS do
                DisableControlAction(0, BLOCKED_CONTROLS[i], true)
            end
            -- La rueda del raton pasa a la interfaz, no al arma.
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            Wait(0)
        end
    end)
end

--- Condiciones que impiden usar el telefono ahora mismo.
---@return boolean, string|nil
local function CanOpen()
    local ped = PlayerPedId()

    if Phone.Abatido(ped) then
        return false, 'No estas en condiciones.'
    end
    if Config.CloseWhenSwimming and IsPedSwimming(ped) then
        return false, 'No con las manos en el agua.'
    end
    if not Config.AllowInVehicle and IsPedInAnyVehicle(ped, false) then
        return false, 'Ahora no.'
    end
    if Esposado(ped) then
        return false, 'No puedes con las manos asi.'
    end

    --[[ Sin movil encima no se abre.

         El servidor ya lo impedia —el arranque contesta err_no_phone_on_you—
         pero por el camino le creaba una linea al jugador y la borraba justo
         despues, porque no puede saber que no hay item hasta que intenta
         escribirle el numero. Con la tecla puesta eso pasaba a ser una ida y
         vuelta al servidor y dos consultas a la base CADA VEZ que alguien sin
         movil pulsa F1.

         Aqui se corta antes. La comprobacion de verdad sigue siendo la del
         servidor: esto solo es para no molestarle. Y si no se puede mirar el
         inventario —CarryingPhone devuelve nil— se deja pasar, que es lo que
         hacia antes. ]]
    if Framework.CarryingPhone() == false then
        return false, Locale.Say('err_no_phone_on_you')
    end

    return true
end

--- Arranca el telefono contra el servidor. Solo la primera vez por sesion.
---@param number string|nil
---@return boolean
function Phone.Boot(number)
    local result = lib.callback.await('origen_phone:rpc', false, 'phone:boot', { number = number })

    if not result or not result.ok then
        Framework.Notify(result and result.error or Locale.Say('err_cannot_open'), 'error')
        return false
    end

    if result.data.error then
        Framework.Notify(result.data.error, 'error')
        return false
    end

    Phone.booted = true
    Phone.awake = true
    Phone.number = result.data.number
    Phone.settings = result.data.settings

    --- Lo primero que se sabe de los ajustes: el volumen de llamada a pma-voice.
    if Calls and Calls.AplicarVolumen then Calls.AplicarVolumen() end
    -- El cliente tambien tiene textos propios (avisos fuera del telefono), asi
    -- que se queda con el idioma que trae el arranque.
    Locale.SetMine(result.data.language)

    -- Los ajustes del panel los necesita el cliente, no solo la interfaz:
    -- de ahi salen las zonas de cobertura y los puntos de carga.
    AjustesDelServidor = result.data.server

    Nui.Send('boot', result.data)

    -- Las alarmas se cargan al encender: tienen que sonar aunque no se vuelva
    -- a abrir el telefono.
    if Alarms then Alarms.Set(result.data.alarms) end

    return true
end

--[[ El arranque contra el servidor, en curso.

     Phone.Boot espera al servidor con lib.callback.await, y mientras espera
     `Phone.open` sigue en false. Pulsar F1 otra vez en ese rato (lo normal si
     el servidor tarda: "no se ha abierto, le doy otra vez") lanzaba un segundo
     arranque, y los dos acababan abriendo: dos hilos de controles, dos veces
     el foco y, con el modelo sin cargar, dos objetos en la mano. Y si el
     servidor no contestaba, el await revienta a los cinco minutos con un error
     que se llevaba la apertura por delante sin decir nada.

     Ahora una segunda pulsacion durante el arranque lo CANCELA (es lo que
     quiere decir pulsar la tecla de abrir y cerrar), y `vueltaApertura` hace
     que el arranque cancelado, cuando por fin vuelva, no abra nada. ]]
local abriendo = false
local vueltaApertura = 0

--[[ Todo lo que se hace con el telefono ya marcado como abierto.

     Va aparte para poder envolverlo en un pcall desde Phone.Open: un error a
     mitad (un offset mal puesto en la configuracion, un modelo que no existe)
     dejaba `Phone.open` en true y el foco puesto sin pantalla visible. ]]
local function Montar()
    --[[ El hilo de los controles, ANTES de lo que espera.

         Crear el objeto y cargar la animacion pueden ceder el hilo hasta dos
         segundos cada uno. Con el hilo arrancado despues, en ese rato el foco
         ya estaba puesto pero la pausa no estaba apagada: Escape cerraba el
         telefono y ademas abria el menu del juego. ]]
    StartControlThread()

    CreatePhoneProp()
    Phone.PlayAnimation(Calls.IsActive())

    --[[ Y se mira si sigue abierto despues de las esperas.

         Si se cerro en ese rato (Escape, morir), el cierre ya ha pasado y no
         volvera a pasar: la postura puesta despues se quedaba para siempre y el
         `visible` de abajo pintaba el telefono en pantalla con `Phone.open` en
         false, sin foco y sin Escape que lo quitara. ]]
    if not Phone.open then
        if not Calls.IsActive() then Phone.SoltarDeLaMano() end
        return
    end

    --[[ EL FOCO, JUNTO CON LA PANTALLA Y NO ANTES.

         Se cogia arriba del todo, y entre eso y el `visible` de aqui hay hasta
         cuatro segundos la primera vez (cargar el modelo y la animacion): el
         jugador tenia el cursor en medio de la pantalla sin telefono a la
         vista, y el vigilante lo daba por perdido y lo cerraba solo. ]]
    Foco.telefono = true
    Foco.Aplicar()
    -- Sin SetCursorLocation (27/09): mover el cursor de Windows a mano con el
    -- raton en modo Windows es parte de lo que lo dejaba clavado al cerrar.

    Nui.Send('visible', true)

    --[[ Cerrar el telefono en mitad de una videollamada quita la camara del
         juego (ver Phone.Close), pero la pantalla sigue con la camara puesta y
         nadie la volvia a encender: el otro pasaba a ver la vista del juego en
         vez de la cara. Al volver a abrirlo, se devuelve. ]]
    if Calls and Calls.IsActive() and Calls.camaraPedida and Camera and not Camera.active then
        Calls.SetVideo(true)
    end
end

---@param number string|nil  numero del item que se ha usado
function Phone.Open(number)
    if Phone.open or abriendo then return end

    local allowed, reason = CanOpen()
    if not allowed then
        Framework.Notify(reason, 'error')
        return
    end

    -- Si se usa otro telefono distinto, se reinicia la sesion.
    if number and number ~= Phone.number then
        Phone.booted = false
    end

    if not Phone.booted then
        abriendo = true
        vueltaApertura = vueltaApertura + 1
        local mia = vueltaApertura

        local bien, arrancado = pcall(Phone.Boot, number)

        --- Cancelado mientras esperaba (ver `abriendo`): no se toca nada.
        if vueltaApertura ~= mia then return end
        abriendo = false

        if not bien then
            print(('^1[origen_phone] El arranque ha fallado: %s^7'):format(tostring(arrancado)))
            Framework.Notify(Locale.Say('err_cannot_open'), 'error')
            return
        end
        if not arrancado then return end

        --[[ Lo que valia antes de esperar puede no valer ya: morir o que te
             esposen mientras el servidor contesta abria el telefono igual. ]]
        allowed, reason = CanOpen()
        if not allowed then
            Framework.Notify(reason, 'error')
            return
        end
    end

    Foco.escribiendoHasta = 0
    Phone.open = true

    local bien, fallo = pcall(Montar)
    if not bien then
        print(('^1[origen_phone] Error al abrir el telefono: %s^7'):format(tostring(fallo)))
        Phone.Close()
    end
end

function Phone.Close()
    if not Phone.open then return end

    Phone.open = false

    --[[ La camara se cierra aqui y no esperando al aviso que manda la app al
         desmontarse: ese aviso llega despues de soltar el foco, y si se estaba
         apuntando lo volvia a coger.

         Con pcall: un error ahi dentro cortaba el cierre ANTES de soltar el
         foco, con `Phone.open` ya en false. El raton se quedaba preso y el
         Escape de client/main.lua, que solo mira con el telefono abierto, ya
         no lo atendia. ]]
    if Camera and Camera.active then
        local bien, fallo = pcall(Camera.CloseNow)
        if not bien then
            print(('^1[origen_phone] Error al cerrar la camara: %s^7'):format(tostring(fallo)))
        end
    end

    Foco.telefono = false
    Foco.apuntando = false
    Foco.escribiendoHasta = 0
    Foco.Aplicar()

    -- Con una llamada en curso el telefono sigue "en la mano": la animacion y
    -- el prop se quedan, solo se va la pantalla.
    if not Calls.IsActive() then
        DestroyPhoneProp()
        Phone.StopAnimation()
    end

    Nui.Send('visible', false)
end

function Phone.Toggle(number)
    if Phone.open then
        Phone.Close()
    elseif abriendo then
        --- Segunda pulsacion con el arranque esperando: se cancela.
        abriendo = false
        vueltaApertura = vueltaApertura + 1
    else
        Phone.Open(number)
    end
end

--- Suelta el telefono del todo (al morir, al perder el item, al reiniciar).
function Phone.Drop()
    local dropped = Phone.number

    --[[ La llamada tambien se va con el telefono. El servidor la cierra, pero
         el aviso ya no le llega a este cliente (sin telefono no hay a quien
         mandarselo): sin esto se quedaba el tono sonando, la voz silenciada si
         lo estaba y la animacion de hablar puesta. ]]
    --[[ Con pcall: Drop es lo que se llama al morir, y un error al colgar
         (un export de la voz que falle) cortaba aqui y el telefono se quedaba
         abierto, con el foco puesto, encima de la pantalla de muerto. ]]
    if Calls and Calls.current then
        local bien, fallo = pcall(Calls.OnEnded, {})
        if not bien then
            print(('^1[origen_phone] Error al colgar al soltar el telefono: %s^7'):format(tostring(fallo)))
        end
    end

    --- Un arranque a medias tampoco puede abrirlo despues.
    abriendo = false
    vueltaApertura = vueltaApertura + 1

    Phone.Close()
    Phone.booted = false
    Phone.awake = false
    Phone.number = nil
    DestroyPhoneProp()
    Phone.StopAnimation()

    -- Se avisa al servidor para que deje de considerarte el dueno de ese
    -- numero. El servidor tambien lo comprueba por su cuenta, pero avisar
    -- ahorra que le llegue una llamada a un telefono que ya no llevas.
    if dropped then
        lib.callback('origen_phone:rpc', false, function() end, 'phone:shutdown', {})
    end
end

--- Notificacion entrante con el telefono cerrado: se despierta la pantalla si
--- los ajustes lo piden.
---@param data table
function Phone.OnNotification(data)
    Calls.PlayAlert()

    if Phone.open then return end
    -- La interfaz decide si la pinta como aviso flotante; aqui solo hace falta
    -- que el sonido y el aviso salgan aunque no se este mirando.
    Nui.Send('backgroundNotification', data)
end

--[[ El telefono se engancha a la red sin abrirse.

     Mientras no este enganchado, el servidor no sabe que numero llevas y no te
     puede entregar nada: ni una llamada, ni un mensaje, ni un aviso. Hasta
     ahora eso pasaba al ABRIR el telefono, asi que el rato entre aparecer y
     acordarte de abrirlo eras ilocalizable sin saberlo.

     Se reintenta cada pocos segundos porque el telefono puede llegar despues
     que tu: te lo dan, lo compras, lo recoges de un cadaver. Y se para en
     cuanto engancha: no hay nada que vigilar despues. ]]
function Phone.Wake()
    if Phone.awake then return true end

    local resultado = lib.callback.await('origen_phone:rpc', false, 'phone:wake', {})
    local datos = resultado and resultado.ok and resultado.data

    if not datos or not datos.ok then return false end

    Phone.awake = true
    Phone.number = Phone.number or datos.number

    --- Para que el aviso suene con el tono del jugador, y calle si lo apago.
    Phone.settings = Phone.settings or datos.settings

    --- La interfaz necesita saber en que idioma escribir y donde poner la tarjeta.
    Nui.Send('wake', datos)
    return true
end

CreateThread(function()
    if Config.Notifications and Config.Notifications.AutoWake == false then return end

    --- Un respiro al aparecer: el inventario tarda en estar listo.
    Wait(5000)

    local cada = ((Config.Notifications and Config.Notifications.WakeEvery) or 20) * 1000

    --[[ Y no se acaba nunca, a proposito.

         Al morir se suelta el aparato y `awake` vuelve a false. Con un bucle que
         terminaba al enganchar la primera vez, tras la primera muerte el
         telefono se quedaba fuera de la red y no lo enganchaba nadie hasta que
         el jugador lo abriera a mano. Y fuera de la red no entran llamadas ni
         mensajes: quien te escribe ve su mensaje entregado, y tu no te enteras.

         Mirar una vez cada tantos segundos no cuesta nada: es leer una variable
         del propio cliente. Solo se habla con el servidor cuando de verdad hay
         que enganchar. ]]
    --[[ Y con freno.

         Mirar cada cinco segundos esta bien para el que acaba de morir y va a
         volver enseguida, pero quien no lleva movil no va a llevarlo por mucho
         que se le pregunte. Sin freno serian cien jugadores pidiendo al
         servidor cada cinco segundos para siempre.

         Se empieza rapido y se va espaciando hasta el intervalo de la
         configuracion. En cuanto engancha, vuelve a empezar rapido: la
         siguiente vez que se caiga —otra muerte— hay prisa otra vez. ]]
    local espera = 5000

    while true do
        if Phone.awake then
            espera = 5000

            --[[ Enganchado, se mira CADA SEGUNDO si sigue estandolo.

                 Antes se esperaba aqui el intervalo entero de la configuracion
                 —veinte segundos— y ese era el agujero: al morir se suelta el
                 aparato en el acto, pero el bucle podia estar en mitad de su
                 espera larga y tardar hasta veinte segundos en darse cuenta.
                 Todo lo que llegara en ese rato —el aviso a los servicios de
                 emergencias, el primero, el que mas se nota— salia arriba en
                 el medio en vez de en el telefono.

                 Y no cuesta nada, que es lo que hace que esto sea la respuesta
                 correcta y no un parche: mirar `Phone.awake` es leer una
                 variable del propio cliente. Con el servidor no se habla hasta
                 que de verdad hay que enganchar, y eso sigue con su freno. ]]
            Wait(1000)
        else
            pcall(Phone.Wake)

            Wait(espera)
            espera = math.min(espera * 2, cada)
        end
    end
end)

--[[ Un aviso que NO es del telefono.

     Para que otro recurso pueda usar la tarjeta del movil sin inventarse un
     evento de telefono: no se guarda en la base, no cuenta como no leido y no
     abre ninguna aplicacion. Solo sale y se va.

         exports.origen_phone:ShowNotification({
             app = 'services', title = 'Central', content = 'Aviso en Vinewood',
         })
]]
local function MostrarAviso(datos)
    if type(datos) ~= 'table' then return false end

    --[[ Si el servidor que lo instala quiere enseñarlo a su manera, es suyo.

         `custom/client/avisos.lua`. Devolviendo true se queda con el aviso y
         aqui no se hace nada mas; devolviendo nil asoma el telefono como de
         serie. Con pcall: un error suyo no puede dejar sin avisos al jugador. ]]
    if type(Custom) == 'table' and type(Custom.Aviso) == 'function' then
        local ok, suyo = pcall(Custom.Aviso, datos)

        if not ok then
            print(('^1[origen_phone] custom/client/avisos.lua ha fallado: %s^7'):format(tostring(suyo)))
        elseif suyo == true then
            return true
        end
    end

    --[[ `silent` para los que ya han sonado en otro sitio.

         Los avisos del servidor salen arriba en el medio y ademas aqui; si cada
         uno sonara dos veces, el telefono seria insoportable. ]]
    if datos.silent ~= true then Calls.PlayAlert() end
    Nui.Send('backgroundNotification', {
        app = type(datos.app) == 'string' and datos.app or 'settings',
        title = datos.title,
        content = datos.content,
        avatar = datos.avatar,
        thumbnail = datos.thumbnail,
        --- Sin id: no es una notificacion guardada, no hay nada que marcar leido.
        local_only = true,
        createdAt = GetGameTimer(),
    })

    return true
end

exports('ShowNotification', MostrarAviso)

-- ---------------------------------------------------------------------------
--  Acciones locales que pide la interfaz
-- ---------------------------------------------------------------------------

--[[ Mientras hay un campo de texto enfocado, las teclas dejan de llegar al
     juego. Sin esto, escribir "andando" en un mensaje hace que el personaje
     ande, salte y saque el arma: el telefono se abre con SetNuiFocusKeepInput
     precisamente para poder moverse, y eso mismo es lo que estorba al teclear. ]]
Nui.On('setTyping', function(params)
    if not Phone.open then return false end

    --- Es una fecha que caduca, no un interruptor: ver client/modules/foco.lua.
    Foco.Escribir(params.typing == true)
    return true
end)

--[[ La pagina dice que una tecla del volante se ha pulsado o soltado.

     Mientras el telefono esta delante, quien tiene el teclado de verdad es la
     pantalla: el juego perdio la tecla al coger el foco y ya no se entera de
     nada (ver client/modules/foco.lua, «QUE EL COCHE NO SE PARE»). Esto es lo
     que le dice a Lua cuando sueltas, que es el aviso que falta. ]]
Nui.On('teclaVolante', function(params)
    if type(params) ~= 'table' or type(params.code) ~= 'string' then return false end
    Foco.TeclaVolante(params.code, params.pulsada == true)
    return true
end)

Nui.On('close', function()
    Phone.Close()
    return true
end)

--[[ Marcar en el GPS una ubicacion que te han mandado.

     `SetNewWaypoint` a secas parecia no hacer nada, y no era cosa del movil:
     en este servidor no hay minimapa a pie --el HUD solo lo saca en vehiculo, y
     el mapa grande lleva RADAR_CON_RUTA = false a proposito--, asi que la ruta
     quedaba puesta en el juego sin ninguna pantalla donde verla.

     Por eso ademas se le pasa al mapa grande, que la adopta como suya: la
     ensena dibujada, con su camino y su distancia. Desde el 11/09/2026 ese
     mapa esta en origen_inventory (antes era origen_pausemenu). En el
     minimapa de origen_map aparece sola en cuanto se ve --ese recurso deja el
     radar vivo justo para que el juego siga calculando la ruta--. ]]
Nui.On('setWaypoint', function(params)
    if not params.x or not params.y then return false end

    local x, y = params.x + 0.0, params.y + 0.0
    SetNewWaypoint(x, y)

    if GetResourceState('origen_inventory') == 'started' then
        pcall(function()
            exports['origen_inventory']:MarcarRuta(x, y, params.nombre or params.label, nil)
        end)
    end

    --[[ El aviso sale en el propio telefono y no arriba en el medio.

         Lo has hecho DESDE el movil y con el movil delante: la tarjeta aparece
         donde estas mirando. El aviso del servidor, ademas, se comia el sitio
         de los que si vienen de fuera.

         `silent`: la tarjeta se ve porque tienes el telefono abierto, asi que
         un pitido para avisarte de algo que acabas de pulsar tu sobra. ]]
    local sitio = params.nombre or params.label
    MostrarAviso({
        app = 'map',
        title = Locale.Say('gps_marked_title'),
        content = (type(sitio) == 'string' and sitio ~= '') and sitio or Locale.Say('gps_route_set'),
        silent = true,
    })

    return true
end)

--- Coordenadas actuales, para compartir ubicacion en un mensaje o etiquetar
--- una publicacion.
--[[ Como se llama un sitio del mapa.

     La aplicacion de viajes deja poner la chincheta en su propio mapa, y ahi no
     hay mas que dos numeros: es el juego quien sabe que ese punto se llama
     "Sandy Shores". Tambien se busca el suelo, porque el mapa es plano y la
     distancia de un viaje se mide en tres dimensiones. ]]
Nui.On('zoneAt', function(params)
    if not params or not params.x then return nil end

    local x, y = params.x + 0.0, params.y + 0.0

    -- Si la zona no esta cargada —lo normal si esta lejos— no hay altura que
    -- consultar; se deja en cero y ya se ajustara al llegar. La distancia
    -- apenas cambia por eso.
    local ok, z = GetGroundZFor_3dCoord(x, y, 1000.0, false)
    local alto = ok and z or 0.0

    return {
        x = x,
        y = y,
        z = alto,
        label = GetLabelText(GetNameOfZone(x, y, alto)),
    }
end)

--[[ Donde esta el punto marcado en el mapa.

     El destino de un viaje sale de ahi y no de escribir una direccion: marcar
     en el mapa es lo que ya sabe hacer todo el mundo en este juego, y no hay
     ningun callejero que consultar. ]]
Nui.On('getWaypoint', function()
    local blip = GetFirstBlipInfoId(8)   -- 8 es el del punto de destino
    if not DoesBlipExist(blip) then return nil end

    local coords = GetBlipInfoIdCoord(blip)

    --[[ El mapa no da la altura, solo el punto sobre el plano.

         Se busca el suelo en esa vertical; si la zona no esta cargada —lo
         normal si esta lejos— se deja en cero y ya se ajustara al llegar. La
         distancia apenas cambia por la altura. ]]
    local ok, z = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)

    return {
        x = coords.x,
        y = coords.y,
        z = ok and z or 0.0,
        label = GetLabelText(GetNameOfZone(coords.x, coords.y, ok and z or 0.0)),
    }
end)

--[[ La ruta que hay puesta ahora mismo, para el widget del GPS.

     El juego no dice "a donde vas": dice que hay una chincheta en tal sitio.
     El nombre sale de la zona del mapa y lo que falta, de la distancia en linea
     recta. No es la distancia por carretera —eso el juego no lo da— y por eso
     el widget la enseña como aproximada. ]]
Nui.On('getRoute', function()
    local marca = GetFirstBlipInfoId(8)
    if not DoesBlipExist(marca) then return { activa = false } end

    local destino = GetBlipInfoIdCoord(marca)
    local yo = GetEntityCoords(PlayerPedId())

    return {
        activa = true,
        label = GetLabelText(GetNameOfZone(destino.x, destino.y, destino.z)),
        metros = #(vector2(yo.x, yo.y) - vector2(destino.x, destino.y)),
    }
end)

--[[ Pescabichos: de unos puntos, cuales caen en agua (mar, lago, rio).
     El servidor no lo sabe y lo pregunta al hacer salir bichos: en el agua
     solo salen los acuaticos. Hay agua si el juego da una altura de agua por
     encima del suelo de ese punto. ]]
lib.callback.register('origen_phone:pb:agua', function(puntos)
    local r = {}
    for i, p in ipairs(type(puntos) == 'table' and puntos or {}) do
        if i > 12 then break end
        local x, y, z = tonumber(p.x) or 0.0, tonumber(p.y) or 0.0, tonumber(p.z) or 0.0
        local hay, agua = GetWaterHeightNoWaves(x, y, z + 40.0)
        local suelo, zs = GetGroundZFor_3dCoord(x, y, z + 40.0, false)
        r[i] = hay == true and (not suelo or zs < agua - 0.6)
    end
    return r
end)

--- Pescabichos: la hora del juego, que el servidor no sabe. Ver
--- server/api/pescabichos.lua (HoraDelJuego): se fia de la que mas se repite.
local CLIMAS = { 'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'SMOG', 'FOGGY', 'OVERCAST', 'RAIN', 'THUNDER', 'CLEARING',
    'NEUTRAL', 'SNOW', 'BLIZZARD', 'SNOWLIGHT', 'XMAS', 'HALLOWEEN' }

Nui.On('pbHora', function()
    local h = GetPrevWeatherTypeHashName()
    local clima
    for _, c in ipairs(CLIMAS) do if GetHashKey(c) == h then clima = c break end end
    return { hora = GetClockHours(), clima = clima }
end)

Nui.On('getPosition', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local street, crossing = GetStreetNameAtCoord(coords.x, coords.y, coords.z)

    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,

        --[[ Y hacia dónde miras.

             Lo usa el panel para orientar al dependiente de la tienda: te pones
             donde quieres el mostrador, mirando hacia donde tiene que mirar él,
             y se guarda eso. En grados no lo sabe nadie.

             Va AQUÍ y no en `adminHere` —que es el otro «dónde estoy» del
             recurso— porque es este el que usa el panel para poner una tienda.
             Puesto en el otro no llegaba, y el rumbo salía siempre a cero. ]]
        h = GetEntityHeading(ped),
        street = GetStreetNameFromHashKey(street),
        crossing = crossing ~= 0 and GetStreetNameFromHashKey(crossing) or nil,
        zone = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z)),
    }
end)

--- Hora del juego, para el reloj de la pantalla de bloqueo.
--[[ El ping, para el widget del servidor.

     Lo pregunta el cliente y no el servidor porque es lo unico de ese widget
     que el servidor no puede saber: es lo que tarda TU maquina en hablar con
     el, y eso solo se mide desde tu maquina. ]]
--[[ GetPlayerPing solo existe en el SERVIDOR. Aqui se llamaba desde el
     cliente y reventaba en cada vuelta del widget ("attempt to call a nil
     value (global 'GetPlayerPing')", 16/09), asi que el ping salia siempre
     vacio y la consola se llenaba de rojo. Se pregunta al servidor, y la
     respuesta se guarda 5 s: el widget la pide cada 10 y puede haber varias
     pantallas pidiendola a la vez. ]]
local pingGuardado, pingHasta = nil, 0

Nui.OnAsync('getPing', function(_, listo)
    local ahora = GetGameTimer()
    if pingGuardado == nil or ahora >= pingHasta then
        local ok, valor = pcall(function()
            return lib.callback.await('origen_phone:ping', false)
        end)
        if ok and type(valor) == 'number' then
            pingGuardado = valor
            pingHasta = ahora + 5000
        end
    end
    listo({ ping = pingGuardado or 0 })
end)

Nui.On('getTime', function()
    return {
        hours = GetClockHours(),
        minutes = GetClockMinutes(),
        day = GetClockDayOfMonth(),
        month = GetClockMonth() + 1,
        year = GetClockYear(),
        weather = Phone.currentWeather or 'CLEAR',
    }
end)

Nui.On('vibrate', function()
    -- Golpe corto del mando, que en teclado no hace nada pero en pad se nota.
    SetControlShakeParameters(0, 100, 60)
    return true
end)

-- El tiempo se consulta poco y cambia despacio: una vez por minuto sobra.
CreateThread(function()
    while true do
        Phone.currentWeather = GetPrevWeatherTypeHashName()
        Wait(60000)
    end
end)

-- ---------------------------------------------------------------------------
--  Perder el telefono
-- ---------------------------------------------------------------------------

AddEventHandler('gameEventTriggered', function(event, args)
    if event ~= 'CEventNetworkEntityDamage' then return end
    if not Config.CloseOnDeath then return end

    local victim = args[1]
    if victim == PlayerPedId() and IsPedDeadOrDying(victim, true) then
        Phone.Drop()
    end
end)

RegisterNetEvent('origen_phone:cl:itemRemoved', function()
    Wait(500)
    if not Phone.number then return end
    if not Framework.HasPhoneItem(Phone.number) then
        Phone.Drop()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    --[[ Marcado como cerrado lo primero: los manejadores de parada de los
         demas modulos (el de la camara va despues de este) miran
         `Phone.open` para decidir si devuelven la postura del telefono. ]]
    Phone.open = false

    Foco.Todo()
    DestroyPhoneProp()
    Phone.StopAnimation()
end)

--[[ Cuando la red de seguridad suelta el foco a la fuerza.

     `soltarraton` en la consola F8 (origen_hud), o una repeticion de
     origen_admin que empieza, sueltan el foco de este recurso sin pasar por
     Phone.Close. El raton quedaba libre, pero `Phone.open` seguia en true: el
     hilo de controles seguia apagando la vista (1 y 2), el ataque y la pausa
     con el telefono ya sin foco, y el telefono seguia pintado. Se cierra
     entero, que es lo que el jugador esperaba al escribir el comando. ]]
if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        abriendo = false
        vueltaApertura = vueltaApertura + 1
        if Phone.open then Phone.Close() end
        --- Lo que quede (admin, tienda) tambien se da por soltado.
        Foco.Todo()
    end)
end

--- La interfaz avisa al cambiar un ajuste, para que el cliente use el nuevo
--- valor sin tener que volver a preguntar al servidor.
--[[ La pantalla del telefono ha fallado.

     Lo manda la propia pagina (source-ui/src/main.ts) al recoger un error
     suelto. Con `fatal` es que ya lo intento y volvio a fallar: se cierra el
     telefono entero, que es lo unico que devuelve el raton, las teclas y la
     camara al juego.

     El texto se imprime en F8 para poder leer QUE fallo: hasta ahora un error
     de la pagina solo se veia como un telefono negro y pillado. ]]
Nui.On('uiError', function(params)
    print(('^1[origen_phone]^7 la pantalla ha fallado (%s): %s')
        :format(tostring(params.donde), tostring(params.mensaje)))

    if params.fatal ~= true then return end

    if Phone.open then
        Phone.Close()
    else
        --- Sin telefono abierto no hay nada que cerrar, pero el foco puede
        --- haberse quedado suyo igualmente (el admin, la tienda).
        Foco.Todo()
    end

    return true
end)

--[[ La pagina se ha recargado y el cliente no (24/09).

     El cliente guarda `Phone.booted` y solo arranca la primera vez; si la
     pagina se recarga sola (la NUI reiniciada, el navegador del juego que se
     cae), pierde el numero, las apps y los textos, y el siguiente F1 solo le
     manda `visible`: una carcasa NEGRA que no sale de ahi hasta reconectar.

     `uiLista`   : la pagina acaba de nacer (main.ts). Se olvida el arranque.
     `sinArranque`: la pagina ha recibido `visible` sin arranque (bridge.ts).
                    Se cierra y se vuelve a abrir arrancando, una vez cada 15 s
                    como mucho para no entrar en bucle si el arranque no llega. ]]
--[[ La marca del servidor, nada mas nacer la pagina (05/10).

     Antes solo llegaba con el arranque de un telefono (applyBoot). Pero el
     movil que ASOMA con un aviso sale sin que nadie haya abierto el telefono
     (tras un reinicio del recurso, o recien entrado), y sin marca no entraba
     su estilo: salia con la piel vieja. main.ts la pide al cargar. ]]
Nui.On('marca', function()
    return GetConvar('origen:marca', 'origen')
end)

Nui.On('uiLista', function()
    if not Phone.booted and not Phone.open then return true end

    print('^3[origen_phone]^7 la pantalla se ha recargado: se arrancara de nuevo al abrir')
    Phone.booted = false
    if Phone.open then Phone.Close() end
    return true
end)

local ultimoRearranque = -30000

Nui.On('sinArranque', function()
    Phone.booted = false
    local estabaAbierto = Phone.open
    if Phone.open then Phone.Close() end

    local ahora = GetGameTimer()
    if not estabaAbierto or ahora - ultimoRearranque < 15000 then return true end
    ultimoRearranque = ahora

    local numero = Phone.number
    CreateThread(function() Phone.Open(numero) end)
    return true
end)

Nui.On('settingsChanged', function(params)
    Phone.settings = params.settings

    --- El volumen de llamada vive en pma-voice, no en la pagina.
    if Calls and Calls.AplicarVolumen then Calls.AplicarVolumen() end
    return true
end)
