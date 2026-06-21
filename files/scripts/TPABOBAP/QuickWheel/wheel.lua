---@omw-context player
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local auxUi = require('openmw_aux.ui')
local omwself = require('openmw.self')
local storage = require('openmw.storage')

local bindingSection = storage.playerSection('OMWInputBindings')
local l10n = core.l10n('TPA_QuickWheel')
local MWUI = I.MWUI.templates
local v2 = util.vector2
local pi2 = 2 * math.pi

local config = require('scripts.TPABOBAP.QuickWheel.config')
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local C = require('scripts.TPABOBAP.QuickWheel.constants')

local R
local DEAD_ZONE
local CENTER
local MIN_SECTORS = 8
local CONTROLLER = false

local MWUIConstants = require('scripts.omw.mwui.constants')
local TextDefault = MWUI.textNormal.props.textColor
local TextHighlight = MWUI.textHeader.props.textColor

---delay update when dirty by 2 frames
local DIRTY_DELAY = 2

---@alias WheelKeybinds table<openmw.input.KeyCode, string>

---@class WheelContext
---@field widget openmw.ui.Element
---@field keybinds WheelKeybinds?
---@field name string?
local Wheel = {
    shown = false,

    ---@type table<number, Icon>
    items = nil,
    selected = 0,
    target = nil,
    dirty = 0,
    lastOffset = nil,
    ---@type nil | string | boolean
    tipId = nil,

    ---@type IconProvider?
    itemProvider = nil,
    isKeybindingActive = false,
    ---@type openmw.ui.Element?
    keybindTutorial = nil,
}

local forbiddenKeys = {}

local function updateForbiddenKeys()
    forbiddenKeys = {
        [input.KEY.Escape] = true,    -- closes wheel/menus
        [input.KEY.Backspace] = true, -- clears current keybind, maybe make it configurable?

        -- modifier keys are used by the wheel - ignore them
        [input.KEY.LeftShift] = true,
        [input.KEY.RightShift] = true,
        [input.KEY.LeftCtrl] = true,
        [input.KEY.RightCtrl] = true,
        [input.KEY.LeftAlt] = true,
        [input.KEY.RightAlt] = true,

        -- most Fn keys do some stuff, ignore them
        [input.KEY.F1] = true,
        [input.KEY.F3] = true,
        [input.KEY.F4] = true,
        [input.KEY.F5] = true,
        [input.KEY.F6] = true,
        [input.KEY.F7] = true,
        [input.KEY.F8] = true,
        [input.KEY.F9] = true,
        [input.KEY.F10] = true,
        [input.KEY.F11] = true,
        [input.KEY.F12] = true,
    }
    for _, key in pairs(C.WheelOpenKeyBind) do
        local bind = bindingSection:get(key)
        if bind and bind.device == 'keyboard' then
            forbiddenKeys[bind.button] = true
        end
    end
end

local function getForbiddenKeyLine()
    local codes = {}
    for k, _ in pairs(forbiddenKeys) do
        table.insert(codes, k)
    end
    table.sort(codes)

    local keys = {}
    for i = 1, #codes do
        table.insert(keys, input.getKeyName(codes[i]))
    end

    return table.concat(keys, ', ')
end

---@type {key:openmw.input.KeyCode, id:string}?
local pendingBind = nil

---@param self WheelContext
local function checkPendingBind(self)
    if not pendingBind then return end
    self.keybinds = self.keybinds or {}
    local reversed = helpers.transposeTable(self.keybinds)

    local was = reversed and reversed[pendingBind.id]
    if was then self.keybinds[was] = nil end
    self.keybinds[pendingBind.key] = pendingBind.id
    pendingBind = nil

    omwself:sendEvent('QW_SetWheelKeybinds', { name = self.name, binds = self.keybinds })
end

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

---@param self WheelContext
---@return openmw.ui.Element
local function makeKeybindButton(self)
    local element = ui.create {
        name = 'reset_button',
        template = MWUI.boxSolid,
        props = {},
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    { props = { size = v2(8, 0), }, },
                    {
                        template = MWUI.textNormal,
                        props = {
                            text = l10n('BTN_BIND_KEYS'),
                            textColor = TextDefault,
                            multiline = true,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                        },
                    },
                    { props = { size = v2(8, 0), }, },
                }
            }
        },
        events = {},
    }
    element.layout.events.focusGain = async:callback(function()
        element.layout.content[1].content[2].props.textColor = TextHighlight
        if self.shown then element:update() end
    end)
    element.layout.events.focusLoss = async:callback(function()
        element.layout.content[1].content[2].props.textColor = TextDefault
        if self.shown then element:update() end
    end)
    element.layout.events.mousePress = async:callback(function()
        ambient.playSound('menu click', { scale = false })
    end)
    element.layout.events.mouseRelease = async:callback(function()
        self:toggleKeybindMode()
    end)

    return element
