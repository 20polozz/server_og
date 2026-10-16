KillCam = {}

local function getPlayerData(killerId)
    local playerData = nil
    for _, data in pairs(playersList) do
        if data.id == killerId then
            playerData = data
            break
        end
    end

    return playerData
end

local function start(killerId)
    local playerData = getPlayerData(killerId)
    if not playerData then return debugger('KillCam: Player not found') end
    local banner = playerData.banner
    local avatar = playerData.avatar
    local name = playerData.name

    
end

KillCam.Start = start