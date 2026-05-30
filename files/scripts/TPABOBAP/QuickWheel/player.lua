local I = require('openmw.interfaces')
local core = require('openmw.core')
local input = require('openmw.input')
local types = require('openmw.types')
local omwself = require('openmw.self')
local async = require('openmw.async')

local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local config = require('scripts.TPABOBAP.QuickWheel.config')
local wheel = require('scripts.TPABOBAP.QuickWheel.wheel')
local PotionIcon = require('scripts.TPABOBAP.QuickWheel.icons.potion_icon')
local CategoryIcon = require('scripts.TPABOBAP.QuickWheel.icons.category_icon')
local C = require('scripts.TPABOBAP.QuickWheel.constants')

local isWheelModeOn = false
local pressedAt = 0
local wasToggled = false
local lastUIMode
---@type string
local lastModifiers

local PotionTypes = C.PotionTypes

local function isPotionOfType(potion, type)
    local record = potion.type.record(potion.recordId)
    local test = PotionTypes[type]
    local limit = config.main.b_NoUnknownCategory and helpers.getKnownAlchemyEffectCount(true) or math.huge

    local valid = false
    for i, effect in ipairs(record.effects) do
        if i > limit then return valid end
        local t = test[effect.id]
        if t == false then
            return false
        elseif t == true then
            valid = true
        end
    end
    return valid
end

---@function
---@param icon PotionIcon
local function usePotion(icon)
    local potion = icon.item or icon
    core.sendGlobalEvent('UseItem', {
        object = potion,
        actor = omwself,
    })
end

local function findPotions(filter)
    local inventory = types.Actor.inventory(omwself)
    local pots = inventory:getAll(types.Potion)
    ---@type table<number, PotionIcon>
    local result = {}
    for _, v in ipairs(pots) do
        if not filter or filter(v) then
            table.insert(result, v)
        end
    end
    return result
end

---@function
---@return table<number, Icon>
local function makePotionIcons(potions)
    ---@type table<number, PotionIcon>
    local result = {}
    for _, v in ipairs(potions) do
        table.insert(result, PotionIcon:new({ item = v, activate = usePotion }))
    end
    table.sort(result, function(a, b)
        local ra = a.item.type.record(a.item.recordId)
        local rb = b.item.type.record(b.item.recordId)

        if ra.name ~= rb.name then
            return ra.name < rb.name
        end

        if ra.value ~= rb.value then
            return ra.value < rb.value --cheaper first
        end

        return a.item.id < b.item.id --id as tie breaker
    end)
    return result
end

local function otherPotionFiler(p)
    for k, _ in pairs(PotionTypes) do
        if isPotionOfType(p, k) then return false end
    end
    return true
end

local function potionCategoryProvider(icon)
    if icon.name == 'Other' then
        return findPotions(otherPotionFiler)
    else
        return findPotions(function(p) return isPotionOfType(p, icon.name) end)
    end
end

---@function
---@param icon CategoryIcon
local function openCategory(icon)
    if not wheel.ctx.shown then return end
    local items = icon:provider()
    if #items == 0 then return end
    local quickUse = icon:getQuickUsePotion(items)
    if quickUse then
        usePotion(quickUse)
    else
        wheel:show(true, function()
            return makePotionIcons(icon:provider())
        end)
    end
end

local function getCategories()
    return {
        CategoryIcon:new({ name = 'Health', activate = openCategory, provider = potionCategoryProvider, quickUse = true }),
        CategoryIcon:new({ name = 'Stamina', activate = openCategory, provider = potionCategoryProvider, quickUse = true }),
        CategoryIcon:new({ name = 'Combat', activate = openCategory, provider = potionCategoryProvider }),
        CategoryIcon:new({ name = 'Cure', activate = openCategory, provider = potionCategoryProvider }),
        CategoryIcon:new({ name = 'Poison', activate = openCategory, provider = potionCategoryProvider }),
        CategoryIcon:new({ name = 'Other', activate = openCategory, provider = potionCategoryProvider }),
        CategoryIcon:new({ name = 'Buffs', activate = openCategory, provider = potionCategoryProvider }),
        CategoryIcon:new({ name = 'Magicka', activate = openCategory, provider = potionCategoryProvider, quickUse = true }),
    }
end

local function setWheelMode(isOn)
    if not isOn then wasToggled = false end
    if isOn == isWheelModeOn then return end

    if lastUIMode ~= nil and not isWheelModeOn then return end

    isWheelModeOn = isOn

    if isWheelModeOn then
        I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
    else
        I.UI.setMode()
    end

    wheel:show(isWheelModeOn, getCategories)

    core.sendGlobalEvent('QW_UpdateWheelState', { state = isWheelModeOn, scale = C.getTimeScale(config.main.s_TimeMode) })
end

local function onUpdate(dt)
    local wasModifiers = lastModifiers
    local wasMode = lastUIMode
    lastUIMode = I.UI.getMode()
    lastModifiers = tostring(input.isShiftPressed()) .. ':' .. tostring(input.isCtrlPressed()) .. ':' .. tostring(input.isAltPressed())
    if isWheelModeOn then
        if wasMode ~= lastUIMode then
            if wasMode == I.UI.MODE.Interface and lastUIMode ~= I.UI.MODE.Interface then
                setWheelMode(false)
                return
            end
        end

        if wasModifiers ~= lastModifiers then
            wheel:updateIcons()
        end

        wheel:checkDirty()
    end
end

local function handleWheelAction(isPressed)
    if isPressed then
        if not isWheelModeOn then
            pressedAt = core.getRealTime()
            setWheelMode(true)
        end
    else
        local mode = config.main.s_KeyMode
        if mode == C.KeyModes.Smart then
            local now = core.getRealTime()
            if (now - pressedAt) > C.KeyHoldThreshold or wasToggled then
                setWheelMode(false)
            else
                wasToggled = true
            end
        elseif mode == C.KeyModes.Toggle then
            if wasToggled then
                setWheelMode(false)
            else
                wasToggled = true
            end
        elseif mode == C.KeyModes.Hold then
            setWheelMode(false)
        end
    end
end

local function Init()
    wheel:init(omwself)
    input.registerActionHandler(C.actionOpenWheel, async:callback(handleWheelAction))
end

local function onKeyRelease(key)
    if key.code == input.KEY.Escape then
        setWheelMode(false)
        return
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onKeyRelease = onKeyRelease,
        onLoad = Init,
        onInit = Init,
    },
    eventHandlers = {
        IE_Update = function()
            wheel:markDirty()
        end,
        QW_UpdateWheelState = function()
            if wheel.ctx.shown then
                wheel:markDirty()
            end
        end,
    },
}