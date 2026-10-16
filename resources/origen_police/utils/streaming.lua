LoadModel = function(model, timeout)
    RequestModel(model)
    local startTime = GetGameTimer()
    while not HasModelLoaded(model) do
        if GetGameTimer() - startTime > timeout then
            return false
        end
        Wait(0)
    end
    return true
end