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

local MagicEffectTypes = {
    Restore = {
        restorefatigue = true,
        restorehealth = true,
        restoremagicka = true,
    },
    Damage = {
        absorbhealth = true,
        damagehealth = true,
        firedamage = true,
        frostdamage = true,
        poison = true,
        shockdamage = true,
        t_mysticism_banishdae = true, --TR Spells (unofficial) - banish daedra

        spellsword_effect = false, --spellsword mod - imbue weapon with magic
    },
    Debuff = {
        absorbattribute = true,
        absorbfatigue = true,
        absorbmagicka = true,
        absorbskill = true,
        blind = true,
        burden = true,
        damageattribute = true,
        damagefatigue = true,
        damagemagicka = true,
        damageskill = true,
        disintegratearmor = true,
        disintegrateweapon = true,
        drainattribute = true,
        drainfatigue = true,
        drainhealth = true,
        drainmagicka = true,
        drainskill = true,
        silence = true,
        sound = true,
        weaknesstoblightdisease = true,
        weaknesstocommondisease = true,
        weaknesstocorprusdisease = true,
        weaknesstofire = true,
        weaknesstofrost = true,
        weaknesstomagicka = true,
        weaknesstonormalweapons = true,
        weaknesstopoison = true,
        weaknesstoshock = true,
    },
    Combat = {
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

        nsp_alacrity = true, --nifty spell pack Alacrity (cast speed)
        spellsword_effect = true, --spellsword mod - imbue weapon with magic
    },
    Buff = {
        chameleon = true,
        feather = true,
        fortifyattribute = true,
        fortifyfatigue = true,
        fortifyhealth = true,
        fortifymagicka = true,
        fortifymaximummagicka = true,
        fortifyskill = true,
        invisibility = true,
        resistblightdisease = true,
        resistcommondisease = true,
        resistcorprusdisease = true,
    },
    Util = {
        detectanimal = true,
        detectenchantment = true,
        detectkey = true,
        light = true,
        lock = true,
        nighteye = true,
        open = true,
        slowfall = true,
        soultrap = true,
        swiftswim = true,
        telekinesis = true,
        waterbreathing = true,
        waterwalking = true,

        nsp_projection = true,

        ----- Spells of Morrowind - Vol. 1 - Trap Handling
        absorbtrap = true,
        detecttrap = true,
        detecttrap_alt = true,
        disarmtrap = true,
        -----------------


        t_mysticism_insight = true, --TR Spells (unofficial) - insight - better loot
        nsp_pocket = true, --nifty spell pack - pocket - extra storage
    },
    Transport = {
        almsiviintervention = true,
        divineintervention = true,
        jump = true,
        levitate = true,
        mark = true,
        recall = true,

        multimark_mark = true, --Daisy Lua Multimark
        multimark_recall = true, --Daisy Lua Multimark
        t_mysticism_blink = true, --TR Spells (unofficial) - blink - teleport
        nsp_wildintervention = true, --nifty spell pack - random teleport
    },
    Cure = {
        cureblightdisease = true,
        curecommondisease = true,
        curecorprusdisease = true,
        cureparalyzation = true,
        curepoison = true,
        dispel = true,
        removecurse = true,
        restoreattribute = true,
        restoreskill = true,
    },
    Control = {
        calmcreature = true,
        calmhumanoid = true,
        charm = true,
        commandcreature = true,
        commandhumanoid = true,
        demoralizecreature = true,
        demoralizehumanoid = true,
        frenzycreature = true,
        frenzyhumanoid = true,
        paralyze = true,
        rallycreature = true,
        rallyhumanoid = true,
        turnundead = true,

        t_illusion_distractcreature = true, --TR Spells (unofficial) - distract creature - moves away
        t_illusion_distracthumanoid = true, --TR Spells (unofficial) - distract humanoid - moves away
    },
    Summon = {
        summonancestralghost = true,
        summonbear = true,
        summonbonelord = true,
        summonbonewalker = true,
        summonbonewolf = true,
        summoncenturionsphere = true,
        summonclannfear = true,
        summondaedroth = true,
        summondremora = true,
        summonfabricant = true,
        summonflameatronach = true,
        summonfrostatronach = true,
        summongoldensaint = true,
        summongreaterbonewalker = true,
        summonhunger = true,
        summonscamp = true,
        summonskeletalminion = true,
        summonstormatronach = true,
        summonwingedtwilight = true,
        summonwolf = true,
    },
    Bound = {
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
    },
}

local KeyModes = {
    Smart = 'SettingKeyModeSmart',
    Hold = 'SettingKeyModeHold',
    Toggle = 'SettingKeyModeToggle'
}
local TimeModes = {
    Normal = 'SettingTimeModeNormal',
    Slow = 'SettingTimeModeSlow',
    VerySlow = 'SettingTimeModeVerySlow',
    Paused = 'SettingTimeModePaused',
}
local getTimeScale = function(mode)
    if mode == TimeModes.Normal then
        return 1
    elseif mode == TimeModes.Slow then
        return 0.3
    elseif mode == TimeModes.VerySlow then
        return 0.1
    elseif mode == TimeModes.Paused then
        return 0
    end
    return 1
end

return {
    PotionTypes = PotionTypes,
    MagicEffectTypes = MagicEffectTypes,
    KeyModes = KeyModes,
    TimeModes = TimeModes,
    getTimeScale = getTimeScale,
    KeyHoldThreshold = 0.35, --- if key is held longer than this in smart mode, assume we want hold variant
    actionOpenWheel = "TPA_QuickWheel_Open",
    SpellCategories = {
        Damage = 'Damage',
        Combat = 'Combat',
        Debuff = 'Debuff',
        Util = 'Util',
        Other = 'Other',
        Transport = 'Transport',
        Control = 'Control',
        Buff = 'Buff',
        Cure = 'Cure',
        Restore = 'Restore',
        Summon = 'Summon',
    },
}