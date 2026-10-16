INSTRUCT_NONE = 'none'
INSTRUCT_PLAY = 'play'
INSTRUCT_THROW = 'throw'

BasketballInstructional = nil
InstructionalState = INSTRUCT_NONE
WantedInstructionalState = INSTRUCT_NONE

function InstructionalButtonMessage(text) end
function InstructionalButton(ControlButton) end
function setupInstructionalPlayScaleform(scaleform) return nil end
function setupInstructionalThrowScaleform(scaleform) return nil end

Citizen.CreateThread(function()
    while true do
        Wait(1000)
        if WantedInstructionalState ~= INSTRUCT_NONE then
            WantedInstructionalState = INSTRUCT_NONE
        end
    end
end)
