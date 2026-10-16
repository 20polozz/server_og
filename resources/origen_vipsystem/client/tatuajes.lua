--[[ ═══════════════════════════════════════════════════════════════════════
     LOS TATUAJES DE LA TIENDA, EN EL PERSONAJE (13/10)

     Qué lleva puesto lo sabe y lo manda el SERVIDOR (server/tienda/tatuajes.lua):
     una lista de decoraciones { c = colección, b = nombre sin _m/_f, n = pasadas }.
     Aquí solo se le pasa al tatuador (origen_tattoos), que es quien repinta al
     personaje cada segundo: exports.origen_tattoos:PonerTatuajesExtra. Así los de
     la tienda conviven con los del tatuador y no se borran entre ellos.

     Ni origen_tattoos ni origen_tatuajes son `dependency` (pueden no estar): se
     mira si están arrancados. Sin ellos, simplemente no se pinta nada.
   ═══════════════════════════════════════════════════════════════════════ ]]

local TATUADOR, PACK = 'origen_tattoos', 'origen_tatuajes'
local YO = GetCurrentResourceName()
local ultima = {}
local avisado = false

local function Pintar(lista)
    ultima = type(lista) == 'table' and lista or {}
    if GetResourceState(TATUADOR) ~= 'started' then return end

    local extras = {}
    if GetResourceState(PACK) == 'started' then
        for _, t in ipairs(ultima) do
            if type(t) == 'table' and type(t.c) == 'string' and type(t.b) == 'string' then
                extras[#extras + 1] = { collection = t.c, base = t.b, opacity = tonumber(t.n) or 1 }
            end
        end
    end

    local bien = pcall(function() exports[TATUADOR]:PonerTatuajesExtra(YO, extras) end)
    if not bien and not avisado then
        avisado = true
        -- un origen_tattoos de antes del 13/10 (sin reiniciar): no sabe pintar tatuajes de otro recurso
        print('^3[origen_vipsystem] tatuajes: origen_tattoos no tiene PonerTatuajesExtra (hay que reiniciarlo): los tatuajes de la tienda no se verán hasta entonces.^7')
    end
end

RegisterNetEvent('origen_vipsystem:client:tatuajes', function(lista)
    Pintar(lista)
end)

--- Pregunta al servidor qué lleva. Recién cargado el personaje puede que aún no lo conozca: insiste un poco.
local pidiendo = false
local function Pedir()
    if pidiendo then return end
    pidiendo = true
    CreateThread(function()
        for _ = 1, 6 do
            local res = lib.callback.await('origen_vipsystem:server:tienda:tatuajes:puestos', 8000)
            if res and res.ok then
                Pintar(res.lista)
                break
            end
            Wait(2500)
        end
        pidiendo = false
    end)
end

RegisterNetEvent('qbx_core:client:playerLoaded', Pedir)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', Pedir)

-- Otro personaje: los del anterior no se quedan pintados
local function Vaciar() Pintar({}) end
RegisterNetEvent('qbx_core:client:playerLoggedOut', Vaciar)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', Vaciar)

-- Si este recurso se reinicia con el jugador dentro
CreateThread(function()
    Wait(1500)
    if LocalPlayer.state.isLoggedIn then Pedir() end
end)

-- Si se reinicia el tatuador (olvida lo que se le pasó) o arranca el pack: se le vuelve a dar
AddEventHandler('onClientResourceStart', function(recurso)
    if recurso ~= TATUADOR and recurso ~= PACK then return end
    Wait(2000)
    Pintar(ultima)
end)
