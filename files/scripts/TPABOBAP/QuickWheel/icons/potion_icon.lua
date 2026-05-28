local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')

local v2 = util.vector2
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local Icon = require('scripts.TPABOBAP.QuickWheel.icons.base_icon')

---@class PotionIcon: Icon
---@field item table
local PotionIcon = Icon:new()

local function circle_pos(n, i, r)
    local a = 2 * i * math.pi / n - math.pi / 2
    return v2(r * math.cos(a), r * math.sin(a))
end

function PotionIcon:makeElement2(p)
    local item = self.item
    local record = item.type.record(item.recordId)
    local recordName = record.name

    self.element = ui.create {
        type = ui.TYPE.Image,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            resource = helpers.createTexture(record.icon),
            size = v2(96, 96),
            position = p
        },
    }

    return self.element
end

function PotionIcon:makeElement(p)
    local item = self.item
    local record = item.type.record(item.recordId)
    local recordName = record.name

    local icons = ui.content {
        ui.create {
            name = "item_icon",
            type = ui.TYPE.Image,
            props = {
                relativePosition = v2(0.5, 0.5),
                anchor = v2(0.5, 0.5),
                resource = helpers.createTexture(record.icon),
                relativeSize = v2(0.5, 0.5),
            },
        }

    }

    local n = #record.effects
    for i, effect in ipairs(record.effects) do
        icons:add(ui.create {
            name = "background",
            type = ui.TYPE.Image,
            props = {
                relativePosition = v2(0.5, 0.5),
                anchor = v2(0.5, 0.5),
                resource = helpers.effectIconTexture(effect.id),
                --size = v2(16, 16),
                relativeSize = v2(0.25, 0.25),
                position = circle_pos(n, i - 1, 16)
            },
        })
    end

    self.element = ui.create {
        name = "wheel_icon",
        type = ui.TYPE.Widget,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            size = v2(64, 64),
            position = p
        },
        content = icons
    }

    return self.element
end

function PotionIcon:update(selected)
    local props = self.element.layout.props
    if selected then
        props.size = v2(96, 96)
    else
        props.size = v2(64, 64)
    end
    self.element:update()
end

return PotionIcon