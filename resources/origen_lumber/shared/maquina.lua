--[[ Las máquinas de este trabajo (piezas, puntos, efectos y luces).

     GENERADO por construir_maquinas.py (m_aserradero.py, en fuente/) a partir de
     los modelos: no tocar a mano. ]]

Maquinas = Maquinas or {}

Maquinas.parque = {
    cuerpo = 'origen_as_parque',
    piezas = {
    },
    notas = {  },
    puntos = { caida = vec3(5.6, 0.0, 0.95) },
    efectos = {  },
    luces = {  },
}

Maquinas.grua = {
    cuerpo = 'origen_as_grua',
    piezas = {
        carro = { modelo = 'origen_as_grua_carro', pos = vec3(0.0, 0.0, 7.4), tipo = 'desliza', eje = vec3(1.0, 0.0, 0.0) },
        pinza = { modelo = 'origen_as_grua_pinza', pos = vec3(0.0, 0.0, -1.0), tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), padre = 'carro' },
        tronco = { modelo = 'prop_log_01', pos = vec3(0.0, 0.0, -0.55), padre = 'pinza', oculta = true },
    },
    notas = { z_pinza = 6.4 },
    puntos = {  },
    efectos = {  },
    luces = { baliza = { punto = vec3(0.0, 0.0, 8.5), color = vec3(255.0, 140.0, 10.0), rango = 12.0, fuerza = 4.0, marcha = true } },
}

Maquinas.descortezadora = {
    cuerpo = 'origen_as_descortezadora',
    piezas = {
        rotor = { modelo = 'origen_as_descortezadora_rotor', pos = vec3(0.0, 0.0, 1.15), tipo = 'giro', eje = vec3(0.0, 1.0, 0.0), giro = 540.0 },
        tronco = { modelo = 'prop_log_01', pos = vec3(0.0, -3.6, 1.15), tipo = 'desliza', eje = vec3(0.0, 1.0, 0.0), oculta = true },
    },
    notas = { recorrido = 7.2 },
    puntos = { entrada = vec3(0.0, -3.6, 1.15), salida = vec3(0.0, 3.6, 1.15) },
    efectos = { astillas = { punto = vec3(0.0, 1.0, 1.15) }, corteza = { punto = vec3(-2.05, 0.0, 1.0) } },
    luces = {  },
    temblor = { radio = 5.0, fuerza = 0.04 },
}

Maquinas.sierra = {
    cuerpo = 'origen_as_sierra',
    piezas = {
        rueda1 = { modelo = 'origen_as_sierra_rueda', pos = vec3(1.13, 0.0, 0.25), tipo = 'giro', eje = vec3(0.0, 1.0, 0.0), giro = 720.0 },
        rueda2 = { modelo = 'origen_as_sierra_rueda', pos = vec3(1.13, 0.0, 3.55), tipo = 'giro', eje = vec3(0.0, 1.0, 0.0), giro = 720.0 },
        carro = { modelo = 'origen_as_sierra_carro', pos = vec3(0.0, -3.2, 0.0), tipo = 'desliza', eje = vec3(0.0, 1.0, 0.0) },
        tronco = { modelo = 'prop_log_01', pos = vec3(0.0, 0.0, 1.05), padre = 'carro', oculta = true },
        tabla = { modelo = 'origen_as_tabla', pos = vec3(0.38, 2.0, 0.8), tipo = 'desliza', eje = vec3(0.0, 1.0, 0.0), oculta = true },
    },
    notas = { carro_fin = 6.4, tabla_fin = 4.6 },
    puntos = { entrada = vec3(0.0, -3.2, 1.05), tabla = vec3(0.38, 2.0, 0.8) },
    efectos = { serrin = { punto = vec3(0.18, 0.0, 0.95) } },
    luces = {  },
    temblor = { radio = 5.0, fuerza = 0.03 },
}

Maquinas.apiladora = {
    cuerpo = 'origen_as_apiladora',
    piezas = {
        pila1 = { modelo = 'origen_as_paquete', pos = vec3(1.2, 0.0, 0.2), oculta = true },
        pila2 = { modelo = 'origen_as_paquete', pos = vec3(2.6, 0.0, 0.2), oculta = true },
        pila3 = { modelo = 'origen_as_paquete', pos = vec3(4.0, 0.0, 0.2), oculta = true },
        pila4 = { modelo = 'origen_as_paquete', pos = vec3(1.2, 0.0, 0.82), oculta = true },
        pila5 = { modelo = 'origen_as_paquete', pos = vec3(2.6, 0.0, 0.82), oculta = true },
        pila6 = { modelo = 'origen_as_paquete', pos = vec3(4.0, 0.0, 0.82), oculta = true },
    },
    notas = {  },
    puntos = { entrada = vec3(-0.3, 0.0, 0.85), salida = vec3(4.0, 0.0, 0.2) },
    efectos = {  },
    luces = {  },
}

Maquinas.secadero = {
    cuerpo = 'origen_as_secadero',
    piezas = {
        puerta = { modelo = 'origen_as_secadero_puerta', pos = vec3(0.0, -3.0, 0.15), tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0) },
        vent1 = { modelo = 'origen_as_ventilador', pos = vec3(-1.7, 0.6, 6.0), tipo = 'giro', eje = vec3(0.0, 0.0, 1.0), giro = 300.0 },
        vent2 = { modelo = 'origen_as_ventilador', pos = vec3(1.7, 0.6, 6.0), tipo = 'giro', eje = vec3(0.0, 0.0, 1.0), giro = 300.0 },
    },
    notas = { puerta = 3.6 },
    puntos = { dentro = vec3(0.0, 0.5, 0.15), puerta = vec3(0.0, -4.1, 0.0) },
    efectos = { vapor1 = { punto = vec3(-1.7, 0.6, 6.3) }, vapor2 = { punto = vec3(1.7, 0.6, 6.3) } },
    luces = { dentro = { punto = vec3(0.0, 0.0, 4.1), color = vec3(255.0, 180.0, 110.0), rango = 8.0, fuerza = 2.0, marcha = true } },
}

Maquinas.cinta = {
    cuerpo = 'origen_as_cinta',
    piezas = {
        banda = { modelo = 'origen_as_cinta_banda', marcha = 'origen_as_cinta_banda_on', pos = vec3(0.0, 0.0, 0.0) },
        lado = { modelo = 'origen_as_paquete', pos = vec3(-2.6, 0.0, 0.35), tipo = 'desliza', eje = vec3(1.0, 0.0, 0.0), oculta = true },
        paquete = { modelo = 'origen_as_paquete', pos = vec3(0.0, 0.0, 0.35), tipo = 'desliza', eje = vec3(0.0, 1.0, 0.0), oculta = true },
    },
    notas = { lado = 2.6, largo = 13.9 },
    puntos = {  },
    efectos = {  },
    luces = {  },
}
