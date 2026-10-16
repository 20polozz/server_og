--[[ LA TIENDA DE TELÉFONOS, EN EL MUNDO

     El mostrador de la compañía. Aquí se compra un móvil y, si el servidor va
     en modo "del aparato", además se recupera una línea perdida.

     POR QUÉ ESTO NO VA DENTRO DEL TELÉFONO

     Porque la pantalla del teléfono ES el teléfono: si no tienes ninguno, no
     hay pantalla que abrir. Una aplicación para comprarse un móvil solo la
     vería quien ya tiene uno.

     Así que va con los menús de ox_lib, que ya usa el resto del recurso para lo
     que pasa fuera de la pantalla. Sin teléfono en la mano y sin NUI de por
     medio.

     LAS DOS COSAS QUE SE HACEN AQUÍ

     Comprar      Sale un aparato sin estrenar. Qué pasa al abrirlo lo decide
                  el modo del servidor, no la tienda: en "de la persona"
                  recupera tu línea de siempre, y en "del aparato" estrena
                  número.

     Recuperar    Solo tiene sentido en "del aparato": te ponen TU número en
                  uno de esos aparatos en blanco.
]]

local ALCANCE = 3.0
local CADA = 500

--[[ Las tiendas y su aspecto, tal como los manda el servidor.

     Antes salían de AjustesDelServidor, que solo se rellena al ENCENDER el
     teléfono: hasta sacar el móvil no había chincheta en ningún mapa, ni
     dependiente, ni [E]. Y quien más necesita la tienda es quien no tiene
     móvil. Ahora se piden al entrar y llegan a todos cuando el panel las toca. ]]
local publico = nil

--- Lo que haya: lo pedido a propósito, o lo que trajo el teléfono al encender.
---@return table|nil
local function Ajustes()
    return publico or AjustesDelServidor
end

--- Las tiendas que ha puesto el servidor desde el panel.
local function Tiendas()
    local ajustes = Ajustes()
    return (ajustes and ajustes.recoveryShops) or {}
end

--[[ Como quiere el servidor que se vea la tienda.

     Sale del panel, no de `config/config.lua`: el fichero solo siembra la
     primera vez. Mientras no lleguen los ajustes se devuelve una tabla vacia y
     no se pinta nada, que es mejor que plantar un dependiente con el modelo de
     fabrica y tener que borrarlo un segundo despues. ]]
---@return table
local function Aspecto()
    local ajustes = Ajustes()
    return (ajustes and ajustes.shop) or {}
end

--- La tienda que se tiene delante, si hay alguna.
---@param coords vector3
---@return table|nil
local function TiendaCerca(coords)
    for _, s in ipairs(Tiendas()) do
        if #(coords - vector3(s.x + 0.0, s.y + 0.0, s.z + 0.0)) <= ALCANCE then
            return s
        end
    end

    return nil
end

--- Un atajo para preguntarle al servidor sin repetir la llamada entera.
---@param metodo string
---@param datos table|nil
---@return table|nil
local function Pedir(metodo, datos)
    return lib.callback.await('origen_phone:rpc', false, metodo, datos or {})
end

-- ---------------------------------------------------------------------------
--  El menú
-- ---------------------------------------------------------------------------

local abriendo = false




--- Declarada antes para poder llamarse a sí misma tras una compra.
local Abrir

--- Si el menú está en pantalla. El guardia de abrir y de cerrar.
local abierta = false

--[[ Cierra el menú.

     EL FOCO SE SUELTA ANTES QUE NADA, siempre. Si se soltara al terminar la
     animación, el ratón se quedaría preso los 260 ms en los que la pantalla ya
     parece cerrada; y si el aviso a la interfaz no llegara —una excepción, un
     `fetch` que falla— se quedaría preso del todo: el menú se ha ido y la
     cámara no vuelve. Soltar primero hace que eso no pueda pasar. ]]
local function Cerrar()
    if not abierta then return end
    abierta = false

    Foco.Panel('tienda', false)

    --- 280 > los 260 que dura el deslizamiento: se desmonta ya fuera de vista.
    SetTimeout(280, function()
        Nui.Send('shopClose', {})
    end)
end

