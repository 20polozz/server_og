--[[ ── Lo que ve y toca el jugador ────────────────────────────────────────────

     A pie, junto a una grua:

       · Con la grua vacia y un coche cerca  → E engancha (o carga).
       · Con la grua cargada                 → E suelta (o baja).
       · En la de plataforma, siempre        → G baja o sube la caja a mano,
                                               para meter un coche por su pie.

     Al volante de la de gancho, PAGEUP y PAGEDOWN suben y bajan el brazo,
     y eso lo ve todo el mundo, no solo tu.

     Las teclas se pueden cambiar en Esc → Ajustes → Asignacion de teclas. ]]

local pulsada = {}
local reciente = {}   -- [nombre] = ms en que se pulso
local puesto = nil    -- el aviso que hay en pantalla ahora mismo, si lo hay

--[[ Una pulsacion SOLO cuenta si en ese instante habia un aviso en pantalla,
     y caduca enseguida. Antes se guardaba cualquier pulsacion de E o de G,
     se hiciera donde se hiciera —la E es el claxon: conduciendo se pulsa
     sin parar— y se quedaba esperando sin fecha. Al bajarse del camion, con
     el jugador ya a pie junto a la grua, esa pulsacion vieja se ejecutaba
     sola: la rampa bajaba, o se cargaba o descargaba un coche, sin que nadie
     hubiera tocado nada y con el camion a lo mejor todavia rodando. ]]
local CADUCA = 350

local function Tecla(nombre, porDefecto, texto)
    RegisterCommand('+origen_tow_' .. nombre, function()
        pulsada[nombre] = true
        if puesto and not IsPedInAnyVehicle(PlayerPedId(), false) then
            reciente[nombre] = GetGameTimer()
        end
    end, false)
    RegisterCommand('-origen_tow_' .. nombre, function()
        pulsada[nombre] = false
    end, false)
    RegisterKeyMapping('+origen_tow_' .. nombre, texto, 'keyboard', porDefecto)
end

CreateThread(function()
    Tecla('usar', Config.Teclas.Usar, 'Grúa: enganchar o soltar')
    Tecla('plataforma', Config.Teclas.Plataforma, 'Grúa: bajar o subir la plataforma')
    Tecla('arriba', Config.Teclas.BrazoArriba, 'Grúa: subir el brazo')
    Tecla('abajo', Config.Teclas.BrazoAbajo, 'Grúa: bajar el brazo')
end)

local function Cogida(nombre)
    local cuando = reciente[nombre]
    reciente[nombre] = nil
    return cuando ~= nil and GetGameTimer() - cuando <= CADUCA
end

-- ── El aviso de accion ────────────────────────────────────────────────────

--- `alt` es la segunda tecla, opcional: { tecla, lo que hace }.
local function Decir(texto, alt)
    local firma = texto .. '|' .. (alt and (alt[1] .. alt[2]) or '')
    if puesto == firma then return end
    puesto = firma
    exports['origen_notify']:DrawText(Config.Teclas.Usar, texto, alt)
end

local function Callar()
    reciente.usar, reciente.plataforma = nil, nil
    if not puesto then return end
    puesto = nil
    exports['origen_notify']:HideText()
end

local function Nombre(veh)
    local etiqueta = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
    if not etiqueta or etiqueta == '' or etiqueta == 'NULL' then return 'el coche' end
    return etiqueta
end

-- ── Buscar ────────────────────────────────────────────────────────────────

--- Lo que me separa del CONTORNO de un vehiculo (0 si estoy pegado o encima).
local function AlContorno(pos, veh, colaExtra)
    local rel = GetOffsetFromEntityGivenWorldCoords(veh, pos.x, pos.y, pos.z)
    local minimo, maximo = GetModelDimensions(GetEntityModel(veh))
    local atras = minimo.y - (colaExtra or 0.0)
    local dx = math.max(minimo.x - rel.x, 0.0, rel.x - maximo.x)
    local dy = math.max(atras - rel.y, 0.0, rel.y - maximo.y)
    return math.sqrt(dx * dx + dy * dy)
