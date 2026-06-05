---@omw-context player
local I = require('openmw.interfaces')
local core = require('openmw.core')
local input = require('openmw.input')
local types = require('openmw.types')
local omwself = require('openmw.self')
local async = require('openmw.async')
local auxUtil = require('openmw_aux.util')

local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local config = require('scripts.TPABOBAP.QuickWheel.config')
local wheel = require('scripts.TPABOBAP.QuickWheel.wheel')
local PotionIcon = require('scripts.TPABOBAP.QuickWheel.icons.potion_icon')
local MagicIcon = require('scripts.TPABOBAP.QuickWheel.icons.magic_icon')
local PotionCategoryIcon = require('scripts.TPABOBAP.QuickWheel.icons.potion_category_icon')
local SpellCategoryIcon = require('scripts.TPABOBAP.QuickWheel.icons.magic_category_icon')
local QuickCaster = require('scripts.TPABOBAP.QuickWheel.quick_caster')
local C = require('scripts.TPABOBAP.QuickWheel.constants')

local isWheelModeOn = false
local currentWheelMode
local pressedAt = 0
local wasToggled = false
local lastUIMode
---@type string
local lastModifiers

local PotionTypes = C.PotionTypes

local function isPotionOfType(potion, type)
    local record = potion.type.record(potion.recordId)
    local test = PotionTypes[type]
    if not test then return false end
    local toxicology = config.potions.s_SeparateAlcohol == C.AlcoholModes.Move and I.Toxicology
    if toxicology and toxicology.isAlcohol then
        if toxicology.isAlcohol(potion) then return false end
    end
    local limit = config.potions.b_NoUnknownCategory and helpers.getKnownAlchemyEffectCount(true) or math.huge

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

---@function
---@param icon PotionIcon
local function usePoison(icon)
    local potion = icon.item or icon
    if config.potions.b_QuickApplyPoison and input.isShiftPressed() then
        core.sendGlobalEvent('Toxicology_ConfirmApply', {
            actor = omwself.object,
            potion = potion,
        })
    else
        core.sendGlobalEvent('UseItem', {
            object = potion,
            actor = omwself,
        })
    end
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
local function makePotionIcons(potions, useAction)
    ---@type table<number, PotionIcon>
    local result = {}
    for _, v in ipairs(potions) do
        table.insert(result, PotionIcon:new({ item = v, activate = useAction or usePotion }))
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
    local toxicology = config.potions.s_SeparateAlcohol ~= C.AlcoholModes.Normal and I.Toxicology
    if toxicology and toxicology.isAlcohol then
        if toxicology.isAlcohol(p) then return true end 
    end
    for k, _ in pairs(PotionTypes) do
        if isPotionOfType(p, k) then return false end
    end
    return true
end

local function isPoisonFilter(p)
    local toxicology = config.potions.b_FilterPoisons and I.Toxicology
    if toxicology and toxicology.isPoison then  
        return toxicology.isPoison(p)
    else
        return isPotionOfType(p, 'Poison')
    end
end

local function potionCategoryProvider(icon)
    if icon.name == 'Other' then
        return findPotions(otherPotionFiler)
    elseif icon.name == 'Poison' then
        return findPotions(isPoisonFilter)
    else
        return findPotions(function(p) return isPotionOfType(p, icon.name) end)
    end
end

---@function
---@param icon PotionCategoryIcon
local function openPotionCategory(icon)
    if not wheel.ctx.shown then return end
    local items = icon:provider()
    if #items == 0 then return end
    local quickUse = icon:getQuickUsePotion(items)
    if quickUse then
        usePotion(quickUse)
    else
        wheel:show(true, function()
            return makePotionIcons(icon:provider(), icon.name == 'Poison' and usePoison or nil)
        end)
    end
end

