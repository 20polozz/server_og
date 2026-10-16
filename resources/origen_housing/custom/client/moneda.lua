-- En qué se paga en la casa en la que está el jugador, para que la NUI pinte
-- la moneda buena: « $» en una particular, « $ negro» en una de banda y
-- « OGN» en una de crew (ui/js/propietario.js). Solo para pintar: quien
-- decide la moneda y cobra es el servidor (custom/server/moneda.lua).
local actual = nil

local function MonedaDe(house)
    local d = house and house.houseData and house.houseData.data
    local uso = type(d) == 'table' and d.uso or nil
    if uso == 'banda' then return 'negro' end
    if uso == 'crew' then return 'ogn' end
    return 'dinero'
end

local function Poner(moneda)
    if moneda == actual then return end
    actual = moneda
    SendNUIMessage({ action = 'monedaCasa', moneda = moneda })
end

-- La de la casa en la que está (dentro o en su zona de fuera); en ninguna, dinero.
CreateThread(function()
    while true do
        local id = currentInteriorHouseID or currentExteriorHouseID
        local house = id and House and House.get(id) or nil
        Poner(MonedaDe(house))
        Wait(1000)
    end
end)

-- El menú de la casa puede abrirse para una casa concreta: la suya, al momento.
CreateThread(function()
    while not Nui or not Nui.OpenHouseMenu do Wait(200) end
    local deSiempre = Nui.OpenHouseMenu
    Nui.OpenHouseMenu = function(data, ...)
        if type(data) == 'table' and data.id then
            Poner(MonedaDe(House.get(data.id)))
        end
        return deSiempre(data, ...)
    end
end)
