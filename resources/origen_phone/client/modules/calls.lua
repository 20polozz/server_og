--[[ Llamadas en el cliente.

     Aqui no se decide nada de la llamada: el servidor manda. Este fichero se
     ocupa de lo que solo se puede hacer en el cliente: sonar, abrir la pantalla
     de llamada aunque el telefono estuviera cerrado, poner la animacion de
     hablar y montar el render de la videollamada.
]]

Calls = {}

Calls.current = nil     -- { id, state, outgoing, number, name, isVideo }

local ringing = false

-- ---------------------------------------------------------------------------
--  Sonido
-- ---------------------------------------------------------------------------

--- Tono elegido en los ajustes, o el primero de la lista si no hay ninguno.
---@param list table
---@param id string|nil
---@return table|nil
local function FindSound(list, id)
    for i = 1, #list do
        if list[i].id == id then return list[i] end
    end
    return list[1]
end

--[[ El telefono suena.

     La clave esta en el primer argumento de `PlaySoundFrontend`: el id del
     sonido. Con -1 el juego lo reproduce y se olvida de el, y eso vale para un
     pitido suelto pero NO para un tono de llamada. `Remote_Ring` se repite solo
     hasta que alguien lo para, asi que lanzado con -1 no habia manera de
     callarlo: cogias la llamada y seguia sonando encima de la conversacion.

     Con un id propio se puede parar (`StopSound`) y devolver (`ReleaseSoundId`),
     que es lo que hace que el tono se corte en el momento justo en que se
     descuelga.

     El sonido respeta el silencio del telefono: con el sonido apagado en
     ajustes o con el no molestar puesto, la llamada entra igual pero sin ruido. ]]
---@return boolean
local function WantsSound()
    local settings = Phone.settings
    if not settings then return true end
    if settings.doNotDisturb then return false end
    if settings.notifications and settings.notifications.soundEnabled == false then return false end
    return true
end

--- El id del tono que esta sonando ahora mismo, para poder pararlo.
local ringId = nil

--- Deja de sonar: corta el tono y suelta el id.
local function StopRingtone()
    ringing = false

    --- El de la interfaz.
    Nui.Send('sound', { stop = true })

    --- Y el del juego, que es el del tono de "llamando".
    if ringId then
        StopSound(ringId)
        ReleaseSoundId(ringId)
        ringId = nil
    end
end

--[[ Arranca un tono y lo deja sonando hasta que se pare.

     Los tonos que se repiten solos (`loops`) se lanzan una vez y ya. Los que
     son un golpe corto hay que repetirlos a mano cada `every` milisegundos para
     que suenen a telefono y no a pitido suelto. ]]
---@param entry table
local function PlayLoop(entry)
    if not entry or not entry.sound then return end
    if ringing then return end
    if not WantsSound() then return end

    ringing = true
    ringId = GetSoundId()

    PlaySoundFrontend(ringId, entry.sound, entry.set, true)

    if entry.loops then return end

    -- Los cortos, a mano. Se reutiliza el mismo id parandolo antes de repetir,
    -- para no ir dejando ids sueltos por el camino.
    CreateThread(function()
        while ringing do
            Wait(entry.every or 1200)
            if not ringing then break end

            if ringId then
                StopSound(ringId)
                PlaySoundFrontend(ringId, entry.sound, entry.set, true)
            end
        end
    end)
end

--[[ Suena al recibir. El tono sale de los ajustes del telefono.

     Lo suena la interfaz, que es quien puede con un fichero. Y suena con el
     telefono guardado: la pagina esta cargada aunque no se vea. ]]
local function StartRingtone()
    if not WantsSound() then return end

    local ajustes = Phone.settings and Phone.settings.sound
    local entry = FindSound(Config.Sounds.Ringtones, ajustes and ajustes.ringtone)
    if not entry or not entry.file then return end

    ringing = true

    Nui.Send('sound', {
        file = entry.file,
        loop = true,
        volume = ((ajustes and ajustes.ringtoneVolume) or 80) / 100,
    })
end

--[[ El tono de llamando: lo que oye quien llama mientras el otro no coge. Es el
     mismo para todos, porque no es un gusto: es como suena la linea. ]]
local function StartRingback()
    PlayLoop(Config.Sounds.Ringback)
