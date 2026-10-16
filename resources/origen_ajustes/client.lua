--[[ Los colores del menu de pausa (Ajustes).

     El menu de pausa de GTA pide sus colores al juego (GET_HUD_COLOUR). Las
     clases que pintan las filas estan repetidas en muchos .gfx (tambien los
     del modo online) y no siempre manda la copia editada, asi que la paleta
     se pone desde aqui, que vale para todas:

     - Mientras el menu de pausa esta abierto, se cambian los colores del HUD
       que usa: el fondo de pausa a gris, el blanco (las letras) a tinta y el
       negro (la letra de lo elegido) a blanco.
     - Al cerrarlo se devuelven los de antes, para que el resto del juego no
       se entere.
     - El acento (FREEMODE 116 / FREEMODE_DARK 123) va siempre puesto: es lo
       que pinta de rosa (o naranja en Nacion) la pestaña y lo elegido. ]]

local ACENTO = {
    origen = { claro = { 216, 27, 85 }, oscuro = { 179, 18, 63 } },
    nacion = { claro = { 255, 146, 48 }, oscuro = { 227, 108, 0 } },
}

--[[ Siempre puestos: solo los usan los menus de GTA, y algunos fondos (la
     lista de ajustes) se pintan una sola vez al montarse el menu, antes de
     que este hilo vea que se ha abierto. ]]
local SIEMPRE = {
    [117] = { 196, 198, 202, 255 },  -- PAUSE_BG: el panel gris
    [71]  = { 220, 221, 224, 255 },  -- MENU_DIMMED: pieza gris clara
}

--[[ Solo con el menu abierto. Los textos ya son tinta de serie en los .gfx
     (texto_tinta.py), y GTA los tiñe con WHITE: aqui WHITE pasa al acento,
     que deja la tinta casi igual y hace de fondo de lo ELEGIDO. Asi tambien
     los recuadros de las teclas (que el juego tiñe con WHITE) salen en el
     acento con la letra negra. BLACK no se toca. ]]
local EN_PAUSA = {
    [1] = 'acento',  -- WHITE: lo ELEGIDO en el acento (rosa / naranja)
}

local function acento()
    local marca = GetConvar('origen:marca', 'origen')
    local c = ACENTO[marca] or ACENTO.origen
    ReplaceHudColourWithRgba(116, c.claro[1], c.claro[2], c.claro[3], 255)
    ReplaceHudColourWithRgba(123, c.oscuro[1], c.oscuro[2], c.oscuro[3], 255)
    for i, v in pairs(SIEMPRE) do
        ReplaceHudColourWithRgba(i, v[1], v[2], v[3], v[4])
    end
end

local originales = nil

local function ponerPaleta()
    if originales then return end
    originales = {}
    for i, c in pairs(EN_PAUSA) do
        local r, g, b, a = GetHudColour(i)
        originales[i] = { r, g, b, a }
        if c == 'acento' then
            local m = ACENTO[GetConvar('origen:marca', 'origen')] or ACENTO.origen
            c = { m.claro[1], m.claro[2], m.claro[3], 255 }
        end
        ReplaceHudColourWithRgba(i, c[1], c[2], c[3], c[4])
    end
end

local function quitarPaleta()
    if not originales then return end
    for i, c in pairs(originales) do
        ReplaceHudColourWithRgba(i, c[1], c[2], c[3], c[4])
    end
    originales = nil
end

--[[ El pie de teclas: la caja de GTA va oculta en el .gfx y esta es la
     nuestra (ui/index.html), solo con el menu de pausa abierto. ]]
--[[ El menu de Ajustes se abre con ActivateFrontendMenu y el servidor apaga
     la pausa normal cada fotograma (origen_inventory), asi que
     IsPauseMenuActive() no siempre lo ve: GetPauseMenuState() sí. ]]
local function menuAbierto()
    return IsPauseMenuActive() or GetPauseMenuState() ~= 0
end

local pieVisto = nil
local function pie(ver)
    if ver == pieVisto then return end
    pieVisto = ver
    SendNUIMessage({ accion = 'origen_ajustes:pie', ver = ver, marca = GetConvar('origen:marca', 'origen') })
    --[[ 07/10: con Ajustes abierto solo se ve el menu. Se avisa a los HUD
         propios (origen_map, origen_quests, origen_hud, origen_notify) y queda
         en el statebag para quien prefiera mirarlo. ]]
    TriggerEvent('origen:ajustes', ver == true)
    LocalPlayer.state:set('ajustes', ver == true, false)
end

CreateThread(function()
    acento()
    while true do
        if menuAbierto() then
            ponerPaleta()
            pie(true)
            Wait(0)
        else
            quitarPaleta()
            pie(false)
            Wait(100)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        quitarPaleta()
        if pieVisto then TriggerEvent('origen:ajustes', false) end
        LocalPlayer.state:set('ajustes', false, false)
    end
end)
