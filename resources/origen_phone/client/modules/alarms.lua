--[[ Alarmas.

     Las vigila el cliente porque es quien tiene delante el reloj del juego, y
     porque tienen que sonar aunque el telefono este cerrado: una alarma que
     solo suena con la app abierta no es una alarma.

     La lista se pide al servidor al arrancar el telefono y cada vez que se
     cambia algo. Aqui solo se guarda en memoria y se mira la hora.
]]

Alarms = {}

Alarms.list = {}

--- Lo ultimo que sono, para no repetir la misma alarma dentro del mismo minuto
--- del juego (que dura unos dos segundos de verdad, asi que el hilo pasa por
--- aqui varias veces).
local lastFired = {}

--- La alarma que esta sonando ahora mismo, si hay alguna.
local ringing = nil

-- ---------------------------------------------------------------------------
--  Datos
-- ---------------------------------------------------------------------------

--- Reemplaza la lista completa. La manda el servidor.
---@param alarms table[]
function Alarms.Set(alarms)
    Alarms.list = alarms or {}
end

--- Vuelve a pedirla. Se llama despues de crear, cambiar o borrar una.
function Alarms.Refresh()
    if not Phone.number then return end

    local alarms = lib.callback.await('origen_phone:rpc', false, 'alarms:list', {})
    if alarms and alarms.ok ~= false then
        Alarms.Set(alarms.data or alarms)
    end
end

-- ---------------------------------------------------------------------------
--  Sonar
-- ---------------------------------------------------------------------------

--- ¿Toca esta alarma a esta hora y en este dia?
---@param alarm table
---@param hour number
---@param minute number
---@param weekday number
---@return boolean
local function Matches(alarm, hour, minute, weekday)
    if not alarm.enabled then return false end
    if alarm.hour ~= hour or alarm.minute ~= minute then return false end

    -- Sin dias marcados suena todos los dias.
    if not alarm.days or #alarm.days == 0 then return true end

    for i = 1, #alarm.days do
        if alarm.days[i] == weekday then return true end
    end

    return false
end

--- Hace sonar la alarma: ruido, vibracion y aviso en la interfaz.
---@param alarm table
local function Ring(alarm)
    ringing = alarm

    -- La interfaz pinta el aviso a pantalla completa si el telefono esta
    -- abierto, y una notificacion si no.
    Nui.Send('alarmRinging', {
        id = alarm.id,
        label = alarm.label,
        hour = alarm.hour,
        minute = alarm.minute,
    })

    CreateThread(function()
        local until_ = GetGameTimer() + (Config.Alarms.RingSeconds * 1000)

        while ringing and ringing.id == alarm.id and GetGameTimer() < until_ do
            Calls.PlayAlert()
            SetControlShakeParameters(0, 200, 80)
            Wait(1500)
        end

        -- Si nadie la ha parado, se calla sola.
        if ringing and ringing.id == alarm.id then
            Alarms.Stop()
        end
    end)
end

--- Calla la que este sonando.
function Alarms.Stop()
    if not ringing then return end

    ringing = nil
    Nui.Send('alarmStopped', true)
end

-- ---------------------------------------------------------------------------
--  El vigilante
-- ---------------------------------------------------------------------------

CreateThread(function()
    while true do
        -- Cada dos segundos: un minuto del juego dura mas o menos eso, asi que
        -- no se escapa ninguno, y no cuesta nada.
        Wait(2000)

        if Phone.number and #Alarms.list > 0 and not ringing then
            local hour, minute = GetClockHours(), GetClockMinutes()
            local weekday = GetClockDayOfWeek()
            local key = ('%d:%d'):format(hour, minute)

            for i = 1, #Alarms.list do
                local alarm = Alarms.list[i]

                if Matches(alarm, hour, minute, weekday) and lastFired[alarm.id] ~= key then
                    lastFired[alarm.id] = key
                    Ring(alarm)

                    --[[ Una alarma sin dias marcados es de un solo uso: se
                         apaga sola despues de sonar, como en cualquier movil.
                         Se apaga en el servidor para que siga apagada al
                         volver a entrar. ]]
                    if not alarm.days or #alarm.days == 0 then
                        alarm.enabled = false
                        lib.callback.await('origen_phone:rpc', false, 'alarms:toggle', { id = alarm.id })
                    end

                    break
                end
            end
        end
    end
end)

-- ---------------------------------------------------------------------------
--  Lo que pide la interfaz
-- ---------------------------------------------------------------------------

Nui.On('stopAlarm', function()
    Alarms.Stop()
    return true
end)

Nui.On('alarmsChanged', function()
    Alarms.Refresh()
    return true
end)
