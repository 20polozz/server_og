if not Config.JobOutfits.enable then return end

CreateThread(function()
    for job, locations in pairs(Config.JobOutfits.locations) do
        for _, location in pairs(locations) do
            local point = lib.points.new({
                coords = location,
                distance = 10.0,
                jobData = job,
                notify = false,
                hasAccess = false,
                isBoss = false
            })

            function point:onEnter()
                local playerJob = Custom.GetJob()
                if playerJob.name == self.jobData then
                    self.hasAccess = true
                    self.isBoss = Config.JobOutfits.bossGrade[playerJob.name] and playerJob.grade >= Config.JobOutfits.bossGrade[playerJob.name] or false
                end
            end
             
            function point:onExit()
                self.hasAccess = false
                self.isBoss = false
            end
            
            function point:nearby()
                if not self.hasAccess then
                    return
                end
                DrawMarker(Config.JobOutfits.markerSettings.sprite, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, Config.JobOutfits.markerSettings.scale, Config.JobOutfits.markerSettings.scale, Config.JobOutfits.markerSettings.scale, Config.JobOutfits.markerSettings.color.r, Config.JobOutfits.markerSettings.color.g, Config.JobOutfits.markerSettings.color.b, Config.JobOutfits.markerSettings.color.a, Config.JobOutfits.markerSettings.bobUpAndDown, Config.JobOutfits.markerSettings.faceCamera, Config.JobOutfits.markerSettings.rotationOrder, Config.JobOutfits.markerSettings.rotate, nil, nil, false)
                if self.currentDistance < 3.0 then
                    if not self.notify then
                        self.notify = true
                        Custom.DrawText("Abrir atuendos", 'E')
                    end
                    if IsControlJustReleased(0, 38) then
                        Outfit.OpenMenu(true)
                    end
                else
                    if self.notify then
                        self.notify = false
                        Custom.HideText()
                    end
                end
            end
        end
    end
end)