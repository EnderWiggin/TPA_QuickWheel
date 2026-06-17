---@omw-context global
local world = require("openmw.world")

local pauseTag = 'quickWheel'
local enabled

return {
    eventHandlers = {
        ---@param data {state: boolean, scale: number, pause: boolean}
        QW_UpdateWheelState = function(data)
            enabled = data.state
            world.unpause(pauseTag)
            if enabled then
                if data.pause then
                    world.pause(pauseTag)
                    world.setSimulationTimeScale(1)
                else
                    world.unpause(pauseTag)
                    world.setSimulationTimeScale(data.scale)
                end
            else
                world.unpause(pauseTag)
                world.setSimulationTimeScale(1)
            end
        end,
        Toxicology_ConfirmApply = function(data)
            if data and data.actor then
                data.actor:sendEvent('QW_UpdateWheelState')
            end
        end,
    },
    engineHandlers = {
        onUpdate = function()
            if not enabled then return end

            local tags = world.getPausedTags()
            if tags.ui then
                world.unpause(tags.ui)
            end
        end,
    }
}
