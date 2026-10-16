Config = {
	Framework = 0, --[ 1 = ESX / 2 = QBCore / 3 = Other ] Choose your framework
	SocietySystem = 0, --[ 1 = esx_addonaccount / 2 = qb-bossmenu / 3 = qb-management ]

	FrameworkTriggers = {
		notify = '', -- [ ESX = 'esx:showNotification' / QBCore = 'QBCore:Notify' ] Set the notification event, if left blank, default will be used
		object = '', --[ ESX = 'esx:getSharedObject' / QBCore = 'QBCore:GetObject' ] Set the shared object event, if left blank, default will be used (deprecated for QBCore)
		resourceName = '', -- [ ESX = 'es_extended' / QBCore = 'qb-core' ] Set the resource name, if left blank, automatic detection will be performed
	},

	SocietyPrefix = "society_", -- How societies are named in your city. For example society_mechanic.

	--[[
		This automatically adds a help point to Burton bowling alley,
		helping players get to the bowling alley and teaches them the basic rules
		and physics.

		This feature requires https://store.rcore.cz/package/5041989, but bowling works great without it.
	]]
	EnableGuidebookIntegration = true,

	--[[
		Further blip configuration (scale, sprite, color)
		can be made directly in client/blip.lua
	]]
	Blips = {
		vector3(-1355.31, -641.44, 23.03), -- k4mb1 bowling map
		-- vector3(-149.44, -258.21, 44.14), -- breze bowling map
		-- vector3(749.92, -776.68, 26.33), -- gabz bowling map
	},

	RenderLaneDebug = false,

	EnabledMaps = {
		K4MB1_BOWLING = true,
		BREZE_BOWLING = false,
		GABZ_BOWLING = false,
		YBN_MILO_RICHARDS_BOWLING = false,
		YBN_MILO_SANDY_SHORES = false,
		YBN_ROCKFORD_MALL = false,
		MAP4ALL_BOWLING = false,
		GND_BOWLING = false,
		TLUX_BOWLING = false,
		DESERT_MANSION = false,
		MARC_BOWL = false,
		AEGON_BOWLING = false,
		VIHHS_WONDERAMA = false,
	},

	AllowWager = true,
	ScoreboardCommand = 'bowling',
	Text = {
		BLIP = 'Bolos',

		REGISTER_LANE = '~INPUT_PICKUP~ %sCrear nueva partida~n~~INPUT_SPRINT~ + ~INPUT_PICKUP~ %sCrear partida por equipos',
		JOIN_LANE = '~INPUT_PICKUP~ %sUnirse a la partida',
		PLAY = '~INPUT_PICKUP~ Jugar',
		OPEN = '~INPUT_PICKUP~ Abrir',
		TAKE_BALL = '~INPUT_PICKUP~ Coger bola',

		NOT_IN_GAME = 'Actualmente no estás jugando a los bolos.',
		NOT_ENOUGH_MONEY = 'No tienes suficiente dinero para pagar la apuesta.',
		NOT_ENOUGH_MONEY_FEE = 'No tienes suficiente dinero para pagar la tarifa de la bolera.',
		NOT_ENOUGH_MONEY_AND_FEE = 'No tienes suficiente dinero para pagar la apuesta y la tarifa de la bolera.',
		INPUT_POSITION = 'Selecciona la ~y~posición inicial de la bola~s~',
		INPUT_ROTATION = 'Selecciona el ~y~efecto~s~ de la bola',
		INPUT_ANGLE = 'Selecciona el ~y~ángulo de lanzamiento~s~',
		INPUT_POWER = 'Selecciona la ~y~potencia de lanzamiento~s~',
		
        TOTAL = "Total",
        MATCH_END = "La partida termina en {0} segundos",
		MATCH_WHO_WON = "{0} ganó ${1}",

		START = "Iniciar",
		CLOSE = "Cerrar",
		JOIN = "Unirse",
		REGISTER = "Registrarse",
		WAGER = "Apuesta",
		WAGER_SET_TO = "La apuesta está fijada en <b>${0}</b>",
		WAGER_NONE = "Sin apuesta",
		INPUT_CONFIRM = "~INPUT_ATTACK~ Confirmar",
		ROUND_COUNT = "Número de rondas",
		TEAM = "Equipo",
		PLAYER = "Jugador",
		TEAM_NAME = 'Nombre del equipo',
		YOUR_NAME = 'Tu nombre',
		LEFT_LANE = 'Has abandonado los bolos.'
	},
	ThrowWait = 1800,
}

POINTS_BREZE = {
    LEFT = {
        {vector3(0.0, 0.0, 0.0), 3.0, 0.0},
        {vector3(0.05000305, 0.1100159, 0.4399986), 3.0, 0.0},
        {vector3(0.2600098, 0.7700195, 0.579998), 1.0, -90.0},
        {vector3(0.2600098, 0.7700195, 0.5599976), 1.0, -90.0}, 
        {vector3(0.480011, 0.6900024, 0.5599976), 1.0, -90.0},
        {vector3(1.059998, 2.340012, 0.5599976), 1.0, 0.0}
    },
    RIGHT = {
        {vector3(0, 0, 0), 3.0, 0.0},
        {vector3(0.05000305, 0.1100159, 0.4399986), 3.0, 0.0},
        {vector3(0.2600098, 0.7700195, 0.579998), 1.0, -90.0},
        {vector3(0.2600098, 0.7700195, 0.5599976), 1.0, -90.0}, 
        {vector3(0.08000183, 0.8400269, 0.5599976), 1.0, -90.0},
        {vector3(0.6500092, 2.490021, 0.5599976), 1.0, 0.0}
    }
}

