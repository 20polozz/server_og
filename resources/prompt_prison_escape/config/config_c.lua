lib.locale()

return {
    interaction = 'auto', -- 'auto' | 'ox_target' | 'qb-target' | 'textUI' (ox_lib textUI)
    requiredItem = 'tool_screwdriver', -- Item required to start the minigame, set to empty to disable item requirement (works only for ox_target or qb-target)

    uiLocation = 'middle-left', -- 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right' | 'middle-left' | 'middle-right' | 'center'

    textUI = {
        hide = function()
            lib.hideTextUI()
        end,

        ---@param text string
        show = function(text)
            lib.showTextUI(text)
        end,
    },

    toilet = {
        screwOffsets = {
            { -- top left
                screw = vec3(-0.27868, 0.503753, 0.521223),
                cam = {
                    vec3(-0.320000, 0.050000, 0.739999),
                    vec3(-30.000000, 0.000000, -9.000000),
                }
            },
            { -- bottom left
                screw = vec3(-0.27868, 0.503753, -0.08372),
                cam = {
                    vec3(-0.440000, 0.100000, 0.040000),
                    vec3(-13.000000, 0.000000, -25.000000),
                }
            },
            { -- top right
                screw = vec3(0.208994, 0.503753, 0.521223),
                cam = {
                    vec3(0.330000, 0.300000, 0.730000),
                    vec3(-50.000000, 0.000000, 31.000000),
                }
            },
            { -- bottom right
                screw = vec3(0.208994, 0.503753, -0.08372),
                cam = {
                    vec3(0.320000, 0.110000, 0.230000),
                    vec3(-42.000000, 0.000000, 22.000000),
                }
            },
        },
        screwModel = joaat('prompt_prison_screw'),
        screwDriverModel = joaat('v_ind_cs_screwdrivr3'),

        useNetworkedObjects = false --[[
            Set to true if you want to use networked objects for the screw and screwdriver
            Set to false if you're using entity lockdown mode
        ]]
    }
}