-- El árbitro de la E (y de la G) de los módulos de la casa.
--
-- Ascensores, plataformas giratorias, luces, pasos secretos, muebles que se
-- abren y sillas ofrecían cada uno su «E» por su cuenta: con dos cosas a mano
-- (un interruptor junto a una puerta secreta, una silla sobre una plataforma)
-- se pisaban el cartel y una sola pulsación hacía las dos. Ahora cada módulo
-- OFRECE lo suyo y aquí se enseña y se ejecuta UNA sola: la de más prioridad
-- y, a igual prioridad, la más cercana.
--
--   Tecla.Ofrecer('luces', {
--       texto = 'Apagar la luz',     -- lo que dice el cartel de la E
--       prioridad = 50,              -- gana la mayor (de serie 50)
--       dist = 0.8,                  -- a igual prioridad, la menor
--       hacer = function() … end,    -- al pulsar la E (en su propio hilo)
--       oculto = false,              -- true: sin cartel (un paso secreto para quien no tiene llave).
--                                    -- Una oferta oculta pierde siempre contra una a la vista.
--       g = { texto = 'Ajustes', hacer = function() … end },   -- opcional: la segunda tecla (sin texto no se anuncia)
--   })
--   Tecla.Retirar('luces')           -- ya no ofrece nada (o Tecla.Ofrecer('luces', nil))
--
-- La oferta hay que renovarla: caduca sola al segundo y medio, por si el hilo
-- del módulo se cae. El módulo decide cada cuánto mira (no hace falta cada
-- fotograma: las teclas se miran aquí).
--
-- Lo de siempre del housing (la puerta de salir, las puertas, el almacén, el
-- ropero, la tele) no pasa por aquí: pinta su cartel con Internal.DrawText y
-- mira su tecla. Mientras uno de esos carteles está puesto, manda él: aquí no
-- se enseña ni se ejecuta nada.
--
-- Este fichero se carga después que los módulos (orden alfabético), pero
-- todos llaman a Tecla.* desde sus hilos, nunca al cargar.
Tecla = {}

local CADUCA = 1500
local ofertas = {}      -- módulo → oferta
local nucleo = false    -- el housing de siempre tiene su cartel puesto
local mostrado = nil    -- el cartel que tiene puesto el árbitro (su firma), o nil
local menuAjeno = false -- otro menú tiene la pantalla (la cinta de decorar, el radial…)
local casaVista = nil
local pintando = false  -- la llamada a Internal.* es del propio árbitro

AddEventHandler('qv2:suppressHud', function(fuera)
    menuAjeno = fuera == true
end)

-- El aviso llega de otros recursos (tienda, radial, ropa…) en dos tiempos: «me pongo»
-- y «me quito». Si el recurso que lo puso se reinicia o falla con su menú abierto, el
-- «me quito» no llega nunca y aquí se quedaba enganchado: no salía ninguna E en la casa
-- (plataformas, luces, ascensores…) hasta reiniciar. Si pasan 4 s sin ningún menú con
-- el ratón y sin estar construyendo ni decorando, se da por quitado.
CreateThread(function()
    local desde = nil
    while true do
        Wait(1000)
        local construyendo = (Furniture and Furniture.active) or (Obra ~= nil and Obra.CintaAbierta ~= nil and Obra.CintaAbierta() == true)
        if menuAjeno and not IsNuiFocused() and not IsPauseMenuActive() and not construyendo then
            desde = desde or GetGameTimer()
            if GetGameTimer() - desde > 4000 then
                menuAjeno, desde = false, nil
                TriggerEvent('origen_housing:sinMenuAjeno')
            end
        else
            desde = nil
        end
    end
end)

-- ── Saber cuándo manda el housing de siempre ────────────────────────────
local pintar, borrar = Internal.DrawText, Internal.HideText

Internal.DrawText = function(texto, tecla, ...)
    if not pintando then nucleo, mostrado = true, nil end
    return pintar(texto, tecla, ...)
end

Internal.HideText = function(...)
    if not pintando then nucleo, mostrado = false, nil end
    return borrar(...)
end

local function Cartel(o, g)
    pintando = true
    local ok = false
    local segunda = g and g.texto or nil    -- (una G sin texto funciona, pero no se anuncia)
    if segunda and GetResourceState('origen_notify') == 'started' then
        -- con segunda tecla: el cartel del servidor la dibuja aparte
        ok = pcall(function() exports.origen_notify:DrawText('E', o.texto, { 'G', segunda }) end)
    end
    if not ok then pcall(pintar, segunda and (o.texto .. '  ·  [G] ' .. segunda) or o.texto, 'E') end
    pintando = false
