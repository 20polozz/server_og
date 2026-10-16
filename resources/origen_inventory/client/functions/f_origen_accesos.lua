--[[
    Accesos desde el riel del inventario.

    Botones que no son pestañas: no cambian lo que se ve en el panel, cierran
    el inventario y abren otro menu. Cada uno sale solo si al jugador le
    corresponde —admin, banda, crew, negocio, policia—; si no, no hay boton.

    Cada uno abre el panel de lo suyo —el de banda, el de crew, el de negocio,
    el de admin, el de policia—, todos con este mismo riel al canto para poder
    volver. Y son la unica via: las teclas que los abrian (F5 las misiones, F6
    la banda, F7 el negocio y la policia) estan quitadas.

    La comprobacion NO se hace en la interfaz. Si la hiciera, bastaria con
    toquetear la NUI para que apareciera el boton de admin. Aqui se pregunta a
    cada recurso y se vuelve a preguntar al pulsar.
]]

--- Los accesos que se vieron por ultima vez, ya con su nombre y su icono. Lo
--- lee la interfaz, que solo pinta.
local Accesos = {}

--- Envuelve un export en pcall: un recurso puede estar arrancado y aun asi no
--- tener registrado el export si acaba de reiniciarse. Sin esto, una llamada
--- fallida se lleva por delante el riel entero.
local function Preguntar(recurso, metodo, ...)
    if GetResourceState(recurso) ~= 'started' then return nil end
    local ok, valor = pcall(function(...)
        return exports[recurso][metodo](exports[recurso], ...)
    end, ...)
    if not ok then return nil end
    return valor
end

--- ¿Puede abrir el menu rapido de admin? Por rango, este o no de servicio:
--- fuera de servicio el menu rapido es justo donde se entra en servicio.
local function EsAdmin()
    local staff = Preguntar('origen_admin', 'EsStaff')
    if staff ~= nil then return staff == true end
    return Preguntar('origen_admin', 'HasPermission', 'AdminMenu') == true
end

--- ¿Pertenece a una banda? Es la misma condicion que pide OpenQuickMenu, asi
--- que el boton sale exactamente cuando el menu tendria algo que enseñar.
local function TieneBanda()
    local banda = Preguntar('origen_ilegalv2', 'GetPlayerGang')
    return banda ~= nil and banda ~= false and banda ~= ''
end

--[[ ¿Sale el botón de Banda? Teniendo banda, o pudiendo crearla (un admin te
     ha dado el permiso). Sin lo segundo, a quien acaba de recibir el permiso no
     le aparece nada y tiene que saberse el comando o esperar al móvil. Igual
     que el de Crew. Si puede o no lo sabe origen_ilegalv2. ]]
local function SaleBanda()
    return TieneBanda() or Preguntar('origen_ilegalv2', 'PuedeCrearBanda') == true
end

--[[ ¿Le toca el boton de Crew?

     Sale de dos maneras: teniendo crew, o teniendo permiso de un admin para
     crearla. La segunda importa tanto como la primera —sin ella, a quien acaba
     de recibir el permiso no le aparece nada y tiene que saberse el comando—.

     Las dos las resuelve origen_racing, que es quien las sabe; aqui solo se
     pinta el boton, igual que con la banda y con el negocio. ]]
local function TieneCrew()
    return Preguntar('origen_racing', 'SaleAccesoCrew') == true
end

--[[ ¿Sale el boton del cuerpo de emergencias, y como se llama?

     origen_police no es solo de policia: lo abren cinco categorias —policia,
     sanidad, SASPA, FIB— y cada una tiene su nombre, su icono y su color. Se
     le pregunta a el, que es quien lo sabe; escribir esa lista tambien aqui
     seria tener dos versiones de la misma regla, y esta se quedaria vieja en
     cuanto alguien toque Config.JobCategory.

     Devuelve la tabla de como presentarlo, o nil si no le toca. Una sola
     pregunta en vez de dos: si hay tabla, hay boton.

     No hace falta estar de servicio: fuera de servicio el boton ofrece
     entrar, igual que el de Negocio ofrece fichar. ]]
local function UIDeEmergencias()
    local ui = Preguntar('origen_police', 'UIDeCategoria')
    return type(ui) == 'table' and ui or nil
end

local function EsPolicia()
    return UIDeEmergencias() ~= nil
end

--[[ ¿Lleva una radio encima?

     La radio no es un permiso ni un cargo: es un objeto. El boton sale si lo
     llevas y desaparece en cuanto lo sueltas, igual que el menu de la radio
     solo se abria usando el item.

     Los nombres de los items los pone la configuracion de origen_radio
     (Config.RadioItems), asi que si mañana hay una radio de policia distinta,
     basta con añadirla alli. Aqui se pregunta por todos.

     Se mira en el inventario del cliente, que ya sabe lo que llevas: no hace
     falta ir al servidor para pintar un boton. ]]