--[[ Escape leido desde aqui, por si la pagina no contesta.

     El menu se abre sin KeepInput: el unico Escape era el de la pagina
     (TiendaTelefonos.vue). Si el 'shopOpen' no llega a pintarse, el foco se
     quedaba sin nada delante. IsRawKeyReleased lee la tecla en crudo; SIN
     PROBAR EN EL JUEGO que llegue con la NUI quedandose el teclado. Si no
     llegara, no cambia nada y queda `soltarraton` en F8 (ver AlSoltar). ]]
local function VigilarEscape()
    if not IsRawKeyReleased then return end

    CreateThread(function()
        while abierta do
            if IsRawKeyReleased(27) then
                Cerrar()
                break
            end
            Wait(0)
        end
    end)
end

if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        if not abierta then return end
        abierta = false
        Foco.tienda = false
        Nui.Send('shopClose', {})
    end)
end

Foco.AlCerrar('tienda', function() Cerrar() end)

Abrir = function()
    if abriendo or abierta then return end
    abriendo = true

    --[[ Las dos preguntas de golpe.

         Lo que la pantalla necesita para decidir viaja CON la apertura y no en
         llamadas sueltas al elegir: un precio que aparece dos clics después de
         haber elegido llega tarde, para entonces ya has decidido. ]]
    --[[ Con pcall: si el servidor no contesta, el await revienta a los cinco
         minutos, y el error salia de aqui con `abriendo` en true. La tienda ya
         no se volvia a abrir en toda la sesion. ]]
    local bien, tienda, lineas = pcall(function()
        return Pedir('shop:state'), Pedir('recovery:state')
    end)

    abriendo = false

    if not bien then
        lib.notify({ description = Locale.Say('err_something_failed'), type = 'error' })
        return
    end

    local sePuedeComprar = tienda ~= nil and tienda.enabled == true
    local suyas = (lineas and lineas.enabled ~= false and lineas.lines) or {}

    --[[ Ni una cosa ni la otra: se dice por qué, en vez de abrir un menú vacío.

         Que no haya nada que recuperar es lo normal —solo pasa si has perdido
         un teléfono—, así que ese es el aviso que se da salvo que la tienda
         entera esté apagada. ]]
    if not sePuedeComprar and #suyas == 0 then
        lib.notify({
            description = Locale.Say(tienda == nil and 'err_shop_off' or 'recovery_nothing'),
            type = 'inform',
        })
        return
    end

    --[[ El telefono, fuera antes.

         La E del mostrador no esta entre las teclas que apaga el telefono, asi
         que se podia abrir la tienda con el telefono en la mano. Comparten
         pagina y foco: al cerrar el telefono con Escape se soltaba el foco
         de los dos, y el menu de la tienda se quedaba pintado sin raton, sin
         Escape y sin poder volver a abrirlo (`abierta` seguia en true). ]]
    if Phone and Phone.open then Phone.Close() end

    abierta = true
    --- Sin teclas para el juego, con cursor; y si el admin estaba abierto, se cierra.
    Foco.Panel('tienda', true)
    VigilarEscape()

    Nui.Send('shopOpen', {
        puedeComprar = sePuedeComprar,
        precio = (tienda and tienda.price) or 0,
        moneda = (tienda and tienda.currency) or '$',
        precioLinea = (lineas and lineas.price) or 0,
        lineas = suyas,
        --- La marca: la tienda se abre sin telefono (ver utils/marca.ts).
        marca = GetConvar('origen:marca', 'origen'),
        --- Y los textos, por lo mismo: sin un telefono encendido antes, la
        --- interfaz no los tiene y el menu salia escrito en claves (shop_title).
        locale = Locale.MiTabla(),
    })
end

-- ---------------------------------------------------------------------------
--  Lo que pide el menú
-- ---------------------------------------------------------------------------

--- Comprar. Devuelve además las líneas al día: con el aparato ya en el
--- bolsillo, recuperar la tuya es justo lo siguiente que se puede hacer.
Nui.On('shopBuy', function()
    local hecho = Pedir('shop:buy')

    if not hecho or hecho.ok ~= true then
        return { ok = false, error = hecho and hecho.error or 'err_something_failed' }
    end

    local lineas = Pedir('recovery:state')

    return { ok = true, lines = (lineas and lineas.lines) or {} }
end)

