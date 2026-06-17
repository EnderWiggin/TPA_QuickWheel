---@omw-context player
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local mwui = require('openmw.interfaces').MWUI
local l10n = core.l10n('TPA_QuickWheel')
local input = require('openmw.input')

local v2 = util.vector2
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local CategoryIcon = require('scripts.TPABOBAP.QuickWheel.icons.category_icon')
local PotionIcon = require('scripts.TPABOBAP.QuickWheel.icons.potion_icon')

local iconMap = {
    Health = 'icons/TPABOBAP/QuickWheel/category-health.png',
    Stamina = 'icons/TPABOBAP/QuickWheel/category-stamina.png',
    Magicka = 'icons/TPABOBAP/QuickWheel/category-magicka.png',
    Poison = 'icons/TPABOBAP/QuickWheel/category-poison.png',
    Cure = 'icons/TPABOBAP/QuickWheel/category-cure.png',
    Combat = 'icons/TPABOBAP/QuickWheel/category-combat.png',
    Buffs = 'icons/TPABOBAP/QuickWheel/category-buff.png',
    Other = 'icons/TPABOBAP/QuickWheel/category-other.png',
}
local CENTER = v2(0.5, 0.5)
local ICON_SIZE_NORMAL = v2(128, 128)
local ICON_SIZE_OVER = v2(160, 160)
local TEXT_SIZE_NORMAL = 16
local TEXT_SIZE_OVER = 24

---@class PotionCategoryIcon: CategoryIcon
local PotionCategoryIcon = CategoryIcon:new()

function PotionCategoryIcon:makeElement(p)
    local count = 0
    for _, v in ipairs(self:provider()) do
        count = count + v.count
    end

    self.element = {
        name = "wheel_icon",
        type = ui.TYPE.Widget,
        props = {
            relativePosition = CENTER,
            anchor = CENTER,
            size = ICON_SIZE_NORMAL,
            position = p
        },
        content = ui.content {
            {
                name = "item_icon",
                type = ui.TYPE.Image,
                props = {
                    relativePosition = CENTER,
                    anchor = CENTER,
                    resource = helpers.createTexture(iconMap[self.name]),
                    relativeSize = CENTER,
                },
            },
            {
                name = 'item_count',
                template = mwui.templates.textNormal,
                props = {
                    relativePosition = v2(0.8, 0.85),
                    anchor = v2(1, 1),
                    text = tostring(count),
                    textSize = TEXT_SIZE_NORMAL,
                },
            }
        }
    }

    return self.element
end

function PotionCategoryIcon:update(selected)
    local props = self.element.props
    local content = self.element.content
    if selected then
        props.size = ICON_SIZE_OVER
        content['item_count'].props.textSize = TEXT_SIZE_OVER
    else
        props.size = ICON_SIZE_NORMAL
        content['item_count'].props.textSize = TEXT_SIZE_NORMAL
    end
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
    local id = 'category:' .. self.name
    quickUse = quickUse or self:getQuickUsePotion()
    if quickUse then
        id = id .. ':' .. quickUse.id
    end
    return id
end

return PotionCategoryIcon
