--[[ ── Sin rastro ─────────────────────────────────────────────────────────────

     Todo lo que la granja crea en el mundo de este cliente (plantas, heno,
     palés, depósitos, cajas en las manos, en la camioneta y lo de dentro,
     aspersores propios, NPC) lleva la marca `origen_farming`. Al parar el
     recurso se borra todo lo marcado, y al arrancar se vuelve a barrer: si el
     recurso se cayó sin despedirse, o algo se quedó huérfano (una caja pegada a
     una mano que ya nadie apuntaba), no sobrevive a un reinicio.

     La marca es un decorador del juego: vive en la entidad, no en el script,
     así que el recurso nuevo reconoce lo que dejó el viejo. ]]

Rastro = {}

local MARCA = 'origen_farming'
local PACA = GetHashKey(Config.Carga.paca.modelo)
DecorRegister(MARCA, 3)

function Rastro.Marcar(ent)
    if ent and ent ~= 0 and DoesEntityExist(ent) then DecorSetInt(ent, MARCA, 1) end
    return ent
end

--[[ Lo que dejaron las versiones de antes de la marca: los modelos de la granja
     creados por un script (mission entity, sin red) dentro de la finca. Los
     del mapa (aspersores, pacas de decorado) no son de script y no se tocan. ]]
local function ModelosDeLaGranja()
    local set = {}
    local function Poner(m) if type(m) == 'string' then set[GetHashKey(m)] = true end end
    for _, cult in pairs(Config.Cultivos) do
        for _, fase in pairs(cult.modelos or {}) do for _, m in ipairs(fase) do Poner(m) end end
        if cult.contenido then Poner(cult.contenido.modelo) end
    end
    for _, c in pairs(Config.Carga) do if type(c) == 'table' then Poner(c.modelo) end end
    Poner(Config.Carga.paleModelo)
    Poner(Config.Riego.modelo)
    for _, m in ipairs({ 'prop_watercrate_01', 'prop_grass_dry_02', 'prop_haybale_01', 'prop_haybale_02', 'prop_haybale_03' }) do
        Poner(m)
    end
    return set
end

local function EnLaFinca(pos)
    if #(pos.xy - Config.Cooperativa.centro.xy) < 250.0 then return true end
    for _, campo in ipairs(Config.Campos) do
        if #(pos.xy - campo.centro.xy) < 250.0 then return true end
    end
    return false
end

local function Quitar(ent)
    if not DoesEntityExist(ent) then return end
    if IsEntityAttached(ent) then DetachEntity(ent, false, false) end
    SetEntityAsMissionEntity(ent, true, true)
    DeleteEntity(ent)
end

--- Borra todo lo de la granja que haya en este cliente. Devuelve cuántos.
function Rastro.Barrer(tambienSinMarca)
    local modelos = tambienSinMarca and ModelosDeLaGranja()
    local n = 0
    for _, ent in ipairs(GetGamePool('CObject')) do
        local nuestro = DecorExistOn(ent, MARCA)
        if not nuestro and modelos and modelos[GetEntityModel(ent)] and IsEntityAMissionEntity(ent)
            and not NetworkGetEntityIsNetworked(ent) then
            -- Solo en la finca: fuera de ella un modelo igual puede ser de otro
            -- trabajo (una caja que lleva alguien en el puerto). La paca de
            -- heno sí, esté donde esté si va pegada a un jugador: ningún otro
            -- trabajo la lleva, y una huérfana sigue a su ped por todo el mapa.
            nuestro = EnLaFinca(GetEntityCoords(ent))
                or (GetEntityModel(ent) == PACA and IsEntityAttachedToAnyPed(ent)
                    and IsPedAPlayer(GetEntityAttachedTo(ent)))
        end
        if nuestro then Quitar(ent) n = n + 1 end
    end
    for _, ped in ipairs(GetGamePool('CPed')) do
        if DecorExistOn(ped, MARCA) and not IsPedAPlayer(ped) then Quitar(ped) n = n + 1 end
    end
    return n
end

-- Al arrancar: nada de la partida anterior.
Rastro.Barrer(true)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    -- Tu personaje deja de ir cargado.
    local anim = Config.Carga.caja.anim
    if IsEntityPlayingAnim(cache.ped, anim.dict, anim.clip, 3) then
        StopAnimTask(cache.ped, anim.dict, anim.clip, 1.0)
    end
    Rastro.Barrer(true)
end)
