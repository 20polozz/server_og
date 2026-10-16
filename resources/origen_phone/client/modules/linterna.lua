--[[ La linterna del telefono.

     Antes esto solo encendia un resplandor dentro de la pantalla del movil: una
     luz dibujada por CSS sobre el cristal, que se veia bonita y no alumbraba
     nada. Ni al que la encendia ni, por supuesto, a nadie mas.

     DOS COSAS QUE HACEN FALTA PARA QUE SEA UNA LINTERNA

     1. QUE ALUMBRE DE VERDAD. GTA no tiene "linterna de telefono", asi que se
        dibuja una luz puntual delante del personaje, fotograma a fotograma,
        mientras este encendida. Delante y no encima: pegada al cuerpo lo unico
        que ilumina es la ropa.

     2. QUE LA VEAN LOS DEMAS. Una linterna que solo ve quien la lleva no sirve
        para lo que sirve una linterna: para que te encuentren, para alumbrarle
        a otro, para que te vean llegar. El servidor guarda quien la tiene
        encendida y se lo dice a todo el mundo; cada cliente dibuja las que
        tenga cerca.

     POR QUE SE AVISA A TODOS Y SE FILTRA EN EL CLIENTE

     Mandarselo solo a los que estan cerca obligaria al servidor a comparar
     posiciones cada pocos segundos por cada linterna encendida. Encenderla y
     apagarla pasa pocas veces, y el aviso es diminuto: sale mas barato que cada
     cliente se quede la lista y mire distancias, que es algo que ya hace de
     todas formas en su bucle de dibujado.
]]

Linterna = {}

--- Si la lleva encendida este jugador.
Linterna.on = false

--[[ Los de los demas: { [serverId] = true }.

     Se guarda el id de servidor y no el ped porque el ped puede no existir
     todavia —o dejar de existir— y el id no cambia mientras el jugador este
     dentro. El ped se busca en el momento de dibujar. ]]
local ajenas = {}

--- Hasta donde se ve la luz de otro. Mas lejos no se distingue y solo cuesta.
local ALCANCE = 60.0

local dibujando = false

--[[ El punto desde el que sale la luz y hacia donde apunta.

     Sale del hueso de la mano derecha, que es donde esta el telefono cuando se
     tiene en la mano. Si ese hueso no existe —algun modelo raro— se cae a la
     posicion del ped mas la altura del pecho, que se parece lo bastante.

     Apunta hacia donde mira el personaje, no hacia donde mira la camara: la
     linterna la lleva el, y si girara con la camara se veria a los demas mover
     la luz sin moverse ellos. ]]
---@param ped number
---@return vector3 desde, vector3 hacia
local function DeDonde(ped)
    local mano = GetPedBoneIndex(ped, 28422) -- SKEL_R_Hand
    local desde = mano ~= -1 and GetWorldPositionOfEntityBone(ped, mano)
        or (GetEntityCoords(ped) + vector3(0.0, 0.0, 0.6))

    local rumbo = math.rad(GetEntityHeading(ped))
    local delante = vector3(-math.sin(rumbo), math.cos(rumbo), 0.0)

    --- Un poco hacia abajo: se alumbra el suelo de delante, no el horizonte.
    return desde, desde + delante * 1.2 - vector3(0.0, 0.0, 0.25)
end

---@param ped number
local function Alumbrar(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    local _, hacia = DeDonde(ped)

    --- Blanco de bombilla, no blanco puro: el puro se ve azulado de noche.
    DrawLightWithRange(hacia.x, hacia.y, hacia.z, 255, 250, 235, 9.0, 14.0)
end

--[[ El bucle. Uno solo para la mia y las de los demas.

     Se enciende cuando hay algo que dibujar y se apaga cuando no queda nada:
     un hilo con Wait(0) corriendo siempre cuesta, aunque no dibuje. ]]
local function Dibujar()
    if dibujando then return end
    dibujando = true

    CreateThread(function()
        while true do
            local hayAlgo = Linterna.on or next(ajenas) ~= nil
            if not hayAlgo then break end

            local yo = PlayerPedId()

            if Linterna.on then Alumbrar(yo) end

            if next(ajenas) ~= nil then
                local donde = GetEntityCoords(yo)

                for serverId in pairs(ajenas) do
                    local jugador = GetPlayerFromServerId(serverId)

                    if jugador ~= -1 and jugador ~= PlayerId() then
                        local ped = GetPlayerPed(jugador)

                        --- El ped de alguien lejos no esta cargado: sale 0.
                        if ped and ped ~= 0 and DoesEntityExist(ped) then
                            if #(GetEntityCoords(ped) - donde) <= ALCANCE then
                                Alumbrar(ped)
                            end
                        end
                    end
                end
            end

            Wait(0)
        end

        dibujando = false
    end)
end

--- Enciende o apaga la mia, y se lo cuenta al servidor.
---@param on boolean
function Linterna.Set(on)
    on = on == true
    if Linterna.on == on then return end

    Linterna.on = on
    TriggerServerEvent('origen_phone:sv:flashlight', on)

    if on then Dibujar() end
end

--- La de otro se ha encendido o apagado.
RegisterNetEvent('origen_phone:cl:flashlight', function(serverId, on)
    if serverId == GetPlayerServerId(PlayerId()) then return end

    ajenas[serverId] = on and true or nil
    if on then Dibujar() end
end)

--[[ Y la lista entera al entrar, que si no las que ya estaban encendidas no se
     ven hasta que su dueño la apague y la vuelva a encender. ]]
RegisterNetEvent('origen_phone:cl:flashlights', function(lista)
    ajenas = {}

    for i = 1, #lista do
        if lista[i] ~= GetPlayerServerId(PlayerId()) then ajenas[lista[i]] = true end
    end

    if next(ajenas) ~= nil then Dibujar() end
end)

Nui.On('setFlashlight', function(params)
    Linterna.Set(params.enabled == true)
    return true
end)

--- Al soltar el recurso se apaga: si no, se queda encendida para los demas.
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if Linterna.on then TriggerServerEvent('origen_phone:sv:flashlight', false) end
end)
