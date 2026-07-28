---@omw-context player
local core = require('openmw.core')
local l10n = core.l10n('TPA_QuickWheel')

local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local CategoryIcon = require('scripts.TPABOBAP.QuickWheel.icons.category_icon')
local PotionIcon = require('scripts.TPABOBAP.QuickWheel.icons.potion_icon')

local iconMap = {
    Health = helpers.createTexture('icons/TPABOBAP/QuickWheel/category-health.png'),
    Stamina = helpers.createTexture('icons/TPABOBAP/QuickWheel/category-stamina.png'),
    Magicka = helpers.createTexture('icons/TPABOBAP/QuickWheel/category-magicka.png'),
    Poison = helpers.createTexture('icons/TPABOBAP/QuickWheel/category-poison.png'),
    Cure = helpers.createTexture('icons/TPABOBAP/QuickWheel/category-cure.png'),
    Combat = helpers.createTexture('icons/TPABOBAP/QuickWheel/category-combat.png'),
    Buffs = helpers.createTexture('icons/TPABOBAP/QuickWheel/category-buff.png'),
    Other = helpers.createTexture('icons/TPABOBAP/QuickWheel/category-other.png'),
}

---@class PotionCategoryIcon: CategoryIcon
local PotionCategoryIcon = CategoryIcon:new()

function PotionCategoryIcon:makeElement(p)
    self:make(p, iconMap)
    return self.element
end

function PotionCategoryIcon:getCount()
    local count = 0
    local items = self:provider()
    for i = 1, #items do
        count = count + items[i].count
    end
    return count
end

--- potions can be nil - uses provider in this case
function PotionCategoryIcon:makeTip(potions)
    local quickUse = self:getQuickUsePotion(potions)
    if quickUse then
        return PotionIcon.makeTipForItem(quickUse)
    end

    local tip = helpers.makeTooltip(
        l10n('Potion_Category_Title_' .. self.name),
        l10n('Potion_Category_Desc_' .. self.name)
    )
    tip.name = self:tipId()
    return tip
end

--- potions can be nil - uses provider in this case
function PotionCategoryIcon:getQuickUsePotion(potions)
    if not self.quickUse then return nil end
    if helpers.isShiftPressed() then
        potions = potions or self:provider()
        if #potions == 0 then return nil end
        return potions[1]
    end
    return nil
end
--- quickUse can be nil - uses provider in this case
function PotionCategoryIcon:tipId(quickUse)
    local id = self:Id()
    quickUse = quickUse or self:getQuickUsePotion()
    if quickUse then
        id = id .. ':' .. quickUse.id
    end
    return id
end

return PotionCategoryIcon
