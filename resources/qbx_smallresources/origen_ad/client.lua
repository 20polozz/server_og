local BlacklistedModels = {
    [`prop_traffic_01a`] = true,
    [`prop_traffic_01b`] = true,
    [`prop_traffic_01d`] = true,
    [`prop_traffic_02a`] = true,
    [`prop_traffic_02b`] = true,
    [`prop_traffic_03a`] = true,
    [`prop_traffic_03b`] = true,
    [`prop_traffic_lightset_01`] = true,
    [`prop_streetlight_01`] = true,
    [`prop_streetlight_01b`] = true,
    [`prop_streetlight_02`] = true,
    [`prop_streetlight_03`] = true,
    [`prop_streetlight_03b`] = true,
    [`prop_streetlight_03c`] = true,
    [`prop_streetlight_03d`] = true,
    [`prop_streetlight_04`] = true,
    [`prop_streetlight_05`] = true,
    [`prop_streetlight_05_b`] = true,
    [`prop_streetlight_14a`] = true,
    [`prop_sign_road_05a`] = true,
    [`prop_sign_road_03e`] = true,
    [`prop_news_disp_01a`] = true,
    [`prop_news_disp_02a`] = true,
    [`prop_news_disp_03a`] = true,
    [`prop_postbox_01a`] = true,
}

local isRunning = false
local threadStarted = false

CreateThread(function()
    threadStarted = true

    while true do
        if not isRunning then
            Wait(1000)
        else
            --[[ Antes: lib.getNearbyObjects, que saca coordenadas y monta una
                 tabla por CADA objeto cargado para luego descartar casi todos.
                 Una vez por segundo en coche, y cada vez un tiron de hasta
                 1,5 ms (perfil del 16/09). Ahora se mira primero el modelo —una
                 native y una busqueda en la tabla— y la distancia solo de los
                 que estan en la lista. ]]
            local coords = GetEntityCoords(cache.ped)
            local objects = GetGamePool('CObject')

            for i = 1, #objects do
                local obj = objects[i]
                if BlacklistedModels[GetEntityModel(obj)]
                    and #(coords - GetEntityCoords(obj)) <= 40.0
                    and HasObjectBeenBroken(obj) then
                    if not IsEntityAMissionEntity(obj) then
                        SetEntityAsMissionEntity(obj, false, true)
                    end
                    DeleteEntity(obj)
                end
            end

            Wait(1000)
        end
    end
end)

lib.onCache('vehicle', function(veh)
    isRunning = veh ~= nil
end)
