---@omw-context player

local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')

local async = require('openmw.async')
local storage = require('openmw.storage')

local main = storage.playerSection('TPA_QuickWheel/MainSettings')
local isAnimated = main:get('b_ShowWheelAnimation')
local isAnimatedChanged = false
main:subscribe(async:callback(function()
    isAnimated = main:get('b_ShowWheelAnimation')
    isAnimatedChanged = true
end))

local v2 = util.vector2

--------------------------------------------------------------------------
-- Wheel open/close animation
--------------------------------------------------------------------------
-- Icons spawn near the centre and spiral outward to the exact positions
-- wheel.lua already laid out for them; closing plays it in reverse. We only
-- wrap Wheel:show / Wheel:update / Wheel:onOffsetChanged and drive the tween
-- from onUpdate -- QuickWheel's own files are untouched.
--
-- Timing comes from core.getRealTime(), not onUpdate's dt: dt is *simulation*
-- time, and QuickWheel has a TimeModes.Paused mode where it would be 0.
local ANIM_OPEN_DURATION = 0.18
local ANIM_CLOSE_DURATION = 0.13
local ANIM_SWAP_DURATION = 0.22  -- ring -> sub-ring; a touch slower, it's the showpiece
local ANIM_START_RADIUS = 0.12   -- fraction of final radius at t=0
local ANIM_SWEEP = math.pi * 0.5 -- quarter turn travelled on the way out
local ANIM_OUT_RADIUS = 2.6      -- outgoing ring's final radius, in units of its own
local ANIM_OUT_SWEEP = math.pi * 0.35
local BG_ALPHA = 0.5             -- wheel.lua's dim backdrop
local BIND_ALPHA = 0.2           -- wheel.lua's keybind box
local OUT_CONTAINER = 'qwp_outgoing'

---@type {t:number, dir:number, closing:boolean, swap:boolean, last:number, icons:table[], binds:table[], out:table[]}
local anim = { t = 0, dir = 0, closing = false, swap = false, last = 0, icons = {}, binds = {}, out = {} }

---nil-safe replacement for content[name], which raises rather than returning nil
local function childByName(content, name)
    if not content then return nil end
    local i = content:indexOf(name)
    return i and content[i] or nil
end

local function resolveRefs(w)
    if not w.widget then return nil end
    local content = w.widget.layout.content
    return {
        widget = w.widget,
        bg = content[1],
        icons = childByName(content, 'icons'),
        binds = childByName(content, 'binds'),
        tooltip = childByName(content, 'tooltip'),
        out = childByName(content, OUT_CONTAINER), -- survives a hot reload
    }
end

---easeOutCubic: fast out of the centre, gentle arrival
local function ease(t)
    local inv = 1 - t
    return 1 - inv * inv * inv
end

---The keybind label opts out of alpha inheritance, so it needs its own handle.
local function bindTitleProps(layout)
    local text = childByName(layout.content, 'text')
    local title = text and childByName(text.content, 'title')
    return title and title.props
end

