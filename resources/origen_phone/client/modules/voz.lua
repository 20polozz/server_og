--[[ El modulador de voz.

     Cambiar como suena tu voz para el otro lado de la llamada.

     COMO FUNCIONA, QUE NO ES OBVIO

     No se toca el microfono. Lo que se hace es que **el que escucha** pase esa
     voz por un filtro antes de sonarla: `MumbleSetSubmixForServerId` mete la voz
     de un jugador por una mesa de efectos, y esa mesa es de quien oye.

     O sea que para que a ti te salga la voz cambiada, no basta con que tu lo
     enciendas: hay que decirselo a los que te oyen para que la pasen por el
     filtro. De ahi que esto vaya por el servidor y no se quede en tu cliente.

     Y de ahi tambien lo que no se puede hacer: un jugador con el recurso tocado
     podria no aplicar el filtro y oirte con tu voz. Para el rol vale —el que
     hace trampa se estropea su propia partida— pero conviene saberlo antes de
     usarlo para algo donde importe de verdad.

     PONERLO UNA VEZ NO SIRVE DE NADA

     Esto es lo que lo tenia roto. pma-voice tambien reparte mesas: le pone la
     suya de "call" a cada uno al entrar en la llamada, y cuando alguien deja de
     hablar `restoreDefaultSubmix` le devuelve la que diga su statebag —o
     ninguna—. Cualquiera de las dos **pisa la nuestra**, asi que el filtro
     duraba hasta la siguiente vez que el otro abria la boca. Que es, justo, la
     unica vez que se le podia oir el filtro.

     Por eso se vuelve a poner cada cuarto de segundo mientras dure. No es un
     apaño: es lo mismo que hace lb-phone —`voiceTargetsInterval`, 250 ms,
     llamando a `MumbleSetSubmixForServerId` para cada uno de la llamada— y lo
     hace por esta misma razon.

     LOS FILTROS

     Son el efecto de radio del juego. Lo que de verdad cambia una voz ahi no
     son los cortes de frecuencia —eso solo la hace sonar por un aparato peor—
     sino **la modulacion en anillo**: multiplicar la voz por un tono, lo que
     saca frecuencias que no estaban y da el punto metalico.

     Y el detalle que lo tenia mudo: `rm_mix` dice CUANTA modulacion se mete y
     `rm_mod_freq` a que frecuencia. Con `rm_mod_freq` a cero —que es como
     viene— modular no hace nada por mucho que subas `rm_mix`. Se ponian las
     mezclas y ninguna frecuencia, asi que los cuatro filtros acababan siendo el
     mismo pasa-banda sobre una llamada que ya viene recortada: indistinguibles.
]]

Voz = {}

--- Las mesas de efectos, una por filtro. Se hacen al arrancar.
local mesas = {}

--- Quien esta modulado ahora mismo: { [serverId] = filtro }.
local puestos = {}

--- Si el reloj que las vuelve a poner esta en marcha.
local repitiendo = false

--[[ Los filtros.

     `low`/`hi` son los cortes de entrada y `oLow`/`oHi` los de salida, en
     hercios. `fudge` es la distorsion. Y las dos que hacen el trabajo:
     `rmFreq`, el tono con el que se modula, y `rmMix`, cuanto se mezcla. Sin
     `rmFreq` la voz no cambia: solo suena por un altavoz mas malo. ]]
local FILTROS = {
    --- Grave: modulacion baja, que gruñe, y sin agudos.
    grave = { low = 60.0,  hi = 1800.0, oLow = 60.0,  oHi = 1800.0, fudge = 0.35, rmFreq = 60.0,  rmMix = 0.35 },
    --- Aguda: se le quita el cuerpo y se modula alto.
    aguda = { low = 700.0, hi = 8000.0, oLow = 900.0, oHi = 9000.0, fudge = 0.15, rmFreq = 550.0, rmMix = 0.30 },
    --- Robot: modulacion a tope, que es lo que hace el metal.
    robot = { low = 300.0, hi = 3400.0, oLow = 300.0, oHi = 3400.0, fudge = 0.60, rmFreq = 280.0, rmMix = 0.75 },
    --- Radio: emisora barata. Banda estrecha y mucha distorsion.
    radio = { low = 420.0, hi = 3600.0, oLow = 420.0, oHi = 3600.0, fudge = 0.50, rmFreq = 100.0, rmMix = 0.06 },
}

--- Por que no se pudo hacer alguna mesa, para poder mirarlo desde fuera.
local fallo = nil

--[[ Se hacen todas al arrancar, no segun hagan falta.

     El juego tiene un numero corto de mesas y `CreateAudioSubmix` devuelve -1
     cuando se acaban. Haciendolas aqui, si no caben se sabe al arrancar y queda
     escrito; haciendolas al vuelo, el filtro fallaba en mitad de una llamada
     sin que nadie se enterara. ]]
