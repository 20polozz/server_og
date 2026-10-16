--[[ ── La línea de sierra (cliente) ───────────────────────────────────────────

     Las máquinas del patio (Maquinas.*, client/maquina.lua) se crean al
     acercarse y se animan igual para todos con lo que manda el servidor
     (server/linea.lua):
       · el parque enseña los troncos que esperan (los que ruedan del camión);
       · por cada tronco: la grúa lo coge del parque y lo deja en la entrada
         de la descortezadora, que lo pasa por el rotor (astillas y corteza);
         luego el carro de la sierra lo pasa dos veces por la hoja y salen dos
         tablas por los rodillos;
       · con el último tronco de cada carga, la apiladora hace el paquete y
         la cinta lo lleva al secadero (la persiana sube, dentro vapor y
         luz). Al entrar, el servidor cobra la carga (server/linea.lua).
     29/09: la línea en U (sin carretilla); el tronco pasa sin saltos de la
     descortezadora al carro de la sierra, y la tabla de la sierra a la
     apiladora: los recorridos salen de dónde estén las máquinas. ]]

local L = Config.Linea
if not L then return end

-- Las luces (baliza de la grúa, dentro del secadero) solo para
-- quien está de jornada o mientras la máquina trabaja.
PL:SoloLucesSi(function(m) return m.marcha or LocalPlayer.state.lumberJornada == true end)

local LOG = GetHashKey('prop_log_01')
local Paquete     -- abajo: apiladora → cinta → secadero
local ids, parque = {}, {}
local montada = false

local function Estado()
    return GlobalState['origen_lumber:linea'] or { cola = 0 }
end

-- ── El parque de troncos ──────────────────────────────────────────────────

local HUECOS_PARQUE = 6

--- Un punto en el marco de una máquina (rumbo de GTA).
local function EnMarco(c, o)
    local r = math.rad(c.w)
    local cs, sn = math.cos(r), math.sin(r)
    return vec3(c.x + o.x * cs - o.y * sn, c.y + o.x * sn + o.y * cs, c.z + o.z)
end

local function HuecoParque(i)
    return EnMarco(L.maquinas.parque, vec3(0.4 + (i - 1) * 0.6, 0.0, 0.95 + 0.29))
end

local quitados = 0          -- troncos que la grúa ya se ha llevado y el servidor aún cuenta
local function PintarParque()
    local n = math.max(0, math.min(HUECOS_PARQUE, (tonumber(Estado().cola) or 0) - quitados))
    for i = 1, HUECOS_PARQUE do
        local quiero = i <= n
        if quiero and not parque[i] then
            if Monte.Cargar(LOG) then
                local p = HuecoParque(i)
                local e = CreateObjectNoOffset(LOG, p.x, p.y, p.z, false, false, false)
                SetEntityHeading(e, L.maquinas.parque.w)
                FreezeEntityPosition(e, true)
                parque[i] = Rastro.Marcar(e)
            end
        elseif not quiero and parque[i] then
            Monte.Borrar(parque[i])
            parque[i] = nil
        end
    end
end

local enMarcha = {}
local function Pintar()
    if not montada then return end
    PintarParque()
end

AddStateBagChangeHandler('origen_lumber:linea', 'global', function()
    SetTimeout(0, Pintar)
end)

local decorado = {}
local parqueEn

--- Para el editor: todo a donde diga Config.Linea ahora mismo.
Linea = Linea or {}
function Linea.Recolocar()
    if not montada then return end
    for nombre, c in pairs(L.maquinas) do
        if ids[nombre] then PL:Colocar(ids[nombre], c.xyz, c.w) end
    end
    for i, d in ipairs(L.decorado or {}) do
        local e = decorado[i]
        if e and DoesEntityExist(e) then
            SetEntityCoordsNoOffset(e, d[2].x, d[2].y, d[2].z, false, false, false)
            SetEntityHeading(e, d[2].w + 0.0)
        end
    end
    -- Los troncos del parque, solo si se ha movido el parque.
    local c = L.maquinas.parque
    if not parqueEn or #(parqueEn.xyz - c.xyz) > 0.001 or parqueEn.w ~= c.w then
        parqueEn = c
        for i, e in pairs(parque) do Monte.Borrar(e) parque[i] = nil end
        PintarParque()
    end
