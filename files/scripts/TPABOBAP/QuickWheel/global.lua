---@omw-context global
local world = require("openmw.world")
local core = require('openmw.core')

local enabled

return {
    eventHandlers = {
        QW_UpdateWheelState = function(data)
            enabled = data and data.state
            world.setSimulationTimeScale(enabled and data.scale or 1)
        end,
        Toxicology_ConfirmApply = function(data)
            if data and data.actor then
                data.actor:sendEvent('QW_UpdateWheelState')
            end
        end,
    },
    engineHandlers = {
        onUpdate = function()
            if core.isWorldPaused() then return end
            if not enabled then return end

            local tags = world.getPausedTags()
            if tags.ui then
                world.unpause(tags.ui)
            end
        end,
    }
}
