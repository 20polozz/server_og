exportsQB = function (name, cb)
    AddEventHandler(string.format('__cfx_export_qb-inventory_%s', name), function(setCB)
        setCB(cb)
    end)
end

exportsOX = function(name, cb)
    AddEventHandler(string.format('__cfx_export_ox_inventory_%s', name), function(setCB)
        setCB(cb)
    end)
end