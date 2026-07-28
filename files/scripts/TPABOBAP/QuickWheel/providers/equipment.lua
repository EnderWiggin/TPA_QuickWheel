---@omw-context player

local I = require('openmw.interfaces')
local core = require('openmw.core')
local player = require('openmw.self')
local types = require('openmw.types')
local ambient = require('openmw.ambient')
local async = require('openmw.async')

local C = require('scripts.TPABOBAP.QuickWheel.constants')
local config = require('scripts.TPABOBAP.QuickWheel.config')
local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local EquipmentIcon = require('scripts.TPABOBAP.QuickWheel.icons.equipment_icon')


local function needsDelay(item)
    if item.type == types.Repair then return true end
    return helpers.getSoul(item)
end

local function needsReady(item)
    local t = item.type
    return t == types.Weapon --do we need to exclude ammo?
        or t == types.Lockpick
        or t == types.Probe
end

---@param item openmw.Object
local function getEnchantId(item)
    local record = item.type.records[item.recordId]
    return record and record.enchant
end

---@param icon EquipmentIcon
local function equipItem(icon)
    local item = icon.item and icon:item() or icon
    local equipped = helpers.isEquipped(item)

    local close = config.equip.b_AutoClose
    if helpers.isShiftPressed() then close = not close end

    local force = config.equip.b_ForceEquip
    if helpers.isCtrlPressed() then force = not force end

    local ready = config.equip.b_AutoReady
    if helpers.isAltPressed() then ready = not ready end
    ready = ready and (not equipped or force) and needsReady(item)

    local opensUI = needsDelay(item)

    if close or opensUI then player:sendEvent('QW_UpdateWheelState', { wheelState = false }) end

    if equipped then
        if force then
            if ready then player.type.setStance(player, types.Actor.STANCE.Weapon) end
        else
            player:sendEvent('Unequip', { item = item })
            --play unequip sounds - equip one are playing automatically
            local sound = helpers.getItemSound(item, 'down')
            if sound then ambient.playSound(sound) end
        end
    elseif opensUI then
        async:newUnsavableGameTimer(0.1, function()
            core.sendGlobalEvent('UseItem', { object = item, actor = player })
        end)
    else
        core.sendGlobalEvent('UseItem', { object = item, actor = player })
        if ready then
            async:newUnsavableGameTimer(0.1, function()
                player.type.setStance(player, types.Actor.STANCE.Weapon)
            end)
        end
    end
end

local function makeIcons(items)
    ---@type table<number, PotionIcon>
    local result = {}
    for i = 1, #items do
        local tmp = items[i]
        if not tmp[1] then tmp = { tmp } end
        table.insert(result, EquipmentIcon:new({ items = tmp, activate = equipItem }))
    end
    table.sort(result, function(a, b)
        local itemA = a:item()
        local itemB = b:item()

        local ra = itemA.type.record(itemA.recordId)
        local rb = itemB.type.record(itemB.recordId)

        if ra.name ~= rb.name then
            return ra.name < rb.name
        end

        if ra.value ~= rb.value then
            return ra.value < rb.value --cheaper first
        end

        return itemA.id < itemB.id --id as tie breaker
    end)
    return result
end

---@param itemType any
---@param list? openmw.Object[][]
---@param inventory openmw.core.Inventory?
---@param filter? fun(item:openmw.Object):boolean
---@param group? boolean|fun(item:openmw.Object):string
---@return openmw.Object[][]
local function addItems(itemType, list, inventory, filter, group)
    if not inventory then inventory = types.Actor.inventory(player) end
    if not list then list = {} end
    local items = inventory:getAll(itemType)
    if group then
        local map = {}
        for i = 1, #items do
            local v = items[i]
            if not filter or filter(v) then
                local g = type(group) == 'function' and group(v) or v.recordId
                if not map[g] then
                    map[g] = { v }
                else
                    table.insert(map[g], v)
                end
            end
        end
        for _, v in pairs(map) do
            --put least durable item first
            table.sort(v, function(a, b)
                local da = types.Item.itemData(a)
                local db = types.Item.itemData(b)

                local ca = da and da.condition or 0
                local cb = db and db.condition or 0

                return ca < cb
            end)
            table.insert(list, v)
        end
    else
        for i = 1, #items do
            local v = items[i]
            if not filter or filter(v) then
                table.insert(list, v)
            end
        end
    end
    return list
end

local function findWeapons()
    local result = {}
    local inventory = types.Actor.inventory(player)
    addItems(types.Weapon, result, inventory)

    if config.equip.b_ShieldsAreWeapons then
        addItems(types.Armor, result, inventory, function(v)
            ---@type openmw.types.ArmorRecord
            local record = types.Armor.records[v.recordId]
            return record and record.type == types.Armor.TYPE.Shield
        end)
    end

    return result
end

local function findArmor()
    local result = {}
    local inventory = types.Actor.inventory(player)
    local filter = config.equip.b_ShieldsAreWeapons and function(v)
        ---@type openmw.types.ArmorRecord
        local record = types.Armor.records[v.recordId]
        return record and record.type ~= types.Armor.TYPE.Shield
    end or nil
    addItems(types.Armor, result, inventory, filter)

    return result
end

local function findClothing()
    local result = {}
    local inventory = types.Actor.inventory(player)
    local filter = config.equip.b_OnlyMagicClothes and getEnchantId or nil
    addItems(types.Clothing, result, inventory, filter)

    return result
end

local function findTools()
    local result = {}
    local inventory = types.Actor.inventory(player)

    addItems(types.Lockpick, result, inventory, nil, true)
    addItems(types.Probe, result, inventory, nil, true)
    addItems(types.Repair, result, inventory, nil, true)
    addItems(types.Light, result, inventory, nil, true)

    if config.equip.b_FilledGemTools then
        addItems(types.Miscellaneous, result, inventory, helpers.getSoul, helpers.getSoul)
    end

    return result
end

local function categoryProvider(icon)
    if icon.name == C.EquipmentCategories.Weapon then
        return findWeapons()
    elseif icon.name == C.EquipmentCategories.Armor then
        return findArmor()
    elseif icon.name == C.EquipmentCategories.Clothes then
        return findClothing()
    elseif icon.name == C.EquipmentCategories.Tools then
        return findTools()
    end
    return {}
end


return {
    makeIcons = makeIcons,
    provider = categoryProvider,
}