end

local function Montar()
    montada = true
    for nombre, c in pairs(L.maquinas) do
        ids[nombre] = PL:Crear(nombre, c.xyz, c.w)
    end
    for i, d in ipairs(L.decorado or {}) do
        local hash = GetHashKey(d[1])
        if Monte.Cargar(hash) then
            local c = d[2]
            local e = CreateObjectNoOffset(hash, c.x, c.y, c.z, false, false, false)
            SetEntityHeading(e, c.w + 0.0)
            if not d[1]:find('^origen_') then PlaceObjectOnGroundProperly(e) end
            FreezeEntityPosition(e, true)
            decorado[i] = Rastro.Marcar(e)
        end
    end
    Pintar()
end

local function Desmontar()
    montada = false
    for _, id in pairs(ids) do PL:Borrar(id) end
    for i, e in pairs(parque) do Monte.Borrar(e) parque[i] = nil end
    for _, e in pairs(decorado) do Monte.Borrar(e) end
    decorado = {}
    ids, enMarcha, quitados = {}, {}, 0
end

CreateThread(function()
    while true do
        local d = #(GetEntityCoords(cache.ped) - L.centro)
        -- Tras un restart los modelos tardan un momento en registrarse.
        if d < 220.0 and not montada and IsModelInCdimage(GetHashKey('origen_as_sierra')) then
            Montar()
        elseif d > 280.0 and montada then
            Desmontar()
        end
        Wait(montada and 5000 or 2000)
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then Desmontar() end
end)

-- ── La grúa ───────────────────────────────────────────────────────────────

--- Un punto del mundo en el marco de la grúa (x a lo largo de la viga).
local function EnGrua(p)
    local c = L.maquinas.grua
    local r = math.rad(c.w)
    local dx, dy = p.x - c.x, p.y - c.y
    return dx * math.cos(r) + dy * math.sin(r), -dx * math.sin(r) + dy * math.cos(r), p.z - c.z
end

--- Los dos cables del carro a la pinza (mientras se mueve la grúa).
local cables = false
local function Cables(id)
    if cables then return end
    cables = true
    CreateThread(function()
        while cables and ids.grua == id do
            local carro, pinza = PL:Entidad(id, 'carro'), PL:Entidad(id, 'pinza')
            if carro and pinza then
                for _, x in ipairs({ -0.35, 0.35 }) do
                    local a = GetOffsetFromEntityInWorldCoords(carro, x, 0.0, -0.45)
                    local b = GetOffsetFromEntityInWorldCoords(pinza, x, 0.0, 0.6)
                    DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, 30, 30, 30, 255)
                end
            end
            Wait(0)
        end
        cables = false
    end)
end

