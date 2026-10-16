--[[ LOS AVISOS DEL CUERPO

     Hambre y sed. Se miran cada cinco segundos y avisan mas a menudo cuanto peor
     estas: cada diez minutos por debajo del 50 %, cada cinco por debajo del
     25 %, cada minuto por debajo del 10 %.

     Y AHORA DICEN CUAL DE LAS TRES ES

     Antes los tres umbrales mandaban el mismo texto —"Tienes mucha hambre,
     deberias comer algo"— asi que la unica diferencia entre ir tirando y estar
     a punto de desmayarte era cada cuanto salia. En pantalla eso casi se
     notaba, por la frecuencia. En el TELEFONO no se nota nada: llega el mismo
     mensaje de la misma Smartband y no hay forma de saber si queda margen.

     Asi que cada umbral tiene el suyo, y estan escritos como los escribiria
     una pulsera: lo que mide y que hacer.

         50 %  ->  "Empiezas a tener hambre. Deberias comer algo pronto."
         25 %  ->  "Llevas demasiado tiempo sin comer. Busca algo de comida."
         10 %  ->  "Estas famelico. Come algo ya o vas a desmayarte."

     El texto de siempre —`TimeEat`, `TimeDrink`— sigue en los idiomas y se usa
     de reserva: si un servidor añade un umbral nuevo a la configuracion y no
     escribe su texto, sale el de antes en vez de salir la clave pelada. ]]

local lastHungerNotification = 0
local lastThirstNotification = 0

--[[ Cada cuanto avisar, y de que umbral se trata.

     Devuelve las dos cosas porque son la misma pregunta hecha una vez: se
     recorren los umbrales buscando el mas bajo que se haya cruzado, y ese es
     tanto el que manda la frecuencia como el que manda el texto. ]]
---@param status number
---@param type 'Hunger'|'Thirst'
---@return number|nil intervalo  ms entre avisos
---@return number|nil umbral     el umbral cruzado (50, 25, 10...)
local function GetNotificationInterval(status, type)
    if not Config.StatusNotifications.Enabled then return nil end

    local thresholds = Config.StatusNotifications[type]
    local interval = nil
    local currentThreshold = -1

    for threshold, minutes in pairs(thresholds) do
        if status <= threshold and threshold > currentThreshold then
            currentThreshold = threshold
            interval = minutes * 60000
        end
    end

    if not interval then return nil end

    return interval, currentThreshold
end

--[[ El texto de ese umbral, o el de siempre si no hay uno escrito.

     `locale:t` devuelve la clave tal cual cuando no la encuentra, asi que hay
     que comparar: sin esto, un umbral sin traducir le llegaria al jugador como
     "notify.TimeEat35". ]]
---@param base 'TimeEat'|'TimeDrink'
---@param umbral number|nil
---@return string
local function StatusMessage(base, umbral)
    if umbral then
        local clave = ('notify.%s%d'):format(base, umbral)
        local texto = locale:t(clave)

        if texto and texto ~= clave and texto ~= '' then return texto end
    end

    return locale:t('notify.' .. base)
end

CreateThread(function()
    while true do
        -- Cada 5 s: los avisos van por GetGameTimer (1-10 min), no por vueltas
        Wait(5000)

        if Config.StatusNotifications and Config.StatusNotifications.Enabled then
            local hunger, thirst
            if Bridge.GetPlayerHungerThirst then
                hunger, thirst = Bridge.GetPlayerHungerThirst()
            else
                hunger = Bridge.GetPlayerHunger()
                thirst = Bridge.GetPlayerThirst()
            end
            local currentTime = GetGameTimer()

            if hunger then
                local hungerInterval, hungerThreshold = GetNotificationInterval(hunger, 'Hunger')
                if hungerInterval and (currentTime - lastHungerNotification > hungerInterval) then
                    Bridge.Notify(StatusMessage('TimeEat', hungerThreshold), 'error')
                    lastHungerNotification = currentTime
                end
            end

            if thirst then
                local thirstInterval, thirstThreshold = GetNotificationInterval(thirst, 'Thirst')
                if thirstInterval and (currentTime - lastThirstNotification > thirstInterval) then
                    Bridge.Notify(StatusMessage('TimeDrink', thirstThreshold), 'error')
                    lastThirstNotification = currentTime
                end
            end
        end
    end
end)
