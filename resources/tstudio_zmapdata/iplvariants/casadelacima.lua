-- #########################################
-- Casa de La Cima - IPL Variants
-- #########################################
-- Resource: tstudio_lacima_estate
--
-- Toggle exterior ymap variants on/off. Set enable = true on the variant you
-- want visible and false on the rest. An IPL name is the ymap filename WITHOUT
-- the .ymap extension. These must be authored/exported as SEPARATE ymaps for the
-- toggle to work (RequestIpl/RemoveIpl operate on ymap IPLs, not on .ydr props).

return {
    resource = "tstudio_lacima_estate",
    variants = {
        {
            name = "Casa de La Cima - Entrance Signage (Flat vs 3D)",
            ipls = {
                { name = "tstudio_vw_estate_ext_signage_flat", enable = false }, -- flat sign (hidden)
                { name = "tstudio_vw_estate_ext_signage_3d",   enable = true  }, -- 3D sign (shown)
            },
        },
    },
}
