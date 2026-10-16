Logs = {}
Logs.__index = Logs

function Logs.new(webhook)
    local self = setmetatable({}, Logs)
    self.webhook = webhook
    return self
end

-- Este archivo es shared_script: solo ejecutar lógica server-side en el servidor
if IsDuplicityVersion() then
    local WebhookBackoffUntil = {}

    -- Helper: comprobar si el jugador es staff via origen_admin
    local function IsStaffPlayer(source)
        if not source or not tonumber(source) then return false, nil end
        if GetResourceState('origen_admin') ~= 'started' then return false, nil end
        local ok, group = pcall(function()
            return exports['origen_admin']:GetAdmin(source)
        end)
        if ok and group then
            return true, group
        end
        return false, nil
    end

    -- Helper: enviar payload raw a una URL de webhook
    local function SendRawWebhook(url, payload)
        if not url or url == '' or url == 'YOUR_DISCORD_WEBHOOK' then return end
        PerformHttpRequest(url, function() end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
    end

    function Logs:SendLog(source, embed, message)
        if not self.webhook then return end
        local identifiers = "**IDENTIFIERS**"
        if tonumber(source) and tonumber(source) < 65000 then
            identifiers = identifiers .. "\nPLAYER ID: " .. source .. "\nPLAYER NAME: " .. GetPlayerName(source) .. "\n"
        else
            identifiers = identifiers .. "\nPLAYER ID: _It hasn't loaded yet_" .. "\nPLAYER NAME: " .. (GetPlayerName(source) or "_It hasn't loaded yet_") .. "\n"
        end
        for k, v in pairs(GetPlayerIdentifiers(source)) do
            if not string.find(v, "license2:") and not string.find(v, "ip:") then
                identifiers = identifiers .. SplitStr(v, ":")[1] .. ": " .. v .. "\n"
            end
        end
        ::skip_identifiers::

        -- Clonar embed para no mutar el original
        local embedCopy = embed and json.decode(json.encode(embed)) or nil
        local messageCopy = message

        if embedCopy then
            embedCopy.description = (embedCopy.description and embedCopy.description .. "\n\n" or "") .. identifiers
        end

        local payload = {
            content = (type(message) == "string" and message ~= "") and message or "",
            allowed_mentions = {
                parse = {"everyone", "roles", "users"}
            }
        }

        if embedCopy and type(embedCopy) == 'table' then
            payload.embeds = {embedCopy}
        end

        if not payload.embeds and payload.content == "" then
            payload.content = identifiers
        end

        local now = GetGameTimer()
        if WebhookBackoffUntil[self.webhook] and now < WebhookBackoffUntil[self.webhook] then
            return
        end

        PerformHttpRequest(self.webhook, function(err, text, headers)
            if err == 404 then
                -- Invalid/deleted webhook; avoid hammering Discord with the same dead URL.
                WebhookBackoffUntil[self.webhook] = GetGameTimer() + 300000
            elseif err == 429 then
                local retryAfter = tonumber(headers and (headers["retry-after"] or headers["Retry-After"])) or 15
                if retryAfter < 1000 then
                    retryAfter = retryAfter * 1000
                end
                WebhookBackoffUntil[self.webhook] = GetGameTimer() + retryAfter
            end
        end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })

        -- ===== STAFF LOG: Si el jugador es admin/mod/god, reenviar al canal staff =====
        local isStaff, adminGroup = IsStaffPlayer(source)
        if isStaff then
            -- Leer webhook directamente del export de origen_admin (más fiable que GlobalState)
            local staffWebhook = nil
            local ok, url = pcall(function()
                return exports['origen_admin']:GetStaffInventoryWebhook()
            end)
            if ok and url and url ~= '' and url ~= 'YOUR_DISCORD_WEBHOOK' then
                staffWebhook = url
            else
                -- Fallback al GlobalState
                staffWebhook = GlobalState['origen_admin:StaffInventoryWebhook']
            end

            if staffWebhook and staffWebhook ~= '' and staffWebhook ~= 'YOUR_DISCORD_WEBHOOK' then
                local staffEmbed = embedCopy and json.decode(json.encode(embedCopy)) or nil
                if staffEmbed then
                    staffEmbed.title = "[STAFF: " .. (adminGroup or "?"):upper() .. "] " .. (staffEmbed.title or "")
                    staffEmbed.color = 0xFFD700 -- gold para staff
                end
                local staffPayload = {}
                if staffEmbed then
                    staffPayload.embeds = {staffEmbed}
                else
                    staffPayload.content = "[STAFF: " .. (adminGroup or "?"):upper() .. "] " .. (messageCopy or "")
                end
                SendRawWebhook(staffWebhook, staffPayload)
            end
        end
    end

else
    -- Client side: SendLog no hace nada (los logs son server-side únicamente)
    function Logs:SendLog(source, embed, message) end
end