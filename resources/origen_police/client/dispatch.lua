-- El aviso que tiene marcado esta unidad (lo usan StartAlerts y VigilarRutaDeAviso).
local alertaMarcadaCode = nil

local MyAlerts = {}
local showing = false
local currentselected = 0
local filter = nil
local silenciado = false
local started = false
local stopAutoAdvance = false

--[[ El mini despacho escondido A MANO (12/10): con la tecla o desde Ajustes.
     Mientras lo este no vuelve a salir solo —antes cada aviso nuevo lo
     reabria— y se guarda en el equipo de cada uno. ]]
local KVP_OCULTO = 'origen_police:dispatch_oculto'
local ocultoAMano = GetResourceKvpString(KVP_OCULTO) == 'si'

RegisterNetEvent("origen_police:meCommand", function(text)
    UseCommand('me', text)
end)

function StartAlerts()
    if started then return end
    started = true

    if Config.Commands.OpenMiniDispatch and Config.Commands.OpenMiniDispatch.cmd then
        RegisterKeyMapping(Config.Commands.OpenMiniDispatch.cmd, Config.Commands.OpenMiniDispatch.description or "Abrir / Cerrar Mini Dispatch", 'keyboard', Config.Commands.OpenMiniDispatch.key or 'U')
        RegisterCommand(Config.Commands.OpenMiniDispatch.cmd, function(src, args, raw)
            local PlayerData = FW_GetPlayerData(false)
            if (not onduty or IsNuiFocused()) or not CanOpenTablet(PlayerData.job.name)[1] then return end
            OcultarDispatch(showing)
        end)
    end
    exports.origen_police:SetDefaultBind(Config.Commands.OpenMiniDispatch.key, "origen_police:dispatch:alertas")
    exports.origen_police:SetDefaultBind(Config.Commands.AcceptAlert.key, "origen_police:dispatch:mrkalert")
    exports.origen_police:SetDefaultBind(Config.Commands.DeleteAlert.key, "origen_police:dispatch:delalert")
    exports.origen_police:SetDefaultBind("J", "origen_police:dispatch:toggleReady")
    
    RegisterKeyMapping(Config.Commands.NextAlert.cmd, Config.Commands.NextAlert.description, 'keyboard', Config.Commands.NextAlert.key)
    RegisterKeyMapping(Config.Commands.PreviousAlert.cmd, Config.Commands.PreviousAlert.description, 'keyboard', Config.Commands.PreviousAlert.key)

    RegisterNetEvent('origen_police:dispatch:alertas', function(src, args, raw)
        local PlayerData = FW_GetPlayerData(false)
        if (not onduty or IsNuiFocused()) or not CanOpenTablet(PlayerData.job.name)[1] then return end
        OcultarDispatch(showing)
    end)

    RegisterNetEvent('origen_police:dispatch:toggleReady', function(src, args, raw)
        local PlayerData = FW_GetPlayerData(false)
        if (not onduty or IsNuiFocused()) or not CanOpenTablet(PlayerData.job.name)[1] then return end
        SendNUIMessage({
            action = "ToggleReadyKeybind"
        })
    end)
    
    RegisterNetEvent('origen_police:dispatch:mrkalert', function(src, args, raw)
        if not onduty then return end
        if showing and currentselected > 0 and MyAlerts[currentselected] then
            --[[ Por el blip: IsWaypointActive() no cuenta el punto que pone
                 nuestro mapa. Ver origen_map/shared/marcar.lua.

                 Antes, con CUALQUIER punto puesto (el GPS de otra cosa, otro
                 aviso) la tecla lo borraba y «desmarcaba» en vez de marcar el
                 aviso de la tarjeta: habia que pulsar dos veces. Ahora solo se
                 desmarca si el punto esta sobre ESTE aviso (40 m, el mismo
                 margen que VigilarRutaDeAviso); si no, se marca. ]]
            local aviso = MyAlerts[currentselected]
            local c = aviso.coords
            local punto = OrigenMapa.Waypoint()
            local sobreEste = punto and c and c.x and #(vector2(c.x + 0.0, c.y + 0.0) - punto.xy) <= 40.0

            if sobreEste then
                DeleteWaypoint()
                alertaMarcadaCode = nil
                TriggerServerEvent("origen_police:server:RespondToAlert", { code = aviso.code }, false)
            elseif c and c.x then
                local alertDistance = #(vector3(c.x + 0.0, c.y + 0.0, (c.z or 0) + 0.0) - GetEntityCoords(PlayerPedId()))
                if alertDistance > 10 then
                    if punto then DeleteWaypoint() end
                    alertaMarcadaCode = aviso.code or aviso.id
                    SetNewWaypoint(tonumber(c.x), tonumber(c.y))
                    -- Tambien los avisos del SAMS apuntan la unidad (antes solo
                    -- avisaban al herido y en la lista salia «Nadie en camino»).
                    TriggerServerEvent("origen_police:server:RespondToAlert", { code = aviso.code }, true)
                    if aviso.job == "ambulance" then
                        TriggerServerEvent("origen_police:server:NotifyEMSOnWay", aviso.code)
                    end
                else
                    ShowNotification(Config.Translations.ClosestAlert)
                end
            end
        end
    end)
    
    RegisterNetEvent('origen_police:dispatch:delalert', function(src, args, raw)
        if not onduty then return end
        if showing then
            Del()
        end
    end)
    
    RegisterCommand(Config.Commands.NextAlert.cmd, function(src, args, raw)
        if not onduty then return end
        if showing then
            Next()
        end
    end)
    
    RegisterCommand(Config.Commands.PreviousAlert.cmd, function(src, args, raw)
        if not onduty then return end
        if showing then
            Prev()
        end
    end)

    SendNUIMessage({
        action = "SetDispatchTheme",
        theme = "default"
    })

    CreateThread(VigilarRutaDeAviso)
