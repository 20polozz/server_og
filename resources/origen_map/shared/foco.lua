--[[ ═══════════════════════════════════════════════════════════════════════
     El raton no puede quedarse preso. La red de seguridad.

     Este fichero se carga EN CADA RECURSO QUE TIENE INTERFAZ, poniendolo el
     primero de sus client_scripts (en origen_map tambien, sin la @, desde
     que su modo posicionar coge el raton):

         client_scripts {
             '@origen_map/shared/foco.lua',
             'client/main.lua',
         }

     Vive en origen_map por lo mismo que marcar.lua: es el recurso que
     arranca antes que nadie (cfg/resources.cfg), y un fichero prestado con @
     solo se puede cargar si su recurso ya esta arrancado.

     ── Por que hace falta ──────────────────────────────────────────────────

     El foco de la NUI es POR RECURSO: SetNuiFocus(false) desde un recurso no
     suelta el que tiene puesto otro. Cuando una pantalla se esconde sin
     avisar a su Lua —el Escape que solo cambia un `v-if`, un cierre que se
     come un antirrebote— el raton se queda en medio, sin pantalla que escuche
     el Escape, y desde fuera no habia forma de quitarlo: solo reconectando.

     ── Lo que hace ─────────────────────────────────────────────────────────

     1. Envuelve SetNuiFocus y SetNuiFocusKeepInput de ESTE recurso para saber
        si tiene el foco puesto y desde que linea se cogio. Los natives se
        buscan como globales al llamarlos, asi que basta con redefinirlos aqui:
        todo el recurso pasa por el envoltorio sin tocar una sola llamada.
     2. Escucha 'origen:foco:soltar' (lo lanza el comando `raton` de
        origen_hud, desde la consola F8, que funciona aunque la NUI tenga el
        teclado) y suelta el foco de este recurso.
     3. Si lo tenia puesto, lo cuenta: recurso, linea que lo cogio y cuanto
        llevaba. Asi cada raton preso dice solo donde esta el fallo.

     Un recurso que quiera recoger su estado cuando le quitan el foco a la
     fuerza (su `isMenuOpen`, por ejemplo, o no volveria a abrirse) puede
     apuntarse:

         OrigenFoco.AlSoltar(function() isMenuOpen = false end)
   ═══════════════════════════════════════════════════════════════════════ ]]

if IsDuplicityVersion() then return end

local YO = GetCurrentResourceName()

local focoNativo = SetNuiFocus
local teclasNativo = SetNuiFocusKeepInput

local conFoco = false
local desde = 0
local quien = nil
local conTeclas = false
local alSoltar = {}

--- Si el foco se cogio CON cursor. Solo eso deja el raton en medio de la
--- pantalla; el foco sin cursor (colocar muebles) no lo vigila el automatico.
local conCursor = false
--- Cada vez que se coge el foco sube: el vigilante de una vez anterior lo ve
--- cambiado y se retira.
local vuelta = 0

--- Que otros recursos tienen el foco ahora mismo. Cada vigilante avisa al
--- cogerlo y al soltarlo; asi una pantalla que esta DEBAJO de otra (la de
--- muerto con el chat abierto encima) puede saberlo y no pisarle el teclado.
local otros = {}

local function avisar(tiene)
    TriggerEvent('origen:foco:estado', YO, tiene)
end

AddEventHandler('origen:foco:estado', function(recurso, tiene)
    if recurso ~= YO then otros[recurso] = tiene or nil end
end)

AddEventHandler('onClientResourceStop', function(recurso)
    otros[recurso] = nil
    --[[ Al pararse este recurso FiveM le quita el foco, pero si llevaba
         KeepInput puesto lo quita en el orden malo y descuadra el contador
         del raton para toda la partida (ORDEN_AL_SOLTAR, mas abajo). Se
         sueltan aqui primero, teclas antes que foco. ]]
    if recurso == YO and conFoco then
        teclasNativo(false)
        focoNativo(false, false)
    end
end)

--- `SetNuiFocus(1, 0)` y `SetNuiFocus(true, false)` son lo mismo para el
--- native; aqui tambien.
local function si(v)
    return v ~= nil and v ~= false and v ~= 0
end

