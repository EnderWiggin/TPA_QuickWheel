---@omw-context player
local I = require('openmw.interfaces')
local core = require('openmw.core')
local input = require('openmw.input')
local omwself = require('openmw.self')
local async = require('openmw.async')
local v2 = require('openmw.util').vector2

local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local config = require('scripts.TPABOBAP.QuickWheel.config')
local wheel = require('scripts.TPABOBAP.QuickWheel.wheel')
local PotionCategoryIcon = require('scripts.TPABOBAP.QuickWheel.icons.potion_category_icon')
local SpellCategoryIcon = require('scripts.TPABOBAP.QuickWheel.icons.magic_category_icon')
local C = require('scripts.TPABOBAP.QuickWheel.constants')

local isWheelModeOn = false
local currentWheelMode
local pressedAt = 0
local wasToggled = false
local lastUIMode
---@type string
local lastModifiers

local UIMode = I.UI.MODE
local InterfaceMode = UIMode.Interface

local potions = require('scripts.TPABOBAP.QuickWheel.providers.provide_potions')
local magics = require('scripts.TPABOBAP.QuickWheel.providers.provide_magic')

---@type table<string, WheelKeybinds>
local keybinds = {
}

---@param icon PotionCategoryIcon
local function openPotionCategory(icon)
    if not wheel.shown then return end
    local items = icon:provider()
    if #items == 0 then return end
    local quickUse = icon:getQuickUsePotion(items)
    if quickUse then
        potions.usePotion(quickUse)
    else
        wheel:show(true, function()
            return potions.makeIcons(icon:provider(), icon.name == 'Poison' and potions.usePoison or nil)
        end, keybinds[icon:Id()])
    end
end

local function getPotionCategories()
    return {
        PotionCategoryIcon:new({ name = 'Health', activate = openPotionCategory, provider = potions.provider, quickUse = true }),
        PotionCategoryIcon:new({ name = 'Stamina', activate = openPotionCategory, provider = potions.provider, quickUse = true }),
        PotionCategoryIcon:new({ name = 'Combat', activate = openPotionCategory, provider = potions.provider }),
        PotionCategoryIcon:new({ name = 'Cure', activate = openPotionCategory, provider = potions.provider }),
        PotionCategoryIcon:new({ name = 'Poison', activate = openPotionCategory, provider = potions.provider }),
        PotionCategoryIcon:new({ name = 'Other', activate = openPotionCategory, provider = potions.provider }),
        PotionCategoryIcon:new({ name = 'Buffs', activate = openPotionCategory, provider = potions.provider }),
        PotionCategoryIcon:new({ name = 'Magicka', activate = openPotionCategory, provider = potions.provider, quickUse = true }),
    }
end

---@param icon SpellCategoryIcon
local function openSpellCategory(icon)
    if not wheel.shown then return end
    local spells = icon:provider()
    if #spells == 0 then return end
    wheel:show(true, function()
        return magics.makeIcons(icon:provider())
    end, keybinds[icon:Id()])
end

local function getSpellCategories()
    local categories = C.SpellCategories
    return {
        SpellCategoryIcon:new({ name = categories.Damage, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Combat, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Debuff, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Control, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Summon, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Other, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Util, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Transport, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Buff, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Restore, activate = openSpellCategory, provider = magics.provider }),
    }
end

local function getALLCategories()
    local categories = C.SpellCategories
    return {
        PotionCategoryIcon:new({ name = 'Health', activate = openPotionCategory, provider = potions.provider, quickUse = true }),
        PotionCategoryIcon:new({ name = 'Stamina', activate = openPotionCategory, provider = potions.provider, quickUse = true }),
        PotionCategoryIcon:new({ name = 'Combat', activate = openPotionCategory, provider = potions.provider }),
        PotionCategoryIcon:new({ name = 'Cure', activate = openPotionCategory, provider = potions.provider }),
        PotionCategoryIcon:new({ name = 'Poison', activate = openPotionCategory, provider = potions.provider }),
        SpellCategoryIcon:new({ name = categories.Damage, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Combat, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Debuff, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Util, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Restore, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Buff, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Summon, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Transport, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Control, activate = openSpellCategory, provider = magics.provider }),
        SpellCategoryIcon:new({ name = categories.Other, activate = openSpellCategory, provider = magics.provider }),
        PotionCategoryIcon:new({ name = 'Other', activate = openPotionCategory, provider = potions.provider }),
        PotionCategoryIcon:new({ name = 'Buffs', activate = openPotionCategory, provider = potions.provider }),
        PotionCategoryIcon:new({ name = 'Magicka', activate = openPotionCategory, provider = potions.provider, quickUse = true }),
    }
end

