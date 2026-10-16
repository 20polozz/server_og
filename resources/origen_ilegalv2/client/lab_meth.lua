-- ── Meth Lab — Registro en el runner genérico ────────────────────────────────
--
-- Toda la lógica de puntos, markers, animaciones, barra de progreso y
-- estado de producción la maneja LabProcessRunner (client/lab_process_runner.lua).
--
-- Meth tiene un comportamiento especial que el runner genérico no cubre:
--   • En grab_tray: attachar un prop de bandeja al hueso de la mano derecha.
--   • El jugador camina con el prop hasta el punto 'smash'.
--   • En smash: detach + stop de la anim carry.
--
-- Esto se implementa via hooks: { onStageComplete } que se llama DESPUÉS de que
-- el runner ejecuta el stage, permitiendo lógica custom por stage_id.

if not Config.LabMeth or not Config.LabMeth.Enabled then return end

local dbg = Debug:new({ enabled = Config.Debug })

-- ── Prop de bandeja ───────────────────────────────────────────────────────────

local _trayProp = nil
local _carryActive = false

local function requestModel(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 3000 do
        Wait(50) ; t = t + 50
    end
    return HasModelLoaded(hash)
end

local function attachTrayProp()
    local anim = Config.LabMeth.Animations and Config.LabMeth.Animations.grab_tray
    if not anim or not anim.prop then return end
    if _trayProp and DoesEntityExist(_trayProp) then
        DeleteEntity(_trayProp)
        _trayProp = nil
    end

    local ped = PlayerPedId()
    local p   = anim.prop
    local h   = GetHashKey(p.hash)
    if not requestModel(h) then return end
    local obj = CreateObject(h, GetEntityCoords(ped), false, false, false)
    SetEntityAsMissionEntity(obj, true, true)
    SetModelAsNoLongerNeeded(h)
    AttachEntityToEntity(
        obj, ped, GetPedBoneIndex(ped, p.bone),
        p.pos.x, p.pos.y, p.pos.z,
        p.rot.x, p.rot.y, p.rot.z,
        true, true, false, true, 1, true
    )
    _trayProp = obj

    -- Mantener animación de carry viva hasta llegar a smash (o reset)
    _carryActive = true
    CreateThread(function()
        local dict = 'anim@heists@box_carry@'
        if not HasAnimDictLoaded(dict) then
            RequestAnimDict(dict)
            local t = 0
            while not HasAnimDictLoaded(dict) and t < 2500 do
                Wait(50)
                t = t + 50
            end
        end

        while _carryActive do
            local carryPed = PlayerPedId()
            if not _trayProp or not DoesEntityExist(_trayProp) then
                break
            end

            if not IsEntityPlayingAnim(carryPed, dict, 'idle', 3) then
                TaskPlayAnim(carryPed, dict, 'idle', 5.0, -1.0, -1, 49, 0, false, false, false)
            end

            Wait(500)
        end
    end)
end

local function detachTrayProp()
    _carryActive = false
    if _trayProp and DoesEntityExist(_trayProp) then
        DeleteEntity(_trayProp)
    end
    _trayProp = nil
    local ped = PlayerPedId()
    if HasAnimDictLoaded('anim@heists@box_carry@') then
        StopAnimTask(ped, 'anim@heists@box_carry@', 'idle', 3.0)
    end
end

-- ── Hooks para el runner ───────────────────────────────────────────────────────
--
-- onStageStart(stageId, result):
--   Llamado justo antes de iniciar anim/progress del stage.
--   En meth lo usamos para soltar la bandeja al arrancar smash.
--
-- onStageComplete(stageId, result):
--   Llamado DESPUÉS de que el runner completa exitosamente un stage.
--   Usamos esto para attachar/detachar el prop en los momentos correctos.
--
-- onReset():
--   Llamado cuando el runner resetea el estado (exit, unload, resource stop).

local methHooks = {
    -- Antes de smash: soltar la bandeja para no romper la animación del proceso.
    onStageStart = function(stageId, result)
        if stageId == 'smash' then
            detachTrayProp()
        end
    end,

    -- Después de grab_tray: attachar el prop
    onStageComplete = function(stageId, result)
        if stageId == 'grab_tray' then
            attachTrayProp()
        end
    end,

    -- Al resetear: asegurarse de limpiar el prop
    onReset = function()
        detachTrayProp()
    end,
}

-- ── Registro ──────────────────────────────────────────────────────────────────
LabProcessRunner.Register('meth', Config.LabMeth, methHooks)

-- Compatibilidad con código existente que llame a este export directamente
exports('MethLabResetProduction', function()
    LabProcessRunner.ResetProduction('meth')
end)
