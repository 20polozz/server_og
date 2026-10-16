--[[
    ============================================================
    LAB SHOP — Laptop upgrade store for the laboratory
    ============================================================
    Defines what can be bought from the lab laptop "Shop" tab.
    Designed to grow over time: today only storage; later you can add
    more categories (security, production, etc.).

    GENERAL STRUCTURE:
      Config.LabShop.modules = {
          [category_key] = {
              label   → visible category name
              icon    → lucide icon (no prefix)
              items   = {
                  {
                      item_key    → unique key (globally unique)
                      label       → visible name
                      description → short description (optional)
                      price       → price in $ (0 = free)
                      icon        → lucide icon for the item
                      -- Category-specific options:
                      slots       → (storage) stash slots
                      weight      → (storage) max stash weight in grams
                       -- Restriction by lab type:
                       allowed_labs → array of lab types where this is available.
                                      If omitted or nil, available in ALL labs.
                                      Example: { 'weed', 'meth' }
                  },
              }
          }
      }

    NOTES:
    - Payment uses the same lab rule (upgrade_payment_mode).
    - If the player cancels stash placement, the purchase is not charged
      (charging happens AFTER position is confirmed).
    - Multiple stashes can be bought per lab (no limit by default,
      but you can add max_per_lab if you want).
    ============================================================
--]]

Config.LabShop = {

    -- ── Stash marker inside the lab interior ────────────────────────────────────
    StashMarker = {
        type          = 22,
        offset        = { x = 0.0, y = 0.0, z = 1.0 },
        scale         = { x = 0.25, y = 0.25, z = 0.25 },
        color         = { r = 0, g = 0, b = 0, a = 170 },
        bobUpAndDown  = true,
        faceCamera    = true,
        rotationOrder = 2,
        rotate        = false,
    },

    -- ── Interaction distances for stashes ─────────────────────────────────────
    StashInteractions = {
        PointDistance    = 30.0,   -- lib.points radius
        DrawDistance     = 10.0,   -- distance to draw the marker
        InteractDistance = 1.8,    -- distance for helptext + [E]
    },

    -- ── Shop modules ───────────────────────────────────────────────────────────
    modules = {

        -- ─── STORAGE ───────────────────────────────────────────────────────────
        storage = {
            label = 'Storage',
            icon  = 'archive',

            items = {
                {
                    item_key    = 'storage_small',
                    label       = 'Small stash',
                    description = 'Basic stash for the lab. 20 slots.',
                    price       = 25000,
                    icon        = 'package',
                    slots       = 20,
                    weight      = 100000,   -- 100 kg in grams
                    -- allowed_labs = nil,  -- available in all labs
                },
                {
                    item_key    = 'storage_medium',
                    label       = 'Medium stash',
                    description = 'Higher capacity for busier labs. 40 slots.',
                    price       = 60000,
                    icon        = 'package-2',
                    slots       = 40,
                    weight      = 250000,   -- 250 kg
                    -- allowed_labs = nil,
                },
                {
                    item_key    = 'storage_large',
                    label       = 'Large stash',
                    description = 'High-capacity stash. 80 slots.',
                    price       = 140000,
                    icon        = 'boxes',
                    slots       = 80,
                    weight      = 500000,   -- 500 kg
                    -- allowed_labs = { 'weed', 'coke' },  -- example: weed and coke labs only
                },
            },
        },
    },
}
