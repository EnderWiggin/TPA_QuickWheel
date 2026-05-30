local I = require('openmw.interfaces')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local _, self = pcall(require, 'openmw.self')
local mwui = I.MWUI

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
    local effectRecord = core.magic.effects.records[effectId] or (I.MagicWindow and I.MagicWindow.Spells.getCustomEffect(effectId))
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

return Helpers