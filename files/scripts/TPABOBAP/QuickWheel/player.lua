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
local Icon = require('scripts.TPABOBAP.QuickWheel.icons.base_icon')
local PotionIcon = require('scripts.TPABOBAP.QuickWheel.icons.potion_icon')

local isWheelModeOn = false
local lastUIMode

---@function
---@param icon PotionIcon
local function usePotion(icon)
    core.sendGlobalEvent('UseItem', {
        object = icon.item,
        actor = omwself,
    })
end

---@function
---@return table<number, Icon>
local function findPotions()
    local inventory = types.Actor.inventory(omwself)
    local pots = inventory:getAll(types.Potion)
    local result = {}
    for k, v in ipairs(pots) do
        result[k] = PotionIcon:new({ item = v, activate = usePotion })
    end
    return result
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