POINTS_GABZ = {
    RIGHT = {
		{vector3(0, 0, 0), 6.0, 270.0},
		{vector3(0.1600342, 0, -0.2099991), 6.0, 270.0},
		{vector3(0.2999878, 0, -0.3500004), 6.0, 270.0},
		{vector3(0.460022, 0, -0.4599991), 6.0, 270.0},
        {vector3(0.7000122, 0, -0.5100002), 6.0, 270.0},
        {vector3(17.04004, 0.01000977, -0.4599991), 5.5, 270.0},
        {vector3(17.23004, 0.01000977, -0.4300003), 4.0, 270.0},
		{vector3(17.40002, 0.01000977, -0.2999992), 3.5, 270.0},
        {vector3(17.64001, 0.01000977, -0.07999992), 3.0, 270.0},
        {vector3(17.71002, 0.01000977, -0.02999878), 2.5, 270.0},
        {vector3(17.85004, 0.01000977, 0.04000092), 2.0, 270.0},
        {vector3(18.13, 0.01000977, 0.06999969), 1.5, 270.0},
        {vector3(18.39001, 0.01000977, 0.06999969), 1.0, 270.0},
        {vector3(18.85999, 0.01000977, 0.06999969), 1.0, 270.0},
    },
    LEFT = {
		{vector3(0, 0, 0), 6.0, 270.0},
		{vector3(0.1600342, 0, -0.2099991), 6.0, 270.0},
		{vector3(0.2999878, 0, -0.3500004), 6.0, 270.0},
		{vector3(0.460022, 0, -0.4599991), 6.0, 270.0},
        {vector3(0.7000122, 0, -0.5100002), 6.0, 270.0},
        {vector3(17.04004, 0.01000977, -0.4599991), 5.5, 270.0},
        {vector3(17.23004, 0.01000977, -0.4300003), 4.0, 270.0},
		{vector3(17.40002, 0.01000977, -0.2999992), 3.5, 270.0},
        {vector3(17.64001, 0.01000977, -0.07999992), 3.0, 270.0},
        {vector3(17.71002, 0.01000977, -0.02999878), 2.5, 270.0},
        {vector3(17.85004, 0.01000977, 0.04000092), 2.0, 270.0},
        {vector3(18.13, 0.01000977, 0.06999969), 1.5, 270.0},
        {vector3(18.39001, 0.01000977, 0.06999969), 1.0, 270.0},
        {vector3(18.85999, 0.01000977, 0.06999969), 1.0, 270.0},
    },
}

POINTS_MILO = {
    LEFT = {
		{vector3(0.000000, 0.000000, 0.000000),	3.0, 0.0},
		{vector3(0.109985, -0.179993, -0.059999), 1.0, 0.0},
		{vector3(0.289917, -0.000046, -0.059999), 1.0, 0.0}, 
		{vector3(1.250000, -1.200049, -0.059999), 1.0, 225.0}
    },
    RIGHT = {
		{vector3(0.000000, 0.000000, 0.000000),	3.0, 0.0},
		{vector3(0.109985, -0.179993, -0.059999), 1.0, 0.0},
		{vector3(-0.050049, -0.360046, -0.059999), 1.0, 0.0}, 
		{vector3(0.880005, -1.600039, -0.059999), 1.0, 225.0}
    }
}

POINTS_M4A = {
    LEFT = {
		{vector3(0.000000, 0.000000, 0.000000),	3.0, 0.0},
		{vector3(0.000000, 0.000000, 0.000000),	3.0, 0.0},
    },
    RIGHT = {
		{vector3(0.000000, 0.000000, 0.000000),	3.0, 0.0},
		{vector3(0.000000, 0.000000, 0.000000),	3.0, 0.0},
    }
}

POINTS_GND = {
    LEFT = {
		{vector3(0.000000, 0.000000, 0.000000),	1.0, 180.0},
		{vector3(0.000000, 0.000000, 0.000000),	1.0, 180.0},
    },
    RIGHT = {
		{vector3(0.000000, 0.000000, 0.000000),	1.0, 180.0},
		{vector3(0.000000, 0.000000, 0.000000),	1.0, 180.0},
    }
}

POINTS_K4MB1 = {
    RIGHT = {
		{vector3(0.0, 0.0, 0.0), 1.0, 45.0},
		{vector3(-0.6, 0.96, 0.04), 1.0, 45.0},
	},
	LEFT = {
		{vector3(0.0, 0.0, 0.0), 1.0, 45.0},
		{vector3(-0.6, 0.96, 0.04), 1.0, 45.0},
	}
}

Lanes = {
}

-- Burton should be the "Place" of the bowling alley you'd like to configure

-- LaneJob = {
-- 	['Burton'] = {
-- 		job = 'burtonbowling',
-- 		price = 1000,
-- 	},
-- 	['Del Perro'] = {
-- 		job = 'delperrobowling',
-- 		price = 1000,
-- 	},
-- }

