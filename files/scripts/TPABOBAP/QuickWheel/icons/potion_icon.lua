---@omw-context player
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local mwui = I.MWUI
local v2 = util.vector2
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local Icon = require('scripts.TPABOBAP.QuickWheel.icons.base_icon')

---@class PotionIcon: Icon
---@field item table
local PotionIcon = Icon:new()
local CENTER = v2(0.5, 0.5)
local ICON_SIZE_NORMAL = v2(64, 64)
local ICON_SIZE_OVER = v2(96, 96)
local TEXT_SIZE_NORMAL = 16
local TEXT_SIZE_OVER = 24

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
    for i = 1, #record.effects do
        local texture
        if i <= knownCount then
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
    local tip
    local IE = I.InventoryExtender
    local isOKIE, makeIETip = pcall(function() return IE and IE.Templates.MAGIC.itemTooltip end)
    isOKIE = false
    if isOKIE and IE and type(makeIETip) == 'function' then
        tip = makeIETip(item, false, IE.getContext())
        tip.props.anchor = CENTER
        tip.props.relativePosition = CENTER
    else
        local MW = I.MagicWindow
        local isOKMW, makeMWTip = pcall(function() return MW and MW.Templates.MAGIC.itemTooltip end)
        if isOKMW and type(makeMWTip) == 'function' then
            tip = makeMWTip(item)
            tip.props.anchor = CENTER
            tip.props.relativePosition = CENTER
        else
            --TODO: improve this tooltip
            local record = item.type.record(item.recordId)
            return helpers.makeTooltip(record.name)
        end
    end
    return tip
end

function PotionIcon:Id()
    return self.item.recordId
end

return PotionIcon