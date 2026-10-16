--[[ ── Mascotas · el perro ──────────────────────────────────────────────────

     Sacarla, guardarla y las cuatro cosas que sabe hacer. El ped lo lleva el
     cliente del dueño: es quien decide a que sigue y a quien muerde, y asi las
     ordenes salen en el acto sin dar la vuelta por el servidor.

     La vida SI da esa vuelta, pero solo cuando cambia de verdad —al guardarla y
     al morir—, porque es lo unico que tiene que sobrevivir a la desconexion. ]]

local Aviso = function(texto, tipo)
    TriggerEvent('QBCore:Notify', texto, tipo or 'primary')
end

--[[ Sentarse va por ESQUELETO, no por raza.

     Iba con los escenarios de GTA (WORLD_DOG_SITTING_*) y una tabla de ocho
     modelos del juego; todo lo demas caia en el de perro pequeño. Pero casi
     todas las razas del catalogo son del pack (ft-*, corgi, golden_r...) y cada
     una se mueve con el esqueleto de un perro grande, uno pequeño o un gato: con
     el escenario que no le toca no pasa nada, el perro se queda de pie. Eso era
     el "no van las animaciones".

     Ahora se mira el esqueleto --shared/esqueletos.lua, sacado del peds.meta del
     pack; los de GTA van aqui-- y se pone la animacion de ese esqueleto con
     TaskPlayAnim, que es lo que usan el K9 de la policia y origen_anims. Cada
     familia lleva varias por si el diccionario no carga, y el escenario queda
     como ultimo recurso. ]]
local ESQUELETO_GTA = {
    a_c_rottweiler = 'grande', a_c_chop = 'grande', a_c_husky = 'grande',
    a_c_shepherd = 'grande', a_c_retriever = 'grande',
    a_c_poodle = 'pequeno', a_c_pug = 'pequeno', a_c_westy = 'pequeno',
    a_c_cat_01 = 'gato',
}

local SENTARSE = {
    grande = {
        { 'creatures@rottweiler@amb@world_dog_sitting@base', 'base' },
        { 'creatures@rottweiler@amb@world_dog_sitting@idle_a', 'idle_a' },
        escenario = 'WORLD_DOG_SITTING_ROTTWEILER',
    },
    pequeno = {
        { 'creatures@pug@amb@world_dog_sitting@idle_a', 'idle_b' },
        { 'creatures@pug@amb@world_dog_sitting@base', 'base' },
        escenario = 'WORLD_DOG_SITTING_SMALL',
    },
    -- Un gato no se sienta a la orden: se tumba.
    gato = {
        { 'creatures@cat@amb@world_cat_sleeping_ground@base', 'base' },
        { 'creatures@cat@amb@world_cat_sleeping_ground@idle_a', 'idle_a' },
        escenario = 'WORLD_CAT_SLEEPING_GROUND',
    },
}

--[[ Los trucos.

     Mismo patron que SENTARSE: por ESQUELETO y con TaskPlayAnim, porque los
     escenarios de GTA solo valen para los ocho modelos del juego y casi todo
     el catalogo se mueve con el esqueleto de un perro grande, uno pequeño o un
     gato. Cada truco lleva varias por si un diccionario no carga.

     Son los que pedian ("no deja hacer animaciones"): tumbarse, dar la patita
     y ladrar. Un gato no da la patita ni ladra: se estira y maulla, que es lo
     equivalente y no deja la orden sin hacer. ]]