local function getPotionCategories()
    return {
        PotionCategoryIcon:new({ name = 'Health', activate = openPotionCategory, provider = potionCategoryProvider, quickUse = true }),
        PotionCategoryIcon:new({ name = 'Stamina', activate = openPotionCategory, provider = potionCategoryProvider, quickUse = true }),
        PotionCategoryIcon:new({ name = 'Combat', activate = openPotionCategory, provider = potionCategoryProvider }),
        PotionCategoryIcon:new({ name = 'Cure', activate = openPotionCategory, provider = potionCategoryProvider }),
        PotionCategoryIcon:new({ name = 'Poison', activate = openPotionCategory, provider = potionCategoryProvider }),
        PotionCategoryIcon:new({ name = 'Other', activate = openPotionCategory, provider = potionCategoryProvider }),
        PotionCategoryIcon:new({ name = 'Buffs', activate = openPotionCategory, provider = potionCategoryProvider }),
        PotionCategoryIcon:new({ name = 'Magicka', activate = openPotionCategory, provider = potionCategoryProvider, quickUse = true }),
    }
end

---@param icon MagicIcon
local function activateMagic(icon)
    local justEquip = input.isAltPressed()
    local enqueue = input.isShiftPressed()
    local quickCast = input.isCtrlPressed()

    local requested = quickCast and 'cast' or enqueue and 'queue' or justEquip and 'regular' or 'none'
    local clickMode = config.magic.s_MagicClickMode

    if clickMode == C.MagicClickModes.EQUIP then
        requested = justEquip and 'regular' or requested
        justEquip = not justEquip
    elseif clickMode == C.MagicClickModes.QCAST then
        requested = quickCast and 'regular' or requested
        quickCast = not quickCast
        requested = requested == 'none' and quickCast and 'cast' or requested
    elseif clickMode == C.MagicClickModes.QUEUE then
        requested = enqueue and 'regular' or requested
        enqueue = not enqueue
        requested = requested == 'none' and enqueue and 'queue' or requested
    end

    local canUseQuickCast = I.MagExp_Player --TODO: add checks for OSSC when relevant?
    if canUseQuickCast and requested == 'cast' then
        justEquip = false
        enqueue = false
        quickCast = true
    elseif canUseQuickCast and requested == 'queue' then
        justEquip = false
        enqueue = true
        quickCast = false
    else
        enqueue = false
        quickCast = false
    end

    if enqueue or quickCast then
        ---@type CastInfo
        local data = { ignoreUIMode = true, item = icon.item, spell = icon.spell, id = icon:tipId() }
        if quickCast then
            I.UI.setMode()
            QuickCaster.SetQueue({})
        end

        if not QuickCaster.isCasting() then
            QuickCaster.SetQueue({ data })
            QuickCaster.quickCast(data)
        elseif enqueue then
            QuickCaster.Enqueue(data)
        end
    else
        QuickCaster.SetQueue({})
        I.UI.setMode()
        if icon.spell then
            omwself.type.setSelectedSpell(omwself, icon.spell)
        elseif icon.item then
            omwself.type.setSelectedEnchantedItem(omwself, icon.item)
        end
        if not justEquip then
            omwself.type.setStance(omwself, types.Actor.STANCE.Spell)
        end
    end
end

local function getMagicItemCountAdjustedByQueue(item)
    local count = item.count
    local enchantId = item.type.record(item).enchant
    local enchant = enchantId and core.magic.enchantments.records[enchantId]
    if enchant == nil then return count end
    if enchant.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
        --do noting - base count already calculated
    elseif enchant.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then
        local mwHelpersOk, mwHelpers = pcall(require, 'scripts.MagicWindowExtender.util.helpers')
        if mwHelpersOk and mwHelpers then
            local itemData = item.type.itemData(item)
            local charge = itemData.enchantmentCharge or 0
            count = math.floor(charge / mwHelpers.getModifiedSpellCost(enchantId, true))
        else
            return count
        end
    else
        return count
    end

    for _, d in ipairs(QuickCaster.GetQueue()) do
        if d.item and d.item.id == item.id then
            count = count - 1
        end
    end
    return count
end

