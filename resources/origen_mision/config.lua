--[[ Origen Lista Negra · la configuracion.

     Trabajos sucios para un policia que trabaja por debajo de la mesa. No los
     coge cualquiera ni hay un contacto en la calle: hace falta la LISTA NEGRA,
     que un admin le da a quien quiera (/darlistanegra o el panel de admin).
     Se abre con /listanegra (o usando el objeto, si el inventario lo tiene):
     los trabajos van por dificultad y cada uno se abre al cerrar el anterior.

     ── Los pasos de un trabajo ──────────────────────────────────────────────

       ir        llegar a un sitio                       x y z  radio
       alejarse  salir de la zona (circulo en el mapa)    x y z  radio
       llamada   una llamada de telefono con subtitulos  nombre lineas = { { quien, dice, t } }
       rastrear  rastros que se examinan con la linterna  x y z  puntos = { { x y z, nombre, pista, da?, props?, sangre? } }
                 (props = { { modelo, dx, dy, rumbo? } }: lo que hay tirado; sangre = true: manchas)
       investigar  hablar con alguien o registrar algo    x y z  npc? objeto? coche? accion tiempo pista da?
                 (npc = { modelo, nombre, escena, h }: una persona puesta ahi; escena_jugador:
                 la animacion del jugador (o `anim = { dict, clip }`); al acabar sale
                 `pista` en una notificacion. `minijuego = { juego, dificultad, titulo }`:
                 antes hay que ganar ese minijuego de origen_minijuegos; `coche`: un
                 coche aparcado que se registra por el maletero)
                 `dialogo` = { inicio, nodos = { id = { dice, opciones = { { texto, va,
                 paga?, requiere = 'arma'? } } } o { dice, fin = 'habla'|'calla',
                 marca?, pista? } } }: una conversacion con respuestas. El final
                 deja una `marca` que otros pasos miran (`avisado` en asesinar:
                 le esperan y no hay plus por sigilo). El servidor la recorre.
                 `da` (en finales, investigar, recoger y puntos de rastrear): las
                 pistas que se consiguen (Config.Pistas). `requiere = 'objeto:<pista>'`
                 en una respuesta: solo vale si la lleva. `entrega` (dejar): las
                 pistas que se entregan ahi (salen del inventario).
       recoger   coger algo del suelo (pulsando E)       x y z  prop  cuerpo?
                 (cuerpo = true: aparece donde cayo el objetivo del paso anterior)
       dejar     soltar lo que se lleva (pulsando E)     x y z  objeto?
                 (objeto = el modelo del contenedor/buzon que hay ahi: flecha encima)
       matar     acabar con todos los que salen          x y z  enemigos
       robar     subirse al volante de un coche          x y z h  vehiculo
       entregar  dejar ESE coche en un sitio             x y z  radio  carroceria?
       asesinar  matar a UN objetivo con escolta          x y z  objetivo escoltas huida? sigilo?
       interceptar  el objetivo va en coche a un sitio    x y z h vehiculo objetivo escoltas destino

     `refuerzos` (asesinar) = { modelo, n, arma, vehiculo, ... }: llegan en ese
     coche cuando salta la alarma y van a por el jugador.
     `emboscada` (cualquier paso) = { modelo, n, arma, vehiculo, distancia, aviso }:
     al acercarse al sitio llega ese coche con gente que va a por el jugador.
     `escoltas.vehiculo` (interceptar): un segundo coche que sigue al objetivo
     con los escoltas que no caben en el suyo.

     ── Asesinar (el sigilo) ────────────────────────────────────────────────
     El objetivo hace su vida (`escena`, un escenario de GTA) y los escoltas
     montan guardia SIN atacar. Hay un medidor de sospecha: sube si un escolta
     te ve de cerca (mas rapido si vas armado, la mitad si vas agachado) y
     baja si no. A 100 %, o con un disparo sin silenciador, o si hieres a
     alguien que sobrevive: ALARMA. Los escoltas van a por ti y el objetivo
     huye (en `huida.vehiculo`, o a pie). Si se aleja `huida.lejos` metros
     del sitio, se ha escapado: fallida.
     `sigilo` = plus de paga (0.5 = +50 %) si lo matas sin tocar a ningun
     escolta. Lo comprueba el servidor mirando la vida de cada escolta.

     ── Interceptar (el convoy) ─────────────────────────────────────────────
     El objetivo sale en `vehiculo` desde x y z (con los escoltas dentro, 3
     como mucho) hacia `destino` en cuanto el jugador se acerca. Si llega
     vivo a menos de 40 m del destino: fallida. Al atacarle acelera y los
     escoltas disparan desde el coche.

     `enemigos` = { modelo, n, arma, vida?, blindaje?, precision?, radio?, jefe? }
     `jefe`     = { modelo, nombre, arma, vida, blindaje }: uno mas, con mas aguante.
     `carroceria` (entregar): minimo de carroceria del coche, de 0 a 1000. Si
     llega mas abollado no hay paga.

     La z de cada sitio NO hace falta clavarla: el cliente busca el suelo de
     verdad antes de poner nada. Basta con que sea aproximada (unos metros).

     Lo que manda es el servidor: la paga y si cada paso esta hecho salen de
     aqui, no de lo que diga el cliente. ]]

Config = {}