if Config.EnabledMaps.K4MB1_BOWLING then
	local diff = vec3(-2.170044, -1.560059, 0.000000)
	Lanes.K4MB1_1 = {
		IsClosestToDoor = true,
		Place = 'Del Perro',
		Start = vector3(-1346.69, -643.22, 22.04),
		End = vector3(-1336.80, -658.45, 22.04),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.0,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_K4MB1,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1349.13, -641.9, 22.45) - vector3(-0.6, 0.96, 0.0),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.4,
		AngleOffset = 180.0,
	}
	Lanes.K4MB1_2 = {
		IsClosestToDoor = true,
		Place = 'Del Perro',
		Start = vector3(-1348.909, -644.7, 22.04),
		End = vector3(-1338.99, -659.98, 22.04),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.0,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_K4MB1,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1349.13, -641.9, 22.45) - vector3(-0.6, 0.96, 0.0),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.55,
		AngleOffset = 180.0,
	}
	Lanes.K4MB1_3 = {
		IsClosestToDoor = true,
		Place = 'Del Perro',
		Start = Lanes.K4MB1_2.Start + (Lanes.K4MB1_2.Start - Lanes.K4MB1_1.Start),
		End = Lanes.K4MB1_2.End + (Lanes.K4MB1_2.End - Lanes.K4MB1_1.End),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.0,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_K4MB1,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1353.57, -644.87, 22.45) - vector3(-0.6, 0.96, 0.0),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.55,
		AngleOffset = 180.0,
	}
	Lanes.K4MB1_4 = {
		IsClosestToDoor = true,
		Place = 'Del Perro',
		Start = Lanes.K4MB1_2.Start + (Lanes.K4MB1_2.Start - Lanes.K4MB1_1.Start) * 2,
		End = Lanes.K4MB1_2.End + (Lanes.K4MB1_2.End - Lanes.K4MB1_1.End) * 2,
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.0,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_K4MB1,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1353.57, -644.87, 22.45) - vector3(-0.6, 0.96, 0.0),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.55,
		AngleOffset = 180.0,
	}
	Lanes.K4MB1_5 = {
		IsClosestToDoor = true,
		Place = 'Del Perro',
		Start = Lanes.K4MB1_2.Start + (Lanes.K4MB1_2.Start - Lanes.K4MB1_1.Start) * 3,
		End = Lanes.K4MB1_2.End + (Lanes.K4MB1_2.End - Lanes.K4MB1_1.End) * 3,
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.0,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_K4MB1,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1358.04, -647.8, 22.45) - vector3(-0.6, 0.96, 0.0),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.55,
		AngleOffset = 180.0,
	}
	Lanes.K4MB1_6 = {
		IsClosestToDoor = true,
		Place = 'Del Perro',
		Start = Lanes.K4MB1_2.Start + (Lanes.K4MB1_2.Start - Lanes.K4MB1_1.Start) * 4,
		End = Lanes.K4MB1_2.End + (Lanes.K4MB1_2.End - Lanes.K4MB1_1.End) * 4,
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.05,
		PinDistance = 17.0,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_K4MB1,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1358.04, -647.8, 22.45) - vector3(-0.6, 0.96, 0.0),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.55,
		AngleOffset = 180.0,
	}
end

if Config.EnabledMaps.BREZE_BOWLING then
    Lanes.BREZE_1 = {
		Place = 'Burton',
		IsClosestToDoor = true,
		Start = vector3(-146.5671, -261.9492, 43.16),
		End = vector3(-152.9371, -280.0592 - 0.0148, 43.17),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_BREZE,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-147.37, -259.4, 43.2),
		BallPickupOffsetMultiplier = 0.6,
		BallPickupZOffset = 0.0,
	}

    Lanes.BREZE_2 = {
		Place = 'Burton',
		Start = vector3(-149.55, -260.9, 43.16),
		End = vector3(-155.92, -279.01 - 0.0148, 43.17),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_BREZE,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-147.37, -259.4, 43.2),
		BallPickupOffsetMultiplier = 0.6,
		BallPickupZOffset = 0.0,
	}

    Lanes.BREZE_3 = {
		Place = 'Burton',
		Start = vector3(-152.2102, -259.9643, 43.16),
		End = vector3(-158.5802, -278.0743 - 0.0148, 43.17),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_BREZE,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-153.02, -257.42, 43.2),
		BallPickupOffsetMultiplier = 0.6,
		BallPickupZOffset = 0.0,
	}
    
    Lanes.BREZE_4 = {
		Place = 'Burton',
		Start = vector3(-155.1931, -258.9151, 43.16),
		End = vector3(-161.5631, -277.0251 - 0.0148, 43.17),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_BREZE,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-153.02, -257.42, 43.2),
		BallPickupOffsetMultiplier = 0.6,
		BallPickupZOffset = 0.0,
	}

    Lanes.BREZE_5 = {
		Place = 'Burton',
		Start = vector3(-159.0136, -257.5713, 43.16),
		End = vector3(-165.3836, -275.6813 - 0.0148, 43.17),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_BREZE,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-159.81, -255.03, 43.19),
		BallPickupOffsetMultiplier = 0.6,
		BallPickupZOffset = 0.0,
	}
    
    Lanes.BREZE_6 = {
		Place = 'Burton',
		Start = vector3(-161.9965, -256.5221, 43.16),
		End = vector3(-168.3665, -274.6321 - 0.0148, 43.17),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_BREZE,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-159.81, -255.03, 43.19),
		BallPickupOffsetMultiplier = 0.6,
		BallPickupZOffset = 0.0,
	}
    
    Lanes.BREZE_7 = {
		Place = 'Burton',
		Start = vector3(-164.6483, -255.5894, 43.16),
		End = vector3(-171.0182, -273.6994 - 0.0148, 43.17),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_BREZE,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-165.44, -253.04, 43.19),
		BallPickupOffsetMultiplier = 0.6,
		BallPickupZOffset = 0.0,
	}
    
    Lanes.BREZE_8 = {
		Place = 'Burton',
		Start = vector3(-167.633, -254.5395, 43.16),
		End = vector3(-174.003, -272.6495 - 0.0148, 43.17),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_BREZE,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-165.44, -253.04, 43.19),
		BallPickupOffsetMultiplier = 0.6,
		BallPickupZOffset = 0.0,
	}
end

