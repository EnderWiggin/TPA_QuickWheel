---@omw-context player
local I = require('openmw.interfaces')
local core = require('openmw.core')
local input = require('openmw.input')
local omwself = require('openmw.self')
local ui = require('openmw.ui')
local async = require('openmw.async')
local v2 = require('openmw.util').vector2

local l10n = core.l10n('TPA_QuickWheel')
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

-- Captures the controller-mode state at the moment the wheel opens, and freezes it for the
-- wheel's lifetime.  wheel.lua's mouseMove handler, the stick feed below and handleActivate
-- all read config.shouldUseController() live, while setWheelMode decides the cursor only once,
-- at open.  If the live flag flips while the wheel is up they disagree with the cursor, and
-- neither input can select or activate.
local openControllerMode = false

local UIMode = I.UI.MODE
local InterfaceMode = UIMode.Interface

local potions = require('scripts.TPABOBAP.QuickWheel.providers.provide_potions')
local magics = require('scripts.TPABOBAP.QuickWheel.providers.provide_magic')
local equipment = require('scripts.TPABOBAP.QuickWheel.providers.equipment')

---@type table<string, WheelKeybinds>
local keybinds = {}

---@param icon PotionCategoryIcon
local function openPotionCategory(icon)
    if not wheel.shown then return end
    local items = icon:provider()
    if #items == 0 then return end
    local quickUse = icon:getQuickUsePotion(items)
    if quickUse then
        potions.usePotion(quickUse)
    else
        local id = icon:Id()
        wheel:show(true, {
            name = id,
            keybinds = keybinds[icon:Id()],
            provider = function()
                return potions.makeIcons(icon:provider(), icon.name == 'Poison' and potions.usePoison or nil)
            end
        })
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
    local id = icon:Id()
    wheel:show(true, {
        name = id,
        keybinds = keybinds[id],
        provider = function()
            return magics.makeIcons(icon:provider())
        end
    })
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

local function getFavoriteMagics()
    return magics.makeIcons(magics.favoriteProvider())
end

---@param icon SpellCategoryIcon
local function openEquipmentCategory(icon)
    if not wheel.shown then return end
    local spells = icon:provider()
    if #spells == 0 then return end
    local id = icon:Id()
    wheel:show(true, {
        name = id,
        keybinds = keybinds[id],
        provider = function()
            return equipment.makeIcons(icon:provider())
        end
    })
end