end

--- El clic de colgar. Cierra la llamada de oido, que es lo que le falta a una
--- llamada que se corta sin mas. Este si es un golpe suelto y se va solo.
local function PlayHangup()
    if not WantsSound() then return end
    PlaySoundFrontend(-1, Config.Sounds.Hangup.sound, Config.Sounds.Hangup.set, true)
end

--- Aviso corto de una notificacion. Lo llama el telefono, no las llamadas.
function Calls.PlayAlert()
    local settings = Phone.settings
    if settings and settings.notifications and settings.notifications.soundEnabled == false then
        return
    end

    local ajustes = settings and settings.sound
    local entry = FindSound(Config.Sounds.Alerts, ajustes and ajustes.alert)

    --- "Sin tono" es una opcion de la lista y no lleva fichero.
    if not entry or not entry.file then return end

    Nui.Send('sound', {
        file = entry.file,
        loop = false,
        volume = ((ajustes and ajustes.alertVolume) or 65) / 100,
    })
end

--- La muestra que esta sonando ahora mismo, para poder callarla.
local muestraId = nil
local muestraTanda = 0

--- Corta la muestra que hubiera sonando. Se puede llamar siempre.
function Calls.StopPreview()
    muestraTanda = muestraTanda + 1

    if not muestraId then return end

    StopSound(muestraId)
    ReleaseSoundId(muestraId)
    muestraId = nil
end

--[[ Deja oir un tono al elegirlo en los ajustes.

     CON UN ID PROPIO, NO CON -1. Es lo mismo que ya estaba escrito arriba para
     el tono de llamada y que aqui se habia quedado sin aplicar: con -1 el juego
     reproduce el sonido y se olvida de el, asi que un tono que se repite solo
     —y varios de la lista lo hacen— no hay forma de callarlo. Se quedaba
     sonando para siempre, por debajo de todo lo demas, y aparecia otra vez
     encima del tono al recibir una llamada.

     Y se corta sola a los dos segundos y medio: una muestra es para oir como
     suena, no para dejarla puesta. La tanda es para que, si se pulsan tres
     tonos seguidos, el temporizador del primero no calle al tercero. ]]
---@param kind string  'ringtone' | 'alert'
---@param id string
function Calls.PreviewSound(kind, id)
    local list = kind == 'ringtone' and Config.Sounds.Ringtones or Config.Sounds.Alerts
    local entry = FindSound(list, id)

    Calls.StopPreview()

    --- La interfaz la corta sola a los cuatro segundos, y se puede cortar.
    if entry and entry.file then
        Nui.Send('sound', { file = entry.file, preview = true })
    end
end

-- ---------------------------------------------------------------------------
--  Estado
-- ---------------------------------------------------------------------------

---@return boolean
function Calls.IsActive()
    return Calls.current ~= nil
end

--- Llamada entrante: suena y se abre la pantalla aunque el telefono estuviera
--- guardado, porque un telefono que no suena en el bolsillo no sirve de nada.
---@param data table
function Calls.OnIncoming(data)
    --[[ Una llamada no pisa a otra que ya esta en marcha.

         El servidor ya no deja que pase, pero si llegara igual (un aviso de
         emergencia que salio justo antes de descolgar la otra), sobrescribir
         `Calls.current` dejaba la llamada buena sin estado en el cliente: sin
         tono que cortar, sin animacion y sin forma de colgarla. ]]
    if Calls.current and Calls.current.state == 'active' and Calls.current.id ~= data.id then
        return
    end

    --[[ Se corta lo que hubiera sonando antes de nada.

         Una muestra de los ajustes por debajo del tono es exactamente lo que se
         reportaba. Y `StopRingtone` deja el estado limpio: si una llamada
         anterior se fue por un camino raro, `ringing` se queda en true y el
         tono de esta no llega a sonar, que era la otra mitad del problema. ]]
    Calls.StopPreview()
    StopRingtone()

    Calls.current = {
        id = data.id,
        state = 'ringing',
        outgoing = false,
        number = data.number,
        name = data.name,
        isVideo = data.isVideo,
    }

    StartRingtone()

    --[[ Y NO se abre el telefono.

         Antes se abria entero, de golpe, en mitad de lo que estuvieras
         haciendo: conduciendo, apuntando, hablando con alguien. Un telefono
         guardado que suena no se saca solo del bolsillo.

         Lo que se hace es asomarlo por abajo con quien llama —lo dibuja
         `AvisosFuera`, que es lo mismo que ya se hacia con los avisos— y quien
         quiera cogerla lo abre. ]]
    Phone.Wake()