end

--[[ ── La distancia al aviso marcado, en vivo ──────────────────────────────

     La distancia que trae cada aviso se calcula una vez, al llegar, y ya no se
     mueve. Con el punto puesto lo que sirve es cuánto te queda.

     Vale marque quien marque: la tecla de aceptar, la central o un clic en el
     mapa de origen_map. Se mira el punto del mapa (el blip 8, ver
     OrigenMapa.Waypoint) y el aviso más cercano a él. El clic en el mapa no cae
     justo encima del aviso, así que se da un margen.

     Solo se manda cuando cambia de verdad (aviso distinto o 5 m), para no
     mandar un mensaje a la NUI cada vuelta. ]]
local MARGEN_PUNTO = 250.0
local rutaEnviada = nil -- { code, metros } lo último que tiene la NUI

RegisterNetEvent('origen_police:client:SetAlertaMarcadaCode', function(code)
    alertaMarcadaCode = code
end)

local function avisoDelPunto(punto)
    if not punto or not punto.x then return nil end
    local mejor, mejorD
    for i = 1, #MyAlerts do
        local c = MyAlerts[i].coords
        if c and c.x then
            local dx = (c.x + 0.0) - punto.x
            local dy = (c.y + 0.0) - punto.y
            local d = math.sqrt(dx * dx + dy * dy)
            if d <= MARGEN_PUNTO and (not mejorD or d < mejorD) then
                mejor, mejorD = MyAlerts[i], d
            end
        end
    end
    return mejor
end

local function buscarAvisoPorCodigo(code)
    if not code then return nil end
    local sCode = tostring(code)
    for i = 1, #MyAlerts do
        local a = MyAlerts[i]
        if a and (tostring(a.code or '') == sCode or tostring(a.id or '') == sCode) then
            return a
        end
    end
    return nil
end

