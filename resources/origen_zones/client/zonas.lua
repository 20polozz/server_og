--[[ ── En qué zona estás ──────────────────────────────────────────────────────

     Un solo hilo mira dónde está el jugador y decide qué reglas mandan ahora
     mismo. Nadie más pregunta: las reglas se enteran por aquí.

     Dos zonas pueden pisarse. Cuando pasa, para cada regla gana la zona de más
     prioridad; a igual prioridad, la última creada. Así una «zona segura»
     grande puede llevar dentro un descampado donde sí se pelea, sin tener que
     recortar el polígono de fuera. ]]

Zonas = {
    todas = {},       -- las que ha mandado el servidor
    dentro = {},      -- [id] = zona, en las que estás ahora
    reglas = {},      -- [clave] = { ajustes = ..., zona = ... }, las que mandan
}

local avisoSonando = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- LO QUE MANDA EL SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════

local function Guardar(lista)
    local nuevas = {}
    for _, zona in ipairs(lista or {}) do
        nuevas[zona.id] = Geo.Preparar(zona)
    end
    Zonas.todas = nuevas

    if Mapa and Mapa.Repintar then Mapa.Repintar() end
end

RegisterNetEvent('origen_zones:zonas', function(lista)
    Guardar(lista)
    -- Una zona puede haber cambiado de forma debajo de los pies: se vuelve a
    -- mirar en la vuelta siguiente del hilo, que llega enseguida.
end)

CreateThread(function()
    Wait(1500)
    local lista = lib.callback.await('origen_zones:dame', false)
    if lista then Guardar(lista) end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- QUÉ REGLAS MANDAN AHORA
-- ═══════════════════════════════════════════════════════════════════════════

-- De las zonas que pisas, la lista ordenada de más mandona a menos.
local function ZonasDeAhora(x, y, z)
    local hora = Geo.HoraDelJuego()
    local dentro = {}

    for _, zona in pairs(Zonas.todas) do
        if Geo.Activa(zona, hora) and Geo.Dentro(zona, x, y, z) then
            dentro[#dentro + 1] = zona
        end
    end

    table.sort(dentro, function(a, b)
        if a.prioridad ~= b.prioridad then return a.prioridad > b.prioridad end
        return a.id > b.id
    end)

    return dentro
end

local function ReglasDe(lista)
    local reglas = {}
    for _, zona in ipairs(lista) do
        for clave, ajustes in pairs(zona.reglas or {}) do
            if reglas[clave] == nil then
                reglas[clave] = { ajustes = ajustes, zona = zona }
            end
        end
    end
    return reglas
end

-- ¿Han cambiado los ajustes de una regla que ya estaba puesta? Si el admin
-- toca el límite de velocidad mientras estás dentro, hay que volver a
-- aplicarla, no dejarla como estaba.
local function MismoAjuste(a, b)
    if a == b then return true end
    if type(a) ~= 'table' or type(b) ~= 'table' then return false end

    for k, v in pairs(a) do
        if not MismoAjuste(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ENTRAR Y SALIR
-- ═══════════════════════════════════════════════════════════════════════════

local function Aviso(texto, tipo)
    if not texto or texto == '' then return end
    if avisoSonando[texto] and GetGameTimer() < avisoSonando[texto] then return end
    avisoSonando[texto] = GetGameTimer() + 3000

    lib.notify({ description = texto, type = tipo or 'inform', duration = 4500 })
end

Zonas.Aviso = Aviso

local function AlEntrar(zona)
    Zonas.dentro[zona.id] = zona
    Aviso(zona.aviso_entrar, 'inform')
    TriggerEvent('origen_zones:entras', zona)
end

local function AlSalir(zona)
    Zonas.dentro[zona.id] = nil
    Aviso(zona.aviso_salir, 'inform')
    TriggerEvent('origen_zones:sales', zona)
end

CreateThread(function()
    while true do
        Wait(Config.Ritmo.cliente)

        local ped = PlayerPedId()
        local c = GetEntityCoords(ped)

        local lista = ZonasDeAhora(c.x, c.y, c.z)

        -- Entradas y salidas, para los avisos y para quien nos escuche.
        local ahora = {}
        for _, zona in ipairs(lista) do ahora[zona.id] = zona end

        for id, zona in pairs(Zonas.dentro) do
            if not ahora[id] then AlSalir(zona) end
        end
        for id, zona in pairs(ahora) do
            if not Zonas.dentro[id] then AlEntrar(zona) end
        end

        -- Y las reglas que mandan.
        local nuevas = ReglasDe(lista)
        local viejas = Zonas.reglas

        for clave, puesta in pairs(viejas) do
            local nueva = nuevas[clave]
            if not nueva then
                Reglas.Quitar(clave)
            elseif not MismoAjuste(puesta.ajustes, nueva.ajustes) then
                Reglas.Quitar(clave)
                Reglas.Poner(clave, nueva.ajustes, nueva.zona)
            end
        end

        for clave, nueva in pairs(nuevas) do
            if not viejas[clave] then
                Reglas.Poner(clave, nueva.ajustes, nueva.zona)
            end
        end

        Zonas.reglas = nuevas
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ENCHUFES PARA OTROS RECURSOS
-- ═══════════════════════════════════════════════════════════════════════════

-- Los ajustes de una regla si manda aquí, o nil. Es lo que hay que preguntar
-- desde otro recurso: `if exports.origen_zones:ReglaActiva('zona_segura') then`
exports('ReglaActiva', function(clave)
    local puesta = Zonas.reglas[clave]
    return puesta and puesta.ajustes or nil
end)

exports('ZonaDeLaRegla', function(clave)
    local puesta = Zonas.reglas[clave]
    return puesta and puesta.zona or nil
end)

exports('ZonasDeAhora', function()
    local lista = {}
    for _, zona in pairs(Zonas.dentro) do lista[#lista + 1] = zona end
    return lista
end)

exports('EnZona', function(id)
    return Zonas.dentro[id] ~= nil
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- LO QUE PIDE EL SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent('origen_zones:aviso', function(texto, tipo)
    Aviso(texto, tipo == 'error' and 'error' or tipo == 'success' and 'success' or 'inform')
end)

-- Sacar a quien no debería estar. Se le deja en el suelo, justo fuera del
-- borde por el que venía, con su coche si iba conduciendo.
RegisterNetEvent('origen_zones:echar', function(x, y)
    local ped = PlayerPedId()
    local entidad = ped

    if IsPedInAnyVehicle(ped, false) then
        local coche = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(coche, -1) == ped then entidad = coche end
    end

    local suelo, z = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, 1000.0, false)
    SetEntityCoords(entidad, x + 0.0, y + 0.0, (suelo and z or 30.0) + 1.0, false, false, false, false)
end)
