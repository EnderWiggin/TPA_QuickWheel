local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local mwui = require('openmw.interfaces').MWUI
local l10n = core.l10n('TPA_QuickWheel')

local v2 = util.vector2
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local Icon = require('scripts.TPABOBAP.QuickWheel.icons.base_icon')

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

---@class CategoryIcon: Icon
---@field name string
local CategoryIcon = Icon:new()

function CategoryIcon:makeElement(p)
    local count = 0
    for _, v in ipairs(self:provider()) do
        count = count + v.count
    end

    self.element = ui.create {
        name = "wheel_icon",
        type = ui.TYPE.Widget,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            size = v2(128, 128),
            position = p
        },
        content = ui.content {
            {
                name = "item_icon",
                type = ui.TYPE.Image,
                props = {
                    relativePosition = v2(0.5, 0.5),
                    anchor = v2(0.5, 0.5),
                    resource = helpers.createTexture(iconMap[self.name]),
                    relativeSize = v2(0.5, 0.5),
                },
            },
            {
                name = 'item_count',
                template = mwui.templates.textNormal,
                props = {
                    relativePosition = v2(0.8, 0.85),
                    anchor = v2(1, 1),
                    text = tostring(count),
                    textSize = 16,
                },
            }
        }
    }

    return self.element
end

function CategoryIcon:update(selected)
    local props = self.element.layout.props
    local content = self.element.layout.content
    if selected then
        props.size = v2(160, 160)
        content.item_count.props.textSize = 24
    else
        props.size = v2(128, 128)
        content.item_count.props.textSize = 16
    end
    self.element:update()
end

function CategoryIcon:makeTip()
    local tip = helpers.makeTooltip(
            l10n('Category_Title_' .. self.name),
            l10n('Category_Desc_' .. self.name)
    )
    tip.name = self:tipId()
    return tip
end

function CategoryIcon:tipId()
    return 'categoery:' .. self.name
end

return CategoryIcon