function VigilarRutaDeAviso()
    while true do
        local espera = 1000
        local aviso = nil

        if onduty and #MyAlerts > 0 then
            local punto = OrigenMapa.Waypoint()
            if punto then
                if alertaMarcadaCode then
                    aviso = buscarAvisoPorCodigo(alertaMarcadaCode)
                end
                if not aviso then
                    aviso = avisoDelPunto(punto)
                    if aviso then
                        alertaMarcadaCode = aviso.code or aviso.id
                    end
                end
            else
                alertaMarcadaCode = nil
            end
        else
            alertaMarcadaCode = nil
        end

        if aviso and aviso.coords and aviso.coords.x then
            espera = 500
            local c = aviso.coords
            local yo = GetEntityCoords(PlayerPedId())
            local dx = (c.x + 0.0) - yo.x
            local dy = (c.y + 0.0) - yo.y
            local dz = ((c.z or yo.z) + 0.0) - yo.z
            local distLinea = math.sqrt(dx * dx + dy * dy + dz * dz)
            local okCar, carretera = pcall(CalculateTravelDistanceBetweenPoints, yo.x, yo.y, yo.z, c.x + 0.0, c.y + 0.0, (c.z or yo.z) + 0.0)
            local metros = math.floor((okCar and carretera and carretera > 0 and carretera < 50000 and carretera >= (distLinea * 0.7)) and carretera or distLinea)
            local code = (aviso.code and tostring(aviso.code)) or (aviso.id and tostring(aviso.id)) or nil
            if not rutaEnviada or rutaEnviada.code ~= code or math.abs(rutaEnviada.metros - metros) >= 5 then
                rutaEnviada = { code = code, metros = metros }
                SendNUIMessage({ action = "DispatchRuta", code = code, metros = metros })
            end
        elseif rutaEnviada then
            rutaEnviada = nil
            SendNUIMessage({ action = "DispatchRuta" })
        end

        Wait(espera)
    end
end

--[[ Se manda SIEMPRE, aunque `showing` no cambie. Antes solo se mandaba al
     cambiar, y la interfaz y Lua se desincronizaban: al cerrar la tablet la
     interfaz se quedaba sin HUD (view 'none') con `showing` a true, y la
     primera pulsacion de «mostrar» lo apagaba en Lua y no se veia nada; habia
     que pulsar dos veces. Un mensaje de mas no cuesta nada. ]]
function ToggleAlerts(value)
    if value == nil then
        value = not showing
    end
    showing = (value and not ocultoAMano) and true or false
    SendNUIMessage({
        action = "ShowAlerts",
        value = showing
    })
end

function OcultarDispatch(oculto)
    ocultoAMano = oculto == true
    SetResourceKvp(KVP_OCULTO, ocultoAMano and 'si' or 'no')
    ToggleAlerts(not ocultoAMano)
    TriggerEvent('origen_notify:client:Notify', 'Dispatch',
        ocultoAMano and 'Dispatch ocultado' or 'Dispatch visible',
        ocultoAMano and 'error' or 'success')
end

-- Lo que pinta el interruptor de Ajustes al abrirse.
RegisterNUICallback("DispatchOculto", function(_, cb)
    cb({ oculto = ocultoAMano })
end)

RegisterNUICallback("SetDispatchOculto", function(data, cb)
    if onduty then OcultarDispatch(type(data) == "table" and data.oculto == true) end
    cb({ oculto = ocultoAMano })
end)

--[[ «Borrar todas mis alertas» de Ajustes: lo mismo que Del() una a una, de
     golpe. Solo vacia MI lista; a los demas no les quita nada. ]]
RegisterNUICallback("BorrarMisAvisos", function(_, cb)
    MyAlerts = {}
    currentselected = 0
    alertaMarcadaCode = nil
    ToggleAlerts(false)
    SendNUIMessage({ action = "NoAlert", total = 0 })
    cb(true)
end)

-- Al cerrar la tablet la interfaz esconde el HUD: se le vuelve a decir como
-- tiene que quedar (client/menu/main.lua, TogglePause).
function ReenviarVistaDispatch()
    ToggleAlerts(showing)
end

--[[ La tarjeta que se ve en el HUD la elige la interfaz (flechas, clic): se
     avisa aqui del codigo para que la tecla de marcar marque ESA y no la que
     Lua tenia seleccionada por su cuenta. Solo mueve el indice local. ]]
