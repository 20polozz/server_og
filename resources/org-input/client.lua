local properties = nil

RegisterNUICallback("buttonSubmit", function(data, cb)
    SetNuiFocus(false)
    SetNuiFocusKeepInput(false)
    if properties then properties:resolve(data.data) end
    properties = nil
    cb("ok")
end)

RegisterNUICallback("closeMenu", function(_, cb)
    SetNuiFocus(false)
    SetNuiFocusKeepInput(false)
    if properties then properties:resolve(nil) end
    properties = nil
    cb("ok")
end)

RegisterNUICallback("changeEvent", function(data, cb)
    TriggerEvent(data.event, data.value)
    cb("ok")
end)

local function ShowInput(data)
    Wait(150)
    if not data then return end
    if properties then return end

    properties = promise.new()

    SetNuiFocus(true, true)
    if data.keepinput then
        SetNuiFocusKeepInput(true)
    end
    SendNUIMessage({
        action = "openMenu",
        data = data
    })

    return Citizen.Await(properties)
end

exports("ShowInput", ShowInput)

--- Cerrar desde fuera (lib.closeInputDialog de ox_lib): quien esperaba recibe nil.
exports("CloseInput", function()
    if not properties then return end
    SetNuiFocus(false)
    SetNuiFocusKeepInput(false)
    local p = properties
    properties = nil
    p:resolve(nil)
    SendNUIMessage({ action = "closeMenu" })
end)

-- Raton soltado a la fuerza: quien esperaba el formulario recibe nil (como
-- al cancelar) y la pagina se cierra; si no, ShowInput no volveria a abrirse.
OrigenFoco.AlSoltar(function()
    if properties then properties:resolve(nil) end
    properties = nil
    SendNUIMessage({ action = "closeMenu" })
end)