---Cache each widget's resting polar coords, so the tween can rebuild its
---position without knowing anything about wheel.lua's radius or sector maths.
local function captureBases(w)
    anim.icons = {}
    anim.binds = {}

    if w.items then
        for i = 1, #w.items do
            local el = w.items[i].element
            local p = el and el.props and el.props.position
            if p then
                anim.icons[#anim.icons + 1] = { props = el.props, r = p:length(), a = math.atan2(p.y, p.x) }
            end
        end
    end

    local r = resolveRefs(w)
    local binds = r and r.binds and r.binds.content
    if binds then
        for i = 1, #binds do
            local layout = binds[i]
            local p = layout.props and layout.props.position
            if p then
                anim.binds[#anim.binds + 1] = {
                    props = layout.props,
                    title = bindTitleProps(layout),
                    r = p:length(),
                    a = math.atan2(p.y, p.x),
                }
            end
        end
    end
end

local function outgoingContainer(w)
    local r = resolveRefs(w)
    if not r then return nil end
    if not r.out then
        local layout = {
            name = OUT_CONTAINER,
            props = {
                relativeSize = v2(1, 1),
                relativePosition = v2(0.5, 0.5),
                anchor = v2(0.5, 0.5),
            },
            content = ui.content {},
        }
        w.widget.layout.content:insert(#w.widget.layout.content, layout)
        r.out = layout
    end
    return r.out
end

local function clearOutgoing(w)
    anim.out = {}
    anim.swap = false
    local r = resolveRefs(w)
    local out = r and r.out
    if not out then return end
    -- Plain layouts, not Elements: dropping the references is enough.
    while #out.content > 0 do table.remove(out.content) end
    out.props.alpha = 1
end

---Move the current ring's widgets out of the containers Wheel:update() is about
---to wipe, so the old ring survives long enough to fly off screen.
local function beginSwap(w)
    -- A swap during a swap: the previous ring is already gone, drop it rather
    -- than leaving it frozen mid-flight.
    clearOutgoing(w)

    local r = resolveRefs(w)
    local out = outgoingContainer(w)
    if not (r and out) then return end
    anim.out = {}

    local function steal(container, isBind)
        local children = container and container.content
        if not children then return end
        while #children > 0 do
            local child = table.remove(children)
            local p = child.props and child.props.position
            if p then
                anim.out[#anim.out + 1] = {
                    props = child.props,
                    title = isBind and bindTitleProps(child) or nil,
                    r = p:length(),
                    a = math.atan2(p.y, p.x),
                }
            end
            out.content:add(child)
        end
    end

    steal(r.icons, false)
    steal(r.binds, true)

    anim.swap = #anim.out > 0
    if anim.swap then out.props.alpha = 1 end
end

local function applyAnim(w)
    local widget = w.widget
    if not widget then return end

    local e = ease(anim.t)
    local scale = ANIM_START_RADIUS + (1 - ANIM_START_RADIUS) * e
    local sweep = ANIM_SWEEP * (1 - e)

    for _, icon in ipairs(anim.icons) do
        local r, a = icon.r * scale, icon.a + sweep
        icon.props.position = v2(r * math.cos(a), r * math.sin(a))
    end

    for _, bind in ipairs(anim.binds) do
        local r, a = bind.r * scale, bind.a + sweep
        bind.props.position = v2(r * math.cos(a), r * math.sin(a))
        bind.props.alpha = BIND_ALPHA * e
        if bind.title then bind.title.alpha = e end
    end

    -- The outgoing ring keeps travelling the same way the incoming one settles:
    -- further out, same rotational direction, fading as it leaves the screen.
    if anim.swap then
        local radius = 1 + (ANIM_OUT_RADIUS - 1) * e
        local outSweep = -ANIM_OUT_SWEEP * e
        for _, old in ipairs(anim.out) do
            local r, a = old.r * radius, old.a + outSweep
            old.props.position = v2(r * math.cos(a), r * math.sin(a))
            if old.title then old.title.alpha = 1 - e end
        end
    end

    local r = resolveRefs(w)
    if not r then return end
    -- Mid-swap the wheel is neither opening nor closing, so the backdrop holds.
    local bg = anim.swap and BG_ALPHA or (BG_ALPHA * e)
    if r.bg and r.bg.props then r.bg.props.alpha = bg end
    if r.icons then r.icons.props.alpha = e end
    if r.tooltip then r.tooltip.props.alpha = e end
    if r.out then r.out.props.alpha = anim.swap and (1 - e) or 0 end
end

---@param self WheelContext
---@param show boolean
local function onBeforeShow(self, show)
    if not isAnimated then return end
    local wasShown = self.shown
    anim.closing = (not show) and wasShown and anim.t > 0

    -- Re-showing an already-open wheel means a new ring: a sub-menu, or a
    -- wheel-mode switch. Rescue the old ring before Wheel:update() destroys it.
    if show and wasShown and self.widget then
        beginSwap(self)
    end
end
---@param self WheelContext
---@param show boolean
local function onAfterShow(self, wasShown, show)
    if not isAnimated then
        if isAnimatedChanged then
            clearOutgoing(self)
            anim.dir = 0
            anim.t = 1

            applyAnim(self)
            self.widget:update()
        end
        isAnimatedChanged = false
        return
    end
    isAnimatedChanged = false

    if show then
        -- Both a fresh open and a ring swap replay the spiral from the centre.
        if not wasShown or anim.swap then
            anim.t = 0
            anim.dir = 1
            anim.last = core.getRealTime()
        end
    elseif anim.closing then
        clearOutgoing(self) -- a half-flown ring must not linger over the fade-out
        anim.dir = -1
        anim.last = core.getRealTime()
        self.widget.layout.props.visible = true
    else
        clearOutgoing(self)
        anim.dir = 0
        anim.t = 0
    end

    applyAnim(self)
end

---@param self WheelContext
local function onAfterUpdate(self)
    if not isAnimated then return end
    -- Only a shown wheel rebuilds its icons, so only then are the positions
    -- resting values worth caching. Mid-close they're already tweened.
    if self.shown then captureBases(self) end
    if anim.closing then self.widget.layout.props.visible = true end
    if anim.dir ~= 0 then
        applyAnim(self)
    end
end

---@param self WheelContext
local function tick(self)
    if not isAnimated then return end
    if anim.dir == 0 then return end
    if not self.widget then
        anim.dir = 0
        return
    end

    local now = core.getRealTime()
    local dt = now - anim.last
    anim.last = now
    if dt <= 0 then return end
    if dt > 0.1 then dt = 0.1 end -- a stall shouldn't teleport the wheel

    local duration = ANIM_CLOSE_DURATION
    if anim.dir > 0 then
        duration = anim.swap and ANIM_SWAP_DURATION or ANIM_OPEN_DURATION
    end
    anim.t = util.clamp(anim.t + anim.dir * dt / duration, 0, 1)
    applyAnim(self)

    if anim.dir > 0 and anim.t >= 1 then
        anim.dir = 0
        if anim.swap then clearOutgoing(self) end
    elseif anim.dir < 0 and anim.t <= 0 then
        anim.dir = 0
        anim.closing = false
        self.widget.layout.props.visible = false
    end

    self.widget:update()
end

return {
    onBeforeShow = onBeforeShow,
    onAfterShow = onAfterShow,
    onAfterUpdate = onAfterUpdate,
    tick = tick,
}
