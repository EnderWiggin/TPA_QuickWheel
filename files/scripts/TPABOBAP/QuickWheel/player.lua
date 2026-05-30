local I = require('openmw.interfaces')
local core = require('openmw.core')
local input = require('openmw.input')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local omwself = require('openmw.self')

local helpers = require('scripts.TPABOBAP.QuickWheel.helpers')
local wheel = require('scripts.TPABOBAP.QuickWheel.wheel')
local Icon = require('scripts.TPABOBAP.QuickWheel.icons.base_icon')
local PotionIcon = require('scripts.TPABOBAP.QuickWheel.icons.potion_icon')
local CategoryIcon = require('scripts.TPABOBAP.QuickWheel.icons.category_icon')

local isWheelModeOn = false
local lastUIMode

local PotionTypes = {
    Health = {
        restorehealth = true,
    },
    Stamina = {
        restorefatigue = true,
    },
    Magicka = {
        restoremagicka = true,
    },
    Poison = { --TODO: filter out alcohol?
        -- Direct damage
        damagehealth = true,
        damagefatigue = true,
        damagemagicka = true,
        damageattribute = true,
        damageskill = true,
        drainhealth = true,
        drainfatigue = true,
        drainmagicka = true,
        drainattribute = true,
        drainskill = true,
        absorbhealth = true,
        absorbfatigue = true,
        absorbmagicka = true,
        absorbattribute = true,
        absorbskill = true,

        -- Elemental damage
        firedamage = true,
        frostdamage = true,
        shockdamage = true,
        poison = true,

        -- Control / debuff
        paralyze = true,
        silence = true,
        blind = true,
        sound = true,
        burden = true,
        weaknesstofire = true,
        weaknesstofrost = true,
        weaknesstoshock = true,
        weaknesstomagicka = true,
        weaknesstocommondisease = true,
        weaknesstoblightdisease = true,
        weaknesstocorprusdisease = true,
        weaknesstonormalweapons = true,
        weaknesstopoison = true,

        -- Mind effects (hostile when cast on player)
        demoralizecreature = true,
        demoralizehumanoid = true,
        frenzycreature = true,
        frenzyhumanoid = true,
        charm = true,
        commandcreature = true,
        commandhumanoid = true,

        -- Equipment destruction
        disintegratearmor = true,
        disintegrateweapon = true,
    },
    Cure = {
        cureblightdisease = true,
        curecommondisease = true,
        curecorprusdisease = true,
        cureparalyzation = true,
        curepoison = true,
        dispel = true,
        restoreattribute = true,
        restoreskill = true,
        removecurse = true,

    },
    Combat = {
        boundbattleaxe = true,
        boundboots = true,
        boundcuirass = true,
        bounddagger = true,
        boundgloves = true,
        boundhelm = true,
        boundlongbow = true,
        boundlongsword = true,
        boundmace = true,
        boundshield = true,
        boundspear = true,
        fireshield = true,
        fortifyattack = true,
        frostshield = true,
        lightningshield = true,
        reflect = true,
        resistfire = true,
        resistfrost = true,
        resistmagicka = true,
        resistnormalweapons = true,
        resistparalysis = true,
        resistpoison = true,
        resistshock = true,
        sanctuary = true,
        shield = true,
        spellabsorption = true,
    },
    Buffs = {
        chameleon = true,
        detectanimal = true,
        detectenchantment = true,
        detectkey = true,
        feather = true,
        fortifyattribute = true,
        fortifyfatigue = true,
        fortifyhealth = true,
        fortifymagicka = true,
        fortifymaximummagicka = true,
        fortifyskill = true,
        invisibility = true,
        jump = true,
        levitate = true,
        light = true,
        nighteye = true,
        resistblightdisease = true,
        resistcommondisease = true,
        resistcorprusdisease = true,
        slowfall = true,
        swiftswim = true,
        telekinesis = true,
        waterbreathing = true,
        waterwalking = true,
    },
}

local function isPotionOfType(potion, type)
    local record = potion.type.record(potion.recordId)
    local test = PotionTypes[type]

    local valid = false
    for _, effect in ipairs(record.effects) do
        local t = test[effect.id]
        if t == false then
            return false
        elseif t == true then
            valid = true
        end
    end
    return valid