local TRUCOS = {
    tumbar = {
        nombre = 'Túmbate',
        grande = {
            { 'creatures@rottweiler@amb@world_dog_barking@idle_a', 'idle_c' },
            { 'creatures@rottweiler@move', 'idle' },
            escenario = 'WORLD_DOG_SITTING_ROTTWEILER',
        },
        pequeno = {
            { 'creatures@pug@amb@world_dog_sitting@base', 'base' },
            escenario = 'WORLD_DOG_SITTING_SMALL',
        },
        gato = {
            { 'creatures@cat@amb@world_cat_sleeping_ground@base', 'base' },
            escenario = 'WORLD_CAT_SLEEPING_GROUND',
        },
    },
    patita = {
        nombre = 'Dame la patita',
        grande = {
            { 'creatures@rottweiler@amb@world_dog_barking@idle_a', 'idle_b' },
            { 'creatures@rottweiler@amb@world_dog_sitting@idle_a', 'idle_a' },
            escenario = 'WORLD_DOG_SITTING_ROTTWEILER',
        },
        pequeno = {
            { 'creatures@pug@amb@world_dog_sitting@idle_a', 'idle_a' },
            escenario = 'WORLD_DOG_SITTING_SMALL',
        },
        gato = {
            { 'creatures@cat@amb@world_cat_sleeping_ground@idle_a', 'idle_a' },
            escenario = 'WORLD_CAT_SLEEPING_GROUND',
        },
    },
    ladrar = {
        nombre = 'Ladra',
        grande = {
            { 'creatures@rottweiler@amb@world_dog_barking@base', 'base' },
            { 'creatures@rottweiler@amb@world_dog_barking@idle_a', 'idle_a' },
            escenario = 'WORLD_DOG_BARKING_ROTTWEILER',
        },
        pequeno = {
            { 'creatures@pug@amb@world_dog_barking@base', 'base' },
            escenario = 'WORLD_DOG_BARKING_SMALL',
        },
        gato = {
            { 'creatures@cat@amb@world_cat_sleeping_ground@idle_a', 'idle_a' },
            escenario = 'WORLD_CAT_SLEEPING_GROUND',
        },
    },
}

local function EsqueletoDe(modelo)
    local m = tostring(modelo or ''):lower()
    return ESQUELETO_GTA[m] or (Esqueletos and Esqueletos[m]) or 'grande'
end

--- Carga un diccionario con plazo. nil si no existe o no llega a cargar.
local function CargarDiccionario(dict)
    if not DoesAnimDictExist(dict) then return nil end
    if HasAnimDictLoaded(dict) then return dict end

    RequestAnimDict(dict)
    local limite = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < limite do Wait(0) end

    return HasAnimDictLoaded(dict) and dict or nil
end

--[[ Pone en bucle la primera animacion de la lista que cargue. Devuelve si
     alguna llego a ponerse. Flag 1 = en bucle y sin soltarla; la orden
     siguiente la quita con ClearPedTasks. ]]
local function Animar(ped, lista)
    for _, a in ipairs(lista or {}) do
        local dict = CargarDiccionario(a[1])
        if dict then
            TaskPlayAnim(ped, dict, a[2], 8.0, -8.0, -1, 1, 0.0, false, false, false)
            return true
        end
    end
    return false
end

local function GuardarSaludEnServidor(muerta)
    if not Mascotas.fuera then return end

    local salud = muerta and Config.SaludTrasMorir or Mascotas.SaludEnCien()

    lib.callback.await('origen_pets:guardarSalud', false, {
        id = Mascotas.fuera.id,
        salud = salud,
        comida = Mascotas.comida,
        bebida = Mascotas.bebida,
        fuera = false,
    })

    Mascotas.fuera.salud = salud
    Mascotas.fuera.comida = Mascotas.comida
    Mascotas.fuera.bebida = Mascotas.bebida
end

--- Deja de mandarle nada y borra el ped.
local function BorrarPed()
    if Mascotas.ped and DoesEntityExist(Mascotas.ped) then
        SetEntityAsMissionEntity(Mascotas.ped, true, true)
        DeleteEntity(Mascotas.ped)
    end
    Mascotas.ped = nil
end

--- Que se ponga detras de ti y no se despegue.
local function Seguir()
    if not Mascotas.EnLaCalle() then return end

    ClearPedTasks(Mascotas.ped)
    TaskFollowToOffsetOfEntity(
        Mascotas.ped, cache.ped,
        -- Con correa va pegada a ti.
        0.0, Mascotas.correa and -1.2 or -Config.Distancias.seguir, 0.0,
        Config.Progreso.Velocidad(Mascotas.Nivel()),   -- mas rapida cuanto mas nivel
        -1,    -- sin limite de tiempo
        1.5,   -- a que distancia del sitio se da por llegado
        true   -- persistir aunque se pierda
    )
end

