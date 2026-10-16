local config = lib.load('config.main')

DuiPool = {}
DuiPool.__index = DuiPool

DuiPool.available = {}
DuiPool.inUse = {}
DuiPool.nextId = 0
DuiPool.loading = {}

RegisterNUICallback('nuiLoaded', function(data, cb)
    local id = tonumber(data.id)
    DuiPool.loading[id] = nil
    cb('ok')
end)

function DuiPool._init(id)
    local dui = lib.dui:new({
        url = ('nui://%s/ui/index.html'):format(cache.resource),
        width = config.dui.width,
        height = config.dui.height,
        debug = false
    })

    DuiPool.loading[id] = true

    while DuiPool.loading[id] do
        dui:sendMessage({ action = 'initDui', id = id, estilo = config.checkpointEstilo or 0 })
        Wait(100)
    end

    return {
        id = id,
        dui = dui
    }
end

function DuiPool._clear(wrapper)
    wrapper.dui:sendMessage({ action = 'resetMarker' })
end

function DuiPool.get()
    if #DuiPool.available > 0 then
        local wrapper = table.remove(DuiPool.available)
        DuiPool.inUse[wrapper.id] = wrapper
        return wrapper.dui, wrapper.id
    end

    DuiPool.nextId = DuiPool.nextId + 1
    local id = DuiPool.nextId

    local wrapper = DuiPool._init(id)
    DuiPool.inUse[id] = wrapper

    return wrapper.dui, id
end

function DuiPool.free(id)
    local wrapper = DuiPool.inUse[id]
    if not wrapper then return end

    DuiPool.inUse[id] = nil
    DuiPool._clear(wrapper)
    DuiPool.available[#DuiPool.available + 1] = wrapper
end

function DuiPool.cleanup()
    for _, wrapper in pairs(DuiPool.inUse) do
        wrapper.dui:remove()
    end
    DuiPool.inUse = {}

    for _, wrapper in ipairs(DuiPool.available) do
        wrapper.dui:remove()
    end
    DuiPool.available = {}
end

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        DuiPool.cleanup()
    end
end)