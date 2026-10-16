Config = {}

Config.MenuCommand = 'sonidos'
Config.SoundproofingPrice = 0
Config.DefaultPreviewVolume = 0.5

Config.Categories = {
    { id = 'all', label = 'Todos' },
    { id = 'super', label = 'Superdeportivos' },
    { id = 'muscle', label = 'Muscle / Clásicos' },
    { id = 'moto', label = 'Motocicletas' },
    { id = 'electric', label = 'Híbridos / Eléctricos' }
}

Config.Sounds = {
    -- Superdeportivos
    { id = 't20', label = 'Progen T20 V8', category = 'super', audio = 'T20', price = 0, description = 'Rugido biturbo de alta gama con soplido de válvula premium.' },
    { id = 'zentorno', label = 'Pegassi Zentorno V12', category = 'super', audio = 'ZENTORNO', price = 0, description = 'Sonido metálico y agresivo de altas revoluciones italiano.' },
    { id = 'adder', label = 'Truffade Adder W16', category = 'super', audio = 'ADDER', price = 0, description = 'Rugido masivo de motor cuádruple turbo W16 con gran resonancia.' },
    { id = 'sultan', label = 'Karin Sultan RS', category = 'super', audio = 'SULTAN', price = 0, description = 'Rugido de 6 cilindros en línea japonés con petardeo deportivo.' },
    { id = 'banshee', label = 'Bravado Banshee V10', category = 'super', audio = 'BANSHEE', price = 0, description = 'Rugido ronco y potente de gran cilindrada americano.' },
    { id = 'coquette', label = 'Invetero Coquette V8', category = 'super', audio = 'COQUETTE', price = 0, description = 'Sonido clásico de superdeportivo Corvette con empuje agresivo.' },

    -- Muscle / Clásicos
    { id = 'dominator', label = 'Vapid Dominator V8', category = 'muscle', audio = 'DOMINATOR', price = 0, description = 'Sonido clásico de muscle car americano con ralentí inestable y brutal.' },
    { id = 'sabre', label = 'Declasse Sabre GT', category = 'muscle', audio = 'SABRE', price = 0, description = 'Rugido rudo y sordo de bloque clásico carburado.' },
    { id = 'dukes', label = 'Imponte Dukes Charger', category = 'muscle', audio = 'DUKES', price = 0, description = 'Compresor volumétrico y rugido ensordecedor de cuarto de milla.' },
    { id = 'vigero', label = 'Declasse Vigero V8', category = 'muscle', audio = 'VIGERO', price = 0, description = 'Clásico ralentí de cam-mediano con sonido de escape metálico.' },

    -- Motocicletas
    { id = 'bati', label = 'Pegassi Bati 801', category = 'moto', audio = 'BATI', price = 0, description = 'Motor tetracilíndrico superbike que grita hasta las 14,000 RPM.' },
    { id = 'double', label = 'Dinka Double T', category = 'moto', audio = 'DOUBLE', price = 0, description = 'Escape deportivo de alto flujo para moto de pista de competición.' },
    { id = 'sanchez', label = 'Maibatsu Sanchez 2T', category = 'moto', audio = 'SANCHEZ', price = 0, description = 'El sonido inconfundible de motor 2 tiempos de motocross.' },
    { id = 'faggio', label = 'Pegassi Faggio', category = 'moto', price = 0, audio = 'FAGGIO', description = 'El zumbido clásico de scooter urbana de 50cc.' },

    -- Híbridos / Eléctricos (Silent/Cabin soundproofing)
    { id = 'voltic', label = 'Coil Voltic Silent', category = 'electric', audio = 'VOLTIC', price = 0, description = 'Silencio casi absoluto con un sutil zumbido magnético eléctrico futurista.' },
    { id = 'tezeract', label = 'Coil Tezeract Hyper', category = 'electric', audio = 'TEZERACT', price = 0, description = 'Sonido eléctrico de inducción magnética hiperdeportiva espacial.' },
    { id = 'dilettante', label = 'Karin Dilettante Eco', category = 'electric', audio = 'DILETTANTE', price = 0, description = 'Modo eco e híbrido urbano de bajísima sonoridad.' }
}
