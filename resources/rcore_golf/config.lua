---@type Config
Config = {
	Framework = 0, --[ 1 = ESX / 2 = QBCore / 3 = Other ] Choose your framework
    SocietySystem = 0, --[ 1 = esx_addonaccount / 2 = qb-bossmenu / 3 = qb-management / 4 = qb-banking (v2.0.0 or newer) ]

    SocietyEnabled = false,
    SocietyName = "society_lsgolfclub", -- You will have to create a society with this name

	FrameworkTriggers = {
		notify = '', -- [ ESX = 'esx:showNotification' / QBCore = 'QBCore:Notify' ] Set the notification event, if left blank, default will be used
		load = '', --[ ESX = 'esx:getSharedObject' / QBCore = 'QBCore:GetObject' ] Set the shared object event, if left blank, default will be used (deprecated for QBCore)
		resourceName = '', -- [ ESX = 'es_extended' / QBCore = 'qb-core' ] Set the resource name, if left blank, automatic detection will be performed
	},

    -- https://docs.fivem.net/docs/game-references/controls
    Keys = {
        openLobbyKey = "E",
        scorecard = 311,
        changeShot = 217,
        swingPower = 223,
        quit = 206,
        reset = 310,
        previewShot = 209,
        previewHole = 203,
    },

    -- Change to 0.0 to disable wind or increase beyond 1.0 to make the wind have more effect
    WindEffect = 1.0,

    -- Time in milliseconds for how often the replay data should be routed to nearby players
    -- A higher value reduces the amount of events sent but increases the initial latency
    ReplaySendDelay = 100,

    --[[
        Enabling this option means that players will require the golf club item to play.
    ]]

    RequireGolfClub = false,
    GolfClubItem = "golf_club",
    EnableQSInventorySupport = false,
    EnableOxInventorySupport = false,

    --[[
        Change these options to affect the rentals of caddys and clubs
    ]]
    RentalPrice = 300,
    CaddyVehicleName = "caddy",
    ClubRentalAvailable = false, -- If enabled, player can rent a club in the UI before a game.
    ClubRentalPrice = 150,

    MembershipEnabled = false,
    MembershipPrice = 500,
    MembershipLength = (60 * 60 * 24 * 5), -- Time in seconds (5 days by default)

    -- Disabling this option will remove the red arrows guiding you towards the next hole
    NextHoleArrows = true,

    -- This will disable the radar after the game of golf is over
    DisableRadarAfterGame = false,
    ShotLimit = 10,

    -- Whether a spotlight should be drawn around the ball and around the hole to aid night visibility
    DrawSpotlights = true,

    -- This will show all the clubs as an option. This will increase the difficulty for your players.
    ShowAllClubs = false,

    WagersEnabled = true,
    MinigameWagersEnabled = true,

    -- The % of money to take from a wager to go into the configured society. Between 0.0 and 1.0
    HasWagerCommission = true,
    WagerCommissionAmount = 0.05,

    -- False by default. If enabled, it will put lobbies into seperate worlds so that they are unaffected by other players.
    UseBuckets = false,

    -- False by default. If enabled, will prevent the golf flags from displaying at any stage.
    DisableFlags = false,

    -- False by default. If enabled, the furthest player from the hole will always have the next shot.
    FurthestShootsFirst = false,

    -- False by default. If enabled, the player within X distance from the hole will have the next shot.
    -- If this and FurthestShootsFirst is enabled, then this will take precedence.
    NextToHoleShootsNext = false,
    NextToHoleDistance = 3.0,

    -- False by default. Disables the reaction animation and camera.
    DisableReactionAnimation = false,

    -- False by default. Deletes any caddies assigned to the player when they leave the golf game.
    DeleteCaddyAfterLeavingGame = false,
    -- Zero by default. The delay after leaving the game in which the caddy should attempt to be deleted. Value is in milliseconds.
    DeleteCaddyAfterLeavingDelay = 0,

    -- False by default. Hides the option to choose to rent a caddy.
    HideCaddyRentalCheckbox = false,

    BlipOptions = {
        blipId = 109, -- Blips can be found here https://docs.fivem.net/docs/game-references/blips/
        colour = nil -- nil will set it to default blip colour. Find all colours here https://docs.fivem.net/docs/game-references/blips/
    },

    -- The size of the marker that indicates where your current ball is (or tee). Default is 0.25
    CurrentMarkerSize = 0.25,

    -- The colour of the marker that indicates where your current ball is (or tee). This value is RGBA.
    CurrentMarkerColour = {216, 27, 85, 125}, -- ORIGEN: rosa de la casa (era granate 52,5,29)

    -- The config for blip that displays where the starting hole is
    TeeBlipData = {
        sprite = 161,
        scale = 0.4,
        colour = 10,
    },

    MinigameScore = {
        maxTimeLimitMsec = 300000,
        scoreToReach = 500,
        maxNumShots = 20,
    },

    MinigamePresure = {
        maxTimeLimitMsec = 300000,
        maxNumShots = 20,
    },

    -- A random force to be applied to the ball in the air for minigames.
    -- Set to 0.0 to disable, or increase for more randomness (increased difficulty)
    -- For longer distances, this effect may become more noticable.
    MinigameRandomForce = 0.0,

    -- Adds prints to the server console that are relevant to the RCore developers. Do not enable unless asked by RCore support.
    Debug = true,
}