if Config.EnabledMaps.GABZ_BOWLING then
    Lanes.GABZ_1 = {
		Place = 'LMESA',
		IsClosestToDoor = true,
		Start = vector3(746.89, -781.84, 25.45),
		End = vector3(728.26, -781.84, 25.45),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GABZ,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(728.61, -780.8, 26.06),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
		LastRackBallPos = vector3(18.88999 + 0.075, 0.01000977, 0.06999969),
	}
    
    Lanes.GABZ_2 = {
		Place = 'LMESA',
		Start = vector3(746.89, -781.84 + 2.085, 25.45),
		End = vector3(728.26, -781.84 + 2.085, 25.45),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GABZ,
		SourceSide = 'LEFT',
		SourceRoot = vector3(728.61, -780.8, 26.06),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
		LastRackBallPos = vector3(18.88999 + 0.075, 0.01000977, 0.06999969),
	}
    
    Lanes.GABZ_3 = {
		Place = 'LMESA',
		Start = vector3(746.89, -781.84 + 2.087 * 2, 25.45),
		End = vector3(728.26, -781.84 + 2.087 * 2, 25.45),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GABZ,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(728.61, -780.8 + 4.17, 26.06),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
		LastRackBallPos = vector3(18.53599 + 0.075, 0.01000977, 0.06999969),
	}
    Lanes.GABZ_4 = {
		Place = 'LMESA',
		Start = vector3(746.89, -781.84 + 2.0875 * 3, 25.45),
		End = vector3(728.26, -781.84 + 2.0875 * 3, 25.45),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GABZ,
		SourceSide = 'LEFT',
		SourceRoot = vector3(728.61, -780.8 + 4.17, 26.06),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
		LastRackBallPos = vector3(18.53599 + 0.075, 0.01000977, 0.06999969),
	}
    
    Lanes.GABZ_5 = {
		Place = 'LMESA',
		Start = vector3(746.89, -781.84 + 2.0875 * 4, 25.45),
		End = vector3(728.26, -781.84 + 2.0875 * 4, 25.45),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GABZ,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(728.61, -780.8 + 4.17*2, 26.06),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
		LastRackBallPos = vector3(19.120999 + 0.075, 0.01000977, 0.06999969),
	}
    Lanes.GABZ_6 = {
		Place = 'LMESA',
		Start = vector3(746.89, -781.84 + 2.0875 * 5, 25.45),
		End = vector3(728.26, -781.84 + 2.0875 * 5, 25.45),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GABZ,
		SourceSide = 'LEFT',
		SourceRoot = vector3(728.61, -780.8 + 4.17*2, 26.06),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
		LastRackBallPos = vector3(19.120999 + 0.075, 0.01000977, 0.06999969),
	}
    Lanes.GABZ_7 = {
		Place = 'LMESA',
		Start = vector3(746.89, -781.84 + 2.0875 * 7, 25.45),
		End = vector3(728.26, -781.84 + 2.0875 * 7, 25.45),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GABZ,
		SourceSide = 'LEFT',
		SourceRoot = vector3(728.61, -780.8 + 4.175*3, 26.06),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
		LastRackBallPos = vector3(18.83199 + 0.075, 0.01000977, 0.06999969),
	}
end
    

if Config.EnabledMaps.YBN_MILO_RICHARDS_BOWLING then
    Lanes.MILO_1 = {
		Place = 'RICHARDS',
		IsClosestToDoor = true,
		Start = vector3(-1282.23, -675.63, 23.75),
		End = vector3(-1293.05, -661.75, 23.75),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_MILO,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1282.7, -677.98, 24.42),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
	}
    Lanes.MILO_2 = {
		Place = 'RICHARDS',
		Start = vector3(-1279.74, -673.68, 23.74),
		End = vector3(-1290.64, -659.7, 23.74),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_MILO,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1277.94, -673.63, 24.42),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
	}
    Lanes.MILO_3 = {
		Place = 'RICHARDS',
		Start = vector3(-1277.53, -671.94, 23.75),
		End = vector3(-1288.42, -657.97, 23.75),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_MILO,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1277.94, -673.63, 24.42),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
	}
    Lanes.MILO_4 = {
		Place = 'RICHARDS',
		Start = vector3(-1275.04, -669.99, 23.75),
		End = vector3(-1285.81, -656.17, 23.75),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_MILO,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1272.66, -669.5, 24.42),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
	}
    Lanes.MILO_5 = {
		Place = 'RICHARDS',
		Start = vector3(-1271.85, -667.51, 23.75),
		End = vector3(-1282.66, -653.62, 23.75),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_MILO,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1272.66, -669.5, 24.42),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
	}
    Lanes.MILO_6 = {
		Place = 'RICHARDS',
		Start = vector3(-1269.35, -665.56, 23.75),
		End = vector3(-1280.19, -651.64, 23.75),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_MILO,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1267.53, -665.52, 24.42),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
	}
    Lanes.MILO_7 = {
		Place = 'RICHARDS',
		Start = vector3(-1267.14, -663.81, 23.75),
		End = vector3(-1277.99, -649.9, 23.75),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_MILO,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1267.53, -665.52, 24.42),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
	}
end


if Config.EnabledMaps.MAP4ALL_BOWLING then
    Lanes.M4A_1 = {
		Place = 'DELPERRO',
		IsClosestToDoor = true,
		Start = vector3(-1661.19, -1067.15, 12.07),
		End = vector3(-1649.39, -1077.05, 12.06),
		Width = 0.643,
		GutterWidth = 0.85,
		GutterDepth = 0.1,
		PinDistance = 13.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1663.7, -1066.49, 12.59),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
		AngleOffset = 180.0,
	}

    Lanes.M4A_2 = {
		Place = 'DELPERRO',
		Start = vector3(-1662.87, -1069.13, 12.07),
		End = vector3(-1651.09, -1079.0, 12.06),
		Width = 0.643,
		GutterWidth = 0.85,
		GutterDepth = 0.1,
		PinDistance = 13.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1663.97, -1066.77, 12.51),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
		AngleOffset = 180.0,
	}

    Lanes.M4A_3 = {
		Place = 'DELPERRO',
		Start = vector3(-1664.22, -1070.72, 12.07),
		End = vector3(-1652.45, -1080.6, 12.06),
		Width = 0.643,
		GutterWidth = 0.85,
		GutterDepth = 0.1,
		PinDistance = 13.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1666.84, -1069.97, 12.51),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
		AngleOffset = 180.0,
	}

    Lanes.M4A_4 = {
		Place = 'DELPERRO',
		Start = vector3(-1665.87, -1072.72, 12.07),
		End = vector3(-1654.14, -1082.57, 12.06),
		Width = 0.643,
		GutterWidth = 0.85,
		GutterDepth = 0.1,
		PinDistance = 13.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1666.89, -1070.4, 12.51),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.6,
		AngleOffset = 180.0,
	}