local function LlevaRadio()
    if GetResourceState('origen_radio') ~= 'started' then return false end
    if GetResourceState('origen_inventory') ~= 'started' then return false end

    -- La lista la da origen_radio, que es quien la tiene en su Config. Copiarla
    -- aqui seria tener dos, y la segunda se quedaria vieja a la primera radio
    -- nueva. Si el export no esta, se cae en el nombre de siempre.
    local items = Preguntar('origen_radio', 'ItemsDeRadio') or { 'radio' }

    for _, item in ipairs(items) do
        local ok, tiene = pcall(function()
            return exports.origen_inventory:HasItem(item)
        end)

        if ok and tiene then return true end
    end

    return false
end

--[[ ¿Tiene alguna mascota?

     Sale con tener una, este en casa o en la calle: el panel es donde se saca,
     asi que sin boton no habria forma de sacarla.

     Lo sabe origen_pets, que es quien tiene la tabla. Aqui solo se pinta. ]]
local function TieneMascotas()
    return Preguntar('origen_pets', 'TieneMascotas') == true
end

--[[ ¿Esta DE SERVICIO en algun negocio?

     Lo dice una bolsa de estado del propio jugador, asi que se resuelve en el
     cliente. Es lo que decide QUE abre el boton, no si sale. ]]
local function DeServicio()
    local negocio = LocalPlayer.state.isOnDuty
    return negocio ~= nil and negocio ~= false and negocio ~= ''
end

--[[ ¿Pertenece a algun negocio?

     No es lo mismo que estar de servicio, y antes se confundian: el boton
     salia solo estando fichado, con lo cual el unico momento en que sirve de
     algo —cuando aun NO lo estas— era justo el que no lo enseñaba.

     La plantilla la sabe el servidor, asi que se pregunta y se guarda. Se
     guarda porque GetRiel se llama en seco desde los otros paneles y ahi no
     se puede esperar una respuesta; se refresca cada vez que se abre el
     inventario, que es cuando el dato se va a usar. ]]
local negociosCache = {}

local function RefrescarNegocios()
    if GetResourceState('origen_businesses') ~= 'started' then
        negociosCache = {}
        return negociosCache
    end

    local ok, lista = pcall(function()
        return lib.callback.await('origen_inventory:accesos:negocios', false)
    end)

    negociosCache = (ok and type(lista) == 'table') and lista or {}
    return negociosCache
end

local function TieneNegocio()
    return DeServicio() or #negociosCache > 0
end

--[[ Lo que abre el boton de Negocio: el panel de negocio, estes fichado o no.

     Antes eran dos cosas distintas —una lista para fichar cuando no lo
     estabas y el menu de trabajo cuando si—, y eso obligaba a saber de
     antemano en cual de los dos estados venias. Ahora es una sola pantalla
     que ya lo dice: el fichar es la primera de sus acciones.

     Con mas de un negocio, el propio panel enseña primero cual. Esa parte la
     resuelve origen_businesses, que es quien sabe la plantilla; aqui no hace
     falta ni preguntarla. ]]
--[[ ── El relevo entre paneles ────────────────────────────────────────────

     Los siete paneles del riel pintan LA MISMA barra del canto derecho:
     identica, en el mismo sitio y con los mismos botones. Al saltar de uno a
     otro, esa barra no tiene por que moverse; lo unico que cambia de verdad es
     la columna.

     El reparto es siempre este:

       · el que se va congela su riel, recoge SOLO la columna --260 ms-- y se
         desmonta a los 280;
       · el cliente abre el destino a los 200, o sea a mitad del recorrido, asi
         que uno acaba de salir mientras el otro ya esta entrando;
       · el que entra recibe `relevo = true` y pinta su riel YA PUESTO, sin
         deslizarlo, encima del que todavia esta ahi.

     Entre los 200 y los 280 hay dos barras en pantalla. Como son la misma, no
     se ve. Sin ese solape queda un hueco negro, que es lo que se veia antes.

     Por eso todos los abridores llevan `relevo`: es la unica forma de que el
     que entra sepa que no viene solo. ]]
local function AbrirNegocio(relevo)
    -- El comando no admite argumentos, asi que la marca se deja apuntada donde
    -- el panel de negocio la lee al abrirse.
    if relevo and GetResourceState('origen_businesses') == 'started' then
        pcall(function() exports.origen_businesses:MarcarRelevo() end)
    end
    ExecuteCommand('negocios_f7')
end