end

local function SinCartel()
    if not mostrado then return end
    mostrado = nil
    pintando = true
    pcall(borrar)
    pintando = false
end

-- ── Lo que usan los módulos ─────────────────────────────────────────────
function Tecla.Ofrecer(modulo, oferta)
    if type(oferta) ~= 'table' or type(oferta.hacer) ~= 'function' then
        ofertas[modulo] = nil
        return
    end
    oferta.hasta = GetGameTimer() + CADUCA
    ofertas[modulo] = oferta
end

function Tecla.Retirar(modulo)
    ofertas[modulo] = nil
end

--- ¿Hay algo que impide ofrecer la E ahora mismo? (un menú delante, decorando…)
function Tecla.Bloqueada()
    if menuAjeno or IsNuiFocused() or IsPauseMenuActive() then return true end
    if IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true or LocalPlayer.state.inLastStand == true then return true end
    if Furniture and Furniture.active then return true end
    return Obra ~= nil and Obra.CintaAbierta ~= nil and Obra.CintaAbierta() == true
end

local function Mejor(ahora)
    local mejor = nil
    for modulo, o in pairs(ofertas) do
        if o.hasta < ahora then
            ofertas[modulo] = nil
        elseif not mejor then
            mejor = o
        else
            local a, b = o.oculto and 0 or 1, mejor.oculto and 0 or 1
            local pa, pb = o.prioridad or 50, mejor.prioridad or 50
            if a > b or (a == b and (pa > pb or (pa == pb and (o.dist or 0.0) < (mejor.dist or 0.0)))) then mejor = o end
        end
    end
    return mejor
end

-- Un mueble puede ser a la vez de los que se abren (almacenajes: un sillón que se
-- reclina, una tumbona que sube el respaldo) y de los de sentarse (especiales). La
-- de más prioridad se quedaba la E y la otra no salía nunca: no había forma de
-- sentarse en el reclinable. Cuando la que gana no trae su propia G, la de su
-- pareja sale en la G: «E Reclinar · G Sentarse» y, ya sentado, «E Levantarse · G Reclinar».
local PAREJA = { almacenajes = 'especiales', especiales = 'almacenajes' }

local function Segunda(o, ahora)
    if o.g or o.oculto then return nil end
    for modulo, otra in pairs(ofertas) do
        if otra == o then
            local s = PAREJA[modulo] and ofertas[PAREJA[modulo]] or nil
            if s and not s.oculto and type(s.texto) == 'string' and s.hasta >= ahora then return s end
            return nil
        end
    end
    return nil
end

local function Lanzar(o, hacer)
    -- la que se ejecuta se retira: su módulo la volverá a ofrecer si sigue valiendo
    for modulo, otra in pairs(ofertas) do
        if otra == o then ofertas[modulo] = nil end
    end
    SinCartel()
    CreateThread(function()
        local ok, err = pcall(hacer)
        if not ok then print(('^3[origen_housing]^0 tecla: %s'):format(tostring(err))) end
    end)
end

CreateThread(function()
    while true do
        local espera = 250
        -- al cambiar de casa (o salir) no vale lo que hubiera: ni ofertas viejas ni un cartel colgado
        local casa = currentInteriorHouseID or currentExteriorHouseID or false
        if casa ~= casaVista then
            casaVista, nucleo = casa, false
            ofertas = {}
        end
        local ahora = GetGameTimer()
        local o = next(ofertas) and Mejor(ahora) or nil
        if o and (nucleo or Tecla.Bloqueada()) then o = nil end
        if o then
            espera = 0
            -- la G: la suya o, si no trae, la de su pareja (ver PAREJA)
            local pareja = Segunda(o, ahora)
            local g = o.g or pareja
            if o.oculto then
                SinCartel()
            else
                local firma = o.texto .. '|' .. (g and g.texto or '')
                if mostrado ~= firma then
                    Cartel(o, g)
                    mostrado = firma
                end
            end
            if IsControlJustReleased(0, 38) then
                Lanzar(o, o.hacer)
            elseif g and type(g.hacer) == 'function' and IsControlJustReleased(0, 47) then
                Lanzar(pareja or o, g.hacer)
            end
        else
            SinCartel()
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() and mostrado then pcall(borrar) end
end)