end
	

if Config.EnabledMaps.GND_BOWLING then
    Lanes.GND_1 = {
		Place = 'DTV',
		Start = vector3(299.39, 236.29, 103.32),
		End = vector3(299.39, 236.29, 103.32) + vec3(6.690002, 18.380005, 0.000000),
		Width = 1.15,
		GutterWidth = 1.3,
		GutterDepth = 0.1,
		PinDistance = 17.5,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GND,
		SourceSide = 'LEFT',
		SourceRoot = vector3(301.32, 236.05, 103.67),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.3,
		AngleOffset = 180.0,
	}
	
    Lanes.GND_2 = {
		Place = 'DTV',
		Start = vector3(302.955, 235.02, 103.32),
		End = vector3(302.955, 235.02, 103.32) + vec3(6.690002, 18.380005, 0.000000),
		Width = 1.15,
		GutterWidth = 1.3,
		GutterDepth = 0.1,
		PinDistance = 17.5,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GND,
		SourceSide = 'LEFT',
		SourceRoot = vector3(304.85, 234.73, 103.67),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.3,
		AngleOffset = 180.0,
	}

    Lanes.GND_3 = {
		Place = 'DTV',
		Start = vector3(302.955, 235.02, 103.32) + vec3(3.514984, -1.269989, 0.000000) * 1.013,
		End = vector3(302.955, 235.02, 103.32) + vec3(3.514984, -1.269989, 0.000000) * 1.013 + vec3(6.690002, 18.380005, 0.000000),
		Width = 1.15,
		GutterWidth = 1.3,
		GutterDepth = 0.1,
		PinDistance = 17.5,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GND,
		SourceSide = 'LEFT',
		SourceRoot = vector3(308.4, 233.35, 103.67),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.3,
		AngleOffset = 180.0,
	}

    Lanes.GND_4 = {
		Place = 'DTV',
		IsClosestToDoor = true,
		Start = vector3(302.955, 235.02, 103.32) + vec3(3.514984, -1.269989, 0.000000) * 2.026,
		End = vector3(302.955, 235.02, 103.32) + vec3(3.514984, -1.269989, 0.000000) * 2.026 + vec3(6.690002, 18.380005, 0.000000),
		Width = 1.15,
		GutterWidth = 1.3,
		GutterDepth = 0.1,
		PinDistance = 17.5,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GND,
		SourceSide = 'LEFT',
		SourceRoot = vector3(311.97, 232.1, 103.67),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.3,
		AngleOffset = 180.0,
	}

    Lanes.GND_5 = {
		Place = 'DTV',
		Start = vector3(302.955, 235.02, 103.32) + vec3(3.514984, -1.269989, 0.000000) * 3.039,
		End = vector3(302.955, 235.02, 103.32) + vec3(3.514984, -1.269989, 0.000000) * 3.039 + vec3(6.690002, 18.380005, 0.000000),
		Width = 1.15,
		GutterWidth = 1.3,
		GutterDepth = 0.1,
		PinDistance = 17.5,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GND,
		SourceSide = 'LEFT',
		SourceRoot = vector3(315.53, 230.84, 103.67),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.3,
		AngleOffset = 180.0,
	}

    Lanes.GND_6 = {
		Place = 'DTV',
		Start = vector3(302.955, 235.02, 103.32) + vec3(3.514984, -1.269989, 0.000000) * 4.05200,
		End = vector3(302.955, 235.02, 103.32) + vec3(3.514984, -1.269989, 0.000000) * 4.05200 + vec3(6.690002, 18.380005, 0.000000),
		Width = 1.15,
		GutterWidth = 1.3,
		GutterDepth = 0.1,
		PinDistance = 17.5,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GND,
		SourceSide = 'LEFT',
		SourceRoot = vector3(319.08, 229.56, 103.67),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.3,
		AngleOffset = 180.0,
	}

    Lanes.GND_7 = {
		Place = 'DTV',
		Start = vector3(302.955, 235.02, 103.32) + vec3(3.514984, -1.269989, 0.000000) * 5.06500,
		End = vector3(302.955, 235.02, 103.32) + vec3(3.514984, -1.269989, 0.000000) * 5.06500 + vec3(6.690002, 18.380005, 0.000000),
		Width = 1.15,
		GutterWidth = 1.3,
		GutterDepth = 0.1,
		PinDistance = 17.5,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GND,
		SourceSide = 'LEFT',
		SourceRoot = vector3(322.61, 228.15, 103.67),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.3,
		AngleOffset = 180.0,
	}

    Lanes.GND_8 = {
		Place = 'DTV',
		Start = vector3(302.955, 235.02, 103.32) + vec3(3.514984, -1.269989, 0.000000) * 6.07800,
		End = vector3(302.955, 235.02, 103.32) + vec3(3.514984, -1.269989, 0.000000) * 6.07800 + vec3(6.690002, 18.380005, 0.000000),
		Width = 1.15,
		GutterWidth = 1.3,
		GutterDepth = 0.1,
		PinDistance = 17.5,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_GND,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(322.61, 228.15, 103.67),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.3,
		AngleOffset = 180.0,
	}
end

