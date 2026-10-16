--[[ ══ Origen Visuals ════════════════════════════════════════════════════════

     El aspecto del juego en el servidor: imagen con mas contraste, aire mas
     limpio, sombras y detalle (arboles incluidos) hasta mas lejos, nubes con
     volumen, y de noche menos luz ambiente con farolas que alumbran mas y
     dejan ver su cono de luz. Los valores estan en config.lua.

     Son tres mecanismos, y ninguno sustituye ficheros del juego:

       1. visualsettings: SetVisualSettingFloat sobre las claves de
          visualsettings.dat. Se guarda el valor que habia para devolverlo.

       2. timecycle: un modificador propio, creado en marcha, puesto en el
          hueco "extra". El hueco normal lo usan las camaras, las drogas y el
          gas pimienta, y lo limpian al acabar; el extra solo lo usa
          origen_gangwars dentro de una zona. Si otro script pone el suyo, se
          le deja; cuando lo quita, vuelve el nuestro.

       3. nubes: se eligen las capas de nubes del juego que tienen volumen
          (LoadCloudHat) en vez de dejarlo al azar.

     /visuals lo apaga y lo enciende para quien lo escribe (se guarda con KVP).
     Es todo del cliente. ]]

-- De serie van los graficos del juego: quien quiera los de Origen los enciende en el
-- panel y se le queda guardado en su maquina.
local CLAVE = 'origen_visuals:encendido'
local MOD = 'origen_visuals'
local CADA = 2000 -- ms entre repasos del timecycle; el reloj del juego va lento

local activo = GetResourceKvpInt(CLAVE) == 1
local originales = {} -- visualsettings: clave -> valor que habia
local puestas = {}    -- timecycle: variable -> valor puesto ahora

--[[ Los gustos de cada jugador (panel «Origen Gráficos»). Se guardan con KVP en su
     maquina. Cada uno elige un nivel por apartado; lo que significa cada nivel esta
     en Config.Opciones. ]]
local CLAVE_GUSTOS = 'origen_visuals:gustos'
local Gustos = {}

--- Entre que valores se mueve la barra de un apartado, o nil si no lleva barra (los de
--- si/no, los fijos y los que manda otro recurso). Lo guardado es el id de un nivel o,
--- si se ajusto con la barra, el numero tal cual.
local function Rango(o)
    if o.externo or o.sinBarra or #o.niveles < 2 then return end
    local min, max
    for _, n in ipairs(o.niveles) do
        if type(n.v) ~= 'number' then return end
        min, max = math.min(min or n.v, n.v), math.max(max or n.v, n.v)
    end
    return min, max
end

local function CargarGustos()
    local ok, t = pcall(json.decode, GetResourceKvpString(CLAVE_GUSTOS) or '')
    Gustos = (ok and type(t) == 'table') and t or {}
    for _, o in ipairs(Config.Opciones) do
        local vale = false
        for _, n in ipairs(o.niveles) do if n.id == Gustos[o.id] then vale = true end end
        if type(Gustos[o.id]) == 'number' then
            local min, max = Rango(o)
            vale = min ~= nil and Gustos[o.id] >= min and Gustos[o.id] <= max
        end
        if not vale then Gustos[o.id] = o.defecto end
    end
end
CargarGustos()

--- El valor que lleva el nivel elegido de un apartado.
local function Nivel(id)
    if type(Gustos[id]) == 'number' then return Gustos[id] end
    for _, o in ipairs(Config.Opciones) do
        if o.id == id then
            for _, n in ipairs(o.niveles) do if n.id == Gustos[id] then return n.v end end
        end
    end
end

--- Para texturas.lua: 0 = las del juego, 1 = las del servidor, 2 = tambien las de cerca.
function OVCalidadTexturas(grupo)
    if not activo or not Config.TexturasEnCaliente then return 0 end
    if grupo == 'coches' then return Nivel('texcoches') and 2 or 0 end
    return Nivel('texturas') or 0
end

--- Cuanto quiere el jugador de algo: 0 = como el juego, 1 = como Origen, mas = mas fuerte.
--- `campo` es 'tc' (variables de timecycle) o 'vs' (claves de visualsettings); cada
--- apartado de Config.Opciones dice que trozos de nombre gobierna. Lo que no gobierna
--- nadie va siempre a 1.
local function Cuanto(campo, nombre)
    for _, o in ipairs(Config.Opciones) do
        for _, trozo in ipairs(o[campo] or {}) do
            if nombre:find(trozo, 1, true) then
                local v = Nivel(o.id)
                if v == true then return 1.0 elseif v == false or v == nil then return 0.0 end
                return v
            end
        end
    end
    return 1.0
