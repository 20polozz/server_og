--[[ ORIGEN · Planta de procesado: máquinas, piezas y montaje.

     GENERADO por fuente/construir.py a partir de los modelos: no tocar a mano.
     Si cambia una medida, se cambia allí y se vuelve a exportar. Qué es
     cada campo está explicado en client/maquinas.lua. ]]

Maquinas = {}

Maquinas.trituradora = {
    cuerpo = 'origen_trituradora',
    piezas = {
        mandibula = { modelo = 'origen_trituradora_mandibula', pos = vec3(0.0, 0.85, 0.85), tipo = 'angulo', eje = vec3(1.0, 0.0, 0.0), vaiven = { centro = 0.0, amp = 1.6, hz = 1.0 } },
        volante = { modelo = 'origen_trituradora_volante', pos = vec3(-1.13, -0.3, 2.35), rumbo = 180.0, tipo = 'giro', eje = vec3(1.0, 0.0, 0.0), giro = -360.0 },
        polea = { modelo = 'origen_trituradora_polea', pos = vec3(1.13, -0.3, 2.35), tipo = 'giro', eje = vec3(1.0, 0.0, 0.0), giro = -360.0 },
        polea_motor = { modelo = 'origen_trituradora_polea_motor', pos = vec3(1.13, -2.3, 0.95), tipo = 'giro', eje = vec3(1.0, 0.0, 0.0), giro = -2013.3 },
    },
    puntos = { boca = vec3(0.0, 0.75, 2.6), salida = vec3(0.0, 2.3, 0.5) },
    efectos = { polvo_boca = { punto = vec3(0.0, 0.75, 2.5), marcha = true }, polvo_salida = { punto = vec3(0.0, 2.25, 0.45), marcha = true }, riego = { punto = vec3(0.0, 0.0, 2.95), marcha = true } },
    luces = { riego = { punto = vec3(1.4, 0.1, 1.4), color = vec3(255.0, 90.0, 30.0), rango = 1.2, fuerza = 0.5, marcha = true } },
    temblor = { radio = 7.0, fuerza = 0.06 },
}

Maquinas.cinta_subida = {
    cuerpo = 'origen_planta_cinta_subida',
    piezas = {
        banda = { modelo = 'origen_planta_cinta_subida_banda', marcha = 'origen_planta_cinta_subida_banda_movil', pos = vec3(0.0, 0.0, 0.0) },
        tambor = { modelo = 'origen_planta_cinta_subida_tambor', pos = vec3(0.0, 11.2797, 3.3366), tipo = 'giro', eje = vec3(1.0, 0.0, 0.0), giro = -143.2 },
    },
    recorrido = {
        vec3(0.0, 0.0, 0.69),
        vec3(0.0, 0.475, 0.69),
        vec3(0.0, 0.95, 0.69),
        vec3(0.0, 1.425, 0.69),
        vec3(0.0, 1.9, 0.69),
        vec3(0.0, 2.375, 0.69),
        vec3(0.0, 2.85, 0.69),
        vec3(0.0, 3.325, 0.69),
        vec3(0.0, 3.795, 0.69),
        vec3(0.0, 4.036, 0.714),
        vec3(0.0, 4.274, 0.738),
        vec3(0.0, 4.512, 0.805),
        vec3(0.0, 4.75, 0.871),
        vec3(0.0, 5.201, 1.067),
        vec3(0.0, 5.659, 1.266),
        vec3(0.0, 6.116, 1.464),
        vec3(0.0, 6.573, 1.663),
        vec3(0.0, 7.03, 1.861),
        vec3(0.0, 7.487, 2.06),
        vec3(0.0, 7.944, 2.258),
        vec3(0.0, 8.401, 2.457),
        vec3(0.0, 8.859, 2.656),
        vec3(0.0, 9.316, 2.854),
        vec3(0.0, 9.773, 3.053),
        vec3(0.0, 10.23, 3.251),
        vec3(0.0, 10.687, 3.45),
        vec3(0.0, 11.144, 3.648),
        vec3(0.0, 11.427, 3.75),
        vec3(0.0, 11.724, 3.693),
        vec3(0.0, 12.067, 3.406),
    },
    velocidad = 0.5,
}

