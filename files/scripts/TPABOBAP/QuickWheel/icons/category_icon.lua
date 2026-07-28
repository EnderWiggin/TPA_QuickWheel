---@omw-context player
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local omwConstants = require('scripts.omw.mwui.constants')
local mwui = require('openmw.interfaces').MWUI
local l10n = core.l10n('TPA_QuickWheel')
local v2 = util.vector2
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local Icon = require('scripts.TPABOBAP.QuickWheel.icons.base_icon')

---@class CategoryIcon: Icon
---@field public name string
---@field public provider fun():any[]
---@field public quickUse boolean

local UNKNOWN = helpers.createTexture('icons/TPABOBAP/QuickWheel/magic-spell.png')
local CENTER = v2(0.5, 0.5)
local ICON_SIZE_NORMAL = v2(128, 128)
local ICON_SIZE_OVER = v2(160, 160)
local TEXT_SIZE_NORMAL = omwConstants.textNormalSize
local TEXT_SIZE_OVER = util.round(1.5 * TEXT_SIZE_NORMAL)

---@class CategoryIcon: Icon
local CategoryIcon = Icon:new()

function CategoryIcon:make(p, iconMap)
    local count = self:getCount()

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
                    resource = iconMap[self.name] or UNKNOWN,
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
end

function CategoryIcon:getCount() return #self:provider() end

function CategoryIcon:update(selected)
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

function CategoryIcon:makeTip()
    local tip = helpers.makeTooltip(
        l10n('Category_Title_' .. self.name),
        l10n('Category_Desc_' .. self.name)
    )
    tip.name = self:tipId()
    return tip
end

function CategoryIcon:Id()
    return 'category:' .. self.name
end

return CategoryIcon
