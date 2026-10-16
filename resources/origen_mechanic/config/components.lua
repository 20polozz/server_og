--[[ Las piezas de servicio asociadas NO se declaran aqui: se derivan de
     Config.Services en shared/utils.lua. Dos listas cruzadas escritas a mano se
     desincronizan en la primera pieza nueva. ]]
Config.Components = {
    motor = {
        label = 'Motor',
        type = Mechanic.FuelType.COMBUSTION,
        order = 1
    },
    transmision = {
        label = 'Transmisión',
        type = Mechanic.FuelType.COMBUSTION,
        order = 2
    },
    frenos = {
        label = 'Frenos',
        type = Mechanic.FuelType.BOTH,
        order = 3
    },
    refrigeracion = {
        label = 'Refrigeración',
        type = Mechanic.FuelType.COMBUSTION,
        order = 4
    },
    inyeccion = {
        label = 'Inyección',
        type = Mechanic.FuelType.COMBUSTION,
        order = 5
    },
    direccion = {
        label = 'Dirección',
        type = Mechanic.FuelType.BOTH,
        order = 6
    },
    alternador = {
        label = 'Alternador',
        type = Mechanic.FuelType.COMBUSTION,
        order = 7
    },
    suspension = {
        label = 'Suspensión',
        type = Mechanic.FuelType.BOTH,
        order = 8
    },
    motor_electrico = {
        label = 'Motor eléctrico',
        type = Mechanic.FuelType.ELECTRIC,
        order = 9
    },
    bateria_ev = {
        label = 'Batería EV',
        type = Mechanic.FuelType.ELECTRIC,
        order = 10
    }
}