Maquinas.cinta_salida = {
    cuerpo = 'origen_planta_cinta_salida',
    piezas = {
        banda = { modelo = 'origen_planta_cinta_salida_banda', marcha = 'origen_planta_cinta_salida_banda_movil', pos = vec3(0.0, 0.0, 0.0) },
        tambor = { modelo = 'origen_planta_cinta_salida_tambor', pos = vec3(0.0, 7.4465, 1.9874), tipo = 'giro', eje = vec3(1.0, 0.0, 0.0), giro = -191.0 },
    },
    recorrido = {
        vec3(0.0, 0.0, 0.47),
        vec3(0.0, 0.467, 0.47),
        vec3(0.0, 0.933, 0.47),
        vec3(0.0, 1.395, 0.47),
        vec3(0.0, 1.636, 0.494),
        vec3(0.0, 1.877, 0.518),
        vec3(0.0, 2.117, 0.576),
        vec3(0.0, 2.36, 0.634),
        vec3(0.0, 2.811, 0.781),
        vec3(0.0, 3.266, 0.929),
        vec3(0.0, 3.72, 1.078),
        vec3(0.0, 4.175, 1.226),
        vec3(0.0, 4.629, 1.374),
        vec3(0.0, 5.084, 1.522),
        vec3(0.0, 5.538, 1.67),
        vec3(0.0, 5.993, 1.819),
        vec3(0.0, 6.448, 1.967),
        vec3(0.0, 6.902, 2.115),
        vec3(0.0, 7.357, 2.263),
        vec3(0.0, 7.648, 2.337),
        vec3(0.0, 7.938, 2.253),
        vec3(0.0, 8.253, 1.935),
    },
    velocidad = 0.5,
}

Maquinas.tolva = {
    cuerpo = 'origen_planta_tolva',
    piezas = {
    },
    puntos = { descarga = vec3(0.0, 1.9, 1.3), tope = vec3(0.0, -1.3, 0.3) },
    efectos = { polvo_descarga = { punto = vec3(0.0, 1.9, 1.35) } },
}

Maquinas.contenedor = {
    huella = { -1.1, 1.1, -1.0, 1.0 },
    cuerpo = 'origen_planta_contenedor',
    piezas = {
        compuerta = { modelo = 'origen_planta_contenedor_compuerta', pos = vec3(0.0, 0.995, 1.0), tipo = 'angulo', eje = vec3(1.0, 0.0, 0.0) },
        monton = { modelo = 'origen_planta_monton_grava', pos = vec3(0.0, 0.0, 1.02), tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), inicio = -1.1, variantes = { grava = 'origen_planta_monton_grava', carbon = 'origen_planta_monton_carbon', hierro = 'origen_planta_monton_hierro', cobre = 'origen_planta_monton_cobre', cuarzo = 'origen_planta_monton_cuarzo', oro = 'origen_planta_monton_oro' } },
    },
    puntos = { entrada = vec3(0.0, -0.3, 1.8), recoger = vec3(0.0, 1.55, 0.6) },
}

