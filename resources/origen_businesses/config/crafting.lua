Config.Crafting = {
    BaseDuration = 3000,          -- Tiempo base en ms para 1 unidad (3 segundos)
    AdditionalDuration = 1800,    -- Tiempo adicional en ms por cada unidad extra sobre la base original (1.8 segundos)
}

function Config.GetCraftDuration(count)
    local c = math.max(1, math.min(10, math.floor(tonumber(count) or 1)))
    local base = Config.Crafting and Config.Crafting.BaseDuration or 3000
    local extra = Config.Crafting and Config.Crafting.AdditionalDuration or 1800
    return math.floor(base + (c - 1) * extra)
end

-- Configuración del sistema de alcohol y efectos de borrachera
Config.Alcohol = {
    Enabled = true,
    MaxLevel = 100,           -- Nivel máximo acumulable de alcohol
    DefaultAmountPerDrink = 10,-- Cantidad por defecto si el item no tiene valor propio
    DecreaseInterval = 15000, -- Cada cuántos ms disminuye el alcohol (15 segundos)
    DecreaseAmount = 1,       -- Cuánto alcohol baja en cada intervalo
    ResetOnDeath = true,      -- Resetear efectos y nivel de alcohol al morir

    -- Bebidas alcohólicas reconocidas y cantidad que suman por consumición
    Items = {
        ['bvs_alcohol'] = 30,
    },

    -- Umbrales y efectos según el nivel de alcohol del jugador
    -- bvs_alcohol suma 30: Copa 1 = Light | Copa 2 = Medium | Copa 3 = Heavy
    Stages = {
        Light = {
            Threshold = 30, -- Se activa con 1 bvs_alcohol
            WalkStyle = 'move_m@drunk@slightlydrunk',
            CamShake = 'DRUNK_SHAKE',
            ShakeIntensity = 0.5,
            Timecycle = 'spectator5',
            TimecycleStrength = 0.35,
            MotionBlur = true,
            StumbleChance = 0,
        },
        Medium = {
            Threshold = 55, -- Se activa con 2 bvs_alcohol
            WalkStyle = 'move_m@drunk@moderatedrunk',
            CamShake = 'DRUNK_SHAKE',
            ShakeIntensity = 1.2,
            Timecycle = 'spectator5',
            TimecycleStrength = 0.7,
            MotionBlur = true,
            StumbleChance = 8, -- % de probabilidad de tropezar al correr/esprintar
        },
        Heavy = {
            Threshold = 85, -- Se activa con 3 bvs_alcohol
            WalkStyle = 'move_m@drunk@verydrunk',
            CamShake = 'DRUNK_SHAKE',
            ShakeIntensity = 2.0,
            Timecycle = 'spectator5',
            TimecycleStrength = 1.0,
            MotionBlur = true,
            StumbleChance = 20, -- % de probabilidad de tropezar
            DriveWobble = true, -- ligero tambaleo al volante conduciendo
        },
    },
}
Config.BusinessConsumables = {
    Duration = 2500,
    Hunger = 25,
    Thirst = 25,
    Items = {
        bvs_comida = {
            Duration = 2500,
            Animation = {
                dict = 'mp_player_inteat@burger',
                clip = 'mp_player_int_eat_burger',
                flag = 49,
            },
        },
        bvs_bebida = {
            Duration = 2500,
            Animation = {
                dict = 'mp_player_intdrink',
                clip = 'loop_bottle',
                flag = 49,
            },
        },
        bvs_alcohol = {
            Duration = 2500,
            Animation = {
                dict = 'mp_player_intdrink',
                clip = 'loop_bottle',
                flag = 49,
            },
        },
    },
}