end

local function Avisar(texto)
    if GetResourceState('origen_notify') == 'started' then
        exports.origen_notify:Notify(texto, 'info')
    else
        TriggerEvent('chat:addMessage', { args = { 'Visuals', texto } })
    end
end

local function Mezcla(a, b, t) return a + (b - a) * t end

-- ── visualsettings ──────────────────────────────────────────────────────────

local function PonerAjustes()
    for clave, valor in pairs(Config.Ajustes) do
        if originales[clave] == nil then originales[clave] = GetVisualSettingFloat(clave) end
        -- cada valor se gradua entre el del juego y el de Origen, segun el gusto del jugador
        SetVisualSettingFloat(clave, Mezcla(originales[clave], valor, Cuanto('vs', clave)) + 0.0)
    end
end

local function QuitarAjustes()
    for clave, valor in pairs(originales) do
        SetVisualSettingFloat(clave, valor + 0.0)
    end
    originales = {}
end

-- ── timecycle ───────────────────────────────────────────────────────────────

local climaPorHash = {}
for nombre in pairs(Base.climas) do climaPorHash[joaat(nombre)] = nombre end

local function Rampa(h, tramo)
    local t = (h - tramo[1]) / (tramo[2] - tramo[1])
    return t < 0.0 and 0.0 or t > 1.0 and 1.0 or t
end

--- De 0 (dia) a 1 (noche cerrada).
local function Noche(h)
    if h >= 12.0 then return Rampa(h, Config.Noche.anochece) end
    return 1.0 - Rampa(h, Config.Noche.amanece)
end

--- Lo que pone el juego en una variable a esa hora, con ese clima.
local function ValorBase(clima, var, h)
    local muestras = Base.climas[clima] and Base.climas[clima][var]
    if not muestras then return nil end
    local horas = Base.horas
    for i = #horas, 1, -1 do
        if h >= horas[i] then
            -- tras la ultima muestra se vuelve a la primera, a las 24
            local sigHora = horas[i + 1] or 24
            local sig = muestras[i + 1] or muestras[1]
            return Mezcla(muestras[i], sig, (h - horas[i]) / (sigHora - horas[i]))
        end
    end
    return muestras[1]
end

local function Factor(porClima, clima)
    return porClima[clima] or porClima.todos or 1.0
end

-- ── ambiente por lugar y hora ───────────────────────────────────────────────

--[[ El juego pinta el mismo aire en Paleto que en el centro. Aqui cada "ambiente" de
     Config.Ambientes entra solo en sus zonas, a sus horas y con su clima: bruma al
     amanecer en el campo, calima en el desierto a mediodia. Entra y sale poco a poco
     (un paso por repaso) para que al cruzar de zona no se note el corte. ]]

local pesoAmbiente = {}
local zonasDe = {}
for _, a in ipairs(Config.Ambientes) do
    pesoAmbiente[a.id] = 0.0
    zonasDe[a.id] = {}
    for _, z in ipairs(a.zonas) do zonasDe[a.id][z] = true end
end

--- De 0 a 1 segun la hora: sube entre horas[1] y horas[2], se mantiene, baja entre [3] y [4].
local function Franja(h, horas)
    if h <= horas[1] or h >= horas[4] then return 0.0 end
    if h < horas[2] then return (h - horas[1]) / (horas[2] - horas[1]) end
    if h > horas[3] then return (horas[4] - h) / (horas[4] - horas[3]) end
    return 1.0
end

