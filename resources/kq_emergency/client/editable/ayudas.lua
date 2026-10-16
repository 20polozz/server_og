--[[ ═══════════════════════════════════════════════════════════════════════
     Las ayudas de teclas del modo de colocacion, con el estilo del servidor.

     Mientras se coloca una pieza (gizmo), el recurso pinta abajo a la derecha
     los botones «de GTA»: el scaleform INSTRUCTIONAL_BUTTONS, con «Modo
     Traslacion [W] · Modo Rotacion [R] · Clonar y reflejar [X] · Clonar
     objeto…». Lo hace desde ficheros CIFRADOS (client/gizmo/kqGizmo.lua,
     client/editor/*): no se pueden tocar.

     Lo que si se puede: los natives se buscan como globales al llamarlos, asi
     que redefinirlos AQUI (este fichero va antes que los cifrados en el
     fxmanifest) hace que todo el recurso pase por el envoltorio. Es el mismo
     truco de @origen_map/shared/foco.lua con SetNuiFocus.

     Que hace:
       1. Apunta los scaleform INSTRUCTIONAL_BUTTONS que pide ESTE recurso.
       2. Escucha lo que se les manda (CLEAR_ALL, SET_DATA_SLOT con su tecla y
          su texto, DRAW_INSTRUCTIONAL_BUTTONS) y reconstruye la lista.
       3. Cuando van a dibujarse, NO los dibuja: le pasa la lista a las
          ayudas de teclas del servidor (exports.origen_hud:setupControls).
       4. Cuando dejan de dibujarse (se sale del modo), las quita.

     Si origen_hud no esta arrancado, no se toca nada y salen los de GTA.

     Vale para las dos marcas (es logica comun, no estilo).

     SIN PROBAR EN PARTIDA (04/10). Si los botones de GTA siguen saliendo es
     que el cifrado llama a los natives por hash (Citizen.InvokeNative) o los
     pinta otro recurso: entonces este fichero no los ve y hay que quitarlo.
     Para quitarlo: borrar su linea del fxmanifest.
   ═══════════════════════════════════════════════════════════════════════ ]]

if IsDuplicityVersion() then return end

local PELICULA = 'INSTRUCTIONAL_BUTTONS'

local nuestras = {}     -- [handle] = true: los scaleform de botones de este recurso
local metodo = nil      -- nombre del metodo abierto sobre uno de los nuestros
local hueco = nil       -- el boton que se esta montando: { indice, teclas = {}, texto }
local montando = {}     -- [indice + 1] = { key, text }
local lista = {}        -- la ultima lista completa
local ultimoDibujo = 0  -- GetGameTimer() de la ultima vez que quisieron dibujarse
local puesta = nil      -- firma de lo que hay puesto en origen_hud (nil = nada)

--- Los botones que GTA nombra por numero (lo que devuelve
--- GetControlInstructionalButton cuando no es una letra).
local BOTONES = {
    ['100'] = 'LCLICK', ['101'] = 'RCLICK', ['102'] = 'MCLICK',
    ['115'] = 'WHEEL', ['116'] = 'WHEEL', ['117'] = 'WHEEL',
    ['194'] = 'UP', ['195'] = 'DOWN', ['196'] = 'LEFT', ['197'] = 'RIGHT',
    ['1000'] = 'SHIFT', ['1002'] = 'TAB', ['1003'] = 'ENTER', ['1004'] = 'BACKSPACE',
    ['1013'] = 'CTRL', ['1015'] = 'ALT', ['2000'] = 'SPACE',
}

--- «t_W» -> «W», «b_1000» -> «SHIFT». nil si el texto no es una tecla.
local function tecla(s)
    local letra = s:match('^t_(.+)$')
    if letra then return letra:upper() end
    local numero = s:match('^b_(%d+)$')
    if numero then return BOTONES[numero] or '?' end
    if s:match('^~INPUT') then return '?' end
    return nil
end

local function hudArrancado()
    return GetResourceState('origen_hud') == 'started'
end

local function abrir(handle, nombre)
    if not nuestras[handle] or type(nombre) ~= 'string' then return end
    metodo = nombre:upper()
    if metodo == 'CLEAR_ALL' then
        montando = {}
    elseif metodo == 'SET_DATA_SLOT' then
        hueco = { teclas = {} }
    elseif metodo == 'DRAW_INSTRUCTIONAL_BUTTONS' then
        lista = {}
        local indices = {}
        for i in pairs(montando) do indices[#indices + 1] = i end
        table.sort(indices)
        for _, i in ipairs(indices) do lista[#lista + 1] = montando[i] end
    end
end

local function cerrar()
    if hueco and metodo == 'SET_DATA_SLOT' and hueco.texto and #hueco.teclas > 0 then
        montando[(hueco.indice or #montando) + 1] = {
            key = table.concat(hueco.teclas, '+'),
            text = hueco.texto,
        }
    end
    hueco = nil
    metodo = nil
end

local function apuntarTexto(s)
    if not hueco or type(s) ~= 'string' or s == '' then return end
    local t = tecla(s)
    if t then
        hueco.teclas[#hueco.teclas + 1] = t
    else
        -- Fuera los codigos de color de GTA (~g~, ~s~...).
        hueco.texto = (s:gsub('~%a~', ''))
    end
end

local function apuntarEntero(n)
    if hueco and hueco.indice == nil and type(n) == 'number' then hueco.indice = n end
end

--- Redefine un native (y sus nombres viejos) dejando pasar la llamada.
--- `antes(...)` devuelve true para NO llamar al original.
local function envolver(nombres, antes, despues)
    for _, nombre in ipairs(nombres) do
        local original = _G[nombre]
        if type(original) == 'function' then
            _G[nombre] = function(...)
                if antes and antes(...) then return end
                if despues then
                    local r = table.pack(original(...))
                    despues(r[1], ...)
                    return table.unpack(r, 1, r.n)
                end
                return original(...)
            end
        end
    end
end

-- 1. Que scaleform son los botones.
envolver({ 'RequestScaleformMovie', 'RequestScaleformMovieInstance', 'RequestScaleformMovieInteractive' }, nil,
    function(handle, nombre)
        if type(nombre) == 'string' and nombre:upper() == PELICULA and handle then
            nuestras[handle] = true
        end
    end)

-- 2. Lo que se les manda.
envolver({ 'BeginScaleformMovieMethod', 'PushScaleformMovieFunction' }, function(handle, nombre)
    abrir(handle, nombre)
end)
envolver({ 'EndScaleformMovieMethod', 'PopScaleformMovieFunctionVoid', 'EndScaleformMovieMethodReturnValue',
    'EndScaleformMovieMethodReturn', 'PopScaleformMovieFunction' }, nil, function()
    cerrar()
end)
--  Los metodos de una sola llamada (sin Begin/End).
envolver({ 'CallScaleformMovieMethod', 'CallScaleformMovieFunctionVoid', 'CallScaleformMovieMethodWithNumber',
    'CallScaleformMovieFunctionFloatParams' }, function(handle, nombre)
    abrir(handle, nombre)
    cerrar()
end)

envolver({
    'ScaleformMovieMethodAddParamPlayerNameString', 'ScaleformMovieMethodAddParamTextureNameString',
    'ScaleformMovieMethodAddParamLiteralString', 'PushScaleformMovieMethodParameterString',
    'PushScaleformMovieFunctionParameterString', 'PushScaleformMovieMethodParameterButtonName',
    'AddTextComponentSubstringPlayerName', 'AddTextComponentString', 'AddTextComponentScaleform',
    'AddTextComponentSubstringKeyboardDisplay',
}, function(s)
    apuntarTexto(s)
end)
--  El texto dado por clave de GXT.
envolver({ 'AddTextComponentSubstringTextLabel', 'AddTextComponentItemString' }, function(clave)
    if hueco and type(clave) == 'string' then apuntarTexto(GetLabelText(clave)) end
end)
envolver({ 'ScaleformMovieMethodAddParamInt', 'PushScaleformMovieMethodParameterInt',
    'PushScaleformMovieFunctionParameterInt' }, function(n)
    apuntarEntero(n)
end)

-- 3. El dibujo: en vez de pintarlos, se los damos al HUD del servidor.
local function firma()
    local t = {}
    for i, c in ipairs(lista) do t[i] = c.key .. '=' .. c.text end
    return table.concat(t, '|')
end

envolver({ 'DrawScaleformMovieFullscreen', 'DrawScaleformMovieFullscreenMasked', 'DrawScaleformMovie' },
    function(handle)
        if not nuestras[handle] or not hudArrancado() then return false end
        ultimoDibujo = GetGameTimer()
        -- Sin lista (no se supo leer lo que mandaron): que salgan los de GTA
        -- antes que quedarse sin ayudas.
        if #lista == 0 then return false end
        local f = firma()
        if f ~= puesta then
            puesta = f
            exports.origen_hud:setupControls(lista)
        end
        return true
    end)

-- 4. Dejaron de dibujarse: fuera las ayudas.
local function quitar()
    if not puesta then return end
    puesta = nil
    if hudArrancado() then exports.origen_hud:hideControls() end
end

CreateThread(function()
    while true do
        Wait(250)
        if puesta and GetGameTimer() - ultimoDibujo > 400 then quitar() end
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then quitar() end
end)
