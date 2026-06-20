---@omw-context menu
local I = require('openmw.interfaces')
local input = require('openmw.input')

local MODNAME = 'TPA_QuickWheel'
local C = require('scripts.TPABOBAP.QuickWheel.constants')

I.Settings.registerRenderer('TPABOBAP/ClearInputBindings', require('scripts.TPABOBAP.clear_input_bind_renderer'))

input.registerAction {
    key = C.Actions.Omni,
    type = input.ACTION_TYPE.Boolean,
    l10n = MODNAME,
    name = '',
    description = '',
    defaultValue = false,
}

input.registerAction {
    key = C.Actions.Potion,
    type = input.ACTION_TYPE.Boolean,
    l10n = MODNAME,
    name = '',
    description = '',
    defaultValue = false,
}

input.registerAction {
    key = C.Actions.Magic,
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
    order = 1,
    permanentStorage = true,
    settings = {
        {
            key = 'k_OmniWheel',
            renderer = 'inputBinding',
            name = 'SettingKeyOmniWheel',
            description = 'SettingKeyOmniWheelDesc',
            default = C.WheelOpenKeyBind.Omni,
            argument = {
                type = "action",
                key = C.Actions.Omni
            },
        },
        {
            key = 'k_PotionWheel',
            renderer = 'inputBinding',
            name = 'SettingKeyPotionWheel',
            description = 'SettingKeyPotionWheelDesc',
            default = C.WheelOpenKeyBind.Potion,
            argument = {
                type = "action",
                key = C.Actions.Potion
            },
        },
        {
            key = 'k_MagicWheel',
            renderer = 'inputBinding',
            name = 'SettingKeyMagicWheel',
            description = 'SettingKeyMagicWheelDesc',
            default = C.WheelOpenKeyBind.Magic,
            argument = {
                type = "action",
                key = C.Actions.Magic
            },
        },
        {
            key = 'k_OmniWheelAlt',
            renderer = 'inputBinding',
            name = 'SettingKeyOmniWheelAlt',
            description = 'SettingKeyOmniWheelDesc',
            default = C.WheelOpenKeyBind.OmniAlt,
            argument = {
                type = "action",
                key = C.Actions.Omni
            },
        },
        {
            key = 'k_PotionWheelAlt',
            renderer = 'inputBinding',
            name = 'SettingKeyPotionWheelAlt',
            description = 'SettingKeyPotionWheelDesc',
            default = C.WheelOpenKeyBind.PotionAlt,
            argument = {
                type = "action",
                key = C.Actions.Potion
            },
        },
        {
            key = 'k_MagicWheelAlt',
            renderer = 'inputBinding',
            name = 'SettingKeyMagicWheelAlt',
            description = 'SettingKeyMagicWheelDesc',
            default = C.WheelOpenKeyBind.MagicAlt,
            argument = {
                type = "action",
                key = C.Actions.Magic
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
                    C.WheelOpenKeyBind.Omni,
                    C.WheelOpenKeyBind.Potion,
                    C.WheelOpenKeyBind.Magic,
                    C.WheelOpenKeyBind.OmniAlt,
                    C.WheelOpenKeyBind.PotionAlt,
                    C.WheelOpenKeyBind.MagicAlt,
                },
                settings = {
                    'k_OmniWheel',
                    'k_PotionWheel',
                    'k_MagicWheel',
                    'k_OmniWheelAlt',
                    'k_PotionWheelAlt',
                    'k_MagicWheelAlt',
                },
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
            key = 's_ControllerMode',
            renderer = 'select',
            name = 'SettingControllerMode',
            description = 'SettingControllerModeDesc',
            default = C.ControllerMode.Auto,
            argument = {
                l10n = MODNAME,
                items = {
                    C.ControllerMode.Off,
                    C.ControllerMode.Auto,
                    C.ControllerMode.Exclusive,
                },
            }
        },
        {
            key = 's_ControllerStick',
            renderer = 'select',
            name = 'SettingControllerStick',
            description = 'SettingControllerStickDesc',
            default = C.ControllerStick.Left,
            argument = {
                l10n = MODNAME,
                items = {
                    C.ControllerStick.Left,
                    C.ControllerStick.Right,
                },
            }
        },
        {
            key = 'n_ControllerDeadZone',
            renderer = 'number',
            name = 'SettingControllerDeadZone',
            description = 'SettingControllerDeadZoneDesc',
            default = 0.15,
            argument = {
                min = 0.01,
                max = 1,
            }
        },
    },
}

