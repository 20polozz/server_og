--[[ NOTA DE ORIGEN: este recurso ya no crea blips del juego.

     Los puntos se registran en origen_map, que es de donde los leen los tres
     mapas del servidor (el minimapa, el del menu de pausa y la pestaña de
     Ciudad del inventario). El ayudante que lo hace se carga desde el
     fxmanifest: '@origen_map/shared/marcar.lua'.

     Es un recurso de terceros: si llega una version nueva, este cambio hay que
     volver a hacerlo. ]]

local nearbyLobbyMenuName = nil
local canPurchaseMembership = false

---@type GameData?
LobbyData = nil
---@type table<string, boolean>
IsInsideGrounds = {}

---@param lobbyCoords vector3
local function DrawLobbyMarker(lobbyCoords)
    DrawMarker(
        22,
        lobbyCoords.x, lobbyCoords.y, lobbyCoords.z +1,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.2, 0.2, 0.2,
        0, 0, 0, 155,
        false, true, 2, false, nil, nil, false
    )
end

---@param membershipPurchaseCoords vector3
local function DrawMembershipMarker(membershipPurchaseCoords)
    DrawMarker(
        22,
        membershipPurchaseCoords.x, membershipPurchaseCoords.y, membershipPurchaseCoords.z +1,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        1.0, 1.0, 1.0,
        0, 0, 0, 155,
        false, false, 2, true, nil, nil, false
    )
end

---@param lobbyCoords vector3
---@param locationName string
local function UpdateLobbyStart(lobbyCoords, locationName)
    local dist = #(LocalPedCoords - lobbyCoords)
    if dist <= 30.0 then
        DrawLobbyMarker(lobbyCoords)
        if dist <= 1.2 and not isNuiOpen() and not IsPauseMenuActive() then
            if not CaddyCreated then
                ShowHelpTextThisFrame("RGOLF_LOBBY", false)
            end
            nearbyLobbyMenuName = locationName
        else
            nearbyLobbyMenuName = nil
        end
    else
        nearbyLobbyMenuName = nil
        Wait(1000)
    end
end

---@param membershipPurchaseCoords vector3
local function UpdateMembership(membershipPurchaseCoords)

    local dist = #(LocalPedCoords - membershipPurchaseCoords)
    if dist <= 30.0 then
        DrawMembershipMarker(membershipPurchaseCoords)
        if dist <= 1.2 and not isNuiOpen() and not IsPauseMenuActive() then
            ShowHelpTextThisFrame("RGOLF_PURCHASE_MEMBERSHIP", false)
            if not canPurchaseMembership then
                canPurchaseMembership = true
            end
        else
            if canPurchaseMembership then
                canPurchaseMembership = false
            end
        end
    else
        if canPurchaseMembership then
            canPurchaseMembership = false
        end
    end
end

---@param locationConfig LocationConfig
local function IsLocationAvailable(locationConfig)
    if locationConfig.requiredResource and GetResourceState(locationConfig.requiredResource) ~= "started" then
        return false
    end
    return true
end

