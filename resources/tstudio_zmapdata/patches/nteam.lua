return {
    creatorName = "NTeam Maps",
    patches = {
        {
            name = "Fix for Mission Row Park & MRPD & NTeam Legion V2",
            requiredMaps = {"tstudio_missionrow_park", "tstudio_mrpd", "cfx-nteam-legion2"},
            fixResource = "tstudio_zpatch_mrpark_mrpd_nteam_legion2"
        },
        {
            name = "Fix for Mission Row Park & NTeam Legion V2",
            requiredMaps = {"tstudio_missionrow_park", "cfx-nteam-legion2"},
            fixResource = "tstudio_zpatch_mrpark_nteam_legion2"
        },
        {
            name = "Fix for MRPD & NTeam Legion V2",
            requiredMaps = {"tstudio_mrpd", "cfx-nteam-legion2"},
            fixResource = "tstudio_zpatch_mrpd_nteam_legion2"
        },
        {
            name = "Fix for Mission Row Park & MRPD & Tropical Heights & NTeam Legion V2",
            requiredMaps = {"tstudio_missionrow_park", "tstudio_mrpd", "tstudio_tropical_heights", "cfx-nteam-legion2"},
            fixResource = "tstudio_zpatch_mrpark_mrpd_th_nteam_legion2"
        },
        {
            name = "Fix for Mission Row Park & Tropical Heights & NTeam Legion V2",
            requiredMaps = {"tstudio_missionrow_park", "tstudio_tropical_heights", "cfx-nteam-legion2"},
            fixResource = "tstudio_zpatch_mrpark_th_nteam_legion2"
        },
        {
            name = "Fix for MRPD & Tropical Heights & NTeam Legion V2",
            requiredMaps = {"tstudio_mrpd", "tstudio_tropical_heights", "cfx-nteam-legion2"},
            fixResource = "tstudio_zpatch_mrpd_th_nteam_legion2"
        },
        {
            name = 'Fix for Peak Towers & Mission Row Park & Legion & Kebab & Tropical & NTeam MRPD (NPCs Disabled only)',
            requiredMaps = { 'tstudio_kebabking', 'tstudio_legionsquare', 'tstudio_missionrow_park', 'tstudio_peak_towers', 'tstudio_tropical_heights', 'cfx-nteam-mrpd' },
            fixResource = 'tstudio_zpatch_peak_mrpark_ls_kebab_th_nteam_mrpd',
        },
        {
            name = 'Fix for Mission Row Park & Legion Square & NTeam MRPD (NPCs Disabled only)',
            requiredMaps = { 'tstudio_legionsquare', 'tstudio_missionrow_park', 'cfx-nteam-mrpd' },
            fixResource = 'tstudio_zpatch_mrpark_ls_nteam_mrpd',
        },
        {
            name = 'Fix for Peak Towers & Legion Square & Mission Row Park & NTeam Lake',
            requiredMaps = { 'tstudio_legionsquare', 'tstudio_missionrow_park', 'tstudio_peak_towers', 'cfx-nteam-newlake' },
            fixResource = 'tstudio_zpatch_peak_mrpark_ls_nteam_lake',
        },
        {
            name = 'Fix for Impound & Car Rent & NTeam Lake',
            requiredMaps = { 'tstudio_carrent', 'tstudio_impound', 'cfx-nteam-newlake' },
            fixResource = 'tstudio_zpatch_impound_carrent_nteam_lake',
        },
    }
}