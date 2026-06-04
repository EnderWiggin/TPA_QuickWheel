---@omw-context player

local I = require('openmw.interfaces')
local core = require('openmw.core')
local omwself = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')

local mwui = I.MWUI
local v2 = util.vector2
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local config = require('scripts.TPABOBAP.QuickWheel.config')
local C = require('scripts.TPABOBAP.QuickWheel.constants')

local QuickCaster = {}
---@type CastInfo[]
local QuickCastQueue = {}
local isQuickCasting = false

---@alias QueuePositioning {relativePosition:openmw.util.Vector2, anchor:openmw.util.Vector2, arrange:openmw.ui.ALIGNMENT, reverse?: boolean}

---@type table<QueueWidgetPosition, QueuePositioning>
local QueuePositioningTypes = {
    [C.QueueWidgetPosition.BOTTOM_LEFT] = {
        relativePosition = v2(0, 0.9),
        anchor = v2(0, 1),
        arrange = ui.ALIGNMENT.Start,
        reverse = true,
    },
    [C.QueueWidgetPosition.BOTTOM_RIGHT] = {
        relativePosition = v2(1, 0.9),
        anchor = v2(1, 1),
        arrange = ui.ALIGNMENT.End,
        reverse = true,
    },
    [C.QueueWidgetPosition.CENTER] = {
        relativePosition = v2(0.5, 0.55),
        anchor = v2(0.5, 0),
        arrange = ui.ALIGNMENT.Center,
    },
    [C.QueueWidgetPosition.TOP_LEFT] = {
        relativePosition = v2(0, 0.1),
        anchor = v2(0, 0),
        arrange = ui.ALIGNMENT.Start,
    },
    [C.QueueWidgetPosition.TOP_RIGHT] = {
        relativePosition = v2(1, 0.1),
        anchor = v2(1, 0),
        arrange = ui.ALIGNMENT.End,
    },
}

local lastPositioning = config.magic.s_QueueWidgetPosition or C.QueueWidgetPosition.BOTTOM_LEFT
local Positioning = QueuePositioningTypes[lastPositioning]

local widget = ui.create {
    name = 'QuickCastQueue',
    layer = 'Windows',
    type = ui.TYPE.Container,
    props = {
        relativePosition = Positioning.relativePosition,
        anchor = Positioning.anchor,
        visible = false,
        autoSize = true,
    },
    content = ui.content {
        {
            name = 'padding',
            template = helpers.padding(10),
            content = ui.content {
                {
                    name = 'container',
                    type = ui.TYPE.Flex,
                    props = {
                        arrange = Positioning.arrange,
                    },
                    content = ui.content {}
                },
            }
        },
    },
}

local function updateWidget()
    ---@type openmw.ui.Layout
    local container = widget.layout.content['padding'].content['container']
    helpers.destroyContentChildren(container.content)
    local props = widget.layout.props
    props.visible = config.magic.b_ShowQueueWidget and #QuickCastQueue > 0
    if not props.visible then
        widget:update()
        return
    end

    local current = config.magic.s_QueueWidgetPosition or C.QueueWidgetPosition.BOTTOM_LEFT
    if current ~= lastPositioning then
        lastPositioning = current
        Positioning = QueuePositioningTypes[current]

        props.relativePosition = Positioning.relativePosition
        props.anchor = Positioning.anchor
        container.props.arrange = Positioning.arrange
    end

    for i, c in ipairs(QuickCastQueue) do
        local name = c.id
        if c.spell then
            name = c.spell.name
        elseif c.item then
            name = c.item.type.record(c.item.recordId).name
        end
        local item = {
            name = 'element_' .. i,
            type = ui.TYPE.Text,
            template = i == 1 and mwui.templates.textHeader or mwui.templates.textNormal,
            props = {
                autoSize = true,
                text = name,
                textSize = i == 1 and 24 or 18,
            }
        }
        if Positioning.reverse then
            container.content:insert(1, item)
        else
            container.content:add(item)
        end
    end
    widget:update()
end

---@alias CastInfo {item:openmw.Object, spell:openmw.core.Spell, id: string, ignoreUIMode: boolean}

