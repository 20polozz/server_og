-- Weather Admin Management --
local weatherTypes = {
    {
        label = 'Ventisca',
        value = 'BLIZZARD'
    },
    {
        label = 'Despejado',
        value = 'CLEAR'
    },
    {
        label = 'Despejándose',
        value = 'CLEARING'
    },
    {
        label = 'Nubes',
        value = 'CLOUDS'
    },
    {
        label = 'Muy soleado',
        value = 'EXTRASUNNY'
    },
    {
        label = 'Niebla',
        value = 'FOGGY'
    },
    {
        label = 'Neutro',
        value = 'NEUTRAL'
    },
    {
        label = 'Cubierto',
        value = 'OVERCAST'
    },
    {
        label = 'Lluvia',
        value = 'RAIN'
    },
    {
        label = 'Contaminación',
        value = 'SMOG'
    },
    {
        label = 'Nieve',
        value = 'SNOW'
    },
    {
        label = 'Nieve ligera',
        value = 'SNOWLIGHT'
    },
    {
        label = 'Tormenta',
        value = 'THUNDER'
    },
    {
        label = 'Navidad',
        value = 'XMAS'
    },
}

--- El nombre en español de un tipo de clima (llega la clave del juego, p. ej. 'RAIN').
local function NombreClima(valor)
    for i = 1, #weatherTypes do
        if weatherTypes[i].value == valor then return weatherTypes[i].label end
    end
    return valor
end

local function viewWeatherEvent(index, weatherEvent, isQueued)
    local metadata = isQueued and {
        ('Clima: %s'):format(NombreClima(weatherEvent.weather)),
        ('Dura %s minutos'):format(weatherEvent.time)
    } or {
        ('Clima: %s'):format(NombreClima(weatherEvent.weather)),
        ('Quedan %s minutos'):format(weatherEvent.time)
    }
    lib.registerContext({
        id = 'Renewed-Weathersync:client:changeWeather',
        title = 'Cambiar el clima',
        menu = 'Renewed-Weathersync:client:manageWeather',
        options = {
            {
                title = 'Información',
                icon = 'fa-solid fa-circle-info',
                readOnly = true,
                metadata = metadata
            },
            {
                title = 'Cambiar el clima',
                icon = 'fa-solid fa-cloud',
                arrow = true,
                onSelect = function()
                    local input = lib.inputDialog('Cambiar el tipo de clima', {
                        {
                            label = 'Elige el clima',
                            type = 'select',
                            required = true,
                            default = weatherEvent.weather,
                            options = weatherTypes
                        },
                    })

                    if input and input[1] then
                        local weather = lib.callback.await('Renewed-Weathersync:server:setWeatherType', false, index, input[1])

                        if weather then
                            weatherEvent.weather = weather
                        end
                    end

                    viewWeatherEvent(index, weatherEvent)
                end
            },
            {
                title = 'Cambiar la duración',
                arrow = true,
                icon = 'fa-solid fa-hourglass-half',
                onSelect = function()
                    local input = lib.inputDialog('Cambiar la duración', {
                        {
                            label = 'Duración en minutos',
                            type = 'slider',
                            required = true,
                            min = 1,
                            max = 120,
                            default = weatherEvent.time,
                        },
                    })

                    if input and input[1] then
                        local time = lib.callback.await('Renewed-Weathersync:server:setEventTime', false, index, input[1])

                        if time then
                            weatherEvent.time = time
                        end
                    end

                    viewWeatherEvent(index, weatherEvent)
                end
            },
            {
                title = 'Quitar de la cola',
                arrow = true,
                icon = 'fa-solid fa-circle-xmark',
                onSelect = function()
                    TriggerServerEvent('Renewed-Weather:server:removeWeatherEvent', index)
                end
            }
        }
    })

    lib.showContext('Renewed-Weathersync:client:changeWeather')
end

RegisterNetEvent('Renewed-Weather:client:viewWeatherInfo', function(weatherTable)
    -- ORIGEN: /weather abre el mismo panel de admin que el hub (pantalla completa).
    if AbrirPanelClima then return AbrirPanelClima(false) end
    local options = {}
    local amt = 0

    local startingIn = 0

    for i = 1, #weatherTable do
        local currentWeather = weatherTable[i]
        amt += 1

        local isQueued = i > 1

        local meatadata = isQueued and {
            ('Empieza en %s minutos'):format(startingIn),
            ('Dura %s minutos'):format(currentWeather.time)
        } or {
            ('Quedan %s minutos'):format(currentWeather.time)
        }

        options[amt] = {
            title = isQueued and ('Próximo clima: %s'):format(NombreClima(currentWeather.weather)) or ('Clima actual: %s'):format(NombreClima(currentWeather.weather)),
            description = isQueued and ('Empieza en %s minutos'):format(startingIn),
            arrow = true,
            icon = isQueued and 'fa-solid fa-cloud-arrow-up' or 'fa-solid fa-cloud',
            metadata = meatadata,
            onSelect = function()
                viewWeatherEvent(i, currentWeather, isQueued)
            end
        }

        startingIn += currentWeather.time
    end


    lib.registerContext({
        id = 'Renewed-Weathersync:client:manageWeather',
        title = 'Gestión del clima',
        options = options
    })

    lib.showContext('Renewed-Weathersync:client:manageWeather')
end)