--[[ ── La planta de compactación (cliente) ────────────────────────────────────

     Las tres prensas de muelle (Maquinas.prensa_muelle), sus contenedores de
     abajo (Maquinas.contenedor) y el decorado de la planta se crean al
     acercarse al depósito. Se anima igual para todos:
       · vaciar un camión: se abre la trampilla y las bolsas vuelan a la tolva
         de SU prensa, y la basura sube en la cámara;
       · el ciclo (arranca solo): baliza y temblor, el pistón baja dos veces
         entre polvo y vapor, sube, se abre la guillotina, la bala sale por los
         rodillos, baja por la rampa y cae al contenedor de abajo;
       · cada contenedor enseña las balas que tiene (las ve todo el mundo).
     A quien es el ciclo (y a su equipo) le sale la tarjeta con lo que cobra. ]]

local P = Config.Planta
-- Las luces de las prensas (foco de noche y baliza) se dibujan en cada
-- fotograma: solo para quien está de jornada o mientras prensa.
PL:SoloLucesSi(function(m) return m.marcha or L.Jornada() end)

local BOLSA = GetHashKey(Config.Bolsa.modelo)
local BALA = GetHashKey('origen_pm_bala')

local prensas, contenedores, decorado = {}, {}, {}
local montada = false

local function Estado(k)
    local e = GlobalState['origen_garbage:prensas']
    return e and e[k] or { ocupada = false, balas = 0 }
end

--- La prensa k (su id de máquina), para el camión y las órdenes de prueba.
Planta = {}
function Planta.Prensa(k) return prensas[k] end
function Planta.Libre(k) return not Estado(k).ocupada end

-- ── Lo que se ve según el estado ──────────────────────────────────────────

local enCiclo = {}          -- [k] = true mientras se anima (no repintar encima)
local esperadas = {}        -- [k] = balas que ya se ven caídas antes de que lo diga el servidor

local function Pintar()
    if not montada then return end
    for k in ipairs(P.prensas) do
        local c = contenedores[k]
        if c and not enCiclo[k] then
            local n = tonumber(Estado(k).balas) or 0
            if esperadas[k] and n >= esperadas[k] then esperadas[k] = nil end
            n = math.max(n, esperadas[k] or 0)
            for b = 1, P.balas.max do PL:Mostrar(c, 'pila' .. b, b <= n) end
        end
    end
end

AddStateBagChangeHandler('origen_garbage:prensas', 'global', function()
    SetTimeout(0, Pintar)
end)

-- ── Montar y desmontar ────────────────────────────────────────────────────

local function Objeto(modelo, c)
    local hash = GetHashKey(modelo)
    if not Dibujo.Cargar(hash) then return nil end
    local ent = Rastro.Marcar(CreateObjectNoOffset(hash, c.x, c.y, c.z, false, false, false))
    SetEntityHeading(ent, c.w + 0.0)
    if not modelo:find('^origen_pm_') then PlaceObjectOnGroundProperly(ent) end
    FreezeEntityPosition(ent, true)
    SetModelAsNoLongerNeeded(hash)
    return ent
end