RegisterNUICallback("DispatchElegir", function(data, cb)
    cb(true)
    local code = type(data) == "table" and data.code or nil
    if code == nil then return end
    code = tostring(code)
    for i = 1, #MyAlerts do
        if tostring(MyAlerts[i].code) == code then
            currentselected = i
            return
        end
    end
end)



RegisterNetEvent('origen_police:client:ReceiveAlert', function(alert, mark)
    local myJobName = PlayerData and PlayerData.job and PlayerData.job.name
    if myJobName then
        local myLevel = PlayerData and PlayerData.job and ((type(PlayerData.job.grade) == "table" and (PlayerData.job.grade.level or PlayerData.job.grade.grade)) or PlayerData.job.grade) or 0
        myLevel = tonumber(myLevel) or 0
        local isStateAdmin = (myJobName == "sapd")
        local reqGrade = GetMinimunGrade(myJobName, "ReceiveAlerts")
        local canReceive = isStateAdmin or (reqGrade == nil and IsBoss(myLevel)) or (reqGrade ~= nil and myLevel >= tonumber(reqGrade))
        if not canReceive then return end
    end

    -- Asegurar que el NUI del dispatch está inicializado aunque SetDuty no haya corrido aún
    if not started then StartAlerts() end

    -- Con los avisos detenidos solo entra el que te asigna la central a ti.
    if silenciado and not alert.central then return end

    if filter and alert.type and alert.type ~= "GENERAL" and alert.type ~= "SATELITE" then
        local found = false
        for i = 1, #filter do
            if filter[i] == alert.type then
                found = true
                break
            end
        end
        if not found then
            return
        end
    end

    if PlayDispatchAlertSound then
        PlayDispatchAlertSound(alert)
    end
    if type(alert.coords) == "table" then
        alert.coords = vector3(alert.coords.x, alert.coords.y, alert.coords.z)
    end
    alert.distance = #(GetEntityCoords(PlayerPedId()) - alert.coords)

    if alert.distance < 1000 then
        alert.distance = FW_Round(alert.distance, 2) .. ' m'
    else
        alert.distance = FW_Round(alert.distance/1000, 2) .. ' Km'
    end
    alert.street = GetStreetNameFromHashKey(GetStreetNameAtCoord(alert.coords.x, alert.coords.y, alert.coords.z))
    alert.time = GetGameTimer()
    table.insert(MyAlerts, alert)

    if Config.SelectNewAlert then
        if not stopAutoAdvance then
            currentselected = #MyAlerts
            SetAlert(currentselected)
        else
            SendNUIMessage({
                action = "UpdateAlertCount",
                total = #MyAlerts
            })
        end
    end

    if mark then
        if OrigenMapa.Waypoint() then
            DeleteWaypoint()
        end
        if currentselected > 0 and MyAlerts[currentselected] then
            alertaMarcadaCode = MyAlerts[currentselected].code or MyAlerts[currentselected].id
            SetNewWaypoint(tonumber(MyAlerts[currentselected].coords.x), tonumber(MyAlerts[currentselected].coords.y))
        end
    end
    
    if Config.OpenDispatchOnAlert then
        if not (stopAutoAdvance and not showing) then
            ToggleAlerts(true)
        end
    end
end)

RegisterNetEvent('origen_police:client:setReporterDispatchSubscription', function(enabled)
    SendNUIMessage({
        action = "SetDispatchTheme",
        theme = enabled == true and "weazel" or "default"
    })

    if enabled == true then
        ToggleAlerts(true)
    else
        ToggleAlerts(false)
    end
end)

function Prev()
    if MyAlerts[currentselected - 1] then
        currentselected = currentselected - 1
        SetAlert(currentselected)
        return true
    else
        return false
    end
end

function Next()
    if MyAlerts[currentselected + 1] then
        currentselected = currentselected + 1
        SetAlert(currentselected)
        return true
    else
        return false
    end
end