function Ambientes(d, c1, c2, paso, h)
    local activo = Nivel('ambiente')
    local pos = GetEntityCoords(PlayerPedId())
    local zona = GetNameOfZone(pos.x, pos.y, pos.z)
    for _, a in ipairs(Config.Ambientes) do
        local quiero = 0.0
        if activo and zonasDe[a.id][zona] and a.climas[c1] and a.climas[c2] then quiero = Franja(h, a.horas) end
        -- hacia donde toca, un paso de 0.08 por repaso: unos 25 segundos de cero a todo
        local peso = pesoAmbiente[a.id]
        peso = peso + math.max(-0.08, math.min(0.08, quiero - peso))
        pesoAmbiente[a.id] = peso

        if peso > 0.001 then
            for var, regla in pairs(a.vars) do
                local actual = d[var]
                if actual == nil then
                    local b1, b2 = ValorBase(c1, var, h), ValorBase(c2, var, h)
                    actual = b1 and b2 and Mezcla(b1, b2, paso) or nil
                end
                if regla.por and actual then
                    d[var] = actual * Mezcla(1.0, regla.por, peso)
                elseif regla.vale then
                    d[var] = Mezcla(actual or 0.0, regla.vale, peso)
                end
            end
        end
    end
end

-- ── viento ──────────────────────────────────────────────────────────────────

--[[ El servidor manda viento cero, y con viento cero los arboles, la hierba y la ropa
     tendida no se mueven. Aqui se pone un viento acorde al clima. ]]
local vientoPuesto

local function PonerViento(c1, c2, paso)
    if not Nivel('viento') then
        if vientoPuesto then SetWind(0.0) vientoPuesto = nil end
        return
    end
    local v1, v2 = Config.Viento[c1 or ''] or Config.Viento.otro, Config.Viento[c2 or ''] or Config.Viento.otro
    local v = Mezcla(v1, v2, paso)
    if not vientoPuesto or math.abs(vientoPuesto - v) > 0.01 then
        SetWind(v + 0.0)
        vientoPuesto = v
    end
end

local function Deseadas()
    local h = GetClockHours() + GetClockMinutes() / 60.0
    local noche = Noche(h)
    local d = {}
    for var, valor in pairs(Config.Fijas) do
        local cuanto = Cuanto('tc', var)
        -- a cero no se pone: la variable se queda como la tenga el juego
        if cuanto > 0.0 then
            d[var] = var:find('vignetting', 1, true) and valor or Mezcla(1.0, valor, cuanto)
        end
    end

    local hash1, hash2, paso = GetWeatherTypeTransition()
    local c1, c2 = climaPorHash[hash1], climaPorHash[hash2]

    --[[ Con lluvia, tormenta o niebla el juego ya pone su propia noche: farolas con el cono
         bien visible y un cielo que da algo de luz. Pisarla con la nuestra, pensada para
         noches despejadas, la dejaba mas plana y mas negra que sin el mod (11/10, con foto).
         Ahi solo se tocan el alcance y el destello de las luces. ]]
    PonerViento(c1, c2, paso)
    local despejado = Config.Noche.despejado[c1 or ''] and Config.Noche.despejado[c2 or '']
    for var, v in pairs(Config.Noche.vars) do
        if despejado or not (var:find('^fog') or var == 'natural_ambient_multiplier') then
            d[var] = Mezcla(v[1], Mezcla(v[1], v[2], Cuanto('tc', var)), noche)
        end
    end

    -- Los interiores traen su propio timecycle y este lo pisaria.
    if GetInteriorFromEntity(PlayerPedId()) ~= 0 then return d end

    if not c1 or not c2 then return d end

    -- De noche, hacia un valor fijo partiendo de lo que ponga el juego a esa hora.
    for var, destino in pairs(Config.Noche.hacia) do
        local b1, b2 = ValorBase(c1, var, h), ValorBase(c2, var, h)
        local neon = Cuanto('tc', var)
        if b1 and b2 and noche > 0.0 and neon > 0.0 and despejado then
            local base = Mezcla(b1, b2, paso)
            d[var] = Mezcla(base, Mezcla(base, destino, neon), noche)
        end
    end

    -- La luz de las personas, de noche: con cualquier clima, que con lluvia tambien hace falta.
    for var, destino in pairs(Config.Personaje) do
        local b1, b2 = ValorBase(c1, var, h), ValorBase(c2, var, h)
        local cuanto = Cuanto('tc', var)
        if b1 and b2 and noche > 0.0 and cuanto > 0.0 then
            local base = Mezcla(b1, b2, paso)
            d[var] = Mezcla(base, Mezcla(base, destino, cuanto), noche)
        end
    end

    for var, porClima in pairs(Config.Proporcion) do
        local f1, f2 = Factor(porClima, c1), Factor(porClima, c2)
        -- cuanto de cada cambio quiere el jugador: 0 = como el juego, 1 = como Origen
        local cuanto = Cuanto('tc', var)
        f1, f2 = Mezcla(1.0, f1, cuanto), Mezcla(1.0, f2, cuanto)
        local b1, b2 = ValorBase(c1, var, h), ValorBase(c2, var, h)
        if b1 and b2 and (f1 ~= 1.0 or f2 ~= 1.0) then
            d[var] = Mezcla(b1 * f1, b2 * f2, paso)
        end
    end

    -- La lente: efectos de camara que el jugador enciende si quiere.
    for id, vars in pairs(Config.Lente) do
        if Nivel(id) then
            for var, valor in pairs(vars) do d[var] = valor end
        end
    end

    Ambientes(d, c1, c2, paso, h)
    return d