local function Sentar()
    if not Mascotas.EnLaCalle() then return end

    local ped = Mascotas.ped
    local esqueleto = EsqueletoDe(Mascotas.Raza(Mascotas.fuera.raza).modelo)
    local sentarse = SENTARSE[esqueleto]

    -- Sin animacion para ese cuerpo (un ciervo, un puma, una vaca): se queda
    -- quieta, que es lo mas parecido y no deja la orden sin hacer.
    if not sentarse then
        ClearPedTasks(ped)
        TaskStandStill(ped, -1)
        return
    end

    -- Parada del todo antes: con la tarea de seguir aun viva, la animacion se
    -- la come el paso siguiente.
    ClearPedTasksImmediately(ped)
    if not Animar(ped, sentarse) then
        TaskStartScenarioInPlace(ped, sentarse.escenario, 0, true)
    end
end

local function Quieto()
    if not Mascotas.EnLaCalle() then return end

    ClearPedTasks(Mascotas.ped)
    TaskStandStill(Mascotas.ped, -1)
end

--[[ Atacar a alguien concreto.

     `TaskCombatPed` con 0 y 16 es lo que usa el juego para que un ped se lance
     a por otro y no se distraiga con lo que pase alrededor. ]]
function Mascotas.Atacar(objetivo)
    if not Mascotas.EnLaCalle() then return false end
    if not objetivo or not DoesEntityExist(objetivo) or IsEntityDead(objetivo) then return false end

    local raza = Mascotas.Raza(Mascotas.fuera.raza)
    if not raza.pelea then
        Aviso(('%s no es un perro de pelea.'):format(Mascotas.fuera.nombre), 'error')
        return false
    end

    ClearPedTasks(Mascotas.ped)
    SetPedCombatAttributes(Mascotas.ped, 46, true)  -- que pelee siempre
    SetPedCombatAttributes(Mascotas.ped, 5, true)   -- que no huya
    TaskCombatPed(Mascotas.ped, objetivo, 0, 16)

    return true
end

--[[ La mochila.

     Un alijo del inventario, con la capacidad de la raza: el rottweiler carga
     doce ranuras y el carlino cuatro. El id lleva el de la mascota, asi que
     cada perro tiene la suya y no se mezclan.

     Solo se abre con el perro delante: es una mochila que lleva puesta, no un
     banco al que se entra desde cualquier sitio. ]]
function Mascotas.AbrirMochila()
    if not Mascotas.EnLaCalle() then
        TriggerEvent('QBCore:Notify', 'Saca a la mascota para llegar a su mochila.', 'error')
        return false
    end

    if GetResourceState('origen_inventory') ~= 'started' then return false end

    local raza = Mascotas.Raza(Mascotas.fuera.raza)
    local alijo = raza.alijo or { slots = 4, peso = 5000 }

    exports.origen_inventory:openInventory('stash', 'mascota_' .. Mascotas.fuera.id, {
        label = ('Mochila de %s'):format(Mascotas.fuera.nombre),
        slots = alijo.slots,
        maxweight = alijo.peso,
    })

    return true
end

--- Aplica lo ultimo que le mandaste. Se llama al sacarla y al terminar una
--- pelea, para que no se quede plantada mirando al infinito.
--- Un truco: la animacion del esqueleto de esa mascota.
local function Truco(cual)
    if not Mascotas.EnLaCalle() then return end

    local truco = TRUCOS[cual]
    if not truco then return end

    local ped = Mascotas.ped
    local esqueleto = EsqueletoDe(Mascotas.Raza(Mascotas.fuera.raza).modelo)
    local lista = truco[esqueleto]

    if not lista then
        ClearPedTasks(ped)
        TaskStandStill(ped, -1)
        return
    end

    -- Como en Sentar: parada del todo, o la tarea de seguir se come la animacion.
    ClearPedTasksImmediately(ped)
    if not Animar(ped, lista) then
        TaskStartScenarioInPlace(ped, lista.escenario, 0, true)
    end
end

--[[ Subir y bajar del coche.

     Una sola orden que hace lo que toca: si la mascota va dentro, se baja; si
     no, se sube al coche en el que estes (o al que tengas al lado, de pie).
     El asiento es el ultimo libre de atras, para no echar a nadie del copiloto.

     Hace falta ponerla a mision y quitarle el seguir antes, o el juego la saca
     del coche en el paso siguiente para volver detras de ti. ]]
