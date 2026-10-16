--[[ ══ El radial ════════════════════════════════════════════════════════════

     El menu de acceso rapido, en el ESC. Un toque lo deja abierto para
     elegir con calma; mantenerlo, pasar el raton por una opcion y soltar la
     elige directamente.

     No abre nada suyo: cada opcion lleva a la pantalla que ya existe --el
     inventario y sus pestañas, su mapa grande, el menu de animaciones--. Si
     esa pantalla no esta en marcha, la opcion sale apagada.

     Mientras esta abierto se puede andar y conducir, como con el inventario:
     el teclado sigue llegando al juego y solo se apaga lo que no toca (ver
     BloquearControles).

     Por eso los atajos son numeros, por orden de arriba abajo, y no letras: con el teclado llegando al juego, la K abriria tambien las
     llaves del coche y la R recargaria. Los numeros son los huecos del
     inventario, que no hacen nada mientras hay una pantalla con el foco.

     El ESC era de origen_pausemenu, que ya no existe: su mapa vive ahora en la
     pestaña Ciudad del inventario, y a el se llega por la opcion Mapa. ]]

local INVENTARIO = 'origen_inventory'

local function EnMarcha(recurso)
    return GetResourceState(recurso) == 'started'
end

--[[ Pestañas del inventario por su export, que es la puerta que usan los
     demas paneles del riel. El tercer argumento es la vista de dentro de la
     pestaña: Reportes vive dentro de Ciudad. ]]
local function Pestana(cual, vista)
    return function()
        exports[INVENTARIO]:AbrirEnPestana(cual, false, vista)
    end
end

--[[ Los accesos del riel --admin, banda, negocio, policia-- abren el panel de
     lo suyo por el export del inventario, que vuelve a comprobar que te toca
     antes de abrir nada. ]]
local function Acceso(cual)
    return function()
        exports[INVENTARIO]:AbrirAcceso(cual, false)
    end
end

--[[ Cada opcion puede llevar:

     `alInventario`  abre el inventario. Importa para el rastreador de
                     misiones: ver Cerrar.
     `siempre`       se puede usar aunque estes herido o esposado. Los
                     ajustes del juego --quitarselos a alguien tirado en el
                     suelo lo dejaria sin poder ni cambiar el volumen-- y el
                     panel de admin, que un admin puede necesitar justo ahi.
     `mostrar`       si devuelve false, la opcion NO SALE (no sale apagada:
                     no sale). Vehiculo fuera de un coche.
     `acceso`        uno de los accesos del riel del inventario. Sale solo si
                     el inventario dice que te toca, y con el nombre que el
                     diga (el de emergencias pone Policia, EMS...).
     `largo`         lo que abre si se MANTIENE pulsada con el raton (2 s)
                     en vez de pulsarla: { label, abrir }.
     `escondeMisiones` la pantalla que abre ocupa el canto derecho y se
                     encarga ella de esconder y devolver las misiones. ]]
