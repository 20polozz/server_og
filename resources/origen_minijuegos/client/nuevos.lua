--[[ LOS MINIJUEGOS NUEVOS · lado del juego

     Un solo lanzador para los ocho: `StartMinijuego(juego, dificultad, ajustes,
     callback)`. Cada juego tiene ademas su export con la firma de siempre
     —(dificultad, callback)—, para que quien ya usa StartLockpick pueda cambiar
     de juego tocando un nombre.

     Lo que se juega y como se pinta vive en html/nuevos; aqui solo se decide
     con que numeros, se pone la animacion y se devuelve el resultado. ]]

--[[ Dos opciones que no son del juego y no pasan por `Ajustes` (que solo deja
     lo que declara config_nuevos):

       titulo   rotulo del panel, para cuando quien lo lanza lo llama de otra
                manera («Desmontar la pieza» en el taller, no «Taladro»).
       sinAnim  no poner la animacion del juego ni cortar la que haya. La usa
                quien ya tiene al personaje trabajando (capo abierto, soldando)
                y no quiere que se le vaya a medias. ]]
local enCurso = nil     -- { juego, callback, turno, sinAnim }
local turno = 0

---@return table|nil ajustes  los de la dificultad, con lo que venga de fuera ya recortado
local function Ajustes(juego, dificultad, extra)
    local def = Config.Nuevos[juego]
    if not def then return nil end

    local base = def.dificultad[dificultad] or def.dificultad.medium
    local final = {}
    for clave, valor in pairs(base) do final[clave] = valor end

    if type(extra) == 'table' then
        for _, ajuste in ipairs(def.ajustes) do
            local valor = extra[ajuste.clave]
            if valor ~= nil and valor ~= '' then
                if ajuste.tipo == 'si_no' then
                    if type(valor) == 'boolean' then final[ajuste.clave] = valor end
                else
                    valor = tonumber(valor)
                    if valor then
                        final[ajuste.clave] = math.max(ajuste.min, math.min(ajuste.max, valor))
                    end
                end
            end
        end
    end

    return final
end

local function Animar(animacion)
    if not animacion then return end
    RequestAnimDict(animacion.dict)
    local tope = GetGameTimer() + 3000
    while not HasAnimDictLoaded(animacion.dict) and GetGameTimer() < tope do Wait(10) end
    if HasAnimDictLoaded(animacion.dict) then
        TaskPlayAnim(PlayerPedId(), animacion.dict, animacion.anim, 8.0, -8.0, -1, animacion.flag or 49, 0, false, false, false)
        RemoveAnimDict(animacion.dict)
    end
end

--- Cierra el juego en curso y entrega el resultado UNA vez.
local function Terminar(exito)
    local partida = enCurso
    if not partida then return end
    enCurso = nil

    SetNuiFocus(false, false)
    if not partida.sinAnim then ClearPedTasks(PlayerPedId()) end

    if partida.callback then pcall(partida.callback, exito == true) end
    TriggerEvent('origen_minijuegos:result', partida.juego, exito == true)
end

