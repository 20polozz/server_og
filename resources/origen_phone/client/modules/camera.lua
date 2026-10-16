--[[ Camara.

     Dos modos, como en cualquier movil:
       - trasera: la camara mira hacia donde mira el personaje, con el telefono
         levantado por delante.
       - frontal: se da la vuelta y enfoca la cara. Es la de los selfies.

     La foto no se hace aqui: la hace la propia interfaz, que tiene la imagen
     del juego metida en un lienzo (ver source-ui/utils/vistaJuego). Aqui solo
     se coloca la camara, se enciende la luz y suena el obturador. Antes habia
     que esconder el telefono un instante y pedirle la captura a otro recurso,
     porque fotografiaba la ventana entera.
]]

Camera = {}

Camera.active = false
Camera.selfie = false

--[[ Quien la tiene abierta: 'camera', 'call' o 'live'.

     La piden tres sitios distintos y ninguno sabe de los otros. Sin esto,
     colgar una videollamada mientras esta abierta la aplicacion de fotos le
     apagaba el visor a la aplicacion de fotos, y el jugador se quedaba mirando
     el mundo desde donde estaba el telefono sin saber por que. ]]
Camera.owner = nil

--[[ De quien es el raton.

     Con la camara abierta el raton no puede servir para las dos cosas a la
     vez: si mueve el encuadre, no llega al boton de disparar, y si mueve el
     cursor, no se puede apuntar. Asi que se turnan, y se cambia con una tecla.

     Se entra con el cursor puesto, que es lo que espera quien acaba de abrir
     una aplicacion. ]]
Camera.aiming = false

--- Alt izquierdo (INPUT_CHARACTER_WHEEL). Se apaga su accion del juego para
--- que no se abra la rueda de personaje al pulsarlo.
local TECLA_MODO = 19
--- Intro (INPUT_CELLPHONE_SELECT): dispara sin tener que volver al cursor.
local TECLA_DISPARO = 176
--- La rueda del raton, para acercar y alejar.
local RUEDA_MAS = 241
local RUEDA_MENOS = 242
--- Cuanto acerca cada muesca de la rueda.
local PASO_ZOOM = 0.1

local cam = nil
local zoom = 0.0            -- 0 = sin zoom, 1 = maximo
local pitch = 0.0           -- cuanto mira arriba o abajo
local swing = 0.0           -- solo en selfie: cuanto se aparta la lente del cuerpo
local giro = 0.0            -- solo en un vehiculo: cuanto gira la lente respecto al coche

local MIN_FOV, MAX_FOV = 20.0, 70.0

--[[ La lente cuelga de la cabeza, no del personaje.

     GetEntityCoords devuelve el suelo bajo los pies, asi que colocar ahi la
     camara con un poco de altura la deja dentro del pecho: se ve el propio
     cuerpo por delante y la imagen se mueve como el torso, no como la mirada.
     Colgandola del hueso de la cabeza y adelantandola un palmo, queda donde
     estaria un movil en la mano y el cuerpo se queda detras. ]]
local HUESO_CABEZA = 31086

--- Metros que la lente trasera va por delante de los ojos.
local ADELANTE = 0.16
--- Metros que sube por encima del hueso de la cabeza.
local SUBIDA = 0.04

--[[ Selfie: la lente va donde esta el aparato.

     Con el brazo de la animacion de selfie, el telefono queda a poco mas de
     medio metro de la cara. Poniendo la lente ahi mismo, el propio aparato cae
     justo en el plano de la camara y no puede salir en la foto; dejandola mas
     lejos, se cruzaba por delante. ]]
local BRAZO = 0.55
local DERECHA = 0.05
local BAJADA = 0.02

--- Limites de giro, en grados.
local LIMITE_PITCH = 60.0
local LIMITE_SWING = 75.0

--- Velocidad a partir de la cual se considera que el personaje va andando.
local ANDANDO = 0.1

--- Movimiento del raton por debajo del cual no se esta apuntando a proposito.
local ZONA_MUERTA = 0.002

