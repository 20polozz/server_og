--[[ ═══════════════════════════════════════════════════════════════════════
     AUTOESCUELA DE LOS SANTOS · el carné de conducir

     Se habla con el instructor, se hace el teórico en la pantalla y luego un
     práctico POR CALLES DE VERDAD con un examinador al lado que va cantando
     las maniobras. El de coche es exigente a propósito: intermitentes,
     límites de velocidad, stops, cinturón, dirección contraria, un frenazo
     de emergencia y un aparcamiento marcha atrás.

         COCHE    (Clase B)  turismos, todoterrenos, furgonetas
         MOTO     (Clase A)  motocicletas          — pide tener el de coche
         CAMIÓN   (Clase C)  camiones y comerciales — pide el de moto

     El carné es un OBJETO del inventario (`licencia_conducir`): se enseña a
     la policía usándolo, y si se pierde el instructor hace un duplicado
     pagando (el anterior queda ANULADO).

     Todo cobro, nota y aprobado lo decide el servidor. El cliente conduce y
     avisa; cada punto del recorrido se comprueba con la posición que tiene
     el servidor del vehículo.
   ═══════════════════════════════════════════════════════════════════════ ]]

Config = {}

Config.Nombre = 'Autoescuela de Los Santos'
Config.Corto = 'Autoescuela'

--- El objeto del carné (definido en origen_inventory/config/items.lua).
Config.Item = 'licencia_conducir'

--[[ El carné viejo. Hasta el 19/09/2026 TODO personaje nacía con
     `driver_license` puesto; el usuario decidió anularlos a todos: ese objeto
     ya no vale, y al usarlo lo dice. Se quitó además de los objetos de inicio
     (origen_titlemenu/config.lua y qbx_core/config/shared.lua). ]]
Config.ItemViejo = 'driver_license'

-- ── La autoescuela ────────────────────────────────────────────────────────

Config.Escuela = {
    -- El instructor: examina, cobra y hace duplicados. Coordenadas del usuario.
    npc = {
        modelo = 'a_m_m_business_01',
        coords = vec4(20.25, -441.93, 35.02, 161.33),
        escenario = 'WORLD_HUMAN_CLIPBOARD',
        nombre = 'Instructor Navarro',
    },
    --[[ Dónde sale el vehículo de cada examen. Son VARIAS plazas a propósito:
         con dos o tres alumnos a la vez, una sola plaza acaba con un coche
         encima de otro. El servidor coge la primera libre y, si no hay
         ninguna, lo dice en vez de sacar el vehículo. Se miden en el juego
         con /autopunto. ]]
    --[[ Las tres plazas de la puerta (medidas por el usuario el 20/09). Valen
         para los tres exámenes: coches, motos y camiones salen de aquí. El
         servidor coge la primera libre y, si están las tres ocupadas, el
         alumno se queda EN COLA hasta que se despejen en vez de perder la
         vez. ]]
    salidas = {
        vec4(-39.10, -389.59, 37.91, 253.80),
        vec4(-37.10, -382.42, 37.96, 249.37),
        vec4(-35.35, -375.49, 37.99, 254.30),
    },
    -- Radio en el que se busca hueco antes de sacar el vehículo.
    hueco = 4.0,
    -- Lejos de este punto el examen se da por abandonado.
    centro = vec3(20.25, -441.93, 35.02),
    radioExamen = 2500.0,
}

-- En Nación, el instructor y el centro de control del examen están en la
-- ubicación de la autoescuela de esa marca. Origen conserva sus coordenadas.
if GetConvar('origen:marca', 'origen') == 'nacion' then
    Config.Escuela.npc.coords = vector4(-1083.92, -1269.38, 4.76, 213.59)
    Config.Escuela.centro = vector3(-1083.92, -1269.38, 5.76)
    Config.Escuela.salidas = {
        vector4(-1077.23, -1250.03, 5.37, 212.05)
    }
end

--- Quién examina. Va sentado de copiloto (en la moto, detrás).
Config.Examinador = {
    modelo = 'a_m_m_business_01',
    nombres = { 'Examinador Peña', 'Examinadora Ibarra', 'Examinador Solís', 'Examinadora Cruz' },
}

-- ── Las clases ────────────────────────────────────────────────────────────
--[[ `clases`: las clases de vehículo de GTA que habilita ESTE nivel además de
     las de abajo. `practicos`: los exámenes de shared/examenes.lua que hay
     que aprobar. `duplicado`: lo que cuesta rehacer la tarjeta. ]]