local function SubirABajarDelCoche()
    if not Mascotas.EnLaCalle() then return end

    local ped = Mascotas.ped

    if IsPedInAnyVehicle(ped, false) then
        ClearPedTasks(ped)
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 0)
        SetTimeout(1500, function()
            if Mascotas.EnLaCalle() then Seguir() end
        end)
        Aviso(('%s se baja.'):format(Mascotas.fuera.nombre), 'inform')
        return
    end

    local coche = cache.vehicle
    if not coche or coche == 0 then
        coche = lib.getClosestVehicle(GetEntityCoords(cache.ped), 5.0, false)
    end

    if not coche or coche == 0 or not DoesEntityExist(coche) then
        Aviso('No hay ningún coche al lado.', 'error')
        return
    end

    -- De atras hacia delante: el ultimo asiento libre que no sea el conductor.
    local plazas = GetVehicleModelNumberOfSeats(GetEntityModel(coche)) - 2
    local asiento

    for i = plazas, 0, -1 do
        if IsVehicleSeatFree(coche, i) then asiento = i break end
    end

    if not asiento then
        Aviso('No queda sitio en el coche.', 'error')
        return
    end

    ClearPedTasks(ped)
    SetPedIntoVehicle(ped, coche, asiento)
    Mascotas.orden = 'coche'
    Aviso(('%s se sube.'):format(Mascotas.fuera.nombre), 'success')
end

--- Si la mascota es un caballo y lo llevas montado (client/caballos.lua).
local function Montada()
    return Mascotas.ped ~= nil and CaballoMontado() == Mascotas.ped
end

function Mascotas.Aplicar(orden)
    Mascotas.orden = orden or Mascotas.orden

    -- Montada la llevan las riendas: la orden se apunta y se cumple al bajar,
    -- o le quitaria al caballo la tarea de andar.
    if Montada() then
        Mascotas.Avisar()
        return
    end

    if TRUCOS[Mascotas.orden] then Truco(Mascotas.orden)
    elseif Mascotas.orden == 'coche' then SubirABajarDelCoche()
    elseif Mascotas.orden == 'sentar' then Sentar()
    elseif Mascotas.orden == 'quieto' then Quieto()
    else Seguir() end

    Mascotas.Avisar()
end