end

---@param self WheelContext
local function makeWheel(self)
    local wheel = ui.create {
        name = 'QuickWheel',
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
                if config.shouldUseController() then return end
                CONTROLLER = false
                self:onOffsetChanged(evt.offset - CENTER)
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
                name = 'binds',
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

    wheel.layout.content:add(makeKeybindButton(self))

    return wheel
end

---@param key openmw.input.KeyCode
---@param pos openmw.util.Vector2
---@param n integer
local function makeKeybindIcon(key, pos, n)
    local keyName = input.getKeyName(key)
    return {
        template = MWUI.boxSolid,
        name = 'wheel-keybind-' .. n,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            alpha = 0.2,
            position = pos,
        },
        content = ui.content {
            {
                name = 'text',
                template = helpers.padding(4),
                content = ui.content {
                    {
                        name = 'title',
                        template = MWUI.textNormal,
                        props = {
                            text = keyName,
                            autoSize = keyName:len() > 2,
                            size = v2(15, 15),
                            textSize = 16,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                            inheritAlpha = false,
                        }
                    },
                }
            }
        }
    }
end

local function circle_pos(n, i, r)
    if MIN_SECTORS and n < MIN_SECTORS then n = MIN_SECTORS end
    local a = 2 * i * math.pi / n - math.pi / 2
    return v2(r * math.cos(a), r * math.sin(a))
end

function Wheel:init(target)
    self.widget = makeWheel(self)
    self.target = target
end

---@alias IconProvider fun():Icon[]

---@function
---@param show boolean
---@param opts {name: string, keybinds: WheelKeybinds?, provider: IconProvider? }?
function Wheel:show(show, opts)
    --if self.shown == show then return end

    if show then
        updateSizeConfigs()
    else
        self.isKeybindingActive = false
        self:destroyKeybindTutorial()
        pendingBind = nil
    end

    self.dirty = 0
    self.shown = show
    self.itemProvider = opts and opts.provider
    self.name = opts and opts.name
    self.keybinds = opts and opts.keybinds
    self:update()
end

function Wheel:update()
    local wheel = self.widget
    wheel.layout.props.visible = self.shown
    if self.shown then
        local iconContainer = wheel.layout.content['icons'].content
        local bindsContainer = wheel.layout.content['binds'].content
        helpers.destroyContentChildren(iconContainer)
        helpers.destroyContentChildren(bindsContainer)

        self.items = type(self.itemProvider) == 'function' and self.itemProvider() or {}

        local n = #self.items
        local binds = helpers.transposeTable(self.keybinds)
        if self.lastOffset then
            self.selected = getSectorIdx(self.lastOffset, n, DEAD_ZONE)
        else
            self.selected = 0
        end

        for i = 1, #self.items do
            local item = self.items[i]
            iconContainer:add(item:makeElement(circle_pos(n, i - 1, R)))
            local key = binds and binds[item:Id()]
            if key then
                bindsContainer:add(makeKeybindIcon(key, circle_pos(n, i - 1, R * 0.75), i))
                binds[key] = nil
            end
        end

        self:updateIcons()
    else
        self.selected = 0
    end

    wheel:update()
end

function Wheel:markDirty()
    self.dirty = DIRTY_DELAY
end

---called each frame from player.lua
function Wheel:checkDirty()
    if self.dirty <= 0 then return end

    if self.dirty > 0 then
        self.dirty = self.dirty - 1
    end

    if self.dirty == 0 then
        checkPendingBind(self)
        self.tipId = false --false is used to make sure tip will get re-evaluated
        self:update()
    end
end

---@param o openmw.util.Vector2
function Wheel:onControllerOffsetChanged(o)
    local r = (DEAD_ZONE.x + 2 * DEAD_ZONE.y) / 3
    if o:length() < config.main.n_ControllerDeadZone then
        if not CONTROLLER then return end
        self:onOffsetChanged(v2(0, 0))
        return
    end
    CONTROLLER = true
    self:onOffsetChanged(o:normalize() * r)
end

