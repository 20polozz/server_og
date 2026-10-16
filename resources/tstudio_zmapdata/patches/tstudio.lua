return {
    creatorName = "TStudio Maps",
    patches = {
        ---@patches TStudio Opium Nights Hotel
        {
            name = "Fix for Opium Nights & LSI Square",
            requiredMaps = { "tstudio_opium_nights", "tstudio_lsi_square" },
            fixResource = "tstudio_zpatch_opium_lsis"
        },
        {
            name = "Fix for Opium Nights & Bennys Racetrack",
            requiredMaps = { "tstudio_opium_nights", "tstudio_bennys_racetrack" },
            fixResource = "tstudio_zpatch_opium_racetrack"
        },
        {
            name = "Fix for Opium Nights, Bennys Racetrack & LSI Square",
            requiredMaps = { "tstudio_opium_nights", "tstudio_lsi_square", "tstudio_bennys_racetrack" },
            fixResource = "tstudio_zpatch_opium_racetrack_lsis"
        },

        ---@patches TStudio Mission Row Park
        {
            name = "Fix for Missionrowpark, Kebabking, Tropical Heights & Legion",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_legionsquare", "tstudio_tropical_heights", "tstudio_kebabking" },
            fixResource = "tstudio_zpatch_mrpark_kebab_th_ls"
        },
        {
            name = "Fix for Missionrowpark, Kebabking & Tropical Heights",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_kebabking", "tstudio_tropical_heights" },
            fixResource = "tstudio_zpatch_mrpark_kebab_th"
        },
        {
            name = "Fix for Missionrowpark & Tropical Heights",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_tropical_heights" },
            fixResource = "tstudio_zpatch_mrpark_th"
        },
        {
            name = "Fix for Missionrowpark, Legion & Tropical Heights",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_tropical_heights", "tstudio_legionsquare" },
            fixResource = "tstudio_zpatch_mrpark_th_ls"
        },
        {
            name = "Fix for Missionrowpark, Kebabking & Legion",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_kebabking", "tstudio_legionsquare" },
            fixResource = "tstudio_zpatch_mrpark_kebab_ls"
        },
        {
            name = "Fix for Missionrowpark & Legion",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_legionsquare" },
            fixResource = "tstudio_zpatch_mrpark_ls"
        },
        {
            name = "Fix for Missionrowpark & Reds Tuner",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_redstuner" },
            fixResource = "tstudio_zpatch_mrpark_reds"
        },
        {
            name = "Fix for Missionrowpark, Kebabking",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_kebabking" },
            fixResource = "tstudio_zpatch_mrpark_kebab"
        },
        {
            name = "Fix for Impound & Carrent",
            requiredMaps = { "tstudio_impound", "tstudio_carrent" },
            fixResource = "tstudio_zpatch_impound_carrent"
        },
        {
            name = "Fix for Missionrowpark & Impound",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_impound" },
            fixResource = "tstudio_zpatch_mrpark_impound"
        },
        {
            name = "Fix for Missionrowpark, Legionsquare, Tropical Heights & Mission Row PD ",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_legionsquare", "tstudio_tropical_heights", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_mrpark_th_ls_mrpd"
        },
        {
            name = "Fix for Missionrowpark, Legionsquare, Tropical Heights, Kebab King & Mission Row PD ",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_legionsquare", "tstudio_tropical_heights", "tstudio_kebabking", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_mrpark_th_kebab_ls_mrpd"
        },
        {
            name = "Fix for Legion Garage & Kebab",
            requiredMaps = { "tstudio_legionsquare_garage", "tstudio_kebabking" },
            fixResource = "tstudio_zpatch_garage_kebab"
        },
        {
            name = "Fix for Pillbox, Legion Garage & Kebab",
            requiredMaps = { "tstudio_pillbox_md", "tstudio_legionsquare_garage", "tstudio_kebabking" },
            fixResource = "tstudio_zpatch_pillbox_garage_kebab"
        },
        {
            name = "Fix for Pillbox & Legion Garage",
            requiredMaps = { "tstudio_pillbox_md", "tstudio_legionsquare_garage" },
            fixResource = "tstudio_zpatch_pillbox_garage"
        },
        {
            name = "Fix for Pillbox & Kebab",
            requiredMaps = { "tstudio_pillbox_md", "tstudio_kebabking" },
            fixResource = "tstudio_zpatch_pillbox_kebab"
        },
        {
            name = "Fix for Pillbox & Kebab",
            requiredMaps = { "tstudio_pillbox_md", "tstudio_kebabking" },
            fixResource = "tstudio_zpatch_pillbox_kebab"
        },
        {
            name = "Fix for Mission Row Park & Jurassic Jackpot",
            requiredMaps = { "tstudio_jurassic_jackpot", "tstudio_missionrow_park" },
            fixResource = "tstudio_zpatch_mrpark_jj",
        },

        ---@patches TStudio VHotel
        {
            name = 'Fix for Aldente\'s & VHotel',
            requiredMaps = { 'tstudio_aldentes', 'tstudio_vhotel_estate' },
            fixResource = 'tstudio_zpatch_aldentes_vhotel',
        },
        {
            name = 'Fix for VHotel Estate & VHotel Exterior',
            requiredMaps = { 'tstudio_ext_vhotel_roof', 'tstudio_vhotel_estate' },
            fixResource = 'tstudio_zpatch_vhotel_vhotel_ext',
        },

        ---@patches TStudio Paleto Benny's
        {
            name = "Fix for Paleto Bewo & Paleto Cardealer",
            requiredMaps = { "tstudio_paleto_bewo", "tstudio_paleto_cardealer" },
            fixResource = "tstudio_zpatch_bw_cardealer",
        },
        {
            name = "Fix for Paleto Bewo & Paleto Cardealer & Taxi",
            requiredMaps = { "tstudio_paleto_bewo", "tstudio_paleto_cardealer", "tstudio_taxi" },
            fixResource = "tstudio_zpatch_bw_cardealer_taxi",
        },
        {
            name = "Fix for Paleto Bewo & Taxi",
            requiredMaps = { "tstudio_paleto_bewo", "tstudio_taxi" },
            fixResource = "tstudio_zpatch_bw_taxi",
        },
        {
            name = "Fix for Paleto Bewo & Laundromat",
            requiredMaps = { "tstudio_paleto_bewo", "tstudio_laundromat" },
            fixResource = "tstudio_zpatch_bw_laundromat",
        },

        ---@patches TStudio Paleto Cardealer
        {
            name = "Fix for Paleto Cardealer & Laundromat",
            requiredMaps = { "tstudio_paleto_cardealer", "tstudio_laundromat" },
            fixResource = "tstudio_zpatch_cardealer_laundromat",
        },
        {
            name = "Fix for Paleto Cardealer & Paleto Bewo & Laundromat",
            requiredMaps = { "tstudio_paleto_cardealer", "tstudio_paleto_bewo", "tstudio_laundromat" },
            fixResource = "tstudio_zpatch_bw_cardealer_laundromat",
        },

        {
            name = "Fix for Ammunation & Gabz PDM",
            requiredMaps = { "tstudio_ammunation", "cfx-gabz-pdm" },
            fixResource = "tstudio_zpatch_ammunation_gabz_pdm",
        },

        {
            name = "Fix for Legion Square & MRPD",
            requiredMaps = { "tstudio_legionsquare", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_ls_mrpd",
        },
        {
            name = "Fix for Legion Square, Tropical Heights & MRPD",
            requiredMaps = { "tstudio_legionsquare", "tstudio_tropical_heights", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_ls_th_mrpd",
        },
        {
            name = "Fix for Mission Row Park & MRPD",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_mrpark_mrpd",
        },
        {
            name = "Fix for Mission Row Park, Kebab, Legion Square & MRPD",
            requiredMaps = { "tstudio_legionsquare", "tstudio_kebabking", "tstudio_missionrow_park", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_mrpark_kebab_ls_mrpd",
        },
        {
            name = "Fix for Mission Row Park, Kebab, Tropical Heights & MRPD",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_kebabking", "tstudio_tropical_heights", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_mrpark_kebab_th_mrpd",
        },
        {
            name = "Fix for Mission Row Park, Legion Square & MRPD",
            requiredMaps = { "tstudio_legionsquare", "tstudio_missionrow_park", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_mrpark_ls_mrpd",
        },
        {
            name = "Fix for Mission Row Park, Tropical Heights, Kebab, Legion Square & MRPD",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_tropical_heights", "tstudio_kebabking", "tstudio_legionsquare", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_mrpark_th_kebab_ls_mrpd",
        },
        {
            name = "Fix for Mission Row Park, Tropical Height, Legion Square & MRPD",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_tropical_heights", "tstudio_legionsquare", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_mrpark_th_ls_mrpd",
        },
        {
            name = "Fix for Mission Row Park, Tropical Height & MRPD",
            requiredMaps = { "tstudio_missionrow_park", "tstudio_tropical_heights", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_mrpark_th_mrpd",
        },
        {
            name = "Fix for Tropical Height & MRPD",
            requiredMaps = { "tstudio_tropical_heights", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_th_mrpd",
        },

        ---@patches TStudio Peak Towers
        {
            name = "Fix for Peak Tower & Jurassic Jackpot",
            requiredMaps = { "tstudio_peak_towers", "tstudio_jurassic_jackpot" },
            fixResource = "tstudio_zpatch_peak_jj",
        },
        {
            name = "Fix for Peak Tower & Kebab King",
            requiredMaps = { "tstudio_peak_towers", "tstudio_kebabking" },
            fixResource = "tstudio_zpatch_peak_kebab",
        },
        {
            name = "Fix for Peak Tower & Legionsquare",
            requiredMaps = { "tstudio_peak_towers", "tstudio_legionsquare" },
            fixResource = "tstudio_zpatch_peak_ls",
        },
        {
            name = "Fix for Peak Tower & Legion Square Garage",
            requiredMaps = { "tstudio_peak_towers", "tstudio_legionsquare_garage" },
            fixResource = "tstudio_zpatch_peak_lsgarage",
        },
        {
            name = "Fix for Peak Tower & Missionrowpark",
            requiredMaps = { "tstudio_peak_towers", "tstudio_missionrow_park" },
            fixResource = "tstudio_zpatch_peak_mrpark",
        },
        {
            name = "Fix for Peak Tower & MRPD",
            requiredMaps = { "tstudio_peak_towers", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_peak_mrpd",
        },
        {
            name = "Fix for Peak Tower & Tropical Heights",
            requiredMaps = { "tstudio_peak_towers", "tstudio_tropical_heights" },
            fixResource = "tstudio_zpatch_peak_th",
        },
        {
            name = "Fix for Peak Tower & Missionrowpark",
            requiredMaps = { "tstudio_peak_towers", "tstudio_missionrow_park" },
            fixResource = "tstudio_zpatch_peak_mrpark",
        },
        {
            name = "Fix for Peak Tower, Kebab & Legionsquare",
            requiredMaps = { "tstudio_peak_towers", "tstudio_kebabking", "tstudio_legionsquare" },
            fixResource = "tstudio_zpatch_peak_kebab_ls",
        },
        {
            name = "Fix for Peak Tower, Kebab & Missionrowpark",
            requiredMaps = { "tstudio_peak_towers", "tstudio_kebabking", "tstudio_missionrow_park" },
            fixResource = "tstudio_zpatch_peak_kebab_mrpark",
        },
        {
            name = "Fix for Peak Tower, Legionsquare & Missionrowpark",
            requiredMaps = { "tstudio_peak_towers", "tstudio_legionsquare", "tstudio_missionrow_park" },
            fixResource = "tstudio_zpatch_peak_ls_mrpark",
        },
        {
            name = "Fix for Peak Tower, Legionsquare & MRPD",
            requiredMaps = { "tstudio_peak_towers", "tstudio_legionsquare", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_peak_ls_mrpd",
        },
        {
            name = "Fix for Peak Tower, Legionsquare & Tropical Heights",
            requiredMaps = { "tstudio_peak_towers", "tstudio_legionsquare", "tstudio_tropical_heights" },
            fixResource = "tstudio_zpatch_peak_ls_th",
        },
        {
            name = "Fix for Peak Tower, Missionrowpark & MRPD",
            requiredMaps = { "tstudio_peak_towers", "tstudio_missionrow_park", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_peak_mrpark_mrpd",
        },
        {
            name = "Fix for Peak Tower, Missionrowpark & Tropical Heights",
            requiredMaps = { "tstudio_peak_towers", "tstudio_missionrow_park", "tstudio_tropical_heights" },
            fixResource = "tstudio_zpatch_peak_mrpark_th",
        },
        {
            name = "Fix for Peak Tower, MRPD & Tropical Heights",
            requiredMaps = { "tstudio_peak_towers", "tstudio_mrpd", "tstudio_tropical_heights" },
            fixResource = "tstudio_zpatch_peak_mrpd_th",
        },
        {
            name = "Fix for Peak Tower, Kebab, Legionsquare & Missionrowpark",
            requiredMaps = { "tstudio_peak_towers", "tstudio_kebabking", "tstudio_legionsquare", "tstudio_missionrow_park" },
            fixResource = "tstudio_zpatch_peak_kebab_ls_mrpark",
        },
        {
            name = "Fix for Peak Tower, Legionsquare, Missionrowpark & MRPD",
            requiredMaps = { "tstudio_peak_towers", "tstudio_legionsquare", "tstudio_missionrow_park", "tstudio_mrpd" },
            fixResource = "tstudio_zpatch_peak_ls_mrpark_mrpd",
        },
        {
            name = "Fix for Peak Tower, Legionsquare, Missionrowpark & Tropical Heights",
            requiredMaps = { "tstudio_peak_towers", "tstudio_legionsquare", "tstudio_missionrow_park", "tstudio_tropical_heights" },
            fixResource = "tstudio_zpatch_peak_ls_mrpark_th",
        },
        {
            name = "Fix for Peak Tower, Legionsquare, MRPD & Tropical Heights",
            requiredMaps = { "tstudio_peak_towers", "tstudio_legionsquare", "tstudio_mrpd", "tstudio_tropical_heights" },
            fixResource = "tstudio_zpatch_peak_ls_mrpd_th",
        },
        {
            name = "Fix for Peak Tower, Missionrowpark, MRPD & Tropical Heights",
            requiredMaps = { "tstudio_peak_towers", "tstudio_missionrow_park", "tstudio_mrpd", "tstudio_tropical_heights" },
            fixResource = "tstudio_zpatch_peak_mrpark_mrpd_th",
        },
        {
            name = "Fix for Peak Tower & Legion Square & Mission Row Park & MRPD & Tropical Heights",
            requiredMaps = { "tstudio_peak_towers", "tstudio_legionsquare", "tstudio_missionrow_park", "tstudio_mrpd", "tstudio_tropical_heights" },
            fixResource = "tstudio_zpatch_peak_ls_mrpark_mrpd_th",
        },
        {
            name = "Fix for Peak Tower & Legion Square & Mission Row Park & MRPD & Tropical Heights & Kebab King",
            requiredMaps = { "tstudio_peak_towers", "tstudio_legionsquare", "tstudio_missionrow_park", "tstudio_mrpd", "tstudio_tropical_heights", "tstudio_kebabking" },
            fixResource = "tstudio_zpatch_peak_ls_mrpark_mrpd_th_kebab",
        },

        ---@patches [ADD-ON] TStudio Peak Towers (Fleeca, Ammunation & Other Locations)
        {
            name = "Addon for Peak Tower & TStudio Fleeca",
            requiredMaps = { "tstudio_peak_towers", "tstudio_fleeca" },
            fixResource = "tstudio_zpatch_peak_addon_fleeca",
        },
        {
            name = "Addon for Peak Tower & TStudio Ammunation",
            requiredMaps = { "tstudio_peak_towers", "tstudio_ammunation" },
            fixResource = "tstudio_zpatch_peak_addon_ammunation",
        },
        {
            name = "Addon for Peak Tower & TStudio Tattoo Parlor",
            requiredMaps = { "tstudio_peak_towers", "tstudio_tattoo_studio" },
            fixResource = "tstudio_zpatch_peak_addon_tattoo",
        },
        {
            name = "Addon for Peak Tower & TStudio Ponsonbys",
            requiredMaps = { "tstudio_peak_towers", "tstudio_ponsonby" },
            fixResource = "tstudio_zpatch_peak_addon_ponsonbys",
        },

        ---@patches TStudio Marlowecrest Estate
        {
            name = 'Fix for Marlowecrest Estate & Japanese Mansion',
            requiredMaps = { 'tstudio_marlowecrest_estate', 'tstudio_ext_japanese_mansion'},
            fixResource = 'tstudio_zpatch_marlowecrest_japanese',
        },
        {
            name = 'Fix for Marlowecrest Estate & Cali Estate',
            requiredMaps = { 'tstudio_marlowecrest_estate', 'tstudio_ext_cali_estate' },
            fixResource = 'tstudio_zpatch_marlowecrest_cali',
        },

        ---@patches TStudio La Cima Estate
        {
            name = 'Fix for Marlowecrest Estate & La Cima Estate',
            requiredMaps = { 'tstudio_marlowecrest_estate', 'tstudio_lacima_estate' },
            fixResource = 'tstudio_zpatch_marlowecrest_lacima',
        },
        {
            name = 'Fix for Marlowecrest Estate & La Cima Estate & Japanese Mansion',
            requiredMaps = { 'tstudio_ext_japanese_mansion', 'tstudio_marlowecrest_estate', 'tstudio_lacima_estate' },
            fixResource = 'tstudio_zpatch_marlowecrest_lacima_japanese',
        },

        ---@patches TStudio Ushero Nightclub
        {
            name = 'Fix for Ushero Nightclub & Carrent',
            requiredMaps = { 'tstudio_ushero_nightclub', 'tstudio_carrent' },
            fixResource = 'tstudio_zpatch_ushero_carrent',
        },
        {
            name = 'Fix for Ushero Nightclub & Impound',
            requiredMaps = { 'tstudio_ushero_nightclub', 'tstudio_impound' },
            fixResource = 'tstudio_zpatch_ushero_impound',
        },
        {
            name = 'Fix for Ushero Nightclub, Carrent & Impound',
            requiredMaps = { 'tstudio_ushero_nightclub', 'tstudio_carrent', 'tstudio_impound' },
            fixResource = 'tstudio_zpatch_ushero_impound_carrent',
        },
        {
            name = 'Fix for Ushero Nightclub & Mission Row Park',
            requiredMaps = { 'tstudio_ushero_nightclub', 'tstudio_missionrow_park' },
            fixResource = 'tstudio_zpatch_ushero_mrpark',
        },
        {
            name = 'Fix for Ushero Nightclub & Reds Tuner ',
            requiredMaps = { 'tstudio_ushero_nightclub', 'tstudio_redstuner' },
            fixResource = 'tstudio_zpatch_ushero_reds',
        },
        {
            name = 'Fix for Ushero Nightclub & Reds Tuner & Mission Row Park',
            requiredMaps = { 'tstudio_ushero_nightclub', 'tstudio_redstuner', 'tstudio_missionrow_park' },
            fixResource = 'tstudio_zpatch_ushero_reds_mrpark',
        },

        ---@patches TStudio Cayo Tunnel & Cayo Lagoon
        {
            name = 'Fix for Cayo Tunnel & Cayo Lagoon',
            requiredMaps = { 'tstudio_cayo_tunnel', 'tstudio_cayo_lagoon' },
            fixResource = 'tstudio_zpatch_cayo_tunnel_lagoon',
        },

        ---@note TStudio Ext Mirrorpark Hood & Leapfrog
        {
            name = 'Fix for Ext Mirrorpark Hood & Leapfrog',
            requiredMaps = { 'tstudio_ext_mirrorpark_hood', 'tstudio_leapfrog' },
            fixResource = 'tstudio_zpatch_mirrorpark_leapfrog',
        },

        ---@note TStudio Fleeca & Binco Harmony
        {
            name = 'Fix for Fleeca & Binco Harmony',
            requiredMaps = { 'tstudio_fleeca', 'tstudio_binco' },
            fixResource = 'tstudio_zpatch_binco_fleeca_harmony',
        },

        ---@note TStudio Suburban & Tattoo Studio
        {
            name = 'Fix for Suburban & Tattoo Studio',
            requiredMaps = { 'tstudio_suburban', 'tstudio_tattoo_studio' },
            fixResource = 'tstudio_zpatch_suburban_tattoo_studio',
        },
    }
}