--- Vector unitario hacia donde mira un pitch/yaw dado, en grados.
---@param p number
---@param y number
---@return vector3
local function Hacia(p, y)
    local rp, ry = math.rad(p), math.rad(y)
    local horiz = math.abs(math.cos(rp))
    return vector3(-math.sin(ry) * horiz, math.cos(ry) * horiz, math.sin(rp))
end

local function GetFov()
    return MAX_FOV - (MAX_FOV - MIN_FOV) * zoom
end

--[[ Coloca la camara. Se llama en cada fotograma.

     Antes solo se llamaba al mover el raton, y eso daba los dos fallos que se
     notaban andando: la camara se quedaba plantada mientras el personaje se
     alejaba, y al tocar el raton pegaba el salto hasta la posicion nueva de
     golpe. Colocarla siempre cuesta cuatro cuentas y se acabo. ]]
local function UpdateCamera()
    if not cam then return end

    local ped = PlayerPedId()
    local cabeza = GetPedBoneCoords(ped, HUESO_CABEZA, 0.0, 0.0, 0.0)
    local rumbo = GetEntityHeading(ped)

    --[[ Sentado, la lente gira por su cuenta: ver Apuntar. Fuera del coche el
         giro no cuenta, o al bajarse la camara seguiria mirando de lado. ]]
    if IsPedInAnyVehicle(ped, false) then
        rumbo = rumbo + giro
    else
        giro = 0.0
    end

    if Camera.selfie then
        --[[ La lente orbita alrededor de la cara y mira siempre hacia ella.

             Se calcula donde va —a un brazo, girada lo que diga el raton, mas
             arriba o mas abajo segun el pitch— y luego se le dice que apunte a
             la cabeza. Apuntar en vez de fijar el angulo a mano es lo que
             garantiza que salgas centrado hagas lo que hagas: cualquier cuenta
             de rotacion que se desvie un grado te saca del encuadre, y eso ya
             paso una vez. ]]
        local p = math.rad(pitch)
        local giro = math.rad(rumbo + swing)

        local lejos = math.cos(p) * BRAZO
        local alto = math.sin(p) * BRAZO

        local pos = vector3(
            cabeza.x - math.sin(giro) * lejos + math.cos(giro) * DERECHA,
            cabeza.y + math.cos(giro) * lejos + math.sin(giro) * DERECHA,
            cabeza.z + alto - BAJADA
        )

        SetCamCoord(cam, pos.x, pos.y, pos.z)
        PointCamAtCoord(cam, cabeza.x, cabeza.y, cabeza.z)
    else
        --[[ Lo primero, soltar el "mira hacia ahi".

             La frontal usa PointCamAtCoord, y eso no es una orden de un
             fotograma: deja la camara amarrada a ese punto hasta que se le diga
             lo contrario. Al volver a la trasera, SetCamRot no pintaba nada
             —la camara seguia clavada mirando al ultimo sitio donde estuvo la
             cabeza— asi que el encuadre se quedaba tieso, el personaje se veia
             cortado por dentro y girar el raton movia el cuerpo pero no la
             vista. Se suelta aqui, que es por donde se pasa siempre. ]]
        StopCamPointing(cam)

        -- Delante de los ojos, mirando a donde mira el personaje.
        local pos = cabeza + Hacia(pitch, rumbo) * ADELANTE + vector3(0.0, 0.0, SUBIDA)
        SetCamCoord(cam, pos.x, pos.y, pos.z)
        SetCamRot(cam, pitch, 0.0, rumbo, 2)
    end

    SetCamFov(cam, GetFov())
end

--[[ Aplica el raton.

     En la trasera el raton gira al **personaje**, no a la camara: asi la
     lente mira siempre hacia delante y andar con WASD te lleva a donde estas
     apuntando, que es lo que espera cualquiera. Girar solo la camara dejaba al
     personaje andando de lado respecto a lo que se veia.

     En la frontal es al reves: ahi si se aparta la lente del cuerpo, porque de
     lo que se trata es de sacarse de otro angulo sin tener que darse la vuelta. ]]
