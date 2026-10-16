function GetCoreObject()
    return Config.Framework == "qbcore" and exports["qb-core"]:GetCoreObject() or Config.Framework == "esx" and exports["es_extended"]:getSharedObject()
end

-- Los avisos van por origen_notify (titulo «Radio»); el del framework
-- solo si origen_notify no esta arrancado.
function FW_Notify(text, tipo)
    if GetResourceState('origen_notify') == 'started' then
        exports.origen_notify:Notify({ title = 'Radio', description = text, type = tipo or 'info', duration = 5000 })
    elseif Config.Framework == "qbcore" then
        QBCore.Functions.Notify(text, tipo)
    elseif Config.Framework == "esx" then
        ESX.ShowNotification(text)
    end
end

function OverrideProximityRange(distance, bool)
    if distance ~= nil then 
        exports["pma-voice"]:overrideProximityRange(distance, bool)
        return
    end
    exports["pma-voice"]:clearProximityOverride()
end

function ToggleVoice(target, value, string)
    exports["pma-voice"]:toggleVoice(target, value, string)
end

function PlayerTargets(radioFreqs)
    exports["pma-voice"]:playerTargets(radioFreqs)
end

function IsPlayerDead()
    return IsEntityPlayingAnim(PlayerPedId(), "dead", "dead_a")
end

function CanTalk()
    local PlayerData = FW_GetPlayerData()
    if PlayerData.metadata["isdead"] or PlayerData.metadata["inlaststand"] or PlayerData.metadata["ishandcuffed"] then
        return false
    end
    return true
end

--[[ Los items que abren la radio, para quien los necesite fuera de aqui.

     Lo pide el riel del inventario, que pinta el boton de Radio solo si llevas
     uno encima. La lista vive en Config.RadioItems y no se copia alli: dos
     listas se separan a la primera radio nueva. ]]
exports('ItemsDeRadio', function()
    return Config.RadioItems or { 'radio' }
end)

--[[ Para que el inventario pueda comprobar, tras pasarle el relevo, que este
     panel llego a abrirse de verdad. Si no, se quedaria con el foco de la NUI
     puesto y ninguna pantalla delante: el raton en medio y la camara sin
     responder. Ver VigilarRelevo en origen_inventory. ]]
exports('EstaAbierto', function()
    return RadioAbierta == true
end)

function CanOpenRadio()
    -- Logic for checking if the player can open the radio
    return true
end

function GetPlayerItems(PlayerData)
    if Config.Inventory == "qs-inventory" then 
        return exports['qs-inventory']:getUserInventory() or {}
    elseif Config.Inventory == "ls-inventory" then
        return exports["ls-inventory"]:GetPlayerItems() or {}
    elseif Config.Inventory == "old_origen_inventory" then
        if Config.Framework == "esx" then
            local inventory = -1
            FW_TriggerCallback("origen_radio:server:GetInventory", function(data)
                inventory = data
            end)
            while inventory == -1 do
                Citizen.Wait(0)
            end
            return inventory or {}
        end
    elseif Config.Inventory == "origen_inventory" then
        return exports.origen_inventory:GetInventory()
    elseif Config.Inventory == "ox_inventory" then 
        return exports.ox_inventory:GetPlayerItems()
    elseif Config.Inventory == "codem-inventory" then
        return exports["codem-inventory"]:GetClientPlayerInventory()
    end

    return PlayerData.items or {}
end

if Config.CustomReviveEvent ~= "" then
    RegisterNetEvent(Config.CustomReviveEvent, function()
        Toggle(true)
    end)
end
--[[ ── El riel del inventario ────────────────────────────────────────────────

     La pantalla de la radio es ahora un panel del riel, como el de banda o el
     de negocio, asi que pinta la misma barra del canto derecho para poder
     volver.

     La lista NO se escribe aqui: se pide a origen_inventory, que es quien sabe
     que accesos le tocan a este jugador. Con una copia local, el dia que
     aparezca un acceso nuevo esta pantalla se quedaria con la lista vieja. ]]
RegisterNUICallback('PedirRiel', function(_, cb)
    if GetResourceState('origen_inventory') ~= 'started' then return cb({}) end

    local ok, riel = pcall(function()
        return exports.origen_inventory:GetRiel('radio')
    end)

    cb((ok and type(riel) == 'table') and riel or {})
end)

