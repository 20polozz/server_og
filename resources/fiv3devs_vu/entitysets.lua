local vu_vanilla = GetInteriorAtCoords(113.652557, -1300.96277, 37.40684)

	-- change this:
	
	-- 1 = normal bed, red light
	-- 2 = prison roleplay
	-- 3 = bdsm
	-- 4 = hospital roleplay
	-- example: vu_red4 enabled means that in the "red" room entityset "hospital" will be enabled
	
	-- "red" room
	EnableInteriorProp(vu_vanilla, "vu_red1")
	DisableInteriorProp(vu_vanilla, "vu_red2")
	DisableInteriorProp(vu_vanilla, "vu_red3")
	DisableInteriorProp(vu_vanilla, "vu_red4")
	
	-- "pink" room
	DisableInteriorProp(vu_vanilla, "vu_pink1")
	EnableInteriorProp(vu_vanilla, "vu_pink2")
	DisableInteriorProp(vu_vanilla, "vu_pink3")
	DisableInteriorProp(vu_vanilla, "vu_pink4")
	
	-- "purple" room
	DisableInteriorProp(vu_vanilla, "vu_purple1")
	DisableInteriorProp(vu_vanilla, "vu_purple2")
	EnableInteriorProp(vu_vanilla, "vu_purple3")
	DisableInteriorProp(vu_vanilla, "vu_purple4")
	
	-- "blue" room
	DisableInteriorProp(vu_vanilla, "vu_blue1")
	DisableInteriorProp(vu_vanilla, "vu_blue2")
	DisableInteriorProp(vu_vanilla, "vu_blue3")
	EnableInteriorProp(vu_vanilla, "vu_blue4")
	
	-- EnableInteriorProp means an entityset is ENABLED
	-- DisableInteriorProp means an entityset is DISABLED
	-- Only ONE entityset per room should be enabled at one time, rooms are named after colors: red, pink, purple, blue
	
RefreshInterior(vu_vanilla)	

-- Disable vanilla VU audio (static emitters + ambient zones, applied once)
Citizen.CreateThread(function()
	while not NetworkIsSessionStarted() do
		Wait(100)
	end
	Wait(2000)

	SetStaticEmitterEnabled("hash_07cbbcd9_ozdsrp_collision", false)
	SetStaticEmitterEnabled("hash_51346d54_ldguwpi_collision", false)
	SetStaticEmitterEnabled("LOS_SANTOS_VANILLA_UNICORN_01_STAGE", false)
	SetStaticEmitterEnabled("LOS_SANTOS_VANILLA_UNICORN_02_MAIN_ROOM", false)
	SetStaticEmitterEnabled("LOS_SANTOS_VANILLA_UNICORN_03_BACK_ROOM", false)
	SetAmbientZoneStatePersistent("AZ_strp3stge_SP", false, false)
	SetAmbientZoneStatePersistent("iz_strp3bkpss", false, false)
end)

-- Toggle audio scene + barks only when player is inside the VU interior (ENABLE FOR ABSOLUTE SILENCE)

--Citizen.CreateThread(function()
--	local insideVU = false
--	while true do
--		Wait(500)
--		local interior = GetInteriorFromEntity(PlayerPedId())
--		local isInside = interior == vu_vanilla and vu_vanilla ~= 0
--
--		if isInside and not insideVU then
--			StartAudioScene("MP_LEADERBOARD_SCENE")
--			SetAudioFlag("DisableBarks", true)
--			insideVU = true
--		elseif not isInside and insideVU then
--			StopAudioScene("MP_LEADERBOARD_SCENE")
--			SetAudioFlag("DisableBarks", false)
--			insideVU = false
--		end
--	end
--end)