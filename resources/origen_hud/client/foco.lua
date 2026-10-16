--[[ El comando que suelta el raton de todos los recursos a la vez.

     Se escribe en la consola F8: es lo unico que sigue respondiendo cuando
     una interfaz se ha quedado con el teclado y no hay pantalla delante. El
     chat no sirve —la T la recibe la interfaz— y ninguna tecla asignada con
     RegisterKeyMapping llega mientras la NUI tiene el foco.

     Cada recurso que carga '@origen_map/shared/foco.lua' contesta si tenia
     el foco puesto y desde que linea; aqui se junta y se enseña, para que el
     fallo se pueda arreglar en su sitio y no volver a pasar. ]]

local soltados = {}
local recogiendo = false

AddEventHandler('origen:foco:soltado', function(recurso, linea, segundos)
    if not recogiendo then return end
    soltados[#soltados + 1] = ('%s (%s, %ds)'):format(recurso, linea, segundos)
end)

-- `soltarraton` es el nombre que ya conocia la gente: antes lo tenia el
-- inventario y solo soltaba el foco del inventario.
RegisterCommand('soltarraton', function()
    soltados = {}
    recogiendo = true

    TriggerEvent('origen:foco:soltar')

    -- Los manejadores de los demas recursos corren en el mismo fotograma,
    -- pero el print de cada uno puede ir detras: un respiro y se resume.
    SetTimeout(200, function()
        recogiendo = false

        if #soltados == 0 then
            print('^3[foco]^7 Ningun recurso con vigilante tenia el raton. Si seguia preso, lo tiene uno sin el (ox_lib, o un recurso sin \'@origen_map/shared/foco.lua\').')
            return
        end

        for i = 1, #soltados do
            print('^3[foco]^7 Soltado: ' .. soltados[i])
        end
    end)
end, false)

--[[ ── focoestado: que pasa con el raton, sin tocar nada ────────────────────

     Para escribirlo en F8 con el raton ya preso y MOVIENDO el raton. Dice:
     - que recursos con vigilante tienen el foco (y desde que linea);
     - lo que cree FiveM (IsNuiFocused / IsNuiFocusKeepingInput);
     - si el juego esta recibiendo el raton, mirando durante 2 s si el cursor
       se mueve y si al juego le llega movimiento de camara.

     Si nadie tiene el foco y aun asi el juego no recibe el raton, no es de
     ningun recurso: es el contador de FiveM (InputHook::SetGameMouseFocus)
     descuadrado, que dura hasta cerrar el juego. Lo corrige `ratonmotor`. ]]
local tenedores = {}
local camara = {}
local escuchando = false

AddEventHandler('origen:foco:camara', function(recurso, que, donde)
    if not escuchando then return end
    camara[#camara + 1] = ('%s: %s (%s)'):format(recurso, que, donde)
end)

AddEventHandler('origen:foco:tengo', function(recurso, linea, cursor, teclas, segundos)
    if not escuchando then return end
    tenedores[#tenedores + 1] = ('%s (lo cogio %s, %ds, cursor=%s, teclas=%s)')
        :format(recurso, linea, segundos, tostring(cursor), tostring(teclas))
end)

RegisterCommand('focoestado', function()
    tenedores = {}
    camara = {}
    escuchando = true
    TriggerEvent('origen:foco:quien')

    CreateThread(function()
        Wait(200)
        escuchando = false

        print('^3[foco]^7 --- estado del raton (mueve el raton 2 segundos) ---')
        print(('^3[foco]^7 FiveM: IsNuiFocused=%s  IsNuiFocusKeepingInput=%s  menu de pausa=%s')
            :format(tostring(IsNuiFocused()), tostring(IsNuiFocusKeepingInput()), tostring(IsPauseMenuActive())))

        --[[ Quien esta apagando la camara o pintando la manita de GTA ahora
             mismo (lo apunta @origen_map/shared/foco.lua en cada recurso). Si
             el raton sigue preso sin ninguna pantalla, el culpable sale aqui. ]]
        if #camara == 0 then
            print('^3[foco]^7 Nadie esta apagando la camara ni pintando el cursor de GTA.')
        else
            for i = 1, #camara do print('^1[foco]^7 ' .. camara[i]) end
        end

        if #tenedores == 0 then
            print('^3[foco]^7 Ningun recurso con vigilante tiene el foco.')
        else
            for i = 1, #tenedores do print('^3[foco]^7 Con foco: ' .. tenedores[i]) end
        end

        local x0, y0 = GetNuiCursorPosition()
        local cursorSeMueve, juegoRecibe = false, false
        local fin = GetGameTimer() + 2000
        while GetGameTimer() < fin do
            local x, y = GetNuiCursorPosition()
            if x ~= x0 or y ~= y0 then cursorSeMueve = true end
            if math.abs(GetDisabledControlUnboundNormal(0, 1)) > 0.0001
                or math.abs(GetDisabledControlUnboundNormal(0, 2)) > 0.0001 then
                juegoRecibe = true
            end
            Wait(0)
        end

        print(('^3[foco]^7 Cursor de Windows se mueve=%s  El juego recibe el raton=%s')
            :format(tostring(cursorSeMueve), tostring(juegoRecibe)))

        if #tenedores == 0 and not IsNuiFocused() and cursorSeMueve and not juegoRecibe then
            print('^1[foco]^7 Nadie tiene el foco y el juego no recibe el raton: es el contador de FiveM descuadrado. Escribe ^5ratonmotor^7 para corregirlo.')
        elseif #tenedores > 0 or IsNuiFocused() then
            print('^3[foco]^7 Hay foco puesto: ^5soltarraton^7 lo suelta y dice de quien era.')
        end
    end)
end, false)

--[[ ── ratonmotor: devuelve el raton al juego ───────────────────────────────

     Corrige el contador de FiveM cuando se ha quedado una vez de mas en
     «raton de la interfaz» sin ninguna interfaz abierta. Hace a proposito la
     secuencia que en FiveM lo baja en uno (foco con teclas, soltar el foco con
     las teclas aun puestas, soltar las teclas), por el native directo para no
     pasar por el vigilante, que la ordenaria. Solo si nadie tiene el foco: con
     una pantalla abierta, soltar el foco es lo que toca. ]]
local SET_NUI_FOCUS = 0x5B98AE30
local SET_NUI_FOCUS_KEEP_INPUT = 0x3FF5E5F8

local function BajarContador()
    Citizen.InvokeNative(SET_NUI_FOCUS, true, false)
    Citizen.InvokeNative(SET_NUI_FOCUS_KEEP_INPUT, true)
    Citizen.InvokeNative(SET_NUI_FOCUS, false, false)
    Citizen.InvokeNative(SET_NUI_FOCUS_KEEP_INPUT, false)
end

RegisterCommand('ratonmotor', function()
    if IsNuiFocused() then
        print('^3[foco]^7 Hay una pantalla con el foco: usa ^5soltarraton^7 primero.')
        return
    end
    BajarContador()
    print('^2[foco]^7 Contador de FiveM bajado en uno. Si el raton sigue sin volver al juego, repite ^5focoestado^7.')
end, false)

--[[ La cura automatica que habia aqui (27/09) se quito el 29/09: saltaba una
     y otra vez sin motivo, y cada salto baja el contador de FiveM, que
     descuadrado al reves deja las pantallas sin quitarle el raton al juego.
     Queda solo `ratonmotor`, a mano. ]]


