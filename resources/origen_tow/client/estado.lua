--[[ ── Por que se soltaban los coches ─────────────────────────────────────────

     La grua del GTA engancha ella sola y suelta ella sola. Con gente
     alrededor eso se rompe por dos sitios:

       1. El coche remolcado cambia de DUEÑO de red (el que manda sobre el
          en el servidor) en cuanto otro jugador se acerca mas. Ese otro no
          sabe nada del enganche, su fisica tira del coche hacia el suelo y
          el juego lo despega.

       2. Aunque nadie se acerque, la logica automatica del camion decide
          por su cuenta soltar en baches, al frenar o al tocar el coche.

     Asi que aqui: se le quita al camion el enganche automatico, el que
     lleva la grua se queda con el dueño del coche y NO lo suelta
     (SetNetworkIdCanMigrate a false), y un vigilante repasa cada poco que
     el enganche siga puesto y lo vuelve a poner si no.

     Y lo importante para que se vea igual en todas las pantallas: el
     enganche lo rehace CADA cliente en su maquina a partir de la lista que
     manda el servidor. Quien conecta a mitad de camino tambien lo ve. ]]

Estado = {}

local remolques = {}       -- [gruaNet] = { coche = cocheNet, tipo = ..., puesto = bool }

local function Ent(netId)
    if type(netId) ~= 'number' or netId == 0 then return nil end
    if not NetworkDoesNetworkIdExist(netId) then return nil end
    local e = NetworkGetEntityFromNetworkId(netId)
    if e and e ~= 0 and DoesEntityExist(e) then return e end
    return nil
end
Estado.Ent = Ent

--- El camion no vuelve a enganchar ni a soltar por su cuenta.
local function Amansar(grua)
    if not Config.QuitarAutomatico then return end
    SetVehicleAutomaticallyAttaches(grua, false, 0)
end

--[[ Hay que amansarlas ANTES de que el jugador meta el gancho debajo de un
     coche: si no, el juego engancha por su cuenta —por fuera de nuestra
     lista— y ese enganche es el que luego se suelta. Asi que repasamos
     todas las gruas que haya alrededor, lleven coche o no. ]]
CreateThread(function()
    while true do
        Wait(2000)
        if Config.QuitarAutomatico then
            for _, veh in ipairs(GetGamePool('CVehicle')) do
                local ficha = Tow.Ficha(GetEntityModel(veh))
                if ficha and ficha.tipo == 'gancho' then
                    Amansar(veh)

                    -- Si aun asi el juego ha enganchado algo a su aire (por
                    -- fuera de nuestra lista), se lo quitamos: ese enganche
                    -- es justo el que se suelta solo mas adelante.
                    local colgado = GetEntityAttachedToTowTruck(veh)
                    if colgado and colgado ~= 0 then
                        local net = NetworkGetNetworkIdFromEntity(veh)
                        if not net or net == 0 or not remolques[net] then
                            DetachVehicleFromTowTruck(veh, colgado)
                        end
                    end
                end
            end
        end
    end
end)

--- Nos quedamos con el coche: dueño de red, sin migrar y sin que lo limpie
--- el juego. Es lo que evita que se suelte al pasar otro jugador cerca.
local function Fijar(coche)
    if not DoesEntityExist(coche) then return false end

    if not NetworkHasControlOfEntity(coche) then
        NetworkRequestControlOfEntity(coche)
        return false
    end

    local net = NetworkGetNetworkIdFromEntity(coche)
    if net and net ~= 0 then
        SetNetworkIdExistsOnAllMachines(net, true)
        SetNetworkIdCanMigrate(net, false)
    end

    SetEntityAsMissionEntity(coche, true, true)
    SetVehicleIsStolen(coche, false)
    SetVehicleHasBeenOwnedByPlayer(coche, true)
    return true
end
Estado.Fijar = Fijar

--- Se lo devolvemos al juego.
local function Liberar(coche)
    if not DoesEntityExist(coche) then return end
    local net = NetworkGetNetworkIdFromEntity(coche)
    if net and net ~= 0 and NetworkHasControlOfEntity(coche) then
        SetNetworkIdCanMigrate(net, true)
    end
    SetEntityAsMissionEntity(coche, false, false)
end

--- ¿Me toca a mi cuidar de esta grua? Al que la conduce; si no la conduce
--- nadie, al que la tenga de dueño de red. Solo uno, para no pelearse.
local function SoyElCuidador(grua)
    local volante = GetPedInVehicleSeat(grua, -1)
    if volante ~= 0 then return volante == PlayerPedId() end
    return NetworkHasControlOfEntity(grua)
end
Estado.SoyElCuidador = SoyElCuidador

--- Pone (o repone) el enganche. Lo hace TODO cliente que tenga los dos
--- coches delante, por eso se ve igual en todas las pantallas.
local function Enganchar(grua, coche, ficha)
    if ficha.tipo == 'gancho' then
        Gancho.Pegar(grua, NetworkGetNetworkIdFromEntity(grua), coche, ficha)
        return
    end

    --[[ Plataforma. El coche va pegado AL CAMION —nunca a la caja, que es
         un adorno local—: es un enganche de red de verdad, el motor lo
         sincroniza solo y entre dos piezas pegadas entre si no hay choque.
         Aun asi se le apaga la colision, en cada cliente y en cada repaso:
         cargado no tiene por que tocar nada. ]]
    SetEntityCollision(coche, false, false)

    if GetEntityAttachedTo(coche) == grua then return end

    if ficha.caja then
        Plataforma.PegarCocheFinal(grua, coche, ficha)
        return
    end

    -- Por perfil: se apoya donde le toque, calculado igual que al subir.
    local donde = Plataforma.SitioFinal(grua, coche, ficha)
    if not donde then return end

    AttachEntityToEntity(coche, grua, 0,
        donde.x, donde.y, donde.z,
        donde.w or 0.0, 0.0, 0.0,
        false, false, false, false, 2, true)