end

local function PonerTimecycle()
    local mio = GetTimecycleModifierIndexByName(MOD)
    if mio == -1 then
        CreateTimecycleModifier(MOD)
        mio = GetTimecycleModifierIndexByName(MOD)
        puestas = {}
    end

    local d = Deseadas()
    for var, valor in pairs(d) do
        local antes = puestas[var]
        if not antes or math.abs(antes - valor) > 0.002 * math.max(1.0, math.abs(valor)) then
            SetTimecycleModifierVar(MOD, var, valor + 0.0, valor + 0.0)
            puestas[var] = valor
        end
    end
    for var in pairs(puestas) do
        if d[var] == nil then
            RemoveTimecycleModifierVar(MOD, var)
            puestas[var] = nil
        end
    end

    -- Solo se coge el hueco si esta libre: el de otro script se respeta.
    if GetExtraTimecycleModifierIndex() == -1 then SetExtraTimecycleModifier(MOD) end
end

local function QuitarTimecycle()
    local mio = GetTimecycleModifierIndexByName(MOD)
    if mio == -1 then return end
    if GetExtraTimecycleModifierIndex() == mio then ClearExtraTimecycleModifier() end
    RemoveTimecycleModifier(MOD)
    puestas = {}
end

-- ── nubes ───────────────────────────────────────────────────────────────────

--[[ El juego elige al azar una "capa de nubes" (cloud hat) por clima, y casi
     siempre cae en las planas. Aqui se elige entre las que tienen volumen.
     La eleccion sale del clima y de la hora del juego, no del azar: todos los
     jugadores ven las mismas nubes. ]]

local nubePuesta, climaNubes

--- UnloadCloudHat salta con una excepcion dentro del native cuando la capa ya no esta
--- cargada (el juego la cambia por su cuenta con el clima), y ni con pcall deja de
--- ensuciar la consola. Se quitan todas con ClearCloudHat, que no falla nunca.
local function Descargar()
    ClearCloudHat()
end

local function QuitarNubes()
    if nubePuesta then Descargar() end
    nubePuesta, climaNubes = nil, nil
end

