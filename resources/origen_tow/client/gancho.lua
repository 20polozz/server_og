--[[ ── La grua de gancho ──────────────────────────────────────────────────────

     En GTA V online y FiveM OneSync, el enganche nativo (AttachVehicleToTowTruck)
     se suelta en cuanto la grúa acelera, coge un bache, frena o cambia el dueño
     de red del vehículo, y una vez suelto no puede volver a morder en marcha.

     Para que sea 100% fiable, no se suelte jamás y se vea idéntico en todas las
     pantallas:
       1. El cable (animación de cabrestante) acerca suavemente el morro o el
          culo del vehículo hasta el gancho según esté encarado.
       2. El vehículo se fija con AttachEntityToEntity al chasis de la grúa, con
          las medidas exactas calculadas dinámicamente de su carrocería para
          que nunca colisione ni quede flotando.
       3. El brazo se levanta y las ruedas delanteras (o traseras) se elevan
          del suelo con una inclinación realista (pitch), mientras las ruedas
          opuestas quedan tocando el asfalto.
       4. Al soltarlo, se posa suavemente en el suelo sin salir disparado. ]]

Gancho = {}

local ocupados = {}   -- [gruaNet] = true mientras el cable tira

function Gancho.Ocupado(gruaNet)
    return ocupados[gruaNet] == true
end

--- Calcula la posición relativa, inclinación y giro exacto para enganchar
--- cualquier coche a la grúa según sus dimensiones reales y el brazo.
function Gancho.CalcularSitio(grua, coche, ficha, altura)
    local minG, maxG = GetModelDimensions(GetEntityModel(grua))
    local minC, maxC = GetModelDimensions(GetEntityModel(coche))

    -- ¿El coche está encarado de morro o de culo hacia la grúa?
    local giro = Tow.Corto(GetEntityHeading(coche) - GetEntityHeading(grua))
    local porDetras = math.abs(giro) > 90.0

    -- Posición del gancho en la grúa
    local ganchoY = ficha.ganchoY or (GetEntityModel(grua) == `towtruck` and -2.45 or -2.15)
    local distBumper = porDetras and math.abs(minC.y) or maxC.y
    local posY = ganchoY - distBumper - 0.15

    -- Altura según la posición del brazo (altura 0.0 a 1.0)
    local arm = altura or ficha.brazo or 0.65
    local baseZ = ficha.ganchoZ or (GetEntityModel(grua) == `towtruck` and 0.35 or 0.30)
    local posZ = baseZ + (arm * 0.28) - (minC.z * 0.22)

    -- Inclinación: levantamos las ruedas delanteras (o traseras si va del revés)
    local pitch = porDetras and -(4.5 + arm * 4.5) or (4.5 + arm * 4.5)
    local yaw = porDetras and 180.0 or 0.0

    return vec3(0.0, posY, posZ), pitch, yaw, porDetras
end

--- Engancha el coche a la grúa de forma robusta y sincronizada.
function Gancho.Pegar(grua, gruaNet, coche, ficha, altura)
    if not DoesEntityExist(grua) or not DoesEntityExist(coche) then return false end

    -- Desactivamos colisiones directas entre grúa y coche para evitar conflictos de físicas
    SetEntityNoCollisionEntity(grua, coche, true)
    SetEntityNoCollisionEntity(coche, grua, true)
    SetEntityCollision(coche, false, false)

    local arm = altura or ficha.brazo or 0.65
    SetVehicleTowTruckArmPosition(grua, arm)

    -- Si ya está pegado a la grúa, mantenemos la colisión apagada y confirmamos
    if GetEntityAttachedTo(coche) == grua then
        return true
    end

    local sitio, pitch, yaw = Gancho.CalcularSitio(grua, coche, ficha, arm)

    AttachEntityToEntity(coche, grua, 0,
        sitio.x, sitio.y, sitio.z,
        pitch, 0.0, yaw,
        false, false, false, false, 2, true)

    -- Quitamos freno y apagamos motor para que no genere arrastre
    SetVehicleHandbrake(coche, false)
    SetVehicleBrake(coche, false)
    SetVehicleEngineOn(coche, false, false, true)

    return GetEntityAttachedTo(coche) == grua
end

--- Actualiza la inclinación y posición del coche cuando el conductor mueve el brazo (PageUp / PageDown)
function Gancho.ActualizarBrazo(grua, coche, ficha, altura)
    if not DoesEntityExist(grua) or not DoesEntityExist(coche) then return end
    SetVehicleTowTruckArmPosition(grua, altura)
    if GetEntityAttachedTo(coche) == grua then
        local sitio, pitch, yaw = Gancho.CalcularSitio(grua, coche, ficha, altura)
        AttachEntityToEntity(coche, grua, 0,
            sitio.x, sitio.y, sitio.z,
            pitch, 0.0, yaw,
            false, false, false, false, 2, true)
    end
end