local function isSpellOfType(effects, type)
    for _, effect in ipairs(effects) do
        local data = helpers.categorizeMagicEffectWithParams(effect)
        local etype = data.type
        if type == C.SpellCategories.Combat then
            if etype == 'Combat' then return true end
        elseif type == C.SpellCategories.Restore then
            if etype == 'Restore' or etype == 'Cure' then return true end
        elseif type == C.SpellCategories.Damage then
            if etype == 'Damage' then return true end
        elseif type == C.SpellCategories.Debuff then
            if etype == 'Debuff' then return true end
        elseif type == C.SpellCategories.Util then
            if etype == 'Util' then return true end
        elseif type == C.SpellCategories.Buff then
            if etype == 'Buff' then return true end
        elseif type == C.SpellCategories.Transport then
            if etype == 'Transport' then return true end
        elseif type == C.SpellCategories.Control then
            if etype == 'Control' then return true end
        elseif type == C.SpellCategories.Summon then
            if etype == 'Summon' or etype == 'Bound' then return true end
        end
    end
    return false
end

local function otherSpellsFilter(effects)
    for k, _ in pairs(C.SpellCategories) do
        if k ~= C.SpellCategories.Other then
            if isSpellOfType(effects, k) then return false end
        end
    end
    return true
end

local function findMagics(filter)
    local pinned
    local hidden

    -- ----------- START Collect Spells ----------------------
    if I.MagicWindow then
        pinned = I.MagicWindow.getStat('pinned')
        pinned = pinned and pinned.spells
        hidden = I.MagicWindow.getStat('hidden')
        hidden = hidden and hidden.spells
    end

    pinned = pinned or {}
    hidden = hidden or {}

    local result_spells = {}
    local spells = omwself.type.spells(omwself)
    for _, spell in ipairs(spells) do
        if spell.type == core.magic.SPELL_TYPE.Spell and filter(spell.effects) and not hidden[spell.id] then
            table.insert(result_spells, spell)
        end
    end

    table.sort(result_spells, function(a, b)
        if pinned[a.id] ~= pinned[b.id] then
            return pinned[a.id]
        end

        if a.name ~= b.name then
            return a.name < b.name
        end

        return a.id < b.id --id as tie breaker
    end)

    -- ----------- Collect Items ----------------------
    if I.MagicWindow then
        pinned = I.MagicWindow.getStat('pinned')
        pinned = pinned and pinned.magicItems
        hidden = I.MagicWindow.getStat('hidden')
        hidden = hidden and hidden.magicItems
    end

    pinned = pinned or {}
    hidden = hidden or {}

    local result_items = {}
    local magicItems = auxUtil.mapFilter(omwself.type.inventory(omwself):getAll(), function(item)
        local enchantId = item.type.record(item).enchant
        local enchant = enchantId and core.magic.enchantments.records[enchantId]
        return enchant ~= nil and enchant.type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect and
                enchant.type ~= core.magic.ENCHANTMENT_TYPE.CastOnStrike
    end)

    for _, item in ipairs(magicItems) do
        if not hidden[item.id] and getMagicItemCountAdjustedByQueue(item) > 0 then
            local enchantId = item.type.record(item).enchant
            local enchant = enchantId and core.magic.enchantments.records[enchantId]
            if filter(enchant.effects) then
                table.insert(result_items, item)
            end
        end
    end

    table.sort(result_items, function(a, b)
        if pinned[a.id] ~= pinned[b.id] then
            return pinned[a.id]
        end

        local ra = a.type.record(a.recordId)
        local rb = b.type.record(b.recordId)

        if ra.name ~= rb.name then
            return ra.name < rb.name
        end

        return a.id < b.id --id as tie breaker
    end)

    -- ----------- Combine Results ----------------------
    local result = {}
    for _, s in ipairs(result_spells) do
        table.insert(result, { spell = s })
    end
    for _, i in ipairs(result_items) do
        table.insert(result, { item = i })
    end

    return result
end

local function spellCategoryProvider(icon)
    if icon.name == C.SpellCategories.Other then
        return findMagics(otherSpellsFilter)
    else
        return findMagics(function(p) return isSpellOfType(p, icon.name) end)
    end
end

---@function
---@return table<number, Icon>
local function makeMagicIcons(magics)
    ---@type table<number, MagicIcon>
    local result = {}

    for _, v in ipairs(magics) do
        local data = { spell = v.spell, item = v.item, activate = activateMagic }
        if v.item then
            data.custom_count = getMagicItemCountAdjustedByQueue(v.item)
        end
        table.insert(result, MagicIcon:new(data))
    end

    return result
end