end

--- Llamada saliente aceptada por el otro lado.
---@param data table
function Calls.OnAccepted(data)
    StopRingtone()

    --[[ Solo si es la llamada que hay. El aviso de "ha cogido" puede llegar
         cuando aqui ya no queda llamada: si se muere justo cuando el otro
         descuelga, Phone.Drop la cierra en el cliente y el aviso que ya venia
         por la red llega despues. Ponia la postura de hablar con el telefono
         guardado y sin llamada que la quitara nunca. ]]
    if not Calls.current or Calls.current.id ~= data.id then return end

    Calls.current.state = 'active'
    Calls.current.answeredAt = data.answeredAt
    Calls.AplicarVolumen()
    Phone.PlayAnimation(true)
end

---@param data table
function Calls.OnEnded(data)
    if Calls.current and data.id and Calls.current.id ~= data.id then return end

    -- Solo suena si habia llamada: si no, colgaria al recibir un aviso suelto.
    if Calls.current then PlayHangup() end

    StopRingtone()
    Calls.current = nil
    Calls.SetVideo(false)
    Calls.camaraPedida = false

    --[[ Si se colgo estando silenciado, se deshace: si no, el jugador se queda
         mudo sin saber por que.

         Aqui habia ademas un `clearProximityOverride` de pma-voice. El telefono
         nunca cambia el alcance de la voz, asi que no tenia nada que deshacer,
         y lo que hacia era pisar el de otro recurso: colgar con el megafono de
         la policia puesto lo apagaba. ]]
    Calls.Silenciar(false)

    if Phone.open then
        Phone.PlayAnimation(false)
    else
        --[[ Con el telefono cerrado, fuera tambien el objeto de la mano.

             Al cerrar el telefono en plena llamada el objeto se deja en la mano
             (Phone.Close), y aqui solo se paraba la animacion: cuando el otro
             colgaba, el movil se quedaba flotando en la mano del personaje hasta
             volver a abrir y cerrar el telefono. ]]
        Phone.SoltarDeLaMano()
    end
end

--- Marca el estado local al iniciar una llamada desde la interfaz. La UI ya ha
--- hablado con el servidor: esto solo guarda lo que hace falta en el cliente.
---@param data table
function Calls.OnStarted(data)
    Calls.current = {
        id = data.id,
        state = 'ringing',
        outgoing = true,
        number = data.number,
        name = data.name,
        isVideo = data.isVideo,
    }

    -- Mientras el otro no coja, se oye el tono de llamando.
    StartRingback()
    Phone.PlayAnimation(true)
end

-- ---------------------------------------------------------------------------
--  Videollamada
-- ---------------------------------------------------------------------------
--  El juego no puede transmitir la camara de otro jugador. Lo que si se puede
--  es enfocar al propio personaje con una camara delantera, que es lo que ve el
--  otro en una videollamada real: tu cara. Cada cliente se enfoca a si mismo y
--  la interfaz coloca ese render donde toca.

--[[ Encender la camara en una videollamada.

     Aqui habia una camara hecha a mano, pegada a la cabeza del personaje. Hacia
     casi lo mismo que la del modulo de la camara —que es la que usa la
     aplicacion de fotos— pero peor: sin el brazo levantado, sin poder darle la
     vuelta, sin acercar, y con un encuadre que no era el del visor. Eran dos
     camaras que mantener y una de las dos sobraba.

     Se abre en modo selfie porque en una videollamada lo que se enseña es la
     cara. Darle la vuelta desde la pantalla sigue funcionando: es la misma
     camara, con el mismo boton. ]]
---@param enabled boolean
function Calls.SetVideo(enabled)
    --- Lo que se ha pedido, para volver a ponerla si se cierra el telefono.
    Calls.camaraPedida = enabled == true and Calls.current ~= nil

    if not enabled then
        Camera.Close('call')
        return
    end

    if Camera.active then return end
    Camera.Open(true, 'call')