Config.Niveles = {
    {
        id = 'coche',
        nombre = 'Coche',
        clase = 'Clase B',
        resumen = 'Turismos, todoterrenos y furgonetas',
        precioTeorico = 1000,
        practicos = { 'coche' },
        duplicado = 500,
        -- 0 compactos · 1 berlinas · 2 todoterrenos · 3 cupés · 4 muscle
        -- 5 clásicos · 6 deportivos · 7 súper · 9 off-road · 12 furgonetas
        -- 22 fórmula
        clases = { 0, 1, 2, 3, 4, 5, 6, 7, 9, 12, 22 },
        -- Lo que la policía ve en su MDT (metadata.licences y police_licenses).
        tipoPolicia = 'driver',
    },
    {
        id = 'moto',
        nombre = 'Moto',
        clase = 'Clase A',
        resumen = 'Motocicletas y ciclomotores',
        precioTeorico = 1000,
        practicos = { 'moto' },
        duplicado = 500,
        clases = { 8 },
        tipoPolicia = 'moto',
    },
    {
        id = 'camion',
        nombre = 'Camión',
        clase = 'Clase C',
        resumen = 'Camiones, comerciales y vehículos de trabajo',
        precioTeorico = 2000,
        practicos = { 'camion' },
        duplicado = 800,
        -- 10 industriales · 11 utilitarios · 17 servicio · 20 comerciales
        clases = { 10, 11, 17, 20 },
        tipoPolicia = 'camion',
    },
}

-- ── El examen teórico ─────────────────────────────────────────────────────

Config.Teorico = {
    preguntas = { coche = 20, moto = 12, camion = 12 },   -- el de coche, largo
    aprobado = 0.9,                                       -- y exigente: 90 %
    tiempo = 900,
    esperaSuspenso = 0,
}

-- ── El práctico ───────────────────────────────────────────────────────────

Config.Practico = {
    -- Se empieza con 100 y cada fallo resta. El de conducir aprueba con 80.
    aprobado = 80,
    esperaSuspenso = 0,
    -- Chapa (sobre 1000) por debajo de la cual el examen se suspende.
    chapaMinima = 900,
    -- Un golpe que quite más de esto a la chapa resta puntos.
    golpe = 12.0,
    puntosGolpe = 15,
    fueraMax = 25,
    -- Velocidad: margen antes de avisar, antes de restar y antes de suspender.
    margenAviso = 3.0,
    margenResta = 12.0,
    margenFuera = 30.0,
    puntosVelocidad = 10,
    -- Intermitente: segundos antes del giro en los que hay que ponerlo.
    -- (el juego devuelve 0 ninguno, 1 izquierda, 2 derecha, 3 los dos; los
    --  cuatro a la vez son las de avería y no cuentan como señal)
    intermitente = 6.0,
    puntosIntermitente = 10,
    -- Salirse de la calzada o ir en dirección contraria.
    puntosFuera = 10,
    puntosContramano = 20,
    segundosFalta = 3.0,
    -- El cinturón (coche y camión).
    puntosCinturon = 15,
}

-- ── Conducir sin carné ────────────────────────────────────────────────────
--[[ Al ponerse al volante se mira si lleva encima un carné válido para ESA
     clase de vehículo. Por defecto solo avisa: multar es cosa de la policía.
     Con `bloquear = true` además no deja arrancar. ]]

Config.Control = {
    activo = true,
    bloquear = false,
    -- Trabajos que conducen vehículos de servicio.
    exentos = { police = true, ambulance = true, sheriff = true },
    -- Clases que no piden carné: bicicletas, barcos, aviones y helicópteros
    -- (los dos últimos son de origen_aviacion), trenes y emergencias.
    libres = { [13] = true, [14] = true, [15] = true, [16] = true, [18] = true, [21] = true },
}

-- ── La policía ────────────────────────────────────────────────────────────
--[[ Cada nivel escribe su fila en `police_licenses` con su `tipoPolicia`, así
     que en la ficha del ciudadano de la MDT salen «Conductor», «Moto» y
     «Camión». Si la policía retira una desde la MDT, la tarjeta sale RETIRADA
     y hay que volver a examinarse. ]]

Config.Policia = {
    mdt = true,
    tipo = 'driver',           -- el que manda (el de coche)
    caduca = 1893456000,
}

-- ── Mapa ──────────────────────────────────────────────────────────────────

Config.Mapa = {
    nombre = 'Autoescuela',
    categoria = 'public',
    icono = 'coche',
}