---@function
---@param icon SpellCategoryIcon
local function openSpellCategory(icon)
    if not wheel.ctx.shown then return end
    local spells = icon:provider()
    if #spells == 0 then return end
    wheel:show(true, function()
        return makeMagicIcons(icon:provider())
    end)
end

local function getSpellCategories()
    return {
        SpellCategoryIcon:new({ name = C.SpellCategories.Damage, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Combat, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Debuff, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Control, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Summon, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Other, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Util, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Transport, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Buff, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Restore, activate = openSpellCategory, provider = spellCategoryProvider }),
    }
end

local function getALLCategories()
    return {
        PotionCategoryIcon:new({ name = 'Health', activate = openPotionCategory, provider = potionCategoryProvider, quickUse = true }),
        PotionCategoryIcon:new({ name = 'Stamina', activate = openPotionCategory, provider = potionCategoryProvider, quickUse = true }),
        PotionCategoryIcon:new({ name = 'Combat', activate = openPotionCategory, provider = potionCategoryProvider }),
        PotionCategoryIcon:new({ name = 'Cure', activate = openPotionCategory, provider = potionCategoryProvider }),
        PotionCategoryIcon:new({ name = 'Poison', activate = openPotionCategory, provider = potionCategoryProvider }),

        SpellCategoryIcon:new({ name = C.SpellCategories.Damage, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Combat, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Debuff, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Util, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Other, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Buff, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Cure, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Summon, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Transport, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Control, activate = openSpellCategory, provider = spellCategoryProvider }),
        SpellCategoryIcon:new({ name = C.SpellCategories.Restore, activate = openSpellCategory, provider = spellCategoryProvider }),

        PotionCategoryIcon:new({ name = 'Other', activate = openPotionCategory, provider = potionCategoryProvider }),
        PotionCategoryIcon:new({ name = 'Buffs', activate = openPotionCategory, provider = potionCategoryProvider }),
        PotionCategoryIcon:new({ name = 'Magicka', activate = openPotionCategory, provider = potionCategoryProvider, quickUse = true }),
    }
end

local function setWheelMode(isOn, mode)
    if not isOn then wasToggled = false end
    if isOn == isWheelModeOn and currentWheelMode == mode then return end

    if lastUIMode ~= nil and not isWheelModeOn then return end

    isWheelModeOn = isOn

    if isWheelModeOn then
        I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
    else
        I.UI.setMode()
    end

    currentWheelMode = mode
    if currentWheelMode == 'potions' then
        wheel:show(isWheelModeOn, getPotionCategories)
    elseif currentWheelMode == 'magic' then
        wheel:show(isWheelModeOn, getSpellCategories)
    else
        wheel:show(isWheelModeOn, getALLCategories)
    end

    core.sendGlobalEvent('QW_UpdateWheelState', { state = isWheelModeOn, scale = C.getTimeScale(config.main.s_TimeMode) })
end

local function onUpdate()
    local wasModifiers = lastModifiers
    local wasMode = lastUIMode
    lastUIMode = I.UI.getMode()
    lastModifiers = tostring(input.isShiftPressed()) ..
            ':' .. tostring(input.isCtrlPressed()) .. ':' .. tostring(input.isAltPressed())
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

local function handleWheelAction(isPressed, wheelMode)
    local uiMode = I.UI.getMode()
    if isPressed then
        if uiMode ~= nil and uiMode ~= I.UI.MODE.Interface then return end
        if not isWheelModeOn then
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

local function Init()
    wheel:init(omwself)
    input.registerActionHandler(C.actionOpenOmniWheel, async:callback(handleOmniWheelAction))
    input.registerActionHandler(C.actionOpenPotionWheel, async:callback(handlePotionWheelAction))
    input.registerActionHandler(C.actionOpenMagicWheel, async:callback(handleMagicWheelAction))
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
        QW_UpdateWheelState = function(data)
            if not data then
                if wheel.ctx.shown then
                    wheel:markDirty()
                end
            else
                setWheelMode(data.wheelState, data.wheelMode)
            end
        end,
        OSSC_CastingState = function(evt)
            QuickCaster.CastingState({ isCasting = evt and evt.isCasting, delay = 0.3 })
        end,
    },
}
