--[[
    ============================================================
    RADIO SETTINGS
    ============================================================
    Frequencies available inside the F6 quick menu radio tab.
    Any member with 'quick_radio' permission and a 'radio' item
    can join / switch between these channels.
    ============================================================
--]]

Config.Radio = {
    -- Item required to use gang radio
    ItemName = 'radio',

    -- List of gang sub-frequencies shown in the radio tab.
    -- These map to 'gang_<gangId>' multi-frequency groups
    -- in the origen_ilegal radio system.
    Frequencies = {
        "Frecuencia 1",
        "Frecuencia 2",
        "Frecuencia 3",
        "Frecuencia 4",
        "Frecuencia 5",
        "Frecuencia 6",
        "Frecuencia 7",
        "Frecuencia 8",
        "Frecuencia 9",
        "Frecuencia 10",
    },

    -- Voice + PTT behavior (pma-voice integration)
    Voice = {
        Enabled = true,
        Resource = 'pma-voice',

        -- Push-to-talk and mute keybinds
        TalkKey = 'LMENU',
        MuteToggleKey = 'R',

        -- If true, toggles incoming/outgoing radio audio locally
        EnableMute = true,

        -- Plays handheld radio animation while talking
        -- Label: friendly name shown in the radio menu animation selector.
        -- Prop (optional): prop model to attach while the animation is active.
        -- PropBone: bone index (GetPedBoneIndex) where the prop is attached.
        -- PropPlacement: { offX, offY, offZ, rotX, rotY, rotZ }
        UseAnimation = true,
        DefaultAnim = 1,
        Anims = {
            {
                Dict  = "random@arrests",
                Anim  = "generic_radio_chatter",
                Flag  = 49,
                Label = "Radio Walkie",
            },
            {
                Dict         = "cellphone@str",
                Anim         = "cellphone_call_listen_a",
                Flag         = 49,
                Label        = "Radio (mano)",
                Prop         = "prop_cs_hand_radio",
                PropBone     = 57005,
                PropPlacement = { 0.12, 0.02, -0.02, 20.0, 70.0, 130.0 },
            },
        },

        -- Keep PTT control state pressed while talking (default radio control)
        KeepControlPressed = true,
        PttControl = 249,

        -- Radio talk click sounds (PTT on/off) via NUI audio bridge
        Clicks = true,
    },
}
