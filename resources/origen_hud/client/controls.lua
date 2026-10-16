local function setupControls(controls)
    SendNUIMessage({
        action = 'setupControls',
        controls = controls,
    })
end

exports('setupControls', setupControls)

local function hideControls()
    SendNUIMessage({
        action = 'setupControls',
        controls = nil,
    })
end

exports('hideControls', hideControls)


--[[ La ayuda de teclas de GTA (arriba a la izquierda, BeginTextCommandDisplayHelp)
     con el estilo del servidor. Recibe el MISMO texto que se le daba a GTA:

         exports.origen_hud:Ayuda('~INPUT_PICKUP~ Usar~n~~INPUT_CELLPHONE_CANCEL~ Cancelar')

     Se llama cada fotograma, como la de GTA: solo se manda a la interfaz
     cuando cambia, y se quita sola cuando se deja de pedir (300 ms). Una
     linea sin tecla sale con un icono de aviso. ]]
local TECLAS = {
    INPUT_PICKUP = 'E', INPUT_CONTEXT = 'E', INPUT_TALK = 'E', INPUT_VEH_HORN = 'E',
    INPUT_DETONATE = 'G', INPUT_THROW_GRENADE = 'G', INPUT_ENTER = 'F', INPUT_RELOAD = 'R',
    INPUT_COVER = 'Q', INPUT_JUMP = 'SPACE', INPUT_SPRINT = 'SHIFT', INPUT_DUCK = 'CTRL',
    INPUT_ATTACK = 'LCLICK', INPUT_AIM = 'RCLICK',
    INPUT_CELLPHONE_CANCEL = 'BACKSPACE', INPUT_FRONTEND_RRIGHT = 'BACKSPACE', INPUT_FRONTEND_CANCEL = 'BACKSPACE',
    INPUT_FRONTEND_ACCEPT = 'ENTER', INPUT_FRONTEND_RDOWN = 'ENTER', INPUT_CELLPHONE_SELECT = 'ENTER',
    INPUT_FRONTEND_PAUSE_ALTERNATE = 'ESCAPE',
    INPUT_CELLPHONE_UP = 'UP', INPUT_CELLPHONE_DOWN = 'DOWN', INPUT_CELLPHONE_LEFT = 'LEFT', INPUT_CELLPHONE_RIGHT = 'RIGHT',
    INPUT_FRONTEND_UP = 'UP', INPUT_FRONTEND_DOWN = 'DOWN', INPUT_FRONTEND_LEFT = 'LEFT', INPUT_FRONTEND_RIGHT = 'RIGHT',
    INPUT_WEAPON_WHEEL_NEXT = 'WHEEL', INPUT_WEAPON_WHEEL_PREV = 'WHEEL',
    INPUT_CURSOR_SCROLL_UP = 'WHEEL', INPUT_CURSOR_SCROLL_DOWN = 'WHEEL',
    INPUT_MOVE_UP_ONLY = 'W', INPUT_MOVE_DOWN_ONLY = 'S', INPUT_MOVE_LEFT_ONLY = 'A', INPUT_MOVE_RIGHT_ONLY = 'D',
}

local function tecla(nombre)
    -- Lo que no esta en la tabla sale con su nombre de GTA: se ve y se añade.
    return TECLAS[nombre] or nombre:gsub('^INPUT_', '')
end

local function partir(texto)
    local lista = {}
    texto = tostring(texto or ''):gsub('\n', '~n~'):gsub('~[rgbywopcmusqh]~', ''):gsub('~a~', '')
    for linea in (texto .. '~n~'):gmatch('(.-)~n~') do
        local teclas, resto = {}, linea
        while true do
            local n, r = resto:match('^%s*~(INPUT_[%w_]+)~%s*(.*)$')
            if not n then break end
            teclas[#teclas + 1] = tecla(n)
            resto = r
        end
        resto = resto:gsub('^%s+', ''):gsub('%s+$', '')
        if #teclas > 0 or resto ~= '' then
            if #teclas == 0 then
                lista[#lista + 1] = { key = 'lucide:info', isIcon = true, text = resto }
            else
                lista[#lista + 1] = { key = table.concat(teclas, ' / '), text = resto }
            end
        end
    end
    return lista
end

local ayudaTexto, ayudaVista = nil, 0

local function Ayuda(texto)
    ayudaVista = GetGameTimer()
    if texto == ayudaTexto then return end
    local primera = ayudaTexto == nil
    ayudaTexto = texto
    setupControls(partir(texto))
    if not primera then return end
    CreateThread(function()
        while ayudaTexto and GetGameTimer() - ayudaVista < 300 do Wait(100) end
        if ayudaTexto then
            ayudaTexto = nil
            hideControls()
        end
    end)
end

exports('Ayuda', Ayuda)