end
Estado.Enganchar = Enganchar

local function Desenganchar(grua, coche, tipo)
    if tipo == 'gancho' then
        Gancho.Soltar(grua and NetworkGetNetworkIdFromEntity(grua) or 0,
                      coche and NetworkGetNetworkIdFromEntity(coche) or 0)
        return
    end
    -- En seco, fuera del camion y devolviendole la colision al final.
    if coche and DoesEntityExist(coche) then
        Plataforma.SoltarLimpio(coche, grua)
    end
end
Estado.Desenganchar = Desenganchar

-- ── La lista ──────────────────────────────────────────────────────────────

function Estado.Remolque(gruaNet)
    return remolques[gruaNet]
end

--- El remolque de una grua que tengo delante, por entidad.
function Estado.RemolqueDe(grua)
    local net = NetworkGetNetworkIdFromEntity(grua)
    if not net or net == 0 then return nil end
    return net, remolques[net]
end

--- ¿Va este coche en alguna grua?
function Estado.VaEnGrua(coche)
    local net = NetworkGetNetworkIdFromEntity(coche)
    if not net or net == 0 then return false end
    for _, dato in pairs(remolques) do
        if dato.coche == net then return true end
    end
    return false
end

RegisterNetEvent('origen_tow:cliente:poner', function(gruaNet, cocheNet, tipo, operario)
    remolques[gruaNet] = { coche = cocheNet, tipo = tipo, puesto = false }

    -- El cable tira del coche, y eso lo pinta cada cliente en su pantalla.
    -- Quien llegue despues se lo encuentra ya puesto, sin animacion.
    if not operario then return end
    local soyYo = operario == GetPlayerServerId(PlayerId())

    if tipo == 'plataforma' then
        Plataforma.Subir(gruaNet, cocheNet, soyYo)
    else
        Gancho.Enganchar(gruaNet, cocheNet, soyYo)
    end
end)

RegisterNetEvent('origen_tow:cliente:quitar', function(gruaNet, operario)
    local dato = remolques[gruaNet]
    if not dato then return end
    remolques[gruaNet] = nil

    local grua, coche = Ent(gruaNet), Ent(dato.coche)

    if dato.tipo == 'plataforma' and operario and grua and coche then
        Plataforma.Bajar(gruaNet, dato.coche, operario == GetPlayerServerId(PlayerId()))
        return
    end

    if coche then
        Desenganchar(grua, coche, dato.tipo)
        Liberar(coche)
    end
end)

RegisterNetEvent('origen_tow:cliente:brazo', function(gruaNet, altura)
    local grua = Ent(gruaNet)
    if grua then
        SetVehicleTowTruckArmPosition(grua, altura)
        local remolque = remolques[gruaNet]
        if remolque and remolque.tipo == 'gancho' then
            local coche = Ent(remolque.coche)
            if coche then
                local ficha = Tow.Ficha(GetEntityModel(grua))
                if ficha then
                    Gancho.ActualizarBrazo(grua, coche, ficha, altura)
                end
            end
        end
    end
end)

-- ── El vigilante ──────────────────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(Config.Vigilante)

        for gruaNet, dato in pairs(remolques) do
            local grua = Ent(gruaNet)
            local coche = Ent(dato.coche)

            if grua and coche then
                local ficha = Tow.Ficha(GetEntityModel(grua))
                if ficha then
                    Amansar(grua)

                    -- Mientras el cable esta tirando del coche manda la
                    -- maniobra; el vigilante no toca.
                    if not Plataforma.Ocupada(gruaNet) and not Gancho.Ocupado(gruaNet) then
                        if SoyElCuidador(grua) then
                            Fijar(coche)
                        end
                        Enganchar(grua, coche, ficha)
                        dato.puesto = true
                    end
                end
            end
        end
    end
end)

-- ── Arranque ──────────────────────────────────────────────────────────────

--[[ Olvidar todo y volver a preguntar. Es el mismo camino que recorre
     quien acaba de conectarse, y sirve para enderezar a mano una pantalla
     que se haya quedado descolgada (/gruaresync). ]]
RegisterNetEvent('origen_tow:cliente:resync', function()
    for gruaNet, dato in pairs(remolques) do
        local grua, coche = Ent(gruaNet), Ent(dato.coche)
        if coche then
            Desenganchar(grua, coche, dato.tipo)
            Liberar(coche)
        end
    end
    remolques = {}
    Plataforma.Olvidar()

    Wait(300)
    TriggerServerEvent('origen_tow:pedir:estado')
end)

--- Al entrar (o al recargar el recurso) pedimos la foto de lo que hay puesto.
AddEventHandler('onClientResourceStart', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    Wait(1500)
    TriggerServerEvent('origen_tow:pedir:estado')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('origen_tow:pedir:estado')
end)

--- Al parar el recurso dejamos los coches como estaban, no colgando.
AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for gruaNet, dato in pairs(remolques) do
        local grua, coche = Ent(gruaNet), Ent(dato.coche)
        if coche then
            Desenganchar(grua, coche, dato.tipo)
            Liberar(coche)
        end
    end
end)
