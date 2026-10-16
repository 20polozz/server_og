--[[ ── El equipo de trabajo (cliente) ─────────────────────────────────────────

     La invitación: al invitado le sale el aviso de tecla de la casa
     (origen_notify) con Y para aceptar y N para rechazar. Si no contesta,
     caduca sola.

     Y `Equipo.Mismo(cid)`: si ese citizenid eres tú o va en tu equipo (lo
     dice la state bag que pone el servidor). Este fichero va igual en la
     granja, en el aserradero y en la mina. ]]

Equipo = {}

local E = Config.Equipo
local RECURSO = GetCurrentResourceName()
local TECLA_SI, TECLA_NO = 246, 306   -- Y, N

--- ¿Es tuyo o de tu equipo? `yo` es tu citizenid.
function Equipo.Mismo(cid, yo)
    if not cid then return false end
    if cid == yo then return true end
    local bag = LocalPlayer.state[E.bag]
    return bag ~= nil and bag.cids ~= nil and bag.cids[cid] == true
end

function Equipo.EnEquipo()
    return LocalPlayer.state[E.bag] ~= nil
end

local pendiente = nil

local function Quitar()
    pcall(function() exports.origen_notify:HideText() end)
end

local function Responder(acepta)
    pendiente = nil
    Quitar()
    lib.callback.await(RECURSO .. ':equipo:responder', false, acepta)
end

RegisterNetEvent(RECURSO .. ':equipo:invitacion', function(nombreTrabajo, deNombre, segundos)
    if GetInvokingResource() then return end
    local mia = { hasta = GetGameTimer() + (tonumber(segundos) or 30) * 1000 }
    pendiente = mia
    lib.notify({
        title = 'Equipo',
        description = ('%s te invita a su equipo de %s: lo que cobréis se reparte entre los que estéis de jornada.')
            :format(tostring(deNombre), tostring(nombreTrabajo)),
        type = 'inform', duration = 9000,
    })
    pcall(function()
        exports.origen_notify:DrawText('Y', ('Unirte al equipo de %s'):format(tostring(deNombre)), { 'N', 'Rechazar' })
    end)
    CreateThread(function()
        while pendiente == mia do
            if GetGameTimer() > mia.hasta then
                pendiente = nil
                Quitar()
                lib.notify({ title = 'Equipo', description = 'La invitación ha caducado.', type = 'inform' })
                break
            end
            if IsControlJustReleased(0, TECLA_SI) then
                Responder(true)
                break
            elseif IsControlJustReleased(0, TECLA_NO) then
                Responder(false)
                break
            end
            Wait(0)
        end
    end)
end)

AddEventHandler('onResourceStop', function(r)
    if r == RECURSO and pendiente then Quitar() end
end)
