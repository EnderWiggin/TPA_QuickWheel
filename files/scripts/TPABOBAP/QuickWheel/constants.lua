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
    KeyModes = KeyModes,
    TimeModes = TimeModes,
    getTimeScale = getTimeScale,
    KeyHoldThreshold = 0.35, --- if key is held longer than this in smart mode, assume we want hold variant
    actionOpenWheel = "TPA_QuickWheel_Open",
}