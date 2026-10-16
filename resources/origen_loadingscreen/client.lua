RegisterNUICallback('remove', function(data, cb)
	
	--ShutdownLoadingScreenNui()
end)
 

RegisterNetEvent("origen_titlemenu:client:OnPlayerJoined", function()
	-- SendNUIMessage({
	-- 	action = "terminar"
	-- })
	Wait(1100)
	ShutdownLoadingScreen()
	ShutdownLoadingScreenNui()
end)