end

-- ---------------------------------------------------------------------------
--  Acciones locales de la interfaz
-- ---------------------------------------------------------------------------

Nui.On('callStarted', function(params)
    Calls.OnStarted(params)
    return true
end)

Nui.On('callAnswered', function(params)
    StopRingtone()
    Calls.AplicarVolumen()
    Calls.current = Calls.current or {}
    Calls.current.id = params.id or Calls.current.id
    Calls.current.state = 'active'
    Phone.PlayAnimation(true)
    return true
end)

Nui.On('callEnded', function()
    Calls.OnEnded({})
    return true
end)

Nui.On('setCallVideo', function(params)
    Calls.SetVideo(params.enabled == true)
    return true
end)

--[[ Altavoz, como en sd-phone: solo se le dice al servidor, que mete en el
     canal de la llamada a los que esten a menos de SpeakerRadius y los saca al
     alejarse. Ver «El altavoz» en server/api/videocall.lua. ]]
Nui.On("setSpeaker", function(params)
    lib.callback.await("origen_phone:rpc", false, "calls:setSpeaker", {
        enabled = params.enabled == true,
    })
    return true
end)

--[[ Silenciar el microfono.

     Destino de voz 0: el que no lleva ningun canal, asi que no sale nada ni
     hacia la llamada ni hacia los de al lado. Al quitarlo, el destino 1, que
     es el de pma-voice (shared.lua). pma-voice solo lo pone al conectarse
     (client/events.lua): no lo pisa mientras dura la llamada.

     Solo eso. Antes se tocaba tambien MumbleSetAudioInputDistance (0 al
     silenciar, 9999 al quitar): pma-voice nunca la toca, asi que ese «9999»
     no devolvia nada a como estaba, dejaba un alcance de entrada que no era
     el de antes. Y NetworkSetVoiceActive(false), mas antes, se lo pisaban
     otros recursos. ]]
local silenciado = false

--- Para el diagnostico (ogphone_voz).
---@return boolean
function Calls.EstaSilenciado()
    return silenciado
end

---@param on boolean
function Calls.Silenciar(on)
    on = on == true
    if on == silenciado then return end
    silenciado = on

    MumbleSetVoiceTarget(on and 0 or 1)
end

Nui.On("setMuted", function(params)
    Calls.Silenciar(params.enabled == true)
    return true
end)

--- Al reiniciar el recurso nadie se queda mudo.
AddEventHandler("onResourceStop", function(name)
    if name ~= GetCurrentResourceName() then return end
    Calls.Silenciar(false)
    --- El "llamando" es un sonido del juego con id propio: parar el recurso
    --- no lo calla, se quedaba dando vueltas hasta reconectar (24/09).
    pcall(StopRingtone)
end)

--[[ Un tono sin llamada que lo justifique se corta (24/09).

     El tono se para al coger, colgar o caducar la llamada, siempre por un aviso
     del servidor. Si ese aviso no llega (el jugador sin red un instante, la
     pagina recargada, un camino raro al soltar el telefono), `ringing` se queda
     en true y el tono en bucle para siempre. Sin llamada sonando no hay tono. ]]
CreateThread(function()
    while true do
        Wait(3000)
        if ringing and not (Calls.current and Calls.current.state == 'ringing') then
            StopRingtone()
        end
    end
end)

--[[ Y si alguien se queda silenciado SIN llamada, se le suelta.

     Silenciar corta el microfono entero, asi que quedarse asi es quedarse mudo
     para todo el servidor sin saber por que. Se deshace al colgar, pero si una
     llamada se cierra por un camino raro —el telefono se pierde, el otro lado
     se cae, un aviso que no llega— no habria quien lo deshiciera. Mirarlo cada
     cinco segundos no cuesta nada y cierra esa puerta. ]]
CreateThread(function()
    while true do
        Wait(5000)
        --- Sin llamada EN CURSO no hay nada que silenciar: ni sin llamada, ni
        --- con una que se ha quedado sonando o a medias.
        local enCurso = Calls.current and Calls.current.state == 'active'
        if silenciado and not enCurso then Calls.Silenciar(false) end
    end
end)

