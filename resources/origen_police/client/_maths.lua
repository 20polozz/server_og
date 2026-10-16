function GetTableLength(table)
    if(table == nil) then return 0 end
    local count = 0
    for _ in pairs(table) do count = count + 1 end
    return count
end

function isInside(vertices, xPlayer, yPlayer)
    local function sign(x1, y1, x2, y2, x3, y3)
        return (x1 - x3) * (y2 - y3) - (x2 - x3) * (y1 - y3)
    end

    local b = {}
    for i = 1, #vertices do
        local j = i % #vertices + 1
        local v1 = vertices[i]
        local v2 = vertices[j]
        local x1, y1 = v1.x or v1[1], v1.y or v1[2]
        local x2, y2 = v2.x or v2[1], v2.y or v2[2]
        b[i] = sign(xPlayer, yPlayer, x1, y1, x2, y2) < 0
    end

    for i = 2, #b do
        if b[i] ~= b[1] then
            return false
        end
    end

    return true
end

function DrawWall(p1, p2, minZ, maxZ, r, g, b, a)
    local bottomLeft = vector3(p1.x, p1.y, minZ)
    local topLeft = vector3(p1.x, p1.y, maxZ)
    local bottomRight = vector3(p2.x, p2.y, minZ)
    local topRight = vector3(p2.x, p2.y, maxZ)
    DrawPoly(bottomLeft,topLeft,bottomRight,r,g,b,a)
    DrawPoly(topLeft,topRight,bottomRight,r,g,b,a)
    DrawPoly(bottomRight,topRight,topLeft,r,g,b,a)
    DrawPoly(bottomRight,topLeft,bottomLeft,r,g,b,a)
end

function Draw3DText(x, y, z, scl_factor, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamCoords()
    local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov * scl_factor
    if onScreen then
        SetTextScale(0.0, scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end