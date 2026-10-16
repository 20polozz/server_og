local pedMugshot

local function GetPedMugshot(ped, transparent)
    if DoesEntityExist(ped) then
		local mugshot
		
		if transparent then
			mugshot = RegisterPedheadshotTransparent(ped)
		else
			mugshot = RegisterPedheadshot(ped)
		end

        local timer = 2000
        while ((not mugshot or not IsPedheadshotReady(mugshot) or not IsPedheadshotValid(mugshot)) and timer > 0) do
            Citizen.Wait(10)
            timer = timer - 10
        end

		return mugshot, GetPedheadshotTxdString(mugshot)
	else
		return false
	end
end

function UpdateMugShot(source, transparent, clearface)
    local ped = source and (IsEntityAPed(source) and source or GetPlayerPed(GetPlayerFromServerId(source))) or PlayerPedId()
	local newMugshot, txd = GetPedMugshot(ped, transparent)

    if IsPedheadshotValid(pedMugshot) then
        UnregisterPedheadshot(pedMugshot)
    end

    pedMugshot = newMugshot

    if newMugshot and txd then
        return "https://nui-img/"..txd.."/"..txd
    else
        return false
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        UnregisterPedheadshot(pedMugshot)
    end
end)