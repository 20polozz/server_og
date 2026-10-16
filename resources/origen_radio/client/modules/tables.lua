Radio = {
    Enabled = false,
    Frec = 0,
    Anim = 1,
    Targets = {},
    Talking = false,
    MultiGroup = "none",
    MultiFrec = "none",
    MultiFrecTargets = {},
    Clicks = true,
    Binds = {},
    Muted = false
}

exports("IsTalking", function()
    return Radio.Talking
end)