local function PonerNubes()
    local hash1, hash2, paso = GetWeatherTypeTransition()
    local clima = climaPorHash[paso > 0.5 and hash2 or hash1]
    local lista = clima and Config.Nubes[clima]
    if not lista or not Nivel('nubes') then return QuitarNubes() end

    local bloque = (GetClockDayOfMonth() * 24 + GetClockHours()) // Config.Nubes.horasPorCapa
    local quiero = lista[bloque % #lista + 1]
    if quiero == nubePuesta then return end

    if clima ~= climaNubes then
        -- Al cambiar de clima el juego ha puesto la suya: fuera todas. Eso
        -- ya es un corte, asi que la nueva entra rapido.
        ClearCloudHat()
        LoadCloudHat(quiero, 3.0)
    else
        if nubePuesta then Descargar() end
        LoadCloudHat(quiero, Config.Nubes.fundido)
    end
    nubePuesta, climaNubes = quiero, clima
end

-- ── lluvia ──────────────────────────────────────────────────────────────────

--[[ Lo que la lluvia hace y el juego no hace solo:
       - charcos: con el nivel de lluvia por encima de 0.5 no llueve mas, pero los charcos
         se forman antes (asi lo documenta el native). El suelo llega a espejo en un par
         de minutos en vez de en diez.
       - ropa: quien esta a la intemperie se va empapando de los pies a la cabeza, y se
         seca poco a poco a cubierto.
       - coches: la lluvia les quita el polvo; un coche limpio brilla y refleja mas.
     Todo es del cliente y solo mientras llueve. ]]

local LLUVIOSOS = { RAIN = true, THUNDER = true, CLEARING = true }
local lluviaPuesta = false
local mojado = 0.0      -- metros de ropa mojada, desde los pies

local function Llueve()
    local hash1, hash2, paso = GetWeatherTypeTransition()
    local c1, c2 = climaPorHash[hash1], climaPorHash[hash2]
    if LLUVIOSOS[c1 or ''] and LLUVIOSOS[c2 or ''] then return true end
    return LLUVIOSOS[c2 or ''] and paso > 0.7 or false
end

local function ALaIntemperie(ped)
    if GetInteriorFromEntity(ped) ~= 0 then return false end
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return true end
    local clase = GetVehicleClass(veh)
    return clase == 8 or clase == 13     -- motos y bicis
end

CreateThread(function()
    while true do
        local llueve = activo and Nivel('lluvia') and Llueve()
        local ped = PlayerPedId()

        -- Se repone si alguien lo ha quitado: el script del clima lo devuelve a -1 en cada cambio.
        if llueve and (not lluviaPuesta or GetRainLevel() < Config.Lluvia.charcos - 0.05) then
            SetRainLevel(Config.Lluvia.charcos + 0.0)
            lluviaPuesta = true
        elseif not llueve and lluviaPuesta then
            SetRainLevel(-1.0)
            lluviaPuesta = false
        end

        if llueve and ALaIntemperie(ped) then
            mojado = math.min(Config.Lluvia.alturaRopa, mojado + Config.Lluvia.alturaRopa / Config.Lluvia.segundosEmpapar)
        elseif mojado > 0.0 then
            mojado = math.max(0.0, mojado - Config.Lluvia.alturaRopa / Config.Lluvia.segundosSecar)
        end

        if llueve then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                local polvo = GetVehicleDirtLevel(veh)
                if polvo > 0.0 then SetVehicleDirtLevel(veh, math.max(0.0, polvo - 15.0 / Config.Lluvia.segundosLavar)) end
            end
        end
        Wait(1000)
    end
end)

-- La ropa mojada hay que pedirla cada fotograma; el hilo duerme mientras este seca.
CreateThread(function()
    while true do
        if mojado > 0.02 then
            local ped = PlayerPedId()
            SetPedWetnessEnabledThisFrame(ped)
            SetPedWetnessHeight(ped, mojado + 0.0)
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- ── encender y apagar ───────────────────────────────────────────────────────

local function Poner(encender, avisar)
    encender = encender and true or false
    if encender ~= activo then
        activo = encender
        SetResourceKvpInt(CLAVE, activo and 1 or 0)
        if activo then
            PonerAjustes()
            PonerTimecycle()
        else
            QuitarAjustes()
            QuitarTimecycle()
            QuitarNubes()
            if vientoPuesto then SetWind(0.0) vientoPuesto = nil end
        end
    end
    if avisar then
        Avisar(activo and 'Gráficos del servidor: activados' or 'Gráficos del servidor: desactivados (los del juego)')
    end
end

CreateThread(function()
    if activo then PonerAjustes() end
    while true do
        if activo then
            PonerTimecycle()
            PonerNubes()
        end
        Wait(CADA)
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    QuitarAjustes()
    QuitarTimecycle()
    QuitarNubes()
    if vientoPuesto then SetWind(0.0) end
    if lluviaPuesta then SetRainLevel(-1.0) end
    if panel then SetNuiFocus(false, false) end
end)

-- ── el panel «Origen Gráficos» ──────────────────────────────────────────────

local panel = false

--- El modo rendimiento es de origen_hud (/fpson, /fpsoff): aqui solo se le pregunta y se le manda.
local function ModoFps()
    if GetResourceState('origen_hud') ~= 'started' then return nil end
    local ok, modo = pcall(function() return exports.origen_hud:ModoRendimiento() end)
    return ok and (modo or 'no') or nil
end

local function Estado()
    local ops = {}
    local fps = ModoFps()
    for _, o in ipairs(Config.Opciones) do
        if o.externo == 'fps' then Gustos[o.id] = fps or 'no' end
        local niveles = {}
        for _, n in ipairs(o.niveles) do niveles[#niveles + 1] = { id = n.id, nombre = n.nombre } end
        if o.externo ~= 'fps' or fps then
            local min, max = Rango(o)
            ops[#ops + 1] = {
                id = o.id, grupo = o.grupo, nombre = o.nombre, ayuda = o.ayuda, niveles = niveles, defecto = o.defecto,
                elegido = type(Gustos[o.id]) == 'string' and Gustos[o.id] or '',
                barra = min and { min = min, max = max } or nil, valor = min and Nivel(o.id) or nil,
            }
        end
    end
    local estilos = {}
    for _, e in ipairs(Config.Estilos) do
        local puesto = true
        for _, o in ipairs(Config.Opciones) do
            if not o.externo and Gustos[o.id] ~= (e.gustos[o.id] or o.defecto) then puesto = false end
        end
        estilos[#estilos + 1] = { id = e.id, nombre = e.nombre, puesto = puesto }
    end
    return { activo = activo, opciones = ops, estilos = estilos }
end

--- Aplica ya lo elegido, sin esperar al repaso de cada dos segundos.
local function Aplicar()
    if not activo then return end
    PonerAjustes()
    PonerTimecycle()
    PonerNubes()
end

local function AbrirPanel()
    if panel then return end
    panel = true
    SetNuiFocus(true, true)
    SendNUIMessage({ accion = 'abrir', datos = Estado() })
end

local function CerrarPanel()
    if not panel then return end
    panel = false
    SetNuiFocus(false, false)             -- primero, siempre
    SetTimeout(280, function() SendNUIMessage({ accion = 'cerrar' }) end)
end

RegisterNUICallback('cerrar', function(_, cb) CerrarPanel() cb({ ok = true }) end)

RegisterNUICallback('elegir', function(datos, cb)
    for _, o in ipairs(Config.Opciones) do
        local min, max = Rango(o)
        if o.id == datos.id and type(datos.valor) == 'number' and min then
            -- con la barra: si cae justo en un nivel se guarda el nivel, y si no, el numero
            local v = math.max(min, math.min(max, datos.valor + 0.0))
            Gustos[o.id] = v
            for _, n in ipairs(o.niveles) do if math.abs(n.v - v) < 0.001 then Gustos[o.id] = n.id end end
            SetResourceKvp(CLAVE_GUSTOS, json.encode(Gustos))
            Aplicar()
        elseif o.id == datos.id then
            for _, n in ipairs(o.niveles) do
                if n.id == datos.nivel then
                    if o.externo == 'fps' then
                        pcall(function() exports.origen_hud:PonerModoRendimiento(n.v or nil) end)
                    else
                        Gustos[o.id] = n.id
                        SetResourceKvp(CLAVE_GUSTOS, json.encode(Gustos))
                        Aplicar()
                    end
                end
            end
        end
    end
    cb(Estado())
end)

RegisterNUICallback('encender', function(datos, cb)
    Poner(datos.activo == true, false)
    cb(Estado())
end)

RegisterNUICallback('estilo', function(datos, cb)
    for _, e in ipairs(Config.Estilos) do
        if e.id == datos.id then
            for _, o in ipairs(Config.Opciones) do
                if not o.externo then Gustos[o.id] = e.gustos[o.id] or o.defecto end
            end
            SetResourceKvp(CLAVE_GUSTOS, json.encode(Gustos))
            Poner(true, false)
            Aplicar()
        end
    end
    cb(Estado())
end)

RegisterNUICallback('restablecer', function(_, cb)
    for _, o in ipairs(Config.Opciones) do Gustos[o.id] = o.defecto end
    SetResourceKvp(CLAVE_GUSTOS, json.encode(Gustos))
    pcall(function() exports.origen_hud:PonerModoRendimiento(nil) end)
    Poner(true, false)
    Aplicar()
    cb(Estado())
end)

exports('Abrir', AbrirPanel)
exports('EstaAbierto', function() return panel end)
RegisterCommand('graficos', AbrirPanel, false)
TriggerEvent('chat:addSuggestion', '/graficos', 'Abre Origen Gráficos: ajusta a tu gusto el aspecto del juego')

RegisterCommand('visuals', function() Poner(not activo, true) end, false)
TriggerEvent('chat:addSuggestion', '/visuals', 'Activa o desactiva los gráficos del servidor (luces, noche, niebla y contraste)')

exports('Activo', function() return activo end)
exports('Poner', function(encender) Poner(encender, false) end)