---@param dx number
---@param dy number
local function Apuntar(dx, dy)
    local ped = PlayerPedId()

    pitch = math.max(-LIMITE_PITCH, math.min(LIMITE_PITCH, pitch - dy))

    if Camera.selfie then
        swing = math.max(-LIMITE_SWING, math.min(LIMITE_SWING, swing - dx))
        return
    end

    if dx == 0.0 then return end

    --[[ DENTRO DE UN VEHICULO SE GIRA LA LENTE, NO EL PERSONAJE.

         SetEntityHeading sobre alguien sentado no gira al personaje: gira el
         coche entero con el dentro. Apuntar con la camara desde el asiento
         hacia girar el coche parado o en marcha (17/09). Sentado no hay forma
         de andar hacia donde se apunta, asi que lo unico que tiene sentido es
         mover la lente, como en la frontal. Vuelta completa permitida: desde
         un coche se fotografia hacia cualquier lado. ]]
    if IsPedInAnyVehicle(ped, false) then
        giro = (giro - dx + 180.0) % 360.0 - 180.0
        return
    end

    --[[ Parado se le cambia el rumbo de golpe y andando se le pide que gire.

         Cambiarlo de golpe mientras anda lo desliza de lado dentro de la
         animacion de andar hacia delante, que es ese caminar raro de medio
         perfil. Pidiendoselo, gira a su ritmo y el paso acompana. ]]
    local nuevo = GetEntityHeading(ped) - dx
    if GetEntitySpeed(ped) > ANDANDO then
        SetPedDesiredHeading(ped, nuevo)
    else
        SetEntityHeading(ped, nuevo)
    end
end

---@param selfie boolean|nil
---@param owner string|nil  quien la pide: 'camera', 'call' o 'live'
function Camera.Open(selfie, owner)
    if Camera.active then return end

    --[[ Sin telefono abierto no hay camara.

         La aplicacion la pide al montarse ('cameraOpen'), y ese aviso de la
         NUI llega cuando llega: abrir el telefono con la camara como ultima
         aplicacion y cerrarlo enseguida (o morir en ese momento) hacia que
         Phone.Close pasara primero —sin camara que cerrar— y la peticion
         llegara despues. Quedaba la camara de guion puesta, la vista y el
         ataque apagados por el hilo de abajo y la postura de foto, con el
         telefono cerrado: el Escape de client/main.lua solo escucha con el
         telefono abierto, asi que no habia salida. ]]
    if not Phone.open then return end

    Camera.active = true

    --[[ Cada apertura tiene su numero, y su hilo solo vive mientras sea la
         ultima. Cerrar y abrir en el mismo frame (pulsar varias veces el boton
         de video) dejaba vivo el hilo anterior, porque `active` volvia a true
         antes de que mirara: un hilo mas por pulsacion, todos cada frame. ]]
    Camera.tanda = (Camera.tanda or 0) + 1
    local tanda = Camera.tanda

    Camera.owner = owner or 'camera'
    Camera.selfie = selfie == true
    Camera.aiming = false
    zoom, pitch, swing, giro = 0.0, 0.0, 0.0, 0.0

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    UpdateCamera()
    RenderScriptCams(true, true, 400, true, true)

    -- Brazo estirado, que es como se sostiene un movil para hacer una foto.
    Phone.SetPose('photo')

    -- Mientras la camara esta abierta, el raton mueve el encuadre en vez de la
    -- vista del juego. Pero solo mientras se este apuntando: en el otro modo el
    -- raton es del telefono y esto no toca nada.
    CreateThread(function()
        while Camera.active and Camera.tanda == tanda do
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, TECLA_MODO, true)
            DisableControlAction(0, TECLA_DISPARO, true)
            DisableControlAction(0, RUEDA_MAS, true)
            DisableControlAction(0, RUEDA_MENOS, true)

            -- La tecla de cambiar responde en los dos modos: es la unica forma
            -- de volver al cursor una vez apuntando.
            if IsDisabledControlJustPressed(0, TECLA_MODO) then
                Camera.SetAiming(not Camera.aiming)
            end

            -- La rueda acerca y aleja en los dos modos: es el gesto que sale
            -- solo, y dentro del visor no hay nada mas que desplazar.
            if IsDisabledControlJustPressed(0, RUEDA_MAS) then
                Camera.SetZoom(zoom + PASO_ZOOM, true)
            elseif IsDisabledControlJustPressed(0, RUEDA_MENOS) then
                Camera.SetZoom(zoom - PASO_ZOOM, true)
            end

            if Camera.aiming then
                if IsDisabledControlJustPressed(0, TECLA_DISPARO) then
                    Nui.Send('cameraShoot', {})
                end

                local dx = GetDisabledControlNormal(0, 1)
                local dy = GetDisabledControlNormal(0, 2)

                -- La zona muerta evita que el temblor del raton reoriente al
                -- personaje solo por estar quieto con la mano encima.
                if dx > ZONA_MUERTA or dx < -ZONA_MUERTA
                    or dy > ZONA_MUERTA or dy < -ZONA_MUERTA then
                    Apuntar(dx * 8.0, dy * 5.0)
                end
            end

            --[[ El telefono, invisible para uno mismo.

                 Estas mirando *a traves* de el, asi que no puede salir en su
                 propia foto; con el brazo estirado se plantaba en mitad del
                 encuadre. Se esconde solo para esta pantalla: los demas
                 jugadores te siguen viendo sosteniendolo, que es lo que tiene
                 que verse desde fuera. Hay que repetirlo cada fotograma. ]]
            local aparato = Phone.GetProp()
            if aparato and DoesEntityExist(aparato) then
                SetEntityLocallyInvisible(aparato)
            end

            -- Siempre, se este apuntando o no: el personaje se mueve con WASD
            -- en los dos modos y la camara tiene que ir con el.
            UpdateCamera()

            Wait(0)
        end
    end)
