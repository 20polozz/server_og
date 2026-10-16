--[[ La planta de compactación: la prensa de muelle y el contenedor de las
     balas (piezas, puntos, efectos y luces).

     GENERADO por construir_muelle.py (fuente/ de origen_garbage) a partir de
     los modelos: no tocar a mano. ]]

Maquinas = Maquinas or {}

Maquinas.prensa_muelle = {
    cuerpo = 'origen_pm_prensa',
    piezas = {
        piston = { modelo = 'origen_pm_piston', pos = vec3(0.0, -0.1, 2.35), tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0) },
        compuerta = { modelo = 'origen_pm_compuerta', pos = vec3(0.0, -1.11, 0.3), tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0) },
        relleno = { modelo = 'origen_pm_relleno', pos = vec3(0.0, -0.1, 0.25), tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), inicio = -1.0 },
        bala = { modelo = 'origen_pm_bala', pos = vec3(0.0, -0.1, 0.3), tipo = 'desliza', eje = vec3(0.0, -1.0, 0.0), oculta = true },
        baliza = { modelo = 'origen_pm_baliza', marcha = 'origen_pm_baliza_on', pos = vec3(0.9, 0.1, 4.58), tipo = 'giro', eje = vec3(0.0, 0.0, 1.0), giro = 420.0 },
    },
    notas = { abajo = -1.55, compuerta = 1.2, rodillos = 2.5 },
    puntos = { boca = vec3(0.0, 1.3, 2.2), camion = vec3(0.0, 2.32, 0.0), caida = vec3(0.0, -3.65, -0.2), numero = vec3(0.0, -0.1, 4.75), lampara = vec3(0.0, -1.9, 0.0) },
    efectos = { polvo_prensa = { punto = vec3(0.0, -0.1, 2.6) }, vapor_prensa = { punto = vec3(0.55, -0.1, 4.65) }, polvo_boca = { punto = vec3(0.0, 1.3, 1.8) }, polvo_caida = { punto = vec3(0.0, -4.3, -2.2) } },
    luces = { trabajo = { punto = vec3(0.0, 1.8, 3.6), dir = vec3(0.0, 0.3, -1.0), color = vec3(255.0, 240.0, 215.0), rango = 9.0, fuerza = 3.0, radio = 60.0, noche = true }, baliza = { pieza = 'baliza', punto = vec3(0.0, 0.0, 0.12), dir = vec3(1.0, 0.0, -0.1), color = vec3(255.0, 140.0, 10.0), rango = 16.0, fuerza = 6.0, radio = 30.0, marcha = true }, baliza2 = { pieza = 'baliza', punto = vec3(0.0, 0.0, 0.12), dir = vec3(-1.0, 0.0, -0.1), color = vec3(255.0, 140.0, 10.0), rango = 16.0, fuerza = 6.0, radio = 30.0, marcha = true }, pantalla = { punto = vec3(-2.0, 0.0, 1.6), color = vec3(120.0, 200.0, 255.0), rango = 1.5, fuerza = 0.6, marcha = true } },
    temblor = { radio = 6.0, fuerza = 0.05 },
}

Maquinas.contenedor = {
    cuerpo = 'origen_pm_contenedor',
    piezas = {
        pila1 = { modelo = 'origen_pm_bala', pos = vec3(-0.6, 1.95, 0.33), rumbo = -5.0, oculta = true },
        pila2 = { modelo = 'origen_pm_bala', pos = vec3(0.6, 1.95, 0.33), rumbo = -1.0, oculta = true },
        pila3 = { modelo = 'origen_pm_bala', pos = vec3(-0.6, 0.55, 0.33), rumbo = 3.0, oculta = true },
        pila4 = { modelo = 'origen_pm_bala', pos = vec3(0.6, 0.55, 0.33), rumbo = -4.0, oculta = true },
        pila5 = { modelo = 'origen_pm_bala', pos = vec3(-0.6, -0.85, 0.33), rumbo = 0.0, oculta = true },
        pila6 = { modelo = 'origen_pm_bala', pos = vec3(0.6, -0.85, 0.33), rumbo = 4.0, oculta = true },
        pila7 = { modelo = 'origen_pm_bala', pos = vec3(-0.6, 1.95, 1.23), rumbo = -3.0, oculta = true },
        pila8 = { modelo = 'origen_pm_bala', pos = vec3(0.6, 1.95, 1.23), rumbo = 1.0, oculta = true },
    },
    notas = {  },
    puntos = {  },
    efectos = {  },
    luces = {  },
}
