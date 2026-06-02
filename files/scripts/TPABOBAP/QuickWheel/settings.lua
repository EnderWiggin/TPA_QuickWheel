---@omw-context menu
local I = require('openmw.interfaces')
local input = require('openmw.input')
local core = require('openmw.core')

local MODNAME = 'TPA_QuickWheel'
local C = require('scripts.TPABOBAP.QuickWheel.constants')

I.Settings.registerRenderer('TPABOBAP/ClearInputBindings', require('scripts.TPABOBAP.clear_input_bind_renderer'))

input.registerAction {
    key = C.actionOpenOmniWheel,
    type = input.ACTION_TYPE.Boolean,
    l10n = MODNAME,
    name = '',
    description = '',
    defaultValue = false,
}

input.registerAction {
    key = C.actionOpenPotionWheel,
    type = input.ACTION_TYPE.Boolean,
    l10n = MODNAME,
    name = '',
    description = '',
    defaultValue = false,
}

input.registerAction {
    key = C.actionOpenMagicWheel,
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
            key = 'k_OmniWheel',
            renderer = 'inputBinding',
            name = 'SettingKeyOmniWheel',
            description = 'SettingKeyOmniWheelDesc',
            default = C.actionOpenOmniWheel,
            argument = {
                type = "action",
                key = C.actionOpenOmniWheel
            },
        },
        {
            key = 'k_PotionWheel',
            renderer = 'inputBinding',
            name = 'SettingKeyPotionWheel',
            description = 'SettingKeyPotionWheelDesc',
            default = C.actionOpenPotionWheel,
            argument = {
                type = "action",
                key = C.actionOpenPotionWheel
            },
        },
        {
            key = 'k_MagicWheel',
            renderer = 'inputBinding',
            name = 'SettingKeyMagicWheel',
            description = 'SettingKeyMagicWheelDesc',
            default = C.actionOpenMagicWheel,
            argument = {
                type = "action",
                key = C.actionOpenMagicWheel
            },
        },
        {
            key = 'r_ResetBindings',
            renderer = 'TPABOBAP/ClearInputBindings',
            name = 'SettingResetKeyBinds',
            description = 'SettingResetKeyBindsDesc',
            argument = {
                section = 'TPA_QuickWheel/MainSettings',
                actions = {
                    C.actionOpenOmniWheel,
                    C.actionOpenPotionWheel,
                    C.actionOpenMagicWheel,
                    "TPA_QuickWheel_Open", --old setting
                },
                settings = {
                    'k_OmniWheel',
                    'k_PotionWheel',
                    'k_MagicWheel'
                }
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