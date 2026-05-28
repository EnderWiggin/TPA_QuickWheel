local I = require('openmw.interfaces')
local core = require('openmw.core')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local auxUi = require('openmw_aux.ui')

local v2 = util.vector2
local pi2 = 2 * math.pi

local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')

local uiScale = 1.25 --TODO: get from settings?
local screenSize = ui.screenSize()
local R = 0.85 * math.floor(math.min(screenSize.x, screenSize.y) / uiScale) / 2
local DEAD_ZONE = v2(R / 5, 0.95 * R / 0.85)
local SIZE = v2(screenSize.x / uiScale, screenSize.y / uiScale)
local CENTER = v2(SIZE.x / 2, SIZE.y / 2)

local MWUIConstants = require('scripts.omw.mwui.constants')

---delay update when dirty by 2 frames
local DIRTY_DELAY = 2

local Wheel = {}

Wheel.ctx = {
    shown = false,

    ---@type table<number, Icon>
    items = nil,
    selected = 0,
    widget = nil,
    target = nil,
    dirty = 0,
    lastOffset = nil,

    ---@function
    ---@return table<number, Icon>
    itemProvider = nil,
}

local function getSectorIdx(c, n, z)
    local x = -c.y
    local y = c.x
    local r = math.sqrt(x * x + y * y)

    if r < z.x or r > z.y then
        return 0
    end

    local step = pi2 / n
    x = x / r
    y = y / r
    local a = math.atan2(y, x)

    if a < 0 then a = a + pi2 end

    a = a + step / 2
    if a > pi2 then a = a - pi2 end

    return 1 + math.floor(a / step)
end

local function makeWheel(self)
    return ui.create {
        layer = 'Windows',
        type = ui.TYPE.Widget,
        props = {
            relativeSize = v2(1, 1),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            visible = false,
        },
        events = {
            mouseMove = async:callback(function(evt, _)
                self:onMouseMove(evt)
            end),
            mouseClick = async:callback(function(_, _)
                self:onMouseClick()
            end),
        },
        content = ui.content({
            {
                type = ui.TYPE.Image,
                props = {
                    resource = MWUIConstants.whiteTexture,
                    color = util.color.rgb(0, 0, 0),
                    alpha = 0.35,
                    relativeSize = v2(1, 1),
                    relativePosition = v2(0.5, 0.5),
                    anchor = v2(0.5, 0.5),
                },
            },
        }),
    }
end

local function circle_pos(n, i, r)
    local a = 2 * i * math.pi / n - math.pi / 2
    return v2(r * math.cos(a), r * math.sin(a))
end

function Wheel:init(target)
    self.ctx.widget = makeWheel(self)
    self.ctx.target = target
end

---@function
---@param show boolean
---@param provider fun():table<number, Icon>
function Wheel:show(show, provider)
    if self.ctx.shown == show then return end

    self.ctx.shown = show
    self.ctx.itemProvider = provider
    self:update()
end

function Wheel:update ()
    local wheel = self.ctx.widget
    wheel.layout.props.visible = self.ctx.shown
    if self.ctx.shown then
        local container = self:getIconContainer()
        if container then
            if not container.content then container.content = ui.content {} end
            container = container.content
            local wdg = table.remove(container)
            while wdg do
                auxUi.deepDestroy(wdg)
                wdg = table.remove(container)
            end
        else
            container = ui.content {}
            wheel.layout.content:add({
                props = {
                    relativeSize = v2(1, 1),
                    relativePosition = v2(0.5, 0.5),
                    anchor = v2(0.5, 0.5),
                },
                content = container
            })
        end

        self.ctx.items = type(self.ctx.itemProvider) == 'function' and self.ctx.itemProvider() or {}

        local n = #self.ctx.items

        if self.ctx.lastOffset then
            self.ctx.selected = getSectorIdx(self.ctx.lastOffset, n, DEAD_ZONE)
        else
            self.ctx.selected = 0
        end

        for i, p in ipairs(self.ctx.items) do
            --container:add(ui.create(txt(i, circle_pos(n, i - 1, r))))
            --container:add(ui.create(icon(p, circle_pos(n, i - 1, R))))
            container:add(p:makeElement(circle_pos(n, i - 1, R)))
        end

        self:updateIcons()
    else
        self.ctx.selected = 0
    end

    wheel:update()
end

---called each frame from player.lua
function Wheel:checkDirty()
    if self.ctx.dirty <= 0 then return end

    if self.ctx.dirty > 0 then
        self.ctx.dirty = self.ctx.dirty - 1
    end

    if self.ctx.dirty == 0 then
        self:update()
    end
end

function Wheel:onMouseMove(evt)
    local p = evt.offset - CENTER
    self.ctx.lastOffset = p
    local container = self:getIconContainer().content
    if not container then return end
    local selectedIdx = getSectorIdx(p, #container, DEAD_ZONE)
    self.ctx.selected = selectedIdx
    --print("Move: ", helpers.deepPrint(p) .. ' Sector: ', selectedIdx, #container)
    self:updateIcons()
end

function Wheel:updateIcons()
    for i, v in ipairs(self.ctx.items) do
        v:update(i == self.ctx.selected)
    end
end

function Wheel:getIconContainer()
    local wheel = self.ctx.widget
    if not wheel.layout.content then return nil end
    if #wheel.layout.content < 2 then return nil end

    return wheel.layout.content[2]
end

function Wheel:onMouseClick()
    if self.ctx.shown and self.ctx.selected > 0 and self.ctx.items then
        self.ctx.items[self.ctx.selected]:activate()

        self.ctx.dirty = DIRTY_DELAY
    end
end

return Wheel