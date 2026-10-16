--[[
    El menu rapido de la policia, desde el riel del inventario.

    El F7 ya no es una tecla suelta: es un boton mas del riel del inventario,
    al lado de Admin, Banda y Negocio. Ese riel es ahora la unica via, igual
    que lo es para los otros tres, asi que la tecla esta quitada en
    config/commands.lua.

    Aqui vive todo lo que hace falta para eso y nada mas:
      · lo que el inventario pregunta para decidir si pinta el boton,
      · lo que el inventario llama para abrirlo —y lo que ofrece cuando aun
        no estas de servicio, que es entrar—,
      · el riel que se pinta dentro del menu para poder volver.

    El menu en si sigue donde estaba —client/interaction.lua—; lo unico que se
    le añadio alli es un parametro para saber si se abre desde el riel.
]]

local INVENTARIO = 'origen_inventory'

--- El trabajo del jugador, o nil si todavia no hay datos.
local function TrabajoActual()
    local ok, datos = pcall(FW_GetPlayerData, false)
    if not ok or type(datos) ~= 'table' or type(datos.job) ~= 'table' then return nil end
    return datos.job
end

--[[ ¿Se puede abrir el panel?

     Con tener el trabajo basta —lo mismo que hace falta para abrir la tablet—,
     y NO se pide estar de servicio.

     Se probo al reves, con la condicion entera del menu
     (CanOpenQuickAccessMenu, que ademas exige servicio), y es el mismo error
     que ya se cometio con el boton de Negocio: el acceso desaparecia
     justamente en el unico momento en el que hace falta que se vea, que es
     cuando aun no has entrado en servicio.

     Global porque la mira tambien OpenQuickAccessMenu, en client/interaction.lua,
     para decidir si deja abrir la columna del riel. ]]
function PuedePanelPolicia()
    local job = TrabajoActual()
    if not job or not job.name then return false end
    if not (job.onduty or onduty) then return false end
    local ok, acceso = pcall(CanOpenTablet, job.name)
    return ok and type(acceso) == 'table' and acceso[1] == true
end

exports('PuedeMenuRapido', PuedePanelPolicia)

--[[ Como se presenta tu categoria.

     El recurso lo abren cinco categorias, no solo la policia, y cada una tiene
     su nombre, su icono y su color en config/jobs.lua. Sin esto el riel del
     inventario ponia "Policia" con una sirena a un sanitario.

     Devuelve nil si no puedes abrirlo: asi el inventario tiene una sola
     pregunta que hacer —¿hay boton, y como se llama?— en vez de dos. ]]
function UIDeCategoria()
    local job = TrabajoActual()
    if not job or not job.name then return nil end
    if not (job.onduty or onduty) then return nil end

    local ok, acceso = pcall(CanOpenTablet, job.name)
    if not ok or type(acceso) ~= 'table' or acceso[1] ~= true then return nil end

    local ui = Config.CategoryUI or {}
    local suyo = ui[acceso[2]] or ui.default or {}

    -- El nombre fijo «Origen X» sale «Nación X» con la marca nacion.
    local brand = suyo.brand or 'Origen Servicio'
    if GetConvar('origen:marca', 'origen') == 'nacion' then
        brand = brand:gsub('^Origen', 'Nación')
    end

    return {
        category = acceso[2],
        label = suyo.label or 'Servicio',
        brand = brand,
        icon = suyo.icon or 'lucide:shield',
        accent = suyo.accent or '#8a8a94',
    }
end

exports('UIDeCategoria', UIDeCategoria)

--[[ Abrirlo desde el riel.

     No pasa por el comando `quickaccess` a proposito: ese se planta si hay
     otra NUI con el foco —y justo venimos de una, el inventario—. Se llama a
     la funcion directamente, con el riel pedido. ]]
--- `relevo` es que se llega desde otro panel del riel y su barra sigue en
--- pantalla: la de aqui tiene que aparecer ya puesta encima en vez de
--- deslizarse, o durante el cruce se verian dos barras moviendose a la vez.
exports('AbrirMenuRapido', function(relevo)
    local job = TrabajoActual()
    if not job or not (job.onduty or onduty) then return false end
    return OpenQuickAccessMenu(true, false, relevo == true)
end)

--[[ Entrar en servicio desde la propia pagina del panel.

     No se hace de rebote al pulsar el boton del riel: entrar se ve desde
     fuera —sales en la lista de agentes de la central— y tiene que ser un
     acto, no un efecto secundario de abrir un menu. Por eso es una pagina con
     su boton y no algo que pase solo. ]]
