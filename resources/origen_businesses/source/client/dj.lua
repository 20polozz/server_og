-- =====================================================
-- SISTEMA DJ – Cliente
-- Gestiona:
--   · Punto tipo 'dj'     → panel de control del DJ
--   · Punto tipo 'dj_zone' → polyzone donde se escucha la música
-- =====================================================

-- -------------------------------------------------------
-- Estado local
-- -------------------------------------------------------
local activeZones   = {}   -- zoneId → { polyzone, businessId, currentTrack }
local djPanelOpen   = false
local musicDisabled = GetResourceKvpString('origen_businesses:music_disabled') == 'true'


-- -------------------------------------------------------
-- Helpers youtube
-- -------------------------------------------------------
local function ExtractYouTubeId(url)
    if not url or url == '' then return nil end
    local id
    -- https://youtu.be/XXXXX
    id = url:match('youtu%.be/([%w_%-]+)')
    if id then return id end
    -- https://www.youtube.com/watch?v=XXXXX
    id = url:match('[&?]v=([%w_%-]+)')
    if id then return id end
    -- https://www.youtube.com/embed/XXXXX
    id = url:match('/embed/([%w_%-]+)')
    if id then return id end
    return nil
end

-- -------------------------------------------------------
-- NUI messages – reproducción en cada zona
-- -------------------------------------------------------
local function NUI_PlayInZone(zoneId, youtubeUrl, volume, offset)
    if musicDisabled then return end
    local yid = ExtractYouTubeId(youtubeUrl)
    if not yid then return end
    SendNUIMessage({
        action    = 'dj_play',
        zoneId    = zoneId,
        youtubeId = yid,
        volume    = volume or 0.7,
        offset    = offset or 0
    })
end

local function NUI_StopInZone(zoneId)
    SendNUIMessage({
        action = 'dj_stop',
        zoneId = zoneId
    })
end

local function NUI_SetVolumeInZone(zoneId, volume)
    if musicDisabled then return end
    SendNUIMessage({
        action = 'dj_volume',
        zoneId = zoneId,
        volume = volume
    })
end

-- -------------------------------------------------------
-- Streamer Mode (Mute music)
-- -------------------------------------------------------
local function SetMusicState(disabled)
    musicDisabled = disabled
    SetResourceKvp('origen_businesses:music_disabled', tostring(disabled))

    -- Altavoces, radios de coche, radio de admin (origen_speaker) y teles
    -- (origen_screens) se callan con este mismo aviso.
    TriggerEvent('origen:modoStreamer', musicDisabled)

    if musicDisabled then
        for zoneId, _ in pairs(activeZones) do
            SendNUIMessage({
                action = 'dj_stop',
                zoneId = zoneId
            })
        end
        Custom.Notify({
            title = 'Música',
            description = 'Modo Streamer activado (música de locales, altavoces, radios y teles en silencio)',
            type = 'inform'
        })
    else
        Custom.Notify({
            title = 'Música',
            description = 'Música activada',
            type = 'inform'
        })
        for zoneId, zData in pairs(activeZones) do
            if zData.inside then
                -- Request current state to resume music if inside a zone
                lib.callback('origen_businesses:dj:getZoneState', false, function(state)
                    -- Re-check if we are still inside and music is still enabled when callback returns
                    if state and state.playing and state.url and state.url ~= '' and not musicDisabled and activeZones[zoneId] and activeZones[zoneId].inside then
                        activeZones[zoneId].currentTrack = state
                        NUI_PlayInZone(zoneId, state.url, state.volume, state.elapsed)
                    end
                end, { zoneId = zoneId, businessId = zData.businessId })
            end
        end
    end
end

RegisterCommand('streamermode', function()
    SetMusicState(not musicDisabled)
end, false)

-- El ajuste se guarda aqui; los otros recursos lo preguntan al arrancar y,
-- si arrancaron antes que este, se enteran por el aviso.
exports('EnModoStreamer', function() return musicDisabled end)

CreateThread(function()
    TriggerEvent('origen:modoStreamer', musicDisabled)
end)

-- -------------------------------------------------------
-- Recibir eventos de servidor → reproducir / parar
-- -------------------------------------------------------
RegisterNetEvent('origen_businesses:dj:play', function(data)
    local zoneId = data.zoneId
    if not activeZones[zoneId] then
        activeZones[zoneId] = {}
    end
    
    activeZones[zoneId].currentTrack = data

    if activeZones[zoneId].inside then
        -- El jugador está dentro de esta zona
        NUI_PlayInZone(zoneId, data.url, data.volume, data.elapsed)
        activeZones[zoneId].pendingPlay = false
    else
        -- Guardar el estado por si entra luego
        activeZones[zoneId].pendingPlay = true
    end
end)

