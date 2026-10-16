-- ── custom/client/store_money.lua ────────────────────────────────────────────
-- Official customization point for money-related UI labels and error messages.
--
-- These strings appear in buy/sell notifications and client-side error feedback.
-- Edit them to match your server's language or style.
-- You do NOT need to touch client/stores.lua or client/sell_stores.lua.
-- ─────────────────────────────────────────────────────────────────────────────

CustomStoreMoneyClient = {}

-- ── Pay type display labels ───────────────────────────────────────────────────
-- Used in success notifications: "You bought x2 item for $500 (dirty)"
CustomStoreMoneyClient.PayTypeLabel = {
    es = {
        clean = 'limpio',
        dirty = 'sucio',
    },
    en = {
        clean = 'clean',
        dirty = 'dirty',
    },
}

-- ── Buy error messages ────────────────────────────────────────────────────────
-- Maps a server-side reason string to a player-visible message.
-- Add or edit entries if you extend rejection reasons on the server.
CustomStoreMoneyClient.BuyErrors = {
    insufficient_funds = 'notify.insufficient_funds',
    item_not_found     = 'server.item_not_found',
    clean_not_allowed  = 'notify.error_with_reason',
    dirty_not_allowed  = 'notify.error_with_reason',
    too_fast           = 'notify.error_with_reason',
    transaction_error  = 'notify.error_generic',
}

-- ── Sell error messages ───────────────────────────────────────────────────────
-- Maps a server-side reason string to a player-visible message.
CustomStoreMoneyClient.SellErrors = {
    insufficient_items = 'notify.error_with_reason',
    item_not_found     = 'server.item_not_found',
    clean_not_allowed  = 'notify.error_with_reason',
    dirty_not_allowed  = 'notify.error_with_reason',
    too_fast           = 'notify.error_with_reason',
    limit_reached      = 'notify.error_with_reason',
    transaction_error  = 'notify.error_generic',
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

--- Returns the display label for the given pay type.
---@param payType string  'clean' | 'dirty'
---@return string
function CustomStoreMoneyClient.GetPayTypeLabel(payType)
    local lang = (locale and locale.lang) or Config.Language or 'en'
    local labels = CustomStoreMoneyClient.PayTypeLabel[lang] or CustomStoreMoneyClient.PayTypeLabel.en
    return labels[payType] or payType
end

--- Returns the buy error message for the given server reason.
---@param reason string
---@return string
function CustomStoreMoneyClient.GetBuyError(reason)
    local key = CustomStoreMoneyClient.BuyErrors[reason]
    if not key then
        return locale:t('notify.error_with_reason', reason or 'error')
    end

    if key == 'notify.error_with_reason' then
        return locale:t(key, reason or 'error')
    end

    return locale:t(key)
end

--- Returns the sell error message for the given server reason.
---@param reason string
---@return string
function CustomStoreMoneyClient.GetSellError(reason)
    local key = CustomStoreMoneyClient.SellErrors[reason]
    if not key then
        return locale:t('notify.error_with_reason', reason or 'error')
    end

    if key == 'notify.error_with_reason' then
        return locale:t(key, reason or 'error')
    end

    return locale:t(key)
end
