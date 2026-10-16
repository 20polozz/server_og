Custom.CanOpenChat = function()
    return true
end

Custom.OnSendNoCommandMessage = function(playerId, message)
    
end

-- Limpiar el chat solo para quien ejecuta el comando
RegisterCommand('clear', function()
    exports['origen_chat']:clearChat()
end, false)

TriggerEvent('chat:addSuggestion', '/clear', 'Limpia el chat')
TriggerEvent('chat:addSuggestion', '/ocultar', 'Activa/Desactivar el anonimato en /me y /do')
