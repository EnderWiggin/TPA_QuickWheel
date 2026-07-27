---@omw-context player
local core = require('openmw.core')
local l10n = core.l10n('TPA_QuickWheel')


local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local CategoryIcon = require('scripts.TPABOBAP.QuickWheel.icons.category_icon')

local iconMap = {
    Restore = 'icons/TPABOBAP/QuickWheel/magic-category-restore.png',
    Util = 'icons/TPABOBAP/QuickWheel/magic-category-util.png',
    Debuff = 'icons/TPABOBAP/QuickWheel/magic-category-debuff.png',
    Damage = 'icons/TPABOBAP/QuickWheel/magic-category-damage.png',
    Combat = 'icons/TPABOBAP/QuickWheel/magic-category-combat.png',
    Buff = 'icons/TPABOBAP/QuickWheel/magic-category-buff.png',
    Other = nil,
    Transport = 'icons/TPABOBAP/QuickWheel/magic-category-travel.png',
    Control = 'icons/TPABOBAP/QuickWheel/magic-category-control.png',
    Summon = 'icons/TPABOBAP/QuickWheel/magic-category-summon.png',
}

---@class SpellCategoryIcon: CategoryIcon
local SpellCategoryIcon = CategoryIcon:new()

function SpellCategoryIcon:makeElement(p)
    self:make(p, iconMap)
    return self.element
end

function SpellCategoryIcon:makeTip()
    local tip = helpers.makeTooltip(
        l10n('Magic_Category_Title_' .. self.name),
        l10n('Magic_Category_Desc_' .. self.name)
    )
    tip.name = self:tipId()
    return tip
end

return SpellCategoryIcon
