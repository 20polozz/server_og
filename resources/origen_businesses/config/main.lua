Config.Debug = false
Config.Language = 'es'
Config.AllowNegativeBalance = false
Config.AutoCloseBusiness = true


Config.Orders = {
    Interval = 5,
    DeliveryTime = 30,
    -- Pedidos de camino a la vez por negocio (cada uno lleva varios materiales). 0 = sin tope.
    MaxPendingOrders = 10
}

Config.Paycheck = {
    Interval = 30,
    RequireDuty = true,
    DeductFromBusiness = false,
    Account = 'bank'
}

Config.Marker = {
    Type = 22,
    Color = { r = 0, g = 0, b = 0, a = 200 },
    Size = vector3(0.2, 0.2, 0.2),
    Offset = vector3(0.0, 0.0, 1.0),
    Distance = 5.0,
    BobUpAndDown = false,
    FaceCamera = false,
    Rotate = true
}

Config.Tuning = {
    -- Sistemas soportados: origen_customs | qb-mechanicjob | vms_tunning | esx_tunning | okokTunning
    -- (qbx_customs se retiró el 18/09/2026; está en copias/qbx_customs)
    -- origen_customs es el taller propio: lo abre el mecánico de servicio (al
    -- volante o a pie, con el coche junto al punto) y el cliente paga el
    -- presupuesto; el dinero entra en la caja del negocio.
    System = 'origen_customs',
    -- true = abre como admin (sin coste), false = cobra al jugador y permite imputar ingreso al negocio.
    AdminMode = false
}

Config.VehicleRecoveryPrice = 100

Config.Mechanic = {
    -- Lo que le cuesta a la caja de la sociedad cada acción.
    -- Reparar ya no está aquí: es una orden de trabajo del punto `taller`, que
    -- COBRA al cliente en vez de gastar de la caja. Ver config/taller.lua.
    CleanPrice = 15,
    -- Duración de la barra de progreso, en milisegundos.
    CleanDuration = 8000,
    -- Radio en el que el cliente busca el vehículo.
    SearchDistance = 5.0,
    -- Radio que acepta el servidor. Más ancho que el del cliente a propósito:
    -- el vehículo se mueve un poco entre que se pulsa y llega la comprobación.
    MaxDistance = 8.0
}

Config.BusinessBlips = {
    ['general'] = { id = 450, color = 0, scale = 0.6 },
    ['restaurant'] = { id = 93, color = 0, scale = 0.6 },
    ['nightclub'] = { id = 590, color = 0, scale = 0.6 },
    ['mechanic'] = { id = 446, color = 0, scale = 0.6 },
    ['shop'] = { id = 59, color = 0, scale = 0.6 },
    ['store'] = { id = 59, color = 0, scale = 0.6 },
    ['taxi'] = { id = 198, color = 0, scale = 0.6 },
    ['reporters'] = { id = 135, color = 0, scale = 0.6 },
    ['fuel'] = { id = 361, color = 0, scale = 0.6 },
    ['service'] = { id = 614, color = 0, scale = 0.6 },
    ['government'] = { id = 419, color = 0, scale = 0.6 },
    ['compraventa'] = { id = 523, color = 0, scale = 0.6 },
    ['cardealer'] = { id = 523, color = 0, scale = 0.6 }
}
--[[ ── LA CENTRAL DE AVISOS ───────────────────────────────────────────────

     Lo que un ciudadano le pide a un local desde la aplicación Servicios del
     móvil: una grúa, un mecánico, la compra a casa, una mesa. El aviso llega a
     los empleados FICHADOS de ese negocio, no a un trabajo del framework.

     Hasta ahora el móvil mandaba el aviso de «Grúa y mecánico» al despacho de
     origen_police con `job = 'mechanic'`. Esa categoría no existe en
     origen_police, así que el aviso no le llegaba a nadie y el ciudadano veía
     igualmente un «aviso enviado». Aquí los talleres son NEGOCIOS, y es el
     negocio quien tiene que recibirlo.

     Qué puede ofrecer cada local lo decide el catálogo de abajo por tipo de
     negocio, y de ahí cada uno enciende o apaga lo que quiera en Ajustes. ]]
Config.Central = {}