Nui.On('shopRecover', function(params)
    local hecho = Pedir('recovery:recover', { id = params and params.id })

    if not hecho or hecho.ok ~= true then
        return { ok = false, error = hecho and hecho.error or 'err_something_failed' }
    end

    lib.notify({
        description = Locale.Say('recovery_done', hecho.number or ''),
        type = 'success',
    })

    return { ok = true }
end)

--- Lo llama la propia pantalla al cerrarse, por cualquiera de sus caminos.
Nui.On('shopClose', function()
    Cerrar()
    return true
end)


-- ---------------------------------------------------------------------------
--  Estar delante del mostrador
-- ---------------------------------------------------------------------------

--[[ Lejos, se mira medio segundo. Delante del mostrador, cada fotograma.

     LOS DOS RITMOS NO SON UN CAPRICHO

     Mirar la distancia cada fotograma desde el otro lado del mapa es tirar
     trabajo: por eso los puntos de carga y esto duermen medio segundo mientras
     no hay nadie cerca.

     Pero `IsControlJustReleased` solo dice que sí en EL FOTOGRAMA en que se
     suelta la tecla. Preguntándolo cada 500 ms, se pierde casi siempre: el
     aviso de pulsar la E salía —eso aguanta un pulso lento— y luego la E no
     hacía nada. Parecía que la tienda estaba rota y lo que estaba mal era el
     reloj de quien escuchaba.

     Así que en cuanto se entra en la tienda el bucle baja a cada fotograma, y
     al salir vuelve a medio segundo. ]]
CreateThread(function()
    local dentro = false

    while true do
        local sitios = Tiendas()
        local cerca = #sitios > 0 and TiendaCerca(GetEntityCoords(PlayerPedId())) or nil

        if cerca and not dentro then
            dentro = true
            lib.showTextUI(Locale.Say('shop_prompt'), { position = 'left-center' })
        elseif not cerca and dentro then
            dentro = false
            lib.hideTextUI()
        end

        if dentro then
            if IsControlJustReleased(0, 38) then
                lib.hideTextUI()
                dentro = false
                Abrir()
            end

            Wait(0)
        else
            Wait(CADA)
        end
    end
end)

-- ---------------------------------------------------------------------------
--  El dependiente
-- ---------------------------------------------------------------------------

--[[ Un vecino detrás del mostrador, para que la tienda no sea un punto en el
     suelo pelado. Se quita entero apagándolo en el panel.

     No anda, no se asusta y no se cae al suelo: está trabajando.

     ── DE QUIÉN ES Y QUIÉN LO VE ──────────────────────────────────────────

     Se crea con `isNetwork = false`, o sea LOCAL de cada cliente. Cada jugador
     se planta el suyo con este mismo código, así que todo el mundo lo ve en el
     mismo sitio sin que exista una sola entidad de red.

     Es lo que hay que hacer con el mobiliario: una entidad de red tendría un
     dueño, se sincronizaría por la red sin necesidad, y desaparecería para
     todos cuando ese dueño se desconectara.

     ── Y SE VA CUANDO NO HAY NADIE DELANTE ────────────────────────────────

     Antes se creaban los de TODAS las tiendas al arrancar y no se borraban
     nunca. Con dos tiendas no se nota; con veinte son veinte peds vivos todo
     el rato al otro lado del mapa, ocupando sitio del presupuesto de entidades
     del juego —que no es infinito— para que no los vea nadie.

     Ahora se plantan al acercarte y se recogen al irte. ]]
local dependientes = {}

--- A cuántos metros aparece. Bastante más que el alcance del mostrador: tiene
--- que estar ya puesto cuando llegas, no aparecerte delante de la cara.
local CERCA = 90.0

--- Se mira cada segundo. Andando no se cruzan noventa metros en menos.
local MIRAR_CADA = 1000

local function QuitarDependiente(clave)
    local ped = dependientes[clave]
    if ped and DoesEntityExist(ped) then DeleteEntity(ped) end
    dependientes[clave] = nil
end

local function QuitarDependientes()
    for clave in pairs(dependientes) do QuitarDependiente(clave) end
    dependientes = {}