RegisterNetEvent('origen_businesses:dj:stop', function(data)
    local zoneId = data.zoneId
    NUI_StopInZone(zoneId)
    if activeZones[zoneId] then
        activeZones[zoneId].currentTrack = nil
        activeZones[zoneId].pendingPlay = false
    end
end)

RegisterNetEvent('origen_businesses:dj:volume', function(data)
    local zoneId = data.zoneId
    if not activeZones[zoneId] then
        activeZones[zoneId] = {}
    end
    if activeZones[zoneId].inside then
        NUI_SetVolumeInZone(zoneId, tonumber(data.volume) or 0.7)
    end
    if activeZones[zoneId].currentTrack then
        activeZones[zoneId].currentTrack.volume = tonumber(data.volume) or 0.7
    end
end)

RegisterNetEvent('origen_businesses:dj:next', function(data)
    -- Igual que play, se reutiliza
    TriggerEvent('origen_businesses:dj:play', data)
end)

-- -------------------------------------------------------
-- Polyzones de DJ (tipo 'dj_zone')
-- Se llama desde Business:SetPoints cuando encuentra
-- un punto de tipo 'dj_zone'
-- -------------------------------------------------------
function Business_RegisterDJZone(business, pData)
    local points = pData.zone_points or pData.points
    if not points or #points < 3 then return end

    local zoneId = tostring(pData.zone_id or (business.id .. '_dj'))

    -- Limpiar zona previa si existe
    if activeZones[zoneId] and activeZones[zoneId].polyzone then
        activeZones[zoneId].polyzone:remove()
    end

    local zone = lib.zones.poly({
        name      = 'dj_zone_' .. zoneId,
        points    = points,
        thickness = tonumber(pData.thickness) or 15.0,
        debug     = Config.Debug,
        onEnter   = function()
            if not activeZones[zoneId] then activeZones[zoneId] = {} end
            activeZones[zoneId].inside = true

            -- Preguntar al servidor el estado actual de esta zona
            lib.callback('origen_businesses:dj:getZoneState', false, function(state)
                if state and state.playing and state.url and state.url ~= '' then
                    activeZones[zoneId].currentTrack = state
                    NUI_PlayInZone(zoneId, state.url, state.volume, state.elapsed)
                end
            end, { zoneId = zoneId, businessId = business.id })
        end,
        onExit = function()
            if activeZones[zoneId] then
                activeZones[zoneId].inside = false
            end
            NUI_StopInZone(zoneId)
        end
    })

    activeZones[zoneId] = activeZones[zoneId] or {}
    activeZones[zoneId].polyzone   = zone
    activeZones[zoneId].businessId = business.id
end

