-- #########################################
-- Ushero Nightclub - IPL Variants
-- #########################################
-- Resource: tstudio_ushero_nightclub
--
-- Toggle exterior ymap variants on/off. Set enable = true on the variant you
-- want visible and false on the rest. An IPL name is the ymap filename WITHOUT
-- the .ymap extension. These must be authored/exported as SEPARATE ymaps for the
-- toggle to work (RequestIpl/RemoveIpl operate on ymap IPLs, not on .ydr props).

return {
    resource = "tstudio_ushero_nightclub",
    variants = {
        {
            name = "Ushero Nightclub - Entrance Signage (Ushero vs Unicorn)",
            ipls = {
                { name = "tstudio_jhn_ushero_loc01_ext_ushero_sign", enable = true }, -- Ushero Sign
                { name = "tstudio_jhn_ushero_loc01_ext_unicorn_sign",   enable = false  }, -- Unicorn Sign
            },
        },
        {
            name = "Ushero Nightclub - Entrance Pillars",
            ipls = {
                { name = "tstudio_jhn_ushero_loc01_ext_pillars", enable = true },-- Ushero Pillars
            },
        },
    },
}