--[[ ── La red de seguridad del relevo ──────────────────────────────────────

     Quedarse sin panel se arregla volviendo a abrir. Quedarse con el foco de
     la NUI puesto y NINGUNA pantalla delante, no: el raton se queda en medio,
     la camara no responde y solo se sale reconectando. Eso no puede pasar
     nunca, asi que no basta con que cada camino este bien escrito: hace falta
     algo que lo compruebe despues.

     Al pasarle el relevo a otro panel se mira, segundo y medio mas tarde, si
     ese panel dice estar abierto. Si no lo dice y el foco sigue puesto, se
     suelta a mano.

     Segundo y medio a proposito: el destino tarda 200 ms en abrirse, y algunos
     esperan antes una respuesta del servidor --la lista de negocios, la crew--
     que puede tardar. Con menos margen se le quitaria el raton a un panel que
     todavia estaba llegando.

     Solo vigila a quien tiene el export `EstaAbierto`. Si no lo tiene no se
     puede saber si esta abierto, y ahi callarse es lo unico prudente: soltar
     el foco por si acaso se lo quitaria a un panel que funciona. ]]
local RECURSO_DE = {
    admin     = 'origen_admin',
    banda     = 'origen_ilegalv2',
    crew      = 'origen_racing',
    negocio   = 'origen_businesses',
    policia   = 'origen_police',
    mascotas  = 'origen_pets',
    radio     = 'origen_radio',
}

--[[ La misma red, para cuando el destino es una PESTAÑA del inventario.

     `AbrirEnPestana` puede no abrir nada --el inventario se niega si estas
     ocupado, herido o esposado-- y hasta ahora eso no lo vigilaba nadie: la
     red solo cubria los accesos. Si a segundo y medio el inventario no esta
     delante y el foco sigue puesto, se suelta.

     Aqui SI se puede decidir a ciegas, sin preguntarle a nadie: quien sabe si
     el inventario esta abierto es este mismo recurso. ]]
--[[ Mientras dura un relevo del riel hay DOS recursos con el foco a la vez
     (el panel que entra y el que se va). Durante ese rato el inventario no se
     cierra porque otro coja el foco: es el relevo, no otro panel encima. Lo
     apuntan AbrirEnPestana y AbrirReportes (entrando) y el paso al admin
     (saliendo, que se cierra el mismo 100 ms despues). Ver mas abajo
     'origen:foco:estado'. ]]
local relevoHasta = 0

local function RelevoEnCurso()
    relevoHasta = GetGameTimer() + 1500
end

local function VigilarPestana()
    SetTimeout(1500, function()
        if Player and Player.isOpen then return end
        if not IsNuiFocused() then return end

        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        print('^1[origen_inventory]^0 El inventario no llego a abrirse tras el relevo. Foco soltado para no dejar el raton preso.')
    end)
end

local function VigilarRelevo(cual)
    local recurso = RECURSO_DE[cual]
    if not recurso then return end

    SetTimeout(1500, function()
        if GetResourceState(recurso) ~= 'started' then return end

        local ok, abierto = pcall(function()
            return exports[recurso]:EstaAbierto()
        end)

        -- Sin export no hay forma de saberlo: mejor no tocar nada.
        if not ok then return end
        if abierto == true then return end

        -- Volvimos al inventario por el camino que sea: el foco es suyo.
        if Player and Player.isOpen then return end
        if not IsNuiFocused() then return end

        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end)
end

--[[ Banda y crew se abren por comando, que no admite argumentos: la marca de
     relevo se deja apuntada en su propio recurso justo antes. Si el export no
     esta --recurso viejo o parado-- se abre igual, solo que sin el relevo: se
     vera el riel entrar deslizando, que es feo pero no roto. ]]
--[[ Con banda abre el panel de banda (el del menú rápido, con este mismo
     riel); sin ella, el creador. Lo decide origen_ilegalv2 (AbrirDelRiel). Si
     el recurso es viejo y no tiene esa puerta, se abre el menú rápido a pelo,
     como antes. ]]
local function AbrirBanda(relevo)
    if GetResourceState('origen_ilegalv2') ~= 'started' then return end
    local ok = pcall(function() exports.origen_ilegalv2:AbrirDelRiel(relevo == true) end)
    if ok then return end
    if relevo then pcall(function() exports.origen_ilegalv2:MarcarRelevo() end) end
    ExecuteCommand('quickmenu')
end

local function AbrirCrew(relevo)
    if relevo and GetResourceState('origen_racing') == 'started' then
        pcall(function() exports.origen_racing:MarcarRelevo() end)
    end
    ExecuteCommand('crew')
end

