local Config = {}

Config.debug = false

Config.useOxInventory = GetResourceState('ox_inventory') == 'started'
Config.useOrigenInventory = GetResourceState('origen_inventory') == 'started'
Config.useOrigenPolicePoints = true -- true: Garages, vestuarios, bossmenu, armerias/alijos y tiendas los gestiona origen_police

Config.clothingScript = 'origen_clothing' -- 'origen_clothing', 'illenium-appearance', 'fivem-appearance', 'core' or false
Config.emsJobs = { "ambulance" }
Config.respawnTime = 0                        -- in minutes
Config.waitTimeForNewCall = 1                 -- minutes (cooldown para volver a pedir auxilio con E)

Config.reviveCommand = "revive"
Config.reviveAreaCommand = "revivearea"
Config.healCommand = "heal"
Config.healAreaCommand = "healarea"
Config.reviveAllCommand = "reviveall"

Config.adminGroup = "group.admin"

Config.medicBagProp = "xm_prop_x17_bag_med_01a"
Config.medicBagItem = "medicalbag"

Config.helpCommand = false -- El comando /auxilio lo gestiona origen_police con argumentos (como /entorno)
Config.removeItemsOnRespawn = true
Config.keepItemsOnRespawn = {} -- items that will not be removed when respawned

-- Las camillas y coordenadas de reaparición de cada hospital se configuran en data/hospitals.lua (sección respawn)
-- Cada camilla requiere bedPoint (vector4 posición en camilla) y spawnPoint (vector4 posición al levantarse)

Config.baseInjuryReward = 150
Config.reviveReward = 700

Config.paramedicTreatmentPrice = 4000
Config.shouldRevive = false
Config.allowAlways = true             -- false if you want it to work only when there are no medics online

Config.ambulanceStretchers = 2        -- how many stretchers should an ambulance have
Config.stretcherDefaultKey = 'K'      -- Tecla por defecto para sacar/recoger camilla médica (cada jugador puede cambiarla en Ajustes -> Asignación de teclas -> FiveM)
Config.consumeItemPerUse = 10         -- every time you use an item it gets used by 10%

Config.timeToWaitForCommand = 2       -- when player dies he needs to wait 2 minutes to do the ambulance command
Config.npcReviveCommand = "ambulance" -- this will work only when there are no medics online

Config.usePedToDepositVehicle = false -- if false the vehicle instantly despawns
Config.extraEffects = false           -- false >> disables screen shake and black and white screen

Config.emsVehicles = {                -- vehicles that have access to stretcher/props
	ambulance = true,
	ambulance2 = true,
}

Config.animations = {
	["death_car"] = {
		dict = "veh@low@front_ps@idle_duck",
		clip = "sit"
	},
	["death_normal"] = {
		dict = "dead",
		clip = "dead_a"
	},
	["get_up"] = {
		dict = "get_up@directional@movement@from_knees@action",
		clip = "getup_r_0"
	}
}

function Config.sendDistressCall(msg)
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	local miId = GetPlayerServerId(PlayerId())

	-- Origen Police / SAMS Dispatch Alert
	-- La id va en `metadata`: el HUD de avisos de origen_police pinta cada
	-- valor como una etiqueta, y asi el sanitario sabe a quien escribir.
	TriggerServerEvent("SendAlert:police", {
		coords = coords,
		title = "Aviso Médico 911",
		message = msg or "Ciudadano inconsciente requiere asistencia médica urgente",
		job = "ambulance",
		type = "ambulance",
		playerID = miId,
		metadata = { name = ("ID %d"):format(miId) },
		ignoreCooldown = true,
	})
end

function Config.giveVehicleKeys(vehicle, plate)
	if GetResourceState('qbx_vehiclekeys') == 'started' then
		exports.qbx_vehiclekeys:GiveKeys(plate)
	elseif GetResourceState('qb-vehiclekeys') == 'started' then
		TriggerEvent("vehiclekeys:client:SetOwner", plate)
	end
end

function Config.removeVehicleKeys(vehicle, plate)
	if GetResourceState('qbx_vehiclekeys') == 'started' then
		exports.qbx_vehiclekeys:RemoveKeys(plate)
	end
end

return Config
