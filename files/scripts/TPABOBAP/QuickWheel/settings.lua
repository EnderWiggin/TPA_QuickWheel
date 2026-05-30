local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local input = require('openmw.input')
local core = require('openmw.core')

local MODNAME = 'TPA_QuickWheel'
local l10n = core.l10n(MODNAME)
local C = require('scripts.TPABOBAP.QuickWheel.constants')

-- inputKeySelection by Pharis
local inputKeyRenderer = function(value, set)
    local name = l10n('No_Key_Set')
    if value then
        name = input.getKeyName(value)
    end
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        template = I.MWUI.templates.textEditLine,
                        props = {
                            text = name,
                        },
                        events = {
                            keyPress = async:callback(function(e)
                                if e.code == input.KEY.Escape then return end
                                set(e.code)
                            end),
                        },
                    },
                },
            },
        },
    }
end

I.Settings.registerRenderer('TPA_QuickWheel/inputKeySelection', inputKeyRenderer)

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
            renderer = 'TPA_QuickWheel/inputKeySelection',
            name = 'SettingKeyPotionWheel',
            description = 'SettingKeyPotionWheelDesc',
            default = nil
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
    },
}