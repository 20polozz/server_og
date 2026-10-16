local config = lib.load('config.main')

Marker = {}
Marker.__index = Marker

Marker.table = {}

function Marker.new(id, data)
    local self = setmetatable({}, Marker)

    local markerType = data.type or 'marker'
    local drawDist = data.drawDistance or config.defaults.drawDistance
    local fadeDist = data.fadeDistance or config.defaults.fadeDistance
    local removeDist = data.removeDistance

    self.id = id

    self.data = {
        coords = data.coords,
        type = markerType,
        label = data.label or 'Punto de control',

        drawDistance = drawDist,
        drawDistanceSq = drawDist * drawDist,
        fadeDistance = fadeDist,
        fadeDistanceSq = fadeDist * fadeDist,

        minHeight = data.minHeight or config.defaults.minHeight,
        maxHeight = data.maxHeight or config.defaults.maxHeight,
        groundZ = data.groundZ or (data.coords.z + config.defaults.groundZOffset),

        removeDistance = removeDist,
        removeDistanceSq = removeDist and (removeDist * removeDist) or nil,
    }

    self.dui = nil
    self.duiId = nil
    self.active = true
    self.isRendering = false

    Marker.table[id] = self
    return self
end

function Marker.get(id)
    return Marker.table[id]
end

function Marker:cleanup()
    self.active = false
    Marker.table[self.id] = nil
end

function Marker:setupDui()
    local d = self.data
    local dui = self.dui

    dui:sendMessage({ 
        action = 'updateMarker', 
        visible = true,
        type = d.type,
        label = d.label
    })
end

function Marker:refresh(data)
    for k, v in pairs(data) do
        self.data[k] = v
    end

    if self.dui then
        self.dui:sendMessage({ 
            action = 'updateMarker', 
            label = data.label or nil,
            distance = data.distance or nil,
        })
    end
end

function Marker:canShow(cam)
    if not self.active then return false end

    local d = self.data
    local diff = cam - d.coords
    local distSq = diff.x * diff.x + diff.y * diff.y + diff.z * diff.z

    if distSq > d.drawDistanceSq then
        return false
    end

    return true
end

local function renderTexture(pos, width, height, r, g, b, a, txd, txn)
    local cam = GetFinalRenderedCamCoord()
    local halfW = width / 2

    local up = vec3(0.0, 0.0, 1.0)
    local toCamera = cam - pos
    local forward = norm(vec3(toCamera.x, toCamera.y, 0.0))
    local right = norm(cross(up, forward))

    local topLeft = pos - (right * halfW) + (up * height)
    local topRight = pos + (right * halfW) + (up * height)
    local bottomLeft = pos - (right * halfW)
    local bottomRight = pos + (right * halfW)

    --[[ El cartel ENTERO: un rectangulo, hecho con dos triangulos.

         Antes se pintaba UN solo triangulo con la punta en el suelo, y la
         textura se estiraba dentro de el: del cartel solo se veia una cuña
         —mas ancha arriba, cortada por los lados— y todo lo que quedaba
         fuera de esa cuña (los bordes, medio rotulo) no salia nunca. Por eso
         cualquier diseño acababa con forma de trapecio.

         Los dos triangulos van en el mismo sentido que el de antes
         (derecha-arriba, izquierda-arriba, abajo) para que miren a la camara. ]]
    DrawTexturedPoly(topRight.x, topRight.y, topRight.z, topLeft.x, topLeft.y, topLeft.z, bottomLeft.x, bottomLeft.y, bottomLeft.z, r, g, b, a, txd, txn, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
    DrawTexturedPoly(topRight.x, topRight.y, topRight.z, bottomLeft.x, bottomLeft.y, bottomLeft.z, bottomRight.x, bottomRight.y, bottomRight.z, r, g, b, a, txd, txn, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0)
end

function Marker:draw(cam, playerPos)
    if not self.active or not self.dui then return false end

    local success = pcall(IsDuiAvailable, self.dui.duiObject)
    if not success then return false end

    local d = self.data
    local camDiff = cam - d.coords
    local camDist = #(camDiff)

    local alpha = 255
    if camDist > d.fadeDistance then
        local fadeRange = d.drawDistance - d.fadeDistance
        alpha = math.floor(255 * (1 - ((camDist - d.fadeDistance) / fadeRange)))
    end

    local baseSize = (d.size or 1.0) * config.rendering.checkpointBaseMultiplier
    local perspectiveScale = camDist / config.rendering.perspectiveDivisor

    if not self.nextDistanceUpdate or GetGameTimer() >= self.nextDistanceUpdate then
        local playerDist = #(playerPos - d.coords)
        local flooredDist = math.floor(playerDist)
        if self.lastDistance ~= flooredDist then
            self.nextDistanceUpdate = GetGameTimer() + config.rendering.distanceUpdateInterval
            self.lastDistance = flooredDist
            self.dui:sendMessage({
                action = 'updateMarker',
                distance = tostring(flooredDist)
            })
        end
    end

    if d.type == 'checkpoint' then
        --[[ El cartel crece con la distancia para verse siempre del mismo
             tamaño en pantalla, y el ALTO de la textura es lo que decide a
             que altura queda el rotulo: va arriba del todo, con el hilo hasta
             el suelo debajo.

             Con el triangulo de antes solo se veia la punta de arriba y nadie
             noto que la textura media un radian de alto: al pintarla entera,
             el rotulo quedaba casi en el cenit y habia que levantar la camara.
             Ahora el alto son unos 12 grados, que caen dentro de la pantalla
             conduciendo, y de cerca no baja de `checkpointMinSize` metros. ]]
        local size = math.max(config.rendering.checkpointMinSize or 2.4, baseSize * perspectiveScale)
        renderTexture(
            vec3(d.coords.x, d.coords.y, d.groundZ),
            size,
            size * config.rendering.checkpointAspectRatio,
            255, 255, 255, alpha,
            self.dui.dictName,
            self.dui.txtName
        )
    end

    if d.removeDistanceSq then
        local playerDiff = playerPos - d.coords
        if (playerDiff.x^2 + playerDiff.y^2 + playerDiff.z^2) <= d.removeDistanceSq then
            return false
        end
    end

    return true
end