end

--[[ Pasa el raton de la camara al telefono y al reves.

     Se avisa a la interfaz para que ensene en que modo esta: sin decirlo, el
     jugador pulsa el boton, no pasa nada, y da por hecho que se ha roto. ]]
---@param on boolean
function Camera.SetAiming(on)
    if not Camera.active or not Phone.open then return end

    on = on == true
    if Camera.aiming == on then return end

    Camera.aiming = on

    -- Apuntando el raton es del juego; con el cursor, del telefono. El foco de
    -- la interfaz se mantiene en los dos casos para que las teclas sigan
    -- llegando. Lo pone client/modules/foco.lua a partir del estado.
    Foco.apuntando = on
    Foco.Aplicar()

    Nui.Send('cameraAim', { on = on })
end

---@param owner string|nil  solo cierra quien la abrio
function Camera.Close(owner)
    if owner and Camera.owner and Camera.owner ~= owner then return end

    Camera.owner = nil
    return Camera.CloseNow()
end

function Camera.CloseNow()
    if not Camera.active then return end

    Camera.active = false
    Camera.SetFlash(false)

    --[[ La postura de vuelta, solo si el telefono sigue en la mano.

         Desde Phone.Close sin llamada, ponerla no servia de nada (se quita
         justo despues) y costaba caro: cargar el diccionario puede ceder el
         hilo, y en ese hueco el cierre aun no habia soltado el foco. Al
         reiniciar el recurso con la camara abierta era peor: la postura se
         ponia DESPUES de que phone.lua la quitara, y el personaje se quedaba con
         el brazo levantado y sin telefono. ]]
    if Phone.open or Calls.IsActive() then
        Phone.PlayAnimation(Calls.IsActive())
    end

    -- Igual que arriba: se suelta antes de devolver la vista al juego.
    if cam then StopCamPointing(cam) end

    -- El cursor vuelve si se sale apuntando: el telefono se quedaria sin raton
    -- y no habria forma de tocar nada. Pero SOLO con el telefono abierto: si
    -- se ha cerrado (morir, que te quiten el movil), la app avisa al
    -- desmontarse y cogeria el foco sin pantalla delante: raton preso.
    if Camera.aiming then
        Camera.aiming = false
        Foco.apuntando = false
        if Phone.open then Foco.Aplicar() end
    end
    RenderScriptCams(false, true, 400, true, true)
    if cam then
        DestroyCam(cam, false)
        cam = nil
    end