--- `modelo` de enemigos, escoltas y refuerzos: uno o una lista. El n-esimo
--- sale del modelo n-esimo (dando la vuelta) y el servidor acepta cualquiera.
function ModelosDe(m) return type(m) == 'table' and m or { m } end
function ModeloN(m, i) local l = ModelosDe(m) return l[((i - 1) % #l) + 1] end
function EsDelModelo(m, hash)
    for _, x in ipairs(ModelosDe(m)) do if joaat(x) == hash then return true end end
    return false
end

--- Avisos por consola del servidor (por que se rechaza lo que manda el cliente).
Config.Debug = false

--- Permiso de origen_admin para dar o retirar la Lista Negra y ver quien lleva que.
Config.Permiso = 'origen_mision'
--- /misionesadmin abre el panel de admin. /darlistanegra [id] (o /darmision) le da la Lista Negra.
Config.ComandoAdmin = 'misionesadmin'
Config.ComandoDar = { 'darlistanegra', 'darmision' }
--- /quitarlistanegra [id] se la quita.
Config.ComandoQuitar = 'quitarlistanegra'
--- El jugador: /listanegra abre el panel de trabajos (si la lleva encima).
Config.ComandoAbrir = 'listanegra'
--- Cualquiera: deja el trabajo en curso (cuenta como fallado).
Config.ComandoAbandonar = 'abandonartrabajo'

--[[ El acceso lo guarda este recurso (tabla origen_mision_acceso): basta con
     /darlistanegra. El objeto del inventario es un extra: si origen_inventory
     lo tiene dado de alta (config/items.lua), se le da tambien y usarlo abre
     la lista. Si no, funciona igual con /listanegra. ]]
Config.Item = 'lista_negra'

--[[ Las pistas: papeles y objetos que se consiguen en los trabajos. Llegan
     al inventario como el objeto `Config.ItemPista` (con su nombre, su
     descripcion y su imagen en los metadatos) y se leen usandolos o desde la
     Lista Negra. Si el inventario no tiene el objeto dado de alta, se guardan
     igual en el trabajo y se leen desde la Lista Negra.

       tipo  nota (a mano) · informe (a maquina) · cartera · tarjeta · objeto
       imagen  ui/pistas/<imagen>.png (el icono del inventario) ]]
Config.ItemPista = 'pista_lista_negra'
Config.Pistas = {
    hoja_ortega = {
        titulo = 'Hoja de servicio de Ortega', tipo = 'informe', imagen = 'informe',
        resumen = 'Encontrada en el maletero de su camuflado, en el patio del taller de El Burro.',
        cabecera = 'DEPARTAMENTO DE POLICÍA DE LOS SANTOS · UNIDAD DE ANTIDROGA',
        texto = {
            'AGENTE: Sgto. Luis Ortega · Placa 4471',
            'ASUNTO: Operación «Libreta». Entrega de pruebas a Fiscalía.',
            'Mañana, 09:00 h. Entrego en mano la caja con los extractos y las grabaciones. NO la llevo en el coche: está en la consigna 14 del muelle de Del Perro. La llave, en la cartera.',
            'Esta noche: última cita con «R.» en el patio del taller de El Burro, a las 23:00. Me trae los nombres que faltan. R. tiene miedo: si algo se tuerce, se larga del estado esta misma noche.',
            'Si me pasa algo, que lo sepa Asuntos Internos: B. no actúa solo.',
        },
        firma = 'L. Ortega',
    },
    cartera_ortega = {
        titulo = 'Cartera de Ortega', tipo = 'cartera', imagen = 'cartera',
        resumen = 'Tirada en el patio del taller de El Burro.',
        texto = {
            'Documento de identidad: Luis Ortega Varela. Placa de Antidroga n.º 4471.',
            'Una foto de una niña con uniforme de colegio. Detrás: «Para papá».',
            '40 $ en billetes y un tíquet de gasolinera de esta tarde.',
            'En el bolsillo de las tarjetas, una llave pequeña con una etiqueta de plástico: «14».',
        },
    },
    llave_consigna = {
        titulo = 'Llave de la consigna 14', tipo = 'objeto', imagen = 'llave',
        resumen = 'Estaba en la cartera de Ortega.',
        texto = { 'Una llave pequeña y gastada. La etiqueta dice «14 · Muelle de Del Perro · Consigna».' },
    },
    matricula_baller = {
        titulo = 'Matrícula apuntada', tipo = 'nota', imagen = 'nota',
        resumen = 'Te la ha dado el mecánico del taller de El Burro.',
        texto = { 'Baller negro', '47 KOR 213', 'Dos tipos. Uno con tatuaje en el cuello.', 'Tiraron cuesta arriba, hacia los pozos de petróleo.' },
        firma = 'Tano',
    },
    caja_ortega = {
        titulo = 'Caja de pruebas de Ortega', tipo = 'objeto', imagen = 'caja',
        resumen = 'Sacada de la consigna 14 del muelle de Del Perro.',
        texto = {
            'Una caja de cartón precintada con cinta de Antidroga. Pesa.',
            'Por un lado asoman extractos bancarios con los sellos de tres bancos de la ciudad y un pendrive con la etiqueta «GRABACIONES — NO COPIAR».',
        },
    },
    movil_quemado = {
        titulo = 'Móvil desechable', tipo = 'nota', imagen = 'nota',
        resumen = 'Estaba en el maletero del Baller, en el desguace de los pozos.',
        texto = {
            'Tres mensajes, sin nombre en la agenda:',
            '21:47 — «El poli está en el taller de El Burro. Ha venido solo.»',
            '23:20 — «Hecho. Lo dejamos en los pozos, nadie mira allí.»',
            '23:58 — «R. dice que la caja no la llevaba el poli encima. Que alguien vaya al muelle.»',
        },
        firma = '(sin firma)',
    },
    placa_ortega = {
        titulo = 'Placa de Ortega', tipo = 'objeto', imagen = 'cartera',
        resumen = 'La llevaba en el cinturón. Le encontraste en el desguace de los pozos.',
        texto = { 'Placa de Antidroga n.º 4471. Manchada de sangre seca.', 'Por detrás, rayado con una llave: «R. = Rafa».' },
    },
    informe_lalo = {
        titulo = 'Lo que había en el pendrive', tipo = 'informe', imagen = 'informe',
        resumen = 'Te lo imprimió Lalo en su autocaravana del Alamo Sea.',
        cabecera = 'TRANSCRIPCIÓN · PENDRIVE «GRABACIONES — NO COPIAR»',
        texto = {
            'Audio 31 · 18:12 h · Llamada saliente.',
            'MEDRANO: «Esta noche me voy. La avioneta sale del aeródromo de McKenzie, en Grapeseed. Quiero a cinco de los vuestros conmigo hasta que despegue.»',
            'VOZ 2: «¿Y los nombres?»',
            'MEDRANO: «Los llevo yo en un sobre. Si me pasa algo, os quedáis sin ellos.»',
        },
        firma = 'Impreso por Lalo',
    },
    kit_prismaticos = {
        titulo = 'Prismáticos de Nando', tipo = 'objeto', imagen = 'prismaticos',
        resumen = 'Material del trabajo. Se devuelve al acabar.',
        texto = { 'Unos prismáticos militares con la goma gastada. «Para ver sin que te vean», dijo Nando.' },
    },
    kit_micro = {
        titulo = 'Micro adhesivo', tipo = 'objeto', imagen = 'micro',
        resumen = 'Material del trabajo. Se devuelve al acabar.',
        texto = { 'Un micro del tamaño de una moneda. Se pega en cualquier sitio y emite a la radio.', 'Hay que sintonizarlo al ponerlo.' },
    },
    kit_ganzua = {
        titulo = 'Ganzúa eléctrica', tipo = 'objeto', imagen = 'ganzua',
        resumen = 'Material del trabajo. Se devuelve al acabar.',
        texto = { 'Abre cerraduras de asientos, puertas y cajas pequeñas. Hace ruido: mejor que nadie mire.' },
    },
    kit_radio = {
        titulo = 'Radio de Nando', tipo = 'objeto', imagen = 'radio',
        resumen = 'Material del trabajo. Se devuelve al acabar.',
        texto = { 'Dos radios con un canal limpio. Para hablar entre vosotros y oír el micro.' },
    },
    clave_caja = {
        titulo = 'La clave de la caja', tipo = 'nota', imagen = 'nota',
        resumen = 'Se la sacasteis al repartidor del Gallego, atado en Elysian.',
        texto = { '23 · 41 · 08', 'La caja tiene alarma: sin luz en el patio, no salta.' },
        firma = 'El repartidor',
    },
    kit_rifle = {
        titulo = 'Rifle de tirador desmontado', tipo = 'objeto', imagen = 'rifle',
        resumen = 'Material del trabajo. Se monta en el puesto; no se saca por la calle.',
        texto = { 'Un rifle de tirador en una funda de guitarra.', 'Se monta en el puesto que toque: desde ahí se cubre y se marca a la gente para el compañero.' },
    },
    libreta_chino = {
        titulo = 'Libreta del Chino', tipo = 'nota', imagen = 'nota',
        resumen = 'Estaba debajo del asiento de su moto, en el aparcamiento de la playa de Del Perro.',
        texto = { 'Lun · 12 · Tequi', 'Mar · 15 · Tequi', 'Mié · 9 · playa', 'Jue · 20 · Tequi', '«La furgo blanca, a las 11, aparcamiento de Vespucci.»' },
        firma = 'Chino',
    },
    libreta_gallego = {
        titulo = 'La libreta del Gallego', tipo = 'informe', imagen = 'informe',
        resumen = 'Sacada de la caja fuerte de su caseta, en los muelles de Elysian.',
        cabecera = 'CUENTAS · NO TOCAR',
        texto = {
            'Clientes de la playa, cantidades y deudas, mes a mes.',
            'Y en la última página, otra lista: «Para AI». Agentes, placas y lo que cobran de Bastida.',
            'Al final, subrayado tres veces: «Si me pasa algo, esto llega solo a Fiscalía».',
        },
        firma = 'G.',
    },
    movil_gallego = {
        titulo = 'Teléfono del Gallego', tipo = 'objeto', imagen = 'nota',
        resumen = 'Lo llevaba encima en el muelle.',
        texto = { 'Último mensaje enviado, a un número sin nombre: «Esta noche te paso el resto de nombres».', 'No llegó a enviarse.' },
    },
    sobre_nombres = {
        titulo = 'Sobre con nombres', tipo = 'nota', imagen = 'sobre',
        resumen = 'Lo llevaba encima el confidente.',
        texto = {
            'Los que cobran:',
            'Agte. Morales — 2.000 / mes',
            'Agte. Pike — 1.500 / mes',
            'Sgto. Díaz — 3.000 / mes',
            'Cmsr. Bastida — 10.000 / mes. Él reparte.',
            '(Y tu nombre, al final, en otra letra.)',
        },
        firma = 'R.',
    },
}

--[[ En grupo: el que acepta el trabajo puede invitar a otros con Lista Negra
     (boton Invitar o /invitarlista [id]). Comparten el trabajo entero. ]]
Config.Grupo = {
    max = 4,              -- contando al que invita
    invitar = 25.0,       -- metros: a quien se puede invitar
    distancia = 300.0,    -- metros del que cierra el trabajo para cobrar
    reparto = 'cada_uno', -- 'cada_uno': la paga entera a cada uno · 'repartir': se divide
    comandoInvitar = 'invitarlista',
    comandoSalir = 'salirlista',
}

--- En que se paga. 'cash' o 'bank'.
Config.Cuenta = 'cash'
--- Repetir un trabajo ya cerrado paga esta parte.
Config.Repeticion = 0.5
--- Minutos entre un trabajo y el siguiente (cerrado, o fallado/abandonado).
Config.Espera = { hecho = 5, fallado = 10 }

--- Quien encarga los trabajos (sale en la lista).
Config.Contacto = { nombre = 'Comisario Bastida', apodo = 'Expedientes B' }

--- Los niveles: como se llama cada tramo de la lista.
Config.Niveles = {
    { n = 1, nombre = 'Calle',     sub = 'Trabajos discretos' },
    { n = 2, nombre = 'Sucio',     sub = 'Ya hay tiros' },
    { n = 3, nombre = 'Podrido',   sub = 'Gente armada de verdad' },
    { n = 4, nombre = 'Intocable', sub = 'Si sale mal, no existes' },
}

-- Enemigos de cada tramo, para no repetirlos en cada paso. Todos con arma de
-- fuego: un guardaespaldas con un bate no protege a nadie.
-- `modelo` es una lista: cada uno sale de uno distinto y con ropa al azar,
-- para que no parezcan clones.
local Matones   = { modelo = { 'g_m_y_ballaeast_01', 'g_m_y_ballaorig_01' }, arma = 'WEAPON_PISTOL', vida = 200, precision = 30 }
local Lost      = { modelo = { 'g_m_y_lost_01', 'g_m_y_lost_02', 'g_m_y_lost_03' }, arma = 'WEAPON_PISTOL', vida = 200, blindaje = 25, precision = 35 }
local Vigilas   = { modelo = { 's_m_m_highsec_01', 's_m_m_highsec_02', 's_m_m_security_01' }, arma = 'WEAPON_COMBATPISTOL', vida = 220, blindaje = 50, precision = 40 }
local Salvas    = { modelo = { 'g_m_y_salvagoon_01', 'g_m_y_salvagoon_02', 'g_m_y_salvagoon_03' }, arma = 'WEAPON_MICROSMG', vida = 220, blindaje = 50, precision = 35 }
local Carronna  = { modelo = { 'g_m_m_armgoon_01', 'g_m_y_armgoon_02', 'g_m_m_armlieut_01' }, arma = 'WEAPON_SMG', vida = 240, blindaje = 75, precision = 45 }
local Federales = { modelo = { 's_m_m_fiboffice_01', 's_m_m_fiboffice_02', 's_m_m_ciasec_01' }, arma = 'WEAPON_CARBINERIFLE', vida = 240, blindaje = 75, precision = 50 }
local Mercs     = { modelo = { 's_m_y_blackops_01', 's_m_y_blackops_02', 's_m_y_blackops_03' }, arma = 'WEAPON_CARBINERIFLE', vida = 260, blindaje = 100, precision = 50 }

local function Con(base, extra)
    local t = {}
    for k, v in pairs(base) do t[k] = v end
    for k, v in pairs(extra) do t[k] = v end
    return t
end

--[[ Los trabajos, por dificultad. El `id` es lo que se guarda en la base: no
     cambiarlo una vez en marcha.

     TODOS los sitios estan mirados en el juego (fotos desde arriba, 04/10):
     nada de puntos en mitad de la calle ni en tejados. Lo que se deja va en
     un objeto que existe ahi (`objeto`: el contenedor, el buzon); los coches
     salen en aparcamientos de verdad y se entregan en el taller clandestino
     de El Burro (punto de entrega de origen_carboosting). ]]

-- Sitios que se repiten.
local GROVE_CONTENEDOR = { x = 119.2, y = -1944.2, z = 19.7, objeto = 'prop_dumpster_01a' }
local BUZON_MISSION_ROW = { x = 393.2, y = -972.3, z = 28.5, objeto = 'prop_postbox_01a' }
local RANCHO_CONTENEDOR = { x = 2441.2, y = 4988.5, z = 45.2, objeto = 'prop_dumpster_3a' }
local TALLER_EL_BURRO = { x = 752.68, y = -1857.07, z = 28.68 }
local TALLER_EL_BURRO_CONTENEDOR = { x = 752.1, y = -1866.2, z = 28.3, objeto = 'prop_dumpster_02a' }
local BUZON_LEGION = { x = 155.8, y = -907.2, z = 29.3, objeto = 'prop_postbox_01a' }
--[[ El preso del interrogatorio (camello, paso 7): atado a la silla de tortura
     de la mision del FBI. Las animaciones de tortura son de escena: el origen
     es el punto del paso y la silla va desplazada de el (`silla`). Las dos
     partes del paso (el que pregunta y el que aprieta) usan el mismo. ]]
local PRESO_REPARTIDOR = { modelo = 'g_m_y_salvagoon_02', nombre = 'El repartidor, atado', h = 53.39,
    -- La silla tiene el origen en el asiento (las patas bajan 0,39) y va de cara al preso.
    silla = { 'prop_torture_ch_01', 0.0, 0.0, 0.39, 180.0 },
    anim = { 'missfbi3_toothpull', 'pull_tooth_idle_victim' } }
--[[ `oz`: donde va el origen de la escena de la tortura del FBI respecto al
     suelo. La cadera del preso queda 0,18 m por encima del origen y el asiento
     de la silla a 0,39 m del suelo: con +0,39 se sienta sin meter los pies en el suelo (medido en
     partida, 07/10). ]]
local SITIO_PRESO = { x = -133.64, y = -2501.75, z = 6.1, oz = 0.39 }   -- puesto por el usuario en partida (07/10)

local function En(sitio, t)
    for k, v in pairs(sitio) do if t[k] == nil then t[k] = v end end
    return t
end

--[[ Cuantos trabajos estan abiertos desde el principio, sin haber hecho
     ninguno (10/10: los cuatro primeros). A partir de ahi, cada uno se abre
     al cerrar el anterior: el quinto, al cerrar el cuarto. ]]
Config.AbiertasDeInicio = 4

Config.Misiones = {
    -- ═══ Nivel 1 · Calle ═════════════════════════════════════════════════
    {
        id = 'soplon_muelle', nivel = 1, tiempo = 20, pago = 1000,
        titulo = 'El soplón del muelle',
        resumen = 'Un confidente que mañana declara ante el fiscal.',
        lore = {
            'Hay un confidente en el muelle de Del Perro que mañana declara ante el fiscal. En su declaración salen tres nombres de la comisaría, y uno es el de Bastida. Ahora mismo está en el aparcamiento del muelle, colgado del teléfono.',
            'Le acompañan tres matones armados que ha contratado con lo que le paga la Fiscalía. Si te ven venir, saldrá corriendo. Hazlo en silencio, quítale el teléfono, que ahí está todo lo que ha grabado, y tíralo al contenedor de basura de Grove Street: el camión lo tritura de madrugada.',
        },
        pasos = {
            { tipo = 'asesinar', texto = 'Haz callar al soplón sin que te vean', x = -1605.0, y = -1040.0, z = 13.0, sigilo = 0.5,
              objetivo = { modelo = 'a_m_m_salton_02', nombre = 'El soplón', vida = 150, escena = 'WORLD_HUMAN_STAND_MOBILE', h = 230.0 },
              escoltas = Con(Matones, { n = 3, radio = 6.0 }),
              huida = { lejos = 250.0 } },
            { tipo = 'recoger', texto = 'Quítale el teléfono', x = -1605.0, y = -1040.0, z = 13.0, prop = 'prop_npc_phone_02', cuerpo = true },
            En(GROVE_CONTENEDOR, { tipo = 'dejar', texto = 'Tira el teléfono al contenedor de basura de Grove Street' }),
        },
    },
    {
        id = 'caja_ortega', nivel = 1, tiempo = 90, pago = 4500,
        titulo = 'La caja de Ortega',
        resumen = 'Un agente de Antidroga con pruebas contra la comisaría y un confidente que vende nombres. El segundo de la lista.',
        lore = {
            'El sargento Ortega, de Antidroga, lleva meses montando un caso contra los agentes que cobran de Bastida. Mañana a las nueve entrega en Fiscalía una caja con extractos y grabaciones.',
            'Esta noche había quedado con su confidente, «R.», en el patio de un taller de El Burro. Desde entonces no contesta. Bastida quiere la caja, quiere los nombres y quiere a «R.» callado para siempre: es el segundo nombre de la Lista Negra.',
            'Es una investigación larga: del taller a los pozos de petróleo, al muelle de Del Perro y al desierto. Los Carroña también buscan la caja.',
        },
        pasos = {
            { tipo = 'llamada', texto = 'Atiende la llamada de Bastida', nombre = 'Comisario Bastida', lineas = {
                { quien = 'Bastida', dice = 'Escucha y no me interrumpas. Ortega, el de Antidroga, lleva meses montando un caso contra nosotros.', t = 6 },
                { quien = 'Bastida', dice = 'Mañana a las nueve entrega una caja con pruebas en Fiscalía. Esta noche había quedado con su confidente en un taller de El Burro.', t = 7 },
                { quien = 'Bastida', dice = 'Y desde entonces no coge el teléfono. Ni el suyo, ni el de la central.', t = 5 },
                { quien = 'Tú', dice = '¿Quieres que vaya a ver qué ha pasado?', t = 3 },
                { quien = 'Bastida', dice = 'Quiero la caja y los nombres antes que nadie. Ortega lo apunta todo: empieza por su coche. Muévete.', t = 6 },
            } },
            -- El camuflado sigue en el patio, donde le atacaron. Va en el punto de
            -- entrega de origen_carboosting: un hueco para un coche, mirado.
            { tipo = 'investigar', texto = 'Registra el camuflado de Ortega en el patio del taller de El Burro', x = 745.5, y = -1849.0, z = 28.3,
              coche = { modelo = 'police4', h = 0.0 }, accion = 'Forzar el maletero', anim = { 'mini@repair', 'fixing_a_player' }, tiempo = 7,
              minijuego = { 'ganzua', 'easy', titulo = 'Forzar el maletero', fallo = 'Se te ha resbalado la ganzúa. Otra vez.' },
              da = 'hoja_ortega',
              pista = 'El camuflado de Ortega está abierto y con las llaves puestas. En el maletero, entre chalecos y conos, una hoja de servicio doblada. Ortega lo apunta todo, como decía Bastida.' },
            { tipo = 'rastrear', texto = 'Busca rastros con la linterna en el patio del taller de El Burro', x = 745.5, y = -1855.0, z = 28.3,
              puntos = {
                  { x = 748.7, y = -1857.1, z = 28.3, nombre = 'Casquillos', pista = 'La pistola reglamentaria de Ortega, tirada, con el cargador vacío y casquillos de 9 mm alrededor. Aquí ha habido tiros esta noche.',
                    props = { { 'w_pi_pistol', 0.0, 0.0 }, { 'w_pi_pistol_mag1', 0.5, -0.2 }, { 'w_pi_singleshot_shell', 0.4, 0.3 }, { 'w_pi_singleshot_shell', -0.3, 0.5 }, { 'w_pi_singleshot_shell', 0.2, -0.4 } } },
                  { x = 744.7, y = -1861.1, z = 28.3, nombre = 'Sangre', pista = 'Gotas de sangre fresca que van del coche hacia el fondo del patio. Alguien se arrastró.', sangre = true },
                  { x = 742.7, y = -1855.1, z = 28.3, nombre = 'Cartera', pista = 'Una cartera tirada entre las marcas de neumáticos. Es la de Ortega. Y dentro hay una llave.', da = { 'cartera_ortega', 'llave_consigna' },
                    props = { { 'prop_ld_wallet_01', 0.0, 0.0 } } },
              } },
            { tipo = 'investigar', texto = 'Busca a Tano, el mecánico del barrio, en la puerta de su taller', x = 925.64, y = -1560.19, z = 29.8,
              npc = { modelo = 's_m_y_xmech_01', nombre = 'Tano, el mecánico', escena = 'WORLD_HUMAN_SMOKING', h = 87.59 },
              -- Vuelven los Carroña a limpiar el patio.
              emboscada = Con(Carronna, { n = 3, vehiculo = 'cavalcade', distancia = 50.0,
                  aviso = 'Un Cavalcade negro para delante del taller. Son de los Carroña, los que se llevaron a Ortega, y vienen a por ti.',
                  previo = 'Los Carroña andan buscando a quien vio algo en El Burro. Habla rápido con el mecánico y ten el arma a mano.' }),
              accion = 'Hablar con el mecánico', escena_jugador = 'WORLD_HUMAN_STAND_IMPATIENT', tiempo = 1,
              --[[ Con la cartera de Ortega delante o con 100 $, suelta la
                   matricula. Si te vas sin presionarle, avisa a los Carroña
                   (en la terminal te esperan). ]]
              dialogo = {
                  inicio = 'a',
                  nodos = {
                      a = { dice = 'Cerrado. Vuelve mañana.', opciones = {
                          { texto = 'Policía. Esta noche ha habido tiros en el patio de El Burro, aquí al lado. ¿Qué has visto?', va = 'nada' },
                          { texto = '(Le enseñas la cartera de Ortega) Esto estaba tirado en el patio de al lado.', requiere = 'objeto:cartera_ortega', va = 'cartera' },
                          { texto = 'Toma cien pavos. ¿Quién ha estado aquí esta noche?', paga = 100, va = 'pagado' },
                          { texto = 'Nada. Buscaba un taller abierto.', va = 'vete' },
                      } },
                      nada = { dice = 'Yo no he visto nada. Aquí cada uno arregla lo suyo.', opciones = {
                          { texto = '(Le enseñas la cartera) ¿Y esto también es de nadie?', requiere = 'objeto:cartera_ortega', va = 'cartera' },
                          { texto = 'Cien pavos por que te vuelva la memoria.', paga = 100, va = 'pagado' },
                          { texto = 'Vale. Si te acuerdas de algo, ya sabes dónde estoy.', va = 'vete' },
                      } },
                      cartera = { fin = 'habla', da = 'matricula_baller',
                          dice = '...Vale, vale. Dos tipos en un Baller negro. Le metieron dentro a golpes, al poli. Apunté la matrícula por si acaso, toma. Tiraron cuesta arriba, hacia los pozos de petróleo.',
                          pista = 'Tano: dos de los Carroña se llevaron a Ortega en un Baller negro hacia los pozos de petróleo de El Burro Heights.' },
                      pagado = { fin = 'habla', da = 'matricula_baller',
                          dice = 'Por cien pavos me acuerdo de todo. Un Baller negro, dos tipos de los Carroña, y se llevaron a un poli herido. Hacia los pozos de petróleo de El Burro Heights. Te apunto la matrícula.',
                          pista = 'Tano: dos de los Carroña se llevaron a Ortega en un Baller negro hacia los pozos de petróleo de El Burro Heights.' },
                      vete = { fin = 'calla', marca = 'avisado',
                          dice = 'Pues aquí no hay nada que arreglar. (Cuando te das la vuelta, le ves teclear deprisa en el móvil.)',
                          pista = 'Tano no ha soltado nada, pero hay marcas de un todoterreno saliendo cuesta arriba, hacia los pozos de petróleo. Y ha avisado a alguien: te esperan.' },
                  },
              } },
            -- El Baller de la matricula, abandonado en el patio del desguace de los
            -- pozos (mirado: a cielo abierto, 14 m de claro, camino al lado).
            { tipo = 'investigar', texto = 'Busca el Baller negro en el desguace de los pozos de petróleo de El Burro Heights', x = 1537.2, y = -2100.2, z = 76.1,
              coche = { modelo = 'baller', h = 120.0, matricula = '47KOR213' }, accion = 'Forzar el maletero del Baller', anim = { 'mini@repair', 'fixing_a_player' }, tiempo = 7,
              minijuego = { 'pines', 'easy', titulo = 'La cerradura del Baller', fallo = 'Un pin se ha vuelto a caer. Otra vez.' },
              -- Vuelven a por el Baller para quemarlo.
              emboscada = Con(Carronna, { n = 3, vehiculo = 'granger', distancia = 70.0,
                  aviso = 'Un Granger sube por el camino de los pozos. Vienen a quemar el Baller, y tú estás en medio.',
                  previo = 'Me dicen que los Carroña van a los pozos a quemar algo. Si encuentras el Baller, no estarás solo mucho rato.' }),
              da = 'movil_quemado',
              pista = 'En el maletero del Baller hay sangre seca y un móvil desechable con tres mensajes. Y unas huellas de arrastre que salen del coche hacia los bidones.' },
            { tipo = 'rastrear', texto = 'Sigue el rastro con la linterna por el desguace', x = 1537.2, y = -2100.2, z = 76.1,
              puntos = {
                  { x = 1541.5, y = -2104.0, z = 76.1, nombre = 'Arrastre', pista = 'Dos surcos en la tierra y sangre: arrastraron a alguien desde el Baller.', sangre = true },
                  { x = 1545.0, y = -2108.5, z = 76.1, nombre = 'Un zapato', pista = 'Un zapato de vestir, del 43. Se le salió al arrastrarle.',
                    props = { { 'prop_ld_shoe_01', 0.0, 0.0 } } },
                  { x = 1548.5, y = -2112.0, z = 76.1, nombre = 'Ortega', pista = 'Es Ortega. Dos tiros en el pecho. Le dejaron aquí para que no le encontrara nadie. Todavía lleva la placa en el cinturón.',
                    cuerpo = { 'a_m_y_business_02', h = 200.0 }, sangre = true, da = { 'placa_ortega' } },
              } },
            { tipo = 'investigar', texto = 'Recoge la caja de la consigna 14 del muelle de Del Perro', x = -1605.0, y = -1040.0, z = 13.0,
              npc = { modelo = 's_m_m_security_01', nombre = 'Ramiro, el vigilante', escena = 'WORLD_HUMAN_GUARD_STAND', h = 140.0 },
              -- Te han seguido desde El Burro.
              emboscada = Con(Salvas, { n = 3, vehiculo = 'cavalcade', distancia = 60.0,
                  aviso = 'Un todoterreno te ha seguido hasta el muelle. Quieren la caja antes que tú.',
                  previo = 'Los de Salvas saben lo de la consigna. Un todoterreno va hacia el muelle de Del Perro: llega antes que ellos o prepárate.' }),
              accion = 'Hablar con Ramiro', escena_jugador = 'WORLD_HUMAN_STAND_IMPATIENT', tiempo = 1,
              dialogo = {
                  inicio = 'a',
                  nodos = {
                      a = { dice = '¿Qué quieres? Estoy de servicio y no tengo toda la noche.', opciones = {
                          { texto = '(Le enseñas la llave) Vengo a por lo de la consigna 14.', requiere = 'objeto:llave_consigna', va = 'llave' },
                          { texto = 'Abre la consigna 14 o te cierro el chiringuito.', va = 'sin_llave' },
                          { texto = 'Cien pavos por abrir la 14 sin preguntas.', paga = 100, va = 'pagado' },
                      } },
                      sin_llave = { dice = 'Sin la llave no abro nada, placa o no placa. Esas consignas son de alquiler.', opciones = {
                          { texto = '(Le enseñas la llave) Aquí la tienes.', requiere = 'objeto:llave_consigna', va = 'llave' },
                          { texto = 'Vale. Cien pavos y te olvidas de mí.', paga = 100, va = 'pagado' },
                      } },
                      llave = { fin = 'habla', da = 'caja_ortega',
                          dice = 'La 14... la del poli de Antidroga. Si traes su llave, no es asunto mío. Toma, y que no la vea nadie salir de aquí.' },
                      pagado = { fin = 'habla', da = 'caja_ortega',
                          dice = 'Sin preguntas. La caja, toma. Y no te he visto en mi vida.' },
                  },
              },
              pista = 'La caja de Ortega: extractos bancarios y un pendrive de grabaciones. Alguien tiene que leer ese pendrive: Lalo, el informático que vive en una autocaravana junto al Alamo Sea, no hace preguntas.' },
            -- Lalo vive en su autocaravana junto al Alamo Sea (mirado: descampado
            -- junto al camino de tierra, 19 m de claro). Lee el pendrive.
            { tipo = 'investigar', texto = 'Lleva el pendrive a Lalo, el informático, a su autocaravana del Alamo Sea', x = 1300.0, y = 3600.0, z = 33.1,
              npc = { modelo = 'a_m_y_hippy_01', nombre = 'Lalo, el informático', escena = 'WORLD_HUMAN_SMOKING', h = 220.0 },
              coche = { modelo = 'journey', dx = 4.5, dy = 3.0, h = 130.0 },
              accion = 'Hablar con Lalo', escena_jugador = 'WORLD_HUMAN_STAND_IMPATIENT', tiempo = 1,
              --[[ Pagando o asustandole, lo cuenta y se calla. Si te vas sin mas,
                   llama a Medrano para venderle que vas (marca «avisado»: en el
                   aerodromo te esperan y no hay plus). ]]
              dialogo = {
                  inicio = 'a',
                  nodos = {
                      a = { dice = '¿Quién te manda? Aquí no viene nadie sin avisar.', opciones = {
                          { texto = '(Le enseñas el pendrive de la caja) Necesito saber qué hay aquí dentro.', requiere = 'objeto:caja_ortega', va = 'mira' },
                          { texto = 'Me manda Bastida. Y a Bastida no se le dice que no.', va = 'bastida' },
                          { texto = '(Sacas la pistola) Vas a mirar una cosa. Ahora.', requiere = 'arma', va = 'mira_miedo' },
                      } },
                      bastida = { dice = '¿Bastida? Pues dile a Bastida que yo no trabajo gratis. ¿Qué traes?', opciones = {
                          { texto = '(Le enseñas el pendrive) Esto. Léelo.', requiere = 'objeto:caja_ortega', va = 'mira' },
                      } },
                      mira = { dice = 'A ver... Grabaciones, muchas. Y un audio de esta tarde: un tal Rafa Medrano, el contable de los Carroña, quedando para salir esta noche en avioneta desde el aeródromo de McKenzie. Esto vale dinero, amigo.', opciones = {
                          { texto = 'Doscientos pavos y te olvidas de que has oído ese nombre.', paga = 200, va = 'pagado' },
                          { texto = '(Sacas la pistola) Lo que vale es que sigas respirando.', requiere = 'arma', va = 'miedo' },
                          { texto = 'Ya me has dicho bastante. Adiós, Lalo.', va = 'avisa' },
                      } },
                      mira_miedo = { dice = '¡Vale, vale, baja eso! Dame el pendrive... Un audio de esta tarde: Rafa Medrano, el contable de los Carroña. Se larga esta noche en avioneta desde el aeródromo de McKenzie.', opciones = {
                          { texto = 'Imprímelo. Todo. Y ni una llamada.', va = 'miedo' },
                      } },
                      pagado = { fin = 'habla', da = 'informe_lalo',
                          dice = 'Un placer hacer negocios. Te lo imprimo: la hora, el sitio y cuánta gente le cubre. Y tú y yo no nos hemos visto nunca.',
                          pista = 'Lalo: Rafa Medrano, el contable de los Carroña, sale esta noche en avioneta desde el aeródromo de McKenzie, en Grapeseed. Le cubren cinco hombres.' },
                      miedo = { fin = 'habla', da = 'informe_lalo',
                          dice = 'Ahí lo tienes, impreso. Medrano, McKenzie, esta noche. Y yo no he visto a nadie, te lo juro.',
                          pista = 'Lalo: Rafa Medrano, el contable de los Carroña, sale esta noche en avioneta desde el aeródromo de McKenzie, en Grapeseed. Le cubren cinco hombres.' },
                      avisa = { fin = 'calla', marca = 'avisado', da = 'informe_lalo',
                          dice = 'Como quieras. Toma, te lo he impreso. (Cuando arrancas, le ves por el retrovisor con el móvil en la oreja.)',
                          pista = 'Lalo te ha dado el sitio: el aeródromo de McKenzie. Pero ha vendido la información: Medrano sabe que vas.' },
                  },
              } },
            -- La caja, para la gente de Bastida: en un contenedor que existe ahi.
            { tipo = 'dejar', texto = 'Deja la caja en el contenedor de Sandy Shores: la recoge un hombre de Bastida', x = 1960.2, y = 3759.2, z = 31.2,
              objeto = 'prop_dumpster_02a', entrega = { 'caja_ortega' } },
            -- El segundo nombre de la lista. Espera la avioneta junto al hangar
            -- de McKenzie (mirado: pista de tierra a cielo abierto).
            { tipo = 'asesinar', texto = 'Elimina a Rafa Medrano en el aeródromo de McKenzie antes de que despegue', x = 2125.0, y = 4800.0, z = 40.0, sigilo = 0.5,
              objetivo = { modelo = 'a_m_m_business_01', nombre = 'Rafa Medrano', vida = 180, escena = 'WORLD_HUMAN_STAND_MOBILE', h = 200.0 },
              escoltas = Con(Carronna, { n = 5, radio = 10.0 }),
              huida = { vehiculo = 'baller', lejos = 450.0 },
              refuerzos = Con(Carronna, { n = 4, vehiculo = 'cavalcade' }),
              -- La avioneta que le espera, en la pista de tierra.
              decorado = { { 'duster', 2100.0, 4755.0, 40.2, 30.0 } },
              avisado = 'avisado' },
            { tipo = 'recoger', texto = 'Quítale a Medrano el sobre con los nombres', x = 2125.0, y = 4800.0, z = 40.0, prop = 'prop_cash_envelope_01', cuerpo = true, da = 'sobre_nombres' },
            { tipo = 'llamada', texto = 'Llama a Bastida', nombre = 'Comisario Bastida', lineas = {
                { quien = 'Bastida', dice = 'Dime que está hecho.', t = 3 },
                { quien = 'Tú', dice = 'Medrano no se ha subido a ningún avión. Tengo el sobre con los nombres.', t = 5 },
                { quien = 'Bastida', dice = '¿Y la caja de Ortega?', t = 3 },
                { quien = 'Tú', dice = 'En el contenedor de Sandy, como dijiste. Ortega estaba en los pozos.', t = 5 },
                { quien = 'Bastida', dice = 'Que lo encuentre la científica dentro de una semana. Quema ese sobre.', t = 5 },
                { quien = 'Bastida', dice = 'Ya van dos nombres tachados de la lista. Descansa. Te llamaré.', t = 5 },
            } },
        },
    },

    {
        id = 'camello_playa', nivel = 1, tiempo = 120, pago = 7000, minimo = 2,
        titulo = 'El camello que habla',
        resumen = 'Para dos. Un camello de la playa vende a Asuntos Internos los nombres de los que cobran de Bastida. El tercero de la lista.',
        lore = {
            'EL OBJETIVO · «El Gallego». Controla la venta en las playas de Vespucci y Del Perro y, desde hace un mes, también otra cosa: le pasa a Asuntos Internos los nombres de los agentes que cobran de Bastida, a cambio de que miren hacia otro lado. Es el tercer nombre de la Lista Negra. Bastida lo quiere callado, y quiere la libreta donde apunta a quién vende… y a quién delata.',
            'ESTO NO ES PARA UNO · El Gallego tiene ojos en toda la playa. Necesitáis ser dos, y cada uno tiene su papel. EL QUE HABLA (quien acepta): conversaciones, registros y entrar a los sitios. LA SOMBRA (el primero que invites): seguir, vigilar, cubrir y la parte técnica. Si va alguien más, hace de apoyo.',
            'EL EQUIPO · No necesitáis traer nada. Nando, en el aparcamiento de Vespucci, os da todo lo que hace falta: prismáticos, linterna, micro, ganzúa eléctrica y radio. La cámara para las fotos la tenéis desde que aceptáis. Al acabar se devuelve todo.',
            'EL PLAN · Un camello del Gallego, «el Chino», vende en la playa de Del Perro, bajo el muelle: uno le aprieta mientras el otro le registra la moto. Su repartidor os llevará hasta el bar donde el Gallego hace negocios; allí uno distrae al dueño y el otro deja un micro en la trastienda. La escucha os dirá dónde guarda la mercancía y la libreta: un patio de los muelles de Elysian lleno de guardias. Antes, Nando os deja al repartidor atado a una silla: uno pregunta, el otro aprieta (amenazas, pinzas, batería) hasta que suelte la clave de la caja. Después, al patio: uno entra y el otro, con los prismáticos desde donde quiera, le marca a los guardias. Un apagón, una caja fuerte y setenta y cinco segundos. Después, dos testigos que tienen que contar lo mismo… y el Gallego en el puerto, con escolta. Uno se acerca. El otro, desde arriba, le abre el camino.',
            'LO QUE OS VAIS A ENCONTRAR · Gente armada que patrulla, una emboscada si os dejáis ver, refuerzos si salta la alarma. Si el repartidor os ve, o si vuestras versiones no cuadran, el Gallego sabrá que vais y os estará esperando. Y Bastida quiere la foto del cuerpo: sin foto no hay paga.',
        },
        pasos = {
            -- 1 · Nando da el material, pero solo si estais los dos (mirado: aparcamiento abierto).
            { tipo = 'investigar', texto = 'Id los dos a ver a Nando al aparcamiento de Vespucci: os da el material', x = -1183.0, y = -1500.0, z = 3.4,
              npc = { modelo = 'a_m_m_hillbilly_02', nombre = 'Nando, el del material', escena = 'WORLD_HUMAN_SMOKING', h = 270.0 },
              coche = { modelo = 'burrito3', dx = -6.0, dy = 0.0, h = 90.0, matricula = 'NANDO 07' },
              accion = 'Hablar con Nando', escena_jugador = 'WORLD_HUMAN_STAND_IMPATIENT', tiempo = 1,
              juntos = 'Nando no le da material a uno solo. Trae a tu compañero (botón Invitar en la Lista Negra) y venid los dos.',
              equipo = { 'weapon_flashlight' },
              dialogo = {
                  inicio = 'a',
                  nodos = {
                      a = { dice = 'Bastida me dijo que vendríais dos. Bien. Aquí no hay nombres, ni recibos, ni preguntas.', opciones = {
                          { texto = '¿Qué tienes para nosotros?', va = 'kit' },
                          { texto = 'Rápido, Nando. No tenemos toda la noche.', va = 'kit' },
                      } },
                      kit = { fin = 'habla', da = { 'kit_prismaticos', 'kit_micro', 'kit_ganzua', 'kit_radio' },
                          dice = 'Prismáticos, linternas, un micro que pega en cualquier sitio, ganzúa eléctrica y radios. Con los prismáticos se vigila desde lejos y se le avisa al otro de quién hay. Lo quiero todo de vuelta. Suerte… la vais a necesitar.',
                          pista = 'Material recibido. Mirad la Lista Negra: cada uno tiene ya su llamada esperando.' },
                  },
              } },
            -- 2 · Cada uno su llamada: ninguno tiene la pista entera.
            { tipo = 'doble', texto = 'Las llamadas', espera = 'Tu compañero sigue al teléfono. Contaos lo que sabéis.',
              partes = {
                  habla = { tipo = 'llamada', texto = 'Atiende la llamada de Bastida', nombre = 'Comisario Bastida', lineas = {
                      { quien = 'Bastida', dice = 'El Gallego. Vende en la playa y ahora también vende otra cosa: nuestros nombres, a Asuntos Internos.', t = 7 },
                      { quien = 'Bastida', dice = 'Tiene a un camello en la playa de Del Perro, el Chino. Apriétale. Que te diga quién le reparte.', t = 6 },
                      { quien = 'Tú', dice = '¿Y la sombra?', t = 2 },
                      { quien = 'Bastida', dice = 'Rocío le está llamando ahora. Ella sabe dónde aparca el Chino la moto. Coordinaos.', t = 6 },
                  } },
                  sombra = { tipo = 'llamada', texto = 'Atiende la llamada de Rocío, de Archivo', nombre = 'Rocío, de Archivo', lineas = {
                      { quien = 'Rocío', dice = 'No tengo mucho tiempo. El Chino, el camello de la playa, tiene una moto de cross en el aparcamiento de la playa de Del Perro.', t = 7 },
                      { quien = 'Rocío', dice = 'Debajo del asiento guarda una libreta con las entregas. Ábrele el asiento mientras tu compañero le entretiene.', t = 7 },
                      { quien = 'Tú', dice = '¿Y si me ve?', t = 2 },
                      { quien = 'Rocío', dice = 'Entonces corre. Y no me has llamado nunca.', t = 4 },
                  } },
              } },
            -- 3 · A la vez: el Chino bajo el muelle de Del Perro y su moto en el aparcamiento de esa playa (mirados 06/10: arena y asfalto abiertos).
            { tipo = 'doble', texto = 'El Chino y su moto',
              partes = {
                  habla = { tipo = 'investigar', texto = 'Aprieta al Chino en la playa de Del Perro, bajo el muelle', x = -1560.0, y = -1100.0, z = 3.5,
                      npc = { modelo = 'g_m_y_ballasout_01', nombre = 'El Chino', escena = 'WORLD_HUMAN_DRUG_DEALER', h = 30.0 },
                      accion = 'Hablar con el Chino', escena_jugador = 'WORLD_HUMAN_STAND_IMPATIENT', tiempo = 1,
                      dialogo = {
                          inicio = 'a',
                          nodos = {
                              a = { dice = '¿Buscas algo, jefe? Aquí todo es legal: sol, arena y buen rollo.', opciones = {
                                  { texto = 'Busco a quien te trae la mercancía.', va = 'no' },
                                  { texto = '(Sacas la placa) Tu repartidor. Ahora.', va = 'placa' },
                                  { texto = '(Le enseñas un billete de cien) Cien pavos por un nombre.', paga = 100, va = 'pagado' },
                              } },
                              no = { dice = 'Yo no sé de qué me hablas. Me lo traen los Reyes Magos.', opciones = {
                                  { texto = '(Sacas la pistola) Prueba otra vez.', requiere = 'arma', va = 'miedo' },
                                  { texto = 'Cien pavos y aquí no ha pasado nada.', paga = 100, va = 'pagado' },
                              } },
                              placa = { dice = 'Una placa… ¿Y qué? Aquí las placas compran como todos.', opciones = {
                                  { texto = '(Sacas la pistola) Esta no compra.', requiere = 'arma', va = 'miedo' },
                                  { texto = 'Cien pavos. Última oferta.', paga = 100, va = 'pagado' },
                              } },
                              pagado = { fin = 'habla',
                                  dice = 'Se agradece. Me lo trae uno en una furgoneta blanca. Carga cada noche en Vespucci, al lado del aparcamiento de la playa. Ya debe de estar allí.',
                                  pista = 'El Chino: le reparte uno en una furgoneta blanca que carga junto al aparcamiento de la playa de Vespucci. Ya está allí.' },
                              miedo = { fin = 'habla',
                                  dice = '¡Vale, vale! Una furgoneta blanca, en el aparcamiento de Vespucci. ¡No le digas que he sido yo, que el Gallego me corta las manos!',
                                  pista = 'El Chino: le reparte uno en una furgoneta blanca que carga junto al aparcamiento de la playa de Vespucci. Ya está allí.' },
                          },
                      } },
                  sombra = { tipo = 'investigar', texto = 'Ábrele el asiento a la moto del Chino en el aparcamiento de la playa de Del Perro', x = -1650.0, y = -950.0, z = 6.8,
                      decorado = { { 'sanchez', -1650.0, -950.0, 6.8, 0.0 } },
                      accion = 'Forzar el asiento', anim = { 'mini@repair', 'fixing_a_player' }, tiempo = 6,
                      minijuego = { 'pines', 'easy', titulo = 'La cerradura del asiento', fallo = 'Se te ha escapado un pin. Otra vez.' },
                      da = 'libreta_chino',
                      pista = 'Debajo del asiento, una libreta: horas, cantidades y una palabra que se repite: «Tequi».' },
              } },
            -- 4 · El repartidor: la sombra le sigue; el que habla se adelanta al bar.
            { tipo = 'doble', texto = 'El repartidor',
              partes = {
                  sombra = { tipo = 'seguir', texto = 'Sigue a la furgoneta blanca del repartidor sin que te vea', x = -1215.8, y = -1531.8, z = 3.2, h = 225.0,
                      vehiculo = 'speedo', color = 111, conductor = 'g_m_y_salvagoon_02', matricula = 'GALL 113', nombre = 'La furgoneta del repartidor',
                      destino = { x = -575.2, y = 258.8, z = 81.9, radio = 25.0, puerta = { x = -555.5, y = 273.8, z = 82.9, h = 0.0 } }, velocidad = 13.0, cerca = 15.0,
                      visto = 'avisado', alVerte = 'El repartidor te ha visto por el retrovisor. Va a llamar al Gallego.',
                      alSalir = 'La furgoneta arranca. Ni pegado ni lejos: entre 35 y 140 metros. Si le pierdes, se acabó.',
                      alPerder = 'La furgoneta se ha perdido entre el tráfico. Sin repartidor no hay bar ni Gallego: el trabajo se cae.' },
                  habla = { tipo = 'ir', texto = 'Adelántate al Tequi-la-la, en Vinewood, y espera en la puerta', x = -555.0, y = 271.0, z = 82.0, radio = 6.0 },
              } },
            -- 5 · En el bar: uno distrae al dueño en la puerta; el otro pone el micro atras.
            { tipo = 'doble', texto = 'El micro del Tequi-la-la',
              partes = {
                  habla = { tipo = 'investigar', texto = 'Entretén al dueño del Tequi-la-la en la puerta', x = -553.0, y = 273.0, z = 82.0,
                      npc = { modelo = 'a_m_m_business_01', nombre = 'Moe, el dueño', escena = 'WORLD_HUMAN_SMOKING', h = 225.0 },
                      accion = 'Hablar con Moe', escena_jugador = 'WORLD_HUMAN_STAND_IMPATIENT', tiempo = 1,
                      dialogo = {
                          inicio = 'a',
                          nodos = {
                              a = { dice = 'Hoy no hay concierto, colega. Vuelve el viernes.', opciones = {
                                  { texto = 'No vengo por la música. Vengo por la licencia del bar.', va = 'licencia' },
                                  { texto = 'Me han dicho que aquí se ve mucho al Gallego.', va = 'gallego' },
                              } },
                              licencia = { dice = '¿La licencia? Está en regla, como todo aquí. ¿Quién te manda?', opciones = {
                                  { texto = 'Inspección. Rutina. Cuéntame cuántos entran cada noche.', va = 'cuenta' },
                                  { texto = 'Nadie. Tengo curiosidad.', va = 'cuenta' },
                              } },
                              gallego = { dice = '¿El Gallego? Aquí viene mucha gente. Yo sirvo copas, no pregunto nombres.', opciones = {
                                  { texto = 'Pues hoy te toca contarme qué copas sirves.', va = 'cuenta' },
                              } },
                              cuenta = { fin = 'habla',
                                  dice = 'Mira, entra quien entra, paga y se va. Hay gente que pide la trastienda para hablar tranquila, y yo no escucho. ¿Ya está? Tengo cosas que hacer.',
                                  pista = 'Moe está entretenido. Que tu compañero aproveche: la trastienda tiene una puerta al patio de atrás.' },
                          },
                      } },
                  sombra = { tipo = 'investigar', texto = 'Pon el micro en la puerta de la trastienda, en el patio de atrás del Tequi-la-la', x = -565.9, y = 295.78, z = 83.03, h = 81.92,
                      accion = 'Colocar el micro', anim = { 'mini@repair', 'fixing_a_player' }, tiempo = 5,
                      minijuego = { 'senal', 'easy', titulo = 'Sintonizar el micro', fallo = 'El micro pita. Vuelve a sintonizarlo.' },
                      pista = 'Micro puesto y emitiendo. Ahora a esperar a que alguien hable.' },
              } },
            -- 6 · La escucha: los dos oyen al Gallego.
            { tipo = 'llamada', escucha = true, texto = 'Escuchad el micro del Tequi-la-la', nombre = 'Micro · trastienda del Tequi-la-la', lineas = {
                { quien = 'Repartidor', dice = 'Lo de la playa está cubierto. El Chino no ha dicho nada.', t = 5 },
                { quien = 'El Gallego', dice = 'El Chino habla hasta dormido. Esta noche movemos todo del patio de Elysian.', t = 6 },
                { quien = 'Repartidor', dice = '¿Y la libreta?', t = 3 },
                { quien = 'El Gallego', dice = 'En la caja de la caseta, como siempre. Que nadie la toque hasta que yo llegue al puerto.', t = 6 },
                { quien = 'El Gallego', dice = 'Y dobla la gente del patio. Hay polis haciendo preguntas.', t = 5 },
            } },
            -- 7 · El repartidor, atado: uno pregunta y el otro aprieta (mirado: explanada abierta al norte del patio).
            { tipo = 'doble', texto = 'El repartidor, atado',
              partes = {
                  habla = { tipo = 'investigar', texto = 'Nando tiene al repartidor atado en una explanada de Elysian. Tú preguntas: sácale la clave de la caja',
                      x = SITIO_PRESO.x, y = SITIO_PRESO.y, z = SITIO_PRESO.z, oz = SITIO_PRESO.oz, npc = PRESO_REPARTIDOR,
                      accion = 'Interrogar', tiempo = 1,
                      dialogo = {
                          inicio = 'a',
                          nodos = {
                              a = { dice = 'Yo no sé nada, tío. Soy repartidor. Llevo cajas. ¡Soltadme!', opciones = {
                                  { texto = '¿Para quién llevas las cajas?', requiere = 'presion:1', va = 'quien' },
                                  { texto = 'Por las buenas: ¿quién te paga?', va = 'nada' },
                              } },
                              nada = { dice = 'Por las buenas no sé nada. ¿Me oyes? ¡Nada!', opciones = {
                                  { texto = '(Miras a tu compañero) Ayúdale a recordar.', va = 'a' },
                              } },
                              quien = { dice = 'Vale… vale. Para el Gallego. Llevo y traigo, nada más. Yo no toco la mercancía.', opciones = {
                                  { texto = 'La libreta del Gallego. ¿Dónde está?', va = 'libreta' },
                                  { texto = 'La caja de la caseta. La combinación.', requiere = 'presion:2', va = 'caja' },
                              } },
                              libreta = { dice = 'En la caja fuerte de la caseta, en el patio de Elysian. Pero la clave solo la sabe él…', opciones = {
                                  { texto = '¿Solo él? Mírame a la cara.', requiere = 'presion:2', va = 'caja' },
                              } },
                              caja = { dice = '…y yo. Yo se la apunto, que él no se acuerda de nada. Pero si os la doy, me mata. ¡Me mata!', opciones = {
                                  { texto = '(Tu compañero coge la batería) Última oportunidad.', requiere = 'presion:3', va = 'fin' },
                              } },
                              fin = { fin = 'habla', da = 'clave_caja',
                                  dice = '¡Veintitrés, cuarenta y uno, ocho! ¡Veintitrés, cuarenta y uno, ocho! Y la caja tiene alarma: si no cortáis la luz del patio, salta. El cuadro está en la nave de al lado. ¡Ya está, ya está!',
                                  pista = 'La clave de la caja del Gallego: 23-41-08. Y la alarma se corta quitando la luz del patio.' },
                          },
                      } },
                  sombra = { tipo = 'torturar', apoyo = true, texto = 'Nando tiene al repartidor atado en una explanada de Elysian. Tú aprietas: que tu compañero pregunte',
                      x = SITIO_PRESO.x, y = SITIO_PRESO.y, z = SITIO_PRESO.z, oz = SITIO_PRESO.oz, npc = PRESO_REPARTIDOR,
                      tope = 'Ya no aguanta más: que pregunte tu compañero',
                      acciones = {
                          -- `grita`: lo que dice el preso (con voz); `dolor`: gritos de dolor del juego.
                          { nombre = 'Amenazarle', t = 6, texto = 'Le gritas a un palmo de la cara. Tiembla.',
                            grita = '¡Vale, vale! ¡Tranquilo, tío, tranquilo! ¡Que yo no he hecho nada!',
                            jugador = { 'misscarsteal4@actor', 'actor_berating_loop' } },
                          { nombre = 'Las pinzas', t = 7, escena = true, texto = 'Le enseñas las pinzas. Grita antes de que le toques.',
                            grita = '¡No, no, no! ¡Los dientes no! ¡Para, para, por favor!', dolor = true,
                            jugador = { 'missfbi3_toothpull', 'pull_tooth_loop_player' }, victima = { 'missfbi3_toothpull', 'pull_tooth_loop_victim' },
                            mano = { 'prop_pliers_01', 0.12, 0.02, -0.02, -90.0, 0.0, 0.0 } },
                          { nombre = 'La batería', t = 9, escena = true, texto = 'Pinzas a la batería. Un chispazo y se le van los ojos.',
                            grita = '¡Aaah! ¡Para! ¡Para, joder! ¡Hablo, hablo, os lo cuento todo!', dolor = true,
                            jugador = { 'missfbi3_electrocute', 'electrocute_both_loop_player' }, victima = { 'missfbi3_electrocute', 'electrocute_both_loop_victim' },
                            -- Una pinza en cada mano, con su cable a cada borne de la bateria, y chispazos.
                            mano = { 'prop_tool_pliers', 0.08, 0.02, -0.02, -90.0, 0.0, 0.0 },
                            mano2 = { 'prop_tool_pliers', 0.08, 0.02, 0.02, 90.0, 0.0, 0.0 },
                            suelo = { 'prop_car_battery_01', 0.9, 0.6 }, cables = true, chispas = true },
                      } },
              } },
            -- 8 · El patio de Elysian: uno lo registra entre guardias; el otro le cubre desde 40 m (mirado: vista libre).
            { tipo = 'doble', texto = 'El patio de Elysian',
              partes = {
                  habla = { tipo = 'rastrear', texto = 'Registra los muelles del Gallego sin que te vean: linterna en mano, busca 4 cosas', x = -228.0, y = -2510.0, z = 6.0,
                      -- Los puntos estan repartidos por todo el muelle (puestos por el usuario en partida, 06/10).
                      alcance = 120.0, ocultos = true,
                      guardias = Con(Salvas, { n = 10, radio = 45.0, vista = 24.0, oido = 14.0, distancia = 160.0 }),
                      ayuda = 'Zona del Gallego: si te ven, sube la Atención. Agáchate (Ctrl) y alumbra con la linterna: lo que buscas solo se ve con la luz encima. Son 4 cosas.',
                      puntos = {
                          { x = -159.48, y = -2462.36, z = 6.02, nombre = 'Cajas abiertas', pista = 'Cajas de pescado con doble fondo. Vacías: ya lo han movido casi todo.',
                            props = { { 'prop_cs_cardbox_01', 0.0, 0.0, 224.0 }, { 'prop_cs_cardbox_01', 0.5, 0.4, 200.0 } } },
                          { x = -217.0, y = -2468.03, z = 6.0, nombre = 'Báscula', pista = 'Una báscula de precisión y bolsas de corte. Aquí se prepara la mercancía.',
                            props = { { 'prop_drug_package', 0.0, 0.0, 273.0 }, { 'prop_drug_package', 0.35, 0.25, 250.0 } } },
                          { x = -254.25, y = -2591.25, z = 6.0, nombre = 'Albarán', pista = 'Un albarán con la hora de la carga: el puerto, a las dos. Y una nota: «La caja de la caseta: la de siempre».',
                            props = { { 'prop_cs_documents_01', 0.0, 0.0, 265.0 } } },
                          { x = -288.76, y = -2496.66, z = 7.29, nombre = 'Bolsa escondida', pista = 'Una bolsa con fajos atados con gomas y una nota: «Para el de AI, el viernes». El Gallego también le paga a alguien de Asuntos Internos.',
                            props = { { 'prop_money_bag_01', 0.0, 0.0, 318.0 } } },
                      } },
                  sombra = { tipo = 'cubrir', apoyo = true, texto = 'Vigila el patio con los prismáticos desde donde quieras, sin que te vean: márcale los guardias a tu compañero', x = -184.7, y = -2468.0, z = 6.0,
                      -- Los prismaticos se sacan donde se quiera, a 25-110 m del patio (`libre`).
                      mira = { x = -228.0, y = -2510.0, z = 6.0 }, libre = { min = 25.0, max = 110.0 }, accion = 'Sacar los prismáticos' },
              } },
            -- 9 · El apagon: la sombra corta la luz y el que habla abre la caja en 75 s.
            { tipo = 'doble', texto = 'El apagón y la caja',
              partes = {
                  sombra = { tipo = 'investigar', texto = 'Corta la luz del patio en el cuadro eléctrico', x = -129.2, y = -2502.7, z = 5.1,
                      accion = 'Puentear el cuadro', anim = { 'mini@repair', 'fixing_a_player' }, tiempo = 3,
                      minijuego = { 'circuito', 'easy', titulo = 'Cortar la luz del patio', fallo = 'Salta un chispazo. Prueba otra vez.' },
                      abre = { nombre = 'apagon', segundos = 75 },
                      pista = '¡Apagón! Tu compañero tiene 75 segundos para abrir la caja.' },
                  habla = { tipo = 'investigar', texto = 'Abre la caja fuerte junto a la caseta durante el apagón', x = -210.0, y = -2530.5, z = 5.0,
                      decorado = { { 'p_v_43_safe_s', -210.0, -2530.5, 5.0, 180.0 } },
                      -- Os han visto salir del patio: vienen a por vosotros a la caseta.
                      emboscada = Con(Salvas, { n = 3, vehiculo = 'cavalcade', distancia = 60.0,
                          aviso = 'Un Cavalcade entra en los muelles. Os han visto en el patio.',
                          previo = 'Me dicen que el Gallego ha mandado más gente a Elysian. Daos prisa con la caja.' }),
                      ventana = 'apagon', sinVentana = 'Con la luz dada salta la alarma de la caja. Espera a que tu compañero corte la luz.',
                      accion = 'Abrir la caja fuerte', anim = { 'mini@safe_cracking', 'idle_base' }, tiempo = 6,
                      minijuego = { 'dial', 'easy', titulo = 'La caja del Gallego · 23-41-08', fallo = 'No era esa combinación.' },
                      -- Sin la clave que suelta el repartidor (paso 7) no se abre.
                      necesita = 'clave_caja', sinNecesita = 'Sin la clave no hay manera. Sácasela al repartidor.',
                      da = 'libreta_gallego',
                      pista = 'La libreta del Gallego: clientes, cantidades… y una página entera con nombres de agentes y lo que cobran.' },
              } },
            -- 10 · Poli bueno, poli malo: dos testigos; las versiones tienen que cuadrar.
            { tipo = 'doble', texto = 'Dos testigos', cuadrar = 'avisado',
              partes = {
                  habla = { tipo = 'investigar', texto = 'Pregunta al gruista del puerto dónde espera el Gallego', x = 864.0, y = -2950.0, z = 4.9,
                      npc = { modelo = 's_m_y_dockwork_01', nombre = 'El gruista', escena = 'WORLD_HUMAN_CLIPBOARD', h = 90.0 },
                      accion = 'Hablar con el gruista', escena_jugador = 'WORLD_HUMAN_STAND_IMPATIENT', tiempo = 1,
                      dialogo = {
                          inicio = 'a',
                          nodos = {
                              a = { dice = 'Turno de noche. ¿Qué pasa ahora?', opciones = {
                                  { texto = '(Poli malo) O me dices dónde para el Gallego, o te paro la grúa un mes.', va = 'malo' },
                                  { texto = '(Poli bueno) Tranquilo. Solo dime si ha venido gente rara al muelle.', va = 'bueno' },
                              } },
                              malo = { fin = 'habla', version = 'muelle',
                                  dice = 'Vale, vale… Espera en el muelle, junto a la grúa, con cinco tipos. A las dos llega un barco.' },
                              bueno = { fin = 'habla', version = 'muelle',
                                  dice = 'Rara… Hay un tipo con cinco escoltas en el muelle, al pie de la grúa. Dicen que espera un barco a las dos.' },
                          },
                      } },
                  sombra = { tipo = 'investigar', texto = 'Pregunta al capataz de Elysian por la carga de esta noche', x = -218.0, y = -2462.0, z = 5.0,
                      npc = { modelo = 's_m_m_dockwork_01', nombre = 'El capataz', escena = 'WORLD_HUMAN_SMOKING', h = 180.0 },
                      accion = 'Hablar con el capataz', escena_jugador = 'WORLD_HUMAN_STAND_IMPATIENT', tiempo = 1,
                      dialogo = {
                          inicio = 'a',
                          nodos = {
                              a = { dice = 'Si vienes por lo del apagón, yo estaba en el bar.', opciones = {
                                  { texto = '(Poli malo) Me da igual dónde estabas. ¿Adónde va la carga del Gallego?', va = 'malo' },
                                  { texto = '(Poli bueno) No vengo por eso. Solo quiero saber adónde va la carga de esta noche.', va = 'bueno' },
                                  { texto = 'La carga va al aeropuerto, ¿verdad?', va = 'mal' },
                              } },
                              malo = { fin = 'habla', version = 'muelle',
                                  dice = 'Al puerto, al muelle de la grúa. El Gallego la recibe en persona. Y ahora déjame en paz.' },
                              bueno = { fin = 'habla', version = 'muelle',
                                  dice = 'Al puerto. El Gallego la recibe en el muelle de la grúa, con su gente.' },
                              mal = { fin = 'habla', version = 'aeropuerto',
                                  dice = '…Sí, sí, al aeropuerto. (Sonríe. Cuando te vas, le ves con el teléfono en la mano.)',
                                  pista = 'El capataz te ha seguido la corriente. Si tu compañero oye otra cosa, el Gallego sabrá que vais.' },
                          },
                      } },
              } },
            -- 11 · El tercero de la lista: uno se acerca y el otro le cubre desde 44 m (mirado: vista libre).
            { tipo = 'doble', texto = 'El Gallego',
              partes = {
                  habla = { tipo = 'asesinar', texto = 'Elimina al Gallego en el muelle de la grúa', x = 850.0, y = -2944.0, z = 4.9, sigilo = 0.5,
                      objetivo = { modelo = 'g_m_m_mexboss_01', nombre = 'El Gallego', vida = 200, escena = 'WORLD_HUMAN_STAND_MOBILE', h = 180.0 },
                      escoltas = Con(Salvas, { n = 5, radio = 10.0 }),
                      huida = { vehiculo = 'baller', lejos = 450.0 },
                      refuerzos = Con(Salvas, { n = 4, vehiculo = 'cavalcade' }),
                      avisado = 'avisado' },
                  sombra = { tipo = 'cubrir', apoyo = true, texto = 'Vigila el muelle con los prismáticos desde donde quieras: márcale los escoltas a tu compañero', x = 850.0, y = -2900.0, z = 5.9,
                      mira = { x = 850.0, y = -2944.0, z = 4.9 }, libre = { min = 25.0, max = 110.0 }, accion = 'Sacar los prismáticos' },
              } },
            { tipo = 'recoger', texto = 'Quítale el teléfono al Gallego', x = 850.0, y = -2944.0, z = 4.9, prop = 'prop_npc_phone_02', cuerpo = true, da = 'movil_gallego' },
            { tipo = 'llamada', texto = 'Llamada de Bastida', nombre = 'Comisario Bastida', lineas = {
                { quien = 'Bastida', dice = '¿Está hecho?', t = 3 },
                { quien = 'Tú', dice = 'El Gallego no vuelve a hablar con nadie. Tenemos la libreta y su teléfono.', t = 5 },
                { quien = 'Bastida', dice = 'Buen trabajo, los dos. Quemad la libreta después de que yo la lea.', t = 5 },
                { quien = 'Bastida', dice = 'Ya van tres nombres tachados. Y los siguientes no van a ser tan fáciles.', t = 6 },
            } },
        },
    },

    --[[ La cuarta: ir a un sitio, eliminar al de la lista y marcharse. Sin
         pistas que buscar ni nada que recoger: una llamada que lo explica, el
         sitio marcado en el mapa y un aviso en cada paso con lo que toca.
         Va muy escoltado (ocho guardias): en cuanto empiezan los tiros se
         sube al Baller y huye a toda velocidad, marcado en el mapa y con la
         ruta del GPS siguiendole, para perseguirle y rematarle.
         El sitio esta medido con rayos (10/10): explanada abierta de la
         terminal, 12 m de claro y a 11 m del carril de los camiones. ]]
    {
        id = 'dirigente_sindicato', nivel = 2, tiempo = 30, pago = 4000,
        titulo = 'El dirigente del sindicato',
        resumen = 'Ve al puerto, elimina a Rubén Ochoa y márchate.',
        lore = {
            'Rubén Ochoa dirige el sindicato de estibadores y ha prometido a la prensa que mañana enseña quién cobra por dejar pasar contenedores en el puerto. Bastida cobra.',
            'Qué tienes que hacer: 1) ve a la terminal de contenedores del puerto, está marcada en el mapa. 2) Elimina a Ochoa: es el del traje con la carpeta, y va rodeado de ocho guardias de seguridad armados. 3) Aléjate de la terminal. No hay que buscar ni recoger nada.',
            'En cuanto suene un tiro Ochoa se sube a su Baller y huye a toda velocidad. Te sale marcado en el mapa con la ruta: persíguele y acaba con él antes de que se pierda. Si le matas sin tocar a los guardias cobras la mitad más.',
        },
        pasos = {
            { tipo = 'llamada', texto = 'Atiende la llamada de Bastida', nombre = 'Comisario Bastida', lineas = {
                { quien = 'Bastida', dice = 'El siguiente de la lista es Rubén Ochoa, el del sindicato de estibadores. Mañana habla con la prensa.', t = 6 },
                { quien = 'Bastida', dice = 'Ahora mismo está en la terminal de contenedores del puerto, revisando con una carpeta. Te lo marco en el mapa.', t = 6 },
                { quien = 'Tú', dice = '¿Va solo?', t = 2 },
                { quien = 'Bastida', dice = 'Ocho guardias de seguridad, armados. Si le das a él sin tocarlos a ellos, te pago la mitad más.', t = 6 },
                { quien = 'Bastida', dice = 'Al primer tiro se mete en su Baller y sale volando. Te lo marco en el mapa: le sigues y lo rematas.', t = 6 },
                { quien = 'Bastida', dice = 'No hay nada que buscar ni que traer. Vas, lo haces y te marchas del puerto.', t = 5 },
            } },
            { tipo = 'asesinar', texto = 'Ve a la terminal del puerto (marcada en el mapa) y elimina a Rubén Ochoa', x = 965.0, y = -3060.0, z = 4.9, sigilo = 0.5,
              ayuda = 'Sigue la ruta del mapa hasta la terminal de contenedores del puerto. Ochoa es el del traje con la carpeta, en la explanada, rodeado de ocho guardias. Si salta la alarma se sube a su Baller y huye: te sale marcado en el mapa con la ruta, persíguele y acaba con él.',
              objetivo = { modelo = 'a_m_y_business_02', nombre = 'Rubén Ochoa', vida = 150, escena = 'WORLD_HUMAN_CLIPBOARD', h = 90.0 },
              escoltas = Con(Vigilas, { n = 8, radio = 10.0 }),
              huida = { vehiculo = 'baller', lejos = 3000.0 } },
            { tipo = 'alejarse', texto = 'Sal del puerto: aléjate de la terminal', x = 965.0, y = -3060.0, z = 4.9, radio = 250.0,
              ayuda = 'Hecho. Ahora sal de la zona marcada en el mapa y el trabajo queda cobrado.' },
        },
    },
    {
        id = 'fiscal_juzgado', nivel = 2, tiempo = 30, pago = 3200,
        titulo = 'El fiscal no llega',
        resumen = 'Un fiscal con un maletín camino de Mission Row.',
        lore = {
            'El fiscal Morán sale de su casa de Rockford Hills con el maletín del caso contra la comisaría. Va a entregarlo en persona en la puerta de la comisaría de Mission Row.',
            'Si llega, Bastida cae y tú con él. Intercepta su coche por el camino. Lleva tres escoltas dentro y un Baller detrás con tres más. En cuanto vea que le sigues, acelerará.',
        },
        pasos = {
            { tipo = 'interceptar', texto = 'Intercepta al fiscal antes de que llegue a Mission Row', x = -827.2, y = 175.5, z = 69.8, h = 330.0,
              vehiculo = 'cognoscenti',
              objetivo = { modelo = 'a_m_y_business_03', nombre = 'El fiscal Morán', vida = 200 },
              -- 3 en su coche y 3 en el Baller que le sigue.
              escoltas = Con(Vigilas, { n = 6, vehiculo = 'baller' }),
              destino = { x = 399.2, y = -990.0, z = 28.5, nombre = 'Mission Row' } },
        },
    },
    {
        id = 'decomiso_sandy', nivel = 2, tiempo = 35, pago = 3000,
        titulo = 'Decomiso que no consta',
        resumen = 'Un alijo que nunca llegará al depósito de pruebas.',
        lore = {
            'Esta mañana ha aterrizado en el aeródromo de Sandy Shores una avioneta con un alijo. Si lo decomisa la Policía, acaba en un informe. Si lo decomisas tú, no.',
            'Lo esperan seis hombres armados junto al hangar. Quítaselo y escóndelo en el contenedor del rancho de Grapeseed: alguien de Bastida pasará a recogerlo. El informe dirá que la avioneta llegó vacía.',
        },
        pasos = {
            { tipo = 'matar', texto = 'Limpia el aeródromo de Sandy Shores', x = 1720.0, y = 3290.0, z = 41.1,
              enemigos = Con(Vigilas, { n = 6, radio = 12.0 }) },
            { tipo = 'recoger', texto = 'Coge el alijo', x = 1720.0, y = 3290.0, z = 41.1, prop = 'prop_drug_package' },
            En(RANCHO_CONTENEDOR, { tipo = 'dejar', texto = 'Esconde el alijo en el contenedor del rancho de Grapeseed' }),
        },
    },

    -- ═══ Nivel 3 · Podrido ═══════════════════════════════════════════════
    {
        id = 'testigo_protegido', nivel = 3, tiempo = 40, pago = 5500,
        titulo = 'El testigo protegido',
        resumen = 'Seis federales cuidan de alguien que sabe demasiado.',
        lore = {
            'El contable de los Carroña ha cambiado de bando y lo tienen escondido en el motel de la ruta 68, con seis agentes federales de guardia día y noche en el patio.',
            'Los federales no son matones de barrio: si te ven, te disparan, piden refuerzos y sacan al testigo en su todoterreno. Entra de noche, agachado y sin ruido. Si sale de allí, no lo vuelves a encontrar.',
        },
        pasos = {
            { tipo = 'asesinar', texto = 'Elimina al testigo en el motel de la ruta 68', x = 1122.0, y = 2650.0, z = 37.0, sigilo = 0.6,
              objetivo = { modelo = 'a_m_m_hillbilly_01', nombre = 'El testigo', vida = 160, escena = 'WORLD_HUMAN_SMOKING', h = 300.0 },
              escoltas = Con(Federales, { n = 6, radio = 11.0 }),
              huida = { vehiculo = 'fbi2', lejos = 500.0 },
              refuerzos = Con(Federales, { n = 4, vehiculo = 'fbi2' }) },
            { tipo = 'alejarse', texto = 'Desaparece antes de que lleguen más federales', x = 1122.0, y = 2650.0, z = 37.0, radio = 400.0 },
        },
    },
    {
        id = 'kuruma_blindado', nivel = 3, tiempo = 40, pago = 5200,
        titulo = 'El Kuruma blindado',
        resumen = 'El coche que mueve el dinero de los sobornos.',
        lore = {
            'Los Carroña pagan a los agentes desde un Kuruma blindado que aparcan junto a los hangares del aeropuerto. Hoy está cargado.',
            'Lo vigilan cinco hombres. Sin ellos, el coche es tuyo. Llévalo al taller clandestino de El Burro: lo que hay dentro va a desaparecer de las cuentas de todos.',
        },
        pasos = {
            { tipo = 'matar', texto = 'Quita de en medio a los guardaespaldas del Kuruma', x = -1270.0, y = -3380.0, z = 13.9,
              enemigos = Con(Carronna, { n = 5, radio = 9.0 }) },
            { tipo = 'robar', texto = 'Súbete al Kuruma', x = -1265.0, y = -3385.0, z = 13.9, h = 330.0, vehiculo = 'kuruma2' },
            En(TALLER_EL_BURRO, { tipo = 'entregar', texto = 'Llévalo al taller clandestino de El Burro', radio = 8.0, carroceria = 500 }),
        },
    },
    {
        id = 'tuerto_stab', nivel = 3, tiempo = 40, pago = 6000,
        titulo = 'El Tuerto sabe demasiado',
        resumen = 'El jefe de los Lost, que va vendiendo nombres.',
        lore = {
            'El Tuerto, el jefe de los Lost de Stab City, fue durante años el confidente de Bastida. Ahora que los Carroña le pagan más, va diciendo nombres a quien quiera oírlos.',
            'Está de fiesta entre las caravanas con ocho de los suyos, y si se arma jaleo llegan más en furgoneta. El Tuerto se subirá a su Daemon y no parará hasta el desierto. Que sea la última fiesta.',
        },
        pasos = {
            { tipo = 'asesinar', texto = 'Acaba con el Tuerto en Stab City', x = 70.0, y = 3700.0, z = 39.7, sigilo = 0.4,
              objetivo = { modelo = 'g_m_y_lost_02', nombre = 'El Tuerto', vida = 400, blindaje = 100, arma = 'WEAPON_PUMPSHOTGUN', escena = 'WORLD_HUMAN_PARTYING', h = 180.0 },
              escoltas = Con(Lost, { n = 8, radio = 13.0, arma = 'WEAPON_SAWNOFFSHOTGUN', vida = 220, blindaje = 50 }),
              huida = { vehiculo = 'daemon', lejos = 600.0 },
              refuerzos = Con(Lost, { n = 4, modelo = 'g_m_y_lost_03', arma = 'WEAPON_MICROSMG', vehiculo = 'gburrito' }) },
            { tipo = 'alejarse', texto = 'Sal de Stab City', x = 70.0, y = 3700.0, z = 39.7, radio = 350.0 },
        },
    },

    -- ═══ Nivel 4 · Intocable ═════════════════════════════════════════════
    {
        id = 'su_senoria', nivel = 4, tiempo = 40, pago = 9000,
        titulo = 'Su señoría',
        resumen = 'El juez que firma mañana las órdenes de detención.',
        lore = {
            'El juez Harlan firma mañana las órdenes de detención contra media comisaría. Esta noche cena en el Observatorio Galileo y vuelve a su casa de Rockford Hills.',
            'Si llega a casa, firma. Párale en la carretera de la colina. Lleva tres escoltas en su coche y un Baller blindado detrás con tres más. No dudarán.',
        },
        pasos = {
            { tipo = 'interceptar', texto = 'Detén el coche del juez antes de que llegue a Rockford Hills', x = -410.8, y = 1185.2, z = 324.5, h = 77.0,
              vehiculo = 'schafter2',
              objetivo = { modelo = 'a_m_m_bevhills_02', nombre = 'El juez Harlan', vida = 200 },
              -- 3 en su coche y 3 en el Baller blindado que le sigue.
              escoltas = { modelo = 's_m_m_highsec_02', n = 6, arma = 'WEAPON_SMG', vida = 240, blindaje = 75, precision = 45, vehiculo = 'baller6' },
              destino = { x = -827.2, y = 175.5, z = 69.8, nombre = 'Rockford Hills' } },
        },
    },
    {
        id = 'asuntos_internos', nivel = 4, tiempo = 45, pago = 8500,
        titulo = 'La cita con Asuntos Internos',
        resumen = 'Un agente de Asuntos Internos que se vende. O eso dice.',
        lore = {
            'Un agente de Asuntos Internos ha pedido una cita en el aparcamiento del Observatorio Galileo: por un maletín, dice, el expediente contra Bastida se pierde.',
            'Bastida no se fía y te manda a ti. Si es un trato, coges los papeles del expediente y los echas al buzón de Mission Row, a su nombre. Si es una trampa, también, pero antes vas a tener trabajo.',
        },
        pasos = {
            { tipo = 'matar', texto = 'Era una trampa: sal vivo del Observatorio', x = -410.0, y = 1180.0, z = 325.6,
              enemigos = Con(Mercs, { n = 8, radio = 15.0 }) },
            { tipo = 'recoger', texto = 'Coge los papeles del expediente', x = -410.0, y = 1180.0, z = 325.6, prop = 'prop_cs_documents_01' },
            En(BUZON_MISSION_ROW, { tipo = 'dejar', texto = 'Échalos al buzón de Mission Row, a nombre de Bastida' }),
        },
    },
    {
        id = 'cerrar_expediente', nivel = 4, tiempo = 50, pago = 13000,
        titulo = 'Cerrar el expediente',
        resumen = 'Ezequiel Carroña, por fin a tiro.',
        lore = {
            'Ezequiel Carroña se ha encerrado con ocho mercenarios en el rancho de Grapeseed. Es la primera vez en dos años que se le puede ver la cara, y sin él los Carroña no son nadie.',
            'Fuma en el camino entre el granero y la casa mientras los mercenarios patrullan, y tienen más esperando a una llamada. Si dan la alarma, Ezequiel sale en su Baller blindado y no vuelve a asomar. Entra sin ruido. Cuando esto acabe no quedará nadie que pueda señalar a Bastida. Ni a ti.',
        },
        pasos = {
            { tipo = 'asesinar', texto = 'Elimina a Ezequiel Carroña en el rancho', x = 2441.0, y = 4995.0, z = 45.2, sigilo = 0.6,
              objetivo = { modelo = 'g_m_m_armlieut_01', nombre = 'Ezequiel Carroña', vida = 500, blindaje = 100, arma = 'WEAPON_ASSAULTRIFLE', escena = 'WORLD_HUMAN_SMOKING', h = 90.0 },
              escoltas = Con(Mercs, { n = 8, radio = 15.0 }),
              huida = { vehiculo = 'baller5', lejos = 600.0 },
              refuerzos = Con(Mercs, { n = 4, vehiculo = 'mesa3' }) },
            { tipo = 'alejarse', texto = 'Sal del rancho antes de que llegue nadie', x = 2441.0, y = 4995.0, z = 45.2, radio = 400.0 },
        },
    },
}

-- Topes de seguridad (no tocar salvo que se sepa por que).
Config.Topes = {
    --- Lo que puede estar el jugador del sitio al decir que lo ha hecho.
    holgura = 4.0,
    --- Distancia de los enemigos/coche al sitio del paso cuando se apuntan.
    apuntar = 60.0,
}

--[[ ── La foto que verifica la muerte ────────────────────────────────────
     Bastida no se fia de palabras: detras de cada asesinato (asesinar o
     interceptar) va un paso `foto` para fotografiar el cuerpo con la camara
     de la policia (instant_camera). Se añade aqui solo, en todos los
     trabajos; `sinFoto = true` en el paso para no pedirla. ]]
Config.Camara = 'instant_camera'
--- Lo que el trabajo da al aceptarlo (a todos los del grupo) y quita al acabar.
Config.EquipoSiempre = { Config.Camara }

local function Asesinato(p)
    if p.tipo == 'asesinar' or p.tipo == 'interceptar' then return p end
    if p.tipo == 'doble' then
        for _, pp in pairs(p.partes) do
            if pp.tipo == 'asesinar' or pp.tipo == 'interceptar' then return pp end
        end
    end
end

for _, m in ipairs(Config.Misiones) do
    local pasos = {}
    for _, p in ipairs(m.pasos) do
        pasos[#pasos + 1] = p
        local a = Asesinato(p)
        if a and not a.sinFoto then
            local nombre = a.objetivo and a.objetivo.nombre or 'el objetivo'
            -- «de El Gallego» -> «del Gallego»
            local de = nombre:match('^[Ee]l (.+)$') and ('del ' .. nombre:match('^[Ee]l (.+)$')) or ('de ' .. nombre)
            pasos[#pasos + 1] = {
                tipo = 'foto', cuerpo = true, x = a.x, y = a.y, z = a.z,
                texto = ('Hazle una foto al cuerpo %s con la cámara, para Bastida'):format(de),
            }
        end
    end
    m.pasos = pasos
end