--[[ Lo que abre el boton de Radio: el menu de origen_radio.

     Por `AbrirDelRiel` y no por `OpenRadio`, que es la puerta de la tecla y
     lleva dos guardas que aqui se cumplen las dos: el foco todavia lo tiene el
     inventario que se esta yendo, y la radio comprueba por su cuenta si llevas
     el item mirando PlayerData.items, que con este inventario no siempre trae
     nada. Por ahi se cerraba el inventario y no se abria nada.

     Se deja OpenRadio de respaldo por si el recurso todavia no tiene la puerta
     nueva. ]]
local function AbrirRadio(relevo)
    if GetResourceState('origen_radio') ~= 'started' then return end

    local ok = pcall(function() exports.origen_radio:AbrirDelRiel(relevo == true) end)
    if not ok then
        pcall(function() exports.origen_radio:OpenRadio() end)
    end
end

--- Lo que abre el boton de Mascotas: su propio panel, con este mismo riel.
local function AbrirMascotas(relevo)
    if GetResourceState('origen_pets') ~= 'started' then return end
    pcall(function() exports.origen_pets:AbrirPanel(relevo == true) end)
end

--[[ Lo que abre el boton de Policia: el menu rapido de origen_police, el de
     esposar, cachear y poner conos.

     No se llama al comando `quickaccess` a secas: por ahi el menu se abre sin
     riel, que es como se abre si alguien lo escribe en la consola. El export
     es el que dice que se viene del riel y hay que pintarlo. ]]
local function AbrirPolicia(relevo)
    if GetResourceState('origen_police') ~= 'started' then return end
    pcall(function()
        exports['origen_police']:AbrirMenuRapido(relevo == true)
    end)
end

--[[ Al arrancar se pregunta una vez, para que el riel que pintan los otros
     paneles ya sepa si hay negocio aunque todavia no se haya abierto el
     inventario ni una sola vez. ]]
CreateThread(function()
    Wait(8000)
    RefrescarNegocios()
end)

--[[ ── El riel, para los demas paneles ──────────────────────────────────

     Admin, banda, crew, negocio y policia abren cada uno su propio panel, y
     hasta ahora al entrar en uno te quedabas encerrado: el riel del inventario
     desaparecia y no habia forma de volver a Personaje o a Vehiculo sin
     cerrar y reabrir.

     La salida es que todos pinten EL MISMO riel. Para que no haya cinco copias
     de la misma lista —que se separarian a la primera— la lista se da desde
     aqui, y cada panel solo la pinta.

     Los iconos van con nombre de lucide, que es lo que usan todos. ]]
local function EnVehiculo()
    return IsPedInAnyVehicle(PlayerPedId(), false)
end

--- La misma condicion que canShowTab() en components/Header.vue: una pestaña
--- apagada en la configuracion no sale en el riel del inventario, asi que
--- tampoco puede salir en el de los demas paneles.
local function PestanaActiva(id)
    local tabs = Config and Config.UI and Config.UI.EnableTabs
    local tab = tabs and tabs[id]
    return not (tab and tab.enable == false)
end

--[[ Los accesos que le tocan a este jugador, en orden y ya con su nombre.

     Lo usan los dos: el riel que pintan los otros paneles y la interfaz del
     propio inventario. Antes la interfaz llevaba su propia copia de los
     nombres y los iconos, y por eso el de emergencias ponia "Policia" a un
     sanitario: habia dos listas y solo se arreglo una. ]]