local function Grua(ms)
    local id = ids.grua
    if not id then return end
    local notas = PL:Notas('grua') or {}
    local zp = (notas.z_pinza or 6.4) - 0.55          -- centro del tronco con la pinza arriba del todo
    -- Coger del último hueco ocupado del parque y dejar en la entrada de la descortezadora.
    local n = math.max(1, math.min(HUECOS_PARQUE, (tonumber(Estado().cola) or 0) + 1 - quitados))
    local desde = HuecoParque(n)
    local hasta = PL:Punto(ids.descortezadora, 'entrada')
    if not desde or not hasta then return end
    local x1, _, z1 = EnGrua(desde)
    local x2, _, z2 = EnGrua(hasta)
    local t = ms / 1000
    enMarcha.grua = true
    PL:Marcha(id, true)
    Cables(id)
    PL:Mover(id, 'carro', x1, t * 0.18)
    Wait(math.floor(ms * 0.19))
    PL:Mover(id, 'pinza', z1 - zp, t * 0.12)
    Wait(math.floor(ms * 0.13))
    -- Coge el tronco
    quitados = quitados + 1
    PintarParque()
    PL:Mostrar(id, 'tronco', true)
    PL:Mover(id, 'pinza', 0.0, t * 0.12)
    Wait(math.floor(ms * 0.13))
    PL:Mover(id, 'carro', x2, t * 0.2)
    Wait(math.floor(ms * 0.21))
    PL:Mover(id, 'pinza', z2 - zp, t * 0.1)
    Wait(math.floor(ms * 0.11))
    PL:Mostrar(id, 'tronco', false)
    PL:Mover(id, 'pinza', 0.0, t * 0.1)
    Wait(math.floor(ms * 0.11))
    PL:Marcha(id, false)
    cables = false
    enMarcha.grua = nil
    quitados = math.max(0, quitados - 1)
end

-- ── Descortezadora y sierra ───────────────────────────────────────────────

local function Descortezar(ms)
    local id = ids.descortezadora
    if not id then return end
    local rec = (PL:Notas('descortezadora') or {}).recorrido or 7.2
    -- Sigue hasta el carro de la sierra si está en línea detrás (la U).
    local a, b = PL:Punto(id, 'entrada'), ids.sierra and PL:Punto(ids.sierra, 'entrada')
    if a and b and #(b.xy - a.xy) < rec + 6.0 then rec = #(b.xy - a.xy) end
    PL:Mover(id, 'tronco', 0.0, 0.0)
    PL:Mostrar(id, 'tronco', true)
    PL:Marcha(id, true)
    PL:Efecto(id, 'astillas', true)
    PL:Efecto(id, 'corteza', true)
    PL:Mover(id, 'tronco', rec, ms / 1000)
    Wait(ms)
    PL:Mostrar(id, 'tronco', false)
    PL:Efecto(id, 'astillas', false)
    PL:Efecto(id, 'corteza', false)
    PL:Marcha(id, false)
end

local function Serrar(ms)
    local id = ids.sierra
    if not id then return end
    local notas = PL:Notas('sierra') or {}
    local fin, tabla = notas.carro_fin or 6.4, notas.tabla_fin or 4.6
    -- La tabla sale por los rodillos hasta la apiladora si está detrás.
    local t0, t1 = PL:Punto(id, 'tabla'), ids.apiladora and PL:Punto(ids.apiladora, 'entrada')
    if t0 and t1 and #(t1.xy - t0.xy) < tabla + 8.0 then tabla = #(t1.xy - t0.xy) end
    local paso = ms / 4
    PL:Mover(id, 'carro', 0.0, 0.0)
    PL:Mostrar(id, 'tronco', true)
    PL:Marcha(id, true)
    for _ = 1, 2 do
        PL:Efecto(id, 'serrin', true)
        PL:Mover(id, 'carro', fin, paso / 1000)
        Wait(math.floor(paso * 0.6))
        -- Sale la tabla por los rodillos
        PL:Mover(id, 'tabla', 0.0, 0.0)
        PL:Mostrar(id, 'tabla', true)
        PL:Mover(id, 'tabla', tabla, paso * 1.2 / 1000)
        Wait(math.floor(paso * 0.4))
        PL:Efecto(id, 'serrin', false)
        PL:Mover(id, 'carro', 0.0, paso * 0.8 / 1000)
        Wait(math.floor(paso))
        PL:Mostrar(id, 'tabla', false)
    end
    PL:Mostrar(id, 'tronco', false)
    PL:Marcha(id, false)
end