local function getEquipCategories()
    local cat = C.EquipmentCategories
    return {
        SpellCategoryIcon:new({ name = cat.Weapon, activate = openEquipmentCategory, provider = equipment.provider }),
        SpellCategoryIcon:new({ name = cat.Armor, activate = openEquipmentCategory, provider = equipment.provider }),
        SpellCategoryIcon:new({ name = cat.Tools, activate = openEquipmentCategory, provider = equipment.provider }),
        SpellCategoryIcon:new({ name = cat.Clothes, activate = openEquipmentCategory, provider = equipment.provider }),
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
    if isOn then openControllerMode = config.shouldUseController() end
    local controllerMode = openControllerMode
    if not controllerMode then
        if isWheelModeOn then
            I.UI.setMode(InterfaceMode, { windows = {} })
        else
            I.UI.setMode()
        end
    end

    currentWheelMode = mode
    local id = 'wheel:' .. (currentWheelMode or 'omni')
    if currentWheelMode == 'potions' then
        wheel:show(isWheelModeOn, { name = id, keybinds = keybinds[id], provider = getPotionCategories })
    elseif currentWheelMode == 'magic' then
        wheel:show(isWheelModeOn, { name = id, keybinds = keybinds[id], provider = getSpellCategories })
    elseif currentWheelMode == 'magic-favorite' then
        wheel:show(isWheelModeOn, { name = id, keybinds = keybinds[id], provider = getFavoriteMagics })
    elseif currentWheelMode == 'equip' then
        wheel:show(isWheelModeOn, { name = id, keybinds = keybinds[id], provider = getEquipCategories, minSectors = 0 })
    else
        wheel:show(isWheelModeOn, { name = id, keybinds = keybinds[id], provider = getALLCategories })
    end

    core.sendGlobalEvent('QW_UpdateWheelState', {
        state = isWheelModeOn,
        scale = C.getTimeScale(config.main.s_TimeMode),
        pause = controllerMode,
    })
end

---@return openmw.util.Vector2
local function getControllerDirection()
    -- raw LeftX/LeftY polls one controller (controllers.begin()); a reconnect can
    -- swap in the wrong pad and leave the stick dead. virtual Move*/Look* axes are
    -- device-agnostic. opt-in via b_UseVirtualAxis (off: deprecated engine API)
    local stick = config.main.s_ControllerStick
    local useVirtual = config.main.b_UseVirtualAxis or false
    if not stick or stick == C.ControllerStick.Left then
        if useVirtual then
            return v2(input.getAxisValue(input.CONTROLLER_AXIS.MoveLeftRight),
                input.getAxisValue(input.CONTROLLER_AXIS.MoveForwardBackward))
        end
        return v2(input.getAxisValue(input.CONTROLLER_AXIS.LeftX), input.getAxisValue(input.CONTROLLER_AXIS.LeftY))
    elseif stick == C.ControllerStick.Right then
        if useVirtual then
            return v2(input.getAxisValue(input.CONTROLLER_AXIS.LookLeftRight),
                input.getAxisValue(input.CONTROLLER_AXIS.LookUpDown))
        end
        return v2(input.getAxisValue(input.CONTROLLER_AXIS.RightX), input.getAxisValue(input.CONTROLLER_AXIS.RightY))
    end
    return v2(0, 0)
end

local function onUpdate()
    -- Outside the isWheelModeOn branch on purpose: the close animation plays
    -- after the wheel has logically shut.
    wheel:tickAnimation()

    local wasModifiers = lastModifiers
    local wasMode = lastUIMode
    lastUIMode = I.UI.getMode()
    lastModifiers = helpers.updateModifiers()
    if isWheelModeOn then
        local dir = getControllerDirection()
        local controller = openControllerMode
        if wasMode ~= lastUIMode then
            if wasMode == InterfaceMode and lastUIMode ~= InterfaceMode
                or openControllerMode and lastUIMode == InterfaceMode then
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

-- activate-on-release -- works on leaf items only
local function activateSelectedLeaf()
    if not wheel.shown or not wheel.items then return end
    local sel = wheel.selected
    local item = sel and sel > 0 and wheel.items[sel]
    if item and not item.provider and item.activate then
        item:activate()
    end
end

local function handleWheelAction(isPressed, wheelMode)
    if wheel.isKeybindingActive then return end
    local uiMode = I.UI.getMode()
    if isPressed then
        if uiMode ~= nil and uiMode ~= InterfaceMode then return end
        if not isWheelModeOn then
            if I.UI.getMode() ~= nil or core.isWorldPaused() then return end
            setWheelMode(true, wheelMode)
            pressedAt = core.getRealTime()
        elseif wheelMode ~= currentWheelMode then
            wasToggled = false
            setWheelMode(true, wheelMode)
            pressedAt = core.getRealTime()
        end
    else
        local mode = config.main.s_KeyMode
        if mode == C.KeyModes.Smart then
            local now = core.getRealTime()
            if (now - pressedAt) > C.KeyHoldThreshold or wasToggled then
                -- a real hold-release confirms, a tap-then-tap close stays a cancel
                if config.main.b_ActivateOnRelease and not wasToggled then activateSelectedLeaf() end
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
            if config.main.b_ActivateOnRelease then activateSelectedLeaf() end -- activate-on-release
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

local function handleFavMagicWheelAction(isPressed)
    if isPressed then
        local favorites = magics.favoriteProvider()
        if #favorites == 0 then
            ui.showMessage(l10n('MSG_NO_FAVORITE_MAGIC'))
            pcall(core.sound.playSound3d, "enchant fail", omwself)
            return
        end
    end
    handleWheelAction(isPressed, 'magic-favorite')
end

local function handleEquipWheelAction(isPressed)
    handleWheelAction(isPressed, 'equip')
end

local function handleActivate()
    if config.shouldUseController() then
        wheel:onMouseClick()
    end
end

local initialized = false
local function Init()
    if initialized then return end
    initialized = true
    wheel:init(omwself)
    input.registerActionHandler(C.Actions.Omni, async:callback(handleOmniWheelAction))
    input.registerActionHandler(C.Actions.Potion, async:callback(handlePotionWheelAction))
    input.registerActionHandler(C.Actions.Magic, async:callback(handleMagicWheelAction))
    input.registerActionHandler(C.Actions.MagicFav, async:callback(handleFavMagicWheelAction))
    input.registerActionHandler(C.Actions.Equipment, async:callback(handleEquipWheelAction))
    input.registerTriggerHandler('Activate', async:callback(handleActivate))

    core.sendGlobalEvent('QW_UpdateWheelState', { state = false })
end

local function onLoad(loadData)
    Init()
    keybinds = loadData and loadData.keybinds or {}
end

local function onSave()
    return {
        version = 1,
        keybinds = keybinds,
    }
end

---@param data {name: string, binds: WheelKeybinds}
local function onSetKeybinds(data)
    if not data or not data.name or not data.binds then return end
    keybinds[data.name] = data.binds
end

---@param evt openmw.input.KeyboardEvent
local function onKeyRelease(evt)
    if evt.code == input.KEY.Escape then
        setWheelMode(false)
        return
    end
end

---@param evt openmw.input.KeyboardEvent
local function onKeyPress(evt)
    if isWheelModeOn then
        wheel:onKeyPress(evt)
    else
        config.controllerActive = false
    end
end

local function onControllerButtonPress()
    if not isWheelModeOn then config.controllerActive = true end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onKeyRelease = onKeyRelease,
        onKeyPress = onKeyPress,
        onControllerButtonPress = onControllerButtonPress,
        onInit = Init,
        onLoad = onLoad,
        onSave = onSave,
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
        QW_SetWheelKeybinds = onSetKeybinds,
        OSSC_CastingState = function(evt)
            magics.QuickCaster.CastingState({ isCasting = evt and evt.isCasting, delay = 0.3 })
        end,
    },
}
