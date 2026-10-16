Config = {
    -- You can change the language of the menu here. Available languages can be found in the locales folder.
    Language = 'es',
    -- You can disable the emote position selector on emotes with the Placement flag here.
    EnableEmotePlacement = true,
    -- You can disable the emote binds option here.
    EnableEmoteBinds = true,
    -- Block players from using weapons while doing an emote.
    EnableWeaponBlock = false,
    -- Block players from aiming and shooting while doing an emote.
    EnableAimShootBlock = true,
    -- Set this to '' to disable the key.
    CancelEmoteKey = 'x', -- List of keys here: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    -- Set this to '' to disable the key.
    HandsUpKey = 'x', -- List of keys here: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    -- Set this to '' to disable the key.
    CrossArmsKey = 'g', -- List of keys here: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    -- Set this to '' to disable the key.
    StanceKey = 'LCONTROL', -- List of keys here: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    -- Set this to '' to disable the key.
    PointKey = 'b', -- List of keys here: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    -- Set this if you really wanna disable emotes in vehicles, if enabled they only play the upper body part of the emote.
    AllowedInVehicles = true,
    -- Cooldown in milliseconds between doing emotes.
    EmoteCooldown = 500,
    -- Commands to play an emote.
    EmotePlayCommands = {'e', 'emote', 'a'},
    -- Commands to set a walk style.
    WalkSetCommands = {'w', 'walk'},
    -- Commands to open the menu.
    MenuOpenCommands = {'em', 'emotemenu'},
    -- Set this to '' to disable the key.
    MenuKeybind = 'F3', -- List of keys here: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    -- You can change the menu position here.
    MenuPosition = 'top-right', -- (top-left, top-right, bottom-left, bottom-right)
    -- You can change the notification position here
    NotificationPosition = 'top', -- (top, bottom, top-left, top-right, bottom-left, bottom-right)
    -- You can change the help alert position here
    HelpAlertPosition = 'right-center', -- (right-center, left-center, top-center)
    -- Set this to '' to disable the key.
    RagdollKeybind = 'z', -- List of keys here: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    -- Set this to '' to disable the key.
    PtfxKeybind = 'g', -- List of keys here: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    -- You can enable automated ptfx on emotes with the Auto flag here. 
    EnableAutoPtfx = false,
    -- You can enable the NSFW emotes here. Can be true, false or 'limited'
    EnableNSFWEmotes = 'limited',
    -- You can enable the gang emotes here.
    EnableGangEmotes = false,
    -- You can enable the social movement emotes here.
    EnableSocialMovementEmotes = false,
    -- You can enable the consumable emotes here.
    EnableConsumableEmotes = false,
    -- You can enable the synchronized emotes here.
    EnableSynchronizedEmotes = true,
    -- You can enable the animal emotes here.
    EnableAnimalEmotes = true,
    -- You can enable radial menu usage here.
    EnableRadialMenu = false,

    disableControls = {1, 142, 2, 24, 257, 25, 106, 287, 286, 18, 45, 80, 140, 263, 22, 26, 199, 24, 25, 36}
}
