local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local mwui = require('openmw.interfaces').MWUI

local v2 = util.vector2
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local Icon = require('scripts.TPABOBAP.QuickWheel.icons.base_icon')

---@class CategoryIcon: Icon
---@field name string
local CategoryIcon = Icon:new()

function CategoryIcon:makeElement(p)
    local count = #self:provider()
    self.element = ui.create {
        type = ui.TYPE.Text,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            text = self.name .. ' (' .. count .. ')', --TODO: l10n
            textSize = 14,
            textColor = util.color.rgb(0, 1, 0),
            position = p
        },
    }

    return self.element
end

function CategoryIcon:makeTip()
    return {
        name = self:tipId(),
        template = mwui.templates.boxSolid,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = ui.content {
            {
                name = 'padding',
                template = helpers.padding(4),
                content = ui.content {
                    {
                        name = 'text',
                        template = mwui.templates.textNormal,
                        props = {
                            text = self.name, --TODO: l10n
                            autoSize = true,
                        }
                    }
                },
            }
        }
    }
end

function CategoryIcon:tipId()
    return 'categoery:' .. self.name
end

return CategoryIcon