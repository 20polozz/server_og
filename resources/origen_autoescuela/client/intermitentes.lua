--[[ ═══════════════════════════════════════════════════════════════════════
     LOS INTERMITENTES

     El servidor no tenía (20/09): el examen los exigía y no había tecla que
     los pusiera. Van aquí porque es la autoescuela la que los pide, pero
     valen SIEMPRE y en cualquier vehículo de tierra, no solo en el examen:
     un intermitente que solo existe el día del carné no se aprende.

       ←  izquierdo      →  derecho      ↓  las cuatro de avería
       (se cambian en Ajustes › Teclas › FiveM)

     Poner luces con la nativa solo se ve en ESTA pantalla, así que el estado
     viaja por el statebag `intermitentes` del coche (0 nada, 1 izquierda,
     2 derecha, 3 avería). Lo escribe el SERVIDOR, que comprueba que quien lo
     pide va al volante; aquí se aplica al momento para que la tecla responda
     y luego llega a los demás.

     El de giro se quita solo al acabar la curva (55° de rumbo) o a los 40 s,
     como la palanca de un coche de verdad. Las de avería, no.
   ═══════════════════════════════════════════════════════════════════════ ]]

local BOLSA = 'intermitentes'
local puesto, rumbo0, desde = 0, 0.0, 0

local function Aplicar(veh, n)
    SetVehicleIndicatorLights(veh, 1, n == 1 or n == 3)   -- 1 = lado izquierdo
    SetVehicleIndicatorLights(veh, 0, n == 2 or n == 3)   -- 0 = lado derecho
end

--- El coche que llevo YO al volante, si es de tierra.
local function MiCoche()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return nil end
    local clase = GetVehicleClass(veh)
    if clase == 13 or clase == 14 or clase == 15 or clase == 16 or clase == 21 then return nil end
    return veh
end

local function Poner(n)
    local veh = MiCoche()
    if not veh then return end
    if puesto == n then n = 0 end          -- la misma tecla otra vez lo quita
    puesto, rumbo0, desde = n, GetEntityHeading(veh), GetGameTimer()
    Aplicar(veh, n)
    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    if NetworkGetEntityIsNetworked(veh) then
        TriggerServerEvent('origen_autoescuela:intermitentes', VehToNet(veh), n)
    end
end

--- Con un menú abierto y el ratón cogido, las flechas son del menú.
local function Tecla(n)
    if IsNuiFocused() or IsPauseMenuActive() then return end
    Poner(n)
end

RegisterCommand('intermitente_izq', function() Tecla(1) end, false)
RegisterCommand('intermitente_der', function() Tecla(2) end, false)
RegisterCommand('intermitente_averia', function() Tecla(3) end, false)
RegisterKeyMapping('intermitente_izq', 'Intermitente izquierdo', 'keyboard', 'LEFT')
RegisterKeyMapping('intermitente_der', 'Intermitente derecho', 'keyboard', 'RIGHT')
RegisterKeyMapping('intermitente_averia', 'Luces de avería', 'keyboard', 'DOWN')

--[[ La palanca: se mantiene y vuelve sola.

     Se vuelve a aplicar cada 200 ms porque el juego las apaga por su cuenta:
     lo vi con el conductor de pruebas (20/09), que lleva el coche con las
     tareas de IA —y la IA maneja los intermitentes ella misma, borrando lo
     que ponga el guion—. Al volante de un jugador no hay IA que las pise,
     pero sí hay reapariciones del coche y golpes, así que insistir sale
     gratis y las deja puestas de verdad. ]]
CreateThread(function()
    while true do
        local espera = 1000
        if puesto ~= 0 then
            espera = 200
            local veh = MiCoche()
            if not veh then
                -- Me he bajado: el de giro se va, el de avería se queda puesto
                -- en el coche (lo mantiene el statebag para todos).
                if puesto ~= 3 then puesto = 0 end
            else
                Aplicar(veh, puesto)
                if puesto == 1 or puesto == 2 then
                    local giro = math.abs(((GetEntityHeading(veh) - rumbo0 + 180.0) % 360.0) - 180.0)
                    if giro > 55.0 or GetGameTimer() - desde > 40000 then
                        Poner(puesto)      -- la misma otra vez: lo quita
                    end
                end
            end
        end
        Wait(espera)
    end
end)

--- Lo que llevan puesto los coches de los demás (y el mío, de vuelta).
AddStateBagChangeHandler(BOLSA, nil, function(bolsa, _, valor)
    local n = tonumber(valor) or 0
    CreateThread(function()
        local veh, fin = 0, GetGameTimer() + 3000
        repeat
            veh = GetEntityFromStateBagName(bolsa)
            if veh == 0 then Wait(100) end
        until veh ~= 0 or GetGameTimer() > fin
        if veh == 0 or not DoesEntityExist(veh) then return end
        -- El mío ya está aplicado, y lo que mando yo es más nuevo que el eco.
        if veh == MiCoche() then return end
        Aplicar(veh, n)
    end)
end)

--- Para el examen y para quien lo quiera saber.
function A.Intermitente() return puesto end
function A.PonerIntermitente(n) Poner(n) end
