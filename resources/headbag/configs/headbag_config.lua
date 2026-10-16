wx = {}

wx.removeHeadbagOnRespawn = true

wx.Command = 'bolsa'
wx.discords = {
    ['237332540266905601'] = true,
    ['284464643844472832'] = true,
}

-- server.cfg: add_ace group.admin wx_headbag.admin allow

wx.Locale = {
    ContextTitle = "Menú bolsa",
    ContextPutOn = "Poner bolsa",
    ContextDescPutOn = "Colocar la bolsa al jugador más cercano",
    ContextTakeOff = "Quitar bolsa",
    ContextDescTakeOff = "Quitar la bolsa al jugador más cercano",
    NotifyTitle = "Bolsa",
    NotifyPutOn = "Has puesto la bolsa a un jugador",
    NotifyTookOff = "Te han quitado la bolsa",
    NotifyAlreadyOn = "Este jugador ya tiene la bolsa puesta",
    NotifyNoOneNearby = "No hay nadie cerca",
    NotifyNoPermission = "No tienes permiso para usar este comando",
}

function Notification(title, desc)
    lib.notify({
        title = title,
        description = desc,
        position = 'top',   -- sin style: el color lo pone origen_notify (pegatina)
        icon = 'masks-theater',
    })
end
