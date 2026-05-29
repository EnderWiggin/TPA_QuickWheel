local ui = require('openmw.ui')
local util = require('openmw.util')

local v2 = util.vector2

---@class Icon
local Icon = {

}

---@function
---@param o Icon
function Icon:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Icon:makeElement(p)
    local item = self.item
    local recordName = item.type.record(item.recordId).name
    self.element = ui.create {
        type = ui.TYPE.Text,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            text = tostring(recordName) .. ' (' .. tostring(item.count) .. ')',
            textSize = 14,
            textColor = util.color.rgb(0, 1, 0),
            position = p
        },
    }

    return self.element
end

function Icon:update(selected)
    local props = self.element.layout.props
    if selected then
        props.textSize = 24
        props.textColor = util.color.rgb(1, 0, 1)
    else
        props.textSize = 14
        props.textColor = util.color.rgb(0, 1, 0)
    end
    self.element:update()
end

function Icon:activate()
   
end

function Icon:makeTip()
   return nil
end

function Icon:tipId()
    return nil
end

return Icon