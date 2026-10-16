-- Admin Panel Client for Hub Integration
_G.DealershipHubIntegration = {
    openedFromHub = false
}

-- Hub Integration Exports
exports('IsOpenedFromHub', function() 
    return _G.DealershipHubIntegration.openedFromHub
end)

exports('ResetHubFlag', function() 
    _G.DealershipHubIntegration.openedFromHub = false
end)

exports('openManagement', function()
    _G.DealershipHubIntegration.openedFromHub = true
    
    -- Ejecutar el comando dealer que ya existe
    ExecuteCommand('dealer')
end)
