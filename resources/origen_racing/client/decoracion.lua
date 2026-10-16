--[[ ═══════════════════════════════════════════════════════════════════════
     LA DECORACION DE LOS CHECKPOINTS

     Lo que se pone a los dos lados de cada checkpoint: focos, conos, barreras,
     neumaticos, bengalas, humo... Cada checkpoint lleva el suyo (`deco`), se
     elige al grabar el circuito y se guarda con el. Los estilos estan en
     Config.CheckpointDelimiters.Estilos.

     Lo usan los dos sitios que pintan checkpoints —la grabacion (admin.lua) y
     la carrera (racing.lua)— para que lo que se ve grabando sea exactamente lo
     que luego se corre.

     LOS LADOS SALEN DEL RUMBO DEL COCHE al marcar el punto, no de donde cae
     el checkpoint siguiente. Antes era lo segundo: con un solo punto puesto no
     habia «siguiente» y los props salian al este y al oeste del mapa, no a
     los lados de la carretera; y en una curva cerrada quedaban cruzados.

     Un checkpoint aqui es { x, y, z, heading, radius, deco }.
   ═══════════════════════════════════════════════════════════════════════ ]]

Decoracion = {}

local cfg = Config.CheckpointDelimiters or {}
local ESTILOS = cfg.Estilos or {}

local porId = {}
for i = 1, #ESTILOS do porId[ESTILOS[i].id] = i end

--- A que distancia se encienden y se apagan las particulas. Un circuito largo
--- tiene cientos de puntos, y cientos de humos encendidos a la vez se comen el
--- cupo de particulas del juego: solo arden los que tienes cerca.
local ALCANCE_FX = 160.0

local ALIAS = cfg.Alias or {}