---@param offset openmw.util.Vector2
function Wheel:onOffsetChanged(offset)
    self.lastOffset = offset
    self.selected = getSectorIdx(offset, #self.items, DEAD_ZONE)
    self:updateIcons()
end

function Wheel:updateIcons()
    local tipId = self.tipId
    local newTipId
    local tip
    for i = 1, #self.items do
        local v = self.items[i]
        if i == self.selected then
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
        self.tipId = newTipId
        local wheel = self.widget
        local place = wheel.layout.content['tooltip']

        helpers.destroyContentChildren(place.content)

        if tip then
            place.content:add(tip)
        end
        wheel:update()
    end
end

---@private
---@param evt openmw.input.KeyboardEvent
function Wheel:activateKeyBind(evt)
    local bind = self.keybinds and self.keybinds[evt.code]
    if not bind then return end

    local items = self.items
    for i = 1, #items do
        if items[i]:Id() == bind then
            items[i]:activate()
            self:markDirty()
            return
        end
    end
end

---@private
---@param evt openmw.input.KeyboardEvent
function Wheel:makeKeyBind(evt)
    if self.selected <= 0 then return end

    local item = self.items[self.selected]
    local id = item and item:Id()
    if not id then return end

    if evt.code == input.KEY.Backspace then
        pendingBind = nil
        local reversed = helpers.transposeTable(self.keybinds)
        local was = reversed and reversed[id]
        if was then
            self.keybinds[was] = nil
            self:markDirty()
            omwself:sendEvent('QW_SetWheelKeybinds', { name = self.name, binds = self.keybinds })
        end
        return
    elseif forbiddenKeys[evt.code] then
        pendingBind = nil
        return
    end

    pendingBind = { key = evt.code, id = id }
    self:markDirty()
end

function Wheel:onMouseClick()
    if self.shown and self.dirty <= 0 and self.selected > 0 and self.items then
        self.items[self.selected]:activate()
        self:markDirty()
    end
end

---@param evt openmw.input.KeyboardEvent
function Wheel:onKeyPress(evt)
    if self.isKeybindingActive then
        if evt.code == input.KEY.Escape then
            self:toggleKeybindMode()
            return
        end
        self:makeKeyBind(evt)
    else
        self:activateKeyBind(evt)
    end
end

---@private
function Wheel:makeKeybindTutorial()
    local content = self.widget and self.widget.layout.content
    if content and not self.keybindTutorial then
        local opts = { backspace = input.getKeyName(input.KEY.Backspace), forbidden = getForbiddenKeyLine() }

        self.keybindTutorial = ui.create({
            template = MWUI.boxSolid,
            props = {
                relativePosition = v2(0, 1),
                anchor = v2(0, 1),
                position = v2(5, -5)
            },
            content = ui.content {
                {
                    name = 'padding',
                    template = helpers.padding(4),
                    content = ui.content {
                        {
                            type = ui.TYPE.Flex,
                            props = {
                                arrange = ui.ALIGNMENT.Center,
                            },
                            content = ui.content {
                                {
                                    name = 'title',
                                    template = MWUI.textHeader,
                                    props = {
                                        text = l10n('TIP_BIND_KEYS_TITLE'),
                                        autoSize = true,
                                        textAlignH = ui.ALIGNMENT.Center,
                                    }
                                },
                                {
                                    name = 'body',
                                    template = MWUI.textNormal,
                                    props = {
                                        text = l10n('TIP_BIND_KEYS_DESC', opts),
                                        autoSize = false,
                                        multiline = true,
                                        wordWrap = true,
                                        size = v2(300, 200),
                                        textAlignV = ui.ALIGNMENT.Center,
                                        textAlignH = ui.ALIGNMENT.Center,
                                    }
                                }
                            }
                        }
                    },
                }
            }
        })
        content:add(self.keybindTutorial)
    end
end

---@private
function Wheel:destroyKeybindTutorial()
    local content = self.widget and self.widget.layout.content
    if content and self.keybindTutorial then
        table.remove(content, content:indexOf(self.keybindTutorial))
        auxUi.deepDestroy(self.keybindTutorial)
        self.keybindTutorial = nil
    end
end

function Wheel:toggleKeybindMode()
    self.isKeybindingActive = not self.isKeybindingActive
    if self.isKeybindingActive then
        updateForbiddenKeys()
        self:makeKeybindTutorial()
    else
        self:destroyKeybindTutorial()
    end
    self:markDirty()
end

return Wheel