--- El tiempo que un aviso aguanta sin que nadie lo coja, en segundos. Pasado
--- eso se cae solo y al cliente se le dice: un aviso de hace media hora que
--- sigue en pantalla es peor que ninguno.
Config.Central.Caduca = 15 * 60

--- Y lo que aguanta ya cogido antes de darse por abandonado. Más largo porque
--- ahí hay alguien conduciendo hasta el otro lado del mapa.
Config.Central.CaducaCogido = 45 * 60

--- Avisos abiertos a la vez por negocio. Un local con veinte avisos sin
--- atender no es una central, es una lista de la compra.
Config.Central.MaxPorNegocio = 12

--- Y los que puede tener abiertos la misma persona (en todos los locales).
Config.Central.MaxPorCliente = 3

--- Segundos entre avisos de la misma persona.
Config.Central.Espera = 45

--- Lo máximo que se puede facturar al cerrar un aviso.
Config.Central.MaxImporte = 100000

--- A cuántos metros del cliente hay que estar para entregar un pedido o
--- cerrar un aviso cobrando. El servidor lo comprueba: si no, se podría
--- entregar la compra desde el otro lado del mapa.
Config.Central.DistanciaEntrega = 12.0

--- Artículos distintos que caben en un pedido, y unidades por artículo.
Config.Central.MaxLineas = 12
Config.Central.MaxUnidades = 50

--[[ Los servicios que existen.

     `tipos` es en qué clase de negocio tiene sentido ofrecerlo; `pordefecto`,
     si viene encendido al crear el local. Un negocio puede apagar cualquiera
     desde Ajustes, y encender los que su tipo permita.

     `pide` dice qué rellena el ciudadano en el móvil:
       · 'texto'    una explicación y ya;
       · 'vehiculo' lo mismo más el coche que tiene delante (lo resuelve el
                    servidor por su posición, no el móvil);
       · 'cesta'    artículos del catálogo del local, con precio y stock. ]]
Config.Central.Servicios = {
    {
        id = 'aviso',
        label = 'Avisar al local',
        desc = 'Hablar con alguien del local',
        icon = 'lucide:message-square',
        pide = 'texto',
        tipos = 'todos',
        pordefecto = true,
    },
    {
        id = 'grua',
        label = 'Grúa',
        desc = 'Que vengan a llevarse el coche',
        icon = 'lucide:truck',
        pide = 'vehiculo',
        --[[ `service` NO: es el tipo de los locales que no encajan en ningún
             otro —Ammunation, el casino, una iglesia, una empresa de
             decoración— y les salía la grúa como si fueran talleres. Un taller
             es `mechanic`; los de coches, `cardealer` y `compraventa`. ]]
        tipos = { mechanic = true, cardealer = true, compraventa = true },
        pordefecto = true,
    },
    {
        id = 'mecanico',
        label = 'Mecánico a domicilio',
        desc = 'Que vengan a arreglarlo aquí',
        icon = 'lucide:wrench',
        pide = 'vehiculo',
        --- Solo un taller arregla coches. Ver la nota de la grúa.
        tipos = { mechanic = true },
        pordefecto = true,
    },
    {
        id = 'pedido',
        label = 'Pedido a domicilio',
        desc = 'Comprar lo que tiene el local y que lo traigan',
        icon = 'lucide:shopping-basket',
        pide = 'cesta',
        --[[ Y los `service` tambien venden: Ammunation, una tienda de
             decoración o el casino tienen género que alguien puede querer que
             le lleven. Lo que sale es lo que el local tenga puesto a la venta
             con stock; sin nada puesto, el móvil dice que no vende nada. ]]
        tipos = {
            shop = true, store = true, restaurant = true, fuel = true,
            nightclub = true, general = true, service = true,
        },
        pordefecto = true,
    },
    {
        id = 'reserva',
        label = 'Reserva',
        desc = 'Apartar mesa o zona',
        icon = 'lucide:calendar-check',
        pide = 'texto',
        tipos = { restaurant = true, nightclub = true },
        pordefecto = false,
    },
}

--- Cómo se llama cada estado por dentro y de cara a la gente.
Config.Central.Estados = {
    open      = 'Sin coger',
    taken     = 'En marcha',
    done      = 'Atendido',
    cancelled = 'Cancelado',
    refused   = 'Rechazado',
    expired   = 'Caducado',
}