--- El cable visual, del brazo al morro (o culo) del coche.
local function Cable(grua, coche, ficha, porDetras)
    RopeLoadTextures()
    local espera = 0
    while not RopeAreTexturesLoaded() and espera < 200 do
        Wait(5)
        espera = espera + 1
    end

    local punto = ficha.cable or vec3(0.0, -2.6, 1.1)
    local a = GetOffsetFromEntityInWorldCoords(grua, punto.x, punto.y, punto.z)
    local minimo, maximo = GetModelDimensions(GetEntityModel(coche))
    local bY = porDetras and (minimo.y + 0.25) or (maximo.y - 0.25)
    local b = GetOffsetFromEntityInWorldCoords(coche, 0.0, bY, minimo.z + 0.45)
    local largo = math.max(#(a - b), 0.5)

    local cuerda = AddRope(a.x, a.y, a.z, 0.0, 0.0, 0.0, largo, 4, largo, 0.5, 1.0, false, false, false, 1.0, true)
    AttachEntitiesToRope(cuerda, grua, coche, a.x, a.y, a.z, b.x, b.y, b.z, largo, false, false, nil, nil)
    return cuerda, punto, bY
end

--- Acerca el coche suavemente hasta el gancho tirando del cable.
local function Acercar(grua, gruaNet, coche, ficha)
    local desde = GetOffsetFromEntityGivenWorldCoords(grua, GetEntityCoords(coche))
    local hasta, pitchFinal, yawFinal, porDetras = Gancho.CalcularSitio(grua, coche, ficha, 0.0)

    local giro = Tow.Corto(GetEntityHeading(coche) - GetEntityHeading(grua))
    local giroObjetivo = porDetras and (giro > 0 and 180.0 or -180.0) or 0.0

    -- Ya está en el gancho: no hace falta animar acercamiento
    if #(vec3(desde.x, desde.y, 0.0) - vec3(hasta.x, hasta.y, 0.0)) < 0.6 and math.abs(giro - giroObjetivo) < 8.0 then
        return
    end

    local cuerda, punto, bY = Cable(grua, coche, ficha, porDetras)
    local ms = Config.Acercar
    local arranque = GetGameTimer()

    SetEntityCollision(coche, false, true)

    while true do
        Wait(0)
        if not DoesEntityExist(grua) or not DoesEntityExist(coche) then break end

        local t = math.min((GetGameTimer() - arranque) / ms, 1.0)
        local s = Tow.Suave(t)

        if Estado.SoyElCuidador(grua) then Estado.Fijar(coche) end

        AttachEntityToEntity(coche, grua, 0,
            Tow.Entre(desde.x, hasta.x, s), Tow.Entre(desde.y, hasta.y, s), Tow.Entre(desde.z, hasta.z, s),
            Tow.Entre(0.0, pitchFinal, s), 0.0, Tow.Entre(giro, giroObjetivo, math.min(s * 2.0, 1.0)),
            false, false, false, false, 2, true)

        if cuerda then
            local a = GetOffsetFromEntityInWorldCoords(grua, punto.x, punto.y, punto.z)
            local minimo, maximo = GetModelDimensions(GetEntityModel(coche))
            local b = GetOffsetFromEntityInWorldCoords(coche, 0.0, bY, minimo.z + 0.45)
            RopeForceLength(cuerda, math.max(#(a - b), 0.5))
        end

        if t >= 1.0 then break end
    end

    if cuerda then DeleteRope(cuerda) end
    Wait(50)
end

--- La maniobra entera. La pintan TODOS los clientes que tengan los dos
--- vehículos delante; `soyYo` solo lo es el que engancha.
function Gancho.Enganchar(gruaNet, cocheNet, soyYo)
    local grua, coche = Estado.Ent(gruaNet), Estado.Ent(cocheNet)
    if not grua or not coche then return end

    local ficha = Tow.Ficha(GetEntityModel(grua))
    if not ficha or ficha.tipo ~= 'gancho' then return end
    if ocupados[gruaNet] then return end

    ocupados[gruaNet] = true

    CreateThread(function()
        local ok, err = pcall(function()
            if soyYo and lib.requestAnimDict('mini@repair', 2000) then
                TaskPlayAnim(PlayerPedId(), 'mini@repair', 'fixing_a_player', 4.0, -4.0,
                    Config.Acercar, 1, 0.0, false, false, false)
            end

            -- Si soy yo, nos aseguramos el control de red del coche antes de maniobrar
            if soyYo then
                local timeout = GetGameTimer() + 2000
                while not NetworkHasControlOfEntity(coche) and GetGameTimer() < timeout do
                    NetworkRequestControlOfEntity(coche)
                    Wait(50)
                end
                Estado.Fijar(coche)
            end

            SetVehicleTowTruckArmPosition(grua, 0.0)
            Acercar(grua, gruaNet, coche, ficha)

            -- Enganche firme y levantamos el brazo
            Gancho.Pegar(grua, gruaNet, coche, ficha, ficha.brazo or 0.65)
        end)

        ocupados[gruaNet] = nil
        if soyYo then ClearPedTasks(PlayerPedId()) end

        if not ok then
            print(('^1[origen_tow]^0 la maniobra del gancho se corto: %s'):format(tostring(err)))
        end
    end)
end

--- Soltar: el brazo baja y el coche se posa en el suelo limpiamente.
function Gancho.Soltar(gruaNet, cocheNet)
    local grua, coche = Estado.Ent(gruaNet), Estado.Ent(cocheNet)

    if grua and DoesEntityExist(grua) then
        DetachVehicleFromAnyTowTruck(grua)
        SetVehicleTowTruckArmPosition(grua, 0.0)
    end

    if coche and DoesEntityExist(coche) then
        DetachEntity(coche, false, false)
        Plataforma.SoltarLimpio(coche, grua)
    end

    ocupados[gruaNet] = nil
end