end

---@function
---@param icon PotionIcon
local function usePotion(icon)
    core.sendGlobalEvent('UseItem', {
        object = icon.item,
        actor = omwself,
    })
end

local function findPotions(filter)
    local inventory = types.Actor.inventory(omwself)
    local pots = inventory:getAll(types.Potion)
    ---@type table<number, PotionIcon>
    local result = {}
    for _, v in ipairs(pots) do
        if not filter or filter(v) then
            table.insert(result, v)
        end
    end
    return result
end

---@function
---@return table<number, Icon>
local function makePotionIcons(potions)
    ---@type table<number, PotionIcon>
    local result = {}
    for _, v in ipairs(potions) do
        table.insert(result, PotionIcon:new({ item = v, activate = usePotion }))
    end
    table.sort(result, function(a, b)
        local ra = a.item.type.record(a.item.recordId)
        local rb = b.item.type.record(b.item.recordId)

        if ra.name ~= rb.name then
            return ra.name < rb.name
        end

        if ra.value ~= rb.value then
            return ra.value < rb.value --cheaper first
        end

        return a.item.id < b.item.id --id as tie breaker
    end)
    return result
end

local function otherPotionFiler(p)
    for k, _ in pairs(PotionTypes) do
        if isPotionOfType(p, k) then return false end
    end
    return true
end

local function potionCategoryProvider(icon)
    if icon.name == 'Other' then
        return findPotions(otherPotionFiler)
    else
        return findPotions(function(p) return isPotionOfType(p, icon.name) end)
    end
end

---@function
---@param icon CategoryIcon
local function openCategory(icon)
    if not wheel.ctx.shown then return end
    if #icon:provider() == 0 then return end
    wheel:show(true, function()
        return makePotionIcons(icon:provider())
    end)
end

local function getCategories()
    return {
        CategoryIcon:new({ name = 'Health', activate = openCategory, provider = potionCategoryProvider }),
        CategoryIcon:new({ name = 'Stamina', activate = openCategory, provider = potionCategoryProvider }),
        CategoryIcon:new({ name = 'Combat', activate = openCategory, provider = potionCategoryProvider }),
        CategoryIcon:new({ name = 'Cure', activate = openCategory, provider = potionCategoryProvider }),
        CategoryIcon:new({ name = 'Poison', activate = openCategory, provider = potionCategoryProvider }),
        CategoryIcon:new({ name = 'Other', activate = openCategory, provider = potionCategoryProvider }),
        CategoryIcon:new({ name = 'Buffs', activate = openCategory, provider = potionCategoryProvider }),
        CategoryIcon:new({ name = 'Magicka', activate = openCategory, provider = potionCategoryProvider }),
    }
end

local function setWheelMode(isOn)
    if isOn == isWheelModeOn then return end

    if lastUIMode ~= nil and not isWheelModeOn then return end

    isWheelModeOn = isOn

    if isWheelModeOn then
        I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
    else
        I.UI.setMode()
    end

    wheel:show(isWheelModeOn, getCategories)

    core.sendGlobalEvent('QW_UpdateWheelState', { state = isWheelModeOn })
end

local function onUpdate(dt)
    local wasMode = lastUIMode
    lastUIMode = I.UI.getMode()
    if isWheelModeOn then
        wheel:checkDirty()
        if wasMode ~= lastUIMode then
            if wasMode == I.UI.MODE.Interface and lastUIMode ~= I.UI.MODE.Interface then
                setWheelMode(false)
                return
            end
        end
    end
end

local function onKeyPress(key)
    if key.code == input.KEY.X then
        setWheelMode(true)
    end
end

local function onKeyRelease(key)
    if key.code == input.KEY.X then
        setWheelMode(false)
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onKeyPress = onKeyPress,
        onKeyRelease = onKeyRelease,
        onLoad = function(_)
            wheel:init(omwself)
        end,
        onInit = function()
            wheel:init(omwself)
        end,
    },
    eventHandlers = {
        IE_Update = function()
            wheel:markDirty()
        end,
        QW_UpdateWheelState = function()
            if wheel.ctx.shown then
                wheel:markDirty()
            end
        end,
    },
}