function Del(number)
    if not number then
        number = currentselected
    end
    if type(MyAlerts) ~= "table" then MyAlerts = {} end
    local deletedAlert = nil
    for k, v in pairs(MyAlerts) do
        if k == number then
            deletedAlert = v
            table.remove(MyAlerts, k)
            break
        end
    end

    if deletedAlert then
        SendNUIMessage({
            action = "removeAlert",
            id = deletedAlert.id or deletedAlert.code or number,
            code = deletedAlert.code,
            total = #MyAlerts
        })
    end

    if #MyAlerts == 0 then
        currentselected = 0
        ToggleAlerts(false)
        SendNUIMessage({
            action = "NoAlert",
            total = 0
        })
        return
    end

    if currentselected > #MyAlerts then
        currentselected = #MyAlerts
    end

    SetAlert(currentselected)
end

function SetAlert(number)
    if currentselected ~= number then currentselected = number end
    local newalert = MyAlerts[number]

    if newalert then
        local myFreq = nil
        pcall(function()
            myFreq = exports["origen_police"]:GetMultiFrec()
        end)
        if not myFreq or myFreq == "none" or myFreq == "" then
            myFreq = LocalPlayer.state.radioChannel or LocalPlayer.state.radio
        end

        SendNUIMessage({
            action = "SetAlert",
            title = newalert.title,
            message = newalert.message,
            annotation = newalert.annotation,
            metadata = newalert.metadata,
            distance = newalert.distance,
            street = newalert.street,
            code = newalert.code,
            central = newalert.central,
            playerID = newalert.playerID,
            unit = newalert.unit,
            count = currentselected,
            ago = math.ceil((GetGameTimer() - newalert.time)/1000),
            total = #MyAlerts,
            color = newalert.color,
            radioFreq = myFreq and tostring(myFreq) or nil
        })
        return true
    else
        return false
    end
end

function GetAlertFromId(alertid)
    local retval, found = false, false
    if type(MyAlerts) ~= "table" then MyAlerts = {} end
    for k, v in pairs(MyAlerts) do
        if v.id == alertid then
            retval = MyAlerts[k]
            found = k
            break
        end
    end

    return retval, found
end

exports('GetAlertFromId', GetAlertFromId)

RegisterNUICallback("SetFilter", function(data, cb)
    if data and data.filter then
        if data.filter == "none" then
            filter = { "__NONE__" }
        elseif data.filter == "all" then
            filter = nil
        elseif type(data.filter) == "table" then
            filter = data.filter
        else
            filter = { data.filter }
        end
    else
        filter = nil
    end
    silenciado = data ~= nil and data.filter == "none"
    cb(true)
end)

--[[ «Detener avisos» (12/10). El filtro de arriba solo mira el tipo, y los
     entornos llegan sin tipo o como GENERAL: pasaban siempre. Ademas el mismo
     aviso entra por otros dos eventos (client/menu/police.lua) que no miraban
     nada. Ahora los tres preguntan aqui. ]]
function AvisosDetenidos()
    return silenciado
end

--[[ Los ajustes de la tablet mandaban { stop = { stop = false } } (una tabla,
     que en Lua es verdadera): tras pulsar «Guardar» en Ajustes los avisos
     nuevos ya no se seleccionaban ni abrian el HUD si estaba cerrado, y solo
     sumaban al contador. Solo cuenta un true de verdad. ]]
RegisterNUICallback("SetAutoAdvance", function(data, cb)
    local stop = type(data) == "table" and data.stop or nil
    if type(stop) == "table" then stop = stop.stop end
    stopAutoAdvance = stop == true
    cb(true)
end)

function ClearAllAlertBlips()
    if type(MyAlerts) == "table" then
        for i = 1, #MyAlerts do
            MyAlerts[i].blipDeleted = true
        end
    end
    if alertaMarcadaCode and OrigenMapa and OrigenMapa.Waypoint and OrigenMapa.Waypoint() then
        DeleteWaypoint()
        alertaMarcadaCode = nil
    end
end

RegisterNUICallback("ClearAlertBlips", function(data, cb)
    ClearAllAlertBlips()
    cb(true)
end)

RegisterNUICallback("SetAlertsCleared", function(data, cb)
    ClearAllAlertBlips()
    cb(true)
end)

