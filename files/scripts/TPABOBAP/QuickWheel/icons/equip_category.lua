---@omw-context player
local core = require('openmw.core')
local l10n = core.l10n('TPA_QuickWheel')


local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local CategoryIcon = require('scripts.TPABOBAP.QuickWheel.icons.category_icon')

local iconMap = {
    Weapon = helpers.createTexture('icons/TPABOBAP/QuickWheel/equip-category-weapon.png'),
    Armor = helpers.createTexture('icons/TPABOBAP/QuickWheel/equip-category-armor.png'),
    Clothes = helpers.createTexture('icons/TPABOBAP/QuickWheel/equip-category-clothes.png'),
    Tools = helpers.createTexture('icons/TPABOBAP/QuickWheel/equip-category-tools.png'),
}

---@class EquipCategoryIcon: CategoryIcon
local EquipCategoryIcon = CategoryIcon:new()

function EquipCategoryIcon:makeElement(p)
    self:make(p, iconMap)
    return self.element
end

function EquipCategoryIcon:makeTip()
    local tip = helpers.makeTooltip(
        l10n('Equip_Category_Title_' .. self.name),
        l10n('Equip_Category_Desc_' .. self.name)
    )
    tip.name = self:tipId()
    return tip
end

return EquipCategoryIcon