I.Settings.registerGroup {
    key = MODNAME .. '/PotionSettings',
    page = MODNAME,
    l10n = MODNAME,
    name = 'SettingsPotionsName',
    order = 2,
    permanentStorage = true,
    settings = {
        {
            key = 'b_NoUnknownCategory',
            renderer = 'checkbox',
            name = 'SettingNoUnknownCategory',
            description = 'SettingNoUnknownCategoryDesc',
            default = false,
        },
        --[[
        {
            key = 'b_FilterPoisons',
            renderer = 'checkbox',
            name = 'SettingFilterPoisons',
            description = 'SettingFilterPoisonsDesc',
            default = true,
        },
        ]]
        {
            key = 'b_QuickApplyPoison',
            renderer = 'checkbox',
            name = 'SettingQuickApplyPoison',
            description = 'SettingQuickApplyPoisonDesc',
            default = true,
        },
        --[[
        {
            key = 's_SeparateAlcohol',
            renderer = 'select',
            name = 'SettingSeparateAlcohol',
            description = 'SettingSeparateAlcoholDesc',
            default = C.AlcoholModes.Show,
            argument = {
                l10n = MODNAME,
                items = {
                    C.AlcoholModes.Normal,
                    C.AlcoholModes.Show,
                    C.AlcoholModes.Move,
                },
            }
        },
        ]]
    }
}

I.Settings.registerGroup {
    key = MODNAME .. '/MagicSettings',
    page = MODNAME,
    l10n = MODNAME,
    name = 'SettingsMagicName',
    description = 'SettingsMagicNameDesc',
    order = 3,
    permanentStorage = true,
    settings = {
        {
            key = 's_MagicClickMode',
            renderer = 'select',
            name = 'SettingMagicClickMode',
            description = 'SettingMagicClickModeDesc',
            default = C.MagicClickModes.READY,
            argument = {
                l10n = MODNAME,
                items = {
                    C.MagicClickModes.READY,
                    C.MagicClickModes.EQUIP,
                    C.MagicClickModes.QCAST,
                    C.MagicClickModes.QUEUE,
                },
            }
        },
        {
            key = 'b_UseOSSC',
            renderer = 'checkbox',
            name = 'SettingMagicUseOSSC',
            description = 'SettingMagicUseOSSCDesc',
            default = true,
        },
        {
            key = 'n_MagicCastDelay',
            renderer = 'number',
            name = 'SettingMagicCastDelay',
            description = 'SettingMagicCastDelayDesc',
            default = 0.35,
            argument = {
                min = 0.1,
                max = 2,
            }
        },
        {
            key = 'n_MagicCastCooldown',
            renderer = 'number',
            name = 'SettingMagicCastCooldown',
            description = 'SettingMagicCastCooldownDesc',
            default = 0.95,
            argument = {
                min = 0.2,
                max = 2,
            }
        },
        {
            key = 'b_ShowQueueWidget',
            renderer = 'checkbox',
            name = 'SettingMagicShowQueue',
            description = 'SettingMagicShowQueueDesc',
            default = true,
        },
        {
            key = 's_QueueWidgetPosition',
            renderer = 'select',
            name = 'SettingMagicQueueWidgetPosition',
            default = C.QueueWidgetPosition.BOTTOM_LEFT,
            argument = {
                l10n = MODNAME,
                items = {
                    C.QueueWidgetPosition.BOTTOM_LEFT,
                    C.QueueWidgetPosition.BOTTOM_RIGHT,
                    C.QueueWidgetPosition.CENTER,
                    C.QueueWidgetPosition.TOP_LEFT,
                    C.QueueWidgetPosition.TOP_RIGHT,
                },
            }
        },
    }
}
