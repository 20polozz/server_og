--[[ EL FOCO DEL RATON Y LAS TECLAS, EN UN SOLO SITIO.

     Hasta el 18/09 el foco lo tocaban cinco modulos (telefono, camara, panel
     de admin, tienda y el hilo de las teclas), cada uno con su idea de en que
     estado estaba el resto. Auditado entero ese dia: el raton se quedaba en
     pantalla porque el foco se cogia antes de que existiera la pantalla, porque
     «escribiendo» se quedaba pegado si la pagina no avisaba, porque el panel
     de admin y la tienda se pisaban el foco, y porque una pagina rota
     contestaba que «se veia algo».

     Ahora nadie llama a SetNuiFocus ni a SetNuiFocusKeepInput mas que este
     fichero. Los demas solo cambian su casilla del ESTADO y llaman a
     Foco.Aplicar(), que calcula que toca a partir de todo el estado y lo pone.
     Es idempotente: se puede llamar cien veces y solo toca el native cuando lo
     que toca ha cambiado.

     LO QUE SALE DEL ESTADO

       foco    = telefono o admin o tienda
       cursor  = foco, salvo con la camara apuntando (el raton es del juego)
       teclas  = telefono sin panel encima, sin campo de texto y sin OTRO
                 recurso con el foco (si el chat o el inventario estan encima,
                 las teclas son suyas)

     EL CAMPO DE TEXTO CADUCA. «Escribiendo» no es un si/no que la pagina
     enciende y apaga: es una fecha. La pagina lo renueva cada segundo mientras
     haya un campo enfocado; si deja de renovarlo —porque se cerro el campo sin
     avisar, o porque la pagina ha muerto— a los 2,5 s las teclas vuelven solas.
     Antes un `setTyping(false)` perdido dejaba al jugador sin teclas, sin
     camara y sin voz hasta reconectar.

     EL ORDEN. FiveM lleva un contador, no un si/no (ver ORDEN_AL_SOLTAR en
     origen_map/shared/foco.lua): al soltar, las teclas se apagan ANTES que el
     foco. El vigilante compartido ya lo reordena, pero aqui tambien se hace
     bien para no depender de el. ]]

Foco = {
    telefono = false,
    apuntando = false,
    admin = false,
    tienda = false,
    carga = false,
    --- Hasta cuando hay un campo de texto enfocado (GetGameTimer).
    escribiendoHasta = 0,
}

--- Cuanto vive un aviso de «escribiendo» sin que la pagina lo renueve.
local ESCRIBIENDO_MS = 2500

--- Lo ultimo que se le pidio a FiveM, para no repetirlo.
local ultimo = { foco = false, cursor = false, teclas = false }

--- Como cerrar cada panel, para que abrir uno cierre el otro.
local cerradores = {}

---@return boolean
function Foco.Escribiendo()
    return GetGameTimer() < Foco.escribiendoHasta
end

--- La pagina dice si hay un campo de texto enfocado. Con `true` se renueva la
--- fecha; con `false` se corta ya.
---@param si boolean
function Foco.Escribir(si)
    Foco.escribiendoHasta = si and (GetGameTimer() + ESCRIBIENDO_MS) or 0
    Foco.Aplicar()
end

local function Deseado()
    local panel = Foco.admin or Foco.tienda or Foco.carga
    local foco = Foco.telefono or panel
    local cursor = foco and not (Foco.telefono and Foco.apuntando and not panel)

    local otro = false
    if OrigenFoco and OrigenFoco.OtroConFoco then otro = OrigenFoco.OtroConFoco() == true end

    local teclas = Foco.telefono and not panel and not Foco.Escribiendo() and not otro

    return foco, cursor, teclas
end