---@param cast CastInfo
QuickCaster.quickCast = function(cast)
    local OSSC = I.OSSC
    local useOSSC = false --TODO: add option to use OSSC if available
    if useOSSC and OSSC then
        OSSC.triggerQuickCast(cast)
        --if cast.item then cast.item = cast.item.id end
        --if cast.spell then cast.spell = cast.spell.id end
        --omwself:sendEvent('OSSC_QuickCast', cast)
        isQuickCasting = true
    elseif I.MagExp_Player then
        isQuickCasting = true
        local delay = config.magic.n_MagicCastDelay or 0.35
        async:newUnsavableSimulationTimer(delay, function()
            QuickCaster.castUsingSF(cast)
        end)
    end
end

---@param cast CastInfo
QuickCaster.castUsingSF = function(cast)
    if QuickCaster.isCastSuccessful(cast) then
        isQuickCasting = true

        local hitObject
        if helpers.hasTouchEffects(cast) then
            local pitch = -(camera.getPitch() + camera.getExtraPitch())
            local yaw = camera.getYaw() + camera.getExtraYaw()
            local cosPitch = math.cos(pitch)
            local cameraDir = util.vector3(cosPitch * math.sin(yaw), cosPitch * math.cos(yaw), math.sin(pitch))
            local cameraPos = camera.getPosition()
            local endPos = cameraPos + cameraDir * (2 * C.TouchRange)
            local ray = nearby.castRay(cameraPos, endPos, { ignore = omwself })
            if ray.hit and ray.hitObject and (ray.hitPos - omwself.position):length() <= C.TouchRange then
                hitObject = ray.hitObject
            end
        end
        core.sendGlobalEvent('MagExp_CastRequest', {
            attacker = omwself,
            spellId = cast.spell and cast.spell.id or cast.item.type.record(cast.item).enchant,
            startPos = omwself.position + util.vector3(0, 0, 120),
            direction = omwself.rotation * util.vector3(0, 1, 0),
            showAllCastVfx = true,
            item = cast.item,
            hitObject = hitObject,
        })
        -- omwself:sendEvent('MagExp_StartQuickCast', {
        --     spellId = cast.spell and cast.spell.id or cast.item.type.record(cast.item).enchant,
        --     item    = cast.item,
        --     isFree  = false,
        -- })

        local cooldown = config.magic.n_MagicCastCooldown or 0.95
        async:newUnsavableSimulationTimer(cooldown, function()
            QuickCaster.CastingState({ isCasting = false })
        end)
    else
        isQuickCasting = false
        if cast.spell and I.MagExp_Player and I.MagExp_Player.consumeSpellCost then
            I.MagExp_Player.consumeSpellCost(cast.spell.id, nil)
        end
        ui.showMessage(core.getGMST('sMagicSkillFail'))
        --TODO: add sound variety based on spell school
        pcall(function() core.sound.playSound3d("spell failure illusion", omwself) end)
    end
end

---@return boolean?
QuickCaster.isCasting = function()
    return isQuickCasting or I.OSSC and I.OSSC.isCasting()
end

---@param evt {isCasting: boolean, delay?:number}
QuickCaster.CastingState = function(evt)
    local canCast = evt and not evt.isCasting
    isQuickCasting = not canCast
    if canCast and #QuickCastQueue > 0 then
        table.remove(QuickCastQueue, 1)
        updateWidget()
        if #QuickCastQueue > 0 then
            local cast = QuickCastQueue[1]
            isQuickCasting = true
            if not evt.delay or evt.delay <= 0 then
                QuickCaster.quickCast(cast)
            else
                async:newUnsavableSimulationTimer(evt.delay, function()
                    QuickCaster.quickCast(cast)
                end)
            end
        end
    end
end

---@param cast CastInfo
QuickCaster.isCastSuccessful = function(cast)
    local mwHelpersOk, mwHelpers = pcall(require, 'scripts.MagicWindowExtender.util.helpers')

    if not mwHelpersOk or not mwHelpers then return true end
    if cast.spell then
        local chance = mwHelpers.getSpellCastChance(cast.spell.id)
        if chance <= 0 then
            return false
        elseif chance >= 100 then
            return true
        else
            return math.random(0, 99) < chance
        end
    elseif cast.item then
        return true
    else
        return false
    end
end

---@return CastInfo[]
QuickCaster.GetQueue = function()
    return QuickCastQueue
end

---@param queue CastInfo[]
QuickCaster.SetQueue = function(queue)
    QuickCastQueue = queue
    updateWidget()
end

---@param cast CastInfo
QuickCaster.Enqueue = function(cast)
    table.insert(QuickCastQueue, cast)
    updateWidget()
end

return QuickCaster