CreateThread(function()
    for nombre, f in pairs(FILTROS) do
        local id = CreateAudioSubmix('ogphone_voz_' .. nombre)

        if id == -1 then
            fallo = ('no quedan mesas de audio libres (fallo en "%s")'):format(nombre)
            break
        end

        SetAudioSubmixEffectRadioFx(id, 0)
        SetAudioSubmixEffectParamInt(id, 0, GetHashKey('default'), 1)

        SetAudioSubmixEffectParamFloat(id, 0, GetHashKey('freq_low'), f.low)
        SetAudioSubmixEffectParamFloat(id, 0, GetHashKey('freq_hi'), f.hi)
        SetAudioSubmixEffectParamFloat(id, 0, GetHashKey('o_freq_lo'), f.oLow)
        SetAudioSubmixEffectParamFloat(id, 0, GetHashKey('o_freq_hi'), f.oHi)
        SetAudioSubmixEffectParamFloat(id, 0, GetHashKey('fudge'), f.fudge)

        --- Las dos van juntas: la mezcla sin la frecuencia no hace nada.
        SetAudioSubmixEffectParamFloat(id, 0, GetHashKey('rm_mod_freq'), f.rmFreq)
        SetAudioSubmixEffectParamFloat(id, 0, GetHashKey('rm_mix'), f.rmMix)

        SetAudioSubmixOutputVolumes(id, 0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0)
        AddAudioSubmixOutput(id, 0)

        mesas[nombre] = id
    end
end)

--[[ El reloj que las mantiene puestas.

     Vive solo mientras haya alguien modulado. Es una llamada por persona cada
     cuarto de segundo: lo mismo que gasta lb-phone en cada llamada. ]]
local function Repetir()
    if repitiendo then return end
    repitiendo = true

    CreateThread(function()
        while next(puestos) do
            for serverId, nombre in pairs(puestos) do
                local mesa = mesas[nombre]
                if mesa then MumbleSetSubmixForServerId(serverId, mesa) end
            end

            Wait(250)
        end

        repitiendo = false
    end)
end

--[[ Devuelve una voz a como la tenia pma-voice.

     Si la llamada sigue, no vale poner -1 a secas: eso le quitaria tambien el
     efecto de llamada de pma-voice y esa voz se quedaria sonando a proximidad
     el resto de la llamada. `toggleVoice` es su propio export y lo deja como
     estaba.

     Si la llamada se ha acabado, en cambio, -1 y nada mas: pedirle que le ponga
     el efecto de llamada a alguien que ya no esta en ninguna le dejaria el
     volumen forzado, y encima pma esta deshaciendo sus propias cosas en ese
     mismo instante. ]]
---@param serverId number
---@param sigueLaLlamada boolean
local function Devolver(serverId, sigueLaLlamada)
    if sigueLaLlamada then
        local ok = pcall(function()
            exports['pma-voice']:toggleVoice(serverId, true, 'call')
        end)

        if ok then return end
    end

    MumbleSetSubmixForServerId(serverId, -1)
end

--[[ Aplica (o quita) el filtro a la voz de alguien.

     Se hace en el cliente de quien ESCUCHA. ]]
---@param serverId number
---@param filtro string|nil
---@param sigue boolean|nil  si esa persona sigue en la llamada al quitarle el filtro
function Voz.Aplicar(serverId, filtro, sigue)
    if not serverId or serverId == GetPlayerServerId(PlayerId()) then return end

    if not filtro then
        if puestos[serverId] then
            puestos[serverId] = nil
            --[[ Solo se le devuelve el efecto de llamada de pma-voice si SIGUE
                 dentro. A un invitado que se acababa de ir se le llamaba igual
                 toggleVoice(…, 'call'): volumen fijo y efecto de llamada para
                 alguien que ya no esta en ningun canal, y nadie lo deshacia:
                 se le oia desde cualquier punto del mapa (18/09). ]]
            Devolver(serverId, sigue == true)
        end

        return
    end

    local mesa = mesas[filtro]
    if not mesa then return end

    puestos[serverId] = filtro
    MumbleSetSubmixForServerId(serverId, mesa)

    Repetir()
end

--- Quita todos. Al colgar, y al soltar el recurso.
function Voz.Limpiar()
    for serverId in pairs(puestos) do
        puestos[serverId] = nil
        Devolver(serverId, false)
    end

    puestos = {}
end

RegisterNetEvent('origen_phone:cl:voice', function(serverId, filtro, sigue)
    Voz.Aplicar(serverId, filtro, sigue)
end)

RegisterNetEvent('origen_phone:cl:voiceClear', function()
    Voz.Limpiar()
end)