RegisterNUICallback('police:entrarEnServicio', function(_, cb)
    cb('ok')

    if Config.Framework == 'esx' then
        TriggerServerEvent('origen_police:server_esx:SetDuty', true)
    else
        TriggerServerEvent('QBCore:ToggleDuty', true)
    end

    --[[ El panel se repinta cuando el servicio ya consta. Hacerlo en el acto
         enseñaria las pestañas de un servicio que todavia no es cierto, y si
         el servidor lo rechaza —no hay plaza, no estas en comisaria— el panel
         diria una cosa y la central otra.

         Va sin foco: el panel esta delante y ya lo tiene. ]]
    CreateThread(function()
        Wait(900)
        -- Si el jugador ya cerro el panel, no se le vuelve a pintar encima.
        if not MenuRapidoAbierto then return end
        OpenQuickAccessMenu(true, true)
    end)
end)

--[[ ── El vehiculo del que habla la pantalla ────────────────────────────────

     La pestaña de interaccion enseña el coche que tienes delante antes de que
     pulses nada. Hasta ahora no habia forma: las acciones de vehiculo resuelven
     su objetivo en Lua al pulsarlas y lo pintan en el juego, pero nadie le
     contaba a la NUI de que coche se trataba.

     Se busca en el mismo orden en que lo haria una persona:
       1. el tuyo, si vas dentro;
       2. al que estas mirando —un rayo de veinte metros desde la camara—;
       3. el mas cercano en ocho metros, para cuando miras al conductor y no
          a la chapa.

     Solo se leen datos: nada de esto toca el vehiculo. ]]

--- Hacia donde mira la camara, a partir de su rotacion.
local function DireccionDeCamara()
    local rot = GetGameplayCamRot(2)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local plano = math.abs(math.cos(x))
    return vector3(-math.sin(z) * plano, math.cos(z) * plano, math.sin(x))
end

local function VehiculoDelante(ped, yo)
    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false)
    end

    local desde = GetGameplayCamCoord()
    local hasta = desde + DireccionDeCamara() * 20.0
    -- El 10 son los vehiculos; el ped propio se ignora para no chocar contigo.
    local rayo = StartShapeTestRay(desde.x, desde.y, desde.z, hasta.x, hasta.y, hasta.z, 10, ped, 0)
    local _, tocado, _, _, entidad = GetShapeTestResult(rayo)
    if tocado == 1 and entidad ~= 0 and IsEntityAVehicle(entidad) then
        return entidad
    end

    return GetClosestVehicle(yo.x, yo.y, yo.z, 8.0, 0, 71)
end

--- El nombre bonito del modelo, con el identificador de reserva: GetLabelText
--- devuelve "NULL" para los coches que no traen etiqueta.
local function NombreDeModelo(modelo)
    local corto = GetDisplayNameFromVehicleModel(modelo)
    local bonito = GetLabelText(corto)
    if not bonito or bonito == '' or bonito == 'NULL' then return corto end
    return bonito
end

RegisterNUICallback('police:vehiculoDelante', function(_, cb)
    local ped = PlayerPedId()
    local yo = GetEntityCoords(ped)
    local veh = VehiculoDelante(ped, yo)

    if not veh or veh == 0 or not DoesEntityExist(veh) then return cb(false) end

    local matricula = GetVehicleNumberPlateText(veh) or ''
    matricula = matricula:gsub('^%s+', ''):gsub('%s+$', '')

    FW_TriggerCallback("origen_police:callback:vehicledata", function(owner)
        cb({
            plate = matricula,
            model = NombreDeModelo(GetEntityModel(veh)),
            owner = (owner and owner ~= '') and owner or 'Desconocido',
            -- 2 y 4 son cerrado; 1 es abierto y 0 es "sin definir".
            locked = GetVehicleDoorLockStatus(veh) >= 2,
            -- Los dos van de 0 a 1000 en el juego.
            engine = math.floor(math.max(0, GetVehicleEngineHealth(veh)) / 10),
            body = math.floor(math.max(0, GetVehicleBodyHealth(veh)) / 10),
            fuel = math.floor(GetVehicleFuelLevel(veh)),
            speed = math.floor(GetEntitySpeed(veh) * 3.6),
            distance = #(yo - GetEntityCoords(veh)),
            mine = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) == veh,
        })
    end, matricula)
end)

--[[ Abrir la tablet grande desde el panel.

     Es el mismo evento que usan el item y el comando `/pcad`, con su misma
     comprobacion dentro —CanOpenTablet—, asi que esto no abre nada que no se
     pudiera abrir ya: solo ahorra cerrar el panel y buscar la tecla.

     El foco se suelta antes: la tablet lo pide para si al abrirse, y dos NUI
     pidiendolo a la vez dejan el raton en la que ya no se ve. ]]
RegisterNUICallback('police:abrirTablet', function(_, cb)
    cb('ok')

    --[[ Se apunta que la tablet se abre DESDE el panel. Al cerrarla, el menu
         vuelve solo y en su tamaño pequeño: quien entro por aqui espera salir
         por aqui, no quedarse mirando la calle. ]]
    TabletDesdeElMenu = true
    SetNuiFocusKeepInput(false)

    --[[ El foco NO se suelta si el panel sigue delante: la tablet se abre
         DENTRO de el, en el mismo bloque, y soltarlo dejaria la pantalla a la
         vista y el raton fuera. Sin panel —el item, el comando— se suelta como
         siempre, que ahi la tablet llega de cero. ]]
    if not MenuRapidoAbierto then
        SetNuiFocus(false, false)
    end

    CreateThread(function()
        Wait(MenuRapidoAbierto and 30 or 150)
        TriggerEvent('origen_police:client:OpenPoliceCad')
    end)
end)

