--[[ ═══════════════════════════════════════════════════════════════════════
     LOS EXÁMENES PRÁCTICOS

     Cada examen es una lista de ETAPAS que el examinador va cantando. El
     cliente las vigila (client/practico.lua) y avisa al servidor al cumplir
     cada una; el servidor comprueba con SU posición del vehículo que de
     verdad se ha hecho (server/practico.lua).

     Tipos de etapa:

       preparar     sentarse al volante, cinturón (`cinturon = true`) y
                    arrancar
       punto        llegar al punto del recorrido (`pos`, `radio`), con su
                    `limite` de velocidad y su `giro` —izquierda, derecha o
                    recto—, que se saca de la geometría de la ruta. Con
                    `stop = true` hay que detenerse del todo antes
       emergencia   el examinador grita y hay que parar del todo en `seg`
       aparcar      meter el coche marcha atrás en la plaza marcada
       fin          apagar el motor con el vehículo dentro de la plaza

     Los recorridos salen de config/ruta.lua, que se generan en el juego
     pegando los puntos a la calzada. Hay VARIOS y el servidor elige uno al
     azar en cada examen: con uno solo, a la semana se lo saben de memoria.
     La moto hace la parte corta y el camión va más despacio.

     Mientras vigila, el cliente mira continuamente lo que no es una etapa
     pero suspende igual: velocidad, cinturón, golpes, atropellos, salirse de
     la calzada, ir en dirección contraria y los intermitentes de cada giro.
   ═══════════════════════════════════════════════════════════════════════ ]]

Config.Examenes = {}

local RADIO = 14.0

--[[ Arma las etapas de un examen a partir de la ruta. `hasta` recorta el
     recorrido (la moto no hace el entero), `limite` lo baja (el camión) y
     `emergenciaEn` dice en qué punto llega el frenazo. ]]
