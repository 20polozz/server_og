--[[ ── Mascotas · señalar a quien morder ────────────────────────────────────

     El panel se cierra y te deja apuntando: un punto en el centro de la
     pantalla, y lo que tengas debajo se marca. Click izquierdo para soltarla,
     ESC o click derecho para dejarlo.

     Es un rayo desde la camara, no desde el perro: se apunta con la vista, que
     es lo unico que el jugador controla. Y solo engancha PEDS —personas y
     animales—: apuntar a una farola y que el perro se lance contra ella seria
     gracioso una vez. ]]

local apuntando = false

--- Lo que hay bajo el centro de la pantalla, hasta donde llegue el puntero.
local function LoQueApunto()
    local camara = GetGameplayCamCoord()
    local mira = GetGameplayCamRot(2)

    -- El vector hacia donde mira la camara, sacado de su rotacion.
    local radianes = math.pi / 180.0
    local x = -math.sin(mira.z * radianes) * math.abs(math.cos(mira.x * radianes))
    local y = math.cos(mira.z * radianes) * math.abs(math.cos(mira.x * radianes))
    local z = math.sin(mira.x * radianes)

    local hasta = vector3(
        camara.x + x * Config.Distancias.laser,
        camara.y + y * Config.Distancias.laser,
        camara.z + z * Config.Distancias.laser
    )

    -- Flag 12: solo peds. El 4 son vehiculos, el 1 el mapa; aqui estorban.
    local rayo = StartShapeTestRay(camara.x, camara.y, camara.z, hasta.x, hasta.y, hasta.z, 12, cache.ped, 4)
    local _, toca, punto, _, entidad = GetShapeTestResult(rayo)

    if toca == 1 and entidad and entidad ~= 0 and IsEntityAPed(entidad) then
        return entidad, punto
    end

    return nil, hasta
end

--- El nombre de a quien apuntas, para poder decirlo en pantalla.
local function NombreDe(ped)
    local jugador = NetworkGetPlayerIndexFromPed(ped)
    if jugador and jugador ~= -1 and NetworkIsPlayerActive(jugador) then
        return GetPlayerName(jugador)
    end
    return 'Alguien'
end

--[[ Empieza a apuntar. Devuelve el control cuando el jugador elige o cancela;
     el que llama no tiene que esperar nada. ]]
function Mascotas.Apuntar()
    if apuntando then return end
    if not Mascotas.EnLaCalle() then return end

    local raza = Mascotas.Raza(Mascotas.fuera.raza)
    if not raza.pelea then
        TriggerEvent('QBCore:Notify', ('%s no es un perro de pelea.'):format(Mascotas.fuera.nombre), 'error')
        return
    end

    apuntando = true

    CreateThread(function()
        while apuntando do
            local objetivo = LoQueApunto()
            local valido = objetivo ~= nil and objetivo ~= cache.ped and objetivo ~= Mascotas.ped and not IsEntityDead(objetivo)

            -- La mira: una cruz rosa con canto negro (pegatina; en Nación la
            -- pasa a naranja tema.lua), y encima lo que hay debajo.
            local al = valido and 255 or 110
            DrawRect(0.5, 0.5, 0.0040, 0.0100, 0, 0, 0, al)
            DrawRect(0.5, 0.5, 0.0070, 0.0060, 0, 0, 0, al)
            DrawRect(0.5, 0.5, 0.0025, 0.0075, 216, 27, 85, al)
            DrawRect(0.5, 0.5, 0.0055, 0.0035, 216, 27, 85, al)

            -- Lo que se hace, en la barra de teclas del servidor (origen_hud).
            local que = valido and ('~INPUT_ATTACK~ Soltar a ' .. Mascotas.fuera.nombre .. ' sobre ' .. NombreDe(objetivo)) or 'Apunta a alguien'
            pcall(function() exports.origen_hud:Ayuda(que .. '~n~~INPUT_FRONTEND_PAUSE_ALTERNATE~ Cancelar') end)

            -- Mientras apuntas no se dispara ni se pega: el clic es para elegir.
            DisableControlAction(0, 24, true)  -- atacar
            DisableControlAction(0, 25, true)  -- apuntar con arma
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)

            if IsDisabledControlJustPressed(0, 24) and valido then
                apuntando = false
                if Mascotas.Atacar(objetivo) then
                    TriggerEvent('QBCore:Notify', ('%s va a por %s.'):format(Mascotas.fuera.nombre, NombreDe(objetivo)), 'success')
                end
            end

            if IsControlJustPressed(0, 202) or IsDisabledControlJustPressed(0, 25) then -- ESC o clic derecho
                apuntando = false
                TriggerEvent('QBCore:Notify', 'Sin objetivo.', 'primary')
            end

            Wait(0)
        end
    end)
end

--- Por si hay que cortarlo desde fuera (al guardar la mascota, por ejemplo).
function Mascotas.DejarDeApuntar()
    apuntando = false
end
