--[[ `interval` es la base en kilometros. El intervalo real de cada vehiculo sale
     de multiplicarlo por Config.IntervalMultipliers segun su clase. ]]
Config.Services = {
    aceite = {
        label = 'Aceite',
        interval = 5000,
        components = { 'motor', 'transmision' },
        type = Mechanic.FuelType.COMBUSTION,
        order = 1
    },
    filtro_aire = {
        label = 'Filtro de aire',
        interval = 8000,
        components = { 'motor', 'inyeccion' },
        type = Mechanic.FuelType.COMBUSTION,
        order = 2
    },
    pastillas = {
        label = 'Pastillas de freno',
        interval = 10000,
        components = { 'frenos' },
        type = Mechanic.FuelType.BOTH,
        order = 3
    },
    filtro_combustible = {
        label = 'Filtro de combustible',
        interval = 12000,
        components = { 'inyeccion' },
        type = Mechanic.FuelType.COMBUSTION,
        order = 4
    },
    bujias = {
        label = 'Bujías',
        interval = 15000,
        components = { 'motor' },
        type = Mechanic.FuelType.COMBUSTION,
        order = 5
    },
    liquido_frenos = {
        label = 'Líquido de frenos',
        interval = 15000,
        components = { 'frenos' },
        type = Mechanic.FuelType.BOTH,
        order = 6
    },
    anticongelante = {
        label = 'Anticongelante',
        interval = 15000,
        components = { 'refrigeracion' },
        type = Mechanic.FuelType.COMBUSTION,
        order = 7
    },
    correa = {
        label = 'Correa de distribución',
        interval = 20000,
        components = { 'alternador', 'refrigeracion' },
        type = Mechanic.FuelType.COMBUSTION,
        order = 8
    },
    liquido_direccion = {
        label = 'Líquido de dirección',
        interval = 20000,
        components = { 'direccion' },
        type = Mechanic.FuelType.BOTH,
        order = 9
    },
    refrigerante_bateria = {
        label = 'Refrigerante de batería',
        interval = 20000,
        components = { 'bateria_ev' },
        type = Mechanic.FuelType.ELECTRIC,
        order = 10
    },
    liquido_transmision = {
        label = 'Líquido de transmisión',
        interval = 25000,
        components = { 'transmision' },
        type = Mechanic.FuelType.COMBUSTION,
        order = 11
    },
    cableado_at = {
        label = 'Cableado de alta tensión',
        interval = 25000,
        components = { 'motor_electrico' },
        type = Mechanic.FuelType.ELECTRIC,
        order = 12
    },
    neumaticos = {
        label = 'Neumáticos',
        interval = 50000,
        components = {},
        type = Mechanic.FuelType.BOTH,
        order = 13
    }
}
