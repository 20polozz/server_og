-- ========================================
-- CLIENTE: LA POLICIA DETRAS DE LAS CARRERAS ILEGALES
-- ========================================
--[[ La mitad de cliente de server/policia.lua. Dos cosas, ninguna por
     fotograma:

     - AGENTE DE SERVICIO: pinta en el mapa (registro de origen_map, que es lo
       que leen el minimapa y el mapa grande; un blip del juego no se ve) el
       circulo donde anda el pelotón de una carrera ilegal. Lo manda el
       servidor, solo a policias de servicio; aqui no se decide nada. Si deja
       de llegar (se cae el servidor del recurso, sale de servicio sin aviso),
       se quita solo.
     - CORREDOR: mientras corre una carrera vigilada, mira una vez por segundo
       si origen_police le tiene esposado (exports.origen_police:IsHandcuffed,
       client/interaction.lua) y, si es asi, lo dice al servidor, que lo
       comprueba antes de sacarle de la carrera. ]]

local CFG = Config.Policia or {}

-- ── Agente: el circulo del pelotón ─────────────────────────────────────────
local circulos = {}   -- [raceId] = GetGameTimer() de la ultima posicion
local vigilando = false

local function Clave(raceId) return 'policia_carrera_' .. tostring(raceId) end

local function Quitar(raceId)
    circulos[raceId] = nil
    OrigenMapa.Quitar(Clave(raceId))
end

-- Si el servidor deja de mandar posiciones, el circulo no se queda clavado
local function VigilarCaducados()
    if vigilando then return end
    vigilando = true
    CreateThread(function()
        local caduca = (math.max(2, tonumber(CFG.Intervalo) or 5) * 3 + 10) * 1000
        while next(circulos) do
            Wait(3000)
            local ahora = GetGameTimer()
            for raceId, t in pairs(circulos) do
                if ahora - t > caduca then Quitar(raceId) end
            end
        end
        vigilando = false
    end)
end

RegisterNetEvent('origen_racing:policia:peloton', function(d)
    if type(d) ~= 'table' or not d.raceId or type(d.centro) ~= 'vector3' and type(d.centro) ~= 'table' then return end
    local c = d.centro
    OrigenMapa.Poner(Clave(d.raceId), {
        x = c.x + 0.0, y = c.y + 0.0, z = (c.z or 0.0) + 0.0,
        cat = 'racing',
        nombre = ('Carrera ilegal · %d vehículos · %s'):format(tonumber(d.n) or 0, d.estrellas or ''),
        radio = (tonumber(d.radio) or 300.0) + 0.0,
        color = '#d81b55',
        -- Como los avisos del dispatch: que salga en el minimapa aunque quede lejos
        prioridad = 10,
    })
    circulos[d.raceId] = GetGameTimer()
    VigilarCaducados()
end)

RegisterNetEvent('origen_racing:policia:quitar', function(raceId)
    if raceId then Quitar(raceId) end
end)

-- ── Corredor: ¿me han esposado? ───────────────────────────────────────────
local corriendo = nil   -- raceId de la carrera vigilada que corro

local function Esposado()
    if GetResourceState('origen_police') ~= 'started' then return false end
    local ok, r = pcall(function() return exports.origen_police:IsHandcuffed() end)
    return ok and r == true
end

RegisterNetEvent('origen_racing:policia:corres', function(raceId)
    if (CFG.Detencion or {}).Enabled == false then return end
    corriendo = raceId
    CreateThread(function()
        local mia = raceId
        local avisado = false
        while corriendo == mia do
            Wait(1000)
            if corriendo ~= mia then break end
            if Esposado() then
                if not avisado then
                    avisado = true
                    TriggerServerEvent('origen_racing:policia:esposado', mia)
                end
            else
                avisado = false   -- se solto (prueba de habilidad): si vuelven, otra vez
            end
        end
    end)
end)

RegisterNetEvent('origen_racing:policia:yaNo', function(raceId)
    if corriendo == raceId then corriendo = nil end
end)

-- ── El calor en el hub (components/racing/NivelBusqueda.vue) ─────────────
RegisterNUICallback('policia:miCalor', function(_, cb)
    local ok, r = pcall(lib.callback.await, 'racing:policia:miCalor', false)
    cb(ok and r or { calor = 0, max = 5, activo = false })
end)

-- Cambia mientras el hub esta abierto (al acabar una carrera, al detenerte)
RegisterNetEvent('origen_racing:policia:miCalor', function(d)
    SendNUIMessage({ action = 'policiaCalor', data = d })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for raceId in pairs(circulos) do OrigenMapa.Quitar(Clave(raceId)) end
end)