if Config.EnabledMaps.YBN_MILO_SANDY_SHORES then
    Lanes.MILO_SANDY_1 = {
		IsClosestToDoor = true,
		Place = 'Sandy Shores',
		Start = vector3(2712.85, 3473.66, 56.62),
		End = vector3(2705.99, 3457.5599999999, 56.6),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(2711.81, 3475.15, 57.25),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.7,
	}
    Lanes.MILO_SANDY_2 = {
		Place = 'Sandy Shores',
		Start = vector3(2709.94, 3474.87, 56.64),
		End = vector3(2703.12, 3458.89, 56.61),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(2711.43, 3475.39, 57.25),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.7,
	}
    Lanes.MILO_SANDY_3 = {
		Place = 'Sandy Shores',
		Start = vector3(2707.33, 3475.96, 56.62),
		End = vector3(2700.5, 3459.94, 56.61),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(2706.63, 3477.69, 57.25),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.7,
	}
    Lanes.MILO_SANDY_4 = {
		Place = 'Sandy Shores',
		Start = vector3(2704.41, 3477.21, 56.62),
		End = vector3(2697.59, 3461.18, 56.6),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(2706.19, 3477.75, 57.25),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.7,
	}
    Lanes.MILO_SANDY_5 = {
		Place = 'Sandy Shores',
		Start = vector3(2700.69, 3478.77, 56.62),
		End = vector3(2693.86, 3462.75, 56.6),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(2699.84, 3480.69, 57.25),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.7,
	}
    Lanes.MILO_SANDY_6 = {
		Place = 'Sandy Shores',
		Start = vector3(2697.77, 3480.03, 56.6),
		End = vector3(2690.94, 3463.98, 56.6),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(2699.41, 3480.82, 57.25),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.7,
	}
    Lanes.MILO_SANDY_7 = {
		Place = 'Sandy Shores',
		Start = vector3(2695.18, 3481.11, 56.61),
		End = vector3(2688.37, 3465.09, 56.61),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 16.1,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(2694.44, 3482.93, 57.25),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.7,
	}
end


if Config.EnabledMaps.TLUX_BOWLING then
    Lanes.TLUX_1 = {
		IsClosestToDoor = true,
		Place = 'Vespucci Canals',
		Start = vector3(-1197.25, -1311.81, -1.94),
		End = vector3(-1202.7, -1299.99, -1.95),
		Width = 0.93,
		GutterWidth = 1.05,
		GutterDepth = 0.05,
		PinDistance = 11.0,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1194.98, -1313.77, -1.45),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.7,
	}

    Lanes.TLUX_2 = {
		IsClosestToDoor = true,
		Place = 'Vespucci Canals',
		Start = vector3(-1194.72, -1310.63, -1.96),
		End = vector3(-1200.25, -1298.67, -1.95),
		Width = 0.93,
		GutterWidth = 1.05,
		GutterDepth = 0.05,
		PinDistance = 11.0,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1194.98, -1313.77, -1.45),
		BallPickupOffsetMultiplier = -0.8,
		BallPickupZOffset = -0.7,
	}

    Lanes.TLUX_3 = {
		IsClosestToDoor = true,
		Place = 'Vespucci Canals',
		Start = vector3(-1192.25, -1309.39, -1.96),
		End = vector3(-1197.7, -1297.52, -1.95),
		Width = 0.93,
		GutterWidth = 1.05,
		GutterDepth = 0.05,
		PinDistance = 11.0,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1189.8, -1311.62, -1.5),
		BallPickupOffsetMultiplier = -0.6,
		BallPickupZOffset = -0.7,
	}

    Lanes.TLUX_4 = {
		IsClosestToDoor = true,
		Place = 'Vespucci Canals',
		Start = vector3(-1189.7, -1308.17, -1.94),
		End = vector3(-1195.2, -1296.29, -1.95),
		Width = 0.93,
		GutterWidth = 1.05,
		GutterDepth = 0.05,
		PinDistance = 11.0,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1189.8, -1311.62, -1.5),
		BallPickupOffsetMultiplier = -0.8,
		BallPickupZOffset = -0.7,
	}
end

if Config.EnabledMaps.DESERT_MANSION then
    Lanes.DESERT_MANSION_1 = {
		IsClosestToDoor = true,
		Place = 'Desert Mansion',
		Start = vector3(766.12, 3429.1, 50.44),
		End = vector3(766.13, 3439.94, 50.45),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 10.0,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(767.5, 3426.27, 51.05),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}
	
    Lanes.DESERT_MANSION_2 = {
		IsClosestToDoor = false,
		Place = 'Desert Mansion',
		Start = vector3(769.28, 3429.1, 50.44),
		End = vector3(769.281, 3439.94, 50.45),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 10.0,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(767.93, 3425.98, 51.05),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}
	
    Lanes.DESERT_MANSION_3 = {
		IsClosestToDoor = false,
		Place = 'Desert Mansion',
		Start = vector3(772.1, 3429.1, 50.44),
		End = vector3(772.11, 3439.94, 50.45),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 10.0,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(773.48, 3426.18, 51.05),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}
end

