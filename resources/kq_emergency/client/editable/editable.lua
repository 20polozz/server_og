-- Whether a specific equipment should be available to the player
function ShouldEquipmentBeAvailable(equipmentData)
    if not equipmentData.jobsWhitelist or table.length(equipmentData.jobsWhitelist) == 0 then
        return true
    end

    local job = exports.kq_link:GetPlayerJob()
    return table.contains(equipmentData.jobsWhitelist, job)
end

-- Whether a specific audio (siren) should be available to the player
function ShouldAudioBeAvailable(audioData)
    if not audioData.jobsWhitelist or table.length(audioData.jobsWhitelist) == 0 then
        return true
    end

    local job = exports.kq_link:GetPlayerJob()
    return table.contains(audioData.jobsWhitelist, job)
end

-- Timecycle used inside the editor
Timecycle = {
    active = false,
    name = 'kq_emergency_workshop',
    values = {
        { 'light_dir_mult', 0.0, 1.0 },
        { 'light_directional_amb_intensity_mult', 0.05, 0.0 },
        { 'light_natural_amb_down_intensity', 0.05, 0.0 },
        { 'light_natural_amb_up_intensity', 0.05, 0.0 },
        { 'fog_start', 0.0, 15.0 },
        { 'fog_density', 10.0, 10.0 },
        { 'fog_falloff', 0.0, 0.5 },
        { 'fog_hdr', -1.0, 1.0 },
        { 'environmental_blur_in', 0.0, 0.0 },
        { 'environmental_blur_out', 80.0, 0.0 },
        { 'environmental_blur_size', 20.0, 0.0 },

        { 'fog_haze_col_r', 0.0, 1.0 },
        { 'fog_haze_col_g', 0.0, 1.0 },
        { 'fog_haze_col_b', 0.0, 1.0 },

        { 'postfx_exposure', 0.9, 0.0 },
        { 'reflection_tweak_directional', 0.0, 0.0 },
        { 'sprite_brightness', 0.0, 0.0 },

        { 'no_rain', 1.0, 0.0 },
        { 'no_rain_ripples', 1.0, 0.0 },
    },
}

Timecycle.init = function()
    CreateTimecycleModifier(Timecycle.name)
    for k, data in pairs(Timecycle.values) do
        SetTimecycleModifierVar(Timecycle.name, data[1], data[2], data[3])
    end
end

Timecycle.enable = function(transition, strength)
    if Timecycle.active then
        return
    end

    Timecycle.active = true
    SetTransitionTimecycleModifier(Timecycle.name, transition or 1.0)
    SetTimecycleModifierStrength(strength or 1.0)
end

Timecycle.disable = function()
    if not Timecycle.active then
        return
    end

    Timecycle.active = false
    ClearTimecycleModifier()
end

Timecycle.init()