--- La libreria `debug` de Lua, si sigue siendo la libreria: origen_titlemenu
--- define un `function debug(msg)` global en su config.lua (shared, carga
--- antes que este fichero) y `debug.getinfo` reventaba en cada SetNuiFocus,
--- dejando el menu de inicio sin raton.
local libDebug = type(debug) == 'table' and debug or nil

--- Fichero:linea de quien llama al envoltorio.
local function origenDeLaLlamada()
    local info = libDebug and type(libDebug.getinfo) == 'function' and libDebug.getinfo(3, 'Sl')
    if not info then return '?' end
    return ('%s:%s'):format(info.short_src or '?', info.currentline or '?')
end

--[[ SetNuiFocusKeepInput es un interruptor GLOBAL del cliente, no del recurso.
     La auditoria del 11/09 lo encontro encendido de sobra en muchos sitios: el
     inventario lo dejaba en true en cada Escape, la muerte al revivir, el admin
     al cerrar... y el panel siguiente que no lo tocaba heredaba el raton
     girando la camara y el clic pegando por detras. Tres reglas lo cortan de
     raiz sin tocar los cuarenta recursos:

     - Al COGER el foco (de no tenerlo a tenerlo) se apaga. Quien lo quiere
       encendido lo enciende despues, que es lo que hacen todos.
     - Al SOLTARLO se apaga si lo encendio este recurso.
     - Sin foco en este recurso, encenderlo no hace nada: no hay pantalla suya
       a la que dejar pasar el teclado.

     Lo que cuesta: un panel que se abre ENCIMA de otro con KeepInput (el chat
     sobre la pantalla de muerto) lo apaga, y al cerrarse no vuelve solo. Quien
     lo necesite mientras dura su pantalla, que lo reafirme (lo hace
     origen_ambulancejob estando muerto, para poder hablar). ]]
--[[ ── 4. El vigilante automatico ────────────────────────────────────────

     Lo de arriba solo sirve si alguien escribe `soltarraton`. El jugador no
     lo sabe, y el raton se le quedaba preso "sobre todo al cerrar el admin".
     Asi que ahora se comprueba solo:

     Mientras este recurso tiene el foco CON cursor, cada 1,5 s le pregunta a
     su pantalla si esta enseñando algo (el trozo que reparte
     kit/repartir-foco.py en cada index.html). Si contesta dos veces seguidas
     que no --unos 3 s sin nada delante--, se suelta el raton y se cuenta en
     la consola F8 quien lo habia cogido.

     - Una pagina sin el trozo no contesta nunca, y sin respuesta NO se
       suelta nada: ante la duda, se deja como estaba.
     - Pero una pagina que SI contestaba y deja de hacerlo esta colgada, y eso
       es distinto de no saber contestar: el navegador de FiveM es uno para
       todas las interfaces, y cuando una se cuelga las demas se quedan
       pintadas a medias y sin responder. El jugador se queda con el raton en
       medio, sin camara, sin poder hablar y sin forma de salir. Tras
       MUDAS_PARA_SOLTAR preguntas sin respuesta (unos 9 s) se suelta igual
       (18/09).
     - La pagina, ante la duda, contesta que si.
     - Un modo que coge el raton sin pintar nada a proposito se aparta con
       OrigenFoco.SinPantalla(true) mientras dure.                         ]]
local ESPERA_PRIMERA = 1500
local CADA = 1500
local VACIAS_PARA_SOLTAR = 2
--- Preguntas seguidas sin contestar, habiendo contestado antes, para dar la
--- pantalla por colgada. Seis son unos nueve segundos.
local MUDAS_PARA_SOLTAR = 6

local sinPantalla = false
local pregunta = 0
local vacias = 0
--- La ultima pregunta que contesto la pantalla, y si contesto alguna vez en
--- esta vuelta: sin eso no se puede distinguir «colgada» de «no sabe».
local contestada = 0
local contestoAlguna = false
local mudas = 0

