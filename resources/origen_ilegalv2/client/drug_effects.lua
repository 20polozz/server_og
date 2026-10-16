-- ── Drug Effects System ───────────────────────────────────────────────────────
-- Aplica efectos al jugador cuando consume una droga.
-- Cada efecto activo se rastrea en activeEffects para poder cancelarlo o
-- no apilar instancias duplicadas del mismo tipo.

local activeEffects = {}

-- Cancela un efecto activo marcándolo como cancelado (el thread lo detecta y limpia)
local function cancelEffect(effectType)
    if activeEffects[effectType] then
        activeEffects[effectType].cancelled = true
        activeEffects[effectType] = nil
    end
end

-- Lanza un thread de duración que llama onTick() cada frame y onEnd() al terminar
local function startDurationEffect(effectType, duration, onTick, onEnd)
    cancelEffect(effectType)
    local ctx = { cancelled = false }
    activeEffects[effectType] = ctx

    CreateThread(function()
        local endTime = GetGameTimer() + (duration * 1000)
        while GetGameTimer() < endTime and not ctx.cancelled do
            if onTick then onTick() end
            Wait(0)
        end
        if not ctx.cancelled then
            activeEffects[effectType] = nil
            if onEnd then onEnd() end
        end
    end)
end

-- ── Definición de efectos ─────────────────────────────────────────────────────

local EFFECT_HANDLERS = {

    -- Físicos inmediatos
    heal = function(value, _)
        local ped   = PlayerPedId()
        local maxHp = GetEntityMaxHealth(ped)
        local curHp = GetEntityHealth(ped)
        local add   = math.floor(maxHp * ((value or 50) / 100.0))
        SetEntityHealth(ped, math.min(maxHp, curHp + add))
    end,

    armor = function(value, _)
        local ped = PlayerPedId()
        SetPedArmour(ped, math.min(100, GetPedArmour(ped) + (value or 50)))
    end,

    stamina = function(_, _)
        RestorePlayerStamina(PlayerId(), 1.0)
    end,

    heal_full = function(_, _)
        local ped = PlayerPedId()
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        SetPedArmour(ped, 100)
    end,

    -- Movimiento con duración
    speed = function(value, duration)
        local mult = value or 1.5
        startDurationEffect('speed', duration or 30,
            function() SetPedMoveRateOverride(PlayerPedId(), mult) end,
            function() SetPedMoveRateOverride(PlayerPedId(), 1.0) end
        )
    end,

    superman = function(_, duration)
        startDurationEffect('superman', duration or 30,
            function()
                SetPedMoveRateOverride(PlayerPedId(), 2.0)
                SetSuperJumpThisFrame(PlayerId())
            end,
            function() SetPedMoveRateOverride(PlayerPedId(), 1.0) end
        )
    end,

    no_ragdoll = function(_, duration)
        SetPedCanRagdoll(PlayerPedId(), false)
        startDurationEffect('no_ragdoll', duration or 30,
            nil,
            function() SetPedCanRagdoll(PlayerPedId(), true) end
        )
    end,

    super_jump = function(_, duration)
        startDurationEffect('super_jump', duration or 30,
            function() SetSuperJumpThisFrame(PlayerId()) end,
            nil
        )
    end,

    -- Combate con duración
    invincible = function(_, duration)
        SetEntityInvincible(PlayerPedId(), true)
        startDurationEffect('invincible', duration or 20,
            nil,
            function() SetEntityInvincible(PlayerPedId(), false) end
        )
    end,

    one_punch = function(_, duration)
        SetPlayerMeleeWeaponDamageModifier(PlayerId(), 99999.0)
        startDurationEffect('one_punch', duration or 20,
            nil,
            function() SetPlayerMeleeWeaponDamageModifier(PlayerId(), 1.0) end
        )
    end,

    infinite_stamina = function(_, duration)
        startDurationEffect('infinite_stamina', duration or 60,
            function() RestorePlayerStamina(PlayerId(), 1.0) end,
            nil
        )
    end,

    fireproof = function(_, duration)
        -- bulletProof=false, fireProof=true, explosionProof=false, collisionProof=false, meleeProof=false
        SetEntityProofs(PlayerPedId(), false, true, false, false, false, false, false, false)
        startDurationEffect('fireproof', duration or 30,
            nil,
            function() SetEntityProofs(PlayerPedId(), false, false, false, false, false, false, false, false) end
        )
    end,

    -- Visuales con duración
    screen_high = function(_, duration)
        AnimpostfxPlay('DrugsMichaelAliensFight', 0, true)
        startDurationEffect('screen_high', duration or 30,
            nil,
            function() AnimpostfxStop('DrugsMichaelAliensFight') end
        )
    end,

    screen_drunk = function(value, duration)
        local intensity = math.min(1.0, ((value or 3) / 5.0) * 0.6)
        ShakeGameplayCam('DRUNK_SHAKE', intensity)
        SetPedMotionBlur(PlayerPedId(), true)
        startDurationEffect('screen_drunk', duration or 30,
            nil,
            function()
                StopGameplayCamShaking(true)
                SetPedMotionBlur(PlayerPedId(), false)
            end
        )
    end,

    blur = function(_, duration)
        AnimpostfxPlay('SwitchShortNeutralIn', 0, true)
        startDurationEffect('blur', duration or 20,
            nil,
            function() AnimpostfxStop('SwitchShortNeutralIn') end
        )
    end,

    night_vision = function(_, duration)
        SetNightvision(true)
        startDurationEffect('night_vision', duration or 60,
            nil,
            function() SetNightvision(false) end
        )
    end,
}