--[[ ── El radar ──────────────────────────────────────────────────────────
     Lo lleva client/alpr.lua; aqui solo se le abre la puerta a la NUI. ]]
RegisterNUICallback('police:radar', function(_, cb)
    if not EstadoDelRadar then return cb(false) end
    local ok, estado = pcall(EstadoDelRadar)
    cb(ok and estado or false)
end)

--[[ Poner el limite desde el panel.

     El comando de siempre abre un cuadro de dialogo encima del juego; desde la
     columna eso seria pedir un numero en una ventana aparte teniendo la
     pantalla delante. Aqui se manda el numero y ya. ]]
RegisterNUICallback('police:radarLimite', function(datos, cb)
    if not PonerLimiteRadar then return cb(false) end
    local ok, puesto = pcall(PonerLimiteRadar, datos and datos.limit)
    cb(ok and puesto or false)
end)

--[[ La lista de botones del riel la da origen_inventory, que es quien sabe si
     estas en un coche, si tienes banda o si eres admin. Aqui solo se pide: si
     cada panel se escribiera la suya, se separarian a la primera y el canto
     derecho parpadearia al cambiar de pantalla. ]]
function RielDelInventario()
    if GetResourceState(INVENTARIO) ~= 'started' then return nil end
    local ok, riel = pcall(function()
        return exports[INVENTARIO]:GetRiel('policia')
    end)
    if not ok then return nil end
    return riel
end

--[[ Saltar a otro panel desde el riel.

     El foco se suelta aqui y no en la interfaz: el destino lo pide para si al
     abrirse, y si la NUI mandase su propio `focus: false` por otro lado, esa
     respuesta podria llegar despues y dejar al panel nuevo sin raton.

     Los accesos —admin, banda, crew, negocio— van por AbrirAcceso; las pestañas
     —inventario, personaje, vehiculo, ciudad— por AbrirEnPestana. ]]
RegisterNUICallback('police:irDelRiel', function(data, cb)
    cb('ok')

    --[[ Con la tablet DENTRO del panel, se va con el. Sin esto InPause se
         quedaba en true despues de saltar: el hilo de TogglePause seguia
         bloqueando todos los controles (DisableAllControlActions) para
         siempre. Las banderas del panel se apagan ANTES, o TogglePause(false)
         creeria que el panel sigue delante y volveria a coger el foco. ]]
    MenuRapidoAbierto = false
    MarcoDeLaTablet = false
    if InPause then TogglePause(false) end

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    --[[ El menu rapido ya no esta delante. La interfaz se desmonta en el acto
         y su `focus` (el que pondria esto a false) no llega a mandarse, asi
         que se hace aqui. Sin esto, MenuRapidoAbierto se quedaba en true: la
         tablet creia tener el menu detras, al cerrarla no soltaba el raton
         (TogglePause) y EstaAbierto mentia al inventario (16/09). ]]
    MenuRapidoAbierto = false
    if not exports["origen_police"]:InTablet() then
        TriggerEvent('qv2:suppressHud', false)
    end

    if GetResourceState(INVENTARIO) ~= 'started' then return end

    local destino = data and data.id
    if not destino or destino == 'policia' then return end   -- ya estas aqui

    --[[ A los 200 y no a los 150: la columna tarda 260 ms en recogerse, asi
         que abriendo a mitad del recorrido el panel que entra empieza a
         deslizarse mientras este acaba de salir y no queda ni un fotograma de
         pantalla vacia. La barra del canto no se mueve en ningun momento.

         El `true` es el aviso de RELEVO: el que entra pinta su riel ya puesto
         en vez de deslizarlo, porque el de aqui sigue ahi hasta desmontarse. ]]
    CreateThread(function()
        Wait(200)
        if destino == 'admin' or destino == 'banda' or destino == 'crew' or destino == 'negocio'
            or destino == 'mascotas' or destino == 'radio' then
            exports[INVENTARIO]:AbrirAcceso(destino, true)
        else
            exports[INVENTARIO]:AbrirEnPestana(destino, true)
        end
    end)
end)

--[[ Para que el inventario pueda comprobar, tras pasarle el relevo, que este
     panel llego a abrirse de verdad. Si no, se quedaria con el foco de la NUI
     puesto y ninguna pantalla delante: el raton en medio y la camara sin
     responder. Ver VigilarRelevo en origen_inventory. ]]
exports('EstaAbierto', function()
    return MenuRapidoAbierto == true
end)
