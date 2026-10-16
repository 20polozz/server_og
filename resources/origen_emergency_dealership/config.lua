Config = {}

-- Comando opcional para abrir/teletransportar al concesionario
Config.Commands = { 'concesionarioemergencias', 'garajepolicia', 'policedealership' }

-- Comandos de Administración In-Game
Config.AdminCommands = { 'edadmin', 'garajeadmin', 'emergencydealershipadmin' }

-- Asignar routing bucket de instancia al jugador (false = Todo en dimension 0)
Config.UseRoutingBucket = false

-- Tiempo de prueba de conducción (en segundos)
Config.TestDriveTime = 60

-- Coordenadas de Entrada Exterior (Comisaría MRPD)
Config.OutsideEntrance = vec4(457.85, -1022.39, 27.35, 92.91)

-- Coordenadas de Entrega para Vehículos Comprados (Exterior)
Config.PurchaseSpawnCoords = vec4(447.03, -1020.69, 27.49, 90.66)

-- Coordenadas de Entrega para Prueba de Conducción (Exterior)
Config.TestDriveSpawnCoords = vec4(447.03, -1020.69, 27.49, 90.66)

-- Coordenadas de Aparición del Jugador dentro del Garaje
Config.InsideGarageCenter = vec4(448.62, -973.99, -68.5, 172.83)

-- Prop Principal / Shell Interior del Garaje
Config.GarageProp = {
    model = 'origen_policegarage',
    coords = vec4(458.24, -1003.6, -67.21, 0.0)
}

-- Puerta de Salida del Garaje
Config.InsideExitDoorCoords = vec4(452.99, -977.28, -68.5, 2.68)

-- Props Adicionales / Decoración en Coordenadas Concretas (Opcional)
Config.Props = {}