--- El interruptor, desde la pantalla de la llamada.
Nui.On('setVoiceFilter', function(params)
    local filtro = params.filter

    --- Solo los de la lista: un nombre cualquiera no crea ninguna mesa.
    if filtro ~= nil and FILTROS[filtro] == nil then return { ok = false } end

    TriggerServerEvent('origen_phone:sv:voice', filtro)
    return { ok = true }
end)

--[[ Que esta pasando de verdad con el modulador.

     Se pide desde el servidor con `ogphone_voz` y se contesta, para no tener
     que estar delante de la consola de cada uno. ]]
RegisterNetEvent('origen_phone:cl:vozEstado', function()
    local hechas, faltan = {}, {}

    for nombre in pairs(FILTROS) do
        if mesas[nombre] then
            hechas[#hechas + 1] = nombre
        else
            faltan[#faltan + 1] = nombre
        end
    end

    local oyendo = {}
    for serverId, nombre in pairs(puestos) do
        oyendo[#oyendo + 1] = ('%s->%s'):format(serverId, nombre)
    end

    --- Y como esta la voz de las llamadas en este cliente (18/09).
    local llamada = Calls and Calls.current

    TriggerServerEvent('origen_phone:sv:vozEstado', {
        --- De paso, como va la intercepcion de los avisos del servidor.
        avisos = Servidor and Servidor.Cuenta and Servidor.Cuenta() or nil,
        mudo = Calls and Calls.EstaSilenciado and Calls.EstaSilenciado() or false,
        mumble = MumbleIsConnected(),
        canal = LocalPlayer.state.callChannel,
        canalPropio = LocalPlayer.state.assignedChannel,
        enLlamada = llamada and (llamada.state .. ' #' .. tostring(llamada.id)) or 'ninguna',
        mesas = table.concat(hechas, ','),
        sinMesa = table.concat(faltan, ','),
        oyendo = #oyendo > 0 and table.concat(oyendo, ' ') or 'a nadie con filtro',
        repitiendo = repitiendo,
        fallo = fallo,
        submixOn = GetConvarInt('voice_enableSubmix', 1),
    })
end)

--[[ ── Lo que se habla EN el juego ───────────────────────────────────────────

     La grabadora y la grabacion de llamadas cogen el microfono desde la
     interfaz, y ese microfono lo oye todo: tambien lo que se dice sin pulsar
     para hablar (OOC, Discord). Mientras graban, la interfaz pide que se le
     diga cuando el jugador esta transmitiendo voz en el juego, y deja pasar el
     microfono solo entonces. Ver source-ui/src/utils/vozIC.ts.

     "Transmitiendo" es cualquiera de estas:
       · NetworkIsPlayerTalking / MumbleIsPlayerTalking: la voz sale de verdad
         (pulsar para hablar, o deteccion de voz para quien la use);
       · el control 249 (pulsar para hablar) apretado: responde al instante,
         antes de que Mumble detecte la voz. Las radios lo fuerzan mientras se
         habla por ellas, asi que hablar por radio tambien cuenta.

     Al soltar se espera un poco antes de cortar, o se comeria el final de
     cada frase. ]]
local vigilandoIC = false
--- Cada encendido lleva su numero: un hilo viejo que siga vivo se para solo.
local vueltaIC = 0
local hablandoIC = false

--- Cuanto se sigue grabando despues de dejar de transmitir, en ms.
local COLA_MS = 400

local function TransmitiendoEnJuego()
    local yo = PlayerId()
    if NetworkIsPlayerTalking(yo) then return true end

    local mumble = MumbleIsPlayerTalking(yo)
    if mumble == true or mumble == 1 then return true end

    return IsControlPressed(0, 249) or IsDisabledControlPressed(0, 249)
end

Nui.On('voz:vigilarIC', function(params)
    local encender = params and params.on == true

    if not encender then
        vigilandoIC = false
        return true
    end

    if vigilandoIC then
        --- Ya vigilando: se repite el estado para quien acaba de engancharse.
        Nui.Send('vozIC', { hablando = hablandoIC })
        return true
    end

    vigilandoIC = true
    vueltaIC = vueltaIC + 1
    local mia = vueltaIC
    hablandoIC = false
    Nui.Send('vozIC', { hablando = false })

    CreateThread(function()
        local hasta = 0

        while vigilandoIC and mia == vueltaIC do
            local ahora = GetGameTimer()
            if TransmitiendoEnJuego() then hasta = ahora + COLA_MS end

            local hablando = ahora < hasta
            if hablando ~= hablandoIC then
                hablandoIC = hablando
                Nui.Send('vozIC', { hablando = hablando })
            end

            Wait(50)
        end
    end)

    return true
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    vigilandoIC = false
    Voz.Limpiar()
end)
