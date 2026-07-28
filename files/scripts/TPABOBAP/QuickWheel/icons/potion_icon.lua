---@omw-context player
local ui = require('openmw.ui')
local util = require('openmw.util')
local omwConstants = require('scripts.omw.mwui.constants')
local I = require('openmw.interfaces')
local mwui = I.MWUI
local v2 = util.vector2
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local Icon = require('scripts.TPABOBAP.QuickWheel.icons.base_icon')

---@class PotionIcon: Icon
---@field item table
local PotionIcon = Icon:new()
local CENTER = v2(0.5, 0.5)
local TEXT_SIZE_NORMAL = omwConstants.textNormalSize
local TEXT_SIZE_OVER = util.round(1.5 * TEXT_SIZE_NORMAL)
local ICON_SIZE_NORMAL = v2(1, 1) * (4 * TEXT_SIZE_NORMAL)
local ICON_SIZE_OVER = v2(1, 1) * (6 * TEXT_SIZE_NORMAL)

function PotionIcon:makeElement(p)
    local item = self.item
    ---@type openmw.types.PotionRecord
    local record = item.type.record(item.recordId)

    local icons = ui.content {
        {
            name = "item_icon",
            type = ui.TYPE.Image,
            props = {
                relativePosition = CENTER,
                anchor = CENTER,
                resource = helpers.createTexture(record.icon),
                relativeSize = CENTER,
            },
        }
    }

    local knownCount = helpers.getKnownAlchemyEffectCount(true)
    local known
    if I.TPA_AlchemyRedone and I.TPA_AlchemyRedone.isEnabled() then
        known = I.TPA_AlchemyRedone.getKnownEffectFlagsForItem(item)
    end
    for i = 1, #record.effects do
        local texture
        local isKnown = i <= knownCount
        if known then isKnown = known[i] end

        if isKnown then
            texture = helpers.effectIconTexture(record.effects[i].id)
        else
            texture = helpers.createTexture('icons/TPABOBAP/QuickWheel/unknown-effect.png')
        end
        icons:add({
            name = "effect_" .. i,
            type = ui.TYPE.Image,
            props = {
                relativePosition = v2(math.floor((i - 1) / 3), (i - 1) % 3) * 0.25,
                anchor = v2(0, 0),
                resource = texture,
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
            textSize = TEXT_SIZE_NORMAL,
        },
    })

    self.element = {
        name = "wheel_icon",
        type = ui.TYPE.Widget,
        props = {
            relativePosition = CENTER,
            anchor = CENTER,
            size = ICON_SIZE_NORMAL,
            position = p
        },
        content = icons
    }

    return self.element
end

function PotionIcon:update(selected)
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

function PotionIcon:makeTip()
    return PotionIcon.makeTipForItem(self.item)
end

function PotionIcon.makeTipForItem(item)
    return helpers.makeItemTooltip(item)
end

function PotionIcon:Id()
    return 'potion:' .. self.item.recordId
end

return PotionIcon
