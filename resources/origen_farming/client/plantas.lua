--[[ ── Lo que se ve en el campo ───────────────────────────────────────────────

     Props LOCALES (cada cliente pone los suyos) apoyados en el suelo y con la
     inclinación del terreno:
       · la planta de cada celda trabajada, según su fase
       · en cada acopio, el palé con sus cajas (cada una con lo de dentro) y el
         depósito de agua
       · los aspersores de cada parcela (los del mapa que la bordean, o unos
         propios en sus tuberías si no tiene), con el chorro de GTA cuando su
         riego está encendido
     Solo existen con los campos cerca; al alejarse se borran.

     La tierra trabajada se pinta con marcadores (más oscuros cuanto más
     húmeda) y la parcela en la que estás, con un borde fino. ]]

Plantas = {}

local props = {}        -- [parcela] = { [idx] = { ent, clave } }
local acopios = {}      -- [acopio] = { base, deposito, z, cajas = {} }
local riegos = {}       -- [parcela] = { propios = {ent}, chorros = {handle}, regando }

local function Modelo(lista)
    for _, m in ipairs(lista or {}) do
        local h = GetHashKey(m)
        if IsModelInCdimage(h) then return h, m end
    end
    return nil
end

local suelos = {}       -- ['parcela:idx'] = z
function Plantas.Suelo(cfg, idx)
    local clave = cfg.id .. ':' .. idx
    if suelos[clave] then return suelos[clave] end
    local pos = Granja.PosCelda(cfg, idx)
    local ok, z = GetGroundZFor_3dCoord(pos.x + 0.0, pos.y + 0.0, cfg.centro.z + 15.0, false)
    if ok and math.abs(z - cfg.centro.z) < 15.0 then
        suelos[clave] = z
        return z
    end
    return nil
end

