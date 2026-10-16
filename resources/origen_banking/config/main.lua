Config.Debug = false

-- SECURITY: Webhook URLs moved to config/server/webhooks.lua (server-only)
Config.Webhook = Config.Webhook or {}

-- IBAN Configuration
Config.IBANPrefix = ''
Config.IBANLength = 16

Config.MaxAccounts = 3 -- Cuentas PROPIAS por jugador, la principal incluida

--[[ ¿Con qué cuenta pagas?

     Cuando un script de compra cobra de banco y el jugador puede pagar con más
     de una cuenta, sale una ventanita para elegir. Lo pide cada compra con
     exports.origen_banking:PreguntarCuenta(source) justo antes de cobrar (ver
     server/classes/account.lua). Los cobros automáticos no preguntan nunca.

     Activo = false  → se cobra siempre de la cuenta activa, como antes.
     Tiendas         → el nombre con el que sale cada recurso en la ventanita. ]]
Config.ElegirCuenta = {
    Activo = true,
    Tiendas = {
        origen_fuel = 'Gasolinera',
        origen_fishing = 'Lonja',
        origen_emergency_dealership = 'Concesionario de emergencias',
        origen_games = (GetConvar('origen:marca', 'origen') == 'nacion' and 'Nación' or 'Origen') .. ' Games',
        origen_dealership = 'Concesionario',
        origen_carrental = 'Alquiler de coches',
        origen_townhall = 'Ayuntamiento',
        origen_customs = 'Taller de tuning',
        origen_housing = 'Inmobiliaria',
        origen_garages = 'Garaje',
        origen_inventory = 'Tienda',
        origen_police = 'Policía',
        origen_ambulancejob = 'Farmacia',
        origen_businesses = 'Negocio / Comercio',
    },
}
Config.Framework = 'qbx_core'

--[[ Los bancos y los cajeros ya no se escriben aquí: los coloca un
     administrador desde el panel del banco (sección «Sucursales y cajeros») y
     viven en la tabla origen_banking_puntos. Ver server/puntos.lua. ]]

Config.Marker = {
    type = 20,
    color = {0, 0, 0, 200},
    size = vector3(0.3, 0.3, -0.3),
    coords = vector3(0.0, 0.0, 1.0),
    bobUpAndDown = false,
    faceCamera = false,
    rotate = true,
}

--[[ Las máquinas de cajero del mapa ya no funcionan solas: solo los cajeros
     que se colocan desde el panel. ]]

--- Los NPC que ofrece el panel al poner uno. Se puede escribir cualquier otro.
Config.PedsDeBanco = {
    { modelo = 'cs_bankman', nombre = 'Director del banco' },
    { modelo = 'u_m_m_bankman', nombre = 'Empleado de banco' },
    { modelo = 'a_f_y_business_01', nombre = 'Cajera' },
    { modelo = 'a_m_y_business_02', nombre = 'Empleado' },
    { modelo = 's_m_m_security_01', nombre = 'Vigilante' },
    { modelo = 'ig_bankman', nombre = 'Banquero' },
}