RegisterNetEvent("origen_police:client:EditAlert", function(data)
    for i = 1, #MyAlerts do
        if MyAlerts[i].code == data.code then
            if type(data) ~= "table" then data = {} end
            local originalTime = MyAlerts[i].time -- Preservar el time local para evitar segundos negativos
            local originalDistance = MyAlerts[i].distance -- Preservar la distancia local para evitar que se pise con la de quien respondió
            local wasBlipDeleted = MyAlerts[i].blipDeleted
            for k, v in pairs(data) do
                MyAlerts[i][k] = v
            end
            MyAlerts[i].time = originalTime -- Restaurar el time original (GetGameTimer es local a cada cliente)
            MyAlerts[i].distance = originalDistance -- Restaurar la distancia original
            if wasBlipDeleted then MyAlerts[i].blipDeleted = true end
            if i == currentselected then
                SetAlert(currentselected)
            end
            break
        end
    end
end)

RegisterNetEvent("origen_police:client:removeAlert", function(alertData)
    local code = nil
    if type(alertData) == "table" then
        code = alertData.code or alertData.id
    else
        code = alertData
    end
    if not code then return end

    local codeStr = tostring(code)

    if type(MyAlerts) == "table" then
        for i = #MyAlerts, 1, -1 do
            local a = MyAlerts[i]
            if a and (tostring(a.code) == codeStr or tostring(a.id) == codeStr) then
                table.remove(MyAlerts, i)
                break
            end
        end
    end

    if alertaMarcadaCode and tostring(alertaMarcadaCode) == codeStr then
        alertaMarcadaCode = nil
        if OrigenMapa and OrigenMapa.Waypoint and OrigenMapa.Waypoint() then
            DeleteWaypoint()
        end
    end

    SendNUIMessage({
        action = "removeAlert",
        id = code,
        code = code,
        total = type(MyAlerts) == "table" and #MyAlerts or 0
    })

    if not MyAlerts or #MyAlerts == 0 then
        currentselected = 0
        ToggleAlerts(false)
        SendNUIMessage({
            action = "NoAlert",
            total = 0
        })
    else
        if currentselected > #MyAlerts then
            currentselected = #MyAlerts
        end
        if currentselected > 0 then
            SetAlert(currentselected)
        end
    end
end)

RegisterNetEvent("origen_police:client:ForceSelectAlert", function(data)
    local founded = false
    for i = 1, #MyAlerts do
        if MyAlerts[i].code == data.code then
            MyAlerts[i].central = true
            SetAlert(i)
            founded = true
            if OrigenMapa.Waypoint() then
                DeleteWaypoint()
            end
            alertaMarcadaCode = MyAlerts[i].code or MyAlerts[i].id
            SetNewWaypoint(tonumber(MyAlerts[i].coords.x), tonumber(MyAlerts[i].coords.y))
            break
        end
    end
    if not founded then
        data.central = true
        TriggerEvent("origen_police:client:ReceiveAlert", data, true)
    end
end)

--[[ ── Los avisos, para los mapas de ORIGEN ─────────────────────────────

     El minimapa y el mapa del menu de pausa ya no son los de GTA: los dibuja
     origen_map y origen_pausemenu con Leaflet, y ahi un blip nativo no se ve.
     Los avisos seguian creandose bien —y sonando, y saliendo en el panel—,
     pero en el mapa no aparecia ninguno.

     Asi que se los damos nosotros. Devuelve lo minimo que hace falta para
     pintar un punto: donde y como se llama. Los mapas preguntan cada pocos
     segundos; no se les manda nada, para que no haya que saber aqui quien
     tiene mapa abierto. ]]
exports('AvisosParaMapa', function()
    local t = {}

    for i = 1, #MyAlerts do
        local aviso = MyAlerts[i]
        local c = aviso and not aviso.blipDeleted and aviso.coords

        if c and c.x then
            t[#t + 1] = {
                x = c.x + 0.0,
                y = c.y + 0.0,
                etiqueta = aviso.title or aviso.message or aviso.street or 'Aviso',
            }
        end
    end

    return t
end)

exports('ClearAlertBlips', ClearAllAlertBlips)
RegisterNetEvent('origen_police:client:clearAlertBlips', ClearAllAlertBlips)
