--[[
    VER UN MODELO DE PED ANTES DE PONERLO

    GTA no trae imagenes de sus modelos y en el servidor no hay ninguna: no se
    puede enseñar una miniatura de `g_m_y_lost_01` porque ese dibujo no existe
    en ninguna parte. Lo que si se puede es enseñar el modelo de verdad, que es
    mejor que una miniatura: sale delante de ti, dando vueltas, y lo ves como
    lo va a ver el jugador.

    Solo aparece para quien lo pide y no interviene en nada: no se registra en
    la red, no se le puede pegar y desaparece solo. Si se pide otro, el
    anterior se va antes.
]]

local previo = nil
local previoModelo = nil

--- Quita el ped de la vista previa, si lo hay.
local function quitar()
    if previo and DoesEntityExist(previo) then
        DeleteEntity(previo)
    end
    previo = nil
    previoModelo = nil
end

--- Trae el modelo a memoria. Devuelve false si no existe o tarda demasiado.
local function cargarModelo(hash)
    if not IsModelInCdimage(hash) or not IsModelAPed(hash) then return false end

    RequestModel(hash)
    local limite = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < limite do Wait(0) end

    return HasModelLoaded(hash)
end

--- Donde se planta: dos metros delante de quien mira, y mirandole a la cara.
local function sitioDelante(ped)
    local delante = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
    local suelo, z = GetGroundZFor_3dCoord(delante.x, delante.y, delante.z + 1.0, false)
    return vector3(delante.x, delante.y, suelo and z or delante.z),
        GetEntityHeading(ped) + 180.0
end

RegisterNUICallback('PreviewPed', function(data, cb)
    local modelo = data and data.model

    -- Sin modelo, o el mismo que ya esta puesto: se entiende como «quitalo».
    if not modelo or modelo == '' or modelo == previoModelo then
        quitar()
        return cb({ ok = true, puesto = false })
    end

    local hash = GetHashKey(modelo)
    if not cargarModelo(hash) then
        quitar()
        return cb({ ok = false, mensaje = 'Ese modelo no existe' })
    end

    quitar()

    local yo = PlayerPedId()
    local donde, giro = sitioDelante(yo)

    previo = CreatePed(4, hash, donde.x, donde.y, donde.z, giro, false, false)
    previoModelo = modelo
    SetModelAsNoLongerNeeded(hash)

    --[[ Un maniqui, no un vecino.

         Congelado y sin colision para que no se mueva ni empuje a nadie, sin
         reaccionar a los eventos del mundo para que no salga corriendo, y sin
         poder recibir daño: es una figura para mirar, no un NPC. ]]
    SetEntityInvincible(previo, true)
    FreezeEntityPosition(previo, true)
    SetBlockingOfNonTemporaryEvents(previo, true)
    SetEntityCollision(previo, false, false)
    SetPedCanRagdoll(previo, false)
    SetEntityAsMissionEntity(previo, true, true)

    cb({ ok = true, puesto = true })
end)

--- Al cerrar el panel no se queda un maniqui en la calle.
RegisterNUICallback('PreviewPedOff', function(_, cb)
    quitar()
    cb({ ok = true })
end)

--[[ Y si el recurso se para con la vista previa puesta, tampoco: un ped sin
     dueño se queda ahi hasta que alguien reinicie el servidor. ]]
AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    quitar()
end)
