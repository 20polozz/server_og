--[[ NOTA DE ORIGEN: este recurso ya no crea blips del juego.

     Los puntos se registran en origen_map, que es de donde los leen los tres
     mapas del servidor (el minimapa, el del menu de pausa y la pestaña de
     Ciudad del inventario). El ayudante que lo hace se carga desde el
     fxmanifest: '@origen_map/shared/marcar.lua'.

     Es un recurso de terceros: si llega una version nueva, este cambio hay que
     volver a hacerlo. ]]

if Link.dispatch.system ~= 'standalone' then return end

function SendDispatchMessage(data)
    local dispatchData = {
        coords = data.coords or GetEntityCoords(PlayerPedId()),
        jobs = data.jobs or {'police', 'lspd', 'bcso'},
    
        title = data.message or '',
        subtitle = data.description or '',
        
        duration = 120000,
        
        blip = {
            sprite = (data.blip.sprite or 58),
            color = (data.blip.color or 1),
            scale = (data.blip.scale or 1.0),
            text = (data.blip.text or 'Dispatch Alert'),
            flash = (data.blip.flash or false),
        }
    }
    
    TriggerServerEvent('kq_link:server:dispatch:sendAlert', dispatchData)
end


RegisterNetEvent('kq_link:client:dispatch:sendAlert')
AddEventHandler('kq_link:client:dispatch:sendAlert', function(data)
    if not Contains(data.jobs, GetPlayerJob()) then
        return
    end
    
    CreateDispatchBlip(data)
    
    NotifyDispatch(data.title, data.subtitle)
end)


--- NOTA DE ORIGEN: un numero por aviso. Con una clave fija, cada aviso nuevo
--- borraba del mapa el anterior, que es justo lo contrario de lo que hace
--- falta cuando llegan tres seguidos.
local ultimoAviso = 0

function CreateDispatchBlip(data)
    Citizen.CreateThread(function()
        local blipData = data.blip
        ultimoAviso = ultimoAviso + 1
        local blip = 'aviso_' .. ultimoAviso
        OrigenMapa.Poner(blip, {
            x = data.coords.x, y = data.coords.y, z = data.coords.z,
            cat = 'avisos',
            nombre = blipData.text,
        })

        Citizen.SetTimeout(blipData.duration or 120000, function()
            OrigenMapa.Quitar(blip)
        end)
    end)
end

function NotifyDispatch(message, subtitle)
    --[[ Por el sistema de avisos del servidor, que es lo que llega al telefono.

         Antes salia por la libreta de GTA, arriba a la izquierda, y esa no pasa
         por ningun sitio: ni por origen_notify, ni por el telefono, ni por nada
         que se pueda tocar. Era el ultimo aviso del servidor que se escapaba.

         El titulo es el del propio aviso, no uno inventado: en un aviso de
         emergencia lo que dice de que va es justamente el titulo. ]]
    if GetResourceState('origen_notify') == 'started' then
        local ok = pcall(function()
            exports['origen_notify']:Notify({
                title = message,
                description = subtitle,
                type = 'error',
                duration = 8000,
            })
        end)

        if ok then return end
    end

    --- Y si no esta, la libreta de siempre: mejor ahi que en ningun sitio.
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(subtitle)

    local iconType = 0
    EndTextCommandThefeedPostMessagetext('CHAR_CALL911', 'CHAR_CALL911', false, iconType, message, '')

    EndTextCommandThefeedPostTicker(false, true)
end
