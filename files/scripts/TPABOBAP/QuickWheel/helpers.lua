local I = require('openmw.interfaces')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')

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
    return Helpers.createTexture(effectRecord.icon)
end

Helpers.destroyContentChildren = function(content)
    local wdg = table.remove(content)
    while wdg do
        auxUi.deepDestroy(wdg)
        wdg = table.remove(content)
    end
end

return Helpers