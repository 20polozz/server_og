Mechanic.OrderStatus = {
    QUOTE = 'presupuesto',
    ACCEPTED = 'aceptada',
    RUNNING = 'en_curso',
    FINISHED = 'terminada',
    PAID = 'pagada',
    CANCELLED = 'cancelada'
}

Mechanic.OrderLabels = {
    presupuesto = 'Presupuesto',
    aceptada = 'Aceptada',
    en_curso = 'En curso',
    terminada = 'Terminada',
    pagada = 'Pagada',
    cancelada = 'Cancelada'
}

--[[ El ciclo de vida, escrito como grafo y no repartido por los callbacks. Cada
     transicion se comprueba contra esto, asi que no hay forma de saltar de
     `presupuesto` a `pagada` aunque alguien llame al callback equivocado. ]]
Mechanic.OrderTransitions = {
    presupuesto = { aceptada = true, cancelada = true },
    aceptada    = { en_curso = true, terminada = true, cancelada = true },
    en_curso    = { terminada = true, cancelada = true },
    terminada   = { pagada = true, cancelada = true },
    pagada      = {},
    cancelada   = {}
}

--- Estados en los que la orden sigue viva y consume un hueco del taller.
Mechanic.OrderOpenStatus = {
    presupuesto = true,
    aceptada = true,
    en_curso = true,
    terminada = true
}

Config.WorkOrders = {
    --[[ EL CIERRE DE LA FASE 5.

         Las Fases 3 y 4 dejaron a proposito que cualquiera con la pieza o con
         la herramienta en el bolsillo pudiera usarla, esperando a que existiera
         el punto `taller` de `origen_businesses`. Con esto en `true`,
         diagnosticar y montar piezas es trabajo de taller.

         El kit de parche NO pasa por aqui: es lo que permite a un jugador tirado
         llegar al taller, y cerrarlo convertiria una averia en una espera. ]]
    RequireEmployment = true,

    --[[ Descuentos que puede poner el mecanico al abrir una orden (por ciento).
         El servidor rechaza cualquier otro. `AllowFree` deja abrirla sin cobro
         (vehiculos de policia, acuerdos del taller): el cliente la acepta igual
         y la orden queda marcada, con quien la abrio. ]]
    Discounts = { 10, 15 },
    AllowFree = true,

    --- Distancia a la que el mecanico puede elegir al cliente de una orden.
    ClientDistance = 12.0,

    --- Cuantas ordenes abiertas puede tener un taller a la vez.
    MaxOpenPerBusiness = 40,

    --- Cuantas ordenes abiertas puede tener una misma matricula.
    MaxOpenPerPlate = 2,

    --- Tope de filas que devuelve una consulta de ordenes.
    ListLimit = 60,

    --[[ Cuanto aguanta un presupuesto sin que el cliente lo acepte, en minutos.
         Pasado ese plazo la orden ya no se puede aceptar: los precios de las
         piezas y el estado del coche que la justificaban han cambiado. ]]
    QuoteMinutes = 60
}