-- Vehículos y Plazas de Exposición en el Garaje (Guardado permanente en BBDD)
Config.Vehicles = {
    -- =========================================================================
    -- PLAZAS YA CONFIGURADAS
    -- =========================================================================
    -- Sedanes (6 Plazas asignadas)
    { model = 'onx_polbuff', label = 'Police Buffalo', price = 25000, desc = 'Sedán de patrulla rápido e icónico.', coords = vec4(490.93, -978.58, -68.98, 179.93) },
    { model = 'onx_polbuff2', label = 'Police Buffalo STX 2', price = 35000, desc = 'Sedán de alta potencia STX.', coords = vec4(485.74, -978.64, -68.77, 179.59) },
    { model = 'onx_polmonar', label = 'Police Monarch', price = 28000, desc = 'Sedán de lujo para patrulla ejecutiva.', coords = vec4(481.08, -978.65, -68.69, 177.4) },
    { model = 'onx_polmerit', label = 'Police Merit', price = 20000, desc = 'Patrulla urbana clásica y resistente.', coords = vec4(476.2, -978.61, -69.19, 179.53) },
    { model = 'onx_poltulip', label = 'Police Tulip M-100', price = 22000, desc = 'Patrulla deportiva M-100.', coords = vec4(471.9, -978.78, -68.99, 181.55) },
    { model = 'onx_poltavros', label = 'Police Tavros', price = 30000, desc = 'Sedán de gran tracción y estabilidad.', coords = vec4(466.7, -978.46, -68.73, 179.85) },

    -- SUVs y Todoterrenos (6 Plazas asignadas)
    { model = 'onx_polscout', label = 'Police Scout', price = 35000, desc = 'SUV táctico de alta velocidad.', coords = vec4(491.73, -994.22, -68.85, 0.16) },
    { model = 'onx_poldorado', label = 'Police Dorado', price = 38000, desc = 'SUV de intervención pesada.', coords = vec4(486.67, -994.65, -68.96, 0.4) },
    { model = 'onx_polterm', label = 'Police Terminus', price = 42000, desc = 'Todoterreno táctico reforzado.', coords = vec4(480.95, -994.67, -68.82, 0.52) },
    { model = 'onx_polalamo', label = 'Police Alamo 2700LX', price = 32000, desc = 'SUV polivalente para todo terreno.', coords = vec4(476.55, -994.27, -68.85, 0.72) },
    { model = 'onx_polgrang', label = 'Police Granger 3600LX', price = 40000, desc = 'SUV de gran capacidad e blindaje.', coords = vec4(472.6, -994.8, -68.81, 1.86) },
    { model = 'onx_polsem', label = 'Police Seminole Frontier', price = 29000, desc = 'SUV todoterreno de patrulla rural.', coords = vec4(468.56, -994.39, -69.06, 1.17) },

    -- Pickups y 4x4 (6 Plazas asignadas)
    { model = 'onx_polcara', label = 'Police Caracara Raid', price = 45000, desc = 'Pickup 4x4 de alta resistencia.', coords = vec4(443.42, -978.78, -68.71, 178.61) },
    { model = 'onx_polbison', label = 'Police Bison 35XD', price = 36000, desc = 'Camioneta pesada 35XD.', coords = vec4(439.07, -978.86, -68.77, 182.74) },
    { model = 'onx_polbison3', label = 'Police Bison Sasquatch', price = 48000, desc = 'Edición extrema todoterreno.', coords = vec4(434.37, -979.02, -68.57, 180.59) },
    { model = 'onx_polinvict', label = 'Police Invictus', price = 50000, desc = 'Pickup táctica de asalto.', coords = vec4(444.69, -994.18, -68.82, 0.24) },
    { model = 'onx_polsand0', label = 'Police Sandstorm D205', price = 42000, desc = 'Pickup reforzada D205.', coords = vec4(428.54, -978.8, -68.74, 181.59) },
    { model = 'onx_polguard', label = 'Police Guardian', price = 55000, desc = 'Camión pesado de transporte táctico.', coords = vec4(440.1, -993.88, -68.35, 359.17) },

    -- Bomberos (2 Plazas asignadas)
    { model = 'onx_firestark', label = 'Camión Bomberos Stark', price = 75000, desc = 'Autobomba de extinción de incendios.', coords = vec4(480.59, -1021.14, -70.93, 90.13) },
    { model = 'onx_fireimpulse', label = 'Camión Bomberos Impulse', price = 80000, desc = 'Camión pesado de rescate y extinción.', coords = vec4(481.07, -1012.59, -70.74, 88.6) },

    -- =========================================================================
    -- VEHÍCULOS DISPONIBLES ONX (SIN PLAZA ASIGNADA AÚN)
    -- Asigna una plaza in-game desde /edadmin colocándote en la posición deseada
    -- =========================================================================
    -- Sedanes
    { model = 'onx_polmerit2', label = 'Police Merit 2', price = 22000, desc = 'Patrulla urbana moderna de respuesta.', coords = nil },
    { model = 'onx_polmerit3', label = 'Police Merit Classic', price = 21000, desc = 'Patrulla urbana clásica.', coords = nil },

    -- SUVs y Todoterrenos
    { model = 'onx_polscout2', label = 'Police Scout Classic', price = 33000, desc = 'SUV táctico clásico.', coords = nil },
    { model = 'onx_poldorado2', label = 'Police Dorado ST', price = 39000, desc = 'SUV de intervención deportiva.', coords = nil },
    { model = 'onx_polterm2', label = 'Police Terminus Overland', price = 44000, desc = 'Todoterreno táctico de expedición.', coords = nil },
    { model = 'onx_polalamo2', label = 'Police Alamo 2', price = 34000, desc = 'SUV Alamo reforzado 4x4.', coords = nil },
    { model = 'onx_polgrang2', label = 'Police Granger 3700LX', price = 41000, desc = 'SUV de asalto pesado.', coords = nil },
    { model = 'onx_polaleu', label = 'Police Aleutian', price = 36000, desc = 'SUV moderno de patrulla.', coords = nil },
    { model = 'onx_polcava', label = 'Police Cavalcade', price = 37000, desc = 'SUV blindado de escolta.', coords = nil },
    { model = 'onx_polstalk', label = 'Police Landstalker', price = 31000, desc = 'SUV de respuesta urbana.', coords = nil },
    { model = 'onx_polregent', label = 'Police Regent', price = 30000, desc = 'SUV ejecutivo de patrulla.', coords = nil },
    { model = 'onx_polregentxl', label = 'Police Regent XL', price = 32000, desc = 'SUV ejecutivo largo.', coords = nil },
    { model = 'onx_polsunset', label = 'Police Sunset', price = 34000, desc = 'SUV de vigilancia y patrulla.', coords = nil },
    { model = 'onx_poljog', label = 'Police Jogger', price = 28000, desc = 'Unidad de patrulla compacta.', coords = nil },
    { model = 'onx_poljog2', label = 'Police Jogger 2', price = 29000, desc = 'Unidad de patrulla compacta V2.', coords = nil },
    { model = 'onx_poljog3', label = 'Police Jogger 3', price = 30000, desc = 'Unidad de patrulla compacta V3.', coords = nil },
    { model = 'onx_poljog4', label = 'Police Jogger 4', price = 31000, desc = 'Unidad de patrulla compacta V4.', coords = nil },

    -- Pickups y 4x4
    { model = 'onx_polbison2', label = 'Police Bison 45XD', price = 38000, desc = 'Camioneta pesada 45XD.', coords = nil },
    { model = 'onx_polbison4', label = 'Police Bison Single Cab', price = 35000, desc = 'Camioneta de cabina simple.', coords = nil },
    { model = 'onx_polinvict2', label = 'Police Invictus 2', price = 52000, desc = 'Pickup táctica de asalto V2.', coords = nil },
    { model = 'onx_polsand0xl', label = 'Police Sandstorm D205 XL', price = 44000, desc = 'Pickup reforzada D205 XL.', coords = nil },
    { model = 'onx_polsand0h', label = 'Police Sandstorm D205 Hellenbach', price = 46000, desc = 'Pickup táctica Hellenbach.', coords = nil },
    { model = 'onx_polsand0sc', label = 'Police Sandstorm D205 Single Cab', price = 40000, desc = 'Pickup D205 cabina simple.', coords = nil },
    { model = 'onx_polsand', label = 'Police Sandstorm', price = 42000, desc = 'Pickup de intervención 4x4.', coords = nil },
    { model = 'onx_polsandxl', label = 'Police Sandstorm XL', price = 44000, desc = 'Pickup de intervención XL.', coords = nil },
    { model = 'onx_polsandh', label = 'Police Sandstorm Hellenbach', price = 46000, desc = 'Pickup de alto rendimiento Hellenbach.', coords = nil },
    { model = 'onx_polsandsc', label = 'Police Sandstorm Single Cab', price = 40000, desc = 'Pickup de cabina simple.', coords = nil },
    { model = 'onx_polsandlwb', label = 'Police Sandstorm Long Wheelbase', price = 45000, desc = 'Pickup de batalla extendida.', coords = nil },
    { model = 'onx_polsandk', label = 'Police Sandstorm K', price = 43000, desc = 'Pickup Sandstorm K.', coords = nil },
    { model = 'onx_polsandk2', label = 'Police Sandstorm K2', price = 44000, desc = 'Pickup Sandstorm K2.', coords = nil },
    { model = 'onx_polsandk3', label = 'Police Sandstorm K3', price = 45000, desc = 'Pickup Sandstorm K3.', coords = nil },
    { model = 'onx_polsandk4', label = 'Police Sandstorm K4', price = 46000, desc = 'Pickup Sandstorm K4.', coords = nil },
    { model = 'onx_polsandk5', label = 'Police Sandstorm K5', price = 47000, desc = 'Pickup Sandstorm K5.', coords = nil },
    { model = 'onx_polsandk6', label = 'Police Sandstorm K6', price = 48000, desc = 'Pickup Sandstorm K6.', coords = nil },
    { model = 'onx_polguard2', label = 'Police Guardian 2', price = 57000, desc = 'Camión pesado táctico V2.', coords = nil },
    { model = 'onx_polguard3', label = 'Police Guardian 3', price = 58000, desc = 'Camión pesado táctico V3.', coords = nil },
    { model = 'onx_polguard4', label = 'Police Guardian 4', price = 60000, desc = 'Camión pesado táctico V4.', coords = nil },

    -- Deportivos, Interceptores y Motos
    { model = 'onx_polgaunt', label = 'Police Gauntlet Interceptor', price = 60000, desc = 'Interceptor de persecución a alta velocidad.', coords = nil },
    { model = 'onx_poldom', label = 'Police Dominator Interceptor', price = 58000, desc = 'Interceptor deportivo Muscle.', coords = nil },
    { model = 'onx_polvigero', label = 'Police Vigero Interceptor', price = 62000, desc = 'Interceptor V8 de alta maniobrabilidad.', coords = nil },
    { model = 'onx_polvstr', label = 'Police Presidente VSTR', price = 65000, desc = 'Super sedán VSTR de alta potencia.', coords = nil },
    { model = 'onx_polbuffhf', label = 'Police Buffalo Hellfire', price = 68000, desc = 'Muscle car Hellfire de interceptación.', coords = nil },
    { model = 'onx_polcoq', label = 'Police Coquette Interceptor', price = 70000, desc = 'Superdeportivo de interceptación extrema.', coords = nil },
    { model = 'onx_polcoq2', label = 'Police Coquette Interceptor 2', price = 72000, desc = 'Superdeportivo de interceptación V2.', coords = nil },
    { model = 'onx_polcoq3', label = 'Police Coquette Interceptor 3', price = 75000, desc = 'Superdeportivo de interceptación V3.', coords = nil },
    { model = 'onx_polkandra', label = 'Police Kandra (Moto)', price = 18000, desc = 'Motocicleta rápida para tráfico y patrulla urbana.', coords = nil },
    { model = 'onx_polverus', label = 'Police Verus ATV (Cuatrimoto)', price = 12000, desc = 'Cuatrimoto ágil para campo y playa.', coords = nil },

    -- Servicios Médicos (EMS)
    { model = 'onx_ambbison', label = 'Ambulancia Bison', price = 30000, desc = 'Ambulancia soporte vital básico.', coords = nil },
    { model = 'onx_ambking', label = 'Ambulancia Speedo King', price = 32000, desc = 'Ambulancia espaciosa de transporte médico.', coords = nil },
    { model = 'onx_ambkee', label = 'Ambulancia Kee', price = 35000, desc = 'Ambulancia pesada para emergencias.', coords = nil },
    { model = 'onx_ambkee2', label = 'Ambulancia Kee 2', price = 36000, desc = 'Ambulancia pesada para emergencias V2.', coords = nil },
    { model = 'onx_ambstorm', label = 'EMS Stormer', price = 40000, desc = 'SUV de intervención rápida médica.', coords = nil },
    { model = 'onx_ambjog', label = 'EMS Granger (Jogger)', price = 27000, desc = 'Unidad VIR de respuesta médica.', coords = nil },
    { model = 'onx_ambjog2', label = 'EMS Scout (Jogger 2)', price = 28000, desc = 'Unidad VIR de respuesta rápida.', coords = nil },
    { model = 'onx_ambjog3', label = 'EMS Alamo (Jogger 3)', price = 29000, desc = 'Unidad SUV de asistencia avanzada.', coords = nil },
    { model = 'onx_gurney', label = 'Camilla Médica Gurney', price = 1500, desc = 'Camilla rodante de asistencia.', coords = nil },

    -- Helicópteros
    { model = 'onx_polcon', label = 'Police Conada Helicopter', price = 120000, desc = 'Helicóptero ligero de reconocimiento táctico.', coords = nil },
    { model = 'onx_polmav', label = 'Police Maverick Helicopter', price = 110000, desc = 'Helicóptero de patrulla aérea con foco.', coords = nil },
    { model = 'onx_polmav2', label = 'Police Maverick Helicopter 2', price = 115000, desc = 'Helicóptero de operaciones especiales aéreas.', coords = nil },
}