local function Soltar(motivo)
    local lo_tenia = conFoco
    local segundos = lo_tenia and math.floor((GetGameTimer() - desde) / 1000) or 0

    -- Sin mirar `conFoco`: si algo del recurso llamo al native por otro
    -- camino, soltarlo igualmente no cuesta nada.
    -- Las teclas ANTES que el foco: ver ORDEN_AL_SOLTAR.
    teclasNativo(false)
    focoNativo(false, false)

    conFoco = false
    conCursor = false
    conTeclas = false
    sinPantalla = false
    vuelta = vuelta + 1

    --[[ `soltarraton` es el rescate del jugador: aunque este recurso no
         tuviera el raton, sus AlSoltar se llaman igual. Hay pantallas que
         bloquean la camara SIN tener el foco (la tablet de policia a medio
         abrir, un modo muebles, un editor), y hasta ahora el comando no las
         tocaba: soltaba un raton que ya estaba suelto y la camara seguia
         clavada (27/09). Cada AlSoltar tiene que poder llamarse sin nada
         abierto. ]]
    if not lo_tenia then
        if motivo == 'comando' then
            for i = 1, #alSoltar do pcall(alSoltar[i]) end
        end
        return
    end

    avisar(false)

    -- Sin imprimir nada (29/09: llenaba el F8). Quien lo quiera ver lo tiene
    -- con `soltarraton`, que junta a quien se lo ha quitado.
    TriggerEvent('origen:foco:soltado', YO, quien or '?', segundos)

    for i = 1, #alSoltar do
        pcall(alSoltar[i])
    end
end

RegisterNUICallback('origen:foco:veo', function(data, cb)
    cb('ok')
    if type(data) ~= 'table' or tonumber(data.n) ~= pregunta then return end

    contestada = pregunta
    contestoAlguna = true
    mudas = 0

    if data.visto == false then
        vacias = vacias + 1
    else
        vacias = 0
    end
end)

local function VigilarPantalla()
    vuelta = vuelta + 1
    local mia = vuelta
    vacias = 0
    contestada = 0
    contestoAlguna = false
    mudas = 0

    CreateThread(function()
        Wait(ESPERA_PRIMERA)

        while conFoco and vuelta == mia do
            local preguntada = 0

            if conCursor and not sinPantalla then
                pregunta = pregunta + 1
                preguntada = pregunta
                SendNUIMessage({ accion = 'origen:foco:mira', n = pregunta })
            else
                vacias = 0
                mudas = 0
            end

            Wait(CADA)
            if not conFoco or vuelta ~= mia then break end

            --- Preguntada y sin contestar: se apunta, pero solo cuenta si esta
            --- pantalla habia contestado antes (si no, es que no sabe).
            if preguntada > 0 then
                if contestada < preguntada then
                    mudas = mudas + 1
                else
                    mudas = 0
                end
            end

            if vacias >= VACIAS_PARA_SOLTAR and conCursor and not sinPantalla then
                Soltar('vacio')
                break
            end

            if contestoAlguna and mudas >= MUDAS_PARA_SOLTAR and conCursor and not sinPantalla then
                Soltar('colgada')
                break
            end
        end
    end)
end

--[[ ORDEN_AL_SOLTAR. Las teclas se sueltan SIEMPRE antes que el foco.

     FiveM no lleva un si/no de «el raton es del juego»: lleva un CONTADOR
     (InputHook::SetGameMouseFocus, g_isFocusStolenCount) que suben y bajan
     SetNuiFocus y SetNuiFocusKeepInput segun el orden en que llegan
     (nui-resources/ResourceUIScripting.cpp, updateFocus). Soltar el foco con
     KeepInput aun puesto lo baja una vez de mas, y el descuadre dura hasta
     cerrar el juego: desde entonces, la pantalla que abre con cursor y SIN
     KeepInput no le quita el raton al juego (cursor clavado en el centro, la
     camara girando detras). Teclas primero y luego foco lo deja a cero.
     Comprobado con un simulador de las reglas de FiveM (17/09/2026). ]]
function SetNuiFocus(foco, cursor)
    local ahora = si(foco) or si(cursor)

    if ahora and not conFoco then
        desde = GetGameTimer()
        quien = origenDeLaLlamada()
        teclasNativo(false)
        conTeclas = false
    elseif not ahora then
        -- Aunque este recurso crea no tenerlas: si alguien las encendio por
        -- el native directo, soltar el foco antes lo descuadraria igual.
        teclasNativo(false)
        conTeclas = false
    end

    local cambia = ahora ~= conFoco
    conFoco = ahora
    conCursor = ahora and si(cursor)
    local r = focoNativo(foco, cursor)
    if cambia then
        avisar(ahora)
        if ahora then VigilarPantalla() end
    end
    return r