--[[ EL VOLUMEN DE LLAMADA, EL DE CADA UNO.

     pma-voice tiene un volumen de llamada por cliente y hasta ahora era el del
     cfg para todo el mundo. Se guarda en los ajustes del telefono y se le pasa
     a pma-voice: al arrancar, cada vez que se toca el deslizador y al empezar
     una llamada (si pma-voice se ha reiniciado por el camino, se le habra
     olvidado).

     Solo toca el volumen de LLAMADA: el de la radio y el de proximidad son
     suyos y no se tocan desde aqui. ]]
---@param volumen number|nil
function Calls.AplicarVolumen(volumen)
    volumen = tonumber(volumen)
    if not volumen then
        local ajustes = Phone.settings and Phone.settings.sound
        volumen = ajustes and tonumber(ajustes.callVolume) or nil
    end

    if not volumen then return end
    --- Nunca 0: con 0 pma-voice pone el volumen del otro a cero y ese jugador
    --- no oye a nadie en ninguna llamada, «segun quien» (18/09).
    if volumen < 5 then volumen = 5 elseif volumen > 100 then volumen = 100 end

    if GetResourceState('pma-voice') ~= 'started' then return end
    pcall(function() exports['pma-voice']:setCallVolume(volumen) end)
end

Nui.On('setCallVolume', function(params)
    Calls.AplicarVolumen(params.volume)
    return true
end)

--[[ Contestar y colgar con una tecla, con el telefono guardado o sacado.

     La tecla solo avisa a la interfaz, que es quien sabe en que punto esta la
     llamada y quien ya tiene escrito como cogerla, rechazarla o colgarla (con
     sus comprobaciones). Asi no hay dos caminos distintos para lo mismo. ]]
RegisterCommand('ogphone_contestar', function()
    if not Calls.current then return end
    -- Tirado en el suelo no se coge; colgar si, que no le da nada a nadie.
    if Phone.Abatido and Phone.Abatido() then return end
    Nui.Send('teclaLlamada', { accion = 'contestar' })
end, false)

RegisterCommand('ogphone_colgar', function()
    if not Calls.current then return end
    Nui.Send('teclaLlamada', { accion = 'colgar' })
end, false)

RegisterKeyMapping('ogphone_contestar', 'Teléfono: coger la llamada', 'keyboard', Config.Calls.KeyAnswer or 'RETURN')
RegisterKeyMapping('ogphone_colgar', 'Teléfono: rechazar o colgar la llamada', 'keyboard', Config.Calls.KeyHangup or 'BACK')

Nui.On('previewSound', function(params)
    Calls.PreviewSound(params.kind or 'ringtone', params.id)
    return true
end)

-- ---------------------------------------------------------------------------
--  La imagen que se manda al otro lado
-- ---------------------------------------------------------------------------

--[[ La interfaz saca el fotograma y el cliente solo lo lleva.

     Va por evento suelto y no por el puente de RPC porque no hay nada que
     contestar: si un fotograma se pierde, el siguiente llega en un cuarto de
     segundo y nadie lo nota. Un RPC ademas dejaria a la interfaz esperando
     una respuesta cuatro veces por segundo. ]]
--[[ A que ritmo se sueltan los fotogramas, en bytes por segundo.

     ESTABA EN 768 KB/s Y NO FRENABA NADA. Cada TriggerLatentServerEvent abre su
     propio envio a ese ritmo sin esperar al anterior, asi que veinte fotogramas
     por segundo eran veinte envios a la vez por la misma conexion que usa el
     juego. Con una imagen con detalle se pasaba de 1 MB/s de subida, la
     conexion con el servidor se atragantaba y FiveM echaba al jugador por
     timeout en mitad de la videollamada (15/09).

     Ahora hay dos frenos: la interfaz no gasta mas de `KBPorSegundo`, y aqui se
     lleva la cuenta de lo que aun esta saliendo. ]]
local RITMO_VIDEO = 256 * 1024

--[[ Cuanto se deja acumular sin salir, en milisegundos.

     `colaHasta` es el momento en que, a `RITMO_VIDEO`, habra terminado de salir
     todo lo que ya se ha soltado. Si un fotograma nuevo tuviera que esperar mas
     de esto, se tira: uno viejo no le sirve a nadie, y amontonarlos es lo que
     ahoga la conexion. ]]