--- Pone en FiveM lo que dice el estado. Solo toca lo que ha cambiado.
---@param forzar boolean|nil  volver a ponerlo todo aunque no haya cambiado
--[[ REENGANCHAR EL RATON AL JUEGO TRAS CERRAR (27/09).

     Jugadores con el cursor clavado y la camara quieta justo despues de
     cerrar el movil, y `focoestado` diciendo que NADIE tiene el foco: FiveM
     da el raton por devuelto pero el juego no lo recibe. Pasa con el movil y
     no con otras pantallas porque es el que se cierra soltando el teclado que
     dejaba pasar al juego (KeepInput) con el raton de Windows por medio
     (citizenfx/fivem#3887).

     Un pulso de foco equilibrado —coger sin cursor y soltar— hace que FiveM
     vuelva a quitarle y devolverle el raton al juego, y en esa vuelta lo
     engancha de nuevo. El contador de FiveM queda igual (+1 y -1). Por el
     native directo: no es una pantalla, no hay que avisar a nadie ni que el
     vigilante lo cuente. Solo si nadie tiene el foco, que si lo tiene otro
     el raton es suyo. Dos veces: al momento y un poco despues, por si el
     cierre de la pagina llega tarde. ]]
local SET_NUI_FOCUS = 0x5B98AE30

local function Reenganchar()
    for _, espera in ipairs({ 150, 900 }) do
        CreateThread(function()
            Wait(espera)
            if Foco.telefono or Foco.admin or Foco.tienda or Foco.carga then return end
            if IsNuiFocused() then return end
            if OrigenFoco and OrigenFoco.OtroConFoco and OrigenFoco.OtroConFoco() then return end

            --[[ Si se esta sosteniendo el acelerador, este tiron espera.

                 Coger el foco --aunque sea un cuadro y para soltarlo enseguida--
                 vuelve a dejar al juego sin la tecla pulsada Y hace que la tecla
                 fisica conteste que esta suelta. Medido el 07/10: el sosten se
                 armaba bien al cerrar y este apaño lo tumbaba 150 ms despues, asi
                 que el coche frenaba igual.

                 Se espera a que se suelte el volante; con el tope de 30 s de
                 Volante, esto no se queda esperando para siempre. ]]
            local hasta = GetGameTimer() + 31000
            while Foco.SosteniendoVolante() and GetGameTimer() < hasta do Wait(100) end

            -- Y se vuelve a mirar todo: en esa espera puede haber cambiado.
            if Foco.telefono or Foco.admin or Foco.tienda or Foco.carga then return end
            if IsNuiFocused() then return end

            --[[ Este tiron tambien es un cambio de foco, y tambien deja al juego
                 sin las teclas pulsadas: quien cerraba el telefono y echaba a
                 andar en el mismo segundo se quedaba parado a los 150 o 900 ms.
                 Se apunta lo que se esta pulsando justo antes, igual que al
                 abrir (aqui el juego dice la verdad: nadie tiene el foco). ]]
            Foco.RecordarVolante(false, true)

            Citizen.InvokeNative(SET_NUI_FOCUS, true, false)
            Wait(0)
            Citizen.InvokeNative(SET_NUI_FOCUS, false, false)
        end)
    end
end

--[[ QUE NO TE PARES AL ABRIR O CERRAR EL TELEFONO (coche y a pie).

     EL PROBLEMA, medido en partida el 07/10 con una sonda:

     Cambiar el foco de la pantalla (`SetNuiFocus`, al abrir y al cerrar) hace
     que el juego PIERDA las teclas que ya estaban pulsadas. El juego registra
     el «se ha pulsado», no el «esta pulsada», y ese aviso ya no vuelve a
     llegar: con la W apretada, el coche deja de acelerar --o el personaje de
     andar-- hasta que la sueltas y vuelves a darle.

     LA SALIDA: justo antes de cambiar el foco se apunta que teclas de moverse
     estaban pulsadas, y se reponen a mano (`SetControlNormal`) hasta que se
     sueltan.

     COMO SE SABE QUE SE HAN SOLTADO. Dos avisos, el primero que llegue:

       - la PAGINA, mientras el telefono esta delante: es quien tiene el
         teclado (`teclaVolante`, desde bridge.ts);
       - el TECLADO DE VERDAD (`RegisterRawKeymap`): avisa cuando la tecla
         sube, con el telefono cerrado.

     LO QUE NO SE HACE (08/10): preguntar `IsRawKeyDown` para ver si sigue
     apretada. Tras un cambio de foco contesta que NO, y solo vuelve a decir
     que si cuando Windows repite la tecla... cosa que solo hace con la ULTIMA
     pulsada. En cuanto tocas la A o la D para girar, la W deja de repetirse,
     `IsRawKeyDown` dice «suelta» y se dejaba de sostener: probando solo con la
     W iba bien y conduciendo de verdad el coche se paraba igual.

     Tampoco se puede preguntar `IsControlPressed` de un control que se esta
     reponiendo: la propia reposicion hace que conteste `true`.

     POR SI SE ESCAPA UN AVISO (soltar justo en el cambio de foco): pulsar la
     tecla contraria la corta, bajarse o subirse la corta, y a los 30 s se
     corta pase lo que pase. Mas vale quedarse corto que dejar a alguien
     andando solo. ]]

--- Tecla de la pagina (`code`) -> tecla de moverse.
local TECLA_DE_CODIGO = {
    KeyW = 'W', ArrowUp = 'W', KeyS = 'S', ArrowDown = 'S',
    KeyA = 'A', KeyD = 'D', ShiftLeft = 'SHIFT',
}

--- Que control del juego es cada tecla, al volante y a pie.
local CONTROL = {
    coche = { W = 71, S = 72, A = 63, D = 64 },
    pie   = { W = 32, S = 33, A = 34, D = 35, SHIFT = 21 },
}

--- La contraria de cada una: pulsarla corta el sosten (frenar para al coche).
local CONTRARIA = { W = 'S', S = 'W', A = 'D', D = 'A' }

--- Las mismas teclas en codigo de Windows, para el aviso del teclado de verdad.
local VK = { W = 0x57, S = 0x53, A = 0x41, D = 0x44, SHIFT = 0xA0 }

local SEGURO_MS = 30000

--[[ Lo que hay que reponer ahora mismo: [tecla] = cuando deja de valer.

     Va declarada AQUI, antes de la primera funcion que la usa. Estaba mas abajo,
     y entonces `Foco.SosteniendoVolante` no veia la local sino una global que no
     existe: «bad argument #1 to 'next' (table expected, got nil)» en bucle. ]]
local reponiendo = {}
local vigilando = false

--- En que modo se armo el sosten ('coche' | 'pie'): si cambia, se suelta todo.
local modoSostenido = nil

--- Lo que la pagina dice que esta pulsado, mientras ella tiene el teclado.
local pulsadoEnLaPagina = {}

--[[ Teclas que `IsRawKeyDown` ha dicho que estan ABAJO desde el ultimo cambio
     de foco. Que diga «arriba» sin mas no vale (ver arriba, lo de la repeticion
     de Windows); pero si la ha visto abajo y luego arriba, eso si es soltarla.
     Es la red por si el aviso del teclado de verdad no llega. ]]
local vistaAbajo = {}

--[[ LA TREGUA TRAS UN CAMBIO DE FOCO (08/10).

     «A veces se para y a veces no»: justo al cambiar el foco el teclado de
     verdad da señales falsas --el juego suelta todas las teclas por dentro, y
     `IsRawKeyDown` puede decir «abajo» un cuadro y «arriba» al siguiente con la
     tecla apretada--. Si eso se toma por soltar, el sosten se cae nada mas
     armarse, y depende del cuadro en que caiga: de ahi lo de «a veces».

     Durante este rato tras cada cambio no se le hace caso al teclado de
     verdad. A la pagina si: ella no se equivoca. ]]
local TREGUA_MS = 500
local focoCambioEn = 0
local focoVisto = false

local function EnTregua()
    return (GetGameTimer() - focoCambioEn) < TREGUA_MS
end

--[[ El diario, para cuando falle: `focodiag` en la consola (F8) lo enseña.
     Las ultimas 60 cosas que han pasado con el sosten y por que. ]]
local diario = {}
local function Apuntar(texto)
    diario[#diario + 1] = ('%d  %s'):format(GetGameTimer(), texto)
    if #diario > 60 then table.remove(diario, 1) end
end

RegisterCommand('focodiag', function()
    print('--- origen_phone · sosten de teclas (ahora ' .. GetGameTimer() .. ') ---')
    for _, linea in ipairs(diario) do print(linea) end
    print('--- fin ---')
end, false)

--- ¿Se esta sosteniendo alguna tecla ahora mismo?
function Foco.SosteniendoVolante()
    return next(reponiendo) ~= nil
end

---@return string|nil  'coche' si conduce, 'pie' si va andando, nil si no toca
local function Modo()
    local ped = PlayerPedId()
    local coche = GetVehiclePedIsIn(ped, false)
    if coche ~= 0 then
        return GetPedInVehicleSeat(coche, -1) == ped and 'coche' or nil
    end
    if IsEntityDead(ped) or IsPedRagdoll(ped) then return nil end
    return 'pie'
end

local function Vigilar()
    if vigilando then return end
    vigilando = true

    CreateThread(function()
        while next(reponiendo) do
            Wait(0)

            local ahora = GetGameTimer()
            local modo = Modo()

            if modo ~= modoSostenido then
                Apuntar(('fin de todo: cambio de modo %s -> %s'):format(tostring(modoSostenido), tostring(modo)))
                for tecla in pairs(reponiendo) do reponiendo[tecla] = nil end
            else
                local conFoco = IsNuiFocused()
                if conFoco ~= focoVisto then
                    -- Un cambio que no ha pasado por aqui (otro recurso): tregua igual.
                    focoVisto = conFoco
                    focoCambioEn = ahora
                    vistaAbajo = {}
                end

                local leerTeclado = IsRawKeyDown and not conFoco and not EnTregua()

                for tecla, caduca in pairs(reponiendo) do
                    local control = CONTROL[modo][tecla]
                    local contraria = CONTRARIA[tecla] and CONTROL[modo][CONTRARIA[tecla]]
                    local suelta = false

                    if leerTeclado then
                        if IsRawKeyDown(VK[tecla]) then
                            vistaAbajo[tecla] = true
                        elseif vistaAbajo[tecla] then
                            suelta = true
                        end
                    end

                    if not control or ahora > caduca or suelta then
                        Apuntar(('fin %s: %s'):format(tecla, suelta and 'tecla fisica abajo->arriba' or (control and 'tope de 30 s' or 'sin control en este modo')))
                        reponiendo[tecla] = nil
                    elseif contraria and not EnTregua() and IsControlJustPressed(0, contraria) then
                        -- Frenar (o tirar hacia el otro lado) lo corta: esa pulsacion
                        -- es nueva y el juego si la ve.
                        Apuntar(('fin %s: pulsada la contraria (juego)'):format(tecla))
                        reponiendo[tecla] = nil
                    else
                        SetControlNormal(0, control, 1.0)
                    end
                end
            end
        end

        vigilando = false
    end)
end

--- Una tecla se ha soltado de verdad: lo diga la pagina o el teclado.
---@param quien string  'pagina' | 'teclado'
local function Soltada(tecla, quien)
    if quien == 'teclado' and EnTregua() then
        if reponiendo[tecla] then Apuntar(('%s: «soltada» del teclado en la tregua, no se le hace caso'):format(tecla)) end
        return
    end
    if reponiendo[tecla] then Apuntar(('fin %s: soltada (%s)'):format(tecla, quien)) end
    pulsadoEnLaPagina[tecla] = nil
    reponiendo[tecla] = nil
end

--- Una tecla se ha pulsado de nuevo: la contraria deja de sostenerse.
---@param quien string  'pagina' | 'teclado'
local function Pulsada(tecla, quien)
    if quien == 'teclado' and EnTregua() then return end
    local contraria = CONTRARIA[tecla]
    if contraria and reponiendo[contraria] then
        Apuntar(('fin %s: pulsada la contraria (%s)'):format(contraria, quien))
        reponiendo[contraria] = nil
    end
end

--[[ La pagina dice que una tecla de moverse se ha pulsado o soltado.

     Sobre todo importa el soltar: es el aviso que al juego no le llega. ]]
---@param code string   el `code` del teclado ('KeyW', 'KeyS'…)
---@param pulsada boolean
function Foco.TeclaVolante(code, pulsada)
    local tecla = TECLA_DE_CODIGO[code]
    if not tecla then return end

    if pulsada then
        pulsadoEnLaPagina[tecla] = true
        Pulsada(tecla, 'pagina')
    else
        Soltada(tecla, 'pagina')
    end
end

--[[ El teclado de verdad. Avisa de subir y bajar aunque el juego haya perdido
     la tecla; es lo que corta el sosten con el telefono ya cerrado. Si esta
     version del juego no lo trae, quedan la pagina y el tope de 30 s. ]]
if RegisterRawKeymap then
    for tecla, vk in pairs(VK) do
        pcall(RegisterRawKeymap, 'ogphone_sosten_' .. tecla,
            function() Pulsada(tecla, 'teclado') end,
            function() Soltada(tecla, 'teclado') end,
            vk, false)
    end
end

--[[ Apuntar que se esta pulsando, JUSTO ANTES de que cambie el foco.

     `alCerrar`: el telefono se cierra. Lo que se venia sosteniendo sigue (la
     pagina habria avisado si se hubiera soltado), lo que la pagina vio pulsar
     tambien, y ademas lo que el juego ve pulsado por su cuenta: con el
     telefono abierto las teclas le siguen llegando (KeepInput), asi que de las
     que NO se estan reponiendo dice la verdad.

     `teclasAlJuego`: si el juego estaba recibiendo teclas hasta ahora. Con un
     campo de texto enfocado no las recibe, y entonces no se le pregunta. ]]
---@param alCerrar boolean|nil
---@param teclasAlJuego boolean|nil
function Foco.RecordarVolante(alCerrar, teclasAlJuego)
    -- Cambia el foco: lo que dijo la tecla fisica hasta ahora deja de valer,
    -- y empieza la tregua.
    vistaAbajo = {}
    focoCambioEn = GetGameTimer()
    focoVisto = not alCerrar

    local modo = Modo()
    if not modo then
        for tecla in pairs(reponiendo) do reponiendo[tecla] = nil end
        return
    end

    local caduca = GetGameTimer() + SEGURO_MS
    local juegoVe = (not alCerrar) or teclasAlJuego

    for tecla, control in pairs(CONTROL[modo]) do
        local pulsada = reponiendo[tecla] ~= nil
            or (alCerrar and pulsadoEnLaPagina[tecla] == true)
            or (juegoVe and IsControlPressed(0, control))

        if pulsada then
            reponiendo[tecla] = caduca
            --[[ Y se da por pulsada tambien para la pagina: si la tecla venia
                 de antes de abrir, la pagina nunca vio su `keydown`, y al
                 cerrar no habria manera de saber que seguia apretada. ]]
            pulsadoEnLaPagina[tecla] = true
        end
    end

    -- Lo que no es de este modo (el SHIFT al volante) no se sostiene.
    for tecla in pairs(reponiendo) do
        if not CONTROL[modo][tecla] then reponiendo[tecla] = nil end
    end

    -- Con el telefono cerrado la pagina ya no cuenta nada: se empieza de cero.
    if alCerrar then pulsadoEnLaPagina = {} end

    modoSostenido = modo

    local lista = {}
    for tecla in pairs(reponiendo) do lista[#lista + 1] = tecla end
    Apuntar(('%s (%s, juego ve teclas: %s) -> sosteniendo [%s]'):format(
        alCerrar and 'CIERRA' or 'ABRE/tiron', modo, tostring(juegoVe and true or false), table.concat(lista, ' ')))

    if next(reponiendo) then Vigilar() end
end

function Foco.Aplicar(forzar)
    local foco, cursor, teclas = Deseado()

    --[[ Antes de tocar el foco, apuntar que se esta pisando: despues el juego
         ya no lo sabe. Al cerrar la verdad la tiene la pagina, que es quien ha
         tenido el teclado mientras tanto. ]]
    if ultimo.foco ~= foco then Foco.RecordarVolante(ultimo.foco and not foco, ultimo.teclas) end


    if not foco then
        if forzar or ultimo.foco or ultimo.teclas then
            --- Teclas antes que foco, siempre.
            SetNuiFocusKeepInput(false)
            SetNuiFocus(false, false)
            if ultimo.foco then Reenganchar() end
        end
    else
        if forzar or not ultimo.foco or ultimo.cursor ~= cursor then
            SetNuiFocus(true, cursor)
        end

        --[[ Las teclas DESPUES del foco, y no al reves.

             `SetNuiFocus(true, …)` borra el KeepInput que hubiera puesto:
             medido el 07/10 con la sonda --se ponia a true, se cogia el foco y
             el juego contestaba `keep=false` hasta la siguiente pasada--. Si se
             pone antes, no sirve de nada.

             Y ademas: coger el foco hace que el juego pierda las teclas que ya
             estaban PULSADAS, con KeepInput o sin el. Eso no se arregla desde
             aqui; lo arregla Volante (abajo).

             Tambien se vuelven a poner si alguien de fuera las apago y ya no
             esta: el vigilante compartido apaga KeepInput cada vez que otro
             recurso coge el foco, y al irse ese otro nadie las devolvia. ]]
        if forzar or ultimo.teclas ~= teclas or (teclas and not IsNuiFocusKeepingInput()) then
            SetNuiFocusKeepInput(teclas)
        end
    end

    ultimo.foco, ultimo.cursor, ultimo.teclas = foco, cursor, teclas
end

--- Registra como se cierra un panel ('admin' | 'tienda').
---@param panel string
---@param fn function
function Foco.AlCerrar(panel, fn)
    cerradores[panel] = fn
end

--[[ Abre o cierra un panel de pantalla completa.

     Son excluyentes: abrir uno cierra el otro. Antes el admin y la tienda solo
     cerraban el telefono, y con los dos abiertos cerrar uno soltaba el foco
     del recurso entero y el otro se quedaba pintado sin raton. ]]
---@param panel string  'admin' | 'tienda'
---@param abierto boolean
function Foco.Panel(panel, abierto)
    if abierto then
        for otro, cerrar in pairs(cerradores) do
            if otro ~= panel and Foco[otro] then pcall(cerrar) end
        end
    end

    Foco[panel] = abierto == true
    Foco.Aplicar()
end

--- Todo fuera: al parar el recurso o cuando la red de seguridad suelta el foco.
function Foco.Todo()
    Foco.telefono, Foco.apuntando, Foco.admin, Foco.tienda, Foco.carga = false, false, false, false, false
    Foco.escribiendoHasta = 0
    Foco.Aplicar(true)
end

--- Otro recurso ha cogido o soltado el foco: las teclas dependen de eso.
AddEventHandler('origen:foco:estado', function(recurso)
    if recurso ~= GetCurrentResourceName() then Foco.Aplicar() end
end)

--[[ El repaso lento. Es lo que hace caducar «escribiendo» y lo que devuelve
     las teclas si alguien de fuera las apago. Solo mientras hay algo abierto:
     con todo cerrado no hay nada que repasar. ]]
CreateThread(function()
    while true do
        Wait(500)
        if Foco.telefono or Foco.admin or Foco.tienda or Foco.carga then Foco.Aplicar() end
    end
end)
