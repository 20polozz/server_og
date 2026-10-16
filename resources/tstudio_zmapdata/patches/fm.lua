return {
    creatorName = "FM Maps",
    patches = {
        {
            name = "Fix for Legion Square & FM MRPD",
            requiredMaps = {"tstudio_legionsquare", "cfx-fm-mrpd"},
            fixResource = "tstudio_zpatch_ls_fm_mrpd"
        },
        {
            name = "Fix for Mission Row Park & FM MRPD",
            requiredMaps = {"tstudio_missionrow_park", "cfx-fm-mrpd"},
            fixResource = "tstudio_zpatch_mrpark_fm_mrpd"
        },
        {
            name = "Fix for Mission Row Park, Legion Square & FM MRPD",
            requiredMaps = {"tstudio_missionrow_park", "tstudio_legionsquare", "cfx-fm-mrpd"},
            fixResource = "tstudio_zpatch_mrpark_ls_fm_mrpd"
        },
        {
            name = "Fix for Mission Row Park, Legion Square, Tropical Heights & FM MRPD",
            requiredMaps = {"tstudio_missionrow_park", "tstudio_legionsquare", "tstudio_tropical_heights", "cfx-fm-mrpd"},
            fixResource = "tstudio_zpatch_mrpark_ls_th_fm_mrpd"
        },
        {
            name = "Fix for Mission Row Park, Tropical Heights & FM MRPD",
            requiredMaps = {"tstudio_missionrow_park", "tstudio_tropical_heights", "cfx-fm-mrpd"},
            fixResource = "tstudio_zpatch_mrpark_th_fm_mrpd"
        },
        {
            name = "Fix for Tropical Heights & FM MRPD",
            requiredMaps = {"tstudio_tropical_heights", "cfx-fm-mrpd"},
            fixResource = "tstudio_zpatch_th_fm_mrpd"
        },
        {
            name = "Fix for Mission Row Park, Legion Square, Tropical Heights & Kebab & FM MRPD",
            requiredMaps = {"tstudio_missionrow_park", "tstudio_legionsquare", "tstudio_tropical_heights", "tstudio_kebabking", "cfx-fm-mrpd"},
            fixResource = "tstudio_zpatch_mrpark_ls_th_kebab_fm_mrpd"
        }
    }
}