local COLA_MAXIMA_MS = 600
local MAX_FOTOGRAMA = 128 * 1024
local colaHasta = 0

Nui.On('videoFrame', function(params)
    local data = params.data
    if type(data) ~= "string" or #data > MAX_FOTOGRAMA then return { ok = false } end

    local ahora = GetGameTimer()
    if colaHasta - ahora > COLA_MAXIMA_MS then return { ok = false, atasco = true } end

    colaHasta = math.max(colaHasta, ahora) + math.ceil(#data * 1000 / RITMO_VIDEO)

    --- Latente y no normal: ver el comentario de RITMO_VIDEO.
    TriggerLatentServerEvent('origen_phone:sv:videoFrame', RITMO_VIDEO, data)
    return { ok = true }
end)

--[[ Y el de un directo de la red social.

     Va por su propio camino y no por el de la videollamada aunque el fotograma
     sea igual: al otro lado son cosas distintas —una llamada tiene dos lados y
     un directo tiene publico— y mezclarlas obligaria a mandar de cual de las dos
     viene en cada fotograma. ]]
--[[ Latente y con cola, igual que la videollamada. Iba con TriggerServerEvent
     normal: un evento fiable de hasta 96 KB varias veces por segundo, que es lo
     que llena la conexion con el servidor hasta que echa al jugador. ]]
local RITMO_DIRECTO = 128 * 1024
local colaDirecto = 0

Nui.On('liveFrame', function(params)
    local data = params.data
    if type(data) ~= "string" or #data > 96 * 1024 then return { ok = false } end

    local ahora = GetGameTimer()
    if colaDirecto - ahora > 1000 then return { ok = false, atasco = true } end

    colaDirecto = math.max(colaDirecto, ahora) + math.ceil(#data * 1000 / RITMO_DIRECTO)

    TriggerLatentServerEvent('origen_phone:sv:liveFrame', RITMO_DIRECTO, data)
    return { ok = true }
end)

--[[ La portada del directo: la miniatura que sale en la lista.

     Va aparte de los fotogramas porque tiene que llegar tambien cuando el video
     va por el camino directo y por el servidor no pasa ninguno. ]]
Nui.On('liveCover', function(params)
    if type(params.data) ~= "string" then return { ok = false } end

    if #params.data > 24 * 1024 then return { ok = false } end

    TriggerLatentServerEvent('origen_phone:sv:liveCover', 64 * 1024, params.data)
    return { ok = true }
end)

--[[ La presentacion de WebRTC.

     Solo lleva y trae: ofertas, respuestas y rutas posibles. El servidor mira
     que los dos telefonos tengan algo que ver antes de reenviar nada; aqui no
     hay nada que comprobar porque lo que viaja es texto que solo entiende el
     otro lado. ]]
Nui.On('rtcSignal', function(params)
    if type(params.to) ~= 'string' or type(params.kind) ~= 'string' then
        return { ok = false }
    end

    TriggerServerEvent('origen_phone:sv:rtcSignal', params.to, params.kind, params.payload, params.live)
    return { ok = true }
end)


--[[ El rastro de la videollamada.

     `ogphone_video_traza 1` enciende y `0` apaga. Escribe una linea por
     segundo en la consola (F8) con todo el camino de la imagen: si el visor
     pinta, si se manda, cuanto ocupa y si llega lo del otro.

     Esta puesto para poder mandar una captura y que se vea donde se corta, sin
     tener que ir probando. ]]
RegisterCommand('ogphone_video_traza', function(_, args)
    local on = args[1] ~= '0'

    Nui.Send('videoTraza', { on = on })
    print(('^5[origen_phone]^7 rastro de video: %s'):format(on and 'encendido' or 'apagado'))
end, false)

--[[ El rastro de un cliente, camino del servidor.

     Cada cliente manda su linea una vez por segundo mientras dura la
     videollamada, y el servidor las junta. Sin esto habria que pedirle una
     captura de consola a cada uno y coincidir en el momento, que es justo lo
     que ha hecho imposible ver los dos lados a la vez. ]]
Nui.On('videoTraza', function(params)
    if type(params.linea) ~= 'string' then return true end

    TriggerServerEvent('origen_phone:sv:videoTraza', params.linea)
    return true
end)
