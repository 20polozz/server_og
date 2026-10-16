Config.Locale = 'es' -- Default language (en, es)
Config.Debug = false -- Enable debug mode (set to false in production)

-- Speaker Settings
Config.InteractionDistance = 2.0 -- Distance to interact with the speaker
Config.MaxSpeakers = 100 -- Maximum speakers per player

-- Speaker Types Configuration
Config.SpeakerTypes = {
    ['speaker_small'] = {
        label = 'Altavoz Pequeño',
        prop = 'prop_radio_01',
        range = 10.0,
        maxVolume = 25,
        item = 'speaker_small'
    },
    ['speaker_medium'] = {
        label = 'Altavoz Mediano 1',
        prop = 'prop_speaker_03',
        range = 35.0,
        maxVolume = 50,
        item = 'speaker_medium'
    },
    ['speaker_medium_1'] = {
        label = 'Altavoz Mediano 2',
        prop = 'prop_speaker_07',
        range = 50.0,
        maxVolume = 75,
        item = 'speaker_medium_1'
    },
    ['speaker_big'] = {
        label = 'Altavoz Grande',
        prop = 'sf_prop_sf_speaker_l_01a',
        range = 75.0,
        maxVolume = 100,
        item = 'speaker_big'
    }
}

-- Volume Settings
Config.DefaultVolume = 50 -- Default volume (0 - 100)
Config.MinVolume = 0 -- Minimum volume (0 = muted)
Config.MaxVolume = 100

-- Playlist Settings
Config.MaxPlaylistSongs = 50 -- Maximum songs in a playlist
Config.MaxPlaylists = 10 -- Maximum playlists per player
Config.EnablePlaylists = true -- Enable playlist feature
Config.EnablePlaylistSharing = true -- Enable playlist sharing between players
Config.EnableShuffle = true -- Enable shuffle mode
Config.EnableLoop = true -- Enable loop mode

-- Permission Settings
Config.UsePermissions = false -- Require permissions to place speakers
Config.AllowedJobs = { -- Jobs allowed to place speakers (if UsePermissions = true)
    'police',
    'ambulance',
    'mechanic'
}

-- Item Settings
Config.RequireItem = true -- Require item to place speaker
Config.SpeakerItem = 'speaker' -- Item name in your inventory

-- Car Radio Settings
Config.EnableCarRadio = false -- Enable car radio feature
Config.CarRadioKey = 303 -- U key to open car radio
Config.CarRadioCommand = 'carradio' -- Command to open car radio
Config.CarRadioRange = 30.0 -- Range in meters to hear a car radio (prevents server-wide broadcast)

-- YouTube Settings
Config.AllowYouTube = true -- Allow YouTube URLs
Config.AllowSoundCloud = false -- Allow SoundCloud URLs (future feature)
Config.ValidateDomain = true -- Validate URL domain

-- UI Settings
Config.UITheme = 'dark' -- UI theme (dark, light)
Config.ShowNotifications = true -- Show notifications

-- Advanced Settings
Config.SyncInterval = 500 -- Sync interval in ms
Config.SaveSpeakers = false -- Save speakers after server restart (set to false for testing)
Config.AutoRemoveOnDisconnect = true -- Remove player's speakers on disconnect

-- Anti-Echo Settings (Prevents double audio when multiple speakers are close)
Config.EnableDominantSpeaker = true -- Only the closest speaker plays at full volume
Config.EchoPreventionDistance = 10.0 -- Distance (meters) where non-dominant speakers are attenuated
Config.NonDominantVolumeMax = 0.3 -- Maximum volume for non-dominant speakers (0.0 to 1.0) - Lower = less echo

-- Directional Audio Settings (Speaker sounds louder from front)
Config.EnableDirectionalAudio = true -- Enable directional audio (louder from front, quieter from back)
Config.DirectionalFrontVolume = 1.0 -- Volume multiplier when in front (0-60°) - 1.0 = 100%
Config.DirectionalSideVolume = 0.5 -- Volume multiplier when on sides (60-120°) - 0.5 = 50%
Config.DirectionalBackVolume = 0.2 -- Volume multiplier when behind (120-180°) - 0.2 = 20%

-- Time Synchronization Settings (Prevents audio desync/echo between synced speakers)
Config.EnableTimeSync = true -- Enable automatic time synchronization between speakers playing the same song
Config.TimeSyncInterval = 2000 -- How often to check and sync time (milliseconds) - Lower = more precise but more CPU
Config.TimeSyncThreshold = 0.3 -- Only sync if time difference is greater than this (seconds) - Lower = more aggressive

-- Speaker Synchronization
Config.SpeakerSync = {
    Enabled = true,                    -- Enable speaker sync system
    MaxSyncDistance = 30.0,            -- Maximum distance to sync speakers (meters)
    MaxSyncedSpeakers = 10,            -- Maximum synced speakers per group
    ShowDistanceInUI = true,           -- Show distance in UI
    RequireSameOwner = true,           -- Only sync your own speakers
    SyncVolume = true,                 -- Sync volume changes
    ShowSyncMarker = true,             -- Show sync indicator on 3D markers
}

-- Key Bindings
Config.Keys = {
    Interact = 38, -- E key
    Cancel = 194, -- BACKSPACE
}

-- Blacklisted URLs (regex patterns)
Config.BlacklistedDomains = {
    -- Add domains you want to block
}

-- Admin Commands
Config.AdminCommand = 'adminradio' -- Command to open admin panel
Config.AdminGroups = { 'admin', 'superadmin' } -- Groups with admin access

-- ================================================
-- Admin Radio System
-- ================================================
Config.AdminRadio = {
    Enabled = true,
    Command = 'adminradio',
    Permissions = {'god', 'admin'}, -- QBCore permission groups
    
    Modes = {
        ZONE = 'zone',          -- Players within radius
        PRIVATE = 'private'     -- Only admin
    },
    
    MinRadius = 10,             -- Minimum radius in meters
    MaxRadius = 500,            -- Maximum radius in meters
    DefaultRadius = 50,         -- Default radius in meters
    UpdateInterval = 500,       -- Update interval for zone checks (ms)
    
    DefaultVolume = 50,         -- Default volume (0-100)
    MinVolume = 0,
    MaxVolume = 100,
    
    ShowPlayerList = true,      -- Show list of players listening
    NotifyPlayers = false,       -- Notify players when admin radio starts/stops
    
    ShowHudBanner = true,       -- Show "Now Playing" HUD for players
    AllowPlayerVolumeControl = false, -- Players CANNOT adjust volume (admin only)
}

Config.CustomDrawText = false
Config.CustomNotify = false
