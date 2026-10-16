Config.K9AllowedJobs = {
    ['police'] = { minGrade = 0, adminMinGrade = 12, model = 'dwxunit', type = 'police' },
    ['sheriff'] = { minGrade = 0, adminMinGrade = 12, model = 'dwxunit', type = 'police' },
    ['ambulance'] = { minGrade = 0, adminMinGrade = 15, model = 'dwxunit', type = 'rescue' },
    ['sapd'] = { minGrade = 0, adminMinGrade = 0, model = 'dwxunit', type = 'police' },
}

Config.K9DefaultModel = 'dwxunit'

Config.K9DetectableItems = {}

Config.K9AllowedVehicles = {
}

Config.K9SpecialtyDefinitions = {
    ['drugs'] = { label = 'Drogas', icon = 'fa-cannabis' },
    ['weapons'] = { label = 'Armas', icon = 'fa-gun' },
    ['money'] = { label = 'Dinero/Otros', icon = 'fa-money-bill' },
    ['explosives'] = { label = 'Explosivos', icon = 'fa-bomb' }
}

Config.K9ItemCategories = {
}


Config.K9Lang = {
    summon_k9 = 'K9 Solicitado',
    dismiss_k9 = 'K9 Guardado',
    dog_name = 'Rex',
    menu_title = 'Operaciones K9',
    sit = 'Sentarse',
    lie_down = 'Tumbarse',
    follow = 'Seguir',
    attack = 'Atacar',
    guard_person = 'Custodiar Persona',
    stop_guard = 'Dejar de Custodiar',
    leash = 'Correa',
    search_person = 'Buscar Persona',
    search_vehicle = 'Buscar Vehículo',
    enter_vehicle = 'Entrar/Salir Vehículo',
    vehicle_searched = 'Vehículo registrado.',
    nothing_found = 'Nada ilegal encontrado.',
    found_something = '¡Guau! ¡Guau! (¡El perro ha encontrado algo sospechoso!)',
    no_one_nearby = 'Nadie cerca para registrar.',
    no_vehicle_nearby = 'Ningún vehículo cerca.',
    attack_command = '¡Orden de ataque enviada!',
    stop_attack = 'Detener Ataque',
    vehicle_too_far = 'El vehículo está demasiado lejos.',
    k9_spawn_error = 'No puedes solicitar un K9 en este momento.',
    k9_following = 'El K9 te está siguiendo.',
    no_seats = '¡No hay asientos libres!',
    must_be_in_vehicle = 'Debes estar en un vehículo o el perro debe estar en uno.'
}

Config.K9Anims = {
    Sit = {
        dict = "creatures@rottweiler@amb@world_dog_sitting@base",
        anim = "base",
    },
    Lie = {
        dict = "creatures@rottweiler@amb@sleep_in_kennel@",
        anim = "sleep_in_kennel",
    },
    Search = {
        dict = "creatures@rottweiler@indication@",
        anim = "indicate_low",
    }
}

Config.K9Progression = { 
    XPPerPeriod = 0.5, 
    PeriodTime = 30 * 60 * 1000,
    SpecialtySlots = {
        { xp = 0, slots = 1 },
        { xp = 500, slots = 2 },
        { xp = 1500, slots = 3 },
        { xp = 3000, slots = 4 }
    }
}
