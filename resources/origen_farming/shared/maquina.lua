--[[ Las máquinas de este trabajo (piezas, puntos, efectos y luces).

     GENERADO por construir_maquinas.py (m_granja.py, en fuente/) a partir de
     los modelos: no tocar a mano. ]]

Maquinas = Maquinas or {}

Maquinas.lavadora = {
    cuerpo = 'origen_gr_lavadora',
    piezas = {
        tambor = { modelo = 'origen_gr_tambor', pos = vec3(0.0, 6.3, 2.0), tipo = 'giro', eje = vec3(0.0, 1.0, 0.0), giro = 120.0 },
        elevador = { modelo = 'origen_gr_elevador', marcha = 'origen_gr_elevador_on', pos = vec3(0.0, 0.0, 0.0) },
        mesa = { modelo = 'origen_gr_mesa', marcha = 'origen_gr_mesa_on', pos = vec3(0.0, 0.0, 0.0) },
        carga = { modelo = 'origen_gr_monton_verdura', pos = vec3(0.0, 0.8, 0.75), tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), inicio = -0.3, oculta = true },
        caja1 = { modelo = 'origen_gr_caja', pos = vec3(2.4, 13.6, 0.24), oculta = true },
        caja2 = { modelo = 'origen_gr_caja', pos = vec3(3.0, 13.6, 0.24), oculta = true },
        caja3 = { modelo = 'origen_gr_caja', pos = vec3(2.4, 14.2, 0.24), oculta = true },
        caja4 = { modelo = 'origen_gr_caja', pos = vec3(3.0, 14.2, 0.24), oculta = true },
        caja5 = { modelo = 'origen_gr_caja', pos = vec3(2.4, 13.6, 0.56), oculta = true },
        caja6 = { modelo = 'origen_gr_caja', pos = vec3(3.0, 13.6, 0.56), oculta = true },
        caja7 = { modelo = 'origen_gr_caja', pos = vec3(2.4, 14.2, 0.56), oculta = true },
        caja8 = { modelo = 'origen_gr_caja', pos = vec3(3.0, 14.2, 0.56), oculta = true },
    },
    notas = { caja_z = 0.32 },
    puntos = { tolva = vec3(0.0, 0.8, 1.55), palet = vec3(2.7, 13.9, 0.24) },
    efectos = { agua1 = { punto = vec3(0.0, 5.3, 3.0) }, agua2 = { punto = vec3(0.0, 7.3, 3.0) }, salpica = { punto = vec3(0.0, 6.3, 0.6) } },
    luces = { trabajo = { punto = vec3(0.6, 7.0, 3.5), dir = vec3(0.0, 0.0, -1.0), color = vec3(255.0, 240.0, 215.0), rango = 10.0, fuerza = 3.0, radio = 70.0, noche = true } },
    temblor = { radio = 4.0, fuerza = 0.02 },
}

Maquinas.bascula = {
    cuerpo = 'origen_gr_bascula',
    piezas = {
    },
    notas = {  },
    puntos = { marcador = vec3(-2.58, 0.0, 3.05) },
    efectos = {  },
    luces = {  },
}

Maquinas.silo = {
    cuerpo = 'origen_gr_silo',
    piezas = {
        monton = { modelo = 'origen_gr_monton', pos = vec3(0.0, 0.0, -0.9), tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0), oculta = true },
        nivel1 = { modelo = 'origen_gr_nivel', pos = vec3(-1.5, 3.06, 0.8), tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0) },
        nivel2 = { modelo = 'origen_gr_nivel', pos = vec3(3.1, 3.06, 0.8), tipo = 'desliza', eje = vec3(0.0, 0.0, 1.0) },
    },
    notas = { nivel_max = 7.6 },
    puntos = { foso = vec3(0.0, 0.0, 0.2) },
    efectos = { polvo_foso = { punto = vec3(0.0, 0.0, 0.4) }, polvo_silo1 = { punto = vec3(-2.2, 5.0, 10.8) }, polvo_silo2 = { punto = vec3(2.4, 5.0, 10.8) } },
    luces = { baliza = { punto = vec3(1.9, 0.0, 15.4), color = vec3(255.0, 140.0, 10.0), rango = 14.0, fuerza = 4.0, marcha = true } },
}