local function AccesosDelJugador()
    local salida = {}

    local fijos = {
        { id = 'admin',   icon = 'lucide:shield-half', label = 'Admin',   sale = EsAdmin },
        { id = 'banda',   icon = 'lucide:swords',      label = 'Banda',   sale = SaleBanda },
        { id = 'crew',    icon = 'lucide:flag',        label = 'Crew',    sale = TieneCrew },
        { id = 'negocio', icon = 'lucide:briefcase',   label = 'Negocio', sale = TieneNegocio },
        { id = 'mascotas', icon = 'lucide:paw-print',  label = 'Mascotas', sale = TieneMascotas },
        { id = 'radio',    icon = 'lucide:radio',       label = 'Radio',    sale = LlevaRadio },
    }

    for _, a in ipairs(fijos) do
        if a.sale() then
            salida[#salida + 1] = { id = a.id, icon = a.icon, label = a.label }
        end
    end

    --[[ El de emergencias va aparte porque no trae su nombre puesto: se lo da
         su propio recurso, que es quien sabe si esta hablando con un agente o
         con un sanitario. ]]
    local emergencias = UIDeEmergencias()
    if emergencias then
        salida[#salida + 1] = {
            id = 'policia',
            icon = emergencias.icon,
            label = emergencias.label,
        }
    end

    return salida
end

exports('GetRiel', function(actual)
    --[[ El mismo orden que constants/tabs.ts, que es de donde saca el riel
         sus botones el propio inventario. Si aqui falta uno, al saltar a otro
         panel el riel pierde botones y se ve el salto: es la unica barra que
         se supone que no cambia. ]]
    local riel = {
        { id = 'inventory', icon = 'lucide:package-2', label = 'Inventario', tipo = 'pestana' },
    }

    if PestanaActiva('personal') then
        riel[#riel + 1] = { id = 'personal', icon = 'lucide:user-round', label = 'Personaje', tipo = 'pestana' }
    end

    -- La de vehiculo solo cuando estas dentro de uno, igual que en el panel.
    if EnVehiculo() and PestanaActiva('vehicle') then
        riel[#riel + 1] = { id = 'vehicle', icon = 'lucide:car-front', label = 'Vehículo', tipo = 'pestana' }
    end

    -- Llaves va detras de Vehiculo, como en tabs.ts.
    if PestanaActiva('keys') then
        riel[#riel + 1] = { id = 'keys', icon = 'lucide:key-round', label = 'Llaves', tipo = 'pestana' }
    end

    -- Ciudad va detras de Llaves, como en tabs.ts. Faltaba, y era el hueco
    -- que se veia entre los iconos al pasar al menu de admin.
    if PestanaActiva('city') then
        riel[#riel + 1] = { id = 'city', icon = 'lucide:building-2', label = 'Ciudad', tipo = 'pestana' }
    end

    -- Misiones va detras de Ciudad, como en tabs.ts. Tambien faltaba (03/10):
    -- al pasar del inventario a cualquier otro panel el riel perdia un boton
    -- y los de debajo subian un puesto.
    if PestanaActiva('quests') then
        riel[#riel + 1] = { id = 'quests', icon = 'lucide:scroll-text', label = 'Misiones', tipo = 'pestana' }
    end

    for _, a in ipairs(AccesosDelJugador()) do
        riel[#riel + 1] = {
            id = a.id, icon = a.icon, label = a.label, tipo = 'acceso',
            -- Para que el panel que lo pinta sepa cual es el suyo y lo marque
            -- encendido en vez de ofrecer ir a donde ya estas.
            actual = (a.id == actual),
        }
    end

    return riel
end)

--[[ Abrir el inventario directamente en una pestaña. Es lo que llaman los
     otros paneles cuando pulsas Inventario o Personaje en su riel. ]]
--[[ Se abre en el acto, con el otro panel todavia en pantalla: asi el riel no
     llega a desaparecer y el relevo se ve como un cambio de columna.

     No se usa `ExecuteCommand('origen_inventory')` porque ese comando se planta
     si hay otra NUI con el foco —y justo venimos de una—, que es por lo que
     antes habia que soltar el foco primero y esperar. Se llama al metodo
     directamente, que es lo que hace el comando cuando no estas en un coche ni
     encima de una bolsa. ]]
--[[ `vista` es opcional: una pantalla de DENTRO de la pestaña. Hoy solo la
     usa Ciudad --'reportes', 'estadisticas', 'mapa'-- y la pide el radial de
     origen_hud, que tiene Reportes como opcion propia. ]]
exports('AbrirEnPestana', function(pestana, relevo, vista)
    --[[ Lo primero, soltar el foco que traiga puesto quien nos llama.

         Este export puede NO abrir nada: `Player:OpenInventory` se niega si
         Bridge.CanOpen() dice que no --ocupado, herido, esposado--, y hasta
         puede no haber Player todavia. Si el que nos llamo se habia quedado
         con el foco esperando a que lo cogieramos nosotros, en esos casos no
         lo coge nadie y el raton se queda en pantalla sin nada que pulsar.

         Soltandolo aqui, lo peor que puede pasar es quedarse sin panel.

         Pero NO si el inventario ya esta delante (la rama de ponerPestana de
         abajo): el foco de este recurso es el suyo, y soltarlo lo dejaba
         pintado sin raton ni forma de cerrarlo. ]]
    if not (Player and Player.isOpen) then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
    RelevoEnCurso()

    --[[ Y se vigila: si segundo y medio despues el inventario no esta abierto
         y el foco sigue puesto, se suelta a mano. Es la misma red que hay para
         los accesos, que hasta ahora no cubria las pestañas. ]]
    VigilarPestana()

    if not Player and not CharacterUnloaded then Player = Player_Class:new() end
    if not Player then return end

    -- Se apuntan ANTES de abrir: los lee InventoryUI.Open al armar el mensaje.
    InventoryUI.relevoEntrante = relevo == true

    if not Player.isOpen then
        --[[ La pestaña viaja CON la apertura, no en un aviso 120 ms despues.

             Asi entraba antes, y se veia: pulsabas Ciudad en el riel de la
             radio y el inventario se abria por Objetos, con su rejilla
             pintada, y a los 120 ms saltaba a Ciudad. Dos pantallas para un
             solo clic. Yendo en el mensaje de apertura, la primera cosa que se
             pinta ya es Ciudad. ]]
        InventoryUI.pestanaEntrante = pestana or 'inventory'
        InventoryUI.vistaEntrante = vista
        Player:OpenInventory()
    else
        --[[ Ya estaba abierto, asi que no hay apertura donde meter la pestaña:
             aqui si toca avisar aparte. Es un cambio de pestaña, no una
             entrada, y no hay nada que parpadee. ]]
        InventoryUI.Emit({ action = 'ponerPestana', data = pestana or 'inventory', vista = vista })
    end
end)

--[[ Los REPORTES, que se pueden abrir aunque estes tirado en el suelo.

     Los reportes viven en la pestaña Ciudad, y la pestaña Ciudad vive en el
     inventario, que se niega a abrirse si estas herido o esposado. Resultado:
     el boton Reportes del radial no hacia nada justo cuando mas falta hace
     --te mata un fallo del servidor y no puedes avisar a nadie--.

     Estando bien, esto es exactamente `AbrirEnPestana('city', .., 'reportes')`.
     Estando tirado se abre igual, pero en modo SOLO REPORTES: la interfaz deja
     unicamente la pestaña Ciudad clavada en Reportes, sin accesos del riel y
     sin volver al indice de Ciudad, asi que no hay rejilla de objetos delante
     ni forma de llegar a ella. El modo se apaga al cerrar. ]]
exports('AbrirReportes', function(relevo)
    local impedido = not Bridge.CanOpen()

    -- Igual que en AbrirEnPestana: con el inventario ya delante el foco es suyo.
    if not (Player and Player.isOpen) then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
    RelevoEnCurso()
    VigilarPestana()

    if not Player and not CharacterUnloaded then Player = Player_Class:new() end
    if not Player then return end

    InventoryUI.relevoEntrante = relevo == true

    if not Player.isOpen then
        InventoryUI.pestanaEntrante = 'city'
        InventoryUI.vistaEntrante = 'reportes'
        InventoryUI.soloReportesEntrante = impedido
        Player:OpenInventory()
        --[[ Si `OpenInventory` se nego igualmente (ocupado por otra cosa), la
             bandera se quedaria puesta y envenenaria la siguiente apertura,
             que saldria recortada sin motivo. La apertura buena ya la apaga
             al armar el mensaje. ]]
        InventoryUI.soloReportesEntrante = false
    else
        InventoryUI.Emit({ action = 'ponerPestana', data = 'city', vista = 'reportes' })
    end
end)

--- Y el camino de vuelta: abrir uno de los accesos desde fuera del inventario.
exports('AbrirAcceso', function(cual, relevo)
    --[[ El foco se suelta YA aunque el destino tarde: si algo falla por el
         camino, lo peor que puede pasar es quedarse sin panel, no quedarse sin
         camara.

         Si el inventario estaba delante, soltar el foco a secas lo dejaba
         pintado y sin raton: aqui el que se va es el, asi que se cierra
         entero (que ya suelta el foco). ]]
    if Player and Player.isOpen then
        Player:CloseInventory(false, false)
    else
        SetNuiFocus(false, false)
    end

    SetTimeout(120, function()
        local r = relevo == true
        VigilarRelevo(cual)
        if cual == 'admin' and EsAdmin() then ExecuteCommand('admin')
        elseif cual == 'banda' and SaleBanda() then AbrirBanda(r)
        elseif cual == 'crew' and TieneCrew() then AbrirCrew(r)
        elseif cual == 'negocio' and TieneNegocio() then AbrirNegocio(r)
        elseif cual == 'policia' and EsPolicia() then AbrirPolicia(r)
        elseif cual == 'mascotas' and TieneMascotas() then AbrirMascotas(r)
        elseif cual == 'radio' and LlevaRadio() then AbrirRadio(r) end
    end)
end)

InventoryUI.On('GetAccesos', function()
    -- Aqui SI se puede esperar la respuesta del servidor: esto corre dentro de
    -- la llamada de la NUI, que va en su propia corrutina. Asi el boton de
    -- Negocio ya es correcto la primera vez que se abre el inventario, sin
    -- depender de que el refresco del arranque haya llegado a tiempo.
    RefrescarNegocios()

    --[[ Se devuelve la lista entera y no cuatro banderas: el nombre y el
         icono de cada boton los sabe Lua, y el de emergencias cambia segun el
         cuerpo. La interfaz solo pinta lo que llega. ]]
    Accesos = AccesosDelJugador()
    return Accesos
end)

--[[ Abrir uno.

     Antes se cerraba el inventario, se esperaba un cuarto de segundo y se abria
     el otro. Eso son 250 ms de pantalla vacia, y lo que mas canta es el riel del
     canto derecho: los dos paneles pintan EL MISMO, en el mismo sitio, asi que
     verlo irse y volver es un parpadeo gratis.

     Ahora se abre el panel nuevo PRIMERO. Su riel se pinta encima del nuestro,
     que es identico, y solo despues se retira el inventario: de un panel a otro
     solo cambia la columna de la izquierda, que es lo unico que de verdad
     cambia. El cierre suelta el foco del inventario: el del panel nuevo es
     suyo y no se toca (el foco de la NUI es por recurso). ]]
InventoryUI.On('AbrirAcceso', function(datos)
    local cual = datos and datos.cual
    if not cual then return false end

    -- Se vuelve a comprobar: que el boton estuviera pintado no prueba nada.
    if cual == 'admin' and not EsAdmin() then return false end
    if cual == 'banda' and not SaleBanda() then return false end
    if cual == 'crew' and not TieneCrew() then return false end
    if cual == 'negocio' and not TieneNegocio() then return false end
    if cual == 'policia' and not EsPolicia() then return false end
    if cual == 'mascotas' and not TieneMascotas() then return false end
    if cual == 'radio' and not LlevaRadio() then return false end

    --[[ El relevo solapado solo con admin, que es el unico del que se puede
         preguntar despues si llego a abrirse (export EstaAbierto). Con los
         demas no hay forma de confirmarlo, y quedarse con el foco puesto y
         ningun panel delante deja el raton pegado sin nada que pulsar: ahi se
         sigue cerrando primero, que parpadea pero no atranca. ]]
    if cual ~= 'admin' then
        if Player and Player.isOpen then
            Player:CloseInventory(false, false)
        end

        --[[ A los 200 y no a los 250: la columna tarda 260 ms en recogerse,
             asi que abriendo a mitad del recorrido el panel que entra empieza
             a deslizarse mientras este acaba de salir. La barra del canto no
             se mueve en ningun momento --la NUI la congela al pulsar y el que
             entra pinta la suya encima--, asi que lo unico que se ve moverse
             es la columna. ]]
        VigilarRelevo(cual)

        SetTimeout(200, function()
            if cual == 'banda' then
                AbrirBanda(true)
            elseif cual == 'crew' then
                AbrirCrew(true)
            elseif cual == 'negocio' then
                AbrirNegocio(true)
            elseif cual == 'policia' then
                AbrirPolicia(true)
            elseif cual == 'mascotas' then
                AbrirMascotas(true)
            elseif cual == 'radio' then
                AbrirRadio(true)
            end
        end)
        return true
    end

    RelevoEnCurso()
    ExecuteCommand('admin')

    SetTimeout(100, function()
        --[[ SIN `mantenerFoco`. El foco de la NUI es POR RECURSO: soltar el
             del inventario no le quita nada al panel de admin, que tiene el
             suyo. Con `mantenerFoco` el inventario se escondia y se quedaba
             con el raton puesto; al cerrar el admin, el raton seguia en
             pantalla sin nada delante (16/09, "sobre todo con el admin"). ]]
        if Player and Player.isOpen then
            Player:CloseInventory(false, false)
        end

        --[[ Red de seguridad: si el panel de admin no llego a abrirse, nadie
             ha cogido el foco y lo tendria todavia una NUI que ya no se ve. Se
             suelta a mano para no dejar al jugador con el raton y nada mas. ]]
        SetTimeout(500, function()
            -- Si en este rato se ha vuelto a abrir el inventario, el foco es
            -- suyo: soltarlo lo dejaria delante sin raton.
            if Player and Player.isOpen then return end
            if Preguntar('origen_admin', 'EstaAbierto') ~= true then
                SetNuiFocus(false, false)
                SetNuiFocusKeepInput(false)
            end
        end)
    end)

    return true
end)

--[[ ── Las teclas viejas ───────────────────────────────────────────────

     Quitar el RegisterKeyMapping del codigo solo sirve para quien entra por
     primera vez. El atajo se guarda EN EL PERFIL del jugador la primera vez
     que lo ve, y ahi se queda aunque el recurso ya no lo pida: por eso a los
     veteranos les seguian abriendo F5 las misiones, F6 la banda y F7 el
     negocio y la policia con el codigo ya limpio de hace tiempo.

     Esto las desata una sola vez y lo deja anotado. Una sola vez a proposito:
     si despues alguien se pone el F5 a mano para lo que sea, esa tecla es
     suya y aqui no se vuelve a tocar.

     Va en el inventario y no en cada recurso porque es el riel el que se
     quedo con esos menus: quien recoge la herencia recoge tambien la
     limpieza, y asi no hay tres sitios desatando la misma tecla.

     AVISO sobre el F6: origen_newjobs todavia lo registra a proposito para el
     dispatch del taxi. A quien tenga el F6 abriendo el menu de banda no le
     afecta —ese F6 ya no es el del taxi—, pero si algun dia se toca esta
     lista, tenerlo presente: desatar una tecla que otro recurso sigue
     pidiendo se la quita a quien la tuviera bien puesta, porque el default de
     RegisterKeyMapping no se vuelve a aplicar a un perfil que ya lo vio. ]]
local TECLAS_VIEJAS = { 'F5', 'F6', 'F7' }
local MARCA_LIMPIEZA = 'origen_riel_teclas_viejas_v1'

CreateThread(function()
    if GetResourceKvpString(MARCA_LIMPIEZA) == 'hecho' then return end

    --[[ Un respiro antes de tocar nada: al arrancar, los recursos todavia
         estan registrando sus propios atajos, y desatar en mitad de eso puede
         no prender o pelearse con un registro que llega justo despues. ]]
    Wait(8000)

    for _, tecla in ipairs(TECLAS_VIEJAS) do
        ExecuteCommand(('unbind keyboard %s'):format(tecla))
    end

    SetResourceKvp(MARCA_LIMPIEZA, 'hecho')
end)

--[[ ── La salida de emergencia ──────────────────────────────────────────────

     Si alguna vez se vuelve a quedar el raton en pantalla con ningun panel
     delante, esto lo suelta:

         F8  ->  soltarraton

     La consola del cliente es lo UNICO que sigue respondiendo con el foco de
     la NUI puesto. Una tecla no vale: con el foco cogido, las teclas se las
     queda la NUI y un RegisterKeyMapping no llega a dispararse nunca. Por eso
     es un comando y no un atajo.

     No deberia hacer falta. Existe porque quedarse sin camara solo se arregla
     reconectando, y eso es peor que cualquier fallo de pintado: mientras haya
     una forma de salir, un panel que se atranque es una molestia y no el final
     de la partida.

     Desde el 11/09 el comando vive en origen_hud (client/foco.lua) y suelta el
     foco de TODOS los recursos, no solo el de este: el foco es de cada
     recurso, y aqui solo se soltaba el del inventario. Lo que queda aqui es lo
     propio del inventario: cerrarse del todo cuando le quitan el raton. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if Player and Player.isOpen then
            Player:CloseInventory(false, false)
        end

        --[[ El modo foto con los ajustes abiertos tiene el foco: soltado a la
             fuerza, InSettings se quedaba en true y su bucle dejaba de leer
             teclas --ni Escape ni E--, con la camara puesta y el tiempo
             parado. Se sale del modo entero; Stop() no coge foco. ]]
        if PhotoMode and PhotoMode.IsActive then
            PhotoMode.Stop()
        end

        -- Y el panel de gestion, que tambien lleva raton.
        if InventoryUI.managementOpen then
            InventoryUI.managementOpen = false
            InventoryUI.Emit({ action = 'closeManagement' }, false, true)
        end
    end)
end

--[[ Otro panel se abre ENCIMA del inventario (un item que abre su pantalla,
     el movil...). foco.lua apaga el KeepInput al cogerlo el otro, y al irse
     ese el inventario se quedaba delante sin teclado y con la camara
     bloqueada. Se cierra antes.

     Salvo en un relevo del riel (relevoHasta): ahi el otro foco es el del
     panel que entra o el que se va, y el cierre ya lo lleva el propio relevo. ]]
AddEventHandler('origen:foco:estado', function(recurso, tiene)
    if not tiene or recurso == GetCurrentResourceName() then return end
    if not (Player and Player.isOpen) then return end
    if GetGameTimer() < relevoHasta then return end

    Player:CloseInventory(false, false)
end)

--[[ ── El chivato del foco ──────────────────────────────────────────────────

     Aqui vivia un hilo que, cada segundo, miraba si la NUI tenia el foco y
     preguntaba a los diez paneles del riel si alguno estaba abierto. Si el
     foco llevaba tres segundos puesto y ninguno decia estarlo, escribia tres
     lineas en la consola del cliente.

     Se ha quitado. Servia para cazar un panel que se atrancaba, y ese fallo
     ya no aparece: lo que quedaba era un hilo despierto cada segundo para
     escribir en cada apertura de inventario que el inventario estaba abierto,
     que es exactamente el ruido que hace que una consola deje de mirarse.

     La salida de emergencia --el comando `soltarraton` de aqui arriba-- se
     queda: eso no escribe nada por su cuenta y es lo que de verdad saca del
     apuro si alguna vez vuelve a pasar. ]]
