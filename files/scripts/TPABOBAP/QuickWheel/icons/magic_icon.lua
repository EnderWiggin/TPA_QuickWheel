---@omw-context player
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local mwui = I.MWUI
local v2 = util.vector2
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local Icon = require('scripts.TPABOBAP.QuickWheel.icons.base_icon')

---@class MagicIcon: Icon
---@field spell? openmw.core.Spell
---@field item? openmw.Object
---@field custom_count? number
local MagicIcon = Icon:new()

local CENTER = v2(0.5, 0.5)
local SIDE = 0.25
local ICON_SZ = v2(SIDE, SIDE)

function MagicIcon:makeElement(p)
    local effects
    local icon
    local count

    if self.spell then
        effects = self.spell.effects
        --TODO: add spell cost and/or chance to count?
        icon = 'icons/TPABOBAP/QuickWheel/magic-spell.png'
    elseif self.item then
        local record = self.item.type.record(self.item.recordId)
        local enchantId = record.enchant
        local enchant = enchantId and core.magic.enchantments.records[enchantId]
        effects = enchant.effects
        icon = record.icon

        if enchant.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
            count = tostring(self.item.count)
        else
        end
    end

    local icons = ui.content {

    }

    if icon then
        icons:add({
            name = "item_icon",
            type = ui.TYPE.Image,
            props = {
                relativePosition = v2(0.5, 0.5),
                anchor = v2(0.5, 0.5),
                resource = helpers.createTexture(icon),
                relativeSize = v2(1, 1),
                --alpha = 0.5,
                color = util.color.rgb(0.7, 0.7, 0.7),
            }
        })
    end

    local n = #effects
    local ny = util.round(math.sqrt(n))
    local nx = math.ceil(n / ny) - 1
    local c = CENTER - v2(nx / 2, (ny - 1) / 2) * SIDE

    for i, effect in ipairs(effects) do
        local k = i - 1
        local texture = helpers.effectIconTexture(effect.id)
        icons:add({
            name = "effect_" .. i,
            type = ui.TYPE.Image,
            props = {
                relativePosition = c + v2(math.floor(k / ny), k % ny) * SIDE,
                anchor = CENTER,
                resource = texture,
                relativeSize = ICON_SZ,
                --position = v2(0, 0)
            },
        })
    end
    icons:add({
        name = 'item_count',
        template = mwui.templates.textNormal,
        props = {
            relativePosition = v2(1, 1),
            anchor = v2(1, 1),
            text = tostring(count),
            textSize = 14,
            visible = not not count
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

function MagicIcon:update(selected)
    local props = self.element.layout.props
    local content = self.element.layout.content
    if selected then
        props.size = v2(96, 96)
        content.item_count.props.textSize = 21
    else
        props.size = v2(64, 64)
        content.item_count.props.textSize = 21
    end
    self.element:update()
end

function MagicIcon:makeTip()
    if self.spell then
        return MagicIcon.makeTipForSpell(self.spell)
    end
    if self.item then
        return MagicIcon.makeTipForItem(self.item)
    end
end

function MagicIcon.makeTipForSpell(spell)
    local MW = I.MagicWindow
    local isOK, makeMWTip = pcall(function() return MW and MW.Templates.MAGIC.spellTooltip end)
    local tip
    if isOK and type(makeMWTip) == 'function' then
        tip = makeMWTip(spell.id)
        tip.props.anchor = v2(0.5, 0.5)
        tip.props.relativePosition = v2(0.5, 0.5)
    else
        --TODO: improve this tooltip
        return helpers.makeTooltip(spell.name)
    end
    return tip
end

function MagicIcon.makeTipForItem(item)
    local tip
    local IE = I.InventoryExtender
    local isOKIE, makeIETip = pcall(function() return IE and IE.Templates.MAGIC.itemTooltip end)
    if isOKIE and type(makeIETip) == 'function' then
        tip = makeIETip(item, false, IE.getContext())
        tip.props.anchor = v2(0.5, 0.5)
        tip.props.relativePosition = v2(0.5, 0.5)
    else
        local MW = I.MagicWindow
        local isOKMW, makeMWTip = pcall(function() return MW and MW.Templates.MAGIC.itemTooltip end)
        if isOKMW and type(makeMWTip) == 'function' then
            tip = makeMWTip(item)
            tip.props.anchor = v2(0.5, 0.5)
            tip.props.relativePosition = v2(0.5, 0.5)
        else
            --TODO: improve this tooltip
            local record = self.item.type.record(self.item.recordId)
            return helpers.makeTooltip(record.name)
        end
    end
    return tip
end

function MagicIcon:tipId()
    return 'magic:' .. ((self.spell and self.spell.id) or (self.item and self.item.id))
end

return MagicIcon