Citizen.CreateThread(function()
    AddTextEntry("RGOLF_LOBBY", string.format(Texts.openLobby, string.format("~INPUT_%08X~", GetHashKey(Texts.openLobbyCommand))))

    AddTextEntry("RGOLF_SHOW_SCORECARD", Texts.openScorecard)
    AddTextEntry("RGOLF_RETURN_BOUNDS", Texts.returnToBounds)
    AddTextEntry("RGOLF_START_SHOT", Texts.startShot)
    AddTextEntry("RGOLF_CADDY_SPAWNED", Texts.caddySpawned)

    -- Instrucciones de swing (garantizamos registro desde archivos editables)
    AddTextEntry("RGOLF_SWING_INSTR_S_KM", " ")
    AddTextEntry("RGOLF_SWING_APPROACH",   " ")
    AddTextEntry("RGOLF_SWING_POWER",      " ")
    AddTextEntry("RGOLF_SWING_PUNCH",      " ")

    if Config.MembershipEnabled then
        AddTextEntry("RGOLF_PURCHASE_MEMBERSHIP", string.format(Texts.purchaseMembership, string.format("~INPUT_%08X~", GetHashKey(Texts.openLobbyCommand)), Texts.currency..tostring(Config.MembershipPrice)))
    end

    for _, locationConfig in pairs(LocationsConfig) do
        if locationConfig.AddMapBlip then
            local blip = 'golf_' .. tostring(locationConfig.name or _)
            OrigenMapa.Poner(blip, {
                x = locationConfig.LobbyCoords.x, y = locationConfig.LobbyCoords.y, z = locationConfig.LobbyCoords.z,
                cat = 'activities',
                icono = 'golf',
                nombre = Texts.golfBlip or "Golf",
            })
            locationConfig.blip = blip
        end
    end

    --- NOTA DE ORIGEN: como esta pintado cada campo ahora mismo. El bucle de
    --- abajo corre cada fotograma cuando estas dentro, asi que el color solo se
    --- manda CUANDO CAMBIA; si no, serian cien avisos por segundo para decir
    --- siempre lo mismo.
    local apagado = {}

    while true do
        LocalPed = PlayerPedId()
        LocalPedCoords = GetEntityCoords(LocalPed)

        local inAnyLocation = false
        for locationName, locationConfig in pairs(LocationsConfig) do
            if IsLocationAvailable(locationConfig) then
                if locationConfig.blip and apagado[locationName] then
                    apagado[locationName] = false
                    OrigenMapa.Tintar(locationConfig.blip, '#5ad2e8')
                end

                local inGrounds = false

                for _, boundInfo in pairs(locationConfig.MainBounds) do
                    if #(LocalPedCoords - boundInfo[1]) < boundInfo[2] then
                        inGrounds = true
                        break
                    end
                end

                if inGrounds and not IsInsideGrounds[locationName] then
                    TriggerServerEvent("rcore_golf:setSubscribedToCourse", locationName, true)
                elseif IsInsideGrounds[locationName] and not inGrounds then
                    TriggerServerEvent("rcore_golf:setSubscribedToCourse", locationName, false)
                end

                IsInsideGrounds[locationName] = inGrounds

                if inGrounds then
                    UpdateLobbyStart(locationConfig.LobbyCoords, locationConfig.name)
                    if Config.MembershipEnabled then
                        UpdateMembership(locationConfig.MembershipPurchaseCoords)
                    end
                    inAnyLocation = true
                end
            --[[ NOTA DE ORIGEN: el campo cerrado ya no se esconde del mapa,
                 se apaga de color. Esconderlo era lo unico que sabia hacer un
                 blip (SetBlipDisplay 0/2); en el mapa del servidor un sitio
                 que esta pero esta cerrado es informacion, y quitarlo obliga a
                 acercarse para descubrirlo. ]]
            elseif locationConfig.blip and not apagado[locationName] then
                apagado[locationName] = true
                OrigenMapa.Tintar(locationConfig.blip, '#6b7280')
            end
        end

        Wait(inAnyLocation and 0 or 1000)
    end
end)

RegisterKeyMapping(Texts.openLobbyCommand, Texts.openLobbyCommandDescription, "KEYBOARD", Config.Keys.openLobbyKey)
RegisterCommand(Texts.openLobbyCommand, function()
    if not nearbyLobbyMenuName then return end
    toggleNuiFrame(true, nearbyLobbyMenuName)
end, false)



if Config.MembershipEnabled then
    local membershipCooldown = false
    RegisterKeyMapping(Texts.purchaseMembershipCommand, Texts.purchaseMembershipCommandDescription, "KEYBOARD", Config.Keys.openLobbyKey)
    RegisterCommand(Texts.purchaseMembershipCommand, function()
        if membershipCooldown or not canPurchaseMembership then return end
        membershipCooldown = true
        Citizen.SetTimeout(3000, function() membershipCooldown = false end)
        TriggerServerEvent("rcore_golf:purchaseMembership")
    end, false)
end

RegisterNetEvent("rcore_golf:sendLobbyData", function(lobbyData)
    LobbyData = lobbyData
    SetLobbyDataForNUI(LobbyData)
    InitMainThread()

    if lobbyData == nil and Config.DeleteCaddyAfterLeavingGame then
        local delay = Config.DeleteCaddyAfterLeavingDelay or 0
        Citizen.CreateThread(function()
            Wait(delay)
            DeleteEntity(vehicleCaddy)
            TriggerServerEvent("rcore_golf:deleteCaddy", vehicleCaddyNetId)
        end)
    end
end)

RegisterNetEvent("rcore_golf:displayNotification", function(message)
    exports['origen_notify']:showNotification({
        title = 'LS GOLF CLUB',
        description = message:gsub("~%a~", ""),
        type = 'primary',
        duration = 5000
    })
end)