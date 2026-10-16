--[[ LA COMPRAVENTA DE VEHÍCULOS

     Antes vivía en `origen_compraventa`, un recurso aparte. No lo era de
     verdad: los menús los abría este recurso y el dinero lo escribía aquí, así
     que era una función de los concesionarios repartida en dos carpetas. Con la
     costura de por medio se caía sola cada vez que se reiniciaba este —lo
     declaraba como dependencia— y había que acordarse de levantarla a mano.

     Va bajo `Config.Compraventa` y no suelto en `Config` a propósito: el
     fichero de antes empezaba por `Config = {}` y aquí eso se llevaría por
     delante la configuración entera del recurso.
]]

Config = Config or {}

Config.Compraventa = {
    --[[ Qué negocios pueden usar el traspaso.

         Se admite el id o el nombre, porque `origen_businesses` los identifica
         de las dos maneras según de dónde venga la llamada. ]]
    AllowedBusinesses = {
        ['cardealer'] = true,
        ['compraventa'] = true,
        [150] = true,
        ['150'] = true,
    },

    --- De dónde sale el dinero de la compra: 'bank' o 'cash'.
    PaymentAccount = 'bank',

    --[[ Qué porcentaje del total se queda el negocio como comisión. El resto va
         al vendedor. A 100 se lo lleva todo el local. ]]
    BusinessTaxRate = 10,

    --- Metros como mucho entre el coche, el empleado y el comprador.
    InteractionDistance = 5.0,
}