end

--[[ La grua que tengo cerca, si la hay, y si estoy PEGADO a ella. Se mira
     una zona ancha (por si estoy junto a un coche que hay detras, con la caja
     tumbada eso son doce metros), pero lo de «pegado» va por el contorno del
     camion y es lo que decide si salen los avisos de la propia grua. ]]
local function GruaCercana(ped)
    local pos = GetEntityCoords(ped)
    local mejor, mejorFicha, mejorD

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local ficha = Tow.Ficha(GetEntityModel(veh))
        if ficha then
            local d = #(pos - GetEntityCoords(veh))
            if d <= (ficha.entrada or Config.Distancia) + 6.0 and (not mejorD or d < mejorD) then
                mejor, mejorFicha, mejorD = veh, ficha, d
            end
        end
    end

    if not mejor then return nil end

    -- Con la caja tumbada el camion «mide» ocho metros mas por detras: junto
    -- al final de la rampa tambien se esta pegado a la grua.
    local net = NetworkGetNetworkIdFromEntity(mejor)
    local cola = (mejorFicha.caja and Plataforma.Tumbada(net)) and 8.0 or 0.0
    return mejor, mejorFicha, AlContorno(pos, mejor, cola) <= Config.CercaGrua
end

--- ¿Puedo llevarme este coche?
local function Vale(veh, grua)
    if veh == grua or not DoesEntityExist(veh) then return false end
    if not NetworkGetEntityIsNetworked(veh) then return false end
    if GetPedInVehicleSeat(veh, -1) ~= 0 then return false end
    if Estado.VaEnGrua(veh) then return false end

    -- Una grua que ya lleva un coche no se remolca a su vez.
    local _, suyo = Estado.RemolqueDe(veh)
    if suyo then return false end

    local clase = GetVehicleClass(veh)
    -- 14 barcos, 15 helicopteros, 16 aviones, 21 trenes.
    if clase == 14 or clase == 15 or clase == 16 or clase == 21 then return false end

    return true
end

--- El coche que se va a llevar: el mas cercano a MI, dentro del alcance de
--- la grua. En la plataforma, ademas, tiene que estar por detras.
local function CocheParaLlevar(ped, grua, ficha)
    local pos = GetEntityCoords(ped)
    local alcance = ficha.tipo == 'plataforma' and (ficha.entrada or 11.0) or Config.Distancia
    local mejor, mejorD, detras

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if Vale(veh, grua) then
            local d = AlContorno(pos, veh)
            if d <= Config.CercaCoche and (not mejorD or d < mejorD) then
                local rel = GetOffsetFromEntityGivenWorldCoords(grua, GetEntityCoords(veh))
                if #(GetEntityCoords(grua) - GetEntityCoords(veh)) <= alcance then
                    mejor, mejorD = veh, d
                    detras = rel.y < -1.5
                end
            end
        end
    end

    return mejor, detras
end

-- ── ¿Puedo? ───────────────────────────────────────────────────────────────

--[[ Las gruas son de los mecanicos de servicio. Se le pregunta al servidor
     —que es quien sabe quien esta fichado— y se guarda la respuesta unos
     segundos; mientras no se sabe, no sale ningun aviso. Sin esto le saldria
     el «cargar coche» a todo el que pasara junto a un flatbed. ]]
local puedo, puedoHasta, preguntando = false, 0, false

local function Puedo()
    local ahora = GetGameTimer()
    if ahora >= puedoHasta and not preguntando then
        preguntando = true
        CreateThread(function()
            local ok, si = pcall(lib.callback.await, 'origen_tow:puedo', false)
            puedo = ok and si == true
            puedoHasta = GetGameTimer() + 12000
            preguntando = false
        end)
    end
    return puedo
end

-- ── El bucle ──────────────────────────────────────────────────────────────

