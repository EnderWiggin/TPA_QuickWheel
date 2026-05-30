local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')

local v2 = util.vector2
local pi2 = 2 * math.pi

local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')

local R
local DEAD_ZONE
local CENTER
local MIN_SECTORS = 8

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
    ---@type nil | string | boolean
    tipId = nil,

    ---@function
    ---@return table<number, Icon>
    itemProvider = nil,
}

local function updateSizeConfigs()
    local windowsIndex = ui.layers.indexOf('Windows')
    local layer = ui.layers[windowsIndex]
    local screenSize = ui.screenSize()
    local uiScale = screenSize.x / layer.size.x
    
    R = 0.85 * math.floor(math.min(screenSize.x, screenSize.y) / uiScale) / 2
    DEAD_ZONE = v2(R / 5, 0.95 * R / 0.85)
    CENTER = screenSize * 0.5 / uiScale

    --TODO: get from settings and allow for it to be nil?
    MIN_SECTORS = 8
end

updateSizeConfigs()

local function getSectorIdx(c, n, z)
    if MIN_SECTORS and n < MIN_SECTORS then n = MIN_SECTORS end
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
                    alpha = 0.5,
                    relativeSize = v2(1, 1),
                    relativePosition = v2(0.5, 0.5),
                    anchor = v2(0.5, 0.5),
                },
            },
            {
                name = 'icons',
                props = {
                    relativeSize = v2(1, 1),
                    relativePosition = v2(0.5, 0.5),
                    anchor = v2(0.5, 0.5),
                },
                content = ui.content {}
            },
            {
                name = 'tooltip',
                props = {
                    relativeSize = v2(1, 1),
                    relativePosition = v2(0.5, 0.5),
                    anchor = v2(0.5, 0.5),
                },
                content = ui.content {}
            }
        }),
    }
end

local function circle_pos(n, i, r)
    if MIN_SECTORS and n < MIN_SECTORS then n = MIN_SECTORS end
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
    --if self.ctx.shown == show then return end

    if show then
        updateSizeConfigs()
    end

    self.ctx.dirty = 0
    self.ctx.shown = show
    self.ctx.itemProvider = provider
    self:update()
end

function Wheel:update ()
    local wheel = self.ctx.widget
    wheel.layout.props.visible = self.ctx.shown
    if self.ctx.shown then
        local container = wheel.layout.content.icons.content
        helpers.destroyContentChildren(container)

        self.ctx.items = type(self.ctx.itemProvider) == 'function' and self.ctx.itemProvider() or {}

        local n = #self.ctx.items

        if self.ctx.lastOffset then
            self.ctx.selected = getSectorIdx(self.ctx.lastOffset, n, DEAD_ZONE)
        else
            self.ctx.selected = 0
        end

        for i, p in ipairs(self.ctx.items) do
            container:add(p:makeElement(circle_pos(n, i - 1, R)))
        end

        self:updateIcons()
    else
        self.ctx.selected = 0
    end

    wheel:update()
end

function Wheel:markDirty()
    self.ctx.dirty = DIRTY_DELAY
end

---called each frame from player.lua
function Wheel:checkDirty()
    if self.ctx.dirty <= 0 then return end

    if self.ctx.dirty > 0 then
        self.ctx.dirty = self.ctx.dirty - 1
    end

    if self.ctx.dirty == 0 then
        self.ctx.tipId = false --false is used to make sure tip will get re-evaluated
        self:update()
    end
end

function Wheel:onMouseMove(evt)
    local p = evt.offset - CENTER
    self.ctx.lastOffset = p
    local wheel = self.ctx.widget
    local container = wheel.layout.content.icons.content
    if not container then return end
    local selectedIdx = getSectorIdx(p, #container, DEAD_ZONE)
    self.ctx.selected = selectedIdx
    --print("Move: ", helpers.deepPrint(p) .. ' Sector: ', selectedIdx, #container)
    self:updateIcons()
end

function Wheel:updateIcons()
    local tipId = self.ctx.tipId
    local newTipId
    local tip
    for i, v in ipairs(self.ctx.items) do
        if i == self.ctx.selected then
            v:update(true)
            newTipId = v:tipId()
            if newTipId ~= tipId then
                tip = v:makeTip()
            end
        else
            v:update(false)
        end
    end

    if newTipId ~= tipId then
        self.ctx.tipId = newTipId
        local wheel = self.ctx.widget
        local place = wheel.layout.content.tooltip

        helpers.destroyContentChildren(place.content)

        if tip then
            place.content:add(tip)
        end
        wheel:update()
    end
end

function Wheel:onMouseClick()
    if self.ctx.shown and self.ctx.dirty <= 0 and self.ctx.selected > 0 and self.ctx.items then
        self.ctx.items[self.ctx.selected]:activate()
        self:markDirty()
    end
end

return Wheel