--- Saltar a otra cosa del riel. El foco se lo queda el que entra.
RegisterNUICallback('IrDelRiel', function(datos, cb)
    cb({})

    local destino = datos and datos.id
    if not destino then return end

    --[[ Cerrar la radio es soltar el foco y deshacer lo que se monto al
         abrirla: la animacion del movil y el aparato en la mano. Es lo mismo
         que hace el callback `focus` de client/events.lua; se repite aqui
         porque desde un recurso no se puede llamar a un callback de NUI propio
         como si fuera una funcion. ]]
    RadioAbierta = false
    SetNuiFocus(false, false)
    StopAnimTask(PlayerPedId(), 'cellphone@', 'cellphone_text_read_base', 2.0)
    ClearPedTasks(PlayerPedId())

    if radioHandProp and radioHandProp ~= 0 then
        DeleteObject(radioHandProp)
        radioHandProp = 0
    end

    if GetResourceState('origen_inventory') ~= 'started' then return end

    --[[ A mitad del recorrido, no al final. La columna tarda 260 ms en
         recogerse; abriendo a los 200 el panel que entra empieza a deslizarse
         mientras este acaba de salir, y no queda ni un fotograma de pantalla
         vacia. Esperar a que termine deja un hueco negro que es justo lo que
         se veia antes.

         `true` es el aviso de que esto es un RELEVO: el que entra tiene que
         pintar el riel ya puesto en vez de deslizarlo, porque el de aqui sigue
         en pantalla hasta que se desmonte. ]]
    SetTimeout(200, function()
        if destino == 'inventory' or destino == 'personal' or destino == 'vehicle' or destino == 'keys'
            or destino == 'city' or destino == 'quests' or destino == 'settings' then
            exports.origen_inventory:AbrirEnPestana(destino, true)
        else
            exports.origen_inventory:AbrirAcceso(destino, true)
        end
    end)
end)

--[[ Cerrar la radio desde fuera: al pararse el recurso, al morir o al quedarse
     sin radio encima. Sin esto la pantalla se quedaba pintada con el foco ya
     suelto --la radio a la vista y sin responder a nada--, que es la forma mas
     rapida de que alguien crea que se le ha colgado el juego. ]]
function CerrarRadioEnPantalla()
    SendNUIMessage({ action = 'CerrarRadio' })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)

--[[ Si el vigilante suelta el raton a la fuerza (`soltarraton`, o la pagina
     sin nada delante), la radio se da por cerrada del todo: sin esto
     `RadioAbierta` seguia en true, la columna pintada y el aparato en la mano
     con la animacion del movil. Sin coger el foco aqui dentro. ]]
OrigenFoco.AlSoltar(function()
    RadioAbierta = false
    SendNUIMessage({ action = 'CerrarRadio' })
    StopAnimTask(PlayerPedId(), 'cellphone@', 'cellphone_text_read_base', 2.0)

    if radioHandProp and radioHandProp ~= 0 then
        DeleteObject(radioHandProp)
        radioHandProp = 0
    end
end)

--[[ El servidor ha visto que ya no llevas radio (server/sin_radio.lua) y te ha
     sacado de todas las frecuencias. Aqui se deja el cliente igual: sin hablar,
     sin oir a nadie, con el estado a cero y la pantalla cerrada.

     El servidor ya ha hecho lo que importa --canal de pma-voice a 0, fuera de
     las listas, la voz apagada en los demas--, asi que un cliente que ignore
     esto no puede seguir hablando por la radio. Esto es para que lo que se ve
     cuadre con lo que pasa. ]]
RegisterNetEvent('origen_radio:client:SinRadio', function()
    if StopTalkRadio then StopTalkRadio() end
    if ClearAllTalkingPlayers then ClearAllTalkingPlayers() end

    Radio.Frec = 0
    Radio.Targets = {}
    Radio.MultiGroup = "none"
    Radio.MultiFrec = "none"
    Radio.MultiFrecTargets = {}
    Toggle(false)

    SendNUIMessage({ action = "DisconnectAllFreqs" })
    SendNUIMessage({ action = "resetRadioWidget" })

    if RadioAbierta then
        RadioAbierta = false
        CerrarRadioEnPantalla()
        StopAnimTask(PlayerPedId(), 'cellphone@', 'cellphone_text_read_base', 2.0)
        ClearPedTasks(PlayerPedId())
    end

    if radioHandProp and radioHandProp ~= 0 then
        DeleteObject(radioHandProp)
        radioHandProp = 0
    end

    if Lang and Lang.notify and Lang.notify.no_radio then
        FW_Notify(Lang.notify.no_radio)
    end
end)