--- El color de una particula: { r, g, b } de 0 a 1, o 'marca' = el de la
--- marca (rosa #d81b55 en Origen, naranja de Nacion).
-- Mas claro que el de la interfaz: el humo lo oscurece mucho y de noche el
-- #d81b55 salia granate (fotos 14/10).
local COLOR_MARCA = (OrigenMarca or GetConvar('origen:marca', 'origen')) == 'nacion'
    and { 1.0, 0.68, 0.32 } or { 1.0, 0.42, 0.66 }
local function colorFx(fx)
    if fx.color == 'marca' then return COLOR_MARCA end
    return fx.color
end

--- El estilo de ese id. Uno de los de antes pasa a su equivalente (Alias); uno
--- desconocido —o ninguno— cae al primero, que es el de serie: un circuito
--- grabado antes de que esto existiera no lleva `deco`.
function Decoracion.Estilo(id)
    return ESTILOS[porId[id] or porId[ALIAS[id]] or 1]
end

function Decoracion.PorDefecto()
    return ESTILOS[1] and ESTILOS[1].id or nil
end

--- El estilo que va `paso` puestos despues (o antes) en la lista, dando la
--- vuelta al llegar al final.
function Decoracion.Siguiente(id, paso)
    local n = #ESTILOS
    if n == 0 then return id end
    local i = (porId[id] or porId[ALIAS[id]] or 1) - 1
    return ESTILOS[((i + paso) % n) + 1].id
end

--- Los dos puntos, izquierda y derecha, donde va la decoracion: en el borde
--- del radio, perpendiculares al rumbo. `extra`: metros de mas o de menos
--- (el `separar` del estilo: la carpa se aparta, el piano se arrima).
function Decoracion.Lados(cp, extra)
    -- En GTA el rumbo 0 mira al norte y crece hacia la izquierda: adelante es
    -- (-sin, cos) y la derecha, (cos, sin).
    local h = math.rad(cp.heading or 0.0)
    local dx, dy = math.cos(h), math.sin(h)
    local d = (cp.radius or 10.0) + (cfg.OffsetDistance or 0.5) + (extra or 0.0)

    return cp.x - dx * d, cp.y - dy * d, cp.x + dx * d, cp.y + dy * d
end

local function suelo(x, y, z)
    local ok, gz = GetGroundZFor_3dCoord(x, y, z + 5.0, false)
    return ok and gz or z
end

local function cargarModelo(nombre)
    local hash = GetHashKey(nombre)
    if HasModelLoaded(hash) then return hash end
    if not IsModelInCdimage(hash) then return nil end

    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 100 do
        Wait(20)
        t = t + 1
    end

    return HasModelLoaded(hash) and hash or nil
end

-- ── Las particulas ──────────────────────────────────────────────────────

local function encender(it)
    local fx = it.fx

    if not HasNamedPtfxAssetLoaded(fx.dict) then
        RequestNamedPtfxAsset(fx.dict)
        local t = 0
        while not HasNamedPtfxAssetLoaded(fx.dict) and t < 50 do
            Wait(20)
            t = t + 1
        end
        if not HasNamedPtfxAssetLoaded(fx.dict) then return end
    end

    -- Si mientras cargaba se ha quitado la decoracion, ya no se enciende: se
    -- quedaria un humo suelto que nadie tiene apuntado para apagarlo.
    if it.quitado then return end

    --[[ `repetir`: una particula que NO es de bucle —una bocanada que dura
         unos segundos— lanzada otra vez cada tantos. Hace falta porque el
         color solo se puede elegir en algunas, y varias de las que lo admiten
         son de un solo disparo. El color de estas se dice ANTES de lanzarla. ]]
    if fx.repetir then
        UseParticleFxAsset(fx.dict)
        local c = colorFx(fx)
        if c then
            SetParticleFxNonLoopedColour(c[1], c[2], c[3])
        end
        StartParticleFxNonLoopedAtCoord(fx.name, it.x, it.y, it.z, 0.0, 0.0, 0.0, it.escala or fx.scale or 1.0, false, false, false)
        it.t = GetGameTimer()
        return
    end

    UseParticleFxAsset(fx.dict)
    it.h = StartParticleFxLoopedAtCoord(fx.name, it.x, it.y, it.z, 0.0, 0.0, 0.0, it.escala or fx.scale or 1.0, false, false, false, false)

    --[[ Un 0 es que el juego NO la ha creado (cupo de particulas lleno): en
         Lua el 0 cuenta como «si», asi que se daba por encendida y no se
         volvia a intentar nunca. Era el hueco en las columnas. Se deja en nil
         y el hilo lo reintenta en la vuelta siguiente. ]]
    if not it.h or it.h == 0 then
        it.h = nil
        return
    end

    local c = colorFx(fx)
    if c then
        SetParticleFxLoopedColour(it.h, c[1], c[2], c[3], false)
    end
end

--- `yaMismo` barre tambien lo que queda en el aire. Parar el bucle solo
--- corta el chorro: el humo ya soltado tarda unos segundos en deshacerse, y al
--- salir de una carrera tiene que irse en el acto.
local function apagar(it, yaMismo)
    -- Las de bocanada no tienen nada que parar: se barre lo que haya.
    if it.t then
        it.t = nil
        RemoveParticleFxInRange(it.x, it.y, it.z, 12.0)
    end

    if it.h then
        StopParticleFxLooped(it.h, false)
        RemoveParticleFx(it.h, false)
        it.h = nil
        if yaMismo then
            RemoveParticleFxInRange(it.x, it.y, it.z, 12.0)
        end
    end
end

--- Las listas que tienen alguna particula, y el hilo que las enciende y las
--- apaga segun lo cerca que estes. Uno solo para todas, y se para solo.
local conFx = {}
local hiloFx = false

local function vigilar(lista)
    conFx[lista] = true
    if hiloFx then return end
    hiloFx = true

    CreateThread(function()
        while next(conFx) do
            local yo = GetEntityCoords(PlayerPedId())

            for l in pairs(conFx) do
                for i = 1, #l do
                    local it = l[i]
                    if it.fx then
                        local cerca = #(yo - vector3(it.x, it.y, it.z)) < ALCANCE_FX
                        if it.fx.repetir then
                            -- Bocanadas: otra cuando toca, mientras estes cerca.
                            if cerca and (not it.t or GetGameTimer() - it.t >= it.fx.repetir * 1000) then
                                encender(it)
                            elseif not cerca and it.t then
                                it.t = nil
                            end
                        elseif cerca and it.h and not DoesParticleFxLoopedExist(it.h) then
                            -- El juego la ha retirado por su cuenta (pasa al
                            -- alejarse y volver): se olvida y se vuelve a poner.
                            it.h = nil
                        elseif cerca and not it.h then
                            encender(it)
                        elseif not cerca and it.h then
                            apagar(it)
                        end
                    end
                end
            end

            Wait(750)
        end

        hiloFx = false
    end)
end

-- ── Los props propios (Config.PropsCarrera) ─────────────────────────────

local PACKS = Config.PropsCarrera or {}
local NACION = (OrigenMarca or GetConvar('origen:marca', 'origen')) == 'nacion'

--- La variante de un pack: el color de la marca o, ya pasado, el verde.
local function variante(pack, pasado)
    if pack.marca then
        if NACION then return pasado and 'n_verde' or 'n_naranja' end
        return pasado and 'o_verde' or 'o_rosa'
    end
    if pasado then return 'verde' end
    return NACION and 'naranja' or 'rosa'
end

--- Las partes de un lado: { { modelo, desplazamiento|nil }, ... }
local function partesDe(pack, lado, pasado)
    local lista = (lado == 2 and pack.der) or pack.partes or {}
    local v = variante(pack, pasado and not pack.fijo)
    local fuera = {}
    for i, p in ipairs(lista) do
        fuera[i] = { p[1]:format(v), p[2] }
    end
    return fuera
end

--[[ Lo que mira a la camara y da luz (la pancarta luminosa: `encara` y `luz`
     del pack en Config.PropsCarrera). Cada cliente crea sus props, asi que
     a cada jugador le miran a el. Un hilo en cada fotograma, solo mientras
     haya alguno, y solo los cercanos. DrawLightWithRange con el color en
     ENTEROS: con decimales deja la pantalla en blanco. ]]
local encarados = {}      -- [obj] = { luz = {alto, alcance, intensidad}, color = {r, g, b}, base, fase }
--[[ Levitan: suben y bajan despacio (LEVITA_ALTO metros, LEVITA_VEL radianes
     por segundo), cada una con su fase para que no vayan todas a la vez. La
     vista previa de la grabacion no (la mueve el coche). ]]
local LEVITA_ALTO, LEVITA_VEL = 0.2, 1.4
local hiloEncarados = false
local COLOR_LUZ = {
    rosa = { 255, 70, 140 }, naranja = { 255, 150, 50 }, verde = { 40, 230, 110 },
}

local function vigilarEncarados()
    if hiloEncarados then return end
    hiloEncarados = true
    CreateThread(function()
        while next(encarados) do
            local cam = GetFinalRenderedCamCoord()
            local t = GetGameTimer() / 1000.0
            for obj, d in pairs(encarados) do
                if not DoesEntityExist(obj) then
                    encarados[obj] = nil
                else
                    local c = GetEntityCoords(obj)
                    local dist = #(c - cam)
                    if dist < 250.0 then
                        if d.base then
                            SetEntityCoordsNoOffset(obj, d.base.x, d.base.y,
                                d.base.z + LEVITA_ALTO * math.sin(t * LEVITA_VEL + d.fase), false, false, false)
                            c = GetEntityCoords(obj)
                        end
                        -- La cara es -Y del modelo: que mire a la camara
                        local rumbo = math.deg(math.atan(-(cam.x - c.x), cam.y - c.y)) + 180.0
                        SetEntityRotation(obj, 0.0, 0.0, rumbo, 2, true)
                        if d.luz and dist < 150.0 then
                            DrawLightWithRange(c.x, c.y, c.z + (d.luz.alto or 4.0), d.color[1], d.color[2], d.color[3],
                                d.luz.alcance or 10.0, d.luz.intensidad or 5.0)
                        end
                    end
                end
            end
            Wait(0)
        end
        hiloEncarados = false
    end)
end

--[[ Planta un grupo (un pack en un lado de un checkpoint) y lo apunta en
     `lista`. La primera parte va al suelo, mirando como la carretera; las
     demas, pegadas a ella: la tela de la bandera no puede ir congelada ni
     con colision (se caeria), y pegada al mastil ondea igual que las de los
     yates del juego, que tambien van pegadas. ]]
local function plantarGrupo(lista, grupo)
    local partes = partesDe(grupo.pack, grupo.lado, grupo.pasado)
    local base
    for i, p in ipairs(partes) do
        local hash = cargarModelo(p[1])
        if not hash then
            print(('^1[Racing]^7 No se pudo cargar el modelo de decoracion %s'):format(p[1]))
            if i == 1 then return end
        else
            local obj = CreateObject(hash, grupo.x, grupo.y, grupo.z, false, false, false)
            if obj and obj ~= 0 then
                SetEntityCollision(obj, false, false)
                if i == 1 then
                    base = obj
                    SetEntityHeading(obj, grupo.heading)
                    if grupo.pack.encara then
                        -- Los que flotan, NO: PlaceObjectOnGroundProperly baja el
                        -- modelo hasta que su punto mas bajo toca el suelo, y la caja
                        -- de luz (que empieza a 3 m del origen) quedaba en el suelo.
                        SetEntityCoordsNoOffset(obj, grupo.x, grupo.y, grupo.z + (grupo.pack.altura or 0.0), false, false, false)
                    else
                        PlaceObjectOnGroundProperly(obj)
                    end
                    FreezeEntityPosition(obj, true)
                    if grupo.pack.encara then
                        local tono = (grupo.pasado and not grupo.pack.fijo) and 'verde' or (NACION and 'naranja' or 'rosa')
                        encarados[obj] = {
                            luz = grupo.pack.luz, color = COLOR_LUZ[tono],
                            base = not grupo.fantasma and GetEntityCoords(obj) or nil,
                            fase = math.random() * 6.283,
                        }
                        vigilarEncarados()
                    end
                elseif base then
                    local o = p[2] or vec3(0.0, 0.0, 0.0)
                    AttachEntityToEntity(obj, base, 0, o.x, o.y, o.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                end
                if grupo.alpha then SetEntityAlpha(obj, grupo.alpha, false) end
                lista[#lista + 1] = { obj = obj, grupo = grupo }
            end
            SetModelAsNoLongerNeeded(hash)
        end
    end
    -- La version verde se pide ya: al pasar el checkpoint el cambio es al momento
    if not grupo.pasado and not grupo.pack.fijo and not grupo.fantasma then
        for _, p in ipairs(partesDe(grupo.pack, grupo.lado, true)) do
            local h = GetHashKey(p[1])
            if IsModelInCdimage(h) then RequestModel(h) end
        end
    end
end

--[[ El corredor ha pasado este checkpoint: sus props se cambian por los
     verdes. Se quitan y se vuelven a plantar en el mismo sitio. Espera a que
     carguen los modelos: hay que llamarla desde un hilo. ]]
function Decoracion.Pasar(lista)
    if lista.pasado then return end
    lista.pasado = true
    local grupos, quitar = {}, {}
    for i = #lista, 1, -1 do
        local it = lista[i]
        if it.grupo and not it.grupo.pack.fijo then
            if not grupos[it.grupo] then grupos[it.grupo] = true end
            if it.obj and DoesEntityExist(it.obj) then DeleteObject(it.obj) end
            table.remove(lista, i)
        end
    end
    for grupo in pairs(grupos) do
        grupo.pasado = true
        plantarGrupo(lista, grupo)
    end
end

-- ── El fantasma de la grabacion ─────────────────────────────────────────
--[[ Grabando un circuito, los props del estilo elegido van pegados al coche,
     a los dos lados, donde quedarian si se marcase el punto AHORA (antes eran
     dos cilindros rosas). Se crean una vez por estilo, en un hilo aparte —la
     grabacion pinta cada fotograma y no puede esperar a que cargue un modelo—
     y luego solo se mueven. ]]
local fantasma = { id = nil, grupos = {}, cargando = false }

local function quitarFantasma()
    for _, lista in pairs(fantasma.grupos) do
        for _, it in ipairs(lista) do
            if it.humo then StopParticleFxLooped(it.humo, false) end
            if it.obj and DoesEntityExist(it.obj) then DeleteObject(it.obj) end
        end
    end
    fantasma.grupos = {}
    fantasma.id = nil
end

--- cp = { x, y, z, heading, radius, deco } o nil para quitarlo. Devuelve si
--- hay fantasma (un estilo sin props propios —humo solo, «Sin nada»— no lo
--- tiene, y quien llama pinta sus guias de siempre).
function Decoracion.Fantasma(cp)
    if not cp then
        if not fantasma.cargando then quitarFantasma() end
        fantasma.id = nil
        return false
    end
    local estilo = Decoracion.Estilo(cp.deco)
    local pack = estilo and estilo.pack and PACKS[estilo.pack]
    if not pack then
        if not fantasma.cargando then quitarFantasma() end
        return false
    end

    local lx, ly, rx, ry = Decoracion.Lados(cp, estilo.separar)
    local rumbo = (cp.heading or 0.0) + (estilo.giro or 0.0)

    if fantasma.id ~= estilo.id or not next(fantasma.grupos) then
        if fantasma.cargando then return true end
        quitarFantasma()
        fantasma.id = estilo.id
        fantasma.cargando = true
        local clave = estilo.id
        CreateThread(function()
            local grupos = {}
            for lado = 1, 2 do
                local x = lado == 1 and lx or rx
                local y = lado == 1 and ly or ry
                local lista = {}
                plantarGrupo(lista, {
                    pack = pack, lado = lado, pasado = false, fantasma = true,
                    x = x, y = y, z = suelo(x, y, cp.z), heading = rumbo, alpha = 160,
                })
                -- Su humo, pegado al prop para que vaya con el
                local fx = estilo.ptfx
                local base = lista[1] and lista[1].obj
                if fx and base then
                    RequestNamedPtfxAsset(fx.dict)
                    local t = GetGameTimer()
                    while not HasNamedPtfxAssetLoaded(fx.dict) and GetGameTimer() - t < 2000 do Wait(20) end
                    if HasNamedPtfxAssetLoaded(fx.dict) and not fx.repetir then
                        local col = fx.columna
                        for _, s in ipairs(fx.salidas or { vec3(0.0, 0.0, fx.alto or 0.0) }) do
                            for piso = 0, (col and col.pisos or 1) - 1 do
                                UseParticleFxAsset(fx.dict)
                                local h = StartParticleFxLoopedOnEntity(fx.name, base, s.x, s.y,
                                    s.z + piso * (col and col.paso or 0.0), 0.0, 0.0, 0.0,
                                    (fx.scale or 1.0) * (1.0 + piso * (col and col.crece or 0.0)), false, false, false)
                                if h and h ~= 0 then
                                    local c = colorFx(fx)
                                    if c then SetParticleFxLoopedColour(h, c[1], c[2], c[3], false) end
                                    lista[#lista + 1] = { humo = h }
                                end
                            end
                        end
                    end
                end
                grupos[lado] = lista
            end
            fantasma.cargando = false
            if fantasma.id == clave then
                fantasma.grupos = grupos
            else
                -- Se ha cambiado de estilo (o se ha dejado de grabar) mientras cargaba
                for _, lista in pairs(grupos) do
                    for _, it in ipairs(lista) do
                        if it.humo then StopParticleFxLooped(it.humo, false) end
                        if it.obj and DoesEntityExist(it.obj) then DeleteObject(it.obj) end
                    end
                end
            end
        end)
        return true
    end

    for lado = 1, 2 do
        local lista = fantasma.grupos[lado]
        local base = lista and lista[1] and lista[1].obj
        if base and DoesEntityExist(base) then
            local x = lado == 1 and lx or rx
            local y = lado == 1 and ly or ry
            SetEntityCoordsNoOffset(base, x, y, suelo(x, y, cp.z) + (pack.encara and pack.altura or 0.0), false, false, false)
            if not pack.encara then SetEntityHeading(base, rumbo) end
        end
    end
    return true
end

-- ── Poner y quitar ──────────────────────────────────────────────────────

--[[ Pone la decoracion de un checkpoint y apunta en `lista` lo que ha creado,
     para poder quitarlo luego con Decoracion.Quitar.

     ESPERA mientras carga el modelo la primera vez: hay que llamarla desde un
     hilo. `opciones.alpha` deja los props translucidos (la grabacion los pone
     asi para que se distingan de los de una carrera). ]]
function Decoracion.Poner(lista, cp, opciones)
    local estilo = Decoracion.Estilo(cp.deco)
    if not estilo then return end

    local lx, ly, rx, ry = Decoracion.Lados(cp, estilo.separar)

    -- Un pack de props propios: un grupo a cada lado (y si lleva humo, sigue
    -- abajo para ponerlo)
    local pack = estilo.pack and PACKS[estilo.pack]
    if pack then
        for lado = 1, 2 do
            local x = lado == 1 and lx or rx
            local y = lado == 1 and ly or ry
            plantarGrupo(lista, {
                pack = pack, lado = lado, pasado = false,
                x = x, y = y, z = suelo(x, y, cp.z),
                heading = (cp.heading or 0.0) + (estilo.giro or 0.0),
                alpha = opciones and opciones.alpha,
            })
        end
        if not estilo.ptfx then return end
    end
    if not estilo.model and not estilo.ptfx then return end
    local hash = estilo.model and cargarModelo(estilo.model) or nil

    if estilo.model and not hash then
        print(('^1[Racing]^7 No se pudo cargar el modelo de decoracion %s'):format(tostring(estilo.model)))
    end

    for lado = 1, 2 do
        local x = lado == 1 and lx or rx
        local y = lado == 1 and ly or ry
        local z = suelo(x, y, cp.z)

        if hash then
            local obj = CreateObject(hash, x, y, z, false, false, false)
            if obj and obj ~= 0 then
                -- Mirando como la carretera: una barrera cruzada no delimita nada.
                SetEntityHeading(obj, (cp.heading or 0.0) + (estilo.giro or 0.0))
                PlaceObjectOnGroundProperly(obj)
                SetEntityCollision(obj, false, false)
                FreezeEntityPosition(obj, true)
                if opciones and opciones.alpha then
                    SetEntityAlpha(obj, opciones.alpha, false)
                end
                lista[#lista + 1] = { obj = obj }
            end
        end

        if estilo.ptfx then
            --[[ `columna`: la misma particula repetida hacia arriba. Una
                 particula hace lo que hace —la del humo rosa es una bola a ras
                 de suelo y no se le puede decir que suba—, pero varias bolas
                 una encima de otra si son una columna. `crece`: cada piso es
                 esa fraccion mas grande que el de abajo (el humo se abre al
                 subir). ]]
            local col = estilo.ptfx.columna
            local pisos = col and col.pisos or 1
            local paso = col and col.paso or 0.0
            local crece = col and col.crece or 0.0
            -- Las salidas van respecto al prop y giran con el (su rumbo)
            local salidas = estilo.ptfx.salidas or { vec3(0.0, 0.0, estilo.ptfx.alto or 0.0) }
            local hr = math.rad((cp.heading or 0.0) + (estilo.giro or 0.0))
            local ch, sh = math.cos(hr), math.sin(hr)

            for _, s in ipairs(salidas) do
                for piso = 0, pisos - 1 do
                    lista[#lista + 1] = {
                        fx = estilo.ptfx,
                        x = x + s.x * ch - s.y * sh, y = y + s.x * sh + s.y * ch,
                        z = z + s.z + piso * paso,
                        escala = (estilo.ptfx.scale or 1.0) * (1.0 + piso * crece),
                    }
                end
            end
            vigilar(lista)
        end
    end

    -- Los objetos ya creados se quedan su modelo; la peticion se suelta para
    -- que el juego pueda descargarlo cuando no quede ninguno. La siguiente
    -- vez se vuelve a pedir (cargarModelo), y si sigue en memoria es al momento.
    if hash then SetModelAsNoLongerNeeded(hash) end
end

--- Quita todo lo apuntado en `lista` y la deja vacia. Se vacia la MISMA tabla
--- en vez de devolver otra: el hilo de las particulas la tiene cogida.
function Decoracion.Quitar(lista)
    for i = #lista, 1, -1 do
        local it = lista[i]
        if it.obj and DoesEntityExist(it.obj) then DeleteObject(it.obj) end
        it.quitado = true
        apagar(it, true)
        lista[i] = nil
    end
    lista.pasado = nil
    conFx[lista] = nil
end
