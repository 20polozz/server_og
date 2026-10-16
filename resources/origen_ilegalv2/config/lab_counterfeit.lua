--[[
    ============================================================
    COUNTERFEIT LAB — MONEY LAUNDERING CONFIGURATION
    ============================================================
    Controls the money laundering system available in the
    'counterfeit' type laboratory, accessible via the lab laptop.

    FLOW:
      1. Player opens laptop inside a counterfeit lab.
      2. Opens the "Launder" app.
      3. Enters an amount (between MinAmount and MaxAmount).
      4. Previews: estimated time + loss + final clean output.
      5. Clicks "Start laundering" → dirty money is charged immediately.
      6. Process runs server-side, persisted in DB.
      7. When ready, any player with lab access clicks
         "Collect cash" to receive clean cash.

    UPGRADE RULES:
      Defined in PrinterRules, keyed by the active variant of
      the 'printer' module (from Config.LabUpgrades.counterfeit).
      If no active variant matches, defaults to 'printer_none'.

    FORMULAS (calculated server-side):
      time_ms  = (BaseTimeMs + input_amount * TimePerDollarMs) * upgrade.time_mult
      loss_pct = math.max(0, math.min(100, BaseLossPct + upgrade.loss_delta_pct))
      output   = math.floor(input_amount * (1 - loss_pct / 100))
    ============================================================
--]]

Config.LabCounterfeit = {

    -- ── Feature flags ──────────────────────────────────────────────────────────
    Enabled  = true,
    LabType  = 'counterfeit',   -- only applies to labs of this type

    -- ── Amount limits ─────────────────────────────────────────────────────────
    MinAmount = 5000,           -- minimum dirty money per operation
    MaxAmount = 500000,         -- maximum dirty money per operation

    -- ── Base time formula ───────────────────────────────────────────────────────
    -- time_ms = (BaseTimeMs + input * TimePerDollarMs) * upgrade.time_mult
    -- Example with defaults and no upgrades:
    --   $10,000  → (60s + 10000 * 0.006s) = 60 + 60  = 120s = 2 min
    --   $100,000 → (60s + 100000 * 0.006s) = 60 + 600 = 660s = 11 min
    --   $500,000 → (60s + 500000 * 0.006s) = 60 + 3000 = 3060s ≈ 51 min
    BaseTimeMs      = 300000,    -- 300 seconds fixed base per operation
    TimePerDollarMs = 6,        -- 6 ms per $1 dirty (6 = 6s per $1000)

    -- ── Base loss ───────────────────────────────────────────────────────────────
    -- output_clean = floor(input * (1 - loss_pct / 100))
    BaseLossPct = 25.0,         -- 25% loss by default (no upgrades)

    -- ── Concurrency ─────────────────────────────────────────────────────────────
    -- MaxConcurrentPerLab es LEGACY — ya no se usa.
    -- El límite por lab es dinámico: 1 slot por lavadora comprada (dryer_1..dryer_4).
    -- Si el lab no tiene lavadoras compradas, el lavado queda bloqueado (0 slots).
    -- MaxConcurrentPerLab    = 5,  -- LEGACY: eliminado en favor de capacidad dinámica
    MaxConcurrentPerPlayer = 4, -- max active processes per player at once

    -- ── Rules per printer upgrade ───────────────────────────────────────────────
    -- Keyed by the active variant_key of the lab's 'printer' module.
    -- can_launder:     if false, the player CANNOT start laundering.
    -- time_mult:       multiplier on computed time (< 1.0 = faster).
    -- loss_delta_pct:  added to BaseLossPct (negative = less loss).
    PrinterRules = {
        printer_none = {
            can_launder    = false,  -- no printer → cannot launder
            time_mult      = 1.0,
            loss_delta_pct = 0.0,
        },
        printer_basic = {
            can_launder    = true,
            time_mult      = 1.0,    -- base time with no upgrade
            loss_delta_pct = 0.0,    -- base loss (25%)
        },
        printer_upgrade = {
            can_launder    = true,
            time_mult      = 0.70,   -- 30% faster
            loss_delta_pct = -8.0,   -- loss reduced to 17%
        },
    },

    -- ── Fallback when no upgrade is active or key is missing ────────────────────
    PrinterRuleFallback = {
        can_launder    = false,
        time_mult      = 1.0,
        loss_delta_pct = 0.0,
    },
}
