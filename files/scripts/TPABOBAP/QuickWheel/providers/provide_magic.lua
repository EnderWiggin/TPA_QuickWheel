---@omw-context player

local I = require('openmw.interfaces')
local core = require('openmw.core')
local omwself = require('openmw.self')
local types = require('openmw.types')
local auxUtil = require('openmw_aux.util')

local C = require('scripts.TPABOBAP.QuickWheel.constants')
local config = require('scripts.TPABOBAP.QuickWheel.config')
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local MagicIcon = require('scripts.TPABOBAP.QuickWheel.icons.magic_icon')
local QuickCaster = require('scripts.TPABOBAP.QuickWheel.quick_caster')

---@param icon MagicIcon
local function activateMagic(icon)
    local justEquip = helpers.isAltPressed()
    local enqueue = helpers.isShiftPressed()
    local quickCast = helpers.isCtrlPressed()

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
        local data = { item = icon.item, spell = icon.spell, id = icon:tipId() }
        if quickCast then
            omwself:sendEvent('QW_UpdateWheelState', { wheelState = false })
            local queue = QuickCaster.GetQueue()
            if #queue > 1 then QuickCaster.SetQueue({ queue[1] }) end
        end

        if not QuickCaster.isCasting() then
            QuickCaster.SetQueue({ data })
            QuickCaster.quickCast(data)
        else
            QuickCaster.Enqueue(data)
        end
    else
        QuickCaster.SetQueue({})
        omwself:sendEvent('QW_UpdateWheelState', { wheelState = false })
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

return {
    makeIcons = makeMagicIcons,
    provider = spellCategoryProvider,
    QuickCaster = QuickCaster,
}