CreateThread(function()
    while true do
        local espera = 500
        local ped = PlayerPedId()

        if not IsPedInAnyVehicle(ped, false) and not IsPedDeadOrDying(ped, true) then
            local grua, ficha, pegado = GruaCercana(ped)

            if grua and ficha and not Puedo() then
                Callar()
                espera = 1000

            elseif grua and ficha then
                espera = 0
                local gruaNet, remolque = Estado.RemolqueDe(grua)

                -- La segunda tecla: bajar o subir la caja a mano. Solo en
                -- los camiones que la tienen movil, y con la grua vacia.
                local palanca = nil
                if ficha.caja and not remolque and pegado then
                    palanca = {
                        Config.Teclas.Plataforma,
                        Plataforma.Tumbada(gruaNet) and 'Subir la plataforma' or 'Bajar la plataforma',
                    }
                end

                if Plataforma.Ocupada(gruaNet) or Gancho.Ocupado(gruaNet) then
                    Callar()

                elseif remolque and not pegado then
                    Callar()

                elseif remolque then
                    Decir(ficha.tipo == 'plataforma' and 'Bajar el coche de la plataforma' or 'Soltar el coche')
                    if Cogida('usar') then
                        Callar()
                        TriggerServerEvent('origen_tow:pedir:soltar', gruaNet)
                    end

                else
                    local coche, detras = CocheParaLlevar(ped, grua, ficha)

                    if not coche then
                        -- Sin coche cerca todavia se puede mover la caja.
                        if palanca then
                            Decir('Acerca un coche por detras', palanca)
                        else
                            Callar()
                        end
                    elseif not detras then
                        -- Solo si estoy entre los dos: junto al coche Y junto
                        -- a la grua. De lejos este aviso no pinta nada.
                        if pegado then
                            Decir(ficha.tipo == 'plataforma' and 'Pon la plataforma delante del coche' or 'Coloca la grúa delante del coche', palanca)
                        else
                            Callar()
                        end
                        Cogida('usar')
                    else
                        Decir((ficha.tipo == 'plataforma' and 'Cargar %s en la plataforma' or 'Enganchar %s'):format(Nombre(coche)), palanca)
                        if Cogida('usar') then
                            Callar()
                            TriggerServerEvent('origen_tow:pedir:enganchar', gruaNet, NetworkGetNetworkIdFromEntity(coche))
                        end
                    end

                    if palanca and Cogida('plataforma') then
                        Callar()
                        TriggerServerEvent('origen_tow:pedir:plataforma', gruaNet)
                    end
                end
            else
                Callar()
            end
        else
            Callar()
        end

        Wait(espera)
    end
end)

-- ── El brazo, desde el asiento ────────────────────────────────────────────

CreateThread(function()
    local altura = nil
    local ultimoAviso = 0
    local pendiente = false

    while true do
        local espera = 500
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local ficha = Tow.Ficha(GetEntityModel(veh))
            if ficha and ficha.tipo == 'gancho' then
                if altura == nil then
                    local _, remolque = Estado.RemolqueDe(veh)
                    altura = remolque and (ficha.brazo or 0.65) or 0.0
                end

                espera = 50
                local paso = 0.0
                if pulsada.arriba then paso = 0.03 end
                if pulsada.abajo then paso = -0.03 end

                if paso ~= 0.0 then
                    altura = math.max(0.0, math.min(1.0, altura + paso))
                    SetVehicleTowTruckArmPosition(veh, altura)
                    pendiente = true
                end

                -- El brazo se mueve suave en mi pantalla, pero a los demas
                -- se lo contamos cada poco: si no, son 20 eventos por segundo.
                local ahora = GetGameTimer()
                if pendiente and ahora - ultimoAviso > 250 then
                    ultimoAviso = ahora
                    pendiente = false
                    TriggerServerEvent('origen_tow:pedir:brazo', NetworkGetNetworkIdFromEntity(veh), altura)
                end
            else
                altura = nil
            end
        else
            altura = nil
        end

        Wait(espera)
    end
end)
