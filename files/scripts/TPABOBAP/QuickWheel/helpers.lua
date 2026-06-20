---@omw-context player
local I = require('openmw.interfaces')
local core = require('openmw.core')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local _, self = pcall(require, 'openmw.self')
local mwui = I.MWUI

local C = require('scripts.TPABOBAP.QuickWheel.constants')

local v2 = util.vector2

local Helpers = {}

Helpers.deepPrint = function(tbl, indent)
    if type(tbl) ~= 'table' then return tostring(tbl) end
    indent = indent or 0
    local toprint = string.rep(" ", indent) .. "{\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint .. k .. " = "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\n"
        elseif (type(v) == "table") then
            toprint = toprint .. Helpers.deepPrint(v, indent + 2) .. ",\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    return toprint
end

---@generic K
---@generic V
---@param tbl table<K, V>?
---@return table<V, K>?
Helpers.transposeTable = function(tbl)
    if not tbl then
        return nil
    end
    local result = {}
    for k, v in pairs(tbl) do
        result[v] = k
    end
    return result
end

local TEXTURES = {}
Helpers.createTexture = function(path, size, offset)
    size = size or v2(0, 0)
    offset = offset or v2(0, 0)
    if TEXTURES[path]
        and TEXTURES[path][size.x] and TEXTURES[path][size.x][size.y]
        and TEXTURES[path][size.x][size.y][offset.x] and TEXTURES[path][size.x][size.y][offset.x][offset.y] then
        return TEXTURES[path][size.x][size.y][offset.x][offset.y]
    else
        local tex = ui.texture { path = path, size = size, offset = offset }
        TEXTURES[path] = TEXTURES[path] or {}
        TEXTURES[path][size.x] = TEXTURES[path][size.x] or {}
        TEXTURES[path][size.x][size.y] = TEXTURES[path][size.x][size.y] or {}
        TEXTURES[path][size.x][size.y][offset.x] = TEXTURES[path][size.x][size.y][offset.x] or {}
        TEXTURES[path][size.x][size.y][offset.x][offset.y] = tex
        return tex
    end
end

Helpers.effectIconTexture = function(effectId)
    local effectRecord = core.magic.effects.records[effectId] or
        (I.MagicWindow and I.MagicWindow.Spells.getCustomEffect(effectId))
    return effectRecord and Helpers.createTexture(effectRecord.icon)
end

Helpers.destroyContentChildren = function(content)
    local wdg = table.remove(content)
    while wdg do
        auxUi.deepDestroy(wdg)
        wdg = table.remove(content)
    end
end

Helpers.padding = function(size)
    size = util.vector2(1, 1) * size
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                props = {
                    size = size,
                },
            },
            {
                external = { slot = true },
                props = {
                    position = size,
                    relativeSize = util.vector2(1, 1),
                },
            },
            {
                props = {
                    position = size,
                    relativePosition = util.vector2(1, 1),
                    size = size,
                },
            },
        }
    }
end

Helpers.makeTooltip = function(title, body)
    local content = ui.content {
        {
            name = 'title',
            template = mwui.templates.textHeader,
            props = {
                text = title,
                autoSize = true,
                textAlignH = ui.ALIGNMENT.Center,
            }
        },
    }

    if type(body) == 'string' then
        body = {
            name = 'body',
            template = mwui.templates.textNormal,
            props = {
                text = body,
                autoSize = true,
                multiline = true,
                textAlignH = ui.ALIGNMENT.Center,
            }
        }
    end

    if body then content:add(body) end

    return {
        template = mwui.templates.boxSolid,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = ui.content {
            {
                name = 'padding',
                template = Helpers.padding(4),
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            arrange = ui.ALIGNMENT.Center,
                        },
                        content = content
                    }
                },
            }
        }
    }
end