---@type table<string, LocationConfig>
LocationsConfig = {
    ["Los Santos Golf Club"] = {
        LobbyCoords = vector3(-1366.18, 56.68, 53.12846),
        AddMapBlip = true,

        MainBounds = {
            {vector3(-1225.16, 79.389, 46.41), 200.0},
            {vector3(-1045.0, -40.0, 43.98), 135.0}
        },

        MembershipPurchaseCoords = vector3(-1366.063, 54.67165, 53.12846),

        HolesConfig = {
            {
                par = 5,
                mapAngle = 280,
                holeCoords = vector3(-1114.121, 220.789, 63.78),
                finalBallPosCoord = vector3(-1114.120972, 220.789551, 63.856472),
                teeCoords = vector3(-1370.93, 173.98, 57.01),
                bounds = {
                    {vector3(-1365.7279, 174.31537, 57.01312), 20.75},
                    {vector3(-1351.8052, 179.00304, 57.291412), 25.75},
                    {vector3(-1338.6167, 182.51062, 57.515053), 25.75},
                    {vector3(1320.9374, 184.8574, 57.82013), 25.75},
                    {vector3(-1303.4974, 185.03795, 58.282097), 25.75},
                    {vector3(-1287.778, 186.67972, 58.92799), 25.75},
                    {vector3(-1276.0924, 187.6004, 59.52738), 25.75},
                    {vector3(-1256.2947, 188.98596, 61.28985), 25.0},
                    {vector3(-1235.7712, 189.36678, 62.402626), 29.5},
                    {vector3(-1217.6161, 191.28922, 63.778843), 33.5},
                    {vector3(-1189.6769, 198.54466, 64.96094), 45.0},
                    {vector3(-1147.4658, 215.92424, 64.519), 40.75},
                },
                terrainGrid = {
                    center = vector3(-1120.569, 222.185, 64.814),
                    direction = vector3(-0.712, 0.7, 0.0),
                    box = vector3(14.92, 24.48, -0.63),
                    gridRes = 42.0
                },
                map = {
                    far = { pos = vector2(-1222.0, 83.0), zoom = 0.81 },
                    short = { pos = vector2(-1142.0, 156.0), zoom = 0.003 }
                }
            },
            {
                par = 4,
                mapAngle = 89,
                holeCoords = vector3(-1322.07, 158.77, 56.69),
                finalBallPosCoord = vector3(-1322.074219, 158.774094, 56.761597),
                teeCoords = vector3(-1107.26, 157.15, 62.04),
                bounds = {
                    {vector3(-1327.7368, 159.32567, 56.804813), 20.0},
                    {vector3(-1313.003, 151.44281, 57.082485), 20.0},
                    {vector3(-1300.2255, 150.73505, 57.934685), 18.75},
                    {vector3(-1314.3357, 159.9026, 56.821346), 18.75},
                    {vector3(-1291.734, 162.25293, 57.521557), 18.75},
                    {vector3(-1273.5385, 163.71556, 57.99153), 18.75},
                    {vector3(-1255.3575, 159.83023, 57.953476), 22.75},
                    {vector3(-1260.9087, 144.87056, 57.691547), 22.75},
                    {vector3(-1244.6907, 145.63866, 57.71403), 22.75},
                    {vector3(-1222.357, 145.15588, 58.442333), 33.5},
                    {vector3(-1195.7145, 138.88812, 59.483425), 38.5},
                    {vector3(-1161.0116, 149.754, 61.720253), 38.5},
                    {vector3(-1118.562, 155.97157, 61.498318), 38.5},
                    {vector3(-1234.8796, 162.84953, 59.07859), 15.0},
                    {vector3(-1304.9606, 167.75325, 57.58253), 10.25},
                },
                terrainGrid = {
                    center = vector3(-1326.193, 162.31, 56.974),
                    direction = vector3(-0.771, 0.636, 0.003),
                    box = vector3(19.48, 24.34, -0.63),
                    gridRes = 42.0
                },
                map = {
                    far = { pos = vector2(-1216.0, 247.0), zoom = 0.75 },
                    short = { pos = vector2(-1294.0, 195.0), zoom = 0.001 }
                }
            },
            {
                par = 3,
                mapAngle = 264,
                holeCoords = vector3(-1237.419, 112.988, 56.086),
                finalBallPosCoord = vector3(-1237.418091, 112.987625, 56.161892),
                teeCoords = vector3(-1312.97, 125.64, 56.39),
                bounds = {
                    {vector3(-1304.9606, 167.75325, 57.58253), 6.25},
                    {vector3(-1234.8796, 162.84953, 59.07859), 11.0},
                    {vector3(-1241.9308, 103.196625, 55.61257), 36.0},
                    {vector3(-1255.2334, 110.28992, 55.627853), 36.0},
                    {vector3(-1274.2787, 119.10796, 56.414837), 28.0},
                    {vector3(-1293.0032, 121.77718, 56.083878), 23.0},
                    {vector3(-1302.7052, 124.26931, 56.271282), 23.0},
                },
                terrainGrid = {
                    center = vector3(-1238.702, 106.882, 56.462),
                    direction = vector3(0.177, 0.982, 0.06),
                    box = vector3(15.72, 27.98, 0.1),
                    gridRes = 42.0
                },
                map = {
                    far = { pos = vector2(-1274.5, 65.0), zoom = 0.1 },
                    short = { pos = vector2(-1274.5, 65.0), zoom = 0.1 }
                }
            },
            {
                par = 4,
                mapAngle = 232,
                holeCoords = vector3(-1096.541, 7.848, 49.63),
                finalBallPosCoord = vector3(-1096.539185, 7.845760, 49.697449),
                teeCoords = vector3(-1218.56, 107.48, 57.04),
                bounds = {
                    {vector3(-1221.06, 98.5996, 57.8836), 20.9},
                    {vector3(-1200.08, 92.5423, 57.6517), 27.65},
                    {vector3(-1178.72, 83.8707, 60.6101), 32.525},
                    {vector3(-1149.67, 68.5744, 57.3165), 36.62},
                    {vector3(-1138.01, 55.2482, 54.4325), 33.52},
                    {vector3(-1125.44, 41.863, 51.9212), 29.825},
                    {vector3(-1121.19, 35.1585, 51.5821), 30.425},
                    {vector3(-1101.69, 12.5718, 50.1535), 34.025},
                    {vector3(-1116.93, 0.466945, 49.0627), 18.575},
                    {vector3(-1155.4375, 92.815, 56.99), 14.5},
                    {vector3(-1095.9377, 42.5799, 50.345), 11.12},
                    {vector3(-1105.0049, 50.75577, 51.6625), 14.7},
                    {vector3(-1093.2511, 36.75171, 49.51097), 11.49},
                    {vector3(-1112.3789, 61.12305, 52.97316), 10.85},
                },
                terrainGrid = {
                    center = vector3(-1099.278, 10.541, 50.81),
                    direction = vector3(-0.993, 0.11, -0.046),
                    box = vector3(33.05, 36.35, -0.63),
                    gridRes = 65.0
                },
                map = {
                    far = { pos = vector2(-1197.0, 1.0), zoom = 0.55 },
                    short = { pos = vector2(-1145.0, 0.0), zoom = 0.001 }
                }
            },
            {
                par = 4,
                mapAngle = 220,
                holeCoords = vector3(-957.386, -90.412, 39.161),
                finalBallPosCoord = vector3(-957.384888, -90.412399, 39.235317),
                teeCoords = vector3(-1098.15, 69.5, 53.09),
                bounds = {
                    {vector3(-946.038, -84.43751, 39.088943), 29.75},
                    {vector3(-969.9369, -67.45364, 40.620064), 29.75},
                    {vector3(-990.43317, -51.773438, 41.65581), 35.75},
                    {vector3(-1006.6395, -20.229515, 45.67778), 48.0},
                    {vector3(-1030.7417, 10.294682, 49.258698), 48.0},
                    {vector3(-1074.0447, 49.566372, 50.12212), 29.75},
                    {vector3(-1081.7299, 57.717678, 50.813744), 29.75},
                    {vector3(-1059.0913, 48.760387, 49.809143), 29.75},
                    {vector3(-1037.4043, 37.183304, 45.01267), 29.75},
                    {vector3(-987.92706, 12.216481, 51.47941), 58.25},
                    {vector3(-923.3143, -55.92058, 38.37607), 58.25},
                    {vector3(-939.21606, -106.79802, 41.728218), 30.75},
                },
                terrainGrid = {
                    center = vector3(-965.273, -82.437, 41.041),
                    direction = vector3(0.549, -0.835, -0.031),
                    box = vector3(20.47, 42.54, -0.63),
                    gridRes = 42.0
                },
                map = {
                    far = { pos = vector2(-1090.0, -70.0), zoom = 0.75 },
                    short = { pos = vector2(-1004.0, -92.0), zoom = 0.001 }
                }
            },
            {
                par = 3,
                mapAngle = 90,
                holeCoords = vector3(-1103.516, -115.163, 40.444),
                finalBallPosCoord = vector3(-1103.515137, -115.161896, 40.518902),
                teeCoords = vector3(-987.7, -105.42, 39.59),
                bounds = {
                    {vector3(-989.4491, -122.88058, 39.029953), 25.25},
                    {vector3(-1018.1705, -117.23991, 40.538963), 25.25},
                    {vector3(-1045.5242, -123.05896, 40.773052), 28.0},
                    {vector3(-1072.8293, -123.25536, 40.2801), 42.0},
                    {vector3(-1094.7015, -125.87067, 40.66322), 42.0},
                },
                terrainGrid = {
                    center = vector3(-1102.084, -116.732, 40.891),
                    direction = vector3(-0.485, -0.875, -0.006),
                    box = vector3(18.56, 20.0, -0.63),
                    gridRes = 42.0
                },
                map = {
                    far = { pos = vector2(-1051.0, -55.0), zoom = 0.5 },
                    short = { pos = vector2(-1076.0, -76.0), zoom = 0.001 }
                }
            },
            {
                par = 4,
                mapAngle = 57,
                holeCoords = vector3(-1290.632, 2.752214, 49.25432),
                finalBallPosCoord = vector3(-1290.638428, 2.759101, 49.302151),
                teeCoords = vector3(-1117.793, -104.069, 40.8406),
                bounds = {
                    {vector3(-1136.2417, -95.06858, 41.302517), 28.25},
                    {vector3(-1165.4347, -81.74862, 44.06945), 37.0},
                    {vector3(-1191.7983, -60.593716, 43.36213), 37.0},
                    {vector3(-1209.493, -45.690117, 43.19042), 37.0},
                    {vector3(-1222.7806, -37.27245, 44.954025), 37.0},
                    {vector3(-1233.6812, -29.527641, 42.59613), 40.0},
                    {vector3(-1254.5319, -18.875807, 46.362934), 40.0},
                    {vector3(-1291.9644, -1.428747, 49.29616), 40.0},
                },
                terrainGrid = {
                    center = vector3(-1284.205, 4.114, 49.654),
                    direction = vector3(-0.997, -0.018, 0.076),
                    box = vector3(19.01, 20.0, 0.7),
                    gridRes = 42.0
                },
                map = {
                    far = { pos = vector2(-1164.0, 40.0), zoom = 0.75 },
                    short = { pos = vector2(-1250.0, 34.0), zoom = 0.085 }
                }
            },
            {
                par = 5,
                mapAngle = 240,
                holeCoords = vector3(-1034.944, -83.144, 42.919),
                finalBallPosCoord = vector3(-1034.943970, -83.144104, 42.998821),
                teeCoords = vector3(-1272.63, 38.4, 48.75),
                bounds = {
                    {vector3(-1262.2653, 30.905869, 47.800354), 23.5},
                    {vector3(-1238.0144, 20.013653, 46.685284), 31.5},
                    {vector3(-1207.6115, -1.210448, 46.65575), 36.25},
                    {vector3(-1176.8757, -18.25381, 45.277035), 36.25},
                    {vector3(-1159.9237, -21.481136, 45.18527), 25.25},
                    {vector3(-1150.8055, -33.96546, 44.683826), 26.75},
                    {vector3(-1137.1497, -43.70882, 44.634342), 26.75},
                    {vector3(-1142.3267, -47.365517, 44.363075), 30.0},
                    {vector3(-1139.1334, -47.338657, 44.39388), 32.0},
                    {vector3(-1123.0103, -54.36808, 43.90327), 32.0},
                    {vector3(-1105.071, -64.81659, 43.047184), 32.0},
                    {vector3(-1088.1053, -68.64159, 42.17559), 32.0},
                    {vector3(-1077.9634, -71.280106, 42.958477), 32.0},
                    {vector3(-1067.0763, -77.985, 42.574677), 32.0},
                    {vector3(-1053.7423, -83.321754, 42.58896), 32.0},
                    {vector3(-1041.1979, -87.2557, 42.836494), 30.0},
                },
                terrainGrid = {
                    center = vector3(-1041.863, -84.943, 43.14),
                    direction = vector3(0.799, 0.6, 0.033),
                    box = vector3(18.69, 24.09, 0.68),
                    gridRes = 42.0
                },
                map = {
                    far = { pos = vector2(-1212.0, -120.0), zoom = 0.825 },
                    short = { pos = vector2(-1097.0, -109.0), zoom = 0.001 }
                }
            },
            {
                par = 4,
                mapAngle = 63,
                holeCoords = vector3(-1294.775, 83.50845, 53.84124),
                finalBallPosCoord = vector3(-1294.775024, 83.524429, 53.887627),
                teeCoords = vector3(-1138.381, 0.60467, 47.98225),
                bounds = {
                    {vector3(-1283.3811, 80.55217, 53.905674), 30.5},
                    {vector3(-1252.5955, 70.568245, 51.245884), 31.0},
                    {vector3(-1229.6606, 60.067318, 51.890144), 31.0},
                    {vector3(-1215.0654, 50.102516, 51.799274), 33.0},
                    {vector3(-1181.4375, 28.372972, 50.825546), 37.5},
                    {vector3(-1167.5991, 15.932876, 49.16326), 37.5},
                    {vector3(-1151.0776, 9.428267, 48.30155), 35.0},
                    {vector3(-1187.1747, 60.732788, 53.639885), 9.0},
                },
                terrainGrid = {
                    center = vector3(-1289.969, 83.574, 54.183),
                    direction = vector3(-1.0, 0.004, 0.005),
                    box = vector3(19.01, 20.0, -0.63),
                    gridRes = 42.0
                },
                map = {
                    far = { pos = vector2(-1173.0, 117.0), zoom = 0.675 },
                    short = { pos = vector2(-1242.0, 106.0), zoom = 0.001 }
                }
            },
        },

        CaddySpawns = {
            vector4(-1392.912, 91.31939, 54.17518, 128.0),
            vector4(-1392.063, 86.06332, 54.0684, 128.0),
            vector4(-1391.675, 81.1264, 53.89445, 128.0),
            vector4(-1391.274, 75.78645, 53.70116, 128.0),
            vector4(-1390.921, 70.31268, 53.61623, 128.0),
            vector4(-1390.661, 65.10999, 53.61349, 128.0),
            vector4(-1390.225, 59.79699, 53.60974, 128.0),
            vector4(-1390.095, 54.29893, 53.60391, 128.0),
            vector4(-1389.026, 49.47268, 53.63363, 128.0),
            vector4(-1388.256, 44.68359, 53.61609, 128.0),
            vector4(-1387.728, 39.53733, 53.61742, 128.0),
            vector4(-1387.654, 33.92693, 53.59889, 128.0),
            vector4(-1386.881, 28.71876, 53.60514, 128.0)
        },

        HolesGuide = {
            {
                vec3(-1371.148560, 63.581978, 53.688217),
                vec3(-1375.237915, 69.267532, 53.856236),
                vec3(-1377.394287, 75.353401, 53.819565),
                vec3(-1378.228027, 82.372650, 54.114098),
                vec3(-1379.067383, 89.157173, 54.253143),
                vec3(-1379.946045, 96.258446, 54.532337),
                vec3(-1380.813232, 103.273270, 54.794167),
                vec3(-1381.681641, 110.295273, 55.030556),
                vec3(-1382.818970, 117.179192, 55.243572),
                vec3(-1383.643677, 124.161308, 55.436382),
                vec3(-1383.763550, 131.227005, 55.637619),
                vec3(-1382.599976, 138.063202, 56.079800),
                vec3(-1380.692993, 144.872101, 56.086079),
                vec3(-1378.786133, 151.686127, 56.934551),
                vec3(-1376.878540, 158.501282, 57.277390),
                vec3(-1374.971436, 165.315887, 57.910137),
            },
            {
                vec3(-1113.834106, 218.501740, 64.898285),
                vec3(-1113.047729, 211.840042, 64.882904),
                vec3(-1112.203857, 204.820068, 64.812546),
                vec3(-1111.515747, 198.986115, 64.082390),
                vec3(-1110.683716, 192.145020, 63.710812),
                vec3(-1109.839722, 185.119583, 63.455601),
                vec3(-1108.986328, 178.014496, 63.178684),
                vec3(-1108.144287, 170.996567, 62.905586),
                vec3(-1107.301147, 163.971466, 63.001347),
            },
            {
                vec3(-1322.069946, 158.770004, 57.689999),
                vec3(-1321.429443, 156.521820, 57.804268),
                vec3(-1319.692627, 150.017502, 57.912247),
                vec3(-1317.840088, 143.217728, 57.927696),
                vec3(-1315.995728, 136.417282, 58.037609),
            },
            {
                vec3(-1237.418945, 112.987999, 57.085999),
                vec3(-1234.806763, 112.415245, 57.265411),
                vec3(-1228.268555, 110.416779, 57.512554),
            },
            {
                vec3(-1096.541016, 7.848000, 50.630001),
                vec3(-1096.617676, 9.663671, 50.752338),
                vec3(-1096.523926, 15.985022, 50.882149),
                vec3(-1096.519653, 23.054283, 51.069912),
                vec3(-1096.510986, 30.120724, 50.885788),
                vec3(-1096.531006, 36.988140, 51.162601),
                vec3(-1096.886353, 44.047791, 51.574947),
                vec3(-1097.240723, 51.194664, 52.333530),
                vec3(-1097.575317, 57.898891, 53.621368),
            },
            {
                vec3(-957.384644, -90.417824, 40.276348),
                vec3(-959.371216, -91.060715, 40.253227),
                vec3(-965.461243, -93.173866, 40.301739),
                vec3(-972.141541, -95.451675, 40.616348),
                vec3(-978.712341, -97.696953, 40.807590),
                vec3(-985.276062, -100.100075, 40.598282),
            },
            {
                vec3(-1103.515991, -115.163002, 41.444000),
                vec3(-1105.105835, -113.886406, 41.548492),
                vec3(-1110.229126, -109.948090, 41.560616),
            },
            {
                vec3(-1290.631958, 2.752214, 50.254318),
                vec3(-1289.677979, 4.600928, 50.362774),
                vec3(-1286.579590, 10.383440, 50.401154),
                vec3(-1283.265991, 16.628931, 50.297787),
                vec3(-1279.947754, 22.879671, 49.700008),
                vec3(-1276.789673, 28.832985, 49.169838),
            },
            {
                vec3(-1034.943970, -83.143997, 43.918999),
                vec3(-1036.605957, -82.168243, 43.999443),
                vec3(-1042.125122, -78.933266, 43.828815),
                vec3(-1048.223511, -75.354271, 43.799709),
                vec3(-1053.840820, -72.077614, 44.562538),
                vec3(-1059.953125, -68.588326, 44.312572),
                vec3(-1066.083740, -65.128044, 44.496071),
                vec3(-1071.062988, -62.322254, 44.934727),
                vec3(-1076.548584, -59.293430, 45.170078),
                vec3(-1081.425537, -56.568794, 45.497028),
                vec3(-1085.602539, -53.521267, 45.655365),
                vec3(-1088.145996, -51.063423, 47.068562),
                vec3(-1092.430176, -48.840061, 47.635059),
                vec3(-1096.575439, -46.203384, 48.243374),
                vec3(-1101.021729, -40.939770, 48.390835),
                vec3(-1105.952515, -35.879536, 48.715843),
                vec3(-1110.883789, -30.804623, 49.039463),
                vec3(-1115.563477, -25.986719, 49.085110),
                vec3(-1120.487793, -20.904985, 49.149925),
                vec3(-1125.392944, -15.805065, 49.129654),
                vec3(-1130.299927, -10.706851, 49.069916),
                vec3(-1135.207031, -5.607260, 48.979797),
            }
        }
    },

    ["Top Golf"] = {
        requiredResource = "k4mb1-topgolf",

        LobbyCoords = vec3(2520.862305, -312.065369, 92.012226),
        AddMapBlip = true,

        MainBounds = {
            {vec3(2523.529785, -409.906952, 92.992279), 95.0},
            {vec3(2518.483398, -322.206696, 92.992279), 75.0},
        },

        MembershipPurchaseCoords = vec3(2523.064453, -312.087189, 92.012233),

        HolesConfig = {},

        CaddySpawns = {
            vector4(2561.818848, -330.303192, 92.992050, 274.739899),
            vector4(2565.524658, -330.347290, 92.992058, 271.837860),

            vector4(2562.034424, -327.401611, 92.992058, 268.015625),
            vector4(2565.359375, -327.056885, 92.992058, 270.916229),

            vector4(2561.893311, -324.202271, 92.992058, 273.397217),
            vector4(2565.410889, -324.091064, 92.992058, 270.978729),

            vector4(2561.973389, -320.999420, 92.992058, 272.376099),
            vector4(2565.274902, -321.040527, 92.992058, 271.354126),

            vector4(2561.863525, -317.963928, 92.992058, 276.020020),
            vector4(2565.204590, -317.800537, 92.992058, 272.128845),

            vector4(2561.922363, -314.850647, 92.992058, 272.909271),
            vector4(2565.052002, -314.740326, 92.992058, 270.445740)
        },

        HolesGuide = {},

        MinigamesStartPositions = {
            -- Ground Floor
            vec3(2557.704834, -333.874359, 92.016441),
            vec3(2553.991211, -333.252777, 92.003006),
            vec3(2550.174805, -332.714569, 92.002968),
            vec3(2546.385010, -332.345886, 92.002983),
            vec3(2542.651367, -332.031372, 92.002975),
            vec3(2538.850586, -331.785583, 92.002960),
            vec3(2535.085205, -331.612793, 92.002998),
            vec3(2531.408691, -331.424072, 92.002968),
            vec3(2527.574219, -331.389374, 92.002945),
            vec3(2523.874512, -331.358551, 92.002983),
            vec3(2520.090576, -331.367859, 92.002998),
            vec3(2516.396484, -331.365295, 92.002930),
            vec3(2512.686279, -331.368988, 92.002968),
            vec3(2508.924072, -331.612396, 92.002998),
            vec3(2505.145264, -331.755859, 92.002937),
            vec3(2501.408936, -332.049011, 92.002998),
            vec3(2497.584961, -332.254852, 92.002975),
            vec3(2493.781738, -332.652313, 92.002930),
            vec3(2489.989990, -333.299042, 92.002930),
            vec3(2486.229492, -333.889191, 92.003181),
            -- Floor 1
            vec3(2557.704834, -333.874359, 96.866441),
            vec3(2553.991211, -333.252777, 96.863006),
            vec3(2550.174805, -332.714569, 96.862968),
            vec3(2546.385010, -332.345886, 96.862983),
            vec3(2542.651367, -332.031372, 96.862975),
            vec3(2538.850586, -331.785583, 96.862960),
            vec3(2535.085205, -331.612793, 96.862998),
            vec3(2531.408691, -331.424072, 96.862968),
            vec3(2527.574219, -331.389374, 96.862945),
            vec3(2523.874512, -331.358551, 96.862983),
            vec3(2520.090576, -331.367859, 96.862998),
            vec3(2516.396484, -331.365295, 96.862930),
            vec3(2512.686279, -331.368988, 96.862968),
            vec3(2508.924072, -331.612396, 96.862998),
            vec3(2505.145264, -331.755859, 96.862937),
            vec3(2501.408936, -332.049011, 96.862998),
            vec3(2497.584961, -332.254852, 96.862975),
            vec3(2493.781738, -332.652313, 96.862930),
            vec3(2489.989990, -333.299042, 96.862930),
            vec3(2486.229492, -333.889191, 96.863181),
            -- Floor 2
            vec3(2557.704834, -333.874359, 101.716441),
            vec3(2553.991211, -333.252777, 101.713006),
            vec3(2550.174805, -332.714569, 101.712968),
            vec3(2546.385010, -332.345886, 101.712983),
            vec3(2542.651367, -332.031372, 101.712975),
            vec3(2538.850586, -331.785583, 101.712960),
            vec3(2535.085205, -331.612793, 101.712998),
            vec3(2531.408691, -331.424072, 101.712968),
            vec3(2527.574219, -331.389374, 101.712945),
            vec3(2523.874512, -331.358551, 101.712983),
            vec3(2520.090576, -331.367859, 101.712998),
            vec3(2516.396484, -331.365295, 101.712930),
            vec3(2512.686279, -331.368988, 101.712968),
            vec3(2508.924072, -331.612396, 101.712998),
            vec3(2505.145264, -331.755859, 101.712937),
            vec3(2501.408936, -332.049011, 101.712998),
            vec3(2497.584961, -332.254852, 101.712975),
            vec3(2493.781738, -332.652313, 101.712930),
            vec3(2489.989990, -333.299042, 101.712930),
            vec3(2486.229492, -333.889191, 101.713181),
            -- Floor 3
            vec3(2557.704834, -333.874359, 106.576441),
            vec3(2553.991211, -333.252777, 106.573006),
            vec3(2550.174805, -332.714569, 106.572968),
            vec3(2546.385010, -332.345886, 106.572983),
            vec3(2542.651367, -332.031372, 106.572975),
            vec3(2538.850586, -331.785583, 106.572960),
            vec3(2535.085205, -331.612793, 106.572998),
            vec3(2531.408691, -331.424072, 106.572968),
            vec3(2527.574219, -331.389374, 106.572945),
            vec3(2523.874512, -331.358551, 106.572983),
            vec3(2520.090576, -331.367859, 106.572998),
            vec3(2516.396484, -331.365295, 106.572930),
            vec3(2512.686279, -331.368988, 106.572968),
            vec3(2508.924072, -331.612396, 106.572998),
            vec3(2505.145264, -331.755859, 106.572937),
            vec3(2501.408936, -332.049011, 106.572998),
            vec3(2497.584961, -332.254852, 106.572975),
            vec3(2493.781738, -332.652313, 106.572930),
            vec3(2489.989990, -333.299042, 106.572930),
            vec3(2486.229492, -333.889191, 106.573181),
        },

        MinigamesHoles = {
            {
                position = vec3(2550.020752, -352.578094, 91.985),
                segments = {
                    {
                        radius = 2.2,
                        numSegments = 4,
                        initialHeading = -17.0,
                        scoreGiven = 20,
                    }
                }
            },
            {
                position = vec3(2530.916016, -349.174011, 91.985),
                segments = {
                    {
                        radius = 2.2,
                        numSegments = 4,
                        initialHeading = -5.0,
                        scoreGiven = 20,
                    }
                }
            },
            {
                position = vec3(2511.817627, -349.122192, 91.985),
                segments = {
                    {
                        radius = 2.2,
                        numSegments = 4,
                        initialHeading = 6.0,
                        scoreGiven = 20,
                    }
                }
            },
            {
                position = vec3(2492.682861, -352.602356, 91.985),
                segments = {
                    {
                        radius = 2.2,
                        numSegments = 4,
                        initialHeading = 17.0,
                        scoreGiven = 20,
                    }
                }
            },
            {
                position = vec3(2507.802002, -369.244629, 91.985),
                segments = {
                    {
                        radius = 2.75,
                        numSegments = 8,
                        initialHeading = 5.6,
                        scoreGiven = 25,
                    },
                    {
                        radius = 5.4,
                        numSegments = 8,
                        initialHeading = 5.6,
                        scoreGiven = 20,
                    },
                },
            },
            {
                position = vec3(2535.237305, -369.282257, 91.985),
                segments = {
                    {
                        radius = 2.75,
                        numSegments = 8,
                        initialHeading = 5.6,
                        scoreGiven = 25,
                    },
                    {
                        radius = 5.4,
                        numSegments = 8,
                        initialHeading = 5.6,
                        scoreGiven = 20,
                    },
                },
            },
            {
                position = vec3(2514.823486, -396.715149, 91.985),
                segments = {
                    {
                        radius = 1.95,
                        numSegments = 8,
                        initialHeading = 0.0,
                        scoreGiven = 50,
                    },
                    {
                        radius = 5.4,
                        numSegments = 8,
                        initialHeading = 0.0,
                        scoreGiven = 25,
                    },
                    {
                        radius = 9.0,
                        numSegments = 8,
                        initialHeading = 0.0,
                        scoreGiven = 20,
                    },
                }
            },
            {
                position = vec3(2531.526367, -422.356842, 91.985),
                segments = {
                    {
                        radius = 2.15,
                        numSegments = 8,
                        initialHeading = 0.0,
                        scoreGiven = 65,
                    },
                    {
                        radius = 5.95,
                        numSegments = 8,
                        initialHeading = 0.0,
                        scoreGiven = 25,
                    },
                    {
                        radius = 9.9,
                        numSegments = 8,
                        initialHeading = 0.0,
                        scoreGiven = 20,
                    },
                }
            },
            {
                position = vec3(2512.334229, -446.424652, 91.985),
                segments = {
                    {
                        radius = 2.3,
                        numSegments = 8,
                        initialHeading = 0.0,
                        scoreGiven = 80,
                    },
                    {
                        radius = 6.50,
                        numSegments = 8,
                        initialHeading = 0.0,
                        scoreGiven = 25,
                    },
                    {
                        radius = 10.8,
                        numSegments = 8,
                        initialHeading = 0.0,
                        scoreGiven = 20,
                    },
                }
            },
            {
                position = vec3(2532.690918, -473.540649, 91.985),
                segments = {
                    {
                        radius = 2.5,
                        numSegments = 8,
                        initialHeading = 0.0,
                        scoreGiven = 100,
                    },
                    {
                        radius = 7.0,
                        numSegments = 8,
                        initialHeading = 0.0,
                        scoreGiven = 25
                    },
                    {
                        radius = 11.75,
                        numSegments = 8,
                        initialHeading = 0.0,
                        scoreGiven = 25,
                    },
                }
            }
        }
    }
}

if not Config.BlipOptions then
    Config.BlipOptions = {
        blipId = 109,
        colour = nil
    }
end