-- -------------------------------------------------------
-- Panel de DJ (tipo 'dj')
-- Abre un menú para gestionar la cola de música de la zona
-- -------------------------------------------------------
function Business_OpenDJPanel(business, pData)
    local zoneId = tostring(pData.zone_id or (business.id .. '_dj'))

    -- Obtener cola actual + estado
    local state = lib.callback.await('origen_businesses:dj:getZoneState', false, {
        zoneId     = zoneId,
        businessId = business.id or tostring(business.id)
    })

    local queue   = (state and state.queue) or {}
    local current = (state and state.playing) and state or nil

    local function buildMenu()
        local menu = {
            {
                header       = '🎵 Mesa de DJ',
                isMenuHeader = true,
                icon         = 'fa-solid fa-music'
            }
        }

        -- Canción actual
        if current and current.url and current.url ~= '' then
            menu[#menu + 1] = {
                header = '▶ ' .. (current.title or current.url),
                txt    = 'Reproduciendo ahora · Volumen: ' .. math.floor((current.volume or 0.7) * 100) .. '%',
                icon   = 'fa-solid fa-compact-disc',
            }
            menu[#menu + 1] = {
                header = '🔊 Cambiar volumen',
                txt    = 'Ajustar el volumen de la canción actual',
                icon   = 'fa-solid fa-volume-high',
                params = {
                    handler = function()
                        local input = exports['org-input']:ShowInput({
                            header     = 'Cambiar volumen',
                            submitText = 'Guardar',
                            icon       = 'fa-solid fa-volume-high',
                            inputs     = {
                                {
                                    type        = 'number',
                                    name        = 'volume',
                                    text        = 'Volumen (0-100)',
                                    icon        = 'fa-solid fa-volume-high',
                                    placeholder = tostring(math.floor((current.volume or 0.7) * 100)),
                                    isRequired  = true,
                                }
                            }
                        })
                        if not input then return end
                        local vol = math.max(0, math.min(100, tonumber(input.volume) or 70)) / 100
                        TriggerServerEvent('origen_businesses:dj:setVolume', {
                            zoneId     = zoneId,
                            businessId = tostring(business.id),
                            volume     = vol
                        })
                        Wait(200)
                        Business_OpenDJPanel(business, pData)
                    end
                }
            }
            menu[#menu + 1] = {
                header = '⏭ Siguiente canción',
                txt    = 'Saltar a la siguiente de la cola',
                icon   = 'fa-solid fa-forward-step',
                params = {
                    handler = function()
                        TriggerServerEvent('origen_businesses:dj:next', {
                            zoneId     = zoneId,
                            businessId = tostring(business.id)
                        })
                    end
                }
            }
            menu[#menu + 1] = {
                header = '⏹ Parar música',
                txt    = 'Detener la reproducción en la zona',
                icon   = 'fa-solid fa-stop',
                params = {
                    handler = function()
                        TriggerServerEvent('origen_businesses:dj:stopZone', {
                            zoneId     = zoneId,
                            businessId = tostring(business.id)
                        })
                    end
                }
            }
        else
            menu[#menu + 1] = {
                header = 'Sin música activa',
                txt    = 'Añade canciones a la cola y pulsa reproducir',
                icon   = 'fa-solid fa-circle-pause',
            }
        end

        -- Cola de reproducción
        if #queue > 0 then
            menu[#menu + 1] = { header = '── Cola de reproducción ──', isMenuHeader = true }
            for i, track in ipairs(queue) do
                local item = {
                    header = ('#%d · %s'):format(i, track.title or track.url),
                    txt    = track.url,
                    icon   = 'fa-brands fa-youtube',
                    params = {
                        handler = function()
                            -- Tocar directamente desde la cola
                            TriggerServerEvent('origen_businesses:dj:playFromQueue', {
                                zoneId     = zoneId,
                                businessId = tostring(business.id),
                                index      = i
                            })
                        end
                    }
                }
                menu[#menu + 1] = item
            end
        end

        -- Añadir canción
        menu[#menu + 1] = {
            header = '➕ Añadir canción',
            txt    = 'Pegar un enlace de YouTube para añadir a la cola',
            icon   = 'fa-solid fa-plus',
            params = {
                handler = function()
                    local input = exports['org-input']:ShowInput({
                        header     = 'Añadir canción',
                        submitText = 'Añadir',
                        icon       = 'fa-brands fa-youtube',
                        inputs     = {
                            {
                                type        = 'text',
                                name        = 'url',
                                text        = 'Enlace de YouTube',
                                icon        = 'fa-solid fa-link',
                                isRequired  = true,
                                placeholder = 'https://youtu.be/...',
                            },
                            {
                                type        = 'number',
                                name        = 'volume',
                                text        = 'Volumen (0-100)',
                                icon        = 'fa-solid fa-volume-high',
                                placeholder = '70',
                            }
                        }
                    })

                    if not input then return end
                    local url = tostring(input.url or ''):gsub('^%s*(.-)%s*$', '%1')
                    if not ExtractYouTubeId(url) then
                        Custom.Notify({ title = 'DJ', description = 'Enlace de YouTube inválido.', type = 'error' })
                        return
                    end

                    local vol = math.max(0, math.min(100, tonumber(input.volume) or 70)) / 100

                    local result = lib.callback.await('origen_businesses:dj:addToQueue', false, {
                        zoneId     = zoneId,
                        businessId = tostring(business.id),
                        url        = url,
                        volume     = vol
                    })

                    if result and result.success then
                        Custom.Notify({ title = 'DJ', description = result.message or 'Canción añadida.', type = 'success' })
                        -- Reabrir menú actualizado
                        Wait(200)
                        Business_OpenDJPanel(business, pData)
                    else
                        Custom.Notify({ title = 'DJ', description = result and result.message or 'Error al añadir.', type = 'error' })
                    end
                end
            }
        }

        -- Limpiar cola
        if #queue > 0 then
            menu[#menu + 1] = {
                header = '🗑 Limpiar cola',
                txt    = 'Eliminar todas las canciones de la cola',
                icon   = 'fa-solid fa-trash',
                params = {
                    handler = function()
                        TriggerServerEvent('origen_businesses:dj:clearQueue', {
                            zoneId     = zoneId,
                            businessId = tostring(business.id)
                        })
                        Custom.Notify({ title = 'DJ', description = 'Cola limpiada.', type = 'inform' })
                    end
                }
            }
        end

        return menu
    end

    exports['org-menu']:openMenu(buildMenu())
end

-- -------------------------------------------------------
-- Limpiar zonas al parar el recurso
-- -------------------------------------------------------
AddEventHandler('onResourceStop', function(resourceName)
    if cache.resource ~= resourceName then return end
    for zoneId, zData in pairs(activeZones) do
        NUI_StopInZone(zoneId)
        if zData.polyzone then
            pcall(function() zData.polyzone:remove() end)
        end
    end
    activeZones = {}
end)