end

function SetNuiFocusKeepInput(activo)
    if si(activo) and not conFoco then return end

    conTeclas = si(activo)
    return teclasNativo(activo)
end

OrigenFoco = {}

function OrigenFoco.AlSoltar(fn)
    if type(fn) == 'function' then alSoltar[#alSoltar + 1] = fn end
end

--- Para un modo que coge el raton sin enseñar nada a proposito: mientras
--- este puesto, el vigilante automatico no lo suelta. Se quita con
--- SinPantalla(false), o solo si el foco se suelta a la fuerza.
function OrigenFoco.SinPantalla(valor)
    sinPantalla = valor ~= false
end

function OrigenFoco.Tiene()
    return conFoco
end

--- Si algun OTRO recurso con vigilante tiene ahora el foco.
function OrigenFoco.OtroConFoco()
    return next(otros) ~= nil
end

AddEventHandler('origen:foco:soltar', function()
    Soltar('comando')
end)

--- Para `focoestado` (origen_hud): quien tiene el foco, sin soltar nada.
AddEventHandler('origen:foco:quien', function()
    if not conFoco then return end
    TriggerEvent('origen:foco:tengo', YO, quien or '?', conCursor, conTeclas,
        math.floor((GetGameTimer() - desde) / 1000))
end)

--[[ ── Quien apaga la camara o pinta el cursor de GTA (27/09) ─────────────────

     El raton «preso» no siempre es una NUI: un jugador tenia la manita de GTA
     en pantalla y la camara quieta sin ningun recurso con el foco, y
     `ratonmotor` no lo arreglaba. Eso lo hace un script que llama cada
     fotograma a SetMouseCursorActiveThisFrame / EnterCursorMode o apaga los
     controles de mirar (1, 2) con una bandera que se ha quedado puesta.

     Como este fichero se carga en casi todos los recursos (tambien en los
     cifrados), aqui se apunta quien lo hace: la hora de la ultima llamada y,
     como mucho una vez cada 2 s, el fichero:linea. `focoestado` lo pregunta
     con 'origen:foco:quien' y cada recurso contesta con
     'origen:foco:camara' si lo ha hecho en el ultimo medio segundo. ]]
local marcas = {}

local function marcar(que)
    local m = marcas[que]
    local ahora = GetGameTimer()
    if not m then m = { t = 0, donde = '?', cuando = 0 } marcas[que] = m end
    m.t = ahora
    if ahora - m.cuando > 2000 then
        m.cuando = ahora
        -- 1 getinfo, 2 marcar, 3 el envoltorio, 4 quien llamo al native.
        local info = libDebug and type(libDebug.getinfo) == 'function' and libDebug.getinfo(4, 'Sl')
        m.donde = info and ('%s:%s'):format(info.short_src or '?', info.currentline or '?') or '?'
    end
end

local cursorNativo = SetMouseCursorActiveThisFrame
local modoCursorNativo = EnterCursorMode
local apagarNativo = DisableControlAction
local apagarTodoNativo = DisableAllControlActions

if cursorNativo then
    function SetMouseCursorActiveThisFrame(...)
        marcar('cursor de GTA')
        return cursorNativo(...)
    end
end

if modoCursorNativo then
    function EnterCursorMode(...)
        marcar('modo cursor (EnterCursorMode)')
        return modoCursorNativo(...)
    end
end

if apagarNativo then
    function DisableControlAction(grupo, control, ...)
        if control == 1 or control == 2 then marcar('camara apagada (control ' .. tostring(control) .. ')') end
        return apagarNativo(grupo, control, ...)
    end
end

if apagarTodoNativo then
    function DisableAllControlActions(...)
        marcar('todos los controles apagados')
        return apagarTodoNativo(...)
    end
end

AddEventHandler('origen:foco:quien', function()
    local ahora = GetGameTimer()
    for que, m in pairs(marcas) do
        if ahora - m.t < 500 then
            TriggerEvent('origen:foco:camara', YO, que, m.donde)
        end
    end
end)