local function Montar()
    montada = true
    for k, def in ipairs(P.prensas) do
        local c = def.coords
        prensas[k] = PL:Crear('prensa_muelle', c.xyz, c.w)
        contenedores[k] = PL:Crear('contenedor', def.contenedor.xyz, def.contenedor.w)
        local n = Basura.Offset(c.xyz, c.w, P.numero)
        decorado[#decorado + 1] = Objeto('origen_pm_num' .. k, vec4(n.x, n.y, n.z, c.w))
        local l = Basura.Offset(c.xyz, c.w, vec3(P.lampara.punto.x, P.lampara.punto.y, 0.0))
        decorado[#decorado + 1] = Objeto('origen_pm_lampara', vec4(l.x, l.y, P.lampara.techo, c.w))
    end
    for _, d in ipairs(P.decorado) do
        decorado[#decorado + 1] = Objeto(d[1], d[2])
    end
    Pintar()
end

local function Desmontar()
    montada = false
    for k in pairs(prensas) do PL:Borrar(prensas[k]) end
    for k in pairs(contenedores) do PL:Borrar(contenedores[k]) end
    for _, e in pairs(decorado) do Dibujo.Borrar(e) end
    prensas, contenedores, decorado, enCiclo, esperadas = {}, {}, {}, {}, {}
end

CreateThread(function()
    while true do
        local d = #(GetEntityCoords(cache.ped) - P.centro)
        -- Al arrancar el recurso los modelos tardan un momento en registrarse:
        -- sin ellos no se monta (se vuelve a mirar en 2 s).
        if d < 200.0 and not montada and IsModelInCdimage(GetHashKey('origen_pm_prensa')) then
            Montar()
        elseif d > 260.0 and montada then
            Desmontar()
        end
        Wait(montada and 5000 or 2000)
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then Desmontar() end
end)

-- ── Vaciar el camión: las bolsas vuelan a la tolva ────────────────────────

local function Vuelo(desde, hasta, ms)
    if not Dibujo.Cargar(BOLSA) then return end
    local ent = Rastro.Marcar(CreateObject(BOLSA, desde.x, desde.y, desde.z, false, false, false))
    SetEntityCollision(ent, false, false)
    local giro = vec3(math.random(-360, 360), math.random(-360, 360), math.random(-360, 360))
    local t0 = GetGameTimer()
    while true do
        local t = (GetGameTimer() - t0) / ms
        if t >= 1.0 then break end
        local p = desde + (hasta - desde) * t
        SetEntityCoordsNoOffset(ent, p.x, p.y, p.z + math.sin(t * math.pi) * 1.4, false, false, false)
        SetEntityRotation(ent, giro.x * t, giro.y * t, giro.z * t, 2, true)
        Wait(0)
    end
    DeleteEntity(ent)
end

RegisterNetEvent('origen_garbage:prensaVaciar', function(k, net, n, ms)
    if GetInvokingResource() then return end
    k = tonumber(k)
    local id = prensas[k]
    if not id then return end
    ms = math.max(1500, math.min(15000, tonumber(ms) or 4000))
    n = math.max(1, math.min(14, math.floor(tonumber(n) or 1)))
    local veh = Vehiculos.Entidad(net)
    local boca = PL:Punto(id, 'boca')
    if not boca then return end
    if veh then SetVehicleDoorOpen(veh, 5, false, false) end
    PL:Efecto(id, 'polvo_boca', true)
    CreateThread(function()
        local paso = (ms - 1200) / n
        for i = 1, n do
            if veh and DoesEntityExist(veh) then
                local desde = Vehiculos.Trasera(veh) + vec3(math.random(-40, 40) / 100, 0.0, 1.6)
                CreateThread(function() Vuelo(desde, boca + vec3(math.random(-50, 50) / 100, 0.0, 0.0), 750) end)
            end
            PL:Mostrar(id, 'relleno', true)
            PL:Mover(id, 'relleno', -1.0 + (i / n) * 0.95, paso / 1000)
            Wait(paso)
        end
        Wait(900)
        if prensas[k] == id then PL:Efecto(id, 'polvo_boca', false) end
        if veh and DoesEntityExist(veh) then SetVehicleDoorShut(veh, 5, false) end
    end)
end)

-- ── La bala cae al contenedor ─────────────────────────────────────────────

--[[ La bala del final de los rodillos (la pieza se esconde) baja por la
     rampa inclinándose y cae al hueco `b` del contenedor, volteando en el
     aire. Luego se enseña la bala quieta de ese hueco. ]]
local function Caida(k, b, ms)
    local id, cid = prensas[k], contenedores[k]
    if not id or not cid or not Dibujo.Cargar(BALA) then return end
    local def = P.prensas[k]
    local c = def.coords
    local notas = PL:Notas('prensa_muelle') or {}
    local rod = notas.rodillos or 2.5
    local inicio = Basura.Offset(c.xyz, c.w, vec3(0.0, -0.1 - rod, 0.3))
    local borde = PL:Punto(id, 'caida') or Basura.Offset(c.xyz, c.w, vec3(0.0, -3.65, -0.2))
    local hueco = Maquinas.contenedor.piezas['pila' .. b]
    local cc = def.contenedor
    local fin = Basura.Offset(cc.xyz, cc.w, hueco.pos)
    local rumboFin = cc.w + (hueco.rumbo or 0.0)
    local ent = Rastro.Marcar(CreateObjectNoOffset(BALA, inicio.x, inicio.y, inicio.z, false, false, false))
    SetEntityCollision(ent, false, false)
    SetEntityRotation(ent, 0.0, 0.0, c.w, 2, true)
    PL:Mostrar(id, 'bala', false)
    local t1, t2 = ms * 0.35, ms * 0.65
    local t0 = GetGameTimer()
    while true do
        local t = GetGameTimer() - t0
        if t >= t1 + t2 then break end
        if t < t1 then
            -- Por la rampa: se acelera y se inclina de morro.
            local u = (t / t1) ^ 2
            local p = inicio + (borde - inicio) * u
            SetEntityCoordsNoOffset(ent, p.x, p.y, p.z, false, false, false)
            SetEntityRotation(ent, 32.0 * u, 0.0, c.w, 2, true)
        else
            -- En el aire: cae con gravedad, voltea y se endereza al llegar.
            local u = (t - t1) / t2
            local x = borde.x + (fin.x - borde.x) * u
            local y = borde.y + (fin.y - borde.y) * u
            local z = borde.z + (fin.z - borde.z) * u * u
            SetEntityCoordsNoOffset(ent, x, y, z, false, false, false)
            SetEntityRotation(ent, 32.0 + 328.0 * u, (1 - u) * 10.0, c.w + (rumboFin - c.w) * u, 2, true)
        end
        Wait(0)
    end
    DeleteEntity(ent)
    PL:Mostrar(cid, 'pila' .. b, true)
    PL:Efecto(id, 'polvo_caida', true)
    SetTimeout(1600, function()
        if prensas[k] == id then PL:Efecto(id, 'polvo_caida', false) end
    end)
end

-- ── El ciclo de prensado ──────────────────────────────────────────────────

local ciclos = {}           -- [k] = { t0, ms, n, valor, cid } (la tarjeta)
local vuelta = {}

RegisterNetEvent('origen_garbage:prensaCiclo', function(k, ms, n, valor, cid)
    if GetInvokingResource() then return end
    k = tonumber(k)
    ms = tonumber(ms) or 16000
    ciclos[k] = { t0 = GetGameTimer(), ms = ms, n = tonumber(n) or 0, valor = tonumber(valor) or 0, cid = cid }
    local id = prensas[k]
    if not id then return end
    vuelta[k] = (vuelta[k] or 0) + 1
    local mia = vuelta[k]
    local x = math.max(0.5, ms / 16000)          -- todo escala con la duración
    local notas = PL:Notas('prensa_muelle') or {}
    local abajo, puerta, rodillos = notas.abajo or -1.55, notas.compuerta or 1.2, notas.rodillos or 2.5
    enCiclo[k] = true
    local function Sigue() return prensas[k] == id and vuelta[k] == mia end
    local function Espera(s) Wait(math.floor(s * 1000 * x)) return Sigue() end
    CreateThread(function()
        PL:Marcha(id, true)
        if not Espera(0.6) then return end
        -- Dos bajadas del pistón, con polvo y vapor en los cilindros.
        PL:Efecto(id, 'polvo_prensa', true)
        PL:Efecto(id, 'vapor_prensa', true)
        PL:Mostrar(id, 'relleno', true)
        PL:Mover(id, 'piston', abajo, 2.4 * x)
        PL:Mover(id, 'relleno', -0.55, 2.4 * x)
        if not Espera(2.5) then return end
        PL:Mover(id, 'piston', abajo * 0.45, 1.0 * x)
        if not Espera(1.1) then return end
        PL:Mover(id, 'piston', abajo, 1.4 * x)
        PL:Mover(id, 'relleno', -0.95, 1.4 * x)
        if not Espera(1.5) then return end
        -- Sube el pistón: ya es una bala.
        PL:Efecto(id, 'vapor_prensa', false)
        PL:Mostrar(id, 'relleno', false)
        PL:Mover(id, 'relleno', -1.0, 0.1)
        PL:Mover(id, 'bala', 0.0, 0.0)
        PL:Mostrar(id, 'bala', true)
        PL:Mover(id, 'piston', 0.0, 2.0 * x)
        if not Espera(1.9) then return end
        PL:Efecto(id, 'polvo_prensa', false)
        -- Sube la guillotina y la bala sale por los rodillos hasta la rampa.
        PL:Mover(id, 'compuerta', puerta, 1.2 * x)
        if not Espera(1.3) then return end
        PL:Mover(id, 'bala', rodillos, 3.0 * x)
        if not Espera(3.05) then return end
        -- Por la rampa, al contenedor.
        local b = math.min(P.balas.max, (tonumber(Estado(k).balas) or 0) + 1)
        PL:Mover(id, 'compuerta', 0.0, 1.4 * x)
        esperadas[k] = b
        Caida(k, b, math.floor(1300 * x))
        PL:Mover(id, 'bala', 0.0, 0.0)
        if not Espera(0.9) then return end
        PL:Marcha(id, false)
        enCiclo[k] = nil
        Pintar()
    end)
end)

-- ── La tarjeta de tu prensa ───────────────────────────────────────────────

CreateThread(function()
    local puesta = false
    while true do
        local espera = 1000
        local tarjeta
        if montada and L.Jornada() and #(GetEntityCoords(cache.ped) - P.centro) < 60.0 then
            espera = 250
            for k, c in pairs(ciclos) do
                local t = (GetGameTimer() - c.t0) / c.ms
                if t >= 1.2 then
                    ciclos[k] = nil
                elseif c.cid and Equipo.Mismo(c.cid, L.cid) then
                    local fase = t < 0.4 and 'Prensando' or t < 0.62 and 'Haciendo la bala'
                        or t < 0.92 and 'La bala sale por los rodillos' or 'Bala en el contenedor'
                    tarjeta = { nombre = ('Prensa %d'):format(k), bolsas = c.n, valor = c.valor,
                        progreso = math.min(1.0, t), fase = fase, cobrado = t >= 1.0 }
                    break
                end
            end
        end
        if tarjeta then
            puesta = true
            L.Tarjeta('prensa', tarjeta)
        elseif puesta then
            puesta = false
            L.SinTarjeta('prensa')
        end
        Wait(espera)
    end
end)
