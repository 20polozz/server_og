Config.Taller = {
    --[[ Tarifa de mano de obra de un taller recien abierto. Es el precio BASE:
         `origen_mechanic` le aplica encima su multiplicador de clase, igual que
         hacia con la tarifa de referencia de Config.Budget.Labor. ]]
    DefaultLabor = {
        component = 450,
        service = 140,
        body = 350
    },

    LaborRange = { min = 0, max = 50000 },

    --[[ Radio que valida el SERVIDOR entre el jugador y el punto `taller` del
         negocio. Mas ancho que el 1.5 del punto de interaccion a proposito: el
         cliente firma o paga de pie junto al coche, no clavado en el marcador. ]]
    PointDistance = 14.0,

    Stock = {
        slots = 80,
        weight = 600000
    },

    --[[ El proveedor al por mayor. El precio es el COSTE del taller, no lo que
         paga el cliente: el margen sale de la mano de obra.

         Esto es la LISTA DE PARTIDA, no la fuente de verdad. Siembra
         `origen_businesses_supplier_prices` la primera vez y aporta las piezas
         que la tabla todavia no tenga; el precio que se cobra sale siempre de
         la tabla, que edita un administrador con /adminproveedor. Cambiar un
         numero de aqui no mueve un catalogo ya sembrado.

         La lista va por nombre de item y no por clave de pieza porque este
         recurso no conoce `Config.Components` de `origen_mechanic`, y tampoco
         debe: aqui se compra un item de inventario. ]]
    Supplier = {
        pieza_motor = 1500,
        pieza_transmision = 1200,
        pieza_frenos = 380,
        pieza_refrigeracion = 430,
        pieza_inyeccion = 400,
        pieza_direccion = 340,
        pieza_alternador = 300,
        pieza_suspension = 540,
        pieza_motor_electrico = 1800,
        pieza_bateria_ev = 2200,

        servicio_aceite = 65,
        servicio_filtro_aire = 50,
        servicio_pastillas = 130,
        servicio_filtro_combustible = 55,
        servicio_bujias = 80,
        servicio_liquido_frenos = 55,
        servicio_anticongelante = 55,
        servicio_correa = 150,
        servicio_liquido_direccion = 55,
        servicio_refrigerante_bateria = 110,
        servicio_liquido_transmision = 75,
        servicio_cableado_at = 160,
        servicio_neumaticos = 230,

        pieza_puerta = 600,
        pieza_capo = 460,
        pieza_porton = 460,
        pieza_rueda = 380,
        pieza_luna = 300,

        kit_parche = 250,
        herramienta_diagnostico = 1800,
        herramienta_chapa = 1600,
        libro_servicio = 250
    },

    SupplierMaxUnits = 50,

    SupplierPriceRange = { min = 1, max = 1000000 },

    --[[ Cuenta con la que paga el cliente la factura del taller. `bank` pasa por
         `origen_banking`, que le pregunta con cual de sus cuentas paga. ]]
    PaymentAccount = 'bank'
}
