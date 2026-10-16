local GetSafeZoneSize = GetSafeZoneSize
local GetActiveScreenResolution = GetActiveScreenResolution
local AddReplaceTexture = AddReplaceTexture
local RemoveReplaceTexture = RemoveReplaceTexture
local SetMinimapClipType = SetMinimapClipType
local SetMinimapComponentPosition = SetMinimapComponentPosition
local SetBlipAlpha = SetBlipAlpha
local SetBigmapActive = SetBigmapActive

local Config = {
    position = { x = 20, bottomMargin = 20 },
    calib = { mx = 2, my = 52, fw = nil, fh = nil, rx = 1.000, ry = 1.010 }
}

local BASE = {
    minimap      = { 0.0, -0.047, 0.1638, 0.183 },
    minimap_mask = { 0.0, 0.0, 0.128, 0.20 },
    minimap_blur = { -0.01, 0.025, 0.262, 0.300 }
}

local frame = nil
local anchor = nil
local dirty = true
local refreshing = false

local function requestRefresh()
    if refreshing then return end
    refreshing = true
    CreateThread(function()
        Wait(150)
        SetBigmapActive(true, false)
        Wait(50)
        SetBigmapActive(false, false)
        refreshing = false
    end)
end

local function resolveFrame()
    local resX, resY = GetActiveScreenResolution()
    resX, resY = resX + 0.0, resY + 0.0

    local fw = Config.calib.fw or math.floor(BASE.minimap[3] * resX + 0.5)
    local fh = Config.calib.fh or math.floor(BASE.minimap[4] * resY + 0.5)

    return {
        x = Config.position.x,
        y = resY - fh - Config.position.bottomMargin,
        w = fw,
        h = fh,
        resX = resX,
        resY = resY
    }
end

local function computeComponents()
    local sx = frame.w / (BASE.minimap[3] * frame.resX) * Config.calib.rx
    local sy = frame.h / (BASE.minimap[4] * frame.resY) * Config.calib.ry
    local inset = 0.5 * (1.0 - GetSafeZoneSize())
    local dx = (frame.x + Config.calib.mx) / frame.resX - inset
    local dy = ((frame.y + Config.calib.my) + frame.h - frame.resY) / frame.resY + inset

    local out = {}
    for name, c in pairs(BASE) do
        out[name] = { c[1] * sx + dx, c[2] * sy + dy, c[3] * sx, c[4] * sy }
    end
    return out
end

local function rebuild()
    frame = resolveFrame()

    SetMinimapClipType(0)
    for name, c in pairs(computeComponents()) do
        SetMinimapComponentPosition(name, 'L', 'B', c[1], c[2], c[3], c[4])
    end

    anchor = {
        x = frame.x / frame.resX,
        y = frame.y / frame.resY,
        width = frame.w / frame.resX,
        height = frame.h / frame.resY,
        res_x = frame.resX,
        res_y = frame.resY
    }

    dirty = false
    requestRefresh()
end

function GetMinimapAnchor()
    local resX, resY = GetActiveScreenResolution()
    if dirty or not frame or frame.resX ~= resX or frame.resY ~= resY then
        rebuild()
    end
    return anchor
end

function loadMinimap()
    RequestStreamedTextureDict('squaremap', false)
    local deadline = GetGameTimer() + 10000
    while not HasStreamedTextureDictLoaded('squaremap') and GetGameTimer() < deadline do
        Wait(100)
    end

    if HasStreamedTextureDictLoaded('squaremap') then
        AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'squaremap', 'radarmasksm')
        AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'squaremap', 'radarmasksm')
    end

    SetBlipAlpha(GetNorthRadarBlip(), 0)
    dirty = true
    GetMinimapAnchor()
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    RemoveReplaceTexture('platform:/textures/graphics', 'radarmasksm')
    RemoveReplaceTexture('platform:/textures/graphics', 'radarmask1g')
    SetBlipAlpha(GetNorthRadarBlip(), 255)
    SetMinimapClipType(1)
    SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045, 0.002, 0.150, 0.188888)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.020, 0.032, 0.111, 0.159)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.03, 0.022, 0.266, 0.237)
end)
