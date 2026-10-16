-- Luces de las casas (ver config/luces.lua y custom/server/luces.lua).
-- El mueble guardado es la lámpara encendida. Apagada, en cada cliente: se
-- esconde ese objeto (invisible y sin colisión, solo aquí) y se pone en su
-- sitio un objeto local con el modelo `_off`. Al encender, al revés.
-- Decorando (el modo muebles o la cinta) se ven todas encendidas, para poder
-- cogerlas y moverlas; al cerrar vuelven a como estaban, ya en su sitio nuevo.
local C = Config.Luces

Luces = {}              -- lo que llama el resto del housing (client/classes/house.lua)

local piezas = {}       -- las de la casa en la que se está: { id, zona, clave, entidad, lampara | interruptor, off, doble }
local casaActual = nil
local apagadas = {}     -- ['zona:id'] = true: lo que el servidor dice que está apagado
local ocultas = {}      -- entidad del mueble → true mientras está escondida por apagada
local menuAjeno = false
local conTexto = false
local ocupado = false
local aplicando, repetir = false, false

-- ── El catálogo ─────────────────────────────────────────────────────────
-- Lo que todavía no tiene modelo no se ofrece (los modelos van llegando).
for _, cat in ipairs(Config.Furniture or {}) do
    local items = cat.items or {}
    for q = #items, 1, -1 do
        local m = items[q].model
        if (C.Lampara(m) or C.Interruptor(m)) and not IsModelInCdimage(joaat(m)) then table.remove(items, q) end
    end
end

-- (el árbitro lo suelta si se queda enganchado: custom/client/tecla_e.lua)
AddEventHandler('origen_housing:sinMenuAjeno', function() menuAjeno = false end)

AddEventHandler('qv2:suppressHud', function(fuera)
    menuAjeno = fuera == true
end)

-- El cartel y la tecla los lleva el árbitro común (custom/client/tecla_e.lua):
-- aquí solo se ofrece la E, o se retira.
local function Texto(texto)
    if not texto then Tecla.Retirar('luces') end
end

-- El modelo apagado de una lámpara, si existe: sin él no se apaga (ni se ofrece)
local OFF = {}
local function ModeloApagado(lampara)
    if OFF[lampara.id] == nil then
        local hash = joaat(lampara.apagada)
        OFF[lampara.id] = IsModelInCdimage(hash) and hash or false
    end
    return OFF[lampara.id] or nil
end

local function Decorando()
    if Furniture and Furniture.active then return true end
    return Obra ~= nil and Obra.CintaAbierta ~= nil and Obra.CintaAbierta() == true
end

--- ¿Está ese mueble escondido porque su lámpara está apagada? (House:VigilarMuebles
--- vuelve a enseñar los muebles invisibles: estos no)
function Luces.Apagada(entidad)
    return ocultas[entidad] == true
end

-- ── Encender y apagar (aquí, a la vista) ────────────────────────────────
local function Encender(p)
    if p.doble then
        if DoesEntityExist(p.doble) then DeleteEntity(p.doble) end
        p.doble = nil
    end
    if ocultas[p.entidad] then
        ocultas[p.entidad] = nil
        if DoesEntityExist(p.entidad) then
            SetEntityVisible(p.entidad, true, false)
            SetEntityCollision(p.entidad, p.colision ~= false, p.colision ~= false)
        end
    end
end

local function Igual(a, b)
    return a and b and math.abs(a.x - b.x) < 0.001 and math.abs(a.y - b.y) < 0.001 and math.abs(a.z - b.z) < 0.001
end

-- Pone el doble apagado donde está el mueble (también si lo ha movido otro)
local function Seguir(p)
    local c, r = GetEntityCoords(p.entidad), GetEntityRotation(p.entidad, 2)
    if not Igual(c, p.c) or not Igual(r, p.r) then
        p.c, p.r = c, r
        SetEntityCoordsNoOffset(p.doble, c.x, c.y, c.z, false, false, false)
        SetEntityRotation(p.doble, r.x, r.y, r.z, 2, true)
    end
    if IsEntityVisible(p.entidad) then
        SetEntityVisible(p.entidad, false, false)
        SetEntityCollision(p.entidad, false, false)
    end
end

local function Apagar(p)
    if not HasModelLoaded(p.off) then
        RequestModel(p.off)
        local limite = GetGameTimer() + 3000
        while not HasModelLoaded(p.off) and GetGameTimer() < limite do Wait(0) end
        -- mientras cargaba puede haber cambiado todo: se mira otra vez
        if not HasModelLoaded(p.off) or p.fuera or not apagadas[p.clave] or not DoesEntityExist(p.entidad) or Decorando() then return end
    end
    local c = GetEntityCoords(p.entidad)
    local doble = CreateObjectNoOffset(p.off, c.x, c.y, c.z, false, false, false)
    SetModelAsNoLongerNeeded(p.off)
    if not doble or doble == 0 then return end
    -- primero el apagado y luego se esconde el encendido: nunca se queda el hueco
    p.colision = not GetEntityCollisionDisabled(p.entidad)
    FreezeEntityPosition(doble, true)
    SetEntityCollision(doble, p.colision, p.colision)
    p.doble, p.c, p.r = doble, nil, nil
    Seguir(p)
    ocultas[p.entidad] = true
    SetEntityVisible(p.entidad, false, false)
    SetEntityCollision(p.entidad, false, false)
end

local function Soltar(p)
    p.fuera = true
    Encender(p)
end