-- Cada tronco: grúa, descortezadora y sierra en cadena. Van solapados con
-- el siguiente (el servidor manda uno cada L.tronco segundos).
RegisterNetEvent('origen_lumber:linea', function(ms, ultimo)
    if GetInvokingResource() or not montada then return end
    ms = math.max(6000, tonumber(ms) or 12000)
    CreateThread(function()
        local t0 = GetGameTimer()
        Grua(math.floor(ms * 0.7))
        Descortezar(math.floor(ms * 0.35))
        Serrar(math.floor(ms * 0.9))
        Pintar()
        if ultimo then
            -- Mismo reloj que el servidor (HastaSecadero): el paquete sale
            -- 1,95 pasos después del tronco.
            Wait(math.max(0, math.floor(ms * 1.95) - (GetGameTimer() - t0)))
            Paquete()
        end
    end)
end)

-- ── El paquete: apiladora → cinta → secadero ─────────────────────────────

--[[ La apiladora enseña el paquete hecho (1,5 s), sale de lado por los
     rodillos a la esquina de la cinta (2 s) y la banda lo sube hasta dentro
     del secadero (L.cinta s): la persiana se abre antes y se cierra detrás. ]]
local vueltaPaquete = 0
Paquete = function()
    local api, cin, sec = ids.apiladora, ids.cinta, ids.secadero
    if not (api and cin and sec) then return end
    vueltaPaquete = vueltaPaquete + 1
    local mia = vueltaPaquete
    local function Sigue() return montada and ids.cinta == cin and vueltaPaquete == mia end
    -- En la apiladora, en el hueco de fuera
    PL:Mostrar(api, 'pila3', true)
    Wait(1500)
    if not Sigue() then return end
    -- De lado a la esquina de la cinta: sale de encima del hueco de la apiladora
    local notas = PL:Notas('cinta') or {}
    local lado = notas.lado or 2.6
    local desde = PL:Punto(api, 'salida')
    local esquina = GetOffsetFromEntityInWorldCoords(PL:Entidad(cin), 0.0, 0.0, 0.0)
    local extra = desde and math.max(0.0, #(desde.xy - esquina.xy) - lado) or 0.0
    PL:Mostrar(api, 'pila3', false)
    PL:Mover(cin, 'lado', -extra, 0.0)
    PL:Mostrar(cin, 'lado', true)
    PL:Mover(cin, 'lado', lado, 2.0)
    Wait(2000)
    if not Sigue() then return end
    PL:Mostrar(cin, 'lado', false)
    PL:Mover(cin, 'lado', 0.0, 0.0)
    -- Por la banda hasta dentro del secadero
    local dentro = PL:Punto(sec, 'dentro')
    local largo = dentro and #(dentro.xy - esquina.xy) or (notas.largo or 14.0)
    local s = (L.cinta or 14) + 0.0
    PL:Mover(cin, 'paquete', 0.0, 0.0)
    PL:Mostrar(cin, 'paquete', true)
    PL:Marcha(cin, true)
    PL:Mover(cin, 'paquete', largo, s)
    -- La persiana se abre cuando el paquete va por la mitad
    SetTimeout(math.floor(s * 400), function()
        if ids.secadero ~= sec then return end
        PL:Mover(sec, 'puerta', (PL:Notas('secadero') or {}).puerta or 3.6, 2.5)
        PL:Marcha(sec, true)
        PL:Efecto(sec, 'vapor1', true)
        PL:Efecto(sec, 'vapor2', true)
    end)
    Wait(math.floor(s * 1000))
    if not Sigue() then return end
    PL:Mostrar(cin, 'paquete', false)
    PL:Mover(cin, 'paquete', 0.0, 0.0)
    PL:Marcha(cin, false)
    PL:Mover(sec, 'puerta', 0.0, 2.5)
    SetTimeout(20000, function()
        if ids.secadero == sec and vueltaPaquete == mia then
            PL:Efecto(sec, 'vapor1', false)
            PL:Efecto(sec, 'vapor2', false)
            PL:Marcha(sec, false)
        end
    end)
end
