--[[ El valet: alguien te acerca el coche.

     El servidor ya ha cobrado y ha sacado el coche del garaje cuando esto
     arranca. Lo que queda es la parte que solo puede hacer el cliente: poner el
     coche en una carretera cerca, meterle un conductor y que venga.

     COMO TERMINA, QUE ES LO QUE SUELE FALLAR EN ESTAS COSAS

     El conductor se va y se borra en cuanto entrega. Si no, el servidor se
     llena de gente parada al lado de coches, y a la decima llamada eso son diez
     peatones que no hacen nada y que a alguien le va a dar por atropellar.

     Y hay un tiempo maximo. Si el coche no llega —se ha quedado atascado, el
     conductor ha chocado, el jugador se ha metido en un interior— se suelta de
     todas formas y se avisa: el coche esta fuera del garaje y pagado, asi que
     dejarlo dando vueltas para siempre seria lo peor de las dos opciones.
]]

--- A que distancia se da por entregado.
local ENTREGADO = 22.0

--- Cuanto se espera antes de darlo por imposible, en milisegundos.
local PACIENCIA = 90000

--- El conductor que trae el coche ahora mismo, si hay alguno.
local conductor = nil
local marca = nil

local function Limpiar()
    if marca then OrigenMapa.Quitar(marca); marca = nil end

    if conductor and DoesEntityExist(conductor) then
        --[[ Se suelta antes de borrarlo.

             Borrar un peaton que va conduciendo deja el coche sin nadie al
             volante a la velocidad que llevara. Se le manda salir, se le deja
             un momento y se borra. ]]
        TaskLeaveVehicle(conductor, GetVehiclePedIsIn(conductor, false), 0)

        local ped = conductor
        conductor = nil

        SetTimeout(4000, function()
            if DoesEntityExist(ped) then
                SetEntityAsNoLongerNeeded(ped)
                DeleteEntity(ped)
            end
        end)
    end
end

--- Carga un modelo y espera a tenerlo. Devuelve si lo ha conseguido.
---@param modelo number
---@return boolean
local function Cargar(modelo)
    if not IsModelInCdimage(modelo) then return false end

    RequestModel(modelo)

    local espera = 0
    while not HasModelLoaded(modelo) and espera < 100 do
        Wait(50)
        espera = espera + 1
    end

    return HasModelLoaded(modelo)
end

--[[ Una carretera a cierta distancia, para que el coche no aparezca encima.

     Se prueba en varias direcciones y se queda con la primera que valga: pedir
     un punto en una sola direccion falla en cuanto el jugador esta contra el
     mar o dentro de un aparcamiento. ]]
---@param centro vector3
---@param metros number
---@return vector3|nil
local function CarreteraCerca(centro, metros)
    for vuelta = 0, 7 do
        local angulo = (vuelta / 8) * 2 * math.pi
        local x = centro.x + math.cos(angulo) * metros
        local y = centro.y + math.sin(angulo) * metros

        local hay, punto = GetClosestVehicleNode(x, y, centro.z, 1, 3.0, 0)
        if hay then return punto end
    end

    return nil
end

Nui.On('valetSpawn', function(params)
    if not params or not params.model then return { ok = false, motivo = 'sin datos' } end

    Limpiar()

    local modelo = GetHashKey(params.model)
    if not Cargar(modelo) then return { ok = false, motivo = 'modelo' } end

    local yo = PlayerPedId()
    local aqui = GetEntityCoords(yo)

    local salida = CarreteraCerca(aqui, params.distance or 140.0)
    if not salida then
        SetModelAsNoLongerNeeded(modelo)
        return { ok = false, motivo = 'sitio' }
    end

    local coche = CreateVehicle(modelo, salida.x, salida.y, salida.z, 0.0, true, false)
    SetModelAsNoLongerNeeded(modelo)

    if not DoesEntityExist(coche) then return { ok = false, motivo = 'coche' } end

    SetVehicleNumberPlateText(coche, params.plate)
    SetVehicleOnGroundProperly(coche)
    SetEntityAsMissionEntity(coche, true, true)

    --[[ Los extras y el color, si ox_lib sabe leerlos.

         Van dentro de un pcall: los modificados los guarda el garaje con su
         propio formato, y un formato que no cuadre no puede impedir que llegue
         el coche. ]]
    if params.mods then
        pcall(function()
            local props = json.decode(params.mods)
            if props then lib.setVehicleProperties(coche, props) end
        end)
    end

    -- El conductor.
    local pedModelo = GetHashKey('a_m_y_business_01')
    if Cargar(pedModelo) then
        conductor = CreatePedInsideVehicle(coche, 4, pedModelo, -1, true, false)
        SetModelAsNoLongerNeeded(pedModelo)
    end

    if conductor and DoesEntityExist(conductor) then
        SetEntityAsMissionEntity(conductor, true, true)
        SetBlockingOfNonTemporaryEvents(conductor, true)
        SetDriverAbility(conductor, 1.0)
        SetDriverAggressiveness(conductor, 0.0)

        --[[ 786603 son las banderas de conducir de siempre: parar en los
             semaforos, esquivar coches y no ir campo a traves. Con cero, el
             conductor atraviesa la ciudad en linea recta. ]]
        TaskVehicleDriveToCoordLongRange(conductor, coche, aqui.x, aqui.y, aqui.z, 18.0, 786603, 15.0)
    end

    --[[ Y una marca, para verlo venir.

         Va con `entidad`: el punto sigue al coche mientras se acerca, que es
         de lo que se trata, y desaparece solo cuando el coche deja de existir.
         Prioridad alta porque el valet puede salir del otro lado de la ciudad
         —era lo que decia SetBlipAsShortRange(false)—. ]]
    marca = 'valet'

    OrigenMapa.Poner(marca, {
        entidad = coche,
        cat = 'garages',
        icono = 'coche',
        nombre = params.label or 'Valet',
        color = '#f0c33c',
        prioridad = 10,
    })

    -- La espera: o llega, o se le da por perdido.
    CreateThread(function()
        local desde = GetGameTimer()

        while DoesEntityExist(coche) do
            Wait(1000)

            local cerca = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(coche))

            if cerca < ENTREGADO then
                Limpiar()
                Nui.Send('valetArrived', { plate = params.plate })
                Framework.Notify(Locale.Say('valet_arrived'), 'success')
                return
            end

            if GetGameTimer() - desde > PACIENCIA then
                --[[ No ha llegado. Se suelta igualmente donde este.

                     El coche esta fuera del garaje y pagado: dejarlo con un
                     conductor dando vueltas para siempre seria peor que
                     decirle al jugador donde ha quedado. ]]
                Limpiar()
                Nui.Send('valetArrived', { plate = params.plate, stuck = true })
                Framework.Notify(Locale.Say('valet_stuck'), 'error')
                return
            end
        end

        Limpiar()
    end)

    return { ok = true }
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then Limpiar() end
end)
