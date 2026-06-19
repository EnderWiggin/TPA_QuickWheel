---@omw-context player

local I = require('openmw.interfaces')
local core = require('openmw.core')
local omwself = require('openmw.self')
local types = require('openmw.types')

local C = require('scripts.TPABOBAP.QuickWheel.constants')
local config = require('scripts.TPABOBAP.QuickWheel.config')
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local PotionIcon = require('scripts.TPABOBAP.QuickWheel.icons.potion_icon')

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

---@param icon PotionIcon
local function usePotion(icon)
    local potion = icon.item or icon
    core.sendGlobalEvent('UseItem', {
        object = potion,
        actor = omwself,
    })
end

---@param icon PotionIcon
local function usePoison(icon)
    local potion = icon.item or icon
    if config.potions.b_QuickApplyPoison and helpers.isShiftPressed() then
        core.sendGlobalEvent('Toxicology_ConfirmApply', {
            actor = omwself.object,
            potion = potion,
        })
        omwself:sendEvent('QW_UpdateWheelState', { wheelState = false })
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

return {
    usePotion = usePotion,
    usePoison = usePoison,
    makeIcons = makePotionIcons,
    provider = potionCategoryProvider,
}