local OPCIONES = {
    {
        id = 'bag', label = 'Inventario',  -- 05/10: en las dos marcas (antes solo Origen)
        recurso = INVENTARIO, alInventario = true,
        --[[ Por el comando y no por la pestaña: es lo mismo que la F2, y la F2
             sabe abrir el maletero o la guantera si estas al lado de un coche,
             o la bolsa que tengas a los pies. ]]
        abrir = function() ExecuteCommand('origen_inventory') end,
    },
    {
        id = 'anims', label = 'Animaciones',  -- 05/10: en las dos marcas
        recurso = 'origen_anims',
        abrir = function()
            if exports.origen_anims:isLimited() then return end
            exports.origen_anims:toggleMenu()
        end,
    },
    {
        --[[ 09/10: un solo boton en las dos marcas. Abre el vipsystem en su
             cartel; lo que en Nacion eran dos entradas mas («Tienda», con la
             cuenta y el codigo, y «Mis cosas») son pestañas de dentro. ]]
        id = 'shop', label = 'Cosméticos',
        recurso = 'origen_vipsystem', escondeMisiones = true,
        -- Solo sale si esta encendido en el panel de admin del vipsystem
        -- (Ajustes → «Cosméticos (tienda)»); apagado, que es como viene, no sale.
        mostrar = function()
            return GlobalState.origenCosmeticosAbiertos == true
        end,
        abrir = function()
            local ok, err = pcall(function() exports['origen_vipsystem']:openUserStore() end)
            if not ok then print(('^1[origen_hud]^0 No se pudo abrir Cosméticos: %s'):format(err)) end
        end,
    },
    {
        id = 'map', label = 'Mapa',
        recurso = INVENTARIO, alInventario = true,
        -- El mapa grande, que se abre al lado de la pestaña Ciudad.
        abrir = Pestana('city', 'mapa'),
    },
    {
        id = 'reports', label = 'Reportes',
        recurso = INVENTARIO, alInventario = true,
        --[[ Se puede aunque estes tirado en el suelo, que es justo cuando mas
             falta hace poder avisar al staff. No abre el inventario: el
             export abre SOLO la pantalla de reportes --una pestaña, sin
             accesos y sin salida al resto del panel-- cuando estas impedido,
             y el panel normal cuando estas bien. ]]
        siempre = true,
        abrir = function() exports[INVENTARIO]:AbrirReportes(false) end,
    },
    {
        id = 'vehicle', label = 'Vehículo',
        recurso = INVENTARIO, alInventario = true,
        -- La pestaña solo existe dentro de un coche, igual que en el riel.
        mostrar = function() return IsPedInAnyVehicle(PlayerPedId(), false) end,
        abrir = Pestana('vehicle'),
    },
    {
        id = 'player', label = 'Personaje',
        recurso = INVENTARIO, alInventario = true,
        abrir = Pestana('personal'),
    },
    {
        id = 'settings', label = 'Ajustes',
        siempre = true,
        --[[ Los del juego: graficos, sonido, teclas. Los mismos que el acceso
             Ajustes de la pestaña Ciudad, y con la misma llamada. ]]
        abrir = function()
            ActivateFrontendMenu(GetHashKey('FE_MENU_VERSION_LANDING_MENU'), false, -1)
        end,
    },
    {
        --[[ Origen Graficos: el aspecto del juego a gusto de cada uno (contraste,
             niebla, noche, neones, detalle). El panel es de origen_visuals. ]]
        id = 'graficos', label = 'Gráficos',
        recurso = 'origen_visuals', escondeMisiones = true,
        abrir = function()
            local ok, err = pcall(function() exports.origen_visuals:Abrir() end)
            if not ok then print(('^1[origen_hud]^0 No se pudo abrir Origen Gráficos: %s'):format(err)) end
        end,
    },
    {
        id = 'missions', label = 'Misiones',
        recurso = INVENTARIO, alInventario = true,
        abrir = Pestana('quests'),
    },

    -- Los de cargo: cada uno solo si te corresponde.
    { id = 'negocio', label = 'Negocio', recurso = INVENTARIO, acceso = 'negocio', abrir = Acceso('negocio') },
    { id = 'policia', label = 'Policía', recurso = INVENTARIO, acceso = 'policia', abrir = Acceso('policia') },
    { id = 'banda', label = 'Banda', recurso = INVENTARIO, acceso = 'banda', abrir = Acceso('banda') },
    {
        id = 'admin', label = 'Administración', recurso = INVENTARIO, acceso = 'admin', siempre = true,
        -- Un toque: las acciones rapidas. Mantenido 2 s: el panel completo.
        abrir = Acceso('admin'),
        largo = {
            label = 'Panel completo',
            abrir = function() exports.origen_admin:AbrirPanelCompleto() end,
        },
    },
}

