--[[ ── Las máquinas de la cooperativa (cliente) ───────────────────────────────

     La línea de lavado, la báscula y los silos (Maquinas.*, client/maquina.lua)
     se crean al acercarse a la cooperativa y se animan igual para todos con lo
     que el servidor manda al entregar en la báscula (server/procesado.lua):
       · lavar: la verdura cae en la tolva, sube por el elevador, gira el
         tambor bajo el agua, corre por la mesa y sale una caja al palé;
       · ensilar: el grano se amontona en el foso, sube por el elevador
         (baliza y polvo arriba) y el visor del silo marca el nivel nuevo.
     La báscula enseña el peso de lo que tiene encima (tú con una caja o la
     camioneta con su carga) en el marcador de la caseta. ]]

local P = Config.Planta
if not P then return end

-- Las luces (foco de noche, baliza) se dibujan en cada fotograma: solo para
-- quien está de jornada o mientras la máquina trabaja.
PL:SoloLucesSi(function(m) return m.marcha or LocalPlayer.state.granjaJornada == true end)

local ids = {}
local montada = false

local function Estado()
    return GlobalState['origen_farming:planta'] or { cajas = 0, silo = { 0.3, 0.2 } }
end

local enMarcha = {}

local function Pintar()
    if not montada then return end
    local e = Estado()
    if ids.lavadora and not enMarcha.lavadora then
        for k = 1, P.cajas do PL:Mostrar(ids.lavadora, 'caja' .. k, k <= (tonumber(e.cajas) or 0)) end
    end
    if ids.silo and not enMarcha.silo then
        local max = (PL:Notas('silo') or {}).nivel_max or 7.6
        for k = 1, 2 do PL:Mover(ids.silo, 'nivel' .. k, max * (tonumber(e.silo and e.silo[k]) or 0), 2.0) end
    end
end

AddStateBagChangeHandler('origen_farming:planta', 'global', function()
    SetTimeout(0, Pintar)
end)

local decorado = {}

--- Para el editor: mover una máquina o el rótulo a donde diga P.maquinas / P.decorado.
Planta = {}
function Planta.Entidad(nombre) return ids[nombre] and PL:Entidad(ids[nombre]) or nil end
function Planta.Recolocar()
    if not montada then return end
    for nombre, c in pairs(P.maquinas) do
        if ids[nombre] then PL:Colocar(ids[nombre], c.xyz, c.w) end
    end
    for i, d in ipairs(P.decorado or {}) do
        local e = decorado[i]
        if e and DoesEntityExist(e) then
            SetEntityCoordsNoOffset(e, d[2].x, d[2].y, d[2].z, false, false, false)
            SetEntityHeading(e, d[2].w + 0.0)
        end
    end
end

local function Montar()
    montada = true
    for nombre, c in pairs(P.maquinas) do
        ids[nombre] = PL:Crear(nombre, c.xyz, c.w)
    end
    for i, d in ipairs(P.decorado or {}) do
        local hash = GetHashKey(d[1])
        RequestModel(hash)
        local fin = GetGameTimer() + 5000
        while not HasModelLoaded(hash) and GetGameTimer() < fin do Wait(0) end
        if HasModelLoaded(hash) then
            local c = d[2]
            local e = CreateObjectNoOffset(hash, c.x, c.y, c.z, false, false, false)
            SetEntityHeading(e, c.w + 0.0)
            FreezeEntityPosition(e, true)
            SetModelAsNoLongerNeeded(hash)
            decorado[i] = e
        end
    end
    Pintar()
end

local function Desmontar()
    montada = false
    for _, id in pairs(ids) do PL:Borrar(id) end
    for _, e in pairs(decorado) do if DoesEntityExist(e) then DeleteEntity(e) end end
    ids, enMarcha, decorado = {}, {}, {}
end