end

---@param value number  0..1
---@param avisar boolean|nil  true si el cambio viene del juego y la interfaz
---                           no se ha enterado (la rueda del raton)
function Camera.SetZoom(value, avisar)
    local antes = zoom
    zoom = math.max(0.0, math.min(1.0, tonumber(value) or 0.0))
    if zoom == antes then return end

    UpdateCamera()
    if avisar then Nui.Send('cameraZoom', { value = zoom }) end
end

function Camera.Flip()
    Camera.selfie = not Camera.selfie
    pitch, swing = 0.0, 0.0

    UpdateCamera()
end

--[[ El obturador.

     Solo el sonido: la imagen la saca la interfaz de su propio lienzo. Se deja
     en el cliente porque un sonido del juego no se puede reproducir desde la
     pagina, y este es el de la camara del movil de GTA. ]]
function Camera.Sound()
    PlaySoundFrontend(-1, 'Camera_Shoot', 'Phone_Soundset_Franklin', true)
end

--[[ La luz del flash.

     No hay ninguna "linterna del telefono" en el juego, asi que se dibuja una
     luz puntual justo delante de la camara que se este renderizando, fotograma
     a fotograma. Delante y no encima: pegada a la camara, lo unico que ilumina
     es el aire que hay entre la lente y la escena, y se ve como una niebla
     blanca en vez de como una linterna. ]]
local flashOn = false
local flashLoop = false

function Camera.SetFlash(on)
    flashOn = on == true
    if not flashOn or flashLoop then return end

    flashLoop = true
    CreateThread(function()
        while flashOn and Camera.active do
            local pos = GetFinalRenderedCamCoord()
            local rot = GetFinalRenderedCamRot(2)

            local rx, rz = math.rad(rot.x), math.rad(rot.z)
            local horiz = math.abs(math.cos(rx))
            local dir = vector3(-math.sin(rz) * horiz, math.cos(rz) * horiz, math.sin(rx))
            local at = pos + dir * 0.7

            DrawLightWithRange(at.x, at.y, at.z, 255, 250, 235, 12.0, 18.0)
            Wait(0)
        end
        flashLoop = false
    end)
end

-- ---------------------------------------------------------------------------
--  Acciones locales
-- ---------------------------------------------------------------------------

Nui.On('cameraOpen', function(params)
    Camera.Open(params.selfie, params.owner or 'camera')
    return { selfie = Camera.selfie }
end)

Nui.On('cameraClose', function(params)
    Camera.Close(params.owner or 'camera')
    return true
end)

Nui.On('cameraFlip', function()
    Camera.Flip()
    return { selfie = Camera.selfie }
end)

Nui.On('cameraZoom', function(params)
    Camera.SetZoom(params.value)
    return { zoom = zoom }
end)

Nui.On('cameraShutterSound', function()
    Camera.Sound()
    return true
end)

Nui.On('cameraAim', function(params)
    Camera.SetAiming(params.on)
    return { on = Camera.aiming }
end)

Nui.On('cameraFlash', function(params)
    Camera.SetFlash(params.on)
    return { on = params.on == true }
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not Camera.active then return end

    Camera.Close()

    --[[ Con una llamada en curso, CloseNow devuelve la postura de hablar, y
         este manejador va detras del de phone.lua, que ya la habia quitado. Con
         el recurso parandose no queda nadie que la quite despues. ]]
    Phone.StopAnimation()
end)