---@param juego string          clave de Config.Nuevos
---@param dificultad string|nil easy | medium | hard | extreme
---@param ajustes table|nil     ajustes sueltos que pisan los de la dificultad
---@param callback fun(exito: boolean)|nil
---@return boolean lanzado
function StartMinijuego(juego, dificultad, ajustes, callback)
    --- Tambien se admite (juego, dificultad, callback).
    if type(ajustes) == 'function' and callback == nil then
        callback, ajustes = ajustes, nil
    end

    local def = Config.Nuevos[juego]
    if not def then
        if callback then pcall(callback, false) end
        return false
    end

    --- Quien esperaba el resultado anterior tiene que recibir uno: si su
    --- callback se pierde, su bandera de «minijuego en curso» no se suelta.
    if enCurso then
        SendNUIMessage({ action = 'nuevoCerrar' })
        Terminar(false)
    end

    turno = turno + 1
    local miTurno = turno
    local extra = type(ajustes) == 'table' and ajustes or nil
    local sinAnim = extra and extra.sinAnim == true
    enCurso = { juego = juego, callback = callback, turno = miTurno, sinAnim = sinAnim }

    if not sinAnim then Animar(def.animacion) end

    SendNUIMessage({
        action = 'nuevoEmpezar',
        juego = juego,
        titulo = (extra and type(extra.titulo) == 'string' and extra.titulo ~= '' and extra.titulo:sub(1, 48)) or def.etiqueta,
        config = Ajustes(juego, dificultad or 'medium', ajustes),
        volumen = Config.NuevosVolumen or 0.35,
        --- Vuelve con el resultado: el de una partida vieja (su rotulo de
        --- final dura casi un segundo) no puede cerrar la nueva.
        turno = miTurno,
    })
    SetNuiFocus(true, true)

    --- Con el raton preso no se puede seguir jugando muerto, esposado o en el
    --- suelo: se da por fallado y se suelta.
    CreateThread(function()
        while enCurso and enCurso.turno == miTurno do
            local ped = PlayerPedId()
            if IsEntityDead(ped) or IsPedRagdoll(ped) or IsPedCuffed(ped) then
                SendNUIMessage({ action = 'nuevoCerrar' })
                Terminar(false)
                return
            end
            Wait(400)
        end
    end)

    return true
end

RegisterNUICallback('nuevoResultado', function(data, cb)
    cb('ok')
    --- Un resultado de una partida que ya no es la viva no cuenta.
    if not enCurso or (data and data.juego ~= enCurso.juego) then return end
    if data and data.turno ~= nil and tonumber(data.turno) ~= enCurso.turno then return end
    Terminar(data and data.exito == true)
end)

--[[ Si el vigilante suelta el raton a la fuerza con un juego abierto, se da
     por fallado: la pantalla fuera y el resultado a quien lo esperaba. ]]
OrigenFoco.AlSoltar(function()
    if enCurso then
        SendNUIMessage({ action = 'nuevoCerrar' })
        Terminar(false)
    end
end)

exports('StartMinijuego', StartMinijuego)

--- Si hay un minijuego nuevo abierto (para quien quiera no pisarlo).
exports('MinijuegoEnCurso', function() return enCurso ~= nil end)

--[[ Lo que necesita un editor para ofrecerlos: clave, etiqueta, los numeros de
     cada dificultad y los ajustes que se pueden tocar con sus topes. ]]
exports('Catalogo', function()
    local lista = {}
    for _, clave in ipairs(Config.NuevosOrden) do
        local def = Config.Nuevos[clave]
        if def then
            lista[#lista + 1] = {
                clave = clave,
                etiqueta = def.etiqueta,
                dificultad = def.dificultad,
                ajustes = def.ajustes,
            }
        end
    end
    return lista
end)

--- Un export por juego, con la firma de los antiguos: (dificultad, callback).
local EXPORTS = {
    ganzua = 'StartGanzua',
    pines = 'StartPines',
    dial = 'StartDial',
    taladro = 'StartTaladro',
    huella = 'StartHuella',
    clave = 'StartClave',
    senal = 'StartSenal',
    corte = 'StartCorte',
    boveda = 'StartBoveda',
    termita = 'StartTermita',
    soplete = 'StartSoplete',
    laser = 'StartLaser',
    tunel = 'StartTunel',
    circuito = 'StartCircuito',
    ritmo = 'StartRitmo',
    inyeccion = 'StartInyeccion',
}

for juego, nombre in pairs(EXPORTS) do
    exports(nombre, function(dificultad, callback, ajustes)
        return StartMinijuego(juego, dificultad, ajustes, callback)
    end)
end

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() and enCurso then
        SetNuiFocus(false, false)
        ClearPedTasks(PlayerPedId())
    end
end)