local function setWheelMode(isOn, mode)
    if not isOn then wasToggled = false end
    if isOn == isWheelModeOn and currentWheelMode == mode then return end

    if lastUIMode ~= nil and not isWheelModeOn then return end

    isWheelModeOn = isOn
    local controllerMode = config.shouldUseController()
    if not controllerMode then
        if isWheelModeOn then
            I.UI.setMode(InterfaceMode, { windows = {} })
        else
            I.UI.setMode()
        end
    end

    currentWheelMode = mode
    if currentWheelMode == 'potions' then
        wheel:show(isWheelModeOn, getPotionCategories, keybinds['wheel:' .. currentWheelMode])
    elseif currentWheelMode == 'magic' then
        wheel:show(isWheelModeOn, getSpellCategories, keybinds['wheel:' .. currentWheelMode])
    else
        wheel:show(isWheelModeOn, getALLCategories, keybinds['wheel:omni'])
    end

    core.sendGlobalEvent('QW_UpdateWheelState', {
        state = isWheelModeOn,
        scale = C.getTimeScale(config.main.s_TimeMode),
        pause = controllerMode,
    })
end

---@return openmw.util.Vector2
local function getControllerDirection()
    local stick = config.main.s_ControllerStick
    if not stick or stick == C.ControllerStick.Left then
        return v2(input.getAxisValue(input.CONTROLLER_AXIS.LeftX), input.getAxisValue(input.CONTROLLER_AXIS.LeftY))
    elseif stick == C.ControllerStick.Right then
        return v2(input.getAxisValue(input.CONTROLLER_AXIS.RightX), input.getAxisValue(input.CONTROLLER_AXIS.RightY))
    end
    return v2(0, 0)
end

local function onUpdate()
    local wasModifiers = lastModifiers
    local wasMode = lastUIMode
    lastUIMode = I.UI.getMode()
    lastModifiers = helpers.updateModifiers()
    if isWheelModeOn then
        local dir = getControllerDirection()
        if dir:length() > config.main.n_ControllerDeadZone then config.controllerActive = true end
        local controller = config.shouldUseController()
        if wasMode ~= lastUIMode then
            if wasMode == InterfaceMode and lastUIMode ~= InterfaceMode
                or controller and lastUIMode == InterfaceMode then
                setWheelMode(false)
                return
            end
        end

        if wasModifiers ~= lastModifiers then
            wheel:updateIcons()
        end

        if controller or config.main.s_TimeMode == C.TimeModes.Paused then
            wheel:onControllerOffsetChanged(dir)
        end
        wheel:checkDirty()
    end
end

local function handleWheelAction(isPressed, wheelMode)
    local uiMode = I.UI.getMode()
    if isPressed then
        if uiMode ~= nil and uiMode ~= InterfaceMode then return end
        if not isWheelModeOn then
            if I.UI.getMode() ~= nil or core.isWorldPaused() then return end
            pressedAt = core.getRealTime()
            setWheelMode(true, wheelMode)
        elseif wheelMode ~= currentWheelMode then
            wasToggled = false
            pressedAt = core.getRealTime()
            setWheelMode(true, wheelMode)
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
local function handleOmniWheelAction(isPressed)
    handleWheelAction(isPressed, 'omni')
end
local function handlePotionWheelAction(isPressed)
    handleWheelAction(isPressed, 'potions')
end
local function handleMagicWheelAction(isPressed)
    handleWheelAction(isPressed, 'magic')
end

local function handleActivate()
    if config.shouldUseController() then
        wheel:onMouseClick()
    end
end

local function Init()
    wheel:init(omwself)
    input.registerActionHandler(C.Actions.Omni, async:callback(handleOmniWheelAction))
    input.registerActionHandler(C.Actions.Potion, async:callback(handlePotionWheelAction))
    input.registerActionHandler(C.Actions.Magic, async:callback(handleMagicWheelAction))
    input.registerTriggerHandler('Activate', async:callback(handleActivate))

    core.sendGlobalEvent('QW_UpdateWheelState', { state = false })
end

---@param key openmw.input.KeyboardEvent
local function onKeyRelease(key)
    if key.code == input.KEY.Escape then
        setWheelMode(false)
        return
    end
end

---@param evt openmw.input.KeyboardEvent
local function onKeyPress(evt)
    config.controllerActive = false
    if isWheelModeOn then
        wheel:onKeyPress(evt)
    end
end

local function onControllerButtonPress()
    config.controllerActive = true
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onKeyRelease = onKeyRelease,
        onKeyPress = onKeyPress,
        onControllerButtonPress = onControllerButtonPress,
        onLoad = Init,
        onInit = Init,
    },
    eventHandlers = {
        IE_Update = function()
            wheel:markDirty()
        end,
        QW_UpdateWheelState = function(data)
            if not data then
                if wheel.shown then
                    wheel:markDirty()
                end
            else
                setWheelMode(data.wheelState, data.wheelMode)
            end
        end,
        OSSC_CastingState = function(evt)
            magics.QuickCaster.CastingState({ isCasting = evt and evt.isCasting, delay = 0.3 })
        end,
    },
}