if Config.EnabledMaps.MARC_BOWL then
    Lanes.MARC_BOWL_1 = {
		IsClosestToDoor = true,
		Place = 'Marc Bowl',
		Start = vector3(-1178.23, -1639.67, 4.84),
		End = vector3(-1193.66, -1650.5, 4.84),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.8,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1176.45, -1636.82, 5.49),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}
	
    Lanes.MARC_BOWL_2 = {
		IsClosestToDoor = false,
		Place = 'Marc Bowl',
		Start = vector3(-1180.06, -1637.14, 4.84),
		End = vector3(-1195.59, -1647.9, 4.84),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.8,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1176.45, -1636.16, 5.49),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}
	
    Lanes.MARC_BOWL_3 = {
		IsClosestToDoor = false,
		Place = 'Marc Bowl',
		Start = vector3(-1181.67, -1634.68, 4.84),
		End = vector3(-1197.29, -1645.64, 4.84),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.8,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1179.85, -1631.89, 5.49),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}

	Lanes.MARC_BOWL_4 = {
		IsClosestToDoor = false,
		Place = 'Marc Bowl',
		Start = vector3(-1183.55, -1632.13, 4.84),
		End = vector3(-1199.16, -1643.11, 4.84),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.8,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1179.85, -1631.37, 5.49),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}

	Lanes.MARC_BOWL_5 = {
		IsClosestToDoor = false,
		Place = 'Marc Bowl',
		Start = vector3(-1185.83, -1628.87, 4.84),
		End = vector3(-1201.47, -1639.79, 4.84),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.8,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1183.47, -1625.61, 5.49),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}

	Lanes.MARC_BOWL_6 = {
		IsClosestToDoor = false,
		Place = 'Marc Bowl',
		Start = vector3(-1187.69, -1626.29, 4.84),
		End = vector3(-1203.21, -1637.18, 4.84),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.8,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1184.05, -1625.43, 5.49),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}

	Lanes.MARC_BOWL_7 = {
		IsClosestToDoor = false,
		Place = 'Marc Bowl',
		Start = vector3(-1189.29, -1623.99, 4.84),
		End = vector3(-1204.85, -1634.91, 4.84),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.8,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-1187.17, -1620.94, 5.49),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}

	Lanes.MARC_BOWL_8 = {
		IsClosestToDoor = false,
		Place = 'Marc Bowl',
		Start = vector3(-1191.05, -1621.37, 4.84),
		End = vector3(-1206.77, -1632.35, 4.84),
		Width = 0.624,
		GutterWidth = 0.75,
		GutterDepth = 0.05,
		PinDistance = 17.8,
		PinSideSpace = 0.34,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-1187.17, -1620.24, 5.49),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}
end