CreateThread(function()
    while true do
        local d = #(GetEntityCoords(cache.ped) - P.centro)
        -- Tras un restart los modelos tardan un momento en registrarse.
        if d < 220.0 and not montada and IsModelInCdimage(GetHashKey('origen_gr_lavadora')) then
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

-- ── Lavar ─────────────────────────────────────────────────────────────────

local vueltaLav = 0
RegisterNetEvent('origen_farming:lavar', function(retraso, ms, nuevas)
    if GetInvokingResource() then return end
    vueltaLav = vueltaLav + 1
    local mia = vueltaLav
    SetTimeout(math.max(0, tonumber(retraso) or 0), function()
        local id = ids.lavadora
        if not id or vueltaLav ~= mia then return end
        ms = math.max(4000, tonumber(ms) or 20000)
        enMarcha.lavadora = true
        CreateThread(function()
            local function Sigue() return ids.lavadora == id and vueltaLav == mia end
            -- Cae a la tolva
            PL:Mostrar(id, 'carga', true)
            PL:Mover(id, 'carga', -0.3, 0.0)
            PL:Mover(id, 'carga', 0.0, 1.2)
            Wait(1300)
            if not Sigue() then return end
            PL:Marcha(id, true)
            PL:Efecto(id, 'agua1', true)
            PL:Efecto(id, 'agua2', true)
            PL:Efecto(id, 'salpica', true)
            -- La tolva se vacía mientras la línea trabaja
            PL:Mover(id, 'carga', -0.3, ms / 1000 * 0.6)
            Wait(math.floor(ms * 0.8))
            if not Sigue() then return end
            PL:Mostrar(id, 'carga', false)
            -- Cajas nuevas al palé, una a una
            local e = Estado()
            local hay = tonumber(e.cajas) or 0
            for k = 1, math.min(nuevas or 1, P.cajas - hay) do
                PL:Mostrar(id, 'caja' .. (hay + k), true)
                Wait(400)
            end
            Wait(math.floor(ms * 0.2))
            PL:Efecto(id, 'agua1', false)
            PL:Efecto(id, 'agua2', false)
            PL:Efecto(id, 'salpica', false)
            PL:Marcha(id, false)
            enMarcha.lavadora = nil
            SetTimeout(1500, Pintar)
        end)
    end)
end)

-- ── Ensilar ───────────────────────────────────────────────────────────────

local vueltaSilo = 0
RegisterNetEvent('origen_farming:ensilar', function(retraso, ms, silo, nivel)
    if GetInvokingResource() then return end
    vueltaSilo = vueltaSilo + 1
    local mia = vueltaSilo
    SetTimeout(math.max(0, tonumber(retraso) or 0), function()
        local id = ids.silo
        if not id or vueltaSilo ~= mia then return end
        ms = math.max(4000, tonumber(ms) or 18000)
        silo = silo == 2 and 2 or 1
        enMarcha.silo = true
        CreateThread(function()
            local function Sigue() return ids.silo == id and vueltaSilo == mia end
            PL:Mostrar(id, 'monton', true)
            PL:Mover(id, 'monton', -0.9, 0.0)
            PL:Mover(id, 'monton', -0.25, 1.5)
            PL:Efecto(id, 'polvo_foso', true)
            Wait(1600)
            if not Sigue() then return end
            PL:Marcha(id, true)
            PL:Efecto(id, 'polvo_silo' .. silo, true)
            local max = (PL:Notas('silo') or {}).nivel_max or 7.6
            PL:Mover(id, 'nivel' .. silo, max * math.min(1.0, tonumber(nivel) or 0), ms / 1000 * 0.8)
            PL:Mover(id, 'monton', -0.9, ms / 1000 * 0.8)
            Wait(math.floor(ms * 0.85))
            if not Sigue() then return end
            PL:Mostrar(id, 'monton', false)
            PL:Efecto(id, 'polvo_foso', false)
            PL:Efecto(id, 'polvo_silo' .. silo, false)
            PL:Marcha(id, false)
            enMarcha.silo = nil
            SetTimeout(1500, Pintar)
        end)
    end)
end)

-- ── El marcador de la báscula ─────────────────────────────────────────────

--[[ Solo cuando hay alguien en la plataforma: el peso de lo que lleva en las
     manos (la caja) o, si es la camioneta, el de su carga. Unos 0,45 kg por
     unidad, más 2 kg de cada caja, 80 kg de quien está encima y 1.900 kg
     de la camioneta vacía. ]]
--[[ En pegatina (07/10): pieza gris clara (220,221,224) con canto negro y
     sombra dura, filete rosa a la izquierda y la cifra en tinta negra. Era
     texto verde lima de GTA. El rosa lo cambia tema.lua en Nación. ]]
local function Texto3D(p, texto)
    local ok, x, y = GetScreenCoordFromWorldCoord(p.x, p.y, p.z)
    if not ok then return end
    local escala = 0.5
    -- El ancho del texto para medir la pieza.
    SetTextFont(4)
    SetTextScale(0.0, escala)
    BeginTextCommandGetWidth('STRING')
    AddTextComponentSubstringPlayerName(texto)
    local ancho = EndTextCommandGetWidth(true)
    local alto = GetRenderedCharacterHeight(escala, 4)
    -- Un píxel (sobre 1080 de alto) en cada eje, para que el canto sea igual.
    local py = 1.0 / 1080.0
    local px = py / GetAspectRatio(false)
    local w, h = ancho + 22 * px, alto + 12 * py
    local cy = y + alto * 0.5 + 2 * py
    -- Sombra dura abajo a la derecha, canto negro de 1,5 px, pieza y filete rosa.
    DrawRect(x + 3 * px, cy + 3 * py, w + 3 * px, h + 3 * py, 0, 0, 0, 255)
    DrawRect(x, cy, w + 3 * px, h + 3 * py, 0, 0, 0, 255)
    DrawRect(x, cy, w, h, 220, 221, 224, 255)
    DrawRect(x - w * 0.5 + 2 * px, cy, 4 * px, h, 216, 27, 85, 255)
    SetTextFont(4)
    SetTextScale(0.0, escala)
    SetTextColour(0, 0, 0, 255)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(texto)
    EndTextCommandDisplayText(x + 2 * px, y)
end

CreateThread(function()
    while true do
        local espera = 1000
        local id = ids.bascula
        if id then
            local c = P.maquinas.bascula
            local pos = GetEntityCoords(cache.ped)
            if #(pos.xy - c.xy) < 25.0 then
                espera = 250
                local kg
                local veh = cache.vehicle
                local sobre = veh and veh ~= 0 and GetEntityCoords(veh) or pos
                local dx, dy = sobre.x - c.x, sobre.y - c.y
                local r = math.rad(-c.w)
                local lx, ly = dx * math.cos(r) - dy * math.sin(r), dx * math.sin(r) + dy * math.cos(r)
                if math.abs(lx) < 1.9 and math.abs(ly) < 4.3 then
                    if veh and veh ~= 0 then
                        kg = 1900.0
                        for _, caja in ipairs(Entity(veh).state.granjaCajas or {}) do
                            local cap = Config.Carga[caja.t] and Config.Carga[caja.t].capacidad or 0
                            kg = kg + 2.0 + (tonumber(caja.l) or 0) * cap * 0.45
                        end
                    else
                        kg = 80.0
                        local caja = LocalPlayer.state.granjaCarga
                        if caja and caja.tipo and caja.tipo ~= 'paca' then
                            local cap = Config.Carga[caja.tipo] and Config.Carga[caja.tipo].capacidad or 0
                            kg = kg + 2.0 + (tonumber(caja.lleno) or 0) * cap * 0.45
                        end
                    end
                end
                if kg then
                    espera = 0
                    local m = PL:Punto(id, 'marcador')
                    if m then Texto3D(m + vec3(0.0, 0.0, 0.0), ('%.1f kg'):format(kg)) end
                end
            end
        end
        Wait(espera)
    end
end)
