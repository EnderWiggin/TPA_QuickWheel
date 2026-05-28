local I = require('openmw.interfaces')
local core = require('openmw.core')
local input = require('openmw.input')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local omwself = require('openmw.self')

local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local wheel = require('scripts.TPABOBAP.QuickWheel.wheel')

local isWheelModeOn = false
local lastUIMode

local function findPotions()
    local inventory = types.Actor.inventory(omwself)
    local pots = inventory:getAll(types.Potion)
    return pots
end

local function setWheelMode(isOn)
    if isOn == isWheelModeOn then return end

    if lastUIMode ~= nil and not isWheelModeOn then return end

    isWheelModeOn = isOn

    if isWheelModeOn then
        I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
    else
        I.UI.setMode()
    end

    wheel:show(isWheelModeOn, findPotions)

    core.sendGlobalEvent('QW_UpdateWheelState', { state = isWheelModeOn })
end

local function onUpdate(dt)
    local wasMode = lastUIMode
    lastUIMode = I.UI.getMode()
    if isWheelModeOn then
        wheel:checkDirty()
        if wasMode ~= lastUIMode then
            if wasMode == I.UI.MODE.Interface and lastUIMode ~= I.UI.MODE.Interface then
                setWheelMode(false)
                return
            end
        end
    end
end

local function onKeyPress(key)
    if key.code == input.KEY.X then
        setWheelMode(true)
    end
end

local function onKeyRelease(key)
    if key.code == input.KEY.X then
        setWheelMode(false)
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onKeyPress = onKeyPress,
        onKeyRelease = onKeyRelease,
        onLoad = function(_)
            wheel:init(omwself)
        end,
        onInit = function()
            wheel:init(omwself)
        end,
    }
}