--- Sacarla a la calle.
function Mascotas.Sacar(mascotaId)
    if Mascotas.EnLaCalle() then
        Aviso('Ya tienes una mascota fuera.', 'error')
        return false
    end

    local ficha
    for _, m in ipairs(Mascotas.lista) do
        if m.id == mascotaId then ficha = m break end
    end

    if not ficha then return false end

    if ficha.salud <= 0 then
        Aviso('Está malherida. Llévala al veterinario.', 'error')
        return false
    end

    --[[ El modelo, antes de avisar al servidor de que la mascota esta en la calle.

         Iba despues, y entonces un modelo que este cliente no tiene --una raza
         creada desde el panel con un ped que no esta en ningun stream-- dejaba la
         mascota marcada como fuera en la base de datos sin que hubiera ningun
         perro: a partir de ahi el panel decia "ya tienes una mascota fuera" y no
         habia manera de recogerla. ]]
    local raza = Mascotas.Raza(ficha.raza)
    local modelo = Mascotas.CargarModelo(raza.modelo)

    if not modelo then
        -- Con el nombre del modelo delante, que es el dato con el que se
        -- arregla: o esta mal escrito en el panel, o su stream no esta puesto.
        Aviso(('No se pudo cargar la mascota (%s).'):format(raza.modelo or '?'), 'error')
        return false
    end

    local respuesta = lib.callback.await('origen_pets:marcarFuera', false, { id = ficha.id, fuera = true })
    if not respuesta or not respuesta.ok then
        Aviso(respuesta and respuesta.mensaje or 'No se pudo sacar.', 'error')
        SetModelAsNoLongerNeeded(modelo)
        return false
    end

    local yo = GetEntityCoords(cache.ped)
    local detras = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, -Config.Distancias.sacar, 0.0)

    local ped = CreatePed(28, modelo, detras.x, detras.y, yo.z, GetEntityHeading(cache.ped), true, true)
    SetModelAsNoLongerNeeded(modelo)

    -- El aspecto guardado, y nunca el que el juego sortea al crearla: ese azar
    -- es lo que sacaba perros con la cabeza de un diseño y el cuerpo de otro,
    -- o con una textura que el pack no trae. Ver client/aspecto.lua.
    Aspecto.Aplicar(ped, raza.modelo, ficha.aspecto)

    -- La vida guardada, devuelta a la escala del juego.
    local vida = 100 + math.floor((raza.salud - 100) * (ficha.salud / 100))
    SetEntityMaxHealth(ped, raza.salud)
    SetEntityHealth(ped, math.max(101, vida))

    -- Que no se la lleve la limpieza de peds del juego ni se asuste sola.
    SetEntityAsMissionEntity(ped, true, true)
    SetPedCanBeTargetted(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, false) -- que no se quede plantado
    SetPedRelationshipGroupHash(ped, GetPedRelationshipGroupHash(cache.ped))
    SetBlockingOfNonTemporaryEvents(ped, true)

    --[[ Lo que pega al morder, en tanto por ciento sobre el mordisco de serie
         del modelo. Lo pone el admin por raza: un chihuahua y un rottweiler no
         hacen el mismo daño aunque el juego los trate casi igual.

         Va por InvokeNative y con pcall a proposito: el nombre de este native
         no esta en todas las versiones del wrapper de Lua, y si falta se queda
         el mordisco de serie -- que es lo que habia hasta ahora -- en vez de
         reventar toda la funcion de sacar la mascota. ]]
    local dano = tonumber(raza.dano) or 100
    if dano > 0 and dano ~= 100 then
        pcall(function()
            Citizen.InvokeNative(0x4757F00BC6323CFE, ped, (dano / 100.0) + 0.0)
        end)
    end

    -- La guardiana pelea mejor.
    if ficha.especialidad == 'guardian' then
        SetPedCombatAbility(ped, 2)
        SetPedCombatMovement(ped, 3)
    end

    Mascotas.ped = ped
    Mascotas.fuera = ficha
    Mascotas.correa = false
    Mascotas.comida = ficha.comida or 100
    Mascotas.bebida = ficha.bebida or 100
    ficha.fuera = true

    Mascotas.Aplicar('seguir')
    Aviso(('%s está contigo.'):format(ficha.nombre), 'success')
    return true
end

--- Guardarla. Se apunta la vida con la que se va.
function Mascotas.Guardar(silencio)
    if not Mascotas.fuera then return end

    local nombre = Mascotas.fuera.nombre
    local viva = Mascotas.EnLaCalle()

    if viva then GuardarSaludEnServidor(false) end

    lib.callback.await('origen_pets:marcarFuera', false, { id = Mascotas.fuera.id, fuera = false })

    Mascotas.fuera.fuera = false
    Mascotas.correa = false
    BorrarPed()
    Mascotas.fuera = nil
    Mascotas.orden = 'seguir'

    if not silencio then Aviso(('%s se queda en casa.'):format(nombre), 'primary') end
    Mascotas.Avisar()
end

--[[ ── Hambre y sed ─────────────────────────────────────────────────────────

     Bajan solas mientras la mascota esta en la calle. Un perro guardado en casa
     no baja: no se muere de hambre porque su dueño lleve tres dias sin entrar.

     No se escribe en la base de datos a cada punto —seria una escritura en
     disco por punto— sino al recogerla y al morir, que es cuando el dato tiene
     que sobrevivir a algo. ]]
CreateThread(function()
    local ultimaBajada = 0
    local ultimoCastigo = 0

    while true do
        Wait(1000)

        if Mascotas.EnLaCalle() then
            local ahora = GetGameTimer()

            if ahora - ultimaBajada >= Config.Necesidades.cada * 1000 then
                ultimaBajada = ahora
                Mascotas.comida = math.max(0, Mascotas.comida - 1)
                Mascotas.bebida = math.max(0, Mascotas.bebida - 1)
                Mascotas.Avisar()
            end

            -- Con hambre o sed pierde vida, poco a poco. No se muere: se queda
            -- debil, y de ahi al veterinario o a darle de comer.
            if (Mascotas.comida <= 0 or Mascotas.bebida <= 0)
                and ahora - ultimoCastigo >= Config.Necesidades.castigo * 1000 then
                ultimoCastigo = ahora

                local raza = Mascotas.Raza(Mascotas.fuera.raza)
                local baja = math.floor((raza.salud - 100) * (Config.Necesidades.danoPorFalta / 100))
                local vida = GetEntityHealth(Mascotas.ped) - baja

                -- Nunca por debajo de 101: 100 es muerto, y de hambre no se
                -- muere. Se queda a un mordisco de hacerlo.
                SetEntityHealth(Mascotas.ped, math.max(101, vida))
                Mascotas.Avisar()
            end
        end
    end
end)

