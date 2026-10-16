-- Hijack SendNUIMessage para capturar notificaciones y gestionar el menú
local nativeSendNUIMessage = SendNUIMessage
local currentMenuItems = {}
local menuTitle = "TENIS DE MESA"
local menuIdentifier = nil

local function OpenTennisInput()
    print("^3[rcore_pingpong] Preparando menú con org-input...^7")
    Citizen.CreateThread(function()
        local inputs = {}
        local playItem = nil

        -- Ordenar por índice para mantener el orden original si es posible
        local sortedItems = {}
        for _, it in ipairs(currentMenuItems) do 
            if it and it.index then
                table.insert(sortedItems, it) 
            end
        end
        table.sort(sortedItems, function(a, b) return (a.index or 0) < (b.index or 0) end)

        print("^2[rcore_pingpong] Items válidos capturados: ^7", #sortedItems)

        for _, item in ipairs(sortedItems) do
            if item.visible and item.itemType ~= 6 then
                local labelVisible = (item.label or "Sin título"):gsub("~[a-z]~", "")
                if item.itemType == 2 then -- Lista (ciclo/selector)
                    local options = {}
                    if item.data then
                        for i, val in ipairs(item.data) do
                            table.insert(options, { value = tostring(i), text = val:gsub("~[a-z]~", "") })
                        end
                    end
                    table.insert(inputs, {
                        type = "select",
                        name = "id_" .. item.index,
                        text = labelVisible,
                        options = options,
                        default = tostring(item.listIndex or 1)
                    })
                elseif item.itemType == 4 then -- Checkbox
                    table.insert(inputs, {
                        type = "checkbox",
                        name = "id_" .. item.index,
                        text = labelVisible,
                        options = {
                            { value = "id_" .. item.index, text = "Seleccionar", checked = item.checked or false }
                        }
                    })
                elseif item.itemType == 1 then -- Botón de acción
                    local lowerLabel = labelVisible:lower()
                    if lowerLabel:find("jugar") or lowerLabel:find("play") or lowerLabel:find("comenzar") or lowerLabel:find("start") then
                        print("^2[rcore_pingpong] Botón de Jugar detectado: ^7", item.label, " (index: "..item.index..")")
                        playItem = item
                    else
                        table.insert(inputs, {
                            type = "checkbox",
                            name = "id_" .. item.index,
                            text = labelVisible,
                            options = {
                                { value = "id_" .. item.index, text = "Activar", checked = false }
                            }
                        })
                    end
                end
            end
        end

        -- Si no hay botón de jugar detectado, usamos el último botón de acción como fallback
        if not playItem then
            for i = #sortedItems, 1, -1 do
                if sortedItems[i].itemType == 1 then
                    playItem = sortedItems[i]
                    print("^3[rcore_pingpong] No se detectó botón 'Jugar' por texto, usando fallback: ^7", playItem.label)
                    break
                end
            end
        end

        print("^2[rcore_pingpong] Mostrando org-input...^7")
        local data = exports['org-input']:ShowInput({
            header = menuTitle,
            submitText = playItem and playItem.label:gsub("~[a-z]~", "") or "Jugar",
            icon = "fa-solid fa-table-tennis-paddle-ball",
            inputs = inputs
        })

        if data then
            print("^2[rcore_pingpong] Procesando selección del usuario...^7")
            -- 1. Actualizar todas las opciones (Selectores y Checkboxes)
            for _, item in ipairs(currentMenuItems) do
                local val = data["id_" .. item.index]
                if val ~= nil then
                    -- Convertir "true"/"false" strings a booleano real
                    local boolVal = (val == "true")
                    
                    if item.itemType == 2 then
                        local listIdx = tonumber(val)
                        nativeSendNUIMessage({
                            type = "proxyPost",
                            endpoint = "updateLabel",
                            data = {
                                index = item.index,
                                listIndex = listIdx,
                                label = item.label,
                                displayLabel = item.data[listIdx],
                                identifier = menuIdentifier
                            }
                        })
                    elseif item.itemType == 4 or item.itemType == 1 then
                        -- Si es itemType 1 y fue marcado en el input, enviamos el click individual si no es el playItem
                        if item.itemType == 1 and item.index ~= (playItem and playItem.index or -1) then
                             if boolVal then
                                nativeSendNUIMessage({
                                    type = "proxyPost",
                                    endpoint = "clickItem",
                                    data = {
                                        index = item.index,
                                        label = item.label,
                                        displayLabel = item.secondLabel or "",
                                        identifier = menuIdentifier
                                    }
                                })
                             end
                        else
                            nativeSendNUIMessage({
                                type = "proxyPost",
                                endpoint = "updatecheck",
                                data = {
                                    index = item.index,
                                    checked = boolVal,
                                    identifier = menuIdentifier
                                }
                            })
                        end
                    end
                end
            end

            -- 2. Finalmente, activar el botón de jugar
            if playItem then
                print("^2[rcore_pingpong] Enviando click final a: ^7", playItem.label)
                Citizen.Wait(200)
                nativeSendNUIMessage({
                    type = "proxyPost",
                    endpoint = "clickItem",
                    data = {
                        index = playItem.index,
                        label = playItem.label,
                        displayLabel = playItem.secondLabel or "",
                        identifier = menuIdentifier
                    }
                })
            end
        else
            print("^1[rcore_pingpong] Menú cancelado.^7")
            -- Si cancela, cerramos el menú en los scripts originales
            nativeSendNUIMessage({
                type = "ui",
                status = false
            })
        end
    end)
end

SendNUIMessage = function(data)
    if not data then return end

    -- Capturar notificaciones
    if data.type == "notifybar" and data.content then
        local content = data.content:gsub("<span>", ""):gsub("</span>", "")
        content = content:gsub("~[a-z]~", "")
        exports.origen_notify:Notify({
            title = "Tenis de Mesa",
            description = content,
            type = "primary",
            duration = 5000
        })
        return
    end

    -- Gestionar datos del menú
    if data.type == "reset" then
        currentMenuItems = {}
    elseif data.type == "title" then
        menuTitle = (data.title or "TENIS DE MESA"):gsub("~[a-z]~", "")
    elseif data.type == "addpack" then
        if data.pack then
            for _, pack in ipairs(data.pack) do
                table.insert(currentMenuItems, pack)
            end
        end
    elseif data.type == "ui" then
        if data.status then
            print("^3[rcore_pingpong] Capturada señal de apertura de UI. ID: ^7", data.identifier)
            menuIdentifier = data.identifier
            OpenTennisInput()
            -- Permitimos que el mensaje pase al NUI original para que se establezca como visible internamente,
            -- el CSS (#menuui) se encarga de que no se vea el menú negro.
        end
    end

    nativeSendNUIMessage(data)
end

-- Redefinir mensajes de tamaño medio (se usan para puntos y resultados)
function ShowMidsizedMessage(test, desc)
    local title = test and test:gsub("~[a-z]~", "") or "Tenis de Mesa"
    local description = desc and desc:gsub("~[a-z]~", "") or ""
    exports.origen_notify:Notify({
        title = title,
        description = description,
        type = "info",
        duration = 5000
    })
end

-- Redefinir notificaciones de pantalla completa (se usan para finales de partida/bonus)
function ShowFullscreenBonusNotify(captionText, mainText, descriptionText, color, stats)
    local title = (captionText or mainText or "Tenis de Mesa"):gsub("~[a-z]~", "")
    local desc = descriptionText and descriptionText:gsub("~[a-z]~", "") or ""
    if stats and #stats > 0 then
        local strippedStats = {}
        for i, s in ipairs(stats) do
            strippedStats[i] = tostring(s):gsub("~[a-z]~", "")
        end
        desc = desc .. "<br>" .. table.concat(strippedStats, "<br>")
    end
    exports.origen_notify:Notify({
        title = title,
        description = desc,
        type = "primary",
        duration = 8000
    })
end

-- Función genérica de notificación
function Notify(text)
    exports.origen_notify:Notify({
        title = "Tenis de Mesa",
        description = text,
        type = "primary",
        duration = 5000
    })
end

-- Evento de notificación por si se dispara desde el servidor
RegisterNetEvent('rcore_pingpong:notify')
AddEventHandler('rcore_pingpong:notify', function(text)
    exports.origen_notify:Notify({
        title = "Tenis de Mesa",
        description = text,
        type = "primary",
        duration = 5000
    })
end)

-- Integración de texto de ayuda para interacciones
local nativeDisplayHelpTextThisFrame = DisplayHelpTextThisFrame
local lastHelpText = nil
local showingHelp = false
local inMatch = false

-- Funciones para gestionar los controles del HUD de Origen
function RefreshControls()
    inMatch = true
    exports['origen_hud']:setupControls({
        { key = 'C', text = 'Cámara' },
        { key = 'M', text = 'Ratón' },
        { key = 'BACK', text = 'Salir' }
    })
end

function HideControls()
    inMatch = false
    exports['origen_hud']:hideControls()
end

-- Última vez (GetGameTimer) que el juego pidió el texto de ayuda. El código
-- cifrado lo pide cada fotograma mientras estás junto a la mesa; cuando deja
-- de pedirlo (te alejas) el hilo de abajo lo quita de pantalla con HideText.
local lastHelpFrame = 0

local function QuitarAyuda()
    if showingHelp then
        exports.origen_notify:HideText()
    end
    showingHelp = false
    lastHelpText = nil
end

function DisplayHelpTextThisFrame(label, shape)
    -- Si estamos en partida, bloqueamos el texto de ayuda original para que no ensucie
    if inMatch then
        HideHelpTextThisFrame()
        QuitarAyuda()
        return
    end

    lastHelpFrame = GetGameTimer()
    if label and label ~= lastHelpText then
        lastHelpText = label
        BeginTextCommandGetLocalizedString(label)
        local text = EndTextCommandGetLocalizedString()

        if text and text ~= '' then
            -- La tecla va en <span>X</span> (locales/es.lua); el resto, sin
            -- etiquetas ni códigos de color de GTA.
            local key = text:match('<span>%s*([^<]-)%s*</span>') or 'E'
            text = text:gsub('<[^>]->', ''):gsub('~.-~', ''):gsub('%s+', ' ')
            exports.origen_notify:DrawText(key, text)
            showingHelp = true
        end
    end
end

-- Hijack de funciones de dibujo de Scaleform para bloquear el HUD nativo durante la partida
local nativeDrawScaleformMovie = DrawScaleformMovie
function DrawScaleformMovie(scaleform, x, y, width, height, r, g, b, a, p9)
    if inMatch then return end
    nativeDrawScaleformMovie(scaleform, x, y, width, height, r, g, b, a, p9)
end

local nativeDrawScaleformMovieFullscreen = DrawScaleformMovieFullscreen
function DrawScaleformMovieFullscreen(scaleform, r, g, b, a, p4)
    if inMatch then return end
    nativeDrawScaleformMovieFullscreen(scaleform, r, g, b, a, p4)
end

-- Hilo para limpiar el texto de ayuda y gestionar el estado del juego
Citizen.CreateThread(function()
    while true do
        if inMatch then
            -- Forzamos la ocultación del HUD nativo
            HideHelpTextThisFrame()
            ClearAllHelpMessages()
            HideHudComponentThisFrame(10) -- HELP_TEXT
            HideHudComponentThisFrame(13) -- CASH / BARS
            HideHudComponentThisFrame(20) -- HUD_WEAPON_WHEEL (Botones de instrucción a veces usan este)
            
            -- Desactivar controles de HUD
            DisableControlAction(0, 44, true) -- Q
            if showingHelp then QuitarAyuda() end
            
            Wait(0)
        else
            -- Si el juego lleva un rato sin pedir el texto de ayuda, ya no
            -- estás junto a la mesa: fuera de pantalla.
            if showingHelp and GetGameTimer() - lastHelpFrame > 600 then
                QuitarAyuda()
            end
            Wait(250)
        end
    end
end)