local function Cargar(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local fin = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < fin do Wait(0) end
    return HasModelLoaded(hash)
end

local function Crear(hash, x, y, z, h)
    if not Cargar(hash) then return nil end
    local ent = Rastro.Marcar(CreateObjectNoOffset(hash, x + 0.0, y + 0.0, z + 0.0, false, false, false))
    SetEntityHeading(ent, (h or 0.0) + 0.0)
    FreezeEntityPosition(ent, true)
    SetEntityCollision(ent, false, false)
    SetEntityCanBeDamaged(ent, false)
    return ent
end

local function Borrar(ent)
    if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
end

--- El suelo y su normal en un punto, con un rayo contra el mapa.
local function SueloConNormal(x, y, zRef)
    local rayo = StartShapeTestLosProbe(x, y, zRef + 12.0, x, y, zRef - 12.0, 1, 0, 7)
    local estado, golpe, punto, normal
    local fin = GetGameTimer() + 500
    repeat
        estado, golpe, punto, normal = GetShapeTestResult(rayo)
        if estado == 1 then Wait(0) end
    until estado ~= 1 or GetGameTimer() > fin
    if golpe == 1 then return punto.z, normal end
    local ok, z, n = GetGroundZAndNormalFor_3dCoord(x, y, zRef + 12.0)
    if ok then return z, n end
    return nil
end
Plantas.SueloConNormal = SueloConNormal

--- Un prop apoyado en el suelo: la base toca la tierra y se inclina con la
--- pendiente. Primero lo coloca el propio motor (PlaceObjectOnGroundProperly);
--- si no puede, se calcula con la normal del terreno. `hundir` (metros) lo mete
--- en la tierra: así crecen las plantas, que GTA no deja escalar.
--- `solido`: con colisión (heno, palé, depósito). Las plantas no la llevan:
--- entre los surcos se tiene que poder andar.
function Plantas.CrearEnSuelo(hash, x, y, rumbo, zRef, hundir, solido)
    if not Cargar(hash) then return nil end
    local z, normal = SueloConNormal(x + 0.0, y + 0.0, (zRef or GetEntityCoords(cache.ped).z) + 0.0)
    if not z then return nil end
    local min = GetModelDimensions(hash)
    local ent = Rastro.Marcar(CreateObjectNoOffset(hash, x + 0.0, y + 0.0, z - min.z + 0.05, false, false, false))
    SetEntityHeading(ent, (rumbo or 0.0) + 0.0)
    if not PlaceObjectOnGroundProperly(ent) then
        local h = math.rad(rumbo or 0.0)
        local enDerecha = normal.x * math.cos(h) + normal.y * math.sin(h)
        local enFrente = -normal.x * math.sin(h) + normal.y * math.cos(h)
        local cabeceo = -math.deg(math.atan(enFrente, normal.z))
        local alabeo = math.deg(math.atan(enDerecha, normal.z))
        SetEntityCoordsNoOffset(ent, x + 0.0, y + 0.0, z - min.z, false, false, false)
        SetEntityRotation(ent, cabeceo + 0.0, alabeo + 0.0, (rumbo or 0.0) + 0.0, 2, true)
    end
    if hundir and hundir > 0 then
        local c = GetEntityCoords(ent)
        SetEntityCoordsNoOffset(ent, c.x, c.y, c.z - hundir, false, false, false)
    end
    FreezeEntityPosition(ent, true)
    SetEntityCollision(ent, solido == true, solido == true)
    SetEntityCanBeDamaged(ent, false)
    return ent, z
end

-- ── Las plantas ───────────────────────────────────────────────────────────

--- Qué modelo le toca a una celda y cuánto va hundido (fracción de su altura).
local function ModeloDe(c)
    if c.e == 'marchita' then return Modelo({ 'prop_grass_dry_02' }), 0.15 end
    -- Con heno: un rollo entero si lo echó el tractor, una paca pequeña si se
    -- esparció a mano (la de tres pacas apiladas era una pared).
    if c.e == 'empajada' then
        if c.m then return Modelo({ 'prop_haybale_01' }), 0.0 end
        return Modelo({ 'prop_haybale_03' }), 0.02
    end
    local fase = G.Fase(c)
    if not fase then return nil end
    local cult = Granja.Cultivo(c.c)
    local def = cult and cult.modelos[fase]
    if not def then return nil end
    return Modelo(def), def.hundir or 0.0
end

function Plantas.ActualizarCelda(parcelaId, idx)
    local cfg = Granja.Parcela(parcelaId)
    local c = G.Celda(parcelaId, idx)
    if not cfg or not c then return end
    props[parcelaId] = props[parcelaId] or {}
    local actual = props[parcelaId][idx]
    local hash, hundir = ModeloDe(c)
    local clave = hash and (hash .. ':' .. hundir) or nil

    if actual and actual.clave == clave and DoesEntityExist(actual.ent) then return end
    if actual then
        -- El rastrillo deshace el rollo: polvo y briznas donde estaba.
        if actual.rollo and c.e ~= 'empajada' and DoesEntityExist(actual.ent) then
            local p = GetEntityCoords(actual.ent)
            RequestNamedPtfxAsset('core')
            if HasNamedPtfxAssetLoaded('core') then
                UseParticleFxAssetNextCall('core')
                StartParticleFxNonLoopedAtCoord('ent_dst_dust', p.x, p.y, p.z, 0.0, 0.0, 0.0, 2.5, false, false, false)
                UseParticleFxAssetNextCall('core')
                StartParticleFxNonLoopedAtCoord('ent_dst_gen_paper', p.x, p.y, p.z + 0.5, 0.0, 0.0, 0.0, 1.5, false, false, false)
            end
        end
        Borrar(actual.ent)
        props[parcelaId][idx] = nil
    end
    if not hash then return end

    local z = Plantas.Suelo(cfg, idx)
    if not z then return end
    local pos = Granja.PosCelda(cfg, idx)
    local min, max = GetModelDimensions(hash)
    local rollo = c.e == 'empajada'
    -- Los rollos, en filas rectas; las plantas, cada una con su giro para que
    -- la fila no parezca clonada.
    local rumbo = rollo and (cfg.rumbo + 90.0) or ((idx * 47) % 360)
    local ent = Plantas.CrearEnSuelo(hash, pos.x, pos.y, rumbo, z, (max.z - min.z) * hundir + 0.03, rollo)
    if not ent then return end
    -- Mientras cargaba el modelo se pudo quitar la parcela (al alejarse o al
    -- soltarla): entonces esta planta ya sobra.
    if not props[parcelaId] then Borrar(ent) return end
    local previa = props[parcelaId][idx]
    if previa and previa.ent ~= ent then Borrar(previa.ent) end
    props[parcelaId][idx] = { ent = ent, clave = clave, rollo = rollo }
end

--- Repasa una parcela: las celdas que llegan y las que tenían planta.
local function RepasarCeldas(id)
    local v = G.parcelas[id]
    local vistas = {}
    for idx in pairs(v and v.celdas or {}) do
        vistas[idx] = true
        Plantas.ActualizarCelda(id, idx)
    end
    for idx in pairs(props[id] or {}) do
        if not vistas[idx] then Plantas.ActualizarCelda(id, idx) end
    end
end

-- ── Los aspersores de cada parcela ───────────────────────────────────────

--[[ Un chorro de riego sobre un aspersor (el de serie de GTA). Va CLAVADO en
     el sitio del aspersor, no pegado al objeto: los aspersores del mapa se
     caen o se descolocan cuando el juego quita la colisión del suelo al
     alejarse (con el noclip, por ejemplo), y un chorro pegado a ellos se iba
     con ellos y dejaba arcos de agua por el cielo. Los de la tubería entre
     dos parcelas los comparten las dos: se cuenta quién lo usa y el chorro es
     uno solo, con la posición redondeada como clave. ]]
local enUso = {}
local function Clave(c)
    return ('%d:%d'):format(math.floor(c.x * 2 + 0.5), math.floor(c.y * 2 + 0.5))
end

local function ChorroNuevo(pos, rumbo)
    local ef = Config.Riego.efecto
    RequestNamedPtfxAsset('core')
    local fin = GetGameTimer() + 2000
    while not HasNamedPtfxAssetLoaded('core') and GetGameTimer() < fin do Wait(0) end
    UseParticleFxAssetNextCall('core')
    local h = StartParticleFxLoopedAtCoord(ef.nombre, pos.x, pos.y, pos.z, ef.rot.x, ef.rot.y, ef.rot.z + rumbo,
        ef.escala, false, false, false, false)
    return h ~= 0 and h or nil
end

local function Chorro(clave, pos, rumbo)
    local u = enUso[clave]
    if u then u.n = u.n + 1 return clave end
    local h = ChorroNuevo(pos, rumbo)
    if not h then return nil end
    enUso[clave] = { h = h, n = 1 }
    return clave
end

function Plantas.ChorroVivo(clave)
    local u = enUso[clave]
    if not u then return false end
    if DoesParticleFxLoopedExist(u.h) then return true end
    -- El juego lo ha perdido: se olvida para volver a crearlo.
    enUso[clave] = nil
    return false
end

local function Soltar(clave)
    local u = enUso[clave]
    if not u then return end
    u.n = u.n - 1
    if u.n <= 0 then
        StopParticleFxLooped(u.h, false)
        enUso[clave] = nil
    end
end

--- Los aspersores del mapa cargados ahora mismo (los de la finca). Se mira el
--- pool una vez por repaso y cada parcela se queda con los suyos.
local function AspersoresCargados()
    local hash = GetHashKey(Config.Riego.modelo)
    local lista = {}
    for _, obj in ipairs(GetGamePool('CObject')) do
        if GetEntityModel(obj) == hash and not IsEntityAMissionEntity(obj) then
            -- Solo los que están de verdad en el suelo: nada de objetos a medio
            -- cargar flotando (dejaban chorros en el aire).
            local sobreSuelo = GetEntityHeightAboveGround(obj)
            if sobreSuelo > -1.0 and sobreSuelo < 1.5 then lista[#lista + 1] = obj end
        end
    end
    return lista
end

--- Los aspersores del mapa que bordean una parcela (sobre sus tuberías).
local function AspersoresDelMapa(cfg, cargados)
    local lista = {}
    for _, obj in ipairs(cargados or AspersoresCargados()) do
        local c = GetEntityCoords(obj)
        if Granja.DentroDe(cfg, c.x, c.y, Config.Riego.margen) then lista[#lista + 1] = obj end
    end
    return lista
end

local function ApagarRiego(r)
    for _, clave in ipairs(r.chorros or {}) do Soltar(clave) end
    r.chorros, r.regando = nil, nil
end

--[[ El riego de una parcela, repasado cada pocos segundos y no solo al
     encenderse. Hace falta porque lo que se ve depende de lo que el juego
     tenga cargado: los aspersores del mapa entran y salen de memoria al
     alejarse (y al volver son OTRAS entidades, sin chorro), el suelo puede no
     tener colisión aún cuando se enciende de lejos, y un chorro se puede
     perder. Así que cada repaso compara lo que debería regar con lo que riega
     y arregla la diferencia. ]]
function Plantas.ActualizarRiego(id, cargados)
    local cfg = Granja.Parcela(id)
    local v = G.parcelas[id]
    if not cfg or not v then return end
    local r = riegos[id] or {}
    riegos[id] = r
    local regando = (v.riego or 0) - (GetGameTimer() - v.recibida) / 1000 > 0

    if not regando then
        if r.regando then
            ApagarRiego(r)
            for _, ent in ipairs(r.propios or {}) do Borrar(ent) end
            r.propios = nil
        end
        return
    end
    r.regando = true
    r.chorros = r.chorros or {}

    -- Los del mapa si están cargados; si no, unos propios en sus tuberías.
    local objetos = AspersoresDelMapa(cfg, cargados)
    if #objetos > 0 then
        for _, ent in ipairs(r.propios or {}) do Borrar(ent) end
        r.propios = nil
    else
        local faltan = not r.propios or #r.propios == 0
        if faltan then
            r.propios = {}
            local hash = Modelo({ Config.Riego.modelo })
            local zRef = Plantas.SueloCentro and Plantas.SueloCentro(cfg) or cfg.centro.z
            for _, pos in ipairs(hash and Granja.AspersoresPropios(cfg) or {}) do
                local ent = Plantas.CrearEnSuelo(hash, pos.x, pos.y, cfg.rumbo + 90.0, zRef or cfg.centro.z)
                if ent then r.propios[#r.propios + 1] = ent end
            end
        end
        objetos = r.propios
    end

    -- Fuera los chorros de lo que ya no está; puestos los que falten. Solo
    -- cuenta el aspersor que está de pie en el suelo en este momento.
    local quiero = {}
    for _, obj in ipairs(objetos) do
        if DoesEntityExist(obj) then
            local sobreSuelo = GetEntityHeightAboveGround(obj)
            if sobreSuelo > -1.0 and sobreSuelo < 1.5 then
                local c = GetEntityCoords(obj)
                quiero[Clave(c)] = { pos = c, rumbo = GetEntityHeading(obj) }
            end
        end
    end
    local siguen = {}
    for _, clave in ipairs(r.chorros) do
        if quiero[clave] and Plantas.ChorroVivo(clave) then
            siguen[#siguen + 1] = clave
            quiero[clave] = nil
        else
            Soltar(clave)
        end
    end
    r.chorros = siguen
    for clave, q in pairs(quiero) do
        if Chorro(clave, q.pos, q.rumbo) then r.chorros[#r.chorros + 1] = clave end
    end
end

-- ── Los acopios ───────────────────────────────────────────────────────────

--- A cuántos metros se ve lo que llevan dentro las cajas de un acopio.
local CONTENIDO = 40.0
local HUECOS_PALE = {}
for piso = 0, 2 do
    for fila = 0, 1 do
        for col = 0, 1 do
            HUECOS_PALE[#HUECOS_PALE + 1] = { col = col, fila = fila, piso = piso }
        end
    end
end

function Plantas.ActualizarAcopio(id)
    local cfg = Granja.Acopio(id)
    if not cfg then return end
    local p = acopios[id]
    if not p then
        local base = Modelo({ Config.Carga.paleModelo })
        local dep = Modelo({ 'prop_watercrate_01', 'prop_barrel_02a' })
        p = { cajas = {} }
        if base then p.base, p.z = Plantas.CrearEnSuelo(base, cfg.pos.x, cfg.pos.y, cfg.pos.w, cfg.pos.z, nil, true) end
        if not p.base then return end
        if dep then p.deposito = Plantas.CrearEnSuelo(dep, cfg.deposito.x, cfg.deposito.y, cfg.pos.w, cfg.pos.z, nil, true) end
        acopios[id] = p
    end

    local cajas = (G.acopios[id] and G.acopios[id].cajas) or {}
    -- Lo de dentro de cada caja son unos cuantos objetos: solo a menos de
    -- CONTENIDO metros, que de más lejos no se ve y con el campo lleno de
    -- acopios reventaría los objetos del juego.
    local cerca = Granja.Plano(GetEntityCoords(cache.ped), cfg.pos) < CONTENIDO
    for i = 1, #HUECOS_PALE do
        local caja = cajas[i]
        -- Una caja con otra encima no enseña nada: no se ve el interior y
        -- así no se gastan objetos pegados (ver client/relleno.lua).
        local tapada = false
        for k = 1, #HUECOS_PALE do
            local o = HUECOS_PALE[k]
            if cajas[k] and o.col == HUECOS_PALE[i].col and o.fila == HUECOS_PALE[i].fila
                and o.piso == HUECOS_PALE[i].piso + 1 then
                tapada = true
                break
            end
        end
        local verDentro = cerca and not tapada
        local clave = caja and (Relleno.Clave(caja) .. (verDentro and ':v' or '')) or nil
        local actual = p.cajas[i]
        if actual and actual.clave ~= clave then
            Relleno.Borrar(actual.dentro)
            Borrar(actual.ent)
            p.cajas[i], actual = nil, nil
        end
        local tipo = type(caja) == 'table' and caja.t or nil
        if tipo and not actual and DoesEntityExist(p.base) then
            local hash = Modelo({ Config.Carga[tipo] and Config.Carga[tipo].modelo })
            if hash then
                -- La pila apoya en la tabla del palé y cada piso encima del de abajo.
                local hueco = HUECOS_PALE[i]
                local ent = Crear(hash, cfg.pos.x, cfg.pos.y, (p.z or cfg.pos.z) + 1.0, cfg.pos.w)
                local dentro = {}
                if ent then
                    local min, max = GetModelDimensions(hash)
                    local _, pmax = GetModelDimensions(GetEntityModel(p.base))
                    local ox = (hueco.col - 0.5) * (max.x - min.x + 0.02) - (min.x + max.x) / 2
                    local oy = (hueco.fila - 0.5) * (max.y - min.y + 0.02) - (min.y + max.y) / 2
                    local oz = pmax.z + hueco.piso * (max.z - min.z) - min.z
                    -- El palé no se mueve: la caja se coloca y se congela. Con
                    -- AttachEntityToEntity, doce cajas por acopio (y lo que
                    -- llevan dentro) llenaban el pool de objetos pegados de
                    -- GTA y el juego se caía (ver client/relleno.lua).
                    AttachEntityToEntity(ent, p.base, 0, ox, oy, oz, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                    if tipo == 'caja' and verDentro then dentro = Relleno.Llenar(ent, caja.c, caja.l) end
                end
                p.cajas[i] = { ent = ent, clave = clave, dentro = dentro }
            end
        end
    end
end

-- ── Borrar y repasar ──────────────────────────────────────────────────────

--- El heno (rollos y pacas) a menos de `radio` de un punto. El tractor lo
--- atraviesa: el rastrillo tiene que pasar por encima para deshacerlo.
function Plantas.Heno(pos, radio)
    local lista = {}
    for id, celdas in pairs(props) do
        local cfg = Granja.Parcela(id)
        if cfg and Granja.Plano(pos, cfg.centro) < radio + cfg.radio then
            for _, pr in pairs(celdas) do
                if pr.rollo and DoesEntityExist(pr.ent) then lista[#lista + 1] = pr.ent end
            end
        end
    end
    return lista
end

--- Una parcela que ha quedado lejos: fuera sus plantas y su riego. Vuelven
--- solas al acercarse (el repaso las crea desde la vista que ya tenemos).
function Plantas.Olvidar(id)
    for _, pr in pairs(props[id] or {}) do Borrar(pr.ent) end
    props[id] = nil
    local r = riegos[id]
    if r then
        ApagarRiego(r)
        for _, ent in ipairs(r.propios or {}) do Borrar(ent) end
        riegos[id] = nil
    end
end

function Plantas.BorrarTodo()
    for _, lista in pairs(props) do
        for _, pr in pairs(lista) do Borrar(pr.ent) end
    end
    props = {}
    for _, r in pairs(riegos) do
        ApagarRiego(r)
        for _, ent in ipairs(r.propios or {}) do Borrar(ent) end
    end
    riegos = {}
    for _, p in pairs(acopios) do
        for _, c in pairs(p.cajas) do Relleno.Borrar(c.dentro) Borrar(c.ent) end
        Borrar(p.base) Borrar(p.deposito)
    end
    acopios = {}
end

AddEventHandler('origen_farming:c:parcela', function(id)
    RepasarCeldas(id)
    Plantas.ActualizarRiego(id)
end)
AddEventHandler('origen_farming:c:celda', function(id, idx) Plantas.ActualizarCelda(id, idx) end)
AddEventHandler('origen_farming:c:acopio', function(id) Plantas.ActualizarAcopio(id) end)
AddEventHandler('origen_farming:c:olvidar', function() Plantas.BorrarTodo() end)

-- Las fases cambian solas con el tiempo (brote → crece), y el riego se apaga.
CreateThread(function()
    while true do
        Wait(4000)
        if G.cerca then
            local pos = GetEntityCoords(cache.ped)
            local cargados = AspersoresCargados()
            for id in pairs(G.parcelas) do
                local cfg = Granja.Parcela(id)
                local d = cfg and Granja.Plano(pos, cfg.centro)
                if d and d <= Config.DistanciaVer then
                    RepasarCeldas(id)
                    Plantas.ActualizarRiego(id, cargados)
                elseif d and d > Config.DistanciaVer + 20.0 then
                    Plantas.Olvidar(id)
                end
                Wait(0)
            end
            for _, a in ipairs(Config.Acopios) do
                if Granja.Plano(pos, a.pos) <= Config.DistanciaVer then Plantas.ActualizarAcopio(a.id) end
            end
        end
    end
end)

-- ── La tierra y los bordes ───────────────────────────────────────────────

--- Lo dibujado no recibe luz: de noche brillaría. Se oscurece con la hora.
local function Luz()
    local h = GetClockHours() + GetClockMinutes() / 60
    if h >= 7 and h <= 19 then return 1.0 end
    if h > 19 and h < 21 then return 1.0 - (h - 19) / 2 * 0.65 end
    if h >= 5 and h < 7 then return 0.35 + (h - 5) / 2 * 0.65 end
    return 0.35
end

--[[ Todo lo que se pinta en la tierra va PEGADO AL SUELO: polígonos cuyos
     vértices están a la altura real del terreno en ese punto (medida con el
     mapa y guardada en una rejilla de 25 cm). Así los bordes y las marcas
     siguen la pendiente y los desniveles en vez de ser cajas planas que
     flotan o se entierran. ]]

local alturas = {}
local ENCIMA = 0.1

--- Altura del suelo en un punto (guardada).
local function Altura(x, y, zRef)
    local clave = math.floor(x * 4 + 0.5) * 100000 + math.floor(y * 4 + 0.5)
    local z = alturas[clave]
    if z then return z end
    local ok, suelo = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, zRef + 15.0, false)
    if not ok or math.abs(suelo - zRef) > 15.0 then return nil end
    alturas[clave] = suelo
    return suelo
end

--- Un cuadrilátero sobre el suelo (visto desde arriba, en sentido antihorario).
local function Quad(a, b, c, d, r, g, bl, al)
    DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, r, g, bl, al)
    DrawPoly(a.x, a.y, a.z, c.x, c.y, c.z, d.x, d.y, d.z, r, g, bl, al)
end

local function PuntoEnSuelo(x, y, zRef)
    local z = Altura(x, y, zRef)
    return z and vec3(x, y, z + ENCIMA) or nil
end

--- Una tira fina sobre el suelo de A a B, troceada cada medio metro.
local function Tira(zRef, ax, ay, bx, by, grosor, col)
    local dx, dy = bx - ax, by - ay
    local largo = math.sqrt(dx * dx + dy * dy)
    if largo < 0.01 then return end
    local n = math.max(1, math.ceil(largo / 0.5))
    -- Perpendicular a la izquierda del sentido A→B.
    local px, py = -dy / largo * grosor / 2, dx / largo * grosor / 2
    local prevI, prevD
    for i = 0, n do
        local t = i / n
        local x, y = ax + dx * t, ay + dy * t
        local zi, zd = Altura(x - px, y - py, zRef), Altura(x + px, y + py, zRef)
        if not zi or not zd then prevI = nil else
            local izq = vec3(x + px, y + py, zd + ENCIMA)
            local der = vec3(x - px, y - py, zi + ENCIMA)
            if prevI then Quad(prevD, der, izq, prevI, col[1], col[2], col[3], col[4]) end
            prevI, prevD = izq, der
        end
    end
end

--- Un rectángulo girado con la parcela (centro, medidas a lo ancho y a lo largo).
local function Esquinas(cfg, cx, cy, ancho, largo)
    local ax, ay = cfg.ejeCol.x * largo / 2, cfg.ejeCol.y * largo / 2
    local bx, by = cfg.ejeFila.x * ancho / 2, cfg.ejeFila.y * ancho / 2
    return {
        { cx - ax - bx, cy - ay - by }, { cx + ax - bx, cy + ay - by },
        { cx + ax + bx, cy + ay + by }, { cx - ax + bx, cy - ay + by },
    }
end

local function Marco(cfg, cx, cy, ancho, largo, grosor, col)
    local e = Esquinas(cfg, cx, cy, ancho, largo)
    for i = 1, 4 do
        local p, q = e[i], e[i % 4 + 1]
        Tira(cfg.centro.z, p[1], p[2], q[1], q[2], grosor, col)
    end
end

--- Un cuadro relleno sobre el suelo, en una rejilla de `div` × `div` trozos.
local function Relleno(cfg, cx, cy, lado, div, col)
    local ax, ay = cfg.ejeCol.x * lado, cfg.ejeCol.y * lado
    local bx, by = cfg.ejeFila.x * lado, cfg.ejeFila.y * lado
    local ox, oy = cx - ax / 2 - bx / 2, cy - ay / 2 - by / 2
    local puntos = {}
    for i = 0, div do
        puntos[i] = {}
        for j = 0, div do
            local x = ox + ax * (i / div) + bx * (j / div)
            local y = oy + ay * (i / div) + by * (j / div)
            puntos[i][j] = PuntoEnSuelo(x, y, cfg.centro.z)
        end
    end
    for i = 0, div - 1 do
        for j = 0, div - 1 do
            local a, b, c, d = puntos[i][j], puntos[i + 1][j], puntos[i + 1][j + 1], puntos[i][j + 1]
            if a and b and c and d then Quad(a, b, c, d, col[1], col[2], col[3], col[4]) end
        end
    end
end

local function DibujarTierra(cfg, v, luz)
    for idx, c in pairs(v.celdas) do
        if c.e ~= 'yermo' and c.e ~= 'empajada' then
            local pos = Granja.PosCelda(cfg, idx)
            local r, g, b, a = 84, 60, 40, 80
            if c.e == 'creciendo' then
                local cc = G.Celda(cfg.id, idx)
                local agua = (cc and cc.a or 0) / 100
                r, g, b, a = 96 - 46 * agua, 70 - 36 * agua, 46 - 24 * agua, 105
            elseif c.e == 'marchita' then
                r, g, b, a = 120, 108, 80, 80
            end
            Relleno(cfg, pos.x, pos.y, cfg.paso * 0.9, 3,
                { math.floor(r * luz), math.floor(g * luz), math.floor(b * luz), a })
        end
    end
end

Plantas.Tira = Tira
Plantas.Relleno = Relleno

function Plantas.SueloCentro(cfg)
    return Altura(cfg.centro.x, cfg.centro.y, cfg.centro.z) or cfg.centro.z
end

--- El marco de la celda apuntada.
function Plantas.Resaltar(cfg, idx, color)
    local pos = Granja.PosCelda(cfg, idx)
    Marco(cfg, pos.x, pos.y, cfg.paso * 0.94, cfg.paso * 0.94, 0.09, color)
end

--- Los bordes de las parcelas: blanco si es libre, rosa si es tuya, ámbar si
--- es de otro. De jornada y a pie se ven las cercanas; la de ahora, más marcada.
local BORDE = { libre = { 255, 255, 255, 110 }, mia = { 216, 27, 85, 190 }, ajena = { 240, 180, 41, 170 } }

CreateThread(function()
    while true do
        local espera = 800
        if G.cerca then
            local pos = GetEntityCoords(cache.ped)
            local luz = Luz()
            for id, v in pairs(G.parcelas) do
                local cfg = Granja.Parcela(id)
                if cfg then
                    local dist = Granja.Plano(pos, cfg.centro)
                    if dist < 40.0 then
                        espera = 0
                        DibujarTierra(cfg, v, luz)
                        local dentro = Granja.DentroDe(cfg, pos.x, pos.y, 0.6)
                        if not cache.vehicle and (dentro or (G.Jornada() and dist < 22.0)) then
                            local base = G.EsMia(v) and BORDE.mia or (v.cid and BORDE.ajena or BORDE.libre)
                            local col = dentro and base
                                or { base[1], base[2], base[3], math.floor(base[4] * 0.6) }
                            Marco(cfg, cfg.centro.x, cfg.centro.y, cfg.filas * cfg.paso, cfg.columnas * cfg.paso,
                                dentro and 0.12 or 0.08, col)
                        end
                    end
                end
            end
        end
        Wait(espera)
    end
end)

--- Borra cualquier partícula que se quedara suelta sobre los campos (un
--- reinicio del recurso no las para). Los aspersores del mapa vuelven solos.
function Plantas.LimpiarParticulas()
    for _, campo in ipairs(Config.Campos) do
        RemoveParticleFxInRange(campo.centro.x, campo.centro.y, campo.centro.z, 250.0)
    end
end

CreateThread(Plantas.LimpiarParticulas)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    Plantas.BorrarTodo()
    Plantas.LimpiarParticulas()
end)