Maquinas.fundicion = {
    huella = { -2.2, 2.2, -1.8, 2.8 },
    cuerpo = 'origen_planta_fundicion',
    piezas = {
        horno = { modelo = 'origen_planta_fundicion_horno', pos = vec3(0.0, 0.0, 1.6), tipo = 'angulo', eje = vec3(1.0, 0.0, 0.0), variantes = { vacio = 'origen_planta_fundicion_horno', lleno = 'origen_planta_fundicion_horno_lleno' } },
        tapa = { modelo = 'origen_planta_fundicion_tapa', padre = 'horno', pos = vec3(0.0, -0.78, 0.63), tipo = 'angulo', eje = vec3(1.0, 0.0, 0.0) },
        chorro = { modelo = 'origen_planta_fundicion_chorro', ancla = { pieza = 'horno', punto = vec3(0.0, 1.07, 0.52) }, oculta = true },
        carrusel = { modelo = 'origen_planta_fundicion_carrusel', pos = vec3(0.0, 1.64, 0.62), tipo = 'angulo', eje = vec3(0.0, 0.0, 1.0) },
        metal1 = { modelo = 'origen_planta_lingote_caliente', padre = 'carrusel', pos = vec3(0.0, -0.55, 0.121), rumbo = -90.0, tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), inicio = -0.08, variantes = { caliente = 'origen_planta_lingote_caliente', hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        metal2 = { modelo = 'origen_planta_lingote_caliente', padre = 'carrusel', pos = vec3(0.476, -0.275, 0.121), rumbo = -30.0, tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), inicio = -0.08, variantes = { caliente = 'origen_planta_lingote_caliente', hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        metal3 = { modelo = 'origen_planta_lingote_caliente', padre = 'carrusel', pos = vec3(0.476, 0.275, 0.121), rumbo = 30.0, tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), inicio = -0.08, variantes = { caliente = 'origen_planta_lingote_caliente', hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        metal4 = { modelo = 'origen_planta_lingote_caliente', padre = 'carrusel', pos = vec3(0.0, 0.55, 0.121), rumbo = 90.0, tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), inicio = -0.08, variantes = { caliente = 'origen_planta_lingote_caliente', hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        metal5 = { modelo = 'origen_planta_lingote_caliente', padre = 'carrusel', pos = vec3(-0.476, 0.275, 0.121), rumbo = 150.0, tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), inicio = -0.08, variantes = { caliente = 'origen_planta_lingote_caliente', hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        metal6 = { modelo = 'origen_planta_lingote_caliente', padre = 'carrusel', pos = vec3(-0.476, -0.275, 0.121), rumbo = 210.0, tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), inicio = -0.08, variantes = { caliente = 'origen_planta_lingote_caliente', hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
    },
    efectos = { fuego = { pieza = 'horno', punto = vec3(-1.1, 0.0, -0.32) }, brasas = { pieza = 'horno', punto = vec3(0.0, 0.0, 0.7) }, vertido = { pieza = 'chorro', punto = vec3(0.0, 0.0, -0.42) }, humo = { punto = vec3(0.0, 0.0, 7.2) }, chispas = { punto = vec3(0.0, 1.09, 0.84) }, vapor = { pieza = 'carrusel', punto = vec3(0.0, 0.0, 0.25) } },
    luces = { horno = { pieza = 'horno', punto = vec3(0.0, 0.0, 1.0), color = vec3(255.0, 120.0, 40.0), rango = 5.0, fuerza = 1.5 }, chorro = { pieza = 'horno', punto = vec3(0.0, 1.2, 0.2), color = vec3(255.0, 140.0, 50.0), rango = 3.0, fuerza = 1.2 }, moldes = { pieza = 'carrusel', punto = vec3(0.0, 0.0, 0.5), color = vec3(255.0, 90.0, 30.0), rango = 2.5, fuerza = 0.9 }, quemador = { pieza = 'horno', punto = vec3(-1.25, 0.0, -0.32), color = vec3(255.0, 150.0, 60.0), rango = 3.5, fuerza = 0.8, noche = true } },
    notas = { verter = -55.0, tapa_abierta = 75.0, giro_molde = -60.0 },
}

Maquinas.generador = {
    huella = { -0.7, 0.7, -1.9, 1.9 },
    cuerpo = 'origen_planta_generador',
    piezas = {
        ventilador = { modelo = 'origen_planta_generador_ventilador', pos = vec3(0.0, 1.62, 1.1), tipo = 'giro', eje = vec3(0.0, 1.0, 0.0), giro = 1100.0 },
        tapa = { modelo = 'origen_planta_generador_tapa', pos = vec3(0.28, -1.215, 2.725), tipo = 'angulo', eje = vec3(1.0, 0.0, 0.0), vaiven = { centro = 32.0, amp = 14.0, hz = 6.5 } },
    },
    efectos = { escape = { punto = vec3(0.28, -1.15, 2.84), marcha = true } },
    luces = { panel = { punto = vec3(0.0, -2.0, 1.1), color = vec3(120.0, 255.0, 150.0), rango = 2.0, fuerza = 0.6, marcha = true } },
    temblor = { radio = 4.0, fuerza = 0.03 },
}

Maquinas.torre_luz = {
    huella = { -1.45, 1.45, -1.3, 1.3 },
    cuerpo = 'origen_planta_torre',
    piezas = {
        mastil = { modelo = 'origen_planta_torre_mastil', pos = vec3(0.0, 1.12, 3.3), tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), inicio = -3.6, noche = { valor = 0.0, segundos = 9.0 } },
        focos = { modelo = 'origen_planta_torre_focos', padre = 'mastil', pos = vec3(0.0, 0.0, 0.0), variantes = { apagado = 'origen_planta_torre_focos', encendido = 'origen_planta_torre_focos_on' }, noche = { variante = 'encendido' } },
    },
    luces = { focos = { pieza = 'focos', punto = vec3(0.0, 0.4, 0.55), dir = vec3(0.0, 0.93, -0.36), color = vec3(255.0, 244.0, 222.0), rango = 40.0, fuerza = 4.0, radio = 55.0, noche = true }, halo = { pieza = 'focos', punto = vec3(0.0, 0.6, 0.55), color = vec3(255.0, 240.0, 215.0), rango = 7.0, fuerza = 1.2, noche = true } },
}

Maquinas.caseta = {
    huella = { -1.5, 1.5, -1.2, 1.2 },
    cuerpo = 'origen_planta_caseta',
    piezas = {
        ventanas = { modelo = 'origen_planta_caseta_ventanas', variantes = { dia = 'origen_planta_caseta_ventanas', noche = 'origen_planta_caseta_ventanas_on' }, noche = { variante = 'noche' } },
        baliza = { modelo = 'origen_planta_baliza', marcha = 'origen_planta_baliza_on', pos = vec3(0.9, -0.8, 5.05), tipo = 'giro', eje = vec3(0.0, 0.0, 1.0), giro = 400.0 },
        aire = { modelo = 'origen_planta_caseta_aire', pos = vec3(1.77, -0.25, 3.93), tipo = 'giro', eje = vec3(1.0, 0.0, 0.0), giro = 700.0 },
    },
    luces = { baliza = { pieza = 'baliza', punto = vec3(0.0, 0.0, 0.12), dir = vec3(1.0, 0.0, -0.08), color = vec3(255.0, 140.0, 10.0), rango = 22.0, fuerza = 7.0, radio = 30.0, marcha = true }, baliza2 = { pieza = 'baliza', punto = vec3(0.0, 0.0, 0.12), dir = vec3(-1.0, 0.0, -0.08), color = vec3(255.0, 140.0, 10.0), rango = 22.0, fuerza = 7.0, radio = 30.0, marcha = true }, dentro = { punto = vec3(0.0, 0.0, 4.28), color = vec3(255.0, 214.0, 160.0), rango = 5.0, fuerza = 1.2, noche = true }, fachada = { punto = vec3(-1.75, 0.0, 4.65), dir = vec3(-0.6, 0.0, -0.8), color = vec3(255.0, 236.0, 200.0), rango = 14.0, fuerza = 2.5, radio = 70.0, noche = true } },
}

Maquinas.temple = {
    huella = { -1.3, 1.2, -0.62, 0.62 },
    cuerpo = 'origen_planta_temple',
    piezas = {
        agua = { modelo = 'origen_planta_temple_agua' },
        cesta = { modelo = 'origen_planta_temple_cesta', pos = vec3(0.0, 0.0, 0.95), tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), variantes = { vacia = 'origen_planta_temple_cesta', caliente = 'origen_planta_temple_cesta_caliente', hierro = 'origen_planta_temple_cesta_hierro', cobre = 'origen_planta_temple_cesta_cobre', oro = 'origen_planta_temple_cesta_oro' } },
    },
    efectos = { vapor = { punto = vec3(0.0, 0.0, 0.77) }, hervor = { punto = vec3(0.0, 0.0, 0.72) } },
    luces = { cesta = { pieza = 'cesta', punto = vec3(0.0, 0.0, 0.4), color = vec3(255.0, 120.0, 40.0), rango = 3.5, fuerza = 1.4 } },
    notas = { dentro = -0.75 },
}

Maquinas.carro = {
    huella = { -0.5, 0.5, -0.36, 0.36 },
    cuerpo = 'origen_planta_carro',
    piezas = {
        l1 = { modelo = 'origen_planta_lingote_hierro', pos = vec3(-0.26, -0.06, 0.62), rumbo = 0.0, oculta = true, variantes = { hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        l2 = { modelo = 'origen_planta_lingote_hierro', pos = vec3(0.0, -0.06, 0.62), rumbo = 0.0, oculta = true, variantes = { hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        l3 = { modelo = 'origen_planta_lingote_hierro', pos = vec3(0.26, -0.06, 0.62), rumbo = 0.0, oculta = true, variantes = { hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        l4 = { modelo = 'origen_planta_lingote_hierro', pos = vec3(-0.26, 0.06, 0.62), rumbo = 0.0, oculta = true, variantes = { hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        l5 = { modelo = 'origen_planta_lingote_hierro', pos = vec3(0.0, 0.06, 0.62), rumbo = 0.0, oculta = true, variantes = { hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        l6 = { modelo = 'origen_planta_lingote_hierro', pos = vec3(0.26, 0.06, 0.62), rumbo = 0.0, oculta = true, variantes = { hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        l7 = { modelo = 'origen_planta_lingote_hierro', pos = vec3(-0.18, 0.0, 0.675), rumbo = 90.0, oculta = true, variantes = { hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        l8 = { modelo = 'origen_planta_lingote_hierro', pos = vec3(-0.06, 0.0, 0.675), rumbo = 90.0, oculta = true, variantes = { hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        l9 = { modelo = 'origen_planta_lingote_hierro', pos = vec3(0.06, 0.0, 0.675), rumbo = 90.0, oculta = true, variantes = { hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        l10 = { modelo = 'origen_planta_lingote_hierro', pos = vec3(0.18, 0.0, 0.675), rumbo = 90.0, oculta = true, variantes = { hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        l11 = { modelo = 'origen_planta_lingote_hierro', pos = vec3(0.0, -0.05, 0.73), rumbo = 0.0, oculta = true, variantes = { hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
        l12 = { modelo = 'origen_planta_lingote_hierro', pos = vec3(0.0, 0.05, 0.73), rumbo = 0.0, oculta = true, variantes = { hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' } },
    },
}

-- La planta entera, respecto a la trituradora (CrearPlanta). `suelo`: toma la altura de otra;
-- `nombre`: con qué nombre sale en la lista de ids (si el tipo se repite).
Planta = {
    { tipo = 'trituradora', pos = vec3(0.0, 0.0, 0.0), rumbo = 0.0 },
    { tipo = 'cinta_subida', pos = vec3(0.0, -10.9, 0.0), rumbo = 0.0 },
    { tipo = 'tolva', pos = vec3(0.0, -10.9, 0.0), rumbo = 0.0, suelo = 'cinta_subida' },
    { tipo = 'cinta_salida', pos = vec3(0.0, 2.0, 0.0), rumbo = 0.0, suelo = 'trituradora' },
    { tipo = 'contenedor', pos = vec3(0.0, 10.05, 0.0), rumbo = 0.0 },
    { tipo = 'fundicion', pos = vec3(5.5, 10.5, 0.0), rumbo = 90.0 },
    { tipo = 'generador', pos = vec3(7.6, -5.8, 0.0), rumbo = 0.0 },
    { tipo = 'caseta', pos = vec3(4.7, -0.3, 0.0), rumbo = 0.0 },
    { tipo = 'torre_luz', pos = vec3(7.5, -12.5, 0.0), rumbo = 49.0, nombre = 'torre_tolva' },
    { tipo = 'torre_luz', pos = vec3(-7.5, 12.5, 0.0), rumbo = 213.0, nombre = 'torre_contenedor' },
}

-- Junto a la fundición, respecto a ella (CrearJunto).
JuntoFundicion = {
    { tipo = 'temple', pos = vec3(3.7, 1.2, 0.0), rumbo = 90.0 },
    { tipo = 'carro', pos = vec3(2.9, -1.2, 0.0), rumbo = 0.0 },
}

Trozos = { grava = 'origen_planta_trozo_grava', carbon = 'origen_planta_trozo_carbon', hierro = 'origen_planta_trozo_hierro', cobre = 'origen_planta_trozo_cobre', cuarzo = 'origen_planta_trozo_cuarzo', oro = 'origen_planta_trozo_oro' }
Piedras = { grava = 'origen_planta_piedra_grava', carbon = 'origen_planta_piedra_carbon', hierro = 'origen_planta_piedra_hierro', cobre = 'origen_planta_piedra_cobre', cuarzo = 'origen_planta_piedra_cuarzo', oro = 'origen_planta_piedra_oro' }
Lingotes = { caliente = 'origen_planta_lingote_caliente', hierro = 'origen_planta_lingote_hierro', cobre = 'origen_planta_lingote_cobre', oro = 'origen_planta_lingote_oro' }