local function Circuito(o)
    local etapas = {
        { tipo = 'preparar', cinturon = o.cinturon,
          texto = o.hola },
    }
    local ruta = o.ruta or {}
    local n = math.min(#ruta, o.hasta or #ruta)
    for i = 1, n do
        local p = ruta[i]
        local pos = p.pos
        if type(pos) == 'table' and not getmetatable(pos) then
            pos = vec3(tonumber(pos.x or pos[1]) + 0.0, tonumber(pos.y or pos[2]) + 0.0, tonumber(pos.z or pos[3]) + 0.0)
        end
        local antes = i > 1 and (ruta[i - 1].pos or Config.Escuela.npc.coords.xyz) or Config.Escuela.npc.coords.xyz
        if type(antes) == 'table' and not getmetatable(antes) then
            antes = vec3(tonumber(antes.x or antes[1]) + 0.0, tonumber(antes.y or antes[2]) + 0.0, tonumber(antes.z or antes[3]) + 0.0)
        end
        local despues = ruta[i + 1] and ruta[i + 1].pos
        if type(despues) == 'table' and not getmetatable(despues) then
            despues = vec3(tonumber(despues.x or despues[1]) + 0.0, tonumber(despues.y or despues[2]) + 0.0, tonumber(despues.z or despues[3]) + 0.0)
        end

        local accion = p.accion or (p.stop and 'stop') or 'normal'
        local giro = p.giro
        if not giro or giro == '' then
            if accion == 'giro_izq' then
                giro = 'izq'
            elseif accion == 'giro_der' then
                giro = 'der'
            else
                giro = Auto.Giro(antes, pos, despues)
            end
        end

        local esStop = accion == 'stop' or p.stop == true
        local radio = tonumber(p.radio) or RADIO
        local limite = math.min(tonumber(p.limite) or Config.Limite, o.limite or 999.0)

        local prefijoAccion = ''
        if esStop then
            prefijoAccion = 'STOP: párate del todo en la línea roja antes de continuar. '
        elseif accion == 'semaforo' then
            prefijoAccion = 'Semáforo o cruce concurrido: extrema la precaución y modera la velocidad. '
        end

        local textoGiro = ''
        if giro == 'izq' then
            textoGiro = 'En el cruce, gira a la izquierda (intermitente obligatorio).'
        elseif giro == 'der' then
            textoGiro = 'En el cruce, gira a la derecha (intermitente obligatorio).'
        else
            textoGiro = 'Sigue recto hasta el siguiente punto.'
        end

        etapas[#etapas + 1] = {
            tipo = 'punto',
            pos = pos,
            radio = radio,
            limite = limite,
            giro = giro,
            stop = esStop,
            accion = accion,
            indice = i,
            de = n,
            texto = prefijoAccion .. textoGiro .. (' Máximo %d km/h.'):format(math.floor(limite)),
        }

        if accion == 'emergencia' or o.emergenciaEn == i then
            etapas[#etapas + 1] = {
                tipo = 'emergencia', seg = 3.0, puntos = 25,
                texto = '¡FRENA! Parada de emergencia.',
                bien = 'Bien. Sigue cuando quieras.',
            }
        end
    end

    etapas[#etapas + 1] = {
        tipo = 'aparcar', seg = 2.0, puntos = 20, marchaAtras = o.marchaAtras ~= false,
        plaza = o.plaza,
        texto = o.marchaAtras ~= false
            and 'Volvemos a la autoescuela: mete el vehículo en la plaza marcha atrás, entre las líneas.'
            or 'Volvemos a la autoescuela: déjalo dentro de la plaza marcada.',
    }
    etapas[#etapas + 1] = { tipo = 'fin', plaza = o.plaza, texto = 'Apaga el motor y hemos terminado.' }
    return etapas
end

Auto.Circuito = Circuito

Config.Examenes.coche = {
    nombre = 'Práctico · Coche',
    aparato = 'Coche de autoescuela',
    modelo = 'asea',
    tipo = 'automobile',
    -- Lo que mide el vehículo de largo (medido en el juego con
    -- GetModelDimensions, prueba/vehiculos.lua). Es el sitio que hay que
    -- dejarle libre en la plaza de salida.
    largo = 4.5,
    salidas = Config.Escuela.salidas,
    nivel = 1,
    precio = 2000,
    tiempo = 20 * 60,
    cinturon = true,
    variantes = {},   -- una tanda de etapas por recorrido (se arma abajo)
}

Config.Examenes.moto = {
    nombre = 'Práctico · Moto',
    aparato = 'Motocicleta',
    modelo = 'faggio2',
    tipo = 'bike',
    largo = 1.9,
    salidas = Config.Escuela.salidas,
    nivel = 2,
    precio = 2000,
    tiempo = 14 * 60,
    cinturon = false,
    variantes = {},
}

Config.Examenes.camion = {
    nombre = 'Práctico · Camión',
    aparato = 'Camión',
    modelo = 'mule',
    tipo = 'automobile',
    largo = 8.1,
    salidas = Config.Escuela.salidas,
    nivel = 3,
    precio = 3000,
    tiempo = 22 * 60,
    cinturon = true,
    variantes = {},
}

-- En Nación, todos los exámenes teóricos y prácticos cuestan $500.
if GetConvar('origen:marca', 'origen') == 'nacion' then
    for _, nivel in ipairs(Config.Niveles) do
        nivel.precioTeorico = 500
    end
    for _, examen in pairs(Config.Examenes) do
        examen.precio = 500
    end
end

Config.RutaDeOriginal = {}
if Config.RutaDe then
    for k, v in pairs(Config.RutaDe) do
        Config.RutaDeOriginal[k] = v
    end
end

--- Arma el examen para un carnet específico usando los recorridos por defecto del config
function Auto.ArmarCarnetDefault(carnet, force)
    -- Si no se fuerza y ya hay rutas configuradas en BD para este carnet, PREVALECEN las de BD
    if not force and ((Rutas and Rutas.Activas and Rutas.Activas[carnet] and #Rutas.Activas[carnet] > 0) or (Auto.RutasActivas and Auto.RutasActivas[carnet] and #Auto.RutasActivas[carnet] > 0)) then
        return
    end

    local ex = Config.Examenes[carnet]
    if not ex then return end
    ex.id = carnet
    ex.variantes = {}

    for id, ruta in pairs(Config.Rutas or {}) do
        if carnet == 'coche' then
            ex.variantes[id] = Circuito({
                ruta = ruta, cinturon = true,
                emergenciaEn = math.max(1, math.floor(#ruta * 0.6)),
                hola = 'Buenas, {nombre}. Soy tu examinador. Cinturón, espejos y arranca cuando estés. Si tienes que dejarlo, pulsa F9 y lo cancelamos.',
            })
        elseif carnet == 'moto' then
            ex.variantes[id] = Circuito({
                ruta = ruta, cinturon = false, hasta = math.max(1, math.floor(#ruta * 0.6)),
                emergenciaEn = math.max(1, math.floor(#ruta * 0.35)), marchaAtras = false,
                hola = '{nombre}, en moto se mira dos veces antes de cada cambio. Arranca cuando quieras. Si tienes que dejarlo, pulsa F9.',
            })
        elseif carnet == 'camion' then
            if not (Config.RutasSinCamion or {})[id] then
                ex.variantes[id] = Circuito({
                    ruta = ruta, cinturon = true, limite = 40.0,
                    emergenciaEn = math.max(1, math.floor(#ruta * 0.5)),
                    hola = '{nombre}, esto pesa diez veces más que un coche: anticipa y abre los giros. Si tienes que dejarlo, pulsa F9.',
                })
            end
        end
    end

    ex.recorridos = {}
    local fijo = (Config.RutaDeOriginal or {})[carnet] or (Config.RutaDe or {})[carnet]
    if fijo and ex.variantes[fijo] then
        ex.recorridos[1] = fijo
        if Config.RutaDe then Config.RutaDe[carnet] = fijo end
    else
        for v in pairs(ex.variantes) do ex.recorridos[#ex.recorridos + 1] = v end
        table.sort(ex.recorridos)
    end
    ex.etapas = ex.recorridos[1] and ex.variantes[ex.recorridos[1]] or {}
end

--[[ Se arma al cargar: una tanda de etapas por CADA recorrido, para que el
     servidor pueda elegir uno al azar en cada examen. Si todavía no se ha
     generado ninguno en el juego, los exámenes se quedan sin variantes y el
     servidor no deja empezarlos (y el panel lo dice). ]]
function Auto.ArmarExamenes()
    Auto.Variantes = {}
    for id in pairs(Config.Rutas or {}) do
        Auto.Variantes[#Auto.Variantes + 1] = id
    end
    table.sort(Auto.Variantes)

    for id in pairs(Config.Examenes) do
        Auto.ArmarCarnetDefault(id)
    end
end

--- Las etapas de una variante (o las de muestra si esa no existe).
function Auto.Etapas(ex, variante)
    if type(ex) == 'string' then ex = Config.Examenes[ex] end
    if not ex then return nil end
    return (variante and ex.variantes[variante]) or ex.etapas
end

Auto.ArmarExamenes()

--- En qué orden salen en la pantalla.
Config.OrdenExamenes = { 'coche', 'moto', 'camion' }
