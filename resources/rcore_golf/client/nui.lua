
local menuOpen = false

-- ORIGEN: precios como en el resto del servidor, con punto de miles y la
-- moneda detrás («1.250 $», no «$1250»).
local function precioOrigen(n)
    local t = tostring(math.floor(tonumber(n) or 0))
    local signo, cifras = t:match('^(-?)(%d+)$')
    if not cifras then return t .. ' ' .. Texts.currency end
    cifras = cifras:reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')
    return signo .. cifras .. ' ' .. Texts.currency
end

function SendReactMessage(action, data)
    SendNUIMessage({
      action = action,
      data = data
    })
end

---@param shouldShow boolean
---@param locationName string
function toggleNuiFrame(shouldShow, locationName)
    menuOpen = shouldShow
    SetNuiFocus(shouldShow, shouldShow)
    SendReactMessage("setScoreboardData", nil)
    SendReactMessage("setVisible", shouldShow)
    SendReactMessage("setLocalPlayerSrc", LocalPlayerSrc)
    SendReactMessage("setTranslations", Texts)
    SendReactMessage("setCaddyRentalAvailable", not Config.HideCaddyRentalCheckbox)
    SendReactMessage("setClubRentalAvailable", (Config.ClubRentalAvailable and Config.RequireGolfClub))
    SendReactMessage("setCaddyPrice", precioOrigen(Config.RentalPrice))
    SendReactMessage("setClubPrice", precioOrigen(Config.ClubRentalPrice))
    SendReactMessage("setWagersEnabled", Config.WagersEnabled)
    SendReactMessage("setMinigamesWagersEnabled", Config.MinigameWagersEnabled)
    if locationName then
        local locationConfig = LocationsConfig[locationName]
        SendReactMessage("setLocationConfig", {
            name = locationName,
            hasRegular = #locationConfig.HolesConfig > 0,
            hasMinigames = locationConfig.MinigamesHoles ~= nil,
        })
    end
    if shouldShow then
        TriggerScreenblurFadeIn(0.0)
    else
        TriggerScreenblurFadeOut(0.0)
    end
    TriggerServerEvent("rcore_golf:setSubscribedToUI", locationName, shouldShow)
end

RegisterNetEvent("rcore_golf:closeNUI", function(locationName)
    menuOpen = false
    toggleNuiFrame(false, locationName)
end)

RegisterNUICallback("hideFrame", function(data, cb)
    toggleNuiFrame(false, data.locationName)
    cb({})
end)

RegisterNUICallback("joinLobby", function(data, cb)
    TriggerServerEvent("rcore_golf:joinLobby", data.locationName, data.hasCaddy, data.wagerValue, data.rentingClub, data.holesToPlay, data.selectedMinigame)
    cb({})
end)

RegisterNUICallback("leaveLobby", function(data, cb)
    TriggerServerEvent("rcore_golf:leaveLobby", data.locationName)
    cb({})
end)

RegisterNUICallback("disbandLobby", function(data, cb)
    TriggerServerEvent("rcore_golf:disbandLobby", data.locationName)
    cb({})
end)

RegisterNUICallback("startGame", function(data, cb)
    TriggerServerEvent("rcore_golf:startGame", data.locationName)
    cb({})
end)

RegisterNUICallback("kickPlayer", function(data, cb)
    TriggerServerEvent("rcore_golf:kickPlayer", data.locationName, data.playerSrc)
    cb({})
end)

function SetLobbyDataForNUI(inputLobbyData)
    local lobbyData = table.copy(inputLobbyData)

    if lobbyData then
        local uiPlayers = {}
        for playerSrc, playerInfo in pairs(lobbyData.players) do
            table.insert(uiPlayers, {
                playerSrc = playerSrc,
                name = playerInfo.name,
                joinOrder = playerInfo.joinOrder
            })
        end

        table.sort(uiPlayers, function(lhs, rhs)
            return lhs.joinOrder < rhs.joinOrder
        end)
        lobbyData.players = uiPlayers

        lobbyData.wagerExists = lobbyData.wagerValue and lobbyData.wagerValue > 0
    end

    SendReactMessage("setPendingLobbyData", lobbyData)
end

RegisterNetEvent("rcore_golf:sendPendingLobbyData", function(lobbyData)
    if LobbyData and LobbyData.hasStarted then
        SetLobbyDataForNUI(LobbyData)
    else
        SetLobbyDataForNUI(lobbyData)
    end
end)

function BlurFadeOut()
    if menuOpen then TriggerScreenblurFadeOut(0.0) end
end

function isNuiOpen()
    return menuOpen
end