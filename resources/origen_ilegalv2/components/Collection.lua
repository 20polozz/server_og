Collection = {}
Collection.__index = Collection

function Collection.new(tbl)
    local self = setmetatable({}, Collection)
    self.tbl = tbl or {}
    return self
end

function Collection:map(func)
    local result = Collection.new()
    for k, v in ipairs(self.tbl) do
        result.tbl[k] = func(v)
    end
    return result
end

function Collection:filter(func)
    local result = Collection.new()
    for k, v in ipairs(self.tbl) do
        if func(v) then
            table.insert(result.tbl, v)
        end
    end
    return result
end

function Collection:find(func)
    for k, v in ipairs(self.tbl) do
        if func(v) then
            return v
        end
    end
    return nil
end

function Collection:each(func)
    for k, v in ipairs(self.tbl) do
        func(v, k)
    end
    return self
end

function Collection:reduce(func, initial)
    local acc = initial
    for k, v in ipairs(self.tbl) do
        acc = func(acc, v, k)
    end
    return acc
end

function Collection:count()
    return #self.tbl
end

function Collection:first()
    return self.tbl[1]
end

function Collection:last()
    return self.tbl[#self.tbl]
end

function Collection:toTable()
    return self.tbl
end

