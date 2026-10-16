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