--[[ Los accesos que le tocan a este jugador ahora mismo, por id. Los calcula
     el inventario para su riel (GetRiel), preguntando a cada recurso --a
     origen_admin si tienes permiso, a origen_ilegalv2 si tienes banda...--.
     Preguntarlo tambien aqui seria tener la misma regla escrita dos veces. ]]
local function AccesosDelJugador()
    local salida = {}
    if not EnMarcha(INVENTARIO) then return salida end

    local ok, riel = pcall(function() return exports[INVENTARIO]:GetRiel() end)
    if not ok or type(riel) ~= 'table' then return salida end

    for _, boton in ipairs(riel) do
        if boton.tipo == 'acceso' then salida[boton.id] = boton end
    end
    return salida
end

local MARCA = OrigenMarca or 'origen'
local DE_ESTA_MARCA = {}
for _, o in ipairs(OPCIONES) do
    if not o.marca or o.marca == MARCA then DE_ESTA_MARCA[#DE_ESTA_MARCA + 1] = o end
end
OPCIONES = DE_ESTA_MARCA

local POR_ID = {}
for _, o in ipairs(OPCIONES) do POR_ID[o.id] = o end

--- Herido o esposado, o nil si estas bien.
local function Impedimento()
    if IsEntityDead(PlayerPedId()) then return 'Estás herido' end

    local ok, datos = pcall(function() return exports.qbx_core:GetPlayerData() end)
    local md = ok and datos and datos.metadata
    if not md then return end
    if md.isdead or md.inlaststand then return 'Estás herido' end
    if md.ishandcuffed then return 'Estás esposado' end
end

--- Por que no se puede usar ahora, o nil si se puede.
local function Motivo(o, impedimento)
    if o.recurso and not EnMarcha(o.recurso) then return 'No disponible' end
    if impedimento and not o.siempre then return impedimento end
    if o.motivo then return o.motivo() end
end

local abierto = false
local cerradoEn = 0

--[[ La ultima vez que habia OTRA pantalla con el foco.

     Casi todas las pantallas se cierran con ESC. Si la pantalla suelta el foco
     antes de que el juego procese la tecla, al juego le llega un ESC "limpio"
     y abriria el radial justo al cerrar el inventario. Mirar IsNuiFocused() en
     ese instante no sirve --ya es false--; mirar si lo era hace nada, si. ]]
local ultimoFocoAjeno = 0

CreateThread(function()
    while true do
        if not abierto and IsNuiFocused() then ultimoFocoAjeno = GetGameTimer() end
        Wait(100)
    end
end)

local function PuedeAbrir()
    if abierto then return false end
    local ahora = GetGameTimer()
    -- Soltar el ESC despues de cerrarlo con el mismo ESC no debe reabrirlo.
    if ahora - cerradoEn < 300 then return false end
    --[[ Tirado en el suelo, la pantalla de muerte de origen_ambulancejob tiene
         el foco TODO el rato (con KeepInput, para poder hablar). Esa no cuenta
         como "otra pantalla": es justo cuando mas falta hace el radial, para
         reportar. Se aparta sola mientras el radial esta abierto. ]]
    local caido = LocalPlayer.state.samsCaido ~= nil
    if not caido then
        if ahora - ultimoFocoAjeno < 350 then return false end
        if IsNuiFocused() then return false end
    end
    if IsPauseMenuActive() or GetPauseMenuState() ~= 0 then return false end
    -- Dentro de una repeticion del admin el ESC es salir de ella.
    if LocalPlayer.state.enRepeticion then return false end
    -- Mirando las cámaras de un negocio el ESC es dejar de mirar
    -- (origen_businesses/source/client/camaras.lua).
    if LocalPlayer.state.mirandoCamara then return false end
    if LocalPlayer.state.isLoggedIn == false then return false end
    return true
end

--[[ El rastreador de misiones de origen_quests ocupa el mismo canto derecho
     que el radial, y el arco se le pintaba encima. Se esconde al abrir y
     vuelve al cerrar, por el mismo evento local que usa el inventario. ]]
local function Misiones(visible)
    TriggerEvent('qv2:suppressHud', not visible)
end

--- Aviso local para quien ocupe el mismo canto (la pantalla de muerte de
--- origen_ambulancejob se aparta mientras el radial esta abierto).
local function Avisar(abiertoAhora)
    TriggerEvent('origen_hud:radial', abiertoAhora)
end

--[[ Si se va al inventario (Reportes, desde el suelo), el aviso de "cerrado"
     espera a que se cierre el inventario: si no, la pantalla de muerte
     volveria a salir por debajo de la de reportes. ]]
local function AvisarAlSoltar(aDondeVa)
    if not (aDondeVa and aDondeVa.alInventario and LocalPlayer.state.samsCaido ~= nil) then
        Avisar(false)
        return
    end
    CreateThread(function()
        Wait(1500)
        while not abierto do
            local ok, inv = pcall(function() return exports[INVENTARIO]:IsInventoryOpen() end)
            if not (ok and inv) then break end
            Wait(250)
        end
        if not abierto then Avisar(false) end
    end)
end

--[[ Con el radial abierto el minimapa de origen_map se ve SIEMPRE, vayas a
     pie o en coche (16/09/2026). Se pide y
     se suelta a nombre de este recurso; si origen_map no esta, no pasa nada. ]]
local function Minimapa(visible)
    if GetResourceState('origen_map') ~= 'started' then return end
    pcall(function() exports.origen_map:Mostrar(visible) end)
end

--[[ Lo que se apaga mientras el radial esta abierto. Es la misma lista que
     usa el inventario (DisableKeys en origen_inventory/client/function.lua):
     andar, correr y conducir siguen, y se va lo que choca con el raton o con
     el propio radial.

       1 2 106           mirar con el raton (a pie y en coche): el raton es
                         del cursor
       24 25 257         disparar y apuntar: elegir con clic dispararia
       140-143 263 264   los seis golpes cuerpo a cuerpo
       68 69 70 91 92    apuntar y disparar desde un vehiculo
       14-17 99 100      la rueda del raton cambia de arma: aqui cambia de
       261 262           opcion
       157-165           los numeros eligen arma: aqui eligen opcion
       18 22 45 80       Enter, saltar, recargar y camara del coche
       200 199 177 202   ESC y P: son del radial, no del juego

     DisablePlayerFiring por encima de todo: el golpe entra por controles
     distintos segun el arma, y cortarlo en la raiz es lo unico seguro. ]]
local CONTROLES = {
    1, 2, 106, 24, 25, 257,
    140, 141, 142, 143, 263, 264,
    68, 69, 70, 91, 92,
    14, 15, 16, 17, 99, 100, 261, 262,
    157, 158, 159, 160, 161, 162, 163, 164, 165,
    18, 22, 45, 80,
    200, 199, 177, 202,
}

local function BloquearControles()
    CreateThread(function()
        local jugador = PlayerId()
        while abierto do
            DisablePlayerFiring(jugador, true)
            for i = 1, #CONTROLES do
                DisableControlAction(0, CONTROLES[i], true)
            end
            Wait(0)
        end
    end)
end

--[[ `abierto` manda sobre la camara: mientras sea true, el bucle de arriba
     apaga mirar con el raton y disparar CADA fotograma, y ESC no vuelve a
     abrir (PuedeAbrir). Si se queda en true sin radial delante, el jugador
     se queda sin camara para siempre aunque el raton ya este suelto.

     Pasaba (27/09, «el raton se queda en pantalla»): el foco se lo podia
     quitar alguien que no pasaba por Cerrar —el `soltarraton`, el vigilante
     de foco.lua, el `unfocus` del App.vue de esta misma pagina con un ESC que
     llega antes de que el radial se pinte— y `abierto` seguia en true.
     Comprobado en el juego: tras `soltarraton`, camara bloqueada.

     Tres redes, todas acaban en Cerrar:
     - OrigenFoco.AlSoltar: el foco se ha soltado a la fuerza.
     - Sin foco: el radial SIEMPRE lo tiene mientras esta abierto; si lo
       pierde medio segundo, esta roto.
     - La pagina: cada segundo se le pregunta si el radial se ve. Esta pagina
       lleva el HUD fijo, asi que el vigilante general de foco.lua siempre
       oye «se ve» y aqui no sirve: hay que preguntar por el radial en
       concreto. Dos «no» seguidos y se cierra. Sin respuesta no se toca
       (pagina vieja o colgada: para eso esta el vigilante general). ]]
local preguntaRadial = 0
local noSeVe = 0

RegisterNUICallback('radial:sigo', function(data, cb)
    cb({})
    if type(data) ~= 'table' or tonumber(data.n) ~= preguntaRadial then return end
    if data.abierto == false then noSeVe = noSeVe + 1 else noSeVe = 0 end
end)

local Cerrar

local vueltaRadial = 0

--- El foco de ESTE recurso: IsNuiFocused() es de todo el cliente y seguiria
--- en true si el foco lo tuviera otro. Sin el vigilante (recurso viejo), el
--- global.
local function TengoFoco()
    if OrigenFoco and OrigenFoco.Tiene then return OrigenFoco.Tiene() end
    return IsNuiFocused()
end

local function VigilarRadial()
    vueltaRadial = vueltaRadial + 1
    local mia = vueltaRadial
    CreateThread(function()
        local sinFocoDesde = nil
        local siguiente = GetGameTimer() + 1000
        preguntaRadial = preguntaRadial + 1
        noSeVe = 0

        -- Una apertura nueva se lleva su propio hilo: este se retira.
        while abierto and vueltaRadial == mia do
            local ahora = GetGameTimer()

            if TengoFoco() then
                sinFocoDesde = nil
            elseif not sinFocoDesde then
                sinFocoDesde = ahora
            elseif ahora - sinFocoDesde > 500 then
                Cerrar()
                break
            end

            if noSeVe >= 2 then
                Cerrar()
                break
            end

            if ahora >= siguiente then
                siguiente = ahora + 1000
                preguntaRadial = preguntaRadial + 1
                SendNUIMessage({ action = 'radial:sigues', n = preguntaRadial })
            end

            Wait(100)
        end
    end)
end

local function Abrir()
    if not PuedeAbrir() then return end

    local impedimento = Impedimento()
    local accesos = AccesosDelJugador()
    local lista = {}
    for _, o in ipairs(OPCIONES) do
        local label = o.label
        local sale = true

        if o.mostrar and not o.mostrar() then sale = false end
        if o.acceso then
            local boton = accesos[o.acceso]
            if boton then label = boton.label or label else sale = false end
        end

        if sale then
            local n = #lista + 1
            --[[ El atajo es su posicion: 1 la de arriba. Del 10 en adelante
                 --con todos los cargos a la vez puede haber doce-- el 10 es el
                 0 y los dos ultimos se quedan sin numero. ]]
            local tecla = n <= 9 and tostring(n) or (n == 10 and '0' or '')
            lista[n] = {
                id = o.id, label = label, key = tecla, motivo = Motivo(o, impedimento),
                largo = o.largo and o.largo.label or nil,
            }
        end
    end

    abierto = true
    Misiones(false)
    Avisar(true)
    Minimapa(true)
    SetNuiFocus(true, true)
    -- El teclado sigue llegando al juego: se anda y se conduce con el abierto.
    SetNuiFocusKeepInput(true)
    BloquearControles()
    SendNUIMessage({ action = 'radial:abrir', items = lista })
    VigilarRadial()
end

--[[ `aDondeVa` es la opcion elegida, o nil si se cierra sin elegir.

     Si se va al inventario, las misiones NO se devuelven aqui: el inventario
     ocupa ese mismo canto y las esconde el solo al abrirse, y las devuelve al
     cerrarse. Devolverlas ahora las haria asomar un instante entre el radial
     y el inventario. ]]
Cerrar = function(aDondeVa)
    if not abierto then return end
    abierto = false
    cerradoEn = GetGameTimer()
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    -- Por si se cierra desde aqui y no desde la pagina (redes de VigilarRadial,
    -- foco soltado a la fuerza): que la pagina no se quede con el radial puesto.
    if not aDondeVa then SendNUIMessage({ action = 'radial:cerrar' }) end
    Minimapa(false)
    AvisarAlSoltar(aDondeVa)

    if aDondeVa and aDondeVa.escondeMisiones then return end

    if not (aDondeVa and aDondeVa.alInventario) then
        Misiones(true)
        return
    end

    --[[ Pero el inventario puede negarse a abrir --ocupado, en plena
         animacion...--, y entonces nadie las devolveria. Si a segundo y medio
         no esta abierto, se devuelven desde aqui. ]]
    SetTimeout(1500, function()
        if abierto then return end
        local ok, abiertoInv = pcall(function() return exports[INVENTARIO]:IsInventoryOpen() end)
        if not (ok and abiertoInv) then Misiones(true) end
    end)
end

--[[ Nombre nuevo a proposito, sin nada que ver con `pauseMenu`: el ESC por
     defecto solo se aplica la primera vez que el perfil del jugador ve el
     comando, y este no lo ha visto nadie. ]]
lib.addKeybind({
    name = 'origen_radial',
    description = 'Menú radial',
    defaultKey = 'ESCAPE',
    onPressed = Abrir,
    --[[ Casi siempre el que se entera de que sueltas es la pagina, que para
         entonces ya tiene el foco. Pero si sueltas antes de que lo coja, solo
         lo sabe el juego: se le pasa a la pagina y ella decide. ]]
    onReleased = function()
        if abierto then SendNUIMessage({ action = 'radial:soltar' }) end
    end,
})

RegisterNUICallback('radial:cerrar', function(_, cb)
    Cerrar()
    cb('ok')
end)

RegisterNUICallback('radial:elegir', function(data, cb)
    cb('ok')

    local o = POR_ID[data and data.id]
    if not o or Motivo(o, Impedimento()) then Cerrar() return end
    Cerrar(o)

    --[[ Un respiro antes de abrir: el foco se acaba de soltar y el comando del
         inventario se planta si todavia ve una NUI con el foco puesto. ]]
    -- Mantenida en vez de pulsada, si la opcion tiene esa segunda puerta.
    local abrir = (data.largo == true and o.largo) and o.largo.abrir or o.abrir

    SetTimeout(100, function()
        local ok, err = pcall(abrir)
        if not ok then
            print(('^1[origen_hud]^0 El radial no pudo abrir "%s": %s'):format(o.id, err))
        end
    end)
end)

--[[ Si el recurso se para con el radial abierto, el foco se queda puesto y
     sin nada delante: raton preso hasta reconectar. Y las misiones, escondidas
     para siempre. ]]
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and abierto then
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
        Misiones(true)
    end
end)

exports('RadialAbierto', function() return abierto end)

--[[ El foco se lo ha quitado alguien que no es Cerrar (`soltarraton`, el
     vigilante de foco.lua): se cierra igual, para que `abierto` no se quede
     en true bloqueando la camara. ]]
if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function() Cerrar() end)
end

--[[ Otra pantalla coge el raton con el radial abierto (el movil con su
     tecla, que llega al juego por el KeepInput): el radial se cierra. Si se
     quedara debajo, al cerrarse la otra seguiria «abierto» sin teclado y con
     la camara bloqueada. ]]
AddEventHandler('origen:foco:estado', function(recurso, tiene)
    if tiene and abierto and recurso ~= GetCurrentResourceName() then Cerrar() end
end)

--- Para el `unfocus` de client/main.lua: el App.vue de la pagina suelta el
--- foco con ESC, y si el radial estaba abierto hay que cerrarlo con el.
function RadialCerrarDesdeFuera()
    Cerrar()
end
