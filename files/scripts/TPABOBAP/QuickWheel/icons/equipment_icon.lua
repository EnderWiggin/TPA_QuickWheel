---@omw-context player
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local omwConstants = require('scripts.omw.mwui.constants')
local mwui = I.MWUI
local v2 = util.vector2
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local Icon = require('scripts.TPABOBAP.QuickWheel.icons.base_icon')

---@class EquipmentIcon: Icon
---@field items openmw.Object[]
---@field needsCount boolean
local EquipmentIcon = Icon:new()
local CENTER = v2(0.5, 0.5)
local TEXT_SIZE_NORMAL = omwConstants.textNormalSize
local TEXT_SIZE_OVER = util.round(1.5 * TEXT_SIZE_NORMAL)
local ICON_SIZE_NORMAL = v2(1, 1) * (4 * TEXT_SIZE_NORMAL)
local ICON_SIZE_OVER = v2(1, 1) * (6 * TEXT_SIZE_NORMAL)

function EquipmentIcon:makeElement(p)
    local item = self:item()
    local record = item.type.record(item.recordId)
    local count = self:count()
    self.needsCount = count > 1 or #self.items > 1

    local icons = ui.content {
        {
            name = "item_icon",
            type = ui.TYPE.Image,
            props = {
                resource = helpers.createTexture(record.icon),
                relativePosition = CENTER,
                anchor = CENTER,
                relativeSize = CENTER,
            },
        }
    }
    local equipped = self:equipped()
    local magic = record.enchant
    if equipped or magic then
        local magicString = magic and '_magic' or ''
        local postString = (equipped and '_equip') or (magicString ~= '' and '') or '_none'
        local bgrPath = 'textures/menu_icon' .. magicString .. postString .. '.dds'
        icons:insert(1, {
            name = 'itemBackground',
            type = ui.TYPE.Image,
            props = {
                resource = helpers.createTexture(bgrPath, v2(40, 40), v2(2, 2)),
                relativePosition = CENTER,
                anchor = CENTER,
                relativeSize = CENTER * 1.3,
            }
        })
    end

    if self.needsCount then
        icons:add({
            name = 'item_count',
            template = mwui.templates.textNormal,
            props = {
                relativePosition = v2(1, 1),
                anchor = v2(1, 1),
                text = tostring(count),
                textSize = TEXT_SIZE_NORMAL,
            },
        })
    end

    self.element = {
        name = "wheel_icon:" .. item.id,
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

function EquipmentIcon:update(selected)
    local props = self.element.props
    local content = self.element.content
    if selected then
        props.size = ICON_SIZE_OVER
        if self.needsCount then
            content['item_count'].props.textSize = TEXT_SIZE_OVER
        end
    else
        props.size = ICON_SIZE_NORMAL
        if self.needsCount then
            content['item_count'].props.textSize = TEXT_SIZE_NORMAL
        end
    end
end

function EquipmentIcon:item() return self.items[1] end

function EquipmentIcon:count()
    local count = 0
    --TODO: option(?) to show count as uses for the tools (picks/probes/repair)
    for i = 1, #self.items do
        local item = self.items[i]
        count = count + item.count
    end
    return count
end

function EquipmentIcon:equipped()
    for i = 1, #self.items do
        local item = self.items[i]
        if helpers.isEquipped(item) then return true end
    end
    return false
end

function EquipmentIcon:makeTip()
    return EquipmentIcon.makeTipForItem(self:item())
end

function EquipmentIcon.makeTipForItem(item)
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

function EquipmentIcon:Id()
    return 'equipment:' .. self:item().id
end

return EquipmentIcon
