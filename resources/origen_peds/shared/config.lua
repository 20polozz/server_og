Config = Config or {}

Config.Peds = {
    appearanceResource      = 'origen_clothing',
    reloadTimeout           = 10000,
    storeColumnTimeout      = 60000,
    appearanceSchemaTimeout = 60000,
}

--- Modelos que representan al personaje del jugador, no a un ped comprable.
Config.BaseModels = {
    ['mp_m_freemode_01'] = true,
    ['mp_f_freemode_01'] = true,
}

Config.Textos = {
    noDisponible   = 'El sistema de peds no esta disponible.',
    noEsTuyo       = 'Ese ped no te pertenece.',
    sinBase        = 'No se encontro tu personaje original.',
    enCurso        = 'Espera a que termine el cambio anterior.',
    equipado       = 'Ped equipado.',
    quitado        = 'Volviste a tu personaje.',
    error          = 'No se pudo cambiar de ped.',
    desincronizado = 'El ped se guardo pero no se pudo aplicar. Reconecta para verlo.',
}