Helpers.getKnownAlchemyEffectCount = function(isPotion)
    if not self or not self.type or not self.type.stats or not self.type.stats.skills or not self.type.stats.skills.alchemy then
        return 0
    end

    local alchemy = self.type.stats.skills.alchemy(self).base
    local threshold = core.getGMST('fWortChanceValue')
    local visibleEffectCount = math.floor(alchemy / threshold)
    if isPotion then
        visibleEffectCount = visibleEffectCount * 2
    end
    return visibleEffectCount
end

local function hasWord(str, word)
    if string.find(str, "[^%a]+" .. word .. "[^%a]+")
        or string.find(str, "^" .. word .. "[^%a]+")
        or string.find(str, "[^%a]+" .. word .. "$")
        or string.find(str, "^" .. word .. "$")
    then
        return true
    end
    return false
end

local function startsWith(text, prefix)
    return text:sub(1, #prefix) == prefix
end

local function getEffectType(id)
    for type, values in pairs(C.MagicEffectTypes) do
        if values[id] == true then return type end
    end

    if startsWith(id, 'summon') or hasWord(id, 'summon') then
        return 'Summon'
    elseif startsWith(id, 'bound') or hasWord(id, 'bound') then
        return 'Bound'
    end

    return 'Unknown'
end

---@param effectParams openmw.core.MagicEffectWithParams
Helpers.categorizeMagicEffectWithParams = function(effectParams)
    local effect = core.magic.effects.records[effectParams.id]
    local isCustom = false
    if not effect then
        effect = I.MagicWindow.Spells.getCustomEffect(effectParams.id)
        if not effect then
            --fill with defaults
            ---@diagnostic disable-next-line: missing-fields
            effect = { harmful = false }
        end
        isCustom = true
    end

    local result = {
        id = effectParams.id,
        range = effectParams.range,
        harmful = effect.harmful,
        type = getEffectType(effectParams.id),
        custom = isCustom
    }

    return result
end


---@param cast CastInfo
Helpers.hasTouchEffects = function(cast)
    ---@type openmw.core.MagicEffectWithParams[]
    local effects

    if cast.spell then
        effects = cast.spell.effects
    elseif cast.item then
        local record = cast.item.type.record(cast.item.recordId)
        local enchant = record.enchant and core.magic.enchantments.records[record.enchant]
        effects = enchant and enchant.effects
    end

    if not effects then return false end

    for i = 1, #effects do
        if effects[i].range == core.magic.RANGE.Touch then
            return true
        end
    end

    return false
end

---
---@param spellId string
---@param actor table
---@param opts? {isGodMode?: boolean, cost?: number}
---@return number
Helpers.getSpellCastChance = function(spellId, actor, opts)
    local isGodMode = opts and opts.isGodMode
    if isGodMode then return 100 end

    local MagExp = (I.MagExp_Player or I.MagExp)
    local sfHelpers = MagExp and MagExp.Helpers
    if sfHelpers then
        return sfHelpers.getSpellCastChance(spellId, actor, opts)
    else
        ---@type boolean, table
        local mwHelpersOk, mwHelpers = pcall(require, 'scripts.MagicWindowExtender.util.helpers')
        if not mwHelpersOk or not mwHelpers then return 100 end
        return mwHelpers.getSpellCastChance(spellId)
    end

    return 100
end

local isShiftPressed = false
local isCtrlPressed = false
local isAltPressed = false

---@return string
Helpers.updateModifiers = function()
    local leftTrigger = input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft) > 0.5
    local rightTrigger = input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight) > 0.5

    isShiftPressed = input.isShiftPressed() or (leftTrigger and not rightTrigger)
    isCtrlPressed = input.isCtrlPressed() or (rightTrigger and not leftTrigger)
    isAltPressed = input.isAltPressed() or (leftTrigger and rightTrigger)

    return tostring(isShiftPressed) .. ':' .. tostring(isCtrlPressed) .. ':' .. tostring(isAltPressed)
end
Helpers.isShiftPressed = function()
    return isShiftPressed
end

Helpers.isCtrlPressed = function()
    return isCtrlPressed
end

Helpers.isAltPressed = function()
    return isAltPressed
end

return Helpers