--[[ ── El bucle ─────────────────────────────────────────────────────────────

     Vigila tres cosas mientras haya mascota fuera:

       · Que no se muera sin que nos enteremos. Al morir se apunta la vida de
         convaleciente y se recoge, en vez de dejar el cadaver tirado.

       · Que no se quede atras. Un perro atascado en una valla al otro lado del
         barrio no vuelve jamas; a partir de cierta distancia se teletransporta,
         que es feo pero menos que perderla.

       · Que si te pegan, muerda. Eso es el modo guardia: no ataca a nadie por su
         cuenta, responde a quien te este atacando a ti. ]]
CreateThread(function()
    while true do
        local espera = 1000

        if Mascotas.fuera then
            espera = 500

            if not DoesEntityExist(Mascotas.ped) then
                -- Se la llevo el juego (streaming, un reinicio). Se recoge sin
                -- perder la vida que tuviera.
                Mascotas.Guardar(true)
                goto siguiente
            end

            if IsEntityDead(Mascotas.ped) then
                local nombre = Mascotas.fuera.nombre
                GuardarSaludEnServidor(true)
                lib.callback.await('origen_pets:marcarFuera', false, { id = Mascotas.fuera.id, fuera = false })

                BorrarPed()
                Mascotas.fuera = nil
                Mascotas.orden = 'seguir'

                Aviso(('%s está malherida. Llévala al veterinario.'):format(nombre), 'error')
                Mascotas.Avisar()
                goto siguiente
            end

            local lejos = #(GetEntityCoords(Mascotas.ped) - GetEntityCoords(cache.ped))

            if lejos > Config.Distancias.lejos and Mascotas.orden == 'seguir' then
                local detras = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, -Config.Distancias.sacar, 0.0)
                SetEntityCoords(Mascotas.ped, detras.x, detras.y, GetEntityCoords(cache.ped).z, false, false, false, false)
                Seguir()
            end

            -- Modo guardia: a por quien te este atacando.
            -- Las de pelea te defienden tambien sin mandarselo (defensaAutomatica).
            if (Mascotas.orden == 'guardia' or (Config.Progreso.defensaAutomatica and Mascotas.orden == 'seguir'))
                and Mascotas.Raza(Mascotas.fuera.raza).pelea then
                local atacante = GetPedSourceOfDeath(cache.ped)
                if IsPedInMeleeCombat(cache.ped) or IsPedBeingStunned(cache.ped, 0) then
                    local objetivo = GetMeleeTargetForPed(cache.ped)
                    if objetivo and objetivo ~= 0 and objetivo ~= cache.ped then
                        Mascotas.Atacar(objetivo)
                        lib.callback('origen_pets:progreso:hecho', false, function() end, 'defender')
                    end
                elseif atacante and atacante ~= 0 and atacante ~= cache.ped and not IsEntityDead(atacante) then
                    Mascotas.Atacar(atacante)
                    lib.callback('origen_pets:progreso:hecho', false, function() end, 'defender')
                end
            end
        end

        ::siguiente::
        Wait(espera)
    end
end)

-- Al bajar del caballo vuelve a lo que estuviera haciendo (seguirte, quieto).
AddEventHandler('origen_pets:caballos:cl:desmontado', function(ent)
    if ent == Mascotas.ped and Mascotas.EnLaCalle() then Mascotas.Aplicar() end
end)

--[[ Si se va el recurso o el jugador, el perro no se queda de adorno en la
     calle. La vida se guarda antes de borrarlo. ]]
AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    -- Con el panel abierto, el raton se quedaria puesto sin nadie detras.
    SetNuiFocus(false, false)
    BorrarPed()
end)
