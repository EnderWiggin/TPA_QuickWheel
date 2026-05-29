local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local mwui = require('openmw.interfaces').MWUI

local v2 = util.vector2
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local Icon = require('scripts.TPABOBAP.QuickWheel.icons.base_icon')

---@class PotionIcon: Icon
---@field item table
local PotionIcon = Icon:new()

function PotionIcon:makeElement(p)
    local item = self.item
    local record = item.type.record(item.recordId)

    local icons = ui.content {
        {
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

    for i, effect in ipairs(record.effects) do
        local x = math.floor((i - 1) / 3)
        local y = (i - 1) % 3
        local c = v2(0.25 * x, 0.125 + y * 0.25)
        icons:add({
            name = "effect_" .. i,
            type = ui.TYPE.Image,
            props = {
                relativePosition = c,
                anchor = v2(0, 0.5),
                resource = helpers.effectIconTexture(effect.id),
                relativeSize = v2(0.25, 0.25),
                position = v2(0, 0)
            },
        })
    end

    icons:add({
        name = 'item_count',
        template = mwui.templates.textNormal,
        props = {
            relativePosition = v2(0.75, 0.75),
            anchor = v2(1, 1),
            text = tostring(item.count),
            textSize = 14,
        },
    })

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
    local content = self.element.layout.content
    if selected then
        props.size = v2(96, 96)
        content.item_count.props.textSize = 21
    else
        props.size = v2(64, 64)
        content.item_count.props.textSize = 14
    end
    self.element:update()
end

function PotionIcon:makeTip()
    --TODO: make separate tip if no IE detected
    local I = require('openmw.interfaces')
    local IE = I.InventoryExtender
    local tip = IE.Templates.MAGIC.itemTooltip(self.item, false, IE.getContext())
    tip.props.anchor = v2(0.5, 0.5)
    tip.props.relativePosition = v2(0.5, 0.5)
    return tip
end

function PotionIcon:tipId()
    return self.item.id
end

return PotionIcon