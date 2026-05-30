local I = require('openmw.interfaces')
local world = require("openmw.world")
local auxUtil = require('openmw_aux.util')

local enabled

return {
    eventHandlers = {
        QW_UpdateWheelState = function(data)
            enabled = data and data.state
            world.setSimulationTimeScale(enabled and 0.1 or 1)
        end,
        Toxicology_ConfirmApply = function(data)
            if data and data.actor then
                data.actor:sendEvent('QW_UpdateWheelState')
            end
        end,
    },
    engineHandlers = {
        onUpdate = function(dt)
            if not enabled then return end

            local tags = world.getPausedTags()
            if tags.ui then
                world.unpause(tags.ui)
            end
        end,
    }
}