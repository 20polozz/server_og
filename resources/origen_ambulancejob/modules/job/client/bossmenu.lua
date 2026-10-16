local useOrigenPolicePoints = lib.load("config").useOrigenPolicePoints
if useOrigenPolicePoints then return end

local hospitals = lib.load("data.hospitals")
local emsJobs = lib.load("config").emsJobs
local IsControlJustReleased = IsControlJustReleased
local DrawMarker = DrawMarker

for index, hospital in pairs(hospitals) do
    if hospital.bossmenu and hospital.bossmenu.pos then
        lib.points.new({
            coords = hospital.bossmenu.pos,
            distance = 2.5,
            onEnter = function(self)
                if not cache.vehicle and Framework.hasJob(emsJobs) then
                    lib.showTextUI('[E] - ' .. locale("bossmenu_label"))
                end
            end,
            onExit = function(self)
                lib.hideTextUI()
            end,
            nearby = function(self)
                if not cache.vehicle and Framework.hasJob(emsJobs) then
                    DrawMarker(2, hospital.bossmenu.pos.x, hospital.bossmenu.pos.y, hospital.bossmenu.pos.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.3, 0.3, 0.3, 216, 27, 85, 200, false, true, 2, false, nil, nil, false)

                    if self.currentDistance < 1.8 and IsControlJustReleased(0, 38) then
                        if Framework.getPlayerJobGrade() >= (hospital.bossmenu.min_grade or 0) then
                            Framework.openBossMenu(Framework.playerJob())
                        else
                            utils.showNotification(locale("bossmenu_denied"), "error")
                        end
                    end
                end
            end
        })
    end
end
