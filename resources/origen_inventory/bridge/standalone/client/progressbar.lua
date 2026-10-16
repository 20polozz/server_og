Bridge = Bridge or {}
if Config.Framework == 'qbcore' then 
    QB = QB or exports['qb-core']:GetCoreObject()
end


if Config.Progressbar == 'ox_lib' then 
    function Bridge.ProgressBar(id,label, time, controls, anim, props, cb)
        if lib.progressBar({
            position = 'bottom',
            duration = time,
            label = label,
            useWhileDead = false,
            canCancel = true,
            anim = anim,
            prop = props,
            disable = {
                car = true
            },
        }) then cb(true) else cb(false) end 
    end
elseif Config.Progressbar == 'qs-progressbar' then
    function Bridge.ProgressBar(id,label, time, controls, anim, props, cb)

        exports['progressbar']:Progress({
            name = id,
            duration = time,
            label = label,
            useWhileDead = false,
            canCancel = true,
            controlDisables = controls,
            animation = anim,
            prop = props or {}
        }, function(status)
            if not status then
                cb(true)
            else
                cb(false)
            end
        end)
    end
elseif Config.Progressbar == 'qb-progressbar' or Config.Progressbar == 'qb-core' then
    function Bridge.ProgressBar(id,label, time, controls, anim, props, cb)
        QB.Functions.Progressbar(id, label, time or 1000,false,true,controls or {} , anim or {}, props or {},{}, function() -- Done
            cb(true)
        end,
        function() -- Cancel
            cb(false)
        end)
    end
elseif Config.Progressbar == 'esx_progressbar' then
    prop_net = nil
    function Bridge.ProgressBar(id,label, time, controls, anim, props, cb)
        Citizen.CreateThread(function()
            Wait(time)
            if prop_net then
                DetachEntity(NetToObj(prop_net), 1, 1)
                DeleteEntity(NetToObj(prop_net))
            end
            local success, error = pcall(function()
                exports["esx_progressbar"]:CancelProgressbar()
            end)
            cb(true)
        end)
        if props then 
            local ped = PlayerPedId()
            RequestModel(GetHashKey(props.model))
            while not HasModelLoaded(GetHashKey(props.model)) do
                Wait(0)
            end

            --local pCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.0)
            local modelSpawn = CreateObject(GetHashKey(props.model), props.coords.x, props.coords.y, props.coords.z, true, true, true)

            local netid = ObjToNet(modelSpawn)
            SetNetworkIdExistsOnAllMachines(netid, true)
            NetworkSetNetworkIdDynamic(netid, true)
            SetNetworkIdCanMigrate(netid, false)
            if not props.bone then
                props.bone = 60309
            end

            if not props.coords then
                props.coords = { x = 0.0, y = 0.0, z = 0.0 }
            end

            if not props.rotation then
                props.rotation = { x = 0.0, y = 0.0, z = 0.0 }
            end

            AttachEntityToEntity(modelSpawn, ped, GetPedBoneIndex(ped, props.bone), props.coords.x, props.coords.y, props.coords.z, props.rotation.x, props.rotation.y, props.rotation.z, 1, 1, 0, 1, 0, 1)
            prop_net = netid
        end
        ESX.Progressbar(label, time, {
            FreezePlayer = false,
            animation = {
                type = 'anim',
                dict = anim.animDict,
                lib = anim.anim,
            }
        })
    end
else
    function Bridge.ProgressBar(id,label, time, controls, anim, props, cb)
        Progress({
            name = id,
            duration = time,
            label = label,
            useWhileDead = false,
            controlDisables = controls,
            canCancel = true,
            animation = anim,
            prop = props
        }, function(status)
            if not status then
                cb(true)
            else
                cb(false)
            end
        end)
    end
end