Preload = {}
Preload.__index = Preload
Preload.table = {}


function Preload.new(data)
    local self = setmetatable({}, Preload)

    self.id = data.id
    self.coords = data.location
    self.render = nil

    Preload.table[self.id] = self

    self:createRender()

    return self
end

function Preload.get(id)
    return Preload.table[id]
end

function Preload:createRender()

    local function onEnter()
        if not self.id then return end
        local house = lib.callback.await('origen_housing:server:getHouse', false, self.id)
        if not house then return end
    
        local new_house = House.new(house)
    
        if new_house then 
            new_house:CreateHouse()    

            self:removeRender()
        end
    end

    self.render = lib.points.new({
        coords = self.coords,
        distance = Config.RenderDistance,
        houseID = self.id,
        onEnter = onEnter,
    })
end

function Preload:removeRender()

    if self.render then
        self.render:remove()
        self.render = nil
    end

    Preload.table[self.id] = nil
end