if Config.EnabledMaps.AEGON_BOWLING then
    Lanes.AEGON_1 = {
		IsClosestToDoor = true,
		Place = 'VW Race Track',
		Start = vector3(1023.62, 152.11, 80.11),
		End = vector3(1032.5, 166.78, 80.14),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(1022.88, 148.24, 80.6),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.AEGON_2 = {
		IsClosestToDoor = false,
		Place = 'VW Race Track',
		Start = vector3(1026.34, 150.5, 80.12),
		End = vector3(1034.96, 164.74, 80.12),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(1023.28, 148.1, 80.6),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.AEGON_3 = {
		IsClosestToDoor = false,
		Place = 'VW Race Track',
		Start = vector3(1028.74, 149.04, 80.11),
		End = vector3(1037.45, 163.43, 80.11),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(1028.04, 145.17, 80.61),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.AEGON_4 = {
		IsClosestToDoor = false,
		Place = 'VW Race Track',
		Start = vector3(1031.43, 147.4, 80.11),
		End = vector3(1040.03, 161.6, 80.13),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(1028.15, 144.69, 80.61),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.AEGON_5 = {
		IsClosestToDoor = false,
		Place = 'VW Race Track',
		Start = vector3(1034.89, 145.32, 80.12),
		End = vector3(1043.53, 159.59, 80.11),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(1034.21, 141.48, 80.609),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.AEGON_6 = {
		IsClosestToDoor = false,
		Place = 'VW Race Track',
		Start = vector3(1037.59, 143.68, 80.11),
		End = vector3(1046.32, 158.11, 80.12),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(1034.45, 141.17, 80.609),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.AEGON_7 = {
		IsClosestToDoor = false,
		Place = 'VW Race Track',
		Start = vector3(1039.99, 142.24, 80.12),
		End = vector3(1048.67, 156.58, 80.11),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(1039.1, 138.08, 80.609),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}
    Lanes.AEGON_8 = {
		IsClosestToDoor = false,
		Place = 'VW Race Track',
		Start = vector3(1042.7, 140.61, 80.12),
		End = vector3(1051.61, 155.34, 80.11),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 17.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(1039.52, 138.08, 80.609),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}
end

if Config.EnabledMaps.YBN_ROCKFORD_MALL then
    Lanes.YBN_ROCKFORD_MALL_1 = {
		IsClosestToDoor = true,
		Place = 'Rockford Mall',
		Start = vector3(-130.54, -158.28, 42.73),
		End = vector3(-124.64, -141.87, 42.72),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-132.98, -160.26, 43.36),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.YBN_ROCKFORD_MALL_2 = {
		IsClosestToDoor = false,
		Place = 'Rockford Mall',
		Start = vector3(-127.57, -159.37, 42.72),
		End = vector3(-121.66, -142.94, 42.72),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-127.09, -161.69, 43.36),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.YBN_ROCKFORD_MALL_3 = {
		IsClosestToDoor = false,
		Place = 'Rockford Mall',
		Start = vector3(-124.95, -160.42, 42.72),
		End = vector3(-118.96, -143.75, 42.72),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-126.72, -161.85, 43.36),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.YBN_ROCKFORD_MALL_4 = {
		IsClosestToDoor = false,
		Place = 'Rockford Mall',
		Start = vector3(-122.0, -161.54, 42.88),
		End = vector3(-115.98, -144.83, 42.71),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-120.78, -163.88, 43.36),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.YBN_ROCKFORD_MALL_5 = {
		IsClosestToDoor = false,
		Place = 'Rockford Mall',
		Start = vector3(-118.16, -162.84, 42.71),
		End = vector3(-112.25, -146.41, 42.72),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-120.48, -164.22, 43.36),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.YBN_ROCKFORD_MALL_6 = {
		IsClosestToDoor = false,
		Place = 'Rockford Mall',
		Start = vector3(-115.17, -163.87, 42.71),
		End = vector3(-109.19, -147.26, 42.72),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-114.63, -166.1, 43.36),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.YBN_ROCKFORD_MALL_7 = {
		IsClosestToDoor = false,
		Place = 'Rockford Mall',
		Start = vector3(-112.54, -164.87, 42.71),
		End = vector3(-106.51, -148.11, 42.72),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-114.32, -166.42, 43.36),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}
end


if Config.EnabledMaps.VIHHS_WONDERAMA then
	
	


    Lanes.VIHHS_SOUTH_1 = {
		IsClosestToDoor = true,
		Place = 'Vihhs South',
		Start = vector3(-175.09, -228.53, 37.2),
		End = vector3(-191.17, -222.83, 37.2),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-170.54, -228.67, 37.72),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}

	
    Lanes.VIHHS_SOUTH_2 = {
		IsClosestToDoor = false,
		Place = 'Vihhs South',
		Start = vector3(-174.03, -225.55, 37.2),
		End = vector3(-190.14, -219.84, 37.21),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-170.54, -228.23, 37.7),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}

    Lanes.VIHHS_SOUTH_3 = {
		IsClosestToDoor = false,
		Place = 'Vihhs South',
		Start = vector3(-173.12, -222.89, 37.21),
		End = vector3(-189.29, -217.16, 37.21),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-168.57, -223.01000000001, 37.76),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}
	
	
    Lanes.VIHHS_SOUTH_4 = {
		IsClosestToDoor = false,
		Place = 'Vihhs South',
		Start = vector3(-172.16, -219.87, 37.2),
		End = vector3(-188.41, -214.12, 37.2),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-168.43, -222.62000000001, 37.75),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}
	
    Lanes.VIHHS_SOUTH_5 = {
		IsClosestToDoor = false,
		Place = 'Vihhs South',
		Start = vector3(-170.92, -216.02, 37.21),
		End = vector3(-186.6, -210.46, 37.2),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-166.05, -216.27000000002, 37.75),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}
	
    Lanes.VIHHS_SOUTH_6 = {
		IsClosestToDoor = false,
		Place = 'Vihhs South',
		Start = vector3(-169.87, -213.04, 37.22),
		End = vector3(-185.87, -207.36, 37.22),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-165.9, -215.88000000002, 37.75),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}

    Lanes.VIHHS_SOUTH_7 = {
		IsClosestToDoor = false,
		Place = 'Vihhs South',
		Start = vector3(-168.83, -210.42, 37.22),
		End = vector3(-184.93, -204.71, 37.2),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(-164.05, -210.66000000003, 37.75),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}
	
    Lanes.VIHHS_SOUTH_8 = {
		IsClosestToDoor = false,
		Place = 'Vihhs South',
		Start = vector3(-167.66, -207.48, 37.21),
		End = vector3(-183.83, -201.74, 37.21),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(-163.88, -210.27000000003, 37.75),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 0.0,
	}
	

	----------------------

	

    Lanes.VIHHS_NORTH_1 = {
		IsClosestToDoor = true,
		Place = 'Vihhs North',
		Start = vector3(1736.46, 4758.45, 35.09),
		End = vector3(1753.62, 4758.12, 35.09),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(1731.91, 4757.17, 35.7),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.VIHHS_NORTH_2 = {
		IsClosestToDoor = false,
		Place = 'Vihhs North',
		Start = vector3(1736.5, 4755.29, 35.11),
		End = vector3(1754.03, 4754.95, 35.09),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(1731.91, 4756.72, 35.7),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}
	

    Lanes.VIHHS_NORTH_3 = {
		IsClosestToDoor = false,
		Place = 'Vihhs North',
		Start = vector3(1736.55, 4752.47, 35.1),
		End = vector3(1753.55, 4752.14, 35.1),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(1731.91, 4751.1799999999, 35.7),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}
	
    Lanes.VIHHS_NORTH_4 = {
		IsClosestToDoor = false,
		Place = 'Vihhs North',
		Start = vector3(1736.34, 4749.32, 35.09),
		End = vector3(1753.43, 4748.98, 35.1),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(1731.91, 4750.7299999999, 35.7),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}
	
    Lanes.VIHHS_NORTH_5 = {
		IsClosestToDoor = false,
		Place = 'Vihhs North',
		Start = vector3(1736.23, 4745.26, 35.12),
		End = vector3(1753.59, 4744.93, 35.11),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(1731.91, 4743.9799999998, 35.7),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.VIHHS_NORTH_6 = {
		IsClosestToDoor = false,
		Place = 'Vihhs North',
		Start = vector3(1736.3, 4742.1, 35.1),
		End = vector3(1753.29, 4741.77, 35.09),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(1731.91, 4743.5099999998, 35.7),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.VIHHS_NORTH_7 = {
		IsClosestToDoor = false,
		Place = 'Vihhs North',
		Start = vector3(1736.24, 4739.29, 35.1),
		End = vector3(1753.15, 4738.96, 35.1),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'LEFT',
		SourceRoot = vector3(1731.91, 4737.9999999997, 35.7),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}

    Lanes.VIHHS_NORTH_8 = {
		IsClosestToDoor = false,
		Place = 'Vihhs North',
		Start = vector3(1736.26, 4736.13, 35.09),
		End = vector3(1753.82, 4735.79, 35.1),
		Width = 0.64,
		GutterWidth = 0.8,
		GutterDepth = 0.17,
		PinDistance = 16.5,
		PinSideSpace = 0.375,
		SourcePoints = POINTS_M4A,
		SourceSide = 'RIGHT',
		SourceRoot = vector3(1731.91, 4737.5499999997, 35.7),
		BallPickupOffsetMultiplier = -0.9,
		BallPickupZOffset = -0.7,
		AngleOffset = 180.0,
	}
	
end