end

--- Carga un modelo, con tope. Devuelve si ha llegado a tiempo.
---@param modelo string|number
---@return boolean
local function CargarModelo(modelo)
    local hash = type(modelo) == 'number' and modelo or GetHashKey(modelo)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return false end

    RequestModel(hash)

    --[[ Con tope a propósito. Un modelo que no llega nunca —mal escrito, o de
         un DLC que no está puesto— colgaría este hilo para siempre. Cinco
         segundos y la tienda se abre sin dependiente, que es mejor que no
         abrirse. ]]
    local hasta = GetGameTimer() + 5000

    while not HasModelLoaded(hash) and GetGameTimer() < hasta do Wait(50) end

    return HasModelLoaded(hash)
end

--- Los ajustes del dependiente, o nil si no toca poner ninguno.
---@return table|nil
local function AjustesDelDependiente()
    if not Config.Shop or Config.Shop.Enabled == false then return nil end

    local ajustes = Aspecto().ped
    if not ajustes or ajustes.enabled == false then return nil end
    if not ajustes.model or ajustes.model == '' then return nil end

    return ajustes
end

--- Planta el dependiente de una tienda.
---@param clave string
---@param tienda table
---@param ajustes table
local function PonerDependiente(clave, tienda, ajustes)
    if dependientes[clave] then return end

    if not CargarModelo(ajustes.model) then
        Utils.Warn(('el modelo del dependiente (%s) no existe: la tienda va sin él')
            :format(tostring(ajustes.model)))
        return
    end

    local hash = GetHashKey(ajustes.model)

    --[[ Un metro por debajo del punto guardado: las coordenadas salen de donde
         estaba plantado quien las puso, o sea a la altura de sus pies mas su
         propia altura, y un ped ahí queda flotando. ]]
    local ped = CreatePed(4, hash,
        tienda.x + 0.0, tienda.y + 0.0, (tienda.z or 0.0) - 1.0,
        (tienda.h or ajustes.heading or 0.0) + 0.0, false, true)

    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(ped) then return end

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedDiesWhenInjured(ped, false)

    if ajustes.scenario and ajustes.scenario ~= '' then
        TaskStartScenarioInPlace(ped, ajustes.scenario, 0, true)
    end

    dependientes[clave] = ped
end

--[[ Pone y quita dependientes según dónde esté el jugador.

     Va en su propio hilo y a un segundo: es una cuenta de distancias contra una
     lista de dos o tres sitios, no algo que necesite el fotograma. ]]
CreateThread(function()
    while true do
        Wait(MIRAR_CADA)

        local ajustes = AjustesDelDependiente()

        if not ajustes then
            if next(dependientes) then QuitarDependientes() end
            goto siguiente
        end

        do
            local yo = GetEntityCoords(PlayerPedId())
            local vivos = {}

            for i, tienda in ipairs(Tiendas()) do
                --[[ Por posición y no por nombre: dos tiendas pueden llamarse
                     igual, y entonces una se quedaría sin dependiente.

                     Con `math.floor` y no con `%d` a secas: en Lua 5.4 un
                     decimal en `%d` no se redondea, REVIENTA —"number has no
                     integer representation"—, y las coordenadas de una tienda
                     son decimales siempre. Se caía el hilo entero y con él los
                     dependientes de todas. ]]
                local clave = ('%d:%d:%d'):format(
                    i, math.floor(tienda.x or 0), math.floor(tienda.y or 0))
                vivos[clave] = true

                local lejos = #(yo - vector3(tienda.x + 0.0, tienda.y + 0.0, (tienda.z or 0.0) + 0.0))

                if lejos <= CERCA then
                    PonerDependiente(clave, tienda, ajustes)
                else
                    QuitarDependiente(clave)
                end
            end

            --- Y los de tiendas que ya no existen —las han quitado del panel—.
            for clave in pairs(dependientes) do
                if not vivos[clave] then QuitarDependiente(clave) end
            end
        end

        ::siguiente::
    end
end)

-- ---------------------------------------------------------------------------
--  Y en el mapa
-- ---------------------------------------------------------------------------

