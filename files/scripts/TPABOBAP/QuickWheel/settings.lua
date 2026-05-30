local I = require('openmw.interfaces')
local input = require('openmw.input')
local core = require('openmw.core')

local MODNAME = 'TPA_QuickWheel'
local l10n = core.l10n(MODNAME)
local C = require('scripts.TPABOBAP.QuickWheel.constants')

input.registerAction {
    key = C.actionOpenWheel,
    type = input.ACTION_TYPE.Boolean,
    l10n = MODNAME,
    name = '',
    description = '',
    defaultValue = false,
}

I.Settings.registerPage {
    key = MODNAME,
    l10n = MODNAME,
    name = 'PageName',
    description = 'PageDesc',
}

I.Settings.registerGroup {
    key = MODNAME .. '/MainSettings',
    page = MODNAME,
    l10n = MODNAME,
    name = 'SettingsName',
    permanentStorage = true,
    settings = {
        {
            key = 'k_PotionWheel',
            renderer = 'inputBinding',
            name = 'SettingKeyPotionWheel',
            description = 'SettingKeyPotionWheelDesc',
            default = C.actionOpenWheel,
            argument = {
                type = "action",
                key = C.actionOpenWheel
            },
        },
        {
            key = 's_KeyMode',
            renderer = 'select',
            name = 'SettingKeyMode',
            description = 'SettingKeyModeDesc',
            default = C.KeyModes.Smart,
            argument = {
                l10n = MODNAME,
                items = {
                    C.KeyModes.Smart,
                    C.KeyModes.Hold,
                    C.KeyModes.Toggle,
                },
            }
        },
        {
            key = 's_TimeMode',
            renderer = 'select',
            name = 'SettingTimeMode',
            description = 'SettingTimeModeDesc',
            default = C.TimeModes.VerySlow,
            argument = {
                l10n = MODNAME,
                items = {
                    C.TimeModes.Normal,
                    C.TimeModes.Slow,
                    C.TimeModes.VerySlow,
                    C.TimeModes.Paused,
                },
            }
        },
        {
            key = 'b_NoUnknownCategory',
            renderer = 'checkbox',
            name = 'SettingNoUnknownCategory',
            description = 'SettingNoUnknownCategoryDesc',
            default = false,
        },
    },
}