-- ── Etiquetas visibles por efecto (para la notificación) ─────────────────────
local EFFECT_LABELS = {
    heal             = 'Recuperación de vida',
    armor            = 'Armadura reforzada',
    stamina          = 'Stamina restaurada',
    heal_full        = 'Vida y armadura al máximo',
    speed            = 'Boost de velocidad',
    superman         = 'Modo supermán',
    no_ragdoll       = 'Resistencia a golpes',
    super_jump       = 'Super salto',
    invincible       = 'Invulnerable',
    one_punch        = 'Super fuerza',
    infinite_stamina = 'Stamina infinita',
    fireproof        = 'Inmune al fuego',
    screen_high      = 'Efecto colocado',
    screen_drunk     = 'Efecto borracho',
    blur             = 'Visión borrosa',
    night_vision     = 'Visión nocturna',
}

-- ── Función pública: consumir una droga ──────────────────────────────────────
function consumeDrug(drugName)
    local drugConfig = Config.DrugSales and Config.DrugSales.DrugList and Config.DrugSales.DrugList[drugName]
    if not drugConfig then
        Notify.SendNotify(locale:t('notify.drug_not_recognized'), 'error')
        return
    end

    local effect = drugConfig.effect
    if not effect or not effect.type or effect.type == 'none' then
        Notify.SendNotify(locale:t('notify.drug_no_effect'), 'error')
        return
    end

    local handler = EFFECT_HANDLERS[effect.type]
    if not handler then
        Notify.SendNotify(locale:t('notify.drug_unknown_effect', effect.type), 'error')
        return
    end

    CreateThread(function()
        local ped = PlayerPedId()
        local ok, err = pcall(function()
            -- Barra de progreso igual que en la venta.
            FreezeEntityPosition(ped, true)
            ProgressBar.Open({ duration = 3000, label = locale:t('notify.consuming_drug', drugConfig.label or drugName), canCancel = false })
            Wait(3000)

            -- El servidor gasta la dosis y contesta con `consumoHecho`: el
            -- efecto se aplica ahí, no aquí, para que sin dosis no haya efecto.
            TriggerServerEvent('origen_gang:drugs:consumeItem', drugName)
        end)

        -- Siempre soltar freeze, incluso si hubo error en el flujo.
        FreezeEntityPosition(ped, false)

        if not ok and err then
            Notify.SendNotify('Error al consumir la droga', 'error')
        end
    end)
end

RegisterNetEvent('origen_gang:drugs:consumoHecho', function(drugName)
    local drugConfig = Config.DrugSales and Config.DrugSales.DrugList and Config.DrugSales.DrugList[drugName]
    local effect = drugConfig and drugConfig.effect
    local handler = effect and EFFECT_HANDLERS[effect.type]
    if not handler then return end

    handler(effect.value, effect.duration)

    local label  = EFFECT_LABELS[effect.type] or effect.type
    local durTxt = (effect.duration and effect.duration > 0) and (' (' .. effect.duration .. 's)') or ''
    Notify.SendNotify((drugConfig.label or drugName) .. ' — ' .. label .. durTxt, 'success')
end)

-- ── Limpieza al detener el recurso ───────────────────────────────────────────
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for _, ctx in pairs(activeEffects) do
        ctx.cancelled = true
    end
    activeEffects = {}

    local ped      = PlayerPedId()
    local playerId = PlayerId()

    SetPedMoveRateOverride(ped, 1.0)
    SetPedCanRagdoll(ped, true)
    SetEntityInvincible(ped, false)
    SetEntityProofs(ped, false, false, false, false, false, false, false, false)
    SetPlayerMeleeWeaponDamageModifier(playerId, 1.0)
    SetNightvision(false)
    StopGameplayCamShaking(true)
    SetPedMotionBlur(ped, false)
    AnimpostfxStopAll()
end)