--[[ Aquí vivía el export SpriteDeLaTienda.

     Existía para que los mapas del servidor supieran con qué número de blip
     marcar las tiendas, porque ese número se elige en el panel y ellos
     agrupaban los puntos POR SPRITE: escrito a mano en el otro recurso,
     cambiarlo aquí hacía desaparecer la tienda de aquel mapa sin que nada lo
     dijera.

     Desde que la tienda se registra como punto en origen_map, el mapa ya no
     busca ningún número: le llega la categoría, y el dibujo de la chincheta
     —el móvil— lo pone él. El export ya no lo llamaba nadie. ]]

local marcas = {}

--[[ Las tiendas, en el mapa.

     Ya no son blips del juego: se registran en origen_map y de ahi las leen
     los tres mapas del servidor. El interruptor del panel sigue mandando; el
     sprite, la escala y el color ya no pintan nada, porque el dibujo de la
     chincheta —el movil— es nuestro.

     Que es justo lo que hacia falta: el icono se elegia en el panel, los mapas
     agrupaban los puntos POR NUMERO DE SPRITE, y cambiarlo alli hacia
     desaparecer la tienda del mapa sin que nada lo dijera. ]]
local function Pintar()
    marcas = {}

    local ajustes = Aspecto().blip
    if not ajustes or ajustes.enabled == false then
        OrigenMapa.PonerVarios('tienda', {})
        return
    end

    local puntos = {}

    for i, s in ipairs(Tiendas()) do
        puntos[#puntos + 1] = {
            id = tostring(s.id or i),
            x = s.x, y = s.y, z = s.z,
            cat = 'telefonos',
            nombre = s.name or Locale.Say('shop_title'),
        }
    end

    OrigenMapa.PonerVarios('tienda', puntos)
    marcas = puntos
end

--[[ Se rehacen cuando el panel las mueve, sin tener que reconectar.

     Los dependientes también: mover una tienda desde el panel y que el empleado
     se quede plantado en la acera de antes sería peor que no tenerlo. ]]
--[[ Los dependientes NO se rehacen aquí: el hilo de arriba los pone y los
     quita solo, y si una tienda se ha movido o se ha apagado el dependiente lo
     nota en el siguiente segundo. Se recogen todos para que el de la posición
     vieja no se quede plantado en la acera de antes. ]]
RegisterNetEvent('origen_phone:cl:settings', function(ajustes)
    if type(ajustes) == 'table' then
        publico = { recoveryShops = ajustes.recoveryShops, shop = ajustes.shop }
    end

    Pintar()
    QuitarDependientes()
end)

RegisterNetEvent('origen_phone:cl:tiendas', function(tiendas)
    if type(tiendas) ~= 'table' then return end

    publico = tiendas
    Pintar()
    QuitarDependientes()
end)

--- Se piden al servidor sin esperar a que nadie encienda el teléfono.
local function PedirTiendas()
    local ok, tiendas = pcall(lib.callback.await, 'origen_phone:tiendas', false)
    if ok and type(tiendas) == 'table' then publico = tiendas end

    Pintar()
end

CreateThread(function()
    Wait(2000)
    PedirTiendas()
end)

--[[ Y otra vez al elegir personaje: si el recurso arrancó con el jugador aún
     en el menú de inicio, la primera respuesta pudo perderse. ]]
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    PedirTiendas()
end)

--[[ Y aqui vivia /ogphone_icono, que servia para ir probando numeros del
     catalogo de blips de GTA hasta dar con uno que se pareciera a un movil.

     Hacia falta porque el icono del minimapa lo pintaba el motor con sus
     propias texturas y ese catalogo no se puede mirar desde dentro del juego:
     o te lo sabias, o probabas. Ahora el minimapa es una pagina web como el
     resto de mapas del servidor y la chincheta la dibujamos nosotros, asi que
     no hay ningun numero que adivinar. ]]

--[[ Al parar el recurso, el dependiente se va con él.

     Los peds no son del recurso, son del mundo: sin esto se quedan de pie en la
     tienda hasta reconectar, y cada reinicio deja otro encima del anterior. ]]
AddEventHandler('onResourceStop', function(nombre)
    if nombre ~= GetCurrentResourceName() then return end
    QuitarDependientes()
end)
