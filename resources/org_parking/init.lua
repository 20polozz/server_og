-- ═══════════════════════════════════════════════════════════════════════════
--  ORG Parking — Shared Init
--  Loads the selected locale and exposes T() + dbg() globally.
-- ═══════════════════════════════════════════════════════════════════════════

local _lang = {}

-- Load the locale file selected in Config.Locale
local function _loadLocale(code)
    local path    = ('locales/%s.lua'):format(code or 'en')
    local content = LoadResourceFile(cache.resource, path)
    if not content then
        if code ~= 'en' then
            -- Fallback to English
            print(string.format('^3[org_parking] Locale "%s" not found — falling back to "en"^7', code))
            return _loadLocale('en')
        end
        print('^1[org_parking] ERROR: Locale file not found: ' .. path .. '^7')
        return {}
    end
    local fn, err = load(content, '@' .. path)
    if not fn then
        print('^1[org_parking] ERROR loading locale: ' .. tostring(err) .. '^7')
        return {}
    end
    local ok, result = pcall(fn)
    if not ok or type(result) ~= 'table' then
        print('^1[org_parking] ERROR evaluating locale: ' .. tostring(result) .. '^7')
        return {}
    end
    return result
end

_lang = _loadLocale(Config.Locale)

-- ── T(key, ...) ────────────────────────────────────────────────────────────
-- Translates a key to the current locale string.
-- If the key is missing, returns the key itself (fail-safe).
-- Supports string.format placeholders: T('key', arg1, arg2, ...)
function T(key, ...)
    local str = _lang[key]
    if not str then
        if Config.Debug then
            print(string.format('^3[org_parking] Missing locale key: %s^7', key))
        end
        return key
    end
    if select('#', ...) > 0 then
        local ok, result = pcall(string.format, str, ...)
        return ok and result or str
    end
    return str
end

-- ── dbg(...) ───────────────────────────────────────────────────────────────
-- Debug print — only outputs when Config.Debug = true
function dbg(...)
    if Config.Debug then
        print('^5[org_parking DBG]^7', ...)
    end
end
