Config = {}

-- Entity Set Configuration
Config.EntitySets = {
    poker = {
        enabled = true, -- Set to true to enable the poker entity set, false to disable
        location = vector3(1577.52856, 3746.17773, 37.00349),
        interior = nil -- Will be populated when interior is found
    }
}

-- Room Configuration
Config.Rooms = {
    enabled = true, -- Set to false to disable room IPLs and use fake doors instead
    fakedoors_ipl = "prompt_sandy_motel_fakedoors" -- IPL to load when rooms are disabled
}

-- Static Interior Configuration
Config.StaticInterior = {
    coordinates = vector3(1622.02, 3782.31, 25.52), -- Static interior location for hotel scripts: YOU CANNOT CHANGE THE POSITION!!!
    description = "Static interior for hotel scripts. Use different dimensions to tp the player to the same interior but they won't see each other"
} 