TattooLists = {}
AppliedTattoos = {}
local interactionPoints = {}

--- Las tiendas tal como las reparte el servidor: se guardan para el panel de
--- admin y se pasan a la forma que usa el resto del recurso.
local function PonerTiendas(lista)
    if type(lista) ~= 'table' then return end
    local guardadas, nuevas = {}, {}
    for _, t in pairs(lista) do
        guardadas[t.id] = t
        nuevas[t.id] = TiendaParaElJuego(t)
    end
    TiendasGuardadas = guardadas
    Config.Stores = nuevas
end

local montado = false

--- Blips, tatuadores y puntos de entrada. Se llama al entrar y cada vez que
--- un admin cambia algo: quita lo de antes y lo vuelve a poner.
function MontarTiendas()
    for _, punto in pairs(interactionPoints) do punto:remove() end
    interactionPoints = {}
    if not openedMenu then lib.hideTextUI() end

    -- La tienda en la que estaba ya no existe: fuera.
    if openedMenu and currentStore and not Config.Stores[currentStore] then CloseMenu() end

    CreateBlips()
    CreateNpcs()

    for index, store in pairs(Config.Stores) do
        local point = lib.points.new({
            coords = store.coords,
            distance = 2.5,
            storeIndex = index
        })

        function point:onEnter()
            if not openedMenu then
                lib.showTextUI('[E] - Acceder a la tienda')
            end
        end

        function point:onExit()
            lib.hideTextUI()
        end

        function point:nearby()
            if not openedMenu and IsControlJustPressed(0, 38) then
                lib.hideTextUI()
                OpenMenu(index)
            end
        end

        interactionPoints[index] = point
    end
    montado = true
end

RegisterNetEvent('origen_tattoos:client:Tiendas', function(lista)
    PonerTiendas(lista)
    if montado then MontarTiendas() end
    AdminTiendasCambiadas()
end)

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(100)
    end

    -- Sin respuesta se queda con las del config, que es lo que habia.
    PonerTiendas(lib.callback.await('origen_tattoos:server:Tiendas', false))
    MontarTiendas()
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn and not openedMenu then 
            ApplyPlayerTattos()
        end
        Wait(1000) 
    end
end)

CreateThread(function()
    if next(TattooLists) then return end
    TattooLists = GetTattoosList()
    if LocalPlayer.state.isLoggedIn then
        AppliedTattoos = GetPlayerTattoos()
        ApplyPlayerTattos()
    end
end)