-- ── El repaso ───────────────────────────────────────────────────────────
local function Recoger()
    local id = currentInteriorHouseID or currentExteriorHouseID
    local house = id and House.get(id) or nil
    local casa = house and tostring(house.id) or nil
    if casa ~= casaActual then
        for _, p in ipairs(piezas) do Soltar(p) end
        piezas, apagadas = {}, {}
        local habia = casaActual
        casaActual = casa
        if casa then
            local pedida = casa
            local todas = lib.callback.await('origen_housing:luces:todas', false, casa)
            if casaActual ~= pedida then return end
            for clave, v in pairs(type(todas) == 'table' and todas or {}) do
                if type(clave) == 'string' and v == false then apagadas[clave] = true end
            end
        elseif habia then
            TriggerServerEvent('origen_housing:luces:salir')
        end
    end
    local antes, lista = {}, {}
    for _, p in ipairs(piezas) do antes[p.entidad] = p end
    if house then
        for zona, muebles in pairs({ interior = house.interiorFurniture, exterior = house.exteriorFurniture }) do
            for mid, m in pairs(muebles or {}) do
                if type(m) == 'table' and m.entity and DoesEntityExist(m.entity) then
                    local lampara = C.Lampara(m.model)
                    if lampara or C.Interruptor(m.model) then
                        local p = antes[m.entity]
                        if p then
                            antes[m.entity] = nil
                        else
                            p = { id = tostring(mid), zona = zona, clave = zona .. ':' .. tostring(mid), entidad = m.entity }
                            if lampara then
                                p.lampara, p.off = lampara, ModeloApagado(lampara)
                            else
                                p.interruptor = true
                            end
                        end
                        lista[#lista + 1] = p
                    end
                end
            end
        end
    end
    for _, p in pairs(antes) do Soltar(p) end      -- se vendió, o el housing rehízo el objeto
    piezas = lista
end

local function Aplicar()
    local decorando = Decorando()
    for _, p in ipairs(piezas) do
        if p.lampara and DoesEntityExist(p.entidad) then
            if p.doble and not DoesEntityExist(p.doble) then p.doble = nil end
            local quiere = p.off ~= nil and apagadas[p.clave] == true and not decorando
            if quiere then
                if p.doble then Seguir(p) else Apagar(p) end
            elseif p.doble or ocultas[p.entidad] then
                Encender(p)
            end
        end
    end
end

-- Una pasada entera. No se pisan dos: la que llega mientras hay otra, la repite.
local function Pasada()
    if aplicando then
        repetir = true
        return
    end
    aplicando = true
    repeat
        repetir = false
        local ok, err = pcall(function()
            Recoger()
            Aplicar()
        end)
        if not ok then print(('^1[origen_housing]^7 luces: %s'):format(tostring(err))) end
    until not repetir
    aplicando = false
end

RegisterNetEvent('origen_housing:luces:estado', function(casa, cambios)
    if tostring(casa) ~= casaActual or type(cambios) ~= 'table' then return end
    for clave, encendida in pairs(cambios) do
        if type(clave) == 'string' then
            if encendida == false then apagadas[clave] = true else apagadas[clave] = nil end
        end
    end
    Pasada()
end)

CreateThread(function()
    while true do
        Pasada()
        Wait(1000)
    end
end)

-- ── La E ────────────────────────────────────────────────────────────────
local function Pulsar(p)
    if ocupado then return end
    ocupado = true
    Texto(nil)
    local res = lib.callback.await('origen_housing:luces:pulsar', false, casaActual, p.zona, p.id)
    if type(res) ~= 'table' or not res.ok then
        Custom.Notify(type(res) == 'table' and res.aviso or 'La luz no responde', 'error', 3500)
    end
    SetTimeout(C.ritmo, function() ocupado = false end)
end

-- Lo que se puede pulsar ahora mismo: el interruptor o la lámpara de mano más
-- cercana, delante del jugador.
local function Cercana()
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 or IsPedRagdoll(ped) or IsEntityDead(ped) then return nil end
    local yo, frente = GetEntityCoords(ped), GetEntityForwardVector(ped)
    local mejor, cuanto = nil, nil
    for _, p in ipairs(piezas) do
        local vale = p.interruptor or (p.lampara.mano and p.off ~= nil)
        if vale and DoesEntityExist(p.entidad) then
            local c = GetEntityCoords(p.entidad)
            local dx, dy = c.x - yo.x, c.y - yo.y
            local d = math.sqrt(dx * dx + dy * dy)
            local tope = p.interruptor and C.alcanceInterruptor or C.alcance
            if d <= tope and math.abs(c.z - yo.z) < 2.2 and (not cuanto or d < cuanto)
                and (d < 0.6 or (dx * frente.x + dy * frente.y) / d > 0.2) then
                mejor, cuanto = p, d
            end
        end
    end
    return mejor, cuanto
end

CreateThread(function()
    while true do
        local espera = 1000
        local cerca, lejos = nil, nil
        if #piezas > 0 then
            espera = 300
            if not ocupado and not menuAjeno and not Decorando() and not currentDoorID
                and not IsNuiFocused() and not IsPauseMenuActive() then
                cerca, lejos = Cercana()
            end
        end
        if cerca then
            -- (la tecla se mira en el árbitro: aquí basta con renovar la oferta unas veces por segundo)
            espera = 150
            local p = cerca
            Tecla.Ofrecer('luces', {
                texto = p.interruptor and 'Luces de la sala' or (apagadas[p.clave] and 'Encender la luz' or 'Apagar la luz'),
                prioridad = p.interruptor and 55 or 50, dist = lejos,
                hacer = function() Pulsar(p) end,
            })
        else
            Texto(nil)
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for _, p in ipairs(piezas) do Soltar(p) end
end)
